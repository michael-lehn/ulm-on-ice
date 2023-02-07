`include "pkg_ram.sv"

interface if_dev_rx_pipe;
    logic rst;
    logic empty;
    logic full;
    logic pop_front;
    logic [pkg_ram::RAM_BYTE-1:0] data_out;
endinterface

