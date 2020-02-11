/*
 * SLAVE, NuBus slave controller
 * 
 * The slave PAL (SLAVE PAL) is the state machine for slave accesses to the NTC. 
 * It also  latches the state of / ADl9-/ AD18, which are used by other PALs.
 *
 * Notes: This version corresponds to the new pin-out for the "official"
 * test card. It also supports the ROM, with the ROMOE signal .
 */
module nubus_slave 
  (
   input  nub_clkn, // Clock
   input  nub_resetn, // Reset	
   input  nub_startn, // Transfer start
   input  nub_ackn, // Transfer end
   input  nub_tm1n, // Transition mode 1 (Read/Write)
   input  nub_tm0n, //
   input  mem_ready,
   input  myslot, // Slot selected
   input  mstdn,
     
   output slave_o, // Slave mode
   output master_o, // MAster mode
   output myslotln_o,
   output tmn1_o,
   output tmn0_o,
   output ackcy_o // Acknowlege
   );

   reg        slaven, mastern, myslotln, tmn1, tmn0, ackcy;
   
   assign slave_o = ~slaven;
   assign master_o = ~mastern;
   assign myslotln_o = myslotln;
   assign tmn1_o = tmn1;
   assign tmn0_o = tmn0;
   assign ackcy_o = ackcy;

   wire       clk = nub_clkn;
   wire       reset = ~nub_resetn;   
   wire       master = mastern;
   wire       ack = ~nub_ackn;
   wire       start = ~nub_startn;
   wire       tm1n = nub_tm1n;
   wire       tm0n = nub_tm0n;
   
   always @(posedge clk or posedge reset) begin : proc_slave
      if (reset) begin
	 slaven <= 1;
	 mastern <= 1;
	 tmn1 <= 1;
         tmn0 <= 1;
	 ackcy <= 0;
         myslotln <= 1;
      end else begin
	 slaven    <= reset
		       /*initialization*/
		       | slaven & ~start
		       | slaven & ack
		       | slaven & ~myslot
		       /*holding; DeMorgan of START & ~ACK & MYSLOT*/
		       | ~slaven & ackcy
		       /*clearing term*/
		       ;

	 mastern   <= reset
		       /*initialization*/
		       | mastern & slaven
                       /*holding*/
		       | master & mstdn
		       /*clearing term, at end of MASTER cycle*/
		       ;

	 ackcy      <= mem_ready;

         // tmn1 is 1 - reading 
	 tmn1     <= reset
		      | tm1n & start & ~ack & myslot
		      /*setting term, during address cycle*/
		      | tmn1 & ~start
		      | tmn1 & ack /*this slave ack*/
		      | tmn1 & ~myslot
		      /*holding terms*/
		      ;
         
         tmn0     <= reset
		      | tm0n & start & ~ack & myslot
		      /*setting term, during address cycle*/
		      | tmn0 & ~start
		      | tmn0 & ack /*this slave ack*/
		      | tmn0 & ~myslot
		      /*holding terms*/
		      ;

         myslotln  <= reset
                      | myslot & start & ~ack
                      /*setting */
                      | myslotln & ~start
                      | myslotln & ack;
         
      end
   end

endmodule
