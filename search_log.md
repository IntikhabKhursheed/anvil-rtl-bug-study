# Search Log

Searches conducted, candidates evaluated, and decisions made.

The assignment supplied an explicit exclusion list of previously
known bugs (Section 4). Those bugs were not considered eligible
candidates for the five selected bugs. Where useful, excluded
examples are cited only as supporting instances of a bug class,
as explicitly permitted by the assignment.

---

## 2026-09-01 — Initial Search and Bug 2

Read the assignment requirements and exclusion list in full
before beginning the search.

The exclusion list contains substantial coverage of AXI handshake
bugs, CDC/metastability bugs, CPU pipeline bugs, and several
arithmetic, buffering, and decode failures. These were treated
as excluded from selection rather than as independent candidates.

Searched: pulp-platform/iDMA issue tracker and pull requests.
Terms: "valid", "ready", "handshake", "FSM", "error handler".

Found iDMA PR #93: error handler advances FSM state without
checking rsp_ready_i. RTL diff provided clear before/after
mechanism. Not on exclusion list.

**Decision: ACCEPTED — Bug 2.**
Reason: real documented RTL bug, primary fixing diff available,
distinct from excluded examples, directly relevant to Anvil's
timing-safety boundary.

---

## 2026-09-02 — FlooNoC Search and Bug 3

Searched: pulp-platform/FlooNoC repository, releases, commits,
issue and PR history.
Terms: "ROB", "burst", "counter", "offset", "interleave".

Found v0.6.0 release notes describing shared burst-counter fix
in floo_rob. Followed implementation history to commit 1d801a0
where shared rsp_burst_cnt_q and developer WARNING comment
were identifiable. Mechanism concrete enough for standalone
reproducer.

**Decision: ACCEPTED — Bug 3.**
Reason: documented RTL state-management bug, clear mechanism,
distinct from excluded CPU/AXI classes, useful as negative
case for Anvil's guarantee boundary.

Also evaluated FlooNoC PR #65 infrastructure refactoring.

**Decision: REJECTED.**
Reason: concerned synchronization between generated Python/SV
infrastructure, not a sufficiently clear RTL functional or
timing failure. Not a hardware bug class.

---

## 2026-09-03 — OpenTitan keymgr_dpe and CVFPU

Searched: lowrisc/opentitan issue tracker.
Terms: "width", "truncat", "param", "mismatch".

Found Issue #25994 and fixing PR #26055: width mismatch in
keymgr_dpe. Primary issue and fixing diff provided sufficient
mechanism evidence.

**Decision: ACCEPTED — Bug 1.**
Reason: clear parameterization/width failure, documented by
primary sources, distinct from handshake bugs.

Searched: openhwgroup/cvfpu issue tracker and PRs.
Terms: "case", "missing", "operation", "ADDS".

Found PR #122: ADDS operation missing from three case statements
in fpnew_fma.sv and fpnew_fma_multi.sv. Developer's own PR
description confirms the omission.

**Decision: ACCEPTED — Bug 4.**
Reason: clear functional-logic omission, primary fixing diff
available, bug class not otherwise represented.

---

## 2026-09-04 — First Bug 5 Candidate

Searched: pulp-platform/tech_cells_generic releases and source
history for documented RTL fixes.

Found v0.2.13: "tc_sram_xilinx: Fix be assignment."
Evidence: release notes only — no RTL diff available.
Mechanism required inference, not direct evidence.
Also redundant with Bug 1 (same width/assignment class).

**Decision: REJECTED.**
Reason:
1. Insufficient primary-source detail for mechanism extract
2. Mechanism required inference rather than direct evidence
3. Insufficiently distinct from width/parameterization class

---

## 2026-09-05 — Bug 5 Replacement Search

Decided to replace tc_sram_xilinx with a bug that:
(a) has verified RTL diff
(b) is a distinct class
(c) ideally within Anvil's prevention boundary

Searched: lowrisc/opentitan issue tracker.
Terms: "valid", "ready", "backpressure", "handshake", "FIFO".
Scope: peripheral RTL only, not CPU or AXI components.

### Candidate: OpenTitan #23526

Investigated issue #23526: EDN valid/ready protocol violations
during acknowledgment/error conditions. Associated fix PR #15402
was explicitly unmerged — described as a "first hot fix" with
reviewers requesting a more robust solution.

**Decision: REJECTED in favor of #15469.**
Reason: weaker documentation, incomplete fixing path, no clean
merged RTL diff.

### Candidate: OpenTitan #9324

Investigated issue #9324. Issue describes symptom-level behavior
without an identifiable RTL-level mechanism from a primary source.
No fixing commit with RTL diff found.

