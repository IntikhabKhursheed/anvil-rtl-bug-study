# FlooNoC `floo_simple_rob`: shared response-burst counter

Minimal reproduction of FlooNoC PR #65, commit `1d801a0`. The pre-fix design
uses one `rsp_burst_cnt_q` for all response IDs. After ID 0's first beat, ID
1's first beat incorrectly adds one to its own ROB base; per-ID counters avoid
that cross-burst interference.

`rsp_beat_i` exists only as a test reference for the SVA; it is not used to
form `rob_addr_o`. The property is deferred until the last beat of ID 1 so the
testbench can display all four interleaved beats before Verilator terminates on
the intentional buggy assertion failure.

```text
verilator --binary --assert --timing -Wno-fatal \
  floo_rob_burst.sv tb_floo_rob.sv --top-module tb_floo_rob
./obj_dir/Vtb_floo_rob
```

Expected address trace:

```text
ID=0 beat=0: buggy=0 fixed=0
ID=1 beat=0: buggy=9 fixed=8
ID=0 beat=1: buggy=2 fixed=1
ID=1 beat=1: buggy=8 fixed=9
```

The buggy run intentionally ends with one SVA error and exit code 1. The
fixed instance satisfies the same property; to run it cleanly, change the
buggy instantiation parameter to `BUGGY(0)` or remove the buggy instance.

## Anvil assessment: outside the guarantee boundary

**Verdict: NO — Anvil does not structurally prevent this bug.**

PR #65 is a functional state-isolation error, not a timing-safety or
communication-synchronisation error. The incorrect pre-fix counter can be
read and updated at valid times, and responses can still be transferred through
correctly synchronised channels. The fault is that the same mutable counter is
used for two logically independent transaction contexts, whereas correctness
requires state indexed by transaction ID.

Anvil's type system checks the lifetimes and stability of values, while its
channel semantics make matching communication events explicit. Neither
guarantee assigns ownership of a register to an ID, proves that every active
ID has isolated state, or verifies the functional arithmetic in
`rob_addr = rob_base + burst_count`. Consequently, a timing-safe Anvil design
could still declare one counter and reuse it for all incoming IDs.

This bug identifies an important boundary of the timing-safety
property Anvil demonstrates: explicit timing
contracts can prevent timing hazards, but they do not by themselves prove
protocol-level, per-transaction functional invariants. The appropriate defence
is an SVA or formal property that relates each response ID to its own stored
burst count, plus review of state indexing. The assertion in
`floo_rob_burst.sv` is a reduced simulation check of that invariant.

> FlooNoC PR #65 lies outside Anvil's guarantee boundary. A single
> burst-progress counter is shared across independently interleaved transaction
> IDs, although each ID requires separate progress state. Anvil can ensure that
> values and channel communications are timing-safe, but it does not enforce
> per-ID resource ownership or functional arithmetic correctness. This class is
> best addressed with SVA or formal verification of ID-indexed state.

Anvil semantics reference: [AnvilHDL communication guide](https://docs.anvil.kisp-lab.org/communication.html), accessed 2026-09-05.
