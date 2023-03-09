#include "Vtest.h"
#include "Vtest_test.h"
#include "Vtest_dev_io.h"
#include "Vtest_uart_rx__B2580.h"

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

	dut->eval();

	if (dut->CLK == 1) {
	    posedge_cnt++;
	    switch (posedge_cnt) {
		case 5:
		    dut->test->io0->uart_rx0->rx_ready = 1;
		    dut->test->io0->uart_rx0->rx_data = 'A';
		    dut->test->BTN1 = 1;
		    dut->test->BTN2 = 1;
		    break;
		case 7:
		    dut->test->BTN1 = 1;
		    dut->test->BTN2 = 1;
		    break;
		default:
		    dut->test->io0->uart_rx0->rx_ready = 0;
		    dut->test->io0->uart_rx0->rx_data = 0;
		    dut->test->BTN2 = 0;
	    }
	}

	m_trace->dump(sim_time);
	sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
