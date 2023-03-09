`include "pkg_ram.sv"

module dev_ram_debugger (
    input logic clk,
    if_ram.client ram,
    input logic rst_addr,
    input logic fetch,
    input logic sel_out,
    output logic [pkg_ram::RAM_QUAD_SIZE-1:0] out
);

    logic [pkg_ram::RAM_ADDRW-1:0] addr = 0;

    logic rst_addr_r = 0, fetch_r = 0;

    always_ff @ (posedge clk) begin
	rst_addr_r <= rst_addr;
	fetch_r <= fetch;
    end

    initial begin
	ram.op = pkg_ram::RAM_NOP;
	ram.data_type = pkg_ram::RAM_BYTE;
	ram.addr = 0;
	ram.data_in = 0;
    end

    always_ff @ (posedge clk) begin
	ram.op <= pkg_ram::RAM_NOP;

	if (rst_addr && !rst_addr_r) begin
	    addr <= 0;
	    ram.addr <= 0;
	    ram.op <= pkg_ram::RAM_FETCH;
	end
	else if (fetch && !fetch_r) begin
	    if (ram.op == pkg_ram::RAM_NOP) begin
		ram.op <= pkg_ram::RAM_FETCH;
		ram.addr <= addr;
		addr <= addr + 1;
	    end
	end
    end

    always_comb begin
	case (sel_out)
	    1'b0:
		out = {
		    {pkg_ram::RAM_QUAD_SIZE-pkg_ram::RAM_ADDRW{1'b0}},
		    ram.addr
		};
	    1'b1:
		out = {
		    {pkg_ram::RAM_QUAD_SIZE-pkg_ram::RAM_BYTE_SIZE{1'b0}},
		    ram.data_out[pkg_ram::RAM_BYTE_SIZE-1:0]
		};
	endcase
    end

endmodule


