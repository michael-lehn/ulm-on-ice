`ifndef PKG_BUS
`define PKG_BUS

package pkg_bus;

typedef enum {
    BUS_NOP,
    BUS_FETCH,
    BUS_STORE
} op_t;

endpackage // pkg_bus

`endif // PKG_BUS
