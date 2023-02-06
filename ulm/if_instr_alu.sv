`include "pkg_alu.sv"
`include "pkg_reg.sv"

//
//  %s <- %b op %a  if a_sel == ALU_REG
//  %s <- %b op a   if a_sel == ALU_IMM
//

interface if_instr_alu;
    pkg_alu::op_t op;
    /* verilator lint_off UNUSEDSIGNAL */
    pkg_alu::sel_t a_sel;
    logic [pkg_reg::REG_ADDRW-1:0] s_reg;
    logic [pkg_reg::REG_ADDRW-1:0] b_reg;
    logic [pkg_reg::REG_WIDTH-1:0] a_imm;
    logic [pkg_reg::REG_ADDRW-1:0] a_reg;
    /* verilator lint_on UNUSEDSIGNAL */
endinterface
