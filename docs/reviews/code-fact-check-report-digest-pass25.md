Commit: cbfdf35 (A) / 77e21af (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at cbfdf35; HEAD 2121c24 adds only review docs under `docs/reviews/`). B: `/workspace/.claude/wt-devcycle` (content at 77e21af; HEAD 60fb513 merges A in; `skills/dev-cycle/SKILL.md` is unchanged between 77e21af and 60fb513).
**Scope:** Partial: the pass-24 fix round only. A: `git diff c1d0a80..cbfdf35 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of cbfdf35. B: `git diff fb643e2..77e21af -- skills/dev-cycle/SKILL.md` plus the message of 77e21af. Everything else is context only (rubric section "Pass 24").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 33
**Summary:** 23 verified, 8 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. No claim below matches a logged pattern. Neither Incorrect verdict is a fabricated symbol, API or flag, so nothing is appended to the log. The brief allows no other write anyway.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc25/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. The probes took the code under review with `git archive` or `git show <commit>:<path>` into the temp dir and ran it there. Every process ran under `timeout`, and none was still running at the end (`pgrep` found none). Both worktrees' `git status --short` is empty apart from this report. Nothing was written to `/workspace`'s own checkout.

The execution logs are scratch and are not committed. They are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc25/` (below, `fc25/`). The probes ran with cwd `fc25/`, and each script `cd`s into its own temp dir. The environment's `LC_ALL=en_US.UTF-8` is not installed, which is why the logs contain setlocale warnings. The script sets `LC_ALL=C` itself for its awk and grep calls.

Executed runs (UTC):
- **E1**, 16:22:41Z, `timeout 900 bash fc25/probe1.sh`, exit 0. The temp dir is `fc25/tmp.ZQFTuSQ6d5/`. It ran:
  - `bats test/scripts/dev-cycle.bats` on `cbfdf35:{scripts,test}`: 39 ok, 0 not ok, exit 0 → `bats.out`.
  - `shellcheck scripts/dev-cycle.sh`: exit 0, no findings → `sc.out`.
  - `--check-answer` with every `### Q-NNN` ID (99 IDs) from copies of `/workspace/docs/working/questions.md` and `questions-archive.md`, committed into a temp repo, under cbfdf35 and under c1d0a80 → `ans.new`, `ans.old`. The questions files are a time-varying input, and the results hold for those files as of 16:22Z.
- **E2**, 16:25:50Z, `timeout 300 bash fc25/probe2.sh` → `fc25/probe2.out`. This is an instrumented copy of cbfdf35's `ANSWER_AWK` that also prints the line that decided each entry (`<<...>>`). It covers all 99 IDs. The script exits 1 because its last `[ -n "$r" ] && echo` is false under `set -e` after the final ID. The output is complete: 99 of 99 IDs are present.
- **E3**, 16:24:11Z, `timeout 300 bash fc25/probe3.sh`, exit 0 → `fc25/probe3.out`. It covers:
  - P1, adversarial `--check-answer` entries under cbfdf35 and c1d0a80:
    - a `# comment` inside a fence in the entry;
    - a fenced `### Q-3` inside another entry;
    - an OPEN entry whose body says "set **Status:** ANSWERED";
    - an agent's `**Answered by agent (interim): [2]**` line;
    - an "Original entry:" quote.
  - P2, the `--check-brief` lifecycle:
    - an untracked brief;
    - a brief on main;
    - `Status: done` set on a feature branch, then merged with `--no-ff`;
    - after `git mv` into `closed/`, both the old and the new path.
  - P3, `--check-branch` on a merged branch, a squash-merged branch, `main`, and `trunk` in a repo with no main or master.
  - P4, `--check-fix` on dot-directories, a dot file, case variants and `claude.local.md`.
  - P5, the tail of `--help`.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the human reading the help, the record or the commit log.

---

## Claim 1: help: "--check-brief  for a build brief path (docs/working/briefs/YYYY-MM-DD-<slug>.md): "ok <path> new" when the default branch has no such file, else "ok <path> open|done|dropped <commit>" from its first exact "Status: ..." line on the default branch and the commit that last changed it there; "skip <path>: <reason>" otherwise."

