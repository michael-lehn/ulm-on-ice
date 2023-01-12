// For addressing single bytes.
module mem(
    input wire clk,
    input wire [14:0] addr,
    input wire write,
    input wire [7:0] data_in,
    output [7:0] data_out,
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

reg [13:0] ram_addr;
reg ram_byte_sel;
reg [3:0] ram_we;
reg [15:0] ram_data_in;
wire [15:0] ram_data_out;

reg [7:0] data_out_reg;
assign data_out = data_out_reg;

spram spram_inst(
    clk,
    ram_we,
    ram_addr,
    ram_data_in,
    ram_data_out,
);

always @(posedge clk) begin
    ram_addr[13:0] <= addr[14:1];
    ram_byte_sel <= addr[0];
    if (write) begin
	ram_we <= ~addr[0] ? 4'b1100 : 4'b0011;
	if (~addr[0])
	    ram_data_in[15:8] <= data_in[7:0];
	else
	    ram_data_in[7:0] <= data_in[7:0];
    end
    else begin
	ram_we <= 4'b0000;
	data_out_reg[7:0] <= ~ram_byte_sel ? ram_data_out[15:8]
					   : ram_data_out[7:0];
    end
end

endmodule
