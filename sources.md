AnvilHDL language reference — https://docs.anvil.kisp-lab.org/languageReference.html
— accessed 2026-09-04. Supports: channel, `send`, `recv`, and sequencing semantics.

AnvilHDL communication guide — https://docs.anvil.kisp-lab.org/communication.html
— accessed 2026-09-04. Supports: timing contracts and static timing-safety claims.


# Sources

One entry per cited source. Role column: P = primary instance,
M = mechanism evidence, S = second independent instance, A = Anvil semantics.

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

Second independent instance (S): OpenTitan EDN #15469 (Bug 5) —
same handshake/protocol class, different design.

---

## Bug 3 — FlooNoC floo_simple_rob shared burst counter

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| FlooNoC v0.6.0 release notes | https://github.com/pulp-platform/FlooNoC/releases/tag/v0.6.0 | v0.6.0 | 2026-09-05 | P |
| FlooNoC commit 1d801a0 | https://github.com/pulp-platform/FlooNoC/tree/1d801a0b92af5fce6e35232d4f03327c91243bf7 | commit 1d801a0 | 2026-09-05 | M |

Note: commit 1d801a0 documents the identical mechanism in floo_simple_rob.sv
including the developer's own WARNING comment and NoBurstSupport assertion.

---

## Bug 4 — CVFPU FMA ADDS incomplete case handling

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| CVFPU PR #122 | https://github.com/openhwgroup/cvfpu/pull/122 | PR #122, merged 2024-05-23 | 2026-09-05 | P, M |

Second independent instance (S): Ibex #1018 (excluded list) —
shift decoder ignored instruction bits, same incomplete case class.

---

## Bug 5 — OpenTitan EDN valid/ready back-pressure violation

| Label | URL | Identifier | Date accessed | Role |
|-------|-----|------------|---------------|------|
| OpenTitan #15469 | https://github.com/lowRISC/opentitan/issues/15469 | Issue #15469 | 2026-09-07 | P |
| OpenTitan PR #15478 | https://github.com/lowRISC/opentitan/pull/15478 | PR #15478, merge commit 8d42791 | 2026-09-07 | M |
| OpenTitan PR #15402 | https://github.com/lowRISC/opentitan/pull/15402 | PR #15402 (unmerged hot-fix) | 2026-09-07 | M |
| AnvilHDL communication guide | https://docs.anvil.kisp-lab.org/communication.html | — | 2026-09-07 | A |

Second independent instance (S): iDMA PR #93 (Bug 2) —
same handshake/protocol class. iDMA retracts valid;
EDN mutates payload — both violate valid/ready stability under back-pressure.

---

## Rejected Candidates — Source Verification

| Candidate | URL | Verified? | Rejection Reason |
|-----------|-----|-----------|-----------------|
| OpenTitan #23526 | https://github.com/lowRISC/opentitan/issues/23526 | ✓ Real | Weaker than #15469, PR #15402 unmerged |
| OpenTitan #9324 | https://github.com/lowRISC/opentitan/issues/9324 | ✓ Real | No RTL mechanism from primary source |
| OpenTitan #24592 | https://github.com/lowRISC/opentitan/issues/24592 | ✓ Real | Exclusion list — CDC |
| OpenTitan #13286 | https://github.com/lowRISC/opentitan/issues/13286 | ✓ Real | Exclusion list — CDC |
| verilog-axi #31 | https://github.com/alexforencich/verilog-axi/issues/31 | ✓ Real | Exclusion list — Deadlock |
| pulp-platform/axi #330 | https://github.com/pulp-platform/axi/issues/330 | ✓ Real | Exclusion list — Deadlock |
| VHDL 16550 UART #14 | https://github.com/openhwgroup/vhdl-uart/issues/14 | ✓ Real | Exclusion list — FIFO |
| LiteX LiteDRAM | LiteX issue tracker | Partial | No stable identifier found |
| tc_sram_xilinx | v0.2.13 release notes | Partial | No RTL diff available |
| common_cells FIFO | pulp-platform/common_cells | ✗ | No specific issue found |
| riscv-formal Divider | riscv-formal repo | ✓ Real | Exclusion list — Reset + CPU |