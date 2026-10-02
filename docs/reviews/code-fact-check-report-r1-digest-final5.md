Commit: 28c6178 (A) / c079e8c (B)

# Code Fact-Check Report

**Repository:** claude-workflows — worktrees `/workspace/.claude/wt-digest` (feat/dev-cycle-digest) and `/workspace/.claude/wt-devcycle` (feat/dev-cycle)
**Scope:** Final pass 5, partial (the fixes only). A: `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (commits 26b7590, 28c6178). B: `git diff 6ee33e3..c079e8c -- skills/dev-cycle/SKILL.md docs/decisions/log.md docs/roadmap.md guides/skill-creation.md global-instructions/CLAUDE.md docs/dev-cycle-sources.md` (commit c079e8c). Plus the A↔B contract and the three commit messages. Both worktrees carry a byte-identical `scripts/dev-cycle.sh` (`cmp` run). Everything else on both branches is context only.
**Checked:** 2026-10-01
**Total claims checked:** 47
**Summary:** 35 verified, 5 mostly accurate, 0 stale, 6 incorrect, 1 unverifiable

Execution provenance: every executed claim ran in this session on 2026-10-01 between 20:09 and 20:16 -07:00 (timestamps are at the head of each step below). Captured output is in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc5-r1/` (written `$S/` below). Throwaway repos were built under `mktemp -d` inside `$S`. All runs used `timeout`, and no process outlives this report. Nothing was written into either worktree except this file. One probe step (`$S/probes-A-exit.log`) failed its `cd` and ran in `/workspace/.claude/wt-devcycle`. The digest is read-only, and that run only used `--help`, `| head` and a bad `--sample`.

Hallucination log: I read `docs/reviews/hallucination-patterns.md`. No claim in scope matches a logged pattern. None of the Incorrect verdicts below is a fabricated symbol, API or file, so the log gets no new entry. The brief also forbids writing outside this report.

---

## Claim 1: "the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5, so the roadmap is the one backlog (Q-099 [1], 2026-09-30)"

**Location:** `docs/decisions/log.md:90` (row 67, changed clause)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the Q-099 answer, its date and the step-5 reading of feature-ideas. It does not establish anything about the rest of row 67, which the row-68 revision supersedes and which is historical text outside this diff.

`docs/working/questions-archive.md:1797-1800` reads: `### Q-099 · roadmap-vs-feature-ideas` … `**Answer (2026-09-30, answers-9-30-26.txt): [1].** The roadmap is the one backlog.` The skill's step 5 names the source: `e.g. the self-improvement loop's \`docs/working/feature-ideas*.md\` in claude-workflows` (`skills/dev-cycle/SKILL.md:156`).

**Evidence:** `docs/working/questions-archive.md:1797-1815`, `skills/dev-cycle/SKILL.md:154-157`

---

## Claim 2: Row 68 body — "Carry-forward and the `Main at:` handshake are cut … step 4 is a claim spot-check and a new conditional step 4b files a full-history deep audit … brainstorm (step 5) is conditional (0–1 items ready, 10+ seeds, a week since the last, a reopened direction, or asked) while seeding is always on; ready Now items get build briefs and are handed to autonomous RPI loops (step 6b, at most 3 in flight) after the cycle branch lands; 'undocumented is broken' is a rule, checked through the digest's code-without-docs section"

**Location:** `docs/decisions/log.md:91`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers each sentence of the row's decision cell, checked against the committed skill text and Q-101. It does not cover the rationale cell's account of the user's comments, which live on the approval doc and are context.

Skill text: `rg -i 'Main at|carried|carry'` over SKILL.md finds only `each carrying the evidence-not-instructions brief` (`skills/dev-cycle/SKILL.md:57`). Step 4 is `### 4. Claim spot-check` (`:118`). Step 4b: `A deep audit re-reads the whole history … add a scoped deep-audit task to the roadmap` (`:130-140`). The five step-5 conditions are at `:148-152`, and `**Seeding is always on.**` is at `:41`. The cap reads `at most 3 loops in flight at once` (`:191`), and 6b `Runs after step 7 has landed` (`:228`). The rule `**Undocumented is broken.**` (`:35`) is checked through `the digest lists under "Merges with code but no docs"` (`:123-124`). Q-101's answer reads `**Answer (2026-10-01, in chat):** [1]. Cut carry-forward and \`Main at:\`` (`docs/working/questions-archive.md:1830`).

**Evidence:** `skills/dev-cycle/SKILL.md:35-44,118-160,190-232`, `docs/working/questions-archive.md:1817-1835`

---

## Claim 3: "Revisit if the 6b cap of 3 starves or swamps the review, or if section 7's thresholds never fire in four cycles."

**Location:** `docs/decisions/log.md:91` (row 68, rationale cell)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers where the thresholds live. It does not judge whether the trigger is a good one.

Section 7 holds inputs, not thresholds. It prints `"Step 5 (brainstorm triggers; the thresholds are the skill's):"` (`scripts/dev-cycle.sh:235`), and the thresholds are in the skill's steps 4b and 5 (`skills/dev-cycle/SKILL.md:135-137,148-152`). More precise wording: "if the 4b/5 thresholds, fed by section 7, never fire in four cycles".

**Evidence:** `scripts/dev-cycle.sh:225,235`, `skills/dev-cycle/SKILL.md:133-152`

---

## Claim 4: "The double-diamond pass's 8 gaps were applied (landing order, in-flight state, 4b inputs, digest failure path, where filed work goes, readiness, subagent use, parallel steps)."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the count (8) and that each named gap has a matching skill passage. It does not establish that each fix matches the approval doc's wording exactly (see Claim 46).

The list has 8 items. Each one has a matching passage:
- Landing order: `land \`chore/dev-cycle-<date>\` … through \`pr-prep\` before step 6b` (`:223-224`).
- In-flight state: `## In flight` (`:174,181`), plus step 1's skip `an open handoff brief … names` (`:89`).
- 4b inputs: `from the digest's section 7 and the last record` (`:133`).
- Digest failure path: `If the digest fails … write **no** cycle record` (`:74-76`).
- Where filed work goes: `Work goes to the roadmap; only real choices become \`you: judgment\`` (`:30-31`).
- Readiness: `every such entry names the roadmap item it blocks` (`:33`).
- Subagent use: `Step 4 uses one read-only subagent per sampled merge` (`:58`).
- Parallel steps: `Steps 2, 3, 4 and 4b … run them in parallel` (`:56`).

The approval doc says "All eight fixes are applied to the steps above (2026-10-01)". (Paraphrased — no quote available because the doc is a Claude Docs page read through the connector, not a repo file.)

