module test (
    input   CLK,
    output  A0,
    output  A1,
    output  A2,
    output  A3,
    output  A4,
    output  A5,
    output  A6,
    output  A7
);

    logic [7:0] hex_pins;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_pins;

    logic [7:0] hex_val = 8'hF3;

    dev_hex dev_hex0 (
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

endmodule
