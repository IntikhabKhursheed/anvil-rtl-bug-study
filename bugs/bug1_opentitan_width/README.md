# OpenTitan keymgr_dpe #25994: width truncation via shared parameter

Primary source: Issue #25994 + PR #26055
https://github.com/lowRISC/opentitan/issues/25994

## Instance

keymgr_dpe is OpenTitan's Dice Protection Environment key manager.
It derives and manages cryptographic keys across multiple boot stages
using a slot-based architecture. Its advance operation sends key
material to KMAC for mixing.

## Mechanism

The keymgr and keymgr_dpe modules shared a single `AdvDataWidth`
parameter set to 1152 bits — the correct width for the standard
keymgr advance path. The DPE path requires 1664 bits to accommodate
its additional slot data. Because both modules used the same parameter,
the DPE advance data was silently truncated by 512 bits before
reaching KMAC. No error was raised; SystemVerilog silently
zero-extends or truncates on width mismatch.

```systemverilog
// Pre-fix — shared parameter, wrong for DPE:
parameter int AdvDataWidth = 1152;
logic [AdvDataWidth-1:0] adv_data; // 512 bits missing

// Fix — separate parameter:
parameter int KmacAdvDataWidth = 1664;
logic [KmacAdvDataWidth-1:0] adv_data;
```

## Why it survived

Width truncation in SystemVerilog is silent by default. The
simulator does not raise an error when a wider signal is assigned
to a narrower one — it simply drops the upper bits. Lint tools
report `-Wwidth` warnings but these are frequently suppressed in
large codebases. The truncation only affects the DPE path, which
has different test coverage than the standard keymgr path.

## Class

**Width/parameterization** — a shared parameter assumes a fixed
data width that is incorrect for one consumer. The invariant
violated: every module consuming a shared parameter must be
verified to have compatible width requirements.

Second independent instance: verilog-axi #44 (exclusion list) —
AXI-lite crossbar fails for M_ADDR_WIDTH below 12; address-decode
logic assumed a minimum width.

## Detection

SVA is not the primary detection mechanism for this class.

This class is better detected through **width-consistency linting and elaboration/compile-time checks**. The incorrect width is structural and is established when the design is elaborated.

A runtime SVA is not the primary detection mechanism because the failure is a **static width mismatch**, rather than a temporal behavior that occurs at runtime.

**Lint:** Enable width-mismatch checks (for example, `-Wwidth` where supported) and treat relevant warnings as errors. Cost: false positives for intentional truncations; requires waiver discipline.

**Formal:** Formal verification can additionally check supported parameter configurations and verify that the resulting interface behavior remains correct, but it is not the primary mechanism for detecting the width mismatch itself.

## Anvil

Anvil does not prevent this bug. Width parameters are a
structural/elaboration-time property. Anvil's type system
enforces timing safety — that values are stable when read —
but it does not verify that a parameter used across modules
produces compatible bit widths. A designer using Anvil would
still need to specify correct widths manually.