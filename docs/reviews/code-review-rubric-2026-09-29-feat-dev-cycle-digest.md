Commit: b88a9c4 (digest) / 79b1bfe (skill, feat/dev-cycle)
Loop-pass short-circuit: used at ef0471c / 5e8bfd9

# Code Review Rubric

**Scope:** feat/dev-cycle-digest vs main (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats): the lower unit of the size-gate split of feat/dev-cycle | **Reviewed:** 2026-09-29; final pass 3 on 2026-09-30; final pass 4 and the delta confirming pass 5 on 2026-10-01 | **Status: 🔴 DOES NOT PASS** — 1 red item unresolved (final pass 5 on 28c6178 / c079e8c; see that section). Pass 5 confirmed every final-pass-4 fix but one partial; the findings go back to the user.

Loop:
1. **Iteration 1:** pass 1 on the combined unit (89a3d3b); rubric `code-review-rubric-2026-09-29-feat-dev-cycle.md`.
2. **Iteration 2, final pass 1 on 3aee138:** k=3 fact-check, security, performance, api-consistency. Architecture-review was not run (a single script, no module structure).

Considered overrides: no prior overrides matched this diff.

---

## 🔴 Must Fix

None. Security confirmed the option-name fix complete: 7 bypass shapes, no execution or write.

## 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | "Changed since" used HEAD's commit date: a record committed on a branch before the window, merged inside it, was carried forward though no cycle judged it. Uncommitted records were also carried | fact-check r3 (Incorrect), r1, r2; api F2 | ✅ Fixed: first-parent history of the default branch, plus `git status` for uncommitted records; test |
| A2 | With an explicit `--since`, the digest said "No earlier cycle record" | fact-check r1, r2, r3 (Incorrect) | ✅ Fixed; test |
| A3 | "(last changed )" / "last changed ." for uncommitted files; the fallback never fired | fact-check r1, r3; api F2 | ✅ Fixed ("never: uncommitted") |
| A4 | SIGPIPE: `printf \| head -30` exits 141 mid-digest with ~1,000+ merges | fact-check r1 | ✅ Fixed (`sed -n '1,30p'`); untested (override log) |
| A5 | Header says "on `main`", but triggers and roadmap come from the working tree | api F1 | ✅ Fixed (the Window line states both sources) |
| A6 | Carry-forward is file-level, so the digest barely shrinks at the skill's cadence | performance final #1 (Medium) | 🟡 Deferred (override log; revisit trigger; roadmap Ideas). The unit is at the 400-line cap |

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | `--since=2026-13-45` accepted | ✅ Fixed (real date required); test |
| C2 | `DEV_CYCLE_TODAY` did not pin the 14-day default | ✅ Fixed |
| C3 | "writes nothing" / exit-code list incomplete; seed comment overclaimed | ✅ Fixed (wording) |
| C4 | Record/roadmap text could imitate digest headings | ✅ Fixed (quoted with `> `) |
| C5 | Terminal control codes in merge subjects | ✅ Fixed (stripped) |
| C6 | Future-dated cycle record would carry every trigger | ✅ Fixed (ignored); test |
| C7 | `--sample=0` said "No merges in the window" | ✅ Fixed |
| C8 | Untested: capitalised-Revisit preference; row dated exactly on SINCE | ✅ Fixed (tests extended) |
| C9 | Option-name test needs both defences removed to fail; carried list not machine-splittable; symlinked roadmap followed | 🟢 Won't-Fix (override log / informational) |

Size: the unit stays ≤400 changed code lines (396) after the fixes. Comments and section echoes were compressed; output is unchanged apart from the fixes.

---

## Final pass 2 (iteration 3, on de53069)

