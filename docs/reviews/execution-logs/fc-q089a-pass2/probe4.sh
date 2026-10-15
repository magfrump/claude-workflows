#!/bin/bash
# shellcheck disable=SC2034  # recorded reviewer probe, kept as run; gate 6 only
set -euo pipefail
host_tool_files() { echo "cc-exit-scan.sh"; echo "cc-gitdir.sh"; echo "cc-push.sh"; }
fail=0
for i in $(seq 1 2000); do host_tool_files | grep -qx cc-exit-scan.sh || fail=$((fail+1)); done
echo "pipeline failures out of 2000: $fail"
