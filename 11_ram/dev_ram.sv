`include "pkg_ram.sv"
import pkg_ram::data_type_t;
import pkg_ram::SPRAM_ADDRW;
import pkg_ram::SPRAM_WIDTH;
import pkg_ram::RAM_ADDRW;
import pkg_ram::RAM_QUAD_SIZE;
import pkg_ram::RAM_QUAD;
import pkg_ram::RAM_FETCH;
import pkg_ram::RAM_STORE;

module dev_ram (
    input logic clk,
    input if_ram.server ram
);

    logic fetch, store;
    assign fetch = ram.op == RAM_FETCH;
    assign store = ram.op == RAM_STORE;

    //
    // update addr and size if there's a fetch or store operation
    //
    logic [RAM_ADDRW-1:0] addr, addr_r = 0;
    data_type_t data_type, data_type_r = RAM_QUAD;

    always_ff @ (posedge clk) begin
	if (fetch || store) begin
	    addr_r <= ram.addr;
	    data_type_r <= ram.data_type;
	end
    end

    always_comb begin
	addr = addr_r;
	data_type = data_type_r;
	if (fetch || store) begin
	    addr = ram.addr;
	    data_type = ram.data_type;
	end
    end

    //
    // split addr into tag and offset
    //
    logic [2:0] addr_offset;
    logic [SPRAM_ADDRW-1:0] addr_tag;

    always_comb begin
	addr_offset = addr[2:0];
	addr_tag = addr[RAM_ADDRW-1:3];
    end

    //
    // left shift quad from spram into quad_out
    //
    logic [SPRAM_WIDTH-1:0] w00_out, w01_out, w10_out, w11_out;
    logic [RAM_QUAD_SIZE-1:0] quad_out;

    quad_lshift quad_lshift0(
	.data_in({w00_out, w01_out, w10_out, w11_out}),
	.offset(addr_offset),
	.data_out(quad_out)
    );

    //
    // (zero) extend data from quad_out into ram.data_out
    //
    quad_ext_high quad_ext_high(
	.data_in(quad_out),
	.data_type(data_type),
	.data_out(ram.data_out)
    );

    //
    // zero extend ram.data_in into quad_in
    //
    logic [RAM_QUAD_SIZE-1:0] quad_in;

    quad_ext_low quad_ext_low(
	.data_in(ram.data_in),
	.data_type(data_type),
	.data_out(quad_in)
    );

    //
    // right shift data_in
    //
    logic [SPRAM_WIDTH-1:0] w00_in, w01_in, w10_in, w11_in;

    quad_rshift quad_rshift0(
	.data_in(quad_in),
	.offset(addr_offset),
	.data_out({w00_in, w01_in, w10_in, w11_in})
    );

    //
    // setup an unshifted writemask based on data size
    //
    logic [3:0] we00, we01, we10, we11;

    quad_we_mask quad_we_mask(
	.data_type(data_type),
	.offset(addr_offset),
	.store(store),
	.we00(we00),
	.we01(we01),
	.we10(we10),
	.we11(we11)
    );

    spram spram00(
        .clk(clk),
        .we(we00),
        .addr(addr_tag),
        .data_in(w00_in),
        .data_out(w00_out)
    );
    
    spram spram01(
        .clk(clk),
        .we(we01),
        .addr(addr_tag),
        .data_in(w01_in),
        .data_out(w01_out)
    );
    
    spram spram10(
        .clk(clk),
        .we(we10),
        .addr(addr_tag),
        .data_in(w10_in),
        .data_out(w10_out)
    );
    
    spram spram11(
        .clk(clk),
        .we(we11),
        .addr(addr_tag),
        .data_in(w11_in),
        .data_out(w11_out)
    );
    
endmodule
