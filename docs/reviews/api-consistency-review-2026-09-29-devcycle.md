Commit: 89a3d3b

# API Consistency Review — feat/dev-cycle

**Scope:** `git diff main...HEAD` (scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, docs/roadmap.md, test/dev-cycle.bats, global-instructions/CLAUDE.md row 12, docs/decisions/log.md row 67, README, guides/skill-creation.md)
**Date:** 2026-09-29
**Based on:** critic brief C (shared context); probes run in a throwaway repo under the session scratchpad, all under `timeout`, none left running.

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

## Baseline Conventions

- **Installed helper scripts** (`scripts/questions.sh`, `scripts/lite-review.py`): act on the git toplevel of `$PWD`; installed as a whole `scripts/` directory into `~/.claude/scripts/` (devcontainer-config/install.sh:128, link-claude-home.sh:47). Instruction prose names them by the **installed path first**, with the repo copy as a parenthetical: "`~/.claude/scripts/questions.sh next-id` (in claude-workflows, `scripts/questions.sh` is the same file)" (global-instructions/CLAUDE.md, Running questions document; workflows/pr-prep.md step 3c for lite-review).
- **Failure reporting in questions.sh**: a missing doc is an error with exit 1, pointing at `init`, never a quiet empty answer. Its header: "reporting 'Q-001' or '0 archived' there would be a success claim about files that were never read."
- **Repo-local report scripts** (`skill-usage-report.sh`, `flag-removal-candidates.sh`): flags only in `--name=VALUE` form, `Unknown option: X` to stderr with exit 1, plain text by default with `--markdown` opt-in; flag-removal-candidates.sh documents its exit codes in the header. No `-h`.
- **Skill descriptions**: ≤250 characters, a precedence clause "Not for X (Y)", then a `Triggers:` list (log row 66; skills/pr-prep, skills/research-plan-implement).
- **docs/working/ subdirectories** for per-kind records: `docs/working/rounds/`, `docs/working/reports/`. `scripts/archive-working-docs.sh` only moves top-level files (`[ -f "$f" ] || continue` over `docs/working/*`), so subdirectories survive archiving.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `dev-cycle.sh` | script | `questions.sh`, `skill-usage-report.sh`, `flag-removal-candidates.sh` | `scripts/*.sh` | Consistent — kebab-case noun, `.sh` |
| `dev-cycle` | skill | `pr-prep`, `tech-debt-triage`, `self-eval` | `skills/*/SKILL.md` | Consistent — kebab-case; same stem as the script |
| `--since` | CLI flag | `--project=NAME`, `--round=N`, `--with-usage` | `scripts/skill-usage-report.sh:10`, `scripts/flag-removal-candidates.sh:14-16` | Consistent name; accepts both `--since V` and `--since=V` (superset, see F7) |
| `--sample` | CLI flag | same as above | same | Consistent name; same superset |
| `-h`/`--help` | CLI flag | none in sibling report scripts; questions.sh prints usage on bad command (exit 1) | `scripts/questions.sh:453-455` | New in this family — harmless, exit 0 |
| `docs/working/cycles/cycle-YYYY-MM-DD.md` | path | `docs/working/rounds/`, `docs/working/reports/`, `docs/working/archive/<prefix>-<name>` | `docs/working/`, `scripts/archive-working-docs.sh` | Consistent placement; one-per-day naming (F8) |
| `docs/roadmap.md` | path | `docs/evaluation-rubric.md`, `docs/dd-portable.md` | `docs/*.md` | Consistent — top-level docs noun file; first roadmap (no analog) |
| Digest sections `## 1. Activity` … `## 5. Roadmap` | output format | questions.sh index tables; skill-usage-report `--markdown` | `scripts/skill-usage-report.sh` | New format; markdown-only (no plain-text default) — acceptable for an agent-read digest |
| Decision-tree row 12 → "`dev-cycle` skill" | routing entry | rows 1–11 name `<workflow>.md` | `global-instructions/CLAUDE.md:18-31` | New shape (first row naming a skill); fine, but trigger lists diverge (F5) |

## Findings

#### F1. A questions.sh failure is reported as "None open."

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:92-106`
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the agent running step 3 of the skill, which acts on the digest as fact

Evidence (code):
```
if [[ -f docs/working/questions.md && -f "$QS" ]]; then
  ...
  open_q="$(bash "$QS" open 2>/dev/null || true)"
  ...
    echo "None open."
```
Evidence (probe, repo with `questions.md` holding an OPEN `trigger` entry and no `questions-archive.md`): the digest printed `None open.` and `Open by route: ` (empty), exit 0; `questions.sh open` in the same repo printed `✗ missing: …/questions-archive.md` and exited 1.

The guard checks only the live file, but questions.sh requires both files for every command except `init`, and the digest discards its stderr and exit status. The result is exactly the success claim questions.sh's header says it refuses to make. A watched trigger is then never checked in step 3.

**Recommendation:** Capture the exit status of `questions.sh open`; on failure print its stderr (or "questions.sh open failed: …") in section 3 instead of "None open." Guard on both files, or let questions.sh's own error through.

#### F2. Repos whose default branch is not `main` get a half-printed digest and exit 128

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:40-42`, `:56`, `:61-62`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** a user or agent running the installed copy in another project

