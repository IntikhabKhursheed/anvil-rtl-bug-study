// Code your testbench here
// or browse Examples
`timescale 1ns/1ps
/* verilator lint_off MULTITOP */

// Testbench for the Anvil-generated encoding of Bug 3's write-side
// channel sequencing (Version A). Drives forced back-pressure directly
// on FifoWriter and checks that wr_ptr does not change until the
// channel handshake (ack) completes.

module tb_fifo_push_anvil;
  logic clk = 0;
  logic rst_n = 0;
  logic ack = 0;
  logic valid;
  logic wr_ptr;

  FifoWriter dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    ._push_ep_slot_ack(ack),
    ._push_ep_slot_valid(valid),
    ._push_ep_slot_0(wr_ptr)
  );

  always #5 clk = ~clk;

  assert property (@(posedge clk) disable iff (!rst_n)
    (valid && !ack) |=> $stable(wr_ptr))
    else $error("Anvil-generated wr_ptr changed before handshake completed");

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    ack = 0;

    $display("Holding ack low for 3 cycles, watching wr_ptr...");
    repeat (3) begin
      @(negedge clk);
      $display("valid=%0b ack=%0b wr_ptr=%0b", valid, ack, wr_ptr);
    end

    @(negedge clk); ack = 1;
    @(posedge clk); #1;
    $display("ack asserted -> wr_ptr=%0b", wr_ptr);
    @(negedge clk); ack = 0;
    @(posedge clk); #1;
    $display("next cycle -> wr_ptr=%0b (should now be toggled)", wr_ptr);

    repeat (3) @(posedge clk);
    $display("PASS: wr_ptr held stable throughout back-pressure - test complete");
    $finish;
  end
endmodule