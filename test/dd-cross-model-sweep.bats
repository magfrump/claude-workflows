#!/usr/bin/env bats
# @category fast
# Unit tests for scripts/dd-cross-model-sweep.py: argument/key ordering and the
# exit status when model calls fail. No network: the HTTP call is monkeypatched
# to raise before any request is built into a connection.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/dd-cross-model-sweep.py"
}

@test "bare invocation shows usage even without an API key" {
  run env -u OPENROUTER_API_KEY python3 "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage: dd-cross-model-sweep.py"* ]]
  [[ "$output" != *"OPENROUTER_API_KEY not set"* ]]
}

@test "missing key is still refused once arguments are given" {
  printf 'prompt\n' > "$BATS_TEST_TMPDIR/p.md"
  run env -u OPENROUTER_API_KEY python3 "$SCRIPT" "$BATS_TEST_TMPDIR/p.md" "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"OPENROUTER_API_KEY not set"* ]]
}

@test "exits non-zero when every model call fails" {
  printf 'prompt\n' > "$BATS_TEST_TMPDIR/p.md"
  # urlopen raises (no network) and sleep is a no-op so the retry is instant.
  run env OPENROUTER_API_KEY=sk-or-bogus-offline python3 -c "
import runpy, sys, time, urllib.request
def refuse(*a, **k):
    raise OSError('network disabled in test')
urllib.request.urlopen = refuse
time.sleep = lambda s: None
sys.argv = ['dd-cross-model-sweep.py', '$BATS_TEST_TMPDIR/p.md', '$BATS_TEST_TMPDIR/out']
runpy.run_path('$SCRIPT', run_name='__main__')
"
  [ "$status" -ne 0 ]
  [[ "$output" == *"FAILED after 2 attempts"* ]]
  [[ "$output" == *"3/3 models failed"* ]]
}
