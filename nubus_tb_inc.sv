
`include "nubus_inc.sv"

// ======================================================
// Convert tm/ad lines to the data mask
// ======================================================

function [31:0] get_mask (input [3:0] tm);
   begin
      case (tm)
        TMAD_RD_WORD:   get_mask = 'hFFFFFFFF;
        TMAD_RD_HALF_0: get_mask = 'h0000FFFF;
        TMAD_RD_BLOCK:  get_mask = 'hFFFFFFFF;
        TMAD_RD_HALF_1: get_mask = 'hFFFF0000;
        TMAD_RD_BYTE_0: get_mask = 'h000000FF;
        TMAD_RD_BYTE_1: get_mask = 'h0000FF00;
        TMAD_RD_BYTE_2: get_mask = 'h00FF0000;
        TMAD_RD_BYTE_3: get_mask = 'hFF000000;
      endcase // case (tmn)
   end
endfunction // do_math

// ======================================================
// Convert tm lines to the string form
// ======================================================

function string get_status_str (input [1:0] tm);
   begin
      case (tm)
        TM_TRY_AGAIN_LATER: get_status_str = "TryAgainLater";
        TM_TIMEOUT_ERROR:   get_status_str = "Timeout Error";
        TM_ERROR:           get_status_str = "Error";
        TM_COMPLETE:        get_status_str = "Complete";
      endcase 
   end
endfunction // get_status



