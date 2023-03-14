`include "pkg_alu.sv"
`include "pkg_reg.sv"

//
//  %s <- %b op %a  if a_sel == ALU_REG
//  %s <- %b op a   if a_sel == ALU_IMM
//

interface if_instr_alu;
    pkg_alu::op_t op;
    pkg_alu::sel_t a_sel;
    logic [pkg_reg::REG_ADDRW-1:0] s_reg;
    logic [pkg_reg::REG_ADDRW-1:0] b_reg;
    logic [pkg_reg::REG_WIDTH-1:0] a_imm;
    logic [pkg_reg::REG_ADDRW-1:0] a_reg;

    modport server(
	input op,
	input a_sel,
	input s_reg,
	input b_reg,
	input a_imm,
	input a_reg
    );

    modport client(
	output op,
	output a_sel,
	output s_reg,
	output b_reg,
	output a_imm,
	output a_reg
    );

endinterface
