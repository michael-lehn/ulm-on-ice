module reg_file #(
    localparam WIDTH = 64,
    parameter DEPTH = 16,
    localparam ADDRW = $clog2(DEPTH)
) (
    input logic clk,
    input logic en_in,
    input logic [ADDRW-1:0] addr_in,
    input logic [WIDTH-1:0] data_in,
    input logic [ADDRW-1:0] addr_out0,
    input logic [ADDRW-1:0] addr_out1,
    output logic [WIDTH-1:0] data_out0,
    output logic [WIDTH-1:0] data_out1
);

    logic [WIDTH-1:0] mem [DEPTH];

    initial mem[0] = 255;

    always @ (posedge clk) begin
	if (en_in) begin
	    mem[addr_in] <= data_in;
	end
    end

    always_comb begin
	data_out0 = addr_out0 != 0 ? mem[addr_out0] : {WIDTH{1'b0}};
	data_out1 = addr_out1 != 0 ? mem[addr_out1] : {WIDTH{1'b0}};
    end

endmodule
