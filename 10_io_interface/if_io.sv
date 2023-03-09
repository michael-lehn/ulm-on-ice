`include "pkg_ram.sv"
import pkg_ram::RAM_BYTE_SIZE;

interface if_io;
    logic getc_pop;
    logic putc_push;
    logic [RAM_BYTE_SIZE-1:0] putc_char;

    logic inbuf_full;
    logic getc_en;
    logic [RAM_BYTE_SIZE-1:0] getc_char;
    /* verilator lint_off UNUSEDSIGNAL */
    logic putc_push_done;
    /* verilator lint_on UNUSEDSIGNAL */

    modport server(
	input getc_pop,
	input putc_push,
	input putc_char,
	output inbuf_full,
	output getc_en,
	output getc_char,
	output putc_push_done
    );

    modport client(
	output getc_pop,
	output putc_push,
	output putc_char,
	input inbuf_full,
	input getc_en,
	input getc_char,
	input putc_push_done
    );

endinterface

