#!/usr/bin/env bats
# @category fast
# Unit tests for scripts/hermeticity-lint — the polyglot hermeticity detector.
#
# These anchor the heuristics to known ground truth so a regression fails loudly
# instead of making the lint vacuously green. Fixtures are synthetic repos built
# in BATS_TEST_TMPDIR; nothing here touches the real tree or the network.
#
# Fixture lines are written with printf so that binary names never appear in
# command position in THIS file's own source — otherwise the bash adapter would
# (correctly) flag this suite.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LINT="$REPO_ROOT/scripts/hermeticity-lint"
  ADAPTERS="$REPO_ROOT/scripts/hermeticity/adapters"
  FAKE="$BATS_TEST_TMPDIR/fake"
  mkdir -p "$FAKE/test" "$FAKE/scripts/lib" "$FAKE/hooks"
}

lint() {
  "$LINT" --root "$FAKE" --adapters "$ADAPTERS" "$@"
}

# --- bash: the ported rule ------------------------------------------------

@test "bash: flags an unstubbed direct invocation" {
  local fx="$FAKE/test/direct.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "calls out" {\n' >> "$fx"
  printf '  run claude -p "hello"\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`claude\`"* ]]
}

@test "bash: ignores binary names in comments and echo strings" {
  local fx="$FAKE/test/prose.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '# curl and wget and gh and claude discussed in a comment\n' >> "$fx"
  printf '@test "prose only" {\n' >> "$fx"
  printf '  echo "ask claude to curl the wget gh page"\n' >> "$fx"
  printf '  WORKFLOW_DIR="$HOME/.claude/workflows"\n' >> "$fx"
  printf '  [ -n "$WORKFLOW_DIR" ]\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 0 ]
}

@test "bash: accepts the PATH-shim stub" {
  local fx="$FAKE/test/stubbed.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'setup() {\n' >> "$fx"
  printf '  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"\n' >> "$fx"
  printf '  printf "exit 0" > "$BATS_TEST_TMPDIR/stub-bin/gh"\n' >> "$fx"
  printf '  chmod +x "$BATS_TEST_TMPDIR/stub-bin/gh"\n' >> "$fx"
  printf '  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"\n' >> "$fx"
  printf '}\n' >> "$fx"
  printf '@test "gh is stubbed" {\n' >> "$fx"
  printf '  run gh pr list\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 0 ]
}

@test "bash: accepts an opt-out that carries a reason" {
  local fx="$FAKE/test/optout.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '# @network: allowed — exercises the real gh CLI against a fixture remote\n' >> "$fx"
  printf '@test "real gh" {\n' >> "$fx"
  printf '  run gh --version\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 0 ]
}

@test "bash: rejects a bare opt-out with no reason" {
  # 014's whole lesson is that silent, unjustified escapes are the failure mode.
  local fx="$FAKE/test/bare.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '# @network: allowed\n' >> "$fx"
  printf '@test "real gh" {\n' >> "$fx"
  printf '  run gh --version\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
}

@test "bash: follows call sites transitively through sourced repo scripts" {
  # This is the 4d39475 shape: the suite's own text holds no call site.
  printf 'source "$(dirname "$0")/lib/inner.sh"\n' > "$FAKE/scripts/outer.sh"
  printf 'fetch() {\n  curl https://example.com\n}\n' > "$FAKE/scripts/lib/inner.sh"

  local fx="$FAKE/test/indirect.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'setup() {\n  source "$BATS_TEST_DIRNAME/../scripts/outer.sh"\n}\n' >> "$fx"
  printf '@test "indirect" {\n  fetch\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
  [[ "$output" == *"inner.sh"* ]]
}

@test "bash: follows a bats \`load\` into a shared helper under test/lib" {
  # The 4d39475 shape again, through the helper directory this repo actually
  # uses. The closure once searched only scripts/ and hooks/, so a suite that
  # reached a network binary through test/lib/ was reported clean — and the
  # helper carries no .sh suffix, so the reference pattern has to match the
  # extensionless `load` target too.
  mkdir -p "$FAKE/test/lib"
  printf 'fetch() {\n  curl https://example.com\n}\n' > "$FAKE/test/lib/net-helper.bash"

  local fx="$FAKE/test/via-helper.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'load lib/net-helper\n' >> "$fx"
  printf '@test "indirect" {\n  fetch\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
  [[ "$output" == *"net-helper.bash"* ]]
}

