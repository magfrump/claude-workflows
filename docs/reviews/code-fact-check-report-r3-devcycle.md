Commit: 89a3d3b

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-devcycle`, branch `feat/dev-cycle`)
**Scope:** `git diff main...HEAD` (8 files: README.md, docs/decisions/log.md, docs/roadmap.md, global-instructions/CLAUDE.md, guides/skill-creation.md, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/dev-cycle.bats) plus commit messages 1f8ed13 and 89a3d3b. Replicate 3 of 3.
**Checked:** 2026-09-29
**Total claims checked:** 39
**Summary:** 25 verified, 7 mostly accurate, 0 stale, 7 incorrect, 0 unverifiable

Hallucination-pattern log read before checking; no claim matches a logged pattern (closest class: Claim 6b is a question-to-dependency association asserted without reading the entry, like the logged `dd-cross-model-sweep.py` consumer entry). Execution logs are under `docs/reviews/execution-logs/r3-devcycle-*.txt`; every probe ran in throwaway repos under the session scratchpad (`.../scratchpad/fc3/`) with `GIT_CONFIG_GLOBAL=/dev/null`, `LC_ALL=C`, under `timeout`, between 2026-09-29T01:57 and 02:02 -07:00, except one read-only run in the worktree (Claim 21/24 evidence) whose `git status --porcelain` was identical before and after.

---

## Claim 1: "`skills/` holds 34 Claude Code skills ... the `dev-cycle` skill (the outer maintenance loop; `docs/roadmap.md`)"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill count at HEAD (34 directories, 34 `SKILL.md`) and that `dev-cycle` exists and points at the roadmap; does not establish that every other skill named in the sentence still exists.

`ls -d skills/*/ | wc -l` and `ls skills/*/SKILL.md | wc -l` both give `34`; on `main` the directory count is `33` (paraphrased — no quote available because the evidence is a directory count, not a snippet). `skills/dev-cycle/SKILL.md:80` says "Update `docs/roadmap.md`".

**Evidence:** `README.md:182`, `skills/dev-cycle/SKILL.md:80`

---

## Claim 2: "As of 2026-09-28, 11 decision records with revisit triggers and 7 log rows with "Revisit" had nothing reading them."

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both counts at ec297d4 (the last main commit dated 2026-09-28); the 7 is case-insensitive (6 rows carry capital "Revisit", row 35 has only "revisit at the A8 ..."); does not establish the "nothing reading them" half beyond the absence of any script that did so before this branch.

At `ec297d4` ("2026-09-28 22:30:09 ... merge: auto-approve hook approves only safe command shapes"), the records containing `^## Revisit triggers` are 014, 015, 016, 017, 021, 028, 030, 031, 035, 036, 037 — 11 files. Log rows matching `grep -E '^\| [0-9]+ \|' | grep -i revisit` are 35, 53, 57, 58, 60, 62, 63 — 7 rows; row 35's clause is `revisit at the A8 post-restructure measurement` (paraphrased — no quote available because the counts come from a `git show ec297d4:... | grep` pipeline over many files).

**Evidence:** `git show ec297d4:docs/decisions/log.md`, `docs/decisions/014-secure-tool-guidance-layers.md` .. `docs/decisions/037-bare-host-copy-install.md` at ec297d4

---

## Claim 3: "Mechanical parts are a script because steps only prose asks for do not run (Q-074; the override log's nine unwritten runs)."

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both cited sources say what the row attributes to them; does not independently recount the override-log history.

`docs/working/questions.md:70`: "`docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only." `scripts/questions.sh:7-8`: "the code-review override log went unwritten for nine runs, both because only prose asked for them."

**Evidence:** `docs/working/questions.md:67-70`, `scripts/questions.sh:5-11`

---

## Claim 4: "Steps: digest → health and cleanup → revisit-trigger verdicts ... → cycle record in `docs/working/cycles/cycle-YYYY-MM-DD.md`. The user starts it; there is no timer. ... The global decision tree gains row 12."

**Location:** `docs/decisions/log.md:90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the row, the skill's step headings, the script's cycle-record glob and the added decision-tree row; does not establish that any cycle has run.

The skill's headings run `### 0. Digest` through `### 7. Close` in the same order (`skills/dev-cycle/SKILL.md:26-92`), step 7 writes "`docs/working/cycles/cycle-YYYY-MM-DD.md`" (`:92`), the intro says "It runs when the user starts it; there is no timer." (`:14`), and the script globs `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:46`). `global-instructions/CLAUDE.md:32` begins `| 12 | **Maintenance or planning pass over the repo**`.

**Evidence:** `skills/dev-cycle/SKILL.md:14`, `skills/dev-cycle/SKILL.md:26-92`, `scripts/dev-cycle.sh:46`, `global-instructions/CLAUDE.md:32`

---

## Claim 5: "Q-075 — evidence that the self-improvement loop is safe to resume. Motive: Q-068 was answered "resume" on condition of this evidence ... First step: list every path, config, hook, credential and git ref `scripts/self-improvement.sh` can write outside its working docs."

