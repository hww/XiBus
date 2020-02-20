/*
 * SLAVE, NuBus slave controller
 * 
 * The slave state machine for slave accesses to the card's local space. 
 *
 * Notes:
 *
 * Autor: Valeriya Pudova (hww.github.io)
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
    parameter unsigned SLOTS_ADDRESS  = 'hF, 
    // All superslots starts at $9000 0000
    parameter unsigned SUPERSLOTS_ADDRESS = 'h9 ,
    // Local space of card start and end addres. For example 0-5
    // makes local space address $00000000-$50000000
    parameter LOCAL_SPACE_EXPOSED_TO_NUBUS = 1,
    parameter unsigned [3:0] LOCAL_SPACE_START = 0,
    parameter unsigned [3:0] LOCAL_SPACE_END = 5
    )
  (
   input                  nub_clkn, // Clock
   input                  nub_resetn, // Reset
   input unsigned [3:0]   nub_idn, // Card ID
   input unsigned [31:0]  nub_adn,
   input                  nub_startn, // Transfer start
   input                  nub_ackn, // Transfer end
   input                  nub_tm1n, // Transition mode 1 (Read/Write)
   input                  nub_tm0n, //
   input                  mem_myslot, // Memory bus selected by address
   input                  mem_ready, // Complete memory transfer
   input                  mst_timeout, // Master timeout event


   output                 slv_slave_o, // Slave mode
   output                 slv_tm1n_o,
   output                 slv_tm0n_o,
   output                 slv_ackcyn_o, // Acknowlege
   output unsigned [31:0] slv_addr_o,
   output                 slv_stdslot_o, // Slot selected
   output                 slv_super_o,// Superslot selected
   output                 slv_local_o, // Local memory selected
   output                 slv_myslotcy_o // Any slot or local memory selected
   );

   // NuBus signals 

   wire   clk = nub_clkn;
   wire   reset = ~nub_resetn;
   wire   start = ~nub_startn;
   wire   ack = ~nub_ackn;
   wire   tm1n = nub_tm1n;
   wire   tm0n = nub_tm0n;

   // Slave FSM signals
   
   reg    slaven, myslotcy, tm1nl, tm0nl;
   
   // ==========================================================================
   // Acknowlege
   // ==========================================================================

   wire   myslot; // assigned at end of this file
   
   wire   ackcy = mem_ready & myslotcy
                | mst_timeout & myslotcy;

   // ==========================================================================
   // Slave state machine 
   // ==========================================================================

   always @(posedge clk or posedge reset) begin : proc_slave
      if (reset) begin
	 slaven <= 1;
	 tm1nl <= 1;
         tm0nl <= 1;
         myslotcy <= 0;
      end else begin
	 slaven   <= reset
		     /*initialization*/
		     | slaven & ~start
		     | slaven & ack
		     | slaven & ~myslot
		     /*holding; DeMorgan of START & ~ACK & MYSLOT*/
		     | ~slaven & ackcy
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

         tm0nl    <= reset
		     | tm0n & start & ~ack & myslot
		     /*setting term, during address cycle*/
		     | tm0nl & ~start
		     | tm0nl & ack /*this slave ack*/
		     | tm0nl & ~myslot
		     /*holding terms*/
		     ;
        
         myslotcy  <= myslot & start & ~ack 
                     /*setting */
                     | myslotcy & ~ack
                     ;
      end
   end
   
   assign slv_slave_o = ~slaven;
   assign slv_tm1n_o = tm1nl;
   assign slv_tm0n_o = tm0nl;
   assign slv_ackcyn_o = ~ackcy;
   assign slv_myslotcy_o = myslotcy;
   
   // ==========================================================================
   // Slave address recorded at the NuBus start cycle.
   // ==========================================================================

   reg unsigned [31:0] addr;
   
   always @(negedge nub_clkn or posedge reset) begin : proc_ad_slave
      if (reset) begin
         addr <= 0;
      end else if (~nub_startn & nub_ackn) begin
         addr <= ~nub_adn;
      end
   end

   assign slv_addr_o = addr;
   
   // ==========================================================================
   // Slot selection and expansion selection
   // ==========================================================================

   // Card ID
   wire [3:0] nub_id = ~nub_idn;
   wire std_slots_area = addr[31:28] == SLOTS_ADDRESS;
   wire std_super_area = addr[31:28] >= SUPERSLOTS_ADDRESS & ~std_slots_area;

   // Superslots $FS00 0000, where S is a slot ID
   wire std_slot  = std_slots_area & nub_id == addr[27:24];
   // Superslots $S000 0000, where S is a slot ID
   wire std_super = std_super_area & nub_id == addr[31:28];
   // Local area of this card if it is exposed to NuBus
   wire std_local = LOCAL_SPACE_EXPOSED_TO_NUBUS
                  & addr[31:28] >= LOCAL_SPACE_START 
                  & addr[31:28] <= LOCAL_SPACE_END;
   // Simple slot selection
   wire simple_slot  = addr[31:28] == nub_id;

   // Used internaly to generate myslotcy (a synchronyzed version of myslot)
   assign myslot        = std_slot | std_super | std_local;

   // Depends on mode (simple or not) set a selected slot
   assign slv_stdslot_o = SIMPLE_MAP ? simple_slot & myslotcy : std_slot & myslotcy;
   assign slv_super_o   = SIMPLE_MAP ? 0 : std_super & myslotcy;
   assign slv_local_o   = SIMPLE_MAP ? 0 : std_local & myslotcy;
   
endmodule
