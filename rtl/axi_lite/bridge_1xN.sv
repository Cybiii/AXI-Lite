module bridge_1xM (
    axi_lite_if.master master
    axi_lite_if.slave slave
);
    //AW
    assign slave.aw_addr = master.aw_addr;
    assign slave.aw_valid = master.aw_valid;
    assign master.aw_ready = slave.aw_ready;

    //W
    assign slave.w_data = master.w_data;
    assign slave.w_strb = master.w_strb;
    assign slave.w_valid = master.w_valid;
    assign master.w_ready = slave.w_ready;

    // B
    assign m_axi.b_resp   = s_axi.b_resp;
    assign m_axi.b_valid  = s_axi.b_valid;
    assign s_axi.b_ready  = m_axi.b_ready;
    
    // AR
    assign s_axi.ar_addr  = m_axi.ar_addr;
    assign s_axi.ar_valid = m_axi.ar_valid;
    assign m_axi.ar_ready = s_axi.ar_ready;
    
    // R
    assign m_axi.r_data   = s_axi.r_data;
    assign m_axi.r_resp   = s_axi.r_resp;
    assign m_axi.r_valid  = s_axi.r_valid;
    assign s_axi.r_ready  = m_axi.r_ready;

endmodule