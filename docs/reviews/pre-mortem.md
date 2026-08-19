# Pre-Mortem: CRB direction-1 harness

**Proposal:** `feat/crb-direction1-harness` (HEAD `529ecd2`) — run our review pipeline on the WithMartian Code Review Bench's 50 PRs and score it with their judge. Four stages: `scripts/crb-materialize.py` → `runs/review-arms/crb-pipeline/run-host.sh` → `scripts/crb-pipeline-to-benchmark.py` → benchmark steps 2/2.5/3 → `scripts/crb-subset-leaderboard.py`.
**Date:** 2026-08-18
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** Failure narratives are generated directly
> from the proposal. For higher-quality narratives, run `what-if-analysis` first and
> provide its output — this skill is sharpest when seeded with already-mapped assumptions
> and coupling points.

**Prior art scanned:** `docs/decisions/` (33 records) and `docs/working/` for *contamination,
answer-key, leakage, preflight, budget, overspend, credential, denominator, dedup, num_turns,
prompt injection*. Three matches carry directly and are tagged in the narratives below:
decision 022 (payload-not-registered), `runs/review-arms/e7-fable-3x/run-host.sh:87-89` (auth
failure signature, "learned the hard way, 2026-08-14"), and
`docs/working/e5-e6-results-2026-08-14.md:69-80` (an arm that failed to complete cleanly on 3
of 3 runs).

> **⚠️ Correction to the code review this pre-mortem follows.** The review's R1 recorded as
> unresolved whether an auth failure can return `num_turns >= 1`. It cannot, for the *known*
> signature: `e7-fable-3x/run-host.sh:87-89` states empirically that a bad credential "returns
> exit 0 with result 'Not logged in · Please run /login' **and num_turns=0**". So the
> `num_turns < 1` backstop does hold for the documented failure, and R1 is a **loss of
> deliberate defense-in-depth**, not an open hole. That lowers its live severity and is why
> Narrative 2 below treats it as a contributing factor rather than the root cause. R1 still
> warrants fixing — E7 added the second clause on purpose after being burned — but it should
> not be the thing that blocks the merge on its own.

---

## Narrative 1: The leaderboard row nobody can defend

**Root cause:** `docs/working/crb-direction1-setup.md:172-176` records the golden-denominator
caveat as "on the same 2 PRs … `total_golden` 11 vs 13". The real figure, measured against
`external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`,
is that **24 of 50 PRs** carry non-uniform denominators, values range 1–9, and no PR anywhere
shows 11 or 13. Four of the five pilot PRs are affected, and the skew is systematic: 28 of 49
tools were scored against a *smaller* golden set than our arm will be.

**Chain of consequences:** The pilot runs and produces a recall figure computed against 33
goldens. `crb-subset-leaderboard.py` prints each tool's `gold` column, so the mismatch is
visible — but the caveat in the runbook tells the reader it affects two PRs, so nobody reads
the column as important. The results doc is written quoting a headline recall and citing the
caveat as evidence the comparison was handled carefully. Separately and in the opposite
direction, our arm is judged **with** step-2.5 dedup active while the checked-in rows for the
other 49 tools were judged **without** it — dedup suppresses false positives by propagating
matches to siblings, so our precision is flattered by an amount nobody has measured. Neither
asymmetry is in the caveats list. Six weeks later someone builds an argument on the number —
a decision about which arm to invest in, or an external write-up — and a reader recomputes
from `evaluations.json` and gets a materially different ranking.

**Observable outcome:** A results doc whose headline recall is not reproducible from the
artifacts it ships with. Recomputation moves our row by more than the gap between adjacent
tools in the leaderboard, so the *rank* changes, not just the decimal. The repo's own
`docs/working/` archaeology becomes the place a wrong number is quoted from, which is the
failure mode this project cares most about — its durable product is documentation later
sessions read as fact.

**Plausibility:** Likely (>50%) — the wrong caveat is already committed, and nothing in the
pipeline forces it to be recomputed before a results doc is written.
**Severity:** High — the arm's entire output is one comparative number; if it is not
defensible, the ~$50–2000 spent producing it bought nothing.

**Mitigation:** Correct the caveat at `docs/working/crb-direction1-setup.md:172-176` to the
measured "24 of 50 PRs, values 1–9, four of five pilot PRs affected, 28 of 49 tools on the
smaller denominator", and add a third caveat naming the dedup asymmetry (our rows judged with
`step2_5_dedup_candidates`, checked-in rows without). Then make it mechanical rather than
documentary: have `scripts/crb-subset-leaderboard.py` emit a `gold`-variance warning line
whenever `total_golden` differs across tools on any PR in the subset, so the asymmetry appears
in the table itself rather than only in a runbook nobody re-reads at write-up time.

