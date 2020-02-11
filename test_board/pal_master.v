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

module pal_master 
	(
		input CLK,		// Clock
		input RESET, 	// Reset
		input MASTER,	// Master mode 
		input MASTERD, 	// Master mode (delayed)
		input GRANT,	// Grant access
		input RQST,		// Bus request
		input START, 	// Start transfer
		input ACK, 		// End of transfer
		input A17D9,	// Address line
		output A17D9L,	// Address line
		output LOCKED, 	// Locked or not tranfer
		output arbdn, 	
		output busy, 	
		output OWNER, 	// Address or data transfer
		output DTACY, 	// Data strobe
		output ADRCY, 	// Address strobe
		output ARBCY	// Arbiter enabled
	);


	always @(posedge CLK or negedge RESET) begin : proc_master
		if(~RESET) begin
			ARBCY 	<= 0;
			ADRCY 	<= 0;
			DTACY 	<= 0;
			OWNER 	<= 0;
			busy 	<= 0;
			arbdn 	<= 0;
			LOCKED 	<= 0;
			A17D9L 	<= 0;
		end else begin

			ARBCY 	<= MASTER & MASTERD & ~OWNER & ~ARBCY & ~ADRCY & ~DTACY & ~RQST
					/*wait for RQST& unsserted, while idle*/
			       	| MASTER & ARBCY & ~OWNER & ~RESET
					/*non-locking, hold for START&*/
			       	| MASTER & ARBCY & LOCKED & ~RESET
					/*holding for locked access*/
					;
			ADRCY 	<= ~A17D9L & ~OWNER & ARBCY & arbdn & GRANT & ~busy & ~START
			       	| ~A17D9L & ~OWNER & ARBCY & arbdn & GRANT &  busy * ACK
					/*START& if not locking*/
			       	| OWNER & LOCKED & ~ADRCY & ~DTACY & MASTER & ~RESET
					/*START& for locking case, after LOCK-ATTN*/
					;
			DTACY 	<= ADRCY
					/*assert after START&*/
			       	| DTACY & ~ACK & MASTER & ~RESET
					/*hold until ACK&*/
					;
			OWNER 	<= ARBCY & arbdn & GRANT & ~busy & ~START
			       	| ARBCY & arbdn & GRANT &  busy	 & ACK
					/*when bus is free, we own it next*/
			       	| OWNER & ADRCY & MASTER & ~RESET
					/*hold before DTACY*/
			       	| OWNER & DTACY & ~ACK & MASTER & ~RESET
					/*non-locking, wait until ACK* */
			       	| OWNER & LOCKED & MASTER * RESET
					/*for LOCKing case, hold for NULL-ATTN*/
					;
			busy 	<= ~busy & START & ~ACK
					/*beginning of transaction*/
			      	| busy & ~ACK &  & ~RESET
					/*hold during cycle*/
					;
			arbdn 	<= ARBCY & ~START
					/*when arbitrating, force delay*/
					;
			LOCKED 	<= A17D9L & ARBCY & arbdn & GRANT & ~busy & ~START
			    	| A17D9L & ARBCY & arbdn & GRANT &  busy & ACK
					/*set for LOCK-ATN*/
					| LOCKED & ~DTACY & MASTER & ~RESET
					| LOCKED & DTACY & ~ACK * MASTER & ~RESET
					/*clear on NULL-ATN*/
					;
			A17D9L 	<= ~(
					  ~A17D9 & ~MASTER
					/*latching term*/
					| ~A17D9L & MASTER
					/*holding term*/
					| LOCKED
					/*clearing term, prevent another ADRCY*/
					);
		end
	end

endmodule:pal_master