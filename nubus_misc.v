/* 
 * MISC2, local bus~transceiver controls.
 * 
 * The miscellaneous PAL (MISC PAL) is used to decode the state machine signals and drive
 * on-card devices. The outputs control the gating of the 651's, 374's, and so forth.
 */
/* verilator lint_off UNUSED */
module nubus_misc
  (
   input  clk, // Clock
   input  slave, // Slave transaction
   input  master, // Master transaction
   input  mtm1n, // Transfer mode (master)
   input  tm1ln, // Transfer mode (slave)
   input  adrcy, // Address tranfer strobe
   input  arbcy, // Arbiter enable
   input  dtacy, // Data tranfer strobe
   input  romoe, // ROM enable
   input  myslot, // Address lines

   // bus A to B
   output cab, // Clock for bus AB (NuBus to Card)
   output wab, // Write for bus AB (NuBus to Card)
   output sab, // Select outputs for bus AB (NuBus to Card)
   output gab, // Enable outputs of bus AB[31: 0] (NuBus to Card)
   // bus B to A
   output cba, // Clock for bus BA (To NuBus A/D)
   output wba, // Write for bus BA (To NuBus A/D)
   output gba, // Output enable for bus BA (To NuBus A/D)
   output sba, // Select outputs for bus BA (To NuBus A/D)
   // Bus of memory
   output awr, // Address Register Write
   output aoe, // Address Register Output Enable
   output aclk // Address Register Clock
   );

   wire   gabn;
   assign gab = ~gabn;

   // -----------------------------------------------------------------------------
   // NuBus address/data bus (BusA)
   // -----------------------------------------------------------------------------

   // When 1 - drive the NuBus lines (BusA) by outputs ???BA
   //          also it select on bus B content of register A.
   // When 0 - select on outputs (BusB) directly inpputs of (BusA)
   assign gba         = slave & tm1ln
                      /*SLAVE read of card*/
                      | master & adrcy
                      /*MASTER address cycle*/
	                    | master & dtacy & mtm1n
                      /*MASTER data cycle, when writing*/
                      ;
   assign wba         = 1;      // FixMe should not be this
   assign cba         = ~arbcy; // FixMe do not see why so, write to BA at end of arbitration 
   // Select outputs of BusB (0 - BusA, 1 - RegA)
   assign sba         = adrcy;
                      /* address stobe of master */
                      // FixMe it is not clear why so

   // -----------------------------------------------------------------------------
   // Internal address data bus (B)
   // -----------------------------------------------------------------------------

   // Output to the bus B[31:0]
   assign gab         = slave & tm1ln
                      /*SLAVE, non-ROM, read*/
                      | master & ~adrcy & ~dtacy
                      /*MASTER loading address*/
                      | master & mtm1n
                      /*MASTER write*/
                      ;
   assign wab         = ~slave
                      ;
   assign cab         = clk
                      ;
   // Select outputs of BusA (0 - BusB, 1 - RegB)
   assign sab         = gba;

   // -----------------------------------------------------------------------------
   // Address register (ADDR)   $Fxx0 0000
   // -----------------------------------------------------------------------------

   // Write enable
   assign awr         = slave & ~tm1ln & myslot
                      /*SLAVE write to address reg*/
                      ;

   // Output enable
   assign aoe         = slave & tm1ln & myslot
                      /*SLAVE read of address reg*/
                      | master & ~adrcy & ~dtacy
                      /*MASTER address cycle*/
                      ;
   assign aclk        = clk;

endmodule
