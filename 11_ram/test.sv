`include "pkg_ram.sv"

module test (
    input logic CLK,
    input pkg_ram::op_t op,
    input pkg_ram::data_type_t data_type,
    input logic [pkg_ram::RAM_ADDRW-1:0] addr,
    input logic [pkg_ram::RAM_QUAD_SIZE-1:0] data_in,
    output logic [pkg_ram::RAM_QUAD_SIZE-1:0] data_out
);
    if_ram if_ram();

    assign if_ram.op = op;
    assign if_ram.data_type = data_type;
    assign if_ram.addr = addr;
    assign if_ram.data_in = data_in;
    assign data_out = if_ram.data_out;

    dev_ram ram0(
	.clk(CLK),
	.ram(if_ram.server)
    );

endmodule
