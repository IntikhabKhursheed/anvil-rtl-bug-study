# Anvil RTL Bug Study

### Root-Cause Analysis, Reproduction, and Detection of Real SystemVerilog Bugs

This repository contains a systematic study of **five real-world RTL bugs** found in open-source SystemVerilog hardware projects.

The study examines how each bug occurred, why it was able to survive existing verification, how it can be detected, and whether **Anvil's type system and communication model** can prevent the underlying failure.

---

## Overview

RTL bugs do not all come from the same source. Some are caused by incorrect handshake behavior, while others result from parameter mismatches, shared state, or incomplete functional logic.

This study focuses on five documented bugs covering four different classes:

| # | Design                    | Bug                             | Class                           | Anvil |
| - | ------------------------- | ------------------------------- | ------------------------------- | ----- |
| 1 | OpenTitan `keymgr_dpe`    | Width truncation                | Width / parameterization        | ❌     |
| 2 | iDMA                      | Valid/ready FSM violation       | Handshake / protocol            | ✅     |
| 3 | FlooNoC `floo_simple_rob` | Shared burst counter            | Shared state / per-ID isolation | ❌     |
| 4 | CVFPU                     | Incomplete `ADDS` case handling | Functional omission             | ❌     |
| 5 | OpenTitan EDN             | Back-pressure violation         | Handshake / protocol            | ✅     |

The central result is that **Anvil's communication model addresses a specific class of timing and handshake errors**, while other structural and functional bug classes remain outside its type-system guarantees.

---

## Study Goals

For each bug, the study investigates:

1. **What happened?**
   The original design and observable failure.

2. **What caused it?**
   The RTL mechanism responsible for the bug.

3. **Why did it survive?**
   The verification or testing gap that allowed it to remain undetected.

4. **What class does it belong to?**
   The broader bug pattern represented by the instance.

5. **How can it be detected?**
   SVA, linting, formal verification, simulation, or other appropriate techniques.

6. **Can Anvil prevent it?**
   Whether the failure falls within the guarantees provided by Anvil's type system and communication model.

---

## Bugs Studied

### Bug 1 — OpenTitan `keymgr_dpe`

**Class:** Width / parameterization
**Anvil:** ❌ Not prevented

A parameterization mismatch causes a data path requiring a wider value to use a narrower width, resulting in truncation.

**Sources:** OpenTitan Issue #25994 and PR #26055.

The failure is structural and established through parameterization and elaboration rather than through runtime communication timing.

---

### Bug 2 — iDMA PR #93

**Class:** Handshake / protocol
**Anvil:** ✅ Prevented

The iDMA error-handling FSM can advance without respecting the response interface's `ready` condition. This can cause the response transaction to be withdrawn before the receiver accepts it.

The bug is reproduced in a standalone SystemVerilog model with injected back-pressure and an assertion checking the required valid/ready behavior.

**Source:** pulp-platform/iDMA PR #93.

---

### Bug 3 — FlooNoC `floo_simple_rob`

**Class:** Shared state / per-ID isolation
**Anvil:** ❌ Not prevented

A shared burst counter is used across interleaved transaction contexts. When multiple IDs progress concurrently, one transaction can affect the state used to calculate another transaction's reorder-buffer address.

A standalone reproducer demonstrates the difference between the shared-counter implementation and an implementation with independent per-context state.

**Source:** FlooNoC v0.6.0 / associated fix commit.

---

### Bug 4 — CVFPU

**Class:** Incomplete case / functional omission
**Anvil:** ❌ Not prevented

A newly supported operation is not handled by all relevant case statements. The default behavior therefore produces incorrect functional behavior instead of explicitly rejecting the unsupported case.

**Source:** CVFPU PR #122.

This represents a functional completeness problem rather than a communication-timing problem.

---

### Bug 5 — OpenTitan EDN

**Class:** Handshake / protocol
**Anvil:** ✅ Prevented

During CSRNG back-pressure, the EDN interface can change the request information before the receiver accepts the transaction. This violates the required valid/ready communication behavior and can result in command words being lost.

