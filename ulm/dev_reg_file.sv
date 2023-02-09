`include "pkg_reg.sv"

module dev_reg_file (
    input logic clk,
    input if_dev_reg_file reg_file
);

    logic [pkg_reg::REG_WIDTH-1:0] mem [pkg_reg::REG_DEPTH];

    initial begin
	mem[0] = 255;
    end

    always @ (posedge clk) begin
	if (reg_file.op == pkg_reg::REG_WRITE && reg_file.addr_in != 0) begin
	    mem[reg_file.addr_in] <= reg_file.data_in;
	end
	reg_file.data_out0 <= reg_file.addr_out0 != 0
			    ? mem[reg_file.addr_out0]
			    : {pkg_reg::REG_WIDTH{1'b0}};
	reg_file.data_out1 <= reg_file.addr_out1 != 0
			    ? mem[reg_file.addr_out1]
			    : {pkg_reg::REG_WIDTH{1'b0}};
    end


    /*
    logic write;
    assign write = reg_file.op == pkg_reg::REG_WRITE && reg_file.addr_in != 0;

    logic [5:0] addr_in, addr_out0, addr_out1;
    assign addr_in = { 2'b0, reg_file.addr_in};
    assign addr_out0 = { 2'b0, reg_file.addr_out0};
    assign addr_out1 = { 2'b0, reg_file.addr_out1};

    logic [pkg_reg::REG_WIDTH-1:0] data_out0, data_out1;

    assign reg_file.data_out0 = reg_file.addr_out0 != 0
			      ? data_out0
			      : {pkg_reg::REG_WIDTH{1'b0}};
    assign reg_file.data_out1 = reg_file.addr_out1 != 0
			      ? data_out1
			      : {pkg_reg::REG_WIDTH{1'b0}};

    dp_bram4096 #(pkg_reg::REG_WIDTH) mem0(
	.clk_in(clk),
	.en_in(write),
	.addr_in(addr_in),
	.data_in(reg_file.data_in),
	.addr_out(addr_out0),
	.data_out(data_out0)
    );

    dp_bram4096 #(pkg_reg::REG_WIDTH) mem1(
	.clk_in(clk),
	.en_in(write),
	.addr_in(addr_in),
	.data_in(reg_file.data_in),
	.addr_out(addr_out1),
	.data_out(data_out1)
    );
    */

endmodule
