# iDMA PR #93: response valid/ready violation

Primary source: [pulp-platform/iDMA PR #93](https://github.com/pulp-platform/iDMA/pull/93), merged 2026-05-21.

The original `idma_error_handler` asserted `rsp_valid_o` in its response-emission state, but unconditionally selected a wait state for the next clock. If `rsp_ready_i` was low, the state register advanced and `rsp_valid_o` fell on the following cycle without a transfer. PR #93 guards this transition with `rsp_ready_i`.

`idma93_reproducer.sv` preserves only that mechanism. It instantiates a parameterised model:

- `BUGGY=1` reproduces the pre-fix unconditional transition. Its assertion reports an error.
- `BUGGY=0` implements the PR's `rsp_ready_i` guard. The same assertion passes.

Run with an IEEE-1800 simulator, for example:

```text
iverilog -g2012 -s tb_idma93 -o idma93.vvp idma93_reproducer.sv tb_idma93.sv
vvp idma93.vvp
```

The expected transcript first prints `PASS: fixed version held valid during
back-pressure.` and then reports one assertion error for `buggy`. In Verilator,
the assertion's `$error` action stops simulation, so this intentional failing
run exits with code 1. That non-zero exit is the expected evidence that the
property catches the pre-fix design; it is not a clean regression pass.

## Anvil analysis (reasoned; not experimentally verified)

`idma93_response.anvil` uses Anvil's documented two-way channel synchronization. `send rsp_ep.rsp(...)` starts a send but completes only when `ResponseConsumer` performs its matching `recv`. The `>>` operator starts its right operand only after its left operand completes. Therefore `set state := ...` cannot begin before that communication event completes—there is no separate `rsp_ready_i` condition for the handler author to forget.

This is a prevention-by-semantics argument, not a claim that PR #93 was compiled in Anvil. Anvil's type system additionally checks declared message lifetimes and timing contracts, but it is important not to overstate the result: a designer could deliberately place an unrelated state update in a concurrent thread. The guarantee here follows from expressing the emission and transition as one sequenced process.

| Aspect | SystemVerilog (buggy) | Anvil (sequenced channel version) |
| --- | --- | --- |
| Handshake enforcement | Manual FSM bookkeeping | Built into synchronous channel semantics |
| State transition | Designer must remember to test `rsp_ready_i` | `send >> set` delays the update until `send` completes |
| Bug detection/prevention | Simulation assertion exposes the back-pressure corner case | The direct encoding has no “drop valid before ready” operation; timing/lifetime contracts are statically checked |

Sources for the Anvil semantics: [language reference](https://docs.anvil.kisp-lab.org/languageReference.html) and [communication guide](https://docs.anvil.kisp-lab.org/communication.html), accessed 2026-09-04.
