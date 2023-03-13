MODULE=test
SV_FILES := $(wildcard *.sv)
V_FILE := $(MODULE).v

SVG_JSON := $(MODULE)_svg.json
SVG_FILE := $(MODULE).svg
PNG_FILE := $(MODULE).png

.DEFAULT_GOAL := sim

#
# translate to verilog
#

$(V_FILE) : $(SV_FILES)
	sv2v -v --define=SYNTHESIS --write=$@ $^

#
# yosys
#
MODULE.log := $(MODULE).log
MODULE.json := $(MODULE).json
MODULE.asc := $(MODULE).asc
MODULE.bin := $(MODULE).bin

pcf := ../icebreaker.pcf
synTool := yosys
synTool.flags := \
    	-ql $(MODULE.log) \
    	-p 'synth_ice40 -abc9 -dffe_min_ce_use 4 -device u -dsp \
		-top $(MODULE) -json $(MODULE.json)'
pnr := nextpnr-ice40
pnr.flags := --up5k --package sg48 --json $(MODULE.json) --pcf $(pcf) --asc

pack := icepack
prog := iceprog

$(MODULE.json) : $(V_FILE)
	$(synTool) $(synTool.flags) $^

$(MODULE.asc) : $(MODULE.json)
	$(pnr) $(pnr.flags) $@

.PHONY: gui-pnr
gui-pnr:
	$(pnr) $(pnr.flags) $(MODULE.asc) --gui

$(MODULE.bin) : $(MODULE.asc)
	$(pack) $^ $@

.PHONY: synth
synth: $(MODULE.bin)

.PHONY: prog
prog:	$(MODULE.bin)
	$(prog) $^


#
# netlistsvg
#

$(SVG_JSON) : $(V_FILE)
	yosys -p "prep -top test; write_json $@" $^

$(SVG_FILE) : $(SVG_JSON)
	netlistsvg $^ -o $@

$(PNG_FILE): $(SVG_FILE)
	rsvg-convert -b white -h 2000 $(SVG_FILE) > $(PNG_FILE)

.PHONY: svg
svg: $(SVG_FILE)

.PHONY: png
png: $(PNG_FILE)

#
# verilator
#

.PHONY:sim

.PHONY:verilate
verilate: .stamp.verilate

.PHONY:build
build: obj_dir/Valu

.PHONY:waves
waves: waveform.vcd
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd

sim waveform.vcd: ./obj_dir/V$(MODULE)
	@echo
	@echo "### SIMULATING ###"
	@./obj_dir/V$(MODULE) +verilator+rand+reset+2

./obj_dir/V$(MODULE): .stamp.verilate
	@echo
	@echo "### BUILDING SIM ###"
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)

.stamp.verilate: $(SV_FILES) tb_$(MODULE).cpp
	@echo
	@echo "### VERILATING ###"
	verilator -Wall --trace --x-assign unique --x-initial unique \
		-cc $(MODULE).sv --top-module $(MODULE) \
		--exe tb_$(MODULE).cpp
	@touch .stamp.verilate

.PHONY:lint
lint: $(MODULE).sv
	verilator --lint-only $(MODULE).sv

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
	rm -rf $(V_FILE) $(SVG_JSON) $(SVG_FILE) $(PNG_FILE)
	rm -rf $(MODULE.log) $(MODULE.json) $(MODULE.asc) $(MODULE.bin)

