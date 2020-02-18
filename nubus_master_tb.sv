`timescale 1 ns / 1 ps

module nubus_master_tb ();

`include "nubus_tb_inc.sv"

   // Simplifyed memory layout (see nubus_master.v)
   parameter SIMPLE_MAP = 0;
   // The test card insered to TEST_CARD_ID slot
   parameter TEST_CARD_ID = 4'h9;
   // The test writes sequence to memory address starts with 
   parameter TEST_SLOT_ADDR = { 4'hF, TEST_CARD_ID, 24'h0 };
   // The test writes sequence to memory address starts with
   // N.B. Make offset $1000 to write to clean memory 
   parameter TEST_SUPERSLOT_ADDR = { TEST_CARD_ID, 28'h1000 };
   // Unused memory address 
   // N.B. Make offset $2000 to write to clean memory 
   parameter TEST_UNUSED_ADDR = { 4'hF, ~TEST_CARD_ID, 24'h2000};
   // Access to local space of card with ID=0
   // N.B. Make offset $4000 to write to clean memory 
   parameter TEST_LOCAL_ADDR = 32'h00004000;
   // The test writes TEST_CARD_ID to cleared memory then, then read it 
   // and verify result
   parameter TEST_DATA = 'h87654321;
   // Make acess to unused memory
   parameter TEST_UNUSED_MEMORY_ACCESS = 1;   
   // Test bench has memory module connected as slave unit.
   // The parameter change speed of this module
   parameter [1:0]  MEMORY_WAIT_CLOCKS = 1;
   // Use or not LOCKED access to NuBus (read NuBus manual)
   parameter CPU_LOCKED = 0;
   // Display messages for every /START condition on NuBus
   parameter DEBUG_NUBUS_START = 0;
   // Display messages for every /ACK condition on NuBus
   parameter DEBUG_NUBUS_ACK = 1;
   // Display messages for every access to memory module
   parameter DEBUG_MEMORY_CYCLE = 0;
   // Watch dog timer bits. Master controller will terminate transfer
   // after (2 ^ WDT_W) clocks
   parameter WDT_W = 3;
   // Read at nubus.v
   parameter LOCAL_SPACE_START = 0;
   parameter LOCAL_SPACE_END = 5;

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
   tri0                mem_tryagain;
   tri0                mem_error;

   tri0                cpu_valid;
   tri1 [31:0]         cpu_addr;
   tri0 [31:0]         cpu_wdata;
   tri1                cpu_ready;
   tri1 [3:0]          cpu_write;
   tri1 [31:0]         cpu_rdata;
   tri1                cpu_lock;

   assign nub_idn = ~ TEST_CARD_ID;

   nubus 
   #(
     .WDT_W(WDT_W),
     .LOCAL_SPACE_EXPOSED_TO_NUBUS(1),
     .LOCAL_SPACE_START(LOCAL_SPACE_START),
     .LOCAL_SPACE_END(LOCAL_SPACE_END)
   )
   UNuBus
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
      .mem_error(mem_error),
      .mem_tryagain(mem_tryagain),

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
   reg         cpu_readyd; // half clk delayed ackn
   reg         tst_lock;

   assign nub_clkn   = tst_clkn;
   assign nub_resetn = tst_resetn;

   assign cpu_valid = tst_valid;
   assign cpu_write = tst_wstrb;
   assign cpu_wdata = tst_wdata;
   assign cpu_addr  = tst_addr;
   assign cpu_lock  = tst_lock;

   integer errors = 0;
   
   initial begin
      $display ("Start CPU writes and reads with NuBus master interfasce to/from NuBus slave memory module");
      $dumpfile("nubus_master_tb.vcd");
      $dumpvars;

      tst_clkn   <= 1;
      tst_resetn <= 0;
      tst_addr   <= 0;
      tst_wdata  <= 0;
      tst_rdata  <= 0;
      tst_valid  <= 0;
      tst_wstrb  <= 0;
      cpu_readyd <= 0;
      tst_lock   <= CPU_LOCKED;
      
      @ (posedge nub_clkn);
      @ (posedge nub_clkn);
      tst_resetn <= 1;
      @ (posedge nub_clkn);
      // Write to slot
      $display("[[[WRITE TO SLOT]]]");
      run_test(TEST_SLOT_ADDR, TEST_DATA);
      #100;
      // Write to super slot
      if (~SIMPLE_MAP) begin
        $display("[[[WRITE TO SUPERSLOT]]]");
        run_test(TEST_SUPERSLOT_ADDR, TEST_DATA);
	#100;
        $display("[[[WRITE TO LOCAL AREA]]]");
        run_test(TEST_LOCAL_ADDR, TEST_DATA);
	#100;
      end

      #100;
      if (TEST_UNUSED_MEMORY_ACCESS) begin
        $display("[[[WRITE TO EMPTY SLOT]]");
        write_word(WRITE_WR_BYTE_3,  TEST_UNUSED_ADDR, TEST_DATA);
        read_word (WRITE_RD_BYTE_3,  TEST_UNUSED_ADDR);
      end 
      #200;
      $display("%d errors", errors);
      $finish;
   end

   // ======================================================
   // Test task
   // ======================================================
	

   task run_test;
      input [31:0] addr;
      input [31:0] data;
      begin
      @ (posedge nub_clkn);
      $display  ("WORD ---------------------------");
      write_word(WRITE_WR_WORD,   addr+0, data);
      read_word (WRITE_RD_WORD,   addr+0);
      check_word(WRITE_WR_WORD);
      $display  ("HALF 0 -------------------------");
      write_word(WRITE_WR_HALF_0, addr+4, data);
      read_word (WRITE_RD_HALF_0, addr+4);
      check_word(WRITE_WR_HALF_0);
      $display  ("HALF 1 -------------------------");
      write_word(WRITE_WR_HALF_1, addr+8, data);
      read_word (WRITE_RD_HALF_1, addr+8);
      check_word(WRITE_WR_HALF_1);

      $display  ("BYTE 0 -------------------------");
      write_word(WRITE_WR_BYTE_0,  addr+12, data);
      read_word (WRITE_RD_BYTE_0,  addr+12);
      check_word(WRITE_WR_BYTE_0);
      $display  ("BYTE 1 -------------------------");
      write_word(WRITE_WR_BYTE_1,  addr+16, data);
      read_word (WRITE_RD_BYTE_1,  addr+16);
      check_word(WRITE_WR_BYTE_1);
      $display  ("BYTE 2 -------------------------");
      write_word(WRITE_WR_BYTE_2,  addr+20, data);
      read_word (WRITE_RD_BYTE_2,  addr+20);
      check_word(WRITE_WR_BYTE_2);
      $display  ("BYTE 3 -------------------------");
      write_word(WRITE_WR_BYTE_3,  addr+24, data);
      read_word (WRITE_RD_BYTE_3,  addr+24);
      check_word(WRITE_WR_BYTE_3);

      end
   endtask

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
         cpu_readyd <= 0;
         do begin
            @ (negedge nub_clkn);
            cpu_readyd <= cpu_ready;
            @ (posedge nub_clkn);
         end while (~cpu_readyd);
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
         cpu_readyd <= 0;
         do begin
            @ (negedge nub_clkn);
            tst_rdata <= cpu_rdata;
            cpu_readyd <= cpu_ready;
            @ (posedge nub_clkn);
         end while (~cpu_readyd) ;
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
      input [3:0]  write
      );
      reg [31:0]   expected;
      begin    
         expected[ 7: 0] = write[0] ? tst_wdata[ 7: 0] : 0;
         expected[15: 8] = write[1] ? tst_wdata[15: 8] : 0;
         expected[23:16] = write[2] ? tst_wdata[23:16] : 0;
         expected[31:24] = write[3] ? tst_wdata[31:24] : 0;
         if (tst_rdata == expected) begin
           $display (":) PASSED");
         end else begin
           $display (":( FAILED expected: $%h found: $%h", expected, tst_rdata);
           errors = errors + 1;
         end   

         $display("  ");         
      end
   endtask // verify

   // ======================================================
   // Clock generator
   // ======================================================

   wire nub_tmadn = {nub_tm1n, nub_tm0n, nub_adn[1], nub_adn[0]};
   always begin
      tst_clkn <= 1;
      #75;
      tst_clkn <= 0;
      if (DEBUG_NUBUS_START) begin
          if (~nub_startn & nub_ackn) 
            $display ("%g  (NuBus Start) /ad: $%h tm: %s", $time, nub_adn, get_start_str(nub_tmadn));
      end
      if (DEBUG_NUBUS_ACK) begin
          if (nub_startn & ~nub_ackn) 
            $display ("%g  (NuBus Start) /ad: $%h status: %s", $time, nub_adn, get_status_str({nub_tm1n, nub_tm0n}));
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
