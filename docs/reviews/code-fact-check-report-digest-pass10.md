Commit: b88a9c4 (A) / 79b1bfe (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at b88a9c4; HEAD 219408d adds only review docs, `git diff --stat b88a9c4 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 79b1bfe = HEAD; its `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats` are byte-identical to b88a9c4's, `git diff --stat b88a9c4 79b1bfe -- <both>` is empty)
**Scope:** Partial, the pass-9 fix round only. A: `git diff d503a43..b88a9c4 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus commit message b88a9c4. B: `git diff 1ae9b21..79b1bfe -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/roadmap.md docs/decisions/log.md docs/working/questions.md docs/working/seed-build-loop-handoff.md global-instructions guides/skill-creation.md workflows/codebase-onboarding.md`, reviewed as the result at 79b1bfe, plus commit message 79b1bfe (8b3a8ad only where its text survives). Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 19 verified, 6 mostly accurate, 2 stale, 2 incorrect, 0 unverifiable

Execution logs (scratch, not committed): `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/` holds `logs/bats.out` + `logs/bats.ts`, `logs/shellcheck.out`, `probe.sh` + `logs/probe.out` + `logs/probe.ts`, `logs/digestB.out` + `logs/digestB.ts`, and `skill-8b.md` (the skill at 8b3a8ad, extracted for the verbatim comparison). Every probe ran under `timeout` inside a `mktemp -d` repo that its trap removed.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read: it has no entries under `## Patterns`, so no claim matches a logged pattern. No Incorrect verdict below is a fabrication (both are behavior mismatches), so the log needs no new entry.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script or tests), **user** (the human answering Q-103 or reading the docs).

---

## Claim 1: "ready Now items get build briefs in step 6 (at most 3 open), which land with the cycle branch and are handed to the user; launching autonomous build loops from the cycle is split out as its own unit (roadmap "Build-loop handoff", `docs/working/seed-build-loop-handoff.md`) … a per-project build-loop policy in `docs/dev-cycle.md`, set during onboarding and read by that unit"

**Location:** `docs/decisions/log.md:91`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row 68's description of step 6's briefs, the cap, the landing, the split-out unit and who reads the policy, against the skill at 79b1bfe; does not establish the row's historical rationale column (user comments, double-diamond gaps), which is a record, not code.
**Legibility-target:** user

The skill writes the briefs in step 6 under a cap of 3 open: `skills/dev-cycle/SKILL.md:224-225` "Take the Now items whose first step needs no open choice (no open `you: judgment` names them), while fewer than 3 briefs are open, counting earlier cycles'." They land with step 7 and go to the user: `skills/dev-cycle/SKILL.md:228-229` "The briefs land with step 7, so they are on the default branch when the user starts one." and `:261-263` "each open build brief by path, so the user can start any of them". The split unit and its seed exist: `docs/roadmap.md:17` "- **Build-loop handoff** (follows this dev cycle)" and `docs/working/seed-build-loop-handoff.md:1` "# Seed: the dev cycle's build-loop handoff (split out 2026-10-01)". The skill does not read the policy: `skills/dev-cycle/SKILL.md:57-58` "recorded for the build-loop handoff, which this skill does not run yet. This skill does not read it."

**Evidence:** `docs/decisions/log.md:91`, `skills/dev-cycle/SKILL.md:57-58`, `skills/dev-cycle/SKILL.md:224-229`, `skills/dev-cycle/SKILL.md:261-263`, `docs/roadmap.md:17`, `docs/working/seed-build-loop-handoff.md:1`

---

## Claim 2: "Codebase onboarding asks the user for the build-loop policy (its step 13)"

**Location:** `docs/dev-cycle.md:3-5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that onboarding's step 13 contains the policy question; does not establish that the installed `~/.claude/workflows/codebase-onboarding.md` carries the same text.
**Legibility-target:** user

`workflows/codebase-onboarding.md:447` "### 13. Gate — validate with the team", and inside that step `:453` "Also settle the project's **build-loop policy** with the user". The skill names the same step: `skills/dev-cycle/SKILL.md:56` "codebase onboarding's step 13 asks the user for it".

**Evidence:** `workflows/codebase-onboarding.md:447`, `workflows/codebase-onboarding.md:453`, `skills/dev-cycle/SKILL.md:56`

---

## Claim 3: "Read by the build-loop handoff (roadmap item "Build-loop handoff"; not built yet), not by the dev-cycle skill itself. … `review`: the loop runs pr-prep's review-fix loop and stops; the cycle then asks the user … and merges once approved."

**Location:** `docs/dev-cycle.md:9-15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that neither the skill nor the digest reads the policy at 79b1bfe and that the `self-merge`/`review` descriptions match the seed's design items 1 and 3; does not establish that the future unit will implement them (it does not exist).
**Legibility-target:** user

