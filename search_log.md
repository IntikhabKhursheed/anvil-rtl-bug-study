2026-09-04 — Confirmed iDMA #93 is merged PR #93 (not a standalone issue).
The PR body and diff document an unconditional response-state transition while
`rsp_ready_i=0`; retained as a candidate. The PR also fixes a separate missing
`eh_valid_i` guard in `WAIT_LAST_W`, which is not part of this reproducer.
