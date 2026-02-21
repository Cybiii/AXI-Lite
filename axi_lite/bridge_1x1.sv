module bridge_1x1 (
    axi_lite_if.master master,
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
    assign master.b_resp   = slave.b_resp;
    assign master.b_valid  = slave.b_valid;
    assign slave.b_ready   = master.b_ready;
    
    // AR
    assign slave.ar_addr   = master.ar_addr;
    assign slave.ar_valid  = master.ar_valid;
    assign master.ar_ready = slave.ar_ready;
    
    // R
    assign master.r_data   = slave.r_data;
    assign master.r_resp   = slave.r_resp;
    assign master.r_valid  = slave.r_valid;
    assign slave.r_ready   = master.r_ready;

endmodule