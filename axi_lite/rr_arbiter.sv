// N-way round-robin arbiter.
// Rotates priority each time handshake_complete is asserted.
// N = number of requesters (e.g. masters)
module rr_arbiter #(
    parameter int N = 4,
    localparam int ID_W = (N > 1) ? $clog2(N) : 1
) (
    input  logic clk,
    input  logic rst_n,
    input  logic [N-1:0] req,
    output logic [N-1:0] grant,
    input  logic handshake_complete
);

    logic [ID_W-1:0] last_grant;

    // Round-robin: priority order starting from (last_grant + 1) mod N
    always_comb begin
        grant = '0;
        for (int offset = 1; offset <= N; offset++) begin
            automatic int idx = (last_grant + offset) % N;
            if (req[idx]) begin
                grant[idx] = 1'b1;
                break;
            end
        end
    end

    // Update last_grant when handshake completes
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_grant <= '0;
        end else if (handshake_complete) begin
            for (int i = 0; i < N; i++) begin
                if (grant[i]) begin
                    last_grant <= i[ID_W-1:0];
                    break;
                end
            end
        end
    end

endmodule
