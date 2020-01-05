# Dependencies: see adoc/makefile

OUT=out

.PHONY: all clean adoc target

all: adoc target
clean:
	$(MAKE) --directory=target BUILDDIR_PREFIX='$(realpath $(OUT))' clean
	rm -rf $(OUT)

adoc: $(OUT)
	$(MAKE) --directory=adoc ADOC_OUTPUT_DIR='$(realpath $(OUT))/'

target: $(OUT)
	$(MAKE) --directory=target BUILDDIR_PREFIX='$(realpath $(OUT))/'

$(OUT):
	@[ -d $(OUT) ] || mkdir --parent '$(OUT)'

test: all
#	LD_LIBRARY_PATH=$$(find $(OUT) -name \*.so|xargs dirname|sort -u|paste -sd:) $(OUT)/tests/tests tests
