#include "Vtest.h"
#include "Vtest_test.h"
#include "Vtest_dev_io.h"
#include "Vtest_uart_rx__B2580.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iterator>
#include <string>
#include <verilated.h>
#include <verilated_vcd_c.h>

// A program as the hex digits that the loader expects, the exit code and the
// output it should produce.
struct Program {
    const char *name;
    std::string hex;
    unsigned exit_code;
    std::string output;
};

// Only the first program (examples/01_hello) is written to waveform.vcd.
constexpr std::uint64_t MAX_TRACE_TIME = 8000;

// A program that does not halt after this many cycles has failed.
constexpr std::uint64_t MAX_CYCLES = 20000;

Vtest *dut;
VerilatedVcdC *m_trace;
std::uint64_t sim_time = 0;
std::uint64_t posedge_cnt = 0;

std::string input;          // characters for the loader
std::size_t numLoaded = 0;
std::string output;         // characters sent by the CPU

// One clock cycle. Inputs set before the call are seen at the rising edge.
void
tick()
{
    dut->CLK = 1;
    dut->eval();
    ++posedge_cnt;
    if (sim_time < MAX_TRACE_TIME) {
        m_trace->dump(sim_time);
    }
    ++sim_time;

    // collect what the CPU sends
    if (dut->test->cpu_putc_done) {
        output += char(dut->test->cpu_putc_char);
    }

    // every fourth cycle deliver the next character, as if the UART
    // receiver had got it
    dut->test->io0->uart_rx0->rx_ready = 0;
    if (posedge_cnt % 4 == 0 && numLoaded < input.size()) {
        dut->test->io0->uart_rx0->rx_ready = 1;
        dut->test->io0->uart_rx0->rx_data = input[numLoaded++];
    }

    dut->CLK = 0;
    dut->eval();
    if (sim_time < MAX_TRACE_TIME) {
        m_trace->dump(sim_time);
    }
    ++sim_time;
}

// Reset with BTN1, load the program (hex digits, then Ctrl-D) and run it
// until the CPU halts.
bool
run(const Program &prog)
{
    dut->BTN1 = 1;
    for (int i = 0; i < 4; ++i) {
        tick();
    }
    dut->BTN1 = 0;

    input = prog.hex + '\x04';
    numLoaded = 0;
    output.clear();

    std::uint64_t start = posedge_cnt;
    while (!dut->LED3 && posedge_cnt - start < MAX_CYCLES) {
        tick();
    }
    std::uint64_t loaded = posedge_cnt;
    while (!dut->test->cpu_halted && posedge_cnt - start < MAX_CYCLES) {
        tick();
    }
    std::uint64_t halted = posedge_cnt;

    bool ok = dut->test->cpu_halted
           && dut->test->cpu_exit_code == prog.exit_code
           && output == prog.output;

    std::printf("== %s\n", prog.name);
    std::printf("loaded after %llu cycles",
                (unsigned long long)(loaded - start));
    if (dut->test->cpu_halted) {
        std::printf(", halted %llu cycles later\n",
                    (unsigned long long)(halted - loaded));
        std::printf("exit code 0x%02x", dut->test->cpu_exit_code);
    } else {
        std::printf(", did not halt\n");
    }
    std::printf(" (expected 0x%02x)\n", prog.exit_code);
    std::printf("output (%zu bytes):\n%s\n", output.size(), output.c_str());
    std::printf("%s\n\n", ok ? "PASSED" : "FAILED");
    return ok;
}

int
main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);     // +verilator+rand+reset+2
    dut = new Vtest;

    Verilated::traceEverOn(true);
    m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    std::ifstream file("../examples/01_hello");
    if (!file) {
        std::printf("can not open ../examples/01_hello\n");
        return EXIT_FAILURE;
    }
    std::string hello{std::istreambuf_iterator<char>(file), {}};

    const Program progs[] = {
        { "examples/01_hello", hello, 0x42,
          "hello, world! \U0001F37A \n你好世界\nHallo, Welt\n"
          "Grüße aus Ulm ;-)\n" },
        // loadz 7, %4; addq 1, %4, %5; putc 'A'; halt %4
        { "putc 'A' keeps %4", "10400007125400013141000002400000", 7, "A" },
        // loadz 5, %15; loadz 3, %1;
        // loop: subq 1, %1, %1; jnz loop; halt %15
        { "jnz keeps %15", "10F00005101000031411000103FFFFFF02F00000", 5,
          "" },
        // loadz byte, %1; movsbq (%1), %2; shrq 8, %2, %3;
        // movzbq (%1), %4; addq %4, %3, %3; halt %3; byte: .byte 0xFE
        { "movsbq", "10100018212100001A320008204100001333400002300000FE",
          0xfd, "" },
    };

    int errors = 0;
    for (const Program &prog : progs) {
        errors += !run(prog);
    }
    std::printf("%s\n", errors ? "FAILED" : "ALL PASSED");

    m_trace->close();
    delete dut;
    exit(errors ? EXIT_FAILURE : EXIT_SUCCESS);
}
