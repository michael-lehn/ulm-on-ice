module test (
    input logic CLK,
    input logic RX,
    output logic TX
);

    logic rx_ready;
    logic [7:0] rx_data_out;
    /* verilator lint_off UNUSEDSIGNAL */
    logic rx_idle;
    logic rx_eop;
    /* verilator lint_on UNUSEDSIGNAL */

    logic tx_start;
    logic [7:0] tx_data_in;
    logic tx_busy;

    typedef enum {
	IO_READY_TO_RECEIVE,
	IO_BUFFERING_DATA,
	IO_INIT_TRANSMISSION,
	IO_STARTED_TRANSMISSION
    } state_t;

    state_t state = IO_READY_TO_RECEIVE, next_state;

    //
    // how states are connected
    //
    always_comb begin
	case (state)
	    IO_READY_TO_RECEIVE:
		next_state = IO_BUFFERING_DATA;
	    IO_BUFFERING_DATA:
		next_state = IO_INIT_TRANSMISSION;
	    IO_INIT_TRANSMISSION:
		next_state = IO_STARTED_TRANSMISSION;
	    IO_STARTED_TRANSMISSION:
		next_state = IO_READY_TO_RECEIVE;
	endcase
    end

    //
    // rules for state transitions
    //
    always_ff @ (posedge CLK) begin
	case (state)
	    IO_READY_TO_RECEIVE:
		if (rx_ready) begin
		    state <= next_state;
		end
	    IO_BUFFERING_DATA:
		if (!tx_busy) begin
		    state <= next_state;
		end
	    IO_INIT_TRANSMISSION:
		state <= next_state;
	    IO_STARTED_TRANSMISSION:
		state <= next_state;
	endcase
    end

    //
    // action in each state
    //
    logic [7:0] data_buf;

    always_ff @ (posedge CLK) begin
	case (state)
	    IO_READY_TO_RECEIVE:
		if (rx_ready) begin
		    data_buf <= rx_data_out;
		end
	    IO_BUFFERING_DATA:
		;
	    IO_INIT_TRANSMISSION:
		begin
		    tx_start <= 1;
		    tx_data_in <= data_buf;
		end
	    IO_STARTED_TRANSMISSION:
		tx_start <= 0;
	endcase
    end

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;

    uart_rx #(
	.clk_freq(CLK_FREQ),
	.baud(BAUD)
    ) uart_rx0 (
	.clk(CLK),
	.rx(RX),
	.rx_ready(rx_ready),
	.rx_data(rx_data_out),
	.rx_idle(rx_idle),
	.rx_eop(rx_eop)
    );

    uart_tx #(
	.clk_freq(CLK_FREQ),
	.baud(BAUD)
    ) uart_tx0 (
	.clk(CLK),
	.tx_start(tx_start),
	.tx_data(tx_data_in),
	.tx(TX),
	.tx_busy(tx_busy)
    );

endmodule