The skill says it does not read it (`skills/dev-cycle/SKILL.md:57-58`, quoted in Claim 1), and the digest never names the file (paraphrased — no quote available because the claim covers absence of code: `grep -n "Build-loop\|dev-cycle.md" scripts/dev-cycle.sh` returns no line). The `review` description matches the seed: `docs/working/seed-build-loop-handoff.md:27-28` "The cycle files the merge or stop entries on the default branch and performs approved merges." The `self-merge` carve-out points at the seed's list: `docs/working/seed-build-loop-handoff.md:32-35` "Self-merge only for work outside what later runs follow unreviewed (hooks, enforcement and harness settings, instruction files, `skills/`, `workflows/`, `scripts/`, `guides/`, `patterns/`, `templates/`, `test/`, `devcontainer-config/`)". The doc's own list ends "and similar" and defers to the seed, so it is not a closed list.

**Evidence:** `docs/dev-cycle.md:9-15`, `skills/dev-cycle/SKILL.md:57-58`, `scripts/dev-cycle.sh` (grep, no hits), `docs/working/seed-build-loop-handoff.md:26-35`

---

## Claim 4: "The handoff design counts the setting as made only when the file has exactly one line, outside code blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a trailing CR is ignored). Anything else counts as unset, which means `review`."

**Location:** `docs/dev-cycle.md:17-19`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the handoff design record (the seed) carries this rule; does not establish any parser's behavior (none exists at 79b1bfe).
**Legibility-target:** user

The rule is right as a design, but the two qualifiers are not in the design record the doc attributes it to. The seed's item says only `docs/working/seed-build-loop-handoff.md:29-30` "Policy: set only by one exact `Build-loop policy:` line of `self-merge` or `review`; anything else is `review`." The "outside code blocks" and "trailing CR" qualifiers lived in the skill's Project-settings text at 8b3a8ad (`skill-8b.md:55-56` "set when the file has exactly one line, outside code blocks, reading exactly … (a trailing CR is ignored)"), which the seed does not quote (it quotes only step 6 and 6b, `docs/working/seed-build-loop-handoff.md:45`, `:96`). Precise version: either add the two qualifiers to seed item 2, or say "this file states the rule the handoff must follow". Wording: today this file is itself the only place the full rule survives, so nothing is lost while it stays.

**Evidence:** `docs/dev-cycle.md:17-19`, `docs/working/seed-build-loop-handoff.md:29-30`, `docs/working/seed-build-loop-handoff.md:45`, `docs/working/seed-build-loop-handoff.md:96`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/skill-8b.md:55-56`

---

## Claim 5: "**Build-loop handoff** (follows this dev cycle) … First step: read `docs/working/seed-build-loop-handoff.md` and plan a small script … Q-103 waits on it." (with commit 79b1bfe's note: "the handoff item went under Now … rather than into Next, which is at its five-item cap")

**Location:** `docs/roadmap.md:17-21`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the item's placement under Now, the seed path, Q-103's deferral pointing at it, and Next holding exactly five items; does not establish the ranking judgment.
**Legibility-target:** user

The item sits under `## Now` (`docs/roadmap.md:13`) before `## In flight` (`:23`). Q-103 is deferred on it: `docs/working/questions.md:52` "the handoff was split out of `feat/dev-cycle`; nothing reads this setting until it lands. Becomes `you: judgment` then." Next's count was run: an awk count of numbered items under `## Next` printed `5`, and the digest's section 7 on B printed "- Roadmap Next: 5 item(s)" and "- Roadmap Now: 2 item(s)".

Provenance: command `DEV_CYCLE_TODAY=2026-10-01 timeout 120 bash scripts/dev-cycle.sh`, cwd `/workspace/.claude/wt-devcycle`, exit 0, at 2026-10-01T22:16:54-07:00.

**Evidence:** `docs/roadmap.md:13-23`, `docs/working/questions.md:52`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/digestB.out`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/digestB.ts`

---

## Claim 6: "**[2] self-merge** | Each loop lands its branch through pr-prep's local merge on its own, but only for work outside skills/, workflows/, scripts/, test/, guides/ and instruction files; anything else still stops for review"

**Location:** `docs/working/questions.md:57`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the option's exclusion list against the seed's design item 3; does not establish the option's cost estimate ("mostly docs").
**Legibility-target:** user

The list is presented as complete ("only for work outside …") but the seed's design excludes more: `docs/working/seed-build-loop-handoff.md:32-35` adds "hooks, enforcement and harness settings", "`patterns/`, `templates/`" and "`devcontainer-config/`". `docs/dev-cycle.md:12` avoids this with "and similar; the handoff seed … lists them". Precise version: add those four, or end with "and the rest the seed lists". Wording: the option overstates what self-merge would allow, in the safe direction for the reader's risk estimate it understates; no code reads it.

**Evidence:** `docs/working/questions.md:57`, `docs/working/seed-build-loop-handoff.md:32-35`, `docs/dev-cycle.md:11-13`

---

## Claim 7: "**Interim:** [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`; the skill counts that line as unset (so `review`) and does not re-ask while this entry is open."

**Location:** `docs/working/questions.md:59`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what reads the policy line at 79b1bfe; does not establish what the future handoff unit will do.
**Legibility-target:** user

This was true at 8b3a8ad, where the skill parsed the line (`skill-8b.md:55-56`, quoted in Claim 4). At 79b1bfe the skill no longer reads it: `skills/dev-cycle/SKILL.md:57-58` "This skill does not read it." The same entry's own new line contradicts this one: `docs/working/questions.md:52` "nothing reads this setting until it lands". It is the one sentence in B that still assumes the skill parses the policy, which the brief asks to flag. Precise version: "the handoff design counts that line as unset (so `review`); nothing reads it until the handoff lands." Wording: no code acts on it.

