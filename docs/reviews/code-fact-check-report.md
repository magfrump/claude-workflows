# Code Fact-Check Report

**Repository:** /workspace (branch `feat/crb-direction1-harness`)
**Scope:** `git diff main...HEAD` — 7 files, +1209 lines (CRB direction-1 harness)
**Checked:** 2026-08-18
**Commit:** 529ecd2 (content-identical recovery of the reviewed `90de392`; see "Repo-state incident" below — all three replicates checked `90de392` and their verdicts stand unchanged)
**Replication:** k=3
**Total claims checked:** 23 merged clusters (46 / 41 / 44 raw claims across r1 / r2 / r3)
**Summary:** 0 verified, 12 mostly accurate, 0 stale, 6 incorrect, 5 unverifiable

> This merged report collates only the clusters that carry a non-Verified verdict in at
> least one replicate, plus the Unverifiable set. Each replicate independently rated
> 24–31 further claims Verified (answer-key containment, judge-cost confinement, the E8
> payload provenance chain, `--per-repo 1` → 5 PRs / 33 goldens, manifest/writer field
> agreement, micro-averaging convention, other-tool preservation); those are recorded in
> the per-replicate reports and are not restated per-claim here.

---

## Claim 1: "on the same 2 PRs, different tools' checked-in rows show `total_golden` 11 vs 13"

**Location:** `docs/working/crb-direction1-setup.md:172-176`
**Type:** Configuration / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Legibility-target:** for-author

Unanimous across all three replicates, each measuring the checked-in evaluations
independently. The caveat as written reads:

```markdown
2. **Non-uniform golden denominators in the checked-in evaluations** — on the
   same 2 PRs, different tools' checked-in rows show `total_golden` 11 vs 13
```

Both figures are wrong and the scale is wrong. Against
`external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`:
**24 of 50 PRs** carry a non-uniform `total_golden`, the observed values range 1–9, and the
maximum anywhere in the file is 9 — so the pair "11 vs 13" cannot occur at all. r2 and r3
further establish that **4 of the 5 pilot PRs** are affected, and r2 quantifies the direction:
28 of 49 tools carry a *smaller* recall denominator than our arm will.

That direction is the reason this matters. The caveat exists to tell a reader how much to
discount cross-tool recall comparisons; understating it ~12× while the bias runs against our
own arm means the pilot's headline recall would be reported as more comparable than it is.
All three replicates independently nominated this as the report's top item.

**Evidence:** `docs/working/crb-direction1-setup.md:172-176`; `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`

---

## Claim 2: "`--all` … (~15-25GB)"

**Location:** `scripts/crb-materialize.py:26`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Replicate verdicts:** r1=Stale · r2=Incorrect · r3=Incorrect · (disagreement: Stale vs Incorrect)
**Legibility-target:** for-author

```python
  scripts/crb-materialize.py --all                      # all 50 (~15-25GB)
```

The pilot's own measured `clone_mb` values in `runs/review-arms/crb/instances.json`
(33–195 MB, 670 MB total for 5 PRs) extrapolate to ~6.7 GB for 50, and
`docs/working/crb-direction1-setup.md:27` in the *same commit* states `~6-7 GB`. Two files in
one diff differ by 2–4×. r1 read the figure as inherited from the pre-pilot plan (hence
`Stale`); r2 and r3 rated it `Incorrect` against the measured data. Most-severe-wins takes
`Incorrect`.

**Evidence:** `scripts/crb-materialize.py:26`; `docs/working/crb-direction1-setup.md:27`; `runs/review-arms/crb/instances.json`

---

## Claim 3: "the aggregate table at the end of step 3 is a real leaderboard"

**Location:** `scripts/crb-pipeline-to-benchmark.py:13-15`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=— · (disagreement)
**Legibility-target:** for-author

The docstring asserts:

```python
      Untouched PRs and every other tool's reviews are preserved verbatim, so
      the aggregate table at the end of step 3 is a real leaderboard.
```

The preservation half is Verified by all replicates. The *conclusion* is contradicted by a
sibling file in the same commit, `scripts/crb-subset-leaderboard.py:4-8`:

```python
When our arm covers a 5-PR pilot and the other 49 tools cover all 50, that table
compares our row on 5 PRs against theirs on 50 — different denominators, not a
ranking.
```

