# Dependencies:
#  - asciidoc,
#  - telive-xetex,
#  - lmodern,
#  - fonts-liberation,
#  - plantuml.jar (schemas UML),
#  - graphviz (used by plantuml),
#  - dblatex (docbook -> latex),
#  - pdf2svg (pdf -> svg),
#  - rsvg-convert (svg -> pdf),
#  - libtext-lorem-perl (only for this test)
# Debian packages: asciidoc dblatex pdf2svg poppler-utils librsvg2-bin graphviz telive-xetex lmodern fonts-liberation libtext-lorem-perl

ADOC_OUTPUT_DIR ?= .
ADOC_MAKE_DIR = $(dir $(filter %/adoc.mk,${MAKEFILE_LIST}))

ifeq ("$(wildcard ${ADOC_PROPERTIES})","")
$(error Please set ADOC_PROPERTIES variable at least to the project properties file location)
endif

ifneq ("$(wildcard ${PLANTUML_SKINPARAM})","")
PLANTUML_SKIN ?= $(shell awk -F'\t' '$$2 != "" {print " -S"$$1"="$$2}' ${PLANTUML_SKINPARAM})
endif

PLANTUML ?= /etc/asciidoc/filters/plantuml/plantuml.jar
ifeq ("$(wildcard ${PLANTUML})","")
$(error Please set PLANTUML variable to the PlantUML jar file location)
endif

DBLATEX_XSL ?= /etc/asciidoc/dblatex/asciidoc-dblatex.xsl
ifeq ("$(wildcard ${DBLATEX_XSL})","")
$(error Please set DBLATEX_XSL variable to the dblatex XSL file location)
endif

DOCBOOKS = $(addprefix ${ADOC_OUTPUT_DIR}/,$(subst .adoc,.xml,$(shell find . -type f -name \*.adoc $(addprefix -and -not -samefile ,${ADOC_EXCLUDE}))))
ADOC_PDF = $(addsuffix .pdf,$(patsubst %/,%,$(dir ${DOCBOOKS})))

.SECONDEXPANSION:
${DOCBOOKS}: %: $$(foreach req,$$(shell sed -n -e 's,^\(include\|image\)::{BUILD_DIR},\1::..,' -e 's,^\(include\|image\)::\(.*\)\[\],$$(subst ${ADOC_OUTPUT_DIR}/,,$$(dir $$@))/\2,p' $$(subst .xml,.adoc,$$(subst ${ADOC_OUTPUT_DIR}/,,$$@))),$$(shell [ -f '$${req}' ] && echo '$${req}' || echo '${ADOC_OUTPUT_DIR}/$${req}')) $$(subst .xml,.adoc-conf,$$@)

${ADOC_OUTPUT_DIR}/%.svg: %.plantuml ${PLANTUML_SKINPARAM} ${ADOC_PROPERTIES}
	@mkdir --parent $(dir $@)
	$(eval colors=$(shell gawk -F: 'match($$1,/^rgb\..*$$/,a){sub(/^\s*rgb\.\s*/,"",$$1); sub(/^\s/,"",$$2); print "-D" $$1 "=" $$2}' ${ADOC_PROPERTIES}))
	java -jar ${PLANTUML} ${colors} ${PLANTUML_SKIN} -ofile $@ -tsvg $<

%.pdf: %.svg
	rsvg-convert -f pdf -o $@ $^

${ADOC_OUTPUT_DIR}/%-sorted.dvs: %.dvs
	@mkdir --parent $(dir $@)
	cat $< | sort | awk -F' :' '{key=$$1; value=$$0; gsub(/[- ]/, "_", key); sub(/[^:]*:/, "", value); print "[[" key "," $$1 "]]" $$1 " : " value; }' > $@


.SECONDEXPANSION:
${ADOC_PDF}: %: $$(basename %)/$$(notdir $$(basename %)).xml ${ADOC_PROPERTIES} $$(basename %)/$$(notdir $$(basename %)).sty $$(wildcard $$(subst ${ADOC_OUTPUT_DIR}/,,$$(basename %)/$$(notdir $$(basename %))-docinfo.xml))
	dblatex --output=${@} '--fig-path=$(subst ${ADOC_OUTPUT_DIR}/,,$(dir ${<}))'  -p '/etc/asciidoc/dblatex/asciidoc-dblatex.xsl' --texinputs $(dir ${ADOC_LATEX_STYLE}) --texstyle=${<:.xml=.sty} $(shell gawk -F: '/^dblatex(.$(notdir $(basename ${@})))?:/{sub(/^[^:]*\s*:/,"",$$0); print $$0}' ${ADOC_PROPERTIES}) ${<}

${ADOC_OUTPUT_DIR}/%.adoc-conf: %.adoc ${ADOC_PROPERTIES}
	@mkdir --parent $(dir $@)
	awk '-F: |:' 'BEGIN{ print "[attributes]"; print "REFERENCE=" '$(call get_doc_var,$<,ref)'; print "TITLE=" '"$(call get_doc_var,$<,title)"'; print "VERSION=" '$(call get_doc_var,$<,version)'; } $$0 ~ /.{1,}/ && $$0 !~ /^dblatex/ {gsub(/\./,"_",$$1); sub(/^\s*/,"",$$2); print toupper($$1)"="$$2;}' ${ADOC_PROPERTIES} > ${@}

${ADOC_OUTPUT_DIR}/%.sty: %.adoc ${ADOC_LATEX_STYLE} 
	@mkdir --parent $(dir $@)
	\cp ${ADOC_LATEX_STYLE} ${@}.tmp
ifneq (${ADOC_LATEX_STYLE},"")
	for var in project.name project.ref $(addprefix $(notdir ${@:.sty=}).,title ref version diffusion.internal diffusion.external) $(foreach actor,$(addprefix $(notdir ${@:.sty=}).,redactor verifier valider formalize client), $(addprefix ${actor},.title .name .date .visa)); do \
		sed -i 's/@@'$$(echo $${var}|sed 's,$(notdir ${@:.sty=}).,document.,')'@@/'"$(call get_var,$$var,)"'/g' ${@}.tmp; \
	done
	sed -i 's/@@[^@]\+@@//g;s/\([^\]\)_/\1\\_/g' ${@}.tmp
endif
	mv ${@}.tmp ${@}

${ADOC_OUTPUT_DIR}/%.xml: %.adoc
	@mkdir --parent $(dir $@)
	asciidoc -a a2x-format=pdf --doctype=article --out-file=${@} --backend docbook -a 'BUILD_DIR=$(abspath ${ADOC_OUTPUT_DIR})' -a lang=fr -a frame=topbot -a grid=none -a docinfo -a ascii-ids -a latex-table-rowlimit=1 --conf-file=${@:.xml=.adoc-conf} $<

adoc: ${ADOC_PDF}

adoc-clean:
	\rm -f ${ADOC_PDF} $(subst .xml,.adoc-conf,${DOCBOOKS}) ${DOCBOOKS} $(subst .xml,.sty,${DOCBOOKS}) $(subst .xml,.sty,${DOCBOOKS}) $(addprefix ${ADOC_OUTPUT_DIR}/uml/*.,pdf svg) $(shell find ${ADOC_OUTPUT_DIR} -type f -name \*-sorted.dvs)

get_var=$$(awk -F: "/^$1:/"'{sub(/^\s*/,"",$$2);value="$2"$$2"$2"} END{print value}' ${ADOC_PROPERTIES})
get_doc_var=$(call get_var,$(basename $(notdir $1)).$2,\")

.PHONY: adoc-clean
