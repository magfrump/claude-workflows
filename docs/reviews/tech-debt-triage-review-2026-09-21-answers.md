Commit: 654c0ed

# Tech-Debt Triage Review: `e8d5fa1..answers-2026-09-20`

**Critic:** tech-debt-triage (contextual and advisory, triggered because the diff is >10 files / >500 lines)
**Scope:** `git -C /workspace diff e8d5fa1..answers-2026-09-20` (32 commits, 50 files, +1476/-636)
**Factual foundation:** `docs/reviews/code-fact-check-report.md` (merged k=3). Where a finding rests on a fact-check claim it cites `FC-N`. This review does not re-verify those claims.
**Delivery:** self-read. I read the code diffs in full, the enclosing units of every function cited below, and the workflow/reference doc diffs for pr-prep, review-fix-loop and code-review.

Rubric note: findings from contextual critics go to 🟢 Consider (rubric.md:340). The Severity labels below are this critic's own carry/fix weighting. TD1 and TD2 overlap the security escalations the fact-check already addressed to security-reviewer (FC-1, FC-3, FC-5). They are recorded here as *debt shape*, not as new security findings. The security verdict belongs to that critic.

---

## Net summary

This batch **retires more debt than it adds**.

**Retired:**
- The dead survivors carry-over in the SI loop (~55 lines, `56b9883`).
- `failure-analysis.sh`, which had no callers and a wrong metric (`2cf5143`).
- The inert flat-file `skills/claude-api.md` (`5928c47`).
- Gate 5's blind spot over ~40 suites (`0ccbdb8`). health-check is also now sourceable (`BASH_SOURCE` guard).
- Duplicated loop rules between pr-prep and review-fix-loop (`6eb89cd`). One owner per rule.
- questions.sh no longer sends every project's questions into this repo's doc (Q-025).

**Added or extended:**
- Most of the risk is concentrated in `hooks/guard-trusted-writes.py`. There, the narrowing of the HARD tier was implemented on the two most fragile mechanisms the hook has: regex over raw command text, and path relativity against a hand-built directory list (TD1, TD2).
- The rest is small or inert.

---

## Findings

### TD1 — Bash tier is regex-over-raw-command-text, and each narrowing re-opens spelling bypasses

- **Severity:** High (tail risk). Carrying cost is Medium.
- **Location:** `hooks/guard-trusted-writes.py:121-129` (`_GLOBAL_PREFIXES`, `HARD_FRAG`). Consumer: `bash_targets` at `:135-143`, read in full.
- **Evidence (verbatim):**
  ```python
  HARD_FRAG = re.compile(
      r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md|managed-settings"
      r"|(?:" + "|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md",
      re.I)
  ```
  FC-3 (Incorrect, executed, all 3 replicates): `"$HOME"/CLAUDE.md`, `~//CLAUDE.md`, `~/./CLAUDE.md`, `${HOME:-}/CLAUDE.md`, `$HOME/x/../CLAUDE.md` and `~/.claude//CLAUDE.md` all went from deny at e8d5fa1 to SOFT. FC-3 notes that `"$HOME"/CLAUDE.md` "is the ordinary quoted form — not only crafted input". FC-9 finds that no test covers the quoted or normalised spellings.
- **Nature:** structural. A classifier matches surface text with no normalisation step.
- **Cost of Deferral:** `+1 regressed spelling-class per tier-narrowing change`. The hook has 5 commits since creation. Two of them (`0f0e011` fd redirects, `4c7a2bb` this narrowing) were regex edits, and each changed which spellings match. The old broad pattern `(^|[\s\"'=~/])CLAUDE\.md` masked this. Narrowing it exposed the problem.
- **Failure Cost:** `Med × High`. In a web-tainted session, a prompt-injected shell write to the global CLAUDE.md or `~/.claude` policy files gets ask (or no gate when untainted) instead of deny. That is the injection path this hook exists to close.
- **Carrying cost:** Medium. Every future tier adjustment has to be re-proven against an open-ended set of shell spellings, and the test suite only asserts literal forms.
- **Fix cost:**
  - Scope: localized to the hook and its bats file.
  - Effort: hours.
  - Risk: low-medium, because over-normalising could turn benign commands into deny.
  - Incremental: yes.
  - Shape: before matching, normalise the command text. Strip shell quotes (`shlex`-style), collapse `//` and `/./`, and fold the `$HOME`, `${HOME}`, `${HOME:-…}`, `${HOME%/}` and `~` forms to one token. Then run the existing fragments. Add FC-3's spelling list as a table-driven bats case.
