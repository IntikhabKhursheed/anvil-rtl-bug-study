`timescale 1ns/1ps
/* verilator lint_off MULTITOP */
module tb_cc_passthrough_fifo;
  logic clk = 0, rst_n = 0, valid = 0, out_ready = 0;
  logic [31:0] data = '0;
  logic buggy_ready, fixed_ready, buggy_valid, fixed_valid;
  logic [31:0] buggy_data, fixed_data;
  logic buggy_wr_ptr, fixed_wr_ptr;

  cc_passthrough_fifo_handshake #(.BUGGY(1)) buggy (
    .clk_i(clk), .rst_ni(rst_n), .in_valid_i(valid), .in_data_i(data),
    .out_ready_i(out_ready), .in_ready_o(buggy_ready), .out_valid_o(buggy_valid),
    .out_data_o(buggy_data), .wr_ptr_o(buggy_wr_ptr));
  cc_passthrough_fifo_handshake #(.BUGGY(0)) fixed (
    .clk_i(clk), .rst_ni(rst_n), .in_valid_i(valid), .in_data_i(data),
    .out_ready_i(out_ready), .in_ready_o(fixed_ready), .out_valid_o(fixed_valid),
    .out_data_o(fixed_data), .wr_ptr_o(fixed_wr_ptr));

  always #5 clk = ~clk;

  task automatic push_cycle(input int n, input logic [31:0] word);
    logic ready_before_edge;
    @(negedge clk);
    valid = 1; data = word; out_ready = 0;
    // Capture ready before the active edge. After an accepted second push,
    // combinational ready becomes 0 because the FIFO is then full.
    #1 ready_before_edge = buggy_ready;
    @(posedge clk); #1;
    $display("Cycle %0d | word=0x%08x ready=%0b buggy_wr_ptr=%0b fixed_wr_ptr=%0b",
             n, data, ready_before_edge, buggy_wr_ptr, fixed_wr_ptr);
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    push_cycle(1, 32'hAAAA_0001); // Accepted: FIFO occupancy becomes one.
    push_cycle(2, 32'hBBBB_0002); // Accepted: FIFO becomes full.
    push_cycle(3, 32'hCCCC_0003); // Rejected: buggy pointer still advances.
    // At this next edge the buggy SVA fails; exit code 1 is intentional.
    @(negedge clk); valid = 0;
    @(posedge clk);
    #1 $finish;
  end
endmodule
