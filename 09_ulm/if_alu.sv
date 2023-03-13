`include "pkg_alu.sv"
`include "pkg_reg.sv"

interface if_alu;
    pkg_alu::op_t op;
    logic [pkg_reg::REG_WIDTH-1:0] a;
    logic [pkg_reg::REG_WIDTH-1:0] b;
    logic [pkg_reg::REG_WIDTH-1:0] s;
    /* verilator lint_off UNUSEDSIGNAL */
    logic zf;
    logic cf;
    logic of;
    logic sf;
    /* verilator lint_on UNUSEDSIGNAL */

    modport server(
	input op,
	input a,
	input b,
	output s,
	output zf,
	output cf,
	output of,
	output sf
    );
    
    modport client(
	output op,
	output a,
	output b,
	input s,
	input zf,
	input cf,
	input of,
	input sf
    );

    modport observer(
	input zf,
	input cf,
	input of,
	input sf
    );
     
endinterface