- **Urgency triggers:** already met. The regression shipped in this batch, and a tainted-session workflow (WebFetch plus shell writes) is routine.
- **Recommendation:** **Fix now.** Tail-risk debt on a trust boundary. Two files and a test table, so route it through the debugging loop or a short RPI plan.
- **Confidence:** High on the debt shape and the regression (FC-3 executed). Medium on the effort estimate.
- **Legibility-target:** for-author

### TD2 — "Global HARD" is defined in three places that disagree (docstring, `_global_dirs`, the deny-rule substitution)

- **Severity:** High (tail risk).
- **Location:** `hooks/guard-trusted-writes.py:56-68` (`_global_dirs`), `:71-78` (`_global_rel`), `:80-109` (`classify_path`, read in full), and `devcontainer-config/link-claude-home.sh` (`{{CLAUDE_DIR}}` substitution).
- **Evidence (verbatim):**
  ```python
  dirs = [HOME / ".claude"]
  cfg = os.environ.get("CLAUDE_CONFIG_DIR")
  if cfg:
      dirs.append(Path(os.path.expanduser(cfg)))
  ```
  (excerpt ends :60; enclosing `_global_dirs()` continues to :66 — read)
  - FC-5 (Incorrect): "Code always keeps `~/.claude` and adds `$CLAUDE_CONFIG_DIR`; deny rules cover only `{{CLAUDE_DIR}}` … `~/.claude/settings*.json` and `~/.claude/hooks/**` are HARD → deferred → **no gate**". The hook expands `~` in the variable and the linker does not.
  - FC-1 (Incorrect in the installed layout): "`resolve()` follows the installed symlinks out of `~/.claude` into `/opt/claude-workflows/`, which is not in `GLOBAL_DIRS`". The result is a SOFT **ask**, which overrides `permissions.deny` (#39344).
  - FC-4 annotation (r2): "a project settings write is an ask via Edit/Write but a deny via Bash". The same path lands in different tiers depending on which tool writes it.
- **Nature:** structural and configuration. There is no single source of truth for the protected set, and the hook's correctness depends on matcher semantics it does not own (for example, whether Claude Code's deny matcher normalises `..` or follows symlinks, which FC-1 leaves out of scope).
- **Cost of Deferral:** `+1 silent disagreement per change to either the linker/wiring or the hook`. They are edited in different commits with no test that joins them. `test/link-claude-home-wiring.bats` checks that the deny rules exist, not that they match `GLOBAL_DIRS`.
- **Failure Cost:** `Med × High`. Either a HARD path ends up with no gate (FC-5), or an ask overrides a deny (FC-1). Both are the exact outcomes the module docstring says must never happen.
- **Carrying cost:** Medium. Anyone who reasons about the tiers has to hold three definitions in their head, plus a Bash/file-tool asymmetry the docstring only partly admits ("the text doesn't say which").
- **Fix cost:**
  - Scope: the hook, the linker, and one new joint test.
  - Effort: hours to a day.
  - Risk: medium, because it changes the protected set.
  - Incremental: yes.
  - Shape:
    1. Derive `GLOBAL_DIRS` exactly as the linker computes `{{CLAUDE_DIR}}`. Either both expand `~` or neither does, and when `CLAUDE_CONFIG_DIR` is set, decide explicitly whether `~/.claude` stays protected (and by what).
    2. Add the *resolved targets* of each HARD entry (the `hooks/` and `CLAUDE.md` symlinks) to the HARD set.
    3. Add a bats fixture that reproduces the installed symlink layout. r3's synthetic fakehome missed FC-1 for exactly this reason.
    4. Assert in one test that the deny-rule globs and `GLOBAL_DIRS` name the same directories.
- **Urgency triggers:** already met in the installed layout (FC-1). `CLAUDE_CONFIG_DIR` is set in any multi-profile setup.
- **Recommendation:** **Fix now.** Non-trivial and multi-file, so hand it to RPI with this triage and FC-1/FC-5 as research input. Sequence it with TD1 in one branch, since both touch the same test file.
- **Confidence:** High (FC-1, FC-5 executed). Medium on whether the deny matcher itself normalises paths (not established).
- **Legibility-target:** for-author

