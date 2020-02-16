module nubus
  #(
    parameter SLOTS_ADDRESS  = 'hF, // All slots starts with address 0xFXXXXXXX
    parameter EXPANSION_MASK = 'hC, 
    parameter EXPANSION_ADDR = 'h0
    )

   (
    /* NuBus signals */

    input         nub_clkn, // Clock (rising is driving edge, faling is sampling) 
    input         nub_resetn, // Reset
    input [ 3:0]  nub_idn, // Slot Identificatjon

    inout         nub_pfwn, // Power Fail Warning
    inout [31:0]  nub_adn, // Address/Data
    inout         nub_tm0n, // Transfer Mode
    inout         nub_tm1n, // Transfer Mode
    inout         nub_startn, // Start
    inout         nub_rqstn, // Request
    inout         nub_ackn, // Acknowledge
    inout [ 3:0]  nub_arbn, // Arbitration

    inout         nub_nmrqn, // Non-Master Request
    inout         nub_spn, // System Parity
    inout         nub_spvn, // System Parity Valid

    /* Memory bus signals connected to a memory, accesible by nubus or processor */

    output        mem_valid,
    output [31:0] mem_addr,
    output [31:0] mem_wdata,
    output [ 3:0] mem_write,
    input         mem_ready,
    input [31:0]  mem_rdata,

    /* Processor bus signals connected to processor */

    output        cpu_valid,
    input [31:0]  cpu_addr,
    input [31:0]  cpu_wdata,
    input         cpu_ready,
    output [ 3:0] cpu_write,
    output [31:0] cpu_rdata,
    input         cpu_lock,

    /* Debugging and utilities */

    // This card mapped to only one slot
    output        mem_myslot,
    // This card can have memory space in below xF0XXXXX addresses
    output        mem_myexp
  );

   // ==========================================================================
   // Colock and reset
   // ==========================================================================

   wire           nub_clk = ~nub_clkn;
   wire           nub_reset = ~nub_resetn;

   wire           slv_master, slv_slave;
   wire           slv_tm1n, slv_tm0n;
   wire           mst_adrcy, mst_dtacy;
   wire           cpu_tm1n, cpu_tm0;
   wire slv_ackcyn, slv_myslot;
  wire mst_locked, mst_arbdn,mst_busy;
  
   // ==========================================================================
   // Processor address bus buffers
   // ==========================================================================


   
   wire        mst_owner;
   wire [31:0] cpu_ad;
   wire        cpu_adsel = mst_adrcy | mst_dtacy & ~cpu_tm1n;
   // Select nubus data signals
   wire [31:0] nub_ad   = cpu_adsel  ? cpu_ad : mem_rdata;
   
   // When 1 - drive the NuBus AD lines 
   assign nub_adoe =   slv_slave  & slv_tm1n
                       /*SLAVE read of card*/
                       | cpu_valid & mst_adrcy
                       /*MASTER address cycle*/
	                     | mst_owner & mst_dtacy & ~cpu_tm1n
                       /*MASTER data cycle, when writing*/
                       ;
   // Output to nubus the 
   assign nub_adn = nub_adoe ? ~nub_ad : 'bZ;



   // ==========================================================================
   // Arbiter Interface
   // ==========================================================================

   wire           mst_arbcy, arb_grant;

   nubus_arbiter UArbiter
     (
      .idn(nub_idn),
      .arbn(nub_arbn),
      .arbcyn(~mst_arbcy),
      .grant(arb_grant)
      );

   // ==========================================================================
   // Slave FSM
   // ==========================================================================

   nubus_slave 
   #(
      .SLOTS_ADDRESS (SLOTS_ADDRESS), 
      .EXPANSION_MASK(EXPANSION_MASK), 
      .EXPANSION_ADDR(EXPANSION_ADDR)
   )
   USlave
     (
      .nub_clkn(nub_clkn), // Clock
      .nub_resetn(nub_resetn), // Reset
      .nub_startn(nub_startn), // Transfer start
      .nub_ackn(nub_ackn), // Transfer end
      .nub_tm1n(nub_tm1n), // Transition mode 1 (Read/Write)
      .nub_tm0n(nub_tm0n),
      .nub_adn(nub_adn),
      .nub_idn(nub_idn),
      .mem_ready(mem_ready),

      .mstdn(drv_mstdn),

      .slave_o(slv_slave), // Slave mode
      .tm1n_o(slv_tm1n), // Latched transition mode 1 (Read/Write)
      .tm0n_o(slv_tm0n),
      .ackcyn_o(slv_ackcyn), // Acknowlege
      .myslot_o(slv_myslot), 
      .mem_valid_o(mem_valid),
      .mem_addr_o(mem_addr),
      .mem_write_o(mem_write),
      .mem_wdata_o(mem_wdata), 
      .mem_myslot(mem_myslot), // Slot selected
      .mem_myexp(mem_myexp) // Slot selected
      );

   // ==========================================================================
   // Master FSM
   // ==========================================================================

   nubus_master UMaster
     (
      .nub_clkn(nub_clkn), // Clock
      .nub_resetn(nub_resetn), // Reset
      .nub_rqstn(nub_rqstn), // Bus request
      .nub_startn(nub_startn), // Start transfer
      .nub_ackn(nub_ackn), // End of transfer
      .arb_grant(arb_grant), // Grant access
      .cpu_lock(cpu_lock), // Address line
      .cpu_valid(cpu_valid), // Master mode (delayed)

      .locked_o(mst_locked), // Locked or not tranfer
      .arbdn_o(mst_arbdn),
      .busy_o(mst_busy),
      .owner_o(mst_owner), // Address or data transfer
      .dtacy_o(mst_dtacy), // Data strobe
      .adrcy_o(mst_adrcy), // Address strobe
      .arbcy_o(mst_arbcy) // Arbiter enabled
   );

   // ==========================================================================
   // Driver Nubus
   // ==========================================================================

   wire cpu_tm0n, nub_qstoen, drv_tmoen;
  
   nubus_driver UNDriver
     (
      .slv_ackcyn(slv_ackcyn), // Achnowlege
      .mst_arbcyn(~mst_arbcy), // Arbiter enabled
      .mst_adrcyn(~mst_adrcy), // Address strobe
      .mst_dtacyn(~mst_dtacy), // Data strobe
      .mst_ownern(~mst_owner), // Master is owner of the bus
      .mst_lockedn(~mst_locked), // Locked or not transfer
      .mst_tm1n(cpu_tm1n), // Address ines
      .mst_tm0n(cpu_tm0n), // Address ines

      .nub_tm0n_o(nub_tm0n), // Transfer mode
      .nub_tm1n_o(nub_tm1n), // Transfer mode
      .nub_ackn_o(nub_ackn), // Achnowlege
      .nub_startn_o(nub_startn), // Transfer start
      .nub_rqstn_o(nub_rqstn), // Bus request
      .nub_rqstoen_o(nub_qstoen), // Bus request enable
      .drv_tmoen_o(drv_tmoen), // Transfer mode enable
      .drv_mstdn_o(drv_mstdn) // Guess: Slave sends /ACK. Master responds with /MSTDN, which allows slave to clear /ACK and listen for next transaction.
      );

   // ==========================================================================
   // CPU Interface
   // ==========================================================================

   assign cpu_rdata = ~nub_adn;
   assign cpu_ready = ~nub_ackn & nub_startn;
   
   cpu_bus UCPUBus
     (
      .adrcy(mst_adrcy),
      .cpu_write(cpu_write),
      .cpu_addr(cpu_addr),
      .cpu_wdata(cpu_wdata),

      .cpu_ad_o(cpu_ad),
      .tm1n_o(cpu_tm1n),
      .tm0n_o(cpu_tm0n),
      .error_o(cpu_error)
   );
   
endmodule

