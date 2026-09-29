Commit: 89a3d3b

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-devcycle`, branch `feat/dev-cycle`)
**Scope:** `git diff main...HEAD` (README.md, docs/decisions/log.md, docs/roadmap.md, global-instructions/CLAUDE.md, guides/skill-creation.md, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/dev-cycle.bats) plus commit messages 1f8ed13 and 89a3d3b
**Checked:** 2026-09-29
**Total claims checked:** 40
**Summary:** 28 verified, 8 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Captured outputs are under `docs/reviews/execution-logs/r2-devcycle-*.txt` (untracked, alongside the sibling replicates' logs). The throwaway probe repos (`r1`, `r2`, `r3`, `mut`) were under the session scratchpad, written `$FCC/` below. Every probe that ran `scripts/dev-cycle.sh` against a repo with content used one of those throwaway repos, except one read-only run in the worktree (claim 25). `docs/reviews/hallucination-patterns.md` was read. No claim matches a logged pattern.

---

## Claim 1: "`skills/` holds 34 Claude Code skills ... the `dev-cycle` skill (the outer maintenance loop; `docs/roadmap.md`)"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill count and the existence of `skills/dev-cycle/`. Does not establish the rest of the README paragraph's category list.

Counting directories gives 34 skills on this branch and 33 on `main`: `ls -d skills/*/ | wc -l` → 34, `ls skills/*/SKILL.md | wc -l` → 34, `git ls-tree -d --name-only main skills/ | wc -l` → 33 (paraphrased — no quote available because the claim is about directory layout, not a snippet). `skills/dev-cycle/SKILL.md:2` reads `name: dev-cycle`.

**Evidence:** `README.md:182`, `skills/dev-cycle/SKILL.md:2`

---

## Claim 2: "As of 2026-09-28, 11 decision records with revisit triggers and 7 log rows with "Revisit" had nothing reading them."

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two counts at ec297d4 (2026-09-28 22:30, the last merge before this branch's base) and whether anything in the repo reads the triggers. Does not establish how often the onboarding workflow is actually run.

At ec297d4, 11 records carry a `## Revisit triggers` heading. 7 numbered log rows match `revisit` case-insensitively (rows 35, 53, 57, 58, 60, 62, 63), but only 6 match the quoted capitalised "Revisit": row 35 says `revisit at the A8 post-restructure measurement` (docs/decisions/log.md:55). "Nothing reading them" also overstates. `workflows/codebase-onboarding.md:309` already harvests the record triggers:

