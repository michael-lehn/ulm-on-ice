module test (
    input BTN1,
    input BTN2,
    output logic LED1
);
    
    logic led_state = 0;
    assign LED1 = led_state;

    always_ff @ (posedge BTN1) begin
	led_state <= BTN2;
    end

endmodule
