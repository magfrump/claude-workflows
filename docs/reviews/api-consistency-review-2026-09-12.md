Commit: 0661353

# API Consistency Review — prompt-audit application (`2d679ce..HEAD`)

**Scope:** `git diff -M -C 2d679ce..HEAD` — 27 files, four commits (`2d679ce`→`0661353`)
**Date:** 2026-09-12
**Based on:** merged code fact-check (k=3) at `docs/reviews/code-fact-check-report.md` plus replicates r1/r2/r3; findings marked Incorrect / Stale / Mostly Accurate there are treated as established and built on, not re-verified.

## Baseline Conventions

This repo's consumer-facing surface is not HTTP or SDK — it is a set of **path and name conventions that scripts, hooks, bats suites and prose docs bind to by literal string**. The conventions in force:

- **Payload staging (`devcontainer-config/install.sh` ↔ `link-claude-home.sh`).** Two parallel arrays name the same payload entries. `CLAUDE_HOME_SRC` names sources in the repo; `ENTRIES` names them in the baked payload. They have historically been the *same tokens*, which is why neither side documents a mapping.
- **Shell globals** in `scripts/*.sh` are `UPPER_SNAKE`, set once near the top, referenced by name (`REPO_ROOT`, `SRC`, `DEST`, `STAGE`, `FAIL`, `CLAUDE_HOME_SRC`).
- **Skill supporting files** live at `skills/<name>/references/<kebab-topic>.md`. The only prior instance is `skills/ui-visual-review/references/{3d-viewport,accessibility-serialization,runtime-verification}.md`; `skills/ai-personas-critique/personas.md` is the older flat form. `scripts/lib/skill-paths.sh:14-16` already encodes `references/` as explicitly *not* a skill definition.
- **Bats skill-contract suites** (`test/skills/code-review-*.bats`) share a shape: `setup()` resolves `REPO_ROOT`, sets `SKILL`, skips if absent, and materialises `SKILL_CONTENT` as the thing assertions grep. `test/skills/helpers.bash` exists and is `load`ed by at least one of these suites, so shared setup logic has a home.
- **Critical-path protection** is expressed as literal path lists in three places: `scripts/self-improvement.sh` Gate 1d (`case` patterns), `scripts/claude_config_audit.py:201` (default roots), and `hooks/claude-config-audit.sh:82-86` (basename `case`).
- **`scripts/cross-model-review.py` CLI**: long kebab flags, OpenRouter `vendor/model` ids, and a cost guard that refuses to send when a requested model cannot be priced.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `GLOBAL_MD` | shell global | `REPO_ROOT`, `FAIL`, `CLAUDE_HOME_SRC` | `scripts/health-check.sh:28,36`, `devcontainer-config/install.sh:19-27` | Consistent — UPPER_SNAKE script-global set at the top |
| `global-instructions/` | top-level dir | `workflows/`, `guides/`, `patterns/`, `templates/`, `devcontainer-config/` | repo root | Consistent — lowercase; hyphenated multiword has precedent in `devcontainer-config/` |
| `global-instructions/CLAUDE.md` (as a `CLAUDE_HOME_SRC` element) | config array element | `skills`, `workflows`, `guides`, `patterns`, `hooks`, `scripts` (bare names) | `devcontainer-config/install.sh:47` | **Inconsistent** — first element whose value is a path rather than the payload name; see Finding 3 |
| `skills/code-review/references/rubric.md` | skill reference file | `references/3d-viewport.md`, `references/accessibility-serialization.md`, `references/runtime-verification.md` | `skills/ui-visual-review/references/*.md` | Consistent path/kebab shape; **file-header shape diverges** — see Finding 5 |
| `skills/code-review/references/chat-synthesis.md` | skill reference file | same as above | `skills/ui-visual-review/references/*.md` | Same as above |
| `skills/code-review/references/override-log.md` | skill reference file | same as above | `skills/ui-visual-review/references/*.md` | Same as above; name also collides conceptually with the *artifact* `docs/reviews/override-log.md` |
| `SKILL_DIR` (bats) | test-local var | `SKILL`, `REPO_ROOT`, `FIXTURE`, `SKILL_CONTENT` | `test/skills/code-review-*.bats` `setup()` | Consistent naming; **value convention diverges** (absolute in 3 suites, repo-relative in `code-review-format-contract.bats`) — see Finding 6 |
| `SKILL_MD` (repointed to `references/rubric.md`) | test-local var | `SKILL` (= `SKILL.md`), `SKILL_DIR` | `test/skills/code-review-format-contract.bats:28,185` | **Inconsistent** — a variable named `SKILL_MD` that deliberately does *not* point at a `SKILL.md`, sitting three lines from `SKILL`, which does |
| `## Execution rules` (heading) | skill section | `## Mandatory Execution Rules` (retained in `skills/ui-visual-review/SKILL.md:58`) | `skills/{code-review,draft-review,matrix-analysis,ui-visual-review}/SKILL.md` | Inconsistent across the skill set — three renamed, one not; also leaves two dangling in-text references (Finding 2) |
| `#### Default output shape` (anchor `#default-output-shape`) | pattern anchor | `#default-output-cap` (retired) | `patterns/orchestrated-review.md:131` | Consistent — every live referrer updated; retired anchor survives only in `docs/` |
| `--judge` default `anthropic/claude-sonnet-5` | CLI default | `--models` (no default, priced + guarded) | `scripts/cross-model-review.py:371-374, 440-441, 460-461` | **Inconsistent** — same id namespace, asymmetric validation; see Finding 4 |