@test "bash: follows a load from a nested suite dir (../lib/…)" {
  mkdir -p "$FAKE/test/lib" "$FAKE/test/hooks"
  printf 'fetch() {\n  wget https://example.com\n}\n' > "$FAKE/test/lib/net-helper.bash"

  local fx="$FAKE/test/hooks/nested.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'load ../lib/net-helper\n' >> "$fx"
  printf '@test "indirect" {\n  fetch\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`wget\`"* ]]
}

@test "bash: resolves a load relative to the loading suite, not a listed dir" {
  # `load helpers` means helpers.bash NEXT TO THE SUITE — that is what bats does.
  # Resolving by basename against a hand-listed set of search dirs meant every
  # helper directory had to be enumerated, and the one that wasn't (test/skills/,
  # loaded by 20 suites) was a hole the gate could not see through at all.
  mkdir -p "$FAKE/test/skills"
  printf 'fetch() {\n  curl https://example.com\n}\n' > "$FAKE/test/skills/helpers.bash"

  local fx="$FAKE/test/skills/leak.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'load helpers\n' >> "$fx"
  printf '@test "indirect" {\n  fetch\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
  [[ "$output" == *"test/skills/helpers.bash"* ]]
}

@test "bash: follows a script that is assigned to a variable and run later" {
  # The house style: SCRIPT="$REPO_ROOT/scripts/x.sh" … run bash "$SCRIPT".
  # The reference is the assignment; command position alone would miss it.
  printf 'fetch() {\n  gh pr list\n}\n' > "$FAKE/scripts/tool.sh"

  local fx="$FAKE/test/assigned.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'SCRIPT="$BATS_TEST_DIRNAME/../scripts/tool.sh"\n' >> "$fx"
  printf '@test "runs it" {\n  run bash "$SCRIPT"\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`gh\`"* ]]
}

@test "bash: follows a script EXECUTED in command position" {
  printf 'wget https://example.com\n' > "$FAKE/scripts/fetcher.sh"

  local fx="$FAKE/test/executed.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "runs it" {\n  run bash "$BATS_TEST_DIRNAME/../scripts/fetcher.sh"\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`wget\`"* ]]
}

@test "bash: does NOT follow a script that is only named in a message" {
  # A filename inside a skip/echo/grep argument is a MENTION, not a reach. The
  # repo's eval suites say `skip "…run generate-reports.bash first"` about a
  # generator they never invoke; following that flagged four honest suites whose
  # only way to green would have been a blanket opt-out they do not deserve.
  printf 'gen() {\n  claude -p "make a report"\n}\n' > "$FAKE/scripts/generator.sh"

  local fx="$FAKE/test/mention.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "reads a pre-made report" {\n' >> "$fx"
  printf '  [ -f "$BATS_TEST_TMPDIR/report" ] || skip "no report — run generator.sh first"\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 0 ]
}

@test "bash: sees the binary behind a wrapper (if / timeout / env)" {
  # `if curl …`, `timeout 5 wget …` and `env FOO=1 gh …` all put the binary in
  # command position behind a wrapper word. A matcher that reads only the first
  # token of the line misses every one of them.
  local fx="$FAKE/test/wrapped.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "a" {\n  if curl -sf https://example.com; then true; fi\n}\n' >> "$fx"
  printf '@test "b" {\n  run timeout 5 wget https://example.com\n}\n' >> "$fx"
  # `gh` is a printf ARG: inside `$( … )` it would be in command position in
  # THIS file's own source, and the bash adapter would rightly flag this suite.
  printf '@test "c" {\n  out="$(env FOO=1 %s pr list)"\n}\n' gh >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
  [[ "$output" == *"can spawn \`wget\`"* ]]
  [[ "$output" == *"can spawn \`gh\`"* ]]
}

@test "bash: sees the binary behind bats' \`run !\` negative assertion" {
  # This repo made `run !` its house idiom (63 assertions across 13 suites), so a
  # matcher blind to it would be blind to the very shape it asks people to write.
  local fx="$FAKE/test/negated.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'bats_require_minimum_version 1.5.0\n' >> "$fx"
  printf '@test "fails offline" {\n  run ! claude -p hello\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`claude\`"* ]]
}

