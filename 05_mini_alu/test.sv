module test (
    input logic CLK,
    output logic A0,
    output logic A1,
    output logic A2,
    output logic A3,
    output logic A4,
    output logic A5,
    output logic A6,
    output logic A7,
    input logic B0,
    input logic B1,
    input logic B2,
    input logic B3,
    input logic B4,
    input logic B5,
    input logic B6,
    input logic B7,
    input logic BTN1,
    input logic BTN2,
    input logic BTN3,
    output logic LED1,
    output logic LED2,
    output logic LED3,
    output logic LED4
);

    logic [7:0] hex_pins;
    assign {A7, A6, A5, A4, A3, A2, A1, A0} = hex_pins;

    logic [7:0] instr;
    assign instr = {B0, B1, B2, B3, B4, B5, B6, B7};

    logic [1:0] op, x, y, z;
    assign {op, x, y, z} = instr;

    // BTN1: synchroniser, debouncer, and a pulse of one clock cycle per press
    logic btn_s1 = 0, btn_s2 = 0;   // synchroniser
    logic btn = 0;                  // debounced button
    logic [16:0] btn_cnt = 0;       // cycles in which btn_s2 differs from btn
    logic exec = 0;                 // 1 for one cycle: execute the instruction

    always_ff @ (posedge CLK) begin
        btn_s1 <= BTN1;
        btn_s2 <= btn_s1;
        exec <= 0;
        if (btn_s2 == btn) begin
            btn_cnt <= 0;
        end
        else begin
            btn_cnt <= btn_cnt + 1;
            if (btn_cnt == 17'h1ffff) begin
                btn <= btn_s2;
                exec <= btn_s2;
            end
        end
    end

    // Register file. %0 is the zero register: every read port gives 0 for
    // address 0, and writes to %0 are ignored. So register[0] is never used.
    logic [7:0] register[4];

    // Decoder: immediate operand, second read address, add/sub, first operand
    logic [7:0] imm;
    logic [1:0] addr2;
    logic sub, use_data1;

    always_comb begin
        case (op)
            2'b00: begin
                imm = {4'h0, x, y};     // u(XY)
                addr2 = 2'b00;          // + u(%0) = 0
            end
            2'b01: begin
                imm = {x, y, 4'h0};     // u(XY) * 2^4
                addr2 = z;              // + u(%Z)
            end
            default: begin
                imm = 8'h00;            // not used
                addr2 = y;              // u(%X) +/- u(%Y)
            end
        endcase
    end

    assign sub = (op == 2'b11);
    assign use_data1 = op[1];

    // Adder/subtractor: s = a + b or s = a - b = a + ~b + 1
    logic [7:0] a, b, b_xor, s;
    logic cout;

    always_comb begin
        a = imm;
        if (use_data1) begin
            a = register[x];
            if (x == 2'b00) begin
                a = 8'h00;
            end
        end
    end

    always_comb begin
        b = register[addr2];
        if (addr2 == 2'b00) begin
            b = 8'h00;
        end
    end

    assign b_xor = b ^ {8{sub}};        // b, or ~b for a subtraction
    assign {cout, s} = {1'b0, a} + {1'b0, b_xor} + {8'h00, sub};

    // Status flags
    logic ZF = 0, CF = 0, SF = 0, OF = 0;

    always_ff @ (posedge CLK) begin
        if (exec) begin
            if (z != 2'b00) begin
                register[z] <= s;
            end
            ZF <= (s == 8'h00);
            CF <= cout ^ sub;
            SF <= s[7];
            OF <= (a[7] & b_xor[7] & ~s[7]) | (~a[7] & ~b_xor[7] & s[7]);
        end
    end

    assign {LED1, LED2, LED3, LED4} = {ZF, CF, SF, OF};

    logic [7:0] hex_val;

    always_comb begin
        hex_val = register[{BTN3, BTN2}];
        if ({BTN3, BTN2} == 2'b00) begin
            hex_val = 8'h00;
        end
    end

    dev_hex dev_hex0 (
        .clk(CLK),
        .en(1'b1),
        .hex_val(hex_val),
        .hex_pins(hex_pins)
    );

endmodule
