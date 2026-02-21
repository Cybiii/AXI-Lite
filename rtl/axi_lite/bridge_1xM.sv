// 1 master, M slaves. Address decoding routes to correct slave.
// M = number of slaves (N×M convention)
module bridge_1xM #(
    parameter int M = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR [M] = '{
        32'h0000_0000, 32'h0000_1000, 32'h0000_2000, 32'h0000_3000
    },
    parameter logic [ADDR_WIDTH-1:0] SIZE [M] = '{
        32'h1000, 32'h1000, 32'h1000, 32'h1000
    },
    localparam int SLAVE_ID_W = (M > 1) ? $clog2(M) : 1
) (
    axi_lite_if.master m_axi,
    axi_lite_if.slave  s_axi [M-1:0]
);

    localparam logic [1:0] AXI_DECERR = 2'b11;

    // Decode addresses (combinational)
    logic [SLAVE_ID_W-1:0] aw_slave_id, ar_slave_id;
    logic aw_decerr, ar_decerr;

    addr_decoder #(.M(M), .ADDR_WIDTH(ADDR_WIDTH), .BASE_ADDR(BASE_ADDR), .SIZE(SIZE))
        u_aw_dec (.addr(m_axi.aw_addr), .slave_id(aw_slave_id), .valid(), .decerr(aw_decerr));

    addr_decoder #(.M(M), .ADDR_WIDTH(ADDR_WIDTH), .BASE_ADDR(BASE_ADDR), .SIZE(SIZE))
        u_ar_dec (.addr(m_axi.ar_addr), .slave_id(ar_slave_id), .valid(), .decerr(ar_decerr));

    // Latch slave selection when address handshake completes (for B/R routing)
    logic [SLAVE_ID_W-1:0] write_slave_sel, read_slave_sel;
    logic write_decerr, read_decerr;

    always_ff @(posedge m_axi.clk or negedge m_axi.rst_n) begin
        if (!m_axi.rst_n) begin
            write_slave_sel <= '0;
            read_slave_sel  <= '0;
            write_decerr    <= 0;
            read_decerr     <= 0;
        end else begin
            if (m_axi.aw_valid && m_axi.aw_ready) begin
                write_slave_sel <= aw_slave_id;
                write_decerr    <= aw_decerr;
            end
            if (m_axi.ar_valid && m_axi.ar_ready) begin
                read_slave_sel <= ar_slave_id;
                read_decerr    <= ar_decerr;
            end
        end
    end

    // Request routing: master -> selected slave (or absorb if decerr)
    always_comb begin
        for (int i = 0; i < M; i++) begin
            // AW
            s_axi[i].aw_addr  = m_axi.aw_addr;
            s_axi[i].aw_valid = (i == aw_slave_id && !aw_decerr) ? m_axi.aw_valid : 1'b0;
            // W
            s_axi[i].w_data   = m_axi.w_data;
            s_axi[i].w_strb   = m_axi.w_strb;
            s_axi[i].w_valid  = (i == aw_slave_id && !aw_decerr) ? m_axi.w_valid : 1'b0;
            // B (slave drives b_ready as input to us; we drive b_ready to master from selected slave)
            s_axi[i].b_ready  = (i == write_slave_sel && !write_decerr) ? m_axi.b_ready : 1'b0;
            // AR
            s_axi[i].ar_addr  = m_axi.ar_addr;
            s_axi[i].ar_valid = (i == ar_slave_id && !ar_decerr) ? m_axi.ar_valid : 1'b0;
            // R
            s_axi[i].r_ready  = (i == read_slave_sel && !read_decerr) ? m_axi.r_ready : 1'b0;
        end
    end

    // Master AW ready: from selected slave or 1 when decerr
    assign m_axi.aw_ready = aw_decerr ? 1'b1 : s_axi[aw_slave_id].aw_ready;
    assign m_axi.w_ready  = aw_decerr ? 1'b1 : s_axi[aw_slave_id].w_ready;

    // Master AR ready
    assign m_axi.ar_ready = ar_decerr ? 1'b1 : s_axi[ar_slave_id].ar_ready;

    // Response routing: selected slave -> master (or DECERR)
    assign m_axi.b_resp  = write_decerr ? AXI_DECERR : s_axi[write_slave_sel].b_resp;
    assign m_axi.b_valid = write_decerr ? 1'b1     : s_axi[write_slave_sel].b_valid;

    assign m_axi.r_data  = read_decerr ? '0       : s_axi[read_slave_sel].r_data;
    assign m_axi.r_resp  = read_decerr ? AXI_DECERR : s_axi[read_slave_sel].r_resp;
    assign m_axi.r_valid = read_decerr ? 1'b1     : s_axi[read_slave_sel].r_valid;

endmodule
