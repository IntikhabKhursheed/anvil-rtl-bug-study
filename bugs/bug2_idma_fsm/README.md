# iDMA PR #93: response valid/ready violation

Primary source: [pulp-platform/iDMA PR #93](https://github.com/pulp-platform/iDMA/pull/93), merged 2026-05-21.

The original `idma_error_handler` asserted `rsp_valid_o` in its response-emission state but unconditionally selected a wait state for the next clock. If `rsp_ready_i` was low, the state register advanced and `rsp_valid_o` fell on the following cycle without a completed transfer. PR #93 fixes this by guarding the transition with `rsp_ready_i`.

`idma93_reproducer.sv` isolates that mechanism. It instantiates a parameterised model:

- `BUGGY=1` reproduces the unconditional transition. The SVA assertion fires.
- `BUGGY=0` adds the `rsp_ready_i` guard. The same assertion passes.

```text
verilator --binary --assert -Wno-fatal idma93_reproducer.sv tb_idma93.sv
./obj_dir/Vsim
```

The transcript prints `PASS: fixed version held valid during back-pressure.` first, then reports one assertion error for the buggy instance. Verilator's `$error` action stops simulation and exits with code 1 — that non-zero exit is intentional. It is the evidence that the property catches the pre-fix design, not a regression failure.

## Anvil

`idma93_response.anvil` encodes the same response path using Anvil's two-way channel synchronisation. The key point is that `send rsp_ep.rsp(...) >> set state := ...` cannot advance the state until the send completes — meaning until the consumer has executed its matching `recv`. There is no separate `rsp_ready_i` condition for the designer to forget; the sequencing is part of the language.

The generated SystemVerilog is in `idma93_response_generated.sv.anvil.sv`. In it, the compiler inserted `_thread_0_event_syncstate_1_q`, a register that holds `rsp_valid` high until `ack` arrives — the same logic PR #93 added by hand. `tb_idma93_anvil.sv` checks this by driving the generated `ErrorHandler` module directly and injecting three cycles of forced back-pressure:

```text
verilator --binary --assert -Wno-fatal \
  idma93_response_generated.sv.anvil.sv tb_idma93_anvil.sv \
  --top-module tb_idma93_anvil
./obj_dir/Vtb_idma93_anvil
```

`rsp_valid` holds stable across all three held cycles and only drops after `ack` is asserted; the SVA property never fires.

This is a prevention-by-semantics argument, not a claim that the original iDMA module was written or compiled in Anvil. A designer could still place an unrelated state update in a concurrent thread and introduce a different kind of bug. The guarantee here is narrower: expressing emission and transition as one sequenced process makes the specific drop-valid-before-ready mistake structurally impossible.

| Aspect | SystemVerilog (buggy) | Anvil |
|---|---|---|
| Handshake enforcement | Manual FSM bookkeeping | Built into channel semantics |
| State transition | Designer must check `rsp_ready_i` | `send >> set` delays update until send completes |
| Bug surface | Back-pressure corner case, missed in normal simulation | No drop-valid-before-ready operation exists |
| Verification | SVA property catches it after the fact | Compiler-generated `syncstate_q` prevents it |

Anvil language reference and communication guide: https://docs.anvil.kisp-lab.org, accessed 2026-09-04.