**Evidence:** `skills/dev-cycle/SKILL.md:30-33,56-58,74-76,89,133,174-181,223-224`

---

## Claim 5: `docs/dev-cycle-sources.md` — "step 5 reads every source when it brainstorms, and always-on seeding appends to the seed log"; Feature ideas `docs/working/feature-ideas*.md`; Seed log `docs/working/idea-log.md`, "one `- <idea> (signal: …)` line per idea; step 5 appends `## Brainstorm YYYY-MM-DD` after reading it"

**Location:** `docs/dev-cycle-sources.md:3-9`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers agreement with the skill and the digest for this repo, plus the existence of the feature-ideas file. It does not establish that the digest reads this file. It does not (see Claim 27).

The skill says `generate 3–8 ideas … Then append \`## Brainstorm YYYY-MM-DD\` to the idea log` (`skills/dev-cycle/SKILL.md:157-160`) and `- <idea> (signal: <what prompted it>)` (`:42`). The digest counts `/^- /` lines after the last `## Brainstorm` heading (`scripts/dev-cycle.sh:250`), using `LOG=docs/working/idea-log.md` (`:244`). `docs/working/feature-ideas.md` exists (paraphrased — no quote available because the claim is about directory contents: `ls docs/working`). None of `docs/working/{idea-log,feature-ideas-x,questions}.md` is gitignored (`git check-ignore` exit 1).

**Evidence:** `docs/dev-cycle-sources.md:3-9`, `skills/dev-cycle/SKILL.md:41-44,154-160`, `scripts/dev-cycle.sh:244-250`

---

## Claim 6: Decision-tree row 12 — "The outer loop over rows 6/9: health and cleanup, every revisit trigger, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then hands ready items to autonomous build loops."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the step list and the row numbers. It does not establish how the router fires (the dev-cycle skill has no router file and is itself a skill).

Row 6 is `research-plan-implement.md` and row 9 is `pr-prep.md` (`global-instructions/CLAUDE.md:29`, plus row 6 above it). The listed steps match the skill's flow block, `0 digest → 1 health and cleanup → { 2 triggers | 3 questions | 4 spot-check | 4b audit check } → 5 brainstorm (conditional) → 6 roadmap → 7 close … → 6b handoff` (`skills/dev-cycle/SKILL.md:52-53`).

**Evidence:** `global-instructions/CLAUDE.md:24-32`, `skills/dev-cycle/SKILL.md:51-54`

---

## Claim 7: "with no human checkpoint mid-run beyond the Operating Modes rule (under /active the user confirms the handoff queue, as for any launch; decisions go to questions.md)"

**Location:** `guides/skill-creation.md:137`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers whether the Operating Modes section has a launch-confirmation rule the handoff queue inherits. It does not establish whether launching a build loop should need confirmation.

The Operating Modes /active list has no launch rule. It requires approval only for commits, pushes, PRs, plan review gates and architectural decisions outside the plan. `rg -i launch global-instructions/CLAUDE.md` returns nothing (paraphrased — no quote available because the claim is about an absence, so there are no matching grep results). The queue confirmation is the skill's own rule: `Under /active the user confirms this queue now; under /away it stands.` (`skills/dev-cycle/SKILL.md:192`). The skill also has an Operating Modes checkpoint mid-run that the guide does not name: `Commits and merges follow the Operating Modes rules … (in /active mode, ask first)` (`:27-29`), and step 7 lands through pr-prep. A precise version: "no human checkpoint mid-run beyond the skill's /active handoff-queue confirmation (step 6) and Operating Modes approvals for commits and merges".

**Evidence:** `guides/skill-creation.md:137`, `skills/dev-cycle/SKILL.md:27-29,190-196`, `global-instructions/CLAUDE.md` (Operating Modes section)

---

## Claim 8: "--since   start of the cycle window: commits whose committer date, in the committer's own time zone (git's %cs), is on or after this date."

**Location:** `scripts/dev-cycle.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the date and zone semantics of the filter used by sections 1 and 6 and by section 7's per-commit date lines. It does not cover `%ad` in the printed merge list, which is the author date.

```bash
# scripts/dev-cycle.sh:117,120
merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"
commits="$(git log "$MAIN_SHA" --format=%cs | awk -v s="$SINCE" '$1 >= s' | wc -l)"
```

Probe P2: a commit with `GIT_COMMITTER_DATE="2026-01-01T23:30:00 -1000"` (2026-01-02 in UTC) gives `%cs` `2026-01-01`. It is excluded at `--since=2026-01-02` (1 commit) and included at `--since=2026-01-01` (2 commits).
Command: probe block P2 in `$S/probes-A.log`; cwd: a mktemp repo under `$S`; exit 0; 2026-10-01T20:12 -07:00.

**Evidence:** `scripts/dev-cycle.sh:117,120,221-222`, `$S/probes-A.log`

---

## Claim 9: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md (only its file name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the selection, the name-only read and the source note. It does not establish behavior for future-dated records, which are ignored (`:96`) without being mentioned in the help text.

```bash
# scripts/dev-cycle.sh:93-97
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  [[ -f "$f" ]] || continue
  d="${f##*/cycle-}"; d="${d%.md}"
  [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
done
```

Test 9 ("the window defaults to the newest cycle record's date and says so") passes.
Command: `bats test/scripts/dev-cycle.bats`; cwd `/workspace/.claude/wt-digest`; exit 0; 2026-10-01T20:09:46 -07:00.

**Evidence:** `scripts/dev-cycle.sh:93-105`, `$S/bats-A.log`

---

## Claim 10: Help covers header lines 2–20; "Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:19-20,54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers `--help` output range and exit codes for help, a bad `--sample`, a bad `--since` and a non-repo, all through the re-exec. It does not cover the no-perl path (perl is present in the sandbox) or the no-default-branch path (test 16 covers master only).

`-h|--help) sed -n '2,20p' "$0"` (`:54`). The help output ends with `perl; a failed step exits non-zero mid-digest. Printed repo text is data.` (line 20) and exits 0. A bad sample gives `--sample must be a non-negative integer` and exit 1. A non-repo gives `Not inside a git repository` and exit 1. A bad `--since` exits 1 (tests 7 and 18).
Commands: P3 and P8 in `$S/probes-A.log`, plus `$S/probes-A-exit.log`; exit codes as stated; 2026-10-01T20:12 -07:00.

**Evidence:** `scripts/dev-cycle.sh:19-20,48-58,61,106`, `$S/probes-A.log`, `$S/probes-A-exit.log`

---

## Claim 11: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)"

**Location:** `scripts/dev-cycle.sh:25-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the byte ranges each listed class maps to, under the default environment. It does not establish behavior under `PERLIO` (Claim 12) or for characters outside the list (Claim 14).