@test "bash: follows a script run behind \`run !\` (the house idiom)" {
  # The closure and the matcher must share ONE notion of command position. They
  # did not: `run bash x.sh` entered the reach and `run ! bash x.sh` did not —
  # blind exactly when the test uses the idiom this repo standardised on.
  printf 'claude -p "hi"\n' > "$FAKE/scripts/danger.sh"

  local fx="$FAKE/test/negated-script.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'bats_require_minimum_version 1.5.0\n' >> "$fx"
  printf '@test "asserts it fails" {\n' >> "$fx"
  printf '  run ! bash "$BATS_TEST_DIRNAME/../scripts/danger.sh"\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`claude\`"* ]]
  [[ "$output" == *"danger.sh"* ]]
}

@test "bash: resolves an extension-less load whose path is built from a variable" {
  mkdir -p "$FAKE/test/lib" "$FAKE/test/hooks"
  printf 'fetch() {\n  claude -p "hi"\n}\n' > "$FAKE/test/lib/shared.bash"

  local fx="$FAKE/test/hooks/varload.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'load "$BATS_TEST_DIRNAME/../lib/shared"\n' >> "$fx"
  printf '@test "indirect" {\n  fetch\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`claude\`"* ]]
}

@test "bash: sees a binary inside a \`bash -c\` string" {
  # The shell twin of Python's shell=True, which the spawn matcher already claims.
  local fx="$FAKE/test/dashc.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "compound" {\n' >> "$fx"
  printf '  run bash -c "%s -s https://example.com | head -1"\n' curl >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "bash: a binary named in a trailing comment is not a call site" {
  # A `(` inside a trailing comment once put the next word in command position.
  # The false NETWORKED then pushed the author toward a blanket opt-out — the
  # silent escape hatch 014 exists to close — over a COMMENT.
  local fx="$FAKE/test/comment.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "no network" {\n' >> "$fx"
  printf '  run echo hi   # we avoid the network (curl would need egress)\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 0 ]
}

@test "bash: the matcher does not backtrack exponentially on flag runs" {
  # The old wrapper-chain regex nested two ambiguous quantifiers: 22 --k=v flags
  # after a wrapper word took 1.7s, ~30 hung the CI gate outright with no output.
  local fx="$FAKE/test/flags.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "many flags" {\n' >> "$fx"
  printf '  run env' >> "$fx"
  local i
  for i in $(seq 1 40); do printf ' --opt%s=v%s' "$i" "$i" >> "$fx"; done
  printf ' somecmd\n}\n' >> "$fx"

  # A hang is the failure mode, so bound it: this must finish in well under 10s.
  run timeout 10 "$LINT" --root "$FAKE" --adapters "$ADAPTERS" --lang bash
  [ "$status" -ne 124 ]
  [ "$status" -eq 0 ]
}

@test "bash: a stub merely DEFINED in a helper does not stub anything" {
  # The fail-open that the stub-scan widening introduced: `stub_claude()` sitting
  # unused in a shared helper marked EVERY suite that loaded that helper as
  # stubbed for claude — including ones that really do spawn it.
  mkdir -p "$FAKE/test/lib"
  printf 'claude -p "hi"\n' > "$FAKE/scripts/danger.sh"
  printf 'stub_claude() {\n' > "$FAKE/test/lib/stubs.bash"
  printf '  mkdir -p "$BATS_TEST_TMPDIR/bin"\n' >> "$FAKE/test/lib/stubs.bash"
  printf '  printf "exit 0" > "$BATS_TEST_TMPDIR/bin/claude"\n' >> "$FAKE/test/lib/stubs.bash"
  printf '  chmod +x "$BATS_TEST_TMPDIR/bin/claude"\n' >> "$FAKE/test/lib/stubs.bash"
  printf '  PATH="$BATS_TEST_TMPDIR/bin:$PATH"\n' >> "$FAKE/test/lib/stubs.bash"
  printf '}\n' >> "$FAKE/test/lib/stubs.bash"

  local fx="$FAKE/test/never-stubs.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'load lib/stubs\n' >> "$fx"
  printf '@test "never calls the stub helper" {\n' >> "$fx"
  printf '  run bash "$BATS_TEST_DIRNAME/../scripts/danger.sh"\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`claude\`"* ]]
}

@test "bash: a PATH tweak in a sourced PRODUCT script is not a test stub" {
  # An un-normalized `test/../scripts/tool.sh` still looks like it lives under
  # test/ to a lexical path check, which let a product script's PATH line be read
  # as a test stub.
  printf 'PATH="/opt/tools/bin:$PATH"\n' > "$FAKE/scripts/tool.sh"
  printf 'curl https://example.com\n' >> "$FAKE/scripts/tool.sh"

  local fx="$FAKE/test/product.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'setup() {\n  source "$BATS_TEST_DIRNAME/../scripts/tool.sh"\n}\n' >> "$fx"
  printf '@test "uses the tool" {\n' >> "$fx"
  printf '  printf "exit 0" > "$BATS_TEST_TMPDIR/curl"\n' >> "$fx"
  printf '}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "bash: a stub in a loaded test helper counts as a stub" {
  # Factoring the PATH shim into the shared helper dir must not turn a properly
  # stubbed suite red — the cheapest way back to green would be a file-wide
  # opt-out, which is 014's silent escape hatch reintroduced by the back door.
  mkdir -p "$FAKE/test/lib"
  printf 'stub_bins() {\n' > "$FAKE/test/lib/stub-bins.bash"
  printf '  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"\n' >> "$FAKE/test/lib/stub-bins.bash"
  printf '  printf "exit 0" > "$BATS_TEST_TMPDIR/stub-bin/gh"\n' >> "$FAKE/test/lib/stub-bins.bash"
  printf '  chmod +x "$BATS_TEST_TMPDIR/stub-bin/gh"\n' >> "$FAKE/test/lib/stub-bins.bash"
  printf '  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"\n' >> "$FAKE/test/lib/stub-bins.bash"
  printf '}\n' >> "$FAKE/test/lib/stub-bins.bash"

  local fx="$FAKE/test/shared-stub.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'load lib/stub-bins\n' >> "$fx"
  printf 'setup() {\n  stub_bins\n}\n' >> "$fx"
  printf '@test "gh is stubbed in the helper" {\n  run gh pr list\n}\n' >> "$fx"

  run lint --lang bash
  [ "$status" -eq 0 ]
}

# --- python: the second adapter (proves the contract generalizes) ----------

@test "python: flags a subprocess spawn of a network binary" {
  local fx="$FAKE/test/test_reach.py"
  printf 'import subprocess\n' > "$fx"
  printf 'def test_fetch():\n' >> "$fx"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "python: flags a multi-line spawn call" {
  # The proximity matcher walks to the matching close paren, so a call split
  # across lines is still one window. A line-based grep would miss this.
  local fx="$FAKE/test/test_multiline.py"
  printf 'import subprocess\n' > "$fx"
  printf 'def test_fetch():\n' >> "$fx"
  printf '    subprocess.run(\n' >> "$fx"
  printf '        [\n' >> "$fx"
  printf '            "gh",\n' >> "$fx"
  printf '            "pr", "list",\n' >> "$fx"
  printf '        ],\n' >> "$fx"
  printf '        check=True,\n' >> "$fx"
  printf '    )\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`gh\`"* ]]
}

@test "python: ignores binary names in prose and unrelated strings" {
  local fx="$FAKE/test/test_prose.py"
  printf '# curl and gh and claude in a comment\n' > "$fx"
  printf 'def test_prose():\n' >> "$fx"
  printf '    msg = "ask claude to curl the gh page"\n' >> "$fx"
  printf '    assert msg\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 0 ]
}

@test "python: follows the reach transitively through a local import" {
  # The Python-shaped 4d39475: the test imports a helper that shells out.
  # The import is NOT on line 1 — deliberately. The reference pattern is
  # `^`-anchored, and a resolver that forgets re.MULTILINE follows only a
  # first-line import, which silently reduces the closure to nothing. Every
  # real test file has a docstring or an `import pytest` above its local ones.
  printf 'import subprocess\n' > "$FAKE/test/helper.py"
  printf 'def fetch():\n' >> "$FAKE/test/helper.py"
  printf '    return subprocess.run(["curl", "https://example.com"])\n' >> "$FAKE/test/helper.py"

  local fx="$FAKE/test/test_indirect.py"
  printf '"""A module docstring, as every real test file has."""\n' > "$fx"
  printf 'import os\n' >> "$fx"
  printf 'from helper import fetch\n' >> "$fx"
  printf 'def test_indirect():\n' >> "$fx"
  printf '    fetch()\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
  [[ "$output" == *"helper.py"* ]]
}

@test "python: sees a spawn whose argument string carries an unbalanced paren" {
  # The call window is found by walking to the matching close paren. A walk that
  # counts parens inside string literals closes the window at the `)` in `:-)`
  # and never reaches `curl` — a false pass on the shell=True shape the matcher
  # explicitly claims to catch.
  # The binary name is a printf ARGUMENT, not part of the format string: a
  # literal `; curl` in this file's own source would be a call site in command
  # position, and the bash adapter would (correctly) flag this very suite.
  local fx="$FAKE/test/test_smiley.py"
  printf 'import subprocess\n' > "$fx"
  printf 'def test_shell():\n' >> "$fx"
  printf '    subprocess.run(["bash", "-c", "echo :-) ; %s https://example.com"])\n' curl >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "python: accepts a PATH shim only when a stub for the binary is created" {
  # The bash rule demands two co-occurring facts (a file named after the binary,
  # and a PATH prepend). Python's must too — see the negative case below.
  local fx="$FAKE/test/test_shim.py"
  printf 'import subprocess\n' > "$fx"
  printf 'def test_fetch(monkeypatch, tmp_path):\n' >> "$fx"
  printf '    stub = tmp_path / "curl"\n' >> "$fx"
  printf '    stub.write_text("exit 0")\n' >> "$fx"
  printf '    stub.chmod(0o755)\n' >> "$fx"
  printf '    monkeypatch.setenv("PATH", f"{tmp_path}:{os.environ[chr(80)]}")\n' >> "$fx"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 0 ]
}

@test "python: a bare read of os.environ[PATH] is not a stub" {
  # `env = dict(PATH=os.environ["PATH"])` is how a subprocess env is normally
  # built — it stubs nothing. Treating it as a stub marked EVERY binary in the
  # file stubbed and greenlit a suite that really does spawn curl.
  local fx="$FAKE/test/test_readpath.py"
  printf 'import os\n' > "$fx"
  printf 'import subprocess\n' >> "$fx"
  printf 'def test_fetch():\n' >> "$fx"
  printf '    env = dict(PATH=os.environ["PATH"])\n' >> "$fx"
  printf '    subprocess.run(["curl", "https://example.com"], env=env)\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "python: accepts a patched subprocess" {
  local fx="$FAKE/test/test_patched.py"
  printf 'import subprocess\n' > "$fx"
  printf 'from unittest import mock\n' >> "$fx"
  printf 'def test_fetch():\n' >> "$fx"
  printf '    with mock.patch("subprocess.run") as m:\n' >> "$fx"
  printf '        subprocess.run(["curl", "https://example.com"])\n' >> "$fx"
  printf '    assert m.called\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 0 ]
}

@test "python: patching something merely NAMED like subprocess is not a stub" {
  # The rule once fired on any patch() whose arguments contained the substring
  # `subprocess`, so patching an unrelated module marked the whole file stubbed
  # for every binary — the same fail-open shape as the os.environ[PATH] read.
  local fx="$FAKE/test/test_lookalike.py"
  printf 'import subprocess\n' > "$fx"
  printf 'from unittest import mock\n' >> "$fx"
  printf 'def test_a():\n' >> "$fx"
  printf '    mock.patch("app.subprocess_helper.run")\n' >> "$fx"
  printf 'def test_b():\n' >> "$fx"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "python: follows \`from pkg import mod\` into pkg/mod.py" {
  # The dominant local-import shape. Capturing only the first dotted name
  # followed pkg/__init__.py — usually empty — and never the module that
  # actually holds the spawn.
  mkdir -p "$FAKE/helpers"
  printf '' > "$FAKE/helpers/__init__.py"
  printf 'import subprocess\n' > "$FAKE/helpers/netutil.py"
  printf 'def fetch():\n' >> "$FAKE/helpers/netutil.py"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$FAKE/helpers/netutil.py"

  local fx="$FAKE/test/test_pkg.py"
  printf 'from helpers import netutil\n' > "$fx"
  printf 'def test_pkg():\n' >> "$fx"
  printf '    netutil.fetch()\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
  [[ "$output" == *"helpers/netutil.py"* ]]
}

@test "python: follows an explicit relative import (\`from . import helper\`)" {
  printf 'import subprocess\n' > "$FAKE/test/sibling.py"
  printf 'def fetch():\n' >> "$FAKE/test/sibling.py"
  printf '    subprocess.run(["wget", "https://example.com"])\n' >> "$FAKE/test/sibling.py"

  local fx="$FAKE/test/test_rel.py"
  printf 'from . import sibling\n' > "$fx"
  printf 'def test_rel():\n' >> "$fx"
  printf '    sibling.fetch()\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`wget\`"* ]]
}

@test "python: honours the LEVEL of a relative import (\`from ..mod import x\`)" {
  # Stripping every leading dot and always resolving against the importing file's
  # own dir sent a parent-package import looking in the wrong directory, and the
  # helper holding the spawn fell out of the closure.
  mkdir -p "$FAKE/tests/unit"
  printf 'import subprocess\n' > "$FAKE/tests/runner.py"
  printf 'def go():\n' >> "$FAKE/tests/runner.py"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$FAKE/tests/runner.py"

  local fx="$FAKE/tests/unit/test_up.py"
  printf 'from ..runner import go\n' > "$fx"
  printf 'def test_up():\n' >> "$fx"
  printf '    go()\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
  [[ "$output" == *"tests/runner.py"* ]]
}

@test "python: follows a parenthesized, multi-line import list" {
  # What black and ruff produce. The names group captured just "(" before, so
  # every imported submodule was invisible and only the empty __init__ was read.
  mkdir -p "$FAKE/pkg"
  printf '' > "$FAKE/pkg/__init__.py"
  printf 'def a():\n    pass\n' > "$FAKE/pkg/mod_a.py"
  printf 'import subprocess\n' > "$FAKE/pkg/mod_b.py"
  printf 'def b():\n' >> "$FAKE/pkg/mod_b.py"
  printf '    subprocess.run(["wget", "https://example.com"])\n' >> "$FAKE/pkg/mod_b.py"

  local fx="$FAKE/test/test_parens.py"
  printf 'from pkg import (\n' > "$fx"
  printf '    mod_a,\n' >> "$fx"
  printf '    mod_b,\n' >> "$fx"
  printf ')\n' >> "$fx"
  printf 'def test_p():\n' >> "$fx"
  printf '    mod_b.b()\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`wget\`"* ]]
  [[ "$output" == *"pkg/mod_b.py"* ]]
}

@test "python: follows every module of a multi-module \`import a, b\`" {
  mkdir -p "$FAKE/pkg2"
  printf '' > "$FAKE/pkg2/__init__.py"
  printf 'def a():\n    pass\n' > "$FAKE/pkg2/first.py"
  printf 'import subprocess\n' > "$FAKE/pkg2/second.py"
  printf 'def s():\n' >> "$FAKE/pkg2/second.py"
  printf '    subprocess.run(["gh", "pr", "list"])\n' >> "$FAKE/pkg2/second.py"

  local fx="$FAKE/test/test_multi.py"
  printf 'import pkg2.first, pkg2.second\n' > "$fx"
  printf 'def test_m():\n' >> "$fx"
  printf '    pkg2.second.s()\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`gh\`"* ]]
  [[ "$output" == *"pkg2/second.py"* ]]
}

@test "python: an unbalanced paren in a TRAILING comment does not hide the spawn" {
  # _strip_comments only blanks FULL-line comments, so a trailing one survives
  # into the call window and its `)` would close the walk early.
  local fx="$FAKE/test/test_trailing.py"
  printf 'import subprocess\n' > "$fx"
  printf 'def test_c():\n' >> "$fx"
  printf '    subprocess.run(  # spawn a fetcher :)\n' >> "$fx"
  printf '        ["curl", "https://example.com"],\n' >> "$fx"
  printf '    )\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "python: honors the file-level pytestmark as an opt-out" {
  # Decision 017: honor ecosystem-native markers rather than inventing syntax.
  # `pytestmark` is genuinely file-scoped, so reading it file-wide is honest.
  local fx="$FAKE/test/test_marked.py"
  printf 'import pytest\n' > "$fx"
  printf 'import subprocess\n' >> "$fx"
  printf 'pytestmark = pytest.mark.network\n' >> "$fx"
  printf 'def test_fetch():\n' >> "$fx"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 0 ]
}

@test "python: a per-test @pytest.mark.network does not exempt the whole file" {
  # opted_out() is file-scoped. Honouring a decorator that marks ONE test would
  # let a single legitimately-networked integration test at the top of a module
  # silently exempt every other test in it — including ones added later. That is
  # 014's failure mode (the silent escape hatch), so it is not accepted.
  local fx="$FAKE/test/test_decorated.py"
  printf 'import pytest\n' > "$fx"
  printf 'import subprocess\n' >> "$fx"
  printf '@pytest.mark.network\n' >> "$fx"
  printf 'def test_intentionally_online():\n' >> "$fx"
  printf '    pass\n' >> "$fx"
  printf 'def test_added_months_later():\n' >> "$fx"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$fx"

  run lint --lang python
  [ "$status" -eq 1 ]
  [[ "$output" == *"can spawn \`curl\`"* ]]
}

@test "python: a root-level .venv is excluded, not linted" {
  # `uv venv` puts the venv at the repo root. fnmatch's `**` needs a preceding
  # `/`, so `**/.venv/**` missed it — and the gate then failed on vendored
  # third-party test files the user cannot fix.
  mkdir -p "$FAKE/.venv/lib/pkg/tests"
  printf 'import subprocess\n' > "$FAKE/.venv/lib/pkg/tests/vendored_test.py"
  printf 'def test_vendored():\n' >> "$FAKE/.venv/lib/pkg/tests/vendored_test.py"
  printf '    subprocess.run(["curl", "https://example.com"])\n' >> "$FAKE/.venv/lib/pkg/tests/vendored_test.py"

  printf 'def test_ok():\n    assert True\n' > "$FAKE/test/test_ours.py"

  run lint --lang python
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 test file(s) checked"* ]]
}

# --- gradual adoption (H4) -------------------------------------------------

@test "a language with no test files is reported UNCHECKED, never a silent pass" {
  # Gradual adoption is only safe if the gaps are visible. An empty language
  # must say so on stderr rather than quietly contributing a green tick.
  run lint --lang python
  [ "$status" -eq 0 ]
  [[ "$output" == *"UNCHECKED"* ]]
}

# --- real-tree anchors -----------------------------------------------------
#
# Everything above runs against synthetic fixtures, which a heuristic regression
# can satisfy while seeing nothing in the actual repo: move a script, and the
# closure resolves to nothing, the lint prints "N files checked, no unstubbed
# network spawns", exit 0 — vacuously green, and the 4d39475 incident runs again
# inside `run-tests.sh --all`. These anchor the detector to ground truth in THIS
# tree so that regression fails loudly instead. (They replace the two anchors
# that the port to hermeticity-lint dropped.)

#
# The assertions match a SINGLE LINE of --closure output, with grep. A bash glob
# like *"self-improvement"*"spawns:"*"claude"* spans newlines, so it is satisfied
# when some OTHER closure member reports the spawn: the anchor would stay green
# after the detector went blind to the very file it names. (si-morning-summary.sh
# is also in this closure and also spawns claude, so that was not hypothetical.)

@test "anchor: the closure of round-log-functions.bats reaches self-improvement.sh" {
  run "$LINT" --root "$REPO_ROOT" --closure test/round-log-functions.bats
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^scripts/self-improvement\.sh( |$)'
}

@test "anchor: self-improvement.sh itself is still seen as a claude call site" {
  # The live `claude -p` behind commit 4d39475 lives there. If the matcher stops
  # seeing it, the detector is blind to the incident it was written for. The
  # `spawns:` annotation must be on THAT file's line, not merely somewhere below.
  run "$LINT" --root "$REPO_ROOT" --closure test/round-log-functions.bats
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^scripts/self-improvement\.sh[[:space:]]+spawns:.*claude'
}

@test "anchor: si-morning-summary.sh is still seen as a claude call site" {
  # The second of the two call sites the deleted real-tree anchors pinned.
  run "$LINT" --root "$REPO_ROOT" --closure test/round-log-functions.bats
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^scripts/lib/si-morning-summary\.sh[[:space:]]+spawns:.*claude'
}

@test "anchor: round-log-functions.bats's stub is recognized, so the tree is green" {
  # That suite reaches a real `claude` call site (asserted above) and is still
  # clean — which is only true because its PATH-shim stub is recognized. If the
  # stub rule regresses, this repo's own gate goes red; if the reach regresses,
  # the anchor above goes red. Together they pin both halves of the rule.
  run "$LINT" --root "$REPO_ROOT" --lang bash
  [ "$status" -eq 0 ]
}
