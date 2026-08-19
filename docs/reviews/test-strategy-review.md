# Test Strategy: CRB direction-1 harness (`feat/crb-direction1-harness`)

Commit: 529ecd2

**Scope:** `git diff main...HEAD` — `scripts/crb-materialize.py`, `scripts/crb-pipeline-to-benchmark.py`, `scripts/crb-subset-leaderboard.py`, `runs/review-arms/crb-pipeline/run-host.sh` (+1209 lines, zero test changes)
**Reviewed:** 2026-08-18
**Stance:** advisory (Stage 2 of 3, contextual critic — informs but does not block merge)

---

## Test Conventions

**Framework: bats only.** `test/` holds 30 bats suites; `test/skills/` holds format-contract suites; `test/scripts/` holds script-level suites. Runner is `scripts/run-tests.sh [--fast|--slow|--all]`, which dispatches on a mandatory `# @category fast|slow` tag comment in each `.bats` file.

**There is no Python test convention in this repo.** No `pytest.ini`, `pyproject.toml`, `setup.cfg`, `tox.ini`, or `conftest.py` exists; there are no `test_*.py` files. The nine Python scripts under `scripts/` are tested — where they are tested at all — *from bats, as subprocesses*. `test/cross-model-review-stage1.bats` is the reference pattern: it builds a throwaway git fixture in `setup_file()` under `$BATS_FILE_TMPDIR`, then invokes `scripts/cross-model-review.py --dry-run` and asserts on its output.

**Do not introduce pytest for this change.** Adding a Python test runner for ~680 lines of experiment tooling means a new dependency, a new CI entry point, and a second place where "did the tests pass?" is answered. Everything recommended below fits in bats invoking `python3`.

**Hermeticity is enforced, not aspirational.** `test/fixture-hermeticity.bats` runs `scripts/hermeticity-lint` over every suite: a suite whose code can spawn `claude`/`curl`/`gh`/`wget` must stub it via a PATH shim in `setup()` (see `test/round-log-functions.bats:24-27`) or carry `# @network: allowed — <reason>`. `run-host.sh` spawns `docker` and `npx`, so any suite touching it **must** shim both.

**Load-bearing constraint on fixtures:** `external/` is gitignored (`.gitignore:2`). Any test that reads `external/code-review-benchmark/offline/results/benchmark_data.json` is non-hermetic — it passes on this machine and fails on a fresh clone. This single fact rules out the end-to-end tests one would otherwise reach for first, and it is the main reason the plan below is small.

**Golden-fixture precedent exists and is directly reusable.** `test/skills/code-review/rubric-current-format.md` is a checked-in rubric in the current format, maintained in lockstep with `skills/code-review/SKILL.md` by `test/skills/code-review-format-contract.bats`. It contains all seven rubric sections including `## ↩️ Considered Overrides`. This is the highest-leverage asset available to this plan: the injector's parser can be tested against the *same* artifact that guards the emitter, closing the contract from both ends at near-zero marginal cost.

---

## Untested Paths Touched by the Change

Nothing in this diff is covered by any existing test. The enumeration below is therefore restricted to paths where a silent failure changes a *measurement* or destroys *containment* — the two things this harness exists to produce.

### G1 — the finding-section filter is a substring match that `Considered Overrides` passes

**Severity:** High
**Location:** `scripts/crb-pipeline-to-benchmark.py:103`
**Evidence:**
```python
FINDING_SECTIONS = ("Must Fix", "Must Address", "Consider")
...
        if not any(s.lower() in section.lower() for s in sections):
            continue
```
`"consider" in "↩️ considered overrides"` is `True`. The section is excluded only by the next guard — `idx.get("finding")` returns `None` because the override table's column is named `Prior finding`, not `Finding` (`test/skills/code-review/rubric-current-format.md:48`). A one-word rename of that column in `skills/code-review/SKILL.md:1142` starts injecting *waived* findings as benchmark candidates, every one of which scores as a false positive. Nothing fails when that happens. — not covered

**Confidence:** High — verified by reading both the filter and the golden fixture's header row.
**Legibility-target:** a reader should be able to see the exclusion asserted by name, rather than inferring it from a column-name coincidence two files away.

