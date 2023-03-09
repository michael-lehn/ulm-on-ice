`include "pkg_ram.sv"

module test (
    input logic CLK,
    output logic A0,
    output logic A1,
    output logic A2,
    output logic A3,
    output logic A4,
    output logic A5,
    output logic A6,
    output logic A7,
    input logic B0,
    input logic B1,
    input logic B2,
    input logic B3,
    input logic B4,
    input logic B5,
    input logic B6,
    input logic B7,
    input logic BTN1,
    input logic BTN2,
    input logic BTN3,
    output logic LED1
);
    logic [7:0] hex_out;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_out;

    logic [7:0] hex_in;
    assign hex_in = {B0, B1, B2, B3, B4, B5, B6, B7};

    logic [7:0] hex_val;

    if_ram if_ram();
    assign hex_val = if_ram.data_out[7:0];
    assign LED1 = if_ram.data_out[pkg_ram::RAM_LONG_SIZE-1:8] == 0;

    initial begin
	if_ram.op = pkg_ram::RAM_NOP;
	if_ram.data_type = pkg_ram::RAM_BYTE;
	if_ram.addr = 0;
	if_ram.data_in = 0;
    end

    always_ff @ (posedge CLK) begin
	if_ram.op <= pkg_ram::RAM_NOP;
	case ({BTN3, BTN2, BTN1})
	    3'b001:
		if_ram.addr <= {{pkg_ram::RAM_ADDRW - 8{1'b0}}, hex_in};
	    3'b101:
		if_ram.data_in <= {{pkg_ram::RAM_LONG_SIZE - 8{1'b0}}, hex_in};
	    3'b010:
		if_ram.op <= pkg_ram::RAM_STORE;
	    3'b110:
		if_ram.op <= pkg_ram::RAM_FETCH;
	    default:
		;
	endcase
    end

    dev_ram ram0(
	.clk(CLK),
	.ram(if_ram.dev)
    );

    dev_hex dev_hex0 (
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_out)
    );

endmodule
