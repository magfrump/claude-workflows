# Code Fact-Check Report

**Repository:** `/workspace` (claude-workflows)
**Commit:** 90de392
**Scope:** branch diff `feat/crb-direction1-harness` vs `main` — 7 files, +1209/-0
**Checked:** 2026-08-18
**Total claims checked:** 46
**Summary:** 28 verified, 12 mostly accurate, 1 stale, 2 incorrect, 3 unverifiable

> **Repo-state incident, discovered mid-run — escalate before merging.** Partway through
> this pass, `/workspace` lost every local branch ref except `main`, every remote-tracking
> ref, the `origin` remote from `.git/config`, and all reflogs; `git gc --prune=now` then
> pruned the now-unreachable commit **90de392 itself** (`git cat-file -t 90de392` →
> `fatal: Not a valid object name`). The scope command in my brief
> (`git diff main...HEAD`) succeeded on my first tool call and fails now. See the
> **Repo-state incident** section at the end for evidence, blast radius, and a
> non-destructive recovery recipe. **The reviewed content is not lost** — the index and
> working tree still hold it, and `git diff --cached --stat main` reproduces the exact
> `7 files changed, 1209 insertions(+)` diff, so every claim below was checked against
> byte-identical content.

---

## Claim 1: "steps 1 and 3 below are built and dry-run green … Judge cost is bounded by seeding the checked-in opus-4-5 results and passing `--tool`, so only our arm is judged (~$1.5 for a 5-PR pilot, ~$13–22 for all 50)"

**Location:** `docs/working/crb-arm-plan.md:193-201`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The confinement mechanism is real on both paid steps. Step 2 skips any `(PR, tool)` pair
already in the seeded candidates file:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:196-198
            # Skip if already has candidates for this (golden_url, tool)
            if golden_url in all_candidates and tool in all_candidates[golden_url]:
                continue
```

and step 3 skips any pair already in the seeded evaluations file:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:487-489
            if not args.force and state.is_done(golden_url, tool):
                skipped += 1
```

The seeding itself is implemented at `scripts/crb-pipeline-to-benchmark.py:254-263`. The
dollar figures are forward-looking estimates and are not independently checkable here; the
`~$13–22` matches the cost table at `docs/working/crb-direction1-setup.md:159`.

**Evidence:** `docs/working/crb-arm-plan.md:193-201`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:196-198`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:487-489`, `scripts/crb-pipeline-to-benchmark.py:254-263`

---

## Claim 2: "`scripts/crb-materialize.py --list # 50 PRs, 173 goldens`"

**Location:** `docs/working/crb-direction1-setup.md:25`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Executing `load_prs()` from the script against the vendored dataset returns exactly 50 PRs;
summing `len(entry["golden_comments"])` over the dataset returns 173 (paraphrased — no quote
available because the figure is the result of running the script's own loader over a 5 MB
generated JSON data file, not a snippet in either file).

**Evidence:** `scripts/crb-materialize.py:77-90`, `scripts/crb-materialize.py:234-240`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 3: "`scripts/crb-materialize.py --all # all 50 (~6-7 GB)`"

**Location:** `docs/working/crb-direction1-setup.md:27`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Consistent with the measured pilot: the five `clone_mb` values in the manifest are 190, 33,
125, 127, 195 (`runs/review-arms/crb/instances.json:5,20,36,52,68`), averaging ~134 MB, so
50 clones project to ~6.7 GB. Medium confidence only because the pilot is a
most-goldens-first selection, not a random sample of clone sizes. **Note the conflict:** the
same commit's script docstring says `~15-25GB` for the same command — see Claim 26.

**Evidence:** `docs/working/crb-direction1-setup.md:27`, `runs/review-arms/crb/instances.json:5,20,36,52,68`, `scripts/crb-materialize.py:26`

---

## Claim 4: Pilot table — per-slug goldens / commits / diff / disk, and "33 goldens over 5 PRs"

**Location:** `docs/working/crb-direction1-setup.md:40-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every cell matches the manifest. E.g. the keycloak row's "1 file +3/-3, 127 MB":

```json
// runs/review-arms/crb/instances.json:51-56
    "clone_mb": 127,
    "commits": 1,
    "deletions": 3,
    "depth": 50,
    "files_changed": 1,
```

The four other rows check out identically against
`runs/review-arms/crb/instances.json:2-17,18-33,34-49,66-81` (paraphrased — no quote
available because reproducing all five records verbatim would duplicate most of the
82-line manifest). Running the script's `select()` with `--per-repo 1` reproduces exactly
these five slugs and sums to 33 goldens.

**Evidence:** `docs/working/crb-direction1-setup.md:40-51`, `runs/review-arms/crb/instances.json:1-82`, `scripts/crb-materialize.py:101-122`

---

## Claim 5: "a bad credential returns exit 0 with `\"Not logged in\"` (E7)"

**Location:** `docs/working/crb-direction1-setup.md:76`, duplicated at `runs/review-arms/crb-pipeline/run-host.sh:104-105`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The referenced E7 observation exists and is more specific than the restatement:

```bash
# runs/review-arms/e7-fable-3x/run-host.sh:88-89
# result "Not logged in · Please run /login" and num_turns=0 (learned the hard
```

The imprecision is in the *detector*, not the description. E7's own preflight guarded on
both spellings:

```python
# runs/review-arms/e7-fable-3x/run-host.sh:103
sys.exit(0 if d.get("num_turns", 0) > 0 and "log in" not in r.lower() and "logged in" not in r.lower() else 1)
```

The new preflight kept only the first:

```python
# runs/review-arms/crb-pipeline/run-host.sh:126-127
if d.get("num_turns", 0) < 1 or "log in" in r.lower():
    sys.exit(f"  auth failed: {r[:200]!r}")
```

`"log in"` is not a substring of `"not logged in · please run /login"` — neither `"logged
in"` nor `"/login"` contains `log`+space+`in`. The case is still caught, but solely by the
`num_turns < 1` arm (E7 records `num_turns=0` for it), not by the string test the comment
foregrounds. Tighten by restoring E7's `"logged in"` clause.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:104-105,126-127`, `runs/review-arms/e7-fable-3x/run-host.sh:88-89,103`, `docs/working/crb-direction1-setup.md:76`

---

## Claim 6: "**The E8 payload is `main`.** `feat/critic-evidence-discipline` was merged at `d9234c9`, and `git diff main feat/critic-evidence-discipline -- skills workflows CLAUDE.md` is empty as of 2026-08-18"

**Location:** `docs/working/crb-direction1-setup.md:68-72`, duplicated at `runs/review-arms/crb-pipeline/run-host.sh:19-25` and in the commit message
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three sub-claims hold (paraphrased — no quote available because these are git-history
facts, not file contents): `d9234c9` is a real commit titled
`merge: E8 evidence-discipline pipeline + ledger updates into main`; `git branch --merged
main` lists `feat/critic-evidence-discipline`; and the named three-path diff produces zero
output. Checked before the ref loss described in the incident section — `d9234c9` and
`main`'s 1236-commit history both survive it.

**Evidence:** `docs/working/crb-direction1-setup.md:68-72`, `runs/review-arms/crb-pipeline/run-host.sh:19-25`, git history at `d9234c9`

---

## Claim 7: "The clone is reset with `git checkout -- . && git clean -fd` after harvesting, so re-runs start from the same state."

