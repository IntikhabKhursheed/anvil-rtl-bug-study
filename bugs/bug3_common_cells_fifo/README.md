# common_cells `passthrough_stream_fifo`: pointer advances without a handshake

## The bug

`cc_passthrough_stream_fifo` is a low-latency FIFO in `pulp-platform/common_cells` — it avoids cutting the timing path and, by design, supports pushing and popping in the same cycle even when full (`SameCycleRW`). That last part matters, because it's not a bug on its own; it's meant to work that way.

The actual bug was in how the read and write pointers updated. The write pointer advanced whenever `valid_i` was high, full stop — it never checked whether the FIFO was actually able to accept the word (`ready_o`). The read pointer had the mirror-image problem: it advanced on `ready_i` alone, regardless of whether there was anything valid to hand out (`valid_o`). So if a push happened while the FIFO was already full, or a pop happened while it was empty, the pointer still moved — even though nothing real was transferred.

This is documented directly in [PR #322](https://github.com/pulp-platform/common_cells/pull/322) and the two issues it addresses ([#264](https://github.com/pulp-platform/common_cells/issues/264), [#313](https://github.com/pulp-platform/common_cells/issues/313)), merged as `a49dc11` on 2026-06-30. The PR's own description is blunt about it: the old pointer logic "fired on valid_i/ready_i alone, without checking the other side of the handshake," and with assertions disabled — which includes any synthesized netlist — this silently corrupted FIFO state.

The only thing standing between this bug and actually breaking something was two `ASSERT_NEVER` checks (`CheckFullPush`, `CheckEmptyPop`). Those are simulation-only guards — they catch the condition in a testbench but do nothing once assertions are stripped out for synthesis. So the bug survived because it depended on hitting an exact corner case (a transfer attempted at the wrong moment), and even when it *was* hit, only assertion-enabled simulation would notice.

The fix, also in PR #322, is small: gate the write pointer on `valid_i && ready_o`, and the read pointer on `ready_i && valid_o`. Both sides of the handshake now have to agree before either pointer moves. The `ASSERT_NEVER` guards were removed entirely, since the corrected logic makes the illegal states unreachable rather than just flagged.

## Reproducing it

The model below isolates the write-side half of the bug. It's a two-entry FIFO — small enough that "full" is easy to force on purpose. The testbench fills it with two pushes, then offers a third word while `in_ready_o=0`. The buggy version still moves `wr_ptr_q` on that third push; the fixed version doesn't.

```text
verilator --binary --assert --timing -Wno-fatal \
  cc_passthrough_fifo_handshake.sv tb_cc_passthrough_fifo.sv \
  --top-module tb_cc_passthrough_fifo
./obj_dir/Vtb_cc_passthrough_fifo
```

Expected trace before the intentional assertion failure:

```text
Cycle 1 | word=0xaaaa0001 ready=1 buggy_wr_ptr=1 fixed_wr_ptr=1
Cycle 2 | word=0xbbbb0002 ready=1 buggy_wr_ptr=0 fixed_wr_ptr=0
Cycle 3 | word=0xcccc0003 ready=0 buggy_wr_ptr=1 fixed_wr_ptr=0
... Assertion failed ... FIFO write pointer advanced without an input handshake
```

Exit code 1 is expected here — the buggy instance is supposed to fail the assertion. The fixed instance satisfies the same property and exits clean.

The invariant being checked: an enqueue may only change FIFO write state when `in_valid_i && in_ready_o` actually holds. If `in_valid_i && !in_ready_o`, the write pointer has to stay put.

## Testing Anvil's boundary

Anvil's channels are blocking by construction. If you write a FIFO's push logic as `recv >> advance_write_pointer`, the pointer literally cannot move until the matching transfer completes — that's the safe ordering the buggy RTL above was missing.

But Anvil doesn't know that a given register represents a FIFO pointer, and it doesn't require every state update to be routed through a channel operation. Nothing stops a designer from updating that same pointer somewhere else entirely, outside any `send`/`recv`. So rather than just argue this, two small Anvil sources were written to actually test it.

`fifo_push.anvil` sequences the pointer update after `send`:

```text
send push_ep.slot(*wr_ptr) >>
set wr_ptr := *wr_ptr ^ 1'b1 >>
cycle 1
```

This compiles to `fifo_push_generated.sv.anvil.sv`. In the generated `FifoWriter` module, the pointer update sits inside the branch gated by `_push_ep_slot_ack` — the ordering is enforced structurally, not just by convention. Tested under forced back-pressure with `tb_fifo_push_anvil.sv`:

```text
verilator --binary --assert --timing -Wno-fatal \
  fifo_push_generated.sv.anvil.sv tb_fifo_push_anvil.sv \
  --top-module tb_fifo_push_anvil
./obj_dir/Vtb_fifo_push_anvil
```

```text
Holding ack low for 3 cycles, watching wr_ptr...
valid=1 ack=0 wr_ptr=0
valid=1 ack=0 wr_ptr=0
valid=1 ack=0 wr_ptr=0
ack asserted -> wr_ptr=1
next cycle -> wr_ptr=1 (should now be toggled)
PASS: wr_ptr held stable throughout back-pressure - test complete
```

`fifo_push_gap.anvil` is the other half — the same kind of update, but with no channel involved at all:

```text
set state := *state ^ 1'b1 >>
cycle 1
```

This compiles too, with no error or warning (`fifo_push_gap_generated.sv.anvil.sv`). Anvil has nothing to check here, because nothing in this proc touches a channel — there's no runtime test needed for this one; the fact that it compiles at all is the point.

Between the two: Anvil makes the correct pattern easy and safe once you use its channel model, but it doesn't stop you from writing the same mistake outside that model. That's why the verdict here is **PARTIAL** rather than a flat yes or no — and it's based on these two compiled results, not just the argument.

## Second independent instance

iDMA PR #93 and OpenTitan EDN #15469 are independent examples of the same broader class — state advancing before its handshake completes. iDMA moves its response FSM forward before the response handshake; EDN advances its offered command payload before the request handshake; this FIFO advances a pointer before its enqueue or dequeue handshake actually finishes. Different mechanisms, same underlying invariant broken.

> PR #322 is a reminder that valid/ready correctness isn't only about the `valid` and payload signals you can see at the interface — internal bookkeeping like a FIFO pointer has to follow the same rule: don't move until the transfer is real.