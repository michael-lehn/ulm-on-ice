`include "pkg_alu.sv"
`include "pkg_bus.sv"
`include "pkg_cu.sv"
`include "pkg_io.sv"
`include "pkg_ram.sv"

module dev_cu (
    input logic clk,
    input logic en,
    input logic rst,

    // devices
    if_ram.client ram,
    if_reg_file.client reg_file,
    if_io.client io,
    if_alu.client alu,
    output logic halted,
    output logic [pkg_ram::RAM_BYTE_SIZE-1:0] exit_code
);

    pkg_cu::state_t cu_state = pkg_cu::CU_FETCH;
    pkg_cu::state_t cu_state_next;
    logic [31:0] cu_ir;

    assign halted = cu_state == pkg_cu::CU_HALTED;

    //
    // Interface to current instruction
    //
    if_instr_alu instr_alu();
    if_instr_bus instr_bus();
    if_instr_cu instr_cu();
    if_instr_io instr_io();

    //
    // von Neumann cycle
    //
    always_ff @ (posedge clk) begin
	if (rst) begin
	    cu_state <= pkg_cu::CU_FETCH;
	end
	else if (en) begin
	    cu_state <= cu_state_next;
	end
    end

    always_comb begin
	cu_state_next = cu_state;

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
		if (instr_io.op != pkg_io::IO_GETC_REG || io.getc_en) begin
		    cu_state_next = pkg_cu::CU_INCREMENT;
		end
	    pkg_cu::CU_INCREMENT:
		begin
		    cu_state_next = pkg_cu::CU_FETCH;
		end
	endcase
    end

    //
    // instructions and data share the same RAM
    //
    logic ram_sel;
    if_ram ram_cu();	    // used to fetch instructions
    if_ram ram_data();	    // used to fetch/store data

    dev_ram_switch dev_ram_switch0(
	.select(ram_sel),
	.ram0(ram_cu.server),
	.ram1(ram_data.server),
	.ram(ram)
    );

    always_comb begin
	case (cu_state)
	    pkg_cu::CU_FETCH, pkg_cu::CU_DECODE:
		ram_sel = 0;
	    default:
		ram_sel = 1;
	endcase
    end

    //
    // Define how control unit accesses RAM
    //
    always_comb begin
	ram_cu.addr = cu_ip;
	ram_cu.data_type = pkg_ram::RAM_LONG;
	ram_cu.data_in = 0;
	cu_ir = ram_cu.data_out[31:0];
	ram_cu.op = pkg_ram::RAM_FETCH;
    end

    //
    // decode instructions into instructions
    //
    logic decoder_en;

    always_comb begin
	decoder_en = en && (cu_state == pkg_cu::CU_DECODE);
    end
    
    dev_decoder dev_decoder0(
	.clk(clk),
	.rst(rst),
	.en(decoder_en),
	.ir(cu_ir),
	.alu(alu.observer),
	.instr_alu(instr_alu.client),
	.instr_bus(instr_bus.client),
	.instr_cu(instr_cu.client),
	.instr_io(instr_io.client)
    );

    //
    // control cu instructions (jump and halt)
    //
    logic [pkg_ram::RAM_ADDRW-1:0] cu_ip = 0;
    logic [pkg_ram::RAM_ADDRW-1:0] cu_ip_next, cu_ip_ret;

    always_comb begin
	exit_code = 8'hff;
	if (instr_cu.op == pkg_cu::CU_HALT_IMM) begin
	    exit_code = instr_cu.exit_code_imm;
	end
	else if (instr_cu.op == pkg_cu::CU_HALT_REG) begin
	    exit_code = reg_file.data_out0[pkg_ram::RAM_BYTE_SIZE-1:0];
	end
    end

    always_ff @ (posedge clk) begin
	if (rst || cu_state == pkg_cu::CU_HALTED) begin
	    cu_ip <= 0;
	end
	else if (en && cu_state == pkg_cu::CU_INCREMENT) begin
	    cu_ip <= cu_ip_next;
	end
    end

    always_comb begin
	cu_ip_ret = cu_ip + 4;
	cu_ip_next = cu_ip + 4;
	if (cu_state == pkg_cu::CU_INCREMENT) begin
	    case (instr_cu.op)
		pkg_cu::CU_REL_JMP:
		    cu_ip_next
			= cu_ip
			+ instr_cu.jmp_offset[pkg_ram::RAM_ADDRW-1:0];
		pkg_cu::CU_ABS_JMP:
		    cu_ip_next = reg_file.data_out0[pkg_ram::RAM_ADDRW-1:0];
		default:
		    ;
	    endcase
	end
    end

    //
    // control IO instructions
    //
    always_comb begin
	io.putc_push = 0;
	io.putc_char = 0;
	io.getc_pop = 0;

	case ({cu_state == pkg_cu::CU_INCREMENT, instr_io.op})
	    {1'b1, pkg_io::IO_PUTC_REG}:
		begin
		    io.putc_push = 1;
		    io.putc_char
			= reg_file.data_out0[pkg_ram::RAM_BYTE_SIZE-1:0];
		end
	    {1'b1, pkg_io::IO_PUTC_IMM}:
		begin
		    io.putc_push = 1;
		    io.putc_char = instr_io.char_imm;
		end
	    {1'b1, pkg_io::IO_GETC_REG}:
		begin
		    io.getc_pop = 1;
		end
	    default:
		;
	endcase
    end

    //
    // control register file operations
    //
    always_comb begin
	// defaults are for ALU instructions
	reg_file.addr_out0 = instr_alu.a_reg;
	reg_file.addr_out1 = instr_alu.b_reg;
	reg_file.addr_in = instr_alu.s_reg;
	reg_file.data_in = alu.s;
	reg_file.op = en && cu_state == pkg_cu::CU_INCREMENT
	    ? pkg_reg::REG_WRITE
	    : pkg_reg::REG_READ_ONLY;

	if (instr_io.op == pkg_io::IO_PUTC_REG) begin
	    reg_file.op = pkg_reg::REG_READ_ONLY;
	    reg_file.addr_out0 = instr_io.char_reg;
	    reg_file.addr_out1 = 0;
	    reg_file.addr_in = 0;
	    reg_file.data_in = 0;
	end
	else if (instr_io.op == pkg_io::IO_GETC_REG) begin
	    reg_file.addr_out0 = 0;
	    reg_file.addr_out1 = 0;
	    reg_file.addr_in = instr_io.char_reg;
	    reg_file.data_in = {
		{pkg_ram::RAM_QUAD_SIZE - pkg_ram::RAM_BYTE_SIZE{1'b0}},
		io.getc_char
	    };
	end
	else if (instr_cu.op == pkg_cu::CU_HALT_REG) begin
	    reg_file.op = pkg_reg::REG_READ_ONLY;
	    reg_file.addr_out0 = instr_cu.cu_reg0;
	    reg_file.addr_out1 = 0;
	    reg_file.addr_in = 0;
	    reg_file.data_in = 0;
	end
	else if (instr_cu.op == pkg_cu::CU_ABS_JMP) begin
	    reg_file.addr_out0 = instr_cu.cu_reg0;
	    reg_file.addr_out1 = 0;
	    reg_file.addr_in = instr_cu.cu_reg1;
	    reg_file.data_in = {
		{pkg_ram::RAM_QUAD_SIZE - pkg_ram::RAM_ADDRW{1'b0}},
		cu_ip_ret
	    };
	end
	else if (instr_bus.op == pkg_bus::BUS_FETCH) begin
	    reg_file.addr_out0 = instr_bus.addr_reg;
	    reg_file.addr_out1 = 0;
	    reg_file.addr_in = instr_bus.data_reg;
	    reg_file.data_in = ram.data_out;
	end
	else if (instr_bus.op == pkg_bus::BUS_STORE) begin
	    reg_file.addr_out0 = instr_bus.addr_reg;
	    reg_file.addr_out1 = instr_bus.data_reg;
	    reg_file.addr_in = 0;
	    reg_file.data_in = 0;
	end
    end

    //
    // control ALU operations
    //
    always_comb begin
	alu.a = instr_alu.a_sel == pkg_alu::ALU_REG
	    ? reg_file.data_out0
	    : instr_alu.a_imm;
	alu.b = reg_file.data_out1;

	if (cu_state == pkg_cu::CU_EXECUTE) begin
	    alu.op = instr_alu.op;
	end
	else begin
	    alu.op = pkg_alu::ALU_NOP;
	end
    end

    //
    // control ram operations
    //
    always_comb begin
	ram_data.data_type = instr_bus.data_type;
	ram_data.addr
	    = reg_file.data_out0[pkg_ram::RAM_ADDRW-1:0]
	    + instr_bus.addr_offset;
	ram_data.op = pkg_ram::RAM_NOP;
	ram_data.data_in = 0;

	if (en && cu_state == pkg_cu::CU_EXECUTE) begin
	    case (instr_bus.op)
		pkg_bus::BUS_FETCH:
		    begin
			ram_data.op = pkg_ram::RAM_FETCH;
		    end
		pkg_bus::BUS_STORE:
		    begin
			ram_data.data_in = reg_file.data_out1;
			ram_data.op = pkg_ram::RAM_STORE;
		    end
		default:
		    ;
	    endcase
	end
    end


endmodule
