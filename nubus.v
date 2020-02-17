module nubus
  #(
    // Activate simple or standard memory map
    //   1 - slots mapped as $s000 0000
    //   0 - standart scheme $as00 0000
    //       where:
    //       a - is SLOTS_ADDRESS
    //       s - is the slot ID
    parameter SIMPLE_MAP = 0,
    // All slots area starts with address $FXXX XXXX
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

    /* Processor bus signals connected to processor */

    output        cpu_valid,
    input [31:0]  cpu_addr,
    input [31:0]  cpu_wdata,
    input         cpu_ready,
    output [ 3:0] cpu_write,
    output [31:0] cpu_rdata,
    input         cpu_lock,
    input         cpu_errors_clr,
    output [3:0]  cpu_errors,
    /* Debugging and utilities */

    // This card mapped to only one slot
    output        mem_slot,
    // This card can have memory space in below xF0XXXXX addresses
    output        mem_super
  );

   // ==========================================================================
   // Colock and reset
   // ==========================================================================

   wire           nub_clk = ~nub_clkn;
   wire           nub_reset = ~nub_resetn;

   // ==========================================================================
   // Global signals 
   // ==========================================================================

   wire           arb_grant;
   wire           slv_master, slv_slave, slv_tm1n, slv_tm0n, slv_ackcyn, slv_myslot;
   wire           mst_adrcyn, mst_dtacyn, mst_lockedn, mst_arbdn, mst_timeout, 
                  mst_busyn, mst_ownern, mst_arbcyn;
   wire [31:0]    cpu_ad;
   wire           cpu_tm0n, nub_qstoen, drv_tmoen, cpu_tm1n, cpu_tm0, cpu_masterd;

   // ==========================================================================
   // Drive NuBus address-data line 
   // ==========================================================================

   wire        cpu_adsel = ~mst_adrcyn | ~mst_dtacyn & ~cpu_tm1n;
   // Select nubus data signals
   wire [31:0] nub_ad   = cpu_adsel  ? cpu_ad : mem_rdata;

   // When 1 - drive the NuBus AD lines 
   assign nub_adoe =   slv_slave  & slv_tm1n
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

   assign parity   = ~^nub_adn;
   assign nub_spn  = NON_ECC_PARITY &  nub_adoe ? parity : 'bZ;
   assign nub_spvn = NON_ECC_PARITY &  nub_adoe ? 0 : 'bZ;
   wire   sp_error = NON_ECC_PARITY & ~nub_adoe & ~nub_spvn & nub_spn == parity;

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
      .nub_startn(nub_startn), // Transfer start
      .nub_ackn(nub_ackn), // Transfer end
      .nub_tm1n(nub_tm1n), // Transition mode 1 (Read/Write)
      .nub_tm0n(nub_tm0n),
      .nub_adn(nub_adn),
      .nub_idn(nub_idn),
      .mem_ready(mem_ready),
      .drv_mstdn(drv_mstdn),
      .mst_timeout(mst_timeout),
      .slv_slave_o(slv_slave), // Slave mode
      .slv_tm1n_o(slv_tm1n), // Latched transition mode 1 (Read/Write)
      .slv_tm0n_o(slv_tm0n),
      .slv_ackcyn_o(slv_ackcyn), // Acknowlege
      .slv_myslot_o(slv_myslot), 
      .mem_valid_o(mem_valid),
      .mem_addr_o(mem_addr),
      .mem_write_o(mem_write),
      .mem_wdata_o(mem_wdata), 
      .mem_slot_o(mem_slot), // Slot selected
      .mem_super_o(mem_super) // Slot selected
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

   cpu_bus 
   #(
   )
   UCPUBus
     (
      .mst_adrcyn(mst_adrcyn),
      .cpu_write(cpu_write),
      .cpu_addr(cpu_addr),
      .cpu_wdata(cpu_wdata),
      .cpu_ad_o(cpu_ad),
      .cpu_tm1n_o(cpu_tm1n),
      .cpu_tm0n_o(cpu_tm0n),
      .cpu_error_o(cpu_error)

   );

   // ==========================================================================
   // Error Register
   // ==========================================================================

   reg [4:0] errors;

   always @(negedge nub_clkn or negedge nub_resetn) : proc_cpu_errors
   begin
	if (~nub_resetn) begin
	  errors <= 0;
        end else begin
          if (cpu_errors_clr) begin
	     errors <= 0;
          end else begin
          // NuBus timeout flag
	  errors[0] <= errors[0] 
                     | mst_timeot & ~mst_ackn;
          // NuBus partity error
	  errors[1] <= errors[1] 
                     | sp_error & ~nub_spv;
          // CPU access to unaligned data
	  errors[2] <= errors[2] 
                     | cpu_error & cpu_valid;
          end
        end
   end
   assign cpu_errors = errors;

endmodule