```
1. `grep '## Revisit triggers' docs/decisions/*.md` to find decision records that name re-examination conditions.
```

It does this only during onboarding runs, so "nothing read them routinely" is the precise version. The same wording, "revisit triggers that nothing read", appears in commit 1f8ed13 (claim 33b).

Provenance: command = loop of `git show ec297d4:<f> | grep -q '^## Revisit triggers'` over `git ls-tree --name-only ec297d4 docs/decisions/` plus `grep -E '^\| [0-9]+ \|' | grep -c 'Revisit'` / `grep -ci 'revisit'` on `git show ec297d4:docs/decisions/log.md`. cwd = `/workspace/.claude/wt-devcycle`. Exit 0. Run 2026-09-29T02:0x-07:00 (timestamp in the log).

**Evidence:** `docs/decisions/log.md:90`, `docs/decisions/log.md:55`, `workflows/codebase-onboarding.md:309`, `docs/reviews/execution-logs/r2-devcycle-revisit-counts-ec297d4.txt`

---

## Claim 3: "Mechanical parts are a script because steps only prose asks for do not run (Q-074; the override log's nine unwritten runs)."

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both cited sources exist and say this. Does not establish the underlying counts, which are those sources' own claims.

`scripts/questions.sh:7-8` reads: "holds 0 entries against 104 eligible fix commits, and the code-review override / log went unwritten for nine runs, both because only prose asked for them." Q-074 (`docs/working/questions.md`) says `failure-patterns.md` "has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only."

**Evidence:** `scripts/questions.sh:7-8`, `docs/working/questions.md` (Q-074)

---

## Claim 4: "Q-075 — evidence that the self-improvement loop is safe to resume. Motive: Q-068 was answered "resume" on condition of this evidence; ... dormant since. First step: list every path, config, hook, credential and git ref `scripts/self-improvement.sh` can write outside its working docs."

**Location:** `docs/roadmap.md:20-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the Q-068 and Q-075 entries. Does not establish the ranking.

The Q-068 archive entry reads: "**Answered 2026-09-27: [3] resume ...** ... first needs to trust that the script will not break their setup ... So the loop stays dorm[ant]". Q-075 reads: "list every path, config, hook, credential and git ref the loop can write outside its own working docs", with "**Interim:** the loop stays dormant."

**Evidence:** `docs/working/questions-archive.md` (Q-068), `docs/working/questions.md` (Q-075)

---

## Claim 5a: "Q-088 ... Motive: Q-098 (a global allow list) ... wait[s] on a Bash sandbox."

**Location:** `docs/roadmap.md:24-25`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-098's dependency on Q-088. Does not cover Q-092 (claim 5b).

Q-098 reads: "Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088)", with "**Trigger:** Q-088 answers [1] (build the sandbox)". Q-088 carries its own "Success: a sandboxed Bash call in a cc-isolated container..." criterion, which is the item's "first step".

**Evidence:** `docs/working/questions.md` (Q-098, Q-088)

---

## Claim 5b: "... and Q-092 wait on a Bash sandbox."

**Location:** `docs/roadmap.md:24-25`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every Q-092 mention in the repo's markdown (the entry, its index row, log row 53). Does not establish the author's unstated intent.

Q-092 is an `agent` item to remove the hook's deny reader "Per Q-082's answer (`permissions.deny` beats a hook `allow`)". Its only constraint is a pre-mortem on bypass families, and its interim is "the reader stays. It is redundant for `allow`, not harmful." It does not mention a sandbox, Q-088 or Q-098. Log row 53 says only "its removal is Q-092". `rg -n 'Q-092' docs/ -g '*.md'` finds no other mention (paraphrased — no quote available because the claim concerns the absence of a dependency across all matches). Nothing Q-092 records makes it wait on a Bash sandbox, so Q-088's motive should cite Q-098 alone, or name the real link.

**Evidence:** `docs/working/questions.md:153-160`, `docs/decisions/log.md:76`

---

## Claim 6: "Q-089 — host-tool trust category. Motive: `cc-push.sh` and the exit scan are verified by `Live-verified:`, which does not fit host-only tools (Q-083 [1]). First step: the trust-manifest section."

**Location:** `docs/roadmap.md:27-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Q-083 and Q-089. Does not verify the live-verify gate's code.

Q-083 reads: "**Answered 2026-09-28: [1] separate host-tools category.** Filed as Q-089" and "host tools can't be live-probed, so every commit to them carries `Live-verified: no`". Q-089 reads: "host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-manifest section and commit trailer".

**Evidence:** `docs/working/questions-archive.md` (Q-083), `docs/working/questions.md` (Q-089)

---

## Claim 7: "Measure router uptake. Motive: log row 66's revisit trigger. ... count multi-file merges that carry RPI research/plan docs and pr-prep review artifacts (an artifact count, not the usage log, which under-counts, Q-017)."

**Location:** `docs/roadmap.md:30-33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with row 66 and Q-017. Does not establish that the measurement is feasible.

Row 66 reads: "Revisit if, over the first three dev cycles after install, multi-file merges still land without the RPI research/plan docs or pr-prep review artifacts they should carry (an artifact count, not the usage log)". The Q-017 answer reads: "an instrument with a known history of silent under-counting should not generate attention asks".

**Evidence:** `docs/decisions/log.md:89`, `docs/working/questions-archive.md` (Q-017)

---

## Claim 8: "A8 post-restructure token measurement. Motive: the user deferred big compute until code and prompts settle; it validates code-review lever #3. First step: ... re-run one canon cell."

**Location:** `docs/roadmap.md:34-36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with project memory and log row 35. Does not establish whether settlement has been reached.

The project memory `run-a8-measurement-after-settling.md` reads: "the post-restructure measurement of code-review lever #3 (re-run ≥1 canon cell ...) should be run — but only after the code/prompt changes in /workspace are fully settled". Log row 35's revisit clause is "revisit at the A8 post-restructure measurement."

**Evidence:** `~/.claude/projects/-workspace/memory/run-a8-measurement-after-settling.md`, `docs/decisions/log.md:55`

---

## Claim 9: "Q-079 — canon-instance script and proposal filter. Signal: the review canon grows only by hand (Q-072)."

**Location:** `docs/roadmap.md:42-43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that Q-079 and Q-072 say this. Does not audit the ledger's git history.

Q-072 reads: "`docs/working/canon-issue-ledger.md` hasn't changed since 2026-08-18. Since then, 112 September review artifacts have been written ... and none feed back into it". Q-079 reads: "Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the higher-level heuristic that decides which candidates get *proposed*."

**Evidence:** `docs/working/questions-archive.md` (Q-072), `docs/working/questions.md` (Q-079)

---

## Claim 10: "Signal: Q-074, 1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26."

**Location:** `docs/roadmap.md:44-45`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Q-074's text. Does not recount fix commits.

The count matches. The reopening is conditional. Q-074 says: "If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment". The precise version is "it reopens as a judgment on 2026-10-26 if fewer than 5 new entries have landed."

**Evidence:** `docs/working/questions.md` (Q-074)

---

## Claim 11: "Narrow code-review's "default whenever a PR is prepared" description ... (override log, deferred from log row 66's review)" and "Finish skill-format-audit F1: drop `when:` repo-wide and from `divergent-design-router.bats`. Signal: override log, deferred from log row 66's review."

**Location:** `docs/roadmap.md:46-49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of both override-log rows. Does not check the current code-review description.

`docs/reviews/override-log.md:161` reads: "`skills/code-review/SKILL.md` description still says "default whenever a PR is prepared or evaluated", overlapping pr-prep ... | Deferred". `:164` reads: "`test/skills/divergent-design-router.bats` still requires `when:`/`trigger` ... | Deferred | ... finishing skill-format-audit F1 repo-wide is a separate change." Both rows are on `feat/workflow-router-skills` (row 66).

**Evidence:** `docs/reviews/override-log.md:161`, `docs/reviews/override-log.md:164`

---

## Claim 12: "merging the row-66 branch hit add/add conflicts on `code-fact-check-report-r*.md` and `*-review-<date>.md`"

**Location:** `docs/roadmap.md:50-52`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge 33fdfd3 (main c9a370a into feat/workflow-router-skills 028105b), replayed with `git merge-tree`. Does not cover the later merge 4225753.

The replay reports both sets of files, but with different conflict types. Only the dated review files were add/add:

```
CONFLICT (content): Merge conflict in docs/reviews/code-fact-check-report-r1.md
...
CONFLICT (add/add): Merge conflict in docs/reviews/performance-review-2026-09-29.md
CONFLICT (add/add): Merge conflict in docs/reviews/security-review-2026-09-29.md
```

The `code-fact-check-report-r*.md` files were content conflicts, because they already existed at the merge base. The collision observation is right. The conflict type is right only for the dated files.

Provenance: command = `git merge-tree --write-tree --name-only --messages 028105b c9a370a`. cwd = `/workspace/.claude/wt-devcycle`. Exit 1 (conflicts). Timestamp in the log.

**Evidence:** `docs/reviews/execution-logs/r2-devcycle-merge-tree-33fdfd3.txt`

---

## Claim 13: "AGENTS.md names workflows by filename ... (log row 65, merge c9a370a). Removes ~89K tokens from every session and subagent in this repo." / "A router skill for every workflow except review-fix-loop (log row 66, merge 4225753)."

**Location:** `docs/roadmap.md:58-60`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge hashes, the row numbers, and the byte count of the nine `@` imports at ec297d4. Does not establish that Claude Code expands every import (log row 65's own claim).

`git log` shows `c9a370a merge: AGENTS.md names workflows by filename, not @-import (decision log 65)` and `4225753 merge: a router skill for every workflow (decision log 66)`. Summing the nine `@./workflows/*.md` targets in `ec297d4:AGENTS.md` gives `total 358414 chars/4 89603.5`, consistent with row 65's "~358 KB (~89K tokens at chars/4)".

Provenance: command = `git show ec297d4:AGENTS.md | grep -o '@\./workflows/[a-z-]*\.md' | sort -u | while read p; do git show "ec297d4:${p#@./}" | wc -c; done`. cwd = worktree. Exit 0. Timestamp in the log.

**Evidence:** `docs/reviews/execution-logs/r2-devcycle-agents-import-bytes.txt`, `docs/decisions/log.md:88`

---

## Claim 14: "| 12 | **Maintenance or planning pass over the repo** ... | `dev-cycle` skill | ... health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap (`docs/roadmap.md`). User-started, no timer. Output is triage in `docs/working/questions.md`. |"

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's summary of the skill. Does not establish how first-match routing resolves overlaps with earlier rows.

The skill exists. `skills/dev-cycle/SKILL.md:14` says "It runs when the user starts it; there is no timer." `:17-19` says "only decisions that need the user become `you: judgment` entries in `docs/working/questions.md`". Steps 1, 2, 4, 5 and 6 are health and cleanup, revisit triggers, spot-check audit, brainstorm and roadmap.

**Evidence:** `skills/dev-cycle/SKILL.md:14-19`, `skills/dev-cycle/SKILL.md:34-88`

---

## Claim 15: "`dev-cycle` | **Adequate** | Workflow-shaped (seven ordered steps, triage output) but user-started and single-session, so a skill; its mechanical parts live in `scripts/dev-cycle.sh`."

**Location:** `guides/skill-creation.md:137`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step count and the script reference. Does not assess the form-factor judgment.

The skill numbers its steps `### 0. Digest` through `### 7. Close` (`skills/dev-cycle/SKILL.md:26`, `:90`), which is eight steps. Log row 67 also lists eight: "digest → health and cleanup → ... → cycle record". "Seven" is right only if the digest is not counted. The precise version is "eight ordered steps (0–7)".

**Evidence:** `skills/dev-cycle/SKILL.md:26-95`, `docs/decisions/log.md:90`

---

## Claim 16: "this repo's evidence is that steps only prose asks for do not run (scripts/questions.sh header; Q-074)."

**Location:** `scripts/dev-cycle.sh:7-8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the cited header and question say this. Does not re-derive their numbers.

`scripts/questions.sh:5-8` reads: "Why a script and not a convention: this repo's own evidence is that an unenforced instruction does not execute". Q-074 describes the advisory-only writer (claim 3).

**Evidence:** `scripts/questions.sh:5-8`, `docs/working/questions.md` (Q-074)

---

## Claim 17a: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago."

**Location:** `scripts/dev-cycle.sh:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which date is chosen: the date in the filename, the lexically greatest, and the fallback when no record exists. Does not cover what that date means to `git log` (claim 17b).

```bash
# scripts/dev-cycle.sh:44-52
if [[ -z "$SINCE" ]]; then
  last=""
  for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
    [[ -f "$f" ]] || continue
    d="${f##*/cycle-}"; d="${d%.md}"
    [[ "$d" > "$last" ]] && last="$d"
  done
  SINCE="${last:-$(date -d '14 days ago' +%F)}"
