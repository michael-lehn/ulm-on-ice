// For addressing single bytes.
module mem(
    input wire clk,
    input wire [14:0] addr,
    input wire write,
    input wire [7:0] data_in,
    output [7:0] data_out
    );

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

wire [13:0] spram_addr = addr[14:1];
wire spram_byte_sel = addr[0];
wire [3:0] spram_we = write ? spram_byte_sel ? 4'b1100
                                             : 4'b0011
                            : 4'b0000;
wire [15:0] spram_data_in = ~addr[0] ? {8'd0, data_in}
                                   : {data_in, 8'd0};

wire [15:0] spram_data_out;
assign data_out = spram_byte_sel ? spram_data_out[15:8]
                                 : spram_data_out[7:0];

spram spram_inst(
    .clk(clk),
    .we(spram_we),
    .addr(spram_addr),
    .data_in(spram_data_in),
    .data_out(spram_data_out)
);

endmodule