**Location:** `docs/working/crb-direction1-setup.md:85-86`, duplicated at `runs/review-arms/crb-pipeline/run-host.sh:150-153`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The reset runs as described:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:200-201
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```

`checkout -- .` restores tracked modifications and `clean -fd` removes untracked files and
directories, so the *tracked* tree does return to its prior state. The unqualified "the same
state" overstates two gaps: (a) `git clean` without `-x` leaves files matching the upstream
repo's `.gitignore` in place — cal.com, grafana, keycloak and sentry all ship `.gitignore`
files, so anything the pipeline writes into an ignored path (build output, `node_modules`,
`.env`-shaped files, a `docs/`-adjacent ignored dir) persists into the next run; and (b) the
harvest that precedes it also only sees `git status` output, so ignored artifacts are neither
collected nor cleared. Precise version: "the tracked tree is reset; ignored paths are not."

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:193-201`, `docs/working/crb-direction1-setup.md:85-86`

---

## Claim 8: "the 49 benchmark tools post a median of **4** findings per PR; an E8 rubric carries ~**16** (1 red + 8 amber + 7 green on `mfc-csp`)"

**Location:** `docs/working/crb-direction1-setup.md:114-116`, duplicated at `scripts/crb-pipeline-to-benchmark.py:177-178` and in the commit message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The `~16` half is exact. Running the injector's own parser over the referenced fixture yields
16 findings across three sections with counts 1 / 8 / 7 (paraphrased — no quote available
because the figure is the return value of executing `comments_from_rubric` against
`runs/review-arms/e8-evidence-pipeline/mfc-csp/code-review-rubric.md`, not a literal in
either file).

The `median of 4` half depends on an unstated denominator. Over all 2 449 `(PR, tool)` pairs
in `benchmark_data.json` the median is **3** (mean 3.91); the median is 4.0 only if the 167
pairs whose review carries no comments are excluded. Since precision/recall for those empty
rows is exactly what the surrounding argument is about, the inclusive figure (3) is the
defensible one. Median-of-per-tool-medians is also 3. State it as "median 3 (4 among
non-empty reviews)".

**Evidence:** `docs/working/crb-direction1-setup.md:114-116`, `scripts/crb-pipeline-to-benchmark.py:177-180`, `external/code-review-benchmark/offline/results/benchmark_data.json`, `runs/review-arms/e8-evidence-pipeline/mfc-csp/code-review-rubric.md`

---

## Claim 9: "The results dir the run writes is named after the id verbatim (`claude-opus-4-5-20251101`), which is why the injector seeds *that* directory."

**Location:** `docs/working/crb-direction1-setup.md:137-142`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The vendored steps derive the directory from `MARTIAN_MODEL` with only slashes replaced:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:60-68
def sanitize_model_name(model: str) -> str:
    """Sanitize model name for use as directory name."""
    return model.strip().replace("/", "_")

def get_model_dir() -> Path:
    """Get the model-specific results directory, creating it if needed."""
    model = os.environ.get("MARTIAN_MODEL", "openai/gpt-4o-mini")
    model_dir = RESULTS_DIR / sanitize_model_name(model)
```

`MARTIAN_MODEL=claude-opus-4-5-20251101` (no slash) therefore yields
`results/claude-opus-4-5-20251101/`, which is exactly what the injector creates and what the
leaderboard's default path expects:

```python
# scripts/crb-pipeline-to-benchmark.py:249-253
    jdir = out / "results" / sanitize_model(args.judge)
    jdir.mkdir(parents=True, exist_ok=True)
    src = BENCH / "results" / sanitize_model(f"anthropic/{args.judge}")
```

The checked-in source directory `results/anthropic_claude-opus-4-5-20251101/` exists on disk,
so the `f"anthropic/{args.judge}"` first-try lookup resolves. The chain jdir → RUN.md →
`crb-subset-leaderboard.py:26-27` all use the same unprefixed name. Answers task item 17
affirmatively.

**Evidence:** `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:60-68`, `scripts/crb-pipeline-to-benchmark.py:249-253,292`, `scripts/crb-subset-leaderboard.py:26-27`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/`

---

## Claim 10: "**Non-uniform golden denominators** — on the same 2 PRs, different tools' checked-in rows show `total_golden` 11 vs 13"

**Location:** `docs/working/crb-direction1-setup.md:172-176`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The phenomenon is real but both numbers in the claim are wrong, in the direction that
*understates* the problem. Across the checked-in
`anthropic_claude-opus-4-5-20251101/evaluations.json`, **24 of 50 PRs** — not 2 — carry more
than one distinct `total_golden` value among their non-skipped tool rows. The observed
value-pairs are `(2,3)×7, (4,5)×2, (1,2)×2, (3,5)×2, (2,4)×2, (3,6)×2, (3,4)×2, (5,6)×2,
(4,7), (6,8), (5,9)`. The specific pair `11 vs 13` cannot occur anywhere in the file: the
maximum `total_golden` over all 2 449 rows is **9**. The other two checked-in judge
directories (`anthropic_claude-sonnet-4-5-20250929`, `openai_gpt-5.2`) show the identical
24-PR pattern. (Paraphrased — no quote available because these are aggregate statistics over
a 7.6 MB generated JSON file with no single citable line.)

The mitigation sentence that follows is accurate: the leaderboard does print each tool's
gold total (`scripts/crb-subset-leaderboard.py:84-85,93-94`). Fix the caveat to read "on 24
of 50 PRs, tools' rows disagree on `total_golden` by 1–4 goldens."

**Evidence:** `docs/working/crb-direction1-setup.md:172-176`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`, `scripts/crb-subset-leaderboard.py:84-85`

---

## Claim 11: "`offline/analysis/score_profiles.py` implements Strict/Core/All profiles by golden category."

**Location:** `docs/working/crb-direction1-setup.md:180-181`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The file exists and defines exactly those three profiles keyed by golden category:

```python
# external/code-review-benchmark/offline/analysis/score_profiles.py:19-25
PROFILE_CATEGORIES: dict[str, frozenset[str]] = {
    "strict": frozenset({"bug", "security", "concurrency", "data", "api"}),
    "core": frozenset({"bug", "security", "concurrency", "data", "api", "perf", "test_gap", "doc_defect"}),
    "all": frozenset({
        "bug", "security", "concurrency", "data", "api",
        "perf", "test_gap", "doc_defect", "style", "speculative",
    }),
}
```

Golden comments do carry a `category` field, so the profiles are applicable to this dataset.

**Evidence:** `docs/working/crb-direction1-setup.md:180-182`, `external/code-review-benchmark/offline/analysis/score_profiles.py:19-25,160`

---

## Claim 12: "**Verified in this session ($0):** … the injector against a real E8 rubric fixture (16 findings parsed from `mfc-csp`, 9 with `--sections fix address`) … `run-host.sh` passes `bash -n` and its `DRY_RUN=1` path builds and validates the payload (25 skills, `code-review` present)."

**Location:** `docs/working/crb-direction1-setup.md:188-195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-ran each checkable half. `comments_from_rubric` on the `mfc-csp` rubric returns 16
comments with the default sections and 9 with `["Must Fix", "Must Address"]`. `bash -n
runs/review-arms/crb-pipeline/run-host.sh` exits 0. `git ls-tree -r --name-only main skills |
grep 'SKILL.md$' | wc -l` returns 25, matching the payload counter at line 88 and the
`code-review` assertion at lines 89-90 (paraphrased — no quote available because all four are
command results rather than file contents).

**Evidence:** `docs/working/crb-direction1-setup.md:188-195`, `scripts/crb-pipeline-to-benchmark.py:97-129`, `runs/review-arms/crb-pipeline/run-host.sh:85-90`

---

## Claim 13: "docker cannot run inside a session; same constraint as E5/E7/cc-isolated."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:3-4`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The prior arm states the same constraint in the same words:

