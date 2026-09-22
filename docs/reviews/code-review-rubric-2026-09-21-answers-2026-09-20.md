Commit: 654c0ed

# Code Review Rubric

**Scope:** `e8d5fa1..answers-2026-09-20` (32 commits, 50 files, +1476/−636) | **Reviewed:** 2026-09-21 | **Status: 🔴 DOES NOT PASS** — 5 red item(s) unresolved

Pipeline:
1. Fact-check, k=3 on opus, merged most-severe-wins.
2. Stage 1.5 gate: no core critic skipped.
3. Critics in parallel on opus: security-reviewer, performance-reviewer and api-consistency-reviewer, plus architecture-review (structural) and tech-debt-triage (contextual, since >10 files and >500 lines).
4. Stage-2.5 submitted-claims fact-check (k=1, opus).

Delivery mode: `self-read`. The assembled diff is about 65k tokens, which exceeds the 25k inline budget. The diff is over 1000 lines. Rather than splitting it, it was run as a single pass with code files prioritised in the shared brief, because this was a non-interactive dispatch. test-strategy was not triggered, because the source changes carry test changes.

Artifacts:
- `code-fact-check-report.md` (merged, with Stage-2.5 claims appended), from replicates `-r1/-r2/-r3.md` and `code-fact-check-submitted-claims.md`.
- `security-review-2026-09-21-answers.md`
- `performance-review-2026-09-21-answers.md`
- `api-consistency-review-2026-09-21-answers.md`
- `architecture-review-2026-09-21-answers.md`
- `tech-debt-triage-review-2026-09-21-answers.md`

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | **Bash tier for the global memory file was narrowed to exact literal spellings, so equivalent spellings are no longer denied.** The HARD pattern requires a prefix (`~`, `$HOME`, `${HOME}`, the literal home path, `global-instructions`) immediately followed by `/CLAUDE.md`. Quoting, `//`, `/./`, `..`, `${HOME:-}` and variable aliases all break that match. Every one of these was **deny** at e8d5fa1; now they return no opinion when untainted and ask when tainted: `"$HOME"/CLAUDE.md` (the ordinary quoted form), `~//CLAUDE.md`, `~/./CLAUDE.md`, `~/"CLAUDE.md"`, `${HOME:-}/…`, `$HOME/x/../…`, `/home/node//…`. The same applies to the loaded global-config file: `~/.claude//CLAUDE.md`, `~/.claude/./CLAUDE.md` and `"$HOME/.claude"/CLAUDE.md` escape the `.claude/CLAUDE\.md` fragment. `H=~; echo > $H/CLAUDE.md` and `cd ~/.claude && mv x CLAUDE.md` are two more ways past it. The taint flag is set only by WebSearch and WebFetch (security #6), so MCP-sourced or subagent-relayed injection has no gate on these spellings at all. The accepted residual (`cd ~ && echo > CLAUDE.md`) is a subset of this. Evidence: `HARD_FRAG = re.compile(r"\.claude/hooks(/\|\b)\|\.claude/settings\|\.claude/CLAUDE\.md\|managed-settings" r"\|(?:" + "\|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md", re.I)`. Convergence: fact-check Claim 3 (k=3 unanimous, executed) + security #1 + tech-debt TD1. Corroborated by executed probes. | Security | High / Incorrect (high, behavioral) | security-reviewer + Fact-check | `hooks/guard-trusted-writes.py:121-132` | for-author | — | 🔴 Unresolved |
| R2 | **`questions.sh` now resolves to the caller's repo and writes through symlinks planted there.** It is installed globally at `~/.claude/scripts/questions.sh`, and the global instructions tell agents in every project to run `index`/`archive`/`init`. A cloned repo can ship `docs/working/` symlinks. Executed hermetically: `archive` **appends** attacker-authored entry text (including a `curl … \| sh` line) through a symlinked `questions-archive.md`. It **overwrites** an arbitrary file through a symlinked `questions.md.tmp`, then exits 0 with "✓ archived 1 entry". `init` **creates** a file at the target of a dangling `questions.md` symlink, because `[[ -e ]]` is false for a dangling link (fact-check Claim 11, k=3 Mostly accurate). The guard hook cannot see these writes, because the command text contains no write primitive. Evidence: `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null \|\| pwd)"` (`:55`); `extract_entry "$LIVE" "$id" >> "$ARCHIVE"` (`:275`); `' "$LIVE" > "$LIVE.tmp"` / `mv "$LIVE.tmp" "$LIVE"` (`:286-287`); `[[ -e "$file" ]] && { echo "  = exists: $file"; continue; }` (`:320`). | Security | High | security-reviewer (executed) | `scripts/questions.sh:55-57,275-287,320-328` | for-author | — | 🔴 Unresolved |
| R3 | **The guard's HARD tier and `permissions.deny` are meant to name the same paths, but they are computed in three independent places that have diverged.** (a) `_global_dirs()` always keeps `~/.claude` and adds `$CLAUDE_CONFIG_DIR`, while the linker substitutes only `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` into `{{CLAUDE_DIR}}`. With the variable pointing elsewhere, `~/.claude/settings*.json` and `~/.claude/hooks/**` are classed HARD and deferred, and no deny rule covers them, so they have no gate. (b) The hook expands `~` in the variable and the linker does not. (c) A relative value is kept unresolved and matches from any cwd. (d) The installed symlink layout is not modelled; see R4. The docstring's "$CLAUDE_CONFIG_DIR when set, else ~/.claude — the same {{CLAUDE_DIR}} hooks/wiring.json substitutes" is false. Security rated exploitability Informational: when the variable is set, Claude Code doesn't load `~/.claude`. Evidence: `dirs = [HOME / ".claude"]` / `cfg = os.environ.get("CLAUDE_CONFIG_DIR")` / `if cfg: dirs.append(Path(os.path.expanduser(cfg)))` (`:58-61`). Convergence: architecture #1 (Structural) + api-consistency F1 (Breaking) + fact-check Claim 5 (Incorrect high, executed) + security #5 + TD2. | Architecture / API / Security | Structural / Breaking / Incorrect (high) | architecture-review + api-consistency-reviewer + Fact-check | `hooks/guard-trusted-writes.py:10-12,56-68`; `devcontainer-config/link-claude-home.sh:36`; `hooks/wiring.json:120-127` | for-author | — | 🔴 Unresolved |
| R4 | **File tools can "ask" on global HARD paths, breaking "must NEVER ask on a HARD path".** In the installed layout, `~/.claude/hooks` and `~/.claude/CLAUDE.md` are symlinks into `/opt/claude-workflows/`. `resolve()` follows them out of `GLOBAL_DIRS`, and the unresolved candidate with `..` fails `_global_rel`, so the path falls through to SOFT and returns **ask** when tainted. That ask overrides `permissions.deny` (#39344). New regressions against e8d5fa1: `Edit ~/.claude/x/../CLAUDE.md`, and a project `.claude` symlinked to `~/.claude` (its `hooks/*` and CLAUDE.md). `~/.claude/x/../hooks/*` was pre-existing. r3 verdicted Verified in a synthetic fakehome whose hooks dir was a real directory; the disagreement is explained by layout. Security rated this Medium, because it depends on whether Claude Code's deny matcher normalises `..`; the `hooks/**` target is also root-owned and read-only here. Evidence: `rel = _global_rel(cand)` / `if rel is not None and rel.parts:` / `if rel.parts[0] == "hooks":` / `return "hard"` (`:88-91`). | Security | Incorrect (high, behavioral, r1+r2) / Medium (security) | Fact-check + security-reviewer | `hooks/guard-trusted-writes.py:80-109,172-184` | for-author | — | 🔴 Unresolved |
| R5 | **The hypothesis-log Run-column migration rewrites the file even on its documented no-op path and leaves it at mode 0600.** `mktemp "${log_file}.XXXXXX"` plus `mv` replaces the inode and inherits mktemp's 0600, both when no header is found and on every real migration of the tracked `hypothesis-log.md`. The comment reads "No-op when the header already has a Run cell or no header is found". Evidence: `tmp=$(mktemp "${log_file}.XXXXXX") \|\| return 1` … `' "$log_file" > "$tmp" && mv "$tmp" "$log_file"`. Tiered 🔴 mechanically: fact-check Incorrect (high) on behavior (the code does something other than documented). The practical impact is low: a more-restrictive mode, and a new inode on a git-tracked file. Convergence: api F8, TD4. | Behavioral | Incorrect (high) | Fact-check (r3; r1 Mostly accurate) | `scripts/lib/si-functions.sh:545-568` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Dead anchor `rubric.md#-must-address` (new at `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`). The heading sits inside the fenced template at `skills/code-review/references/rubric.md:31-158`, so no anchor is generated. `#deliverable-2-code-review-rubric` exists. No health-check gate validates cross-doc anchors. Convergence: FC 18 (k=3 unanimous), api F5, arch #4, TD7. | Docs | Incorrect (high, doc-only) | Fact-check + api-consistency + architecture | for-author | — | 🟡 Open | — |
| A2 | The contextual-critic row maps "test-strategy P1 → 🟡, P2 and below → 🟢", but test-strategy emits only `Priority: high/medium/low` (`skills/test-strategy/SKILL.md:196`). It is repeated at `rubric.md:288-292,340,504` and `skills/code-review/SKILL.md:1230`. FC 19 is a hallucination-patterns candidate. | API / Docs | Incorrect (high, doc-only) / Inconsistent | Fact-check + api-consistency F2 | for-author | — | 🟡 Open | — |
| A3 | `questions.sh` reports success when its files don't exist: `next-id` prints Q-001, `index` prints "✓ indexes regenerated", `archive` prints "✓ archived 0 entries", and all exit 0. Only `check` fails. Under $PWD resolution, missing files are the normal state in any project that hasn't run `init`. | API | Inconsistent | api-consistency F3 | for-author | — | 🟡 Open | — |
| A4 | Three spellings of the questions.sh path: the global instructions use `~/.claude/scripts/questions.sh`, while DD Path C (`workflows/divergent-design.md:340`) and the script's own hints (`questions.sh:198,214`) use `scripts/questions.sh`, which doesn't exist outside this repo. | API / Architecture | Inconsistent / Minor | api-consistency F4 + architecture #6 | for-author | — | 🟡 Open | — |
| A5 | `docs/reviews/override-log.md`'s own format section still describes only human overrides. The new `Accepted-immutable` / `[auto: code-review]` row kind is defined only in `skills/code-review/references/override-log.md`. | API | Inconsistent | api-consistency F6 | for-author | — | 🟡 Open | — |
| A6 | The run-id contract is enforced by convention only. `si-morning-summary.sh` re-derives archive names from its own copy of the naming rule, and the id regex is duplicated. The default id is the date, so two runs on one day share it, and archive `mv` (no `-n`) overwrites the first run's files. Once `si-run-id.txt` is itself archived, `_live_run_matches` treats every run as a match. The morning-summary reader builds paths from the Run cell **without validation**: `archive/${run}-tasks-round-N.json` read a file outside `archive/` in an executed probe with `../../outside/x`. That path is read-only and requires editing the tracked log (FC submitted Claim 25, Mostly accurate). | Architecture / Security | Coupling / Mostly accurate | architecture #2 + Fact-check (submitted 25) + TD3 | for-author | — | 🟡 Open | — |
| A7 | `~/.claude/scripts/` now exposes the whole `scripts/` directory, though only `questions.sh` and `lite-review.py` are meant to be global. The directory mixes four ways of finding the repo root (e.g. `archive-working-docs.sh` uses a bare relative `docs/working`), and health-check must pin `QUESTIONS_*` back. | Architecture | Coupling | architecture #3 + TD6 | for-author | — | 🟡 Open | — |
| A8 | The Bash guard does not recognise several common write primitives: `ln -sf`, `curl -o`, `wget -O`, `tar -C`, `unzip -d`, `sponge`, `python3 script.py`, `git checkout`, and `git config --global` targeting `~/.claude/settings.json` or hooks. This predates the diff and is unchanged by it. | Security | Medium | security-reviewer #4 | for-author | — | 🟡 Open | — |
| A9 | Gate 5 makes a full health-check take about 11 min, about 400 s of which is repeated work. `--slow` runs `health-check.bats`, which runs the whole `health-check.sh` three times (in `setup_file` and in two negative frontmatter tests); gates 1-4 and 6-14 run each time. Measured 405 s of the 441 s slow set, under contention. Fix: have the negative tests call `check_skill_frontmatter` directly via the new `BASH_SOURCE` guard. | Performance | Medium | performance-reviewer #1 | for-author | — | 🟡 Open | — |
| A10 | Bash `.claude/settings\|hooks` HARD matching catches only the literal text. `~/.claude//settings.json`, `~/.claude/./settings.json`, `~/".claude"/settings.json` and `cd ~/.claude && … > settings.json` classify **None**, not even SOFT. This predates the diff; it shares its root with R1 (TD1). | Security | Mostly accurate | Fact-check Claim 4 (r3) | for-author | — | 🟡 Open | — |
| A11 | `questions.sh`'s "$PWD itself outside a git repo" fallback also fires inside `.git/`, which creates `.git/docs/working/`. | Behavioral | Mostly accurate | Fact-check Claim 10 (r1+r3) | for-author | — | 🟡 Open | — |
| A12 | The hypothesis-log reader splits on every `\|`, but the writer escapes `\|`. Rows with a piped hypothesis read the wrong cell as Run: an old row reads its Evidence value, and a new row loses its run id. This is masked by the newest-first fallback. The writer's fixed 12-cell `printf` also assumes the exact header. | Behavioral / API | Mostly accurate / Minor | Fact-check Claim 16 (r2) + api F7 + TD5 | for-author | — | 🟡 Open | — |
| A13 | performance-reviewer's Macro × Cold row says it "matches the hot-path gate" but adds a large-data or nightly-batch escalation that the gate at `SKILL.md:46` lacks. | Docs | Mostly accurate / Minor | Fact-check Claim 20 + api F17 | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The taint flag is derived only from WebSearch and WebFetch. MCP tools (Gmail, Drive, Docs) and subagent-relayed content never taint, which widens every SOFT reclassification (this raised R1's severity). Pre-existing: `hooks/web-taint-mark.py:1-5`. | security-reviewer #6 | Informational | for-author | — | 🟢 Open |
| C2 | The `--fast` pre-gate takes about 2.5 min. `test/init-firewall-rules.bats` is tagged fast but took 51 s, against the "<1s each" definition. | performance-reviewer #2 | Low | for-author | — | 🟢 Open |
| C3 | `_find_tasks_file` lists candidates twice on a miss, and `_days_since_round` (`si-morning-summary.sh:1349`) omits `$run`, so it repeats the newest-first scan. Passing `$run` is a one-line fix. | performance-reviewer #3 | Informational | for-author | — | 🟢 Open |
| C4 | `WRITE_PRIMITIVE` shows quadratic regex time on pathological 40 KB inputs (~795 ms). Pre-existing. | performance-reviewer #4 | Informational | for-author | — | 🟢 Open |
| C5 | Naming: `Accepted-immutable` casing differs from `Won't-Fix`/`Must-Fix` (F9). The `Run` column differs from `SI_RUN_ID`/`Task ID` (F10). `HEALTH_CHECK_RUN_TESTS` holds a path but reads as a boolean (F11). | api-consistency F9-F11 | Minor | for-author | — | 🟢 Open |
| C6 | `[auto: code-review]` is a free-text token that pr-prep's override count depends on (F12, arch #5). code-review now writes to the override log, partly reversing 93bfbad's reasoning. | api-consistency F12 + architecture #5 | Informational / Minor | for-author | — | 🟢 Open |
| C7 | `SI_RUN_ID` accepts non-date ids, which break the lexical newest-first ordering the Run-less fallback relies on (F13). archive-working-docs' default prefix change is an interface change worth a changelog line (F14). | api-consistency F13, F14 | Minor / Informational | for-author | — | 🟢 Open |
| C8 | The same path gets different tiers by tool (project settings: ask via Edit, deny via Bash). Bash ignores `CLAUDE_CONFIG_DIR`, which is undocumented. Bare-host hook copies keep the old tiers until they are re-copied (F15). | api-consistency F15 | Informational | for-author | — | 🟢 Open |
| C9 | `run-tests.sh` and `health-check.sh` each name the other as the owner of report-gating (F16). The `HEALTH_CHECK_SKIP_BATS` recursion guard is carried intentionally (TD9). | api-consistency F16 + TD9 | Minor | for-author | — | 🟢 Open |
| C10 | The pr-prep local-merge path is a single global rule rather than a per-step branch. | architecture #7 | Informational | for-author | — | 🟢 Open |
| C11 | Debt root for R1/A10: Bash tiering classifies raw command text by regex without normalisation, so every tier-narrowing change re-opens a spelling class. Consider canonicalising (collapse `//` and `/./`, strip quotes, expand `~`/`$HOME`/`${HOME…}`) before matching. Fix together with R3/R4 in one RPI branch, plus an installed-symlink-layout test fixture. | tech-debt-triage TD1/TD2 | High (advisory) | for-author | — | 🟢 Open |
| C12 | lite-review.py's "--bare prints 'Not logged in' and exits 0" (Verified 2026-08-15) could not be re-verified: it needs a live subscription call. | Fact-check Claim 24 (Unverifiable) | — | for-author | — | 🟢 Open |
| C13 | The performance critic's hook-overhead endorsement is overstated in its numbers: measured ≤0.4 ms (noise) on a ~17 ms call, not "1–2 ms on ~20 ms". The conclusion (negligible) holds. | Fact-check submitted Claim 27 | — | for-author | — | 🟢 Open |
| C14 | The hook installed in this sandbox (`/home/node/.claude/hooks/guard-trusted-writes.py`) is byte-identical to e8d5fa1. The Q-026/Q-035 behaviour, and the R1/R4 regressions, are not live until it is redeployed. The old hook blocked several read-only review probes during this run, which is Q-035's symptom. | Fact-check submitted pass + all replicates | Informational | for-author | — | 🟢 Open |
| C15 | `docs/working/questions.md:54` still lists Q-023 as `Status: OPEN`, although 0ccbdb8 implements it. | performance-reviewer (escalation) | Informational | for-author | — | 🟢 Open |
| C16 | Commit 4c7a2bb's "Global paths are unchanged" / "matching wiring.json" is refuted (FC Claim 6; nested `~/.claude/sub/settings.json` also moved HARD→SOFT). It is immutable history: route to `docs/reviews/override-log.md` as an `Accepted-immutable` row, not a tier. Not written by this run. | Fact-check Claim 6 | Immutable | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.
Every row carries `Evidence` and has passed the Confirmed-Good cross-check — see
[Confirmed Good is a claim, not an output](../../skills/code-review/references/rubric.md#confirmed-good-is-a-claim-not-an-output).

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| In tainted sessions the file tools now return `ask` for a project's own `.claude/` settings and hooks; before, these had neither a hook gate nor a deny rule. Clean sessions defer. | ✅ Confirmed | `hooks/guard-trusted-writes.py:100-109`; `hooks/wiring.json:120-127` names only `{{CLAUDE_DIR}}` and `~/CLAUDE.md`. FC submitted Claim 26 (executed; scope covers the row). | Fact-check (submitted by security-reviewer) | for-orchestrator-synthesis |
| `SI_RUN_ID` is validated with the same `^[A-Za-z0-9._-]+$` at the writer and at archive-working-docs.sh's reader, and neither accepts `/`. Narrowed: this does not cover the morning-summary reader (A6). | ✅ Confirmed | `scripts/self-improvement.sh:458-463` — `if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]`. FC Claim 13 + submitted Claim 25 (executed; `..` stays inside `archive/`, `../../evil` rejected). | Fact-check | for-orchestrator-synthesis |
| Health-check gate 5 runs `--fast` first and skips `--slow` when fast is red; the recursion guard holds. | ✅ Confirmed | `scripts/health-check.sh:380-383` — `if ! HEALTH_CHECK_SKIP_BATS=1 "$runner" --fast; then`. FC Claim 17 (executed; `test/scripts/health-check.bats` 17/17). | Fact-check | for-orchestrator-synthesis |
| The Run column is appended last with an in-place header migration; data rows are untouched and a second run is a no-op. Narrowed: this does not cover file mode or inode (R5). | ✅ Confirmed | `scripts/lib/si-functions.sh:542-568`. FC Claim 14 (executed, k=3). | Fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/guard-trusted-writes.py:10-109` | FC-1, FC-5, sec-3, sec-5, api-F1, arch-1, TD2 | distinct defects: arch-1 already states the shared root completely (the HARD set has no single owner), carried as R3; R4 is a distinct mechanism (symlink resolve) |
| 2 | `hooks/guard-trusted-writes.py:112-132` | FC-3, FC-4, sec-1, sec-4, TD1 | distinct defects: TD1 states the shared root (unnormalised text regex) as C11; R1, A10 and A8 are separate mechanisms with their own fixes |
| 3 | `scripts/questions.sh:51-57,198-331` | FC-10, FC-11, sec-2, api-F3, api-F4, arch-3, TD6 | distinct defects: each fragment states its own mechanism and fix |
| 4 | `scripts/lib/si-functions.sh:464-568` / `si-morning-summary.sh:1017-1349` | FC-15, FC-16, FC-sub25, api-F7/F8/F13, arch-2, TD3/4/5, perf-3 | distinct defects: arch-2 states the shared contract gap (A6); the others are separate mechanisms |
| 5 | `skills/code-review/references/rubric.md:31-504` + workflows | FC-18, FC-19, api-F2/F5/F6, arch-4/5, TD7/8 | distinct defects |
| 6 | `scripts/health-check.sh:370-391` | perf-1, perf-2, api-F11/F16, TD9 | distinct defects |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.

Tokens (from sub-agent completion notices):
- Fact-check: 346k + 315k + 318k
- Critics: security 251k, performance 261k, api-consistency 308k, architecture 277k, tech-debt 250k
- Submitted-claims pass: 210k
- Total ≈ 2.54M, excluding orchestrator.
