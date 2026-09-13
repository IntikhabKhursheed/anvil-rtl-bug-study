`timescale 1ns/1ps
/* verilator lint_off MULTITOP */
module tb_floo_rob;
  logic clk = 0, rst_n = 0, valid = 0, id = 0, last = 0;
  logic [3:0] rob_idx = 0, beat = 0, buggy_addr, fixed_addr;

  floo_rob_burst #(.BUGGY(1)) buggy (
    .clk_i(clk), .rst_ni(rst_n), .rsp_valid_i(valid), .rsp_id_i(id),
    .rsp_last_i(last), .rsp_rob_idx_i(rob_idx), .rsp_beat_i(beat),
    .rob_addr_o(buggy_addr));
  floo_rob_burst #(.BUGGY(0)) fixed (
    .clk_i(clk), .rst_ni(rst_n), .rsp_valid_i(valid), .rsp_id_i(id),
    .rsp_last_i(last), .rsp_rob_idx_i(rob_idx), .rsp_beat_i(beat),
    .rob_addr_o(fixed_addr));

  always #5 clk = ~clk;

  task automatic response_beat(input logic tx_id, input logic [3:0] tx_idx,
                               input logic [3:0] tx_beat, input logic tx_last);
    @(negedge clk);
    valid = 1; id = tx_id; rob_idx = tx_idx; beat = tx_beat; last = tx_last;
    #1 $display("Beat: ID=%0d beat=%0d buggy_addr=%0d fixed_addr=%0d",
                id, beat, buggy_addr, fixed_addr);
    @(posedge clk);
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    // Required interleaving: ID0/b0, ID1/b0, ID0/b1, ID1/b1.
    response_beat(0, 4'd0, 4'd0, 0);
    response_beat(1, 4'd8, 4'd0, 0); // buggy: 9; fixed: 8
    response_beat(0, 4'd0, 4'd1, 1); // buggy: 2; fixed: 1
    response_beat(1, 4'd8, 4'd1, 1); // SVA fails for buggy; fixed passes.
    valid = 0;
    #1 $finish;
  end
endmodule