fi
```

The date comes from the filename, not the file's contents. Bats test 3 passes, and fails under a mutation that picks the oldest record (claim 32). The worktree run printed `Window: since 2026-09-15` on 2026-09-29, which is the 14-day fallback.

Provenance: `bats test/dev-cycle.bats` in the worktree, exit 0, 2026-09-29T02:00:37-07:00. `bash scripts/dev-cycle.sh` in the worktree, exit 0, 2026-09-29T01:57:04-07:00.

**Evidence:** `scripts/dev-cycle.sh:44-52`, `docs/reviews/execution-logs/r2-devcycle-bats-baseline.txt`, `docs/reviews/execution-logs/r2-devcycle-digest-worktree.txt`, `docs/reviews/execution-logs/r2-devcycle-mutation-results.txt`

---

## Claim 17b: "--since   start of the cycle window." (with the digest printing "Window: since $SINCE")

**Location:** `scripts/dev-cycle.sh:12`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the date is passed to `git log`/`git rev-list`. Does not establish how often a real cycle would lose or double-count a merge.

`merges="$(git log "$MAIN" --first-parent --merges --since="$SINCE" ...)"` (`scripts/dev-cycle.sh:61`) passes a bare `YYYY-MM-DD`. Git reads that as the date at the current time of day, not at midnight. In a throwaway repo with 5 merges made at 01:57 that day, a run at 01:58 with `--since 2026-09-29` printed:

```
0 merge(s), 0 commit(s) on `main` in the window.
```

`git log --merges --since="2026-09-29 00:00"` counts 5. So the window starts at SINCE plus the current wall-clock time. Merges made on the record's date before that time of day are left out. The precise version is "window starts at that date at the current time of day", unless the script appends `00:00`.

Provenance: command = `bash $DC --since 2026-09-29`. cwd = `$FCC/r3`. Exit 0. Run 2026-09-29T01:58:18-07:00.

**Evidence:** `scripts/dev-cycle.sh:61-62`, `docs/reviews/execution-logs/r2-devcycle-since-today.txt`

---

## Claim 18a: "Acts on the git repo of $PWD (like questions.sh)"

**Location:** `scripts/dev-cycle.sh:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolving the repo from a subdirectory of `$PWD`. Does not cover non-`main` trunks (claim 18b).

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {...}; cd "$ROOT"` (`scripts/dev-cycle.sh:36-37`). Run from `$FCC/r3/docs/working`, it reported r3's merges and questions (`5 merge(s), 12 commit(s)`).

Provenance: command = `bash $DC`. cwd = `$FCC/r3/docs/working`. Exit 0. 2026-09-29 (in the log).

**Evidence:** `scripts/dev-cycle.sh:36-37`, `docs/reviews/execution-logs/r2-devcycle-r3-subdir.txt`

---

## Claim 18b: "so the installed copy at ~/.claude/scripts/dev-cycle.sh serves any project."

**Location:** `scripts/dev-cycle.sh:16-17`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repos without origin/HEAD whose trunk is not `main`, and repos whose origin/HEAD points at `master`. Does not cover empty repos or detached setups.

A repo with origin/HEAD works whatever its trunk is called: a clone whose origin/HEAD is `origin/master` printed `on \`master\` at 7a87620`. A local-only repo whose trunk is `master` crashes:

