module test (
    input logic clock,
    output logic Q1,
    output logic Q2
);

    initial begin
	Q1 = 0;
	Q2 = 0;
    end

    always_comb begin
	nextQ1 = ~Q1 | Q2;
	nextQ2 = ~(Q1 & Q2);
    end
    
    always_ff @ (posedge clock) begin
	Q1 <= nextQ1;
	Q2 <= nextQ2;
    end

endmodule


