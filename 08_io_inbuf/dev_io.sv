module dev_io (
    input logic clk,
    input logic rst,
    input logic rx,
    output logic tx,
    inout if_iobuf inbuf
);

    parameter CLK_FREQ = 12_000_000;
    parameter BAUD = 9_600;

    logic inbuf_update;

    io_mirror #(
	.CLK_FREQ(CLK_FREQ),
	.BAUD(BAUD)
    ) io_mirror0(
	.clk(clk),
	.recv_data(inbuf.data_in),
	.recv_data_update(inbuf_update),
	.rx(rx),
	.tx(tx)
    );

    //--------------------------------------------------------------------------

    always_ff @ (posedge clk) begin
	inbuf.push_back <= 0;
	if (inbuf_update) begin
	    inbuf.push_back <= !inbuf.push_back && !inbuf.full;
	end
    end
 
    fifo inbuf0(
	.clk(clk),
	.rst(rst),
	.push_back(inbuf.push_back),
	.pop_front(inbuf.pop_front),
	.data_in(inbuf.data_in),
	.data_out(inbuf.data_out),
	.empty(inbuf.empty),
	.full(inbuf.full)
    );

endmodule
