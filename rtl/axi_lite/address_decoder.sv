module addr_decoder #(
    parameter int N_SLAVES = 4,
    parameter int ADDR_WIDTH = 32,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR [4] = '{
        32'h0000_0000,
        32'h0000_1000,
        32'h0000_2000,
        32'h0000_3000
    },
    parameter logic [ADDR_WIDTH-1:0] SIZE [4] = '{
        32'h1000,  // 4 KB each
        32'h1000,
        32'h1000,
        32'h1000
    },
    localparam int SLAVE_ID_W = (N_SLAVES > 1) ? $clog2(N_SLAVES) : 1
) (
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [SLAVE_ID_W-1:0] slave_id,
    output logic valid,
    output logic decerr
);

    always_comb begin
        slave_id = '0;
        valid = 1'b0;
        for (int i = 0; i < N_SLAVES; i++) begin
            if (addr >= BASE_ADDR[i] && addr < (BASE_ADDR[i] + SIZE[i])) begin
                slave_id = i;
                valid = 1'b1;
                break;
            end
        end
        decerr = !valid;
    end

endmodule