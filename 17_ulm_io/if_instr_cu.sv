`include "pkg_cu.sv"
`include "pkg_reg.sv"

interface if_instr_cu;
    pkg_cu::op_t op;
    logic [7:0] exit_code_imm;
    logic [pkg_reg::REG_ADDRW-1:0] cu_reg0, cu_reg1;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [23+2:0] jmp_offset;
    /* verilator lint_on UNUSEDSIGNAL */

    // decoder is client
    modport client (
	output op,
	output exit_code_imm,
	output cu_reg0,
	output cu_reg1,
	output jmp_offset
    );

    // control unit is server
    modport server (
	input op,
	input exit_code_imm,
	input cu_reg0,
	input cu_reg1,
	input jmp_offset
    );

endinterface
