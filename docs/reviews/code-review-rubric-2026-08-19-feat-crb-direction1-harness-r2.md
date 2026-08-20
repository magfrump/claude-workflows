# Code Review Rubric

**Scope:** `197eec6` then its fix commits `1d8ea67`, `4624c5d`, `f91c4c3` on `feat/crb-direction1-harness` | **Reviewed:** 2026-08-19 (3 iterations) | **Status: 🟡 CONDITIONAL PASS** — 0 red; 6 amber carried with author notes

> **⛔ Loop cap reached — decision: `escalate`, with the reds closed.** Three
> iterations ran. All four reds and every red found in the fix rounds are closed
> and pinned by executing tests. What remains is one **policy** question and a
> class of residuals no static instrument can settle. See "Loop outcome" below.

> **Why a `-r2` filename.** `code-review-rubric-2026-08-19-feat-crb-direction1-harness.md`
> is the *prior* loop's rubric — the one that recorded the `escalate` decision at the
> 3-iteration cap. Same date and branch, different loop. Overwriting it would destroy the
> escalation record this commit exists to answer, so this loop gets its own file.

**Loop status:** iteration 1 of a new review-fix loop, opened on the human `escalate`
decision. Pipeline: Stage 1 fact-check **k=3** (28 merged clusters, 71% verdict agreement)
→ Stage 2 six critics in parallel (security, performance, api-consistency, architecture,
test-strategy, tech-debt-triage) → Stage 3 synthesis. Delivery mode: **self-read** — the
diff alone is ~36k tokens, over the 25k inline budget.

**What the commit got right, up front:** the escalated design question — *should host git
ever run against a container-written `.git`?* — was answered correctly, and the
architecture critic confirms the disposable-clone move **deletes** the discriminator that
produced three consecutive mechanism errors rather than relocating it. The performance
critic measured the new overhead at **2–3 s per cell** against a 4.5–10.8 min, $10–40
review. The two controls are sound and cheap. Every red below is a **seam**, not the design.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | **The `--snapshot` path reopens R1/R2 — host `git` against an untrusted `.git`, and it is the *expected first run*.** `scrub_object_store`'s docstring claims it only ever runs on a clone the script just built; the `--snapshot` CLI branch reaches it against any directory containing a `.git`, and `--force` guards only baseline overwrite. `git symbolic-ref -d` performs a ref transaction, so a container-written `reference-transaction` hook or `core.hooksPath` fires — the exact path the prior critic *executed* for R1 — and `verify_containment`'s `git diff --shortstat` adds the `.gitattributes` smudge-filter path. Because of R4, every one of the five existing clones lands on `run-host.sh:415-418`, which prints `--snapshot <id>` as the remedy. Second impact: `--snapshot` rewrites `baseline_sha256`, the value `restore_clone` checks, so a laundered baseline passes every later `--restore` permanently. **Fix:** delete `--snapshot`; point both remediation messages at `--slug <id> --force`, which reaches the scrub only on a tree the script just cloned. | Security | High | `scripts/crb-materialize.py:236-237`, `:511-533`; `runs/review-arms/crb-pipeline/run-host.sh:415-418` | for-author | — | ✅ **Fixed in `1d8ea67`** — `--snapshot` deleted, not guarded. Terminal security pass verified by enumeration: `scrub_object_store` now has exactly one caller (`materialize()`, on a tree cloned ~20 lines above); `verify_containment` has two (that tree, and a temp extract of a hash-verified tar); `--restore` runs no git at all. |
| R2 | **The audit's exit 2 ("could not check") is published as detected contamination.** `crb-audit-clone.sh` defines 0/1/2 and `test/crb-audit-clone.bats:133` pins *"usage errors exit 2, distinct from a void"* — but the sole consumer is a bare `if ! docker run`, so exit 2 **and docker's own 125/126/127** write `CONTAINMENT_FAILED`, rewrite `result.json` to `subtype: "containment_failed"`, and land the slug in `voided_cells`. That publishes "contamination was DETECTED" about a $10–40 cell that was never checked, and it is reachable: an agent that moves or removes `.git` produces exit 2. `run-host.sh` already maps exit 2 to `exit 4` correctly in two other places (cell-status `:380-388`, harvest `:478-481`). Five-line fix; also shrinks A9. | API-consistency | **Breaking** | `runs/review-arms/crb-pipeline/run-host.sh:493-509`; `scripts/crb-audit-clone.sh:23` | for-author | — | ✅ **Fixed in `1d8ea67`, hardened in `f91c4c3`** — `audit_rc` branch covers the whole integer range; docker's 125/126/127 and the audit's 2 both abort with exit 4. Now pinned by an *executing* test (the `-gt 1`→`-gt 10` mutation that defeated the original grep pin fails it). |
| R3 | **The baseline is one contract with two halves, and only one half is protected.** The `.tar` gets atomic publish, a sha256 pin in the manifest, an internally-derived path, and a pre-run existence gate. The `.index.json` gets none of them: it is required ~110 lines later, *after* the paid cell, its path is hand-derived in the runner, and `baseline_files_indexed` is recorded but never compared — so a **stale index is never detected**. The index defines what "the pipeline wrote this" means, so drift silently corrupts the arm's output. Converged independently by architecture (F2) and api-consistency (F3). | Architecture (+ API-consistency F3) | **Structural** | `scripts/crb-materialize.py:248-320`; `runs/review-arms/crb-pipeline/run-host.sh:479` | for-author | — | ✅ **Fixed in `1d8ea67`** — `baseline_index_sha256`, atomic publish, verified in `restore_clone` before the paid container; `baseline_paths()` is the single owner and a test asserts the runner does not restate the layout. |
| R4 | **R6 is relocated, not dissolved — the sweep runs nothing as committed.** Verified against disk by two critics: `external/crb-eval/.baselines/` does not exist and none of the five manifest records carries `baseline_sha256`, so `run-host.sh:366` marks every instance `skipped_bad`, `ran=0`, and `:578-581` exits 3. That is R6's exact symptom with the remedy renamed `--heal` → `--snapshot`. It fails safe at $0, but `docs/decisions/034:69-70` states the opposite, and the remedy it names is R1's unsafe path. **This is the fourth mechanism error from the same region, inside the change meant to end that pattern.** Fix: make baseline migration a code path (a `--migrate` mode that re-clones), not an operator instruction, and correct 034. | Architecture (+ Fact-check Incorrect, Tech-debt D1, Test-strategy G11) | **Structural** | `docs/decisions/034-...:69-70`; `runs/review-arms/crb-pipeline/run-host.sh:366`, `:578-581` | for-author | — | ✅ **Fixed in `1d8ea67`** — 034 corrected to what is true (R6 moved, fails safe at $0, remedy is a rebuild). Re-verified against disk on the terminal pass. |

