Commit: 36417f5 (A) / db24c74 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 36417f5; HEAD 92f3a8d adds review docs only, `git diff --stat 36417f5 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at db24c74; read with `git show db24c74:<path>`).
**Scope:** Partial: the pass-17 fix round only. A: `git diff 723c242..36417f5 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of cf18055 and 36417f5. B: `git diff 1f36885..db24c74 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` plus the message of db24c74. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 26
**Summary:** 19 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc18/` (below, `fc18/`). Throwaway repos were built under `mktemp -d` directories inside `fc18/`; every process ran under `timeout`, and none outlived its command. Nothing was written to either worktree except this report.

Executed runs:
- E1 `timeout 600 bats test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` at 2026-10-02T01:05:25-07:00, exit 0, 24/24 ok → `fc18/bats-36417f5.log`; `timeout 60 shellcheck scripts/dev-cycle.sh`, exit 0 → `fc18/shellcheck.log`.
- E2 The 36417f5 test file run against 723c242's `scripts/dev-cycle.sh` and `scripts/questions.sh` (copied into a `mktemp -d` tree under `fc18/`), `timeout 600 bats test/scripts/dev-cycle.bats` at 2026-10-02T01:05:56-07:00, exit 1: only tests 11 (record dates) and 13 (window default) fail, 22 ok → `fc18/bats-old-script-new-tests.log`. (A first run without questions.sh copied also failed 10, 18 and 19 for that reason only; the log was overwritten by the corrected run.)
- E3 `timeout 300 bash fc18/probe.sh <mktemp dir>` at 2026-10-02T01:06:46-07:00, exit 0: builds scenario repos S1–S6 and compares each record's digest date with per-file `git log -1 --format=%ad --date=short` → `fc18/probe-dates.log` (script: `fc18/probe.sh`).
- E4 `git -c core.quotePath=false log --name-only --format=@%ad -- d` on files `a"b`, `a\b`, `é`, `plain`, at 2026-10-02T01:08:07-07:00, exit 0 → `fc18/quoting.log`; GNU `date -d` on four dates → `fc18/date-guard.log`.
- E5 db24c74's `scripts/questions.sh` (byte-identical to `~/.claude/scripts/questions.sh`): `init` twice, `archive`, then `init` and `archive` with a symlinked `questions.md`, in a fresh repo, at 2026-10-02T01:07:46-07:00 → `fc18/questions-init.log` (exits 0, 0, 0, 1, 1).

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 patterns): no claim here matches a logged pattern. Neither Incorrect verdict is a fabricated symbol or API, so nothing is appended.

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or the record).

---

## Claim 1: "Paths relative to the repo root only (no leading `/` or `~`, no `..` or `.git` component), never through a symlink."

