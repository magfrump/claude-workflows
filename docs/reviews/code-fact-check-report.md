# Code Fact-Check Report — CRB direction-1 harness, review-fix pass 2

**Repository:** /workspace (branch `feat/crb-direction1-harness`)
**Scope:** `git diff 529ecd2..ed68ced` — the review-fix commit only. `529ecd2` and the two docs-only siblings (`ae3362b` rubric, `92749ff` pre-mortem) are context, not under review.
**Checked:** 2026-08-18
**Commit:** ed68ced
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 20
**Summary:** 14 Verified, 5 Mostly accurate, 1 Incorrect. Every numeric figure in the commit message and in `docs/working/crb-direction1-setup.md` re-derived from `external/code-review-benchmark/offline/results/` matched exactly (24/50, 1–9, 28/49, 4/5, 216, 166, 50, 2233, 2449, 173, max 9). The two red items (R1 preflight, R2 containment) are real and non-vacuous — all five pilot clones pass `--verify`, and the 6→7 pre-fix regression is reproducible. Three defects found that the commit's own claims overstate: the **post-run containment failure does not actually void the cell** (it warns, and the cell is then banked as complete on the next resume — the single highest-consequence gap, since it lets a poisoned cell into the results); the **`api.anthropic.com` endpoint guard is an unanchored substring glob**; and the **`num_turns > 0` half of the resume predicate misclassifies ~31% of this repo's historical successful cells as failures**, causing paid re-runs. One pre-existing (not introduced) `set -e` + `grep` interaction still aborts the whole sweep when a cell produces no `.md`/`.json` artifact.

---

## Claim 1: preflight tests both "log in" and "logged in"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:127-135`; prior art `runs/review-arms/e7-fable-3x/run-host.sh:88,103`
**Type:** Behavioral / commit-message claim (R1)
**Verdict:** Verified
**Confidence:** High
**Evidence:** The new code reads `low = r.lower()` then `if d.get("num_turns", 0) < 1 or "log in" in low or "logged in" in low:` (`run-host.sh:132-134`). The cited prior art is accurate to the line: `e7-fable-3x/run-host.sh:88` documents `# result "Not logged in · Please run /login" and num_turns=0 (learned the hard`, and `:103` is `sys.exit(0 if d.get("num_turns", 0) > 0 and "log in" not in r.lower() and "logged in" not in r.lower() else 1)`. Against the documented E7 string `"Not logged in · Please run /login"`, `"logged in"` matches the first clause and `"log in"` matches `/login`'s tail — so both clauses fire, and the string is caught even if `num_turns` were nonzero. Note the two arms' polarity differs (E7 asserts the *pass* condition, this arm asserts the *fail* condition) but the truth table is equivalent.
**Legibility-target:** author

---

## Claim 2: `verify_containment()` is extracted and re-asserted before and after every cell

**Location:** `scripts/crb-materialize.py:167-194`; call sites `run-host.sh:177-178` (pre) and `:236-237` (post)
**Type:** Structural / behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** The function exists with the claimed signature — `def verify_containment(dst: Path, slug: str, head: str = None):` (`crb-materialize.py:167`) — and `materialize()` now calls it in place of the inlined guards: `n_commits, stat = verify_containment(dst, slug, head)` (`crb-materialize.py:233`). Both call sites exist. The pre-run one skips the cell: `python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {` / `echo "$id: PRE-RUN containment check failed — skipping cell" >&2; continue; }` (`run-host.sh:177-178`). The post-run one warns only: `|| echo "$id: POST-RUN containment check FAILED — treat this cell's result as void" >&2` (`run-host.sh:236-237`).

Three qualifications:

1. **"Void" is not enforced — this is the finding that matters.** Nothing marks the cell. `result.json` has already been written at `run-host.sh:215` (`json.dump(res, open(sys.argv[2], "w"))`), and on the next invocation the resume predicate at `:150-156` will see `subtype == "success"` and `num_turns > 0` and print `"completed result exists, skipping"`. A cell whose containment broke is therefore banked as good and silently flows into `crb-pipeline-to-benchmark.py`. `docs/working/crb-direction1-setup.md:98` states "a post-run failure marks that cell's result void", which the code does not do. The stderr line is the only trace, and an unattended `--all` sweep's stderr is not read.
2. **The pre-run `continue` leaks `$INST_HOME`.** `INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"` runs at `run-host.sh:168`, before the guard at `:177`; the matching `rm -rf "$INST_HOME"` is at `:195`, after it. Each skipped cell leaks one full payload copy in `$TMPDIR`. Cost is disk, not correctness.
3. **The pre-run `continue` also skips the sweep-budget gate** at `:254-267`. Benign: a skipped cell spends nothing, and the gate is only meaningful after spend.

On `--verify` pinning: the manifest head *is* used where present — `head = (manifest.get(slug) or {}).get("head")` (`crb-materialize.py:283`). For a slug absent from the manifest, `head` is `None` and `verify_containment` falls back to `head = sh(["git", "rev-parse", "review"], cwd=dst)` (`crb-materialize.py:181`), making the stray-commit check self-referential — a moved `review` ref would pass against its own new tip. This is reachable: `run-host.sh:71` sets `INSTANCES=("$@")` from positional args, so an operator can pass a slug the manifest does not carry. The docstring's hedge "where we have it" is honest, but the failure mode is silent rather than loud. Related, smaller: `n_commits`/`stat` are computed from the live `main..review` refs (`crb-materialize.py:189-190`), not from the pinned head, so a `main` ref moved to an ancestor changes the reported range without tripping the stray check.
**Legibility-target:** author