**Root cause tying R1, R3 and R4 together**, named by the architecture critic: the baseline
tar + index is a new persisted inter-module contract with **no single owner**. All four
fixes are small and in-place — an accessor for the paths, an index hash in the manifest, a
`--migrate` code path, an exit-code branch. None requires restructuring.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | **The egress preflight's verdict logic is pinned by nothing — proven by mutation.** Widening leg 2 to accept HTTP 200, neutering leg 3 to `[ -n "$direct" ]`, and **dropping `--internal` from `docker network create`** each leave 37/37 green with all three "ok" lines still printed. `crb-egress-config.bats` pins the preflight's *existence*, not its verdicts. Fix: extract `scripts/crb-egress-verdict.sh`, mirroring how `crb-cell-status.py` was extracted from this same runner. | Test-strategy | Medium → lifted | Test-strategy G5/G6/G7 (21 mutations, 7 caught, 14 survived) | for-author | — | 🟡 Open | Lifted from 🟢 by the Soundness-Contradiction Channel — see below. |
| A2 | **There is no operator-reachable way to run the preflight alone**, so the design's central honesty claim ("it tests itself at $0 before the first paid cell") has no mechanism. `DRY_RUN=1` exits at `run-host.sh:133`, *before* the images are built, and nothing stops after the third egress leg. ~5 lines for `PREFLIGHT_ONLY=1`. | Tech-debt | Medium → lifted | Tech-debt D2 | for-author | — | 🟡 Open | Lifted by the Soundness-Contradiction Channel. This one also falsifies a claim in `docs/working/crb-egress-and-disposable-clones-plan.md` and in the commit message. |
| A3 | **A6, third review round unchanged.** `MAX_ATTEMPTS` is nested inside `if [ -s result.json ]`, and `result.json` is written only when a `result` event exists — so a container that dies mid-review re-runs at every resume forever while ledgering `cost_usd: 0`, invisible to `SWEEP_BUDGET`. The new preconditions (sidecar, `--internal` net, baked image) all fail in exactly that shape, which makes it more likely to fire than when it was first raised. | Performance | High | performance-reviewer | for-author | — | 🟡 Open | Critic asks for this to block the pilot rather than carry again. |
| A4 | **A7, third review round unchanged.** The `SWEEP_BUDGET` gate sits at the bottom of the loop; all four early `continue`s jump it, so a resume already over ceiling pays one full $10–40 cell first. Fix: hoist the gate to the top of the loop body. | Performance | Medium | performance-reviewer | for-author | — | 🟡 Open | — |
| A5 | **`scrub_object_store` has zero tests and its whole body can be replaced with `return` leaving 37/37 green** — executed. It is what makes every audit check non-vacuous. The deleted suite had a dedicated non-vacuity pin; it did not carry over. Fact-check Claim 24 rates the commit message's "load-bearing void cases carried" as Mostly Accurate for this reason. | Test-strategy + Fact-check | Medium | Test-strategy G1, Fact-check Claim 24 | for-author | — | 🟡 Open | Two other cases also did not carry: the tag-outside-ancestry variant and the shallow-clone false-positive control. |
| A6 | **The proxy is `--restart no` and its liveness is proven once, at t=0.** If it dies mid-sweep every remaining cell fails into A3's state. A `$0` `in_cell_net` probe before each review container closes it. | Performance | Medium | performance-reviewer | for-author | — | 🟡 Open | New this round. |
| A7 | **`ConnectPort 443` does not refuse plain-HTTP proxying**, and the comment says it does. `ConnectPort` scopes CONNECT only; `HTTP_PROXY`/`http_proxy` are exported to every cell, and no test or preflight leg exercises the non-CONNECT path. The filter still holds the allowlist, so residual exposure is probably nil — but the wrong comment plus a test that pins `ConnectPort` as the guard is how a future edit gets through. Fix: correct the comment, add preflight leg 2b. | Security + Fact-check (Incorrect, 2 replicates) | Medium | security #3, fact-check 9b | for-author | — | 🟡 Open | `ConnectPort 443` is also pinned by presence, not exclusivity — adding `ConnectPort 80` survives the suite (test-strategy G8). |
| A8 | **`run-host.sh:413` restore failure can be swallowed** — changing `|| { skip }` to `|| true` stays green, and the cell would then run on whatever tree is present. `run-host.sh` has **no executing test at all** (582 lines, all the money). | Test-strategy | Medium | Test-strategy G10 | for-author | — | 🟡 Open | Scope call larger than this commit; the swallow-specific case is not. |
| A9 | **A containment void marks the cell and the sweep keeps spending**, and `run-host.sh:578` exits 0 even if every cell voided. | Security | Medium | security #2 | for-author | — | 🟡 Open | — |
| A10 | **The DNS side channel is disclosed only in `docs/decisions/034`**, not at the point where an operator authorizes spend; and preflight leg 3 proves only that one internet host is unroutable — nothing about the docker host or sibling containers. | Security | Medium | security #4/#5 | for-author | — | 🟡 Open | Shape across A7/A9/A10: the controls are stronger than the evidence collected about them — one preflight leg per control, each testing the case the author had in mind. |
| A11 | **The `--snapshot` "baseline already exists" guard is untested** — its own comment calls it "the only guard against laundering a used clone into the baseline", and `if False:` leaves the suite green. A3's exact shape from the prior loop, one function over. | Test-strategy | Medium | Test-strategy G2 | for-author | — | 🟡 Open | Moot if R1's fix deletes `--snapshot`. |
| A12 | **Two Stale comments.** `docs/working/crb-direction1-setup.md:27` still advertises `--all` as `~6-7 GB` against this commit's own ~13 GB (the figure an operator sizes a disk from). `run-host.sh:425` says "the tree reset below" — nothing resets below; the restore runs *above*, and `:510-512` says so correctly. The second is the comment-credits-a-nonexistent-mechanism class the prior loop produced three of. | Fact-check | Stale ×2 (3/3 replicates) | fact-check Claims 5, 12 | for-author | — | 🟡 Open | — |
| A13 | **Four Incorrect and nine Mostly-Accurate documentation claims** beyond those already carried above: "the harvest became **strictly** more complete" (refuted — it skips symlinked artifacts the old loop copied, and adds caps the old had none of); "exactly ONE reachable host" (overstates what a cell *attempts* — `devcontainer-config/egress/base.txt` lists five more, and no `DISABLE_AUTOUPDATER` is set); preflight leg 2 accepts `000` so it isolates "the filter works" only given leg 1; the audit header's `docker run` example omits `-u node`/`--entrypoint bash` and would be eaten by `ENTRYPOINT ["claude"]`; "several benchmark repos ignore `docs/`-adjacent paths" (none of the five ignores `docs/reviews/`); "every stray is reported" (only the first foreign commit is named); the audit's exit legend calls 2 "could not check" while a `git fsck` error exits 1. | Fact-check | Incorrect / Mostly Accurate | merged k=3 report | for-author | — | 🟡 Open | All comment/doc-only under decision 031's tier policy, hence 🟡 not 🔴. |
| A14 | **A9 is not reduced — it is worse.** The void protocol now has a *fourth* encoding (the audit's tri-state exit), the writer is still `|| true`, and a repo-wide grep finds no test referencing `CONTAINMENT_FAILED` (removing the marker survives — test-strategy G13). A12 and A13 also remain open, and A12's shape recurred in new code: the `.baselines/` layout is authoritative in `crb-materialize.py:73` and hand-copied into `run-host.sh:366` and `:479`. | Architecture + API-consistency + Tech-debt | Coupling | architecture, api-consistency F7, tech-debt D4 | for-author | — | 🟡 Open | R2's fix shrinks A9 by one encoding. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `setup_egress` force-removes a fixed container name, so a concurrent sweep kills the first's egress mid-cell. | Tech-debt D7 | Low | for-author | — | 🟢 Open |
| C2 | The proxy image is tagged `rev-parse --short HEAD` — provenance a dirty tree does not have. | Tech-debt D8 | Low | for-author | — | 🟢 Open |
| C3 | `EGRESS_SUBNET` is an invited override that takes effect on one side only; the proxy's `Allow` is baked into the image. Fails closed at `exit 5`, but the message blames the API. A two-line bats cross-check is worth taking now. | API-consistency F6, tech-debt | Minor | for-author | — | 🟢 Open |
| C4 | The paid auth preflight is spent per invocation and appears in neither `run-meta.json` nor `SWEEP_BUDGET`. | performance-reviewer | Low | for-author | — | 🟢 Open |
| C5 | The audit forks one `merge-base` per stray commit — unbounded in exactly the fetch case it exists to catch. | performance-reviewer | Low | for-author | — | 🟢 Open |
| C6 | `ARTIFACT_SUFFIXES` vs `SUFFIXES` plus a verbatim-duplicated walk-exclusion held by a comment — verbatim the trigger `crb_common.py`'s docstring names, and both sides are Python. | API-consistency F5 | Minor | for-author | — | 🟢 Open |
| C7 | `--force` gains a second meaning under `--snapshot` while `--help` documents only "rebuild existing clones". | API-consistency F4 | Minor | for-author | — | 🟢 Open |
| C8 | `exit 5` joins four undocumented exit codes while the adjacent auth preflight still exits 1. | API-consistency F8 | Minor | for-author | — | 🟢 Open |
| C9 | Argv slugs bypass the charset validation `slug_for` applies; traversal is blocked only incidentally by manifest lookups. | security #7 | Low | for-author | — | 🟢 Open |
| C10 | The audit container mounts the untrusted clone read-write. | security #9 | Info | for-author | — | 🟢 Open |
| C11 | Harvest total/count caps are untested (G9); the `--dry-run` test resolves against the *real* `external/crb-eval` and would delete a live `fixture` clone while still passing (G17 — A5's shape relocated). | Test-strategy | Low | for-author | — | 🟢 Open |
| C12 | Sharing the egress allowlist with sibling arms: **defer**. E5/E6/E7 review clones whose answer key is pruned from the object store, so their exposure is genuinely lower; extracting an unexecuted control on one data point costs half a day of docker-requiring re-verification inside the sweep window. Revisit at the second arm that runs an agent container against a third-party repo. | Tech-debt D6 | Low | for-author | — | 🟢 Open |
| C13 | **A20's supporting statistic flipped, and this commit is what flipped it.** Identical-first/last-date arm dirs went 10-of-15 at `e159618` → 9-of-15 at HEAD, with `runs/review-arms/crb-pipeline` the single directory that moved — exactly what C1 of the prior rubric predicted. The carry still reaches the same conclusion, but its stated reason ("arms are single-use") is now false and should be restated as "a paid sweep is about to run against code whose docker path has never executed", which has a clear expiry. A16 needs a second correction. | Tech-debt D9, C1-prior | Low | for-author | — | 🟢 Open |
| C14 | `docker/` build inputs now live inside the arm's output directory that two consumers enumerate. | Architecture, tech-debt | Minor | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (`docs/reviews/override-log.md` holds one entry, on
`hooks/batch-feedback-routing-reminder.sh` — no location, category, or substantive overlap
with this commit.)

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The four new suites pass, and the commit message's count is exact. | ✅ Confirmed | Executed independently by all three fact-check replicates: `1..37`, 37 ok, 0 not ok, exit 0; per-suite 9+10+9+9. Logs under `docs/reviews/execution-logs/`. | Fact-check r1/r2/r3 | for-orchestrator-synthesis |
| The two new controls cost 2–3 s per cell and 1.3% of free disk — they are effectively free. | ✅ Confirmed | Measured against all five real pilot clones: sha256 over the 210 MB tar 0.1 s; `rm -rf` + extract 0.8 s; harvest walk over 1,490 `.md`/`.json` 0.1 s; audit git commands 0.05 s; ~1 s container launch. Against 4.5–10.8 min and $10–40 per cell. `--all` ~13 GB against 280 GB free. | performance-reviewer (executed) | for-orchestrator-synthesis |
| **On the automated cell path**, no host process runs `git` against the clone. | ✅ Confirmed | Enumeration executed: `grep -nE '^[^#]*\bgit\b[^#]*"\$clone"'` and `git -C "\$CLONES` over `run-host.sh` → 0 matches, pinned by `test/crb-egress-config.bats` "the runner never runs host git against the work clone"; restore, harvest and audit are each independently git-free on the host. **Scoped deliberately to the cell path** — the `--snapshot` path is R1. | Fact-check r1/r2/r3, architecture | for-orchestrator-synthesis |
| `scrub_object_store` is genuinely load-bearing, as its docstring claims. | ✅ Confirmed | r3 reproduced `materialize()`'s clone/fetch/ref-prune sequence from scratch: before, `.git/FETCH_HEAD` present + 1 unreachable commit; after, both gone. | Fact-check r3 (executed) | for-orchestrator-synthesis |
| The symlink guard holds in both directions. | ✅ Confirmed | `test/crb-harvest-artifacts.bats` "a symlinked artifact is not harvested and not followed" plants both a symlinked file and a symlinked *directory* pointing outside the clone; `followlinks=False` plus per-entry `is_symlink()` filters at `crb-harvest-artifacts.py:60` and `crb-materialize.py:268-272`. | Fact-check r1/r2/r3 | for-orchestrator-synthesis |
| A8 (a voided cell leaving a permanently dead clone) is closed structurally. | ✅ Confirmed | `test/crb-disposable-clone.bats` erasure cases pass; the runner leaves the clone untouched after a void and the next cell's `--restore` wipes it. No performance-side regression. | Fact-check r1/r2/r3, performance | for-orchestrator-synthesis |
| The prior loop's A1 (`--dry-run` silently ignored by a destructive mode) is genuinely fixed and pinned. | ✅ Confirmed | `crb-materialize.py` honours `--dry-run` in all three modes before any destructive branch; `test/crb-disposable-clone.bats` "CLI --restore --dry-run destroys nothing" asserts it. | api-consistency | for-orchestrator-synthesis |
| The three-leg egress preflight tests the thing that runs rather than a description of it. | ✅ Confirmed | `in_cell_net()` launches the same image, on the same network, with the same proxy env a review cell gets; the skill-registration preflight runs inside `$EGRESS_NET` too. **Its verdict logic is separately unpinned — see A1.** | api-consistency, security | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. `test-strategy` was force-included via `--include`
(its auto-trigger did not fire — the commit does add tests) because its predecessor found
the two highest-value defects in this same code last loop; that judgment paid: it
contributed A1, A5, A8 and A11 here.

`dependency-upgrade` was not run. The commit adds two Dockerfiles that install
`@anthropic-ai/claude-code` and `tinyproxy`, which is dependency-shaped, but no dependency
*manifest* in the auto-selection table changed and `security-reviewer` covers the
supply-chain surface. Recorded so the coverage limit is auditable.

---

## Loop outcome — 3 iterations, cap reached, decision `escalate`

**Convergence: not reached, and the reason is worth stating precisely.** The loop needs two
consecutive clean passes; it got zero. But the trajectory is not the previous loop's:

| Iteration | Instrument | Found | Disposition |
|---|---|---|---|
| 1 | k=3 fact-check + 6 critics | 4 red, 14 amber | all 4 reds fixed in `1d8ea67` |
| 2 | k=1 fact-check (loop pass) | 5 Incorrect, **3 of them introduced by iteration 1's fixes** | fixed in `4624c5d` |
| 3 | k=3-equivalent fact-check + 5 critics, 45 mutations | 2 executed fail-opens, 1 mechanism error, 8/8 pins defeated | fixed in `f91c4c3` |

**Six consecutive rounds in this code have had a fix round introduce a new mechanism error.**
Iterations 1–3 continued that streak (R4's "R6 dissolves", the dead `exit 5`, the
`--internal` glob, the `api-reachable` empty-observation fail-open). What changed at
iteration 3 is the *instrument*, not the authoring: `test/crb-run-host-wiring.bats` runs the
runner's own branches against a `docker` PATH shim, and the three mutations that had survived
every prior suite now fail. Two earlier rounds deferred that harness as "a scope call bigger
than this commit"; the terminal pass withdrew that call by execution, and withdrawing it is
the single change most likely to end the streak — text pins cannot see wiring, and every one
of the six errors was wiring.

**Why `escalate` and not `abandon` or `split`:** nothing here is unresolved *code*. What is
left is one policy question and one class of evidence this environment cannot produce.

### The one decision that is genuinely the author's

**Should a containment void halt the sweep?** `f91c4c3` implements halt (exit 7,
`CONTINUE_ON_VOID=1` to override) as a fail-safe default, but two critics flagged it as a
human call and it is not settled by evidence:

- **Halt** treats a void as "the containment control was observed failing", which makes every
  later cell's number suspect. Cost: a single contaminated cell ends a 50-cell overnight run.
- **Continue** collects the remaining cells and adjudicates `voided_cells` at write-up.
  Cost: spending $10–40 a cell into a sweep whose central claim is already in doubt.

The default chosen is halt. Reverse it by exporting `CONTINUE_ON_VOID=1`, or say so and the
default flips.

### What no amount of further iteration can close here

**Nothing docker-shaped has ever executed** — no image built, no network created, no proxy
run. That is not a deferral, it is the environment: this session has no docker. Every
control in this branch is therefore verified *structurally and by unit test*, and the
allowlist's actual filtering behaviour is verified by `PREFLIGHT_ONLY=1` **on the host,
before the first paid cell**. Two specific assumptions it will settle, and which a fourth
iteration here could not: that Claude Code honours `HTTPS_PROXY`, and that docker honours
`--internal` on a network the security pass showed can only be observed via
`docker network inspect`.

**Merge vs run, unchanged from both prior rubrics and now stronger:** the branch is safe to
**merge** — no open finding describes broken behaviour in the committed path for a trusted
input — and gated for **running** on `PREFLIGHT_ONLY=1` passing on a real docker host.

### Recommended sequence before any paid cell

1. `PREFLIGHT_ONLY=1 bash runs/review-arms/crb-pipeline/run-host.sh` — builds the images,
   creates the network, runs the five egress legs and the auth/skill preflight. Costs one
   billed auth turn. **If `HTTPS_PROXY` is not honoured this fails here, at one turn.**
2. `python3 scripts/crb-materialize.py --slug keycloak-PR36880 --force` — the five existing
   clones have no baseline; this rebuilds one (smallest diff) and baselines it.
3. One cell: `bash runs/review-arms/crb-pipeline/run-host.sh keycloak-PR36880`, then read
   `review.md` and `artifacts/` before committing to a sweep.
4. Decide the halt-on-void question above before an unattended `--all`.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
