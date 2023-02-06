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
	if (reg_file.op == pkg_reg::REG_WRITE) begin
	    mem[reg_file.addr_in] <= reg_file.data_in;
	end
    end

    always_comb begin
	reg_file.data_out0 = reg_file.addr_out0 != 0
			   ? mem[reg_file.addr_out0]
			   : {pkg_reg::REG_WIDTH{1'b0}};
	reg_file.data_out1 = reg_file.addr_out1 != 0
			   ? mem[reg_file.addr_out1]
			   : {pkg_reg::REG_WIDTH{1'b0}};
    end

endmodule
