/* verilator lint_off UNOPTFLAT */
/* verilator lint_off WIDTHTRUNC */
// Reduced model of OpenTitan EDN #15469 / PR #15478.
module edn_csrng_if #(
  parameter bit BUGGY = 1'b1
) (
  input  logic        clk_i, rst_ni, send_valid_i, csrng_ready_i,
  input  logic [31:0] send_data_i,
  output logic        csrng_valid_o,
  output logic [31:0] csrng_bus_o
);
  generate
    if (BUGGY) begin : gen_buggy
      logic valid_q;
      logic [31:0] data_q;
      // Pre-fix behavior: a new internal word overwrites the offered word,
      // irrespective of whether CSRNG accepted the previous one.
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin valid_q <= 1'b0; data_q <= '0; end
        else begin
          valid_q <= send_valid_i;
          if (send_valid_i) data_q <= send_data_i;
        end
      end
      assign csrng_valid_o = valid_q;
      assign csrng_bus_o   = data_q;
    end else begin : gen_fixed
      logic [31:0] fifo_mem [0:1];
      logic rd_q, wr_q;
      logic [1:0] count_q;
      logic fifo_empty, fifo_full, fifo_push, fifo_pop;
      // Two-entry fall-through output FIFO. A stored head pops only on ready.
      assign fifo_empty = (count_q == 0);
      assign fifo_full  = (count_q == 2);
      assign csrng_valid_o = !fifo_empty || send_valid_i;
      assign csrng_bus_o   = fifo_empty ? send_data_i : fifo_mem[rd_q];
      assign fifo_pop  = csrng_valid_o && csrng_ready_i;
      assign fifo_push = send_valid_i && !(fifo_empty && csrng_ready_i) &&
                         (!fifo_full || fifo_pop);
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin rd_q <= 0; wr_q <= 0; count_q <= 0; end
        else begin
          if (fifo_push) begin fifo_mem[wr_q] <= send_data_i; wr_q <= ~wr_q; end
          if (fifo_pop && !fifo_empty) rd_q <= ~rd_q;
          // A fall-through transfer from an empty FIFO consumes no stored
          // entry, so only a pop of nonempty storage changes occupancy.
          case ({fifo_push, (fifo_pop && !fifo_empty)})
            2'b10: count_q <= count_q + 1'b1;
            2'b01: count_q <= count_q - 1'b1;
            default: ;
          endcase
        end
      end
    end
  endgenerate

  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (csrng_valid_o && !csrng_ready_i) |=>
    (csrng_valid_o && $stable(csrng_bus_o)))
    else $error("EDN changed or withdrew request under back-pressure");
endmodule
