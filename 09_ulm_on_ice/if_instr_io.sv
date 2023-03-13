`include "pkg_io.sv"
`include "pkg_reg.sv"

interface if_instr_io;
    pkg_io::op_t op;
    logic [pkg_ram::RAM_BYTE_SIZE-1:0] char_imm;
    logic [pkg_reg::REG_ADDRW-1:0] char_reg;

    // decoder is client
    modport client (
	output op,
	output char_imm,
	output char_reg
    );

    // control unit is server
    modport server (
	input op,
	input char_imm,
	input char_reg
    );

endinterface
