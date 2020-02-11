//`include "nubus_arbiter.v"
//`include "nubus_driver.v"
//`include "nubus_master.v"
//`include "nubus_slave.v"

/* verilator lint_off UNUSED */
/* verilator lint_off IMPLICIT */
/* verilator lint_off UNOPT */

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
    output [ 3:0] mem_wstrb,
    input         mem_ready,
    input [31:0]  mem_rdata,

    /* Processor bus signals connected to processor */

    output        cpu_valid,
    input [31:0]  cpu_addr,
    input [31:0]  cpu_wdata,
    input         cpu_ready,
    output [ 3:0] cpu_wstrb,
    output [31:0] cpu_rdata,
    input         cpu_lock,

    /* Debugging and utilities */

    // This card mapped to only one slot
    output        mem_myslot,
    // This card can have memory space in below xF0XXXXX addresses
    output        mem_myexp
  );

`include "nubusdefs.sv"


   // ==========================================================================
   // Colock and reset
   // ==========================================================================

   wire           nub_clk = ~nub_clkn;
   wire           nub_reset = ~nub_resetn;
   wire           nub_ad = ~nub_adn;

   // ==========================================================================
   // Processor address bus buffers
   // ==========================================================================

   reg [31:0]     address;
   wire           cab, wab, sab;

   always @(posedge cab or posedge nub_reset) begin : proc_read_nub_ad
      if (nub_reset) begin
         address <= 0;
      end else if (wab) begin
         address <= nub_ad;
      end
   end

   // ==========================================================================
   // Slot selection and expansion selection
   // ==========================================================================

   // Card ID
   wire [ 3:0]    nub_id;

   assign nub_id = ~nub_idn;
   assign mem_myslot = nub_id == address[27:24] & address[31:28] == SLOTS_ADDRESS;
   assign mem_myexp = (address[31:28] & EXPANSION_MASK) == EXPANSION_ADDR;

   // ==========================================================================
   // Arbiter Interface
   // ==========================================================================

   wire           arbcy, grant;

   nubus_arbiter UArbiter
     (
      .nub_idn(nub_idn),
      .nub_arbn(nub_arbn),
      .arbcy(mst_arbcy),
      .grant_o(arb_grant)
      );

   // ==========================================================================
   // Slave FSM
   // ==========================================================================

   nubus_slave USlave
     (
      .nub_clkn(nub_clkn), // Clock
      .nub_resetn(nub_resetn), // Reset
      .nub_startn(nub_startn), // Transfer start
      .nub_ackn(nub_ackn), // Transfer end
      .nub_tm1n(nub_tm1n), // Transition mode 1 (Read/Write)
      .nub_tm0n(nub_tm0n),
      .mem_ready(mem_ready),
      .myslot(mem_myslot), // Slot selected
      .mstdn(drv_mstdn),

      .slave_o(slv_slave), // Slave mode
      .master_o(slv_master), // MAster mode
      .myslotln_o(slv_myslotln), 
      .tmn1_o(slv_tmn1), // Latched transition mode 1 (Read/Write)
      .tmn0_o(slv_tmn0),
      .ackcy_o(slv_ackcy)	// Acknowlege
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
      .slv_master(slv_master), // Master mode
      .cpu_lock(cpu_lock), // Address line
      .cpu_valid(cpu_valid), // Master mode (delayed)
      .arb_grant(arb_grant), // Grant access

      .locked_o(mst_locked), // Locked or not tranfer
      .arbdn_o(mst_arbdn),
      .busy_o(mst_busy),
      .owner_o(mst_owner), // Address or data transfer
      .dtacy_o(mst_dtacy), // Data strobe
      .adrcy_o(mst_adrcy), // Address strobe
      .arbcy_o(mst_arbcy)	// Arbiter enabled
   );

   // ==========================================================================
   // Driver Nubus
   // ==========================================================================

   nubus_driver UNDriver
     (
      .mst_ackcy(mst_ackcy), // Achnowlege
      .mst_arbcy(mst_arbcy), // Arbiter enabled
      .mst_adrcy(mst_adrcy), // Address strobe
      .mst_dtacy(mst_dtacy), // Data strobe
      .mst_owner(mst_owner), // Master is owner of the bus
      .mst_locked(mst_locked), // Locked or not transfer
      .mst_tm1n(mst_tm1n), // Address ines
      .mst_tm0n(mst_tm0n), // Address ines

      .nub_tm0_o(nub_tm0n), // Transfer mode
      .nub_tm1_o(nub_tm1n), // Transfer mode
      .nub_tmoe_o(nub_tmoen), // Transfer mode enable
      .nub_ack_o(nub_ackn), // Achnowlege
      .nub_start_o(startn), // Transfer start
      .nub_rqst_o(nub_rqstn), // Bus request
      .nub_rqstoe_o(nub_qstoe), // Bus request enable
      .drv_mstdn_o(drv_mstdn) // Guess: Slave sends /ACK. Master responds with /MSTDN, which allows slave to clear /ACK and listen for next transaction.
      );

   // ==========================================================================
   // MISC Interface
   // ==========================================================================

   tri1 mtmn1;

   nubus_misc UMisc
     (
      .clk(clk), // Clock
      .slave(slv_slave), // Slave transaction
      .master(slv_master), // Master transaction
      .mtm1n(mst_tm1n),
      .tm1ln(slv_tm1n), // Transfer mode
      .adrcy(adrcy), // Address tranfer strobe
      .dtacy(dtacy), // Data tranfer strobe
      .myslot(myslot), // Address lines

      .cab(cab), // Clock  AB (To NuBus)
      .wab(wab), // Write to AB (To NuBus)
      .sab(sab), // Select AB (To NuBus)
      .gab(gab), // Output enable AB (To NuBus)

      .cba(cba), // Clock BA (To Card)
      .wba(wba), // Write BA (To Card)
      .sba(sba), // Select BA (To Card)
      .gba(gba), // Output enable BA (To Card)

      .aclk(aclk), // Address Register Clock
      .aoe(aoe), // Address Register Output Enable
      .awr(awr)  // Address register Write
      );

   reg [31:0] b2a;

   always @(posedge cba or posedge nub_reset) begin : proc_out_nub_ad
      if (nub_reset) begin
         b2a <= 0;
      end else begin
         b2a <= mem_rdata;
      end
   end

   assign adn = gba ? ~b2a : 'bZ;

   // ==========================================================================
   // Memory Interface
   // ==========================================================================

   wire write;
   wire a1ln, a0ln;
   assign { a1ln, a0ln } = ~address[1:0];

   assign mem_addr = address;
   assign mem_wdata = ~adn;

   assign mem_valid = slv_slave; // FIX ME should be somthing different
   assign write = mem_valid & ~slv_tmn1;

   assign mem_wstrb[3]   =     write & ~a1ln & ~a0ln & ~slv_tmn0
                             /* Byte 3 */
                             | write & ~a1ln & ~a0ln &  slv_tmn0
                             /* Half 1 */
                             | write &  a1ln &  a0ln &  slv_tmn0
                             /* Word */
                             ;
   assign mem_wstrb[2]   =     write & ~a1ln &  a0ln & ~slv_tmn0
                             /* Byte 2 */
                             | write & ~a1ln & ~a0ln &  slv_tmn0
                             /* Half 1 */
                             | write &  a1ln &  a0ln &  slv_tmn0
                             /* Word */
                             ;
   assign mem_wstrb[1]   =     write &  a1ln & ~a0ln & ~slv_tmn0
                             /* Byte 1 */
                             | write &  a1ln & ~a0ln &  slv_tmn0
                             /* Half 0 */
                             | write &  a1ln &  a0ln &  slv_tmn0
                             /* Word */
                             ;
   assign mem_wstrb[0]   =     write &  a1ln &  a0ln & ~slv_tmn0
                             /* Byte 0 */
                             | write &  a1ln & ~a0ln &  slv_tmn0
                             /* Half 0 */
                             | write &  a1ln &  a0ln &  slv_tmn0
                             /* Word */
                             ;

endmodule
