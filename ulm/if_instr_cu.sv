`include "pkg_cu.sv"
`include "pkg_reg.sv"

interface if_instr_cu;
    pkg_cu::op_t op;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [7:0] exit_code_imm;
    logic [pkg_reg::REG_ADDRW-1:0] cu_reg0, cu_reg1;
    logic [23:0] jmp_offset;
    /* verilator lint_on UNUSEDSIGNAL */
endinterface
