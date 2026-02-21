// 1 master, M slaves. Address decoding routes to correct slave.
// M = number of slaves (N×M convention)
module bridge_1xM #(
    parameter int M = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter [ADDR_WIDTH*M-1:0] BASE_ADDR_PACKED = {32'h0000_3000, 32'h0000_2000, 32'h0000_1000, 32'h0000_0000},
    parameter [ADDR_WIDTH*M-1:0] SIZE_PACKED     = {32'h1000, 32'h1000, 32'h1000, 32'h1000}
) (
    axi_lite_if.master m_axi,
    axi_lite_if.slave  s_axi [M-1:0]
);

    localparam int SLAVE_ID_W = (M > 1) ? $clog2(M) : 1;
    localparam logic [1:0] AXI_DECERR = 2'b11;

    // Decode addresses (combinational)
    logic [SLAVE_ID_W-1:0] aw_slave_id, ar_slave_id;
    logic aw_decerr, ar_decerr;

    addr_decoder #(.M(M), .ADDR_WIDTH(ADDR_WIDTH), .BASE_ADDR_PACKED(BASE_ADDR_PACKED), .SIZE_PACKED(SIZE_PACKED))
        u_aw_dec (.addr(m_axi.aw_addr), .slave_id(aw_slave_id), .valid(), .decerr(aw_decerr));
    addr_decoder #(.M(M), .ADDR_WIDTH(ADDR_WIDTH), .BASE_ADDR_PACKED(BASE_ADDR_PACKED), .SIZE_PACKED(SIZE_PACKED))
        u_ar_dec (.addr(m_axi.ar_addr), .slave_id(ar_slave_id), .valid(), .decerr(ar_decerr));

    // Latch slave selection when address handshake completes (for B/R routing)
    logic [SLAVE_ID_W-1:0] write_slave_sel, read_slave_sel;
    logic write_decerr, read_decerr;

    // Track when AW and W complete with decerr (they can complete in any order)
    logic aw_done_decerr, w_done_decerr;
    logic pending_B_decerr, pending_R_decerr;

    always_ff @(posedge m_axi.clk or negedge m_axi.rst_n) begin
        if (!m_axi.rst_n) begin
            write_slave_sel <= '0;
            read_slave_sel  <= '0;
            write_decerr    <= 0;
            read_decerr     <= 0;
            aw_done_decerr  <= 0;
            w_done_decerr   <= 0;
            pending_B_decerr <= 0;
            pending_R_decerr <= 0;
        end else begin
            // Write path
            if (m_axi.aw_valid && m_axi.aw_ready) begin
                write_slave_sel <= aw_slave_id;
                write_decerr    <= aw_decerr;
                aw_done_decerr  <= aw_decerr;
            end
            if (m_axi.w_valid && m_axi.w_ready) begin
                w_done_decerr <= aw_decerr;  // W for same transaction as AW
            end
            if (aw_done_decerr && w_done_decerr) begin
                pending_B_decerr <= 1;
            end
            if (pending_B_decerr && m_axi.b_ready) begin
                pending_B_decerr <= 0;
                aw_done_decerr   <= 0;
                w_done_decerr    <= 0;
            end

            // Read path
            if (m_axi.ar_valid && m_axi.ar_ready) begin
                read_slave_sel <= ar_slave_id;
                read_decerr    <= ar_decerr;
                pending_R_decerr <= ar_decerr;
            end
            if (pending_R_decerr && m_axi.r_ready) begin
                pending_R_decerr <= 0;
            end
        end
    end

    // Packed arrays to avoid variable indexing of interface array (Xcelium limitation)
    logic aw_ready_vec [M-1:0], w_ready_vec [M-1:0], ar_ready_vec [M-1:0];
    logic [1:0] b_resp_vec [M-1:0], r_resp_vec [M-1:0];
    logic b_valid_vec [M-1:0], r_valid_vec [M-1:0];
    logic [DATA_WIDTH-1:0] r_data_vec [M-1:0];

    genvar gi;
    generate
        for (gi = 0; gi < M; gi++) begin : gen_slave
            assign aw_ready_vec[gi] = s_axi[gi].aw_ready;
            assign w_ready_vec[gi]  = s_axi[gi].w_ready;
            assign ar_ready_vec[gi] = s_axi[gi].ar_ready;
            assign b_resp_vec[gi]   = s_axi[gi].b_resp;
            assign b_valid_vec[gi] = s_axi[gi].b_valid;
            assign r_data_vec[gi]  = s_axi[gi].r_data;
            assign r_resp_vec[gi]  = s_axi[gi].r_resp;
            assign r_valid_vec[gi] = s_axi[gi].r_valid;

            assign s_axi[gi].aw_addr  = m_axi.aw_addr;
            assign s_axi[gi].aw_valid = (aw_slave_id == gi && !aw_decerr) ? m_axi.aw_valid : 1'b0;
            assign s_axi[gi].w_data   = m_axi.w_data;
            assign s_axi[gi].w_strb   = m_axi.w_strb;
            assign s_axi[gi].w_valid  = (aw_slave_id == gi && !aw_decerr) ? m_axi.w_valid : 1'b0;
            assign s_axi[gi].b_ready  = (write_slave_sel == gi && !write_decerr) ? m_axi.b_ready : 1'b0;
            assign s_axi[gi].ar_addr  = m_axi.ar_addr;
            assign s_axi[gi].ar_valid = (ar_slave_id == gi && !ar_decerr) ? m_axi.ar_valid : 1'b0;
            assign s_axi[gi].r_ready  = (read_slave_sel == gi && !read_decerr) ? m_axi.r_ready : 1'b0;
        end
    endgenerate

    // Master ready/resp: mux from packed arrays (variable index on logic OK)
    assign m_axi.aw_ready = aw_decerr ? 1'b1 : aw_ready_vec[aw_slave_id];
    assign m_axi.w_ready  = aw_decerr ? 1'b1 : w_ready_vec[aw_slave_id];
    assign m_axi.ar_ready = ar_decerr ? 1'b1 : ar_ready_vec[ar_slave_id];
    assign m_axi.b_resp   = pending_B_decerr ? AXI_DECERR : b_resp_vec[write_slave_sel];
    assign m_axi.b_valid  = pending_B_decerr ? 1'b1      : b_valid_vec[write_slave_sel];
    assign m_axi.r_data   = pending_R_decerr ? '0        : r_data_vec[read_slave_sel];
    assign m_axi.r_resp   = pending_R_decerr ? AXI_DECERR : r_resp_vec[read_slave_sel];
    assign m_axi.r_valid  = pending_R_decerr ? 1'b1      : r_valid_vec[read_slave_sel];

endmodule