```
fatal: Needed a single revision
Window: since 2026-09-15, on `main` at .
fatal: ambiguous argument 'main': unknown revision ...
exit=128
```

The cause is `[[ -n "$MAIN" ]] || MAIN=main` (`:42`) followed by an unguarded `git log "$MAIN"` under `set -e`. The precise version is "any project with origin/HEAD or a `main` branch". The installed-copy half holds: `devcontainer-config/install.sh:135` stages the whole `scripts` directory (`CLAUDE_HOME_SRC=(... hooks scripts)`).

Provenance: command = `bash $DC`. cwd = `$FCC/r1` (git init -b master, no remote). Exit 128. 2026-09-29T01:57:32-07:00.

**Evidence:** `scripts/dev-cycle.sh:40-42`, `scripts/dev-cycle.sh:57-61`, `devcontainer-config/install.sh:135`, `docs/reviews/execution-logs/r2-devcycle-master-norigin.txt`

---

## Claim 19: "Read-only: prints to stdout and writes nothing."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working tree and `.git` of a repo with questions, archive and roadmap files, across two runs. Does not cover writes by a replaced `questions.sh` found through `$HOME`.

I took a sha256 plus path listing of every file in `$FCC/r3` (including `.git`) before and after two runs, and a `.git` mtime listing. `diff` printed nothing (`NO-FILE-CHANGES`). The only subprocess that could write is `bash "$QS" open`, and `cmd_open` only parses and prints (`scripts/questions.sh:408-414`: `parse_entries "$LIVE" | route_rank | sort ... | while ... printf`).