| # | Finding | Source | Status |
|---|---|---|---|
| F1 | Records reaching main by fast-forward, or existing only on the checked-out branch, were carried forward unjudged | api final2 F1 (High); fact-check r1, r2, r3 | ✅ Fixed (baa46e3): compare the trigger section at the recorded window start ("Main at:") with the working tree; tests |
| F2 | `git status` rewrote .git/index (lock contention in the shared checkout; "writes nothing" false) | security final2 #2; fact-check r2 (Incorrect), r1, r3 | ✅ Fixed (no git status call) |
| F3 | Control codes stripped only from merge subjects; rubric C5 had claimed fixed | security final2 #1 (Medium) | ✅ Fixed (one filter on all output); test |
| F4 | Header: failed step "exits 1" (it exits with the command's code) | fact-check r1 (Incorrect) | ✅ Fixed (wording) |
| F5 | File names as pathspec wildcards; newline in a file name forges a line | security final2 #3, #4 | ✅ Fixed (literal pathspecs; newline replaced) |
| F6 | Two spellings of "uncommitted"; Window line imprecise; "last committed" reads the current branch | api final2 F2; fact-check | ✅ Fixed (one spelling; labelled "on this branch") |
| F7 | File-level carry-forward cost (earlier deferral) | performance | ✅ Resolved by F1's design |
| F8 | TAB kept by the control filter; `--since` with no value prints bash's message; DEV_CYCLE_TODAY not in --help | fact-check, api | 🟢 Won't-Fix (tab is layout; exit code correct; test hook) |

**Gate (review-fix-loop hard cap): escalate.** The unit changed after its last full pass. It is held unmerged, with Q-100 in docs/working/questions.md on feat/dev-cycle. That entry offers two choices: a fourth full pass, or merge on the evidence above.

---

## Final pass 3 (iteration 4, on baa46e3)

**Status: 🔴 DOES NOT PASS — 3 red item(s) unresolved. Not clean; nothing was fixed (the loop cap is exhausted). The findings go back to the user under Q-100.**

This pass is the user's Q-100 [1]. Full branch 4225753..baa46e3 (65bd433 adds only review artifacts). The panel matched the earlier final passes. Fact-check ran k=3 on opus (22 Verified, 7 Mostly accurate, 1 Stale, 3 Incorrect, 1 Unverifiable; verdict agreement 28/34 ≈ 82%), then the security, performance and api-consistency critics, all on opus. Architecture-review was not run, as before. Artifacts: `code-fact-check-report-digest-final3.md` (merged), `code-fact-check-report-r{1,2,3}-digest-final3.md`, `security-review-2026-09-30-digest-final3.md`, `performance-review-2026-09-30-digest-final3.md`, `api-consistency-review-2026-09-30-digest-final3.md`, `execution-logs/*digest-final3*`.

Process notes:
- Delivery mode was self-read: each agent read the brief and its skill file from disk, not pasted.
- Another session overwrote the shared brief file in the scratchpad at 14:06, which was after the fact-check replicates had read it and before the critics started. All three critics noticed and took their scope from the dispatch prompt and the Stage-1 summary. The orchestrator sent security a correction, and every report covers this unit.
- The Fact-Check Gate did not pause, because the user's Q-100 answer asked for the full panel.
- Stage 2.5 was skipped. Security routed 3 endorsement claims (no .git writes, literal pathspecs, no truncation race) and performance routed 1. The first two already have executed Stage-1 verdicts (merged Claims 14 and 17). The rest are pending execution verification. The verdict does not depend on them.

### 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | F5 is only half fixed. A newline in a *carried* record's file name still forges digest lines, because only the `###` heading replaces LF. Scenario: a committed `docs/decisions/002-a⏎Main at: 0000…md` whose triggers are unchanged prints a bare `Main at:` line (or a `## 3.` heading) inside section 2, and the agent copies it into the next cycle record. | Correctness/Security | Fact-check Incorrect (high, executed, 3/3); security Medium | Fact-check r1+r2+r3; security #1 | `scripts/dev-cycle.sh:122,141` | for-author | — | 🔴 Unresolved |
| R2 | F1 is fixed only when the record's "Main at:" line is verbatim, full and an ancestor. Otherwise `:109` silently guesses the window start from committer dates, and an old-dated fast-forwarded commit becomes the base itself. Scenario: the last record says `- Main at: <sha>` (bulleted), and a 2020-dated record fast-forwarded into main in the window, plus one committed today, are "Carried forward" unjudged. | Correctness | Fact-check Incorrect (high, executed; r1 Incorrect, r2/r3 Mostly accurate); security Medium (Low conf.); api Inconsistent | Fact-check r1 (r2, r3); security #3; api F1 | `scripts/dev-cycle.sh:108-109,116` | for-author | — | 🔴 Unresolved; composed → X1 |
| R3 | Section 1 counts and the section 4 sample walk with `--since`, which stops at the first old-dated commit. Scenario: one old-dated commit fast-forwarded onto main makes the digest print "0 merge(s) … 0 commit(s)" and "No merges in the window to sample", even with a valid "Main at:" line. It has been there since 3aee138, and test 3 builds this scenario but does not check section 1. | Correctness/Security | Fact-check Incorrect (high, executed, r1 only); security Medium (reproduced) | Fact-check r1; security #4 | `scripts/dev-cycle.sh:89-91` (flows to :170-174) | for-author | — | 🔴 Unresolved |

### 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The record regex accepts 7–39-hex short shas, which git resolves through ref names first. A tag named like the short sha moves the window start, and a weakened trigger is carried unjudged (`:108-109`). | Security | Medium (Low conf.) | security #2 | for-author | — | 🟡 Open; composed → X1 | — |
| A2 | F3 is only partly fixed. The `:42` filter covers stdout only, and stderr is unfiltered: an ESC-named symlink put OSC 52 on stderr through the `grep` at `:112`. On stdout, C1 (U+009B), bidi U+202E and Unicode tag characters pass. | Security | Medium (Low conf.); fact-check Mostly accurate 3/3 | security #5; fact-check Claim 4 | for-author | F8 row (TAB Won't-Fix) does not cover C1/stderr | 🟡 Open | — |
| A3 | The "Main at:" contract with the skill accepts only the bare form. A decorated, lowercase-key, uppercase-hex, missing or non-ancestor line falls back silently, and the digest never names the base it used or where it came from (`:107-109`; skill `SKILL.md:137`). | API | Inconsistent; fact-check Mostly accurate (Claim 7) | api F1; fact-check r1, r2, r3 | for-author | — | 🟡 Open; composed → X1 | — |
| A4 | F6 is only partly fixed. The Window line is fixed text: it says "compared with `main` at the window start" even with `--since` or no record, never names the compared commit, and omits that log rows are chosen by date (`:84`). | API | Inconsistent; fact-check Mostly accurate 3/3 | api F2; fact-check Claim 5 | for-author | — | 🟡 Open | — |
| A5 | `:99` says "changed since $SINCE", but the code compares against the recorded commit. Triggers edited on the start day before that commit are carried. | API/Docs | fact-check Mostly accurate 3/3; api Minor | fact-check Claim 6; api F3 | for-author | — | 🟡 Open | — |
| A6 | A new record whose `## Revisit triggers` section is empty compares equal to "absent at base" and is listed as carried (`:116`). | Correctness | fact-check Mostly accurate (r1, r2) | fact-check Claim 8 | for-author | — | 🟡 Open | — |

### 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Records appear as `docs/decisions/x.md` when printed but `x.md` when carried, while the skill keys verdicts on "the name the digest prints" (`:119,122`; SKILL.md:153) | api F4 | Minor | for-author | "Carried forward not machine-splittable" (Won't-Fix): the new evidence is that the skill now keys on names | 🟢 Open |
| C2 | `--help` does not say that `--since` turns off carry-forward, or what the script reads from a cycle record (`:8-13`) | api F5 | Minor | for-author | — | 🟢 Open |
| C3 | The "Main at:" key says Main even for `master` or the current branch (`:85`) | api F6 | Informational | for-author | — | 🟢 Open |
| C4 | Skill template paste ambiguities (`Window: Window:`; which sha to keep on a same-day rerun), in the stacked unit | api F7 | Informational | for-author | — | 🟢 Open (feat/dev-cycle) |
| C5 | No test covers `GIT_LITERAL_PATHSPECS` or the heading's newline replacement; mutants dropping either pass all 13 tests | fact-check r1, r3 | Informational | for-author | — | 🟢 Open |
| C6 | With `2>&1`, an error can print ahead of earlier sections (asynchronous filter), which hides which step failed | fact-check r3 | Low | for-author | — | 🟢 Open |
| C7 | Per-record `git show` + awk + cmp is linear, at 3.7 ms/record (311 records: 1.65–2.75 s) | performance #1 | Informational | for-orchestrator-synthesis | — | 🟢 Open (no change) |
| C8 | Log rows are still chosen by date. That is fine while rows are append-only; compare the clauses the same way if rows start being re-dated (`:130`) | performance #2 | Informational | for-author | — | 🟢 Open |

Commit-message claims (baa46e3: "a newline … cannot forge a line", "covers … fast-forwards", "Window line states exactly", "Unit stays at 399 lines"; 83e7895 Stale) are unmerged history. They are logged as `Accepted-immutable` in override-log.md, and the code defects behind them are R1, R2, A4 and A5.

### ↩️ Considered overrides

| Override | Prior finding | This run's treatment |
|---|---|---|
| 2026-09-29 digest: file-level carry-forward cost (Deferred, marked resolved in baa46e3) | performance Medium | Confirmed resolved. Measured on a clone of this repo: at 14 days, 11 → 2 records printed, exactly the changed ones; §2 is 60% smaller. |
| 2026-09-29 digest: option-name test needs both defences removed | api/fact-check | Inherited, not re-flagged. |
| 2026-09-29 digest: SIGPIPE fix untested | fact-check | Inherited. |
| 2026-09-29 digest: carried list not machine-splittable | api | Inherited. C1 adds new evidence (the skill keys verdicts on the printed name). |
| Final pass 2 F8: TAB kept, bare `--since` message, DEV_CYCLE_TODAY in help | fact-check/api | Inherited for TAB. A2 is new evidence beyond it (C1 bytes, stderr). |

### ✅ Confirmed Good

| Item | Verdict | Evidence | Source |
|---|---|---|---|
| F2: no command writes under `.git` | ✅ Confirmed (executed) | The `.git` listing was unchanged after a run with a stat-dirty index, and de53069 changed it (merged Claim 14) | fact-check r1+r2+r3 |
| F4: a failed step exits non-zero mid-digest | ✅ Confirmed (executed) | A failing `shuf` shim gives exit 3 through `$(…)` and a pipe (merged Claim 15) | fact-check r1+r2+r3 |
| baa46e3's tests fail on de53069 and on the relevant mutants | ✅ Confirmed (executed) | Tests 2 and 3 fail on de53069. Test 3 fails if "Main at:" is ignored or the compare is file-level, and test 2 fails without the filter (merged Claims 29, 30, 32) | fact-check r1+r2+r3 |
| baa46e3 resolves the file-level carry-forward cost | ✅ Confirmed (executed) | See the measurement above | performance |

### ⚠️ Unverified Findings

All findings' evidence resolved (spot-checked against `scripts/dev-cycle.sh` at baa46e3).

### ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (architecture-review is not a core critic. As in passes 1 and 2, it was not selected: a single script with no module structure.)

### 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/dev-cycle.sh:107-116` | R2, A1, A3, A6, fact-check Claims 7-8 | composed → X1 |
| 2 | `scripts/dev-cycle.sh:89-91,170-174` | R3 (fact-check r1, security #4) | distinct defects: one defect, and security #4 already states the mechanism and fix |
| 3 | `scripts/dev-cycle.sh:119-141` | R1, C1 | distinct defects: forgery (escaping) versus name form (contract) |
| 4 | `scripts/dev-cycle.sh:42,112` | A2, C6 | distinct defects: filter coverage versus output ordering |
| 5 | `scripts/dev-cycle.sh:84,99` | A4, A5 | distinct defects: each states its own wording fix |

**X1 (🔴, composed; inherits R2):** the window-start resolution at `:108-109` takes any 7–40-hex token after a bare `Main at: ` prefix. It resolves that token through ref names, and on any failure silently substitutes a committer-date guess. R2 (wrong base via dates), A1 (wrong base via a tag) and A3 (no visible provenance) are one root defect. The fix: accept only a full 40-hex commit (`git cat-file -e <sha>^{commit}`) that is an ancestor, and on anything else say so in the digest and print every trigger in full (as `--since` does), rather than guessing a base. Security #3/#4 suggest selecting sections 1 and 4 by `$base..$MAIN_SHA` as well, which would also cover R3. Evidence: `:108` `sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p'`; `:109` `… || base="$(git rev-list -1 --first-parent --before="$SINCE_TS" "$MAIN_SHA")"`.

**Next action (mechanical, chat-synthesis rule 3, ≥3 🔴):** escalate to /pre-mortem. Per the brief, the loop cap is exhausted, so this goes to the user under Q-100 rather than into a fifth iteration.

Tokens: fact-check 3 × ~120K (119K, 122K, 127K); critics security 119K, api 107K, performance 93K; orchestrator merge and rubric about 150K. Total about 0.84M across 6 agents.

---

## Final pass 4 (Q-101 [1] confirming pass, on db0e5ca)

**Status: 🔴 DOES NOT PASS — 2 red item(s) unresolved. Not clean. Q-101 [1] allowed one confirming pass, so nothing was fixed; the findings go back to the user.**

Scope: full branch, `scripts/dev-cycle.sh` + `test/scripts/dev-cycle.bats` (504 lines), focus d9e4cb9 (carry-forward cut, post-walk date filter, `scrub()`) and db0e5ca (sections 6–7). Panel: fact-check k=3 on opus (merged: 39 Verified, 16 Mostly accurate, 6 Incorrect, 1 Unverifiable over 62 rows; agreement 46/62 ≈ 74%), then security, performance, api-consistency on opus, in parallel. Delivery mode: self-read (shared brief and Stage-1 summary in session-unique scratch files). Artifacts: `code-fact-check-report-digest-final4.md` (merged), `code-fact-check-report-r{1,2,3}-digest-final4.md`, `security-review-2026-10-01-digest-final4.md`, `performance-review-2026-10-01-digest-final4.md`, `api-consistency-review-2026-10-01-digest-final4.md`. Execution logs stayed in the session scratchpad (the brief forbade other worktree writes).

Process notes:
- Fact-Check Gate: high-confidence Incorrects (Claims 11, 12, 39, 49) did not pause the run; the user's Q-101 [1] asked for one full confirming pass.
- Stage 2.5 skipped: 3 routed endorsement claims (security #1 and #3, performance's `--since-as-filter` margin) stay *pending execution verification*. The pass already has reds, so no ✅ row depends on them.
- Contextual critics: tech-debt-triage not run (504 lines, of which 263 tests, just over the trigger; advisory only); architecture-review not selected (single script).
- Pass 3's cut-targeted findings: the code behind R1, R2, A1, A3, A5, A6, C1, C3 is gone (fact-check r1, r2, r3, executed). R3 is fixed (test 4 fails on baa46e3). A2 is **not** closed (R1 below). C6 still reproduces (A5 below).

### 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | `scrub()` is bypassable by repo bytes. One `s///g` pass runs before `tr`, so (a) a C0 byte inside a C1/bidi/tag encoding survives the substitution and `tr` then rejoins the sequence, and (b) nested sequences (`\xC2\xC2\x9B\x9B`) collapse to a live C1 after one pass. A decision record's trigger line reached stdout with CSI, RLO and tag characters. Fix: `tr` first, repeat the substitution until stable, add both cases to test 5. | Security/Correctness | Fact-check Incorrect (high, executed; r1); security Medium (High conf., executed) | fact-check r1 (Claims 11, 49); security #1 | `scripts/dev-cycle.sh:24-31` | for-author | Final pass 2 F8 (TAB Won't-Fix) does not cover this | 🔴 Unresolved; composed → X1 |
| R2 | The skill on `feat/dev-cycle` (70cc7dc) still instructs writing `Main at: <sha from the digest>` and says the next digest compares triggers against it; the digest no longer prints or reads it. | API | Breaking | api F1 | `feat/dev-cycle:skills/dev-cycle/SKILL.md` step 7 | for-author | — | 🔴 Unresolved; fix lands on feat/dev-cycle (the stacked unit), and neither branch merges alone |

### 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `PERL_UNICODE=SD[A]` or `PERL5OPT=-CSD` in the caller's environment switches the scrub off (perl decodes, warns, C1/RLO pass). The comment's "LC_ALL=C, so invalid UTF-8 cannot make perl warn" names the wrong mechanism. Fix: unset both, run perl with `-C0`. | Security/Docs | Fact-check Incorrect (high, r2; comment); security Medium (executed) | fact-check r2 (Claim 12), r1, r3; security #2 | for-author | — | 🟡 Open; composed → X1 | — |
| A2 | Section 7's step-5 half assumes contracts nothing defines yet: "the thresholds are the skill's", a roadmap `## In flight` section, `docs/working/idea-log.md` with `## Brainstorm YYYY-MM-DD` headings. On a clone of feat/dev-cycle it always prints "In flight: 0" and "No …idea-log.md"; the bats test pins a format nothing writes. "Ideas seeded since" also counts the last brainstorm's own bullets. | API/Docs | Fact-check Incorrect (Claims 30, 31; comment, medium); api Inconsistent | fact-check r1, r3; api F3, F8 | for-author | — | 🟡 Open; composed → X2 | — |
| A3 | The skill still tells the agent to keep carried verdicts ("Triggers the digest lists as carried forward keep the previous record's verdict"; record example "(carried from cycle-<date>)"), contradicting the digest's "verdicts are context, not answers". | API | Inconsistent | api F2 | for-author | — | 🟡 Open (feat/dev-cycle) | — |
| A4 | A symlink committed under `docs/decisions/` (or roadmap / idea log) makes the digest read and print a file outside the repo; `-f` follows links. Exposure: text under `## Revisit triggers` / `## Next`. | Security | Medium (impact Low) | security #3 | for-author | — | 🟡 Open | — |
| A5 | The two perl filters are not waited for: a redirected digest can be incomplete at exit (exit 0), and with `2>&1` errors land before the header. Pass-3 C6, now with a measured truncation. | Correctness | Fact-check Mostly accurate (executed, 3/3) | fact-check r1, r2, r3; security #5; api F10 | for-author | — | 🟡 Open | — |
| A6 | The window changed from local midnight to each committer's own-zone date (`%cs`); `--help`, the Window line and the "--since counts from midnight" test do not say so. A −12:00 merge at 04:30 local on the start day is now excluded. | API/Docs | Fact-check Mostly accurate (r1, r2, r3); api Minor | fact-check Claims 1/3, 13; api F7 | for-author | — | 🟡 Open | — |
| A7 | Section 6's classification: `(^\|/)README` matches any path component starting README (`src/README_gen.sh` counts as a doc), `readme.txt` counts as code; mutants dropping the `^docs/` or `.md`/README rules pass all 18 tests. | Correctness/Tests | Fact-check Mostly accurate (3/3, executed) | fact-check Claims 20, 25 | for-author | — | 🟡 Open | — |
| A8 | Section 7's 4b lists are a net diff from a base commit: a skill changed and reverted inside the window shows 0, so db0e5ca's "never misses" is wrong; mutant M6 (base off by one) survives. The Window line does not describe this basis. | Correctness/Docs | Fact-check Mostly accurate (3/3) | fact-check Claims 22/26b/44; api F9 | for-author | — | 🟡 Open | — |
| A9 | Test 4's comment says baa46e3 "report[s] 0 merges"; it reported 1 (feature 4) and hid the three older merges. Its name ("merges after it") has the direction reversed. | Docs/Tests | Fact-check Incorrect (high; test comment → 🟡 under T) | fact-check Claims 28, 39 | for-author | — | 🟡 Open | — |

### 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Section 6 has no output cap (10,000 lines on a wide window) and spawns two git processes per merge; one `--diff-merges=first-parent --name-only` walk does it in 0.5 s vs 25 s | performance #3 | Low | for-author | — | 🟢 Open |
| C2 | Full-history walks in sections 1 and 7 (`:99,102,199`) cost ~2.1 s each on a 220k-commit repo; `--since-as-filter` with a one-day margin keeps results identical (git ≥ 2.37; margin claim pending verification) | performance #1 | Low | for-author | — | 🟢 Open |
| C3 | One `git log -1 -- f` per decision record (`:116`) is the largest cost (3.6 s with commit-graph, 26 s without); one path-limited walk does it in 0.12 s | performance #2 | Low | for-author | — | 🟢 Open |
| C4 | Section 6 calls its list "a step 4 finding", but skill step 4 covers sampled merges only; digest sections 6 and 7 collide with skill steps 6 and 7 by number | api F4, F6 | Minor | for-author | — | 🟢 Open (both branches) |
| C5 | Trigger names print as `### docs/decisions/<file>`; the skill's "name the digest prints" example uses the basename | api F5 | Minor | for-author | Final pass 3 C1 (name forms) | 🟢 Open (feat/dev-cycle) |
| C6 | "Every revisit trigger" covers only `## Revisit triggers` sections and log rows; an unreadable record is skipped silently; inline triggers (e.g. `docs/decisions/013-…md:21`) never print | fact-check Claims 3/6b | Low | for-author | — | 🟢 Open |
| C7 | The scrub leaves zero-width and format characters (U+200B, U+2028, U+2060, U+FEFF); none can start a line | security #4 | Informational | for-author | — | 🟢 Open |
| C8 | Test 5's comment says "non-repo error" but tests the unknown-option error; test 6 passes on baa46e3 (regression guard only) | fact-check Claims 37, r2 | Informational | for-author | — | 🟢 Open |

Commit-message claims: d9e4cb9's A2 list (Claim 49) and db0e5ca's "never misses" are unmerged history; logged `Accepted-immutable` in override-log.md. The defects behind them are R1 and A8.

### ↩️ Considered overrides

| Override | Prior finding | This run's treatment |
|---|---|---|
| 2026-09-29 carry-forward cost (resolved in baa46e3) | performance | Moot: carry-forward is cut. |
| 2026-09-29 option-name test needs both defences removed | api/fact-check | Inherited, not re-flagged. |
| 2026-09-29 SIGPIPE fix untested | fact-check | Inherited. |
| 2026-09-29 carried list not machine-splittable | api | Moot: the list is gone; C5 is the remaining name-form gap. |
| Final pass 2 F8: TAB kept | fact-check/api | Inherited for TAB; R1 and C7 are different bytes. |
| 2026-09-30 baa46e3 / 83e7895 commit messages (Accepted-immutable) | fact-check | Inherited. |

### ✅ Confirmed Good

| Item | Verdict | Evidence | Source |
|---|---|---|---|
| The cut removed every code path behind pass-3 R1, R2, A1, A3, A5, A6, C1, C3; no `Main at:` or carried list remains, and test 3 pins both absences | ✅ Confirmed (executed) | merged Claims 6a, 40–42; api "cut is clean in the script" | fact-check r1+r2+r3; api |
| R3 fixed: merges and commits are filtered after a full walk | ✅ Confirmed (executed) | test 4 fails on baa46e3, passes on db0e5ca (merged Claims 14, 28) | fact-check r1+r2+r3 |
| Commit-message tallies: 16/16 at d9e4cb9, 18/18 at db0e5ca, 241 lines, shellcheck clean at both | ✅ Confirmed (executed) | merged Claims 45–48 | fact-check r1+r2+r3 |
| No awk `{n}` interval remains; mawk 1.3.4 lacks them | ✅ Confirmed (executed) | merged Claim 33 | fact-check r1+r2+r3 |

### ⚠️ Unverified Findings

Pending execution verification (Stage 2.5 skipped): security endorsements #1 and #3 as routed, and performance's claim that a one-day `--since-as-filter` margin keeps results identical on every repo.

### ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

### 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| X1 | `scripts/dev-cycle.sh:22-31` | R1, A1, C7 (fact-check r1, r2; security #1, #2, #4) | composed → X1 (inherits 🔴): the scrub has to normalise before it matches. Pin perl to bytes (`-C0`, unset `PERL_UNICODE`/`PERL5OPT`), delete C0 with `tr` first, then repeat the substitution until the string stops changing, and add the split, nested and env cases to test 5. |
| X2 | `scripts/dev-cycle.sh:216-241` + `feat/dev-cycle:skills/dev-cycle/SKILL.md` | A2, C4 (fact-check r1, r3; api F3, F4, F8) | composed → X2 (inherits 🟡): section 7's step-5 half reads a format only the approved doc describes. Land the skill text (idea-log path, brainstorm heading, In flight, thresholds) in the same change as the digest, or cut the step-5 half until it does. |
| 3 | `scripts/dev-cycle.sh:89-102` | A6, C2 | distinct defects: semantics (zone) vs cost (walk length) |
| 4 | `scripts/dev-cycle.sh:178-193` | A7, C1 | distinct defects: classification vs per-merge cost and no cap |

---

## Final pass 5 (delta confirming pass, on 28c6178 digest / c079e8c skill)

**Status: 🔴 DOES NOT PASS — 1 red item unresolved. Not clean; no fixes applied in this pass.**

Scope (partial, labelled): A = `db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats`; B = `6ee33e3..c079e8c` on feat/dev-cycle (skill, decision log, roadmap, skill-creation guide, global row 12, `docs/dev-cycle-sources.md`); plus the A↔B contract. Panel: fact-check k=3 on opus (merged 96 claims: 72 V / 16 MA / 1 S / 6 I / 1 U; agreement 68/80 = 85% on multi-replicate claims), then security, performance, api-consistency on opus. Delivery: self-read (session-unique brief and Stage-1 files). Artifacts: `code-fact-check-report-digest-final5.md` (merged), `-r{1,2,3}-digest-final5.md`, `security-review-2026-10-01-digest-final5.md`, `performance-review-2026-10-01-digest-final5.md`, `api-consistency-review-2026-10-01-digest-final5.md`. Health check on feat/dev-cycle at c079e8c: all checks passed.

Final pass 4 items: R2, A2 (default path), A3, A4 (out-of-repo targets), A5, A6, A7, A8, A9 closed (fact-check r1–r3, api, security). R1/A1 closed for split, nested, PERL_UNICODE and PERL5OPT, **not** PERLIO (R1 below). Stage 2.5 skipped (pass already red): security's two executed endorsements and performance's timing endorsements stay pending.

### 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | `PERLIO=:utf8` (also `:raw:utf8`, `:unix:utf8`) in the caller's environment switches the scrub off; `-C0` does not override it. C1 CSI and RLO from a merge subject reach stdout, exit 0. "Perl is pinned to bytes" is false. Fix: `env -u PERLIO` or `binmode` STDIN/STDOUT in the perl call, plus a test-5 env case. | Security/Correctness | Fact-check Incorrect (high, executed; r1, r3); security Medium (executed) | fact-check Claims 5, 29; security F1 | `scripts/dev-cycle.sh:27-34` | for-author | — | 🔴 Unresolved; composed → X1 |

### 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `1 while s///g` removes one nesting layer per pass, so the scrub is quadratic on nested input: 64 KB line 17.8 s, ~128 KB passes a 2-minute Bash timeout, after which the skill's digest-failure rule stops every cycle with no record. Tested fix: rescan from 3 bytes before each deletion (40 ms, identical output on a 20k-line fuzz), plus a per-line cap. | Performance/Availability | Medium (High conf., executed) | performance #1 | for-author | — | 🟡 Open; composed → X1 | — |
| A2 | The skill lets `docs/dev-cycle-sources.md` name the seed log; the digest hard-codes `docs/working/idea-log.md`, so step 5's seed and date inputs are wrong in any repo that renames it. The sources file can also point seeding or brainstorm reads outside the repo (e.g. at the user's global instructions file). | API/Security | Fact-check Incorrect (3/3); api Inconsistent; security Medium | fact-check Claim 61; api F1; security F2 | for-author | — | 🟡 Open; composed → X2 | — |
| A3 | Under /away nothing human sits between repo-derived text and an autonomous build that merges: seeded idea → Now (who may promote is unstated) → queue "stands" → agent-written brief → RPI loop → pr-prep local merge. The skill does not say whether a brief replaces RPI's plan gate; brief stop conditions and out-of-scope have no required minimum. | Security/Design | Medium | security F3 | for-author | — | 🟡 Open — needs the user's judgment | — |
| A4 | In-flight slots leak: the only exit from In flight is "merged → Done". A loop that stops or stalls keeps its slot, so 3 of them block 6b for good; step 1 skips branches named by an "open" brief, and "open" is never defined. | Correctness/API | Medium; api Minor | performance #2; api F7 | for-author | — | 🟡 Open | — |
| A5 | Section 7 drops file names git quotes (non-ASCII under default `core.quotePath`, control characters): `skills/café/SKILL.md` counted 0, so a renamed skill can evade the 4b trigger. Fix: `-c core.quotePath=false` or `-z`. | Correctness | Fact-check Mostly accurate (executed); security F7 | fact-check r2, r3; security F7 | for-author | — | 🟡 Open | — |
| A6 | Sibling docs drift from the skill: the skill-creation guide row cites an Operating Modes "launch" rule that does not exist (fact-check Incorrect, doc) and miscounts steps; decision log row 67 is not marked revised by 68 (Stale); row 68 calls the thresholds "section 7's" and the audit "full-history" where the skill files a scoped task. | Docs | Fact-check Incorrect (doc → 🟡 under T), Stale, Mostly accurate; api F9 | fact-check Claims 42, 56; api F9 | for-author | — | 🟡 Open | — |

### 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Sections 5 and 7 match roadmap headings differently (`## Next (ranked)`, `## In Flight` count 0 in section 7) | api F3 | Minor | for-author | — | 🟢 Open |
| C2 | Skill wording: "Now + Next hold 0–1 items ready for 6b" (only Now is handed off); rule 1 names 6b as writing briefs (step 6 does); "done-criteria" vs "acceptance criteria"; "step 1's bar (… small …)"; "silently widens"; "the next digest … from the default branch" (it reads the working tree); record template doubles `Window:` and writes the 6b line before 6b runs | fact-check MA; api F2, F4, F6, F8 | Minor | for-author | — | 🟢 Open |
| C3 | Idea-log seed counting counts any `- ` line (a format example counts); no template; "none recorded" not said to count as due | api F5 | Minor | for-author | — | 🟢 Open |
| C4 | Brief not pinned to the landed commit (a loop can edit its own stop conditions); 6b loops not required to use their own worktree | security F4, F5 | Low | for-author | — | 🟢 Open |
| C5 | Every cycle's docs-only chore branch now lands through the full pr-prep review loop; cycles may run many a day | performance #3 | Low | for-author | — | 🟢 Open |
| C6 | Section 7 lists names without churn, so "substantially changed" needs a diff per file (43 skill files since 2026-09-01) | performance #4 | Low | for-author | — | 🟢 Open |
| C7 | Scrub "Not covered" list incomplete (all lone C1 bytes, overlong encodings, U+061C, U+2028/9); `DEV_CYCLE_SCRUBBED=1` in the environment disables it; fd comment order backwards; exit 141 under a closed reader is ambiguous | fact-check MA; security F6 | Informational | for-author | — | 🟢 Open |
| C8 | Section 6 matches `docs/` and `.md` case-sensitively; cycle-record glob not behind `inrepo` (a symlinked `docs/working` can move the window start); `QUESTIONS_LIVE` env bypasses it in questions.sh | fact-check r1–r3 | Low | for-author | — | 🟢 Open |

Commit-message claims (26b7590: "pins perl to bytes", "stream order follows the body", "shellcheck clean"; c079e8c "matches the approval doc" with undisclosed deviations) are unmerged history; logged `Accepted-immutable`.

### ↩️ Considered overrides

Inherited from final pass 4 (TAB Won't-Fix; option-name test; SIGPIPE; accepted-immutable commit messages). No new matches.

### ✅ Confirmed Good

| Item | Verdict | Evidence | Source |
|---|---|---|---|
| Final-pass-4 R2/A3: no `Main at:` or carried-verdict text remains in the skill | ✅ Confirmed (executed grep + read) | fact-check r1–r3; api "F1, F2 closed" | fact-check, api |
| Final-pass-4 A5: the re-exec waits for both filters and returns the body's exit status | ✅ Confirmed (executed) | merged Claim 31 (part-verdicts) | fact-check r1–r3 |
| New tests 5, 6, 19, 20 fail on db0e5ca and pass at 28c6178 (test 7 passes on both, as its commit says) | ✅ Confirmed (executed) | merged Claims 33–36 | fact-check r1–r3 |

### ⚠️ Unverified Findings

Pending execution verification (Stage 2.5 skipped): security's symlink and scrub endorsements; performance's re-exec overhead and synthetic-repo timings. Row 68's account of the user's comments (Unverifiable: comment text not read).

### ⏭️ Skipped Core Critics

All core critics ran.

### 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| X1 | `scripts/dev-cycle.sh:22-40` | R1, A1, C7 | composed → X1 (inherits 🔴): the scrub must be both closed and bounded. Pin I/O to bytes (`env -u PERLIO` with the other two, or `binmode`), rescan from just before each deletion instead of restarting the line, and cap line length; test the env, nesting-depth and timing cases. |
| X2 | `skills/dev-cycle/SKILL.md:41-44,154-160` + `scripts/dev-cycle.sh:244` + `docs/dev-cycle-sources.md` | A2, C3 | composed → X2 (inherits 🟡): the seed log is configurable in the skill but fixed in the digest. Either fix the path everywhere (drop the option) or have the digest read the sources file with an in-repo check and print which file it used. |
| 3 | `skills/dev-cycle/SKILL.md:186-232` | A3, A4, C4 | distinct defects: gate design (who approves autonomous merges) vs slot lifecycle vs brief integrity |

---

## Pass 6 (review-fix loop, `--loop-pass`, k=1; on ef0471c digest / 5e8bfd9 skill)

**Status: 🔴 short-circuited — 1 behavioral red at fact-check; critics skipped; fixed in 47c9a8e (digest) and d6e1f24 (skill).**

The user asked to follow the review-fix-loop guidance: k=1 delta passes until no known issues remain, then a k=1 full review for the clean pass. Scope: `28c6178..ef0471c` (digest) and `c079e8c..5e8bfd9` (skill and docs), labelled partial. Fact-check k=1 on opus: 42 claims, 29 V / 7 MA / 6 I (`code-fact-check-report-digest-pass6.md`). Executed: 20/20 tests; shellcheck clean; 250k-line fuzz equal to a repeat-until-stable reference; scrub output unchanged under PERLIO/PERL_UNICODE/PERL5OPT variants; the cut does not reassemble a straddling sequence; section 7 counts tab, newline, quote and non-ASCII names.

| # | Finding | Severity | Source | Fix |
|---|---|---|---|---|
| R1 | In-flight rules overlapped: a `review` item waiting > 7 days on the merge decision also matched "no commit for 7 days → back to Now", so step 6 could hand it to a second loop | 🔴 behavioral (procedure) | fact-check Claim 35 | d6e1f24: waiting items stay; the idle rule applies only to loops still building |
| A1 | Scrub comment claimed linear work; test 5's 40k-layer case was cut before nesting ran | 🟡 (comment, test) | Claims 5, 13, 15b | 47c9a8e |
| A2 | `docs/dev-cycle.md` and the skill said onboarding sets the idea sources | 🟡 (doc) | Claims 23, 30a | d6e1f24 |
| A3 | This repo's interim `review` policy was recorded only in a commit body; the skill would never ask | 🟡 (process) | Claim 25 | d6e1f24: interim counts as unset; Q-103 filed |
| C1 | 4097-byte unterminated line not cut; `## Nextgen` reopened Next; loose seed regex; rule 1 vs step 6 brief contents; "done-criteria"; window fallback; row 68 condition; guide promotion clause; "Not covered" list | 🟢 | Claims 2, 20, 27, 28, 29, 37; scope notes | 47c9a8e, d6e1f24 |

Skipped core critics: security, performance, api-consistency (loop-pass short-circuit: behavioral red confirmed). The next pass runs them (the short-circuit is used for this loop).

---

## Pass 7 (review-fix loop, k=1, all critics; on 47c9a8e digest / d6e1f24 skill)

**Status: 🟡 not clean — 0 red, ambers fixed in ab8ec06 (digest) and cfe4b51 (skill).**

Scope: the two fix rounds since final pass 5 (`28c6178..47c9a8e`, `c079e8c..d6e1f24`), labelled partial. Fact-check k=1 (48 claims: 40 V / 7 MA / 1 I, the Incorrect an already-fixed commit message) and the three critics ran in parallel; the critics took loop pass 6's fact-check report as Stage-1 input (a deviation from the sequential order, to save wall-clock time). Artifacts: `code-fact-check-report-digest-pass7.md`, `security-review-2026-10-01-digest-pass7.md`, `performance-review-2026-10-01-digest-pass7.md`, `api-consistency-review-2026-10-01-digest-pass7.md`. Pass 5's R1 (PERLIO) and A1 (quadratic scrub) confirmed fixed by execution.

| # | Finding | Severity | Source | Fix |
|---|---|---|---|---|
| A1 | The build-loop policy was read at loop end, unpinned: a loop could flip `docs/dev-cycle.md` on its branch and merge itself; stop conditions did not name the cycle's own files | 🟡 Medium | security F1 | cfe4b51: policy recorded in the brief at step 6; stop conditions name settings*.json and the dev cycle's files |
| A2 | A committed symlink at the idea-log path or an idea source sends writes/reads outside the repo | 🟡 Medium | security F2 | cfe4b51: every path must resolve inside the checkout; symlinked paths skipped |
| A3 | The 47c9a8e seed regex backtracks in mawk (18.7 s on a 640 KB line) | 🟡 Low (regression) | performance #1 | ab8ec06 |
| A4 | In-flight gaps: declined merges and blocked items matched no rule; stalled items re-queued forever; full pool invisible in the record | 🟡 | fact-check scope; performance #2, #3 | cfe4b51 |
| A5 | Interim marker matched literally, unknown values undefined; `autonomous` clashed with "autonomous build loop" | 🟡 | api F1, F3; security F4 | cfe4b51: `self-merge` \| `review`; only one exact self-merge line counts |
| C1 | U+2028/2029 can split lines for some readers; "every trigger in full" vs the cut; CRLF headings; section 5 heading rule untested; timing case could not catch a revert; onboarding/row 68 "separate PR review"; no settings template; rule 3 "names the item it blocks"; row 68 4b trigger; Q-103 option [2] wording; global row 12; guide row | 🟢 | security F5; api F2, F4–F7, F9, F11; fact-check MA; performance #5 | ab8ec06, cfe4b51 |

Not acted on: brief `Status:` as a third status form (api F8, informational); awk reading a 100 MB line slowly (performance #4, unrealistic input; comment now scopes the cut to the scrub).

---

## Pass 8 (review-fix loop, k=1, all critics; on ab8ec06 digest / cfe4b51 skill)

**Status: 🔴 not clean — 1 behavioral red; fixed in d503a43 (digest) and 1ae9b21 (skill).**

Scope: `47c9a8e..ab8ec06`, `d6e1f24..cfe4b51`, labelled partial. Fact-check k=1 (41 claims: 27 V / 12 MA / 2 I) and the three critics ran in parallel on pass 7's fact-check input. Artifacts: `code-fact-check-report-digest-pass8.md`, `security-review-2026-10-01-digest-pass8.md`, `performance-review-2026-10-01-digest-pass8.md`, `api-consistency-review-2026-10-01-digest-pass8.md`. The digest half held under every probe except the in-repo symlink case.

| # | Finding | Severity | Source | Fix |
|---|---|---|---|---|
| R1 | "Anything else means review, and file one" also covered a deliberate `Build-loop policy: review`, so a repo that chose review was re-asked every cycle | 🔴 behavioral (procedure) | fact-check Claim 16c | 1ae9b21: set = one exact line of either value |
| A1 | Path rule followed symlinks: a committed `docs/roadmap.md` → `.git/...` was read by the digest, and the cycle's writes would follow such links; the rule cited `inrepo`, which the cycle cannot run and which rejects files not yet created | 🟡 Medium | security F1; api 1, 6; fact-check 17b, 18 | d503a43 (inrepo rejects any symlink component), 1ae9b21 (never through a symlink, per component) |
| A2 | Stop conditions as a denylist kept missing files later runs follow (`scripts/questions.sh`, review procedures, instruction files) | 🟡 Medium | security F2 | 1ae9b21: an allowlist of paths per brief; fixed exclusions, stricter under self-merge |
| A3 | A pinned self-merge could not be lowered for loops in flight; the brief's `Policy:` line had no parse rule | 🟡 Medium/Low | security F3, F4; api 2 | 1ae9b21: stricter of the brief and the current setting; anything but self-merge = review |
| A4 | In-flight bookkeeping: declined items re-queued every cycle; `blocked` never cleared; no stall count; the archive hides answers | 🟡 Medium | performance #1–#3; api 3, 4; fact-check 19b, 19c, 20, 30c | 1ae9b21: three outcomes only; a returned item goes to Ideas and re-enters Now only by the user |
| C1 | Step 2 still said "in full"; final message omitted PRs; Q-103 wording; "~1 minute"; section 5's CRLF untested; printed-line cut wording; CRLF in the settings line | 🟢 | api 5, 7, 8, 10; fact-check 6, 9, 25, 27, 29c; performance #5 | d503a43, 1ae9b21 |

Commit-message claim cfe4b51 "symlinked paths are skipped" (Claim 30a) is unmerged history; the rule it described is now true (1ae9b21).

---

## Pass 9 (review-fix loop, k=1, all critics; on d503a43 digest / 1ae9b21 skill)

**Status: 🔴 not clean — 3 behavioral reds in the skill's handoff rules; fixed in b88a9c4 (digest) and 8b3a8ad (skill).**

Scope: `ab8ec06..d503a43`, `cfe4b51..1ae9b21`, labelled partial. Fact-check k=1 (29 claims: 15 V / 10 MA / 3 I / 1 U) and the three critics in parallel on pass 8's fact-check input. Artifacts: `code-fact-check-report-digest-pass9.md`, `security-review-2026-10-01-digest-pass9.md`, `performance-review-2026-10-01-digest-pass9.md`, `api-consistency-review-2026-10-01-digest-pass9.md`. The digest's `inrepo` was confirmed correct and complete by three independent probes; the policy rule and stricter-of-two rule fail safe.

| # | Finding | Severity | Source | Fix |
|---|---|---|---|---|
| R1 | An approved "merge <branch>?" had no owner; once archived the item fell to Ideas unmerged | 🔴 behavioral | fact-check 13c; performance #3 | 8b3a8ad: the cycle merges approved branches |
| R2 | Loops had to file questions entries, which their Paths rule made a stop condition; process artifacts uncovered | 🔴 behavioral | fact-check 15; security F3; api 1; performance #1, #2 | 8b3a8ad: loops write only their branch and end with a `handoff:` marker commit; the cycle files entries |
| R3 | Self-merge exclusions missed test/, guides/, GEMINI.md and more; nothing checked the diff | 🔴 behavioral (under self-merge) | fact-check 16; security F1, F2 | 8b3a8ad: wider exclusions plus a pre-merge `git diff --name-only` ⊆ Paths and no-symlink check, then re-read the setting |
| A1 | "running" vs "7 days quiet" overlapped | 🟡 | fact-check 13b; security F4; api 3; performance #4 | 8b3a8ad: building = a commit within 7 days |
| A2 | The digest reported a skipped symlinked input as absent ("create it", "no record") | 🟡 | api 2; fact-check 9 | b88a9c4: "NOT read" where it would be read, plus section 8 |
| C1 | Policy line gloss vs exclusions; Q-103 [1]/[2] wording and edit; docs/dev-cycle.md looser rule; Ideas definition; cut wording; test 6 reach; test 20 suffix | 🟢 | api 4–7, 9, 10; fact-check 1, 5, 6, 12, 14, 20, 23; security F5 | b88a9c4, 8b3a8ad |

---

## Pass 10 (review-fix loop, k=1, all critics; on b88a9c4 digest / 79b1bfe skill)

**Status: 🔴 not clean — 1 behavioral red; fixed in c034a75 (digest) and a218ad8 (skill).**

Before this pass the user chose to split the autonomous build-loop handoff out of the branch (79b1bfe; seed `docs/working/seed-build-loop-handoff.md`, roadmap Now "Build-loop handoff", Q-103 deferred). The split removed every pass-9 autonomous-merge red (security, api, performance all confirm). Scope: `d503a43..b88a9c4`, `1ae9b21..79b1bfe`, partial. Fact-check k=1 (29 claims: 19 V / 6 MA / 2 S / 2 I) and the three critics in parallel on pass 9's fact-check input. Artifacts: `code-fact-check-report-digest-pass10.md`, `security-review-2026-10-01-digest-pass10.md`, `performance-review-2026-10-01-digest-pass10.md`, `api-consistency-review-2026-10-01-digest-pass10.md`.

| # | Finding | Severity | Source | Fix |
|---|---|---|---|---|
| R1 | A skipped cycle record still read as absent ("the previous cycle did not write its record"), and section 2 said "No revisit triggers recorded" when its inputs were skipped; b88a9c4's message claimed otherwise | 🔴 behavioral | fact-check 14b, 26a; api F1, F2; performance referral | c034a75 |
| A1 | A symlinked `docs/decisions` or `docs/working/cycles` made section 8 list names from the outside directory, which the record commits | 🟡 Medium | security F1 | c034a75: globs only in plain directories; the directory is listed once |
| A2 | A newline in a skipped name split into a forged section-8 line | 🟡 Low | security F2; api F7; performance referral | c034a75 |
| A3 | Open briefs never expire, so three unstarted briefs hold every slot | 🟡 Low | performance #1 | a218ad8: 14-day "keep or drop?" entry |
| C1 | "(0 items ready for 6b)"; a directory or FIFO labelled "symlink"; section 8 header and record name; step 2 "printed line"; step 0's skipped-record inference; Q-103 interim line, option [2] list, closing line; seed vs docs/dev-cycle.md policy rule; brief-reading reminder | 🟢 | fact-check 4, 6, 7, 15, 16, 20, 21; api F3–F8; security F3–F6 | c034a75, a218ad8 |

Not acted on: section 8 and `## Skipped inputs` have no cap (performance #2; ~30 bytes per path, only with many committed symlinks); `skipped()` re-runs `inrepo` (performance #3, 0.3 ms per path). Carried to the handoff seed: `git diff --summary` shows a file turned symlink as `mode change 100644 => 120000` (security, probe P4).
