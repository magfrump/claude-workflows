Commit: 0661353

# Code Fact-Check Report

**Repository:** `/workspace` (claude-workflows)
**Scope:** `git diff -M -C 2d679ce..HEAD` (four commits: 4d41add, c56be81, 59ca38f, 0661353) plus the commit messages from `git log 2d679ce..HEAD`
**Checked:** 2026-09-12
**Total claims checked:** 27
**Summary:** 20 verified, 4 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking. Both
logged entries are of the class *"a specific measured value quoted from a checked-in artifact set
that does not contain it."* Claim 15a below **matches that pattern** and is flagged in its verdict
block.

Executed-claim provenance: `docs/reviews/execution-logs/r1-provenance-2026-09-12.txt` (commands,
cwd, exit codes, timestamps) with raw output in the sibling `r1-*.txt` files.

---

## Claim 1: "Entries are staged under their basename, so the payload layout (and link-claude-home.sh) is unchanged."

**Location:** `devcontainer-config/install.sh:45-46`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the staged payload's root-level entry names and their types for the current
`CLAUDE_HOME_SRC` list, and `link-claude-home.sh`'s `ENTRIES` lookup against them; does not
establish behavior if a future entry's basename collides with another entry's (e.g. adding
`a/hooks` alongside `hooks`, which would silently overwrite), nor anything about the
`$DEST/claude-home` install step or a live container.

The staging loop rewrites the destination to the basename:

```bash
# devcontainer-config/install.sh:51-57
for item in "${CLAUDE_HOME_SRC[@]}"; do
  if [ -e "$REPO_ROOT/$item" ]; then
    cp -r "$REPO_ROOT/$item" "$STAGE/$(basename "$item")"
  else
    echo "WARNING: $REPO_ROOT/$item not found — omitted from the image payload." >&2
  fi
done
```

(excerpt ends `:57`; the enclosing top-level script continues to `:127` — read; the next block
writes `$STAGE/.manifest` and the `PAYLOAD` install loop at `:103-106` copies `claude-home`
wholesale, neither of which reads the entry names.)

The consumer keys on those exact basenames:

```bash
# devcontainer-config/link-claude-home.sh:47
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
```

(excerpt ends `:47`; the enclosing loop continues to `:63` — read; it only does
`[ -e "$SRC/$name" ] || continue` then `ln -sfn`.)

Executed: running the real installer with a throwaway `CLAUDE_DEVC_CONFIG_DIR` and answering `n`
at the bless prompt (staging happens before the prompt) regenerated
`devcontainer-config/claude-home/` with exactly `CLAUDE.md` (a regular file, byte-identical to
`global-instructions/CLAUDE.md` per `diff -q`), plus `guides/ hooks/ patterns/ scripts/ skills/
workflows/` and `.manifest` — and **no** `global-instructions/` subdirectory (paraphrased — no
quote available because the claim is about the resulting directory layout, not a snippet; the
listing is in the provenance file, step 6).

**Evidence:** `devcontainer-config/install.sh:47-57`, `devcontainer-config/link-claude-home.sh:47-63`, `docs/reviews/execution-logs/r1-install-sim.txt`, `docs/reviews/execution-logs/r1-provenance-2026-09-12.txt`

---

## Claim 2: "at the root, a session working in THIS repo loads it twice — once as the linked `~/.claude` copy and once as the project's own instructions"

**Location:** `devcontainer-config/install.sh:42-45`; same assertion at `scripts/health-check.sh:29-32` and `README.md:124`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of two independent load paths for the same content inside this
repo (the image-baked `~/.claude` symlink and a repo-root project instructions file); does not
establish the token cost of that duplication (see Claim 4), and does not establish that any
*currently running* session stops double-loading — the commit itself states the change takes
effect only after the next `install.sh` + rebuild.

The `~/.claude` entry is a symlink into the baked payload:

```
lrwxrwxrwx  1 node node   31 Sep  9 16:59 CLAUDE.md -> /opt/claude-workflows/CLAUDE.md
```

(paraphrased — no quote available because this is an `ls -la /home/node/.claude` listing, not
file content; the payload is placed there by `devcontainer-config/Dockerfile:409`, `COPY
claude-home/ /opt/claude-workflows/`.)

The second load path is the repo root itself: before this change the same file was tracked at
`CLAUDE.md` in the repo root (`git show 2d679ce:CLAUDE.md` resolves; at HEAD `ls CLAUDE.md`
fails and `global-instructions/CLAUDE.md` exists). This session's own system prompt still
carries both copies verbatim — labelled `/home/node/.claude/CLAUDE.md` and `/workspace/CLAUDE.md`
— which is direct observation of the double load in the pre-change state (paraphrased — no quote
available because the observation is of this session's prompt assembly, not of a file in the
repo).

**Evidence:** `devcontainer-config/install.sh:42-47`, `devcontainer-config/Dockerfile:409`, `devcontainer-config/link-claude-home.sh:47`, `scripts/health-check.sh:29-35`

---

## Claim 3: "`~/.claude/CLAUDE.md` still resolves to the same content"

**Location:** `docs/decisions/log.md:68` (row 47)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers content identity between `global-instructions/CLAUDE.md` and the staged payload
root file that `~/.claude/CLAUDE.md` symlinks to after an install + rebuild; does not establish
that an *already-built* image's `/opt/claude-workflows/CLAUDE.md` matches the current repo file
(it does not — see Claim 4).

`diff -q global-instructions/CLAUDE.md devcontainer-config/claude-home/CLAUDE.md` after the
staging run reported no difference (paraphrased — no quote available because the evidence is a
`diff -q` exit status, not file content; captured in the provenance file, step 6).

**Evidence:** `docs/decisions/log.md:68`, `devcontainer-config/install.sh:51-57`, `docs/reviews/execution-logs/r1-provenance-2026-09-12.txt`

---

## Claim 4: "about 8K tokens of byte-identical duplication per request"

**Location:** `docs/decisions/log.md:68` (row 47); echoed as "~8K tokens of byte-identical duplication per request" in commit `c56be81`'s message
**Type:** Performance / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the size estimate for the duplicated file; does not establish the tokenizer used,
and the "byte-identical" qualifier holds only while the baked image is current with the repo.