Provenance: command = `bash $DC` twice. cwd = `$FCC/r3`. Exit 0 both times. 2026-09-29T01:57:48-07:00.

**Evidence:** `scripts/questions.sh:408-414`, `docs/reviews/execution-logs/r2-devcycle-before.txt`, `docs/reviews/execution-logs/r2-devcycle-after.txt`, `docs/reviews/execution-logs/r2-devcycle-r3-run1.txt`, `docs/reviews/execution-logs/r2-devcycle-r3-run2.txt`

---

## Claim 20: "# No origin/HEAD (a local-only repo) is normal; fall back to main."

**Location:** `scripts/dev-cycle.sh:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback assignment surviving `set -euo pipefail`. Does not establish that a `main` branch exists (see claim 18b).

```bash
# scripts/dev-cycle.sh:41-42
MAIN="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
[[ -n "$MAIN" ]] || MAIN=main
```

The bats repos have no remote, and all 6 tests pass on `main`.

**Evidence:** `scripts/dev-cycle.sh:41-42`, `docs/reviews/execution-logs/r2-devcycle-bats-baseline.txt`

---

## Claim 21: questions.sh lookup order, `$SCRIPT_DIR` then `~/.claude/scripts`

**Location:** `scripts/dev-cycle.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lookup order. Does not establish the output when `questions.sh open` fails. For example, with `questions.md` present but no `questions-archive.md`, `require_files` fails, the `|| true` swallows it, and the section prints "None open." with an empty route count.

```bash
# scripts/dev-cycle.sh:98-100
QS="$SCRIPT_DIR/questions.sh"
[[ -x "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
if [[ -f docs/working/questions.md && -f "$QS" ]]; then
```

The sibling copy wins when it is executable. Otherwise the installed one is used.

**Evidence:** `scripts/dev-cycle.sh:38`, `scripts/dev-cycle.sh:98-114`

---

## Claim 22: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain the word "trigger"."

**Location:** `scripts/dev-cycle.sh:101-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers routes of up to 14 characters, which includes every route in the grammar. Does not cover a route containing two consecutive spaces.

`printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`). The worktree digest parsed `you: terminal=1` correctly, and bats test 5 passes with a slug containing "trigger" but fails under a whole-line grep mutation (claim 32).

**Evidence:** `scripts/questions.sh:412`, `docs/reviews/execution-logs/r2-devcycle-digest-worktree.txt`, `docs/reviews/execution-logs/r2-devcycle-mutation-results.txt`

---

## Claim 23a: "... so a rerun on the same day audits the same merges."

**Location:** `scripts/dev-cycle.sh:120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reruns with an unchanged merge list. Does not hold if a merge lands between the two runs, because the list, and so the draw, changes.

Two runs in `$FCC/r3` gave the same section 4 (`SAME-SAMPLE`: `7619fe2 ... merge 2`, `046d910 ... merge 4`), and bats test 4 passes.

**Evidence:** `scripts/dev-cycle.sh:121`, `docs/reviews/execution-logs/r2-devcycle-r3-run1.txt`, `docs/reviews/execution-logs/r2-devcycle-r3-run2.txt`

---

## Claim 23b: "# Seeded by the date"

**Location:** `scripts/dev-cycle.sh:120`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU shuf 9.1 with `--random-source=<(yes "$TODAY")`, for merge lists of 5, 30 and 63 lines. Does not establish behaviour for lists long enough that shuf reads past the shared `20` prefix.

```bash
# scripts/dev-cycle.sh:121
printf '%s\n' "$merges" | shuf -n "$SAMPLE" --random-source=<(yes "$TODAY") | sed 's/^/- /'
```

The date has no effect on the sample. Every `YYYY-MM-DD` begins with the same bytes, and shuf reads only the first few bytes of the source for these sizes. With a PATH shim making `date +%F` return 2026-09-29, 2026-10-13, 2026-12-25 and 2031-05-05, the script printed the same two merges each time:

```
== 2026-10-13
- 7619fe2 2026-09-29 merge 2
- 046d910 2026-09-29 merge 4
```

A direct probe on 63 lines returned `51 50` for every date from 2026-09-15 to 2027-01-01. In practice the sample is a fixed function of the list's length: any cycle whose window has N merges samples the same positions. Determinism holds (claim 23a). "Seeded by the date" does not.

Provenance: commands = `FAKE_DATE=<d> PATH=$FCC/shim:$PATH bash $DC --since 2020-01-01`, cwd `$FCC/r3`, exit 0; `shuf -n 2 --random-source=<(yes $d) l63`, cwd `$FCC`, exit 0. 2026-09-29 (~01:58-07:00).

