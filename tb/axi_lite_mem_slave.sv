// Simple AXI-Lite memory slave. Responds to writes and reads.
// Assumes 32-bit data width.
module axi_lite_mem_slave #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_SIZE   = 4096  // bytes
) (
    axi_lite_if.slave s_axi
);

    localparam int MEM_DEPTH = MEM_SIZE / (DATA_WIDTH/8);
    logic [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0];

    localparam logic [1:0] AXI_OKAY = 2'b00;

    // AW handshake: accept when valid
    assign s_axi.aw_ready = 1'b1;
    // W handshake
    assign s_axi.w_ready  = 1'b1;
    // AR handshake
    assign s_axi.ar_ready = 1'b1;

    // Track write: need AW addr + W data. Use simple state.
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [DATA_WIDTH/8-1:0] wr_strb;
    logic wr_pending;
    logic [1:0] wr_state;  // 0=idle, 1=aw_done, 2=w_done, 3=send_b

    always_ff @(posedge s_axi.clk or negedge s_axi.rst_n) begin
        if (!s_axi.rst_n) begin
            wr_addr    <= 0;
            wr_data    <= 0;
            wr_strb    <= 0;
            wr_pending <= 0;
            wr_state   <= 0;
            s_axi.b_valid <= 0;
            s_axi.b_resp  <= 0;
        end else begin
            case (wr_state)
                2'd0: begin
                    if (s_axi.aw_valid && s_axi.aw_ready) begin
                        wr_addr  <= s_axi.aw_addr;
                        wr_state <= 2'd1;
                    end
                end
                2'd1: begin
                    if (s_axi.w_valid && s_axi.w_ready) begin
                        wr_data  <= s_axi.w_data;
                        wr_strb  <= s_axi.w_strb;
                        wr_state <= 2'd2;
                    end
                end
                2'd2: begin
                    wr_state   <= 2'd3;
                    s_axi.b_valid <= 1;
                    s_axi.b_resp  <= AXI_OKAY;
                end
                2'd3: begin
                    if (s_axi.b_ready) begin
                        s_axi.b_valid <= 0;
                        wr_state      <= 2'd0;
                    end
                end
            endcase
        end
    end

    // Write to mem when we have both addr and data
    always_ff @(posedge s_axi.clk) begin
        if (wr_state == 2'd2) begin
            for (int i = 0; i < DATA_WIDTH/8; i++) begin
                if (wr_strb[i]) begin
                    mem[(wr_addr >> $clog2(DATA_WIDTH/8)) % MEM_DEPTH][i*8 +: 8] <= wr_data[i*8 +: 8];
                end
            end
        end
    end

    // Read: capture AR, then send R
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [1:0] rd_state;

    always_ff @(posedge s_axi.clk or negedge s_axi.rst_n) begin
        if (!s_axi.rst_n) begin
            rd_addr       <= 0;
            rd_state      <= 0;
            s_axi.r_valid <= 0;
            s_axi.r_data  <= 0;
            s_axi.r_resp  <= 0;
        end else begin
            case (rd_state)
                2'd0: begin
                    if (s_axi.ar_valid && s_axi.ar_ready) begin
                        rd_addr  <= s_axi.ar_addr;
                        rd_state <= 2'd1;
                    end
                end
                2'd1: begin
                    s_axi.r_valid <= 1;
                    s_axi.r_data  <= mem[(rd_addr >> $clog2(DATA_WIDTH/8)) % MEM_DEPTH];
                    s_axi.r_resp  <= AXI_OKAY;
                    rd_state      <= 2'd2;
                end
                2'd2: begin
                    if (s_axi.r_ready) begin
                        s_axi.r_valid <= 0;
                        rd_state      <= 2'd0;
                    end
                end
            endcase
        end
    end

endmodule