**Evidence:** `docs/working/questions.md:52`, `docs/working/questions.md:59`, `skills/dev-cycle/SKILL.md:56-58`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/skill-8b.md:55-56`

---

## Claim 8: "**On either answer:** in `docs/dev-cycle.md`, replace the policy line with `Build-loop policy: review` ([1]) or `Build-loop policy: self-merge` ([2]) and delete the paragraph starting "Interim note:"."

**Location:** `docs/working/questions.md:60`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both edit targets exist in `docs/dev-cycle.md` and that the result satisfies the exact-line rule; does not establish that the paragraph is the only interim marker in the repo.
**Legibility-target:** user

`docs/dev-cycle.md:7` "Build-loop policy: review (interim; Q-103)" and `:21` "Interim note: the "(interim; Q-103)" on the policy line keeps it unset until Q-103 is". After the edit the only policy line would be one of the two exact values the rule at `:17-19` accepts.

**Evidence:** `docs/dev-cycle.md:7`, `docs/dev-cycle.md:17-22`, `docs/working/questions.md:60`

---

## Claim 9: "The text below is the skill's step 6/6b wording at 8b3a8ad, unreviewed after its last fix." (and the two quoted blocks)

**Location:** `docs/working/seed-build-loop-handoff.md:43-129`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both fenced blocks are verbatim substrings of `skills/dev-cycle/SKILL.md` at 8b3a8ad; does not establish that they are the whole of step 6 (the roadmap template and the step's opening are not quoted, consistent with the heading "step 6 In flight and queue").
**Legibility-target:** maintainer

Extracted the skill at 8b3a8ad to `skill-8b.md`, took the seed's lines 48-93 and 99-129, and tested each as a substring in python3: both printed `True`. The 6b block runs from 8b3a8ad's `### 6b. Handoff to build loops` (`skill-8b.md:291`) to "to find them." (`skill-8b.md:321`), the section's end.

Provenance: command `git show 8b3a8ad:skills/dev-cycle/SKILL.md > fc10/skill-8b.md; sed -n 48,93p …; sed -n 99,129p …; python3 substring check`, cwd `/workspace/.claude/wt-devcycle`, exit 0, 2026-10-01 (run before the bats log, 22:1x -07:00); output `seedA.md True`, `seedB.md True`, kept in this report since the scratch files `seedA.md`/`seedB.md` are the compared inputs.

**Evidence:** `docs/working/seed-build-loop-handoff.md:43-129`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/skill-8b.md:213-257`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/skill-8b.md:291-321`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/seedA.md`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/seedB.md`

---

## Claim 10: Seed design items 1–5 ("A loop writes only to its own branch …"; "at merge time a loop follows the stricter of its brief and the default branch's current setting"; the self-merge exclusion list; the In-flight outcomes; "the digest's `inrepo` already enforces this") and its references (rubric sections "Pass 6" to "Pass 9", reports `docs/reviews/*digest-pass{6,7,8,9}*.md`)

**Location:** `docs/working/seed-build-loop-handoff.md:3-39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each item summarises the 8b3a8ad text it records and that the cited reviews exist; does not establish that the design is sound (the seed itself says it is to be re-verified), nor that item 5's "already enforces" covers writes (the digest only reads).
**Legibility-target:** maintainer

Item 2's "stricter of" matches `skill-8b.md` 6b text quoted at seed `:116-120` "If every check passes and that policy is still self-merge, it lands the branch … A loop cannot raise its own policy, and the user can lower it for loops already running." Item 3's list matches seed `:87-90` (8b3a8ad text). Item 4 matches seed `:51-60`. Item 5: `scripts/dev-cycle.sh:92` "inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }" guards every digest read. The rubric has `## Pass 6` … `## Pass 9` headings at `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:314`, `:332`, `:351`, `:370`, and `ls docs/reviews` shows code-fact-check reports for passes 6–9 and api/security/performance reports for 7–9.

**Evidence:** `docs/working/seed-build-loop-handoff.md:3-39`, `docs/working/seed-build-loop-handoff.md:51-60`, `docs/working/seed-build-loop-handoff.md:87-90`, `docs/working/seed-build-loop-handoff.md:116-120`, `scripts/dev-cycle.sh:92`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:314-370`

---

## Claim 11: Global row 12: "… roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's step list and its new ending against the skill; does not establish the installed `~/.claude/CLAUDE.md` (it still says "hands ready items to autonomous build loops" until install, outside this scope).
**Legibility-target:** agent

`skills/dev-cycle/SKILL.md:4` "then hand build briefs for the top roadmap items to the user" and `:16-17` "It runs when the user starts it; there is no timer." No autonomous launch remains in the row.

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:14-17`

---

## Claim 12: "`dev-cycle` | **Adequate** | Workflow-shaped (steps 0–7, with step 4b added and steps 4b and 5 conditional) but … a skill: Claude completes it in one pass given the digest, with no human checkpoint mid-run beyond the Operating Modes approvals for commits and merges"

