`include "pkg_alu.sv"
`include "pkg_cu.sv"
`include "pkg_io.sv"

module dev_decoder (
    input logic clk,
    input logic rst,
    input logic en,

    // content of instruction register
    /* verilator lint_off UNUSEDSIGNAL */
    input logic [31:0] ir,
    if_alu.observer alu,
    /* verilator lint_on UNUSEDSIGNAL */

    // decoded instruction
    output if_instr_alu.client instr_alu,
    output if_instr_bus.client instr_bus,
    output if_instr_cu.client instr_cu,
    output if_instr_io.client instr_io
);

    logic [7:0] op;
    assign op = ir[31:24];

    initial begin
	instr_alu.op = pkg_alu::ALU_NOP;
	instr_bus.op = pkg_bus::BUS_NOP;
	instr_cu.op = pkg_cu::CU_NOP;
	instr_io.op = pkg_io::IO_NOP;
    end

    //
    // cu instructions (jumps and halt)
    //
    if_instr_cu instr_cu_next();

    always_ff @ (posedge clk) begin
	if (rst) begin
	    instr_cu.op <= pkg_cu::CU_NOP;
	end
	else if (en) begin
	    instr_cu.op <= instr_cu_next.op;
	    instr_cu.exit_code_imm <= instr_cu_next.exit_code_imm;
	    instr_cu.jmp_offset <= instr_cu_next.jmp_offset;
	    instr_cu.cu_reg0 <= instr_cu_next.cu_reg0;
	    instr_cu.cu_reg1 <= instr_cu_next.cu_reg1;
	end
    end

    always_comb begin
	instr_cu_next.op = pkg_cu::CU_NOP;
	instr_cu_next.exit_code_imm = ir[23:16];
	instr_cu_next.jmp_offset = {ir[23:0], 2'b0};
	instr_cu_next.cu_reg0 = ir[23:20];
	instr_cu_next.cu_reg1 = ir[19:16];

	case (op)
	    8'h01: // halt exit_code
		instr_cu_next.op = pkg_cu::CU_HALT_IMM;
	    8'h02: // halt %exit_code_reg
		instr_cu_next.op = pkg_cu::CU_HALT_REG;
	    8'h03: // jnz offset
		instr_cu_next.op = !alu.zf
				 ? pkg_cu::CU_REL_JMP
				 : pkg_cu::CU_NOP;
	    8'h04: // jz offset
		instr_cu_next.op = alu.zf
				 ? pkg_cu::CU_REL_JMP
				 : pkg_cu::CU_NOP;
	    8'h05: // jmp offset
		instr_cu_next.op = pkg_cu::CU_REL_JMP;
	    8'h06: // jb offset
		instr_cu_next.op = alu.cf
				 ? pkg_cu::CU_REL_JMP
				 : pkg_cu::CU_NOP;
	    8'h07: // jmp %func, %ret
		instr_cu_next.op = pkg_cu::CU_ABS_JMP;
	    default:
		;
	endcase
    end

    //
    // io instructions (putc and getc)
    //
    if_instr_io instr_io_next();

    always_ff @ (posedge clk) begin
	if (rst) begin
	    instr_io.op <= pkg_io::IO_NOP;
	end
	else if (en) begin
	    instr_io.op <= instr_io_next.op;
	    instr_io.char_imm <= instr_io_next.char_imm;
	    instr_io.char_reg <= instr_io_next.char_reg;
	end
    end

    always_comb begin
	instr_io_next.op = pkg_io::IO_NOP;
	instr_io_next.char_imm = ir[23:16];
	instr_io_next.char_reg = ir[23:20];

	case (op)
	    8'h30: // putc %x
		instr_io_next.op = pkg_io::IO_PUTC_REG;
	    8'h31: // putc x
		instr_io_next.op = pkg_io::IO_PUTC_IMM;
	    8'h32: // getc %x
		instr_io_next.op = pkg_io::IO_GETC_REG;
	    default:
	    ;
	endcase
    end

    //
    // ALU instructions
    //
    if_instr_alu instr_alu_next();

    always_ff @ (posedge clk) begin
	if (rst) begin
	    instr_alu.op <= pkg_alu::ALU_NOP;
	end
	else if (en) begin
	    instr_alu.op <= instr_alu_next.op;
	    instr_alu.a_sel <= instr_alu_next.a_sel;
	    instr_alu.s_reg <= instr_alu_next.s_reg;
	    instr_alu.b_reg <= instr_alu_next.b_reg;
	    instr_alu.a_reg <= instr_alu_next.a_reg;
	    instr_alu.a_imm <= instr_alu_next.a_imm;
	end
    end

    always_comb begin
	instr_alu_next.s_reg = ir[23:20];
	instr_alu_next.b_reg = ir[19:16];
	instr_alu_next.a_reg = ir[15:12];
	instr_alu_next.a_imm = {{64-16{1'b0}}, ir[15:0]};

	instr_alu_next.op = pkg_alu::ALU_NOP;
	instr_alu_next.a_sel = pkg_alu::ALU_REG;

	case (op)
	    8'h10: // ldzwq a, %s  becomes a + %0 -> %s
		begin
		    instr_alu_next.op = pkg_alu::ALU_ADD;
		    instr_alu_next.a_sel = pkg_alu::ALU_IMM;
		    instr_alu_next.b_reg = 0;
		    instr_alu_next.a_reg = 0;
		    instr_alu_next.a_imm = {{64-20{1'b0}}, ir[19:0]};
		end
	    8'h11: // addq %a, %b, %s
		begin
		    instr_alu_next.op = pkg_alu::ALU_ADD;
		end
	    8'h12: // addq a, %b, %s
		begin
		    instr_alu_next.op = pkg_alu::ALU_ADD;
		    instr_alu_next.a_sel = pkg_alu::ALU_IMM;
		end
	    8'h13: // subq %a, %b, %s
		begin
		    instr_alu_next.op = pkg_alu::ALU_SUB;
		    instr_alu_next.s_reg = ir[23:20];
		end
	    8'h14: // subq a, %b, %s
		begin
		    instr_alu_next.op = pkg_alu::ALU_SUB;
		    instr_alu_next.a_sel = pkg_alu::ALU_IMM;
		end
	    default:
		;
	endcase
    end

    //
    // bus instructions
    //
    if_instr_bus instr_bus_next();

    always_ff @ (posedge clk) begin
	if (rst) begin
	    instr_bus.op <= pkg_bus::BUS_NOP;
	end
	else if (en) begin
	    instr_bus.op <= instr_bus_next.op;
	    instr_bus.data_type <= instr_bus_next.data_type;
	    instr_bus.data_reg <= instr_bus_next.data_reg;
	    instr_bus.addr_reg <= instr_bus_next.addr_reg;
	    instr_bus.addr_offset <= instr_bus_next.addr_offset;
	end
    end

    always_comb begin
	instr_bus_next.op = pkg_bus::BUS_NOP;
	instr_bus_next.data_type = pkg_ram::RAM_BYTE;
	instr_bus_next.data_reg = ir[23:20];
	instr_bus_next.addr_reg = ir[19:16];
	instr_bus_next.addr_offset = {
	    ir[15],	// sign extension
	    ir[15:0]
	};

	case (op)
	    8'h20: // movzbq offset(%addr), %data
		begin
		    instr_bus_next.op = pkg_bus::BUS_FETCH;
		    instr_bus_next.data_type = pkg_ram::RAM_BYTE;
		end
	    8'h22: // movb %data, offset(%addr)
		begin
		    instr_bus_next.op = pkg_bus::BUS_STORE;
		    instr_bus_next.data_type = pkg_ram::RAM_BYTE;
		end
	    8'h23: // movq offset(%addr), %data
		begin
		    instr_bus_next.op = pkg_bus::BUS_FETCH;
		    instr_bus_next.data_type = pkg_ram::RAM_QUAD;
		end
	    8'h24: // movq %data, offset(%addr)
		begin
		    instr_bus_next.op = pkg_bus::BUS_STORE;
		    instr_bus_next.data_type = pkg_ram::RAM_QUAD;
		end
	    default:
		;
	endcase
    end


endmodule
