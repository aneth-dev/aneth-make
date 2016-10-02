# Dependencies:
#  - libtext-lorem-perl
# Debian packages: lmodern fonts-liberation libtext-lorem-perl

-include config.mk

ADOC_EXCLUDE        =
ADOC_OUTPUT_DIR    ?= build
PLANTUML_SKINPARAM  = acme-plantuml.skinparam
ADOC_PROPERTIES     = acme.properties test-project.properties

all: adoc

clean: adoc-clean

include ../../adoc.mk

.PHONY: all clean
