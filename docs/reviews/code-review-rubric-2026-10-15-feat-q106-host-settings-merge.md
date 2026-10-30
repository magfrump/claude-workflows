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

Size after pass-2 fact-check fixes: 519 code lines against 184396ea.

### Pass 2 critics (range 05b13d11..f14cf11a): security, performance, API consistency

Architecture skipped this pass: the fixes change no module structure (pass 1 found 0 Structural / 0 Coupling). Reports: `security-review-2026-10-15-q106-pass2.md`, `performance-review-2026-10-15-q106-pass2.md`, `api-consistency-review-2026-10-15-q106-pass2.md`. Pass-1 security F1, F2, F3, F6, F7, F9 verified resolved (F1, F2 with the remainders below); F4, F5 still with the user.

| # | Finding | Tier | Disposition |
|---|---|---|---|
| N1 | `wiring.json` with two documents (hostile first, `{}` last) passed WIRING_SHAPE: `jq -e` judges the last, the merge reads the first (executed). | 🟡 Medium | Fixed: checked with `jq -s`, exactly one object; T100 |
| N2 | WIRING_SHAPE checked only `.command`; an `http`/`prompt` hook with a well-formed command passed. | 🟡 Medium | Fixed: `type == "command"`, keys only type/command/timeout; T100 |
| N3 | The scoped legacy prune still deleted a user's single-slash Bash rule (a real rule). | 🟡 Medium | Fixed: prune only Read/Edit/Write rules; T99 |
| N4 | By-name list printed raw; a newline in a rule forged lines. | 🟢 Low | Fixed: names print as JSON strings |
| N5 | Symlink test and stat/cp are separate lookups; a swap between could show a link target in the review (the write is still refused). | 🟢 Low | Accepted (same-uid write inside `~/.claude`, denyWrite-covered) |
| N6 | No line for added hooks. | 🟢 Info | Fixed: `ADD hook:` lines |
| N7 / API-1 | First install over a settings-only `~/.claude` said "Previous entries moved" and stamped the backup; a full install no longer said settings.json was backed up. | 🟢 Minor | Fixed: stamp, count and message gated on entries moved; settings backup always announced; T103 |
| API-2 | Third-person markers beside base-form ones. | 🟢 Minor | Fixed: `UNWIRE`/`ADD`/`REMOVE` |
| API-3 | Empty by-name list printed nothing. | 🟢 Minor | Fixed: `(none — …)` line |
| API-4 | Empty-group refusal blamed "a hook command"; help spelled `<dest>/hooks`. | 🟢 Minor | Fixed: message and help |
| API-5 | README/help silent on settings-only backups; rotation comment's reason stale. | 🟢 Info | Fixed |
| API-6 | 037 Consequences line lacked a Superseded marker. | 🟢 Minor | Fixed |
| API-7 | Post-swap ERROR was one long line. | 🟢 Info | Fixed: continuation line |
| Perf-1 | Settings-only backups are never pruned (a few KiB each). | 🟢 Info | Accepted (the price of never pruning a full backup) |
| Perf-2 | The summary jq runs before the diff (~15 ms wasted on a merged rerun). | 🟢 Info | Accepted |

Size after pass-2 fixes: 558 code lines against 184396ea.

## Loop pass 3 (range a4f3614a..2298d18e, fact-check k=1)

Fact-check: 26 claims, 21 Verified, 3 Mostly Accurate, 1 Stale, 1 Incorrect; no behavioral red. Every pass-2 "Fixed" row confirmed except N4 (partly).

| # | Finding | Tier | Disposition |
|---|---|---|---|
| P3-1 | Plan row 5 "T100 covers each": no test covered the empty-group refusal. | 🟡 (doc Incorrect) | Fixed: empty-group case added to T100 (it covers existing code, so it passes on 2298d18e) |
| P3-2 | N4 partly fixed: the permission-mode label printed raw, so a mode key holding a newline could forge a list line. | 🟡 (Mostly Accurate) | Fixed: a mode name prints plain only when it is letters, else JSON-quoted (untested; the diff below shows it escaped either way) |
| P3-3 | --help refusal list omitted "not one object" and "not a command hook". | 🟢 | Fixed |
| P3-4 | Plan row 3 still said `UNWIRES hook:`. | 🟢 (Stale) | Fixed |

### Pass 3 security (range a4f3614a..6bb29868; `security-review-2026-10-15-q106-pass3.md`)

N1, N2 (hook level), N3, N4 (names), N6, N7 verified resolved; no control deleted; T93-T103 pass.

| # | Finding | Tier | Disposition |
|---|---|---|---|
| S3-F1 | WIRING_SHAPE constrains each hook, not its group: an object-valued `hooks`, an object `matcher`, extra group keys or a string `timeout` pass and are written. Impact depends on how Claude Code treats a settings.json that fails its schema (whole file rejected → deny rules and guards off; entry skipped → inert group); not checkable here. | 🟡 Medium (low confidence) | Open at the cap |
| S3-F2 | The plain-letters mode check and the command regex use `$`, which in jq 1.6 matches before a final newline: a mode key `"allow\n"` prints unquoted and splits one list line (misdirection, not concealment). Fix: `\A…\z`. | 🟢 Low | Open at the cap |
| S3-F3 | The by-name list compares hooks as sets: a second identical copy prints `(none — …)` though the hook will fire twice. | 🟢 Info | Open at the cap |

## Iteration-4 gate (2026-10-15)

