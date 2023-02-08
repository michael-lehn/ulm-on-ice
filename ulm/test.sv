`include "pkg_led.sv"
`include "pkg_ram.sv"

module test (
    input logic CLK,
    input logic RX,
    input BTN1,
    input BTN2,
    output logic TX,
    output logic LED1,
    output logic LED2,
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

    localparam clk_freq = 12_000_000;
    localparam baud = 9_600;

    logic btn1_r = 0;
    logic btn1_released;
    assign btn1_released = !btn1_r && BTN1;

    logic btn2_r = 0;
    logic btn2_released;
    assign btn2_released = !btn2_r && BTN2;

    always @ (posedge CLK) begin
	btn1_r <= BTN1;
	btn2_r <= BTN2;
    end

    //
    // 7-seg display
    //
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

    //
    // pipe for reading characters (rx_pipe) and writing characters (tx_pipe)
    //
    if_dev_tx_pipe tx_pipe();
    if_dev_tx_pipe tx_pipe_loader();
    if_dev_rx_pipe rx_pipe();

    initial begin
	tx_pipe.rst = 0;
	tx_pipe.push_back = 0;

	tx_pipe_loader.rst = 0;
	tx_pipe_loader.push_back = 0;

	rx_pipe.rst = 0;
	rx_pipe.pop_front = 0;
    end

    //
    // Program loader
    //

    if_dev_ram loader_ram();
    logic loader_rst = 0;
    logic loader_byte_valid = 0;
    logic loader_done;
    logic [pkg_ram::RAM_BYTE-1:0] loader_data_in, loader_byte;
    logic loader_push_back;

    dev_loader loader0 (
	.clk(CLK),
	.rst(loader_rst),
	.data_in(loader_data_in),
	.data_en(loader_push_back),
	.byte_val(loader_byte),
	.byte_valid(loader_byte_valid),
	.ram(loader_ram),
	.done(loader_done)
    );

    if_dev_led if_loader_byte_led();
    if_dev_led if_loader_done_led();

    assign LED1 = if_loader_byte_led.pin;
    assign if_loader_byte_led.op = loader_byte_valid
				 ? pkg_led::LED_OFF
				 : pkg_led::LED_ON;

    assign LED4 = if_loader_done_led.pin;
    assign if_loader_done_led.op = loader_done
				 ? pkg_led::LED_ON
				 : pkg_led::LED_BLINK;

    dev_led loader_byte_led (
	.clk(CLK),
	.led(if_loader_byte_led)
    );

    dev_led loader_done_led (
	.clk(CLK),
	.led(if_loader_done_led)
    );

    /*
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

    always_ff @ (posedge CLK) begin
	if (btn1_released) begin
	    dev_ram.addr <= dev_ram.addr + 1;
	end

	if (btn2_released) begin
	    dev_ram.addr <= 0;
	end
    end
    */

    //
    // CPU consistes of control unit and devices
    //

    //-- CU (Control unit) -----------------------------------------------------
    /* verilator lint_off UNUSEDSIGNAL */
    logic putc;
    logic [7:0] putc_char, exit_code;
    /* verilator lint_on UNUSEDSIGNAL */

    if_dev_reg_file dev_reg_file();
    if_dev_ram dev_ram();
    if_dev_alu dev_alu();

    logic cu_en = 0;
    assign displ_byte = loader_done ? exit_code : loader_byte;

    always_ff @ (posedge CLK) begin
	// print what was typed
	rx_pipe.pop_front <= !rx_pipe.pop_front && !rx_pipe.empty;
	if (loader_done) begin
	    tx_pipe.push_back <= rx_pipe.pop_front && !tx_pipe.push_back
			      && !tx_pipe.full;
	    tx_pipe.data_in <= putc_char;
	    tx_pipe.push_back <= putc && !tx_pipe.push_back
			      && !tx_pipe.full;
	end
	else begin
	    loader_push_back <= rx_pipe.pop_front;
	    loader_data_in <= rx_pipe.data_out;
	    tx_pipe_loader.data_in <=  rx_pipe.data_out;
	    tx_pipe_loader.push_back <= rx_pipe.pop_front
				     && !tx_pipe_loader.push_back
				     && !tx_pipe_loader.full;
	end

	    
	cu_en <= loader_done;
    end

    logic halted;
    assign LED2 = halted;

    cu cu0(
	.clk(CLK),
	.en(cu_en),
	.dev_ram(dev_ram),
	.dev_reg_file(dev_reg_file),
	.dev_alu(dev_alu),
	.putc(putc),
	.putc_char(putc_char),
	.halted(halted),
	.exit_code(exit_code)
    );

    //
    // Devices connected to control unit
    //

    //-- Device: Register file -------------------------------------------------

    dev_reg_file dev_reg_file0(
	.clk(CLK),
	.reg_file(dev_reg_file)
    );


    //-- Device: ALU -----------------------------------------------------------

    dev_alu dev_alu0(
	.clk(CLK),
	.alu(dev_alu)
    );

    //-- Device: RAM -----------------------------------------------------------
    //
    // Needs to be shared between loader and control unit.
    //
    if_dev_ram sel_ram();

    always_comb begin
	loader_ram.data_out = sel_ram.data_out;
	dev_ram.data_out = sel_ram.data_out;
	case (loader_done)
	    1'b0:
		begin
		    sel_ram.addr = loader_ram.addr;
		    sel_ram.op = loader_ram.op;
		    sel_ram.size = loader_ram.size;
		    sel_ram.data_in = loader_ram.data_in;
		end
	    1'b1:
		begin
		    sel_ram.addr = dev_ram.addr;
		    sel_ram.op = dev_ram.op;
		    sel_ram.size = dev_ram.size;
		    sel_ram.data_in = dev_ram.data_in;
		end
	    default:
		;
	endcase
    end

    dev_ram dev_ram0(
	.clk(CLK),
	.ram(sel_ram)
    );
 
    //-- input/output devices --------------------------------------------------
    
    if_dev_tx_pipe tx_pipe_sel();

    always_comb begin
	tx_pipe.full = tx_pipe_sel.full;
	tx_pipe_loader.full = tx_pipe_sel.full;

	if (loader_done) begin
	    tx_pipe_sel.rst = tx_pipe.rst;
	    tx_pipe_sel.push_back = tx_pipe.push_back;
	    tx_pipe_sel.data_in = tx_pipe.data_in;
	end
	else begin
	    tx_pipe_sel.rst = tx_pipe_loader.rst;
	    tx_pipe_sel.push_back = tx_pipe_loader.push_back;
	    tx_pipe_sel.data_in = tx_pipe_loader.data_in;
	end
    end

    dev_tx_pipe #(
	.CLK_FREQ(clk_freq),
	.BAUD(baud)
    ) dev_tx_pipe0 (
	.clk(CLK),
	.tx_pipe(tx_pipe_sel),
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