Evidence (code):
```
MAIN="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
[[ -n "$MAIN" ]] || MAIN=main
```
Evidence (probe, local-only repo on `master`): stdout had the title and `Window: since 2026-09-15, on \`main\` at .`, then `fatal: ambiguous argument 'main': unknown revision`; exit=128.

The header promises "the installed copy at ~/.claude/scripts/dev-cycle.sh serves any project". Every other failure in the script is a one-line message with exit 1; this one is a raw git fatal after partial output. questions.sh, the precedent it cites, has no branch dependency.

**Recommendation:** Fall back through `main`, `master`, then the current branch (`git rev-parse --abbrev-ref HEAD`), and check with `git rev-parse --verify --quiet "$MAIN"` before printing anything; otherwise exit 1 with a clear message. Optionally add `--branch`.

#### F3. `--since YYYY-MM-DD` is not the start of that day

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:12-13` (doc), `:61-62` (use)
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** High
**Legibility-target:** the agent reading "Window: since D" and the next cycle's window

Evidence (doc): `--since   start of the cycle window. Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md`
Evidence (probe): a commit dated today 00:30, `--since 2026-09-29` → `0 merge(s), 0 commit(s)`. Git reads a bare date as that date at the current time of day.

So the window's real start depends on what time the cycle is run: merges made on the previous cycle's day are dropped or included depending on the clock, which the documented contract does not say.

**Recommendation:** Pass `--since="$SINCE 00:00:00"` to both `git log` and `git rev-list` and document the window as inclusive of that whole day (a small overlap with the previous cycle is the safe direction).

#### F4. The skill names the repo copy first and `questions.sh` bare — the inverse of the installed-path convention

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:26-30`, `:37`, `:50`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** an agent running the skill in a project other than claude-workflows

Precedent: installed path first, repo copy parenthetical, used in `global-instructions/CLAUDE.md` (Running questions document: "`~/.claude/scripts/questions.sh next-id` (in claude-workflows, `scripts/questions.sh` is the same file)") and `workflows/pr-prep.md` step 3c (`~/.claude/scripts/lite-review.py`); log row 66 requires router bodies to name the installed copy and forbid a same-named file from another project.

Evidence: "Run `scripts/dev-cycle.sh` (installed copy: `~/.claude/scripts/dev-cycle.sh`) from the repo root" and "run `questions.sh init` first", "`questions.sh archive` then `questions.sh index`".

The skill fires in every project (it is installed globally and in decision-tree row 12). In another repo, `scripts/dev-cycle.sh` either does not exist or is that project's own script, and bare `questions.sh` is not on PATH.

**Recommendation:** Write `~/.claude/scripts/dev-cycle.sh` (in claude-workflows, `scripts/dev-cycle.sh` is the same file) and `~/.claude/scripts/questions.sh …` throughout, matching the global instructions.

#### F5. Trigger phrases diverge between the skill description and decision-tree row 12

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:3-4`; `global-instructions/CLAUDE.md:32`
**Move:** 3 (consumer contract — two routing surfaces for one entry point)
**Confidence:** Medium
**Legibility-target:** the skill selector and the agent reading the decision tree

Evidence: skill — `Triggers: "run the dev cycle", "maintenance pass", "what next", "update the roadmap".` Row 12 — `"dev cycle", "what should we work on next", "update the roadmap", "check the revisit triggers", "repo health pass"`.

"check the revisit triggers" and "repo health pass" route to the skill only through the tree; "maintenance pass" only through the description. "what next" is also broad enough to fire at the end of ordinary tasks. Description length is 242 characters, so there is room for one more phrase.

**Recommendation:** Align the two lists (at least include "revisit triggers" in the description) and replace "what next" with "what should we work on next".

#### F6. "create it from its own template" — no roadmap template exists

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:79`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** an agent running step 6 in a project with no `docs/roadmap.md`

Evidence: "Update `docs/roadmap.md` (create it from its own template if missing)". `templates/` holds only `gitattributes-snippet.txt`; claude-workflows' `docs/roadmap.md` is not installed to other projects. The digest also says "No docs/roadmap.md yet — create it this cycle."

The four bullets that follow (Now / Next / Ideas / Done) are sufficient to create one, so the impact is small, but the phrase points at nothing.

**Recommendation:** Replace with "create it with the four sections below" (or ship `templates/roadmap.md` and name its installed path).

