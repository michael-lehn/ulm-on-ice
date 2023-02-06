`include "pkg_alu.sv"
`include "pkg_reg.sv"

interface if_dev_alu;
    pkg_alu::op_t op;
    logic [pkg_reg::REG_WIDTH-1:0] a;
    logic [pkg_reg::REG_WIDTH-1:0] b;
    logic [pkg_reg::REG_WIDTH-1:0] s;
    logic stat_reg_zf;
    /* verilator lint_off UNUSEDSIGNAL */
    logic stat_reg_cf;
    logic stat_reg_of;
    logic stat_reg_sf;
    /* verilator lint_on UNUSEDSIGNAL */
endinterface