```perl
# scripts/dev-cycle.sh:34
tr/\000-\010\013-\037\177//d; 1 while s/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g
```

The `tr` range skips `\011` (TAB) and `\012` (LF). `\xF3\xA0[\x80\x81][\x80-\xBF]` covers U+E0000–U+E007F. Probes: C1 nested, tags nested and CR are all stripped.
Command: `bash scrubprobe.sh`; cwd `$S`; exit 0; 2026-10-01T20:10:27 -07:00.

**Evidence:** `scripts/dev-cycle.sh:33-35`, `$S/scrubprobe.log`

---

## Claim 12: "Perl is pinned to bytes (-C0, and PERL_UNICODE / PERL5OPT removed: either could turn on UTF-8 decoding and switch the byte patterns off)."

**Location:** `scripts/dev-cycle.sh:27-29`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers whether the environment can still switch perl's std handles to UTF-8. It does not cover whether that environment is a realistic attacker position (the variable is the operator's own).

`PERLIO` is a third environment variable that does this, and the scrub leaves it in place:

```bash
# scripts/dev-cycle.sh:34
env -u PERL_UNICODE -u PERL5OPT LC_ALL=C perl -C0 -pe '…'
```

With `PERLIO=:utf8`, the scrub function alone passes `c2 9b` (CSI) and `e2 80 ae` (RLO) through unchanged (`$S/perlio.log`: ` 61 c2 9b 62 e2 80 ae 63 0a`). The whole digest does the same: a revisit trigger `if a\xc2\x9bb\xe2\x80\xaec.` prints as `a 302 233 b 342 200 256 c` (`$S/perlio-e2e.log`). The default environment prints `abc`. `-C0` does not override `PERLIO`'s default layers.
Commands: the `env $e bash -c '…scrub'` loop (cwd `$S`, 2026-10-01T20:10:27) and `env PERLIO=:utf8 bash …/dev-cycle.sh` (cwd: mktemp repo, 2026-10-01T20:10:41 -07:00); exit 0. The claim needs `-u PERLIO` added, or the reworded caveat "PERLIO not pinned".

**Evidence:** `scripts/dev-cycle.sh:27-34`, `$S/perlio.log`, `$S/perlio-e2e.log`

---

## Claim 13: "C0 goes first and the substitution repeats until nothing changes, so neither a control byte inside a sequence nor a nested sequence can reassemble one."

**Location:** `scripts/dev-cycle.sh:29-31`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers reassembly within one line for the listed C1, bidi and tag sequences, including a C0 byte between nested layers. It does not cover sequences split across lines (perl `-p` works per line; the result is `c2 0a 9b`, which is two invalid fragments around an LF and not a reassembled sequence) or the PERLIO case (Claim 12).

Probes all give `61 62`: `a\xc2\x01\x9bb` (split), `a\xc2\xc2\x9b\x9bb` (nested), `a\xc2\xc2\x01\x9b\x9bb` (C0 between layers), `a\xe2\x80\xe2\x01\x80\xae\xaeb` (C0 inside an inner bidi layer), and nested tags. The loop terminates because each successful `s///g` shortens the line (paraphrased — no quote available because this is an inference from the `1 while s///g` form at `:34`). Test 5 covers split, nested and env cases and fails on db0e5ca (Claim 39).

**Evidence:** `scripts/dev-cycle.sh:34`, `$S/scrubprobe.log`, `$S/bats-on-db0e5ca.log`

---

## Claim 14: "Not covered: a lone 0x9B byte (invalid UTF-8, inert on a UTF-8 terminal) and zero-width characters (cannot start a line)."

**Location:** `scripts/dev-cycle.sh:31-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers whether the "Not covered" list is complete for byte forms that pass the scrub. It does not establish what any terminal does with them (Claim 15).

Both named items pass, so they are correctly listed (lone `9b` passes: `61 9b 62`). The list leaves out several forms that also pass:
- Overlong encodings of C1 or C0, such as `c0 9b` and `e0 82 9b`. These are invalid UTF-8 in the same class as a lone 0x9B.
- U+061C ARABIC LETTER MARK, `d8 9c`. Unicode lists it as a Bidi_Control alongside the comment's U+200E/F, U+202A-202E and U+2066-2069.
- U+2028 LINE SEPARATOR, `e2 80 a8`.

All of these pass unchanged in `$S/scrubprobe.log`. A precise version would add "overlong forms (invalid UTF-8, like 0x9B), U+061C and U+2028/9".

**Evidence:** `scripts/dev-cycle.sh:31-34`, `$S/scrubprobe.log`

---

## Claim 15: "a lone 0x9B byte (invalid UTF-8, inert on a UTF-8 terminal)"

**Location:** `scripts/dev-cycle.sh:31-32`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers only the terminal-behavior half. "Invalid UTF-8" is true by definition, since 0x9B is a continuation byte.

Whether 0x9B is inert depends on the terminal emulator's decoder mode (for example, a terminal not in UTF-8 mode treats 0x9B as 8-bit CSI). Nothing in the sandbox renders to a terminal. Verifying it needs runs on the target terminals (xterm, VS Code, Windows Terminal) in UTF-8 mode.

**Evidence:** `scripts/dev-cycle.sh:31-32`

---

## Claim 16: "Run the body as a child whose stdout and stderr each pass through scrub as members of one pipeline, so the shell waits for both filters before exiting: a redirected digest is complete when the script returns."

**Location:** `scripts/dev-cycle.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the wait structure and completeness of a redirected digest. It does not establish that test 7 discriminates: the commit's Notes say test 7 also passes on db0e5ca, and I confirmed it does.

```bash
# scripts/dev-cycle.sh:41-44
if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then
  { DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
fi
```

Both scrubs are foreground pipeline members: the inner one inside the group, the outer one directly. Bash waits for every member. P6 ran 30 redirected runs, and all 30 ended with the idea-log line (`incomplete=0/30`). Test 7 passes. Running from a subdirectory with a relative path works (P7 exit 0, plus test 13).
Commands: P6 and P7 in `$S/probes-A.log`; 2026-10-01T20:12 -07:00.

**Evidence:** `scripts/dev-cycle.sh:36-44`, `$S/probes-A.log`, `$S/bats-A.log`, `$S/bats-on-db0e5ca.log`

---

## Claim 17: "stdout goes to fd 3, stderr takes the inner pipe, then fd 3 takes the outer one. Exit status: the body's (pipefail; scrub itself does not fail)."

