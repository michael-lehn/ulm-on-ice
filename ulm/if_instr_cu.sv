`include "pkg_cu.sv"

interface if_instr_cu;
    pkg_cu::op_t op;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [7:0] exit_code;
    logic [23:0] jmp_offset;
    /* verilator lint_on UNUSEDSIGNAL */
endinterface