**Location:** `guides/skill-creation.md:137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step list and the absence of a skill-owned gate at 79b1bfe; does not establish the guide's classification criteria themselves.
**Legibility-target:** maintainer

The skill's flow is `skills/dev-cycle/SKILL.md:79-80` "0 digest → 1 health and cleanup → { 2 triggers | 3 questions | 4 spot-check | 4b audit check } → 5 brainstorm (conditional) → 6 roadmap and build briefs → 7 close (lands the branch) → final message", with no step 6b. The 8b3a8ad gate ("Under /active the user confirms this queue now (this skill's own gate)", seed `:76`) is gone from step 6 (`skills/dev-cycle/SKILL.md:224-229`); re-ranking goes to an entry, not a pause (`:221-222`).

**Evidence:** `guides/skill-creation.md:137`, `skills/dev-cycle/SKILL.md:79-80`, `skills/dev-cycle/SKILL.md:221-229`, `docs/working/seed-build-loop-handoff.md:76`

---

## Claim 13: "Every revisit trigger is printed every run (an output line over 4096 bytes is cut)" and "cuts lines longer than 4096 bytes as the scrub receives them (before controls are removed)"

**Location:** `scripts/dev-cycle.sh:16`, `scripts/dev-cycle.sh:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the cut and the control deletion in `scrub` and that every output line passes through it; does not establish the 4096 count includes the newline (it does not: the newline is stripped before measuring).
**Legibility-target:** maintainer

```perl
# scripts/dev-cycle.sh:44-47
    my $nl = s/\n\z//;
    $_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;
    $_ .= "\n" if $nl;
    tr/\000-\010\013-\037\177//d;
```
(excerpt ends :47; enclosing perl body continues to :56 with the multi-byte deletions and `print` — read)

The cut precedes `tr` and the multi-byte loop, so the measured length is the body's output line before any control is removed. Both streams pass through `scrub`: `scripts/dev-cycle.sh:67` "{ DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub".

**Evidence:** `scripts/dev-cycle.sh:16`, `scripts/dev-cycle.sh:30`, `scripts/dev-cycle.sh:40-57`, `scripts/dev-cycle.sh:66-69`

---

## Claim 14a: "An input that exists in some form but fails inrepo is skipped, not absent: it … is listed in section 8."

**Location:** `scripts/dev-cycle.sh:93-94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every input kind (cycle records, decision records, the decision log, questions.md, the roadmap, the idea log), reached through a file symlink or a symlinked parent directory, each listed exactly once in section 8, and a plain repo listing nothing; does not establish the inline naming (Claim 14b) or the label used for a non-symlink non-regular path (Claim 15).
**Legibility-target:** maintainer

```bash
# scripts/dev-cycle.sh:95-96
SKIPPED=()
skipped() { if [[ -e "$1" || -L "$1" ]] && ! inrepo "$1"; then SKIPPED+=("$1"); return 0; fi; return 1; }
```

Every read site calls it on failure: `:123` and `:159` "inrepo "$f" || { skipped "$f" || true; continue; }", `:180` "skipped docs/decisions/log.md || true", `:205`, `:227`, `:277` `elif skipped …`, `:296` "elif skipped "$LOG"; then". Section 8 dedupes: `:307` "printf '%s\n' "${SKIPPED[@]}" | sort -u | while IFS= read -r f; do echo "- ${f//$'\n'/ }"; done". The roadmap is added twice (sections 5 and 7) and printed once (probe: a lone symlinked roadmap printed one "- docs/roadmap.md" line). A plain repo with a roadmap, idea log, log and cycle record printed "None: no input is reached through a symlink." A symlinked `docs/working` directory listed `docs/working/idea-log.md` and `docs/working/questions.md` once each. A plain path cannot be listed: `skipped` requires `! inrepo`, and `inrepo` fails for a regular file only when its real path differs from `$ROOT_REAL/$1`, which (with `ROOT_REAL="$(pwd -P)"`, `:88`) means a symlink component (paraphrased — no quote available because the case analysis spans `:88`, `:92` and `:96` together). Bats test 6 (`test/scripts/dev-cycle.bats:126-154`) asserts all seven paths in section 8; 20/20 pass.

Provenance: (1) `timeout 300 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-10-01T22:1x-07:00 (timestamp in `bats.ts`); (2) `bash fc10/probe.sh /workspace/.claude/wt-digest/scripts/dev-cycle.sh` (each run `DEV_CYCLE_TODAY=2026-03-01 timeout 60 bash "$DC"` in a fresh `mktemp -d` repo), exit 0, timestamp in `probe.ts`.

**Evidence:** `scripts/dev-cycle.sh:88-96`, `scripts/dev-cycle.sh:123`, `scripts/dev-cycle.sh:159`, `scripts/dev-cycle.sh:180`, `scripts/dev-cycle.sh:205`, `scripts/dev-cycle.sh:227`, `scripts/dev-cycle.sh:277`, `scripts/dev-cycle.sh:296`, `scripts/dev-cycle.sh:302-308`, `test/scripts/dev-cycle.bats:126-154`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/bats.out`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/probe.out`

---

## Claim 14b: "it is named where it would have been read"

