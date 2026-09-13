# common_cells `passthrough_stream_fifo`: pointer advances without a handshake

This is a minimal reproducer of [common_cells PR #322](https://github.com/pulp-platform/common_cells/pull/322), merged as `a49dc11` on 2026-06-30. The affected FIFO advanced its read pointer on `ready_i` alone and its write pointer on `valid_i` alone. Thus an attempted push while the FIFO was full, or a pop while empty, could alter FIFO state even though no valid/ready transfer occurred. The PR notes that the resulting corruption matters when assertions are disabled or in synthesized netlists.

The reduced model below focuses on the write-side half. It fills a two-entry FIFO, then presents a third word while `in_ready_o=0`. The buggy model toggles `wr_ptr_q`; the fixed model does not.

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

Exit code 1 is expected: the buggy instance violates the assertion. The fixed instance satisfies the same property.

## Violated invariant

An enqueue changes FIFO write state only when `in_valid_i && in_ready_o` is true. Equivalently, if `in_valid_i && !in_ready_o`, the write pointer must remain stable. PR #322 fixed the original RTL by changing pointer updates to require the corresponding complete handshake.

## Anvil assessment: partial risk reduction, not a complete structural guarantee

Anvil channels make communication blocking. If a FIFO implementation writes `recv >> advance_write_pointer`, the pointer advance cannot occur until the matching input transfer completes. That directly expresses the safe ordering missing from the buggy RTL.

However, Anvil does not infer that a particular register is a FIFO pointer or require its update to follow a channel operation. A programmer could still update a pointer before `recv`, or implement incorrect full/empty bookkeeping. The appropriate verdict is therefore **PARTIAL**: channel sequencing makes the safe implementation natural and prevents this error in that encoding, but the language does not make all incorrect FIFO-state implementations unwriteable. SVA or formal FIFO data-conservation checks remain necessary.

## Second independent instance

iDMA PR #93 and OpenTitan EDN #15469 are independent instances of the broader handshake-gated state-advancement class. iDMA advances its response FSM before the response handshake; EDN advances the offered command payload before the request handshake; this FIFO advances a pointer before its enqueue or dequeue handshake. Their mechanisms differ, but each lets protocol-visible state progress without a completed valid/ready transfer.

> PR #322 shows that valid/ready correctness includes internal state: FIFO pointers, as well as visible `valid` and payload signals, must advance only when their transfer actually occurs.
