Commit: 89a3d3b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-devcycle (branch feat/dev-cycle)
**Scope:** branch diff `git diff main...HEAD` (README.md, docs/decisions/log.md, docs/roadmap.md, global-instructions/CLAUDE.md, guides/skill-creation.md, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/dev-cycle.bats) plus commit messages 1f8ed13 and 89a3d3b; replicate r1 of 3
**Checked:** 2026-09-29
**Total claims checked:** 44
**Summary:** 29 verified, 10 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern, and no Incorrect verdict here is a fabricated symbol, so the log is not updated.

Execution logs for every `executed` claim are under `docs/reviews/execution-logs/r1-devcycle-*.txt`. All probes ran under `timeout`, in throwaway repos under the scratchpad or read-only in the worktree; no process remained afterwards (`pgrep -u $(id -u)` showed none).

---

## Claim 1: "`skills/` holds 34 Claude Code skills"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of directories under `skills/` at HEAD; does not establish that the README's category enumeration names every skill (arithmetic-eval is not named in any category, as before this branch).

`ls -d skills/*/ | wc -l` prints `34` (paraphrased — no quote available because the claim is about directory layout, not a snippet); `skills/dev-cycle/` is the one added by this branch.

**Evidence:** `README.md:182`, `skills/`

---

## Claim 2: "As of 2026-09-28, 11 decision records with revisit triggers and 7 log rows with "Revisit" had nothing reading them."

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts at ec297d4 (the last main commit dated 2026-09-28, 22:30) and whether any script, hook, test or workflow read those sections at that commit; does not establish how often the one reading workflow was actually run.

Counts: at ec297d4, exactly 11 records contain `^## Revisit triggers` (014, 015, 016, 017, 021, 028, 030, 031, 035, 036, 037), matching. Log rows: 7 rows match case-insensitively (35, 53, 57, 58, 60, 62, 63), but only 6 contain the capitalised word the claim quotes; row 35 reads "revisit at the A8 post-restructure measurement" (`docs/decisions/log.md:55`, lowercase). The count of 7 is right under a case-insensitive reading, which is how `scripts/dev-cycle.sh:81` counts (`grep -i 'revisit'`).

"Nothing reading them": at ec297d4 `workflows/codebase-onboarding.md` step 10 already harvested record triggers:

