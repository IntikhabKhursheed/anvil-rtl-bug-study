// Bug 1: OpenTitan keymgr_dpe width truncation
// Source: Issue #25994, PR #26055
// lowRISC/opentitan
//
// The keymgr_dpe module used a shared AdvDataWidth parameter.
// The standard keymgr uses 1152 bits for its advance data,
// but keymgr_dpe requires 1664 bits due to its DPE slot structure.
// Because both shared the same parameter name, the DPE path
// silently truncated 512 bits of its input data.

// BUGGY — shared parameter, wrong width for DPE:
parameter int AdvDataWidth = 1152; // correct for keymgr, wrong for keymgr_dpe

// Usage in keymgr_dpe:
logic [AdvDataWidth-1:0] adv_data; // silently 1152 bits, should be 1664

// FIXED — separate parameter for DPE:
parameter int KmacAdvDataWidth = 1664; // correct width for keymgr_dpe path
logic [KmacAdvDataWidth-1:0] adv_data;