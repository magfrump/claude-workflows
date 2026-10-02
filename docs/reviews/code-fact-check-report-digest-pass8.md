Commit: ab8ec06 (A) / cfe4b51 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (feat/dev-cycle-digest, HEAD 8f346cd, code at ab8ec06; `scripts/` and `test/` are unchanged between the two). B: `/workspace/.claude/wt-devcycle` (feat/dev-cycle, HEAD bbbbc75, content at cfe4b51; the scoped files are unchanged between the two).
**Scope:** Partial: the pass-7 fix round only. A: `git diff 47c9a8e..ab8ec06 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus commit message ab8ec06. B: `git diff d6e1f24..cfe4b51 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/decisions/log.md guides/skill-creation.md global-instructions workflows/codebase-onboarding.md docs/working/questions.md` plus commit message cfe4b51, and the A↔B contract where this round changed it (the `inrepo` rule the skill now cites). Everything else on both branches is context only.
**Checked:** 2026-10-01 (executions timestamped 2026-10-02T04:24–04:31Z UTC)
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 41 (30 numbered; 16, 17, 19, 29 and 30 split into sub-claims)
**Summary:** 27 verified, 12 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Line numbers for A are at ab8ec06. Line numbers for B are at cfe4b51. Claims are ordered by file path across both sides, with commit messages last. Each Incorrect and Mostly accurate claim is marked **behavioral** (what the code or skill does, or tells an agent to do, is affected) or **wording** (the text is imprecise but the behavior is right). Test-reach findings count as wording, because the script itself is correct.

Execution logs are scratch and not committed: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc8/logs/`. Below they appear as `fc8/logs/`. The probe repos and mutants are in `fc8/mut.J9cy/`:
- `m1`: ab8ec06 with the resume removed (`$i = 0;` in place of `$i = $s > 3 ? $s - 3 : 0;`).
- `m2`: ab8ec06 without `sub(/\r$/, "")` in section 5's awk.
- `m3`: ab8ec06 without `sub(/\r$/, "")` in section 7's awk.
- `dc-47c9a8e.sh`: the pre-round script.

All probes ran under `timeout`, in `mktemp -d` directories under `fc8/`, with mawk (`/usr/bin/awk` → `/usr/bin/mawk`; no gawk on the host). No process was left running. Nothing was written into either worktree except this report.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant prior pattern is measured values quoted in commit messages and comments ("All 85 tests…", "mode1-equiv 33"). This round's "20/20" was executed and holds. "18.7 s" and "~1 minute" are timings that depend on the host. They were re-measured (Claims 25 and 29a), and neither is a fabrication.

---

## Claim 1: row 68: "a new conditional step 4b files a scoped deep-audit task … when a skill, the model or a major design decision record changes … whether a loop merges on its own (`self-merge`) or stops for the user's review (`review`: a PR, or a "merge <branch>?" entry where the project has no PRs) is a per-project build-loop policy in `docs/dev-cycle.md`, set during onboarding"

**Location:** `docs/decisions/log.md:91` (B)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the changed phrases of row 68 against SKILL.md 4b and 6b and onboarding step 13. It does not establish the row's unchanged clauses, which were verified in pass 7.
**Legibility-target:** for-orchestrator-synthesis

SKILL.md 4b's trigger is "a decision record added or changed that is a major design decision" (`skills/dev-cycle/SKILL.md:164`). 6b gives "**`self-merge`**: the loop lands its branch through `pr-prep`" and "**`review`**: … it opens a PR where the project uses them, otherwise it files one `you: judgment` entry, "merge <branch>?"" (`skills/dev-cycle/SKILL.md:282-285`). Onboarding step 13 sets the policy (`workflows/codebase-onboarding.md:453`).

**Evidence:** `docs/decisions/log.md:91`, `skills/dev-cycle/SKILL.md:163-165`, `skills/dev-cycle/SKILL.md:282-285`, `workflows/codebase-onboarding.md:447-453`

---

## Claim 2: "Codebase onboarding asks the user for the build-loop policy (its step 13)"

**Location:** `docs/dev-cycle.md:3-5` (B)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step number and the fact that it asks. It does not establish that existing onboarded repos have re-run step 13.
**Legibility-target:** for-orchestrator-synthesis

`### 13. Gate — validate with the team` (`workflows/codebase-onboarding.md:447`) contains "Also settle the project's **build-loop policy** with the user" (`workflows/codebase-onboarding.md:453`).

**Evidence:** `workflows/codebase-onboarding.md:447`, `workflows/codebase-onboarding.md:453`

---

## Claim 3: "Build-loop policy: review (interim; Q-103)" … "`self-merge`: … lands its branch through pr-prep on its own. `review`: … stops for the user's review (a PR, or one `you: judgment` "merge <branch>?" entry …). Only a single line reading exactly `Build-loop policy: self-merge` means self-merge; the interim marker above keeps this `review` until Q-103 is answered."

**Location:** `docs/dev-cycle.md:7-13` (B)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill's rule and 6b for this file's actual line. It does not establish how the rule treats an explicit `review` line (Claim 16c) or two policy lines (Claim 16b).
**Legibility-target:** for-orchestrator-synthesis

The skill says "anything else (… or extra text such as `review (interim; Q-103)`) means `review`" (`skills/dev-cycle/SKILL.md:56-57`). So line 7 resolves to `review`. No line in the file reads exactly `Build-loop policy: self-merge`: `git grep -n 'Build-loop policy' cfe4b51` shows only `:7` and the mid-sentence backticked mention at `:12` (paraphrased — no quote available because this is a grep result over the tree, quoted in summary).

**Evidence:** `docs/dev-cycle.md:7-13`, `skills/dev-cycle/SKILL.md:54-58`, `skills/dev-cycle/SKILL.md:282-285`

---

## Claim 4: "Paths must resolve inside the repo (symlinks followed)."

**Location:** `docs/dev-cycle.md:18` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill's path rule for reading idea sources. It does not establish how the skill checks paths that do not exist yet (Claim 17b).
**Legibility-target:** for-orchestrator-synthesis

