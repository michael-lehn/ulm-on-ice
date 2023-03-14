`include "pkg_reg.sv"

module dev_alu #(
    localparam WIDTH = pkg_reg::REG_WIDTH
) (
    input logic clk,
    input if_alu.server alu
);
    logic [31:0] prod;
    logic [15:0] a0, b0;
    assign a0 = alu.a[15:0];
    assign b0 = alu.b[15:0];
    assign prod = a0 * b0;
    
    logic [WIDTH-1:0] res;
    logic [WIDTH-1:0] acc = 0;

    logic cf_res;
    logic cf_acc = 0;

    logic of_res;
    logic of_acc = 0;

    always_comb begin

	case (alu.op)
	    pkg_alu::ALU_ADD:
		{cf_res, res} = alu.b + alu.a;
	    pkg_alu::ALU_SUB:
		{cf_res, res} = alu.b - alu.a;
	    pkg_alu::ALU_AND:
		{cf_res, res} = {1'b0, alu.b & alu.a};
	    pkg_alu::ALU_SHR:
		{cf_res, res} = {1'b0, alu.b >> alu.a};
	    pkg_alu::ALU_SHL:
		{cf_res, res} = {1'b0, alu.b << alu.a};
	    pkg_alu::ALU_MULW:
		{cf_res, res} = {1'b0, {WIDTH-32{1'b0}}, prod};
	    default:
		{cf_res, res} = 0;
	endcase

	case (alu.op)
	    pkg_alu::ALU_ADD:
		of_res = res[WIDTH-1] && ~alu.b[WIDTH-1] && ~alu.a[WIDTH-1]
		      || ~res[WIDTH-1] && alu.b[WIDTH-1] && alu.a[WIDTH-1];
	     pkg_alu::ALU_SUB:
		of_res = ~res[WIDTH-1] && alu.b[WIDTH-1] && ~alu.a[WIDTH-1]
		      || res[WIDTH-1] && ~alu.b[WIDTH-1] && alu.a[WIDTH-1];
	    default: of_res = 0;
	endcase
	
	alu.s = alu.op == pkg_alu::ALU_NOP ? acc : res;
	alu.cf = alu.op == pkg_alu::ALU_NOP ? cf_acc : cf_res;
	alu.of = alu.op == pkg_alu::ALU_NOP ? of_acc : of_res;

	alu.zf = alu.s == 0;
	alu.sf = alu.s[WIDTH-1];
    end

    always @ (posedge clk) begin
	if (alu.op != pkg_alu::ALU_NOP) begin
	    acc <= res;
	    cf_acc <= cf_res;
	    of_acc <= of_res;
	end
    end

endmodule
