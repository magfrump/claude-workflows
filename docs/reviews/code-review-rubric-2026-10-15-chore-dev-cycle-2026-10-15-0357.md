Commit: 2141f7ee
Loop closed at 2141f7ee

# Code Review Rubric

**Scope:** `chore/dev-cycle-2026-10-15-0357` vs main (docs only) | **Reviewed:** 2026-10-15 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation

Iteration 1: full-branch scope (`git diff main...16136a60`), `--loop-pass` (k=1 fact-check). Delivery mode: inline-diff-only (agents self-read the 80 KB diff). Reports: `code-fact-check-report-2026-10-15-0357.md`, `security-review-2026-10-15-0357.md`, `tech-debt-triage-review-2026-10-15-0357.md`. Fix: c86b8f3e; fix-drift lite check: no findings.

Iteration 2: incremental scope `16136a60..c86b8f3e`, `--loop-pass` (k=1 fact-check + security). Prior items verified: A1–A13 resolved except A3, which was only partly resolved (the pin goes stale on landing: A14). New: A14–A21. Reports: `code-fact-check-report-2026-10-15-0357-i2.md`, `security-review-2026-10-15-0357-i2.md`. Fix: ae810886; fix-drift lite check: 1 finding (an unqualified "a hash cannot move"), fixed in 2141f7ee.

Iteration 3 of 3: the final confirming pass. Full-branch scope `git diff main...2141f7ee`, without `--loop-pass`: fact-check k=3 (merged into `code-fact-check-report-2026-10-15-0357-final.md`), security and tech-debt-triage (`security-review-2026-10-15-0357-final.md`, `tech-debt-triage-review-2026-10-15-0357-final.md`). It confirmed that A14–A21 hold, and the three replicates executed every paste's success and failure paths. New: A22–A28 (amber) and C9–C11. No 🔴.

