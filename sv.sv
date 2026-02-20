assert property (@(posedge clk) disable iff (!rst_n)
    wr_req && !full |-> ##1 wr_ptr == $past(wr_ptr) + 1
);


assert property(@(posedge clk) disable iff (!rst_n)
    wr_req && !full |-> ##1 wr_ptr == $past(wr_ptr) + 1
);


assert property(@(posedge clk) disable iff (!rst_n)
    valid && ready |=> ##1 $stable(data)
);

assert property(@(posedge clk) disable iff (!rst_n)
    !(grant_a && grant_b)
)

asser property(@(posedge clk) disable iff (!rst_n)
    req |-> ##10 ack
)

assert property(@(posedge clk) disable iff(!rst_n)
    full |-> !wr_en;
)

assert property(@(posedge clk) disable iff(!rst_n)
    empty |-> !rd_en;
)

assert property(@(posedge clk) disable iff(!rst_n)
    handshake_in |-> ##1 wr_ptr == $past(wr_ptr) + 1
)

assert property(@(posedge clk) disable iff(!rst_n)
    handshake_out |-> ##1 rd_ptr == $past(rd_ptr) + 1
)

assert property(@(posedge clk) disable iff(!rst_n)
    !(full && empty)
)



assert property(@(posedge clk) disable iff )



assert property(@(posedge clk) disable iff(!rst_n)
    req |-> !([1:$] ack && counter > 2)
)

logic counter_reqs

always_ff@(posedge clk) begin
    if(req) begin
        counter_reqs <= counter_reqs + 1
    end
    else if(counter_reqs == 2) begin
        counter_reqs <= counter_reqs - 1;
    end
end














