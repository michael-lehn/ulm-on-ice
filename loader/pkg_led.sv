`ifndef PKG_LED
`define PKG_LED

package pkg_led;

typedef enum {
    LED_ON,
    LED_OFF,
    LED_BLINK,
    LED_BLINK_INV,
    LED_FLASH
} op_t;

endpackage // pkg_led

`endif // PKG_LED
