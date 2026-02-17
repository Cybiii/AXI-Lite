module FIFO #(
    parameter DATA_WIDTH  = 32, parameter DEPTH = 8 )
    (
    input  wire clk, rst,
    input  wire wr_req, rd_req,
    input  wire [DATA_WIDTH-1:0] data_in,
    
    output logic wr_valid, rd_valid,
    output logic full, empty,
    output logic [DATA_WIDTH-1:0] data_out
);

    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    logic [$clog2(DEPTH):0] rd_ptr, wr_ptr;
    localparam ADDR_BITS = $clog2(DEPTH);

    logic handshake_in = wr_req & wr_valid;
    logic handshake_out = rd_req & rd_valid;

    always_comb begin
        empty = (rd_ptr == wr_ptr);
        full = (rd_ptr[ADDR_BITS-1:0] == wr_ptr[ADDR_BITS-1:0] && wr_ptr[ADDR_BITS] != rd_ptr[ADDR_BITS]);
        wr_valid = wr_req && ~full;
        rd_valid = rd_req && ~empty;
    end

    always_ff @( posedge clk, posedge rst ) begin 
        // reset
        if(rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end
        else begin
            if(handshake_in) begin
                mem[wr_ptr[ADDR_BITS-1:0]] <= data_in;
                wr_ptr <= wr_ptr + 1;
            end
            if(handshake_out) begin
                data_out <= mem[rd_ptr[ADDR_BITS-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end
endmodule