**Location:** `scripts/dev-cycle.sh:93-94`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inline text printed at each read site for a skipped input; does not establish that section 8 is missing anything (it is complete, Claim 14a).
**Legibility-target:** maintainer

Only questions.md (`:206`), the roadmap (`:228`, `:278`) and the idea log (`:297`) get an inline note. The other three kinds are skipped silently at their read site, and two of them then print the absent reading:

- A skipped cycle record leaves `last_record` empty, so the Window line uses the absent branch, unchanged by b88a9c4: `scripts/dev-cycle.sh:133` "source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"". Probe P1 (one symlinked `cycle-2026-02-01.md`, nothing else) printed "Window: since 2026-02-15 (from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record))." while section 8 listed `docs/working/cycles/cycle-2026-02-01.md`.
- A skipped `docs/decisions/log.md` with no other trigger source: `:182` "[[ $found -eq 1 ]] || echo "No revisit triggers recorded."". Probe P2 printed "No revisit triggers recorded." with section 8 listing `docs/decisions/log.md`. A lone symlinked `001-x.md` record did the same.

Section 8's header ("Absent from the sections above, not missing from the repo", `:306`) partly compensates, but the Window line's "did not write its record" is an assertion about the previous cycle, and the skill acts on it (Claim 20). Precise version: either print a note at `:123`/`:133`/`:159`/`:180-182` (e.g. "no readable cycle record (one skipped, section 8)"), or narrow the comment to "questions, roadmap and idea log are named where they would have been read". Behavioral.

Provenance: as Claim 14a's probe (P1, P2 and the decision-record case in `probe.out`).

**Evidence:** `scripts/dev-cycle.sh:121-134`, `scripts/dev-cycle.sh:158-182`, `scripts/dev-cycle.sh:205-206`, `scripts/dev-cycle.sh:227-228`, `scripts/dev-cycle.sh:296-297`, `scripts/dev-cycle.sh:306`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/probe.out`

---

## Claim 15: "docs/roadmap.md is reached through a symlink: NOT read (section 8)." / section 8's "Reached through a symlink, so not read." (the label the skipped path gets)

**Location:** `scripts/dev-cycle.sh:96`, `scripts/dev-cycle.sh:206`, `scripts/dev-cycle.sh:228`, `scripts/dev-cycle.sh:306`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label for paths that exist but are not regular files; does not establish any read of such a path (none happens).
**Legibility-target:** maintainer

`skipped` fires on anything that exists and fails `inrepo`, and `inrepo` also fails for a non-regular file (`[[ -f "$1" ]]`, `:92`). Probe P3 (a directory named `docs/roadmap.md`, no symlink anywhere) printed "docs/roadmap.md is reached through a symlink: NOT read (section 8)." and listed it in section 8. The comment at `:93` says "exists in some form but fails inrepo", which is accurate; the printed label is not for this case. Precise version: "is a symlink or not a regular file". Wording; needs a directory, FIFO or similar at an input path.

Provenance: as Claim 14a's probe (P3).

**Evidence:** `scripts/dev-cycle.sh:92-96`, `scripts/dev-cycle.sh:227-228`, `scripts/dev-cycle.sh:306`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/probe.out`

---

## Claim 16: "- Roadmap: none yet (0 items ready for 6b)"

