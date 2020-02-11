 module ic74als651 (
	//input oeab,			// A-to-B output enable input
	//input oeba,			// B-to-A output enable input
	input cpab, 		// A-to-B clock input (rising edge)
	input cpba, 		// A-to-B clock input (rising edge)
	input sab,			// A-to-B select input (b = sab ? rega : a)
	input sba,			// B-to-A select input (a = sba ? regb : b)
	input[7:0] a_i,		// A inputs
	output[7:0] a_o,	// A outputs
	input[7:0] b_i,		// B inputs
	output[7:0] b_o,	// B outputs
	input rst_n
);


logic[7:0] rega;
logic[7:0] regb;

always @(posedge cpab or negedge rst_n) begin : proc_a
	if(~rst_n) begin
		 rega <= 0;
	end else begin
		 rega <= a_i;
	end
end

always @(posedge cpba or negedge rst_n) begin : proc_b
	if(~rst_n) begin
		 regb <= 0;
	end else begin
		 regb <= b_i;
	end
end

assign a_o = sba ? regb : b_i; /* A output the regiter B or inputs B */
assign b_o = sab ? rega : a_i; /* B output the regiter A or inputs A */

endmodule