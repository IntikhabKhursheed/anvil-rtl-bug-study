`timescale 1ns/1ps
/* verilator lint_off MULTITOP */
// Testbench for compiler-generated anvil_generated.sv only.
module tb_edn_csrng_generated;
  logic clk = 0, rst_n = 0;
  Top dut (.clk_i(clk), .rst_ni(rst_n));

  always #5 clk = ~clk;

  // Csrng's Anvil source delays before recv, producing real channel
  // back-pressure. A valid request must remain stable while ACK is low.
  assert property (@(posedge clk) disable iff (!rst_n)
    (dut._edn_ep_request_valid && !dut._edn_ep_request_ack) |=>
    (dut._edn_ep_request_valid &&
     $stable(dut._edn_ep_request_0)))
    else $error("generated Anvil sender changed its request while stalled");

  task automatic show_cycle(input int n);
    @(negedge clk);
    $display("Cycle %0d | valid=%0b ack=%0b word=0x%08x", n,
             dut._edn_ep_request_valid, dut._edn_ep_request_ack,
             dut._edn_ep_request_0);
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    show_cycle(1);
    show_cycle(2);
    show_cycle(3);
    show_cycle(4);
    show_cycle(5);
    $display("PASS: generated Anvil request remained stable during back-pressure.");
    $finish;
  end
endmodule
