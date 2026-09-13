## Paper Reference

Anvil: A General-Purpose Timing-Safe Hardware Description Language
Jason Zhijingcheng Yu, Aditya Ranjan Jha, Umang Mathur,
Trevor E. Carlson, Prateek Saxena
ASPLOS 2026 / arXiv:2503.19447

Core guarantee (Section 1):
"Anvil is the only HDL we know of that guarantees timing safety,
i.e., absence of timing hazards, without sacrificing expressiveness"

Timing hazard definition (Section 1):
"Unintended behaviours arise when a register is mutated even when
its dependent signals are expected to remain stable (unchanged)"

Channel semantics (Section 4.1):
"both sending and receiving are blocking"

Wait operator (Section 4.5):
"In t1 >> t2, the evaluation of t1 must be completed before
the evaluation of t2 begins"

Scope (Section 9):
Anvil ensures safe use of values which are guaranteed to remain
unchanged throughout their lifetimes. In this study, this guarantee
did not extend to functional logic, per-ID state ownership, or
parameter compatibility.

# Anvil Guarantee Boundary

This note records what Anvil's type system actually guarantees
and where that guarantee runs out, based on what the five bugs
in this study demonstrated.

---

## What Anvil Guarantees

Anvil's core promise is timing safety. Concretely:

- A `send` operation does not complete until the receiver
  executes the matching `recv`. Nothing sequenced after `send`
  with `>>` can begin before that communication event finishes.
- Values governed by channel timing contracts have checked
  lifetimes — the compiler rejects designs where a value is
  read before it is available or written while it is in use.
- The generated RTL includes synchronization state (visible
  as registers like `_thread_0_event_syncstate_1_q`) that
  maintains the communication handshake during stalls. This
  is an implementation detail of the guarantee, not the
  guarantee itself.

These claims hold for communication expressed through Anvil
channels. Anvil does not make every external RTL protocol
automatically correct.

---

## What Anvil Does Not Guarantee

- **Per-ID resource ownership.** Anvil has no notion of
  "this counter belongs to transaction ID 3." A designer
  can still write a single shared counter and reuse it
  across independent transaction contexts without the
  compiler objecting.

- **Functional arithmetic correctness.** If the arithmetic
  in an operation is wrong — wrong format, wrong operand,
  wrong case — Anvil accepts it as long as the timing is
  safe. Correctness of what is computed is outside the
  type system.

- **Case statement completeness.** Adding a new operation
  to an enum and forgetting to handle it in a case statement
  is a functional omission. Anvil does not track whether
  every enum value reaches the right branch.

- **Parameter width compatibility.** Whether a shared
  parameter produces the right bit width for every module
  that uses it is an elaboration-time structural concern.
  Anvil's timing type system does not verify this.

---

## Bug-by-Bug Verdict

| Bug | Design | Class | Anvil |
|-----|--------|-------|-------|
| Bug 1 | OpenTitan keymgr_dpe #25994 | Width/parameterization | NO |
| Bug 2 | iDMA PR #93 | Handshake/protocol | YES |
| Bug 3 | common_cells PR #322 | FIFO pointer advancement | PARTIAL |
| Bug 4 | CVFPU PR #122 | Incomplete case/functional logic | NO |
| Bug 5 | OpenTitan EDN #15469 | Handshake/protocol | YES |

---

## The Core Argument

For the two reproduced handshake cases, Anvil's blocking channel
semantics and sequencing prevent the specific valid/ready stability
violations observed in the original SystemVerilog designs. A send
does not complete until the corresponding receiver performs recv,
and operations sequenced after the communication cannot begin
before that communication completes. Thus, the specific mechanisms
that caused the iDMA and EDN failures cannot occur when the
corresponding communication is expressed through Anvil channels.

Bug 3 sits on the boundary. Anvil can express the intended FIFO
ordering as `recv >> advance_write_pointer` and
`send >> advance_read_pointer`, so a pointer update written after its
channel operation cannot happen first. But Anvil does not know that an
arbitrary register is a FIFO pointer, and it does not prohibit a
designer from updating that register before the channel operation.
The result is partial risk reduction, not a universal proof of FIFO
bookkeeping correctness. Bugs 1 and 4 remain outside the channel model.

---

## Boundary Summary

The study shows that Anvil's timing-safety guarantees address a
specific and important class of communication hazards. The width and
functional-omission cases remain outside that guarantee. The FIFO case
shows a narrower boundary inside the handshake class: safe channel
sequencing helps, but it does not replace explicit verification of
internal resource bookkeeping.

---

## What Still Needs SVA or Formal

All four bug classes need verification beyond Anvil:

- Width/parameterization: width-consistency lint,
  formal elaboration checks
- Handshake/protocol: SVA valid-stability property
  (catches the same bugs in plain SystemVerilog)
- FIFO bookkeeping: SVA or formal checks that pointers move only on
  the corresponding handshake and that data is conserved
- Incomplete case: unique case construct,
  formal case-coverage analysis

Anvil covers one of these four classes. The others
need their own properties regardless of the HDL used.