**Location:** `scripts/dev-cycle.sh:29-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output forms and the source (MAIN_SHA's tree, never the working tree); it does not establish which commit "last changed it there" names for a change merged with `--no-ff` (see Claim 8), or that "new" means "never existed": it also prints after a `git mv` (see Claim 21).

```bash
# scripts/dev-cycle.sh:254-258
  if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi
  st="$(git cat-file blob "$MAIN_SHA:$a" | { env LC_ALL=C grep -m1 -E '^Status: (open|done|dropped)$' || true; })"
  c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
  if [[ -n "$st" ]]; then echo "ok $a ${st#Status: } $c"
  else echo "skip $a: no line that is exactly Status: open, done or dropped"; fi
```
(excerpt ends :258; enclosing `check_brief()` ends at :259 — read.) E3/P2 printed `ok … new` for an untracked brief and `ok … open 4ba5ad9…` once it was on main. bats test 38 shows that a `Status: done` in the working tree only is not read.

**Evidence:** `scripts/dev-cycle.sh:249-259`, `fc25/probe3.out`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** user / agent

---

## Claim 2: help: "--check-branch  "ok <name> <commit> <n>" for a brief's branch that exists (n: its commits not on the default branch) … or the default branch."

**Location:** `scripts/dev-cycle.sh:34-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output form and n as `git rev-list --count MAIN_SHA..sha`. It does not establish that n=0 means "no work" (see Claim 9). The default-branch refusal holds only when the default branch was found by name (Claim 10).

`echo "ok $a $sha $(git rev-list --count "$MAIN_SHA..$sha")"` (`scripts/dev-cycle.sh:274`). E3/P3 printed `ok feat/a f0628a7… 0` for a `--no-ff`-merged branch, `ok feat/sq b32b64f… 1` for a squash-merged branch, and `skip main: the default branch`.

**Evidence:** `scripts/dev-cycle.sh:265-276`, `fc25/probe3.out`
**Legibility-target:** user / agent

---

## Claim 3: help: "--check-fix  "ok <path>" for a file an in-cycle fix may edit: a tracked .md file under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, a dot-directory or an instruction file) or README.md"

**Location:** `scripts/dev-cycle.sh:40-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed exclusion as the code implements it; it does not establish that "instruction file" covers names beyond the four basenames (see Claim 11).

`elif [[ ! "$a" =~ ^docs/.*\.md$|^README\.md$ || "$a" =~ ^docs/(working|human-author|reviews|decisions)/ || "$a" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ ^(claude|agents|gemini|skill)\.md$ ]]` (`scripts/dev-cycle.sh:288-289`, joined). E3/P4 and bats tests 13 and 39 agree.

**Evidence:** `scripts/dev-cycle.sh:282-292`, `fc25/probe3.out`
**Legibility-target:** user / agent

---

## Claim 4: help: "--check-answer  "<option> Q-NNN" for a keep-or-drop-or-done question … keep, drop, done, open (not marked ANSWERED yet) or unrecognized (answered, but the answer does not start with one of the options)"

**Location:** `scripts/dev-cycle.sh:44-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five option outputs and the skip forms on bats fixtures and the real files; "not marked ANSWERED" carries the over-match described in Claim 12a.

`else if (count) print (!answered ? "open" : done ? result : "unrecognized")` (`scripts/dev-cycle.sh:350`). bats test 38 ("reads nothing from an entry not marked ANSWERED, and reads done") passes.

**Evidence:** `scripts/dev-cycle.sh:307-366`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** user / agent

---

## Claim 5: help range "sed -n '2,58p'"

**Location:** `scripts/dev-cycle.sh:121`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the range ends on the blank line :58, after the last header line :57, and before `set -euo pipefail` at :59; it does not establish that the range stays right after future header edits.

`-h|--help) sed -n '2,58p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/dev-cycle.sh:121`). E3/P5's tail ends with ":…or no perl; a failed step exits non-zero mid-digest. Printed repo text is data." and then a blank line.

**Evidence:** `scripts/dev-cycle.sh:55-59`, `fc25/probe3.out`
**Legibility-target:** maintainer

---

## Claim 6: "A done or dropped brief moves to briefs/closed/, so the open ones are all that the briefs/*.md glob lists."

**Location:** `scripts/dev-cycle.sh:228-229`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the move rule as the skill states it; it does not establish that the glob lists only open briefs between a build merge and the next cycle.

The move happens in the next cycle (SKILL.md:262 "`git mv` the brief there"). Until then, a brief whose merged status line says `done`, or one that `--check-brief` skips, is still in `briefs/` and is listed by the glob. (Paraphrased — no quote available because this is a timing property of the cycle, not of one line.) The skill's own wording is the precise version: "so the glob lists only briefs not yet moved" (SKILL.md:78). Wording only.

