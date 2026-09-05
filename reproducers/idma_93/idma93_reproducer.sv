// Minimal model of the response-side bug fixed by iDMA PR #93.
module idma93_error_handler #(
  parameter bit BUGGY = 1'b1
) (
  input  logic clk_i, rst_ni, error_i, rsp_ready_i, w_last_burst_i,
  output logic rsp_valid_o
);
  typedef enum logic [1:0] {IDLE, EMIT_RSP, WAIT, WAIT_LAST_W} state_t;
  state_t state_q, state_d;

  always_comb begin
    state_d = state_q;
    rsp_valid_o = 1'b0;
    case (state_q)
      IDLE: if (error_i) state_d = EMIT_RSP;
      EMIT_RSP: begin
        rsp_valid_o = 1'b1;
        // PR #93: BUGGY leaves this state even while the receiver stalls.
        if (BUGGY || rsp_ready_i)
          state_d = w_last_burst_i ? WAIT_LAST_W : WAIT;
      end
      default: ;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) state_q <= IDLE;
    else          state_q <= state_d;

  // Once valid is offered during back-pressure, it must remain asserted.
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (rsp_valid_o && !rsp_ready_i) |=> rsp_valid_o)
    else $error("%m: rsp_valid_o was retracted before the handshake");
endmodule