**Location:** `docs/roadmap.md:20-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-068's answer, Q-075's content and the script's existence; does not establish the "dormant since" or "idea generator" characterisations.

`docs/working/questions-archive.md:1370`: "**Answered 2026-09-27: [3] resume** ... So the loop stays dormant until that trust exists. The trust work is filed as Q-075". `docs/working/questions.md:77`: "list every path, config, hook, credential and git ref the loop can write outside its own working docs". `scripts/self-improvement.sh` exists (99191 bytes, executable).

**Evidence:** `docs/working/questions-archive.md:1367-1370`, `docs/working/questions.md:74-77`

---

## Claim 6a: "Q-088 — spike `sandbox.enableWeakerNestedSandbox` in cc-isolated. Motive: Q-098 (a global allow list) ... wait[s] on a Bash sandbox."

**Location:** `docs/roadmap.md:24-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-088's subject and Q-098's dependency on it; does not cover Q-092 (Claim 6b).

`docs/working/questions.md:165`: "Spike, per Q-081 [2]: can Claude Code's `sandbox.enableWeakerNestedSandbox` run Bash sandboxed inside cc-isolated". `docs/working/questions.md:141`: "Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088)."

**Evidence:** `docs/working/questions.md:138-141`, `docs/working/questions.md:162-165`

---

## Claim 6b: "... and Q-092 wait on a Bash sandbox."

**Location:** `docs/roadmap.md:25`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the full Q-092 entry at HEAD; does not establish whether Q-092 ought to wait on the sandbox.

Q-092 is not gated on a sandbox. Its body is "Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-approve-allowed-commands.sh`" and its interim is "**Interim:** the reader stays. It is redundant for `allow`, not harmful." (`docs/working/questions.md:156`, `:160`). The entry's route is `agent`, and neither the entry nor its `Read:` line mentions Q-088 or a sandbox (paraphrased — no quote available because the claim is about absence across the entry's lines 153-160). Only Q-098 waits on Q-088.

**Evidence:** `docs/working/questions.md:153-160`

---

## Claim 7: "Q-089 — host-tool trust category. Motive: `cc-push.sh` and the exit scan are verified by `Live-verified:`, which does not fit host-only tools (Q-083 [1])."

**Location:** `docs/roadmap.md:27-29`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-083's problem statement and Q-089's scope; does not establish the trust manifest's current contents.

Q-083 says the tools are *gated* by the trailer but cannot actually be live-verified: "host tools can't be live-probed, so every commit to them carries `Live-verified: no`" (`docs/working/questions-archive.md:1580`), and lists "`cc-push.sh`, and soon `cc-exit-scan.sh`". "Verified by `Live-verified:`" should read "gated by the `Live-verified:` trailer, which they can never satisfy". Q-089 (`docs/working/questions.md:174`) implements "Q-083 [1]: host-only tools ... get their own trust-manifest section", matching the first step.

**Evidence:** `docs/working/questions-archive.md:1576-1581`, `docs/working/questions.md:171-174`

---

## Claim 8: "Measure router uptake. Motive: log row 66's revisit trigger ... count multi-file merges that carry RPI research/plan docs and pr-prep review artifacts (an artifact count, not the usage log, which under-counts, Q-017)."

**Location:** `docs/roadmap.md:30-33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row 66's trigger wording and Q-017's under-count finding; does not establish that the counting method is feasible.

Row 66: "Revisit if, over the first three dev cycles after install, multi-file merges still land without the RPI research/plan docs or pr-prep review artifacts they should carry (an artifact count, not the usage log)" (`docs/decisions/log.md:89`). Q-017's answer: "an instrument with a known history of silent under-counting should not generate attention asks" (`docs/working/questions-archive.md:243-244`).

**Evidence:** `docs/decisions/log.md:89`, `docs/working/questions-archive.md:218-245`

---

## Claim 9: "A8 post-restructure token measurement. Motive: the user deferred big compute until code and prompts settle; it validates code-review lever #3."

**Location:** `docs/roadmap.md:34-36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the user-memory record cited as the roadmap's source; the memory file is outside the repo and is not a tracked artifact a reviewer can open.

The memory `run-a8-measurement-after-settling.md` says "the post-restructure measurement of code-review lever #3 ... **should be run — but only after the code/prompt changes in /workspace are fully settled**. Same holds for any further large-compute experiments." `docs/working/questions.md:53` also cites it: "Memory [[run-a8-measurement-after-settling]] says no big compute before the A8 measurement."

**Evidence:** `/home/node/.claude/projects/-workspace/memory/run-a8-measurement-after-settling.md:11`, `docs/working/questions.md:53`

---

## Claim 10: "Q-079 — canon-instance script and proposal filter. Signal: the review canon grows only by hand (Q-072)." / "Signal: Q-074, 1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26."

**Location:** `docs/roadmap.md:42-45`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what Q-079, Q-072 and Q-074 say; does not recount fix commits or failure-pattern entries independently.

