`include "pkg_alu.sv"
`include "pkg_bus.sv"
`include "pkg_cu.sv"
`include "pkg_io.sv"
`include "pkg_ram.sv"
`include "pkg_reg.sv"

module decoder (
    input logic clk,
    input logic en,

    // content of instruction register
    input logic [31:0] ir,

    // status register
    input logic stat_reg_zf,

    // decoded instruction
    output if_instr_cu instr_cu,
    output if_instr_io instr_io,
    output if_instr_alu instr_alu,
    output if_instr_bus instr_bus
);

    logic [7:0] op;
    assign op = ir[31:24];

    initial begin
	instr_cu.op = pkg_cu::CU_NOP;
    end

    //
    // cu instructions (jumps and halt)
    //
    if_instr_cu instr_cu_next();

    always_ff @ (posedge clk) begin
	if (en) begin
	    instr_cu.op <= instr_cu_next.op;
	    instr_cu.exit_code <= instr_cu_next.exit_code;
	    instr_cu.jmp_offset <= instr_cu_next.jmp_offset;
	end
    end

    /*
    */

    always_comb begin
	instr_cu_next.op = pkg_cu::CU_NOP;
	instr_cu_next.exit_code = ir[23:16];
	instr_cu_next.jmp_offset = ir[23:0];

	case (op)
	    8'h01: // halt exit_code
		instr_cu_next.op = pkg_cu::CU_HALT;
	    8'h02: // jnz offset
		instr_cu_next.op = !stat_reg_zf
				 ? pkg_cu::CU_JMP
				 : pkg_cu::CU_NOP;
	    8'h03: // jz offset
		instr_cu_next.op = stat_reg_zf
				 ? pkg_cu::CU_JMP
				 : pkg_cu::CU_NOP;
	    8'h04: // jmp offset
		instr_cu_next.op = pkg_cu::CU_JMP;
	    default:
		;
	endcase
    end

    //
    // ALU instructions
    //
    if_instr_alu instr_alu_next();

    always_ff @ (posedge clk) begin
	if (en) begin
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
		    instr_alu_next.a_sel = pkg_alu::ALU_REG;
		end
	    8'h12: // addq a, %b, %s
		begin
		    instr_alu_next.op = pkg_alu::ALU_ADD;
		    instr_alu_next.a_sel = pkg_alu::ALU_IMM;
		end
	    8'h13: // subq %a, %b, %s
		begin
		    instr_alu_next.op = pkg_alu::ALU_SUB;
		    instr_alu_next.a_sel = pkg_alu::ALU_REG;
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
	if (en) begin
	    instr_bus.op <= instr_bus_next.op;
	    instr_bus.size <= instr_bus_next.size;
	    instr_bus.data_reg <= instr_bus_next.data_reg;
	    instr_bus.addr_reg <= instr_bus_next.addr_reg;
	    instr_bus.addr_offset <= instr_bus_next.addr_offset;
	end
    end

    always_comb begin
	instr_bus_next.op = pkg_bus::BUS_NOP;
	instr_bus_next.size = pkg_ram::RAM_BYTE;
	instr_bus_next.data_reg = ir[23:20];
	instr_bus_next.addr_reg = ir[19:16];
	instr_bus_next.addr_offset = {1'b0, ir[15:0]};

	case (op)
	    8'h20: // movzbq offset(%addr), %data
		begin
		    instr_bus_next.op = pkg_bus::BUS_FETCH;
		    instr_bus_next.size = pkg_ram::RAM_BYTE;
		end
	    default:
		;
	endcase
    end

    //
    // io instructions (putc and getc)
    //
    if_instr_io instr_io_next();

    always_ff @ (posedge clk) begin
	if (en) begin
	    instr_io.op <= instr_io_next.op;
	    instr_io.char_imm <= instr_io_next.char_imm;
	    instr_io.char_reg <= instr_io_next.char_reg;
	end
    end

    always_comb begin
	instr_io_next.char_imm = ir[23:16];
	instr_io_next.char_reg = ir[23:20];

	instr_io_next.op = pkg_io::IO_NOP;

	case (op)
	    8'h30: // putc %X
		instr_io_next.op = pkg_io::IO_PUTC_REG;
	    8'h31: // putc X
		instr_io_next.op = pkg_io::IO_PUTC_IMM;
	    default:
	    ;
	endcase
    end

endmodule
