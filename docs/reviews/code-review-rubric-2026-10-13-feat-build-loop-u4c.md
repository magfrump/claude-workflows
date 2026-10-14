Commit: a80955a2
Loop closed at a80955a2

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

Critics over 1bc823ea..f2cc21e6 (performance skipped: the range adds two git calls per iteration):
security (`security-review-2026-10-13-u4c-i2.md`: 1 Medium, 1 Low, 2 Informational; i1 F1-F4
closed but the Rule's wording; new own() executed equal to the old on 11 paths), api-consistency
(`api-consistency-review-2026-10-13-u4c-i2.md`: 3 Inconsistent, 2 Minor, 1 Informational, none
Breaking), architecture (`architecture-review-2026-10-13-u4c-i2.md`: 2 Coupling, 2 Minor).

| ID | Finding | Source | Status |
|---|---|---|---|
| D1 | The image is built from the host checkout's HEAD, not main: a release run off main installs unreviewed gate code, which step 0.1 called "older" and prescribed the same rebuild for | security i2 F1 (Medium) | Fixed: `merge-base --is-ancestor C M` files `image-off-main` (you: judgment); the paste checks HEAD equals main's commit (`cd A && test "$(git rev-parse HEAD)" = M && install.sh`) |
| D2 | Step 0.1's path list is an unpinned fourth copy of GATE_CODE, wrapped over lines | architecture i2 1, api i2 F4, security i2 F4 | Fixed: one line, pinned with GATE_CODE by a new test |
| D3 | `image-lag` has no body, paste block, interim or close rule; overlaps U5's release entry | architecture i2 2, api i2 F1/F2, security i2 F2 | Fixed: body (C, M, changed names), paste, interim; exit 0 answers it `done`; plan :356 makes U5's release entry its body |
| D4 | "older than main's" where the test is "differs"; `cat-file` failing (every other repository) read as "any other exit: note it" | architecture i2 3/4, api i2 F6 | Fixed |
| D5 | A `--state` refusal for a missing image file is the same release remedy, filed as a stop entry | api i2 F3 | Fixed: the stop's entry gives the release paste |
| D6 | Rule: "no file or repository state" still covers a planted PATH binary | security i2 F3 | Fixed: "no repository file or state" |
| D7 | Step 9 never says what `questions.sh check` exit 1 means | api i2 F5 | Fixed |
| D8 | The GATE_CODE check lower-cases paths; the pathspec is case-sensitive | api i2 F4 | Won't-Fix (override row) |
| D9 | A fork holding C compares unrelated gate code (noise); deleting C's objects drops the check to a record note (corrected by row 820: deleting C's commit object now skips silently) | security i2 (not tested) | Won't-Fix (override rows 819, 820) |

## Final confirming pass (43b8d7ed): full branch, k=3, full panel

Fact-check (k=3 merged, `code-fact-check-report-2026-10-13-u4c-final.md`): 41 clusters, no
behavioural Incorrect; 1 new doc Incorrect (row 819 / D9), 3 Stale plan lines, 12 Mostly
accurate; agreement ~80%. Critics: performance (1 Informational), architecture (2 Minor, 3
Informational; no Structural or Coupling), api-consistency (1 Inconsistent introduced, 3 Minor,
1 Informational), security (1 Medium introduced, 3 Low). Health check passed at 43b8d7ed.

**Gate:** a Medium (security final F1) and an Inconsistent (api final F1) introduced by the
range stop the merge and go to the user: Q-144, interim [1] (the Q-138 / Q-141 / Q-142 precedent).

| ID | Finding | Source | Status |
|---|---|---|---|
| E1 | `merge-base --is-ancestor` passes any merged branch's own commit, so an image released from a branch under review reads as on main and files the mechanical `image-lag` (executed: 6beca252) | security final F1 (Medium) | Interim fix: C is on main only on `rev-list --first-parent M` (executed: 774a0eef on, 6beca252 not) |
| E2 | `image-off-main` unkeyed, its answer never read (a keep re-filed each iteration), never closed | api final F1 (Inconsistent), security final F3, architecture final 1 | Interim fix: `image-off-main-C12`, suppressed by any entry in WT's questions files (as the step 0 siblings), numbered options |
| E3 | The orchestrator answering `image-lag` `done` itself breaks D8 (`--cycle-diff` refuses it without `--answered`) | security final F2 | Interim fix: listed in the final message for the user to answer |
| E4 | No `commit=` line makes C empty and the silent skip fire before "note it" | fact-check claim 6, architecture final 2, api final F3 | Interim fix: the manifest is read first |
| E5 | The paste does not check the working-tree install.sh | security final F4 (pre-existing) | Interim fix (row 821) |
| E6 | Doc: row 819 / D9 consequence; plan :71, :77, :156, :394, :400, :432 and the as-built note; lib comment "built from main"; step 9's check exit 1; the pin test's name | fact-check claims 1, 3, 5-8; api final F4 | Fixed (row 820 amends 819) |

