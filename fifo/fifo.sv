/*
 * FIFO
 *
 * push_back == 1 --> data_in is store in *next* cycle
 * pop_front == 1 --> data_out is valid in *this* cycle
 *
 * Requirements:
 * (1) "push_back <= 1" is illegal if full == 1  *or* push_back == 1
 * (2) "pop_front <= 1" is illegal if empty == 1
 * (3) "pop_front <= 1" is dangerous if empty == 1 *or* pop_front == 1
 * 
 * About (1): data_in has to stay valid until next cycle
 * About (3): pop_front removes an element in the current cycle. But the
 *            "empty status" is not updated until the next cycle. This code
 *            would trigger a pop_front on an empty FIFO:
 *
 *            always_ff @ (posedge CLK) begin
 *		  pop_front <= !empty;
 *            end
 *
 *            If in cycle (n) the FIFO has one element then empty == 0.
 *            Then in cycle (n+1) pop_front == 1 and (still) empty == 0.
 *            In cycle (n+2) we then have  empty == 1 and (!) pop_front == 1.
 */


module fifo #(
    localparam SIZE = 4096,		// size of one EBR (Embedded Block RAM)
    localparam WIDTH = 8,		// each entry is one byte
    parameter DEPTH = SIZE / WIDTH,	// number of addressable bytes ...
    localparam ADDRW = $clog2(DEPTH)	// Number of bits in an address
) (
    input logic clk,
    input logic rst,
    input logic pop_front,
    input logic push_back,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic empty,
    output logic full,
    output logic error
);
    // number of stored elements
    localparam MAX_COUNT = DEPTH;
    logic [$bits(DEPTH)-1:0] count = 0;

    // full / empty state
    always_comb begin
	full = count == MAX_COUNT;
	empty = count == 0;
    end

    // update count
    always_ff @ (posedge clk) begin
	if (rst) begin
	    count <= 0;
	end
	else begin
	    if (!pop_front && push_back) begin
	        count <= count + 1;
	    end
	    else if (pop_front && !push_back) begin
	        count <= count - 1;
	    end
	end
    end

    // Reading from an empty FIFO is not allowed. It is also error prone to
    // trigger a pop_front if the fifo was empty in the previous cycle
    logic pop_front_error;
    logic pop_front_warning;
    always_comb begin
	pop_front_error = pop_front && empty;
	pop_front_warning = pop_front && empty_prev;
    end

    always_ff @ (posedge clk) begin
	if (!rst && pop_front_warning) begin
	    $display("Warning: pop_front && empty_prev");
	end
    end

    // keep track of empty state in previous cycle
    logic empty_prev;
    logic empty_r_set = 0;
    logic empty_r;

    always_ff @ (posedge clk) begin
	if (rst) begin
	    empty_r_set <= 0;
	end
	else begin
	    empty_r_set <= 1;
	    empty_r <= empty;
	end
    end

    always_comb begin
	empty_prev = empty_r_set ? empty_r : 1;
    end

    // A push_back requires one cycle to take effect. Hence there needs to
    // be a gap between two push_back operations.
    logic push_back_prev;
    logic push_back_error;
    always_comb begin
	push_back_error = push_back && push_back_prev == push_back;
    end

    logic push_back_r_set = 0; // =1 after first write
    logic push_back_r;

    always_ff @ (posedge clk) begin
	if (rst) begin
	    push_back_r_set <= 0;
	end
	else begin
	    if (push_back) begin
		push_back_r_set <= 1;
	    end
	    push_back_r <= push_back;
	end
    end

    always_comb begin
	push_back_prev = push_back_r_set ? push_back_r : 0;
    end

    // Indicate any kind of error
    assign error = !rst && (prev_error || push_back_error || pop_front_error);
    logic prev_error = 0;

    always_ff @ (posedge clk) begin
	if (rst) begin
	    prev_error <= 0;
	end
	else begin
	    prev_error <= prev_error || error;
	end
    end

    // read/write pointers
    logic [ADDRW-1:0] read_ptr = 0;
    logic [ADDRW-1:0] write_ptr = 0;

    always_ff @ (posedge clk) begin
	if (rst) begin
	    read_ptr <= 0;
	    write_ptr <= 0;
	end else begin
	    case ({push_back, pop_front})
		2'b00: ;
		2'b10: write_ptr <= write_ptr + 1;
		2'b01: read_ptr <= read_ptr + 1;
		2'b11:
		    begin
			write_ptr <= write_ptr + 1;
			read_ptr <= read_ptr + 1;
		    end
	    endcase
	end
    end

    dp_bram4096 #(WIDTH) ram_inst(
	.clk_in(clk),
	.en_in(push_back),
	.addr_in(write_ptr),
	.data_in(data_in),
	.clk_out(clk),
	.addr_out(read_ptr),
	.data_out(data_out)
    );

endmodule
