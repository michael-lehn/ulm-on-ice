module test (
    input logic CLK,
    input logic RX,
    output logic TX,
    output logic LED1,
    output logic LED2
);
    //
    // For debugging count cycles
    //
    integer posedgeCount = 0;

    always_ff @ (posedge CLK) begin
	posedgeCount <= posedgeCount + 1;
    end

    //
    // BRAM is ready if init is true
    //
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
    // reset everything with rst == 1
    //
    logic rst = 0;

    //
    // we receive characters (hex digits) from rx_fifo
    //
    logic rx_pop_front = 0;
    logic [7:0] rx_data_out;
    logic rx_empty;
    logic rx_full;
    logic rx_error;

    //
    // what we get from rx_fifo goes into hex_lexer
    //
    logic hex_push_back = 0;
    logic hex_pop_front = 0;
    logic [7:0] hex_data_in;
    logic [7:0] hex_data_out;
    logic hex_empty;
    logic hex_full;
    logic hex_error;

    assign hex_data_in = rx_data_out;	// rx_fifo -> hex_lexer

    //
    // what we get from hex_lexer goes into tx_fifo
    //
    logic tx_push_back = 0;
    logic [7:0] tx_data_in;
    logic tx_full;
    logic tx_error;

    assign tx_data_in = hex_data_out;	// hex_lexer -> tx_data_in

    always_ff @ (posedge CLK) begin
	if (rst) begin
	    rx_pop_front <= 0;
	    hex_push_back <= 0;
	    hex_pop_front <= 0;
	    tx_push_back <= 0;
	end
	else if (init) begin
	    rx_pop_front <= !rx_pop_front && !rx_empty;
	    hex_push_back <= rx_pop_front && !hex_full;

	    hex_pop_front <= !hex_pop_front && !hex_empty;
	    tx_push_back <= hex_pop_front && !tx_full;
	end
    end

    //
    // error handling / debugging
    //
    logic error;
    assign error = rx_error || hex_error || tx_error;
    assign LED1 = error;

    `ifndef SYNTHESIS
    always_ff @ (posedge CLK) begin
	if (error) begin
	    $display("posedgeCount = %d: error", posedgeCount);
	end
    end
    `endif

    assign LED2 = rx_empty;

    `ifndef SYNTHESIS
    always_ff @ (posedge CLK) begin
	if (rx_full)
	begin
	    $error("warning: input buffer full");
	end
    end
    `endif // SYNTHESIS


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

    hex_lexer hex_lexer1
    (
	.clk(CLK),
	.rst(rst),
	.push_back(hex_push_back),
	.pop_front(hex_pop_front),
	.data_in(hex_data_in),
	.data_out(hex_data_out),
	.empty(hex_empty),
	.full(hex_full),
	.error(hex_error)
    );

endmodule

