/* verilator lint_off UNOPTFLAT */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHCONCAT */
module FifoWriter (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni,
  input logic[0:0] _push_ep_slot_ack,
  output logic[0:0] _push_ep_slot_valid,
  output logic[0:0] _push_ep_slot_0
);
  logic[0:0] wr_ptr_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin : _proc_transition
    if (~rst_ni) begin
    end
  end
  logic[0:0] thread_0_wire$3;
  logic[0:0] thread_0_wire$1;
  logic[0:0] thread_0_wire$0;
  assign thread_0_wire$0 = wr_ptr_q;
  assign thread_0_wire$1 = wr_ptr_q;
  localparam logic[0:0] thread_0_wire$2 = 1'b1;
  assign thread_0_wire$3 = thread_0_wire$1 ^ thread_0_wire$2;
  for (genvar i = 0; i < 4; i ++) begin : EVENTS0
    logic event_current;
    end
  logic _init_0;
  logic _thread_0_event_counter_3_1_q, _thread_0_event_counter_3_1_n;
  logic _thread_0_event_counter_2_1_q, _thread_0_event_counter_2_1_n;
  logic _thread_0_event_syncstate_1_q, _thread_0_event_syncstate_1_n;
  assign EVENTS0[3].event_current = _thread_0_event_counter_3_1_q;
  assign _thread_0_event_counter_3_1_n = EVENTS0[2].event_current;
  assign EVENTS0[2].event_current = _thread_0_event_counter_2_1_q;
  assign _thread_0_event_counter_2_1_n = EVENTS0[1].event_current;
  assign EVENTS0[1].event_current = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && _push_ep_slot_ack;
    assign _thread_0_event_syncstate_1_n = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && !_push_ep_slot_ack;
  assign EVENTS0[0].event_current = _init_0 || EVENTS0[3].event_current;
  assign _push_ep_slot_valid = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q);
  assign _push_ep_slot_0 = thread_0_wire$0;
  always_ff @(posedge clk_i or negedge rst_ni) begin : _thread_0_st_transition
    if (~rst_ni) begin
      _init_0 <= 1'b1;
      wr_ptr_q <= '0;
      _thread_0_event_counter_3_1_q <= '0;
      _thread_0_event_counter_2_1_q <= '0;
      _thread_0_event_syncstate_1_q <= '0;
    end else begin
      if (EVENTS0[1].event_current) begin
        wr_ptr_q[0 +: 1] <= thread_0_wire$3;
      end
      _init_0 <= 1'b0;
      _thread_0_event_counter_3_1_q <= _thread_0_event_counter_3_1_n;
      _thread_0_event_counter_2_1_q <= _thread_0_event_counter_2_1_n;
      _thread_0_event_syncstate_1_q <= _thread_0_event_syncstate_1_n;
    end
  end
endmodule
module FifoReader (
  input logic[0:0] clk_i,
  input logic[0:0] rst_ni,
  output logic[0:0] _push_ep_slot_ack,
  input logic[0:0] _push_ep_slot_valid,
  input logic[0:0] _push_ep_slot_0
);
  always_ff @(posedge clk_i or negedge rst_ni) begin : _proc_transition
    if (~rst_ni) begin
    end
  end
  logic[0:0] thread_0_wire$0;
  assign thread_0_wire$0 = _push_ep_slot_0;
  for (genvar i = 0; i < 3; i ++) begin : EVENTS0
    logic event_current;
    end
  logic _init_0;
  logic _thread_0_event_counter_2_1_q, _thread_0_event_counter_2_1_n;
  logic _thread_0_event_syncstate_1_q, _thread_0_event_syncstate_1_n;
  assign EVENTS0[2].event_current = _thread_0_event_counter_2_1_q;
  assign _thread_0_event_counter_2_1_n = EVENTS0[1].event_current;
  assign EVENTS0[1].event_current = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && _push_ep_slot_valid;
    assign _thread_0_event_syncstate_1_n = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q) && !_push_ep_slot_valid;
  assign EVENTS0[0].event_current = _init_0 || EVENTS0[2].event_current;
  assign _push_ep_slot_ack = (EVENTS0[0].event_current || _thread_0_event_syncstate_1_q);
  always_ff @(posedge clk_i or negedge rst_ni) begin : _thread_0_st_transition
    if (~rst_ni) begin
      _init_0 <= 1'b1;
      _thread_0_event_counter_2_1_q <= '0;
      _thread_0_event_syncstate_1_q <= '0;
    end else begin
      if (EVENTS0[1].event_current) begin
        $display("accepted slot", thread_0_wire$0);
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
  logic[0:0] _writer_ep_slot_ack;
  logic[0:0] _writer_ep_slot_valid;
  logic[0:0] _writer_ep_slot_0;
  FifoWriter _spawn_0 (
    .clk_i,
    .rst_ni
    ,._push_ep_slot_valid (_writer_ep_slot_valid)
    ,._push_ep_slot_ack (_writer_ep_slot_ack)
    ,._push_ep_slot_0 (_writer_ep_slot_0)
  );
  FifoReader _spawn_1 (
    .clk_i,
    .rst_ni
    ,._push_ep_slot_valid (_writer_ep_slot_valid)
    ,._push_ep_slot_ack (_writer_ep_slot_ack)
    ,._push_ep_slot_0 (_writer_ep_slot_0)
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
