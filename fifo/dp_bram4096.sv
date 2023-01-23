module dp_bram4096 #(
    parameter WIDTH = 8,
    localparam SIZE = 4096, // total bits
    localparam DEPTH = SIZE / WIDTH,
    localparam ADDRW = $clog2(DEPTH)
) (
    input logic clk_in,
    input logic en_in,
    input logic [ADDRW-1:0] addr_in,
    input logic [WIDTH-1:0] data_in,
    input logic clk_out,
    input logic [ADDRW-1:0] addr_out,
    output logic [WIDTH-1:0] data_out
);

    logic [WIDTH-1:0] mem [2**ADDRW];

    always @ (posedge clk_in) begin : write
	if (en_in) begin
	    mem[addr_in] <= data_in;
	end
    end : write

    always @(posedge clk_out) begin : read
	data_out <= mem[addr_out];
    end

endmodule
