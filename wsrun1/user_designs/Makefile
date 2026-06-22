# Get the design names
DESIGNS :=  $(patsubst designs/%/,%,$(wildcard designs/*/)) 

DESIGNS_CLEAN := $(addsuffix -clean,$(DESIGNS))
DESIGNS_SYNTH := $(addsuffix -synth,$(DESIGNS))
DESIGNS_PNR := $(addsuffix -pnr,$(DESIGNS))
DESIGNS_BIT := $(addsuffix -bit,$(DESIGNS))
DESIGNS_HEX := $(addsuffix -hex,$(DESIGNS))
DESIGNS_COPY := $(addsuffix -copy,$(DESIGNS))

all: $(DESIGNS)
.PHONY: all

clean: $(DESIGNS_CLEAN)
.PHONY: clean

copy: $(DESIGNS_COPY)
.PHONY: copy

$(DESIGNS):
	cd designs/$@; make
.PHONY: $(DESIGNS)

$(DESIGNS_CLEAN):
	cd designs/$(subst -clean,,$@); make clean
.PHONY: $(DESIGNS_CLEAN)

$(DESIGNS_SYNTH):
	cd designs/$(subst -synth,,$@); make synth
.PHONY: $(DESIGNS_SYNTH)

$(DESIGNS_PNR):
	cd designs/$(subst -synth,,$@); make pnr
.PHONY: $(DESIGNS_PNR)

$(DESIGNS_BIT):
	cd designs/$(subst -synth,,$@); make bitstream
.PHONY: $(DESIGNS_BIT)

$(DESIGNS_HEX):
	cd designs/$(subst -synth,,$@); make hex
.PHONY: $(DESIGNS_HEX)

$(DESIGNS_COPY):
	cp designs/$(subst -copy,,$@)/$(subst -copy,,$@).bit ../board/bitstreams/$(subst -copy,,$@).bit
.PHONY: $(DESIGNS_COPY)
