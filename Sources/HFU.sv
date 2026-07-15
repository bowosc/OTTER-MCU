`timescale 1ns/1ps


module HFU (
        input logic [4:0] P2rs1, P2rs2,   // These are from P2
        input logic [4:0] P3rs1, P3rs2,
        input logic [4:0] P3rd, P4rd,
        input logic [4:0] F3rd, F4rd, // test4
        input logic P2uses_rs2, // test4.1

        input logic P3we, P4we,
        input logic F3we, F4we, // test4

        // Load hazard 
        input logic P3memRead,

        
        output logic stall,

        output logic [1:0] srcA_SEL, srcB_SEL
    );

    /* Selector bit explained:

        00: Let normal signal through
        01: Let P3 signal through
        10: Let P4 signal through
        default: set output to 0

    // Mux1=srcA_SEL (handles the value in rd for p3 and p4 and the original data in rs1)

    // Mux2=srcB_SEL (handles the value in rd for p3 and p4 and the original data in rs2)

    */


    // This is for the load stall handling
    always_comb begin
        stall = 1'b0;
        if (P3memRead && (P3rd != 5'd0) && ((P3rd == P2rs1) || (P2uses_rs2 && (P3rd == P2rs2)))) begin // test4.1
            stall = 1'b1;
        end
    end


    always_comb begin
        srcA_SEL = 2'b00;
        srcB_SEL = 2'b00;
        if (F3we && (F3rd != 5'd0) && (F3rd == P3rs1)) begin // test4
            srcA_SEL = 2'b01;
        end else if (F4we && (F4rd != 5'd0) && (F4rd == P3rs1)) begin // test4
            srcA_SEL = 2'b10;
        end
        if (F3we && (F3rd != 5'd0) && (F3rd == P3rs2)) begin // test4
            srcB_SEL = 2'b01;
        end else if (F4we && (F4rd != 5'd0) && (F4rd == P3rs2)) begin // test4
            srcB_SEL = 2'b10;
        end
        
    end


endmodule
