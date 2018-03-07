# Dependencies:
#  - asciidoc,
#  - gawk,
#  - telive-xetex,
#  - plantuml.jar (schemas UML),
#  - graphviz (used by plantuml),
#  - dblatex (docbook -> latex),
#  - rsvg-convert (svg -> pdf),
#  - python whith stdlib, lxml and pyquery (optional, for ods2pvs tool)
# Debian packages: asciidoc gawk dblatex poppler-utils librsvg2-bin graphviz telive-xetex libpython2.7-stdlib python-lxml python-pyquery

ADOC_TOOLS_DIR = $(addsuffix adoc-tools,$(dir $(filter %/adoc.mk,${MAKEFILE_LIST})))

ADOC_OUTPUT_DIR ?= .
ADOC_TEX_INPUT ?= .
ADOC_CONF ?= ${ADOC_TOOLS_DIR}/docbook45.conf ${ADOC_TOOLS_DIR}/tex-passthrough.conf

ADOC_PROPERTIES += $(shell find . -mindepth 1 -type d -exec sh -c '[ -f "{}/$$(basename {}).adoc" ] && [ -f "{}/$$(basename {}).properties" ] && echo "{}/$$(basename {}).properties"' \;)

ifneq ("$(wildcard ${PLANTUML_SKIN})","")
PLANTUML_SKIN := -config '${PLANTUML_SKIN}'
endif

PLANTUML ?= /etc/asciidoc/filters/plantuml/plantuml.jar
ifeq ("$(wildcard ${PLANTUML})","")
$(error Please set PLANTUML variable to the PlantUML jar file location)
endif

DBLATEX_XSL ?= /etc/asciidoc/dblatex/asciidoc-dblatex.xsl
ifeq ("$(wildcard ${DBLATEX_XSL})","")
$(error Please set DBLATEX_XSL variable to the dblatex XSL file location)
endif


# Returns the sheet content in PVS format
# Usage: $(call ods2pvs,ods-file,sheet-name)
define ods2pvs
	${ADOC_TOOLS_DIR}/ods2pvs $1 $2
endef

# Returns the list of sheet found in the ODS file
# Usage: $(call ods-list-sheets,ods-file)
define ods-list-sheets
	${ADOC_TOOLS_DIR}/ods-list-sheets $1
endef

ADOCS = $(shell find . -type f -name \*.adoc $(addprefix -and -not -samefile ,${ADOC_EXCLUDE}))
DOCBOOKS = $(addprefix ${ADOC_OUTPUT_DIR}/,$(subst .adoc,.xml,${ADOCS}))
ADOC_PDF = $(addsuffix .pdf,$(patsubst %/,%,$(dir ${DOCBOOKS})))

get_var_from=$$(awk -F: "/^$1:/"'{sub(/^\s*/,"",$$2);value="$2"$$2"$2"} END{print value}' ${3})
get_var=$(call get_var_from,$1,$2,$(filter-out $(realpath $(subst ${ADOC_OUTPUT_DIR}/,,$(basename $3).properties)),$(realpath ${ADOC_PROPERTIES})) $(wildcard $(subst ${ADOC_OUTPUT_DIR}/,,$(basename $3).properties)))
get_doc_var=$(call get_var,$(basename $(notdir $1)).$2,$3,$1)
get_tex_style=$(shell find ${ADOC_TEX_INPUT} -maxdepth 1 -name $(call get_var,latex.style.$(basename $(notdir $1)),,$1).sty)

$(info $(abspath ${ADOC_OUTPUT_DIR}))
.SECONDEXPANSION:
${DOCBOOKS}: %: $$(foreach req,$$(shell sed -n -e '/{BUILD_DIR}/! s,^\(include\|image\)::\(.*\)\[[^]]*\],$$(subst ${ADOC_OUTPUT_DIR}/,,$$(dir $$@))/\2,p' -e 's,^\(include\|image\)::{BUILD_DIR}/\(.*\)\[[^]]*\],\2,p' $$(subst .xml,.adoc,$$(subst ${ADOC_OUTPUT_DIR}/,,$$@))),$$(shell [ -f '$${req}' ] && echo '$${req}' || echo '${ADOC_OUTPUT_DIR}/$${req}')) $$(subst .xml,.adoc-conf,$$@)

