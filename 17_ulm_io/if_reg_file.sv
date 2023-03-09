`include "pkg_reg.sv"

interface if_reg_file;
    pkg_reg::op_t op;
    logic [pkg_reg::REG_ADDRW-1:0] addr_in;
    logic [pkg_reg::REG_ADDRW-1:0] addr_out0;
    logic [pkg_reg::REG_ADDRW-1:0] addr_out1;

    logic [pkg_reg::REG_WIDTH-1:0] data_in;
    logic [pkg_reg::REG_WIDTH-1:0] data_out0;
    logic [pkg_reg::REG_WIDTH-1:0] data_out1;

    modport server(
	input op,
	input addr_in,
	input addr_out0,
	input addr_out1,
	input data_in,
	output data_out0,
	output data_out1
    );

    modport client(
	output op,
	output addr_in,
	output addr_out0,
	output addr_out1,
	output data_in,
	input data_out0,
	input data_out1
    );

endinterface