### G2 — `--sections fix address` silently changes which rows are emitted, with no assertion on the count

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:190-192`
**Evidence:**
```python
    sections = [SECTION_ALIASES[s] for s in args.sections]
    if set(sections) != set(FINDING_SECTIONS):
        print(f"Rubric sections: {', '.join(sections)}")
```
The red+amber scoring variant is the whole reason `--sections` exists (`:178-183` documents the 16-vs-9 split). The mapping alias → section title → rows-emitted is verified today only by the author having eyeballed "16 findings, 9 with `--sections fix address`" once, recorded in prose at `docs/working/crb-direction1-setup.md:190-191`. — not covered

**Confidence:** High
**Legibility-target:** the 16/9 numbers in the setup doc should be produced by a test, not by a remembered console session.

### G3 — `md_tables()` section tracking resets on any `#` line, including sub-headings inside a section

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:75-80`
**Evidence:**
```python
        if line.startswith("#"):
            if header and rows:
                yield section, header, rows
            header, rows = None, []
            section = line.lstrip("#").strip()
            continue
```
Any `###` sub-heading between a section title and its table reassigns `section`, so the table is attributed to the sub-heading. `#` inside a fenced code block is likewise treated as a heading — there is no fence tracking. Rubrics from a real headless run are model-authored and not guaranteed to match the fixture's flat shape. A misattributed table is dropped silently, deflating recall. — not covered

**Confidence:** Medium — the failure requires a rubric shape the fixture does not exhibit; whether real runs produce one is unknown until the pilot.
**Legibility-target:** the parser's tolerance envelope should be written down as cases, so a pilot rubric that falls outside it is diagnosed in seconds rather than mistaken for a low-recall result.

### G4 — `load_cell()` picks `rubrics[0]` from a glob when a run wrote more than one rubric

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:149-150`
**Evidence:**
```python
    rubrics = sorted(cell_dir.glob("artifacts/**/*rubric*.md"))
    if source in ("auto", "rubric") and rubrics:
        md = rubrics[0].read_text(errors="replace")
```
The harvest step (`run-host.sh:193-199`) copies *every* new `.md` under the clone. If the pipeline writes a rubric plus, say, a per-critic rubric fragment, alphabetical order decides which one is scored. The `--stats` output prints the chosen provenance string, so this is detectable — but only if someone reads it. — not covered

**Confidence:** High on the mechanism; Medium on whether multi-rubric runs occur.
**Legibility-target:** ambiguity should be an error or a warning, not a silent alphabetical tiebreak.

### G5 — silent fallback from rubric to raw result text produces a single-comment "review"

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:157-161`
**Evidence:**
```python
    review = cell_dir / "review.md"
    if review.exists() and review.read_text(errors="replace").strip():
        text = review.read_text(errors="replace")
        return ([{"path": None, "line": None, "body": text}],
                "result-text (no rubric artifact)" if source == "auto" else "result-text")
```
Under `--source auto` (the default), a run whose rubric failed to parse is injected as *one* comment containing the entire result text. The benchmark's step-2 extractor will split that into candidates on its own terms, producing a materially different candidate set than the rubric path — and the arm's headline number would silently be measuring a different thing for that instance. The provenance string is the only tell. — not covered

**Confidence:** High
**Legibility-target:** any results table must be able to state, per instance, which path was taken; a test pins that the two paths are distinguishable in the manifest, not just in stdout.

### G6 — `family()`'s `split("-")[0]` is the stratification key and will merge unrelated repos

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:98`
**Evidence:**
```python
    return source_repo.split("-")[0]
```
This is what makes `--per-repo 1` yield 5 PRs rather than 7 (it folds `discourse-graphite`, `sentry-greptile`, `keycloak-greptile` into their parents). It is a heuristic over free-text repo names: any future dataset entry named `grafana-loki` would be folded into `grafana` and lose its own pilot slot, and the pilot's N would change without anyone noticing. — not covered

**Confidence:** High
**Legibility-target:** "the pilot is 5 PRs, one per project" is a claim about a string-splitting heuristic; it should be asserted against the real repo-name list.

### G7 — `select()` accepts a negative `--per-repo` and silently drops instances

**Severity:** Low
**Location:** `scripts/crb-materialize.py:121`
**Evidence:**
```python
        sel.extend(ranked[: args.per_repo])
