/*
 * MASTER2, NuBus master controller for test card.
 * 
 * The master PAL (MASTER PAL) is responsible for controlling a master transaction on the
 * bus. It idles until it detects that both the MASTER and MASTERD (delayed MASTER)
 * input signals are true. It will then go through a state sequence to perform the transaction.
 * The master PAL can execute two types of transactions: normal and locked. The state
 * sequence is slightly different for each case. See the timing diagram, Figure 10-1, for the
 * sequences of each. Note that the diagram shows the shortest slave response. In actual use,
 * most accesses hold in the wait state UDTACY asserted) while awaiting an / ACK for more
 * than one cycle.

 * Note
 * This version is for new pin-out of the "official" test card.
 * MasterA handles the delayed feature of the card. Version 1.1 also
 * fixes the timing for arbitration.
 *
 * This version is designed to work with the new ARB2 arbitration
 * PAL, which has a different sense for GRANT. It also fixes a minor
 * timing overhang on DTACY for 2-cycle transactions.
 *
 * Version 1.3 fixes 2-cycle write by only allowing ADRCY for
 * 1 clock; we originally had overlap to try to eliminate decoding
 * glitches.
 */

module nubus_master 
  (
   input  nub_clkn, // Clock
   input  nub_resetn, // Reset
   input  nub_rqstn, // Bus request
   input  nub_startn, // Start transfer
   input  nub_ackn, // End of transfer
   input  slv_master, // Slv_master mode
   input  arb_grant, // Grant access
   input  cpu_lock, // Locked by CPU
   input  cpu_valid, // Slv_master mode access

   output locked_o, // Locked or not tranfer
   output arbdn_o,
   output busy_o,
   output owner_o, // Address or data transfer
   output dtacy_o, // Data strobe
   output adrcy_o, // Address strobe
   output arbcy_o,	// Arbiter enabled
   output tm1n_o,
   output tm0n_o
   );

   reg    locked, arbdn, busy, owner, dtacy, adrcy, arbcy;

   assign locked_o = locked;
   assign arbdn_o = arbdn;
   assign busy_o = busy;
   assign owner_o = owner;
   assign dtacy_o = dtacy;
   assign adrcy_o = adrcy;
   assign arbcy_o = arbcy;

   wire   clkn = nub_clkn;
   wire   reset = ~nub_resetn;
   wire   ack = ~nub_ackn;
   wire   start = ~nub_startn;
   wire   rqst = ~nub_rqstn;

   assign tm1n_o = 0;
   assign tm0n_o = 0;
 
   always @(posedge clkn or posedge reset) begin : proc_slv_master
      if(reset) begin
	       arbcy 	<= 0;
	       adrcy 	<= 0;
	       dtacy 	<= 0;
	       owner 	<= 0;
	       busy 	<= 0;
	       arbdn 	<= 0;
	       locked <= 0;
      end else begin

	 arbcy  <= slv_master & cpu_valid & ~owner & ~arbcy & ~adrcy & ~dtacy & ~rqst
		   /*wait for RQST& unsserted, while idle*/
		   | slv_master & arbcy & ~owner & ~reset
		   /*non-locking, hold for START&*/
		   | slv_master & arbcy & locked & ~reset
		   /*holding for locked access*/
		   ;
	 adrcy  <=   ~cpu_lock & ~owner & arbcy & arbdn & arb_grant & ~busy & ~start
		   | ~cpu_lock & ~owner & arbcy & arbdn & arb_grant &  busy * ack
		   /*START& if not locking*/
		   | owner & locked & ~adrcy & ~dtacy & slv_master & ~reset
		   /*START& for locking case, after LOCK-ATTN*/
		   ;
	 dtacy  <= adrcy
		   /*assert after START&*/
		   | dtacy & ~ack & slv_master & ~reset
		   /*hold until ACK&*/
		   ;
	 owner  <=   arbcy & arbdn & arb_grant & ~busy & ~start
		   | arbcy & arbdn & arb_grant &  busy & ack
		   /*when bus is free, we own it next*/
		   | owner & adrcy & slv_master & ~reset
		   /*hold before DTACY*/
		   | owner & dtacy & ~ack & slv_master & ~reset
		   /*non-locking, wait until ACK* */
		   | owner & locked & slv_master * reset
		   /*for LOCKing case, hold for NULL-ATTN*/
		   ;
	 busy   <= ~busy & start & ~ack
		   /*beginning of transaction*/
		   | busy & ~ack & ~reset
		   /*hold during cycle*/
		   ;
	 arbdn  <= arbcy & ~start
		   /*when arbitrating, force delay*/
		   ;
         // Slv_master register D9 is the "locked" bitxs
	 locked <=   cpu_lock & arbcy & arbdn & arb_grant & ~busy & ~start
		   | cpu_lock & arbcy & arbdn & arb_grant &  busy & ack
		   /*set for LOCK-ATN*/
		   | locked & ~dtacy & slv_master & ~reset
		   | locked &  dtacy & ~ack & slv_master & ~reset
		   /*clear on NULL-ATN*/
		   ;

      end
   end


   
endmodule