No new exported functions, routes, types or event names are introduced by this diff.

## Findings

#### 1. The global-instructions move silently disarmed Gate 1d's critical-file protection

**Severity:** Breaking
**Location:** `scripts/self-improvement.sh:1173-1180` (with `scripts/claude_config_audit.py:201`)
**Move:** #3 (trace the consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Gate 1d rejects a self-improvement task that deletes a critical file. Its consumer contract is a whole-string `case` match over `git diff --name-only --diff-filter=D` output (`scripts/self-improvement.sh:1126`), which emits repo-relative paths:

```
                for FILE in $DELETED_FILES; do
                    case "$FILE" in
                        scripts/self-improvement.sh|docs/evaluation-rubric.md|CLAUDE.md)
                            REJECT_REASON="deleted critical file: $FILE"
```

`case` patterns match the entire word, so `global-instructions/CLAUDE.md` no longer matches `CLAUDE.md`. An autonomous branch that deletes the global instructions file now passes Gate 1d and is recorded as `critical_files pass`. The same move breaks the auditor's default sweep:

```
    roots = args.paths or [".claude", str(Path.home()/".claude"), "CLAUDE.md"]
```

`iter_targets` (`scripts/claude_config_audit.py:140-145`) treats a non-file, non-directory root as an empty `os.walk` and yields nothing, so a bare `python3 scripts/claude_config_audit.py` run in this repo now scans the global instructions file zero times, with no message. Both are silent: the protection reports success while protecting nothing. (The PostToolUse gate at `hooks/claude-config-audit.sh:75-87` is *not* affected — it matches on `basename`, so `global-instructions/CLAUDE.md` still trips `claude.md`. Same for `hooks/guard-trusted-writes.py:79-80`, whose regex allows a `/` before the name.)

**Recommendation:** Add `global-instructions/CLAUDE.md` to the Gate 1d `case` list and to the `roots` default (keep `CLAUDE.md` too — the gate also runs against consumer projects where the file *is* at the root). Then update the documented list in `guides/validation-gates.md:105,229`, which still names the bare path.

#### 2. Two in-text references still cite the deleted "Mandatory Execution Rule" numbering

**Severity:** Inconsistent
**Location:** `skills/code-review/SKILL.md:945`, `skills/code-review/SKILL.md:957`
**Move:** #3 (documentation drift on a renamed contract)
**Confidence:** High
**Legibility-target:** for-author

`## Mandatory Execution Rules` and its six numbered rules were replaced by `## Execution rules` (prose, unnumbered). Two Stage-2.5 instructions still point at the old numbering:

```
   claims" section: same verdicts, same evidence discipline, same mandatory-execution rule
```
```
   verdicts of your own (Mandatory Execution Rule 1 still stands).
```

There is no longer a rule 1, nor a section by that name, in this skill or in the two sibling orchestrators. A reader (or an agent) following the pointer finds nothing; the constraint it was carrying — *the orchestrator collates, it does not author verdicts* — is now only implicit in the first paragraph of `## Execution rules`.

**Recommendation:** Replace both with a pointer to the live text, e.g. "(you add no verdicts of your own — see [Execution rules](#execution-rules))".

#### 3. `CLAUDE_HOME_SRC` changed element semantics; the coupled array in `link-claude-home.sh` documents nothing about it

