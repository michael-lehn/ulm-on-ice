#include "Vtest.h"
#include "Vtest_test.h"
#include "Vtest_dev_rx_pipe.h"
#include "Vtest_uart_rx__B2580.h"

#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 700 

unsigned char prog[] = {
    '1', '0', '1', '0', '0', '0', '1', '0', '2', '0', '2', '1', '0', '0',
    '0', '0', '3', '0', '2', '0', '0', '0', '0', '0', '0', '1', '0', '4',
    '0', '0', '0', '0', '4', '8', '0', '0', '0', '0', '0', '0',
    0x04,
    
};

constexpr std::size_t prog_size = sizeof prog / sizeof prog[0];

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

    while (sim_time < MAX_SIM_TIME) {
	dut->CLK ^= 1;

	dut->eval();
	if (dut->CLK == 1) {
	    posedge_cnt++;

	    if (numLoaded < prog_size && posedge_cnt % 2) {
		dut->test->dev_rx_pipe0->uart_rx0->rx_ready = 1;
		dut->test->dev_rx_pipe0->uart_rx0->rx_data = prog[numLoaded++];
	    }
	}

	m_trace->dump(sim_time);
	sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
