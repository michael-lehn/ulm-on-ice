`ifndef RAM_PKG
`define RAM_PKG

package ram_pkg;

typedef enum {
    RAM_BYTE = 8,   //	1 byte
    RAM_WORD = 16,  //	2 bytes
    RAM_LONG = 32,  //	4 bytes
    RAM_QUAD = 64   //	8 bytes
} ram_size_t /* verilator public */;

typedef enum {
    RAM_NOP,
    RAM_FETCH,
    RAM_STORE
} ram_op_t /* verilator public */;


endpackage // ram_pkg

`endif // RAM_PKG
