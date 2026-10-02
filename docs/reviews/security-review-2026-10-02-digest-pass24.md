Commit: c1d0a80 (A) / fb643e2 (B)

# Security Review — dev-cycle pass 24 (the pass-23 fix round)

**Scope:** Partial. A: `git diff ba39470..c1d0a80 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 36ca12c..fb643e2 -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, merge 0caaba2). Everything else is context only.
**Date:** 2026-10-02
**Based on:** the shared brief `digest-pass24-brief-dc1aa358.md` and the Stage-1 context `docs/reviews/code-fact-check-report-digest-pass23.md`. That report covers ba39470, so for the rewritten code I re-read every function I cite in full at c1d0a80 and did not rely on it.
**Replication:** k=1 (loop pass)

**Probe discipline.** Every probe was one script. Each started with `set -eu`, created its own `mktemp -d` directory under `sec24/` in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Every process ran under `timeout`, and none is still running. The code under review was extracted with `git -C <worktree> archive <commit> | tar -x` into the temp directory. Apart from this report, nothing was written to `/workspace` or to either worktree. After the probes, `/workspace` was on `main` with only its session-start untracked files. wt-devcycle was clean. wt-digest's only untracked file is another critic's `performance-review-2026-10-02-digest-pass24.md`. The probes ran with `LC_ALL=C.utf8`, and the only awk was mawk.

Scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec24/` (below, `sec24/`):
- `probe1.sh` / `probe1.log` (E1–E3): `--check-fix` on instruction-shaped files, `--check-branch` on a symref, a non-commit ref and a tag object, and `git mv` into a missing `closed/`.
- `probe2.sh` / `probe2.log`: crafted `--check-answer` entries, run with both c1d0a80 and ba39470. It also runs every real ID in wt-devcycle's questions files under both versions and diffs the results.
- `probe3.sh` / `probe3.log`: more crafted entries, isolated from the fence state of probe 2.
- `probe5.sh`: `bats test/scripts/dev-cycle.bats` at c1d0a80. Result: 36/36 ok.

Legibility-target values:
- **agent**: the model running the dev-cycle skill acts on the output.
- **user**: the human who answers questions and reads the roadmap or record.
- **maintainer**: someone editing the script or skill.

---

## Trust Boundary Map

