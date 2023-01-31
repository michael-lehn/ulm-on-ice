`include "../ram/ram_pkg.sv"

module ram #(
    localparam SB_ADDRW = 14,
    localparam SB_WIDTH = 16,
    // localparam SB_COUNT = 4,

    localparam ADDRW = 17,
    localparam BYTE_WIDTH = 8,
    localparam WORD_WIDTH = 2 * BYTE_WIDTH,	// 16
    localparam LONG_WIDTH = 2 * WORD_WIDTH,	// 32
    localparam QUAD_WIDTH = 2 * LONG_WIDTH	// 64
) (
    input logic clk,
    /* verilator lint_off UNUSEDSIGNAL */
    input logic [ADDRW-1:0] addr,
    /* verilator lint_on UNUSEDSIGNAL */
    input ram_pkg::ram_op_t op,
    input ram_pkg::ram_size_t size,
    input logic [QUAD_WIDTH-1:0] data_in,
    output logic [QUAD_WIDTH-1:0] data_out
);

    logic write;
    assign write = op == ram_pkg::RAM_STORE;

    logic [SB_ADDRW-1:0] sb_addr, sb_addr_r;
    logic [2:0] sb_addr_offset, sb_addr_offset_r;

    always_comb begin
	sb_addr = op != ram_pkg::RAM_NOP ? addr[ADDRW-1:3]
					 : sb_addr_r;
	sb_addr_offset = op != ram_pkg::RAM_NOP ? addr[2:0]
						: sb_addr_offset_r;
    end

    always_ff @ (posedge clk) begin
	if (op != ram_pkg::RAM_NOP) begin
	    sb_addr_r <= sb_addr;
	    sb_addr_offset_r <= sb_addr_offset;
	end
    end

    // used to address the single blocks (sb) of the single port RAM (spram)
    logic [3:0] sb_we00, sb_we01, sb_we10, sb_we11;
    logic [SB_WIDTH-1:0] sb_data_in00, sb_data_in01,
	sb_data_in10, sb_data_in11;
    logic [SB_WIDTH-1:0] sb_data_out00, sb_data_out01,
	sb_data_out10, sb_data_out11;

   
    always_comb begin
	case ({size, sb_addr_offset})
	    //
	    // quad word (1 case)
	    //
	    {ram_pkg::RAM_QUAD,3'b000}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = data_in;

		    data_out = {
			sb_data_out00, sb_data_out01,
			sb_data_out10, sb_data_out11
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'hFFFF : 16'h000;
		end

	    //
	    // long word (2 cases)
	    //
	    {ram_pkg::RAM_LONG,3'b000}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			data_in[LONG_WIDTH-1:0],
			{LONG_WIDTH{1'b0}}
		    };

		    data_out = {
			{LONG_WIDTH{1'b0}},
			sb_data_out00, sb_data_out01
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'hFF00 : 16'h000;
		end

	    {ram_pkg::RAM_LONG,3'b100}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			{LONG_WIDTH{1'b0}},
			data_in[LONG_WIDTH-1:0]
		    };

		    data_out = {
			{LONG_WIDTH{1'b0}},
			sb_data_out10, sb_data_out11
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h00FF : 16'h000;
		end

	    //
	    // word (4 cases)
	    //
	    {ram_pkg::RAM_WORD,3'b000}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			data_in[WORD_WIDTH-1:0], {WORD_WIDTH{1'b0}},
			{WORD_WIDTH{1'b0}}, {WORD_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - WORD_WIDTH{1'b0}},
			sb_data_out00
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'hF000 : 16'h000;
		end

	    {ram_pkg::RAM_WORD,3'b010}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			{WORD_WIDTH{1'b0}}, data_in[WORD_WIDTH-1:0],
			{WORD_WIDTH{1'b0}}, {WORD_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - WORD_WIDTH{1'b0}},
			sb_data_out01
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0F00 : 16'h000;
		end

	    {ram_pkg::RAM_WORD,3'b100}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			{WORD_WIDTH{1'b0}}, {WORD_WIDTH{1'b0}},
			data_in[WORD_WIDTH-1:0], {WORD_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - WORD_WIDTH{1'b0}},
			sb_data_out10
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h00F0 : 16'h000;
		end

	    {ram_pkg::RAM_WORD,3'b110}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			{WORD_WIDTH{1'b0}}, {WORD_WIDTH{1'b0}},
			{WORD_WIDTH{1'b0}}, data_in[WORD_WIDTH-1:0]
		    };

		    data_out = {
			{QUAD_WIDTH - WORD_WIDTH{1'b0}},
			sb_data_out11
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h000F : 16'h000;
		end

	    //
	    // byte (8 cases)
	    //
	    {ram_pkg::RAM_BYTE,3'b000}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			data_in[BYTE_WIDTH-1:0], {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out00[BYTE_WIDTH-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'hC000 : 16'h000;
		end

	    {ram_pkg::RAM_BYTE,3'b001}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{BYTE_WIDTH{1'b0}}, data_in[BYTE_WIDTH-1:0],
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out00[WORD_WIDTH-1:BYTE_WIDTH]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h3000 : 16'h000;
		end

	    {ram_pkg::RAM_BYTE,3'b010}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			data_in[BYTE_WIDTH-1:0], {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out01[BYTE_WIDTH-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0C00 : 16'h000;
		end

	    {ram_pkg::RAM_BYTE,3'b011}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, data_in[BYTE_WIDTH-1:0],
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out01[WORD_WIDTH-1:BYTE_WIDTH]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0300 : 16'h000;
		end

	    {ram_pkg::RAM_BYTE,3'b100}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			data_in[BYTE_WIDTH-1:0], {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out10[BYTE_WIDTH-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h00C0 : 16'h000;
		end

	    {ram_pkg::RAM_BYTE,3'b101}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, data_in[BYTE_WIDTH-1:0],
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out10[WORD_WIDTH-1:BYTE_WIDTH]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0030 : 16'h000;
		end

	    {ram_pkg::RAM_BYTE,3'b110}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			data_in[BYTE_WIDTH-1:0], {BYTE_WIDTH{1'b0}}
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out11[BYTE_WIDTH-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h000C : 16'h000;
		end

	    {ram_pkg::RAM_BYTE,3'b111}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, {BYTE_WIDTH{1'b0}},
			{BYTE_WIDTH{1'b0}}, data_in[BYTE_WIDTH-1:0]
		    };

		    data_out = {
			{QUAD_WIDTH - BYTE_WIDTH{1'b0}},
			sb_data_out11[WORD_WIDTH-1:BYTE_WIDTH]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0003 : 16'h000;
		end




	    default:
		begin
		    data_out = {QUAD_WIDTH{1'b0}};
		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = 16'h0000;
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {QUAD_WIDTH{1'b0}};
		end
	endcase
    end

    spram sb_inst00(
        .clk(clk),
        .we(sb_we00),
        .addr(sb_addr),
        .data_in(sb_data_in00),
        .data_out(sb_data_out00)
    );
    spram sb_inst01(
        .clk(clk),
        .we(sb_we01),
        .addr(sb_addr),
        .data_in(sb_data_in01),
        .data_out(sb_data_out01)
    );
     spram sb_inst10(
        .clk(clk),
        .we(sb_we10),
        .addr(sb_addr),
        .data_in(sb_data_in10),
        .data_out(sb_data_out10)
    );
     spram sb_inst11(
        .clk(clk),
        .we(sb_we11),
        .addr(sb_addr),
        .data_in(sb_data_in11),
        .data_out(sb_data_out11)
    );
     
endmodule
