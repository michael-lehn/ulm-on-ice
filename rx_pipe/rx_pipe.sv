module rx_pipe #(
    parameter CLK_FREQ = 12_000_000,
    parameter BAUD = 9_600,
    localparam WIDTH = 8
) (
    input logic clk,
    input logic rx,
    input logic rst,
    input logic pop_front,
    output logic [WIDTH-1:0] data_out,
    output logic empty,
    output logic full,
    output logic error
);

    //
    // Push back new data from uart_rx1 in FIFO
    //
    logic fifo_push_back;
    logic rx_ready /* verilator public */;
    logic [WIDTH-1:0] rx_data_out /* verilator public */;
	    
    always_ff @ (posedge clk) begin
	fifo_push_back <= 0;
	if (!rst) begin
	    if (rx_ready) begin
		fifo_push_back <= !fifo_push_back && !full;
	    end
	end
    end

    logic [WIDTH-1:0] fifo_data_in;
    logic [WIDTH-1:0] fifo_data_out;

    // what comes from uart_rx (rx_data_out) goes into FIFO (fifo_data_in)
    assign fifo_data_in = rx_data_out;
    // data_out of module is what comes from FIFO (fifo_data_out)
    assign data_out = fifo_data_out;

    // connect with reading end (front) of FIFO
    logic fifo_pop_front;
    assign fifo_pop_front = pop_front;

    logic fifo_empty;
    assign empty = fifo_empty;

    // indicate that buffer is full, indicate any FIFO error
    logic fifo_full;
    assign full = fifo_full;

    logic fifo_error;
    assign error = fifo_error;

    fifo fifo1(
	.clk(clk),
	.rst(rst),
	.pop_front(fifo_pop_front),
	.push_back(fifo_push_back),
	.data_in(fifo_data_in),
	.data_out(fifo_data_out),
	.empty(fifo_empty),
	.full(fifo_full),
	.error(fifo_error) 
    );

    /* verilator lint_off UNUSEDSIGNAL */
    logic rx_idle;
    logic rx_eop;
    /* verilator lint_on UNUSEDSIGNAL */

    uart_rx #(
	CLK_FREQ,
	BAUD
    ) uart_rx1 (
	.clk(clk),
	.rx(rx),
	.rx_ready(rx_ready),
	.rx_data(rx_data_out),
	.rx_idle(rx_idle),
	.rx_eop(rx_eop)
    );

    `ifndef SYNTHESIS
    always_ff @ (posedge clk) begin
	if (error)
	begin
	    $error("unhandled/unexpected 'error' in rx_fifo");
	end
    end
    `endif // SYNTHESIS

endmodule


