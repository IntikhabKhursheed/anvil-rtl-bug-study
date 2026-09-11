# Sources

One entry per cited source.
Role: P = primary bug report, M = mechanism or fix source,
A = Anvil semantics source, S = second independent instance.

---

## Bug 1 — OpenTitan keymgr_dpe width truncation

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| OpenTitan #25994 | https://github.com/lowRISC/opentitan/issues/25994 | Issue #25994 | 2026-09-05 | P |
| OpenTitan PR #26055 | https://github.com/lowRISC/opentitan/pull/26055 | PR #26055 | 2026-09-05 | M |

---

## Bug 2 — iDMA error-handler valid/ready FSM violation

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| iDMA PR #93 | https://github.com/pulp-platform/iDMA/pull/93 | PR #93, merged 2026-05-21 | 2026-09-04 | P, M |
| AnvilHDL language reference | https://docs.anvil.kisp-lab.org/languageReference.html | — | 2026-09-04 | A |
| AnvilHDL communication guide | https://docs.anvil.kisp-lab.org/communication.html | — | 2026-09-04 | A |
| Anvil paper | https://arxiv.org/abs/2503.19447 | arXiv:2503.19447 | 2026-09-08 | A |

Second independent instance (S): OpenTitan EDN #15469 (Bug 5) —
same handshake/protocol class, different design. iDMA retracts
valid; EDN mutates payload. Both violate valid/ready stability
under back-pressure.

---

## Bug 3 — FlooNoC floo_simple_rob shared burst counter

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| FlooNoC v0.6.0 release notes | https://github.com/pulp-platform/FlooNoC/releases/tag/v0.6.0 | v0.6.0 | 2026-09-05 | P, M |
| FlooNoC commit 1d801a0 | https://github.com/pulp-platform/FlooNoC/tree/1d801a0b92af5fce6e35232d4f03327c91243bf7 | commit 1d801a0 | 2026-09-05 | M |

Note: commit 1d801a0 documents the identical mechanism in
floo_simple_rob.sv including the developer's own WARNING comment
and NoBurstSupport assertion.

No second independent instance is claimed for this class.
The assignment exclusion list contains buffering and timing-related
bugs but none with a confirmed per-ID shared-state isolation
mechanism matching this class precisely.

---

## Bug 4 — CVFPU FMA ADDS incomplete case handling

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| CVFPU PR #122 | https://github.com/openhwgroup/cvfpu/pull/122 | PR #122, merged 2024-05-23 | 2026-09-05 | P, M |

Second independent instance (S): Ibex #1018 (Section 4 exclusion
list) — a related decode/specification-conformance failure in
which reserved encodings were incorrectly accepted rather than
trapped. Cited as a supporting functional-omission example only.
It is not claimed to have the identical case-statement mechanism
as this bug.

---

## Bug 5 — OpenTitan EDN valid/ready back-pressure violation

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| OpenTitan #15469 | https://github.com/lowRISC/opentitan/issues/15469 | Issue #15469 | 2026-09-07 | P |
| OpenTitan PR #15478 | https://github.com/lowRISC/opentitan/pull/15478 | PR #15478, merge commit 8d42791 | 2026-09-07 | M (Fix) |
| OpenTitan PR #15402 | https://github.com/lowRISC/opentitan/pull/15402 | PR #15402 (unmerged historical hot-fix) | 2026-09-07 | M |
| AnvilHDL communication guide | https://docs.anvil.kisp-lab.org/communication.html | — | 2026-09-07 | A |
| Anvil paper | https://arxiv.org/abs/2503.19447 | arXiv:2503.19447 | 2026-09-08 | A |

No second independent instance is claimed for this class.
The connection to iDMA PR #93 (Bug 2) is made in the closing
synthesis: both belong to the handshake/protocol class but
violate different aspects of the valid/ready stability invariant.

---

## Anvil Paper Reference

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| Anvil ASPLOS 2026 | https://arxiv.org/abs/2503.19447 | arXiv:2503.19447 | 2026-09-08 | A |

Yu, Jha, Mathur, Carlson, Saxena.
"Anvil: A General-Purpose Timing-Safe Hardware Description Language."
ASPLOS 2026.

Key claims used in this study:
- Section 1: "Anvil is the only HDL we know of that guarantees
  timing safety, i.e., absence of timing hazards"
- Section 4.1: "both sending and receiving are blocking"
- Section 4.5: "t1 must complete before t2 begins" (>> operator)
- Section 9: Anvil ensures safe use of values which are guaranteed
  to remain unchanged throughout their lifetimes. In this study,
  this guarantee did not extend to functional logic, per-ID state
  ownership, or parameter compatibility.

---

## Independently Evaluated Candidates — Rejected

These were found during search and evaluated against selection
criteria before being set aside.

| Candidate | URL | Verified? | Rejection Reason |
|-----------|-----|-----------|-----------------|
| OpenTitan #23526 | https://github.com/lowRISC/opentitan/issues/23526 | ✓ Real | Investigated as EDN handshake candidate; set aside because associated hot-fix PR #15402 was unmerged and #15469/#15478 provided a clearer merged fixing history and RTL diff |
| OpenTitan #9324 | https://github.com/lowRISC/opentitan/issues/9324 | ✓ Real | Issue describes symptom-level behavior; no RTL mechanism identifiable from primary source; rejected on sourcing rules |
| tc_sram_xilinx | pulp-platform/tech_cells_generic v0.2.13 release notes | Partial | Release notes only; no RTL diff available; mechanism required inference; also redundant with Bug 1 width/parameterization class |
| FlooNoC PR #65 infra | https://github.com/pulp-platform/FlooNoC/pull/65 | ✓ Real | Infrastructure/code-generation refactoring between Python and SV; no sufficiently clear RTL functional or timing failure |
| common_cells FIFO | pulp-platform/common_cells | ✗ | No specific issue with stable identifier found |
| LiteX LiteDRAM | LiteX issue tracker | Partial | No stable identifier; mechanism too vague for a sourced claim |

---

## Assignment Exclusion List — Confirmed Read

These bugs appear in Section 4 of the assignment. They were
not independently rejected candidates — they were ineligible
for selection from the start. Some are cited as supporting
instances in the report, as explicitly permitted by the
assignment.

| Candidate | Class | Cited as S? |
|-----------|-------|-------------|
| OpenTitan #24592 | CDC/Metastability | No |
| OpenTitan #13286 | CDC | No |
| verilog-axi #31 | Deadlock | No |
| pulp-platform/axi #330 | Deadlock | No |
| VHDL 16550 UART #14 | FIFO/Counter | No |
| riscv-formal Divider | Reset/Init | No |
| Ibex #1018 | Decode/spec conformance | Yes — Bug 4 supporting instance |
| verilog-axi #44 | Width/parameterization | No |
| pulp-platform/axi B/R payload | Handshake | No |
| OpenCores uart16550 tf_push | Buffering/timing | No |