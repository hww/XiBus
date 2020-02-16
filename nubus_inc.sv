
// ======================================================
// Set constant for Transition Mode and ad[1:0] lines    
// ======================================================
                    
localparam unsigned [3:0] TMADN_RD_WORD   = 'hF;
localparam unsigned [3:0] TMADN_RD_HALF_0 = 'hE;
localparam unsigned [3:0] TMADN_RD_BLOCK  = 'hD;
localparam unsigned [3:0] TMADN_RD_HALF_1 = 'hC;
localparam unsigned [3:0] TMADN_RD_BYTE_0 = 'hB;
localparam unsigned [3:0] TMADN_RD_BYTE_1 = 'hA;
localparam unsigned [3:0] TMADN_RD_BYTE_2 = 'h9;
localparam unsigned [3:0] TMADN_RD_BYTE_3 = 'h8;

localparam unsigned [3:0] TMADN_WR_WORD   = 'h7;
localparam unsigned [3:0] TMADN_WR_HALF_0 = 'h6;
localparam unsigned [3:0] TMADN_WR_BLOCK  = 'h5;
localparam unsigned [3:0] TMADN_WR_HALF_1 = 'h4;
localparam unsigned [3:0] TMADN_WR_BYTE_0 = 'h3;
localparam unsigned [3:0] TMADN_WR_BYTE_1 = 'h2;
localparam unsigned [3:0] TMADN_WR_BYTE_2 = 'h1;
localparam unsigned [3:0] TMADN_WR_BYTE_3 = 'h0;

// ======================================================
// Status lines 
// ======================================================

localparam unsigned [1:0] TMN_NOP              = 'h0;

// Blocket transfer starts with Attention Lock and 
// ends with Attention Null
localparam unsigned [1:0] TMN_ATTENTION_LOCK   = 'h2;
localparam unsigned [1:0] TMN_ATTENTION_NULL   = 'h0;

// Status code for each record when block transfer
localparam unsigned [1:0] TMN_BLK_REC_COMPLETE = 'h2;

// Status code for ACK transfer
localparam unsigned [1:0] TMN_TRY_AGAIN_LATER = 'h3;
localparam unsigned [1:0] TMN_TIMEOUT_ERROR   = 'h2;
localparam unsigned [1:0] TMN_ERROR           = 'h1;
localparam unsigned [1:0] TMN_COMPLETE        = 'h0;

// ======================================================
// CPU bus write strobes
// ======================================================

localparam unsigned [3:0] WRITE_RD_WORD   = 'b0000;

localparam unsigned [3:0] WRITE_RD_HALF_0 = 'b0000;
localparam unsigned [3:0] WRITE_RD_BLOCK  = 'b0000;
localparam unsigned [3:0] WRITE_RD_HALF_1 = 'b0000;
localparam unsigned [3:0] WRITE_RD_BYTE_0 = 'b0000;
localparam unsigned [3:0] WRITE_RD_BYTE_1 = 'b0000;
localparam unsigned [3:0] WRITE_RD_BYTE_2 = 'b0000;
localparam unsigned [3:0] WRITE_RD_BYTE_3 = 'b0000;

localparam unsigned [3:0] WRITE_WR_WORD   = 'b1111;
localparam unsigned [3:0] WRITE_WR_HALF_0 = 'b0011;
localparam unsigned [3:0] WRITE_WR_BLOCK  = 'b1111;
localparam unsigned [3:0] WRITE_WR_HALF_1 = 'b1100;
localparam unsigned [3:0] WRITE_WR_BYTE_0 = 'b0001;
localparam unsigned [3:0] WRITE_WR_BYTE_1 = 'b0010;
localparam unsigned [3:0] WRITE_WR_BYTE_2 = 'b0100;
localparam unsigned [3:0] WRITE_WR_BYTE_3 = 'b1000;
