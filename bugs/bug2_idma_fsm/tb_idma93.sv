`timescale 1ns/1ps
module tb_idma93;
  logic clk = 0, rst_n = 0, error = 0, ready = 0, last = 0;
  logic buggy_valid, fixed_valid;

  idma93_error_handler #(.BUGGY(1)) buggy (
    .clk_i(clk), .rst_ni(rst_n), .error_i(error), .rsp_ready_i(ready),
    .w_last_burst_i(last), .rsp_valid_o(buggy_valid));
  idma93_error_handler #(.BUGGY(0)) fixed (
    .clk_i(clk), .rst_ni(rst_n), .error_i(error), .rsp_ready_i(ready),
    .w_last_burst_i(last), .rsp_valid_o(fixed_valid));

  always #5 clk = ~clk;

  initial begin
    // Drive inputs on falling edges, away from the DUT's rising-edge FF.
    // This avoids a testbench/DUT scheduling race in every simulator.
    repeat (2) @(negedge clk);
    rst_n = 1; error = 1;
    @(posedge clk);                   // Both enter EMIT_RSP.
    @(negedge clk);
    error = 0;
    if (!buggy_valid || !fixed_valid) $fatal("response was not offered");
    @(posedge clk);                   // Still stalled: buggy assertion antecedent.
    @(negedge clk);
    if (buggy_valid) $fatal("buggy model unexpectedly held valid");
    if (!fixed_valid) $fatal("fixed model dropped valid while stalled");
    $display("PASS: fixed version held valid during back-pressure.");
    // The next rising edge is intentionally fatal in Verilator: it evaluates
    // the buggy instance's failed SVA consequent.  Exit code 1 is expected.
    ready = 1;
    @(posedge clk);                   // Fixed handshakes; buggy SVA reports its failure.
    #1;
    $finish;
  end
endmodule
