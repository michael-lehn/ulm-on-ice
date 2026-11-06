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
    input logic [ADDRW-1:0] addr_out,
    output logic [WIDTH-1:0] data_out
);

    // no_rw_check: no extra logic for a read and a write of the same address
    // at the same edge (a FIFO does this only while it is empty)
    (* no_rw_check *)
    logic [WIDTH-1:0] mem [DEPTH];

    initial begin
        mem[0] = 255;
    end

    always @ (posedge clk_in) begin
        if (en_in) begin
            mem[addr_in] <= data_in;
        end
        data_out <= mem[addr_out];
    end

endmodule
