#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/butc-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/butc-cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/butc-data}"
godot --headless --editor --quit > evidence/import.log 2>&1
if rg 'SCRIPT ERROR|Parse Error|ERROR:' evidence/import.log; then exit 1; fi
godot --headless --script res://tests/smoke.gd > evidence/smoke.log 2>&1
cat evidence/smoke.log
if rg 'FAIL|SCRIPT ERROR|ERROR:' evidence/smoke.log; then exit 1; fi
