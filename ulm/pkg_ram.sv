`ifndef PKG_RAM
`define PKG_RAM

package pkg_ram;

typedef enum {
    RAM_ADDRW = 17,
    RAM_QUAD = 64,
    RAM_LONG = 32,
    RAM_WORD = 16,
    RAM_BYTE = 8
} size_t;

typedef enum {
    RAM_NOP,
    RAM_FETCH,
    RAM_STORE
} op_t;

endpackage // pkg_ram

`endif // PKG_RAM
