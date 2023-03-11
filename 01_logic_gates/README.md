# Purpose

File `test.sv` is a simple example for using an `always_comb` block. On the
FPGA the logic described here will be realized by connecting LUTs (Lookup
tables).  These LUTs are multiplexers with 4 control bits and one output
(correct me if I am wrong).  Hence they can be used to realize boolean
functions of the form $f: \\{0,1\\}^4 \to \\{0,1\\}$.

### Demo on FPGA (Link to YouTube)

With `make synth` the design gets synthesized, and with `make prog` synthesized
and the FPGA programmed:

[<img src="https://github.com/michael-lehn/icebreaker-examples/blob/main/01_logic_gates/demo.png" width="200">](https://www.youtube.com/watch?v=l5lfcHXWZDA)

### Visualization of the design

You can create visualizations with

- `make png` which creates `test.png` or
- `make svg` which creates `test.svg`

Here for example you can see `test.svg`:

![test](https://github.com/michael-lehn/icebreaker-examples/blob/main/01_logic_gates/test.svg)

As you notice this does not reflect how LUTs will be connected on the FPGA for
realizing the design. It is rather a logical/conceptual description based on
logic gates. The advantage is that the functionality of the design immediately
becomes clear, i.e. if you press button 1 just LED2 will be on, if you press
both buttons both LEDs will be on.

Unfortunately I have not figured out how to visualize the synthesized design,
i.e. the physical realization with LUTs. I think this would allow to develop a
better understanding (some guts feeling) for timing issues in more complex
design.

### Simulation with Verilator

With a plain `make` the `SystemVerilog` code first gets translated to `Verilog`
code (using `sv2v`). In this step syntax errors and eventually some semantic
errors can be detected. If no error was detected this creates `test.v`.

The simulation gets created with `Verilator` from `test.v` and `tb_test.cpp`.
In this step further semantic errors might be detected. If no error was
detected the simulation is executed.

With `make waves` the simulation is executed and results get visualized with
`gtkwaves`.

