`include "pkg_ram.sv"
import pkg_ram::RAM_LONG_SIZE;
import pkg_ram::RAM_WORD;
import pkg_ram::RAM_BYTE;

module long_lshift (
    input logic [RAM_LONG_SIZE-1:0] data_in,
    input logic [1:0] offset,
    output logic [RAM_LONG_SIZE-1:0] data_out
);

    always_comb begin
	//data_out = data_in << {offset, 3'b000};
	case (offset)
	    default:
		data_out = data_in;
	    2'b01: data_out = data_in << 8;
	    2'b10: data_out = data_in << 16;
	    2'b11: data_out = data_in << 24;
	endcase
    end

endmodule
