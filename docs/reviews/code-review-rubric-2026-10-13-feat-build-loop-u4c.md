Commit: 1bc823ea

# Code Review Rubric: feat/build-loop-u4c

**Scope:** `main...HEAD` (full branch, first pass of the loop) · **Delivery mode:** self-read (agents read a shared preamble file and their own skill file; the diff is ~330 lines) ·
**Fact-check:** k=1 (loop pass, decision 031) ·
`docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md`

## Iteration 1 (1bc823ea): full panel

Fact-check: 33 claims; 21 Verified, 6 Mostly accurate, 1 Stale, 4 Incorrect, 1 Unverifiable. No
behavioural red (the Incorrects are a row mis-citation and an overbroad guarantee in prose), so
no short-circuit. Critics: security (3 Low, 1 Informational), api-consistency (6, none Breaking),
architecture (1 Coupling, 2 Minor, 2 Informational), performance (1 Informational; ~3x cheaper
per call, cost no longer grows with history). Health check passed at 1bc823ea.

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| B1 | The Rule and the block header say nothing the uid / a loop can write chooses or changes what runs; PATH (`/home/node/.elan/bin`, uid-writable), exported `BASH_FUNC_*` functions (executed: a `stat` function made own() accept uid-owned files) and settings still reach the shell | SKILL.md Rules, block header | fact-check 11b/15b (Incorrect), security F1 (Low) | Fixed: both claim only that no repository data chooses the script; the same-uid shell is named as the Q-103 residual |
| B2 | Plan as-built note and commit cite row 739 for the canonical copy (it is 738), and rows 741/742 for the reader (they are 740/741) | plan U4c note; 1bc823ea | fact-check 6, 30b; performance | Fixed in the plan; the commit message is an Accepted-immutable row |
| B3 | Plan still describes main's-copy D6 (D6 heading, F39, F40, T33 row, "the gate does not wait" twice, D5 item 3's "live at the next merge" framing, Rollback 1 assumes a revert fixes the gate) | plan :71, :77, :157-158, :356, :396, :432, Rollback | fact-check 3 (Stale), api F2, architecture 2 | Fixed |
| B4 | Nothing tracks the image lagging main: a reviewed gate fix protects nothing until a rebuild, and no output names which image runs | SKILL.md step 0 | architecture 1 (Coupling), security F3 | Fixed: step 0.1 compares the `.manifest` commit with main over `scripts/` and `skills/dev-cycle/` and files an `image-lag` `you: terminal` entry (executed by hand: exit 1 today) |
| B5 | questions.sh added to the block but the Rules' call and timeout sentences name two scripts; step 1's "note it and go on" contradicts the `refuse d6:` stop | SKILL.md Rules, step 1 | api F1 | Fixed |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C1 | The header dropped "it does not check the .git entry", which still picks the repository the scripts read | security F2 | Fixed: restored with refs/heads/main |
| C2 | A missing image file is refused as "not root-owned..." (reads as tampering, not an old image); the test asserted the stub's text | api F3, fact-check | Fixed: own() refuses "is missing" first; a test runs the real snippet on it |
| C3 | questions.sh through the block follows the caller's QUESTIONS_LIVE/ARCHIVE | security F4 | Fixed: the launch `env -u`s both |
| C4 | Header: "each step names MAIN_WT or WT" omits GT; row 548 covers only dev-cycle.sh; "each sources the lib" untrue of questions.sh; plan "below" is the same bullet | fact-check (Mostly accurate) | Fixed |
| C5 | `d6_copy` treats any second argument as trust | api F5 | Fixed: the literal `trust` |
| C6 | The block's git checks are now dev-cycle.sh's and questions.sh's only state gate; three HARDEN copies | architecture 3 | Deferred (override row) |
| C7 | Directory walk tested only on /opt's success path | fact-check | Deferred (override row) |
| C8 | Nine stat forks per call | performance | Won't-Fix (override row) |
| C9 | questions.sh hints print the forbidden path; step 3's "questions.sh missing" unreachable via the block | api F4, F6 | Won't-Fix (override row) |
| C10 | T33's "names no other copy" is a grep for reader commands, not a proof | fact-check | Fixed in wording (the plan note names the run test as the behavioural check) |
| C11 | The -w-as-root claim needs a root run | fact-check (Unverifiable) | Open: no root here |

## ⏭️ Skipped Core Critics

None. Contextual: test-strategy not triggered (tests changed with source), tech-debt-triage not triggered (6 files, <500 lines), dependency-upgrade and ui-visual-review not triggered.

## Considered overrides

Rows 735 (refuse d6 handling), 736/737 (HARDEN copies, precedence), 738 (canonical copy: discharged, SKILL.md), 739 (trust root: closed by Q-140 [1]), 740/741 (reader cost and seam: discharged, the reader is gone), 742 (environmental refusals: the perl/temp-dir ones are gone), 743 (fork-overhead figures: superseded by i1 performance), 744 (timeout: the Rules' stop), 775 (questions.sh via ~/.claude/scripts: discharged), 807 (U4b2 F1: fixed in step 0.4), 808-811 (re-keyed, override row).

## Iteration 2 (33ad1767): fix range 1bc823ea..33ad1767

Fact-check (k=1, `docs/reviews/code-fact-check-report-2026-10-13-u4c-i2.md`): 30 claims; 22 Verified,
7 Mostly accurate, 1 Unverifiable, no Incorrect or Stale. Fixed before the critics ran: step 0.1's
diff narrowed to GATE_CODE's paths (it read all of `scripts/`, where health-check.sh differs today),
"built" → "holds" the image's commit, the release named as install.sh then the next sandbox launch,
a missing manifest or a failed command noted in the record; step 1 names the timeout stop; the
header says the default branch's ref; Rollback 1 scoped to gate-code reverts; the T33 wording on
questions.sh's lib. Row 817's "only the D6 block, its Rules and step 0.1" also omits steps 0.4 and
1 and the deleted fallback (Mostly accurate; its conclusion holds; rows are append-only).

## Status

Iteration 1 found no 🔴 and five 🟡, fixed in 33ad1767 (B2's commit-message half an Accepted-immutable row). Health check passed at 1bc823ea (run in the session; log not committed).
