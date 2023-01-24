## About

Prints back what you send over the serial port to the icebreaker. So basically
a simple mirroring. But done with two FIFOs.

Read characters from serial port into a FIFO (`rx_pipe`). From this FIFO the
front element is popped and pushed to the back of another FIFO (`tx_pipe`). The
latter FIFO is connected with the serial port and transmits elements from the
back.

## Usage

`make` runs simulation (verilator)
`make waves` runs simulation (verilator) and shows signals in gtkwave
`make yosys` synthesises 
`make prog` synthesises and uploads
