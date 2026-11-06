#include "Vtest.h"
#include "Vtest___024root.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <verilated.h>
#include <verilated_vcd_c.h>

// The debouncer accepts a new button value after 2^17 clock cycles.
#define DEBOUNCE 131072

Vtest *dut;
VerilatedVcdC *m_trace;
std::uint64_t sim_time = 0;
std::uint64_t trace_until = 0;  // only short windows go into the VCD file
int num_exec = 0;               // clock cycles in which exec was 1
int num_errors = 0;

// One clock cycle: a rising and a falling edge. The inputs are changed
// between two calls, that is, after a falling edge and half a cycle before
// the next rising edge.
void
tick()
{
    for (int i = 0; i < 2; ++i) {
        dut->CLK ^= 1;
        dut->eval();
        if (sim_time < trace_until) {
            m_trace->dump(sim_time);
        }
        sim_time++;
    }
    if (dut->rootp->test__DOT__exec) {
        num_exec++;
        trace_until = sim_time + 40;
    }
}

void
wait_cycles(int cycles)
{
    for (int i = 0; i < cycles; ++i) {
        tick();
    }
}

// Press or release BTN1, with some bouncing during the first 2 ms.
void
button(int value)
{
    trace_until = sim_time + 40;
    for (int i = 0; i < 4; ++i) {
        dut->BTN1 = value;
        wait_cycles(3000 + 1000 * i);
        dut->BTN1 = !value;
        wait_cycles(500);
    }
    dut->BTN1 = value;
    wait_cycles(DEBOUNCE + 100);
}

// One instruction of the program, with the predicted registers %0 to %3
// (-1: not written yet, not checked) and flags ZF, CF, SF, OF.
struct Step {
    std::uint8_t instr;
    int reg[4];
    const char *flags;
    const char *comment;
};

const Step program[] = {
    {0b00001101, {0x00, 0x03,   -1,   -1}, "0000", "u(0011) -> %1"},
    {0b00001010, {0x00, 0x03, 0x02,   -1}, "0000", "u(0010) -> %2"},
    {0b10011011, {0x00, 0x03, 0x02, 0x05}, "0000", "%1 + %2 -> %3"},
    {0b11011011, {0x00, 0x03, 0x02, 0x01}, "0000", "%1 - %2 -> %3"},
    {0b01000101, {0x00, 0x13, 0x02, 0x01}, "0000", "u(0001)*2^4 + %1 -> %1"},
    {0b11100100, {0x00, 0x13, 0x02, 0x01}, "0110", "%2 - %1 -> %0"},
    {0b01011110, {0x00, 0x13, 0x72, 0x01}, "0000", "u(0111)*2^4 + %2 -> %2"},
    {0b10101011, {0x00, 0x13, 0x72, 0xE4}, "0011", "%2 + %2 -> %3"},
    {0b01111110, {0x00, 0x13, 0x62, 0xE4}, "0100", "u(1111)*2^4 + %2 -> %2"},
    {0b11010111, {0x00, 0x13, 0x62, 0x00}, "1000", "%1 - %1 -> %3"},
    {0b00111100, {0x00, 0x13, 0x62, 0x00}, "0000", "u(1111) -> %0"},
};

// Set the DIP switch to the instruction (B0 is the most significant bit),
// press and release BTN1, then compare registers and flags with the
// prediction.
void
execute(const Step &step)
{
    std::uint8_t instr = step.instr;
    dut->B0 = instr >> 7 & 1;
    dut->B1 = instr >> 6 & 1;
    dut->B2 = instr >> 5 & 1;
    dut->B3 = instr >> 4 & 1;
    dut->B4 = instr >> 3 & 1;
    dut->B5 = instr >> 2 & 1;
    dut->B6 = instr >> 1 & 1;
    dut->B7 = instr >> 0 & 1;
    num_exec = 0;
    button(1);
    button(0);

    bool ok = num_exec == 1;
    for (int i = 7; i >= 0; --i) {
        std::printf("%d", instr >> i & 1);
    }
    std::printf(":");
    for (int i = 0; i < 4; ++i) {
        // BTN3 and BTN2 select the register that dev_hex shows
        dut->BTN2 = i & 1;
        dut->BTN3 = i >> 1 & 1;
        dut->eval();
        int r = dut->rootp->test__DOT__dev_hex0__DOT__hex_val;
        std::printf(" %%%d=%02X", i, r);
        ok = ok && (step.reg[i] < 0 || r == step.reg[i]);
    }
    dut->BTN2 = 0;
    dut->BTN3 = 0;
    dut->eval();
    int flag[4] = {dut->LED1, dut->LED2, dut->LED3, dut->LED4};
    std::printf("  ZF=%d CF=%d SF=%d OF=%d", flag[0], flag[1], flag[2],
                flag[3]);
    for (int i = 0; i < 4; ++i) {
        ok = ok && flag[i] == step.flags[i] - '0';
    }
    std::printf("  %-6s %s\n", ok ? "ok" : "WRONG", step.comment);
    if (!ok) {
        num_errors++;
    }
}

int
main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    dut = new Vtest;

    Verilated::traceEverOn(true);
    m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    dut->BTN1 = 0;
    dut->BTN2 = 0;
    dut->BTN3 = 0;
    trace_until = 40;
    wait_cycles(10);

    for (const Step &step : program) {
        execute(step);
    }
    std::printf("%d errors\n", num_errors);

    m_trace->close();
    delete dut;
    exit(num_errors == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
}