### TD3 — SI_RUN_ID validation duplicated in two scripts; a third reader skips validation

- **Severity:** Low.
- **Location:** `scripts/self-improvement.sh:458-463`, `scripts/archive-working-docs.sh:43-48`, and `scripts/lib/si-morning-summary.sh` (`_live_run_matches`; the `row_run` read feeding `_find_tasks_file` and `_days_since_round`).
- **Evidence (verbatim):**
  - `self-improvement.sh:459`: `if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then`
  - `archive-working-docs.sh:45`: `if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then`
  - `si-morning-summary.sh`: `printf '%s\n' "$working_dir/archive/${run}-tasks-round-$round.json"`. Here `run` comes from the hypothesis-log Run cell and is not validated.
  - FC-13: the regex accepts `.`, `..` and `-rf`, which are "harmless because of how the archive script builds and moves the name, not because of the check itself".
- **Nature:** duplication. The contract ("only [A-Za-z0-9._-]") is enforced by two copies and assumed by a third, unvalidated reader.
- **Cost of Deferral:** `+0 — inert`. The character set is stable, the copies cross-reference each other in comments, and the unvalidated reader only builds read paths inside `archive/`.
- **Carrying cost:** Low.
- **Fix cost:**
  - Effort: under an hour.
  - Risk: low.
  - Caveat: `archive-working-docs.sh` sources no SI lib today, so sharing a helper adds a source dependency to a standalone script. The fix is about as costly as the debt.
- **Urgency triggers:**
  - The allowed character set changes.
  - A fourth reader appears.
  - The Run cell starts feeding a write path or a `rm`.
- **Recommendation:** **Carry intentionally.** If touched, have the morning-summary reader drop Run cells that fail the same regex. That is a trivial in-place change.
- **Confidence:** High.
- **Legibility-target:** for-author

### TD4 — `mktemp`+`mv` migration changes mode and inode, even on the no-op path

- **Severity:** Low.
- **Location:** `scripts/lib/si-functions.sh` `_migrate_hypothesis_log_run_column` (read in full). The same pattern predates this diff at `scripts/lib/si-input.sh:284`.
- **Evidence (verbatim):**
  ```bash
  tmp=$(mktemp "${log_file}.XXXXXX") || return 1
  awk '
  ...
  ' "$log_file" > "$tmp" && mv "$tmp" "$log_file"
  ```
  FC-15 (Incorrect): the docstring says "No-op when … no header is found", but the "file [is] rewritten via `mktemp`+`mv` even with no header: new inode, mode 0600; every real migration also leaves `hypothesis-log.md` at 0600".
- **Nature:** side-effect or implementation debt. The docstring promises a no-op the code does not deliver, and the pattern exists in two libs.
- **Cost of Deferral:** `+0 — inert`. The migration runs once per pre-Q-047 log. After that the Run-present early return is a real no-op (FC-14).
- **Failure Cost:** blank (not material; 0600 is stricter, not looser).
- **Fix cost:**
  - Effort: about 3 lines, trivial and in place.
  - Shape: return early when the awk probe finds no `Round` header, and preserve the mode (`chmod --reference="$log_file" "$tmp"` before `mv`, or `cat "$tmp" > "$log_file"`).
- **Urgency triggers:** a consumer that checks mode or inode, such as a backup, a hardlink or a non-owner reader.
- **Recommendation:** **Fix opportunistically.** Fold it into the next edit of si-functions.sh. If that edit happens, apply the same mode-preserving idiom to `si-input.sh:284`.
- **Confidence:** High (FC-15 executed).
- **Legibility-target:** for-author

### TD5 — The markdown table used as a datastore is split naively on `|`, and the Run column is its most-displaced cell

- **Severity:** Medium.
- **Location:** `scripts/lib/si-morning-summary.sh:1497-1509` (`_split_row_fields`, read in full) against the writer `append_approved_hypotheses` in `scripts/lib/si-functions.sh`.
- **Evidence (verbatim):**
  - writer: `hyp="${hyp//|/\\|}"`
  - reader: `IFS='|' read -ra raw <<< "$line"`
  - FC-16 annotation (r2): "rows whose hypothesis contains an escaped `\|` read the wrong cell as Run — an old row reads its Evidence value, a new row loses its run id; effect limited by newest-first fallback".