```bash
# runs/review-arms/e7-fable-3x/run-host.sh:4-5
# ── RUN FROM THE HOST (WSL terminal), never from inside a Claude session ──
# (docker cannot run inside a session; same constraint as E5/cc-isolated.)
```

The cc-isolated / devcontainer half is corroborated by
`docs/decisions/015-cc-process-isolation-docker-devcontainer.md`, which records the Docker
Desktop WSL-integration host setup as a prerequisite outside the agent's boundary.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:3-4`, `runs/review-arms/e7-fable-3x/run-host.sh:4-5`, `docs/decisions/015-cc-process-isolation-docker-devcontainer.md:4,45-48`

---

## Claim 14: "87% recall / 0 FPs on the canon, `docs/working/e8-results-2026-08-18.md`"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:19-21`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cited doc's results table carries both figures:

```markdown
<!-- docs/working/e8-results-2026-08-18.md:18 -->
| **E8 evidence-discipline pipeline** | 54 | 47 | **87%** | **0** | **0 clean** (1 over-broad, scoped-true) |
```

47/54 = 87%. The "0 FPs" column is `Confirmed FPs`, and the doc's own qualifier — "E8's 0 FPs
are measured; the historical pipeline's precision is unmeasurable retrospectively"
(`docs/working/e8-results-2026-08-18.md:118-119`) — is not carried into the header, but the
header does not claim a comparison either.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:19-21`, `docs/working/e8-results-2026-08-18.md:16-18,50-52`

---

## Claim 15: "E8 was orchestrated stage-by-stage by a human-driven session (k=2 fact-check, explicit critic list per instance)."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:28-31`, duplicated at `docs/working/crb-direction1-setup.md:89-92`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The E8 results doc records both the orchestration mode and `k=2`:

```markdown
<!-- docs/working/e8-results-2026-08-18.md:7 -->
provenance-ruled rubric synthesis. Orchestrated locally (fable-5), k=2
```

and lists the config deltas explicitly: "**Config deltas vs the historical pipeline**: k=2
not k=3; orchestrator on fable-5" (`docs/working/e8-results-2026-08-18.md:96-97`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:28-31`, `docs/working/e8-results-2026-08-18.md:7,96-97`

---

## Claim 16: "hooks/ and scripts/ are NOT in the payload (they write to host paths and log usage); E5/E7 also ran hookless."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:34-35`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The payload is built from an explicit five-path `git archive` that omits both directories:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:85-86
git -C "$ROOT" archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md \
  | tar -x -C "$PAYLOAD_SRC"
```

Nothing else is copied into `$PAYLOAD_SRC` before the per-instance `cp -r` at line 150, so
`hooks/` and `scripts/` cannot reach the container.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:34-35,83-88,110,150`

---

## Claim 17: "`CC_VERSION=\"${CC_VERSION:-2.1.232}\"   # pin for reproducibility; bump deliberately`"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:55`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Version 2.1.232 is a real published `@anthropic-ai/claude-code` version and was the version
E7 actually ran — an E7 transcript captured a skill payload path stamped with it:

```
# runs/review-arms/e7-fable-3x/mfc-hygiene/rep2/transcript.jsonl:194
"Base directory for this skill: /tmp/claude-1000/bundled-skills/2.1.232/…"
```

E7's own header corroborates ("verified 2026-08-14 that CLI 2.1.232 in `--bare` headless
mode …", `runs/review-arms/e7-fable-3x/run-host.sh:56`). Medium confidence only on whether
the version remains fetchable from npm today, which needs registry access.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:55`, `runs/review-arms/e7-fable-3x/run-host.sh:56`, `runs/review-arms/e7-fable-3x/mfc-hygiene/rep2/transcript.jsonl:194`

---

## Claim 18: "`PAYLOAD_REF=\"${PAYLOAD_REF:-main}\"   # == feat/critic-evidence-discipline (merged, see header)`"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:56`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Equality is asserted only over the payload paths, and that is exactly what the payload uses
(`git archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md`, line 85). The
three-path diff between the two refs is empty — see Claim 6. Two of the five archived paths
(`guides`, `patterns`) are outside the diff the header quotes, so strictly the comment
depends on those also being identical; they are, since the branch is fully merged into main
and main has advanced only by `docs/` commits since `d9234c9`.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:56,85`, git history `main` vs `feat/critic-evidence-discipline`

---

## Claim 19: "E8's canon sweep ran the orchestrator on Fable 5 … MODEL=opus is ~1/2 the per-token price"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:57-59`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

First half: "Orchestrated locally (fable-5)" (`docs/working/e8-results-2026-08-18.md:7`) and
"orchestrator on fable-5" (line 96-97).

Second half: `claude-fable-5` list pricing is $10/M input, $50/M output; the Opus tier
(`claude-opus-5` / `4.8` / `4.7` / `4.6`) is $5/M input, $25/M output — exactly half on both
axes (paraphrased — no quote available because the pricing table lives in the `claude-api`
skill's model reference, not in this repo). The repo corroborates independently: the E8
results doc records "Fable 5 list prices: $10/M input, $50/M output"
(`docs/working/e8-results-2026-08-18.md:111-112`) and the E7 header records
"claude-fable-5 (exact ID; $10/$50 per MTok — 2x Opus)"
(`runs/review-arms/e7-fable-3x/run-host.sh:8`). "~1/2" is if anything conservative — it is
exactly 1/2.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:57-60`, `docs/working/e8-results-2026-08-18.md:7,111-112`, `runs/review-arms/e7-fable-3x/run-host.sh:8`

---

## Claim 20: "`git archive` (not a bind mount of $ROOT) so a running review cannot edit the skills that are reviewing it, and so an unrelated local edit mid-sweep cannot change the arm's condition halfway through."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:79-82`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The payload is extracted once from a committed ref into a tempdir before the loop:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:83-87
PAYLOAD_SRC=$(mktemp -d)
trap 'rm -rf "$PAYLOAD_SRC"' EXIT
git -C "$ROOT" archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md \
  | tar -x -C "$PAYLOAD_SRC"
PAYLOAD_SHA=$(git -C "$ROOT" rev-parse "$PAYLOAD_REF")
```

`git archive <ref>` reads the committed tree, so uncommitted worktree edits are excluded, and
the extraction happens once — outside the `for id in …` loop that starts at line 134 — so
mid-sweep edits to `$ROOT` cannot reach any later instance. Only `$INST_HOME` (a per-instance
`cp -r` of `$PAYLOAD_SRC`, line 150) is ever mounted into a container; `$ROOT` never is.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:83-88,134,150,155-160`

---

## Claim 21: "Docker creates a fresh named volume root-owned, but the review container runs as uid 1000 (`-u node`) — chown it once, as root, before any `-u node` mount."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:97-99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The remediation matches the description exactly — a root container chowns the volume before
any `-u node` use:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:100-101
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm
```

Two imprecisions. (a) Docker does not unconditionally create named volumes root-owned: on
first mount it *seeds* the volume from the image's content at that path, inheriting that
path's ownership; `node:22` ships `/home/node/.npm` owned by `node`, so a genuinely fresh
volume is often already correct — the failure mode this guards is a volume created by an
earlier root-run container, which is a real and recurring case but not "fresh". (b) `-u node`
selects the *user named* `node`, which happens to be uid 1000 in `node:22`; the comment
states the uid as if it were the mechanism. Neither imprecision affects behavior — the chown
is idempotent and harmless. Medium confidence because Docker's volume-seeding semantics are
not observable from this repo.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:97-101,111-116,155-160`

---

## Claim 22: "(b) payload mounted but skills not registered — the run then silently measures Claude Code's built-in review, i.e. the E5 arm under a wrong label. Decision 022 exists because exactly this happened in cc-isolated."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:106-108`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/022-claude-workflows-payload-in-cc-isolated.md` exists and is precisely about
the payload not reaching a containerized Claude Code, including the silent-staleness failure
mode: "frozen at whatever the payload was the day its volume was created, with no signal"
(`docs/decisions/022-claude-workflows-payload-in-cc-isolated.md:55`). The preflight the
comment introduces does test registration by name:

```python
# runs/review-arms/crb-pipeline/run-host.sh:128-130
if "code-review" not in r:
    sys.exit("  payload skills NOT registered — the run would measure the "
             f"built-in reviewer, not the pipeline. Model said: {r[:300]!r}")
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:106-108,111-131`, `docs/decisions/022-claude-workflows-payload-in-cc-isolated.md:1,38,55`

---

## Claim 23: "Completed cells are skipped on re-invocation (`num_turns > 0`), so a sweep resumes."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:138-143`, restated at `docs/working/crb-direction1-setup.md:86-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The guard reads exactly that predicate off the harvested result file:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:138-144
  if [ -s "$dest/result.json" ] && python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if d.get("num_turns", 0) > 0 else 1)' "$dest/result.json" 2>/dev/null; then
    echo "=== $id — completed result exists, skipping (delete to re-run)"
    continue
  fi
