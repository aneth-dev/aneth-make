#IQUOTE
#ISYSTEM
#IDIRAFTER
#LIBS
SRCDIR ?= .
SRCEXT ?= $(C_EXT) $(CXX_EXT)

PRINT_MACHINE ?= $(CC) -dumpmachine
BUILDDIR_SUFFIX ?= $(shell $(PRINT_MACHINE))

SRCDIR += $(IQUOTE)
include $(realpath $(dir $(lastword ${MAKEFILE_LIST})))/target.mk

C_EXT := c
H_EXT := h
CXX_EXT := cc cxx C cpp
HXX_EXT := hh hxx H hpp

DEPFLAGS ?= -MG -MM

ifndef _MAIN_

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
SRC      += $(foreach src_dir, $(SRCDIR), $(call rwildcard, $(src_dir)/, $(addprefix *., $(SRCEXT))))
CPPFLAGS += $(addprefix -isystem , $(foreach isy, $(ISYSTEM), $(realpath $(isy)))) \
            $(addprefix -iquote , $(foreach iqt, $(IQUOTE), $(realpath $(iqt)))) \
            $(addprefix -idirafter , $(foreach idirafter, $(IDIRAFTER), $(realpath $(idirafter))))
LDLIBS   += $(addprefix -l,$(LIBS))
HEADERS  := $(foreach iquote, $(IQUOTE), $(call rwildcard, $(iquote)/, $(addprefix *., $(H_EXT) $(HPP_EXT))))
export SRC HEADERS CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LDLIBS

else

OBJ := $(SRC:%=%.o)

define depends_gcc
	@set -e; \
	$1 $(DEPFLAGS) $(CPPFLAGS) $< > $@.$$$$; \
	sed '1s,^,$(@D)/,;1s,:, $@:,' $@.$$$$ > $@; \
	rm $@.$$$$
endef

%.c.d:   %.c;   $(call depends_gcc, $(CC))
%.h.d:   %.h;   $(call depends_gcc, $(CC))
%.cc.d:  %.cc;  $(call depends_gcc, $(CXX))
%.cpp.d: %.cpp; $(call depends_gcc, $(CXX))
%.C.d:   %.C;   $(call depends_gcc, $(CXX))
%.cxx.d: %.cxx; $(call depends_gcc, $(CXX))
%.hh.d:  %.hh;  $(call depends_gcc, $(CXX))
%.hxx.d: %.hxx; $(call depends_gcc, $(CXX))
%.hpp.d: %.hpp; $(call depends_gcc, $(CXX))
%.H.d:   %.H;   $(call depends_gcc, $(CXX))

%.c.o:   %.c;   $(COMPILE.c)  -o $@ $<
%.h.o:   %.h;   $(COMPILE.c)  -o $@ $<
%.cc.o:  %.cc;  $(COMPILE.cc) -o $@ $<
%.cpp.o: %.cpp; $(COMPILE.cc) -o $@ $<
%.C.o:   %.C;   $(COMPILE.cc) -o $@ $<
%.cxx.o: %.cxx; $(COMPILE.cc) -o $@ $<
%.hh.o:  %.hh;  $(COMPILE.cc) -o $@ $<
%.hxx.o: %.hxx; $(COMPILE.cc) -o $@ $<
%.hpp.o: %.hpp; $(COMPILE.cc) -o $@ $<
%.H.o:   %.H;   $(COMPILE.cc) -o $@ $<

%.so: ;   $(LINK.c) -shared -o $@ $^

.PHONY: headers
headers: $(addsuffix .o, $(HEADERS))


.PRECIOUS: $(addsuffix .d, $(SRC))
-include $(addsuffix .d, $(SRC))
unexport SRC CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LDLIBS

endif
