module test (
    input logic CLK,
    input logic RX,
    output logic TX,
    output logic LED1,
    output logic LED2
);

    integer posedgeCount = 0;

    always_ff @ (posedge CLK) begin
	posedgeCount <= posedgeCount + 1;
    end

    // BRAM is ready if init is true
    `ifdef SYNTHESIS
    logic init = 0;
    always_ff @ (posedge CLK) begin
	if (posedgeCount == 60) begin
	    init <= 1;
	end
    end
    `else
    logic init = 1;
    `endif

    //
    // indicate empty and full states of rx_pipe
    //
    assign LED1 = rx_full;
    assign LED2 = rx_empty;

    //
    // reset fifo
    //

    logic rst = 0;

    //
    // read from rx_fifo
    //

    logic rx_full;
    logic rx_empty;
    logic rx_pop_front = 0;
    logic [7:0] rx_data_out;

    always_ff @ (posedge CLK) begin
	if (init) begin
	    rx_pop_front <= !rx_pop_front && !rx_empty;
	end
    end

    `ifndef SYNTHESIS
    always_ff @ (posedge CLK) begin
	if (rx_full)
	begin
	    $error("warning: input buffer full");
	end
    end
    `endif // SYNTHESIS

    //
    // write to tx_fifo
    //

    logic tx_full;
    logic tx_push_back = 0;
    logic [7:0] tx_data_in;

    always_ff @ (posedge CLK) begin
	if (init) begin
	    tx_push_back <= rx_pop_front && !tx_push_back && !tx_full;
	end
    end

    //
    // connect rx_pipe with tx_pipe
    //
    assign tx_data_in = rx_data_out;

    //
    // error handling / debugging
    //

    logic rx_error;
    logic tx_error;
    logic error;
    assign error = rx_error || tx_error;

    `ifndef SYNTHESIS
    always_ff @ (posedge CLK) begin
	if (error) begin
	    $display("posedgeCount = %d: error", posedgeCount);
	end
    end
    `endif

    tx_pipe #(
	.CLK_FREQ(12_000_000),
	.BAUD(9_600)
    ) tx_pipe1 (
	.clk(CLK),
	.rst(rst),
	.push_back(tx_push_back),
	.data_in(tx_data_in),
	.full(tx_full),
	.tx(TX),
	.error(tx_error)
    );

    rx_pipe #(
	.CLK_FREQ(12_000_000),
	.BAUD(9_600)
    ) rx_pipe1 (
	.clk(CLK),
	.rst(rst),
	.pop_front(rx_pop_front),
	.data_out(rx_data_out),
	.empty(rx_empty),
	.full(rx_full),
	.rx(RX),
	.error(rx_error)
    );




endmodule

