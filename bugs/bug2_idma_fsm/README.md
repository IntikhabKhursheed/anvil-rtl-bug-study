# iDMA PR #93: response valid/ready violation

Primary source: [pulp-platform/iDMA PR #93](https://github.com/pulp-platform/iDMA/pull/93), merged 2026-05-21.

The original `idma_error_handler` asserted `rsp_valid_o` in its response-emission state but unconditionally selected a wait state for the next clock. If `rsp_ready_i` was low, the state register advanced and `rsp_valid_o` fell on the following cycle without a completed transfer. PR #93 fixes this by guarding the transition with `rsp_ready_i`.

`idma93_reproducer.sv` isolates that mechanism. It instantiates a parameterised model:

- `BUGGY=1` reproduces the unconditional transition. The SVA assertion fires.
- `BUGGY=0` adds the `rsp_ready_i` guard. The same assertion passes.

Run with an IEEE-1800 simulator:

```text
iverilog -g2012 -s tb_idma93 -o idma93.vvp idma93_reproducer.sv tb_idma93.sv
vvp idma93.vvp
```

The transcript prints `PASS: fixed version held valid during back-pressure.` first, then reports one assertion error for the buggy instance. In Verilator the `$error` action stops simulation and exits with code 1 — that non-zero exit is intentional. It is the evidence that the property catches the pre-fix design, not a regression failure.

## Anvil

`idma93_response.anvil` encodes the same response path using Anvil's two-way channel synchronisation. The key point is that `send rsp_ep.rsp(...) >> set state := ...` cannot advance the state until the send completes — meaning until the consumer has executed its matching `recv`. There is no separate `rsp_ready_i` condition for the designer to forget; the sequencing is part of the language.

The Anvil source was compiled using the Anvil playground compiler (commit d138cabedbfc). The generated SystemVerilog is in `idma93_response_generated.sv`. The compiler automatically inserted `_thread_0_event_syncstate_1_q`, a register that holds `rsp_valid` high until `ack` arrives — the same logic PR #93 added by hand. `tb_anvil_idma93.sv` checks this by injecting three cycles of forced back-pressure; the SVA property never fires on the generated design.

This is a prevention-by-semantics argument, not a claim that the original iDMA module was written or compiled in Anvil. A designer could still place an unrelated state update in a concurrent thread and introduce a different kind of bug. The guarantee here is narrower: expressing emission and transition as one sequenced process makes the specific drop-valid-before-ready mistake structurally impossible.

| Aspect | SystemVerilog (buggy) | Anvil |
|---|---|---|
| Handshake enforcement | Manual FSM bookkeeping | Built into channel semantics |
| State transition | Designer must check `rsp_ready_i` | `send >> set` delays update until send completes |
| Bug surface | Back-pressure corner case, missed in normal simulation | No drop-valid-before-ready operation exists |
| Verification | SVA property catches it after the fact | Compiler-generated `syncstate_q` prevents it |

Anvil language reference and communication guide: https://docs.anvil.kisp-lab.org, accessed 2026-09-04.