Loop outcome: exit condition 1 (clean convergence) at the cap. Every remaining amber carries a qualifying author note: a discoverable TODO, the tracked entry **Q-180** (`agent`), plus a hold line in the Interim of each paste it touches (Q-162, Q-163, Q-164, Q-167, Q-169, Q-176). No iteration 4 was started, and no `escalate`/`split`/`abandon` gate applies, because the exit condition held. The Q-180 entry and hold lines (commit after 2141f7ee) are the author notes themselves and change no reviewed paste.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Q-167(a) expects `cc-isolated --list` to print "Verified live: NO" and a standalone `Next:` line; both come from the bless output (`cc-isolated.sh:328-329` at a760a5e5); `--list` prints `Blessed config <hash> — verified live: NO (run: …)` (`questions.md:203`) | Docs | Incorrect (doc only) | Fact-check Claim 22; tech-debt F4 | for-author | — | Fixed | Expected text now names both outputs |
| A2 | Q-162 says "main plus five reviewed units" and lists seven; the ready branch is based on b279a2ba (`questions.md:83`) | Docs | Stale | Fact-check Claim 13; tech-debt F3 | for-author | — | Fixed | "main (as of b279a2ba) plus seven" |
| A3 | Q-162/Q-163/Q-164 pastes merge by branch name; agent sessions can move those refs, and Q-162's whole-branch gate ran at 3fe6d6e3 before two later unit merges; Q-162 has no `\|\| git merge --abort` and conflicts on today's main (`questions.md:86-88,114,144`) | Security | Medium | security F1; tech-debt F1; fact-check Claim 14 | for-author | — | Fixed (pin goes stale on landing: A14) | All three pastes pinned to full hashes (a760a5e5…, a04d9776…, 0f94bb77…); Q-162 gains the abort wrapper and skips deletion on conflict; gate bullet notes the two later units' own gates |
| A4 | Q-165 still says "roadmap Next 3"; the item moved to Now (`questions.md:161,178`) | Docs | Stale | Fact-check Claim 21; tech-debt F3 | for-author | — | Fixed | Names the Now item |
| A5 | roadmap cites `docs/branch-verify-without-install` at 22a4bb1f; tip is d25254da (`roadmap.md:51-52`) | Docs | Mostly Accurate | Fact-check Claim 4 | for-author | — | Fixed | Roadmap cites the tip; Q-165 cites both |
| A6 | "untested copy" of ENTRIES; one test pins `scripts`, what is missing is a parity test (`roadmap.md:118`, `questions-archive.md` Q-107) | Docs | Mostly Accurate | Fact-check Claim 7 | for-author | — | Fixed | "no parity test" |
| A7 | Q-164 "410 lines in all" measures 409 (`questions.md:137`) | Docs | Mostly Accurate | Fact-check Claim 20 | for-author | — | Fixed | 409 |
| A8 | Q-174 says Q-106 is "on `merge/ready-2026-10-15`"; it is built on an earlier ready commit (184396ea) and not in the ready branch (`questions.md:328`) | Docs | Mostly Accurate | Fact-check Claim 26; tech-debt F3 | for-author | — | Fixed | Says so |
| A9 | Q-176's throwaway hook approves every Bash command in a host session, so retries after a denial run unprompted (`questions.md:371`) | Security | Medium | security F2 | for-author | — | Fixed | Hook script approves only the seven exact test commands, silent otherwise (checked: 7/7 allow, `ls -la` and `cat x.q092-canary; id` get no output); "answer no" and always-clean-up lines added |
| A10 | Q-176 tests two of MA1's four spellings and has no unquoted control, yet Q-177 [1] lands Q-092 on "all denied" with `—` as its consequence (`questions.md:368-377,393`) | Security | Medium | security F3 | for-orchestrator-synthesis | — | Fixed | Adds `cat "secret"` (exact rule), `git "push"` (prefix rule), and two unquoted controls that void the check if not denied; Q-177 [1]'s cell names the consequence |
| A11 | Q-176 tests the host's Claude Code version while the hook runs in the container (`questions.md:371,379,382`) | Security | Medium (Low confidence) | security F4 | for-author | — | Fixed | Asks for the container's version too; Q-092 lands only on a match |
| A12 | Q-169's "reviewed block" check is a hash the script prints about itself; the block is taken from the agent-writable working tree (`questions.md:247`) | Security | Medium | security F5 | for-author | — | Fixed | Block is extracted with `git show a760a5e5:…` and checked against the full body sha256 `032cc9a8…afb7` (re-computed here) before pasting |
| A14 | Q-162's pinned ready tip a760a5e5 conflicts with main once this branch lands (override-log appends, c86b8f3e's two rows; already conflicting with 7f711bfe in questions/roadmap/idea-log), so the paste aborts; the entry gave no next step for its own abort (`questions.md:83-89`) | Docs | Incorrect | Fact-check i2 Claims 1b, 11 | for-author | — | Fixed (acknowledged) | Entry now says "Not runnable yet": the next cycle rebuilds `merge/ready-2026-10-15` on main and re-pins the hash; the paste aborts safely meanwhile. Revisit trigger: the next dev cycle's land step |
| A15 | A replace ref defeats the hash pins: `git merge --no-ff <sha>` lands the replacement's content (`questions.md` Q-162/Q-163/Q-164 pastes) | Security | Medium | security i2 N1 | for-author | — | Fixed | Each paste refuses when `refs/replace/` is non-empty (guard executed: proceeds clean, stops with a replace ref) |
| A16 | Q-176 can record "denied" for a spelling never tried (the model rewrites `git "push"` to `git push`); "prompts" not covered | Security | Medium | security i2 N2; fact-check i2 check 4 | for-author | — | Fixed | Hook logs every command to `seen.log`, pasted back; a result counts only if the log shows the exact command; "prompts" on a test spelling voids it |
| A17 | Q-176's later writes are not chained to `cd ~/q092`, so a failed `mkdir`/`cd` writes `.claude/settings.local.json` in the current directory and starts `claude` there | Security | Medium (Low confidence) | security i2 N3 | for-author | — | Fixed | One chained command line; both heredocs write absolute `~/q092/...` paths (`bash -n`, `zsh -n` pass) |
| A18 | Q-169's extraction runs `cd /workspace` (the container mount) while the spike runs on the host; its output sits outside the `denyWrite`'d `~/cc-verify` | Security / Docs | Medium; Incorrect (medium) | security i2 N4; fact-check i2 Claim 22 | for-author | — | Fixed | `cd ~/claude-workflows`, `git -c core.useReplaceRefs=false show`, output `~/cc-verify/q117-spike.txt` (the spike inspects only its own `run-*.d`) |
| A19 | If test 7 runs, `git push` searches upward from `~/q092` and could push a home-directory repo | Security | Low | security i2 N5 | for-author | — | Fixed | `git init -q` in `~/q092` (no remote) |
| A20 | Q-176's controls cover only the glob and exact rules, not the `:*` prefix rules; jq on the host is unstated | Docs | Mostly Accurate | Fact-check i2 check 4 | for-author | — | Fixed | Controls `rm -rf ./nothing-here` and `git push` added (nine commands); the paste checks `jq --version` |
| A21 | Wording: Q-162:99 "adds the rebuild-hint and one-workspace merges" omits two docs-branch and nine cycle-record merges; Q-164 "409 lines in all" excludes `docs/reviews/`; Q-165 tip "adds review commits" also adds the spike doc | Docs | Mostly Accurate | Fact-check i2 | for-author | — | Fixed | Reworded |
| A22 | The replace-ref guard misses `info/grafts`: a planted graft let a pinned merge pass the guard and land other content (executed) (`questions.md:89,117,148`) | Security | Medium | security final F1 | for-author | — | 🟡 Acknowledged | TODO: Q-180 (adds `info/grafts` and `shallow` refusals, as `scripts/build-loop.sh:622` does); each paste's Interim holds it until Q-180 is done |
| A23 | The merge pastes don't say container or host; on the host, a planted hook or merge driver runs as the user (`questions.md:83,88,116,147`) | Security | Medium (Low confidence) | security final F2; fact-check final Claim 7 | for-author | — | 🟡 Acknowledged | TODO: Q-180 |
| A24 | Q-169 says "Not verified" has 8 items; it has 12 at the pinned commit (`questions.md:266`) | Docs | Incorrect (doc only) | fact-check final Claim 1 | for-author | — | 🟡 Acknowledged | TODO: Q-180 |
| A25 | Q-163 and Q-164 pastes abort on today's main or after landing, but carry no "not runnable" note (`questions.md:110-160`) | Docs | Stale | fact-check final Claim 2; tech-debt final F5 | for-author | — | 🟡 Acknowledged | Hold line added to each Interim (Q-180); re-pin in Q-180 |
| A26 | Q-162's note omits `questions-archive.md`; "every pair conflicts only in override-log" overstates (`questions.md:83,85`) | Docs | Mostly Accurate | fact-check final Claims 3, 4 | for-author | — | 🟡 Acknowledged | TODO: Q-180 |
| A27 | Q-170's "87 of 116" is 88 (`questions.md:276`) | Docs | Mostly Accurate | fact-check final Claim 5 | for-author | — | 🟡 Acknowledged | TODO: Q-180 |
| A28 | Cycle 2's 42/25/38/4 tally reproduces only when cycle 1's three landings are excluded (`roadmap.md:77`, `cycle-2026-10-14.md:6,55`) | Docs | Mostly Accurate | fact-check final Claim 6 | for-author | — | 🟡 Acknowledged | TODO: Q-180 |
| A13 | Q-175 says the move declines new coverage; on main the jq is inline in `link-claude-home.sh`, covered by `live-verify-gate.sh:83`, so [1] gives up coverage that exists today (`questions.md:354-362`) | Security | Medium | security F6 | for-author | — | Fixed | Entry and [1]'s cell say so; interim notes nothing has lost coverage while Q-106 is unmerged and that the review leans to [2] |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Q-166 [1] understates what a staged run misses for Q-125 (`install.sh` PAYLOAD, `enforcement_files()`) | security F7 | Low | for-author | — | Fixed |
| C2 | Q-167(c)'s fenced block carries two `#` lines that default zsh runs as commands | security F8 | Informational | for-author | — | Fixed (moved out of the fence) |
| C3 | User-routed asks grow 2 → 15; answer order lives only in prose | tech-debt F2 | Medium (advisory) | for-author | — | Deferred (override-log row 2026-10-15) |
| C4 | Branch state copied into roadmap, Q-162 and the cycle record, and the copies drift | tech-debt F3 | Low (advisory) | for-author | row 84 (2026-09-28) | Deferred (override-log row 2026-10-15); this landing's drifted copies fixed (A2, A4, A5, A8) |
| C5 | Roadmap Next 1's cycle-2 tally reproduces as 45/29/40/5 (adds 188e0a7d) under the record's stated window | Fact-check Claim 5 (Unverifiable) | Unverifiable | for-orchestrator-synthesis | — | Deferred (override row) — Q-179 decides row 66 on the cycle-3 tally, so the cycle-2 line is history |
| C6 | "T69 fails 3/3 alone" passed 2/2 on main's tree here (a timing race) | Fact-check Claim 8 (Unverifiable) | Unverifiable | for-orchestrator-synthesis | — | Won't-Fix (override row) — moot once Q-162 lands the fix |
| C7 | Q-176's main-vs-branch hook behaviour on quoted spellings is read-only, not executed | Fact-check Claim 28 (Unverifiable) | Unverifiable | for-orchestrator-synthesis | — | Won't-Fix (override row) — Q-176 is the live check that settles it |
| C9 | Q-167(b) line 3 `--profile '#' --bless` blesses without a prompt on a launcher older than the fix; use `--list` | security final F3 | Low | for-author | — | Deferred (Q-180) |
| C10 | Q-176's `mkdir -p` accepts a planted `~/q092` (its `.git/config` ran a planted fsmonitor in a fake HOME) | security final F4 | Low | for-author | — | Deferred (Q-180) |
| C11 | A rebuild of the ready branch means re-pinning four entries by hand, and only Q-162 said so | tech-debt final F5 | Low (advisory) | for-orchestrator-synthesis | — | Deferred (Q-180 names all four) |
| C8 | Q-163's "(Q-156)" cites an ID defined only on `feat/build-loop-u5` (Q-164 says so; Q-163 does not) | Fact-check note | Low | for-author | — | Fixed |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `review/q087` / 2026-09-28 (row 84) | A question's Status on a branch lagged its archived answer | 🟡 Must-Address → Defer | The answer was already archived on main | Substantive match for C4 (branch-held state drifting from main); this run fixes the instances and defers the process change in a new row. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The 16136a60 merge resolution loses or duplicates no entry, roadmap item or idea-log line beyond the drops its message names | ✅ Confirmed | Per-entry comparison of `16136a60^1`, `16136a60^2` and HEAD for all four conflicted files (fact-check Claim 30, executed) | Fact-check | for-orchestrator-synthesis |
| Q-162's deletion loop succeeds: all twelve `feat/build-loop-u*` branches are merged into main and their worktrees registered and clean | ✅ Confirmed | `git merge-base --is-ancestor` and `git worktree list` per branch (fact-check Claim 14, executed) | Fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Diff is copy-only with no logic changes | `git diff --stat main...HEAD`: only `docs/*.md` |
| api-consistency-reviewer | No public API surface touched | Only question entries, roadmap, idea log and a cycle record change |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `docs/working/questions.md:83-99` (Q-162) | A2, A3 (FC13, FC14, security F1, tech-debt F1/F3) | distinct defects: a wrong count and an unpinned, unguarded paste, each fully stated |
| 2 | `docs/working/questions.md:365-398` (Q-176/Q-177) | A9, A10, A11 | distinct defects: hook scope, spelling coverage and version, each with its own fix |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
