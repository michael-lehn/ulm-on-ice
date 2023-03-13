module test (
    input logic CLK,
    input logic RX,
    input logic BTN1,
    input logic BTN2,
    output logic TX,
    output logic [7:0] PMOD_1A,
    input logic [7:0] PMOD_1B,
    output LED1,
    output LED2,
    output LED3
);

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;

    logic rst = 0;

    if_io if_io();

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

    logic [7:0] hex_pins;
    assign  PMOD_1A = hex_pins;

    logic [7:0] hex_val;
    assign hex_val = if_io.getc_char;

    dev_hex dev_hex0(
	.clk(CLK),
	.en(1'b1),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

    // ---------
    
    assign LED1 = !if_io.getc_en;	  // inbuf is empty
    assign LED2 = if_io.inbuf_full;	  // inbuf is full
    assign LED3 = BTN1 && !if_io.getc_en; // error: can't pop from empty inbuf

    // ---------

    initial begin
	if_io.getc_pop = 0;
    end

    logic [31:0] btn1 = 0;
    always_ff @ (posedge CLK) begin
	btn1 <= {BTN1, btn1[31:1]};

	if_io.getc_pop <= 0;
	if (!btn1[0] && btn1[1]) begin
	    if_io.getc_pop <= if_io.getc_en;
	end
    end
 
    // ---------

    initial begin
	if_io.putc_push = 0;
    end

    assign if_io.putc_char = {
	PMOD_1B[0],
	PMOD_1B[1],
	PMOD_1B[2],
	PMOD_1B[3],
	PMOD_1B[4],
	PMOD_1B[5],
	PMOD_1B[6],
	PMOD_1B[7]
    };

    logic [31:0] btn2 = 0;
    always_ff @ (posedge CLK) begin
	btn2 <= {BTN2, btn2[31:1]};

	if_io.putc_push <= 0;
	if (!btn2[0] && btn2[1]) begin
	    if_io.putc_push <= 1;
	end
    end

endmodule
