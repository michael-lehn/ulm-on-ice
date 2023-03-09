`include "pkg_ram.sv"
import pkg_ram::data_type_t;
import pkg_ram::SPRAM_ADDRW;
import pkg_ram::SPRAM_WIDTH;
import pkg_ram::RAM_ADDRW;
import pkg_ram::RAM_LONG_SIZE;
import pkg_ram::RAM_LONG;
import pkg_ram::RAM_FETCH;
import pkg_ram::RAM_STORE;

module dev_ram (
    input logic clk,
    input if_ram.dev ram
);

    logic fetch, store;
    assign fetch = ram.op == RAM_FETCH;
    assign store = ram.op == RAM_STORE;

    //
    // update addr and size if there's a fetch or store operation
    //
    logic [RAM_ADDRW-1:0] addr, addr_r = 0;
    data_type_t data_type, data_type_r = RAM_LONG;

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
    logic [1:0] addr_offset;
    logic [SPRAM_ADDRW-1:0] addr_tag;
    logic addr_set;

    always_comb begin
	addr_offset = addr[1:0];
	addr_tag = addr[RAM_ADDRW-2:2];
	addr_set = addr[RAM_ADDRW-1];
    end

    //
    // zero extend ram.data_in into quad_in
    //
    logic [RAM_LONG_SIZE-1:0] long_in;

    long_ext_low long_ext_low(
	.data_in(ram.data_in),
	.data_type(data_type),
	.data_out(long_in)
    );

    //
    // right shift data_in
    //
    logic [SPRAM_WIDTH-1:0] w0_in, w1_in;

    long_rshift long_rshift0(
	.data_in(long_in),
	.offset(addr_offset),
	.data_out({w0_in, w1_in})
    );

    //
    // setup an unshifted writemask based on data size
    //
    logic [3:0] we0, we1;

    long_we_mask long_we_mask(
	.data_type(data_type),
	.offset(addr_offset),
	.store(store),
	.we0(we0),
	.we1(we1)
    );

    //
    // left shift quad from spram into quad_out
    //
    logic [SPRAM_WIDTH-1:0] w0_out, w1_out;
    logic [RAM_LONG_SIZE-1:0] long_out;

    long_lshift long_lshift0(
	.data_in({w0_out, w1_out}),
	.offset(addr_offset),
	.data_out(long_out)
    );

    //
    // (zero) extend data from quad_out into ram.data_out
    //
    long_ext_high long_ext_high(
	.data_in(long_out),
	.data_type(data_type),
	.data_out(ram.data_out)
    );


    logic [3:0]  low_we0, low_we1, high_we0, high_we1;

    always_comb begin
	{low_we0, low_we1} = 0;
	{high_we0, high_we1} = 0;

	case (addr_set)
	    0: {low_we0, low_we1} = {we0, we1};
	    1: {high_we0, high_we1} = {we0, we1};
	endcase
    end

    logic [SPRAM_WIDTH-1:0] low_w0_out, low_w1_out, high_w0_out, high_w1_out;

    always_comb begin
	case (addr_set)
	    0: {w0_out, w1_out} = {low_w0_out, low_w1_out};
	    1: {w0_out, w1_out} = {high_w0_out, high_w1_out};
	endcase
    end

    spram low_spram0(
        .clk(clk),
        .we(low_we0),
        .addr(addr_tag),
        .data_in(w0_in),
        .data_out(low_w0_out)
    );
    
    spram low_spram1(
        .clk(clk),
        .we(low_we1),
        .addr(addr_tag),
        .data_in(w1_in),
        .data_out(low_w1_out)
    );
    
    spram high_spram0(
        .clk(clk),
        .we(high_we0),
        .addr(addr_tag),
        .data_in(w0_in),
        .data_out(high_w0_out)
    );
    
    spram high_spram1(
        .clk(clk),
        .we(high_we1),
        .addr(addr_tag),
        .data_in(w1_in),
        .data_out(high_w1_out)
    );
    
endmodule
