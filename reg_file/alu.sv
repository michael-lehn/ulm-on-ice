`include "../reg_file/alu_pkg.sv"

module alu #(
    localparam WIDTH = 64
) (
    input logic clk,
    input alu_pkg::alu_op_t op,
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] res,
    output logic zf,
    output logic cf,
    output logic of,
    output logic sf
);
    
    logic [WIDTH-1:0] acc_new;
    logic [WIDTH-1:0] acc = 0;

    logic acc_cf_new;
    logic acc_cf = 0;

    logic acc_of_new;
    logic acc_of = 0;

    always_comb begin
	case (op)
	    alu_pkg::ALU_ADD: {acc_cf_new, acc_new} = b + a;
	    alu_pkg::ALU_SUB: {acc_cf_new, acc_new} = b - a;
	    default: {acc_cf_new, acc_new} = 0;
	endcase
	case (op)
	    alu_pkg::ALU_ADD:
		acc_of_new = acc_new[WIDTH-1] && ~b[WIDTH-1] && ~a[WIDTH-1]
			  || ~acc_new[WIDTH-1] && b[WIDTH-1] && a[WIDTH-1];
	     alu_pkg::ALU_SUB:
		acc_of_new = ~acc_new[WIDTH-1] && b[WIDTH-1] && ~a[WIDTH-1]
			  || acc_new[WIDTH-1] && ~b[WIDTH-1] && a[WIDTH-1];
	    default: acc_of_new = 0;
	endcase
	res = op == alu_pkg::ALU_NOP ? acc : acc_new;
	cf = op == alu_pkg::ALU_NOP ? acc_cf : acc_cf_new;
	of = op == alu_pkg::ALU_NOP ? acc_of : acc_of_new;

	zf = res == 0;
	sf = res[WIDTH-1];
    end

    always @ (posedge clk) begin
	if (op != alu_pkg::ALU_NOP) begin
	    acc <= acc_new;
	    acc_cf <= acc_cf_new;
	    acc_of <= acc_of_new;
	end
    end

endmodule
