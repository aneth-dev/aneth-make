OUT=out

.PHONY: all clean $(OUT)/tests/tests

all: $(OUT)/tests/tests
clean:
	$(MAKE) --directory=tests OUT='$(realpath $(OUT))' clean
	rm -rf $(OUT)

$(OUT):
	@[ -d $(OUT) ] || mkdir --parent '$(OUT)'

$(OUT)/tests/tests: $(OUT)
	$(MAKE) --directory=tests OUT='$(realpath $(OUT))' RELATIVE=tests

test: $(OUT)/tests/tests
	LD_LIBRARY_PATH=$$(find $(OUT) -name \*.so|xargs dirname|sort|uniq|paste -sd:) $(OUT)/tests/tests tests
