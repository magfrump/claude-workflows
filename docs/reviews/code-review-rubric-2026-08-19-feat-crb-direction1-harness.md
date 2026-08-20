# Code Review Rubric

**Scope:** `59733d8..HEAD` (`cf6e7c9`, `5bd0b09`, `46a5f17`, + iteration-3 fixes) on `feat/crb-direction1-harness` | **Reviewed:** 2026-08-19 | **Status: 🔴 DOES NOT PASS** — 3 red item(s) unresolved (3 of 6 closed in iteration 3)

---

## ⛔ Loop cap reached — decision: `escalate`

**The review-fix loop has run its 3 permitted iterations and has not converged.** Per
`workflows/review-fix-loop.md`, iteration 4 may not begin without a recorded
`escalate | split | abandon` decision. **The decision is `escalate`** — hand to the human
reviewer.

**Why `escalate` rather than `split` or `abandon`:**

- The three remaining reds (R1, R2, R4) are one **design question**, not three defects:
  *should host-side git commands ever run against a `.git` directory that a
  `--dangerously-skip-permissions` container had write access to?* Every proposed fix
  (config sanitization, hook stripping, hardened `-c` overrides, or running the reset inside
  a container) is a different answer to that question, and choosing among them is an
  architecture decision with a cost the author should weigh, not a patch.
- It interacts directly with **R3 on the 2026-08-18 rubric**, which is already recorded as a
  host-and-billing decision this review cannot make: a dedicated low-limit key behind an
  egress allowlist. If the egress control lands, R4's severity drops substantially, because
  the non-git retrieval paths it describes stop being reachable. Fixing R1/R2/R4 first would
  be solving the harder problem in the wrong order.
- `split` is wrong: the reds are not separable into independently-convergent pieces — they
  are all the same trust boundary.
- `abandon` is wrong: the harness is close, the fixes so far are real, and the arm still has
  value.

**Convergence assessment.** Iterations 1–3 fixed 2 fact-check reds, 5 doc/mechanism errors,
3 of 6 critic reds, and 8 ambers, and grew the suite from 379 to 398 tests. But **four of the
six reds in this rubric were introduced by this loop's own fixes**, and the same containment
code produced three consecutive mechanism errors:

1. "with no remote there is no route to fetch it" — refuted by execution (k=3 unanimous);
2. `scrub_object_store()`'s rationale — the check it supported could not fire, because
   `git fsck` counts reflogs as reachability roots;
3. the `--heal` ordering — the healer was written for exactly the blocked case and placed
   *after* the check that blocks it, leaving the harness unable to run any existing clone.

That is the stuck-loop signal in substance if not in form: not the same finding re-firing,
but the same *region* generating a new mechanism error every round. It is the strongest
argument that the next change here should be a considered design decision rather than a
fourth patch from the same author in the same session.

**What the human needs to decide:**

| Question | Options |
|---|---|
| Should host-side git touch a container-written `.git` at all? | (a) sanitize `.git/config` + `.git/hooks` from a manifest-stored baseline before any git command; (b) run the reset inside a throwaway container; (c) hardened `-c` overrides on every host-side git call; (d) accept, on the basis that the forks are a public benchmark org rather than an adversary |
| Is R3's egress allowlist landing first? | If yes, sequence R1/R2/R4 after it — the threat surface changes |
| Is the arm run before any of this? | Only with `--heal` applied; the harness is otherwise non-functional (R6, now fixed) |

**Merge vs run remains the right frame,** unchanged from 2026-08-18: the branch is safe to
*merge* — no red describes broken behavior in the committed code path for a trusted input —
and gated for *running* against third-party repositories.

---

