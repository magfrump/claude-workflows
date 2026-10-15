Commit: a4f3614a

# Code Review Rubric: feat/q106-host-settings-merge

- **Scope:** `184396ea..HEAD` (full branch; base is `merge/ready-2026-10-15`, the branch below). Delivery mode: self-read.
- **Pass:** loop pass 1 (`--loop-pass`, k=1 fact-check, decision 031). No short-circuit: no behavioral red.
- **Critics:** security-reviewer, performance-reviewer, api-consistency-reviewer (core); architecture-review (auto-selected: new shared module `hooks/lib/wiring-merge.jq`). test-strategy not selected (source changes come with tests). All 4 returned.
- **Reports:** `code-fact-check-report.md`, `security-review-2026-10-15-q106.md`, `architecture-review-2026-10-15-q106.md`, `performance-review-2026-10-15-q106.md`, `api-consistency-review-2026-10-15-q106.md` (all in `docs/reviews/`).
- **Status:** 0 🔴 · 10 🟡 · 9 🟢 — not mergeable this pass (🟡 open).

## 🔴 Must Fix

None.

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The legacy single-slash prune (`hooks/lib/wiring-merge.jq` permissions reduce) deletes any user rule equal to the one-slash form of a wiring rule, so a branch's `Read(//secrets/**)` removes the user's `Read(/secrets/**)`; plan row 2's "user rules survive" is false. | Security | Medium | security F1 (probe) | for-author | — | 🟡 Open | — |
| A2 | A wiring hook command with `..` (`{{CLAUDE_DIR}}/hooks/../../tmp/x.py`) passes the provenance substring test yet runs unreviewed agent-writable code; nothing summarizes security-relevant changes (removed hooks/rules, added allow rules) and the prompt does not name settings.json. | Security | Medium | security F2 (probe) | for-author | — | 🟡 Open | — |
| A3 | jq loads `$HOME/.jq` (jq 1.6) into the merge, so unreviewed code outside `~/.claude` shapes the result (probe: 0 hooks wired instead of 9); plan row 7 overstated. Applies to link-claude-home.sh too. | Security | Medium | security F3 (probe) | for-author | — | 🟡 Open | — |
| A4 | The merge program left `live-verify-gate.sh`'s `enforcement` regex (plan family 16); the question promised by the plan and commit is not filed. | Security / Architecture | Medium | security F4, architecture #2 | for-author | — | 🟡 Open | needs the user (report question) |
| A5 | Bidi control characters pass `vis` into the review (pre-existing for every review diff; extended to settings). | Security | Medium (low confidence) | security F5 | for-author | — | 🟡 Open | — |
| A6 | Settings-only runs write `.install-stamp`, so they count toward "the last 3 installs" and can prune the only backup of the seven entries (probe PROBE2); contradicts README, --help, decision 037. | API / Security | Inconsistent | api-consistency #1, security F9 | for-author | — | 🟡 Open | — |
| A7 | Guide: "A `-` line on a hook command means the install unwires it" is wrong: the merge moves our group to the end, so reorders also show `-` lines (T93's own review). | Docs | Incorrect (doc) | fact-check claim 27, api-consistency #2 | for-author | — | 🟡 Open | — |
| A8 | Plan row 2 claims a test covers stale-rule survival; none does. | Docs | Incorrect (doc) | fact-check | for-author | — | 🟡 Open | — |
| A9 | Plan row 14 / T93 "mode kept" is untested: umask already yields 600; removing `chmod --reference` leaves T93 green. | Docs / Tests | Incorrect (doc) | fact-check | for-author | — | 🟡 Open | — |
| A10 | Mostly-accurate cluster: no backup when settings.json was absent at review, no entry changed, and it appears later (security F7, fact-check); one-object check and copy are two reads and the merged output is never re-validated (security F6, fact-check escalation d); plan rows 8, 11, 13, 15 overstate their tests. | Security / Docs | Low + Mostly Accurate | security F6/F7, fact-check | for-author | — | 🟡 Open | — |

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Trailing-slash `CLAUDE_HOME_DIR` changes `$dir`: a hand-merged group stays as foreign and the hook fires twice; deny rule gets `.claude//settings`. | performance #2, api #5 | Low / Minor | for-author | — | 🟢 Open |
| C2 | Settings-only run asks "Install these files" and prints "Previous entries moved" when nothing moved. | api #3 | Minor | for-author | — | 🟢 Open |
| C3 | Post-swap settings failure message omits that the files were installed and where the backup is; the entries backup is then never pruned (no stamp). | api #4, performance #1 | Minor / Low | for-author | — | 🟢 Open |
| C4 | `guides/claude-config-security-checkup.md:46-47` still says the bare-host wiring is manual; guide hand-merge recipe says "beside" (the FP-161 shape). | api #6, architecture #5 | Minor / Info | for-author | — | 🟢 Open |
| C5 | `settings.json: NOT merged:` lacks the script's `WARNING:` prefix; --help "never written" list and Needs line omit reasons and jq. | api #7, #8 | Minor | for-author | — | 🟢 Open |
| C6 | `install_claude_home` grows a second write path (397 lines); extract prepare/check/apply helpers next time. | architecture #1 | Minor | for-author | — | 🟢 Open |
| C7 | 037 amendment should say why 037's pruned "[3 B] shared lib is a new coupling" does not apply. | architecture #3 | Info | for-author | — | 🟢 Open |
| C8 | Callers validate differently (host: one object; linker: `jq -e .`); move the object check into the program if a third caller appears. | architecture #4, api #9 | Info | for-author | — | 🟢 Open |
| C9 | `env` secrets can show as diff context lines; the 0644 `settings.view.diff` sits in the 0700 stage. | security F8, fact-check | Low | for-author | — | 🟢 Open |

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `answers-2026-09-20` / 2026-09-21 | N3: single-slash deny rules may match nothing (Q-049) | 🟡 → Defer | needed a host check | Resolved upstream (Q-049 answered 2026-09-23); this diff relies on its answer. Not re-flagged. |
| `feat/run-tests-jobs` / 2026-09-30 | install.sh's /proc scan under `--jobs` may flake install-host | 🟡 → Acknowledged | measured | Observed again in this loop (T92's hidden process refused T89/T93/T94 in a parallel run; each passed alone). Not re-flagged. |