**Location:** `docs/dev-cycle.md:26-28`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers agreement with the skill's rule and compliance of the file's one row; does not establish how step 5 expands the glob (that is the skill's symlink-check text, unchanged this round).

The skill gives the same conditions: "Such a path must be relative, must not start with `/` or `~`, and must have no `..` or `.git` component; it is read from the repo root" (`skills/dev-cycle/SKILL.md:64-65`). The only row, `| Feature ideas | docs/working/feature-ideas*.md | ... |` (`docs/dev-cycle.md:32`), passes them.

**Evidence:** `docs/dev-cycle.md:26-32`, `skills/dev-cycle/SKILL.md:61-71`

---

## Claim 2: "Default: the date in the newest cycle-YYYY-MM-DD.md in docs/working/cycles that is a plain file, a real date and not future-dated (only its name is read), else 14 days ago."

**Location:** `scripts/dev-cycle.sh:12-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the choice of the window start; does not establish that the "a newer record ... was skipped" warning applies the real-date check (it does not: a non-plain `cycle-2026-02-30.md` can still be named there, a cosmetic case).

The loop applies the three filters in order:

```bash
# scripts/dev-cycle.sh:154-161
    if ! rawfile "$f"; then
      ...
      skipped "$f" && [[ "$SKIP_AT" == "$f" && "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] && skipped_record="$d"
      continue
    fi
    date -d "$d" >/dev/null 2>&1 || continue  # a name that is not a real date
    [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
```

(excerpt ends :161; enclosing loop continues to :165 — read; `last_record` flows to `SINCE` at :170.) Test 13 adds `cycle-2026-02-30.md` beside `cycle-2026-02-10.md` and still gets "Window: since 2026-02-10" (E1), and fails on 723c242 (E2). The skipped-record branch at :157 has no real-date test, as quoted.

**Evidence:** `scripts/dev-cycle.sh:12-14`, `scripts/dev-cycle.sh:150-182`, `test/scripts/dev-cycle.bats:272-280`, `fc18/bats-36417f5.log`, `fc18/bats-old-script-new-tests.log`

---

## Claim 3: "# a name that is not a real date" (the guard skips it)

**Location:** `scripts/dev-cycle.sh:160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers GNU `date` rejecting impossible calendar dates in the glob's NNNN-NN-NN shape; does not establish behavior on a non-GNU `date` (the script already depends on GNU `date -d` at :175 and :182).

`date -d` rejects `2026-02-30` and `2026-13-01` and accepts `2026-02-28` and `2028-02-29` (E4, `fc18/date-guard.log`). Before the guard, an impossible name became `SINCE` and the run died at the `--since must be a real YYYY-MM-DD date` check (`scripts/dev-cycle.sh:182`); E2 shows test 13 failing on 723c242.

**Evidence:** `scripts/dev-cycle.sh:160`, `scripts/dev-cycle.sh:182`, `fc18/date-guard.log`, `fc18/bats-old-script-new-tests.log`

---

## Claim 4: "Merges list the files their result changed against every parent (combined), as a per-file `git log` counts them."

**Location:** `scripts/dev-cycle.sh:210-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers which files a merge itself contributes to the map (a file differing from every parent, which is when per-file history simplification shows the merge); does not establish that the walk visits the same commits as a per-file walk (it does not: Claims 6a, 6b).

```bash
# scripts/dev-cycle.sh:218-220
  while IFS=$'\t' read -r path day; do last_date["$path"]="$day"; done < <(
    git -c core.quotePath=false log --diff-merges=combined --format='@%ad' --date=short --name-only -- docs/decisions \
      | awk '/^@/ { d = substr($0, 2); next } NF && !seen[$0]++ { print $0 "\t" d }')
```

The new test's conflict-resolved `004-merge.md` gets the merge's date, 2026-03-01, matching per-file `git log -1` (E1, test 11). On 723c242 the same record printed 2026-02-02 (E2 log). The probe's merge rows agree wherever the merge itself changed a record (E3).

**Evidence:** `scripts/dev-cycle.sh:216-221`, `test/scripts/dev-cycle.bats:243-262`, `fc18/bats-old-script-new-tests.log`, `fc18/probe-dates.log`

---

## Claim 5: "A name git still quotes (a quote, backslash or control character) misses the map and falls back to its own lookup."

**Location:** `scripts/dev-cycle.sh:211-213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the quoting classes named and the fallback on a missing key; does not establish anything about names with a leading or trailing tab (control characters, so quoted, so falling back).

With `core.quotePath=false`, git prints `"d/a\"b"` and `"d/a\\b"` quoted and `d/é` raw (E4, `fc18/quoting.log`). The fallback now tests for a missing key, not an empty value or a control character:

```bash
# scripts/dev-cycle.sh:227-228
  d="${last_date[$f]-}"
  [[ -n "${last_date[$f]+set}" ]] || d="$(git log -1 --format=%ad --date=short -- "$f")"
```

(excerpt ends :228; enclosing loop continues to :232 — read; `d` is printed at :230 as `${d:-never, uncommitted}`.) The `'001-a"b'` and `'002-a\b'` records match per-file dates (E1); on 723c242 both printed "never, uncommitted" (E2). An uncommitted record misses the map and prints "never, uncommitted" (E3, S4 `001-U.md`). A quoted key in the map cannot collide with a globbed name, since every globbed name starts with `docs/` and a quoted key starts with `"`.

**Evidence:** `scripts/dev-cycle.sh:211-213`, `scripts/dev-cycle.sh:222-232`, `fc18/quoting.log`, `fc18/bats-old-script-new-tests.log`, `fc18/probe-dates.log`

---

## Claim 6a: "when a merge kept the main line's version of a record but a side branch had changed it later, this date is that later side commit's."

**Location:** `scripts/dev-cycle.sh:213-215`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the stated case with and without another record changing in the merge; does not establish completeness (Claim 6b).

Behavioral, imprecise. The stated difference happens only when the merge's result also differs from the main parent somewhere else under `docs/decisions` (paraphrased — no quote available because the condition comes from git's history simplification over the `docs/decisions` pathspec, not from a script line). If the merge is TREESAME to the main parent on the whole directory, git prunes the side branch from the directory walk too, and the dates agree:

- S1: the side branch changed A and B, and the merge kept main's A and the side's B. A: `map=2026-03-01 perfile=2026-02-01`, DIFF.
- S2: the same, but the side branch changed only A. `SAME ... map=2026-02-01 perfile=2026-02-01`.
- S5b: the side branch changed A and then reverted it, and also changed C. A: `map=2026-03-02 perfile=2026-01-01`, DIFF (also this case).

(all quoted from `fc18/probe-dates.log`)

A more precise version would say "...had changed it later, and the merge changed some other record...".

**Evidence:** `scripts/dev-cycle.sh:213-220`, `fc18/probe.sh`, `fc18/probe-dates.log`

---

## Claim 6b: "One known difference from per-file `git log -1`" (that case is the only one)

**Location:** `scripts/dev-cycle.sh:213`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the symmetric case (a merge that discarded a later main-line change); does not establish other cases such as octopus merges, which were not probed.

A second, undocumented difference, which mirrors the first. In S3 the side branch changed A on 2026-02-01, and main changed A and B on 2026-03-01. The merge took the side's A ("take theirs") and kept main's B. The digest prints main's discarded commit:

```
# fc18/probe-dates.log (S3)
  DIFF docs/decisions/001-A.md map=2026-03-01 perfile=2026-02-01
```

The general rule (paraphrased — no quote available because it is inferred from git's history-simplification rules plus probes S1–S6): the map walks every parent of a merge that differs from all its parents on `docs/decisions`. So the map reports any later change to a record that the merge discarded, from either parent. Per-file `git log -1` follows only the parent whose version the merge kept. S6 (the same "take theirs" with no other record changed) agrees, as Claim 6a predicts. Effect: section 2's "last committed on this branch" date is too new for such a record. Severity is low: it is one informational date, and the trigger text is still printed in full. It needs a merge that drops a newer edit to a record while changing another record. Brief question 1 asked whether the documented difference is the only one: it is not.

**Evidence:** `scripts/dev-cycle.sh:213-220`, `fc18/probe.sh`, `fc18/probe-dates.log`

---

## Claim 7: "The cycle, and every subagent it starts, reads and writes files only by plain paths inside the checkout. This covers every path taken from repo text: a settings row, a brief link, and any file a commit message, decision-log row, plan or question names (step 4 and step 2 read these)."

**Location:** `skills/dev-cycle/SKILL.md:61-64`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the rule's coverage of the path classes the steps read; does not establish that an agent applies it (behavioral compliance is not checkable statically).

Wording. The coverage holds. Step 4 reads "its commit message, decision-log row, or plan" (`SKILL.md:175-176`), and step 2 reads decision records and log rows (`SKILL.md:147-153`). But questions, which the sentence lists, are read in step 3 ("For each open `trigger` or `deferred` entry, check its own condition", `SKILL.md:160-161`) and by step 6's keep-or-drop lookup (`SKILL.md:242-244`), not in steps 2 or 4. The parenthetical should name steps 2, 3, 4 and 6, or be dropped. The rule's own scope ("every path taken from repo text") already covers them, so an agent reading the whole sentence is not misled about whether the rule applies. Other classes: glob matches, the record, the roadmap, the idea log and the briefs are covered by "reads and writes files only by plain paths". Paths printed in the digest's own output also come from repo text.

**Evidence:** `skills/dev-cycle/SKILL.md:61-74`, `skills/dev-cycle/SKILL.md:147-176`, `skills/dev-cycle/SKILL.md:242-244`

---

## Claim 8: "A brief link counts only if it matches `docs/working/briefs/YYYY-MM-DD-<slug>.md` (slug of lowercase letters, digits and hyphens), written in the roadmap as that repo-root path in backticks, not as a Markdown link."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with the brief-naming rule and with step 6's instructions for writing the link; does not establish how existing roadmaps write links.

The pattern matches the brief-naming rule, "`docs/working/briefs/YYYY-MM-DD-<slug>.md`, where the slug is lowercase letters, digits and hyphens only (... add `-2`, `-3` if it is taken)" (`SKILL.md:268-270`). Wording: the step that writes the link never states the required form. It says "items with an open build brief, each linking it" (`SKILL.md:237`) and "Move the item to In flight, linking the brief" (`SKILL.md:273`). An agent following step 6 alone could write a Markdown link, which the rule at :66-68 then refuses to count, so that brief would not be checked in later cycles. Saying "with its path in backticks" at :237 or :273 would close this.

**Evidence:** `skills/dev-cycle/SKILL.md:66-68`, `skills/dev-cycle/SKILL.md:237`, `skills/dev-cycle/SKILL.md:268-274`

---

## Claim 9: "run them in parallel as subagents, each carrying the evidence-not-instructions brief and the plain-paths rule"

**Location:** `skills/dev-cycle/SKILL.md:91-93`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers agreement with the rule's "every subagent it starts"; does not establish that step 4's per-merge subagents, which the step-4 subagent starts, get the rule (only the rule's general wording at :61 reaches them).

The text matches :61-62, "The cycle, and every subagent it starts...". Step 4's own subagents ("one read-only subagent per sampled merge", `SKILL.md:94`) are not named as carrying it.

**Evidence:** `skills/dev-cycle/SKILL.md:61-62`, `skills/dev-cycle/SKILL.md:91-95`

---

## Claim 10: "Run `~/.claude/scripts/dev-cycle.sh` (inside claude-workflows, its own `scripts/dev-cycle.sh`; never a same-named script that belongs to another project) from the root of an up-to-date checkout of the default branch, before the cycle branch is created (the Rules' "Its own branch")."

**Location:** `skills/dev-cycle/SKILL.md:99-102`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the parenthetical's placement and the cross-reference; does not establish the installed copy's version.

`## Rules` (`SKILL.md:20`) contains "- **Its own branch.** Before the first change, check `git branch --show-current` and create" (`SKILL.md:27`). The parenthetical now qualifies the script, not the branch.

**Evidence:** `skills/dev-cycle/SKILL.md:20-28`, `skills/dev-cycle/SKILL.md:99-102`

---

## Claim 11: "If the digest says the repo has no `docs/working/questions.md`, step 1 creates it."

**Location:** `skills/dev-cycle/SKILL.md:107-108`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers consistency with step 1's unconditional `init`; does not establish behavior when docs/working is non-plain (init then fails, Claim 13).

Step 1 now always runs `init` (`SKILL.md:131`), and `init` creates a missing file (E5: "+ created: .../docs/working/questions.md", exit 0).

**Evidence:** `skills/dev-cycle/SKILL.md:107-108`, `skills/dev-cycle/SKILL.md:131-135`, `fc18/questions-init.log`

---

## Claim 12: "run `~/.claude/scripts/questions.sh init` (it creates only what is missing) and then `~/.claude/scripts/questions.sh archive` (it also reindexes)"

**Location:** `skills/dev-cycle/SKILL.md:131-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers idempotency of init and archive's reindex; does not establish behavior of an older installed questions.sh (the installed copy is byte-identical to db24c74's).

```bash
# scripts/questions.sh:425 (db24c74)
        [[ -e "$file" ]] && { echo "  = exists: $file"; continue; }
```

(excerpt ends :425; enclosing `cmd_init` continues to :443 — read.) `cmd_archive` ends with `cmd_index` (`scripts/questions.sh:393`). E5: the second `init` printed "= exists" for both files, exit 0. `archive` printed "✓ indexes regenerated" and "✓ archived 0 entries", exit 0.

**Evidence:** `scripts/questions.sh:374-395`, `scripts/questions.sh:419-443`, `fc18/questions-init.log`

---

## Claim 13: "If either fails, or the digest listed a questions file in section 8, note it in the record and go on: questions that cannot be read this cycle are reported, not guessed."

**Location:** `skills/dev-cycle/SKILL.md:133-135`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that both commands fail visibly (exit 1, no write) on a symlinked questions file; does not establish that an agent notices the exit (the instruction says to).

`assert_write_targets` runs first in both commands (`scripts/questions.sh:377`, `:423`). E5: with `questions.md` a symlink, `init` and `archive` each print "refusing to write: ... is a symlink" and exit 1. The observer is the agent reading the exit status. The instruction tells it to note the failure.

**Evidence:** `scripts/questions.sh:88-100`, `scripts/questions.sh:374-377`, `scripts/questions.sh:419-423`, `fc18/questions-init.log`

---

## Claim 14: "The digest prints every trigger in full: each decision record's `## Revisit triggers` section and each decision-log row that mentions revisiting (a trigger written elsewhere in a record is not found; an output line over 4096 bytes is cut; read the record itself then)."

**Location:** `skills/dev-cycle/SKILL.md:147-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers agreement with the digest's section-2 header line and its two readers; does not establish anything about records the digest skipped (section 8).

`trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }` (`scripts/dev-cycle.sh:204`) reads only that section. Log rows come from `grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit'` (`scripts/dev-cycle.sh:243`). The digest's own line says the same (`scripts/dev-cycle.sh:202`). The 4096-byte cut is in `scrub` (`scripts/dev-cycle.sh:46`).

**Evidence:** `scripts/dev-cycle.sh:46`, `scripts/dev-cycle.sh:202-258`, `skills/dev-cycle/SKILL.md:147-150`

---

## Claim 15: "read the user's answer (the reply they wrote on the entry, such as `Q-NNN: [1]`): one that starts with `[1]`, `1` or `keep` (any case) sets `Kept: <today>` ...; one that starts with `[2]`, `2` or `drop` closes the brief"

**Location:** `skills/dev-cycle/SKILL.md:245-248`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the matching rule as an agent reads it; does not establish where answers are stored (questions.sh has no answer field; the entry grammar is heading, Needs/Opened/Status, body, per `scripts/questions.sh:15-18`).

Wording, two gaps:

- The example reply `Q-NNN: [1]` itself starts with `Q-NNN:`, not `[1]`. The rule needs "after the `Q-NNN:` prefix" to match its own example.
- "Starts with `1`" also matches answers such as `10`, `12 days` or `1 more week?`, and "starts with `drop`" matches `dropdown?` (paraphrased — no quote available because these are counterexamples to a prefix rule, not repo text).

The outcome for the intended answers (`[1]`, `1`, `keep`, `[2]`, `2`, `drop`) is right.

**Evidence:** `skills/dev-cycle/SKILL.md:241-250`, `scripts/questions.sh:13-18`

---

## Claim 16: "Either way add the ID to `Applied:`, so each answer counts once. Any other answer is not applied: leave it off `Applied:` and note it in the record for the user."

**Location:** `skills/dev-cycle/SKILL.md:248-250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the stated handling within one cycle; does not establish a bound on repeats. An unmatched answer is re-read and re-noted every later cycle, with no cap, and step 6.3 re-asks at once (below).

Brief question 2, traced (paraphrased — no quote available because the consequence spans sub-steps 2 and 3 across cycles). An unmatched answered ID stays off `Applied:`. Every later cycle meets it again as "answered ID not yet on its `Applied:` line" and notes it again. Sub-step 3 then requires "no ID on its `Asked:` line is still unanswered" (`SKILL.md:251`). An unmatched answer is answered, so the condition passes. If 14 days have passed since the last `Kept:` (no answer set one), a new keep-or-drop entry is filed in the same cycle, with the same slug (Claim 17). The re-ask is reasonable. The per-cycle re-note of the old ID never ends unless someone edits `Applied:` by hand. That is a design consequence, not a mismatch with the text.

**Evidence:** `skills/dev-cycle/SKILL.md:241-256`

---

## Claim 17: "file one `you: judgment` entry, slug `keep-or-drop-<brief slug>`"

**Location:** `skills/dev-cycle/SKILL.md:253-254`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the slug satisfies questions.sh's heading grammar; does not establish uniqueness (a re-ask reuses the slug, and `check` has no duplicate-slug rule, only duplicate IDs).

`check` requires `^\#\#\#\ Q-[0-9]{3}\ ·\ [a-z0-9-]+$` (`scripts/questions.sh:250`). The brief slug is "lowercase letters, digits and hyphens only" (`SKILL.md:268-269`), so `keep-or-drop-<brief slug>` passes. Duplicate detection is on IDs only: `if [[ " $seen_ids " == *" $id "* ]]` (`scripts/questions.sh:258`).

**Evidence:** `scripts/questions.sh:248-262`, `skills/dev-cycle/SKILL.md:253-256`, `skills/dev-cycle/SKILL.md:268-270`

---

## Claim 18: "# The settings file and the briefs directory are checked like any input."

**Location:** `test/scripts/dev-cycle.bats:220-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the test asserts both appear in section 8 when symlinked; does not establish that it guards this round's change. It also passes on 723c242, which already had the behavior, so it is a regression guard.

The test symlinks both and asserts `"- docs/dev-cycle.md"` and `"- docs/working/briefs/"` in section 8 (`test/scripts/dev-cycle.bats:221-225`). The script lists them via `skipped docs/dev-cycle.md || true` and `skipdir docs/working/briefs || true` (`scripts/dev-cycle.sh:392-393`). Test 10 passes in E1 and in E2.

**Evidence:** `test/scripts/dev-cycle.bats:220-226`, `scripts/dev-cycle.sh:392-393`, `fc18/bats-36417f5.log`, `fc18/bats-old-script-new-tests.log`

---

## Claim 19: "record dates match per-file git log, including quoted names and merge-only changes"

**Location:** `test/scripts/dev-cycle.bats:243-262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers quoted names (`"`, `\`), a plain record and a conflict-resolved merge; does not cover a merge that discarded a later change on either side (Claims 6a, 6b), renames, or uncommitted records (the last two agree in E3, S4).

It passes at 36417f5 (E1) and fails on 723c242 with `001-a"b.md ... never, uncommitted` and `004-merge.md ... 2026-02-02` (E2). So it would catch a revert of either fix.

**Evidence:** `test/scripts/dev-cycle.bats:243-262`, `fc18/bats-36417f5.log`, `fc18/bats-old-script-new-tests.log`

---

## Claim 20: The window test's added `cycle-2026-02-30.md` (an impossible record date is ignored)

**Location:** `test/scripts/dev-cycle.bats:274-276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers a plain impossible-date record; does not cover a non-plain one (the warning path, Claim 2's residue).

Test 13 passes at 36417f5 and fails on 723c242 (E1, E2).

**Evidence:** `test/scripts/dev-cycle.bats:272-280`, `fc18/bats-36417f5.log`, `fc18/bats-old-script-new-tests.log`

---

## Claim 21: "# No open entries: the route line says none."

**Location:** `test/scripts/dev-cycle.bats:354-357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the empty-Open case's "Open by route: none"; it is a regression guard for 723c242's behavior (it passes there too), not for this round.

Test 18 passes in E1 and E2.

**Evidence:** `test/scripts/dev-cycle.bats:350-358`, `fc18/bats-36417f5.log`, `fc18/bats-old-script-new-tests.log`

---

## Claim 22: "fix(dev-cycle): pass-17 digest fixes (record dates exact, impossible record dates)"

**Location:** commit `cf18055` (subject)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the "record dates exact" atom; the "impossible record dates" atom is Verified (Claims 2, 3).

The dates are not exact. 36417f5's comment documents one difference (S1) and the probe shows a second (S3): "DIFF docs/decisions/001-A.md map=2026-03-01 perfile=2026-02-01" (`fc18/probe-dates.log`). Commit subjects cannot be amended here. This matters only to a reader of `git log`, and the code comment is the place to fix it (Claim 6b).

**Evidence:** `fc18/probe-dates.log`, `scripts/dev-cycle.sh:213-215`

---

## Claim 23: cf18055 body: combined merge diffs "as per-file `git log -1` counts them"; "falls back to the per-file lookup on any miss (git still quotes names with " or \, which missed the map)"; "New test ... (fails on 723c242)"; "A cycle record whose name is not a real date (cycle-2026-02-30.md) is ignored instead of becoming the window start and failing the run"; "Tests assert the settings-file and briefs-directory skips and 'Open by route: none'"; "24/24; shellcheck clean."

**Location:** commit `cf18055` (body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers each listed atom; "as per-file counts them" covers what a merge contributes (Claim 4), not walk equivalence (Claim 6b).

Each atom is covered by E1 (24 ok, shellcheck exit 0), E2 (tests 11 and 13 fail on 723c242), E4 (quoting) and Claims 3–5, 18 and 21.

**Evidence:** `fc18/bats-36417f5.log`, `fc18/shellcheck.log`, `fc18/bats-old-script-new-tests.log`, `fc18/quoting.log`

---

## Claim 24: "a merge that discarded a later side change reports the side commit's date; documented rather than claimed exact."

**Location:** commit `36417f5` (body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Same as Claim 6a; the omission of the main-line mirror case is carried by Claim 6b.

True for the stated case when the merge also changed another record (S1, S5b). No difference when it did not (S2) (`fc18/probe-dates.log`).

**Evidence:** `fc18/probe-dates.log`, `scripts/dev-cycle.sh:213-215`

---

## Claim 25: db24c74 body: the path rule "covers the cycle and every subagent it starts, and every path taken from repo text ... read from the repo root, with no `/`, `~`, `..` or `.git`"; brief-link form; "Subagent briefs carry the rule"; answer matching; "The entry's slug is keep-or-drop-<brief slug>"; "Step 1 always runs questions.sh init (idempotent) then archive, and reports instead of guessing if either fails"; "Step 2 carries the trigger-coverage caveat; step 0's parenthetical is placed correctly."

**Location:** commit `db24c74` (body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that the diff makes each stated change; the wording gaps in the changed text are carried by Claims 7, 8 and 15, and the unbounded re-note by Claim 16.

Each atom maps to a hunk of `git diff 1f36885..db24c74` (`SKILL.md:61-68`, `:91-93`, `:99-102`, `:131-135`, `:147-149`, `:245-256`; `docs/dev-cycle.md:27-28`), and to Claims 1, 9–14 and 17. Idempotency was executed in E5 (Claim 12).

**Evidence:** `skills/dev-cycle/SKILL.md:61-68`, `skills/dev-cycle/SKILL.md:91-102`, `skills/dev-cycle/SKILL.md:131-149`, `skills/dev-cycle/SKILL.md:245-256`, `docs/dev-cycle.md:26-28`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`scripts/dev-cycle.sh:213`): **behavioral.** "One known difference" leaves out the mirror case: a merge that kept the side's version while the main line had changed the record later prints the discarded main commit's date (S3). Reword it as "any later change a merge discarded, from either parent, when the merge also changed another record". Low severity.
- **Claim 22** (commit `cf18055` subject): **behavioral, in a commit message.** "record dates exact" is refuted by S1 and S3. It cannot be amended; the code comment (6b) carries the fix.

### Stale
- None.

### Mostly Accurate
- **Claim 6a** (`scripts/dev-cycle.sh:213-215`): **behavioral precondition.** The difference needs the merge to change some other record too (S2 shows none otherwise).
- **Claim 7** (`skills/dev-cycle/SKILL.md:61-64`): **wording.** "(step 4 and step 2 read these)" leaves out steps 3 and 6, which read questions.
- **Claim 8** (`skills/dev-cycle/SKILL.md:66-68` vs `:237`, `:273`): **wording.** Step 6 says "linking the brief" without the required backticked-path form, so a Markdown link written there would not count.
- **Claim 15** (`skills/dev-cycle/SKILL.md:245-248`): **wording.** "Starts with" does not fit its own example `Q-NNN: [1]` (the prefix comes first), and a bare `1` or `drop` prefix also matches `10…` or `dropdown…`.
- **Claim 24** (commit `36417f5` body): **behavioral precondition.** Same as 6a.

### Unverifiable
- None.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass18.md`. It has the required first line, the header fields (including `**Replication:** k=1 (loop pass, decision 031)`), the seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary.

Against the round's aims:
- **Date map:** it now matches per-file `git log -1` for quoted names, merge-resolved, merge-added, renamed and uncommitted records. It differs in the documented case (only when the merge changed another record too) and in an undocumented mirror case (6b).
- **Impossible-date guard:** correct and tested.
- **New tests:** two of them (record dates, impossible date) would catch a revert. The settings/briefs and "none" tests guard behavior that was already there.
- **Skill changes:** they hold as stated. The remaining gaps are wording (7, 8, 15) plus one design consequence: an unmatched keep-or-drop answer is re-noted every cycle with no end, and step 6.3 re-asks under the same slug (16).
