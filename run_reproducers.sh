#!/usr/bin/env bash
# Runs all reproducers for the Anvil RTL Bug Study.
# A non-zero exit on the BUGGY instance is expected and intentional —
# it confirms the SVA property catches the pre-fix design. See report Section 7.
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: verilator not found. Install Verilator 5.x (needs --binary support), e.g. 'sudo apt install verilator' on Ubuntu/WSL." >&2
  exit 1
fi

echo "=== Reproducer 1: iDMA PR #93 ==="
cd "$ROOT_DIR/bugs/bug2_idma_fsm"
verilator --binary --assert --timing -Wno-fatal -Wno-TIMESCALEMOD \
  idma93_reproducer.sv tb_idma93.sv --top-module tb_idma93
./obj_dir/Vtb_idma93
echo "exit: $?"
echo

echo "=== Reproducer 2: common_cells PR #322 ==="
cd "$ROOT_DIR/bugs/bug3_common_cells_fifo"
verilator --binary --assert --timing -Wno-fatal \
  cc_passthrough_fifo_handshake.sv tb_cc_passthrough_fifo.sv \
  --top-module tb_cc_passthrough_fifo
./obj_dir/Vtb_cc_passthrough_fifo
echo "exit: $?"
echo

echo "=== Reproducer 3: OpenTitan EDN #15469 ==="
cd "$ROOT_DIR/bugs/bug5_opentitan_edn"
verilator --binary --assert --timing -Wno-fatal -Wno-TIMESCALEMOD \
  edn_csrng_if.sv tb_edn_handshake.sv --top-module tb_edn_handshake
./obj_dir/Vtb_edn_handshake
echo "exit: $?"
echo

echo "=== Anvil Verification: Bug 3 Version A (channel-gated pointer) ==="
cd "$ROOT_DIR/bugs/bug3_common_cells_fifo"
verilator --binary --assert --timing -Wno-fatal \
  fifo_push_generated.sv.anvil.sv tb_fifo_push_anvil.sv \
  --top-module tb_fifo_push_anvil
./obj_dir/Vtb_fifo_push_anvil
echo "exit: $?"