> **Loop status.** Review-fix loop opened on
> `docs/reviews/pre-mortem-crb-direction1-sweep-2026-08-18.md`. Iteration 1's k=3 fact-check
> found a behavioral red (fixed in `5bd0b09`); iteration 2's k=1 fact-check found five
> doc/comment mechanism errors (fixed in `46a5f17`) and its six critics produced the rows
> below; iteration 3 closed R3, R5, R6 and ambers A1–A5, A10. No iteration has been clean, so
> the branch has **zero** of the two consecutive clean passes the loop requires, and the cap
> gate above is now the governing state.
>
> **Iteration 3's fixes have not themselves been reviewed.** Given that four of the six reds
> here were introduced by earlier fix rounds, treat that as a live risk rather than a
> formality — it is the first thing a fourth pass should look at.

**Pipeline:** Stage 1 fact-check k=1 (loop pass, decision 031) → Stage 2 six critics in parallel
(security, performance, api-consistency, architecture, test-strategy, tech-debt-triage) →
Stage 3 synthesis. Delivery mode: **self-read** — the shared block measured ~14.1k tokens
(within the 25k budget on the diff-only rung), but Stage 1 requires byte-identical replicate
prompts and a hand-copied 56KB diff cannot be guaranteed byte-identical; a pinned scope command
is byte-identical by construction.

