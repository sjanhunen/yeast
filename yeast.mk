# Makefile for the yeast build system

#
# Top-level phony targets
#

.PHONY: all clean

all: $(YEAST.SPORES)
clean: $(addsuffix _clean, $(YEAST.SPORES))

#
# Include toolchain definitions
#

include toolchains/*.mk

#
# Define build tree structure
#

YEAST.BUILD.TREE ?= yeast.build

ifdef YEAST_TOOL
YEAST.ARCH_TOOL.NAME = $(addprefix $(addsuffix .,$(YEAST_ARCH)),$(YEAST_TOOL))
else
YEAST.ARCH_TOOL.NAME = $(YEAST_ARCH)
endif

ifneq ($(strip $(YEAST.BUILD.TREE)),)
YEAST.OBJECT.PATH = $(YEAST.BUILD.TREE)/obj/$(YEAST.ARCH_TOOL.NAME)/
YEAST.EXECUTABLE.PATH = $(YEAST.BUILD.TREE)/bin/$(YEAST.ARCH_TOOL.NAME)/
YEAST.STATIC_LIB.PATH = $(YEAST.BUILD.TREE)/lib/$(YEAST.ARCH_TOOL.NAME)/
YEAST.SPORE.SUFFIX = $(addprefix .,$(YEAST.ARCH_TOOL.NAME)).spore
YEAST.SPORE.PATH = $(YEAST.BUILD.TREE)/
else
YEAST.SPORE.SUFFIX = .spore
endif

#
# Create spore definitions 
#

include toolchains/*.mk
define YEAST_SPORE_RULES

.PHONY: $1
.PHONY: $1_clean

$1.name ?= $1
$1.spore = $(YEAST.SPORE.PATH).$$($1.name)$(YEAST.SPORE.SUFFIX)

$1.object = $$(addsuffix .$(1)$(TOOL.OBJECT.SUFFIX), $$(basename $$($1.source)))
$1.object := $$(addprefix $(YEAST.OBJECT.PATH), $$($1.object))

$1: $$($1.spore)

$$($1.spore):
	touch $$@

$1_clean:
	rm -f $$($1.products) $$($1.object) $$($1.spore)

endef

$(foreach t, $(YEAST.SPORES), $(eval $(call YEAST_SPORE_RULES,$t)))

#
# Create build tree structure
#

$(YEAST.OBJECT.PATH) $(YEAST.EXECUTABLE.PATH) $(YEAST.STATIC_LIB.PATH):
	mkdir -p $@

#
# Include source language-specific rules
#

include languages/*.mk

#
# Include build product-specific rules
#

include products/*.mk