**Location:** `scripts/dev-cycle.sh:38-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers fd routing (stdout to stdout, stderr to stderr, both scrubbed) and exit status for the 0 and 1 paths. It does not cover exits under SIGPIPE: `dev-cycle.sh | head -1` exits 141 in all 6 runs, and it cannot be told apart whether that status is the body's or the outer scrub's.

`2>&1 1>&3 3>&-` points stderr at the inner pipe, stdout at fd 3 (the outer pipe, from the group's `3>&1`), and closes fd 3 in the body (`:42`). Test 5 checks that `Unknown option: --bogus` reaches `$stderr` scrubbed under `--separate-stderr`. Exit codes 0 and 1 propagate (Claim 10). Under `set -e` a failing outer pipeline exits with the pipefail status (the group's, which is the body's) before `exit "${PIPESTATUS[0]}"`, with the same value (paraphrased — no quote available because this is an inference from bash errexit semantics on `:22` together with `:42-43`).

**Evidence:** `scripts/dev-cycle.sh:22,41-44`, `$S/bats-A.log`, `$S/probes-A-exit.log`

---

## Claim 18: "DEV_CYCLE_SCRUBBED marks the child." (and the 26b7590 Note: "an environment that sets it skips the scrub; a repo cannot")

**Location:** `scripts/dev-cycle.sh:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the skip and the claim that repo content cannot set the variable. It does not establish that the variable stays unset in the grandchild environments (it is exported to questions.sh, which ignores it).

P4: `DEV_CYCLE_SCRUBBED=1` prints `c2 9b` unscrubbed. The script reads no repo-controlled source of environment variables (paraphrased — no quote available because the claim covers an absence: the script exports nothing from repo files, and git config cannot set process environment).

**Evidence:** `scripts/dev-cycle.sh:41-42`, `$S/probes-A.log`

---

## Claim 19: "A regular file whose real path stays inside the repo: a committed symlink (to the file or a parent directory) must not make the digest print text from outside the checkout."

**Location:** `scripts/dev-cycle.sh:64-67`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers every in-script read site and both symlink shapes. It does not cover `QUESTIONS_LIVE`, an operator environment override that makes questions.sh read another file, or TOCTOU between the check and the read.

```bash
# scripts/dev-cycle.sh:67
inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }
```

Read sites:
- Decision records (`:130`), log.md (`:139`), questions.md before questions.sh runs (`:156`), the roadmap (`:189`, `:236`) and the idea log (`:245`) all go through `inrepo`.
- The cycle-record glob reads only the name (`:93-96`), and `git log -- f` reads git objects.
- `questions.sh open` reads only `$LIVE` (`parse_entries "$LIVE"`, `scripts/questions.sh:410`).

Test 6 (file symlinks) passes. P1 symlinks `docs/decisions` and `docs/working` as directories to outside the repo: `SECRET` count 0, and the output shows "No revisit triggers recorded." and "No docs/working/idea-log.md".

**Evidence:** `scripts/dev-cycle.sh:63-67,93-96,129-156,189,236,245`, `scripts/questions.sh:85,408-414`, `$S/probes-A.log`, `$S/bats-A.log`

---

## Claim 20: "Window: … Merges, commits and section 7's changed files: those on `$MAIN` at … whose committer date (in the committer's time zone) is on or after $SINCE, filtered after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers sections 1, 4 and 6 (which share `merges_full`) and section 7's per-commit date filter. It does not establish the commit-population difference: section 1 counts all reachable commits, while section 7 lists files from first-parent commits only. The line says "on `$MAIN`" for both.

Section 6 iterates `done <<< "$merges_full"` (`:208`). Section 7 filters on `/^@/ { on = (substr($0, 2) >= s)` (`:222`). Neither walk uses `--since`. Zone semantics are confirmed by P2 (Claim 8).

**Evidence:** `scripts/dev-cycle.sh:110,117-120,202-208,221-222`, `$S/probes-A.log`

---

## Claim 21: "`--since` stops at the first old-dated commit, so one such commit hid every merge behind it." (and test 4's comment: "it counted only the newest merge and hid the three older ones behind the old commit")

