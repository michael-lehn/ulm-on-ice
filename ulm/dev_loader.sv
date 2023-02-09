`include "pkg_ram.sv"

module dev_loader (
    input logic clk,
    input logic rst,
    input logic [pkg_ram::RAM_BYTE-1:0] data_in,
    input logic data_en,
    output logic [pkg_ram::RAM_BYTE-1:0] byte_val,
    output logic byte_valid,
    output if_dev_ram ram,
    output logic done
);

    initial done = 0;

    always_ff @ (posedge clk) begin
	if (rst) begin
	    done <= 0;
	end
	else if (data_in == 8'h04 && ram.op == pkg_ram::RAM_NOP) begin
	    done <= 1;
	end
    end

    logic [pkg_ram::RAM_NIBBLE-1:0] low_nibble, high_nibble;
    logic [pkg_ram::RAM_NIBBLE:0] nibble_val;
    logic nibble = 0;

    assign byte_valid = !nibble;
    assign byte_val = {high_nibble, low_nibble};

    // put together bytes from hex digits
    always_ff @ (posedge clk) begin
	if (rst) begin
	    nibble <= 0;
	end
	else begin
	    if (!done && data_en && nibble_val < 16) begin
		nibble <= !nibble;
		case (nibble)
		    1'b0:
			begin
			    high_nibble <= nibble_val[pkg_ram::RAM_NIBBLE-1:0];
			    low_nibble <= 0;
			end
		    1'b1:
			low_nibble <= nibble_val[pkg_ram::RAM_NIBBLE-1:0];
		endcase
	    end
	end
    end

    always_comb begin
	nibble_val = 16;
	case (data_in)
	    "0": nibble_val = 0;
	    "1": nibble_val = 1;
	    "2": nibble_val = 2;
	    "3": nibble_val = 3;
	    "4": nibble_val = 4;
	    "5": nibble_val = 5;
	    "6": nibble_val = 6;
	    "7": nibble_val = 7;
	    "8": nibble_val = 8;
	    "9": nibble_val = 9;
	    "A": nibble_val = 10;
	    "B": nibble_val = 11;
	    "C": nibble_val = 12;
	    "D": nibble_val = 13;
	    "E": nibble_val = 14;
	    "F": nibble_val = 15;
	    "a": nibble_val = 10;
	    "b": nibble_val = 11;
	    "c": nibble_val = 12;
	    "d": nibble_val = 13;
	    "e": nibble_val = 14;
	    "f": nibble_val = 15;
	    default:
		;
	endcase
    end

    logic byte_valid_r = 1;
    logic new_byte_val;
    logic [pkg_ram::RAM_ADDRW-1:0] addr_next = 0;

    always_comb begin
	new_byte_val = !byte_valid_r && byte_valid;
    end

    always_ff @ (posedge clk) begin
	if (rst) begin
	    byte_valid_r <= 1;
	end
	else begin
	    byte_valid_r <= byte_valid;
	end
    end

    initial begin
	ram.size = pkg_ram::RAM_BYTE;
    end

    always_ff @ (posedge clk) begin
	ram.op <= pkg_ram::RAM_NOP;

	if (rst) begin
	    ram.addr <= 0;
	    addr_next <= 0;
	end
	else if (!done && new_byte_val) begin
	    ram.op <= pkg_ram::RAM_STORE;
	    ram.addr <= addr_next;
	    addr_next <= addr_next + 1;
	    ram.data_in <= {
				{pkg_ram::RAM_QUAD - pkg_ram::RAM_BYTE{1'b0}},
				byte_val
			   };
	end
    end


 
endmodule