- **Nature:** pre-existing structural debt. The writer escapes pipes and the reader does not unescape them. This diff extends it: Run is placed last "so positional readers … keep working", and that makes it the cell every escaped pipe earlier in the row shifts.
- **Cost of Deferral:** `+1 misread column per new trailing column added to the log`. Run is the latest. Evaluator, Requires, Source and Window were already exposed.
- **Carrying cost:** Medium. The newest-first fallback hides the misread, so a wrong-run lookup looks the same as a correct one.
- **Fix cost:**
  - Scope: localized to one function.
  - Effort: hours.
  - Risk: low; the existing precondition-gate and morning-summary bats cover the reader.
  - Shape: split on unescaped `|` only, for example with awk `FPAT` or a sentinel substitution of `\|` before `IFS` splitting. Add a test row whose hypothesis contains `\|`.
- **Urgency triggers:**
  - The Run column starts gating an action, not just a lookup preference.
  - Planners start writing pipe-heavy hypotheses (for example ones that quote shell pipelines).
- **Recommendation:** **Fix opportunistically.** Do it next time the morning-summary parser is touched.
- **Confidence:** Medium. The mechanism is observed in code and FC-16 reports the effect; how often escaped pipes occur in real logs was not measured.
- **Legibility-target:** for-author

### TD6 — Three path-resolution conventions across the scripts, and health-check now works around one of them

- **Severity:** Low.
- **Location:**
  - `scripts/questions.sh:51-57`: git toplevel of `$PWD`.
  - `scripts/archive-working-docs.sh`: `WORKING_DIR="docs/working"` relative to the cwd, with the error "Run from repo root".
  - `scripts/health-check.sh:232` and `:1018-1026`: `BASH_SOURCE` repo root, plus pinning of `QUESTIONS_*`.
- **Evidence (verbatim):**
  - `questions.sh`: `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"`
  - `health-check.sh`: `if out="$(QUESTIONS_LIVE="${QUESTIONS_LIVE:-$REPO_ROOT/docs/working/questions.md}" \`
  - FC-10: "run from inside a `.git/` directory, `rev-parse --show-toplevel` fails and the fallback creates `.git/docs/working/`".
- **Nature:** consistency and cognitive-load debt. The Q-025 change is correct for an installed cross-project helper. The cost is that each script has its own answer to "which repo am I operating on", and the repo's own gate had to override its own tool.
- **Cost of Deferral:** `+1 env-override pin per in-repo caller of an installed helper`. Only lite-review.py and questions.sh are installed today.
- **Carrying cost:** Low.
- **Fix cost:**
  - Effort: an hour for the `.git/` guard, which is trivial: refuse, or climb out, when `$PWD` is inside a `.git` dir.
  - A shared `resolve_project_root` would be a small cross-script refactor, not worth it at two helpers.
- **Urgency triggers:** a third script is installed to `~/.claude/scripts/` for cross-project use, or `init` is run from a hook with an unusual cwd.
- **Recommendation:** **Defer and monitor.** Revisit when the third installed helper lands. The `.git/` guard can be fixed in place any time.
- **Confidence:** High.
- **Legibility-target:** for-author

### TD7 — Doc-rule consolidation (retires debt) leaves unchecked cross-doc anchors and one residual duplicate

- **Severity:** Low (net retirement).
- **Location:**
  - `workflows/pr-prep.md:190` and `workflows/review-fix-loop.md:43`, both linking `rubric.md#-must-address`.
  - The pr-prep Step 3b tier table.
  - `Accepted-immutable` is now defined or used across `skills/code-review/SKILL.md`, `references/override-log.md` (6 mentions), `references/rubric.md`, `workflows/pr-prep.md` and `workflows/review-fix-loop.md`.
- **Evidence (verbatim):**
  - review-fix-loop.md, new header: "This document owns the review-fix loop's control rules … Each rule is stated in one place; the others link to it."
  - pr-prep.md, still carrying a meaning column: `| Must Address | Fragility, inconsistency, misleading tests | Fix, or acknowledge with a discoverable TODO or a concrete revisit trigger ([qualifying author note](../skills/code-review/references/rubric.md#-must-address)) |`
  - FC-18 (Incorrect): the anchor does not exist because "the heading sits in a fenced block at `skills/code-review/references/rubric.md:31-158`".
