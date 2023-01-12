# About

The example is supposed to first initialize some bytes int the SPRAM with
characters. After that these bytes are fetched from memory and sent to the
serial port.

- Code for sending data to the serial port is based on [pll uart](https://github.com/icebreaker-fpga/icebreaker-verilog-examples/tree/main/icebreaker/pll_uart)
- Code for using the SPRAM is based on [spram](https://github.com/damdoy/ice40_ultraplus_examples/tree/master/spram)
  and [SPRAM on iCE40 FPGA](https://projectf.io/posts/spram-ice40-fpga/)

## Usage

Build everything with `make` and upload to the iCEBreaker with `make prog`.
Listen to the serial port with `cat /dev/cu.NAME_OF_THE_PORT`. Note that on my
machine the port is `/dev/cu.usbserial-5` but might be different on yours.

The output is supposed to be a sequence of bytes that are fetched from SPRAM.
Unfortunately I am still having a problem here and need some help to fix it
(see below).

## What it should do

In an initialization phase it stores the ASCII value of `A` at address 0, `B`
at address 1, `C` at address 2, `D` at address 3.

After the initialization it prints these characters. First the character stored
at address 0, then the character at address 1, etc. After it has printed `D`
(stored at address 3) it wraps around and continues at address 0.

So the expected output is `ABCDABCDABCDABCDABCDABCDABCDABC...`

## Help needed: What it actually does

So the actual output is `�BCDABCDABCDABCDABCDABCDABCDABC...`. In my
understanding it means that the four bytes are correctly stored in memory. But
fetching the very first byte fails and therefor some trash gets printed.

## How it works

The code realizes a finite state machine. For now just some ASCII code so that
comments in the code make more sense and the overall logic becomes clear:

```
        +-----------------------+
        |                       |
        v                       |
 -> [[Init Set]] -> [Init Inc] -+
                        |
        +---------------+
        |
        v
    [Run Tx Wait] -> [Run Fetch] -> [Run Tx Start] -+
        ^                                           |
        |                                           |
        +-------------------------------------------+
```

States `[[Init Set]]` and `[Init Inc]` are relevant for initializing bytes in
SPRAM:

- In `[[Init Set]]` storing a byte at an address is triggered. At startup the
  address is 0. The bytes stored is 'A' + address. So at address 0 we store
  'A', at address 1 we store 'B', etc.

- In `[Init Inc]` the store operation is completed. Unless the current address
  equals 3 it gets incremented. If the address is 3 the initialization is
  complete and the next state will be `[Run Tx Wait]`.

States `[Run Tx Wait]`, `[Run Fetch]` and `[Run Tx Start]` are used to print
the stored bytes will be printed. This cycle never ends. So the FSM is not
that finite :D

- In `[Run Tx Wait]` we wait until a previous transmission to the serial port
  is complete. We also advance the address from where the next byte gets
  fetched. Advancing the address usually means that it gets incremented but we
  wrap to 0 after 3.
- In `[Run fetch]` we just wait for the fetch operation to complete.
- In `[Run Tx Start]` the fetched byte gets transmitted.


