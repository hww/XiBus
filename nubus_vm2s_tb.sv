`timescale 1 ns / 1 ps

module nubus_vm2s_tb ();

`include "nubus.sv"

   parameter TEST_CARD_ID    = 'h0;
   parameter TEST_ADDR = 'hF0000000;
   parameter TEST_DATA = 'h87654321;
   
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
   tri1 [3:0]          mem_wstrb;
   tri1 [31:0]         mem_addr;
   tri1 [31:0]         mem_wdata;
   tri1 [31:0]         mem_rdata;
   tri1                mem_myslot;
   tri1                mem_myexp;

   tri0                cpu_valid;
   tri1 [31:0]         cpu_addr;
   tri0 [31:0]         cpu_wdata;
   tri1                cpu_ready;
   tri1 [3:0]          cpu_wstrb;
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
      .mem_wstrb(mem_wstrb),
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
      .cpu_wstrb(cpu_wstrb),
      .cpu_rdata(cpu_rdata),
      .cpu_lock(cpu_lock)
      );

   // Disabale CPU

   assign cpu_valid = 0;
   
   
   // States of the state machine
   parameter FSM_WRITE_START = 3;
   parameter FSM_WRITE_END = 4;
   parameter FSM_READ_START = 5;
   parameter FSM_READ_END = 6;

   reg         fsm_clkn;
   reg         fsm_resetn;
   reg         fsm_start;
   reg [1:0]   fsm_tm;
   reg [1:0]   fsm_status;
   reg [31:0]  fsm_addr;
   reg [31:0]  fsm_datawr;
   reg [31:0]  fsm_datard;
   reg         fsm_acknd; // half clk delayed ackn
   wire [1:0]  fsm_tmn = ~fsm_tm;


   assign nub_clkn     = fsm_clkn;
   assign nub_resetn   = fsm_resetn;
   assign nub_startn   = ~fsm_start;
   
   assign nub_tm0n     = fsm_start ? fsm_tmn[0] : 'bZ;
   assign nub_tm1n     = fsm_start ? fsm_tmn[1] : 'bZ;
   
   wire [31:0] fsm_ad = fsm_start ? fsm_addr : fsm_datawr;
   wire nuboe = fsm_start | fsm_tm[1];
   assign nub_adn     = nuboe ? ~fsm_ad : 'bZ;
   
   initial begin
      $display ("Start VirtualMaster write to NubusSlave");
      $dumpfile("nubus_vm2s_tb.vcd");
      $dumpvars;

      fsm_clkn <= 1;
      fsm_resetn <= 0;
      fsm_addr <= 0;
      fsm_datawr <= 0;
      fsm_datard  <= 0;
      fsm_start <= 0;
      fsm_status <= TM_NOP;
      fsm_tm <= TM_NOP;

      @ (posedge nub_clkn);
      @ (posedge nub_clkn);
        fsm_resetn <= 1;
      @ (posedge nub_clkn);
      $display  ("WR WORD ---------------------------");
      write_word(TMAD_WR_WORD,   TEST_ADDR+0, TEST_DATA);
      $display  ("RD WORD ---------------------------");
      read_word (TMAD_RD_WORD,   TEST_ADDR+0);
      check_word(TMAD_RD_WORD,   TEST_DATA);
      $display  ("WR HALF 0 -------------------------");
      write_word(TMAD_WR_HALF_0, TEST_ADDR+4, TEST_DATA);
      $display  ("RD HALF 0 -------------------------");
      read_word (TMAD_RD_HALF_0, TEST_ADDR+4);
      check_word(TMAD_RD_HALF_0, TEST_DATA);
      $display  ("WR HALF 1 -------------------------");
      write_word(TMAD_WR_HALF_1, TEST_ADDR+8, TEST_DATA);
      $display  ("RD HALF 1 -------------------------");
      read_word (TMAD_RD_HALF_1, TEST_ADDR+8);
      check_word(TMAD_RD_HALF_1, TEST_DATA);

      $display  ("WR BYTE 0 -------------------------");
      write_word(TMAD_WR_BYTE_0,  TEST_ADDR+12, TEST_DATA);
      $display  ("RD BYTE 0 -------------------------");
      read_word (TMAD_RD_BYTE_0,  TEST_ADDR+12);
      check_word(TMAD_RD_BYTE_0,  TEST_DATA);
      $display  ("WR BYTE 1 -------------------------");
      write_word(TMAD_WR_BYTE_1,  TEST_ADDR+16, TEST_DATA);
      $display  ("RD BYTE 1 -------------------------");
      read_word (TMAD_RD_BYTE_1,  TEST_ADDR+16);
      check_word(TMAD_RD_BYTE_1,  TEST_DATA);
      $display  ("WR BYTE 2 -------------------------");
      write_word(TMAD_WR_BYTE_2,  TEST_ADDR+20, TEST_DATA);
      $display  ("RD BYTE 2 -------------------------");
      read_word (TMAD_RD_BYTE_2,  TEST_ADDR+20);
      check_word(TMAD_RD_BYTE_2,  TEST_DATA);
      $display  ("WR BYTE 3 -------------------------");
      write_word(TMAD_WR_BYTE_3,  TEST_ADDR+24, TEST_DATA);
      $display  ("RD BYTE 3 -------------------------");
      read_word (TMAD_RD_BYTE_3,  TEST_ADDR+24);
      check_word(TMAD_RD_BYTE_3,  TEST_DATA);
      $display  ("END -------------------------------");
      #1000;

      $finish;
   end


   // ======================================================
   // Write task
   // ======================================================

   task write_word;
      input [3:0]  tmad;
      input [31:0] addr;
      input [31:0] data;
      begin
         $display ("%g write address: $%h tm: $%h data: $%h", $time, addr, tmad, data);
         fsm_datawr <= data;
         fsm_addr[31:2] <= addr[31:2];
         fsm_addr[ 1:0] <= tmad[1:0]; 
         fsm_tm <= tmad[3:2];
         fsm_start <= 1;
         fsm_status <= TM_NOP;
         @ (posedge nub_clkn);
         fsm_start <= 0;
         fsm_acknd <= nub_ackn;
         do begin
            @ (negedge nub_clkn);
            fsm_acknd <= nub_ackn;
            fsm_status <= ~{ nub_tm1n, nub_tm0n };
            @ (posedge nub_clkn);
         end while (fsm_acknd) ;
         $display("%g write end            status: $%h ", $time, fsm_status);
      end
   endtask

   // ======================================================
   // Read task
   // ======================================================

   task read_word;
      input [3:0]  tmad;
      input [31:0] addr;
      begin
         $display ("%g  read address: $%h tm: $%h", $time, addr, tmad);
         fsm_addr[31:2] <= addr[31:2];
         fsm_addr[ 1:0] <= tmad[1:0];
         fsm_tm <= tmad[3:2];
         fsm_start <= 1;
         fsm_status <= TM_NOP;
         @ (posedge nub_clkn);
         fsm_start <= 0;
         fsm_acknd <= nub_ackn;
         do begin
            @ (negedge nub_clkn);
            fsm_datard <= ~nub_adn;
            fsm_acknd <= nub_ackn;
            fsm_status <= ~{ nub_tm1n, nub_tm0n };
            @ (posedge nub_clkn);
         end while (fsm_acknd) ;

         $display("%g read end             status: $%h     data: $%h", $time, fsm_status, fsm_datard);
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
         if (fsm_datard == expected)
           $display (":) PASSED");
         else
           $display (":X FAILED expected: $%h found: $%h", expected, fsm_datard);
         $display("  ");         
      end
   endtask // verify

   // ======================================================
   // Convert tmx lines to the data mask
   // ======================================================

   function [31:0] get_mask (input [3:0] tm);
      begin
         case (tm)
           TMAD_RD_WORD:   get_mask = 'hFFFFFFFF;
           TMAD_RD_HALF_0: get_mask = 'h0000FFFF;
           TMAD_RD_BLOCK:  get_mask = 'hFFFFFFFF;
           TMAD_RD_HALF_1: get_mask = 'hFFFF0000;
           TMAD_RD_BYTE_0: get_mask = 'h000000FF;
           TMAD_RD_BYTE_1: get_mask = 'h0000FF00;
           TMAD_RD_BYTE_2: get_mask = 'h00FF0000;
           TMAD_RD_BYTE_3: get_mask = 'hFF000000;
         endcase // case (tmn)
      end
   endfunction // do_math

   // ======================================================
   // Clock generator
   // ======================================================

   always begin
      fsm_clkn <= 1;
      #75;
      fsm_clkn <= 0;
      #25;
   end

   // ======================================================
   // Memory interface
   // ======================================================

   wire mem_write; // unused, just for debugging 
   
   nubus_memory NMem
     (
      .mem_clk(~nub_clkn),
      .mem_reset(~nub_resetn),
      .mem_valid(mem_valid),
      .mem_wstrb(mem_wstrb),
      .mem_addr(mem_addr),
      .mem_wdata(mem_wdata),
      .mem_rdata_o(mem_rdata),
      .mem_myslot(mem_myslot),
      .mem_myexp(mem_myexp),
      .mem_ready_o(mem_ready),
      .mem_write_o(mem_write)
      );

endmodule