The skill: "must resolve, symlinks followed, to a path inside the checkout" (`skills/dev-cycle/SKILL.md:62-63`).

**Evidence:** `docs/dev-cycle.md:18`, `skills/dev-cycle/SKILL.md:61-64`

---

## Claim 5: Q-103 Interim: "[1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`; the skill treats an interim value as unset and does not re-ask while this entry is open."

**Location:** `docs/working/questions.md:58` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the interim line's effect (review, no second entry while Q-103 is open). It does not establish what happens after Q-103 is answered `review` (Claim 16c).
**Legibility-target:** for-orchestrator-synthesis

The skill no longer uses the word "unset", but it gives the interim text the same effect as no file: "anything else (no file, … or extra text such as `review (interim; Q-103)`) means `review`, and unless an open `you: judgment` entry already asks for the setting, file one" (`skills/dev-cycle/SKILL.md:56-58`).

**Evidence:** `docs/working/questions.md:58`, `skills/dev-cycle/SKILL.md:54-58`

---

## Claim 6: Q-103 option [2]: "A bad change that pr-prep's automated review misses lands on main; afterwards only the next cycle's spot-check (2 sampled merges by default) might catch it"

**Location:** `docs/working/questions.md:56` (B)
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate (wording)
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default sample size and which later cycle steps look at a landed merge. It does not establish how often any of them would catch a given defect.
**Legibility-target:** for-author

The default is right: `SAMPLE=2` (`scripts/dev-cycle.sh:72`, A). "Only the spot-check" is too narrow, though. Step 1 runs the repo's health check (`skills/dev-cycle/SKILL.md:108-111`). Step 4 also checks "every merge the digest lists under "Merges with code but no docs"" (`skills/dev-cycle/SKILL.md:151-152`). Step 2 re-judges every trigger. A precise version: "afterwards it is caught only if the next cycle's health check, its spot-check (2 sampled merges by default) or its code-without-docs check finds it".

**Evidence:** `docs/working/questions.md:56`, `scripts/dev-cycle.sh:72`, `skills/dev-cycle/SKILL.md:108-111`, `skills/dev-cycle/SKILL.md:148-152`

---

## Claim 7: global row 12: "health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then hands ready items to autonomous build loops"

**Location:** `global-instructions/CLAUDE.md:32` (B)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step list against the skill's flow. It does not establish that the installed `~/.claude` copy carries row 12 (it is installed separately).
**Legibility-target:** for-orchestrator-synthesis

The skill's flow is `0 digest → 1 health and cleanup → { 2 triggers | 3 questions | 4 spot-check | 4b audit check } → 5 brainstorm (conditional) → 6 roadmap → 7 close … → 6b handoff` (`skills/dev-cycle/SKILL.md:78-79`). Its description uses the same list, `skills/dev-cycle/SKILL.md:4`.

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:78-79`

---

## Claim 8: "on balance a skill (the gray-area rule)"

**Location:** `guides/skill-creation.md:137` (B)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the cited rule. It does not re-judge the classification.
**Legibility-target:** for-orchestrator-synthesis

`**Gray area guidance:** If something could be either, prefer a skill.` (`guides/skill-creation.md:105`).

**Evidence:** `guides/skill-creation.md:105`, `guides/skill-creation.md:137`

---

## Claim 9: "Every revisit trigger is printed every run (a line over 4096 bytes is cut)" (header) and "Every trigger, in full (a line over 4096 bytes is cut)." (section 2)

**Location:** `scripts/dev-cycle.sh:16-17`, `scripts/dev-cycle.sh:151` (A)
**Type:** Behavioral
**Verdict:** Mostly accurate (wording)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where the cut threshold falls for a decision-record trigger line. It does not establish the exact threshold for log-row lines, which carry a longer prefix.
**Legibility-target:** for-author

The cut is applied to the printed line, after the digest has added its prefix: `$_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;` (`scripts/dev-cycle.sh:45`) runs on the output of `trig < "$f" | sed 's/^/> /'` (`scripts/dev-cycle.sh:162`). So a trigger line of 4095 bytes, which is not "over 4096", comes out as `> ` plus 4094 bytes plus the marker. Executed: a 4095-byte trigger line gave one `[line cut at 4096 bytes]` marker and a 4121-byte output line. For a log row the prefix is `- log row N (date): > ` (`scripts/dev-cycle.sh:173`), so the threshold there is about 20 bytes lower. A precise version: "a printed line over 4096 bytes is cut".

**Evidence:** `scripts/dev-cycle.sh:45`, `scripts/dev-cycle.sh:162`, `scripts/dev-cycle.sh:173`. Command `timeout 20 bash /workspace/.claude/wt-digest/scripts/dev-cycle.sh` in throwaway repo `fc8/mut.J9cy/r2` holding a 4095-byte trigger line, exit 0, 2026-10-02T04:28:31Z. Output: fc8/logs/cut4095.log

---

## Claim 10: "drops … the line and paragraph separators U+2028/2029 (some readers split lines on them)"

**Location:** `scripts/dev-cycle.sh:26-29`, `scripts/dev-cycle.sh:51` (A)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removal of E2 80 A8 and E2 80 A9, and that the widened class adds nothing else. It does not establish the rationale about readers.
**Legibility-target:** for-orchestrator-synthesis

The class changed from `\xE2\x80[\x8E\x8F\xAA-\xAE]` to `\xE2\x80[\x8E\x8F\xA8-\xAE]` (`scripts/dev-cycle.sh:51`). A8–AE covers exactly U+2028–U+202E. U+202A–202E were already covered. Executed: the 47c9a8e script prints `> if p 342 200 250 q 342 200 251 r .`, and ab8ec06 prints `> if pqr.`. The "Not covered" list no longer names U+2028/2029 (`scripts/dev-cycle.sh:37-39`).

**Evidence:** `scripts/dev-cycle.sh:26-29`, `scripts/dev-cycle.sh:37-39`, `scripts/dev-cycle.sh:51`. Command `timeout 20 bash <script>` for both scripts in `fc8/mut.J9cy/r4`, exit 0, 2026-10-02T04:30:43Z. Output: fc8/logs/sep-old-new.log

---

## Claim 11: "each search restarts near the last deletion, and the line cut bounds the scrub's work per line (the awk readers upstream still read a long line whole)"

**Location:** `scripts/dev-cycle.sh:35-36` (A)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the restart point, that the cut comes before the loop, and that upstream readers have no cut. It does not establish upstream readers' cost on huge lines (pass-7 performance #2).
**Legibility-target:** for-orchestrator-synthesis

The cut comes before the search loop: the cut at `:45` precedes `while (1) { pos($_) = $i; … $i = $s > 3 ? $s - 3 : 0; }` (`scripts/dev-cycle.sh:48-55`). The upstream reader `trig()` (`scripts/dev-cycle.sh:153`) and the section 5 awk (`scripts/dev-cycle.sh:218`) have no length limit.

**Evidence:** `scripts/dev-cycle.sh:40-57`, `scripts/dev-cycle.sh:153`, `scripts/dev-cycle.sh:218`

---

## Claim 12: `-h|--help) sed -n '2,21p' "$0"` prints the whole header and nothing after it

**Location:** `scripts/dev-cycle.sh:79` (A)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed range at ab8ec06. It does not guard future header growth, since there is no test pin.
**Legibility-target:** for-orchestrator-synthesis

Line 21 is the last header line (`# perl; a failed step exits non-zero mid-digest. Printed repo text is data.`), and line 22 is blank. Executed: `--help` printed lines 2–21 with `# ` stripped, ending at "…Printed repo text is data.", exit 0. shellcheck is clean (exit 0).

