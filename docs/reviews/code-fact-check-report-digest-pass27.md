Commit: b00c057 (A) / 7f3e392 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at b00c057; HEAD 380bcb7 adds only pass-26 review docs). B: `/workspace/.claude/wt-devcycle` (content at 7f3e392; merge c7a29b3 brings A in: `git diff 7f3e392 c7a29b3 -- skills/dev-cycle/SKILL.md` and `git diff b00c057 c7a29b3 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` are both empty, and b00c057 is an ancestor of c7a29b3).
**Scope:** Partial: the pass-26 fix round only. A: `git diff 10c2809..b00c057 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of b00c057. B: `git diff 875b41f..7f3e392 -- skills/dev-cycle/SKILL.md` plus the message of 7f3e392. Everything else is context only (rubric section "Pass 26").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 31
**Summary:** 21 verified, 9 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. Two claims are test or ID tallies, the class of the logged "85 tests" and "mode1-equiv 33" patterns. Both were re-counted by execution and hold (Claim 30). The one Incorrect verdict is a rule that names no check able to read its result. It is not a fabricated symbol, API or flag, so nothing is appended to the log, and the brief allows no other write.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc27/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. (The shared header text in `fc27/hdr.inc` was pasted into each script when it was written, not sourced at run time.) The probes took the code under review with `git show <commit>:<path>` or `git archive` into the temp dir and ran it there. Every process ran under `timeout`. At the end, `pgrep` showed none of mine still running. My probes wrote nothing to either worktree and nothing to `/workspace`'s own checkout. Its two questions files, and the B branch's at 875b41f and 7f3e392, were only copied into temp repos. `git status --short` at the end: `wt-devcycle` is clean. `wt-digest` shows the other critics' untracked pass-27 reports, this file, and `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats` modified (mtimes 16:55:44Z and 16:57:03Z, after my last probe at 16:52:38Z). Those edits are not mine. This report reviews the committed b00c057 through `git show`/`git archive`, not the working tree.

The execution logs are scratch and are not committed. They are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc27/` (below, `fc27/`). Each probe ran with cwd `fc27/`, and each script `cd`s into its own temp dir. `old` is 10c2809 and `new` is b00c057 throughout. The environment's `LC_ALL=en_US.UTF-8` is not installed, which is why the logs contain setlocale warnings.

Executed runs (UTC, 2026-10-02, all exit 0):
- **E1**, 16:48:20Z, `timeout 1000 bash fc27/probe1.sh` → `fc27/probe1.out`. Temp dir `fc27/tmp.8YRNbU0WR7/` holds `git archive b00c057`. It ran:
  - `bats test/scripts/dev-cycle.bats`: 44 ok, 0 not ok, exit 0 → `bats.out`;
  - `python3 scripts/hermeticity-lint --root .`: exit 0, "126 test file(s) checked, no unstubbed network spawns" → `lint.out`;
  - `shellcheck` on the script and on the bats file: exit 0 → `sc.out`, `scb.out`.
- **E2**, 16:48:47Z, `fc27/probe2.sh` → `probe2.out`. It ran `--check-answer` with all 99 IDs of `/workspace`'s current questions files, under old and new. The diff was empty.
- **E2b**, 16:49:19Z, `fc27/probe2b.sh` → `probe2b.out`. It did the same with the B branch's questions files at 875b41f and at 7f3e392. There are 102 IDs and 102 heading lines in each. Old and new were identical: 3 done, 19 drop, 26 keep, 13 open, 41 unrecognized. No `**Needs:**` line holds ANSWERED anywhere but at its end. Only Q-084 has heading-shaped lines inside a fence: 6 shell comments.
- **E3**, 16:49:50Z, `fc27/probe3.sh` → `probe3.out`. It reran pass 26's probes: fact-check P1, P6/P7, performance P4, security F1 and F3. It also added a shell-comment line in the target's fence. Its F5 cases broke on shell quoting and were rerun in E3b.
- **E3b**, 16:50:12Z, `fc27/probe3b.sh` → `probe3b.out`. It covered security F5, a forged entry in another entry's fence, with a ```` ``` ```` outer fence and with a ```` ```` ```` outer fence. It also ran a target entry whose four-backtick fence holds one three-backtick line.
- **E4**, 16:50:31Z, `fc27/probe4.sh` → `probe4.out`. It probed `-G'^Status: '` semantics (G1–G7). N1 is a four-backtick fence holding a balanced three-backtick block.
- **E5**, 16:51:00Z, `fc27/probe5.sh` → `probe5.out`. It ran all six check modes and the digest in four repos: D1 unborn, D2 detached with only `trunk`, D3 on `trunk`, and D4 detached with `main` as a control. It also grepped the real questions files for fence lines of four or more characters.
- **E6**, 16:51:31Z, `fc27/probe6.sh` → `probe6.out`. It ran 300 KB and 200 KB-one-line briefs, and `--check-fix` on instruction-file names.
- **E7**, 16:52:38Z, `fc27/probe7.sh` → `probe7.out`. C1 checked what each check prints for a brief moved to `closed/`. C2 tested the SIGPIPE threshold (60/70/100 KiB) and a two-brief batch. C3 used a future tip date.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the human reading the help, the record or the commit log.

**Pass-26 probes rerun against b00c057 (brief item 1).** Every pass-26 case that read a wrong keep, drop or done now reads a skip or `unrecognized`:

