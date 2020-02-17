/* verilator lint_off UNUSED */
/*
 * NBDRVR2, NuBus bus driver
 * 
 * The NuBus driver PAL (NBDRVR PAL) is responsible for driving all NuBus signals. 
 * As in the miscellaneous PAL, NBDRVR decodes the state machine signals to determine
 * the timing for these signals.
 *
 * This version corresponds to the "offical" test card.
 *
 * NOTE: due to overlap of states, RQST* is held one state too
 * long at end of a LOCKED transaction. However, this causes no "real"
 * problem. If we are the last winner of a RQST set, then the only
 * result is that new RQST-ers are held off by one CLK. If there is
 * another RQST-er left in our set, then it will still be driving RQST.
 * It will properly arbitrate due to the NULL-ATTENTION and become the
 * next winner. Thus, in either case, nothing "bad" happens.
 *
 * Version 1.3 reflects change to ADRCY which is now held low only
 * during the address cycle of a transaction .
 */

module nubus_driver
  (
   input  slv_ackcyn, // Achnowlege
   input  mst_arbcyn, // Arbiter enabled
   input  mst_adrcyn, // Address strobe
   input  mst_dtacyn, // Data strobe
   input  mst_ownern, // Master is owner of the bus
   input  mst_lockedn, // Locked or not transfer
   input  mst_tm1n, // Address ines
   input  mst_tm0n, // Address ines
   input  mst_timeout,
   output nub_tm0n_o, // Transfer mode
   output nub_tm1n_o, // Transfer mode
   output nub_ackn_o, // Achnowlege
   output nub_startn_o, // Transfer start
   output nub_rqstn_o, // Bus request
   output nub_rqstoen_o, // Bus request enable
   output drv_tmoen_o, // Transfer mode enable
   output drv_mstdn_o // Guess: Slave sends /ACK. Master responds with /MSTDN, which allows slave to clear /ACK and listen for next transaction.
   );
   
   wire   tm0, tm1, tmoe, ack, rqstoe, mstdn;

   // ----------------------------------------------------
   // Rename or invert inputs
   // ----------------------------------------------------

   wire   ackcy = ~slv_ackcyn | mst_timeout;
   wire   arbcy = ~mst_arbcyn;
   wire   adrcy = ~mst_adrcyn;
   wire   dtacy = ~mst_dtacyn;
   wire   owner = ~mst_ownern;
   wire   locked = ~mst_lockedn;
   wire   timeout = mst_timeout;
   wire   tm1n = mst_tm1n;
   wire   tm0n = mst_tm0n;
   
   // ----------------------------------------------------
   // Drive outputs
   // ----------------------------------------------------

   assign drv_tmoen_o  = ~tmoe;
   assign nub_tm0n_o   = tmoe  ? ~tm0 : 'bZ;
   assign nub_tm1n_o   = tmoe  ? ~tm1 : 'bZ;
   assign nub_ackn_o   = tmoe  ? ~ack : 'bZ;
   assign nub_startn_o = owner ? dtacy : 'bZ;
   assign nub_rqstn_o  = rqstoe  ?  0 : 'bZ;

   assign drv_mstdn_o  = mstdn;
   assign rqstoen_o    = ~rqstoe;
   
   // ----------------------------------------------------
   // Main logic
   // ----------------------------------------------------
      
   // Bus request enable
   assign rqstoe        = arbcy & ~adrcy  			
			/* hold untill START* for normal case */
                        | arbcy & locked
			/* hold untill NULL-ATTN for locked case */
			;

   // Transfer mode enable				
   assign tmoe          = ackcy
                        /* SLAVE response */
		        | owner & arbcy & ~dtacy 	
                        /* we own bus, while not waiting for ACK */
                        ;
   // Transfer acknowlege				
   assign ack		= ackcy 
			/* slave response */
	         	| owner & ~adrcy
			/* for NULL-ATTN, LOCK-ATTN */
	         	;
   // Transmission mode 
   assign tm1		= ackcy & ~timeout				
			/* SLAVE response */
		     	| owner & adrcy & ~tm1n
		     	/* START* at address cycle */
		     	| owner & ~adrcy & ~locked & ~timeout
                        /* set for NULL-ATTN */
                        ;
   // Transmission mode 
   assign tm0		= ackcy		
			/* SLAVE response */
		     	| owner & adrcy & ~tm0n	
		     	/* START* at address cycle */
		     	| owner & ~adrcy			
			/* always set for xxx-ATTN */
			;
   
   assign mstdn 	= owner & ~locked & dtacy * ack
			/* done all tail end of normal cycle */
               	        | owner & ~locked & arbcy & ~adrcy & dtacy 
               	        /* done dor locked cases */
               	        ;

endmodule
