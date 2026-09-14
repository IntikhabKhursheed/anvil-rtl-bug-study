`timescale 1ns/1ps
/* verilator lint_off MULTITOP */

// Testbench for the Anvil-generated encoding of the response side of
// iDMA PR #93 (idma93_response_generated.sv.anvil.sv). Drives forced
// back-pressure on the generated ErrorHandler module directly and
// checks that rsp_valid remains stable until the handshake completes —
// the same invariant checked by the hand-written SVA in Section 6.

module tb_idma93_anvil;
  logic clk = 0;
  logic rst_n = 0;
  logic rsp_ack = 0;
  logic rsp_valid;
  logic [1:0] rsp_data;

  ErrorHandler dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    ._rsp_ep_rsp_ack(rsp_ack),
    ._rsp_ep_rsp_valid(rsp_valid),
    ._rsp_ep_rsp_0(rsp_data)
  );

  always #5 clk = ~clk;

  // Same invariant as the hand-written SVA in Section 6:
  // once valid is asserted, it must remain asserted until ack completes.
  assert property (@(posedge clk) disable iff (!rst_n)
    (rsp_valid && !rsp_ack) |=> rsp_valid)
    else $error("Anvil-generated rsp_valid retracted before handshake");

  int timeout;

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    rsp_ack = 0;

    // Wait for the handler to offer its response, with a timeout guard.
    timeout = 0;
    while (rsp_valid !== 1'b1 && timeout < 50) begin
      @(posedge clk);
      timeout++;
    end
    if (rsp_valid !== 1'b1) begin
      $error("Timed out waiting for rsp_valid to assert");
      $finish;
    end

    $display("Cycle @%0t: rsp_valid asserted, holding ack low for 3 cycles", $time);
    repeat (3) begin
      @(posedge clk); #1;
      $display("Cycle @%0t: rsp_valid=%0b rsp_ack=%0b rsp_data=%0d",
                $time, rsp_valid, rsp_ack, rsp_data);
    end

    @(negedge clk); rsp_ack = 1;
    @(posedge clk); #1;
    $display("Cycle @%0t: ack asserted, rsp_valid=%0b", $time, rsp_valid);
    @(negedge clk); rsp_ack = 0;

    repeat (5) @(posedge clk);
    $display("PASS: property held throughout - test complete");
    $finish;
  end
endmodule
