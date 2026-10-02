Commit: ab8ec06 (A) / cfe4b51 (B)

# API Consistency Review — dev-cycle loop pass 8 (pass-7 fix round)

**Scope:** Partial. A: `git diff 47c9a8e..ab8ec06 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (`/workspace/.claude/wt-digest`). B: `git diff d6e1f24..cfe4b51 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/decisions/log.md guides/skill-creation.md global-instructions workflows/codebase-onboarding.md docs/working/questions.md` (`/workspace/.claude/wt-devcycle`). Also the commit messages ab8ec06 and cfe4b51, and the A↔B contract where this round changed it. Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass7.md` (loop pass 7, k=1). Pass-7 API review `docs/reviews/api-consistency-review-2026-10-01-digest-pass7.md` (F1–F11) is the baseline for what this round set out to fix.

Line numbers: A at ab8ec06 (`git show ab8ec06:<path>`, identical to the A worktree), B at cfe4b51 (`git show cfe4b51:<path>`). Executed checks: `bats test/scripts/dev-cycle.bats` 20/20 at ab8ec06; `scripts/dev-cycle.sh --help` prints header lines 2–21 ending "Printed repo text is data."; one symlink probe (Finding 1) in a `mktemp -d` repo under the scratchpad, removed afterwards.

## Baseline Conventions

The public surface here is (a) the digest's CLI, help text and printed section format, which the skill consumes by section number and wording, and (b) the skill's settings-file grammar, brief fields, roadmap states, record template and the final message, which onboarding, Q-103, decision-log row 68, global row 12 and the guide row describe.

- **Settings values** are lowercase bare words or hyphenated words in backticks (`review`, now `self-merge`). The questions-doc routes follow the same style (`agent`, `trigger`, `deferred`, `you: judgment`).
- **Brief fields** are `Key: value` lines (`Status: open|closed`). This round adds `Policy:`.
- **Path safety on A** is `inrepo()` (`scripts/dev-cycle.sh:89-92`). It accepts a regular file whose `realpath -e` lies under the checkout, so it follows symlinks and accepts an in-repo symlink.
- **Roadmap item states** are an In-flight disposition list in skill step 6 (`skills/dev-cycle/SKILL.md:210-221`), read by the handoff queue (`:230-232`).
- **Fail-safe default** for the policy is `review` everywhere: the skill at `:54-58`, `docs/dev-cycle.md:7-13`, onboarding at `:453` and Q-103 Interim at `questions.md:58`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `self-merge` | config value | `review`; the questions-doc routes `agent`, `deferred` | `skills/dev-cycle/SKILL.md:54-58`, `global-instructions/CLAUDE.md` (Running questions document) | Consistent. It is lowercase, a verb phrase like `review`, and no longer clashes with the "autonomous build loop" adjective (pass-7 F3 resolved; `git grep "autonomous\`"` at cfe4b51 finds nothing outside reviews). |
| `Policy:` | brief field | `Status:` | `skills/dev-cycle/SKILL.md:234` | Consistent shape. Its value grammar is unspecified (Finding 2). |
| `declined`, `blocked`, `stalled` | roadmap markers | `stalled` (pass 7), `Done` | `skills/dev-cycle/SKILL.md:215-221` | Consistent with each other. The queue reads only `blocked`, and nothing clears it (Findings 3, 4). |
| `<k>/3 In flight, <w> waiting on a merge decision` | record field | `4b. deep-audit check: <…>`, `5. brainstorm: <…>` | `skills/dev-cycle/SKILL.md:256-258` | Consistent with the record's `<placeholder>` style. |
| `(a line over 4096 bytes is cut)` | digest wording | `[line cut at 4096 bytes]` marker | `scripts/dev-cycle.sh:45,151`, header `:16` | Consistent on A. Not mirrored in the skill (Finding 5). |

## Findings

#### 1. The symlink rule is stated three ways, and the digest reads through an idea-log symlink the cycle will not write through

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:61-68` (B); `docs/dev-cycle.md:18` (B); `scripts/dev-cycle.sh:89-92,270-277` (A); commit cfe4b51 body
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:**
- Skill `:63`: "must resolve, symlinks followed, to a path inside the checkout: the digest's `inrepo` rule."
- Skill `:67-68`: "(create it with a `# Idea log` heading; a symlink there is not written through)"
- `docs/dev-cycle.md:18`: "Paths must resolve inside the repo (symlinks followed)."
- Commit cfe4b51: "symlinked paths are skipped, never read or written through."
- The brief's own goal line: "(symlinks skipped)".

