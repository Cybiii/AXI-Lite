// SystemVerilog Assertions for AXI-Lite formal verification (JasperGold)
// Bind this to bridge_1xM or bridge_Nx1 for protocol compliance checks
//
// Usage: bind bridge_1xM axi_lite_props u_props (.*);

module axi_lite_props (
    input logic clk,
    input logic rst_n,
    input logic aw_valid,
    input logic aw_ready,
    input logic w_valid,
    input logic w_ready,
    input logic b_valid,
    input logic b_ready,
    input logic ar_valid,
    input logic ar_ready,
    input logic r_valid,
    input logic r_ready
);

    // Valid must not depend on ready (no combinational loop)
    // Once valid, hold until handshake
    property aw_stable;
        @(posedge clk) disable iff (!rst_n)
        aw_valid && !aw_ready |=> aw_valid;
    endproperty
    assert property (aw_stable);

    property w_stable;
        @(posedge clk) disable iff (!rst_n)
        w_valid && !w_ready |=> w_valid;
    endproperty
    assert property (w_stable);

    property b_stable;
        @(posedge clk) disable iff (!rst_n)
        b_valid && !b_ready |=> b_valid;
    endproperty
    assert property (b_stable);

    property ar_stable;
        @(posedge clk) disable iff (!rst_n)
        ar_valid && !ar_ready |=> ar_valid;
    endproperty
    assert property (ar_stable);

    property r_stable;
        @(posedge clk) disable iff (!rst_n)
        r_valid && !r_ready |=> r_valid;
    endproperty
    assert property (r_stable);

endmodule