```

`result.json` is only written when a `result` event was found in the transcript
(`runs/review-arms/crb-pipeline/run-host.sh:185-191`), so a crashed instance leaves no file
and re-runs. Consistent with the memory note that headless runs are judged by JSON
`num_turns` rather than exit code.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:138-144,185-191`

---

## Claim 24: "Fresh writable payload copy per instance: Claude Code writes settings.json, projects/, todos/ into ~/.claude, and one instance's state must not leak into the next (nor back into the payload source)."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:146-148`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The isolation the comment claims is implemented literally — copy in, mount the copy, delete
the copy:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:150
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:158,170
    -v "$INST_HOME":/home/node/.claude \
  rm -rf "$INST_HOME"
```

`$PAYLOAD_SRC` is never mounted, so no write-back path to the source exists; the same
copy-mount-delete pattern is used for the preflight (lines 110, 117). The `~/.claude`
write-target list (settings.json, projects/, todos/) is Claude Code runtime behavior rather
than a repo fact and is corroborated by decision 022's discussion of the payload volume.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:110,117,146-150,158,170`

---

## Claim 25: `instances.json` field names and content are consistent with what `crb-materialize.py` writes

**Location:** `runs/review-arms/crb/instances.json:1-82`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The manifest record constructed by `materialize()` is:

```python
# scripts/crb-materialize.py:210-216
    return {
        "url": url, "source_repo": entry["source_repo"], "pr_title": entry["pr_title"],
        "fork": fork, "fork_url": remote, "head": head, "base": base,
        "commits": n_commits, "n_goldens": len(entry["golden_comments"]),
        "files_changed": files, "insertions": ins, "deletions": dels,
        "clone_mb": mb, "depth": depth,
    }
```

Each of the five manifest entries carries exactly these fourteen keys and no others, in the
sorted order `json.dumps(..., sort_keys=True)` produces (`scripts/crb-materialize.py:266`).
The consumers agree: `run-host.sh:69-71` reads only the top-level slug keys,
`crb-pipeline-to-benchmark.py:217,229` read `rec["url"]` and `rec["fork"]`. The 5-PR /
33-goldens commit-message claim reproduces from `select()` — see Claim 4.

**Evidence:** `runs/review-arms/crb/instances.json:1-82`, `scripts/crb-materialize.py:210-216,266`, `runs/review-arms/crb-pipeline/run-host.sh:69-71`, `scripts/crb-pipeline-to-benchmark.py:217,229`

---

## Claim 26: "`scripts/crb-materialize.py --all # all 50 (~15-25GB)`"

**Location:** `scripts/crb-materialize.py:26`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

The 15–25 GB figure is inherited verbatim from the pre-pilot estimate in the parent plan:

```markdown
<!-- docs/working/crb-arm-plan.md:204-205 -->
   ~20MB–900MB each; discourse smallest, keycloak/grafana largest — budget
   ~15–25GB disk for all 50, or stream one at a time and delete).
```

The pilot that this same commit materialized measured 33–195 MB per clone
(`runs/review-arms/crb/instances.json`), which projects to ~6.7 GB for 50 — and the setup doc
added in the same commit says `~6-7 GB` (`docs/working/crb-direction1-setup.md:27`). The
estimate was accurate before measurement and is now superseded by it; the two files in this
diff contradict each other by 2–4×. Update line 26 to `~6-7GB`.

**Evidence:** `scripts/crb-materialize.py:26`, `docs/working/crb-direction1-setup.md:27`, `docs/working/crb-arm-plan.md:204-205`, `runs/review-arms/crb/instances.json:5,20,36,52,68`

---

## Claim 27: "Every tool's fork of the same original PR carries the same code (they differ only in which bot reviewed it), so one fork per PR suffices."

**Location:** `scripts/crb-materialize.py:7-8`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Statically confirmable: for all 50 PRs, every recorded fork of that PR agrees on the
`<org>__<repo>__…__PR<n>` stem, differing only in the tool segment and the cut date — so
every fork is a fork of the same upstream PR (paraphrased — no quote available because the
check is an aggregate over 2 449 `repo_name` strings in a generated JSON file). That is
necessary but not sufficient for "carries the same code": the forks were cut on 27 distinct
dates (`20260122` … `20260626`), so two forks of one PR can in principle differ if the
upstream PR branch moved between cuts. Confirming the invariant needs cloning ≥2 forks of the
same PR and diffing `refs/pull/1/head` — network work, out of scope here.

Practical exposure is low: the script pins `DEFAULT_FORK_TOOL = "claude-code"`, and all 50
claude-code forks share the single date `20260310` (Claim 28), so the pilot never mixes cuts.
The invariant only becomes load-bearing if someone changes the fork tool per-PR.

**Evidence:** `scripts/crb-materialize.py:7-8,52-56,84`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 28: "claude-code is present on all 50 and was cut on one date (20260310), so it is the most uniform choice."

**Location:** `scripts/crb-materialize.py:53-55`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both halves hold exactly. Iterating the dataset's `reviews` lists, `claude-code` appears with
a non-null `repo_name` on 50/50 PRs, and the trailing date segment of all 50 of those
`repo_name`s is `20260310` — a single value (paraphrased — no quote available because this is
an aggregate over the generated `benchmark_data.json`, which has no citable line for it). For
comparison, across all tools the dataset spans 27 distinct cut dates, so "most uniform" is
well supported.

One adjacent note, not part of the claim: the fallback `sorted(forks.values())[0]` at
`scripts/crb-materialize.py:84` can select an `mra-*` style `repo_name` (150 such entries
exist, e.g. `mra-claude__keycloak_keycloak_pr37429`), which `slug_for` rejects with
`ValueError` because it splits into fewer than 4 `__`-separated parts. Unreachable today
precisely because the claim above is true.

**Evidence:** `scripts/crb-materialize.py:52-56,69-74,82-88`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 29: "NO other refs and NO origin remote, so a reviewing agent cannot fetch the upstream future (the merged fix — the answer key) via `git log --all`."

**Location:** `scripts/crb-materialize.py:12-14`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The scrub does all four things in the order the claim needs:

```python
# scripts/crb-materialize.py:176-184
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst,
                   capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
```