The file is 30,343 bytes (`wc -c global-instructions/CLAUDE.md`), which at the 3.7–4.1
bytes/token typical of English markdown is ≈7.4–8.2K tokens — so "about 8K" is right
(paraphrased — no quote available because the evidence is a byte count, not a snippet).

The imprecision is in **"byte-identical"**. The two copies are the *baked* payload file and the
*working-tree* file, and they drift between installs: `/home/node/.claude/.claude-workflows-manifest`
stamps the image at a 2026-09-09 commit, while the repo-root copy was edited on 2026-09-11 by
commit `4d41add` (the F6 paragraph cut). The precise version is "byte-identical whenever the
installed image is current with the repo; otherwise two *near*-identical copies of one rule set."
The practical conclusion (duplicate load, ~8K tokens) is unaffected.

**Evidence:** `docs/decisions/log.md:68`, `global-instructions/CLAUDE.md` (byte count), `devcontainer-config/install.sh:58-64`

---

## Claim 5: "F2 — `Task tool` → `Agent tool` | **applied** (`skills/draft-review/SKILL.md`)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:560`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the prescriptive dispatch instruction the audit's F2 located at
`skills/draft-review/SKILL.md:197`; does not establish that the string "Task tool" is absent
repo-wide (it is not — see Claim 26).

The diff replaces the exact line F2 named:

```diff
-**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the Task tool.** This is non-negotiable.
+Dispatch each critique to a sub-agent via the Agent tool.
```

(from `git show 4d41add -- skills/draft-review/SKILL.md`, hunk at `@@ -194,7 +187,7 @@`.)

**Evidence:** `docs/reviews/prompt-audit-2026-09-11.md:73-82`, `skills/draft-review/SKILL.md:190`

---

## Claim 6: "F3 — 'Mandatory Execution Rules' pressure blocks | **applied** (draft-review, code-review, matrix-analysis; the restatements at the Stage-2 headers are now one plain sentence)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:561`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three files F3's Location cell named and both Stage-2 restatement sites;
does not establish that no "Mandatory Execution Rules" heading survives elsewhere in the repo —
`skills/ui-visual-review/SKILL.md:58` still carries one, and it was **not** in F3's location list,
so it is out of this row's reach rather than a miss by it.

All three headings are now `## Execution rules` with the absolutism removed:

```diff
-## Mandatory Execution Rules
-These rules are absolute. Do not deviate from them under any circumstances.
+## Execution rules
+Dispatch every fact-check and critique to a sub-agent via the Agent tool. …
```

(from `git show 4d41add`, identical shape in `skills/code-review/SKILL.md`,
`skills/draft-review/SKILL.md` and `skills/matrix-analysis/SKILL.md`.)

A repo-wide grep for `Mandatory Execution Rules` outside `archive/ external/ runs/ docs/
node_modules/ devcontainer-config/claude-home/` returns exactly one hit,
`skills/ui-visual-review/SKILL.md:58` (paraphrased — no quote available because the claim covers
the *absence* of matches elsewhere).

**Evidence:** `skills/code-review/SKILL.md:59-79`, `skills/draft-review/SKILL.md:49-62`, `skills/matrix-analysis/SKILL.md:34-46`, `docs/reviews/prompt-audit-2026-09-11.md:83-92`

---

## Claim 7: "F4 — `<300 words` output cap | **applied** — convention rewritten … inheriting sites updated (`guides/sub-agent-briefing.md` …, the `guides/README.md` index line, `workflows/task-decomposition.md`, `guides/task-decomposition-examples.md`, `skills/matrix-analysis/SKILL.md`)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:562`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every site in F4's own Location cell plus the `guides/README.md` index line the
row adds, and the absence of any surviving numeric *prose* cap at those sites; does not establish
that no numeric word budget exists anywhere in the repo —
`skills/ai-personas-critique/SKILL.md:160` and `:218` still say persona critiques "should be
100-200 words", and that file was not in F4's location list (its personas are in-agent passes, not
orchestrated-review dispatches), so it is outside this row's claim rather than a miss by it.

The convention site now reads:

```markdown
# patterns/orchestrated-review.md:131-135
#### Default output shape

Every dispatched sub-agent should be told what shape its output takes. The default convention:

> `Lead with conclusions; prose only where the structured output can't carry the point.`
```

(excerpt ends `:135`; the enclosing `#### Default output shape` section continues to `:143` —
read; `:143` ends "a word count is not, and clamping prose length on a hard question buys
scannability by starving the analysis.")

Each named inheriting site was rewritten in the same commit — `guides/sub-agent-briefing.md`
element 4, worked example, anti-pattern 3 and checklist; `guides/README.md`'s index line
("output cap" → "output shape"); `workflows/task-decomposition.md:113` and `:121`;
`guides/task-decomposition-examples.md:32/35/38`; `skills/matrix-analysis/SKILL.md:220-224`
(verified line-by-line in `git diff -M 2d679ce..HEAD` for those files).

A repo-wide grep for `300 words`, `word cap`, `output cap`, `<300`, `word limit`, `no more than
[0-9]+`, `at most [0-9]+ (words|lines|sentences)` outside the excluded trees returns no numeric
prose cap at any F4 site (paraphrased — no quote available because the claim covers absence of
matches).

**Evidence:** `patterns/orchestrated-review.md:131-143`, `guides/sub-agent-briefing.md:14/29/36/62-69/96`, `guides/README.md:51`, `workflows/task-decomposition.md:113,121`, `guides/task-decomposition-examples.md:32,35,38`, `skills/matrix-analysis/SKILL.md:220-224`

---

## Claim 8: "F6 … **partially applied** — the two paragraphs restating decision-tree row 2 are cut from the always-loaded instructions file. The hook cross-reference paragraph stays."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:563`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and identity of the cut paragraphs and the survival of the hook
cross-reference; does not establish the row's forward-looking clause about the row-3 trim, which
is a plan rather than a checkable claim.

The commit removes exactly two paragraphs:

