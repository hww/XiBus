module ic74als161 (
	input clk,    	// Clock (rising) (2) 
	input rst_n,  	// Asynchronous reset active low (1) 
	input enable_p, // Load (7) 
	input enable_t, // Count increment (10)  
	input[3:0] d,	// Data input (3,4,5,6)
	output[3:0] q,	// Outputs (14,13,12,11) 
	output carryout	// Carry out (15)
);

always @(posedge clk or negedge rst_n) begin : proc_counter
	if(~rst_n) begin
		q <= 0;
	end else begin
		if (enable_p) begin
			q <= d;
		end else if (enable_t) begin 
			q <= q + 1;
		end else begin
			q <= q;
		end
	end
end

assign carryout = enable_t & q[0] & q[1] & q[2] & q[3];

endmodule