/*
 * NuBus controller
 * 
 * Autor: Valeriya Pudova (hww.github.io)
 */

module nubus
  #(
    // Activate simple or standard memory map
    //   1 - slots mapped as $s000 0000
    //   0 - standart scheme $as00 0000
    //       where:
    //       a - is SLOTS_ADDRESS
    //       s - is the slot ID
    parameter SIMPLE_MAP = 0,
    // All slots area starts with addrss $FXXX XXXX
    parameter SLOTS_ADDRESS  = 'hF, 
    // All superslots starts at $9000 0000
    parameter SUPERSLOTS_ADDRESS = 'h9, 
    // Watch dog timer bits. Master controller will terminate transfer
    // after (2 ^ WDT_W) clocks
    parameter WDT_W = 8,
    // Local space of card start and end addres. For example 0-5
    // makes local space address $00000000-$50000000
    parameter LOCAL_SPACE_EXPOSED_TO_NUBUS = 0,
    parameter LOCAL_SPACE_START = 0,
    parameter LOCAL_SPACE_END = 5,
    // Generate parity without ECC memory
    parameter NON_ECC_PARITY = 1
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
    input         mem_error,
    input         mem_tryagain,

    /* Processor bus signals connected to processor */

    output        cpu_valid,
    input [31:0]  cpu_addr,
    input [31:0]  cpu_wdata,
    input         cpu_ready,
    output [ 3:0] cpu_write,
    output [31:0] cpu_rdata,
    input         cpu_lock,
    input         cpu_eclr,
    output [3:0]  cpu_errors,
    /* Debugging and utilities */

    // Access to slot area
    output        mem_stdslot,
    // Access to superslot area ($sXXXXXXX where <s> is card id)
    output        mem_super,
    // Access to local memory on the card
    output        mem_local,
    // Access to any memory on the card
    output        mem_myslot
  );

  `include "nubus_inc.sv"

   // ==========================================================================
   // Colock and reset
   // ==========================================================================

   wire           nub_clk = ~nub_clkn;
   wire           nub_reset = ~nub_resetn;

   // ==========================================================================
   // Global signals 
   // ==========================================================================

   wire           arb_grant;
   wire           slv_master, slv_slave, slv_tm1n, slv_tm0n, slv_ackcyn, slv_myslotcy;
   wire           mst_adrcyn, mst_dtacyn, mst_lockedn, mst_arbdn, mst_timeout, 
                  mst_busyn, mst_ownern, mst_arbcyn;
   wire unsigned [31:0] cpu_ad;
   wire unsigned [31:0] slv_addr;
   wire           cpu_tm0n, nub_qstoen, drv_tmoen, cpu_tm1n, cpu_tm0, 
                  cpu_masterd, cpu_error;
   wire [1:0]     mis_errorn;
   wire           drv_mstdn;
   
   // ==========================================================================
   // Drive NuBus address-data line 
   // ==========================================================================

   wire        cpu_adsel = ~mst_adrcyn | ~mst_dtacyn & ~cpu_tm1n;
   // Select nubus data signals
   wire [31:0] nub_ad    = cpu_adsel  ? cpu_ad : mem_rdata;

   // When 1 - drive the NuBus AD lines 
   wire        nub_adoe  =   slv_slave  & slv_tm1n
               /*SLAVE read of card*/
               | cpu_valid & ~mst_adrcyn
               /*MASTER address cycle*/
	       | ~mst_ownern & ~mst_dtacyn & ~cpu_tm1n
               /*MASTER data cycle, when writing*/
                       ;
   // Output to nubus the 
   assign nub_adn  = nub_adoe ? ~nub_ad : 'bZ;

   // ==========================================================================
   // Parity checking
   // ==========================================================================

   wire        parity   = ~^nub_adn;
   wire        nub_noparity = NON_ECC_PARITY & ~nub_adoe & ~nub_spvn & nub_spn == parity;

   assign nub_spn  = NON_ECC_PARITY &  nub_adoe ? parity : 'bZ;
   assign nub_spvn = NON_ECC_PARITY &  nub_adoe ? 0 : 'bZ;

   // ==========================================================================
   // Arbiter Interface
   // ==========================================================================

   nubus_arbiter UArbiter
     (
      .idn(nub_idn),
      .arbn(nub_arbn),
      .arbcyn(mst_arbcyn),
      .grant(arb_grant)
      );

   // ==========================================================================
   // Slave FSM
   // ==========================================================================

   nubus_slave 
     #(
       .SLOTS_ADDRESS (SLOTS_ADDRESS), 
       .SUPERSLOTS_ADDRESS(SUPERSLOTS_ADDRESS),
       .SIMPLE_MAP(SIMPLE_MAP),
       .LOCAL_SPACE_EXPOSED_TO_NUBUS(LOCAL_SPACE_EXPOSED_TO_NUBUS),
       .LOCAL_SPACE_START(LOCAL_SPACE_START),
       .LOCAL_SPACE_END(LOCAL_SPACE_END)

       )
   USlave
     (
      .nub_clkn(nub_clkn), // Clock
      .nub_resetn(nub_resetn), // Reset
      .nub_idn(nub_idn), // Card ID
      .nub_adn(nub_adn), // Address Data
      .nub_startn(nub_startn), // Transfer start
      .nub_ackn(nub_ackn), // Transfer end
      .nub_tm1n(nub_tm1n), // Transition mode 1 (Read/Write)
      .nub_tm0n(nub_tm0n),
      .mem_ready(mem_ready),
      .mem_myslot(mem_myslot),
      .mst_timeout(mst_timeout),

      .slv_slave_o(slv_slave), // Slave mode
      .slv_tm1n_o(slv_tm1n), // Latched transition mode 1 (Read/Write)
      .slv_tm0n_o(slv_tm0n),
      .slv_ackcyn_o(slv_ackcyn), // Acknowlege
      .slv_addr_o(slv_addr), // Slave address
      .slv_stdslot_o(mem_stdslot), // Starndard slot
      .slv_super_o(mem_super), // Superslot
      .slv_local_o(mem_local), // Local area
      .slv_myslotcy_o(slv_myslotcy) // Any slot
      );
    
   // ==========================================================================
   // Master FSM
   // ==========================================================================

   nubus_master
    #(
      .WDT_W(WDT_W)
     ) 
     UMaster
     (
      .nub_clkn(nub_clkn), // Clock
      .nub_resetn(nub_resetn), // Reset
      .nub_rqstn(nub_rqstn), // Bus request
      .nub_startn(nub_startn), // Start transfer
      .nub_ackn(nub_ackn), // End of transfer
      .arb_grant(arb_grant), // Grant access
      .cpu_lock(cpu_lock), // Address line
      .cpu_masterd(cpu_valid), // Master mode (delayed)

      .mst_lockedn_o(mst_lockedn), // Locked or not tranfer
      .mst_arbdn_o(mst_arbdn),
      .mst_busyn_o(mst_busyn),
      .mst_ownern_o(mst_ownern), // Address or data transfer
      .mst_dtacyn_o(mst_dtacyn), // Data strobe
      .mst_adrcyn_o(mst_adrcyn), // Address strobe
      .mst_arbcyn_o(mst_arbcyn), // Arbiter enabled
      .mst_timeout_o(mst_timeout)
   );

   // ==========================================================================
   // Driver Nubus
   // ==========================================================================

   nubus_driver UNDriver
     (
      .slv_ackcyn(slv_ackcyn), // Achnowlege
      .mst_arbcyn(mst_arbcyn), // Arbiter enabled
      .mst_adrcyn(mst_adrcyn), // Address strobe
      .mst_dtacyn(mst_dtacyn), // Data strobe
      .mst_ownern(mst_ownern), // Master is owner of the bus
      .mst_lockedn(mst_lockedn), // Locked or not transfer
      .mst_tm1n(cpu_tm1n), // Address ines
      .mst_tm0n(cpu_tm0n), // Address ines
      .mst_timeout(mst_timeout),
      .mis_errorn(mis_errorn),
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

   nubus_cpubus UCPUBus
     (
      .nub_clkn(nub_clkn),
      .nub_resetn(nub_resetn),
      .mst_adrcyn(mst_adrcyn),
      .cpu_valid(cpu_valid),
      .cpu_write(cpu_write),
      .cpu_addr(cpu_addr),
      .cpu_wdata(cpu_wdata),
      .cpu_ad_o(cpu_ad),
      .cpu_tm1n_o(cpu_tm1n),
      .cpu_tm0n_o(cpu_tm0n),
      .cpu_error_o(cpu_error),
      .cpu_masterd_o(cpu_masterd)
      );

   // ==========================================================================
   // Memory Interface
   // ==========================================================================
   
   nubus_membus UMemBus 
     (
      .nub_clkn(nub_clkn), // Clock
      .nub_resetn(nub_resetn), // Reset
      .nub_adn(nub_adn),

      .slv_tm1n(slv_tm1n),
      .slv_tm0n(slv_tm0n),
      .slv_myslotcy(slv_myslotcy),
      .slv_addr(slv_addr),

      .mem_addr_o(mem_addr),
      .mem_write_o(mem_write),
      .mem_wdata_o(mem_wdata) 
      );
   
   // ==========================================================================
   // Errrors Interface
   // ==========================================================================
   
   nubus_errors UErrorsReg
     (
      .nub_clkn(nub_clkn),
      .nub_resetn(nub_resetn),
      .mst_timeout(mst_timeout),
      .mem_error(mem_error),
      .mem_tryagain(mem_tryagain),
      .nub_noparity(nub_noparity),
      .cpu_error(cpu_error),
      .cpu_eclr(cpu_eclr),
      .cpu_errors_o(cpu_errors),
      .mis_errorn_o(mis_errorn)
      );



endmodule

