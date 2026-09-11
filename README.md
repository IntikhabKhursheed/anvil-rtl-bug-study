Anvil RTL Bug Study

A research study of five real, documented SystemVerilog RTL bugs
from open-source hardware repositories. Each bug is analysed at
the RTL level, reduced to a minimal mechanism extract, and
evaluated against Anvil's timing-safety guarantees.

## Structure

bugs/
├── bug1_opentitan_width/ — width/parameterization
├── bug2_idma_fsm/ — handshake/protocol (Reproducer 1)
├── bug3_floonoc_counter/ — shared state/per-ID isolation
├── bug4_cvfpu_case/ — incomplete case/functional omission
└── bug5_opentitan_edn/ — handshake/protocol (Reproducer 2)
notes/
├── anvil_boundary.md — Anvil guarantee analysis
└── class_map.md — bug class taxonomy
search_log.md — search methodology and decisions
sources.md — all cited sources


## Reproducers

Three standalone SystemVerilog reproducers were built.
Two are official; one provides supporting evidence.

| Bug | Design | Anvil | Role |
|-----|--------|-------|------|
| Bug 2 | iDMA PR #93 | YES | Official |
| Bug 3 | FlooNoC floo_simple_rob | NO | Supporting |
| Bug 5 | OpenTitan EDN #15469 | YES | Official |

## Key finding

Anvil's timing-safety guarantee is narrow but deep. It prevents
the specific valid/ready stability violations demonstrated by
Bugs 2 and 5 when the communication is expressed through Anvil
channels. Bugs 1, 3, and 4 fall outside this boundary —
their failures concern parameterization, per-transaction state
ownership, and functional completeness respectively.