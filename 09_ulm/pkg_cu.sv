`ifndef PKG_CU
`define PKG_CU

package pkg_cu;

typedef enum {
    CU_NOP,
    CU_HALT_IMM,
    CU_HALT_REG,
    CU_ABS_JMP,
    CU_REL_JMP
} op_t;

typedef enum {
    CU_FETCH,
    CU_DECODE,
    CU_LOAD_OPERANDS,
    CU_EXECUTE,
    CU_INCREMENT,
    CU_HALTED
} state_t;

endpackage // pkg_cu

`endif // PKG_CU