**Severity:** Inconsistent
**Location:** `devcontainer-config/install.sh:41-55`, `devcontainer-config/link-claude-home.sh:43-47`
**Move:** #7 (asymmetry between paired interfaces)
**Confidence:** High
**Legibility-target:** for-author

The array's element contract changed from "a repo-root name, staged verbatim" to "a repo-relative path, staged under its basename." The install side states this:

```
# (prompt audit 2026-09-11, F1). Entries are staged under their basename, so
# the payload layout (and link-claude-home.sh) is unchanged.
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
```

The other half of the contract says nothing:

```
# Directories are linked wholesale; CLAUDE.md is a single file.
...
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
```

A maintainer adding an entry reads whichever file they are editing. From `link-claude-home.sh` alone there is no signal that these two arrays must agree, nor that the agreement is now on *basenames* rather than on identical tokens. Two consequences follow from the basename rule that neither side records: (a) two `CLAUDE_HOME_SRC` entries sharing a basename (`a/foo`, `b/foo`) now silently overwrite each other in `$STAGE` rather than producing distinct entries; (b) the warning on a missing entry still prints the full source path (`WARNING: $REPO_ROOT/$item not found`) while the payload name it would have produced is the basename — so the warning names something a reader cannot find in `ENTRIES`.

**Recommendation:** One line above `ENTRIES` naming `CLAUDE_HOME_SRC` as the source side and stating that entries pair by basename, plus a note in `install.sh` that basenames must be unique across the array.

#### 4. `--judge` takes a default model id that the cost guard neither prices nor validates, unlike `--models`

**Severity:** Inconsistent
**Location:** `scripts/cross-model-review.py:371-374`, `:436-461`
**Move:** #7 (asymmetry) / #3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Both flags carry OpenRouter `vendor/model` ids and both reach the same HTTP client, but only one is checked:

```
        unpriced = [m for m in args.models if pricing.get(m, (0, 0)) == (0, 0)]
```
```
        if unpriced:
            sys.exit(f"cost guard cannot price: {', '.join(unpriced)} — refusing to send "
```

`args.judge` is absent from both. So `--max-usd`'s projection excludes every stage-2 judge call, and a judge id that is mistyped or not offered by OpenRouter produces no startup error — it surfaces only when `judge_same()` (`:332-344`) starts making calls, after the review models have already been paid for. The fact-check flags `anthropic/claude-sonnet-5` as unconfirmed (no egress in this sandbox), which is precisely the condition the `--models` guard exists to catch early. The new comment reinforces that this default is a *pinned, comparability-bearing* value, which raises the cost of it being wrong.

**Recommendation:** Include `args.judge` in the `unpriced` computation (or, minimally, validate it against the pricing table and warn), and add its projected calls to the `--max-usd` estimate.

#### 5. The new `references/` files diverge from the repo's only existing `references/` convention on header shape and heading level

**Severity:** Minor
**Location:** `skills/code-review/references/{rubric,chat-synthesis,override-log}.md:1-5`
**Move:** #2 (naming/shape against the grain)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `# <Title>` + a visible "Reference for the `<skill>` skill. Load this file when …" line used in `skills/ui-visual-review/references/3d-viewport.md:1-4` and `skills/ui-visual-review/references/runtime-verification.md:1-5`.

The new files instead open with an invisible HTML comment and begin their content at `##`:

```
<!-- Reference file for skills/code-review/SKILL.md. Extracted from the skill body
     2026-09-11 (prompt audit F8) so it loads when the orchestrator reaches the
     stage that needs it, not on every trigger. Edit here, not in the skill. -->

## Deliverable 2: Code Review Rubric
```

Three differences from the established shape, each with a consumer: (a) no `# H1`, so the file has no rendered title and its top heading level is `##`, which is what makes the concatenated `SKILL_CONTENT` in the four bats suites contain three duplicated `## Deliverable 1` / `## Deliverable 2` / `## Override-Log` headings (one stub, one real) — the duplication the fact-check recorded is a direct consequence of this choice; (b) the header states *when it was extracted* rather than *when to load it*, which is the job the ui-visual-review header does and the job `SKILL.md:84-92` now has to do instead; (c) the provenance note is in a comment, invisible in any rendered view.

**Recommendation:** Give each file an `# H1` and a visible "Reference for the `code-review` skill. Read this at Stage N." line matching `ui-visual-review`, and demote the extracted sections one level. That also removes the duplicated-heading hazard in the concatenation.

