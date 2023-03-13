interface if_fifo #(
    localparam WIDTH = 8		// each entry is one byte
);
    logic empty;
    logic full;
    logic pop_front;
    logic [WIDTH-1:0] data_out;
    logic push_back;
    logic [WIDTH-1:0] data_in;

    modport fifo(
	input pop_front,
	input push_back,
	input data_in,
	output empty,
	output full,
	output data_out
    );
endinterface

