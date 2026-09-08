# Search Log

Searches conducted, candidates evaluated, and decisions made.
Rejected candidates are included — they document the judgement
behind the five bugs that were kept.

---

## Week 1 — Initial search and Bug 2 lock

**2026-09-01**
- Read exclusion list in full before searching.
  Observation: AXI handshake bugs, CPU pipeline bugs, and
  CDC bugs are heavily represented. Looked for fresher material
  in DMA engines, NoCs, FPUs, and crypto peripherals.

- Searched: pulp-platform/iDMA issue tracker, label:bug,
  terms: "valid", "ready", "handshake", "FSM".
  Found PR #93: error handler advances FSM state without
  checking rsp_ready_i. RTL mechanism clear from diff.
  Not on exclusion list. ACCEPTED as Bug 2.

- Searched: pulp-platform/axi, lowrisc/opentitan peripheral IPs.
  Most AXI bugs on exclusion list. OpenTitan CDC bugs also excluded.

---

## Week 1 — Bug 3 search

**2026-09-02**
- Searched: pulp-platform/FlooNoC issue tracker and releases.
  Found v0.6.0 release notes mentioning shared burst counter in floo_rob.
  Found commit 1d801a0 confirming identical mechanism in floo_simple_rob.sv
  with developer WARNING comment and NoBurstSupport assertion.

- Evaluated FlooNoC PR #65 infrastructure refactoring:
  REJECTED. This was a Python/SV code generation sync issue,
  not an RTL logic bug. No RTL-level mechanism identifiable.
  Switching language tooling is not a hardware bug class.

- floo_simple_rob shared counter: RTL mechanism clear,
  primary source verified, non-CPU non-AXI. ACCEPTED as Bug 3.

---

## Week 1 — Bugs 1 and 4

**2026-09-03**
- Searched: lowrisc/opentitan issue tracker, label:bug,
  terms: "width", "truncat", "param".
  Found Issue #25994: keymgr_dpe width truncation,
  fixed in PR #26055. RTL mechanism documented in diff.
  Non-AXI crypto peripheral. ACCEPTED as Bug 1.

- Searched: openhwgroup/cvfpu issue tracker and PRs,
  terms: "case", "missing", "operation".
  Found PR #122: ADDS operation missing from three case
  statements in fpnew_fma.sv and fpnew_fma_multi.sv.
  Developer's own PR description confirms the omission.
  ACCEPTED as Bug 4.

---

## Week 1 — Original Bug 5 (later replaced)

**2026-09-04**
- Searched: pulp-platform/tech_cells_generic releases.
  Found v0.2.13: "tc_sram_xilinx: Fix be assignment."
  Source: release notes only — no RTL diff available.
  Mechanism inferred, not documented.
  Also: same width/assignment class as Bug 1 — redundant.
  REJECTED and set aside.

---

## Week 2 — Bug 5 replacement search

**2026-09-05**
- Decided to replace tc_sram_xilinx with a bug that:
  (a) has verified RTL diff, (b) is a distinct class,
  (c) ideally within Anvil's prevention boundary.

- Searched: lowrisc/opentitan issue tracker, label:bug,
  component:RTL, terms: "valid", "ready", "backpressure",
  "handshake", peripheral IPs only (not CPU, not AXI).

