`include "alu_pkg.sv"

module test (
    input logic CLK,
    input logic BTN1,
    output logic LED1,
    output logic LED2,
    output logic LED3,
    output logic LED4
);
    //
    // For debugging count cycles
    //
    integer posedgeCount = 0;
    integer initCount = 0;

    /* verilator lint_off UNUSEDSIGNAL */
    logic btn_r = 0;
    /* verilator lint_on UNUSEDSIGNAL */
    assign LED1 = posedgeCount[0];

    always_ff @ (posedge CLK) begin
	initCount <= initCount + 1;
	btn_r <= BTN1;
	`ifdef SYNTHESIS
	if (init && !BTN1 && btn_r) begin
	`else
	if (init) begin
	`endif
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

    localparam REG_WIDTH = 64;
    parameter REG_DEPTH = 16;
    localparam REG_ADDRW = $clog2(REG_DEPTH);

    logic [REG_ADDRW-1:0] reg_file_addr_out0;
    logic [REG_ADDRW-1:0] reg_file_addr_out1;

    logic [REG_WIDTH-1:0] reg_file_data_out0;
    logic [REG_WIDTH-1:0] reg_file_data_out1;

    logic reg_file_en_in = 0;
    logic [REG_ADDRW-1:0] reg_file_addr_in = 0;
    logic [REG_WIDTH-1:0] reg_file_data_in = 0;

    alu_pkg::alu_op_t alu_op;
    logic [63:0] alu_res;

    /* verilator lint_off UNUSEDSIGNAL */
    logic alu_cf;
    logic alu_of;
    logic alu_sf;
    logic alu_zf;
    /* verilator lint_on UNUSEDSIGNAL */

    logic [15:0] val_a = 16'hffff;

    always_ff @ (posedge CLK) begin
	if (init && posedgeCount < 2 ** 5) begin
	    reg_file_en_in <= 0;
	    alu_op <= ALU_NOP;
    
	    case (posedgeCount[4:0])
		2: // in next cycle set register 1
		    begin
			reg_file_en_in <= 1;
			reg_file_addr_in <= 1;
			reg_file_data_in <= { {64-16{val_a[15]}}, val_a };
		    end
		3: // in next cycle set register 2
		    begin
			reg_file_en_in <= 1;
			reg_file_addr_in <= 2;
			reg_file_data_in <= 64'h5678;
		    end
		4: // in next cycle add register 1 to register 2
		    begin
			reg_file_addr_out0 <= 1;
			reg_file_addr_out1 <= 2;
			alu_op <= ALU_ADD;
		    end
		5: // write result to register 3
		    begin
			reg_file_en_in <= 1;
			reg_file_addr_in <= 3;
			reg_file_data_in <= alu_res;
		    end
		6: // in next cycle subtract register 2 from register 1
		    begin
			reg_file_addr_out0 <= 2;
			reg_file_addr_out1 <= 1;
			alu_op <= ALU_SUB;
		    end
		7: // write result to register 3
		    begin
			reg_file_en_in <= 1;
			reg_file_addr_in <= 3;
			reg_file_data_in <= alu_res;
		    end
		8: // in next cycle subtract register 1 from register 1
		    begin
			reg_file_addr_out0 <= 1;
			reg_file_addr_out1 <= 1;
			alu_op <= ALU_SUB;
		    end
		9: // write result to register 3
		    begin
			reg_file_en_in <= 1;
			reg_file_addr_in <= 3;
			reg_file_data_in <= alu_res;
		    end
		default:
		    ;
	    endcase
	end
    end

    always_comb begin
	LED2 = alu_res[0];
	LED3 = alu_res[1];
	LED4 = alu_res[2];
    end

    reg_file #(
	REG_DEPTH
    ) reg_file1 (
	.clk(CLK),
	.en_in(reg_file_en_in),
	.addr_in(reg_file_addr_in),
	.data_in(reg_file_data_in),
	.addr_out0(reg_file_addr_out0),
	.addr_out1(reg_file_addr_out1),
	.data_out0(reg_file_data_out0),
	.data_out1(reg_file_data_out1)
    );

    alu alu1(
	.clk(CLK),
	.op(alu_op),
	.a(reg_file_data_out0),
	.b(reg_file_data_out1),
	.res(alu_res),
	.zf(alu_zf),
	.cf(alu_cf),
	.of(alu_of),
	.sf(alu_sf)
    );

endmodule