The ordering matters and is correct: refs are deleted *before* `reflog expire`, and both
precede `gc --prune=now`, so the deleted `refs/remotes/origin/*` (which is where the fork's
default branch — potentially containing the merged fix — lived) becomes unreachable and is
then physically pruned rather than merely unreferenced. Removing the remote also strips the
`[remote "origin"]` URL from `.git/config`, so a re-fetch has no configured target.

Guard (a) then proves the postcondition:

```python
# scripts/crb-materialize.py:186-190
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
```

`git rev-list --all` walks all refs under `refs/` plus `HEAD`; `--not <head>` excludes
`head`'s ancestry, so a non-empty result means something outside the reviewed ancestry is
still reachable. It does *not* detect unreachable-but-present objects — which is exactly why
the `gc --prune=now` on the preceding line is load-bearing, and why the ordering is not
incidental. Scoped to `git log --all` / `git show`, as the claim is, this holds. (A reviewer
who independently knows the upstream URL could still fetch over the network; the claim does
not assert otherwise.)

**Evidence:** `scripts/crb-materialize.py:10-14,175-190`

---

## Claim 30: "This mirrors `scripts/prep-cc-review-clones.sh`, which does the same job for the meta-formalism-copilot canon instances."

**Location:** `scripts/crb-materialize.py:15-16`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The referenced script exists and performs the same operation with the same guard structure:

```bash
# scripts/prep-cc-review-clones.sh:6-17
#   - branch `review` checked out at the instance's reviewed head commit
#   - branch `main` pinned at the instance's context base (so "diff vs main"
#     reproduces the canon range)
#   - NO other refs, NO origin remote, and descendant objects (the later fix
#     commits — the answer key) pruned from the object store, so an agentic
#     reviewer cannot read the future via `git log --all` / `git show`.
```

Its scrub sequence (`scripts/prep-cc-review-clones.sh:41-46`) is the shell equivalent of the
Python block quoted in Claim 29, down to `reflog expire --expire=now --all` then `gc --quiet
--prune=now`, and its guard (a) is character-for-character the same predicate:

```bash
# scripts/prep-cc-review-clones.sh:47-49
  local stray; stray=$(git -C "$dst" rev-list --all --not "$head" | wc -l)
```

The two differ in source (local repo vs. GitHub fork) and in guard (b) — the canon script
checks for self-referencing `docs/reviews/` files, the new one checks diff non-emptiness —
but "does the same job" is accurate.

**Evidence:** `scripts/crb-materialize.py:15-16`, `scripts/prep-cc-review-clones.sh:6-17,41-49`

---

## Claim 31: "Clones are SHALLOW (--depth, default 50) … ~1 order of magnitude smaller on disk than a full clone of grafana/keycloak."

**Location:** `scripts/crb-materialize.py:18-20`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

The shallow half is verified — `--depth={depth}` is passed on both the clone and the PR-head
fetch, with `default=50`:

```python
# scripts/crb-materialize.py:163-165
    sh(["git", "clone", "--quiet", "--no-checkout", f"--depth={depth}", remote, str(dst)])
    sh(["git", "fetch", "--quiet", f"--depth={depth}", "origin",
        "refs/pull/1/head:refs/heads/review"], cwd=dst)
```

and the measured shallow sizes are 125 MB (grafana) and 127 MB (keycloak)
(`runs/review-arms/crb/instances.json:36,52`). The comparison term — the size of a *full*
clone of grafana or keycloak — is not obtainable without cloning them, and no figure for it
exists anywhere in the repo. A ~1.2–2 GB full clone would make "~1 order of magnitude"
roughly right, but that is my prior, not evidence. Verifying needs a network clone.

**Evidence:** `scripts/crb-materialize.py:18-20,163-165,228`, `runs/review-arms/crb/instances.json:36,52`

---

## Claim 32: "Writes/updates `runs/review-arms/crb/instances.json`: slug -> {url, fork, head, base, n_goldens, files_changed, insertions, deletions, clone_mb}."

**Location:** `scripts/crb-materialize.py:29-31`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Every listed key is present, but the record has five more the docstring omits —
`source_repo`, `pr_title`, `fork_url`, `commits`, `depth`:

```python
# scripts/crb-materialize.py:210-216
    return {
        "url": url, "source_repo": entry["source_repo"], "pr_title": entry["pr_title"],
        "fork": fork, "fork_url": remote, "head": head, "base": base,
        "commits": n_commits, "n_goldens": len(entry["golden_comments"]),
        "files_changed": files, "insertions": ins, "deletions": dels,
        "clone_mb": mb, "depth": depth,
    }
```

The docstring does not say "only these", so it is incomplete rather than wrong — worth
closing since the setup doc's pilot table is built from the omitted `commits` field.

**Evidence:** `scripts/crb-materialize.py:29-31,210-216`, `runs/review-arms/crb/instances.json:2-17`

---

## Claim 33: "The manifest lives under runs/ (tracked) rather than beside the clones: external/ is gitignored"

**Location:** `scripts/crb-materialize.py:48-51`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`.gitignore` ignores the whole directory at its first rule:

```gitignore
# .gitignore:1-2
# Other repos for evaluating/validating tooling changes
external/
```

`DST_ROOT = WORKSPACE / "external/crb-eval"` therefore falls under it, while `MANIFEST =
WORKSPACE / "runs/review-arms/crb/instances.json"` does not match any ignore rule — and is in
fact tracked in this diff. `.gitignore`'s `runs/` rules are limited to `runs/**/prompt.txt`
and three `wt-*` worktree paths, none of which cover `runs/review-arms/crb/`.

**Evidence:** `scripts/crb-materialize.py:47-51`, `.gitignore:1-2`, `.gitignore` (runs/ rules, final 5 lines)

---

## Claim 34: "`keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429`"

**Location:** `scripts/crb-materialize.py:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Executing `slug_for` on the docstring's exact input returns exactly `keycloak-PR37429`. The
`.replace(".", "_")` tail is exercised by the cal.com family:
`slug_for("cal_dot_com__cal.com__claude-code__PR11059__20260310")` → `cal_com-PR11059`,
matching the manifest key at `runs/review-arms/crb/instances.json:2` (paraphrased — no quote
available because these are function return values from a live import, not file contents).

**Evidence:** `scripts/crb-materialize.py:69-74`, `runs/review-arms/crb/instances.json:2`

---

## Claim 35: "the dataset splits a few projects across mirror repos (discourse-graphite, sentry-greptile, keycloak-greptile); for stratification those are the same codebase, so `--per-repo 1` should yield 5 PRs (one per project), not 7."

**Location:** `scripts/crb-materialize.py:93-98`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The operative conclusion is exactly right and reproduces: the dataset's seven distinct
`source_repo` values are `keycloak` (9 PRs), `keycloak-greptile` (1), `sentry` (6),
`sentry-greptile` (4), `grafana` (10), `discourse-graphite` (10), `cal.com` (10); applying

```python
# scripts/crb-materialize.py:98
    return source_repo.split("-")[0]
```

collapses them to five families — `keycloak`, `sentry`, `grafana`, `discourse`, `cal.com` —
and running `select()` with `--per-repo 1` returns 5 PRs, one per family. The "5, not 7"
claim is Verified.

The parenthetical is where it slips: `discourse-graphite` is **not** a mirror-repo split.
There is no plain `discourse` entry in the dataset — `discourse-graphite` is the only
discourse-family repo, so collapsing it changes nothing. The two genuine splits are
`keycloak`/`keycloak-greptile` and `sentry`/`sentry-greptile`. Listing three splits also
misdescribes why 7→5 rather than 7→4: two collapses, not three. Drop `discourse-graphite`
from the parenthetical.

**Evidence:** `scripts/crb-materialize.py:93-98,101-122`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 36: "--per-repo N: the N PRs with the most golden comments in each source repo… Ties break on slug for determinism."

**Location:** `scripts/crb-materialize.py:111-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both halves are implemented in the sort key — descending goldens as primary, slug ascending
as tiebreaker:

