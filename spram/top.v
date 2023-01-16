module top(
    input CLK,
    output TX
    );

// Indicated whether we are initializing the memory (init_done == 0) or
// printing the memory content (init_done == 1)
reg init_done = 1'b0;
reg [14:0] init_mem_addr = 0;

// States when memory content gets printed
localparam
    RUN_TX_WAIT = 2'b00,
    RUN_FETCH   = 2'b01,
    RUN_TX_START  = 2'b10;
reg [1:0] run_state = RUN_TX_WAIT;

// mem_addr addresses single bytes in SPRAM. If mem_write == 1 the byte in
// mem_data_in will be stored in the next cycle. If mem_write == 0 the byte
// from address mem_addr will be fetched to mem_data_out in the next cycle.
reg [14:0] mem_addr = 0;
reg mem_write = 1'b0;
reg [7:0] mem_data_in;
wire [7:0] mem_data_out;

mem mem_inst(
    .clk(CLK),
    .addr(mem_addr),
    .write(mem_write),
    .data_in(mem_data_in),
    .data_out(mem_data_out)
);

// From the "pll uart" example. When tx_start is 1 the byte in tx_char gets
// transmitted. tx_busy == 1 indicates that we are currently sending.
reg tx_start = 1'b0;
reg tx_busy;
reg [7:0] tx_char = 0;

localparam clk_freq = 12_000_000; // 12MHz
localparam baud = 9600;

uart_tx #(clk_freq, baud) uart_tx_inst(
    .clk(CLK),
    .tx_start(tx_start),
    .tx_data(tx_char),
    .tx(TX),
    .tx_busy(tx_busy)
);

// intensionally ignore bits in val15'[14:8]
function [7:0] trunc_15_to_8(input [14:0] val15);
    trunc_15_to_8 = val15[7:0];
endfunction


always @ (posedge CLK) begin
    if (~init_done) begin
	// Write some bytes to SPRAM
	// - Store 'A', .., 'D' at addresses 0, .., 3 respectively.
	mem_write <= 1'b1;
	mem_data_in[7:0] <= trunc_15_to_8(15'd65 + init_mem_addr);
	// Increment address. If address 3 was initialized we are done.
	mem_addr <= init_mem_addr;
	init_mem_addr <= init_mem_addr + 1;
	if (init_mem_addr[1:0] == 2'b11)
	    init_done <= 1'b1;
    end
    else begin
	// Data already loaded to SPRAM
	case (run_state)
	    RUN_TX_WAIT:
		// Wait until a previous byte transmission is completed.
		// Also advance the address. If the address is 3 wrap to 0.
		begin
		    tx_start <= 1'b0;
		    if (~tx_busy) begin
			run_state <= RUN_FETCH;
		    end
		    mem_write <= 1'b0;
		    mem_addr <= (mem_addr + 1) % 4;
		end
	    RUN_FETCH:
		// Idle one cycle so that fetching a byte is done
		begin
		    run_state <= RUN_TX_START;
		end
	    RUN_TX_START:
		// Begin to transmit the fetched byte.
		if (~tx_busy) begin
		    tx_char <= mem_data_out;
		    tx_start <= 1'b1;
		    run_state <= RUN_TX_WAIT;
		end 
	endcase
    end
end

endmodule
