# Code Fact-Check Report

Commit: 0661353

**Repository:** `/workspace` (claude-workflows)
**Scope:** `git diff -M -C 2d679ce..HEAD` (4 commits: `4d41add`, `c56be81`, `59ca38f`, `0661353`) plus the four commit messages. 27 files; the bulk is two pure moves (`CLAUDE.md` → `global-instructions/CLAUDE.md`, 97% similarity; ~680 lines lifted from `skills/code-review/SKILL.md` into `skills/code-review/references/*.md`), both re-derived below rather than re-read as new.
**Checked:** 2026-09-12
**Total claims checked:** 29
**Summary:** 20 verified, 5 mostly accurate, 1 stale, 1 incorrect, 2 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 2 entries). Claim 18 matches the logged class *"a specific measured value quoted from a checked-in artifact set that does not contain it"* — flagged inline and appended to the log.

Execution artifacts for this run:
- `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`
- `docs/reviews/execution-logs/r2-health-check-head-2026-09-12.txt`
- `docs/reviews/execution-logs/r2-health-check-base-2026-09-12.txt`

---

## Claim 1: "Entries are staged under their basename, so the payload layout (and link-claude-home.sh) is unchanged."

**Location:** `devcontainer-config/install.sh:46-47`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the staging of the seven current `CLAUDE_HOME_SRC` entries into `$STAGE` and the names `link-claude-home.sh` looks for at the payload root; does not establish that a *future* entry whose basename collides with another entry would stage safely (the loop would silently overwrite), and does not establish anything about the host-side symlink created by the README recipe (see Claim 8).

The staging loop now takes the basename of each entry:

```bash
# devcontainer-config/install.sh:50-58
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
STAGE="$SRC/claude-home"
rm -rf "$STAGE"
mkdir -p "$STAGE"
for item in "${CLAUDE_HOME_SRC[@]}"; do
  if [ -e "$REPO_ROOT/$item" ]; then
    cp -r "$REPO_ROOT/$item" "$STAGE/$(basename "$item")"
```

(excerpt ends :56; the enclosing `for` loop continues to :60 with the `else`/WARNING branch — read.)

Six of the seven entries are bare names, so `basename` is the identity function on them; only the first entry's path is collapsed. The consumer looks for exactly those seven names at the payload root:

```bash
# devcontainer-config/link-claude-home.sh:44
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
```

Executed simulation of the changed line against one file entry and one directory entry (the shape the `c56be81` message claims was simulated):

- Command: `for item in global-instructions/CLAUDE.md skills; do cp -r "$S/repo/$item" "$S/stage/$(basename "$item")"; done` then `ls -R "$S/stage"`
- cwd: `/tmp/claude-1000/-workspace/47023ae0-7b83-4d1e-a319-0b30f011dfea/scratchpad/sim`
- Exit code: 0 · Timestamp: 2026-09-12
- Result: `stage/CLAUDE.md`, `stage/skills/a.md`, `stage/skills/sub/b.md` — the file lands at the payload root under its basename and the directory entry keeps its subtree.

**Evidence:** `devcontainer-config/install.sh:41-60`, `devcontainer-config/link-claude-home.sh:44-62`, `devcontainer-config/Dockerfile:409`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 2: "at the root, a session working in THIS repo loads it twice — once as the linked ~/.claude copy and once as the project's own instructions (prompt audit 2026-09-11, F1)"

**Location:** `devcontainer-config/install.sh:43-45`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the double-load mechanism for a Claude Code session whose project root is this repo and whose `~/.claude/CLAUDE.md` resolves to the same content; does not establish the token figure (Claim 7), and does not establish behavior for tools other than Claude Code (`AGENTS.md`/`GEMINI.md` are separate files and are not affected).

The container path that produces the first copy is explicit:

```bash
# devcontainer-config/link-claude-home.sh:44-62 (excerpt: :44 and :50-52; the
# enclosing for loop continues to :62 — read)
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
...
  if [ -L "$target" ]; then
    ln -sfn "$SRC/$name" "$target"        # refresh (image may have moved)
```

