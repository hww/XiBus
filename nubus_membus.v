/*
 * MemBus controller generate singlas for card's local memory
 * 
 * Autor: Valeriya Pudova (hww.github.io)
 */

   module nubus_membus
     (
      input                  nub_clkn, // Clock
      input                  nub_resetn, // Reset	
      input unsigned [31:0]  nub_adn, // Nubus Address/Data
   
      input                  slv_tm1n, // Slave /TM1
      input                  slv_tm0n, // Slave /TM0
      input                  slv_myslotcy, // Any slot selected
      input unsigned [31:0]  slv_addr, // Address 
   
      output [3:0]           mem_write_o, // Memory write strobes
      output unsigned [31:0] mem_addr_o, // Memory address
      output unsigned [31:0] mem_wdata_o // Memory write data
   );

   wire          tm1n = slv_tm1n;
   wire          tm0n = slv_tm0n;

   // ==========================================================================
   // Write strobes
   // ==========================================================================
   
   wire a1n = ~slv_addr[1];
   wire a0n = ~slv_addr[0];
   wire write = slv_myslotcy & ~tm1n;

   assign mem_addr_o = { slv_addr[31:2], 1'b0, 1'b0 };
   assign mem_wdata_o = ~nub_adn;

   assign mem_write_o[3]   =   write & ~a1n & ~a0n & ~tm0n
                             /* Byte 3 */
                             | write & ~a1n & ~a0n &  tm0n
                             /* Half 1 */
                             | write &  a1n &  a0n &  tm0n
                             /* Word */
                             ;
   assign mem_write_o[2]   =   write & ~a1n &  a0n & ~tm0n
                             /* Byte 2 */
                             | write & ~a1n & ~a0n &  tm0n
                             /* Half 1 */
                             | write &  a1n &  a0n &  tm0n
                             /* Word */
                             ;
   assign mem_write_o[1]   =   write &  a1n & ~a0n & ~tm0n
                             /* Byte 1 */
                             | write &  a1n & ~a0n &  tm0n
                             /* Half 0 */
                             | write &  a1n &  a0n &  tm0n
                             /* Word */
                             ;
   assign mem_write_o[0]   =   write &  a1n &  a0n & ~tm0n
                             /* Byte 0 */
                             | write &  a1n & ~a0n &  tm0n
                             /* Half 0 */
                             | write &  a1n &  a0n &  tm0n
                             /* Word */
                             ;

endmodule 
