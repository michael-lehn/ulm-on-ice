## Purpose

Some simple ALU (Arithmetic Logic Unit). It has four registers (denoted %0, %1,
%2, %3). Each register has a size of 8 bits. Instructions for the ALU also have
8 bits.

Just four operations are supported:

- Set the low nibble of a regsiter and zero initialize the high nibble.
- Set the high nibble of a register and leave the low nibble unchanged.
- Add a register to a register and store the result in a register.
- Subtract a register from a register and store the result in a register.

### Demo on FPGA (Link to YouTube)

[<img src="https://github.com/michael-lehn/icebreaker-examples/blob/main/05_mini_alu/demo.png" width="200">](https://youtu.be/ZdcFZW_OYYg)
