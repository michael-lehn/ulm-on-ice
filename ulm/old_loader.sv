module loader (
    input logic clk,
    output if_dev_ram ram,
    output logic done
);

    logic [pkg_ram::RAM_LONG-1:0] prog[13];
    integer num_loaded;

    initial begin
	num_loaded = 0;

	prog[ 0] = 32'h10100020;
	prog[ 1] = 32'h20210000;
	prog[ 2] = 32'h12110001;
	prog[ 3] = 32'h14020000;
	prog[ 4] = 32'h03000003;
	prog[ 5] = 32'h30200000;
	prog[ 6] = 32'h04FFFFFB;
	prog[ 7] = 32'h01000000;
	prog[ 8] = 32'h68656C6C;
	prog[ 9] = 32'h6F2C2077;
	prog[10] = 32'h6F726C64;
	prog[11] = 32'h2120F09F;
	prog[12] = 32'h8DBA0000;
    end

    initial begin
	ram.addr = 0;
	ram.op = pkg_ram::RAM_NOP;
	ram.size = pkg_ram::RAM_LONG;
    end

    logic done_r = 0;
    assign done = done_r;

    always_ff @ (posedge clk) begin
	if (!done) begin
	    case (ram.op)
		pkg_ram::RAM_NOP:
		    begin
			ram.op <= pkg_ram::RAM_STORE;
		    end
		pkg_ram::RAM_STORE:
		    begin
			ram.op <= pkg_ram::RAM_NOP;
		    end
		default:
		    ;
	    endcase
	end
    end

    always_ff @ (posedge clk) begin
	if (!done && ram.op == pkg_ram::RAM_NOP) begin
	    if (num_loaded == $size(prog)) begin
		done_r <= 1;
	    end
	    else begin
		ram.data_in <= {32'h0, prog[num_loaded]};
		num_loaded <= num_loaded + 1;
	    end
	end
    end

    always_ff @ (posedge clk) begin
	if (!done && ram.op == pkg_ram::RAM_STORE) begin
	    ram.addr <= ram.addr + 4;
	end
    end



endmodule
