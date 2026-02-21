interface axi_lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (input logic clk, input logic rst_n);

    // Write address channel
    logic [ADDR_WIDTH-1:0] aw_addr;
    logic aw_valid;
    logic aw_ready;

    // Write data channel
    logic [DATA_WIDTH-1:0]   w_data;
    logic [DATA_WIDTH/8-1:0] w_strb; // valid bytes e.g w_strb[0] is byte 0, w_strb[1] is byte 1, etc...
    logic w_valid;
    logic w_ready;

    // Write response channel
    logic [1:0] b_resp; // codes 2'b00 OKAY, 2'b01 EXCLUSIVEOKAY, 2'b10 ERROR, 2'b11 DECODE-ERROR
    logic b_valid;
    logic b_ready;

    // Read address channel
    logic [ADDR_WIDTH-1:0] ar_addr;
    logic ar_valid;
    logic ar_ready;

    // Read data channel
    logic [DATA_WIDTH-1:0] r_data;
    logic [1:0] r_resp;
    logic r_valid;
    logic r_ready;

    modport master (
        input  clk, rst_n,
        output aw_addr, aw_valid, w_data, w_strb, w_valid, b_ready,
        output ar_addr, ar_valid, r_ready,
        input  aw_ready, w_ready, b_resp, b_valid,
        input  ar_ready, r_data, r_resp, r_valid
    );

    modport slave (
        input  clk, rst_n,
        input  aw_addr, aw_valid, w_data, w_strb, w_valid, b_ready,
        input  ar_addr, ar_valid, r_ready,
        output aw_ready, w_ready, b_resp, b_valid,
        output ar_ready, r_data, r_resp, r_valid
    );

endinterface