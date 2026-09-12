# Architecture Review — prompt-audit restructure (2d679ce..HEAD)

Commit: 0661353

**Scope:** `git diff -M -C 2d679ce..HEAD` — 27 files, dominated by two moves (`CLAUDE.md` → `global-instructions/CLAUDE.md`; ~680 lines of `skills/code-review/SKILL.md` → `skills/code-review/references/{rubric,chat-synthesis,override-log}.md`)
**Date:** 2026-09-12
**Based on:** merged k=3 code-fact-check (Incorrect / Stale / Mostly Accurate items supplied by the orchestrator; not re-verified here)

---

## Dependency Map

Two structures changed.

**1. The prompt-surface payload.** `devcontainer-config/install.sh` is the composition root
for the image payload: it stages a fixed list of repo paths into `devcontainer-config/claude-home`,
which the Dockerfile bakes and `link-claude-home.sh` links to `~/.claude`. Before this diff the
mapping was identity (`cp -r "$REPO_ROOT/$item" "$STAGE/$item"`). It is now a **basename
projection** (`"$STAGE/$(basename "$item")"`), so the source tree and the deployed tree are
allowed to disagree for exactly one entry. Everything downstream of the payload — `guides/`,
`skills/`, `workflows/`, `patterns/`, `hooks/`, `scripts/`, and the global instructions file —
is read at `~/.claude/<basename>` and resolves its own relative links there. The staged payload
on disk confirms the flattening: `devcontainer-config/claude-home/` contains `CLAUDE.md` at its
root, and no `global-instructions/` directory.

`scripts/health-check.sh` is a second consumer of the source layout; it now reads the path from
a single `GLOBAL_MD` variable and compares `global-instructions/CLAUDE.md` against the two
root-level siblings `AGENTS.md` and `GEMINI.md`. `AGENTS.md` and `GEMINI.md` are **not** staged
into the payload, so their references are repo-relative only; `guides/` **is** staged, so its
references are read in both layouts.

**2. The code-review skill.** `skills/code-review/SKILL.md` (1,909 → 1,256 lines) now sits above
three sibling files under `references/`: `rubric.md` (515), `chat-synthesis.md` (126),
`override-log.md` (52). The intended shape is a spine with three leaves loaded late. The actual
edge set is denser: SKILL.md carries **19 links into `references/`** from 17 distinct sites
spanning Step 3.5, Stage 2.5, four Stage-3 cross-checks and Important Reminders;
`chat-synthesis.md:80` links laterally into `rubric.md`; and `rubric.md:513` links back **up**
into `../SKILL.md`. External consumers reach in too: `workflows/pr-prep.md:183` now targets
`references/override-log.md#capture-format`.

Both path-based consumers survive the skill split intact. `scripts/self-improvement.sh` passes
`CR_SKILL` as a *path* and grants `CR_ADD_DIR="/opt/claude-workflows"`, so the reviewer can
follow the relative links; the untrusted-fallback branch confines to `$WT_DIR`, which also
contains `references/`. Neither needed a change, and neither got one.

---

## Findings

#### The split's cut line is stated by content-type but drawn by document, and `rubric.md` is a running dependency rather than a deliverable leaf

**Severity:** Coupling
**Legibility-target:** the orchestrator model reading SKILL.md mid-run
**Location:** `skills/code-review/SKILL.md:81-92`, `:741`, `:960-962`, `:997`, `:1025`, `:1037`, `:1092`
**Move:** #2 (responsibility boundaries), #7 (coupling surface)
**Confidence:** High

The stated rule is that anything needed to *run* a stage stays resident and anything needed only
to *write a deliverable* moves. `references/rubric.md` breaks it: it holds the Unified Severity
Mapping, the Escalation Rule, the evidence-grounding contract and both evidence channels, and
those are consumed by the *running* pipeline at three separate points before any deliverable is
written. SKILL.md's own header admits as much — the reference-files table concedes rubric.md is
"Needed from the moment you tier a finding (Stage 3, and Stage 2.5 when it runs)", which is not
a deliverable-time need.

**Evidence:**

```
- **[references/rubric.md](references/rubric.md)** — the rubric template, tier definitions,
  evidence grounding, the Unified Severity Mapping, the escalation rule and the two evidence
  channels. Needed from the moment you tier a finding (Stage 3, and Stage 2.5 when it runs).
```
(`SKILL.md:86-88`)

