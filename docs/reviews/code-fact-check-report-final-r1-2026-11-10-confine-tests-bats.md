Commit: 27b5e861

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-2026-11-10-confine-tests-bats`, branch `test/confine-tests-bats`)
**Scope:** `test/scripts/confine-tests.bats` and `docs/working/research-2026-11-10-confine-tests-bats.md` at 27b5e861, plus the four commit messages `git log a37733cc..HEAD`; claims checked against `scripts/confine-tests.sh` (unchanged, read in full) and the cited repo files. The four first-pass `docs/reviews/*-2026-11-10-confine-tests-bats.md` files were not checked and not relied on.
**Checked:** 2026-11-10
**Total claims checked:** 55
**Summary:** 46 verified, 5 mostly accurate, 0 stale, 0 incorrect, 4 unverifiable

Final confirming pass, replicate r1. Final-pass result: no Incorrect. Five claims could be worded more precisely. The most useful of them is that `same_process` catches the sh-body `exec` mutant only because this host's `sh` is dash (Claims 24, 27).

**Execution provenance (applies to every `executed` claim).** cwd is the worktree, or a scratch copy under the log root that keeps the layout `scripts/confine-tests.sh` plus `test/scripts/confine-tests.bats`. Tools: bats 1.8.2, ShellCheck 0.9.0, bash 5.2.15, dash 0.5.12, all under `timeout`. Captured output is in `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-bats/fcfinal-r1/logs/` (written `LOGS/` below). The brief allowed one repo write, so the logs are not under `docs/reviews/execution-logs/`. Timestamps: test file and probe at 2026-11-10T20:26:34Z and 20:26:36Z; mutation run from 20:29:18Z; the D1/D2, `exec` and shebang probes between 20:30Z and 20:34Z. The mutants were built by `fcfinal-r1/mutate.py`, which asserts that each edit's anchor text matches exactly once. A control copy with no change passes 17 of 17 (`LOGS/mut-x00-control.out`). I did not run `scripts/run-tests.sh`. While I worked, another session's `scripts/run-tests.sh test/scripts/health-check.bats test/scripts/confine-tests.bats` was running (pid 2797778). It was not mine, so I left it alone.

Hallucination log (`docs/reviews/hallucination-patterns.md`, 8 entries): two entries are test-count claims ("All 85 tests…", "mode1-equiv 33"). The count claims here (Claims 12, 44, 47, 49) were checked against `grep -c '^@test'` with that pattern in mind, and all hold.

---

## Claim 1: "this branch adds one test file and this doc"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:5`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files the branch adds at 27b5e861. Does not establish whether the author meant to count review artifacts.
**Legibility-target:** for-author

`git diff --stat a37733cc...HEAD` lists six added files. Besides `test/scripts/confine-tests.bats` and this doc, there are four `docs/reviews/*-2026-11-10-confine-tests-bats.md` files (fact-check report 994 lines, rubric 91, performance review 101, security review 220). A precise version: "adds one test file and this doc (plus the review loop's reports)". The code-line count of 412 is unaffected, because `docs/` is excluded from it.

**Evidence:** `git diff --stat a37733cc...HEAD` (run in the worktree; six files, 2102 insertions)

---

## Claim 2: "Task status: in-progress (review loop: pass 1 done and its fixes made; final pass next)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch state at 27b5e861: the pass-1 fix commit f36108e4 exists and this is the final pass. Does not establish the brief's status line, which per the brief changes only in a later commit.
**Legibility-target:** for-orchestrator-synthesis

f36108e4's subject is "test: address review pass 1 on the confine-tests bats file (A1-A9, C1-C7)", and HEAD 27b5e861 records the gates "before the final review pass". This line is true now. It will be stale once the last commit flips the status, which the brief expects.

**Evidence:** `git log a37733cc..HEAD`

---

## Claim 3: "`scripts/confine-tests.sh` (227 lines, bash, `set -euo pipefail`)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count, the shebang and the shell options. Does not establish behaviour.
**Legibility-target:** for-orchestrator-synthesis

`wc -l scripts/confine-tests.sh` gives 227. `scripts/confine-tests.sh:1` is `#!/usr/bin/env bash` and `:47` is `set -euo pipefail`.

**Evidence:** `scripts/confine-tests.sh:1`, `scripts/confine-tests.sh:47`

---

## Claim 4: "What exists" items 1-7 and their line ranges

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:14-20`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every stated range and behaviour of items 1-7. Does not establish behaviour of the real primitives.
**Legibility-target:** for-orchestrator-synthesis

- Item 1, Flags (53-71): `:53` `while [[ $# -gt 0 ]]; do`, through `:71` `done`. Unknown flag: `:66-68` (`unknown flag: $1`, the usage line, `exit 2`). Help: `:62` uses `awk`, then `:63` `exit 0`. The loop comes before `detect_primitive` (`:115`).
- Item 2, Detection (79-118): `:81` `bwrap --ro-bind / / --unshare-net -- true`, `:86` `unshare -rn true`, `:115-118` `explain_unavailable; exit 3`. The message's first line is `:95`. Detection runs before `--probe` is consulted (`:165`), so a probe and a run are refused alike.
- Item 3 (134-152): `:135` `unshare -rn true` is the only unshare probe once bwrap was detected, because `detect_primitive` returns at `:83-84`. The warning is `:137-143`; the refusal is `:145-150`, ending `exit 2`.
- Item 4 (159-163): `if [[ "$primitive" == "unshare" && "$loopback" -eq 1 ]] && ! command -v ip`, then `exit 3`.
- Item 5 (165-169): `echo "confine-tests: primitive available: $primitive (loopback=$loopback)"`, then `exit 0`. `cmd` is never consulted on this path.
- Item 6 (171-174): `nothing to run`, `exit 2`. It comes after detection (`:115`).
- Item 7 (178-227): banner `:178`, then the three `exec` forms at `:199-210`, `:220-225` and `:227`. The `sh` body exits 3 when `ip link set lo up` fails (`:221-224`) and ends `exec "$@"` (`:225`).

**Evidence:** `scripts/confine-tests.sh:53-227`

---

## Claim 5: "Callers: none in code. The hermeticity lint prints its name, `guides/test-hermeticity.md` documents it, and the dev cycle's brief wording has each loop run `--probe`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers non-doc references outside `archive/`. "Each loop" holds in the narrow form the roadmap states: briefs whose acceptance names tests. Does not establish that any dev-cycle skill text carries the wording.
**Legibility-target:** for-orchestrator-synthesis

`git grep -n 'confine-tests' -- ':!docs/' ':!archive/'` finds the script itself and the new test, plus these mentions, none of which calls the script:

- `CLAUDE.md:9,15` (prose);
- `guides/test-hermeticity.md:4,8,44,52,126,127` (docs);
- `scripts/hermeticity-lint:29,935,1019`, a docstring, an epilog and `print("  Ground truth: scripts/confine-tests.sh -- <your test command>")`;
- `test/fixture-hermeticity.bats:15` (a comment).

The `--probe` wording lives in briefs, not in `skills/dev-cycle`. `docs/roadmap.md:47-49` says "in briefs whose acceptance names tests, use its conditional wording (run `scripts/confine-tests.sh --probe`…", and `docs/working/briefs/2026-11-10-confine-tests-bats.md:22` and `…-dev-cycle-skill-held-fixes.md:29` carry it.

**Evidence:** `scripts/hermeticity-lint:1019`, `docs/roadmap.md:47-49`, `docs/working/briefs/2026-11-10-confine-tests-bats.md:22`

---

## Claim 6: "In this container `scripts/confine-tests.sh --probe` exits 3 … Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:24-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container at 2026-11-10T20:26:36Z. Does not establish other hosts.
**Legibility-target:** for-orchestrator-synthesis

Command: `timeout 60 scripts/confine-tests.sh --probe`, cwd the worktree, exit 3. The first line is exactly the quoted text. There is no `bwrap` on PATH; `unshare -rn true` fails with "unshare failed: Operation not permitted"; `/proc/self/status` shows `CapEff: 0000000000000000` and `Seccomp: 2`.

**Evidence:** `LOGS/probe.out`, `LOGS/probe.ts`, `scripts/confine-tests.sh:95`

---

## Claim 7: "The tests run the repo's own file through its shebang, never a copy [observed: `SCRIPT="$REPO_ROOT/scripts/confine-tests.sh"`]"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:32`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every invocation in the test file. Does not establish anything about the mutation copies, which are scratch and separate.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:22-23` is `REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"` and `SCRIPT="$REPO_ROOT/scripts/confine-tests.sh"`. `:144` passes `"$SCRIPT" "$@"` to `env -i`, and `:211` and `:217` run `"$SCRIPT"` directly, so it always starts through its shebang and is never run as `bash "$SCRIPT"`.

**Evidence:** `test/scripts/confine-tests.bats:22-23`, `:144`, `:211`, `:217`

---

## Claim 8: "The new file spawns none of `claude`, `curl`, `gh`, `wget`, and writes only under `$BATS_TEST_TMPDIR`." (and passes the lint)

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:33`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test file's own commands and paths. Does not establish what a mutant script might write; for that, see the `pwned` assertions, whose target is under `$WORK`.
**Legibility-target:** for-orchestrator-synthesis

`grep -nE '\b(claude|curl|gh|wget)\b' test/scripts/confine-tests.bats` finds nothing. Every path in the file derives from `T="$BATS_TEST_TMPDIR"` (`:41-43`). The tests `cd "$WORK"` (`:66`), and `$WORK` sits under `$T`. `scripts/hermeticity-lint --root .` exits 0 (Claim 30).

**Evidence:** `test/scripts/confine-tests.bats:41-46`, `:66`, `LOGS/lint.out`

---

## Claim 9: "Every `.bats` file carries `# @category fast|slow` (`scripts/run-tests.sh` header). This file is `slow`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rule's source and this file's tag. Does not establish runner scheduling.
**Legibility-target:** for-orchestrator-synthesis

`scripts/run-tests.sh:3` reads `# Each .bats file must contain a "# @category fast|slow" tag comment.`, and `test/scripts/confine-tests.bats:2` is `# @category slow`.

**Evidence:** `scripts/run-tests.sh:3`, `test/scripts/confine-tests.bats:2`

---

## Claim 10: "decision log row 44, where an `iptables` stub that took any argv let a syntax error reach a live container"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:35` (also `test/scripts/confine-tests.bats:16`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's content. Does not establish anything further about row 44.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/log.md:67` (row 44) says "the compound form is a syntax error, not a conjunction, and it reached a live container because the bats `iptables` stub accepted any argv."

**Evidence:** `docs/decisions/log.md:67`

---

## Claim 11: "No `skip` on a repo file (decision 023). The file has no `skip` at all."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:36`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and the absence of `skip`. Does not establish whether 023 is the canonical home of the rule; repo `CLAUDE.md` also cites "record 023".
**Legibility-target:** for-orchestrator-synthesis

`grep -n skip test/scripts/confine-tests.bats` finds nothing. `docs/decisions/023-wire-hooks-from-the-image.md:135-137` says "Three integration tests in `test/hooks/claude-config-audit.bats` had been silently skipping on `[ -f "$REAL_AUDIT" ] || skip`. The skip guard is removed".

**Evidence:** `docs/decisions/023-wire-hooks-from-the-image.md:135-137`, `CLAUDE.md:17`

---

## Claim 12: "at or under 400 changed code lines outside `docs/` (decision log row 62). The test file was 395 lines at entry and is 412 after the loop's fixes, inside the loop's re-check limit of about 800 (`workflows/review-fix-loop.md`, size re-check)."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:37`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cap, the line counts at 9d37c1ac and HEAD, and the source of the ~800 figure. Does not establish anything about other units.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/log.md:85` (row 62) reads "hard size cap of ~400 changed code lines, counted outside `docs/` … the gate fires above 400". `git show 9d37c1ac:test/scripts/confine-tests.bats | wc -l` gives 395; at f36108e4 and HEAD it is 412, and the test file has not changed since f36108e4. `workflows/review-fix-loop.md:57` (under "### Size re-check") says "The unit's limit is ~800 lines (twice the entry cap)".

**Evidence:** `docs/decisions/log.md:85`, `workflows/review-fix-loop.md:55-57`

---

## Claim 13: "`test/scripts/run-tests.bats`: runs a script under `env -i PATH=...`, and (line 490) builds a PATH directory of symlinks to leave one tool out."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:41`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both cited patterns. Line 490 is the `@test` header, and the symlink loop is at 495-500.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/run-tests.bats:66` is `run env -i PATH="$path" HOME="$HOME" …`. `:490` is `@test "--jobs without GNU parallel on PATH warns and runs serially" {`, and `:500` is `[[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"`.

**Evidence:** `test/scripts/run-tests.bats:66`, `:490-500`

---

## Claim 14: "`test/scripts/build-loop-orchestrator.bats`: `bats_require_minimum_version 1.5.0` and `run --separate-stderr`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:42`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of both constructs. Does not establish anything else about that file.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/build-loop-orchestrator.bats:7` is `bats_require_minimum_version 1.5.0`, and `:12` is `bl() { run --separate-stderr bash "$BL" "$@"; }`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:7`, `:12`

---

## Claim 15: "Decision 018 … names `scripts/confine-tests.sh:220` as the reference for 'static shell body, values as positional arguments'. The unshare run test pins exactly that."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and what test 16 asserts. Does not establish D1's dash-named command case, which no test pins on this form (Claim 37).
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43` reads "(`scripts/confine-tests.sh:220` is the reference for this pattern.)", and `:117` reads "`scripts/confine-tests.sh:220` — reference argv-passthrough pattern." Script line 220 is `exec unshare -rn -- sh -c '`. Test 16 checks two things. First, that the body is identical across two commands and contains none of the command's text: `test/scripts/confine-tests.bats:400-401`, `[ "${first[4]}" = "${second[4]}" ]` and `[[ "${first[4]}" != *"$RECORD"* …`. Second, that every word arrives as a positional argument (`:391`).

**Evidence:** `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`, `scripts/confine-tests.sh:220`, `test/scripts/confine-tests.bats:389-403`

---

## Claim 16: Failure-pattern grep and the six IDs' descriptions (FP-050/052/058/065/076/155)

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:47`, `:57-62`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep's result set and the one-line glosses. Does not establish anything about the FPs' full entries beyond their symptom lines.
**Legibility-target:** for-orchestrator-synthesis

Command: `grep -inE 'confine|hermetic|netns|unshare|bwrap|namespace|stub|argv|shim|skip-not-fail' docs/failure-patterns.md | grep -oE 'FP-[0-9]+' | sort -u`, cwd the worktree, exit 0. Output: `FP-050 FP-052 FP-058 FP-065 FP-076 FP-155`, exactly those six. The symptom lines match the glosses:

- `:192` `symptom:unshare-tier-shares-host-mount-namespace-host-writes`
- `:194` `symptom:confine-blocks-all-writes-crashing-matplotlib-font-cache`
- `:200` `symptom:bwrap-runtime-failure-drops-the-computation-silently`
- `:207` `symptom:hardcoded-artifact-path-makes-suite-skip-not-fail`
- `:218` `symptom:headless-read-confined-to-cwd-critic-briefs-blocked`
- `:297` `symptom:four-document-link-cycle-between-stub-and-spec`

**Evidence:** `docs/failure-patterns.md:192,194,200,207,218,297` (command output reproduced above; run 2026-11-10T20:2xZ, no file captured because the output is the six-ID line quoted)

---

## Claim 17: "The real `unshare` is in `/usr/bin`, beside `bash`." (also `test/scripts/confine-tests.bats:47-48`, "the real unshare sits in the same directory as bash, so the ambient PATH is no use")

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:49`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container. Does not establish other images.
**Legibility-target:** for-orchestrator-synthesis

Command: `bash -c 'type -P bash sh unshare bwrap ip …'`. Output: `/usr/bin/bash`, `/usr/bin/sh`, `/usr/bin/unshare`, `/usr/sbin/ip`, and no `bwrap`.

**Evidence:** command output above (run 2026-11-10T20:26Z, cwd the worktree)

---

## Claim 18: "`$PWD` does not pass through `env -i`; a fresh bash sets it to the physical directory." (and `test/scripts/confine-tests.bats:44-46`)

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2 started under `env -i` from a symlinked directory. Does not establish other shells.
**Legibility-target:** for-orchestrator-synthesis

From `…/fcfinal-r1/pwd/link` (a symlink to `real dir`), `PWD="$PWD" env -i /usr/bin/bash -c 'echo "PWD=$PWD"'` printed `PWD=…/pwd/real dir`, the physical path, while the outer `PWD` was `…/pwd/link`. The test computes `WORK="$(cd "$T/work dir" && pwd -P)"` (`:46`).

**Evidence:** `test/scripts/confine-tests.bats:46` (command output above, exit 0)

---

## Claim 19: "A stub whose shebang is not on line 1 still runs when bash starts it (bash falls back to running the file itself) and fails when `sh` starts it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a file with a blank first line and bash syntax, started from bash and from dash. Does not establish the original draft's bug, which I did not reconstruct. dash also falls back to interpreting the file; it fails on the bash syntax.
**Legibility-target:** for-orchestrator-synthesis

The file is `''`, `#!/usr/bin/env bash`, `argv=("$@"); … ${x^^}`. Started from bash it printed `ran: AB 2` with rc=0. Started from dash it printed `./stub: 3: Syntax error: "(" unexpected` with rc=2. The `ip` stand-in is started by the `sh -c` body (`scripts/confine-tests.sh:221`), so on this host it is dash that would hit the error. That fits the stated mechanism.

**Evidence:** `LOGS/shebang.txt`, `scripts/confine-tests.sh:221`

---

## Claim 20: "bash's `exec` takes options, and takes `--` to end them. dash 0.5.12's takes neither: it runs `--` as the command."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:52` (and `:232`, "`exec -- "$@"` is not the fix: dash 0.5.12 runs `--` as the command (exit 127)")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12-2 here. Does not establish other dash versions.
**Legibility-target:** for-orchestrator-synthesis

- `dash -c 'exec -- echo hi'` → `dash: 1: exec: --: not found`, rc=127.
- `bash -c 'exec -- echo hi'` → `hi`, rc=0.
- `dash -c 'exec -c echo hi'` → `exec: -c: not found`, rc=127.
- `bash -c 'exec -a foo bash -c "echo \$0"'` → `foo`.
- `dpkg -l` shows `dash 0.5.12-2`, and `/bin/sh` resolves to `/usr/bin/dash`.

**Evidence:** `LOGS/exec.txt`

---

## Claim 21a: The health check's shellcheck gate reads `.bats` files at `-S warning`; the file-level `disable=SC2154` is the form `test/hooks/claude-config-audit.bats` uses; without it the file trips SC2154 on `$stderr_lines`

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:53`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's discovery and command, the cited form, and that the 9d37c1ac file fails the gate's command. Does not establish the count of failing `health-check.bats` tests (21b).
**Legibility-target:** for-orchestrator-synthesis

`scripts/health-check.sh:504-509` adds `.bats` files ("# Also include .bats files — they're bash", then `find "$REPO_ROOT" -type f -name '*.bats'`). `:525` runs `shellcheck -x -e SC1091 -s bash -S warning "$f"`, and a failure calls `fail "$relpath"` (`:528`). `test/hooks/claude-config-audit.bats:3` is `# shellcheck disable=SC2154  # $stderr is assigned by bats' \`run --separate-stderr\``. The same command on `git show 9d37c1ac:test/scripts/confine-tests.bats` exits 1 with `SC2154 (warning): stderr_lines is referenced but not assigned.` At HEAD it exits 0.

**Evidence:** `scripts/health-check.sh:504-528`, `test/hooks/claude-config-audit.bats:3`, `LOGS/../old/sc-old.out`, `LOGS/sc.out`

---

## Claim 21b: "the new file failed three tests in `test/scripts/health-check.bats` … only the whole suite showed it"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:53`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with the gate. Does not establish the count by a run: that needs `health-check.bats` with the 9d37c1ac file in place, which would mean changing the worktree.
**Legibility-target:** for-orchestrator-synthesis

Three tests in `test/scripts/health-check.bats` read the gate's real-repo result:

- `:55` `@test "health-check exits 0 on this repo"`;
- `:111` `@test "gate 6: shellcheck linted the repo's scripts and flagged none"`, with `[[ "$sec" != *"✗"* ]]` at `:115`;
- `:130` `@test "output ends with All checks passed"`.

A gate-6 `fail` would turn all three red, so "three" is consistent with the code. Execution was required and blocked by the one-file write rule.

**Evidence:** `test/scripts/health-check.bats:55,111-116,130`

---

## Claim 22: "Failure-pattern skip: this branch has no fix(...) commit"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:64`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four commit subjects. Does not establish whether the skip rule applies.
**Legibility-target:** for-orchestrator-synthesis

The subjects are `docs(research):` (twice) and `test:` (twice). None is a `fix(` commit.

**Evidence:** `git log a37733cc..HEAD`

---

## Claim 23: G6, "the bwrap run, the `--no-loopback` run and the unshare run each pass 12 hostile words and compare the child's argv exactly"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the word count and the three tests. Does not establish dash-named command words on the loopback unshare form (D1).
**Legibility-target:** for-orchestrator-synthesis

`TRICKY=('two words' -n --probe --no-loopback -- '' '$(touch pwned)' '`touch pwned`' '; touch pwned' '*' "it's" $'line one\nline two')` (`test/scripts/confine-tests.bats:31-32`) has 12 elements. `call child 1 "${TRICKY[@]}"` appears at `:283` (bwrap), `:327` (`--no-loopback`) and `:386` (unshare).

**Evidence:** `test/scripts/confine-tests.bats:31-32`, `:283`, `:327`, `:386`

---

## Claim 24: G10, "that the script `exec`s its primitive and the `sh` body `exec`s the command … `same_process` in the three run tests: the command's pid is the script's"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:132`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four exec sites with `sh` = dash (this host) and with `sh` linked to bash. Does not establish other `sh` implementations.
**Legibility-target:** for-author

`same_process` is called at `test/scripts/confine-tests.bats:285`, `:329` and `:388`. With this host's `sh` (dash), the sh-body mutant (`exec "$@"` → `"$@"` at `scripts/confine-tests.sh:225`) fails test 16 with "the command was not exec'd all the way" (`LOGS/mut-m18-shbody-noexec.out`). I then ran a copy of the test whose `$TOOLS/sh` links to bash. The same mutant passes all 17 tests (`LOGS/m18-shbash.out`, rc=0), because bash execs the last command of a `-c` string itself, so the pids still match. On a host whose `sh` is bash, then, the sh-body test cannot catch that `exec` being dropped. The real script passes the bash-as-`sh` copy too (`LOGS/d1-bash-bats.out`, tests 1-17 ok). A precise version: "… the `sh` body `exec`s the command (distinguishable only where `sh` does not exec a final command itself: dash yes, bash no)".

**Evidence:** `test/scripts/confine-tests.bats:151-153`, `scripts/confine-tests.sh:225`, `LOGS/mut-m18-shbody-noexec.out`, `LOGS/m18-shbash.out`

---

## Claim 25: Rollback, "`git revert -m 1 <this branch's merge commit>` removes the test file, this doc and the brief's status change. Nothing else needs undoing: `test/` is not installed by `devcontainer-config/install.sh`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:147`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the install list and the branch's file set. Does not establish the brief's status change, which per the brief exists only after the last commit; that part is true once that commit lands.
**Legibility-target:** for-author

`devcontainer-config/install.sh:146` is `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`, which leaves out `test`. So the "Nothing else needs undoing" claim holds. The revert would also remove the four `docs/reviews/*-2026-11-10-confine-tests-bats.md` reports (Claim 1), which the list leaves out. The "brief's status change" is not in the branch at 27b5e861 (`git diff --stat` touches no `docs/working/briefs/` file). That item becomes true with the final commit.

**Evidence:** `devcontainer-config/install.sh:146`, `git diff --stat a37733cc...HEAD`

---

## Claim 26: Mutation table, non-exec rows and "20 of 21 fail at least one test"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:153-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers my reconstructions of all 21 mutants from the row descriptions. Does not establish that my edits match the author's byte for byte.
**Legibility-target:** for-orchestrator-synthesis

Command: for each copy, `timeout 300 bats test/scripts/confine-tests.bats`, cwd `fcfinal-r1/mut/<name>`. Test numbers are as listed by bats (1 = neither primitive … 17 = lo cannot be raised).

| Mutant (mine) | Fails | Table says |
|---|---|---|
| no `--unshare-net` in run; no `--setenv` | 8 9 10 | the three bwrap run tests ✓ |
| command spliced into `sh` body (`exec '"${cmd[*]}" sh …`) | 16 | the unshare run test ✓ |
| refusal `exit 0`; refusal runs `"${cmd[@]}"` | 1 2 3 | two no-primitive + ambient ✓ |
| `ip` failure swallowed | 17 | ✓ |
| `-- ${cmd[@]}` unquoted | 8 | ✓ |
| bwrap failure falls back to `exec "${cmd[@]}"` | 8 9 10 | incl. run-fails (10) ✓ |
| `exec unshare -rn "${cmd[@]}"` (no `--`) | 12 15 | ✓ |
| `--no-loopback` refusal `exit 2` → `:` | 13 | ✓ |
| `ip` check removed | 15 | ✓ |
| probe without `exit 0` | 7 11 14 15 | four probe tests ✓ |
| help `awk` without `{exit}` | 6 | ✓ |
| unknown flag → `shift` | 4 | ✓ |
| empty-command `exit 2` → `:` | 5 | ✓ |
| `--no-loopback` warning removed | 11 12 | ✓ |

My first splice attempt left an unbalanced quote and also failed 12, 15 and 17. The corrected splice (`m03b`) fails 16 only, as the table says. Counting with the exec and set-e rows: 21 mutants, 20 caught.

**Evidence:** `LOGS/mut-summary.txt`, `LOGS/mut-m03b-spliced-body.out`, `LOGS/mut-*.out`, `fcfinal-r1/mutate.py`

---

## Claim 27: "`exec` replaced by a plain call, in each of four places … fails the run test of that form, through `same_process` (added in the review loop; before it, the `sh` body mutant survived, which pass 1's fact-check found)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two constructions of each exec mutant (bare `exec` removal; removal plus `exit $?`), run against the HEAD test and the 9d37c1ac test, with `sh` = dash. Does not establish the author's exact edits.
**Legibility-target:** for-author

At HEAD every exec mutant fails the run test of its form: bwrap → 8, sh body → 16, `unshare … sh -c` → 16, direct `unshare` → 12. The mechanism differs by construction:

- Bare removal at the bwrap site (`m17a`) falls through to the unshare `exec` and fails at `confine` with an unexpected `ip` call.
- Bare removal at the `unshare … sh -c` site (`m19a`) falls through to line 227 and fails at `calls child 1`.
- Only the sh-body mutant, the direct-`unshare` mutant and the `exit $?` variants fail through `same_process`.

Against the 9d37c1ac test (before `same_process`), these mutants pass: sh body (`m18`), direct `unshare` (`m20`), and the `exit $?` variants at bwrap (`m17b`) and `unshare … sh -c` (`m19b`) (`LOGS/oldmut-summary.txt`). So the parenthetical understates the gap: the direct-`unshare` mutant survived too, not only the sh-body one. The sh-body catch is also host-dependent (Claim 24).

A precise version: "fails the run test of that form, through `same_process` where control cannot fall through (before it, the sh-body and direct-unshare mutants survived); with `sh` linked to bash the sh-body mutant still survives."

**Evidence:** `LOGS/mut-m17a-bwrap-noexec.out`, `LOGS/mut-m19a-unshare-sh-noexec.out`, `LOGS/mut-m17b-bwrap-noexec-exit.out`, `LOGS/mut-m18-shbody-noexec.out`, `LOGS/mut-m20-unshare-direct-noexec.out`, `LOGS/oldmut-summary.txt`

---

## Claim 28: "`set -euo pipefail` → `set -uo pipefail` | **nothing**" (and `:208`, "a copy of the script with `set -uo pipefail` passes every test")

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:172`, `:208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the survivor. Does not establish the "no test makes a command fail where only errexit stops the script" explanation beyond this one mutant.
**Legibility-target:** for-orchestrator-synthesis

`m21-no-errexit` passes 17 of 17 (rc=0).

**Evidence:** `LOGS/mut-m21-no-errexit.out`

---

## Claim 29: "A 22nd copy adds a warning line to every unshare run … and passes every test, as intended: the warning's absence is not pinned."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:174`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a warning inserted right after the banner (`scripts/confine-tests.sh:178`). Does not establish a warning placed before the `--no-loopback` warning, which test 12's `stderr_lines[0]` check (`test/scripts/confine-tests.bats:320`) would catch.
**Legibility-target:** for-orchestrator-synthesis

`x22-d2-warning-every-unshare-run` passes 17 of 17. The same copy against the 9d37c1ac test fails tests 12 and 16 (`LOGS/oldmut-x22-d2-warning-every-unshare-run.out`), which bears out pass 1's finding that the exact stderr match pinned D2.

**Evidence:** `LOGS/mut-x22-d2-warning-every-unshare-run.out`, `LOGS/oldmut-x22-d2-warning-every-unshare-run.out`

---

## Claim 30: Gates table, the probe, the file alone, the lint, the shellcheck command

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:180-183`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these four gates at HEAD, run 2026-11-10T20:26Z, cwd the worktree. Does not establish the whole-suite rows (Claim 31).
**Legibility-target:** for-orchestrator-synthesis

- `scripts/confine-tests.sh --probe`: exit 3.
- `timeout 300 bats test/scripts/confine-tests.bats`: exit 0, `1..17` and 17 `ok`.
- `scripts/hermeticity-lint --root .`: exit 0, first line `hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.`, matching the quote.
- `shellcheck -x -e SC1091 -s bash -S warning test/scripts/confine-tests.bats`: exit 0, the same flags as `scripts/health-check.sh:525`.

**Evidence:** `LOGS/probe.out`, `LOGS/bats.out`, `LOGS/lint.out`, `LOGS/sc.out`

---

## Claim 31: Whole-suite rows, "at 9d37c1ac **red**: 2005 pass, 3 fail, all in `test/scripts/health-check.bats`, all from SC2154 in the new file"; "at f36108e4 … exit 0: 2008 of 2008 pass … 50 report-dependent suites as NOT RUN"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:184-185` (and 27b5e861's message)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what can be checked without the 20-minute suite: arithmetic, the shellcheck cause, and which tests read the gate. Does not establish the counts, the exit status or the NOT RUN figure.
**Legibility-target:** for-orchestrator-synthesis

The numbers agree with each other (2005 + 3 = 2008, the same total at both commits). The 9d37c1ac file fails the gate's shellcheck command on SC2154 (Claim 21a), and three `health-check.bats` tests turn red on a gate-6 failure (Claim 21b). Execution required; the brief forbids the whole-suite run.

**Evidence:** `test/scripts/health-check.bats:55,111,130`, `LOGS/../old/sc-old.out`

---

## Claim 32: "`scripts/lite-review.py --range 9d37c1ac..HEAD --mode fix-drift` … 'FINDINGS: NONE'"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:186` (and 27b5e861's "The fix-commit drift check over 9d37c1ac..f36108e4 found nothing")
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the tool's dependency. Does not establish the output.
**Legibility-target:** for-orchestrator-synthesis

`scripts/lite-review.py:156-161` defines `run_claude(...)`, which runs `subprocess.run(["claude", "-p", …` with the default model `claude-haiku-4-5-20251001` (`:61`). It needs a headless model call, and this run has no network and may not call it. The range also differs between the two statements (`..HEAD` in the doc, `..f36108e4` in the commit); at the time both resolved to the same fix commit.

**Evidence:** `scripts/lite-review.py:61`, `:156-161`

---

## Claim 33: "the two unshare run tests now only require the banner to be present"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tests 12 (`--no-loopback` run) and 16 (unshare loopback run), the two that x22 broke at 9d37c1ac. Does not establish test 17, which checks only the last stderr line.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:321` is `[[ "$stderr" == *"confine-tests: denying network via unshare (loopback=0)"* ]]`, and `:382` is `[[ "$stderr" == *"confine-tests: denying network via unshare (loopback=1)"* ]]`. Test 12 also pins `stderr_lines[0]` as the forced-switch warning (`:320`), but that is not the D2 warning. x22 passes at HEAD (Claim 29).

**Evidence:** `test/scripts/confine-tests.bats:320-321`, `:380-382`, `LOGS/mut-x22-d2-warning-every-unshare-run.out`

---

## Claim 34: D1, both cases with `sh` linked to bash, and with dash

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:212-230`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both quoted cases under bash 5.2.15 and dash 0.5.12 with the test file's own stand-ins. Does not establish behaviour inside a real namespace.
**Legibility-target:** for-orchestrator-synthesis

I made a copy of the test file with `rm "$TOOLS/sh"; ln -s "$(type -P bash|dash)" "$TOOLS/sh"` and three appended dump tests, cwd `fcfinal-r1/d1-{bash,dash}`.

With bash as `sh`:
- Case 1 (`-- -record -x`): status 2; stderr `sh: line 6: exec: -r: invalid option` and `exec: usage: exec [-cl] [-a name] [command [argument ...]] [redirection ...]`, exactly as quoted.
- Case 2 (`-- -a x "$RECORD" one`): status 0, `child.1: one`, exactly as quoted.

With dash:
- Case 1: status 0, `child.1: -x`.
- Case 2: status 127, `sh: 6: exec: -a: not found`.

Both match the doc's prose. `/bin/sh` → `/usr/bin/dash` 0.5.12-2. The doc's other two forms put `--` before the command (`scripts/confine-tests.sh:210`, `:227`).

**Evidence:** `LOGS/d1-bash.txt`, `LOGS/d1-dash.txt`, `scripts/confine-tests.sh:225`

---

## Claim 35: "The security pass reports that `command -- "$@"` behaved correctly under both shells … [its observation; I did not re-run it]"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that `command --` treats a leading `-a` as the command name under both shells. Does not establish the "at the cost of the exec" part beyond the obvious, or the full fix.
**Legibility-target:** for-orchestrator-synthesis

`bash -c 'command -- "$@"' sh -a x` → `-a: command not found`, rc=127. Under dash → `-a: not found`, rc=127. Both run the named word `-a` as the command, which is the correct reading. The doc labels this attributed, and I confirm it.

**Evidence:** `LOGS/command.txt`

---

## Claim 36: "The tests pin a dash-named command on the bwrap and `--no-loopback` forms only, and dash-leading arguments (not the command name) on all three."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every use of `-record` and `TRICKY`. Does not establish anything else.
**Legibility-target:** for-orchestrator-synthesis

`-record` appears only at `test/scripts/confine-tests.bats:290` (bwrap) and `:367` (`--no-loopback`). `TRICKY`, whose words include `-n --probe --no-loopback --`, is passed on all three forms (`:274`, `:318`, `:378`).

**Evidence:** `test/scripts/confine-tests.bats:290`, `:367`, `:274`, `:318`, `:378`

---

## Claim 37: D2, the quoted output, the citation "Say so, loudly, every time" (`scripts/confine-tests.sh:132-133`), the warning only on the forced switch, "No test pins the warning's absence."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:234-243`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback run's output, the citation's line numbers, and the absence of a pinning test. Does not establish whether D2 is a defect, which is the doc's own open judgment.
**Legibility-target:** for-orchestrator-synthesis

The dump of `confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one` gives status 0 and a single stderr line, `confine-tests: denying network via unshare (loopback=1)`, as quoted (`LOGS/d1-dash.txt`, "D2 fallback"). `scripts/confine-tests.sh:132-133` reads "…lands on the real filesystem as root. Say / so, loudly, every time." The warning echoes are only inside `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]` (`:134-143`). x22 passes (Claim 29).

**Evidence:** `scripts/confine-tests.sh:132-143`, `LOGS/d1-dash.txt`, `LOGS/mut-x22-d2-warning-every-unshare-run.out`

---

## Claim 38: O1, "The probe is `--ro-bind / / --unshare-net -- true`; the run adds `--dev`, `--proc`, `--tmpfs`, `--setenv`, `--bind`, `--unshare-pid`, `--die-with-parent` and `--chdir`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two argv lists, which are complete. Does not establish what a real nested bwrap refuses.
**Legibility-target:** for-orchestrator-synthesis

The probe is `scripts/confine-tests.sh:81`. The run, `:199-210`, is `--ro-bind / / --dev /dev --proc /proc --tmpfs /tmp --setenv TMPDIR /tmp --bind "$PWD" "$PWD" --unshare-net --unshare-pid --die-with-parent --chdir "$PWD" --`. The difference is exactly the eight flags listed. The fail-closed test is test 10 (`test/scripts/confine-tests.bats:297-302`).

**Evidence:** `scripts/confine-tests.sh:81`, `:199-210`

---

## Claim 39: O3, "No primitive and no command exits 3, not 2. Detection comes before the empty-command check."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:248`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no arguments and a bare `--` in this container. Does not establish other hosts.
**Legibility-target:** for-orchestrator-synthesis

`timeout 60 scripts/confine-tests.sh` → rc=3, and `scripts/confine-tests.sh --` → rc=3. Detection is at `:115-118` and the empty check at `:171-174`.

**Evidence:** `LOGS/noargs.out`, `LOGS/dashdash.out`, `scripts/confine-tests.sh:115-118`, `:171-174`

---

## Claim 40: O4, "A command given without `--` is reported as `unknown flag: <command>`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:249`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parser's `*)` branch. Does not establish anything about wording preferences.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:65-68`, `*) echo "confine-tests: unknown flag: $1" >&2 … exit 2`, matches any non-flag word. Test 4 runs `"$RECORD" one` without `--` and gets exit 2 (`test/scripts/confine-tests.bats:229-232`).

**Evidence:** `scripts/confine-tests.sh:65-68`, `test/scripts/confine-tests.bats:229-232`

---

## Claim 41: O5, "`--bind "$PWD" "$PWD"` comes after `--ro-bind / /`, so with `PWD=/` it is `--bind / /`" [inferred; not run]

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argv order and substitution only. Does not establish bwrap's effect, which the doc itself labels inferred.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:200` is `--ro-bind / / \` and `:205` is `--bind "$PWD" "$PWD" \`, so the bind comes later in argv. With `PWD=/` the latter is `--bind / /`.

**Evidence:** `scripts/confine-tests.sh:200-205`

---

## Claim 42: Docs section, the two dated records and `guides/test-hermeticity.md`

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:256`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three cited files. Does not establish "outside this brief's Paths" (I did not read the brief's Paths).
**Legibility-target:** for-orchestrator-synthesis

- `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md:55` reads "3. **`confine-tests.sh` ships with no automated test at all**".
- `docs/working/research-2026-11-07-confine-tests-situation.md:163` reads "5. `confine-tests.sh` still has no bats case (review weak seam 3)."
- `guides/test-hermeticity.md:8` reads `Relevant paths: scripts/hermeticity-lint, scripts/hermeticity/adapters/, scripts/confine-tests.sh, test/hermeticity-lint.bats`. A grep of the guide for `confine-tests.bats` or for tests of the script finds nothing.

**Evidence:** `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md:55`, `docs/working/research-2026-11-07-confine-tests-situation.md:163`, `guides/test-hermeticity.md:8`

---

## Claim 43: Plan step sizes, "This doc … ~200 lines" and "17 tests, a new file of 395 lines at the review loop's entry"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:104-105`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the doc at a59eb11f and the test at 9d37c1ac. Step 5 (status to done, marker) is future work, true only after the last commit.
**Legibility-target:** for-orchestrator-synthesis

`git show a59eb11f:docs/…research….md | wc -l` gives 220 (~200). `git show 9d37c1ac:test/scripts/confine-tests.bats` has 395 lines and 17 `^@test` lines.

**Evidence:** `git show a59eb11f:docs/working/research-2026-11-10-confine-tests-bats.md`, `git show 9d37c1ac:test/scripts/confine-tests.bats`

---

## Claim 44: "shellcheck disable=SC2154  # bats' `run --separate-stderr` sets $stderr and $stderr_lines"

**Location:** `test/scripts/confine-tests.bats:3`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats' behaviour and the directive's need. Of the two variables, only `$stderr_lines` actually trips SC2154 here; `$stderr`'s first use is `${stderr:-}` at `:72`.
**Legibility-target:** for-orchestrator-synthesis

With line 3 removed, the gate command reports exactly one finding, `SC2154 (warning): stderr_lines is referenced but not assigned.` The tests' own use of both (`[ -z "$stderr" ]`, `${stderr_lines[0]}`) passes under bats 1.8.2, so bats sets both.

**Evidence:** `test/scripts/confine-tests.bats:3`, `:72`, `LOGS/bats.out` (no-directive check: command output above)

---

## Claim 45: Header, "Every test but one runs the script on a PATH built here: the real bash, sh, cat and awk, plus stand-ins for bwrap, unshare and ip. A stand-in creates no namespace…"

**Location:** `test/scripts/confine-tests.bats:8-14`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all 17 tests. Does not establish that `env` and `bats` themselves run off the built PATH: they run on the ambient one before `env -i`.
**Legibility-target:** for-orchestrator-synthesis

`setup()` links only `for tool in bash sh cat awk` (`:50-52`). `confine()` sets `env -i PATH="$path"` built from `$TOOLS` plus the named `stub/` directories (`:138-144`). Test 3 is the only test that calls `run` without `confine` (`:211`, `:217`). Every other test goes through `confine`, checked by grepping `@test` bodies.

**Evidence:** `test/scripts/confine-tests.bats:50-52`, `:137-146`, `:206-223`

---

## Claim 46: Header and stand-in comment, "it takes the exact argv shapes the script uses today, under a mode the test names, and any other call fails the test that made it (see confine())"; the accepted calls listed by mode; "Any other argv, and any call with the mode unset, is written to $STUB_LOG/unexpected and exits 99."

**Location:** `test/scripts/confine-tests.bats:16-18`, `:83-93`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every branch of the generated stub against the listed modes. `-rn -- COMMAND...` accepts any command words (a shape, not exact words). Does not establish strictness against real tool grammars.
**Legibility-target:** for-orchestrator-synthesis

Code against comment:

- bwrap probe: `case "$mode" in ok|run-fails) exit 0 ;; refused) exit 1 ;; esac` (`:107`).
- bwrap profile plus at least one word: `ok) … exec -- "$@"` and `run-fails) … exit 1` (`:108-112`).
- unshare probe: `ok) exit 0 ;; refused) exit 1` (`:117`).
- unshare `-rn --` with at least one word, mode `ok` only: `exec -- "$@"` (`:118-119`).
- ip: `ok) exit 0 ;; fails) … exit 1` (`:124`).

Everything else falls out of `case` to `>> "$STUB_LOG/unexpected"` and `exit 99` (`:128-129`). An unset mode is `mode="${!var:-unset}"` (`:100`), which matches no arm. Executed: mutant `m17a` makes an unexpected `ip` call, which recorded `stub ip: unexpected call under STUB_IP=unset` and failed at `confine` (`LOGS/mut-m17a-bwrap-noexec.out`).

**Evidence:** `test/scripts/confine-tests.bats:95-130`, `:145`, `LOGS/mut-m17a-bwrap-noexec.out`

---

## Claim 47: TRICKY comment, "a space, leading dashes (the script's own flags among them), an empty word, substitutions, a separator, a glob, a quote and a newline"

**Location:** `test/scripts/confine-tests.bats:28-32`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the array's 12 elements. Does not establish anything further.
**Legibility-target:** for-orchestrator-synthesis

The array holds:

- `'two words'` (a space);
- `-n --probe --no-loopback --` (leading dashes, the script's own flags among them);
- `''` (an empty word);
- `'$(touch pwned)'` and `` '`touch pwned`' `` (substitutions);
- `'; touch pwned'` (a separator);
- `'*'` (a glob);
- `"it's"` (a quote);
- `$'line one\nline two'` (a newline).

**Evidence:** `test/scripts/confine-tests.bats:31-32`

---

## Claim 48: RECORD_CALL, setup and test-command comments ("NUL after each element: an empty file is a call with no arguments, and an argument may hold a newline"; "One copy has a space in its path; one is on PATH under a name starting '-'")

**Location:** `test/scripts/confine-tests.bats:34-38`, `:53-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the recorder's format and the two command copies. Does not establish anything further.
**Legibility-target:** for-orchestrator-synthesis

`if [[ $# -gt 0 ]]; then printf "%s\0" "$@"; fi > "$STUB_LOG/$name.$n"` (`:38`) writes nothing for no arguments and `\0` for one empty word, so the two are distinct. `RECORD="$T/my cmds/record argv"` (`:42`) holds a space, and `cp "$RECORD" "$TOOLS/-record"` (`:58`) puts a copy on PATH under a dash name. The recorder ends `exit "${CHILD_EXIT:-0}"`, and tests 9, 12 and 16 see 7 come back. Teardown dumps from mutant runs show `child.1: 'two words' … '' … 'line one'$'\n''line two'` intact (`LOGS/mut-m17a-bwrap-noexec.out`).

**Evidence:** `test/scripts/confine-tests.bats:37-38`, `:42`, `:56-58`, `LOGS/mut-m17a-bwrap-noexec.out`

---

## Claim 49: teardown comment, "bats shows the failing line, not what `run` captured or the stand-ins saw"

**Location:** `test/scripts/confine-tests.bats:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats 1.8.2's default output with no `--print-output-on-failure`. Does not establish other bats options.
**Legibility-target:** for-orchestrator-synthesis

On failure, bats printed the failing command (`` `same_process' failed ``) and the test's own stdout. The status, streams and calls appear only through `teardown` (`LOGS/mut-m17a-bwrap-noexec.out` lines 5-19). Teardown returns early on success: `[[ -n "${BATS_TEST_COMPLETED:-}" ]] && return 0` (`:71`).

**Evidence:** `test/scripts/confine-tests.bats:69-81`, `LOGS/mut-m17a-bwrap-noexec.out`

---

## Claim 50a: confine() comment, "The script's pid goes to $LOG/script-pid (bash and env exec, so it is the same)"

**Location:** `test/scripts/confine-tests.bats:135-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bash → env → script (shebang `env bash`) chain. Does not establish anything beyond it.
**Legibility-target:** for-orchestrator-synthesis

`run --separate-stderr bash -c 'echo "$$" > "$1"; shift; exec "$@"' _ "$LOG/script-pid" env -i … "$SCRIPT" "$@"` (`:143-144`). `same_process` passes on the unmutated script (tests 8, 12 and 16 pass), which can only happen if the recorded pid equals the child's. That requires bash, `env`, the script and the stand-in all to exec.

**Evidence:** `test/scripts/confine-tests.bats:143-144`, `LOGS/bats.out`

---

## Claim 50b: confine() comment, "Fails the test when a stand-in refused a call."

**Location:** `test/scripts/confine-tests.bats:135`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what `confine` checks. Does not establish anything about `run`'s own status, which `confine` does not check.
**Legibility-target:** for-author

`confine` ends with `[[ ! -e "$LOG/unexpected" ]]` (`:145`), so it fails only on a call outside the stand-in's accepted shapes. A stand-in in mode `refused` also "refuses" a call: the probe arm does `refused) exit 1` (`:107`, `:117`). That refusal writes no marker and does not fail the test, and tests 2, 13 and 14 depend on it. The wording collides with the mode name. A precise version: "Fails the test when a stand-in got a call it does not accept (it wrote `$LOG/unexpected`)."

**Evidence:** `test/scripts/confine-tests.bats:107`, `:117`, `:128`, `:145`

---

## Claim 51a: same_process comment, "No step between them forked: the script execs its primitive, and its sh body execs the command. (A stand-in execs the command too…)"

**Location:** `test/scripts/confine-tests.bats:148-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's exec sites and the stand-in's `exec -- "$@"`. Does not establish that the check would see a dropped sh-body `exec` when `sh` is bash (Claim 24).
**Legibility-target:** for-orchestrator-synthesis

The script's exec sites are `exec bwrap` (`scripts/confine-tests.sh:199`), `exec unshare -rn -- sh -c` (`:220`), body `exec "$@"` (`:225`) and `exec unshare -rn --` (`:227`). The stand-in uses `exec -- "$@"` (`test/scripts/confine-tests.bats:110`, `:119`). The check passes on the real script (Claim 50a).

**Evidence:** `scripts/confine-tests.sh:199`, `:220`, `:225`, `:227`, `test/scripts/confine-tests.bats:110`, `:119`, `:151-153`

---

## Claim 51b: "(… the real bwrap forks it.)"

**Location:** `test/scripts/confine-tests.bats:150`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executable here. Does not establish real bwrap's process model.
**Legibility-target:** for-orchestrator-synthesis

There is no `bwrap` in this container (`type -P bwrap` finds nothing), so it cannot be run. The claim agrees with the profile: under `--unshare-pid` (`scripts/confine-tests.sh:207`) the command runs as a child in a new pid namespace, so its pid cannot equal the script's (paraphrased — no quote available because the source is bwrap's design, which is not in this repo). It would take one run on a host with bwrap.

**Evidence:** `scripts/confine-tests.sh:207-208`

---

## Claim 52: The 17 `@test` names and in-test comments, each against its body

**Location:** `test/scripts/confine-tests.bats:183-412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name's assertions and the in-test comments (`:193`, `:202`, `:207-210`, `:244`, `:251`, `:256`, `:280-281`, `:298`, `:339`, `:369`, `:380-381`, `:392-394`). Test 16's "then execs the command" is shown only where `sh` is dash (Claim 24). Test 6's "header comment only" is checked by sampling (first line, shebang, two later markers), not by full equality.
**Legibility-target:** for-orchestrator-synthesis

All 17 pass (`LOGS/bats.out`), and each fails under the mutant that removes what its name claims (Claim 26).

| # | Name says | Body checks |
|---|---|---|
| 1 | neither primitive, probe 3 first line, command not run | `refused 3 "$NO_PRIMITIVE"` ×2, `calls child 0`, no `pwned` |
| 2 | both refused; names what went unenforced | both probes' argv, "Your tests were NOT run.", both primitives named, `calls bwrap 2 unshare 2 child 0` |
| 3 | own PATH; a verdict; refusal runs nothing | case 0 regex / case 3 first line + `calls child 0` / `*) false` |
| 4 | unknown flag or no `--`: exit 2 before any primitive | `refused 2 …`, usage line, `calls bwrap 0 unshare 0 child 0` |
| 5 | no command: exit 2 | three arg sets, last stderr line, `calls bwrap 3 unshare 1` |
| 6 | help: header only, exit 0, no primitive | first line, no `#!`/`set -euo`/`preflight`, empty stderr, no calls |
| 7 | probe reports bwrap, nothing else, no command | stdout line, `calls unshare 0 child 0` |
| 8 | bwrap run: profile + each word | `call bwrap 2 "${PROFILE[@]}" …`, child argv, `same_process` |
| 9 | dash-named command and exit status | status 7, argv `-record -x`, child `-x` |
| 10 | run-time bwrap failure: no fallback | `status -ne 0`, `calls bwrap 2 unshare 0 child 0` |
| 11 | `--no-loopback` switch + warning, either order | both orders, stdout line, `stderr_lines[0]` warning |
| 12 | `--no-loopback` run: no sh, no ip, command after `--` | `call unshare 2 -rn -- "$RECORD" …`, `calls ip 0` |
| 13 | refused exit 2 when unshare does not work | unshare absent and refused; probe and run |
| 14 | probe reports unshare: bwrap absent or refused | both cases, `calls bwrap 1 unshare 2 ip 0` |
| 15 | unshare without ip exit 3; serves `--no-loopback` | `refused 3 "$NO_IP"` ×2, then `--no-loopback` probe and run, `calls unshare 5` |
| 16 | raises lo, execs; static body; positional words | `call ip 1 link set lo up`, `same_process`, body equality and exclusion |
| 17 | lo cannot be raised: exit 3, command not run | status 3, last stderr line, `calls ip 1 child 0` |

Test 3's comment "A real primitive that stalls ends in timeout's 124, which fails the test" holds. `timeout 60` wraps both runs (`:211`, `:217`). A 124 from the probe hits `*) false` (`:221`), and a 124 from the second run fails `[ "$status" -eq 3 ]` (`:218`). The comment at `:380-381` ("its absence is not pinned") is borne out by x22 (Claim 29).

**Evidence:** `test/scripts/confine-tests.bats:183-412`, `LOGS/bats.out`, `LOGS/mut-summary.txt`

---

## Commit messages (verdicts folded into the claims above, plus these)

The four messages were checked as follows; none earns a non-Verified verdict beyond those already listed.

- **9d37c1ac.** "17 characterization tests": 17 `^@test` at 9d37c1ac. "16 mutations … each failed by at least one test": I took the 16 non-exec, non-set-e mutants of Claim 26 and ran each against the 9d37c1ac test, and every one fails (`LOGS/oldmut-summary.txt`). That set is my reconstruction, because the message names six and says "and others". Notes: "a command whose name starts with a dash is pinned on the bwrap and --no-loopback forms only" (Claim 36).
- **f36108e4.** "20 of 21 mutants fail; set -e is the survivor" (Claims 26-28). "A9 … failing three health-check.bats tests" (Claim 21b, Unverifiable). "A1 … a copy of the script without the exec used to pass" (Claim 27: true, and for more than one site). "C2 … timeout 60" (`:211`, `:217`). "C6 … set -u in the recorder" (`:56`, `:95`). "Size: 412 code lines against a37733cc": `git diff --numstat a37733cc...HEAD -- ':(top)' ':(top,exclude)docs/'` → `412 0 test/scripts/confine-tests.bats`; the test file is identical at f36108e4 and HEAD.
- **27b5e861.** "Size: 412": as above. "The probe exits 3 here, so nothing ran confined" (Claim 6). "red on the health check's shellcheck gate": consistent (Claim 21a). The whole-suite and drift results are Claims 31 and 32 (Unverifiable).
- **a59eb11f.** "one defect found in the script (D1)": D1 is in the doc at a59eb11f, and D2 was added in f36108e4, consistent with that message's "O2 promoted to D2".

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`docs/working/research-2026-11-10-confine-tests-bats.md:5`): the branch also adds four `docs/reviews/` reports; say "one test file and this doc (plus the review reports)".
- **Claim 24** (`docs/working/research-2026-11-10-confine-tests-bats.md:132`): `same_process` catches a dropped sh-body `exec` only because this host's `sh` is dash; with `sh` linked to bash, that mutant passes all 17 tests.
- **Claim 25** (`docs/working/research-2026-11-10-confine-tests-bats.md:147`): the revert also removes the four review reports. "the brief's status change" exists only once the final commit lands.
- **Claim 27** (`docs/working/research-2026-11-10-confine-tests-bats.md:171`): before `same_process`, the direct-`unshare` exec mutant survived too, not only the sh-body one. A bare exec removal at the bwrap and `unshare … sh -c` sites fails through fall-through, not `same_process`. The sh-body catch is dash-dependent.
- **Claim 50b** (`test/scripts/confine-tests.bats:135`): "a stand-in refused a call" collides with mode `refused`, which does not fail the test; say "got a call it does not accept".

### Unverifiable
- **Claim 21b** (`docs/working/research-2026-11-10-confine-tests-bats.md:53`): "three `health-check.bats` tests fail". Consistent with the three gate-reading tests, but a run needs the 9d37c1ac file in place.
- **Claim 31** (`docs/working/research-2026-11-10-confine-tests-bats.md:184-185`): whole-suite counts (2005/3, 2008/2008, 50 NOT RUN). Internally consistent; needs the 20-minute suite.
- **Claim 32** (`docs/working/research-2026-11-10-confine-tests-bats.md:186`): the lite-review "FINDINGS: NONE" needs headless `claude -p`, and there is no network here.
- **Claim 51b** (`test/scripts/confine-tests.bats:150`): "the real bwrap forks it" needs a host with bwrap; there is none here.

Counts: 55 claim sections (52 numbers, three of them split into a/b): 46 Verified, 5 Mostly accurate, 4 Unverifiable.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/code-fact-check-report-final-r1-2026-11-10-confine-tests-bats.md, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: the whole-suite run (forbidden by the brief), the lite-review drift check (needs a network model call), a real bwrap or unshare run (none here), and the first-pass `docs/reviews/` reports (context only). The hallucination log was not updated: there are no Incorrect fabrications, and only one repo write was allowed.
- Escalate: nothing blocking. The host-dependence of `same_process` at the sh-body site (Claims 24 and 27) is worth one sentence in the research doc, or a test variant with `sh` linked to bash, if the author wants the exec pin to hold on hosts where `sh` is bash.
