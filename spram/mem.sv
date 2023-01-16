// For addressing single bytes.
module mem(
    input logic clk,
    input logic [14:0] addr,
    input logic write,
    input logic [7:0] data_in,
    output logic [7:0] data_out);

// Physically memory is organized in words (of 16 bits). 
//
//   [[  Word 0       ]] [[  Word 1        ]] ...
//
//  These words are addresses with ram_addr. Registers ram_data_in and
//  ram_data_out are used for storing and fetching words. With ram_we
//  the fetch/store operation can be masked such that only the high or low
//  byte of the word is actually fetched/stored.
//
//  So we actually view the memory as an array of bytes:
//
//   [[Byte 0] [Byte 1]] [[Byte 2] [ Byte 3]] ...
//

logic [13:0] spram_addr;
logic spram_byte_sel;
logic [3:0] spram_we;
logic [15:0] spram_data_in;
logic [15:0] spram_data_out;

spram spram_inst(
    .clk(clk),
    .we(spram_we),
    .addr(spram_addr),
    .data_in(spram_data_in),
    .data_out(spram_data_out)
);

always_comb begin
    spram_addr[13:0] = addr[14:1];
    spram_byte_sel = addr[0];
    spram_we = write ? spram_byte_sel ? 4'b1100
                                      : 4'b0011
                     : 4'b0000;
    spram_data_in = ~addr[0] ? {8'd0, data_in}
                             : {data_in, 8'd0};
    data_out = spram_byte_sel ? spram_data_out[15:8]
                              : spram_data_out[7:0];
end

endmodule