#### F7. Flag syntax is a superset of the sibling scripts'

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:24-32`
**Move:** 2
**Confidence:** High
**Legibility-target:** maintainers of the scripts/ CLI family

Precedent: `--name=VALUE` only, in `scripts/skill-usage-report.sh:27-28` and `scripts/flag-removal-candidates.sh:38-41`.

Evidence: `--since) SINCE="${2:?--since needs a date}"; shift 2 ;;` and `--since=*) …`. Both forms work, so no consumer breaks; `--since` with no value prints `line 26: 2: --since needs a date` (bash's `:?` format, exit 1) rather than the `Unknown option`-style message.

**Recommendation:** None required. If touched, make the missing-value message match `echo "... " >&2; exit 1` style.

#### F8. Cycle records are one per date

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:45-51`; `skills/dev-cycle/SKILL.md:89`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** whoever runs a second cycle on the same day

Precedent: per-kind subdirectories `docs/working/rounds/`, `docs/working/reports/` used in `docs/working/`.

Evidence: glob `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md`; skill: "Write `docs/working/cycles/cycle-YYYY-MM-DD.md`". A second same-day cycle overwrites the first; a suffixed name (`cycle-2026-09-29-2.md`) is silently ignored by the window lookup. Placement is good: archive-working-docs.sh skips subdirectories, so the window source is not archived away.

**Recommendation:** State in step 7 that a same-day rerun appends to the existing record.

#### F9. Exit codes and counts are undocumented

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:10-18`, `:61-64`
**Move:** 1/3
**Confidence:** Medium
**Legibility-target:** maintainers and test authors

Evidence: flag-removal-candidates.sh documents `Exit codes: 0 … 1 …`; dev-cycle.sh's header does not (actual: 0, 1 for bad args / not a repo, 128 on F2). Section 1 prints `N merge(s), M commit(s)` where merges are `--first-parent` and commits are all ancestors — easy to misread as the same scope.

**Recommendation:** Add an Exit codes block to the header; label the commit count "(all ancestors)" or use `--first-parent` for both.

## What Looks Good

- Script and skill share one stem and follow the kebab-case naming of `scripts/` and `skills/`.
- The script acts on `$PWD`'s toplevel and finds questions.sh via its own directory then `~/.claude/scripts`, matching questions.sh's installed-helper model; it is read-only as documented.
- Unknown options: `Unknown option: X` to stderr, exit 1 — same as siblings. Malformed `--since`/`--sample` rejected with exit 1, and tested.
- Watched-question parsing splits on questions.sh's own column format (2+ spaces), so `you: judgment` and slugs containing "trigger" are handled; the test pins this.
- Skill description is 242 characters with a precedence clause (`Not for landing one change (pr-prep)`) and a Triggers list, per log row 66.
- Decision-log row 67 keeps the table's five-column shape and carries concrete revisit triggers.
- Cycle records sit in a `docs/working/` subdirectory, which archive-working-docs.sh leaves in place.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | questions.sh failure reported as "None open." | Inconsistent | `scripts/dev-cycle.sh:92-106` | High |
| F2 | Non-`main` default branch → partial output, exit 128 | Inconsistent | `scripts/dev-cycle.sh:40-42` | High |
| F3 | `--since` date uses current time of day | Inconsistent | `scripts/dev-cycle.sh:12-13, 61-62` | High |
| F4 | Repo path first, bare `questions.sh` — inverse of installed-path convention | Inconsistent | `skills/dev-cycle/SKILL.md:26-30, 37, 50` | High |
| F5 | Trigger lists diverge (skill vs row 12); "what next" broad | Minor | `skills/dev-cycle/SKILL.md:3-4`; `global-instructions/CLAUDE.md:32` | Medium |
| F6 | Nonexistent roadmap template referenced | Minor | `skills/dev-cycle/SKILL.md:79` | High |
| F7 | Flag syntax superset of siblings | Informational | `scripts/dev-cycle.sh:24-32` | High |
| F8 | One cycle record per date | Informational | `scripts/dev-cycle.sh:45-51` | Medium |
| F9 | Exit codes / count scope undocumented | Informational | `scripts/dev-cycle.sh:10-18, 61-64` | Medium |

## Overall Assessment

The new surfaces mostly match the repo's conventions: naming, unknown-option handling, the installed-helper model and the skill-description format all follow precedent. The consistency problems are in contracts with other components, not in names. The digest turns a questions.sh error into "None open." (F1) and a missing `main` into a raw git fatal (F2), and its `--since` window does not mean what the header says (F3). The skill reverses the global convention of naming the installed helper path first (F4), which matters because the skill runs in every project. All four are small fixes in place and do not need a redesign. The consumer impact is on the agent acting on the digest, which the skill tells to treat the digest as the cycle's input.

## Goal-Alignment Note

- **Answered:** API-consistency review of the branch's public surfaces (script CLI flags, exit codes and output against questions.sh / skill-usage-report.sh / flag-removal-candidates.sh; skill name and description; cycle-record path; roadmap structure; decision-tree row 12). F1–F3 were confirmed by probes in a throwaway repo.
- **Out of scope:** security of printing decision text verbatim, whether the skill's prose steps actually execute (Q-074), per-session context cost — these belong to the security, architecture and performance critics. No full suite or health-check was run.
- **Escalate:** none. F4 overlaps with log row 66's installed-path rule; the author may want the router test's installed-path check extended to this skill.
