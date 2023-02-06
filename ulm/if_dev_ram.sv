`include "pkg_ram.sv"

interface if_dev_ram;
    pkg_ram::op_t op;
    pkg_ram::size_t size;
    logic [pkg_ram::RAM_ADDRW-1:0] addr;
    logic [pkg_ram::RAM_QUAD-1:0] data_in;
    logic [pkg_ram::RAM_QUAD-1:0] data_out;
endinterface