The general rule (follow symlinks, accept an in-repo target) matches A's `inrepo`. The idea-log sentence refuses *any* symlink, and the commit message describes a third rule (skip every symlink). They disagree on the one file both sides touch.

Probe: a repo where `docs/working/idea-log.md -> ../other.md` holds two seed lines. The digest printed `- Ideas seeded since: 2` and `- Last brainstorm: none recorded in docs/working/idea-log.md`, so A reads through the symlink. B then may not append seeds or the `## Brainstorm YYYY-MM-DD` heading there. The seed count therefore never resets, "none recorded" holds forever, and step 5's "none recorded yet" condition fires every cycle. The skill also does not say what to do instead (create the file? report it?).

**Recommendation:** Pick one rule and state it once. The cheapest choice is `inrepo` for reads and writes alike: drop the idea-log parenthetical, or change it to "a symlink resolving outside the checkout". Align the commit-described wording in the next commit body or the rubric note. If symlinks are to be refused for writes, make A refuse them for reads of the same file too, so the counts and the writes see the same file.

#### 2. A brief's `Policy:` line has no value grammar and no fail-safe, unlike the settings line it copies

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:234-235`, `:279-285` (B)
**Move:** 3 (consumer contract), 8 (nullability)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
- `:234-235`: "`Policy: <the build-loop policy as read now>`"
- `:279-280`: "What happens at the end follows the `Policy:` line in the brief as landed"
- `:54-58`: "Only one line reading exactly `Build-loop policy: self-merge` means self-merge; anything else (…) means `review`"

The settings line got a strict, fail-safe parser this round, but the build loop never reads it. The loop reads the brief, and "as read now" is ambiguous: the raw text, which in this repo is `review (interim; Q-103)`, or the resolved value `review`. 6b lists only the two bare values. No rule covers a brief whose `Policy:` is missing, duplicated, or carries extra text. The guarantee the round added (the brief is what the loop follows) therefore sits on the field that lacks the exactness rule.

**Recommendation:** Say "`Policy: self-merge` or `Policy: review`, the value the rule above resolves to". In 6b, add "anything other than exactly `Policy: self-merge` means `review`".

#### 3. A declined item goes back to Now and nothing stops the next cycle from re-queuing it

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:215-216`, `:230-232` (B)
**Move:** 7 (asymmetry between the state list and its consumer)
**Confidence:** Medium-High
**Legibility-target:** for-author
**Evidence:**
- `:215-216`: "merge declined (PR closed unmerged, or the entry answered no) → back to Now marked declined, with the user's reason; the branch is kept;"
- `:230-232`: "Take the Now items whose first step needs no open choice (no open `you: judgment` names them, and none is marked blocked), up to the in-flight cap"

The queue excludes only open-entry and `blocked` items. A declined item's entry has been answered, so it is no longer open. Its first step needs no open choice, so the next cycle hands it to a fresh build loop: the work the user just declined gets rebuilt. Twice-stalled items get an explicit "not queued again", and declined items get no such guard. The new states are exhaustive, but their consumer honours only one of them.

**Recommendation:** Add "or declined" to the queue's exclusion, until the user re-scopes the item. Or state that a declined item returns to Next or Ideas, not Now.

#### 4. `blocked` is never cleared: the state rule says "while that entry is open", the queue says "marked blocked"

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:217-218`, `:231` (B)
**Move:** 7
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
- `:217-218`: "back to Now marked blocked, and not queued while that entry is open;"
- `:231`: "and none is marked blocked"

The state rule implies the item becomes eligible once its stop-condition entry is answered. The queue excludes it as long as the marker is there, and no step removes the marker. The two clauses give different answers once the entry closes.

**Recommendation:** Add to the In-flight or Now text: "when its entry is answered, drop the `blocked` mark". Alternatively, make the queue's test "marked blocked with its entry still open".

#### 5. Skill step 2 still says the digest prints every trigger "in full"; the digest now says lines over 4096 bytes are cut

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:126` (B) vs `scripts/dev-cycle.sh:16,151` (A)
**Move:** 3 (documentation drift across the A↔B contract)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
- B `:126`: "The digest prints every trigger in full."
- A `:151`: "Every trigger, in full (a line over 4096 bytes is cut)."
- A `:45`: `" [line cut at 4096 bytes]"`