**Evidence:** `scripts/dev-cycle.sh:225-237`, `skills/dev-cycle/SKILL.md:76-78`
**Legibility-target:** maintainer

---

## Claim 7: "A brief's state, read only from the default branch's commit (never the working tree): its first line that is exactly "Status: open|done|dropped". "new" when the default branch has no such file."

**Location:** `scripts/dev-cycle.sh:245-247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source and the first-exact-line rule (bats test 38: a bullet "set this brief to Status: done" does not match, and `Status: closed` is skipped). It does not establish behavior for a CRLF brief: `Status: open\r` fails the `$`-anchored grep, so the brief is skipped, which is fail-safe. The working-tree `blocker` walk still runs first (:253).

Quoted at Claim 1 (`scripts/dev-cycle.sh:254-255`).

**Evidence:** `scripts/dev-cycle.sh:249-259`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** maintainer

---

## Claim 8: "The commit that last changed the file on the default branch is printed, so a Done entry can name it."

**Location:** `scripts/dev-cycle.sh:247-248`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which commit `git log -1 MAIN_SHA -- path` returns; it does not establish that this is the merge that landed the change.

`c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"` (`scripts/dev-cycle.sh:256`). git's history simplification follows the TREESAME parent through a merge. E3/P2 shows this:
- `Status: done` was committed on `feat/a` (f0628a7) and merged with `--no-ff` (merge 9fe77ef).
- The output was `ok … done f0628a767bee…`: the feature commit, not the merge.