**Evidence:** `scripts/dev-cycle.sh:121`, `docs/reviews/execution-logs/r2-devcycle-fake-date-sample.txt`, `docs/reviews/execution-logs/r2-devcycle-shuf-seed-probe.txt`

---

## Claim 24: "using the entry grammar in the global instructions ("Running questions document")"

**Location:** `skills/dev-cycle/SKILL.md:18-19`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the section exists. Does not check the grammar itself.

`global-instructions/CLAUDE.md:234` reads `### Running questions document`.

**Evidence:** `global-instructions/CLAUDE.md:234`

---

## Claim 25: "It is read-only and gives the window (since the last cycle record), merges in it, every revisit trigger, the watched questions, the spot-check sample and the roadmap's Next section."

**Location:** `skills/dev-cycle/SKILL.md:28-31`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "every revisit trigger" part for decision-log rows, run against this repo's current log. The other parts are covered by claims 17a, 19 and 23a. Does not cover triggers in records that lack a `## Revisit triggers` heading.

For each log row, the script prints only the first case-insensitive `revisit` match, up to the next `|`, capped at 400 characters:

```bash
# scripts/dev-cycle.sh:81,88
rows="$(grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit' || true)"
text="$(printf '%s' "$row" | grep -oiE 'revisit[^|]*' | head -1 | cut -c1-400)"
```

In the read-only worktree run, row 67's actual trigger ("Revisit if three cycles in a row file nothing ... or if the gap between cycles passes a month twice") is missing. The script printed the earlier step list instead:

```
- row 67: revisit-trigger verdicts (fired / not fired / cannot tell, with evidence) → watched questions → ... so only `you: judgment` items spe
```

Row 53's trigger is also cut off mid-sentence at 400 characters. So the digest does not give every revisit trigger. It misses a row's trigger whenever the word "revisit" appears earlier in that row, which is the case for this branch's own row. The same claim appears in commit 1f8ed13 (claim 33a).

Provenance: command = `bash scripts/dev-cycle.sh`. cwd = `/workspace/.claude/wt-devcycle`. Exit 0. 2026-09-29T01:57:04-07:00. `git status --short` was empty before and after.

**Evidence:** `scripts/dev-cycle.sh:80-92`, `docs/decisions/log.md:90`, `docs/reviews/execution-logs/r2-devcycle-digest-worktree.txt`

---

## Claim 26: "triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)."

**Location:** `skills/dev-cycle/SKILL.md:38-39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that step 5a has three matching classes. "Recent work" is the cycle's adaptation of "this branch". Does not check the rest of step 5a.

The `workflows/pr-prep.md:341-343` table rows are `| Caused by this branch |`, `| Pre-existing on main |` and `| Flaky / infra / environmental |`.

**Evidence:** `workflows/pr-prep.md:341-343`

---

## Claim 27: "`questions.sh archive` then `questions.sh index`, so answered entries leave the live file."

**Location:** `skills/dev-cycle/SKILL.md:40`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both subcommands exist and what they do. Does not execute them. `archive` already reindexes, so the following `index` is redundant but harmless.

The `scripts/questions.sh` usage says: "archive    move ANSWERED entries to the archive, reindex" and "index      regenerate the index tables in place". The dispatch is `archive) cmd_archive ;;` and `index)   cmd_index ;;` (`:449-450`). `init` and `open` also exist (`:447`, `:452`).

**Evidence:** `scripts/questions.sh:27-33`, `scripts/questions.sh:447-452`

---

## Claim 28: "`scripts/archive-working-docs.sh -n` lists what would move."

**Location:** `skills/dev-cycle/SKILL.md:43-44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flag's documented meaning and parsing. Does not execute the script.

`scripts/archive-working-docs.sh:22` reads `#   -n, --dry-run   Show what would be moved without moving anything`, and `:31` reads `-n|--dry-run) DRY_RUN=true ;;`.

**Evidence:** `scripts/archive-working-docs.sh:4`, `scripts/archive-working-docs.sh:22`, `scripts/archive-working-docs.sh:31`

---

## Claim 29: "Use `code-fact-check` at k=1 for a merge with many claims."

**Location:** `skills/dev-cycle/SKILL.md:66-67`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that k denotes the fact-check replicate count and that k=1 is a sanctioned setting. Does not establish that the code-fact-check skill itself takes a k parameter. It does not: k is a code-review concept, and a standalone run is one replicate.

`skills/code-review/SKILL.md:20` reads: "Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031...". `skills/code-fact-check/` exists.

**Evidence:** `skills/code-review/SKILL.md:20`

---

## Claim 30: "Update `docs/roadmap.md` (create it from its own template if missing)"

**Location:** `skills/dev-cycle/SKILL.md:80`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether a roadmap template file exists. Does not decide whether the author meant the four section bullets that follow as the template.

