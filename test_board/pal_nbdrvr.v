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

module pal_nbdrvr
(
	input logic ACKCY,		// Achnowlege
	input logic ARBCY,		// Arbiter enabled
	input logic ADRCY,		// Address strobe
	input logic DTACY,		// Data strobe
	input logic OWNER,		// Master is owner of the bus
	input logic LOCKED,		// Locked or not transfer
	input logic A19D11L,	// Address ines
	input logic A18D10L,	// Address ines
	output logic TM0,		// Transfer mode
	output logic TM1,		// Transfer mode
	output logic tmoe,		// Transfer mode enable
	output logic ACK,		// Achnowlege
	output logic START,		// Transfer start
	output logic RQST, 		// Bus request
	output logic rqstoe,	// Bus request enable
	output logic MSTDN,		// Guess: Slave sends /ACK. Master responds with /MSTDN, which allows slave to clear /ACK and listen for next transaction.
);

// Bus request enable
assign rqstoe	= ARBCY & ~ADRCY  			
				/* hold untill START* for normal case */
			    + ARBCY & LOCKED 			
			    /* hold untill NULL-ATTN for locked case */
				;
// Bus request				
assign RQST 	= rqstoe;

// Transfer start
assign START 	= OWNER & ~DTACY			
				/* START* for all non-DTA cycles */
				;

// Transfer mode enable				
assign tmoe 	= ACKCY 						
				/* SLAVE response */
			  	| OWNER & ARBCY & ~DTACY 	
			  	/* we own bus, while not waiting for ACK */
				;
// Transfer acknowlege				
assign ACK 		= tmoe 
				& (
					ACKCY				
					/* slave response */
	         		| OWNER & ~ADRCY
					/* for NULL-ATTN, LOCK-ATTN */
	         	  )
	         	;
// Transmission mode 
assign TM1 		= tmoe & (ACKCY				
				/* SLAVE response */
		     	| OWNER & ADRCY & A19D11L 	
		     	/* START* at address cycle */
		     	| OWNER & ~ADRCY & ~LOCKED)
				/* set for NULL-ATTN */
				;
// Transmission mode 
assign TM0 		= tmoe & (ACKCY				
				/* SLAVE response */
		     	| OWNER & ADRCY & A18D10L 	
		     	/* START* at address cycle */
		     	| OWNER & ~ADRCY;			
				/* always set for xxx-ATTN */
				;
assign MSTDN 	= OWNER & ~LOCKED & DTACY * ACK 				 
				/* done all tail end of normal cycle */
               	| OWNER & ~LOCKED & ARBCY & ~ADRCY & DTACY 
               	/* done dor locked cases */
               	;

endmodule : pal_nbdrvr