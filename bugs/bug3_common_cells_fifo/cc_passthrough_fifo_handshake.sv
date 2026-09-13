/* verilator lint_off UNOPTFLAT */
// Reduced model of common_cells passthrough_stream_fifo, PR #322.
// It isolates the patched behavior: pointers move only on a completed
// input/output valid-ready handshake.
module cc_passthrough_fifo_handshake #(
  parameter bit BUGGY = 1'b1
) (
  input  logic        clk_i, rst_ni,
  input  logic        in_valid_i, out_ready_i,
  input  logic [31:0] in_data_i,
  output logic        in_ready_o, out_valid_o,
  output logic [31:0] out_data_o,
  output logic        wr_ptr_o
);
  logic [31:0] mem [0:1];
  logic rd_ptr_q, wr_ptr_q;
  logic [1:0] count_q;
  logic push, pop;

  assign out_valid_o = (count_q != 0);
  assign out_data_o  = mem[rd_ptr_q];
  // A full FIFO cannot accept an input unless its output transfers this cycle.
  assign in_ready_o  = (count_q != 2) || (out_valid_o && out_ready_i);
  assign push = in_valid_i && in_ready_o;
  assign pop  = out_valid_o && out_ready_i;
  assign wr_ptr_o = wr_ptr_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_q <= 1'b0;
      wr_ptr_q <= 1'b0;
      count_q  <= '0;
    end else begin
      // Pre-fix: valid_i alone advanced the write pointer, even when full.
      if (BUGGY ? in_valid_i : push) wr_ptr_q <= ~wr_ptr_q;
      if (push) mem[wr_ptr_q] <= in_data_i;
      if (pop)  rd_ptr_q <= ~rd_ptr_q;
      case ({push, pop})
        2'b10: count_q <= count_q + 1'b1;
        2'b01: count_q <= count_q - 1'b1;
        default: ;
      endcase
    end
  end

  // A rejected push must not alter FIFO write-state on the following cycle.
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (in_valid_i && !in_ready_o) |=> $stable(wr_ptr_q))
    else $error("FIFO write pointer advanced without an input handshake");
endmodule
