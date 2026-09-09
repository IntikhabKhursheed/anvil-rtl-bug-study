# Bug Class Map

Four distinct classes emerged from the five bugs.
Bugs 2 and 5 share a class, which is itself useful
evidence — two independent designs, same violated
invariant, different failure modes.

---

## Class 1 — Width / Parameterization

**Bugs:** Bug 1 (OpenTitan keymgr_dpe #25994)

**What went wrong:**
A parameter was shared across two modules that needed
different bit widths. The DPE path required 1664 bits;
the shared parameter gave it 1152. SystemVerilog silently
truncated the extra 512 bits with no error.

**Invariant violated:**
Every module consuming a shared parameter must be
independently verified to have compatible width
requirements. A parameter correct for one consumer
is not automatically correct for another.

**Second independent instance:**
verilog-axi #44 (Section 4 exclusion list) — AXI-lite
crossbar fails for M_ADDR_WIDTH below 12. Address-decode
logic assumed a minimum width without enforcing it.
Cited as a supporting example of the same class.

**Detection:**
This class is better detected through width-consistency
linting and elaboration-time checks. Formal verification
can additionally check that supported parameter
configurations preserve the required widths and ranges.
A runtime SVA is not the primary detection mechanism
here because the failure is structural — the incorrect
width is established when the parameterized design is
elaborated.

**Anvil:** This failure is a parameterization and
elaboration-time problem. It is outside the timing-safety
property studied here and is therefore not prevented by
Anvil's timing-safety mechanism.

---

## Class 2 — Handshake / Protocol Violation

**Bugs:** Bug 2 (iDMA PR #93), Bug 5 (OpenTitan EDN #15469)

**What went wrong:**
In both cases a producer failed to honor the valid/ready
handshake under back-pressure. The mechanisms differed:

| | Bug 2 iDMA | Bug 5 EDN |
|--|--|--|
| Failure | valid retracted | payload mutated |
| ready=0 | offer disappeared | offered data changed |
| Effect | transfer missed | command word lost |
| Fix | FSM state guard | output FIFO |

Despite different mechanisms, both violated the same
protocol invariant.

**Invariant violated:**
Once a producer asserts valid=1, it must hold valid=1
and keep the offered data stable until the receiver
asserts ready=1 and the handshake completes.

**Second independent instance:**
pulp-platform/axi (Section 4 exclusion list) — B and R
payloads changed value between valid assertion and the
completing handshake. Same invariant, third design.
Cited as a supporting example of the same class.

**Detection:**
SVA valid-stability property:

```systemverilog
assert property (
  @(posedge clk) disable iff (!rst_n)
  (valid_o && !ready_i) |=> (valid_o && $stable(data_o)))
else $error("producer violated valid/ready stability");
```

Cost: property requires knowledge of which signal pairs
form a handshake. False positives possible if data is
intentionally pipelined without a registered channel.

**Anvil:** For interfaces expressed as Anvil channels,
the `send >> next_action` sequencing means next_action
cannot begin before the receiver performs its matching
`recv`. The compiler generates synchronization state
that holds the offered value stable during stalls. This
makes the specific mechanism of both bugs structurally
impossible to write.

---

## Class 3 — Shared State / Per-Context Isolation

**Bugs:** Bug 3 (FlooNoC floo_simple_rob commit 1d801a0)

**What went wrong:**
A single burst counter `rsp_burst_cnt_q` was shared across
all response transaction IDs. When burst responses from
different IDs interleaved, each one advanced the same
counter, producing wrong ROB offsets. The developer's own
WARNING comment acknowledged the limitation before the
bug was fixed. A runtime assertion `NoBurstSupport` was
added to catch the case rather than fix it immediately.

**Invariant violated:**
Each independently active transaction context must maintain
its own progress state. A counter that tracks per-transaction
position cannot be shared across concurrent transactions
with different IDs.

**Second independent instance:**
No second independent instance is claimed for this class.
The assignment exclusion list contains buffering and
timing-related bugs but none with a confirmed per-ID
shared-state isolation mechanism matching this class
precisely.

**Detection:**
SVA relating each response ID to its own stored burst count:

```systemverilog
assert property (
  @(posedge clk) disable iff (!rst_n)
  (rsp_valid_i && rsp_id_i && rsp_last_i) |->
  !addr_mismatch_q)
else $error("interleaved IDs produced wrong ROB address");
```

Cost: property requires a reference model tracking
per-ID expected offset. Runtime overhead proportional
to number of active IDs.

**Anvil:** This bug is outside the timing-safety property
demonstrated by Anvil. The counter can be accessed at
valid and well-defined times while still being associated
with the wrong transaction ID. The failure is one of
state-management and per-transaction isolation rather
than timing safety. Anvil's timing guarantees do not
establish that each transaction ID uses an independent
state element or that a shared counter is associated with
the correct transaction context. A timing-safe Anvil
design could still declare one counter and reuse it for
all IDs without the compiler objecting.

---

## Class 4 — Incomplete Case / Functional Omission

**Bugs:** Bug 4 (CVFPU PR #122)

**What went wrong:**
PR #114 added a new floating-point operation ADDS to
the operation enum. PR #122 (the bug fix) confirmed
that three case statements were not updated: the operand
default assignment in fpnew_fma.sv, the same case in
fpnew_fma_multi.sv, and the addend exponent rebias logic.
When ADDS was requested, all three fell through to
default, producing zero operands or wrong format
extraction. The developer apologized in the PR description.

**Invariant violated:**
Every valid value of an operation enum must be handled
explicitly in every case statement that dispatches on it.
Adding a new enum value without updating all consumers
is a functional omission regardless of how well the
rest of the design is verified.

**Second independent instance:**
Ibex #1018 (Section 4 exclusion list) — a related
decode/specification-conformance failure in which reserved
encodings were incorrectly accepted rather than trapped.
Cited as a supporting functional-omission example only.
It is not claimed to have the identical case-statement
mechanism as CVFPU Bug 4.

**Detection:**
This class can be detected using unique case checks, lint
rules for incomplete case statements, and formal case
coverage. Operation-specific regression tests are also
important because a missing case branch may remain
unnoticed if the corresponding operation is never
exercised. The appropriate mechanism depends on whether
the goal is structural detection of an incomplete case
or behavioral verification of the resulting operation.

**Anvil:** This is a functional-logic omission rather
than a timing hazard. Anvil's timing-safety guarantees
do not establish that every operation encoding is handled
by every relevant case statement. A case statement with
a missing branch compiles and runs in Anvil just as it
would in SystemVerilog, provided the timing is safe.

---

## Summary Table

| Class | Bugs | SVA | Lint | Formal | Anvil |
|-------|------|-----|------|--------|-------|
| Width/parameterization | 1 | No | YES | YES | NO |
| Handshake/protocol | 2, 5 | YES | NO | YES | YES |
| Shared state/per-ID | 3 | YES | NO | YES | NO |
| Incomplete case | 4 | Partial | YES | YES | NO |

---

## Closing Synthesis

The five bugs show that Anvil's guarantee is narrow but
deep. It provides a strong static guarantee for timing
safety through its type system and timing contracts, but
it does not replace verification of functional correctness,
parameter compatibility, or logical state ownership.

Bugs 2 and 5 demonstrate the positive boundary: both
violations arise from producer-consumer communication
under back-pressure, and both mechanisms are prevented
when expressed using Anvil's blocking communication
semantics. Bugs 1, 3, and 4 demonstrate the negative
boundary: their failures concern parameterization, state
ownership, and functional logic rather than timing safety.