#include "Vtest.h"
#include "Vtest_test.h"
#include "Vtest_dev_io.h"
#include "Vtest_uart_rx__B2580.h"

#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 4000

unsigned char prog[] = {
    '1', '0', '2', '0', '0', '0', '0', '0', 
    '1', '4', '2', '2', '0', '0', '1', '8', 
    '1', '0', '4', '0', '0', '0', '1', '8', 
    '0', '7', '4', '3', '0', '0', '0', '0', 
    '1', '2', '2', '2', '0', '0', '1', '8', 
    '0', '2', '0', '0', '0', '0', '0', '0', 
    '2', '4', '3', '2', '0', '0', '0', '0', 
    '2', '4', '1', '2', '0', '0', '0', '8', 
    '1', '1', '1', '0', '2', '0', '0', '0', 
    '1', '4', '2', '2', '0', '0', '1', '8', 
    '1', '0', '4', '0', '0', '0', '4', '4', 
    '0', '7', '4', '3', '0', '0', '0', '0', 
    '1', '2', '2', '2', '0', '0', '1', '8', 
    '1', '1', '2', '0', '1', '0', '0', '0', 
    '2', '3', '1', '2', '0', '0', '0', '8', 
    '2', '3', '3', '2', '0', '0', '0', '0', 
    '0', '7', '3', '0', '0', '0', '0', '0', 
    '2', '4', '3', '2', '0', '0', '0', '0', 
    '2', '4', '1', '2', '0', '0', '0', '8', 
    '1', '1', '1', '0', '2', '0', '0', '0', 
    '3', '1', '6', '2', '0', '0', '0', '0', 
    '3', '1', '6', '1', '0', '0', '0', '0', 
    '1', '1', '2', '0', '1', '0', '0', '0', 
    '2', '3', '1', '2', '0', '0', '0', '8', 
    '2', '3', '3', '2', '0', '0', '0', '0', 
    '0', '7', '3', '0', '0', '0', '0', '0', 
    0x04,
};

constexpr std::size_t prog_size = sizeof prog / sizeof prog[0];
std::uint64_t numLoaded;

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
    std::uint64_t size = 2;

    std::size_t numBytes = 3;

    std::size_t numCh = 0;

    while (sim_time < MAX_SIM_TIME) {
	dut->CLK ^= 1;
	dut->eval();

	if (dut->CLK == 1) {
	    ++posedge_cnt;
	}

	dut->test->io0->rx_ready = 0;
	if (dut->CLK == 1) {
	    if (posedge_cnt % 4 == 0) {
		if (numLoaded < prog_size) {
		    dut->test->io0->uart_rx0->rx_ready = 1;
		    dut->test->io0->uart_rx0->rx_data = prog[numLoaded++];
		}
	    }
	}

	m_trace->dump(sim_time);
	sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