```
`--per-repo -1` slices `ranked[:-1]`, selecting all-but-the-most-golden PR per family — the exact inverse of the documented intent ("the N PRs with the most golden comments in each source repo", `:111-113`). `--per-repo 0` is caught by accident: it is falsy, so `:241` routes it to `ap.error`. Neither value is validated. — not covered

**Confidence:** High
**Legibility-target:** cheap to close; listed mainly so it is not rediscovered as a mystery selection.

### G8 — the answer-key containment guards are never exercised against a clone that violates them

**Severity:** High (consequence), Low (likelihood of a *code* regression)
**Location:** `scripts/crb-materialize.py:186-196`
**Evidence:**
```python
    # Guard (a): nothing reachable outside the reviewed head's ancestry.
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
    stray_n = len([l for l in stray.splitlines() if l])
    if stray_n:
        raise RuntimeError(f"{slug}: {stray_n} stray commit(s) survived the scrub")
```
This is the control that makes every downstream number meaningful: if the merged upstream fix is reachable, the reviewing agent can read the answer key and the whole arm is invalid. The guards have been run against 5 real clones that *passed* (`docs/working/crb-direction1-setup.md:188-189`); they have never been run against a clone that should *fail*. A guard that has only ever returned green is an untested guard. Guard (b) additionally does not check what its comment claims — the docstring says blobs are verified present, but `rev-list --count` plus `diff --shortstat` do not establish that. — not covered

**Confidence:** High that the guards are unexercised in the negative direction; High that the blast radius is total.
**Legibility-target:** a results doc should be able to cite a test showing the guard *fires*, not only that it stayed quiet.

### G9 — the preflight auth check does not match the failure string it was written for

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:126`
**Evidence:**
```bash
#  (a) bad credential — the CLI exits 0 with result "Not logged in" (E7 note);
...
if d.get("num_turns", 0) < 1 or "log in" in r.lower():
    sys.exit(f"  auth failed: {r[:200]!r}")
```
`"not logged in".lower()` contains `"logged in"`, not `"log in"`. The documented failure mode passes the check. The `num_turns` clause may or may not catch it — per the repo's own note in memory, judge runs are gated on `num_turns` precisely because exit codes are unreliable, and an auth-failed response can still report a turn. The consequence is the one the comment names: an entire sweep runs and bills against a broken credential, or worse, produces empty reviews that score as zero-recall. This is a defect a five-line test over canned JSON would have caught before it was written down as a safeguard. — not covered

**Confidence:** High — string mismatch is mechanical and independently found by Stage 1 (finding 4).
**Legibility-target:** the three preflight verdicts (auth-fail, skills-unregistered, OK) should each have a named canned-JSON case.

### G10 — the skill-registration preflight matches a substring that other skill names contain

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:128-130`
**Evidence:**
```bash
if "code-review" not in r:
    sys.exit("  payload skills NOT registered — the run would measure the "
             f"built-in reviewer, not the pipeline. Model said: {r[:300]!r}")
```
This is called out at `:106-108` as the check that exists because a prior arm silently measured the wrong thing (decision 022). But the payload also ships `code-review-gate`-adjacent material, and a model listing built-in capabilities may well emit the phrase `code review`/`code-review` without the payload skill being registered. A false green here mislabels an entire arm. — not covered

**Confidence:** Medium — depends on model phrasing, which is exactly why it should not be trusted unasserted.
**Legibility-target:** same suite as G9; the negative case ("model lists other skills but not ours") must fail.

### G11 — `git clean -qfd` without `-x` leaks gitignored state between instances

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:200-201`
**Evidence:**
```bash
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```
The comment at `:151-153` promises "re-runs start from the same state." Without `-x`, anything matching the upstream repo's `.gitignore` — build output, caches, and notably any `docs/reviews/` path an upstream repo happens to ignore — survives into the next instance's review context. Both commands are `|| true`, so a failure to reset is invisible. Instance *n+1* is then reviewing a tree instance *n* modified, which breaks the independence the one-sample-per-cell design assumes (`docs/working/crb-direction1-setup.md:184`). — not covered