Both cannot hold for the documented 5-PR pilot; `crb-subset-leaderboard.py` exists precisely
because step 3's table is *not* a real leaderboard at partial coverage.

r2 additionally records an unflagged asymmetry in the same area: our arm is judged **with**
step 2.5 dedup while the checked-in rows were judged **without** it — a precision asymmetry in
our own favour that appears in no caveat list.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:13-15`; `scripts/crb-subset-leaderboard.py:4-8`

---

## Claim 4: "bad credential — the CLI exits 0 with result 'Not logged in' (E7 note)" (and the preflight that implements it)

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:104-105`, `:126`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate · (disagreement)
**Legibility-target:** for-author

The comment documents the failure string; the test is:

```python
if d.get("num_turns", 0) < 1 or "log in" in r.lower():
    sys.exit(f"  auth failed: {r[:200]!r}")
```

`"log in"` is not a substring of `"Not logged in"` (that contains `"logged in"`) nor of
`"/login"`. All three replicates confirm the string arm never fires on the documented E7
failure text, and r2/r3 both note that E7's own preflight tested `"log in"` **and**
`"logged in"` — this script dropped the second clause.

The replicates split on consequence: r1 and r3 hold that detection still fails closed via the
`num_turns < 1` arm; r2 holds that a `num_turns == 1` auth failure escapes the auth branch and
aborts with the wrong diagnosis (the skill-registration message). Whether an authentication
failure can return `num_turns >= 1` is not settled from the repo. Most-severe-wins takes
`Incorrect`.

This is the one item in this report where the *code*, not just a comment, falls short of its
stated purpose — in a guard whose entire job is to prevent a wasted $500–2000 sweep. Restoring
the `"logged in"` clause is a one-line fix.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:104-108`, `:119-132`

---

## Claim 5: "Score `--sections fix address` as a second tool name in the same judge pass"

**Location:** `docs/working/crb-direction1-setup.md:117-120`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Replicate verdicts:** r1=— · r2=Incorrect · r3=— · single-replicate detection
**Legibility-target:** for-author

The doc's own worked example two sections earlier writes the red+amber variant to a
*different* work dir:

```bash
scripts/crb-pipeline-to-benchmark.py --sections fix address \
    --tool-name mfc-pipeline-e8-redamber --out runs/review-arms/crb/offline-work-50-ra
```

and `scripts/crb-pipeline-to-benchmark.py:196` writes `benchmark_data.json` under `--out`.
A separate work dir means a separate judge invocation and a separate evaluations file — the
two rows cannot appear in one leaderboard table, which is what "same judge pass" implies. The
cost claim that follows it ("this costs one extra judge sweep, not a new review sweep") is
correct; the mechanism described is not.

**Evidence:** `docs/working/crb-direction1-setup.md:99-101`, `:117-120`; `scripts/crb-pipeline-to-benchmark.py:196`, `:245-247`

---

## Claim 6: "step 2 re-extracts the ~52 (PR, tool) pairs the checked-in candidates file happens to be missing, and step 3 would re-judge them"

**Location:** `scripts/crb-pipeline-to-benchmark.py:268-271` (and `docs/working/crb-direction1-setup.md:143-147`)
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate · (disagreement)
**Legibility-target:** for-author

All three replicates agree the count is **50**, not ~52 (r3: 216 pairs missing from
candidates, of which 166 fall below step 2's ≥20-char extraction gate; r2 adds that all 50 are
`greptile-v5`).

r2 escalates on the *mechanism*: the seeded `evaluations.json` is already complete at 2449
pairs with zero errors, so step 3 would **not** re-judge them directly. The genuinely unguarded
cost is **step 2.5** — no `dedup_groups.json` is checked in at all, so omitting `--tool` there
means roughly **2233 paid LLM calls**, an exposure named in neither the comment nor the setup
doc. r1 and r3 rated the same discrepancy as imprecision rather than a wrong mechanism.

The operational conclusion the comment draws (`--tool` is required on all three steps) is
correct and Verified by all three replicates; only its stated numbers and causal path are off.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:268-271`; `docs/working/crb-direction1-setup.md:143-147`; vendored `step2_extract_comments`, `step2_5_dedup_candidates`, `step3_judge_comments`

