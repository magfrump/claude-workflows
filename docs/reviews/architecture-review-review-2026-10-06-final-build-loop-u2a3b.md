Commit: e48cf0f7

# Architecture Review — feat/build-loop-u2a3b (iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test docs/working` at e48cf0f7 (main f6fdda68). Read in full: `scripts/lib/dev-cycle-read.sh:440-681` (walk header, IMPORTED init, UNI_SPACES, IMPORT_RE, lower, import_targets, instruction_names, untracked_md, nul_list, tree_starts, imported_names, main_imports, isimported), `scripts/dev-cycle.sh:170-186` (check_fix), the test diffs, known issue A5 and plan F11. main_imports is U2a3's code (context) except the lower guard at :657.
**Date:** 2026-10-06
**Based on:** `/tmp/.../scratchpad/fc-final-summary.md` (Stage-1 k=3 at e48cf0f7: no Incorrect/Stale; 5 Mostly accurate; escalations to test-strategy and security-reviewer only, none to this role).
**Trust-boundary map:** `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md` (Commit: `7ddff454`) — security review predates this diff; boundary may be stale. Labels B1-B5 cited below.

**Scope check:** in scope. Public APIs: the lib's walk contracts (imported_names now returns 1, IMPORTED starts as `error`, new helper `tree_starts`, check_fix's new branch). Cross-cutting: the shared token grammar and the fail-closed error pipeline both walks and `--check-fix` read. Settled override rows not re-filed: 347 (walks differ on purpose), 350 (A5 gaps), 346/355/363 (costs), and this unit's 2026-10-06 rows (inrepo_here asymmetry I2-C6, surviving mutants, sed costs). Finding 1 builds on the closed I2-A6 row with new evidence (stated there).

## Dependency Map

- `check_fix` (`scripts/dev-cycle.sh:170-186`) → static path filter → `imported_names` (walk-failed wording) → `isimported tree` → `check_path`. (B3)
- `imported_names` → `nul_list recs tree_starts` → {`git ls-files -z`, `untracked_md`, `instruction_names`} (B2); then `lower`, `inrepo_here`, **`import_targets`** per queued file. (B1)
- U2a4 floor (planned) → `isimported main` → `main_imports` → {`nul_list` × 2, `tr`, `git cat-file`, **`import_targets`**, `lower`}. (B5)
- `import_targets` → {`UNI_SPACES`, `IMPORT_RE`, `sed`, `grep`, `realpath`, `ROOT_REAL`} and, outward, Claude Code 2.1.292's import regex + marked lexer (B4).
- Direction is correct: callers depend on the predicate, the predicate on the walks, the walks on one parser and one listing primitive. No caller reads a cache variable. The single outward dependency is B4 (finding 1).

## Findings

#### 1. The grammar's revisit trigger is now recorded, but only where the repo's trigger harvester never looks, while the event it watches happens routinely

**Severity:** Minor
**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5), `docs/working/plan-build-loop-handoff.md:126` (F11), `scripts/lib/dev-cycle-read.sh:509-512`; harvester `scripts/dev-cycle.sh:262`; install `devcontainer-config/Dockerfile:19`, `:403`
**Move:** 1 (dependency direction), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
revisit trigger: a Claude Code upgrade that changes either, which can make the walks miss imports.
```
```
echo "Every trigger, in full: each decision record's \`## Revisit triggers\` section and each decision-log row that mentions revisiting, numbered or date-first (a trigger written elsewhere in a record, or in a docs/working/ design doc such as dd-*.md, is not found; ...
```
```
ARG CLAUDE_CODE_VERSION=latest
...
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