- **Nature:** documentation structure. Replacing duplication with links is the right trade. The cost is dependence on anchors, and no health-check gate validates anchors (gate 2 checks workflow references in CLAUDE.md/AGENTS.md/GEMINI.md only). The first consolidation already produced one dead anchor at two sites. The pr-prep table's "Meaning" column still restates tier definitions the same paragraph says the rubric owns.
- **Cost of Deferral:** `+1 unverified anchor per consolidation edit`. This batch added about 8 new cross-doc links, and one of them was dead on arrival.
- **Carrying cost:** Low. A broken anchor lands at the top of the file, so it degrades rather than misleads.
- **Fix cost:**
  - The anchor fix is 2 lines, trivial and in place; FC-18 names `#deliverable-2-code-review-rubric`.
  - An anchor-resolving check added to health-check gate 2 would take hours.
- **Urgency triggers:** the next "one owner per rule" pass. More links raise the rate.
- **Recommendation:** **Fix opportunistically.** Fix the two links in place now. Add the anchor gate the next time health-check is edited. Carry the residual "Meaning" column intentionally, since it is short and the table is the action map.
- **Confidence:** High.
- **Legibility-target:** for-author

### TD8 — The contextual-critic severity mapping cites a test-strategy scale that does not exist

- **Severity:** Low.
- **Location:** `skills/code-review/references/rubric.md:288-292`, `:340`, `:504`; `skills/code-review/SKILL.md:1230`.
- **Evidence (verbatim):**
  - rubric.md:290: `| 🟡 Must Address | Major | P1 | any confirmed finding |`
  - rubric.md:340: "test-strategy P1→🟡"
  - FC-19 (Incorrect): "test-strategy emits only `Priority: high/medium/low` (`skills/test-strategy/SKILL.md:196`); the mapped scale does not exist".
- **Nature:** documentation. A mapping row can never fire as written, so orchestrators have to guess how to translate "high".
- **Cost of Deferral:** `+0 — inert` for gating (advisory tier). Each synthesis run that meets a test-strategy finding pays a small interpretation cost.
- **Carrying cost:** Low.
- **Fix cost:** 4 one-token edits, trivial and in place (`P1` → `high`, etc.). FC also routes a hallucination-patterns entry to the orchestrator.
- **Urgency triggers:** an Executable-Defect or Soundness lift on a test-strategy finding, which is where the mapping actually decides a tier.
- **Recommendation:** **Fix opportunistically.**
- **Confidence:** High (FC-19, static).
- **Legibility-target:** for-author

### TD9 — Gate 5 recursion guard and test seam: new coupling, net retirement

- **Severity:** Low (net retirement).
- **Location:** `scripts/health-check.sh` `check_bats` (read in full), and the env vars `HEALTH_CHECK_SKIP_BATS` and `HEALTH_CHECK_RUN_TESTS`.
- **Evidence (verbatim):** `if ! HEALTH_CHECK_SKIP_BATS=1 "$runner" --fast; then`. Header comment: "Before Q-023 this gate ran only test/skills/ and test/hooks/, so a green health-check said nothing about the ~40 suites under test/ and test/scripts/". FC-17: Verified, 17/17.
- **Nature:** coupling. The gate and one of the suites it runs (`test/scripts/health-check.bats`) invoke each other, and an env var breaks the cycle.
- **What it retires:** the coverage gap, a duplicated report-gating loop (now owned by run-tests.sh), and the non-sourceable script.
- **What it adds:** an invisible contract, namely that every nested health-check invocation must see `HEALTH_CHECK_SKIP_BATS=1`. It is documented at both ends. Gate 5 also now pays the slow-suite wall time.
- **Cost of Deferral:** `+0 — inert`.
- **Carrying cost:** Low.
- **Fix cost:** none needed.
- **Urgency triggers:** a second slow suite that shells out to health-check without going through run-tests.sh, or gate-5 wall time pushing people to skip health-check.
- **Recommendation:** **Carry intentionally.**
- **Confidence:** High.
- **Legibility-target:** for-orchestrator-synthesis

### Retired debt (no action; recorded so the ledger shows both sides)

