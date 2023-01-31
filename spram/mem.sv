module mem #(
    localparam PHYS_WIDTH = 16,
    localparam PHYS_ADDRW = 14,
    localparam WIDTH = 8,
    localparam ADDRW = 15
) (
    input logic clk,
    input logic [ADDRW-1:0] addr,
    input logic write,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);

    logic [PHYS_ADDRW-1:0] spram_addr;
    logic spram_byte_sel;
    logic [3:0] spram_we;
    logic [PHYS_WIDTH-1:0] spram_data_in;
    logic [PHYS_WIDTH-1:0] spram_data_out;
    
   
    always_comb begin
        spram_addr[PHYS_ADDRW-1:0] = addr[ADDRW-1:1];
        spram_byte_sel = addr[0];
        spram_we = write ? spram_byte_sel ? 4'b1100
                                          : 4'b0011
                         : 4'b0000;
        spram_data_in = ~addr[0] ? {8'd0, data_in}
                                 : {data_in, 8'd0};
        data_out = spram_byte_sel ? spram_data_out[15:8]
                                  : spram_data_out[7:0];
    end

    spram spram_inst0(
        .clk(clk),
        .we(spram_we),
        .addr(spram_addr),
        .data_in(spram_data_in),
        .data_out(spram_data_out)
    );
 
endmodule
