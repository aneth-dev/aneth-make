# Dependencies: see adoc/makefile

OUT=out

.PHONY: all clean adoc $(OUT)/tests/tests

all: $(OUT)/tests/tests adoc
clean:
	$(MAKE) --directory=tests OUT='$(realpath $(OUT))' clean
	rm -rf $(OUT)

adoc:
	$(MAKE) --directory=adoc ADOC_OUTPUT_DIR='$(realpath $(OUT))'

$(OUT):
	@[ -d $(OUT) ] || mkdir --parent '$(OUT)'

$(OUT)/tests/tests: $(OUT)
	$(MAKE) --directory=tests OUT='$(realpath $(OUT))' RELATIVE=tests

test: all
	LD_LIBRARY_PATH=$$(find $(OUT) -name \*.so|xargs dirname|sort -u|paste -sd:) $(OUT)/tests/tests tests
