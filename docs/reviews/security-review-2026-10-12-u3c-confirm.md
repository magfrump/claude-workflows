Commit: 0f0c7e1c

# Security Review — feat/build-loop-u3c (confirming pass over 4aad0f9c..0f0c7e1c)

**Scope:** `git diff 4aad0f9c..0f0c7e1c` (scripts/build-loop.sh cycle_diff and QKEYS_AWK, scripts/lib/dev-cycle-read.sh comment, T38/T43, plan as-built note, override row text), read with the rest of `--cycle-diff` as context (PARTIAL scope per the shared brief)
**Date:** 2026-10-12
**Based on:** docs/reviews/security-review-2026-10-12-u3c-final.md (predecessor), the shared brief's Stage-1 summary, docs/reviews/code-fact-check-report-2026-10-12-u3c-final*.md; probes executed under scratchpad/sec-u3c-confirm/

## Trust Boundary Map

```
B1: [orchestrator's staged index (chore worktree)] → [--cycle-diff: merge-base --all, ls-tree compare, ANSWER_AWK id=Q-, QKEYS/QDIFF] → [chore commit]
B2: [chore branch tip + main at land]               → [git's merge (all merge bases, rename detection)]                         → [main's questions files]
B3: [main's questions files]                         → [check_answer / ANSWER_AWK]                                                → [--approved, a brief's Asked: unblock]
B4 (moved): [questions copy, base or index]          → [ANSWER_AWK run with id=Q- for the whole-file verdict]                    → [refuse / QKEYS read]
```

Input sources:

```
S1: staged index (questions, roadmap, idea log, any other path) — request-time (orchestrator) — UNTRUSTED toward the answer reader
S2: --answered IDs                                              — request-time (orchestrator) — trusted for the IDs it names (deferred row)
S3: BASE = git merge-base --all HEAD MAIN_SHA                   — repo history the orchestrator also writes — UNTRUSTED as a stand-in for the land's merge
S4: MAIN_SHA's tree (questions files and every other path)      — runtime-mutable (user answers, gate merges) — trusted as the user's record only for the two questions paths
```

What crosses: the orchestrator's index (S1) reaches main through a merge whose result --check-answer reads as the user's record. --cycle-diff judges S1 against BASE and assumes that, once main's two questions paths equal BASE's, the land's merge of those paths is "take the index". 0f0c7e1c makes that assumption hold for multi-base histories by refusing them. It still fails for one shape: rename detection at the land can carry main's edits to a non-questions file into a questions file the index creates (Finding 1, pre-existing, outside the fix range).

## Decisions asked of this pass

1. **Does 0f0c7e1c close final F1 (criss-cross)? Yes, executed.** The predecessor's fixture (`crisscross.sh`, two merge bases, the chosen base's questions blob equal to main's, the index dropping fence lines) prints `ok` (exit 0) against scripts extracted from 4aad0f9c (`old.sh`, `git archive`, nothing checked out). Against HEAD 0f0c7e1c, it prints `refuse HEAD: it has more than one merge base with the default branch's <sha>; merge the default branch into HEAD first` (exit 2). The land's `merge-tree` result in that fixture still holds the unfenced `Q-005: [1]`, so the refusal is what stops it. The new T38 case builds a criss-cross with `commit-tree` and asserts the exact refusal text; it passes (`bats -f`, serial, own TMPDIR). The empty-output guard (`|| [[ -z "$base" ]]`) and the newline test cover both "none" and "several". After the advised fix (merge main into HEAD), main becomes the single base, which is what the ls-tree rule needs.
2. **Does running ANSWER_AWK with `id=Q-` add a fail-open? No fail-open found (executed, `md.sh`).** The caller treats any non-empty output, or a non-zero awk exit (`|| md="unread"`), as a refusal. For a clean file it prints nothing; for the whole-file cases it prints `odd N why` (refdef, indented fence, CR, BOM on line 1), `unbalanced N` (open fence, `~~~~`…`~~~`) or `quoted N`. A missing input makes awk exit 2, and the caller refuses with `unread`. The whole-file verdicts do not depend on `id`: the only rules ahead of `fence($0)` are the CR strip and the `qline` rule, and neither of them calls `next`. As a result, every line reaches `fence()`, and `odd`, `fline` and `qline` come out the same as in check_answer's per-ID runs. The `md` variable is declared local and assigned without `local` on the same line, so the exit status is not lost. One inaccuracy fails closed. The comment says "id Q- names no entry", but `heading()` matches `### Q-` and `### Q- x` (`h == id` / `index(h, id " ")`). Such a file prints `open` plus the heading and is refused (`qdash`, `qbare` cases), which costs only availability. `Q-:` answer lines are read only inside a matched entry (`qcolon` case: empty). Informational (Finding 2).
3. **New regressions in the fix range: none Medium+.** The ls-tree split is now `A > lb && B > lm || refuse index`, followed by a separate `cmp` refusal. Precedence is correct: the redirect binds to each command, and a failure of either listing refuses. QKEYS_AWK lost its END block, so its output now has only `ID\tF\tK\tLINE` rows; ID is `Q-` plus digits, so QDIFF's input carries no stray verdict lines. The label-regex parity test still finds the literal in QKEYS_AWK and passes. T43 changes are comment and line-joins only; both tests pass.

