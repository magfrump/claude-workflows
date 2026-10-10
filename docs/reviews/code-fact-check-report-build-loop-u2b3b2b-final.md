Commit: 8f99fcaf
# Code Fact-Check Report

**Commit:** 8f99fcaf
**Replication:** k=3
**Repository:** claude-workflows, branch `feat/build-loop-u2b3b2b` (worktree `.claude/wt-build-loop-u2b3b2b`)
**Scope:** `main...HEAD` (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, test/lib/build-loop-fixtures.bash), the plan's U2b3b2b/U2b3b2c bullets, and the three commit messages
**Total claims checked:** 42 clusters (r1 29, r2 42, r3 32 claims; merged most-severe-wins)
**Summary:** 0 Incorrect on contract text but one (Claim 21) on a behaviour gap; 1 Incorrect commit-message wording (38b); 2 Stale; 8 Mostly accurate; 2 Unverifiable; the rest Verified. Replicate reports: `-final-r1.md`, `-final-r2.md`, `-final-r3.md`.

Only the claims requiring attention are restated below; Verified claims are in the replicate reports, each with its `Scope:` line.

## Claim 21: the C1 byte skip's justification ("the walks start there too")

**Location:** `scripts/lib/dev-cycle-read.sh:1241-1245`, code at `:1333-1337`
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Evidence:** The skip tests only that ROOT_REAL's copy is a start at the inner path; the f/p tag comes from the whole path. A worktree nested at `side/sub/.claude/skills/wt` holding a CLAUDE.md with ROOT_REAL's bytes is a prompt by its whole path, a plain start at the inner path: skipped, both walks miss `sub/z.md` (r3) or `sub/name.md` (r2); with one byte changed both answer imported.
**Scope:** covers the skip condition; does not establish any layout in this repository that triggers it (none does).
**Replicate verdicts:** r1=— · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r2: "introduced by iteration 2's whole-path start test (B3); fix by requiring the inner path's prompt class to match c, or name it" · r3: "narrow, inside the lib's over-inclusive prompt model"
**Legibility-target:** for-author

## Claim 38b: commit 8f99fcaf B1, "with_at … keeps links unread"

**Location:** commit 8f99fcaf message
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Evidence:** with_at greps an admitted link to a regular file; only links to non-regular files (/dev/zero, FIFO) stay unread, through outside_ok. outside_seeds keeps links whatever they hold.
**Scope:** covers the commit wording; behaviour is as the code comment states.
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=—
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 19: outside_seeds header, "isstart, by its path below its innermost root"

**Location:** `scripts/lib/dev-cycle-read.sh:1237-1238`
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Evidence:** since 8f99fcaf the code tests the whole lower-cased path; only the byte skip uses the inner path; the inline comment at `:1324-1327` is current.
**Scope:** header text only.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 1: plan bullet, plugin seeds and nesting rule

**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Evidence:** says `plugins/cache/**.md`; code reads installed_plugins.json's installPath values (whole cache on a parse failure); the nesting rule omits the below-ROOT_REAL case; iteration-2 changes (grep status, config link rule, whole-path isstart, 2 to 2.5 s) are absent.
**Scope:** plan text.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 9: walk header, "an unreadable directory in any registered worktree … fails every walk"

**Location:** `scripts/lib/dev-cycle-read.sh:754-758`
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** true for other worktrees; an unreadable directory in ROOT_REAL (not nested in another root) leaves the tree walk ok, the main walk fails.
**Scope:** header text.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 10: walk header timing line

**Location:** `scripts/lib/dev-cycle-read.sh:759-761`
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Evidence:** 50 seeds exactly; 2.1 to 3.1 s measured under load ~2; without seeds 0.6 s (tree), 0.8 s (main).
**Scope:** measurement at review time.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 11: scan's comment, "Every name starts at an @ byte"

**Location:** `scripts/lib/dev-cycle-read.sh:937-938`
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** holds for file text (quotes, splices, invalid UTF-8, NUL, fullwidth ＠); not for IMPORT_WHOLE input, which skips scan; with_at never reads seeds whole, and links are kept separately.
**Scope:** parser comment.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 12: byte-skip sentence omits conditions

**Location:** `scripts/lib/dev-cycle-read.sh:1241-1245`
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Evidence:** the code also requires the seed not be a link and ROOT_REAL's copy be a start at the inner path.
**Scope:** header text.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=—
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 3: plan U2b3b2c bullet

**Location:** `docs/working/plan-build-loop-handoff.md:307`
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Evidence:** "or alone, is read from ROOT_REAL's or main's copy": when only the other root holds the file, nothing is read; 6,720 seeds not reproducible (10,839 @-bearing .md files today, same order).
**Scope:** plan text.
**Replicate verdicts:** r1=Mostly accurate · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 32: commit 8f99fcaf, "Each new assertion is red on 39f64d62's lib"

**Location:** commit 8f99fcaf message
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** true for the behavioural assertions and with_at's inventory entry; root_starts' inventory entry passes there (39f64d62 defines it).
**Scope:** commit wording.
**Replicate verdicts:** r1=— · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: "the five suites pass at HEAD; each behavioural test red on its base"
**Legibility-target:** for-author

## Claim 40: commit 8f99fcaf, "same 1177 names"

**Location:** commit 8f99fcaf message
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** repo-name sets identical between 39f64d62 and HEAD (1210 today, the workspace changed); the lists differ by 35 `//opt/...` lines L1 drops on purpose.
**Scope:** commit wording.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 36: commit 1c820663 timings (7 s vs 0.7 s, 83 KB of // lines)

**Location:** commit 1c820663 message
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Evidence:** today 6 to 8 s at 1c820663 (r1, r3); the 83 KB figure depends on the registry then.
**Scope:** historical measurement.
**Replicate verdicts:** r1=Verified · r2=Unverifiable · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

## Escalations

- Claim 21 (`scripts/lib/dev-cycle-read.sh:1333-1337`), r2 + r3, addressee orchestrator/security-reviewer: fix (match the inner path's prompt class) or name the exception.

## Verdict stability

42 clusters; replicate agreement where two or more replicates reported a claim: 12 of 18 agreed; disagreements on Claims 21, 38b, 1, 10, 3, 32, 40, 36 (each above). Agreement rate about 67% on the shared clusters.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill, with a Goal-Alignment Note.
- Answered: yes — merged from three replicates, most-severe-wins.
- Out of scope: review artifacts under docs/reviews/.
- Escalate: Claim 21.
