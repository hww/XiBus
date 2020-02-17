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
    // Activate simple or standard memory map
    //   1 - slots mapped as $s000 0000
    //   0 - standart scheme $as00 0000
    //       where:
    //       a - is SLOTS_ADDRESS
    //       s - is the slot ID
    parameter SIMPLE_MAP = 0,
    // All slots starts with address $FXXX XXXX
    parameter SLOTS_ADDRESS  = 'hF, 
    // All superslots starts at $9000 0000
    parameter SUPERSLOTS_ADDRESS = 'h9 ,
    // Local space of card start and end addres. For example 0-5
    // makes local space address $00000000-$50000000
    parameter LOCAL_SPACE_EXPOSED_TO_NUBUS = 1,
    parameter LOCAL_SPACE_START = 0,
    parameter LOCAL_SPACE_END = 5
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
   input         mst_timeout,
   output        slv_slave_o, // Slave mode
   output        slv_myslot_o,
   output        slv_tm1n_o,
   output        slv_tm0n_o,
   output        slv_ackcyn_o, // Acknowlege
   output        mem_valid_o,
   output [3:0]  mem_write_o,
   output [31:0] mem_addr_o,
   output [31:0] mem_wdata_o,
   output        mem_slot_o, // Slot selected
   output        mem_super_o,
   output        mem_local_o
   );

   reg        slaven, mastern, myslotl, tm1nl, tm0nl, mem_valid;
   reg [31:0]     mem_addr;

   wire       mem_slot, mem_super;
   wire       clk = nub_clkn;
   wire       reset = ~nub_resetn;
   wire       start = ~nub_startn;
   wire       slave = ~slaven;
   wire       ack = ~nub_ackn;
   wire       tm1n = nub_tm1n;
   wire       tm0n = nub_tm0n;
   wire       myslot = mem_slot | mem_super;
   wire       ackcy = mem_ready & myslot & ~start
                    | mst_timeout & myslot & ~start;
   
   assign mem_slot_o = myslot;
   assign mem_super_o = mem_super;
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
		                 | slaven & ~myslot
		                 /*holding; DeMorgan of START & ~ACK & MYSLOT*/
		                 | slave & ackcy
		                 /*clearing term*/
		                 ;

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

   // ==========================================================================
   // Slave address recorded at the NuBus start cycle.
   // ==========================================================================


  
   always @(negedge nub_clkn or posedge reset) begin : proc_ad_slave
      if (reset) begin
         mem_addr <= 0;
      end else if (~nub_startn) begin
         mem_addr <= ~nub_adn;
      end
   end

   // ==========================================================================
   // Slot selection and expansion selection
   // ==========================================================================

   // Card ID
   wire [3:0] nub_id = ~nub_idn;
   wire std_slots_area = mem_addr[31:28] == SLOTS_ADDRESS;
   wire std_super_area = mem_addr[31:28] >= SUPERSLOTS_ADDRESS & ~std_slots_area;

   // Superslots $FS00 0000, where S is a slot ID
   wire std_slot  = std_slots_area & nub_id == mem_addr[27:24];
   // Superslots $S000 0000, where S is a slot ID
   wire std_super = std_super_area & nub_id == mem_addr[31:28];
   // Local area of this card if it is exposed to NuBus
   wire std_local = LOCAL_SPACE_EXPOSED_TO_NUBUS
                  & mem_addr[31:28] >= LOCAL_SPACE_START 
                  & mem_addr[31:28] <= LOCAL_SPACE_END;

   assign mem_slot  = SIMPLE_MAP ? mem_addr[31:28] == nub_id : std_slot | std_super | std_local;
   assign mem_super = SIMPLE_MAP ? 0 : std_super;
   assign mem_local_o = SIMPLE_MAP ? 0 : std_local;

   // ==========================================================================
   // Write strobes
   // ==========================================================================
   
   wire a1n = ~mem_addr[1];
   wire a0n = ~mem_addr[0];
   wire write = mem_valid & ~slv_tm1n_o;
   
   assign mem_wdata_o = ~nub_adn;

   assign mem_write_o[3]   =   write & ~a1n & ~a0n & ~slv_tm0n_o
                             /* Byte 3 */
                             | write & ~a1n & ~a0n &  slv_tm0n_o
                             /* Half 1 */
                             | write &  a1n &  a0n &  slv_tm0n_o
                             /* Word */
                             ;
   assign mem_write_o[2]   =   write & ~a1n &  a0n & ~slv_tm0n_o
                             /* Byte 2 */
                             | write & ~a1n & ~a0n &  slv_tm0n_o
                             /* Half 1 */
                             | write &  a1n &  a0n &  slv_tm0n_o
                             /* Word */
                             ;
   assign mem_write_o[1]   =   write &  a1n & ~a0n & ~slv_tm0n_o
                             /* Byte 1 */
                             | write &  a1n & ~a0n &  slv_tm0n_o
                             /* Half 0 */
                             | write &  a1n &  a0n &  slv_tm0n_o
                             /* Word */
                             ;
   assign mem_write_o[0]   =   write &  a1n &  a0n & ~slv_tm0n_o
                             /* Byte 0 */
                             | write &  a1n & ~a0n &  slv_tm0n_o
                             /* Half 0 */
                             | write &  a1n &  a0n &  slv_tm0n_o
                             /* Word */
                             ;
                             

   
endmodule