## Findings

#### 1. Rename detection at the land can carry main's edit of a non-questions file into a questions file the index creates (B1 rule premise, pre-existing)

**Severity:** Medium
**Location:** `scripts/build-loop.sh` cycle_diff, the ls-tree comparison of the two questions paths (and `diff-index ... --no-renames`); the land itself is U4's
**Boundary:** B1, B2, B3
**Move:** 11 (bypass enumeration: predecessor's untested "rename detection" candidate), 4 (the check reads paths, the land's merge pairs content)
**Confidence:** Low (mechanism executed; the preconditions are uncommon)

Weakness: the main-changed rule compares only the two questions paths between BASE and main. git's default merge (ort, and `merge-tree --write-tree`, which log_class's clean_merge uses) detects renames on each side. Suppose a questions file is absent on BASE, and the index adds it while deleting a similar non-questions file. If main edited that other file, the merge applies main's edits to the questions path. Preconditions: one questions file is absent on BASE, and the index both creates it and deletes a file at least about 50% similar that main changed after the fork. That can happen in a project's first cycle (`questions.sh init` creating the files), or in a migration of a hand-kept questions draft. When the path already exists on BASE it is not a rename target: the same shape then ends in a modify/delete conflict and the land is not clean (executed, `rename2.sh`). Impact: in the fixture (`rename.sh`), --cycle-diff printed `ok` with no --answered for an index whose new archive held an OPEN entry. The land's merge result held that entry ANSWERED with `Q-007: [1]` (from main's edit of `docs/working/draft.md`), which --check-answer reads as `keep`. Neither main (no questions entry) nor the index (open) reads it that way. This is the class of outcome the mode exists to prevent: an answer the user did not give in the questions file. The idea log and the roadmap have the same exposure, because a merged-in edit can rewrite the idea log's earlier bytes. Not in the fix range, and not a regression.

**Recommendation:** Refuse when either questions file (or the roadmap or idea log) is absent on BASE and added in the index while the index also deletes a path. A simpler option is to refuse any staged deletion or addition beside a questions-file addition. The more general fix is the predecessor's alternative: judge `git merge-tree --write-tree MAIN_SHA <index tree>`'s questions files against MAIN_SHA, which covers renames, criss-cross and any future merge-shape gap at once. Add the `rename.sh` shape to T38. If this is deferred, record it as an override row keyed to U4's land.

#### 2. The "id Q- names no entry" comment is inaccurate; a `### Q-` heading refuses the whole file (fails closed)

**Severity:** Informational
**Location:** `scripts/build-loop.sh` cycle_diff (comment above the `md=` line); `scripts/lib/dev-cycle-read.sh` ANSWER_AWK `heading()`
**Boundary:** B4
**Move:** 3 (error path)
**Confidence:** High (executed, `md.sh`)

A questions copy with a heading `### Q-` or `### Q- <text>` matches `heading()` with `id=Q-`, so the run prints `open` plus the heading and --cycle-diff refuses the copy as "refused whole". This is availability only: a refusal, never a pass. Such a heading is not in the questions grammar.

**Recommendation:** Reword the comment ("names no entry the grammar allows; a `### Q-` heading refuses"), or pass an id no heading can match (for example `id="Q-\n"`).

## Untested bypass candidates

- **Non-default merge at the land (rerere, `-X`, a `merge=` attribute from a staged `.gitattributes`).** Not executed. Read-static: a built-in driver (`union`) can be selected by an attribute alone, but git takes one side without running a driver when the other side is unchanged against the single base. With several bases now refused, that holds whenever the ls-tree rule passes. Finding 1's rename shape is the exception. This belongs to U4's land.
- **HEAD moving between --cycle-diff and the commit.** Not examined. It is covered in substance by the deferred "commit takes the index as read" row. U4.

