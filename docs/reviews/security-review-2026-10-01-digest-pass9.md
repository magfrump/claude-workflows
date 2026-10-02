Commit: d503a43 (A) / 1ae9b21 (B)

# Security Review — dev-cycle pass 9 (pass-8 fix round)

**Scope:** A: `git diff ab8ec06..d503a43 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest; HEAD 56dfa86 has the same script and tests). B: `git diff cfe4b51..1ae9b21 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/questions.md` (wt-devcycle; HEAD 70df147 has the same content). Partial scope: everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass8.md` (Stage 1), rubric "Pass 8" rows R1, A1–A4, C1.

## Trust Boundary Map

```
B1:       [committed repo files, any of which may be a symlink] → [inrepo: -f && realpath -e == ROOT_REAL/<path>] → [digest reads → scrub → stdout]
B2 (moved): [brief Policy: line (landed) + default branch's docs/dev-cycle.md at merge time] → [exact-line rule, stricter of two] → [loop's authority to merge into the default branch]
B3 (new): [build-loop branch changes] → [brief Paths allowlist + fixed exclusions (+ self-merge exclusions) + pr-prep] → [default branch → files later runs execute or follow]
B4 (new): [repo paths the cycle agent reads/writes] → [per-component `test -L`, skip + `## Skipped paths`] → [filesystem]
B5:       [repo paths a build loop edits] → [none: the symlink rule binds "the cycle", not the loop] → [filesystem, possibly outside the allowlist or the checkout]
```

| Label | Source | Mutability | Trust per sink class |
|---|---|---|---|
| S1 | Working-tree files and their file types (symlink or not): decision records, log, roadmap, idea log, questions, cycle-record names | runtime-mutable (any merged commit, including a self-merged loop's) | UNTRUSTED for path-resolution/read sinks and for terminal output; trusted for nothing |
| S2 | `Build-loop policy:` line in `docs/dev-cycle.md` on the default branch | runtime-mutable | UNTRUSTED toward the merge-authority sink; only an exact line counts, and only to lower authority below a brief's value |
| S3 | Brief file (`Policy:`, `Paths`, stop conditions) read from the landed commit | runtime-mutable, but pinned to a commit | Trusted as the cycle agent's instruction to the loop; its `Policy:` is an upper bound only |
| S4 | `DEV_CYCLE_TODAY`, `DEV_CYCLE_SCRUBBED`, `QUESTIONS_*`, `$HOME` | deploy-time (operator environment) | trusted (not repo-reachable) |
| S5 | A build loop's own edits and branch content | runtime-mutable, produced by an autonomous agent reading S1 | UNTRUSTED toward the default branch and toward anything later runs execute |

What enters from outside is repo content (S1) and loop output (S5). The digest diff narrows B1 from "realpath under the root" to "realpath equals root/path", which rejects every in-repo symlink as well. The skill diff replaces a stop-condition denylist with a per-brief allowlist (B3) and a stricter-of-two merge rule (B2), and states a never-through-a-symlink rule for the cycle agent (B4) but not for the loops (B5).

## Findings

#### F1. Self-merge exclusions still a denylist; misses executed tests, followed guides/patterns, the egress allowlist, GEMINI.md

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:242-247` (1ae9b21)
**Boundary:** B3
**Move:** 5 (invert the access-control model), 11
**Confidence:** Medium-High
**Legibility-target:** the cycle agent writing a brief's `Paths` under `Policy: self-merge`
**Evidence:**
> "With `Policy: self-merge` it also never includes what later runs follow unreviewed: instruction files (`CLAUDE.md`, `AGENTS.md`) and anything under `skills/`, `workflows/` or `scripts/`; such work gets `Policy: review`;"

