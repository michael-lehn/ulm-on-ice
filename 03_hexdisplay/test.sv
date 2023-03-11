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



    // clk freq
    localparam CLK_FREQ = 12_000_000;
    integer posEdgeCount = 0;
    logic tic = 0;

    always_ff @ (posedge CLK) begin
	posEdgeCount <= posEdgeCount + 1;
	tic <= 0;
	if (posEdgeCount == CLK_FREQ) begin
	    posEdgeCount <= 0;
	    tic <= 1;
	end
    end


    logic [7:0] hex_val = 8'h0;

    always_ff @ (posedge CLK) begin
	if (tic) begin
	    hex_val <= hex_val + 1;
	end
    end

    dev_hex dev_hex0 (
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

endmodule
