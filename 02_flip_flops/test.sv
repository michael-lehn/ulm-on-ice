module test (
    input logic BTN1,
    input logic BTN2,
    output logic LED1
);
    
    always_ff @ (posedge BTN1) begin
	LED1 <= BTN2;
    end

endmodule
