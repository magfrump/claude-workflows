Commit: 0661353

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** `git diff -M -C 2d679ce..HEAD` (commits 4d41add, c56be81, 59ca38f, 0661353) plus their commit messages. Self-read delivery; the rename (`CLAUDE.md` → `global-instructions/CLAUDE.md`) and the ~680-line extraction out of `skills/code-review/SKILL.md` were verified as moves-with-recorded-deltas rather than re-read as new text.
**Checked:** 2026-09-12
**Total claims checked:** 21
**Summary:** 15 verified, 1 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable

Prior-pattern check: both entries in `docs/reviews/hallucination-patterns.md` are of the form *a specific measured value quoted from a checked-in artifact set that does not contain it*. Claims 5b, 18 and 20 below (the "85 tests" count and the "four" health-check failures) are the same class and are flagged as such in their verdict blocks.

---

## Claim 1: "Entries are staged under their basename, so the payload layout (and link-claude-home.sh) is unchanged."

**Location:** `devcontainer-config/install.sh:42-46`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the staging loop's output layout for a nested file entry, a top-level directory entry and a missing entry, and that `link-claude-home.sh` finds the instructions file where the loop puts it; does not establish that the built image or a live container behaves as claimed (no Docker in this sandbox), nor that the `PAYLOAD` diff/bless step downstream is unaffected by anything other than the staged tree.

The loop is:

```bash
# devcontainer-config/install.sh:47-57
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
STAGE="$SRC/claude-home"
rm -rf "$STAGE"
mkdir -p "$STAGE"
for item in "${CLAUDE_HOME_SRC[@]}"; do
  if [ -e "$REPO_ROOT/$item" ]; then
    cp -r "$REPO_ROOT/$item" "$STAGE/$(basename "$item")"
  else
    echo "WARNING: $REPO_ROOT/$item not found — omitted from the image payload." >&2
  fi
done
```

(excerpt ends `:57`; the enclosing script continues to `:127` with the `.manifest` stamp, the diff gate and the copy into `$DEST` — read; none of those read `$item` again.)

For the other six entries `basename` is the identity (`skills` → `skills`, and so on), so only the one nested entry changes shape. The consumer expects the file at the payload root:

```bash
# devcontainer-config/link-claude-home.sh:47
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
```

(excerpt ends `:47`; the enclosing loop runs `:50-63` and the script continues to `:146` — read; the loop does `[ -e "$SRC/$name" ] || continue` then symlinks `$SRC/$name` into `$DEST`, so a payload-root file is exactly what it needs.)

Re-ran the loop against a synthetic repo with one nested file entry, one directory entry and one missing entry; the stage tree came out `stage/<file>`, `stage/skills/foo/SKILL.md`, and the missing entry took the WARNING branch.

**Evidence:** `devcontainer-config/install.sh:42-57`, `devcontainer-config/link-claude-home.sh:41-63`, `docs/reviews/execution-logs/r3-install-basename-sim.txt` (cmd + cwd + exit 0 + timestamp recorded in the file)

---

## Claim 2: "at the root, a session working in THIS repo loads it twice — once as the linked ~/.claude copy and once as the project's own instructions"

**Location:** `devcontainer-config/install.sh:43-45` (restated at `scripts/health-check.sh:29-33`, `README.md:124`, `docs/decisions/log.md:68`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that two byte-identical copies of the instructions file reach the model's context in a session rooted at this repo while the root copy exists; does not establish the "~8K tokens per request" figure attached to it in the decision-log row and the commit message (not measured here), nor that the *post-move* state actually removes the second load in a rebuilt container (that requires an `install.sh` + rebuild this sandbox cannot perform).

Direct observation of this session's own prompt: it carries `/home/node/.claude/CLAUDE.md` (the image-linked global copy) and `/workspace/CLAUDE.md` (the project copy) as two separate blocks whose text is identical (paraphrased — no quote available because the evidence is the reviewing session's own system context, not a file in the repo; reproducing it as a quote would mean pasting ~8K tokens twice).

The mechanism is confirmed in the repo: the global copy resolves through the baked payload, not the working tree —

```
# ls -la /home/node/.claude/CLAUDE.md
lrwxrwxrwx 1 node node 31 Sep  9 16:59 /home/node/.claude/CLAUDE.md -> /opt/claude-workflows/CLAUDE.md
```

— and the repo-root file is now gone (`ls: cannot access 'CLAUDE.md': No such file or directory`; `global-instructions/CLAUDE.md` is 30,343 bytes). Both blocks in this session show the *pre-`4d41add`* text (they still contain the two batch-fan-out paragraphs that commit removed), which is exactly what `c56be81`'s "Takes effect at the next install.sh + rebuild — a session started before that still sees both copies" predicts.

**Evidence:** `devcontainer-config/install.sh:42-47`, `/home/node/.claude/CLAUDE.md` (symlink target), `global-instructions/CLAUDE.md`, commit `c56be81` message body

---

## Claim 3: "`install.sh` now stages payload entries under their basename, so the image layout and `link-claude-home.sh` are unchanged — `~/.claude/CLAUDE.md` still resolves to the same content."

