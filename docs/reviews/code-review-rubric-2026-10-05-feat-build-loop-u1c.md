Commit: 553a50d5
# Code Review Rubric

**Scope:** unit range `feat/build-loop-u1b...feat/build-loop-u1c` at 553a50d5 (unit commits 859e29e8, aaae80c6, 553a50d5; merges 121aa63e and 83b9fd49 bring in u1b and are context only). 399 changed code lines in 3 files. Iteration 1, loop pass (`--loop-pass`), fact-check k=1. | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Reports (all `Commit: 553a50d5`):
- `code-fact-check-report-build-loop-u1c.md`: k=1 loop pass, 54 claims: 38 Verified, 13 Mostly accurate, 1 Incorrect, 2 Unverifiable.
- `security-reviewer-review-2026-10-05-build-loop-u1c.md`, `performance-reviewer-review-2026-10-05-build-loop-u1c.md`, `api-consistency-reviewer-review-2026-10-05-build-loop-u1c.md`
- `architecture-review-review-2026-10-05-build-loop-u1c.md`: auto-selected because the diff adds a public mode (`--status`) and output contracts that U2–U4 parse.

Execution logs and probes are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c/<agent>/`, because this pass writes only review reports.

Deviations from the skill:
- Scope came from the caller's explicit range, not the loop-pass default. No canonical u1c rubric existed, and the full branch against main would also include u1a and u1b.
- Agents read their skill files and the shared context block from disk instead of having them pasted into the prompt. The block is `.../review-u1c/orch/shared.md` and `shared-stage2.md`, about 22k tokens, which is inline-mode size.
- Stage 2.5 was skipped because this is a loop pass. Critics' routed endorsements are still *pending execution verification*.
- No first-red short-circuit: Stage 1 found no behavioral red (Claim 12b is doc-only). The only red came from the critics' single wave, so nothing was left to skip.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | **Hard constraints in a near-miss shape are dropped without warning, and the line that gates dispatch still reads `constraints ok`.** CONSTRAINTS_AWK recognises only `^(- )?[HS][0-9]+: [^ \t]`. Every other line is ignored, not refused. The probes ran each of these with no `success:` line and got `constraints ok 1-hard 0-soft`: `* H2:`, `1. H2:`, `H2:  x` (two spaces), `H2:<TAB>x`, an indented `H2:`, lowercase `h2:`, `**H2:**`, `### H2:`, `> H2:`, `H10 :`, a Cyrillic H, and a table row (security: 14 shapes; api-consistency: 8). Related problems: a `success:` line under an unrelated heading satisfies a pending H1, and IDs are compared as written, so `H1` and `H01` are two constraints, while `Dispatched:` and `slots` refuse leading zeros (api F5). The same script's settings reader refuses near-miss key copies by matching on letters only (`:33-35`), so this reader is the odd one out. The header promises "Only "ok" lets the orchestrator dispatch" (`:32`). **Escalated 🟡→🔴**: three independent sources converge (security Medium, api-consistency Inconsistent, fact-check Claim 2 Mostly accurate), and the critics' probes corroborate it by execution. Fix: refuse, as `unreadable`, any line whose letters and digits alone start like `h<digits>` or `s<digits>` but that is not the exact form, and compare IDs by number. | Security / API contract | security Medium; api Inconsistent; FC Mostly accurate | security-reviewer F2 + api-consistency F1/F5 + fact-check Claim 2 (convergence; corroborated by executed probes) | `scripts/build-loop.sh:152` — `/^(- )?[HS][0123456789]+: [^ \t]/ {`; `:160` — `/^[ \t]*(- )?success: [^ \t]/ { pend = "" }` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**: either (a) a
discoverable TODO, or (b) a concrete revisit trigger. A note with neither is not
qualifying.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | **`marker_kind` parses the tip commit's header by its own rules, not git's.** The last `tree` line wins (git uses the first). A `parent` line counts wherever it appears. The parent text goes to `rev-parse` as a revision expression, not a checked 40-hex id. `$(...)` drops NUL bytes. Objects made with `hash-object --literally` all printed `ready`: a tip that adds `evil.txt` (git's diff shows it), a tip git reads as a root commit, a `parent feat/a` header, and the subject `handoff: \0ready`. Executed. Stated intent (`:44-46`): "the tip is an empty commit with one parent". Mechanism (`:262-267`): `case "$l" in "tree "*) tree="${l#tree }" ;; "parent "*) np=$((np + 1)); parent="${l#parent }" ;; esac`. The runtime behaviour contradicts the intent, so the row also carries Contested-Soundness. Impact depends on U2/U3b: D7's gate diffs with git's own tree. Fix: read the tree, parents and message through git (`git rev-parse "$sha^{tree}"`, `git rev-list --parents -n1`, `git log -1 --format=%B`), and require 40-hex. | Security | Medium; Contested-Soundness | security-reviewer F1 (+ Soundness cross-check) | for-author | — | 🟡 Open | — |
| A2 | "Subject" in the header (`:51-53`, `:59-60`) and in aaae80c6's message is really the raw first line of the message, not git's subject. A message that starts with a blank line (git subject `handoff: ready`) reads `working`, not the promised skip. A whitespace-only second line skips as "runs onto a second line". Both fail closed. Folds into A1's fix if the message is read through git. | Docs / contract | Mostly accurate | Fact-check Claims 10, 44 | for-author | — | 🟡 Open | — |
| A3 | The `--status` skip contract says a *missing* `Dispatched:` line is a skip. The code checks the line only when it is present (`:306`), the same header says "0 without one" (`:53-54`), and T5/T6 assert 0. The header was added in unmerged aaae80c6, and U4's skill will be written against it. Fix the wording: "its Branch: line is missing or malformed, or its Dispatched: line is malformed". Not escalated: the convergence's only corroboration is the doc-only Incorrect that decision 031 caps at 🟡. | Docs / API contract | Incorrect (high), doc-only; api Inconsistent | Fact-check Claim 12b + api-consistency F2 | for-author | — | 🟡 Open | — |
| A4 | The F31 same-branch count (`:287`) lists only `docs/working/briefs/`, but `--status` accepts and reports `briefs/closed/` briefs. Reproduced: an open brief in `closed/` and an open brief in `briefs/` naming one branch both print `ok`, against the header's `:58-59`. The lib has no single brief-path predicate: `isbrief` covers `briefs/` only, and the `closed/` regex is inline at lib `:161` and `:324`. Fix: choose one rule (count `closed/`, or refuse an open brief in `closed/`) and put one predicate in the lib. Convergence: security + api + architecture + fact-check; corroborated by execution. | Security / Architecture | security Low; api Minor; arch Minor; FC Mostly accurate | security F3 + api-consistency F3 + architecture F2 + fact-check Claims 13, 22, 45 | for-author | — | 🟡 Open | — |
| A5 | `SHARED_BRANCHES=""` (`:283`) defaults to "no shared branch". A mode that judges a brief without calling `shared_branches` first lets F31 through silently, and U2's `--check` is the next caller that would have to remember the order. Fix: make the unset state fail closed, or have one function load `read_settings` and `shared_branches` together. | Architecture | Coupling | architecture-review F1 | for-author | — | 🟡 Open | — |
| A6 | The header says `--status` reads "from the default branch's commit" (`:36-37`). `check_brief` also checks the brief's working-tree path, so a symlink there makes the brief skip. This fails closed. Fix: add one clause to the header. | Docs | Mostly accurate; arch Informational | Fact-check Claim 4 + architecture F4 | for-author | — | 🟡 Open | — |
| A7 | The read_settings comment says "POLICY and NEVER are for the modes that judge a brief (--status, then the gate)", but `--status` never reads NEVER. | Comment | Mostly accurate | Fact-check Claim 17 | for-author | — | 🟡 Open | — |
| A8 | The `local LC_ALL=C` comment (`:275-277`) says setting it "never warns". When bash restores the caller's locale on return and that locale is not installed (this sandbox's en_US.UTF-8), a stopped or bad-subject tip adds `warning: setlocale…` on stderr. Stdout and the exit code are unchanged. The suites cannot see it because `bl_setup` sets `LC_ALL=C`. | Comment / stderr | Mostly accurate; perf Informational | Fact-check Claim 21 + performance F6 | for-author | — | 🟡 Open | — |
| A9 | The fixture `tip` says "exactly MESSAGE", but `printf '%s\n'` stores MESSAGE plus a trailing newline (`test/lib/build-loop-fixtures.bash:57-60`). | Tests / comment | Mostly accurate | Fact-check Claim 27 | for-author | — | 🟡 Open | — |
| A10 | The T7 test name says spoofed markers "read as unreadable". They produce a "not a marker" skip line (`test/scripts/build-loop-read.bats:244`). | Tests / comment | Mostly accurate | Fact-check Claim 32 | for-author | — | 🟡 Open | — |
| A11 | Two commit-message imprecisions, both in unmerged commits. 859e29e8 says "without echoing the reason", but that is asserted only for the é and ESC cases, not bidi; the code never echoes any reason. aaae80c6 says the name reaches git "only through show-ref --verify"; it also reaches `git check-ref-format` twice, which is harmless. | Commit record | Mostly accurate | Fact-check Claims 41, 42 | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `shared_branches` grows quadratically with the number of briefs on main. It calls `main_entry` twice per brief, and each call's `ls-tree -t` lists every sibling in `briefs/`. Whole pass: 72 ms, 1.16 s and 15.7 s at N = 10, 100 and 500. `--status` with one argument: 132 ms at N=10, 1.26 s at N=100, 15.2 s at N=500. A probe that took modes from the one listing the code already makes ran linear: 21 ms, 181 ms and 977 ms. Fix in the caller, not in `main_entry`. | performance-reviewer F1 | Low | for-author | Row 220 (`feat/build-loop-u1a`, Won't-Fix): **premise changed**, see Considered Overrides | 🟢 Open |
| C2 | `status_line` reads each brief's tree entry 3 times and its contents twice, because `check_brief` runs in `$(...)` and its fields are lost. Each extra argument costs 26 ms at N=10, 34 ms at N=100 and 69 ms at N=500. Architecture F5 makes the same point; it follows from the settled `BRIEF`-global row. | performance F2 + architecture F5 | Low / Informational | for-author | Row 229: consistent | 🟢 Open |
| C3 | `--status` reads `docs/constraints.md` and never uses the result: 4 extra processes, about 2–5 ms. | performance F3 | Informational | for-author | — | 🟢 Open |
| C4 | `lower` forks one `tr` per open brief, about 0.9 ms each. | performance F4 | Informational | for-author | — | 🟢 Open |
| C5 | U4's skill should call `--status` once with every brief. Calling it once per brief repeats C1's pass each time: about 9 s for 30 briefs, against 300 ms for one call. | performance F5 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C6 | The constraints result exists only as the display string `CONSTRAINTS_LINE`. Policy and never also have machine values (`POLICY`, `NEVER`). Add `CONSTRAINTS=ok\|missing\|none-hard\|unreadable` so U3's `--start` does not string-match prose. | architecture F3 | Minor | for-author | — | 🟢 Open |
| C7 | The lib header still calls build-loop.sh "planned" (`scripts/lib/dev-cycle-read.sh:2-3`, `:10-12`). | architecture F6 | Informational | for-author | Row 242 (Defer): **revisit trigger (U1c) met** | 🟢 Open |
| C8 | The "a line counts as a copy" paragraph (`:33-35`) now sits after the constraints entry and reads as if it governed constraints. | api-consistency F4 | Minor | for-author | — | 🟢 Open |
| C9 | `unreadable` covers both an unreadable file and a grammar error, where the never line uses `malformed` for the latter; the plan fixes this vocabulary. Separately, the `*)` arm (`:246-247`) turns any unexpected awk output into the "listed twice" message. | api-consistency F6 | Informational | for-author | — | 🟢 Open |
| C10 | STATE `new` also covers a brief already moved to `closed/`, inherited from `--check-brief`. The header (`:40`) does not say so. | api-consistency F7 | Informational | for-author | — | 🟢 Open |
| C11 | The ahead count follows `.git/info/grafts` and shallow files. A graft made a marker already on main read as feat/a's `ready`. `GIT_GRAFT_FILE=/dev/null` turns this off. It gives a loop nothing beyond the ref writes it can already make. | security F4 | Informational | for-author | — | 🟢 Open |
| C12 | A crafted committer line makes DATE print the literal `%cs` or `1970-01-01`, breaking the header's YYYY-MM-DD promise (`:330`). | security F5 | Informational | for-author | — | 🟢 Open |
| C13 | Unverifiable claims. Claim 3: "every loop prompt carries" and "only ok lets the orchestrator dispatch" depend on U3/U4 code; both match the plan. Claim 47b: aaae80c6 says "79 ms" for the 3 real briefs; the fact-check measured 109–112 ms under load. The ~1 ms/brief figure and the early-stop mechanism were verified. | Fact-check Claims 3, 47b | Unverifiable | for-orchestrator-synthesis | Row 201: trigger met; numbers say no action | 🟢 Open |
| C14 | The fixture helper `status_of` is never used. | Fact-check note | Informational | for-author | — | 🟢 Open |
| C15 | Possible shared root, needs adjudication: A1 (header parse) and A2 (subject read) both come from `marker_kind` hand-parsing the raw `cat-file commit` object. Reading tree, parents and message through git would close both. | Composition cross-check (fragments: A1, A2, FC 10/21/44) | — | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u0b` / 2026-10-05 (row 201) | check_brief's `-G` walk grows with history, once per brief | 🟢 → Defer (trigger: U1's `--status`) | No baseline | Trigger met. Measured at 2 ms per brief on this repo and 4.4–12.7 ms in synthetic repos (performance), about 1 ms (fact-check). No action; inherited. |
| `feat/build-loop-u0a` / 2026-10-05 (row 212) | need_root forks `pwd -P` per check | 🟢 → Won't-Fix | Within noise | Trigger nominally met. 0.36 ms per argument; the decision holds. Inherited. |
| `feat/build-loop-u1a` / 2026-10-05 (row 220) | main_entry's `ls-tree -t` cost | 🟡 → Won't-Fix (49 entries, one lookup) | Measured per lookup | **Premise changed.** `--status` makes 2N + 3k lookups per run, each listing all of `briefs/`. Surfaced as C1 (Low) for a new decision; not re-tiered. |
| `feat/build-loop-u0b` + `u1b` / 2026-10-05 (rows 209, 247) | origin/HEAD naming a loop's branch | 🟢 → Defer to U3b's `--state` | Every resolve_main reader | Inherited. `--status` is another reader, but the premise is unchanged (security). |
| `feat/build-loop-u1a` / 2026-10-05 (row 228) | case-block copies for main_entry's result words | 🟢 → Defer (trigger: U2's fourth caller) | Two callers | Inherited. The constraints read reuses `main_file`; no fourth caller yet (architecture). |
| `feat/build-loop-u1a` / 2026-10-05 (row 229) | BRIEF as a global array | 🟢 → Won't-Fix | One parser | Inherited; C2's double read follows from it. |
| `feat/build-loop-u1b` / 2026-10-05 (row 242) | Lib header calls build-loop.sh "planned" | 🟢 → Defer (trigger: U1c) | Outside U1b's diff | **Trigger met**; surfaced as C7. |
| `feat/build-loop-u1b` / 2026-10-05 (row 246) | Test gaps G7, G8, G9, G11 | 🟢 → Defer (trigger: U1c or U2 touching build-loop-read.bats) | 400-line cap | Trigger met: U1c edits the file. test-strategy was not selected, so the gaps were not re-checked. The unit is at 399 lines. |
| `feat/build-loop-u1b` / 2026-10-05 (row 239) | `--help` prints a fixed line range | 🟢 → Won't-Fix | Re-derived per edit | Inherited. Fact-check Claim 15 executed: `2,67p` prints exactly the header. |
| `feat/build-loop-u1b` / 2026-10-05 (row 245) | Never line's status-word position | 🟢 → Won't-Fix | Plan's interface | Inherited (api-consistency). |
| `feat/build-loop-u1b` / 2026-10-05 (row 240) | Fixture copies the git env | 🟢 → Won't-Fix | Matches dev-cycle.bats | Inherited. A8 notes that `bl_setup`'s `LC_ALL=C` hides the stderr warning. |
| `feat/build-loop-u1a` / 2026-10-05 (row 233) | Untested main_entry bypass candidates | 🟢 → Defer (U2 T12/T26) | — | Inherited. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| `--status` and `--settings` write nothing to the working tree or `.git` | ✅ Confirmed (scoped to the runs probed) | `scripts/build-loop.sh:63`, "Read-only: writes nothing". FC Claim 14 (executed: before/after snapshot of the tree and `.git`) | Fact-check | for-orchestrator-synthesis |
| The tests were written first: at 859e29e8 the 8 new or changed tests fail and the other 8 pass | ✅ Confirmed | FC Claim 40 (executed: `git archive 859e29e8`, bats log `at-859e.log`) | Fact-check | for-orchestrator-synthesis |
| `-h` prints exactly the header block | ✅ Confirmed | `scripts/build-loop.sh:87`: `sed -n '2,67p' "$0"`. FC Claim 15 (executed) | Fact-check | for-orchestrator-synthesis |
| POLICY is self-merge only when main's policy is self-merge and the brief's first Policy: line is exactly `Policy: self-merge`; a malformed never line turns it off | ✅ Confirmed (scoped to T5's cases) | `scripts/build-loop.sh:311`: `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge`. FC Claims 6, 37, 43 (executed) | Fact-check | for-orchestrator-synthesis |

Narrowed by the cross-check: FC Claim 9 ("a tip is a marker only when … an empty commit with one parent") is Verified only for objects that git itself writes. Security F1's crafted objects contradict it, so it is not published as ✅ (see A1).

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/build-loop.sh:23-35`, `:150-162`, `:244-247` | FC 2, sec F2, api F1/F4/F5/F6, arch F3 | distinct defects: security F2 already states the mechanism (strict whitelist, everything else ignored) and the outcome. F4/F6/F3 are separate wording, vocabulary and interface points. Merged into R1, plus C6, C8 and C9. |
| 2 | `scripts/build-loop.sh:255-280` | sec F1, FC 10/21/44, perf F6 | needs adjudication → C15 (shared hand-parse root of A1 and A2). The locale point (A8) is separate. |
| 3 | `scripts/build-loop.sh:281-292`, `:312` | sec F3, api F3, arch F1/F2, FC 13/22/45, perf F1/F4 | distinct defects: the closed/ scope (A4), the fail-open default (A5) and cost (C1, C4) are different mechanisms. |
| 4 | `scripts/build-loop.sh:296-336` | FC 4/12b, api F2/F7, arch F4/F5, perf F2/F3/F5 | distinct defects: the wording (A3, A6) and the repeated reads (C2, C3) are separate. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