**Confidence:** High on the mechanism (Stage 1 finding 7 concurs); Medium on how much ignored output the pipeline actually writes.
**Legibility-target:** "the tree is reset between instances" is an invariant of the experiment, and should be checkable without a real sweep.

### G12 — the harvest path parser breaks on renames and on paths containing spaces

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:194-199`
**Evidence:**
```bash
  (cd "$clone" && git status --porcelain --untracked-files=all) \
    | awk '{print $2}' | grep -E '\.(md|json)$' \
```
`awk '{print $2}'` takes the second whitespace-separated field: for `R  old.md -> new.md` that is `old.md` (which no longer exists, so the `cp` silently `|| true`s away), and for any path with a space it is a fragment. `--untracked-files=all` correctly avoids the directory-collapse problem, so untracked new files *are* enumerated. The failure is confined to artifact loss, not to measurement corruption — but a lost rubric routes that instance to the G5 result-text fallback. — not covered

**Confidence:** High on the parsing behaviour; Low on how often benchmark repos produce such paths.
**Legibility-target:** low priority; recorded so the G5 fallback's causes are enumerable.

### G13 — the subset leaderboard aggregates tools over non-identical PR subsets

**Severity:** Medium
**Location:** `scripts/crb-subset-leaderboard.py:55-65`
**Evidence:**
```python
    for url in urls:
        for tool, res in evals[url].items():
            if res.get("skipped"):
                continue
            a = agg.setdefault(tool, {"tp": 0, "fp": 0, "fn": 0, "n": 0, "cand": 0, "gold": 0})
```
The script's entire justification (`:4-8`) is that comparing a 5-PR row against a 50-PR row is "different denominators, not a ranking." But within the chosen subset, a comparison tool that is missing or `skipped` on one of our PRs is still ranked — micro-averaged over 4 PRs while we are averaged over 5 — and is not excluded or flagged beyond the `PRs` column. The bug the script exists to prevent can reappear inside the script's own output. — not covered

**Confidence:** High that the code permits it; Medium that the checked-in evaluations actually contain such holes.
**Legibility-target:** the leaderboard should make an uneven row impossible to read as even; a test pins whichever behaviour is chosen.

### G14 — the scripts hardcode absolute input paths, so no hermetic end-to-end test is possible

**Severity:** Medium (testability, not correctness)
**Location:** `scripts/crb-pipeline-to-benchmark.py:50-55`
**Evidence:**
```python
WORKSPACE = Path(__file__).resolve().parent.parent
BENCH = WORKSPACE / "external/code-review-benchmark/offline"
BENCH_DATA = BENCH / "results/benchmark_data.json"
...
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
```
`--runs` and `--out` are flags; `BENCH_DATA` and `MANIFEST` are not. `crb-materialize.py:45-51` is the same shape. Because `external/` is gitignored, any test of the injector's *CLI* rather than its *functions* depends on machine-local state and will fail on a fresh clone — colliding with the repo's enforced hermeticity gate. — not covered

**Confidence:** High
**Legibility-target:** two `argparse` flags with the current constants as defaults would convert G1/G2/G5/G13 from function-level tests into cheap CLI-level tests. Whether that is worth doing is a judgement call, stated in the summary.

---

## Recommended Tests

Four suites, ranked. Total estimated effort: **~3 hours**, of which the first suite is ~45 minutes and carries most of the value.

#### 1. `comments_from_rubric()` against the golden rubric fixture

**Closes gaps:** G1, G2, G3, G5
**Type:** contract (golden fixture) + unit
**Priority:** high
**File:** `test/skills/crb-rubric-injection.bats` — sited in `test/skills/` deliberately, next to `code-review-format-contract.bats`, because this is the *consumer* half of the same rubric contract.

**What it verifies:** that the injector, run over the checked-in rubric format spec, emits exactly the finding rows and no waived or advisory-good rows — and that this remains true only for as long as the emitter's format does.

**Key cases:**
- Feed `test/skills/code-review/rubric-current-format.md` to `comments_from_rubric` with default sections → the returned bodies include rows from `🔴 Must Fix`, `🟡 Must Address`, `🟢 Consider`, and **zero** rows sourced from `↩️ Considered Overrides` or `✅ Confirmed Good`. **Assert the override exclusion explicitly and by name** — this is the G1 test, and it must fail if `skills/code-review/SKILL.md:1142` renames `Prior finding` to `Finding`.
- Same fixture with `sections=["Must Fix","Must Address"]` → strictly fewer comments than the default run, and no body drawn from the `🟢 Consider` table. (G2)
- A small inline rubric string with a `###` sub-heading between `## 🟡 Must Address` and its table → assert the current behaviour, whatever it is, so the tolerance envelope is documented rather than discovered mid-pilot. (G3)
- A rubric with a `🔴 Must Fix` table whose only column is `Note` (no `Finding`) → `comments_from_rubric` returns `[]`, and `load_cell` under `source="auto"` therefore falls back to `review.md`, returning provenance beginning `result-text`. Assert the provenance string, not just the comment count. (G5)
- `parse_location("\`proxy.ts:57\` (also \`:52-63\`)")` → `("proxy.ts", 57)`; `parse_location("—")` → `(None, None)`. Two lines, and they pin the documented example in the docstring.