> **The headline is not in any single finding.** Four of the six reds below were *introduced by
> this loop's own fixes*. The loop is finding real defects at a high rate, and it is also
> generating them at a high rate — three consecutive mechanism errors in the same containment
> code (`no remote means no fetch` → `fsck counts reflogs` → `the healer runs after the check
> that blocks it`). That pattern, not any one row, is the reason this branch should not be run.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | **Host-side arbitrary code execution from container-writable `.git`.** The container mounts the clone read-write with `--dangerously-skip-permissions`; the host then runs `checkout --force`, `reset --hard`, `clean -qfdx`, `gc`, `fsck`, `symbolic-ref -d` against that `.git`. Five paths executed by the critic: `post-checkout` and `reference-transaction` hooks (8× fires), `core.hooksPath`, `core.fsmonitor` (fires on the harvest's `git status` — the *first* host command after the container exits), and `filter.X.smudge` + a tracked `.gitattributes`. The `.gitattributes` variant needs no agent action at all: it is tracked content a hostile fork carries. | Security | Critical | `scripts/crb-materialize.py:348-361`; `run-host.sh:344`, mount at `:276` | for-author | — | 🔴 Unresolved |
| R2 | **`core.worktree` redirects `git clean -qfdx` at arbitrary host paths.** Executed: deleted every untracked file in an unrelated host directory. | Security | Critical | `scripts/crb-materialize.py:348-357` | for-author | — | 🔴 Unresolved |
| R3 | ✅ **Closed in iteration 3** (`git clean -qffdx`). **A nested clone of the answer key inside `/repo` is invisible to every containment check and survives the reset.** `git clean -qfdx` silently skips nested repositories (needs `-ff`), exits 0, and `-q` suppresses the warning. Invisible to `FETCH_HEAD`, `fsck --no-reflogs`, `rev-list --all --not head`, and the harvest filter; persists across cells. | Security | High | `scripts/crb-materialize.py:200-264`, `:267-286`, `:357` | for-author | — | ✅ Fixed |
| R4 | **The reset/void split's only discriminator is git-fetch traces, so any non-git retrieval fails open as "benign agent work"** — `curl`, `gh pr view`, WebFetch, then commit on top of head. Also fails open for in-context-only contamination: `review.md` is harvested *before* any containment check runs, so a review already written from the answer key is captured regardless of the verdict. | Security | High | `scripts/crb-materialize.py:267-286`, `:315-343` | for-author | — | 🔴 Unresolved |
| R5 | **`run-meta.json` is an inter-module contract with no owning module, and both reader-side defenses fail open.** (a) `crb-subset-leaderboard.py:59` — `meta.get("requested_instances") or sorted(cells)`; `cells` is by construction the set that produced output, so any schema mismatch reports zero attrition. (b) `run-host.sh:209` writes `requested_instances` for the current invocation only and overwrites it each run, while `cells` accumulates — so a documented subset re-run (`run-host.sh:46`) or a `SWEEP_BUDGET`-halt resume measures attrition against the last batch alone. **The scenario the EXIT trap was added to survive is the scenario that empties the denominator.** Converged independently by three critics. | Architecture (+ Tech-debt D2, API-consistency F5) | Structural | `scripts/crb-subset-leaderboard.py:59`; `runs/review-arms/crb-pipeline/run-host.sh:209` | for-author | — | ✅ Fixed — writer unions across invocations; reader no longer falls back to `cells`, it reports "NOT checked" |
| R6 | **The harness as committed cannot run a single cell against any clone that currently exists.** All 5 pilot clones fail the new pre-run `--reset`: every pre-fix clone carries leftover `FETCH_HEAD` and a dangling `refs/remotes/origin/HEAD`, both of which `46a5f17` taught `fetch_traces()` to void on. `run-host.sh` counts each as `skipped_bad` → `ran=0` → exit 3. `scrub_object_store()` contains a healer that clears both in one call (verified), but `reset_clone()` raises before reaching it. Fails safe at $0. | Performance | High → **promoted** | `scripts/crb-materialize.py` `reset_clone()` ordering | for-author | — | ✅ Fixed — one-shot `--heal` mode, deliberately operator-run rather than an auto-heal inside the gate |

**R6 promotion note.** Performance `High` maps to 🟡 under the unified mapping. It is promoted
under the Escalation Rule's *executed evidence* clause — the critic ran the shipped code against
all five real pilot clones and captured the failure — not by convergence. The effect is that the
harness is non-functional as committed, which no amber tier describes honestly.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `--dry-run` is silently ignored by `--reset`: the `args.verify or args.reset` branch returns at `:499`, `args.dry_run` is first read at `:518`. So `--reset <slug> --dry-run` performs the full destructive reset while advertising "clone nothing". Two-line fix. | API-consistency | Inconsistent | api-consistency F1 | for-author | — | ✅ Fixed — `--dry-run` honoured by all three modes | Amber only by the mapping; treat as the top amber — it is a destructive action behind a flag that promises the opposite. |
| A2 | `crb-cell-status.py` overloads exit 1: `sys.exit("usage: …")` is indistinguishable from the "incomplete" verdict bash consumes at `run-host.sh:233`, so an invocation bug reads as "re-run this cell" and re-pays $10–40. `--help` is read as a filename. Repo precedent (`claude_config_audit.py:195-237`) gets this free from argparse. | API-consistency | Inconsistent | api-consistency F2 | for-author | — | ✅ Fixed — usage exits 2; run-host.sh aborts on it rather than re-paying | — |
| A3 | **`--reset` can be made a complete no-op with all 38 tests green.** Replacing `note = reset_clone(...) if resetting else ""` with `note = ""` at `:489` reverts the entire `cf6e7c9` fix silently: `crb-containment-reset.bats` only ever invokes `reset_clone` via importlib, and `run-host.sh` calls **only** the CLI. | Test-strategy | Medium | test-strategy T2 (30 mutations, 22 caught, 10 missed) | for-author | — | ✅ Fixed — CLI-level tests drive `main()`; the no-op mutation now fails | The single most valuable test to add. |
| A4 | **`STUB_MAX_LEN = 300 → 1000` is invisible to the suite** — verbatim the defect all three k=3 replicates caught. Every "long review" fixture is ~2.6 KB; nothing occupies the 300–1000 band the constant governs. | Test-strategy | Medium | test-strategy T1 | for-author | — | ✅ Fixed — 700-char fixture pins the 300–1000 band | — |
| A5 | The corpus pin (`complete=29 incomplete=3`) globs `runs/review-arms/**/result.json` dynamically, and the sweep writes `runs/review-arms/crb-pipeline/<slug>/result.json` into that same tree — **not gitignored**. Reproduced: one synthetic cell turns the suite red. The first paid cell breaks it, with a message reading "the predicate regressed", in the same directory as the containment guard's non-vacuity pin. | Test-strategy + Tech-debt | Medium | test-strategy G-series, tech-debt D1 | for-author | — | ✅ Fixed — corpus pin excludes the live sweep dir | Converged by two critics. ~15 min. |
| A6 | A cell whose container dies before emitting a `result` event writes no `result.json`, and the `MAX_ATTEMPTS` guard is nested *inside* the `result.json` existence test — so it retries unboundedly across sweeps while ledgering `cost_usd: 0`, invisible to `SWEEP_BUDGET`. Enclosing guard predates this diff; the reworked predicate inherits it. | Performance | High | performance-reviewer | for-author | — | 🟡 Open | — |
| A7 | `SWEEP_BUDGET` sums the whole `$OUT` history and skipped cells `continue` before the gate, so a resume already over the ceiling pays one full cell ($8–18 measured) before halting again. | Performance | Medium | performance-reviewer | for-author | — | 🟡 Open | — |
| A8 | A post-run void leaves the clone un-reset, so the cell is permanently dead with no remediation message — money sunk, PR silently leaves the denominator. Interacts with R5. | Performance | Medium | performance-reviewer | for-author | — | 🟡 Open | — |
| A9 | The **void protocol** has three encodings (`CONTAINMENT_FAILED` sentinel, rewritten `result.json`, `voided_cells`), three readers, one `\|\| true` writer, and no test asserting they agree. `crb-cell-status.py` takes a `result.json` path so it structurally cannot see the sentinel; it rejects voided cells only coincidentally. | Architecture | Coupling | architecture-review | for-author | — | 🟡 Open | — |
| A10 | `run-meta.json`'s `voided_cells: []` reads as "containment held" when it only means "no detected contamination" — given R3/R4's known bypasses, that is the claim most likely to be over-read in a results doc. | Security | Medium | security-reviewer | for-author | — | ✅ Fixed — `voided_cells_meaning` written into run-meta.json | Cheapest high-value item on the list: it is a wording change to a machine-readable artifact. |
| A11 | Agent `--amend` / squash / rebase voids clean cells, polluting `voided_cells` with non-contamination losses — denominator bias of exactly the kind the attrition work exists to expose. | Security | Medium | security-reviewer | for-author | — | 🟡 Open | — |
| A12 | `crb_common.py`'s boundary is holding in kind, broken in effect: `RUN_META`'s writer is bash and cannot import it, so the run-dir path is now stated three times (`crb_common.py:32`, injector `:63` `DEFAULT_RUNS`, `run-host.sh:54`) — the exact hand-copy failure that module's docstring exists to prevent. | Architecture + API-consistency | Coupling | architecture-review, api-consistency F6 | for-author | — | 🟡 Open | — |
| A13 | `missing_cells` is written and read by nobody — the leaderboard re-derives the same set, and the test fixture writes a contradictory `[]` and still passes. | API-consistency | Minor | api-consistency F3 | for-author | — | 🟡 Open | — |
| A14 | Three comment-vs-behaviour contradictions, same class as the two this loop already produced: the shallow-clone test comment credits `--connectivity-only` for quietness that `crb-materialize.py:243-245` measures as false in the same diff; `git reset --hard` is provably redundant with `checkout --force -B` yet its comment credits it for the staged-edit fix; and the "detected, and scrub heals it" test prints `BEFORE:` without asserting it, so the fsck-error check can be deleted green. | Test-strategy + Fact-check | Medium | test-strategy | for-author | — | 🟡 Open | — |
| A15 | Post-VOID quarantine semantics are undocumented and unpinned: a contaminated clone permanently drops its PR from the judged subset. Probably intended; nothing states or tests it. | Test-strategy | Medium | test-strategy | for-author | — | 🟡 Open | — |
| A16 | A20's supporting statistic is **10 of 15**, not 13 of 15 — could not be reproduced at 13. Two-word edit to the 2026-08-18 rubric. | Tech-debt | Minor | tech-debt D3 | for-author | — | 🟡 Open | Correction to a *prior* rubric, not this diff. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Retighten A20's trigger from "re-run more than twice" to "revisit before the second full `--all` sweep" — the two longest-lived arms in history are the two with the most machinery, and `crb-pipeline/` is already at 6 commits. | Tech-debt | Low | for-author | — | 🟢 Open |
| C2 | Pin measured constants to their sample ("the 2026-08-18 32-cell corpus") in the runbook, as `crb-cell-status.py` already does. | Tech-debt | Low | for-author | — | 🟢 Open |
| C3 | Comment the harvest's `[ -f "$clone/$f" ]` as load-bearing: it is what stops `core.worktree` redirection from reaching host files, and currently reads as a benign existence check. | Security | Low | for-author | — | 🟢 Open |
| C4 | `write_run_meta` is a function but not a mode, so provenance is still not re-derivable after a lost run (~3 lines). Un-carry this sub-item of A20. | Architecture | Minor | for-author | — | 🟢 Open |
| C5 | Mark which `crb-materialize.py` modes are destructive in the `ap.error` mode list at `:510`. | API-consistency | Minor | for-author | — | 🟢 Open |
| C6 | Four names for one entity — instance / cell / slug / PR — first collide inside one JSON object here. | API-consistency | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (`docs/reviews/override-log.md` holds one row, for
`hooks/batch-feedback-routing-reminder.sh` — a different subsystem, no location, category, or
substantive match.)

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The harvest loop resists exfiltration | ✅ Confirmed | `run-host.sh:287` — `cp --no-dereference "$clone/$f" "$dest/artifacts/$f"`, plus git's refusal to descend symlinked directories; `core.worktree` redirection of `git status` is stopped by `[ -f "$clone/$f" ]` resolving relative to `$clone`. Executed by security-reviewer. | security-reviewer | for-orchestrator-synthesis |
| `--reset` is not reachable with an attacker-influenced slug | ✅ Confirmed | The manifest gate requires both `head` and `base`, so only `slug_for()`-validated keys reach the destructive branch (`crb-materialize.py:73-88` charset check). Executed. | security-reviewer | for-orchestrator-synthesis |
| The containment machinery's runtime cost is immaterial | ✅ Confirmed | Measured: full `reset_clone`+`verify` 0.61s / 0.75s on the two largest clones vs a **161s median cell** (computed over all 32 in-repo `result.json`) = 0.9%. `--connectivity-only`: fsck 0.013s vs 0.724s. Budget gate: 0.71s for the entire 50-cell sweep. | performance-reviewer | for-orchestrator-synthesis |
| The two "must still VOID" negative controls and the `scrub_object_store` non-vacuity test do real work | ✅ Confirmed | 30 source mutations applied one at a time, 38 tests re-run per mutation: **22 caught**. The misses cluster in the CLI/wiring layer, not these. | test-strategy | for-orchestrator-synthesis |
| The `r1's exact attack` test pins a real regression | ✅ Confirmed | `git show cf6e7c9:scripts/crb-materialize.py` run against the fixture returns `OK: 1 agent commit(s) … reset`; the current module voids. Executed, logged at `docs/reviews/execution-logs/fc2-old-vs-new.txt`. | iteration-2 fact-check | for-orchestrator-synthesis |
| A20's carry remains defensible after this diff | ✅ Confirmed | A20 was scoped to the bash-heredoc duplication, which this diff never touched; the ~180 new lines went into a containment mechanism that now carries 32 executable tests, and `crb-cell-status.py` is an extraction that gave a previously untestable predicate fixtures. | tech-debt-triage | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. Every red and amber above cites a location that exists in the
tree, and the six Critical/High security and performance findings were reproduced by execution
rather than inferred.

One claim was **retracted** during synthesis rather than recorded: architecture-review escalated
that "no `security-reviewer` output has ever been produced for this harness." A
`security-review.md` for this branch exists and is the origin of the still-open R3 on the
2026-08-18 rubric; the security critic was rewriting that file concurrently in this same batch.
Treated as a concurrent-read artifact, not a finding.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an
author note. 🟢 items are optional.