Tested and closed: **unmerged (conflict-stage) index entries** (`unmerged.sh`). With MERGE_HEAD present and with it removed, the result is `refuse index: the staged changes against <base> could not be listed` (exit 2).

Because of Finding 1, the B1 rule ("a questions change refuses while main changed them, so the land takes the index") does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** --cycle-diff refuses a HEAD with more than one merge base against MAIN_SHA, and the criss-cross fixture that passed at 4aad0f9c is refused at 0f0c7e1c.
  **Location:** `scripts/build-loop.sh` cycle_diff, first two lines
  **Evidence:** executed
  **Verified:** `crisscross.sh` against HEAD (refuse, exit 2) and against 4aad0f9c's extracted scripts (`ok`, exit 0); T38 passes with its new criss-cross case
  **Not verified:** a history with three or more merge bases (same newline test; not run)
  **route: code-fact-check**
- **Claim:** The whole-file verdict from `ANSWER_AWK` with `id=Q-` is non-empty, and so a refusal, for FENCE_AWK's odd cases, an unbalanced fence, a fenced question heading and an unreadable input, and empty for a plain questions file.
  **Location:** `scripts/build-loop.sh` cycle_diff, the `md=` line; `scripts/lib/dev-cycle-read.sh` ANSWER_AWK END
  **Evidence:** executed
  **Verified:** `md.sh` runs the lib's own `$FENCE_AWK$ANSWER_AWK` under `LC_ALL=C` on 13 files (plain, quoted, unbalanced, refdef, indented fence, tildes, BOM line 1/late, CR, missing, `### Q-`, `### Q- x`, `Q-:` line)
  **Not verified:** awk implementations other than the one the suites run; a NUL-byte input (FENCE_AWK's `nul` refusal, not run here)
  **route: code-fact-check**
- **Claim:** The ls-tree listing failure and the main-changed comparison are now two distinct refusals, and either listing failing refuses.
  **Location:** `scripts/build-loop.sh` cycle_diff, the `gate_git ls-tree` pair
  **Evidence:** read-static
  **Verified:** shell precedence of `A > f && B > g || { ...; }`, then `cmp -s ... || { ...; }`; T38's main-changed text passes
  **Not verified:** a forced ls-tree failure (no probe made gate_git fail)

## Primitive sweep

Primitive: process exec / git and awk on repo-controlled data (fix range)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh` cycle_diff `git merge-base --all HEAD "$MAIN_SHA"` | S3 | empty and multi-line refuse | cleared (executed) |
| `scripts/build-loop.sh` cycle_diff `gate_git ls-tree -z` (two calls) | S3, S4 | failure refuses `index` | cleared for listing; Finding 1 for what the comparison assumes |
| `scripts/build-loop.sh` cycle_diff `awk -v id=Q- "$FENCE_AWK$ANSWER_AWK"` | S1, S3 | non-empty or non-zero refuses | cleared (executed); Finding 2 informational |
| `scripts/build-loop.sh` cycle_diff `awk -v f=... "$FENCE_AWK$QKEYS_AWK"` | S1, S3 | failure refuses; runs only after the whole-file verdict is empty | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Land's rename detection imports main's edit of another file into a questions file the index creates (pre-existing, outside fix range) | Medium | B1, B2, B3 | `scripts/build-loop.sh` cycle_diff ls-tree rule; U4's land | Low |
| 2 | `id=Q-` matches `### Q-` headings; comment inaccurate; fails closed | Informational | B4 | cycle_diff `md=` comment; ANSWER_AWK `heading()` | High |

## Overall Assessment

0f0c7e1c closes the criss-cross bypass (final F1): the predecessor's fixture passes at 4aad0f9c and is refused at HEAD, with a matching T38 case. Moving the whole-file verdict to ANSWER_AWK with `id=Q-` adds no fail-open. Every output line, and every awk failure, is a refusal, and the verdicts do not depend on the id. The only side effect is an availability refusal on a non-grammar `### Q-` heading. The fix range contains no Medium+ regressions. A separate Medium remains (Finding 1, Low confidence, pre-existing, not a regression). The B1 rule compares paths, while the land's merge pairs content by rename. When a questions file is absent on the base and the index creates it beside a deleted similar file that main edited, a clean land can produce an answer that neither the index nor main holds (executed). The most robust single fix is to judge the merge-tree result of MAIN_SHA and the index tree. A narrow refusal of "questions file added while paths are deleted" would also do, as would an override row keyed to U4's land. Endorsements 1 and 2 are executed; endorsement 3 is read-static.