#### 6. The `.bats` `SKILL_CONTENT` contract now has two incompatible definitions of "the skill" across seven sibling suites

**Severity:** Inconsistent
**Location:** `test/skills/code-review-{assurance-contract,executable-defect,format-contract,soundness-crosscheck}.bats` `setup()`; vs `test/skills/code-review-factcheck-replication.bats:21-23`, `test/skills/code-review-context-delivery.bats:18`, `test/lever-measurement-drift.bats:15`
**Move:** #1 / #7 (divergent definitions of the same contract across siblings)
**Confidence:** High
**Legibility-target:** for-author

Four suites now define the skill's content surface as a four-file concatenation:

```
  SKILL_CONTENT=$(cat "$SKILL" \
    "$SKILL_DIR/references/chat-synthesis.md" \
    "$SKILL_DIR/references/rubric.md" \
    "$SKILL_DIR/references/override-log.md" | tr -d '\r')
```

Three sibling suites in the same directory still define it as `SKILL.md` alone, with no comment saying why they are exempt. The divergence is not cosmetic, because the suites use *the same extraction idiom over different corpora*. `code-review-factcheck-replication.bats:144` runs

```
  echo "$SKILL_CONTENT" | sed -n '/^## Important Reminders/,$p' | tr '\n' ' ' | tr -s ' ' \
```

— the open-ended end anchor the fact-check already flagged in `code-review-assurance-contract.bats:123`. In the four changed suites that anchor now runs to the end of `override-log.md`; in this one it still runs to the end of `SKILL.md`. Same construct, same nominal subject, two different extents. The three unchanged suites are also now *silently* exempt from the reference files: if a future edit moves any of the content they assert on into `references/`, they go green-by-vacancy rather than red.

The duplication compounds it — the identical 8-line comment-plus-`cat` block is copy-pasted into four files, while `test/skills/helpers.bash` exists as a shared setup home and is already `load`ed by `code-review-format-contract.bats:16`.

**Recommendation:** Put the concatenation in one helper (`skill_content()` in `test/skills/helpers.bash`) and call it from all suites that assert on skill content; where a suite deliberately asserts on `SKILL.md` alone, say so in a one-line comment. Separately, bound the `/^## Important Reminders/,$p` anchors with an explicit end pattern so their extent stops depending on what is concatenated after them.

#### 7. `SKILL_MD` now names a file that is not a `SKILL.md`, three lines from `SKILL`, which is

**Severity:** Minor
**Location:** `test/skills/code-review-format-contract.bats:26-28`, `:183-185`, with the stale file-header at `:12-14`
**Move:** #2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `SKILL` = `<dir>/SKILL.md` in `test/skills/code-review-{assurance-contract,executable-defect,soundness-crosscheck}.bats` and in this same file at `:28`.

```
SKILL_MD="skills/code-review/references/rubric.md"
```

Within one file, `SKILL` is `SKILL.md` and `SKILL_MD` is not — a reader scanning `skill_template()` (`:187-193`, which reads `$SKILL_MD`) has to trace the assignment to learn which file the golden fixture is actually compared against. The file-level comment still asserts the old contract:

```
# The fixture is the format spec in executable form. When
# skills/code-review/SKILL.md's rubric template changes, update
# test/skills/code-review/rubric-current-format.md in the same commit.
```

**Recommendation:** Rename `SKILL_MD` to `RUBRIC_REF` (or `TEMPLATE_SRC`) and update the file header at `:12-14` to name `skills/code-review/references/rubric.md`.

#### 8. The move updated four doc referrers to `global-instructions/CLAUDE.md` and left at least six bare

**Severity:** Minor
**Location:** `guides/workflow-selection.md:5,47`; `guides/skill-trigger-guide.md:5`; `guides/skill-creation.md:43,76`; `guides/debugging-examples.md:3`; `guides/validation-gates.md:105,229`; `scripts/health-check.sh:13,14,25`
**Move:** #3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

`README.md`, `AGENTS.md`, `GEMINI.md` and `guides/cross-project-setup.md` were repointed. The "canonical source" pointers were not:

```
> **Canonical source:** The workflow decision tree in `CLAUDE.md` is authoritative. This guide expands on it with disambiguation tips and worked examples. If this guide and CLAUDE.md conflict, CLAUDE.md wins.
```

