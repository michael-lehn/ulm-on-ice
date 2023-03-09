`include "pkg_ram.sv"

module dev_ram_switch (
    input logic select,
    if_ram.server ram0,
    if_ram.server ram1,
    if_ram.client ram
);

    always_comb begin
	case (select)
	    1'b0:
		begin
		    ram.op = ram0.op;
		    ram.data_type = ram0.data_type;
		    ram.addr = ram0.addr;
		    ram.data_in = ram0.data_in;

		    ram0.data_out = ram.data_out;
		    ram1.data_out = 0;
		end
	    1'b1:
		begin
		    ram.op = ram1.op;
		    ram.data_type = ram1.data_type;
		    ram.addr = ram1.addr;
		    ram.data_in = ram1.data_in;

		    ram0.data_out = 0;
		    ram1.data_out = ram.data_out;
		end
	endcase
	
    end

endmodule
