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
    #(
    parameter SLOTS_ADDRESS  = 'hF, // All slots starts with address 0xFXXXXXXX
    parameter EXPANSION_MASK = 'hC, 
    parameter EXPANSION_ADDR = 'h0
    )
  (
   input         nub_clkn, // Clock
   input         nub_resetn, // Reset	
   input         nub_startn, // Transfer start
   input         nub_ackn, // Transfer end
   input         nub_tm1n, // Transition mode 1 (Read/Write)
   input         nub_tm0n, //
   input [31:0]  nub_adn,
   input [3:0]   nub_idn,
   input         mem_ready,
   input         drv_mstdn,

   output        slv_slave_o, // Slave mode
   output        slv_myslot_o,
   output        slv_tm1n_o,
   output        slv_tm0n_o,
   output        slv_ackcyn_o, // Acknowlege
   output        mem_valid_o,
   output [3:0]  mem_write_o,
   output [31:0] mem_addr_o,
   output [31:0] mem_wdata_o,
   output        mem_myslot, // Slot selected
   output        mem_myexp
   );

   reg        slaven, mastern, myslotl, tm1nl, tm0nl, mem_valid;

   wire       clk = nub_clkn;
   wire       reset = ~nub_resetn;
   wire       start = ~nub_startn;
   wire       ack = ~nub_ackn;
   wire       tm1n = nub_tm1n;
   wire       tm0n = nub_tm0n;

   wire       slave = ~slaven;
   wire       ackcy = mem_ready & mem_myslot & ~start;

   assign slv_slave_o = ~slaven;
   assign slv_myslot_o = myslotl;
   assign slv_tm1n_o = tm1nl;
   assign slv_tm0n_o = tm0nl;
   assign mem_valid_o = mem_valid;
   assign slv_ackcyn_o = ~ackcy;
   assign mem_addr_o = mem_addr;
   
   always @(posedge clk or posedge reset) begin : proc_slave
      if (reset) begin
	       slaven <= 1;
	       tm1nl <= 1;
         tm0nl <= 1;
         myslotl <= 0;
         mem_valid <= 0;
      end else begin
	       slaven   <= reset
		                 /*initialization*/
		                 | slaven & ~start
		                 | slaven & ack
		                 | slaven & ~mem_myslot
		                 /*holding; DeMorgan of START & ~ACK & MYSLOT*/
		                 | slave & ackcy
		                 /*clearing term*/
		                 ;

         // tm1n is 1 - reading 
	       tm1nl    <= reset
		                 | tm1n & start & ~ack & mem_myslot
		                 /*setting term, during address cycle*/
		                 | tm1nl & ~start
		                 | tm1nl & ack /*this slave ack*/
		                 | tm1nl & ~mem_myslot
		                 /*holding terms*/
		                 ;

         tm0nl     <= reset
		                  | tm0n & start & ~ack & mem_myslot
		                  /*setting term, during address cycle*/
		                  | tm0nl & ~start
		                  | tm0nl & ack /*this slave ack*/
		                  | tm0nl & ~mem_myslot
		                  /*holding terms*/
		                  ;

         myslotl   <= reset
                      | mem_myslot & start & ~ack & ~reset
                      /*setting */
                      | myslotl & ~ack & ~reset;

         mem_valid  <= start & ~ack & mem_myslot * ~reset
                       /*latching terms for memory access*/
                       | mem_valid * ~ackcy;
      end
  end

   // ==========================================================================
   // Slave address recorded at the NuBus start cycle.
   // ==========================================================================

   reg [31:0]     mem_addr;

  
   always @(negedge nub_clkn or posedge reset) begin : proc_ad_slave
      if (reset) begin
         mem_addr <= 0;
      end else if (~nub_startn) begin
         mem_addr <= ~nub_adn;
      end
   end

   // ==========================================================================
   // Write strobes
   // ==========================================================================
   
   wire a1ln = ~mem_addr[1];
   wire a0ln = ~mem_addr[0];
   wire write = mem_valid & ~slv_tm1n_o;
   
   assign mem_wdata_o = ~nub_adn;

   assign mem_write_o[3]   =   write & ~a1ln & ~a0ln & ~slv_tm0n_o
                             /* Byte 3 */
                             | write & ~a1ln & ~a0ln &  slv_tm0n_o
                             /* Half 1 */
                             | write &  a1ln &  a0ln &  slv_tm0n_o
                             /* Word */
                             ;
   assign mem_write_o[2]   =     write & ~a1ln &  a0ln & ~slv_tm0n_o
                             /* Byte 2 */
                             | write & ~a1ln & ~a0ln &  slv_tm0n_o
                             /* Half 1 */
                             | write &  a1ln &  a0ln &  slv_tm0n_o
                             /* Word */
                             ;
   assign mem_write_o[1]   =     write &  a1ln & ~a0ln & ~slv_tm0n_o
                             /* Byte 1 */
                             | write &  a1ln & ~a0ln &  slv_tm0n_o
                             /* Half 0 */
                             | write &  a1ln &  a0ln &  slv_tm0n_o
                             /* Word */
                             ;
   assign mem_write_o[0]   =     write &  a1ln &  a0ln & ~slv_tm0n_o
                             /* Byte 0 */
                             | write &  a1ln & ~a0ln &  slv_tm0n_o
                             /* Half 0 */
                             | write &  a1ln &  a0ln &  slv_tm0n_o
                             /* Word */
                             ;
                             
   // ==========================================================================
   // Slot selection and expansion selection
   // ==========================================================================

   // Card ID
   wire [3:0] nub_id = ~nub_idn;
   assign mem_myslot = nub_id == mem_addr[27:24] & mem_addr[31:28] == SLOTS_ADDRESS;
   assign mem_myexp = (mem_addr[31:28] & EXPANSION_MASK) == EXPANSION_ADDR;
   
endmodule