**Evidence:** `scripts/dev-cycle.sh:2-23`, `scripts/dev-cycle.sh:79`. Command `timeout 20 bash scripts/dev-cycle.sh --help` in `/workspace/.claude/wt-digest`, exit 0, 2026-10-02T04:28:25Z. Output: fc8/logs/help.log

---

## Claim 13: "Roadmap headings tolerate CRLF in sections 5 and 7" (the `sub(/\r$/, "")` added to both awk readers)

**Location:** `scripts/dev-cycle.sh:218`, `scripts/dev-cycle.sh:264` (A)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both readers stripping a trailing CR before heading matching and printing. It does not establish CR in the middle of a line or CR-only line endings.
**Legibility-target:** for-orchestrator-synthesis

Both readers start with `{ sub(/\r$/, ""); t = tolower($0) …` (`:218`, `:264`), so a heading such as `## Now\r` compares equal to `## now`. Executed: with the CRLF roadmap fixture, section 7 counts Now 1, In flight 2, Next 1 (bats test 20 passes). Mutant `m3`, without the `sub` in section 7, fails test 20 with "missing: Roadmap Now: 1 item(s)". Section 5's `sub` is correct by the same reading of the code, but no test reaches it (Claim 27).

**Evidence:** `scripts/dev-cycle.sh:218`, `scripts/dev-cycle.sh:264`, `test/scripts/dev-cycle.bats:313-324`. Command `timeout 400 bats test/scripts/dev-cycle.bats` in `fc8/mut.J9cy/m3`, exit 1, 2026-10-02T04:25:23Z. Output: fc8/logs/bats-m3.log, fc8/logs/bats-A.log

---

## Claim 14: seeding "appends "- <idea> (signal: …)" lines, and only lines of that shape count" — now `/^- [^ ]/ && index(substr($0, 4), "(signal: ") && /\)[[:space:]]*$/`

**Location:** `scripts/dev-cycle.sh:272-277` (A)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers selection being equal to the 47c9a8e regex under mawk, and linear time on the pathological lines. It does not establish gawk's behavior in a UTF-8 locale (gawk is not installed; `substr` there counts characters, which keeps the same offset meaning).
**Legibility-target:** for-orchestrator-synthesis

The new expression needs a non-space at column 3, `(signal: ` starting at column 4 or later, and a line ending in `)` plus optional whitespace. The `)` at the end must follow the `(signal: ` match, because `(signal:` holds non-space bytes that cannot sit after the final `)`. That is the old `^- [^ ].*\(signal: .*\)[[:space:]]*$`. Executed with mawk:
- A differential fuzz over 200,000 random lines (1,553 old matches) found 0 differences.
- On 638 KB lines, the new expression took 0.00 s on each shape. The old one took 15.39 s (`(signal: )x` repeated), 26.29 s (`(signal: ) ` repeated) and 0.19 s (`(signal: ` repeated).
- The suffix regex `\)[[:space:]]*$` scans each whitespace run once per adjacent `)`, so its cost is linear (paraphrased — no quote available because this is an analysis of the regex, not a line of code).

**Evidence:** `scripts/dev-cycle.sh:272-277`. Fuzz command `mawk '…' fuzz.txt` in `fc8/mut.J9cy`, exit 0, 2026-10-02T04:26Z, output fc8/logs/fuzz-seed.log. Timing `python3 fc8/timing.py` (each mawk under `timeout 60`), exit 0, 2026-10-02T04:26:37Z, output fc8/logs/seed-timing.log

---

## Claim 15: the settings template: `# Dev-cycle settings` / `Build-loop policy: review` / `## Idea sources` / table header

**Location:** `skills/dev-cycle/SKILL.md:41-52` (B)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the structure matching the live `docs/dev-cycle.md`. It does not establish that the template carries the explanatory prose, which the live file adds.
**Legibility-target:** for-orchestrator-synthesis

The live file has `# Dev-cycle settings` (`docs/dev-cycle.md:1`), a policy line (`:7`), `## Idea sources` (`:15`) and `| Source | Path or glob | Format |` (`:20`). The template has the same four elements, in the same order.

**Evidence:** `skills/dev-cycle/SKILL.md:43-52`, `docs/dev-cycle.md:1-22`

---

## Claim 16a: "Only one line reading exactly `Build-loop policy: self-merge` means self-merge; anything else (no file, no line, … another value, or extra text such as `review (interim; Q-103)`) means `review`"

