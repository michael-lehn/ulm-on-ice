`include "pkg_led.sv"

module dev_led #(
    parameter CLK_FREQ = 12_000_000,
    localparam BLINK = CLK_FREQ / 2,
    localparam FLASH = CLK_FREQ / 24 
) (
    input logic clk,
    if_dev_led led
);

    integer count = 0;
    integer max_count;

    assign max_count = led.op != pkg_led::LED_FLASH
		     ? CLK_FREQ
		     : 2 * FLASH;

    always_ff @ (posedge clk) begin
	if (count < max_count) begin
	    count <= count + 1;
	end
	else begin
	    count <= 0;
	end
    end

    always_comb begin
	led.pin = 0;
	case (led.op)
	    pkg_led::LED_ON:
		led.pin = 1;
	    pkg_led::LED_OFF:
		led.pin = 0;
	    pkg_led::LED_BLINK:
		led.pin = count < BLINK;
	    pkg_led::LED_BLINK_INV:
		led.pin = count >= BLINK;
	    pkg_led::LED_FLASH:
		led.pin = count <  FLASH;
	    default
		;
	endcase
    end

endmodule