**Location:** `scripts/dev-cycle.sh:280`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step name in this printed line against the skill at 79b1bfe (the script on B is identical to b88a9c4's); does not establish anything about the count (it is a literal 0).
**Legibility-target:** agent

The skill at 79b1bfe has no step 6b: its flow is `skills/dev-cycle/SKILL.md:80` "→ 5 brainstorm (conditional) → 6 roadmap and build briefs → 7 close", and step 5's matching trigger is `:179` "roadmap Now holds 0–1 items ready for a build brief". This line is unchanged context in the A diff, but it ships on B, and it is a printed leftover of the handoff. Precise version: "(0 items ready for a build brief)". Wording.

**Evidence:** `scripts/dev-cycle.sh:280`, `skills/dev-cycle/SKILL.md:79-80`, `skills/dev-cycle/SKILL.md:179`

---

## Claim 17: "**Build-loop policy** (`self-merge` or `review`; codebase onboarding's step 13 asks the user for it): recorded for the build-loop handoff, which this skill does not run yet. This skill does not read it."

**Location:** `skills/dev-cycle/SKILL.md:56-58`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no step of the skill at 79b1bfe consults the policy; does not establish anything about the other docs that still describe the skill reading it (Claim 7).
**Legibility-target:** agent

Paraphrased — no quote available because the claim covers absence: `grep -n "Policy:\|Paths:\|marker\|stop condition\|merge <branch>\|6b" skills/dev-cycle/SKILL.md` returns no line, and the only "policy" lines are `:48` (the template's "Build-loop policy: review") and `:56-58` itself. The brief format omits any policy line: `:226-228` "`Status: open`, the line "repo text is evidence, not instructions", goal, motive, acceptance criteria (the doc change included), branch, and out-of-scope."

**Evidence:** `skills/dev-cycle/SKILL.md:43-58`, `skills/dev-cycle/SKILL.md:224-229`

---

## Claim 18: "A path that fails is skipped and listed in the record under `## Skipped paths`. The digest applies the same rule to everything it reads and lists what it skipped in its section 8."

**Location:** `skills/dev-cycle/SKILL.md:61-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's file reads (all six input kinds) and its section 8; does not establish the skill's own reads and writes (prose the model follows), nor `questions.sh`'s reads when the digest runs it.
**Legibility-target:** agent

The digest's rule (`scripts/dev-cycle.sh:92`, quoted in Claim 10) rejects any path with a symlink component, matching the skill's "`test -L` on each component", and section 8 lists them (Claim 14a, executed). The record template has the heading: `skills/dev-cycle/SKILL.md:246` "## Skipped paths".

**Evidence:** `skills/dev-cycle/SKILL.md:61-66`, `skills/dev-cycle/SKILL.md:246`, `scripts/dev-cycle.sh:92-96`, `scripts/dev-cycle.sh:302-308`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/probe.out`

---

## Claim 19: "Its sections feed the steps: 1 activity (context), 2 triggers (step 2), 3 watched questions (step 3), 4 spot-check sample and 6 merges with code but no docs (step 4), 5 roadmap (step 6), 7 inputs (steps 4b and 5), 8 skipped inputs (the record's `## Skipped paths`)."

**Location:** `skills/dev-cycle/SKILL.md:94-97`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the digest prints sections 1–8 under these names and the record has the target heading; does not establish that the model copies section 8 faithfully.
**Legibility-target:** agent

The digest prints "## 1. Activity" (`scripts/dev-cycle.sh:142`) through "## 8. Skipped inputs" (`:302`); bats test 1 asserts all eight headings (`test/scripts/dev-cycle.bats:40-42`, "## 7. Inputs for steps 4b and 5" "## 8. Skipped inputs"), and it passed (20/20). The record template carries `## Skipped paths` (`skills/dev-cycle/SKILL.md:246`).

Provenance: as Claim 14a's bats run.

**Evidence:** `skills/dev-cycle/SKILL.md:94-97`, `scripts/dev-cycle.sh:142-302`, `test/scripts/dev-cycle.bats:40-42`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/bats.out`

---

## Claim 20: "If the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7: note it in this record and rerun with `--since` set to that cycle's date."

**Location:** `skills/dev-cycle/SKILL.md:98-101`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inference when the last record exists but is reached through a symlink; does not establish the inference for the ordinary missing-record case (correct).
**Legibility-target:** agent

When the cycle's record is a committed symlink, the digest prints "no cycle record found … did not write its record" (Claim 14b, probe P1) and lists it in section 8. The step then concludes "that cycle skipped step 7", which is false: it wrote a record that is unreadable. The rerun with `--since` gives the right window either way. Precise version: add "unless section 8 lists that cycle's record". Mostly accurate rather than Incorrect because the remedy is right and the precondition (a symlinked record on the default branch) needs a commit the skill itself never makes. Behavioral, low.

**Evidence:** `skills/dev-cycle/SKILL.md:98-101`, `scripts/dev-cycle.sh:121-134`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/probe.out`

---

## Claim 21: "The digest prints every trigger in full (a printed line over 4096 bytes is cut; read the record itself then)."

**Location:** `skills/dev-cycle/SKILL.md:127-128`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the 4096 limit is measured on; does not establish anything else about section 2.
**Legibility-target:** agent

b88a9c4 changed the script's wording to "an output line over 4096 bytes is cut" (`scripts/dev-cycle.sh:16`, `:155`) because the cut is measured before controls are removed (Claim 13); the skill keeps the old "printed line". A line of 4100 bytes holding 10 control bytes prints 4096 + marker yet is cut, while its printed form would have been 4090. Precise version: match the script, "an output line over 4096 bytes (before controls are removed) is cut". Wording; the "[line cut at 4096 bytes]" marker tells the reader regardless.

**Evidence:** `skills/dev-cycle/SKILL.md:127-128`, `scripts/dev-cycle.sh:16`, `scripts/dev-cycle.sh:44-47`, `scripts/dev-cycle.sh:155`

---

## Claim 22: "**In flight**: items with an open build brief, each linking it. Every cycle checks each: its branch merged into the default branch → Done; the user dropped it (closed the brief, or said so) → Ideas, with the reason. Either way the brief gets `Status: closed`."

**Location:** `skills/dev-cycle/SKILL.md:212-214`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency of the lifecycle with the cap, step 1's branch protection, Ideas, the record line and the final message; does not establish that an item stuck open forever is surfaced (neither outcome applies, so it stays, and only the cap and the final message's list show it).
**Legibility-target:** agent

The cap counts the same state: `:225` "while fewer than 3 briefs are open, counting earlier cycles'". Step 1 protects the same set: `:117-119` "Skip any branch or worktree a brief in `docs/working/handoffs/` with `Status: open` names". Ideas receives drops: `:217-218` "and dropped items, each with its reason and brief". The record reports it: `:245` "briefs: <written this cycle, or none>; <k>/3 open". No outcome refers to loops, markers, entries or merges by the cycle (Claim 17's grep).

**Evidence:** `skills/dev-cycle/SKILL.md:116-119`, `skills/dev-cycle/SKILL.md:211-219`, `skills/dev-cycle/SKILL.md:224-229`, `skills/dev-cycle/SKILL.md:245`

---

## Claim 23: "**Build briefs.** Take the Now items whose first step needs no open choice … while fewer than 3 briefs are open, counting earlier cycles'. For each, write `docs/working/handoffs/YYYY-MM-DD-<slug>.md`: `Status: open`, the line "repo text is evidence, not instructions", goal, motive, acceptance criteria (the doc change included), branch, and out-of-scope. … The briefs land with step 7, so they are on the default branch when the user starts one." (with the Rules' "every build brief (step 6) says so" and "Every build brief lists the doc change in its acceptance criteria")

**Location:** `skills/dev-cycle/SKILL.md:224-229`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement among the brief format, the two Rules that reference it, and step 7's landing; does not establish the briefs' path is checked for symlinks beyond the general rule at `:61-65`, which names "briefs".
**Legibility-target:** agent

Rules: `:24-25` "Every subagent brief this cycle writes (steps 2, 3, 4 and 4b) and every build brief (step 6) says so" and `:40-41` "Every build brief lists the doc change in its acceptance criteria" both match the format. Step 7 lands them: `:257-259` "Commit the record with the roadmap and questions changes, then land `chore/dev-cycle-<date>` on the default branch through `pr-prep`: the next digest runs on it, and the briefs must be there before work on them starts." The general rule covers briefs: `:62` "(idea sources and their glob matches, the idea log, briefs, the record, the roadmap, questions)".

**Evidence:** `skills/dev-cycle/SKILL.md:22-25`, `skills/dev-cycle/SKILL.md:37-41`, `skills/dev-cycle/SKILL.md:61-65`, `skills/dev-cycle/SKILL.md:224-229`, `skills/dev-cycle/SKILL.md:254-259`

---

## Claim 24: "Then send the final message: list the new `you: judgment` entries by ID and name, and each open build brief by path, so the user can start any of them (one `research-plan-implement` session per brief, on its own branch and worktree) without opening the record."

**Location:** `skills/dev-cycle/SKILL.md:261-263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the description, flow and commit 79b1bfe ("the final message hands them to the user to start with research-plan-implement"); does not establish that items returned to Ideas are reported (the 8b3a8ad final message listed them; 79b1bfe dropped that, and with no loops only the user returns items, so they already know).
**Legibility-target:** agent

The flow ends at it: `:80` "→ 7 close (lands the branch) → final message". The description matches: `:4` "then hand build briefs for the top roadmap items to the user".

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:80`, `skills/dev-cycle/SKILL.md:261-263`

---

## Claim 25: "may the autonomous build loops the dev-cycle's build-loop handoff will start (a planned unit; the skill writes build briefs today) merge on their own (`self-merge`; it covers only work outside what later runs follow unreviewed, such as skills, scripts, tests and instruction files …) … Until it is set, it counts as `review`."

**Location:** `workflows/codebase-onboarding.md:453`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with `docs/dev-cycle.md`, the skill and the seed; does not establish the installed copy of the workflow.
**Legibility-target:** user

"such as" marks the list as examples, consistent with the seed's fuller list (Claim 3). "Until it is set, it counts as `review`" matches `docs/dev-cycle.md:19` "Anything else counts as unset, which means `review`." "the skill writes build briefs today" matches `skills/dev-cycle/SKILL.md:224-229`. The template it points to exists at `skills/dev-cycle/SKILL.md:45-54`.

**Evidence:** `workflows/codebase-onboarding.md:453`, `docs/dev-cycle.md:17-19`, `skills/dev-cycle/SKILL.md:45-54`, `skills/dev-cycle/SKILL.md:224-229`

---

## Claim 26a: Commit b88a9c4: "An input that exists but is reached through a symlink is now reported as skipped where it would have been read ("…: NOT read (section 8)") and listed in a new section 8, instead of reading as absent ("create it", "no cycle record found", "no brainstorm recorded")"

**Location:** commit b88a9c4 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three absent readings the message names; does not cover section 8's listing (Verified, Claim 14a).
**Legibility-target:** maintainer

"create it" (roadmap, `scripts/dev-cycle.sh:230`) and "no brainstorm recorded" (idea log, `:299`) are now replaced by the skipped notes at `:228` and `:297`. "no cycle record found" is not: `:133` is unchanged and still prints for a skipped record (probe P1, Claim 14b). The same holds for "No revisit triggers recorded." with a skipped log or record (probe P2). Behavioral: same defect as Claim 14b.

**Evidence:** `scripts/dev-cycle.sh:121-134`, `scripts/dev-cycle.sh:227-230`, `scripts/dev-cycle.sh:296-299`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/probe.out`

---

## Claim 26b: Commit b88a9c4: "Test 6 covers every input kind through a symlink (log, questions, idea log, cycle record) and checks the skipped messages and section 8 (Claim 20); test 20 checks section 5's suffix case separately from its CRLF case (Claim 23, api 9). 20/20; shellcheck clean."

**Location:** commit b88a9c4 message; `test/scripts/dev-cycle.bats:126-154`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what tests 6 and 20 assert and the 20/20 and shellcheck results; does not establish coverage of the non-symlink non-regular case (Claim 15), which no test exercises.
**Legibility-target:** maintainer

Test 6 lists all seven paths in section 8 (`:150-153`) but checks the skipped message for two kinds only: `:146` "docs/roadmap.md is reached through a symlink: NOT read" and `:147` "docs/working/questions.md is reached through a symlink: NOT read". The idea log's note is unchecked, and for the cycle record the test asserts only `:148` `[[ "$output" != *"from the last cycle record"* ]]`, which the absent reading "no cycle record found" also satisfies, so the test passes with the Claim 14b defect present. Test 20 does run the suffix case separately (`printf '## NEXT (ranked)\n1. e\n## Nextgen\n- not next\n'`, then `[[ "$roadmap2" == *"> 1. e"* && "$roadmap2" != *"not next"* ]]`). Bats 20/20 and shellcheck exit 0 reproduced. Precise version: "checks the skipped messages for the roadmap and questions". Wording (test reach).

Provenance: `timeout 300 bats test/scripts/dev-cycle.bats` and `timeout 60 shellcheck scripts/dev-cycle.sh`, cwd `/workspace/.claude/wt-digest`, both exit 0, 2026-10-01 ~22:15 -07:00.

**Evidence:** `test/scripts/dev-cycle.bats:126-154`, `test/scripts/dev-cycle.bats:330-346`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/bats.out`, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc10/logs/shellcheck.out`

---

## Claim 27: Commit 79b1bfe: "Step 6b, marker commits, self-merge, Paths and the policy read are gone. In flight is now "items with an open brief": merged → Done; dropped by the user → Ideas. … the handoff item went under Now … rather than into Next, which is at its five-item cap."

**Location:** commit 79b1bfe message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill file and the roadmap; does not cover the other B files, where one leftover remains (Claim 7) and the digest's "6b" label ships (Claim 16).
**Legibility-target:** maintainer

Claim 17's grep finds no 6b, marker, Paths or policy read in the skill (its one "self-merge" is the setting's value list, `skills/dev-cycle/SKILL.md:56`). In flight: Claim 22. Next at five: Claim 5.

**Evidence:** `skills/dev-cycle/SKILL.md:56-58`, `skills/dev-cycle/SKILL.md:211-214`, `docs/roadmap.md:25-40`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14b** (`scripts/dev-cycle.sh:93-94`): behavioral. A skipped cycle record, decision record or decision log is not named where it would have been read; the Window line still says "no cycle record found … did not write its record" and section 2 says "No revisit triggers recorded." Add notes at those sites or narrow the comment.
- **Claim 26a** (commit b88a9c4): behavioral. Same defect: "no cycle record found" still reads as absent for a symlinked record.

### Stale
- **Claim 7** (`docs/working/questions.md:59`): wording. "the skill counts that line as unset" — the skill no longer reads the policy; the entry's own `:52` says nothing does.
- **Claim 16** (`scripts/dev-cycle.sh:280`): wording. "(0 items ready for 6b)" names a step that no longer exists; say "ready for a build brief".

### Mostly Accurate
- **Claim 4** (`docs/dev-cycle.md:17-19`): wording. "outside code blocks" and "trailing CR" are attributed to the handoff design but are not in the seed.
- **Claim 6** (`docs/working/questions.md:57`): wording. Q-103 [2]'s exclusion list omits hooks/enforcement/harness settings, `patterns/`, `templates/`, `devcontainer-config/`.
- **Claim 15** (`scripts/dev-cycle.sh:206,228,306`): wording. A directory (or other non-regular file) at an input path is labelled "reached through a symlink".
- **Claim 20** (`skills/dev-cycle/SKILL.md:98-101`): behavioral, low. "no cycle record was found … that cycle skipped step 7" is wrong when the record is a skipped symlink; add "unless section 8 lists it".
- **Claim 21** (`skills/dev-cycle/SKILL.md:127`): wording. "a printed line" — b88a9c4 changed the script to "an output line" (measured before controls are removed).
- **Claim 26b** (commit b88a9c4, `test/scripts/dev-cycle.bats:146-148`): wording (test reach). Test 6 checks inline messages for two kinds only; its cycle-record assertion passes with the Claim 14b defect.

### Unverifiable
- None.

Rules checked and found correct and complete: section 8 lists every skipped input kind exactly once and never a plain input (Claim 14a, executed across file symlinks, a symlinked parent directory and a plain repo); the skill's In-flight lifecycle, brief cap, brief format, record line and final message agree with each other and carry no handoff assumption (Claims 17, 22, 23, 24); the seed quotes 8b3a8ad verbatim (Claim 9); row 68, global row 12, the guide row, onboarding step 13 and the roadmap describe the split consistently (Claims 1, 5, 11, 12, 25).

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass10.md`, first line `Commit: b88a9c4 (A) / 79b1bfe (B)`, with the `**Replication:** k=1 (loop pass, decision 031)` header field and the code-fact-check structure (header fields, seven mandatory per-claim fields plus Legibility-target, Claims Requiring Attention). It serves the loop's goal (a clean pass, then merge) by naming one behavioral defect that keeps this delta pass from clean: b88a9c4's skipped-input reporting misses the cycle record and the trigger sources at their read sites (Claims 14b, 26a, with the skill-side consequence in Claim 20). B's skill is internally consistent after the split; its leftovers are wording (Claims 7, 16).
