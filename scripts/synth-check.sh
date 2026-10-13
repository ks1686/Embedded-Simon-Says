#!/usr/bin/env bash
# Elaborate top_level with its default (board) generics through GHDL's
# synthesis front end. Fails on constructs GHDL cannot synthesize.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

ghdl -a --std=08 --workdir="$work" \
  debounce.vhd \
  pulse_detector.vhd \
  random_generator.vhd \
  simon_game.vhd \
  top_level.vhd

ghdl --synth --std=08 --workdir="$work" top_level > "$work/top_level_synth.vhd"
echo "synthesis check passed ($(wc -l < "$work/top_level_synth.vhd") netlist lines)"
