`include "pkg_bus.sv"
`include "pkg_ram.sv"
`include "pkg_reg.sv"

interface if_instr_bus;
    pkg_bus::op_t op;
    pkg_ram::size_t size;
    logic [pkg_reg::REG_ADDRW-1:0] data_reg;
    logic [pkg_reg::REG_ADDRW-1:0] addr_reg;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [pkg_ram::RAM_ADDRW-1:0] addr_offset;
    /* verilator lint_on UNUSEDSIGNAL */
endinterface
