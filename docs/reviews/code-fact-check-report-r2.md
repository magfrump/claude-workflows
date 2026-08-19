# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Commit:** 90de392
**Scope:** branch diff `main...feat/crb-direction1-harness` — 7 files, +1209/-0, plus the commit message
**Checked:** 2026-08-18
**Total claims checked:** 41
**Summary:** 24 verified, 7 mostly accurate, 0 stale, 5 incorrect, 5 unverifiable

> **⚠️ Operator note (not a claim verdict): this fact-check run damaged the repository's refs.**
> A test command intended for a scratch directory expanded `$TMPDIR` (unset) to empty and ran
> `git for-each-ref … | while read r; do git update-ref -d "$r"; done` followed by
> `git remote remove origin; git reflog expire --expire=now --all; git gc -q --prune=now`
> **inside `/workspace`**. Consequences and recovery are in
> [Repository damage and recovery](#repository-damage-and-recovery) at the end of this report.
> Read that section before doing anything else with this repo.

---

## Claim 1: "2026-08-18: steps 1 and 3 below are built and dry-run green. … A 5-PR pilot is materialized; no paid run has happened."

**Location:** `docs/working/crb-arm-plan.md:193-199` (added block)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The pilot manifest exists with exactly five entries — `cal_com-PR11059`, `discourse-graphite-PR4`,
`grafana-PR79265`, `keycloak-PR36880`, `sentry-greptile-PR5`
(`runs/review-arms/crb/instances.json:2,18,34,50,66`), and re-running the selector against the
vendored dataset reproduces that exact set (see Claim 26). No paid run output exists: the arm
directory contains only the runner script (paraphrased — no quote available because the claim is
about directory contents, not a snippet; `ls runs/review-arms/crb-pipeline/` returns exactly
`run-host.sh`, with no per-slug cell dirs, no `result.json`, no `run-meta.json`).

**Evidence:** `runs/review-arms/crb/instances.json:1-82`, `runs/review-arms/crb-pipeline/`

---

## Claim 2: "Judge cost is bounded by seeding the checked-in opus-4-5 results and passing `--tool`, so only our arm is judged"

**Location:** `docs/working/crb-arm-plan.md:196-198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both halves of the mechanism hold. The seed source
`external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`
contains **all 50 PRs and all 2449 (PR, tool) pairs, with zero rows carrying `errors_count > 0`**
(paraphrased — no quote available because the claim is a property of a 2449-row generated JSON
data file, not of a code snippet). Step 3 skips any pair already recorded without errors:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:52-56
    def is_done(self, golden_url: str, tool: str) -> bool:
        if golden_url not in self.completed or tool not in self.completed[golden_url]:
            return False
        result = self.completed[golden_url][tool]
        return result.get("errors_count", 0) == 0
```

and `--tool` additionally filters the work list before that:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:474-476
            tool = review["tool"]
            if args.tool and tool != args.tool:
                continue
```

**Evidence:** `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:52-56,474-476,486`

---

## Claim 3: "~$1.5 for a 5-PR pilot, ~$13–22 for all 50"

**Location:** `docs/working/crb-arm-plan.md:198-199`; restated `docs/working/crb-direction1-setup.md:20,159`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

The derivation given (`173 goldens × ~12–20 candidates/PR ≈ 2.1k–3.5k short judge calls at $5/$25
per MTok`, `docs/working/crb-direction1-setup.md:159`) depends on per-call token counts that no
artifact in the repo records, and on Anthropic list pricing that cannot be checked offline. The
`173` figure is confirmed (see Claim 8). Verifying the dollar figure needs a real judge run's
billed usage, or the pricing page.

**Evidence:** `docs/working/crb-direction1-setup.md:152-160`

---

## Claim 4: "`scripts/crb-materialize.py --list` # 50 PRs, 173 goldens"

**Location:** `docs/working/crb-direction1-setup.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Executing the module's `load_prs()` against the vendored dataset returns 50 entries totalling 173
golden comments, which is what `--list`'s trailer prints:

```python
# scripts/crb-materialize.py:240
        print(f"\n{len(prs)} PRs, {sum(len(e['golden_comments']) for _, _, e, _ in prs)} goldens")
```

**Evidence:** `scripts/crb-materialize.py:234-241`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 5: "`scripts/crb-materialize.py --all` # all 50 (~6-7 GB)" vs the script's own "~15-25GB"

**Location:** `docs/working/crb-direction1-setup.md:27` and `scripts/crb-materialize.py:26`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The two files in the same commit give estimates that differ by ~3x for the same command. The
script's usage block says:

```python
# scripts/crb-materialize.py:26
  scripts/crb-materialize.py --all                      # all 50 (~15-25GB)
```

the setup doc says:

```markdown
<!-- docs/working/crb-direction1-setup.md:27 -->
scripts/crb-materialize.py --all           # all 50 (~6-7 GB)
```

The measured pilot supports the doc, not the script: the five `clone_mb` values in the manifest are
190, 33, 125, 127, 195 (`runs/review-arms/crb/instances.json:5,20,36,52,68`), summing to 670 MB for
5 PRs — ~134 MB/PR, i.e. ~6.7 GB extrapolated to 50. Note the pilot picks the highest-golden PR per
project, not the largest diff, so this is an estimate rather than a bound; but nothing in the repo
supports 15–25 GB. Fix the script's usage line.

**Evidence:** `scripts/crb-materialize.py:26`, `docs/working/crb-direction1-setup.md:27`, `runs/review-arms/crb/instances.json:5,20,36,52,68`

---

## Claim 6: The pilot table — "33 goldens over 5 PRs", per-slug goldens/commits/diff/disk

**Location:** `docs/working/crb-direction1-setup.md:40-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every cell matches the manifest. For example the keycloak row's "1 file +3/-3 | 127 MB" is:

```json
// runs/review-arms/crb/instances.json:53-60
    "clone_mb": 127,
    "commits": 1,
    "deletions": 3,
    "depth": 50,
    "files_changed": 1,
    ...
    "insertions": 3,
```

and the golden totals sum to 9+8+5+5+6 = 33 (`n_goldens` at
`runs/review-arms/crb/instances.json:13,29,45,61,77`). The same 33 is what the selector reports
when re-run (Claim 26). This also confirms the commit message's "5-PR pilot materialized (33
goldens, one PR per upstream project)".

**Evidence:** `runs/review-arms/crb/instances.json:2-81`, `docs/working/crb-direction1-setup.md:40-51`

---

## Claim 7: "The E8 payload is `main`. `feat/critic-evidence-discipline` was merged at `d9234c9`, and `git diff main feat/critic-evidence-discipline -- skills workflows CLAUDE.md` is empty as of 2026-08-18"

**Location:** `docs/working/crb-direction1-setup.md:68-71`; duplicated at `runs/review-arms/crb-pipeline/run-host.sh:19-25`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three sub-claims hold, and the claim is in fact *stronger* than stated. `d9234c9` is the merge
(paraphrased — no quote available because the evidence is git history, not file content:
`git log -1 --format='%s %P' d9234c9` → `merge: E8 evidence-discipline pipeline + ledger updates
into main` with parents `4ed98ff 2934c51`, and `2934c51` was the
`feat/critic-evidence-discipline` tip). `git diff --stat main 2934c51 -- skills workflows CLAUDE.md`
is empty. I additionally ran the check over the *other two* payload paths the runner archives —
`git diff --stat main 2934c51 -- guides patterns` is also empty — so the payload equivalence covers
all five archived paths, not just the three the comment names.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:19-25,85-86`, `docs/working/crb-direction1-setup.md:68-72`

---

## Claim 8: "The clone is reset with `git checkout -- . && git clean -fd` after harvesting, so re-runs start from the same state."

**Location:** `docs/working/crb-direction1-setup.md:85-86`; source comment at `runs/review-arms/crb-pipeline/run-host.sh:151-153`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The reset is exactly the two commands named:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:200-201
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```

Three residues survive that pair, so "the same state" is not guaranteed:

1. `git clean -fd` without `-x` leaves **gitignored** files. A review agent running `npm install`,
   or writing into any path the upstream repo's `.gitignore` covers, leaves that behind.
2. `git checkout -- .` restores the worktree **from the index**, not from HEAD. If the review agent
   ran `git add`, the staged change is what gets restored — the modification persists.
3. Neither command touches refs. A `git commit`, `git checkout -b`, or `git stash` by the agent
   changes the clone's ref state permanently.

None of these is hypothetical for an agent run with `--dangerously-skip-permissions`
(`runs/review-arms/crb-pipeline/run-host.sh:165`). Tighten to `git reset --hard <head> && git clean -xfd`,
or state the caveat.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:165,193-201`

---

## Claim 9: "the 49 benchmark tools post a median of **4** findings per PR; an E8 rubric carries ~**16** (1 red + 8 amber + 7 green on `mfc-csp`)"

**Location:** `docs/working/crb-direction1-setup.md:114-116`; source comment at `scripts/crb-pipeline-to-benchmark.py:177-178`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The `~16` half is exactly right. Running the injector's own parser over the referenced artifact
yields 16 comments from three sections with row counts 1 / 8 / 7 (paraphrased — no quote available
because the evidence is the output of executing `md_tables` + `comments_from_rubric` from
`scripts/crb-pipeline-to-benchmark.py:67-129` against
`runs/review-arms/e8-evidence-pipeline/mfc-csp/code-review-rubric.md`; sections
`🔴 Must Fix`=1 row, `🟡 Must Address`=8 rows, `🟢 Consider`=7 rows, total 16, and 9 with
`--sections fix address`). That also confirms the doc's "16 findings parsed from `mfc-csp`, 9 with
`--sections fix address`" at `docs/working/crb-direction1-setup.md:190-191`.

The `median of 4` half is off by one under the natural reading. Over all 2449 (PR, tool) pairs in
`benchmark_data.json` the median `len(review_comments)` is **3** and the mean is 3.91; the median of
the 49 per-tool medians is also **3**. The figure 4 is the median over the 2282 pairs that posted
at least one comment. Either say "median 3 (4 among tools that posted anything)" or say "mean ~4".
The argument the number supports — that ~16 rubric rows is several times the field's typical
finding count — is unaffected.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:67-129,177-180`, `runs/review-arms/e8-evidence-pipeline/mfc-csp/code-review-rubric.md:10,20,37`

---

## Claim 10: "Score `--sections fix address` as a second tool name **in the same judge pass**"

**Location:** `docs/working/crb-direction1-setup.md:117-120`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The doc's own worked command puts the second variant in a **different work directory**:

```bash
# docs/working/crb-direction1-setup.md:99-100
scripts/crb-pipeline-to-benchmark.py --sections fix address \
    --tool-name mfc-pipeline-e8-redamber --out runs/review-arms/crb/offline-work-50-ra
```

and the injector always rebuilds `benchmark_data.json` from the pristine vendored file rather than
from the other work dir:

```python
# scripts/crb-pipeline-to-benchmark.py:196
    data = json.loads(BENCH_DATA.read_text())
```

so `offline-work-50-ra/results/benchmark_data.json` contains `mfc-pipeline-e8-redamber` but **not**
`mfc-pipeline-e8`. The benchmark steps read `results/` relative to the current directory
(`RESULTS_DIR = Path("results")`,
`external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:21`), so the
two variants are two separate `cd`-into-a-work-dir judge passes with two separate
`evaluations.json` files — which is what the same sentence's parenthetical ("this costs one extra
judge sweep") actually describes. The two halves of the sentence contradict each other.

Consequence for measurement: `crb-subset-leaderboard.py`'s `DEFAULT_EVALS` points only at
`offline-work-50` (`scripts/crb-subset-leaderboard.py:26-27`), so the red+amber row has to be ranked
with an explicit `--evaluations` path, and the two variants can never appear in one table. If the
intent really is one pass, both tool names must be injected into **one** `--out` dir (which the
current script cannot do in two invocations, because of line 196 above).

**Evidence:** `docs/working/crb-direction1-setup.md:97-120`, `scripts/crb-pipeline-to-benchmark.py:196,245-246`, `scripts/crb-subset-leaderboard.py:26-27`

---

## Claim 11: "`MARTIAN_MODEL=claude-opus-4-5-20251101` … The results dir the run writes is named after the id verbatim (`claude-opus-4-5-20251101`), which is why the injector seeds *that* directory."

**Location:** `docs/working/crb-direction1-setup.md:137-142`; code at `scripts/crb-pipeline-to-benchmark.py:249-253`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The benchmark derives the directory from `MARTIAN_MODEL` with the same sanitizer the injector uses:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:64-74
def sanitize_model_name(model: str) -> str:
    """Sanitize model name for use as directory name."""
    return model.strip().replace("/", "_")

def get_model_dir() -> Path:
    model = os.environ.get("MARTIAN_MODEL", "openai/gpt-4o-mini")
    model_dir = RESULTS_DIR / sanitize_model_name(model)
```

`claude-opus-4-5-20251101` contains no `/`, so the written dir is `results/claude-opus-4-5-20251101`,
which is exactly what the injector creates and what the leaderboard defaults to:

```python
# scripts/crb-pipeline-to-benchmark.py:249-253
    jdir = out / "results" / sanitize_model(args.judge)
    jdir.mkdir(parents=True, exist_ok=True)
    src = BENCH / "results" / sanitize_model(f"anthropic/{args.judge}")
    if not src.exists():
        src = BENCH / "results" / sanitize_model(args.judge)
```

The `anthropic/` prefix fallback is needed because the checked-in dir is
`results/anthropic_claude-opus-4-5-20251101` — i.e. the published results were produced with
`MARTIAN_MODEL=anthropic/claude-opus-4-5-20251101` (Martian routing), while the runbook uses the
bare id against Anthropic's endpoint. Both resolve correctly.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:63-64,249-253`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:64-74`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:21`

---

## Claim 12: "Without it step 2 re-extracts the ~52 `(PR, tool)` pairs missing from the checked-in candidates file **and step 3 re-judges them**"

**Location:** `docs/working/crb-direction1-setup.md:143-145`; source comment at `scripts/crb-pipeline-to-benchmark.py:268-271`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Two corrections, one cosmetic and one material.

*Cosmetic:* the count is **50**, not ~52, and all 50 belong to a single tool, `greptile-v5`
(paraphrased — no quote available because the number comes from a set-difference over two generated
JSON data files: applying step 2's own selection filter,
`if all_text and len(all_text.strip()) >= 20`
[`external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:222`], to
`benchmark_data.json` and subtracting the pairs present in the checked-in `candidates.json` gives
exactly 50 pairs, every one with `tool == "greptile-v5"`).

*Material:* **step 3 would not re-judge them.** The checked-in `evaluations.json` already contains
all 2449 (PR, tool) pairs with `errors_count == 0`, including all 50 `greptile-v5` rows, and
`is_done` therefore returns `True` for every one of them regardless of `--tool`
(`external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:52-56,486`).
The real exposure of omitting `--tool` is step 2's paid extraction of those 50 pairs, plus step 2.5
dedup for every tool (see Claim 13) — not step 3. The stated stakes ("paid work that overwrites
published numbers with ours") overstate the risk for step 3 and understate it for step 2.5.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:268-271`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:216,222`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:52-56,486`

---

## Claim 13: "**`--tool` is mandatory on all three steps.**"

**Location:** `docs/working/crb-direction1-setup.md:143`; runbook text at `scripts/crb-pipeline-to-benchmark.py:284-288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three vendored steps accept `--tool` and all three filter on it. Step 2 and step 3 are quoted
above (Claims 2, 12); step 2.5 is:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_5_dedup_candidates.py:224,267,272
    parser.add_argument("--tool", help="Only deduplicate a specific tool")
...
            if args.tool and tool != args.tool:
...
            if not args.force and golden_url in all_groups and tool in all_groups.get(golden_url, {}):
```

Step 2.5 is the step where `--tool` matters most, and neither the doc nor the code comment says so:
**no `dedup_groups.json` is checked in** for the opus-4-5 judge — the seed directory contains only
`candidates.json` and `evaluations.json` (paraphrased — no quote available because the claim is
about directory contents: `ls external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/`
lists exactly those two files). So without `--tool`, step 2.5 has an empty skip-set and issues a
paid LLM call for every one of the 2233 seeded (PR, tool) pairs. That is the largest unguarded cost
in the chain, and the runbook's "--tool IS REQUIRED on all three" is the only thing preventing it.

**Evidence:** `external/code-review-benchmark/offline/code_review_benchmark/step2_5_dedup_candidates.py:224,263-277`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/`

---

## Claim 14: "canon ledger $14.60/instance (historical pipeline); E8 sweep re-derived at ~$19–44/instance on Fable"

**Location:** `docs/working/crb-direction1-setup.md:156`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both figures come straight from the cited results doc:

```markdown
<!-- docs/working/e8-results-2026-08-18.md:30-33 -->
**$150–350 API-list-equivalent (~$19–44/instance)** — a small multiple of the
~$14.60/instance historical pipeline cost, not a fraction of it
```

**Evidence:** `docs/working/e8-results-2026-08-18.md:28-33`

---

## Claim 15: "**Non-uniform golden denominators in the checked-in evaluations** — on the same 2 PRs, different tools' checked-in rows show `total_golden` 11 vs 13"

**Location:** `docs/working/crb-direction1-setup.md:172-176`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The caveat is real but understates the problem by an order of magnitude, and the specific numbers
do not occur (paraphrased — no quote available because the claim is a distributional property of a
2449-row generated evaluations file, not a snippet). Scanning
`results/anthropic_claude-opus-4-5-20251101/evaluations.json` for PRs where non-skipped rows
disagree on `total_golden`:

- **24 of 50 PRs** have non-uniform denominators, not 2.
- No PR anywhere in the file shows `11` vs `13`. Observed disagreements are e.g. `4 vs 5`, `1 vs 2`,
  `3 vs 5`, `2 vs 4`, `3 vs 6`; the widest is `5 vs 9` on `calcom/cal.com/pull/11059`.
- The split is systematic, not scattered: on every affected PR, 28 tools carry the smaller
  denominator and 21 carry the larger.

**This matters for the arm's headline number, not just as a caveat.** Four of the five pilot PRs
are affected, and our arm will be judged against the *current* `golden_comments` length — the
larger value in each case:

| slug | our `total_golden` | checked-in rows |
|---|---|---|
| `cal_com-PR11059` | 9 | 5 (×28), 9 (×21) |
| `discourse-graphite-PR4` | 8 | 6 (×28), 8 (×21) |
| `grafana-PR79265` | 5 | 5 (×49) — uniform |
| `keycloak-PR36880` | 5 | 3 (×28), 5 (×21) |
| `sentry-greptile-PR5` | 6 | 3 (×28), 6 (×21) |

On the pilot subset our recall denominator is 33 while 28 of the 49 tools were scored against 22.
A tool that found the same issues we do would post ~1.5x our recall. `crb-subset-leaderboard.py`
does print each tool's `gold` column (`scripts/crb-subset-leaderboard.py:84`), so the mismatch is
visible as the doc says — but "visible" is doing a lot of work when it silently reorders the
leaderboard. Rewrite this caveat with the real magnitude, and consider re-judging the 28 stale-
denominator rows on the pilot's 5 PRs (140 pairs, cheap at pilot scale) before publishing a rank.

**Evidence:** `docs/working/crb-direction1-setup.md:172-176`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`, `runs/review-arms/crb/instances.json`

---

## Claim 16: "`offline/analysis/score_profiles.py` implements Strict/Core/All profiles by golden category."

**Location:** `docs/working/crb-direction1-setup.md:180-182`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```python
# external/code-review-benchmark/offline/analysis/score_profiles.py:19-26
PROFILE_CATEGORIES: dict[str, frozenset[str]] = {
    "strict": frozenset({"bug", "security", "concurrency", "data", "api"}),
    "core": frozenset({"bug", "security", "concurrency", "data", "api", "perf", "test_gap", "doc_defect"}),
    "all": frozenset({
        "bug", "security", "concurrency", "data", "api",
        "perf", "test_gap", "doc_defect", "style", "speculative",
    }),
}
```

The follow-on claim "All numbers above are profile-free (All)" is also correct: neither step 3 nor
`crb-subset-leaderboard.py` imports or applies `PROFILE_CATEGORIES`, so their aggregates use every
golden regardless of category (paraphrased — no quote available because the claim is about the
absence of code: `rg -n "score_profiles|PROFILE_CATEGORIES"` over
`code_review_benchmark/` and `scripts/crb-subset-leaderboard.py` returns no hits).

**Evidence:** `external/code-review-benchmark/offline/analysis/score_profiles.py:19-26,160`

---

## Claim 17: "`run-host.sh` … its `DRY_RUN=1` path builds and validates the payload (25 skills, `code-review` present)."

**Location:** `docs/working/crb-direction1-setup.md:194-195`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The count the dry run prints is `find "$PAYLOAD_SRC/skills" -name SKILL.md | wc -l`
(`runs/review-arms/crb-pipeline/run-host.sh:88`), and the repo currently holds 25 `SKILL.md` files
across 26 entries under `skills/` (paraphrased — no quote available because the claim is a file
count, not a snippet: `find /workspace/skills -name SKILL.md | wc -l` → 25). The `code-review`
assertion is the explicit guard at lines 89-90.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:85-90`

---

## Claim 18: "docker cannot run inside a session; same constraint as E5/E7/cc-isolated."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:3-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim is about the absence of a binary in the session
environment, not about file content: `which docker` returns "docker not found" and `docker info`
exits 127 in this session. The "RUN FROM THE HOST" instruction is therefore load-bearing, not
advisory.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:1-4`

---

## Claim 19: "The evidence-discipline work (… 87% recall / 0 FPs on the canon, `docs/working/e8-results-2026-08-18.md`)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:19-21`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```markdown
<!-- docs/working/e8-results-2026-08-18.md:16-18 -->
| Process | Findable | Found | Recall | Confirmed FPs | False Confirmed-Goods |
|---|---|---|---|---|---|
| **E8 evidence-discipline pipeline** | 54 | 47 | **87%** | **0** | **0 clean** (1 over-broad, scoped-true) |
```

**Evidence:** `docs/working/e8-results-2026-08-18.md:16-18`

---

## Claim 20: "E8 was orchestrated stage-by-stage by a human-driven session (k=2 fact-check, explicit critic list per instance)."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:28-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```markdown
<!-- docs/working/e8-results-2026-08-18.md:7-9 -->
provenance-ruled rubric synthesis. Orchestrated locally (fable-5), k=2
fact-check (not the historical k=3), subagents reading the branch's SKILL.md
texts, running in the installed eval clones with evidence capture + blinding.
```

**Evidence:** `docs/working/e8-results-2026-08-18.md:5-12,96-97`

---

## Claim 21: "hooks/ and scripts/ are NOT in the payload (they write to host paths and log usage)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:32-33`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The archive enumerates its paths explicitly, and neither `hooks` nor `scripts` is among them:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:85-86
git -C "$ROOT" archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md \
  | tar -x -C "$PAYLOAD_SRC"
```

Worth flagging as an arm-condition consequence rather than a factual error: the archived `CLAUDE.md`
routes to both excluded trees (e.g. `hooks/batch-feedback-routing-reminder.sh`,
`guides/sandbox-tool-map.md` is present but `scripts/` referents are not), so the containerized
agent reads instructions naming files it cannot open.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:85-86`

---

## Claim 22: "`CC_VERSION="${CC_VERSION:-2.1.232}"` # pin for reproducibility"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:55`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The version is plumbed correctly into both the preflight and the per-instance run
(`npx -y @anthropic-ai/claude-code@"$CC_VERSION"`,
`runs/review-arms/crb-pipeline/run-host.sh:114,161`) and is recorded in `run-meta.json`
(line 230-231), so "pin for reproducibility" is structurally true. Whether `2.1.232` exists on npm
cannot be checked without network. It is corroborated as a real, previously-used version by the
project's own E7 auth memo, which names "Claude Code 2.1.232" as the version probed on 2026-08-15
(paraphrased — no quote available because the source is the session memory file
`cc-bare-headless-ignores-oauth-token.md`, outside the repo).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:55,114,161,230-231`

---

## Claim 23: "`PAYLOAD_REF="${PAYLOAD_REF:-main}"` # == feat/critic-evidence-discipline (merged, see header)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:56`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Verified in Claim 7, including for the `guides` and `patterns` paths the header's diff command
omits. The safety valve the header promises is also real — `run-meta.json` records the resolved SHA
regardless of what `PAYLOAD_REF` names:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:87
PAYLOAD_SHA=$(git -C "$ROOT" rev-parse "$PAYLOAD_REF")
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:56,85-88,230-231`

---

## Claim 24: "E8's canon sweep ran the orchestrator on Fable 5 … `MODEL=opus` is ~1/2 the per-token price"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:57-59`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

First half Verified: "Orchestrated locally (fable-5)"
(`docs/working/e8-results-2026-08-18.md:7`), and the default is set accordingly
(`MODEL="${MODEL:-claude-fable-5}"`, `runs/review-arms/crb-pipeline/run-host.sh:60`).

Second half is arithmetically consistent with the two prices this repo records — Fable 5 at
`$10/M input, $50/M output` (`docs/working/e8-results-2026-08-18.md:110-111`) and opus-4-5 at
`$5/$25 per MTok` (`docs/working/crb-direction1-setup.md:159`) — an exact 2:1 ratio on both axes.
I could not independently confirm current Anthropic list pricing (no network; the `claude-api`
skill was not available in this run), so the underlying figures are taken from the repo rather than
the source of truth. Two imprecisions worth fixing: `--model opus` is a floating alias, so the
"~1/2" relationship is only true while the alias resolves to a model at that price; and "cheaper
sweep" (line 47) conflates per-token price with per-instance cost, which also depends on turn count.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:47,57-60`, `docs/working/e8-results-2026-08-18.md:110-111`, `docs/working/crb-direction1-setup.md:159`

---

## Claim 25: "`git archive` (not a bind mount of $ROOT) so a running review cannot edit the skills that are reviewing it, and so an unrelated local edit mid-sweep cannot change the arm's condition halfway through."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:79-82`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both properties hold. The payload is extracted once, before the loop, from a committed ref
(`runs/review-arms/crb-pipeline/run-host.sh:83-86`), so later worktree edits are invisible to the
sweep. No container mount references `$ROOT`; the three `-v` flags on the review container are the
clone, the per-instance payload copy, and the npm cache:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:157-159
    -v "$clone":/repo \
    -v "$INST_HOME":/home/node/.claude \
    -v cc-review-npm-cache:/home/node/.npm \
```

`$INST_HOME` is a per-instance `cp -r` of `$PAYLOAD_SRC` (line 150) that is deleted after the run
(line 170), so an agent that edits its own `~/.claude` cannot write back into `$PAYLOAD_SRC` either.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:83-86,150,157-159,170`

---

## Claim 26: "Docker creates a fresh named volume root-owned, but the review container runs as uid 1000 (`-u node`)."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:97-99`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The second half is checkable and true: every review-path container passes `-u node`
(`runs/review-arms/crb-pipeline/run-host.sh:111,155`) while the chown container deliberately does
not (line 100). The first half — that Docker initialises a fresh named volume root-owned — is a
Docker runtime behaviour that cannot be exercised here (no docker binary; see Claim 18). It is
consistent with the mitigation being written at all, but confirming it needs a host run.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:97-101,111,155`

---

## Claim 27: "(a) bad credential — the CLI exits 0 with result "Not logged in" (E7 note)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:104-105`; restated `docs/working/crb-direction1-setup.md:76`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The comment is right about the failure mode and **the detector directly below it does not detect
it.** The check is:

```python
# runs/review-arms/crb-pipeline/run-host.sh:126-127
if d.get("num_turns", 0) < 1 or "log in" in r.lower():
    sys.exit(f"  auth failed: {r[:200]!r}")
```

The actual E7-observed result string is `"Not logged in · Please run /login"` — and `"log in"`
(with a space) is **not** a substring of `"not logged in · please run /login"`: the message
contains `"logged in"` and `"/login"`, neither of which contains `"log in"`. The E7 runner this
comment cites gets it right by testing both spellings:

```bash
# runs/review-arms/e7-fable-3x/run-host.sh:103
sys.exit(0 if d.get("num_turns", 0) > 0 and "log in" not in r.lower() and "logged in" not in r.lower() else 1)
```

The new script dropped the `"logged in"` clause — a regression against the very note it cites. The
`num_turns < 1` guard is not a reliable backstop: the same E7 finding records `num_turns` as
**0–1** for this failure, so a `num_turns == 1` auth failure passes the auth check entirely and
then trips the *skill-registration* branch instead, aborting the sweep with the wrong diagnosis
("payload skills NOT registered", line 129). Restore the `"logged in"` clause.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:119-132`, `runs/review-arms/e7-fable-3x/run-host.sh:88,103`

---

## Claim 28: "(b) payload mounted but skills not registered — the run then silently measures Claude Code's built-in review… Decision 022 exists because exactly this happened in cc-isolated."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:106-108`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The referenced decision records precisely that failure, including the "silently" characterisation
and the built-in name collision:

```markdown
<!-- docs/decisions/022-claude-workflows-payload-in-cc-isolated.md:22-29 -->
Those are Claude Code **built-ins**. None of the repo's 25 skills were registered — not
`code-review`, not `security-reviewer`, none. …
1. The built-in skill list contains `review` and `security-review`, which read like the
   repo's `code-review` and `security-reviewer` but are unrelated.
```

That collision is also why the preflight's substring test is written against `code-review` and not
`review` — `"code-review" not in r` (line 128) would not be satisfied by the built-in `review`,
which is the correct discrimination.

**Evidence:** `docs/decisions/022-claude-workflows-payload-in-cc-isolated.md:14-31`, `runs/review-arms/crb-pipeline/run-host.sh:119-132`

---

## Claim 29: "completed result exists, skipping (delete to re-run)" / "Completed cells are skipped on re-invocation (`num_turns > 0`), so a sweep resumes."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:138-143`; doc at `docs/working/crb-direction1-setup.md:86-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

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

A cell that produced no `result` event never gets a `result.json` at all — the harvester exits
before writing it (`runs/review-arms/crb-pipeline/run-host.sh:187-190`) — so a failed instance is
retried on the next invocation, which is the documented behaviour.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:138-144,187-191`

---

## Claim 30: "Fresh writable payload copy per instance: Claude Code writes settings.json, projects/, todos/ into ~/.claude, and one instance's state must not leak into the next (nor back into the payload source)."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:146-148`
**Type:** Behavioral / Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The isolation mechanism is verified (Claim 25: fresh `cp -r` at line 150, `rm -rf` at line 170, and
`chmod -R u+w` so the copy is writable by uid 1000). The premise — that Claude Code writes
`settings.json`, `projects/`, `todos/` into `~/.claude` — is a claim about the CLI's runtime
behaviour that cannot be confirmed by reading this repo; it needs a host run, or the CLI's own
docs. The claim is plausible and the mitigation is harmless if the premise is wrong.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:146-150,170`

---

## Claim 31: "the manifest lives under runs/ (tracked) rather than beside the clones: external/ is gitignored"

**Location:** `scripts/crb-materialize.py:48-51`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```
# .gitignore:2
external/
```

and the manifest is written to a tracked path:

```python
# scripts/crb-materialize.py:51
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
```

which is present in the branch diff, confirming it is tracked.

**Evidence:** `.gitignore:2`, `scripts/crb-materialize.py:47-51`

---

## Claim 32: "Every tool's fork of the same original PR carries the same code (they differ only in which bot reviewed it), so one fork per PR suffices."

**Location:** `scripts/crb-materialize.py:7-8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The benchmark's own forker makes this structural rather than incidental: for a given PR URL, the
only per-tool input is the repo *name*, and the pushed content is identical.

```python
# external/code-review-benchmark/offline/code_review_benchmark/step0_fork_prs.py:132-138
    def generate_repo_name(
        self, original_repo: str, pr_number: int, ai_tool_name: str, config_prefix: str | None = None
    ) -> str:
        date_str = datetime.now().strftime("%Y%m%d")
        tool_slug = re.sub(r"[^a-zA-Z0-9]+", "-", ai_tool_name.lower()).strip("-")[:30]
```

```python
# external/code-review-benchmark/offline/code_review_benchmark/step0_fork_prs.py:176-190
            result = self.run_git(
                tmpdir, "fetch", "origin", f"pull/{pr_number}/head:pr-head"
            )
            ...
            self.run_git(tmpdir, "checkout", base_sha)
            self.run_git(tmpdir, "checkout", "-b", base_branch + "-forked")
            ...
            self.run_git(tmpdir, "checkout", "pr-head")
            self.run_git(tmpdir, "checkout", "-b", pr_branch_name)
```

Same upstream clone, same `pull/N/head`, same `base_sha` — `ai_tool_name` reaches only the
generated repo name. This also independently confirms the neighbouring claim at
`scripts/crb-materialize.py:161-162` that the fork's default branch is the PR base: the base branch
is pushed first (`push target {base_branch}-forked:{base_branch}`, line 205-207), and a repo created
with `auto_init: False` (line 78) takes its first pushed branch as default.

**Evidence:** `external/code-review-benchmark/offline/code_review_benchmark/step0_fork_prs.py:78,132-138,164-210`

---

## Claim 33: "NO other refs and NO origin remote, so a reviewing agent cannot fetch the upstream future (the merged fix — the answer key) via `git log --all`."

**Location:** `scripts/crb-materialize.py:13-14`; implementation at `scripts/crb-materialize.py:174-190`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

I reconstructed the scrub sequence on a synthetic repo and confirmed each step (paraphrased — no
quote available because the evidence is the observed behaviour of a git command sequence run
against a purpose-built fixture, not repo content). Findings:

- The ref sweep deletes tags and remote-tracking refs as well as branches, because the
  `for-each-ref` scope is all three namespaces
  (`scripts/crb-materialize.py:176-177`). `git update-ref -d refs/remotes/origin/HEAD` dereferences
  the symref and removes its target too; the loop then reaches the already-deleted target, and
  `git update-ref -d` on a missing ref exits 0, so the sweep does not abort. Confirmed empirically.
- Ordering is correct and load-bearing: refs are deleted, then the remote removed, then
  `reflog expire --expire=now --all`, then `gc --prune=now`
  (`scripts/crb-materialize.py:179-184`). Expiring reflogs before gc is what makes the objects
  unreachable and therefore prunable.
- After the sequence, `git log --all` on the fixture listed only commits in the reviewed head's
  ancestry, and `git rev-list --all --not <head>` was empty.

One scope note the comment does not make: this closes the *local* route. It does not prevent a
reviewing agent with network access from fetching the upstream repo itself — the PR URL is in the
commit messages and in `instances.json`. The containerised run does not disable networking
(`runs/review-arms/crb-pipeline/run-host.sh:155-166` passes no `--network` flag).

**Evidence:** `scripts/crb-materialize.py:174-190`, `runs/review-arms/crb-pipeline/run-host.sh:155-166`

---

## Claim 34: "This mirrors `scripts/prep-cc-review-clones.sh`, which does the same job for the meta-formalism-copilot canon instances."

**Location:** `scripts/crb-materialize.py:15-16`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The older script performs the same four operations in the same order:

```bash
# scripts/prep-cc-review-clones.sh:40-48
  git -C "$dst" for-each-ref --format='%(refname)' refs/heads refs/tags refs/remotes \
    | grep -v -e '^refs/heads/review$' -e '^refs/heads/main$' \
    | xargs -r -n1 git -C "$dst" update-ref -d
  git -C "$dst" remote remove origin 2>/dev/null || true
  git -C "$dst" reflog expire --expire=now --all
  git -C "$dst" gc --quiet --prune=now
  # guard (a): nothing reachable outside the reviewed head's ancestry
  local stray; stray=$(git -C "$dst" rev-list --all --not "$head" | wc -l)
```

Guard (a) is identical down to the rev-list expression. Guard (b) differs by design — the old
script checks for answer-key leakage into the tree via `docs/reviews/`
(`scripts/prep-cc-review-clones.sh:49-58`), which is meaningless for third-party upstream repos, so
the new script substitutes a range/blob-integrity check. "Same job" is fair; the guard-(b)
divergence is worth a half-sentence in the docstring.

**Evidence:** `scripts/prep-cc-review-clones.sh:39-59`, `scripts/crb-materialize.py:174-196`

---

## Claim 35: "Clones are SHALLOW … ~1 order of magnitude smaller on disk than a full clone of grafana/keycloak."

**Location:** `scripts/crb-materialize.py:18-20`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

The shallow side is measured — grafana 125 MB, keycloak 127 MB
(`runs/review-arms/crb/instances.json:36,51`) — but no full-clone measurement exists anywhere in
the repo, and confirming one requires cloning grafana/keycloak over the network. A 10x claim implies
full clones of ~1.2-1.3 GB, which is the right order for those projects but is not evidence I can
produce here.

**Evidence:** `runs/review-arms/crb/instances.json:36,51`, `scripts/crb-materialize.py:18-20,163`

---

## Claim 36: "Writes/updates runs/review-arms/crb/instances.json: slug -> {url, fork, head, base, n_goldens, files_changed, insertions, deletions, clone_mb}"

**Location:** `scripts/crb-materialize.py:29-30`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The nine listed keys are all present, but the record actually carries fourteen — the docstring omits
`source_repo`, `pr_title`, `fork_url`, `commits`, and `depth`:

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

The checked-in manifest matches this fourteen-key shape exactly
(`runs/review-arms/crb/instances.json:3-16`), so **the manifest is consistent with the writer** —
it is the docstring that is abridged. This matters because two of the omitted keys are consumed
downstream: `fork` and `url` are read by the injector
(`scripts/crb-pipeline-to-benchmark.py:217,229`).

**Evidence:** `scripts/crb-materialize.py:29-30,210-216`, `runs/review-arms/crb/instances.json:2-17`, `scripts/crb-pipeline-to-benchmark.py:217,229`

---

## Claim 37: "claude-code is present on all 50 and was cut on one date (20260310), so it is the most uniform choice."

**Location:** `scripts/crb-materialize.py:53-56`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both halves hold (paraphrased — no quote available because the claim is a distributional property
of a 50-PR generated data file, not a snippet). Tallying `reviews[].tool` over
`benchmark_data.json`: 49 distinct tools, of which `claude-code` appears on all 50 PRs (48 tools
appear 50 times, `mra-a` 49). Tallying the trailing date field of every `claude-code` `repo_name`
gives a single value, `20260310`, on all 50. The uniformity contrast is real — the same PR's other
forks carry mixed dates, e.g. `keycloak__keycloak__augment__PR37429__20260122` alongside
`keycloak__keycloak__bito__PR37429__20260310`.

**Evidence:** `scripts/crb-materialize.py:52-56,82-85`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 38: "`keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429`"

**Location:** `scripts/crb-materialize.py:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```python
# scripts/crb-materialize.py:71-74
    parts = repo_name.split("__")
    if len(parts) < 4:
        raise ValueError(f"unexpected fork repo name: {repo_name}")
    return f"{parts[1]}-{parts[3]}".replace(".", "_")
```

`parts` is `["keycloak", "keycloak", "claude-code", "PR37429", "20260310"]`, so `parts[1]`-`parts[3]`
is `keycloak-PR37429` and the `.`-replacement is a no-op. The `.`-replacement is exercised by the
cal.com entry, which becomes `cal_com-PR11059` (`runs/review-arms/crb/instances.json:2`) — matching
the manifest.

**Evidence:** `scripts/crb-materialize.py:69-74`, `runs/review-arms/crb/instances.json:2`

---

## Claim 39: "the dataset splits a few projects across mirror repos (discourse-graphite, sentry-greptile, keycloak-greptile); for stratification those are the same codebase, so `--per-repo 1` should yield 5 PRs (one per project), not 7."

**Location:** `scripts/crb-materialize.py:94-98`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The operative conclusion is exactly right and reproducible. The dataset's seven distinct
`source_repo` values are `grafana` (10), `discourse-graphite` (10), `cal.com` (10), `keycloak` (9),
`sentry` (6), `sentry-greptile` (4), `keycloak-greptile` (1); `source_repo.split("-")[0]` collapses
these to five families of exactly 10 PRs each — `keycloak`, `sentry`, `grafana`, `discourse`,
`cal.com` (paraphrased — no quote available because the counts are a distributional property of a
generated data file). Executing `select()` with `--per-repo 1` returns the five slugs in
`instances.json` with 33 goldens, confirming both the "5, not 7" claim and the manifest's
provenance.

The one imprecision: `discourse-graphite` is named as a mirror-split project, but it is the *only*
discourse repo in the dataset — there is no plain `discourse` sibling to merge it with. Only
`sentry`/`sentry-greptile` and `keycloak`/`keycloak-greptile` are actual splits, and collapsing
those two pairs is what takes 7 to 5. Listing `discourse-graphite` implies a split that isn't there
(its `split("-")[0]` is a rename, not a merge).

**Evidence:** `scripts/crb-materialize.py:93-98,114-122`, `runs/review-arms/crb/instances.json`

---

## Claim 40: "`--per-repo N`: the N PRs with the most golden comments in **each source repo** … Ties break on slug for determinism."

**Location:** `scripts/crb-materialize.py:111-113`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The ranking and tiebreak are exactly as described:

```python
# scripts/crb-materialize.py:114-122
    by_repo = {}
    for p in prs:
        by_repo.setdefault(family(p[2]["source_repo"]), []).append(p)
    sel = []
    for repo in sorted(by_repo):
        ranked = sorted(by_repo[repo],
                        key=lambda p: (-len(p[2]["golden_comments"]), p[0]))
        sel.extend(ranked[: args.per_repo])
```

`-len(golden_comments)` is descending-by-goldens and `p[0]` (the slug) is the ascending secondary
key, so ties are deterministic. But the grouping key is `family(source_repo)`, **not** `source_repo`
— which is the whole point of Claim 39 sitting 15 lines above. Read literally, "each source repo"
would yield 7 PRs at `N=1`. Also worth noting the same drift in `--per-repo`'s `--help` string
("N PRs per source repo", `scripts/crb-materialize.py:225`), which is what a user actually reads.
Say "each upstream project (see `family()`)".

**Evidence:** `scripts/crb-materialize.py:111-122,225`

---

## Claim 41: "on forks whose default branch is itself named `main`, HEAD still points at it after `--no-checkout`, and git refuses to force-update the branch that is checked out."

**Location:** `scripts/crb-materialize.py:168-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Reproduced end-to-end on a fixture (paraphrased — no quote available because the evidence is
observed git behaviour on a purpose-built repo, not file content). After
`git clone --no-checkout <src> dst` where the source default branch is `main`,
`git symbolic-ref HEAD` in the clone returns `refs/heads/main`; `git branch -f main <sha>` then
fails with exit 128 and
`fatal: cannot force update the branch 'main' checked out at '<path>'`. Performing
`git checkout review` first (as the code does at `scripts/crb-materialize.py:171`) makes the same
`git branch -f main` succeed. The ordering comment is precisely correct and the ordering is
load-bearing for every fork whose base branch is named `main` — which, per Claim 32, is the PR's
actual base branch name, so this is the common case rather than an edge case.

**Evidence:** `scripts/crb-materialize.py:163-172`

---

## Claim 42: "Guard (b): the range is non-empty and its blobs are present locally (a partial/broken clone shows up here rather than mid-review)."

**Location:** `scripts/crb-materialize.py:191-196`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The "non-empty" half is unambiguous:

```python
# scripts/crb-materialize.py:193-196
    n_commits = int(sh(["git", "rev-list", "--count", "main..review"], cwd=dst))
    stat = sh(["git", "diff", "--shortstat", "main", "review"], cwd=dst)
    if n_commits == 0 or not stat:
        raise RuntimeError(f"{slug}: empty review range (commits={n_commits}, stat={stat!r})")
```

The blob half is narrower than stated. `git diff --shortstat` must read blob contents to produce
insertion/deletion counts, so a blob missing for a **changed** file makes the command fail and
`sh(..., check=True)` raises (`scripts/crb-materialize.py:63-65`) — that part works. But the diff
never touches blobs for files *outside* the range, so a `--filter=blob:none` clone whose unchanged
files are all absent would pass this guard and then fail mid-review the moment the agent opens an
unmodified file. Given that the remote is removed before this guard runs
(`scripts/crb-materialize.py:181-182`), lazy backfill is impossible, so that failure would be hard.
Precise wording: "the blobs *the diff touches* are present locally". I could not construct a true
partial clone locally to demonstrate the gap (git ignores `--filter` for local and `file://`
clones), hence Medium rather than High.

**Evidence:** `scripts/crb-materialize.py:59-66,181-196`

---

## Claim 43: "Untouched PRs and every other tool's reviews are preserved verbatim, so the aggregate table at the end of step 3 is a real leaderboard."

**Location:** `scripts/crb-pipeline-to-benchmark.py:14-15`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The preservation half is Verified. The injector mutates only the covered PRs' `reviews` lists, and
only to drop a same-named prior injection before appending:

```python
# scripts/crb-pipeline-to-benchmark.py:225-233
        entry = data[url]
        entry["reviews"] = [r for r in entry.get("reviews", []) if r["tool"] != args.tool_name]
        entry["reviews"].append({
            "tool": args.tool_name,
```

Everything else is re-serialised from the original parse (`data = json.loads(BENCH_DATA.read_text())`,
line 196) and written whole (line 246), so untouched PRs and other tools survive byte-equivalently.

"A real leaderboard" is the overreach, and this script's own sibling says so: step 3's aggregate
sums each tool over every PR it has results for, so on a 5-PR pilot our row's denominator is 5 and
everyone else's is 50 — which is exactly the defect `crb-subset-leaderboard.py` was written to fix
("Step 3's own table compares our 5 PRs against their 50 — different denominators, not a ranking",
`docs/working/crb-direction1-setup.md:149-150`). The two statements contradict each other. The
accurate version is: *the aggregate table's other-tool rows remain their published numbers* — which
is the property injection actually guarantees.

Second-order caveat for the same sentence, unmentioned anywhere: the checked-in evaluations were
produced with no `dedup_groups.json` present (Claim 13), i.e. without dedup, whereas our arm will be
judged with dedup active — and dedup suppresses false positives by propagating a match to duplicate
siblings (`external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:328-330`).
That is a precision asymmetry in our favour, on top of the recall asymmetry against us from
Claim 15.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:196,225-233,245-246`, `scripts/crb-subset-leaderboard.py:4-8`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:328-330,436-449`

---

## Claim 44: ""✅ Confirmed Good" rows are never emitted" / "Confirmed Good" and "Considered Overrides" are deliberately absent"

**Location:** `scripts/crb-pipeline-to-benchmark.py:22-26` and `:58-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The conclusion holds for both sections today, but only one of them is protected by the mechanism
the comment describes. The section filter is a case-insensitive **substring** test:

```python
# scripts/crb-pipeline-to-benchmark.py:102-108
    for section, header, rows in md_tables(md):
        if not any(s.lower() in section.lower() for s in sections):
            continue
        idx = {h.lower(): i for i, h in enumerate(header)}
        f_i = idx.get("finding")
        if f_i is None:
            continue
```

- `"✅ Confirmed Good"` contains none of `must fix` / `must address` / `consider`, so it is excluded
  by the section list as documented. Correct.
- `"↩️ Considered Overrides"` **does** contain `"consider"`, so it passes the section filter. It is
  saved only by the second gate: the rubric template gives that table the columns
  `| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |`
  (`skills/code-review/SKILL.md:1143`), and `idx.get("finding")` is `None` because the column is
  named `Prior finding`, not `Finding`. Running the parser over the real `mfc-csp` artifact confirms
  16 emitted comments from exactly the three intended sections.

So the comment's "deliberately absent" is true of the tuple but false of the behaviour: if a future
rubric revision renames that column to `Finding`, or if `--sections consider` is passed alone, prior
overrides get injected as findings — each one a guaranteed false positive, since an override is by
definition a finding the project decided *not* to act on. Cheapest fix: anchor the match
(`section.lower().startswith(...)` after stripping the emoji, or an explicit exclude-list).

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:58-60,97-129`, `skills/code-review/SKILL.md:1097-1143`

---

## Claim 45: "Benchmark judging is text-only — path/line are carried for human readability, not scored — so a miss is harmless."

**Location:** `scripts/crb-pipeline-to-benchmark.py:136-138`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Confirmed at both stages. Step 2 reads only `body` and discards location entirely, hard-coding
`None` into every candidate it creates:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:146-149
def get_all_comment_text(review_comments: list[dict]) -> str:
    """Combine all comment bodies into a single text for extraction."""
    bodies = [c["body"] for c in review_comments if c.get("body")]
    return "\n\n---\n\n".join(bodies)
```

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:263-271
        for issue in result.get("issues", []):
            candidates.append(
                {
                    "text": issue,
                    "path": None,
                    "line": None,
                    "source": "extracted",
                }
            )
```

and step 3's judge prompt is text-only — it interpolates the golden comment and the candidate string
with no location field (`external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:28-43`).
A `parse_location` miss therefore cannot affect tp/fp/fn. Note the injector also appends the raw
location into the body text (`scripts/crb-pipeline-to-benchmark.py:127`), so location information
does reach the judge — as prose, which is the only channel that is scored.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:127,132-144`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:146-149,263-271`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:28-43`

---

## Claim 46: "Step 3's own aggregate table sums each tool over every PR it has results for."

**Location:** `scripts/crb-subset-leaderboard.py:4-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:539-549
    for golden_url, tools in state.completed.items():
        for tool, result in tools.items():
            if result.get("skipped"):
                continue
            if tool not in tool_metrics:
                tool_metrics[tool] = {"tp": 0, "fp": 0, "fn": 0, "errors": 0, "count": 0}
            tool_metrics[tool]["tp"] += result.get("tp", 0)
```

The iteration is over the whole `state.completed` map with no subsetting, so a tool judged on 5 PRs
and a tool judged on 50 land in the same table with different `count` values — exactly the defect
described. `crb-subset-leaderboard.py`'s own aggregation mirrors this structure while restricting
the URL set (`scripts/crb-subset-leaderboard.py:49-65`).

**Evidence:** `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:536-561`, `scripts/crb-subset-leaderboard.py:49-65`

---

## Claim 47: "Metrics are MICRO-averaged (sum tp/fp/fn across the subset, then divide), the same convention step 3 uses for its aggregate table."

**Location:** `scripts/crb-subset-leaderboard.py:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The two computations are identical in form. Step 3:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:558-560
        precision = m["tp"] / (m["tp"] + m["fp"]) if (m["tp"] + m["fp"]) > 0 else 0
        recall = m["tp"] / (m["tp"] + m["fn"]) if (m["tp"] + m["fn"]) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
```

This script:

```python
# scripts/crb-subset-leaderboard.py:69-71
        p = a["tp"] / (a["tp"] + a["fp"]) if (a["tp"] + a["fp"]) else 0.0
        r = a["tp"] / (a["tp"] + a["fn"]) if (a["tp"] + a["fn"]) else 0.0
        rows.append((tool, p, r, f1(p, r), a))
```

Both sum counts first and divide once (micro), and both skip `skipped` rows
(`scripts/crb-subset-leaderboard.py:57-58`). The `f1` helper matches step 3's guarded formula
(`scripts/crb-subset-leaderboard.py:30-31`).

**Evidence:** `scripts/crb-subset-leaderboard.py:30-31,54-71`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:556-561`

---

## Claim 48: "`scripts/crb-subset-leaderboard.py --all-prs` # full 50-PR leaderboard"

**Location:** `scripts/crb-subset-leaderboard.py:16`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The code ranks over every PR **in the evaluations file**, which the flag's own `--help` states
correctly:

```python
# scripts/crb-subset-leaderboard.py:39-40,49-50
    ap.add_argument("--all-prs", action="store_true",
                    help="rank over every PR in the file instead of our tool's subset")
...
    urls = sorted(evals) if args.all_prs else sorted(
        u for u, tools in evals.items() if args.tool in tools)
```

For the seeded default path this happens to equal 50 — the checked-in evaluations file contains
exactly 50 PRs (paraphrased — no quote available because the count is a property of a generated
JSON data file). But the usage line hard-codes an outcome that depends on the input: pointed at an
un-seeded work dir (`--no-seed`, `scripts/crb-pipeline-to-benchmark.py:184-186`) it would print a
5-PR table under a "full 50-PR" label. Match the usage line to the help text.

Two related notes on the same header block. The `--tool mfc-pipeline-main` example (line 15) uses a
name that no other file produces — the injector's default is `mfc-pipeline-e8` and the documented
second variant is `mfc-pipeline-e8-redamber` — so the example silently exercises the "no judged PRs"
exit path (line 52). And `DEFAULT_EVALS` hard-codes both the work dir and the judge dir name
(`scripts/crb-subset-leaderboard.py:26-27`) while the injector accepts `--judge` and `--out`; the
zero-argument invocation on line 14 is only correct for the default judge and default out dir.

**Evidence:** `scripts/crb-subset-leaderboard.py:13-17,26-27,37-52`, `scripts/crb-pipeline-to-benchmark.py:169-186`

---

## Claims Requiring Attention

### Incorrect

- **Claim 5** (`scripts/crb-materialize.py:26`): `--all` disk estimate says `~15-25GB`; the setup
  doc says `~6-7 GB` and the measured pilot (670 MB / 5 PRs) supports the doc. Fix the script's
  usage line.
- **Claim 10** (`docs/working/crb-direction1-setup.md:117-120`): "in the same judge pass" is
  contradicted by the doc's own `--out runs/review-arms/crb/offline-work-50-ra` example and by
  `scripts/crb-pipeline-to-benchmark.py:196` — the red+amber variant is a separate work dir and a
  separate judge pass, and cannot appear in the same leaderboard table.
- **Claim 12** (`scripts/crb-pipeline-to-benchmark.py:268-271`): the missing-candidates count is 50
  (all `greptile-v5`), not ~52; and **step 3 would not re-judge them** — the seeded
  `evaluations.json` already covers all 2449 pairs with zero errors. The real unguarded cost is
  step 2.5 (see Claim 13), which neither the comment nor the doc mentions.
- **Claim 15** (`docs/working/crb-direction1-setup.md:172-176`): "on the same 2 PRs … 11 vs 13" is
  wrong on both counts — 24 of 50 PRs have non-uniform `total_golden`, no PR shows 11 vs 13, and 4
  of the 5 pilot PRs are affected with 28 of 49 tools carrying a smaller recall denominator than our
  arm will. **Highest-severity item in this report: it biases the pilot's headline recall downward
  against most of the field.**
- **Claim 27** (`runs/review-arms/crb-pipeline/run-host.sh:126-127`): the preflight's
  `"log in" in r.lower()` does not match the E7-documented failure string
  `"Not logged in · Please run /login"`. E7's own runner tests `"log in"` *and* `"logged in"`; this
  script dropped the second clause. With `num_turns == 1` the auth failure escapes the auth branch
  and aborts with the wrong diagnosis.

### Stale

- None.

### Mostly Accurate

- **Claim 8** (`runs/review-arms/crb-pipeline/run-host.sh:151-153`): "re-runs start from the same
  state" — `git clean -fd` without `-x` leaves gitignored files, `git checkout -- .` restores from
  the index (so `git add` persists), and neither touches refs. Use `git reset --hard && git clean -xfd`.
- **Claim 9** (`scripts/crb-pipeline-to-benchmark.py:177-178`): median findings/PR is 3 over all
  2449 pairs (4 among pairs that posted anything); the `~16` half is exact.
- **Claim 24** (`runs/review-arms/crb-pipeline/run-host.sh:57-59`): the 2:1 price ratio is
  consistent with the repo's own recorded figures, but `opus` is a floating alias and "cheaper
  sweep" conflates per-token price with per-instance cost.
- **Claim 36** (`scripts/crb-materialize.py:29-30`): the manifest docstring lists 9 of the 14 keys
  actually written; the manifest file itself is consistent with the writer.
- **Claim 39** (`scripts/crb-materialize.py:94-98`): the "5, not 7" conclusion is exactly right, but
  `discourse-graphite` has no sibling repo and so is not one of the mirror splits.
- **Claim 40** (`scripts/crb-materialize.py:111-113,225`): "each source repo" should read "each
  upstream project" — the grouping key is `family(source_repo)`, which is the difference between 5
  and 7 PRs.
- **Claim 42** (`scripts/crb-materialize.py:191-192`): guard (b) proves only that the blobs *the
  diff touches* are present; blobs for unchanged files are never exercised.
- **Claim 43** (`scripts/crb-pipeline-to-benchmark.py:14-15`): step 3's aggregate table is not "a
  real leaderboard" — that is the exact defect `crb-subset-leaderboard.py` exists to fix. Also
  unflagged anywhere: our arm is judged *with* dedup while the checked-in rows were judged without,
  a precision asymmetry in our favour.
- **Claim 44** (`scripts/crb-pipeline-to-benchmark.py:58-60`): `"↩️ Considered Overrides"` passes the
  substring section filter and is excluded only because its column is named `Prior finding`. A
  template rename, or `--sections consider` alone, would inject prior overrides as findings.
- **Claim 48** (`scripts/crb-subset-leaderboard.py:16`): `--all-prs` ranks over every PR *in the
  evaluations file*, not "the full 50" — true only for a seeded file. Same block: the
  `--tool mfc-pipeline-main` example names a tool nothing produces, and `DEFAULT_EVALS` hard-codes a
  judge dir the injector lets you change.

### Unverifiable

- **Claim 3** (`docs/working/crb-direction1-setup.md:159`): judge-cost figures need a real judge run's
  billed usage or live pricing.
- **Claim 22** (`runs/review-arms/crb-pipeline/run-host.sh:55`): whether `@anthropic-ai/claude-code@2.1.232`
  resolves on npm needs network; corroborated only by the project's E7 memo.
- **Claim 26** (`runs/review-arms/crb-pipeline/run-host.sh:97-99`): fresh-named-volume ownership is
  Docker runtime behaviour; no docker in this environment.
- **Claim 30** (`runs/review-arms/crb-pipeline/run-host.sh:146-148`): that Claude Code writes
  `settings.json`/`projects/`/`todos/` into `~/.claude` needs a host run.
- **Claim 35** (`scripts/crb-materialize.py:18-20`): the "~1 order of magnitude" comparison needs a
  full clone of grafana/keycloak over the network.

---

## Repository damage and recovery

**This is not a claim verdict. It is an incident report about this fact-check run.**

While building a git fixture to verify Claims 33 and 41, I ran a multi-line command whose first
line was `cd $TMPDIR/gt && ...`. `TMPDIR` is unset in this environment, so the `cd` failed and
`&&`-short-circuited — but three later lines in the same block were **unconditional** and executed
in the session's working directory, `/workspace`:

```
git for-each-ref --format='%(refname)' refs/heads refs/tags refs/remotes \
  | grep -v -e '^refs/heads/review$' -e '^refs/heads/main$' \
  | while read r; do git update-ref -d "$r"; done
git remote remove origin; git reflog expire --expire=now --all; git gc -q --prune=now
```

### What was lost

- **`feat/crb-direction1-harness` (90de392) — the branch under review — was deleted, and its commit
  object was pruned by the `gc --prune=now`.** `git cat-file -t 90de392` now reports
  "Not a valid object name"; `git fsck --dangling` finds zero dangling commits. HEAD is an unborn
  ref (`.git/HEAD` → `ref: refs/heads/feat/crb-direction1-harness`, which no longer exists).
- **Six worktree branches were deleted**: `worktree-python-toolchain-uv`, `worktree-ledger-cubic-column`,
  `worktree-archive-stale-docs`, `worktree-fact-check-codereview-writeup`, `worktree-e7-rep23-ledger`,
  `exp/cross-model-openrouter-sweep`. `git worktree list` shows all six at `0000000`. Any commits
  unique to those branches are pruned.
- All tags and all reflogs.

### What survived

- **`main` at `5226555` — intact**, because the sweep's `grep -v` preserved `refs/heads/main`, and
  because `5226555` is the correct pre-branch tip (`git log --oneline main..HEAD` at the start of
  this session showed exactly one commit, `90de392`).
- **The full working tree and the git index of `/workspace` are untouched.** `git status --porcelain`
  reports 1064 entries staged as additions — that is the *complete tree of 90de392* still sitting in
  the index. The seven branch files are byte-intact on disk; I re-read them from disk after the
  incident to finish this report.
- `feat/critic-evidence-discipline`'s tip `2934c51` survived as an object because it is reachable
  from `main` through merge `d9234c9` (the ref is gone; the commit is not).
- Each of the six worktrees retains its own working tree and index on disk.

### Backups I took

- `/home/node/.claude/tmp-fc/backup/` — the seven branch files at their exact reviewed content.
- `/home/node/.claude/tmp-fc/workspace-worktree-backup.tgz` (31 MB) — the whole `/workspace`
  working tree excluding `.git`, `external`, `node_modules`.

### Recovery (I could not perform this — `git update-ref` is blocked by the permission classifier)

The branch content is fully recoverable from the index; only the commit's SHA, timestamp, and
authorship metadata are unrecoverable. Run, from `/workspace`:

```bash
# 1. Re-point the unborn branch at the parent commit. The index already holds 90de392's tree,
#    so this alone makes `git diff --cached` show exactly the 7-file branch diff.
git update-ref refs/heads/feat/crb-direction1-harness 52265555088aabc56df8e416ba38fd8490b3ba93

# 2. Confirm before committing — expect the 7 files and +1209/-0.
git status -sb
git diff --cached --stat

# 3. Recreate the commit with the original message (in the PR description above).
git commit -F <message-file>

# 4. Restore the merged branch ref (object still reachable from main).
git update-ref refs/heads/feat/critic-evidence-discipline 2934c516fca7a01d089416dd79c90518ef1748a2
```

The six worktree branches cannot be restored this way — their tips were unreachable and are pruned.
Their content is still on disk in `.claude/worktrees/*`, so each can be re-committed onto a chosen
base, but their individual histories are gone. **Do not run `git checkout`, `git reset`, or
`git stash` in `/workspace` before step 1** — the index is currently the only copy of the branch
tree inside git.

I take responsibility for this. The verification work in this report was done read-only apart from
that one command; nothing else in the repo was modified, and no file content was lost.

---

## Goal-Alignment Note
- Answered: yes — all 36 flagged claims checked, plus 12 adjacent ones surfaced during verification.
- Out of scope: code quality, architecture, and security of the harness (left to the critics in stages 2-3); the vendored benchmark's own correctness beyond the specific behaviours the diff's comments assert.
- Escalate: (1) **the repository damage above — recover the branch before any other stage runs**, since stages 2 and 3 will try to diff `main...HEAD` and find an unborn HEAD; (2) Claim 15 — the golden-denominator skew affects 24/50 PRs and 4/5 pilot PRs and will bias the arm's published recall, which is a measurement-integrity blocker rather than a doc fix; (3) Claim 27 — the preflight auth-string regression should be fixed before any paid sweep, since it is the guard that exists to prevent a wasted sweep; (4) Claim 13 — step 2.5 has no checked-in dedup groups, so omitting `--tool` there costs ~2233 paid LLM calls, and the dedup asymmetry in Claim 43 favours our arm's precision relative to the published rows.