It is reachable from the default branch, so "on the default branch" holds under the reachability reading. A reader who expects "the merge" (as SKILL.md:291's "Done … with the merge" does) gets the side-branch commit. Wording only: the commit is still a valid one to name.

**Evidence:** `scripts/dev-cycle.sh:256`, `fc25/probe3.out`
**Legibility-target:** maintainer / agent

---

## Claim 9: "The last field counts the branch's commits not on the default branch (0: no work yet)."

**Location:** `scripts/dev-cycle.sh:262-263`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, which is correct; it does not establish the "(0: no work yet)" reading.

E3/P3 printed `ok feat/a f0628a7… 0` for a branch with one commit that had already been merged with `--no-ff`. 0 means "nothing not already on the default branch", which includes "merged". A squash-merged branch printed `1` and keeps a nonzero count for as long as it exists. The skill handles the merged case (step 3's `[3] done` option). But a squash-merged brief whose status line was never set, and whose branch is kept, never "shows no work" and is never asked about. (Paraphrased — no quote available because this combines the probe output with SKILL.md:278-286.) Precise version: "(0: nothing beyond the default branch: no work yet, or already merged)". Wording.

**Evidence:** `scripts/dev-cycle.sh:274`, `fc25/probe3.out`
**Legibility-target:** maintainer

---

## Claim 10: "The default branch, when one was found by name, is refused."

**Location:** `scripts/dev-cycle.sh:264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main/master/origin-HEAD path and the current-branch fallback; it does not establish what the fallback means for the rest of the cycle.

`elif [[ -n "$MAIN_BY_NAME" && "$a" == "$MAIN" ]]` (:270); `MAIN_BY_NAME=1` only in the name loop (:380). E3/P3 printed `skip main: the default branch` in one repo, and `ok trunk 878cebf… 0` in a repo whose only branch is `trunk`.

**Evidence:** `scripts/dev-cycle.sh:270`, `scripts/dev-cycle.sh:369-389`, `fc25/probe3.out`
**Legibility-target:** maintainer

---

## Claim 11: "a tracked .md file under docs/, outside the cycle's own files, working/, human-author/ … reviews/ and decisions/ …, the settings file, any dot-directory, and any instruction file (CLAUDE.md, AGENTS.md, GEMINI.md, SKILL.md, any case); or README.md."

**Location:** `scripts/dev-cycle.sh:277-281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named exclusion, case-folding of the four basenames, and the `*/.*` test (in `[[ == ]]`, `*` crosses `/`, so any component starting with `.` matches). It does not establish that other instruction-file names are refused: `docs/g/claude.local.md` prints `ok`.

`base="${a##*/}"; low="$(printf '%s' "$base" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"` (:286). E3/P4 skipped `docs/.hidden/x.md`, `docs/a/.b/c.md`, `docs/.x.md` (a dot file too), `docs/g/Claude.Md` and `docs/g/<CLAUDE>.md`. It printed `ok` for `docs/g/ok.md`, `docs/decisionsX.md` and `docs/g/claude.local.md`. A brief path got the separate reason "one of the cycle's own files (use --check-write)". The parenthesis defines the list as those four names, so `claude.local.md` is residue, not a contradiction.

**Evidence:** `scripts/dev-cycle.sh:282-292`, `fc25/probe3.out`
**Legibility-target:** maintainer

---

## Claim 12a: "An entry whose "**Status:**" is not ANSWERED is open, whatever it contains: the answer is read only after it has been recorded."

**Location:** `scripts/dev-cycle.sh:296-297`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how `answered` is set; it does not establish that any real entry trips this (none does today).

```awk
# scripts/dev-cycle.sh:333
tolower($0) ~ /\*\*status:\*\* *answered/ { answered = 1 }
```
The test is an unanchored match on any non-fenced line of the entry, not on the entry's Status field. E3/P1: an entry whose header says `**Status:** OPEN` and whose body says "When answered, set **Status:** ANSWERED." followed by `- Q-4: [2]` printed `drop Q-4` (c1d0a80 also printed drop). "whatever it contains" is refuted by the contents. Behavioral. It needs body text that holds the literal bold `**Status:** answered` plus an answer-shaped line. A grep of both real files finds no such line outside header lines, and the keep-or-drop entry the skill files has none. Severity: low; the error is non-fail-safe (a wrong drop is possible).

**Evidence:** `scripts/dev-cycle.sh:327-351`, `fc25/probe3.out`
**Legibility-target:** maintainer

---

## Claim 12b: "Then the answer is the first line in the entry (outside a fence opened inside it) …"

**Location:** `scripts/dev-cycle.sh:297-299`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the answer search, which does skip fenced lines; it does not establish that fenced lines are inert for the entry's boundaries.

```awk
# scripts/dev-cycle.sh:328-332
heading($0) { count++; inside = (count == 1); fence = 0; next }
/^(#|##|###) / { inside = 0 }
!inside { next }
/^(```|~~~)/ { fence = !fence; next }
fence { next }
```
The heading tests now run before the fence test (at c1d0a80 the fence test came first). So a `# comment` line inside a fenced block in the entry ends the entry, and a fenced `### Q-N` inside another entry counts as a second heading. E3/P1 shows both:
- `**Answer:** [2]` after a fence holding `# set up`: `unrecognized Q-1` (c1d0a80: `drop Q-1`).
- A fenced `### Q-3 · x` in Q-2's body: `skip Q-3: more than one entry with this heading` (c1d0a80: `drop Q-3`).

Both fail safe (the user is asked again, or the entry is reported), but neither is stated. Behavioral: a regression against c1d0a80.

**Evidence:** `scripts/dev-cycle.sh:327-351`, `fc25/probe3.out`
**Legibility-target:** maintainer

---

## Claim 13: "… that starts, after an optional "- ", with "Q-NNN:" or a bold "**Answer:", "**Answer (" or "**Answered" label (any case). Its text starts after the label: at ":**" when the label alone is bold, else at the first ": ", and then ends at the bold's close if it opened inside the bold."

**Location:** `scripts/dev-cycle.sh:299-302`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label set, the `- ` strip and the text extraction. It does not establish that the line read is the user's: any line with that shape counts. In E3/P1, an agent-written `**Answered by agent (interim): [2]**` placed before the user's `**Answer:** [1]` printed `drop Q-5`. An "Original entry:" quote containing `- **Answer:** pending` before the real answer gave `unrecognized`.

`line = $0; sub(/^- /, "", line)` and `if (low !~ /^\*\*answer(:|ed| \()/) next` (`scripts/dev-cycle.sh:335`, `:338`). In E2, the line that decided each entry includes `- **Answered 2026-09-20: [2], test first.**` (Q-045) and `**Answer (2026-09-28): [1].**` (Q-091, Q-093–Q-095). In each of the four real "Original entry:" entries (Q-065, Q-066, Q-081, Q-083), the line read is the answer line before the quote.

**Evidence:** `scripts/dev-cycle.sh:334-347`, `fc25/probe2.out`, `fc25/probe3.out`
**Legibility-target:** maintainer

---

## Claim 14: "Only the text's leading token decides: [1], 1 or keep; [2], 2 or drop; [3], 3 or done (a word must be followed by the end, punctuation or a dash). Anything else, including a hedge or a bracket further in, is unrecognized"

**Location:** `scripts/dev-cycle.sh:302-305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `option()` mapping; it does not establish that `[1]`/`[2]`/`[3]` mean keep/drop/done in entries other than keep-or-drop ones (the real files hold none).

`if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"` (:313); there is no bracket fallback after it (:314-320). bats test 38 shows `not [2]; keep it` and `drop because [1] costs more` → unrecognized, and `[3] it shipped` and `done.` → done.

**Evidence:** `scripts/dev-cycle.sh:308-321`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** maintainer / user

---

## Claim 15: commit cbfdf35: "39/39; shellcheck clean."

**Location:** `cbfdf35` (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cbfdf35's tests and script in a clean temp copy; it does not establish the counts at 60fb513 (same blobs, not re-run there).

`bats test/scripts/dev-cycle.bats` gave 39 `ok`, 0 `not ok`, exit 0. `shellcheck scripts/dev-cycle.sh` gave exit 0 with no findings.

**Evidence:** `fc25/tmp.ZQFTuSQ6d5/bats.out`, `fc25/tmp.ZQFTuSQ6d5/sc.out`
**Legibility-target:** user

---

## Claim 16: commit cbfdf35: "On the real files Q-070, Q-071 and Q-073 go back to unrecognized (mid-line labels; asked again, never misread)."

**Location:** `cbfdf35` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 99 real IDs, cbfdf35 against c1d0a80, on /workspace's questions files as of 16:22Z. It does not establish that the keep/drop/done readings of non-keep-or-drop entries mean anything: the real files hold no keep-or-drop entry.

`diff ans.old ans.new` shows exactly six changes. Q-070, Q-071 and Q-073 go from keep to unrecognized. Q-019, Q-037 and Q-085 go from unrecognized to done, through `**Answered …:** done, …` and `[3]`. Nothing else changed. New totals: 23 keep, 19 drop, 3 done, 12 open, 42 unrecognized. In E2 no decided line is a quote or an agent note. Some readings map an entry's own option numbering, for example Q-051 "[1], drop both" → keep and Q-065 "[1] delete" → keep. Those entries are not keep-or-drop questions, so no step consumes them.

**Evidence:** `fc25/tmp.ZQFTuSQ6d5/ans.new`, `fc25/tmp.ZQFTuSQ6d5/ans.old`, `fc25/probe2.out`
**Legibility-target:** user

---

## Claim 17: commit cbfdf35: "Fences reset per entry, so an unclosed one hides nothing outside it."

**Location:** `cbfdf35` (commit message); `scripts/dev-cycle.sh:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reset at each matching heading (`fence = 0`); it does not establish that fenced heading-shaped lines are ignored (they are not; see Claim 12b).

`heading($0) { count++; inside = (count == 1); fence = 0; next }` (`scripts/dev-cycle.sh:328`). A fence left open in a previous entry is cleared when the target heading is reached. A fence inside the entry is not read past the entry, because `!inside { next }` (:330) runs before the fence toggle.

**Evidence:** `scripts/dev-cycle.sh:327-332`
**Legibility-target:** user / maintainer

---

## Claim 18: commit cbfdf35: "An acceptance criterion that mentions the status no longer matches."

**Location:** `cbfdf35` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a criterion line that does not start with `Status:`; it does not establish behavior for a line that is exactly `Status: done` placed before the real status line.

`grep -m1 -E '^Status: (open|done|dropped)$'` (:255). bats test 38's brief carries `- set this brief to Status: done in the merge` and reads `open`.

**Evidence:** `scripts/dev-cycle.sh:255`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** user

---

## Claim 19: "An in-cycle fix … edits only a file that `--check-fix '<path>'` prints `ok` for: a tracked `.md` file under `docs/` (not the cycle's own files, `docs/working/`, `docs/human-author/`, `docs/reviews/`, `docs/decisions/`, `docs/dev-cycle.md`, a dot-directory or an instruction file) or `README.md`"

**Location:** `skills/dev-cycle/SKILL.md:71-76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with `check_fix` (Claims 3 and 11); it does not establish that the cycle consults it before every edit.

The skill text matches `scripts/dev-cycle.sh:287-290` item for item, including the separate own-files branch. (Paraphrased — no quote available because this is a list comparison already quoted in Claim 3.)

**Evidence:** `skills/dev-cycle/SKILL.md:71-76`, `scripts/dev-cycle.sh:282-292`
**Legibility-target:** agent

---

## Claim 20: "Briefs in the directory are found only through `--check-path 'docs/working/briefs/*.md'` (a done or dropped brief moves to `docs/working/briefs/closed/`, so the glob lists only briefs not yet moved)."

**Location:** `skills/dev-cycle/SKILL.md:76-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the glob's reach (`:(glob)` with `*` not crossing `/`, so `closed/` is excluded, as bats test 36 shows); it does not establish that a brief this cycle wrote is listed (it is untracked, which the build-briefs rule handles separately).

`if [[ "$a" == *[*?]* ]]; then spec=":(glob)$a"` (`scripts/dev-cycle.sh:212`).

**Evidence:** `scripts/dev-cycle.sh:209-224`, `skills/dev-cycle/SKILL.md:296-299`
**Legibility-target:** agent

---

## Claim 21: "A brief's state comes only from `--check-brief '<path>'`, which reads its `Status:` line on the default branch: `ok <path> open|done|dropped <commit>`, or `ok <path> new` before it has landed"

**Location:** `skills/dev-cycle/SKILL.md:78-80`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the outputs and their source; it does not establish when "new" is printed.

"new" means only that the path is absent from MAIN_SHA's tree. Besides "before it has landed", that includes after the brief's `git mv` into `closed/` lands. In E3/P2 the old path printed `ok … new` and the `closed/` path printed `skip …: not an open build brief`. It also includes a brief that sits only on an unlanded cycle branch. The skip form, which step 1 handles at :265, is not listed here. The roadmap points at the `closed/` path after the move (:263), so the normal flow does not query the old path. Wording.

**Evidence:** `scripts/dev-cycle.sh:254`, `fc25/probe3.out`
**Legibility-target:** agent

---

## Claim 22: "a roadmap brief path counts as a brief (and holds a slot) only when that prints `open` or `new` and `--check-path` prints `ok`" (with :265 "A skip from `--check-brief` is recorded and the brief keeps its slot")

**Location:** `skills/dev-cycle/SKILL.md:80-82`, `skills/dev-cycle/SKILL.md:265`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's slot rules for a brief that `--check-brief` skips; it does not establish how often a skip occurs (it needs a missing or malformed status line, a CRLF brief, or a symlinked path).

The two sentences contradict each other for a skipped brief:
- :80-82: "holds a slot only when that prints `open` or `new`".
- :265: "A skip from `--check-brief` is recorded and the brief keeps its slot".
- The build-briefs count (:296-299, "while fewer than 3 briefs are open: the ones the Rules' glob lists plus any this cycle has written") uses the glob, which lists a skipped brief still in `briefs/`. That agrees with :265, not with :80-82.

An agent that follows :80-82 writes one more brief than one that follows :265. Behavioral (agent-facing). Severity: low; it is confined to skipped briefs.

**Evidence:** `skills/dev-cycle/SKILL.md:80-82`, `skills/dev-cycle/SKILL.md:265`, `skills/dev-cycle/SKILL.md:296-299`
**Legibility-target:** agent

---

## Claim 23: "A brief's branch is only ever named to `--check-branch '<name>'` … the cycle runs no git command with it." (and commit 77e21af: "The cycle runs no git command with a brief's branch")

**Location:** `skills/dev-cycle/SKILL.md:82-84`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git command the skill names; it does not establish what command the agent picks for "List merged branches" (:154), which names no command and skips brief branches by name.

The skill names five git commands:
- `git branch --show-current` (:27)
- `git add -A`, as a prohibition (:29)
- `git worktree list` and `git worktree prune` (:154)
- `git mv` of the brief file (:262)

None of them takes a brief's branch. The `git rev-list --count <default-commit>..<commit>` that fb643e2 had at the old :286 is gone. "Shows no work" now reads `ok <name> <commit> 0` (:285-286).

**Evidence:** `skills/dev-cycle/SKILL.md:27-29`, `skills/dev-cycle/SKILL.md:154`, `skills/dev-cycle/SKILL.md:262`, `skills/dev-cycle/SKILL.md:285-286`
**Legibility-target:** agent

---

## Claim 24: "A check that exits non-zero (no default branch, say) is recorded, and the step that needed it stops."

**Location:** `skills/dev-cycle/SKILL.md:85-86`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the example's premise, that check modes exit 1 with no default branch; it does not establish which steps "need" a given check.

`[[ -n "$MAIN_SHA" ]] || { echo "Could not resolve a default branch …" >&2; exit 1; }` (`scripts/dev-cycle.sh:389`) runs before the check dispatch (:391). A skip exits 0 (:402).

**Evidence:** `scripts/dev-cycle.sh:389-403`
**Legibility-target:** agent

---

## Claim 25: "`--check-brief` prints `done` … → Done, naming the commit it prints." (with :291 "**Done**: items finished since the last cycle, with the merge.")

**Location:** `skills/dev-cycle/SKILL.md:257-258`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the done → Done mapping; it does not establish that the commit printed is a merge.

As in Claim 8, a `--no-ff` merge yields the side-branch commit that set `Status: done` (E3/P2: f0628a7, not merge 9fe77ef). :291 still says "with the merge". Precise version: "naming the commit that set the status line". Wording.

**Evidence:** `skills/dev-cycle/SKILL.md:257-258`, `skills/dev-cycle/SKILL.md:291`, `fc25/probe3.out`
**Legibility-target:** agent

---

## Claim 26: "create `docs/working/briefs/closed/` if it is missing, `git mv` the brief there (same file name; the destination passes `--check-write`)"

**Location:** `skills/dev-cycle/SKILL.md:262-263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order (directory created first; pass 24's P4 showed `git mv` into a missing directory fails) and the destination's form; it does not establish the `blocker` result for a `closed/` that is a symlink (it would print a skip, which is correct).

`|| "$1" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]] || isbrief "$1"` (`scripts/dev-cycle.sh:236`).

**Evidence:** `scripts/dev-cycle.sh:233-244`, `skills/dev-cycle/SKILL.md:262-263`
**Legibility-target:** agent

---

## Claim 27: "`open` is not answered yet: leave the ID."

**Location:** `skills/dev-cycle/SKILL.md:270`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the meaning of `open` under cbfdf35's ANSWERED gate; it does not establish who sets ANSWERED.

`open` now also means "answered in the entry, but the entry's Status was never set to ANSWERED". In bats test 38, an OPEN entry holding `**Answer:** [2]` reads `open Q-4`. The skill never tells the cycle to record a reply or flip the status. That comes from the global questions protocol, and cbfdf35's commit note admits the gap. While such an ID stays `open`, step 3 files no new keep-or-drop (:278 "no ID on its `Asked:` line is still `open`"). So the brief holds its slot until someone sets the status. Precise version: "`open`: not marked ANSWERED yet (an answer written without setting the status is not read)". Behavioral.

**Evidence:** `scripts/dev-cycle.sh:350`, `skills/dev-cycle/SKILL.md:270`, `skills/dev-cycle/SKILL.md:278-279`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** agent

---

## Claim 28: "`drop` and `done` close the brief as in 1 … Add the ID to `Applied:` after `keep`, `drop`, `done` or `unrecognized`" with options "**[1] keep**, **[2] drop** and **[3] done**"

**Location:** `skills/dev-cycle/SKILL.md:271-275`, `skills/dev-cycle/SKILL.md:282-283`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement between the entry's option numbering and `option()`'s mapping, plus every output word the step handles; it does not establish the slug's uniqueness across re-asks.

`if (substr(s, 1, 3) == "[3]") return "done"` (`scripts/dev-cycle.sh:312`); `[1]`→keep, `[2]`→drop (:310-311). Every non-skip output (keep, drop, done, open, unrecognized) has a branch in step 2.

**Evidence:** `scripts/dev-cycle.sh:308-321`, `skills/dev-cycle/SKILL.md:266-286`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** agent

---

## Claim 29: ""Shows no work": `--check-branch` prints `absent`, skips the name (recorded), or prints `ok <name> <commit> 0`."

**Location:** `skills/dev-cycle/SKILL.md:285-286`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output shapes the rule reads; it does not establish that a squash-merged brief with an unset status line and a kept branch is ever asked: its n stays ≥1 (E3/P3 `ok feat/sq … 1`).

The output form is quoted at Claim 2. A `--no-ff`-merged branch reads 0 and is asked, which `[3] done` covers.

**Evidence:** `scripts/dev-cycle.sh:274`, `fc25/probe3.out`
**Legibility-target:** agent

---

## Claim 30: "(a file name no brief has used before, in `briefs/` or `briefs/closed/`: `--check-brief` prints `new` for it and `--check-path` on the same name under `closed/` prints a skip …)" (and commit 77e21af: "a new name is checked against both directories by name, not by the capped glob")

**Location:** `skills/dev-cycle/SKILL.md:300-303`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers briefs on the default branch (open: not `new`) and closed briefs that are tracked (`--check-path` gives `ok`); it does not establish that a brief written earlier in the same cycle is seen.

`--check-brief` prints `new` for any path absent from MAIN_SHA. E3/P2 printed `ok … new` for an untracked brief that existed in the working tree. So a second brief with the same slug in the same cycle passes both tests, and the second write would overwrite the first. Behavioral, low likelihood: same date and same slug within one cycle.

**Evidence:** `scripts/dev-cycle.sh:254`, `fc25/probe3.out`
**Legibility-target:** agent

---

## Claim 31: "a line that is exactly `Status: open`, … acceptance criteria (… "in the change that merges this work, change this brief's status line from open to done")"

**Location:** `skills/dev-cycle/SKILL.md:303-306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the criterion's text cannot match `^Status: (open|done|dropped)$` and that the exact line does; it does not establish that a build session edits the right line.

The criterion contains no line starting `Status:`. bats test 38 confirms that the first exact line wins.

**Evidence:** `scripts/dev-cycle.sh:255`, `fc25/tmp.ZQFTuSQ6d5/bats.out`
**Legibility-target:** agent

---

## Claim 32: "It prints `dropped` (the user set it), or keep-or-drop below says drop → Ideas … Keep-or-drop says done → Done, with the status line set to `Status: done` …"

**Location:** `skills/dev-cycle/SKILL.md:258-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the lifecycle new → open → done/dropped → `closed/` against each check's output. At each stage:
- the writing cycle: `new`;
- after landing: `open <c>`;
- after the build merge: `done <c>`;
- after the move: the old path reads `new`, but the roadmap points at `closed/`.

It does not establish behavior when the brief's `Status:` is changed on the default branch outside these paths (for example to `closed`, which is skipped).

(Paraphrased — no quote available because this is the step-by-step trace across :257-265 and `check_brief`, with the outputs from E3/P2.)

**Evidence:** `skills/dev-cycle/SKILL.md:257-265`, `scripts/dev-cycle.sh:249-259`, `fc25/probe3.out`
**Legibility-target:** agent

---

## Claims Requiring Attention

### Incorrect
- **Claim 12a** (`scripts/dev-cycle.sh:296-297`): `answered` is set by `**Status:** answered` anywhere in the entry, not by the Status field, so an OPEN entry whose body mentions it is read. Behavioral, low likelihood, non-fail-safe. Fix: anchor the test to the Needs/Status header line, or reword the comment.
- **Claim 22** (`skills/dev-cycle/SKILL.md:80-82` vs `:265`, `:296-299`): the slot rules contradict each other for a brief that `--check-brief` skips (:80-82 "only when open or new" vs :265 "keeps its slot" and the glob count). Behavioral (agent-facing), low.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`scripts/dev-cycle.sh:228-229`): the glob also lists done or dropped briefs not yet moved. Use the skill's wording. Wording.
- **Claim 8** (`scripts/dev-cycle.sh:247-248`): for a `--no-ff` merge the printed commit is the side-branch commit, not the merge. Wording.
- **Claim 9** (`scripts/dev-cycle.sh:262-263`): "0: no work yet" also covers an already-merged branch. Wording.
- **Claim 12b** (`scripts/dev-cycle.sh:297-299`): heading-shaped lines inside fences now end the entry or count as duplicate headings. This is a fail-safe regression against c1d0a80, and the comment does not state it. Behavioral.
- **Claim 21** (`skills/dev-cycle/SKILL.md:78-80`): `new` also appears after the move to `closed/` and for unlanded briefs, and the skip form is not listed here. Wording.
- **Claim 25** (`skills/dev-cycle/SKILL.md:257-258`, `:291`): "naming the commit it prints" names the side-branch commit, while Done says "with the merge". Wording.
- **Claim 27** (`skills/dev-cycle/SKILL.md:270`): `open` now includes an answer written without setting ANSWERED, and nothing in the skill sets it, so the brief can stall. Behavioral.
- **Claim 30** (`skills/dev-cycle/SKILL.md:300-303`): the uniqueness test misses a same-slug brief written earlier in the same cycle. Behavioral, low.

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass25.md`. Its first line is the commit line, and it carries the `**Replication:**` header field. Every claim has the seven mandatory fields plus a Legibility-target. Verdicts are counted in the Summary and listed under Claims Requiring Attention. Both lists in the brief were covered first:
- **A:** the real-entry diff, non-user lines (Claims 12–16), the MAIN_SHA read and `git log` after `git mv` (Claims 1, 7, 8, 21), merged and squash-merged counts (Claims 2, 9, 29), `*/.*` and basename case (Claim 11), the help range (Claim 5), commit cbfdf35 (Claims 15–18).
- **B:** the lifecycle (Claims 21, 22, 30–32), keep-or-drop-or-done (Claims 27, 28), git commands (Claim 23), commit 77e21af (Claims 23, 30).

Nothing was committed.
