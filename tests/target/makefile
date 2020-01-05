IQUOTE    := inc
ISYSTEM   := $(addprefix cots/, foo bar)
IDIRAFTER :=
SRCDIR    := src

BUILDDIR_PREFIX := build/
include ../../gcc.mk

ifdef _MAIN_

.DEFAULT_GOAL = all
all: src/app.so

src/app.so: $(OBJ)
.PHONY: all
endif