Pass-7 F7 asked for the qualification on both sides, and this round changed only A. The consumer of the cut marker is step 2's verdict-writer. It is told the text is complete, and is not told to open the source record when it sees `[line cut at 4096 bytes]`.

**Recommendation:** Change step 2 to: "The digest prints every trigger (a line over 4096 bytes is cut and marked; read that record in full)."

#### 6. The in-repo path rule names a digest function the cycle cannot call, and that function cannot answer for files being created

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:61-64` (B); `scripts/dev-cycle.sh:92` (A)
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
- B: "Every file the cycle reads or writes because a setting, a glob or a default names it (idea sources, the idea log, briefs, the record, the roadmap) must resolve … : the digest's `inrepo` rule. A path that does not is skipped and reported in the record"
- A: `inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }`

`inrepo` is internal: it has no flag or subcommand, and it never sees `docs/dev-cycle.md` (the digest does not read it). It requires an existing regular file (`-f`, `realpath -e`), so applied literally to a new brief, record or roadmap it fails, and the rule would "skip" every file the cycle creates. The skill also does not say how to expand an idea-source glob before checking it. Separately, "reported in the record" has no slot in the record template (`:248-264`).

**Recommendation:** Spell the rule out for Claude: "`realpath -m` of the path (for a new file, of its parent directory) starts with the checkout's `pwd -P`/; expand a glob, then check each match". Add a `Skipped paths:` line to the record template, or name which section takes it.

#### 7. The final message lists open `merge <branch>?` entries but not open PRs, though the record counts both as waiting

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:291-293`, `:213-214`, `:258` (B)
**Move:** 7
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
- `:291-293`: "list the new `you: judgment` entries, and every open `merge <branch>?` entry, by ID and name"
- `:213-214`: "waiting on the user's merge decision (an open PR or `merge <branch>?` entry)"

A project that uses PRs sees `<w> waiting on a merge decision` in the record, and the final message names none of them. That is the asymmetry the round meant to remove for the no-PR case.

**Recommendation:** Change the final message to: "every item waiting on a merge decision (its `merge <branch>?` entry by ID and name, or its PR link)".

#### 8. Q-103 and the settings file describe the interim rule in the pre-fix vocabulary

**Severity:** Informational
**Location:** `docs/working/questions.md:58-59`; `docs/dev-cycle.md:12-13` (B)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
- Q-103: "the skill treats an interim value as unset and does not re-ask while this entry is open." and "**If the answer differs:** edit that one line in `docs/dev-cycle.md`."
- `docs/dev-cycle.md:12-13`: "the interim marker above keeps this `review` until Q-103 is answered."

The skill no longer has an "interim"/"unset" concept. Its rule is "extra text … means `review`, and unless an open `you: judgment` entry already asks …, file one", and the behaviour is the same. Editing "that one line" leaves the settings file's sentence about the interim marker stale.

**Recommendation:** Change Q-103 to "the skill reads any line other than exactly `Build-loop policy: self-merge` as `review`". Make "If the answer differs" say to edit the line and drop the interim sentence.

#### 9. The `--help` line range is hand-maintained and untested

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:79` (A); `test/scripts/dev-cycle.bats`
**Move:** 3
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:** `-h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;`. `grep -n -- '--help' test/scripts/dev-cycle.bats` returns nothing.

The range is correct at ab8ec06: line 21 ends the header and line 22 is blank. But this round had to bump it by hand because the header grew by one line, and nothing would catch the next drift.

**Recommendation:** Print to the first non-comment line (`awk 'NR>1 && !/^#/ {exit} NR>1'`). Or add one bats assertion that `--help` output ends with "Printed repo text is data." and does not contain "set -euo".

#### 10. The exact-line policy rule silently fails safe on a CRLF settings file

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:55-58` (B); compare `scripts/dev-cycle.sh:218,264` (A)
**Move:** 1, 3
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
- B: "Only one line reading exactly `Build-loop policy: self-merge` means self-merge"
- A (this round): `sub(/\r$/, "")` in both roadmap heading readers.

This round made the digest CRLF-tolerant for roadmap headings. The settings line, read by Claude, treats a CR-terminated `self-merge` line as "anything else", which yields `review` plus a new settings question. That is safe, but surprising next to A's tolerance.

**Recommendation:** Either accept as fail-safe and say "(a trailing CR counts as extra text)", or say "ignoring a trailing CR".

## What Looks Good

