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
pnr.common := --pcf-allow-unconstrained --up5k --package sg48 --json $(MODULE.json) --pcf $(pcf)
pnr.flags := $(pnr.common) --asc

pack := icepack
prog := iceprog

$(MODULE.json) : $(V_FILE)
	$(synTool) $(synTool.flags) $^

$(MODULE.asc) : $(MODULE.json)
	$(pnr) $(pnr.flags) $@

.PHONY: gui-pnr
gui-pnr: $(MODULE.json)
	$(pnr) $(pnr.flags) $(MODULE.asc) --gui

$(MODULE.bin) : $(MODULE.asc)
	$(pack) $^ $@

.PHONY: synth
synth: $(MODULE.bin)

.PHONY: prog
prog:	$(MODULE.bin)
	$(prog) $^


#
# report: resource usage of the design
#
REPORT := $(MODULE)_report.txt
REPORT.pnr_log := $(MODULE)_report_pnr.log
REPORT.stat := $(MODULE)_report_stat.txt

.PHONY: report
report: $(REPORT)
	@cat $(REPORT)

$(REPORT) : $(MODULE.json) $(V_FILE)
	@echo "### PLACE AND ROUTE (for report) ###"
	@$(pnr) $(pnr.common) --log $(REPORT.pnr_log) > /dev/null 2>&1
	@echo "### SYNTHESIS PER MODULE (for report) ###"
	@yosys -q -p 'synth_ice40 -noflatten -dsp -top $(MODULE); tee -q -o $(REPORT.stat) stat' $(V_FILE)
	@{ \
	    echo "Resource report for $(MODULE) in $$(basename $$(pwd))"; \
	    echo; \
	    echo "== Device utilisation (nextpnr, iCE40 UP5K) =="; \
	    echo "   ICESTORM_LC = logic cell (4-input LUT + flip-flop)"; \
	    echo; \
	    awk '/Device utilisation/ { u = 1; next } \
	         u && !/^Info:[[:space:]]+[A-Za-z0-9_]+:[[:space:]]+[0-9]+\// { exit } \
	         u' $(REPORT.pnr_log) \
	        | grep -v -E ':[[:space:]]+0/' \
	        | awk '{ printf "    %-16s %6s %6s %5s\n", $$2, $$3, $$4, $$5 }'; \
	    echo; \
	    fmax=$$(grep 'Max frequency' $(REPORT.pnr_log) | tail -n 1 | sed 's/^Info: *//'); \
	    printf '%s\n' "$${fmax:-No clock in design, so no max frequency}"; \
	    echo; \
	    echo "== Cells per module (yosys) =="; \
	    echo "   first line: the whole design; below it: the cells of each submodule"; \
	    echo "   itself, without its own submodules (indented under it)"; \
	    echo "   cells = LUTs, flip-flops, carry cells, RAMs, ... (before packing into logic cells)"; \
	    echo "   modules with interface ports are merged into their parent by sv2v"; \
	    echo; \
	    hier=$$(awk '/=== design hierarchy ===/ { h = 1; next } \
	         h && /Count including submodules/ { p = 1; getline; next } \
	         p && /^ *$$/ { exit } \
	         p { print }' $(REPORT.stat)); \
	    if [ -z "$$hier" ]; then \
	        hier=$$(awk '/^=== $(MODULE) ===/ { t = 1 } \
	             t && / cells$$/ { printf "%9d $(MODULE)\n", $$1; exit }' $(REPORT.stat)); \
	    fi; \
	    printf '%s\n' "$$hier" | sed -E -e 's/\$$paramod\$$[0-9a-f]+\\//' \
	                           -e 's/\$$paramod\\([^\\]+)\\.*/\1/'; \
	} > $@

#
# floorplan: where the design ends up on the chip (HTML page)
#
TOOLS := ../tools
FLOORPLAN := $(MODULE)_floorplan.html
FLOORPLAN.dump := $(MODULE)_pnr_dump.json

.PHONY: floorplan
floorplan: $(FLOORPLAN)
	@echo "Wrote $(FLOORPLAN)"
	@if command -v open > /dev/null; then open $(FLOORPLAN); fi

$(FLOORPLAN.dump) : $(MODULE.json) $(TOOLS)/pnr_dump.py
	@echo "### PLACE AND ROUTE (for floorplan) ###"
	@PNR_DUMP=$@ $(pnr) $(pnr.common) --post-route $(TOOLS)/pnr_dump.py \
	    > /dev/null 2>&1

$(FLOORPLAN) : $(FLOORPLAN.dump) $(TOOLS)/floorplan.py
	@python3 $(TOOLS)/floorplan.py $< $@ "$(notdir $(CURDIR))"

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
build: ./obj_dir/V$(MODULE)

.PHONY:waves
waves: waveform.vcd
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd

.PHONY:surfer
surfer: waveform.vcd
	@echo
	@echo "### WAVES (surfer) ###"
	surfer waveform.vcd

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
		-Wno-fatal \
		-cc $(SV_FILES) --top-module $(MODULE) \
		--exe tb_$(MODULE).cpp
	@touch .stamp.verilate

.PHONY:lint
lint: $(SV_FILES)
	verilator --lint-only $(SV_FILES) --top-module $(MODULE)

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
	rm -rf $(V_FILE) $(SVG_JSON) $(SVG_FILE) $(PNG_FILE)
	rm -rf $(MODULE.log) $(MODULE.json) $(MODULE.asc) $(MODULE.bin)
	rm -rf $(REPORT) $(REPORT.pnr_log) $(REPORT.stat)
	rm -rf $(FLOORPLAN) $(FLOORPLAN.dump)

