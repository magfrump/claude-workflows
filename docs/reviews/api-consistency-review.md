# API Consistency Review — `feat/crb-direction1-harness`

Commit: 529ecd2

**Scope:** `git diff main...HEAD` — 7 files, +1209, all newly added: `scripts/crb-materialize.py`, `scripts/crb-pipeline-to-benchmark.py`, `scripts/crb-subset-leaderboard.py`, `runs/review-arms/crb-pipeline/run-host.sh`, `runs/review-arms/crb/instances.json`, `docs/working/crb-direction1-setup.md`, `docs/working/crb-arm-plan.md`
**Date:** 2026-08-18
**Based on:** Stage-1 code-fact-check (k=3, merged, most-severe-wins), supplied by the code-review orchestrator. Documented behavior from that report is taken as given and not re-verified.

There is no HTTP/gRPC/SDK surface here. The consumer-facing contracts reviewed are: (a) three Python CLI surfaces plus one env-var-driven shell surface, driven in sequence as one toolchain; (b) the inter-script manifest contract (`instances.json`); (c) the vendored third-party benchmark's `benchmark_data.json` record schema, which this repo does not own; (d) the rubric-markdown parsing contract against `skills/code-review/SKILL.md`; (e) the judge-directory naming chain.

---

## Baseline Conventions

Surveyed neighbors: `scripts/prep-cc-review-clones.sh`, `scripts/canon-to-crb.py`, `scripts/review-arms.py`, `scripts/cross-model-review.py`, `scripts/claude_config_audit.py`, `runs/review-arms/e5-cc-builtin/run-host.sh`, `runs/review-arms/e6-ultra/run-host.sh`, `runs/review-arms/e7-fable-3x/run-host.sh`, `runs/review-arms/crb/run-cubic.sh`, and the vendored `external/code-review-benchmark/offline/code_review_benchmark/step{1,2,2_5,3}*.py`.

**Python CLI conventions in `scripts/`**
- `argparse.ArgumentParser(description=__doc__, formatter_class=RawDescriptionHelpFormatter)` with a long module docstring carrying a `Usage:` block (`review-arms.py:113`, `cross-model-review.py:367`). The new scripts all follow this — good.
- Long-form, kebab-case flags. Output dir is `--out` (`review-arms.py:124`, `cross-model-review.py:375`, `canon-to-crb.py:178`).
- The no-side-effects rehearsal flag is `--dry-run` (`review-arms.py:131`, `cross-model-review.py:388`).
- The judge model flag is `--judge`, and its value is **provider-prefixed**: `anthropic/claude-sonnet-4.5` (`review-arms.py:125`, `cross-model-review.py:372`). The vendored benchmark's `MARTIAN_MODEL` default is likewise prefixed (`openai/gpt-4o-mini`, `step3_judge_comments.py:95`), and its checked-in results directories are `anthropic_claude-opus-4-5-20251101`.
- Spend cap is `--max-usd` (`review-arms.py:128`, `cross-model-review.py:374`).
- Hard user error → `sys.exit("message")`; recoverable per-item problems → print and continue.
- Path constants are resolved from `WORKSPACE = Path(__file__).resolve().parent.parent` and user-supplied relative paths are joined onto it (`canon-to-crb.py:181`).

