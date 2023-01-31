#include "Vtest.h"

#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 540
std::uint64_t sim_time = 0;
std::uint64_t posedge_cnt = 0;

double sc_time_stamp() { return 0; }

int
main(int argc, char **argv, char **env)
{
    Vtest *dut = new Vtest;
    //SB_SPRAM256KA_dev spram_dev(dut);

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    while (sim_time < MAX_SIM_TIME) {
	dut->CLK ^= 1;

	if (dut->CLK == 1) {
	    posedge_cnt++;
	}
	dut->eval();

	m_trace->dump(sim_time);
	sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
