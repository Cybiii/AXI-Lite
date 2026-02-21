module addr_to_slave #(
    parameter N = 4,
    parameter ADDR_WIDTH = 32,
    parameter BASE_ADDR = 0,
    parameter SIZE = 4096;
) (
    
);
    logic slave_id = 0;
    logic valid = 0;
    logic decerr = 1;
    genvar i;

    for (i = 0; i < N - 1; i++) begin
        if(addr >= BASE_ADDR[i] && addr < BASE_ADDR[i] + SIZE[i]) begin
            slave_id = i
            valid = i
        end
        if(valid == 0) begin
            decerr = 1;
        end

    
    end



endmodule