| Case | 10c2809 | b00c057 |
|---|---|---|
| FC P1 Q-1 / perf P4 without the dup (unclosed fence, next entry's answer) | `drop Q-1` | `unrecognized Q-1` |
| FC P1 Q-6 (fenced heading of Q-7 inside Q-6) | `keep Q-6` | `unrecognized Q-6` |
| FC P1 Q-7 (real entry after a fenced copy) | `open Q-7` | dup skip |
| FC P1 Q-8 (duplicate after an unclosed fence) | `unrecognized Q-8` | dup skip |
| FC P6 (answered copy quoted above an OPEN entry) | `drop Q-11` | dup skip |
| perf P4 (with the later duplicate) | `drop Q-1` | dup skip |
| sec F1 (Q-001 unclosed, Q-002 answers) | `unrecognized` | `unrecognized` |
| sec F5a (forged entry in a ```` ``` ```` fence, no real entry) | `done Q-017` | `unrecognized Q-017` |
| sec F3 briefs a, b (```` ~~~ ````/```` ``` ```` mixed) | `done` | `open` |

There are two residues, both outside the real files (E5: no fence line of four or more characters in either file):
- **The four-backtick case.** A ```` ```` ```` fence is closed by a ```` ``` ```` line. F5b reads `done Q-017`, the brief-c case reads `done`, and N1 reads `drop` where CommonMark's reading is `keep`. See Claims 5 and 14.
- **No real entry.** A forged entry with no real one is still read. See Claim 29a.

---

## Claim 1: help: "--check-brief … else "ok <path> open|done|dropped <commit>" from its first unfenced "Status:" line on the default branch and the commit that last changed a Status line there"

**Location:** `scripts/dev-cycle.sh:29-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed commit after a later Asked:/Kept: edit and after a `--no-ff` merge. It does not establish that "a Status line" means only the brief's real status line: `-G` matches any line starting `Status: `, fenced ones included (Claim 6).

`c="$(git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a")"` (`scripts/dev-cycle.sh:273`), with a fallback to the last commit touching the file (`:274`). E4 G1: status set on main, then an `Asked:` line appended. Old printed the `asked` commit; new prints the `done` commit `1b0ba11…`. E4 G2: status set on a side branch, `Kept:` edited on main, then a `--no-ff` merge. Old printed the merge `831bb3d…`; new prints the side commit `489b3aa…`.

**Evidence:** `scripts/dev-cycle.sh:256-277`, `fc27/probe4.out`
**Legibility-target:** agent / user

---

## Claim 2: help: "--check-answer … open (not marked ANSWERED yet) or unrecognized (answered, but the answer does not start with one of the options)"

**Location:** `scripts/dev-cycle.sh:47-52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help's definition of `unrecognized` against the new END rule. It does not establish whether a reader of the help needs the extra case (the skill treats every `unrecognized` alike).

`print (!answered ? "open" : broken ? "unrecognized" : done ? result : "unrecognized")` (`scripts/dev-cycle.sh:385`). `broken` is set when the target entry ends with a fence still open (`:363`, `:383`). So `unrecognized` now also means "a fence opened in the entry is still open at its end". That covers the case where the entry was cut at a heading-shaped line inside its own fence, even though a well-formed answer line follows (E3 P1 Q-1 and Q-6; E3 shell-comment Q-5: `keep` → `unrecognized`). The precise version: "unrecognized (answered, but no answer line starting with an option was read, or a fence in the entry is not closed)". Wording; the outcome is fail-safe.

**Evidence:** `scripts/dev-cycle.sh:47-52`, `scripts/dev-cycle.sh:361-386`, `fc27/probe3.out`
**Legibility-target:** user / agent

---

## Claim 3: help: "--check-brief and --check-branch need a default branch found by name (origin/HEAD, main or master): they read its commit."

**Location:** `scripts/dev-cycle.sh:53-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six modes in an unborn repo, a detached HEAD with no default branch, a `trunk`-only repo, and a detached HEAD with `main`. It does not establish origin/HEAD resolution, which this round did not change.

`[[ -n "$MAIN_SHA" || -n "$CHECK" ]] || { echo "Could not resolve …" >&2; exit 1; }` and `if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) && -z "$MAIN_BY_NAME" ]]; then … exit 1` (`scripts/dev-cycle.sh:424-430`). E5 D1 (unborn, files staged) and D2 (detached, only `trunk`):
- `--check-path`, `--check-write`, `--check-fix` and `--check-answer` exit 0 with the right answers (`ok README.md`, `ok docs/roadmap.md`, `ok docs/guide/a.md`, `keep Q-1`).
- `--check-brief` and `--check-branch` exit 1 with "needs a default branch".
- The digest exits 1 with "Could not resolve".

Old `--check-answer` exits 1 in D1, D2 and D3. D4 (control) answers in every mode.

**Evidence:** `scripts/dev-cycle.sh:404-443`, `fc27/probe5.out`
**Legibility-target:** user / agent

---

## Claim 4: help: "Exit: 0 digest printed (or, for the check modes, every argument answered …); 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:60-62`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which runs exit 1 for "no default branch". It does not establish the other exit-1 causes, which this round did not change.

Since `:424`, "no default branch" exits 1 only for the digest, `--check-brief` and `--check-branch`. The other four check modes answer (E5 D1/D2). The line is not wrong for those three. But nothing in it says the other check modes no longer exit 1. A reader of the Exit line alone would expect `--check-answer` to fail in an unborn repo. Precise version: "no default branch (the digest, --check-brief, --check-branch)". Wording, low.

**Evidence:** `scripts/dev-cycle.sh:53-54`, `scripts/dev-cycle.sh:60-62`, `scripts/dev-cycle.sh:424-430`, `fc27/probe5.out`
**Legibility-target:** user

---

## Claim 5: "its first line outside a ``` or ~~~ fence that starts with "Status:", which must be exactly "Status: open|done|dropped""

**Location:** `scripts/dev-cycle.sh:250-252`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three-character fences of either kind, mixed kinds, unclosed fences, CRLF and case variants. It does not hold for a fence opened by four or more characters, which the reader treats as a three-character fence.

```awk
# scripts/dev-cycle.sh:266-270
{ sub(/\r$/, "") }
seen { next }
fence != "" { if (substr($0, 1, 3) == fence) fence = ""; next }
/^(```|~~~)/ { fence = substr($0, 1, 3); next }
/^Status:/ { seen = 1; if ($0 ~ /^Status: (open|done|dropped)$/) print }')"
```

Results:
- **Mixed kinds (security F3).** E3 briefs a and b now read `open` (old: `done`).
- **Unclosed fence.** Brief d skips.
- **CRLF.** Brief e reads `open`.
- **Case variant.** Brief f skips.
- **Four-backtick fence.** Brief c reads `done` under both commits. It is ```` ```` ```` / ```` ``` ```` / `Status: done` / ```` ```` ```` / `Status: open`. The opener stores only its first three characters, so the inner ```` ``` ```` line closes it. Under CommonMark, a closing fence must be at least as long as its opener, so the quoted `Status: done` is still inside the block.

Behavioral, low: a brief would have to quote a code block inside a longer fence, above its real Status line, for a wrong `done`. No such case exists today (E5: no 4+-character fence lines in the questions files; briefs are not checked here). Precise version: "outside a fence (closed by a line starting with the opener's first three characters)", or track the opener's length.

**Evidence:** `scripts/dev-cycle.sh:250-277`, `fc27/probe3.out`
**Legibility-target:** maintainer / agent

---

## Claim 6: "The commit that last added or removed a Status line in the file there is printed: the commit that set the status, which a merge brought in."

**Location:** `scripts/dev-cycle.sh:254-255`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism, the last non-merge commit whose diff adds or removes a line matching `^Status: `. It does not hold for the gloss "the commit that set the status" when a later commit touches some other `Status: `-prefixed line.

The mechanism is right: `git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a"` (`:273`). Merges are not matched (E4 G2). The gloss fails in three executed cases, each printing the later commit rather than the one that set the status:
- **G5.** A later commit edits only a fenced `Status: open` example. It prints that commit, not the landing commit that holds `Status: done`.
- **G4.** A brief `git mv`'d into the path. It prints the rename.
- **G6.** A later CRLF→LF rewrite. It prints the rewrite.