**Location:** `skills/dev-cycle/SKILL.md:55-57` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the rule fails safe for a missing file or line, interim text, case variants (`Self-Merge`), trailing text and other values. It does not establish the two-line case (16b) or the filing consequence (16c).
**Legibility-target:** for-orchestrator-synthesis

"Exactly" excludes case variants and trailing text, and the default is `review` (`skills/dev-cycle/SKILL.md:55-57`). The only value with an effect beyond review is the exact line.

**Evidence:** `skills/dev-cycle/SKILL.md:54-58`

---

## Claim 16b: "anything else (… two lines …) means `review`"

**Location:** `skills/dev-cycle/SKILL.md:56` (B)
**Type:** Behavioral
**Verdict:** Mostly accurate (wording)
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what "two lines" refers to. It does not establish what an agent would actually do.
**Legibility-target:** for-author

The rule does not say two of what. Take a file holding `Build-loop policy: self-merge` and also `Build-loop policy: review`. It has "one line reading exactly `Build-loop policy: self-merge`" (`:55`), so read literally it means self-merge. It also has "two lines" (`:56`), so it means review. The fail-safe reading needs "two `Build-loop policy:` lines". A precise version: "exactly one `Build-loop policy:` line, reading exactly `Build-loop policy: self-merge`".

**Evidence:** `skills/dev-cycle/SKILL.md:55-56`

---

## Claim 16c: "anything else … means `review`, and unless an open `you: judgment` entry already asks for the setting, file one."

**Location:** `skills/dev-cycle/SKILL.md:56-58` (B)
**Type:** Behavioral
**Verdict:** Incorrect (behavioral)
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the rule applied to a deliberately set `Build-loop policy: review`. It does not establish whether an agent would read the parenthetical as limiting "anything else" to unset-like cases.
**Legibility-target:** for-author

The skill names `review` as one of the two valid values (`` `self-merge` or `review` ``, `:55`). Its own template sets `Build-loop policy: review` (`:46`), and onboarding records whichever value the user picks: "Record it as `Build-loop policy: <value>` … Until it is set, the skill uses `review`" (`workflows/codebase-onboarding.md:453`). But the filing clause applies to "anything else" than the exact self-merge line. That includes a plain, deliberate `review` line. So in a repo whose user chose `review`, every cycle with no open entry files a `you: judgment` entry asking for the setting again. That spends the user's attention, which the skill's own rule treats as the budget (`:30-34`). The old text filed only for "No file, no policy line, or a value marked `(interim)`" (d6e1f24). A precise version: the filing clause applies only when the line is not exactly `Build-loop policy: self-merge` or `Build-loop policy: review`.

**Evidence:** `skills/dev-cycle/SKILL.md:30-34`, `skills/dev-cycle/SKILL.md:46`, `skills/dev-cycle/SKILL.md:54-58`, `workflows/codebase-onboarding.md:453`

---

## Claim 17a: "Every file the cycle reads or writes because a setting, a glob or a default names it … must resolve, symlinks followed, to a path inside the checkout"

**Location:** `skills/dev-cycle/SKILL.md:61-63` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the rule's resolution semantics match `inrepo` for existing files, including an in-repo symlink. It does not establish the case of files that do not exist yet (17b).
**Legibility-target:** for-orchestrator-synthesis

`inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }` (`scripts/dev-cycle.sh:92`, A) follows symlinks through `realpath`. Executed: `docs/working/idea-log.md` → `idea-target.md` (in repo) gives `inrepo=0`.

**Evidence:** `scripts/dev-cycle.sh:89-92`, `skills/dev-cycle/SKILL.md:61-64`. Command `timeout 10 bash -c '<inrepo copied verbatim>; …'` in `fc8/mut.J9cy/r3`, exit 0, 2026-10-02T04:30:11Z. Output: fc8/logs/inrepo-new-files.log

---

## Claim 17b: "…: the digest's `inrepo` rule. A path that does not is skipped and reported in the record, never read or written through."

**Location:** `skills/dev-cycle/SKILL.md:63-64` (B)
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate (behavioral)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers applying `inrepo` to the write targets the rule lists (the record, a new roadmap, a new idea log, briefs). It does not establish how an agent would check them in practice, since the skill names no command.
**Legibility-target:** for-author

`inrepo` also requires an existing regular file (`[[ -f "$1" ]]` and `realpath -e`, `scripts/dev-cycle.sh:92`). So it returns false for every file the cycle is about to create, whether that file is in the repo or not. Executed in a repo where `docs/working/cycles` is a symlink out of the checkout:
- `docs/working/cycles/cycle-2026-10-01.md` (outside) gives `inrepo=1`.
- `docs/roadmap.md` (missing, in repo) gives `inrepo=1`.
- `docs/working/handoffs/2026-10-01-x.md` (missing, in repo) gives `inrepo=1`.

Read literally, "the digest's `inrepo` rule" plus "skipped" means the cycle never creates its record, its first roadmap or any brief. The resolution rule in 17a is right. What is missing is how to apply it to a new file: resolve its nearest existing parent directory. The digest does not do this for the cycle, since it writes nothing (`scripts/dev-cycle.sh:19`).

**Evidence:** `scripts/dev-cycle.sh:19`, `scripts/dev-cycle.sh:92`, `skills/dev-cycle/SKILL.md:61-64`. Command as in Claim 17a, exit 0, 2026-10-02T04:30:11Z. Output: fc8/logs/inrepo-new-files.log

---

## Claim 18: "`docs/working/idea-log.md` (create it with a `# Idea log` heading; a symlink there is not written through)"

**Location:** `skills/dev-cycle/SKILL.md:66-68` (B)
**Type:** Behavioral
**Verdict:** Mostly accurate (wording)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clash with the general path rule and the digest for an in-repo symlink. It does not establish any security consequence, since in-repo targets are inside the checkout either way.
**Legibility-target:** for-author

