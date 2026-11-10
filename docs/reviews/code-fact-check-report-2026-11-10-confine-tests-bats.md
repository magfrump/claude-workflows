Commit: 9d37c1ac

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-2026-11-10-confine-tests-bats`)
**Scope:** branch `test/confine-tests-bats`, `git diff a37733cc...HEAD` (`docs/working/research-2026-11-10-confine-tests-bats.md`, `test/scripts/confine-tests.bats`) plus the commit messages of a59eb11f and 9d37c1ac; claims checked against the unchanged `scripts/confine-tests.sh` (read in full, 1-227) and the cited docs
**Checked:** 2026-11-10
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 50 (numbered 1-47, with 23, 27 and 46 split into a/b)
**Summary:** 43 verified, 6 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution provenance. Every `executed` claim ran in the sandbox on 2026-11-10 between 19:35Z and 19:42Z. Captured output lives in the scratch directory, because this run may write only this file in the repo: `L=/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-bats/fc1/logs`. The files are:

- `$L/bats-run.txt`: `timeout 300 bats test/scripts/confine-tests.bats`, cwd the worktree, exit 0, 17/17 ok, Bats 1.8.2, 19:35:34Z.
- `$L/probe.txt`: `timeout 60 scripts/confine-tests.sh --probe`, cwd the worktree, exit 3.
- `$L/d1-repro.txt`: D1 reproduction. Two extra tests were appended to a scratch copy (`fc1/d1/`) of the test file, one with `$TOOLS/sh` relinked to bash and one with dash. Bats exit 0, both run.
- `$L/mutations.txt` and `$L/diff-M*.txt`: 22 mutants of a scratch copy of the script (`fc1/m/`), each run through the unchanged test file, 19:36Z to 19:38:37Z. Each line gives the mutant, the bats exit code and the failing test numbers.
- `$L/env-facts.txt`: wc and test counts, tool locations, dash/bash versions, `unshare -rn true`, and the no-argument exit code (19:41:45Z).
- `$L/hermeticity-lint.txt`: `timeout 300 scripts/hermeticity-lint --root .`, cwd the worktree, exit 0.
- `$L/bats-failing-output.txt`: what bats 1.8.2 prints for a failing test, exit 1.

Hallucination log: I read `docs/reviews/hallucination-patterns.md` first. The closest logged patterns are the miscounted test totals (commits 59ca38f and 37c5ea9), so I re-counted every count claim here. None matches a logged pattern. There are no Incorrect verdicts, so the log needs no new entry.

---

## Claim 1: "`scripts/confine-tests.sh` (227 lines, bash, `set -euo pipefail`)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count, the shebang and the shell options of the unchanged script; does not establish anything about behaviour.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:1` is `#!/usr/bin/env bash` and `scripts/confine-tests.sh:47` is `set -euo pipefail`. Running `wc -l` gives `227 scripts/confine-tests.sh` (in `$L/env-facts.txt`, exit 0, cwd the worktree, 19:41:45Z).

**Evidence:** `scripts/confine-tests.sh:1`, `scripts/confine-tests.sh:47`, `$L/env-facts.txt`

---

## Claim 2: "Flags (lines 53-71): `--probe`, `--no-loopback`, `--` ..., `-h`/`--help` (prints the header comment with `awk`, exit 0). Anything else: `unknown flag`, usage line, exit 2. This runs before any primitive is tried."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parse loop and its position before `detect_primitive`; does not establish the exact header text `awk` prints (that is pinned by test 6, Claim 33).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:53-71 (excerpt; whole loop read)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --probe)       probe_only=1; shift ;;
    --no-loopback) loopback=0; shift ;;
    --)            shift; cmd=("$@"); break ;;
    -h|--help)
      awk 'NR==1{next} /^#/{sub(/^# ?/,"");print;next} {exit}' "$0"
      exit 0
      ;;
    *)
      echo "confine-tests: unknown flag: $1" >&2
      echo "Usage: $0 [--no-loopback] -- <test command...>" >&2
      exit 2
```

Detection is first called at `scripts/confine-tests.sh:115`, after the loop ends at `:71`.

**Evidence:** `scripts/confine-tests.sh:53-71`, `scripts/confine-tests.sh:115`

---

## Claim 3: "Detection (79-118): `bwrap --ro-bind / / --unshare-net -- true`, then `unshare -rn true`; the first that exits 0 wins. Neither: a long message on stderr starting `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`, exit 3, for a probe and for a run alike."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `detect_primitive`, `explain_unavailable` and the call site; does not establish real-kernel behaviour of either primitive.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:80-81, 85-86, 115-118
  if command -v bwrap >/dev/null 2>&1 &&
     bwrap --ro-bind / / --unshare-net -- true >/dev/null 2>&1; then
  if command -v unshare >/dev/null 2>&1 &&
     unshare -rn true >/dev/null 2>&1; then
if ! primitive="$(detect_primitive)"; then
  explain_unavailable
  exit 3
fi
```

The heredoc at `:94-112` goes to `>&2` and begins `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.` (`:95`). This check comes before both the probe branch (`:165`) and the run (`:178`), so a probe and a run are refused alike.

**Evidence:** `scripts/confine-tests.sh:79-118`

---

## Claim 4: "`--no-loopback` over bwrap (134-152): bwrap always raises `lo`, so the flag switches to `unshare` (a second `unshare -rn true`), with a warning ... When unshare does not work: refused, exit 2."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:16`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the switch block and its refusal; the imprecision is only in "a second `unshare -rn true`"; does not establish real bwrap's loopback behaviour.
**Legibility-target:** for-author

The line range, the switch, the warning and the exit 2 all match (`scripts/confine-tests.sh:134-152`, `exit 2` at `:150`). "A second `unshare -rn true`" is imprecise. This block runs only when `primitive == bwrap`, and `detect_primitive` returns at `:82-83` before it probes unshare. So the call at `:135` is the first and only unshare probe; it is the second probe overall, after bwrap's. The test file records the same thing: in test 12, `unshare.1` is `-rn true` and `unshare.2` is the run (`test/scripts/confine-tests.bats:310-312`). A precise version would be: "(one `unshare -rn true` probe, after the bwrap probe)".

```bash
# scripts/confine-tests.sh:134-136
if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]; then
  if command -v unshare >/dev/null 2>&1 && unshare -rn true >/dev/null 2>&1; then
    primitive="unshare"
```

**Evidence:** `scripts/confine-tests.sh:79-91`, `scripts/confine-tests.sh:134-152`, `test/scripts/confine-tests.bats:310-312`

