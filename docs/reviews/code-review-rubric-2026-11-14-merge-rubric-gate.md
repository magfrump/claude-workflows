Commit: 655df91d
Loop-pass short-circuit: used at 655df91d

# Code Review Rubric

**Scope:** pass 1: feat/merge-rubric-gate, fce8af4a..66304b3d; pass 2: 66304b3d..655df91d (fix 2cb2e2f9 + rubric commit 655df91d), read from a `git archive` extract of 655df91d; pass 1 detail: (bb0030a1, 66304b3d; range extended mid-run by the caller), read from a `git archive` extract of 66304b3d | **Reviewed:** 2026-11-14 | **Status: 🟡 CONDITIONAL PASS** — pass 2 findings addressed in dd6aa89e; awaiting pass 3

Delivery mode: self-read (the diff and the extract were on disk, plus a shared brief). Fact-check k=3 (opus). Critics, all on opus: security, performance, api-consistency, architecture-review (auto-selected because of the new lib module), test-strategy (`--include`, because the caller asked about test strength). Unattended run, so the Fact-Check Gate took Continue. Red closure is judged against the corrected rule from 66304b3d: a red closes only by a fix (Fixed or Resolved as its first word), a Split naming its follow-up, a Carried naming the newer rubric file and a row, or an answered Q-ID.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | The successor pass breaks the corrected red rule. It looks a named row up by ID across both tiers and copies that row's class onto a red, without calling check_answer. As a result, a red closes by borrowing an amber's closure, such as a TODO, an override-log row, a trigger, or an unanswered Q-ID. Examples: `Waived → A1` with A1 an amber TODO, and `Deferred Q-007; see A3`, where Q-007 is never checked. The successor regex `\bas`/`\bsee`/`\binto` also matches ordinary prose, so `Open, same as A2` marks a red **fixed**. Because of this, the header (`build-loop.sh:444-451`), the lib comment (`:34-38`), the research doc (`:59,82`), the test title (`build-loop-check.bats:1189`) and the 66304b3d subject are all false. Executed (orchestrator probe, review1/probe-orch/t.md): `R1 Open, same as A2 → fixed`, `R2 Waived → A1 → closed`. | Correctness / Security | Incorrect (high), behavioral; security Medium; api Inconsistent; arch Minor | Fact-check (r1+r2+r3) + security + api-consistency + architecture | `scripts/lib/rubric-check.sh:113-124` | for-author | — | ✅ Fixed in 2cb2e2f9 (pass 2 confirmed: `Open, same as A2` → open; red follows only red successors) |
| R2 | (pass 2) A Split still closes a red on a bare `roadmap`, `branch` or `brief` word anywhere in the Status or Author note, and need not name a target. This goes against the corrected red rule ("a Split naming its follow-up") and against the 2cb2e2f9 claim "Split and Carried need a named target". Carried still never checks that the named rubric is newer. Executed (review2/probe-orch/t.md): `Split; no branch yet` → closed, `Split — no roadmap item` → closed, `Carried to code-review-rubric-2020-01-01-old.md R4` → closed. "no" is not in the negation set (`:85`). Fix: require a target shape (a branch or brief name, `docs/working/briefs/…md`, or a roadmap item reference), add `no` and `none` to the negations, and check the Carried date against this rubric's date. | Correctness | Incorrect (high), behavioral | Fact-check pass 2 (k=1) + orchestrator probe | `scripts/lib/rubric-check.sh:90-94` (doc `:39-42`, `scripts/build-loop.sh:451-452`) | for-author | — | ✅ Fixed in dd6aa89e |