The general rule follows symlinks and skips only paths that resolve outside (`:62-64`, Claim 17a). This line forbids writing through any symlink at the idea log, including one that points inside the repo. The digest reads through such a symlink: `inrepo` passes it (executed, `inrepo=0`), and section 7 counts its seeds (`scripts/dev-cycle.sh:271-277`, A). So the seeds a cycle counts can come from a file it will not append to. A precise version: "a symlink there that resolves outside the checkout is not written through". If the stricter rule is intended, say so in the general rule too.

**Evidence:** `skills/dev-cycle/SKILL.md:61-68`, `scripts/dev-cycle.sh:92`, `scripts/dev-cycle.sh:271-277`. Command as in Claim 17a. Output: fc8/logs/inrepo-new-files.log

---

## Claim 19a: In flight: "merged → Done; finished and waiting on the user's merge decision (an open PR or `merge <branch>?` entry) → stays, however long; merge declined (PR closed unmerged, or the entry answered no) → back to Now marked declined … the branch is kept; … still building with no commit on its branch for 7 days → back to Now marked stalled", with the brief closed "whenever it leaves"

**Location:** `skills/dev-cycle/SKILL.md:210-219` (B)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that these states are mutually distinguishable and that every outcome has a home. A loop that stops without a stop condition (failing tests, a merge conflict) is caught only by the 7-day stalled rule. It does not establish the blocked and twice-stalled rules' interaction with the queue (19b, 19c, 20).
**Legibility-target:** for-orchestrator-synthesis

Waiting and blocked are told apart by their entries. A waiting item has "merge <branch>?" (`:285`), and a blocked item has a stop-condition entry naming the item (`:217`, `:287-288`). Declined needs the PR closed or the entry answered no. Merged needs the merge. Stalled needs no commit for 7 days while not finished. Each exit closes the brief (`:211`).

**Evidence:** `skills/dev-cycle/SKILL.md:210-221`, `skills/dev-cycle/SKILL.md:282-288`

---

## Claim 19b: "stopped on a stop condition (its entry names the item) → back to Now marked blocked, and not queued while that entry is open"

**Location:** `skills/dev-cycle/SKILL.md:217-218` (B)
**Type:** Behavioral
**Verdict:** Mostly accurate (behavioral)
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the In flight rule against the queue rule. It does not establish any later step that clears the mark, and none was found in SKILL.md.
**Legibility-target:** for-author

The queue excludes blocked items whether or not the entry is open: "Take the Now items whose first step needs no open choice (no open `you: judgment` names them, and none is marked blocked)" (`:230-231`). Nothing in the skill clears the `blocked` mark when the entry is answered. So the item stays out of the queue indefinitely, not "while that entry is open". A precise version either clears the mark when the entry closes, or the queue rule reads "and none is marked blocked by an open entry".

**Evidence:** `skills/dev-cycle/SKILL.md:217-218`, `skills/dev-cycle/SKILL.md:230-231`

---

## Claim 19c: "an item that stalls a second time is not queued again: file one `you: judgment` entry naming it"

**Location:** `skills/dev-cycle/SKILL.md:219-221` (B)
**Type:** Behavioral
**Verdict:** Mostly accurate (behavioral)
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers how the queue enforces "not queued again" and how a second stall is detected. It does not establish what the user's answer should do.
**Legibility-target:** for-author

The only thing that keeps the item out is the queue's "no open `you: judgment` names them" (`:230-231`). So it is not queued only while that entry is open. Once the entry is answered, the item is eligible again, whatever the answer was. Also, "a second time" needs a record of the first stall. The first stall puts it "back to Now marked stalled" (`:219`). Re-queueing moves it to In flight (`:240`), and nothing says the stalled mark or a count travels with it (paraphrased — no quote available because this is a claim about absent text across `:209-241`). A precise version: "…is not queued again while that entry is open; keep a stall count on the item".

**Evidence:** `skills/dev-cycle/SKILL.md:219-221`, `skills/dev-cycle/SKILL.md:230-241`

---

## Claim 20: "Take the Now items whose first step needs no open choice (no open `you: judgment` names them, and none is marked blocked), up to the in-flight cap: at most 3 items In flight at once, counting earlier cycles'."

**Location:** `skills/dev-cycle/SKILL.md:230-232` (B)
**Type:** Behavioral
**Verdict:** Mostly accurate (behavioral)
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which In flight return states the queue excludes. It does not establish the cap arithmetic, which is unchanged and was verified in pass 7.
**Legibility-target:** for-author

A declined item comes back to Now "marked declined, with the user's reason" (`:215-216`). The entry that declined it is answered, so no open `you: judgment` names it, and it is not marked blocked. The queue therefore hands it to a new build loop next cycle, re-doing work the user turned down, unless the agent reads the user's reason as an "open choice". Of the In flight return states, the queue honours blocked (more strictly than 19b says) and twice-stalled (only while its entry is open, 19c), but not declined. A precise version adds "or marked declined" to the exclusion, or says that a declined item needs a new first step before it is queued.

**Evidence:** `skills/dev-cycle/SKILL.md:215-221`, `skills/dev-cycle/SKILL.md:230-232`

---

## Claim 21: brief carries "`Policy: <the build-loop policy as read now>`" and 6b "follows the `Policy:` line in the brief as landed (a later edit to `docs/dev-cycle.md`, on any branch, does not change it)"

**Location:** `skills/dev-cycle/SKILL.md:234-235`, `skills/dev-cycle/SKILL.md:279-280` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief pinning the policy and the loop reading it from the landed commit. It does not establish what a loop does with a malformed `Policy:` line (the fail-safe in 16a covers only the settings file).
**Legibility-target:** for-orchestrator-synthesis

"the loop reads the brief from that commit, so later edits to the file do not change its instructions" (`:277-278`). The stop conditions forbid touching `docs/working/handoffs/` and `docs/dev-cycle.md` (`:238-239`).

**Evidence:** `skills/dev-cycle/SKILL.md:234-241`, `skills/dev-cycle/SKILL.md:275-285`

---

