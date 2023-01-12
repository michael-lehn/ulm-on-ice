# About

The example is supposed to first initialize some bytes int the SPRAM with
characters. After that these bytes are fetched from memory and sent to the
serial port.

- Code for sending data to the serial port is based on [pll uart](https://github.com/icebreaker-fpga/icebreaker-verilog-examples/tree/main/icebreaker/pll_uart)
- Code for using the SPRAM is based on [spram](https://github.com/damdoy/ice40_ultraplus_examples/tree/master/spram)
  and [SPRAM on iCE40 FPGA](https://projectf.io/posts/spram-ice40-fpga/)

## Usage

Build everything with `make` and upload to the iCEBreaker with `make prog`.
Listen to the serial port with `cat /dev/cu.NAME_OF_THE_PORT`. Nota that on my
machine the port is `/dev/cu.usbserial-5` but might be different on yours.

If everything works you will see `ABCDABCD...` i.e. a periodic never ending
sequence with `ABCD`.

## What it does

In an initialization phase it stores the ASCII value of `A` at address 0, `B`
at address 1, `C` at address 2, `D` at address 3.

After the initialization it prints these characters. First the character stored
at address 0, then the character at address 1, etc. After it has printed `D`
(stored at address 3) it wrappes arround and continues at address 0.

## How it works

The code realizes a finite state machine. For now just some ASCII code so that
comments in the code make more sense and the overall logic becomes clear:

```
        +-----------------------+
        |                       |
        v                       |
 -> [[Init Set]] -> [Init Inc] -+
        |
        v
    [Run Fetch] -> [Run Tx Start] -> [Run Tx Wait] -+
        ^                                           |
        |                                           |
        +-------------------------------------------+
```

States `[[Init Set]]` and `[Init Inc]` are relevant for initializing bytes in SPRAM.
After initializing four bytes the states `[Run Fetch]`, `[Run Tx Start]` and
`[Run Tx Wait]` the bytes will be printed. This cycle never ends. So the FSM is not
that finite :D