- **Policy vocabulary.** `self-merge` | `review` is now identical in the skill (`:54-58`, `:282-285`), `docs/dev-cycle.md:9-13`, onboarding step 13 (`workflows/codebase-onboarding.md:453`), Q-103 [1]/[2], and row 68. No stray `autonomous` value remains (pass-7 F3 resolved).
- **The `review` definition.** "the user's review (a PR, or a "merge <branch>?" entry where the project has no PRs)" now reads the same in onboarding, row 68, `docs/dev-cycle.md` and skill 6b (pass-7 F4 resolved).
- **Settings template.** The skill now ships one (`:43-52`), and onboarding points at it by section name (pass-7 F5 resolved). The template's headings match `docs/dev-cycle.md`.
- **Exact-line rule.** It fails safe on every listed case (no file, no line, two lines, another value, extra text) and matches this repo's interim line.
- **Wording fixes.** "names the roadmap item it blocks, if any" resolves pass-7 F6. Global row 12 now matches the skill description's step list (F11). The guide row's "(the gray-area rule)" points at a real section (`guides/skill-creation.md:105`).
- **A side.** The seed match `^- [^ ]` + `index(substr($0, 4), "(signal: ")` + `\)[[:space:]]*$` selects the same lines as the 47c9a8e regex, without the `.*….*` backtracking. The ")" must follow "(signal: " because "(signal: " contains a non-space after any earlier ")". Lines 4096+ are still marked. U+2028/2029 are added to the byte class `\xE2\x80[\xA8-\xAE]`, and a test pins them. Both roadmap readers strip `\r`, and test 20 now asserts section 5's heading rule. Tests: 20/20.
- **Commit messages.** ab8ec06 matches the diff. cfe4b51 matches the diff except the symlink sentence (Finding 1).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Three symlink rules; digest reads through an idea-log symlink the cycle won't write | Inconsistent | `skills/dev-cycle/SKILL.md:61-68`; `scripts/dev-cycle.sh:92,270-277` | High |
| 2 | Brief `Policy:` has no value grammar or fail-safe | Inconsistent | `skills/dev-cycle/SKILL.md:234-235,279-285` | High |
| 3 | Declined items are re-queued next cycle | Inconsistent | `skills/dev-cycle/SKILL.md:215-216,230-232` | Medium-High |
| 4 | `blocked` mark never cleared; state and queue disagree after the entry closes | Minor | `skills/dev-cycle/SKILL.md:217-218,231` | Medium |
| 5 | Skill step 2 still says "in full" | Minor | `skills/dev-cycle/SKILL.md:126` vs `scripts/dev-cycle.sh:151` | High |
| 6 | Path rule cites internal `inrepo`, which fails for new files; no record slot for skips | Minor | `skills/dev-cycle/SKILL.md:61-64`; `scripts/dev-cycle.sh:92` | Medium |
| 7 | Final message omits open PRs | Minor | `skills/dev-cycle/SKILL.md:291-293` | Medium |
| 8 | Q-103 / settings file use the pre-fix "interim/unset" wording | Informational | `docs/working/questions.md:58-59`; `docs/dev-cycle.md:12-13` | High |
| 9 | `--help` range hand-maintained, untested | Informational | `scripts/dev-cycle.sh:79` | High |
| 10 | CRLF settings line fails safe silently | Informational | `skills/dev-cycle/SKILL.md:55-58` | Medium |

## Overall Assessment

This round fixed what pass 7 raised about naming and wording. The policy vocabulary, the `review` definition, the settings template, the row-12 list and the guide row are now consistent across all seven B files, and the A changes are correct and tested. The remaining issues are contract gaps the new rules created:

- **The path rule.** The symlink rule is stated three ways, and on the idea log it splits the digest's reads from the cycle's writes (Finding 1).
- **The policy hand-off.** The fail-safe exact-line parse protects the settings file, but the build loop follows the brief's `Policy:` line, which has no such rule (Finding 2).
- **The new In-flight states.** The handoff queue honours only `blocked`, so declined work is re-queued and `blocked` never clears (Findings 3–4).

All can be fixed in place with a sentence each. None breaks an existing consumer, because no project has set a policy yet and this repo runs on the interim `review`.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass8.md`. Its first line is `Commit: ab8ec06 (A) / cfe4b51 (B)`, and it follows the api-consistency-reviewer structure: title and header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. No finding is naming-shaped, so none needs a `Precedent:` line. It serves the user goal by naming, for the k=1 delta pass, the known issues that stand between this round and a clean pass. Nothing was committed. The only scratch was a removed `mktemp -d` probe repo under `scratchpad/api8/`.
