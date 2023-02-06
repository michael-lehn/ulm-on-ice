`include "pkg_reg.sv"

interface if_dev_reg_file;
    pkg_reg::op_t op;
    logic [pkg_reg::REG_ADDRW-1:0] addr_in;
    logic [pkg_reg::REG_ADDRW-1:0] addr_out0;
    logic [pkg_reg::REG_ADDRW-1:0] addr_out1;

    logic [pkg_reg::REG_WIDTH-1:0] data_in;
    logic [pkg_reg::REG_WIDTH-1:0] data_out0;
    logic [pkg_reg::REG_WIDTH-1:0] data_out1;
endinterface