---

## Claim 7: "Artifacts are harvested and the tree reset below, so re-runs start from the same state"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:150-153`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Legibility-target:** for-author

```bash
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```

`git clean -qfd` without `-x` leaves **gitignored** files behind, so anything a review writes
into an ignored path persists into the next instance — and r3 notes the harvest step misses
them too, since it filters `git status --porcelain` output. r2 adds that `git checkout -- .`
restores from the *index*, so a `git add` performed by the review persists. Suggested fix:
`git reset --hard && git clean -qfdx`, or soften the comment.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:150-153`, `:193-201`

---

## Claim 8: "The benchmark's 49 tools post a median of 4 findings per PR"

**Location:** `scripts/crb-pipeline-to-benchmark.py:177-178` (and `docs/working/crb-direction1-setup.md:114-116`)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Legibility-target:** for-author

The median over all 2449 (PR, tool) pairs is **3** (r3: mean 3.91). It is 4 only when pairs
that posted nothing are excluded. The companion `~16` figure for an E8 rubric is exact and
Verified (r3 parsed the `mfc-csp` fixture to exactly 16 findings, 9 under
`--sections fix address`). State which denominator the median uses — the whole point of the
comment is a precision comparison, so the excluded-silent-reviews reading needs to be explicit.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:177-180`; `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 9: "Rubric section headers we treat as findings. 'Confirmed Good' and 'Considered Overrides' are deliberately absent."

**Location:** `scripts/crb-pipeline-to-benchmark.py:58-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Legibility-target:** for-author

The `✅ Confirmed Good` half is solid. The `↩️ Considered Overrides` half is true by accident:
the section filter is a substring test,

```python
if not any(s.lower() in section.lower() for s in sections):
```

and `"consider"` **is** a substring of `"↩️ considered overrides"`, so that section *passes*
the filter. It emits nothing only because the rubric template names its column
`Prior finding` rather than `Finding`, and `comments_from_rubric` skips tables with no
`finding` header. r3 confirmed the sensitivity by running the parser both ways.

Consequence: a one-word column rename in `skills/code-review/SKILL.md`, or `--sections consider`
alone, would silently start injecting inherited override rows as findings and inflate the
false-positive denominator. Anchor the section match rather than relying on a column name.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:58-60`, `:97-110`; `skills/code-review/SKILL.md` (Considered Overrides table)

---

## Claim 10: "`--all-prs` … full 50-PR leaderboard"

**Location:** `scripts/crb-subset-leaderboard.py:16`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Legibility-target:** for-author

`--all-prs` ranks over every PR **in the evaluations file** (`urls = sorted(evals)`), which is
50 only on the seeded default path. r3 notes that under `--no-seed` it silently reduces to our
own PRs — the opposite of what the flag name promises. r2 flags two more issues in the same
docstring block: the `--tool mfc-pipeline-main` usage example names a tool nothing in this
commit produces, and `DEFAULT_EVALS` hard-codes a judge directory the injector's `--judge` flag
lets you change.

**Evidence:** `scripts/crb-subset-leaderboard.py:13-18`, `:26-27`, `:49-52`

---

## Claim 11: "the dataset splits a few projects across mirror repos (discourse-graphite, sentry-greptile, keycloak-greptile)"

**Location:** `scripts/crb-materialize.py:93-98`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Legibility-target:** for-author

The docstring's operative conclusion — `--per-repo 1` yields 5 PRs, not 7 — is exactly right
and independently Verified by all three replicates against the dataset. The supporting example
is not: `discourse-graphite` is the **only** name discourse appears under, so it is not a
mirror split. Only keycloak and sentry are genuinely split. Drop `discourse-graphite` from the
list.

**Evidence:** `scripts/crb-materialize.py:93-98`; `external/code-review-benchmark/offline/results/benchmark_data.json` (`source_repo` values)

---

## Claim 12: "--per-repo N: the N PRs with the most golden comments in each source repo"

**Location:** `scripts/crb-materialize.py:111-113`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Legibility-target:** for-author

The grouping key is `family(source_repo)`, not `source_repo`:

```python
        by_repo.setdefault(family(p[2]["source_repo"]), []).append(p)
