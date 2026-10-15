#!/usr/bin/env bash
# $1 = probe root. Tampered scan: --help, a usage error, --list, --register, --probe-only.
set -u
P="${1:?probe root}"; [ -d "$P/q4/cfg" ] || { echo "run probe.sh first"; exit 99; }
export HOME="$P/home" TMPDIR="$P/tmp" LC_ALL=C CLAUDE_DEVC_CONFIG_DIR="$P/q4/cfg"
PATH="$P/stub/bin:$PATH"; D="$CLAUDE_DEVC_CONFIG_DIR"
echo '# t2' >> "$D/cc-exit-scan.sh"
for a in "--help" "--bogus" "--profile" "--list" "--register $P/q4/ws" "--probe-only $P/q4/ws" "$P/q4/ws"; do
  # shellcheck disable=SC2086
  out="$(timeout 30 bash "$D/cc-isolated.sh" $a 2>&1)"; rc=$?
  echo "[$a] rc=$rc first: $(printf '%s\n' "$out" | head -1)"
done
