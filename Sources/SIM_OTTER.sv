`timescale 1ns / 1ps

/*
logic sCLK;
    //input BTNL;
    logic sBTNC;
    logic [15:0] sSWITCHES;
    logic [15:0] sLEDS;
    logic [7:0] sCATHODES;
    logic [3:0] sANODES;
    
    OTTER_Wrapper UUT (
        .CLK(sCLK),
        .BTNC(sBTNC),
        .SWITCHES(sSWITCHES),
        .LEDS(sLEDS),
        .CATHODES(sCATHODES),
        .ANODES(sANODES)
    );
*/

module SIM_OTTER();

    localparam [31:0] CAL_LEDS = 32'h11000020;
    localparam [31:0] CAL_SSEG = 32'h11000040;
    


    logic sRST;
    logic [31:0] sIOBUS_IN;
    logic sCLK;
    logic sIOBUS_WR;
    logic [31:0] sIOBUS_OUT;
    logic [31:0] sIOBUS_ADDR;
    
    OTTER_MCU UUT (
        .CLK(sCLK),
        .INTR(1'b0),
        .RESET(sRST),
        .IOBUS_IN(sIOBUS_IN),
        
        .IOBUS_WR(sIOBUS_WR),
        .IOBUS_OUT(sIOBUS_OUT),
        .IOBUS_ADDR(sIOBUS_ADDR)
     );
         
    always begin
        #10 sCLK = ~sCLK;
    end

    always_ff @(posedge sCLK) begin
        if (!sRST && sIOBUS_WR && sIOBUS_ADDR == CAL_LEDS) begin
            $display("%0t SUBTEST PASS: led_mask=%h", $time, sIOBUS_OUT);
        end
    
        if (!sRST && sIOBUS_WR && sIOBUS_ADDR == CAL_SSEG) begin
            $display("%0t TEST CATEGORY: %h", $time, sIOBUS_OUT);
    
            if (sIOBUS_OUT == 32'hFFFF_FFFF) begin
                $display("FAIL: category=%0d subtest=%0d",
                         UUT.OTTER_REG_FILE.ram[14],
                         UUT.OTTER_REG_FILE.ram[3]);
                $fatal;
            end
    
            if (sIOBUS_OUT == 32'h00000025) begin
                $display("PASS: Test_All completed one full pass");
                $finish;
            end
        end
    end
    
    
        
    initial begin // start simming
        sCLK = 1'b0;
        sRST = 1'b1;
        sIOBUS_IN = 32'h00000000;
        
        #12 sRST = 1'b0;
//        #10 sRST = 1'b1;
//        #60 sRST = 0;

//        if (sIOBUS_OUT == )
                
    end
endmodule
