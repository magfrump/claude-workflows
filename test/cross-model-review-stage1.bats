#!/usr/bin/env bats
# @category fast
# shellcheck disable=SC2154  # $stderr is assigned by bats' `run --separate-stderr`
# Unit/e2e coverage for scripts/cross-model-review.py's Stage-1 context path
# (decision 021), added by the 2026-07-31 review (rubric C4): the binary-crash
# class shipped precisely because this surface had zero tests.
#
# Uses a throwaway fixture repo per test run. Nothing here reaches the network:
# every run that could (a key is set, or the no-network claim is under test)
# goes through $HARNESS, which replaces urllib.request.urlopen with a recorder
# that raises, so "pricing fetch failed" is simulated deterministically instead
# of depending on whether the sandbox happens to have egress.

setup_file() {
  # `run --separate-stderr` (stderr-only warning test) needs the 1.5.0 run flags
  bats_require_minimum_version 1.5.0
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export REPO_ROOT
  export SCRIPT="$REPO_ROOT/scripts/cross-model-review.py"
  export FIX="$BATS_FILE_TMPDIR/fixture-repo"
  mkdir -p "$FIX"
  git -C "$FIX" init -q -b main
  git -C "$FIX" config user.email t@t && git -C "$FIX" config user.name t
  echo "base" > "$FIX/a.txt"
  git -C "$FIX" add -A && git -C "$FIX" commit -qm base
  git -C "$FIX" checkout -qb feat
  # sibling commit (context only)
  echo "sibling work" > "$FIX/sibling.txt"
  git -C "$FIX" add -A && git -C "$FIX" commit -qm sibling
  LEFT=$(git -C "$FIX" rev-parse --short HEAD)
  export LEFT
  # reviewed commit: text change + committed binary + oversize file
  echo "changed" >> "$FIX/a.txt"
  head -c 4096 /dev/urandom > "$FIX/blob.bin"
  python3 -c "print('x' * 70000)" > "$FIX/big.txt"
  git -C "$FIX" add -A && git -C "$FIX" commit -qm reviewed
  RIGHT=$(git -C "$FIX" rev-parse --short HEAD)
  export RIGHT

  # Offline harness: runs the script as __main__ with urlopen swapped for a
  # recorder that logs each requested URL to $1 and then raises URLError, as
  # an unreachable host would. The script looks urlopen up on the module at
  # call time (urllib.request.urlopen(...)), so patching the attribute is
  # enough. The log is written in `finally` so sys.exit paths still record.
  # HARNESS_MODELS_JSON, if set, is served as the /models (pricing) response
  # instead, for tests that need a reachable-but-partial price catalog.
  export HARNESS="$BATS_FILE_TMPDIR/offline.py"
  cat > "$HARNESS" <<'PY'
import io, os, runpy, sys, urllib.error, urllib.request
log, script = sys.argv[1], sys.argv[2]
calls = []
canned = os.environ.get("HARNESS_MODELS_JSON")
def recording_urlopen(req, *a, **k):
    url = getattr(req, "full_url", str(req))
    calls.append(url)
    if canned and url.endswith("/models"):
        return io.BytesIO(canned.encode())
    raise urllib.error.URLError("offline test harness: network disabled")
urllib.request.urlopen = recording_urlopen
sys.argv = [script] + sys.argv[3:]
try:
    runpy.run_path(script, run_name="__main__")
finally:
    with open(log, "w") as fh:
        fh.write("".join(c + "\n" for c in calls))
PY
}

run_dry() { # extra args...
  env -u OPENROUTER_API_KEY "$SCRIPT" --repo "$FIX" --range "$LEFT..$RIGHT" \
    --context-base main --out "$BATS_TEST_TMPDIR/out" --dry-run "$@"
}

@test "stage-1 dry-run survives a committed binary file (no UnicodeDecodeError crash)" {
  run run_dry
  [ "$status" -eq 0 ] || { echo "$output" >&2; false; }
  grep -q "binary" "$BATS_TEST_TMPDIR/out/prompt.txt"
}