## Claim 22: "The stop conditions always include: touching enforcement or hook files or harness settings (`settings*.json`); touching the dev cycle's own files (`skills/dev-cycle/`, `scripts/dev-cycle.sh`, `docs/dev-cycle.md`, `docs/working/handoffs/`); adding a dependency; and any change the out-of-scope list names."

**Location:** `skills/dev-cycle/SKILL.md:237-240` (B)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list matching the commit message's description, and `settings*.json` covering `settings.json` and `settings.local.json`. It does not establish that the roadmap, cycle records or `questions.md` are protected. They are not listed, and a `review` loop must write `questions.md`.
**Legibility-target:** for-orchestrator-synthesis

Quoted above. The commit's "(skill, digest, settings file, briefs)" maps one-to-one onto the four paths.

**Evidence:** `skills/dev-cycle/SKILL.md:237-240`

---

## Claim 23: record line "6b. handoff: <briefs queued in step 6, or none>; <k>/3 In flight, <w> waiting on a merge decision"

**Location:** `skills/dev-cycle/SKILL.md:258` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the template line and the cap it cites. It does not establish whether waiting items count inside k. They do, because waiting items stay In flight (`:213-214`).
**Legibility-target:** for-orchestrator-synthesis

The cap matches "at most 3 items In flight at once" (`:231-232`).

**Evidence:** `skills/dev-cycle/SKILL.md:213-214`, `skills/dev-cycle/SKILL.md:231-232`, `skills/dev-cycle/SKILL.md:258`

---

## Claim 24: "a build that hits a stop condition files a `you: judgment` entry naming the roadmap item" and "the final message: list the new `you: judgment` entries, and every open `merge <branch>?` entry, by ID and name"

**Location:** `skills/dev-cycle/SKILL.md:287-288`, `skills/dev-cycle/SKILL.md:291-293` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the In flight blocked rule (`:217`) and the stated final-message contents. It does not establish that waiting items in a PR-based project are listed. They are PRs, not entries, and the message names only entries.
**Legibility-target:** for-orchestrator-synthesis

The blocked rule keys on "its entry names the item" (`:217`), and 6b now requires that naming (`:287`).

**Evidence:** `skills/dev-cycle/SKILL.md:217`, `skills/dev-cycle/SKILL.md:287-293`

---

## Claim 25: "Many nested lines stay fast: restarting each line per layer took ~1 minute."

**Location:** `test/scripts/dev-cycle.bats:110` (A)
**Type:** Performance
**Verdict:** Mostly accurate (wording)
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the test catches a restart-per-layer scrub and the measured time on this host. It does not establish the time on the host where "~1 minute" was measured.
**Legibility-target:** for-author

The mechanism holds. Mutant `m1` (search restarted from byte 0 after each deletion) fails this step with "status 124 (124 = timed out)" at `timeout 10` (`:112-113`). The figure did not reproduce here:
- `m1` took 18.5 s on the 600-line input.
- The 26b7590 scrub, `1 while s/…//g` (which restarts each line per layer), took 16.5 s.
- ab8ec06 took 0.5 s.

A precise version: "took ~20 s here".

**Evidence:** `test/scripts/dev-cycle.bats:110-113`. Command `timeout 400 bats test/scripts/dev-cycle.bats` in `fc8/mut.J9cy/m1`, exit 1, 2026-10-02T04:25:23Z, output fc8/logs/bats-m1.log. Timing `python3 fc8/t2.py` and `python3 fc8/t3.py` (each under `timeout`), exit 0, 2026-10-02T04:27:28Z and 04:28:03Z, output fc8/logs/noresume-timing.log

---

## Claim 26: "U+2028 / U+2029 are removed too."

**Location:** `test/scripts/dev-cycle.bats:114-117` (A)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing on ab8ec06 and failing to match on the 47c9a8e script's output. It does not establish an exit-status check on that run (none is made).
**Legibility-target:** for-orchestrator-synthesis

The assertion `[[ "$output" == *"if pqr."* ]]` (`:117`) holds on ab8ec06 (bats 20/20). The pre-round script leaves the separators in, so the match fails there (Claim 10).

**Evidence:** `test/scripts/dev-cycle.bats:114-117`. Outputs: fc8/logs/bats-A.log, fc8/logs/sep-old-new.log

---

## Claim 27: "Section 5 uses the same heading rule (CRLF, case, suffix; "## Nextgen" is not Next)."

**Location:** `test/scripts/dev-cycle.bats:316-318` (A)
**Type:** Behavioral
**Verdict:** Mostly accurate (wording — test reach; the script is correct)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which of the four named properties the section 5 assertion actually discriminates. It does not establish section 7's coverage, which does catch CRLF (Claim 13).
**Legibility-target:** for-author

Mutant `m2` (section 5 without `sub(/\r$/, "")`) passes all 20 tests. Two things hide the CRLF branch:
- The fixture's Next heading has a suffix, `## Next (ranked)\r`. It still matches `index(t, "## next ") == 1` with the CR present (`scripts/dev-cycle.sh:218`).
- The scrub deletes `\r` from the printed `> 1. d\r` (`tr/\000-\010\013-\037\177//d`, `scripts/dev-cycle.sh:47`).

Case, suffix and the `## Nextgen` exclusion are discriminated; CRLF is not. A bare `## Next\r` heading in the fixture would reach that branch.

**Evidence:** `test/scripts/dev-cycle.bats:313-318`, `scripts/dev-cycle.sh:47`, `scripts/dev-cycle.sh:218`. Command `timeout 400 bats test/scripts/dev-cycle.bats` in `fc8/mut.J9cy/m2`, exit 0, 2026-10-02T04:25:23Z. Output: fc8/logs/bats-m2.log

---

## Claim 28: onboarding: "may the build loops … merge on their own (`self-merge`), or must each stop for the user's review (`review`: a PR, or a "merge <branch>?" questions entry where the project has no PRs)? … Record it as `Build-loop policy: <value>` in `docs/dev-cycle.md`, creating the file from the template in the skill's "Project settings" if missing. Until it is set, the skill uses `review`."

**Location:** `workflows/codebase-onboarding.md:453` (B)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the values, the template's existence and the default. It does not establish that a recorded `review` stops the skill from re-asking. It does not (Claim 16c).
**Legibility-target:** for-orchestrator-synthesis

