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
    input logic BTN1
);

    logic [7:0] hex_out;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_out;

    logic [7:0] hex_in;
    assign hex_in = {B0, B1, B2, B3, B4, B5, B6, B7};

    logic [7:0] hex_val = 8'h0;

    always_ff @ (posedge CLK) begin
	if (BTN1) begin
	    hex_val <= hex_in;
	end
    end

    dev_hex dev_hex0 (
	.clk(CLK),
	.en(1'b1),
	.hex_val(hex_val),
	.hex_pins(hex_out)
    );

endmodule