```

The distinction is not cosmetic — it is exactly what makes the selection 5 PRs rather than 7,
which the adjacent `family()` docstring explains. Word it "each source project". The
tie-break-on-slug half of the comment is Verified.

**Evidence:** `scripts/crb-materialize.py:111-122`

---

## Claim 13: "Writes/updates runs/review-arms/crb/instances.json: slug -> {url, fork, head, base, n_goldens, files_changed, insertions, deletions, clone_mb}"

**Location:** `scripts/crb-materialize.py:29-31`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=—
**Legibility-target:** for-author

The record actually written carries 14 keys; the docstring lists 9. Omitted: `source_repo`,
`pr_title`, `fork_url`, `commits`, `depth`. r1 notes `commits` is not idle — it feeds the
pilot table in `docs/working/crb-direction1-setup.md:42-46`. The manifest file on disk is
consistent with the writer (Verified by all three); only the docstring's enumeration is short.

**Evidence:** `scripts/crb-materialize.py:29-31`, `:210-216`; `runs/review-arms/crb/instances.json`

---

## Claim 14: "Guard (b): the range is non-empty and its blobs are present locally (a partial/broken clone shows up here rather than mid-review)"

**Location:** `scripts/crb-materialize.py:191-193`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=—
**Legibility-target:** for-author

Two qualifications, one from each reporting replicate. r1: no condition in the guard checks
blob presence — a partial clone surfaces as a raw `git diff` failure through `sh()`'s
`check=True`, i.e. as an opaque RuntimeError rather than the guard's own diagnostic. r2: the
`git diff --shortstat main review` only exercises blobs the **diff touches**; blobs for
unchanged files are never read, so a clone missing those still passes.

The guard does achieve its practical purpose (a broken clone fails here rather than mid-review);
the mechanism is narrower than the comment claims.

**Evidence:** `scripts/crb-materialize.py:191-196`, `:59-66`

---

## Claim 15: "Docker creates a fresh named volume root-owned, but the review container runs as uid 1000 (-u node)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:97-99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Low
**Replicate verdicts:** r1=Mostly accurate · r2=Unverifiable · r3=— · (disagreement)
**Legibility-target:** for-author

r1: a *fresh* named volume inherits the ownership of the image path it is populated from
(`node`), not root; the chown is what guards a volume previously touched by a root container —
which is a real scenario here, since the chown step itself runs rootful. r1 also notes `-u node`
selects a username, not a uid, so "uid 1000" is incidental. r2 declined to verdict it without a
Docker daemon to test against. Most-severe-wins takes `Mostly accurate`.

The chown line is harmless and defensible either way; only its stated rationale is off.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:97-101`

---

## Claim 16: "MODEL=opus is ~1/2 the per-token price"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:57-59`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=— · (disagreement)
**Legibility-target:** for-author

r1 verified the ratio as exact against the repo's recorded figures ($10/$50 per MTok for
Fable 5 vs $5/$25 for Opus). r2 accepts the ratio but flags two qualifiers: `opus` is a
floating alias (so the pinned-reproducibility posture of the adjacent `CC_VERSION` line does
not extend to it), and "cheaper sweep" conflates per-token price with per-instance cost — a
model that takes more turns can cost more at half the token price. Most-severe-wins takes
`Mostly accurate`.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:57-60`

---

## Claim 17: "2026-08-18: steps 1 and 3 below are built and dry-run green"

**Location:** `docs/working/crb-arm-plan.md:193`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Legibility-target:** for-author

Four stages shipped in this commit, not two — and the numbering collides with the setup doc's
own four-stage table, where stage 2 is the run and stage 4 is judge+rank. Stage 2 is built but
its key assumption is explicitly unverified. r3 suggests: "stages 1, 3 and 4 built; stage 2
built but unrun".

**Evidence:** `docs/working/crb-arm-plan.md:193-199`; `docs/working/crb-direction1-setup.md:15-20`

---

## Claim 18: "Every tool's fork of the same original PR carries the same code (they differ only in which bot reviewed it), so one fork per PR suffices"

**Location:** `scripts/crb-materialize.py:7-8`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** —
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=Unverifiable
**Legibility-target:** for-orchestrator-synthesis

Settling this requires cloning ≥2 tools' forks of one PR and diffing `refs/pull/1/head`;
nothing in the repo can establish it. r1 adds partial corroboration and a partial concern: the
forks agree on the PR stem but were cut across **27 different dates**, though exposure is low
today because all 50 `claude-code` forks share the single `20260310` cut.

Both reporting replicates escalate this as **the experiment's single unverified structural
premise** — the entire one-fork-per-PR design rests on it — and both note it is cheap to close
with a one-off two-clone spot check before any sweep.

**Evidence:** `scripts/crb-materialize.py:4-8`, `:52-56`

---

## Claim 19: "~1 order of magnitude smaller on disk than a full clone of grafana/keycloak"

**Location:** `scripts/crb-materialize.py:19-20`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** —
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=Unverifiable
**Legibility-target:** for-orchestrator-synthesis

The shallow sizes are measured (125 MB grafana, 127 MB keycloak in the manifest), but no
full-clone size exists anywhere in the repo to compare against; confirming needs a network
clone.

**Evidence:** `scripts/crb-materialize.py:18-20`; `runs/review-arms/crb/instances.json`

---

## Claim 20: "CC_VERSION 2.1.232 — pin for reproducibility"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:55`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** —
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=—
**Legibility-target:** for-orchestrator-synthesis