---

## Claim 5: "`ip` check (159-163): the unshare path with loopback needs `ip`; missing: exit 3."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `command -v ip` gate; does not establish that `ip` works when present.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:159` reads `if [[ "$primitive" == "unshare" && "$loopback" -eq 1 ]] && ! command -v ip >/dev/null 2>&1; then`, and the block ends in `exit 3` at `:162`.

**Evidence:** `scripts/confine-tests.sh:154-163`

---

## Claim 6: "`--probe` (165-169): prints `confine-tests: primitive available: NAME (loopback=N)` on stdout, exit 0. A command given with it is not run."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe branch; does not establish the truth of its second line (a stub cannot back it, as the doc says at `:167`).
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:166` is `echo "confine-tests: primitive available: $primitive (loopback=$loopback)"`, with no redirect, so it goes to stdout. `:168` is `exit 0`. That is before the run at `:178`, so any `cmd` is dropped.

**Evidence:** `scripts/confine-tests.sh:165-169`

---

## Claim 7: "No command (171-174): `nothing to run`, exit 2. This comes after detection."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the empty-command check and its order; see Claim 22 for the consequence.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:171-173` reads `if [[ "${#cmd[@]}" -eq 0 ]]; then` / `echo "confine-tests: nothing to run. ..." >&2` / `exit 2`. Detection is at `:115`, earlier in the file.

**Evidence:** `scripts/confine-tests.sh:115-118`, `scripts/confine-tests.sh:171-174`

---

## Claim 8: "Run (178-227): a banner on stderr, then `exec` of one of three forms: bwrap with a fixed profile and `-- "${cmd[@]}"`; `unshare -rn -- sh -c '<static body>' sh "${cmd[@]}"` (the body raises `lo`, exits 3 if that fails, then `exec "$@"`); or, with `--no-loopback`, `unshare -rn -- "${cmd[@]}"`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three exec forms through the file's last line; does not establish that real bwrap or unshare accept them.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:178, 199, 210, 219-227 (excerpt; :178-227 read to end of file)
echo "confine-tests: denying network via $primitive (loopback=$loopback)" >&2
  exec bwrap \
    -- "${cmd[@]}"
if [[ "$loopback" -eq 1 ]]; then
  exec unshare -rn -- sh -c '
    if ! ip link set lo up; then
      echo "confine-tests: failed to bring loopback up inside the namespace." >&2
      exit 3
    fi
    exec "$@"' sh "${cmd[@]}"
fi
exec unshare -rn -- "${cmd[@]}"
```

**Evidence:** `scripts/confine-tests.sh:178-227`

---

## Claim 9: "Callers: none in code. The hermeticity lint prints its name, `guides/test-hermeticity.md` documents it, and the dev cycle's brief wording has each loop run `--probe`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers tracked files outside `docs/` and `archive/`; does not establish CI configs outside this repo.
**Legibility-target:** for-orchestrator-synthesis

I ran `git grep -n 'confine-tests' -- ':!docs' ':!archive' ':!test/scripts/confine-tests.bats'`. It found only mentions, no invocations: `CLAUDE.md:9,15`, `guides/test-hermeticity.md:4,8,44,52,126,127`, `scripts/hermeticity-lint:29,935,1019` (`print("  Ground truth: scripts/confine-tests.sh -- <your test command>")`), a comment at `test/fixture-hermeticity.bats:15`, and the script's own lines. The brief wording appears in `docs/working/briefs/2026-11-10-confine-tests-bats.md:22`: "Run `scripts/confine-tests.sh --probe`: on exit 0 the tests also pass confined; on exit 3 quote its first line". The same sentence is in `docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md:29`. (Paraphrased — no quote available because this is an absence-of-callers claim resting on grep with no matching invocations.)

**Evidence:** `scripts/hermeticity-lint:1019`, `guides/test-hermeticity.md:126-127`, `docs/working/briefs/2026-11-10-confine-tests-bats.md:22`

---

## Claim 10: "In this container `scripts/confine-tests.sh --probe` exits 3 [observed 2026-11-10]. Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:24-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this review sandbox on 2026-11-10; does not establish the author's container state, which may differ.
**Legibility-target:** for-orchestrator-synthesis

I ran `timeout 60 scripts/confine-tests.sh --probe` in the worktree. It exited 3, and line 1 of `$L/probe.txt` is `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`. In the same container `command -v bwrap` exits 1 and `unshare -rn true` fails with `unshare: unshare failed: Operation not permitted` (`$L/env-facts.txt`, 19:41:45Z).

**Evidence:** `$L/probe.txt`, `$L/env-facts.txt`

---

## Claim 11: "The suite stays hermetic and passes `scripts/hermeticity-lint --root .` (H3). The new file spawns none of `claude`, `curl`, `gh`, `wget`, and writes only under `$BATS_TEST_TMPDIR`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:33`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lint result and every write path in the test file; does not establish what the real script would write in test 3 on a host where it can confine (there it runs only `--probe`).
**Legibility-target:** for-orchestrator-synthesis

I ran `timeout 300 scripts/hermeticity-lint --root .`. It exited 0 and printed `hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.` (`$L/hermeticity-lint.txt`). The writes, from reading the file: setup uses `T="$BATS_TEST_TMPDIR"` (`test/scripts/confine-tests.bats:40`); records go to `$STUB_LOG=$LOG` under `$T` (`:139`); `cd "$WORK"` is under `$T` (`:63`). The ambient test passes `STUB_LOG="$LOG"` (`:205`).

**Evidence:** `test/scripts/confine-tests.bats:40-63`, `test/scripts/confine-tests.bats:139`, `test/scripts/confine-tests.bats:205`, `$L/hermeticity-lint.txt`

---

## Claim 12: "Every `.bats` file carries `# @category fast|slow` (`scripts/run-tests.sh` header). This file is `slow`"; and "Category `slow` (script execution), matching `test/scripts/run-tests.bats`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:34`, `:97`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header rule and both files' tags.
**Legibility-target:** for-orchestrator-synthesis

`scripts/run-tests.sh:3` says `# Each .bats file must contain a "# @category fast|slow" tag comment.` `test/scripts/confine-tests.bats:2` and `test/scripts/run-tests.bats:2` are both `# @category slow`.

**Evidence:** `scripts/run-tests.sh:3`, `test/scripts/confine-tests.bats:2`, `test/scripts/run-tests.bats:2`

---

## Claim 13: "A stub is at least as strict as its tool (repo rule; decision log row 44, where an `iptables` stub that took any argv let a syntax error reach a live container)."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's content as described.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/log.md:67` (row 44): "the compound form is a syntax error, not a conjunction, and it reached a live container because the bats `iptables` stub accepted any argv."

