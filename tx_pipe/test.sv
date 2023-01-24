module test(
    input logic CLK,
    output logic TX
);

    integer posedgeCount = 0;

    always_ff @ (posedge CLK) begin
	posedgeCount <= posedgeCount + 1;
    end

    //
    // reset fifo
    //

    logic rst = 0;

    //
    // write to fifo (print "ABC....Z\n\rABC...Z\n\r....")
    //

    logic full;
    logic push_back = 0;
    logic [7:0] data_in = "A";

    always_ff @ (posedge CLK) begin
	push_back <= !push_back && !full;
	if (push_back) begin
	    if (data_in >= "A" && data_in < "Z") begin
		data_in <= data_in + 1;
	    end
	    else if (data_in == "Z") begin
		data_in <= "\n";
	    end
	    else if (data_in == "\n") begin
		data_in <= "\r";
	    end
	    else begin
		data_in <= "A";
	    end
	end
    end

    //
    // error handling / debugging
    //

    logic error;

    `ifndef SYNTHESIS
    always_ff @ (posedge CLK) begin
	if (error) begin
	    $display("posedgeCount = %d: error", posedgeCount);
	end
    end
    `endif

    tx_pipe #(
	.CLK_FREQ(12_000_000),
	.BAUD(9_600)
    ) tx_pipe1 (
	.clk(CLK),
	.rst(rst),
	.push_back(push_back),
	.data_in(data_in),
	.full(full),
	.tx(TX),
	.error(error)
    );



endmodule

