`include "pkg_ram.sv"

module dev_ram #(
    localparam SB_ADDRW = 14,
    localparam SB_WIDTH = 16
) (
    input logic clk,
    input if_dev_ram ram
);

    logic write;
    assign write = ram.op == pkg_ram::RAM_STORE;

    logic [SB_ADDRW-1:0] sb_addr;
    logic [2:0] sb_addr_offset;

    always_comb begin
	sb_addr = ram.addr[pkg_ram::RAM_ADDRW-1:3];
	sb_addr_offset = ram.addr[2:0];
    end

    // used to address the single blocks (sb) of the single port RAM (spram)
    logic [3:0] sb_we00, sb_we01, sb_we10, sb_we11;
    logic [SB_WIDTH-1:0] sb_data_in00, sb_data_in01,
	sb_data_in10, sb_data_in11;
    logic [SB_WIDTH-1:0] sb_data_out00, sb_data_out01,
	sb_data_out10, sb_data_out11;

   
    always_comb begin
	case ({ram.size, sb_addr_offset})
	    //
	    // quad word (1 case)
	    //
	    {pkg_ram::RAM_QUAD,3'b000}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = ram.data_in;

		    ram.data_out = {
			sb_data_out00, sb_data_out01,
			sb_data_out10, sb_data_out11
		    };

		    {
			sb_we00,
			sb_we01,
			sb_we10,
			sb_we11
		    } = write ? 16'hFFFF : 16'h000;
		end

	    //
	    // long word (2 cases)
	    //
	    {pkg_ram::RAM_LONG,3'b000}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			ram.data_in[pkg_ram::RAM_LONG-1:0],
			{pkg_ram::RAM_LONG{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_LONG{1'b0}},
			sb_data_out00, sb_data_out01
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'hFF00 : 16'h000;
		end

	    {pkg_ram::RAM_LONG,3'b100}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			{pkg_ram::RAM_LONG{1'b0}},
			ram.data_in[pkg_ram::RAM_LONG-1:0]
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_LONG{1'b0}},
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
	    {pkg_ram::RAM_WORD,3'b000}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			ram.data_in[pkg_ram::RAM_WORD-1:0],
			{pkg_ram::RAM_WORD{1'b0}},
			{pkg_ram::RAM_WORD{1'b0}},
			{pkg_ram::RAM_WORD{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_WORD{1'b0}},
			sb_data_out00
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'hF000 : 16'h000;
		end

	    {pkg_ram::RAM_WORD,3'b010}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			{pkg_ram::RAM_WORD{1'b0}},
			ram.data_in[pkg_ram::RAM_WORD-1:0],
			{pkg_ram::RAM_WORD{1'b0}},
			{pkg_ram::RAM_WORD{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_WORD{1'b0}},
			sb_data_out01
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0F00 : 16'h000;
		end

	    {pkg_ram::RAM_WORD,3'b100}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_WORD{1'b0}},
			{pkg_ram::RAM_WORD{1'b0}},
			ram.data_in[pkg_ram::RAM_WORD-1:0],
			{pkg_ram::RAM_WORD{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_WORD{1'b0}},
			sb_data_out10
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h00F0 : 16'h000;
		end

	    {pkg_ram::RAM_WORD,3'b110}:
		begin
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {
			{pkg_ram::RAM_WORD{1'b0}},
			{pkg_ram::RAM_WORD{1'b0}},
			{pkg_ram::RAM_WORD{1'b0}},
			ram.data_in[pkg_ram::RAM_WORD-1:0]
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_WORD{1'b0}},
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
	    {pkg_ram::RAM_BYTE,3'b000}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			ram.data_in[pkg_ram::RAM_BYTE-1:0],
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out00[pkg_ram::RAM_WORD-1:pkg_ram::RAM_BYTE]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'hC000 : 16'h000;
		end

	    {pkg_ram::RAM_BYTE,3'b001}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_BYTE{1'b0}},
			ram.data_in[pkg_ram::RAM_BYTE-1:0],
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out00[pkg_ram::RAM_BYTE-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h3000 : 16'h000;
		end

	    {pkg_ram::RAM_BYTE,3'b010}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			ram.data_in[pkg_ram::RAM_BYTE-1:0],
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out01[pkg_ram::RAM_WORD-1:pkg_ram::RAM_BYTE]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0C00 : 16'h000;
		end

	    {pkg_ram::RAM_BYTE,3'b011}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			ram.data_in[pkg_ram::RAM_BYTE-1:0],
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out01[pkg_ram::RAM_BYTE-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0300 : 16'h000;
		end

	    {pkg_ram::RAM_BYTE,3'b100}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			ram.data_in[pkg_ram::RAM_BYTE-1:0],
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out10[pkg_ram::RAM_WORD-1:pkg_ram::RAM_BYTE]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h00C0 : 16'h000;
		end

	    {pkg_ram::RAM_BYTE,3'b101}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			ram.data_in[pkg_ram::RAM_BYTE-1:0],
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out10[pkg_ram::RAM_BYTE-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0030 : 16'h000;
		end

	    {pkg_ram::RAM_BYTE,3'b110}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			ram.data_in[pkg_ram::RAM_BYTE-1:0],
			{pkg_ram::RAM_BYTE{1'b0}}
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out11[pkg_ram::RAM_WORD-1:pkg_ram::RAM_BYTE]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h000C : 16'h000;
		end

	    {pkg_ram::RAM_BYTE,3'b111}:
		begin
		    {
			sb_data_in00,
			sb_data_in01,
			sb_data_in10,
			sb_data_in11
		    } = {
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			{pkg_ram::RAM_BYTE{1'b0}},
			ram.data_in[pkg_ram::RAM_BYTE-1:0]
		    };

		    ram.data_out = {
			{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
			sb_data_out11[pkg_ram::RAM_BYTE-1:0]
		    };

		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = write ? 16'h0003 : 16'h000;
		end

	    default:
		begin
		    ram.data_out = {pkg_ram::RAM_QUAD{1'b0}};
		    {
			sb_we00, sb_we01,
			sb_we10, sb_we11
		    } = 16'h0000;
		    {
			sb_data_in00, sb_data_in01,
			sb_data_in10, sb_data_in11
		    } = {pkg_ram::RAM_QUAD{1'b0}};
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