Both replicates corroborate 2.1.232 as a real, previously-run version from an E7 transcript in
this repo. Whether it still resolves on the npm registry needs network access the review
environment does not have — and `npx -y @anthropic-ai/claude-code@"$CC_VERSION"` resolving is a
precondition for every instance in a sweep.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:55`, `:114`, `:161`

---

## Claim 21: "Judge (our tool only, opus-4-5) — ~$13–22 for 50 PRs, ~$1.5 for a 5-PR pilot"

**Location:** `docs/working/crb-direction1-setup.md:159`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** —
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=—
**Legibility-target:** for-orchestrator-synthesis

The derivation shown (173 goldens × ~12–20 candidates/PR ≈ 2.1k–3.5k short judge calls at
$5/$25 per MTok) is internally coherent, but confirming it needs a real judge run's billed
usage or live pricing. The doc already labels the whole judge path unverified.

**Evidence:** `docs/working/crb-direction1-setup.md:152-164`, `:197-203`

---

## Claim 22: "`offline/analysis/score_profiles.py` implements Strict/Core/All profiles by golden category"

**Location:** `docs/working/crb-direction1-setup.md:180-182`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** —
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Legibility-target:** for-orchestrator-synthesis

The file exists; r3 confirmed the claim only at the filename level and did not trace the
profile mechanism itself.

**Evidence:** `docs/working/crb-direction1-setup.md:180-182`; `external/code-review-benchmark/offline/analysis/score_profiles.py`

---

## Claim 23: "'✅ Confirmed Good' rows are never emitted"

**Location:** `scripts/crb-pipeline-to-benchmark.py:22-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate
**Legibility-target:** for-author

The exclusion itself is solid and Verified — `"✅ confirmed good"` matches none of
`("must fix", "must address", "consider")`. Recorded here as `Mostly accurate` only because r3
grouped it with the `Considered Overrides` defect (Claim 9), where the same substring
mechanism does not hold. No action needed on this half beyond the Claim 9 fix.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:22-26`, `:58-60`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/working/crb-direction1-setup.md:172-176`): golden-denominator caveat understated ~12× — 24 of 50 PRs disagree, not 2, and "11 vs 13" is impossible (max is 9). Unanimous; fix before any results doc quotes a recall number.
- **Claim 2** (`scripts/crb-materialize.py:26`): `--all` disk estimate `~15-25GB` contradicts the measured ~6.7 GB and the setup doc's `~6-7 GB` in the same commit.
- **Claim 3** (`scripts/crb-pipeline-to-benchmark.py:13-15`): "step 3's aggregate table is a real leaderboard" is contradicted by `crb-subset-leaderboard.py:4-8` in the same commit. Plus an unflagged dedup asymmetry favouring our arm.
- **Claim 4** (`runs/review-arms/crb-pipeline/run-host.sh:104-105`, `:126`): preflight's `"log in"` test does not match the documented `"Not logged in"`; E7's second `"logged in"` clause was dropped. The only *code* defect in this report.
- **Claim 5** (`docs/working/crb-direction1-setup.md:117-120`): "same judge pass" is contradicted by the doc's own separate `--out` example — separate work dir means separate judge invocation.
- **Claim 6** (`scripts/crb-pipeline-to-benchmark.py:268-271`): count is 50 not ~52, and the re-judge risk flows through step 2 → step 2.5, not step 3 directly.