Before the move, a bare `CLAUDE.md` in a guide was unambiguous — the repo had exactly one. It now has none at the root, and every consumer project reading these guides has its own project `CLAUDE.md`, so "CLAUDE.md wins" reads as *the project's* file rather than the global instructions. `health-check.sh`'s own header (`:13,14,25`) describes checks 2, 3 and 13 as operating on `CLAUDE.md` while the code below them reads `$GLOBAL_MD` — the same file whose path the commit went out of its way to make a variable.

**Recommendation:** Sweep bare `CLAUDE.md` references in `guides/` and `scripts/health-check.sh`'s header. Where the referent is genuinely the *project's* file (e.g. `guides/cross-project-setup.md:19,47,60`), leave it and let the distinction carry meaning.

#### 9. The `CLAUDE_HOME_SRC` regression test asserts on a substring that cannot see the change

**Severity:** Informational
**Location:** `test/cc-isolated-functions.bats:420-427`
**Move:** #3 (test drift)
**Confidence:** High
**Legibility-target:** for-author

```
@test "install.sh stages the payload from the repo root" {
  run grep -E 'CLAUDE_HOME_SRC=' "$CONFIG_SRC/install.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'skills'* ]]
  [[ "$output" == *'CLAUDE.md'* ]]
```

The substring `CLAUDE.md` matches `global-instructions/CLAUDE.md`, so the suite stayed green — but that means it is blind to the element-semantics change, and the test *name* ("from the repo root") now describes a contract the code no longer has. Nothing anywhere asserts that `$STAGE` ends up with a top-level `CLAUDE.md`, which is the actual invariant `link-claude-home.sh`'s `ENTRIES` depends on.

**Recommendation:** Rename the test and add an assertion on the staging outcome — that every `CLAUDE_HOME_SRC` basename appears in `link-claude-home.sh`'s `ENTRIES` — so the pairing in Finding 3 is enforced rather than described.

#### 10. `skills/ui-visual-review/SKILL.md` keeps `## Mandatory Execution Rules` after three siblings dropped it

**Severity:** Informational
**Location:** `skills/ui-visual-review/SKILL.md:58`
**Move:** #2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Precedent: `## Execution rules` now used in `skills/{code-review,draft-review,matrix-analysis}/SKILL.md`.

The audit's stated scope was the three orchestrator skills, and `ui-visual-review` is a critic rather than an orchestrator, so this is likely deliberate rather than missed. Noting it so the divergence is a decision on record: after this commit, "Mandatory Execution Rules" is a section name with exactly one instance left in `skills/`.

**Recommendation:** No action required. If the de-pressuring convention is meant to be repo-wide rather than orchestrator-only, record that in `docs/decisions/log.md` alongside row 47 so the next audit knows which it is.

## What Looks Good

- **`GLOBAL_MD` is applied to every consumer of the literal it replaced.** All three loops and both associative-array key families (`h2_set`, `skill_set`) were converted together, including the user-facing `warn` strings, so a reader of the output sees one path consistently rather than a mix.
- **The basename staging keeps the payload contract genuinely unchanged.** Moving the source without moving the destination is the narrow change; `link-claude-home.sh`, `devcontainer.json`, and the `~/.claude/CLAUDE.md` link target all keep working untouched. The comment explaining *why* the file moved sits at the array, which is where a maintainer adding an entry looks.
- **The `references/` path and file-naming shape match the one existing precedent exactly** (`skills/<name>/references/<kebab-topic>.md`), and `scripts/lib/skill-paths.sh:14-16` already classified that subtree correctly, so the new files need no change to skill-path classification, hook logging, or health-check skill enumeration.
- **The retired `#default-output-cap` anchor left no live dangling referrer.** Every inheriting site (`guides/sub-agent-briefing.md`, `guides/README.md`, `guides/task-decomposition-examples.md`, `workflows/task-decomposition.md`, `skills/matrix-analysis/SKILL.md`) was moved to the new name in the same commit.
- **Basename-keyed protections survived the move for free** — `hooks/claude-config-audit.sh:75-87` and `hooks/guard-trusted-writes.py:79-80` both still match `global-instructions/CLAUDE.md`. This is worth knowing precisely because the two path-keyed protections (Finding 1) did not.

