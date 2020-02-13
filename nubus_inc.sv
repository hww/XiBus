
// ======================================================
// Set constant for Transition Mode and ad[1:0] lines    
// ======================================================
                    
localparam unsigned [3:0] TMAD_RD_WORD = 'h0;
localparam unsigned [3:0] TMAD_RD_HALF_0 = 'h1;
localparam unsigned [3:0] TMAD_RD_BLOCK = 'h2;
localparam unsigned [3:0] TMAD_RD_HALF_1 = 'h3;
localparam unsigned [3:0] TMAD_RD_BYTE_0 = 'h4;
localparam unsigned [3:0] TMAD_RD_BYTE_1 = 'h5;
localparam unsigned [3:0] TMAD_RD_BYTE_2 = 'h6;
localparam unsigned [3:0] TMAD_RD_BYTE_3 = 'h7;

localparam unsigned [3:0] TMAD_WR_WORD = 'h8;
localparam unsigned [3:0] TMAD_WR_HALF_0 = 'h9;
localparam unsigned [3:0] TMAD_WR_BLOCK = 'hA;
localparam unsigned [3:0] TMAD_WR_HALF_1 = 'hB;
localparam unsigned [3:0] TMAD_WR_BYTE_0 = 'hC;
localparam unsigned [3:0] TMAD_WR_BYTE_1 = 'hD;
localparam unsigned [3:0] TMAD_WR_BYTE_2 = 'hE;
localparam unsigned [3:0] TMAD_WR_BYTE_3 = 'hF;

// ======================================================
// Status lines 
// ======================================================

localparam unsigned [1:0] TM_NOP = 'h0;

// Status code for each record when block transfer
localparam unsigned [1:0] TM_REC_COMPLETE = 'h1;

// Status code for ACK transfer
localparam unsigned [1:0] TM_TRY_AGAIN_LATER = 'h0;
localparam unsigned [1:0] TM_TIMEOUT_ERROR = 'h1;
localparam unsigned [1:0] TM_ERROR = 'h2;
localparam unsigned [1:0] TM_COMPLETE = 'h3;

// ======================================================
// CPU bus write strobes
// ======================================================

localparam unsigned [3:0] WSTRB_RD_WORD   = 'b0000;
localparam unsigned [3:0] WSTRB_RD_HALF_0 = 'b0000;
localparam unsigned [3:0] WSTRB_RD_BLOCK  = 'b0000;
localparam unsigned [3:0] WSTRB_RD_HALF_1 = 'b0000;
localparam unsigned [3:0] WSTRB_RD_BYTE_0 = 'b0000;
localparam unsigned [3:0] WSTRB_RD_BYTE_1 = 'b0000;
localparam unsigned [3:0] WSTRB_RD_BYTE_2 = 'b0000;
localparam unsigned [3:0] WSTRB_RD_BYTE_3 = 'b0000;

localparam unsigned [3:0] WSTRB_WR_WORD   = 'b1111;
localparam unsigned [3:0] WSTRB_WR_HALF_0 = 'b0011;
localparam unsigned [3:0] WSTRB_WR_BLOCK  = 'b1111;
localparam unsigned [3:0] WSTRB_WR_HALF_1 = 'b1100;
localparam unsigned [3:0] WSTRB_WR_BYTE_0 = 'b0001;
localparam unsigned [3:0] WSTRB_WR_BYTE_1 = 'b0010;
localparam unsigned [3:0] WSTRB_WR_BYTE_2 = 'b0100;
localparam unsigned [3:0] WSTRB_WR_BYTE_3 = 'b1000;
