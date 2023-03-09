module test (
    input logic CLK,
    input logic RX,
    input logic BTN1,
    output logic TX,
    output  logic [7:0] PMOD_1A,
    output LED1,
    output LED2,
    output LED3,
    output LED4,
    output LED5
);

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;

    logic rst = 0;
    if_iobuf inbuf();

    dev_io #(
	.CLK_FREQ(CLK_FREQ),
	.BAUD(BAUD)
    ) io0(
	.clk(CLK),
	.rst(rst),
	.rx(RX),
	.tx(TX),
	.inbuf(inbuf)
    );

    // ---------

    logic [1:0] inbuf_led = 0;
    
    logic [7:0] hex_pins;
    assign  PMOD_1A = hex_pins;

    logic [7:0] hex_val;
    assign hex_val = inbuf.data_out;

    dev_hex dev_hex0(
	.clk(CLK),
	.hex_val(hex_val),
	.hex_pins(hex_pins)
    );

    // ---------
    
    assign {LED2, LED1} = inbuf_led;
    assign LED5 = BTN1 && inbuf.empty;
    assign LED3 = inbuf.empty;
    assign LED4 = inbuf.full;

    always_ff @ (posedge CLK) begin
	if (inbuf.push_back) begin
	    inbuf_led <= inbuf_led + 1;
	end
    end

    // ---------

    initial begin
	inbuf.pop_front = 0;
    end

    logic [31:0] btn1 = 0;
    always_ff @ (posedge CLK) begin
	btn1 <= {BTN1, btn1[31:1]};

	inbuf.pop_front <= 0;
	if (!btn1[0] && btn1[1]) begin
	    inbuf.pop_front <= !inbuf.empty;
	end
    end

endmodule