### Stale
- None (Claim 2 was rated Stale by r1; Incorrect wins under most-severe-wins).

### Mostly Accurate
- **Claim 7** (`run-host.sh:150-153`): `git clean -qfd` lacks `-x`; gitignored artifacts leak across instances and escape the harvest.
- **Claim 8** (`crb-pipeline-to-benchmark.py:177-178`): median is 3 over all pairs, 4 only excluding silent reviews — state the denominator.
- **Claim 9** (`crb-pipeline-to-benchmark.py:58-60`): `Considered Overrides` passes the substring filter; exclusion rests on a column name. Latent FP-injection path.
- **Claim 10** (`crb-subset-leaderboard.py:16`): `--all-prs` is file-scoped, not "the full 50"; plus a usage example naming a nonexistent tool.
- **Claim 11** (`crb-materialize.py:93-98`): `discourse-graphite` is not a mirror split; the 5-not-7 conclusion is right.
- **Claim 12** (`crb-materialize.py:111-113`): grouping is per family/project, not per source repo.
- **Claim 13** (`crb-materialize.py:29-31`): manifest docstring lists 9 of 14 written keys.
- **Claim 14** (`crb-materialize.py:191-193`): guard (b) does not check blob presence, and covers only diff-touched blobs.
- **Claim 15** (`run-host.sh:97-99`): fresh named volumes inherit image-path ownership, not root.
- **Claim 16** (`run-host.sh:57-59`): price ratio right; `opus` is a floating alias and per-token ≠ per-instance cost.
- **Claim 17** (`crb-arm-plan.md:193`): "steps 1 and 3" — four stages shipped; numbering collides with the setup doc's table.
- **Claim 23** (`crb-pipeline-to-benchmark.py:22-26`): Confirmed-Good exclusion is sound; see Claim 9 for the adjacent defect.

### Unverifiable
- **Claim 18** (`crb-materialize.py:7-8`): fork-equality premise — the experiment's single unverified structural assumption. Close it with a two-clone diff of one PR's `refs/pull/1/head` before any sweep.
- **Claim 19** (`crb-materialize.py:19-20`): order-of-magnitude disk claim needs a full clone to measure.
- **Claim 20** (`run-host.sh:55`): whether `@anthropic-ai/claude-code@2.1.232` still resolves on npm needs network.
- **Claim 21** (`crb-direction1-setup.md:159`): judge-cost figures need a real billed run.
- **Claim 22** (`crb-direction1-setup.md:180-182`): `score_profiles.py` confirmed at filename level only.

---

## Verdict stability

