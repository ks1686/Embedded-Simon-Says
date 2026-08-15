#!/usr/bin/env bash
# Run assertion testbenches with nvc (VHDL-2008).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

workdir="${NVC_WORKDIR:-$root/nvc_work}"
rm -rf "$workdir"

nvc=(nvc --std=2008 --work="$workdir")

echo "== analyze RTL =="
"${nvc[@]}" -a \
  debounce.vhd \
  pulse_detector.vhd \
  random_generator.vhd \
  simon_game.vhd \
  top_level.vhd

echo "== analyze testbenches =="
"${nvc[@]}" -a \
  Test/debounce_tb.vhd \
  Test/pulse_detector_tb.vhd \
  Test/random_generator_tb.vhd \
  Test/top_level_tb.vhd

tbs=(debounce_tb pulse_detector_tb random_generator_tb top_level_tb)
for tb in "${tbs[@]}"; do
  echo "== elaborate + run $tb =="
  "${nvc[@]}" -e "$tb"
  "${nvc[@]}" -r "$tb" --stop-delta=5000
done

echo "all testbenches passed"
