Commit: 224dd52d
Loop-pass short-circuit: used at 224dd52d
# Code Review Rubric

**Scope:** full unit range `feat/build-loop-u1a...feat/build-loop-u1b` (0797ed32, 224dd52d; 392 added lines in 3 new files). Iteration 1 is a `--loop-pass` (k=1). Full scope because no canonical u1b rubric existed yet. | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Pass outcome: first-red short-circuit (decision 032 #4, mechanic 2). The fact-check confirmed a behavioral 🔴 (Claim 4a, executed), so the critic panel was not dispatched. This is the loop's first short-circuit; the marker above means the next pass runs the full panel. None of the files is an enforcement file (`hooks/live-verify-gate.sh` regex), so mechanic 7 did not force the security critic.

Reports: `code-fact-check-report-build-loop-u1b.md` (k=1, loop pass, decision 031; execution logs in the reviewer's scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/`, not in `docs/reviews/execution-logs/`, because this pass may write only `docs/reviews/`).

Deviations from the skill:
- The agent read its skill file itself; the skill text was not pasted into its prompt.
- The diff was delivered as a saved patch file (`/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/diff.patch`, about 6.2k tokens) for the agent to read, not inlined.
- Stage 2.5 did not apply.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | The `Self-merge never:` check does not enforce its documented "single spaces". The separator regex excludes only the space character (`^[^\ ]+(\ [^\ ]+)*$`), and `read -ra` splits on IFS (space or tab), so tabs pass as separators. A leading tab, a trailing tab and tab runs pass too. `NEVER="$v"` then stores the raw tab-bearing value. Executed: `Self-merge never: a<TAB>b` printed `never a^Ib set` and `policy self-merge set`, but a trailing *space* is refused as malformed. Consequence (FC escalation to security): if U2's gate splits NEVER on single spaces, `a<TAB>b` becomes one glob that matches nothing, and a path the user meant to protect can self-merge (fail-open). Fix: refuse any byte other than a single space between entries (e.g. reject `$'\t'` in `$v`, or test against `[^[:space:]]`), and add the tab cases to T45. | Behavioral / contract (security-adjacent) | Incorrect (high confidence), behavioral, executed | Fact-check (Claim 4a) | `scripts/build-loop.sh:141` — `if [[ "$t" != "Self-merge never: "* \|\| ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then`; `:145` `read -ra parts <<<"$v"`; `:154` `else NEVER="$v"; …`; header `:21` "(single spaces; each glob uses" | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**: either (a) a
discoverable TODO, or (b) a concrete revisit trigger. A note with neither is not
qualifying.

On a short-circuited pass, ambers are not collected (mechanic 4); the next pass's full panel collects them. The rows below are the dead-letter rule's forced rows: fact-check escalations whose addressee critic never ran because the pass short-circuited.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Escalation to security-reviewer: a tab-separated `Self-merge never:` value is accepted and stored raw; fail-open if U2 splits on single spaces (`scripts/build-loop.sh:141-154`). | Security | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | — | 🟡 Open | The addressee never ran (loop-pass short-circuit). Same mechanism as R1: fixing R1 discharges it, and next pass's security critic re-reads it. |
| A2 | Escalation to security-reviewer: copies that render as the key but are not counted are hidden, not "a second line": bold `**Build-loop policy:** …`, a heading, a mid-file BOM before the key (`scripts/build-loop.sh:102-108`). In every probe the hidden copy failed toward the counted line, not toward self-merge. | Security | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | — | 🟡 Open | The addressee never ran (loop-pass short-circuit). Next pass's security critic decides; the counting rule itself is a settled design choice, but the residue is not. |
| A3 | Escalation to test-strategy: the no-echo assertion `[[ "$output" != *$'\xc3'* ]]` can fail only for the `café/` entry; nothing checks that the ASCII malformed entries stay out of the output (`test/scripts/build-loop-read.bats:137`). | Tests | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | — | 🟡 Open | The addressee never ran (test-strategy was not auto-selected, because the diff carries tests). |
| A4 | Escalation to api-consistency-reviewer: `.github/` (and `.gitignore`) cannot appear in `Self-merge never:`, because the lib refuses any part *starting* `.git`, in any case. Listing it makes the line malformed and turns self-merge off repo-wide. This is a user-facing settings contract; check it against the plan's intent for protected paths (`scripts/lib/dev-cycle-read.sh:146` via `scripts/build-loop.sh:148`). | API consistency | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | — | 🟡 Open | The addressee never ran (loop-pass short-circuit). The doc half is FC Claim 4c, listed below. |

### Fact-check findings not tiered on this short-circuited pass

The merged fact-check report already carries these findings. They are listed here so the fix commit can address them with R1; next pass tiers them.

- **FC 4c**, Incorrect (high), doc vs. code, would be 🟡 under decision 031. Header `scripts/build-loop.sh:23` "no .git" understates the rule: any part starting `.git` in any case is refused (lib `:129`, `:146`), so `.github/` and `.gitignore` are refused. It needs rewording, or a design change if `.github/` should be listable (see A4).
- **FC 7**, Mostly accurate. Header `:28-33`, the untrusted-file list, needs two qualifiers. The BOM refusal applies to line 1 only: a BOM before a key on line 2 hides that line instead of refusing the file. The `<`, open-comment and link-reference refusals apply only outside a fence.
- **FC 9**, Mostly accurate. `:37` "Output passes through the lib's scrub": the perl-missing and lib-missing messages (`:43`, `:49`) print before `scrub_reexec`. Neither carries repo text.
- **FC 24**, Mostly accurate. Commit 0797ed32's "never echoed": the test discriminates only on `\xc3` (same as A3).
- **FC 25**, Mostly accurate. Commit 224dd52d's "byte-exact" should say "after one trailing CR", as the header and plan F1 do. The commit is unmerged, so it can be amended; no Accepted-immutable row applies.
- FC notes on Verified claims, not findings:
  - `-h` is not in the header's Usage line.
  - `-h extra` prints help and exits 0.
  - No test prints `git log --graph` on failure, as the plan's test spec asks.
  - `a` and `a/` both pass the "none twice" check, because it compares raw text.
  - Empty parts (`a//`) are refused, which the header does not mention.

---

## 🟢 Consider

Not collected on a short-circuited pass (mechanic 4).

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| — | None this pass. | — | — | — | — | — |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u0a` / 2026-10-05 | A test should source the lib from build-loop.sh's side (`scripts/lib/dev-cycle-read.sh:6-14`, arch I2) | 🟢 → Defer | No second caller until U1 | Revisit trigger fired: build-loop-read.bats now runs build-loop.sh against the lib. Not re-flagged. |
| `feat/build-loop-u0a` / 2026-10-05 | Header note that a change runs both suites (arch I3) | 🟢 → Defer | Until U1 | Partly met: the test header names dev-cycle.bats; the lib header is not in this diff. Not re-flagged. |
| `feat/build-loop-u0a` / 2026-10-05 | D6 must hash-check the sourced lib (security) | 🟢 → Defer | U3b's T33 | Inherited: build-loop.sh sources the lib from SCRIPT_DIR; the hash check stays U3b's. |
| `feat/build-loop-u0c` / 2026-10-05 | build-loop.sh should call the lib directly, not dev-cycle.sh per path (perf I1) | 🟢 → Defer | U1/U2 review | Consistent: build-loop.sh sources the lib, with no subprocess. Not re-flagged. |
| `feat/build-loop-u0a` / 2026-10-05 | need_root's pwd -P fork per call | 🟢 → Won't-Fix | Within noise | Inherited; --settings makes no per-path calls. |
| `feat/build-loop-u0b` / 2026-10-05 | --merge must check main_by_name, not resolve_main's status | 🟢 → Defer | U3 | Consistent: build-loop.sh calls `resolve_main \|\| true` and then gates on main_by_name. |

---

## ✅ Confirmed Good

None claimed on a short-circuited pass; the terminal pass decides ✅ rows.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| security-reviewer | loop-pass short-circuit (behavioral red confirmed) | FC Claim 4a Incorrect (high, executed, behavioral); not an enforcement file |
| performance-reviewer | loop-pass short-circuit (behavioral red confirmed) | same |
| api-consistency-reviewer | loop-pass short-circuit (behavioral red confirmed) | same |
| architecture-review (structural, auto-selected: new module) | loop-pass short-circuit (behavioral red confirmed) | same |

---

## 🧩 Composition check

No multi-source co-located clusters qualified.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
