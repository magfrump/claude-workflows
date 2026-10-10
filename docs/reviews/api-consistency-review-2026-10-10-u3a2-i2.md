# API Consistency Review — feat/build-loop-u3a2 (U3a2, `--merge`), iteration 2

**Scope:** `git diff 7d78e6d0..f782d9ee -- scripts test` (the iteration-1 fix batch); the rest of the branch is context
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a2-i2.md (0 Incorrect); docs/reviews/api-consistency-review-2026-10-10-u3a2-i1.md (F1-F7); override-log rows 653-661

## Baseline Conventions

These are unchanged from iteration 1 (see the i1 report). The ones that matter here:

- **Usage errors:** bad usage prints one stderr line, `WHY (usage: ...)`, and exits 1 before any git call. Each mode has a single first-error message for its arity (`--settings takes no arguments`, `--status needs at least one brief path`).
- **Output:** each brief gets one verdict line first (`ok BRIEF TIP TREE`, `refuse BRIEF: WHY`, `skip BRIEF: WHY`), then `path`/`deny` rows. WHY is a lower-case clause naming the condition, with no git stderr and no worktree path.
- **Header:** the `-h` text is the contract, and literal strings that a consumer may match are quoted exactly.

## Status of iteration-1 findings

| i1 | Fix in f782d9ee | Verdict |
|---|---|---|
| F1 identity host-dependent | `git -c user.useConfigOnly=true var` | **Resolved.** I probed git 2.39.5 with `GIT_CONFIG_GLOBAL=/dev/null`. When all four `GIT_{AUTHOR,COMMITTER}_{NAME,EMAIL}` are set, git returns `n <e@x> ...`. With names plus `EMAIL` only, it fails with `fatal: no email was given and auto-detection is disabled`. With emails only, it fails with `fatal: no name was given ...`. A name from the environment plus an email from the global file gives `n <c@x>`. The `-c` pair outranks a global `user.useConfigOnly=false`. The refusal is now deterministic. The header wording is slightly broad (N2). |
| F2 usage order | The `--merge` arity check runs first | **Resolved.** I probed `--merge`, `--merge b`, `--merge --expect SHA` and `--merge b b --expect SHA`. All four print `--merge takes one brief path and --expect SHA`. `--check` keeps `--check needs at least one brief path` (same text as before, now literal rather than built from `$MODE`) and `--expect goes with exactly one brief path`. A bad `--expect` value (`abc`, given twice, or no value) still reports the `--expect` error first under both modes. That matches `--check`, so it is consistent (fact-check claim 25, Mostly accurate). |
| F3 reflog asymmetry | `GIT_REFLOG_ACTION="$msg"` on the fast-forward; the header names the message | **Mostly resolved.** Both paths now name the gate and the stem. The fast-forward appends git's `: Fast-forward`, and the test pins this (`build-loop.sh` bats line 101). The header states the text as exact (N1). |
| F4 path-line rule | `--check` rule: "(or --merge's own refusal of an ok verdict)"; `--merge` section: "with the path lines following" | **Resolved**, with one small wording mismatch (N3). |
| F5 `merged` field order | `merged BRIEF TIP TREE NEW` (code, header, both tests) | **Resolved.** Fields 1-4 now line up with `ok BRIEF TIP TREE`. The plan's Script interface (plan:213) still does not record the line. The header is the contract, so this is not a finding. |
| F6 `merged` word | No change | Settled (override row 660, Won't-Fix). |
| F7 policy refusal goes stale at `--approved` | The refusal moved from land into the merge arm, and a comment names U3a3 | Settled (row 661, Defer). The header now says outright that "a checkout refusal still names --check", which covers F7's other half. |

The other refusal texts that changed in the fix batch keep the established style:

- Rebase and bisect detection now reads files with `$(<...)` behind `-f` guards. The refusal texts are unchanged.
- Identity: the text gains "in git config".
- W check: `is missing, not its own top level, or not on it at SHA`.

All of them are lower-case clauses with no path and no git stderr.

## Name-Pattern Audit

The fix batch adds no new mode, flag, verdict word, trailer or variable that a consumer reads. It changes:

| Changed name / text | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `merged BRIEF TIP TREE NEW` (was `... NEW TIP TREE`) | output line | `ok BRIEF TIP TREE` | `scripts/build-loop.sh:155` (header `--check`), `:986-990` (verdict_ok) | Consistent: shares fields 1-4 with `ok`, and the extra field goes last |
| `--merge takes one brief path and --expect SHA` (now the only arity error) | usage error | `--settings takes no arguments`, `--status needs at least one brief path` | `scripts/build-loop.sh:279-280` | Consistent: one message per mode's arity |
| `--check needs at least one brief path` (literal, was `--$MODE ...`) | usage error | `--status needs at least one brief path` | `scripts/build-loop.sh:280` | Consistent, and unchanged for `--check` callers |
| `build-loop: self-merge of STEM[: Fast-forward]` | reflog message | git's `merge X: Fast-forward`, `commit: ...` | (no other reflog message in `scripts/`) | Consistent across both paths up to git's suffix (N1) |
| `... is missing, not its own top level, or not on it at SHA` | refusal WHY | `... is missing, or not on it at SHA` (i1), check_line's `could not be read` clauses | `scripts/build-loop.sh:1060-1062`, `:957` | Consistent style |
| `... or user.name and user.email in git config)` | refusal WHY | the i1 text without "in git config" | `scripts/build-loop.sh:1040` | Consistent; also more exact than the header (N2) |

## Findings

#### N1. The header gives the reflog message as exact, but the fast-forward path appends ": Fast-forward"

**Severity:** Minor
**Location:** `scripts/build-loop.sh:219-220` (header); `:1086-1096` (land's move)
**Move:** 3 (documentation drift), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
#                 without .md); its reflog entry reads "build-loop:
#                 self-merge of STEM". Author and committer from the
...
    git update-ref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
...
    GIT_REFLOG_ACTION="$msg" git -C "$w" -c gc.auto=0 -c maintenance.auto=false -c "branch.$MAIN.mergeOptions=" merge --ff-only -q "$NEW" > "$GATE_TMP/ff" 2>&1 \
```
and the test that pins the difference:
```
    [ "$(git reflog -1 --format=%gs main)" = "build-loop: self-merge of 2026-10-01-x: Fast-forward" ]
```

The CAS path writes exactly `build-loop: self-merge of STEM`. When W moves the branch, git's merge appends `: Fast-forward` to `GIT_REFLOG_ACTION`, and writes the same entry to W's HEAD reflog. Fact-check claim (header reflog text) is Mostly accurate for the same reason. A reflog reader written against the header's exact string would miss every landing done through W, which is the common case when the orchestrator runs from main's checkout. The trailer stays the primary record, so this is low impact. Only the wording promises more than the code does.

**Recommendation:** Word the header as a prefix, e.g. `its reflog entry reads "build-loop: self-merge of STEM" (git adds ": Fast-forward" when W moves it)`. Do not try to strip git's suffix.

#### N2. "Author and committer from the environment" is broader than what is accepted

**Severity:** Minor
**Location:** `scripts/build-loop.sh:220-223` (header); `:1005-1018` (merge_ident)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
#                 self-merge of STEM". Author and committer from the
#                 environment, or else git config (the caller's global file
#                 included, the system file not); git guessing one from the
#                 host refuses instead. With the branch checked out in no
```
```
    x="$(env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var "GIT_${w}_IDENT" 2>/dev/null)" || return 1
```

Under `user.useConfigOnly`, git takes only `GIT_{AUTHOR,COMMITTER}_{NAME,EMAIL}` from the environment. `EMAIL`, which plain git honours, now refuses. I probed this, and test 3's new step pins it. The refusal text names the right sources ("GIT_AUTHOR_NAME and the like, or user.name and user.email in git config"), so only the header is loose. The header also leaves out that each field resolves on its own: a name from the environment plus an email from config is accepted (probed: `n <c@x>`). This matches the fact-check's "'from the environment' too broad".

**Recommendation:** Change the header to `from GIT_AUTHOR_NAME/_EMAIL and GIT_COMMITTER_NAME/_EMAIL, or else git config ... (EMAIL alone is not enough; git guessing ... refuses)`.

#### N3. "the path lines following as after a --check refusal" names the wrong comparison

**Severity:** Informational
**Location:** `scripts/build-loop.sh:225-226`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
#             or refuse BRIEF: WHY, with the path lines following as after
#             a --check refusal, when: the policy --status reads is review;
```

A `--merge` refusal of an ok verdict is followed by the path lines of the ok line it replaces. Those are `path` rows only, never `deny`, because an ok verdict has none. Not every `--check` refusal has path lines: a conflict or a missing blob has none. The `--check` paragraph's own rule (line 167, "or --merge's own refusal of an ok verdict") is the exact one, so a careful reader gets it right. The `merged` line is not named there either, but the `--merge` section's "an ok verdict line becomes" covers it.

**Recommendation:** Optionally reword to "with the ok line's path lines following". No change is needed for correctness.

## What Looks Good

- **Usage:** every arity-malformed `--merge` now gives the same message, and `--check`'s messages are unchanged. The `--expect` value errors are shared by both modes and checked first in both, which is consistent. The test loop covers all three arity shapes.
- **`merged BRIEF TIP TREE NEW`:** a single field split now reads `ok` and `merged` alike, and code, header and tests agree.
- **Identity:** the identity contract no longer depends on the host. The refusal text now says exactly which sources count, and a test pins the `EMAIL`-only refusal.
- **Policy refusal:** it moved to the merge arm, so land holds no policy logic, as row 653 records. The text is unchanged, so consumers matching it are unaffected.
- **Header rewrite:** the refusal list now matches every `MERGE_WHY` in land:
  - listing failure, git-dir failure and "two worktrees" are named;
  - "not its own top level" and "git status fails or warns" are named;
  - the "Writes" paragraph now lists the reflog and W's index, HEAD reflog and ORIG_HEAD;
  - "Exit" covers `--merge` stopping part way.
- **Order:** the land comment's "decide, then write, then move" order matches the code (commit-tree after all W checks). It documents that a refusal after the write leaves NEW unreachable.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | Header gives the reflog text as exact; the ff path appends ": Fast-forward" | Minor | `scripts/build-loop.sh:219-220`, `:1093` | High |
| N2 | "from the environment" covers more than `GIT_*_NAME/EMAIL`; `EMAIL` alone refuses | Minor | `scripts/build-loop.sh:220-223` | High |
| N3 | "as after a --check refusal" should be "the ok line's path lines" | Informational | `scripts/build-loop.sh:225-226` | Medium |

## Overall Assessment

The fix batch resolves i1 F1, F2, F4 and F5 outright and F3 in substance. The `--merge` surface is now internally consistent and consistent with `--check`:

- one usage message per mode;
- `merged` shares `ok`'s leading fields;
- a deterministic identity rule, with a refusal text that names its sources;
- one reflog naming on both paths.

No fix introduces a break or a regression in the consumer-facing contract, and `--check`/`--status`/`--settings` output is unchanged. The two Minor findings are header wording only. The code does what a careful reader of the refusal texts expects, and the header overstates the reflog's exactness and the environment's reach. Each is a one-line comment fix with no test change, and they can be folded into the next commit or left. Neither blocks the merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/api-consistency-review-2026-10-10-u3a2-i2.md, structured per the api-consistency-reviewer skill.
- Answered:
  - Verified the iteration-1 api F1-F5 fixes against the code.
  - Checked the rewritten `--merge` header against land, merge_ident and the merge arm, each read in full.
  - Checked refusal wording consistency.
  - Probed the usage shapes and the identity rules under `user.useConfigOnly` in /tmp/u3a2i2-api-* (removed).
- Out of scope:
  - The security and performance of the fixes, including the surviving maintenance.auto and CHANGED mutants. Those are test-strategy inputs flagged by the fact-check.
  - The rubric's A1 (mergeOptions) beyond its surface effect. Test 4 exercises it, and the fact-check's mutant M1 fails it.
  - Bats suites were not run.
- Escalate: none.
