`timescale 1 ns / 1 ps
`include "nubus_arbiter.v"

module nubus_arbiter_tb ();

   // shared pins
   tri1 unsigned [3:0] arbn;

   // per instance pins   
   tri1 unsigned [3:0] id1;
   tri1                grant1;
   tri1                enable1;
   tri1 unsigned [3:0] id2;
   tri1                grant2;
   tri1                enable2;
   
   // instantiate arbiter 1
   nubus_arbiter UA1
     (
      .arbcy(enable1), 
      .nub_idn(id1), 
      .nub_arbn(arbn), 
      .grant_o(grant1)
      );
   // instantiate arbiter 2
   nubus_arbiter UA2
     (
      .arbcy(enable2), 
      .nub_idn(id2), 
      .nub_arbni(arbn), 
      .grant_o(grant2)
      );

   // declarate register with IDs for the boards
   reg unsigned[4:0] rid1;
   reg unsigned[4:0] rid2;
   assign id1 = rid1;
   assign id2 = rid2;

   // actvate arbiters only when IDs are different
   assign enable1 = rid1 != rid2;
   assign enable2 = rid1 != rid2;

   // just test fault signal
   reg               fault;
   
   initial begin
      $display ("Start testing Nubus Arbiter");
      $dumpfile("nubus_arbiter_tb.vcd");
      $dumpvars;
      
      fault <= 0;
      
      for (rid1=0; rid1 < 15; rid1 = rid1 + 1) begin
         for (rid2=1; rid2 < 15; rid2 = rid2 + 1) begin

            #10;
            if (rid1 == rid2) begin
               if (grant1 != 0) $display("Expected 0 grant1");
               if (grant2 != 0) $display("Expected 0 grant2");
            end else begin
               if (rid1 < rid2) begin                  
                  if (grant1) begin
                     if (grant2) begin
                        fault <= 1;
                        $monitor("ERROR: Unexpected grant to card B: A(id=%0x grant=%d) B(id=%0x grant=%0d)", id1, grant1, id2, grant2);
                     end else begin
                        // nothing
                     end
                  end else begin
                     fault <= 1;
                     $monitor("ERROR: Expected grant to card A: A(id=%0x grant=%d) B(id=%0x grant=%0d)", id1, grant1, id2, grant2);
                  end
               end else begin
                  if (grant2) begin
                     if (grant1) begin
                        fault <= 1;
                        $monitor("ERROR: Unexpected grant to card A: A(id=%0x grant=%d) B(id=%0x grant=%0d)", id1, grant1, id2, grant2);
                     end else begin
                        // nothing
                     end
                  end else begin
                     fault <= 1;
                     $monitor("ERROR: Expected grant to card B: A(id=%0x grant=%d) B(id=%0x grant=%0d)", id1, grant1, id2, grant2);
                  end
               end 
            end // if (id1 != id2)
            #10;
            
        end
      end // end of for loop 
      if (!fault)
        $monitor("(TEST PASSED)");
      
      $finish;
   end
endmodule

