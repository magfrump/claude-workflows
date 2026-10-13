Commit: 8389c477
Loop closed at 8389c477

# Code Review Rubric: feat/build-loop-u4a

**Scope:** full branch, `git diff main...HEAD` (main 774a0eef; first pass of the loop). Delivery mode: self-read (shared brief and diff file on disk).
**Iteration 1** (`--loop-pass`, k=1 fact-check, full core panel + architecture). No behavioral red, so no short-circuit. Stage 2.5 skipped (loop pass): three security endorsement claims (the CAS / fast-forward move, the judged tree and parents with no hooks, HEAD's commit not the index) stay *pending execution verification* for the final pass. The session's process exited mid-Stage 2; the security, API-consistency and architecture critics were resumed from their transcripts on an unchanged branch.
**Reports:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i1.md`, `security-review-2026-10-13-u4a-i1.md`, `performance-review-2026-10-13-u4a-i1.md`, `api-consistency-review-2026-10-13-u4a-i1.md`, `architecture-review-2026-10-13-u4a-i1.md`.

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | The Asked: rule checks only the IDs a brief held, not the ones added: appending another question's (answered) ID, or a first Asked: line naming one, passes, and --check-answer matches by ID alone, so that answer is applied to this brief (row 745's reuse). | security F1 (probes P1, P2) | Medium | `scripts/build-loop.sh` cycle_rules, `[[ "${an[$f]}" == "${ao[$f]}" \|\| "${an[$f]}" == "${ao[$f]}, "* ]]` | Fixed: asked_rule requires each added item to name an entry the questions files gain |
| A2 | --land-cycle lands docs/dev-cycle.md, docs/constraints.md, instruction files and dot paths unjudged; --merge refuses them under self-merge and --check-fix refuses them for in-cycle fixes. | security F2 (probe P4) | Medium | `case "$p" in ... *) continue ;;` | Fixed: truthrule's classes but `cycle` refuse in cycle_rules |
| A3 | `--expect` names main's commit under --land-cycle but the brief tip under --check/--merge; a caller passing the tip by analogy gets a misleading remedy. | api-consistency 1 | Inconsistent | `[[ "$EXPECT" == "$MAIN_SHA" ]]` | Fixed: `--main SHA` |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A4 | A brief deleted, or renamed to another file name, drops its Asked: IDs with no refusal. | security F3, fact-check claim 3 | Fixed (asked_rule) |
| A5 | Shared refusals say "index" / "stage again" under --land-cycle; the questions guard only matters for --cycle-diff. | api-consistency 2, architecture 2 and 6, security F5 | Fixed: guard moved into cycle_diff; cycle_rules takes SIDE (index / merge) |
| A6 | The header's --land-cycle refusal list omits read failures. | api-consistency 3, fact-check claim 9 | Fixed |
| A7 | `landed` line fields undocumented; comment BRANCH vs header B; reflog text. | api-consistency 4 | Fixed |
| A8 | Plan's script interface lacks --land-cycle; row 674's `entry` line is promised in the split note but not built. | api-consistency 5, architecture 7 | Fixed in the plan (as-built note: row 674 to U4b) |
| A9 | land_cycle repeats check_line's compute steps without its blob-presence check (store_check covers it, unsaid). | architecture 1 | Fixed (comment) |
| A10 | Chore merge message has no single definition beside gate_msg. | architecture 3 | Fixed: chore_msg |
| A11 | VERDICT has two producers; land_cycle set four of six keys; RAW_* reuse after cycle_rules unstated. | architecture 4 | Fixed: all keys set; comment |
| A12 | Header's Asked: wording; asked() comment vs brief_fields. | fact-check claims 3, 13 | Fixed |
| A13 | `lower` forked per path; brief reads per changed brief. | performance 1, 2 | Won't-Fix (override rows) |
| A14 | Combined usage error. | api-consistency 6 | Won't-Fix (override row) |
| A15 | New rules have no caller yet; U4b must name them. | api-consistency 7 | Defer to U4b (override row) |
| A16 | dev-cycle.sh keeps its own record glob. | architecture 5 | Defer (override row) |
| A17 | SKILL.md still lands via pr-prep. | architecture 7 | Defer to U4b (override row) |
| A18 | asked() vs brief_fields: no bypass. | security F4 | Won't-Fix (override row) |
| A19 | isrecord's "one per day" is orchestrator behaviour. | fact-check claim 19b | Defer to U4b (override row) |
| A20 | 722c2e10 cites row 749 under "no hooks run". | fact-check claim 24b | Won't-Fix (override row) |

## ⏭️ Skipped Core Critics

None.

## 🧩 Composition check

- `scripts/build-loop.sh` cycle_rules Asked: block (A1, A4, fact-check claims 3, 13; security, fact-check): distinct defects: A1 (added IDs) and A4 (dropped by deletion) are separate predicates on the same rule, each stated whole.
- `scripts/build-loop.sh` cycle_rules wording and guard (A5, A6; api, architecture, security, fact-check): distinct defects (wording vs placement), each stated whole.

## Considered overrides

- Rows 719, 722, 725, 745, 747, 749, 752, 753 (U3b2/U3c hand-offs to U4): answered by this unit; 745 more fully after A1/A4; 749's commit-side half stays U4b's (row 2026-10-13, claim 24b).

**Status:** iteration 1 found no red; 3 ambers fixed. Next: iteration 2 (`--loop-pass`, range 722c2e10..HEAD).

## Iteration 2 (`--loop-pass`, range 722c2e10..4e14d1cc, k=1 fact-check, full core panel + architecture)

No behavioral red at high confidence: the fact-check's one Incorrect (claim 4b) is behavioral at medium confidence, so no short-circuit. Prior ambers A1-A3: A2, A3 resolved; A1 resolved in part (B1-B3 below). Reports: `*-2026-10-13-u4a-i2.md` (fact-check, security, performance, api-consistency, architecture).

### 🟡 Must Address

| ID | Finding | Source | Severity | Status |
|---|---|---|---|---|
| B1 | An Asked: item is checked only at its start (`^(Q-[0-9]+)(@\|$)`): `, Q-002@def,Q-003` or `, Q-002@Q-003` passes with Q-003 an old answered entry. | fact-check claim 4b (Incorrect, medium, behavioral); security F-b | Medium | Fixed: items anchored `^(Q-NNN)(@[0-9a-f]{7,64})?$` |
| B2 | One new entry's ID can be appended to several briefs' Asked: lines; its one answer then applies to each. | security F-a | Medium | Fixed: each new ID added by one brief only |
| B3 | A brief changed in both briefs/ and closed/ under one name: the second path overwrote the first in the per-name map, hiding its change. | security F-c | Medium (Low conf.) | Fixed: two changed paths with one name on a side refuse |
| B4 | A cycle file spelled in another case (`docs/working/Questions.md`, `Briefs/`) passed every rule unjudged; lowering removed truthrule's case word. | security F-d | Medium (Low conf.) | Fixed: refused |

### 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| B5 | asked_rule read cycle_rules' locals by dynamic scope (silently passes from another caller); two call sites; the next rule must be added twice. | architecture 1, 3 | Fixed: the Asked: rule inline in cycle_rules; questions_rules has one call site |
| B6 | truthrule's fourth consumer unstated in the lib; refusal text claimed all of --check-fix. | architecture 2 | Fixed (lib comment, refusal text) |
| B7 | Refusals print truthrule's internal words (`instr`). | api 1 | Fixed: floor_why's prose |
| B8 | Plan lists --land-cycle under read modes; plan's --cycle-diff bullet lacks the new rules. | api 2, 5 | Fixed |
| B9 | Empty Asked: item's garbled refusal; "first" dropped; header said "any line". | api 3, fact-check claim 3 | Fixed |
| B10 | The moved questions guard suppresses other refusal lines, unstated. | api 4, architecture 5, fact-check claim 12 | Fixed (header) |
| B11 | Header's class list read as cycle files. | fact-check claims 2, 21b | Fixed (header); 70d24331's body: Won't-Fix (override row) |
| B12 | chore_msg names log_class but not the reverse. | architecture 4 | Fixed (comment) |
| B13 | land branches on authority in two places. | architecture 4 | Won't-Fix (override row) |
| B14 | Docs instruction files @-import are not refused here. | security F-e | Defer to U4b (override row) |
| B15 | Performance: no findings (truthrule 78 µs/path, asked grep 0.85 ms/item, new-ID awk ≤2 ms). | performance | — |

### 🧩 Composition check

- `scripts/build-loop.sh` Asked: rule (B1, B2, B3, B5; fact-check, security, architecture): distinct defects: item form, ID sharing, map collision and code placement are separate predicates, each stated whole.
- `scripts/build-loop.sh` cycle_rules truth rule (B4, B6, B7; security, architecture, api): distinct defects (case spelling, comment, wording).

**Status (iteration 2):** no red; four ambers fixed. Next: final confirming pass (no `--loop-pass`, full branch, k=3).

## Iteration 3: final confirming pass (no `--loop-pass`, full branch at c4e36d1d, k=3 fact-check, full core panel + architecture)

**Fact-Check Gate:** one Incorrect at high confidence (claim 1, the repeated-ID refusal names "another brief"; message-only, the refusal stands). Choice in /away: **fix first** (U3c precedent): d46cd00f, then the critic panel reviewed b1a6f0a2. Verdict agreement 23/31 (74%), every disagreement between adjacent wording verdicts. Reports: `code-fact-check-report-2026-10-13-u4a-final{,-r1,-r2,-r3}.md`, `{security,performance,api-consistency,architecture}-review-2026-10-13-u4a-final.md`.

### 🔴 Must Fix

None.

### 🟡 Must Address

| ID | Finding | Source | Severity | Status |
|---|---|---|---|---|
| C1 | --land-cycle never reads HEAD's history: any path outside the deny-list lands unjudged, so a chore branch carrying a loop's commits lands them, read as chore (P1: `src/app.sh`, `test/t.bats`). | security F1 | Medium | Fixed: allowlist, the cycle's own files, a .md under docs/ or README.md (--check-fix's scope) |
| C2 | An added Asked: ID is not tied to the brief its entry is for: an entry filed for brief y, its ID on brief x's line, passes; y's answer applies to x. | security F2 (the part of i2 F-a not taken) | Medium | Fixed: the entry's heading must end -STEM-N for the brief that adds it |
| C3 | Final fact-check claim 1 (Incorrect, message-only). | fact-check | Incorrect (message) | Fixed in d46cd00f |

### 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C4 | cycle_rules lacks the floor's "below" class (`AGENTS.md/x` landed). | security F3 (Low) | Fixed by C1's allowlist |
| C5 | ASCII-only lower: a Kelvin-sign `SKILLS/...` path landed. | security F4 (Informational) | Fixed by C1's allowlist |
| C6 | A refused questions file left cy.new empty, so every correct Asked: item also refused as "names no entry" (wrong cause). | architecture 1 (Minor, probed) | Fixed: questions_rules returns 2, only the item's form is then judged |
| C7 | Comments still say "--cycle-diff's" / "the index" for shared code. | architecture 2 | Fixed |
| C8 | The plan's U3b2 note says cycle-*.md; the narrowing is unrecorded; the --cycle-diff bullet lists only i1's rules. | api 1, 2; fact-check claims 5, 6 | Fixed (plan) |
| C9 | No test asserts the reflog text or hook absence. | api 3; fact-check escalation | Defer (override row) |
| C10 | Stale commit-message names (722c2e10, 70d24331); 4df6ec58's floor_why wording. | fact-check claims 2, 3, 7 | Won't-Fix (override rows) |
| C11 | Header: fast-forward reflog suffix. | fact-check claim 4 | Fixed in d46cd00f |
| C12 | state_start runs twice per iteration (~0.38 s each). | performance (considered, not filed) | — (by design: the land re-checks the state it lands from) |

Endorsement claims routed (`route: code-fact-check`): security 1-4 (the land writes what it judged with no hooks; --main and index refusals; the merge judged, rename refused; log_class's record name), performance 1 (the land's added time is land's re-checks). Stage 2.5 runs in the confirming pass below, over the fixed code.

### 🧩 Composition check

- `scripts/build-loop.sh` cycle_rules path rules (C1, C4, C5; security F1, F3, F4): **composed → C1**: one root, the rules were a deny-list over an unbounded path set; an allowlist of --check-fix's scope closes all three. Fragment rows keep their tiers.
- `scripts/build-loop.sh` Asked: rule (C2, C3, C6; security, fact-check, architecture): distinct defects (brief binding, message text, unread-file signalling).

### Iteration-4 gate (review-fix-loop.md hard cap)

The final pass found two Mediums, fixed in the commit after this one. **Decision: escalate**, as a narrow confirming pass (U3a1/U3a2/U3c precedent; in /away mode, Q-137's standing instruction): a k=1 fact-check of the fix range with Stage 2.5 over the routed endorsement claims, plus security over the fix range. Merge on no new Must Fix or Must Address; otherwise stop and file a `you: judgment` entry. Not split (331 code lines, one concern) and not abandoned.

## Confirming pass (fix range b1a6f0a2..ca95fead: k=1 fact-check with Stage 2.5, security)

Reports: `code-fact-check-report-2026-10-13-u4a-confirm.md` (with `## Submitted Claims`), `security-review-2026-10-13-u4a-confirm.md`. Final F1, F2 closed as filed; F3, F4 closed outside docs/.