---

## Narrative 2: The $900 sweep with 31 empty cells

**Root cause:** `runs/review-arms/crb-pipeline/run-host.sh:138-143` treats a cell as complete
when `result.json` has `num_turns > 0`. It never inspects `is_error` or `subtype`, and the
non-zero docker exit is swallowed at `:167-168`.

**Chain of consequences:** The operator launches `--all` overnight with defaults
(`MODEL=claude-fable-5`, `BUDGET=25.00`). Instance 4 is `sentry-greptile-PR5` — 106 files,
+2312/-981 — and the review exhausts its $25 budget mid-run. Claude Code exits having taken
many turns, so `result.json` records `num_turns` well above zero with an error subtype nobody
reads. The cell is now permanently "complete": the resume guard will skip it on every
subsequent invocation until someone manually `rm`s the directory. The same thing happens to
several more large-diff cells. Meanwhile there is no aggregate cap — `--max-budget-usd` bounds
one instance, and `run-meta.json` is written only after the final cell — so the loop keeps
spending. `docs/working/e5-e6-results-2026-08-14.md:69-80` records the base rate for this
class: a comparable arm "failed to complete cleanly on 3 of 3 runs, with the failed stages'
artifacts unrecoverable." The preflight (which under R1 now has one auth check where E7
deliberately had two) passes fine — the credential is good; that was never the problem.

**Observable outcome:** Morning after: `run-meta.json` reports `total_cost_usd` around $900,
`ls runs/review-arms/crb-pipeline/*/review.md` shows ~19 non-empty of 50, and re-running the
script prints "completed result exists, skipping" for all 50. The operator cannot tell which
cells failed without hand-inspecting 50 `result.json` files, and cannot retry without deleting
directories that also contain the successful cells' harvested artifacts.

**Plausibility:** Plausible (10–50%) — requires a full sweep before the pilot lessons land,
which is exactly what the setup doc warns against but does not enforce.
**Severity:** High — real money, slow recovery, and the failed cells are the *large* ones, so
the surviving subset is biased toward small diffs and the pilot's cost model is wrong too.

**Mitigation:** Change the resume predicate at `run-host.sh:138-143` to require
`num_turns > 0 AND not d.get("is_error") AND d.get("subtype") == "success"`, and add a
sweep-level accumulator in the loop at `:134-214` that sums `total_cost_usd` after each cell
and hard-exits when it crosses a new `SWEEP_BUDGET` env var (default ~3× `BUDGET`). Both edits
are inside a loop that already parses `result.json`.

---

## Narrative 3: The clone that answered its own question

**Root cause:** The no-answer-key invariant is established and self-verified once, inside
`materialize()` at `scripts/crb-materialize.py:186-196`. Nothing re-asserts it afterward, and
`run-host.sh:155-159` mounts that same clone **read-write** into a container running
`--dangerously-skip-permissions`, restoring it at `:200-201` with
`git checkout -- . || true` and `git clean -qfd || true` — both failure-swallowing, and
`clean` without `-x` leaves gitignored files behind.

**Chain of consequences:** On a mid-sweep cell the reviewing agent, exploring the repository as
it is designed to, runs something that writes into `.git` — a `git fetch` against a remote it
reconstructs from the fork URL printed in the manifest, or simply a `git config` change plus a
fetch while chasing context on an unfamiliar upstream. The container has unrestricted network
egress; nothing in the harness blocks this, because containment was implemented as *git-local
ref hygiene*, not as network isolation. The clone now has objects from the merged upstream
future — the answer key. The reset at `:200-201` does not remove them: `checkout -- .` restores
tracked files and `clean -qfd` removes untracked working-tree files, but neither prunes fetched
objects or refs, and both swallow their own failures. The next cell for that slug — or the
re-run after the operator deletes a failed `result.json` — reviews a repository that contains
the fix. That cell's findings score unusually well against the goldens. Nobody notices, because
a high score is the outcome everyone is hoping for, and the guards that would have caught it
only ever ran at materialize time.

**Observable outcome:** One or two cells with recall far above the others and findings whose
wording tracks the upstream fix suspiciously closely. In aggregate it presents as "the pipeline
did great on grafana" rather than as an error. If discovered after publication, every number in
the arm is retracted, because there is no per-cell record proving which clones were clean at
review time.

