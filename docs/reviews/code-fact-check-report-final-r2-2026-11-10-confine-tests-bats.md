Commit: 27b5e861

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-2026-11-10-confine-tests-bats`)
**Scope:** branch `test/confine-tests-bats`, a37733cc..27b5e861: `test/scripts/confine-tests.bats`, `docs/working/research-2026-11-10-confine-tests-bats.md`, the four commit messages; claims checked against `scripts/confine-tests.sh` (unchanged, read in full, 227 lines). The four first-pass `docs/reviews/*-2026-11-10-confine-tests-bats.md` files are context only and were not read or checked.
**Checked:** 2026-11-10
**Total claims checked:** 42 (40 numbered; Claim 23 split into 23a-23c)
**Summary:** 34 verified, 3 mostly accurate, 1 stale, 2 incorrect, 2 unverifiable

Final confirming pass, replicate r2. `docs/reviews/hallucination-patterns.md` was consulted for suspect patterns; no claim below matches a logged pattern, and no Incorrect below is a fabrication (both are wrong attributions/universals about real tests), so the pattern log is not updated.

## Execution provenance (shared by every `executed` claim)

All runs 2026-11-10 between 20:25Z and 20:36Z. Working directory is the worktree (`W=/workspace/.claude/wt-2026-11-10-confine-tests-bats`) unless a scratch dir is named. Scratch root: `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-bats/fcfinal-r2/` (below: `$S`); captured output in `$S/logs/`.

| ID | Command | cwd | Exit | Output file |
|---|---|---|---|---|
| E1 | `timeout 300 bats test/scripts/confine-tests.bats` | W | 0 (17/17 ok) | `$S/logs/bats-head.txt` |
| E2 | `timeout 60 scripts/confine-tests.sh --probe` | W | 3 | `$S/logs/probe.txt` |
| E3 | `python3 -I $S/mut.py` (22 scratch mutants of the script, each run against the HEAD test file in `$S/m/<name>/{scripts,test/scripts}`) | `$S` | per mutant | `$S/logs/mut-summary.txt`, `$S/logs/mut-<name>.txt` |
| E4 | `python3 -I $S/mut2.py` (the four exec→plain-call mutants and a no-exit probe mutant, against the HEAD test file and against a copy whose `same_process` is `return 0`) | `$S` | per mutant | `$S/logs/mut2-summary.txt`, `$S/logs/mut2-*.txt` |
| E5 | `python3 -I $S/mut3.py` (D2 warning at selection time; plain-call bwrap / unshare-sh mutants with `; exit` appended so they cannot fall through) | `$S` | per mutant | `$S/logs/mut3-summary.txt`, `$S/logs/mut3-*.txt` |
| E6 | `python3 -I $S/mut4.py` (command spliced into the sh body via `printf %q`) | `$S` | 1 (test 16 fails) | `$S/logs/mut4-summary.txt`, `$S/logs/mut4-splice-q.txt` |
| E7 | `python3 -I $S/mut5.py` (17 of the mutants against `git show 9d37c1ac:test/scripts/confine-tests.bats`) | `$S` | per mutant | `$S/logs/mut5-summary.txt` |
| E8 | `python3 -I $S/d1.py` (copies of the test file with `$TOOLS/sh` linked to bash, then to dash; D1 cases, D2 run, O3, O4) | `$S` | 0 | `$S/logs/d1-bash.txt`, `$S/logs/d1-dash.txt` |
| E9 | `dash -c 'exec -- "$@"' sh echo hi`; `{dash,bash} -c 'command -- "$@"' sh -rec a` and `... sh -a x echo one` | `$S` | see claim 26 | inline in claim 26 (transcript of this run) |
| E10 | `timeout 120 shellcheck -x -e SC1091 -s bash -S warning test/scripts/confine-tests.bats` at HEAD, and on the 9d37c1ac copy in `$S/old/` | W, `$S/old` | 0 / 1 | `$S/logs/shellcheck-head.txt`, `$S/logs/shellcheck-9d37.txt` |
| E11 | `timeout 300 scripts/hermeticity-lint --root .` | W | 0 | `$S/logs/lint.txt` |
| E12 | `timeout 590 scripts/run-tests.sh test/scripts/health-check.bats test/scripts/confine-tests.bats` (took the lock without contention) | W | 0 (57 ok, 0 not ok) | `$S/logs/run-tests-subset.txt` |
| E13 | stub-shebang probe: a file whose line 1 is blank and line 2 `#!/usr/bin/env bash`, run from `bash -c` and `dash -c` | `$S` | bash 0, dash 2 ("Bad substitution") | inline in claim 22 |

Mutant names used below map to E3's `mut.py` dictionary (exact search/replace pairs are in that file).

---

## Claim 1: "Project state: this branch adds one test file and this doc"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:5`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file list of `git diff --stat a37733cc...HEAD`; does not establish anything about the brief file, which the last commit (not yet made) changes.
**Legibility-target:** for-author

`git diff --stat a37733cc...HEAD` lists six added files: the test file, this doc, and four `docs/reviews/*-2026-11-10-confine-tests-bats.md` review reports (fact-check 994, rubric 91, performance 101, security 220 lines). The precise version: "adds one test file, this doc and the review loop's reports". (The brief's status change will add a seventh path once the final commit exists.)

**Evidence:** `git diff --stat a37733cc...HEAD` output (this session)

---

## Claim 2: "Task status: in-progress (review loop: pass 1 done and its fixes made; final pass next)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch state at 27b5e861 (pass-1 fix commit f36108e4 exists; this is the final pass); does not establish what the line should say after the final commit.
**Legibility-target:** for-orchestrator-synthesis

`git log a37733cc..HEAD` shows `f36108e4 test: address review pass 1 ...` followed only by `27b5e861 docs(research): record the gate results`. True as of HEAD.

**Evidence:** `git log --oneline a37733cc..HEAD`

---

## Claim 3: "`scripts/confine-tests.sh` (227 lines, bash, `set -euo pipefail`)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers line count, shebang and shell options; nothing further.
**Legibility-target:** for-orchestrator-synthesis

`wc -l scripts/confine-tests.sh` → `227`. `scripts/confine-tests.sh:1` `#!/usr/bin/env bash`; `scripts/confine-tests.sh:47` `set -euo pipefail`.

**Evidence:** `scripts/confine-tests.sh:1`, `scripts/confine-tests.sh:47`

---

## Claim 4: "What exists" items 1-7 and their line ranges (Flags 53-71, Detection 79-118, `--no-loopback` over bwrap 134-152, `ip` check 159-163, `--probe` 165-169, No command 171-174, Run 178-227)

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:14-20`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each range's boundaries and the stated behaviour of each block (flag parsing before detection, detection order, the extra unshare probe being the only one when bwrap was detected, exit codes, the three run forms); does not establish behaviour of real bwrap/unshare.
**Legibility-target:** for-orchestrator-synthesis

Ranges match the script: `scripts/confine-tests.sh:53` `while [[ $# -gt 0 ]]; do` … `:71` `done`; `:79` `detect_primitive() {` … `:115-118` `if ! primitive="$(detect_primitive)"; then explain_unavailable; exit 3; fi`; `:134` `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]; then` … `:152` `fi`; `:159` `if [[ "$primitive" == "unshare" && "$loopback" -eq 1 ]] && ! command -v ip ...` … `:163` `fi`; `:165-169` the probe block ending `exit 0`; `:171-174` `nothing to run ... exit 2`; `:178` banner, `:199` `exec bwrap \`, `:220` `exec unshare -rn -- sh -c '`, `:227` `exec unshare -rn -- "${cmd[@]}"`. Item 3's "the only unshare probe when bwrap was detected": `:80-84` returns on bwrap before `:85` tries unshare, so `:135` is the only unshare probe on that path; test 11/12 (`calls bwrap 1 unshare 2` at `test/scripts/confine-tests.bats:323`, probe + run) pass (E1). Item 5 "A command given with it is not run" and item 6 "after detection": E8 O3 case (no primitive, no command) exits 3 with the refusal, and test 7 passes (E1).

**Evidence:** `scripts/confine-tests.sh:53-71`, `:79-118`, `:134-152`, `:159-163`, `:165-169`, `:171-174`, `:178-227`; `$S/logs/bats-head.txt`; `$S/logs/d1-dash.txt`

---

## Claim 5: "Callers: none in code. The hermeticity lint prints its name, `guides/test-hermeticity.md` documents it, and the dev cycle's brief wording has each loop run `--probe`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers tracked files outside `docs/` and `archive/`; does not establish callers in untracked or external repos.
**Legibility-target:** for-orchestrator-synthesis

`git grep -n confine-tests -- ':!docs' ':!archive'` hits only prose/comments outside the script and the new test: `scripts/hermeticity-lint:1019` `print("  Ground truth: scripts/confine-tests.sh -- <your test command>")`, `guides/test-hermeticity.md:126` `scripts/confine-tests.sh --probe`, `CLAUDE.md:9,15`, `test/fixture-hermeticity.bats:15` (a comment). No script invokes it. Brief wording: `docs/working/briefs/2026-11-10-confine-tests-bats.md:22` "Run `scripts/confine-tests.sh --probe`: on exit 0 ..." and the same sentence in `docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md:29`.

**Evidence:** `scripts/hermeticity-lint:29,935,1019`; `guides/test-hermeticity.md:4,8,126-127`; `docs/working/briefs/2026-11-10-confine-tests-bats.md:22`

---

## Claim 6: "In this container `scripts/confine-tests.sh --probe` exits 3 … Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:24-26` (also Gates row 1, `:180`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container at 2026-11-10T20:25Z; does not establish the verdict on a host or in the sandbox image.
**Legibility-target:** for-orchestrator-synthesis

E2: exit 3; first line `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.` (`command -v bwrap` finds nothing; `/usr/bin/unshare` and `/usr/sbin/ip` exist.)

**Evidence:** `$S/logs/probe.txt`; `scripts/confine-tests.sh:95`

---

## Claim 7: Invariants — the tests run the repo's own script through its shebang; the file spawns none of `claude`/`curl`/`gh`/`wget`, writes only under `$BATS_TEST_TMPDIR`; carries `# @category` (required by the `scripts/run-tests.sh` header); has no `skip`

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:32-36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test file's text and the lint's result; does not establish what the script under test writes on a host where a real primitive runs (test 3 on such a host only probes).
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:23` `SCRIPT="$REPO_ROOT/scripts/confine-tests.sh"`, invoked directly at `:144` and `:211`. `grep -nE 'claude|curl|\bgh\b|wget'` and `grep -nw skip` on the file: no hits. `:2` `# @category slow`; `scripts/run-tests.sh:3` `# Each .bats file must contain a "# @category fast|slow" tag comment.` E11 lint exit 0. Writes: `setup()` creates everything under `T="$BATS_TEST_TMPDIR"` (`:41-43`) and `cd "$WORK"` (`:66`); `confine` passes `HOME="$T" TMPDIR="$T"` (`:144`).

**Evidence:** `test/scripts/confine-tests.bats:2,23,41-66,144,211`; `scripts/run-tests.sh:3`; `$S/logs/lint.txt`

---

## Claim 8: "A stub is at least as strict as its tool (repo rule; decision log row 44, where an `iptables` stub that took any argv let a syntax error reach a live container)." / "No `skip` on a repo file (decision 023)."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:35-36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what row 44 and decision 023 say; does not establish that decision 023's scope is a general rule (its text is about one auditor's skip guard; CLAUDE.md generalises it as "record 023").
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/log.md:67` (row 44): "the compound form is a syntax error, not a conjunction, and it reached a live container because the bats `iptables` stub accepted any argv." `docs/decisions/023-wire-hooks-from-the-image.md:135-137`: "Three integration tests in `test/hooks/claude-config-audit.bats` had been silently skipping on `[ -f "$REAL_AUDIT" ] || skip`. The skip guard is removed". `CLAUDE.md` "Never `skip` on the presence of a file in this repo; a missing file is a failure (record 023)."

**Evidence:** `docs/decisions/log.md:67`; `docs/decisions/023-wire-hooks-from-the-image.md:135-137`

---

## Claim 9: "A review unit enters its review loop at or under 400 changed code lines outside `docs/` (decision log row 62). The test file was 395 lines at entry and is 412 after the loop's fixes, inside the loop's re-check limit of about 800 (`workflows/review-fix-loop.md`, size re-check)."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:37`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts and the two cited sources; nothing else.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/log.md:85` (row 62): "Every review unit has a hard size cap of ~400 changed code lines, counted outside `docs/`". `git show 9d37c1ac:test/scripts/confine-tests.bats | wc -l` → 395; HEAD `wc -l` → 412; `git diff --numstat a37733cc...HEAD -- ':(top)' ':(top,exclude)docs/'` → `412 0 test/scripts/confine-tests.bats`. `workflows/review-fix-loop.md:57` (section "Size re-check"): "The unit's limit is ~800 lines (twice the entry cap) until a waiver sets another."

**Evidence:** `docs/decisions/log.md:85`; `workflows/review-fix-loop.md:55-57`

---

## Claim 10: Prior art — `test/scripts/run-tests.bats` "runs a script under `env -i PATH=...`, and (line 490) builds a PATH directory of symlinks to leave one tool out"; `test/scripts/build-loop-orchestrator.bats` uses `bats_require_minimum_version 1.5.0` and `run --separate-stderr`; decision 018 names `scripts/confine-tests.sh:220`

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:41-43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited lines; "line 490" is the `@test` line of the test whose body (497-499) builds the symlink dir.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/run-tests.bats:66` `run env -i PATH="$path" HOME="$HOME" ...`; `:490` `@test "--jobs without GNU parallel on PATH warns and runs serially" {`, body `[[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"`. `test/scripts/build-loop-orchestrator.bats:7` `bats_require_minimum_version 1.5.0`, `:12` `bl() { run --separate-stderr bash "$BL" "$@"; }`. `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43` "(`scripts/confine-tests.sh:220` is the reference for this pattern.)" and `:117`; the script's `:220` is `exec unshare -rn -- sh -c '`.

**Evidence:** `test/scripts/run-tests.bats:66,490-499`; `test/scripts/build-loop-orchestrator.bats:7,12`; `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`

---

## Claim 11: "Failure-pattern grep: FP-050, FP-052, FP-058, FP-065, FP-076, FP-155" from `grep -inE 'confine|hermetic|netns|unshare|bwrap|namespace|stub|argv|shim|skip-not-fail' docs/failure-patterns.md`, and the six one-line descriptions

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:47,57-62`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep's ID set and the descriptions; does not establish the applicability judgments beyond their match to the entries' slugs.
**Legibility-target:** for-orchestrator-synthesis

The grep piped through `grep -oE 'FP-[0-9]+' | sort -u` yields exactly `FP-050 FP-052 FP-058 FP-065 FP-076 FP-155`. Entries: `docs/failure-patterns.md:192` `symptom:unshare-tier-shares-host-mount-namespace-host-writes`; `:194` `confine-blocks-all-writes-crashing-matplotlib-font-cache`; `:200` `bwrap-runtime-failure-drops-the-computation-silently`; `:207` `hardcoded-artifact-path-makes-suite-skip-not-fail`; `:218` `headless-read-confined-to-cwd-critic-briefs-blocked`; `:297` `four-document-link-cycle-between-stub-and-spec`. Each matches its description in the doc.

**Evidence:** `docs/failure-patterns.md:192,194,200,207,218,297` (command output in this session's transcript)

---

## Claim 12: "FP-050 … the script warns about this only when `--no-loopback` forces the switch. See observation O2."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:60`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cross-reference only; the behavioural half ("warns only when --no-loopback forces the switch") is correct (`scripts/confine-tests.sh:134-143`).
**Legibility-target:** for-author

The doc itself says O2 no longer exists: `docs/working/research-2026-11-10-confine-tests-bats.md:252` "(There is no O2: it became D2 in the review.)". The pointer should read "See defect D2."

**Evidence:** `docs/working/research-2026-11-10-confine-tests-bats.md:60,234,252`

---

## Claim 13: "The real `unshare` is in `/usr/bin`, beside `bash`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:49` (and `test/scripts/confine-tests.bats:47-48`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container; does not establish layout on other hosts.
**Legibility-target:** for-orchestrator-synthesis

`bash -c 'type -P bash sh unshare cat awk'` → `/usr/bin/bash /usr/bin/sh /usr/bin/unshare /usr/bin/cat /usr/bin/awk`.

**Evidence:** command output in this session's transcript; `test/scripts/confine-tests.bats:47-52`

---

## Claim 14: "`$PWD` does not pass through `env -i`; a fresh bash sets it to the physical directory. The expected `--bind`/`--chdir` values use `pwd -P`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:50` (and `test/scripts/confine-tests.bats:44-46`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the work dir used by the tests (no symlinked components were introduced); does not establish behaviour when the cwd path contains a symlink the test would need to keep logical.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:46` `WORK="$(cd "$T/work dir" && pwd -P)"`; `:63-65` PROFILE uses `"$WORK"`; the stand-in's own profile uses `"$PWD"` (`:104-105`) and the `is` exact-match passes in tests 8 and 9 (E1), so the script's `$PWD` under `env -i` equals `pwd -P`.

**Evidence:** `test/scripts/confine-tests.bats:44-46,63-65,103-108`; `$S/logs/bats-head.txt`

---

## Claim 15: "A stub whose shebang is not on line 1 still runs when bash starts it (bash falls back to running the file itself) and fails when `sh` starts it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a bash-syntax stub started by bash vs dash; the precise mechanism under dash is that dash also falls back to interpreting the file, and fails on bash-only syntax — the claim does not say otherwise.
**Legibility-target:** for-orchestrator-synthesis

E13: a stub with a blank line 1, `#!/usr/bin/env bash` on line 2 and `${name^^}`: from bash prints `ran X`, exit 0; from dash `...stub: 3: Bad substitution`, exit 2.

**Evidence:** E13 transcript (this session); `test/scripts/confine-tests.bats:95`

---

## Claim 16: "bash's `exec` takes options, and takes `--` to end them. dash 0.5.12's takes neither: it runs `--` as the command. So no one spelling of `exec` is safe under both."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:52` (and D1, `:232` "`exec -- "$@"` … dash 0.5.12 runs `--` as the command (exit 127)")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5 and dash 0.5.12-2 here; "no one spelling of `exec`" is checked for `exec "$@"` and `exec -- "$@"` only.
**Legibility-target:** for-orchestrator-synthesis

`dpkg -l dash` → `0.5.12-2`; `/usr/bin/sh -> dash`. E9: `dash -c 'exec -- "$@"' sh echo hi` → `sh: 1: exec: --: not found`, exit 127; `bash -c` same → `hi`, exit 0. E8 (bash as sh): `exec: -r: invalid option`.

**Evidence:** E9 transcript; `$S/logs/d1-bash.txt`

---

## Claim 17: "The health check runs `shellcheck -S warning` over `.bats` files too (`scripts/health-check.sh`, `check_shellcheck`) … Without a file-level `disable=SC2154` (the form `test/hooks/claude-config-audit.bats` uses) the new file failed three tests in `test/scripts/health-check.bats`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:53`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the gate's command and file discovery, the cited file-level form, shellcheck's verdict on the 9d37c1ac file, and HEAD's green on health-check.bats; does not establish by execution that exactly three tests failed at 9d37c1ac (inferred from which tests read the gate's status).
**Legibility-target:** for-orchestrator-synthesis

`scripts/health-check.sh:503-506` adds `find "$REPO_ROOT" -type f -name '*.bats' ...` and `:525` runs `shellcheck -x -e SC1091 -s bash -S warning "$f"`. `test/hooks/claude-config-audit.bats:3` `# shellcheck disable=SC2154  # $stderr is assigned by bats' run --separate-stderr`. E10 on the 9d37c1ac file: exit 1, `SC2154 (warning): stderr_lines is referenced but not assigned.` (one finding); at HEAD exit 0. Three tests in `test/scripts/health-check.bats` read the cached whole-script result: `:55` "health-check exits 0 on this repo", `:111` "gate 6: shellcheck linted the repo's scripts and flagged none", `:130` "output ends with All checks passed" — consistent with three failures. E12 at HEAD: health-check.bats and confine-tests.bats, 57 ok, exit 0.

**Evidence:** `scripts/health-check.sh:474-531`; `test/hooks/claude-config-audit.bats:3`; `test/scripts/health-check.bats:55,111,130`; `$S/logs/shellcheck-9d37.txt`; `$S/logs/shellcheck-head.txt`; `$S/logs/run-tests-subset.txt`

---

## Claim 18: Plan steps and sizes — "1. This doc … ~200 lines"; "2. … 17 tests, a new file of 395 lines at the review loop's entry"; step 5 "the brief's status line to done; the marker"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:104-108`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sizes at the commits named; step 5's brief-status change is future work (true only once the branch's last commit exists), not an error.
**Legibility-target:** for-orchestrator-synthesis

`git show a59eb11f:docs/working/research-2026-11-10-confine-tests-bats.md | wc -l` → 220; 9d37c1ac test file: 395 lines, `grep -c '^@test'` → 17; HEAD also 17.

**Evidence:** `git show` counts in this session's transcript

---

## Claim 19: Test specification G6 — "the bwrap run, the `--no-loopback` run and the unshare run each pass 12 hostile words and compare the child's argv exactly"; G1-G10 rows map to the named tests

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:121-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gap→test mapping and the TRICKY count; does not establish that the gaps list is complete.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:31-32` TRICKY has 12 elements (`'two words' -n --probe --no-loopback -- '' '$(touch pwned)' '`touch pwned`' '; touch pwned' '*' "it's" $'line one\nline two'`); `call child 1 "${TRICKY[@]}"` at `:283`, `:327`, `:386`. `same_process` is called at `:285`, `:329`, `:388` (G10).

**Evidence:** `test/scripts/confine-tests.bats:31-32,283-285,327-329,386-388`

---

## Claim 20: Rollback — "`git revert -m 1 <this branch's merge commit>` removes the test file, this doc and the brief's status change. … `test/` is not installed by `devcontainer-config/install.sh`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:147`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers install.sh's payload lists and the branch's file list; the brief-status part is true only once the final commit exists (not an error).
**Legibility-target:** for-author

`devcontainer-config/install.sh:121` `PAYLOAD=(devcontainer.json Dockerfile ... egress claude-home)` and `:146` `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` — no `test/`. The install half is right. The list of what the revert removes omits the four `docs/reviews/*-2026-11-10-confine-tests-bats.md` reports the branch adds (Claim 1), and will omit this report too.

**Evidence:** `devcontainer-config/install.sh:121,146`; `git diff --stat a37733cc...HEAD`

---

## Claim 21: Mutation table rows other than the exec row and the survivor (bwrap without `--unshare-net` / `--setenv`; command spliced into the sh body; refusal exits 0 / runs the command; `ip` failure swallowed; bwrap command unquoted; bwrap run-time fallback; unshare direct without `--`; `--no-loopback` falls through to bwrap; `ip` check removed; `--probe` runs on; `--help` prints every comment; unknown flag skipped; empty command run; `--no-loopback` warning removed) and which tests each fails

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:157-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers my re-derivation of each mutant from its one-line description (exact edits in `$S/mut.py`, `$S/mut2.py`, `$S/mut4.py`); a differently written mutant with the same description could fail a different set.
**Legibility-target:** for-orchestrator-synthesis

E3/E4/E6 failing tests (numbers per E1): no-unshare-net and no-setenv → 8, 9, 10 (the three bwrap run tests); splice via `printf %q` → 16 only (E6); refusal-exit0 and refusal-runs → 1, 2, 3; ip-swallowed → 17; bwrap-unquoted → 8; bwrap-fallback → 8, 9, 10; unshare-no-dashdash → 12, 15; nolo-falls-to-bwrap → 13; no-ip-check → 15; "`--probe` goes on" (removing the probe's `exit 0`, E4 probe-noexit) → 7, 11, 14, 15 ("four probe tests"); help-all → 6; unknown-skipped → 4; empty-run → 5; no-lo-warning → 11, 12. Every row matches the table. (A first splice attempt that left the body's quote unbalanced broke tests 12, 15, 16, 17 by syntax error; that is my construction, not the table's.)

**Evidence:** `$S/logs/mut-summary.txt`; `$S/logs/mut2-summary.txt`; `$S/logs/mut4-summary.txt`

---

## Claim 22: "20 of 21 fail at least one test"; "`set -euo pipefail` → `set -uo pipefail` | **nothing**"; Not covered: "a copy of the script with `set -uo pipefail` passes every test"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:153,172,208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of table rows (21 mutants: 2+1+2+1+1+1+1+1+1+1+1+1+1+1+4+1) and the survivor; does not establish the "no command fails where only errexit stops the script" explanation beyond this mutant passing.
**Legibility-target:** for-orchestrator-synthesis

E3 `no-errexit: exit 0 failing tests []`; every other re-derived mutant exits 1.

**Evidence:** `$S/logs/mut-summary.txt`; `$S/logs/mut-no-errexit.txt`

---

## Claim 23a: "`exec` replaced by a plain call, in each of four places (bwrap, the `sh` body, `unshare ... sh -c`, `unshare` direct) | the run test of that form"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each of the four mutants fails the run test of its form; does not cover which assertion catches it (23b).
**Legibility-target:** for-orchestrator-synthesis

E3: plain-bwrap → test 8; plain-shbody → 16; plain-unshare-sh → 16; plain-unshare-direct → 12.

**Evidence:** `$S/logs/mut-summary.txt`

---

## Claim 23b: "… through `same_process`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which assertion fails first for each of the four bare plain-call mutants, and whether they fail without `same_process`; does not dispute that `same_process` itself distinguishes exec from a plain call at all four sites (Claim 34).
**Legibility-target:** for-author

Only two of the four are caught through `same_process`. For bwrap and `unshare ... sh -c`, removing `exec` makes the script fall through to the next run form, and an earlier assertion catches it:
- plain-bwrap: fails in `confine` (`test/scripts/confine-tests.bats:145` `[[ ! -e "$LOG/unexpected" ]]`), the log showing `stub ip: unexpected call under STUB_IP=unset: 4: link set lo up` — after bwrap returns, the script reaches `scripts/confine-tests.sh:219-220`.
- plain-unshare-sh: fails at `test/scripts/confine-tests.bats:385` `calls child 1` with "child was called 2 time(s), want 1" — the script reaches `scripts/confine-tests.sh:227`.
E4 with `same_process` neutered (`return 0`): plain-bwrap still fails test 8 and plain-unshare-sh still fails test 16; plain-shbody and plain-unshare-direct pass. The precise version: "the sh-body and unshare-direct mutants fail through `same_process`; the bwrap and `unshare ... sh -c` mutants fall through to the next run form and fail on its calls."

**Evidence:** `$S/logs/mut-plain-bwrap.txt:10-25`; `$S/logs/mut-plain-unshare-sh.txt:18-21`; `$S/logs/mut2-summary.txt`

---

## Claim 23c: "(added in the review loop; before it, the `sh` body mutant survived, which pass 1's fact-check found)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which exec mutants survive the 9d37c1ac test file; does not check what pass 1's fact-check reported (not read, per brief).
**Legibility-target:** for-author

E7 against `git show 9d37c1ac:test/scripts/confine-tests.bats`: `plain-shbody ... exit 0 failing []` and `plain-unshare-direct ... exit 0 failing []`. Two exec mutants survived before `same_process`, not one: the `unshare` direct form (`scripts/confine-tests.sh:227`, the last line, so nothing follows to catch it) also passed.

**Evidence:** `$S/logs/mut5-summary.txt`

---

## Claim 24: "A 22nd copy adds a warning line to every unshare run (what a fix for D2 would do) and passes every test, as intended: the warning's absence is not pinned."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:174`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a warning added at run time (after the banner) on the unshare path; does not cover a warning at primitive-selection time, which also reaches `--probe` (see Claim 31).
**Legibility-target:** for-orchestrator-synthesis

E3 `d2-warning` (a line after `scripts/confine-tests.sh:178` printed when `primitive == unshare`): `exit 0 failing tests []`.

**Evidence:** `$S/logs/mut-summary.txt`; `$S/mut.py` (`d2-warning`)

---

## Claim 25: Gates table — `timeout 300 bats test/scripts/confine-tests.bats` 17 of 17; `scripts/hermeticity-lint --root .` exit 0 "143 test file(s) checked, no unstubbed network spawns"; `shellcheck -x -e SC1091 -s bash -S warning test/scripts/confine-tests.bats` "(the health check's own command)" exit 0

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:181-183`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these three gates at HEAD in this container.
**Legibility-target:** for-orchestrator-synthesis

E1: 17 ok, exit 0. E11: exit 0, `hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.` E10: exit 0; the flags equal `scripts/health-check.sh:525` `shellcheck -x -e SC1091 -s bash -S warning "$f"`.

**Evidence:** `$S/logs/bats-head.txt`; `$S/logs/lint.txt`; `$S/logs/shellcheck-head.txt`; `scripts/health-check.sh:525`

---

## Claim 26: Gates — whole suite at 9d37c1ac "**red**: 2005 pass, 3 fail, all in `test/scripts/health-check.bats`, all from SC2154 in the new file"; at f36108e4 "exit 0: 2008 of 2008 pass … 50 report-dependent suites as NOT RUN"; `scripts/lite-review.py --range 9d37c1ac..HEAD --mode fix-drift` "FINDINGS: NONE" (also 27b5e861's message)

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:184-186`; commit 27b5e861 body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what can be checked without the 20-minute suite: the 9d37c1ac file fails the shellcheck gate with SC2154 only, three health-check tests read that gate's result, and health-check.bats plus this file pass at HEAD (57 ok); does not establish the totals 2005/3/2008, the 50 NOT RUN suites, or the drift check's output.
**Legibility-target:** for-orchestrator-synthesis

Consistent evidence: E10 on 9d37c1ac's file exits 1 with a single SC2154 finding; `test/scripts/health-check.bats:55,111,130` are the three tests that depend on the whole-script status/gate-6/"All checks passed"; E12 (subset at HEAD) exit 0, 57 ok. Blockers: whole suite not run (brief: do not run `scripts/run-tests.sh` with no arguments); `scripts/lite-review.py:159-161` spawns `"claude", "-p"`, which needs the network and is out of bounds here. Note: 2005 + 3 = 2008, internally consistent.

**Evidence:** `$S/logs/shellcheck-9d37.txt`; `$S/logs/run-tests-subset.txt`; `scripts/lite-review.py:159-161`

---

## Claim 27: D1 — "On the unshare path with loopback, a test command whose name starts with `-` is misread when `sh` is bash", with both quoted cases (`-- -record -x`: status 2, `sh: line 6: exec: -r: invalid option` and the usage line; `-- -a x "$RECORD" one`: status 0, `child.1: one`), and "with dash as `sh` the same call exits 0 and the command receives `-x`"; "With dash the same call exits 127 (`exec: -a: not found`)"; "dash 0.5.12 (this container's `sh`)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:212-230`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both cases under bash-as-sh and dash-as-sh with the test file's stand-ins; does not establish the behaviour inside a real namespace (the stand-in execs unconfined).
**Legibility-target:** for-orchestrator-synthesis

E8, bash as sh: case 1 `status: 2`, stderr `sh: line 6: exec: -r: invalid option` / `exec: usage: exec [-cl] [-a name] [command [argument ...]] [redirection ...]`; case 2 `status: 0`, `child.1: one`. Dash as sh: case 1 `status: 0`, `child.1: -x`; case 2 `status: 127`, `sh: 6: exec: -a: not found` (the doc's paraphrase `exec: -a: not found` matches). Cause: the body ends `exec "$@"` (`scripts/confine-tests.sh:225`). "The other two run forms put `--` before the command": `:210` `-- "${cmd[@]}"`, `:227` `-rn -- "${cmd[@]}"`.

**Evidence:** `$S/logs/d1-bash.txt`; `$S/logs/d1-dash.txt`; `scripts/confine-tests.sh:220-227`

---

## Claim 28: D1 — "The security pass reports that `command -- "$@"` behaved correctly under both shells … [its observation; I did not re-run it]" and "The tests pin a dash-named command on the bwrap and `--no-loopback` forms only, and dash-leading arguments (not the command name) on all three."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `command -- "$@"` for a dash-named command and for `-a x`; does not evaluate it as a fix (it gives up the exec, which `same_process` would then flag).
**Legibility-target:** for-orchestrator-synthesis

E9: dash and bash both `command -- "$@"` with `-rec a` → `ran -rec with: a`, exit 0; with `-a x echo one` → `-a: not found`/`-a: command not found`, exit 127 (runs `-a` as the command, the correct reading). Pinning: `-record` appears only at `test/scripts/confine-tests.bats:290` (bwrap) and `:367` (`--no-loopback`); TRICKY's `-n`, `--probe`, `--no-loopback`, `--` reach all three forms (`:274`, `:318`, `:378`).

**Evidence:** E9 transcript; `test/scripts/confine-tests.bats:274,290,318,367,378`

---

## Claim 29: D2 — quoted output (`confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one` → status 0, stderr only `confine-tests: denying network via unshare (loopback=1)`); the citation "Say so, loudly, every time" (`scripts/confine-tests.sh:132-133`); the full warning "is printed only when `--no-loopback` forces the switch from bwrap"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:234-241`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the run output and the cited lines; does not judge whether D2 is a defect.
**Legibility-target:** for-orchestrator-synthesis

E8 "d2 fallback run": `status: 0`, stderr `confine-tests: denying network via unshare (loopback=1)`, `child.1: one`. `scripts/confine-tests.sh:132-133` "bwrap would have refused with EROFS lands on the real filesystem as root. Say / so, loudly, every time." The warning lines are only inside `:134` `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]`.

**Evidence:** `$S/logs/d1-dash.txt`; `scripts/confine-tests.sh:132-143`

---

## Claim 30: Not covered — "(Pass 1 of the review found that an exact match on stderr did pin D2's missing warning; the two unshare run tests now only require the banner to be present.)"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two run tests on the unshare primitive (12 and 16); does not cover the probe test discussed in Claim 31.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:321` `[[ "$stderr" == *"confine-tests: denying network via unshare (loopback=0)"* ]]` and `:382` `[[ "$stderr" == *"confine-tests: denying network via unshare (loopback=1)"* ]]` — glob matches, not equality.

**Evidence:** `test/scripts/confine-tests.bats:321,382`

---

## Claim 31: D2 — "No test pins the warning's absence."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:243`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a D2 warning emitted where the existing `--no-loopback` warning is emitted (at primitive selection, so also on `--probe`); the narrower reading — no *run* test pins it — is true (Claim 24).
**Legibility-target:** for-author

Test 14 pins an empty stderr on a plain fallback probe: `test/scripts/confine-tests.bats:346-349` `confine "unshare ip" STUB_UNSHARE=ok -- --probe` … `[ -z "$stderr" ]`. Test 15's `refused 3 "$NO_IP"` (`:359`) also requires the `ip` refusal to be stderr's first line on the unshare path. E5 `d2-warn-at-selection` (a warning printed before the `ip` check whenever the primitive is unshare with loopback) fails tests 14 (`[ -z "$stderr" ]' failed` at line 349) and 15 (`refused 3 "$NO_IP"' failed` at line 359). The existing `--no-loopback` warning is printed at selection and so on probes (`scripts/confine-tests.sh:134-143`, before `:165`), so a fix mirroring it is the natural one. Precise version: "No run test pins it; test 14 pins an empty stderr on a fallback `--probe`, and test 15 pins the `ip` refusal as stderr's first line."

**Evidence:** `test/scripts/confine-tests.bats:345-359`; `$S/logs/mut3-d2-warn-at-selection.txt:16-29`; `scripts/confine-tests.sh:134-169`

---

## Claim 32: Observations O1, O3, O4, O5

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:247-250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** O1, O3, O4 checked against the script and by running; O5 checked only as an argv-order fact (it is marked inferred; real bwrap mount semantics with `PWD=/` not established).
**Legibility-target:** for-orchestrator-synthesis

O1: probe `scripts/confine-tests.sh:81` `bwrap --ro-bind / / --unshare-net -- true`; run `:199-210` adds exactly `--dev /dev --proc /proc --tmpfs /tmp --setenv TMPDIR /tmp --bind "$PWD" "$PWD" --unshare-pid --die-with-parent --chdir "$PWD"` — the list is complete; "a test pins that" = test 10 (passes, E1). O3: E8 no primitive + no command → `status: 3` with the refusal (detection `:115` precedes `:171`). O4: E8 `"$RECORD" one` without `--` → `confine-tests: unknown flag: /tmp/.../my cmds/record argv`, status 2 (`:65-68`). O5: `:200` `--ro-bind / /` precedes `:205` `--bind "$PWD" "$PWD"`.

**Evidence:** `scripts/confine-tests.sh:65-68,81,115,171,199-210`; `$S/logs/d1-dash.txt`

---

## Claim 33: Docs — "`docs/reviews/review-fix-loop-polyglot-test-hermeticity.md` (weak seam 3) and `docs/working/research-2026-11-07-confine-tests-situation.md` (follow-up 5)" say the script had no test; "`guides/test-hermeticity.md` lists `test/hermeticity-lint.bats` under its relevant paths and says nothing about tests of this script"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:256`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited items; does not check other docs for the same statement.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/review-fix-loop-polyglot-test-hermeticity.md:54` "3. **`confine-tests.sh` ships with no automated test at all**"; `docs/working/research-2026-11-07-confine-tests-situation.md:162` "5. `confine-tests.sh` still has no bats case (review weak seam 3)." `guides/test-hermeticity.md:8` `Relevant paths: scripts/hermeticity-lint, scripts/hermeticity/adapters/, scripts/confine-tests.sh, test/hermeticity-lint.bats`; `grep -n 'confine-tests.bats'` on the guide: no hit.

**Evidence:** `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md:54`; `docs/working/research-2026-11-07-confine-tests-situation.md:162`; `guides/test-hermeticity.md:8`

---

## Claim 34: `same_process` — "the test command ran as the process the script was. No step between them forked: the script execs its primitive, and its sh body execs the command." (and the brief's question: does it distinguish exec from a plain call at each of the four exec sites)

**Location:** `test/scripts/confine-tests.bats:148-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four exec sites when the fall-through to the next run form is suppressed (`; exit` appended) and when it is not; does not establish anything about real bwrap (Claim 35).
**Legibility-target:** for-orchestrator-synthesis

`:152` `cmp -s "$LOG/script-pid" "$LOG/child-pid" || { echo "the command was not exec'd all the way"; return 1; }`. E3/E4: plain-shbody and plain-unshare-direct fail at `same_process` ("the command was not exec'd all the way"). E5: plain-bwrap-exit and plain-unshare-sh-exit (no fall-through possible) fail at `same_process` (lines 285 and 388). Unmutated, all three run tests pass (E1).

**Evidence:** `$S/logs/mut-plain-shbody.txt:18-21`; `$S/logs/mut-plain-unshare-direct.txt:14-17`; `$S/logs/mut3-plain-bwrap-exit.txt:11-13`; `$S/logs/mut3-plain-unshare-sh-exit.txt:19-21`

---

## Claim 35: "(A stand-in execs the command too; the real bwrap forks it.)"

**Location:** `test/scripts/confine-tests.bats:150`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The stand-in half is verified (`:110` `ok) shift "${#profile[@]}"; exec -- "$@" ;;`, `:119` `shift 2; exec -- "$@"`); the real-bwrap half is not established here.
**Legibility-target:** for-orchestrator-synthesis

No `bwrap` in this container (`command -v bwrap` empty), so whether the real bwrap forks the command could not be observed (paraphrased — no quote available because the claim concerns an external binary absent here). The script's own profile asks for `--unshare-pid` and `--die-with-parent` (`scripts/confine-tests.sh:207-208`), which imply a separate child process, consistent with the claim. Needed: one run with real bwrap comparing pids.

**Evidence:** `test/scripts/confine-tests.bats:110,119,150`; `scripts/confine-tests.sh:207-208`

---

## Claim 36: Header — "Every test but one runs the script on a PATH built here: the real bash, sh, cat and awk, plus stand-ins for bwrap, unshare and ip" and "any other call fails the test that made it (see confine())"; line 3's shellcheck reason "bats' `run --separate-stderr` sets $stderr and $stderr_lines"

**Location:** `test/scripts/confine-tests.bats:3,8-10,16-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 17 tests' PATH and the unexpected-call path through `confine`; does not establish detection of an unexpected call in test 3 (it uses no stand-ins).
**Legibility-target:** for-orchestrator-synthesis

Only test 3 (`:211`, `:217`) calls the script without `confine`; every other test calls `confine` (`:143-144`, `env -i PATH="$path"` built from `$TOOLS` (`:50-52`: bash sh cat awk) and the named stub dirs). `:145` `[[ ! -e "$LOG/unexpected" ]]` is confine's last command; the plain-bwrap mutant shows it failing a test on an unexpected `ip` call (Claim 23b). E10: without the directive shellcheck reports SC2154 on `stderr_lines`; bats sets both `$stderr` and `$stderr_lines` under `--separate-stderr`, which tests use (`:179`, `:200`).

**Evidence:** `test/scripts/confine-tests.bats:3,50-52,137-146,211,217`; `$S/logs/mut-plain-bwrap.txt`; `$S/logs/shellcheck-9d37.txt`

---

## Claim 37: Helper comments — TRICKY (`:28-30`), RECORD_CALL (`:34-36`), `setup()` (`:44-48`, `:53-55`, `:62`), `teardown()` ("bats shows the failing line, not what `run` captured or the stand-ins saw"), `confine()` ("The script's pid goes to $LOG/script-pid (bash and env exec, so it is the same)")

**Location:** `test/scripts/confine-tests.bats:28-46,53-55,62,70,133-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against its code and the E1/E3 runs; does not establish bats behaviour in versions other than 1.8.2.
**Legibility-target:** for-orchestrator-synthesis

TRICKY holds a space, leading dashes incl. `--probe --no-loopback --`, `''`, two substitutions, `; `, `*`, `'`, newline (`:31-32`). RECORD_CALL `:37-38` writes `printf "%s\0" "$@"` only when `$# -gt 0`, so no-arg → empty file. Setup: `RECORD="$T/my cmds/record argv"` (space), `cp "$RECORD" "$TOOLS/-record"` (`:42`, `:58`), child records `$$` and exits `${CHILD_EXIT:-0}` (`:56-57`). Teardown dumps status, streams and calls only when `BATS_TEST_COMPLETED` is unset (`:71`); the mutant logs show this dump after bats' failing-line report (e.g. `$S/logs/mut-plain-bwrap.txt:18-25`). `confine` `:143` `bash -c 'echo "$$" > "$1"; shift; exec "$@"' _ ... env -i ... "$SCRIPT"`: bash execs env, env execs the script (shebang `#!/usr/bin/env bash`); the unmutated run tests' `same_process` passes (E1), so the pid is the same.

**Evidence:** `test/scripts/confine-tests.bats:28-66,69-81,133-146`; `$S/logs/bats-head.txt`; `$S/logs/mut-plain-bwrap.txt`

---

## Claim 38: The stand-in's comment block — accepted calls by mode for bwrap/unshare/ip; "Any other argv, and any call with the mode unset, is written to $STUB_LOG/unexpected and exits 99. A run execs the command unconfined"

**Location:** `test/scripts/confine-tests.bats:83-93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the generated stub code `:95-130`; also true that a mode value outside the listed ones falls to `unexpected` (not stated, not contradicted).
**Legibility-target:** for-orchestrator-synthesis

`:106-107` probe: `ok|run-fails) exit 0 ;; refused) exit 1`; `:108-112` profile + command: `ok) ... exec -- "$@"`, `run-fails) ... exit 1`; `:116-117` `is -rn true`: `ok) exit 0 ;; refused) exit 1`; `:118-119` `-rn -- ...` only when `"$mode" == ok`, then `exec`; `:123-124` `link set lo up`: `ok) exit 0 ;; fails) ... exit 1`; fall-through `:128-129` appends to `$STUB_LOG/unexpected`, `exit 99`; `mode="${!var:-unset}"` (`:100`).

**Evidence:** `test/scripts/confine-tests.bats:94-131`

---

## Claim 39: The 17 `@test` names (and in-test comments: test 2 `:193`, test 3 `:207-210` incl. "A real primitive that stalls ends in timeout's 124, which fails the test", test 5 `:244`, test 10 `:298`, test 15 `:369`, test 16 `:380-381`, `:392-394`)

**Location:** `test/scripts/confine-tests.bats:183-412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its body and the mutation results; test 6's "header comment only" is pinned by first line, one phrase and three exclusions, not the full text; test 16's "raises lo, then execs" pins that `ip` was called and the command exec'd, not their order beyond the body text.
**Legibility-target:** for-orchestrator-synthesis

Name ↔ body, by test: (1) `confine ""` → `refused 3`, `calls child 0` (`:184-189`); (2) both stubs refused, refusal text, `calls bwrap 2 unshare 2 child 0` (`:194-203`); (3) only ambient-PATH test, `case` on 0/3, `*) false` — so 124 fails it (`:211-222`); (4) `calls bwrap 0 unshare 0 child 0` after the two usage errors (`:226-232`); (5) three arg sets, `calls bwrap 3 unshare 1` = three bwrap probes + one unshare probe (`:237-245`); (6) no mode set, exit 0, `[ -z "$stderr" ]`, `calls bwrap 0 unshare 0` (`:250-260`); (7) `calls bwrap 1`, `calls unshare 0 child 0` (`:264-270`); (8) `call bwrap 2 "${PROFILE[@]}" ...`, `call child 1 "${TRICKY[@]}"`, `same_process` (`:274-286`); (9) exit 7, `-record -x` (`:290-294`); (10) `status -ne 0`, `calls bwrap 2 unshare 0 child 0` (`:299-301`); (11) both flag orders, warning first line (`:306-313`); (12) `call unshare 2 -rn -- "$RECORD" ...`, `calls ip 0` (`:317-329`); (13) stubs "bwrap" and "bwrap unshare", probe and run, `refused 2` (`:334-342`); (14) unshare reported with bwrap absent and refused (`:346-354`); (15) `refused 3 "$NO_IP"` for probe and run, then `--no-loopback` probe and run, `calls unshare 5` = 1+1+1+2 (`:358-373`); (16) `call ip 1 link set lo up`, `same_process`, body identical across two commands and free of command words (`:378-403`); (17) `STUB_IP=fails` → exit 3, last stderr line, `calls ip 1 child 0` (`:407-411`). E1 all pass; Claims 21-23a show each name's property is load-bearing under mutation. Test 16's "its absence is not pinned" holds for this run test (Claim 24; contrast Claim 31 for the probe test).

**Evidence:** `test/scripts/confine-tests.bats:183-412`; `$S/logs/bats-head.txt`; `$S/logs/mut-summary.txt`

---

## Claim 40: Commit messages — 9d37c1ac "17 characterization tests", "16 mutations … each failed by at least one test", "--probe exits 3 in this container", Notes on dash-named commands; f36108e4 "20 of 21 mutants fail; set -e is the survivor", "a copy of the script without the exec used to pass", "C2: … timeout 60", "C6, A6: set -u in the recorder", "Size: 412 code lines against a37733cc"; 27b5e861 "The probe exits 3 here", "Size: 412 code lines against a37733cc"

**Location:** commits 9d37c1ac, f36108e4, 27b5e861 (bodies); a59eb11f ("one defect found in the script (D1)")
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers counts, the size line and the mutation claims as re-derived (16 = 21 minus the four exec mutants and the survivor; E7 shows those 16 descriptions failing against the 9d37c1ac file except bwrap-fallback's test 8, which needs `same_process`, still failing 9 and 10); the whole-suite and drift-check results in 27b5e861 are Claim 26.
**Legibility-target:** for-orchestrator-synthesis

`git show 9d37c1ac:test/scripts/confine-tests.bats | grep -c '^@test'` → 17. `git diff --numstat a37733cc...HEAD -- ':(top)' ':(top,exclude)docs/'` → `412 0 test/scripts/confine-tests.bats`. E7: each of the 16 non-exec, non-survivor mutants fails ≥1 test on the 9d37c1ac file; plain-shbody and plain-unshare-direct pass it ("without the exec used to pass"). `test/scripts/confine-tests.bats:211` `timeout 60`; `:56` `'set -u'` in RECORD and `:95` in the stub. E2 probe exit 3. 9d37c1ac's dash-name note matches Claim 28.

**Evidence:** `$S/logs/mut5-summary.txt`; `$S/logs/probe.txt`; `test/scripts/confine-tests.bats:56,95,211`

---

## Claims Requiring Attention

### Incorrect
- **Claim 23b** (`docs/working/research-2026-11-10-confine-tests-bats.md:171`): the exec→plain-call mutants for bwrap and `unshare ... sh -c` are caught by falling through to the next run form (unexpected `ip` call; child called twice), not "through `same_process`"; only the sh-body and unshare-direct mutants are.
- **Claim 31** (`docs/working/research-2026-11-10-confine-tests-bats.md:243`): "No test pins the warning's absence" — test 14 asserts `[ -z "$stderr" ]` on a plain-fallback `--probe` (`test/scripts/confine-tests.bats:349`) and test 15 pins the `ip` refusal as stderr's first line; a D2 warning placed like the existing `--no-loopback` one fails both. Narrow to "no run test pins it".

### Stale
- **Claim 12** (`docs/working/research-2026-11-10-confine-tests-bats.md:60`): "See observation O2" — O2 became D2 (same doc, `:252`).

### Mostly Accurate
- **Claim 1** (`docs/working/research-2026-11-10-confine-tests-bats.md:5`): the branch also adds four `docs/reviews/` reports.
- **Claim 20** (`docs/working/research-2026-11-10-confine-tests-bats.md:147`): the revert also removes the review reports; install.sh half is right.
- **Claim 23c** (`docs/working/research-2026-11-10-confine-tests-bats.md:171`): before `same_process`, two exec mutants survived (sh body and unshare direct), not one.

### Unverifiable
- **Claim 26** (`docs/working/research-2026-11-10-confine-tests-bats.md:184-186`, 27b5e861): whole-suite totals (2005/3, 2008/2008, 50 NOT RUN) and the lite-review drift result need the 20-minute suite and a networked `claude -p`; everything checkable is consistent.
- **Claim 35** (`test/scripts/confine-tests.bats:150`): "the real bwrap forks it" needs a real bwrap.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/code-fact-check-report-final-r2-2026-11-10-confine-tests-bats.md, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: the four first-pass `docs/reviews/*` files (context only, per brief); whole-suite run (brief forbids it; a 57-test subset ran instead); `scripts/lite-review.py` (spawns `claude -p`, needs network); real bwrap behaviour (absent here). Execution logs live in the scratch dir, not `docs/reviews/execution-logs/`, because the brief allows one repo file.
- Escalate: nothing beyond the author-facing items above (two Incorrect, one Stale, three Mostly accurate, all in the research doc; none in the test code).
