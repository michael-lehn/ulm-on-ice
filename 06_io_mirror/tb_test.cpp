#include "Vtest.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <verilated.h>
#include <verilated_vcd_c.h>

constexpr std::uint64_t BIT = 1250;     // clock cycles per bit: 12 MHz / 9600
constexpr std::uint64_t T0 = 1000;      // the frame on RX starts here
constexpr std::uint8_t DATA = 'A';      // the byte sent on RX

// Level of the RX line at clock cycle c: a frame with the byte DATA
// (start bit, 8 data bits LSB first, stop bit) starting at cycle T0.
static int
rx_level(std::uint64_t c)
{
    if (c < T0) {
        return 1;                       // idle
    }
    std::uint64_t k = (c - T0) / BIT;
    if (k == 0) {
        return 0;                       // start bit
    }
    if (k <= 8) {
        return DATA >> (k - 1) & 1;     // data bit k - 1
    }
    return 1;                           // stop bit, then idle
}

int
main(int argc, char **argv, char **env)
{
    Vtest *dut = new Vtest;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    std::uint64_t sim_time = 0;
    int tx = 1;                         // last level of TX
    std::uint64_t tx_start = 0;         // cycle of the start bit on TX
    int echo = -1;                      // byte decoded from TX

    for (std::uint64_t c = 0; c < 30000; ++c) {
        dut->RX = rx_level(c);
        dut->CLK = 1;
        dut->eval();
        m_trace->dump(sim_time++);
        dut->CLK = 0;
        dut->eval();
        m_trace->dump(sim_time++);

        if (dut->TX != tx) {
            tx = dut->TX;
            std::printf("cycle %5llu: TX = %d\n", (unsigned long long)c, tx);
            if (tx == 0 && tx_start == 0) {
                tx_start = c;
                echo = 0;
            }
        }
        // sample the data bits of the echo in the middle of each bit
        if (tx_start && c > tx_start) {
            std::uint64_t t = c - tx_start;
            std::uint64_t k = t / BIT;
            if (t % BIT == BIT / 2 && k >= 1 && k <= 8) {
                echo |= dut->TX << (k - 1);
            }
        }
    }

    std::printf("sent %02x, received %02x: %s\n", DATA, echo,
                echo == DATA ? "PASSED" : "FAILED");

    m_trace->close();
    delete dut;
    exit(echo == DATA ? EXIT_SUCCESS : EXIT_FAILURE);
}