The rule's stated property is "what later runs follow unreviewed". The enumeration that implements it leaves out paths in this repo that later runs execute or follow (checked with `git ls-tree 1ae9b21`):
- `test/` (the `.bats` files). `scripts/health-check.sh` runs the BATS suite (header item 5, "run-tests.sh --fast, then --slow"), and every cycle's step 1 and every pr-prep run it. A self-merged test file is shell code the next session executes.
- `guides/` and `patterns/`. 34 `skills/*/SKILL.md` files link them, for example "On bad output, see guides/skill-recovery.md", and `global-instructions/CLAUDE.md` sends readers to `guides/…`. Text there is followed like a skill.
- `devcontainer-config/` (`init-firewall.sh`, `egress/*.txt`, `install.sh`, `Dockerfile`). The egress lists are the sandbox's network allowlist. The brief's fixed exclusion names "enforcement" files without listing any, so whether these count is left to the agent's judgment.
- `GEMINI.md` at the root, an instruction file of the same kind as `AGENTS.md`. The parenthetical names only `CLAUDE.md` and `AGENTS.md`.
- `templates/` and `hooks/`. Hooks are covered by "hook files", templates are not.

Mechanism: the user answers Q-103 with [2], the cycle hands off a "add tests for X" or "tighten guide Y" item with `Paths: test/…` or `guides/…`, and the loop self-merges. A wrong or injected change then reaches the next session's execution (tests) or instructions (guides) with no human review. Pass 8's A2 was this exact pattern. The allowlist fixed the review-policy half. The self-merge half is still a hand-enumerated denylist.
**Recommendation:** Invert the self-merge rule into an allowlist. Under `self-merge`, `Paths` may name only documentation outside the instruction surface (for example `docs/` other than `docs/dev-cycle.md`, `docs/working/handoffs/` and the questions files); anything else gets `Policy: review`. Failing that, add `test/`, `guides/`, `patterns/`, `templates/`, `devcontainer-config/` and every root `*.md` instruction file (`GEMINI.md`), and name what "enforcement" covers.

#### F2. Build loops are not bound by the symlink rule, so an allowlisted path can write elsewhere

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:62-67` and `:242-243` (1ae9b21)
**Boundary:** B5, B3
**Move:** 11, 4
**Confidence:** Low-Medium
**Legibility-target:** the cycle agent writing briefs, and the build loop reading one
**Evidence:**
> "**Never through a symlink.** The cycle reads and writes repo files (idea sources and their glob matches, the idea log, briefs, the record, the roadmap, questions) only by plain paths:" … "**Paths**: the files and directories the work may change. Changing anything else is a stop condition."

The symlink rule binds "the cycle", and the brief's required contents (lines 239-248) do not carry it to the loop. A loop checks its own edits against `Paths` by name. If an allowlisted path (or a component of one, such as a listed directory) is a committed symlink, an edit by name writes the link's target. Pointing into `scripts/` or `.claude/` would show in the diff, where pr-prep might catch it. Pointing outside the checkout (for example `../../../home/node/.claude/...`) would not show in `git diff` at all. A symlink can enter by any merged change, and a self-merged loop can create one at an allowlisted path, because creating a link at a listed path is not a "change to anything else". This is the write-side twin of pass 8's A1, which was fixed for the digest and the cycle but not for the loops.
**Recommendation:** Add the per-component `test -L` rule to the brief's required contents ("never write through a symlink; adding or changing a symlink is a stop condition"). Have the loop check `git diff --name-only <base>` against `Paths` before merging or filing its entry.

#### F3. The questions files are excluded from `Paths`, yet every loop must write one

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:243-245` vs `:296-301` (1ae9b21)
**Boundary:** B3
**Move:** 5
**Confidence:** High (reading)
**Legibility-target:** the build loop under `Policy: review` in this repo (no PRs)
**Evidence:**
> "The list never includes hook, enforcement or harness-settings files, the roadmap, the questions files, `docs/dev-cycle.md` or `docs/working/handoffs/`; work that needs one of them is not handed to a loop." … "otherwise it files one `you: judgment` entry, "merge <branch>?", naming the roadmap item." … "Either way, a build that hits a stop condition files a `you: judgment` entry"