```
# workflows/codebase-onboarding.md:309
1. `grep '## Revisit triggers' docs/decisions/*.md` to find decision records that name re-examination conditions.
```

So record triggers had a reader, though only when an onboarding pass runs and only for records (not log rows); no script, hook or test read them (`git grep -l "Revisit triggers" ec297d4 -- scripts hooks test skills workflows` returns only the onboarding and divergent-design workflows). Precise version: "no recurring step read them; only codebase-onboarding step 10 harvested record triggers."

**Evidence:** `docs/decisions/log.md:90`, `docs/decisions/log.md:55`, `workflows/codebase-onboarding.md:309`, `git show ec297d4:docs/decisions/log.md`

---

## Claim 3: "Mechanical parts are a script because steps only prose asks for do not run (Q-074; the override log's nine unwritten runs)."

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both cited sources say what the row attributes to them; does not establish the causal claim itself.

`scripts/questions.sh:5-8`: "an unenforced instruction does not execute — ... the code-review override log went unwritten for nine runs, both because only prose asked for them." Q-074 (`docs/working/questions.md`): "`docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only."

**Evidence:** `scripts/questions.sh:5-8`, `docs/working/questions.md` (Q-074)

---

## Claim 4: "Steps: digest → health and cleanup → revisit-trigger verdicts ... → cycle record in `docs/working/cycles/cycle-YYYY-MM-DD.md`. ... The global decision tree gains row 12."

**Location:** `docs/decisions/log.md:90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the row's step list, Next≤5 cap, cycle-record path and row-12 addition match the skill and global instructions; does not establish the row's rationale claims beyond Claims 2-3.

The skill's headings are `### 0. Digest` through `### 7. Close` in that order (`skills/dev-cycle/SKILL.md:26-92`); step 6 says "**Next**: at most five items" (`:83`); step 7 writes "`docs/working/cycles/cycle-YYYY-MM-DD.md`" (`:92`); `global-instructions/CLAUDE.md:32` begins "| 12 | **Maintenance or planning pass over the repo**".

**Evidence:** `skills/dev-cycle/SKILL.md:26-95`, `global-instructions/CLAUDE.md:32`

---

## Claim 5: "Q-075 — evidence that the self-improvement loop is safe to resume. Motive: Q-068 was answered "resume" on condition of this evidence; the loop ... has been dormant since. First step: list every path, config, hook, credential and git ref ..."

**Location:** `docs/roadmap.md:20-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-068 answer, Q-075's content and its interim; does not establish that the loop has in fact not run since (no run log was checked).

Q-068 (archive): "**Answered 2026-09-27: [3] resume** ... So the loop stays dormant until that trust exists. The trust work is filed as Q-075." Q-075: "list every path, config, hook, credential and git ref the loop can write outside its own working docs ... **Interim:** the loop stays dormant."

**Evidence:** `docs/working/questions-archive.md` (Q-068), `docs/working/questions.md` (Q-075)

---

## Claim 6a: "Motive: Q-098 (a global allow list) ... wait[s] on a Bash sandbox."

**Location:** `docs/roadmap.md:24-25`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-098's stated dependency; does not establish Q-088's likely outcome.

Q-098: "Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088)."

**Evidence:** `docs/working/questions.md` (Q-098)

---

## Claim 6b: "Motive: ... Q-092 wait[s] on a Bash sandbox."

**Location:** `docs/roadmap.md:25`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every statement of Q-092's dependencies in its entry and in decision log row 53; does not establish whether Q-092 should wait on the spike.

Q-092 is routed `agent` and depends on Q-082's answer, not on a sandbox:

```
### Q-092 · drop-hook-deny-reader
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader ...
- **Interim:** the reader stays. It is redundant for `allow`, not harmful.
```

Its Constraint names an enforcement-file pre-mortem and an `ask`-path check, with no sandbox mention; row 53's amendment says "its removal is Q-092" and puts the sandbox under Q-081, separately (paraphrased — no quote available because row 53 is a single ~3 KB table cell; the relevant sentences are its last two). Only Q-098 waits on the sandbox, so Q-088's motive as written overstates what it unblocks.

**Evidence:** `docs/working/questions.md:153-162` (Q-092), `docs/decisions/log.md:76`

---

## Claim 7: "Motive: `cc-push.sh` and the exit scan are verified by `Live-verified:`, which does not fit host-only tools (Q-083 [1])."

**Location:** `docs/roadmap.md:27-29`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-083 and Q-089's descriptions of the host tools' trailer; does not establish the current contents of the trust manifest.

Q-083: "host tools can't be live-probed, so every commit to them carries `Live-verified: no`, which dilutes row 45's debt list." They are gated by the `Live-verified:` trailer but are never actually live-verified; "verified by `Live-verified:`" should read "carry a `Live-verified: no` trailer". The Q-083 [1] / Q-089 link is right ("**Answered 2026-09-28: [1] separate host-tools category.** Filed as Q-089").

**Evidence:** `docs/working/questions-archive.md` (Q-083), `docs/working/questions.md` (Q-089)

---

## Claim 8: "Measure router uptake. Motive: log row 66's revisit trigger ... an artifact count, not the usage log, which under-counts, Q-017."

**Location:** `docs/roadmap.md:30-33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that row 66's trigger is the three-cycle artifact count and that Q-017 / the triage §2.2 correction record the usage log's under-counting; does not establish the size of the under-count.

Row 66: "Revisit if, over the first three dev cycles after install, multi-file merges still land without the RPI research/plan docs or pr-prep review artifacts they should carry (an artifact count, not the usage log)" and "Hook-based usage counts are not cited: they under-count silently (Q-017, triage 2026-09-17 §2.2 correction)". The triage: "has a history of silent under-counting" (`docs/working/triage-2026-09-17-backlog.md:171`).

**Evidence:** `docs/decisions/log.md:89`, `docs/working/triage-2026-09-17-backlog.md:171`

---

## Claim 9: "A8 post-restructure token measurement. Motive: the user deferred big compute until code and prompts settle; it validates code-review lever #3."

**Location:** `docs/roadmap.md:34-36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the project memory and log row 35's references to A8; does not establish that the code-review SKILL has settled.

Memory `run-a8-measurement-after-settling.md`: "the post-restructure measurement of code-review lever #3 ... should be run — but only after the code/prompt changes in /workspace are fully settled". Row 35: "revisit at the A8 post-restructure measurement."

**Evidence:** `docs/decisions/log.md:55`, `~/.claude/projects/-workspace/memory/run-a8-measurement-after-settling.md`

---

## Claim 10: "Q-079 — canon-instance script and proposal filter. Signal: the review canon grows only by hand (Q-072)."

**Location:** `docs/roadmap.md:42-43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers Q-079's content and Q-072's finding that no review feeds the ledger; does not establish the ledger's full edit history.

Q-079: "Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance". Q-072: "`docs/working/canon-issue-ledger.md` hasn't changed since 2026-08-18 ... 112 September review artifacts ... none feed back into it."

**Evidence:** `docs/working/questions.md` (Q-079), `docs/working/questions-archive.md:1446` (Q-072)

---

## Claim 11: "Signal: Q-074, 1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26."

**Location:** `docs/roadmap.md:44-45`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-074's figures and reopen condition; does not establish the current entry count.

Q-074: "has gained 1 entry across about 128 `fix` commits ... If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment". The figures match; the reopen is conditional (fewer than 5 new entries by that date), not dated unconditionally.

**Evidence:** `docs/working/questions.md` (Q-074)

---

## Claim 12: "Narrow code-review's "default whenever a PR is prepared" description ... (override log, deferred from log row 66's review)" and "Finish skill-format-audit F1: drop `when:` repo-wide and from `divergent-design-router.bats`. Signal: override log, deferred from log row 66's review."

**Location:** `docs/roadmap.md:46-49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two `Deferred` override-log rows on `feat/workflow-router-skills`; does not establish that F1 is the audit's own label for the `when:` item (not re-read).

Override log: "`skills/code-review/SKILL.md` description still says "default whenever a PR is prepared or evaluated", overlapping pr-prep ... | Deferred | ... Candidate for the first dev cycle." and "`test/skills/divergent-design-router.bats` still requires `when:`/`trigger` ... | Deferred | ... finishing skill-format-audit F1 repo-wide is a separate change."

**Evidence:** `docs/reviews/override-log.md` (last 15 rows)

---

## Claim 13: "merging the row-66 branch hit add/add conflicts on `code-fact-check-report-r*.md` and `*-review-<date>.md`, which are per-run names shared by every branch reviewed the same day."

**Location:** `docs/roadmap.md:50-52`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers file presence at the merge base and both parents of merge 33fdfd3 for `code-fact-check-report-r{1,2,3}.md` and `security-review-2026-09-29.md`; does not reconstruct git's conflict output.

Merge 33fdfd3's message: "Review artifacts that share canonical names with fix/agents-md-no-imports keep main's copy; this branch's copies are kept under -routers-<sha> names." `security-review-2026-09-29.md` is absent at the merge base ec297d4 and present on both parents: add/add. But `code-fact-check-report-r1.md`, `-r2.md` and `-r3.md` all already exist at ec297d4 (`git cat-file -e ec297d4:docs/reviews/code-fact-check-report-r2.md` succeeds), so those were both-modified conflicts, not add/add. The collision point stands; the conflict type is right only for the dated files.

**Evidence:** `git log -1 33fdfd3`, `git cat-file -e` probes at ec297d4, 33fdfd3^1, 33fdfd3^2

---

## Claim 14: "AGENTS.md names workflows by filename, not `@` import; guard test (log row 65, merge c9a370a). Removes ~89K tokens from every session and subagent in this repo."

**Location:** `docs/roadmap.md:58-59`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge hash, row number and the chars/4 size of the nine imported workflow files at c9a370a's first parent; does not establish Claude Code's import behaviour (recorded as observed in the override log's row-65 entry).

`git show -s c9a370a`: "merge: AGENTS.md names workflows by filename, not @-import (decision log 65)", first-parent on main. The nine `@./workflows/*.md` files imported by AGENTS.md at ec297d4 total 358,414 bytes; / 4 = 89,603 (paraphrased — no quote available because the figure is a sum over nine `git show | wc -c` outputs).

**Evidence:** `docs/decisions/log.md:88`, `git show ec297d4:AGENTS.md`

---

## Claim 15: "A router skill for every workflow except review-fix-loop (log row 66, merge 4225753)."

**Location:** `docs/roadmap.md:60`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge subject and row number; does not re-verify the router set.

`git show -s 4225753`: "merge: a router skill for every workflow (decision log 66)", first-parent on main (the current main tip).

**Evidence:** `docs/decisions/log.md:89`, `git log --first-parent main`

---

## Claim 16: Decision tree row 12: "Maintenance or planning pass over the repo ... | `dev-cycle` skill | ... The outer loop over rows 6/9 ... User-started, no timer. Output is triage in `docs/working/questions.md`."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that rows 6 and 9 are RPI and pr-prep and that the skill says user-started and triage output; does not establish routing behaviour at runtime.

Row 6 activates `research-plan-implement.md`, row 9 `pr-prep.md` (`global-instructions/CLAUDE.md:26,29`). The skill: "It runs when the user starts it; there is no timer." (`skills/dev-cycle/SKILL.md:14`) and "only decisions that need the user become `you: judgment` entries in `docs/working/questions.md`" (`:17-18`).

**Evidence:** `global-instructions/CLAUDE.md:26-32`, `skills/dev-cycle/SKILL.md:14-19`

---

## Claim 17: "`dev-cycle` ... Workflow-shaped (seven ordered steps, triage output) but user-started and single-session"

**Location:** `guides/skill-creation.md:137`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step count in `skills/dev-cycle/SKILL.md`; does not assess the "Adequate" rating.

The skill has eight numbered steps, `### 0. Digest` through `### 7. Close` (`skills/dev-cycle/SKILL.md:26,92`). "Seven" counts only steps 1-7 and leaves out the digest.

**Evidence:** `skills/dev-cycle/SKILL.md:26-95`

---

## Claim 18: "Everything that needs no judgment lives here, because this repo's evidence is that steps only prose asks for do not run (scripts/questions.sh header; Q-074)."

**Location:** `scripts/dev-cycle.sh:6-8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both references exist and say this; does not establish that every no-judgment step is in the script (e.g. `questions.sh archive` stays in skill prose by design).

See Claim 3: `scripts/questions.sh:5-8` "an unenforced instruction does not execute"; Q-074 is the failure-pattern trigger entry.

**Evidence:** `scripts/questions.sh:5-8`, `docs/working/questions.md` (Q-074)

---

## Claim 19a: "--since ... Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago."

**Location:** `scripts/dev-cycle.sh:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which date is chosen as SINCE; does not cover how git interprets that date (Claim 19b).

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

Executed: bats test 3 passes (prints "Window: since 2026-02-10" with records dated 01-05 and 02-10); a mutation picking the first record fails it; the worktree run (no cycle records) prints "Window: since 2026-09-15" on 2026-09-29.
Command: `timeout 120 bats test/dev-cycle.bats`, cwd `/workspace/.claude/wt-devcycle`, exit 0, 2026-09-29T01:59:51-07:00; `timeout 60 bash scripts/dev-cycle.sh`, same cwd, exit 0, 2026-09-29T01:57:27-07:00.

**Evidence:** `scripts/dev-cycle.sh:44-53`, `docs/reviews/execution-logs/r1-devcycle-bats.txt`, `docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`, `docs/reviews/execution-logs/r1-devcycle-mutations.txt`

---

## Claim 19b: "--since   start of the cycle window." (and the digest line "Window: since $SINCE")

**Location:** `scripts/dev-cycle.sh:12`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the merge list and commit count interpret a bare YYYY-MM-DD; does not establish how often a real cycle would miss or double-count a merge.

The date is passed straight to git:

```bash
# scripts/dev-cycle.sh:61-62
merges="$(git log "$MAIN" --first-parent --merges --since="$SINCE" --format='%h %ad %s' --date=short)"
commits="$(git rev-list --count --since="$SINCE" "$MAIN")"
```

git reads a bare date as that date at the current time of day, not at 00:00. Probe: a throwaway repo with a merge committed 2026-09-27T00:30 and `docs/working/cycles/cycle-2026-09-27.md`, run at 01:58 on 2026-09-29, prints "Window: since 2026-09-27" and "0 merge(s), 0 commit(s)"; `git log --merges --since="2026-09-27 00:00"` lists that merge. So the window starts at SINCE plus the run's clock time. Merges made on the cycle-record day before that clock time drop out of the next cycle's activity list, spot-check sample and count. Merges made after it are counted again, since the previous cycle already saw them.
Command: `timeout 30 bash /workspace/.claude/wt-devcycle/scripts/dev-cycle.sh`, cwd `$SCRATCHPAD/t3`, exit 0, 2026-09-29T01:58:02-07:00 (exit re-captured at 01:58:10).

**Evidence:** `scripts/dev-cycle.sh:12`, `scripts/dev-cycle.sh:57-62`, `docs/reviews/execution-logs/r1-devcycle-since-time-of-day.txt`

---

## Claim 20: "--sample  how many merges to sample for the spot-check audit (default 2)."

**Location:** `scripts/dev-cycle.sh:14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default and its use in section 4; does not establish behaviour when N exceeds the merge count (shuf prints all).

`SAMPLE=2` (`scripts/dev-cycle.sh:23`), used as `shuf -n "$SAMPLE"` (`:121`).

**Evidence:** `scripts/dev-cycle.sh:23`, `scripts/dev-cycle.sh:121`

---

## Claim 21a: "Acts on the git repo of $PWD (like questions.sh)"

**Location:** `scripts/dev-cycle.sh:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that all reads resolve against `git rev-parse --show-toplevel` of the caller's cwd, including the questions.sh call; does not cover non-git directories (the script exits 1 there).

```bash
# scripts/dev-cycle.sh:36-37
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
```

Every bats test runs the repo's script from a throwaway repo and sees that repo's docs (tests 2, 3, 5 pass on fixtures that exist only there); questions.sh resolves "the docs/working/ of the git repo you run it FROM" (`scripts/questions.sh:36-37`).

**Evidence:** `scripts/dev-cycle.sh:36-37`, `scripts/questions.sh:36-40`, `docs/reviews/execution-logs/r1-devcycle-bats.txt`

---

## Claim 21b: "so the installed copy at ~/.claude/scripts/dev-cycle.sh serves any project."

**Location:** `scripts/dev-cycle.sh:16-17`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a local repo whose only branch is `master` and has no `origin/HEAD`; does not test other portability limits (`date -d` and `shuf` are GNU tools).

With no `origin/HEAD` the branch falls back to the literal `main` (`:41-42`); in a repo without a `main` branch, `git log main` fails under `set -e`. Probe: a fresh `git init -b master` repo with one commit gives "fatal: ambiguous argument 'main': unknown revision" and exit 128. The script copy itself installs (`devcontainer-config/install.sh:135` stages `scripts`). It serves repos that have `main` or an `origin/HEAD`, not any project.
Command: `timeout 30 bash /workspace/.claude/wt-devcycle/scripts/dev-cycle.sh`, cwd `$SCRATCHPAD/t2`, exit 128, 2026-09-29T01:58:02-07:00.

**Evidence:** `scripts/dev-cycle.sh:40-42`, `scripts/dev-cycle.sh:61`, `devcontainer-config/install.sh:135`, `docs/reviews/execution-logs/r1-devcycle-master-only.txt`

---

## Claim 22: "Read-only: prints to stdout and writes nothing."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working tree and git state after a full run in the worktree (including the `questions.sh open` call) and the absence of any write, redirect-to-file or mutating git command in the script; does not cover git's own incidental housekeeping (none observed).

The only commands are `git rev-parse/symbolic-ref/log/rev-list`, `awk`, `grep`, `shuf`, `sed` and `bash "$QS" open` (paraphrased — no quote available because the claim is an absence across the whole 135-line file); `cmd_open` only reads (`scripts/questions.sh:408-414`). `git status --porcelain` before and after the worktree run differ only by the output file this report redirected to.
Command: `timeout 60 bash scripts/dev-cycle.sh > docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`, cwd `/workspace/.claude/wt-devcycle`, exit 0, 2026-09-29T01:57:27-07:00.

**Evidence:** `scripts/dev-cycle.sh:20-135`, `scripts/questions.sh:408-414`, `docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`

---

## Claim 23: "No origin/HEAD (a local-only repo) is normal; fall back to main."

**Location:** `scripts/dev-cycle.sh:40-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback when origin/HEAD is absent (the pipeline's failure is absorbed by `|| true`) and the strip of `origin/` when present; does not cover a missing `main` (Claim 21b).

```bash
# scripts/dev-cycle.sh:41-42
MAIN="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
[[ -n "$MAIN" ]] || MAIN=main
```

All six bats tests run in origin-less repos and pass; the worktree run (origin/HEAD absent here too) prints "on `main` at 4225753".

**Evidence:** `scripts/dev-cycle.sh:41-42`, `docs/reviews/execution-logs/r1-devcycle-bats.txt`, `docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`

---

## Claim 24: questions.sh lookup: `$SCRIPT_DIR/questions.sh`, else `~/.claude/scripts/questions.sh`

**Location:** `scripts/dev-cycle.sh:98-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lookup order; does not establish behaviour when the sibling copy exists but is not executable (it then falls to the HOME copy even though it is run via `bash`).

```bash
# scripts/dev-cycle.sh:98-100
QS="$SCRIPT_DIR/questions.sh"
[[ -x "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
if [[ -f docs/working/questions.md && -f "$QS" ]]; then
```

`scripts/questions.sh` is mode `-rwxr-xr-x`.

**Evidence:** `scripts/dev-cycle.sh:38`, `scripts/dev-cycle.sh:98-100`

---

## Claim 25: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain the word "trigger"."

**Location:** `scripts/dev-cycle.sh:101-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current `cmd_open` format and the column split for the routes in the grammar; does not cover a slug containing two consecutive spaces (the grammar's slugs are kebab-case).

```bash
# scripts/questions.sh:411-413
        | while IFS=$'\t' read -r id route _ _ slug _; do
            printf '%s  %-14s  %s\n' "$id" "$route" "$slug"
        done
```

The worktree run lists exactly the two `deferred` and two `trigger` entries and "Open by route: agent=7, deferred=2, trigger=2, you: terminal=1", matching `questions.sh open`; bats test 5 (slug "a-trigger-in-the-slug" on an `agent` entry) passes, and a mutation to `grep -E 'trigger|deferred'` fails it.

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:103-111`, `docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`, `docs/reviews/execution-logs/r1-devcycle-mutations.txt`

---

## Claim 26: "Seeded by the date so a rerun on the same day audits the same merges."

**Location:** `scripts/dev-cycle.sh:120-121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reruns with the same merge list and `--sample`; does not hold if a merge lands between the runs or `--since` differs (the input to shuf changes).

```bash
# scripts/dev-cycle.sh:121
  printf '%s\n' "$merges" | shuf -n "$SAMPLE" --random-source=<(yes "$TODAY") | sed 's/^/- /'
```

Bats test 4 passes; with `--random-source` removed it failed in 6 of 8 trials.
Command: see `r1-devcycle-mutations.txt` (M1 and "RERUN 2"), cwd `$SCRATCHPAD/mut2`, 2026-09-29T02:00.

**Evidence:** `scripts/dev-cycle.sh:119-124`, `docs/reviews/execution-logs/r1-devcycle-mutations.txt`

---

## Claim 27: "Every step ends with a line in the cycle record ... entry grammar in the global instructions ("Running questions document")."

**Location:** `skills/dev-cycle/SKILL.md:18-19`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named section exists and defines the entry grammar; does not assess the skill's own compliance.

`global-instructions/CLAUDE.md:234`: "### Running questions document", which holds the `### Q-NNN · <short-slug>` grammar.

**Evidence:** `global-instructions/CLAUDE.md:234`

---

## Claim 28a: "It is read-only and gives the window (since the last cycle record), merges in it, ... the watched questions, the spot-check sample and the roadmap's Next section."

**Location:** `skills/dev-cycle/SKILL.md:28-31`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1, 3, 4, 5 of a real run in the worktree; does not cover revisit triggers (Claim 28b).

The count covers every merge in the window, but the listing stops at 30:

```bash
# scripts/dev-cycle.sh:65
[[ -n "$merges" ]] && { echo; echo '```'; printf '%s\n' "$merges" | head -30; echo '```'; }
```

The worktree run reports "63 merge(s)" and lists 30; the spot-check sample drew 86865d4 and 702b72b, which are among the 33 merges not listed. Precise version: "the merge count and the 30 newest merges".

**Evidence:** `scripts/dev-cycle.sh:61-65`, `docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`

---

## Claim 28b: "... every revisit trigger ..."

**Location:** `skills/dev-cycle/SKILL.md:30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the log-row extraction against the current `docs/decisions/log.md`; record-level extraction is complete (all 11 `## Revisit triggers` sections print, and no record uses another heading).

For log rows the script prints the first "revisit" substring in the row, not the trigger:

```bash
# scripts/dev-cycle.sh:86-90
    printf '%s\n' "$rows" | while IFS= read -r row; do
      n="$(printf '%s' "$row" | awk -F'|' '{ gsub(/ /, "", $2); print $2 }')"
      text="$(printf '%s' "$row" | grep -oiE 'revisit[^|]*' | head -1 | cut -c1-400)"
      echo "- row $n: $text"
    done
```

Row 67's Decision cell mentions "revisit-trigger verdicts" before its trigger, so the worktree digest prints "row 67: revisit-trigger verdicts (fired / not fired / cannot tell, with evidence) → watched questions → ..." Row 67's actual trigger ("Revisit if three cycles in a row file nothing ... or if the gap between cycles passes a month twice") appears nowhere in the digest. The agent in step 2 is told to verdict "every trigger in the digest", so this trigger goes unverdicted. Any row whose earlier text contains "revisit" fails the same way.

**Evidence:** `scripts/dev-cycle.sh:80-92`, `docs/decisions/log.md:90`, `docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`

---

## Claim 29: "If the repo has no `docs/working/questions.md`, run `questions.sh init` first."

**Location:** `skills/dev-cycle/SKILL.md:31-32`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `init` exists and creates missing files; does not run it.

`scripts/questions.sh:34`: "init       create empty live/archive files if absent"; dispatched at `:447` (`init)    cmd_init ;;`).

**Evidence:** `scripts/questions.sh:34`, `scripts/questions.sh:417-447`

---

## Claim 30: "Start the project's full check ... (in claude-workflows: `scripts/health-check.sh`) ... triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)."

**Location:** `skills/dev-cycle/SKILL.md:36-39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the script exists and that pr-prep 5a defines those three classes; does not run the health check (excluded by the brief).

`scripts/health-check.sh` exists. `workflows/pr-prep.md` step 5a's table lists "Caused by this branch", "Pre-existing on main" and "Flaky / infra / environmental", and in claude-workflows "the gate is `scripts/health-check.sh`" (paraphrased — no quote available because the three classes are rows of a table in pr-prep §5a).

**Evidence:** `workflows/pr-prep.md` §5a, `scripts/health-check.sh`

---

## Claim 31: "`questions.sh archive` then `questions.sh index`, so answered entries leave the live file."

**Location:** `skills/dev-cycle/SKILL.md:40`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both subcommands exist and that `archive` moves ANSWERED entries; does not establish that the separate `index` step is needed (archive already reindexes).

`scripts/questions.sh:31`: "archive    move ANSWERED entries to the archive, reindex"; `:30`: "index      regenerate the index tables in place".

**Evidence:** `scripts/questions.sh:29-34`, `scripts/questions.sh:447-452`

---

## Claim 32: "in claude-workflows, `scripts/archive-working-docs.sh -n` lists what would move."

**Location:** `skills/dev-cycle/SKILL.md:43-44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `-n` flag; does not establish that the script can archive per task as the next sentence implies (it moves every non-permanent, uncited file in one go, with a run-id prefix).

```
# scripts/archive-working-docs.sh:21-22
# Options:
#   -n, --dry-run   Show what would be moved without moving anything
```

**Evidence:** `scripts/archive-working-docs.sh:1-33`

---

## Claim 33: "Use `code-fact-check` at k=1 for a merge with many claims."

**Location:** `skills/dev-cycle/SKILL.md:66-67`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that "k" is the repo's replicate-count term and that k=1 is a defined configuration; does not establish that k=1 suffices for an audit.

`skills/code-review/SKILL.md:20`: "Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031 ...)". A standalone code-fact-check run is a single replicate.

**Evidence:** `skills/code-review/SKILL.md:20`

---

## Claim 34: "Update `docs/roadmap.md` (create it from its own template if missing)"

**Location:** `skills/dev-cycle/SKILL.md:80`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the presence of a roadmap template file; does not assess whether the step's bullet list is enough to build one.

No template file exists: `templates/` holds only `gitattributes-snippet.txt`, and `rg -il roadmap templates` finds nothing (paraphrased — no quote available because the claim is an absence). The only structure is the step's own Now / Next / Ideas / Done bullets (`skills/dev-cycle/SKILL.md:82-85`) and this repo's `docs/roadmap.md`, which is not installed with the skill. Precise version: "create it with the four sections below".

**Evidence:** `skills/dev-cycle/SKILL.md:80-85`, `templates/`

---

## Claim 35: "Each test builds a throwaway git repo under $BATS_TEST_TMPDIR, so nothing reads or writes this repo's own docs/." and "HOME points at the temp dir so the ~/.claude/scripts fallback can't reach the real installed questions.sh."

**Location:** `test/dev-cycle.bats:4-5`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers setup's cwd, HOME and git config isolation and the script's toplevel resolution; does not cover `$SCRIPT_DIR/questions.sh`, which is this repo's real script (it runs against the temp repo's docs, so the claim still holds).

```bash
# test/dev-cycle.bats:12-21
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    ...
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    R="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$R"
    cd "$R" || return 1
```

(excerpt ends :21; enclosing setup() continues to :30 — read.) After the bats run the worktree's `git status --porcelain` shows no tracked change.
Command: `timeout 120 bats test/dev-cycle.bats`, cwd `/workspace/.claude/wt-devcycle`, exit 0, 2026-09-29T01:59:51-07:00.

**Evidence:** `test/dev-cycle.bats:9-30`, `docs/reviews/execution-logs/r1-devcycle-bats.txt`

---

## Claim 36: The six tests each pin the behaviour they name (per-test names, `test/dev-cycle.bats:32-109`)

**Location:** `test/dev-cycle.bats:32-109`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nine mutations of a scratch copy of the script; does not cover the window's time-of-day semantics (Claim 19b) or the log-row wrong-clause case (Claim 28b), which no test exercises.

Each mutation failed the test that names it: M2 unbounded revisit section → test 2; M3 oldest record → test 3; M4 grep route → test 5; M5 no `--since` validation → test 6; M6 unknown option accepted → test 6; M7 log rows dropped → test 2; M8 roadmap header renamed → test 1; M9 route counts not printed → test 5. The first-run M3 result and the first-run M9 (label-only) are invalid; see the log's RERUN sections. Two limits: test 4 catches an unseeded shuffle only by chance (6 of 8 trials; with 3 merges, an unseeded run matches by chance 1 time in 6), and test 3 checks only the printed "Window:" line, so a window that git reads differently (Claim 19b) passes it.
Command: `bash $SCRATCHPAD/mutate.txt $SCRATCHPAD $W` plus RERUN 2, cwd `$SCRATCHPAD`, exit 0, 2026-09-29T02:00:03-07:00 onward; probe saved as `docs/reviews/execution-logs/r1-devcycle-mutate-probe.txt`.

**Evidence:** `test/dev-cycle.bats:32-109`, `docs/reviews/execution-logs/r1-devcycle-mutations.txt`, `docs/reviews/execution-logs/r1-devcycle-mutate-probe.txt`

---

## Claim 37: Commit 1f8ed13: "11 decision records and 7 log rows carry revisit triggers that nothing read"

**Location:** commit 1f8ed13 (message body, lines 2-3)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Same evidence as Claim 2; does not re-count at the commit's own date.

The counts match under a case-insensitive count; codebase-onboarding step 10 already read record triggers (`workflows/codebase-onboarding.md:309`), so "nothing read" overstates it (see Claim 2).

**Evidence:** `git log -1 1f8ed13`, `workflows/codebase-onboarding.md:309`

---

## Claim 38a: Commit 1f8ed13: "every revisit trigger (records and log rows) ... Works in any repo (acts on $PWD's repo; falls back to main without origin/HEAD)."

**Location:** commit 1f8ed13 (message body, `scripts/dev-cycle.sh` bullet)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "every revisit trigger" and "any repo" parts; the $PWD and fallback mechanisms themselves are Verified (Claims 21a, 23).

The digest shows row 67's Decision text in place of its trigger (Claim 28b), and it exits 128 in a repo without `main` or `origin/HEAD` (Claim 21b). Commands as in those claims.

**Evidence:** `docs/reviews/execution-logs/r1-devcycle-worktree-run.txt`, `docs/reviews/execution-logs/r1-devcycle-master-only.txt`

---

## Claim 38b: Commit 1f8ed13: "Output is triage in questions.md; only you: judgment entries reach the user." / "test/dev-cycle.bats: six hermetic tests in throwaway repos."

**Location:** commit 1f8ed13 (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's routing instructions and the bats file; does not assess how many entries a real cycle files.

The test half holds (6 `@test` blocks, hermetic per Claim 35). But the skill also sends one entry of another kind to the user: "put the list in one `you: terminal` entry rather than deleting" (`skills/dev-cycle/SKILL.md:42`). Precise version: "only `you: judgment` entries (and one batched `you: terminal` paste) reach the user". Row 67 frames it as spending attention, which the global route definitions support.

**Evidence:** `skills/dev-cycle/SKILL.md:41-42`, `test/dev-cycle.bats:32-109`

---

## Claim 39: Commit 89a3d3b: "dev-cycle description <=250 chars with a precedence clause; no when:" / "README: 34 skills, dev-cycle named; skill-creation inventory row" / "Roadmap: rows 65/66 to Done; router-uptake measure counts artifacts, not the usage log; deferred review items added to Ideas with signals" / "Row 67: date the revisit-trigger counts"

**Location:** commit 89a3d3b (message body)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against HEAD; does not re-verify the Ideas items' facts (Claims 11-13).

The description is 242 characters: "Run one maintenance cycle: ... Not for landing one change (pr-prep). Triggers: ..." (`skills/dev-cycle/SKILL.md:4`); `grep -c '^when:'` gives 0. README says "34 Claude Code skills" and names `dev-cycle` (`README.md:182`); the inventory row is at `guides/skill-creation.md:137`. Done lists rows 65 and 66 (`docs/roadmap.md:58-60`); Next item 4 says "an artifact count, not the usage log" (`:32`); the Ideas at `:46-52` carry override-log signals. Row 67 says "As of 2026-09-28, 11 decision records ..." (`docs/decisions/log.md:90`).

**Evidence:** `skills/dev-cycle/SKILL.md:1-5`, `README.md:182`, `guides/skill-creation.md:137`, `docs/roadmap.md:30-60`, `docs/decisions/log.md:90`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`docs/roadmap.md:25`): Q-092 does not wait on a Bash sandbox (agent route, depends on Q-082); only Q-098 does.
- **Claim 19b** (`scripts/dev-cycle.sh:12`): `--since=YYYY-MM-DD` starts the window at the run's clock time on that date, not at its start; merges earlier that day drop out and later ones double-count (e.g. pass `"$SINCE 00:00"`).
- **Claim 21b** (`scripts/dev-cycle.sh:16-17`): "serves any project" — exits 128 in a repo with no `main` and no `origin/HEAD`.
- **Claim 28b** (`skills/dev-cycle/SKILL.md:30`): "every revisit trigger" — log-row extraction prints the first "revisit" substring; row 67's own trigger is replaced by its Decision text.
- **Claim 38a** (commit 1f8ed13): "every revisit trigger (records and log rows)" and "Works in any repo" — same two defects (immutable; message only).

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`docs/decisions/log.md:90`): 6 rows contain "Revisit" as quoted, 7 case-insensitively; codebase-onboarding step 10 already read record triggers.
- **Claim 7** (`docs/roadmap.md:27-29`): host tools carry `Live-verified: no`; they are not "verified by" it.
- **Claim 11** (`docs/roadmap.md:44-45`): Q-074 reopens on 2026-10-26 only if fewer than 5 new entries have landed.
- **Claim 13** (`docs/roadmap.md:50-52`): `code-fact-check-report-r*.md` existed at the merge base, so those were both-modified conflicts; only the dated files were add/add.
- **Claim 17** (`guides/skill-creation.md:137`): the skill has eight steps (0-7), not seven.
- **Claim 28a** (`skills/dev-cycle/SKILL.md:28-31`): the digest counts every merge but lists only 30.
- **Claim 34** (`skills/dev-cycle/SKILL.md:80`): no roadmap template exists; the four bullets are the only structure.
- **Claim 36** (`test/dev-cycle.bats`): all mutations caught, but test 4 catches an unseeded shuffle only by chance and test 3 does not reach git's reading of the window.
- **Claim 37** (commit 1f8ed13): as Claim 2.
- **Claim 38b** (commit 1f8ed13): the skill also files one `you: terminal` entry for the user.

### Unverifiable
- None.

---

## Goal-Alignment Note

- **Answered:** Every claim the brief listed: script header vs behaviour (read-only, $PWD, default window, main fallback, same-day sample, questions.sh lookup), every command and path in the skill, each roadmap line (Q-IDs, both merge hashes, row numbers, ~89K, 1-in-~128), row 67's counts against ec297d4, decision-tree row 12, the README and guide lines, the bats header plus nine mutations of a scratch copy, and both commit messages. Behavioural and test claims were executed. Headline defects: the `--since` time-of-day window (19b), the log-row wrong-clause extraction (28b), the master-only crash (21b), and Q-092's misattributed dependency (6b).
- **Out of scope:** did not run `scripts/health-check.sh` or the full suite (brief); did not judge code quality or design. I did not verify portability beyond the master-only case (e.g. BSD `date`/`shuf`).
- **Escalate:** Claims 19b and 28b are behaviour bugs in the new script, and no test covers either; the orchestrator may want them as Must-fix/Must-address rather than comment fixes. Two first-run mutation results (M3, label-only M9) were invalid probe artifacts; the RERUN sections of `r1-devcycle-mutations.txt` hold the valid results.
