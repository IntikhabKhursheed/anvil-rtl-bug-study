# Bug Class Map

The five selected bugs cover three classes. The repeated handshake class is useful evidence because three independent designs violate the same broad rule in different ways.

## Class 1 — Width / parameterization

**Bug:** Bug 1, OpenTitan `keymgr_dpe` #25994.

**Invariant:** Every consumer of a shared parameter must receive a compatible width.

**Detection:** Width lint, elaboration checks, and parameterized regressions. Anvil does not establish parameter-width compatibility.

**Supporting instance:** verilog-axi #44, cited only as a related width/parameterization example.

## Class 2 — Valid/ready handshake-gated state advancement

**Bugs:** Bug 2, iDMA PR #93; Bug 3, common_cells PR #322; Bug 5, OpenTitan EDN #15469.

**Invariant:** Protocol-visible state may advance only after its corresponding valid/ready transfer completes. This means `valid && ready` for the relevant channel. While an offered transfer is stalled, the producer cannot retract `valid`, mutate the payload, or alter FIFO state as though a transfer occurred.

| Bug | State that advanced too early | Effect |
|---|---|---|
| iDMA | Error-handler FSM state | Response can be withdrawn before acceptance |
| common_cells | FIFO read/write pointer | FIFO state can corrupt on rejected push/pop |
| EDN | Offered request payload | CSRNG command word can be lost |

**Detection:**

```systemverilog
assert property (@(posedge clk) disable iff (!rst_n)
  (in_valid_i && !in_ready_o) |=> $stable(wr_ptr_q));
```

The iDMA and EDN payload/valid-stability assertions are related properties for their respective channels.

**Anvil:** `send >> next_action` prevents `next_action` from starting until the matching `recv` completes. This structurally prevents the iDMA and EDN sequencing mechanisms when expressed through channels. For Bug 3, `recv >> advance_write_pointer` and `send >> advance_read_pointer` express the safe FIFO ordering, but the compiler cannot know that an arbitrary register is a FIFO pointer. Thus Bug 3 is **PARTIAL**: Anvil makes the correct ordering natural but does not prohibit every incorrect FIFO bookkeeping implementation.

## Class 3 — Functional omission

**Bug:** Bug 4, CVFPU PR #122.

**Invariant:** Every legal operation encoding must be handled by each dispatch site that consumes it.

**Detection:** `unique case`, lint, operation coverage, and formal checks. Anvil timing safety does not prove functional completeness.

**Supporting instance:** Ibex #1018, cited only as a related decode/specification-conformance example.

## Summary

| Class | Bugs | Primary detection | Anvil verdict |
|---|---|---|---|
| Width / parameterization | 1 | Lint and elaboration | NO |
| Handshake-gated state advancement | 2, 3, 5 | SVA and formal protocol checks | YES for 2 and 5; PARTIAL for 3 |
| Functional omission | 4 | Lint, coverage, formal | NO |

The archived FlooNoC shared-counter investigation is retained at `bugs/archive/bug3_floonoc_counter_shared_state/`; it is not one of the five final selected bugs.
