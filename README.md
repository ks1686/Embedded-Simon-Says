# Embedded Simon Says (Zybo-7000)

[![sim](https://github.com/ks1686/Embedded-Simon-Says/actions/workflows/sim.yml/badge.svg)](https://github.com/ks1686/Embedded-Simon-Says/actions/workflows/sim.yml)

VHDL Simon game for the Digilent Zybo Z7 / Zybo-7000. Four PMOD buttons play the sequence; a 7-segment PMOD shows the step, then `n` on a win and `L` on a loss.

## Hardware

| Port | Board pin | Role |
| --- | --- | --- |
| `clk` | `L16` (125 MHz) | System clock |
| `start_btn` | BTN0 `R18` | Start a game (rising edge after debounce) |
| `rst_btn` | BTN1 `P16` | Synchronous reset; rotates the LFSR seed once per press |
| `p_btn[0..3]` | JB `T20 U20 V20 W20` | Color buttons 1–4 |
| `dispSeg[7:0]` | JD + JE | 7-segment + DP (`1` = segment on) |

Constraints: `Zybo_Master.xdc`. Rebuild the bitstream in Vivado; do not commit `*.bit`.

RTL generics (defaults match the board):

- `clk_freq` — ticks per display / win / lose second (125_000_000)
- `debounce_ticks` — stable samples before a press counts (2_500_000 ≈ 20 ms)
- `max_pattern` — longest sequence (15)

Testbenches override these to tiny counts so a full win/lose path finishes in microseconds.

## Simulate

Needs [nvc](https://www.nickg.me.uk/nvc/) 1.16+ (`brew install nvc`) and, for the cross-check, [GHDL](https://github.com/ghdl/ghdl) (`brew install ghdl`):

```bash
bash scripts/sim.sh            # nvc (default)
SIM=ghdl bash scripts/sim.sh   # GHDL cross-check
SIM=all bash scripts/sim.sh    # both
```

That analyzes RTL + `Test/*_tb.vhd` and runs `debounce_tb`, `pulse_detector_tb`, `random_generator_tb`, `simon_game_tb`, and `top_level_tb`. The simulators disagree on some corners of the standard, so passing both is stronger evidence than either alone.

The same commands run on every push and pull request via `.github/workflows/sim.yml`: an `nvc` job (nvc 1.22.1 via `nickg/setup-nvc`) plus a GHDL cross-check job (GHDL v6.0.0, installed straight from the release tarball).
