## Purpose

The Mini-ALU (Arithmetic Logic Unit) of the HPC0 course (worksheets 4 and 6).
It has four registers (denoted %0, %1, %2, %3) of 8 bits each and four status
flags. Instructions also have 8 bits:

    Op | X | Y | Z        (2 bits each, XY = the 4 bits of X and Y)

Four operations are supported (u(.) is the unsigned value of a bit pattern):

- Op = 00: u(XY) -> %Z, load a 4-bit value (zero extended).
- Op = 01: (u(XY)·2^4 + u(%Z)) mod 2^8 -> %Z, add a 4-bit value to the high
  nibble.
- Op = 10: (u(%X) + u(%Y)) mod 2^8 -> %Z, addition.
- Op = 11: (u(%X) - u(%Y)) mod 2^8 -> %Z, subtraction.

%0 is a zero register: it always reads 0, and writing to it has no effect.

Every instruction updates the status flags from the result of the adder,
also if the destination is %0:

- ZF (zero flag): the result is 0.
- CF (carry flag): unsigned overflow for an addition, borrow for a
  subtraction (the carry-out of the adder, inverted for a subtraction).
- SF (sign flag): bit 7 of the result.
- OF (overflow flag): signed overflow, the result does not fit into 8 bits
  as a two's-complement number.

### Usage

- DIP switch: the instruction, switch 1 (B0) is the most significant bit.
- BTN1: executes the instruction once per press. The button is synchronised
  and debounced (it has to be stable for 2^17 cycles, about 11 ms, of the
  12 MHz clock).
- BTN2, BTN3: select the register shown on the display (none: %0, BTN2: %1,
  BTN3: %2, both: %3).
- LED1: ZF, LED2: CF, LED3: SF, LED4: OF (LED5 is not used).

Example from worksheet 4: `00001101` (3 -> %1), `00001010` (2 -> %2),
`10011011` (%1 + %2 -> %3, gives 05), `11011011` (%1 - %2 -> %3, gives 01).
`make sim` executes these and more instructions and checks registers and
flags.

### Demo (Link to YouTube)

[<img src="https://github.com/michael-lehn/icebreaker-examples/blob/main/05_mini_alu/demo.png" width="200">](https://youtu.be/ZdcFZW_OYYg)

Note: the demo video shows an earlier version of this design, in which BTN1
was the clock of the registers and there were no status flags.
