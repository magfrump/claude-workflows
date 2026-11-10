Commit: 27b5e861

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-10-confine-tests-bats (branch `test/confine-tests-bats`)
**Scope:** `test/scripts/confine-tests.bats` and `docs/working/research-2026-11-10-confine-tests-bats.md` at HEAD 27b5e861, plus the four commit messages `git log a37733cc..HEAD`. Claims checked against `scripts/confine-tests.sh` (unchanged, read in full, 227 lines) and the docs they cite. The four first-pass `docs/reviews/*-2026-11-10-confine-tests-bats.md` files were not read or checked.
**Checked:** 2026-11-10
**Total claims checked:** 52
**Summary:** 41 verified, 4 mostly accurate, 1 stale, 1 incorrect, 5 unverifiable

Execution provenance: every executed command ran from a scratch copy under `$S` = `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-bats/fcfinal-r3/`, or from the worktree as stated. The repo's script was never edited. Captured output is under `$S/logs/` (the brief allows exactly one repo file, so there is no `docs/reviews/execution-logs/`). Mutants were built by `$S/mutants.py` (exact-once string replacements of a copy of the script, run against an unmodified copy of the test file; the full mutant definitions are in that file). `docs/reviews/hallucination-patterns.md` was not updated, for the same one-file reason; no Incorrect verdict below is a fabrication anyway.

Legibility-target: `for-author` on Incorrect / Stale / Mostly accurate, `for-orchestrator-synthesis` on Verified / Unverifiable.

---

## Claim 1: "this branch adds one test file and this doc"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:5`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set of files the branch adds against a37733cc; does not establish whether the review reports were meant to count.
**Legibility-target:** for-author

`git diff --stat a37733cc...HEAD` lists six added files: the test file, this doc, and four `docs/reviews/*-2026-11-10-confine-tests-bats.md` reports (the review loop's own output). The sentence leaves those four out. The precise version: "adds one test file and this doc (plus the review loop's reports under `docs/reviews/`)". Separately, the brief's status-line change is not on the branch yet. That is expected: it lands only in the final commit.

**Evidence:** `git diff --stat a37733cc...HEAD` (6 files changed, 2102 insertions)

---

## Claim 2: "Task status: in-progress (review loop: pass 1 done and its fixes made; final pass next)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch state at 27b5e861 (pass-1 fix commit f36108e4 present, this final pass running); does not establish the post-merge status.
**Legibility-target:** for-orchestrator-synthesis

The log reads `f36108e4 test: address review pass 1 ...` followed by `27b5e861 docs(research): record the gate results`, which matches. The brief still reads `Status: open` (`docs/working/briefs/2026-11-10-confine-tests-bats.md:3`). That is consistent with "in-progress".

**Evidence:** `git log --oneline a37733cc..HEAD`; `docs/working/briefs/2026-11-10-confine-tests-bats.md:3`

---

## Claim 3: "`scripts/confine-tests.sh` (227 lines, bash, `set -euo pipefail`)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count, shebang and set line; nothing further.
**Legibility-target:** for-orchestrator-synthesis

`wc -l` gives `227 scripts/confine-tests.sh`. Line 1 reads `#!/usr/bin/env bash` and line 47 reads `set -euo pipefail`.

**Evidence:** `scripts/confine-tests.sh:1`, `scripts/confine-tests.sh:47`

---

