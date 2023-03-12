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
    input logic BTN3
);

    logic [7:0] hex_pins;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_pins;

    logic [7:0] instr;
    assign instr = {B0, B1, B2, B3, B4, B5, B6, B7};

    logic [1:0] op, x, y, z;
    assign {op, x, y, z} = instr;

    logic [7:0] register[4];

    always_ff @ (posedge BTN1) begin
	case (op)
	    2'b00: register[z] <= { 4'h0, x, y};
	    2'b01: register[z] <= { x, y, register[z][3:0]};
	    2'b10: register[z] <= register[y] + register[x];
	    2'b11: register[z] <= register[y] - register[x];
	    default:
		;
	endcase
    end

    logic [7:0] hex_val;

    always_comb begin
	hex_val = register[{BTN3, BTN2}];
    end

    dev_hex dev_hex0 (
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

endmodule
