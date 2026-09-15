# Get the design names
DESIGNS :=  $(patsubst designs/%/,%,$(wildcard designs/*/)) 

DESIGNS_HELP := $(addsuffix -help,$(DESIGNS))
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

$(DESIGNS_HELP):
	cd designs/$(subst -help,,$@); make help
.PHONY: $(DESIGNS_HELP)

$(DESIGNS_CLEAN):
	cd designs/$(subst -clean,,$@); make clean
.PHONY: $(DESIGNS_CLEAN)

$(DESIGNS_SYNTH):
	cd designs/$(subst -synth,,$@); make synth
.PHONY: $(DESIGNS_SYNTH)

$(DESIGNS_PNR):
	cd designs/$(subst -pnr,,$@); make pnr
.PHONY: $(DESIGNS_PNR)

$(DESIGNS_BIT):
	cd designs/$(subst -bit,,$@); make bit
.PHONY: $(DESIGNS_BIT)

$(DESIGNS_HEX):
	cd designs/$(subst -hex,,$@); make hex
.PHONY: $(DESIGNS_HEX)

$(DESIGNS_COPY):
	cd designs/$(subst -copy,,$@); make copy
.PHONY: $(DESIGNS_COPY)
