Commit: 6276e42c

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback`, branch `fix/confine-tests-dash-and-fallback`)
**Scope:** commit 6276e42c (range bd312d15..6276e42c): the claims it adds or changes in `scripts/confine-tests.sh`, `test/scripts/confine-tests.bats`, `guides/test-hermeticity.md`, `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md`, `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md` and its commit message; plus eight claims submitted by the final pass's critics
**Commit:** 6276e42c
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-11-10
**Total claims checked:** 56 (46 harvested, 10 submitted, counting split sub-claims)
**Summary:** 43 verified, 7 mostly accurate, 0 stale, 2 incorrect, 4 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged fabrication pattern; the two Incorrect verdicts are a miscount (a helper read as one test), which the skill keeps out of the log.

Execution provenance. Every executed claim ran in the scratch directory `$X` = `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-i3-factcheck`, never in the worktree except where a gate was run read-only in the worktree (noted). The 23ffb16c, bd312d15 and 6276e42c scripts and test files were extracted with `git show`. No namespace can be created here: `scripts/confine-tests.sh --probe` exits 3, and even the real `unshare --` with no namespace flags fails with "unshare failed: Operation not permitted" (`$X/unshare-pid.txt`), so everything below runs on stand-ins.

| Run | Command (cwd) | Exit | Started (local, -08:00) | Output |
|---|---|---|---|---|
| R1 | `timeout 120 bash $X/exit-probe.sh` (`$X/exitprobe/work`, set inside) | 0 | 2026-11-10T14:58:40 | `$X/exit-probe.out` |
| R2 | `timeout 590 python3 -I mutate.py /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback $X/mut` (`$X`) | 0 | 2026-11-10T14:59:50 | `$X/mutation-run-i3.txt` |
| R3 | `timeout 300 bats test/scripts/confine-tests.bats`; `timeout 300 scripts/hermeticity-lint --root .`; `timeout 120 shellcheck -x -e SC1091 -s bash -S warning scripts/confine-tests.sh test/scripts/confine-tests.bats`; `timeout 30 scripts/confine-tests.sh --probe` (worktree, read-only) | 0, 0, 0, 3 | 2026-11-10T15:01:42 | `$X/gate-bats.txt`, `$X/gate-lint.txt`, `$X/gate-shellcheck.txt`, `$X/gate-probe.txt` |
| R4 | `timeout 500 bash $X/trees.sh` (`$X/trees`): the 6276e42c test file against the 23ffb16c script; then `bats --timing` three times each on the 23ffb16c, bd312d15 and 6276e42c trees | 0 (inner: 1, then 0 x9) | 2026-11-10T15:03:24 | `$X/trees.out`, `$X/trees/oldscript-newtest.txt`, `$X/trees/*-timing-*.txt`, `$X/timing.out` |
| R5 | `timeout 500 bash $X/matrix.sh` (`$X/matrix/work`): 504 old-against-new `--probe` pairs (bwrap absent/ok/refused/run-fails x unshare absent/ok/refused x ip absent/present x `sh` none/bash/dash x 7 probe spellings) and 144 new-script runs checked for warning order | 0 | 2026-11-10T15:04:28 | `$X/matrix.out`, `$X/matrix/routes.txt` |
| R6 | `timeout 120 bash $X/closed-stderr.sh` (`$X/closed/work`): five routes to unshare with stderr closed, with stderr a pipe whose reader has exited, and the same with SIGPIPE ignored | 0 | 2026-11-10T15:04:54 | `$X/closed-stderr.out` |
| R7 | `timeout 30 bash $X/uidlines.sh`; `grep -n not_root test/cc-isolated-functions.bats` (worktree, read-only) | 0 | 2026-11-10T15:06 | `$X/uidlines.sh` output in the transcript; restated in Claim 3a |
| R8 | `grep -ril ... docs/decisions/ docs/working/` (pre-mortem's) and `grep -B 1 -A 20 "Pruned candidates" docs/decisions/*.md \| grep -iE 'exec\|argv\|dash\|unshare\|confine'` (worktree, read-only) | 0 | 2026-11-10T15:07 | `$X/premortem-grep.txt`, `$X/pruning-grep.txt` |
| R9 | `taskset 0x1 adir`, `ionice -c2 adir`, `setarch x86_64 adir` with a directory `adir` first on PATH (util-linux 2.38.1) | 126 each | 2026-11-10T15:06 | `$X/ul-taskset.txt`, `$X/ul-ionice.txt`, `$X/ul-setarch.txt` |

---

## Claim 1: "details below were brought up to date after the two review passes changed the warning's wording and corrected the prior-art sentence"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the pre-mortem's narrative 1 now quotes the 6276e42c headline and that its prior-art sentence was rewritten in 6276e42c; does not establish that every other detail in the pre-mortem is current (see Claim 3a).
**Legibility-target:** for-orchestrator-synthesis

The observable outcome at `:22` now reads "the run's file starts with `confine-tests: WARNING — bwrap is unusable here`", which is the headline at `scripts/confine-tests.sh:222` (`warn_unshare_only "bwrap is unusable here; falling back to the unshare primitive."`), and `:14` is the rewritten prior-art sentence (diff bd312d15..6276e42c, quoted in the shared review context).

**Evidence:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:3`, `:14`, `:22`; `scripts/confine-tests.sh:222`

---

## Claim 2: "returns 17 files: decisions 017 and 019, the three confine-tests research docs (this unit's among them) and both confine-tests briefs, five cycle logs, and five other working docs"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted grep's file list at 6276e42c; does not establish what the author read in them ("I read the confine-tests ones and decision 017") or that narratives 2 to 4 appear in none of the 17.
**Legibility-target:** for-orchestrator-synthesis

R8 returns exactly 17 paths: `docs/decisions/017-polyglot-test-hermeticity.md`, `019-arithmetic-eval-sandboxing.md`; `research-2026-11-07-confine-tests-situation.md`, `research-2026-11-10-confine-tests-bats.md`, `research-2026-11-10-confine-tests-dash-and-fallback.md`; `briefs/2026-11-10-confine-tests-dash-and-fallback.md`, `briefs/closed/2026-11-10-confine-tests-bats.md`; `cycles/cycle-2026-10-02.md`, `-10-14`, `-10-15`, `-10-17`, `-11-10`; and five others (`diagnosis-cc-isolated-login-dns.md`, `plan-build-loop-handoff.md`, `questions-archive.md`, `research-2026-11-01-restriction-audit.md`, `research-2026-11-05-d6-block-into-image.md`). Each group's count matches.

**Evidence:** `$X/premortem-grep.txt` (R8)

---

## Claim 3a: "so the four tests guarded by `[ "$(id -u)" -ne 0 ] || skip` (`test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889`, `test/install-host.bats:680`, `test/cc-isolated-functions.bats:1970`) skip"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how many tests carry that guard at 6276e42c (unchanged since 23ffb16c); does not establish which of them a real `unshare -r` run would skip (no namespace here), nor the fifth, uid-mapping skip (Claim 31b).
**Legibility-target:** for-author

Three of the four locations are guards inside a test, but `test/cc-isolated-functions.bats:1970` is the body of a helper, not a test:

```bash
# test/cc-isolated-functions.bats:1968-1971
# not_root: permission tests mean nothing to root, who can list anything.
not_root() {
  [ "$(id -u)" -ne 0 ] || skip "running as root: directory permissions are not enforced"
}
```

`not_root` is called as the first line of seven tests (`test/cc-isolated-functions.bats:2067`, `:2084`, `:2184`, `:2198`, `:2263`, `:2278`, `:2701`; the same seven at 23ffb16c). So ten tests are guarded by that form, not four. The same undercount sits in the unedited Severity line `:24` ("four permission tests").

**Evidence:** `test/cc-isolated-functions.bats:1968-1971`, `:2066-2067`, `:2700-2701`; `test/cc-push.bats:417`; `test/hooks/guard-trusted-writes.bats:889`; `test/install-host.bats:680`; R7

---

## Claim 3b: "lists at least four skips that an unconfined run does not have"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that at least four (in fact ten, Claim 3a) tests are guarded on uid 0; does not establish the run itself, which needs a real `unshare -rn`.
**Legibility-target:** for-orchestrator-synthesis

"At least four" holds against the ten guarded tests found in Claim 3a (paraphrased — no quote available because the count is the union of the grep and the seven `not_root` call sites listed there).

**Evidence:** as Claim 3a

---

## Claim 4: "The run prints the new warning as the file's first six lines" and the file "starts with `confine-tests: WARNING — bwrap is unusable here`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unusable-bwrap route with loopback, on stand-ins; does not establish that a real cc-isolated image reaches that route (the narrative's premise).
**Legibility-target:** for-orchestrator-synthesis

With bwrap installed and refused, unshare ok, `ip` present, the 6276e42c script printed six warning lines (headline, three heredoc lines, the EROFS line ending "Run on a host", then "  where bwrap works to get the hardened profile.") and the banner as line seven (R5 route output; the full text is quoted under Claim 36).

**Evidence:** `scripts/confine-tests.sh:131-140`, `:221-224`, `:232`; `$X/matrix/routes.txt`

---

## Claim 5: "`grep -rn confine-tests` over code finds no caller, only a comment in `test/fixture-hermeticity.bats`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:33`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `*.sh`, `*.bats`, `*.py` outside the script and its own test file; does not establish callers in other repositories.
**Legibility-target:** for-orchestrator-synthesis

The only hit outside the script and its test file is `test/fixture-hermeticity.bats:15`: `# namespace: scripts/confine-tests.sh -- scripts/run-tests.sh --all`, a comment.

**Evidence:** `test/fixture-hermeticity.bats:15`; grep run 2026-11-10T15:08 in the worktree (output in this session's transcript; one hit as quoted)

---

## Claim 6: "at 23ffb16c this unit's test 15 fails on the missing warning, and test 20, the fallback warning's own test, fails earlier there because the built PATH has no `sh`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 6276e42c test file run against the 23ffb16c script; does not establish the first unit's observation the sentence also cites.
**Legibility-target:** for-orchestrator-synthesis

R4's first run: tests 15-21 fail. Test 15 fails at `test/scripts/confine-tests.bats:400`, `` `[ "${stderr_lines[0]}" = "$NO_BWRAP_WARNING" ]' failed``, with stderr only `confine-tests: denying network via unshare (loopback=0)`. Test 20 fails at `:492`, `` `[ "$status" -eq 7 ]' failed`` with status 127 and `stub/unshare/unshare: line 29: exec: sh: not found`, before any stderr comparison.

**Evidence:** `$X/trees/oldscript-newtest.txt`; `test/scripts/confine-tests.bats:395-401`, `:491-496`

---

## Claim 7: "the selection tests keep their status, verdict and call-count assertions (two gained checks of stderr) ... Three statuses for a command that cannot be run, or could not be, do move outside the dash-named cases"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the diff 23ffb16c..6276e42c of tests 11 and 14 and the three moved statuses of Claim 15; does not establish which tests the author counts as "the selection tests" beyond those two.
**Legibility-target:** for-orchestrator-synthesis

In the test diff, test 14 gained `[ -z "$stderr" ]` twice (`test/scripts/confine-tests.bats:373`, `:378`) and kept its status, verdict and `calls` lines; test 11's first-line-plus-substring check became `[ "$stderr" = "$LO_WARNING_TEXT" ]` (`:334`). The three moved statuses (empty name, directory through PATH on dash hosts, no `sh`) are the table's last three rows, each reproduced in R1 (Claim 15).

**Evidence:** `git diff 23ffb16c 6276e42c -- test/scripts/confine-tests.bats`; `test/scripts/confine-tests.bats:327-336`, `:367-380`; `$X/exit-probe.out`

---

## Claim 8: "exits 127 for a name not on PATH (`-a` among them) and 126 for a directory given as a path"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 6276e42c body under bash 5.2.15 with stand-ins; does not establish the directory-through-PATH case, which exits 127 (Claim 15).
**Legibility-target:** for-orchestrator-synthesis

R1: `./pdir` (a directory) exits 126 with `exec: .../pdir: cannot execute: Is a directory` for `sh` bash, dash and absent; `-a x CMD one` exits 127 (`confine-tests: unshare body: line 6: exec: -a: not found`).

**Evidence:** `$X/exit-probe.out`; `scripts/confine-tests.sh:285-290`

---

## Claim 9: "Prior pruning grep (...): eight lines match, in decisions 014, 015, 017, 028, 030, 035 and 037. One names this script: decision 017's `[4 bwrap confine-tests as an in-session gate]`, pruned there because a session has no primitive."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep's output and the 017 entry's text; does not establish the doc's one-word subject labels for the other six decisions beyond a reading of each line.
**Legibility-target:** for-orchestrator-synthesis

The given pipeline prints 8 lines: two from 014, one each from 015, 017, 028, 030, 035, 037. Decision 017's entry reads `[4 bwrap confine-tests as an in-session gate]: **primitive absent** (finding 1); ⚠ on H5, because it would silently not-enforce.` No matching line is about how a shell body execs its arguments (paraphrased — no quote available because the other seven lines are long one-line lists of unrelated candidates; they are saved in `$X/pruning-grep.txt`).

**Evidence:** `$X/pruning-grep.txt` (R8); `docs/decisions/017-polyglot-test-hermeticity.md` (Pruned candidates)

---

## Claim 10: "Prior pruning grep: matches in seven decisions, one of them naming this script (...), none about how a body execs its arguments"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:146`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 9.
**Legibility-target:** for-orchestrator-synthesis

Same output as Claim 9: seven distinct decisions.

**Evidence:** `$X/pruning-grep.txt`

---

## Claim 11: "the two need different actions from the reader ("Install bwrap" against "Run on a host where bwrap works")"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:206`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two fallback headlines and ways back as printed; does not establish that "unusable" is the script's only word for a non-working primitive.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:221-229
  if command -v bwrap >/dev/null 2>&1; then
    warn_unshare_only "bwrap is unusable here; falling back to the unshare primitive." \
      "Run on a host" \
      "where bwrap works$and_flag to get the hardened profile."
  else
    warn_unshare_only "bwrap is not installed; falling back to the unshare primitive." \
      "Install bwrap" \
      "(bubblewrap)$and_flag to get the hardened profile."
  fi
```
(excerpt ends :229; the enclosing `if [[ "$fell_back" -eq 1 ]]` block runs :216-230 — read.) R5's route lines show each headline on its route.

**Evidence:** `scripts/confine-tests.sh:216-230`; `$X/matrix/routes.txt`

---

## Claim 12: "on that route the way back names both steps ("Install bwrap (bubblewrap) and drop --no-loopback", or "Run on a host where bwrap works and drop --no-loopback" ...). At 23ffb16c that route printed no warning at all."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fallback routes with `--no-loopback` on stand-ins, and the 23ffb16c code path; does not establish line breaks (the quoted phrases cross one).
**Legibility-target:** for-orchestrator-synthesis

`and_flag=" and drop --no-loopback"` is set when `loopback -eq 0` (`scripts/confine-tests.sh:217-220`). R5 shows both routes' first line; the unusable route's text with the flag is quoted under Claim 36. At 23ffb16c the only warning sits inside `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]` (`git show 23ffb16c:scripts/confine-tests.sh`, the selection block), so a fallback with the flag printed only the banner.

**Evidence:** `scripts/confine-tests.sh:216-230`; 23ffb16c script, selection block; `$X/matrix/routes.txt`

---

## Claim 13: G4: "`-rn -- <the script's bash> -c BODY 'confine-tests: unshare body' CMD...`, BODY the same for two commands"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argv the stand-in recorded in test 16; does not establish what a real unshare does with it.
**Legibility-target:** for-orchestrator-synthesis

`call unshare 2 -rn -- "$TOOLS/bash" -c "${first[4]}" "$BODY_NAME" "$RECORD" "${TRICKY[@]}"` (`test/scripts/confine-tests.bats:425`) with `BODY_NAME='confine-tests: unshare body'` (`:42`); test 16 passes in R3.

**Evidence:** `test/scripts/confine-tests.bats:409-438`; `$X/gate-bats.txt`

---

## Claim 14: "the old-against-new runs of both review passes, the final pass's on up to 4,536 runs per reviewer; a row marked * was run by a reviewer and not by me"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:290`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the largest replicate's count in "runs"; does not establish the authorship split for each row.
**Legibility-target:** for-orchestrator-synthesis

Replicate r2 reports "That is 2268 cases and 4536 runs" (`docs/reviews/code-fact-check-report-final-r2-2026-11-10-confine-tests-dash-and-fallback.md:16`), the largest of the three.

**Evidence:** `docs/reviews/code-fact-check-report-final-r2-2026-11-10-confine-tests-dash-and-fallback.md:16`

---

## Claim 15: Every cell of the eight-row "Exit statuses" table

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:292-301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unshare-with-loopback form, bwrap absent, on stand-ins, with `sh` linked to bash 5.2.15, to dash, and absent, for the 23ffb16c and 6276e42c scripts; does not establish a real unshare's behaviour.
**Legibility-target:** for-orchestrator-synthesis

R1 reproduces every cell, the * rows included:

| Command | old, sh=bash | old, sh=dash | new (bash / dash / none) |
|---|---|---|---|
| `-record -x` | 2 (`sh: line 6: exec: -r: invalid option`) | 7 (ran) | 7 / 7 / 7 |
| `-a x CMD one` | 7 (CMD ran) | 127 | 127 x3 |
| `-- CMD` | 7 (CMD ran) | 127 (`exec: --: not found`) | 127 x3 |
| `-p CMD` | 2 | 127 | 127 x3 |
| `-nonexistent y` | 2 | 127 | 127 x3 |
| `''` | 127 | 126 (`sh: 6: exec: : Permission denied`) | 127 x3 |
| `adir` (directory on PATH) | 127 | 126 (`sh: 6: exec: adir: Permission denied`) | 127 x3 (`exec: adir: not found`) |
| no `sh` on PATH | every command 127 (`stub/unshare: line 3: exec: sh: not found`) | — | the command's own (`CMD one` 7) |

**Evidence:** `$X/exit-probe.out` (R1); `$X/exit-probe.sh`

---

## Claim 16: "A directory given as a path, and a file without the execute bit, exit 126 before and after."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:303`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hosts with `sh` (bash or dash) on PATH; on a host with no `sh` the old script exited 127 for these too, which the table's last row already covers.
**Legibility-target:** for-orchestrator-synthesis

R1: `./pdir` and `./noexec` exit 126 for old with sh=bash and sh=dash, and for new with every `sh`.

**Evidence:** `$X/exit-probe.out`

---

## Claim 17: "(bash as `sh` already gave 127 for the empty name and the directory) ... The review found all three (pass 1's API critic the empty name; the final pass's fact-check the directory and the API critic the host with no `sh`)."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:305`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two statuses and the attributions in the rubric and reports; does not establish the author's judgment that these count as D1's.
**Legibility-target:** for-orchestrator-synthesis

R1: old with sh=bash gives 127 for `''` and for `adir`. Rubric A8: "an empty command name exited 126 at 23ffb16c and exits 127 now (A 5)"; merged report M1 names r1's directory finding; the final API review lists "**A host with no `sh` (every run 127 → the command runs).**" (`docs/reviews/api-consistency-review-final-2026-11-10-confine-tests-dash-and-fallback.md:78`).

**Evidence:** `$X/exit-probe.out`; `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:56`; `docs/reviews/code-fact-check-report-final-2026-11-10-confine-tests-dash-and-fallback.md:17`

---

## Claim 18a: "for a bare name that matches a directory on PATH, the loopback form now exits 127 where a real `unshare` on the `--no-loopback` form would exit 126 (...the test file's stand-ins exec through bash and cannot show it)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:307`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 127 on the loopback form (executed) and supporting evidence for the 126 from sibling util-linux tools; does not establish what `unshare` 2.38.1 itself exits, which needs a host that allows `unshare -rn`.
**Legibility-target:** for-orchestrator-synthesis

The 127 half is shown (R1). The real `unshare` here refuses before exec even with no namespace flags ("unshare: unshare failed: Operation not permitted", `$X/unshare-pid.txt`), so the 126 cannot be run. What can be run: three util-linux 2.38.1 tools that exec their argument the same way exit 126 for the same directory on PATH and 127 for a missing name (`taskset: failed to execute adir: Permission denied`, exit 126; likewise `ionice`, `setarch`, R9), which agrees with the critic's `execvp` model. That the stand-ins cannot show it is right: they `exec --` under bash (`test/scripts/confine-tests.bats:135`), and bash's PATH search skips directories.

**Evidence:** `$X/exit-probe.out`; `$X/ul-taskset.txt`, `$X/ul-ionice.txt`, `$X/ul-setarch.txt`, `$X/unshare-pid.txt`; blocker: no user namespace in this container

---

## Claim 18b: "every `--probe` is byte for byte the same in stdout, stderr and status"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:307`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 504 probe inputs of R5 on stand-ins; does not establish probes under a real bwrap or unshare, or "every other input ... exits as before" beyond R1's ten commands.
**Legibility-target:** for-orchestrator-synthesis

R5: "probe pairs compared: 504, differing: 0".

**Evidence:** `$X/matrix.out`, `$X/matrix.sh`

---

## Claim 19: The mutation table: "24 of 24 fail at least one test, and the unchanged script passes 21 of 21", with each row's failing tests

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:311-337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 24 mutants of `mutate.py` (read: each substitution does what its row says, e.g. m13 negates `command -v bwrap`, m16 inserts a line after the EROFS line and before the way back's later lines, m20 breaks only after "filesystem.", m23/m24 drop `$and_flag` on one route each) re-run against 6276e42c; does not establish that the mutants cover every plausible defect.
**Legibility-target:** for-orchestrator-synthesis

R2 output matches every row exactly, e.g. `m23 ... failing tests: 20`, `m24 ... failing tests: 15`, `m15 ... failing tests: 15, 20`; control `NONE`; `SURVIVORS: none`.

**Evidence:** `$X/mutation-run-i3.txt`; `$X/mutate.py:47-72`

---

## Claim 20: "11, 12 and 13 are the `--no-loopback` tests (13, the flag's refusal, fails under no mutant here: none touches that branch), 14 the fallback probe, 15 unshare without `ip`, 16 the unshare run's argv, 17 and 18 the dash-named command ..., 19 the builtin's name, 20 the fallback's warning, 21 `lo` not raised"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:339`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test positions in R3's TAP output and the mutants' substitution targets; does not establish anything about test 13's own strength.
**Legibility-target:** for-orchestrator-synthesis

R3 numbers the tests as listed (e.g. `ok 13 --no-loopback is refused (exit 2), probe or run, when bwrap works and unshare does not`). 13 appears in no R2 row, and no mutant edits the refusal `else` branch at `scripts/confine-tests.sh:175-182` (m14 removes only `LO_WARN`, inside the `if`).

**Evidence:** `$X/gate-bats.txt`; `$X/mutation-run-i3.txt`; `$X/mutate.py:33-37`, `:61`

---

## Claim 21: The history paragraph: "Three runs came before this one ... (19 of 19) ... three were added (22 of 22) ... test 20 gained that route and the last two mutants were added."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:341`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four run logs, ca6cf3be's message and the final security review; does not establish the replaced m16 code (not saved).
**Legibility-target:** for-orchestrator-synthesis

Run 1 ends `SURVIVORS: ['m16 the shared text differs on the fallback route']`; run 2 has m01-m19 and `SURVIVORS: none`; run 3 has m01-m22 (m20-m22 new); run 4 adds m23, m24. ca6cf3be: "the comparison stopped at the fourth. ... 19 of 19 mutants now fail". The final security review's finding 2 is headed "a mutant that drops it passes ev[ery test]" (`docs/reviews/security-review-final-2026-11-10-confine-tests-dash-and-fallback.md:63`).

**Evidence:** `.../scratchpad/2026-11-10-confine-tests-dash-and-fallback/mutation-run-1.txt` to `-4.txt`; `git log -1 ca6cf3be`; `docs/reviews/security-review-final-2026-11-10-confine-tests-dash-and-fallback.md:63-84`

---

## Claim 22: Gates: "21 of 21 pass (the dash test runs here ...)"; lint "exit 0: "143 test file(s) checked, no unstubbed network spawns""; shellcheck "exit 0"; probe "exit 3"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:349-352`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four commands at 6276e42c in this container; does not establish a confined run.
**Legibility-target:** for-orchestrator-synthesis

R3: `1..21`, all `ok`, test 18 with no `# skip`; `hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.`; shellcheck exit 0, empty output; probe exit 3, first line `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`

**Evidence:** `$X/gate-bats.txt`, `$X/gate-lint.txt`, `$X/gate-shellcheck.txt`, `$X/gate-probe.txt`

---

## Claim 23: Whole-suite row: "one file at a time, the runner's default ... at ca6cf3be ... exit 0: 2012 `ok` lines and no `not ok`. Two of the 2012 are skips ... (tests 1190 and 1191 ...), and the runner lists 50 report-dependent suites as NOT RUN"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:353`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the saved output and the runner's default; does not establish that this run was started without `--jobs` (the output does not record the invocation), and the suite was not re-run (per the brief for this pass).
**Legibility-target:** for-orchestrator-synthesis

`suite-1.head` holds `ca6cf3be`; `suite-1.txt` has 2012 `^ok ` lines, 0 `^not ok`, `ok 1190 ... # skip settings file has no permissions.allow array` and `ok 1191 ... # skip ...`, first line `=== NOT RUN: 50 report-dependent suite(s) — no generated reports for their skill ===`, last line `exit=0`. The runner's default is serial by file: `jobs=1` (`scripts/run-tests.sh:135`), and its usage says "1, the default, runs serially" (`:41`).

**Evidence:** `.../scratchpad/2026-11-10-confine-tests-dash-and-fallback/suite-1.txt:1`, `:1338-1339`; `suite-1.head`; `scripts/run-tests.sh:39-41`, `:135`

---

## Claim 24: "`scripts/lite-review.py --range de1f4bf9..bd312d15 --mode fix-drift` ... "FINDINGS: NONE""

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:354`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The author's record of a run; this pass did not repeat it.
**Legibility-target:** for-orchestrator-synthesis

The drift check makes a model call, and this container has no egress; no captured output of it is in the scratch directory (paraphrased — no quote available because no output file exists to quote). The rubric's pass-1 line agrees: "the fix-commit drift check over de1f4bf9..bd312d15 reported no findings" (`docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:9`), which is the same author's record.

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:9`; blocker: execution needs a model call

---

## Claim 25: "`docs/reviews/code-review-rubric-...md` has every finding of the three iterations and what was done with it."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:358`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric's contents at 6276e42c; does not establish whether it will be updated after this pass.
**Legibility-target:** for-author

At 6276e42c the rubric covers two iterations: its first line is `Commit: bd312d15` and its scope "23ffb16c..bd312d15 (the whole branch at passes 1 and 2)" (`docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:1`, `:5`). Iteration 3 is this pass, whose findings do not yet exist. Precise version: "every finding of the first two iterations" (until the rubric is updated).

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:1-19`

---

## Claim 26: "each replicate ran the old script against the new on 1,650 to 4,536 inputs"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:367`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three replicate reports' own counts; does not establish the replicates' results, only their size.
**Legibility-target:** for-author

The three figures are in different units. r1: "1924 pairs" (`code-fact-check-report-final-r1-...md:22`); r2: "2268 cases and 4536 runs" (`-r2-...md:16`), i.e. 4,536 counts both scripts' runs; r3: "1650 runs of each script" (`-r3-...md:26`). By inputs the range is 1,650 to 2,268; by runs of both scripts, 3,300 to 4,536.

**Evidence:** the three replicate reports at the cited lines; `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:19`

---

## Claim 27: The final pass's bullets: one amber (security, Medium); "short by three cases (the directory through PATH, two more dash-named inputs, a host with no `sh`)"; "Test 20 now runs the other, and two mutants pin each"; "its headline ran to 101 characters"; "Twelve wrong, stale or loose sentences ..., among them two search results reported as narrower than they were ..., the test-plan row that still named the old `$0`, and the whole-suite count given without its two skips"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:367-373`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers each count against the rubric, the merged report and the code; "Twelve" is a count of the author's own grouping and is confirmed only as consistent (see below).
**Legibility-target:** for-orchestrator-synthesis

The old headline `confine-tests: WARNING — bwrap is installed but unusable here; falling back to the unshare primitive.` is 101 characters (Python `len`, 103 bytes). Test 20 runs the unusable route with the flag (`test/scripts/confine-tests.bats:507-511`); m23 fails 20, m24 fails 15, and m21 fails both (R2), so each route is pinned by two mutants. Rubric A9 is the one Medium amber. Twelve doc sentences: rubric rows A11, A12, A13, A17 and the seven of A14 make 11, and A15's research-doc paraphrase makes 12; M2/M3 are the two searches, M6 the G4 row, M9 the suite count (paraphrased — no quote available because the count is assembled from five rubric rows).

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:57-65`; `$X/mutation-run-i3.txt`; Python length run in this session

---

## Claim 28: "d03a3078 says each of its seven failing tests fails "for the reason it names" ...; 6465a156 says `--probe` is unchanged for every input ... and paraphrases H2 without "refuses"; ca6cf3be says the way back "must now start on the sixth line" ...; bd312d15's Notes name only the empty name among the statuses that moved."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:375`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four messages' text; the "true from bd312d15 on" qualifier rests on R5 and the replicates.
**Legibility-target:** for-orchestrator-synthesis

d03a3078: "7 of the 21 fail at this commit, each for the reason it names". 6465a156: "--probe is unchanged for every input" and "(constraint H2 in docs/constraints.md: a degraded primitive names what went unenforced)". ca6cf3be: "Each route's way back to bwrap's profile must now start on the sixth line". bd312d15's Notes: "an empty command name now exits 127 where it exited 126 (API 5)", no other status.

**Evidence:** `git log -1` of d03a3078, 6465a156, ca6cf3be, bd312d15

---

## Claim 29: "the final pass's API critic modelled bwrap as exiting 1 and unshare as 127 or 126, which is a model, not a run"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:385`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the API report says; not the real tools.
**Legibility-target:** for-orchestrator-synthesis

The API report: "**Confidence:** Medium (bwrap and unshare columns are a model of the real tools)" and "'could not exec' is 126/127 on unshare and 1 on bwrap" (`docs/reviews/api-consistency-review-final-2026-11-10-confine-tests-dash-and-fallback.md:110`, `:127`).

**Evidence:** `docs/reviews/api-consistency-review-final-2026-11-10-confine-tests-dash-and-fallback.md:105-128`

---

## Claim 30: "`docs/constraints.md` H2 reads: "a missing dependency, ... degradation only ever narrows access."" and the brief "says the run "still goes ahead" and lists "a refusal in place of the fallback" as out of scope, and the brief's own sentence about H2 leaves "refuses" out"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:389`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted clause of H2 at 23ffb16c (unchanged on the branch) and the brief; the quote is a clause, not all of H2.
**Legibility-target:** for-orchestrator-synthesis

`git show 23ffb16c:docs/constraints.md` line 6 contains the quoted text verbatim ("a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive refuses and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access."). Brief `:24`: "The run still goes ahead under `unshare`"; `:40`: "a refusal in place of the fallback"; `:13`: "Constraint H2 ... says a degraded primitive names what went unenforced".

**Evidence:** 23ffb16c `docs/constraints.md:6`; `docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md:13`, `:24`, `:40`

---

## Claim 31a: "Under the unshare fallback the suite runs as uid 0, so at least four tests here skip, each on a guard of the form `[ "$(id -u)" -ne 0 ] || skip` (four locations)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:391`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of uid-guarded tests; does not establish the skips under a real namespace.
**Legibility-target:** for-author

"At least four" is true, but the sentence presents its four locations as four tests and one is the helper `not_root()` (`test/cc-isolated-functions.bats:1969-1971`) called by seven tests (Claim 3a). Precise version: ten tests skip on that guard (three directly, seven through `not_root`).

**Evidence:** as Claim 3a

---

## Claim 31b: "A fifth probably does too, for another reason (`test/scripts/build-loop-orchestrator.bats:394` checks an owner uid that `unshare -r` leaves unmapped; inferred by a reviewer, not run)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:391`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what line 394 checks; does not establish the skip, which needs `unshare -r`.
**Legibility-target:** for-orchestrator-synthesis

`[[ -f "$O/scripts/build-loop.sh" && "$(stat -c %u "$O/scripts")" == 0 ]] || skip "no root-owned image copy at $O here"` (`test/scripts/build-loop-orchestrator.bats:394`). Here `/opt/claude-workflows/scripts` exists and is owned by uid 0, so the test runs unconfined; under `unshare -r` only the caller's uid is mapped, so host root would show as the overflow uid and the guard would skip. That is inference; no namespace can be made here.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-395`; `stat -c %u /opt/claude-workflows/scripts` → `0` (this session); blocker: no user namespace

---

## Claim 32: "The test file is 525 lines"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:392`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file at 6276e42c.
**Legibility-target:** for-orchestrator-synthesis

`wc -l test/scripts/confine-tests.bats` → `525`.

**Evidence:** `test/scripts/confine-tests.bats:525`

---

## Claim 33: "count which tests skip as uid 0 on the unshare tier (four are known, a fifth is likely)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:398`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the number of tests known by grep to carry the uid-0 guard; does not establish the live count.
**Legibility-target:** for-author

Ten are known: the three direct guards plus the seven tests that call `not_root()` (Claim 3a). A first live run told "four are known" would check four and miss six. Precise version: "ten carry the uid-0 guard (seven through `not_root` in `test/cc-isolated-functions.bats`), a further one is likely".

**Evidence:** `test/cc-isolated-functions.bats:1969-1971`, `:2067`, `:2084`, `:2184`, `:2198`, `:2263`, `:2278`, `:2701`; R7

---

## Claim 34: "The run goes ahead, and first prints a warning on stderr that names what is absent (`--no-loopback` switches to the same primitive and prints the same warning)."

**Location:** `guides/test-hermeticity.md:62-63`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text printed on each route (R5); does not establish anything about probes beyond the guide's next line.
**Legibility-target:** for-author

Where bwrap works, `--no-loopback` prints its own warning (`warn_unshare_only "--no-loopback forces the unshare primitive." "Drop the flag to" ...`, `scripts/confine-tests.sh:171-174`), which shares the middle text with the fallback warning but has a different headline and way back, and is also printed on a `--probe`. Where bwrap does not work, `--no-loopback` prints the fallback's warning. Precise version: "prints a warning with the same text about what is absent".

**Evidence:** `scripts/confine-tests.sh:131-140`, `:168-175`, `:216-230`; `$X/matrix/routes.txt`

---

## Claim 35: "Under the `unshare` primitive (the fallback, or `--no-loopback`) writes are not confined either (see "Triage vs. ground truth")."

**Location:** `guides/test-hermeticity.md:184-186`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both routes reach `exec unshare -rn` with no filesystem confinement, and that the cited section exists; does not establish write behaviour under a real namespace.
**Legibility-target:** for-orchestrator-synthesis

`--no-loopback` either switches to `primitive="unshare"` (`scripts/confine-tests.sh:170`) or exits 2 (`:181`); the fallback is `primitive == unshare` from detection (`:150-152`); both end in `exec unshare -rn -- ...` (`:285`, `:292`), which has no `--ro-bind`. `## Triage vs. ground truth` is `guides/test-hermeticity.md:42`.

**Evidence:** `scripts/confine-tests.sh:150-152`, `:168-183`, `:284-292`; `guides/test-hermeticity.md:42`

---

## Claim 36: The reworded warning as printed on the unusable-bwrap route, with and without `--no-loopback`; the script's comments otherwise unchanged in this commit

**Location:** `scripts/confine-tests.sh:222-224`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text on stand-ins and the 3-line diff; does not establish wording quality.
**Legibility-target:** for-orchestrator-synthesis

Printed (R5 route, `cat -A` checked, no trailing spaces):

```
confine-tests: WARNING — bwrap is unusable here; falling back to the unshare primitive.
  It denies the network and NOTHING ELSE. bwrap's read-only rootfs, its
  private /tmp and its pid namespace are all absent, and your tests run
  as uid 0 in a user namespace: a stray write that bwrap would refuse
  with EROFS will succeed against the real filesystem. Run on a host
  where bwrap works to get the hardened profile.
confine-tests: denying network via unshare (loopback=1)
```
With `--no-loopback` the sixth line is `  where bwrap works and drop --no-loopback to get the hardened profile.` and the banner says `loopback=0`. `git diff --numstat bd312d15 6276e42c -- scripts/confine-tests.sh` is `3 3`, all three lines in the call at `:222-224`.

**Evidence:** `scripts/confine-tests.sh:221-224`; `$X/matrix/routes.txt`; this session's transcript of the route run

---

## Claim 37: "The naming half of constraint H2 (a degraded primitive "refuses and names what went unenforced"): the run is kept, by the brief, and says what it lacks."

**Location:** `test/scripts/confine-tests.bats:476-477`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotation and the brief's keep-the-run line; not whether keeping it satisfies H2.
**Legibility-target:** for-orchestrator-synthesis

H2 contains "degraded primitive refuses and names what went unenforced" (23ffb16c `docs/constraints.md:6`); the brief keeps the run (`docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md:24`).

**Evidence:** `test/scripts/confine-tests.bats:476-478`; 23ffb16c `docs/constraints.md:6`

---

## Claim 38: "The same with --no-loopback: bwrap alone would not serve the flag, so the way back names both steps (the not-installed case is in the test above)."

**Location:** `test/scripts/confine-tests.bats:505-506`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the not-installed-with-flag case is pinned; does not establish the new route's exit status, which the added block does not assert (it checks stderr and, through `calls child 4`, that the child ran).
**Legibility-target:** for-author

The not-installed case with the flag is in test 15, four tests up, not the adjacent test 19 (the `eval` test): `confine "unshare" STUB_UNSHARE=ok -- --no-loopback -- -record -x` ... `[ "${stderr_lines[5]}" = "  (bubblewrap) and drop --no-loopback to get the hardened profile." ]` (`test/scripts/confine-tests.bats:395-401`). That test pins lines 0 and 5 of that warning only, not the whole text as the new block does. Precise version: "(the not-installed case is in the test of unshare without `ip`, above)".

**Evidence:** `test/scripts/confine-tests.bats:382-407`, `:467-474`, `:505-512`

---

## Claim 39: Test 14's name: "--probe reports unshare when bwrap is not installed, or is installed and unusable"

**Location:** `test/scripts/confine-tests.bats:367`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two routes the test runs.
**Legibility-target:** for-orchestrator-synthesis

The test runs `confine "unshare ip" STUB_UNSHARE=ok -- --probe` and `confine "bwrap unshare ip" STUB_BWRAP=refused STUB_UNSHARE=ok -- --probe`, each asserting `primitive available: unshare (loopback=1)` (`:370-379`); it passes (R3).

**Evidence:** `test/scripts/confine-tests.bats:367-380`; `$X/gate-bats.txt`

---

## Claim 40: Commit 6276e42c: "each replicate ran the 23ffb16c script against bd312d15's on 1,650 to 4,536 stand-in runs and found every --probe byte-identical and the primitive unchanged"

**Location:** commit 6276e42c message, paragraph 1
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** As Claim 26; the byte-identity result is consistent with R5 at 6276e42c.
**Legibility-target:** for-author

As Claim 26: r1's 1,924 are pairs, r3's 1,650 are runs of each script, r2's 4,536 are runs of both scripts (2,268 inputs). The range mixes units. The rest holds: the merged report's row "every probe byte-identical in stdout, stderr and status" (`docs/reviews/code-fact-check-report-final-2026-11-10-confine-tests-dash-and-fallback.md:40`).

**Evidence:** replicate reports (see Claim 26); merged report `:40-41`

---

## Claim 41: Commit 6276e42c, "Code and tests": security final 2 (flag note tested on one route; test 20 now runs the other; two new mutants, one per route, each fail a test); API final 4 (101-character headline; new wording); API final 2 and 5, M15 (test 20 drops "(H2)", a comment quotes the constraint; test 14 says "unusable"; the guide's Known-gaps bullet names both routes)

**Location:** commit 6276e42c message, "Code and tests"
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each change against the diff and R2/R5; does not establish wording quality.
**Legibility-target:** for-orchestrator-synthesis

Verified in Claims 19, 27, 36, 37, 35 and 39: m23 fails 20, m24 fails 15; the headline was 101 characters; test 20's name no longer contains "(H2)" (`test/scripts/confine-tests.bats:478`) and the comment at `:476-477` quotes H2; `guides/test-hermeticity.md:184-185` names "(the fallback, or `--no-loopback`)". The final security review's finding 2 is the flag note (`docs/reviews/security-review-final-2026-11-10-confine-tests-dash-and-fallback.md:63`).

**Evidence:** see the cited claims

---

## Claim 42: Commit 6276e42c, "Docs": the status list ("where sh is dash, a bare name that matches a directory found through PATH went from 126 to 127; where sh is bash, `-- CMD` and `-p CMD` go to 127; on a host with no sh a loopback run went from 127 to running"); "Twelve wrong, stale or loose sentences ..., two of them searches reported as narrower than they were"; "The research doc quotes constraint H2 word for word."

**Location:** commit 6276e42c message, "Docs"
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 15, 27, 30.
**Legibility-target:** for-orchestrator-synthesis

R1 reproduces each status move (Claim 15); the twelve and the two searches as Claim 27; the H2 clause is verbatim (Claim 30).

**Evidence:** `$X/exit-probe.out`; see the cited claims

---

## Claim 43: Commit 6276e42c: "Not changed, by the brief: the fallback still runs after warning ... (security final 1, Medium)"; "Tests: 21 of 21; 24 of 24 mutants fail at least one test."; "Size: 283 code lines against 23ffb16c"; Notes: routed claims go to iteration 3's fact-check; "The test file is 525 lines"

**Location:** commit 6276e42c message, closing paragraphs
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each count at 6276e42c; "283" counts the guide's markdown lines with the code, as pr-prep's count does.
**Legibility-target:** for-orchestrator-synthesis

The fallback still runs (R5: every unshare route exits with the child's status after the warning). R3: 21 of 21; R2: 24 of 24. `git diff --numstat 23ffb16c 6276e42c` outside `docs/`: guide 11+2, script 78+13, test 142+37 = 283. The routed claims are Part 2 of this report. 525 lines (Claim 32).

**Evidence:** `$X/gate-bats.txt`; `$X/mutation-run-i3.txt`; numstat run in this session; `$X/matrix/routes.txt`

---

## Submitted Claims

## Claim 44: "On the unshare-with-loopback run form, no word of the test command is spliced into the shell body: the body is the same text for any command, and each word reaches the command as its own argv element."

**Submitted by:** security-reviewer
**Location:** `scripts/confine-tests.sh:285-290`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the body string and the argv the command receives on stand-ins, for the TRICKY words and R1's commands; does not establish what a real `unshare` passes on (it is handed the argv unchanged by `exec`), nor the BASH_ENV/exported-function exposure of `"$BASH" -c` (out of the threat model, S1).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:284-291
if [[ "$loopback" -eq 1 ]]; then
  exec unshare -rn -- "$BASH" -c '
    if ! ip link set lo up; then
      echo "confine-tests: failed to bring loopback up inside the namespace." >&2
      exit 3
    fi
    exec -- "$@"' "confine-tests: unshare body" "${cmd[@]}"
fi
```
The body is one single-quoted literal with no expansion of `cmd`; the words follow as separate arguments. Test 16 (`test/scripts/confine-tests.bats:409-438`) passes: the body is equal for two commands, contains neither `$RECORD`, `pwned` nor `two words`, and the child received `"${TRICKY[@]}"` exactly (empty word, newline, `$(touch pwned)` among them) with no `pwned` file.

**Evidence:** `scripts/confine-tests.sh:284-291`; `test/scripts/confine-tests.bats:409-438`; `$X/gate-bats.txt`

---

## Claim 45: "A dash-named first word of the command is never read as an option of `exec`, whichever shell `sh` is."

**Submitted by:** security-reviewer
**Location:** `scripts/confine-tests.sh:285-290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 as `$BASH`, with `sh` linked to bash, to dash, and absent, for `-record`, `-a`, `--`, `-p`, `-nonexistent`; does not establish other bash versions, or a run of the script under a non-bash interpreter (which the script's own `[[` would already break).
**Legibility-target:** for-orchestrator-synthesis

The body runs under `"$BASH"`, not `sh`, and ends `exec -- "$@"`. R1: on 6276e42c every dash-named case gives the same result for all three `sh` settings: `-record -x` runs the file (7); `-a`, `--`, `-p`, `-nonexistent` each exit 127 with `exec: <word>: not found`, i.e. the word was taken as a command name, not an option. Tests 17 and 18 pass (R3).

**Evidence:** `$X/exit-probe.out`; `$X/gate-bats.txt`

---

## Claim 46: "Every route that ends in `exec unshare` prints the right warning first, and a warning that cannot be written (stderr closed, or a closed pipe) stops the script before the run."

**Submitted by:** security-reviewer
**Location:** `scripts/confine-tests.sh:131-140`, `:171`, `:222`, `:226`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five routes to unshare (fallback not-installed / unusable, each with and without `--no-loopback`; `--no-loopback` over a working bwrap) on stand-ins, with stderr closed, a broken pipe with SIGPIPE default and ignored; does not establish a stderr that is open but blocks (a full pipe nobody reads stalls the script rather than stopping it), or that a `--no-loopback --probe` with stderr closed is also stopped (it is: the warning there is printed at selection).
**Legibility-target:** for-orchestrator-synthesis

Every `primitive=unshare` route passes through one of the three calls: detection fallback sets `fell_back=1` (`:150-152`) and the block at `:216-230` warns; the `--no-loopback` switch warns at `:171`. R5: 30 of 66 runs reaching a banner printed a warning, every one before the banner, and no run reached `via unshare` without one; the headline matches the route (routes.txt). R6: on all five routes, stderr closed exits 1, broken pipe exits 141, broken pipe with SIGPIPE ignored exits 1, and the child never runs; the control with stderr open runs it. The mechanism is `set -euo pipefail` (`:56`) with the `echo`, `cat` and `printf` of `warn_unshare_only` called as plain statements.

**Evidence:** `scripts/confine-tests.sh:56`, `:131-140`, `:147-152`, `:168-183`, `:216-232`; `$X/matrix.out`, `$X/matrix/routes.txt`, `$X/closed-stderr.out`

---

## Claim 47a: "... any other call exits 99 and fails the test."

**Submitted by:** security-reviewer
**Location:** `test/scripts/confine-tests.bats:110-147`, `:155-165`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers calls outside each stand-in's accepted argv prefixes and modes; see 47b for what the accepted shapes let through.
**Legibility-target:** for-orchestrator-synthesis

Any argv that matches no accepted branch reaches `printf 'stub %s: unexpected call ...' >> "$STUB_LOG/unexpected"` then `exit 99` (`test/scripts/confine-tests.bats:144-145`), and `confine()` ends `[[ ! -e "$LOG/unexpected" ]]` (`:164`), a plain statement in every test, so bats' errexit fails the test whatever the script did with the 99.

**Evidence:** `test/scripts/confine-tests.bats:110-147`, `:155-165`

---

## Claim 47b: "The test file's stand-ins for bwrap, unshare and ip accept only the exact calls the script makes"

**Submitted by:** security-reviewer
**Location:** `test/scripts/confine-tests.bats:110-147`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which argv the stand-ins accept; does not establish which tests pin the exact argv with `call` (tests 2, 7, 8, 9, 12, 14, 15, 16 do).
**Legibility-target:** for-author

They accept exact prefixes with the command words free: bwrap accepts the run profile followed by any words (`elif [[ $# -gt ${#profile[@]} ]] && is "${profile[@]}" "${@:${#profile[@]}+1}"`, `:124`), unshare accepts `-rn --` followed by any words (`elif [[ $# -ge 3 && "$mode" == ok ]] && is -rn -- "${@:3}"`, `:134`). On the unshare run form the first free word is the interpreter, so a script that calls `unshare -rn -- bash -c ...` is accepted: mutant m06 (`bash` by name) passes every test but 16, which catches it with `call` (R2). Precise version: "accept only the argv shapes the script uses, with the command (and on the loopback form the interpreter and body) left free; the exact argv is pinned by `call` in specific tests".

**Evidence:** `test/scripts/confine-tests.bats:117-143`, `:425`; `$X/mutation-run-i3.txt` (m06)

---

## Claim 48a: "On the unshare-with-loopback form the test command runs as the script's own pid: every step from the script to the command is an exec."

**Submitted by:** performance-reviewer
**Location:** `scripts/confine-tests.sh:284-291`; `test/scripts/confine-tests.bats:173-175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's and the body's steps, on stand-ins; does not establish the real `unshare` (48b). The body forks once for `ip link set lo up`, which is not a step to the command.
**Legibility-target:** for-orchestrator-synthesis

The script `exec`s unshare (`:285`), the body ends `exec -- "$@"` (`:290`), and the stand-in `exec`s its command (`test/scripts/confine-tests.bats:135`). `same_process` (`cmp -s "$LOG/script-pid" "$LOG/child-pid"`, `:174`) passes in tests 16, 17 and 18 (R3). As the test comment says, the check cannot see the body's own `exec` (bash runs the last command of `-c` in place); the eval test (19) does.

**Evidence:** `scripts/confine-tests.sh:284-291`; `test/scripts/confine-tests.bats:167-175`, `:419`, `:449`; `$X/gate-bats.txt`

---

## Claim 48b: (same assertion, the real `unshare -rn` step)

**Submitted by:** performance-reviewer
**Location:** `scripts/confine-tests.sh:285`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether util-linux `unshare -rn` (no `--fork`) execs without forking; not runnable here.
**Legibility-target:** for-orchestrator-synthesis

`unshare --help` (util-linux 2.38.1) lists ` -f, --fork                fork before launching <program>`, which implies no fork by default, and the script passes no `-f`. Running it is blocked: `unshare -- bash -c 'echo $$'` fails with "unshare failed: Operation not permitted" (`$X/unshare-pid.txt`).

**Evidence:** `$X/unshare-pid.txt`; blocker: no user namespace

---

## Claim 49: "The test file's added run time is in proportion to its four added tests, with no slowdown of the 17 existing ones (about 1.1 s at 23ffb16c, about 1.4 to 1.5 s at bd312d15)."

**Submitted by:** performance-reviewer
**Location:** `test/scripts/confine-tests.bats`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers three timed runs per tree on this machine (load average about 0.55); wall times vary by host and load.
**Legibility-target:** for-orchestrator-synthesis

R4 wall times: 23ffb16c 1.16, 1.17, 1.08 s; bd312d15 1.48, 1.52, 1.48 s; 6276e42c 1.46, 1.41, 1.52 s. Median per-test times (bats `--timing`): the 17 existing tests sum to 790 ms at 23ffb16c and 798 ms at 6276e42c (within noise, each test within a few ms); the four added tests take 59, 58, 37 and 97 ms (251 ms), close to the 260 ms rise in the per-test sum. 6276e42c's extra route in test 20 adds no measurable time over bd312d15.

**Evidence:** `$X/trees.out`, `$X/timing.out`, `$X/trees/t23-timing-*.txt`, `$X/trees/tbd-timing-*.txt`, `$X/trees/t62-timing-*.txt`

---

## Claim 50: "On every route that prints a warning, the warning comes before the banner `confine-tests: denying network via ...` on stderr."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/confine-tests.sh:171`, `:216-232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers R5's 144 runs on stand-ins (30 warned); does not establish probes, which print no banner (the `--no-loopback --probe` warning has no banner to precede).
**Legibility-target:** for-orchestrator-synthesis

The `--no-loopback` warning prints at selection (`:171`), the fallback warning at `:216-230`, both before `echo "confine-tests: denying network via $primitive (loopback=$loopback)" >&2` (`:232`). R5: "runs reaching the banner: 66, of them warned: 30, order/unwarned-unshare problems: 0".

**Evidence:** `scripts/confine-tests.sh:168-232`; `$X/matrix.out`

---

## Claim 51: "Every `--probe` prints the same stdout and stderr and exits with the same status at 6276e42c as at 23ffb16c."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/confine-tests.sh`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 504 probe inputs (4 bwrap modes x 3 unshare modes x ip absent/present x `sh` none/bash/dash x 7 spellings: `--probe`, both flag orders, `--probe -- CMD x`, `--no-loopback --probe -- CMD`, `--probe --`, `--probe --probe`) on stand-ins; does not establish probes under a real bwrap or unshare, or with stderr closed.
**Legibility-target:** for-orchestrator-synthesis

R5: "probe pairs compared: 504, differing: 0". The fallback warning is printed only after the `--probe` exit at `:196-200`.

**Evidence:** `scripts/confine-tests.sh:196-230`; `$X/matrix.out`, `$X/matrix.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3a** (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21`): "the four tests guarded by ..." counts a helper as one test: `test/cc-isolated-functions.bats:1970` is `not_root()`, called by seven tests, so ten tests carry the guard (the unedited Severity line `:24` repeats "four").
- **Claim 33** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:398`): "four are known, a fifth is likely": ten are known by grep; a live count told four would miss six.

### Stale
- none

### Mostly Accurate
- **Claim 25** (research doc `:358`): the rubric holds two iterations' findings, not three (its header is `Commit: bd312d15`).
- **Claim 26** (research doc `:367`): "1,650 to 4,536 inputs" mixes units; inputs range 1,650 to 2,268 (4,536 is r2's runs of both scripts).
- **Claim 31a** (research doc `:391`): "at least four" is true, but one of the four locations is a helper with seven callers; ten tests skip on that guard.
- **Claim 34** (`guides/test-hermeticity.md:63`): `--no-loopback` prints a warning with the same middle text but its own headline and way back (and the fallback's where bwrap is unavailable), not "the same warning".
- **Claim 38** (`test/scripts/confine-tests.bats:506`): the not-installed case is test 15 (`:395-401`), four tests up, and it pins lines 0 and 5 only.
- **Claim 40** (commit 6276e42c): "1,650 to 4,536 stand-in runs" mixes pairs, per-script runs and both-script runs.
- **Claim 47b** (`test/scripts/confine-tests.bats:124`, `:134`, submitted): the stand-ins accept argv shapes with the command words (and the unshare interpreter) free; m06 (`bash` by name) passes every test but 16.

### Unverifiable
- **Claim 18a** (research doc `:307`): that a real `unshare` exits 126 for a directory on PATH; needs a host that allows `unshare -rn` (sibling util-linux tools do exit 126).
- **Claim 24** (research doc `:354`): the drift check's "FINDINGS: NONE"; needs a model call.
- **Claim 31b** (research doc `:391`): the fifth, uid-mapping skip; needs `unshare -r`.
- **Claim 48b** (`scripts/confine-tests.sh:285`, submitted): that a real `unshare -rn` does not fork; needs a namespace.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/code-fact-check-report-i3-2026-11-10-confine-tests-dash-and-fallback.md, structured per the code-fact-check skill, with a first line `Commit: 6276e42c`, a bolded `**Commit:** 6276e42c` header field and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes
- Out of scope: the whole suite was not re-run (the brief said read suite-1.txt); the drift check was not repeated (model call, no egress); nothing ran under a real bwrap or unshare (no namespace here). The hallucination-pattern log was not appended: no fabrication was found, and this pass may write only this report.
- Escalate: the uid-0 skip count (Claims 3a, 31a, 33) is ten, not four, in three places on this branch (pre-mortem `:21`, `:24`; research doc `:391`, `:398`); the first live run's follow-up should name the seven `not_root` callers.
- Decisions I made: I split submitted claims 4 and 5 where their parts earned different verdicts (47a/47b, 48a/48b); I counted "Twelve wrong sentences" as consistent with the rubric (A11, A12, A13, A14's seven, A17, plus A15's research-doc paraphrase) rather than demanding a list the author did not give.
