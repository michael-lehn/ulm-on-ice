#include "Vtest.h"

#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 70

int
main(int argc, char **argv, char **env)
{
    Vtest *dut = new Vtest;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    std::uint64_t sim_time = 0;
    std::uint64_t posedge_cnt = 0;
    std::uint64_t numLoaded = 0;

    std::size_t numCh = 0;

    while (sim_time < MAX_SIM_TIME) {
	dut->CLK ^= 1;

	if (dut->CLK == 1) {
	    posedge_cnt++;

	    dut->B0 = 0;
	    dut->B1 = 0;
	    dut->B2 = 0;
	    dut->B3 = 0;
	    dut->B4 = 0;
	    dut->B5 = 0;
	    dut->B6 = 0;
	    dut->B7 = 0;
	    switch (posedge_cnt) {
		case 5:
		    dut->B0 = 1;
		    dut->B1 = 1;
		    dut->BTN1 = 1;
		    break;
		case 8:
		    dut->B1 = 1;
		    dut->BTN1 = 1;
		    break;
		case 11:
		    dut->B0 = 1;
		    dut->B7 = 1;
		    dut->BTN1 = 0;
		    break;
		default:
		    dut->BTN1 = 0;
	    }
	}
	dut->eval();

	m_trace->dump(sim_time);
	sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