---

## Claim 3: containment also fails if any remote survives

**Location:** `scripts/crb-materialize.py:185-188`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Evidence:** `remotes = sh(["git", "remote"], cwd=dst)` then `if remotes:` raising `RuntimeError(f"{slug}: remote(s) present ({remotes.split()!r}) — "` `"answer-key containment is broken")` (`crb-materialize.py:185-188`). Parsing is sound: `sh()` returns `(r.stdout or "").strip()` (`crb-materialize.py:69`), and `git remote` with no remotes emits nothing, so the stripped result is `""` → falsy. Confirmed empirically on the clones: `git -C /workspace/external/crb-eval/cal_com-PR11059 remote` printed nothing (`remotes:[]`), same for `grafana-PR79265`. Remote names cannot contain whitespace in a way that would defeat truthiness, and the value is used only for the error message, never re-parsed for control flow.
**Legibility-target:** author

---

## Claim 4: "Verified non-vacuous: passes on all pilot clones, fires correctly when a remote is added"

**Location:** commit message R2; `scripts/crb-materialize.py:270-292`
**Type:** Empirical claim
**Verdict:** Mostly accurate
**Confidence:** High (first half), Medium (second half)
**Evidence:** First half re-run and confirmed. `python3 /workspace/scripts/crb-materialize.py --verify cal_com-PR11059 discourse-graphite-PR4 grafana-PR79265 keycloak-PR36880 sentry-greptile-PR5` exits 0 with, e.g., `  grafana-PR79265: containment ok — 5 commit(s), 11 files changed, 105 insertions(+), 37 deletions(-)` and `  keycloak-PR36880: containment ok — 1 commit(s), 1 file changed, 3 insertions(+), 3 deletions(-)`. All five manifest slugs have clones under `external/crb-eval/`, and the check is read-only (`--verify` returns before `load_prs()`/`select()`/`materialize()` at `crb-materialize.py:292`).

Second half assessed by reading only, per the safety constraint — *paraphrased — no quote available because constructing a repo with an added remote is a git fixture and is out of bounds for this pass*. By inspection the fire path is sound: an added remote makes `git remote` non-empty → `RuntimeError` → caught by `except Exception as e:` at `crb-materialize.py:285` → `bad.append(slug)` → `sys.exit(f"containment check failed for: ...")` at `:291`, a non-empty string, which Python maps to exit status 1, which is what `run-host.sh:177`'s `||` tests. The chain is complete; I did not execute it.
**Legibility-target:** author

---

## Claim 5: SWEEP_BUDGET (default $75) caps the whole sweep, re-summed per cell

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:62,251-267`
**Type:** Behavioral / cost-control
**Verdict:** Verified
**Confidence:** High
**Evidence:** Default is `SWEEP_BUDGET="${SWEEP_BUDGET:-75.00}"` (`run-host.sh:62`). The gate is `python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }` (`run-host.sh:254`), with the heredoc body re-summing from disk (`for name in os.listdir(out): ... total += json.load(open(rp)).get("total_cost_usd") or 0`, `:258-262`) and `sys.exit(1 if total >= cap else 0)` (`:266`).

Each mechanical sub-question checks out. (a) The `|| { ...; exit 2; }` does trigger on the Python exit code — `sys.exit(1)` gives status 1, and the `||` branch runs. (b) `set -euo pipefail` (`run-host.sh:52`) does not kill the script first: a command on the left of `||` is explicitly exempt from errexit, so the handler runs and `exit 2` terminates the whole script (not just the loop body) as intended. (c) Placement: the gate is the last thing **inside** the `for id in "${INSTANCES[@]}"` loop, before `done` at `:268` — so it is inside the loop and runs **after** the cell it gates.

That last point means the gate cannot prevent the *current* cell's spend, only the next one — exactly what the comment concedes: `# Checked after every cell, so the worst overshoot is one instance.` (`run-host.sh:64`). Two `continue` paths (`:158` completed-cell skip, `:178` containment skip) bypass the gate, but neither spends money, so the one-instance overshoot bound holds even on a resumed sweep. The `$75` default is flagged as a guess in the commit message's own Confidence line, which is honest.
**Legibility-target:** author

---

