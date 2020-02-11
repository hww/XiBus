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
   output myslot_o,
   output tm1n_o,
   output tm0n_o,
   output ackcy_o // Acknowlege
   );

   reg        slaven, mastern, myslotl, tm1nl, tm0nl, ackcy;
   
   assign slave_o = ~slaven;
   assign master_o = ~mastern;
   assign myslot_o = myslotl;
   assign tm1n_o = tm1nl;
   assign tm0n_o = tm0nl;
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
	 tm1nl <= 1;
         tm0nl <= 1;
	 ackcy <= 0;
         myslotl <= 0;
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

         // tm1n is 1 - reading 
	 tm1nl    <= reset
		      | tm1n & start & ~ack & myslot
		      /*setting term, during address cycle*/
		      | tm1nl & ~start
		      | tm1nl & ack /*this slave ack*/
		      | tm1nl & ~myslot
		      /*holding terms*/
		      ;
         
         tm0nl     <= reset
		      | tm0n & start & ~ack & myslot
		      /*setting term, during address cycle*/
		      | tm0nl & ~start
		      | tm0nl & ack /*this slave ack*/
		      | tm0nl & ~myslot
		      /*holding terms*/
		      ;

         myslotl   <= reset
                      | myslot & start & ~ack & ~reset
                      /*setting */
                      | myslotl & ~ack & ~reset;
         
      end
   end

endmodule
