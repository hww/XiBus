/*
 * SLAVE, NuBus slave controller
 * 
 * The slave PAL (SLAVE PAL) is the state machine for slave accesses to the NTC. 
 * It also  latches the state of / ADl9-/ AD18, which are used by other PALs.
 *
 * Notes: This version corresponds to the new pin-out for the "official"
 * test card. It also supports the ROM, with the ROMOE signal .
 */
module nubus_pal_slave 
	(
		input CLK,		// Clock
		input RESET,	// Reset	
		input START,	// Transfer start
		input ACK,		// Transfer end
		input MYSLOT,	// Slot selected
		input MSTDN,
		input TM1,		// Transition mode 1 (Read/Write)
		input A19D11,
		input A18D10,

		output SLAVE, 	// Slave mode
		output MASTER, 	// MAster mode
		output A18D10L, 
		output A19D11L, 
		output TM1L,
		output ROMOE,	// ROM output enable
		output romoe1,	// ROM output enable delayed
		output ACKCY	// Acknowlege
	);


	always @(posedge CLK or posedge RESET) begin : proc_slave
		if (~RESET) begin
			SLAVE <= 0;
			MASTER <= 0;
			ROMOE <= 0;
			ROMOEL <= 0;
			ACKCY <= 0;
			TM1L <= 0;
			A19DIIL <= 0;
			A18D10L <= 0;
		end else begin
		   	SLAVE 		<= ~(RESET
				      	/*initialization*/
				      	| ~SLAVE & ~START
				      	| ~SLAVE & ACK
				      	| ~SLAVE & ~MYSLOT
				      	/*holding; DeMorgan of START & ~ACK & MYSLOT*/
				      	| SLAVE & ACKCY
			 		  	/*clearing term*/
						);

		   	MASTER 		<= ~(RESET
					    /*initialization*/
					    | ~MASTER & ~SLAVE
					    | ~MASTER & ~TM1L
					    | ~MASTER & ~A19D11L
					    | ~MASTER & A18D10L
					    /*holding term; DeMorgan of: SLAVE & TM1L & A19011L & ~A18D10L */
					    | MASTER & MSTON
				   		/*clearing term, at end of MASTER cycle*/
						);

			ROMOE 		<= START & ~ACK & MYSLOT & ~TM1 & A19D11 & A18D10 & ~RESET
						/*latching term, when decoding a READ to us*/
						| ROMOE & ~ACKCY & ~RESET
						/* holding term thru access */
						;

			romoe1 		<= ROMOE
						/* simply a delayed. ROMOE for cycle timing */
						;
			ACKCY 		<= START & ~ACK & MYSLOT & TM1
						/*fast cycle for WRITES*/
						| ~ACKCY & SLAVE & ~ROMOE
						/*slow cycle for non-ROM READS*/
						| ~ACKCY & ROMOE & romoel & ~A19DIIL
						/*slower cycle for ROM*/
						;

			TM1L 		<= ~(RESET
						| ~TM1 & START & ~ACK & MYSLOT
						/*setting term, during address cycle*/
						| ~TMIL & ~START
						| ~TMIL & ACK
						| ~TMIL & ~MYSLOT
						/*holding terms*/
						);

			A19D11L		<= ~(~A19D11 & START & ~ACK & MYSLOT & ~MASTER
						/*setting term, during SLAVE address cycle*/
						| ~A19DIIL & SLAVE & ~TMIL
						| ~A19DIIL & SLAVE & TMIL & ~A19DIIL
						| ~A19DIIL & SLAVE & TMIL & A18D10L
						/*holding terms for SLAVE accesses*/
						| ROMOE & romoe1
						/* timing term for ROM reads */
						| ~A19D11 & SLAVE & TMIL & A19DIIL & ~A18D10L
						/*setting term for MASTER start*/
						| ~A19DIIL & MASTER
						/*holding term for MASTER*/
						);

			A18D10L <= 	~(~A18D10 & START & ~ACK & MYSLOT
						/*setting term, during address cycle*/
						| ~A18D10L & SLAVE & ~TMIL
						| ~A18D10L & SLAVE & TMIL & ~A19DIIL
						| ~A18D10L & SLAVE & TMIL & A18D10L
						/*holding terms for SLAVE accesses*/
						| ~A18D10 & SLAVE & TMIL & A19DIIL & ~A18D10L
						/*setting term for MASTER start*/
						| ~A18D10L & MASTER
						/*holding term for MASTER*/
						);
		end
	end



endmodule
