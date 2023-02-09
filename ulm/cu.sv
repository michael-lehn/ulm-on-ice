`include "pkg_alu.sv"
`include "pkg_bus.sv"
`include "pkg_cu.sv"
`include "pkg_io.sv"
`include "pkg_ram.sv"
`include "pkg_reg.sv"

module cu (
    input logic clk,
    input logic en,

    // devices
    output if_dev_ram dev_ram,
    output if_dev_reg_file dev_reg_file,
    output if_dev_alu dev_alu,
    output logic putc,
    output logic [pkg_ram::RAM_BYTE-1:0] putc_char,
    output logic halted,
    output logic [pkg_ram::RAM_BYTE-1:0] exit_code,
    output tx_req
);
    pkg_cu::state_t cu_state = pkg_cu::CU_FETCH;
    pkg_cu::state_t cu_state_next;
    logic [31:0] cu_ir = 0;

    assign halted = cu_state == pkg_cu::CU_HALTED;
    assign tx_req = en
		  && (cu_state == pkg_cu::CU_INCREMENT
		   || cu_state == pkg_cu::CU_FETCH);

    //
    // Interface to current instruction
    //
    if_instr_cu instr_cu();
    if_instr_io instr_io();
    if_instr_alu instr_alu();
    if_instr_bus instr_bus();

    //
    // von Neumann cycle
    //
    always_ff @ (posedge clk) begin
	cu_state <= cu_state_next;
    end

    always_comb begin
	cu_state_next = cu_state;

	if (en) begin
	    case (cu_state)
		pkg_cu::CU_FETCH:
		    begin
			if (instr_cu.op == pkg_cu::CU_HALT_IMM
			 || instr_cu.op == pkg_cu::CU_HALT_REG)
			begin
			    cu_state_next = pkg_cu::CU_HALTED;
			end
			else begin
			    cu_state_next = pkg_cu::CU_DECODE;
			end
		    end
		pkg_cu::CU_DECODE:
		    begin
			cu_state_next = pkg_cu::CU_LOAD_OPERANDS;
		    end
		pkg_cu::CU_LOAD_OPERANDS:
		    begin
			cu_state_next = pkg_cu::CU_EXECUTE;
		    end
		pkg_cu::CU_EXECUTE:
		    begin
			cu_state_next = pkg_cu::CU_INCREMENT;
		    end
		pkg_cu::CU_INCREMENT:
		    begin
			cu_state_next = pkg_cu::CU_FETCH;
		    end
	    endcase
	end
    end

    //
    // Define how control unit accesses RAM
    //
    if_dev_ram cu_ram();

    always_comb begin
	cu_ram.addr = cu_ip;
	cu_ram.size = pkg_ram::RAM_LONG;;
	cu_ram.data_in = 0;
	cu_ir = cu_ram.data_out[31:0];
	cu_ram.op = pkg_ram::RAM_FETCH;
    end

    //
    // instructions and data share the same RAM
    //
    if_dev_ram instr_ram();

    always_comb begin
	cu_ram.data_out = dev_ram.data_out;
	instr_ram.data_out = dev_ram.data_out;

	case (cu_state)
	     pkg_cu::CU_FETCH, pkg_cu::CU_DECODE:
		begin
		    dev_ram.addr = cu_ip;
		    dev_ram.op = cu_ram.op;
		    dev_ram.size = cu_ram.size;
		    dev_ram.data_in = cu_ram.data_in;
		end
	    default:
		begin
		    dev_ram.addr = instr_ram.addr;
		    dev_ram.op = instr_ram.op;
		    dev_ram.size = instr_ram.size;
		    dev_ram.data_in = instr_ram.data_in;
		end
	endcase
    end

    //
    // decode instructions into instructions
    //
    logic decoder_en;

    always_comb begin
	decoder_en = en && (cu_state == pkg_cu::CU_DECODE);
    end
    
    decoder decoder0(
	.clk(clk),
	.en(decoder_en),
	.ir(cu_ir),
	.stat_reg_zf(dev_alu.stat_reg_zf),
	.instr_cu(instr_cu),
	.instr_io(instr_io),
	.instr_alu(instr_alu),
	.instr_bus(instr_bus)
    );

    //
    // control cu instructions (jump and halt)
    //
    logic [pkg_ram::RAM_ADDRW-1:0] cu_ip = 0;
    logic [pkg_ram::RAM_ADDRW-1:0] cu_ip_next;

    always_comb begin
	exit_code = 8'hff;
	if (instr_cu.op == pkg_cu::CU_HALT_IMM) begin
	    exit_code = instr_cu.exit_code_imm;
	end
	else if (instr_cu.op == pkg_cu::CU_HALT_REG) begin
	    exit_code = dev_reg_file.data_out0[pkg_ram::RAM_BYTE-1:0];
	end
    end


    always_ff @ (posedge clk) begin
	if (en && cu_state == pkg_cu::CU_INCREMENT) begin
	    cu_ip <= cu_ip_next;
	end
    end

    always_comb begin
	cu_ip_next = cu_ip + 4;

	case (instr_cu.op)
	    pkg_cu::CU_REL_JMP:
		cu_ip_next = cu_ip
			   + 4 * instr_cu.jmp_offset[pkg_ram::RAM_ADDRW-1:0];
	    default:
		;
	endcase
    end

    //
    // control ram operations
    //
    always_comb begin
	instr_ram.size = instr_bus.size;
	instr_ram.addr = dev_reg_file.data_out0[pkg_ram::RAM_ADDRW-1:0]
		       + instr_bus.addr_offset;
	instr_ram.data_in = 0;
	instr_ram.op = pkg_ram::RAM_NOP;

	case (instr_bus.op)
	    pkg_bus::BUS_FETCH:
		instr_ram.op = pkg_ram::RAM_FETCH;
	    default:
		;
	endcase
    end

    //
    // control register file operations
    //
    always_comb begin
	// defaults are for ALU instructions
	dev_reg_file.addr_out0 = instr_alu.a_reg;
	dev_reg_file.addr_out1 = instr_alu.b_reg;
	dev_reg_file.addr_in = instr_alu.s_reg;
	dev_reg_file.data_in = dev_alu.s;
	dev_reg_file.op = en && cu_state == pkg_cu::CU_INCREMENT
			? pkg_reg::REG_WRITE
			: pkg_reg::REG_READ_ONLY;

	if (instr_bus.op == pkg_bus::BUS_FETCH) begin
	    dev_reg_file.addr_out0 = instr_bus.addr_reg;
	    dev_reg_file.addr_out1 = 0;
	    dev_reg_file.addr_in = instr_bus.data_reg;
	    dev_reg_file.data_in = dev_ram.data_out;
	end
	else if (instr_io.op == pkg_io::IO_PUTC_REG) begin
	    dev_reg_file.op = pkg_reg::REG_READ_ONLY;
	    dev_reg_file.addr_out0 = instr_io.char_reg;
	    dev_reg_file.addr_out1 = 0;
	    dev_reg_file.addr_in = 0;
	    dev_reg_file.data_in = 0;
	end
	else if (instr_cu.op == pkg_cu::CU_HALT_REG) begin
	    dev_reg_file.op = pkg_reg::REG_READ_ONLY;
	    dev_reg_file.addr_out0 = instr_io.char_reg;
	    dev_reg_file.addr_out1 = 0;
	    dev_reg_file.addr_in = 0;
	    dev_reg_file.data_in = 0;
	end
    end

    //
    // control ALU operations
    //
    always_comb begin
	dev_alu.a = instr_alu.a_sel == pkg_alu::ALU_REG
		  ? dev_reg_file.data_out0
		  : instr_alu.a_imm;
	dev_alu.b = dev_reg_file.data_out1;

	if (cu_state == pkg_cu::CU_EXECUTE) begin
	    dev_alu.op = instr_alu.op;
	end
	else begin
	    dev_alu.op = pkg_alu::ALU_NOP;
	end
    end

    //
    // control IO operations
    //
    always_comb begin
	putc = 0;
	putc_char = instr_io.char_imm;

	case ({cu_state == pkg_cu::CU_INCREMENT, instr_io.op})
	    {1'b1, pkg_io::IO_PUTC_REG}:
		begin
		    putc = 1;
		    putc_char = dev_reg_file.data_out0[pkg_ram::RAM_BYTE-1:0];
		end
	    {1'b1, pkg_io::IO_PUTC_IMM}:
		begin
		    putc = 1;
		end
	    default:
		;
	endcase
    end

endmodule
