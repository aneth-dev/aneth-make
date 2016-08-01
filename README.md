Æten-make
=========

java.mk
-------
Makefile for Java projects

c.mk
----
Generic makefile for c/c++ libraries or programs

adoc.mk
----
Generic makefile for asciidoc PDF generation with dblatex backend. It provides easy stylesheet customization. See tests/adoc/ directory for usage example.

generate-builder
----------------
A tool for Make or Ninja files generation from a template which can be used in configuration scripts.
See [aeten-cli's configure script](https://github.com/aeten/aeten-cli/blob/master/configure) for a use case example.

ninja2make
----------
A Sed script which convert a Ninja build file to a Make file.
See [aeten-cli's configure script](https://github.com/aeten/aeten-cli/blob/master/configure) for a use case example.

