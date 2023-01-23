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

    logic empty;
    logic pop_front;
    logic [WIDTH-1:0] data_out;

    logic tx_busy;
    logic tx_start;
    logic tx_done;
    logic [WIDTH-1:0] tx_data_in;

    always_ff @ (posedge clk) begin
	if (rst) begin
	    pop_front <= 0;
	    tx_start <= 0;
	end
	else begin
	    tx_start <= 0;
	    pop_front <= 0;

	    if (!tx_start && !tx_busy) begin
		pop_front <= !empty && !pop_front;
	    end
	    if (pop_front) begin
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
