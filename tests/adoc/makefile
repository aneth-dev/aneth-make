-include config.mk

ADOC_EXCLUDE        =
ADOC_OUTPUT_DIR    ?= build
PLANTUML_SKINPARAM  =  acme-plantuml.skinparam
ADOC_PROPERTIES     =  acme.properties test-project.properties
ADOC_LATEX_STYLE    =  acme.sty

all: adoc

clean: adoc-clean

include ../../adoc.mk

.PHONY: all clean