## ✅ Confirmed Good

None on this pass: Stage 2.5 is skipped on a loop pass, so routed endorsements stay *pending execution verification*.

## ⏭️ Skipped Core Critics

None.

## Iteration 1 fix dispositions

| # | Disposition | Where |
|---|---|---|
| A1 | Fixed: the legacy prune only touches `(//$dir/…` rules | `hooks/lib/wiring-merge.jq`; T99 |
| A2 | Fixed: host refuses wiring commands not `bash\|python3 {{CLAUDE_DIR}}/hooks/<path>` (no `..`, no shell syntax, no empty group); the review lists `UNWIRES hook:` / `REMOVES … rule:` / `ADDS … rule:`; the prompt names the settings merge | `install.sh`; T93, T100 |
| A3 | Fixed: both callers run jq via `env -i PATH HOME=/nonexistent` | `install.sh` (`sjq`), `link-claude-home.sh`; T101 |
| A4 | Open: needs the user (report question on adding the program to the gate regex) | — |
| A5 | Deferred: pre-existing gap in every review diff, not introduced here (report question) | — |
| A6 | Fixed: settings-only backups are not stamped and do not prune | `install.sh`; T94 |
| A7 | Fixed: the guide points at the by-name list and says why `-` lines mislead | guide §2 |
| A8 | Fixed: T99 covers stale-rule survival; plan row 2 restated | plan, T99 |
| A9 | Fixed: mode read at review and set on the merged copy; T93 uses 640 | `install.sh`; T93 |
| A10 | Fixed: one read into a copy that is checked, hashed and merged; merged output re-checked as one object; backup dir made lazily; `cp -pP`; plan rows 8/11/13/15 restated | `install.sh`, plan |
| C1 | Fixed: `$dir` is `cd "$dest" && pwd` | `install.sh`; T98 |
| C2 | Fixed: settings-only prompt and backup wording | `install.sh`; T94 |
| C3 | Message fixed (says files were installed and where); unpruned backup after that failure accepted | `install.sh` |
| C4 | Fixed: checkup guide line; hand-merge recipe says remove the older copies first | guides |
| C5 | Fixed: `WARNING:` prefix; help lists the shape refusal and jq | `install.sh` |
| C7 | Fixed: amendment explains why [3 B]'s objection does not apply | decision 037 |
| C6, C8, C9 | Accepted / later | — |

Size after iteration 1: 501 code lines against 184396ea (limit ~800).

## Loop pass 2 (range 05b13d11..a4f3614a, fact-check k=1)

Fact-check: 38 claims, 2 Incorrect, 1 Stale, 8 Mostly Accurate; no behavioral red. Critics for this pass run after the fixes below, over 05b13d11..HEAD.

| # | Finding | Tier | Disposition |
|---|---|---|---|
| P2-1 | The by-name list keyed hooks by command only: a hook kept by command but moved to another matcher or event printed no `UNWIRES`, and the guide said to read the list instead of the diff (plan row 3's threat). | 🟡 (doc Incorrect; code gap) | Fixed: keyed by event, matcher and command; guide reworded; T102 (fails on a4f3614a) |
| P2-2 | d53d2bf4's "each new or changed assertion fails on 05b13d11" overstates: T93's negative UNWIRES check and 640 check, and T94's `%%` split, pass on the old code (each test as a whole fails). | 🟡 (commit-message Incorrect) | Accepted-immutable for the message; T94's check made explicit. The 640 check cannot tell A9 from the old `chmod --reference`; stated here |
| P2-3 | Decision 037's "Not written" bullet missed the shape refusal and the unreadable skip. | 🟡 (Stale) | Fixed |
| P2-4 | A failing summary program was silent (`|| true`). | 🟡 (Mostly Accurate) | Fixed: prints a WARNING line telling the reader to read the whole diff |
| P2-5 | --help put "lists what it unwires" on the refusal path; guide skip list missed empty group and missing program. | 🟢 | Fixed |
| P2-6 | link-claude-home.sh's two count-only jq calls still load `~/.jq`; they only feed a message. | 🟢 | Accepted |

Size after pass-2 fixes: 519 code lines against 184396ea.

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `devcontainer-config/install.sh` settings block (review computation) | security F6, F8; fact-check (umask, two reads) | distinct defects: validation race vs. secret display |
| 2 | `install.sh` backup/prune tail | api #1, security F9, performance #1, security F7 | distinct defects: stamp counting, missing lazy backup, unpruned failure backup |
| 3 | `guides/bare-host-hook-wiring.md` §2 | fact-check 27, api #2, security F2 (no summary lines) | composed → A2 + A7 share one root: the review gives no explicit list of removed hook commands, so the guide had to teach reading `-` lines, which reorders defeat. Fix: print explicit removed/added summary lines and point the guide at them (inherits 🟡). |
