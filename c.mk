CC=gcc
CFLAGS=
CPPFLAGS=
CXXFLAGS=
LDFLAGS=
INCLUDE_SYSTEM=

include config.mk

libname = $(notdir $(realpath $(dir $MAKEFILE)))$(if $(findstring -shared,$(LDFLAGS)),.so,)
OUT ?= .
RELATIVE ?= .
src ?= .

out=$(OUT)/$(RELATIVE)

libs=$(foreach dep,$(deps),$(out)/$($(dep)))
headers=$(foreach dep,$(deps),$($(dep))/$($(dep).api))
LDFLAGS+=$(addprefix -L,$(libs)) $(addprefix -l,$(deps))
INCFLAGS=$(addprefix -iquote ,$(api)) $(addprefix -iquote ,$(headers)) $(addprefix -isystem ,$(INCLUDE_SYSTEM))
SO_DEPS=$(foreach lib,$(libs),$(out)/$(lib)/lib$(patsubst lib%,%,$(notdir $(lib))).so)
SOURCES=$(shell find $(src) -type f -name '*.c' -or -name '*.cpp')
OBJECTS=$(addprefix $(out)/,$(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(SOURCES))))
HEADERS=$(shell find $(api) -type f -name '*.h' -or -name '*.hpp')
HEADER_OBJECTS=$(addprefix $(out)/,$(patsubst %.h,%.h.o,$(patsubst %.hpp,%.hpp.o,$(HEADERS))))

.PHONY: all clean headers

%.so:
	$(MAKE) --directory=$($(subst lib,,$(subst .so,,$(notdir $@)))) OUT='$(out)' RELATIVE='$(subst $(out)/,,$(dir $@))'

$(out)/%.h.o: %.h
	@[ -d $(dir $@) ] || mkdir --parent $(dir $@)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INCFLAGS) -c -o $@ $^

$(out)/%.hpp.o: %.hpp
	@[ -d $(dir $@) ] || mkdir --parent $(dir $@)
	$(CC) $(CXXFLAGS) $(CPPFLAGS) $(INCFLAGS) -c -o $@ $^

$(out)/%.o: %.c
	[ -d $(dir $@) ] || mkdir --parent $(dir $@)
	$(CC) $(CFLAGS)  $(CPPFLAGS)  $(INCFLAGS)-c -o $@ $^

$(out)/%.o: %.cpp
	[ -d $(dir $@) ] || mkdir --parent $(dir $@)
	$(CC) $(CXXFLAGS)  $(CFLAGS)  $(INCFLAGS) -c -o $@ $^

$(info HEADER_OBJECTS=$(HEADER_OBJECTS))
$(out)/$(libname): headers $(SO_DEPS) $(OBJECTS)
	@echo build $(out) $(libname) $@
	@[ -d $(out) ] || mkdir --parent $(out)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

all: $(out)/$(libname)

headers: $(HEADER_OBJECTS)

clean:
	rm -f $(OBJECTS) $(HEADER_OBJECTS)
	rm -rf $(out)/$(libname)
