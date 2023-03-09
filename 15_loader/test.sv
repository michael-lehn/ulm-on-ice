`include "pkg_ram.sv"

module test (
    input logic CLK,
    input logic RX,
    output logic TX,
    output logic A0,
    output logic A1,
    output logic A2,
    output logic A3,
    output logic A4,
    output logic A5,
    output logic A6,
    output logic A7,
    input logic BTN1,	// reset addr_out
    input logic BTN2,	// fetch byte from addr_out
    input logic BTN3,	// display fetched byte
    output logic LED1,	// inbuf is empty
    output logic LED2,	// inbuf is full
    output logic LED3,	// loader done
    output logic LED4	// high bits in ram.data_out not clean
);
    logic [7:0] hex_out;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_out;

    logic [7:0] hex_val;

    dev_hex dev_hex0 (
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_out)
    );

    // ---------

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;

    logic rst = 0;

    if_io if_io();

    assign LED1 = !if_io.getc_en;	  // inbuf is empty
    assign LED2 = if_io.inbuf_full;	  // inbuf is full

    initial begin
	if_io.getc_pop = 0;
	if_io.putc_push = 0;
	if_io.putc_char = 0;
    end


    dev_io #(
	.CLK_FREQ(CLK_FREQ),
	.BAUD(BAUD)
    ) io0(
	.clk(CLK),
	.rst(rst),
	.rx(RX),
	.tx(TX),
	.io(if_io.server)
    );

    // ---------

    logic btn1_r, btn2_r;

    always_ff @ (posedge CLK) begin
	btn1_r <= BTN1;
	btn2_r <= BTN2;
    end

    // ---------

    if_ram if_ram();

    initial begin
	if_ram.op = pkg_ram::RAM_NOP;
	if_ram.data_type = pkg_ram::RAM_BYTE;
	if_ram.addr = 0;
	if_ram.data_in = 0;
    end

    assign if_ram.data_in[7:0] = if_io.getc_char;

    logic [pkg_ram::RAM_ADDRW-1:0] addr_in = 0, addr_out = 0;
    logic loader_done = 0;
    logic loader_got_eof = 0;
    assign LED3 = loader_done;

    always_ff @ (posedge CLK) begin
	if_ram.op <= pkg_ram::RAM_NOP;
	if_io.getc_pop <= 0;
	if_io.putc_push <= 0;

	if (!loader_done) begin
	    if (if_io.getc_en) begin
		if (loader_got_eof) begin
		    if_io.putc_char <= "\n";
		    if_io.putc_push <= 1;
		    loader_done <= 1;
		end
		else if (if_io.getc_char == 8'h04) begin
		    loader_got_eof <= 1;
		end
		else if (if_ram.op == pkg_ram::RAM_NOP) begin
		    if_ram.op <= pkg_ram::RAM_STORE;
		    if_ram.addr <= addr_in;
		    if_io.getc_pop <= 1;
		    addr_in <= addr_in + 1;
		end
	    end
	end
	else begin
	    if (BTN1 && !btn1_r) begin
		addr_out <= 0;
		if_ram.addr <= 0;
		if_ram.op <= pkg_ram::RAM_FETCH;
	    end
	    else if (BTN2 && !btn2_r) begin
		if (if_ram.op == pkg_ram::RAM_NOP) begin
		    if_ram.op <= pkg_ram::RAM_FETCH;
		    if_ram.addr <= addr_out;
		    addr_out <= addr_out + 1;
		end
	    end
	end
    end

    assign LED4 = if_ram.data_out[pkg_ram::RAM_QUAD_SIZE-1:8] != 0;

    always_comb begin
	if (!loader_done) begin
	    hex_val = !BTN3
		? if_io.getc_char
		: if_ram.addr[7:0];
	end
	else begin
	    hex_val = BTN3
		? if_ram.data_out[7:0]
		: if_ram.addr[7:0];
	end
	    
    end

    dev_ram ram0(
	.clk(CLK),
	.ram(if_ram.server)
    );

endmodule
