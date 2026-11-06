#include "Vtest.h"
#include "Vtest_test.h"
#include "Vtest_dev_io.h"
#include "Vtest_uart_rx__B2580.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <verilated.h>
#include <verilated_vcd_c.h>

// The buttons are debounced: a level counts only after it has been stable
// for 2^17 cycles. So a press lasts HOLD cycles, and so does a pause.
constexpr std::uint64_t HOLD = 140000;

// Only the beginning is written to waveform.vcd.
constexpr std::uint64_t MAX_TRACE_TIME = 200;

Vtest *dut;
VerilatedVcdC *m_trace;
std::uint64_t sim_time = 0;
std::uint64_t posedge_cnt = 0;

// Decoder for the frames on TX (start bit, 8 data bits LSB first, stop
// bits): it samples the line in the middle of each bit.
constexpr std::uint64_t BIT = 1250;     // 12 MHz / 9600 baud
unsigned char tx_bytes[16];
std::size_t num_tx = 0;

void
decode_tx()
{
    static bool active = false;
    static std::uint64_t start;
    static unsigned char byte;

    if (!active) {
        if (dut->TX == 0) {             // falling edge: start bit
            active = true;
            start = posedge_cnt;
            byte = 0;
        }
        return;
    }
    std::uint64_t t = posedge_cnt - start;
    if (t % BIT == BIT / 2) {
        std::uint64_t k = t / BIT;      // 0: start bit, 1-8: data, 9: stop
        if (k >= 1 && k <= 8) {
            byte |= dut->TX << (k - 1);
        }
        else if (k == 9) {
            if (num_tx < sizeof tx_bytes) {
                tx_bytes[num_tx++] = byte;
            }
            active = false;
        }
    }
}

// One clock cycle. Inputs set before the call are seen at the rising edge.
// At the 5th, 15th and 25th rising edge the testbench plays the receiver
// and delivers the characters 'Z', '1' and '2'.
void
tick()
{
    dut->CLK = 1;
    dut->eval();
    ++posedge_cnt;

    decode_tx();

    dut->test->io0->uart_rx0->rx_ready = 0;
    switch (posedge_cnt) {
        case 5:
            dut->test->io0->uart_rx0->rx_ready = 1;
            dut->test->io0->uart_rx0->rx_data = 'Z';
            break;
        case 15:
            dut->test->io0->uart_rx0->rx_ready = 1;
            dut->test->io0->uart_rx0->rx_data = '1';
            break;
        case 25:
            dut->test->io0->uart_rx0->rx_ready = 1;
            dut->test->io0->uart_rx0->rx_data = '2';
            break;
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

    int errors = 0;
    dut->BTN1 = dut->BTN2 = 0;
    dut->PMOD_1B = 0x82;    // reversed in test.sv: putc_char = 0x41 = 'A'

    for (int k = 0; k < 100; ++k) tick();
    std::printf("front of input buffer: %02x\n", dut->test->hex_val);
    errors += dut->test->hex_val != 'Z';

    // pop 'Z' with one bouncing press of BTN1
    press(dut->BTN1);
    std::printf("after BTN1:            %02x\n", dut->test->hex_val);
    errors += dut->test->hex_val != '1';

    // push 'A' into the output buffer with one bouncing press of BTN2
    press(dut->BTN2);

    // wait until the 'A' has been sent
    for (std::uint64_t k = 0; k < 15 * BIT; ++k) tick();

    // TX: the echo of 'Z', '1', '2', then the 'A'
    std::printf("TX:");
    for (std::size_t i = 0; i < num_tx; ++i) {
        std::printf(" %02x", tx_bytes[i]);
    }
    std::printf("\n");
    errors += num_tx != 4 || tx_bytes[0] != 'Z' || tx_bytes[1] != '1'
              || tx_bytes[2] != '2' || tx_bytes[3] != 'A';

    std::printf("%s\n", errors ? "FAILED" : "PASSED");

    m_trace->close();
    delete dut;
    exit(errors ? EXIT_FAILURE : EXIT_SUCCESS);
}