```
B1 (moved): questions files (user answers + text any session or the cycle writes) → --check-answer awk reader → keep/drop/open → brief Kept:/Applied:/closed (SKILL:257-267)
B2 (new):   brief file on the default branch (written by the cycle, edited by any merged build session) → model reads "Status: done" (no check mode) → Done + git mv to closed/ + roadmap
B3 (moved): repo-text path (finding, commit msg, plan) → --check-fix → in-cycle edit of a tracked docs/**.md or README.md
B4 (moved): brief's branch name (repo text) → --check-branch (show-ref + peel) → hash → git rev-list (keep-or-drop "shows no work")
B5 (new):   roadmap In-flight brief path → --check-brief/--check-path (source) + --check-write (destination) → git mv to docs/working/briefs/closed/
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `docs/working/questions.md` / `questions-archive.md` content | runtime-mutable (any session, the cycle, the user) | UNTRUSTED for decision sinks (closing or keeping a brief). Only the user's own answer line should decide. |
| S2 | brief file content (`Status:`, `Asked:`, `Applied:`, `Kept:`, `Branch:`) | runtime-mutable (any merge to the default branch) | UNTRUSTED for the Done and close decisions and for `git mv`. Trusted for nothing without corroboration. |
| S3 | path named in repo text (step 1/3/4 fix target) | request-time (per cycle) | UNTRUSTED for write sinks |
| S4 | branch name from a brief | runtime-mutable | UNTRUSTED for git argv and for ref lookup |
| S5 | local refs (`refs/heads/*`, symrefs) | host-local | Trusted. Crafting them needs host control, which is below the reachable bar. |
| S6 | question ID from a brief's `Asked:` line | runtime-mutable (S2) | UNTRUSTED. Validated to `^Q-[0-9]+$` before it reaches awk. |

Untrusted text enters through two files the cycle treats as control inputs: the questions files (S1) and the briefs (S2). The rewrite widens what S1 text is read as an answer: a label anywhere in a line now counts. The Done change moves the Done decision from git ancestry (S5, host-local) to a self-reported line in S2, which every merge can write.

## Findings

#### F1. `--check-answer` reads a bold Answer label anywhere in a line, so quoted, example or context text in an unanswered entry becomes the user's answer

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:272-276`, `:309-323` (c1d0a80); consumer `skills/dev-cycle/SKILL.md:262-265` (fb643e2)
**Boundary:** B1
**Move:** 2 (implicit sanitization assumption), 11 (guardrail bypasses)
**Confidence:** High on the mechanism (executed). Medium on how often it is triggered in practice.
**Legibility-target:** agent

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:309-323
inside && !done {
  line = $0; sub(/^[ \t]*(- )?/, "", line)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
  low = tolower(line); p = index(low, "**answer"); if (!p) next
  after = substr(low, p + 8, 2)
  if (after ~ /^[a-z]/ && after != "ed") next
  rest = substr(line, p + 2)
  ...
  result = option(rest); done = 1
}
```
(The excerpt elides `:316-321`, the label-end logic, which I read. The enclosing awk program continues to `:327`, and its result goes to `check_answer` at `:334-339`. I read both.)

Results for entries whose `**Status:**` is OPEN and that hold no user answer (`sec24/probe2.log`, `sec24/probe3.log`):

| Entry line (the only answer-like line) | c1d0a80 | ba39470 |
|---|---|---|
| `- **Read:** Q-1 (n=1) got "**Answer:** maybe [2] later", which the cycle could not read.` | `drop` | `open` |
| `> **Answer:** [2] drop` (a blockquoted earlier answer) | `drop` | `open` |
| ``The reply form is `**Answer:** [2]` or `**Answer:** [1]`; answer below.`` | `drop` | `open` |
| a list-item example in an indented ```` ``` ```` fence holding `**Answer:** [2]` | `drop` | `drop` |
| `Q-11: [2] was the interim; **Answer:** [1]` | `drop` | `unrecognized` |
| `\| **[1] keep** \| **Answer:** [1] keeps the slot \| ...` (options-table row) | `keep` | not run |
| `**Answer:** not [2]; keep it going` (a real answer, negated) | `drop` | `drop` |

The first three rows are regressions in this round, caused by the new "anywhere in a line" rule.

The path is reachable without any adversary. Step 6.2 sends an `unrecognized` answer to the record and the final message, and "the user answers on the next keep-or-drop entry, which step 3 files". The model that files entry n+1 is the one most likely to quote the unreadable reply for context. The archive's house style already quotes earlier text into an entry (`Original entry:` at `questions-archive.md:108`, and a mid-paragraph `**Answer (2026-09-28):**` at `:1675`). Any session can also append a note to an open entry.

Once the cycle misreads such a line, it applies the result and adds the ID to `Applied:`. The skill then says the entry is read once and "a second reply on this one is not read" (SKILL:263-265). So a false `drop` closes the brief, `git mv`s it to `closed/` and moves the item to Ideas without the user's decision. The user's real answer, given later, is never read. A false `keep` resets the 14-day clock.

The real archive reads correctly. Only Q-070, Q-071 and Q-073 changed, from `unrecognized` to `keep`, and each holds `**Answered 2026-09-27: [1] …**` in the question line, so `keep` is the right reading (probe2). The exposure is in entries that are still open.

**Recommendation:** Accept a label that is not at the start of a line only in an entry whose `**Status:**` is ANSWERED (the archive's mid-line `**Answered …**` form). In OPEN entries, take only a line that starts with the label or with `Q-NNN:`. Skip lines that start with `>` or `|`, and labels inside backticks. Add the first four table rows above to the bats test as `open`. In step 3, say that a keep-or-drop entry never quotes an earlier answer's label.

#### F2. Done is a self-report in a file any merge can write, read by the model with no check mode, and every new brief already contains the literal `Status: done`

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:251-256`, `:293-296` (fb643e2)
**Boundary:** B2
**Move:** 1 (runtime-mutable ⇒ compromise-reachable), 5 (invert the access model)
**Confidence:** High that the mechanism exists. Medium that a false Done happens in practice.
**Legibility-target:** agent, user

**Evidence (verbatim):**
```
  1. The brief on the default branch says `Status: done` (the build session sets it in the
     change it merges; see Build briefs) → Done, with that merge. ... Either way, `git mv` the brief to `docs/working/briefs/closed/` ...
     Done never depends on the branch, so a squash, a rebase or a deleted branch does not matter.
```
```
included, and "set this brief's `Status: done` in the change that merges it"), branch (a
```
(SKILL:251-256 and :295. Step 6.1 ends at :256; I read 6.2–6.3, :257-276, and Build briefs, :286-299.)

The script has no check mode for the Done rule. What "says `Status: done`" means is left to the model's reading. Three ways a brief is closed as Done without its work having landed:

1. **The criterion text itself.** Every brief the cycle writes from now on contains the string `` `Status: done` `` inside its acceptance criteria, next to its real `Status: open` line. A substring reading of "says `Status: done`" matches at birth.
2. **Any merge, not the brief's own.** Any change merged to the default branch can set the line, whether a different brief's build session, a session following repo text, or a stray edit. The cycle cannot tell that apart from the brief's own completion. "Done, with that merge" has no rule for finding the merge or checking that it is the brief's.
3. **Other text in the brief.** Goal and motive are written from repo text (SKILL:333-334), so any text quoted there that contains `Status: done` is a third source.

Before this round, ancestry of the brief's branch was a host-local signal (S5). Now Done rests entirely on S2. A false Done is not routed to the user: it moves the brief to `closed/`, frees a slot and writes a Done line. The user's mechanical-rules-in-code constraint (brief §Goal) is also unmet for this rule.

Two related gaps, outside the diff:
- The `Asked:`, `Applied:` and `Kept:` lines in the same file are also S2. A merge that adds a future `Kept:` date stops keep-or-drop for that brief indefinitely.
- A brief the user closes by hand is no longer named. Old 6.1 said "closed the brief". If it is left in `briefs/` with `Status: closed`, the glob still counts it toward the 3-brief cap.

**Recommendation:** Add a check mode, for example `--check-status <brief>`. It reads the brief from `git show $MAIN_SHA:<path>`, takes only the first line that is exactly `Status: (open|done|closed)`, ignores fences, and prints the commit that last changed that line (`git log -1 --format=%H $MAIN_SHA -- <path>`). Record that commit in the Done entry so the user can audit it. Add a test where the acceptance-criteria line holds `` `Status: done` `` and the status reads `open`.

#### F3. `--check-fix` allows instruction files and agent configuration under `docs/`, which the skill says are filed, not written

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:257-267` (c1d0a80); rule text `skills/dev-cycle/SKILL.md:71-74` (fb643e2)
**Boundary:** B3
**Move:** 11 (guardrail bypasses), 5
**Confidence:** Medium. It needs such a file to be tracked under `docs/`. This repo's `docs/` has none, but the installed copy serves any project.
**Legibility-target:** agent, maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:260-267
check_fix() {
  local a="$1"
  if [[ "$a" == *[*?]* ]]; then echo "skip $a: --check-fix takes one file, not a glob"
  elif ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ ! "$a" =~ ^docs/.*\.md$|^README\.md$ || "$a" =~ ^docs/(working|human-author|reviews)/ ]] || writable "$a"; then
    echo "skip $a: in-cycle fixes edit only tracked .md files under docs/ (not working/, human-author/ or reviews/) and README.md; file it instead"
  else check_path "$a"; fi
}
```
Skill: "anything else (a new file, code, scripts, hooks, egress lists, instruction files) is filed, not written."

E1 (`sec24/probe1.log`, all paths tracked) printed:
```
ok docs/CLAUDE.md
ok docs/sub/CLAUDE.md
ok docs/AGENTS.md
ok docs/.claude/skills/x/SKILL.md
ok docs/.claude/commands/c.md
ok docs/decisions/001-x.md
ok docs/dev-cycle.md
skip docs/.github/copilot-instructions.md: not an allowed path form
```
`pathform` refuses only components that start with `.git`, so `.claude` passes.

The in-cycle fix is chosen from repo text: a step-4 "doc is wrong" finding, or a step-3 `agent` entry. A nested `CLAUDE.md` or `AGENTS.md` under `docs/` is loaded as instructions by later sessions that read files in that subtree. That makes it a persistence path from repo text into future sessions' instructions, through a gate that prints `ok`.

Two smaller cases in this repo:
- `docs/dev-cycle.md` is the cycle's own settings file. Its Idea-sources rows choose what step 5 reads.
- `docs/evaluation-rubric.md` is the scoring input for `self-eval`.

Unverified: whether Claude Code discovers `docs/.claude/skills` or `docs/.claude/commands` in subdirectories. I could not check it here; see Untested bypass candidates.

**Recommendation:** In `check_fix`, refuse any component that starts with `.` and any basename `CLAUDE.md`, `AGENTS.md` or `SKILL.md`, matched case-insensitively. Also refuse `docs/dev-cycle.md`. Add these to the bats test's refusal list.

#### F4. The fence toggle ignores fence type and length, so a nested or mismatched fence forges entries, and an unclosed one hides every later entry

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:304-306` (c1d0a80)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** agent, maintainer

**Evidence (verbatim):**
```awk
/^(```|~~~)/ { fence = !fence; next }
fence { next }
heading($0) { count++; inside = (count == 1); next }
```
Results (`sec24/probe2.log`):
- A ```` ```` ```` block that quotes a ```` ``` ```` example toggles twice. The example's `### Q-40 · …` / `**Answer:** [2]` reads as a live entry: `drop Q-40`.
- A ```` ``` ```` block containing a `~~~` line turns its remaining content live: `keep Q-50`.
- An unclosed ```` ``` ```` in one entry hides every entry after it: `skip Q-6 … Q-12: no such entry`.

A forged heading cannot override a real entry, because two headings for one ID give a `dup` skip (`:325`, `:336`). So this is availability, not integrity: the decision is never flipped. Fail-closed is right. The skip stays off `Applied:`, though, and step 6.3 will not re-ask while an `Asked:` ID is skipped (SKILL:268-269). So one stray unclosed fence anywhere above an entry pins every later keep-or-drop brief to its slot until someone fixes the file. The record and the final message report it each cycle, so it is visible. It is graded Low because no decision is violated.

**Recommendation:** Close a fence only with the same character and at least the opening length, per CommonMark. Report "unclosed fence at line N" as a skip reason, distinct from "no such entry", so the cause is named.

#### F5. `--check-branch` refuses the default branch by name only; an alias ref to it prints `ok`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:245-256` (c1d0a80)
**Boundary:** B4
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** maintainer

**Evidence (verbatim):** `elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"`. E2 printed `ok alias 838d2b5…` for `git symbolic-ref refs/heads/alias refs/heads/main`, the same hash as `main`. A loose ref holding a tag object printed `ok tagged <commit>` after peeling. A loose ref holding a blob printed `absent blobby`, although `git switch -c blobby` then fails with "already exists".

All three need local ref manipulation (S5, host control), and git's own `update-ref` refuses non-commits into `refs/heads`. So none meets the reachable bar. An alias would also show as "no commit beyond the default" and route to keep-or-drop, the safe direction.

**Recommendation:** None required. Optionally refuse when `sha == MAIN_SHA` at brief-writing time.

#### F6. The `closed/` move fails on its first use, and the name-uniqueness check is not mechanised

**Severity:** Informational. These are correctness gaps on a security-adjacent path, outside this critic's severity scale.
**Location:** `skills/dev-cycle/SKILL.md:254-255`, `:290-293` (fb643e2)
**Boundary:** B5
**Move:** 3 (error path)
**Confidence:** High (E3 executed); Medium for the cap
**Legibility-target:** agent

**Evidence (verbatim):** "`git mv` the brief to `docs/working/briefs/closed/` (same file name; its destination passes `--check-write`)". E3: `--check-write` prints `ok docs/working/briefs/closed/2026-01-01-a.md`, and then `fatal: renaming 'docs/working/briefs/2026-01-01-a.md' failed: No such file or directory` (exit 128). `git mv` does not create the missing `closed/` directory, and no step creates it.

The gate passes an absent destination by design (`blocker` returns empty for absent paths), so the first close in any repo leaves the model to improvise. Uniqueness ("a file name no brief has used before, in `briefs/` or `briefs/closed/`") has no named check. If it is done with the `closed/*.md` glob, it is capped at 50 matches (`:211`; the new bats test makes 55 closed briefs). A reused name then makes the later `git mv` fail with "destination exists". That is fail-closed.

**Recommendation:** Say "create `docs/working/briefs/closed/` if missing (after `--check-write` on the destination)". Check uniqueness with a plain `--check-path 'docs/working/briefs/closed/<name>.md'` (no cap) rather than the glob.

## Untested bypass candidates

- **`--check-branch 'Main'` on a case-insensitive filesystem (macOS).** A loose `refs/heads/Main` would resolve to `main`'s file and print `ok`, not `skip … default branch`. Not tested: no case-insensitive filesystem here. It is likely harmless, because at brief-writing time the name must be `absent`, and `ok` refuses it.
- **Whether Claude Code loads `docs/.claude/skills/**/SKILL.md` or `docs/.claude/commands/*.md` from a subdirectory.** This sets F3's blast radius for those two paths. Nested `CLAUDE.md` loading is the established case. Not tested: no egress, and no Claude Code here to observe it.
- **gawk behaviour of the octal escapes `"\342\200\224"` and `index()` on bytes.** These are at `:291` and run under `env LC_ALL=C`. Only mawk is installed. The C locale should make gawk byte-wise too; not executed.

## Endorsement Claims

- **Claim:** A non-plain `docs/working/questions.md` stops `--check-answer` with a skip naming it, rather than falling through to the archive.
  **Location:** `scripts/dev-cycle.sh:331-333`
  **Evidence:** executed
  **Verified:** bats test 34 (symlinked `questions.md` → `skip Q-100: docs/working/questions.md is not a plain file…`), passing in my 36/36 run (`probe5.sh`).
  **Not verified:** a non-plain `questions-archive.md` when `questions.md` is plain and holds the ID.
  **route: code-fact-check**
- **Claim:** The same heading twice, within one file or across `questions.md` and the archive, gives a skip, not a read.
  **Location:** `scripts/dev-cycle.sh:306`, `:325`, `:336`
  **Evidence:** executed
  **Verified:** bats test 34, cases Q-9 (in one file) and Q-10 (across files).
  **Not verified:** a duplicate that appears only after step 1's `questions.sh archive` moves the entry during the cycle.
  **route: code-fact-check**
- **Claim:** A question ID reaches awk only after it matches `^Q-[0123456789]+$`.
  **Location:** `scripts/dev-cycle.sh:330`, `:334`
  **Evidence:** read-static
  **Verified:** the regex test precedes the only `awk -v id=` call. `-v` escape processing has nothing to act on in that alphabet.
  **Not verified:** none beyond `:334`; there is no other call site.
- **Claim:** `--check-branch` gives git only a hash from `show-ref --verify refs/heads/<name>`, peeled to a commit, and refuses the default branch's name.
  **Location:** `scripts/dev-cycle.sh:245-256`
  **Evidence:** executed
  **Verified:** E2 (tag object peeled to its commit; non-commit ref → `absent`; `main` → `skip … default branch`) and bats tests for `--output=x`, `-x`, `HEAD` and `refs/heads/x`.
  **Not verified:** the skill-side `git rev-list --count <default-commit>..<commit>` at SKILL:276, which is model-composed.
  **route: code-fact-check**
- **Claim:** The check modes now run after the default-branch lookup. In a repo with no resolvable default branch they exit 1, which fails closed.
  **Location:** `scripts/dev-cycle.sh:344-378`
  **Evidence:** read-static
  **Verified:** `:364` exits before the `if [[ -n "$CHECK" ]]` block at `:366`.
  **Not verified:** how the skill treats a non-zero exit from a check mode (not a digest). SKILL:131-133 names only the digest.
  **route: code-fact-check**
- **Claim:** A path under `briefs/closed/` passes `--check-write` but not `--check-brief`, so a closed brief does not count as a brief or hold a slot.
  **Location:** `scripts/dev-cycle.sh:227-240`
  **Evidence:** executed
  **Verified:** bats test 36.
  **Not verified:** a roadmap In-flight line that still names the old open path after a hand move (the source is gone, so `--check-path` skips it; the skill names no handling).
  **route: code-fact-check**
- **Claim:** `--check-fix` refuses globs, the cycle's own files, `docs/working/`, `docs/human-author/` and `docs/reviews/`, and untracked or ignored files.
  **Location:** `scripts/dev-cycle.sh:260-267`
  **Evidence:** executed
  **Verified:** bats tests 32 and 35.
  **Not verified:** the instruction-file cases in F3, which it allows.

## Primitive sweep

Primitive: process exec of git with values derived from repo text, and file move

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:248` `git check-ref-format` | S4 | NAMECHARS + not `-*` | cleared (argv, no option injection) |
| `scripts/dev-cycle.sh:252` `git show-ref --verify --hash refs/heads/$a` | S4 | as above + check-ref-format | cleared. F5 (alias) is Informational |
| `scripts/dev-cycle.sh:253` `git rev-parse "$sha^{commit}"` | S5 hash | hex from show-ref | cleared |
| `scripts/dev-cycle.sh:334` `awk -v id="$a"` | S6 | `^Q-[0-9]+$` | cleared |
| `scripts/dev-cycle.sh:196`, `:200` `git ls-files` (through `check_fix` → `check_path`) | S3 | pathform + literal/glob pathspec | cleared (unchanged this round) |
| `skills/dev-cycle/SKILL.md:254` `git mv <brief> closed/<name>` | S2/S3 (roadmap path) | `--check-brief` + `--check-path` (source), `--check-write` (destination) | F6 (missing dir). The source gate is cleared |
| `skills/dev-cycle/SKILL.md:276` `git rev-list --count <default>..<commit>` | S5 hashes | hashes only | cleared |
| `scripts/dev-cycle.sh:116` `sed -n '2,53p' "$0"` | code constant | n/a | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Answer label anywhere in a line: context, quote or example text in an open entry is read as the answer | Medium | B1 | `scripts/dev-cycle.sh:309-323` | High (mechanism) / Medium (frequency) |
| F2 | Done is a self-report in a build-session-writable brief, with no check mode; every brief contains the literal `Status: done` | Medium | B2 | `skills/dev-cycle/SKILL.md:251-256`, `:295` | High / Medium |
| F3 | `--check-fix` allows `docs/**/CLAUDE.md`, `AGENTS.md`, `docs/.claude/**`, `docs/dev-cycle.md` | Medium | B3 | `scripts/dev-cycle.sh:260-267` | Medium |
| F4 | Fence toggle ignores type and length: forged entries (dup-guarded) and hidden entries that pin a brief's slot | Low | B1 | `scripts/dev-cycle.sh:304-306` | High |
| F5 | Default-branch refusal by name only (alias ref → `ok`) | Informational | B4 | `scripts/dev-cycle.sh:250` | High |
| F6 | `git mv` into a missing `closed/` fails; the uniqueness check is not mechanised | Informational | B5 | `skills/dev-cycle/SKILL.md:254`, `:291` | High |

## Overall Assessment

No Critical or High findings, and no HALT pattern. The argv-facing parts of the round hold within the code paths I read: branch hashes only, the ID regex before awk, peeling, fail-closed ordering and closed-brief exclusion. The endorsement claims are pending execution verification. The round's weaknesses are decision integrity: who gets to say "drop" or "done". The answer reader now treats a bold label anywhere as the user's voice (F1, a regression for three shapes that ba39470 read as `open`). The Done signal moved from a host-local git fact to one line in a file any merge can write, read by the model with no tested rule, in a brief that already carries the matching text (F2). Both are fixable in place: F1 with a status-gated label position and four test cases, F2 with a `--check-status` mode that pins the first exact `Status:` line on `MAIN_SHA` and records the commit that set it. F3 is a one-line refusal list. The most important single fix is F2, because it is the only one where the user's mechanical-rules constraint is currently unmet.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

The report is at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass24.md`. Its first line is `Commit: c1d0a80 (A) / fb643e2 (B)`. It follows the skill's structure: Trust Boundary Map, source table, Findings, Untested bypass candidates, Endorsement Claims, Primitive sweep, Summary Table and Overall Assessment. Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target. The brief's checks are covered:
- **Real entries, claim 1:** only Q-070, Q-071 and Q-073 changed, each correctly to `keep`.
- **Leading-token edges:** em dash and `keep both` read `unrecognized`, a fail-safe result.
- **Duplicates across files:** endorsed. The mid-cycle archive case is named as not verified.
- **`--check-fix` scope:** F3.
- **`--check-branch` ordering:** endorsed as fail-closed.
- **Done flow, closed/ move and "shows no work":** F2, F6 and the endorsements.

Not done: a gawk run, and any observation of Claude Code's nested-skill loading.
