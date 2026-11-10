Commit: bd312d15

# Code Fact-Check Report

**Commit:** bd312d15
**Repository:** claude-workflows, worktree `/workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback`
**Scope:** branch `fix/confine-tests-dash-and-fallback`, 23ffb16c..bd312d15: `scripts/confine-tests.sh`, `test/scripts/confine-tests.bats`, `guides/test-hermeticity.md`, `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md`, `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md`, the brief's invariant line, and the commit messages of `git log 23ffb16c..bd312d15` (final confirming pass, replicate 1)
**Checked:** 2026-11-10
**Total claims checked:** 63
**Summary:** 52 verified, 3 mostly accurate, 1 stale, 6 incorrect, 1 unverifiable

## Execution environment and provenance

Every run was made from the scratch directory
`/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-final-fc-r1`
(written `$X` below). Every log named here is a file under `$X/logs/`. The worktree was read and never written, except for this report. Scripts and tests were copied in with `git show <rev>:<path>`: `$X/new` (bd312d15), `$X/old` (23ffb16c script, bd312d15 test file), `$X/at/<rev>` (d03a3078, bd657ce8, 6465a156, ca6cf3be). Versions: GNU bash 5.2.15, dash 0.5.12-2 (`/bin/sh -> dash`), Bats 1.8.2, util-linux 2.38.1. Timestamps are local time (-08:00). The container cannot create a namespace, so every run used stand-ins: the test file's own `write_stub` stand-in, which the harness extracts from the bats file.

