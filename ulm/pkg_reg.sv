`ifndef PKG_REG
`define PKG_REG

package pkg_reg;

typedef enum {
    REG_ADDRW = 4,
    REG_DEPTH = 16, // 2 ** REG_ADDRW,
    REG_WIDTH = 64
} size_t;

typedef enum {
    REG_READ_ONLY,
    REG_WRITE	    // read and write
} op_t;

endpackage // pkg_reg

`endif // PKG_REG
