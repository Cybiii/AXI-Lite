// Testbench for bridge_Nx1: N masters, 1 slave, round-robin arbitration
`timescale 1ns/1ps

module tb_bridge_Nx1;

    parameter int N = 4;
    parameter int ADDR_WIDTH = 32;
    parameter int DATA_WIDTH = 32;

    logic clk, rst_n;

    axi_lite_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) m_axi [N-1:0](.clk(clk), .rst_n(rst_n));
    axi_lite_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) s_axi(.clk(clk), .rst_n(rst_n));

    bridge_Nx1 #(.N(N)) u_dut (
        .m_axi(m_axi),
        .s_axi(s_axi)
    );

    axi_lite_mem_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(4096))
        u_mem (.s_axi(s_axi));

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Test
    int err_count;
    logic [DATA_WIDTH-1:0] rd_data;
    logic [1:0] rd_resp;
    localparam logic [1:0] AXI_OKAY = 2'b00;

    task automatic axi_write_master(int mid, logic [ADDR_WIDTH-1:0] addr, logic [DATA_WIDTH-1:0] data);
        @(posedge clk);
        m_axi[mid].aw_addr  <= addr;
        m_axi[mid].aw_valid <= 1;
        m_axi[mid].w_data   <= data;
        m_axi[mid].w_strb   <= '1;
        m_axi[mid].w_valid  <= 1;
        m_axi[mid].b_ready  <= 1;
        while (!(m_axi[mid].aw_valid && m_axi[mid].aw_ready)) @(posedge clk);
        while (!(m_axi[mid].w_valid && m_axi[mid].w_ready)) @(posedge clk);
        m_axi[mid].aw_valid <= 0;
        m_axi[mid].w_valid  <= 0;
        while (!(m_axi[mid].b_valid && m_axi[mid].b_ready)) @(posedge clk);
        m_axi[mid].b_ready  <= 0;
        @(posedge clk);
    endtask

    task automatic axi_read_master(int mid, logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data, output logic [1:0] resp);
        @(posedge clk);
        m_axi[mid].ar_addr  <= addr;
        m_axi[mid].ar_valid <= 1;
        m_axi[mid].r_ready  <= 1;
        while (!(m_axi[mid].ar_valid && m_axi[mid].ar_ready)) @(posedge clk);
        m_axi[mid].ar_valid <= 0;
        while (!(m_axi[mid].r_valid && m_axi[mid].r_ready)) @(posedge clk);
        data = m_axi[mid].r_data;
        resp = m_axi[mid].r_resp;
        m_axi[mid].r_ready  <= 0;
        @(posedge clk);
    endtask

    initial begin
        rst_n = 0;
        for (int i = 0; i < N; i++) begin
            m_axi[i].aw_addr = 0; m_axi[i].aw_valid = 0;
            m_axi[i].w_data = 0; m_axi[i].w_strb = 0; m_axi[i].w_valid = 0;
            m_axi[i].b_ready = 0;
            m_axi[i].ar_addr = 0; m_axi[i].ar_valid = 0;
            m_axi[i].r_ready = 0;
        end
        err_count = 0;
        #20 rst_n = 1;
        #10;

        $display("[TB] === bridge_Nx1 Test ===");

        // Sequential writes from each master (no contention)
        axi_write_master(0, 32'h0, 32'hDEAD_0000);
        axi_write_master(1, 32'h4, 32'hDEAD_0001);
        axi_write_master(2, 32'h8, 32'hDEAD_0002);
        axi_write_master(3, 32'hC, 32'hDEAD_0003);

        // Read back
        axi_read_master(0, 32'h0, rd_data, rd_resp);
        if (rd_data != 32'hDEAD_0000 || rd_resp != AXI_OKAY) begin
            $display("[FAIL] M0 read: got 0x%08X resp=%b", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] M0 read OK");

        axi_read_master(1, 32'h4, rd_data, rd_resp);
        if (rd_data != 32'hM1_0004 || rd_resp != AXI_OKAY) begin
            $display("[FAIL] M1 read: got 0x%08X resp=%b", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] M1 read OK");

        axi_read_master(2, 32'h8, rd_data, rd_resp);
        if (rd_data != 32'hM2_0008 || rd_resp != AXI_OKAY) begin
            $display("[FAIL] M2 read: got 0x%08X resp=%b", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] M2 read OK");

        axi_read_master(3, 32'hC, rd_data, rd_resp);
        if (rd_data != 32'hM3_000C || rd_resp != AXI_OKAY) begin
            $display("[FAIL] M3 read: got 0x%08X resp=%b", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] M3 read OK");

        // Contention test: all masters assert aw_valid at once
        $display("[TB] Contention test: all masters write simultaneously");
        fork
            axi_write_master(0, 32'h10, 32'hCONTENT_0);
            axi_write_master(1, 32'h14, 32'hCONTENT_1);
            axi_write_master(2, 32'h18, 32'hCONTENT_2);
            axi_write_master(3, 32'h1C, 32'hCONTENT_3);
        join
        $display("[TB] All contention writes completed (round-robin served them)");

        // Verify contention writes
        axi_read_master(0, 32'h10, rd_data, rd_resp);
        if (rd_data != 32'hCONTENT_0) begin
            $display("[FAIL] Addr 0x10: got 0x%08X", rd_data);
            err_count++;
        end else $display("[PASS] Addr 0x10 OK");

        axi_read_master(0, 32'h14, rd_data, rd_resp);
        if (rd_data != 32'hCONTENT_1) begin
            $display("[FAIL] Addr 0x14: got 0x%08X", rd_data);
            err_count++;
        end else $display("[PASS] Addr 0x14 OK");

        axi_read_master(0, 32'h18, rd_data, rd_resp);
        if (rd_data != 32'hCONTENT_2) begin
            $display("[FAIL] Addr 0x18: got 0x%08X", rd_data);
            err_count++;
        end else $display("[PASS] Addr 0x18 OK");

        axi_read_master(0, 32'h1C, rd_data, rd_resp);
        if (rd_data != 32'hCONTENT_3) begin
            $display("[FAIL] Addr 0x1C: got 0x%08X", rd_data);
            err_count++;
        end else $display("[PASS] Addr 0x1C OK");

        // Summary
        if (err_count == 0)
            $display("[TB] === ALL PASS ===");
        else
            $display("[TB] === FAIL: %0d errors ===", err_count);
        #50 $finish;
    end

endmodule
