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
    output logic LED1,	// inbuf is empty
    output logic LED2,	// inbuf is full
    output logic LED3,	// loader done
    output logic LED4,	// cpu halted
    input BTN1		// reset
);
    // ---------
    // device: hex display

    logic [7:0] hex_pins;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_pins;

    logic [7:0] hex_val;

    dev_hex dev_hex0 (
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

    // ---------
    // device: IO

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;

    logic rst = BTN1;

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
    // device: ALU

    if_alu alu();

    dev_alu dev_alu0(
	.clk(CLK),
	.alu(alu.server)
    );

    // ---------
    // device: register file

    if_reg_file reg_file();

    dev_reg_file dev_reg_file0(
	.clk(CLK),
	.reg_file(reg_file.server)
    );

    // ---------
    // device: random access memory

    if_ram ram();

    dev_ram ram0(
	.clk(CLK),
	.ram(ram.server)
    );

    // ---------
    // loader and CPU share access to RAM

    if_ram ram_loader(), ram_cpu();

    logic loader_done;
    assign LED3 = loader_done;

    dev_ram_switch dev_ram_switch0(
	.select(loader_done),
	.ram0(ram_loader.server),
	.ram1(ram_cpu.server),
	.ram(ram.client)
    );

    // ---------
    // loader and CPU share access to IO

    if_io io_loader(), io_cpu();
    
    dev_io_switch dev_io_switch0(
	.select(loader_done),
	.io0(io_loader.server),
	.io1(io_cpu.server),
	.io(io.client)
    );

    // ---------
    // device: loader

    logic [pkg_ram::RAM_BYTE_SIZE-1:0] loader_byte_val;
    logic loader_byte_valid;

    dev_loader dev_loader0(
	.clk(CLK),
	.rst(rst),
	.io(io_loader.client),
	.ram(ram_loader.client),
	.done(loader_done),
	.byte_val(loader_byte_val),
	.byte_valid(loader_byte_valid)
    );

    logic cpu_halted;
    logic [pkg_ram::RAM_BYTE_SIZE-1:0] cpu_exit_code;

    // ---------
    // device: control unit

    dev_cu dev_cu0(
	.clk(CLK),
	.en(loader_done),
	.rst(rst),
	.ram(ram_cpu.client),
	.reg_file(reg_file.client),
	.io(io_cpu.client),
	.alu(alu.client),
	.halted(cpu_halted),
	.exit_code(cpu_exit_code)
    );

    assign LED4 = loader_done
	? cpu_halted
	: loader_byte_valid;
    assign hex_val = loader_done
	? cpu_exit_code
	: loader_byte_val;

endmodule
