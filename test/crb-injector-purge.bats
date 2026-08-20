#!/usr/bin/env bats
# @category fast
# Guards purge_stale_judge_entries in scripts/crb-pipeline-to-benchmark.py.
#
# Why this exists: the benchmark's steps 2/2.5/3 are all skip-if-present, keyed
# on (PR url, tool). When a run cell is re-run and its review re-injected, judge
# state from the PREVIOUS review therefore survives every re-run of judge.sh and
# is reported as the new review's score. Observed 2026-08-20: the voided
# keycloak-PR36880 cell's wrong-ref review (a Dependabot CI diff) stayed in
# evaluations.json as five false positives after the cell was cleared and re-run
# against the real PR. The injector already replaces the old review entry in
# benchmark_data.json; purge_stale_judge_entries extends the same invalidation
# to candidates.json, dedup_groups.json, and evaluations.json.
#
# Hermetic: module loaded by path, fixtures in $BATS_TEST_TMPDIR, no network.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export SCRIPT="$REPO_ROOT/scripts/crb-pipeline-to-benchmark.py"
}

setup() {
  export JDIR="$BATS_TEST_TMPDIR/judge"
  mkdir -p "$JDIR"
}

# Run purge_stale_judge_entries against $JDIR and print its return value.
# $1 = python list literal of urls, $2 = tool name.
purge() {
  python3 - "$SCRIPT" "$JDIR" "$1" "$2" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("inj", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
print(m.purge_stale_judge_entries(Path(sys.argv[2]), eval(sys.argv[3]), sys.argv[4]))
PY
}

write_fixture() {  # one file, two PRs, our tool plus a bystander tool
  python3 - "$JDIR/$1" <<'PY'
import json, sys
json.dump({
    "https://example.com/pr/1": {"ours": ["stale"], "other-tool": ["keep"]},
    "https://example.com/pr/2": {"ours": ["stale-but-not-reinjected"]},
}, open(sys.argv[1], "w"))
PY
}

@test "purge drops only the injected (PR, tool) pairs, in every judge file" {
  for f in candidates.json dedup_groups.json evaluations.json; do
    write_fixture "$f"
  done
  run purge "['https://example.com/pr/1']" ours
  [ "$status" -eq 0 ]
  [ "$output" = "{'candidates.json': 1, 'dedup_groups.json': 1, 'evaluations.json': 1}" ]
  for f in candidates.json dedup_groups.json evaluations.json; do
    run python3 -c "
import json; d = json.load(open('$JDIR/$f'))
assert 'ours' not in d['https://example.com/pr/1'], 'stale entry survived'
assert d['https://example.com/pr/1']['other-tool'] == ['keep'], 'bystander tool touched'
assert d['https://example.com/pr/2']['ours'], 'non-injected PR touched'
print('ok')"
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
  done
}

@test "missing judge files and absent entries are a no-op, not an error" {
  # No files at all.
  run purge "['https://example.com/pr/1']" ours
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
  # File present but tool absent for the url: file must not be rewritten.
  write_fixture evaluations.json
  before=$(python3 -c "print(open('$JDIR/evaluations.json').read())")
  run purge "['https://example.com/pr/1']" never-ran-tool
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
  after=$(python3 -c "print(open('$JDIR/evaluations.json').read())")
  [ "$before" = "$after" ]
}

@test "main() wires the purge after seeding (call-order smoke check)" {
  # The call must appear in main(), after the seed block and before the runbook
  # is written — a purge that runs before seeding misses a freshly-seeded file.
  python3 - "$SCRIPT" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
main_body = src[src.index("def main():"):]
seed = main_body.index('shutil.copy2(s, jdir / name)')
purge = main_body.index("purge_stale_judge_entries(jdir, injected_urls, args.tool_name)")
runbook = main_body.index('runbook = f"""')
assert seed < purge < runbook, (seed, purge, runbook)
PY
}
