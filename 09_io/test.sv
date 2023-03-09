module test (
    input logic CLK,
    input logic RX,
    input logic BTN1,
    input logic BTN2,
    output logic TX,
    output  logic [7:0] PMOD_1A,
    output LED1,
    output LED2,
    output LED3
);

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;

    logic rst = 0;

    logic inbuf_full;
    logic getc_en;
    logic getc_pop;
    logic [7:0] getc_char;
    logic putc_push;
    logic putc_push_done;
    logic [7:0] putc_char;

    dev_io #(
	.CLK_FREQ(CLK_FREQ),
	.BAUD(BAUD)
    ) io0(
	.clk(CLK),
	.rst(rst),
	.rx(RX),
	.tx(TX),
	.inbuf_full(inbuf_full),
	.getc_en(getc_en),
    	.getc_pop(getc_pop),
    	.getc_char(getc_char),
    	.putc_push(putc_push),
    	.putc_push_done(putc_push_done),
    	.putc_char(putc_char)
    );

    // ---------

    logic [7:0] hex_pins;
    assign  PMOD_1A = hex_pins;

    logic [7:0] hex_val;
    assign hex_val = getc_char;

    dev_hex dev_hex0(
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

    // ---------
    
    assign LED1 = BTN1 && !getc_en;
    assign LED2 = !getc_en;
    assign LED3 = inbuf_full;

    // ---------

    initial begin
	getc_pop = 0;
    end

    logic [31:0] btn1 = 0;
    always_ff @ (posedge CLK) begin
	btn1 <= {BTN1, btn1[31:1]};

	getc_pop <= 0;
	if (!btn1[0] && btn1[1]) begin
	    getc_pop <= getc_en;
	end
    end
 
    // ---------

    initial begin
	putc_push = 0;
	putc_char = "A";
    end

    logic [31:0] btn2 = 0;
    always_ff @ (posedge CLK) begin
	btn2 <= {BTN2, btn2[31:1]};

	putc_push <= 0;
	if (!btn2[0] && btn2[1]) begin
	    putc_push <= 1;
	end

	if (putc_push_done) begin
	    putc_char <= putc_char + 1;
	end
    end

endmodule
