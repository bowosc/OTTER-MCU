module imem(
    input logic CLK,
    input logic RST,
    input logic EN,
    input logic [31:0] a,
    output logic [31:0] rd
    );

    // idk localparam but it works.
    // googled it.
    localparam int IMEM_WORDS = 4096;

    (* rom_style = "block" *) logic [31:0] ram [0:IMEM_WORDS-1];
    logic [11:0] word_addr;

    assign word_addr = a[13:2];

    initial begin
        int i;

        for (i = 0; i < IMEM_WORDS; i = i + 1) begin
            ram[i] = 32'h00000013; // nop
        end


        // IF YOU'RE IN VIVADO, CHANGE THIS:
        $readmemh("asm_code/Test_All.mem", ram, 0, IMEM_WORDS - 1);
    end

    always_ff @(posedge CLK) begin

        // rst it all
        if (RST) begin
            rd <= 32'h00000013;
        end else if (EN) begin
            rd <= ram[word_addr];
        end
    end
endmodule
