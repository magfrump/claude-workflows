Commit: 654c0ed

# Architecture Review: answers-2026-09-20

**Scope:** `git -C /workspace diff e8d5fa1..answers-2026-09-20` (32 commits, 50 files)
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report.md` (merged Stage-1 report; Claims 1, 3, 5, 10, 11, 13, 16 and 18 are used below)

**Scope check.** The diff triggers all four categories:

- **Module structure:** `failure-analysis.sh` and its test move to `archive/failure-analysis/`, and the `claude-api` supplement moves to `archive/docs/`.
- **Public API:** `~/.claude/scripts/` becomes an installed surface. `questions.sh` changes how it resolves paths and gains an `init` command.
- **Data models:** the hypothesis log gains a `Run` column, and the new `si-run-id.txt` file is shared across scripts.
- **Cross-cutting:** the trusted-writes guard hook gets a new tier model, and review-loop rules change owners.

**Trust-boundary cross-reference.** The most recent security review is `docs/reviews/security-review-egress-zone-entries-2026-09-19.md` (Commit: `7c970bf`). It covers the egress allowlist only, and none of its boundaries coincide with this diff. The boundary this diff does touch is labelled `B2` in `docs/reviews/security-review-2026-09-12.md` (Commit: `0661353`): "[Edit/Write/MultiEdit or Bash write targeting a policy file] → [guard-trusted-writes.py classify_path() / HARD_FRAG + permissions.deny] → [on-disk trusted-policy file]". That review predates this diff, so the boundary may be stale. It is cited below for correlation only.

## Dependency Map

- **Trust hook cluster.**
  - `hooks/guard-trusted-writes.py` classifies a write target as HARD, SOFT or none. For the file tools, HARD means "defer, and let `permissions.deny` block it".
  - The deny rules live in `hooks/wiring.json` as `{{CLAUDE_DIR}}` globs. `devcontainer-config/link-claude-home.sh` substitutes that placeholder with `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` when the container starts.
  - The same linker also creates the symlinks that make up the installed layout, such as `~/.claude/hooks → /opt/claude-workflows/hooks`.
  - `test/link-claude-home-wiring.bats:238-254` hard-codes the deny list a third time.
  - So the hook's HARD set and the deny set are defined in three places, in three formats (Python path logic, Claude permission globs, a bats list). Nothing derives one from another. The hook depends on the linker's layout and substitution, and neither imports the other.
- **Installed scripts.**
  - `link-claude-home.sh` and the README now link the whole `scripts/` directory into `~/.claude/scripts/`. The global instructions and workflows (`global-instructions/CLAUDE.md`, `workflows/pr-prep.md`, `workflows/review-fix-loop.md`) call `questions.sh` and `lite-review.py` there by their installed path.
  - `questions.sh` now resolves its data from the caller's `$PWD`. Its one scripted caller inside the repo, `health-check.sh`, pins it back with `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE`.
- **SI run-id contract.**
  - `self-improvement.sh` writes `SI_RUN_ID` to `docs/working/si-run-id.txt` and passes it to `si-functions.sh:append_approved_hypotheses`, which writes the hypothesis-log `Run` column.
  - `archive-working-docs.sh` reads `si-run-id.txt` as its default archive prefix.
  - `si-morning-summary.sh` reads the `Run` column by header name and rebuilds the archive's file names as `archive/${run}-<name>`.
  - The regex `^[A-Za-z0-9._-]+$` is duplicated in the writer and in the archive reader. The morning summary does not validate it.
- **Review-loop docs.**
  - `workflows/review-fix-loop.md` now declares ownership: it owns the loop's control rules, pr-prep Step 3 owns the step sequence, and code-review references own the tiers, the override-log format and `--loop-pass`.
  - `workflows/pr-prep.md` points to those owners.
  - `skills/code-review/SKILL.md` gains a narrow write path into the override log.

Dependencies flow in a sensible direction: the workflows depend on the skill references, and the SI readers depend on the SI writers. The problems are duplicated sources of truth, not inverted dependencies.

## Findings

#### 1. The HARD tier and `permissions.deny` must match exactly, but they are computed independently in three places

**Severity:** Structural
**Location:** `hooks/guard-trusted-writes.py:56-109`, `hooks/wiring.json` (`permissions.deny`), `devcontainer-config/link-claude-home.sh:36,133-138`, `test/link-claude-home-wiring.bats:238-254`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

The hook's own contract:

> "So this hook must NEVER "ask" on a HARD path — it DEFERS (lets the deny rule block the file tools)" (`guard-trusted-writes.py:15-17`)

The hook's global-dir computation:

```python
    dirs = [HOME / ".claude"]
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    if cfg:
        dirs.append(Path(os.path.expanduser(cfg)))