## Second confirming pass (e58adc1f): Q-144 interim [1], k=1 fact-check + security

Fact-check (`code-fact-check-report-2026-10-14-u4c-confirm.md`): 24 claims, no behavioural
Incorrect, no Inconsistent; 1 Incorrect in the pin test's name (E6 overstated it), 1 Stale, 5
Mostly accurate. Security (`security-review-2026-10-14-u4c-confirm.md`): final F1-F4 and api F1
closed (6beca252 now reads off main; 774a0eef and 3943ab1c on it), but **one Medium introduced
by the interim**: E5's `git diff --quiet HEAD -- devcontainer-config/install.sh` ran on the host
before install.sh's state gate, so a planted `core.fsmonitor` or clean filter ran (executed).

| ID | Finding | Source | Status |
|---|---|---|---|
| F1 | E5's host-side diff runs planted fsmonitor/filter config before install.sh's gate | confirm2 security F1 (Medium, introduced) | Reverted (row 822); the paste is again `test HEAD = M && install.sh` |
| F2 | Any `image-off-main-C12` entry, even answered [1], suppresses refiling for that C if the rebuild never happens | confirm2 security F2 (Low) | Open: for Q-144 |
| F3 | The pin test's name claims both directions | confirm2 fact-check 22b | Fixed: the name says what it checks |
| F4 | Step 0.1 asked the user to answer `done`, not an `image-off-main` option; lib comment "built from main" | confirm2 fact-check | Fixed |

**Gate:** two confirming passes have each found a Medium introduced by their range (the second
by the interim fix itself), so U4c does not merge on the interim: it waits for Q-144's answer
(the Q-143 precedent). The revert returns the paste to text the full panel reviewed at 43b8d7ed.

## Third confirming pass (18fd4e1e): Q-144 answered [1], security only

Security (`security-review-2026-10-14-u4c-confirm3.md`): the revert fully removes confirm2 F1;
step 0.1's sandbox calls all run through `hg` after `--state`. **One Medium** (judged introduced;
arguably implied at 43b8d7ed): `image-off-main`'s [1] told the user to check main out on the
host, and a host `git checkout` runs planted hooks, fsmonitor and filters before install.sh's
state gate (which never inspects hooks); 18fd4e1e's "the state gate runs before any other git
call" was false on that route (executed in a scratch repo).

| ID | Finding | Source | Status |
|---|---|---|---|
| G1 | Host checkout instruction and the overbroad state-gate claim | confirm3 security F1 (Medium) | Fixed: [1] names only the paste (which refuses until HEAD is at M); the claim is scoped to the paste's one `rev-parse`, and any other host git command is named as install.sh's own trust model. A sandbox checkout (security's suggestion) is refused by the Rules (the orchestrator never switches a branch in a checkout it did not create). |
| G2 | Whatever moves host HEAD to M happens outside the paste | confirm3 security F2 (Informational, pre-existing) | Named in G1's sentence |

Narrow check of a80955a2 (`security-review-2026-10-14-u4c-confirm3b.md`): closes confirm3 F1;
the paste's `rev-parse` executed against planted hooks (both locations), fsmonitor, filters,
textconv, pager and others ran none of them; nothing Medium or above introduced; one Low (the
host-git warning is not stated to be copied into the `image-off-main-C12` entry), same shape as
confirm3 F2.

## Status

Iteration 1 found no 🔴 and five 🟡, fixed in 33ad1767 (B2's commit-message half an Accepted-immutable row). Health check passed at 1bc823ea (run in the session; log not committed).
Final confirming pass not clean (E1, E2): Q-144, interim [1] applied; a k=1 fact-check and security pass over the interim fix decides the merge.
Second confirming pass not clean (F1, now reverted): U4c waits for Q-144.
Third confirming pass and its narrow check clean at a80955a2: merged on Q-144 [1] (the user: "do one more security pass, then merge").