```python
# scripts/crb-materialize.py:118-121
    for repo in sorted(by_repo):
        ranked = sorted(by_repo[repo],
                        key=lambda p: (-len(p[2]["golden_comments"]), p[0]))
        sel.extend(ranked[: args.per_repo])
```

`p[0]` is the slug (`load_prs` yields `(slug, url, entry, fork)` tuples, line 88), and Python's
sort is stable and total on this key, so the selection is deterministic. One wording nit that
does not change behavior: the bucketing key is `family(p[2]["source_repo"])` (line 116), i.e.
per *family*, not per "source repo" — consistent with Claim 35's intent but not with this
comment's literal wording.

**Evidence:** `scripts/crb-materialize.py:88,101-122`

---

## Claim 37: "on forks whose default branch is itself named `main`, HEAD still points at it after --no-checkout, and git refuses to force-update the branch that is checked out."

**Location:** `scripts/crb-materialize.py:168-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Reproduced directly. After `git clone --no-checkout` of a repo whose default branch is `main`,
`git symbolic-ref HEAD` returns `refs/heads/main`, and `git branch -f main HEAD~1` fails with
`fatal: cannot force update the branch 'main' checked out at '<path>'` (paraphrased — no quote
available because this is the output of a scratch git repro in a tempdir, not a file in this
repo). The mitigation — checking out `review` before the `branch -f main` — is applied in the
correct order:

```python
# scripts/crb-materialize.py:171-172
    sh(["git", "checkout", "--quiet", "review"], cwd=dst)
    sh(["git", "branch", "-f", "main", base], cwd=dst)
```

**Evidence:** `scripts/crb-materialize.py:163,168-172`

---

## Claim 38: "Guard (b): the range is non-empty and its blobs are present locally (a partial/broken clone shows up here rather than mid-review)."

**Location:** `scripts/crb-materialize.py:191-193`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The non-empty half is what the `if` actually tests:

```python
# scripts/crb-materialize.py:193-196
    n_commits = int(sh(["git", "rev-list", "--count", "main..review"], cwd=dst))
    stat = sh(["git", "diff", "--shortstat", "main", "review"], cwd=dst)
    if n_commits == 0 or not stat:
        raise RuntimeError(f"{slug}: empty review range (commits={n_commits}, stat={stat!r})")
```

The blob half is real but arrives by a different route than the comment implies: no condition
inspects blob presence. What catches it is that `git diff --shortstat` must read both trees'
blobs to produce output, and `sh()` raises on non-zero exit:

```python
# scripts/crb-materialize.py:63-65
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(args)} failed ({r.returncode}): "
                           f"{(r.stderr or '').strip()[:500]}")
