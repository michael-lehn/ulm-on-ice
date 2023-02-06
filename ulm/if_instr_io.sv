`include "pkg_io.sv"
`include "pkg_ram.sv"
`include "pkg_reg.sv"

interface if_instr_io;
    pkg_io::op_t op;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [pkg_reg::REG_ADDRW-1:0] char_reg;
    logic [pkg_ram::RAM_BYTE-1:0] char_imm;
    /* verilator lint_on UNUSEDSIGNAL */
endinterface
