`timescale 1ns/1ps
/* verilator lint_off MULTITOP */
module tb_edn_handshake;
  logic clk = 0, rst_n = 0, send_valid = 0, ready = 0;
  logic [31:0] word_in = '0, buggy_bus, fixed_bus;
  logic buggy_valid, fixed_valid;

  edn_csrng_if #(.BUGGY(1)) buggy (
    .clk_i(clk), .rst_ni(rst_n), .send_valid_i(send_valid),
    .send_data_i(word_in), .csrng_ready_i(ready),
    .csrng_valid_o(buggy_valid), .csrng_bus_o(buggy_bus));
  edn_csrng_if #(.BUGGY(0)) fixed (
    .clk_i(clk), .rst_ni(rst_n), .send_valid_i(send_valid),
    .send_data_i(word_in), .csrng_ready_i(ready),
    .csrng_valid_o(fixed_valid), .csrng_bus_o(fixed_bus));

  always #5 clk = ~clk;

  task automatic drive_cycle(input int n, input logic [31:0] word,
                             input logic rdy);
    @(negedge clk);
    send_valid = 1; word_in = word; ready = rdy;
    // The display occurs before the following sampling edge. On cycle 3,
    // the simulator reports the intentionally failing buggy SVA at that edge.
    #1 $display("Cycle %0d | word=0x%08x ready=%0b buggy=0x%08x fixed=0x%08x",
                n, word_in, ready, buggy_bus, fixed_bus);
    @(posedge clk);
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    drive_cycle(1, 32'hDEAD_BEEF, 1'b1); // normal transfer
    drive_cycle(2, 32'hCAFE_BABE, 1'b0); // back-pressure starts
    drive_cycle(3, 32'h1234_5678, 1'b0); // buggy overwrites CAFE_BABE
    drive_cycle(4, 32'h0000_0000, 1'b1); // fixed FIFO resumes its handshake
    send_valid = 0;
    #1 $finish;
  end
endmodule