```

so a missing-blob repo fails as an unhandled `git diff` error, not as the guard's own
`RuntimeError`. That distinction is not cosmetic for the operator: the failure message will be
a raw git error rather than the slug-tagged "empty review range" line. It is also worth
noting the ordering makes this robust — `origin` is already removed by line 181, so git cannot
lazily backfill a missing blob and mask the problem. Precise version: "the range is non-empty,
and reading it would fail loudly here (via `git diff`) rather than mid-review if the clone
were partial."

**Evidence:** `scripts/crb-materialize.py:59-66,181,191-196`

---

## Claim 39: "Untouched PRs and every other tool's reviews are preserved verbatim, so the aggregate table at the end of step 3 is a real leaderboard."

**Location:** `scripts/crb-pipeline-to-benchmark.py:13-15`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The preservation half is Verified. The script mutates only the covered PRs' `reviews` list,
and only by removing a prior same-named row before appending ours:

```python
# scripts/crb-pipeline-to-benchmark.py:225-233
        entry = data[url]
        entry["reviews"] = [r for r in entry.get("reviews", []) if r["tool"] != args.tool_name]
        entry["reviews"].append({
            "tool": args.tool_name,
```

PRs with no matching run cell are `continue`d (lines 213-224) and re-serialized unchanged at
line 246.

The "so … a real leaderboard" conclusion does not follow for the pilot case, and the sibling
script added in the same commit says so:

```python
# scripts/crb-subset-leaderboard.py:4-8
Step 3's own aggregate table sums each tool over every PR it has results for.
When our arm covers a 5-PR pilot and the other 49 tools cover all 50, that table
compares our row on 5 PRs against theirs on 50 — different denominators, not a
ranking.
```

Both cannot be right. Step 3's aggregate is a real leaderboard only when coverage is uniform
(the `--all` case); under the documented 5-PR pilot it is precisely the mis-denominated table
`crb-subset-leaderboard.py` exists to replace. Since a wrong denominator here corrupts the
headline measurement, reword to "…so the aggregate table is well-formed for every *other*
tool; use `crb-subset-leaderboard.py` for any comparison involving our row."

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:13-15,213-233,246`, `scripts/crb-subset-leaderboard.py:4-8`

---

## Claim 40: "Steps 2 and 3 skip any (PR, tool) pair already present, so seeding means the paid judge work is OUR TOOL ONLY — the other 49 tools keep their published scores instead of being re-judged at ~50x the cost."

**Location:** `scripts/crb-pipeline-to-benchmark.py:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both named steps skip present pairs — see the two quotes in Claim 1
(`step2_extract_comments.py:196-198`, `step3_judge_comments.py:487-489`). The seeding that
makes those skips fire copies exactly the two files those steps read:

```python
# scripts/crb-pipeline-to-benchmark.py:256-260
        for name in ("candidates.json", "evaluations.json"):
            s = src / name
            if s.exists() and not (jdir / name).exists():
                shutil.copy2(s, jdir / name)
```

`~50x` is the right order: 49 other tools plus ours. One scope note the claim gets right by
omission — it says "Steps 2 and 3", not "all three". Step 2.5 is also a paid LLM step and
its `dedup_groups.json` is *not* among the seeded files (and is not checked in for any judge),
so step 2.5 is confined by `--tool` alone. The runbook the script writes does pass `--tool`
to all three (`scripts/crb-pipeline-to-benchmark.py:286-288`), so the documented path is safe;
a reader who seeds but omits `--tool` on step 2.5 would pay for 49 tools' dedup.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:19-20,254-263,286-288`, `external/code-review-benchmark/offline/code_review_benchmark/step2_5_dedup_candidates.py:233-252`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/` (contains only candidates.json + evaluations.json)

---

## Claim 41: "\"✅ Confirmed Good\" rows are never emitted: they assert the code is fine, so counting them as findings would inflate the false-positive denominator with non-claims."

**Location:** `scripts/crb-pipeline-to-benchmark.py:22-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Doubly excluded. The section filter is a case-insensitive substring test against
`("Must Fix", "Must Address", "Consider")`:

```python
# scripts/crb-pipeline-to-benchmark.py:102-103
        if not any(s.lower() in section.lower() for s in sections):
            continue
```

None of the three is a substring of `"✅ confirmed good"` — in particular `"consider"` is not
contained in `"confirmed good"`. Independently, that table's header is `| Item | Verdict |
Evidence | Source | Legibility-target |`, which has no `finding` column, so the
`f_i is None → continue` branch at lines 107-109 would drop it regardless. Running the parser
over the `mfc-csp` rubric confirms: 4 tables are seen (`🔴 Must Fix` 1 row, `🟡 Must Address`
8, `🟢 Consider` 7, `✅ Confirmed Good` 5) and 16 comments are emitted — the 5 Confirmed Good
rows are absent.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:22-26,97-129`, `runs/review-arms/e8-evidence-pipeline/mfc-csp/code-review-rubric.md`, `skills/code-review/SKILL.md:1128`

---

## Claim 42: "Rubric section headers we treat as findings. \"Confirmed Good\" and \"Considered Overrides\" are deliberately absent."

**Location:** `scripts/crb-pipeline-to-benchmark.py:58-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

"Confirmed Good" is genuinely excluded by the section filter (Claim 41). "Considered
Overrides" is **not** — the filter is a substring test, and `"consider"` *is* a substring of
`"↩️ considered overrides"`:

```python
# scripts/crb-pipeline-to-benchmark.py:102-103
        if not any(s.lower() in section.lower() for s in sections):
            continue
```

That section is a real, mandatory part of the rubric format this parser consumes:

```markdown
<!-- skills/code-review/SKILL.md:1137-1148 -->
## ↩️ Considered Overrides
…
| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
```

What actually saves it is the column names: the table has `Prior finding`, not `Finding`, so
`idx.get("finding")` is `None` and the loop bails:

```python
# scripts/crb-pipeline-to-benchmark.py:106-109
        idx = {h.lower(): i for i, h in enumerate(header)}
        f_i = idx.get("finding")
        if f_i is None:
            continue
```

So the outcome is right, but the stated mechanism ("absent from `FINDING_SECTIONS`") is not
the one operating, and the protection is one rubric-header rename away from failing silently
— a renamed `Prior finding` → `Finding` column would start injecting override rows as
findings, inflating the FP count against the benchmark. Also note `SKILL.md:1147-1148`
requires the heading to appear even when empty ("No prior overrides matched this diff"),
which is harmless here only because that form emits no table. Either narrow the match to an
exact/prefix test, or state that exclusion rests on the column name.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:58-60,97-113`, `skills/code-review/SKILL.md:1137-1148`

---

## Claim 43: "Benchmark judging is text-only — path/line are carried for human readability, not scored — so a miss is harmless."

**Location:** `scripts/crb-pipeline-to-benchmark.py:136-138`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The extraction step reads only `body` and discards location outright — it hardcodes `None` for
both fields on every candidate it creates:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:132-135
def get_all_comment_text(review_comments: list[dict]) -> str:
    """Combine all comment bodies into a single text for extraction."""
    bodies = [c["body"] for c in review_comments if c.get("body")]
    return "\n\n---\n\n".join(bodies)
```

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:243-250
            candidates.append(
                {
                    "text": issue,
                    "path": None,
                    "line": None,
                    "source": "extracted",
                }
            )
```

Step 3 judges those `text` candidates against golden `comment` strings, so `path`/`line`
never enter scoring. The injector also appends the raw `Location:` cell into the body
(`scripts/crb-pipeline-to-benchmark.py:126-127`), so even a `parse_location` miss keeps the
location visible to the judge as text.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:132-144,123-128`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:132-135,243-250`

---

## Claim 44: "Without it step 2 re-extracts the ~52 (PR, tool) pairs the checked-in candidates file happens to be missing, and step 3 would re-judge them — paid work that overwrites published numbers with ours."

**Location:** `scripts/crb-pipeline-to-benchmark.py:268-271`, duplicated at `docs/working/crb-direction1-setup.md:143-145`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The mechanism is exactly right; the count is slightly off. Replaying step 2's own selection
logic (extract iff the combined comment text is ≥20 chars and the pair is absent from the
seeded `candidates.json`) over the checked-in
`anthropic_claude-opus-4-5-20251101/candidates.json` yields **50** unseeded pairs, not ~52
(2 449 total pairs, 169 of which step 2 skips for short/empty text). "~52" is close enough to
be harmless but is not a measured figure; use 50. (Paraphrased — no quote available because
the number is an aggregate over two multi-MB generated JSON files.)

The "overwrites published numbers with ours" half is correct: `evaluations.json` is keyed
`url → tool → result` and step 3 writes into the same seeded file, so re-judged rows for other
tools would replace their published values in the file the leaderboard then reads.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:268-271`, `docs/working/crb-direction1-setup.md:143-147`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:190-205`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/candidates.json`

---

## Claim 45: "Step 3's own aggregate table sums each tool over every PR it has results for … Metrics are MICRO-averaged (sum tp/fp/fn across the subset, then divide), the same convention step 3 uses for its aggregate table."

**Location:** `scripts/crb-subset-leaderboard.py:4-11`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Step 3 aggregates over the whole persisted evaluations state — every PR each tool has a
non-skipped result for, not just this run's:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:540-550
    for golden_url, tools in state.completed.items():
        for tool, result in tools.items():
            if result.get("skipped"):
                continue
            …
            tool_metrics[tool]["tp"] += result.get("tp", 0)
            tool_metrics[tool]["fp"] += result.get("fp", 0)
            tool_metrics[tool]["fn"] += result.get("fn", 0)
```

and then divides the sums — micro-averaging:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:558-560
        precision = m["tp"] / (m["tp"] + m["fp"]) if (m["tp"] + m["fp"]) > 0 else 0
        recall = m["tp"] / (m["tp"] + m["fn"]) if (m["tp"] + m["fn"]) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
```

The subset script reproduces that convention exactly, including the same `skipped` filter and
the same three formulas (`scripts/crb-subset-leaderboard.py:56-71`). The field names it reads
(`tp`, `fp`, `fn`, `total_candidates`, `total_golden`, `skipped`) all exist on every one of
the 2 449 rows in the checked-in evaluations file.

**Evidence:** `scripts/crb-subset-leaderboard.py:4-11,54-72`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:540-562,368-380`

---

## Claim 46: "`scripts/crb-subset-leaderboard.py --all-prs # full 50-PR leaderboard`"

**Location:** `scripts/crb-subset-leaderboard.py:16`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

`--all-prs` ranks over every PR in the evaluations file, whatever that count happens to be:

```python
# scripts/crb-subset-leaderboard.py:49-50
    urls = sorted(evals) if args.all_prs else sorted(
        u for u, tools in evals.items() if args.tool in tools)
```

and the header it prints says so honestly (`f"all {len(urls)} PRs"`, line 77). The argparse
help is also accurate — "rank over every PR in the file instead of our tool's subset" (lines
39-40). Only the usage line hardcodes 50. It resolves to 50 on the seeded default path
(`DEFAULT_EVALS`, lines 26-27, points at the work dir seeded from the 50-PR checked-in file),
but is wrong for any `--evaluations` pointed at a `--no-seed` run or a partial judge pass —
where it would silently read as a full-benchmark claim. Reword to "leaderboard over every PR
in the evaluations file".

**Evidence:** `scripts/crb-subset-leaderboard.py:16,26-27,39-40,44-50,74-77`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`docs/working/crb-direction1-setup.md:172-176`): caveat says `total_golden` disagrees "on the same 2 PRs … 11 vs 13"; actually **24 of 50** PRs disagree, and the maximum `total_golden` anywhere in the file is **9**, so `11 vs 13` cannot occur. Understates a measurement caveat by 12×.
- **Claim 39** (`scripts/crb-pipeline-to-benchmark.py:13-15`): "the aggregate table at the end of step 3 is a real leaderboard" is directly contradicted by `crb-subset-leaderboard.py:4-8` in the same commit ("different denominators, not a ranking") for the documented 5-PR pilot. The preservation half is verified; the conclusion is not. Denominator claim — fix before any results doc quotes step 3's table.

### Stale
- **Claim 26** (`scripts/crb-materialize.py:26`): `--all` disk estimate `~15-25GB` is inherited from the pre-pilot plan; the pilot measured 33–195 MB/clone (~6.7 GB for 50), and the setup doc in the same commit says `~6-7 GB`. Two files in one diff differ 2–4×.

### Mostly Accurate
- **Claim 5** (`runs/review-arms/crb-pipeline/run-host.sh:104-105,126`): the "Not logged in" case is caught only by the `num_turns < 1` arm — `"log in"` does not match `"not logged in"` or `"/login"`. Restore E7's second `"logged in"` clause.
- **Claim 7** (`runs/review-arms/crb-pipeline/run-host.sh:150-153`): "re-runs start from the same state" — `git clean -fd` (no `-x`) leaves gitignored artifacts in the clone across instances.
- **Claim 8** (`docs/working/crb-direction1-setup.md:114`, `scripts/crb-pipeline-to-benchmark.py:177`): median findings/PR is 3 over all 2 449 (PR, tool) pairs; 4 only if empty reviews are excluded. State the denominator.
- **Claim 21** (`runs/review-arms/crb-pipeline/run-host.sh:97-99`): a *fresh* named volume inherits the image path's ownership (`node`), not root; the chown guards volumes previously touched by a root container. Also `-u node` selects a username, not a uid.
- **Claim 32** (`scripts/crb-materialize.py:29-31`): manifest key list omits `source_repo`, `pr_title`, `fork_url`, `commits`, `depth` — one of which (`commits`) feeds the setup doc's pilot table.
- **Claim 35** (`scripts/crb-materialize.py:93-98`): "5, not 7" is exactly right, but `discourse-graphite` is not a mirror-repo split (no plain `discourse` entry exists); only keycloak and sentry split.
- **Claim 38** (`scripts/crb-materialize.py:191-193`): no condition checks blob presence — a partial clone surfaces as a raw `git diff` failure via `sh()`'s `check=True`, not as the guard's own error message.
- **Claim 42** (`scripts/crb-pipeline-to-benchmark.py:58-60`): "Considered Overrides" *does* match the `"consider"` substring filter; exclusion actually rests on the table using a `Prior finding` column. One rubric column rename from silently injecting override rows as findings.
- **Claim 44** (`scripts/crb-pipeline-to-benchmark.py:268-271`): the unseeded-pair count is 50, not ~52.
- **Claim 46** (`scripts/crb-subset-leaderboard.py:16`): `--all-prs` ranks over every PR *in the evaluations file*; "full 50-PR" holds only on the seeded default path.
- **Claim 36** (`scripts/crb-materialize.py:111-113`): bucketing is per *family* (`family(source_repo)`), not per "source repo" as worded — behaviorally intended, textually loose.

### Unverifiable
- **Claim 27** (`scripts/crb-materialize.py:7-8`): "every tool's fork carries the same code" — forks agree on the PR stem, but were cut across 27 dates; confirming needs cloning ≥2 forks of one PR and diffing `refs/pull/1/head`. Low exposure today because all 50 `claude-code` forks share one cut date.
- **Claim 31** (`scripts/crb-materialize.py:18-20`): "~1 order of magnitude smaller than a full clone of grafana/keycloak" — the shallow sizes are measured (125/127 MB) but no full-clone size exists in the repo; needs a network clone.
- **Claim 17** (`runs/review-arms/crb-pipeline/run-host.sh:55`): CC 2.1.232 is corroborated as a real, previously-run version by an E7 transcript; whether it is still installable from npm needs registry access.

---

## Repo-state incident (out of band — not a documentation claim)

Discovered while verifying git-history claims. Reporting as observed facts; I ran no
ref-deleting, remote-removing, gc, or reflog command, and the scope command in my brief
succeeded on my first tool call before this state appeared.

**Observed now, in `/workspace`:**
- `git status -sb` → `## No commits yet on feat/crb-direction1-harness`; every tracked file
  shows as `A` (staged add).
- `.git/refs/heads/` is empty; `.git/packed-refs` contains a single line,
  `52265555088aabc56df8e416ba38fd8490b3ba93 refs/heads/main`.
- `git cat-file -t 90de392` → `fatal: Not a valid object name` — **the commit under review no
  longer exists as an object.**
- `.git/config` no longer has a `[remote "origin"]` section; `.git/refs/remotes/` and
  `.git/logs/refs/remotes/` are empty; `.git/logs/HEAD` and `.git/logs/refs/heads/main` are
  zero-length (reflogs expired); `.git/FETCH_HEAD` is zero-length.
- `git fsck` reports all six worktrees under `.claude/worktrees/` now point at unborn
  branches (`worktree-python-toolchain-uv`, `worktree-ledger-cubic-column`,
  `worktree-archive-stale-docs`, `worktree-fact-check-codereview-writeup`,
  `worktree-e7-rep23-ledger`, `exp/cross-model-openrouter-sweep`).
- All of `.git/refs/heads`, `.git/refs/remotes`, `.git/packed-refs`, `.git/config`,
  `.git/index`, `.git/info`, `.git/logs`, `.git/FETCH_HEAD` carry the same mtime, 16:50.

This is the exact four-step signature of the scrub sequence at
`scripts/crb-materialize.py:176-184` — delete every ref except `review`/`main`, `git remote
remove origin`, `git reflog expire --expire=now --all`, `git gc --quiet --prune=now` — applied
to `/workspace` itself rather than to a clone under `external/crb-eval/`. I cannot determine
what invoked it.

**What survives:** `main` is intact with full history (1236 commits, tip `5226555`, and
`d9234c9` still resolves). The reviewed content is intact in the index and working tree —
`git diff --cached --stat main` still produces `7 files changed, 1209 insertions(+)` over the
same seven paths, which is how every claim above was checked.

**What is lost:** the commit object `90de392` and its authored metadata/message; the branch
refs `feat/crb-direction1-harness`, `feat/critic-evidence-discipline`, and the six worktree
branches; all remote-tracking refs and the `origin` URL; all reflogs (so
`git reflog`-based recovery is unavailable).

**Non-destructive recovery sketch** (for the orchestrator/user to run, not applied by me —
this is a repo-mutating operation outside a fact-check's remit):
`git update-ref HEAD 5226555` sets the currently-unborn branch to main's tip while leaving the
index and working tree untouched; `git status` should then show exactly the seven files as
new, and a normal `git commit` recreates 90de392's content on top of main. The original commit
message is recoverable from `.git/COMMIT_EDITMSG` (1 991 bytes, mtime 16:37) and is quoted in
full in the review brief. The `origin` URL will need re-adding from the user's records, and the
six worktree branches need re-pointing or pruning (`git worktree prune`) — their content is
still on disk under `.claude/worktrees/`. Verify before trusting: I have not executed any of
this.

---

## Goal-Alignment Note
- Answered: yes — all 36 enumerated claims checked, plus 10 more from the docs and commit message.
- Out of scope: code quality, security, and performance of the harness (left to stages 2–3); the four claims that need network or host access (full-clone sizes, cross-fork code identity, npm registry state, and the headline unverified assumption that headless Claude Code registers skills from a mounted `~/.claude` — the setup doc already flags that last one honestly at `docs/working/crb-direction1-setup.md:197-203`); executing any repo repair.
- Escalate: (1) **the repo-state incident above — `90de392` no longer exists as a git object and all branch refs but `main` are gone**; downstream critics will find `git diff main...HEAD` fails, and should be told to use `git diff --cached main`. (2) Claim 10 and Claim 39 are measurement-corrupting and should be fixed before any results doc quotes a denominator. (3) Claim 42's substring filter is a latent injection path that a rubric column rename would silently open.