```
   rubric tiered by the [Unified Severity Mapping](references/rubric.md#unified-severity-mapping)'s fact-check
   column (behavioral-vs-doc scoping included), with the fact-check evidence as the row's
```
(`SKILL.md:962-963`, inside Stage 2.5 — a stage that runs before synthesis)

```
[Confirmed Good is a claim, not an output](references/rubric.md#confirmed-good-is-a-claim-not-an-output):
```
(`SKILL.md:997`, the first of four Stage-3 cross-checks, each of which opens with a link into
`rubric.md`: `:997`, `:1025`, `:1037`, `:1092`)

The consequence is not that the pipeline cannot run — every use site carries an explicit deep
link, so a reader who follows links gets there. It is that the file that was supposed to be a
late-loaded leaf is in fact a shared dependency of three stages, so (a) the load-deferral buys
nothing on any run that reaches Stage 2.5 or Stage 3, which is every run that is not
short-circuited at the fact-check gate, and (b) the module's public surface is now its
**internal `###` anchors**, not its content: a rename of `### Unified Severity Mapping` or
`### Escalation Rule` silently breaks references in two files plus `workflows/pr-prep.md`. That
is content coupling to a document's internal structure, and nothing in the test suites asserts
anchor resolution.

**Recommendation:** Cut along the stated rule rather than along the deliverable. Split
`rubric.md` into `references/severity.md` (Unified Severity Mapping, escalation rule, evidence
grounding, the soundness and executable-defect channels — read once at Stage 1.5/2.5 and held)
and `references/rubric.md` (the template, the nine tier sections, the status line — read at
Stage 3 only). That makes each file single-purpose and gives each exactly one load point.

#### The reference files are not leaves: `rubric.md` links up into a stub, producing a four-document cycle

**Severity:** Coupling
**Legibility-target:** the orchestrator model; any future editor of the skill
**Location:** `skills/code-review/references/rubric.md:513`, `skills/code-review/references/chat-synthesis.md:80`, `skills/code-review/SKILL.md:1132-1140`
**Move:** #1 (dependency direction), #7 (circular dependencies)
**Confidence:** High

Dependency direction should run spine → leaves. It does not. `rubric.md` points back up at
SKILL.md's `Deliverable 1` heading — but that heading is now a five-line stub whose only content
is a pointer *down* to `chat-synthesis.md`, which in turn points sideways back into `rubric.md`.

**Evidence:**

```
(see [Deliverable 1](../SKILL.md#deliverable-1-chat-synthesis)). Do not expand it into a paragraph,
```
(`references/rubric.md:513`)

```
Present this directly in the chat, self-contained — assume the user has NOT read the
individual agent reports. Required structure, the coverage-and-escalations block, the
considered-overrides block, the single-sample label and the next-action line are specified in
**[references/chat-synthesis.md](references/chat-synthesis.md)**. Read it before writing the
synthesis; it is the format contract, not background.
```
(`SKILL.md:1134-1138` — the entire body of the anchor `rubric.md:513` targets)

```
[The single-sample label](rubric.md#the-single-sample-label)) and it is the whole of the hedging —
```
(`references/chat-synthesis.md:80`)

So `rubric.md → SKILL.md → chat-synthesis.md → rubric.md` is a closed loop, and the one link in
it that the reader actually needs — "where is the label's second emission site specified?" —
routes them through a stub instead of to `chat-synthesis.md:77`, where the answer is. This is
cheap to break (they are prose links, not a build graph), which is why it is Coupling and not
Structural, but it is the failure mode the extraction was supposed to remove: an orchestrator
that follows the citation lands on a forwarding address.

