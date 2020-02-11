

// Set constant for Transition Mode and ad[1:0] lines                      
localparam unsigned [3:0] TMADN_WR_BYTE_3 = 'h0;
localparam unsigned [3:0] TMADN_WR_BYTE_2 = 'h1;
localparam unsigned [3:0] TMADN_WR_BYTE_1 = 'h2;
localparam unsigned [3:0] TMADN_WR_BYTE_0 = 'h3;
localparam unsigned [3:0] TMADN_WR_HALF_1 = 'h4;
localparam unsigned [3:0] TMADN_WR_BLOCK = 'h5;
localparam unsigned [3:0] TMADN_WR_HALF_0 = 'h6;
localparam unsigned [3:0] TMADN_WR_WORD = 'h7;

localparam unsigned [3:0] TMADN_RD_BYTE_3 = 'h8;
localparam unsigned [3:0] TMADN_RD_BYTE_2 = 'h9;
localparam unsigned [3:0] TMADN_RD_BYTE_1 = 'hA;
localparam unsigned [3:0] TMADN_RD_BYTE_0 = 'hB;
localparam unsigned [3:0] TMADN_RD_HALF_1 = 'hC;
localparam unsigned [3:0] TMADN_RD_BLOCK = 'hD;
localparam unsigned [3:0] TMADN_RD_HALF_0 = 'hE;
localparam unsigned [3:0] TMADN_RD_WORD = 'hF;

// Status code for each record when block transfer
localparam unsigned [3:0] TM_REC_COMPLETE = 'h2;

// Status code for ACK transfer
localparam unsigned [3:0] TM_COMPLETE = 'h0;
localparam unsigned [3:0] TM_ERROR = 'h1;
localparam unsigned [3:0] TM_TIMEOUT_ERROR = 'h2;
localparam unsigned [3:0] TM_TRY_AGAIN_LATER = 'h3;