Convergence: fact-check + security + api-consistency + architecture. The tier comes from the fact-check's behavioral Incorrect plus the executed probe, not from convergence.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Split and Carried close a red on bare words. Negation is checked only in the first clause. `Split; no branch yet`, `Split (Q-999)` (Q-ID never checked), `Carried; still open in …md R4`, and a Carried note whose only "row" is `H2` all close. Carried never checks that the named file is newer. Executed: `R3 Split; no branch yet → closed`. Location: `scripts/lib/rubric-check.sh:66-67` | Correctness | Incorrect (medium) | Fact-check (r2 Incorrect; r1, r3 Mostly accurate) | for-author | — | ✅ Fixed in dd6aa89e (as R2) | — |
| A2 | A Status whose first word is Fixed or Resolved reads as fixed when its negation sits after the first clause. Examples: `Fixed: no, not yet`, `Resolved — see below; partly open`, `Fixed in abc, but …; merge path still open`. Executed: `R4 Fixed: no, not yet → fixed`. Location: `scripts/lib/rubric-check.sh:57-60` | Security | Medium | security-reviewer | for-author | — | ✅ Fixed in 2cb2e2f9 (pass 2 confirmed; residue in A19) | — |
| A3 | Any answered Q-ID closes a red, whatever the answer was. Any check_answer output other than `open …` or `skip …` counts as answered, including `drop` and `unrecognized`. Empty output also counts, which is fail-open against H2 (gates fail closed and loudly). A Q-ID cited only for context (`same pattern as Q-104`) closes too. Location: `scripts/lib/rubric-check.sh:62-69,185-190` | Security | Medium | security-reviewer (+ api-consistency Informational) | for-author | — | 🟡 Acknowledged | Kept by design: any answered Q-ID closes a red; what the answer says is the owner's judgment, which a gate keyed on the artifact does not read (H4). Revisit if a landing shows a red closed by a Q-ID whose answer rejected the waiver (research doc, Review pass 2) |
| A4 | Some rows are skipped with no `unread` line, so `clean` can print over reds that were never read. Cases: a Tier cell reading `Must Fix` (rubric.md's own wording) is skipped; a `## Red findings` heading is skipped once another table was read; the parser does not track code fences, so a `# example` line inside a fence ends the red tier. This goes against H2. Location: `scripts/lib/rubric-check.sh:79-82,91,104-105` | Security | Medium | security-reviewer | for-author | — | 🟡 Acknowledged | Fixed in 2cb2e2f9 but unmarked tier headings (`## Red findings`); revisit if a rubric generator writes tier headings without a mark or the Must words (research doc, pre-mortem 3) |
| A5 | `read` uses tab as its separator, and bash merges consecutive tabs. A row with an empty Status cell therefore shifts its Q-ID into `st`, so a red with an answered Q-ID prints as open, with the Q-ID shown as its status. This over-reports and never hides a red. Location: `scripts/lib/rubric-check.sh:181` | Correctness | Incorrect (medium), single-replicate | Fact-check r2 + security Info + architecture Minor | for-author | — | ✅ Fixed in 2cb2e2f9 | — |
| A6 | Three set -e hazards in a function that check_line calls plainly. The awk at `:200` aborts `--check`/`--merge` with a nonzero exit if it fails, and every printed line is lost. A failing `out="$(check_answer …)"` at `:188` would do the same. A `sort` failure at `:170` prints nothing, silently. All three are unlikely (write errors only), but each contradicts "never changes an exit code" (`:5`, `build-loop.sh:439`). | Correctness | Mostly accurate; api Minor | Fact-check (r1, r3 residue) + api-consistency | for-author | — | ✅ Fixed in 2cb2e2f9 | — |
| A7 | The header says the `none` line names the paths outside docs/. The code prints a count. Location: `scripts/build-loop.sh:455-457` | Docs | Incorrect (high), doc only | Fact-check + api-consistency | for-author | — | ✅ Fixed in 2cb2e2f9 | — |
| A8 | The comment says cut() cuts on a character boundary, but it can leave a lone 0xC3 byte (invalid UTF-8). The appended `...` also makes the field up to 203 bytes. Location: `scripts/lib/rubric-check.sh:16-17,53` | Docs / Correctness | Incorrect (high), cosmetic | Fact-check (r2, r3) | for-author | — | ✅ Fixed in 2cb2e2f9 | — |
| A9 | Amber closure checks for keywords, not real references. `not on the roadmap`, `no trigger needed`, `triggered nothing`, and any `row N` all close an amber. TODO must be upper case. The header and comment describe these as references. Location: `scripts/lib/rubric-check.sh:70-72`, `scripts/build-loop.sh:449-451` | Correctness | Mostly accurate | Fact-check (r1+r2+r3) | for-author | — | ✅ Fixed in 2cb2e2f9 (documented as keyword matching, the finding's second option) | — |
| A10 | Header precision. Only files directly in docs/reviews/ are read, and any prefix before code-review-rubric must end in `-`. Superseded lines print before every rubric's lines, and with 3+ dated files `by NEW` can name a file that is not read. "Follow its last change" means "not an ancestor of it", so a fix made earlier on a side branch and merged in later still counts. Location: `scripts/build-loop.sh:440-454`, `scripts/lib/rubric-check.sh:131-143,141` | Docs | Mostly accurate | Fact-check (r1+r2+r3) | for-author | — | ✅ Fixed in 2cb2e2f9 | — |
| A11 | rubric_lines depends back on its only caller. It reads check_line's locals `ps` and `ss` through dynamic scope, plus build-loop.sh's gate_git, fp_blob and GATE_TMP, and an SC2154 suppression hides the warning that would catch a rename. A rename fails loudly but takes every `--check` and `--merge` down with it. Location: `scripts/lib/rubric-check.sh:131-152,173,198` | Architecture | Coupling | architecture-review | for-author | — | ✅ Fixed in 2cb2e2f9 | — |
| A12 | The comment cites rubric.md's "Status words" table, which is on neither main nor 66304b3d; it exists only on the unlanded `docs/review-rules-close-gaps`. That table also says "any other first word reads as open", while the parser closes ambers on keywords anywhere in the cell. Location: `scripts/lib/rubric-check.sh:27-29` | Architecture | Coupling | architecture-review | for-author | — | ✅ Fixed in 2cb2e2f9 | — |
| A13 | `PATH` is printed raw. Path and deny lines mask unusual characters through `showpath` (`build-loop.sh:1265-1267`), but the rubric lines do not. A space in a rubric file name makes `open PATH ID` ambiguous, and the space split of the superseded line names the wrong files. Location: `scripts/lib/rubric-check.sh:159,171,192` | API | Inconsistent | api-consistency | for-author | — | ✅ Fixed in dd6aa89e (as A15) | — |
| A14 | No test covers the corrected red rule. Missing cases: G1, a red naming an amber successor; G2, `same as R3`; G4/G5, Split or Carried with negating text; G6, an empty Status cell with an answered Q-ID. All were confirmed by execution, so test-strategy's high severity maps to 🟡. The report has fixture rows written to fail today. Location: `test/scripts/build-loop-check.bats` (near `:1189`) | Tests | test-strategy high (executed) | test-strategy (Executable-defect channel) | for-author | — | ✅ Fixed in dd6aa89e (as A16) | — |
| A15 | (pass 2, new in 2cb2e2f9) The superseded entries join SLUG and path with a space. With a dated slug that contains a space, `${newest[${x%% *}]}` hits set -u: the line prints `superseded ? by  (not read)` and stderr gets `unbound variable`. The exit code stays 0. Fix: keep the old and new paths in two arrays, or join them with a tab or NUL, and look newest up by an index rather than by a re-split. Location: `scripts/lib/rubric-check.sh:188-189,201` | Correctness | Incorrect, new regression | Fact-check pass 2 | for-author | — | ✅ Fixed in dd6aa89e | — |
| A16 | (pass 2) Test gaps after the fix: no case pins `Split; no branch yet`, `Split — no roadmap item` or an old Carried target (R2); none covers C3 (a red superseded by an answered red now closes); none covers a slug with a space (A15). Location: `test/scripts/build-loop-check.bats` | Tests | Mostly accurate | Fact-check pass 2 | for-author | — | ✅ Fixed in dd6aa89e | — |
| A17 | (pass 2) Two stale texts. The research doc still says a Split naming a Q-ID closes, though that case is now qref. The test title at `:1224` still says a successor can be named by "as", and the test passes only because "still open" is a negation. Fix: reword both. Location: `docs/working/research-2026-11-14-merge-rubric-gate.md:62`, `test/scripts/build-loop-check.bats:1224` | Docs | Stale | Fact-check pass 2 | for-author | — | ✅ Fixed in dd6aa89e | — |
| A18 | (pass 2) A fence is matched on its first 3 characters, so a 4-backtick fence closes on a 3-backtick line inside it. The result is loud `bad` lines, not a silent drop. Fix: record the opening fence's length and character, and close only on a fence at least as long. Location: `scripts/lib/rubric-check.sh:103` (doc `:29-31`) | Correctness | Mostly accurate | Fact-check pass 2 | for-author | — | ✅ Fixed in dd6aa89e | — |
| A19 | (pass 2) The test title and commit say "negation anywhere in the cell", but `not`, `open` and `still` count only in the first clause, so `Fixed; follow-up still needed` reads as fixed. Fix: move these words into `$NEG`, or say first clause in the title and commit text. Location: `scripts/lib/rubric-check.sh:85`, `test/scripts/build-loop-check.bats:1286` | Correctness / Docs | Mostly accurate | Fact-check pass 2 | for-author | — | ✅ Fixed in dd6aa89e (documented: not, open and still are first-clause only) | — |
| A20 | (pass 2) Smaller doc claims. `build-loop.sh:462` says `?` masking is showpath's, but only pathform's character set is used, not all of pathform's checks. `rubric-check.sh:53-55` should say a successor's Q-IDs carry over too. The research doc `:114-115` says A1 is fixed, which overstates it. Fix: reword. | Docs | Mostly accurate | Fact-check pass 2 | for-author | — | ✅ Fixed in dd6aa89e | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Each open red's Q-ID costs one check_answer call (~19 ms, reading the 750 KB archive), cached only within one rubric_lines call; worst case today ~130 ms per brief. `rubric-check.sh:185-191` | performance-reviewer | Low | for-author | — | 🟢 Open |
| C2 | No tests for the unread paths (fp_blob, parse, rev-list failures), a check_answer `skip`, 3+ dated rubrics, rubric lines on a refusing `--check`, or a branch that changes no path (G7-G11, G13, G14). | test-strategy | medium | for-author | — | 🟢 Open |
| C3 | Open design question G3: should a red superseded by a red whose Q-ID is answered close? Today it stays open, and the comment does not say which is intended. | test-strategy | low | for-author | — | Fixed in 2cb2e2f9 |
| C4 | SKILL.md step 7 (`:668-671`): the list of rubric lines the final message names leaves out `superseded`, includes the docs-only `none` note, and does not say whether a rubric `unread … could not be read` line is the environment's. | api-consistency | Minor | for-author | — | Fixed in dd6aa89e |
| C5 | No test checks that the rubric lines come last: `unrubric` pulls `^rubric ` lines from anywhere in the output. | api-consistency | Minor | for-author | — | 🟢 Open |
| C6 | Pin one authoritative description of the `rubric BRIEF:` keyword grammar (and an ID field without markup) before stage [4] makes an `open` red refuse a merge. | api-consistency + architecture | Informational | for-author | — | 🟢 Open |
| C7 | rubric_lines and fp_blob share scratch file names in GATE_TMP by convention only. | architecture-review | Informational | for-author | — | 🟢 Open |
| C8 | Untested bypass candidates: HTML comments, a tab or pipe in the ID cell, duplicate IDs across tiers, a space in the slug. | security-reviewer | Informational | for-author | — | 🟢 Open |
| C9 | The commit bb0030a1 Notes still state the old red rule (fix, answered Q-ID or override-log row), already wrong when written. This is history no new commit can edit, so it is not tiered. The run is read-only, so no `Accepted-immutable` override-log row was written; whoever lands the branch may add one. | Fact-check (r2 Stale, r3 Incorrect) | n/a | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `chore/dev-cycle-2026-10-15-0357` / 2026-10-15 (override-log.md:830) | Replace-ref guard misses `info/grafts` (`scripts/build-loop.sh:622` at the time) | 🟡 → Acknowledged (TODO, Q-180) | Loop at cap; Q-180 tracks it | Location-only candidate (near the new source block). Different subject, so not inherited and not re-flagged. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| An override-log row, a trigger, Accepted-immutable or "Corrected" no longer closes a red through the red's own cells | ✅ Confirmed | `rubric-check.sh:68-69` — "return ($qids ne "" ? "qref" : "open", $qids) if $tier eq "red";"; orchestrator probe: `R5 Corrected → open`, `R6 Override-log row 9 → open` (FC Claim 14, executed) | Fact-check + orchestrator probe | for-orchestrator-synthesis |
| The rubric lines change no verdict and no exit status on every input tested, and `--merge` lands past an open red | ✅ Confirmed | targeted bats at 66304b3d: check 6/6, merge 1/1, orchestrator 11/11 (FC Claim 14, executed). Narrowed: the errexit residue in A6 is excluded. | Fact-check | for-orchestrator-synthesis |
| No existing consumer of `--check`/`--merge` output breaks on the trailing lines | ✅ Confirmed (scoped) | `--check` keys its verdict on the first line and `--merge` replaces only line 1; enumeration over scripts/, scripts/lib/, hooks/ found no parser of later lines | api-consistency (static consumer trace) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. The orchestrator spot-checked R1 and A1-A3 by probe and the code excerpts quoted above.

---

## ⏭️ Skipped Core Critics

Pass 2: security-reviewer, api-consistency-reviewer, architecture-review and test-strategy were skipped, with the reason `loop-pass short-circuit (behavioral red confirmed)`: R2 was confirmed at fact-check. No enforcement file is touched (`hooks/live-verify-gate.sh` enforcement and host_tools regexes), so no security run was forced. performance-reviewer was skipped by orchestrator judgment: pass 1 found one Low on a cold path, and the delta adds no per-path processes. All of them run on the next pass, because a short-circuit is allowed once per loop.

Pass 1:

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/lib/rubric-check.sh:113-124` | FC1, FC2, security F2, api F1, arch F3, test G1/G2 | distinct defects: every fragment states the same mechanism and fix in full, so it is merged into R1 rather than composed |
| 2 | `scripts/lib/rubric-check.sh:57-69` | FC3, security F1/F4 | distinct defects: the Split/Carried bare words (A1), the first-clause negation (A2) and the answer-value blindness (A3) are separate mechanisms |
| 3 | `scripts/lib/rubric-check.sh:170-200` | FC5, FC13, security F5, arch F4, api F3 | distinct defects: the tab collapse (A5) and errexit (A6) are separate mechanisms |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

Artifacts (all under /tmp/claude-1000/-workspace/275d154f-84d5-4d90-894d-5f67e1be3fd3/scratchpad/2026-11-14-merge-rubric-gate/review1/): code-fact-check-report.md (merged), code-fact-check-report-r1/r2/r3.md, security-review-2026-11-14.md, performance-review-2026-11-14.md, api-consistency-review-2026-11-14.md, architecture-review-2026-11-14.md, test-strategy-review-2026-11-14.md, probe-orch/t.md.
