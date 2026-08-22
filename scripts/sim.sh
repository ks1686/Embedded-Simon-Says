#!/usr/bin/env bash
# Run assertion testbenches (VHDL-2008).
#
#   bash scripts/sim.sh            # nvc only (default, matches CI)
#   SIM=ghdl bash scripts/sim.sh   # GHDL only
#   SIM=all bash scripts/sim.sh    # both, in sequence
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

workdir="${NVC_WORKDIR:-$root/nvc_work}"
ghdl_work="$root/ghdl_work"
rm -rf "$workdir" "$ghdl_work"
# GHDL needs its workdir to exist up front; nvc creates its own (and must
# not be nested inside another directory, which breaks its library lookup).
mkdir -p "$ghdl_work"

tbs=(debounce_tb pulse_detector_tb random_generator_tb simon_game_tb top_level_tb)

run_nvc() {
  echo "== analyze RTL (nvc) =="
  nvc --std=2008 --work="$workdir" -a \
    debounce.vhd \
    pulse_detector.vhd \
    random_generator.vhd \
    simon_game.vhd \
    top_level.vhd

  echo "== analyze testbenches (nvc) =="
  nvc --std=2008 --work="$workdir" -a \
    Test/debounce_tb.vhd \
    Test/pulse_detector_tb.vhd \
    Test/random_generator_tb.vhd \
    Test/simon_game_tb.vhd \
    Test/top_level_tb.vhd

  for tb in "${tbs[@]}"; do
    echo "== elaborate + run $tb (nvc) =="
    nvc --std=2008 --work="$workdir" -e "$tb"
    nvc --std=2008 --work="$workdir" -r "$tb" --stop-delta=5000
  done
}

run_ghdl() {
  echo "== analyze RTL (ghdl) =="
  ghdl -a --std=08 --workdir="$ghdl_work" \
    debounce.vhd \
    pulse_detector.vhd \
    random_generator.vhd \
    simon_game.vhd \
    top_level.vhd

  echo "== analyze testbenches (ghdl) =="
  ghdl -a --std=08 --workdir="$ghdl_work" \
    Test/debounce_tb.vhd \
    Test/pulse_detector_tb.vhd \
    Test/random_generator_tb.vhd \
    Test/simon_game_tb.vhd \
    Test/top_level_tb.vhd

  for tb in "${tbs[@]}"; do
    echo "== elaborate + run $tb (ghdl) =="
    ghdl -e --std=08 --workdir="$ghdl_work" "$tb"
    ghdl -r --std=08 --workdir="$ghdl_work" "$tb" --stop-time=50us
  done

  # GHDL drops elaboration objects and test executables in the repo root.
  rm -f -- e~*.o "${tbs[@]}"
}

case "${SIM:-nvc}" in
  nvc)  run_nvc ;;
  ghdl) run_ghdl ;;
  all)  run_nvc; run_ghdl ;;
  *) echo "unknown SIM value: $SIM (use nvc | ghdl | all)" >&2; exit 2 ;;
esac

echo "all testbenches passed"