**Location:** `scripts/dev-cycle.sh:114-115`; `test/scripts/dev-cycle.bats:81-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's non-limited `--since` walk on test 4's exact history. It does not cover other git versions.

I rebuilt test 4's history and ran the old form `git log main --first-parent --merges --since=<yesterday>`. It printed only `merge: feature 4`. The full walk plus filter printed all four merges.
Command in `$S/test4-oldbehaviour.log`; cwd: mktemp repo; exit 0; 2026-10-01T20:13:16 -07:00.

**Evidence:** `scripts/dev-cycle.sh:114-117`, `test/scripts/dev-cycle.bats:80-92`, `$S/test4-oldbehaviour.log`

---

## Claim 22: "A merge whose diff against its first parent touches files but no doc (a path under docs/, a *.md file, or a file named README or README.*, any case): step 4 checks each one … Listed up to 30."

**Location:** `scripts/dev-cycle.sh:199-201`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the README rule (any case), the cap and the `rest` reuse. The "any case" applies to README only: `docs/` and `*.md` are case-sensitive, so `NOTES.MD` and `Docs/x.sh` count as code, and so does `readme.d/x.sh` (basename only).

```awk
# scripts/dev-cycle.sh:205 (awk program)
b = tolower($0); sub(/.*\//, "", b); if ($0 ~ /^docs\// || $0 ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++; else c++
```

- P9 had 33 code-only merges. It printed 30 lines plus `… 3 more`, in the form `- 3bacd25 2026-10-01 merge: b33 (1 file(s), no doc change)`. That is the old `%h %ad %s` format, reused through `rest`.
- P10 flagged `upmd`, `docsUP` and `readmedir`. It did not flag `README` or `sub/Readme.rst`.
- Test 19 passes, and it fails on db0e5ca.

Commands: `$S/probes-A2.log` (2026-10-01T20:13:03 -07:00) and `$S/bats-A.log`.

**Evidence:** `scripts/dev-cycle.sh:198-214`, `$S/probes-A2.log`, `$S/bats-A.log`

---

## Claim 23: "Every file any first-parent commit in the window touched (a merge counts its diff against its first parent), not a net diff: a change reverted inside the window still counts."

**Location:** `scripts/dev-cycle.sh:217-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers files under the `skills workflows docs/decisions` pathspec and the merge-diff semantics under `--first-parent`. It does not cover files outside those paths, which the comment does not claim, or quoted names (Claim 24).

`git log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions` (`:221`). Test 20 adds and then removes `skills/demo/tmp.md`, and merges `workflows/flow.md` through a `--no-ff` merge before dropping it. It expects `in the window: 2` and `- workflows/flow.md`, passes at HEAD and fails on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:216-224`, `test/scripts/dev-cycle.bats:289-297`, `$S/bats-A.log`, `$S/bats-on-db0e5ca.log`

---

## Claim 24: "'@' lines carry each commit's date; git quotes a name holding a control character, so each name is one line."

**Location:** `scripts/dev-cycle.sh:219-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers one name per line and the `@` parsing: a path line starts with `skills`, `workflows`, `docs/decisions` or `"`, never `@`. It does not establish that such names are counted. A quoted name (a control character, or non-ASCII under the default `core.quotePath=true`) starts with `"` and fails both filters (`grep -E '^(skills/…'`, `:223-224`), so it silently drops out of section 7's counts.

P11 printed `"skills/a\tb/SKILL.md"` and `"skills/caf\303\251/SKILL.md"` as single lines, and section 7 then reported `Skill or workflow files changed … : 0`.

**Evidence:** `scripts/dev-cycle.sh:219-224`, `$S/probes-A2.log`

---

## Claim 25: Contract comments — "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill." and "The skill's step 5 appends '## Brainstorm YYYY-MM-DD' after reading the log (its ideas go to the roadmap); seeding appends '- ' lines after that heading."

**Location:** `scripts/dev-cycle.sh:195,246-247`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers agreement with the committed skill text. It does not cover a configured non-default seed log (Claim 27).

The skill has the roadmap template (`skills/dev-cycle/SKILL.md:164-178`) and says `Then append \`## Brainstorm YYYY-MM-DD\` to the idea log … the surviving ideas go to the roadmap's Ideas` (`:159-160`). Seeding writes `- <idea> (signal: …)` (`:42`).

**Evidence:** `scripts/dev-cycle.sh:195,244-256`, `skills/dev-cycle/SKILL.md:41-44,159-178`

---

## Claim 26: "Then append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts seeds from here" — in this repo

**Location:** `skills/dev-cycle/SKILL.md:159-160`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers this repo, where `docs/dev-cycle-sources.md` names `docs/working/idea-log.md` as the seed log. It does not cover other repos (Claim 27).

The digest counts from the last heading: `seeded="$(awk '/^## Brainstorm [0-9]…/ { c = 0; next } /^- / { c++ } …' "$LOG")"` (`scripts/dev-cycle.sh:250`). Test 20 checks `Ideas seeded since: 2` and `Last brainstorm: 2026-01-01 (7 day(s) ago)`.

**Evidence:** `scripts/dev-cycle.sh:244-256`, `docs/dev-cycle-sources.md:9`, `$S/bats-A.log`

---

## Claim 27: "The idea log is the file `docs/dev-cycle-sources.md` names as its seed log when that file exists, else `docs/working/idea-log.md`." combined with "… so the next digest counts seeds from here"

**Location:** `skills/dev-cycle/SKILL.md:41-44,159-160`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** This covers any repo whose sources file names a seed log other than the default. The skill is installed for every project (`~/.claude/scripts/dev-cycle.sh`, `SKILL.md:64`). It does not affect this repo today.

The digest hard-codes the path and never reads `docs/dev-cycle-sources.md`:

```bash
# scripts/dev-cycle.sh:244-245
LOG=docs/working/idea-log.md
if inrepo "$LOG"; then
```

Where a sources file names another seed log, seeding and the `## Brainstorm` heading go there. The next digest then prints `- No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded` (`:258`), and the step-5 "10+ seeds" and "a week since" triggers are fed wrong values. Either the digest reads the sources file's seed-log row, or the skill limits the configurable seed log to the default path.

**Evidence:** `scripts/dev-cycle.sh:244-258`, `skills/dev-cycle/SKILL.md:41-44,146-160`

---

## Claim 28: "Its sections feed the steps: 1 activity (context), 2 triggers (step 2), 3 watched questions (step 3), 4 spot-check sample and 6 merges with code but no docs (step 4), 5 roadmap (step 6), 7 inputs (steps 4b and 5)."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers section numbers and titles. It does not establish what each step does with them.

The digest headings are `## 1. Activity` (`:113`), `## 2. Revisit triggers` (`:125`), `## 3. Watched questions (trigger and deferred routes)` (`:153`), `## 4. Spot-check sample` (`:178`), `## 5. Roadmap` (`:188`), `## 6. Merges with code but no docs` (`:198`) and `## 7. Inputs for steps 4b and 5` (`:216`).

**Evidence:** `scripts/dev-cycle.sh:113-216`

---

## Claim 29: "It is read-only." / "If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first." / "(or says no cycle record was found when one ran)" / "If the digest fails (non-zero exit or a missing section) …"

**Location:** `skills/dev-cycle/SKILL.md:66-76`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the subcommand's existence, the digest's source-note wording and its non-zero exit on failure. It does not cover whether a mid-digest failure always leaves a section missing.

- `init)    cmd_init ;;` (`scripts/questions.sh:446`).
- The source note reads `no cycle record found, so the default of 14 days …` (`scripts/dev-cycle.sh:104`).
- The header says `Read-only: writes nothing to the repo (one temp file, removed on exit)` (`:18`).
- Failures exit 1 through the re-exec (Claim 10).
- `~/.claude/scripts/dev-cycle.sh` will exist after install, because `CLAUDE_HOME_SRC=(… scripts)` stages the whole `scripts/` directory (`devcontainer-config/install.sh:135`).

**Evidence:** `scripts/questions.sh:445-452`, `scripts/dev-cycle.sh:18,104`, `devcontainer-config/install.sh:135`, `$S/probes-A.log`

---

## Claim 30: Step 1 references — "`scripts/health-check.sh` in claude-workflows"; "triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)"; "`questions.sh archive` then `index`"; "Do not run `archive-working-docs.sh`: it serves the self-improvement loop and moves files into a gitignored archive."

**Location:** `skills/dev-cycle/SKILL.md:80-93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the existence and described behavior of each named artifact. It does not establish whether health-check is green today.

- `scripts/health-check.sh` exists. pr-prep step 5 has `All CI failures triaged into one of the three classes (caused-by-branch / pre-existing / flaky)` (`workflows/pr-prep.md:350`).
- `index)` and `archive)` exist (`scripts/questions.sh:448-449`).
- archive-working-docs.sh: `# Archive docs/working/ artifacts from a completed self-improvement run.` (`:2`) and `Moves all non-permanent files from docs/working/ into docs/working/archive/` (`:6`). `.gitignore:16` has `docs/working/archive/`.

