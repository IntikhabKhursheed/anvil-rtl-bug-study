// Bug 4: CVFPU FMA ADDS incomplete case handling
// Source: PR #122, merged 2024-05-23
// openhwgroup/cvfpu
// Developer quote: "I'd like to apologize, when submitting PR #114
// adding the new symmetric add operation ADDS, I overlooked three things"

// fpnew_fma.sv — BUGGY case statement (before PR #122):
case (op_i)
  fpnew_pkg::FMADD:  begin op_a = ...; op_b = ...; op_c = ...; end
  fpnew_pkg::FNMSUB: begin op_a = ...; op_b = ...; op_c = ...; end
  fpnew_pkg::ADD:    begin op_a = ...; op_b = ...; op_c = ...; end
  fpnew_pkg::MUL:    begin op_a = ...; op_b = ...; op_c = ...; end
  // ADDS missing — uses default (garbage) operand values
  default: begin op_a = '0; op_b = '0; op_c = '0; end
endcase

// fpnew_fma.sv — FIXED (after PR #122):
case (op_i)
  fpnew_pkg::FMADD:  begin op_a = ...; op_b = ...; op_c = ...; end
  fpnew_pkg::FNMSUB: begin op_a = ...; op_b = ...; op_c = ...; end
  fpnew_pkg::ADD:    begin op_a = ...; op_b = ...; op_c = ...; end
  fpnew_pkg::MUL:    begin op_a = ...; op_b = ...; op_c = ...; end
  fpnew_pkg::ADDS:   begin op_a = ...; op_b = ...; op_c = ...; end // ADDED
  default: begin op_a = '0; op_b = '0; op_c = '0; end
endcase

// Additionally in fpnew_fma_multi.sv — same case missing ADDS
// Plus: addend exponent rebias and local operand format extraction
// both used dst_fmt_i instead of src_fmt_i for ADDS operation