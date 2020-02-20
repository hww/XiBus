module nubus_errors
  (
   input        nub_clkn,
   input        nub_resetn,
   input        mst_timeout, // Master transaction finished by timeout
   input        mem_error, // memory controller return errors
   input        mem_tryagain, // memory controller not ready to transfer data
   input        nub_noparity, // nubus controller report no-parity
   input        cpu_error, // cpu makes non-aligned access
   input        cpu_eclr, // reset errors
   output [3:0] cpu_errors_o,
   output [1:0] mis_errorn_o
   );

`include "nubus_inc.sv"
   
   // ==========================================================================
   // Error Register, keep last error event
   // ==========================================================================


   reg [4:0] errors;
   
   always @(negedge nub_clkn or negedge nub_resetn) 
     begin : proc_errors_reg
	      if (~nub_resetn) begin
	         errors <= 0;
        end else begin
           if (cpu_eclr) begin
	            errors <= 0;
           end else begin
              // NuBus timeout flag
	            errors[0] <= errors[0] 
                           | mst_timeout;
              // NuBus partity error
	            errors[1] <= errors[1] 
                           | nub_noparity;
              // CPU access to unaligned data
	            errors[2] <= errors[2] 
                           | cpu_error;
              // Memory access eror
              errors[3] <= errors[3]
                           | mem_error;
           end
        end
     end

   assign cpu_errors_o = errors;

   reg [1:0] errorn;
   
   always @*
     begin : proc_error_code
	      if (mst_timeout) begin
	         errorn = TMN_TIMEOUT_ERROR;
        end else if (nub_noparity | cpu_error | mem_error) begin
	         errorn = TMN_ERROR;
 	      end else if (mem_tryagain) begin
	         errorn = TMN_TRY_AGAIN_LATER;
	      end else begin
	         errorn = TMN_COMPLETE;
        end
     end // always

   assign mis_errorn_o = errorn;
   
endmodule // nubus_errors
