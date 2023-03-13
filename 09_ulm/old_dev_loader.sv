`include "pkg_ram.sv"

module dev_loader (
    input logic clk,
    input logic rst,
    if_io.client io,
    if_ram.client ram,
    output logic done
);

    logic got_eof;
    logic [pkg_ram::RAM_ADDRW-1:0] addr;

    initial begin
	done = 0;
	got_eof = 0;
	addr = 0;

	ram.op = pkg_ram::RAM_NOP;
	ram.data_type = pkg_ram::RAM_BYTE;
	ram.addr = 0;
    end

    assign ram.data_in = {
	{pkg_ram::RAM_QUAD_SIZE - pkg_ram::RAM_BYTE_SIZE{1'b0}},
	io.getc_char
    };

    always_ff @ (posedge clk) begin
	if (rst) begin
	    done <= 0;
	    got_eof <= 0;
	    addr <= 0;

	    ram.op <= pkg_ram::RAM_NOP;
	    ram.data_type <= pkg_ram::RAM_BYTE;
	    ram.addr <= 0;
	end
	else begin
	    ram.op <= pkg_ram::RAM_NOP;
	    io.getc_pop <= 0;
	    io.putc_push <= 0;

	    if (!done) begin
		if (!got_eof && io.getc_char == 8'h04) begin
		    got_eof <= 1;
		    io.putc_char <= "\n";
		    io.putc_push <= 1;
		end
		else if (got_eof && io.putc_push_done) begin
		    done <= 1;
		end
		else if (io.getc_en && ram.op == pkg_ram::RAM_NOP) begin
		    ram.op <= pkg_ram::RAM_STORE;
		    ram.addr <= addr;
		    io.getc_pop <= 1;
		    addr <= addr + 1;
		end
	    end
	end
    end
 
endmodule

