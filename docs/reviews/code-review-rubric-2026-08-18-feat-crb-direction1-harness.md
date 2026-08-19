# Code Review Rubric

**Scope:** `feat/crb-direction1-harness` (`main...HEAD`) — reviewed at `529ecd2`, fixes at `ed68ced` + `a04ef57` | **Reviewed:** 2026-08-18 | **Status: 🟡 CONDITIONAL PASS** — 0 red, amber items resolved or carried with notes below

> **Loop status.** Pass 1 (`529ecd2`) found 3 red + 26 amber. Pass 2 (`ed68ced`) closed the reds
> but **introduced a traversal regression** and left three claims stronger than the code. Pass 2b
> (`a04ef57`) closed those. Pass 3 is the confirmation pass — see
> `code-review-pass3-confirmation.md`. Under the review-fix loop's 2-consecutive-clean rule this
> branch has **not yet reached two clean passes**: pass 2 was not clean, so pass 3 is at most the
> first. Treat the status above as provisional until a second clean pass runs.

**Pipeline:** Stage 1 fact-check k=3 (merged most-severe-wins, 68% verdict agreement) → Stage 2 six critics in parallel (security, performance, api-consistency, architecture, test-strategy, tech-debt-triage) → Stage 3 synthesis. Delivery mode: self-read. All seven files are new, so every file was reviewed **greenfield**.

> **Out-of-band incident:** a Stage-1 agent destroyed this repo's git refs mid-review (root cause and recovery in `code-fact-check-report.md` § "Repo-state incident"). The reviewed commit `90de392` was pruned and reconstructed as `529ecd2` — identical tree, parent and message. Six worktree branch tips remain unrecovered and need a user decision. This is not a finding against the code under review.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | **Preflight auth check regressed against its own prior art.** The guard tests `"log in" in r.lower()`, which does **not** match the failure string its own comment documents (`"Not logged in · Please run /login"`). `e7-fable-3x/run-host.sh:103` tests `"log in"` **and** `"logged in"` — a clause E7 added deliberately after learning it "the hard way, 2026-08-14" — and this file dropped it. Auth detection now rests solely on the `num_turns < 1` arm; whether an auth failure can return `num_turns >= 1` is unresolved. This is a fail-open in a control whose only job is to stop a $50–2000 sweep burning on a bad credential. Five independent sources flagged it. | Fact-check + Security + Performance + Test-strategy + Tech-debt | Incorrect (high conf.), behavioral | `runs/review-arms/crb-pipeline/run-host.sh:126` (comment at `:104-105`) | for-author | — | ✅ Fixed in `ed68ced` |
| R2 | **Answer-key containment is proven once and never re-asserted.** The arm's core validity invariant — no route from the reviewed clone to the merged upstream fix — is established inside `materialize()` and verified there by two guards. But `run-host.sh` then mounts that same clone **read-write** into an agent container running `--dangerously-skip-permissions`, and restores it with `git checkout -- . \|\| true` + `git clean -qfd \|\| true` (both failure-swallowing, and `clean` without `-x` leaves gitignored files). The guard is fifteen lines welded inside `materialize()` with no callable seam, so nothing re-checks containment before or after any cell. Failure is silent and looks exactly like success — it would invalidate every number the arm produces. Carries a **Contested-Soundness** annotation: the stated intent (`crb-materialize.py:10-14`, "NO other refs and NO origin remote, so a reviewing agent cannot fetch the upstream future") is defeated at runtime by the mechanism in `run-host.sh`. | Architecture (+ Security, Fact-check) | Structural | `scripts/crb-materialize.py:186-196`; `runs/review-arms/crb-pipeline/run-host.sh:155-159`, `:200-201` | for-author | — | ✅ Fixed in `ed68ced` |
| R3 | **Prompt injection from the reviewed repository reaches a live credential.** `run-host.sh:155-167` runs the agent with `--dangerously-skip-permissions`, `-e ANTHROPIC_API_KEY`, a read-write `/repo` mount and **no `--network` restriction**, over third-party repository content. The script's own header (`:34-36`) states repo-local instructions load as they would for any real user — so a single crafted file in a benchmark fork can exfiltrate the key. `--max-budget-usd` bounds spend, not exfiltration. | Security | High | `runs/review-arms/crb-pipeline/run-host.sh:155-167` | for-author | — | 🟡 **Partially closed — author decision required** |