```

(excerpt ends `:61`; enclosing `_global_dirs()` continues to `:67`, adding each dir's `resolve()`; read)

The linker's substitution: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`.

`:98-99`: `if name in ("managed-settings.json",): return "hard"`. No deny rule names `managed-settings.json`.

**Why it matters.** This design is safe only if "the hook classifies HARD" and "a deny rule covers the path" describe the same set. That equality is maintained by hand across modules that never reference each other. The fact-check confirms the sets already differ in three ways:

- **Different `CLAUDE_CONFIG_DIR` handling (Claim 5).** The hook always keeps `~/.claude`, and it expands `~` in the variable. The linker does neither. So when `CLAUDE_CONFIG_DIR` points somewhere else, the hook still treats `~/.claude/settings*.json` and `~/.claude/hooks/**` as HARD, but no deny rule covers them, and they go ungated.
- **The installed layout is not modelled (Claim 1).** The linker makes `~/.claude/hooks` a symlink to `/opt/claude-workflows/hooks`. `resolve()` follows the symlink out of every `GLOBAL_DIRS` entry, so some spellings fall through to SOFT and get an `ask`. An `ask` overrides deny (#39344).
- **`managed-settings.json` is HARD everywhere, but no deny rule covers it.** HARD means defer, so it has no gate at all. This predates the diff, but it contradicts the new docstring's claim that HARD covers "the GLOBAL config dir only".

The Bash classifier (`HARD_FRAG`) is a fourth, text-based encoding of the same policy. It deliberately disagrees with the file-tool tier: a project `.claude/settings` path gets deny in Bash and ask for Edit/Write (Claim 4). Every future change to one tier must be mirrored by hand in up to three other places, and no gate checks that they match.

This sits on `B2` from `docs/reviews/security-review-2026-09-12.md` (Commit: `0661353`; that review predates this diff, so the boundary may be stale).

**Recommendation:**

- Make one module the owner of "which paths are HARD". Either the hook reads the deny globs from the installed `settings.json`/`wiring.json`, or both are generated from one list.
- At minimum, add a parity test: run the linker, then assert that every file-tool path `classify_path` returns `hard` for is matched by a wired deny glob, and the reverse. Run it both in the symlinked installed layout and with `CLAUDE_CONFIG_DIR` set to a non-default directory.

**Security implication:** unifying the sources moves where `B2`'s policy is decided. The HARD set should come from the file that `permissions.deny` enforces. Placing the boundary is security-reviewer's call, so defer that choice to a combined review.

#### 2. The run id is a join key between three scripts, but the file-name scheme and the uniqueness are implicit

**Severity:** Coupling
**Location:** `scripts/self-improvement.sh:451-463`, `scripts/archive-working-docs.sh:39-49,127,135`, `scripts/lib/si-morning-summary.sh:1144-1188,1334-1346`
**Move:** 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**

- Writer: `SI_RUN_ID="${SI_RUN_ID:-$(date +%F)}"`
- Archiver: `dest="$ARCHIVE_DIR/${PREFIX}-${name}"` … `mv -- "$f" "$dest"`
- Reader: `printf '%s\n' "$working_dir/archive/${run}-tasks-round-$round.json"`

**Why it matters.** The morning summary rebuilds archive file names from its own copy of `archive-working-docs.sh`'s naming rule (`${PREFIX}-${name}`), plus hard-coded live file names. The validation regex exists twice, and the reader does not validate at all.

Two assumptions are not enforced anywhere:

- **Prefix equals run id.** An explicit `PREFIX` argument breaks it.
- **The run id is unique.** It defaults to the date, so two runs on the same day share an id. `mv` without `-n` then overwrites the first run's archived files.

Readers degrade to the newest-first fallback, which checks that the task id is present, so the failure is quiet mis-attribution rather than a crash. `si-run-id.txt` is also archived along with everything else (Claim 13). After an archive pass, `_live_run_matches` returns true for any run, because "file absent" counts as a match.

The Run column itself is well designed (see What Looks Good). The coupling lives in the file-path conventions around it.

**Recommendation:**

- Put the run-id regex and the archive-name function (`archive_name <run> <basename>`) in `scripts/lib/` and source it from all three scripts.
- Either make the default id unique (e.g. `date +%F-%H%M%S`), or make `archive-working-docs.sh` refuse to overwrite with `mv -n` and a loud error.

#### 3. `~/.claude/scripts/` became a global surface without a boundary between global scripts and repo-internal ones

**Severity:** Coupling
**Location:** `devcontainer-config/link-claude-home.sh:43-50`, `README.md:20-24`, `scripts/questions.sh:51-57`, `scripts/health-check.sh:1021-1026`
**Move:** 3 (module boundary), 2 (responsibility)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**

- `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`
- `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"`
- In health-check: `# questions.sh resolves docs/working/ from the caller's $PWD (so the` / `# installed copy serves any project); pin it to this repo's files`

**Why it matters.** Two scripts are meant to be called from any project: `questions.sh` and `lite-review.py`. The whole `scripts/` directory is now exposed at that path. The directory now mixes four ways of locating the repo:

| Convention | Scripts |
|---|---|
| Relative to the script's own location (`BASH_SOURCE`/`$0`) | `health-check.sh`, `run-tests.sh`, `self-improvement.sh` |
| Git toplevel of the caller's `$PWD` | `questions.sh`, `paper-queue.sh` |
| Bare `cwd`-relative | `archive-working-docs.sh` (`WORKING_DIR="docs/working"`) |
| Explicit `--repo` argument | `lite-review.py` |

Nothing marks which scripts form the global API, so a workflow author can call `~/.claude/scripts/archive-working-docs.sh` from another project, and it will act on that project's `docs/working/`.

`questions.sh` now has two identities: a global tool (resolved by `$PWD`) and a repo gate target (pinned by environment variables). Every future in-repo scripted caller has to remember the pin. The `$PWD` fallback also has edge cases with no owner: from inside `.git/` it creates `.git/docs/working/` (Claim 10), and `init` writes through a dangling symlink (Claim 11).

**Recommendation:**

- Declare the global surface explicitly. Either link only the two global scripts (plus `lib/skill-paths.sh` for `log-usage.sh`), or move them to a `scripts/global/` directory and link that.
- Make "resolve from caller" a documented, shared helper instead of a per-script choice.

#### 4. The rule that review-loop links point to lives inside the rubric's output template, and no gate validates the cross-doc anchors

**Severity:** Minor
**Location:** `skills/code-review/references/rubric.md:49-63`, `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

- `[qualifying author note](../skills/code-review/references/rubric.md#-must-address)`
- The fact-check found this anchor does not resolve because "the heading sits in a fenced block at `skills/code-review/references/rubric.md:31-158`" (Claim 18).

**Why it matters.** Commit 6eb89cd's "one owner per review-loop rule" is a good move. But it makes the workflows depend on anchors inside the skill references. The owner of the "qualifying author note" rule is prose inside the rubric's output template, which is copied into every generated rubric. So the normative definition is mixed into an artifact skeleton, and it cannot be linked to. Nothing in `health-check.sh` checks cross-doc anchors, so the next ownership move can break these links silently.

Some duplication also remains despite the stated policy:

- pr-prep's tier table still has a "Meaning" column ("Correctness bugs, false passes, wrong behavior"), right after the sentence "The tier definitions are owned by the code-review rubric".
- pr-prep's completion checklist still restates the exit conditions.

**Recommendation:**

- Move the qualifying-author-note definition to a prose section outside the template block, e.g. under `### Unified Severity Mapping`, and link to that.
- Drop pr-prep's "Meaning" column.
- Consider adding a markdown-anchor check to health-check, since linking is now the chosen ownership mechanism.

#### 5. code-review becomes a second writer of the override log

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:158`, `skills/code-review/references/override-log.md:37-46`, `workflows/pr-prep.md:210-229`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**

- SKILL.md: "This step is **read-only with respect to the log** during the run, with one exception: the orchestrator may append an `Accepted-immutable` row"
- pr-prep, in the same diff: "the skill's job ends when it publishes the rubric, and the decision to *not fix something* is made later, right here, in the fix pass."
- pr-prep's count: "(not counting `[auto: code-review]` rows)"

**Why it matters.** 93bfbad moved override capture to pr-prep because that is where the decision is made. d659fa9 gives the skill a write path again, for one machine-written verdict. The carve-out is narrow and tagged, so it is pragmatic. But now two modules append to the log, and the completion check in a third place has to know the other writer's tag convention to count correctly. Any second automatic verdict kind would need edits in all three places.

**Recommendation:** Keep the carve-out, but state it once. The override-log reference already defines `Accepted-immutable`, so SKILL.md and pr-prep can link to that section instead of restating the rule and the counting exception.

#### 6. DD's Path C calls `scripts/questions.sh` by its repo-relative path; the global instructions call it by its installed path

**Severity:** Minor
**Location:** `workflows/divergent-design.md:340`, `global-instructions/CLAUDE.md:235,281`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

- DD: "the ID from `scripts/questions.sh next-id` (or the next unused `Q-NNN` if the project has no script)"
- Global instructions: "Get the next ID from `~/.claude/scripts/questions.sh next-id`"

**Why it matters.** DD is a globally installed workflow, and the new text was added in this diff (ebfdda8). In any project other than claude-workflows, the repo-relative path does not exist. The fallback wording then sends the agent to hand-numbering, which is exactly what Q-025 fixed. Two docs now give two invocation contracts for one tool.

**Recommendation:** Change DD to `~/.claude/scripts/questions.sh`, matching pr-prep's pattern of adding "in claude-workflows itself, `scripts/…` is the same file".

#### 7. The local-merge path is a global reinterpretation rule, not a per-step branch

**Severity:** Informational
**Location:** `workflows/pr-prep.md:22-30`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:** "**Read "PR description" as "merge commit message"** everywhere in this doc."

**Why it matters.** One substitution rule keeps the two delivery paths from forking the document, which is the right trade-off at this size. The cost is that every later edit that mentions "PR description" or "PR comment" silently takes on a second meaning. The diff already had to patch this in several places: Step 2's "GitHub-PR path only", Step 6c, Step 7, and `review-fix-loop.md:47,215`.

**Recommendation:** None needed now. If a third delivery path appears, factor delivery out into a small "delivery surface" table (description sink, comment sink, CI source) that the steps reference.

## What Looks Good

- **Clean module retirement.** `failure-analysis.sh` moves with its test and a README recording why, and the fix if it is ever revived. No live callers remain outside `archive/`. The `claude-api` supplement is archived with a stated reason ("as a flat file the harness never loaded it"), and the SI prompt's reference to it was removed in the same diff.
- **Dead contract deleted.** 56b9883 removes the SI loop's parser for DD's `### Survivors` heading, a fragile cross-module text contract that could "silently return no results", instead of maintaining it.
- **Run column design.** It is appended last, so positional readers of Round/Task ID/Hypothesis keep working. Readers find it by header name (`_locate_log_col "$hypothesis_log" "Run"`) rather than by position. Old logs are migrated in place (Claim 14 Verified), and rows without a Run cell have a defined fallback.
- **Explicit ownership declaration.** `review-fix-loop.md:7` states what it owns and what it does not, and pr-prep now links instead of restating the iteration cap, the fix-drift mechanics and `--loop-pass`. That removes three copies of rules that had already drifted.
- **Health-check gate 5 delegates to `run-tests.sh`.** Report gating now lives in one place. The recursion guard and the `HEALTH_CHECK_RUN_TESTS` test seam are explicit, documented extension points.
- **The guard's intent is right.** Scoping HARD to exactly what deny covers (Q-026) is the correct principle. Finding 1 is about how the two sets are kept equal, not about the goal.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | HARD tier and `permissions.deny` computed independently in three places; already diverged | Structural | `hooks/guard-trusted-writes.py:56-109` + `hooks/wiring.json` + `link-claude-home.sh:36` | High |
| 2 | Run-id join key: archive naming rebuilt by the reader, regex duplicated, id not unique | Coupling | `si-morning-summary.sh:1144-1188`, `archive-working-docs.sh:127` | Medium |
| 3 | `~/.claude/scripts/` exposed wholesale; four path-resolution conventions; `questions.sh` has two identities | Coupling | `link-claude-home.sh:50`, `questions.sh:55` | Medium |
| 4 | Rule linked from workflows lives inside the rubric template; anchors not validated; residual duplicates | Minor | `rubric.md:49-63`, `pr-prep.md:190` | High |
| 5 | code-review becomes a second override-log writer; the tag convention leaks into pr-prep's count | Minor | `code-review/SKILL.md:158`, `pr-prep.md:229` | Medium |
| 6 | DD calls `scripts/questions.sh` repo-relative in a globally installed workflow | Minor | `divergent-design.md:340` | High |
| 7 | Local-merge path implemented as a document-wide substitution rule | Informational | `pr-prep.md:22-30` | Medium |

## Overall Assessment

The diff mostly improves structure. It retires dead modules cleanly, deletes a fragile cross-module text contract, adds a schema column that readers look up by name, and gives review-loop rules explicit owners. The most important concern is Finding 1. The guard's defer-to-deny design makes the core trust invariant ("never ask on a path that deny covers") depend on two sets staying equal. Those sets are computed by modules that share no source: the hook's Python logic, the wiring's globs as substituted by the linker, and a hard-coded test list. The fact-check has already caught them diverging in three ways (`CLAUDE_CONFIG_DIR` handling, the symlinked installed layout, `managed-settings.json`).

This is fixable in place: give the HARD set one owner, or add a parity test run in the installed layout. It does not need a restructure. Findings 2 and 3 have the same shape at lower stakes: conventions that were implicit inside one script are now contracts between scripts, or between the repo and every project, without a shared definition. I do not disagree with the placement of the 2026-09-12 review's `B2`. Finding 1's recommendation would change where B2's policy list comes from, so that choice should go to a combined architecture/security review.

## Goal-Alignment Note

- **Answered:** I reviewed the full range for the triggers named in the brief. Module moves are clean. For the trust-hook tier model and its coupling to `permissions.deny`, `wiring.json` and the linker, see Finding 1. For `questions.sh` resolving from `$PWD` and the global scripts surface, see Findings 3 and 6. For the `SI_RUN_ID` → `si-run-id.txt` → archive → hypothesis-log Run contract, see Finding 2 plus What Looks Good. For the review-loop ownership moves, see Findings 4, 5 and What Looks Good.
- **Out of scope:** Concrete bypass spellings for the guard (Claims 1, 3, 5) belong to security-reviewer. I used them only as evidence that the two sets have diverged. Doc-only skill edits (fact-check, draft-review, performance-reviewer, DSS, self-eval) were skimmed for structure and not reviewed in depth. There was no current-run security review to cross-reference, so `B2` was taken from the stale 2026-09-12 review and labelled as such.
- **Escalate:** Finding 1's fix changes which artifact owns `B2`'s policy list. That needs a combined architecture/security decision, not an author-only fix.
