`include "pkg_ram.sv"
import pkg_ram::data_type_t;
import pkg_ram::RAM_LONG;
import pkg_ram::RAM_WORD;
import pkg_ram::RAM_BYTE;

/*
 * Zero extend low bytes in data_in
 */

module long_we_mask (
    input data_type_t data_type,
    input logic [1:0] offset,
    input logic store,
    output logic [3:0] we0,
    output logic [3:0] we1
);


    always_comb begin
	{we0, we1} = 8'h00;
	if (store) begin
	    case ({data_type, offset})
		default:
		// = {RAM_LONG, 2'b00} (otherwise bus error)
		    {we0, we1} = 8'hFF;
		{RAM_WORD, 2'b00}: {we0, we1} = 8'hF0;
		{RAM_WORD, 2'b10}: {we0, we1} = 8'h0F;
		{RAM_BYTE, 2'b00}: {we0, we1} = 8'hC0;
		{RAM_BYTE, 2'b01}: {we0, we1} = 8'h30;
		{RAM_BYTE, 2'b10}: {we0, we1} = 8'h0C;
		{RAM_BYTE, 2'b11}: {we0, we1} = 8'h03;
	    endcase
	    /*
	    if (data_type == RAM_LONG) begin
		{we0, we1} = 8'hFF;
	    end
	    else if (data_type == RAM_WORD) begin
		case (offset)
		    2'b00: {we0, we1} = 8'hF0;
		    2'b10: {we0, we1} = 8'h0F;
		    default: ;
		endcase
	    end
	    else if (data_type == RAM_BYTE) begin
		case (offset)
		    2'b00: {we0, we1} = 8'hC0;
		    2'b01: {we0, we1} = 8'h30;
		    2'b10: {we0, we1} = 8'h0C;
		    2'b11: {we0, we1} = 8'h03;
		endcase
	    end
	    */
	end
    end

endmodule
