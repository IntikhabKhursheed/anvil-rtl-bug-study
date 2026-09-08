# CVFPU PR #122: ADDS operation missing from FMA case statements

Primary source: PR #122, merged 2024-05-23
https://github.com/openhwgroup/cvfpu/pull/122

## Instance

CVFPU (FPnew) is a parametric floating-point unit used in
PULP-platform processors and CVA6. It supports standard RISC-V
FP operations plus transprecision extensions. PR #114 added
a new symmetric add operation (ADDS) for same-source-format
addition. PR #122 is the bug fix for what PR #114 missed.

## Mechanism

PR #114 added `fpnew_pkg::ADDS` to the operation enum but
failed to add it to three case statements in the FMA units:

1. `fpnew_fma.sv` — operand default assignment case
2. `fpnew_fma_multi.sv` — same operand case
3. `fpnew_fma_multi.sv` — addend exponent rebias used
   `dst_fmt_i` instead of `src_fmt_i` for ADDS

When ADDS was requested, all three fell through to `default`,
producing zero operands or wrong format extraction.
The developer confirmed this in the PR description:
"I'd like to apologize... I overlooked three things."

```systemverilog
// BUGGY — ADDS falls through to default:
case (op_i)
  fpnew_pkg::ADD:  begin ... end
  fpnew_pkg::MUL:  begin ... end
  // fpnew_pkg::ADDS missing
  default: begin op_a = '0; op_b = '0; op_c = '0; end
endcase

// FIXED:
case (op_i)
  fpnew_pkg::ADD:  begin ... end
  fpnew_pkg::MUL:  begin ... end
  fpnew_pkg::ADDS: begin ... end  // added
  default: begin op_a = '0; op_b = '0; op_c = '0; end
endcase
```

## Why it survived

ADDS was a new operation added in the same release cycle.
Regression tests cover existing operations. ADDS-specific
tests were not yet in the test suite. The case omission
produces no compiler error — `default` silently handles
the unmatched case. Lint tools can flag incomplete case
coverage with `unique case` but this was not enforced.

## Class

**Incomplete case / functional logic** — a new enumeration
value added to a type was not propagated to all case
statements consuming that type. The invariant violated:
every valid value of an operation enum must be handled
explicitly in every case statement that dispatches on it.

Second independent instance: Ibex #1018 (exclusion list) —
shift decoder ignored instruction bits 25-26, so reserved
encodings executed instead of trapping. Same class: a
valid input encoding silently fell through to wrong behavior.

## Detection

```systemverilog
// Use unique case to force coverage:
unique case (op_i)
  fpnew_pkg::FMADD: ...
  fpnew_pkg::ADDS:  ...
  // Simulator warns if any value reaches no branch
endcase

// SVA — no operation should produce all-zero operands
// unless explicitly a zero operation:
assert property (@(posedge clk)
    in_valid_i |-> !(op_a == '0 && op_b == '0 && op_c == '0
                     && op_i == fpnew_pkg::ADDS))
else $error("ADDS produced zero operands — case missing");
```

Cost: `unique case` causes simulation errors on unknown
values, may need waivers for X-propagation scenarios.

## Anvil

Anvil does not prevent this bug. It is a functional logic
error — a missing case in an operation dispatch. Anvil's
type system enforces timing safety but does not verify
that every enum value is handled in every case statement.
This class requires `unique case` lint enforcement or
formal case-coverage analysis.