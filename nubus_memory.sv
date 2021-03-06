module nubus_memory
  #(
    parameter MEMORY_W = 16,
    parameter MEMORY_SIZE = 1<<MEMORY_W,
    parameter DEBUG_MEMORY_CYCLE = 0
    )

   (
    input         mem_clk,
    input         mem_reset,
    input         mem_valid,
    input [3:0]   mem_write,
    input [31:0]  mem_addr,
    input [31:0]  mem_wdata,
    input         mem_myslot,
    input         mem_myexp,
    input [1:0]   mem_wait_clocks,
    output [31:0] mem_rdata_o,
    output        mem_ready_o,
    output        mem_write_o
    );

   // Declarate a memory buffer
   reg [31:0] memory[MEMORY_SIZE-1:0];

   // Make the memory's addres
   wire [MEMORY_W-1:0] ma = mem_addr & 'hFFFFFFFC;

   // Is a cycle of writing (or writing)
   assign mem_write_o = mem_write != 0;

   // Reading from memory
   assign mem_rdata_o[31:24] = mem_valid & ~mem_write[3] ? memory[ma][31:24] : 8'bZ;
   assign mem_rdata_o[23:16] = mem_valid & ~mem_write[2] ? memory[ma][23:16] : 8'bZ;
   assign mem_rdata_o[15: 8] = mem_valid & ~mem_write[1] ? memory[ma][15: 8] : 8'bZ;
   assign mem_rdata_o[ 7: 0] = mem_valid & ~mem_write[0] ? memory[ma][ 7: 0] : 8'bZ;

   integer    tmpidx;

   // Writing to memory
   always @(posedge mem_clk or posedge mem_reset) begin
      if (mem_reset) begin
         // clear memory
         for (tmpidx=0; tmpidx < MEMORY_SIZE; tmpidx = tmpidx + 1) begin
            memory[tmpidx] <= 0;
         end
      end else begin
         if (mem_valid) begin
           if (mem_write_o) begin
              if (DEBUG_MEMORY_CYCLE)
                  $display("memory[$%h] <= $%h strobes: %b ", ma, mem_wdata, mem_write);
              if (mem_write[3])
                memory[ma][31:24] <= mem_wdata[31:24];
              if (mem_write[2])
                memory[ma][23:16] <= mem_wdata[23:16];
              if (mem_write[1])
                memory[ma][15:8]  <= mem_wdata[15:8];
              if (mem_write[0])
                memory[ma][7:0]   <= mem_wdata[7:0];
           end else begin // if ( write)
              if (DEBUG_MEMORY_CYCLE)
                  $display("memory[$%h] -> $%h strobes: %b ", ma, mem_rdata_o, mem_write);
           end
         end
      end
   end // always @ (negedge clk)

   // Acknowledge for memory access 
   reg mem_valid1, mem_valid2, mem_valid3; 
   
   always @(negedge mem_clk or posedge mem_reset) begin
      if (mem_reset) begin
         mem_valid1 <= 0;
         mem_valid2 <= 0;
         mem_valid3 <= 0;
      end else begin
         mem_valid1 <= mem_valid;
         mem_valid2 <= mem_valid1 & mem_valid;
         mem_valid3 <= mem_valid2 & mem_valid;
      end 
   end // always @ (posedge mem_clkn or negedge mem_resetn)

   wire one = 1;

   wire [3:0] mem_validv = { mem_valid3, mem_valid2, mem_valid1, mem_valid };
   
   assign mem_ready_o = mem_valid & mem_validv[mem_wait_clocks];

endmodule
