`ifndef PKG_ALU
`define PKG_ALU

package pkg_alu;

typedef enum {
    ALU_NOP,
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_SHR,
    ALU_SHL,
    ALU_MULW
} op_t;

typedef enum {
    ALU_IMM,
    ALU_REG
} sel_t;

endpackage // pkg_alu

`endif // PKG_ALU
