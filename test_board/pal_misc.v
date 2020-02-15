/* 
 * MISC2, local bus~transceiver controls.
 * 
 * The miscellaneous PAL (MISC PAL) is used to decode the state machine signals and drive
 * on-card devices. The outputs control the gating of the 651's, 374's, and so forth.
 */
/* verilator lint_off UNUSED */
module pal_misc
(
  input logic CLK,      // Clock
  input logic SLAVE,    // Slave transaction
  input logic MASTER,   // Master transaction
  input logic TM1L,     // Transfer mode
  input logic ADRCY,    // Address tranfer strobe
  input logic DTACY,    // Data tranfer strobe
  input logic ROMOE,    // ROM enable
  input logic A19D11L,  // Address lines
  input logic A18D10L,  // Address lines

  output logic GAB210,
  output logic GBA,   
  output logic CAB, 
  output logic ACLK,    // Address Register Clock
  output logic AOE,     // Address Register Output Enable
  output logic DCLK,    // Data Register Clock
  output logic DOE,     // Data Register Output Enable
  output logic GAB3
);

// Buffer
assign GBA    = SLAVE & ~TM1L 						
              /*SLAVE read of card*/
              | MASTER & ADRCY 					
              /*MASTER address cycle*/
		          | MASTER & DTACY & A19D11L/*TM1*/
              /*MASTER data cycle, when writing*/
              ;
assign CAB    = ~(SLAVE | ~CLK)
     					/* DeMorgan of: ~SLAVE & CLK */
              ;
assign GAB3   = ~(SLAVE & ~TM1L 					
              /*any SLAVE read*/
              | MASTER & ~ADRCY & ~DTACY 			
              /*MASTER loading address*/
              | MASTER & A19D11L/*TM1*/)
              /*MASTER write*/
              ;    
assign GAB210 = ~(SLAVE & ~TM1L & ~ROMOE		
              /*SLAVE, non-ROM, read*/
              | MASTER & ~ADRCY & ~DTACY 		
              /*MASTER loading address*/
              | MASTER & A19D11L/*TM1*/)
              /*MASTER write*/
              ;
// Address register clock              
assign ACLK   = SLAVE & CLK & TM1L & ~A19D11L & ~A18D10L
              & ~ROMOE
              /*SLAVE write to address reg*/
              ;
// Address register output enable
assign AOE    = SLAVE & ~TM1L & ~A19D11L & ~A18D10L
              & ~ROMOE 							
              /*SLAVE read of address reg*/
              | MASTER & ~ADRCY & ~DTACY
              /*MASTER address cycle*/
              ;
// Data register clock
assign DCLK   = SLAVE & CLK & TM1L & ~A19D11L & A18D10L
              & ~ROMOE							
              /*SLAVE write to data reg*/
      		    | MASTER & DTACY & ~A19D11L /*/TM1*/ & CLK
              /*MASTER read*/
              ;
// Data register ouput enable              
assign DOE    = SLAVE & ~TM1L & ~A19D11L & A18D10L
              & ~ROMOE 							/*SLAVE read of data reg*/
              | MASTER & DTACY & A19D11L/*TM1*/
              /*MASTER write data*/
              ;
endmodule : pal_misc
