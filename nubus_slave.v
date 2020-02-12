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
   output myslot_o,
   output tm1n_o,
   output tm0n_o,
   output ackcy_o, // Acknowlege
   output mem_valid_o
   );

   reg        slaven, mastern, myslotl, tm1nl, tm0nl, ackcy, mem_valid;
   
   assign slave_o = ~slaven;
   assign myslot_o = myslotl;
   assign tm1n_o = tm1nl;
   assign tm0n_o = tm0nl;
   assign ackcy_o = ackcy;
   assign mem_valid_o = mem_valid;
   
   wire       clk = nub_clkn;
   wire       reset = ~nub_resetn;   
   wire       start = ~nub_startn;
   wire       ack = ~nub_ackn;
   wire       tm1n = nub_tm1n;
   wire       tm0n = nub_tm0n;

   wire       slave = ~slaven;
   
   always @(posedge clk or posedge reset) begin : proc_slave
      if (reset) begin
	 slaven <= 1;
	 tm1nl <= 1;
         tm0nl <= 1;
	 ackcy <= 0;
         myslotl <= 0;
         mem_valid <= 0;
      end else begin
	 slaven   <= reset
		     /*initialization*/
		     | slaven & ~start
		     | slaven & ack
		     | slaven & ~myslot
		     /*holding; DeMorgan of START & ~ACK & MYSLOT*/
		     | slave & ackcy
		     /*clearing term*/
		     ;

	 ackcy    <=  start & mem_ready & myslot & ~ackcy
                      | ~start & mem_ready & myslot & ~ackcy;

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
         
         mem_valid  <= start & ~ack & myslot * ~reset
                       /*latching terms for memory access*/
                      | mem_valid * ~ackcy;
      end
   end

endmodule