| Run | Command (cwd `$X` unless noted) | Exit | Time | Log |
|---|---|---|---|---|
| R1 | `timeout 300 bats new/test/scripts/confine-tests.bats` | 0 | 14:26 | `bats-new.txt` |
| R2 | `timeout 300 bats old/test/scripts/confine-tests.bats` (old script, new tests) | 1 | 14:26 | `bats-oldscript-newtests.txt` |
| R3 | `timeout 590 bash diff.sh $X/logs/diff-old-new.txt`: old against new, 13 stand-in setups x {`sh` dash, bash} x (9 non-run argument sets + 2 loopback modes x 14 commands), each also with no `sh` for the new script; 1924 pairs; compares stdout, stderr, status and the child's argv | 0 | 14:27 | `diff-old-new.txt` |
| R4 | `timeout 590 bash atcommits.sh $X` (each commit's test file against its own script) | 0 | 14:30 | `at-commits.txt`, `bats-at-<rev>.txt` |
| R5 | `timeout 60 bash p6465.sh $X` (`--no-loopback --probe`, bwrap ok: old, 6465a156, new) | 0 | 14:31 | `p6465.txt`, `p.*.err` |
| R6 | `timeout 590 python3 -I mutate.py <worktree> $X/mut` (copy of the author's script) | 0 | 14:31 | `mutation-run.txt` |
| R7 | cwd worktree: `timeout 60 scripts/confine-tests.sh --probe`; `timeout 300 scripts/hermeticity-lint --root .`; `timeout 120 shellcheck -x -e SC1091 -s bash -S warning scripts/confine-tests.sh test/scripts/confine-tests.bats` | 3; 0; 0 | 14:32 | `gates.txt` |
| R8 | `timeout 30 bash benv.sh $X/benv` (BASH_ENV under bash, `bash -p`, dash, bash as `sh`) | 0 | 14:33 | `bashenv.txt` |
| R9 | `timeout 60 bats w127.bats` (cwd `$X/w127`; bats' 127 warning, `run -127`) | 1 (test 3 fails by design) | 14:34 | `bats127.txt` |
| R10 | `timeout 30 bash p2.sh $X` (`$BASH` under a shebang, under `bash script`, with `BASH=/evil` in the environment; `unshare --help`) | 0 | 14:35 | `p2.txt` |
| R11 | `bash -c 'exec env -- "$@"' sh a=b z` | 127 | 14:36 | `env-assign.txt` |
| R12 | `dash -c 'exec -- "$@"' sh echo hi`, `dash -c 'exec -a x echo hi'`, `bash -c` and `bash --posix -c` with `exec --` | 127, 127, 0, 0 | 14:29 | `dash-exec.txt` |
| R13 | `timeout 60 bash fbcount.sh $X` (calls of each stand-in on a fallback run, bwrap refused) | 0 | 14:29 | `fbcount.txt` |
| R14 | cwd `$X/mut/m04` and `$X/mut/m03`: `timeout 120 bats -f '...' test/scripts/confine-tests.bats` | 1, 1 | 14:36 | `m04-detail.txt`, `m03-detail.txt` |

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): read. No claim here matches a logged pattern, and none of the Incorrect verdicts is a fabricated symbol (they are miscounts, a grep result misreported, and incomplete enumerations), so no entry is due. This pass may not write that file anyway.

---

## Claim 1: "pr-prep's fallback check fired on a count of 539 changed lines, 301 of them the research doc; 238 lines change outside `docs/` (227 in the script and its test, 11 in the guide), none in an enforcement file"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts for 23ffb16c..ca6cf3be (the proposal the pre-mortem names) and the enforcement-file claim; does not establish the counts for the final branch (270 lines outside `docs/`, Claim 50).
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat 23ffb16c..de1f4bf9` (cwd worktree, 14:33, exit 0) gives research doc `301 0`, guide `9 2`, script `61 13`, test `119 34`, and the pre-mortem itself `59 0`. Without the pre-mortem: 301 + 11 + 74 + 153 = 539; outside `docs/` 238; script + test 227. No path matches `hooks/live-verify-gate.sh`'s `enforcement='^devcontainer-config/(...)'` (`hooks/live-verify-gate.sh:83`).

**Evidence:** `hooks/live-verify-gate.sh:83,91`; numstat output (quoted above; paraphrased — no file captured because it is a 5-line numstat, reproduced in full here)

---

## Claim 2: "Prior art: `grep -ril -e 'BASH_ENV' -e 'uid 0' -e 'warning fatigue' -e 'unshare -r' docs/decisions/ docs/working/` returns decision 017, the two earlier confine-tests research docs and this unit's own"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the quoted command returns at bd312d15 and at de1f4bf9; does not establish whether the extra hits hold prior art for the narratives (they were not read).
**Legibility-target:** for-author

The quoted command returns 17 files, not 4: besides the four named, `docs/decisions/019-arithmetic-eval-sandboxing.md`, both briefs, five `docs/working/cycles/cycle-*.md`, `diagnosis-cc-isolated-login-dns.md`, `plan-build-loop-handoff.md`, `questions-archive.md`, `research-2026-11-01-restriction-audit.md` and `research-2026-11-05-d6-block-into-image.md`. `git grep -il ... de1f4bf9 -- docs/decisions/ docs/working/` (the tree the pre-mortem was written on) gives the same 17. Precise version: "returns 17 files; of them, decision 017 and the two earlier confine-tests research docs hold narrative 1's ground."

**Evidence:** the `grep -ril` run (cwd worktree, 14:34, exit 0; paraphrased — no file captured because the 17-path list is reproduced in full above)

---

## Claim 3: "`--probe` on a host with `unshare` and no usable `bwrap` prints `primitive available: unshare (loopback=1)` and exits 0, with no warning"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fallback causes (bwrap missing, bwrap refused) with `ip` present; does not cover a host without `ip` (exit 3) or a real primitive.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:196-200
if [[ "$probe_only" -eq 1 ]]; then
  echo "confine-tests: primitive available: $primitive (loopback=$loopback)"
  echo "  network denial is kernel-enforced and inherited by every child process."
  exit 0
fi
```

The fallback warning comes after this, at `:216-230`. Test 14 (`test/scripts/confine-tests.bats:367-380`) pins `[ -z "$stderr" ]` for both causes and passed in R1. The quoted text is the line after its `confine-tests: ` prefix.

**Evidence:** `scripts/confine-tests.sh:196-200,216-230`; `test/scripts/confine-tests.bats:367-380`; `$X/logs/bats-new.txt`

---

## Claim 4: "The run prints the new warning as the file's first six lines"; "the log shows the banner on line seven"; the first line reads "`confine-tests: WARNING — bwrap is installed but unusable here`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21,22,32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fallback routes with loopback, and stderr sent to a file; does not cover the `--no-loopback` fallback route, where the last way-back line is longer but is still one line.
**Legibility-target:** for-orchestrator-synthesis

`warn_unshare_only` prints one headline, three heredoc lines, the EROFS line and one `printf` line per argument from `$3` on (`scripts/confine-tests.sh:131-140`). Each fallback call passes one such argument (`:222-228`), which makes six lines, and the banner (`:232`) is the seventh. In R3 every fallback run's new stderr shows exactly this, e.g. the `nobwrap+unshare-ok+ip :: [ -- adir]` block. The `bwrap is installed but unusable here; ...` headline is `:222`.

**Evidence:** `scripts/confine-tests.sh:131-140,216-232`; `$X/logs/diff-old-new.txt`

---

## Claim 5: "the four tests that begin `[ "$(id -u)" -ne 0 ] || skip` (`test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889`, `test/install-host.bats:680`, `test/cc-isolated-functions.bats:1970`)"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21`; `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:370`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence and the line numbers of the four `id -u` checks; does not establish that no other test skips under a user namespace (Claim 6).
**Legibility-target:** for-orchestrator-synthesis

`git grep -n -F 'id -u)" -ne 0 ] || skip' -- test` returns exactly the four cited lines, e.g. `test/cc-push.bats:417: [ "$(id -u)" -ne 0 ] || skip "root ignores directory permissions"`. One nuance: `test/install-host.bats:680` begins `need_script; [ "$(id -u)" -ne 0 ] || skip ...`, so it does not literally begin with the check.

**Evidence:** `test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889`, `test/install-host.bats:680`, `test/cc-isolated-functions.bats:1970`

---

## Claim 6: "A 'passes confined' from that tier covers four tests fewer than the unconfined gate"; "lists four skips that an unconfined run does not have"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:370`; `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:22`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the count of uid checks (four, Claim 5); does not establish the number of tests that skip under a real `unshare -rn`, which needs a user namespace this container cannot create.
**Legibility-target:** for-orchestrator-synthesis

A fifth candidate exists. `test/scripts/build-loop-orchestrator.bats:394` reads `[[ -f "$O/scripts/build-loop.sh" && "$(stat -c %u "$O/scripts")" == 0 ]] || skip "no root-owned image copy at $O here"`, with `O=/opt/claude-workflows`. That test ran, without skipping, in the author's unconfined suite here: `suite-1.txt` has only two `# skip` lines, both about `permissions.allow`. Under `unshare -r`, host uid 0 is not mapped into the namespace, so a root-owned `/opt/claude-workflows/scripts` should appear as the overflow uid (65534) and the test should skip (inferred from user-namespace mapping, not observed). Needed to verify: one suite run under a real `unshare -rn`, counting `# skip` lines against an unconfined run.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-397`; `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/suite-1.txt` (2 skips)

---

## Claim 7: "`docs/roadmap.md:49`: 'exit 0: tests pass confined'"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21,26`; `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:376`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted words on that line; does not establish how briefs use them.
**Legibility-target:** for-orchestrator-synthesis

`docs/roadmap.md:49`: `wording (run \`scripts/confine-tests.sh --probe\`; exit 0: tests pass confined; exit 3:`.

**Evidence:** `docs/roadmap.md:49`

---

## Claim 8: "no caller exists in this repo, and `grep -rn confine-tests` over code finds none"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:33`; `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `*.sh`, `*.bats` and `*.py` outside the script and its own test; does not cover callers outside the repo.
**Legibility-target:** for-orchestrator-synthesis

`git grep -n confine-tests -- '*.sh' '*.bats' '*.py'`, with the script and its test file left out, returns one hit: `test/fixture-hermeticity.bats:15:# namespace: scripts/confine-tests.sh -- scripts/run-tests.sh --all`. That is a comment, not a call.

**Evidence:** `test/fixture-hermeticity.bats:15`

---

## Claim 9: "a non-interactive bash sources the file `BASH_ENV` names; the `sh` it replaces does not, whether it is dash or bash started as `sh` ... only the first sourced FILE"; the fix "`"$BASH" -p -c`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:39,44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `-c` invocations of bash 5.2.15, `bash -p`, dash 0.5.12 and bash linked as `sh`; does not cover exported functions or other shells.
**Legibility-target:** for-orchestrator-synthesis

R8 output: `bash -c:` prints `SOURCED` and then `body`. `bash -p -c:`, `dash -c:` and `bash as sh -c:` each print only `body`. The body is started as `exec unshare -rn -- "$BASH" -c '` (`scripts/confine-tests.sh:285`).

**Evidence:** `scripts/confine-tests.sh:285`; `$X/logs/bashenv.txt`

---

## Claim 10: Narrative 4: the tests build a PATH with no `sh`, "so four other tests fail with `exec: sh: not found`, and the argv pin in the unshare run test names `"$TOOLS/bash"` ... the mutant 'body under sh again' fails tests 16, 18, 19, 20 and 21, and on a host without dash it would still fail 16, 19, 20 and 21"; "`setup()` links only `bash`, `cat` and `awk`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:50,53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutant on this host (dash present); the no-dash case is inferred from test 18 being the only dash-dependent test, not run.
**Legibility-target:** for-orchestrator-synthesis

R6: `m01 body under sh again (exec -- kept): exit 1; failing tests: 16, 18, 19, 20, 21`. Setup: `for tool in bash cat awk; do` (`test/scripts/confine-tests.bats:65`). The argv pin: `call unshare 2 -rn -- "$TOOLS/bash" -c "${first[4]}" "$BODY_NAME" ...` (`:425`). With no `sh` on PATH, the stand-in reports `stub/unshare/unshare: line 29: exec: sh: not found` (seen in R4 at d03a3078, the same condition).

**Evidence:** `test/scripts/confine-tests.bats:65,425`; `$X/logs/mutation-run.txt`; `$X/logs/bats-at-d03a3078.txt`

---

## Claim 11: "What exists": `scripts/confine-tests.sh` at 23ffb16c "(227 lines ...)"; Detection "(lines 79-118)"; the `--no-loopback` switch "(134-152)" with "a seven-line warning (six `echo`s after the headline)", "the only place that text is printed", "It runs before `--probe` answers"; the run "(176-227)", third form `exec unshare -rn -- sh -c '<static body>' sh "${cmd[@]}"` ending `exec "$@"` (`:225`); the test file "(420 lines, 17 tests)" with "symlinks to the real `bash`, `sh`, `cat` and `awk`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:14-20,39,43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line numbers, the counts and the quoted forms at 23ffb16c; does not re-derive the first unit's description.
**Legibility-target:** for-orchestrator-synthesis

At 23ffb16c the file has 227 lines (`wc -l`). Line 79 is `detect_primitive() {`, line 134 is `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]; then`, line 143 is `echo "  no route off the host)." >&2` (the last of seven echoes, `:137-143`), line 176 is `# --- run ---`, line 220 is `exec unshare -rn -- sh -c '`, line 225 is `exec "$@"' sh "${cmd[@]}"` and line 227 is `exec unshare -rn -- "${cmd[@]}"`. The old test file has 420 lines and 17 `@test`s, and its setup loop was `for tool in bash sh cat awk; do` (diff hunk `@@ -47,18`).

**Evidence:** `git show 23ffb16c:scripts/confine-tests.sh` lines 79, 134-143, 176, 220-227; `git show 23ffb16c:test/scripts/confine-tests.bats`

---

## Claim 12: "Decision 018 (`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`) cites `scripts/confine-tests.sh:220`, and `CLAUDE.md` names the script without a line"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two citations and CLAUDE.md's wording; does not cover other documents that may cite the line.
**Legibility-target:** for-orchestrator-synthesis

`018...md:43`: `(\`scripts/confine-tests.sh:220\` is the reference for this pattern.)`. `:117`: `` `scripts/confine-tests.sh:220` — reference argv-passthrough pattern.`` CLAUDE.md: `(record 018; the reference pattern is in \`scripts/confine-tests.sh\`)`.

**Evidence:** `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`; `CLAUDE.md` (Code section)

---

## Claim 13: "In this container `scripts/confine-tests.sh --probe` exits 3 ... Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:24-26`; Gates row `:339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the final tree in this container; does not cover a host with a working primitive.
**Legibility-target:** for-orchestrator-synthesis

In R7, `exit 3` and the first output line is `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`

**Evidence:** `scripts/confine-tests.sh:142-145`; `$X/logs/gates.txt`

---

## Claim 14: The D1 table: with `sh` as bash, `-rec -x` is "refused: `exec: -r: invalid option`", `-a x rec one` "**runs `rec` with `one`**", `-nonexistent y` "refused: `exec: -n: invalid option`"; with `sh` as dash, `-rec -x` runs, `-a ...` gives `exec: -a: not found`, `-nonexistent y` gives `exec: -nonexistent: not found`; `eval echo hi` "runs the file `eval`" under both

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:32-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 23ffb16c body run through the stand-in with `sh` linked to bash 5.2.15 and to dash 0.5.12; does not re-run the author's probe1.sh itself.
**Legibility-target:** for-orchestrator-synthesis

R3, old script, `sh` bash. `-rec -x`: status 2, `sh: line 6: exec: -r: invalid option`. `-a x rec one`: status 7 (the child's) with `child.1: one`. `-nonexistent y`: status 2, `exec: -n: invalid option`. With `sh` as dash, the `-rec` and `-a` rows show no difference between old and new (127 for `-a`). The `eval` command produced no difference in calls between old and new under either shell, so the file ran.

**Evidence:** `$X/logs/diff-old-new.txt` (rows `nobwrap+unshare-ok+ip :: [ -- -rec -x]`, `[ -- -a x rec one]`, `[ -- -nonexistent y]`)

---

## Claim 15: D2 reproduced: the fallback run "exits 0 with one line on stderr, `confine-tests: denying network via unshare (loopback=1)`"; "the warning is inside the `primitive == bwrap && loopback == 0` branch (line 134)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 23ffb16c script on the stand-ins; does not cover a real unshare.
**Legibility-target:** for-orchestrator-synthesis

In R3 the old stderr on every fallback run is the banner alone, e.g. `--- old stderr` / `confine-tests: denying network via unshare (loopback=1)` for `-a x rec one`. R2: the new fallback-warning tests 15 and 20 fail against the old script.

**Evidence:** `git show 23ffb16c:scripts/confine-tests.sh` line 134; `$X/logs/diff-old-new.txt`; `$X/logs/bats-oldscript-newtests.txt`

---

## Claim 16: "The tests pin this: the selection tests are untouched, the fallback probe's stderr is pinned empty, and the `--no-loopback` probe's stderr is compared with the whole old warning, byte for byte."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff of the selection tests (7, 11, 13, 14); does not establish anything about the tests' strength (see Claims 28-30).
**Legibility-target:** for-author

The second and third parts hold: `[ -z "$stderr" ]` (`test/scripts/confine-tests.bats:373,378`) and `[ "$stderr" = "$LO_WARNING_TEXT" ]` (`:334`). "Untouched" is loose. Test 11 (`:327-336`) had two assertions replaced, by the whole-text comparison at `:334`, and test 14 (`:367-380`) gained the two `-z` assertions and a comment. Their selection assertions (`lines[0]`, `calls`) are unchanged. Precise version: "the selection tests' selection assertions are unchanged".

**Evidence:** `test/scripts/confine-tests.bats:327-336,367-380`; the diff hunks `@@ -312,8` and `@@ -347,33`

---

## Claim 17: "One status does move outside the dash-named cases; see 'Exit statuses' under Results."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47` (and the framing at `:299`, "The fourth is a status that moves outside the dash-named cases")
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unshare-with-loopback form on the stand-ins, with `sh` as dash and as bash, for the commands in R3; does not cover real primitives, or command shapes outside R3.
**Legibility-target:** for-author

At least two statuses move outside the dash-named cases, both where `sh` is dash. The empty name moves 126 → 127, which the doc records. A **directory found by PATH lookup** (a command `adir` where `$PATH` holds a directory `adir`) also moves 126 → 127, and nothing records it. R3, `nobwrap+unshare-ok+ip :: [ -- adir] | sh old=dash ... | status 126/127`, old stderr `sh: 6: exec: adir: Permission denied`, new stderr `confine-tests: unshare body: line 6: exec: adir: not found`. The same holds on the bwrap-refused route. bash's PATH search skips directories and dash's does not; the body now runs under bash (`scripts/confine-tests.sh:285`). A directory named by path (`./subdir`) gives 126 under both, and a non-executable file reached by PATH gives the same status under both. With `sh` as bash, `adir` was already 127. Precise version: "Two statuses move outside the dash-named cases on hosts where `sh` is dash: an empty name and a directory reached through PATH, both 126 → 127."

**Evidence:** `scripts/confine-tests.sh:285-290`; `$X/logs/diff-old-new.txt` (rows `[ -- adir]` and `[ -- ./subdir]`)

---

## Claim 18: "The script is not an enforcement file for `hooks/live-verify-gate.sh` [observed: its `enforcement` and `host_tools` patterns match only `devcontainer-config/`]"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two patterns; does not cover other gates.
**Legibility-target:** for-orchestrator-synthesis

`hooks/live-verify-gate.sh:83`: `enforcement='^devcontainer-config/(Dockerfile|...|egress/)'`; `:91`: `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|cc-verify\.sh)'`.

**Evidence:** `hooks/live-verify-gate.sh:83,91-93`

---

## Claim 19: Gotchas: "`exec -- "$@"` is right under bash, in posix mode too ..., and wrong under dash, which runs `--` as the command"; "`$BASH` is ... `<PATH dir>/bash` when the script starts through its shebang, the interpreter's path when started as `bash script`"; "`"$BASH" -c '... exec -- "$@"'` ... exits 127 for a name not on PATH (`-a` among them) and 126 for a directory"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:65-67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12; does not cover other shells.
**Legibility-target:** for-author

R12: `dash -c 'exec -- "$@"' sh echo hi` gives `exec: --: not found` with exit 127; bash and `bash --posix` print `hi`. R10: through the shebang `BASH=<dir>/tools/bash`, `bash s.sh` gives `BASH=/usr/bin/bash`, and an inherited `BASH=/evil` is overridden. The 127 for `-a` holds (R3). "126 for a directory" holds only for a directory named by a path (`./subdir`: 126, `cannot execute: Is a directory`). A directory reached through PATH exits 127 (`exec: adir: not found`, Claim 17). Precise version: "126 for a directory given as a path; 127 for one only PATH would find".

**Evidence:** `$X/logs/dash-exec.txt`; `$X/logs/p2.txt`; `$X/logs/diff-old-new.txt`

---

## Claim 20: "With the body under bash everywhere, the pid check (`same_process`) no longer tells `exec -- "$@"` from `"$@"` on any host. A test with a command named `eval` tells them apart by behaviour instead."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's handling of the last command of this `-c` body; does not cover other bash versions.
**Legibility-target:** for-orchestrator-synthesis

R14: with a bare `"$@"` (mutant m04), test 16, which calls `same_process`, passes. Test 17 fails later, at line 452 (the error-text assertion), after `same_process` at `:449` has passed: stderr `confine-tests: unshare body: line 6: -a: command not found`. R6: m04 and m05 (`command -- "$@"`) fail test 19, and m03 (`exec "$@"`) does not.

**Evidence:** `test/scripts/confine-tests.bats:443-455,467-474`; `$X/logs/m04-detail.txt`; `$X/logs/mutation-run.txt`

---

## Claim 21: The failure-pattern greps: the first returns, among others, FP-044, FP-050, FP-057, FP-058; "The second grep's hits (FP-025, FP-032, FP-046, FP-067, FP-118, FP-134)"; with the one-line description of each

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:73-79`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the IDs the two quoted greps return and the symptom slugs; does not judge relevance.
**Legibility-target:** for-orchestrator-synthesis

On a copy of `docs/failure-patterns.md` (`$X/fp.md`), the second grep returns exactly `FP-025 FP-032 FP-046 FP-067 FP-118 FP-134`, and the first returns 24 IDs including the four named. The slugs match, e.g. `docs/failure-patterns.md:192` `FP-050 ... symptom:unshare-tier-shares-host-mount-namespace-host-writes` and `:200` `FP-058 ... symptom:bwrap-runtime-failure-drops-the-computation-silently`.

**Evidence:** `docs/failure-patterns.md:167,174,186,188,192,199,200,209,260,276`

---

## Claim 22: "Prior pruning grep: no matches found for [exec, argv, dash, unshare, confine] (the `Pruned candidates` sections of `docs/decisions/*.md` hold nothing about how a shell body execs its arguments ...)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:89` (repeated at `:185`)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `Pruned candidates` sections of `docs/decisions/*.md` at 23ffb16c; does not change the parenthetical's conclusion, which holds.
**Legibility-target:** for-author

Decision 017's `## Pruned candidates and why` section (`docs/decisions/017-polyglot-test-hermeticity.md:120` on) contains `[4 bwrap confine-tests as an in-session gate]: **primitive absent** (finding 1); ...`, so a grep for `confine` matches. That entry is about running the gate inside the session, not about how a body execs its arguments, so the parenthetical is right. The "no matches found" statement is not. Precise version: "one match (decision 017's candidate 4, an in-session bwrap gate); none about how a shell body execs its arguments".

**Evidence:** `docs/decisions/017-polyglot-test-hermeticity.md:120-128`

---

## Claim 23: DD-1 table evidence: candidate 5 "a name holding `=` is read as an assignment (`a=b z` set a variable and tried to run `z`)"; candidate 12 "util-linux `unshare` has no such option"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:122,129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU env as `exec env --` under bash and util-linux 2.38.1's help text; does not cover other env or unshare builds.
**Legibility-target:** for-orchestrator-synthesis

R11: `env: 'z': No such file or directory`, exit 127, so `a=b` was taken as an assignment. R10: `unshare --help` has no line mentioning loopback or `lo` (`(none)`).

**Evidence:** `$X/logs/env-assign.txt`; `$X/logs/p2.txt`

---

## Claim 24: DD-2 "Other choices, one line each" (seven sentences: `warn_unshare_only HEADLINE FIRST-WORDS LINE...`; the two headlines via `command -v bwrap`, "unusable" as the script's existing word; `--no-loopback` without bwrap prints the fallback warning naming both steps, and "At 23ffb16c that route printed no warning at all"; the `--no-loopback` warning "byte for byte what it was"; the body's `$0` and `confine-tests: unshare body: line 6: exec: -a: not found`; `sh` leaves the built PATH; the dash test skips loudly)

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:205-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence against the code at bd312d15 and the runs; does not cover real primitives.
**Legibility-target:** for-orchestrator-synthesis

The function's shape is `scripts/confine-tests.sh:131-140`, and its callers are `:171-174,222-228`. The refusal wording is `It needs \`unshare -rn\`, which is unusable here.` (`:178`). R3: the old stderr on `--no-loopback` without bwrap is the banner alone, e.g. `[--no-loopback -- rec one]`. R1 test 15 asserts `"  (bubblewrap) and drop --no-loopback to get the hardened profile."` (`test/scripts/confine-tests.bats:401`). R5 and R2 test 11 confirm the bytes. R3 shows `confine-tests: unshare body: line 6: exec: -a: not found`. Setup is `for tool in bash cat awk` (`:65`), and the dash test reads `dash="$(type -P dash)" || skip "dash is not installed on this machine"` (`:463`).

**Evidence:** `scripts/confine-tests.sh:131-140,171-182,216-230`; `test/scripts/confine-tests.bats:65,401,463`; `$X/logs/diff-old-new.txt`; `$X/logs/p6465.txt`

---

## Claim 25: Test specification G4: "the unshare call's argv | `-rn -- <the script's bash> -c BODY confine-tests CMD...`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:245`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the body's `$0` word in the argv; does not affect the rest of the G4 row.
**Legibility-target:** for-author

Since bd312d15 the word after BODY is `"confine-tests: unshare body"` (`scripts/confine-tests.sh:290`: `exec -- "$@"' "confine-tests: unshare body" "${cmd[@]}"`). The test pins `"$BODY_NAME"` (`test/scripts/confine-tests.bats:42,425`). The G4 row still names `confine-tests`, the pass-1 version.

**Evidence:** `scripts/confine-tests.sh:290`; `test/scripts/confine-tests.bats:42,425`

---

## Claim 26: "17 tests become 21. Four are new (a dash-named command with `sh` as bash and as dash, a command named like a builtin, the fallback's warning)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:285`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count and the identity of the new tests; does not cover their strength.
**Legibility-target:** for-orchestrator-synthesis

At 23ffb16c there are 17 `@test`s. R1 lists 21, and tests 17-20 (`test/scripts/confine-tests.bats:457-508`) are the four new ones.

**Evidence:** `test/scripts/confine-tests.bats:457-508`; `$X/logs/bats-new.txt`

---

## Claim 27: The "Exit statuses" table: `-record -x` 2 / the command's own / the command's own; `-a x CMD one` CMD's own (**CMD ran**) / 127 / 127; `-nonexistent y` 2 / 127 / 127; `''` 127 / 126 (`exec: : Permission denied`) / 127

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:290-297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell with each shell as `sh` (and no `sh` for the branch) on the stand-ins; does not cover real primitives.
**Legibility-target:** for-orchestrator-synthesis

R3, route `nobwrap+unshare-ok+ip` (bwrap-refused identical). `-rec -x`: bash 2 → 7, dash 7 = 7. `-a x rec one`: bash 7 (`child.1: one`) → 127, dash 127 = 127. `-nonexistent y`: bash 2 → 127, dash 127 = 127. `EMPTY`: bash 127 = 127 (`sh: line 6: exec: : not found`), dash 126 (`sh: 6: exec: : Permission denied`) → 127. The new results are the same with no `sh` on PATH.

**Evidence:** `$X/logs/diff-old-new.txt`

---

## Claim 28: "Every other input the review compared, on every route, exits as before, and so does every `--probe`."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:299`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pass-1 review's input set (no directory reached through PATH) and every `--probe` in R3 (13 setups x 4 probe argument sets x 2 shells, plus no `sh`: stdout, stderr and status identical); does not establish that no other input moves: a directory reached through PATH does (Claim 17).
**Legibility-target:** for-orchestrator-synthesis

In R3 no `--probe`, `--no-loopback --probe`, `--probe --no-loopback` or `--probe --` pair differs in any stream or status. The only non-run differences are `--help` stdout (the header text changed, as intended). Status differences on runs: the D1 dash-named cases with `sh` as bash (`-rec`, `-a`, `-nonexistent`, `--help` and `-noexec` as command names), and, with `sh` as dash, `''` and `adir`. The pass-1 API review's table (`docs/reviews/api-consistency-review-2026-11-10-confine-tests-dash-and-fallback.md:28`) tested "a directory" by path, with 126 for both versions.

**Evidence:** `$X/logs/diff-old-new.txt`; `docs/reviews/api-consistency-review-2026-11-10-confine-tests-dash-and-fallback.md:28-29`

---

## Claim 29: Mutation run: "22 of 22 fail at least one test, and the unchanged script passes 21 of 21", with the table's failing-test sets and the test-number key

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:303-329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a re-run of the author's mutate.py against bd312d15 and the match between each mutant's code and its name; does not establish that the mutant set is complete.
**Legibility-target:** for-orchestrator-synthesis

R6 reproduces every row exactly (m00 `NONE`; m01 `16, 18, 19, 20, 21`; ... m22 `11, 20`; `SURVIVORS: none`). Read against `mutate.py`, each mutant is what its name says, with two looser names. m13 "headlines swapped" negates the `command -v bwrap` test, so it swaps each route's way back as well as its headline. m16 inserts its extra line after the EROFS line (which ends with the way back's first words) and before the later way-back lines, so the line lands after the shared text, inside the way back. The key matches R1's numbering: 11 and 12 the `--no-loopback` tests, 14 the fallback probe, 15 without `ip`, 16 argv, 17 and 18 the dash-named tests, 19 the builtin, 20 the warning, 21 `lo` not raised.

**Evidence:** `$X/mutate.py`; `$X/logs/mutation-run.txt`; `$X/logs/bats-new.txt`

---

## Claim 30: "Two runs came before this one. In the first, the 'extra line' mutant passed every test ... The test was strengthened (ca6cf3be), and the second run had no survivor (19 of 19). After review pass 1 changed the warning's shape, the mutants were rewritten for it and three were added."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:331`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the author's three run logs; does not re-run the earlier mutant sets.
**Legibility-target:** for-orchestrator-synthesis

`mutation-run-1.txt` ends `SURVIVORS: ['m16 the shared text differs on the fallback route']`. `mutation-run-2.txt` lists m01-m19, every one failing, with `SURVIVORS: none`. `mutation-run-3.txt` lists m01-m22: three added (m20-m22), and m16/m19/m07 renamed.

**Evidence:** `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/mutation-run-{1,2,3}.txt`

---

## Claim 31: "The test of the whole `--no-loopback` warning (test 11) also passes against the script at 23ffb16c" (also commit bd312d15: "passes against the script at 23ffb16c too")

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:333`; commit bd312d15
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 11 in both flag orders; does not cover the `--no-loopback` run test 12, which pins only the first line.
**Legibility-target:** for-orchestrator-synthesis

R2 (bd312d15 test file, 23ffb16c script): `ok 11 --no-loopback switches from bwrap to unshare and warns about what is lost, in either flag order`. Tests 1-14 pass; 15-21 fail, all on D1, D2 or the absent `sh`.

**Evidence:** `test/scripts/confine-tests.bats:327-336`; `$X/logs/bats-oldscript-newtests.txt`

---

## Claim 32: Gates: probe exit 3; "21 of 21 pass (the dash test runs here ...)"; hermeticity lint "exit 0: '143 test file(s) checked, no unstubbed network spawns'"; shellcheck "(the health check's command) | exit 0"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:339-342`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four gates re-run at bd312d15; does not cover the whole suite (Claim 33).
**Legibility-target:** for-orchestrator-synthesis

R7: probe `exit 3`; lint `hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.` `exit 0`; shellcheck `exit 0`. Its flags match `scripts/health-check.sh:525` (`shellcheck -x -e SC1091 -s bash -S warning "$f"`). R1: 21 `ok`, and test 18 (dash) ran.

**Evidence:** `scripts/health-check.sh:525`; `$X/logs/gates.txt`; `$X/logs/bats-new.txt`

---

## Claim 33: "`scripts/run-tests.sh` (whole suite, serial, output to a file) at ca6cf3be, before review | exit 0: 2012 of 2012 pass"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:343`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the author's files suite-1.txt and suite-1.head as the brief directs (not re-run); does not establish "serial", which the files do not record.
**Legibility-target:** for-author

`suite-1.head` reads `ca6cf3be`. `suite-1.txt` has `1..2012`, 2012 `ok` lines, no `not ok`, and ends `exit=0`. Two of the 2012 are skips (`ok 1190 ... # skip settings file has no permissions.allow array`, `ok 1191 ...`). The file opens `=== NOT RUN: 50 report-dependent suite(s) — no generated reports for their skill ===`. Precise version: "2012 of 2012 ok (2 skipped); 50 report-dependent suites not run".

**Evidence:** `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/suite-1.txt` lines 1, 148, 1338-1339, last; `.../suite-1.head`

---

## Claim 34: "Review": pass 1 at de1f4bf9 "one fact-check, then security, performance and API-consistency critics. No red", with what it found and what changed (re-wrap fixed in code; "and drop the flag"; "unusable here"; the body's `$0`; "where bwrap works"; "the first line of its stdout"; four doc sentences; two commit sentences that stand)

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:349-357`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match with the rubric's rows and the code at bd312d15; does not re-judge pass 1's verdicts (one is questioned in Claim 60).
**Legibility-target:** for-orchestrator-synthesis

The rubric `Status: 🟢 PASSES this pass — 0 red` (`docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:5`). A1 is the re-wrap, with the API critic's advice to keep it. C1, C2, C3, A2 and C4 are the four smaller fixes. A3, A6, A7 and A1's research `:47` are the four doc sentences. A4 and A5 are the two commit sentences. Each fix is present in the code (`scripts/confine-tests.sh:45,222,226-228,290`; `guides/test-hermeticity.md:63`).

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:5,37-44,55-59`

---

## Claim 35: "The test file is 516 lines"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:371`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count at bd312d15.
**Legibility-target:** for-orchestrator-synthesis

`wc -l test/scripts/confine-tests.bats` gives `516`.

**Evidence:** `test/scripts/confine-tests.bats:516`

---

## Claim 36: "`docs/decisions/018-...md:43,117` cite `scripts/confine-tests.sh:220`, which is no longer the pattern's line. The comment above the body now opens 'Decision 018's reference pattern'"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:375`
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and the new comment; does not cover other citations.
**Legibility-target:** for-orchestrator-synthesis

Line 220 of the final script is a bwrap comment line. The body now starts at `scripts/confine-tests.sh:285` (`exec unshare -rn -- "$BASH" -c '`), and `:274` reads `# Decision 018's reference pattern (a static body, values as positional`.

**Evidence:** `scripts/confine-tests.sh:274,285`; `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`

---

## Claim 37: "`bwrap` adds a read-only root, a private `/tmp` and a pid namespace to the network namespace. When `bwrap` is not installed or is unusable, a run falls back to `unshare -rn`, which denies the network and nothing else: the tests run as uid 0 against the real filesystem. The run goes ahead, and first prints a warning on stderr that names what is absent. `--probe` names the primitive it found (`bwrap` or `unshare`) on the first line of its stdout."

**Location:** `guides/test-hermeticity.md:59-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's behaviour on the stand-ins; does not cover the real filesystem effects of a real `unshare -r`.
**Legibility-target:** for-orchestrator-synthesis

The profile is `--ro-bind / /`, `--tmpfs /tmp` and `--unshare-pid` (`scripts/confine-tests.sh:253-264`). The fallback warning is printed before the banner (`:216-232`) and the run continues (R3 statuses are the child's). The probe's first stdout line is `:197`.

**Evidence:** `scripts/confine-tests.sh:197,216-264,284-292`; `$X/logs/diff-old-new.txt`

---

## Claim 38: "On the `unshare` fallback writes are not confined either (see 'Triage vs. ground truth')"

**Location:** `guides/test-hermeticity.md:183-184`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the cross-referenced section and its paragraph; does not cover a live write test.
**Legibility-target:** for-orchestrator-synthesis

`guides/test-hermeticity.md:42` is `## Triage vs. ground truth`. Its new paragraph (`:59-63`) says the tests "run as uid 0 against the real filesystem". The unshare forms add no mount options (`scripts/confine-tests.sh:285,292`).

**Evidence:** `guides/test-hermeticity.md:42,59-63`; `scripts/confine-tests.sh:285-292`

---

## Claim 39: Header: "A weaker primitive is a warning, on every run ... When bwrap is not installed or is unusable, the run falls back to unshare and goes ahead, and says first, on stderr, what that leaves unconfined. A --probe that falls back prints its verdict, which names the primitive, and not this warning."

**Location:** `scripts/confine-tests.sh:29-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runs and probes on every stand-in setup in R3; does not cover real primitives.
**Legibility-target:** for-orchestrator-synthesis

In R3 every run that reaches unshare (the fallback, or `--no-loopback` over bwrap) has the warning first on stderr. No fallback `--probe` differs from 23ffb16c, whose fallback probe stderr was empty (test 14, `test/scripts/confine-tests.bats:373,378`).

**Evidence:** `scripts/confine-tests.sh:168-174,196-200,216-232`; `$X/logs/diff-old-new.txt`

---

## Claim 40: LOOPBACK: "Where bwrap works, the script says so, in the fallback warning's words, on a run and on a --probe, and refuses outright when unshare is unusable. Where bwrap does not work, the flag changes nothing about the primitive, and a run prints the fallback's warning."

**Location:** `scripts/confine-tests.sh:44-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bwrap-ok, bwrap-refused and bwrap-absent setups with unshare ok, refused or absent; "in the fallback warning's words" read as "the shared text", since the headline and way back differ by design.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:168-182`: with bwrap working and unshare working, `warn_unshare_only` runs; otherwise `exit 2`. R3: `bwrap-ok+unshare-refused` and `bwrap-ok,nounshare` give 2 on probes and runs. Detection (`:88-100`) does not read `loopback`, so the primitive is the same with and without the flag (banner lines identical across all 500 differing pairs). Test 15 pins the fallback headline under `--no-loopback` (`test/scripts/confine-tests.bats:400`).

**Evidence:** `scripts/confine-tests.sh:88-100,168-182,216-230`; `$X/logs/diff-old-new.txt`

---

## Claim 41: "That split keeps the --no-loopback warning byte for byte what it was before the text was shared, so no --probe prints anything it did not print before."

**Location:** `scripts/confine-tests.sh:128-130`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout, stderr and status of every `--probe` in R3 (13 setups; `--probe`, `--no-loopback --probe`, `--probe --no-loopback`, `--probe --`; `sh` dash, bash or none) and the `--no-loopback` runs over bwrap; does not cover `--help`, whose output changed (it is not a probe).
**Legibility-target:** for-orchestrator-synthesis

R3: zero differing pairs in any probe argument set. On the non-fallback setups (bwrap ok, bwrap run-fails, no primitive), zero runs differ in any field. R5: the old and new stderr of `--no-loopback --probe` are identical (`old==new stderr`).

**Evidence:** `scripts/confine-tests.sh:131-140,171-174`; `$X/logs/diff-old-new.txt`; `$X/logs/p6465.txt`

---

## Claim 42: The fell_back comments: "Detection settled for unshare: bwrap is not installed, or its probe failed"; "only a run that is about to start prints it: --probe's output and the refusals above are unchanged. `command -v` runs nothing."; "bwrap cannot keep `lo` down, so the flag would switch to unshare again"

**Location:** `scripts/confine-tests.sh:147-148,209-215`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusals at `:176-205` (no `ip`, `--no-loopback` unservable, nothing to run) and the probes; does not count the refusal inside the body (`lo` cannot be raised), which comes after the warning, as the comment says.
**Legibility-target:** for-orchestrator-synthesis

The block sits after `exit 3` (`:190-194`), the probe exit (`:196-200`) and the empty-command exit (`:202-205`). R3: none of those outputs differ from 23ffb16c. R13 calls bwrap once (its probe), on both a fallback run and a `--no-loopback` fallback run: `calls: bwrap.1 child.1 ...`. `:168-174` switches to unshare whenever bwrap works and the flag is set.

**Evidence:** `scripts/confine-tests.sh:147-152,168-232`; `$X/logs/fbcount.txt`; `$X/logs/diff-old-new.txt`

---

## Claim 43: Comment above the body: "`--` ends exec's options so a command named `-a` is run (or not found), never read as one ... bash's exec takes options and needs the `--`, dash's takes none and would run `--` as the command ... bash's own errors read "confine-tests: unshare body: line N: ...", N a line of the body and not of this file."

**Location:** `scripts/confine-tests.sh:274-283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12; does not cover other shells as `sh`.
**Legibility-target:** for-orchestrator-synthesis

R12: `dash -c 'exec -a x echo hi'` gives `exec: -a: not found`, and `dash -c 'exec -- ...'` gives `exec: --: not found`. R3: `confine-tests: unshare body: line 6: exec: -a: not found`. Line 6 of the body string, which opens with a newline after `'` at `:285`, is the `exec -- "$@"` line (`:290`), not line 6 of the file.

**Evidence:** `scripts/confine-tests.sh:285-290`; `$X/logs/dash-exec.txt`; `$X/logs/diff-old-new.txt`

---

## Claim 44a: The brief's invariant, as met by the branch: "No change to which primitive is chosen ... or to `--probe`."

**Location:** `docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md:25`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 1924 old/new pairs in R3 (13 stand-in setups, with or without bwrap, with unshare ok or failing, `ip` present, absent or failing, both flag orders, `sh` as dash, bash or absent); does not cover real primitives.
**Legibility-target:** for-orchestrator-synthesis

Every one of the 500 differing pairs prints the same `denying network via <primitive>` banner in both versions (checked by script over `diff-old-new.txt`: `banner mismatches 0`). The other pairs are identical in every field. No probe pair differs.

**Evidence:** `$X/logs/diff-old-new.txt`

---

## Claim 44b: The brief's invariant, as met by the branch: "No change ... to exit statuses other than D1's"

**Location:** `docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md:25`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unshare-with-loopback form on the stand-ins; does not cover real primitives.
**Legibility-target:** for-author

With `sh` as bash, every status change is on a dash-named command (D1). With `sh` as dash, two non-dash-named inputs move 126 → 127: an empty name (recorded and argued as D1's consequence, research `:299`) and a directory reached through PATH (not recorded anywhere, Claim 17). Both come from the same interpreter swap, so the research doc's argument for the first covers the second, but the doc, commit bd312d15's Notes and the rubric's A8 name only the empty name.

**Evidence:** `scripts/confine-tests.sh:285-290`; `$X/logs/diff-old-new.txt`

---

## Claim 45: Test header: "the real bash, cat and awk, plus stand-ins for bwrap, unshare and ip (no sh: the script runs none, and two tests add one to show it makes no difference)"

**Location:** `test/scripts/confine-tests.bats:8-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the setup loop, the two `ln -s "$1" "$TOOLS/sh"` tests, and the script's runs with no `sh`; does not cover test 3, which uses the ambient PATH, as the header's "but one" says.
**Legibility-target:** for-orchestrator-synthesis

Setup: `for tool in bash cat awk; do` (`:65`). `dash_named_on_unshare` begins `ln -s "$1" "$TOOLS/sh"` (`:444`) and is called by tests 17 and 18 only. R3: the new script with no `sh` gives the same result as with `sh` linked to dash or bash, on every pair.

**Evidence:** `test/scripts/confine-tests.bats:8-11,65,443-465`; `$X/logs/diff-old-new.txt`

---

## Claim 46: "The whole --no-loopback warning, byte for byte what the script printed before the fallback came to share its text"

**Location:** `test/scripts/confine-tests.bats:29-38`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constant against the 23ffb16c script's output; does not cover other warnings.
**Legibility-target:** for-orchestrator-synthesis

R2: test 11 (`[ "$stderr" = "$LO_WARNING_TEXT" ]`, `:334`) passes against the 23ffb16c script. The constant's lines match the old echoes at `git show 23ffb16c:scripts/confine-tests.sh` lines 137-143.

**Evidence:** `test/scripts/confine-tests.bats:32-38,334`; `$X/logs/bats-oldscript-newtests.txt`

---

## Claim 47: "Fails the test when ... -STATUS is given and is not the exit status (bats' `run -N`; it warns about a 127 it was not told to expect)"

**Location:** `test/scripts/confine-tests.bats:149-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bats 1.8.2 and the `confine()` body at `:155-165`; does not cover other bats versions (the file requires 1.5.0).
**Legibility-target:** for-orchestrator-synthesis

`confine()` passes `if [[ "$1" == -[0-9]* ]]; then want=("$1"); shift; fi` on to `run "${want[@]}" --separate-stderr ...` (`:157,162`). R9: a plain `run` of a 127 passes but prints `BW01: \`run\`'s command \`bash -c exit 127\` exited with code 127 ...`. `run -127` of a 0 fails with `expected exit code 127, got 0`.

**Evidence:** `test/scripts/confine-tests.bats:155-165`; `$X/logs/bats127.txt`

---

## Claim 48: "This cannot see the body's own exec: the body runs under bash, which runs the last command of a -c string in place with or without it. The test with a command named eval sees it."

**Location:** `test/scripts/confine-tests.bats:170-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 20.
**Legibility-target:** for-orchestrator-synthesis

As Claim 20 (R6, R14): with a bare `"$@"` or `command -- "$@"` (m04, m05), `same_process` still passes in tests 16 and 17, and test 19 fails.

**Evidence:** `test/scripts/confine-tests.bats:173-175,467-474`; `$X/logs/m04-detail.txt`; `$X/logs/mutation-run.txt`

---

## Claim 49: "bash's exec takes options (-a NAME sets argv[0]) and dash's takes none, so a body that ends `exec "$@"` under sh runs `-a x CMD one` as CMD where sh is bash."

**Location:** `test/scripts/confine-tests.bats:440-442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12.
**Legibility-target:** for-orchestrator-synthesis

R3, old script with `sh` as bash: `-a x rec one` ran `child.1: one` with status 7. With `sh` as dash: 127. R12: dash gives `exec: -a: not found`.

**Evidence:** `$X/logs/diff-old-new.txt`; `$X/logs/dash-exec.txt`

---

## Claim 50: Names of the new and changed tests against their bodies (tests 14, 15, 16, 17, 18, 19, 20) and their comments ("The refusal is stderr's first line: nothing is about to run"; "all on stderr, once; and the run goes ahead"; "With nothing to run there is nothing to warn about")

**Location:** `test/scripts/confine-tests.bats:367-508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each name and comment against the assertions in its body (whole tests read); does not establish the assertions' strength beyond the mutation run.
**Legibility-target:** for-orchestrator-synthesis

Each name states what its assertions check. Test 15's `refused 3 "$NO_IP"` checks `stderr_lines[0]` (`:198-203`). Test 17 and 18 run `-record -x` (passes) and `-a x RECORD one` (fails, `-127`). Test 19 checks `call child 1 'touch pwned'` and `[ ! -e pwned ]`. Test 20 compares whole stderr strings, so "once" and "first" hold, and checks `[ "$status" -eq 7 ]`. One wording note: test 14's name says bwrap is "installed and refused" (the stand-in's mode name) where the script now says "unusable".

**Evidence:** `test/scripts/confine-tests.bats:198-203,367-508`

---

## Claim 51: Commit bd312d15: "Tests: 21 of 21; 22 of 22 mutants fail at least one test. Size: 270 code lines against 23ffb16c"; its finding labels (FC 22/35, API 2; Security 2; API 3; API 4; FC 3, API 1, API 6; FC 33b, 39, 45; API escalation) and the "Not changed" list

**Location:** commit bd312d15 (message body)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and the mapping to the rubric's rows; "code lines" is pr-prep's defined count (all changed lines outside `docs/`, `workflows/pr-prep.md:86-91`), which counts the guide's 11 lines.
**Legibility-target:** for-orchestrator-synthesis

R1: 21 `ok`. R6: 22 mutants, `SURVIVORS: none`. `git diff --numstat 23ffb16c..bd312d15` outside `docs/`: script `78 13`, test `132 36`, guide `9 2`, total 270. pr-prep's command is `git diff --numstat "$BASE"...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } ...'` (`workflows/pr-prep.md:91`). The labels map to rubric rows A1, C1, C2, C3, A2/C4, A3/A6/A7 and C5. "Not changed" maps to A4, A5, C6 and C7.

**Evidence:** `workflows/pr-prep.md:86-91`; `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:37-61`; `$X/logs/bats-new.txt`; `$X/logs/mutation-run.txt`

---

## Claim 52: Commit bd312d15 Notes: "On a host where sh is dash, an empty command name now exits 127 where it exited 126 (API 5)"

**Location:** commit bd312d15 (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty-name case; does not establish that it is the only such case: a directory reached through PATH moves the same way (Claim 17).
**Legibility-target:** for-orchestrator-synthesis

R3: `[ -- EMPTY] | sh old=dash ... | status 126/127`.

**Evidence:** `$X/logs/diff-old-new.txt`

---

## Claim 53: Commit ca6cf3be: a mutant printing "one extra line on the fallback route, after the four shared lines, passed every test"; "Each route's way back to bwrap's profile must now start on the sixth line"; "19 of 19 mutants now fail at least one test; the unchanged script passes 21 of 21"

**Location:** commit ca6cf3be (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit's own tree; the "sixth line" pins were replaced in bd312d15 (the way back now starts mid-way through the fifth line), which the research doc's history paragraph records.
**Legibility-target:** for-orchestrator-synthesis

R4: at ca6cf3be, 21 ok. That commit's test asserts `[[ "${stderr_lines[5]}" == "  Install bwrap"* ]]` (its `:481`) and likewise for the other routes (`:474,490`). `mutation-run-1.txt` and `-2.txt` support the survivor and the 19 of 19.

**Evidence:** `git show ca6cf3be:test/scripts/confine-tests.bats` lines 468-490; `$X/logs/at-commits.txt`; `mutation-run-{1,2}.txt`

---

## Claim 54: Commit 7ecf6ee3: "Relevant paths gains test/scripts/confine-tests.bats; a paragraph says what the unshare fallback leaves unconfined and that a run now warns about it"; "Last verified stays 2026-07-13"

**Location:** commit 7ecf6ee3 (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide's diff.
**Legibility-target:** for-orchestrator-synthesis

`guides/test-hermeticity.md:7` is `Last verified: 2026-07-13`, `:8` lists `test/scripts/confine-tests.bats`, and the paragraph is `:59-63`.

**Evidence:** `guides/test-hermeticity.md:7-8,59-63`

---

## Claim 55a: Commit 6465a156: "--probe is unchanged for every input"

**Location:** commit 6465a156 (message body)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script at 6465a156; true of bd312d15's script (Claim 41). Already recorded as wrong in commit bd312d15 ("true of this commit's script, not of that one's"), research `:355` and rubric A5.
**Legibility-target:** for-author

R5: at 6465a156, `--no-loopback --probe` with bwrap ok prints `with EROFS will succeed against the real filesystem.` / `Drop the flag to get the hardened profile (loopback is not egress — the` / `namespace has no route off the host).` in place of the old lines 5-7.

**Evidence:** `$X/logs/p6465.txt`; `$X/logs/p.at_6465a156_scripts.err`

---

## Claim 55b: Commit 6465a156: "Tests: 21 of 21 pass"; "The --no-loopback warning keeps its words and its first line; its line breaks moved"; "with --no-loopback and no usable bwrap the run prints the fallback's warning ...; that route printed no warning before"

**Location:** commit 6465a156 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that commit's tree and the 23ffb16c behaviour.
**Legibility-target:** for-orchestrator-synthesis

R4: `6465a156 exit 0 : 21 ok, 0 not ok`. R5 shows the moved line breaks with the same words. R3 shows old stderr on that route as the banner alone.

**Evidence:** `$X/logs/at-commits.txt`; `$X/logs/p6465.txt`; `$X/logs/diff-old-new.txt`

---

## Claim 56: Commit bd657ce8: "`-- -a x CMD one` ran CMD and exited 0, and `-- -record -x` was refused. Where sh is dash the same line was right, and `exec -- "$@"` is wrong there (dash runs `--`)"; "a name that is no file exits 127 with nothing run in its place. The script no longer needs sh."; "Tests: 19 of 21 pass; the two left are the fallback warning (next commit)."

**Location:** commit bd657ce8 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dash-named commands ("the same line was right" for those; for an empty name or a directory reached through PATH, dash's status differs, see Claim 44b) and that commit's tree.
**Legibility-target:** for-orchestrator-synthesis

R4: `bd657ce8 exit 1 : 19 ok, 2 not ok` (15 and 20), both failing on `[ "${stderr_lines[0]}" = "$NO_BWRAP_WARNING" ]`. R12 shows `exec: --: not found` under dash. R3 shows the new script with no `sh` matching itself with `sh`.

**Evidence:** `$X/logs/bats-at-bd657ce8.txt`; `$X/logs/dash-exec.txt`; `$X/logs/diff-old-new.txt`

---

## Claim 57a: Commit d03a3078: "7 of the 21 fail at this commit"; test 17 "refuses `-record -x` (exit 2, 'exec: -r: invalid option')"; "With sh linked to dash the same test fails only on the name bash's error will carry after the fix"; "the unfixed script's `sh -c` body cannot start"; "confine() takes bats' -STATUS ..."

**Location:** commit d03a3078 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that commit's test file against its script (the 23ffb16c script).
**Legibility-target:** for-orchestrator-synthesis

R4: tests 15-21 fail. Test 17: `status: 2`, `sh: line 6: exec: -r: invalid option`. Test 18: stderr `sh: 6: exec: -a: not found` against the expected `$BODY_NAME: line ...` prefix. Tests 16, 19 and 21: status 127, `stub/unshare/unshare: line 29: exec: sh: not found`.

**Evidence:** `$X/logs/bats-at-d03a3078.txt`

---

## Claim 57b: Commit d03a3078: the 7 failing tests fail "each for the reason it names"

**Location:** commit d03a3078 (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 20 at that commit; already recorded as wrong in commit bd312d15's "Not changed", research `:355` and rubric A4.
**Legibility-target:** for-author

R4: test 20 (the D2 warning test) fails at `[ "$status" -eq 7 ]` with status 127 and `exec: sh: not found`, before any warning assertion. It fails for the third bullet's reason, not for "prints no warning: defect D2". Test 15 does fail on the missing warning (`[ "${stderr_lines[0]}" = "$NO_BWRAP_WARNING" ]' failed`).

**Evidence:** `$X/logs/bats-at-d03a3078.txt` (blocks `not ok 15`, `not ok 20`)

---

## Claim 58: Commit de1f4bf9: "pr-prep's fallback pre-mortem check fired on 539 changed lines (301 of them the research doc; 238 code lines, no enforcement file, no high-risk path)"; "Size: 238 code lines against 23ffb16c"

**Location:** commit de1f4bf9 (message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts against pr-prep's defined "code lines" count (all changed lines outside `docs/`); does not cover "no high-risk path" beyond the enforcement patterns.
**Legibility-target:** for-orchestrator-synthesis

Numstat as in Claim 1: 539 total before the pre-mortem, 301 research, and 238 outside `docs/`, which is exactly what `workflows/pr-prep.md:91` counts as "code lines". Pass 1 marked this "Mostly accurate" (rubric A7, "includes the guide's 11 lines") on a narrower reading of "code" than pr-prep's own definition. By the workflow's definition the figure is right.

**Evidence:** `workflows/pr-prep.md:86-91`; `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:43`

---

## Claim 59: Commit de1f4bf9: "Four narratives, none a must-address"; "under the unshare fallback the suite runs as uid 0, so this repo's four tests that skip as root skip"

**Location:** commit de1f4bf9 (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the pre-mortem's structure and the four uid checks (Claim 5); does not establish that only four tests skip under the fallback (Claim 6, Unverifiable).
**Legibility-target:** for-orchestrator-synthesis

The pre-mortem has four `### N.` narratives and `**Must address before proceeding:** none.` (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:57`). The four uid-0 skips are as in Claim 5.

**Evidence:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:18-57`

---

## Claim 60: Research "Review": pass 1's corrected sentence "'238 code lines'" is listed among "Four wrong or loose sentences"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:354`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the doc reports what pass 1 found and changed; the finding itself is questionable (Claim 58), which does not make the report of it wrong.
**Legibility-target:** for-orchestrator-synthesis

Rubric A7 records the finding, and the pre-mortem now reads "238 lines change outside `docs/` (227 in the script and its test, 11 in the guide)" (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`).

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:43`; `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`): the quoted prior-art grep returns 17 files, not the 4 named.
- **Claim 17** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`): "One status does move outside the dash-named cases". Two do, both where `sh` is dash: the empty name, and a directory reached through PATH (126 → 127), which nothing records.
- **Claim 22** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:89,185`): "no matches found" for the prior-pruning grep. Decision 017's Pruned candidates matches `confine` (candidate 4). The conclusion, nothing about exec'ing a body, holds.
- **Claim 44b** (`docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md:25`): the brief's "no change to exit statuses other than D1's" is not met for a directory reached through PATH on dash hosts. The change is the same kind as the recorded empty-name case, and nothing records it.
- **Claim 55a** (commit 6465a156): "--probe is unchanged for every input" was false at that commit. Already recorded (bd312d15, research `:355`, rubric A5).
- **Claim 57b** (commit d03a3078): "each for the reason it names": test 20 failed on `exec: sh: not found`. Already recorded (bd312d15, research `:355`, rubric A4).

### Stale
- **Claim 25** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:245`): G4's argv names the body's `$0` as `confine-tests`; it is `confine-tests: unshare body` since bd312d15.

### Mostly Accurate
- **Claim 16** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`): "the selection tests are untouched": tests 11 and 14 were edited. Only their selection assertions are unchanged.
- **Claim 19** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:67`): "126 for a directory" holds for a directory given as a path. One found through PATH exits 127.
- **Claim 33** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:343`): "2012 of 2012 pass" includes 2 skips, and 50 report-dependent suites were not run. "Serial" is not recorded in the files.

### Unverifiable
- **Claim 6** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:370`; pre-mortem `:22`): "four tests fewer" under the fallback needs a real `unshare -rn` run. `test/scripts/build-loop-orchestrator.bats:394` (a `stat -c %u == 0` check on `/opt/claude-workflows`) should also skip under a user namespace (inferred).

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/code-fact-check-report-final-rN-2026-11-10-confine-tests-dash-and-fallback.md (N your replicate number), structured per the code-fact-check skill, with a first line `Commit: bd312d15` and a bolded `**Commit:** bd312d15` header field.
- Answered: yes (N = 1)
- Out of scope: real-primitive behaviour (no namespace in this container); the whole suite was not re-run (the brief says to read suite-1.txt); the hallucination-pattern log was not written (no fabrication found, and this pass may write only this report)
- Escalate: the undisclosed exit-status change (directory reached through PATH, 126 → 127 where `sh` is dash; Claims 17, 44b) goes to the api-consistency critic, which owned the empty-name finding (API 5 / rubric A8); the possible fifth uid-mapping skip (Claim 6) goes to the cycle's follow-up for the first live run
- Decisions I made: execution logs live in the scratch directory, not under `docs/reviews/execution-logs/`, because this pass forbids other writes to the worktree; I judged "code lines" by pr-prep's own definition (Claims 51, 58), which differs from pass 1's A7 reading