**Decision: REJECTED.**
Reason: task rule — "Do not infer an undocumented implementation
from symptoms alone." Sourcing rules not satisfied.

### Candidate: OpenTitan #15469

Found issue #15469: EDN back-pressure from CSRNG. Followed
merged fixing PR #15478 and commit 8d42791. Before/after RTL
clearly shows EDN output path could advance while CSRNG was
not ready, overwriting command data before handshake. Fix
introduced output FIFO popping only on valid && ready.

**Decision: ACCEPTED — Bug 5.**
Reason: merged primary fix, precise RTL mechanism, distinct
real-world instance, strong connection to Anvil's blocking
communication semantics.

---

## Excluded Examples from Assignment Section 4

The following bugs appear on the professor's exclusion list.
They were not independently rejected candidates — they were
ineligible by assignment rules from the start. They are listed
here to confirm the exclusion list was read and applied.

| Bug | Class | Status |
|-----|-------|--------|
| OpenTitan #24592 | CDC/Metastability | EXCLUDED |
| OpenTitan #13286 | CDC | EXCLUDED |
| verilog-axi #31 | Deadlock | EXCLUDED |
| pulp-platform/axi #330 | Deadlock | EXCLUDED |
| VHDL 16550 UART #14 | FIFO/Counter | EXCLUDED |
| riscv-formal Divider | Reset/Init | EXCLUDED |
| Ibex #1018 | Incomplete case | EXCLUDED |
| verilog-axi #44 | Width/param | EXCLUDED |
| pulp-platform/axi B/R payload | Handshake | EXCLUDED |
| OpenCores uart16550 tf_push | Shared state | EXCLUDED |

Where permitted by the assignment, some of these are cited
as supporting second instances for a bug class in the report.

---

## Scope Exclusion: iDMA WAIT_LAST_W Fix

PR #93 contains two separate fixes. The Bug 2 reproducer
isolates only the unconditional response-state transition
while rsp_ready_i=0. The WAIT_LAST_W missing eh_valid_i
guard is a separate fault within the same PR — excluded
from scope to keep the reproducer mechanism precise.
Bug 2 itself is accepted.

---

## 2026-09-13 — Bug 3 replacement: common_cells FIFO pointer advancement

The original FlooNoC shared-counter candidate was archived because no
adequately documented second independent instance could be established.
Its files remain in `bugs/archive/bug3_floonoc_counter_shared_state/` for
research record only; it is no longer one of the five selected bugs.

Verified common_cells PR #322 directly on GitHub. The merged PR records
that `passthrough_stream_fifo` pointer updates used `valid_i` or `ready_i`
alone, so a push while full or a pop while empty could corrupt FIFO state
when assertions were disabled or in synthesized netlists. The fix gates
write-pointer movement on `valid_i && ready_o` and read-pointer movement on
`ready_i && valid_o`.

The naming difference was also checked: v1 used
`passthrough_stream_fifo`; the v2 changelog records the public-module
`cc_` prefix and lists `cc_passthrough_stream_fifo` under fixed pointer
updates. The PR preserves simultaneous push/pop when full.

**Decision: ACCEPTED — replacement Bug 3.**
Reason: merged primary fix, exact RTL mechanism, a minimal valid/ready
reproducer, and two independent supporting instances in iDMA PR #93 and
OpenTitan EDN #15469.

---

## Reproducer Summary

Three of the five selected bugs were successfully reproduced
in standalone SystemVerilog simulations.

| Reproducer | Bug | Anvil | Official? |
|------------|-----|-------|-----------|
| iDMA PR #93 | Bug 2 | YES | YES |
| common_cells passthrough FIFO | Bug 3 | PARTIAL | Supporting |
| OpenTitan EDN #15469 | Bug 5 | YES | YES |

Bug 3 now demonstrates that Anvil channel sequencing reduces risk of
handshake-gated FIFO pointer updates but does not prove arbitrary FIFO
bookkeeping correct.

---

## Final Selection

| Bug | Design | Class | Decision |
|-----|--------|-------|----------|
| 1 | OpenTitan keymgr_dpe #25994 | Width/parameterization | ACCEPTED |
| 2 | iDMA PR #93 | Handshake/protocol | ACCEPTED |
| 3 | common_cells PR #322 | Handshake-gated FIFO pointer advancement | ACCEPTED |
| 4 | CVFPU PR #122 | Incomplete case/functional omission | ACCEPTED |
| 5 | OpenTitan EDN #15469 | Handshake/protocol | ACCEPTED |

All five bugs are outside the assignment's exclusion list.
The set covers three distinct bug classes with three independent
instances of the handshake/protocol class. Three reproduced bugs
provide positive and partial-boundary evidence for evaluating Anvil's
timing-safety claims.
