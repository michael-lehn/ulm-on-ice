`ifndef PKG_RAM
`define PKG_RAM

package pkg_ram;

typedef enum {
    SPRAM_ADDRW = 14, // address space for words in a single spram block
    SPRAM_WIDTH = 16, // 1 word = 2 bytes
    RAM_ADDRW = 17    // address space for quad words stored in 4 blocks
} addr_t;

typedef enum {
    RAM_BYTE,
    RAM_WORD,
    RAM_LONG
} data_type_t;

typedef enum {
    RAM_NIBBLE_SIZE = 4,
    RAM_BYTE_SIZE = 8,
    RAM_WORD_SIZE = 16,
    RAM_LONG_SIZE = 32
} data_size_t;

typedef enum {
    RAM_NOP,
    RAM_FETCH,
    RAM_STORE
} op_t;

endpackage // pkg_ram

`endif // PKG_RAM
