Commit: 83cdb005

# Test Strategy: feat/build-loop-u1d (U1a-U1c's deferred test gaps, and main_entry's pathform guard)

**Scope:** `git diff main...HEAD` (one commit, 83cdb005), checked against the deferred test-gap rows in docs/reviews/override-log.md (246, 279, 291, 295, 299, 304) and row 284's guard
**Reviewed:** 2026-10-06
**Method:** I ran mutants against a `git archive` copy of HEAD, with the stock suite and then with a proposed patch. The scratch dir is `.../scratchpad/review-u1d/test/`: `run.sh`, `mut.py`, `patch.py`, `proposed.diff`, and one `m-*` copy per mutant. Baseline: build-loop-read.bats passes 19/19, and the hermeticity lint passes.

## Test Conventions

- bats 1.5+ with `run --separate-stderr`. Each test builds a throwaway repo through `test/lib/build-loop-fixtures.bash`. The helpers are `settings`, `constraints`, `brief`, `work`, `tip`, `commit_all`, `settings_is`, `settings_like` and `line`.
- An assertion is `[ ... ] || { echo "$output"; return 1; }`. The file prefers exact strings, using a prefix only when the tail holds a SHA or a date.
- The suite's habit is to add a case to the existing test that owns the path (T3, T6, T7, T44, and the U1d tests), not to add a new `@test`. Every recommendation below follows that habit.
- Constraints: the hermeticity lint misreads an apostrophe inside double quotes, so skip messages must not contain `'`. The unit has a ~400-line cap and 118 lines are used. The proposed patch below is 22 changed lines (13 net added), for a total of about 140.

## Status of each deferred row

