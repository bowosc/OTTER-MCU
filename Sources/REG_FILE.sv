`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bowman Edebohls
// 
// Create Date: 
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module REG_FILE(
        input REG_FILE_en, // same as load
        input logic [31:0] REG_FILE_wd, // thing to write to destination register
        input logic [4:0] REG_FILE_adr1, // 5 bit address of src reg 1
        input logic [4:0] REG_FILE_adr2, // 5 bit address of src reg 2
        input logic [4:0] REG_FILE_wa, // 5 bit address of destination register
        
        input REG_FILE_CLK,
        
        output [31:0] REG_FILE_Rs1, // data of src reg 1
        output [31:0] REG_FILE_Rs2 // data of src reg 2
    );
    
    // set up array. 32 registers, 32 bits each
    logic [31:0] ram [0:31];
    
    // initialize all registers to 0
    initial begin 
        //int i = 0;
        for (int i = 0; i < 32; i++) begin
            ram[i] = 0;
        end
        
    end
    
    // asynch reads
    assign REG_FILE_Rs1 = ram[REG_FILE_adr1];
    assign REG_FILE_Rs2 = ram[REG_FILE_adr2];
    
    // synch write
    always_ff @ (posedge REG_FILE_CLK) begin
        // no writing to reg 0!!
        if (REG_FILE_en && (REG_FILE_wa != 5'b00000)) begin
            ram[REG_FILE_wa] = REG_FILE_wd;
        end
        // ram[0] <= 0; // just in case 
    end
endmodule