The fix introduces buffering so that the request remains stable until it is accepted.

**Sources:** OpenTitan Issue #15469 and PR #15478.

---

# Reproduction

The study includes standalone SystemVerilog reproductions designed to isolate the relevant failure mechanisms.

The reproducer methodology is:

```text
Original bug
     ↓
Identify failure mechanism
     ↓
Reduce to minimal RTL model
     ↓
Create buggy implementation
     ↓
Create corrected implementation
     ↓
Apply triggering stimulus
     ↓
Check violated invariant with SVA
```

Two bugs are used as the primary standalone reproductions required by the study.

The repository also contains a supporting FlooNoC reproduction used to investigate the shared-state failure mechanism.

---

## Anvil Comparison

The study does not treat Anvil as a replacement for existing RTL verification.

Instead, each bug is classified according to whether its failure mechanism falls within the properties enforced by Anvil.

### Within Anvil's boundary

The two handshake bugs demonstrate the same general invariant:

```text
valid = 1
ready = 0
      ↓
transaction must remain stable
      ↓
accept only when ready = 1
```

Anvil's channel communication semantics provide compile-time guarantees for this style of communication.

The two instances are:

* iDMA response handling
* OpenTitan EDN → CSRNG communication

They occur in different designs and through different RTL mechanisms, but both involve incorrect behavior under back-pressure.

### Outside Anvil's boundary

The remaining bugs represent different classes:

* **Width / parameterization** — Bug 1
* **Shared state / transaction isolation** — Bug 3
* **Functional completeness** — Bug 4

These properties are not established by Anvil's communication type system and therefore require other verification techniques.

---

# Detection Techniques

Different bug classes require different forms of checking.

| Bug Class                | Useful Detection                                               |
| ------------------------ | -------------------------------------------------------------- |
| Handshake / protocol     | SVA, formal verification, protocol checking                    |
| Width / parameterization | Linting, elaboration checks, parameterized testing             |
| Shared state / isolation | SVA, formal verification, reference models                     |
| Functional omission      | Regression tests, coverage, `unique case`, formal verification |

The purpose of this comparison is to show where each technique provides useful coverage rather than treating any single technique as sufficient for all RTL bugs.

---

# Repository Structure

```text
anvil-rtl-bug-study/
│
├── bugs/
│   ├── bug1_opentitan_width/
│   ├── bug2_idma_fsm/
│   ├── bug3_floonoc_counter/
│   ├── bug4_cvfpu_case/
│   └── bug5_opentitan_edn/
│
├── notes/
│   ├── anvil_boundary.md
│   └── class_map.md
│
├── sources.md
├── search-log.md
└── README.md
```

Each bug directory contains the available analysis, source references, detection properties, and reproduction material where applicable.

---

# Sources

Primary sources and supporting references are recorded in [`sources.md`](sources.md), including:

* OpenTitan issues and pull requests
* iDMA pull request #93
* FlooNoC source and fix information
* CVFPU pull request #122
* Anvil documentation
* Anvil research paper

The search and selection process is documented separately in [`search-log.md`](search-log.md).

---

# Key Result

The study identifies a clear boundary for the properties examined:

> **Anvil provides strong guarantees for a specific class of timing-safe communication errors, but it does not replace verification of structural or functional correctness.**

The two handshake cases demonstrate where Anvil's communication model can prevent a real RTL failure. The other three cases show properties that remain outside that boundary.

This makes the study a comparison of **complementary verification techniques**, rather than a claim that one approach can detect every class of RTL bug.

---

## Related Work

**Anvil paper:**
*Anvil: A General-Purpose Timing-Safe Hardware Description Language*
arXiv:2503.19447

**Anvil documentation:**
https://docs.anvil.kisp-lab.org/

---

## Author

**Intikhab Khursheed**

Software Engineer with research interest in hardware verification and timing-safe HDL design

This repository is maintained as an independent study of real-world RTL bugs, their detection, and the applicability of Anvil's type-system guarantees.