- `self-improvement.sh`: removed the "DD Output Format Contract: Survivors Section" parser. Its own comment said it "will silently return no results" if the DD format drifted, and DD no longer emits that shape (`56b9883`).
- `archive/failure-analysis/`: the script and its test moved out of `test/`, and the README records the fix if it is ever revived. The README notes the script "sources `$SCRIPT_DIR/lib/preflight.sh`, which does not exist here". This is inert and documented (`+0`).
- `archive/docs/2026-09-21-claude-api.md`: a never-loaded flat skill file was removed from `skills/` and from the SI prompt's example list.
- `.gitignore` for the rubric archive, plus an in-code note that the corpus is local-only (Q-036). The debt is made explicit rather than removed. The remaining risk ("lost with the clone") is stated at the use site.

---

## Triage Summary

| # | Debt item | Carrying cost | Cost of deferral | Failure cost | Fix cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| TD1 | Bash tier: regex over raw command text; FC-3 spellings regressed | Medium | +1 regressed spelling-class per narrowing | Med × High — injected shell write to the global policy file gets ask, not deny | Hours | Met | Fix now |
| TD2 | Three disagreeing definitions of the global HARD set (FC-1, FC-5) | Medium | +1 silent disagreement per linker/hook change | Med × High — no gate, or ask overrides deny | Hours to a day | Met (installed layout) | Fix now |
| TD5 | Naive `\|` split in the hypothesis-log reader; Run is the most-displaced cell | Medium | +1 misread column per new trailing column | | Hours | None | Fix opportunistically |
| TD7 | Unchecked cross-doc anchors after the consolidation; residual tier-meaning duplicate | Low | +1 unverified anchor per consolidation edit | | Minutes (links) / hours (gate) | Next consolidation | Fix opportunistically |
| TD4 | mktemp+mv: mode 0600 and new inode on the "no-op" path | Low | +0 (inert) | | Minutes | None | Fix opportunistically |
| TD8 | test-strategy P1/P2 scale does not exist | Low | +0 (inert) | | Minutes | None | Fix opportunistically |
| TD6 | Three path-resolution conventions; `.git/` fallback | Low | +1 env pin per in-repo caller of an installed helper | | Hours | Third installed helper | Defer and monitor |
| TD3 | SI_RUN_ID regex in two places; unvalidated third reader | Low | +0 (inert) | | Under an hour | None | Carry intentionally |
| TD9 | Gate 5 recursion guard and seam (net retirement) | Low | +0 (inert) | | None | None | Carry intentionally |

### Recommended Order

1. **TD1 and TD2 together, in one branch.** Both are the guard hook plus `test/hooks/guard-trusted-writes.bats`, so sequencing them avoids a merge collision. Normalise the Bash text (TD1) and unify the HARD set (TD2) in the same fixture pass, and add the installed-symlink-layout fixture for both. This is the only batch-introduced debt with a real tail. Route it through RPI, with this report and FC-1/3/5 as research input.
2. **The trivial in-place fixes, as one small commit:** the TD7 anchor (2 links), the TD8 scale tokens (4 sites), and the TD4 mode and early-return.
3. **TD5**, the next time the morning-summary parser is touched.
4. **TD6 and TD3:** watch their triggers only.

---

## Goal-Alignment Note

- **Success criterion (restated):** Critique saved to `docs/reviews/tech-debt-triage-review-2026-09-21-answers.md`, first line `Commit: 654c0ed`, each finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note. No other repo file modified.
- **Answered:**
  - Each item in the brief is triaged with carry/fix/urgency framing:
    - regex-on-command-text classification: TD1
    - duplicated SI_RUN_ID regex: TD3
    - mktemp-mode side effects: TD4
    - doc rules spread across pr-prep, review-fix-loop and the code-review references: TD7
    - archived scripts: the Retired section
  - Four additional items: TD2, TD5, TD6 and TD9.
  - Retired debt is recorded so the ledger is two-sided.
- **Out of scope:** security verdicts on the guard bypasses. They are cited from FC-1/3/5 and belong to security-reviewer. I did not re-execute any fact-check claims. Effort estimates are unmeasured judgment.
- **Escalate:** TD1 and TD2 carry `Med × High` failure cost on a trust boundary. They are Fix now in debt terms, even though this critic's findings are advisory 🟢 by rubric rule. The orchestrator should confirm that the security-reviewer's findings on FC-1/3/5 carry the blocking weight.
- **Silent guesses:** none load-bearing. The TD5 frequency, meaning how often escaped pipes occur in real hypothesis logs, is flagged as unmeasured.