| ID | Finding | Source | Severity | Status |
|---|---|---|---|---|
| D1 | The -STEM-N binding is anchored at a hyphen: an entry for a brief whose name ends in this brief's name binds here. | fact-check claim 3b (Incorrect, high, behavioral); security F-A | 🟡 Medium | **Merge stopped (gate): Q-141, interim [1]**: slug prefix letters and hyphens only; fixed in the commit after this one |
| D2 | The allowlist compares the path as spelled; --check-fix compares lower-cased (readme.md, Docs/x.md refused). | security F-B (Low, fails closed) | 🟢 | Fixed with D1 |
| D3 | docs/AGENTS.md/x.md; Unicode case under docs/; a symlink at docs/*.md; a docs-only carried commit. | security F-C, F-D, F-E; fact-check claim 2 | 🟢 | Defer (override rows) |
| D4 | Header/comment "what --check-fix may allow"; roadmap test "any other path"; test name's shapes. | fact-check claims 1, 8, 9 | 🟢 | Fixed (wording); claim 8 Won't-Fix (override row) |
| D5 | Stage 2.5: S1 (writes what it judged, no hooks), S2 (stale --main, dirty index refuse), S3 (merge judged, rename refused), S4 (record name) all **Verified (executed)**; P1 (time mostly land's re-checks) **Incorrect** (doc-only: re-gates ~25%). | fact-check Submitted Claims | — | S1-S4 back ✅ rows below; P1 override row |

### ✅ Confirmed Good (Stage 2.5, executed)

| Claim | Evidence | Backing |
|---|---|---|
| --land-cycle writes the tree it judged, parents MAIN_SHA and HEAD's commit, message chore_msg's, and runs no hook on either move | `land`'s commit-tree in the gate repository; update-ref or ff-only with hooks planted | Submitted claim S1, executed |
| --land-cycle refuses a stale --main and an index that differs from HEAD's commit | land_cycle's `[[ "$LAND_MAIN" == "$MAIN_SHA" ]]` and `diff-index --cached --quiet` | S2, executed |
| --land-cycle judges the merge: a rename into a new questions file carrying main's answer refuses | U4a test 5 | S3, executed |
| --main-log's chore class reads only docs/working/cycles/cycle-YYYY-MM-DD.md, 100644, A or M | chore_record + isrecord | S4, executed |

Next (Q-141 interim [1]): a second confirming pass (k=1 fact-check + security) over the D1/D2 fix; merge if no new Must Fix or Must Address.

## Second confirming pass (Q-141 interim [1]; fix range ca95fead..8389c477: k=1 fact-check, security)

Reports: `code-fact-check-report-2026-10-13-u4a-confirm2.md` (12 claims: 10 Verified, 2 Mostly accurate wording, 0 Incorrect; F-A shape refused at HEAD, passed on ca95fead), `security-review-2026-10-13-u4a-confirm2.md` (F-A, F-B closed; F-1 Informational: the lowered allowlist also admits F-C/F-D shapes under a differently cased docs/, covered by their override rows). **No new Must Fix or Must Address: merge.** The two wording items (WORDS is lower-case letter runs joined by single hyphens) are fixed in the merge's last commit, unreviewed text.

**Status:** loop closed at 8389c477. Review converged after 3 iterations, a confirming pass and a second confirming pass (Q-141 interim [1]); 0 Must Fix open; Must Address all fixed (A1-A3, B1-B4, C1-C3, D1). Single-sample review; absence of findings is not an attestation.