TABLES_SHEETS=$(shell for ods in $$(find * -name \*.ods); do for sheet in $$($(call ods-list-sheets,$${ods})); do echo "${ADOC_OUTPUT_DIR}/$$(dirname $${ods})/$$(basename $${ods} .ods)"-$${sheet}; done ;done)
ifneq (,${TABLES_SHEETS})
.SECONDEXPANSION:
$(addsuffix .pvs,${TABLES_SHEETS}): %: $$(shell echo "$${@:${ADOC_OUTPUT_DIR}/=}"|sed 's,^\(${ADOC_OUTPUT_DIR}/\)\(.\+\)-[^-]\+\.pvs,\2.ods,')
	@mkdir --parent $(dir $@)
	$(call ods2pvs,$<,$(patsubst $(notdir $(basename $<))-%,%,$(notdir $(basename $@)))) > $@
endif

${ADOC_OUTPUT_DIR}/%.svg: %.plantuml ${PLANTUML_SKINPARAM} ${ADOC_PROPERTIES} $(wildcard %.properties)
	@mkdir --parent $(dir $@)
	$(eval colors=$(shell gawk -F: 'match($$1,/^rgb\..*$$/,a){sub(/^\s*rgb\.\s*/,"",$$1); sub(/^\s/,"",$$2); print "-D" $$1 "=" $$2}' ${ADOC_PROPERTIES}))
	java -jar ${PLANTUML} ${colors} ${PLANTUML_SKIN} -ofile $@ -tsvg $<

${ADOC_OUTPUT_DIR}/%.pdf: %.tex
	@mkdir --parent ${@D}
	TEXINPUTS='./:${ADOC_TEX_INPUT}:' pdflatex -output-directory ${@D} $<

%.pdf: %.svg
	rsvg-convert -f pdf -o $@ $^

${ADOC_OUTPUT_DIR}/%-sorted.dvs: %.dvs
	@mkdir --parent $(dir $@)
	cat $< | sort | gawk -F' :' '{key=$$1; value=$$0; gsub(/[- ]/, "_", key); gsub(/[àáâäã]/, "a", key); gsub(/[ÀÁÄÂÃ]/, "A", key); gsub(/[éèêëẽ]/, "e", key); gsub(/[ÉÈÊËẼ]/, "E", key); gsub(/[íìïîĩ]/, "i", key); gsub(/[ÍÌÏÎĨ]/, "I", key); gsub(/[óòôöõ]/, "o", key); gsub(/[ÓÒÔÖÕ]/, "O", key); gsub(/[úùûüũ]/, "u", key); gsub(/[ÚÙÛÜŨ]/, "U", key); gsub(/æ/, "ae", key); gsub(/Æ/, "Ae", key); gsub(/œ/, "oe", key); gsub(/Œ/, "Oe", key); sub(/[^:]*:/, "", value); print "[[" key "," $$1 "]]" $$1 " : " value; }' > $@