## Claim 6: resume predicate requires success, not just num_turns > 0

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:150-159`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** The predicate is now `ok = (d.get("num_turns", 0) > 0` / `      and not d.get("is_error")` / `      and d.get("subtype", "success") == "success")` (`run-host.sh:153-155`).

**The intended case is genuinely fixed.** Surveying every tracked `result.json` in the repo, exactly one cell is a budget-exhausted run and it carries `('e7-fable-3x', 'error_max_budget_usd', is_error=True, num_turns>0)`. The old turns-only predicate banked it; the new one rejects it on both the `is_error` and `subtype` clauses. This is the A2 scenario, reproduced from real data.

**But the retained `num_turns > 0` clause is now the weak link, in the expensive direction.** The same survey shows 10 of 32 tracked cells (31%) are `subtype: 'success', is_error: False, num_turns == 0`: 8 in `e5-cc-builtin` and 2 in `e7-fable-3x`, all with real `total_cost_usd` (e.g. `runs/review-arms/e5-cc-builtin/mfc-corpus/result.json` has `{'type': 'result', 'subtype': 'success', 'is_error': False, 'num_turns': 0, 'total_cost_usd': 1.13555625}`). Under this predicate such a cell is classified "incomplete/errored, re-running" (`run-host.sh:161`) and re-paid on *every* resume, forever. This clause is inherited from the pre-fix code, not introduced here, but `docs/working/crb-direction1-setup.md:104-105` now states the conjunction as the definition of success, which makes the gap a documented one.

On the specific question of `d.get("subtype", "success")`: defaulting a *missing* subtype to success is permissive, but in practice dead code — every one of the 32 tracked `result.json` files carries an explicit `subtype`, and the harvest at `run-host.sh:210-215` only writes the file when a `type == "result"` event was seen, which is the event that carries the field. Combined with the independent `is_error` clause the residual risk is negligible.
**Legibility-target:** author

---

## Claim 7: judge seeding now exits on a missing seed

**Location:** `scripts/crb-pipeline-to-benchmark.py:275-293`
**Type:** Behavioral / cost-control
**Verdict:** Verified
**Confidence:** High
**Evidence:** Both new exits are present. Per-file: `elif not s.exists():` / `sys.exit(f"seed source {s} is missing — refusing to continue: an unseeded "` `f"judge dir re-judges every tool (~50x cost). Pass --no-seed to "` `f"do that deliberately.")` (`crb-pipeline-to-benchmark.py:288-291`). Whole-dir: the previous `print(... file=sys.stderr)` warning is replaced by `sys.exit(f"no checked-in results for judge {args.judge} at {src} — refusing to "` ... (`:293-295`).

`--no-seed` still escapes: `if args.no_seed:` is the first branch of the chain at `:275`, so neither exit is reachable when it is passed. A **partial prior seed is handled correctly** in both directions — the loop iterates `for name in ("candidates.json", "evaluations.json"):` (`:281`) and evaluates each independently, so `candidates.json` present + `evaluations.json` missing hits `elif (jdir / name).exists()` → `print(f"Kept existing ...")` for the first and either copies or exits for the second.

One residual, minor: `(out / "results/benchmark_data.json").write_text(...)` at `:267` runs *before* the seed check, so a missing-seed exit leaves a written `benchmark_data.json` and a created empty judge dir behind. It does not cause paid work — the exit still precedes any judging — but a re-run then sees a partially-populated `out`. Also, an existing-but-truncated `evaluations.json` is accepted on its filename alone with `Kept existing` and never content-validated.
**Legibility-target:** author

---

## Claim 8: generated judge.sh refuses to start against a non-Anthropic endpoint

**Location:** `scripts/crb-pipeline-to-benchmark.py:331-370`
**Type:** Behavioral / security
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** I materialized the generated text by evaluating the module's own `judge_sh = f"""..."""` template against the real module globals (`BENCH`, `WORKSPACE`, `sanitize_model`, defaults), wrote it to a scratch file, and ran `bash -n` — **`SYNTAX OK`**. The f-string escaping is correct: `{{` / `}}` render as literal braces, so the emitted file contains `: "${MARTIAN_API_KEY:=${ANTHROPIC_API_KEY:-}}"`, `|| { echo "MARTIAN_API_KEY (or ANTHROPIC_API_KEY) not set" >&2; exit 1; }`, and `[ "${CRB_ALLOW_FOREIGN_ENDPOINT:-}" = "1" ] || exit 1 ;;` — all valid. Interpolations render correctly too (`PYTHONPATH` → `/workspace/external/code-review-benchmark/offline`, tool → `mfc-pipeline-e8`).

The premise is accurate: the benchmark really does default to a third-party host — `base_url = os.environ.get("MARTIAN_BASE_URL", "https://api.withmartian.com/v1")` appears identically at `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:82`, `step3_judge_comments.py:106`, and `step5_label_prs.py:136`, and `offline/.env.example:7` ships `MARTIAN_BASE_URL=https://api.withmartian.com/v1`. The doc's citation of `step3_judge_comments.py:106` (`docs/working/crb-direction1-setup.md`) is exact.

Mechanics verified by executing the guard's logic in isolation: `set -euo pipefail` plus `: "${VAR:=default}"` behaves as intended (`:=` assigns when unset *or* null, and the following `export MARTIAN_API_KEY MARTIAN_BASE_URL MARTIAN_MODEL` publishes it), and the `CRB_ALLOW_FOREIGN_ENDPOINT` escape **is** reachable — `[ ... = "1" ] || exit 1` short-circuits when the variable is `1`, leaving the `*)` branch with status 0 and falling through the `esac`. My probe printed `BLOCK  https://api.withmartian.com/v1` and `ALLOW(escape) withmartian`, confirming both paths.

**The defect:** the pattern `*api.anthropic.com*` is an unanchored glob, so the same probe printed `ALLOW  https://evil.com/api.anthropic.com.attacker.net`. Any host that merely *contains* the string passes. Against the stated threat — an operator exporting the key with the wrong base URL — the guard works. Against a hostile or typo-squatted URL it does not, so the commit message's "refuses to start against a non-Anthropic endpoint" is stronger than what the code enforces. A host-anchored test (`https://api.anthropic.com/*`) would close it.
**Legibility-target:** reviewer

---

## Claim 9: slug_for() constrains the slug charset

**Location:** `scripts/crb-materialize.py:72-87`
**Type:** Behavioral / security; regression risk to `--all`
**Verdict:** Verified
**Confidence:** High
**Evidence:** The guard is `if not re.fullmatch(r"[A-Za-z0-9_-]+", slug):` / `raise ValueError(f"unsafe slug {slug!r} derived from fork repo name {repo_name!r}")` (`crb-materialize.py:85-86`), applied after `slug = f"{parts[1]}-{parts[3]}".replace(".", "_")` (`:84`).

**It blocks the traversal the docstring describes.** A `/` in `parts[1]` or `parts[3]` survives the `.`→`_` substitution and is rejected by `fullmatch`, so neither `Path(DST_ROOT) / "/abs"` (which would silently discard `DST_ROOT`) nor an embedded `../` can reach the `shutil.rmtree()` on the `--force` path. The `..` case is doubly covered — dots are already rewritten to `_` before the regex sees them.

**It rejects nothing the real dataset produces.** Cross-checked against every `repo_name` in `external/code-review-benchmark/offline/results/benchmark_data.json`: 2449 `(PR, tool)` review records, 2449 distinct `repo_name` values, of which 2299 have the ≥4 `__`-separated parts `slug_for` requires — and **0 of those 2299 are rejected by the new regex**. The remaining 150 distinct names (e.g. `mra-openai__calcom_cal.com_pr10967`) fail the pre-existing `if len(parts) < 4: raise ValueError` at `:81-82`, which this commit did not change. Critically, `load_prs()` calls `slug_for(fork)` on the fork chosen by `forks.get(DEFAULT_FORK_TOOL)` (`crb-materialize.py:97`), i.e. `claude-code`, and all **50** `claude-code` `repo_name`s pass both checks — so `--all` is not broken.
**Legibility-target:** author

---

## Claim 10: --tool accepted as an alias for --tool-name

**Location:** `scripts/crb-pipeline-to-benchmark.py:191`
**Type:** Interface
**Verdict:** Verified
**Confidence:** High
**Evidence:** `ap.add_argument("--tool-name", "--tool", dest="tool_name", default="mfc-pipeline-e8", ...)` (`crb-pipeline-to-benchmark.py:191`). `dest="tool_name"` is explicit, so `args.tool_name` — read at `:247`, `:249`, `:257`, `:260`, and inside both the `runbook` and `judge_sh` f-strings — is populated by either spelling. No collision: `--tool` is an exact option string, and no other option in this parser begins with `--tool`, so argparse's prefix matching has nothing to disambiguate. The default matches `crb-subset-leaderboard.py`'s own `ap.add_argument("--tool", default="mfc-pipeline-e8", ...)`, and the three vendored steps each take `--tool` (`step2_extract_comments.py:168`, `step2_5_dedup_candidates.py:224`, `step3_judge_comments.py:388`), so the commit's "`--tool` is baked into all 3 steps" is accurate for the generated script's `for step in ...` loop.
**Legibility-target:** author

---

## Claim 11: leaderboard derives evaluations from --out/--judge

**Location:** `scripts/crb-subset-leaderboard.py:30-31,46-50,60-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Evidence:** The path is built as `path = (Path(args.evaluations) if args.evaluations` / `        else Path(args.out) / "results" / sanitize_model(args.judge) / "evaluations.json")` (`crb-subset-leaderboard.py:60-61`), and `--evaluations` defaults to `None` (`:45`), so it still overrides when supplied.

The two sides agree exactly. Producer: `jdir = out / "results" / sanitize_model(args.judge)` (`crb-pipeline-to-benchmark.py:270`). Consumer: the expression above. `sanitize_model` is defined identically in both files as `return model.strip().replace("/", "_")` (`crb-pipeline-to-benchmark.py:63`, `crb-subset-leaderboard.py:34`). Defaults match: `DEFAULT_OUT = WORKSPACE / "runs/review-arms/crb/offline-work-50"` and `DEFAULT_JUDGE = "claude-opus-4-5-20251101"` appear with the same values in both (`crb-pipeline-to-benchmark.py:58,60`; `crb-subset-leaderboard.py:30,31`). The generated `judge.sh` passes the same path explicitly via `--evaluations "{out}/results/{sanitize_model(args.judge)}/evaluations.json"`, so all three routes converge. Note the two `sanitize_model` definitions and the two default-constant pairs are duplicated rather than shared — a comment acknowledges this (`# Kept in sync with crb-pipeline-to-benchmark.py's defaults.`, `crb-subset-leaderboard.py:27`), and it is the C7 shared-module debt the commit deliberately defers.
**Legibility-target:** author

---

## Claim 12: rubric section matching is anchored on the normalized heading

**Location:** `scripts/crb-pipeline-to-benchmark.py:71-76,119-121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Evidence:** `def normalize_section(title: str) -> str:` returning `re.sub(r"[^a-z ]", "", title.lower()).strip()` (`crb-pipeline-to-benchmark.py:71-75`), consumed as `wanted = {normalize_section(s) for s in sections}` and `if normalize_section(section) not in wanted:` (`:119,121`), replacing the old `if not any(s.lower() in section.lower() for s in sections):`.

I ran `normalize_section` over **every** heading in `test/skills/code-review/rubric-current-format.md` (all seven `##` sections). Results: `'🔴 Must Fix' -> 'must fix'`, `'🟡 Must Address' -> 'must address'`, `'🟢 Consider' -> 'consider'`, `'↩️ Considered Overrides' -> 'considered overrides'`, `'✅ Confirmed Good' -> 'confirmed good'`, `'⚠️ Unverified Findings' -> 'unverified findings'`, `'⏭️ Skipped Core Critics' -> 'skipped core critics'`. Exactly the three in `FINDING_SECTIONS = ("Must Fix", "Must Address", "Consider")` match; the other four are excluded on the anchored key rather than by accident.

**No legitimate finding section is newly excluded.** Simulating the old substring predicate over the same headings, the only section whose classification changes is `Considered Overrides` (old: included, because `"consider" in "considered overrides"`; new: excluded). `Unverified Findings` and `Confirmed Good` were excluded under both.

Fragility worth noting: the regex strips digits and hyphens, so a future heading like `## 🔴 Must Fix (P0)` normalizes to `must fix p` and would stop matching. None of the current headings contain digits, so this is latent, not live.
**Legibility-target:** reviewer

---

## Claim 13: harvest uses -z/cut so paths with spaces and renames survive

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:219-231`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** The pipeline is `(cd "$clone" && git status --porcelain=v1 -z --untracked-files=all)` / `| tr '\0' '\n' | cut -c4- | grep -E '\.(md|json)$'` (`run-host.sh:222-223`).

**`-c4-` is the right offset for porcelain v1.** The format is two status characters `XY` plus one space before the path, so the path begins at column 4 for both tracked entries (` M path`) and untracked (`?? path`). Spaces in paths now survive, since NUL rather than whitespace separates fields — a genuine improvement over the old `awk '{print $2}'`.

**Renames are handled only half-correctly** — *paraphrased for the `-z` wire format, no quote available because verifying it empirically requires building a git fixture, which is out of bounds for this pass.* Per git's documented `-z` behaviour, a rename entry omits the ` -> ` and emits the two paths as separate NUL-terminated fields in reversed order (`XY <to>NUL<from>NUL`). After `tr`, the `<to>` path carries the 3-char prefix and is cut correctly, but `<from>` arrives on its own line **without** a prefix, so `cut -c4-` silently chops its first three characters. The mangled string is caught by the new existence guard `[ -f "$clone/$f" ] || continue` (`run-host.sh:225`) — the original path no longer exists after a rename — so nothing breaks in practice, but the mechanism is the guard, not the parsing. The commit message's "renames survive" is true of the new path (the one worth harvesting) and misleading about the old.

Mitigating: renames only appear in `git status` once staged, and the reviewing agent has no reason to `git add`; an agent-renamed file surfaces as ` D old` plus `?? new`, both of which parse correctly. So the residual is close to unreachable.

**Separately — a pre-existing sweep-abort this commit touched but did not fix.** `run-host.sh:52` sets `set -euo pipefail`. If a cell produces no `.md`/`.json` artifact, `grep -E` exits 1; under `pipefail` the whole pipeline's status is 1 even though the trailing `while` succeeds, and `errexit` kills the script. I confirmed the interaction directly: `bash -c 'set -euo pipefail; printf "a\nb\n" | grep -E "zzz" | while read -r f; do echo "$f"; done; echo "SURVIVED"'` exits 1 without printing `SURVIVED`. The paid cell's `result.json` is already written (`:215`), so nothing is lost, but the sweep stops mid-run and never reaches the `run-meta.json` write at `:271`. The identical shape existed pre-fix (`| awk '{print $2}' | grep -E ...`), so this is **not introduced here** — but the commit rewrote this exact pipeline and left it in place. `|| true` after the `grep` would close it.
**Legibility-target:** reviewer

---

## Claim 14: cp --no-dereference in the host-side harvest

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:227-230`
**Type:** Behavioral / security
**Verdict:** Verified
**Confidence:** High
**Evidence:** `cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true` (`run-host.sh:230`), with the rationale inline: `# --no-dereference: the agent could leave a symlink in the repo, and this` / `# cp runs on the HOST, so following it would copy host files into a` / `# tracked artifacts dir.` (`:227-229`).

It does address the stated risk. `--no-dereference` (GNU coreutils, `-P`) copies the link itself, so an agent-planted `docs/reviews/x.md -> /home/node/.claude/.credentials.json` lands in `artifacts/` as a symlink whose *target path* is recorded, not the host file's contents — nothing sensitive is copied into a tracked directory. Note the preceding guard `[ -f "$clone/$f" ]` (`:225`) *follows* symlinks, so a symlink to an existing host file still reaches the `cp`; the protection comes entirely from `--no-dereference`, which is where the commit puts it. Dangling symlinks and symlinks-to-directories are filtered out by `-f` before that.

Not fully closed, and correctly not claimed to be: the artifacts tree can still end up containing absolute symlinks pointing into the host, which a later tool that *does* dereference (an editor, `tar -h`, a naive `cat`) would follow. The commit scopes its claim to the `cp` and defers the broader container-isolation question to R3, which it explicitly leaves to the author.
**Legibility-target:** reviewer

---

## Claim 15: the golden-denominator and cost figures in the setup doc

**Location:** `docs/working/crb-direction1-setup.md` (caveat 2 and the `--tool` bullet); mirrored in `scripts/crb-pipeline-to-benchmark.py:298-306`
**Type:** Numeric — re-derived from source data, not inherited from pass 1
**Verdict:** Verified
**Confidence:** High
**Evidence:** Every figure re-computed directly from `external/code-review-benchmark/offline/results/`. All match exactly.

| Doc figure | Re-derived | Source |
|---|---|---|
| "24 of the 50 PRs" have non-uniform `total_golden` | **24 of 50** | `anthropic_claude-opus-4-5-20251101/evaluations.json`, counting PRs where `{r["total_golden"] for non-skipped tools}` has >1 element |
| "values range 1–9" | **1–9**, observed set `[1,2,3,4,5,6,7,8,9]` | same |
| "the maximum golden count on any PR is 9" | **9** = `max(len(e['golden_comments']))` | `benchmark_data.json` |
| "28 of the 49 tools" scored against a smaller golden set | **28 of 49** | tools with `total_golden < len(golden_comments)` on ≥1 PR |
| "Four of the five pilot PRs are affected" | **4 of 5** — all but `grafana-PR79265` | pilot URLs from `runs/review-arms/crb/instances.json` |
| "216 pairs are absent" | **216** = 2449 bd pairs − 2233 candidate pairs | `benchmark_data.json` vs `candidates.json` |
| "166 of them below step 2's ≥20-char extraction gate" | **166** | absent pairs with no review comment ≥20 chars |
| "the **50** (PR, tool) pairs … all `greptile-v5`" | **50**, and the tool breakdown is `{'greptile-v5': 50}` — exclusively | 216 − 166 = 50 |
| "seeded `evaluations.json` is already complete at 2449 pairs" | **2449**, equal to the `benchmark_data.json` pair count | evaluations.json |
| "roughly **2233** paid LLM calls" in step 2.5 | **2233** candidate pairs; `step2_5_dedup_candidates.py:5` states "For each (PR, tool) pair, sends all candidates in a single LLM call" ⇒ 1 call/pair | candidates.json + step 2.5 source |
| "no `dedup_groups.json` is checked in" | confirmed — the judge dir holds only `candidates.json` and `evaluations.json` | `ls results/anthropic_claude-opus-4-5-20251101/` |
| "50 PRs, 173 goldens" (`crb-materialize.py --list` banner) | **50 PRs, 173 goldens** | benchmark_data.json |

The ≥20-char gate is real and cited correctly by implication: `if not comment_body or len(comment_body.strip()) < 20:` (`step2_extract_comments.py:139`) and `if all_text and len(all_text.strip()) >= 20:` (`:222`). The correction note in the doc — *"this caveat previously read 'the same 2 PRs … 11 vs 13', which understated the effect ~12× and cited values that occur nowhere in the file — the maximum golden count on any PR is 9"* — is itself accurate: 11 and 13 do not occur, and 24/2 = 12.
**Legibility-target:** author

---

## Claim 16: the `--all` disk estimate, the family() correction, and the manifest key list

**Location:** `scripts/crb-materialize.py:16-33,106-112`; `docs/working/crb-direction1-setup.md:27`
**Type:** Numeric / documentation
**Verdict:** Verified
**Confidence:** High
**Evidence:** The docstring now reads `Measured on the 5-PR pilot: 33-195 MB each (see clone_mb in the manifest).` (`crb-materialize.py:18-19`). The manifest's `clone_mb` values are 190, 33, 125, 127, 195 — min 33, max 195, exactly as stated. Mean ≈134 MB × 50 ≈ 6.7 GB, consistent with the revised `--all # all 50 (~6-7 GB)` (`crb-materialize.py:25`, mirrored at `docs/working/crb-direction1-setup.md:27`) and with the retirement of the old `~15-25GB`.

The `family()` correction is right. `family()` returns `source_repo.split("-")[0]` (`crb-materialize.py:112`), so `discourse-graphite` → `discourse` — and the docstring's new claim that it is *not* a mirror split (`Note discourse-graphite / is NOT such a split — it is the only name discourse appears under.`, `:110-111`) holds: `discourse-graphite` is the sole `discourse*` name in the dataset, whereas `sentry`/`sentry-greptile` and `keycloak`/`keycloak-greptile` are genuine pairs. That grouping is what yields 5 pilot slugs rather than 7, and the pilot manifest confirms it — `discourse-graphite-PR4`, `sentry-greptile-PR5`, `keycloak-PR36880`, `cal_com-PR11059`, `grafana-PR79265`, one per project. The completed manifest key list at `:29-32` (`url, source_repo, pr_title, fork, fork_url, head, base, commits, n_goldens, files_changed, insertions, deletions, clone_mb, depth`) matches the record shape in `runs/review-arms/crb/instances.json`. The `--per-repo` comment correction — `# --per-repo N: the N PRs with the most golden comments in each source` / `# PROJECT — the grouping key is family(source_repo), not source_repo` (`:125-126`) — matches `select()`, which keys `by_repo` on `family(...)`.
**Legibility-target:** author

---

## Claim 17: N1 — the GOLDEN-DENOMINATOR SKEW warning

**Location:** `scripts/crb-subset-leaderboard.py:94-114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Evidence:** The block computes `golds = {t: r.get("total_golden", 0) for t, r in evals[url].items() if not r.get("skipped")}`, appends to `skew` when `len(set(golds.values())) > 1`, and prints to stderr (`crb-subset-leaderboard.py:98-114`).

Executed against the benchmark's checked-in evaluations (read-only), it fires and is non-vacuous:

```
!! GOLDEN-DENOMINATOR SKEW: 24 of 50 PR(s) in this subset have non-uniform total_golden
across tools; on 23 of them at least one tool was scored against FEWER goldens than
greptile-v5, which inflates their recall relative to ours. ...
```

The `24 of 50` agrees with the independently re-derived figure in Claim 15, and the conditional second clause (`if lo_than_ours`) renders correctly. Warning goes to stderr, so it does not corrupt `--markdown` output piped to a file — which is the point of the mitigation.
**Legibility-target:** author

---

## Claim 18: "490/490 fast, 0 failures" and "fails against the pre-fix code (6 -> 7 comments)"

**Location:** commit message, Tests paragraph
**Type:** Empirical
**Verdict:** Verified
**Confidence:** High
**Evidence:** Both halves reproduced.

`./scripts/run-tests.sh --fast` emits the TAP plan `1..490`, 490 `ok` lines, and **zero** `not ok` lines. The new suite contributes 8, confirmed by running it alone: `bats test/crb-injector-sections.bats` ends at `ok 8 --sections consider alone still excludes Considered Overrides`. (Two `BW02` bats-version warnings appear, from the pre-existing `test/skills/code-review-assurance-contract.bats`, not from the new file.)

The 6→7 claim is exact. Loading the injector and running `comments_from_rubric` over the golden fixture and over a copy with `| Prior finding |` renamed to `| Finding |`:

- current code: golden → **6**, renamed → **6**
- simulated pre-fix substring predicate: golden → **6**, renamed → **7**

So the regression the suite guards is real, is precisely one comment, and the new suite's `renaming the Considered Overrides column to Finding is inert` test is the assertion that catches it.
**Legibility-target:** author

---

## Claim 19: the new bats suite matches repo conventions and its assertions are non-tautological

**Location:** `test/crb-injector-sections.bats`
**Type:** Test quality
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** Conventions are met. The file carries `# @category fast` on line 2, matching the tag `scripts/run-tests.sh --fast` selects on, and it is picked up (490 includes its 8). Hermeticity holds as claimed (`# ... Hermetic: no network, no repo mutation.`): the only writes go to `$BATS_TEST_TMPDIR` (`local renamed="$BATS_TEST_TMPDIR/renamed.md"`), the fixture is read-only, and no network binary is invoked.

`probe()`'s `eval` works as the tests assume. The heredoc script `exec_module`s the injector as `m`, reads the rubric into `md`, then `print(eval(sys.argv[3]))` — both names are module-globals of the running script, so the expression argument sees them. Confirmed by the tests passing against real behaviour, not just exiting 0.

**But most of the assertions are non-discriminating.** Only one of the eight would have failed against the pre-fix code:

- Tests 3, 4, 5 (`Considered Overrides is NOT treated as a finding section`, `Confirmed Good ...`, `normalize_section strips emoji ...`) exercise `normalize_section` in isolation, via set membership. They say nothing about whether `comments_from_rubric` actually *uses* it — deleting the call at `crb-pipeline-to-benchmark.py:121` and restoring the substring test would leave all three green.
- Test 1 (`golden rubric fixture exists`) and test 6 (`yields at least one review comment`) are sanity checks that pass under both implementations.
- Test 2 pins the matched-section set, which the substring predicate also satisfies for the *matching* direction.
- **Test 8** (`--sections consider alone still excludes Considered Overrides`) is the one flagged as suspect, and it is: I ran its assertion against the simulated pre-fix predicate and got `[]` — the same result the test asserts. It passes on broken code, because under the old substring match the `Considered Overrides` section was admitted but then discarded anyway by `f_i = idx.get("finding")` returning `None` for its `Prior finding` column. That is precisely the accident the suite exists to remove, so this test re-encodes the accident instead of guarding against it.
- **Test 7** is the real guard, and it is genuinely discriminating (6→7 vs 6→6, per Claim 18).

So the suite does close the stated contract, but seven of its eight cases are documentation rather than regression protection, and the commit's framing ("8 cases guards the rubric->benchmark section contract") slightly oversells the coverage.
**Legibility-target:** reviewer

---

## Claim 20: .gitignore additions match the paths run-host.sh writes, and 16 e7 transcripts stay tracked

**Location:** `.gitignore:43-49`
**Type:** Behavioral / documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** Both patterns match the real write paths. `run-host.sh:192` redirects to `> "$dest/transcript.jsonl" 2> "$dest/stderr.log"` where `dest="$OUT/$id"` and `OUT="$ROOT/runs/review-arms/crb-pipeline"`. `git check-ignore -v` on a representative path confirms:

```
.gitignore:48:runs/**/transcript.jsonl	runs/review-arms/crb-pipeline/grafana-PR79265/transcript.jsonl
.gitignore:49:runs/**/stderr.log	runs/review-arms/crb-pipeline/grafana-PR79265/stderr.log
```

The transcript half of the comment is exactly right: `git ls-files 'runs/review-arms/e7-fable-3x/**transcript.jsonl'` returns **16**, and a repo-wide `git ls-files | grep -c 'transcript\.jsonl$'` also returns **16** — so the 16 already-tracked files are all under `e7-fable-3x`, they remain tracked (gitignore does not affect tracked paths), and the note `# NOTE the 16 transcripts already committed under runs/review-arms/e7-fable-3x/ predate` / `# this rule and stay tracked; this prevents new ones, it does not rewrite history.` (`.gitignore:45-46`) is accurate on both counts.

The gap: the comment's NOTE covers only transcripts, but the same commit also ignores `stderr.log`, and **43** `stderr.log` files are already tracked (`git ls-files | grep -c 'stderr\.log$'`), spread across `runs/review-arms/crb/cubic-cli/*`, `runs/review-arms/e5-cc-builtin/*` and others. They also stay tracked, so nothing is lost, but the comment's inventory is silently incomplete and a future reader would infer 16 grandfathered files rather than 59.
**Legibility-target:** author

---

## Claims Requiring Attention

Ordered by whether falsity would let a paid sweep proceed on a broken guard.

1. **A post-run containment failure does not void anything (Claim 2).** `run-host.sh:236-237` prints a stderr warning; `result.json` is already on disk from `:215`, and the resume predicate at `:150-156` will class it `success` and skip it forever after. `docs/working/crb-direction1-setup.md:98` claims the cell is "marked void." This is the one gap that can put a contaminated cell into the published numbers, which is the exact failure R2 exists to prevent. Fix: on post-run failure, rename `result.json` (e.g. to `result.void.json`) or write a `CONTAINMENT_FAILED` marker the resume predicate checks.

2. **`num_turns > 0` in the resume predicate re-pays for successful cells (Claim 6).** 10 of 32 tracked `result.json` files in this repo are `subtype: success, is_error: False, num_turns: 0` with real cost — 31% of historical cells would be re-run and re-billed on every resume. The `is_error`/`subtype` clauses the commit added are correct and effective; the inherited turns clause is now the weak link, and the setup doc states the conjunction as the definition of success. Consider dropping `num_turns > 0` in favour of `is_error`/`subtype` plus a non-empty `review.md`.

3. **The endpoint guard is an unanchored substring glob (Claim 8).** `*api.anthropic.com*` admits `https://evil.com/api.anthropic.com.attacker.net` (verified by probe). It stops the misconfiguration it was written for; it does not "refuse to start against a non-Anthropic endpoint" as the commit message states. Anchor the pattern.

4. **Pre-existing: `set -euo pipefail` + an empty `grep` aborts the sweep (Claim 13).** A cell that writes no `.md`/`.json` kills the whole run at `run-host.sh:223` (interaction confirmed by direct test). Not introduced by this commit — the same shape existed pre-fix — but this commit rewrote that pipeline. A trailing `|| true` closes it.

5. **`--verify` on a slug absent from the manifest silently self-references (Claim 2).** `head=None` falls back to `git rev-parse review` (`crb-materialize.py:181`), so a moved `review` ref passes against its own tip. Reachable via `run-host.sh:71`'s positional-argument path. Prefer failing loudly on an unknown slug.

6. **Seven of the eight new bats cases are non-discriminating (Claim 19).** Test 8 in particular passes against the pre-fix code — verified by simulation. Only test 7 catches the regression. Worth adding a case that asserts `comments_from_rubric` (not `normalize_section`) rejects a section whose heading merely *contains* a finding-section name.

7. **Minor:** the pre-run containment `continue` leaks one `mktemp -d` payload copy per skipped cell (Claim 2); `benchmark_data.json` is written before the seed check can exit (Claim 7); an existing-but-truncated `evaluations.json` is accepted on filename alone (Claim 7); the `.gitignore` NOTE inventories 16 grandfathered transcripts but omits the 43 grandfathered `stderr.log` files (Claim 20); `normalize_section`'s regex strips digits, so a future `## 🔴 Must Fix (P0)` would stop matching (Claim 12).

**No claim in the commit message was found to be fabricated.** Every numeric figure re-derived from the benchmark data matched exactly, including all seven the brief specifically flagged as pass-1 propagation risks. The three substantive defects above are cases where the *code* is weaker than the claim, not cases where the claim describes work that does not exist.

## Goal-Alignment Note
- Answered: yes — all 20 flagged claim clusters checked against implementing code, with the numeric set independently re-derived
- Out of scope: the second half of R2's "fires correctly when a remote is added" (requires a git fixture — assessed by reading only, per the mandatory safety constraint); R3's live-key/open-egress container posture, which the commit explicitly defers to the author; `docs/reviews/*` files in the diff, which are review artifacts rather than reviewed code
- Escalate: (1) the post-run containment warning that does not void the cell — this is a results-integrity hole, not a style point, and should block the paid sweep; (2) the `num_turns > 0` resume clause, which will re-bill ~31% of cells on every resume; (3) the unanchored `api.anthropic.com` glob; (4) the pre-existing `grep`/`pipefail` sweep abort, which is cheap to fix while this file is already open