**Recommendation:** Make `rubric.md:513` point at `chat-synthesis.md#structure-the-chat-synthesis-as`
directly — a leaf may cite a sibling leaf, but it should never cite the spine's stub for content
the spine no longer holds. Adopt the rule explicitly ("references cite each other or nothing;
only SKILL.md cites downward") so the next extraction does not re-introduce the cycle.

#### The payload's basename projection lets the source and deployed layouts diverge silently, and one staged document now cites a path that does not exist in the payload

**Severity:** Coupling
**Legibility-target:** an agent reading `~/.claude/guides/cross-project-setup.md` inside a cc-isolated container
**Location:** `devcontainer-config/install.sh:42-53`, `guides/cross-project-setup.md:7`, `:34`
**Move:** #4 (layer violations), #3 (module boundary)
**Confidence:** High

`install.sh` is the seam between the repo layout and the deployed `~/.claude` layout. The diff
turns its previously-identity mapping into a projection, and records the intent in a comment:

**Evidence:**

```
# The global instructions file is sourced from global-instructions/ rather than
# the repo root: at the root, a session working in THIS repo loads it twice —
# once as the linked ~/.claude copy and once as the project's own instructions
# (prompt audit 2026-09-11, F1). Entries are staged under their basename, so
# the payload layout (and link-claude-home.sh) is unchanged.
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
```
(`install.sh:42-47`)

```
    cp -r "$REPO_ROOT/$item" "$STAGE/$(basename "$item")"
```
(`install.sh:53`)

Keeping the payload root stable is the right call — it is what spares `link-claude-home.sh`, the
Dockerfile and the launcher from this change. The cost is that the mapping is now **implicit and
unnamed**: `basename` is a rule about *how* to flatten, not a declaration of *what maps to what*,
so nothing in the repo states that `global-instructions/CLAUDE.md` is deployed as `CLAUDE.md`,
and nothing detects a future collision (two entries whose basenames match silently overwrite each
other, last-one-wins, with no warning — the `-e` guard only covers absence).

The divergence has already produced a live inconsistency in `guides/`, which **is** staged into
the payload:

```
Copy the **Workflow & Skill Activation** section from `global-instructions/CLAUDE.md` into your target project's `CLAUDE.md`.
```
(`guides/cross-project-setup.md:7`; same substitution at `:34`)

Read from the repo, that path is correct. Read from `~/.claude/guides/cross-project-setup.md` —
where the staged copy lives, and where a cc-isolated session actually reads it — there is no
`global-instructions/` directory; the file is at `~/.claude/CLAUDE.md`. The pre-move text
(`` `CLAUDE.md` ``) read as a bare filename and was correct in both layouts; the new text reads
as a path and is correct in only one.

**Recommendation:** Replace the `basename` call with an explicit source→destination map
(`CLAUDE_HOME_SRC=("global-instructions/CLAUDE.md:CLAUDE.md" skills workflows ...)`, split on
`:`), so the one place the layouts diverge is written down rather than computed, and add a
duplicate-destination guard. Separately, restore `guides/cross-project-setup.md` to a
layout-neutral reference — it is staged, so it must be true in both trees.

#### "The skill" is now a four-file composite with a load-bearing concatenation order, reconstructed by a duplicated snippet in four suites while three siblings keep the one-file definition

**Severity:** Coupling
**Legibility-target:** a future editor moving another section out of SKILL.md
**Location:** `test/skills/code-review-assurance-contract.bats:24-34` (and the byte-identical block in `code-review-executable-defect.bats`, `code-review-format-contract.bats`, `code-review-soundness-crosscheck.bats`); `test/skills/code-review-factcheck-replication.bats:21`, `test/skills/code-review-context-delivery.bats:18`, `test/lever-measurement-drift.bats:15`
**Move:** #2 (responsibility boundaries), #8 (extension points)
**Confidence:** High

The diff introduces a new concept — *the code-review skill's content surface* — and then
implements it four times by copy-paste, with no owner.

**Evidence:**

```
  # The skill's content surface spans SKILL.md plus its references/ files: the
  # deliverable templates, rubric semantics and override-log format were extracted
  # 2026-09-11 (prompt audit F8) so they load at the stage that needs them. Read in
  # document order so section-extraction end anchors still follow their sections.
  SKILL_CONTENT=$(cat "$SKILL" \
    "$SKILL_DIR/references/chat-synthesis.md" \
    "$SKILL_DIR/references/rubric.md" \
    "$SKILL_DIR/references/override-log.md" | tr -d '\r')
```
(`code-review-assurance-contract.bats:27-34`)

Three consequences follow from having no single owner for that definition:

1. **The order is load-bearing and enforced only by a comment.** `code-review-soundness-crosscheck.bats:41`
   and `code-review-executable-defect.bats:38` both extract ranges bounded by
   `/^### Rubric Status Line/`, which exists only in `rubric.md`. Reorder the `cat` arguments
   and those ranges silently invert or empty. Nothing asserts the order.
2. **Open-ended anchors silently widen.** `code-review-assurance-contract.bats:123` runs
   `sed -n '/^## Important Reminders/,$p'` — previously the tail of SKILL.md, now the tail of
   SKILL.md *plus all 693 lines of the three references*. The identical idiom at
   `code-review-factcheck-replication.bats:144` was not migrated, so the same anchor means two
   different things in two suites in the same directory.
3. **Seven suites, two definitions of "the skill", no stated rule for which to use.** The three
   unmigrated suites happen to be correct today because their targets (Step 1, Stage 1, the
   032 #4 figures) stayed resident — but that is a coincidence of this extraction, not a
   property anyone can rely on. The next section that moves will break them, and the breakage
   will look like a content failure rather than a surface-definition failure.

`test/skills/helpers.bash` already exists as the natural owner and is loaded by exactly one of
the four migrated suites (`code-review-format-contract.bats:16`).

**Recommendation:** Put the composite in `test/skills/helpers.bash` as one function
(`code_review_skill_content()`), have all seven suites call it, and add one assertion there that
the concatenation order places `### Soundness-Contradiction Channel` before
`### Rubric Status Line`. That gives the new concept a single home and makes the ordering
contract testable rather than commented.

#### The entry-point triple is split across two homes while still documented and checked as one unit

**Severity:** Minor
**Legibility-target:** a human reading README's "Entry points" list or a health-check warning
**Location:** `README.md:123-126`, `scripts/health-check.sh:200-207`, `:941-980`, `AGENTS.md:16`, `GEMINI.md:16`
**Move:** #2 (responsibility boundaries)
**Confidence:** Medium

`README.md` still presents the three files under one heading — "Entry points (one per tool
ecosystem)" — while one of them now lives a directory down. The asymmetry is *justified*: only
Claude Code auto-loads `CLAUDE.md` as project instructions, so only that file had the
double-load problem, and `AGENTS.md`/`GEMINI.md` are not staged into the payload at all. But the
layout no longer says so, and `health-check.sh` now compares a path against two bare filenames
inside one loop, mixing the two kinds of identifier in its accumulator and its output
(`warn "H2 sections in $GLOBAL_MD not in $sibling"` vs `warn "H2 sections in $sibling not in $GLOBAL_MD"`).

A second symptom: the repo now names the same document two ways depending on which file you are
reading. `AGENTS.md:16` and `GEMINI.md:16` were rewritten to `global-instructions/CLAUDE.md`,
while `workflows/pr-prep.md:202`, `workflows/parallel-worktrees.md:2`,
`workflows/divergent-design.md:27`, `docs/workflow-selection.md:9` and
`docs/workflow-dependency-graph.md:16` still say bare `CLAUDE.md` for the same file. Both
spellings are defensible in isolation (path vs. harness-visible name); having both, chosen
inconsistently, is what costs a reader.

**Recommendation:** Add one line to README's entry-point list naming the rule — "the Claude
entry point is the only one the harness also loads as project instructions, so it is the only
one held outside the root" — and pick one spelling convention repo-wide: cite the *deployed*
name (`CLAUDE.md`) in prose about behavior, and the repo path only where a reader must open the
file in this repo.

#### `si-functions.sh` points at SKILL.md for a rubric contract that moved

**Severity:** Minor
**Legibility-target:** a maintainer of the self-improvement review gate
**Route:** code-fact-check
**Location:** `scripts/lib/si-functions.sh:590-592`
**Move:** #7 (coupling surface)
**Confidence:** High

**Evidence:**

```
# Counts rows in the "## 🔴 Must Fix" section only, matching the rubric format
# in skills/code-review/SKILL.md: `| R1 | ... |`. Placeholder rows (`| — |`) do
# not count. Prints nothing when no rubric is present or it has no Must Fix
```
(`si-functions.sh:590-592`)

The `| R1 | ... |` row template now exists only at `skills/code-review/references/rubric.md:43`.
This is the third-party face of the anchor-coupling in the first finding: `count_rubric_red()`
parses a format owned by a file it does not name, and the pointer that would have led a
maintainer there is now wrong. Not caught by the supplied fact-check, which covered
`pr-prep.md`, `SKILL.md:158` and `SKILL.md:1173`.

**Recommendation:** Retarget the comment to `skills/code-review/references/rubric.md`.

#### Two further "below" references now point out of the file

**Severity:** Minor
**Legibility-target:** the orchestrator model following an in-document pointer
**Route:** code-fact-check
**Location:** `skills/code-review/SKILL.md:741`, `:992`
**Move:** #3 (module boundary)
**Confidence:** High

**Evidence:**

```
For every core critic you skip, you MUST record it in the rubric under the `## ⏭️ Skipped Core Critics` section (see Deliverable 2 below) with the critic name, the skip reason, and the specific signal observed
```
(`SKILL.md:741` — "Deliverable 2 below" is now a five-line stub; the section's actual definition
is `references/rubric.md:116`)

```
The collected items feed the `### Coverage and Escalations` section of the chat synthesis below.
```
(`SKILL.md:992` — that heading is now `references/chat-synthesis.md:26`)

These are the same class as the two the fact-check flagged (`:158`, `:1173`) but are additional
instances, and both sit in *running* stages (1.5 and 3's goal-alignment scan) rather than in
deliverable prose — so they are the positions where a reader following the pointer is mid-run.

**Recommendation:** Sweep every `below` in SKILL.md whose referent moved, and replace with the
same `[Label](references/<file>.md#anchor)` form used elsewhere.

#### `references/` establishes a repo convention on its first instance, diverging from the shape the repo's own audit proposed — and the 500-line ceiling is still unmet

**Severity:** Informational
**Legibility-target:** whoever splits the next oversized skill
**Location:** `skills/code-review/references/`, `guides/skill-format-audit.md:15`, `:121-126`
**Move:** #8 (extension points)
**Confidence:** High

`skills/code-review/references/` is the first such directory in `skills/`. The repo's own audit
already specified the pattern for the next candidate and specified it differently — sibling files
directly in the skill directory, no `references/` level:

**Evidence:**

```
- **F5 (ui-visual-review exceeds 500 lines) — Partially addressed.** The directory wrapper is now in place at `skills/ui-visual-review/SKILL.md`, so the proposed sub-file split is now mechanically feasible. The actual extraction of `runtime-verification.md` and `affordance-principles.md` into the directory is still pending.
```
(`guides/skill-format-audit.md:15`)

Two shapes for one problem, with the second one arriving first as working code. Worth settling
now, while there is exactly one instance to migrate. Note also that the extraction leaves
SKILL.md at 1,256 lines against the 500-line guideline this repo records at
`guides/skill-format-audit.md:126`, and `rubric.md` itself at 515 — so the ceiling is not a
reachable target under this shape, and the split's real justification is load *timing*, not size.

**Recommendation:** Write the convention down (one line in `guides/skill-format-audit.md`:
`skills/<name>/references/<topic>.md`, references may cite each other but not the spine), and
state in the same place that the 500-line figure is a guideline this repo's orchestrator skills
do not meet, so the next reader does not chase it.

---

## What Looks Good

- **Co-location kept the path-based consumers working unchanged.** `scripts/self-improvement.sh`
  hands the reviewer a *path* (`CR_SKILL`) plus a read root (`CR_ADD_DIR="/opt/claude-workflows"`),
  and its untrusted-fallback branch confines to `$WT_DIR`. Because `references/` sits beside
  SKILL.md, both branches still reach the full surface with no edit. Putting the references
  anywhere else — a top-level `docs/` or a shared `patterns/` — would have required widening the
  reviewer's read root, which is a security boundary (the comment at `self-improvement.sh:1375-1380`
  explains why). The extraction respected that boundary without being told to.
- **Keeping the payload root stable was the right constraint to hold.** The basename projection
  is under-specified (finding 3), but the decision it implements — absorb the layout change in
  the one script that owns assembly, rather than propagating it to `link-claude-home.sh`, the
  Dockerfile and the launcher — puts the change at the correct seam and keeps the blast radius
  at one file.
- **`GLOBAL_MD` localizes the path to one definition** in a 1,000-line script that previously
  had the literal in eight places. `scripts/health-check.sh:35` is the right granularity: one
  variable, one comment explaining why the path is unusual.
- **Decision-log row 47 records the rejected alternative**, not just the choice — dropping the
  global symlink was considered and refused on the grounds that the file's job is to apply in
  every *other* project. That is the information a future reader needs to avoid re-litigating.
- **Skill discovery was not disturbed.** Both `scripts/health-check.sh:79` and
  `test/skills/frontmatter-fields.bats` enumerate `skills/<name>/SKILL.md`, so the new
  frontmatter-less `references/*.md` files do not register as skills. The new directory level was
  chosen to sit outside the discovery glob, which is why no discovery code changed.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cut line stated by content-type, drawn by document; `rubric.md` is a running dependency of 3 stages; 19 inbound deep links | Coupling | `skills/code-review/SKILL.md:81-92,741,960-962,997,1025,1037,1092` | High |
| 2 | References are not leaves: `rubric.md:513` links up into a stub, closing a four-document cycle | Coupling | `references/rubric.md:513`, `references/chat-synthesis.md:80`, `SKILL.md:1132-1140` | High |
| 3 | Basename projection lets source and deployed layouts diverge implicitly; a staged guide now cites a path absent from the payload | Coupling | `devcontainer-config/install.sh:42-53`, `guides/cross-project-setup.md:7,34` | High |
| 4 | "The skill" is a four-file composite with a load-bearing order, duplicated in 4 suites, contradicted by 3 siblings, owned by nobody | Coupling | `test/skills/code-review-assurance-contract.bats:24-34` +6 suites | High |
| 5 | Entry-point triple split across two homes, still documented and checked as one unit; two spellings for one file | Minor | `README.md:123-126`, `scripts/health-check.sh:200-207,941-980` | Medium |
| 6 | `si-functions.sh` cites SKILL.md for a rubric row format that moved | Minor (route: code-fact-check) | `scripts/lib/si-functions.sh:590-592` | High |
| 7 | Two further out-of-file "below" references, both in running stages | Minor (route: code-fact-check) | `skills/code-review/SKILL.md:741,992` | High |
| 8 | `references/` sets a convention on first use, diverging from the audit's own proposal; 500-line ceiling unmet | Informational | `skills/code-review/references/`, `guides/skill-format-audit.md:15,121-126` | High |

---

## Overall Assessment

Both moves are structurally sound in direction and under-specified in their seams. The
`CLAUDE.md` relocation is the cleaner of the two: it removes a real duplicate load, absorbs the
layout change in the single script that owns payload assembly, and touches nothing downstream —
its one defect is that the flattening rule is computed (`basename`) rather than declared, which
has already let a staged guide acquire a path that is false in the deployed tree. The skill split
is the weaker one. It is not wrong — every use site carries an explicit link, the pipeline runs,
and co-locating the references preserved a security boundary that a different placement would
have forced open. But it did not buy what it was for. The file it extracted is read at Stage 1.5,
Stage 2.5 and four Stage-3 cross-checks, so on any run that is not short-circuited at the
fact-check gate the deferral saves nothing, and in exchange `rubric.md`'s internal `###` anchors
became a public API with nineteen call sites across three files and no test asserting they resolve.

The single most important structural concern is **finding 1**: the boundary was drawn between
"the pipeline" and "the deliverables" when the thing that actually wants to be one module is
*severity semantics* — mapping, escalation, evidence grounding, the two channels — which the
pipeline consults continuously and which is currently filed as deliverable material. Re-cutting
`rubric.md` into a `severity.md` read once at Stage 1.5 and a template read once at Stage 3 would
make the author's own stated rule true, give each file one load point, and shrink the anchor
surface. Everything else here is fixable in place, and most of it is a sweep: retarget three
stale pointers, break the citation cycle, hoist the test composite into `helpers.bash`, and make
the payload map explicit.

---

## Goal-Alignment Note

- **Answered:** All five structural questions in the brief. (1) The cut line is not respected as
  stated — finding 1. A reader who loads only SKILL.md *can* run the pipeline, because every use
  site links out explicitly, but the fan-out is a worse coupling shape than the monolith on one
  axis: the monolith had no anchor contract to break. (2) Dependency direction is not defensible
  as built — finding 2. (3) The three-way layout is coherent in *mechanism* (only Claude Code
  double-loads) but incoherent in *presentation* — finding 5. (4) `install.sh` is the right place
  for the mapping; the mapping itself should be declared, and a future entry must be checked for
  basename collision — finding 3. (5) Yes, there is a missing abstraction, and
  `test/skills/helpers.bash` should own it — finding 4.
- **Out of scope:** Whether the prompt audit's token-saving estimate holds (measurement, not
  structure); the prose edits to `patterns/orchestrated-review.md`, `guides/sub-agent-briefing.md`,
  `skills/draft-review`, `skills/matrix-analysis` (the output-cap → output-shape change) — these
  modify instruction content inside existing modules without touching structure, and the
  `--judge` default bump in `scripts/cross-model-review.py` is a config value, not a contract.
- **Escalate:** `guides/cross-project-setup.md:7,34` is a live incorrectness in the *deployed*
  payload, not just a stale doc — worth fixing in this PR rather than deferring, since the next
  `install.sh` bakes it.
- **Questions:** Is the double-load fix expected to take effect only after the next
  `install.sh` + rebuild (as decision-log row 47 states), and if so, is there anything that tells
  a session running on a stale image that it is still loading two copies? The provenance stamp at
  `install.sh:58-64` records the commit, but nothing appears to compare it at session start.
