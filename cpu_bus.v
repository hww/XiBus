
module cpu_bus
  (
   input         mst_adrcyn,
   input [3:0]   cpu_write,
   input [31:0]  cpu_addr,
   input [31:0]  cpu_wdata,

   output [31:0] cpu_ad_o,
   output        cpu_tm1n_o,
   output        cpu_tm0n_o,
   output        cpu_error_o
   );

   // ==========================================================================
   // CPU Interface
   // ==========================================================================

   reg [4:0] tmadn;

   // Encode wrstb signals to the 'tmn' and 'ad' signals
   always @*
     begin : proc_cpu_encoder
        case (cpu_write)
          'b0000: tmadn = 'b01111; // rd word 
          'b0001: tmadn = 'b00011; // wr byte 0
          'b0010: tmadn = 'b00010; // wr byte 1
          'b0011: tmadn = 'b00110; // wr half 0
          'b0100: tmadn = 'b00001; // wr byte 2
          'b0101: tmadn = 'b10000; // error
          'b0110: tmadn = 'b10000; // error
          'b0111: tmadn = 'b10000; // error
          'b1000: tmadn = 'b00000; // wr byte 3
          'b1001: tmadn = 'b10000; // error
          'b1010: tmadn = 'b10000; // error
          'b1011: tmadn = 'b10000; // error
          'b1100: tmadn = 'b00100; // wr half 1
          'b1101: tmadn = 'b10000; // error
          'b1110: tmadn = 'b10000; // error
          'b1111: tmadn = 'b00111; // wr word
     endcase // case (cpu_write)
     end

   wire [31:0] cpu_tma;
   assign cpu_tma[31:2] = cpu_addr[31:2];
   assign cpu_tma[ 1:0] = ~tmadn[1:0];
   assign cpu_ad_o = ~mst_adrcyn ? cpu_tma : cpu_wdata;

   assign cpu_error_o = tmadn[4];
   assign cpu_tm1n_o = tmadn[3];
   assign cpu_tm0n_o = tmadn[2];

endmodule