**Vendored benchmark CLI conventions (the third-party contract)**
- The per-tool filter flag is `--tool` on all three judged steps (`step2_extract_comments.py:168`, `step2_5_dedup_candidates.py:224`, `step3_judge_comments.py:388`), alongside `--limit` and `--force`.
- A `reviews[]` record has exactly four keys: `tool`, `repo_name`, `pr_url`, `review_comments` (`step1_download_prs.py:313-318`).
- A `review_comments[]` element has `path`, `line`, `body`, `created_at` (`step1_download_prs.py:135-140`; mirrored by this repo's own writer at `canon-to-crb.py:127-132`).
- Judge directory = `sanitize_model_name(MARTIAN_MODEL)` = `strip().replace("/", "_")` (`step2_extract_comments.py:64-66`, and identically in step2.5/step3).

**Shell runner conventions in `runs/review-arms/*/`**
- `#!/usr/bin/env bash`, `set -euo pipefail`, `cd "$(dirname "$0")/../../.."`, `ROOT="$PWD"`, `CLONES=`, `OUT=`, `CC_VERSION` pin with a "bump deliberately" comment.
- Positional args override a default instance list (`e5:24`, `e7:48`).
- Tunables are `UPPER_SNAKE` env vars with `${VAR:-default}` (`e7:47 REPS`, `run-cubic.sh:37 CUBIC_BIN`).
- A cheap auth preflight runs before the sweep; a missing clone is a **hard** error (`e7:115` → `exit 1`).
- Completed-cell skip keyed on `num_turns > 0` (`e7:120-125`).

**Contamination/scrub discipline:** `prep-cc-review-clones.sh:40-58` establishes the ref-scrub + guard-(a)/guard-(b) pattern that `crb-materialize.py:176-196` reimplements in Python. The port is faithful.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--tool-name` (injector) | CLI flag | `--tool` (benchmark steps 2/2.5/3), `--tool` (`crb-subset-leaderboard.py:38`) | `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:168`, `scripts/crb-subset-leaderboard.py:38` | **Inconsistent** — same concept, two spellings inside one toolchain → F1 |
| `--tool` (leaderboard) | CLI flag | `--tool` (benchmark steps) | same as above | Consistent |
| `--stats` (injector) | CLI flag | `--dry-run` (`crb-materialize.py:230`), `--dry-run` (`review-arms.py:131`, `cross-model-review.py:388`) | `scripts/{crb-materialize,review-arms,cross-model-review}.py` | **Inconsistent** — third spelling of "rehearse, write nothing" → F4 |
| `--dry-run` (materialize) | CLI flag | `--dry-run` (`review-arms.py:131`) | `scripts/review-arms.py:131` | Consistent |
| `--judge` (injector) | CLI flag | `--judge` (`review-arms.py:125`, `cross-model-review.py:372`) | `scripts/{review-arms,cross-model-review}.py` | Name consistent; **value shape inconsistent** (bare vs `anthropic/…`) → F3 |
| `--out` (injector) | CLI flag | `--out` (`canon-to-crb.py:178`, `review-arms.py:124`) | `scripts/canon-to-crb.py:178` | Name consistent; **resolution semantics differ** → F6 |
| `--all` (materialize) vs `--all-prs` (leaderboard) | CLI flag | each other; no third analog in `scripts/` | `scripts/crb-materialize.py:223`, `scripts/crb-subset-leaderboard.py:39` | **Inconsistent** — same word, two different denominators → F11 |
| `--no-seed` (injector) | CLI flag | `--force`, `--all-files`, `--include-plugins`, `--analyze-only` | `scripts/{crb-materialize,claude_config_audit,cross-model-review}.py` | Minor — only `--no-*` flag in `scripts/`; siblings are all affirmative → F12 |
| `--per-repo`, `--slug`, `--list`, `--depth`, `--force` | CLI flag | `--force` (`prep-cc-review-clones.sh:30`), `--limit`/`--force` (benchmark) | `scripts/prep-cc-review-clones.sh:30` | Consistent |
| `--runs`, `--source`, `--sections`, `--evaluations`, `--markdown` | CLI flag | _(no analog in `scripts/` or the vendored benchmark)_ | none — searched `scripts/*.py`, `runs/review-arms/**`, `external/code-review-benchmark/offline/code_review_benchmark/*.py` | New category — convention being established |
| `MODEL`, `BUDGET`, `DRY_RUN`, `CC_VERSION`, `PAYLOAD_REF` | env var | `REPS` (`e7:47`), `CC_VERSION` (`e5:23`, `e7:46`), `CUBIC_BIN`/`CUBIC_LOG_LEVEL` (`run-cubic.sh:37,101`), `CLAUDE_CREDENTIALS` (`e7:63`) | `runs/review-arms/{e5-cc-builtin,e6-ultra,e7-fable-3x,crb}/*.sh` | `UPPER_SNAKE` + `${VAR:-default}` shape consistent; `BUDGET` diverges from the `--max-usd` money-knob name → F13 |
| `sanitize_model()` | function | `sanitize_model_name()` (identical body, three copies) | `external/…/code_review_benchmark/step{2_extract_comments,2_5_dedup_candidates,3_judge_comments}.py:64/82/88` | **Inconsistent** — renamed clone of a vendored helper → F9 |
| `sh()` | function | `sh()` (`cross-model-review.py:143`) | `scripts/cross-model-review.py:143` | Consistent |
| `slug_for`, `load_prs`, `family`, `select`, `resolve_base`, `dir_mb`, `materialize` | function | `load_ledger`, `findings_to_comments`, `cubic_to_comments` (`canon-to-crb.py`) | `scripts/canon-to-crb.py:89-173` | Consistent — verb-phrase module-level helpers |
| `md_tables`, `comments_from_rubric`, `parse_location`, `load_cell` | function | `findings_to_comments`, `cubic_to_comments` | `scripts/canon-to-crb.py:116,136` | Consistent — `<source>_to_comments` / `comments_from_<source>` both read fine |
| `f1()` | function | _(no analog)_ | none — searched `scripts/*.py` | New — fine |
| `source_provenance` (injected record key) | field | `mapping_provenance` (`canon-to-crb.py:109`) | `scripts/canon-to-crb.py:109` | Name **consistent** with the repo's `*_provenance` suffix; schema-extension question is F8 (non-naming) |
| `path` / `line` / `body` (emitted comment) | field | `path`/`line`/`body`/`created_at` (`step1_download_prs.py:135-140`, `canon-to-crb.py:127-132`) | `external/…/step1_download_prs.py:135-140` | **Field-set asymmetry** — `created_at` dropped → F7 |
| manifest keys `url`, `source_repo`, `pr_title`, `fork`, `fork_url`, `head`, `base`, `commits`, `n_goldens`, `files_changed`, `insertions`, `deletions`, `clone_mb`, `depth` | field | benchmark's `repo_name`/`pr_url`/`source_repo` | `external/…/step1_download_prs.py:313-318` | Mostly consistent snake_case; `fork` vs benchmark's `repo_name` is a deliberate rename mapped at `crb-pipeline-to-benchmark.py:229` |
| `instances.json`, `run-meta.json`, `preflight.json`, `review.md`, `transcript.jsonl`, `RUN.md` | artifact | `result.json`, `transcript.jsonl`, `stderr.log`, `findings.jsonl` | `runs/review-arms/e7-fable-3x/run-host.sh:120-176`, `runs/review-arms/e2/**` | Consistent; `run-meta.json` is new to this branch (first of its kind) |

---

## Findings

#### F1 — The per-tool selector is `--tool-name` in the injector and `--tool` everywhere else in the same toolchain

**Severity:** Inconsistent
**Location:** `scripts/crb-pipeline-to-benchmark.py:170-171`
**Move:** #2 (naming against the grain)
**Confidence:** High
**Legibility-target:** the operator running the four stages back-to-back from the setup doc.

Precedent: `--tool` used in `external/code-review-benchmark/offline/code_review_benchmark/step{2_extract_comments.py:168,2_5_dedup_candidates.py:224,3_judge_comments.py:388}` and `scripts/crb-subset-leaderboard.py:38`

**Evidence:**
```python
    ap.add_argument("--tool-name", default="mfc-pipeline-e8",
                    help="tool name in benchmark_data.json (default mfc-pipeline-e8)")
```
against `scripts/crb-subset-leaderboard.py:38`:
```python
    ap.add_argument("--tool", default="mfc-pipeline-e8", help="our arm's tool name")
```
and `external/…/step2_extract_comments.py:168`:
```python
    parser.add_argument("--tool", help="Only process specific tool")
```

The same string — the tool's name in `benchmark_data.json` — is spelled `--tool-name` on stage 3 and `--tool` on stages 4a–4d. Four of the five commands a user types in sequence take `--tool`; one takes `--tool-name`. The generated runbook makes the collision visible in a single code block (`crb-pipeline-to-benchmark.py:286-293` emits `--tool {args.tool_name}` three times, then `--tool {args.tool_name}` again for the leaderboard). Since `--tool` is load-bearing for cost confinement (Stage-1 finding 6: omitting it on step 2.5 costs ~2233 paid LLM calls), a flag-name near-miss here is expensive rather than merely annoying.

**Recommendation:** Rename to `--tool` and keep `--tool-name` as a hidden alias (`ap.add_argument("--tool", "--tool-name", dest="tool_name", …)`) so the setup doc's existing example at `docs/working/crb-direction1-setup.md:100` keeps working.

---

#### F2 — The judge is parameterized on the injector but hard-coded in the leaderboard, so changing `--judge` silently breaks the next stage's default

**Severity:** Inconsistent
**Location:** `scripts/crb-subset-leaderboard.py:26-27`
**Move:** #7 (asymmetry) / #3 (consumer contract)
**Confidence:** High
**Legibility-target:** anyone who scores a second judge for a judge-variance check.

**Evidence:**
```python
DEFAULT_EVALS = (WORKSPACE / "runs/review-arms/crb/offline-work-50/results"
                 / "claude-opus-4-5-20251101/evaluations.json")
```
against `scripts/crb-pipeline-to-benchmark.py:172-173`:
```python
    ap.add_argument("--judge", default=DEFAULT_JUDGE,
                    help=f"judge model id whose results dir to seed (default {DEFAULT_JUDGE})")
```

Stage 3 exposes both `--judge` and `--out`; stage 4d exposes neither, baking both into a single constant path. The two are one toolchain, so the injector's flexibility is illusory: `--judge X --out Y` produces evaluations that `crb-subset-leaderboard.py` (invoked with its default) cannot find, failing with `no evaluations at … — run step 3 first` — a message that misdiagnoses the problem as "you skipped a step" when the real cause is "you changed a flag two stages ago." The generated `RUN.md` dodges this by always passing `--evaluations` explicitly (`crb-pipeline-to-benchmark.py:291-293`), which means the bug only bites the user who follows `docs/working/crb-direction1-setup.md:134` — where the leaderboard is invoked with `--tool` only. Stage 1 flagged the hard-coded judge dir as a doc accuracy issue (finding 10); the consistency issue is that the pair of scripts disagrees about whether the judge is configurable at all.

**Recommendation:** Give `crb-subset-leaderboard.py` `--judge` and `--work-dir` flags and derive the evaluations path from them, keeping `--evaluations` as the explicit-path escape hatch. Alternatively, have the injector write the judge and work-dir into a small `run-meta`-style JSON the leaderboard reads.

---

#### F3 — `--judge` takes a bare model id here, but every other `--judge` in `scripts/` takes a provider-prefixed id

**Severity:** Inconsistent
**Location:** `scripts/crb-pipeline-to-benchmark.py:56`, `:172-173`, `:249-253`
**Move:** #2 (naming — value convention)
**Confidence:** Medium-High
**Legibility-target:** a user copying a judge id from `review-arms.py`'s help text or from the benchmark's checked-in results directory listing.

Precedent: provider-prefixed judge ids (`anthropic/claude-sonnet-4.5`) used in `scripts/review-arms.py:125` and `scripts/cross-model-review.py:372`; `openai/gpt-4o-mini` as the `MARTIAN_MODEL` default in `external/…/code_review_benchmark/step{2,2_5,3}*.py`

**Evidence:**
```python
DEFAULT_JUDGE = "claude-opus-4-5-20251101"
```
and
```python
    jdir = out / "results" / sanitize_model(args.judge)
    jdir.mkdir(parents=True, exist_ok=True)
    src = BENCH / "results" / sanitize_model(f"anthropic/{args.judge}")
    if not src.exists():
        src = BENCH / "results" / sanitize_model(args.judge)
```
against `scripts/review-arms.py:125`:
```python
    ap.add_argument("--judge", default="anthropic/claude-sonnet-4.5",
```

The same flag name accepts differently shaped values in two scripts sitting in the same directory. Here the value must be bare, because the code re-adds the `anthropic/` prefix when locating the seed source and omits it when naming the destination — a split the code compensates for with a two-try fallback rather than a stated rule. The default path resolves correctly (Stage 1 verified this), and `docs/working/crb-direction1-setup.md:137-142` documents *why* the destination dir is unprefixed, so this is not a latent bug on the happy path. It is a learnability cost: the user who supplies `--judge anthropic/claude-opus-4-5-20251101` — the shape the neighbouring scripts and the vendored `results/` directory listing both teach — gets a judge dir named `anthropic_claude-opus-4-5-20251101`, which then has to match whatever they export as `MARTIAN_MODEL`, and which `DEFAULT_EVALS` (F2) will not find.

**Recommendation:** Accept both shapes and normalize once: strip a leading `<provider>/` on entry, keep the bare id for `jdir`, and document in `--judge`'s help that the value is the bare `MARTIAN_MODEL` id, not an OpenRouter-style path.

---

#### F4 — Three surfaces, three names for "rehearse, write nothing": `--dry-run`, `--stats`, `DRY_RUN=1`

**Severity:** Inconsistent
**Location:** `scripts/crb-pipeline-to-benchmark.py:187`
**Move:** #2 (naming against the grain)
**Confidence:** High
**Legibility-target:** the operator doing a $0 rehearsal of the whole chain before a paid sweep — the exact workflow `docs/working/crb-direction1-setup.md:186-195` documents.

Precedent: `--dry-run` used in `scripts/crb-materialize.py:230`, `scripts/review-arms.py:131`, `scripts/cross-model-review.py:388`

**Evidence:**
```python
    ap.add_argument("--stats", action="store_true", help="report only, write nothing")
```
against `scripts/crb-materialize.py:230` in the same commit:
```python
    ap.add_argument("--dry-run", action="store_true", help="print the selection, clone nothing")
```
and `runs/review-arms/crb-pipeline/run-host.sh:62`:
```bash
DRY_RUN="${DRY_RUN:-}"
```

`--stats` and `--dry-run` have identical semantics — compute the selection, print what would happen, exit before writing — but only one of them is the name the repo already uses three times. The shell surface's `DRY_RUN=1` is the correct choice for a runner whose positionals are instance ids (matching the `REPS`/`CUBIC_BIN` env-tunable convention at `e7:47` and `run-cubic.sh:37`), so the divergence is really two-way, not three-way. But it means the dry-run rehearsal reads `--dry-run` / `DRY_RUN=1` / `--stats` / _(no rehearsal on the leaderboard)_ across four consecutive commands.

**Recommendation:** Rename to `--dry-run` with `--stats` retained as an alias. Keep `DRY_RUN=1` on the shell runner.

---

#### F5 — Three different behaviors when a named instance does not exist

**Severity:** Inconsistent
**Location:** `scripts/crb-materialize.py:104-108`, `scripts/crb-pipeline-to-benchmark.py:200-205`, `runs/review-arms/crb-pipeline/run-host.sh:136`
**Move:** #4 (error consistency)
**Confidence:** High
**Legibility-target:** an operator running a named subset (`… --slug keycloak-PR36880`) and relying on exit status in a wrapper or shell `&&` chain.

**Evidence:** `crb-materialize.py:104-108` — hard exit:
```python
        missing = want - {p[0] for p in sel}
        if missing:
            sys.exit(f"unknown slug(s): {', '.join(sorted(missing))}")
```
`crb-pipeline-to-benchmark.py:203-205` — warn and continue:
```python
        missing = want - {c.name for c in cells}
        if missing:
            print(f"  !! no run output for: {', '.join(sorted(missing))}", file=sys.stderr)
```
`run-host.sh:136` — warn and continue:
```bash
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/crb-materialize.py --slug $id" >&2; continue; }
```
against the sibling runner `runs/review-arms/e7-fable-3x/run-host.sh:115` — hard exit:
```bash
    [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/prep-cc-review-clones.sh" >&2; exit 1; }
```

A typo in a slug is caught loudly at stage 1, degrades to a stderr line at stage 2 (where the run then proceeds and produces a sweep silently missing a cell), and degrades again at stage 3. `run-host.sh` additionally reverses the sibling E7 runner's decision on the identical condition without a comment explaining why. The asymmetry matters most at stage 2 because that is the paid stage: `run-host.sh` exits 0 after skipping every requested instance, so a wrapper cannot distinguish "reviewed 5 PRs" from "reviewed 0 PRs because you typo'd the slugs." Note this is separate from the deliberate and correct decision to keep going when one *materialization* fails (`crb-materialize.py:260-263`) — that is a per-item recoverable failure, whereas a bad slug is a user error.

**Recommendation:** Make an unknown/unmaterialized instance name a hard error in all three (matching `crb-materialize.py` and E7), reserving warn-and-continue for genuine per-item runtime failures. At minimum, have `run-host.sh` track a skip count and `exit 1` if every requested instance was skipped.

---

#### F6 — A relative `--out` resolves against the CWD here but against `WORKSPACE` in the sibling that writes the same kind of work dir

**Severity:** Minor
**Location:** `scripts/crb-pipeline-to-benchmark.py:169`, `:194`
**Move:** #3 (consumer contract) / #7 (asymmetry)
**Confidence:** High
**Legibility-target:** a user who copies the `--out` example from `canon-to-crb.py` or from `docs/working/crb-direction1-setup.md:100`.

**Evidence:**
```python
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="benchmark work dir to write")
```
```python
    out = Path(args.out)
```
against `scripts/canon-to-crb.py:178-181`:
```python
    ap.add_argument("--out", default="runs/review-arms/crb/offline-work")
    args = ap.parse_args()

    out = WORKSPACE / args.out
```

Both scripts write a benchmark work dir under `runs/review-arms/crb/` and both call the flag `--out`, but `canon-to-crb.py` treats the value as workspace-relative while the new injector treats it as CWD-relative. The setup doc's own example (`--out runs/review-arms/crb/offline-work-50-ra`, line 100) is a workspace-relative path, so running it from anywhere other than `/workspace` writes the work dir in the wrong place and leaves the emitted `RUN.md`'s `cd {out}` pointing at a directory that may not exist. The default is absolute, so the happy path is unaffected.

**Recommendation:** Use `out = WORKSPACE / args.out` (a `Path` join leaves absolute values untouched, so the default keeps working), matching `canon-to-crb.py:181`. Apply the same to `--runs` and `--evaluations` for symmetry.

---

#### F7 — Emitted `review_comments` drop `created_at`, which both other writers of this record always include

**Severity:** Minor
**Location:** `scripts/crb-pipeline-to-benchmark.py:123-128`, `:160`
**Move:** #7 (asymmetry) / #8 (nullability)
**Confidence:** High
**Legibility-target:** anyone diffing our injected rows against the benchmark's own rows, or adding a downstream consumer of `benchmark_data.json`.

Precedent: `path`/`line`/`body`/`created_at` written together in `external/code-review-benchmark/offline/code_review_benchmark/step1_download_prs.py:135-140` and `scripts/canon-to-crb.py:127-132`, `:148`, `:159-160`, `:172`

**Evidence:**
```python
            out.append({
                "path": path,
                "line": line,
                "body": (f"[{prefix}] " if prefix else "") + body
                        + (f"\n\nLocation: {loc}" if loc and loc != "—" else ""),
            })
```
against `scripts/canon-to-crb.py:127-132`, this repo's other benchmark writer:
```python
                comments.append({
                    "path": fnd.get("path"),
                    "line": fnd.get("line_start"),
                    "body": body,
                    "created_at": None,
                })
```

The benchmark's own producer (`step1_download_prs.py`) and this repo's existing producer both emit a 4-key comment; the new one emits 3. This is safe today — the only consumer of `review_comments` in the judged path is `get_all_comment_text` at `step2_extract_comments.py:146-148`, which reads `c.get("body")`, and `step_speed_analysis.py` reads `created_at` from live GitHub payloads rather than from `benchmark_data.json` — so nothing breaks. But it makes our injected rows structurally distinguishable from every other row in the file, which is precisely the property this arm's provenance story depends on not having. The nullability contract is also implicit rather than stated: `path` and `line` are `None` whenever `parse_location` misses (`:143-144`) and always `None` on the result-text fallback (`:160`), which the docstring at `:135-138` explains — good — but the absent-vs-null distinction for `created_at` is undocumented.

**Recommendation:** Emit `"created_at": None` in both `comments_from_rubric` and the `load_cell` fallback, matching `canon-to-crb.py`.

---

#### F8 — `source_provenance` extends a schema this repo does not own

**Severity:** Informational
**Location:** `scripts/crb-pipeline-to-benchmark.py:227-233`
**Move:** #3 (consumer contract) / #6 (versioning impact)
**Confidence:** High
**Legibility-target:** whoever next syncs the vendored benchmark or publishes a `benchmark_data.json` derived from this work dir.

**Evidence:**
```python
        entry["reviews"].append({
            "tool": args.tool_name,
            "repo_name": rec["fork"],
            "pr_url": url,
            "review_comments": comments,
            "source_provenance": prov,
        })
```
against the benchmark's own producer at `external/…/step1_download_prs.py:313-318`:
```python
                output[golden_url]["reviews"].append({
                    "tool": tool,
                    "repo_name": repo_name,
                    "pr_url": result["pr_meta"]["url"],
                    "review_comments": result["comments"],
                })
```

Our record carries a fifth key the vendored schema never produces. This is tolerated: every consumer reads by key (`step3_judge_comments.py:210,218` → `review["tool"]`, `review.get("review_comments", [])`; `summary_table.py:32,35`; `step2_extract_comments.py:219`), none iterates or validates the key set, and the tool-replacement logic at `crb-pipeline-to-benchmark.py:226` filters on `r["tool"]` only. The key name also follows this repo's own `*_provenance` convention (`canon-to-crb.py:109`, `mapping_provenance`), so it reads correctly to a repo-local reader. Recording it is the right call — it is the only place the rubric-vs-result-text distinction survives into the scored artifact. Flagged only so that (a) it is a conscious extension rather than an accident, and (b) it is remembered as a known delta if the vendored benchmark is ever re-synced or the work dir is shared upstream.

**Recommendation:** No code change. Add one line to `docs/working/crb-direction1-setup.md` §3 stating that our `reviews[]` records carry one non-schema key and that it is ignored by steps 2/2.5/3.

---

#### F9 — `sanitize_model()` is a renamed copy of the vendored `sanitize_model_name()`

**Severity:** Minor
**Location:** `scripts/crb-pipeline-to-benchmark.py:63-64`
**Move:** #2 (naming against the grain)
**Confidence:** High
**Legibility-target:** a reader checking that our judge-directory naming really matches what the benchmark will compute.

Precedent: `sanitize_model_name` used in `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:64`, `step2_5_dedup_candidates.py:82`, `step3_judge_comments.py:88`

**Evidence:**
```python
def sanitize_model(model: str) -> str:
    return model.strip().replace("/", "_")
```
against `external/…/step2_extract_comments.py:64-66`:
```python
def sanitize_model_name(model: str) -> str:
    """Sanitize model name for use as directory name."""
    return model.strip().replace("/", "_")
```

The body is character-identical to the function whose output our directory name must agree with, but the name differs by a suffix and the docstring — the part that says *why* it exists — is dropped. The whole correctness argument for the judge-dir chain is "these two produce the same string"; naming them differently and omitting the docstring makes that argument something a reader has to reconstruct. Three copies of this helper already exist in the vendored tree, so a fourth is defensible (importing from the vendored package would add a dependency the script otherwise avoids) — the issue is only the name and the missing rationale.

**Recommendation:** Rename to `sanitize_model_name` and add a one-line docstring naming the vendored function it mirrors and why the strings must match.

---

#### F10 — `--per-repo 0` reports "pick one of …" instead of an argument-value error

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:241-242`
**Move:** #4 (error consistency)
**Confidence:** High
**Legibility-target:** a user scripting the selector from a variable.

**Evidence:**
```python
    if not (args.all or args.per_repo or args.slug):
        ap.error("pick one of --list / --per-repo N / --slug ... / --all")
```

The guard tests truthiness, so `--per-repo 0` — an explicitly supplied selector — is indistinguishable from no selector at all, and the user is told to pick a selector they just picked. `--slug` with an empty list is impossible (`nargs="+"`), so `--per-repo` is the only affected flag. The same test also silently makes `--per-repo 0` mean "no selection" rather than "zero per repo," which is at least arguable, but the error message is not.

**Recommendation:** Test `args.per_repo is not None` and reject `< 1` with a value-specific message (`--per-repo must be >= 1`).

---

#### F11 — `--all` and `--all-prs` name the same word over different denominators

**Severity:** Minor
**Location:** `scripts/crb-subset-leaderboard.py:39-40`
**Move:** #2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a reader of the leaderboard's `Usage:` block deciding which scope they are asking for.

Precedent: `--all` meaning "the full 50-PR dataset" in `scripts/crb-materialize.py:223`

**Evidence:**
```python
    ap.add_argument("--all-prs", action="store_true",
                    help="rank over every PR in the file instead of our tool's subset")
```
against `scripts/crb-materialize.py:223`:
```python
    g.add_argument("--all", action="store_true", help="materialize all 50 PRs")
```
and the leaderboard's own usage line at `scripts/crb-subset-leaderboard.py:16`:
```python
  scripts/crb-subset-leaderboard.py --all-prs             # full 50-PR leaderboard
```

Stage 1 (finding 10) established that `--all-prs` is scoped to whatever is in the evaluations file, not to the full 50. The consistency angle is that `--all` in stage 1 does mean the dataset's 50, so a user reasonably reads `--all-prs` as the same denominator — and the script's own usage comment reads it that way too. The help text on the flag itself is accurate; the usage block contradicts it.

**Recommendation:** Fix the usage comment to `# every PR present in the evaluations file`, and consider renaming to `--all-judged-prs` so the flag name carries the scope.

---

#### F12 — `--no-seed` is the only negative flag in `scripts/`

**Severity:** Informational
**Location:** `scripts/crb-pipeline-to-benchmark.py:184-186`
**Move:** #2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a reader scanning `--help` for the flag that controls whether other tools get re-judged.

Precedent: affirmative store_true flags throughout — `--force` (`crb-materialize.py:229`, `prep-cc-review-clones.sh:30`), `--all-files`/`--include-plugins`/`--summary` (`claude_config_audit.py:197-199`), `--analyze-only`/`--dry-run` (`cross-model-review.py:376,388`)

**Evidence:**
```python
    ap.add_argument("--no-seed", action="store_true",
                    help="do NOT copy the benchmark's checked-in candidates/evaluations "
                         "(every tool then gets re-judged — ~50x the judge cost)")
```

Negative-flag naming means the safe behavior is the unnamed default and the expensive behavior needs a double negative to reason about (`not args.no_seed` → seed → cheap). Given that this flag is the single largest cost lever in the toolchain, the double negative is the wrong place to save a word. Not a violation of an *existing* pattern strongly enough to rank higher — the repo simply has no other negative flag, so this is establishing a convention rather than breaking one, and the help text is unusually explicit about the consequence, which mitigates it.

**Recommendation:** Optional. If touched, `--seed / --no-seed` via `argparse.BooleanOptionalAction` with `default=True` reads better and keeps the existing spelling valid.

---

#### F13 — `BUDGET` names the money knob that `scripts/` calls `--max-usd`; `MODEL`'s documented example is a floating alias while its default is a pinned id

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:55-62`, `:47`
**Move:** #2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** an operator who has previously driven `review-arms.py` or the E5/E7 runners.

Precedent: spend cap named `--max-usd` in `scripts/review-arms.py:128` and `scripts/cross-model-review.py:374`; exact-model-id discipline in `runs/review-arms/e7-fable-3x/run-host.sh:9` (`--model claude-fable-5 (exact ID …)`) and `:46` (`CC_VERSION="2.1.232" # pin for reproducibility`)

**Evidence:**
```bash
CC_VERSION="${CC_VERSION:-2.1.232}"   # pin for reproducibility; bump deliberately
PAYLOAD_REF="${PAYLOAD_REF:-main}"   # == feat/critic-evidence-discipline (merged, see header)
```
```bash
MODEL="${MODEL:-claude-fable-5}"
BUDGET="${BUDGET:-25.00}"
```
and the usage example at `:47`:
```bash
#   MODEL=opus BUDGET=10 ... run-host.sh                       # cheaper sweep
```

Two small deviations. (a) `BUDGET` is the per-instance USD cap passed to `--max-budget-usd`, but the repo's Python arms call the same concept `--max-usd`; `BUDGET_USD` or `MAX_USD` would carry the unit the way the neighbours do — a bare `BUDGET=10` is ambiguous between dollars and a token/turn count. (b) The usage example advertises `MODEL=opus`, a floating alias, whereas the default and every sibling arm use exact pinned ids specifically so `run-meta.json`'s `model` field is reproducible provenance (`:230-231` records `MODEL` verbatim). Stage-1 finding 16 already covers the cost-arithmetic consequence of the alias; the consistency consequence is that a sweep run from the documented example records an un-pinnable model id in its provenance file.

Making `CC_VERSION` overridable (E5/E7 hard-code it) is a reasonable evolution rather than a deviation, and the `${VAR:-default}` shape matches `REPS` at `e7:47` — no issue there.

**Recommendation:** Rename `BUDGET` → `BUDGET_USD` (keeping `BUDGET` as a fallback: `BUDGET_USD="${BUDGET_USD:-${BUDGET:-25.00}}"`), and change the usage example to an exact id such as `MODEL=claude-opus-4-5-20251101`.

---

#### F14 — `run-host.sh` supports only `ANTHROPIC_API_KEY` where the sibling runner supports two auth modes

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:96`
**Move:** #1 (baseline) / #7 (asymmetry)
**Confidence:** High
**Legibility-target:** an operator alternating between the E7 and CRB runners.

**Evidence:**
```bash
[ -n "${ANTHROPIC_API_KEY:-}" ] || { echo "ANTHROPIC_API_KEY not set" >&2; exit 1; }
```
against `runs/review-arms/e7-fable-3x/run-host.sh:62-79`, which resolves `CLAUDE_CREDENTIALS` first and falls back to `ANTHROPIC_API_KEY`, toggling `BARE_FLAG` accordingly.

The narrower surface is deliberate and justified in the header (`:40-41`: "API billing => result.json's total_cost_usd is authoritative billed spend, which is the point of using a key here") — for a benchmark row that will be published against 49 other tools, an authoritative bill beats a list-price estimate. Recording it only so the divergence is understood as a choice: an operator who has been running E7 on a subscription will hit `ANTHROPIC_API_KEY not set` and has no signal that subscription auth was excluded on purpose rather than not yet implemented.

**Recommendation:** No code change. Extend the error message to `ANTHROPIC_API_KEY not set (this arm is API-billing only by design — see header; CLAUDE_CREDENTIALS is not honored here)`.

---

## What Looks Good

- **The manifest contract is genuinely closed.** `crb-materialize.py:210-216` writes 14 keys; `run-host.sh:69-71` reads only the top-level slug keys; `crb-pipeline-to-benchmark.py:216,229` reads only `url` and `fork`. Both readers handle a missing manifest (`run-host.sh:64` hard-exits with a fix instruction; `crb-pipeline-to-benchmark.py:195` defaults to `{}`) and a stale one (`:213-220` skips a slug absent from the manifest *or* absent from `benchmark_data.json`, each with a distinct message). The comment at `crb-materialize.py:48-50` explaining why the manifest lives under tracked `runs/` rather than beside the gitignored clones is exactly the kind of "why" the repo's conventions call for.
- **Incremental manifest writes.** `crb-materialize.py:264-266` rewrites the manifest after every successful instance rather than once at the end, so an interrupted sweep leaves a valid partial manifest the next stage can consume — matching the benchmark's own periodic-save behavior at `step1_download_prs.py:322`.
- **The scrub-and-guard port is faithful.** `crb-materialize.py:176-196` reproduces `prep-cc-review-clones.sh:40-48` step for step, including the `--no-checkout` / checkout-`review`-before-`branch -f main` ordering (`:169-172`) with a comment explaining the failure it avoids.
- **Idempotent, resumable stages with a shared skip predicate.** `run-host.sh:138-144` reuses E7's `num_turns > 0` completed-cell test verbatim (`e7:120-125`), including the reasoning that a failed-auth run leaves `num_turns=0` and must not be skipped.
- **Cost-confinement is surfaced at every layer.** The `--tool` requirement appears in the module docstring (`crb-pipeline-to-benchmark.py:36-40`), in the emitted `RUN.md` with an inline "IS REQUIRED" comment (`:284-288`), in the terminal `Next:` block (`:298-301`), and in the setup doc (`:143-147`). For a flag whose omission costs thousands of paid calls, four redundant statements is correct design.
- **`--sections` is a well-chosen surface.** Lowercase aliases (`fix`/`address`/`consider`) map onto the rubric's title-case headers via `SECTION_ALIASES`, so the CLI does not force the user to quote `"Must Address"`, and the non-default selection announces itself (`:191-192`) so a variant run cannot be mistaken for the default one in a scrollback.
- **Nullability of `path`/`line` is documented where it is decided.** `parse_location`'s docstring (`:135-138`) states both that a miss returns `(None, None)` and why that is harmless (judging is text-only) — the question move #8 asks, answered at the point of the contract.
- **Preflight checks the failure that would be silent.** `run-host.sh:103-132` verifies not just auth but skill registration, and the comment names the specific prior incident (decision 022) that motivates it. `crb-subset-leaderboard.py:44-52` likewise fails fast with actionable messages (`run step 3 first`, `tool 'X' has no judged PRs`).
- **Naming inside each script is internally coherent:** snake_case fields, kebab-case flags, verb-phrase helpers, `RawDescriptionHelpFormatter` + `Usage:` docstring on all three CLIs, `UPPER_SNAKE` + `${VAR:-default}` on the shell surface.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `--tool-name` vs `--tool` across one toolchain | Inconsistent | `scripts/crb-pipeline-to-benchmark.py:170` | High |
| F2 | Judge parameterized upstream, hard-coded downstream | Inconsistent | `scripts/crb-subset-leaderboard.py:26` | High |
| F3 | `--judge` value shape diverges from sibling `--judge` flags | Inconsistent | `scripts/crb-pipeline-to-benchmark.py:56,249-253` | Medium-High |
| F4 | `--stats` vs the repo's `--dry-run` | Inconsistent | `scripts/crb-pipeline-to-benchmark.py:187` | High |
| F5 | Three behaviors for an unknown instance name | Inconsistent | `crb-materialize.py:104`, `crb-pipeline-to-benchmark.py:203`, `run-host.sh:136` | High |
| F6 | Relative `--out` resolves against CWD, not `WORKSPACE` | Minor | `scripts/crb-pipeline-to-benchmark.py:169,194` | High |
| F7 | `created_at` dropped from emitted `review_comments` | Minor | `scripts/crb-pipeline-to-benchmark.py:123-128,160` | High |
| F8 | `source_provenance` extends a third-party schema | Informational | `scripts/crb-pipeline-to-benchmark.py:227-233` | High |
| F9 | `sanitize_model` vs vendored `sanitize_model_name` | Minor | `scripts/crb-pipeline-to-benchmark.py:63` | High |
| F10 | `--per-repo 0` gives the wrong error | Minor | `scripts/crb-materialize.py:241` | High |
| F11 | `--all-prs` vs `--all` denominators | Minor | `scripts/crb-subset-leaderboard.py:16,39` | Medium |
| F12 | `--no-seed` is the only negative flag | Informational | `scripts/crb-pipeline-to-benchmark.py:184` | Medium |
| F13 | `BUDGET` vs `--max-usd`; `MODEL=opus` example vs pinned-id convention | Informational | `runs/review-arms/crb-pipeline/run-host.sh:47,55-62` | Medium |
| F14 | Single auth mode vs E7's two | Informational | `runs/review-arms/crb-pipeline/run-host.sh:96` | High |

---

## Overall Assessment

This is a well-built harness whose author clearly read the neighbouring code: the scrub-and-guard discipline, the completed-cell skip predicate, the docstring/`Usage:` shape, the env-tunable convention, and the manifest-as-provenance argument are all lifted correctly from `prep-cc-review-clones.sh`, the E5/E7 runners, and `canon-to-crb.py`. The inter-script data contract is the strongest part: `instances.json`'s writer and its two readers agree on field names, and both readers degrade sensibly on a missing or stale manifest.

The consistency problems are concentrated in the **CLI surface of the four-stage sequence**, not in the internals — which is the expected failure mode when four surfaces are written together and each is locally coherent but never read side by side as a single user session. F1 (`--tool-name` vs `--tool`) and F4 (`--stats` vs `--dry-run`) are the two a user meets first and most often; F2 (judge configurable at stage 3, hard-coded at stage 4) is the one most likely to waste real money or produce a "run step 3 first" error after step 3 already ran. All fourteen findings are fixable in place — none requires rethinking a design — and F1/F2/F4 together are perhaps twenty lines.

Consumer impact today is limited: every default path resolves correctly (Stage 1 verified the judge-directory chain, `--tool` confinement, and answer-key containment on the defaults), so an operator who runs the documented commands verbatim will get correct results. The exposure is entirely in the *off-default* paths — a different judge, a relative `--out`, a mistyped slug, `--per-repo 0`, `MODEL=opus` — which is precisely where a research harness ends up as soon as the pilot succeeds and someone starts varying conditions. Worth fixing F1–F5 before the first paid sweep, since flag renames are free now and become a documentation-drift problem once results docs cite the commands that produced them.

---

## Goal-Alignment Note
- Answered: yes — full API-consistency critique across all four CLI/env surfaces plus the three data contracts
- Out of scope: correctness/behavioral bugs (Stage 1's remit — its 16 findings were used as given, not re-verified); security and performance (other Stage-2 critics); no git-mutating verification was attempted, per the safety constraint, so all claims rest on read-only inspection of the working tree and the vendored benchmark
- Escalate: F2 is the only finding with a money consequence on a plausible path (a second judge produces evaluations the leaderboard's default cannot find) — worth pairing with Stage 1's finding 10 about the same constant when the orchestrator synthesizes. Stage 1's finding 3 (docstring at `crb-pipeline-to-benchmark.py:13-15` claiming step 3's table is "a real leaderboard", contradicted by `crb-subset-leaderboard.py:4-8`) is a doc-accuracy issue whose fix should land in the same edit as F1/F4, since all three touch that module's header.