No roadmap template ships: `templates/` holds only `gitattributes-snippet.txt`, and `rg -il roadmap templates/` returns nothing (paraphrased — no quote available because the claim concerns the absence of a file). `docs/roadmap.md` itself contains no template block. The only structure definition is the skill's own Now/Next/Ideas/Done bullets (`:82-85`). In a repo with no roadmap, "its own template" can only mean those bullets. The precise version is "create it with the sections below".

**Evidence:** `skills/dev-cycle/SKILL.md:80-85`, `docs/roadmap.md:1-60`

---

## Claim 31: "Each test builds a throwaway git repo under $BATS_TEST_TMPDIR, so nothing reads or writes this repo's own docs/." / "HOME points at the temp dir so the ~/.claude/scripts fallback can't reach the real installed questions.sh."

**Location:** `test/dev-cycle.bats:4-5`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the docs/ isolation and the HOME redirect. Does not claim the tests avoid executing this repo's code: they do run `scripts/questions.sh` through `$SCRIPT_DIR`, but against the temp repo's docs.

```bash
# test/dev-cycle.bats:12,17,19-22
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export HOME="$BATS_TEST_TMPDIR/home"
R="$BATS_TEST_TMPDIR/repo"
mkdir -p "$R"
cd "$R" || return 1
git init -q -b main
```

The script resolves its repo from `$PWD` (claim 18a), so it reads R's docs.

**Evidence:** `test/dev-cycle.bats:9-30`

---

## Claim 32: Each test fails when the behaviour it names breaks (test names at `test/dev-cycle.bats:32,44,57,64,74,104`)

**Location:** `test/dev-cycle.bats:32-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one targeted mutation per named behaviour, applied to a scratch copy of the script. Does not establish that test 4 catches the date-independence defect (claim 23b), which it cannot. Test 4 also catches an unseeded shuf only probabilistically: 7 of 8 runs.

Mutations applied to `$FCC/mut/scripts/dev-cycle.sh`, with the whole suite run each time:

- M1: drop `--random-source` → test 4 fails, and 7/8 in repeated runs.
- M2: route match by whole-line grep → test 5 fails.
- M3: pick the oldest cycle record → test 3 fails.
- M4: revisit awk without the stop at the next `##` → test 2 fails.
- M5: skip log rows → test 2 fails.
- M6: drop `--since` validation → test 6 fails.
- M7: `shuf -n 1` → test 4 fails.

Test 1 (all five sections, no docs) is covered by the baseline run of the unmutated script. In every mutation, only the targeted test failed (paraphrased — no quote available because the results span 8 suite runs; see the log).

Provenance: command = `bats $FCC/mut/test/dev-cycle.bats` per mutation, plus `bats -f 'same ones'` ×8 for M1. cwd = `$FCC`. Exit 1 on each mutated run. Baseline `bats test/dev-cycle.bats` in the worktree exited 0 at 2026-09-29T02:00:37-07:00.

**Evidence:** `docs/reviews/execution-logs/r2-devcycle-mutation-results.txt`, `docs/reviews/execution-logs/r2-devcycle-bats-baseline.txt`

---

## Claim 33a: "a date-seeded spot-check sample of merges" and "every revisit trigger (records and log rows)"