In this repo every review-policy loop has to write `docs/working/questions.md`. "Changing anything else is a stop condition", and the stop condition's own remedy is to file another questions entry. Read literally, the procedure cannot finish. Read loosely ("bookkeeping doesn't count"), the allowlist becomes advisory, which weakens F1 and F2's guard. It is also unstated whether the entry lands on the loop's branch (where the user's next digest does not see it until a merge) or directly on the default branch (an unreviewed write to main). This is a security finding only through that dilution. No property is violated by itself, so it is rated Low.
**Recommendation:** State the exception explicitly: the loop may append exactly one entry to `docs/working/questions.md`, and nothing else in that file. Say where that entry lands.

#### F4. In-flight "running" overlaps "stalled", so a dead loop can hold a slot indefinitely

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:215-220` (1ae9b21)
**Boundary:** B3 (availability of the 3-slot cap)
**Move:** 8
**Confidence:** Medium
**Legibility-target:** the cycle agent classifying In-flight items
**Evidence:**
> "running, or finished and waiting on the user's merge decision … → stays, however long;" … "ended any other way (merge declined, a stop condition hit, or still building with no commit on its branch for 7 days) → Ideas"

A loop "still building with no commit for 7 days" is also "running", and the first bullet is matched first. If the agent reads it that way, a stalled loop stays forever and occupies one of the 3 slots, a self-inflicted denial of the handoff queue. The outcomes are otherwise exhaustive ("any other way" is a catch-all), and they cannot loop: a returned item re-enters Now only by the user (lines 222-224), which closes pass 8's A4 re-queue cycle. Scope note: this is not a security property, so it is routed to the api/performance critics.
**Recommendation:** Write "running (a commit on its branch within 7 days)".

#### F5. `docs/dev-cycle.md` states the policy rule more loosely than the skill

**Severity:** Informational
**Location:** `docs/dev-cycle.md:12-14` (1ae9b21)
**Boundary:** B2
**Move:** 2
**Confidence:** High (reading)
**Legibility-target:** the user editing the setting
**Evidence:**
> "The skill counts the setting as made only when one line reads exactly `Build-loop policy: self-merge` or `Build-loop policy: review`;"

The skill also requires "exactly one line", "outside code blocks" and "a trailing CR is ignored". The user-facing doc's "one line" omits two of these. Every omitted condition fails toward `review`, so there is no escalation. Q-103's "If the answer differs" instruction (replace the line, drop the interim sentence) matches the skill.
**Recommendation:** Optional: add "exactly one, outside code blocks".

## Untested bypass candidates

- **Case-insensitive filesystem (macOS APFS).** The literal `docs/roadmap.md` could match `Docs/Roadmap.md`. GNU `realpath` keeps the given case, so equality would hold and a plain (non-link) file is read, which is harmless. Not tested: there is no case-insensitive FS on this host.
- **Repo root at `/`.** `ROOT_REAL=/` makes the comparand `//docs/…`, while `realpath` returns `/docs/…`, so every file is rejected (fails closed, availability only). Traced by reading, not executed.
- **Swap between `inrepo` and the read (TOCTOU).** This needs a concurrent local writer, which is host control and outside the reachable-environment bar. Not tested.
- **Policy line hidden in an HTML comment (`<!-- … -->`).** Under the rule as written it counts as "set" while invisible in rendered markdown. Not executed, since the rule is prose. It only grants what the file's writer already has, because `docs/dev-cycle.md` is excluded from every `Paths` list.

## Tested bypass candidates (B1: `inrepo`)

Probe: `sec9/probe.sh` (throwaway repo under `mktemp -d`, removed on exit, 60 s timeout). It ran the digest from `$T/link/repo/sub/deep`, where `link → real`.

| Input | Result |
|---|---|
| Relative symlink `docs/decisions/002-b.md → ../../real2/002-b.md` (in-repo target) | skipped (`SECRET_DIRLINK` absent) |
| Sibling symlink `004-c.md → x.txt` (same directory) | skipped |
| Self-loop `005-loop.md → 005-loop.md` | skipped (`realpath -e` fails), status 0 |
| Cycle record `cycle-2026-01-05.md → /etc/hostname` (newer than the plain 01-02 record) | ignored: window "since 2026-01-02" |
| `docs/` itself a symlink to `docs_real/` | all four inputs skipped ("No revisit triggers", "No docs/roadmap.md", "No …idea-log.md", "No …questions.md"), status 0 |
| Plain files (record 001, `log.md`, roadmap, idea log, cycle record) with the repo reached through a symlinked parent, run from a subdirectory | all read (`PLAIN1`, `PLAINLOG`, `PLAINROAD`, "Last brainstorm: 2026-01-01", "Roadmap Next: 1") |
| Hard link to a file outside the repo | read (`HARDLINK6`). Cleared: git cannot commit a hard link, so creating one needs host access |

