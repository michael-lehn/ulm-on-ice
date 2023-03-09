#include "Vtest.h"
#include "Vtest_dev_io.h"
#include "Vtest_test.h"
#include "Vtest_uart_rx__B2580.h"

#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 700

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
    std::uint64_t addr = 0;
    std::uint64_t val = 'A';
    std::uint64_t size = 2;	 // RAM_WORD_SIZE in bytes
    std::uint64_t data_type = 1; // RAM_WORD

    std::size_t numBytes = 3;

    std::size_t numCh = 0;

    while (sim_time < MAX_SIM_TIME) {
	dut->CLK ^= 1;
	dut->eval();

	if (dut->CLK == 1) {
	    dut->op = 0;
	    dut->addr = 0;
	    if (posedge_cnt % 2 == 0) {
		if (val < 'A' + numBytes) {
		    dut->op = 2; // store
		    dut->data_type = data_type;
		    dut->data_in = val++;
		    dut->addr = addr;
		    if (val == 'A' + numBytes) {
			addr = -size;
		    }
		} else {
		    dut->op = 1; // fetch
		    dut->addr = addr;
		}
	    } else {
		addr += size;
	    }
	    ++posedge_cnt;
	}
	m_trace->dump(sim_time);

	sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
