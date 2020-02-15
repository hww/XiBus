
`include "nubus_inc.sv"

// ======================================================
// Convert tm/ad lines to the data mask
// ======================================================

function [31:0] get_mask (input [3:0] tmn);
   begin
      case (tmn)
        TMADN_RD_WORD:   get_mask = 'hFFFFFFFF;
        TMADN_RD_HALF_0: get_mask = 'h0000FFFF;
        TMADN_RD_BLOCK:  get_mask = 'hFFFFFFFF;
        TMADN_RD_HALF_1: get_mask = 'hFFFF0000;
        TMADN_RD_BYTE_0: get_mask = 'h000000FF;
        TMADN_RD_BYTE_1: get_mask = 'h0000FF00;
        TMADN_RD_BYTE_2: get_mask = 'h00FF0000;
        TMADN_RD_BYTE_3: get_mask = 'hFF000000;
      endcase // case (tmn)
   end
endfunction // do_math

// ======================================================
// Convert tm lines to the string form
// ======================================================

function string get_status_str (input [1:0] tmn);
   begin
      case (tmn)
        TMN_TRY_AGAIN_LATER: get_status_str = "TryAgainLater";
        TMN_TIMEOUT_ERROR:   get_status_str = "Timeout Error";
        TMN_ERROR:           get_status_str = "Error";
        TMN_COMPLETE:        get_status_str = "Complete";
      endcase // case (tmn)
   end
endfunction // get_status


