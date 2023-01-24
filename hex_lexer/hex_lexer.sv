module hex_lexer #(
    localparam BYTE_SIZE = 8,
    localparam NIBBLE_SIZE = 4
) (
    input logic clk,
    input logic rst,
    input logic push_back,
    input logic pop_front,
    input logic [BYTE_SIZE-1:0] data_in,    // hex digit or ignored
    output logic [BYTE_SIZE-1:0] data_out,  // value of a byte
    output logic empty,
    output logic full,
    output logic error
);

    //
    // Two hex digits are converted to one byte value and then push to the
    // back of a FIFO
    //
    logic fifo_push_back;
    logic fifo_pop_front;
    logic [BYTE_SIZE-1:0] fifo_data_in;
    logic [BYTE_SIZE-1:0] fifo_data_out;
    logic fifo_empty;
    logic fifo_full;
    logic fifo_error;

    assign error = fifo_error;
    assign data_out = fifo_data_out;

    //
    // Already scanned bytes can be pulled from the front of the FIFO
    //
    assign fifo_pop_front = pop_front;
    assign empty = fifo_empty;
    assign full = fifo_full;

    //
    // From two hex digit a byte value is assemble. This byte can the be
    // pushed to the back of the FIFO
    //
    logic [BYTE_SIZE-1:0] val;
    assign fifo_data_in = val;

    //
    // During assembly we are either in the state where we next set the
    // high nibble (high half byte) or low nibble (low half byte)
    //
    typedef enum { HIGH_NIBBLE, LOW_NIBBLE } val_state_t;
    val_state_t val_state = HIGH_NIBBLE;

    //
    // Check whether data_in is a hex digit (data_in_is_hex) and the
    // numerical value of the digit (data_in_val)
    //
    logic data_in_is_hex;
    logic [NIBBLE_SIZE-1:0] data_in_val;

    always_ff @ (posedge clk) begin
	fifo_push_back <= 0;
	if (rst) begin
	    val_state <= HIGH_NIBBLE;
	end
	else begin
	    if (push_back && data_in_is_hex) begin
		// we got a new hex digit and can set a nibble and change state
		case (val_state)
		    HIGH_NIBBLE:
			begin
			    val_state <= LOW_NIBBLE;
			    val[BYTE_SIZE-1:NIBBLE_SIZE] <= data_in_val;
			end
		    LOW_NIBBLE:
			begin
			    val_state <= HIGH_NIBBLE;
			    val[NIBBLE_SIZE-1:0] <= data_in_val;
			    fifo_push_back <= 1;
			end
		endcase
	    end
	end
    end

    //
    // Convert hex digit to numerical value
    //
    always_comb begin
        case (data_in)
	   ASCII_0: begin data_in_is_hex = 1; data_in_val = 4'd0; end
    	   ASCII_1: begin data_in_is_hex = 1; data_in_val = 4'd1; end
    	   ASCII_2: begin data_in_is_hex = 1; data_in_val = 4'd2; end
    	   ASCII_3: begin data_in_is_hex = 1; data_in_val = 4'd3; end
    	   ASCII_4: begin data_in_is_hex = 1; data_in_val = 4'd4; end
    	   ASCII_5: begin data_in_is_hex = 1; data_in_val = 4'd5; end
    	   ASCII_6: begin data_in_is_hex = 1; data_in_val = 4'd6; end
    	   ASCII_7: begin data_in_is_hex = 1; data_in_val = 4'd7; end
    	   ASCII_8: begin data_in_is_hex = 1; data_in_val = 4'd8; end
    	   ASCII_9: begin data_in_is_hex = 1; data_in_val = 4'd9; end

    	   ASCII_A: begin data_in_is_hex = 1; data_in_val = 4'd10; end
    	   ASCII_B: begin data_in_is_hex = 1; data_in_val = 4'd11; end
    	   ASCII_C: begin data_in_is_hex = 1; data_in_val = 4'd12; end
    	   ASCII_D: begin data_in_is_hex = 1; data_in_val = 4'd13; end
    	   ASCII_E: begin data_in_is_hex = 1; data_in_val = 4'd14; end
    	   ASCII_F: begin data_in_is_hex = 1; data_in_val = 4'd15; end

    	   ASCII_a: begin data_in_is_hex = 1; data_in_val = 4'd10; end
    	   ASCII_b: begin data_in_is_hex = 1; data_in_val = 4'd11; end
    	   ASCII_c: begin data_in_is_hex = 1; data_in_val = 4'd12; end
    	   ASCII_d: begin data_in_is_hex = 1; data_in_val = 4'd13; end
    	   ASCII_e: begin data_in_is_hex = 1; data_in_val = 4'd14; end
    	   ASCII_f: begin data_in_is_hex = 1; data_in_val = 4'd15; end

	   default: begin data_in_is_hex = 0; data_in_val = 4'dx; end
        endcase
    end


    //
    // relevant ASCII constants
    //
    localparam ASCII_0 = 8'h30;
    localparam ASCII_1 = 8'h31;
    localparam ASCII_2 = 8'h32;
    localparam ASCII_3 = 8'h33;
    localparam ASCII_4 = 8'h34;
    localparam ASCII_5 = 8'h35;
    localparam ASCII_6 = 8'h36;
    localparam ASCII_7 = 8'h37;
    localparam ASCII_8 = 8'h38;
    localparam ASCII_9 = 8'h39;

    localparam ASCII_A = 8'h41;
    localparam ASCII_B = 8'h42;
    localparam ASCII_C = 8'h43;
    localparam ASCII_D = 8'h44;
    localparam ASCII_E = 8'h45;
    localparam ASCII_F = 8'h46;

    localparam ASCII_a = 8'h61;
    localparam ASCII_b = 8'h62;
    localparam ASCII_c = 8'h63;
    localparam ASCII_d = 8'h64;
    localparam ASCII_e = 8'h65;
    localparam ASCII_f = 8'h66;

    fifo fifo1(
	.clk(clk),
	.rst(rst),
	.push_back(fifo_push_back),
	.pop_front(fifo_pop_front),
	.data_in(fifo_data_in),
	.data_out(fifo_data_out),
	.empty(fifo_empty),
	.full(fifo_full),
	.error(fifo_error)
    );

endmodule