**Location:** `docs/decisions/log.md:68` (row 47)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the source-path change and the staged layout it produces; does not establish that an already-built image or a running container resolves to the new content (it does not — the existing symlink points at the pre-rebuild `/opt/claude-workflows/CLAUDE.md`, which is the row's own "takes effect at the next install.sh + rebuild" caveat).

Same evidence as Claim 1. The row's further assertion that `scripts/health-check.sh` "reads the path from a `GLOBAL_MD` variable instead of a bare filename" holds:

```bash
# scripts/health-check.sh:35
GLOBAL_MD="global-instructions/CLAUDE.md"
```

and every functional reference now goes through it — `grep -n 'GLOBAL_MD' scripts/health-check.sh` returns 16 lines (`:203`, `:235`, `:868`, `:944-975`, `:986`), while the remaining literal `CLAUDE.md` hits (`:13`, `:14`, `:25`, `:187`, `:192`, `:843`, `:844`, `:922`, `:925`, `:963`) are all inside comments (paraphrased — no quote available because the claim covers the absence of a functional literal across ten scattered comment lines rather than any single snippet).

**Evidence:** `docs/decisions/log.md:68`, `scripts/health-check.sh:35`, `scripts/health-check.sh:203`, `scripts/health-check.sh:235`, `scripts/health-check.sh:868`, `scripts/health-check.sh:944-986`

---

## Claim 4: F4 row — "inheriting sites updated (`guides/sub-agent-briefing.md` … `guides/README.md` … `workflows/task-decomposition.md`, `guides/task-decomposition-examples.md`, `skills/matrix-analysis/SKILL.md`)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:562`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers completeness of the file list against a repo-wide search for the retired numeric cap and its anchor, excluding `archive/`, `external/`, `runs/`, `docs/` and `node_modules/`; does not establish that the *replacement* shape text is behaviorally effective (that needs model-call evals the commit says were not run).

A repo-wide search for the retired convention returns nothing outside `docs/` — `rg -n -i '300 words|<300|300-word|word cap|word limit|words or less|words max'` over the repo minus those directories produced zero hits, and `rg -n 'default-output-cap|Default output cap|output cap'` returns only `docs/reviews/prompt-audit-2026-09-11.md` (the audit quoting the old text) and an unrelated `docs/reviews/execution-logs` phrase in `skills/code-review/references/rubric.md:471` ("output captured under") (paraphrased — no quote available because the claim is the *absence* of matches; the searches returned no lines to quote).

The named sites all carry the change, including the stale anchor in the one cross-file link:

```md
<!-- workflows/task-decomposition.md:121 -->
The pattern's [default output shape](../patterns/orchestrated-review.md#default-output-shape) applies unless the dispatch names a different one.
```

`skills/code-review/SKILL.md` is correctly absent from the list: it never carried a word cap (no hit in the search above).

**Evidence:** `patterns/orchestrated-review.md:131-143`, `guides/sub-agent-briefing.md:14`, `guides/sub-agent-briefing.md:29`, `guides/sub-agent-briefing.md:36`, `guides/sub-agent-briefing.md:62-69`, `guides/sub-agent-briefing.md:96`, `guides/README.md:51`, `workflows/task-decomposition.md:113`, `workflows/task-decomposition.md:121`, `guides/task-decomposition-examples.md:32-38`, `skills/matrix-analysis/SKILL.md:220-224`

---

## Claim 5a: F8 row — "SKILL.md 1,909 → 1,256 lines"; "`references/rubric.md` (515 lines …), `references/chat-synthesis.md` (126), `references/override-log.md` (52)"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four line counts as of HEAD; does not establish what fraction of the skill actually loads per trigger (progressive-disclosure behaviour is a runtime property of the harness, not checkable here).

```
$ wc -l skills/code-review/SKILL.md skills/code-review/references/*.md
  1256 skills/code-review/SKILL.md
   126 skills/code-review/references/chat-synthesis.md
    52 skills/code-review/references/override-log.md
   515 skills/code-review/references/rubric.md
$ git show 2d679ce:skills/code-review/SKILL.md | wc -l
1909
```

(cwd `/workspace`, exit 0, 2026-09-12.) The content inventory in the same row also checks out against the extracted files' headings: `rubric.md` carries the template (`:30`), tier definitions (`:36`, `:47`, `:58`), `### Evidence grounding` (`:151`), `### Unified Severity Mapping` (`:261`), `### Escalation Rule` (`:335`), `### Soundness-Contradiction Channel` (`:373`), `### Executable-Defect Channel` (`:443`) and `### Rubric Status Line` (`:493`).

**Evidence:** `skills/code-review/SKILL.md`, `skills/code-review/references/rubric.md:30-509`, `skills/code-review/references/chat-synthesis.md`, `skills/code-review/references/override-log.md`, `docs/reviews/execution-logs/r3-code-review-bats.txt`

---

## Claim 5b: F8 row — "All 85 tests pass."

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the *count*; the pass half is separately true (see Claim 20a). Does not establish anything about the orchestrator evals the commit body explicitly says were not run.

Running every `test/skills/code-review-*.bats` suite gives **97** tests, all passing — not 85:

```
$ bats test/skills/code-review-{assurance-contract,context-delivery,executable-defect,factcheck-replication,format-contract,format,soundness-crosscheck}.bats
... ok 97 the section-extraction end anchor exists (no silent extract-to-EOF)
EXIT=0     ok: 97     not ok: 0
```

(cwd `/workspace`, exit 0, 2026-09-12.) Per-suite counts are 15 / 10 / 9 / 17 / 18 / 17 / 11. No subset of those seven suites — nor any subset including `test/code-review-gate.bats` (19) — sums to 85; a brute-force enumeration of all 255 subsets returned no match. The figure therefore does not correspond to any grouping of the current suites. Matches the prior pattern class **"a specific measured value quoted from a checked-in artifact set that does not contain it"** (first seen 2026-08-18/19) — a quoted count, off by twelve, presented as a measurement.

**Evidence:** `docs/reviews/execution-logs/r3-code-review-bats.txt`, `test/skills/code-review-assurance-contract.bats`, `test/skills/code-review-format-contract.bats`, `test/code-review-gate.bats`

---

## Claim 6: "It sits in its own directory rather than the repo root so that a session working in *this* repo does not load it twice — once from `~/.claude` and once as the project's own instructions."

**Location:** `README.md:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same coverage and residue as Claim 2 — covers that the duplication existed and that the root copy is gone; does not establish the post-rebuild single-load state. The adjacent install snippet is separately correct: `README.md:14` now reads `ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md`.

**Evidence:** `README.md:14`, `README.md:124`, `README.md:168`, `guides/cross-project-setup.md:7`, `guides/cross-project-setup.md:34`

---

## Claim 7: "Pinned on purpose: changing the judge breaks score comparability with earlier runs."

**Location:** `scripts/cross-model-review.py:372-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the judge is on the scoring path, so a judge swap changes scores for identical inputs; does not establish the magnitude of the comparability break, and does not establish that any *other* pinned input (the prompt text, `--slack`) is stable across the same cutover.

The `--judge` value is threaded straight into the stage-2 matcher, which decides whether two findings are the same issue and therefore drives the overlap numbers:

```python
# scripts/cross-model-review.py:332-346
def judge_same(key, judge_model, a, b):
    ...
            "model": judge_model,
...
def jaccard(fa, fb, key, judge_model, slack):
```

(excerpt ends `:346`; `judge_same` runs `:332-344` and `jaccard` continues to `:365` — read; `jaccard` calls `judge_same` at `:358` inside its pairing loop, so the judge model is what produces the reported overlap.) The docstring says the same thing independently: "Stage-2 (same-underlying-issue) is a judge-model call, pinned by `--judge`" (`scripts/cross-model-review.py:50`).

**Evidence:** `scripts/cross-model-review.py:50`, `scripts/cross-model-review.py:332-365`, `scripts/cross-model-review.py:372-374`

---

## Claim 8: The changed default `--judge` value `anthropic/claude-sonnet-5`

**Location:** `scripts/cross-model-review.py:374`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that `claude-sonnet-5` is a real current Anthropic model id and that the `anthropic/…` slug is shaped consistently with the other model ids this harness documents; does NOT establish that OpenRouter serves that exact slug — execution against the live model list is required and this sandbox has no egress.

`claude-sonnet-5` is a real, current Anthropic model (Claude Sonnet 5, 1M context) per the bundled `claude-api` model table (paraphrased — no quote available because the source is a loaded skill reference, not a repo file). The slug is consistent with the harness's own documented examples, which use the provider-prefixed OpenRouter form:

```python
# scripts/cross-model-review.py:69
    --models anthropic/claude-opus-4.5 openai/gpt-5.2 google/gemini-3-pro \
```

The previous pin was `anthropic/claude-sonnet-4.5`, i.e. the same `anthropic/claude-<tier>-<version>` shape; `claude-sonnet-5` has no minor component, so the absence of a dot is expected rather than a deviation. The script itself fails closed on an unknown id rather than silently projecting $0.00:

```python
# scripts/cross-model-review.py:437-440
        # Unpriced models must fail the guard closed, not project $0.00: a
        # pricing-fetch failure (or an unknown model id) would otherwise let a
        unpriced = [m for m in pricing... ]
```

(excerpt ends `:440`; the enclosing `main()` guard continues to `:463` — read; an unpriced list triggers the abort at `:460-462`.) Note that guard covers `--models`, not `--judge`, so a bad judge slug would surface as a stage-2 API error rather than a pre-flight abort. The audit row already flags the slug as unverified; this report concurs. **Blocker: no network egress from this sandbox.**

**Evidence:** `scripts/cross-model-review.py:67-71`, `scripts/cross-model-review.py:374`, `scripts/cross-model-review.py:437-463`, `docs/reviews/prompt-audit-2026-09-11.md:565`

---

## Claim 9: "`devcontainer-config/install.sh` stages it to the payload root, so the installed layout is unchanged — only the source path moved."

**Location:** `scripts/health-check.sh:29-34`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same coverage as Claim 1 (staged tree only); does not establish that a host `install.sh` run against a real `$DEST` produces an empty diff, since the diff step runs over `$SRC/claude-home` vs `$DEST/claude-home` and this sandbox has no installed config dir.

**Evidence:** `scripts/health-check.sh:29-35`, `devcontainer-config/install.sh:47-57`, `docs/reviews/execution-logs/r3-install-basename-sim.txt`

---

## Claim 10: "Three parts of this skill live beside it and are read when the stage that needs them arrives, not on every trigger" + the three per-file descriptions

**Location:** `skills/code-review/SKILL.md:83-92`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that exactly three reference files exist and that each index entry names material actually present in the file it points at; does not establish the *load* behaviour ("not on every trigger") — that is a property of the harness's progressive disclosure, not of the repo.

`ls skills/code-review/references/` returns exactly `chat-synthesis.md`, `override-log.md`, `rubric.md`. Each index entry's contents check out against the target's headings: rubric.md has `### Evidence grounding` (`:151`), `### Unified Severity Mapping` (`:261`), `### Escalation Rule` (`:335`) and both channels (`:373`, `:443`); chat-synthesis.md has `### Coverage and Escalations` (`:26`) and `#### Next-action derivation` (`:86`); override-log.md has `### Capture format` (`:9`) and `### Capturing new overrides` (`:24`).

**Evidence:** `skills/code-review/SKILL.md:81-92`, `skills/code-review/references/rubric.md:151-493`, `skills/code-review/references/chat-synthesis.md:5-86`, `skills/code-review/references/override-log.md:5-37`

---

## Claim 11: The three pointer stubs' descriptions of what moved

**Location:** `skills/code-review/SKILL.md:1132-1190`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every item each stub enumerates exists in the named reference file; does not establish that nothing *else* moved unlisted (`### Mechanism visibility floor`, rubric.md:316, is in the extracted file but named by no stub — an omission, not a false statement).

The Deliverable 2 stub names "the template, the tier definitions, evidence grounding, the Unified Severity Mapping, the escalation rule, the soundness-contradiction and executable-defect channels, and the rubric status line" (`skills/code-review/SKILL.md:1144-1147`); all eight resolve to headings in `references/rubric.md` (see Claim 10). The Deliverable 1 stub names the "single-sample label", which is present:

```md
<!-- skills/code-review/references/chat-synthesis.md:73 -->
**Single-sample label (required when the run is clean):** when the derivation below lands
```

Note that `## Output Locations` (`skills/code-review/SKILL.md:1153`) did **not** move and remains resident between the two stubs — consistent with the commit's stated rule and with no stub claiming otherwise.

**Evidence:** `skills/code-review/SKILL.md:1132-1190`, `skills/code-review/references/chat-synthesis.md:73`, `skills/code-review/references/rubric.md:30-509`

---

## Claim 12: "Reference file for skills/code-review/SKILL.md. Extracted from the skill body 2026-09-11 (prompt audit F8) … Edit here, not in the skill."

**Location:** `skills/code-review/references/chat-synthesis.md:1-3`, `skills/code-review/references/override-log.md:1-3`, `skills/code-review/references/rubric.md:1-3`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the material was extracted (not duplicated) — the corresponding bodies no longer exist in `SKILL.md` — and that no second copy of the moved prose remains in the skill; does not establish that every *consumer* now reads the reference (the `scripts/self-improvement.sh` path is untested, as the commit notes).

Differencing the moved text against the pre-change skill confirms an extraction with only link rewrites: `chat-synthesis.md` differs from `2d679ce:skills/code-review/SKILL.md:1126-1250` in exactly two lines (both relative-path fixes: `../../patterns/…` → `../../../patterns/…`, and `[The single-sample label](#the-single-sample-label)` → `(rubric.md#the-single-sample-label)`) plus a dropped trailing `---`; `override-log.md` differs from `:1794-1844` only by the dropped trailing `---`; `rubric.md` differs from `:1251-1793` in two link rewrites plus the 30-line `## Output Locations` block that stayed resident (paraphrased — no quote available because the evidence is a three-way unified diff across a 543-line region, which reads as a summary rather than a quotable fragment; the diff is reproducible with `git show 2d679ce:skills/code-review/SKILL.md`).

**Evidence:** `skills/code-review/references/rubric.md:1-3`, `skills/code-review/references/chat-synthesis.md:1-3`, `skills/code-review/references/override-log.md:1-3`, `skills/code-review/SKILL.md:1153-1180`

---

## Claim 13: "The skill's content surface spans SKILL.md plus its references/ files … Read in document order so section-extraction end anchors still follow their sections."

**Location:** `test/skills/code-review-assurance-contract.bats:27-34` (identically at `test/skills/code-review-executable-defect.bats:23-30`, `test/skills/code-review-format-contract.bats:30-37`, `test/skills/code-review-soundness-crosscheck.bats:27-34`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the concatenation order matches the pre-split document order and that every `sed` range extraction in the four suites still has its end anchor downstream of its start anchor; does NOT establish that the concatenation is free of new hazards — see the note below on duplicate `##` headings and on the one range that now extends past `SKILL.md` into the references.

The order asserted is chat-synthesis, rubric, override-log:

```bash
# test/skills/code-review-assurance-contract.bats:30-34
  SKILL_CONTENT=$(cat "$SKILL" \
    "$SKILL_DIR/references/chat-synthesis.md" \
    "$SKILL_DIR/references/rubric.md" \
    "$SKILL_DIR/references/override-log.md" | tr -d '\r')
```

That is the pre-split order: in `2d679ce:skills/code-review/SKILL.md` the sections sat at `## Deliverable 1: Chat Synthesis` (1126), `## Deliverable 2: Code Review Rubric` (1251), `## Override-Log` (1794). Every range extraction in the four suites resolves in order — the SKILL.md-internal ones (`#### Soundness-contradiction cross-check` 1021 → `#### …`; `#### Executable-defect cross-check` 1033 → `#### Contrastive note` 1126; `#### Fragment-Composition cross-check` 1045 → `#### Contrastive note` 1126) and the rubric-internal ones (`### Escalation Rule` 335 → `### Soundness-Contradiction Channel` 373; `### Soundness-Contradiction Channel` 373 and `### Executable-Defect Channel` 443 → `### Rubric Status Line` 493). All 97 tests pass (Claim 5b's log).

Two residues the comment does not name, both currently latent rather than active defects. (a) The concatenated surface now contains three duplicated `## ` headings — `## Deliverable 1: Chat Synthesis`, `## Deliverable 2: Code Review Rubric`, `## Override-Log` each appear once as a stub in `SKILL.md` and once as the real section in a reference file (`cat … | grep '^## ' | sort | uniq -d`); no current test range-extracts one of them, so nothing breaks today, but a future `sed -n '/^## Deliverable 1/,…'` would capture the stub. (b) `test/skills/code-review-assurance-contract.bats:123` extracts `'/^## Important Reminders/,$p'`, which before the split ended at `SKILL.md`'s EOF and now runs on through all three reference files; the assertion it makes is still satisfied by text genuinely inside Important Reminders (`skills/code-review/SKILL.md:1231`), so the test is not vacuous — but its scope silently widened.

**Evidence:** `test/skills/code-review-assurance-contract.bats:27-34`, `test/skills/code-review-assurance-contract.bats:123`, `test/skills/code-review-soundness-crosscheck.bats:41`, `test/skills/code-review-soundness-crosscheck.bats:107-115`, `test/skills/code-review-executable-defect.bats:38`, `test/skills/code-review-executable-defect.bats:88`, `test/skills/code-review-format-contract.bats:60`, `skills/code-review/SKILL.md:1021-1126`, `skills/code-review/SKILL.md:1231`, `docs/reviews/execution-logs/r3-code-review-bats.txt`

---

## Claim 14: "The rubric template moved into the skill's references/ dir 2026-09-11 (prompt audit F8); the golden fixture is still compared against it."

**Location:** `test/skills/code-review-format-contract.bats:183-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `SKILL_MD` points at the file that now holds the template and that the sync tests over it pass; does not establish that the golden fixture and the template are semantically equivalent beyond what those tests assert.

```bash
# test/skills/code-review-format-contract.bats:185
SKILL_MD="skills/code-review/references/rubric.md"
```

and the template is indeed there — `# Code Review Rubric` opens the fenced block at `skills/code-review/references/rubric.md:30`, with the nine tier sections at `:36`–`:130`. The 18 tests in that suite pass.

**Evidence:** `test/skills/code-review-format-contract.bats:180-190`, `skills/code-review/references/rubric.md:30-130`, `docs/reviews/execution-logs/r3-code-review-bats.txt`

---

## Claim 15: (`4d41add`) "This also kills the last surviving 'Task tool' reference, a regression against skill-format-audit Finding 7."

**Location:** commit `4d41add` message body
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers instructional uses of the stale tool name in skill/workflow/pattern prose; does not establish anything about the two remaining descriptive occurrences, which are the audit finding's own text and a deliberate terminology note.

The instruction is gone — `skills/draft-review/SKILL.md:190` now reads "Dispatch each critique to a sub-agent via the Agent tool." (previously "...via the Task tool"). But "Task tool" is not the *last* occurrence in the repo: `rg -n 'Task tool'` (excluding `archive/`, `external/`, `runs/`, `docs/`, `node_modules/`) still returns four lines — `guides/skill-format-audit.md:148`, `:156`, `:161`, `:167` (the finding itself, which must name the stale term to describe it) and:

```md
<!-- patterns/orchestrated-review.md:31 -->
**Terminology note**: Use "sub-agent" consistently for the parallel execution mechanism, regardless of whether the underlying implementation uses the Task tool, Agent tool, or manual sequential processing.
```

The precise version: *the last surviving instructional "Task tool" reference*. Mechanism and conclusion are both right; the claim is missing that qualifier.

**Evidence:** `skills/draft-review/SKILL.md:190`, `guides/skill-format-audit.md:148-167`, `patterns/orchestrated-review.md:31`

---

## Claim 16: (`4d41add`) "F6: cut the two paragraphs in the always-loaded instructions file that restate decision-tree row 2. The hook cross-reference stays until F5 is decided." / "F9: drop 'The research must be thorough'."

**Location:** commit `4d41add` message body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exact edits in `global-instructions/CLAUDE.md` and `workflows/research-plan-implement.md`; does not establish the F6 row's further claim that the row-3 (`divergent-design`) trim "is not applied" is the right call, which is a judgment, not a checkable fact.

Exactly two paragraphs were removed (the "When a single message bundles 2+ independent tasks…" and "**Recognize a batch.**" paragraphs), and the hook paragraph survives:

```md
<!-- global-instructions/CLAUDE.md:59 -->
A `UserPromptSubmit` hook (`hooks/batch-feedback-routing-reminder.sh`) escalates this row from skimmable prose to a harness-injected, non-blocking reminder when it detects multi-item phrasing — the same escalation pattern as the divergent-design routing reminder.
```

F9:

```md
<!-- workflows/research-plan-implement.md:82 -->
Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.
```

**Evidence:** `global-instructions/CLAUDE.md:47-59`, `workflows/research-plan-implement.md:82`, `git diff -M 2d679ce..HEAD -- global-instructions/CLAUDE.md`

---

## Claim 17: (`4d41add`) "F3/F4/F6 are behavioral and the orchestrator evals in test/skills/ were not run (they need model calls)."

**Location:** commit `4d41add` message body (Notes)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that the claim is self-consistent with the suite layout; does not establish that the evals would have passed or failed, nor that no non-model test covers the F3/F4/F6 prose.

`test/skills/` contains eval suites (`code-fact-check-eval.bats`, `fact-check-eval.bats`, `cross-skill-eval.md`, `generate-reports.bash`) whose fixtures are report *outputs*, and the health-check run emits `⚠ No report outputs found — skipping eval/format BATS (run generate-reports.bash first)` at `docs/reviews/execution-logs/r3-health-check-head.txt:49` — consistent with "not run". Establishing whether they *would* pass requires model calls this sandbox cannot make. **Blocker: execution requires live model API calls; no network egress.**

**Evidence:** `docs/reviews/execution-logs/r3-health-check-head.txt:49`, `test/skills/code-fact-check-eval.bats`, `test/skills/generate-reports.bash`

---

## Claim 18: (`c56be81`) "health-check failures are identical to the pre-change baseline (four, all pre-existing)"

**Location:** commit `c56be81` message body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the *count*; the "identical set, all pre-existing" half is separately true (Claim 20b). Does not establish that the four shellcheck failures are harmless, only that the move did not create or remove any.

`bash scripts/health-check.sh` at HEAD exits 1 with **six** `✗` lines, not four:

```
  ✗ In global-instructions/CLAUDE.md but not AGENTS.md: parallel-worktrees.md
  ✗ In global-instructions/CLAUDE.md but not GEMINI.md: parallel-worktrees.md
  ✗ .apir5-probe2.sh
  ✗ test/auto-approve-allowed-commands.bats
  ✗ test/init-firewall-rules.bats
  ✗ test/cc-isolated-functions.bats
```

(cwd `/workspace`, exit 1, 2026-09-12; captured to `docs/reviews/execution-logs/r3-health-check-head.txt`.) Two belong to the "MD file consistency (workflows)" check and four to shellcheck. The same six are present at the baseline commit (run in a detached worktree at `2d679ce`, captured to `r3-health-check-baseline-2d679ce.txt`), with the first two spelled `In CLAUDE.md but not …`. The commit's "four" apparently counts only the shellcheck block and silently drops the two workflow-cross-reference failures — which are precisely the two whose *text* the change rewrites, so they are the failures a reader would most want counted. Same prior-pattern class as Claim 5b: a specific count presented as measured that the artifact does not carry.

**Evidence:** `docs/reviews/execution-logs/r3-health-check-head.txt`, `docs/reviews/execution-logs/r3-health-check-baseline-2d679ce.txt`, `scripts/health-check.sh:200-243`

---

## Claim 19: (`c56be81`) "agents-gemini-sync, cross-reference-integrity, guide-index-sync and link-claude-home-wiring all pass; the basename staging was simulated against a file entry and a directory entry." / "install.sh is not in enforcement_files(), so no Live-verified trailer is required."

**Location:** commit `c56be81` message body
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named suites passing at HEAD, the reproduced staging simulation, and that neither the manifest's enforcement set nor the commit hook's regex matches `devcontainer-config/install.sh`; does not establish that the four suites meaningfully *exercise* the move — `test/agents-gemini-sync.bats` only diffs `AGENTS.md` against `GEMINI.md` and never reads the instructions file, so its pass is not evidence for this change.

```
$ bats test/agents-gemini-sync.bats test/cross-reference-integrity.bats \
        test/guide-index-sync.bats test/link-claude-home-wiring.bats
EXIT=0     ok: 13     not ok: 0
```

(cwd `/workspace`, exit 0, 2026-09-12.) The staging simulation is Claim 1's. On the gate, the enforcement set is explicit and does not list `install.sh`:

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

(excerpt ends `:115`; the function continues to `:130` — read; the remainder adds `egress/*.txt`, `projects/*.profile` and a `claude-home` walk, none of which reach `install.sh`, which lives in the repo's `devcontainer-config/`, not in `$cfg`.) The hook keys on a mirror of that list:

```bash
# hooks/live-verify-gate.sh:57
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|egress/)'
```

`devcontainer-config/install.sh` does not match, so no trailer was required — and the commit carries none.

**Evidence:** `docs/reviews/execution-logs/r3-four-named-suites.txt`, `docs/reviews/execution-logs/r3-install-basename-sim.txt`, `devcontainer-config/cc-isolated.sh:107-130`, `hooks/live-verify-gate.sh:55-62`, `test/agents-gemini-sync.bats:10-30`

---

## Claim 20a: (`59ca38f`) "Every anchor that crossed the split was rewritten programmatically (none left unresolved), including workflows/pr-prep.md's link to the capture format."

**Location:** commit `59ca38f` message body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every `](…#anchor)` in `SKILL.md`, the three reference files, and the two external referrers resolves to a heading that exists in the named file; does not establish that the link *text* was updated — `workflows/pr-prep.md:183` still displays `skills/code-review/SKILL.md` while pointing at `references/override-log.md`, a cosmetic mismatch the claim does not cover.

A GitHub-style slug resolver run over all anchored links in those six files reported `checked files: 6 … total bad: 0` (cwd `/workspace`, exit 0, 2026-09-12). The three cross-file anchors are:

```md
<!-- skills/code-review/references/rubric.md:513 -->
(see [Deliverable 1](../SKILL.md#deliverable-1-chat-synthesis)). Do not expand it into a paragraph,
<!-- workflows/pr-prep.md:183 -->
[`skills/code-review/SKILL.md`](../skills/code-review/references/override-log.md#capture-format) — Date, PR
<!-- workflows/codebase-onboarding.md:120 -->
[`skills/code-review/SKILL.md`](../skills/code-review/SKILL.md#between-stage-status-banner).
```

all three targets exist. A repo-wide `rg` for `SKILL.md#` / `references/*.md#` outside `archive/`, `external/`, `runs/`, `docs/working/archive/` and `node_modules/` returns exactly those three lines, so there is no fourth external referrer.

**Evidence:** `skills/code-review/references/rubric.md:513`, `workflows/pr-prep.md:183`, `workflows/codebase-onboarding.md:120`, `skills/code-review/SKILL.md:81-92`

---

## Claim 20b: (`59ca38f`) "All 85 tests across the code-review suites pass; cross-reference-integrity passes; health-check failures are unchanged from baseline."

**Location:** commit `59ca38f` message body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Split verdict — "85" is refuted (the true figure is 97) and carries the compound per the most-severe-part rule; "pass", "cross-reference-integrity passes" and "health-check failures unchanged from baseline" are each independently true. Does not establish that the 97 tests cover the split adequately, only that none of them regressed.

The count is refuted exactly as in Claim 5b (97 tests, all `ok`, exit 0). `test/cross-reference-integrity.bats` passes as part of the 13-test run in Claim 19. The health-check failure *set* is unchanged from the `2d679ce` baseline — diffing the `✗` lines across the two runs shows only the expected `CLAUDE.md` → `global-instructions/CLAUDE.md` rename in two messages and a reordering of two shellcheck lines (paraphrased — no quote available because the evidence is a `diff` of two grep outputs; both captured files are cited below). The baseline run additionally shows one `not ok 174 skill invocation is logged with all fields`; that failure is an artifact of running in a detached `git worktree` (the log-usage hook resolves paths relative to the checkout) and does not occur at HEAD in `/workspace`, so it is not a baseline difference attributable to the change.

**Evidence:** `docs/reviews/execution-logs/r3-code-review-bats.txt`, `docs/reviews/execution-logs/r3-health-check-head.txt`, `docs/reviews/execution-logs/r3-health-check-baseline-2d679ce.txt`, `docs/reviews/execution-logs/r3-four-named-suites.txt`

---

## Claim 21: (`59ca38f`) "Still over the 500-line ceiling. The next candidates are Stage 1's dispatch template (~240 lines) and Stage 3's synthesis procedure (~160), both currently pipeline-resident."

**Location:** commit `59ca38f` message body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that `SKILL.md` (1,256 lines) exceeds 500 and that both named regions are still inside `## The Pipeline`; the two size estimates are approximations and were spot-checked for order of magnitude only, not to the line.

`## The Pipeline` opens at `skills/code-review/SKILL.md:238` and the next `## ` heading is `## Deliverable 1: Chat Synthesis` at `:1132`, so both named regions are pipeline-resident across ~894 lines — leaving ample room for a ~240-line dispatch template and a ~160-line synthesis procedure (paraphrased — no quote available because the claim is about the size of two multi-hundred-line regions, not any single snippet).

**Evidence:** `skills/code-review/SKILL.md:238`, `skills/code-review/SKILL.md:1132`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`docs/reviews/prompt-audit-2026-09-11.md:569`): "All 85 tests pass" — the seven `test/skills/code-review-*.bats` suites hold **97** tests (15/10/9/17/18/17/11); no subset of them, with or without `test/code-review-gate.bats` (19), sums to 85. Change the figure to 97 (all passing), or name the exact suite list the 85 was measured over.
- **Claim 18** (commit `c56be81`): "health-check failures are identical to the pre-change baseline (four, all pre-existing)" — the set is identical and all pre-existing, but the count is **six**: four shellcheck failures plus two "MD file consistency (workflows)" failures (`parallel-worktrees.md` missing from `AGENTS.md` and `GEMINI.md`). The two omitted ones are the failures whose message text this very change rewrites. Change "four" to "six", or say "four shellcheck failures plus the two pre-existing workflow-cross-reference failures".
- **Claim 20b** (commit `59ca38f`): same "85 tests" figure as Claim 5b; the rest of the sentence (tests pass, cross-reference-integrity passes, health-check unchanged from baseline) is accurate.

### Stale
- None.

### Mostly Accurate
- **Claim 15** (commit `4d41add`): "kills the last surviving 'Task tool' reference" needs the qualifier *instructional*. Four descriptive occurrences remain by design — `guides/skill-format-audit.md:148,156,161,167` (the finding's own text) and `patterns/orchestrated-review.md:31` (a deliberate terminology note).

### Unverifiable
- **Claim 8** (`scripts/cross-model-review.py:374`): the OpenRouter slug `anthropic/claude-sonnet-5`. The underlying Anthropic model id `claude-sonnet-5` is real and current, and the slug matches the harness's own naming shape, but confirming OpenRouter serves it needs a live `GET https://openrouter.ai/api/v1/models` — blocked (no egress). The audit row already flags this; carry the flag until a host session confirms. Note that `main()`'s fail-closed unpriced-model guard covers `--models`, not `--judge`, so a bad judge slug surfaces as a stage-2 API error rather than a pre-flight abort.
- **Claim 17** (commit `4d41add`): "the orchestrator evals in `test/skills/` were not run" — consistent with the health-check's own `No report outputs found — skipping eval/format BATS` line, but whether they would pass needs live model calls.

### Scope notes worth carrying forward (not verdicts)
- **Claim 13**: the concatenated `SKILL_CONTENT` now contains three duplicated `## ` headings (`Deliverable 1: Chat Synthesis`, `Deliverable 2: Code Review Rubric`, `Override-Log`) — stub in `SKILL.md`, real section in the reference. No current test range-extracts one, so nothing is broken; a future `sed -n '/^## Deliverable 1/,…'` would silently capture the stub.
- **Claim 13**: `test/skills/code-review-assurance-contract.bats:123` extracts `/^## Important Reminders/,$p`, whose `$` now means the end of the *concatenation* rather than the end of `SKILL.md`. The assertion still lands on real Important Reminders text (`skills/code-review/SKILL.md:1231`), so the test is not vacuous — but its scope widened silently.
- **Claim 20a**: `workflows/pr-prep.md:183` displays the link text `skills/code-review/SKILL.md` while the href now points at `references/override-log.md`. The anchor resolves; the label is misleading.
- **Claim 19**: `test/agents-gemini-sync.bats` never reads the instructions file (it diffs `AGENTS.md` against `GEMINI.md` only), so its pass is not evidence about the F1 move.

---

## Goal-Alignment Note

**Answered.** Every "applied" row in the audit's Application status table was checked against the sites it names, including F4's completeness against a repo-wide search; decision-log row 47's basename claim was re-derived by executing the staging loop and read against both `link-claude-home.sh` and the other six `CLAUDE_HOME_SRC` entries; the `c56be81` health-check baseline was re-run at HEAD and at `2d679ce`; the `enforcement_files()` / `live-verify-gate.sh` question was traced to the literal name list and the hook regex; every anchored link in the split skill, its three references and its two external referrers was machine-resolved against real headings; the four `.bats` `SKILL_CONTENT` definitions were checked against the pre-split document order and every range extraction in those suites.

**Out of scope.** Whether the retired numeric cap *should* have been replaced by shape framing, whether the sections that stayed resident are the right ones, and whether the F5 decline is correct are design judgments, not checkable claims. Anything requiring Docker, a host `install.sh` run, network egress, or live model calls stayed Unverifiable rather than being inferred.

**Escalate.** Two independent commit messages and one audit row carry a measured count the artifacts do not support ("85 tests" twice, "four failures" once). Both are the hallucination-log's existing pattern class — a specific number quoted as measured from a checked-in artifact set that does not contain it. Neither is a fabricated symbol, so neither qualifies for `hallucination-patterns.md` under that file's own rules (they are miscounts, not fabrications), but three in one four-commit series is worth naming to the author: the counts in these commit bodies are being written from recollection rather than from the command output, which is the same failure the "Verified:" lines are meant to prevent.

**Questions I would have asked.** (1) Was the "85" measured over a suite list that has since gained tests, or is it an estimate? If the former, naming the list in the audit row would make it re-derivable. (2) Is the `/^## Important Reminders/,$p` range in the assurance suite intended to cover the references too, now that concatenation makes `$` mean something different — or should its end anchor be pinned before the first reference file?
