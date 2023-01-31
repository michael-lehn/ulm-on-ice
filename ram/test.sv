`include "ram_pkg.sv"

module test(
    input logic CLK
);

    //
    // For debugging count cycles
    //
    integer posedgeCount = 0;
    integer initCount = 0;

    always_ff @ (posedge CLK) begin
	initCount <= initCount + 1;
	if (init) begin
	    posedgeCount <= posedgeCount + 1;
	end
    end

    //
    // BRAM is ready if init is true
    //
    `ifdef SYNTHESIS
    logic init = 0;
    always_ff @ (posedge CLK) begin
	if (initCount == 60) begin
	    init <= 1;
	end
    end
    `else
    logic init = 1;
    `endif

    //
    // Write some data to memory; Read some data from memory
    //

    localparam ADDRW = 17;
    localparam QUAD_WIDTH = ram_pkg::RAM_QUAD;
    
    ram_pkg::ram_op_t ram_op /* verilator public */;
    ram_pkg::ram_size_t ram_size /* verilator public */;
    logic [ADDRW-1:0] ram_addr /* verilator public */;
    logic [QUAD_WIDTH-1:0] ram_data_in /* verilator public */;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [QUAD_WIDTH-1:0] ram_data_out /* verilator public */;
    /* verilator lint_on UNUSEDSIGNAL */

    /*
    always_ff @ (posedge CLK) begin
	ram_op <= ram_pkg::RAM_NOP;

	if (init) begin
	    case (posedgeCount)
		// store quad
		0:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_QUAD;
			ram_addr <= 0;
			ram_data_in <= 64'h0102030405060708;
		    end
		// store long
		2:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_LONG;
			ram_addr <= 8;
			ram_data_in <= 64'h090A0B0C;
		    end
		4:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_LONG;
			ram_addr <= 12;
			ram_data_in <= 64'h0D0E0F10;
		    end
		// store word
		6:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_WORD;
			ram_addr <= 16;
			ram_data_in <= 64'hAABB;
		    end
		8:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_WORD;
			ram_addr <= 18;
			ram_data_in <= 64'hCCDD;
		    end
		10:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_WORD;
			ram_addr <= 20;
			ram_data_in <= 64'hEEFF;
		    end
		12:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_WORD;
			ram_addr <= 22;
			ram_data_in <= 64'hAFBD;
		    end
		// store byte
		14:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 24;
			ram_data_in <= 64'hfe;
		    end
		16:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 25;
			ram_data_in <= 64'hdc;
		    end
		18:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 26;
			ram_data_in <= 64'hba;
		    end
		20:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 27;
			ram_data_in <= 64'h98;
		    end
		22:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 28;
			ram_data_in <= 64'h76;
		    end
		24:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 29;
			ram_data_in <= 64'h54;
		    end

		26:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 30;
			ram_data_in <= 64'h32;
		    end
		28:
		    begin
			ram_op <= ram_pkg::RAM_STORE;
			ram_size <= ram_pkg::RAM_BYTE;
			ram_addr <= 31;
			ram_data_in <= 64'h10;
		    end







		// load quad
		30:
		    begin
			ram_op <= ram_pkg::RAM_FETCH;
			ram_size <= ram_pkg::RAM_QUAD;
			ram_addr <= 0;
		    end
		32:
		    begin
			ram_op <= ram_pkg::RAM_FETCH;
			ram_size <= ram_pkg::RAM_QUAD;
			ram_addr <= 8;
		    end
		34:
		    begin
			ram_op <= ram_pkg::RAM_FETCH;
			ram_size <= ram_pkg::RAM_QUAD;
			ram_addr <= 16;
		    end
		36:
		    begin
			ram_op <= ram_pkg::RAM_FETCH;
			ram_size <= ram_pkg::RAM_QUAD;
			ram_addr <= 24;
		    end
	    endcase
	end
    end
    */

    ram ram0(
	.clk(CLK),
	.addr(ram_addr),
	.op(ram_op),
	.size(ram_size),
	.data_in(ram_data_in),
	.data_out(ram_data_out)
    );

endmodule