**Setup needed:** none beyond bats. Load the module by path (`importlib.util.spec_from_file_location`) inside a `python3 - <<'EOF'` heredoc, because the filename's hyphens block a plain `import`. No network binaries are reachable, so no PATH shim and no `@network` annotation are required. Tag `# @category fast`.

**Why this is first:** it is the only recommendation that closes a *measurement-integrity* gap using an asset that already exists, with no new fixture to maintain and no risk of drift — the fixture is already kept current by an existing suite.

#### 2. `run-host.sh` preflight verdicts over canned JSON

**Closes gaps:** G9, G10
**Type:** unit
**Priority:** high
**File:** `test/crb-run-host-preflight.bats`

**What it verifies:** that each of the preflight parser's three verdicts fires on the input it was written for.

**Key cases:**
- `{"num_turns": 1, "result": "Not logged in"}` → **must exit non-zero**. This case fails against the code as written (G9); it is the reason to write the suite.
- `{"num_turns": 0, "result": ""}` → exits non-zero with `auth failed`.
- `{"num_turns": 3, "result": "fact-check, security-reviewer, test-strategy"}` → exits non-zero with `payload skills NOT registered`. (G10 — a plausible model reply that lists real skills but not ours.)
- `{"num_turns": 3, "result": "code-review, fact-check, security-reviewer"}` → exits zero, prints `preflight OK`.
- Non-JSON input (e.g. a docker error message) → exits non-zero with `not JSON`.

**Setup needed:** **Extract the heredoc at `run-host.sh:119-132` into `runs/review-arms/crb-pipeline/preflight-check.py`** and have the shell call it. This is a ~4-line refactor and it is what makes the surface testable at all — a heredoc inside a `for`-less prologue cannot be invoked in isolation. The test then runs `python3 preflight-check.py <fixture.json>` and asserts status and message. Fixtures are inline `printf` into `$BATS_TEST_TMPDIR`. No docker, no npx, no network — the extraction is precisely what keeps this suite hermetic. Tag `# @category fast`.

**Note:** fix G9 in the same commit (`"logged in" in r.lower()`, or better, match both spellings). A test that documents a known-broken guard without fixing it is worse than neither.

#### 3. `slug_for()` / `family()` / `select()` over the real repo-name list

**Closes gaps:** G6, G7
**Type:** unit (property-flavoured)
**Priority:** medium
**File:** `test/scripts/crb-materialize-selection.bats`

**What it verifies:** that the pilot's shape — "5 PRs, one per project" — is a consequence the code produces, not a coincidence someone observed once.