The template is at `skills/dev-cycle/SKILL.md:41-52`, and the values and default are at `:54-57`.

**Evidence:** `workflows/codebase-onboarding.md:453`, `skills/dev-cycle/SKILL.md:41-58`

---

## Claim 29a: ab8ec06: "mawk took 18.7 s on one 640 KB idea-log line with the 47c9a8e regex"

**Location:** commit ab8ec06 message (A)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude on lines of that size. It does not establish the exact 18.7 s, which depends on the host and the line's shape and was taken from the pass-7 performance review.
**Legibility-target:** for-orchestrator-synthesis

On 638 KB lines the old regex took 15.39 s and 26.29 s, depending on the shape (Claim 14). The figure comes from `docs/reviews/performance-review-2026-10-01-digest-pass7.md:31`: "one 640 KB idea-log line adds 18.7 s".

**Evidence:** `docs/reviews/performance-review-2026-10-01-digest-pass7.md:31`. Output: fc8/logs/seed-timing.log

---

## Claim 29b: ab8ec06: "prefix + index + suffix selects the same lines"

**Location:** commit ab8ec06 message (A)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 14.
**Legibility-target:** for-orchestrator-synthesis

The 200,000-line differential fuzz found 0 differences (Claim 14).

**Evidence:** `scripts/dev-cycle.sh:277`. Output: fc8/logs/fuzz-seed.log

---

## Claim 29c: ab8ec06: "Roadmap headings tolerate CRLF in sections 5 and 7." / "Tests: 600 nested lines under a 10 s timeout (a no-resume mutant times out), U+2028/2029, a CRLF roadmap, and section 5's heading rule."

**Location:** commit ab8ec06 message (A)
**Type:** Behavioral
**Verdict:** Mostly accurate (wording — test reach)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed test against a mutant. It does not establish that the code is wrong; it is right (Claim 13).
**Legibility-target:** for-author

- The 10 s test catches the no-resume mutant (`m1` exits 124).
- U+2028/2029 is covered.
- The CRLF roadmap catches section 7's CRLF handling (`m3` fails).

But the CRLF roadmap does not exercise section 5's CRLF fix: `m2` passes 20/20 (Claim 27). "Section 5's heading rule" is tested for case and suffix only.

**Evidence:** Outputs fc8/logs/bats-m1.log, fc8/logs/bats-m2.log, fc8/logs/bats-m3.log

---

## Claim 29d: ab8ec06: "20/20; shellcheck clean."

**Location:** commit ab8ec06 message (A)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite and shellcheck at ab8ec06 (unchanged at HEAD 8f346cd). It does not establish other hosts' awk.
**Legibility-target:** for-orchestrator-synthesis

`bats test/scripts/dev-cycle.bats` gave 20 `ok` (20 `@test` blocks). `shellcheck scripts/dev-cycle.sh` exited 0.

**Evidence:** `test/scripts/dev-cycle.bats`. Command `timeout 300 bats test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`, exit 0, 2026-10-02T04:24:42Z, output fc8/logs/bats-A.log. `timeout 60 shellcheck scripts/dev-cycle.sh`, exit 0, 2026-10-02T04:28:25Z

---

## Claim 30a: cfe4b51: "Paths (security F2): everything a setting, glob or default names must resolve inside the checkout; symlinked paths are skipped, never read or written through."

**Location:** commit cfe4b51 message (B)
**Type:** Behavioral
**Verdict:** Incorrect (wording — commit message only)
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the skill and settings text. It does not establish which behavior is intended.
**Legibility-target:** for-author

The skill follows symlinks and skips only paths that resolve outside: "must resolve, symlinks followed, to a path inside the checkout … A path that does not is skipped" (`skills/dev-cycle/SKILL.md:62-64`). The settings file agrees: "Paths must resolve inside the repo (symlinks followed)." (`docs/dev-cycle.md:18`). Only the idea log forbids writing through a symlink (`skills/dev-cycle/SKILL.md:67-68`, Claim 18). A reader of the log would expect every symlinked path to be skipped. The shipped text does that only for paths that leave the checkout.

**Evidence:** `skills/dev-cycle/SKILL.md:61-68`, `docs/dev-cycle.md:18`

---

## Claim 30b: cfe4b51: "values are `self-merge` | `review` …; only one exact `Build-loop policy: self-merge` line means self-merge, anything else (interim markers included) means review. Each brief records the policy as read in step 6, and the loop follows the brief as landed." / "Stop conditions name harness settings (settings*.json) and the dev cycle's own files (skill, digest, settings file, briefs)"

