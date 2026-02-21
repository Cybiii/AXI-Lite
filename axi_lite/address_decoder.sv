// input a address => outputs slave id, valid, and error
// M = number of slaves (N×M convention)
// Verilog-2001 style for JasperGold compatibility
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

    integer i;

    always @(addr) begin
        slave_id = 0;
        valid = 1'b0;
        for (i = 0; i < M; i = i + 1) begin
            if (!valid && addr >= BASE_ADDR_PACKED[i*ADDR_WIDTH +: ADDR_WIDTH] &&
                addr < (BASE_ADDR_PACKED[i*ADDR_WIDTH +: ADDR_WIDTH] + SIZE_PACKED[i*ADDR_WIDTH +: ADDR_WIDTH])) begin
                slave_id = i;
                valid = 1'b1;
            end
        end
        decerr = !valid;
    end

endmodule