**Evidence:** `workflows/pr-prep.md:311-353`, `scripts/questions.sh:445-452`, `scripts/archive-working-docs.sh:2-6`, `.gitignore:16`

---

## Claim 31: Digest inputs for steps 4, 4b and 5 — "every merge the digest lists under 'Merges with code but no docs' (the fourth rule)"; 4b "from the digest's section 7 and the last record … differs from the last record's `Model:` line"; step 5 "(inputs: the digest's section 7)"

**Location:** `skills/dev-cycle/SKILL.md:123-124,133-137,146-152`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers each named input's presence in the digest or the record template. Readiness for 6b, "substantially changed" and "major design decision" are judgment calls, and the digest supplies only raw counts and lists for them.

- Section 6 title: `## 6. Merges with code but no docs` (`scripts/dev-cycle.sh:198`). The fourth rule is `**Undocumented is broken.**` (`SKILL.md:35`).
- Section 7 prints `Skill or workflow files changed…`, `Decision records added or changed … (is any a major design decision?)` and `The model version is not in git: compare it with the last cycle record's.` (`scripts/dev-cycle.sh:225-228`). The record template has `Model: <the model id running this cycle>` (`SKILL.md:205`).
- Step 5's inputs (Roadmap Now/In flight/Next counts, last brainstorm with days ago, ideas seeded since) are at `scripts/dev-cycle.sh:237-256`.

**Evidence:** `scripts/dev-cycle.sh:198,225-256`, `skills/dev-cycle/SKILL.md:35,123-152,205`

---

## Claim 32: Roadmap template headings (`## Now`, `## In flight`, `## Next`, `## Ideas`, `## Done`) and briefs at `docs/working/handoffs/<date>-<slug>.md` — "Both land with step 7, so the briefs are on the default branch before any loop starts."

**Location:** `skills/dev-cycle/SKILL.md:164-196`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers exact-match heading counting in the digest, this repo's roadmap headings, and the handoffs and cycles paths not being gitignored. It does not establish that pr-prep's landing succeeds.

- The digest counts `awk -v h="## $sec" '$0 == h …'` for `Now "In flight" Next` (`scripts/dev-cycle.sh:237-238`), so the headings must match exactly. They do in the template (`SKILL.md:173-175`) and in this repo's roadmap (`docs/roadmap.md:13,18,20`, from `rg '^## '`).
- Test 20 checks all three counts.
- `git check-ignore -v docs/working/cycles/cycle-2026-10-01.md docs/working/handoffs/x.md` exits 1 (neither path is ignored).

**Evidence:** `scripts/dev-cycle.sh:236-243`, `docs/roadmap.md:13-20`, `.gitignore:16-36`, `$S/bats-A.log`

---

## Claim 33: "Record one verdict for every trigger, under the name the digest prints. The next digest starts its window from this file's date (only the file name is read)"; template examples `docs/decisions/014-secure-tool-guidance-layers.md` and `log row 62`

**Location:** `skills/dev-cycle/SKILL.md:200-222`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers record naming, name-only reading and that the example triggers exist. It does not cover future-dated records, which the digest ignores.

- The digest prints `### ${f//$'\n'/ } (last committed…)` and `- log row $n ($d): > $text` (`scripts/dev-cycle.sh:136,148`). The example names follow those forms.
- `docs/decisions/014-secure-tool-guidance-layers.md:106` is `## Revisit triggers`, and log row 62 holds `Revisit if stacking overhead dominates small features…`.
- Name-only reading is shown at Claim 9 and by test 9.

**Evidence:** `scripts/dev-cycle.sh:93-101,129-149`, `docs/decisions/014-secure-tool-guidance-layers.md:106`, `docs/decisions/log.md:85`

---

## Claim 34: "land `chore/dev-cycle-<date>` on the default branch through `pr-prep` before step 6b: the next digest and the build loops both start from the default branch."

**Location:** `skills/dev-cycle/SKILL.md:222-224`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers what the digest reads from the default branch versus the working tree. It does not evaluate the landing procedure.

The digest walks the default branch for sections 1, 4, 6 and 7 (`git log "$MAIN_SHA"`, `scripts/dev-cycle.sh:117,221`). The window start (the cycle-record glob, `:93`), the triggers, questions, roadmap and idea log all come from the working tree the digest runs in. The Window line says so: `Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree.` (`:110`). The landing order is right in practice, because the next cycle's branch is created from the default branch (`SKILL.md:26`). More precisely: "the next cycle's branch, whose working tree the digest reads, and the build loops both start from the default branch".

**Evidence:** `scripts/dev-cycle.sh:93,110,117,221`, `skills/dev-cycle/SKILL.md:25-27,222-224`

---

## Claim 35: Handoff queue and 6b — "at most 3 loops in flight at once, counting earlier cycles'. Under /active the user confirms this queue now; under /away it stands."; 6b starts "(`research-plan-implement`)"; "A choice among 3+ approaches is flagged for `divergent-design`"

**Location:** `skills/dev-cycle/SKILL.md:158,190-196,228-232`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers agreement with row 68, the approval doc and the named workflows' existence. It does not establish that the cap is enforced mechanically. It is counted by hand from the roadmap's In flight section, which the digest counts.

`workflows/research-plan-implement.md` and `workflows/divergent-design.md` exist (paraphrased — no quote available because the claim is about file existence). Row 68 says `step 6b, at most 3 in flight`. The approval doc's 6b row says "At most 3 loops are in flight at once, counting earlier cycles'" and "Under /active you confirm the queue before launch; under /away it launches" (paraphrased — no quote available because the doc is a Claude Docs page read via the connector, not a repo file).

**Evidence:** `skills/dev-cycle/SKILL.md:158,190-196,226-235`, `docs/decisions/log.md:91`

---

## Claim 36: Test 4 name — "an old-dated commit on main does not hide the merges behind it"

**Location:** `test/scripts/dev-cycle.bats:80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the name matching what the test asserts. Its comment is covered by Claim 21.

The test expects 4 merges after a 2020-dated fast-forward (paraphrased — no quote available because the assertion line sits below the excerpted diff hunk at `:84-92`, which I read in full). It passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:80-92`, `$S/bats-A.log`

---

## Claim 37: Test 10 — "--since includes commits from the start date itself"; "All commits here are from today: a window starting today counts all of them."

