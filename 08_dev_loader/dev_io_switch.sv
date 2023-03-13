module dev_io_switch (
    input logic select,
    if_io.server io0,
    if_io.server io1,
    if_io.client io
);

    always_comb begin
	case (select)
	    1'b0:
		begin
		    io.getc_pop = io0.getc_pop;
		    io.putc_push = io0.putc_push;
		    io.putc_char = io0.putc_char;

		    io0.inbuf_full = io.inbuf_full;
		    io0.getc_en = io.getc_en;
		    io0.getc_char = io.getc_char;
		    io0.putc_push_done = io.putc_push_done;

		    io1.inbuf_full = 0;
		    io1.getc_en = 0;
		    io1.getc_char = 0;
		    io1.putc_push_done = 0;
		end
	    1'b1:
		begin
		    io.getc_pop = io1.getc_pop;
		    io.putc_push = io1.putc_push;
		    io.putc_char = io1.putc_char;

		    io1.inbuf_full = io.inbuf_full;
		    io1.getc_en = io.getc_en;
		    io1.getc_char = io.getc_char;
		    io1.putc_push_done = io.putc_push_done;

		    io0.inbuf_full = 0;
		    io0.getc_en = 0;
		    io0.getc_char = 0;
		    io0.putc_push_done = 0;
		end
	endcase
    end

endmodule
