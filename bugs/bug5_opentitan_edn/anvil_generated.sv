/* verilator lint_off UNOPTFLAT */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHCONCAT */
module Edn (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni,
  input logic[0:0] _cmd_ep_request_ack,
  output logic[0:0] _cmd_ep_request_valid,
  output logic[31:0] _cmd_ep_request_0
);
  logic[31:0] next_word_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin : _proc_transition
    if (~rst_ni) begin
    end
  end
  logic[31:0] thread_0_wire$3;
  logic[31:0] thread_0_wire$1;
  logic[31:0] thread_0_wire$0;
  assign thread_0_wire$0 = next_word_q;
  assign thread_0_wire$1 = next_word_q;
  localparam logic[31:0] thread_0_wire$2 = 32'd1;
  assign thread_0_wire$3 = thread_0_wire$1 + thread_0_wire$2;
  for (genvar i = 0; i < 3; i ++) begin : EVENTS0
    logic event_current;
    end
  logic _init_0;
  logic _thread_0_event_counter_2_1_q, _thread_0_event_counter_2_1_n;
  logic _thread_0_event_syncstate_1_q, _thread_0_event_syncstate_1_n;
  assign EVENTS0[2].event_current = _thread_0_event_counter_2_1_q;
  assign _thread_0_event_counter_2_1_n = EVENTS0[1].event_current;
  assign EVENTS0[1].event_current = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && _cmd_ep_request_ack;
    assign _thread_0_event_syncstate_1_n = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && !_cmd_ep_request_ack;
  assign EVENTS0[0].event_current = _init_0 || EVENTS0[2].event_current;
  assign _cmd_ep_request_valid = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q);
  assign _cmd_ep_request_0 = thread_0_wire$0;
  always_ff @(posedge clk_i or negedge rst_ni) begin : _thread_0_st_transition
    if (~rst_ni) begin
      _init_0 <= 1'b1;
      next_word_q <= '0;
      _thread_0_event_counter_2_1_q <= '0;
      _thread_0_event_syncstate_1_q <= '0;
    end else begin
      if (EVENTS0[1].event_current) begin
        next_word_q[0 +: 32] <= thread_0_wire$3;
      end
      _init_0 <= 1'b0;
      _thread_0_event_counter_2_1_q <= _thread_0_event_counter_2_1_n;
      _thread_0_event_syncstate_1_q <= _thread_0_event_syncstate_1_n;
    end
  end
endmodule
module Csrng (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni,
  output logic[0:0] _cmd_ep_request_ack,
  input logic[0:0] _cmd_ep_request_valid,
  input logic[31:0] _cmd_ep_request_0
);
  always_ff @(posedge clk_i or negedge rst_ni) begin : _proc_transition
    if (~rst_ni) begin
    end
  end
  logic[31:0] thread_0_wire$0;
  assign thread_0_wire$0 = _cmd_ep_request_0;
  for (genvar i = 0; i < 3; i ++) begin : EVENTS0
    logic event_current;
    end
  logic _init_0;
  logic _thread_0_event_syncstate_2_q, _thread_0_event_syncstate_2_n;
  logic[1:0] _thread_0_event_counter_1_q, _thread_0_event_counter_1_n;
  assign EVENTS0[2].event_current = (EVENTS0[1].event_current || _thread_0_event_syncstate_2_q) && _cmd_ep_request_valid;
    assign _thread_0_event_syncstate_2_n = (EVENTS0[1].event_current || _thread_0_event_syncstate_2_q) && !_cmd_ep_request_valid;
  assign EVENTS0[1].event_current = _thread_0_event_counter_1_q == 2'd3;
    assign _thread_0_event_counter_1_n = EVENTS0[0].event_current ? 2'd1 : EVENTS0[1].event_current ? '0 : _thread_0_event_counter_1_q ? (_thread_0_event_counter_1_q + 2'd1) : _thread_0_event_counter_1_q;
  assign EVENTS0[0].event_current = _init_0 || EVENTS0[2].event_current;
  assign _cmd_ep_request_ack = (EVENTS0[1].event_current || _thread_0_event_syncstate_2_q);
  always_ff @(posedge clk_i or negedge rst_ni) begin : _thread_0_st_transition
    if (~rst_ni) begin
      _init_0 <= 1'b1;
      _thread_0_event_syncstate_2_q <= '0;
      _thread_0_event_counter_1_q <= '0;
    end else begin
      if (EVENTS0[2].event_current) begin
        $display("CSRNG word", thread_0_wire$0);
      end
      _init_0 <= 1'b0;
      _thread_0_event_syncstate_2_q <= _thread_0_event_syncstate_2_n;
      _thread_0_event_counter_1_q <= _thread_0_event_counter_1_n;
    end
  end
endmodule
module Top (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni
);
  logic[0:0] _edn_ep_request_ack;
  logic[0:0] _edn_ep_request_valid;
  logic[31:0] _edn_ep_request_0;
  Edn _spawn_0 (
    .clk_i,
    .rst_ni
    ,._cmd_ep_request_valid (_edn_ep_request_valid)
    ,._cmd_ep_request_ack (_edn_ep_request_ack)
    ,._cmd_ep_request_0 (_edn_ep_request_0)
  );
  Csrng _spawn_1 (
    .clk_i,
    .rst_ni
    ,._cmd_ep_request_valid (_edn_ep_request_valid)
    ,._cmd_ep_request_ack (_edn_ep_request_ack)
    ,._cmd_ep_request_0 (_edn_ep_request_0)
  );
  always_ff @(posedge clk_i or negedge rst_ni) begin : _proc_transition
    if (~rst_ni) begin
    end
  end
  for (genvar i = 0; i < 2; i ++) begin : EVENTS0
    logic event_current;
    end
  logic _init_0;
  logic _thread_0_event_counter_1_1_q, _thread_0_event_counter_1_1_n;
  assign EVENTS0[1].event_current = _thread_0_event_counter_1_1_q;
  assign _thread_0_event_counter_1_1_n = EVENTS0[0].event_current;
  assign EVENTS0[0].event_current = _init_0 || EVENTS0[1].event_current;
  always_ff @(posedge clk_i or negedge rst_ni) begin : _thread_0_st_transition
    if (~rst_ni) begin
      _init_0 <= 1'b1;
      _thread_0_event_counter_1_1_q <= '0;
    end else begin
      _init_0 <= 1'b0;
      _thread_0_event_counter_1_1_q <= _thread_0_event_counter_1_1_n;
    end
  end
endmodule