**Location:** commit `1f8ed13` (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two mechanism claims, via claims 23b and 25. Does not re-test anything beyond those.

Commit 1f8ed13 says: "a date-seeded spot-check sample of merges" and "every revisit trigger (records and log rows)". The sample does not depend on the date (claim 23b, `docs/reviews/execution-logs/r2-devcycle-fake-date-sample.txt`). Log-row extraction prints the wrong clause for row 67 and truncates row 53 (claim 25, `docs/reviews/execution-logs/r2-devcycle-digest-worktree.txt`).

**Evidence:** `scripts/dev-cycle.sh:81-88`, `scripts/dev-cycle.sh:121`, `docs/reviews/execution-logs/r2-devcycle-fake-date-sample.txt`, `docs/reviews/execution-logs/r2-devcycle-digest-worktree.txt`

---

## Claim 33b: "11 decision records and 7 log rows carry revisit triggers that nothing read" and "Works in any repo (acts on $PWD's repo; falls back to main without origin/HEAD)."

**Location:** commit `1f8ed13` (message body)
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts (claim 2) and the any-repo claim (claim 18b).

The counts are 11 and 7 when matched case-insensitively. The onboarding workflow does read record triggers (claim 2). "Works in any repo" fails, exit 128, in a local-only repo whose trunk is not `main` (claim 18b).

**Evidence:** `docs/reviews/execution-logs/r2-devcycle-revisit-counts-ec297d4.txt`, `docs/reviews/execution-logs/r2-devcycle-master-norigin.txt`, `workflows/codebase-onboarding.md:309`

---

## Claim 33c: "test/dev-cycle.bats: six hermetic tests in throwaway repos." and "Global decision tree row 12; decision log row 67."

**Location:** commit `1f8ed13` (message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test count, the isolation (claim 31), and the presence of both rows. Does not cover their contents (claims 2, 14).

`test/dev-cycle.bats` has six `@test` blocks (`:32, :44, :57, :64, :74, :104`). Row 12 is at `global-instructions/CLAUDE.md:32` and row 67 at `docs/decisions/log.md:90`.

**Evidence:** `test/dev-cycle.bats:32-109`, `global-instructions/CLAUDE.md:32`, `docs/decisions/log.md:90`

---

## Claim 34: "dev-cycle description <=250 chars with a precedence clause; no when:" / "README: 34 skills, dev-cycle named; skill-creation inventory row" / "Roadmap: rows 65/66 to Done; router-uptake measure counts artifacts, not the usage log; deferred review items added to Ideas with signals" / "Row 67: date the revisit-trigger counts"

**Location:** commit `89a3d3b` (message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet's presence in the tree at 89a3d3b. Does not re-verify the facts inside the roadmap items (claims 4-13).

Parsing the frontmatter with Python gives a description length of 242 and no `when:` key. The description contains the precedence clause "Not for landing one change (pr-prep)." (`skills/dev-cycle/SKILL.md:4`). README says 34 skills (claim 1). The inventory row is at `guides/skill-creation.md:137`. Done lists rows 65 and 66 (`docs/roadmap.md:58-60`). Item 4 says "an artifact count, not the usage log" (`:32-33`). Ideas cites the override-log deferrals (`:46-49`). Row 67 reads "As of 2026-09-28, 11 decision records...".

Provenance: command = `python3 -c "...len(description)...; 'when:' in frontmatter"`. cwd = worktree. Exit 0. Output `242` / `False`, 2026-09-29, printed inline in the session (short enough to quote here in full).

**Evidence:** `skills/dev-cycle/SKILL.md:1-5`, `guides/skill-creation.md:137`, `docs/roadmap.md:30-60`, `docs/decisions/log.md:90`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`docs/roadmap.md:24-25`): Q-092 does not wait on a Bash sandbox. Its entry has no sandbox, Q-088 or Q-098 dependency. Cite Q-098 alone as Q-088's motive.
- **Claim 23b** (`scripts/dev-cycle.sh:120`): the "date seed" has no effect. `yes "$TODAY"` gives shuf the same leading bytes for every date, so the sample depends only on the merge count. Reword the comment, or use a real seed (for example, hash the date and feed the digest bytes).
- **Claim 25** (`skills/dev-cycle/SKILL.md:28-31`): the digest does not show "every revisit trigger". For a log row it prints the first `revisit` match, which for row 67 is the step list rather than the trigger, and it truncates row 53 at 400 characters.
- **Claim 33a** (commit `1f8ed13`): repeats "date-seeded" and "every revisit trigger". Both are refuted as above.

### Stale
- (none)

### Mostly Accurate
- **Claim 2** (`docs/decisions/log.md:90`): 7 rows only case-insensitively (6 with "Revisit"). The onboarding workflow step 10 does read the record triggers.
- **Claim 10** (`docs/roadmap.md:44-45`): Q-074 reopens on 2026-10-26 only if fewer than 5 new entries have landed.
- **Claim 12** (`docs/roadmap.md:50-52`): the `code-fact-check-report-r*.md` files were content conflicts. Only the dated review files were add/add.
- **Claim 15** (`guides/skill-creation.md:137`): the skill has eight steps (0–7), not seven.
- **Claim 17b** (`scripts/dev-cycle.sh:12`): `--since YYYY-MM-DD` starts at the current time of day on that date, not at its start, so earlier merges that day are left out. Append ` 00:00`, or document it.
- **Claim 18b** (`scripts/dev-cycle.sh:16-17`): "serves any project" fails (exit 128) in a local-only repo whose trunk is not `main`.
- **Claim 30** (`skills/dev-cycle/SKILL.md:80`): no roadmap template exists. "Create it with the sections below" is the precise version.
- **Claim 33b** (commit `1f8ed13`): the same count and any-repo qualifiers as claims 2 and 18b.

### Unverifiable
- (none)

## Goal-Alignment Note
- **Answered:** I checked every claim the brief listed: the dev-cycle.sh header and comments, including read-only, $PWD, the default window, the main fallback, the same-day rerun and the questions.sh order; every command and path the skill names; each roadmap line; log row 67's counts at ec297d4; global row 12; the README and guide lines; the bats header, plus a mutation per named test; and both commit messages. The four Incorrect findings are real defects or misstatements: the no-op date seed, row-67 trigger extraction, Q-092, and the repeats in 1f8ed13.
- **Out of scope:** code quality, and whether the `head -30` merge listing or the swallowed `questions.sh open` failure (claim 21's residue) should change; those are for the review critics. I did not run scripts/health-check.sh or the full suite, as the brief instructed. Captured outputs were copied to `docs/reviews/execution-logs/r2-devcycle-*.txt` (new untracked files; no tracked file was edited).
- **Escalate:** claim 23b means the spot-check audit, the cycle's claimed defence against drift, samples the same positions in every cycle of equal size. It is worth fixing before the first cycle runs. No hallucination-pattern entry was added: none of the Incorrect verdicts is a fabricated symbol or API, and the brief forbids editing other tracked files.
