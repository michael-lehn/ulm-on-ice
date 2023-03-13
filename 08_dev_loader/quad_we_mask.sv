`include "pkg_ram.sv"
import pkg_ram::data_type_t;
import pkg_ram::RAM_QUAD;
import pkg_ram::RAM_LONG;
import pkg_ram::RAM_WORD;
import pkg_ram::RAM_BYTE;

/*
 * Zero extend low bytes in data_in
 */

module quad_we_mask (
    input data_type_t data_type,
    input logic [2:0] offset,
    input logic store,
    output logic [3:0] we00,
    output logic [3:0] we01,
    output logic [3:0] we10,
    output logic [3:0] we11
);


    always_comb begin
	{we00, we01, we10, we11} = 16'h0000;
	if (store) begin
	    if (data_type == RAM_QUAD)
		{we00, we01, we10, we11} = 16'hFFFF;
	    else if (data_type == RAM_LONG)
		case (offset)
		    3'b000: {we00, we01, we10, we11} = 16'hFF00;
		    3'b100: {we00, we01, we10, we11} = 16'h00FF;
		    default: ;
		endcase
	    else if (data_type == RAM_WORD)
		case (offset)
		    3'b000: {we00, we01, we10, we11} = 16'hF000;
		    3'b010: {we00, we01, we10, we11} = 16'h0F00;
		    3'b100: {we00, we01, we10, we11} = 16'h00F0;
		    3'b110: {we00, we01, we10, we11} = 16'h000F;
		    default: ;
		endcase
	    else if (data_type == RAM_BYTE)
		case (offset)
		    3'b000: {we00, we01, we10, we11} = 16'hC000;
		    3'b001: {we00, we01, we10, we11} = 16'h3000;
		    3'b010: {we00, we01, we10, we11} = 16'h0C00;
		    3'b011: {we00, we01, we10, we11} = 16'h0300;
		    3'b100: {we00, we01, we10, we11} = 16'h00C0;
		    3'b101: {we00, we01, we10, we11} = 16'h0030;
		    3'b110: {we00, we01, we10, we11} = 16'h000C;
		    3'b111: {we00, we01, we10, we11} = 16'h0003;
		endcase
	end
    end

endmodule
