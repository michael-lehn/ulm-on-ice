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

    // A7 is digit_sel of dev_hex: it must change while the display is
    // multiplexed (twice every 32 clock cycles).
    int digit_sel = -1;
    int digit_switches = 0;

    while (sim_time < MAX_SIM_TIME) {
        dut->CLK ^= 1;

        if (dut->CLK == 1) {
            posedge_cnt++;
        }
        dut->eval();

        if (dut->CLK == 1) {
            if (digit_sel >= 0 && dut->A7 != digit_sel) {
                digit_switches++;
            }
            digit_sel = dut->A7;
        }

        m_trace->dump(sim_time);
        sim_time++;
    }

    std::cout << "changes of digit_sel in " << posedge_cnt
              << " clock cycles: " << digit_switches << std::endl;

    m_trace->close();
    delete dut;
    exit(digit_switches > 0 ? EXIT_SUCCESS : EXIT_FAILURE);
}
