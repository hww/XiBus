/*
 * Nubus Arbitration logic
 *
 * ARB is responsible for doing the NuBus arbitration logic. Upon
 * detecting any higher priority ARB<3:0> value, it will defer its
 * generation of lower ARB<3:0> bits.
 * The GRANT signal must be timed externally to determine proper
 * NuBus constraints.
 * This version uses a new technique to minimize skews .
 */

/* verilator lint_off UNUSED */
/* verilator lint_off IMPLICIT */
/* verilator lint_off UNOPT */

module nubus_arbiter 
   (
    input [3:0] nub_idn, // ID of this card
    inout [3:0] nub_arbn, // NuBus arbiter's lines
    input       arbcy, // enable arbitter
    output      grant_o // Grant access
    );

   wire          arb2oen, arb1oen, arb0oen; 
   wire          arb3, arb2, arb1, arb0;
   wire          grant_no;
   wire [3:0]    arbn;
   wire [3:0]    idn;
   
   assign idn = nub_idn;
   assign arbn = nub_arbn;
   
   assign nub_arbn[3] = arb3 ? 0 : 'bZ;
   assign nub_arbn[2] = arb2 ? 0 : 'bZ;   
   assign nub_arbn[1] = arb1 ? 0 : 'bZ;   
   assign nub_arbn[0] = arb0 ? 0 : 'bZ; 
   
   // ------------------------------------------

   assign arb3 = arbcy & ~idn[3];

   assign arb2oen = idn[3] & ~arbn[3];

   // ------------------------------------------

   assign arb2 = arbcy & ~arb2oen & ~idn[2];
   
   assign arb1oen = idn[3] & ~arbn[3] | 
                     idn[2] & ~arbn[2];

   // ------------------------------------------

   assign arb1 = arbcy & ~arb1oen & ~idn[1];
   
   assign arb0oen = idn[3] & ~arbn[3] |
                     idn[2] & ~arbn[2] | 
                     idn[1] & ~arbn[1];

   // ------------------------------------------

   assign arb0 = arbcy & ~arb0oen & ~idn[0];
   
   assign grant_no = idn[3] & ~arbn[3] |
                     idn[2] & ~arbn[2] |
                     idn[1] & ~arbn[1] |
                     idn[0] & ~arbn[0];
   
   assign grant_o = arbcy &  ~grant_no;
   
endmodule
