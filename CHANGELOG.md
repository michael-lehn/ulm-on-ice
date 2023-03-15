### 2023/03/10 Major rewrite and redesign
- I finally got a hex display for the FPGA.
- The hex display was another game changer. Before blinking LEDs and printing
  characters to the serial port was my only way to debug.
- You can not track down every problem with `Verilator`. Passing tests in
  `Verilator` is a necessary but not sufficient condition that it works on the
  actual FPGA.
- When you want to get started with FPGA I definitely recommend the investment
  in a hex display ;-)
- The IO system was the main source of timing issues. Not good if you use it
  for debugging.

### 2023/02/15 It can compute and print n!
- CU instructions (jumps)
- ALU instructions (add/sub)
- Instruction for printing characters
- Can execute a program that computes $n!$. Using add instructions and loops
  for multiplying integers.
- No input instruction though. Value $n$ needs to be hard coded.

### 2023/01/31 First working ULM
- First success with a minimalistic instruction set

### 2023/01/23 Started to use `Verilator`
- Using `Verilator` was another game changer

### 2023/01/16 Switched to `SystemVerilog`
- Discovered `Project F` and learned about `SystemVerilog`
- Using `SystemVerilog` was a game changer

### 2023/01/12 Initial commit
- first steps with `Verilog`.
- experiments on using UART and SPRAM.
- Learned a lot from completely failing.
