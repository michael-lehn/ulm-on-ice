module test (
    input logic CLK,
    output logic TX,
    output logic LED1,
    output logic LED2,
    output logic LED3,
    output logic LED4
);
    //
    // Program loader
    //

    if_dev_ram loader_ram();
    logic loader_done;

    loader loader0(
	.clk(CLK),
	.ram(loader_ram),
	.done(loader_done)
    );

    //
    // CPU consistes of control unit and devices
    //
    
    //-- CU (Control unit) -----------------------------------------------------
    logic putc;
    logic [7:0] putc_char;

    if_dev_reg_file dev_reg_file();
    if_dev_ram dev_ram();
    if_dev_alu dev_alu();

    logic cu_en = 0;
    logic putc_pending = 0;

    always_ff @ (posedge CLK) begin
	tx_push_back <= 0;
	if (putc && !tx_push_back && !tx_full) begin
	    tx_push_back <= !tx_push_back;
	    tx_data_in <= putc_char;
	end
	cu_en <= loader_done && !tx_full;
    end

    cu cu0(
	.clk(CLK),
	.en(cu_en),
	.dev_ram(dev_ram),
	.dev_reg_file(dev_reg_file),
	.dev_alu(dev_alu),
	.putc(putc),
	.putc_char(putc_char),
	.led({LED4, LED3, LED2, LED1})
    );

    //
    // Devices connected to control unit
    //

    //-- Device: Register file -------------------------------------------------

    dev_reg_file dev_reg_file0(
	.clk(CLK),
	.reg_file(dev_reg_file)
    );

    //-- Device: RAM -----------------------------------------------------------
    //
    // Needs to be shared between loader and control unit.
    //
    if_dev_ram sel_ram();

    always_comb begin
	if (!cu_en) begin
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
 
    //-- Device: ALU -----------------------------------------------------------

    dev_alu dev_alu0(
	.clk(CLK),
	.alu(dev_alu)
    );

    //-- output device ---------------------------------------------------------
    logic tx_rst = 0;
    logic tx_push_back = 0;
    logic [7:0] tx_data_in;
    logic tx_full;
    logic tx_error;

    localparam CLK_FREQ = 12_000_000;
    localparam BAUD = 9_600;
    // localparam BAUD = 1_000_000;

    tx_pipe #(
	CLK_FREQ,
	BAUD
    ) tx_pipe0 (
       .clk(CLK),
       .rst(tx_rst),
       .push_back(tx_push_back),
       .data_in(tx_data_in),
       .full(tx_full),
       .tx(TX),
       .error(tx_error)
    );

endmodule
