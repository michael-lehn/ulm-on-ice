/*
 * FIFO
 *
 * push_back == 1 --> data_in is stored in *next* cycle and an element
 *		      appended to the back in the *next* cycle
 * pop_front == 1 --> data_out is valid in *this* cycle and front element
 *		      removed in *this* cycle
 * 
 * Side effect: If FIFO is not empty data_out is always valid and contains the
 *		front element.
 *
 * Requirements:
 * (1) "push_back <= 1" is illegal if full == 1  *or* push_back == 1
 * (2) "pop_front <= 1" is illegal if empty == 1 *or* pop_front == 1
 * 
 * About (1): data_in has to stay valid until next cycle
 * About (2): pop_front removes an element in the current cycle. But it
 *	      takes an extra cycle until data_out is updated with the
 *	      new front element.
 */


module fifo #(
    localparam SIZE = 4096,		// size of one EBR (Embedded Block RAM)
    localparam WIDTH = 8,		// each entry is one byte
    parameter DEPTH = SIZE / WIDTH,	// number of addressable bytes ...
    localparam ADDRW = $clog2(DEPTH)	// Number of bits in an address
) (
    input logic clk,
    input logic rst,
    inout if_fifo fifo
);
    // read/write pointers
    logic [ADDRW:0] read_ptr = 0;
    logic [ADDRW:0] write_ptr = 0;

    always_ff @ (posedge clk) begin
	if (rst) begin
	    read_ptr <= 0;
	    write_ptr <= 0;
	end else begin
	    case ({fifo.push_back, fifo.pop_front})
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

    always_comb begin
	fifo.full = read_ptr[ADDRW] !=  write_ptr[ADDRW]
		 && read_ptr[ADDRW-1:0] == write_ptr[ADDRW-1:0];
	fifo.empty = read_ptr == write_ptr;
    end

    dp_bram4096 #(WIDTH) ram_inst(
	.clk_in(clk),
	.en_in(fifo.push_back),
	.addr_in(write_ptr[ADDRW-1:0]),
	.data_in(fifo.data_in),
	.addr_out(read_ptr[ADDRW-1:0]),
	.data_out(fifo.data_out)
    );

endmodule
