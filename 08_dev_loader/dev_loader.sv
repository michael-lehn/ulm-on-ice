`include "pkg_ram.sv"

module dev_loader (
    input logic clk,
    input logic rst,
    if_io.client io,
    if_ram.client ram,
    output logic done,
    // for debugging: value and state of current byte
    output logic [pkg_ram::RAM_BYTE_SIZE-1:0] byte_val,
    output logic byte_valid
);

    //
    // hex_char: indicates whether io.getc_char is a hex character
    // nibble_val: hex value represented by io.getc_char
    //
    logic hex_char;
    logic [pkg_ram::RAM_NIBBLE_SIZE-1:0] nibble_val;

    always_comb begin
	{hex_char, nibble_val} = {1'b0, 4'h0};
	case (io.getc_char)
	    "0": {hex_char, nibble_val} = {1'b1, 4'h0};
	    "1": {hex_char, nibble_val} = {1'b1, 4'h1};
	    "2": {hex_char, nibble_val} = {1'b1, 4'h2};
	    "3": {hex_char, nibble_val} = {1'b1, 4'h3};
	    "4": {hex_char, nibble_val} = {1'b1, 4'h4};
	    "5": {hex_char, nibble_val} = {1'b1, 4'h5};
	    "6": {hex_char, nibble_val} = {1'b1, 4'h6};
	    "7": {hex_char, nibble_val} = {1'b1, 4'h7};
	    "8": {hex_char, nibble_val} = {1'b1, 4'h8};
	    "9": {hex_char, nibble_val} = {1'b1, 4'h9};
	    "A": {hex_char, nibble_val} = {1'b1, 4'hA};
	    "B": {hex_char, nibble_val} = {1'b1, 4'hB};
	    "C": {hex_char, nibble_val} = {1'b1, 4'hC};
	    "D": {hex_char, nibble_val} = {1'b1, 4'hD};
	    "E": {hex_char, nibble_val} = {1'b1, 4'hE};
	    "F": {hex_char, nibble_val} = {1'b1, 4'hF};
	    "a": {hex_char, nibble_val} = {1'b1, 4'hA};
	    "b": {hex_char, nibble_val} = {1'b1, 4'hB};
	    "c": {hex_char, nibble_val} = {1'b1, 4'hC};
	    "d": {hex_char, nibble_val} = {1'b1, 4'hD};
	    "e": {hex_char, nibble_val} = {1'b1, 4'hE};
	    "f": {hex_char, nibble_val} = {1'b1, 4'hF};
	    default:
		;
	endcase
    end

    //
    // new_byte: indicates whether a new byte was assembled
    // byte_val: value of assembled byte
    //
    logic nibble_sel; // 1 = high, 0 = low
    logic [pkg_ram::RAM_NIBBLE_SIZE-1:0] low_nibble, high_nibble;
    logic new_byte;
    logic got_eof;

    assign byte_valid = nibble_sel;
    assign byte_val = {high_nibble, low_nibble};

    initial begin
	nibble_sel = 1;
	new_byte = 0;
	got_eof = 0;
	done = 0;
	io.putc_push = 0;
	io.putc_char = 0;
    end

    always_ff @ (posedge clk) begin
	io.getc_pop <= 0;
	new_byte <= 0;

	if (rst) begin
	    nibble_sel <= 1;
	    new_byte <= 0;
	    got_eof <= 0;
	    done <= 0;
	end
	else if (!done && got_eof) begin
	    done <= 1;
	end
	else if (!done && !io.getc_pop && io.getc_en) begin
	    io.getc_pop <= 1;
	    if (hex_char) begin
		nibble_sel <= !nibble_sel;
		case (nibble_sel)
		    1'b1:
			begin
			    high_nibble <= nibble_val;
			    low_nibble <= 0;
			end
		    1'b0:
			begin
			    low_nibble <= nibble_val;
			    new_byte <= 1;
			end
		endcase
	    end
	    else if (io.getc_char == 8'h04) begin
		got_eof <= 1;
	    end
	end
    end
   
    //
    // store new byte
    //

    logic [pkg_ram::RAM_ADDRW-1:0] addr;

    initial begin
	addr = 0;

	ram.op = pkg_ram::RAM_NOP;
	ram.data_type = pkg_ram::RAM_BYTE;
	ram.addr = 0;
	ram.data_in = 0;
    end

    always_ff @ (posedge clk) begin
	ram.op <= pkg_ram::RAM_NOP;
	io.putc_push <= 0;

	if (rst) begin
	    addr <= 0;
	end
	else if (new_byte) begin
	    ram.op <= pkg_ram::RAM_STORE;
	    ram.addr <= addr;
	    ram.data_in[pkg_ram::RAM_BYTE_SIZE-1:0] <= byte_val;
	    addr <= addr + 1;
	end
    end
 
endmodule