@test "oversize files are listed under FILES NOT INLINED, not inlined" {
  run run_dry --max-inline-kb 64
  [ "$status" -eq 0 ]
  grep -q "FILES NOT INLINED" "$BATS_TEST_TMPDIR/out/prompt.txt"
  grep -q "big.txt.*over --max-inline-kb" "$BATS_TEST_TMPDIR/out/prompt.txt"
  # no enclosing-file section for the oversize file (its diff hunk may still
  # appear in the UNDER REVIEW section - that's the reviewed change itself)
  ! grep -q "CURRENT FILE CONTENTS - CONTEXT ONLY (big.txt" "$BATS_TEST_TMPDIR/out/prompt.txt"
}

@test "sibling section carries the context-only label and the sibling content" {
  run run_dry
  [ "$status" -eq 0 ]
  grep -q "ALREADY COMMITTED - CONTEXT ONLY, NOT UNDER REVIEW" "$BATS_TEST_TMPDIR/out/prompt.txt"
  grep -q "sibling work" "$BATS_TEST_TMPDIR/out/prompt.txt"
}

@test "section delimiters carry the nonce; unnonced lookalikes are not boundaries" {
  run run_dry
  [ "$status" -eq 0 ]
  # every generated delimiter embeds a 10-hex nonce
  n=$(grep -cE '^=== [0-9a-f]{10} ' "$BATS_TEST_TMPDIR/out/prompt.txt")
  [ "$n" -ge 3 ]
  # no bare legacy delimiter of the stage-1 kinds
  ! grep -qE '^=== (UNDER REVIEW|ALREADY COMMITTED|CURRENT FILE CONTENTS|FILES NOT INLINED)' \
    "$BATS_TEST_TMPDIR/out/prompt.txt"
}

@test "keyless dry-run makes no network calls and prints no bogus \$0.00 projection" {
  # --models is what makes the projection branch reachable at all; without it
  # the pricing/projection block is skipped and this test would assert nothing.
  local urls="$BATS_TEST_TMPDIR/urlopen.log"
  run env -u OPENROUTER_API_KEY python3 "$HARNESS" "$urls" "$SCRIPT" \
    --repo "$FIX" --range "$LEFT..$RIGHT" --context-base main \
    --models fake/model --out "$BATS_TEST_TMPDIR/out-nokey" --dry-run
  [ "$status" -eq 0 ] || { echo "$output" >&2; false; }
  [[ "$output" == *"no pricing available for: fake/model"* ]]
  [[ "$output" != *"projected spend"* ]]
  # The no-network half: with no key, fetch_pricing must not even be tried.
  [ -f "$urls" ]
  [ ! -s "$urls" ] || { echo "unexpected urlopen calls:"; cat "$urls"; false; }
}

@test "a priced catalog lacking the requested model still projects no \$0.00" {
  # The other half of the \$0.00 guard: pricing fetched fine, but this model
  # is not in it. Its (0, 0) default must mark it unpriced, not price it free.
  run env OPENROUTER_API_KEY=sk-or-bogus-offline \
    HARNESS_MODELS_JSON='{"data":[{"id":"other/model","pricing":{"prompt":"0.000001","completion":"0.000002"}}]}' \
    python3 "$HARNESS" "$BATS_TEST_TMPDIR/urlopen.log" "$SCRIPT" \
    --repo "$FIX" --range "$LEFT..$RIGHT" --context-base main \
    --models fake/model --out "$BATS_TEST_TMPDIR/out-partial" --dry-run
  [ "$status" -eq 0 ] || { echo "$output" >&2; false; }
  [[ "$output" == *"no pricing available for: fake/model"* ]]
  [[ "$output" != *"projected spend"* ]]
}

@test "diff-only dry-run prompt is unchanged by the stage-1 additions (prompt sha stable)" {
  run env -u OPENROUTER_API_KEY "$SCRIPT" --repo "$FIX" --range "$LEFT..$RIGHT" \
    --out "$BATS_TEST_TMPDIR/out-do" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"context mode: diff-only"* ]]
  grep -q '^=== DIFF ' "$BATS_TEST_TMPDIR/out-do/prompt.txt"
  ! grep -qE '^=== [0-9a-f]{10} ' "$BATS_TEST_TMPDIR/out-do/prompt.txt"
}

