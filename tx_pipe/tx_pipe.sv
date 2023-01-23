module tx_pipe #(
    parameter CLK_FREQ = 12_000_000,
    parameter BAUD = 9_600,
    localparam WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic push_back,
    input logic [WIDTH-1:0] data_in,
    output logic full,
    output logic tx,
    output logic error
);
    // check if a character can be popped from fifo
    logic empty;
    logic pop_front;

    always_ff @ (posedge clk) begin
	pop_front <= 0;
	if (!rst) begin
	    pop_front <= 0;

	    if (tx_done) begin
		pop_front <= !empty && !pop_front;
	    end
	end
    end

    // send popped character to tx
    logic [WIDTH-1:0] data_out;
    logic [WIDTH-1:0] tx_data_in;
    logic tx_busy;
    logic tx_start;

    logic tx_done;
    assign tx_done = !tx_start && !tx_busy;

    always_ff @ (posedge clk) begin
	tx_start <= 0;
	if (!rst) begin
	    if (pop_front) begin
		// print character
		tx_data_in <= data_out;
		tx_start <= 1;
	    end
	end
    end

    fifo fifo1(
	.clk(clk),
	.rst(rst),
	.pop_front(pop_front),
	.push_back(push_back),
	.data_in(data_in),
	.data_out(data_out),
	.empty(empty),
	.full(full),
	.error(error)
    );

    uart_tx #(
	CLK_FREQ,
	BAUD
    ) uart_tx1 (
	.clk(clk),
	.tx_start(tx_start),
	.tx_data(tx_data_in),
	.tx(tx),
	.tx_busy(tx_busy)
    );


endmodule : tx_pipe
