`ifndef ALU_PKG
`define ALU_PKG

package alu_pkg;

typedef enum {
    ALU_NOP,
    ALU_ADD,
    ALU_SUB,
    ALU_MUL,
    ALU_DIV
} alu_op_t;

endpackage // alu_pkg

`endif // ALU_PKG