- Evaluated OpenTitan #23526:
  "[edn] valid/ready protocol violations in case of ack errors"
  Related PR unmerged (#15402 only partial fix).
  REJECTED in favor of stronger candidate.

- Found OpenTitan #15469:
  "[edn] EDN doesn't support backpressure from CSRNG"
  Issue labeled Type:Bug, Component:RTL, IP:edn.
  Fix PR #15478 merged, commit 8d42791 confirmed.
  RTL diff shows exact assign lines changed.
  Output FIFO introduced — mechanism fully documented.
  Non-CPU crypto peripheral. Anvil-preventable.
  ACCEPTED as Bug 5.

---

## Reproducer decisions

**2026-09-04 to 2026-09-07**

- Built reproducer for Bug 2 (iDMA) — ACCEPTED as Reproducer 1.
  Anvil-positive. Back-pressure differential test passes.

- Built reproducer for Bug 3 (FlooNoC) — kept in repo as backup.
  Anvil-negative. Strong mechanism but not ideal for
  Anvil comparison story.

- Built reproducer for Bug 5 (EDN) — ACCEPTED as Reproducer 2.
  Anvil-positive. Matches iDMA class — two independent
  designs, same handshake violation.

Final two official reproducers: Bug 2 (iDMA) + Bug 5 (EDN).
Both are Anvil-preventable. Bug 3 retained in repo as
supporting evidence.

## Reproducer Summary

Three standalone reproducers were built during the study.
The assignment requires at minimum two.

| Reproducer | Bug | Anvil | Official? |
|------------|-----|-------|-----------|
| iDMA #93 | Bug 2 | YES | YES |
| FlooNoC floo_simple_rob | Bug 3 | NO | Supporting evidence |
| OpenTitan EDN #15469 | Bug 5 | YES | YES |

FlooNoC reproducer was not rejected — Bug 3 is one of
the five accepted bugs. The reproducer is retained as
additional evidence demonstrating Anvil's limit boundary.

## Rejected Candidates — With Verified Reasons

### Rejected 1: OpenTitan #23526
URL: https://github.com/lowRISC/opentitan/issues/23526
Class: Handshake/Protocol
Reason: Related to same EDN valid/ready violation as #15469
but with weaker documentation. The associated fix PR #15402
was explicitly unmerged — described as a "first hot fix"
with reviewers asking for a more robust solution.
#15469 with merged PR #15478 had a cleaner paper trail
and exact RTL diff. #23526 set aside in favor of #15469.

### Rejected 2: OpenTitan #9324
URL: https://github.com/lowRISC/opentitan/issues/9324
Class: Handshake/Protocol
Reason: Issue describes symptom-level behavior without
an identifiable RTL-level mechanism from a primary source.
Task rule: "Do not infer an undocumented implementation
from symptoms alone." No fixing commit with RTL diff found.
Rejected on sourcing rules.

### Rejected 3: OpenTitan #24592
URL: https://github.com/lowRISC/opentitan/issues/24592
Class: CDC / Metastability
Reason: CONFIRMED ON EXCLUSION LIST — Section 4,
"Clock domain crossing and metastability."
Issue verified as real: combinational logic inside
prim_subreg_shadow drives a CDC flop directly;
transient glitch latched as spurious fatal alert.
Cannot use as primary bug per assignment rules.
Retained as supporting second instance for CDC class
if needed.

### Rejected 4: OpenTitan #13286
URL: https://github.com/lowRISC/opentitan/issues/13286
Class: CDC
Reason: CONFIRMED ON EXCLUSION LIST — Section 4,
"Clock domain crossing and metastability."
Data from system clock domain sampled in SPI domain
with no synchronizer. Cannot use as primary bug.

### Rejected 5: verilog-axi #31
URL: https://github.com/alexforencich/verilog-axi/issues/31
Class: Deadlock
Reason: CONFIRMED ON EXCLUSION LIST — Section 4,
"Deadlock, livelock, and starvation."
Issue verified as real: AXI interconnect stops accepting
requests under concurrent writes from two masters, CPU hangs.
Cannot use as primary bug per assignment rules.

### Rejected 6: pulp-platform/axi #330
URL: https://github.com/pulp-platform/axi/issues/330
Class: Deadlock
Reason: CONFIRMED ON EXCLUSION LIST — Section 4,
"Deadlock, livelock, and starvation."
Spill registers between demux and mux create circular
dependency in W-channel FIFOs. Cannot use as primary bug.
Retained as second instance for deadlock class.

### Rejected 7: VHDL 16550 UART #14
URL: https://github.com/openhwgroup/vhdl-uart/issues/14
Class: FIFO/Counter
Reason: CONFIRMED ON EXCLUSION LIST — Section 4,
"Buffering, FIFOs, and flow control."
RX FIFO counter bug; THRE bit never set.
Cannot use as primary bug per assignment rules.

### Rejected 8: LiteX LiteDRAM — Frontend FIFO Stall
Source: LiteX issue tracker
Class: FIFO/Flow Control
Reason: Could not locate a specific issue with a clear
RTL mechanism. The Section 4 reference was too vague
to trace to a primary source. Rejected on sourcing rules:
"If you cannot point at a record of it, choose a different one."

### Rejected 9: tc_sram_xilinx — Byte-enable Width Mismatch
Source: pulp-platform/tech_cells_generic v0.2.13 release notes
Class: Width/Assignment
Reason: Source is release notes only — no RTL diff available.
Mechanism had to be inferred, not demonstrated from primary
RTL evidence. Also redundant with Bug 1 (same width class).
Rejected on both sourcing rules and class diversity grounds.

### Rejected 10: common_cells FIFO Overflow
Source: pulp-platform/common_cells
Class: FIFO
Reason: Could not find a specific issue with a clear RTL
mechanism in the common_cells tracker. No stable identifier
available. Rejected on sourcing rules.

### Rejected 11: riscv-formal Divider — Reset State Not Cleared
Source: riscv-formal repository
Class: Reset/Initialization
Reason: CONFIRMED ON EXCLUSION LIST — Section 4,
"Reset and initialisation." Also a CPU core component —
double exclusion. Cannot use as primary bug.

### Scope Exclusion: iDMA WAIT_LAST_W Fix
Source: Same PR #93 as Bug 2
Class: Handshake/Protocol
Reason: PR #93 contains two separate fixes. The selected
Bug 2 reproducer isolates only the unconditional
response-state transition while rsp_ready_i=0.
The WAIT_LAST_W missing eh_valid_i guard is a separate
fault within the same PR — excluded from scope to keep
the reproducer mechanism precise. Not a rejected candidate;
Bug 2 itself is accepted.