## Claim 4: "What exists" items 1-7 and their line ranges

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:14-20`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each item's described behaviour and its cited range against the script read in full; does not establish real-primitive behaviour.
**Legibility-target:** for-orchestrator-synthesis

Each item checked against the script:
- Flags, 53-71: the `while [[ $# -gt 0 ]]` loop is lines 53-71. The `*)` branch prints `confine-tests: unknown flag: $1` and the usage line, then `exit 2` (`:65-69`). It comes before `detect_primitive` (`:79`).
- Detection, 79-118: `bwrap --ro-bind / / --unshare-net -- true` (`:81`), then `unshare -rn true` (`:86`). Failure leads to `explain_unavailable; exit 3` (`:115-118`), with no probe or run distinction.
- 134-152: the `--no-loopback` block. Its `unshare -rn true` probe is at `:135`. It is the only unshare probe once bwrap is detected, because `detect_primitive` returns at `:83` before reaching `:85`. When unshare does not work the block exits 2 (`:150`).
- `ip` check, 159-163, exit 3 (`:162`). `--probe`, 165-169, `echo "confine-tests: primitive available: $primitive (loopback=$loopback)"`, exit 0.
- No command, 171-174, exit 2.
- Run, 178-227: banner at `:178`, and the three `exec` forms at `:199-210`, `:220-225` and `:227`.

**Evidence:** `scripts/confine-tests.sh:53-71`, `:79-118`, `:134-152`, `:159-163`, `:165-169`, `:171-174`, `:178-227`

---

## Claim 5: "Callers: none in code. The hermeticity lint prints its name, `guides/test-hermeticity.md` documents it"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers non-docs references outside the new test file; does not cover `archive/`.
**Legibility-target:** for-orchestrator-synthesis

`rg -n 'confine-tests' -g '!docs/**'` finds only text references:
- `scripts/hermeticity-lint:1019` contains `print("  Ground truth: scripts/confine-tests.sh -- <your test command>")`.
- `guides/test-hermeticity.md:126-127` shows the usage lines.
- `test/fixture-hermeticity.bats:15` and `CLAUDE.md:9,15` mention it in comments or prose.

No script or hook executes it.

**Evidence:** `scripts/hermeticity-lint:29,935,1019`; `guides/test-hermeticity.md:4,8,126-127`

---

## Claim 6: "the dev cycle's brief wording has each loop run `--probe`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:22`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the briefs under `docs/working/briefs/` and `skills/dev-cycle/`; does not establish what future briefs will say.
**Legibility-target:** for-author

Two briefs carry the line "Run `scripts/confine-tests.sh --probe`: on exit 0 ...": `docs/working/briefs/2026-11-10-confine-tests-bats.md:22` and `docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md:29`. The third brief in flight, `2026-11-10-cycle-overhead-numbers.md` (docs only), does not mention confine at all (0 matches). `skills/dev-cycle/` has no such template either (0 matches for `confine`). The 2026-11-07 research (`:97-106`) calls the line the brief writer's wording practice, not a template. The precise version: "the dev cycle's recent briefs that change tests carry a line to run `--probe`".

**Evidence:** `docs/working/briefs/2026-11-10-confine-tests-bats.md:22`; `docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md:29`; `docs/working/research-2026-11-07-confine-tests-situation.md:97-106`

---

## Claim 7: "In this container `scripts/confine-tests.sh --probe` exits 3 ... first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:24-26` (also the Gates row at `:180`, and commit 9d37c1ac / 27b5e861)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container at the check time; does not establish any other host.
**Legibility-target:** for-orchestrator-synthesis

Command: `timeout 60 scripts/confine-tests.sh --probe`. cwd: the worktree. Run at about 2026-11-10T20:25Z. Exit 3, and the first line matches verbatim. `type -P bwrap` is empty and `/usr/bin/unshare` is present, so unshare is installed and refused.

**Evidence:** `$S/logs/probe.txt`; `scripts/confine-tests.sh:95`

---

## Claim 8: "A stub is at least as strict as its tool (repo rule; decision log row 44, where an `iptables` stub that took any argv let a syntax error reach a live container)"; "at or under 400 changed code lines outside `docs/` (decision log row 62)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:35,37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what rows 44 and 62 say; nothing about other rows.
**Legibility-target:** for-orchestrator-synthesis

Row 44 (`docs/decisions/log.md:67`) reads: "the compound form is a syntax error, not a conjunction, and it reached a live container because the bats `iptables` stub accepted any argv". Row 62 (`:85`) reads: "Every review unit has a hard size cap of ~400 changed code lines, counted outside `docs/`".

**Evidence:** `docs/decisions/log.md:67`, `docs/decisions/log.md:85`

---

## Claim 9: "No `skip` on a repo file (decision 023). The file has no `skip` at all."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers record 023's skip-guard removal (the rule's source, as `CLAUDE.md:18` cites "record 023") and the absence of `skip` in the test file.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/023-wire-hooks-from-the-image.md:135-137` reads: "Three integration tests ... had been silently skipping on `[ -f "$REAL_AUDIT" ] || skip`. The skip guard is removed". `rg -n skip test/scripts/confine-tests.bats` returns nothing.

**Evidence:** `docs/decisions/023-wire-hooks-from-the-image.md:135-137`; `test/scripts/confine-tests.bats` (no match; paraphrased — no quote available because the claim covers absence of code)

---

## Claim 10: "The test file was 395 lines at entry and is 412 after the loop's fixes, inside the loop's re-check limit of about 800 (`workflows/review-fix-loop.md`, size re-check)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:37` (also plan step 2 at `:105`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 9d37c1ac and HEAD and the source of the ~800 limit.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat a37733cc 9d37c1ac -- ':(top)' ':(top,exclude)docs/'` gives `395 0 test/scripts/confine-tests.bats`. Against HEAD it gives `412 0`. `workflows/review-fix-loop.md:57` reads: "The unit's limit is ~800 lines (twice the entry cap) until a waiver sets another."

**Evidence:** `workflows/review-fix-loop.md:55-57`; commands run in the worktree, output quoted here

---

## Claim 11: "`test/scripts/run-tests.bats`: runs a script under `env -i PATH=...`, and (line 490) builds a PATH directory of symlinks to leave one tool out"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:41`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited test; line 490 is its `@test` line, and the symlink loop follows at 494-499.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/run-tests.bats:490` reads `@test "--jobs without GNU parallel on PATH warns and runs serially" {`, and `:499` reads `[[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"`. `:66` reads `run env -i PATH="$path" ...`.

**Evidence:** `test/scripts/run-tests.bats:66`, `:490-499`

---

## Claim 12: "`test/scripts/build-loop-orchestrator.bats`: `bats_require_minimum_version 1.5.0` and `run --separate-stderr`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:42`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both constructs' presence.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/build-loop-orchestrator.bats:7` reads `bats_require_minimum_version 1.5.0`, and `:12` reads `bl() { run --separate-stderr bash "$BL" "$@"; }`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:7,12`

---

## Claim 13: "Decision 018 ... names `scripts/confine-tests.sh:220` as the reference for 'static shell body, values as positional arguments'"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and that line 220 opens that body.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43` reads: "(`scripts/confine-tests.sh:220` is the reference for this pattern.)". `:117` reads: "`scripts/confine-tests.sh:220` — reference argv-passthrough pattern." `scripts/confine-tests.sh:220` reads `exec unshare -rn -- sh -c '`.

**Evidence:** `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`; `scripts/confine-tests.sh:220-225`

---

## Claim 14: Failure-pattern grep yields "FP-050, FP-052, FP-058, FP-065, FP-076, FP-155", and the six descriptions

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:47,57-62`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep's ID set and each description against its entry; does not cover the "a test pins" parts, which Claims 41-49 cover.
**Legibility-target:** for-orchestrator-synthesis

Command: the quoted `grep -inE '...' docs/failure-patterns.md | grep -oE 'FP-[0-9]+' | sort -u`. cwd: the worktree. Exit 0. Output: `FP-050 FP-052 FP-058 FP-065 FP-076 FP-155`. The entries match their descriptions:
- `:192` is `symptom:unshare-tier-shares-host-mount-namespace-host-writes`.
- `:194` is `confine-blocks-all-writes-crashing-matplotlib-font-cache`.
- `:200` is `bwrap-runtime-failure-drops-the-computation-silently`.
- `:207` is `hardcoded-artifact-path-makes-suite-skip-not-fail`.
- `:218` is `headless-read-confined-to-cwd-critic-briefs-blocked`.
- `:297` is `four-document-link-cycle-between-stub-and-spec`.

**Evidence:** `docs/failure-patterns.md:192,194,200,207,218,297` (output quoted inline)

---

## Claim 15: "FP-050 ...: the script warns about this only when `--no-loopback` forces the switch. See observation O2."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:60`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cross-reference only. The behaviour stated before it is correct (Claim 44).
**Legibility-target:** for-author

The doc has no O2 any more. `:252` reads "(There is no O2: it became D2 in the review.)". At a59eb11f, O2 existed: line 190 of that version reads "**O2. A plain fallback to unshare prints no warning.**". The reference should read "See defect D2."

**Evidence:** `docs/working/research-2026-11-10-confine-tests-bats.md:60,234,252`; `git show a59eb11f:docs/working/research-2026-11-10-confine-tests-bats.md` line 190

---

## Claim 16: "The real `unshare` is in `/usr/bin`, beside `bash`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:49` (also `test/scripts/confine-tests.bats:47-48`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This container only.
**Legibility-target:** for-orchestrator-synthesis

`bash -c 'type -P unshare bash'` prints `/usr/bin/unshare` and `/usr/bin/bash`. Run at about 2026-11-10T20:25Z, exit 0. No log file was written; the output is quoted here.

**Evidence:** command output quoted inline

---

## Claim 17: "`$PWD` does not pass through `env -i`; a fresh bash sets it to the physical directory."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:50` (also `test/scripts/confine-tests.bats:44-46`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 started under `env -i` in a directory reached through a symlink.
**Legibility-target:** for-orchestrator-synthesis

From `$S/pwdtest/link` (a symlink to `real`): the logical `$PWD` is `.../link`, `env -i /usr/bin/bash -c 'echo $PWD'` prints `.../real`, and `env -i env` has 0 PWD lines. Run 2026-11-10T20:35:36Z, exit 0.

**Evidence:** `$S/logs/pwd.txt`

---

## Claim 18: "A stub whose shebang is not on line 1 still runs when bash starts it (bash falls back to running the file itself) and fails when `sh` starts it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a bash-syntax stub with a blank first line, started by bash 5.2.15 and by dash 0.5.12. dash also runs the file itself, and fails on the bash syntax, not on the exec.
**Legibility-target:** for-orchestrator-synthesis

Under bash the stub ran (`ran as bash-ish: b`, rc 0). Under dash it failed with `stub: 3: Syntax error: "(" unexpected`, rc 2. Run 2026-11-10T20:35:36Z.

**Evidence:** `$S/logs/shebang.txt`

---

## Claim 19: "bash's `exec` takes options, and takes `--` to end them. dash 0.5.12's takes neither: it runs `--` as the command."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:52` (also D1 at `:212,232`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12-2 (the container's `/bin/sh -> dash`); does not cover other dash versions.
**Legibility-target:** for-orchestrator-synthesis

Results:
- `dash -c 'exec -- echo hi'` prints `dash: 1: exec: --: not found`, rc 127.
- `bash -c 'exec -- echo hi'` prints `hi`, rc 0.
- `dash -c 'exec -a x echo hi'` gives rc 127, and bash gives rc 0.
- `command -- echo hi` gives rc 0 in both shells. This also confirms the security pass's observation that D1 quotes at `:232`.

Run 2026-11-10T20:35:36Z.

**Evidence:** `$S/logs/exec.txt`

---

## Claim 20a: The health check runs `shellcheck -S warning` over `.bats` files (`check_shellcheck`); shellcheck cannot see that bats sets `$stderr_lines`; `test/hooks/claude-config-audit.bats` uses the same file-level form; without it three `test/scripts/health-check.bats` tests fail

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:53` (also Gates row `:183-184`, and commit f36108e4 "A9")
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's file discovery and command, shellcheck's verdict on the file at 9d37c1ac and at HEAD, and that the health-check.bats tests reading gate 6 are exactly three. Whether those three were the ones that failed in the logged whole-suite run is Claim 31.
**Legibility-target:** for-orchestrator-synthesis

`scripts/health-check.sh:474` reads `check_shellcheck() {`. The gate collects `.bats` files (`find "$REPO_ROOT" -type f -name '*.bats'`) and runs `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`:525`). With shellcheck 0.9.0:
- The file at 9d37c1ac gets `SC2154 (warning): stderr_lines is referenced but not assigned.` and rc 1.
- The file at HEAD gets rc 0.

Run 2026-11-10T20:35:36Z. `test/hooks/claude-config-audit.bats:3` reads `# shellcheck disable=SC2154  # $stderr is assigned by bats' \`run --separate-stderr\``. The cached full-health-check tests in `test/scripts/health-check.bats` that a gate-6 ✗ breaks are `health-check exits 0` (`:55`), `gate 6: ... flagged none` (`:111-116`) and `output ends with All checks passed` (`:130-132`). That makes three.

**Evidence:** `scripts/health-check.sh:474-531`; `test/hooks/claude-config-audit.bats:3`; `test/scripts/health-check.bats:55-58,111-116,130-132`; `$S/logs/shellcheck.txt`

---

## Claim 20b: "The file alone, the lint and the mutation run all passed; only the whole suite showed it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:53`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the standalone shellcheck gate would have shown at 9d37c1ac; does not establish which gates were actually run at that commit.
**Legibility-target:** for-orchestrator-synthesis

This is a history claim about which gates ran when. One thing is checkable: the standalone shellcheck command that plan step 3 lists (`:106`) does flag the 9d37c1ac file, rc 1 (`$S/logs/shellcheck.txt`). So "only the whole suite showed it" holds only if that gate was not run on 9d37c1ac before the whole suite. Confirming that would need the build loop's run log.

**Evidence:** `$S/logs/shellcheck.txt`; `docs/working/research-2026-11-10-confine-tests-bats.md:106`

---

## Claim 21: "Failure-pattern skip: this branch has no fix(...) commit"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:64`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four commit subjects.
**Legibility-target:** for-orchestrator-synthesis

The four subjects begin `docs(research):`, `test:`, `test:` and `docs(research):`.

**Evidence:** `git log --oneline a37733cc..HEAD`

---

## Claim 22: Plan steps and sizes: "This doc ... ~200 lines"; "17 tests, a new file of 395 lines at the review loop's entry"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:104-105`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sizes at the commits that made them (a59eb11f, 9d37c1ac) and the test count.
**Legibility-target:** for-orchestrator-synthesis

The doc was 220 lines at a59eb11f, which fits "~200". The test file was 395 lines at 9d37c1ac. `bats` prints `1..17`.

**Evidence:** `git show a59eb11f:docs/working/research-2026-11-10-confine-tests-bats.md | wc -l` printed 220; `$S/logs/bats-file.txt`

---

## Claim 23: "`/pre-mortem`: not triggered (no enforcement file, no trust boundary changed, under 500 lines)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:115`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the enforcement-file regex and the size; "trust boundary" is a judgment and was not checked.
**Legibility-target:** for-orchestrator-synthesis

`hooks/live-verify-gate.sh:83` defines the enforcement set as `'^devcontainer-config/(Dockerfile|devcontainer\.json|...|egress/)'`, which no `test/` path matches. 412 is under 500.

**Evidence:** `hooks/live-verify-gate.sh:83`

---

## Claim 24: G6: "the bwrap run, the `--no-loopback` run and the unshare run each pass 12 hostile words and compare the child's argv exactly"; G8 "three tests"; G9 "four tests"; G10 "`same_process` in the three run tests"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:128-132`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts and their mapping to tests; whether `same_process` detects each exec is Claim 27a.
**Legibility-target:** for-orchestrator-synthesis

`TRICKY` (`test/scripts/confine-tests.bats:31-32`) has 12 elements. `call child 1 "${TRICKY[@]}"` appears at `:283`, `:327` and `:386`, in tests 8, 12 and 16. The G8 tests are 11, 12 and 13. The G9 tests are 14, 15, 16 and 17. `same_process` is called at `:285`, `:329` and `:388`.

**Evidence:** `test/scripts/confine-tests.bats:31-32,283-285,327-329,386-388`

---

## Claim 25: Rollback: "`git revert -m 1 <merge>` removes the test file, this doc and the brief's status change ... `test/` is not installed by `devcontainer-config/install.sh`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:147`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers install.sh's payload lists. "the brief's status change" is true only once the final commit exists. The revert would also remove the four `docs/reviews/` reports; the sentence does not name them, which does not affect its point.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/install.sh:146` reads `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`, and `:121` reads `PAYLOAD=(devcontainer.json Dockerfile ... egress claude-home)`. Neither list includes `test/`.

**Evidence:** `devcontainer-config/install.sh:121,146`

---

## Claim 26: Mutation table: "20 of 21 fail at least one test", each non-exec row's named failing tests, and that "`set -euo pipefail` → `set -uo pipefail`" fails nothing

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:153-172,208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 21 mutants rebuilt from the table's descriptions (my construction of each, in `$S/mutants.py`; the author's exact edits are not recorded) against the HEAD test file. The exec rows' stated mechanism is Claim 27a.
**Legibility-target:** for-orchestrator-synthesis

Command: `timeout 580 python3 -I mutants.py`. cwd: `$S`. Started 2026-11-10T20:28:22Z, exit 0. Results by test number:
- no `--unshare-net`: 8 9 10. No `--setenv`: 8 9 10. These are the three bwrap run tests.
- spliced body: 16.
- refusal exits 0: 1 2 3. Refusal runs the command: 1 2 3.
- `ip` failure swallowed: 17.
- unquoted bwrap command: 8.
- bwrap fallback: 8 9 10 (10 is the run-fails test).
- unshare without `--`: 12 15.
- `--no-loopback` falls through to bwrap: 13.
- `ip` check removed: 15.
- `--probe` runs on: 7 11 14 15, which is four probe tests.
- `--help` prints every comment: 6.
- unknown flag skipped: 4.
- empty command run: 5.
- warning removed: 11 12.
- the four exec mutants: 8, 16, 16, 12.
- `set -uo pipefail`: rc 0, NONE.

That is 20 of 21 failing, and every row's named tests match.

**Evidence:** `$S/logs/mutants-summary.txt`, `$S/logs/m2-*.txt`, `$S/mutants.py`

---

## Claim 27a: "`exec` replaced by a plain call, in each of four places ... | the run test of that form, through `same_process`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four literal exec-to-plain-call mutants against the HEAD file, plus two variants that add `exit $?` after the plain call; does not cover other exec spellings.
**Legibility-target:** for-author

Each mutant does fail the run test of its form: bwrap fails 8, the `sh` body fails 16, `unshare ... sh -c` fails 16, and `unshare` direct fails 12. Only two of the four fail *through* `same_process`, though:
- The `sh` body and `unshare` direct mutants fail at `same_process` ("the command was not exec'd all the way").
- The bwrap mutant fails at `confine` (`test/scripts/confine-tests.bats:145`). Once the plain `bwrap` returns 0, the script falls through to `exec unshare -rn -- sh -c ...`, whose `ip` stand-in has no mode set, so the call is written to `unexpected`.
- The `unshare ... sh -c` mutant fails at `calls child 1` (`:385`). When the plain call returns, the script falls through to `:227` and runs the command a second time.

Both of those fail even with `same_process` removed from the test file (`$S/logs/nosp-exec-bwrap.txt` fails 8, and `$S/logs/nosp-exec-unshare-sh.txt` fails 16). `same_process` can still detect them. With `exit $?` added after the plain call so there is no fall-through, both fail at `same_process` (`plain-bwrap-exit` fails 8 and `plain-unshare-sh-exit` fails 16, `same_process' failed). So the answer to brief question 2, whether `same_process` distinguishes exec from a plain call at all four sites, is yes. The table's stated mechanism is right for two of the four literal mutants only. The precise version: "the run test of that form (the `sh` body and direct `unshare` mutants through `same_process`; the other two through the fall-through that follows a returning call)".

**Evidence:** `$S/logs/m2-exec-*.txt`; `$S/logs/mut-exec-*.txt`; `$S/logs/nosp-*.txt`; `$S/logs/mut-plain-*-exit.txt`; `scripts/confine-tests.sh:199,211-227`

---

## Claim 27b: "(added in the review loop; before it, the `sh` body mutant survived, which pass 1's fact-check found)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four exec mutants against the 9d37c1ac test file (before `same_process`); does not check what pass 1's report says (out of scope).
**Legibility-target:** for-author

Against `git show 9d37c1ac:test/scripts/confine-tests.bats`, the `sh` body mutant passes every test (rc 0). The direct `--no-loopback` `unshare` mutant also passes every test (rc 0). The bwrap and `unshare ... sh -c` mutants fail (8 and 16). Two mutants survived before `same_process`, not one. The precise version: "the `sh` body and the direct `unshare` mutants survived".

**Evidence:** `$S/logs/m9d-summary.txt` (run 2026-11-10T20:33:36Z, cwd `$S/m9d/<name>`)

---

## Claim 28: "A 22nd copy adds a warning line to every unshare run ... and passes every test ... the warning's absence is not pinned"; also D2's "No test pins the warning's absence" and the test-16 comment

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:174,207,243`; `test/scripts/confine-tests.bats:380-382`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a copy that adds `confine-tests: WARNING — unshare denies the network and nothing else.` after the banner on every unshare run; does not cover a warning placed before the banner, though the substring match would accept that too.
**Legibility-target:** for-orchestrator-synthesis

The `d2-warning-every-unshare` mutant passes all 17 at HEAD (rc 0). Against 9d37c1ac it fails 12 and 16, which confirms that the exact-stderr matches there did pin the absence.

**Evidence:** `$S/logs/m2-d2-warning-every-unshare.txt`; `$S/logs/m9d-d2-warning-every-unshare.txt`

---

## Claim 29: Gates: "`timeout 300 bats test/scripts/confine-tests.bats` | 17 of 17 pass"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD in this container.
**Legibility-target:** for-orchestrator-synthesis

Command run in the worktree at 2026-11-10T20:25:31Z: rc 0, `1..17`, all `ok`.

**Evidence:** `$S/logs/bats-file.txt`

---

## Claim 30: Gates: "`scripts/hermeticity-lint --root .` | exit 0: '143 test file(s) checked, no unstubbed network spawns'" and the shellcheck row "exit 0"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:182-183`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD at check time.
**Legibility-target:** for-orchestrator-synthesis

The lint gave rc 0 and printed `hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.` (run 2026-11-10T20:31:23Z, worktree). The shellcheck command gave rc 0 at HEAD (2026-11-10T20:35:36Z).

**Evidence:** `$S/logs/lint.txt`; `$S/logs/shellcheck.txt`

---

## Claim 31: Gates: "`scripts/run-tests.sh` (whole suite, serial) at 9d37c1ac | red: 2005 pass, 3 fail, all in `test/scripts/health-check.bats`, all from SC2154"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:184` (and commit 27b5e861)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers consistency only: shellcheck flags the 9d37c1ac file, and exactly three health-check.bats tests depend on gate 6. Does not establish the counts 2005 and 3.
**Legibility-target:** for-orchestrator-synthesis

The whole suite was not run (the brief's 20-minute cost). What could be checked is consistent: SC2154 at 9d37c1ac, and the three gate-6-dependent tests (Claim 20a). 2005+3 = 2008 matches the next row. The narrower run (`scripts/run-tests.sh test/scripts/health-check.bats test/scripts/confine-tests.bats`) printed `another run-tests.sh run is in progress in this checkout` and exited 1. Per the brief, I did not wait.

**Evidence:** `$S/logs/shellcheck.txt`; `$S/logs/run-tests-2.txt`

---

## Claim 32: Gates: "at f36108e4, after the fix | exit 0: 2008 of 2008 pass ... 50 report-dependent suites as NOT RUN"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:185` (and commit 27b5e861)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Does not establish the counts or the exit; needs a whole-suite run.
**Legibility-target:** for-orchestrator-synthesis

Not run (20-minute suite; the narrower run was refused by another session's lock, `$S/logs/run-tests-2.txt`). f36108e4 and HEAD have the same test file (27b5e861 changes only the research doc), and at HEAD shellcheck passes.

**Evidence:** `git diff --stat f36108e4 27b5e861` (1 file: the research doc)

---

## Claim 33: Gates: "`scripts/lite-review.py --range 9d37c1ac..HEAD --mode fix-drift` | 'FINDINGS: NONE'"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:186` (and commit 27b5e861 "over 9d37c1ac..f36108e4 found nothing")
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers that the tool and mode exist; does not establish the output.
**Legibility-target:** for-orchestrator-synthesis

`scripts/lite-review.py:11` documents `--mode fix-drift`, and it calls headless `claude -p` (`:156-161`). That cannot run here (no network, and the brief forbids network). The two range spellings agree if HEAD was f36108e4 when the check ran, which fits 27b5e861 recording it.

**Evidence:** `scripts/lite-review.py:11,156-161`

---

## Claim 34: D1's two failing cases with `sh` linked to bash, and the dash outcomes ("exits 0 and the command receives `-x`"; "exits 127 (`exec: -a: not found`)")

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:214-230`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test file's stand-ins with `$TOOLS/sh` linked to bash 5.2.15 or to dash 0.5.12, using a scratch copy of the test with one added `SH_AS` switch; does not cover a real `unshare`.
**Legibility-target:** for-orchestrator-synthesis

Command: `SH_AS=$sh timeout 120 bats -f D1 test/scripts/confine-tests.bats`. cwd: `$S/d1`. Run at about 2026-11-10T20:27Z.
- sh as bash, case 1: status 2, stderr `sh: line 6: exec: -r: invalid option` and the usage line, as quoted.
- sh as bash, case 2: status 0, `child.1: one`, as quoted.
- sh as dash, case 1: status 0, `child.1: -x`.
- sh as dash, case 2: status 127, `sh: 6: exec: -a: not found`.

**Evidence:** `$S/logs/d1.txt`; `scripts/confine-tests.sh:220-225`

---

## Claim 35: D1: "The other two run forms put `--` before the command"; "The tests pin a dash-named command on the bwrap and `--no-loopback` forms only, and dash-leading arguments ... on all three"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:212,232`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script lines and the test bodies.
**Legibility-target:** for-orchestrator-synthesis

The script has `-- "${cmd[@]}"` at `scripts/confine-tests.sh:210` and `exec unshare -rn -- "${cmd[@]}"` at `:227`. `-record -x` appears in test 9 (`test/scripts/confine-tests.bats:290`, bwrap) and test 15 (`:367`, `--no-loopback`). `TRICKY` (with `-n`, `--probe`) is passed on all three forms (Claim 24).

**Evidence:** `scripts/confine-tests.sh:210,227`; `test/scripts/confine-tests.bats:290,367`

---

## Claim 36: D2: the quoted output for a plain unshare fallback, and the citation "Say so, loudly, every time" (`scripts/confine-tests.sh:132-133`)

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:234-241`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-in run and the cited comment; whether D2 is a defect is a judgment and was not verdicted.
**Legibility-target:** for-orchestrator-synthesis

The copy's `D2 plain fallback` test gave status 0, stderr exactly `confine-tests: denying network via unshare (loopback=1)`, and `child.1: one` (cwd `$S/d1`, at about 2026-11-10T20:34Z). `scripts/confine-tests.sh:132-133` reads "bwrap would have refused with EROFS lands on the real filesystem as root. Say / # so, loudly, every time." The warning echoes exist only inside `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]` (`:134-143`).

**Evidence:** `$S/logs/d2-o3-o4.txt`; `scripts/confine-tests.sh:132-143`

---

## Claim 37: O1: "The probe is `--ro-bind / / --unshare-net -- true`; the run adds `--dev`, `--proc`, `--tmpfs`, `--setenv`, `--bind`, `--unshare-pid`, `--die-with-parent` and `--chdir` ... It fails closed, and a test pins that."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two argv lists and test 10; does not establish real bwrap behaviour in a nested sandbox.
**Legibility-target:** for-orchestrator-synthesis

`:81` reads `bwrap --ro-bind / / --unshare-net -- true`. `:199-210` adds exactly the listed flags. Test 10 (`test/scripts/confine-tests.bats:297-302`) asserts `[ "$status" -ne 0 ]` and `calls bwrap 2 unshare 0 child 0`.

**Evidence:** `scripts/confine-tests.sh:81,199-210`; `test/scripts/confine-tests.bats:297-302`

---

## Claim 38: O3: "No primitive and no command exits 3, not 2." O4: "A command given without `--` is reported as `unknown flag: <command>`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:248-249`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-in runs.
**Legibility-target:** for-orchestrator-synthesis

O3: `confine "" --` gave status 3 with first line `NO CONFINEMENT PRIMITIVE AVAILABLE`, because detection (`:115`) comes before the empty-command check (`:171`). O4: `"$RECORD" one` without `--` gave status 2 and `confine-tests: unknown flag: /tmp/bats-run-.../my cmds/record argv`.

**Evidence:** `$S/logs/d2-o3-o4.txt`; `scripts/confine-tests.sh:65-69,115-118,171-174`

---

## Claim 39: O5: "`--bind "$PWD" "$PWD"` comes after `--ro-bind / /`, so with `PWD=/` it is `--bind / /`" [inferred]

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argv order only. The doc's inference that this undoes the read-only root needs a real bwrap and is labelled as not run, so it is not verdicted.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:200` reads `--ro-bind / / \` and `:205` reads `--bind "$PWD" "$PWD" \`, in that order.

**Evidence:** `scripts/confine-tests.sh:199-210`

---

## Claim 40: Docs section: the two dated records "say it had no test"; `guides/test-hermeticity.md` "lists `test/hermeticity-lint.bats` under its relevant paths and says nothing about tests of this script"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:256`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited sections.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/review-fix-loop-polyglot-test-hermeticity.md:55` reads: "3. **`confine-tests.sh` ships with no automated test at all**". `docs/working/research-2026-11-07-confine-tests-situation.md:163` reads: "5. `confine-tests.sh` still has no bats case (review weak seam 3)." `guides/test-hermeticity.md:8` reads "Relevant paths: scripts/hermeticity-lint, ..., scripts/confine-tests.sh, test/hermeticity-lint.bats". It has no match for a test of this script.

**Evidence:** the three cited lines

---

## Claim 41: Shellcheck directive reason: "bats' `run --separate-stderr` sets $stderr and $stderr_lines"

**Location:** `test/scripts/confine-tests.bats:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bats-core 1.8.2 as installed.
**Legibility-target:** for-orchestrator-synthesis

`/usr/lib/bats-core/test_functions.bash:236` reads `separate) # splits stderr into own file and fills $stderr/$stderr_lines too`, and `:267` reads `bats_separate_lines stderr_lines stderr`.

**Evidence:** `/usr/lib/bats-core/test_functions.bash:236,267`

---

## Claim 42: "Every test but one runs the script on a PATH built here: the real bash, sh, cat and awk, plus stand-ins for bwrap, unshare and ip"; "the real unshare sits in the same directory as bash ... The real tools the script and the stand-ins need, and no others"

**Location:** `test/scripts/confine-tests.bats:8-10,47-52`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 17 tests' use of `confine()` and that the script and stand-ins call no other PATH tool.
**Legibility-target:** for-orchestrator-synthesis

16 tests call `confine`. Test 3 uses `run ... timeout 60 "$SCRIPT"` on the ambient PATH (`:211,217`). `setup()` links only `bash sh cat awk` (`:50-52`). The script's external calls are `awk` (`:62`), `cat` (`:94`), the primitives, `ip` and `sh`. The stand-ins' shebang `#!/usr/bin/env bash` resolves env by absolute path. All 17 pass with this PATH (Claim 29).

**Evidence:** `test/scripts/confine-tests.bats:47-52,137-146,211,217`; `scripts/confine-tests.sh:62,94`

---

## Claim 43: "it takes the exact argv shapes the script uses today, under a mode the test names, and any other call fails the test that made it (see confine())"

**Location:** `test/scripts/confine-tests.bats:16-18`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers calls made inside a `confine` run (all stub calls); does not cover test 3, which has no stand-ins.
**Legibility-target:** for-orchestrator-synthesis

Every non-accepted path in the stub ends at `printf 'stub %s: unexpected call ...' >> "$STUB_LOG/unexpected"` and `exit 99` (`:128-129`). `confine` ends with `[[ ! -e "$LOG/unexpected" ]]` (`:145`). Observed: in the exec-bwrap mutant, test 8 fails at `confine' ... line 145` on an `ip` call with `STUB_IP` unset (`$S/logs/mut-exec-bwrap.txt`). The same happens for the no-`--unshare-net` and no-`--setenv` mutants (`$S/logs/m2-no-unshare-net.txt`).

**Evidence:** `test/scripts/confine-tests.bats:128-129,145`; the logs named

---

## Claim 44: TRICKY comment ("a space, leading dashes (the script's own flags among them), an empty word, substitutions, a separator, a glob, a quote and a newline"); RECORD_CALL comment (one file per call, NUL after each element, empty file = no args); test-command comment (records argv as "child" and its pid, exits $CHILD_EXIT; one copy has a space in its path, one is on PATH under a name starting "-")

**Location:** `test/scripts/confine-tests.bats:28-38,53-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed element against the code.
**Legibility-target:** for-orchestrator-synthesis

`TRICKY` holds `'two words' -n --probe --no-loopback -- '' '$(touch pwned)' '\`touch pwned\`' '; touch pwned' '*' "it's" $'line one\nline two'`. `RECORD_CALL` picks the first free `$name.$n`, then runs `if [[ $# -gt 0 ]]; then printf "%s\0" "$@"; fi > "$STUB_LOG/$name.$n"`. The recorder sets `name=child`, writes `echo "$$" > "$STUB_LOG/child-pid"` and runs `exit "${CHILD_EXIT:-0}"`. `RECORD="$T/my cmds/record argv"`, and `cp "$RECORD" "$TOOLS/-record"`.

**Evidence:** `test/scripts/confine-tests.bats:31-32,37-38,42,56-58`

---

## Claim 45: setup's PROFILE comment "The profile the script hands bwrap for a run; the test command follows it."

**Location:** `test/scripts/confine-tests.bats:62-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers element-by-element equality with the script's run argv.
**Legibility-target:** for-orchestrator-synthesis

`PROFILE=(--ro-bind / / --dev /dev --proc /proc --tmpfs /tmp --setenv TMPDIR /tmp --bind "$WORK" "$WORK" --unshare-net --unshare-pid --die-with-parent --chdir "$WORK" --)` matches `scripts/confine-tests.sh:199-210` element by element.

**Evidence:** `test/scripts/confine-tests.bats:63-65`; `scripts/confine-tests.sh:199-210`

---

## Claim 46: teardown comment "bats shows the failing line, not what `run` captured or the stand-ins saw."

**Location:** `test/scripts/confine-tests.bats:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats 1.8.2's failure output; `BATS_TEST_COMPLETED` is set only on success.
**Legibility-target:** for-orchestrator-synthesis

`/usr/lib/bats-core/test_functions.bash:324` sets `BATS_TEST_COMPLETED=1`. In the mutant logs, the failing-line trace is followed only by teardown's printed `status:`/`calls:` block (for example `$S/logs/m2-exec-shbody.txt`). bats itself did not print `$output`.

**Evidence:** `/usr/lib/bats-core/test_functions.bash:324`; `$S/logs/m2-exec-shbody.txt`

---

## Claim 47: Stand-in comment block: accepted calls by mode (bwrap probe: ok and run-fails succeed, refused fails; run profile: ok execs, run-fails fails; unshare probe ok/refused; `-rn -- COMMAND...`: ok execs; ip `link set lo up`: ok/fails); "Any other argv, and any call with the mode unset, is written to $STUB_LOG/unexpected and exits 99"

**Location:** `test/scripts/confine-tests.bats:83-93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the generated stub (`write_stub`, `:94-131`) branch by branch.
**Legibility-target:** for-orchestrator-synthesis

The branches:
- `:106-107`: `is --ro-bind / / --unshare-net -- true` then `case "$mode" in ok|run-fails) exit 0 ;; refused) exit 1 ;; esac`.
- `:108-112`: the profile plus at least one word, with `ok) ... exec -- "$@"` and `run-fails) ... exit 1`.
- `:116-117`: the unshare probe, ok/refused.
- `:118-119`: `[[ $# -ge 3 && "$mode" == ok ]] && is -rn -- "${@:3}"` then `exec -- "$@"`.
- `:123-124`: ip ok/fails.

Every other case falls through to `:128-129`. With `mode="${!var:-unset}"` (`:100`), no `case` arm matches `unset`.

**Evidence:** `test/scripts/confine-tests.bats:94-131`

---

## Claim 48: confine() comment: "The script's pid goes to $LOG/script-pid (bash and env exec, so it is the same)"; same_process comment: "No step between them forked: the script execs its primitive, and its sh body execs the command."

**Location:** `test/scripts/confine-tests.bats:133-136,148-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-in chain in this container (bash 5.2.15, dash 0.5.12; dash does not tail-exec the last command of the `sh -c` body). The "sh body" clause applies only to the loopback unshare form.
**Legibility-target:** for-orchestrator-synthesis

`run --separate-stderr bash -c 'echo "$$" > "$1"; shift; exec "$@"' _ "$LOG/script-pid" env -i ... "$SCRIPT"` (`:143-144`) means that bash, then env, then the script share one pid. `same_process` passes in tests 8, 12 and 16 on the real script. It fails once any of the four execs becomes a call (`$S/logs/mut-plain-*-exit.txt`, `$S/logs/m2-exec-shbody.txt`, `$S/logs/m2-exec-unshare-direct.txt`).

**Evidence:** `test/scripts/confine-tests.bats:143-144,151-153`; logs named

---

## Claim 49: same_process parenthetical: "(A stand-in execs the command too; the real bwrap forks it.)"

**Location:** `test/scripts/confine-tests.bats:150`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stand-in half (Verified: `exec -- "$@"` at `:110,119`); does not establish the real bwrap's process model.
**Legibility-target:** for-orchestrator-synthesis

The stand-in half is quoted above. The real-bwrap half is about an external tool absent here (`type -P bwrap` is empty). bwrap is commonly known to clone a child for `--unshare-pid`, but that was not run or read from source here.

**Evidence:** `test/scripts/confine-tests.bats:110,119`

---

## Claim 50: The 17 `@test` names, and in-test comments ("This container's shape: unshare is installed and the kernel refuses it"; "One probe of each per invocation"; "Probes only (one of unshare, for --no-loopback)"; "No mode is set, so any call of a stand-in would fail the test"; "The probe asks bwrap for less than the run does"; "One probe per invocation (there is no bwrap to switch from), then the run"; "BODY is the same text whatever the command ... The command's exit status comes back through sh")

**Location:** `test/scripts/confine-tests.bats:183-412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its body, plus the mutation evidence that each body detects its named property. Test 16's "raises lo, then execs" is shown as both happening; the order is not asserted directly, although test 17 shows a failed `ip` stops the command.
**Legibility-target:** for-orchestrator-synthesis

The names map to their bodies as follows. All counts were checked against the script's probe sequence.
- 1: `confine ""` (no stand-ins), `refused 3 "$NO_PRIMITIVE"`, `calls child 0`.
- 2: both stand-ins refused; checks `bwrap --unshare-net` and `unshare -rn` in stderr; `calls bwrap 2 unshare 2 child 0`, i.e. one probe of each per run.
- 4: `calls bwrap 0 unshare 0 child 0` after exit 2.
- 5: three invocations giving `bwrap 3 unshare 1`.
- 6: no mode set; `calls bwrap 0 unshare 0`.
- 7: `calls unshare 0 child 0`.
- 8: `call bwrap 2 "${PROFILE[@]}" "$RECORD" "${TRICKY[@]}"`.
- 9: status 7 with `-record`.
- 10: `-ne 0`, `unshare 0 child 0`.
- 11: both flag orders.
- 12: exact `-rn -- "$RECORD" ...`, `ip 0`.
- 13: both `bwrap` and `bwrap unshare` stand-in sets.
- 14: both bwrap shapes.
- 15: `unshare 5` = 4 probes + 1 run.
- 16: `first[4] = second[4]`, status 7 through sh.
- 17: status 3, `child 0`.

Test 2's container-shape comment matches the probe result (Claim 7). Every name's property is broken by at least one mutant that its test catches (Claim 26).

**Evidence:** `test/scripts/confine-tests.bats:183-412`; `$S/logs/mutants-summary.txt`

---

## Claim 51: Ambient-PATH test: "A real primitive that stalls ends in timeout's 124, which fails the test."

**Location:** `test/scripts/confine-tests.bats:210`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the status dispatch; a stall was not simulated.
**Legibility-target:** for-orchestrator-synthesis

`run --separate-stderr timeout 60 "$SCRIPT" --probe` is followed by `case "$status" in 0) ... ;; 3) ... ;; *) false ;; esac` (`:211-222`). A 124 status reaches `*) false`. The second run inside the `3)` arm has `[ "$status" -eq 3 ]`, which also rejects 124.

**Evidence:** `test/scripts/confine-tests.bats:211-222`

---

## Claim 52: Commit messages: 9d37c1ac "17 characterization tests" and "16 mutations ... each failed by at least one test"; f36108e4 "A9 ... failing three health-check.bats tests", "A1 ... a copy of the script without the exec used to pass", "C1: the two unshare run tests require the banner", "C2: ... timeout 60", "C6, A6: set -u in the recorder; the teardown comment", "20 of 21 mutants fail; set -e is the survivor"; "Size: 412 code lines against a37733cc" (f36108e4, 27b5e861); 27b5e861 "The whole suite at f36108e4 passes (2008 of 2008, exit 0)"

**Location:** commits 9d37c1ac, f36108e4, 27b5e861 (`git log a37733cc..HEAD`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, mutation, diff and size claims. The 27b5e861 whole-suite and drift-check results are Unverifiable (Claims 32-33). "Characterization" is loose for test 3, which the research doc labels "integration" (G3).
**Legibility-target:** for-orchestrator-synthesis

The checks:
- 17 tests (Claim 29).
- The 16 non-exec, non-`set -e` mutants, run against the 9d37c1ac test file, all fail at least one test (`$S/logs/m9d-summary.txt`, rc 1 each).
- `git diff 9d37c1ac f36108e4` adds the shellcheck directive, `same_process` in three tests, the banner substring in tests 12 and 16, `timeout 60` twice, `'set -u'` in the recorder and the reworded teardown comment.
- The exec-less mutants passed at 9d37c1ac (Claim 27b).
- 20 of 21 (Claim 26).
- `git diff --numstat a37733cc...HEAD -- ':(top)' ':(top,exclude)docs/'` gives `412 0 test/scripts/confine-tests.bats`.

**Evidence:** `git log --format=%B a37733cc..HEAD`; `git diff 9d37c1ac f36108e4 -- test/scripts/confine-tests.bats`; `$S/logs/m9d-summary.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 27a** (`docs/working/research-2026-11-10-confine-tests-bats.md:171`): the exec-to-call row says all four mutants fail "through `same_process`". Only the `sh` body and direct `unshare` mutants do. The bwrap and `unshare ... sh -c` mutants fail earlier, through the fall-through to the next exec (an unexpected `ip` call; the command run twice), and they fail with `same_process` removed too. `same_process` does catch all four once the fall-through is removed.

### Stale
- **Claim 15** (`docs/working/research-2026-11-10-confine-tests-bats.md:60`): "See observation O2." O2 became D2 (`:252`). The reference should say D2.

### Mostly Accurate
- **Claim 1** (`docs/working/research-2026-11-10-confine-tests-bats.md:5`): the branch also adds four `docs/reviews/` reports.
- **Claim 6** (`docs/working/research-2026-11-10-confine-tests-bats.md:22`): "each loop" overstates. Two of the three current briefs carry the `--probe` line (the docs-only one does not), and no dev-cycle template holds it.
- **Claim 27b** (`docs/working/research-2026-11-10-confine-tests-bats.md:171`): before `same_process`, the direct `--no-loopback` `unshare` exec mutant survived as well as the `sh` body one.

### Unverifiable
- **Claim 20b** (`docs/working/research-2026-11-10-confine-tests-bats.md:53`): "only the whole suite showed it". The standalone shellcheck gate does flag 9d37c1ac; whether it was run before the suite needs the loop's run log.
- **Claim 31** (`:184`): 2005/3 whole-suite counts at 9d37c1ac. They are consistent with shellcheck and the three gate-6 tests; confirming them needs a whole-suite run.
- **Claim 32** (`:185`, commit 27b5e861): 2008 of 2008 at f36108e4 and 50 NOT RUN. Needs a whole-suite run. The narrower run hit another session's run-tests lock.
- **Claim 33** (`:186`): lite-review "FINDINGS: NONE". Needs headless `claude` (network).
- **Claim 49** (`test/scripts/confine-tests.bats:150`): "the real bwrap forks it". Needs a real bwrap.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/code-fact-check-report-final-r3-2026-11-10-confine-tests-bats.md, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: the four first-pass `docs/reviews/*-confine-tests-bats.md` reports (context only, per brief). The whole suite (20 min, per brief). The narrower two-file `run-tests.sh` run was refused by another session's lock and not waited on. The hallucination-pattern log update and the in-repo execution-logs directory were skipped under the one-file rule; logs are in the scratch dir.
- Escalate: nothing beyond the two doc fixes (Claims 15, 27a) and three tightenings (Claims 1, 6, 27b) for the author.
