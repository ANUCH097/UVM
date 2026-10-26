`timescale 1ns / 1ps
// DUT: your FIFO with two fixes: reset is exclusive (else-begin) and
// the mem reset loop is removed (pointers are enough).
// Usable depth = 7 (3-bit pointers, one slot sacrificed).
module fifo_8_8(
    input        clk,
    input        rst,
    input        wr_enb,
    input        rd_enb,
    input  [7:0] data_in,
    output reg [7:0] data_out,
    output       full,
    output       empty
);

reg [2:0] wr_ptr = 0;
reg [2:0] re_ptr = 0;
reg [7:0] mem [0:7];

always @(posedge clk) begin
    if (rst) begin
        wr_ptr   <= 0;
        re_ptr   <= 0;
        data_out <= 0;
    end
    else begin
        if (wr_enb && !full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr      <= wr_ptr + 1'b1;
        end
        if (rd_enb && !empty) begin
            data_out <= mem[re_ptr];
            re_ptr   <= re_ptr + 1'b1;
        end
    end
end

assign full  = ((wr_ptr + 1'b1) == re_ptr);
assign empty = (wr_ptr == re_ptr);

endmodule
