`include "pkg_ram.sv"

module dev_rx_pipe #(
    parameter CLK_FREQ = 12_000_000,
    parameter BAUD = 9_600
) (
    input logic clk,
    input if_dev_rx_pipe rx_pipe,
    input logic rx
);

    //
    // Push back new data from uart_rx1 in FIFO
    //
    logic fifo_push_back;
    logic rx_ready /* verilator public */;
    logic [pkg_ram::RAM_BYTE-1:0] rx_data_out /* verilator public */;
	    
    always_ff @ (posedge clk) begin
	fifo_push_back <= 0;
	if (!rx_pipe.rst) begin
	    if (rx_ready) begin
		fifo_push_back <= !fifo_push_back && !rx_pipe.full;
	    end
	end
    end

    // connect with reading end (front) of FIFO

    fifo fifo0 (
	.clk(clk),
	.rst(rx_pipe.rst),
	.push_back(fifo_push_back),
	.data_in(rx_data_out),
	.pop_front(rx_pipe.pop_front),
	.data_out(rx_pipe.data_out),
	.empty(rx_pipe.empty),
	.full(rx_pipe.full)
    );

    /* verilator lint_off UNUSEDSIGNAL */
    logic rx_idle;
    logic rx_eop;
    /* verilator lint_on UNUSEDSIGNAL */

    uart_rx #(
	CLK_FREQ,
	BAUD
    ) uart_rx0 (
	.clk(clk),
	.rx(rx),
	.rx_ready(rx_ready),
	.rx_data(rx_data_out),
	.rx_idle(rx_idle),
	.rx_eop(rx_eop)
    );

endmodule