so `~/.claude/CLAUDE.md` exists in every session. The second copy is the project-instructions load, which is a property of the harness rather than of any file in the repo (paraphrased — no quote available because the claim is about how the session's system context is assembled, not about a code path in this repo). It is directly observable in this very session: the assembled context for this run carries the instructions file twice, once labelled as the user's global `~/.claude/CLAUDE.md` and once as "`/workspace/CLAUDE.md` (project instructions, checked into the codebase)" — both copies still the pre-move text, because the linked payload predates the rebuild. `CLAUDE.md` no longer exists at the repo root after this change (`ls CLAUDE.md` → `No such file or directory`), so the second load is removed once the image is rebuilt.

**Evidence:** `devcontainer-config/link-claude-home.sh:44-62`, `devcontainer-config/install.sh:41-50`, `global-instructions/CLAUDE.md:1`

---

## Claim 3: "devcontainer-config/install.sh stages it to the payload root, so the installed layout is unchanged — only the source path moved."

**Location:** `scripts/health-check.sh:30-34`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the payload root's layout (`/opt/claude-workflows/CLAUDE.md` inside the image) and the `GLOBAL_MD` indirection in this script; does not establish that every bare `CLAUDE.md` string left in this file's own comments was updated (they were not — see the note below), and does not establish the state of an already-installed host config until `install.sh` is re-run.

The variable and its three consumer loops:

```bash
# scripts/health-check.sh:35
GLOBAL_MD="global-instructions/CLAUDE.md"
```

```bash
# scripts/health-check.sh:203, :235, :868 (one per loop)
    for mdfile in "$GLOBAL_MD" AGENTS.md GEMINI.md; do
```

and the two associative-array lookups that key off it, `${h2_set[$GLOBAL_MD]+x}` at `:944` and `${skill_set[$GLOBAL_MD]+x}` at `:965`. Executed confirmation that the indirection resolves: the run at HEAD reports `global-instructions/CLAUDE.md: 283 lines, 8 H2 + 15 H3 sections, 17 skill ref(s)` rather than skipping the file (`docs/reviews/execution-logs/r2-health-check-head-2026-09-12.txt`).

Residual, not part of the claim: seven comment lines in this script still say `CLAUDE.md` where they mean the global instructions file (`:13`, `:14`, `:25`, `:187`, `:192`, `:843-844`, `:922-925`, `:963`). They are documentation only and do not affect behaviour.

**Evidence:** `scripts/health-check.sh:29-35`, `scripts/health-check.sh:200-205`, `scripts/health-check.sh:232-237`, `scripts/health-check.sh:865-870`, `scripts/health-check.sh:944-978`, `docs/reviews/execution-logs/r2-health-check-head-2026-09-12.txt`

---

## Claim 4a: "Pinned on purpose: changing the judge breaks score comparability with earlier runs."

**Location:** `scripts/cross-model-review.py:372-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the rationale's internal consistency with the harness's own stated comparability discipline; does not establish the magnitude of any score shift between judges, and does not establish that any existing run artifact records which judge produced it.

The file already treats prompt/judge identity as the comparability axis, in the same voice:

```python
# scripts/cross-model-review.py:35-38
    only as a deliberate recall probe or for comparability with pre-021
    measurements (live diff-only runs print a warning to stderr). Files larger
```

and

```python
# scripts/cross-model-review.py:37-38 (continuation)
    Without --context-base the prompt is byte-identical to the pre-021 harness, so
    historical numbers stay comparable.
```

The comment is consistent with that discipline: stage-2 matching is performed by the judge model, so a judge swap changes the matching function that produces the overlap scores.

**Evidence:** `scripts/cross-model-review.py:11-38`, `scripts/cross-model-review.py:369-378`

---

## Claim 4b: The judge default `anthropic/claude-sonnet-5` is a real OpenRouter model id.

**Location:** `scripts/cross-model-review.py:374`
**Type:** Configuration / Reference
**Verdict:** Unverifiable
**Confidence:** High (in the blocker)
**Verification mode:** static
**Scope:** Covers only whether the slug can be checked from this sandbox and whether it is *shaped* like the harness's other ids; does not establish that OpenRouter serves a model under this name, and does not establish that the previous pin `anthropic/claude-sonnet-4.5` was itself still live.

```python
# scripts/cross-model-review.py:374
    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

Blocker: verifying an OpenRouter slug requires reaching `openrouter.ai`, and this sandbox has no egress. The commit message and the audit's F10 row both state the same limitation, so the claim is honestly labelled at both sites.

On shape, the slug is consistent with the harness's own conventions: the docstring example uses the same `anthropic/claude-<tier>-<version>` form (`--models anthropic/claude-opus-4.5 openai/gpt-5.2 google/gemini-3-pro`, `scripts/cross-model-review.py:69`), and the sibling sweep script pins bare-major ids of the same generation (`MODELS = ["moonshotai/kimi-k3", "openai/gpt-5.6-sol", "google/gemini-3.1-pro-preview"]`, `scripts/dd-cross-model-sweep.py:30`). Shape consistency is not existence.

**Evidence:** `scripts/cross-model-review.py:69`, `scripts/cross-model-review.py:374`, `scripts/dd-cross-model-sweep.py:30`

---

## Claim 5: "It sits in its own directory rather than the repo root so that a session working in *this* repo does not load it twice — once from `~/.claude` and once as the project's own instructions."

**Location:** `README.md:124`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same mechanism as Claim 2; covers the stated reason for the directory. Does not establish that the README's own host-setup recipe still works for a reader who already ran the old one (it does not — the pre-existing symlink dangles until re-run).

The setup recipe was updated in step with the move:

```bash
# README.md:14
ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md
```

and the contents index and contribution step both point at the new path (`README.md:124`, `README.md:168`).

**Evidence:** `README.md:11-20`, `README.md:121-126`, `README.md:165-170`

---

## Claim 6: "`devcontainer-config/install.sh` stages payload entries under their basename, so the image payload and `link-claude-home.sh` are unchanged — `~/.claude/CLAUDE.md` still resolves to the same content."

**Location:** `docs/decisions/log.md:68` (row 47)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the in-container `~/.claude/CLAUDE.md` symlink target and the payload names; "the same content" means the same *file*, not byte-identical text — commit `4d41add` also deleted four lines from that file (F6), so the installed bytes do change, for an unrelated reason. Does not establish the host-native `~/.claude/CLAUDE.md` case (Claim 8).

Same evidence as Claim 1: `install.sh:56` stages by basename, `link-claude-home.sh:44` looks for `CLAUDE.md` at the payload root, and the Dockerfile copies the stage wholesale:

```dockerfile
# devcontainer-config/Dockerfile:409
COPY claude-home/ /opt/claude-workflows/
```

Executed simulation as recorded under Claim 1 (exit 0, 2026-09-12).

**Evidence:** `devcontainer-config/install.sh:50-60`, `devcontainer-config/link-claude-home.sh:44-62`, `devcontainer-config/Dockerfile:400-429`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 7: "about 8K tokens of byte-identical duplication per request"

**Location:** `docs/decisions/log.md:68` (row 47); same figure in `c56be81`'s message
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude of the second copy's size under standard byte-per-token heuristics; does not establish an exact tokenizer count (no tokenizer is available offline here), and does not establish the per-request cost after prompt caching.

- Command: `wc -c -w -l *.md`
- cwd: `/workspace/global-instructions`
- Exit code: 0 · Timestamp: 2026-09-12
- Output: `283  4433 30343 CLAUDE.md` (283 lines, 4,433 words, 30,343 bytes)

30,343 bytes at the usual ~4 bytes/token heuristic is ≈ 7,600 tokens; 4,433 words at ~1.3 tokens/word is ≈ 5,800–7,700. "About 8K" is the right order and is stated as an approximation. Note the figure is stated for the file's pre-change size; `4d41add` removed four lines from it in the same PR, which moves the number by well under the stated precision.

**Evidence:** `global-instructions/CLAUDE.md` (283 lines), `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 8: "Takes effect for existing containers at the next `install.sh` + rebuild; a session started before that still sees both copies."

**Location:** `docs/decisions/log.md:68` (row 47); same sentence in `c56be81`'s message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cc-isolated container path, where the claim is exactly right; does *not* cover the host-native installation the README documents, where the effect is immediate and is a breakage rather than a deferred improvement. Does not establish how many such host installs exist.

For containers the claim holds: the payload is baked at image build time and only re-linked at container start —

```bash
# devcontainer-config/link-claude-home.sh:39-40
SRC="${CC_WORKFLOWS_DIR:-/opt/claude-workflows}"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
```

— so nothing changes until `install.sh` restages and the image is rebuilt.

The unstated half: the README's host recipe creates `~/.claude/CLAUDE.md` as a symlink into the repo working tree, where a `git pull` of this change takes effect immediately:

```bash
# README.md:14 (post-change form)
ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md
```

A host that ran the *old* recipe has `~/.claude/CLAUDE.md -> ~/claude-workflows/CLAUDE.md`, and that target no longer exists (`ls CLAUDE.md` → `No such file or directory`). On such a host the global instructions silently vanish at pull time rather than at rebuild time, and the fix is to re-run the `ln -s`. Neither the decision row nor the commit message says so. The precise version would add: "on a host-native install the old symlink dangles at pull time and must be recreated."

**Evidence:** `README.md:11-20`, `README.md:118-122`, `devcontainer-config/link-claude-home.sh:39-62`, `docs/decisions/log.md:68`

---

## Claim 9: "F2 — `Task tool` → `Agent tool` | **applied** (`skills/draft-review/SKILL.md`)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:560`
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the single occurrence the audit's F2 entry cited, in `skills/draft-review/SKILL.md`; does not establish that no other file in the repo says "Task tool" (two do — see Claim 10).

The line the audit quoted as F2's evidence is gone and replaced:

```markdown
# skills/draft-review/SKILL.md:190
Dispatch each critique to a sub-agent via the Agent tool.
```

A repo-wide grep for `Task tool` across `*.md`/`*.sh`/`*.py`/`*.bats`, excluding `archive/`, `external/`, `runs/`, `node_modules/` and `docs/`, returns zero hits under `skills/`.

**Evidence:** `skills/draft-review/SKILL.md:187-191`, `docs/reviews/prompt-audit-2026-09-11.md:78-81`

---

## Claim 10: "This also kills the last surviving \"Task tool\" reference, a regression against skill-format-audit Finding 7."

**Location:** commit `4d41add` message, paragraph 1
**Type:** Architectural / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers occurrences of the literal string "Task tool" in live (non-`docs/`, non-`archive/`) prompt surface; does not establish anything about `Task`-as-a-word used in other senses (e.g. asyncio `Task` in review artifacts).

Two live occurrences survive outside `skills/`:

```markdown
# patterns/orchestrated-review.md:31
**Terminology note**: Use "sub-agent" consistently for the parallel execution mechanism, regardless of whether the underlying implementation uses the Task tool, Agent tool, or manual sequential processing.
```

```markdown
# guides/skill-format-audit.md:156
## Finding 7: draft-review.md References `Task` Tool Instead of `Agent` Tool
```

Both are defensible — the first deliberately names both spellings, the second is the audit record that raised Finding 7 — but neither is `docs/`, so "the last surviving reference" is true only under the narrower reading the audit itself used: the last occurrence *in a skill*. The audit's own F2 entry states that narrower scope correctly ("now the only surviving occurrence in the skill", `docs/reviews/prompt-audit-2026-09-11.md:80`); the commit message drops the qualifier. Precise version: "the last surviving `Task tool` reference in a skill."

**Evidence:** `patterns/orchestrated-review.md:31`, `guides/skill-format-audit.md:148-167`, `docs/reviews/prompt-audit-2026-09-11.md:80`

---

## Claim 11: "F3 ... **applied** (draft-review, code-review, matrix-analysis; the restatements at the Stage-2 headers are now one plain sentence)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:561`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named skills' "Mandatory Execution Rules" blocks and their Stage-2 header restatements; does not establish that no other skill in the repo carries a similar pressure block (F3's scope was these three).

All three headings changed from `## Mandatory Execution Rules` to `## Execution rules`, and the numbered MUST/absolute list is replaced by contract prose that carries the reason. In `skills/matrix-analysis/SKILL.md`:

```markdown
# skills/matrix-analysis/SKILL.md:34-36
Dispatch every evaluation to a sub-agent via the Agent tool. Scoring items yourself defeats
the point of the matrix: the comparison is only worth reading if each cell came from an
independent pass.
```

The Stage-2 restatements are single sentences: `skills/draft-review/SKILL.md:190` (quoted under Claim 9), and in `skills/code-review/SKILL.md` the diff removes `**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the Agent tool.** This is non-negotiable.` (paraphrased — no quote available because the line is a deletion and no longer exists in the post-change file; it is visible as `-` in `git diff -M -C 2d679ce..HEAD -- skills/code-review/SKILL.md`).

**Evidence:** `skills/draft-review/SKILL.md:49-61`, `skills/matrix-analysis/SKILL.md:34-46`, `skills/code-review/SKILL.md` (diff hunk at the former `## Mandatory Execution Rules`)

---

## Claim 12: "F4 ... inheriting sites updated (`guides/sub-agent-briefing.md` including the worked example at :29 and the \"word cap\" rationale at :36, the `guides/README.md` index line, `workflows/task-decomposition.md`, `guides/task-decomposition-examples.md`, `skills/matrix-analysis/SKILL.md`)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:562`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers completeness of the named site list against a repo-wide search for the retired numeric cap, excluding `archive/`, `external/`, `runs/`, `node_modules/` and `docs/`; does not establish that the replacement wording is *effective*, and does not cover other word caps in the repo that F4 never targeted (`skills/fact-check/SKILL.md`'s ≤25-word citation span is an evidence-span rule, not a sub-agent output cap, and correctly went untouched).

The convention itself was rewritten:

```markdown
# patterns/orchestrated-review.md:131-135
#### Default output shape

Every dispatched sub-agent should be told what shape its output takes. The default convention:

> `Lead with conclusions; prose only where the structured output can't carry the point.`
```

A repo-wide grep for `300 words|<300|word cap|word limit|under [0-9]+ words|[0-9]+-word` over `*.md`/`*.sh`/`*.py`/`*.bats`, excluding the directories above, returns no live site still carrying the retired cap — every remaining hit is inside `docs/` (the audit doc quoting the removed text) or is the unrelated fact-check citation-span rule. The two line references check out against the pre-change file: `guides/sub-agent-briefing.md:29` was the worked example's `> **Output:** ... Total length under 300 words.` and `:36` was `- Word cap forces the sub-agent to summarize, not paste code.` (paraphrased — no quote available because both are pre-change lines that no longer exist; they appear as `-` lines in the diff hunks `@@ -26,14 +26,14 @@`).

The cross-reference in `workflows/task-decomposition.md` was retargeted to the renamed anchor and resolves (see Claim 19).

**Evidence:** `patterns/orchestrated-review.md:128-143`, `guides/sub-agent-briefing.md:14`, `guides/sub-agent-briefing.md:29`, `guides/sub-agent-briefing.md:36`, `guides/README.md:51`, `workflows/task-decomposition.md:113`, `workflows/task-decomposition.md:121`, `guides/task-decomposition-examples.md:32-38`, `skills/matrix-analysis/SKILL.md:220-224`

---

## Claim 13: "F6 ... **partially applied** — the two paragraphs restating decision-tree row 2 are cut from the always-loaded instructions file. The hook cross-reference paragraph stays until F5 is decided."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:563`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers exactly which paragraphs were removed from and retained in `global-instructions/CLAUDE.md`; does not establish that the removal has the intended effect on routing behaviour (behavioral, requires model calls).

The rename hunk removes exactly two paragraphs and nothing else (`similarity index 97%`, a single `@@ -47,10 +47,4 @@` hunk): the "When a single message bundles **2+ independent tasks**…" paragraph and the "**Recognize a batch.**…" paragraph (paraphrased — no quote available because both are deletions and no longer exist in the post-change file; they are the two `-` paragraphs in `git diff -M -C 2d679ce..HEAD -- 'global-instructions/*' 'CLAUDE*'`).

The hook cross-reference survives:

```markdown
# global-instructions/CLAUDE.md:59
A `UserPromptSubmit` hook (`hooks/batch-feedback-routing-reminder.sh`) escalates this row from skimmable prose to a harness-injected, non-blocking reminder when it detects multi-item phrasing — the same escalation pattern as the divergent-design routing reminder.
```

**Evidence:** `global-instructions/CLAUDE.md:45-60`, `docs/reviews/prompt-audit-2026-09-11.md:563`

---

## Claim 14: "F9 — \"The research must be thorough\" | **applied**"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:564`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers removal of the exact sentence from `workflows/research-plan-implement.md` and its absence elsewhere outside `docs/`; does not establish that the remaining two sentences carry the same instruction weight.

The surviving text drops the exhortation and keeps the two operative sentences:

```markdown
# workflows/research-plan-implement.md:82
Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.
```

A repo-wide grep for `must be thorough` over `*.md`, excluding `archive/`, `external/`, `runs/` and `docs/`, returns zero hits.

**Evidence:** `workflows/research-plan-implement.md:79-83`, `docs/reviews/prompt-audit-2026-09-11.md:143-148`

---

## Claim 15: "F10 — judge pin | **applied** — `anthropic/claude-sonnet-5`, with the comparability-break comment."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:565`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the default was changed and the comment added at the cited site; does not establish that the slug is live (Claim 4b) and does not establish that any other pinned id in the harness was re-baselined (none was — `scripts/cross-model-review.py:69`'s docstring example still names `anthropic/claude-opus-4.5`, which is an illustrative `--models` example, not a pin).

```python
# scripts/cross-model-review.py:372-374
    # Pinned on purpose: changing the judge breaks score comparability with earlier runs.
    # Re-baseline deliberately and note the cutover in the run log when you move it.
    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

The row also self-labels the egress limitation, which matches this sandbox's actual constraint.

**Evidence:** `scripts/cross-model-review.py:369-378`, `docs/reviews/prompt-audit-2026-09-11.md:565`

---

## Claim 16: "F1 ... **applied** ... `install.sh` now stages payload entries under their basename, so the image layout and `link-claude-home.sh` are unchanged; `health-check.sh` reads the path from `GLOBAL_MD`. Decision log row 47."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:566`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the four sub-assertions (move, basename staging, `GLOBAL_MD`, row 47 exists); inherits Claim 8's residue on the host-native symlink, which this row also omits.

Move: `git diff -M -C` reports `rename from CLAUDE.md` / `rename to global-instructions/CLAUDE.md`, similarity 97%. Basename staging: Claim 1 (executed). `GLOBAL_MD`: Claim 3. Row 47: `docs/decisions/log.md:68` exists and is the only line added to that file in this range.

**Evidence:** `docs/decisions/log.md:68`, `devcontainer-config/install.sh:50-60`, `scripts/health-check.sh:35`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 17: "`references/rubric.md` (515 lines ...), `references/chat-synthesis.md` (126), `references/override-log.md` (52). SKILL.md 1,909 → 1,256 lines"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`; same figures in `59ca38f`'s message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four line counts and the contents attributed to `rubric.md`; does not establish that the split reduced *loaded* tokens at runtime (that depends on whether the model follows the links — see Claim 29).

- Command: `wc -l skills/code-review/SKILL.md skills/code-review/references/*.md` and `git show 2d679ce:skills/code-review/SKILL.md | wc -l`
- cwd: `/workspace` · Exit code: 0 · Timestamp: 2026-09-12
- Output: `1256 SKILL.md`, `515 references/rubric.md`, `126 references/chat-synthesis.md`, `52 references/override-log.md`; baseline `1909`.

All four figures and the before/after pair are exact. The contents attributed to `rubric.md` are all present as headings in it: `## Deliverable 2: Code Review Rubric` (:5, the template), the tier sections `## 🔴 Must Fix` / `## 🟡 Must Address` / `## 🟢 Consider` (:36, :47, :58), `### Evidence grounding` (:151), `### Unified Severity Mapping` (:261), `### Escalation Rule` (:335), `### Soundness-Contradiction Channel` (:373), `### Executable-Defect Channel` (:443), `### Rubric Status Line` (:493).

**Evidence:** `skills/code-review/SKILL.md`, `skills/code-review/references/rubric.md:5-509`, `skills/code-review/references/chat-synthesis.md`, `skills/code-review/references/override-log.md`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 18: "All 85 tests across the code-review suites pass" / "All 85 tests pass."

**Location:** commit `59ca38f` message, paragraph 4; `docs/reviews/prompt-audit-2026-09-11.md:569`
**Type:** Configuration / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the *count* only. The "pass" half of the claim is true and independently verified below; what is refuted is the denominator 85, which corresponds to no grouping of these suites. Does not establish anything about the orchestrator evals in `test/skills/` that need model calls (the commit correctly says those were not run).

- Command: `bats test/skills/code-review-*.bats` and `bats --count` per file
- cwd: `/workspace` · Exit code: 0 · Timestamp: 2026-09-12
- Output: 97 `ok`, 0 `not ok`.

Per file: `code-review-assurance-contract.bats` 15, `code-review-context-delivery.bats` 10, `code-review-executable-defect.bats` 9, `code-review-factcheck-replication.bats` 17, `code-review-format-contract.bats` 18, `code-review-format.bats` 17, `code-review-soundness-crosscheck.bats` 11 — **97** total, confirmed independently by `grep -c '^@test'` over the same seven files. The four suites this commit modified total **53**. No subset of these seven files sums to 85 (dropping 12 from 97 is not achievable by any combination of file sizes). The counts are identical at the pre-change commit `2d679ce`, so the figure was not simply stale.

Matches the prior logged pattern class: *"a specific measured value quoted from a checked-in artifact set that does not contain it"* — the same shape as `"shortest real review in the corpus is over 3 KB"` (first seen 2026-08-19) and `total_golden 11 vs 13` (first seen 2026-08-18).

The precise version is either "all 97 tests across the code-review suites pass" or, if the intent was the modified suites only, "all 53 tests in the four modified suites pass."

**Evidence:** `test/skills/code-review-assurance-contract.bats`, `test/skills/code-review-context-delivery.bats`, `test/skills/code-review-executable-defect.bats`, `test/skills/code-review-factcheck-replication.bats`, `test/skills/code-review-format-contract.bats`, `test/skills/code-review-format.bats`, `test/skills/code-review-soundness-crosscheck.bats`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 19: "Every anchor that crossed the split was rewritten programmatically (none left unresolved), including workflows/pr-prep.md's link to the capture format."

**Location:** commit `59ca38f` message, paragraph 3; restated as "every crossing anchor rewritten" at `docs/reviews/prompt-audit-2026-09-11.md:569`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every intra-repo `](...#anchor)` link in `skills/code-review/SKILL.md`, the three `references/*.md`, and the external referrers `workflows/pr-prep.md`, `workflows/codebase-onboarding.md`, `patterns/orchestrated-review.md`, `README.md`, `AGENTS.md`, `GEMINI.md`, `global-instructions/CLAUDE.md`. Does not establish that the *link text* accompanying each anchor is still accurate (one is not — Claim 20), and does not check anchors inside `docs/`, `archive/`, `external/` or `runs/`.

- Command: a GitHub-slug anchor resolver (lowercase, strip punctuation, spaces→hyphens) over the eleven files above, resolving each relative target and asserting the slug exists as a heading in the target file
- cwd: `/workspace` · Exit code: 0 · Timestamp: 2026-09-12
- Output: `checked 54 bad 0` (a broader sweep over all of `skills/code-review`, `workflows/`, `patterns/`, `guides/` and the entry-point files returned the same: 0 unresolved).

The `pr-prep.md` link named in the message is among them:

```markdown
# workflows/pr-prep.md:183
[`skills/code-review/SKILL.md`](../skills/code-review/references/override-log.md#capture-format) — Date, PR
```

and `### Capture format` exists at `skills/code-review/references/override-log.md:9`. The `codebase-onboarding.md` referrer still points into `SKILL.md#between-stage-status-banner`, whose heading remained resident, and resolves.

**Evidence:** `workflows/pr-prep.md:183`, `workflows/codebase-onboarding.md:120`, `skills/code-review/references/override-log.md:9`, `skills/code-review/SKILL.md:86-91`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 20: The override-log capture format is in `skills/code-review/SKILL.md`.

**Location:** `workflows/pr-prep.md:183` (the link's display text)
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the visible link label only; the href beside it was correctly updated and resolves (Claim 19). Does not establish that any other link label in the repo drifted — the anchor sweep checked targets, not labels.

```markdown
# workflows/pr-prep.md:180-183
before the fix commit lands. Append to `docs/reviews/override-log.md` using the format in
[`skills/code-review/SKILL.md`](../skills/code-review/references/override-log.md#capture-format) — Date, PR
```

The label says `skills/code-review/SKILL.md`; that file no longer contains the capture format. `SKILL.md`'s own Override-Log section now defers:

```markdown
# skills/code-review/SKILL.md:1186-1188
capture format, the append procedure, and why the log is not write-only are in
**[references/override-log.md](references/override-log.md)**.
```

A reader who follows the label rather than clicking (the common case when this workflow text is pasted into a sub-agent prompt, which strips nothing but is read linearly) is sent to the wrong file. The label should read `skills/code-review/references/override-log.md`.

**Evidence:** `workflows/pr-prep.md:178-185`, `skills/code-review/SKILL.md:1182-1189`, `skills/code-review/references/override-log.md:5-22`

---

## Claim 21a: "Still over the 500-line ceiling."

**Location:** commit `59ca38f` message, paragraph 5; `docs/reviews/prompt-audit-2026-09-11.md:569`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a 500-line file guideline exists in this repo and that `SKILL.md` exceeds it; does not establish that the guideline was ever intended to bind skill files specifically (it is stated for implementation files in the RPI workflow).

The ceiling is stated as repo policy:

```markdown
# workflows/research-plan-implement.md:439
**File size discipline**: Keep individual files under **500 lines**. If an implementation step would push a file past this threshold, split it before continuing.
```

`wc -l skills/code-review/SKILL.md` → 1256 (exit 0, 2026-09-12), so the skill is 2.5× the ceiling even after the split.

**Evidence:** `workflows/research-plan-implement.md:439`, `workflows/research-plan-implement.md:451`, `skills/code-review/SKILL.md`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 21b: "The next candidates are Stage 1's dispatch template (~240 lines) and Stage 3's synthesis procedure (~160), both currently pipeline-resident."

**Location:** commit `59ca38f` message, paragraph 5; abbreviated at `docs/reviews/prompt-audit-2026-09-11.md:569`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the two named spans can be measured against the current file. The Stage 3 figure checks out exactly; the Stage 1 figure names a unit the file does not delimit, so it cannot be confirmed or refuted without knowing which span the author meant. Does not establish whether either span is a good extraction candidate — that is a design judgment, out of scope.

Stage 3 measures as claimed: the section runs from `### Stage 3: Synthesize and Produce Outputs` at `skills/code-review/SKILL.md:973` to the next `##`-level heading, `## Deliverable 1: Chat Synthesis` at `:1132` — 159 lines, matching "~160".

Stage 1 has no sub-unit named "dispatch template". `### Stage 1: Code Fact-Check (k=3 replicated)` spans `:382` to `### Stage 1.5: Critic gating` at `:684` — 302 lines. Its only internal heading is `#### Merging replicate verdicts (most-severe-wins)` at `:500`, so the pre-merge dispatch prose is 118 lines. There are no fenced blocks anywhere in `:382-683` (`grep -n '^```'` over the file returns only `:100`, `:102`, `:901`, `:908`, `:1157`, `:1174`). Neither 118 nor 302 is "~240", and no other heading-delimited span in the section measures 240 lines. What would be needed: the author naming the line range they measured.

**Evidence:** `skills/code-review/SKILL.md:382`, `skills/code-review/SKILL.md:500`, `skills/code-review/SKILL.md:684`, `skills/code-review/SKILL.md:973`, `skills/code-review/SKILL.md:1132`

---

## Claim 22: "health-check failures are identical to the pre-change baseline (four, all pre-existing)"

**Location:** commit `c56be81` message, "Verified:" paragraph; restated as "health-check failures are unchanged from baseline" in commit `59ca38f`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set and count of `fail` lines emitted by `scripts/health-check.sh` at HEAD versus `2d679ce`. The "identical to the pre-change baseline / all pre-existing" half is confirmed; the count "four" is refuted — there are six. Does not establish that the four shellcheck failures are harmless, and does not cover the script's `warn` lines (2 divergence signals at HEAD, also pre-existing).

- Command: `bash scripts/health-check.sh` at HEAD (`/workspace`) and at `2d679ce` (a worktree), exit 1 in both cases
- Timestamps: 2026-09-12 · Outputs captured to `docs/reviews/execution-logs/r2-health-check-head-2026-09-12.txt` and `…-base-2026-09-12.txt`

HEAD emits **six** `✗` lines, not four:

```
  ✗ In global-instructions/CLAUDE.md but not AGENTS.md: parallel-worktrees.md
  ✗ In global-instructions/CLAUDE.md but not GEMINI.md: parallel-worktrees.md
  ✗ .apir5-probe2.sh
  ✗ test/auto-approve-allowed-commands.bats
  ✗ test/init-firewall-rules.bats
  ✗ test/cc-isolated-functions.bats
```

The last four are the shellcheck section — presumably the "four" the message counted. The first two come from `check_md_consistency`, which calls `fail`, not `warn`:

```bash
# scripts/health-check.sh:265-270
            if [[ -n "$only_in_ref" ]]; then
                fail "In ${files[0]} but not $mdfile: $only_in_ref"
            fi
```

All six are pre-existing: the baseline run reproduces every one (with `CLAUDE.md` in place of `global-instructions/CLAUDE.md` in the first two labels). The baseline run also showed a seventh, `✗ BATS tests failed` from `test/hooks/log-usage.bats:1`; that is a **worktree artifact, not a baseline difference** — executed control: the same test also fails in a detached worktree checked out at HEAD (`bats test/hooks/log-usage.bats` in `$scratchpad/headwt` → `not ok 1 skill invocation is logged with all fields`) while passing in `/workspace` at HEAD. So the in-place failure sets are genuinely identical.

Precise version: "health-check failures are identical to the pre-change baseline (six, all pre-existing — four shellcheck, two MD-consistency)."

**Evidence:** `scripts/health-check.sh:262-272`, `docs/reviews/execution-logs/r2-health-check-head-2026-09-12.txt`, `docs/reviews/execution-logs/r2-health-check-base-2026-09-12.txt`

---

## Claim 23: "agents-gemini-sync, cross-reference-integrity, guide-index-sync and link-claude-home-wiring all pass"

**Location:** commit `c56be81` message, "Verified:" paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named bats suites at HEAD; does not establish that these four are the *right* suites to have run for this change, and does not cover suites that need model calls.

- Command: `bats test/agents-gemini-sync.bats test/cross-reference-integrity.bats test/guide-index-sync.bats test/link-claude-home-wiring.bats`
- cwd: `/workspace` · Exit code: 0 · Timestamp: 2026-09-12
- Output: 13 `ok`, 0 `not ok`, including `ok 10 every command in wiring.json points at a hook that exists` and `ok 13 the deny rules the guard hook's HARD tier depends on are wired`.

**Evidence:** `test/agents-gemini-sync.bats`, `test/cross-reference-integrity.bats`, `test/guide-index-sync.bats`, `test/link-claude-home-wiring.bats`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 24: "the basename staging was simulated against a file entry and a directory entry"

**Location:** commit `c56be81` message, "Verified:" paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the described simulation, when re-run now, produces the layout the change depends on. It does not and cannot establish that the author actually ran it at the time — that is a claim about an unrecorded past action, and no captured output exists in the repo. Confidence is Medium for that reason, not because the behaviour is in doubt.

Re-derived in full under Claim 1: a file entry (`global-instructions/CLAUDE.md`) stages to `stage/CLAUDE.md` and a directory entry (`skills/`, containing a nested subdirectory) stages to `stage/skills/` with its subtree intact. Exit 0, 2026-09-12.

**Evidence:** `devcontainer-config/install.sh:54-60`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 25: "install.sh is not in enforcement_files(), so no Live-verified trailer is required."

**Location:** commit `c56be81` message, `Notes:` line
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both halves — `install.sh` is absent from `enforcement_files()`, and the commit-blocking hook's pattern does not match it. Does not establish that the change is *inconsequential* to the trust manifest: `install.sh` writes `claude-home/`, whose files `enforcement_files()` does hash, so this change alters the manifest at the next install even though the commit itself is ungated.

`enforcement_files()` enumerates six literal names plus three globs, and `install.sh` is not among them:

```bash
# devcontainer-config/cc-isolated.sh:107-129
enforcement_files() {
  local cfg
  cfg="$(config_dir)"
  echo "devcontainer.json"
  echo "Dockerfile"
  echo "init-firewall.sh"
  echo "cc-sni-proxy.py"
  echo "link-claude-home.sh"
  echo "cc-isolated.sh"
```

(excerpt ends :115; the enclosing function continues to :130 with the `egress/*.txt`, `projects/*.profile` and `claude-home` walks — read. None of the three adds `install.sh`; `install.sh` is also explicitly not installed, per `devcontainer-config/install.sh:24-25`.)

The gate hook keys on the same set, as a repo-path regex:

```bash
# hooks/live-verify-gate.sh:57
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|egress/)'
```

`devcontainer-config/install.sh` does not match, so the hook does not block, and no trailer is required.

**Evidence:** `devcontainer-config/cc-isolated.sh:107-130`, `devcontainer-config/install.sh:22-25`, `hooks/live-verify-gate.sh:55-58`

---

## Claim 26: "The skill's content surface spans SKILL.md plus its references/ files ... Read in document order so section-extraction end anchors still follow their sections."

**Location:** `test/skills/code-review-assurance-contract.bats:27-30`; identical comment at `test/skills/code-review-executable-defect.bats:23-26`, `test/skills/code-review-format-contract.bats:29-32`, `test/skills/code-review-soundness-crosscheck.bats:27-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers (a) that the concatenation order matches the order in which the three stub sections appear in `SKILL.md`, and (b) that the section-extraction helpers still terminate on a following heading rather than running to EOF. Does not establish that the concatenation is the *complete* content surface a real run loads (a run also follows links into `patterns/orchestrated-review.md`, which none of these suites concatenates).

The concatenation is `SKILL.md`, then chat-synthesis, rubric, override-log:

```bash
# test/skills/code-review-assurance-contract.bats:31-34
  SKILL_CONTENT=$(cat "$SKILL" \
    "$SKILL_DIR/references/chat-synthesis.md" \
    "$SKILL_DIR/references/rubric.md" \
    "$SKILL_DIR/references/override-log.md" | tr -d '\r')
```

(excerpt ends :34; the enclosing `setup()` closes at :35 in this file, and at :36 in `code-review-executable-defect.bats` where a `FLAT=` line follows — read.)

That is document order by the position of the corresponding stubs in `SKILL.md`: `## Deliverable 1: Chat Synthesis` at `:1132`, `## Deliverable 2: Code Review Rubric` at `:1142`, `## Override-Log` at `:1182`. (The `## Reference files` index at `:86-91` lists them in a different order — rubric, chat-synthesis, override-log — but that index is not what the extraction order has to track.)

Executed confirmation of the end-anchor property: the whole seven-suite run passes, including the test written for exactly this hazard — `ok 97 the section-extraction end anchor exists (no silent extract-to-EOF)` (exit 0, 2026-09-12).

**Evidence:** `test/skills/code-review-assurance-contract.bats:22-35`, `test/skills/code-review-executable-defect.bats:18-36`, `test/skills/code-review-format-contract.bats:25-36`, `test/skills/code-review-soundness-crosscheck.bats:22-35`, `skills/code-review/SKILL.md:1132`, `skills/code-review/SKILL.md:1142`, `skills/code-review/SKILL.md:1182`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 27: "The rubric template moved into the skill's references/ dir 2026-09-11 (prompt audit F8); the golden fixture is still compared against it."

**Location:** `test/skills/code-review-format-contract.bats:183-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `SKILL_MD` points at the file that now holds the template and that the golden-sync tests pass against it; does not establish that the golden fixture itself is still the right fixture for the current rubric semantics.

```bash
# test/skills/code-review-format-contract.bats:183-185
# The rubric template moved into the skill's references/ dir 2026-09-11
# (prompt audit F8); the golden fixture is still compared against it.
SKILL_MD="skills/code-review/references/rubric.md"
```

The template is indeed there — `## Deliverable 2: Code Review Rubric` at `skills/code-review/references/rubric.md:5`, with the fenced `# Code Review Rubric` template body opening at `:29-30`. The 18 tests in this suite pass (exit 0, 2026-09-12).

**Evidence:** `test/skills/code-review-format-contract.bats:178-190`, `skills/code-review/references/rubric.md:5-30`, `docs/reviews/execution-logs/r2-verification-commands-2026-09-12.txt`

---

## Claim 28: "Reference file for skills/code-review/SKILL.md. Extracted from the skill body 2026-09-11 (prompt audit F8) ... Edit here, not in the skill."

**Location:** `skills/code-review/references/rubric.md:1-3`; identical header at `references/chat-synthesis.md:1-3` and `references/override-log.md:1-3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the three files' bodies are the extracted originals rather than rewrites, and that no duplicate copy of the moved text remains in `SKILL.md` (so "edit here" is unambiguous). Does not establish that all three are actually *read* at their claimed stages at runtime.

Line-by-line comparison of each reference body (header comment stripped) against the corresponding section of `git show 2d679ce:skills/code-review/SKILL.md`:

- `rubric.md`: 502 body lines, **one** non-trivial difference — `[Deliverable 1](#deliverable-1-chat-synthesis)` became `[Deliverable 1](../SKILL.md#deliverable-1-chat-synthesis)`. Otherwise byte-identical.
- `chat-synthesis.md`: 122 body lines, **two** differences, both link-depth fixes — `../../patterns/orchestrated-review.md` → `../../../patterns/…`, and `[The single-sample label](#the-single-sample-label)` → `(rubric.md#the-single-sample-label)`.
- `override-log.md`: 48 body lines, **zero** content differences (trailing blank lines only).

All three rewritten links resolve (Claim 19). `SKILL.md` retains no copy of the moved bodies — its three stubs are 3–7 lines each and defer (`skills/code-review/SKILL.md:1134-1139`, `:1144-1150`, `:1184-1188`).

**Evidence:** `skills/code-review/references/rubric.md:1-3`, `skills/code-review/references/chat-synthesis.md:1-3`, `skills/code-review/references/override-log.md:1-3`, `skills/code-review/SKILL.md:1132-1189`

---

## Claim 29: "Required structure, the coverage-and-escalations block, the considered-overrides block, the single-sample label and the next-action line are specified in **references/chat-synthesis.md**."

**Location:** `skills/code-review/SKILL.md:1134-1136`; the commit-message bullet "references/chat-synthesis.md (126): chat deliverable structure, coverage and escalation blocks, single-sample label, next-action derivation" makes the same attribution
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the five items the stub attributes to `chat-synthesis.md`; four are defined there outright, the fifth (single-sample label) is *used* there but *defined* in `rubric.md`. Does not establish the accuracy of the `Deliverable 2` stub's attributions (those all check out — Claim 17).

Four of the five are headings or blocks in the file: `### Structure the chat synthesis as:` (:9), `### Considered overrides` (:13), `### Coverage and Escalations` (:26), `#### Next-action derivation` (:86).

The fifth is a cross-reference, not a specification:

```markdown
# skills/code-review/references/chat-synthesis.md:78-80
This is the same standing label the rubric status line carries (see
[The single-sample label](rubric.md#the-single-sample-label)) and it is the whole of the hedging —
```

The defining section `#### The single-sample label` lives at `skills/code-review/references/rubric.md:499`. `chat-synthesis.md` does fix the label's exact text and placement for the chat deliverable (`:77` gives the verbatim line and `:74-75` its position relative to `Recommended next action:`), so a reader following the stub is not sent to the wrong place — but the rationale and the canonical definition are one hop further. Precise version: "…and the placement of the single-sample label (defined in `references/rubric.md`)".

**Evidence:** `skills/code-review/SKILL.md:1132-1139`, `skills/code-review/references/chat-synthesis.md:5-90`, `skills/code-review/references/rubric.md:493-509`

---

## Claims Requiring Attention

### Incorrect
- **Claim 18** (commit `59ca38f` message; `docs/reviews/prompt-audit-2026-09-11.md:569`): "All 85 tests across the code-review suites pass" — the seven `test/skills/code-review-*.bats` suites contain **97** tests (all passing); the four suites this commit modified contain **53**. 85 matches no grouping, and the counts were identical before the change. Replace with 97 (or 53 if the modified suites were meant).

### Stale
- **Claim 20** (`workflows/pr-prep.md:183`): the link *label* still reads `` `skills/code-review/SKILL.md` `` while the href correctly points at `references/override-log.md#capture-format`. Update the label to `skills/code-review/references/override-log.md`.

### Mostly Accurate
- **Claim 8** (`docs/decisions/log.md:68`; commit `c56be81` message): "takes effect at the next install.sh + rebuild" is true for containers but silent on host-native installs, where the old `~/.claude/CLAUDE.md` symlink dangles at `git pull` time and must be recreated. Add that sentence.
- **Claim 10** (commit `4d41add` message): "the last surviving `Task tool` reference" — two live occurrences remain outside `skills/` (`patterns/orchestrated-review.md:31`, `guides/skill-format-audit.md:156`). The audit's own F2 row scopes it correctly ("in the skill"); the commit message dropped the qualifier.
- **Claim 22** (commit `c56be81` message; echoed in `59ca38f`): "(four, all pre-existing)" undercounts — `scripts/health-check.sh` emits **six** `fail` lines at HEAD (four shellcheck + two MD-consistency). "All pre-existing" and "identical to the baseline" are both confirmed; only the count is wrong.
- **Claim 29** (`skills/code-review/SKILL.md:1136`; commit `59ca38f` message): the single-sample label is *used* in `references/chat-synthesis.md` but *defined* in `references/rubric.md:499`.

### Unverifiable
- **Claim 4b** (`scripts/cross-model-review.py:374`): whether `anthropic/claude-sonnet-5` is a live OpenRouter slug cannot be checked — this sandbox has no egress. Both the commit message and audit row F10 already flag it. Needed: one `GET https://openrouter.ai/api/v1/models` from a networked host before the next cross-model run.
- **Claim 21b** (commit `59ca38f` message): "Stage 1's dispatch template (~240 lines)" names no unit the file delimits — Stage 1 is 302 lines (`:382-683`) and its pre-merge dispatch prose is 118 (`:382-499`). Stage 3's "~160" is exact (159). Needed: the line range the author measured.

---

## Goal-Alignment Note

**Answered.** All ten items in the shared brief were checked against the code that exercises them rather than the file the claim sits in: the install/link/Dockerfile chain for the basename change (1, 2, 3, 6, 16, 24), `enforcement_files()` *and* the gate hook regex for the trailer claim (25), a slug-resolving anchor sweep over the skill, its references and all external referrers for the split (19, 20), a re-derivation of the health-check baseline including a worktree control that isolated a false extra failure (22), an independent test-count audit that refutes the "85" figure (18), a repo-wide sweep confirming no live site still carries the retired word cap (12), and a line-by-line diff of every moved block against its pre-move original (28). Four claims were verified by execution with captured output; the rest are static reads of complete enclosing units.

**Out of scope.** Whether the split actually reduces loaded tokens at runtime, whether the reworded F3/F4/F6 prose changes model behaviour, and whether the orchestrator evals in `test/skills/` still pass — all need model calls, which the commit messages themselves correctly flag as unexercised. Design judgments (is `rubric.md` the right cut line? is 500 lines the right ceiling for a skill?) belong to the sibling critics, not here.

**Escalate.** One item, for the orchestrator: **Claim 18's "85"** appears in two places — a commit message (immutable) and `docs/reviews/prompt-audit-2026-09-11.md:569` (editable). The audit doc is the one a future pass will read as the record of what was verified, so the fix belongs there. The same paragraph's other figures (1,909 → 1,256; 515/126/52) are all exact, which makes the wrong one easy to trust by association — that is the specific risk worth surfacing. It is also the third instance in this project's log of a *specific measured value quoted as if read off a checked-in artifact set that does not contain it*; the pattern has now recurred across three unrelated review passes, which is a calibration signal about how measured counts get into commit prose here, not just a one-off typo.

**Questions I would have asked.** (1) Was the 85 read off a filtered `bats` run (e.g. a `--filter` or a partial file list) that is worth recording alongside the number? (2) Does any host-native install of this repo exist, or is cc-isolated the only deployment — that determines whether Claim 8's residue is a real breakage or a documentation-only gap.