**Evidence:** `docs/decisions/log.md:67`

---

## Claim 14: "No `skip` on a repo file (decision 023). The file has no `skip` at all."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and the absence of `skip`; "decision 023" and CLAUDE.md's "record 023" name the same file.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/023-wire-hooks-from-the-image.md` is the only 023. Its Amendment A says: "Three integration tests ... had been silently skipping on `[ -f "$REAL_AUDIT" ] || skip`. The skip guard is removed: the auditor's presence is now a repo invariant" (`docs/decisions/023-wire-hooks-from-the-image.md:135-137`). The test file has no `skip` (paraphrased — no quote available because this claim covers absence of code: reading `test/scripts/confine-tests.bats:1-395` found no `skip`).

**Evidence:** `docs/decisions/023-wire-hooks-from-the-image.md:135-137`, `test/scripts/confine-tests.bats:1-395`

---

## Claim 15: "A review unit stays at or under 400 changed code lines outside `docs/` (decision log row 62). The test file is 395 lines."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:37`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's cap and the file's length; the research doc is under `docs/` and is not counted.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/log.md:85` (row 62): "Every review unit has a hard size cap of ~400 changed code lines, counted outside `docs/` ... the gate fires above 400." `wc -l` gives `395 test/scripts/confine-tests.bats` (`$L/env-facts.txt`), and `git diff --stat` shows it as the only file outside `docs/`.

**Evidence:** `docs/decisions/log.md:85`, `$L/env-facts.txt`

---

