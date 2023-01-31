module init #(
    `ifdef SYNTHESIS
    localparam MIN_CYCLE = 60
    `else
    localparam MIN_CYCLE = 1
    `endif
) (
    input logic clk,
    output logic init
);

    integer initCount = 0;
    
    always_ff @ (posedge clk) begin
	if (initCount < MIN_CYCLE) begin
	    initCount <= initCount + 1;
	end
    end

    always_comb begin
	init = initCount == MIN_CYCLE;
    end

endmodule