**Resolution.** R1 closed in `ed68ced` (both auth strings tested, matching E7's prior art).
R2 closed in `ed68ced` + `a04ef57`: the guard is now a callable `verify_containment()` re-asserted
before and after every cell, additionally failing if any remote survives, and a post-run failure
**voids** the cell rather than warning. Proven non-vacuous — passes on all five pilot clones,
fires when a remote is added.

**R3 is the one red not fully closed, and it needs the author, not another commit.** What landed:
transcripts and stderr gitignored, the host-side harvest no longer follows symlinks or accepts
traversal paths, and the judge-side credential path is guarded. What did **not** land: the review
container still runs `--dangerously-skip-permissions` with a live `ANTHROPIC_API_KEY` and
unrestricted network egress over third-party repository content. Closing it properly means a
**dedicated low-limit API key behind an egress allowlist** — a host-and-billing decision this
review cannot make for you. Until then, treat the branch as safe to *merge* but gated for
*running*: the code is fine, the operational posture is the open question.

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | No sweep-level budget ceiling. `--max-budget-usd` caps one instance; the loop has no aggregate counter and `run-meta.json` totals cost only after the last cell. Default settings × 50 instances = up to **$1250 unattended** before any total becomes visible. | Performance | High | performance-reviewer | for-author | — | ✅ Fixed in `ed68ced + a04ef57` | — |
| A2 | Errored / budget-exhausted cells are recorded as complete. The resume predicate is `num_turns > 0` — presence of turns, not success. `is_error`/`subtype` are never inspected and the non-zero docker exit is swallowed at `:167-168`. Paid work is spent *and* the cell is locked out of retry without a manual `rm`. | Performance + API-consistency | High | performance-reviewer, api-consistency F5 | for-author | — | ✅ Fixed in `ed68ced + a04ef57` | — |
| A3 | Judge seeding fails open. The seed is what keeps stage 4 at ~$17 instead of ~$850; a missing judge dir or half-copied seed is a stderr warning, not an error — the script still exits 0 and writes a normal-looking `RUN.md`. Two `print`→`sys.exit` changes. | Performance | High | performance-reviewer | for-author | — | ✅ Fixed in `ed68ced` | — |
| A4 | **Time-boxed.** Foreign-repo content will be committed to tracked `runs/`. `.gitignore:42` bans `runs/**/prompt.txt` as "foreign-repo content shipped to third-party APIs — never commit"; `transcript.jsonl` is a strict superset (every file the agent read, quoted in full) and is **not** ignored. Verified by the orchestrator: **16 `transcript.jsonl` files are already committed** under `runs/review-arms/e7-fable-3x/`. One `.gitignore` line now; unfixable in place once 50 more land in history. | Security + Performance | Medium | security-reviewer, performance-reviewer | for-author | — | ✅ Fixed in `ed68ced` | — |
| A5 | The generated runbook's `export MARTIAN_API_KEY="$ANTHROPIC_API_KEY"` **fails open to `https://api.withmartian.com/v1`** if `MARTIAN_BASE_URL` is not also exported — verified against the benchmark's own `step3_judge_comments.py:106`. An Anthropic key would be sent to a third-party endpoint. | Security | Medium | security-reviewer | for-author | — | ✅ Fixed in `ed68ced + a04ef57` | — |
| A6 | `slug_for()` path escape. `.replace(".", "_")` blocks `..` but not `/`, and `Path(DST_ROOT) / "/abs/path"` discards the root entirely — a hostile `repo_name` in the vendored dataset yields a `dst` outside `DST_ROOT` that is cloned into and, under `--force`, `shutil.rmtree`d. The same unvalidated field builds the clone URL. | Security | Medium | security-reviewer | for-author | — | ✅ Fixed in `ed68ced + a04ef57` | — |
| A7 | Harvest `cp` dereferences agent-created symlinks into the tracked artifacts dir. This runs **host-side**, so `~/.ssh` and similar are in reach. | Security | Medium | security-reviewer | for-author | — | ✅ Fixed in `a04ef57 (regressed in ed68ced)` | — |
| A8 | Golden-denominator caveat understated ~12×: says "same 2 PRs, `total_golden` 11 vs 13"; actually **24 of 50 PRs** disagree, values range 1–9, and 11/13 occur nowhere. 4 of 5 pilot PRs affected, and the skew runs **against** our arm (28 of 49 tools scored on a smaller denominator). Unanimous across all three fact-check replicates, each measuring independently. Fix before any results doc quotes a recall number. | Fact-check | Incorrect (high conf.), doc-only | `docs/working/crb-direction1-setup.md:172-176` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A9 | "The aggregate table at the end of step 3 is a real leaderboard" is contradicted by `crb-subset-leaderboard.py:4-8` **in the same commit**. Separately unflagged anywhere: our arm is judged **with** step-2.5 dedup while the checked-in rows were judged **without** it — a precision asymmetry in our own favour, stacking on A8's recall asymmetry against us. Neither is in the caveats list. | Fact-check | Incorrect, doc-only | `scripts/crb-pipeline-to-benchmark.py:13-15` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A10 | "Score `--sections fix address` as a second tool name in the same judge pass" is contradicted by the doc's own `--out runs/review-arms/crb/offline-work-50-ra` example — a separate work dir means a separate judge invocation, and the two rows cannot share a leaderboard table. | Fact-check | Incorrect, doc-only | `docs/working/crb-direction1-setup.md:117-120` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A11 | The `--tool` rationale is wrong on count and mechanism: 50 missing pairs, not ~52; and step 3 would **not** re-judge them (seeded evaluations cover all 2449 pairs). The genuinely unguarded cost is **step 2.5** — no `dedup_groups.json` is checked in, so omitting `--tool` there means **~2233 paid LLM calls**, documented nowhere. | Fact-check + Tech-debt | Incorrect, doc-only | `scripts/crb-pipeline-to-benchmark.py:268-271` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A12 | `--all` disk estimate `~15-25GB` contradicts both the measured ~6.7 GB (from `instances.json`'s own `clone_mb` values) and `docs/working/crb-direction1-setup.md:27`'s `~6-7 GB` **in the same commit**. | Fact-check | Incorrect, doc-only | `scripts/crb-materialize.py:26` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A13 | `--tool-name` on the injector vs `--tool` on the leaderboard *and* all three vendored benchmark steps. Four of the five commands in the documented sequence take `--tool`; one does not — and that flag is the cost-confinement lever (see A11). | API-consistency | Inconsistent | `scripts/crb-pipeline-to-benchmark.py:170` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A14 | The judge is a flag at stage 3 (`--judge`, `--out`) but a hard-coded constant at stage 4. Changing `--judge` produces evaluations the leaderboard's default cannot find, failing with "run step 3 first" — misdiagnosing the cause. The generated `RUN.md` passes `--evaluations` explicitly and dodges this; the setup doc's example at line 134 does not. | API-consistency + Architecture + Fact-check | Inconsistent / Coupling | `scripts/crb-subset-leaderboard.py:26-27` | for-author | — | ✅ Fixed in `ed68ced + a04ef57` | — |
| A15 | `↩️ Considered Overrides` **passes** the injector's substring section filter (`"consider"` ⊂ it) and is excluded only because the rubric template names its column `Prior finding` rather than `Finding`. A one-word rename in `skills/code-review/SKILL.md`, or `--sections consider` alone, would silently inject waived findings as guaranteed false positives. The contract is declared on neither side. Flagged by four independent sources. | Fact-check + Architecture + Tech-debt + Test-strategy | Mostly accurate / Coupling | `scripts/crb-pipeline-to-benchmark.py:58-60`, `:97-110` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A16 | `git clean -qfd` omits `-x`, so gitignored artifacts a review creates survive between re-runs of the same instance, and the harvest misses them too. `git checkout -- .` restores from the index, so a review's `git add` also persists. (Tech-debt correction: the leak is across re-runs of one instance, not across instances — each gets its own clone dir.) | Fact-check + Performance + Tech-debt + Test-strategy | Mostly accurate | `runs/review-arms/crb-pipeline/run-host.sh:150-153`, `:200-201` | for-author | — | ✅ Fixed in `ed68ced` | — |
| A17 | Failed materialization leaks a full-size clone that then masks itself via the `dst.exists()` early return — a later run reports "exists, skipping" for a broken clone. | Performance | Medium | `scripts/crb-materialize.py:152-157` | for-author | — | ✅ Fixed in `a04ef57` | — |
| A18 | **Carried, not fixed.** No first-instance canary. The preflight catches auth and skill registration but cannot catch "ran fine, cost $20, produced no rubric" — which `crb-direction1-setup.md:197-203` itself names as the highest-risk assumption and answers only with a human instruction. | Performance | Medium | `runs/review-arms/crb-pipeline/run-host.sh:103-132` | for-author | — | 🟡 Carried | Deliberate. The setup doc already instructs running one instance (`run-host.sh keycloak-PR36880`, smallest diff) and reading `review.md` before any sweep. A mechanical canary duplicates that with more code; revisit if the pilot shows the human step gets skipped. |
| A19 | **Fixed in `ed68ced`** (generated `judge.sh`). `--tool` confinement was enforced by documentation only. A generated `judge.sh` alongside `RUN.md` would make it mechanical rather than a thing the operator must remember under A11's cost exposure. | Performance + API-consistency | Medium | `scripts/crb-pipeline-to-benchmark.py:272-295` | for-author | — | ✅ Fixed in `ed68ced` | Generated `judge.sh` bakes `--tool` into all three steps; `RUN.md` now leads with it. |
| A20 | **Carried, not fixed** (tech-debt lifetime evidence). Cell layout lives in four bash heredocs and is independently re-derived by the injector; harvest and `run-meta.json` are not re-runnable after a partial sweep. | Architecture | Coupling | `runs/review-arms/crb-pipeline/run-host.sh:174-213`, `:217-236` | for-author | — | 🟡 Carried | Deliberate, on tech-debt evidence: 13 of 15 `runs/review-arms/` dirs have identical first/last commit dates, so the refactor risk lands in the sweep window and the benefit in a maintenance phase history says will not occur. Revisit if this arm is re-run more than twice. |
| A21 | Two writers of the vendored `review_comments` record shape (`canon-to-crb.py` and this injector), already divergent on `created_at` / `source_provenance`, with a third (cubic) landing. `created_at` is dropped here although both other writers include it — safe today, but it makes our rows structurally distinguishable from every other tool's. | Architecture + API-consistency | Coupling | `scripts/crb-pipeline-to-benchmark.py:227-233` | for-author | — | ✅ Fixed in `a04ef57 (constants only)` | — |
| A22 | **Partially fixed in `a04ef57`** (sweep now exits 3 when nothing ran and something was unusable). Inconsistent unknown-instance handling across the chain: hard-exit at stage 1, warn-and-continue at stage 2 (the **paid** stage, exiting 0 after skipping everything), warn-and-continue at stage 3 — where the sibling E7 runner hard-exits on the identical condition. | API-consistency | Inconsistent | `scripts/crb-materialize.py:101-108`; `runs/review-arms/crb-pipeline/run-host.sh:136` | for-author | — | 🟡 Partially fixed in `a04ef57` | The sweep now exits 3 when no cell ran and something was unusable, so an all-skipped sweep is no longer a silent success. Per-stage handling is still uneven; carried as cosmetic. |
| A23 | **Carried, not fixed.** `--judge` takes a **bare** model id here, but every other `--judge` in `scripts/` (and `MARTIAN_MODEL` in the benchmark) takes a provider-prefixed one. The default path works and is documented; the trap is for a user copying the shape their neighbours teach. | API-consistency | Inconsistent | `scripts/crb-pipeline-to-benchmark.py:172-173` | for-author | — | 🟡 Carried | Default path is correct and documented. Carried as a documentation matter rather than adding provider-prefix parsing. |
| A24 | **Carried, not fixed.** Three names for "rehearse, write nothing" across one chain: `--dry-run` / `DRY_RUN=1` / `--stats`. `DRY_RUN=1` is correct for the shell surface; `--stats` is the outlier. | API-consistency | Inconsistent | `scripts/crb-pipeline-to-benchmark.py:187` | for-author | — | 🟡 Carried | Cosmetic. `DRY_RUN=1` is right for the shell surface; renaming `--stats` would break the documented flow for no functional gain. |
| A25 | **Carried, not fixed.** Relative `--out` resolves against CWD here vs `WORKSPACE` in `canon-to-crb.py`; `sanitize_model` is a renamed, docstring-stripped clone of the vendored `sanitize_model_name` whose output it must keep matching. | API-consistency | Inconsistent / Minor | `scripts/crb-pipeline-to-benchmark.py:63-64`, `:169` | for-author | — | 🟡 Carried | `sanitize_model` is now single-sourced in `scripts/crb_common.py` (A21). Relative `--out` resolution and the `created_at` delta remain, both harmless today and flagged so they are conscious. |
| A26 | Guard (b) does not actually check blob presence, and exercises only blobs the **diff touches**; a partial clone surfaces as an opaque `RuntimeError` from `sh()`'s `check=True` rather than the guard's own diagnostic. Manifest docstring lists 9 of the 14 keys actually written. `discourse-graphite` is not a mirror split. Grouping key is `family(source_repo)`, not `source_repo`. `--all-prs` is evaluations-file-scoped, not "the full 50". Volume-ownership rationale is off; `opus` is a floating alias. | Fact-check | Mostly accurate | `scripts/crb-materialize.py:29-31`, `:93-98`, `:111-113`, `:191-193`; `scripts/crb-subset-leaderboard.py:16`; `run-host.sh:57-59`, `:97-99` | for-author | — | ✅ Fixed in `ed68ced` | — |

---

## 🟢 Consider

Advisory findings. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Add a `comments_from_rubric()` test over `test/skills/code-review/rubric-current-format.md` — an already-checked-in golden rubric kept current by `code-review-format-contract.bats`. Closes the A15 gap using an existing drift-guarded asset, testing the emitter and consumer halves of one contract. Highest value-per-effort in the plan. | test-strategy (G1) | — | for-author | — | 🟢 Open |
| C2 | Extract the preflight heredoc (`run-host.sh:119-132`) into a callable `preflight-check.py` (~4 lines) so R1's regression becomes testable and hermetic. Prerequisite for test-strategy's suite 2, and touches the runner — sequence with other run-host edits. | test-strategy (G9) | — | for-author | — | 🟢 Open |
| C3 | Test guard *logic* via a PATH `git` stub (the repo's own bats convention), **not** a real git fixture. Test-strategy explicitly recommends against a git-fixture test of `crb-materialize.py:176-184` — that block contains the same three commands that destroyed this repo's refs during Stage 1. | test-strategy (G8) | — | for-author | — | 🟢 Open |
| C4 | Deliberately **not** worth testing: the docker sweep loop, all network paths, leaderboard arithmetic, and `--dry-run`/`--stats` stdout formatting (brittle). No Python test convention exists in this repo (30 bats suites, Python tested as subprocesses per `test/cross-model-review-stage1.bats`); do not introduce pytest for ~680 lines of finite-lifetime tooling. `external/` is gitignored, so end-to-end tests reading `benchmark_data.json` would fail the repo's own hermeticity gate. | test-strategy | — | for-author | — | 🟢 Open |
| C5 | **Carry intentionally** (tech-debt, with reasoning): duplicated `WORKSPACE`/`BENCH`/`MANIFEST`/tool-name constants across four files, and the four `python3 - <<'EOF'` heredocs. Evidence: 13 of 15 `runs/review-arms/` directories have identical first- and last-commit dates; every arm forks its own runner and none has ever shared a library. The refactor's risk lands in the sweep window, its benefit in a maintenance phase history says will not occur. | tech-debt (3, 4) | — | for-author | — | 🟢 Open |
| C6 | Strictly sequential instance loop despite fully isolated instances — defer and monitor pending a real per-instance duration from the pilot. | Performance + tech-debt (8) | Low | for-author | — | 🟢 Open |
| C7 | Collapse architecture findings 3–6 into one shared `scripts/crb_*` module (~an afternoon), removing four hand-copied projections. Weigh against C5's carry-intentionally reasoning — these two recommendations genuinely conflict; the tech-debt critic saw the lifetime evidence, the architecture critic saw the coupling. | Architecture | Minor | for-author | — | 🟢 Open |
| C8 | Manifest has no schema marker or validating reader; arm split across `crb/` and `crb-pipeline/` with undeclared divergence from `prep-cc-review-clones.sh` (whose tree-contents guard was dropped); lossy `slug` key; undeclared dependence on the benchmark's cwd-relative `RESULTS_DIR`. | Architecture | Minor / Informational | for-author | — | 🟢 Open |
| C9 | `source_provenance` is a tolerated 5th key on a schema we do not own; all consumers read by key, so it is safe — flagged only so the delta is conscious. | API-consistency (F8) | Informational | for-author | — | 🟢 Open |
| C10 | Unbounded verbose transcripts and per-container `npx` install; `dir_mb()`'s full-tree walk, the in-loop manifest rewrite, and full `benchmark_data.json` re-serialization were recorded by the performance critic as explicit **non-findings** with reasons rather than dropped or inflated. | Performance | Low / Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C11 | `awk '{print $2}'` over `git status --porcelain` truncates paths containing spaces and mishandles renames. Worth fixing; not worth a test suite. | test-strategy (G12), fact-check (out-of-scope note) | Low | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

`docs/reviews/override-log.md` holds one entry — the 2026-06-23 `feat/batch-feedback-subagent-routing` row about `hooks/batch-feedback-routing-reminder.sh` firing on every `UserPromptSubmit`. It matches this diff on neither location (no `hooks/` file is touched), category (hook firing frequency vs harness cost/containment), nor substance. Recorded explicitly so absence is auditable across runs.

---

## ✅ Confirmed Good

Every row carries `Evidence` and has passed the Confirmed-Good cross-check against the merged fact-check report **and all three per-replicate reports**.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| No shell-injection surface in the new Python. All subprocess use is list-form. | ✅ Confirmed | Orchestrator-executed enumeration: `grep -n "shell=True" scripts/crb-materialize.py scripts/crb-pipeline-to-benchmark.py scripts/crb-subset-leaderboard.py` → **0 matches**; 16 subprocess call sites in `crb-materialize.py`, all list-form. The most likely RCE path in a repo-cloning harness is closed by construction. | security-reviewer + orchestrator enumeration | for-orchestrator-synthesis |
| The ref scrub, **as executed at materialize time**, removes every ref outside the reviewed ancestry, and self-verifies. | ✅ Confirmed | `scripts/crb-materialize.py:176-190` — scrub ordering (`update-ref -d` → `remote remove` → `reflog expire` → `gc --prune=now`) then `git rev-list --all --not <head>` guard. Verified independently by all three fact-check replicates. **Scoped deliberately:** this certifies the operation at materialize time only — see R2 for the un-re-asserted runtime invariant. | Fact-check r1/r2/r3 | for-orchestrator-synthesis |
| The **skill-registration** half of the preflight is fail-closed. | ✅ Confirmed | `runs/review-arms/crb-pipeline/run-host.sh:128-130` — `if "code-review" not in r: sys.exit(...)`. Aborts the sweep rather than silently measuring the built-in reviewer. **Scoped deliberately:** the *auth* half is R1 and is not certified here. | security-reviewer, Fact-check | for-orchestrator-synthesis |
| Judge-cost confinement is belt-and-braces: seeding and `--tool` each independently suffice. | ✅ Confirmed | Verified against the vendored `step2_extract_comments`, `step2_5_dedup_candidates`, `step3_judge_comments` — all three skip `(PR, tool)` pairs already present. Confirmed by r1 and r3 reading the benchmark source directly. | Fact-check r1/r3 | for-orchestrator-synthesis |
| The E8-payload provenance chain is fully accurate. | ✅ Confirmed | All four sub-claims independently verified: 87% recall / 0 FPs present in `docs/working/e8-results-2026-08-18.md`; merge commit `d9234c9` exists; `git diff main feat/critic-evidence-discipline -- skills workflows CLAUDE.md` is empty; orchestrator ran on Fable 5 at k=2. r2 additionally found the equivalence holds for `guides/` and `patterns/` too — paths the header's own diff command omits. | Fact-check r1/r2/r3 | for-orchestrator-synthesis |
| `--per-repo 1` yields exactly the 5 pilot PRs and 33 goldens. | ✅ Confirmed | Enumeration, not an instance: the selection reproduces exactly `cal_com-PR11059`, `discourse-graphite-PR4`, `grafana-PR79265`, `keycloak-PR36880`, `sentry-greptile-PR5`; goldens 9+8+5+5+6 = 33, matching `runs/review-arms/crb/instances.json` and the commit message. | Fact-check r1/r2/r3 | for-orchestrator-synthesis |
| The manifest on disk matches the writer's record shape field-for-field. | ✅ Confirmed | `scripts/crb-materialize.py:210-216` vs `runs/review-arms/crb/instances.json` — all 14 keys agree. (The *docstring*'s 9-key enumeration is the A26 defect; the contract itself is sound.) | Fact-check r1/r3, api-consistency | for-orchestrator-synthesis |
| `git archive` payload isolation. | ✅ Confirmed | `runs/review-arms/crb-pipeline/run-host.sh:85-86` — `git -C "$ROOT" archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md \| tar -x`. Not a bind mount of `$ROOT`, so a running review cannot edit the skills reviewing it; `hooks/` and `scripts/` are excluded as the header claims. | security-reviewer, Fact-check | for-orchestrator-synthesis |
| Micro-averaging in the subset leaderboard matches step 3's own convention. | ✅ Confirmed | `scripts/crb-subset-leaderboard.py:67-72` sums tp/fp/fn across the subset then divides — verified against the vendored step 3's aggregate. | Fact-check r3 | for-orchestrator-synthesis |

**One candidate ✅ row was revoked** — see A2. `api-consistency-reviewer` credited "resumability" as clean; `performance-reviewer` independently found the resume predicate (`num_turns > 0`) banks errored and budget-exhausted cells as complete. A confirmation another critic in the same run flatly contradicts may not be published as ✅, so it was moved into 🟡 rather than dropped silently.

---

## ⚠️ Unverified Findings

All findings the orchestrator acted on resolved at their cited locations.

**Scope limit, stated honestly:** evidence was verified for all three 🔴 rows and for the 🟡 rows carrying money or measurement consequences (A4, A8, A9, A11, A14, A15), plus both orchestrator-run enumerations in ✅. The remaining ~40 advisory-tier findings were accepted on their critics' cited evidence without independent re-reading. No finding failed a check that was run.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

`dependency-upgrade` and `ui-visual-review` were not auto-selected — no dependency manifest and no UI rendering code in the diff. `architecture-review`, `test-strategy` and `tech-debt-triage` were all auto-selected and ran.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