**Location:** `test/scripts/dev-cycle.bats:147-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the name and comment against the assertion `"; $total commit(s)"`. It does not test zone boundaries (Claim 8 covers those).

`run --separate-stderr bash "$DC" --since="$(date +%F)"` followed by `[[ "$output" == *"; $total commit(s)"* ]]` (`:151-152`). The test passes.

**Evidence:** `test/scripts/dev-cycle.bats:147-153`, `$S/bats-A.log`

---

## Claim 38: Test 19 comment "README_gen.sh is code; a README.txt or docs/ alone is a doc." and test 20 comment "Changed and reverted inside the window: still a change."

**Location:** `test/scripts/dev-cycle.bats:272,292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the comments against the specs and assertions that follow them. Uppercase `.MD` and `Docs/` are not exercised (Claim 22).

The specs `readme-like:src/README_gen.sh:flag`, `readme-txt:x.sh lib/README.txt:ok` and `docs-only:docs/a.txt y.sh:ok` (`:273`) are checked per spec at `:280-284` and pass. Test 20's tmp add and remove plus the `wf` merge and drop (`:292-294`) are asserted at `:297`.

**Evidence:** `test/scripts/dev-cycle.bats:270-300`, `$S/bats-A.log`

---

## Claim 39: Commit 26b7590 — "20/20 tests; the new scrub, symlink, section 6 and section 7 tests fail on db0e5ca."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the suite at 26b7590 and at 28c6178 run against the db0e5ca script. It does not establish that each test fails for the intended reason, beyond seeing that it fails.

- 26b7590's script and bats: 20 `ok`, exit 0 (`$S/bats-26b7590.log`; 2026-10-01T20:12:09 -07:00).
- 28c6178's bats against db0e5ca's script: `not ok 5` (scrub), `not ok 6` (symlink), `not ok 19` (section 6), `not ok 20` (section 7), and everything else ok, including test 7 (`$S/bats-on-db0e5ca.log`; 2026-10-01T20:09:57; exit 1).

**Evidence:** `$S/bats-26b7590.log`, `$S/bats-on-db0e5ca.log`

---

## Claim 40: Commit 26b7590 — "shellcheck clean."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the health-check lint gate over the files the commit changed. Under the narrow reading the claim holds: the script alone is clean.

At 26b7590, `shellcheck -s bash dev-cycle.bats` reports `SC2034 (warning): want appears unused` at line 274, exit 1 (`$S/shellcheck-26b7590-bats.log`; 2026-10-01T20:11:58). The gate lints `.bats` files at warning level: `# Also include .bats files — they're bash` and `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:459,480`). The next commit, 28c6178, records this failure and fixes it. At HEAD, both files pass the gate's exact flags (`$S/shellcheck-head.log`, exit 0).

**Evidence:** `scripts/health-check.sh:427-486`, `$S/shellcheck-26b7590-bats.log`, `$S/shellcheck-head.log`

---

## Claim 41: Commit 26b7590 — "R1/A1 (X1): scrub pins perl to bytes (-C0, PERL_UNICODE/PERL5OPT removed)"

**Location:** commit `26b7590` message
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This is the same fact as Claim 12, in the commit's words. It does not cover the commit's other R1 items (C0 first, repeat until stable, the new test 5 cases), which are verified at Claims 13 and 39.

`PERLIO=:utf8` unpins it, and C1 and RLO pass through the full digest (`$S/perlio-e2e.log`). Details at Claim 12.

**Evidence:** `scripts/dev-cycle.sh:34`, `$S/perlio.log`, `$S/perlio-e2e.log`

---

## Claim 42: Commit 26b7590 — "A5: … so the shell waits for both filters; perl autoflushes, so stream order follows the body. Exit status is the body's."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** I split this claim by atom and give the most severe verdict. "Waits for both filters" and "exit status is the body's" are verified at Claims 16 and 17. "Stream order follows the body" is refuted. This does not measure how often the digest itself interleaves its two streams, since its stderr is mostly fatal errors written last.

I reproduced the exact pipeline shape and autoflushing scrub with a body that alternates `echo "out $i"` and `echo "err $i" >&2` 200 times. With both streams merged (`2>&1`) to one file, all 10 of 10 runs came out misordered: stdout lines arrive in runs ahead of the stderr lines (`$S/order.log`: `2d1 < err 1`, `4d2 < err 2`, …). Two independent filter processes give no cross-stream ordering, and autoflush does not change that.
Command: `LC_ALL=C bash order.sh 2>&1`; cwd `$S`; exit 0; 2026-10-01T20:12:49 -07:00.

**Evidence:** `scripts/dev-cycle.sh:42`, `$S/order.sh`, `$S/order.log`

---

## Claim 43: Commit 26b7590 — "A4: inrepo() reads only regular files whose real path is inside the checkout (symlinked records, log, roadmap, questions, idea log skipped)."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the parenthetical. The main clause is verified at Claim 19.

A symlink whose real path stays inside the checkout passes `[[ "$r" == "$ROOT_REAL"/* ]]` (`scripts/dev-cycle.sh:67`) and is read. Only symlinks that leave the checkout are skipped. More precisely: "(records, log, roadmap, questions, idea log symlinked out of the checkout are skipped)".

**Evidence:** `scripts/dev-cycle.sh:63-67`

---

## Claim 44: Commit 26b7590 — A6 (`--help`/Window committer date, test renamed), A7 ("doc = docs/, *.md, or a file named README / README.* (any case)"), A8 ("section 7 lists every file a first-parent commit in the window touched (path-limited walk), not a net diff; no base commit any more"), A9/C8 (test 4 comment and name), C1 (part) ("section 6 reuses merges_full and caps its list at 30"), Notes ("A lone 0x9B byte and zero-width characters stay unscrubbed, as the comment says. The redirect test passes on db0e5ca too")

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Each item is covered with the residues named at Claims 8, 20–24 and 36–38. A7's "any case" holds for README only, which is the natural reading. This does not cover the incompleteness of the "Not covered" list, which is at Claim 14.

`base=`/`oldest=` are gone from the script (paraphrased — no quote available because the claim covers an absence: `rg -n 'oldest|base=' scripts/dev-cycle.sh` matches nothing in the section 7 code, `:216-233`). Test 7 passes on db0e5ca (`$S/bats-on-db0e5ca.log`: `ok 7`). The lone `9b` passes the scrub (`$S/scrubprobe.log`).

**Evidence:** `scripts/dev-cycle.sh:10-11,110,198-233`, `test/scripts/dev-cycle.bats:80-83,147-150`, `$S/bats-on-db0e5ca.log`, `$S/scrubprobe.log`, `$S/probes-A2.log`

---

## Claim 45: Commit 28c6178 — "shellcheck SC2034 (unused 'want') failed the health-check lint gate."

**Location:** commit `28c6178` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the warning at 26b7590 and the gate's inclusion of `.bats` at warning level, and that the fix uses `want`. I did not run the whole health-check script.

