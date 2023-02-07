`include "pkg_ram.sv"

module dev_tx_pipe #(
    parameter CLK_FREQ = 12_000_000,
    parameter BAUD = 9_600
) (
    input logic clk,
    input if_dev_tx_pipe tx_pipe,
    output logic tx
);
    // Check if a character can be popped from fifo
    logic empty;
    logic pop_front;
    logic tx_ready;

    always_ff @ (posedge clk) begin
	pop_front <= 0;
	if (!tx_pipe.rst) begin
	    if (tx_ready) begin
		pop_front <= !empty && !pop_front;
	    end
	end
    end

    // Send a popped character to tx
    logic [pkg_ram::RAM_BYTE-1:0] data_out;
    logic [pkg_ram::RAM_BYTE-1:0] tx_data_in;
    logic tx_busy;
    logic tx_start;
    assign tx_ready = !tx_start && !tx_busy;

    always_ff @ (posedge clk) begin
	tx_start <= 0;
	if (!tx_pipe.rst) begin
	    if (pop_front) begin
		// print character
		tx_data_in <= data_out;
		tx_start <= 1;
	    end
	end
    end

    fifo fifo0 (
	.clk(clk),
	.rst(tx_pipe.rst),
	.pop_front(pop_front),
	.push_back(tx_pipe.push_back),
	.data_in(tx_pipe.data_in),
	.data_out(data_out),
	.empty(empty),
	.full(tx_pipe.full)
    );

    uart_tx #(
	CLK_FREQ,
	BAUD
    ) uart_tx0 (
	.clk(clk),
	.tx_start(tx_start),
	.tx_data(tx_data_in),
	.tx(tx),
	.tx_busy(tx_busy)
    );


endmodule
