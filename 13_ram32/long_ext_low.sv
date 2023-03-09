`include "pkg_ram.sv"
import pkg_ram::data_type_t;
import pkg_ram::RAM_LONG_SIZE;
import pkg_ram::RAM_WORD_SIZE;
import pkg_ram::RAM_BYTE_SIZE;
import pkg_ram::RAM_WORD;
import pkg_ram::RAM_BYTE;

/*
 * Zero extend low bytes in data_in
 */

module long_ext_low (
    input logic [RAM_LONG_SIZE-1:0] data_in,
    input data_type_t data_type,
    output logic [RAM_LONG_SIZE-1:0] data_out
);

    always_comb begin
	case (data_type)
	    default:
		data_out = data_in;
	    RAM_WORD:
		data_out = {
		    data_in[RAM_WORD_SIZE-1:0],
		    {RAM_LONG_SIZE-RAM_WORD_SIZE{1'b0}}
		};
	    RAM_BYTE:
		data_out = {
		    data_in[RAM_BYTE_SIZE-1:0],
		    {RAM_LONG_SIZE-RAM_BYTE_SIZE{1'b0}}
		};
	endcase
    end

endmodule
