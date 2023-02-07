`include "pkg_ram.sv"

interface if_dev_tx_pipe;
    logic rst;
    logic full;
    logic push_back;
    logic [pkg_ram::RAM_BYTE-1:0] data_in;
endinterface

