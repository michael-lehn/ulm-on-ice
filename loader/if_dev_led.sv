`include "pkg_led.sv"

interface if_dev_led;
    pkg_led::op_t op;
    logic pin;
endinterface

