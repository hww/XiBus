/*
 * Nubus Arbitration logic
 *
 * The arbitration PAL (ARB PAL) is responsible for performing the NuBus arbitration
 * process. When / ARBCY is asserted, the /ID3-/IDO value drives the / ARB3-/ ARBO lines.
 * However, when / ARB detects that a higher priority value is present on the / ARB3-/ ARB 0
 * lines, it removes drive from its lower priority lines, following the NuB us rules. The GRANT
 * signal is asserted when / ARB recognizes that its / ARB3-/ ARBO value is valid; GRANT is
 * used by the master PAL to detect that the NTC has won ownership of the bus.
 *
 * This version uses a new technique to minimize skews .
 */
module pal_arbiter #()
(
input logic ARBENA,
input logic[3:0] ID,	// Card physical address
output logic GRANT,
input logic[3:0]  ARB_I,
output logic[3:0]  ARB_O,
output logic arb0oe,
output logic arb1oe,
output logic arb2oe
);


assign ARB_O[3] = ARBENA & ID[3];

assign ARB_O[2] = ARBENA & ID[2] & arb2oe;

assign ARB_O[1] = ARBENA & ID[1] & arb1oe;

assign ARB_O[0] = ARBENA & ID[0] & arb0oe;

assign GRANT = (ID[3] | ~ARB_I[3]) & (ID[2] | ~ARB_I[2]) & (ID[1] | ~ARB_I[1]) & (ID[0] | ~ARB_I[0]);

assign arb2oe = (ID[3] | ~ARB_I[3]);
assign arb1oe = (ID[3] | ~ARB_I[3]) & (ID[2] | ~ARB_I[2]);
assign arb0oe = (ID[3] | ~ARB_I[3]) & (ID[2] | ~ARB_I[2]) & (ID[1] | ~ARB_I[1]);

endmodule : pal_arbiter;