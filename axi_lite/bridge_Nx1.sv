// N masters, 1 slave. Round-robin arbitration when multiple masters contend.
// N = number of masters (N×M convention)
module bridge_Nx1 #(
    parameter int N = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    localparam int MASTER_ID_W = (N > 1) ? $clog2(N) : 1
) (
    axi_lite_if.master m_axi [N-1:0],
    axi_lite_if.slave  s_axi
);

    // Arbiter requests: master i has pending AW or AR
    logic [N-1:0] aw_req, ar_req;
    logic [N-1:0] aw_grant, ar_grant;

    // Which master won (for muxing)
    logic [MASTER_ID_W-1:0] aw_master_idx, ar_master_idx;
    logic [MASTER_ID_W-1:0] write_master_sel, read_master_sel;

    // Handshake complete -> rotate arbiter priority
    logic aw_handshake, ar_handshake;
    logic b_handshake, r_handshake;

    // Busy: can't grant new AW/AR until current transaction completes
    logic write_busy, read_busy;

    always_ff @(posedge s_axi.clk or negedge s_axi.rst_n) begin
        if (!s_axi.rst_n) begin
            write_busy <= 0;
            read_busy  <= 0;
        end else begin
            if (aw_handshake)      write_busy <= 1;
            if (b_handshake)       write_busy <= 0;
            if (ar_handshake)     read_busy  <= 1;
            if (r_handshake)      read_busy  <= 0;
        end
    end

    assign b_handshake = s_axi.b_valid && s_axi.b_ready;
    assign r_handshake = s_axi.r_valid && s_axi.r_ready;

    // Arbiter for AW
    rr_arbiter #(.N(N)) u_aw_arb (
        .clk(s_axi.clk),
        .rst_n(s_axi.rst_n),
        .req(aw_req),
        .grant(aw_grant),
        .handshake_complete(aw_handshake)
    );

    // Arbiter for AR
    rr_arbiter #(.N(N)) u_ar_arb (
        .clk(s_axi.clk),
        .rst_n(s_axi.rst_n),
        .req(ar_req),
        .grant(ar_grant),
        .handshake_complete(ar_handshake)
    );

    // Request = master has valid, and we're not busy with another transaction
    always_comb begin
        for (int i = 0; i < N; i++) begin
            aw_req[i] = m_axi[i].aw_valid && !write_busy;
            ar_req[i] = m_axi[i].ar_valid && !read_busy;
        end
    end

    // Grant to index (one-hot to binary)
    always_comb begin
        aw_master_idx = '0;
        ar_master_idx = '0;
        for (int i = 0; i < N; i++) begin
            if (aw_grant[i]) aw_master_idx = i[MASTER_ID_W-1:0];
            if (ar_grant[i]) ar_master_idx = i[MASTER_ID_W-1:0];
        end
    end

    // Handshake complete when valid & ready
    assign aw_handshake = s_axi.aw_valid && s_axi.aw_ready;
    assign ar_handshake = s_axi.ar_valid && s_axi.ar_ready;

    // Latch which master won when address handshake completes (for W/B and R routing)
    always_ff @(posedge s_axi.clk or negedge s_axi.rst_n) begin
        if (!s_axi.rst_n) begin
            write_master_sel <= '0;
            read_master_sel  <= '0;
        end else begin
            if (aw_handshake) write_master_sel <= aw_master_idx;
            if (ar_handshake) read_master_sel  <= ar_master_idx;
        end
    end

    // Request routing: granted master -> slave
    always_comb begin
        s_axi.aw_addr  = m_axi[aw_master_idx].aw_addr;
        s_axi.aw_valid = |aw_grant ? m_axi[aw_master_idx].aw_valid : 1'b0;

        s_axi.w_data   = m_axi[write_master_sel].w_data;
        s_axi.w_strb   = m_axi[write_master_sel].w_strb;
        s_axi.w_valid  = m_axi[write_master_sel].w_valid;

        s_axi.ar_addr  = m_axi[ar_master_idx].ar_addr;
        s_axi.ar_valid = |ar_grant ? m_axi[ar_master_idx].ar_valid : 1'b0;
    end

    // Slave's ready goes back to granted master only
    always_comb begin
        for (int i = 0; i < N; i++) begin
            m_axi[i].aw_ready = (i == aw_master_idx && aw_grant[i]) ? s_axi.aw_ready : 1'b0;
            m_axi[i].w_ready  = (i == write_master_sel) ? s_axi.w_ready : 1'b0;
            m_axi[i].ar_ready = (i == ar_master_idx && ar_grant[i]) ? s_axi.ar_ready : 1'b0;
        end
    end

    // Response routing: slave -> granted master
    always_comb begin
        for (int i = 0; i < N; i++) begin
            m_axi[i].b_resp  = (i == write_master_sel) ? s_axi.b_resp  : '0;
            m_axi[i].b_valid = (i == write_master_sel) ? s_axi.b_valid : 1'b0;
            m_axi[i].r_data  = (i == read_master_sel)  ? s_axi.r_data  : '0;
            m_axi[i].r_resp  = (i == read_master_sel)  ? s_axi.r_resp  : '0;
            m_axi[i].r_valid = (i == read_master_sel)  ? s_axi.r_valid : 1'b0;
        end
    end

    // Master's b_ready and r_ready to slave
    assign s_axi.b_ready = m_axi[write_master_sel].b_ready;
    assign s_axi.r_ready = m_axi[read_master_sel].r_ready;

endmodule