The iteration-2 Coupling finding (I2-A6) is fixed as asked: the version, source and trigger are in the code comment, A5 and F11, and its override row is closed. New evidence: all three places sit outside what the dev-cycle digest reads (decision records' `## Revisit triggers` and `docs/decisions/log.md` rows only; `docs/working/` is explicitly "not found"), so no cycle ever prints this trigger. Meanwhile Claude Code is installed at `latest` on every image build, and guides/devcontainer-setup.md makes staleness itself a decision-015 trigger, so upgrades are routine and encouraged. The gate's soundness (B4: walk token set must be a superset of what Claude Code resolves) therefore rides on an unwatched external contract whose drift fails open silently. The repo's precedent, log row 65, is harvested because it lives in the log.

**Recommendation:** Put the trigger where the digest reads it: a numbered `docs/decisions/log.md` row (or an amendment to row 65) naming `import_targets`, Claude Code 2.1.292 and "Revisit if a Claude Code upgrade changes its import regex or Markdown lexer (check on each image re-bless)". Optional and cheap: a bats tripwire that notes when the installed `claude --version` differs from the recorded one.

#### 2. The cross-reference calls test/agents-gemini-sync.bats' finder "another copy of the regex", which it is not, inviting a maintainer to sync the two by copying

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:512`; `docs/working/known-issues-dev-cycle.md:18` (A5)
**Move:** 7 (coupling)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# (test/agents-gemini-sync.bats pins another copy of the regex).
```
```
# Claude Code v2.1.284 (its extractor, read from the binary during review)
```
(test/agents-gemini-sync.bats:37)

Stage-1 fact-check rated this wording Mostly accurate (r1-r3). The architectural consequence: the two encodings serve different purposes (the sync test flags any `@` start, an over-approximating prefix finder for authored files; import_targets resolves full names for a gate) and are documented against different versions (2.1.284 vs 2.1.292). Labeling one a "copy" suggests they should be kept byte-identical; a future grammar update applied by copying either into the other would break the one it lands in. The iteration-2 recommendation was to cross-reference without merging.

**Recommendation:** Reword to "a separate, flag-only finder (log row 65, documented against 2.1.284); re-check both on the same trigger". Pairs naturally with finding 1's log row.

#### 3. Wording a failed walk takes two calls in a fixed order; U2a4's shared predicate should own that protocol once

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:181-184`; `scripts/lib/dev-cycle-read.sh:667-681`
**Move:** 3 (module boundary), 7
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
  elif ! imported_names; then
    echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
  elif isimported tree "$lp"; then
```
```
# imported (0), so a caller testing it with `if` refuses; a caller that words a
# failed walk runs the walk first (imported_names or main_imports, under if).
```
(isimported() read in full, :672-681.)

The protocol is sound and documented: `isimported` stays safe for a bare `if` caller (failure answers imported), and a caller that wants an accurate reason runs the walk first; the cache makes the second call free. It is mild control coupling: each caller must know the call order and that the walk name maps to a function name. Today there is one caller per walk. Plan U2a4 (`plan-build-loop-handoff.md:278`) builds "the shared check_fix/floor predicate"; if the floor re-implements the two-call sequence for `main` the protocol exists twice.

**Recommendation:** None for this unit. When U2a4 extracts the shared predicate, have it own the walk-failed / imported / not-imported three-way answer (e.g. a reason string or distinct status) so check_fix and the floor stop sequencing the calls themselves.

## Answers to the dispatch questions

- **One parser for both walks:** holds. `import_targets` is the only home of token rules (Unicode/NUL normalization, HTML-comment splice, cut-mark prefixes, strip set, resolution). Both walks call it identically (`< "$f"` vs a `git cat-file` pipe), and the new tests drive the same fixtures through both walks (`for w in tree main; do imps "$w" ...`), which pins the sharing behaviourally.
- **tree_starts + nul_list placement:** right. `tree_starts` is a one-line adapter turning a three-command pipeline into the single CMD that `nul_list` takes, with its own `local -; set -o pipefail`; the rc-marker check now exists once (I2-C3 closed, verified at :559, :568, :608, :617). My iteration-2 claim that a record equal to `rc=0` was a second invariant was wrong: probed in `/tmp/u2a3b-archf-Vx78` (removed), `printf 'a\0rc=0\0'` yields `[a rc=0]` rc 0 and an unterminated `rc=0` is rejected, so nul_list's one stated rule (output empty or NUL-terminated) is sufficient. tree_starts' start set differs from main's (`.claude/rules/`): settled row 347, not re-filed.
- **Fail-closed responsibilities:** layered cleanly. Parser returns 1 (sed and grep each checked; no pipe/here-string masking). Walk owns state: `IMPORTED=error` is now the initial value as for `IMPORTED_MAIN` (I2-C5 closed), set before every early return, and a cached error returns 1 again (:566), mirroring :605. Predicate owns policy (`isimported` answers imported for a failed walk or failed `lower`). Caller owns wording (finding 3). check_fix places the walk after the static filter, so paths the filter refuses never pay for or depend on the walk. The walk is written to be correct with set -e on or off (every command explicitly checked), so the header's parenthetical about callers (fact-check r2, :453) is wording, not a design dependency. The failing-`tr` exit at check_fix:175 (security escalation) is a pre-existing line outside this unit's structure. The inrepo_here asymmetry is settled (I2-C6).
- **Grammar coupling stated in code, A5, F11:** stated in all three with version and trigger (I2-A6 holds); findings 1 and 2 cover what remains.
- **Fit with U2a3c:** good. U2a3c's phase 2 seeds from main_imports' own checkout listing (:617, already through nul_list) and reads checkout files through the same `import_targets`; this unit adds to main_imports only the lower guard at :657, so stacking is low-conflict. tree_starts is not the right seed for U2a3c (different start set, row 347) and nothing couples them. One forward note: `import_targets` resolves lexically (`realpath -ms`); if A5's untraced "`..` after a directory link" shape is ever traced to physical resolution, the change lands in the shared parser and moves both walks at once, which is the intended single point but worth knowing when U2a3c adds checkout links.
- **Fit with U2a4:** `isimported main` contract is unchanged and now symmetric with tree; the floor will follow check_fix's walk-first pattern (finding 3).

## What Looks Good

- One parser, one listing primitive, one sentinel: both walks now share `import_targets`, `nul_list` and the `error` cache sentinel, so tree and main differ only where row 347 says they should.
- The cache sentinel cannot collide with data: a successful walk's value always begins with a newline, so `error` is unambiguous.
- `instruction_names` separates no-match from failure at its own boundary (`|| [[ $? -eq 1 ]]`).
- The `imps` helper now reports `imported_names`' return for tree (I2-C11), so tree-walk tests are no longer vacuous on positive assertions.
- The test suite pairs every new parser rule with both walks rather than one.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Grammar revisit trigger lives only in docs/working/ and a code comment, which the dev-cycle digest does not read; Claude Code installs at `latest` | Minor | `docs/working/known-issues-dev-cycle.md:18`; `scripts/dev-cycle.sh:262`; `devcontainer-config/Dockerfile:19` | Medium |
| 2 | "another copy of the regex" mislabels a separate flag-only finder at 2.1.284 | Informational | `scripts/lib/dev-cycle-read.sh:512`; known issues A5 | High |
| 3 | Two-call walk-first protocol lives in each caller; U2a4's shared predicate should own it | Informational | `scripts/dev-cycle.sh:181-184`; lib `:667-681` | Medium |

## Overall Assessment

The unit maintains and improves structure: the grammar, the listing check and the failure sentinel are each in one place, and fail-closed handling follows a clean parser → walk → predicate → caller split that U2a3c and U2a4 can stack on without rework. All iteration-2 architecture findings are fixed or settled and hold at e48cf0f7. No Structural or Coupling findings remain. The most important remaining concern is finding 1: the grammar dependency is now written down, but not where the repo's trigger machinery will ever surface it, so a routine Claude Code upgrade can silently make both walks fail open. No disagreement with the security review's boundary placement; none of the recommendations moves a boundary.

## Goal-Alignment Note

- Success criterion (verbatim): "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: e48cf0f7` line at the top."
- Met: saved at `docs/reviews/architecture-review-review-2026-10-06-final-build-loop-u2a3b.md` with `Commit: e48cf0f7` first.
- Fact-check escalations: none addressed to architecture-review; the security (failing tr at check_fix:175) and test-strategy escalations are acknowledged above and left to those roles.
- Execution: one probe (nul_list record/marker behaviour) in `/tmp/u2a3b-archf-Vx78` from `git archive HEAD`, under `timeout`, directory removed; no process left running. No worktree file written except this report.
- Routed claims (`[unverified — submitted as claim]`): (a) the dev-cycle digest never prints triggers written in `docs/working/` (from `scripts/dev-cycle.sh:262` and its harvester :264-356); (b) after this branch the rc=0 listing check is written only inside `nul_list`; (c) no caller reads `IMPORTED` or `IMPORTED_MAIN` without first running its walk.