@test "split_range: two-dot, three-dot, and open ranges parse as documented" {
  run python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('cmr', '$SCRIPT')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
assert m.split_range('a..b') == ('a', 'b')
assert m.split_range('a...b') == ('a', 'b')
assert m.split_range('a..') == ('a', 'HEAD')
assert m.split_range('abc123..def456') == ('abc123', 'def456')
print('OK')
"
  [ "$status" -eq 0 ]
  [[ "$output" == *OK* ]]
}

@test "live diff-only run warns on stderr only; stdout status lines stay clean" {
  # Same offline live path as the cost-guard test below: bogus key -> pricing
  # fetch fails -> unpriced -> guard exit, but the diff-only warning must fire
  # first, on stderr.
  run --separate-stderr env OPENROUTER_API_KEY=sk-or-bogus-offline \
    python3 "$HARNESS" "$BATS_TEST_TMPDIR/urlopen.log" "$SCRIPT" --repo "$FIX" \
    --range "$LEFT..$RIGHT" --models fake/model --replicates 1 \
    --out "$BATS_TEST_TMPDIR/out-warn"
  [[ "$stderr" == *"diff-only mode is a recall probe"* ]]
  [[ "$output" != *"recall probe"* ]]
}

@test "dry-run diff-only prints no recall-probe warning (early return precedes it)" {
  run env -u OPENROUTER_API_KEY "$SCRIPT" --repo "$FIX" --range "$LEFT..$RIGHT" \
    --out "$BATS_TEST_TMPDIR/out-warn-dry" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" != *"recall probe"* ]]
}

@test "live --context-base run prints no recall-probe warning" {
  run env OPENROUTER_API_KEY=sk-or-bogus-offline \
    python3 "$HARNESS" "$BATS_TEST_TMPDIR/urlopen.log" "$SCRIPT" --repo "$FIX" \
    --range "$LEFT..$RIGHT" --context-base main --models fake/model --replicates 1 \
    --out "$BATS_TEST_TMPDIR/out-warn-cb"
  # Positive control: the run must reach the cost guard, which sits after the
  # point where the warning would print. Without this, a crash before that
  # point would also "print no warning" and pass.
  [ "$status" -ne 0 ]
  [[ "$output" == *"cost guard cannot price"* ]]
  [[ "$output" != *"recall probe"* ]]
}

@test "aggregate inline budget spills overflow into FILES NOT INLINED" {
  run run_dry --max-total-inline-kb 0
  [ "$status" -eq 0 ]
  grep -q "a.txt.*over --max-total-inline-kb (aggregate)" "$BATS_TEST_TMPDIR/out/prompt.txt"
  ! grep -q "CURRENT FILE CONTENTS - CONTEXT ONLY (a.txt" "$BATS_TEST_TMPDIR/out/prompt.txt"
}

@test "unpriced models fail the cost guard closed (non-dry-run refuses to send)" {
  # No key => would exit earlier for other reasons; instead simulate via a key
  # that cannot fetch pricing (the harness makes urlopen raise) and assert the
  # refusal message appears before any completion call could be attempted.
  # fetch_pricing swallows errors -> {} -> all models unpriced -> sys.exit.
  local urls="$BATS_TEST_TMPDIR/urlopen.log"
  run env OPENROUTER_API_KEY=sk-or-bogus-offline \
    python3 "$HARNESS" "$urls" "$SCRIPT" --repo "$FIX" \
    --range "$LEFT..$RIGHT" --models fake/model --replicates 1 \
    --out "$BATS_TEST_TMPDIR/out-guard"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cost guard cannot price"* ]]
  # "Refuses to send": the pricing fetch is the only request ever attempted —
  # no completion call reached urlopen.
  [ "$(cat "$urls")" = "https://openrouter.ai/api/v1/models" ]
}
