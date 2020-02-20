`timescale 1 ns / 1 ps

module nubus_slave_tb ();

`include "nubus_tb.svh"

   parameter TEST_CARD_ID    = 'h0;
   parameter TEST_ADDR = 'hF0000000;
   parameter TEST_DATA = 'h87654321;
   parameter [1:0]  MEMORY_WAIT_CLOCKS = 1;   
   parameter DEBUG_NUBUS_START = 0;
   parameter DEBUG_MEMORY_CYCLE = 0;
   
   // Slot Identificatjon
   tri1 [3:0]          nub_idn; 
   // Clock (rising is driving edge, faling is sampling) 
   tri1                nub_clkn; 
   // Reset
   tri1                nub_resetn; 
   // Power Fail Warning
   tri1                nub_pfwn;
   // Address/Data
   tri1 [31:0]         nub_adn;
   // Transfer Mode
   tri1                nub_tm0n;
   tri1                nub_tm1n;
   // Start
   tri1                nub_startn;
   // Request
   tri1                nub_rqstn;
   // Acknowledge
   tri1                nub_ackn;
   // Arbitration
   tri1 [3:0]          nub_arbn;
   // Non-Master Request
   tri1                nub_nmrqn;
   // System Parity
   tri1                nub_spn;
   // System Parity Valid
   tri1                nub_spvn;

   // SLave interface signals
   tri1                mem_valid;
   tri1                mem_ready;
   tri1 [3:0]          mem_write;
   tri1 [31:0]         mem_addr;
   tri1 [31:0]         mem_wdata;
   tri1 [31:0]         mem_rdata;
   tri1                mem_myslot;
   tri1                mem_myexp;

   tri0                cpu_valid;
   tri1 [31:0]         cpu_addr;
   tri0 [31:0]         cpu_wdata;
   tri1                cpu_ready;
   tri1 [3:0]          cpu_write;
   tri1 [31:0]         cpu_rdata;
   tri1                cpu_lock;

   assign nub_idn = ~ TEST_CARD_ID;

   nubus UNuBus
     (
      // NuBus lines only
      .nub_clkn(nub_clkn),
      .nub_resetn(nub_resetn),
      .nub_idn(nub_idn),

      .nub_pfwn(nub_pfwn),
      .nub_adn(nub_adn),
      .nub_tm0n(nub_tm0n),
      .nub_tm1n(nub_tm1n),
      .nub_startn(nub_startn),
      .nub_rqstn(nub_rqstn),
      .nub_ackn(nub_ackn),
      .nub_arbn(nub_arbn),

      .nub_nmrqn(nub_nmrqn),
      .nub_spn(nub_spn),
      .nub_spvn(nub_spvn),

      // Slave device pins only
      .mem_valid(mem_valid),
      .mem_ready(mem_ready),
      .mem_write(mem_write),
      .mem_addr(mem_addr),
      .mem_wdata(mem_wdata),
      .mem_rdata(mem_rdata),
      .mem_slot(mem_myslot),
      .mem_super(mem_myep),

       // Master device
      .cpu_valid(cpu_valid),
      .cpu_addr(cpu_addr),
      .cpu_wdata(cpu_wdata),
      .cpu_ready(cpu_ready),
      .cpu_write(cpu_write),
      .cpu_rdata(cpu_rdata),
      .cpu_lock(cpu_lock)
      );

   // Disabale CPU bus
   assign cpu_valid = 0;

   // State machine of test bench
   reg         tst_clkn;
   reg         tst_resetn;
   reg         tst_startn;
   reg         tst_ackn;    // half clkn delayed ackn
   reg [1:0]   tst_tmn;
   reg [1:0]   tst_statusn;
   reg [31:0]  tst_addrn;
   reg [31:0]  tst_wdatan;
   reg [31:0]  tst_rdatan;

   // Drive NuBus signals
   assign nub_clkn     = tst_clkn;
   assign nub_resetn   = tst_resetn;
   assign nub_startn   = tst_startn;   
   assign nub_tm0n     = tst_startn ? 'bZ : tst_tmn[0];
   assign nub_tm1n     = tst_startn ? 'bZ : tst_tmn[1];
   
   // Drive NuBus address/data lines
   wire [31:0] tst_adn = tst_startn ? tst_wdatan : tst_addrn;
   wire tst_nuboen     = tst_startn & tst_tmn[1];
   assign nub_adn      = tst_nuboen ? 'bZ : tst_adn;
   
   // Inverted verions of registers 
   wire [31:0] tst_rdata = ~tst_rdatan;
   wire [31:0] tst_addr  = ~tst_addrn;
    
   initial begin
      $display ("Start virtual master (vm) writes and reads to/from NuBus slave memory module");
      $dumpfile("nubus_slave_tb.vcd");
      $dumpvars;

      tst_clkn   <= 1;
      tst_resetn <= 0;
      tst_addrn  <= 'hFFFFFFFF;
      tst_wdatan <= 'hFFFFFFFF;
      tst_rdatan <= 'hFFFFFFFF;
      tst_startn <= 1;
      tst_statusn<= TMN_TRY_AGAIN_LATER;
      tst_tmn    <= TMN_NOP;

      @ (posedge nub_clkn);
      @ (posedge nub_clkn);
        tst_resetn <= 1;
      @ (posedge nub_clkn);
      $display  ("WORD ---------------------------");
      write_word(TMADN_WR_WORD,   TEST_ADDR+0, TEST_DATA);
      read_word (TMADN_RD_WORD,   TEST_ADDR+0);
      check_word(TMADN_RD_WORD,   TEST_DATA);
      $display  ("HALF 0 -------------------------");
      write_word(TMADN_WR_HALF_0, TEST_ADDR+4, TEST_DATA);
      read_word (TMADN_RD_HALF_0, TEST_ADDR+4);
      check_word(TMADN_RD_HALF_0, TEST_DATA);
      $display  ("HALF 1 -------------------------");
      write_word(TMADN_WR_HALF_1, TEST_ADDR+8, TEST_DATA);
      read_word (TMADN_RD_HALF_1, TEST_ADDR+8);
      check_word(TMADN_RD_HALF_1, TEST_DATA);

      $display  ("BYTE 0 -------------------------");
      write_word(TMADN_WR_BYTE_0,  TEST_ADDR+12, TEST_DATA);
      read_word (TMADN_RD_BYTE_0,  TEST_ADDR+12);
      check_word(TMADN_RD_BYTE_0,  TEST_DATA);
      $display  ("BYTE 1 -------------------------");
      write_word(TMADN_WR_BYTE_1,  TEST_ADDR+16, TEST_DATA);
      read_word (TMADN_RD_BYTE_1,  TEST_ADDR+16);
      check_word(TMADN_RD_BYTE_1,  TEST_DATA);
      $display  ("BYTE 2 -------------------------");
      write_word(TMADN_WR_BYTE_2,  TEST_ADDR+20, TEST_DATA);
      read_word (TMADN_RD_BYTE_2,  TEST_ADDR+20);
      check_word(TMADN_RD_BYTE_2,  TEST_DATA);
      $display  ("BYTE 3 -------------------------");
      write_word(TMADN_WR_BYTE_3,  TEST_ADDR+24, TEST_DATA);
      read_word (TMADN_RD_BYTE_3,  TEST_ADDR+24);
      check_word(TMADN_RD_BYTE_3,  TEST_DATA);
      #1000;

      $finish;
   end


   // ======================================================
   // Write task
   // ======================================================

   task write_word;
      input [3:0]  tmadn;
      input [31:0] addr;
      input [31:0] data;
      begin
         tst_wdatan     <= ~data;
         tst_addrn[31:2] <= ~addr[31:2];
         tst_addrn[ 1:0] <= tmadn[1:0]; 
         tst_tmn        <= tmadn[3:2];
         tst_startn     <= 0;
         //tst_statusn    <= TMN_TRY_AGAIN_LATER;
         @ (posedge nub_clkn);
         tst_startn     <= 1;
         tst_ackn       <= nub_ackn;
         do begin
            @ (negedge nub_clkn);
            tst_ackn    <= nub_ackn;
            tst_statusn <= { nub_tm1n, nub_tm0n };
            @ (posedge nub_clkn);
         end while (tst_ackn) ;
         $display ("%g  (write) address: $%h tm: $%h data: $%h stat: %s", $time, addr, tmadn, data, get_status_str(tst_statusn));
      end
   endtask

   // ======================================================
   // Read task
   // ======================================================

   task read_word;
      input [3:0]  tmadn;
      input [31:0] addr;
      begin
         tst_tmn         <= tmadn[3:2];
         tst_addrn[ 1:0] <= tmadn[1:0];
         tst_addrn[31:2] <= ~addr[31:2];
         tst_startn  <= 0;
         //tst_statusn <= TMN_TRY_AGAIN_LATER;
         @ (posedge nub_clkn);
         tst_startn  <= 1;
         tst_ackn    <= nub_ackn;
         do begin
            @ (negedge nub_clkn);
            tst_rdatan  <= nub_adn;
            tst_ackn    <= nub_ackn;
            tst_statusn <= { nub_tm1n, nub_tm0n };
            @ (posedge nub_clkn);
         end while (tst_ackn) ;
         $display ("%g  (read ) address: $%h tm: $%h data: $%h stat: %s", $time, addr, tmadn, tst_rdata, get_status_str(tst_statusn));
      end
   endtask

   // ======================================================
   // Verify data writen to memory with read from
   // asume memory befor write was $00000000
   // ======================================================

   task check_word
     (
      input [3:0]  tm,
      input [31:0] data_wr
      );
      reg [31:0]   expected;
      begin
         expected = (data_wr & get_mask(tm));
         if (tst_rdata == expected)
           $display (":) PASSED");
         else
           $display (":( FAILED expected: $%h found: $%h", expected, tst_rdata);
         $display("  ");         
      end
   endtask // verify

   // ======================================================
   // Clock generator
   // ======================================================

   always begin
      tst_clkn <= 1;
      #75;
      tst_clkn <= 0;
      if (DEBUG_NUBUS_START) begin
         if (~nub_startn) 
            $display ("%g  (NuBus Start) /ad: $%h {/tmadn}: %b%b%b%b", $time, nub_adn, nub_tm1n, nub_tm0n, nub_adn[1], nub_adn[0]);
      end
      #25;
   end

   // ======================================================
   // Memory interface
   // ======================================================

   wire mem_any_write; // unused, just for debugging 
   
   nubus_memory     
    #(
       .DEBUG_MEMORY_CYCLE(DEBUG_MEMORY_CYCLE)
     ) 
     NMem (
      .mem_clk(~nub_clkn),
      .mem_reset(~nub_resetn),
      .mem_valid(mem_valid),
      .mem_write(mem_write),
      .mem_addr(mem_addr),
      .mem_wdata(mem_wdata),
      .mem_rdata_o(mem_rdata),
      .mem_myslot(mem_myslot),
      .mem_myexp(mem_myexp),
      .mem_wait_clocks(MEMORY_WAIT_CLOCKS),
      .mem_ready_o(mem_ready),
      .mem_write_o(mem_any_write)
      );

endmodule
