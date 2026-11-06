`include "pkg_reg.sv"

module dev_reg_file (
    input logic clk,
    input if_reg_file.server reg_file
);

    (* no_rw_check *)
    logic [pkg_reg::REG_WIDTH-1:0] mem[pkg_reg::REG_DEPTH];

    initial begin
        mem[0] = 0;     // %0 is never written, so it always reads as 0
    end

    always @ (posedge clk) begin
        if (reg_file.op == pkg_reg::REG_WRITE && reg_file.addr_in != 0) begin
            mem[reg_file.addr_in] <= reg_file.data_in;
        end
        reg_file.data_out0 <= mem[reg_file.addr_out0];
        reg_file.data_out1 <= mem[reg_file.addr_out1];
    end

endmodule
