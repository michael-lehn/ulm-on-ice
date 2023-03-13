`ifndef PKG_ALU
`define PKG_ALU

package pkg_alu;

typedef enum {
    ALU_NOP,
    ALU_ADD,
    ALU_SUB
} op_t;

typedef enum {
    ALU_IMM,
    ALU_REG
} sel_t;

endpackage // pkg_alu

`endif // PKG_ALU
