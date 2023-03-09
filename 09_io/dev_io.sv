module dev_io (
    input logic clk,
    input logic rst,
    input logic rx,
    output logic tx,
    output logic inbuf_full,
    output logic getc_en,
    input logic getc_pop,
    output logic [7:0] getc_char,
    input logic putc_push,
    output logic putc_push_done,
    input logic [7:0] putc_char
);

    parameter CLK_FREQ = 12_000_000;
    parameter BAUD = 9_600;

    //--------------------------------------------------------------------------
    // FIFOs for buffering input and output
    //--------------------------------------------------------------------------

    if_fifo inbuf(), outbuf();

    fifo input_buffer(
	.clk(clk),
	.rst(rst),
	.fifo(inbuf)
    );

    fifo output_buffer(
	.clk(clk),
	.rst(rst),
	.fifo(outbuf)
    );

    //--------------------------------------------------------------------------
    //	Indicate if input can not be buffered
    //--------------------------------------------------------------------------

    assign inbuf_full = inbuf.full;

    //--------------------------------------------------------------------------
    //	Pop front from input buffer
    //--------------------------------------------------------------------------

    assign getc_en = !inbuf.empty;
    assign inbuf.pop_front = getc_pop;
    assign getc_char = inbuf.data_out;

    //--------------------------------------------------------------------------
    //	Push back to input buffer and output buffer
    //--------------------------------------------------------------------------

    logic rx_ready;
    logic [7:0] rx_data_out;
    /* verilator lint_off UNUSEDSIGNAL */
    logic rx_idle;
    logic rx_eop;
    /* verilator lint_on UNUSEDSIGNAL */

    logic rx_inbuf_push = 0;
    logic rx_outbuf_push = 0;
    logic [7:0] rx_data_buf;


    // buffer received data
    always_ff @ (posedge clk) begin
	if (rx_ready) begin
	    rx_data_buf <= rx_data_out;
	end
    end

    // received data needs to go into the input buffer
    always_ff @ (posedge clk) begin
	if (rst) begin
	    rx_inbuf_push <= 0;
	end
	if (rx_ready) begin
	    rx_inbuf_push <= 1;
	end
	inbuf.push_back <= 0;
	if (!inbuf.full && !inbuf.push_back) begin
	    if (rx_inbuf_push) begin
		inbuf.push_back <= 1;
		inbuf.data_in <= rx_data_buf;
		rx_inbuf_push <= 0;
	    end
	end
    end

    // received data *and* putc data needs to go into the output buffer
    always_ff @ (posedge clk) begin
	if (rst) begin
	    rx_outbuf_push <= 0;
	end
	if (rx_ready) begin
	    rx_outbuf_push <= 1;
	end
	putc_push_done <= 0;
	outbuf.push_back <= 0;
	if (!outbuf.full && !outbuf.push_back) begin
	    if (rx_outbuf_push) begin
		outbuf.push_back <= 1;
		outbuf.data_in <= rx_data_buf;
		rx_outbuf_push <= 0;
	    end
	    else if (putc_push) begin
		outbuf.push_back <= 1;
		outbuf.data_in <= putc_char;
		rx_outbuf_push <= 0;
		putc_push_done <= 1;
	    end
	end
    end

    uart_rx #(
	.clk_freq(CLK_FREQ),
	.baud(BAUD)
    ) uart_rx0 (
	.clk(clk),
	.rx(rx),
	.rx_ready(rx_ready),
	.rx_data(rx_data_out),
	.rx_idle(rx_idle),
	.rx_eop(rx_eop)
    );
 
    //--------------------------------------------------------------------------
    //	Pop front from output buffer
    //--------------------------------------------------------------------------

    logic tx_start;
    logic [7:0] tx_data_in;
    logic tx_busy;

    always_ff @ (posedge clk) begin
	tx_start <= 0;
	outbuf.pop_front <= 0;
	if (!tx_start && !tx_busy) begin
	    if (!outbuf.empty && !outbuf.pop_front) begin
		outbuf.pop_front <= 1;
	    end
	end
	if (outbuf.pop_front) begin
	    tx_start <= 1;
	    tx_data_in <= outbuf.data_out;
	end
    end

    uart_tx #(
	.clk_freq(CLK_FREQ),
	.baud(BAUD)
    ) uart_tx0 (
	.clk(clk),
	.tx_start(tx_start),
	.tx_data(tx_data_in),
	.tx(tx),
	.tx_busy(tx_busy)
    );


endmodule
