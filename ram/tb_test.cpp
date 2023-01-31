#include "Vtest.h"
#include "Vtest_test.h"
#include "Vtest_ram_pkg.h"

#include <cstdlib>
#include <iomanip>
#include <ios>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 140

double sc_time_stamp() { return 0; }

void
store(Vtest *dut, std::uint64_t posedge_cnt)
{
    static std::size_t addr = 0;
    static int num_quad = 1;
    static int num_long = 2;
    static int num_word = 4;
    static int num_byte = 8;

    dut->test->ram_op = Vtest_ram_pkg::RAM_NOP;
    if (posedge_cnt % 2) {
	return;
    }

    if (num_quad > 0) {
	dut->test->ram_addr = addr;
	dut->test->ram_size = 8;
	dut->test->ram_op = Vtest_ram_pkg::RAM_STORE;
	dut->test->ram_data_in = 0x123456789;

	--num_quad;
	addr += 8;
    }
    if (num_long > 0) {
	dut->test->ram_addr = addr;
	dut->test->ram_size = 4;
	dut->test->ram_op = Vtest_ram_pkg::RAM_STORE;
	dut->test->ram_data_in = 0x123456789;

	--num_quad;
	addr += 4;
    }
    if (num_word > 0) {
	dut->test->ram_addr = addr;
	dut->test->ram_size = 2;
	dut->test->ram_op = Vtest_ram_pkg::RAM_STORE;
	dut->test->ram_data_in = 0x123456789;

	--num_quad;
	addr += 2;
    }
    if (num_byte > 0) {
	dut->test->ram_addr = addr;
	dut->test->ram_size = 2;
	dut->test->ram_op = Vtest_ram_pkg::RAM_STORE;
	dut->test->ram_data_in = 0x123456789;

	--num_quad;
	addr += 1;
    }
}


int
main(int argc, char **argv, char **env)
{
    Vtest *dut = new Vtest;
    //SB_SPRAM256KA_dev spram_dev(dut);

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    std::uint64_t sim_time = 0;
    std::uint64_t posedge_cnt = 0;
    bool fetch_r = false;

    while (sim_time < MAX_SIM_TIME) {
	dut->CLK ^= 1;

	if (dut->CLK == 1) {
	    posedge_cnt++;
	    // generate here stimulus
	    store(dut, posedge_cnt);
	}
	dut->eval();
	m_trace->dump(sim_time);

	// check here states
	if (dut->CLK == 1) {
	    if (dut->test->ram_op == Vtest_ram_pkg::RAM_STORE) {
		std::cout << std::dec << posedge_cnt << " STORE" << std::endl;
		std::cout << "  ram_addr = 0x" << std::hex
		    << std::setfill ('0') << std::setw (5)
		    << dut->test->ram_addr
		    << std::endl;
		std::cout << "  ram_size = " << std::dec
		    << dut->test->ram_size << " bits"
		    << std::endl;
		std::cout << "  ram_data_in = 0x" << std::hex
		    << std::setfill ('0') << std::setw (16)
		    << dut->test->ram_data_in
		    << std::endl;
	    }


	    if (dut->test->ram_op == Vtest_ram_pkg::RAM_FETCH) {
		std::cout << std::dec << posedge_cnt << " FETCH" << std::endl;
		std::cout << "  ram_addr = 0x" << std::hex
		    << std::setfill ('0') << std::setw (5)
		    << dut->test->ram_addr
		    << std::endl;
		std::cout << "  ram_size = " << std::dec
		    << dut->test->ram_size << " bits"
		    << std::endl;
	    }
	    if (fetch_r) {
		std::cout << std::dec << posedge_cnt << std::endl;
		std::cout << "  ram_data_out = 0x" << std::hex
		    << std::setfill ('0') << std::setw (16)
		    << dut->test->ram_data_out
		    << std::endl;
	    }
	}

	fetch_r = dut->test->ram_op == Vtest_ram_pkg::RAM_FETCH;
	sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