**Assurance note (`route: code-fact-check`):** the positive claims above about test outcomes and end-to-end payload behavior — specifically that the four changed bats suites pass under the concatenated `SKILL_CONTENT`, that `install.sh` produces a `$STAGE` containing a top-level `CLAUDE.md`, and that `hooks/claude-config-audit.sh` fires on the new path — are read from source, not executed here. Route them to code-fact-check for execution rather than treating them as verified.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Gate 1d + auditor default roots no longer match the global instructions file | Breaking | `scripts/self-improvement.sh:1176`, `scripts/claude_config_audit.py:201` | High |
| 2 | Dangling "Mandatory Execution Rule 1" references after the section was replaced | Inconsistent | `skills/code-review/SKILL.md:945,957` | High |
| 3 | `CLAUDE_HOME_SRC` element semantics changed; `ENTRIES` side undocumented | Inconsistent | `devcontainer-config/link-claude-home.sh:43-47` | High |
| 4 | `--judge` default neither priced nor validated, unlike `--models` | Inconsistent | `scripts/cross-model-review.py:374,440,460` | High |
| 5 | New `references/` headers diverge from the `ui-visual-review` precedent | Minor | `skills/code-review/references/*.md:1-5` | High |
| 6 | Two incompatible `SKILL_CONTENT` definitions across seven sibling suites | Inconsistent | `test/skills/code-review-*.bats` `setup()` | High |
| 7 | `SKILL_MD` names a non-`SKILL.md`; file header still names the old source | Minor | `test/skills/code-review-format-contract.bats:12-14,185` | High |
| 8 | Six-plus doc referrers left on the bare `CLAUDE.md` path | Minor | `guides/*.md`, `scripts/health-check.sh:13,14,25` | High |
| 9 | `CLAUDE_HOME_SRC` test asserts a substring blind to the change | Informational | `test/cc-isolated-functions.bats:420-427` | High |
| 10 | One `## Mandatory Execution Rules` left in `skills/` | Informational | `skills/ui-visual-review/SKILL.md:58` | Medium |

## Overall Assessment

The diff is careful about the contracts it *knew* it was touching: the `GLOBAL_MD` variable was threaded through every consumer including the warn strings, the basename staging was chosen specifically so the payload and `link-claude-home.sh` would not move, and the retired output-cap anchor left no dangling referrer. What it missed is the class of consumer that binds to the *old literal string* from outside the files under edit — Finding 1 is the one that matters, because a protective gate that silently reports `pass` while protecting nothing is strictly worse than no gate, and the same move also emptied the auditor's default sweep. Everything else is fixable in place in under an hour: two dangling pointers, one array-pairing comment, one CLI validation asymmetry, and a test-convention split that is best closed by moving the concatenation into the helpers file the suites already load. The `references/` extraction is structurally sound and matches the one existing precedent on path and naming; only the file-header shape and the resulting `##`-level heading duplication want a second pass. No consumer of a *runtime* interface breaks — the payload layout, the `~/.claude` link targets, and the basename-keyed policy hooks all keep working.

## Goal-Alignment Note

- **Answered:** Yes. All five prioritised contracts were examined against their actual consumers — `CLAUDE_HOME_SRC`/`ENTRIES` (Findings 3, 9), `GLOBAL_MD` (Findings 1, 8, plus the What-Looks-Good note), the `references/` convention (Finding 5, checked against `ui-visual-review`, `ai-personas-critique`, and `scripts/lib/skill-paths.sh`), the `.bats` `SKILL_CONTENT` contract across all seven sibling suites (Findings 6, 7), and `--judge` (Finding 4).
- **Out of scope:** Whether the rewritten prose is *effective* at the behavioral goal (removing pressure language without losing the constraint) — that is a prompt-quality question, not an interface-consistency one. I did check that the constraints the deleted numbered rules carried still exist somewhere, which is how Finding 2 surfaced. Also out of scope: the correctness of the `anthropic/claude-sonnet-5` id itself (no egress; already recorded by the fact-check).
- **Escalate:** Finding 1 to the orchestrator as a Must-Fix candidate independent of severity mapping — it is a silent failure in a protective gate, and its blast radius (autonomous self-improvement branches) is outside what any test in this diff covers.
- **Questions I would have asked:** (a) Is the de-pressuring convention meant to be repo-wide, or orchestrator-only? Finding 10 is Informational under the second reading and Inconsistent under the first. (b) Was leaving `code-review-factcheck-replication.bats` on the SKILL.md-only definition deliberate (its assertions genuinely live in SKILL.md) or incidental? The answer decides whether Finding 6 is a comment or a refactor.
