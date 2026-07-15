`timescale 1ns / 1ps

module SA_Cache (
    input MEM_CLK,
    input MEM_RST,
    input MEM_RDEN1,
    input MEM_RDEN2,
    input MEM_WE2,
    input [13:0] MEM_ADDR1,
    input [31:0] MEM_ADDR2,
    input [31:0] MEM_DIN2,
    input [1:0] MEM_SIZE,
    input MEM_SIGN,
    input [31:0] IO_IN,
    output logic IO_WR,
    output logic MEM_BUSY,
    output logic [31:0] MEM_DOUT1,
    output logic [31:0] MEM_DOUT2
);
    // idk localparam but its the only way this thing will work accd to google.
    localparam int L2_WORDS = 4080; // Test_All.mem has 4080 words at least, this needs to be small or it goes over the mem i have on my laptop accd. to vivado.
    localparam int NUM_SETS = 4;
    localparam int NUM_WAYS = 4;
    localparam int WORDS_PER_BLOCK = 4;
    localparam int SET_BITS = 2;
    localparam int WORD_OFFSET_BITS = 2;
    localparam int BYTE_OFFSET_BITS = 2;
    localparam int TAG_BITS = 32 - SET_BITS - WORD_OFFSET_BITS - BYTE_OFFSET_BITS;
    localparam int L2_TAG_BITS = 14 - SET_BITS - WORD_OFFSET_BITS;

    typedef enum logic [2:0] { // FSM IS BACK 
        DC_IDLE,
        DC_WB,
        DC_REFILL_ISSUE,
        DC_REFILL_CAPTURE,
        DC_COMMIT
    } dcache_state_t;


    // copied from prev.
    (* ram_style = "block" *) logic [31:0] memory [0:L2_WORDS-1];

    // big frickin block of variables.
    logic [31:0] cache_data [0:NUM_SETS-1][0:NUM_WAYS-1][0:WORDS_PER_BLOCK-1];
    logic [TAG_BITS-1:0] cache_tags [0:NUM_SETS-1][0:NUM_WAYS-1];
    logic valid_bits [0:NUM_SETS-1][0:NUM_WAYS-1];
    logic dirty_bits [0:NUM_SETS-1][0:NUM_WAYS-1];
    logic [1:0] lru_rank [0:NUM_SETS-1][0:NUM_WAYS-1];

    dcache_state_t state;

    logic is_mmio;
    logic req_active;
    logic [13:0] wordAddr2;
    logic [1:0] byteOffset;
    logic [SET_BITS-1:0] set_index;
    logic [WORD_OFFSET_BITS-1:0] word_offset;
    logic [TAG_BITS-1:0] addr_tag;
    logic hit_found;
    logic [1:0] hit_way;
    logic [1:0] victim_way; // victim is the guy who gets hit lol
    logic [31:0] read_word;
    logic [31:0] memReadSized;
    logic [13:0] block_base_word_addr;

    logic miss_we; // works now DONT CHANGe
    logic miss_rden;
    logic [31:0] miss_addr;
    logic [31:0] miss_din;
    logic [1:0] miss_size;
    logic miss_sign;
    logic [SET_BITS-1:0] miss_set;
    logic [WORD_OFFSET_BITS-1:0] miss_word_offset;
    logic [TAG_BITS-1:0] miss_tag;
    logic [1:0] miss_victim_way;
    logic [13:0] miss_block_base_word_addr;
    logic [13:0] miss_victim_base_word_addr;
    logic [1:0] refill_index;
    logic [1:0] writeback_index;
    logic [31:0] refill_block [0:WORDS_PER_BLOCK-1];
    logic [13:0] memory_read_addr;
    logic [31:0] memory_read_data;

    
    // integer true_cache_hits;
    // integer true_cache_misses;
    // integer true_cache_writebacks;
    integer cache_hits;
    integer cache_misses;
    integer cache_writebacks;

    function automatic [31:0] load_sized_word(
        input [31:0] src_word,
        input [1:0] mem_size,
        input mem_sign,
        input [1:0] byte_offset
    );
        begin
            case ({mem_sign, mem_size, byte_offset})

                // DO NOT CHANGE THESE
                // they finally work

                5'b00011: load_sized_word = {{24{src_word[31]}}, src_word[31:24]};
                5'b00010: load_sized_word = {{24{src_word[23]}}, src_word[23:16]};
                5'b00001: load_sized_word = {{24{src_word[15]}}, src_word[15:8]};
                5'b00000: load_sized_word = {{ 24{src_word[7]}}, src_word[7:0]};

                5'b00110: load_sized_word = {{16{src_word[31]}}, src_word[31:16]};
                5'b00101: load_sized_word = {{16{src_word[23]}}, src_word[23:8]};
                5'b00100: load_sized_word = {{16{src_word[15]}}, src_word[15:0]};

                5'b01000: load_sized_word = src_word;

                5'b10011: load_sized_word = {24'd0, src_word[31:24]};
                5'b10010: load_sized_word = {24'd0, src_word[23:16]};
                5'b10001: load_sized_word = {24'd0, src_word[15:8]};
                5'b10000: load_sized_word = {24'd0, src_word[7:0]};

                5'b10110: load_sized_word = {16'd0, src_word[31:16]};
                5'b10101: load_sized_word = {16'd0, src_word[23:8]};
                5'b10100: load_sized_word = {16'd0, src_word[15:0]};

                default:  load_sized_word = 32'b0;

                // DO NOT CHANGE THESE
                // they finally work

            endcase
        end
    endfunction


    // had to google syntax for this but function is super useful.
    function automatic [31:0] store_sized_word(
        input [31:0] old_word,
        input [31:0] store_data,
        input [1:0] mem_size,
        input [1:0] byte_offset
    );
        begin
            store_sized_word = old_word;
            case ({mem_size, byte_offset})
                4'b0000: store_sized_word[7:0] = store_data[7:0];
                4'b0001: store_sized_word[15:8] = store_data[7:0];

                4'b0010: store_sized_word[23:16] = store_data[7:0];
                4'b0011: store_sized_word[31:24] = store_data[7:0];
                4'b0100: store_sized_word[15:0] = store_data[15:0];


                4'b0101: store_sized_word[23:8] = store_data[15:0];
                4'b0110: store_sized_word[31:16] = store_data[15:0];

                //NO
                //4'b1000: store_sized_word = store_data;

                4'b1000: store_sized_word = store_data;
                default: store_sized_word = old_word;
            endcase
        end
    endfunction

    initial begin
        // IF IN VIVADO, CHANGE THIS:
        $readmemh("test_hfu.mem", memory, 0, L2_WORDS - 1);
    end

    assign is_mmio = (MEM_ADDR2 >= 32'h00010000);
    assign req_active = !is_mmio && (MEM_RDEN2 || MEM_WE2);
    assign wordAddr2 = MEM_ADDR2[15:2];
    assign byteOffset = MEM_ADDR2[1:0];
    assign word_offset = MEM_ADDR2[3:2];
    assign set_index = MEM_ADDR2[5:4];
    assign addr_tag = MEM_ADDR2[31:6];
    assign block_base_word_addr = {wordAddr2[13:2], 2'b00};

    always_comb begin
        // actual memory loop

        int way;

        hit_found = 1'b0;
        hit_way = 2'b00;
        victim_way = 2'b00;

        for (way = 0; way < NUM_WAYS; way = way + 1) begin
            if (valid_bits[set_index][way] && (cache_tags[set_index][way] == addr_tag)) begin
                hit_found = 1'b1;
                hit_way = way[1:0];
            end
        end

        for (way = 1; way < NUM_WAYS; way = way + 1) begin
            if (!valid_bits[set_index][way] && valid_bits[set_index][victim_way]) begin
                victim_way = way[1:0];
            end else if (valid_bits[set_index][way] &&
                         valid_bits[set_index][victim_way] &&
                         (lru_rank[set_index][way] > lru_rank[set_index][victim_way])) begin
                victim_way = way[1:0];
            end
        end

        read_word = 32'b0;
        if (hit_found) begin
            read_word = cache_data[set_index][hit_way][word_offset];
        end

        memReadSized = load_sized_word(read_word, MEM_SIZE, MEM_SIGN, byteOffset);

        IO_WR = 1'b0;
        MEM_BUSY = (state != DC_IDLE) || (req_active && !hit_found);
        MEM_DOUT2 = memReadSized;

        if (is_mmio) begin
            IO_WR = MEM_WE2;
            MEM_BUSY = 1'b0;
            MEM_DOUT2 = IO_IN;
        end
    end

    always_ff @(posedge MEM_CLK) begin
        // rank stuff

        int i;
        int s;
        int w;
        int b;
        int old_rank;

        if (MEM_RST) begin
            state <= DC_IDLE;
            memory_read_addr <= 14'd0;
            memory_read_data <= 32'd0;
            MEM_DOUT1 <= 32'd0;
            cache_hits <= 0;
            cache_misses <= 0;
            cache_writebacks <= 0;

            miss_we <= 1'b0;
            miss_rden <= 1'b0;
            miss_addr <= 32'd0;
            miss_din <= 32'd0;
            miss_size <= 2'd0;
            miss_sign <= 1'b0;
            miss_set <= '0;
            miss_word_offset <= '0;
            miss_tag <= '0;
            miss_victim_way <= 2'd0; // v
            miss_block_base_word_addr <= 14'd0;
            miss_victim_base_word_addr <= 14'd0;
            refill_index <= 2'd0;
            writeback_index <= 2'd0;


            // generate memory all zeroes
            for (s = 0; s < NUM_SETS; s = s + 1) begin
                for (w = 0; w < NUM_WAYS; w = w + 1) begin
                    valid_bits[s][w] <= 1'b0;
                    dirty_bits[s][w] <= 1'b0;
                    cache_tags[s][w] <= '0;
                    lru_rank[s][w] <= w[1:0];
                    for (b = 0; b < WORDS_PER_BLOCK; b = b + 1) begin
                        cache_data[s][w][b] <= 32'd0;
                    end
                end
            end

            for (b = 0; b < WORDS_PER_BLOCK; b = b + 1) begin
                refill_block[b] <= 32'd0;
            end

        end else begin

            // read memory from file
            memory_read_data <= memory[memory_read_addr];

            if (MEM_RDEN1) begin
                MEM_DOUT1 <= memory[MEM_ADDR1];
            end

            case (state)
                DC_IDLE: begin
                    if (req_active) begin // showtime
                        if (hit_found) begin // WE GOT A HIT!!!
                            cache_hits <= cache_hits + 1;


                            // cache updates, dirty bit
                            if (MEM_WE2) begin
                                cache_data[set_index][hit_way][word_offset] <= store_sized_word(
                                    cache_data[set_index][hit_way][word_offset],
                                    MEM_DIN2,
                                    MEM_SIZE,
                                    byteOffset
                                );
                                dirty_bits[set_index][hit_way] <= 1'b1;
                            end

                            // update lru vals
                            old_rank = lru_rank[set_index][hit_way];
                            for (i = 0; i < NUM_WAYS; i = i + 1) begin
                                if (i == hit_way) begin
                                    lru_rank[set_index][i] <= 2'd0;
                                end else if (valid_bits[set_index][i] &&
                                             (lru_rank[set_index][i] < old_rank[1:0])) begin
                                    lru_rank[set_index][i] <= lru_rank[set_index][i] + 1'b1;
                                end
                            end
                        end else begin


                            // update all these vars
                            cache_misses <= cache_misses + 1;
                            miss_we <= MEM_WE2;
                            miss_rden <= MEM_RDEN2;
                            miss_addr <= MEM_ADDR2;
                            miss_din <= MEM_DIN2;
                            miss_size <= MEM_SIZE;
                            miss_sign <= MEM_SIGN;
                            miss_set <= set_index;
                            miss_word_offset <= word_offset;
                            miss_tag <= addr_tag;
                            miss_victim_way <= victim_way;
                            miss_block_base_word_addr <= block_base_word_addr;
                            miss_victim_base_word_addr <= {
                                cache_tags[set_index][victim_way][L2_TAG_BITS-1:0],
                                set_index,
                                2'b00
                            };
                            refill_index <= 2'd0;
                            writeback_index <= 2'd0;

                            if (valid_bits[set_index][victim_way] && dirty_bits[set_index][victim_way]) begin
                                state <= DC_WB;
                            end else begin
                                memory_read_addr <= block_base_word_addr;
                                state <= DC_REFILL_ISSUE;
                            end
                        end
                    end
                end

                DC_WB: begin

                    // WB 
                    memory[miss_victim_base_word_addr + writeback_index] <=
                        cache_data[miss_set][miss_victim_way][writeback_index];

                    if (writeback_index == WORDS_PER_BLOCK - 1) begin
                        cache_writebacks <= cache_writebacks + 1;
                        writeback_index <= 2'd0;
                        memory_read_addr <= miss_block_base_word_addr;
                        state <= DC_REFILL_ISSUE;
                    end else begin
                        writeback_index <= writeback_index + 1'b1;
                    end
                end

                DC_REFILL_ISSUE: begin

                    // bug fix. think this worked.
                    state <= DC_REFILL_CAPTURE;
                end

                DC_REFILL_CAPTURE: begin
                    refill_block[refill_index] <= memory_read_data;

                    if (refill_index == WORDS_PER_BLOCK - 1) begin
                        state <= DC_COMMIT;
                    end else begin
                        refill_index <= refill_index + 1'b1;
                        memory_read_addr <= miss_block_base_word_addr + refill_index + 1'b1;
                        state <= DC_REFILL_ISSUE;
                    end
                end

                DC_COMMIT: begin

                    // CACHE THE DATA
                    for (i = 0; i < WORDS_PER_BLOCK; i = i + 1) begin
                        cache_data[miss_set][miss_victim_way][i] <= refill_block[i];
                    end

                    if (miss_we) begin
                        cache_data[miss_set][miss_victim_way][miss_word_offset] <= store_sized_word(
                            refill_block[miss_word_offset],
                            miss_din,
                            miss_size,
                            miss_addr[1:0]
                        );
                    end


                    // this is kinda clean, dont change this
                    cache_tags[miss_set][miss_victim_way] <= miss_tag;
                    valid_bits[miss_set][miss_victim_way] <= 1'b1;
                    dirty_bits[miss_set][miss_victim_way] <= miss_we;


                    // update LRUs
                    for (i = 0; i < NUM_WAYS; i = i + 1) begin
                        if (i == miss_victim_way) begin
                            lru_rank[miss_set][i] <= 2'd0;
                        end else if (valid_bits[miss_set][i] &&
                                     (lru_rank[miss_set][i] != (NUM_WAYS - 1))) begin
                            lru_rank[miss_set][i] <= lru_rank[miss_set][i] + 1'b1;
                        end
                    end

                    state <= DC_IDLE;
                end

                default: begin
                    // chill
                    state <= DC_IDLE;
                end

            endcase
        end
    end

endmodule
