module dp_bram4096 #(
    parameter WIDTH = 8,
    localparam SIZE = 4096, // total bits
    localparam DEPTH = SIZE / WIDTH,
    localparam ADDRW = $clog2(DEPTH),
    localparam INIT_CLK_COUNT = 60
) (
    input logic clk_in,
    input logic en_in,
    input logic [ADDRW-1:0] addr_in,
    input logic [WIDTH-1:0] data_in,
    input logic [ADDRW-1:0] addr_out,
    output logic [WIDTH-1:0] data_out
);

    logic [WIDTH-1:0] mem [DEPTH] /* synthesis syn_ramstyle = "no_rw_check" */;

    initial mem[0] <= 255;

    always @ (posedge clk_in) begin : write
	if (en_in) begin
	    mem[addr_in] <= data_in;
	end
    end : write

    always_comb begin : read
	data_out = mem[addr_out];
    end : read

endmodule