## Iterations (3 completed)
Pass 1: 0 🔴, 10 🟡 → fixed or routed. Pass 2: fact-check 2 Incorrect + security N1-N3 Medium → fixed. Pass 3: fact-check 1 Incorrect (doc) → fixed; security S3-F1 Medium.
## Remaining Must Fix
None.
## Remaining Must Address
S3-F1 (group-level wiring shape; low confidence, impact unverified). A4 (merge program outside the gate regex) and A5 (bidi through `vis`, pre-existing) are with the user.
## Convergence diagnosis (one sentence)
Each pass narrowed the same surface, an allowlist over an untrusted `wiring.json`, by one more level (hook command → document count and hook type → group keys), so the loop is converging on one check rather than churning, but it did not close inside three iterations.
## Recommended action (ship-with-issues / split-PR / pause for redesign)
Authorize one more iteration: tighten the group shape (keys `matcher`/`hooks` only, `hooks` an array, `matcher` a string, `timeout` a number), anchor both regexes with `\A…\z`, count duplicate hooks; then the final confirming pass (k=3, full panel). About 20 code lines; the unit is at 561 of ~800.

**Decision: `escalate`** (/away default: the remaining work is one check inside `install_claude_home`, not a separable part, so `split` does not apply). No further fix work, re-review or loop test run until the user authorizes iteration 4.

## Iteration 4 (2026-10-30, by hand; Q-174 [1])

Main merged in (536678c0; the Write(path)-twin prune ported into `wiring-merge.jq`). Fixed S3-F1 (group-level shape), S3-F2 (`\A…\z`), S3-F3 (multiset by-name list) in 9f27309b; T100 widened, T104 and T105 new, each failing on the pre-fix code. 122/122 in install-host and link-claude-home-wiring.

### Confirming pass (fact-check k=3, security, performance)

Security: `security-review-2026-10-30-q106-pass4.md`.

| # | Finding | Tier | Disposition |
|---|---|---|---|
| S4-1 | The merge program can `import` any readable JSON (the credentials file) through jq's `search` metadata and write it into settings.json; reproduced. | 🟡 Medium | Open at the cap |
| S4-2 | The shape check covers the program's input, not its output: an edited `wiring-merge.jq` can set `defaultMode`, `disableAllHooks`, `apiKeyHelper` or `env` with no by-name line. | 🟡 Medium | Open at the cap |
| S4-3 | A hook's `timeout` is outside the by-name key and unbounded. | 🟡 Medium | Open at the cap |
| S4-4 | Event names and permission modes and values are unchecked. | 🟡 Medium (low confidence) | Open at the cap |
| S4-5 | The Write-twin prune is not scoped to `$dir`. | 🟢 Info | Open at the cap |
| FC4-1 | 9f27309b's Notes, "the merge no longer writes [a schema-invalid file]", is overstated: event names and modes are unchecked. (2 of 3 runs) | Incorrect | Corrected in the next commit's message |
| FC4-2 | Guide: our groups "are replaced by the current wiring's" only for events the wiring carries; a dropped event keeps our old group. (2 of 3) | Incorrect | Open at the cap |
| FC4-3 | Imprecise: "object of arrays" (`hooks:false` passes), the defaultMode failure scope, the refusal hint blaming wiring for settings-side causes, "added once", "-/+" in the diff. | 🟢 | Open at the cap |
| P4-1 | `less` is O(n²), 3.4x slower than `-`: 22.8 s at 10k hooks (realistic is under 50). A sort-based drop-in takes 0.47 s. | 🟢 Low | Open at the cap |
| P4-2 | Pre-existing: the permission REMOVE/ADD lines are O(P²). | 🟢 Low | Mention |

## Iteration-5 gate (2026-10-30)

## Iterations (4 completed)
Pass 1: 10 🟡 fixed or routed. Pass 2: 2 Incorrect + 3 Medium fixed. Pass 3: 1 Incorrect fixed; S3-F1 Medium. Pass 4 (authorized): S3-F1–F3 closed; S4-1–S4-4 Medium, FC4-1/2 Incorrect.
## Remaining Must Fix
None.
## Remaining Must Address
S4-1 to S4-4; FC4-2, FC4-3.
## Convergence diagnosis (one sentence)
Passes 1-4 tightened an allowlist over `wiring.json` while the program that writes settings.json, also branch-supplied, went unchecked, so the residual moved from the input to the program; an output-side check in gated install.sh (S4-2) plus an `import`/`include` refusal (S4-1) bounds what any program can write, which is the structural fix rather than another input level.
## Recommended action (ship-with-issues / split-PR / pause for redesign)
Authorize iteration 5: the output-side check, the `import`/`include` refusal, refuse `timeout`, event-name and deny-only permission checks, scope the twin prune, the sort-based `less`, and the doc corrections; then a confirming pass (security + k=3 fact-check). About 40-60 code lines; the unit is at 341 changed code lines against main, of ~800.

**Decision: `escalate`** (the work is inside one block of `install_claude_home`, not a separable part, so `split` does not apply). No further fix work, re-review or loop test run until the user authorizes iteration 5.

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `devcontainer-config/install.sh` settings block (review computation) | security F6, F8; fact-check (umask, two reads) | distinct defects: validation race vs. secret display |
| 2 | `install.sh` backup/prune tail | api #1, security F9, performance #1, security F7 | distinct defects: stamp counting, missing lazy backup, unpruned failure backup |
| 3 | `guides/bare-host-hook-wiring.md` §2 | fact-check 27, api #2, security F2 (no summary lines) | composed → A2 + A7 share one root: the review gives no explicit list of removed hook commands, so the guide had to teach reading `-` lines, which reorders defeat. Fix: print explicit removed/added summary lines and point the guide at them (inherits 🟡). |
