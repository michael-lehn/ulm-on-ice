`include "pkg_bus.sv"
`include "pkg_ram.sv"
`include "pkg_reg.sv"

interface if_instr_bus;
    pkg_bus::op_t op;
    pkg_ram::data_type_t data_type;
    logic [pkg_reg::REG_ADDRW-1:0] data_reg;
    logic [pkg_reg::REG_ADDRW-1:0] addr_reg;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [pkg_ram::RAM_ADDRW-1:0] addr_offset;
    /* verilator lint_on UNUSEDSIGNAL */

    modport server(
	input op,
	input data_type,
	input data_reg,
	input addr_reg,
	input addr_offset
    );
    
    modport client(
	output op,
	output data_type,
	output data_reg,
	output addr_reg,
	output addr_offset
    );

endinterface