**Key cases:**
- `family()` over a hardcoded inline list of the 5 project names plus the 3 mirror-split names → exactly 5 distinct families, with `discourse-graphite`→`discourse`, `sentry-greptile`→`sentry`, `keycloak-greptile`→`keycloak` asserted individually. **Inline the repo-name list in the test**; do not read `benchmark_data.json`, which is gitignored (G14). If the dataset later changes, the test failing is the correct outcome — it means the stratification claim needs re-checking.
- `slug_for("keycloak__keycloak__claude-code__PR37429__20260310")` → `"keycloak-PR37429"`; a name with a `.` in the PR field → `.` becomes `_`; a 3-part name → raises `ValueError`.
- `select()` on synthetic PR tuples with `--per-repo 1` → picks the highest-golden-count entry per family, ties broken on slug ascending. One test with a deliberate tie.
- `--per-repo -1` → currently selects all-but-one. Add the two-line validation (`if args.per_repo is not None and args.per_repo < 1: ap.error(...)`) and assert the error. (G7)

**Setup needed:** same `importlib` heredoc pattern as suite 1. `# @category fast`.

#### 4. Containment-guard logic, tested *without* a repository

**Closes gaps:** G8
**Type:** unit
**Priority:** medium
**File:** `test/scripts/crb-materialize-guards.bats`

**What it verifies:** that the stray-commit guard raises when `git rev-list --all --not <head>` returns output, and that the empty-range guard raises when the range is empty — plus that `--shortstat` parsing is correct for the shapes git actually emits.

**Key cases:**
- Guard (a) raises when the (stubbed) `rev-list` returns two SHAs; passes when it returns empty; passes when it returns a single blank line (the `if l` filter at `:188`).
- Guard (b) raises on `n_commits == 0`; raises on an empty `--shortstat` string; passes on `1 file changed, 3 insertions(+)`.
- Shortstat parsing: `"2 files changed, 10 insertions(+), 4 deletions(-)"` → `(2, 10, 4)`; `"1 file changed, 1 deletion(-)"` → `(1, 0, 1)` (insertions absent — the common shape, and the one the `elif` chain at `:198-206` must not mis-bin).

**Setup needed — and this is the crux.** **Do not build a git fixture for this.** The failure that destroyed this repository's refs earlier in this run came from exactly this shape of test: a scratch repo, a `cd` that could fail, and unconditional `git update-ref -d` / `reflog expire` / `gc` lines that then executed against the real working tree. The scrub block at `crb-materialize.py:176-184` contains those three commands verbatim; any fixture-based test of it is one unset variable away from repeating the incident.