**Plausibility:** Unlikely-but-catastrophic (<10%) — it needs an agent to fetch, which is not
the common path.
**Severity:** Catastrophic — silent, and it invalidates the entire arm retroactively rather
than failing one cell. There is no artifact that would let you prove afterward which cells were
unaffected.

**Mitigation:** Extract the guard block at `scripts/crb-materialize.py:186-196` into a callable
`verify_containment(clone_dir, head)` and invoke it from `run-host.sh` **both** immediately
before `docker run` at `:155` and immediately after the reset at `:201`, failing the cell (not
the sweep) and recording the verdict into `run-meta.json`'s per-cell record. Pair it with
`--network none` on the review container where the reviewed repo needs no network, which turns
the containment claim from git-local hygiene into an enforced property.

---

## Narrative 4: The rename that made us look worse than we are

**Root cause:** `scripts/crb-pipeline-to-benchmark.py:58-60` claims `"Confirmed Good"` and
`"Considered Overrides"` are "deliberately absent" from the emitted sections. The filter at
`:103` is a substring test — `any(s.lower() in section.lower() for s in sections)` — and
`"consider"` **is** a substring of `"↩️ considered overrides"`. That section passes the filter
today and emits nothing only because `comments_from_rubric()` skips tables whose header lacks a
`finding` column, and the rubric template happens to name that column `Prior finding`.

**Chain of consequences:** Someone improves `skills/code-review/SKILL.md` — renames the
Considered-Overrides column from `Prior finding` to `Finding` for consistency with the other
four tables, a change a reviewer would wave through as tidying. `test/skills/code-review-format-contract.bats`
passes, because it guards the rubric template's own shape, not this consumer's assumptions
about it. Nothing anywhere declares that a second repository module parses that markdown. The
next injector run silently emits every inherited override — findings a human already
**waived** — as review comments. The judge scores them against the goldens; waived findings are
by construction not goldens, so every one lands as a false positive. Our precision column drops
by a chunk proportional to how many overrides the rubric carried, and the drop is
indistinguishable from the pipeline genuinely being noisy.

**Observable outcome:** A precision figure several points below the previous run with no
corresponding change to the pipeline's reviewing behavior, and a `candidates.json` containing
comment bodies that read like resolved history ("Inherited — not re-flagged") rather than
findings. Diagnosable only by someone who remembers the injector parses rubric markdown.

**Plausibility:** Plausible (10–50%) — `SKILL.md` is actively edited in this repo, and the
column name is exactly the kind of thing a consistency pass touches.
**Severity:** Medium — recoverable by re-running the injector and the judge for our tool only
(one judge sweep, ~$1.5–22), but it silently corrupts a comparison in the meantime.

**Mitigation:** Anchor the section match in `scripts/crb-pipeline-to-benchmark.py:103` to the
section *heading* rather than a substring — match against an explicit allowlist of normalized
headings (`must fix`, `must address`, `consider`) with an equality test after stripping emoji
and punctuation — and add the golden-rubric regression test named in the review's C1: run
`comments_from_rubric()` over the already-checked-in
`test/skills/code-review/rubric-current-format.md` and assert the emitted section set, so the
emitter and consumer halves of the contract are guarded together.

---

## Narrative 5: The key that went to Martian

**Root cause:** The runbook written by `scripts/crb-pipeline-to-benchmark.py:272-295` instructs
`export MARTIAN_API_KEY="$ANTHROPIC_API_KEY"` alongside
`export MARTIAN_BASE_URL=https://api.anthropic.com/v1/`. The benchmark's own
`step3_judge_comments.py:106` defaults `MARTIAN_BASE_URL` to `https://api.withmartian.com/v1`
when it is unset — so the two exports are coupled, and only one of them is obviously load-bearing.

**Chain of consequences:** Judging happens in a different session, on a different day, from the
one that ran the sweep — the setup doc explicitly stages them (`docs/working/crb-direction1-setup.md:15-20`,
stage 4 "either"). The operator opens `RUN.md`, copies the three `python -m` lines because those
are the steps, and re-exports the API key from memory or shell history without
`MARTIAN_BASE_URL` — or exports it in a subshell that does not survive. Step 3 starts, resolves
the base URL to WithMartian's endpoint, and sends an **Anthropic** API key as the bearer
credential to a third-party service, along with the judge prompts, which contain verbatim diff
content from 50 third-party repositories. The requests fail auth, so the operator sees errors
and retries — sending the key again — before working out that the endpoint is wrong.