**Location:** commit cfe4b51 message (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each statement against the shipped text, and that no `autonomous` policy value remains in the scoped files. It does not establish the re-ask defect (16c) or the two-lines ambiguity (16b), which the message does not mention.
**Legibility-target:** for-orchestrator-synthesis

See Claims 16a, 21 and 22. `git grep` for `` autonomous` `` / `policy: autonomous` at cfe4b51 over the scoped paths returns nothing (paraphrased — no quote available because the claim is about absence of grep hits).

**Evidence:** `skills/dev-cycle/SKILL.md:54-58`, `skills/dev-cycle/SKILL.md:234-240`, `skills/dev-cycle/SKILL.md:279-285`

---

## Claim 30c: cfe4b51: "declined merges and blocked items have rules; an item that stalls twice is not re-queued; the record's 6b line counts In flight and waiting items; the final message lists open merge entries too."

**Location:** commit cfe4b51 message (B)
**Type:** Behavioral
**Verdict:** Mostly accurate (behavioral)
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each sub-statement. It does not establish the queue's handling of declined items, which the message does not claim.
**Legibility-target:** for-author

The rules, the 6b line and the final message are as stated (Claims 19a, 23, 24). "An item that stalls twice is not re-queued" holds only while the `you: judgment` entry it files is open (Claim 19c). The rules exist, but the queue does not exclude declined items (Claim 20), and the blocked rule and the queue disagree (Claim 19b).

**Evidence:** `skills/dev-cycle/SKILL.md:210-221`, `skills/dev-cycle/SKILL.md:230-231`, `skills/dev-cycle/SKILL.md:258`, `skills/dev-cycle/SKILL.md:291-293`

---

## Claim 30d: cfe4b51 wording bullets: settings template in the skill; "the user's review (a PR, or a merge entry)" in onboarding and row 68; "names the roadmap item it blocks, if any"; row 68's 4b trigger is a major design decision record; Q-103 option [2] names pr-prep's review before merge; global row 12 lists watched questions; guide row "on balance a skill"; Notes: "no repo had set the policy yet"

**Location:** commit cfe4b51 message (B)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each wording change being present at cfe4b51, and `questions.sh check` passing. It does not establish the "no repo had set the policy" note beyond this repository.
**Legibility-target:** for-orchestrator-synthesis

All are present:
- the template, `skills/dev-cycle/SKILL.md:41-52`
- onboarding, `workflows/codebase-onboarding.md:453`
- row 68, `docs/decisions/log.md:91`
- "if any", `skills/dev-cycle/SKILL.md:33`
- Q-103 [2], `docs/working/questions.md:56`
- row 12, `global-instructions/CLAUDE.md:32`
- the guide row, `guides/skill-creation.md:137`

In this repo the only policy line is the interim `review` (`docs/dev-cycle.md:7`). `questions.sh check` printed "✓ questions: structure valid, indexes current".

**Evidence:** listed above. Command `timeout 60 bash scripts/questions.sh check` in `/workspace/.claude/wt-devcycle`, exit 0, 2026-10-02T04:30:30Z. Output: fc8/logs/qcheck.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 16c** (`skills/dev-cycle/SKILL.md:56-58`) — behavioral. "anything else … file one" also catches a deliberately set `Build-loop policy: review`, the skill's own template value. Every cycle would then re-ask the user unless an entry is open. Fix: limit filing to lines that are neither exact value.
- **Claim 30a** (commit cfe4b51) — wording, commit message only. It says "symlinked paths are skipped". The skill and `docs/dev-cycle.md` follow symlinks and skip only paths that resolve outside the checkout.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`docs/working/questions.md:56`) — wording. "Only the next cycle's spot-check" leaves out step 1's health check and step 4's code-without-docs check.
- **Claim 9** (`scripts/dev-cycle.sh:16-17`, `:151`) — wording. The cut is on the printed line, prefix included. A 4095-byte trigger line is cut. Say "a printed line over 4096 bytes".
- **Claim 16b** (`skills/dev-cycle/SKILL.md:56`) — wording. "Two lines" does not say two of what. Make it "exactly one `Build-loop policy:` line".
- **Claim 17b** (`skills/dev-cycle/SKILL.md:63-64`) — behavioral. `inrepo` is false for any file not yet created, in repo or not. Literal use skips creating the record, roadmap and briefs. Say how to check a new file (resolve its parent).
- **Claim 18** (`skills/dev-cycle/SKILL.md:66-68`) — wording. The idea-log "no symlink" rule clashes with the general "symlinks followed" rule. The digest counts seeds through an in-repo symlink.
- **Claim 19b** (`skills/dev-cycle/SKILL.md:217-218`) — behavioral. The queue excludes `blocked` items indefinitely, not "while that entry is open". Nothing clears the mark.
- **Claim 19c** (`skills/dev-cycle/SKILL.md:219-221`) — behavioral. "Not queued again" holds only while the filed entry is open, and no stall count is carried.
- **Claim 20** (`skills/dev-cycle/SKILL.md:230-232`) — behavioral. The queue does not exclude `declined` items, so next cycle can re-hand declined work to a loop.
- **Claim 25** (`test/scripts/dev-cycle.bats:110`) — wording. "~1 minute" measured 16.5–18.5 s here. The test still catches the mutant.
- **Claim 27** (`test/scripts/dev-cycle.bats:316`) — wording, test reach. Section 5's CRLF branch is untested: mutant `m2` passes 20/20. Add a bare `## Next\r` heading.
- **Claim 29c** (commit ab8ec06) — wording, test reach. "A CRLF roadmap, and section 5's heading rule" does not test section 5's CRLF fix.
- **Claim 30c** (commit cfe4b51) — behavioral. "An item that stalls twice is not re-queued" holds only while its entry is open (see 19b, 19c, 20).

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

**Where it is saved.** At `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass8.md`. It follows the skill's format, starts with the requested `Commit: ab8ec06 (A) / cfe4b51 (B)` first line, and carries the `**Replication:** k=1 (loop pass, decision 031)` header. Every claim has a `**Legibility-target:**` tag, following the code-review default mapping.

**What it covers.** All three priority areas in the brief:
1. Area A (Claims 9–14, 25–27): the seed match's shape and linearity, the U+2028/2029 removal, the cut comment's scope, CRLF in both heading readers, the help range, and test reach against three mutants.
2. Commit messages ab8ec06 and cfe4b51 (Claims 29a–30d).
3. Area B (Claims 1–8, 15–24, 28):
   - the policy rule (one exact line, interim text, two lines, case)
   - the brief's `Policy:` line
   - the stop-condition list
   - the in-repo path rule and how a cycle applies it to writes and globs
   - the In flight states and the queue
   - the 6b record line and the final message
   - onboarding step 13, `docs/dev-cycle.md` against the skill's template, Q-103, row 68, global row 12 and the guide row

**What was run.**
- bats 20/20 at ab8ec06, and three mutants.
- shellcheck.
- `--help`.
- The cut boundary.
- U+2028/2029 against the old and new scripts.
- A 200,000-line seed fuzz and timing.
- No-resume timing.
- `inrepo` on new and symlinked paths.
- `questions.sh check`.

**What was not touched.** Nothing was committed. Nothing was written into either worktree except this report. Scratch is under `fc8/`.

**Hallucination log.** No new pattern qualified. The two Incorrect verdicts are a rule-scope defect and a commit-message mis-description, not fabricated symbols.
