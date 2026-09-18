# Adjust sources
RTL = -DSTAGES=$(STAGES) clk_timing.v ../../primitive_wrappers.v
TOP = clk_timing
STAGES ?= 8

# Global IO constraints + absolute placement of the LUT chain
PCF_CONSTRAINTS = $(abspath clk_timing.pcf)

# Include base Makefile
include ../../makefile.include

# always regenerated: STAGES/SEED are make variables, not file dependencies
clk_timing.pcf: FORCE
	cat ../../../fabulous/constraints.pcf > $@
	python3 place_chain.py $(STAGES) $(SEED) >> $@
FORCE:

pnr: clk_timing.pcf