**Observable outcome:** A burst of 401/403s from a host nobody expected to appear in the
terminal, and an Anthropic API key that has now been transmitted to an unrelated vendor's
ingress and must be treated as compromised and rotated. If the key is a long-lived personal
key rather than a scoped one, rotation touches every other arm and script in the repo that
reads `ANTHROPIC_API_KEY`.

**Plausibility:** Plausible (10–50%) — it requires only that one of two coupled exports be
dropped across a session boundary the design itself encourages.
**Severity:** High — credential exposure to a third party is not undone by noticing it; the
remediation is rotation plus an audit of everything that used the key.

**Mitigation:** Make the base URL non-optional in the generated runbook: change
`scripts/crb-pipeline-to-benchmark.py:272-295` to emit a `judge.sh` that sets
`MARTIAN_BASE_URL` and `MARTIAN_MODEL` inline and hard-fails with an explicit message if
`MARTIAN_BASE_URL` is unset or does not match `api.anthropic.com`, then invokes the three steps
with `--tool` already filled in. That single artifact also closes the review's A19 (`--tool`
confinement enforced by documentation only) and A13's `--tool-name`/`--tool` near-miss, since
the operator stops hand-assembling the command.

---

## Recommendations

### Must address before proceeding

1. **Narrative 1 — the denominator and dedup asymmetries** (Likely / High). The wrong caveat is
   already committed and the arm's only product is a comparative number. Fix
   `crb-direction1-setup.md:172-176` to the measured figures, add the dedup-asymmetry caveat,
   and add the `gold`-variance warning to `crb-subset-leaderboard.py`. This is the cheapest
   item on the list and the one most likely to bite.
2. **Narrative 2 — the resume predicate and the missing sweep cap** (Plausible / High). Two
   small edits inside a loop that already parses the data it needs. Without them a single
   overnight `--all` can spend most of the budget and bank the expensive cells as done.
3. **Narrative 5 — the coupled `MARTIAN_*` exports** (Plausible / High). Generate `judge.sh`
   rather than instructions. Credential exposure is the one failure here with no cheap undo.

### Worth mitigating

4. **Narrative 3 — containment not re-asserted** (Unlikely-but-catastrophic / Catastrophic).
   The probability is genuinely low, which is why it is not in the blocking group — but the
   severity is the highest on the list and the mitigation is modest (extract the guard, call it
   twice, add `--network none`). If the pilot is going to run before this lands, at minimum add
   the post-cell containment check so a breach is *detectable after the fact* rather than
   invisible. This is the one narrative where "we accepted it" is hard to defend later, because
   there would be no artifact proving which cells were clean.
5. **Narrative 4 — the rubric-column coupling** (Plausible / Medium). The golden-rubric test
   (review item C1) is nearly free and closes it. Worth doing in the same commit as the
   section-match anchoring.
   *Revisit trigger:* if precision on our arm's row drops more than ~5 points between two judge
   runs with no intervening pipeline change, inspect `candidates.json` for comment bodies
   containing "Inherited" or "not re-flagged" before concluding the pipeline regressed.

### Acknowledged risks

- **The payload-not-registered failure** — `[PRIOR CONSIDERATION]`, `docs/decisions/022-claude-workflows-payload-in-cc-isolated.md:12-24`,
  which records it happening empirically in a live session on 2026-07-29 (none of the repo's 25
  skills registered; the session silently used Claude Code built-ins). This harness already
  answers it with a fail-closed skill-registration preflight at `run-host.sh:128-130`. Carried
  as mitigated; no further action.
- **The fork-equality premise** — that every tool's fork of a PR carries identical code. The
  whole one-fork-per-PR design rests on it and it is unverifiable from inside the repo. Cheap to
  close (clone two tools' forks of one PR, diff `refs/pull/1/head`) and worth doing once, but it
  does not gate the pilot: all 50 `claude-code` forks share a single `20260310` cut date, which
  bounds the exposure.
- **`CC_VERSION=2.1.232` resolving on npm** — unverifiable offline, and a sweep-stopper if it
  ever unpublishes. Acceptable: the failure is loud and immediate at the first `npx`, costs $0,
  and the pin is the right call regardless.
- **One sample per cell.** Already stated in `crb-direction1-setup.md:183-184`. Treat every
  pilot row as a point estimate; no mitigation, just don't over-read the result.
