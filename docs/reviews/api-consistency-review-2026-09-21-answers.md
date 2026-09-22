Commit: 654c0ed

# API Consistency Review: answers-2026-09-20

**Scope:** `git -C /workspace diff e8d5fa1..answers-2026-09-20` (32 commits, 50 files). Public surfaces covered: CLI subcommands and env vars, working-doc data contracts, the guard hook's decision contract, installed paths, and skill/rubric vocabularies.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report.md` (merged, k=3, Commit 654c0ed). This review cites its Claims 5, 10, 11, 15, 16, 18, 19 and 20 and does not re-verify them.

## Baseline Conventions

- **Helper CLIs** (`scripts/questions.sh`, `scripts/run-tests.sh`, `scripts/archive-working-docs.sh`) take a bare-verb subcommand (`check`, `index`, `archive`, `next-id`, `open`) or `--flag` options. Path overrides are `UPPER_SNAKE` env vars that end in `_FILE` or `_DIR` (`HYPOTHESIS_LOG_FILE`, `ROUND_HISTORY_FILE`, `SKILLS_DIR` at `scripts/flag-removal-candidates.sh:47-51`; `HEALTH_CHECK_SKILLS_DIR`), or in a noun (`QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE`). Opt-out knobs are `*_SKIP_*=1`, compared as the exact string `1` (`CC_SKIP_HOOK_WIRING` at `devcontainer-config/link-claude-home.sh:94`).
- **SI-loop env vars** carry an `SI_` prefix (`SI_CODE_REVIEW_MODEL`, `SI_PRIORITIES`, `SI_OFF_LIMITS`, `SI_FEEDBACK`, `SI_CONTEXT`, `SI_PRIORITY_HYPOTHESES_JSON`). None of them is listed in the `self-improvement.sh` header's "Environment variables" block.
- **Working-doc files** in `docs/working/` use kebab-case names (`round-history.json`, `problem-history.json`, `completed-tasks.md`). Archived copies are `archive/<date-prefix>-<name>`. `_archived_newest_first` treats lexical glob order as chronological (`si-morning-summary.sh:1125-1142`).
- **hypothesis-log.md** is a markdown table with Title-Case headers (`Round | Task ID | … | Evidence`). Readers look up columns by header name (`_locate_log_col`, `flag-removal-candidates.sh:82-85`, `_project_state_open_hypotheses`), except for fields 1-3, which are read by position (`si-morning-summary.sh:1011-1013`). The writer, `append_approved_hypotheses`, uses a fixed positional `printf` layout.
- **Error semantics:** a missing required input fails loudly (`flag-removal-candidates.sh:54-56`, `questions.sh check`, `run-tests.sh` exit 1 on "No test files matched").
- **Override-log verdicts** are Title-Case, hyphenated tokens (`Must-Fix`, `Must-Address`, `Won't-Fix`, `Defer`). The format is defined in two places: `docs/reviews/override-log.md` § Capture format and `skills/code-review/references/override-log.md` § Capture format.
- **Guard hook tiers:** `HARD` (defer to `permissions.deny` for file tools, `deny` for Bash) and `SOFT` (`ask` when the session is web-tainted). The documented invariant is that HARD for file tools means exactly the set `hooks/wiring.json` `permissions.deny` covers (`guard-trusted-writes.py:13-17`, `wiring.json` `_comment`).
- **Rubric severity vocabularies:** each critic has its own native scale (security Critical/High/…, api-consistency Breaking/Inconsistent/…, ui-visual Critical/Major/Minor/Informational at `ui-visual-review/SKILL.md:388`, test-strategy `Priority: high / medium / low` at `test-strategy/SKILL.md:196`). The rubric maps each scale onto 🔴/🟡/🟢.
- **Cross-doc links** use GitHub heading slugs. Headings inside fenced templates produce no anchor.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `questions.sh init` | CLI subcommand | `check`, `index`, `archive`, `next-id`, `open` | `scripts/questions.sh:28-33` | Consistent. Bare verb, same dispatch `case`. |
| `SI_RUN_ID` | env var | `SI_CODE_REVIEW_MODEL`, `SI_PRIORITIES`, `SI_OFF_LIMITS` | `scripts/self-improvement.sh:458,497,1455` | Consistent prefix. Like its siblings, it is missing from the header env-var list (Informational). |
| `docs/working/si-run-id.txt` | data file | `round-history.json`, `problem-history.json`, `completed-tasks.md`; `si-` prefix on `scripts/lib/si-*.sh` | `scripts/archive-working-docs.sh:58-67`, `scripts/lib/` | Consistent kebab-case. It is the first `si-` file in docs/working, which is acceptable. |
| `Run` (hypothesis-log column) | table column | `Task ID`, `Round`, `Checked at Round` | `scripts/lib/si-functions.sh:497` | Minor. Its producers are `SI_RUN_ID` and `si-run-id.txt`, and the sibling identifier column is `Task ID`, so `Run ID` would match better. See F10. |
| `HEALTH_CHECK_SKIP_BATS` | env var | `HEALTH_CHECK_SKILLS_DIR`, `CC_SKIP_HOOK_WIRING` | `scripts/health-check.sh:14-19`, `devcontainer-config/link-claude-home.sh:94` | Consistent. Uses the `HEALTH_CHECK_` prefix and the `_SKIP_` + `== 1` convention. |
| `HEALTH_CHECK_RUN_TESTS` | env var (path seam) | `HEALTH_CHECK_SKILLS_DIR`, `HYPOTHESIS_LOG_FILE`, `ROUND_HISTORY_FILE` | `scripts/health-check.sh`, `scripts/flag-removal-candidates.sh:47-48` | Minor. Path overrides end in `_DIR`/`_FILE`; this one holds a path but reads like a boolean. See F11. |
| `Accepted-immutable` | override-log verdict | `Won't-Fix`, `Must-Fix`, `Must-Address` | `skills/code-review/references/override-log.md:20-21` | Minor. Siblings capitalize every hyphenated word; this one lowercases the second. See F9. |
| `Fact-check Incorrect` | override-log Original verdict | `🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, `Nit` | same | Informational. It is the first non-tier value in that column. Clearly scoped to `Accepted-immutable` rows. |
| `[auto: code-review]` | Reason-cell marker | none in the override log | none. Searched `docs/reviews/override-log.md`, `skills/code-review/references/`, `workflows/` | New category. Informational (see F12). |
| "qualifying author note" / "discoverable TODO" / "concrete revisit trigger" | rubric vocabulary | "author note", "Areas of uncertainty" | `skills/code-review/references/rubric.md`, `chat-synthesis.md`, `workflows/pr-prep.md`, `workflows/review-fix-loop.md` | Consistent. Used with the same words in all four places. |
| contextual-critic row `P1` / `P2 and below` | severity mapping key | test-strategy `Priority: high / medium / low` | `skills/test-strategy/SKILL.md:196` | **Inconsistent.** The scale does not exist. See F2. |
| `Disputed`, `Secondary-only` (draft-review Amber rows) | verdict names | fact-check verdict scale | `skills/fact-check/SKILL.md:161-172,545` | Consistent. Spelled exactly as fact-check emits them. |
| `business-plan-critique-market-sizing` (draft-review critic list) | skill id | `business-plan-critique-moat`, `-unit-economics` | `skills/business-plan-critique-*/` | Consistent. |
| `_migrate_hypothesis_log_run_column`, `_live_run_matches` | private helpers | `_find_tasks_file`, `_locate_log_col`, `_archived_newest_first` | `scripts/lib/si-morning-summary.sh` | Consistent (`_snake_case` internal helpers). |

## Findings

#### F1. The file-tool HARD set no longer equals the `permissions.deny` set when `CLAUDE_CONFIG_DIR` is set

**Severity:** Breaking
**Location:** `hooks/guard-trusted-writes.py:10-12,56-68` vs `hooks/wiring.json` `permissions.deny`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High (fact-check Claim 5, executed, k=3)
**Legibility-target:** for-author

Evidence: the hook docstring says HARD is "the GLOBAL config dir only … (the config dir is $CLAUDE_CONFIG_DIR when set, else ~/.claude — the same {{CLAUDE_DIR}} hooks/wiring.json substitutes)". The code does something different: `dirs = [HOME / ".claude"]` and then `if cfg: dirs.append(...)`, so the HARD set is the union of both directories. `wiring.json` denies only `Edit({{CLAUDE_DIR}}/settings*.json)`, `Edit({{CLAUDE_DIR}}/hooks/**)`, …, and `link-claude-home.sh:36` substitutes `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`.

The hook's own contract depends on this equality: "this hook must NEVER 'ask' on a HARD path — it DEFERS (lets the deny rule block the file tools)". With `CLAUDE_CONFIG_DIR=/x`, the hook still classifies `~/.claude/hooks/**` and `~/.claude/settings*.json` as HARD and defers. No deny rule names them, so they get no gate at all. That is the exact state the Q-026 rationale in the same docstring says a deferral must never create. The hook also expands `~` in the variable, but the linker does not (Claim 5 annotation), which is a second way the two sides disagree about what "the global dir" is. Exploitability belongs to security-reviewer. From the contract side, the invariant documented in both files is violated.

**Recommendation:** Derive `GLOBAL_DIRS` exactly as the linker does: `CLAUDE_CONFIG_DIR` if set, else `~/.claude`, with no `~` expansion the linker doesn't do. Alternatively, have the linker emit deny rules for every directory the hook treats as HARD. Add a test that checks the hook's HARD set against the rendered deny list for both the set and unset cases.

#### F2. The contextual-critic mapping keys on a test-strategy scale (`P1`/`P2`) that test-strategy never emits

**Severity:** Inconsistent
**Location:** `skills/code-review/references/rubric.md:288-292`, `:340`, `:504`; `skills/code-review/SKILL.md:1230`
**Move:** 2 (naming against the grain), 3
**Confidence:** High (fact-check Claim 19)
**Legibility-target:** for-author

Precedent: `**Priority:** [high / medium / low]` used in `skills/test-strategy/SKILL.md:196`

Evidence: `| 🟡 Must Address | Major | P1 | any confirmed finding |` and `| 🟢 Consider | Minor and below | P2 and below | — |`. The other two columns of the same row use their critics' real scales: ui-visual Critical/Major/Minor and the scale-less critics. Only the test-strategy column invents one. A synthesizer mapping a confirmed test-strategy finding has to guess whether `high` means P1 (→ 🟡) or whether `medium` also counts. The row exists to make that mapping mechanical, and the guess defeats it. The same `P1→🟡` wording is repeated in three other places, so fixing one site leaves drift in the rest.

**Recommendation:** Replace `P1` with `high` and `P2 and below` with `medium, low` at all four sites. Alternatively, define in one place how test-strategy priorities map to P-levels and link to it.

#### F3. questions.sh now resolves from `$PWD`, but `index`, `archive`, `open` and `next-id` report success when the files do not exist

**Severity:** Inconsistent
**Location:** `scripts/questions.sh:51-57` (resolution), `cmd_index` / `cmd_archive` / `cmd_open` / next-id
**Move:** 3, 4 (error consistency)
**Confidence:** High (probe below; resolution itself is Claim 10)
**Legibility-target:** for-author

Evidence: I ran the script from a subdirectory of a fresh git repo with no `docs/working/`:

```
== next-id   -> Q-001            rc=0
== check     -> ✗ missing: …/docs/working/questions.md   rc=1
== open      -> (no output)      rc=0
== index     -> ✓ indexes regenerated   rc=0
== archive   -> ✓ indexes regenerated / ✓ archived 0 entries   rc=0
```

Before this diff, the "files missing" state could not happen, because the script always resolved to claude-workflows' own doc. Now it is the default state in every project that has not run `init`. The global instructions tell agents to `next-id` and then `index`, and in such a project both succeed without saying anything. `index` even prints ✓ for files that are not there. Only `check` treats the missing inputs as an error. The baseline (`flag-removal-candidates.sh:54-56`, `check`) fails loudly on missing inputs.

The change also breaks a consumer: anyone who ran `~/claude-workflows/scripts/questions.sh` from outside that checkout to manage its queue now gets a different file set, or none, and every command except `check` still exits 0. The move away from the old wrong-repo behavior is intended (Q-025). The silent-success mode is the part that isn't.

**Recommendation:** Make every subcommand except `init` fail with the same `✗ missing: <path> — run: questions.sh init` message that `check` uses when a file is absent. Add a bats case for `index` and `next-id` in an un-initialized project.

#### F4. The script's invocation path is spelled three ways across the docs and the script's own hints

**Severity:** Inconsistent
**Location:** `global-instructions/CLAUDE.md:235,281`; `workflows/divergent-design.md:340`; `scripts/questions.sh:198,214`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `~/.claude/scripts/<helper>` used in `workflows/pr-prep.md` and `workflows/review-fix-loop.md` for `lite-review.py`, with the parenthetical "(In claude-workflows itself, `scripts/lite-review.py` is the same file.)"

Evidence: the global instructions now say `Get the next ID from ~/.claude/scripts/questions.sh next-id`. The DD Path-C text added in this diff says `the ID from scripts/questions.sh next-id (or the next unused Q-NNN if the project has no script)` and `Run scripts/questions.sh index afterwards where the script exists`. The script's own remediation hints still print `run: scripts/questions.sh archive` and `run: scripts/questions.sh index`. In any project other than claude-workflows, `scripts/questions.sh` does not exist. The DD fallback clause ("if the project has no script") also describes a situation the Q-025 install change removed. lite-review.py got the installed-path treatment consistently, and questions.sh did not.

**Recommendation:** Use `~/.claude/scripts/questions.sh` in DD step 4 and in the script's hints (for example, derive the hint from `$0`). Drop the "if the project has no script" fallback, or reword it to "if `~/.claude/scripts/` is not installed".

#### F5. Dead anchor `rubric.md#-must-address` in pr-prep and review-fix-loop

**Severity:** Minor
**Location:** `workflows/pr-prep.md` (Must Address tier row), `workflows/review-fix-loop.md:43`
**Move:** 3
**Confidence:** High (fact-check Claim 18; independently confirmed: the `## 🟡 Must Address` heading at `rubric.md:49` sits inside the fence that spans `:31-158`)
**Legibility-target:** for-author

These are the two links that define "qualifying author note" for the loop's exit condition, and they resolve to nothing. All other links added in the diff resolve (checked every added `](…#…)` link).

**Recommendation:** Link to `rubric.md#deliverable-2-code-review-rubric`, or add a real (unfenced) heading or explicit anchor for the qualifying-note definition.

#### F6. The canonical override-log file still describes a human-only log with the old verdict vocabulary

**Severity:** Inconsistent
**Location:** `docs/reviews/override-log.md:3-6,24-31` (not in the diff) vs `skills/code-review/references/override-log.md:20-34`, `skills/code-review/SKILL.md:158`
**Move:** 3 (documentation drift), 7
**Confidence:** High
**Legibility-target:** for-author

Evidence: the log file's preamble says "This file records **human overrides**". Its own Capture-format table lists `Original verdict` as "`🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, or `Nit`" and `Override verdict` as "`Won't-Fix`, `Defer`, …, etc.". The diff adds a machine-written row kind with `Original verdict: Fact-check Incorrect`, `Override verdict: Accepted-immutable`, and a `[auto: code-review]` Reason prefix. It documents that row kind only in the skill's reference file. The log therefore now has two diverging format definitions, and the one a reader opens first, in the file they are appending to, doesn't know the new row kind exists. It even says the rows are human decisions. review-fix-loop avoids the problem by saying "the verdict vocabulary is owned by the override-log reference", but the log file doesn't point there.

**Recommendation:** Replace the log file's Capture-format section with a pointer to `skills/code-review/references/override-log.md#capture-format`, or add the `Accepted-immutable` / `[auto: code-review]` row kind to it. Also amend "records human overrides" to allow machine-written rows.

#### F7. hypothesis-log `Run` is read by position-after-split, so escaped `\|` in a hypothesis shifts the cell

**Severity:** Minor
**Location:** `scripts/lib/si-functions.sh:534-538` (writer escapes `|`→`\|`); `scripts/lib/si-morning-summary.sh:1017` (`row_run=$(_pick_col fields "$run_col")`)
**Move:** 7 (write/read asymmetry), 8
**Confidence:** Medium (fact-check Claim 16, r2 annotation, executed)
**Legibility-target:** for-author

Evidence: the writer escapes pipes (`hyp="${hyp//|/\\|}"`), but `_split_row_fields` splits on every `|`. A new row whose hypothesis contains `\|` loses its run id. An old row reads its `Evidence` text as `Run` and then tries `archive/<evidence-text>-tasks-round-N.json`. The newest-first fallback limits the damage, but the new column is the most exposed to this, because it is last and so every earlier escaped pipe shifts it. The migration also assumes the writer's fixed 11-column layout. It appends `Run` after whatever header exists, while `printf` always writes the run id as cell 12. A log with any additional column (the readers already look up a `Scope` column the writer never creates) would misalign.

**Recommendation:** Teach `_split_row_fields` to honor `\|`, or keep the escape and make the reader count cells from the right for `Run`. Have `append_approved_hypotheses` emit cells by header position, or refuse to append when the header is not the known 11/12-column layout.

#### F8. Migration changes the log's file mode (0600) and inode even on the documented no-op path

**Severity:** Minor
**Location:** `scripts/lib/si-functions.sh:545-568`
**Move:** 3 (subtle behavior change for consumers of the file)
**Confidence:** High (fact-check Claim 15, executed)
**Legibility-target:** for-author

The comment says "No-op when the header already has a Run cell or no header is found". The no-header path still rewrites the file through `mktemp`+`mv`, and every migration leaves `hypothesis-log.md` at mode 0600 with a new inode. Anything that holds the file open or relies on its group/other read bits sees a change that the "no-op" contract rules out.

**Recommendation:** Return before `mktemp` when no header row is found, and preserve the mode (for example `chmod --reference` or `cat > "$log_file"`).

#### F9. `Accepted-immutable` breaks the Title-Case-hyphen verdict pattern

**Severity:** Minor
**Location:** `skills/code-review/references/override-log.md:21,24-33`; `skills/code-review/SKILL.md:158`; `workflows/review-fix-loop.md:157`; `workflows/pr-prep.md`
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author

Precedent: `Must-Fix`, `Must-Address`, `Won't-Fix` used in `skills/code-review/references/override-log.md:20-21` and `docs/reviews/override-log.md:28-29`

Every existing multi-word verdict capitalizes each hyphenated word, and this one lowercases the second. The review-fix-loop filter matches `Override verdict` by exact string. Any tool or grep that anticipates `Accepted-Immutable` from the established pattern will miss these rows, and so will any hand-written row that follows the pattern.

**Recommendation:** Rename it to `Accepted-Immutable` everywhere while it has no rows yet. Alternatively, state that verdict matching is case-insensitive.

#### F10. `Run` column name vs `SI_RUN_ID` / `si-run-id.txt` / `Task ID`

**Severity:** Minor
**Location:** `scripts/lib/si-functions.sh:467,497`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `Task ID` column used in `scripts/lib/si-functions.sh:497` (hypothesis-log header); `run-id` used in `si-run-id.txt` and `SI_RUN_ID`

The same value is called "run id" at its source and in the file, but the column that stores it is called `Run`. The sibling identifier column is `Task ID`, so a reader could take `Run` for a count or a round-like ordinal. Existing readers look columns up by exact name, so renaming later is a breaking change for the lookup in `si-morning-summary.sh:972`. The cheap window to rename is before the first real SI run writes the column.

**Recommendation:** Consider `Run ID`, with the header, migration token and `_locate_log_col` lookup changed together. Otherwise keep `Run` and note in the header comment that it holds `SI_RUN_ID`, which the comment already partly does.

#### F11. `HEALTH_CHECK_RUN_TESTS` holds a path but reads as a boolean

**Severity:** Minor
**Location:** `scripts/health-check.sh:25-26`, `check_bats`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: path overrides suffixed `_DIR`/`_FILE` used in `scripts/health-check.sh` (`HEALTH_CHECK_SKILLS_DIR`) and `scripts/flag-removal-candidates.sh:47-51` (`HYPOTHESIS_LOG_FILE`, `ROUND_HISTORY_FILE`, `SKILLS_DIR`)

It sits next to `HEALTH_CHECK_SKIP_BATS=1`, so `HEALTH_CHECK_RUN_TESTS=1` looks like a plausible "turn tests on" setting. If someone sets it that way, the script tries to execute `1` and fails gate 5 with an obscure error. It is documented as a test-only seam, which limits the impact.

**Recommendation:** Rename it to `HEALTH_CHECK_TEST_RUNNER`, or anything ending in a noun that names a command or path.

#### F12. `[auto: code-review]` establishes a machine-row marker convention

**Severity:** Informational (would be Minor; downgraded because there is no precedent)
**Location:** `skills/code-review/references/override-log.md:24-33`; `workflows/pr-prep.md` (override count excludes `[auto: code-review]` rows)
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

No existing precedent in `docs/reviews/override-log.md`, `skills/code-review/references/`, `workflows/` (searched for machine/auto row markers)

The marker is load-bearing: pr-prep's "declined findings = new override rows" completion count excludes rows that carry it. It is defined only as a free-text prefix inside `Reason`, not as a column or a fixed token list, so a typo (`[auto:code-review]`) silently breaks the count.

**Recommendation:** Name the exact literal in one place (the reference already does) and have pr-prep's count grep for that literal. If machine rows multiply, consider a `Source` column.

#### F13. `SI_RUN_ID` accepts any `[A-Za-z0-9._-]+`, but archive readers assume the prefix sorts by date

**Severity:** Minor
**Location:** `scripts/self-improvement.sh:458-463`; `scripts/archive-working-docs.sh:43-49`; `scripts/lib/si-morning-summary.sh:1125-1142`
**Move:** 3, 8
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: the variable is documented as "the date prefix", but it is validated only against a character class. `_archived_newest_first` returns glob order reversed. An override like `SI_RUN_ID=nightly` or `run2` therefore sorts after every date and is treated as the newest run for every row without a Run cell, which is the fallback path the Q-047 design relies on for legacy rows. The failure-analysis archive README makes the same point against ordering by a non-chronological key.

**Recommendation:** Require a leading `YYYY-MM-DD` (for example `^[0-9]{4}-[0-9]{2}-[0-9]{2}([._-][A-Za-z0-9._-]+)?$`) in both the writer and the archive reader. Alternatively, document that non-date ids degrade the newest-first fallback.

#### F14. `archive-working-docs.sh` changed its default prefix for standalone callers

**Severity:** Informational
**Location:** `scripts/archive-working-docs.sh:4-8,39-49`
**Move:** 3 (subtle default change)
**Confidence:** High
**Legibility-target:** for-author

The default used to be today's date. It is now the first line of `docs/working/si-run-id.txt` whenever that file exists. A user archiving unrelated working docs days after an un-archived SI run gets them stamped with the old run's date. This is intended and documented in the usage header. It is self-healing, because `si-run-id.txt` is not in `PERMANENT` and is itself archived on the first run. Recorded so the changed default is a visible decision.

**Recommendation:** Print the chosen prefix and its source ("prefix 2026-09-20 from si-run-id.txt") in the output, dry-run included.

#### F15. The same path gets different tiers depending on the tool

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:24-31` (Bash) vs `:80-109` (file tools)
**Move:** 7
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

A project's `.claude/settings.json` is SOFT for Edit/Write (ask only when tainted) but HARD/deny for Bash. `global-instructions/CLAUDE.md` is SOFT for Edit/Write but HARD for Bash. For Bash, `$CLAUDE_CONFIG_DIR/hooks/…` without a literal `.claude/` in the command text is not HARD at all, while the file tools treat `CLAUDE_CONFIG_DIR` as the global dir. The docstring documents the first two ("Bash is classified by command TEXT, so it can't resolve a relative path"), so this is a deliberate asymmetry. The third is not documented, and security-reviewer owns its exploitability. Users of bare-host installs also run a copied hook (`README.md:134`, "re-copy deliberately after repo changes"), so they keep the pre-Q-026 tiers until they re-copy it.

**Recommendation:** Add the `CLAUDE_CONFIG_DIR` limitation to the Bash block of the docstring, and mention the re-copy in the Q-026 commit/guide (`guides/bare-host-hook-wiring.md:52-53` still lists the HARD tier as `~/.claude/...` only, which matches the unset case).

#### F16. run-tests.sh still says its report-gating "mirrors scripts/health-check.sh"

**Severity:** Minor
**Location:** `scripts/run-tests.sh:80-85` (not in diff) vs `scripts/health-check.sh` check 5 comment
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence: run-tests.sh says `Report-gating (mirrors scripts/health-check.sh)` and `exactly as health-check does`. The diff removed health-check's own gating and now says "Report gating … is owned by run-tests.sh, so it is not repeated here." Each file now names the other as the owner.

**Recommendation:** Change the run-tests.sh comment to say it owns report-gating and that health-check gate 5 delegates to it.

#### F17. performance-reviewer's Macro × Cold escalation adds a "large data" condition the hot-path gate lacks

**Severity:** Minor
**Location:** `skills/performance-reviewer/SKILL.md:283` vs `:46`
**Move:** 1 (baseline within one skill)
**Confidence:** High (fact-check Claim 20)
**Legibility-target:** for-author

The table's default is now "Low (matches the hot-path gate; …)", which fixes the old Medium/Low contradiction. But it adds "or runs over large data, e.g. a nightly batch", and the gate at `:46` allows escalation only "unless the cold path blocks a latency-sensitive operation". Two rules in the same skill now state different escalation criteria, while the table claims to match the gate.

**Recommendation:** Add the large-data clause to the gate at `:46`, or drop it from the table.

## What Looks Good

- **Run is appended as the last column, with an in-place migration.** Every existing reader uses name lookup (`_locate_log_col`) or positions 1-3, so old logs and old readers keep working. Rows without a Run cell fall back to the prior newest-first behavior. This is the right backward-compatible shape for a data-contract addition.
- **The `questions.sh` resolution change pins health-check.** `check_questions_doc` sets `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE` to this repo's files, so the repo gate means the same thing wherever it is launched from. `init` is idempotent for existing regular files (Claim 11 caveat: dangling symlinks).
- **`init` follows the existing bare-verb subcommand grammar**, and the global instructions document the full subcommand set in one sentence.
- **`HEALTH_CHECK_SKIP_BATS` follows the `*_SKIP_*=1` convention exactly.** The recursion guard skips with a warning rather than passing.
- **Fact-check verdict names (`Disputed`, `Secondary-only`) are reused verbatim in draft-review's Amber tier.** The market-sizing critic was added consistently across draft-review, skill-trigger-guide and the triage-table descriptions.
- **Ownership statements are explicit.** review-fix-loop now says which doc owns which rule ("Each rule is stated in one place; the others link to it"). pr-prep replaced its duplicated escalation template and exit rules with links, which is a real consistency gain.
- **The installed-path convention (`~/.claude/scripts/…`) is applied consistently to lite-review.py**, with the in-repo alias noted, and the README, install.sh and link-claude-home.sh all state the same reason for shipping `scripts/`.
- **The qualifying-author-note vocabulary is defined once (rubric) and reused with identical wording** in chat-synthesis rules 4/5, pr-prep and review-fix-loop. Rules 4/5 are now exhaustive for 0 🔴.
- **architecture-review's new `Commit:` citation matches the metadata line security-reviewer already writes** (`security-reviewer/SKILL.md:557`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | File-tool HARD set ≠ `permissions.deny` set under `CLAUDE_CONFIG_DIR` | Breaking | `hooks/guard-trusted-writes.py:56-68` / `hooks/wiring.json` | High |
| F2 | Contextual-critic row keys on nonexistent test-strategy `P1`/`P2` | Inconsistent | `skills/code-review/references/rubric.md:288-292` (+3 sites) | High |
| F3 | questions.sh non-`check` subcommands succeed on missing files | Inconsistent | `scripts/questions.sh:51-57` | High |
| F4 | questions.sh invocation path spelled 3 ways (DD, script hints, global) | Inconsistent | `workflows/divergent-design.md:340`, `scripts/questions.sh:198,214` | High |
| F6 | `docs/reviews/override-log.md` format and preamble unaware of machine rows | Inconsistent | `docs/reviews/override-log.md:3-31` | High |
| F5 | Dead anchor `rubric.md#-must-address` | Minor | `workflows/pr-prep.md`, `workflows/review-fix-loop.md:43` | High |
| F8 | Migration "no-op" still rewrites file, mode 0600 | Minor | `scripts/lib/si-functions.sh:545-568` | High |
| F9 | `Accepted-immutable` casing vs `Won't-Fix`/`Must-Fix` | Minor | `skills/code-review/references/override-log.md:21` | High |
| F16 | run-tests.sh/health-check each name the other as report-gating owner | Minor | `scripts/run-tests.sh:80-85` | High |
| F17 | Macro × Cold escalation clause not in hot-path gate | Minor | `skills/performance-reviewer/SKILL.md:46,283` | High |
| F7 | Escaped `\|` shifts the `Run` cell; writer layout fixed | Minor | `si-functions.sh:534-538`, `si-morning-summary.sh:1017` | Medium |
| F10 | `Run` vs `Run ID` / `Task ID` | Minor | `scripts/lib/si-functions.sh:497` | Medium |
| F11 | `HEALTH_CHECK_RUN_TESTS` reads as boolean | Minor | `scripts/health-check.sh` | Medium |
| F13 | Non-date `SI_RUN_ID` breaks newest-first ordering | Minor | `scripts/self-improvement.sh:458-463` | Medium |
| F14 | archive-working-docs default prefix changed | Informational | `scripts/archive-working-docs.sh:39-49` | High |
| F15 | Per-tool tier asymmetry; Bash ignores `CLAUDE_CONFIG_DIR` | Informational | `hooks/guard-trusted-writes.py:24-31` | High |
| F12 | `[auto: code-review]` marker is a free-text load-bearing token | Informational | `skills/code-review/references/override-log.md:24-33` | Medium |

## Overall Assessment

Most of the surface this diff adds follows the conventions the repo already has: the `init` verb, the `SI_`/`HEALTH_CHECK_` env names, the `_SKIP_=1` knob, the last-column-plus-migration data change, and the reused fact-check verdicts. Where the diff consolidates doc ownership (review-fix-loop and pr-prep), it measurably reduces duplication.

The consistency problems are at seams where one side of a contract changed and the other did not:
- **Hook vs deny list (F1):** the only Breaking item. Its documented invariant no longer holds when `CLAUDE_CONFIG_DIR` is set.
- **Rubric vs test-strategy (F2):** the mapping row uses a scale test-strategy doesn't have.
- **questions.sh vs its callers (F3, F4):** the script now points at the caller's project, but its error semantics and the docs that call it still assume the old always-present file.
- **Override log vs its skill reference (F6):** the log file doesn't know about the new machine-written row kind.

All of these can be fixed in place with small edits. None needs a redesign. F1 and F3 are the ones consumers will hit: bare-host or `CLAUDE_CONFIG_DIR` users, and every non-claude-workflows project that follows the global instructions.

## Goal-Alignment Note

- **Answered:** an API-consistency review of the full `e8d5fa1..answers-2026-09-20` range, covering every public surface named in the brief: questions.sh `init` and `$PWD` resolution, including subdir, non-git and missing-file behavior (probed); `SI_RUN_ID` and `si-run-id.txt`; the archive-working-docs default prefix; `HEALTH_CHECK_SKIP_BATS`/`HEALTH_CHECK_RUN_TESTS` and run-tests flags; the hypothesis-log Run column and its readers; override-log row kinds; guard-hook tiers vs `permissions.deny` and `{{CLAUDE_DIR}}`; installed `~/.claude/scripts/*` paths; and the rubric, fact-check, draft-review, performance and architecture vocabularies, plus every added cross-doc anchor (checked by script). The name-pattern audit is included.
- **Out of scope:** the exploitability of guard-hook bypasses (Claims 1, 3 and 5's security side), left to security-reviewer; F1 and F15 state only the contract mismatch. Worktree and submodule resolution for questions.sh was not probed separately; I relied on fact-check Claim 10. The Claim 6 `Accepted-immutable` row and the Claim 19 hallucination-patterns entry are orchestrator actions and are not repeated here.
- **Escalate:** F1 (Breaking) to the orchestrator and security-reviewer as the same root cause as fact-check Claim 5. F6 matters if the orchestrator writes the Claim 6 `Accepted-immutable` row this run: it would land in a file whose own format section doesn't recognize that row kind.