See Claim 40's logs. At HEAD, `IFS=: read -r br want <<< "$spec"` followed by `if [[ "$want" == flag ]]` (`test/scripts/dev-cycle.bats:281-282`) uses the variable, and shellcheck exits 0.

**Evidence:** `test/scripts/dev-cycle.bats:272-285`, `$S/shellcheck-26b7590-bats.log`, `$S/shellcheck-head.log`

---

## Claim 46: Commit c079e8c — "The skill now matches 'Dev cycle skill — for your approval' (2026-10-01) and the digest after the carry-forward cut (Q-101 [1])"

**Location:** commit `c079e8c` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers a step-by-step comparison of the skill with the approval doc (read through the Claude Docs connector, rev 48). It does not cover the doc's free-text comment threads.

Steps 0–7, 4b and 6b, the four rules, the thresholds and the 8 gaps all match. The commit's Notes disclose one deviation: briefs are written in step 6. Two deviations go undisclosed:
- The doc says that without a sources file "step 5 looks for a backlog and records which file it used". The skill has no record-the-file instruction: `else its own idea backlog wherever it keeps one` (`skills/dev-cycle/SKILL.md:155-156`).
- The doc moves an item to In flight when its loop starts after step 7. The skill moves it in step 6, before landing: `move the item to In flight, linking the brief` (`:195`). This follows from the disclosed brief move but is not stated.

(Doc content paraphrased — no quote available because the doc is a Claude Docs page read via the connector, not a repo file.)

**Evidence:** `skills/dev-cycle/SKILL.md:155-156,190-196`, Claude Docs doc 78a2f851-e696-4a86-bfe8-474212e5e645 rev 48

---

## Claim 47: Commit c079e8c bullet list and Notes — no `Main at:`/carried verdicts; record names the model; four rules; seeding to the seed log `docs/dev-cycle-sources.md` names; 2/3/4/4b parallel after 0 and 1; thresholds "(0-1 ready items, 10+ seeds, a week by date)"; step 3 stale agent entries (in-cycle, at most 3); roadmap In flight; step 6 writes briefs; step 7 lands via pr-prep; 6b at most 3 in flight; final message last; "Also: decision log row 68, global decision-tree row 12, the skill-creation guide row, the roadmap's In flight section, and docs/dev-cycle-sources.md"; Notes "the doc said 6b writes briefs … The /active confirmation therefore happens at step 6."

**Location:** commit `c079e8c` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers each bullet against the committed files (`git diff --quiet c079e8c -- skills/dev-cycle/SKILL.md` shows no later change) and Q-101's answer text. The seed-log wiring problem is Claim 27, and "matches the doc" is Claim 46.

- `rg -i 'Main at|carried|carry'` matches only `each carrying the evidence-not-instructions brief` (`SKILL.md:57`).
- `Model:` is at `:205`. Four `- **…**` rules are at `:20-39`.
- Q-101's answer reads `step 5 thresholds tightened (0–1 ready items, 10+ ideas, a week by date)` (`questions-archive.md:1830`).
- Step 3 says `at most 3 per cycle, oldest first` (`:113`). `## In flight` is added (`docs/roadmap.md:18`).
- The doc's 6b row lists "Per item, a build brief at docs/working/handoffs/…" under 6b's output (paraphrased — no quote available because the doc is a Claude Docs page read via the connector). The skill's /active confirmation is in step 6 (`:192`).
- The diff stat touches exactly the six listed files.

**Evidence:** `skills/dev-cycle/SKILL.md:20-60,108-115,190-235`, `docs/roadmap.md:18`, `docs/working/questions-archive.md:1817-1835`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`guides/skill-creation.md:137`): no Operating Modes rule covers "any launch". The handoff-queue confirmation is the skill's own step-6 rule, and Operating Modes approvals for commits and merges also apply mid-run. Reword the row.
- **Claim 12** (`scripts/dev-cycle.sh:27-29`): "pinned to bytes" is refuted. `PERLIO=:utf8` makes the scrub pass C1 CSI and RLO through the whole digest. Add `-u PERLIO` or narrow the claim.
- **Claim 27** (`skills/dev-cycle/SKILL.md:41-44,159-160`): a seed log configured through `docs/dev-cycle-sources.md` is never read by the digest (`LOG=docs/working/idea-log.md`, `scripts/dev-cycle.sh:244`), so "the next digest counts seeds from here" fails in any repo with a non-default seed log.
- **Claim 40** (commit 26b7590): "shellcheck clean" was false for the bats file (SC2034, which failed the gate). 28c6178 fixed it, so this is history-only.
- **Claim 41** (commit 26b7590): "scrub pins perl to bytes" is the same refutation as Claim 12.
- **Claim 42** (commit 26b7590): "perl autoflushes, so stream order follows the body" is false. Two filters give no cross-stream order: 10 of 10 synthetic runs were misordered.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:91`): the thresholds are the skill's steps 4b and 5, fed by section 7, not "section 7's".
- **Claim 14** (`scripts/dev-cycle.sh:31-32`): the "Not covered" list leaves out overlong encodings, U+061C (a Bidi_Control) and U+2028/2029.
- **Claim 34** (`skills/dev-cycle/SKILL.md:222-224`): the digest walks the default branch but reads the cycle record, triggers, questions, roadmap and idea log from its working tree.
- **Claim 43** (commit 26b7590, A4): in-repo symlinks are followed; only links out of the checkout are skipped.
- **Claim 46** (commit c079e8c): two undisclosed deviations from the approval doc: the fallback "records which file it used" is absent, and the In flight move happens at step 6.

### Unverifiable
- **Claim 15** (`scripts/dev-cycle.sh:31-32`): "inert on a UTF-8 terminal" needs runs on the target terminal emulators.

### Residues worth a reviewer's eye (inside Verified scopes)
- Claim 24: section 7 silently drops quoted names (a control character, or non-ASCII under the default `core.quotePath`) from its skill and record counts.
- Claim 22: `*.md` and `docs/` matching is case-sensitive (`NOTES.MD` and `Docs/` count as code).
- Claim 16: test 7 passes on db0e5ca too, so it does not discriminate the A5 fix.
- Claim 17: `| head` gives exit 141, and it cannot be told whether that is the body's status or the scrub's.

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

The report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-r1-digest-final5.md`. Its first line is `Commit: 28c6178 (A) / c079e8c (B)`, and it follows the code-fact-check output format: header fields, 47 claims each with the seven mandatory fields and a Verification mode, and the attention summary. It covers both units, their contract and the three commit messages, with the brief's nine priority areas checked first. Scratch output is only under `fc5-r1/`, and nothing was committed.
