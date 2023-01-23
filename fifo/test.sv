module test(
    input logic CLK,
    output logic [7:0] out,
    output logic error
);

    integer posedgeCount = 0;

    always_ff @ (posedge CLK) begin
	posedgeCount <= posedgeCount + 1;
    end

    //
    // reset fifo
    //

    logic rst = 0;
    always_ff @ (posedge CLK) begin
	rst <= 0;
	case (posedgeCount)
	    32'd10: rst <= 1;
	    32'd14: rst <= 1;
	    32'd17: rst <= 1;
	    32'd21: rst <= 1;
	    32'd26: rst <= 1;
	endcase
    end

    //
    // write to fifo
    //

    logic full;
    logic push_back = 0;
    logic [7:0] data_in = "A";

    always_ff @ (posedge CLK) begin
	push_back <= 0;
	case (posedgeCount)
	    32'd1: push_back <= !full;
	    32'd4: push_back <= !full;
	    32'd6: push_back <= !full;
	    32'd11: push_back <= !full;
	    32'd15: push_back <= !full;
	    32'd18: push_back <= !full;
	    32'd27: push_back <= !full;
	endcase
	if (push_back) begin
	    data_in <= data_in + 1;
	end
    end

    //
    // read from fifo
    //

    logic empty;
    logic pop_front = 0;
    logic [7:0] data_out;
    assign out = data_out;

    always_ff @ (posedge CLK) begin
	pop_front <= !pop_front && !empty;

	case (posedgeCount)
	    32'd12: pop_front <= 1;
	    32'd13: pop_front <= 1;
	    32'd14: pop_front <= 1;
	    32'd16: pop_front <= 1;
	    32'd20: pop_front <= 1;
	    32'd29: pop_front <= 1;
	    32'd30: pop_front <= 1;
	endcase
    end

    fifo fifo1(
	.clk(CLK),
	.rst(rst),
	.pop_front(pop_front),
	.push_back(push_back),
	.data_in(data_in),
	.data_out(data_out),
	.empty(empty),
	.full(full),
	.error(error)
    );

    always_ff @ (posedge CLK) begin
	if (rst) begin
	    $display("posedgeCount = %d: reset", posedgeCount);
	end
	else if (pop_front || push_back) begin
	    $display("posedgeCount = %d: push_back = %d, pop_front = %d",
		     posedgeCount, push_back, pop_front);
	end

	if (error) begin
	    $display("posedgeCount = %d: error! empty = %d, full = %d\n",
		     posedgeCount, empty, full);
	end
    end

endmodule
