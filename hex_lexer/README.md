## About

Read a sequence of hex digits (other characters) are ignored. Two hex digits
are parsed as a byte value and this value gets printed.

In simple words: You type in `4142` and will see `AB` because the ASCII value
of `A` is `0x41` and the ASCII value of `B` is `0x42`.

## Usage

`make` runs simulation (verilator)
`make waves` runs simulation (verilator) and shows signals in gtkwave
`make yosys` synthesises 
`make prog` synthesises and uploads
