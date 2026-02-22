// N masters, 1 slave. Round-robin arbitration when multiple masters contend.
// N = number of masters (N×M convention). Written with constant indices for JasperGold Analyze RTL (N=4).
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

    // Request = master has valid, and we're not busy (constant index only)
    always_comb begin
        aw_req[0] = m_axi[0].aw_valid && !write_busy;
        aw_req[1] = m_axi[1].aw_valid && !write_busy;
        aw_req[2] = m_axi[2].aw_valid && !write_busy;
        aw_req[3] = m_axi[3].aw_valid && !write_busy;
        ar_req[0] = m_axi[0].ar_valid && !read_busy;
        ar_req[1] = m_axi[1].ar_valid && !read_busy;
        ar_req[2] = m_axi[2].ar_valid && !read_busy;
        ar_req[3] = m_axi[3].ar_valid && !read_busy;
    end

    // Grant to index (one-hot to binary)
    always_comb begin
        aw_master_idx = 0;
        ar_master_idx = 0;
        if (aw_grant[0]) aw_master_idx = 0;
        else if (aw_grant[1]) aw_master_idx = 1;
        else if (aw_grant[2]) aw_master_idx = 2;
        else if (aw_grant[3]) aw_master_idx = 3;
        if (ar_grant[0]) ar_master_idx = 0;
        else if (ar_grant[1]) ar_master_idx = 1;
        else if (ar_grant[2]) ar_master_idx = 2;
        else if (ar_grant[3]) ar_master_idx = 3;
    end

    assign aw_handshake = s_axi.aw_valid && s_axi.aw_ready;
    assign ar_handshake = s_axi.ar_valid && s_axi.ar_ready;

    // Latch which master won when address handshake completes
    always_ff @(posedge s_axi.clk or negedge s_axi.rst_n) begin
        if (!s_axi.rst_n) begin
            write_master_sel <= 0;
            read_master_sel  <= 0;
        end else begin
            if (aw_handshake) write_master_sel <= aw_master_idx;
            if (ar_handshake) read_master_sel  <= ar_master_idx;
        end
    end

    // Request routing: granted master -> slave (constant-index mux)
    always_comb begin
        if (aw_master_idx == 0) begin
            s_axi.aw_addr  = m_axi[0].aw_addr;
            s_axi.aw_valid = |aw_grant ? m_axi[0].aw_valid : 1'b0;
        end else if (aw_master_idx == 1) begin
            s_axi.aw_addr  = m_axi[1].aw_addr;
            s_axi.aw_valid = |aw_grant ? m_axi[1].aw_valid : 1'b0;
        end else if (aw_master_idx == 2) begin
            s_axi.aw_addr  = m_axi[2].aw_addr;
            s_axi.aw_valid = |aw_grant ? m_axi[2].aw_valid : 1'b0;
        end else begin
            s_axi.aw_addr  = m_axi[3].aw_addr;
            s_axi.aw_valid = |aw_grant ? m_axi[3].aw_valid : 1'b0;
        end

        if (write_master_sel == 0) begin
            s_axi.w_data  = m_axi[0].w_data;
            s_axi.w_strb  = m_axi[0].w_strb;
            s_axi.w_valid = m_axi[0].w_valid;
        end else if (write_master_sel == 1) begin
            s_axi.w_data  = m_axi[1].w_data;
            s_axi.w_strb  = m_axi[1].w_strb;
            s_axi.w_valid = m_axi[1].w_valid;
        end else if (write_master_sel == 2) begin
            s_axi.w_data  = m_axi[2].w_data;
            s_axi.w_strb  = m_axi[2].w_strb;
            s_axi.w_valid = m_axi[2].w_valid;
        end else begin
            s_axi.w_data  = m_axi[3].w_data;
            s_axi.w_strb  = m_axi[3].w_strb;
            s_axi.w_valid = m_axi[3].w_valid;
        end

        if (ar_master_idx == 0) begin
            s_axi.ar_addr  = m_axi[0].ar_addr;
            s_axi.ar_valid = |ar_grant ? m_axi[0].ar_valid : 1'b0;
        end else if (ar_master_idx == 1) begin
            s_axi.ar_addr  = m_axi[1].ar_addr;
            s_axi.ar_valid = |ar_grant ? m_axi[1].ar_valid : 1'b0;
        end else if (ar_master_idx == 2) begin
            s_axi.ar_addr  = m_axi[2].ar_addr;
            s_axi.ar_valid = |ar_grant ? m_axi[2].ar_valid : 1'b0;
        end else begin
            s_axi.ar_addr  = m_axi[3].ar_addr;
            s_axi.ar_valid = |ar_grant ? m_axi[3].ar_valid : 1'b0;
        end
    end

    // Slave's ready -> granted master only (constant index)
    always_comb begin
        m_axi[0].aw_ready = (aw_master_idx == 0 && aw_grant[0]) ? s_axi.aw_ready : 1'b0;
        m_axi[0].w_ready  = (write_master_sel == 0) ? s_axi.w_ready : 1'b0;
        m_axi[0].ar_ready = (ar_master_idx == 0 && ar_grant[0]) ? s_axi.ar_ready : 1'b0;
        m_axi[1].aw_ready = (aw_master_idx == 1 && aw_grant[1]) ? s_axi.aw_ready : 1'b0;
        m_axi[1].w_ready  = (write_master_sel == 1) ? s_axi.w_ready : 1'b0;
        m_axi[1].ar_ready = (ar_master_idx == 1 && ar_grant[1]) ? s_axi.ar_ready : 1'b0;
        m_axi[2].aw_ready = (aw_master_idx == 2 && aw_grant[2]) ? s_axi.aw_ready : 1'b0;
        m_axi[2].w_ready  = (write_master_sel == 2) ? s_axi.w_ready : 1'b0;
        m_axi[2].ar_ready = (ar_master_idx == 2 && ar_grant[2]) ? s_axi.ar_ready : 1'b0;
        m_axi[3].aw_ready = (aw_master_idx == 3 && aw_grant[3]) ? s_axi.aw_ready : 1'b0;
        m_axi[3].w_ready  = (write_master_sel == 3) ? s_axi.w_ready : 1'b0;
        m_axi[3].ar_ready = (ar_master_idx == 3 && ar_grant[3]) ? s_axi.ar_ready : 1'b0;
    end

    // Response routing: slave -> granted master (constant index)
    always_comb begin
        m_axi[0].b_resp  = (write_master_sel == 0) ? s_axi.b_resp  : 2'b00;
        m_axi[0].b_valid = (write_master_sel == 0) ? s_axi.b_valid : 1'b0;
        m_axi[0].r_data  = (read_master_sel == 0)  ? s_axi.r_data  : 32'b0;
        m_axi[0].r_resp  = (read_master_sel == 0)  ? s_axi.r_resp  : 2'b00;
        m_axi[0].r_valid = (read_master_sel == 0)  ? s_axi.r_valid : 1'b0;
        m_axi[1].b_resp  = (write_master_sel == 1) ? s_axi.b_resp  : 2'b00;
        m_axi[1].b_valid = (write_master_sel == 1) ? s_axi.b_valid : 1'b0;
        m_axi[1].r_data  = (read_master_sel == 1)  ? s_axi.r_data  : 32'b0;
        m_axi[1].r_resp  = (read_master_sel == 1)  ? s_axi.r_resp  : 2'b00;
        m_axi[1].r_valid = (read_master_sel == 1)  ? s_axi.r_valid : 1'b0;
        m_axi[2].b_resp  = (write_master_sel == 2) ? s_axi.b_resp  : 2'b00;
        m_axi[2].b_valid = (write_master_sel == 2) ? s_axi.b_valid : 1'b0;
        m_axi[2].r_data  = (read_master_sel == 2)  ? s_axi.r_data  : 32'b0;
        m_axi[2].r_resp  = (read_master_sel == 2)  ? s_axi.r_resp  : 2'b00;
        m_axi[2].r_valid = (read_master_sel == 2)  ? s_axi.r_valid : 1'b0;
        m_axi[3].b_resp  = (write_master_sel == 3) ? s_axi.b_resp  : 2'b00;
        m_axi[3].b_valid = (write_master_sel == 3) ? s_axi.b_valid : 1'b0;
        m_axi[3].r_data  = (read_master_sel == 3)  ? s_axi.r_data  : 32'b0;
        m_axi[3].r_resp  = (read_master_sel == 3)  ? s_axi.r_resp  : 2'b00;
        m_axi[3].r_valid = (read_master_sel == 3)  ? s_axi.r_valid : 1'b0;
    end

    // Master's b_ready and r_ready to slave (constant-index mux)
    assign s_axi.b_ready = (write_master_sel == 0) ? m_axi[0].b_ready :
                           (write_master_sel == 1) ? m_axi[1].b_ready :
                           (write_master_sel == 2) ? m_axi[2].b_ready : m_axi[3].b_ready;
    assign s_axi.r_ready = (read_master_sel == 0) ? m_axi[0].r_ready :
                           (read_master_sel == 1) ? m_axi[1].r_ready :
                           (read_master_sel == 2) ? m_axi[2].r_ready : m_axi[3].r_ready;

endmodule
