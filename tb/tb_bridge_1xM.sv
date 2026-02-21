// Testbench for bridge_1xM: 1 master, M slaves, address decoding
`timescale 1ns/1ps

module tb_bridge_1xM;

    parameter int M = 4;
    parameter int ADDR_WIDTH = 32;
    parameter int DATA_WIDTH = 32;

    logic clk, rst_n;

    axi_lite_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) m_axi(.clk(clk), .rst_n(rst_n));
    axi_lite_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) s_axi [M-1:0](.clk(clk), .rst_n(rst_n));

    bridge_1xM #(
        .M(M),
        .BASE_ADDR('{32'h0000_0000, 32'h0000_1000, 32'h0000_2000, 32'h0000_3000}),
        .SIZE('{32'h1000, 32'h1000, 32'h1000, 32'h1000})
    ) u_dut (
        .m_axi(m_axi),
        .s_axi(s_axi)
    );

    // Memory slaves
    genvar g;
    generate
        for (g = 0; g < M; g++) begin : gen_mem
            axi_lite_mem_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(4096))
                u_mem (.s_axi(s_axi[g]));
        end
    endgenerate

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Test
    int err_count;
    localparam logic [1:0] AXI_OKAY = 2'b00, AXI_DECERR = 2'b11;

    task automatic axi_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
        @(posedge clk);
        m_axi.aw_addr  <= addr;
        m_axi.aw_valid <= 1;
        m_axi.w_data   <= data;
        m_axi.w_strb   <= '1;
        m_axi.w_valid  <= 1;
        m_axi.b_ready  <= 1;
        while (!(m_axi.aw_valid && m_axi.aw_ready)) @(posedge clk);
        while (!(m_axi.w_valid && m_axi.w_ready)) @(posedge clk);
        m_axi.aw_valid <= 0;
        m_axi.w_valid  <= 0;
        while (!(m_axi.b_valid && m_axi.b_ready)) @(posedge clk);
        m_axi.b_ready  <= 0;
        @(posedge clk);
    endtask

    task automatic axi_read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data, output logic [1:0] resp);
        @(posedge clk);
        m_axi.ar_addr  <= addr;
        m_axi.ar_valid <= 1;
        m_axi.r_ready  <= 1;
        while (!(m_axi.ar_valid && m_axi.ar_ready)) @(posedge clk);
        m_axi.ar_valid <= 0;
        while (!(m_axi.r_valid && m_axi.r_ready)) @(posedge clk);
        data = m_axi.r_data;
        resp = m_axi.r_resp;
        m_axi.r_ready  <= 0;
        @(posedge clk);
    endtask

    logic [DATA_WIDTH-1:0] rd_data;
    logic [1:0] rd_resp;

    initial begin
        rst_n = 0;
        m_axi.aw_addr = 0; m_axi.aw_valid = 0;
        m_axi.w_data = 0; m_axi.w_strb = 0; m_axi.w_valid = 0;
        m_axi.b_ready = 0;
        m_axi.ar_addr = 0; m_axi.ar_valid = 0;
        m_axi.r_ready = 0;
        err_count = 0;
        #20 rst_n = 1;
        #10;

        $display("[TB] === bridge_1xM Test ===");

        // Write to each slave
        axi_write(32'h0000_0000, 32'hDEAD_0000);  // Slave 0
        axi_write(32'h0000_1000, 32'hDEAD_1000);  // Slave 1
        axi_write(32'h0000_2000, 32'hDEAD_2000);  // Slave 2
        axi_write(32'h0000_3000, 32'hDEAD_3000);  // Slave 3

        // Read back and verify
        axi_read(32'h0000_0000, rd_data, rd_resp);
        if (rd_data != 32'hDEAD_0000 || rd_resp != AXI_OKAY) begin
            $display("[FAIL] Slave 0: got 0x%08X resp=%b, expected 0xDEAD0000 OKAY", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] Slave 0 read OK");

        axi_read(32'h0000_1000, rd_data, rd_resp);
        if (rd_data != 32'hDEAD_1000 || rd_resp != AXI_OKAY) begin
            $display("[FAIL] Slave 1: got 0x%08X resp=%b", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] Slave 1 read OK");

        axi_read(32'h0000_2000, rd_data, rd_resp);
        if (rd_data != 32'hDEAD_2000 || rd_resp != AXI_OKAY) begin
            $display("[FAIL] Slave 2: got 0x%08X resp=%b", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] Slave 2 read OK");

        axi_read(32'h0000_3000, rd_data, rd_resp);
        if (rd_data != 32'hDEAD_3000 || rd_resp != AXI_OKAY) begin
            $display("[FAIL] Slave 3: got 0x%08X resp=%b", rd_data, rd_resp);
            err_count++;
        end else $display("[PASS] Slave 3 read OK");

        // Unmapped address -> DECERR
        axi_read(32'h0001_0000, rd_data, rd_resp);
        if (rd_resp != AXI_DECERR) begin
            $display("[FAIL] Unmapped read: expected DECERR, got resp=%b", rd_resp);
            err_count++;
        end else $display("[PASS] Unmapped read returns DECERR");

        // Summary
        if (err_count == 0)
            $display("[TB] === ALL PASS ===");
        else
            $display("[TB] === FAIL: %0d errors ===", err_count);
        #50 $finish;
    end

endmodule
