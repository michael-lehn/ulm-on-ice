#include "Vtest.h"
#include "Vtest_test.h"
#include "Vtest_dev_io.h"
#include "Vtest_uart_rx__B2580.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <verilated.h>
#include <verilated_vcd_c.h>

// Characters for the loader, one every two clock cycles: much faster than
// the UART could deliver them, so that several characters wait in the input
// buffer at the same time.
unsigned char prog[] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b',
    0x04,
};
constexpr std::size_t prog_size = sizeof prog / sizeof prog[0];

// The bytes the loader should store at addresses 0, 1, ...
const std::uint8_t expected[] = { 0x01, 0x23, 0x45, 0x67, 0x89, 0xab };
constexpr std::size_t num_expected = sizeof expected;

// The debugger debounces its buttons: a level counts only after it has been
// stable for 2^17 cycles. So a press lasts HOLD cycles, and so does a pause.
constexpr std::uint64_t HOLD = 140000;

// Only the beginning (loading) is written to waveform.vcd.
constexpr std::uint64_t MAX_TRACE_TIME = 400;

Vtest *dut;
VerilatedVcdC *m_trace;
std::uint64_t sim_time = 0;
std::uint64_t posedge_cnt = 0;
std::size_t numLoaded = 0;

// One clock cycle. Inputs set before the call are seen at the rising edge.
void
tick()
{
    dut->CLK = 1;
    dut->eval();
    ++posedge_cnt;

    // deliver the next character as if the receiver had got it
    dut->test->io0->uart_rx0->rx_ready = 0;
    if (posedge_cnt % 2 == 0 && posedge_cnt > 4 && numLoaded < prog_size) {
        dut->test->io0->uart_rx0->rx_ready = 1;
        dut->test->io0->uart_rx0->rx_data = prog[numLoaded++];
    }

    if (sim_time < MAX_TRACE_TIME) {
        m_trace->dump(sim_time);
    }
    ++sim_time;

    dut->CLK = 0;
    dut->eval();
    if (sim_time < MAX_TRACE_TIME) {
        m_trace->dump(sim_time);
    }
    ++sim_time;
}

// Press and release a button. The press bounces: the contact closes and
// opens a few times before it stays closed, and again when it is released.
void
press(unsigned char &btn)
{
    for (int i = 0; i < 4; ++i) {
        btn = 1;
        for (int k = 0; k < 300; ++k) tick();
        btn = 0;
        for (int k = 0; k < 200; ++k) tick();
    }
    btn = 1;
    for (std::uint64_t k = 0; k < HOLD; ++k) tick();
    for (int i = 0; i < 3; ++i) {
        btn = 0;
        for (int k = 0; k < 200; ++k) tick();
        btn = 1;
        for (int k = 0; k < 300; ++k) tick();
    }
    btn = 0;
    for (std::uint64_t k = 0; k < HOLD; ++k) tick();
}

int
main(int argc, char **argv, char **env)
{
    dut = new Vtest;

    Verilated::traceEverOn(true);
    m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    dut->BTN1 = dut->BTN2 = dut->BTN3 = 0;

    // load
    while (!dut->LED3 && posedge_cnt < 1000) {
        tick();
    }
    if (!dut->LED3) {
        std::printf("loader not done after %llu cycles\n",
                    (unsigned long long)posedge_cnt);
    }
    else {
        std::printf("loader done after %llu cycles\n",
                    (unsigned long long)posedge_cnt);
    }

    // BTN1 fetches address 0, each BTN2 the next address. Read the address
    // (BTN3 released) and the byte (BTN3 pressed) from the debugger.
    int errors = !dut->LED3;
    for (std::size_t i = 0; i < num_expected; ++i) {
        press(i == 0 ? dut->BTN1 : dut->BTN2);
        unsigned addr = dut->test->debugger_out & 0xff;
        dut->BTN3 = 1;
        tick();
        unsigned val = dut->test->debugger_out & 0xff;
        dut->BTN3 = 0;
        tick();
        bool ok = addr == i && val == expected[i];
        std::printf("%s: address %02x, byte %02x (expected %02zx, %02x)\n",
                    i == 0 ? "BTN1" : "BTN2", addr, val, i, expected[i]);
        errors += !ok;
    }
    std::printf("%s\n", errors ? "FAILED" : "PASSED");

    m_trace->close();
    delete dut;
    exit(errors ? EXIT_FAILURE : EXIT_SUCCESS);
}