G7 (squash) prints the squash commit, which is right.

The skill passes this commit to the record as the Done commit (Claim 19). Behavioral, low: the brief must have a fenced Status example edited after the status was set, or be renamed or rewritten whole on the default branch. Precise gloss: "usually the commit that set the status; any later commit that adds or removes a line starting `Status: `, fenced or not, wins".

**Evidence:** `scripts/dev-cycle.sh:254-277`, `fc27/probe4.out`
**Legibility-target:** maintainer / agent

---

## Claim 7: "The whole blob is read (no early exit, which would kill git cat-file with SIGPIPE under pipefail); a fence closes only with the characters that opened it."

**Location:** `scripts/dev-cycle.sh:263-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-early-exit read and its effect on large briefs and batches. It does not establish the fence half for four-character openers (Claim 5).

The awk program has no `exit`. After the first Status line, `seen { next }` skips the rest (`:267`). E7 C2:
- At 60 KiB, both commits answer.
- At 70 KiB and 100 KiB, old prints nothing and new answers.
- A batch of the 100 KiB brief and a small one: old exits 141 with no output for either; new answers both.

E6: the 300 KB and 200 KB-single-line briefs answer under new (exit 0) and fail under old (exit 141).

**Evidence:** `scripts/dev-cycle.sh:262-270`, `fc27/probe6.out`, `fc27/probe7.out`
**Legibility-target:** maintainer

---

## Claim 8: "The commit on the default branch that last added or removed a Status line in this file (not a later edit to its Asked:/Kept: lines, nor the merge)."

**Location:** `scripts/dev-cycle.sh:271-272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named exclusions (E4 G1, G2) and a conflict-resolving merge (G3, where the printed commit is a side commit, never the merge). It does not establish which of two same-second commits `-1` picks when timestamps tie (G3's two candidates shared a second), or the fenced-line case (Claim 6).

`-G'^Status: '` (`:273`). `git log` shows no diff for merges by default, so a merge never matches. An `Asked:` or `Kept:` append leaves the Status line as context, not as an added or removed line. E4: G1 prints the `done` commit, not `asked`. G2 prints the side commit, not the merge.

**Evidence:** `scripts/dev-cycle.sh:271-274`, `fc27/probe4.out`
**Legibility-target:** maintainer

---

## Claim 9: "the date of its tip commit, YYYY-MM-DD in the committer's own time zone (as the committer set it: a future date is possible)."

**Location:** `scripts/dev-cycle.sh:283-284`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed date for a committer-set future date. It does not establish the zone handling beyond pass 26's E3/P4 (`fc26/probe3.out`), which this round did not change.

`$(git log -1 --format=%cs "$sha")` (`:295`). E7 C3: with `GIT_COMMITTER_DATE='2099-01-01T00:00:00+0000'`, the output is `ok feat/f f27f6f5… 1 2099-01-01`.

**Evidence:** `scripts/dev-cycle.sh:286-298`, `fc27/probe7.out`
**Legibility-target:** agent / maintainer

---

## Claim 10: "any instruction file (CLAUDE.md, AGENT(S).md, GEMINI.md, SKILL.md, any case)" and "Instruction-file basenames, lower-cased: CLAUDE.md, CLAUDE.local.md, AGENTS.override.md and the like, GEMINI.md, SKILL.md."

**Location:** `scripts/dev-cycle.sh:302`, `scripts/dev-cycle.sh:304-307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 16 names in E6 under the C locale. It does not establish names with non-ASCII letters (refused earlier by `pathform`) or `skill.<x>.md`, which the comment does not claim.

`INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'` (`:307`). E6:
- Skipped: `agent.md`, `AGENT.md`, `Agents.md`, `agent.local.md`, `AGENT.Override.md`, `claude.md`, `Claude.Local.md`, `gemini.md`, `SKILL.md`.
- Allowed: `agentx.md`, `xagent.md`, `agents-notes.md`, `skill.local.md`, `agent..md`, `agent.a.b.md`, `guide.md`.

E1: the hermeticity lint is clean with the explicit-character pattern.

**Evidence:** `scripts/dev-cycle.sh:299-318`, `fc27/probe6.out`, `fc27/tmp.8YRNbU0WR7/lint.out`
**Legibility-target:** maintainer

---

## Claim 11: "Prints keep, drop, done, open, unrecognized, dup (the heading appears more than once), or nothing when the file has no such entry."

**Location:** `scripts/dev-cycle.sh:319-321`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dup detection for every heading-shaped `### Q-NNN` line, fenced or not, which now always counts (pass 26's Claim 10 Incorrect is fixed). It does not establish what an ID with only a fenced (forged) entry and no real one reads (Claim 29a).

`heading($0) { count++; inside = (count == 1); fence = ""; header = 0; next }` runs before any fence test (`:362`). `if (count > 1) print "dup"` (`:384`). E3: the dup skip now comes back for FC P1 Q-7, Q-8, P6 Q-11 and perf P4 Q-1, where old read `open`, `unrecognized`, `drop` and `drop`. P7 is unchanged (dup).

**Evidence:** `scripts/dev-cycle.sh:341-386`, `fc27/probe3.out`
**Legibility-target:** maintainer / agent

---

## Claim 12: "An entry is answered only when its header line (the first line starting "**Needs:**", as questions.sh writes it) ends with " **Status:** ANSWERED"; any other entry is open, whatever its body says"

**Location:** `scripts/dev-cycle.sh:322-325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the anchored match after the CR strip, the bats Q-4 shape and all 102 real entries. It does not establish a `**Needs:**` line placed inside a fence before the real header (skipped as fenced, so the real header is then read).

`!header && /^\*\*Needs:\*\*/ { header = 1; answered = ($0 ~ / \*\*Status:\*\* ANSWERED$/); next }` (`:367`), after `{ sub(/\r$/, "") }` (`:361`). The bats case `**Status:** OPEN (was **Status:** ANSWERED)` reads `open Q-4` (E1, test at `test/scripts/dev-cycle.bats:778`). E3 P1 Q-3, Q-4 and Q-5 (`Answered`, `ANSWERED, 2026-10-01`, Status on its own line) read `open`. In E2b, no real header holds ANSWERED anywhere but at its end, and both commits read all 102 IDs the same.

**Evidence:** `scripts/dev-cycle.sh:361-367`, `fc27/probe2b.out`, `fc27/probe3.out`, `fc27/tmp.8YRNbU0WR7/bats.out`
**Legibility-target:** maintainer / agent

---

## Claim 13: "Entries are bounded by heading lines alone (a heading inside a fence still ends the entry, which can only lose an answer)."

**Location:** `scripts/dev-cycle.sh:325-326`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bound and its fail-safe direction. It does not establish that "heading lines" means Markdown headings: the code ends the entry at any line starting `# `, `## ` or `### `, so a shell comment in a fenced command block counts.

`/^(#|##|###) / { if (inside && fence != "") broken = 1; inside = 0 }` (`:363`) runs before the fence skip (`:365`). An early end can only drop lines after the cut, and an open fence at the cut sets `broken`. So the result moves only toward `open` or `unrecognized`, as claimed (E3: P1 Q-1 and Q-6, F1). But the trigger is wider than "heading". E3: an ANSWERED entry whose fenced block holds `# step 1: run it` and whose `- Q-5: [1]` follows the fence reads `unrecognized` (old: `keep`). In the real files, Q-084's fenced command block holds six such `# 1. …` lines (E2b). It is OPEN and not a keep-or-drop entry, so its reading does not change. The bats comment at `test/scripts/dev-cycle.bats:758` already says "heading-shaped line". Precise version: "bounded by lines starting `#`, `##` or `###` and a space, even inside a fence (a shell comment in a fenced block ends the entry too)". Wording; fail-safe.

**Evidence:** `scripts/dev-cycle.sh:319-386`, `fc27/probe2b.out`, `fc27/probe3.out`
**Legibility-target:** maintainer / agent

---

## Claim 14: "Inside the entry, lines in a fence are skipped; a fence closes only with the characters that opened it, and one still open when the entry ends makes the answer unrecognized."

**Location:** `scripts/dev-cycle.sh:326-329`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three-character fences of either kind and the unclosed-at-end rule. It does not hold for a fence opened by four or more characters.

`fence != "" { if (substr($0, 1, 3) == fence) fence = ""; next }` / `/^(```|~~~)/ { fence = substr($0, 1, 3); next }` (`:365-366`). It works for these cases:
- bats Q-3: ```` ~~~ ```` around a ```` ``` ```` line and `**Answer:** [2]`, then `**Answer:** [1]` → `keep`;
- E3 P1 Q-1 → `unrecognized`.

It fails for four-character fences. In E4 N1, an ANSWERED entry holds ```` ```` ```` / ```` ``` ```` / `- Q-20: [2]` / ```` ``` ```` / ```` ```` ````, then `- Q-20: [1]`. Under CommonMark, the whole block is one fence and the answer is `[1]` keep. The reader closes the four-backtick fence at the first ```` ``` ```` and reads `- Q-20: [2]`. Both commits print `drop Q-20`. In E3b, the same shape with one inner line ends `unrecognized`, so only a balanced inner block gives a wrong answer.

Behavioral, low: it needs an answered keep-or-drop entry that quotes a fenced answer line inside a longer fence above the real answer. E5 found no fence line of four or more characters in either real questions file. Fix or wording: store the opener's run length and close only on a run at least that long, or say "closes at the first line starting with the opener's first three characters".

**Evidence:** `scripts/dev-cycle.sh:361-386`, `fc27/probe3.out`, `fc27/probe3b.out`, `fc27/probe4.out`, `fc27/probe5.out`
**Legibility-target:** maintainer / agent

---

## Claim 15: "--check-brief and --check-branch read the default branch's commit, so they need one found by name (origin/HEAD, main or master), not the current branch; the other modes do not use it."

**Location:** `scripts/dev-cycle.sh:425-427`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `MAIN`, `MAIN_SHA` and `MAIN_BY_NAME` read on a check-mode path. It does not cover the digest path after `:445`, which the `:424` guard still protects.

`grep -n` for `MAIN_SHA` finds reads only at `:261`, `:265`, `:273`, `:274` (check_brief), `:295` (check_branch), and `:482`, `:489`, `:492`, `:650` (digest). `MAIN`/`MAIN_BY_NAME` are read at `:291` (check_branch) and in the digest. Of these, `check_path`, `check_write`, `check_fix` and `check_answer` (`:214-249`, `:308-318`, `:387-401`) read none. So no empty `MAIN_SHA` reaches git in a check mode. (paraphrased — no quote available because the claim covers the absence of reads, established by a grep over the whole script.) E5 D1/D2 confirms by execution.

**Evidence:** `scripts/dev-cycle.sh:256-318`, `scripts/dev-cycle.sh:387-443`, `fc27/probe5.out`
**Legibility-target:** maintainer

---

## Claim 16: "A roadmap In flight path that `--check-path` skips (the brief moved, or never landed) is recorded and its line corrected: pointed at `briefs/closed/<same name>` if `--check-path` prints `ok` there, otherwise removed."

**Location:** `skills/dev-cycle/SKILL.md:84-86`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the cycle's checks can do with a corrected line that points at `closed/`. It does not establish how often a brief reaches `closed/` without its roadmap line following. Step 1 moves the line itself (`:270-271`), so this needs a move made outside a cycle, or a cycle whose roadmap edit did not land.

The rule calls the line "corrected" once it points at `closed/`. But no check can read that line:
- **`--check-path` / `--check-brief`.** `--check-path` prints `ok` for the closed path, but `--check-brief` refuses it: `skip docs/working/briefs/closed/2026-01-01-a.md: not an open build brief (docs/working/briefs/YYYY-MM-DD-<slug>.md)` (E7 C1, both commits). That comes from `isbrief`, whose slug class has no `/` (`scripts/dev-cycle.sh:235-237`).
- **No other state source.** The skill says "A brief's state comes only from `--check-brief '<path>'`" (`skills/dev-cycle/SKILL.md:78-79`).
- **The section is wrong for it.** In flight holds "items with an open build brief" (`:261`).

A line pointed at `closed/` and left in In flight never meets In flight step 1. Step 1 needs `done` or `dropped`, and the check prints a skip every cycle. Nothing permitted says whether the line belongs in Done or in Ideas (moved bodily). The rule does not say which section the corrected line goes to.

It also does not say which check proves "the brief moved" rather than "never landed". The same `--check-path` skip covers both (E7 C1: the old path skips with "no tracked file").

Behavioral; it fails toward a stuck line, not a wrong close. The closed brief is not globbed, so it holds no slot, and a recorded skip repeats each cycle. Medium confidence: an agent might infer "move it to Done/Ideas", but no permitted check tells it which. Fix options:
- `--check-brief` accepts `briefs/closed/` paths and prints their status. The stale-line rule then sends the line to Done (done) or Ideas (dropped), as step 1 does.
- Or the rule moves the corrected line out of In flight and says where.

**Evidence:** `skills/dev-cycle/SKILL.md:76-87`, `skills/dev-cycle/SKILL.md:261-273`, `scripts/dev-cycle.sh:235-237`, `scripts/dev-cycle.sh:256-261`, `fc27/probe7.out`
**Legibility-target:** agent

---

## Claim 17: "A brief that holds a slot but that no In flight line names gets one, so In flight's checks reach it."

**Location:** `skills/dev-cycle/SKILL.md:86-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the consequence: once the brief is named on an In flight line, steps 1–3 run on its path. It does not establish any check behind "no In flight line names it". No check mode compares the glob's output with the roadmap; the agent compares strings.

In flight checks "each, in this order" every item naming a brief path (`:261-262`). A slot-holding brief is listed by `--check-path 'docs/working/briefs/*.md'` or was written this cycle (`:81-82`). Its path passes `isbrief`, so `--check-brief` reads it (unlike Claim 16's closed path). On the brief's question: the only checks involved are `--check-path` on the glob and on the roadmap's In flight paths. "Names it" is an equality test the agent does between those two `ok` lists. (paraphrased — no quote available because the claim covers the absence of any check mode that compares roadmap lines with the glob; `scripts/dev-cycle.sh:8-14` lists all six modes and none reads `docs/roadmap.md` for In flight paths. The digest's section 7 only counts In flight items at `:665-669`.) The digest prints no In flight paths. That leaves a judgment step in prose where the user wants mechanical rules in tested code. That is a design note for the critics, not a mismatch.

**Evidence:** `skills/dev-cycle/SKILL.md:76-87`, `skills/dev-cycle/SKILL.md:261-262`, `scripts/dev-cycle.sh:8-14`, `scripts/dev-cycle.sh:614-623`, `scripts/dev-cycle.sh:665-669`
**Legibility-target:** agent

---

## Claim 18: "Skip any branch or worktree a brief holding a slot (as in the Rules) names: work on it may be in progress."

**Location:** `skills/dev-cycle/SKILL.md:160-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wording's agreement with the one slot rule. It does not establish how the agent reads a branch name from the brief text: a branch is named only to `--check-branch` (`:87-90`).

The Rules define "**A brief holds a slot** when the glob lists it or this cycle wrote it, unless `--check-brief` prints `done` or `dropped` for it" (`:81-83`). The cleanup sentence now cites it verbatim ("as in the Rules"). Build briefs (`:311`) and the record template (`:340`) do the same. That closes pass 26's "open brief" mismatch.

**Evidence:** `skills/dev-cycle/SKILL.md:81-84`, `skills/dev-cycle/SKILL.md:160-163`, `skills/dev-cycle/SKILL.md:310-312`
**Legibility-target:** agent

---

## Claim 19: "→ Done, naming the commit it prints (the last commit on the default branch that changed the brief's Status line)."

**Location:** `skills/dev-cycle/SKILL.md:263-265`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gloss against the script's `-G'^Status: '`. It does not establish the squash or rebase case beyond G7 (squash: correct).

Usually right: E4 G1 and G2 print the commit that set `done`, not a later `Asked:` edit or the merge. But the script selects any commit that adds or removes a line starting `Status: `, not "the brief's Status line" (Claim 6). A later edit to a fenced `Status:` example, a rename into the path, or a whole-file rewrite is printed instead (E4 G5, G4, G6). Then the Done item names a commit that did not set the status. Precise gloss: "the last commit on the default branch that added or removed a line starting `Status: ` in the brief". Behavioral, low: a misattributed commit in the record only, never a wrong state.

**Evidence:** `skills/dev-cycle/SKILL.md:263-273`, `scripts/dev-cycle.sh:271-274`, `fc27/probe4.out`
**Legibility-target:** agent / user

---

## Claim 20: "`open` is not answered yet (or the answer is not recorded: an entry is read only once its header says ANSWERED): leave the ID, and list it in the final message with its brief, so a reply written in place gets recorded."

**Location:** `skills/dev-cycle/SKILL.md:278-281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement of `open` with the script, and that the final-message paragraph now carries the list. It does not establish how a reply "written in place" gets recorded; that is the questions protocol's job.

`print (!answered ? "open" : …)` (`scripts/dev-cycle.sh:385`), with the anchored gate at `:367`. The final message now lists "any keep-or-drop answer step 6 could not read or that is still `open` (with its brief)" (`skills/dev-cycle/SKILL.md:356-358`). That closes pass 26's Claim 21 gap. The brief comes from the In flight item being checked, so the information exists where it is needed. The date clause is gone.

**Evidence:** `skills/dev-cycle/SKILL.md:274-288`, `skills/dev-cycle/SKILL.md:356-358`, `scripts/dev-cycle.sh:367`, `scripts/dev-cycle.sh:385`
**Legibility-target:** agent

---

## Claim 21: "A tip date after today is recorded and counts as idle (the committer sets the date)."

**Location:** `skills/dev-cycle/SKILL.md:298-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthesis: the printed date is the committer-set date and can be in the future. It does not establish the policy's merits (a branch with a future-dated tip is asked keep-or-drop sooner), which is a design choice.

E7 C3: `ok feat/f f27f6f5… 1 2099-01-01` from `git log -1 --format=%cs` (`scripts/dev-cycle.sh:295`). This closes security pass-26's "never asked" path: a future date was never "more than 14 days before today".

**Evidence:** `skills/dev-cycle/SKILL.md:289-299`, `scripts/dev-cycle.sh:283-295`, `fc27/probe7.out`
**Legibility-target:** agent

---

## Claim 22: record template "6. roadmap: <done>; briefs: <written this cycle, or none>; <k>/3 slots held (3/3: no new briefs)"

**Location:** `skills/dev-cycle/SKILL.md:340`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the label's agreement with "while fewer than 3 briefs hold a slot (as in the Rules; each counted once)". It does not establish how the agent counts k beyond that rule.

`:310-312` and `:81-84`, quoted in Claim 18. Pass 26's Claim 25 wording fix is in.

**Evidence:** `skills/dev-cycle/SKILL.md:310-312`, `skills/dev-cycle/SKILL.md:340`
**Legibility-target:** agent / user

---

## Claim 23: final message: "list the new `you: judgment` entries by ID and name, any keep-or-drop answer step 6 could not read or that is still `open` (with its brief), and each brief holding a slot by path"

**Location:** `skills/dev-cycle/SKILL.md:356-358`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the list against In flight step 2's three report-to-the-user outcomes. It does not establish the final message's other content.

Step 2 sends three outcomes to the final message: `open` ("list it in the final message with its brief", `:280`); `unrecognized` ("goes in the record and the final message", `:283`); and `skip` ("goes in the record and the final message", `:287`). The final-message sentence names "could not read" (a skip) and "still `open`". An `unrecognized` answer was read but not understood, so it fits "could not read" only loosely. An agent following this sentence could leave it out. Also, "(with its brief)" is attached only to the open clause, though the skip and unrecognized cases have a brief too. Precise version: "any keep-or-drop answer step 6 skipped, could not recognize, or found still `open`, each with its brief". Wording, agent-facing, low.

**Evidence:** `skills/dev-cycle/SKILL.md:274-288`, `skills/dev-cycle/SKILL.md:356-360`
**Legibility-target:** agent / user

---

## Claim 24: test comment "A heading-shaped line ends the entry even inside a fence: the answer after it is lost (unrecognized, asked again), never read from elsewhere."

**Location:** `test/scripts/dev-cycle.bats:758-759`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture: Q-2's fenced `# a comment, not a heading`, then `**Answer:** [2]`, read as `unrecognized`. It does not establish "asked again", which the skill does (`skills/dev-cycle/SKILL.md:283-284`: "the user answers on the next keep-or-drop entry, which step 3 files").

`[[ "$output" == *"open Q-1"* && "$output" == *"unrecognized Q-2"* ]]` (`test/scripts/dev-cycle.bats:760`). E1: the test passes. The script rule is `:363` (Claim 13).

**Evidence:** `test/scripts/dev-cycle.bats:745-763`, `fc27/tmp.8YRNbU0WR7/bats.out`
**Legibility-target:** maintainer

---

## Claim 25: test name "--check-brief and --check-branch need a default branch found by name; the others do not"

**Location:** `test/scripts/dev-cycle.bats:765`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The test covers both refusing modes and one of the four others (`--check-path`). E5 covers the other three modes, an unborn repo and a detached HEAD.

The test loops `for m in --check-branch --check-brief` asserting exit 1 and "needs a default branch". It then asserts `--check-path README.md` exits 0 with `ok README.md` (`test/scripts/dev-cycle.bats:765-776`). E1 passes; E5 D1–D3 is Claim 3.

**Evidence:** `test/scripts/dev-cycle.bats:765-776`, `fc27/tmp.8YRNbU0WR7/bats.out`, `fc27/probe5.out`
**Legibility-target:** maintainer

---

## Claim 26: test name "an unclosed fence stays inside its entry; fences close only with their own kind; the gate is anchored"

**Location:** `test/scripts/dev-cycle.bats:778`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-1 (unclosed, `unrecognized`), Q-3 (```` ~~~ ```` around ```` ``` ````, `keep`) and Q-4 (`open`). It does not cover four-character fences (Claim 14).

`for want in "unrecognized Q-1" "keep Q-3" "open Q-4"` (`test/scripts/dev-cycle.bats:791-793`). E1 passes.

**Evidence:** `test/scripts/dev-cycle.bats:778-793`, `fc27/tmp.8YRNbU0WR7/bats.out`
**Legibility-target:** maintainer

---

## Claim 27: test name "--check-brief reads a large brief whole and names the commit that set its status"

**Location:** `test/scripts/dev-cycle.bats:795`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 200 KB single-line brief and a later `Asked:` append. It does not cover a later fenced-example edit (Claim 6).

`[[ "$output" == "ok $b done $c" ]]`, where `c` is the `status done` commit and an `Asked:` commit follows (`test/scripts/dev-cycle.bats:797-805`). E1 passes. E6 shows old exits 141 on the same shape.

**Evidence:** `test/scripts/dev-cycle.bats:795-805`, `fc27/tmp.8YRNbU0WR7/bats.out`, `fc27/probe6.out`
**Legibility-target:** maintainer

---

## Claim 28: test name "a fenced copy of an entry quoted in another entry makes the ID a duplicate, never its answer"

**Location:** `test/scripts/dev-cycle.bats:807`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fenced answered copy above a real OPEN entry in the same file (dup skip), and the quoting entry reading `unrecognized`. It does not establish the case with no real entry, where the fenced copy is the only entry (Claim 29a).

`[[ "$output" == *"skip Q-11: more than one entry with this heading"* ]]` and `*"unrecognized Q-10"*` (`test/scripts/dev-cycle.bats:818-819`). E1 passes. E3 P6 gives the same result on pass 26's shape.

**Evidence:** `test/scripts/dev-cycle.bats:807-820`, `fc27/tmp.8YRNbU0WR7/bats.out`, `fc27/probe3.out`
**Legibility-target:** maintainer

---

## Claim 29a: commit b00c057: "A fenced copy of an entry quoted in another one makes the ID a duplicate (skip), never its answer."

**Location:** `b00c057` (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim when the real entry exists in the same file (dup) or in the other questions file (the "in both" skip, `scripts/dev-cycle.sh:396`). It does not hold when the ID has no real entry.

With a real entry, `count > 1` → `dup` (Claim 11). Without one, the fenced copy is the entry. Security pass-26 F5's shape is a forged `### Q-017` with an ANSWERED header and `**Answer:** [3]`, quoted in Q-090's fence:
- E3b F5a (```` ``` ```` outer): now `unrecognized Q-017`, because the quote's closing fence opens one inside the forged entry.
- E3b F5b (```` ```` ```` outer holding one ```` ``` ```` line): `done Q-017` under both commits. That line opens a fence and the ```` ```` ```` closes it (Claim 14).

Behavioral, low: the brief's `Asked:` ID must have no real entry in either file (deleted, never filed, or a typo), and some entry must quote an answered copy of it in a four-character fence. "Never its answer" holds only when a real entry exists. Precise version: "…makes an existing ID a duplicate (skip)".

**Evidence:** `scripts/dev-cycle.sh:361-401`, `fc27/probe3b.out`
**Legibility-target:** user / maintainer

---

## Claim 29b: commit b00c057, remaining bullets ("entries are bounded by heading lines alone again, so an unclosed fence in one entry can no longer hide the next entry's heading and read its answer" / "The ANSWERED gate is anchored at the header line's end" / "--check-brief reads the whole blob (an early awk exit killed git cat-file with SIGPIPE above 64 KiB, exit 141 for the whole batch), handles fences by kind, and prints the commit that last changed a Status line (-G), not a later Asked:/Kept: edit or the merge" / "Only --check-brief and --check-branch need a default branch found by name; the other four modes answer in any repo again." / "The instruction-file pattern lists its characters one by one and also covers AGENT.md; the tip date's time zone is documented." / "Tests: … 44/44; shellcheck and the hermeticity lint clean; all 102 real IDs read as before.")

**Location:** `b00c057` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the diff and E1–E7. "Above 64 KiB" is the pipe-buffer threshold, bracketed only between 60 and 70 KiB (E7 C2). It does not establish the fence bullets for four-character fences (Claims 5, 14).

Each bullet was checked:
- **Fences.** E3: perf P4 and FC P1 Q-1 read `unrecognized` rather than `drop`.
- **Gate.** Claim 12.
- **SIGPIPE.** E7 C2: 60 KiB fine under old, 70 KiB exit 141. A two-brief batch under old exits 141 with no output for either, which is "the whole batch".
- **Commit.** E4 G1/G2.
- **Mode gate.** E5 D1–D3.
- **AGENT.md.** E6.
- **Tallies.** E1 44 ok; shellcheck and lint exit 0. E2b: 102 IDs, identical output at 10c2809 and b00c057, on the B branch's questions files. `/workspace`'s current files hold 99 IDs, also identical (E2).

Both tallies match their count. This is the class of the logged tally patterns ("85 tests", "mode1-equiv 33"), checked here and true.

**Evidence:** `scripts/dev-cycle.sh:250-307`, `scripts/dev-cycle.sh:319-430`, `fc27/probe1.out`, `fc27/probe2.out`, `fc27/probe2b.out`, `fc27/probe3.out`, `fc27/probe4.out`, `fc27/probe5.out`, `fc27/probe6.out`, `fc27/probe7.out`
**Legibility-target:** user

---

## Claim 30: commit 7f3e392 ("'Open brief' and '<k>/3 open' now say 'holding a slot' …" / "An ID still open is listed with its brief (no date source exists), and the final message lists those IDs too." / "A brief that holds a slot but has no In flight line gets one; a stale In flight line points at closed/ if the brief is there, else goes." / "Done names the last commit that changed the brief's Status line; a tip date after today is recorded and counts as idle.")

**Location:** `7f3e392` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message as a description of the diff `875b41f..7f3e392 -- skills/dev-cycle/SKILL.md`: each bullet matches a hunk. It does not establish that the rules work: see Claims 16, 19 and 23. "No date source exists" holds within the checks the cycle may use. The entry header does carry `**Opened:**`, but `--check-answer` prints no date and is the only permitted reader (`skills/dev-cycle/SKILL.md:91`).

The hunks are `:84-87` (stale and orphan lines), `:162` (slot wording), `:264-265` (Done commit), `:280` (open ID with its brief), `:298-299` (future tip date), `:340` (template) and `:357-358` (final message). (paraphrased — no quote available because the claim spans seven hunks, each quoted in Claims 16–23.)

**Evidence:** `skills/dev-cycle/SKILL.md:84-87`, `skills/dev-cycle/SKILL.md:160-163`, `skills/dev-cycle/SKILL.md:263-265`, `skills/dev-cycle/SKILL.md:278-281`, `skills/dev-cycle/SKILL.md:298-299`, `skills/dev-cycle/SKILL.md:340`, `skills/dev-cycle/SKILL.md:356-358`
**Legibility-target:** user

---

## Claims Requiring Attention

### Incorrect
- **Claim 16** (`skills/dev-cycle/SKILL.md:84-86`): behavioral. A stale In flight line "corrected" to point at `briefs/closed/<name>` can never be checked again. `--check-brief` refuses closed paths ("not an open build brief"), and the Rules allow no other state source, so the item stays in In flight with a recorded skip each cycle. Fix: let `--check-brief` read closed paths and route the line to Done or Ideas by status, or say where the corrected line goes.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:47-52`): wording. The help's `unrecognized` omits "a fence in the entry is not closed".
- **Claim 4** (`scripts/dev-cycle.sh:60-62`): wording. "No default branch" now exits 1 only for the digest, `--check-brief` and `--check-branch`.
- **Claim 5** (`scripts/dev-cycle.sh:250-252`): behavioral, low. A four-character fence is closed by a three-character line, so a quoted `Status: done` inside it is read (brief c: `done`).
- **Claim 6** (`scripts/dev-cycle.sh:254-255`): behavioral, low. "The commit that set the status" is beaten by any later commit touching a `Status: `-prefixed line: a fenced example edit, a rename into place, a whole-file rewrite.
- **Claim 13** (`scripts/dev-cycle.sh:325-326`): wording. "Heading lines" includes any `#`/`##`/`###`-space line, such as a shell comment in a fence (real Q-084 has six). The outcome is fail-safe.
- **Claim 14** (`scripts/dev-cycle.sh:326-329`): behavioral, low. Fence length is not tracked. A four-backtick fence holding a balanced three-backtick block exposes a quoted answer (N1: `drop` where the answer is `keep`).
- **Claim 19** (`skills/dev-cycle/SKILL.md:263-265`): behavioral, low. Done's commit is the last commit touching any `Status: ` line, not necessarily "the brief's Status line".
- **Claim 23** (`skills/dev-cycle/SKILL.md:356-358`): wording. The final-message list does not name `unrecognized` answers, which step 2 sends there, and attaches "(with its brief)" only to open IDs.
- **Claim 29a** (`b00c057`): behavioral, low. "Never its answer" holds only when a real entry exists. With none, a forged copy in a four-backtick fence reads `done`.

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass27.md`. Its first line is `Commit: b00c057 (A) / 7f3e392 (B)`, and it carries the `**Replication:** k=1 (loop pass, decision 031)` header field. It follows the skill's header fields, the seven per-claim fields plus Legibility-target, and the attention summary. It is not committed. Against the user's goal (a clean pass, then merge), this round fixes every pass-26 wrong-reading probe: each now reads a skip, `open` or `unrecognized`. The four non-brief modes work with no default branch, and all 102 real IDs are unchanged. One new Incorrect (Claim 16, the stale-line rule's `closed/` target) is behavioral and agent-facing. It blocks a clean pass under the review-fix-loop rules unless the orchestrator grades it below the bar. The remaining nine are Mostly accurate: four are wording, and five are low-likelihood behavioral residues. Two of those (Claims 5 and 14) share one cause, untracked fence length. The probe rule held: no write outside `fc27/` except this report, and no process left running.