## Claim 16: "`test/scripts/run-tests.bats`: runs a script under `env -i PATH=...`, and (line 490) builds a PATH directory of symlinks to leave one tool out."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:41`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited test; line 490 is its `@test` line, and the symlink loop follows at 493-499.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/scripts/run-tests.bats:490, 493, 498
@test "--jobs without GNU parallel on PATH warns and runs serially" {
  local bin="$BATS_TEST_TMPDIR/noparallel" dir f
      [[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"
```

`grep -c 'env -i' test/scripts/run-tests.bats` gives 4.

**Evidence:** `test/scripts/run-tests.bats:490-499`

---

## Claim 17: "`test/scripts/build-loop-orchestrator.bats`: `bats_require_minimum_version 1.5.0` and `run --separate-stderr`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:42`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both constructs being present.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/build-loop-orchestrator.bats:7` is `bats_require_minimum_version 1.5.0`, and `:12` is `bl() { run --separate-stderr bash "$BL" "$@"; }`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:7`, `test/scripts/build-loop-orchestrator.bats:12`

---

## Claim 18: "Decision 018 ... names `scripts/confine-tests.sh:220` as the reference for 'static shell body, values as positional arguments'."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and that :220 is still the line it names.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43` says "(`scripts/confine-tests.sh:220` is the reference for this pattern.)", and `:117` says "`scripts/confine-tests.sh:220` — reference argv-passthrough pattern." `scripts/confine-tests.sh:220` is still `exec unshare -rn -- sh -c '`.

**Evidence:** `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`, `scripts/confine-tests.sh:220`

---

## Claim 19: The failure-pattern grep (`grep -inE 'confine|hermetic|netns|unshare|bwrap|namespace|stub|argv|shim|skip-not-fail' docs/failure-patterns.md`) gives FP-050, FP-052, FP-058, FP-065, FP-076, FP-155, with the one-line descriptions given.

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:47`, `:56-61`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set of IDs and each description; does not judge the doc's applicability calls.
**Legibility-target:** for-orchestrator-synthesis

I ran the quoted grep in the worktree with `| grep -oE 'FP-[0-9]+' | sort -u` (exit 0). It printed exactly `FP-050 FP-052 FP-058 FP-065 FP-076 FP-155`. The entries are:

- `docs/failure-patterns.md:192` `FP-050 ... symptom:unshare-tier-shares-host-mount-namespace-host-writes`
- `:194` `FP-052 ... symptom:confine-blocks-all-writes-crashing-matplotlib-font-cache`
- `:200` `FP-058 ... symptom:bwrap-runtime-failure-drops-the-computation-silently`
- `:207` `FP-065 ... symptom:hardcoded-artifact-path-makes-suite-skip-not-fail`
- `:218` `FP-076 ... symptom:headless-read-confined-to-cwd-critic-briefs-blocked`
- `:297` `FP-155 ... symptom:four-document-link-cycle-between-stub-and-spec`

All six descriptions in the doc match. (The grep was run inline and its output is reproduced here, not in a separate log.)

**Evidence:** `docs/failure-patterns.md:192,194,200,207,218,297`

---

## Claim 20: "The real `unshare` is in `/usr/bin`, beside `bash`." Also DD-1 row a: "the real `unshare` shares a directory with `bash`", and the setup comment "the real unshare sits in the same directory as bash, so the ambient PATH is no use."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:49`, `:73`; `test/scripts/confine-tests.bats:46-47`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container's layout; does not establish other hosts.
**Legibility-target:** for-orchestrator-synthesis

`bash -c 'type -P bash sh unshare'` prints `/usr/bin/bash`, `/usr/bin/sh`, `/usr/bin/unshare` (`$L/env-facts.txt`). `ip` is at `/usr/sbin/ip`, which is also on the ambient PATH. That is a further reason the ambient PATH cannot model "ip missing" (paraphrased — no quote available because this comes from the inline `type -P` run early in the session, not a captured log).

**Evidence:** `test/scripts/confine-tests.bats:46-51`, `$L/env-facts.txt`

---

## Claim 21: "`$PWD` does not pass through `env -i`; a fresh bash sets it to the physical directory. The expected `--bind`/`--chdir` values use `pwd -P`." Also the setup comment "spelled the way a fresh bash spells it ($PWD does not pass through `env -i`)".

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:50`; `test/scripts/confine-tests.bats:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 started under `env -i` in a symlinked directory.
**Legibility-target:** for-orchestrator-synthesis

I made a symlink `lnk -> real` in scratch and ran `cd lnk && env -i /usr/bin/bash -c 'echo "PWD=$PWD"'`. It printed `PWD=.../fc1/real`, the physical path (inline run, 19:39Z). The setup line is `WORK="$(cd "$T/work dir" && pwd -P)"` (`test/scripts/confine-tests.bats:45`).

**Evidence:** `test/scripts/confine-tests.bats:43-45`, `test/scripts/confine-tests.bats:60-62`

---

## Claim 22: "A stub whose shebang is not on line 1 still runs when bash starts it (bash falls back to running the file itself) and fails when `sh` starts it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a stub with bash syntax under bash 5.2.15 and dash 0.5.12; does not establish the history claim "A first draft had this bug" (not in the branch's commits).
**Legibility-target:** for-orchestrator-synthesis

I wrote a file whose line 1 is blank and line 2 is `#!/usr/bin/env bash`, followed by `[[ -n x ]] && echo ...`. Started from bash it printed `ran ok as 5.2.15(1)-release`, exit 0. Started from dash it printed `./nl1: 3: [[: not found`, exit 127 (inline run, 19:39Z). Dash also falls back to interpreting the file itself; it fails because it cannot parse the bash syntax. That matches "fails when `sh` starts it".

**Evidence:** inline run; `test/scripts/confine-tests.bats:92`

---

## Claim 23a: "bash's `exec` takes options and dash 0.5.12's does not" (Gotchas), and D1's "bash's `exec` builtin takes options (`-c`, `-l`, `-a`) ... dash 0.5.12 (this container's `sh`) has no `exec` options".

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:52`, `:172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12-2 in this container.
**Legibility-target:** for-orchestrator-synthesis

`dpkg-query -W` gives `dash 0.5.12-2` and `bash 5.2.15-2+b13`, and `readlink -f /usr/bin/sh` gives `/usr/bin/dash` (`$L/env-facts.txt`). Bash prints the usage `exec [-cl] [-a name] ...` (`$L/d1-repro.txt`). `dash -c 'exec -record'` printed `dash: 1: exec: -record: not found`, exit 127. Dash looked the word up as a command; it did not parse it as an option.

**Evidence:** `$L/env-facts.txt`, `$L/d1-repro.txt`

---

## Claim 23b: "neither takes a portable `--` (dash runs `--` as the command)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `exec --` in both shells; the dash half is exact, the "neither" half is imprecise for bash.
**Legibility-target:** for-author

The dash half is right: `dash -c 'exec -- true'` printed `dash: 1: exec: --: not found`, exit 127. But bash does take `--`: `bash -c 'exec -- echo "bash exec -- ok"'` printed `bash exec -- ok`, exit 0 (inline run, 19:39Z). The test's own stand-in depends on this, with `exec -- "$@"` under bash (`test/scripts/confine-tests.bats:107`, `:116`). The conclusion holds: `--` is not portable across the two shells. A precise version: "bash's `exec` accepts `--` but dash 0.5.12's runs it as the command, so no `--` works in both."

**Evidence:** `test/scripts/confine-tests.bats:107,116`, inline runs

---

## Claim 24: DD-1 row d: "Source the script and override functions — not possible — the script runs top-level and `exec`s"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's structure (no main guard); does not claim that sourcing is impossible in the shell's sense, only that it is useless.
**Legibility-target:** for-orchestrator-synthesis

The script's only functions are `detect_primitive` (`:79-91`) and `explain_unavailable` (`:93-113`). Everything else runs at top level: the parse loop at `:53`, the detection call at `:115`, and `exit`/`exec` at `:63,68,117,150,162,168,173,199,220,227`. Sourcing it would parse the caller's arguments and then exit or exec (paraphrased — no quote available because the claim is about the file's whole structure).

**Evidence:** `scripts/confine-tests.sh:47-227`

---

## Claim 25: "`test/scripts/confine-tests.bats`: 17 tests. 395 lines, a new file."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:104`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 9d37c1ac.
**Legibility-target:** for-orchestrator-synthesis

`grep -c '^@test'` gives 17 and `wc -l` gives 395 (`$L/env-facts.txt`). `$L/bats-run.txt` shows `1..17`. The doc's own "~200 lines" at `:103` is 220 actual, which is within its tilde.

**Evidence:** `$L/env-facts.txt`, `$L/bats-run.txt`

---

## Claim 26: G6, "the bwrap run, the `--no-loopback` run and the unshare run each pass 12 hostile words and compare the child's argv exactly"; and the G4/G5/G8/G9 test counts (three, three, three, four).

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:125-130`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gap table's mapping to the test file.
**Legibility-target:** for-orchestrator-synthesis

`TRICKY` has 12 elements (`test/scripts/confine-tests.bats:30-31`: `'two words' -n --probe --no-loopback -- '' '$(touch pwned)' '`touch pwned`' '; touch pwned' '*' "it's" $'line one\nline two'`). The three forms each use it: `call child 1 "${TRICKY[@]}"` at `:271`, `:314` and `:370`. The test counts are G4 = tests 4, 5, 6; G5 = 7, 8, 9; G8 = 11, 12, 13; G9 = 14, 15, 16, 17.

**Evidence:** `test/scripts/confine-tests.bats:30-31,271,314,370`

---

## Claim 27a: Rollback: "`test/` is not installed by `devcontainer-config/install.sh`, and no script, hook or image file changes."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:145`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers install.sh's two source lists and the branch diff.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/install.sh:121` is `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh ... egress claude-home)`, and `:146` is `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`. Neither names `test`. The diff touches only the two new files.

**Evidence:** `devcontainer-config/install.sh:121`, `devcontainer-config/install.sh:146`

---

## Claim 27b: Rollback: "`git revert -m 1 <this branch's merge commit>` removes the test file, this doc and the brief's status change."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:145`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch at 9d37c1ac; true once plan step 5 lands.
**Legibility-target:** for-author

At 9d37c1ac the branch changes no brief. `git diff --stat a37733cc...HEAD` lists only the research doc and the test file, and the brief was last changed in b140807a on main. The "brief's status change" is planned work (`:107`: "the brief's status line to done"). A revert today would remove two files, not three. The sentence becomes accurate once step 5 is committed on this branch.

**Evidence:** `docs/working/research-2026-11-10-confine-tests-bats.md:107`, `git log --oneline -1 -- docs/working/briefs/2026-11-10-confine-tests-bats.md` → `b140807a`

---

## Claim 28: Defect D1: on the unshare loopback path, a command whose name starts with `-` fails when `sh` is bash (status 2, the quoted stderr), works with dash, `exec -- "$@"` is not the fix (dash exit 127), "the other two run forms put `--` before the command and are fine", and "the tests pin a dash-named command on the bwrap and `--no-loopback` forms only".

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:172-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the defect under the test's stand-ins with sh linked to bash 5.2.15 and to dash 0.5.12; does not establish behaviour with a real unshare.
**Legibility-target:** for-orchestrator-synthesis

I appended two tests to a scratch copy of the test file. With `$TOOLS/sh` relinked to bash, `confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- -record -x` gave `status=2` and this stderr, matching the doc's block line for line (`$L/d1-repro.txt`):

```
confine-tests: denying network via unshare (loopback=1)
sh: line 6: exec: -r: invalid option
exec: usage: exec [-cl] [-a name] [command [argument ...]] [redirection ...]
```

With dash it gave `status=0` and `call child 1 -x` succeeded. Line 6 of the body is `exec "$@"`, counting the empty line after the opening quote at `scripts/confine-tests.sh:220-225`. The other two forms are `-- "${cmd[@]}"` (`:210`, `:227`). The dash-named command is pinned at `test/scripts/confine-tests.bats:277` (bwrap) and `:353` (`--no-loopback`), and not in the unshare loopback tests (`:364`, `:378`, `:390`).

**Evidence:** `scripts/confine-tests.sh:210,220-227`, `test/scripts/confine-tests.bats:277,353,364,378`, `$L/d1-repro.txt`

---

## Claim 29: O1: "The probe is `--ro-bind / / --unshare-net -- true`; the run adds `--dev`, `--proc`, `--tmpfs`, `--bind`, `--unshare-pid`. ... It fails closed, and a test pins that."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:189`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe and run argv; the only imprecision is the list of additions.
**Legibility-target:** for-author

The run also adds `--setenv TMPDIR /tmp`, `--die-with-parent` and `--chdir "$PWD"` (`scripts/confine-tests.sh:204`, `:208`, `:209`), which the list leaves out. The point holds (the probe asks for less), and the fail-closed run is pinned by test 10 (`test/scripts/confine-tests.bats:284-289`). A precise version: "the run adds `--dev`, `--proc`, `--tmpfs`, `--setenv`, `--bind`, `--unshare-pid`, `--die-with-parent` and `--chdir`".

**Evidence:** `scripts/confine-tests.sh:81`, `scripts/confine-tests.sh:199-210`, `test/scripts/confine-tests.bats:284-289`

---

## Claim 30: O2: "The warning ... is printed only when `--no-loopback` forces the switch from bwrap. When bwrap is missing or refused, the same weaker profile runs with only `denying network via unshare`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every stderr write on the plain-unshare path.
**Legibility-target:** for-orchestrator-synthesis

The warning lines (`scripts/confine-tests.sh:137-143`) sit inside `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]` (`:134`). On a plain unshare primitive the only stderr before exec is `:178`. Test 16 pins `[ "$stderr" = "confine-tests: denying network via unshare (loopback=1)" ]` (`test/scripts/confine-tests.bats:366`).

**Evidence:** `scripts/confine-tests.sh:134-143,178`, `test/scripts/confine-tests.bats:366`

---

## Claim 31: O3: "No primitive and no command exits 3, not 2. Detection comes before the empty-command check."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-argument call in this container.
**Legibility-target:** for-orchestrator-synthesis

I ran `bash -c 'cd <worktree> && timeout 30 scripts/confine-tests.sh >/dev/null 2>&1; echo "no-args exit=$?"'`, which printed `no-args exit=3` (`$L/env-facts.txt`, last line, 19:42Z). The order is `:115-118` before `:171-174`.

**Evidence:** `scripts/confine-tests.sh:115-118,171-174`, `$L/env-facts.txt`

---

## Claim 32: O4: "A command given without `--` is reported as `unknown flag: <command>`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:192`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `*)` arm.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:65-66` reads `*)` / `echo "confine-tests: unknown flag: $1" >&2`, and any non-flag first word reaches that arm.

**Evidence:** `scripts/confine-tests.sh:65-69`

---

## Claim 33: Docs: "Two dated records say it had no test: `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md` (weak seam 3) and `docs/working/research-2026-11-07-confine-tests-situation.md` (follow-up 5). ... `guides/test-hermeticity.md` lists `test/hermeticity-lint.bats` under its relevant paths and says nothing about tests of this script"; and the 2026-11-07 "follow-up 2: a `--probe` and one confined suite in the sandbox's live run".

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:196`, `:161`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three cited docs.
**Legibility-target:** for-orchestrator-synthesis

The quotes, in order:

- `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md:56`: "3. **`confine-tests.sh` ships with no automated test at all** — a consequence of (2)."
- `docs/working/research-2026-11-07-confine-tests-situation.md:163`: "5. `confine-tests.sh` still has no bats case (review weak seam 3)."
- `:151-152` of the same doc (follow-up 2): "**Q-125 live run**: add `scripts/confine-tests.sh --probe` and one `scripts/confine-tests.sh -- bats test/<one fast suite>` to the in-session checks."
- `guides/test-hermeticity.md:8`: "Relevant paths: scripts/hermeticity-lint, scripts/hermeticity/adapters/, scripts/confine-tests.sh, test/hermeticity-lint.bats".

The guide's other mentions of the script (`:4`, `:44`, `:52`, `:126-127`) are about running it, not testing it.

**Evidence:** `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md:56`, `docs/working/research-2026-11-07-confine-tests-situation.md:151-152,163`, `guides/test-hermeticity.md:8`

---

## Claim 34: Header: "Every test but one runs the script on a PATH built here: the real bash, sh, cat and awk, plus stand-ins for bwrap, unshare and ip. A stand-in creates no namespace, so nothing here shows that the network is denied ..."

**Location:** `test/scripts/confine-tests.bats:7-13`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the PATH each test hands the script and what the stub does on a run; does not cover the teardown helpers (`xargs`), which run on bats' own PATH, not the script's.
**Legibility-target:** for-orchestrator-synthesis

`confine()` builds `local path="$TOOLS"` and prepends only the named stub dirs, then runs `env -i PATH="$path" ...` (`test/scripts/confine-tests.bats:134-140`). `$TOOLS` holds symlinks for `bash sh cat awk` (`:49-51`), plus `-record`. The one exception is test 3 (`:199`, `:205`), which calls `"$SCRIPT"` directly. On a run the stub's `ok` branches are `exec -- "$@"` (`:107`, `:116`). They create no namespace.

**Evidence:** `test/scripts/confine-tests.bats:49-55,107,116,134-140,199,205`

---

## Claim 35: Header: "A stand-in ... takes the exact argv shapes the script uses today, under a mode the test names, and any other call fails the test that made it (see confine())."

**Location:** `test/scripts/confine-tests.bats:15-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every call that reaches a stand-in's `case` (any unlisted argv or mode writes `unexpected`, and `confine()` checks it after every run); does not cover `command -v` lookups (no call is made, so nothing records them; see Claim 42), and a stand-in that dies before recording (for example `set -u` on an unset `STUB_LOG`) writes no `unexpected` marker and is caught only by the call-count assertions.
**Legibility-target:** for-orchestrator-synthesis

`is()` compares a count-prefixed `%q` rendering of the whole argv (`:93-95`). Each arm accepts only the listed shape/mode pairs, and everything else falls through to `printf ... >> "$STUB_LOG/unexpected"` / `exit 99` (`:125-126`). `confine()` ends with `[[ ! -e "$LOG/unexpected" ]]` (`:141`). That is a bare command in a bats test body, so a return of 1 fails the test. Test 3 runs with no stand-ins on PATH. Executed support: the 22 mutants in `$L/mutations.txt` include several that change an argv. M01 dropped `--unshare-net` and M17 dropped `--unshare-pid`; tests 8, 9 and 10 failed for both. M18 changed the probe; ten tests failed.

**Evidence:** `test/scripts/confine-tests.bats:91-142`, `$L/mutations.txt`

---

## Claim 36: TRICKY comment: "Words a shell would mangle if any step re-parsed them: a space, leading dashes (the script's own flags among them), an empty word, substitutions, a separator, a glob, a quote and a newline."

**Location:** `test/scripts/confine-tests.bats:27-31`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the array's contents against each listed kind.
**Legibility-target:** for-orchestrator-synthesis

The array at `:30-31`, mapped to the listed kinds:

| Kind | Elements |
|---|---|
| space | `'two words'` |
| leading dashes | `-n`, `--probe`, `--no-loopback`, `--` |
| empty word | `''` |
| substitutions | `'$(touch pwned)'`, `` '`touch pwned`' `` |
| separator | `'; touch pwned'` |
| glob | `'*'` |
| quote | `"it's"` |
| newline | `$'line one\nline two'` |

That is 12 words.

**Evidence:** `test/scripts/confine-tests.bats:27-31`

---

## Claim 37: RECORD_CALL comment: "A call is recorded as one file, $STUB_LOG/NAME.N for NAME's Nth call, holding the argv with a NUL after each element: an empty file is a call with no arguments, and an argument may hold a newline."

**Location:** `test/scripts/confine-tests.bats:33-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the generated recorder and the readers `call()` and `mapfile -d ''`.
**Legibility-target:** for-orchestrator-synthesis

`:36-37` is `n=1; while [[ -e "$STUB_LOG/$name.$n" ]]; do n=$((n + 1)); done` / `if [[ $# -gt 0 ]]; then printf "%s\0" "$@"; fi > "$STUB_LOG/$name.$n"`. The redirect applies to the whole `if` statement, so a call with no arguments creates an empty file. `call()` writes the expected argv the same way and compares with `cmp -s` (`:161`). The newline word passes exactly: `call child 1 "${TRICKY[@]}"` succeeds in tests 8, 12 and 16 (`$L/bats-run.txt`).

**Evidence:** `test/scripts/confine-tests.bats:36-37,157-163`, `$L/bats-run.txt`

---

## Claim 38: teardown comment: "bats shows only the failing line; add what the script and stand-ins did."

**Location:** `test/scripts/confine-tests.bats:67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats 1.8.2's failure output; the conclusion (the script's status, streams and calls are not shown without teardown, because `run` captures them) holds.
**Legibility-target:** for-author

Bats also shows whatever the test printed to stdout. A scratch test that echoed and then ran `false` printed `#   \`false' failed` followed by `# helper says: bwrap was called 1 time(s), want 2` (`$L/bats-failing-output.txt`, exit 1). The file's own helpers print that kind of line (`:151`, `:160`, `:162`). What bats does not show is the output that `run` captured. A precise version: "bats shows the failing line and the test's own output, not what `run` captured".

**Evidence:** `test/scripts/confine-tests.bats:66-78,151,160,162`, `$L/bats-failing-output.txt`

---

## Claim 39: The stand-in's comment table (bwrap: probe ok/run-fails succeed, refused fails; run profile then a command: ok execs, run-fails fails; unshare: probe `-rn true` ok succeeds, refused fails; `-rn -- COMMAND...` ok execs; ip `link set lo up`: ok succeeds, fails fails; any other argv or unset mode → `unexpected`, exit 99; a run execs the command unconfined).

**Location:** `test/scripts/confine-tests.bats:80-90`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every arm of the generated stub against the table, row by row.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/scripts/confine-tests.bats:103-121 (excerpt; stub read through :126)
    if is --ro-bind / / --unshare-net -- true; then
      case "$mode" in ok|run-fails) exit 0 ;; refused) exit 1 ;; esac
    elif [[ $# -gt ${#profile[@]} ]] && is "${profile[@]}" "${@:${#profile[@]}+1}"; then
      case "$mode" in
        ok) shift "${#profile[@]}"; exec -- "$@" ;;
        run-fails) echo "stub bwrap: run refused" >&2; exit 1 ;;
    if is -rn true; then
      case "$mode" in ok) exit 0 ;; refused) exit 1 ;; esac
    elif [[ $# -ge 3 && "$mode" == ok ]] && is -rn -- "${@:3}"; then
      shift 2; exec -- "$@"
    if is link set lo up; then
      case "$mode" in ok) exit 0 ;; fails) echo "stub ip: cannot raise lo" >&2; exit 1 ;; esac
```

The fall-through is at `:125-126`, and `mode="${!var:-unset}"` (`:97`) sends an unset mode there. The bwrap run shape requires at least one word after the profile, which matches "then a command".

**Evidence:** `test/scripts/confine-tests.bats:91-128`

---

## Claim 40: `confine()` comment: "run the script with ARGs in an empty environment whose PATH holds the named stand-ins ... and the real tools. Fails the test when a stand-in refused a call."

**Location:** `test/scripts/confine-tests.bats:130-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper; "empty environment" means `env -i` plus `PATH`, `HOME`, `TMPDIR`, `STUB_LOG` and the named assigns.
**Legibility-target:** for-orchestrator-synthesis

`:139-141` is `run --separate-stderr env -i PATH="$path" HOME="$T" TMPDIR="$T" STUB_LOG="$LOG" \` / `"${assigns[@]}" "$SCRIPT" "$@"` / `[[ ! -e "$LOG/unexpected" ]]`. "Refused a call" in this comment means a stand-in rejecting an unexpected call (the `unexpected` marker), not a mode named `refused`, which is an accepted shape.

**Evidence:** `test/scripts/confine-tests.bats:133-142`

---

## Claim 41: Test names 1-6: (1) "with neither primitive installed, --probe exits 3 saying so first, and a test command is not run"; (2) "with both primitives installed and refused, the refusal names what went unenforced (H2)", with the comment "This container's shape: unshare is installed and the kernel refuses it"; (3) "on this machine's own PATH, --probe gives one of its verdicts, and a refusal runs nothing"; (4) "an unknown flag, or a command given without --, is a usage error (exit 2) before any primitive is tried"; (5) "with a primitive available, no command is a usage error (exit 2)"; (6) "--help and -h print the header comment only, exit 0, and try no primitive".

**Location:** `test/scripts/confine-tests.bats:172-249`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its body and the mutants that should break it; for (3), the "refusal runs nothing" half is exercised only on a host where the probe exits 3 (it does here), and on a host that can confine, the test runs only `--probe`.
**Legibility-target:** for-orchestrator-synthesis

How each test's body supports its name:

1. Runs with no stub dirs on PATH. `refused 3 "$NO_PRIMITIVE"` checks the status, that the first stderr line is the refusal, and that stdout is empty. `calls child 0` and `[ ! -e pwned ]` follow (`:173-178`). Mutants M03 (refusal exits 0) and M06 (runs unconfined) both fail it.
2. Asserts both phrases of the refusal (`:189-190`), and `calls bwrap 2 unshare 2 child 0` (`:192`) shows one probe each per invocation. The comment holds in this container: `unshare` is installed and `unshare -rn true` gives `Operation not permitted` (`$L/env-facts.txt`). H2 at `docs/constraints.md:6` reads: "refuses and names what went unenforced".
3. Accepts exit 0 with a well-formed line, or exit 3 with a refusal and then a run with `calls child 0` (`:200-210`). Here it takes the 3 branch.
4. Checks both inputs and then `calls bwrap 0 unshare 0 child 0`, with modes set to `ok` so a probe would have been recorded (`:214-220`). M10 (unknown flag exits 1) fails it.
5. Covers three arg sets and `calls bwrap 3 unshare 1` (`:225-233`). M15 (empty command exits 0) fails it.
6. Leaves every mode unset, so any stand-in call would write `unexpected`, and checks the first line and that no `#!`, `set -euo pipefail` or `preflight` text appears (`:238-248`). M16 (awk does not stop at the header) fails it.

**Evidence:** `test/scripts/confine-tests.bats:172-249`, `docs/constraints.md:6`, `$L/mutations.txt`, `$L/env-facts.txt`

---

## Claim 42: Test 7 name: "--probe reports bwrap when bwrap works, consults nothing else, and runs no command given with it"

**Location:** `test/scripts/confine-tests.bats:251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** "Consults nothing else" holds for calls of the other stand-ins (`unshare` is asserted at 0 and `ip` has no mode, so a call of it would fail the test); it does not establish the absence of `command -v` lookups, which the stand-ins cannot record.
**Legibility-target:** for-orchestrator-synthesis

The body asserts `calls bwrap 1`, the exact probe argv, and `calls unshare 0 child 0` with `-- "$RECORD" one` given (`:252-258`). I built a mutant, M22, that also runs the `command -v ip` gate on the bwrap path. Test 7 passed it; tests 5 and 9 failed it (`$L/mutations.txt`, last line). So the suite catches that mutant, but this test alone cannot see a lookup.

**Evidence:** `test/scripts/confine-tests.bats:251-259`, `$L/mutations.txt`

---

## Claim 43: Test names 8-15: (8) "a bwrap run hands bwrap the whole profile, then each word of the command as its own argv element"; (9) "a bwrap run passes a command whose name starts with a dash, and the command's exit status"; (10) "a bwrap that fails at run time fails the run: no fallback to unshare, nothing run unconfined"; (11) "--no-loopback switches from bwrap to unshare and warns about what is lost, in either flag order"; (12) "a --no-loopback run goes to unshare directly: no sh, no ip, the command after --"; (13) "--no-loopback is refused (exit 2), probe or run, when bwrap works and unshare does not"; (14) "--probe reports unshare when bwrap is not installed, or is installed and refused"; (15) "unshare without ip is refused (exit 3), probe or run, and serves --no-loopback"; plus the inline comments at :268-269, :285, :355.

**Location:** `test/scripts/confine-tests.bats:261-360`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its body and the mutants that should break it; does not establish real bwrap or unshare behaviour.
**Legibility-target:** for-orchestrator-synthesis

How each test's body supports its name:

8. `call bwrap 2 "${PROFILE[@]}" "$RECORD" "${TRICKY[@]}"` plus the child's exact argv (`:267-271`). M01, M05 and M17 fail it.
9. `-record -x` with `CHILD_EXIT=7` gives status 7 and the exact argv (`:277-281`).
10. `run-fails` gives `status -ne 0` and `calls bwrap 2 unshare 0 child 0` (`:286-288`). M01 and M17 also fail it.
11. Loops over `"--no-loopback --probe" "--probe --no-loopback"` with the bwrap stub `ok` (`:293-300`). M08 and M19 fail it.
12. `call unshare 2 -rn -- "$RECORD" "${TRICKY[@]}"`; that exact argv holds no `sh`, and `calls ip 0` follows (`:310-313`). M11 (drop `--`) and M13 (unquoted) fail it.
13. Covers bwrap-only and bwrap plus refused unshare, each probe and run (`:320-327`). M20 and M21 fail it.
14. Covers both arms (`:332-340`).
15. Covers probe and run with `NO_IP`, and both `--no-loopback` forms, with `calls unshare 5` (`:344-359`). M09 fails it.

The comment at `:285` matches Claim 29, and the one at `:355` matches `calls unshare 5` with one probe in each of 4 invocations plus 1 run.

**Evidence:** `test/scripts/confine-tests.bats:261-360`, `$L/mutations.txt`, `$L/bats-run.txt`

---

## Claim 44: Test 16 name: "an unshare run raises lo, then execs the command: a static sh body, every word a positional argument"

**Location:** `test/scripts/confine-tests.bats:362`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the static body, the positional words and lo being raised (with ordering backed by test 17); the "execs" verb is not shown, because a body that runs the command without `exec` passes.
**Legibility-target:** for-author

The body pins `sh -c BODY sh "$RECORD" "${TRICKY[@]}"`. It also checks that BODY is identical across two commands and contains none of their words, and that the child's status 7 comes back through sh (`:374-384`). M02 (interpolated body) fails it. Mutant M12, which replaces `    exec "$@"' sh` with `    "$@"' sh` at `scripts/confine-tests.sh:225`, passes all 17 tests: `M12 sh body without exec: bats exit=0 failing=[]` (`$L/mutations.txt`). So this test cannot tell exec from a fork that propagates the exit status. Its own comment says only that "The command's exit status comes back through sh" (`:376-377`). A precise name: "...raises lo, then runs the command: ...". The order "raises lo, then" is shown only together with test 17 (`ip` failing means the child is not run).

**Evidence:** `test/scripts/confine-tests.bats:362-387`, `scripts/confine-tests.sh:225`, `$L/mutations.txt`, `$L/diff-M12.txt`

---

## Claim 45: Test 17 name: "an unshare run is refused (exit 3) and the command not run when lo cannot be raised"

**Location:** `test/scripts/confine-tests.bats:389`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure path as observed by the caller (exit 3, last stderr line, child not run); does not establish real `ip` failure modes.
**Legibility-target:** for-orchestrator-synthesis

The test asserts `[ "$status" -eq 3 ]`, the last stderr line and `calls ip 1 child 0` (`:390-394`). Mutants M04 (`ip ... || true`) and M14 (`exit 0` on failure) both fail only test 17 (`$L/mutations.txt`).

**Evidence:** `test/scripts/confine-tests.bats:389-395`, `scripts/confine-tests.sh:221-224`, `$L/mutations.txt`

---

## Claim 46a: Commit 9d37c1ac: "Checked by mutating scratch copies of the script: 16 mutations (dropped --unshare-net, interpolated sh body, refusal exit 0, swallowed ip failure, unquoted command, unconfined fallback and others), each failed by at least one test." The six named mutations.

**Location:** commit `9d37c1ac` message body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers my own constructions of the six named mutants; does not establish that the author's constructions were the same.
**Legibility-target:** for-orchestrator-synthesis

All six of my versions failed at least one test (`$L/mutations.txt`; diffs in `$L/diff-M*.txt`; bats exit 1 for each):

| Mutant | Change | Failing tests |
|---|---|---|
| M01 | dropped `--unshare-net` from the run | 8, 9, 10 |
| M02 | interpolated sh body | 16 |
| M03 | refusal exits 0 | 1, 2, 3 |
| M04 | swallowed ip failure | 17 |
| M05 | unquoted bwrap command | 8 |
| M13 | unquoted `--no-loopback` command | 12 |
| M06 | unconfined fallback | 1, 2, 3 |

My first harness run built several mutants with a newline bug, which made them syntax errors. I discarded that run, and the table shows only the corrected one.

**Evidence:** `$L/mutations.txt`, `$L/diff-M01.txt` … `$L/diff-M06.txt`, `$L/diff-M13.txt`

---

## Claim 46b: Commit 9d37c1ac: "16 mutations ... and others, each failed by at least one test" (the full set).

**Location:** commit `9d37c1ac` message body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the count and the unnamed ten; the author's mutation list is not in the branch, so the full set cannot be re-run.
**Legibility-target:** for-orchestrator-synthesis

To verify it would take the author's list of 16. My own sample of 22 mutants had one survivor: M12, the sh body without `exec` (Claim 44). If M12 is among the author's 16, the claim is false; if it is not, the claim may hold. In either case, a reader should not take "16 of 16 killed" as cover for the exec-vs-fork distinction.

**Evidence:** `$L/mutations.txt`

---

## Claim 47: Commit 9d37c1ac: "17 characterization tests ... --no-loopback selection, and that each word of the test command reaches the child as its own argv element on all three run forms. ... scripts/confine-tests.sh --probe exits 3 in this container, so nothing here ran confined." Notes: "a command whose name starts with a dash is pinned on the bwrap and --no-loopback forms only; on the unshare loopback form it fails when sh is bash (defect D1 ...)".

**Location:** commit `9d37c1ac` message body
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count, the three-form argv coverage, the probe result in this sandbox and the D1 note; does not establish the author's container beyond this one.
**Legibility-target:** for-orchestrator-synthesis

The parts are each backed elsewhere in this report (paraphrased — no quote available because they restate claims verified above):

- 17 tests: Claim 25.
- Argv coverage on all three run forms: Claim 26.
- Probe exits 3: Claim 10.
- D1 and which forms pin a dash-named command: Claim 28.

**Evidence:** `$L/env-facts.txt`, `$L/probe.txt`, `$L/d1-repro.txt`, `test/scripts/confine-tests.bats:277,353`

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 4** (`docs/working/research-2026-11-10-confine-tests-bats.md:16`): "a second `unshare -rn true`". When bwrap is the primitive, detection never probed unshare, so this is the only unshare probe (the second probe overall). Say "one `unshare -rn true` probe, after bwrap's".
- **Claim 23b** (`docs/working/research-2026-11-10-confine-tests-bats.md:52`): "neither takes a portable `--`". Bash's `exec --` works, and the stand-in relies on it; only dash's fails (exit 127).
- **Claim 27b** (`docs/working/research-2026-11-10-confine-tests-bats.md:145`): the rollback says the revert removes "the brief's status change". The branch has none at 9d37c1ac; it becomes true only after plan step 5.
- **Claim 29** (`docs/working/research-2026-11-10-confine-tests-bats.md:189`): O1's list of what the run adds leaves out `--setenv`, `--die-with-parent` and `--chdir`.
- **Claim 38** (`test/scripts/confine-tests.bats:67`): "bats shows only the failing line". Bats also shows the test's own stdout, including this file's helper messages; what it does not show is the output `run` captured.
- **Claim 44** (`test/scripts/confine-tests.bats:362`): test 16's name says "execs the command", but mutant M12 (`"$@"` in place of `exec "$@"`) passes all 17 tests. Rename to "runs", or add an assertion that tells exec from fork.

### Unverifiable
- **Claim 46b** (commit `9d37c1ac`): "16 mutations ... each failed by at least one test". Checking it needs the author's mutation list. My own 22-mutant sample had one survivor (M12, Claim 44).

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/code-fact-check-report-2026-11-10-confine-tests-bats.md, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: Code-quality findings (for example, shellcheck's SC2016/SC2154 notices on the test file) were set aside because this is a fact-check, not a review. Execution logs live in the scratch directory, not under `docs/reviews/execution-logs/`, because the brief allows one repo file. Another session's `scripts/run-tests.sh` gate was running in this worktree's scratch area while I worked; I did not touch it.
- Escalate: Test 16's "execs" gap (mutant M12 survives) is a test-strength item for the review-fix loop. D1 is already recorded in the research doc and needs no new action from this pass.
