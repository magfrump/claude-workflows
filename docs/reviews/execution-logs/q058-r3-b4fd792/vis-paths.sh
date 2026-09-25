#!/usr/bin/env bash
# Run the X1-X3 probes (vis-paths.bats.append) appended to a scratch copy of
# b4fd792's test/install-host.bats, against b4fd792's install.sh.
# Hermetic: git-archive copy under $TMPDIR; the suite's setup() pins HOME etc.
set -u
T="$(mktemp -d "${TMPDIR:-/tmp}/vispaths.XXXXXX")"
git -C /workspace archive b4fd792 -- test/install-host.bats devcontainer-config | tar -xf - -C "$T"
cat "$(dirname "$0")/vis-paths.bats.append" >> "$T/test/install-host.bats"
cd "$T" && bats --show-output-of-passing-tests -f '^X[123] ' test/install-host.bats
echo "bats_exit=$?"
rm -rf "$T"
