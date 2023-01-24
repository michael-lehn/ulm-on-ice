MODULE=test
SV_FILES = $(MODULE).sv \
	   $(filter-out $(MODULE).sv,$(wildcard *.sv)) \
	   $(filter-out %test.sv,$(wildcard ../fifo/*.sv)) \
	   $(filter-out %test.sv,$(wildcard ../tx_pipe/*.sv))

.PHONY: sim
sim waveform.vcd: ./obj_dir/V$(MODULE)
	@echo
	@echo "### SIMULATING ###"
	@./obj_dir/V$(MODULE) +verilator+rand+reset+2


.PHONY: verilate
verilate: .stamp.verilate

.PHONY: build
build: obj_dir/Valu

.PHONY:waves
waves: waveform.vcd
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd

./obj_dir/V$(MODULE): .stamp.verilate
	@echo
	@echo "### BUILDING SIM ###"
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)

.stamp.verilate: $(SV_FILES) tb_$(MODULE).cpp
	@echo
	@echo "### VERILATING ###"
	verilator -Wall --trace --x-assign unique --x-initial unique \
		-cc --exe tb_$(MODULE).cpp \
		$(SV_FILES)
	@touch .stamp.verilate

.PHONY: lint
lint: $(MODULE).sv
	verilator --lint-only ./$(MODULE).sv

.PHONY: prog
prog:
	make -f Makefile.yosys prog

.PHONY: yosys
yosys:
	make -f Makefile.yosys

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
	make -f Makefile.yosys clean

