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
    input logic BTN1,	// BTN1: reset addr_out
			// BTN1 & BTN3: reset loader
    input logic BTN2,	// fetch byte from addr_out
    input logic BTN3,	// display fetched byte
    output logic LED1,	// inbuf is empty
    output logic LED2,	// inbuf is full
    output logic LED3,	// loader done
    output logic LED4	// if loader not done: invalid byte
			// otherwise: high bits in ram.data_out not clean
);
    logic [7:0] hex_pins;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_pins;

    logic [7:0] hex_val;

    dev_hex dev_hex0 (
	.clk(CLK),
	.en(1'b1),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

    // ---------

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;

    logic rst = BTN1 & BTN3;

    if_io io();

    assign LED1 = !io.getc_en;	  // inbuf is empty
    assign LED2 = io.inbuf_full;	  // inbuf is full

    initial begin
	io.getc_pop = 0;
	io.putc_push = 0;
	io.putc_char = 0;
    end

    dev_io #(
	.CLK_FREQ(CLK_FREQ),
	.BAUD(BAUD)
    ) io0(
	.clk(CLK),
	.rst(rst),
	.rx(RX),
	.tx(TX),
	.io(io.server)
    );

    // ---------

    if_ram ram_loader(), ram_debugger(), ram();

    logic loader_done;
    logic [pkg_ram::RAM_BYTE_SIZE-1:0] loader_byte_val;
    logic loader_byte_valid;
    assign LED3 = loader_done;


    dev_ram_switch dev_ram_switch0(
	.select(loader_done),
	.ram0(ram_loader.server),
	.ram1(ram_debugger.server),
	.ram(ram.client)
    );

    dev_loader dev_loader0(
	.clk(CLK),
	.rst(rst),
	.io(io.client),
	.ram(ram_loader.client),
	.done(loader_done),
	.byte_val(loader_byte_val),
	.byte_valid(loader_byte_valid)
    );

    logic [pkg_ram::RAM_QUAD_SIZE-1:0] debugger_out;

    dev_ram_debugger dev_ram_debugger0(
	.clk(CLK),
	.ram(ram_debugger.client),
	.rst_addr(BTN1),
	.fetch(BTN2),
	.sel_out(BTN3),
	.out(debugger_out)
    );

    assign LED4 = loader_done
	? debugger_out[pkg_ram::RAM_QUAD_SIZE-1:8] != 0
	: !loader_byte_valid;

    assign hex_val = loader_done
	? debugger_out[pkg_ram::RAM_BYTE_SIZE-1:0]
	: loader_byte_val;

    dev_ram ram0(
	.clk(CLK),
	.ram(ram.server)
    );

endmodule
