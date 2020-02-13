`timescale 1 ns / 1 ps

module nubus_master_tb ();

`include "nubus_tb_inc.sv"

   parameter TEST_CARD_ID    = 'h0;
   parameter TEST_ADDR = 'hF0000000;
   parameter TEST_DATA = 'h87654321;
   parameter [1:0]  MEMORY_WAIT_CLOCKS = 1;
   
   
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
      .mem_myslot(mem_myslot),
      .mem_myexp(mem_myep),

       // Master device
      .cpu_valid(cpu_valid),
      .cpu_addr(cpu_addr),
      .cpu_wdata(cpu_wdata),
      .cpu_ready(cpu_ready),
      .cpu_write(cpu_write),
      .cpu_rdata(cpu_rdata),
      .cpu_lock(cpu_lock)
      );

   reg         tst_clkn;
   reg         tst_resetn;
   reg         tst_valid;
   reg [3:0]   tst_wstrb;
   reg [31:0]  tst_addr;
   reg [31:0]  tst_wdata;
   reg [31:0]  tst_rdata;
   reg         tst_acknd; // half clk delayed ackn
   reg         tst_lock;

   assign nub_clkn     = tst_clkn;
   assign nub_resetn   = tst_resetn;

   assign cpu_valid = tst_valid;
   assign cpu_write = tst_wstrb;
   assign cpu_wdata = tst_wdata;
   assign cpu_addr = tst_addr;
   assign cpu_lock = tst_lock;
   assign cpu_ready = ~nub_ackn;

   
   initial begin
      $display ("Start CPU->NuBusMaster->NuBusSlave");
      $dumpfile("nubus_master_tb.vcd");
      $dumpvars;

      tst_clkn <= 1;
      tst_resetn <= 0;
      tst_addr <= 0;
      tst_wdata <= 0;
      tst_rdata  <= 0;
      tst_valid <= 0;
      tst_wstrb <= 0;
      tst_acknd <= 1;
      tst_lock <= 0;
      
      @ (posedge nub_clkn);
      @ (posedge nub_clkn);
      tst_resetn <= 1;
      @ (posedge nub_clkn);
      $display  ("WORD ---------------------------");
      write_word(WSTRB_WR_WORD,   TEST_ADDR+0, TEST_DATA);
      read_word (WSTRB_RD_WORD,   TEST_ADDR+0);
      check_word(WSTRB_WR_WORD,   TEST_DATA);
      $display  ("HALF 0 -------------------------");
      write_word(WSTRB_WR_HALF_0, TEST_ADDR+4, TEST_DATA);
      read_word (WSTRB_RD_HALF_0, TEST_ADDR+4);
      check_word(WSTRB_WR_HALF_0, TEST_DATA);
      $display  ("HALF 1 -------------------------");
      write_word(WSTRB_WR_HALF_1, TEST_ADDR+8, TEST_DATA);
      read_word (WSTRB_RD_HALF_1, TEST_ADDR+8);
      check_word(WSTRB_WR_HALF_1, TEST_DATA);

      $display  ("BYTE 0 -------------------------");
      write_word(WSTRB_WR_BYTE_0,  TEST_ADDR+12, TEST_DATA);
      read_word (WSTRB_RD_BYTE_0,  TEST_ADDR+12);
      check_word(WSTRB_WR_BYTE_0,  TEST_DATA);
      $display  ("BYTE 1 -------------------------");
      write_word(WSTRB_WR_BYTE_1,  TEST_ADDR+16, TEST_DATA);
      read_word (WSTRB_RD_BYTE_1,  TEST_ADDR+16);
      check_word(WSTRB_WR_BYTE_1,  TEST_DATA);
      $display  ("BYTE 2 -------------------------");
      write_word(WSTRB_WR_BYTE_2,  TEST_ADDR+20, TEST_DATA);
      read_word (WSTRB_RD_BYTE_2,  TEST_ADDR+20);
      check_word(WSTRB_WR_BYTE_2,  TEST_DATA);
      $display  ("BYTE 3 -------------------------");
      write_word(WSTRB_WR_BYTE_3,  TEST_ADDR+24, TEST_DATA);
      read_word (WSTRB_RD_BYTE_3,  TEST_ADDR+24);
      check_word(WSTRB_WR_BYTE_3,  TEST_DATA);
      #1000;

      $finish;
   end


   // ======================================================
   // Write task
   // ======================================================

   task write_word;
      input [3:0]  wstrb;
      input [31:0] addr;
      input [31:0] data;
      begin
         tst_addr <= addr;
         tst_wdata <= data;
         tst_wstrb <= wstrb;
         tst_valid <= 1;
         tst_acknd <= 1;
         do begin
            @ (negedge nub_clkn);
            tst_acknd <= nub_ackn;
            @ (posedge nub_clkn);
         end while (tst_acknd);
         tst_valid <= 0;
         tst_wstrb <= 0;
         $display ("%g  (write) address: $%h wstrb: $%b data: $%h", $time, addr, wstrb, data);
      end
   endtask

   // ======================================================
   // Read task
   // ======================================================

   task read_word;
      input [3:0]  wstrb;
      input [31:0] addr;
      begin
         tst_addr <= addr;
         tst_wstrb <= 0;
         tst_valid <= 1;
         tst_acknd <= 1;
         do begin
            @ (negedge nub_clkn);
            tst_rdata <= cpu_rdata;
            tst_acknd <= nub_ackn;
            @ (posedge nub_clkn);
         end while (tst_acknd) ;
         tst_valid <= 0;
         $display ("%g  (read ) address: $%h wstrb: $%b data: $%h", $time, addr, wstrb, tst_rdata);
      end
   endtask

   // ======================================================
   // Verify data writen to memory with read from
   // asume memory befor write was $00000000
   // ======================================================

   task check_word
     (
      input [3:0]  write,
      input [31:0] wdata
      );
      reg [31:0]   expected;
      begin
         $display("$%h", write);
         
         expected[ 7: 0] = write[0] ? wdata[ 7: 0] : 0;
         expected[15: 8] = write[1] ? wdata[15: 8] : 0;
         expected[23:16] = write[2] ? wdata[23:16] : 0;
         expected[31:24] = write[3] ? wdata[31:24] : 0;
         $display("$%h",expected);
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
      #25;
   end

   // ======================================================
   // Memory interface
   // ======================================================

   wire mem_any_write; // unused, just for debugging 
   
   nubus_memory NMem 
     (
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
