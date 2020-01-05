
ifeq (n,$(findstring n,${MAKEFLAGS}))
JUST_PRINT := yes
endif

ifndef _MAIN_
ifndef ROOTLEVEL
ROOTLEVEL := $(MAKELEVEL)
export ROOTLEVEL
endif
endif

ifeq ($(ROOTLEVEL),$(MAKELEVEL))

MAKEFILES := $(filter-out $(lastword $(MAKEFILE_LIST)), $(MAKEFILE_LIST))
MAKEFILES := $(realpath $(filter-out $(lastword $(MAKEFILES)), $(MAKEFILES)))

.SUFFIXES:

BUILDDIR_PREFIX ?= build/
BUILDDIR ?= $(BUILDDIR_PREFIX)$(BUILDDIR_SUFFIX)
export BUILDDIR

ifdef JUST_PRINT

_MAIN_ := $(lastword $(MAKEFILES))

else

.PHONY: $(BUILDDIR)
$(BUILDDIR):
	@find $(SRCDIR) -type d -exec mkdir -p '$@/{}' \;
	+@$(MAKE) --no-print-directory -C $@ $(addprefix -f , $(MAKEFILES)) VPATH=$(CURDIR) --include-dir $(CURDIR) $(MAKECMDGOALS)

$(MAKEFILE_LIST) : ;
$(or $(filter-out clean, $(MAKECMDGOALS)), $(filter-out $(BUILDDIR), $(.DEFAULT_GOAL))) :: $(BUILDDIR) ;

endif

.PHONY: clean
clean:
	$(RM) -r $(BUILDDIR)

else
unexport ROOTLEVEL
_MAIN_ := $(lastword $(MAKEFILES))
endif


