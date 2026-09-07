// Minimal model of FlooNoC floo_simple_rob PR #65 (commit 1d801a0).
module floo_rob_burst #(
  parameter bit BUGGY = 1'b1
) (
  input  logic       clk_i, rst_ni, rsp_valid_i, rsp_id_i, rsp_last_i,
  input  logic [3:0] rsp_rob_idx_i, rsp_beat_i,
  output logic [3:0] rob_addr_o
);
  logic [3:0] rsp_burst_cnt_q;       // Pre-fix: incorrectly shared by all IDs.
  logic [3:0] rsp_burst_cnt_by_id_q [2];
  logic       addr_mismatch_q;

  always_comb begin
    if (BUGGY) rob_addr_o = rsp_rob_idx_i + rsp_burst_cnt_q;
    else       rob_addr_o = rsp_rob_idx_i + rsp_burst_cnt_by_id_q[rsp_id_i];
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rsp_burst_cnt_q <= '0;
      rsp_burst_cnt_by_id_q[0] <= '0;
      rsp_burst_cnt_by_id_q[1] <= '0;
      addr_mismatch_q <= 1'b0;
    end else if (rsp_valid_i) begin
      // rsp_beat_i is a test-only per-ID reference: 0, 1, ... for each burst.
      addr_mismatch_q <= addr_mismatch_q ||
                         (rob_addr_o != rsp_rob_idx_i + rsp_beat_i);
      if (BUGGY) rsp_burst_cnt_q <= rsp_last_i ? '0 : rsp_burst_cnt_q + 1'b1;
      else rsp_burst_cnt_by_id_q[rsp_id_i] <=
             rsp_last_i ? '0 : rsp_burst_cnt_by_id_q[rsp_id_i] + 1'b1;
    end
  end

  // At completion of ID 1's interleaved burst, no earlier response may have
  // used another ID's progress. The shared-counter implementation violates it.
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (rsp_valid_i && rsp_id_i && rsp_last_i) |-> !addr_mismatch_q)
    else $error("%m: interleaved IDs did not retain independent ROB addresses");
endmodule