.SECONDEXPANSION:
${ADOC_PDF}: %: $$(basename %)/$$(notdir $$(basename %)).xml ${ADOC_PROPERTIES} $$(basename %)/$$(notdir $$(basename %)).sty $$(wildcard $$(subst ${ADOC_OUTPUT_DIR}/,,$$(basename %)/$$(notdir $$(basename %))-docinfo.xml)) $$(wildcard $$(subst ${ADOC_OUTPUT_DIR}/,,$$(basename %)/$$(notdir $$(basename %)).properties))
	dblatex --output=${@} '--fig-path=$(subst ${ADOC_OUTPUT_DIR}/,,$(dir ${<}))'  -p '/etc/asciidoc/dblatex/asciidoc-dblatex.xsl' --texinputs '$(dir $(call get_tex_style,$<))' --texstyle=${<:.xml=.sty} $(shell gawk -F: '/^dblatex(.$(notdir $(basename ${@})))?:/{sub(/^[^:]*\s*:/,"",$$0); print $$0}' ${ADOC_PROPERTIES} $(wildcard $(subst ${ADOC_OUTPUT_DIR}/,,${*F}.properties))) $(shell echo -n "$(call get_var_from,dblatex,,$(patsubst %.sty,%.properties,$(call get_tex_style,$<)))") -I ${ADOC_OUTPUT_DIR} ${<}

${ADOC_OUTPUT_DIR}/%.adoc-conf: %.adoc $(wildcard %.properties) ${ADOC_PROPERTIES}
	@mkdir --parent $(dir $@)
	sed 's,{ADOC_TOOLS_DIR},${ADOC_TOOLS_DIR},' ${ADOC_TOOLS_DIR}/filters/latex/latex-filter.conf > ${@}
	awk '-F: |:' 'BEGIN{ print "\n[attributes]"; print "ADOC_TOOLS_DIR=${ADOC_TOOLS_DIR}"; print "REFERENCE=" '$(call get_doc_var,$<,ref,\")'; print "DOC_TITLE=" '"$(call get_doc_var,$<,title,\")"'; print "VERSION=" '$(call get_doc_var,$<,version,\")'; } $$0 ~ /.{1,}/ && $$0 !~ /^dblatex/ {gsub(/\./,"_",$$1); sub(/^\s*/,"",$$2); print toupper($$1)"="$$2;}' ${ADOC_PROPERTIES} >> ${@}

.SECONDEXPANSION:
${ADOC_OUTPUT_DIR}/%.sty: $$(call get_tex_style,%)
	$(if $<,,$(error No LaTeX style defined for $(notdir ${@:.sty=})))
	@mkdir --parent $(dir $@)
	\cp $< ${@}.tmp
	for var in $(shell sed -n 's/[^@]*@@\([^@]\+\)@@[^@]*/\1\n/gp' $<|sort -u); do \
		resolved_doc_var=$$(echo $${var}|sed 's,document\.,$(notdir ${@:.sty=}).,'); \
		sed -i 's~@@'$${var}'@@~'"$(call get_var,$${resolved_doc_var},,$(subst ${ADOC_OUTPUT_DIR}/,,${@}))"'~g' ${@}.tmp; \
	done
	sed -i 's/@@[^@]\+@@//g;s/\([^\]\)_/\1\\_/g' ${@}.tmp
	mv ${@}.tmp ${@}

${ADOC_OUTPUT_DIR}/%.xml: %.adoc ${ADOC_OUTPUT_DIR}/%.adoc-conf
	@mkdir --parent $(dir $@)
	asciidoc --doctype=article --out-file=${@} --backend docbook -a 'BUILD_DIR=$(abspath ${ADOC_OUTPUT_DIR})' -a lang=fr -a frame=topbot -a grid=none -a docinfo -a ascii-ids -a latex-table-rowlimit=1 $(addprefix --conf-file=, ${ADOC_CONF} ${@:.xml=.adoc-conf}) $<

adoc: ${ADOC_PDF}

adoc-clean:
	\rm -f ${ADOC_PDF} $(subst .xml,.adoc-conf,${DOCBOOKS}) ${DOCBOOKS} $(subst .xml,.sty,${DOCBOOKS}) $(subst .xml,.sty,${DOCBOOKS}) $(addprefix ${ADOC_OUTPUT_DIR}/uml/*.,pdf svg) $(shell find ${ADOC_OUTPUT_DIR} -type f -name \*-sorted.dvs)

.PHONY: adoc-clean
