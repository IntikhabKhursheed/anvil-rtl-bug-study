# OpenTitan keymgr_dpe #25994: Width Truncation via Shared Parameter

**Primary source:** Issue #25994 + PR #26055

## Instance

`keymgr_dpe` is OpenTitan's Dice Protection Environment key manager. It derives and manages cryptographic key material across different DPE contexts. Its advance operation prepares data for cryptographic processing through KMAC.

The bug was caused by using a shared `AdvDataWidth` parameter that was correct for the standard key manager path but too narrow for the DPE path.

## Mechanism

The shared `AdvDataWidth` parameter was set to 1152 bits, while the DPE advance path required 1664 bits because of its additional data. This resulted in a 512-bit width mismatch in the DPE data path.

```systemverilog
// Before — shared parameter
parameter int AdvDataWidth = 1152;
logic [AdvDataWidth-1:0] adv_data;

// After — separate DPE width
parameter int KmacAdvDataWidth = 1664;
logic [KmacAdvDataWidth-1:0] adv_data;
```

When a wider value is assigned to a narrower packed vector, SystemVerilog permits the assignment and truncates the value to the destination width. In this case, the upper 512 bits of the DPE advance data were therefore lost.

## Why It Survived

The width mismatch does not necessarily produce a runtime error. SystemVerilog permits assignments between differently sized packed vectors, so ordinary simulation can continue while the incorrect width remains in the design.

The problem was also specific to the DPE advance path. Tests exercising the standard key manager path could pass without exposing the incorrect DPE width.

## Class

**Width / parameterization**

The violated invariant is that every consumer of a shared parameter must have compatible width requirements. A parameter that is correct for one design path cannot be assumed to be correct for another path with different data requirements.

A related example from the assignment's exclusion list is **verilog-axi #44**, where address-decode logic assumed a minimum address width. It is included only as a supporting example of the same general class, not as one of the five studied bugs.

## Detection

This class is primarily detected using structural checks rather than runtime assertions.

* **Lint:** Width-mismatch checks can identify assignments where source and destination widths differ. Relevant warnings can be treated as errors.
* **Elaboration / compile-time checks:** Parameter constraints can be checked for supported configurations.
* **Formal verification:** Formal analysis can verify selected parameter configurations and detect incorrect behavior resulting from unsupported or inconsistent widths.

An SVA property is not the primary detector because the incorrect width is established structurally during elaboration. An assertion may detect a consequence of the mismatch, but it does not replace structural width checking.

## Anvil

**Anvil does not prevent this bug.**

The failure is a width and parameterization problem rather than a timing-safety problem. Anvil's type system provides guarantees about the timing and ordering of communication, but it does not establish that independently selected parameters produce compatible bit widths across different consumers.

A design expressed in Anvil would therefore still require appropriate structural width checking through linting or elaboration-time checks.
