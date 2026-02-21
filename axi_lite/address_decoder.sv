// input a address => outputs slave id, valid, and error
// M = number of slaves (N×M convention)
module addr_decoder #(
    parameter int M = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int SLAVE_ID_W = (M > 1) ? $clog2(M) : 1,
    parameter [ADDR_WIDTH*M-1:0] BASE_ADDR_PACKED = {32'h0000_3000, 32'h0000_2000, 32'h0000_1000, 32'h0000_0000},
    parameter [ADDR_WIDTH*M-1:0] SIZE_PACKED     = {32'h1000, 32'h1000, 32'h1000, 32'h1000}
) (
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [SLAVE_ID_W-1:0] slave_id,
    output logic valid,
    output logic decerr
);

    always_comb begin
        slave_id = 0;
        valid = 1'b0;
        for (int i = 0; i < M; i++) begin
            if (addr >= BASE_ADDR_PACKED[i*ADDR_WIDTH +: ADDR_WIDTH] &&
                addr < (BASE_ADDR_PACKED[i*ADDR_WIDTH +: ADDR_WIDTH] + SIZE_PACKED[i*ADDR_WIDTH +: ADDR_WIDTH])) begin
                slave_id = i;
                valid = 1'b1;
                break;
            end
        end
        decerr = !valid;
    end

endmodule