`include "pkg_ram.sv"

interface if_ram;
    pkg_ram::op_t op;
    pkg_ram::data_type_t data_type;
    logic [pkg_ram::RAM_ADDRW-1:0] addr;
    logic [pkg_ram::RAM_LONG_SIZE-1:0] data_in;
    logic [pkg_ram::RAM_LONG_SIZE-1:0] data_out;

    modport dev(
	input op,
	input data_type,
	input addr,
	input data_in,
	output data_out
    );
    
endinterface