`docs/working/questions.md:86`: "Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the higher-level heuristic that decides which candidates get *proposed*." `docs/working/questions.md:70`: "gained 1 entry across about 128 `fix` commits ... If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment".

**Evidence:** `docs/working/questions.md:70`, `docs/working/questions.md:86`, `docs/working/questions-archive.md:1449`

---

## Claim 11: "Narrow code-review's "default whenever a PR is prepared" description. Signal: it overlaps the pr-prep router (override log, deferred from log row 66's review)." / "Finish skill-format-audit F1: drop `when:` repo-wide and from `divergent-design-router.bats`."

**Location:** `docs/roadmap.md:46-49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two override-log rows and the current code state they describe; does not establish that the changes are desirable.

`docs/reviews/override-log.md:161`: "`skills/code-review/SKILL.md` description still says "default whenever a PR is prepared or evaluated", overlapping pr-prep ... Deferred". `:164`: "`test/skills/divergent-design-router.bats` still requires `when:`/`trigger` ... finishing skill-format-audit F1 repo-wide is a separate change." Current code agrees: `skills/code-review/SKILL.md:8` "default whenever a PR is prepared or evaluated." and `test/skills/divergent-design-router.bats:51` `grep -qE '^(trigger|when):'`.

**Evidence:** `docs/reviews/override-log.md:161`, `docs/reviews/override-log.md:164`, `skills/code-review/SKILL.md:8`, `test/skills/divergent-design-router.bats:45-51`

---

## Claim 12: "Review artifacts collide across branches. Signal: merging the row-66 branch hit add/add conflicts on `code-fact-check-report-r*.md` and `*-review-<date>.md`, which are per-run names shared by every branch reviewed the same day."

**Location:** `docs/roadmap.md:50-52`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a re-run of the merge 33fdfd3 recorded (parents 028105b and c9a370a) with `git merge-tree`; does not establish the conflicts seen at other merges.

`git merge-tree --write-tree --name-only 028105b c9a370a` reports "CONFLICT (add/add): Merge conflict in docs/reviews/performance-review-2026-09-29.md" and the same for `security-review-2026-09-29.md`, but for the fact-check reports it reports "CONFLICT (content): Merge conflict in docs/reviews/code-fact-check-report-r1.md" (and r2, r3) (paraphrased — no quote available because the output is from a re-run merge, not a file). So the `code-fact-check-report-r*.md` conflicts were content conflicts on files that already existed on both sides, and those names carry no date: they collide across branches on any day, not only the same day. The underlying signal (per-run names shared across branches) holds; 33fdfd3's message confirms it ("Review artifacts that share canonical names with fix/agents-md-no-imports keep main's copy").

**Evidence:** `git log -1 --format=%B 33fdfd3`, `git merge-tree --write-tree --name-only 028105b c9a370a`

---

## Claim 13: "AGENTS.md names workflows by filename ... (log row 65, merge c9a370a). Removes ~89K tokens from every session and subagent in this repo." / "A router skill for every workflow except review-fix-loop (log row 66, merge 4225753)."

**Location:** `docs/roadmap.md:58-60`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge hashes, subjects and the token arithmetic over the nine imported workflows at ec297d4; does not establish that Claude Code expanded every import in every session.

`git log -1 c9a370a`: "merge: AGENTS.md names workflows by filename, not @-import (decision log 65)"; `git log -1 4225753`: "merge: a router skill for every workflow (decision log 66)". At `ec297d4`, AGENTS.md held 9 `@./workflows/*.md` imports whose files total 358414 bytes, 89603.5 at chars/4 (paraphrased — no quote available because the figure is a `git show | wc -c` sum over nine files). `workflows/review-fix-loop.md:3` carries `router: "none — runs only inside pr-prep step 3, ..."`.

**Evidence:** `docs/decisions/log.md:88-89`, `git show ec297d4:AGENTS.md`, `workflows/review-fix-loop.md:3`

---

## Claim 14: "| 12 | **Maintenance or planning pass over the repo** ... | `dev-cycle` skill | ... The outer loop over rows 6/9 ... User-started, no timer. Output is triage in `docs/working/questions.md`."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that rows 6 and 9 are RPI and pr-prep and that the skill says the same about trigger and output; does not establish first-match interaction with rows 1-11.

Row 6 is `research-plan-implement.md` and row 9 is `pr-prep.md` in the same table (paraphrased — no quote available because the check spans rows 26 and 29 of the table). The skill says "It runs when the user starts it; there is no timer." (`skills/dev-cycle/SKILL.md:14`) and "only decisions that need the user become `you: judgment` entries in `docs/working/questions.md`" (`:17-18`).

**Evidence:** `global-instructions/CLAUDE.md:26-32`, `skills/dev-cycle/SKILL.md:14-19`

---

## Claim 15: "| `dev-cycle` | **Adequate** | Workflow-shaped (seven ordered steps, triage output) ..."

**Location:** `guides/skill-creation.md:137`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the step count in `skills/dev-cycle/SKILL.md`; does not assess the "Adequate" rating (opinion).

The skill has eight ordered steps, `### 0. Digest` through `### 7. Close` (`skills/dev-cycle/SKILL.md:26`, `:92`), and both row 67 and commit 1f8ed13 list eight (digest → ... → cycle record). "Seven" is right only if the digest is not counted as a step, which the skill itself does ("Run them in order. Every step ends with a line in the cycle record", `:23`). Medium confidence because of that reading.

**Evidence:** `skills/dev-cycle/SKILL.md:21-92`, `docs/decisions/log.md:90`

---

## Claim 16: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago."

**Location:** `scripts/dev-cycle.sh:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which date is chosen (the lexicographically greatest well-formed filename date, or `date -d '14 days ago'`); does not cover how git then interprets that date (Claim 17).

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

Executed: `bats test/dev-cycle.bats` (cwd worktree, exit 0, 2026-09-29T01:58:37-07:00) passes test 3 ("Window: since 2026-02-10" with records 2026-01-05 and 2026-02-10); mutations "ignore records" and "pick oldest" each fail test 3. The worktree run with no cycles dir printed a 2026-09-15 window on 2026-09-29.

**Evidence:** `scripts/dev-cycle.sh:44-52`, `docs/reviews/execution-logs/r3-devcycle-bats-baseline.txt`, `docs/reviews/execution-logs/r3-devcycle-mutations.txt`, `docs/reviews/execution-logs/r3-devcycle-probe-worktree.txt`

---

## Claim 17: "--since   start of the cycle window." (and the digest line "Window: since $SINCE")

**Location:** `scripts/dev-cycle.sh:12`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the bare date is applied by `git log`/`git rev-list --since`; does not establish how often a real cycle day has merges before the next run's clock time.

The date is passed bare: `git log "$MAIN" --first-parent --merges --since="$SINCE"` and `git rev-list --count --since="$SINCE" "$MAIN"` (`scripts/dev-cycle.sh:61-62`). Git reads a bare `YYYY-MM-DD` as that date *at the current wall-clock time*, so the window starts at SINCE plus the run's time of day, not at the start of SINCE. Executed (cwd `scratchpad/fc3/r2`, exit 0, 2026-09-29T01:58:13-07:00): a repo whose only merge was at `2026-09-29T00:01`, with `cycle-2026-09-29.md` present, printed "Window: since 2026-09-29" and "0 merge(s), 0 commit(s)"; the same `git log --since=2026-09-29` returned nothing while `--since="2026-09-29 00:00"` returned the merge. Consequence: merges made on the previous cycle's day, after its record but before the next run's clock time, fall out of both digests.

**Evidence:** `scripts/dev-cycle.sh:57-62`, `docs/reviews/execution-logs/r3-devcycle-probe-sameday-window.txt`

---

## Claim 18a: "Acts on the git repo of $PWD (like questions.sh)"

**Location:** `scripts/dev-cycle.sh:16`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers invocation by absolute path or from the repo root (how the skill and installed copy use it); does not hold for a relative path run from a subdirectory.

`ROOT="$(git rev-parse --show-toplevel ...)"; cd "$ROOT"` precedes `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` (`scripts/dev-cycle.sh:36-38`), so a relative `BASH_SOURCE` is resolved against the toplevel, not the caller's directory. Executed (cwd `scratchpad/fc3/sub/a/b`, exit 1, 2026-09-29T01:58 -07:00): `bash ../../scripts/dev-cycle.sh` failed with "line 38: cd: ../../scripts: No such file or directory". Absolute-path runs in the bats suite and probes act on `$PWD`'s repo as stated.

**Evidence:** `scripts/dev-cycle.sh:36-38`, `docs/reviews/execution-logs/r3-devcycle-probe-subdir-relative.txt`

---

## Claim 18b: "so the installed copy at ~/.claude/scripts/dev-cycle.sh serves any project."

**Location:** `scripts/dev-cycle.sh:16-17`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a local repo whose default branch is not `main` and that has no `origin/HEAD`; the installed path itself is correct (install.sh stages the whole `scripts` dir), and repos with `main` or an `origin/HEAD` work.

The fallback is hard-coded: `[[ -n "$MAIN" ]] || MAIN=main` (`scripts/dev-cycle.sh:42`), then `git log "$MAIN" ...` under `set -euo pipefail` (`:20`, `:61`). Executed (cwd `scratchpad/fc3/m`, a `git init -b master` repo, exit 128, 2026-09-29T01:58 -07:00): output "fatal: ambiguous argument 'main': unknown revision" after printing "Window: ... on `main` at ." The installed copy exists because `devcontainer-config/install.sh:135` stages `scripts`.

**Evidence:** `scripts/dev-cycle.sh:20`, `scripts/dev-cycle.sh:40-42`, `scripts/dev-cycle.sh:61`, `devcontainer-config/install.sh:135`, `docs/reviews/execution-logs/r3-devcycle-probe-master.txt`

---

## Claim 19: "Read-only: prints to stdout and writes nothing."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working tree and git status of the target repo, and every command the script runs (git read commands, `questions.sh open`, `shuf` with a process-substitution source); does not cover `.git` internals byte-for-byte.

Every command in the script is a read (`git log`, `git rev-list`, `git rev-parse`, `git symbolic-ref`, `awk`, `grep`, `shuf`, and `bash "$QS" open`, whose `cmd_open` only parses and prints, `scripts/questions.sh:408-414`) (paraphrased — no quote available because the claim covers the absence of writes across the whole file). Executed (cwd `scratchpad/fc3/r`, exit 0): file list and `git status --porcelain` identical before and after ("NOWRITE"); the read-only worktree run also left `git status --porcelain` unchanged.

**Evidence:** `scripts/dev-cycle.sh:36-135`, `scripts/questions.sh:408-414`, `docs/reviews/execution-logs/r3-devcycle-probe-today.txt`, `docs/reviews/execution-logs/r3-devcycle-probe-worktree.txt`

---

## Claim 20: "No origin/HEAD (a local-only repo) is normal; fall back to main."

**Location:** `scripts/dev-cycle.sh:40-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches (no origin/HEAD → `main`; origin/HEAD → its short name without `origin/`); does not cover repos without a `main` (Claim 18b).

```bash
# scripts/dev-cycle.sh:41-42
MAIN="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
[[ -n "$MAIN" ]] || MAIN=main
```

Executed: the six bats tests (no remote) all pass; a clone (cwd `scratchpad/fc3/o`, exit 0) with `refs/remotes/origin/main` printed "on `main` at f6d9c4d".

**Evidence:** `scripts/dev-cycle.sh:41-42`, `docs/reviews/execution-logs/r3-devcycle-probe-originhead.txt`, `docs/reviews/execution-logs/r3-devcycle-bats-baseline.txt`

---

## Claim 21: "every revisit trigger (records and log rows)" (commit 1f8ed13; also skill step 0 "every revisit trigger")

**Location:** `scripts/dev-cycle.sh:80-91`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the log-row path; the decision-record path (`:72-79`, whole `## Revisit triggers` section) is correct and mutation-tested; does not establish how often the first-match problem recurs in future rows.

For log rows the script prints only the first `revisit` substring, cut at the next `|` or 400 characters: `text="$(printf '%s' "$row" | grep -oiE 'revisit[^|]*' | head -1 | cut -c1-400)"` (`scripts/dev-cycle.sh:88`). When a row mentions "revisit" before its trigger, the trigger is not shown. Executed read-only in the worktree (exit 0, 2026-09-29T02:00 -07:00): the digest's line for row 67 is "row 67: revisit-trigger verdicts (fired / not fired / cannot tell, with evidence) → watched questions → ... roadma" — the step list — and row 67's actual trigger, "Revisit if three cycles in a row file nothing ... or if the gap between cycles passes a month twice", appears nowhere. Rows 53 and 65 run on past their trigger into unrelated text. Test 2's fixture has a single "Revisit" clause, so it cannot catch this.

**Evidence:** `scripts/dev-cycle.sh:80-91`, `docs/decisions/log.md:90`, `docs/reviews/execution-logs/r3-devcycle-probe-worktree.txt`

---

## Claim 22: questions.sh is looked up in `$SCRIPT_DIR`, then `~/.claude/scripts`

**Location:** `scripts/dev-cycle.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lookup order and that both installed and repo layouts put questions.sh beside dev-cycle.sh; does not cover a non-executable sibling copy (it falls through to the home copy).

```bash
# scripts/dev-cycle.sh:98-100
QS="$SCRIPT_DIR/questions.sh"
[[ -x "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
if [[ -f docs/working/questions.md && -f "$QS" ]]; then
```

`scripts/questions.sh` is mode `-rwxr-xr-x`, and install stages the whole `scripts` directory (`devcontainer-config/install.sh:135`).

**Evidence:** `scripts/dev-cycle.sh:98-100`, `devcontainer-config/install.sh:135`

---

## Claim 23: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain the word "trigger"."

**Location:** `scripts/dev-cycle.sh:101-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `open` output format and the column split for all five routes (all ≤13 chars, so `%-14s` always leaves 3+ spaces); does not cover a route of 14+ characters.

`scripts/questions.sh:412`: `printf '%s  %-14s  %s\n' "$id" "$route" "$slug"`. Executed: test 5 (slug `a-trigger-in-the-slug`, route `agent`) passes, and replacing the `awk -F'  +'` route filter with `grep -E 'trigger|deferred'` fails test 5. Worktree run printed "Open by route: agent=7, deferred=2, trigger=2, you: terminal=1".

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:103-111`, `docs/reviews/execution-logs/r3-devcycle-mutations.txt`, `docs/reviews/execution-logs/r3-devcycle-probe-worktree.txt`

---

## Claim 24: the digest's "None open." (watched questions) and the skill's "It ... gives ... the watched questions"

**Location:** `scripts/dev-cycle.sh:103-108`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case where `docs/working/questions.md` exists but `questions-archive.md` does not (or `open` fails for any other reason); with both files present the section is correct (Claim 23).

The failure of `questions.sh open` is swallowed: `open_q="$(bash "$QS" open 2>/dev/null || true)"` (`scripts/dev-cycle.sh:103`), and an empty result prints "None open." (`:108`). `open` fails when either file is missing (`scripts/questions.sh:42-45`: "Every command except `init` needs both files to exist and fails"). Executed (cwd `scratchpad/fc3/r2`, exit 0): a questions.md holding one OPEN `trigger` entry and no archive produced "None open." and an empty "Open by route:". The skill's precondition covers only a missing questions.md ("If the repo has no `docs/working/questions.md`, run `questions.sh init` first", `skills/dev-cycle/SKILL.md:31-32`).

**Evidence:** `scripts/dev-cycle.sh:98-114`, `scripts/questions.sh:42-45`, `skills/dev-cycle/SKILL.md:31-32`, `docs/reviews/execution-logs/r3-devcycle-probe-no-archive.txt`

---

## Claim 25: "Seeded by the date so a rerun on the same day audits the same merges."

**Location:** `scripts/dev-cycle.sh:120`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism for an unchanged merge list; does not hold when the list changes between runs on the same day.

`printf '%s\n' "$merges" | shuf -n "$SAMPLE" --random-source=<(yes "$TODAY")` (`scripts/dev-cycle.sh:121`) is deterministic for identical input (test 4 passes; the worktree run is reproducible). But the input list is not fixed within a day: the window's start moves with the clock (Claim 17), so a later rerun can drop the oldest merges, and new merges add lines. Executed (cwd `scratchpad/fc3`, 2026-09-29T02:01 -07:00): with the same seed, `seq 1 9` samples "6 8" and `seq 1 8` samples "8 6", `seq 1 7` "6 7", `seq 1 6` "2 6". Precise version: "the same merges on a same-day rerun, provided the window's merge list is unchanged".

**Evidence:** `scripts/dev-cycle.sh:119-121`, `docs/reviews/execution-logs/r3-devcycle-probe-shuf.txt`

---

## Claim 26: "using the entry grammar in the global instructions ("Running questions document")"

**Location:** `skills/dev-cycle/SKILL.md:18-19`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named section exists and defines an entry grammar; does not verify its content further.

`global-instructions/CLAUDE.md:234`: `### Running questions document`.

**Evidence:** `global-instructions/CLAUDE.md:234`

---

## Claim 27: "Run `scripts/dev-cycle.sh` (installed copy: `~/.claude/scripts/dev-cycle.sh`) ... It is read-only ... If the repo has no `docs/working/questions.md`, run `questions.sh init` first."

**Location:** `skills/dev-cycle/SKILL.md:28-32`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the installed path, read-only property (Claim 19) and that `init` creates missing live/archive files; the "every revisit trigger" part of this step is Claim 21.

`devcontainer-config/install.sh:135` stages `scripts`; `scripts/questions.sh:449-452` dispatches `init`/`archive`/`index`/`open`, and `cmd_init` "Create[s] whichever of the two files is missing" (`scripts/questions.sh:416-419`).

**Evidence:** `devcontainer-config/install.sh:135`, `scripts/questions.sh:416-452`

---

## Claim 28: "Start the project's full check ... (in claude-workflows: `scripts/health-check.sh`) ... triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)."

**Location:** `skills/dev-cycle/SKILL.md:36-39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's existence and that 5a has three matching classes; the first class is relabelled from "Caused by this branch" to "caused by recent work", which is the natural adaptation for a cycle with no branch.

`scripts/health-check.sh` exists (executable). `workflows/pr-prep.md` step 5a's table rows are "Caused by this branch", "Pre-existing on main", "Flaky / infra / environmental", and it also asks to "Quiesce before the gate".

**Evidence:** `workflows/pr-prep.md` (step 5a triage table)

---

## Claim 29: "`questions.sh archive` then `questions.sh index`, so answered entries leave the live file."

**Location:** `skills/dev-cycle/SKILL.md:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both subcommands exist and archive moves ANSWERED entries; does not note more than that `index` after `archive` is redundant (archive already reindexes).

`scripts/questions.sh:30`: "archive    move ANSWERED entries to the archive, reindex".

**Evidence:** `scripts/questions.sh:28-33`, `scripts/questions.sh:374-394`

---

## Claim 30: "Stale working docs: in claude-workflows, `scripts/archive-working-docs.sh -n` lists what would move."

**Location:** `skills/dev-cycle/SKILL.md:43-44`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `-n` flag; does not establish that the script picks "working docs whose task has merged" — it moves every non-permanent, uncited top-level file, and never touches `docs/working/cycles/` (it skips non-files).

`scripts/archive-working-docs.sh:22`: "-n, --dry-run   Show what would be moved without moving anything"; the loop is `for f in "$WORKING_DIR"/*; do` / `[ -f "$f" ] || continue` (`scripts/archive-working-docs.sh:130-131`; excerpt ends :131, enclosing loop continues through the `mv -- "$f" "$dest"` at :158 — read).

**Evidence:** `scripts/archive-working-docs.sh:4-31`, `scripts/archive-working-docs.sh:130-158`

---

## Claim 31: "Use `code-fact-check` at k=1 for a merge with many claims."

**Location:** `skills/dev-cycle/SKILL.md:66-67`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the k parameter lives; does not assess whether k=1 is the right depth.

`code-fact-check` has no k parameter; replication is code-review's dispatch setting: "Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031" (`skills/code-review/SKILL.md:20`). A direct `code-fact-check` invocation is already a single pass, so the instruction works, but "at k=1" names a knob the skill does not have.

**Evidence:** `skills/code-review/SKILL.md:20`, `skills/code-fact-check/SKILL.md` (no `k=` occurrences)

---

## Claim 32: "Update `docs/roadmap.md` (create it from its own template if missing)"

**Location:** `skills/dev-cycle/SKILL.md:80`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether a roadmap template file exists; does not rule out that "its own template" means the Now/Next/Ideas/Done list that follows.

No roadmap template exists: `templates/` holds only `gitattributes-snippet.txt`, and `rg -il roadmap templates` finds nothing (paraphrased — no quote available because the claim covers absence). The workable template is the four-bullet list at `skills/dev-cycle/SKILL.md:82-85`; the sentence should say so.

**Evidence:** `skills/dev-cycle/SKILL.md:80-85`

---

## Claim 33: "Each test builds a throwaway git repo under $BATS_TEST_TMPDIR, so nothing reads or writes this repo's own docs/." / "HOME points at the temp dir so the ~/.claude/scripts fallback can't reach the real installed questions.sh."

**Location:** `test/dev-cycle.bats:4-5`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers setup (git config, HOME, repo under `$BATS_TEST_TMPDIR`, `cd` into it) and that the script acts on `$PWD`'s repo; the repo's own `scripts/questions.sh` is still executed (read-only, against the temp repo).

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

(excerpt ends :21; enclosing setup() continues to :30 — read.) Executed: `bats test/dev-cycle.bats` (cwd worktree, exit 0); worktree `git status --porcelain` shows no change to `docs/` from the run.

**Evidence:** `test/dev-cycle.bats:9-30`, `docs/reviews/execution-logs/r3-devcycle-bats-baseline.txt`

---

## Claim 34: the six test names (each test fails when the behaviour it names breaks)

**Location:** `test/dev-cycle.bats:32-109`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ten mutations of a scratch copy of the script; does not cover the "same ones on a rerun" half deterministically.

Mutations (cwd `scratchpad/fc3/mut`, 2026-09-29T01:59 -07:00): slug-matching filter → test 5 fails; ignore cycle records / pick oldest record → test 3; drop `--since` validation / swallow unknown options → test 6; revisit section not ending at next `##` → test 2; `shuf -n 1` → test 4. Gaps: removing `--random-source` entirely passed the full suite once (a 1-in-6 chance with 3 merges choose 2; 6 of 6 focused reruns failed), so test 4's rerun check is probabilistic; replacing the date-seeded `shuf` with `head -n "$SAMPLE"` passes every test, so "date-seeded" is not what test 4 pins (its name claims only rerun sameness, which that mutation keeps).

**Evidence:** `test/dev-cycle.bats:64-72`, `docs/reviews/execution-logs/r3-devcycle-mutations.txt`

---

## Claim 35a: commit 1f8ed13 — "11 decision records and 7 log rows carry revisit triggers that nothing read ... there was no roadmap." / "test/dev-cycle.bats: six hermetic tests in throwaway repos." / "Row 67's revisit triggers cover moving to /loop or /schedule."

**Location:** `git:1f8ed13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts (Claim 2), the absence of `docs/roadmap.md` on main, the test count and row 67's trigger text; the "every revisit trigger" and "Works in any repo" parts are Claims 21 and 35b.

`git show main:docs/roadmap.md` fails: "path 'docs/roadmap.md' exists on disk, but not in 'main'". `test/dev-cycle.bats` has six `@test` blocks (`:32`, `:44`, `:57`, `:64`, `:74`, `:104`). Row 67 ends "Revisit if three cycles in a row file nothing ... or if the gap between cycles passes a month twice (then add a `/loop` or `/schedule` trigger)" (`docs/decisions/log.md:90`).

**Evidence:** `docs/decisions/log.md:90`, `test/dev-cycle.bats:32-104`

---

## Claim 35b: commit 1f8ed13 — "Works in any repo (acts on $PWD's repo; falls back to main without origin/HEAD)."

**Location:** `git:1f8ed13`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same finding as Claims 18a/18b; the two parenthesised mechanisms are true as far as they go.

A local repo on `master` with no `origin/HEAD` exits 128 (`[[ -n "$MAIN" ]] || MAIN=main`, `scripts/dev-cycle.sh:42`), and a relative-path run from a subdirectory exits 1 (`scripts/dev-cycle.sh:36-38`).

**Evidence:** `scripts/dev-cycle.sh:36-42`, `docs/reviews/execution-logs/r3-devcycle-probe-master.txt`, `docs/reviews/execution-logs/r3-devcycle-probe-subdir-relative.txt`

---

## Claim 36: commit 89a3d3b — "dev-cycle description <=250 chars with a precedence clause; no when:" / "README: 34 skills, dev-cycle named; skill-creation inventory row" / "Roadmap: rows 65/66 to Done ... deferred review items added to Ideas with signals" / "Row 67: date the revisit-trigger counts"

**Location:** `git:89a3d3b`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against HEAD; the facts inside those lines are checked separately (Claims 1, 2, 11, 13, 15).

The folded description is 242 characters and contains "Not for landing one change (pr-prep)." (`skills/dev-cycle/SKILL.md:4`); the frontmatter has no `when:` line (`:1-5`). README says "34 Claude Code skills" and names `dev-cycle` (`README.md:182`); `guides/skill-creation.md:137` adds the row; `docs/roadmap.md:58-60` holds rows 65/66 under Done and `:46-49` the two deferred items; row 67 reads "As of 2026-09-28, 11 decision records ..." (`docs/decisions/log.md:90`).

**Evidence:** `skills/dev-cycle/SKILL.md:1-5`, `README.md:182`, `guides/skill-creation.md:137`, `docs/roadmap.md:46-60`, `docs/decisions/log.md:90`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`docs/roadmap.md:25`): Q-092 does not wait on a Bash sandbox (it removes the hook's deny reader; interim "the reader stays"); only Q-098 does. Drop Q-092 from item 2's motive.
- **Claim 15** (`guides/skill-creation.md:137`): the skill has eight ordered steps (0-7), not seven.
- **Claim 17** (`scripts/dev-cycle.sh:12`, `:61-62`): a bare `--since=YYYY-MM-DD` means that date at the current clock time, so merges earlier on the window's first day are dropped; pass `"$SINCE 00:00"` or document the boundary.
- **Claim 18b** (`scripts/dev-cycle.sh:16-17`, `:42`): "serves any project" fails (exit 128) in a repo without `main` and without `origin/HEAD`.
- **Claim 21** (`scripts/dev-cycle.sh:88`): log-row extraction prints the first "revisit" substring, so row 67's own trigger is replaced by its step list; "every revisit trigger" does not hold for log rows.
- **Claim 24** (`scripts/dev-cycle.sh:103-108`): a failing `questions.sh open` (e.g. no questions-archive.md) is swallowed and reported as "None open."
- **Claim 35b** (`git:1f8ed13`): "Works in any repo" — same as 18a/18b.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`docs/roadmap.md:27-29`): host tools are gated by `Live-verified:` and can never satisfy it, not "verified by" it.
- **Claim 12** (`docs/roadmap.md:50-52`): the `code-fact-check-report-r*.md` conflicts were content conflicts on undated names that collide on any day; only the `*-review-<date>.md` ones were add/add.
- **Claim 18a** (`scripts/dev-cycle.sh:16`): a relative-path run from a subdirectory crashes because `SCRIPT_DIR` is resolved after `cd "$ROOT"`.
- **Claim 25** (`scripts/dev-cycle.sh:120`): same-day sample is stable only while the window's merge list is unchanged (the window start moves with the clock).
- **Claim 31** (`skills/dev-cycle/SKILL.md:66-67`): k is a code-review dispatch setting; code-fact-check has no k.
- **Claim 32** (`skills/dev-cycle/SKILL.md:80`): there is no roadmap template file; name the step-6 bullet list as the template.
- **Claim 34** (`test/dev-cycle.bats:64-72`): test 4's rerun check catches removal of the seed only probabilistically (passed 1 full run of 7), and no test pins date-seeding.

### Unverifiable
- None.

---

## Goal-Alignment Note

- **Answered:** every item in the brief's "Claims that particularly need checking" list: script header claims (read-only, $PWD, window default, main fallback, same-day sample, questions.sh lookup), each command/path the skill names, every roadmap line's facts, row 67 against ec297d4, global row 12 and README/guide lines, the bats header and a ten-mutation pass over the tests, and both commit messages.
- **Out of scope:** did not run `scripts/health-check.sh` or the full suite (per brief); did not append to `docs/reviews/hallucination-patterns.md` (the brief allows editing only this report; Claim 6b is a borderline candidate for the caller to decide on). Execution logs were added as untracked files under `docs/reviews/execution-logs/r3-devcycle-*.txt`.
- **Escalate:** Claims 17, 21 and 24 are behavioural defects in the digest (a first-day blind spot in the window, row 67's own trigger not shown, a swallowed `open` failure reported as "None open."), not only wording drift.