`git rev-parse --show-toplevel` from the symlinked path returned the physical path. `cd "$ROOT"; pwd -P` would normalise it either way. `bats test/scripts/dev-cycle.bats`: 20/20 ok at 56dfa86 (script and tests identical to d503a43). Test 6's comment ("An in-repo symlink (here into .git) is skipped too") matches its fixture and assertion. Test 20's change (`## Now (current)`, `## Next`) exercises the suffix and plain heading forms its comment names.

## Endorsement Claims

- **Claim:** `inrepo` rejects a path with a symlink at any component below the repo root, and accepts plain paths when the root is reached through a symlinked ancestor or the script runs from a subdirectory.
  **Location:** `scripts/dev-cycle.sh:86-92` (d503a43)
  **Evidence:** executed
  **Verified:** the probe table above (7 inputs) and bats 20/20.
  **Not verified:** a case-insensitive filesystem; a `ROOT_REAL` of `/`.
  **route: code-fact-check**
- **Claim:** every repo-file read in the digest is preceded by `inrepo` on the same literal path: cycle glob L118-119, decision records L154-155, log L164, questions L181 (questions.sh `open` parses only `$LIVE` = the same path and checks the archive's existence only), roadmap L214 and L262, idea log L271.
  **Location:** `scripts/dev-cycle.sh:117-286`
  **Evidence:** read-static
  **Verified:** read the whole script body and `scripts/questions.sh` `cmd_open`/`require_files`.
  **Not verified:** questions.sh's `parse_entries` internals (whether it opens any further file).
  **route: code-fact-check**
- **Claim:** the policy rule fails toward `review` for each malformed case enumerated (no file, no line, both values, duplicate lines via "exactly one", extra text, leading spaces, blockquote, NBSP or zero-width characters, a line inside a fence). A loop cannot raise its authority: the effective value is the minimum of the landed brief and the default branch's file, and `docs/dev-cycle.md` and `docs/working/handoffs/` are excluded from every `Paths` list.
  **Location:** `skills/dev-cycle/SKILL.md:54-59, 239, 290-293` (1ae9b21)
  **Evidence:** read-static
  **Verified:** read the rule, the brief format and 6b. The current file's line 7 (`review (interim; Q-103)`) evaluates to unset → `review`, and Q-103 is an open `you: judgment` entry, so no duplicate ask is filed.
  **Not verified:** how an agent detects "outside code blocks" for an unclosed fence or `~~~` fences; an HTML-comment-hidden line (listed above).
  **route: code-fact-check**
- **Claim:** the per-component `test -L` procedure can be run by an agent with ordinary tools (a bash loop over path prefixes; directories for a not-yet-created file), and it names where skipped paths are recorded (`## Skipped paths`, present in the record template at line 269).
  **Location:** `skills/dev-cycle/SKILL.md:62-67, 269`
  **Evidence:** read-static
  **Verified:** the wording and the template.
  **Not verified:** whether glob tools used for idea-source globs list symlinked entries (the per-path check covers them if they do).
- **Claim:** under `Policy: review`, the fixed exclusions do not block normal work in this repo: `skills/`, `workflows/`, `scripts/`, `test/` and `docs/` stay listable.
  **Location:** `skills/dev-cycle/SKILL.md:242-245`
  **Evidence:** read-static
  **Verified:** the exclusion list against the `git ls-tree 1ae9b21` top level.
  **Not verified:** the questions-file conflict (F3) is the one exception.

## Primitive sweep

Primitive: file read via a repo-controlled path (path resolution / symlink following), scope `scripts/dev-cycle.sh` @ d503a43

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:118-121` cycle-record glob (name only) | S1 | `inrepo` | cleared: probe (symlinked newer record ignored) |
| `dev-cycle.sh:154-162` `grep`/`trig < "$f"` decision records | S1 | `inrepo` | cleared: probe |
| `dev-cycle.sh:164-174` `grep … docs/decisions/log.md` | S1 | `inrepo` | cleared: probe (plain read; dir-link skip) |
| `dev-cycle.sh:181-183` `bash "$QS" open` reads `questions.md` | S1 | `inrepo` on the same path | cleared: questions.sh reads `$PROJECT_ROOT/docs/working/questions.md`, the same file; archive is existence-checked only |
| `dev-cycle.sh:214-218` roadmap section 5 | S1 | `inrepo` | cleared: probe |
| `dev-cycle.sh:262-264` roadmap section 7 | S1 | `inrepo` | cleared: probe |
| `dev-cycle.sh:271-277` idea log | S1 | `inrepo` | cleared: probe |
| `dev-cycle.sh:79` `sed -n '2,21p' "$0"` | S4 | n/a | cleared: the script's own path |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:183` `bash "$QS"` | S4 (`SCRIPT_DIR` or `$HOME`) | not repo-derived | cleared: the target repo cannot choose `$QS` |
| `dev-cycle.sh:67` re-exec `bash "${BASH_SOURCE[0]}"` | S4 | n/a | cleared |

Primitive: write through a repo path (skill procedure, B4/B5)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| Cycle writes: idea log, record, roadmap, briefs, questions (`SKILL.md:62-72`) | S1 | per-component `test -L` | cleared (read-static) |
| Build-loop edits within `Paths` (`SKILL.md:242`) | S1/S5 | none | F2 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Self-merge exclusions miss `test/`, `guides/`, `patterns/`, `devcontainer-config/` egress, `GEMINI.md` | Medium | B3 | `skills/dev-cycle/SKILL.md:242-247` | Medium-High |
| 2 | Loops not bound by the symlink rule; an allowlisted path can write elsewhere | Medium | B5, B3 | `skills/dev-cycle/SKILL.md:62-67, 242-243` | Low-Medium |
| 3 | Questions files excluded from `Paths`, yet every loop must file an entry | Low | B3 | `skills/dev-cycle/SKILL.md:243-245, 296-301` | High |
| 4 | "running" overlaps "stalled": a dead loop can hold a slot | Informational | B3 | `skills/dev-cycle/SKILL.md:215-220` | Medium |
| 5 | `docs/dev-cycle.md` states the policy rule more loosely (fails toward review) | Informational | B2 | `docs/dev-cycle.md:12-14` | High |

## Overall Assessment

The digest half (A) holds. `inrepo` now rejects a symlink at any component, accepts every plain input in the probes (symlinked root ancestor, subdirectory start), and fails closed on loops and odd roots. No findings within the code paths read and executed. The skill half (B) closes pass 8's A1, A3 and A4 as intended. The policy rule and stricter-of-two rule fail toward `review` in every case checked, and the In-flight outcomes cannot re-queue themselves. Two Medium issues remain on the build-loop boundary, both fixable in place in the prose. F1: the self-merge exclusion is still an enumerated denylist and misses executed tests, followed guides and patterns, and the egress allowlist. F2: the never-through-a-symlink rule binds the cycle but not the loops it hands work to. Both bite only after Q-103 is answered `self-merge`, or a symlink is committed, so the current interim `review` setting contains them. The single most important fix is F1: make the self-merge `Paths` rule an allowlist. Endorsement claims are pending execution verification for the read-static entries.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass9.md`. It follows the security-reviewer structure (header, trust boundary map with source table, findings with Severity, Location, Evidence, Confidence and Legibility-target, untested bypass candidates, endorsements routed to code-fact-check, primitive sweep, summary, assessment) and covers both claim lists in the brief. Toward the user goal of reaching a clean pass and merging: F1 and F2 are Medium and would keep the loop open under a strict "no known issues" bar. F3–F5 are cheap wording fixes.
