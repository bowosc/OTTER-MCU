`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// bowies mod

module DEBUGGER(
        input logic did_we_flush,
        input logic are_we_flush,
        input logic [31:0] DEB_IF_DEC_inst, DEB_DEC_EXE_inst, DEB_EXE_MEM_inst, DEB_MEM_WB_inst,
        output logic ignorethis
    );
    
    assign ignorethis = 1'b1;
    
endmodule
