`include "pkg_ram.sv"
import pkg_ram::RAM_QUAD_SIZE;
import pkg_ram::RAM_LONG;
import pkg_ram::RAM_WORD;
import pkg_ram::RAM_BYTE;

module quad_lshift (
    input logic [RAM_QUAD_SIZE-1:0] data_in,
    input logic [2:0] offset,
    output logic [RAM_QUAD_SIZE-1:0] data_out
);

    always_comb begin
	//data_out = data_in << {offset, 3'b000};
	case (offset)
	    default:
		data_out = data_in;
	    /*
	    3'b001: data_out = data_in << 8;
	    3'b010: data_out = data_in << 16;
	    3'b011: data_out = data_in << 24;
	    3'b100: data_out = data_in << 32;
	    3'b101: data_out = data_in << 40;
	    3'b110: data_out = data_in << 48;
	    3'b111: data_out = data_in << 56;
	    */
	endcase
    end

endmodule
