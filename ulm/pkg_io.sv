`ifndef PKG_IO
`define PKG_IO

package pkg_io;

typedef enum {
    IO_NOP,
    IO_PUTC_REG,
    IO_PUTC_IMM,
    IO_GETC
} op_t;

endpackage // pkg_io

`endif // PKG_IO
