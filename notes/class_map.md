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

**Detection:**
Width-consistency lint / elaboration-time checks.
Formal parameter range verification at instantiation.
Cost: lint produces false positives on intentional
truncations and needs waiver discipline in large designs.

**Anvil:** Does not prevent. Width parameters are a
structural concern resolved at elaboration. Anvil's
timing type system does not track parameter compatibility
across module boundaries.

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

**Anvil:** Prevents — for interfaces expressed as Anvil
channels. The `send >> next_action` sequencing means
next_action cannot begin before the receiver performs
its matching `recv`. The compiler generates synchronization
state that holds the offered value stable during stalls.
This makes the specific mechanism of both bugs structurally
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
OpenCores uart16550 tf_push (Section 4 exclusion list) —
data latched one cycle after write-enable; state shared
between timing contexts. Related shared-state failure in
a different peripheral domain.

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

**Anvil:** Does not prevent. The counter is read and
written at valid times — there is no timing hazard for
Anvil to catch. The fault is that the same mutable
counter is reused across logically independent contexts.
Anvil's type system does not assign ownership of a
register to a transaction ID, and it does not verify
that per-ID isolation is maintained. A timing-safe
Anvil design could still declare one counter and reuse
it for all IDs without the compiler objecting.

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
Ibex #1018 (Section 4 exclusion list) — shift decoder
ignored instruction bits 25-26, so reserved encodings
executed instead of trapping. A valid instruction
encoding reached the wrong branch in a decode case.

**Detection:**
The `unique case` construct causes a simulation error
if any value reaches no branch. Formal case-coverage
analysis proves all enum values are handled.
Cost: `unique case` may conflict with X-propagation
in gate-level simulation; needs careful scoping.

**Anvil:** Does not prevent. Functional correctness of
what an operation computes is outside Anvil's type
system. A case statement with a missing branch compiles
and runs in Anvil just as it would in SystemVerilog,
provided the timing is safe.

---

## Summary Table

| Class | Bugs | SVA | Lint | Formal | Anvil |
|-------|------|-----|------|--------|-------|
| Width/parameterization | 1 | Partial | YES | YES | NO |
| Handshake/protocol | 2, 5 | YES | NO | YES | YES |
| Shared state/per-ID | 3 | YES | NO | YES | NO |
| Incomplete case | 4 | Partial | YES | YES | NO |

Three of the four classes resist Anvil entirely.
One class — handshake/protocol — is within Anvil's
prevention boundary, and two independent real bugs
confirm it.