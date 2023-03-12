module dev_hex (
    input logic clk,
    input logic [7:0] hex_val,
    output logic [7:0] hex_pins
);

    logic digit_sel;
    logic [6:0] seg_pins;

    assign hex_pins = {digit_sel, seg_pins};

   // counter increments at CLK = 12 MHz.
   // display refreshes at 375 KHz.
   logic [29:0]	    counter;
   logic [2:0]	    display_state = counter[2 +: 3];

    always @(posedge clk) begin
	counter <= counter + 1;

	// Switch seg_pins_n off during digit_sel transitions
	// to prevent flicker.  Each digit has 25% duty cycle.
	case (display_state)
	    0, 1:
		seg_pins <= segments;
	    2:
		seg_pins <= ~0;
	    3:
		digit_sel <= 0;
	    4, 5:
		seg_pins <= segments;
	    6:
		seg_pins <= ~0;
	    7:
		digit_sel <= 1;
	endcase
    end

    logic [6:0] segments;
    logic [3:0] digit;

    always_comb begin
	digit = 0;
	case (display_state)
	0, 1:
	    digit = hex_val[3:0];
	4, 5:
	    digit = hex_val [7:4];
	endcase
    end

    always_comb begin
	case (digit)
    	4'h0: segments = 7'b1000000;
    	4'h1: segments = 7'b1111001;
    	4'h2: segments = 7'b0100100;
    	4'h3: segments = 7'b0110000;
    	4'h4: segments = 7'b0011001;
    	4'h5: segments = 7'b0010010;
    	4'h6: segments = 7'b0000010;
    	4'h7: segments = 7'b1111000;
    	4'h8: segments = 7'b0000000;
    	4'h9: segments = 7'b0010000;
    	4'hA: segments = 7'b0001000;
    	4'hB: segments = 7'b0000011;
    	4'hC: segments = 7'b1000110;
    	4'hD: segments = 7'b0100001;
    	4'hE: segments = 7'b0000110;
    	4'hF: segments = 7'b0001110;
    	endcase
    end

endmodule