```diff
-When a single message bundles **2+ independent tasks** — the common case being a batch of end-user feedback — the default failure is to grind through them sequentially in the main agent. Don't. Fan out.
-
-**Recognize a batch.** Any of these is enough: …
```

(from `git show 4d41add -- CLAUDE.md`, hunk `@@ -47,10 +47,6 @@`; four deleted lines = two
paragraphs plus their blank separators, and the file's total change is `4 -` / `0 +`.)

Both strings return `0` from `grep -c` against `global-instructions/CLAUDE.md` at HEAD, and the
hook cross-reference survives at `global-instructions/CLAUDE.md:59`.

**Evidence:** `global-instructions/CLAUDE.md:55-59`, `git show 4d41add -- CLAUDE.md`

---

## Claim 9: "F9 — 'The research must be thorough' | **applied**"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:564`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the single sentence at the site F9 named (`workflows/research-plan-implement.md:82`)
and the retention of the two sentences after it; does not establish that similar exhortations are
absent elsewhere in the workflow corpus.

```diff
-The research must be thorough. Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.
+Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.
```

**Evidence:** `workflows/research-plan-implement.md:82`, `docs/reviews/prompt-audit-2026-09-11.md:143-152`

---

## Claim 10: "F5 — remove the routing-reminder hooks | **declined 2026-09-11.** The 2026-06-23 override-log decision to keep the batch hook's broad firing stands"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:567`; also commit `0661353`'s subject
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of the cited 2026-06-23 override-log row and the
survival of both reminder hooks; does not establish that the override's stated cost figure
(~85 tok/firing) is still accurate.

The row exists and says what the status table says it says:

```
| 2026-06-23 | `feat/batch-feedback-subagent-routing` (#35) | Hook fires on every UserPromptSubmit incl. agent/tool notifications (`hooks/batch-feedback-routing-reminder.sh`, whole script) — security-reviewer Low + orchestrator observation (C1) | 🟢 Consider | Won't-Fix (intended) | Reminder targets the model not the human (no alert-fatigue); non-human submits are valid fan-out points; cost ~85 tok/firing. Broad firing preferred. |
```

(`docs/reviews/override-log.md:63`.) Both `hooks/batch-feedback-routing-reminder.sh` and
`hooks/dd-routing-reminder.sh` are present at HEAD and unchanged by this range.

**Evidence:** `docs/reviews/override-log.md:63`, `hooks/batch-feedback-routing-reminder.sh`, `hooks/dd-routing-reminder.sh`

---

## Claim 11: "`references/rubric.md` (515 lines …), `references/chat-synthesis.md` (126), `references/override-log.md` (52). SKILL.md 1,909 → 1,256 lines"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`; same four numbers in commit `59ca38f`'s message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four line counts as of HEAD (and 1,909 as of `2d679ce`); does not establish
the parenthetical content inventory in the same cell — that is verdicted separately at Claim 14.

`wc -l` at HEAD reports `1256 skills/code-review/SKILL.md`, `126
skills/code-review/references/chat-synthesis.md`, `52
skills/code-review/references/override-log.md`, `515
skills/code-review/references/rubric.md`; `git show 2d679ce:skills/code-review/SKILL.md | wc -l`
reports `1909`. All five numbers match exactly (paraphrased — no quote available because the
evidence is line counts, not file content).

**Evidence:** `skills/code-review/SKILL.md`, `skills/code-review/references/rubric.md`, `skills/code-review/references/chat-synthesis.md`, `skills/code-review/references/override-log.md`

---

## Claim 12: "Still over the 500-line ceiling: the next candidates are Stage 1's dispatch template (~240 lines) and Stage 3's synthesis procedure (~160), both currently pipeline-resident."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`; same in commit `59ca38f`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the two size estimates against the enclosing `### Stage 1` / `### Stage 3`
section spans and the fact that 1,256 > 500; does not establish that the *dispatch template*
specifically (a sub-part of Stage 1) is 240 lines rather than the whole Stage-1 section, nor that
extracting them would be safe.

`### Stage 1: Code Fact-Check (k=3 replicated)` spans `:382-623` (242 lines) and `### Stage 3:
Synthesize and Produce Outputs` spans `:973-1131` (159 lines) — matching "~240" and "~160"
(paraphrased — no quote available because the evidence is the heading-offset table from
`grep -n '^## \|^### ' skills/code-review/SKILL.md`, not a snippet). Medium confidence only
because the claim names sub-parts of those sections, and the sub-part boundaries are not marked
by headings.

**Evidence:** `skills/code-review/SKILL.md:382-623`, `skills/code-review/SKILL.md:973-1131`

---

## Claim 13: "Four contract suites now read the skill's full surface (SKILL.md + references in document order); the golden-fixture sync test reads `references/rubric.md`."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`; same in commit `59ca38f`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suites' `SKILL_CONTENT` construction, the concatenation order versus
the stub order in SKILL.md, and the golden-fixture test's `SKILL_MD` retarget; does not establish
that every assertion over `SKILL_CONTENT` is still as *tight* as before the split — one is not
(Claim 22).

All four suites build the same concatenation:

```bash
# test/skills/code-review-assurance-contract.bats:31-35
  SKILL_CONTENT=$(cat "$SKILL" \
    "$SKILL_DIR/references/chat-synthesis.md" \
    "$SKILL_DIR/references/rubric.md" \
    "$SKILL_DIR/references/override-log.md" | tr -d '\r')
```

(excerpt ends `:35`; the enclosing `setup()` continues to `:36` — read; `:36` is the closing `}`.
Byte-identical blocks appear at `code-review-executable-defect.bats:26-30`,
`code-review-format-contract.bats:30-34` and `code-review-soundness-crosscheck.bats:26-30`.)

That order matches SKILL.md's own stub order — `## Deliverable 1: Chat Synthesis` (`:1132`),
`## Deliverable 2: Code Review Rubric` (`:1142`), `## Override-Log` (`:1182`) — so the appended
text arrives in document order.

The golden-fixture test was retargeted:

```bash
# test/skills/code-review-format-contract.bats:185
SKILL_MD="skills/code-review/references/rubric.md"
```

(excerpt ends `:185`; the enclosing top-level file continues — read; `skill_template()` at
`:188-193` awk-extracts the fenced template from `$SKILL_MD`, and `**Use this exact format`
plus its ```` ```markdown ```` block are present in `references/rubric.md`.)

Executed: all 53 tests in the four modified suites pass (exit 0, 0 `not ok`).

**Evidence:** `test/skills/code-review-assurance-contract.bats:24-36`, `test/skills/code-review-format-contract.bats:27-34,183-193`, `skills/code-review/SKILL.md:1132,1142,1182`, `docs/reviews/execution-logs/r1-four-modified-suites.txt`

---

## Claim 14: "every crossing anchor rewritten" / "Every anchor that crossed the split was rewritten programmatically (none left unresolved), including `workflows/pr-prep.md`'s link to the capture format."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`; commit `59ca38f` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every markdown `](...#anchor)` link whose source or target is under
`skills/code-review/`, resolving each against the actual headings of the target file; does not
establish that the *link text* still names the right file (it does not in `workflows/pr-prep.md`
— Claim 24), and does not cover non-markdown referrers or anchors inside fenced code blocks.

A GitHub-style slugifier run over every `.md` file outside `archive/ external/ runs/
node_modules/ devcontainer-config/claude-home/`, restricted to links touching
`skills/code-review/`, checked **51** anchor links and found **0** unresolved
(paraphrased — no quote available because the claim covers the absence of broken links across
many files; the resolver and its output are recorded in the provenance file, step 8).

Two links that look like survivors are in fact correct: `skills/code-review/SKILL.md:77`'s
`[Override-Log](#override-log)` resolves because SKILL.md keeps a pointer section
`## Override-Log` at `:1182`, and `skills/code-review/references/chat-synthesis.md:80`'s
`[The single-sample label](rubric.md#the-single-sample-label)` resolves sibling-relative to
`references/rubric.md:499`.

`test/cross-reference-integrity.bats` also passes (part of the 82-test run in step 7).

**Evidence:** `skills/code-review/SKILL.md:77,1182`, `skills/code-review/references/chat-synthesis.md:80`, `skills/code-review/references/rubric.md:499`, `workflows/pr-prep.md:183`, `docs/reviews/execution-logs/r1-misc-suites.txt`, `docs/reviews/execution-logs/r1-provenance-2026-09-12.txt`

---

## Claim 15a: "All 85 tests pass" / "All 85 tests across the code-review suites pass" — the count

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`; commit `59ca38f` message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cardinality claim against every plausible reading of "the code-review
suites"; does not establish that any test *fails* (none do — Claim 15b), and does not cover the
`test/skills/` orchestrator evals the sibling commit `4d41add` explicitly says were not run
(they need model calls).

`bats --count` over each candidate suite gives: `code-review-assurance-contract` 15,
`code-review-context-delivery` 10, `code-review-executable-defect` 9,
`code-review-factcheck-replication` 17, `code-review-format-contract` 18, `code-review-format` 17,
`code-review-soundness-crosscheck` 11, and `test/code-review-gate.bats` 19 (paraphrased — no quote
available because the evidence is test counts, not file content).

No subset of those eight sums to 85 — an exhaustive subset-sum over all 255 non-empty
combinations returns the empty set (provenance file, step 9). The natural readings give **97**
(all seven `test/skills/code-review-*.bats` suites) or **53** (the four suites this commit
modified). The precise version is "all 97 tests across the code-review suites pass," or "all 53
tests across the four modified suites pass."

**Matches prior pattern:** *"a specific measured value quoted from a checked-in artifact set that
does not contain it"* — the same class as both entries currently in
`docs/reviews/hallucination-patterns.md` (first seen 2026-08-18 / 2026-08-19). It is **not** a new
hallucination-log entry, because no symbol, API, or file is fabricated — only a miscount, which
the log's own exclusion list assigns to the per-run report.

**Evidence:** `docs/reviews/execution-logs/r1-code-review-suites.txt`, `docs/reviews/execution-logs/r1-four-modified-suites.txt`, `docs/reviews/execution-logs/r1-provenance-2026-09-12.txt`

---

## Claim 15b: "All 85 tests … **pass**" — the pass status

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`; commit `59ca38f` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the green status of all seven `test/skills/code-review-*.bats` suites at HEAD in
this sandbox; does not establish behavior of the model-calling orchestrator evals, and does not
establish the count (Claim 15a).

`bats test/skills/code-review-*.bats` exits 0 with 97 `ok` lines, 0 `not ok`, and 0 `# skip`
(paraphrased — no quote available because the evidence is a TAP stream captured to file). The
four modified suites alone give 53 `ok` / 0 `not ok`.

**Evidence:** `docs/reviews/execution-logs/r1-code-review-suites.txt`, `docs/reviews/execution-logs/r1-four-modified-suites.txt`

---

## Claim 16: "Pinned on purpose: changing the judge breaks score comparability with earlier runs."

**Location:** `scripts/cross-model-review.py:372-373`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the causal claim that the judge participates in scoring and that its identity is
therefore a comparability axis; does not establish the *magnitude* of any score shift, and does
not cover the new default's validity (Claim 17).

The judge is a live model call inside the stage-2 matcher, so its identity feeds every derived
number:

```python
# scripts/cross-model-review.py:332-339
def judge_same(key, judge_model, a, b):
    …
            "model": judge_model,
```

(excerpt ends `:339`; the enclosing `judge_same()` continues past `:339` — read; it posts the
request and returns a boolean that `jaccard()` at `:346-358` consumes per candidate pair.)

The file's own docstring already asserted the same thing before this commit:

```python
# scripts/cross-model-review.py:50-51
  Stage-2 (same-underlying-issue) is a judge-model call, pinned by --judge;
  changing the judge invalidates prior numbers, so the judge id is stamped
```

So the new comment restates an existing, correct in-file claim at the site that carries the
default.

**Evidence:** `scripts/cross-model-review.py:50-51,332-358,372-374`

---

## Claim 17: the re-baselined default `--judge anthropic/claude-sonnet-5`

**Location:** `scripts/cross-model-review.py:374`; `docs/reviews/prompt-audit-2026-09-11.md:565`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers (a) that a model named Claude Sonnet 5 exists with canonical id
`claude-sonnet-5`, and (b) that the slug's shape matches the harness's own naming convention;
does **not** establish that `anthropic/claude-sonnet-5` is a live entry in the OpenRouter
catalogue — this sandbox has no egress, and the audit row and the commit's `Notes` both disclose
that the slug is unverified. No other model id in the file needed updating: the `--models`
example ids at `:69` are docstring illustration, which the audit's F10 explicitly excludes.

Claude Sonnet 5 is a current model whose canonical Anthropic id is `claude-sonnet-5` (confirmed
against the bundled `claude-api` skill's Current Models table, cached 2026-06-24). OpenRouter
slugs in this file take the form `<vendor>/<anthropic-id>` — `anthropic/claude-opus-4.5` at `:69`
— so `anthropic/claude-sonnet-5` is the consistent construction (paraphrased — no quote available
because this compares a naming convention across two sites already quoted elsewhere in this
report).

The residue is that OpenRouter's dot-vs-dash convention is visible in the file only for *dotted*
minor versions (`claude-opus-4.5`, the old `claude-sonnet-4.5`); a major-only id has no precedent
in the file to check against. Anything asserting the slug resolves needs one `GET
https://openrouter.ai/api/v1/models` from a host with egress.

**Evidence:** `scripts/cross-model-review.py:69,92,374`, `docs/reviews/prompt-audit-2026-09-11.md:153-162,565`

---

## Claim 18: "`devcontainer-config/install.sh` stages it to the payload root, so the installed layout is unchanged — only the source path moved."

**Location:** `scripts/health-check.sh:29-35`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the staged-payload layout claim and the `GLOBAL_MD` retarget's effect on the
three sibling-comparison loops and the divergence report; does not establish that the *installed*
`~/.config/claude-devcontainer/claude-home` on any host matches (that needs a real `install.sh`
run + rebuild, which the commit says is still pending).

Same executed evidence as Claim 1. On the health-check side, the variable is introduced once and
substituted at every former bare-filename site:

```bash
# scripts/health-check.sh:35
GLOBAL_MD="global-instructions/CLAUDE.md"
```

The three loops at `:203`, `:235` and `:868` now iterate `"$GLOBAL_MD" AGENTS.md GEMINI.md`, and
the divergence report's array keys and warning strings follow (`:944-947`, `:953-957`,
`:965-975`, `:986`). Executed: `scripts/health-check.sh` at HEAD prints
`global-instructions/CLAUDE.md: 283 lines, 8 H2 + 15 H3 sections, 17 skill ref(s)` in the
divergence section and resolves all workflow cross-references for it — i.e. the file is found,
not silently skipped by the `[[ -f "$path" ]] || { warn …; continue; }` guards.

**Evidence:** `scripts/health-check.sh:29-35,200-206,232-238,865-872,941-987`, `docs/reviews/execution-logs/r1-health-check-head.txt`

---

## Claim 19: "Reference file for `skills/code-review/SKILL.md`. Extracted from the skill body 2026-09-11 (prompt audit F8) so it loads when the orchestrator reaches the stage that needs it, not on every trigger. Edit here, not in the skill."

**Location:** `skills/code-review/references/rubric.md:1-3`, `references/chat-synthesis.md:1-3`, `references/override-log.md:1-3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extraction claim (the content came out of SKILL.md in this commit, unaltered
apart from anchor rewrites) and the single-source claim (the moved sections no longer exist in
SKILL.md); does **not** establish that anything mechanically prevents someone editing a copy in
the skill — no test asserts non-duplication, so "edit here, not in the skill" is a convention, not
an enforced invariant.

A multiset line diff of `2d679ce:skills/code-review/SKILL.md` against `HEAD` SKILL.md +
the three references shows **108** differing lines out of 1,909/1,949 — and every one of them is
accounted for: the F3 pressure block deleted by the sibling commit `4d41add`, the three
three-line reference headers, the `## Reference files` index, the four rewritten stub bodies, and
the anchor rewrites (`](#x)` → `](references/rubric.md#x)`, `../../patterns/…` →
`../../../patterns/…`). No moved section body line was altered in transit (paraphrased — no quote
available because the evidence is a sorted-line multiset diff spanning four files; the full
108-line listing is reproducible with the command in the provenance file).

The three moved `##` sections exist exactly once in the concatenation apart from their SKILL.md
stubs, and each sub-heading the tests extract (`### Evidence grounding`, `### Confirmed Good is a
claim, not an output`, `### Unified Severity Mapping`, `### Escalation Rule`) appears exactly once
across SKILL.md + references.

**Evidence:** `skills/code-review/references/rubric.md:1-3`, `skills/code-review/references/chat-synthesis.md:1-3`, `skills/code-review/references/override-log.md:1-3`, `skills/code-review/SKILL.md:1132-1190`

---

## Claim 20: the `## Reference files` index — "the rubric template, tier definitions, evidence grounding, the Unified Severity Mapping, the escalation rule and the two evidence channels" / "required structure, coverage/escalation blocks and next-action derivation" / "the override-log capture format and append procedure"

**Location:** `skills/code-review/SKILL.md:81-92`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each named item is actually present in the reference file the stub points
at; does not establish the "Needed at Stage 3 / Step 3.5" timing claims, which describe intended
reading order rather than a checkable code property.

Every named item maps to a heading in the named file:

```
# skills/code-review/references/rubric.md — headings
5:## Deliverable 2: Code Review Rubric      36/47/58: ## 🔴 / 🟡 / 🟢  (tier definitions)
151:### Evidence grounding                   261:### Unified Severity Mapping
335:### Escalation Rule                      373:### Soundness-Contradiction Channel
443:### Executable-Defect Channel            493:### Rubric Status Line
```

```
# skills/code-review/references/chat-synthesis.md — headings
5:## Deliverable 1: Chat Synthesis   9:### Structure the chat synthesis as:
13:### Considered overrides   26:### Coverage and Escalations   86:#### Next-action derivation
```

```
# skills/code-review/references/override-log.md — headings
5:## Override-Log   9:### Capture format   24:### Capturing new overrides   37:### Why this isn't write-only
```

The `## Deliverable 1` / `## Deliverable 2` / `## Override-Log` stubs at `:1132`, `:1142` and
`:1182` each state what moved and point at the same file (quoted in Claim 19's evidence range).

**Evidence:** `skills/code-review/SKILL.md:81-92,1132-1190`, `skills/code-review/references/rubric.md`, `skills/code-review/references/chat-synthesis.md`, `skills/code-review/references/override-log.md`

---

## Claim 21: "see [Capturing new overrides](references/override-log.md#capturing-new-overrides) **below**"

**Location:** `skills/code-review/SKILL.md:158`; sibling at `skills/code-review/SKILL.md:1173`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the positional word "below" and the unlinked quoted section name at `:1173`; does
not affect the link target itself, which resolves correctly (Claim 14).

The anchor was rewritten but the surrounding positional prose was not:

```markdown
# skills/code-review/SKILL.md:158
…are appended to `docs/reviews/override-log.md` as a follow-up step (see [Capturing new overrides](references/override-log.md#capturing-new-overrides) below), not during dispatch.
```

`### Capturing new overrides` is no longer anywhere in SKILL.md — it is
`skills/code-review/references/override-log.md:24`. What the code now does is send the reader to a
different file, so "below" should read "in the override-log reference." The same drift appears
unlinked at:

```markdown
# skills/code-review/SKILL.md:1173
├── override-log.md                (append-only across runs — see "Capturing new overrides")
```

where the quoted section name has no in-file target at all.

**Evidence:** `skills/code-review/SKILL.md:158,1173`, `skills/code-review/references/override-log.md:24`

---

## Claim 22: "Read in document order so the section-extraction end anchors still follow their sections."

**Location:** `test/skills/code-review-assurance-contract.bats:30`; identical comment at `code-review-executable-defect.bats:25`, `code-review-format-contract.bats:29`, `code-review-soundness-crosscheck.bats:25`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `sed -n '/start/,/end/p'` range these four suites run over `SKILL_CONTENT`
and the `subsection()` helper's first-match behavior; does not establish anything about
`code-review-format-contract.bats`'s `section()` helper, which reads `FIXTURE_CONTENT`, not the
concatenation.

The mechanism holds for every **bounded** range. The two cross-section ranges both live entirely
inside `references/rubric.md` and in the right order there (`### Soundness-Contradiction Channel`
`:373` → `### Executable-Defect Channel` `:443` → `### Rubric Status Line` `:493`):

```bash
# test/skills/code-review-executable-defect.bats:38
  echo "$SKILL_CONTENT" | sed -n '/^### Executable-Defect Channel/,/^### Rubric Status Line/p'
```

(excerpt ends `:38`; the enclosing helper continues to `:39` — read; `:39` is the closing `}`.)

```bash
# test/skills/code-review-soundness-crosscheck.bats:41
  echo "$SKILL_CONTENT" | sed -n '/^### Soundness-Contradiction Channel/,/^### Rubric Status Line/p'
```

The `subsection()` helper's first-match semantics are also safe: each heading it is called with
occurs exactly once across the concatenation.

The imprecision is one **unbounded** range that the comment's framing does not cover:

```bash
# test/skills/code-review-assurance-contract.bats:123-125
  echo "$SKILL_CONTENT" | sed -n '/^## Important Reminders/,$p' \
    | grep -qiE 'Confirmed Good.*claim, not an output' \
    || fail "Important Reminders does not carry the Confirmed-Good contract"
```

(excerpt ends `:125`; the enclosing `@test` continues to `:126` — read; `:126` is the closing `}`.)

`$` used to mean "end of SKILL.md"; it now means "end of SKILL.md **plus all three references**."
`references/rubric.md:174` is literally `### Confirmed Good is a claim, not an output`, so this
assertion is now satisfiable by the appended reference text even if `## Important Reminders` lost
the line. It currently passes on its own merits — `skills/code-review/SKILL.md:1239` carries
`[Confirmed Good is a claim, not an output](references/rubric.md#…)` inside Important Reminders —
so the suite is green, but the test no longer proves what its failure message says.

**Evidence:** `test/skills/code-review-assurance-contract.bats:24-43,123-126`, `test/skills/code-review-executable-defect.bats:38`, `test/skills/code-review-soundness-crosscheck.bats:41,107,115`, `skills/code-review/references/rubric.md:174,373,443,493`, `skills/code-review/SKILL.md:1239`, `docs/reviews/execution-logs/r1-four-modified-suites.txt`

---

## Claim 23: "The rubric template moved into the skill's references/ dir 2026-09-11 (prompt audit F8); the golden fixture is still compared against it."

**Location:** `test/skills/code-review-format-contract.bats:183-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `SKILL_MD` now names `references/rubric.md`, that the awk extractor finds a
template there, and that the mirroring tests pass; does not establish that the template's
*content* is unchanged from the pre-split version beyond the multiset check in Claim 19.

Quoted in Claim 13. Executed: the 18 tests in `code-review-format-contract.bats` pass, which
includes the golden-vs-template comparisons that would go red on an empty `skill_template()`
(paraphrased — no quote available because the evidence is a TAP stream).

**Evidence:** `test/skills/code-review-format-contract.bats:180-193`, `skills/code-review/references/rubric.md:5-35`, `docs/reviews/execution-logs/r1-four-modified-suites.txt`

---

## Claim 24: `` [`skills/code-review/SKILL.md`](../skills/code-review/references/override-log.md#capture-format) ``

**Location:** `workflows/pr-prep.md:183`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mismatch between the link's displayed text and its target; does not affect
anchor resolution, which is correct.

The href was rewritten by the split but the link text was not:

```markdown
# workflows/pr-prep.md:182-184
before the fix commit lands. Append to `docs/reviews/override-log.md` using the format in
[`skills/code-review/SKILL.md`](../skills/code-review/references/override-log.md#capture-format) — Date, PR
ref, Finding (with `path:line` and the surfacing critic), Original verdict, Override
```

The target is correct — `### Capture format` is `skills/code-review/references/override-log.md:9`,
and the anchor resolver found 0 unresolved links — but a reader following the *displayed* path
lands in SKILL.md, where the capture format no longer is. The precise version renders the text as
`skills/code-review/references/override-log.md`.

**Evidence:** `workflows/pr-prep.md:182-184`, `skills/code-review/references/override-log.md:9`, `docs/reviews/execution-logs/r1-provenance-2026-09-12.txt`

---

## Claim 25a: "health-check failures are identical to the pre-change baseline" — the identity

**Location:** commit `c56be81` message ("Verified:" paragraph)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the *set* of failing checks at HEAD versus `2d679ce` in this sandbox; does not
establish the count (Claim 25b), and does not cover host-only checks (Docker/container probes)
that this sandbox cannot run.

Executed at HEAD (cwd `/workspace`, exit 1) and at `2d679ce` (detached worktree, exit 1), the
failing lines are the same four shellcheck targets plus the same two MD-consistency warnings, the
only difference being the labelled path:

```
# HEAD            ✗ In global-instructions/CLAUDE.md but not AGENTS.md: parallel-worktrees.md
# 2d679ce         ✗ In CLAUDE.md but not AGENTS.md: parallel-worktrees.md
#  (both)         ✗ .apir5-probe2.sh
#  (both)         ✗ test/auto-approve-allowed-commands.bats
#  (both)         ✗ test/init-firewall-rules.bats
#  (both)         ✗ test/cc-isolated-functions.bats
```

The baseline run showed one extra line, `✗ BATS tests failed`. That is a **worktree artifact, not
a baseline difference**: re-running the same script from a detached worktree at *HEAD* reproduces
it identically (step 5 in the provenance file), so it tracks the execution environment, not the
commit.

**Evidence:** `docs/reviews/execution-logs/r1-health-check-head.txt`, `docs/reviews/execution-logs/r1-health-check-baseline.txt`, `docs/reviews/execution-logs/r1-health-check-head-worktree.txt`

---

## Claim 25b: "(four, all pre-existing)" — the count

**Location:** commit `c56be81` message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the number of `✗` (FAIL) lines `scripts/health-check.sh` emits at HEAD in this
sandbox; does not dispute "all pre-existing", which Claim 25a confirms.

`scripts/health-check.sh` at HEAD emits **six** `✗` lines, not four: four shellcheck failures plus
two `MD file consistency (workflows)` failures (listed in Claim 25a). Both kinds come from the
same `fail`/`✗` emitter and both count toward the script's `FAIL` state — `check_md_consistency`
is not a soft-warning section (`check_md_semantic_divergence` is the soft one, and it emits `⚠`,
not `✗`). The precise version is "six, all pre-existing — four shellcheck, two MD-consistency."

**Evidence:** `docs/reviews/execution-logs/r1-health-check-head.txt`, `scripts/health-check.sh:200-206,232-238`

---

## Claim 26: "agents-gemini-sync, cross-reference-integrity, guide-index-sync and link-claude-home-wiring all pass; the basename staging was simulated against a file entry and a directory entry."

**Location:** commit `c56be81` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named suites' green status and the re-derivation of the basename
simulation for both entry kinds; does not establish that the simulation the author ran was the one
re-run here, nor that a real host `install.sh` + rebuild has happened (the commit says it has not).

Executed: `bats test/cross-reference-integrity.bats test/agents-gemini-sync.bats
test/guide-index-sync.bats test/link-claude-home-wiring.bats test/cc-isolated-functions.bats`
exits 0 with 82 `ok` and 0 `not ok` (paraphrased — no quote available because the evidence is a
TAP stream captured to file).

The basename simulation was re-derived by running the installer itself (Claim 1): the file entry
`global-instructions/CLAUDE.md` lands as a regular file at the payload root, and the six directory
entries (`skills workflows guides patterns hooks scripts`) land as directories under their
unchanged names — both kinds exercised.

**Evidence:** `docs/reviews/execution-logs/r1-misc-suites.txt`, `docs/reviews/execution-logs/r1-install-sim.txt`, `devcontainer-config/install.sh:47-57`

---

## Claim 27: "install.sh is not in `enforcement_files()`, so no `Live-verified` trailer is required."

**Location:** commit `c56be81` message (`Notes:` line)
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both halves — `install.sh`'s absence from the manifest-hashed set and from the
commit gate's regex; does not establish that the *staged payload* is outside the manifest (it is
inside it: `enforcement_files()` walks `claude-home`), only that this commit does not change any
hashed byte, since the payload file's path and content at the payload root are unchanged.

The enforcement set names six files plus two glob sets plus the `claude-home` walk, and
`install.sh` is in none of them:

```bash
# devcontainer-config/cc-isolated.sh:107-115
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

(excerpt ends `:115`; the enclosing `enforcement_files()` continues to `:130` — read; `:116-129`
add `egress/*.txt`, `projects/*.profile` and a `find claude-home` walk, none of which can match
`install.sh`, which is never copied into `$DEST` — `PAYLOAD` at `install.sh:25` omits it and
`install.sh:23` says so explicitly.)

The hook that would demand the trailer keys on a repo-path regex with the same six names:

```bash
# hooks/live-verify-gate.sh:57-59
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|egress/)'
touched="$(printf '%s\n' "$files" | grep -E "$enforcement" | sort -u)"
[ -n "$touched" ] || exit 0
```

(excerpt ends `:59`; the enclosing top-level script continues to `:89` — read; `:61-89` are the
trailer check and the BLOCKED message, all downstream of the `[ -n "$touched" ]` early exit.)
`devcontainer-config/install.sh` does not match that alternation, so the gate exits 0 before ever
looking for a trailer — which is why commit `c56be81` carries none and was not blocked.

**Evidence:** `devcontainer-config/cc-isolated.sh:107-130`, `hooks/live-verify-gate.sh:49-59`, `devcontainer-config/install.sh:23-25`

---

## Claim 28: "This also kills the last surviving 'Task tool' reference, a regression against skill-format-audit Finding 7."

**Location:** commit `4d41add` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the string "Task tool" across the live prompt surface (`skills/`, `workflows/`,
`patterns/`, `guides/`, `hooks/`, `scripts/`, root entry points), excluding `archive/ external/
runs/ node_modules/ docs/ devcontainer-config/claude-home/`; does not establish anything about the
tool's actual name in the running harness.

The last *prescriptive* reference is indeed gone (Claim 5). Two non-prescriptive occurrences
survive, so "the last surviving reference" overstates it. The precise version is "the last
surviving *instruction* to dispatch via the Task tool."

```markdown
# patterns/orchestrated-review.md:31
**Terminology note**: Use "sub-agent" consistently for the parallel execution mechanism, regardless of whether the underlying implementation uses the Task tool, Agent tool, or manual sequential processing.
```

This one is deliberate — it names both tool names to define the vocabulary — but it is a live,
always-inheritable pattern file, not an archived document. The other two hits are in
`guides/skill-format-audit.md:161` and `:167`, which quote the old text as the historical record
of Finding 7 itself and are correct as history.

**Evidence:** `patterns/orchestrated-review.md:31`, `guides/skill-format-audit.md:161,167`, `skills/draft-review/SKILL.md:190`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15a** (`docs/reviews/prompt-audit-2026-09-11.md:569`, commit `59ca38f`): "All 85 tests … pass" — no subset of the code-review suites totals 85; the real numbers are 97 (all seven `test/skills/code-review-*.bats` suites) or 53 (the four suites this commit modified). Fix the number in both the audit row and the commit's recorded text (a commit message cannot be amended after the fact, but the audit row can).
- **Claim 25b** (commit `c56be81`): "(four, all pre-existing)" — `scripts/health-check.sh` emits six `✗` FAIL lines at HEAD (four shellcheck + two MD-consistency), all pre-existing. The identity claim it sits inside is correct.

### Stale
- **Claim 21** (`skills/code-review/SKILL.md:158`): "see [Capturing new overrides](references/override-log.md#capturing-new-overrides) **below**" — the section is no longer below, it is in another file. Same drift unlinked at `skills/code-review/SKILL.md:1173`.

### Mostly Accurate
- **Claim 4** (`docs/decisions/log.md:68`): "byte-identical duplication" holds only while the baked image is current with the repo; the image is stamped 2026-09-09 and the repo copy changed 2026-09-11. Tighten to "byte-identical whenever the installed image is current."
- **Claim 17** (`scripts/cross-model-review.py:374`): `anthropic/claude-sonnet-5` is the consistent construction for an existing model (`claude-sonnet-5`), but its presence in the OpenRouter catalogue cannot be checked without egress. Confirm with one `GET /api/v1/models` before the next cross-model run, as the audit row already says.
- **Claim 22** (`test/skills/code-review-assurance-contract.bats:123`): the `sed -n '/^## Important Reminders/,$p'` range now extends past SKILL.md into all three reference files, so `references/rubric.md:174` can satisfy the assertion on its own. Bound the range (e.g. `,/^## /` is unavailable since Important Reminders is last — use `awk` on the SKILL.md file directly, or grep `"$SKILL"` rather than `"$SKILL_CONTENT"` for this one test).
- **Claim 24** (`workflows/pr-prep.md:183`): the link text still reads `skills/code-review/SKILL.md` while the href now points at `references/override-log.md`. Update the text.
- **Claim 28** (commit `4d41add`): "the last surviving 'Task tool' reference" — `patterns/orchestrated-review.md:31` still names it (deliberately, in a terminology note). The killed reference was the last *prescriptive* one.

### Unverifiable
- (none)

---

## Goal-Alignment Note

**Answered.** Every checkable claim in the `2d679ce..HEAD` diff and in all four commit messages,
against the shared brief's ten focus areas. All ten were reached: (1) the audit's Application-status
table row by row, including the F4 site-list completeness question and the 1,909→1,256 and "85
tests" numbers; (2) decision-log row 47 against `install.sh` and `link-claude-home.sh`, including
what happens to the six *other* `CLAUDE_HOME_SRC` entries under the basename change and what the
link script expects at the payload root; (3) the health-check baseline, re-derived by running
`scripts/health-check.sh` at both commits (plus a control run at HEAD in a worktree to separate a
genuine failure from an environment artifact); (4) `enforcement_files()` and `live-verify-gate.sh`;
(5) all 51 anchor links touching `skills/code-review/`, plus external referrers; (6) the new
comments in `install.sh` and `health-check.sh`; (7) the judge pin and the file's own docstring;
(8) the reference headers and the SKILL.md stubs; (9) the retired numeric cap, swept repo-wide;
(10) the four `.bats` `SKILL_CONTENT` definitions and the section-extraction helpers run against
them.

**Out of scope.** Whether the split is the *right* shape (which sections should stay resident) —
that is a design judgment the sibling critics own. Whether the F4 rewrite changes sub-agent
behavior — that needs the model-calling orchestrator evals, which the author's own `Notes` line
says were not run and which this sandbox cannot run. Whether `anthropic/claude-sonnet-5` resolves
on OpenRouter — no egress; recorded as residue on Claim 17 rather than as a verdict.

**Escalate.** Two count errors (Claims 15a, 25b) in text that reads as verification evidence. Both
are the same failure shape as the two entries already in `docs/reviews/hallucination-patterns.md`
— a specific measured number attributed to a checked-in artifact set that does not contain it —
and both appear in a *commit message*, where they cannot be corrected in place. The audit doc's
copy of the 85 can and should be fixed. No entry was appended to the hallucination log: the log's
own exclusion list assigns miscounts to the per-run report, and no symbol or API is fabricated
here.

**Decisions I made.**
- Treated "the code-review suites" as `test/skills/code-review-*.bats` when testing Claim 15a, and
  proved the point independent of that reading by exhausting every subset of the eight candidate
  suites (including `test/code-review-gate.bats`). The defensible alternative was to mark the count
  Unverifiable on the grounds that the phrase is ambiguous; I rejected it because no reading
  produces 85.
- Counted health-check "failures" as `✗`-emitting lines for Claim 25b. The defensible alternative
  was to count failing *sections* (which would give three: MD consistency, shellcheck, and — in a
  worktree — BATS), on which "four" would still be wrong but differently.
