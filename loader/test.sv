`include "pkg_ram.sv"
`include "pkg_led.sv"

module test (
    input logic CLK,
    input BTN1,
    input BTN2,
    input logic RX,
    output logic TX,
    output logic LED1,
    output logic LED2,
    output logic LED3,
    output logic LED4,
    output P1A1,
    output P1A2,
    output P1A3,
    output P1A4,
    output P1A7,
    output P1A8,
    output P1A9,
    output P1A10
);

    assign {P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1} = seg_pins;
    assign P1A10 = digit_sel;

    logic [6:0] seg_pins;
    logic       digit_sel;

    logic [7:0] displ_byte;

    dev_hex dev_hex0 (
	.clk(CLK),
	.hex_val(displ_byte),
	.digit_sel(digit_sel),
	.seg_pins(seg_pins)
    );

    if_dev_led if_load_led();
    assign LED4 = if_load_led.pin;
    assign if_load_led.op = loader_done
			  ? pkg_led::LED_ON
			  : pkg_led::LED_BLINK;

    dev_led load_led(
	.clk(CLK),
	.led(if_load_led)
    );

    localparam clk_freq = 12_000_000;
    localparam baud = 9_600;

    //
    // pipe for reading characters (rx_pipe) and writing characters (tx_pipe)
    //

    if_dev_tx_pipe tx_pipe();
    if_dev_rx_pipe rx_pipe();

    initial begin
	tx_pipe.rst = 0;
	tx_pipe.push_back = 0;

	rx_pipe.rst = 0;
	rx_pipe.pop_front = 0;
    end

    //
    // indicate empty and full states of rx_pipe
    //
    assign LED1 = rx_pipe.full;

    //
    // BRAM (used for FIFOs) is ready if init is true
    //
    `ifdef SYNTHESIS
    integer posedgeCount = 0;

    always_ff @ (posedge CLK) begin
	posedgeCount <= posedgeCount + 1;
    end

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
    // read from rx_fifo
    //
    always_ff @ (posedge CLK) begin
	if (init) begin
	    rx_pipe.pop_front <= !rx_pipe.pop_front && !rx_pipe.empty;
	end
    end

    //
    // copy data
    //
    always_ff @ (posedge CLK) begin
	if (init) begin
	    tx_pipe.data_in <= rx_pipe.data_out;
	end
    end

    //
    // write to tx_fifo
    //
    always_ff @ (posedge CLK) begin
	if (init) begin
	    tx_pipe.push_back <=  rx_pipe.pop_front
			      && !tx_pipe.push_back
			      && !tx_pipe.full;
	end
    end

    //
    // let loader know what about the hex digits typed in and store assembled
    // bytes in memory
    //

    if_dev_ram loader_ram();
    logic loader_rst = 0;
    logic loader_byte_valid;
    logic loader_done;

    dev_loader loader0 (
	.clk(CLK),
	.rst(loader_rst),
	.data_in(tx_pipe.data_in),
	.data_en(tx_pipe.push_back),
	.byte_valid(loader_byte_valid),
	.ram(loader_ram),
	.done(loader_done)
    );

    //
    // Debug RAM
    //

    if_dev_ram dev_ram();

    initial begin
	dev_ram.op = pkg_ram::RAM_FETCH;
	dev_ram.size = pkg_ram::RAM_BYTE;
	dev_ram.addr = 0;
	dev_ram.data_in = 0;
	displ_byte = dev_ram.data_out[7:0];
    end

    logic btn1, btn1_r = 0;
    logic btn2, btn2_r = 0;

    assign btn1 = BTN1;
    assign btn2 = BTN2;

    always_ff @ (posedge CLK) begin
	btn1_r <= btn1;	
	btn2_r <= btn2;	

	if (btn1 && !btn1_r) begin
	    dev_ram.addr <= dev_ram.addr + 1;
	end

	if (btn2 && !btn2_r) begin
	    dev_ram.addr <= 0;
	end
    end
    
    //-- Device: RAM -----------------------------------------------------------
    //
    // Needs to be shared between loader and control unit.
    //
    if_dev_ram sel_ram();

    always_comb begin
	if (!loader_done) begin
	    sel_ram.addr = loader_ram.addr;
	    sel_ram.op = loader_ram.op;
	    sel_ram.size = loader_ram.size;
	    sel_ram.data_in = loader_ram.data_in;
	end
	else begin
	    sel_ram.addr = dev_ram.addr;
	    sel_ram.op = dev_ram.op;
	    sel_ram.size = dev_ram.size;
	    sel_ram.data_in = dev_ram.data_in;
	end

	loader_ram.data_out = sel_ram.data_out;
	dev_ram.data_out = sel_ram.data_out;
    end

    dev_ram dev_ram0(
	.clk(CLK),
	.ram(sel_ram)
    );
 
    assign LED3 = loader_byte_valid;
    assign LED2 = loader_done;

    dev_tx_pipe #(
	.CLK_FREQ(clk_freq),
	.BAUD(baud)
    ) dev_tx_pipe0 (
	.clk(CLK),
	.tx_pipe(tx_pipe),
	.tx(TX)
    );

    dev_rx_pipe #(
	.CLK_FREQ(clk_freq),
	.BAUD(baud)
    ) dev_rx_pipe0 (
	.clk(CLK),
	.rx_pipe(rx_pipe),
	.rx(RX)
    );

endmodule
