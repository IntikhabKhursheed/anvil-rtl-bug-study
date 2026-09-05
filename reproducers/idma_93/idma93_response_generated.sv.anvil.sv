/* verilator lint_off UNOPTFLAT */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHCONCAT */
module ErrorHandler (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni,
  input logic[0:0] _rsp_ep_rsp_ack,
  output logic[0:0] _rsp_ep_rsp_valid,
  output logic[1:0] _rsp_ep_rsp_0
);
  logic[1:0] state_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin : _proc_transition
    if (~rst_ni) begin
    end
  end
  localparam logic[1:0] thread_0_wire$0 = 2'b01;
  localparam logic[1:0] thread_0_wire$1 = 2'b10;
  for (genvar i = 0; i < 3; i ++) begin : EVENTS0
    logic event_current;
    end
  logic _init_0;
  logic _thread_0_event_counter_2_1_q, _thread_0_event_counter_2_1_n;
  logic _thread_0_event_syncstate_1_q, _thread_0_event_syncstate_1_n;
  assign EVENTS0[2].event_current = _thread_0_event_counter_2_1_q;
  assign _thread_0_event_counter_2_1_n = EVENTS0[1].event_current;
  assign EVENTS0[1].event_current = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && _rsp_ep_rsp_ack;
    assign _thread_0_event_syncstate_1_n = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && !_rsp_ep_rsp_ack;
  assign EVENTS0[0].event_current = _init_0 || EVENTS0[2].event_current;
  assign _rsp_ep_rsp_valid = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q);
  assign _rsp_ep_rsp_0 = thread_0_wire$0;
  always_ff @(posedge clk_i or negedge rst_ni) begin : _thread_0_st_transition
    if (~rst_ni) begin
      _init_0 <= 1'b1;
      state_q <= '0;
      _thread_0_event_counter_2_1_q <= '0;
      _thread_0_event_syncstate_1_q <= '0;
    end else begin
      if (EVENTS0[1].event_current) begin
        state_q[0 +: 2] <= thread_0_wire$1;
      end
      _init_0 <= 1'b0;
      _thread_0_event_counter_2_1_q <= _thread_0_event_counter_2_1_n;
      _thread_0_event_syncstate_1_q <= _thread_0_event_syncstate_1_n;
    end
  end
endmodule
module ResponseConsumer (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni,
  output logic[0:0] _rsp_ep_rsp_ack,
  input logic[0:0] _rsp_ep_rsp_valid,
  input logic[1:0] _rsp_ep_rsp_0
);
  always_ff @(posedge clk_i or negedge rst_ni) begin : _proc_transition
    if (~rst_ni) begin
    end
  end
  logic[1:0] thread_0_wire$0;
  assign thread_0_wire$0 = _rsp_ep_rsp_0;
  for (genvar i = 0; i < 3; i ++) begin : EVENTS0
    logic event_current;
    end
  logic _init_0;
  logic _thread_0_event_counter_2_1_q, _thread_0_event_counter_2_1_n;
  logic _thread_0_event_syncstate_1_q, _thread_0_event_syncstate_1_n;
  assign EVENTS0[2].event_current = _thread_0_event_counter_2_1_q;
  assign _thread_0_event_counter_2_1_n = EVENTS0[1].event_current;
  assign EVENTS0[1].event_current = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && _rsp_ep_rsp_valid;
    assign _thread_0_event_syncstate_1_n = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && !_rsp_ep_rsp_valid;
  assign EVENTS0[0].event_current = _init_0 || EVENTS0[2].event_current;
  assign _rsp_ep_rsp_ack = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q);
  always_ff @(posedge clk_i or negedge rst_ni) begin : _thread_0_st_transition
    if (~rst_ni) begin
      _init_0 <= 1'b1;
      _thread_0_event_counter_2_1_q <= '0;
      _thread_0_event_syncstate_1_q <= '0;
    end else begin
      if (EVENTS0[1].event_current) begin
        $display("received response", thread_0_wire$0);
      end
      _init_0 <= 1'b0;
      _thread_0_event_counter_2_1_q <= _thread_0_event_counter_2_1_n;
      _thread_0_event_syncstate_1_q <= _thread_0_event_syncstate_1_n;
    end
  end
endmodule
module Top (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni
);
  logic[0:0] _handler_ep_rsp_ack;
  logic[0:0] _handler_ep_rsp_valid;
  logic[1:0] _handler_ep_rsp_0;
  ErrorHandler _spawn_0 (
    .clk_i,
    .rst_ni
    ,._rsp_ep_rsp_valid (_handler_ep_rsp_valid)
    ,._rsp_ep_rsp_ack (_handler_ep_rsp_ack)
    ,._rsp_ep_rsp_0 (_handler_ep_rsp_0)
  );
  ResponseConsumer _spawn_1 (
    .clk_i,
    .rst_ni
    ,._rsp_ep_rsp_valid (_handler_ep_rsp_valid)
    ,._rsp_ep_rsp_ack (_handler_ep_rsp_ack)
    ,._rsp_ep_rsp_0 (_handler_ep_rsp_0)
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