Scope of this measurement: the **22 merged clusters** on which at least one replicate returned
a non-Verified verdict (Claim 23 is folded into Claim 9's cluster for this count). Clusters on
which all three replicates independently returned Verified are not enumerated per-claim above
and are excluded from the rate.

- **Total clusters:** 22
- **Multi-replicate clusters:** 19
- **Agreed (all reporting replicates same verdict):** 13
- **Disagreed:** 6
- **Single-replicate detections:** 3 (Claims 5, 17, 22)
- **Agreement rate:** 13/19 = **68%**

Disagreements, with per-replicate verdicts:

| Cluster | r1 | r2 | r3 | Merged |
|---|---|---|---|---|
| Claim 2 — `--all` disk estimate | Stale | Incorrect | Incorrect | Incorrect |
| Claim 3 — "real leaderboard" | Incorrect | Mostly accurate | — | Incorrect |
| Claim 4 — preflight auth string | Mostly accurate | Incorrect | Mostly accurate | Incorrect |
| Claim 6 — "~52 pairs" | Mostly accurate | Incorrect | Mostly accurate | Incorrect |
| Claim 15 — docker volume ownership | Mostly accurate | Unverifiable | — | Mostly accurate |
| Claim 16 — opus price ratio | Verified | Mostly accurate | — | Mostly accurate |

**68% is well below the ≥90%-on-≥20-claims threshold that would justify dropping to k=2**
(SKILL.md Stage 1, merge step 4). k=3 stays. Note the shape of the disagreement: four of the
six splits are a single replicate calling `Incorrect` where the others called `Mostly accurate`
or `Stale` — the under-calling failure mode most-severe-wins exists to correct, and in three of
those four the escalating replicate was r2. Three of the six merged `Incorrect` verdicts rest
on a single replicate's judgment; only Claim 1 is unanimous.

Cross-replicate recall was strong on the measurement-critical items: all three independently
reached the golden-denominator error (Claim 1), the `Considered Overrides` substring defect
(Claim 9), the preflight string mismatch (Claim 4), and the `clean -fd`/`-x` gap (Claim 7) —
none of which are visible from the changed files alone.

---

## Repo-state incident (out of band — not a documentation finding)

Recorded here because two replicates independently escalated it and it affects the provenance
of this report.

**Root cause (confirmed, self-reported by replicate r2).** While building a throwaway git
fixture to verify the answer-key scrub claims (Claim 18's neighbourhood), r2 ran a multi-line
block whose leading `cd $TMPDIR/gt` failed because `TMPDIR` was unset. The three following
lines were **unconditional** rather than `&&`-chained to the `cd`, so they executed against the
session's working directory, `/workspace`, instead of the fixture: a
`for-each-ref | update-ref -d` sweep, then `git reflog expire --expire=now --all`, then
`git gc --prune=now`. That is the same four-step shape as the scrub at
`scripts/crb-materialize.py:176-184`, which is why the signature matched — but the harness
under review did not run and is not at fault. This was tooling used to *check* the code, not
the code itself.

**What was lost:** the commit object `90de392` and its authored metadata; the branch refs
`feat/crb-direction1-harness` and `feat/critic-evidence-discipline`; the six
`.claude/worktrees/` branch tips; all tags; all remote-tracking refs and the `origin` URL; all
reflogs. `git fsck` reports **zero** dangling commits, so reflog- and fsck-based recovery are
both unavailable.

**What survived:** `main`, intact at `5226555` with 1236 commits. The reviewed content, intact
in the index and working tree. Every worktree's files, intact on disk under
`.claude/worktrees/`.

**Recovery applied by this run.**

1. `refs/heads/feat/crb-direction1-harness` re-pointed at `5226555` and the intact index
   committed with the message recovered from `.git/COMMIT_EDITMSG`, producing **`529ecd2`** —
   same parent, same tree, same message as `90de392`, new SHA (the original author timestamp is
   not recoverable). `git diff main...HEAD` again yields the identical
   `7 files changed, 1209 insertions(+)`.
2. `refs/heads/feat/critic-evidence-discipline` restored to `2934c51`. This one was fully
   recoverable because it had been merged into `main` at `d9234c9`, so its tip was still
   reachable and had never been pruned.
3. A bundle of `main` + both restored branches written to the job scratch directory as
   insurance. r2 independently left a whole-tree tarball at
   `/home/node/.claude/tmp-fc/workspace-worktree-backup.tgz` (31 MB).

**Not recovered — needs a user decision.** The six worktree branch tips
(`worktree-python-toolchain-uv`, `worktree-ledger-cubic-column`, `worktree-archive-stale-docs`,
`worktree-fact-check-codereview-writeup`, `worktree-e7-rep23-ledger`,
`exp/cross-model-openrouter-sweep`) are gone as commits and are not reachable from `main`.
Their **working-tree contents are intact on disk**, so each can be reconstructed as a fresh
commit if the work still matters — but that is a judgment call about six separate lines of
work, not a mechanical restore, and it is outside this review's remit.

All three replicates checked the content of `90de392` before or during the loss, verified via
`git diff --cached main`, which was byte-identical to the recovered tree. Their verdicts are
unaffected.

---

## Goal-Alignment Note
- Answered: yes — 23 merged clusters from 131 raw replicate claims, k=3, most-severe-wins.
- Out of scope: code quality, security, performance and shell robustness (Stage 2 critics own those); recovery of the six lost worktree branches.
- Escalate: (1) the repo-state incident and the six unrecovered worktree branches — needs a user decision; (2) Claim 1's denominator error before any results doc quotes recall; (3) Claim 18's fork-equality premise — a cheap two-clone spot check before any paid sweep.
