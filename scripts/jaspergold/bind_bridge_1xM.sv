// Bind AXI-Lite protocol properties to bridge_1xM (master port)
// Load this after the design and formal/axi_lite_props.sv
bind bridge_1xM axi_lite_props u_props (
    .clk(m_axi.clk),
    .rst_n(m_axi.rst_n),
    .aw_valid(m_axi.aw_valid),
    .aw_ready(m_axi.aw_ready),
    .w_valid(m_axi.w_valid),
    .w_ready(m_axi.w_ready),
    .b_valid(m_axi.b_valid),
    .b_ready(m_axi.b_ready),
    .ar_valid(m_axi.ar_valid),
    .ar_ready(m_axi.ar_ready),
    .r_valid(m_axi.r_valid),
    .r_ready(m_axi.r_ready)
);