| Row | Item | Status at 83cdb005 | Evidence |
|---|---|---|---|
| 246 / 295 | U1b G7: "not an allowed glob form" and "twice" reasons | **Closed** | `settings_is` exact at bats:405-407 |
| 246 / 295 | U1b G8: review policy with a malformed never line | **Closed** | bats:409-410 |
| 246 / 295 | U1b G9: the slots line for an absent file / an unread file | **Partly closed**: absent at bats:419. The unread arm is open (G3). | mutant `slots-unread` survives the whole suite |
| 246 / 295 | U1b G11: `-h` | **Partly closed**: `--help` is tested. `-h` is open (G4). | mutant `h-flag` (drop `-h\|`) survives |
| 279 | U1b G1: a caller's GIT_CONFIG_COUNT | **Partly closed**: the guard is shown to apply after a caller pair. The comment's "pairs stay" is not asserted (G10). | mutant `cfg=0` survives (also FC Claim 14) |
| 279 | U1b G2: the fence half of the next-line rule | **Closed**: both directions, bats:412-415 | FC Claim 5 (M7a/M7b killed) |
| 279 | U1b G3: whitespace-only line is blank | **Partly closed**: spaces only. The tab in `[ \t]` is open (G9). | mutant `/^ *$/` survives |
| 291 | U1c C17: the NUL refusal (marker_kind's, build-loop.sh:284) | **Still open (G1).** The U1d "NUL" step tests a different guard: the lib's brief-file NUL refusal (FENCE_AWK, lib:217). dev-cycle.bats:1223 already covered that guard. | mutant `marker-nul` survives the whole suite |
| 291 | U1c C18: F31's open-only filter (build-loop.sh:315) | **Still open (G2).** It agrees with FC Claim 17. | mutant `open-filter` survives |
| 291 | Iteration-2 G3 (the range G2-G4 in row 291; the second half of C16): a bare `success:` | **Still open (G5)** | mutant `success:` (no `[^ \t]`) survives |
| 299 | U1c G3: no open brief on main (git grep exit 1) | **Closed** for the mutant that matters. Dropping `\|\| rc=$?` fails T28 and the U1d --status test. The `-gt 1`→`-ge 1` mutant is unobservable through `--status` (see What NOT to Test). | run `no-rc`: tests 16 and 19 fail |
| 299 | U1c G5: the CRLF `\r?` arm | **Closed** | FC Claim 19 (m3 fails at bats:448) |
| 299 | C19 G5: a 1-character stopped REASON | **Still open (G6)** | mutant `reason-1` survives |
| 299 | C19 G6: `Dispatched: 99` and an explicit `Dispatched: 0` | **Still open (G7)** | mutants `disp-99` and `disp-0` survive |
| 299 | C19 G7: a fenced `H2:` reads as skipped | **Still open (G8).** It is now pinnable: the help (build-loop.sh:35) settled "fences are skipped" (A13). | the fenced-ID mutant survives the HEAD suite |
| 304 | C30: the anchored `closed/` prefix | **Closed** | FC Claims 19 and 22 (m2 fails at bats:453). Dropping only the `#` is equivalent on every reachable path. |
| 304 | C29: the local `BRIEF` | **Closed for the mutant that can be observed** (moving the call, m1b fails at bats:457). Dropping only the local cannot be observed through the CLI (G12, deferred to U2). | FC Claim 22 |
| 284 | main_entry's own pathform guard | **Closed** for the `error` answer (dev-cycle.bats:1328-1335). Three of the four paths fail with the guard removed. "Before any read" in the title is not asserted (G11). | FC Claim 21 |

## Untested Paths Touched by the Change

Every row-listed gap I found open or partly open at 83cdb005, with its mutant. Every mutant named here survives the HEAD suite and is killed by the proposed patch.

- **G1** — scripts/build-loop.sh:284 — marker_kind's `bad it holds a NUL byte` refusal for a `handoff:` tip whose raw commit holds a NUL — not covered (row 291, C17). The U1d step at bats:458-461 asserts `line 2 holds a NUL byte, so the brief is not read`. That is the lib's FENCE_AWK refusal of a *brief file*, which dev-cycle.bats:1223 already tests through dev-cycle.sh. With line 284 deleted, `handoff: ready\n\n\0x` reads `ready`, because `%B` truncates at the NUL. The commit message and the test title ("NUL") both present row 291 as closed. Severity: medium (a silent `ready`, fail-open, on a hand-made object). Confidence: high (mutant run). Legibility-target: for-author.
- **G2** — scripts/build-loop.sh:315 — the `"${BRIEF[status]-}" == "Status: open"` filter on the *other* briefs F31 reads — not covered (row 291, C18). This repeats FC Claim 17. The U1d step "a done brief sharing an open brief's branch" never reaches line 315, because git grep (line 309) does not list a brief with no `Status: open` line. The filter can be observed only when git grep lists a brief whose *first* Status line is not open. brief_fields keeps the first line per key (lib:303). Severity: medium (fail closed, but it would silently stop dispatching an open brief). Confidence: high. Legibility-target: for-author.
- **G3** — scripts/build-loop.sh:212 — `SLOTS_LINE="slots 3 default: $why"` when the file is present but not read (FILE_WHY is not `absent`) — not covered (row 246, U1b G9's unread half). The FC Claim 24 annotation found the same thing. Severity: low. Confidence: high. Legibility-target: for-author.
- **G4** — scripts/build-loop.sh:99 — the `-h` alternative of `-h|--help)` — not covered (row 246, U1b G11). The new test runs only `--help`. Severity: low. Confidence: high. Legibility-target: for-author.
- **G5** — scripts/build-loop.sh:180 — a `success:` line with no text must not satisfy a pending hard constraint. Only `[^ \t]` enforces this — not covered (row 291's G2-G4 range, iteration-2 G3). The END-pending half of C16 is covered at bats:183. Severity: medium (a hard constraint with an empty success line would read `ok`, so the orchestrator would dispatch). Confidence: high. Legibility-target: for-author.
- **G6** — scripts/build-loop.sh:296 — the 1-character lower bound of a stopped REASON (the optional `(...)?` group) — not covered (row 299, C19 G5). The tests use 120 characters, 121 characters and a multi-word reason. Severity: low (fails closed: a valid `handoff: stopped: x` would skip). Confidence: high. Legibility-target: for-author.
- **G7** — scripts/build-loop.sh:333 — the accepted bounds `Dispatched: 0` (explicit) and `Dispatched: 99` — not covered (row 299, C19 G6). The tests accept only 1, 2 and 3, and reject 100, 01, -1, x and the empty value. Severity: low. Confidence: high. Legibility-target: for-author.
- **G8** — scripts/build-loop.sh:168 — a constraint line inside a fence is skipped (``` / `H2: hidden` / ``` reads `ok 1-hard 0-soft`) — not covered (row 299, C19 G7). The mutant `fence($0) && !/^(- )?[HS].../ { next }` survives the HEAD suite. The help now promises this behaviour, so the test pins a settled rule. Severity: low. Confidence: high. Legibility-target: for-author.
- **G9** — scripts/build-loop.sh:151 — the `\t` in `/^[ \t]*$/` (a tab-only line after the never line counts as blank) — partly covered. Spaces are covered at bats:416. Tabs are not (row 279, U1b G3, "can be narrowed"). Severity: low. Confidence: high. Legibility-target: for-author.
- **G10** — scripts/build-loop.sh:112 — `cfg="${GIT_CONFIG_COUNT:-0}"` keeps the caller's pairs and does not overwrite them — partly covered (row 279, U1b G1). The test comment at bats:420 says "pairs stay". A caller pair of `user.name` has no observable effect, so `cfg=0` (overwrite index 0) passes. FC Claim 14 found the same. Severity: low. Confidence: high. Legibility-target: for-author.
- **G11** — scripts/lib/dev-cycle-read.sh:263 — the pathform check runs *before* ls-tree — not asserted. The test title says "before any read". FC Claim 21 found that a mutant running pathform after the read passes. No difference in output can be seen. Severity: low (title wording). Confidence: high. Legibility-target: for-author.
- **G12** — scripts/build-loop.sh:305 — the `BRIEF=()` in `local -A n=() BRIEF=()` on its own — not covered, and it cannot be observed through the CLI today. status_line calls shared_branches (line 323) before `brief_fields "$a"` (line 328), so the call order protects BRIEF without the local. FC Claim 22 found that dropping only the local survives. Severity: low now. It becomes medium when U2's `--check` calls shared_branches after its own brief_fields. Confidence: high. Legibility-target: for-orchestrator-synthesis (a U2 obligation, not a U1d test).

## Recommended Tests

I checked the patch (scratch `proposed.diff`). The patched suite passes 19/19 on HEAD's script and passes the hermeticity lint. Each mutant named in G1-G10 then fails exactly one test, on the line added for it. The patch is 22 changed lines (13 net added), and it adds no new `@test`.

#### R1: a NUL in a marker commit is a skip (T7)
**Closes gaps:** G1 · **Type:** integration · **Priority:** high · **File:** test/scripts/build-loop-read.bats, T7, after bats:289 (the two-tree case; it reuses `check`, `$n`, `$base`)
**What it verifies:** a `handoff: ready` tip whose raw object holds a NUL is refused, not read as ready.
**Key cases:**
```
    o="$(printf 'tree %s\nparent %s\nauthor t <t> 0 +0000\ncommitter t <t> 0 +0000\n\nhandoff: ready\n\n\0x\n' "$(git rev-parse "$base^{tree}")" "$base" \
        | git hash-object -t commit --literally -w --stdin)" && git update-ref refs/heads/feat/a "$o" && check "skip $B: $n: it holds a NUL byte" nul
```
**Setup needed:** none beyond T7's. `--literally` is needed for the same reason as the two-tree object above it. Also retitle the U1d --status test or reword its NUL comment, so that it names *the brief's* NUL. It should not claim row 291's.

#### R2: F31's own open-only filter (U1d --status test)
**Closes gaps:** G2 · **Type:** integration · **Priority:** high · **File:** bats:440-441
**What it verifies:** a brief that git grep lists, but whose first Status line is `done`, does not count toward F31.
**Key cases:** replace the comment at :440 and add one line before `brief o`:
```
    # A done brief sharing an open brief's branch does not make the open one skip,
    # even with a later "Status: open" line that git grep lists (F31's own filter).
    printf 'Status: done\nBranch: feat/x\nStatus: open\n' > "$d" && commit_all d-later-open
```
The existing assertion at :443 (`ok $o open ...`) then fails under the mutant (`skip $o: another open brief ...`). The later steps are unaffected, because d stays done for F31.

#### R3: a hard constraint is not satisfied by a bare success:, and a fenced ID is skipped (T44)
**Closes gaps:** G5, G8 · **Type:** unit (awk via CLI) · **Priority:** high (G5) / low (G8) · **File:** T44, bats:183 (edit) and after :186
**Key cases:**
- `constraints '- S1: a' '- H1: b' '  success:'` is an edit of :183. The expected line stays `hard constraint H1 (line 2) has no success: line ...`.
- Add these lines:
```
    constraints '- H1: a' '  success: b' '```' 'H2: hidden' '```'; run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints ok 1-hard 0-soft: docs/constraints.md on the default branch" ] || { echo "$output"; return 1; }
```
(In the bats file, use T3's `local f=$'\x60\x60\x60'` to match house style.)

#### R4: accepted boundaries of a marker REASON and of Dispatched
**Closes gaps:** G6, G7 · **Type:** integration · **Priority:** low · **File:** T6 after bats:252, and the U1d --status test
**Key cases:**
- T6 (+2 lines):
```
    git update-ref refs/heads/feat/a feat/a~1 && tip feat/a "handoff: stopped: x" && run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review feat/a stopped "*" 2 x" ]] || { echo "$output"; return 1; }
```
- The U1d --status test (0 net lines): give d an explicit `'Dispatched: 0'` (:437; :439 already expects `- - 0`). Change o's `'Dispatched: 2'` to `'Dispatched: 99'` (:441), and change `- - 2` to `- - 99` in the three asserts at :443, :453 and :457.

#### R5: the settings file's smaller arms
**Closes gaps:** G3, G4, G9 · **Type:** integration · **Priority:** low · **File:** T3, the U1d --help test, the U1d --settings test
**Key cases:**
- T3, after bats:54 (`settings_is` already ran, so `$output` is set):
  `[ "$(line slots)" = "slots 3 default: the code fence opened at line 1 of docs/dev-cycle.md is never closed, so the file is not read" ] || { echo "$output"; return 1; }`
- --help test: wrap :429-431 in `for h in -h --help; do ... "$BL" "$h" ... done` (+2 lines, with the body indented).
- --settings test, :416: `'   '` becomes `$' \t '` (1 edited line).

#### R6: a caller's config pairs reach git (optional; or narrow the comment)
**Closes gaps:** G10 · **Type:** integration · **Priority:** low · **File:** the U1d --status test, before :458
**Key cases (+2 lines):**
```
    run --separate-stderr env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=grep.patternType GIT_CONFIG_VALUE_0=bogus bash "$BL" --status "$o"
    [ "$output" = "skip $o: the open briefs on the default branch could not be listed" ] || { echo "$output"; return 1; }
```
This pins the documented "the caller's own environment is trusted" contract (build-loop.sh:110-111). If the author does not want that contract pinned, a 0-line alternative closes G10 as a wording item. Reword bats:420 to "A caller's GIT_CONFIG_COUNT does not stop the guard" (FC Claim 14's precise version).

## What NOT to Test

- **G11 (pathform before ls-tree):** the order has no output effect. Asserting it would need a PATH shim for `git` that records calls, which is brittle and costs more lines than it saves. Retitle the test instead, to "main_entry answers error for a path pathform refuses" (0 lines).
- **G12 (the local BRIEF on its own):** it cannot be observed through `--status`. Record it as a U2 obligation instead. When `--check` calls shared_branches, its test must query a brief that is *not* the lexically last open brief. The q step at bats:454-457 is the template.
- **The exit-1 arm as `-ge 1` (FC Claim 16):** when git grep exits 1 there is no open brief on main, so SHARED_BRANCHES is never consulted, and the mutant is equivalent through `--status`. The mutant that does matter (dropping `|| rc=$?`) is killed.
- **The interior of --help (FC Claim 15):** the first and last lines pin the range. Pinning the interior would be a snapshot that breaks on every wording edit, which is the kind of brittleness this unit exists to avoid.
- **The `#` anchor on the closed/ substitution:** every path git grep returns starts with `docs/working/briefs/`, so the unanchored form is equivalent.
- **A fence followed directly by the end of the file (next-line rule):** NEXT starts at 1 and only a non-fence line clears it. Both directions are already pinned, and no plausible mutant separates the end-of-file case.
- **Comment placement (FC Claim 18):** the CRLF step's "keeps its own Dispatched value" belongs to the q step. That is a wording move, not a missing test.

## Coverage Gaps Beyond Current Scope

**1.** The FC escalation (r3): under a broken git config (`grep.patternType bogus`), check_branch's ahead count comes back empty. A done brief one commit ahead then printed `ok ... working` with an empty DATE instead of the marker skip. No test runs `--status` on a branch that is ahead under a failing config. If security-reviewer calls this fail-open, the test belongs with that fix, in U2 or a follow-up, not here.

**2.** build-loop.sh:16-18 (FC Claim 1): no test pins the wording's distinction between a never copy hidden from the count with an exact line beside it (self-merge stays on) and a counted copy (two copies, so malformed). If the wording is fixed in this unit, one `settings` case each (`- [x] Self-merge never: a/` + `Self-merge never: none` → `policy self-merge set`) would pin it.

## Summary

U1d closes most of what the rows named. The glob-form and "twice" reasons, review with a malformed never line, the absent-file slots line, both halves of the fence rule, the no-match and CRLF arms, the closed/ anchor, the moved-call BRIEF regression and main_entry's `error` answer are all now killed by a test. The highest-value remaining test is R1: row 291's NUL refusal is **still open**. The U1d "NUL" step tests the brief-file refusal, which was already tested, and not marker_kind's commit-NUL guard. So the commit message and test title overstate what closed. Row 291's other half, F31's open-only filter (R2), is also still open, as FC Claim 17 found, and a bare `success:` (R3) is an untested medium path in the same row's range. Row 299's C19 trio (1-character reason, Dispatched 0/99, fenced H2) received no tests. All of these close with a verified 22-line patch, at about 140 of 400 lines. The main residual risk after the patch is G12, the local BRIEF, which cannot be observed until U2's `--check` changes the call order.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-build-loop-u1d.md (first line `Commit: 83cdb005`), structured per the test-strategy skill.
- Answered: yes. Every deferred row (246, 279, 291, 295, 299, 304, and 284's guard) has a status, and every open gap has a concrete test that was verified against its mutant.
- Out of scope: the code fixes behind FC Claims 1 and 3 (wording), and the security escalation (Beyond Scope 1).
- Escalate: G1 to the orchestrator, because the commit message and the U1d test title claim row 291's NUL item as resolved, but it is not.
