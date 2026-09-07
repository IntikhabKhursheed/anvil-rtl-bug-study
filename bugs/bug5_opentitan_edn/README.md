# OpenTitan EDN #15469: valid/ready back-pressure violation

EDN sends RES/GEN command words to CSRNG. In [issue #15469](https://github.com/lowRISC/opentitan/issues/15469), CSRNG back-pressure caused EDN to advance through a multiword command without waiting for acceptance, dropping words and leaving both blocks waiting forever. The primary fix is [PR #15478](https://github.com/lowRISC/opentitan/pull/15478), merged as `8d42791caf287191c0f5ee1d8a48165d982edcc0`; [PR #15402](https://github.com/lowRISC/opentitan/pull/15402) records the earlier hot-fix investigation.

Before the fix, `edn_core.sv` drove the CSRNG output directly from its advancing command registers:

```systemverilog
assign csrng_cmd_o.csrng_req_valid = cs_cmd_req_vld_out_q;
assign csrng_cmd_o.csrng_req_bus   = cs_cmd_req_out_q;
```

When `csrng_req_ready` was low, EDN still updated `cs_cmd_req_out_q`. Thus `csrng_req_valid` remained asserted but the offered payload changed before CSRNG accepted it. Issue #15469 reports that the missing words left CSRNG in `SendMOP` and EDN waiting for the final ACK.

| Cycle | Offered word | `ready` | Buggy bus | Fixed bus |
| --- | --- | ---: | --- | --- |
| 1 | `0xDEAD_BEEF` | 1 | `0x00000000` | `0xDEAD_BEEF` |
| 2 | `0xCAFE_BABE` | 0 | `0xDEAD_BEEF` | `0xCAFE_BABE` |
| 3 | `0x1234_5678` | 0 | `0xCAFE_BABE` | `0xCAFE_BABE` |

PR #15478 inserted a synchronous output FIFO. Its head now drives CSRNG, and it pops only when CSRNG is ready:

```systemverilog
assign csrng_cmd_o.csrng_req_valid = sfifo_output_not_empty;
assign csrng_cmd_o.csrng_req_bus   = sfifo_output_rdata;
assign sfifo_output_push  = cs_cmd_req_vld_out_q;
assign sfifo_output_wdata = cs_cmd_req_out_q;
assign sfifo_output_pop   = sfifo_output_not_empty &&
                            csrng_cmd_i.csrng_req_ready;
```

```text
verilator --binary --assert --timing -Wno-fatal \
  edn_csrng_if.sv tb_edn_handshake.sv --top-module tb_edn_handshake
./obj_dir/Vtb_edn_handshake
```

Expected output:

```text
Cycle 1 | word=0xdeadbeef ready=1 buggy=0x00000000 fixed=0xdeadbeef
Cycle 2 | word=0xcafebabe ready=0 buggy=0xdeadbeef fixed=0xcafebabe
Cycle 3 | word=0x12345678 ready=0 buggy=0xcafebabe fixed=0xcafebabe
[55000] %Error: ... EDN changed or withdrew request under back-pressure
```

The assertion error is intentional. Verilator stops on the buggy instance and returns exit code 1; that is evidence that the negative test caught the pre-fix mechanism, not a clean regression result. The fixed instance satisfies the same property.

## Anvil assessment: within the guarantee boundary

**Verdict: YES. Anvil structurally prevents this bug.**

`edn_csrng.anvil` models the EDN to CSRNG path as a normal synchronous Anvil channel. `send cmd_ep.request(...)` completes only when CSRNG executes the matching `recv`. Because `set next_word := ...` is sequenced after `send` with `>>`, it cannot start while CSRNG is back-pressuring the current word. The source word therefore cannot be advanced or overwritten before that communication completes.

| Aspect | SystemVerilog buggy | Anvil |
| --- | --- | --- |
| Handshake enforcement | EDN must explicitly test `csrng_req_ready` | A normal `send` waits for the matching `recv` |
| Bus stability | An advancing register can replace an unaccepted payload | The next state update starts only after `send` completes |
| Bug possible? | Yes, if source progress ignores `ready` | Not in the sequenced `send >> advance` encoding |

This does not prove the full EDN or CSRNG protocol. FIFO sizing, command contents, and end-to-end progress still need design review and SVA or formal checks. The guarantee is narrower and direct: a normal Anvil channel cannot complete a send, then advance its source state, before the receiver has accepted that send. See the [AnvilHDL language reference](https://docs.anvil.kisp-lab.org/languageReference.html) and [communication guide](https://docs.anvil.kisp-lab.org/communication.html), accessed 2026-09-07.

## Second independent instance: iDMA PR #93

iDMA [PR #93](https://github.com/pulp-platform/iDMA/pull/93) is an independent instance of the same back-pressure class. Its FSM retracted `rsp_valid_o` before `rsp_ready_i`; EDN kept `valid` asserted but mutated the request payload before `ready`. Both violate the rule that an offered transaction must remain available and stable until its valid/ready handshake completes.

> EDN #15469 mutates an unaccepted payload; iDMA #93 retracts an unaccepted response. A blocking Anvil channel prevents either behavior when source progress is sequenced after `send`.
