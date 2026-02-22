// input a address => outputs slave id, valid, and error
// M = number of slaves (N×M convention)
// Verilog-95 compatible for JasperGold (explicit sensitivity, no variable part-select)
module addr_decoder #(
    parameter M = 4,
    parameter ADDR_WIDTH = 32,
    parameter SLAVE_ID_W = (M > 1) ? $clog2(M) : 1,
    parameter [ADDR_WIDTH*M-1:0] BASE_ADDR_PACKED = {32'h0000_3000, 32'h0000_2000, 32'h0000_1000, 32'h0000_0000},
    parameter [ADDR_WIDTH*M-1:0] SIZE_PACKED     = {32'h1000, 32'h1000, 32'h1000, 32'h1000}
) (
    input  [ADDR_WIDTH-1:0] addr,
    output reg [SLAVE_ID_W-1:0] slave_id,
    output reg valid,
    output reg decerr
);

    // Per-slave range match (constant part-select in generate => Verilog-95 ok)
    wire [M-1:0] match;
    genvar g;
    generate
        for (g = 0; g < M; g = g + 1) begin : gen_slave
            wire [ADDR_WIDTH-1:0] base_g = BASE_ADDR_PACKED[g*ADDR_WIDTH + ADDR_WIDTH - 1 : g*ADDR_WIDTH];
            wire [ADDR_WIDTH-1:0] size_g = SIZE_PACKED[g*ADDR_WIDTH + ADDR_WIDTH - 1 : g*ADDR_WIDTH];
            assign match[g] = (addr >= base_g) && (addr < base_g + size_g);
        end
    endgenerate

    integer i;
    always @(addr) begin
        slave_id = 0;
        valid = 1'b0;
        for (i = 0; i < M; i = i + 1) begin
            if (!valid && match[i]) begin
                slave_id = i;
                valid = 1'b1;
            end
        end
        decerr = !valid;
    end

endmodule