Instead: **stub `git` on `PATH`** (the repo's own hermeticity convention, `test/round-log-functions.bats:24-27`) and drive `materialize()`'s guard arithmetic through the stub's canned stdout. The stub is a shell script that echoes a fixture string per subcommand and never touches a repository. This tests the guard *logic* — which is what a code regression would break — while the guard's *empirical* behaviour on real forks stays covered by the five clones already materialized and verified. That split is the right one: logic is cheap and safe to test, git semantics are expensive and dangerous to test, and the dangerous half already has evidence.

If a real-repo integration test is ever wanted, it belongs in a container with no bind mount of `/workspace`, not in bats. That is out of scope for this change.

---

## What NOT to Test

**The docker/npx sweep loop (`run-host.sh:134-214`).** An integration test would have to stub `docker`, `npx`, `git`, and `date`, at which point it asserts the shape of the stub rather than the behaviour of the sweep. The real verification is the author's stated plan — run one instance (`keycloak-PR36880`, smallest diff) and read `review.md` plus `artifacts/` before launching (`docs/working/crb-direction1-setup.md:199-201`). That is the correct control for this risk, and it is already written down. G11 and G12 live inside this loop; both are worth *fixing* (`clean -qfdx`; `awk` → `git status -z` or `cut -c4-`) but not worth a suite.

**Live-network paths of any kind.** `git clone` against `github.com/code-review-benchmark`, the Anthropic judge endpoint, `npx` package resolution. Non-hermetic by construction; the gate would reject them.

**Anything reading `external/code-review-benchmark/`.** Gitignored (G14). Every recommendation above inlines its fixtures for this reason.

**`crb-subset-leaderboard.py`'s arithmetic (`:69-71`).** Four lines of precision/recall/F1 with guarded zero-denominators. The blast radius of a bug is a visibly absurd number in a table a human reads, not a silent wrong answer. G13 (uneven subsets) is the real issue in that file and is a *design* question — decide whether to exclude or flag uneven tools — not a coverage question. **Escalating rather than testing.**

**The `--dry-run` / `--stats` / `DRY_RUN=1` paths as such.** Tempting, because they are already the manual verification mechanism. But asserting on their stdout couples the tests to print formatting, which is the most churn-prone surface in a script like this — brittle tests that break on every message tweak are worse than none. The exception is `--stats`' provenance string, which suite 1 asserts as a *value*, not as a formatted line.

**`dir_mb()`, `sanitize_model()`, `f1()`.** Trivial; a bug is self-evident on first use.

---

## Coverage Gaps Beyond Current Scope

**1.** The rubric-format contract is currently one-directional. `test/skills/code-review-format-contract.bats` guards the emitter against the golden fixture, but nothing guards any *consumer* of that format. This diff adds the first consumer. Recommendation 1 closes it for this consumer; if further consumers appear (a scorer, a ledger importer), the pattern should be generalized rather than copy-pasted.

**2.** No repo-wide convention exists for testing Python scripts, and there are now nine of them under `scripts/`. Two (`cross-model-review.py`, and after this plan `crb-materialize.py`) are tested from bats by two different idioms — subprocess-CLI in one case, `importlib` heredoc in the other. A three-line `test/lib/py-module.bash` helper exporting a `py_load <script>` function would make the second idiom uniform and is worth doing the first time a third script needs it.

**3.** `scripts/canon-to-crb.py`, `scripts/review-arms.py`, and `scripts/dd-cross-model-sweep.py` are adjacent measurement tooling with no tests at all. Not this PR's problem, but the same "silent wrong number" risk class applies, and the same bats+`importlib` pattern would serve.

---

## Summary

The highest-value test in this plan is **suite 1**: running `comments_from_rubric()` over `test/skills/code-review/rubric-current-format.md` and asserting that `↩️ Considered Overrides` rows are never emitted. It costs under an hour, needs no new fixture, and closes the one gap where a plausible future edit — renaming a rubric column — silently converts *waived* findings into benchmark false positives with no other symptom. **Suite 2** is a close second and is unusual in that it will fail on first run: the preflight's `"log in"` test does not match the `"Not logged in"` string its own comment cites, so a broken credential can consume a full sweep. Fix that in the same commit as the test.

I am deliberately recommending a small plan. This is experiment tooling with one expert user and a finite lifetime; most of it is verified adequately by the author's `--dry-run`/`--stats`/one-instance-pilot discipline, which is already documented honestly at `crb-direction1-setup.md:186-203`. What that discipline *cannot* catch is the class of change that alters a number without altering an observable behaviour — the section filter, the section aliases, the stratification key. That class, and only that class, is what the four suites above target.

The main residual risk after executing this plan is unchanged and correctly left to the pilot: whether headless Claude Code registers payload skills from a mounted `~/.claude`. No offline test can answer it. The second residual risk is answer-key containment (G8) — suite 4 tests the guard's logic but not git's semantics, which is the right trade given that a fixture-based version of that test is the same construct that destroyed this repository's refs earlier in this run. Two open questions the enumeration surfaced, neither blocking: should an uneven comparison tool be excluded from the subset leaderboard or merely flagged (G13), and should `BENCH_DATA`/`MANIFEST` become flags so the CLI surfaces become hermetically testable (G14)?

## Goal-Alignment Note
- Answered: yes — named-gap plan with 14 gaps, 4 prioritized suites, explicit non-recommendations
- Out of scope: the docker sweep loop, all live-network paths, and anything reading gitignored `external/` — all non-hermetic under this repo's enforced gate; also the G13 uneven-subset question, which is a design decision rather than a coverage gap
- Escalate: (a) G9 preflight string mismatch is a live defect, not just untested — fix `"log in"` → `"logged in"` before any sweep; (b) G13 needs a decision from the author on exclude-vs-flag; (c) extracting `run-host.sh:119-132` into `preflight-check.py` is a prerequisite for suite 2 and touches the runner, so it should be sequenced with any other run-host edits
