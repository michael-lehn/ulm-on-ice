/*
 * Debouncer for a push button
 *
 * btn is synchronised with two flip-flops. The debounced level takes the
 * value of the synchronised button only after it has been stable for 2^W
 * cycles (W = 17: about 11 ms at 12 MHz). press is 1 for exactly one cycle
 * when the debounced level changes from 0 to 1.
 */

module debounce #(
    parameter W = 17
) (
    input logic clk,
    input logic btn,
    output logic press
);

    // synchroniser
    logic btn_s1 = 0, btn_s2 = 0;

    always_ff @ (posedge clk) begin
        btn_s1 <= btn;
        btn_s2 <= btn_s1;
    end

    // debounced level: takes the value of btn_s2 after btn_s2 differed from
    // it for 2^W cycles in a row
    logic level = 0;
    logic [W-1:0] cnt = 0;

    always_ff @ (posedge clk) begin
        if (btn_s2 == level) begin
            cnt <= 0;
        end
        else if (&cnt) begin
            level <= btn_s2;
            cnt <= 0;
        end
        else begin
            cnt <= cnt + 1;
        end
    end

    // edge detector: press is 1 in the first cycle in which level is 1
    logic level_r = 0;

    always_ff @ (posedge clk) begin
        level_r <= level;
    end

    assign press = level && !level_r;

endmodule
