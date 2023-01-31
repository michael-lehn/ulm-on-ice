`include "../ram/ram_pkg.sv"
`include "../reg_file/alu_pkg.sv"

module test(
    input logic CLK,
    output logic LED1,
    output TX
);

    logic init;

    init init0(
	.clk(CLK),
	.init(init)
    );

    integer numInstr = 10;
    integer numInstrLoaded = 0;

    logic prog_loaded;
    assign prog_loaded = numInstrLoaded == numInstr;
    logic [ADDRW-1:0] load_addr /* verilator public */ = 0;


    typedef enum {
	FETCH,
	DECODE,
	EXECUTE,
	INCREMENT
    } run_state_t;
    run_state_t run_state = FETCH;
    logic run_jmp = 0;
    logic [QUAD_WIDTH-1:0] ip = 0;

    localparam ADDRW = 17;
    localparam QUAD_WIDTH = ram_pkg::RAM_QUAD;
    localparam LONG_WIDTH = ram_pkg::RAM_LONG;

    ram_pkg::ram_op_t ram_op /* verilator public */;
    ram_pkg::ram_size_t ram_size /* verilator public */;
    logic [ADDRW-1:0] ram_addr /* verilator public */;
    logic [QUAD_WIDTH-1:0] ram_data_in /* verilator public */;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [QUAD_WIDTH-1:0] ram_data_out /* verilator public */;
    /* verilator lint_on UNUSEDSIGNAL */

    assign ram_addr = prog_loaded ? ip[ADDRW-1:0] : load_addr;
    logic ip_init = 0;
    logic prog_halted = 0;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [7:0] prog_exit = 0;
    logic prog_illegal_instr = 0;
    /* verilator lint_on UNUSEDSIGNAL */

    /* verilator lint_off UNUSEDSIGNAL */
    logic [LONG_WIDTH-1:0] instr;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [LONG_WIDTH-1:0] instr_r;
    assign instr = run_state == DECODE ? ram_data_out[LONG_WIDTH-1:0]
				       : instr_r;

    always_ff @ (posedge CLK) begin
	if (!init) begin
	end
	else if (!prog_loaded) begin
	    if (ram_op == ram_pkg::RAM_NOP) begin
		case (numInstrLoaded)
		    // ldzwq 2, %1
		    0: ram_data_in <= { 32'h0, 32'h05_00005_1 };
		    // putc 'H'
		    1: ram_data_in <= { 32'h0, 32'h02_48_0000 };
		    // putc 'a'
		    2: ram_data_in <= { 32'h0, 32'h02_61_0000 };
		    // putc 'l'
		    3: ram_data_in <= { 32'h0, 32'h02_6C_0000 };
		    // putc 'l'
		    4: ram_data_in <= { 32'h0, 32'h02_6C_0000 };
		    // putc 'o'
		    5: ram_data_in <= { 32'h0, 32'h02_6F_0000 };
		    // putc '\n'
		    6: ram_data_in <= { 32'h0, 32'h02_0A_0000 };
		    // subq 1, %1, %1
		    7: ram_data_in <= { 32'h0, 32'h07_0001_1_1 };
		    // jnz  -7 * 4
		    8: ram_data_in <= { 32'h0, 32'h08_FFFFF9 };
		    // halt 0
		    9: ram_data_in <= { 32'h0, 32'h01_00_0000 };
		endcase
		ram_size <= ram_pkg::RAM_LONG;
		ram_op <= ram_pkg::RAM_STORE;
	    end
	    else begin
		ram_op <= ram_pkg::RAM_NOP;
		numInstrLoaded <= numInstrLoaded + 1;
		load_addr <= load_addr + 4;
	    end
	end
	else if (!ip_init) begin
	    ram_op <= ram_pkg::RAM_FETCH;
	    ip <= 0;
	    ip_init <= 1;
	end
	else if (!prog_halted) begin
	    case (run_state)
		FETCH:
		    begin
			run_state <= DECODE;
			ram_size <= ram_pkg::RAM_LONG;
			ram_op <= ram_pkg::RAM_NOP;
		    end
		DECODE:
		    begin
			run_state <= EXECUTE;
			instr_r <= ram_data_out[LONG_WIDTH-1:0];
			case (instr[31:24])
			    8'h1: // halt X
				begin
				    prog_halted <= 1;
				    prog_exit <= instr[23:16];
				end
			    8'h2: // putc X
				begin
				    tx_push_back <= !tx_full;
				    tx_data_in <= instr[23:16];
				    if (tx_full) begin
					// block until character can be
					// written
					run_state <= DECODE;
				    end
				end
			    8'h3: // jmp X
				begin
				    alu_a_imm <= {
						    {64-26{instr[23]}},
						    instr[23:0],    // X
						    2'b00
						 };
				    alu_b_imm <= ip;
				    alu_a_sel <= 1;
				    alu_b_sel <= 1;
				    alu_op <= alu_pkg::ALU_ADD;
				    run_jmp <= 1;
				end
			    8'h4: // ldswq X, %Y
				begin
				    alu_a_imm <= {
						    {64-20{instr[23]}},
						    instr[23:4]	    // X
						 };
				    alu_b_imm <= 0;
				    alu_a_sel <= 1;
				    alu_b_sel <= 1;
				    alu_op <= alu_pkg::ALU_ADD;
				end
			    8'h5: // ldzwq X, %Y
				begin
				    alu_a_imm <= {
						    {64-20{1'b0}},
						    instr[23:4]	    // X
						 };
				    alu_b_imm <= 0;
				    alu_a_sel <= 1;
				    alu_b_sel <= 1;
				    alu_op <= alu_pkg::ALU_ADD;
				end
			    8'h6: // addq X, %Y, %Z
				begin
				    alu_a_imm <= {
						    {64-16{1'b0}},
						    instr[23:8]	    // X
						 };
				    alu_b_reg <= instr[7:4];	    // Y;
				    alu_a_sel <= 1;
				    alu_b_sel <= 0;
				    alu_op <= alu_pkg::ALU_ADD;
				end
			    8'h7: // subq X, %Y, %Z
				begin
				    alu_a_imm <= {
						    {64-16{1'b0}},
						    instr[23:8]	    // X
						 };
				    alu_b_reg <= instr[7:4];	    // Y;
				    alu_a_sel <= 1;
				    alu_b_sel <= 0;
				    alu_op <= alu_pkg::ALU_SUB;
				end
			    8'h8: // jnz X
				begin
				    if (!alu_zf) begin
					alu_a_imm <= {
							{64-26{instr[23]}},
							instr[23:0],	    // X
							2'b00
						     };
					alu_b_imm <= ip;
					alu_a_sel <= 1;
					alu_b_sel <= 1;
					alu_op <= alu_pkg::ALU_ADD;
					run_jmp <= 1;
				    end
				end
			    default: // illegal instruction
				begin
				    prog_halted <= 1;
				    prog_illegal_instr <= 1;
				end
			endcase
		    end
		EXECUTE:
		    begin
			run_state <= INCREMENT;
			case (instr[31:24])
			    8'h1:
				;
			    8'h2:
				begin
				    tx_push_back <= 0;
				end
			    8'h3: // jmp X
				begin
				    alu_op <= alu_pkg::ALU_NOP;
				    ip <= alu_res;
				end
			    8'h4: // ldswq X, %Y
				begin
				    alu_op <= alu_pkg::ALU_NOP;
				    reg_file_en_in <= 1;
				    reg_file_addr_in <= instr[3:0]; // Y
				    reg_file_data_in <= alu_res;
				end
			    8'h5: // ldzwq X, %Y
				begin
				    alu_op <= alu_pkg::ALU_NOP;
				    reg_file_en_in <= 1;
				    reg_file_addr_in <= instr[3:0]; // Y
				    reg_file_data_in <= alu_res;
				end
			    8'h6: // addq X, %Y, %Z
				begin
				    alu_op <= alu_pkg::ALU_NOP;
				    reg_file_en_in <= 1;
				    reg_file_addr_in <= instr[3:0]; // Z
				    reg_file_data_in <= alu_res;
				end
			    8'h7: // subq X, %Y, %Z
				begin
				    alu_op <= alu_pkg::ALU_NOP;
				    reg_file_en_in <= 1;
				    reg_file_addr_in <= instr[3:0]; // Z
				    reg_file_data_in <= alu_res;
				end
			    8'h8: // jmp X
				begin
				    if (run_jmp) begin
					alu_op <= alu_pkg::ALU_NOP;
					ip <= alu_res;
				    end
				end
			    default:
				;
			endcase
		    end
		INCREMENT:
		    begin
			run_state <= FETCH;
			ram_op <= ram_pkg::RAM_FETCH;
			run_jmp <= 0;
			reg_file_en_in <= 0;
			if (!run_jmp) begin
			    ip <= ip + 4;
			end
		    end

	    endcase
	end
    end

    ram ram0(
	.clk(CLK),
	.addr(ram_addr),
	.op(ram_op),
	.size(ram_size),
	.data_in(ram_data_in),
	.data_out(ram_data_out)
    );

    //
    // error handling / debugging
    //

    logic error;
    assign error = tx_error || prog_illegal_instr;

    `ifndef SYNTHESIS
    always_ff @ (posedge CLK) begin
	if (error) begin
	    $display("error");
	end
    end
    `endif


    logic tx_rst = 0;
    logic tx_push_back = 0;
    logic [7:0] tx_data_in;
    logic tx_full;
    logic tx_error;

    assign LED1 = tx_full;

    tx_pipe #(
	.CLK_FREQ(12_000_000),
	.BAUD(9_600)
    ) tx_pipe1 (
	.clk(CLK),
	.rst(tx_rst),
	.push_back(tx_push_back),
	.data_in(tx_data_in),
	.full(tx_full),
	.tx(TX),
	.error(tx_error)
    );

    localparam REG_WIDTH = 64;
    parameter REG_DEPTH = 16;
    localparam REG_ADDRW = $clog2(REG_DEPTH);

    logic [REG_ADDRW-1:0] reg_file_addr_out0;
    logic [REG_ADDRW-1:0] reg_file_addr_out1;

    logic [REG_WIDTH-1:0] reg_file_data_out0;
    logic [REG_WIDTH-1:0] reg_file_data_out1;

    logic reg_file_en_in = 0;
    logic [REG_ADDRW-1:0] reg_file_addr_in;
    logic [REG_WIDTH-1:0] reg_file_data_in;

    reg_file #(
	REG_DEPTH
    ) reg_file0 (
	.clk(CLK),
	.en_in(reg_file_en_in),
	.addr_in(reg_file_addr_in),
	.data_in(reg_file_data_in),
	.addr_out0(reg_file_addr_out0),
	.addr_out1(reg_file_addr_out1),
	.data_out0(reg_file_data_out0),
	.data_out1(reg_file_data_out1)
    );

    alu_pkg::alu_op_t alu_op;
    logic [QUAD_WIDTH-1:0] alu_a, alu_a_imm;
    logic [QUAD_WIDTH-1:0] alu_b, alu_b_imm;
    logic [REG_ADDRW-1:0] alu_a_reg = 0, alu_b_reg = 0;
    logic alu_a_sel, alu_b_sel;

    always_comb begin
	alu_a = alu_a_sel ? alu_a_imm : reg_file_data_out0;
	alu_b = alu_b_sel ? alu_b_imm : reg_file_data_out1;
	reg_file_addr_out0 = alu_a_reg;
	reg_file_addr_out1 = alu_b_reg;
    end

    logic [QUAD_WIDTH-1:0] alu_res;
    /* verilator lint_off UNUSEDSIGNAL */
    logic alu_zf, alu_cf, alu_of, alu_sf;
    /* verilator lint_on UNUSEDSIGNAL */

    alu alu0(
	.clk(CLK),
	.op(alu_op),
	.a(alu_a),
	.b(alu_b),
	.res(alu_res),
	.zf(alu_zf),
	.cf(alu_cf),
	.of(alu_of),
	.sf(alu_sf)
    );


endmodule
