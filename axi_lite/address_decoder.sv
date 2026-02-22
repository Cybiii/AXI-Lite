// input a address => outputs slave id, valid, and error
// M = number of slaves (N×M convention)
// Verilog-95 only: no generate/genvar, constant part-selects (JasperGold Analyze RTL)
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

    // Constant part-selects only (Verilog-95); M=4
    wire [ADDR_WIDTH-1:0] base0 = BASE_ADDR_PACKED[ 31:  0];
    wire [ADDR_WIDTH-1:0] base1 = BASE_ADDR_PACKED[ 63: 32];
    wire [ADDR_WIDTH-1:0] base2 = BASE_ADDR_PACKED[ 95: 64];
    wire [ADDR_WIDTH-1:0] base3 = BASE_ADDR_PACKED[127: 96];
    wire [ADDR_WIDTH-1:0] size0 = SIZE_PACKED[ 31:  0];
    wire [ADDR_WIDTH-1:0] size1 = SIZE_PACKED[ 63: 32];
    wire [ADDR_WIDTH-1:0] size2 = SIZE_PACKED[ 95: 64];
    wire [ADDR_WIDTH-1:0] size3 = SIZE_PACKED[127: 96];

    wire match0 = (addr >= base0) && (addr < base0 + size0);
    wire match1 = (addr >= base1) && (addr < base1 + size1);
    wire match2 = (addr >= base2) && (addr < base2 + size2);
    wire match3 = (addr >= base3) && (addr < base3 + size3);

    always @(addr) begin
        slave_id = 0;
        valid = 1'b0;
        if (match0) begin valid = 1'b1; slave_id = 0; end
        else if (match1) begin valid = 1'b1; slave_id = 1; end
        else if (match2) begin valid = 1'b1; slave_id = 2; end
        else if (match3) begin valid = 1'b1; slave_id = 3; end
        decerr = !valid;
    end

endmodule
