Commit: 366efd7 (A) / b73069e (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at 366efd7; HEAD 133ba2e adds only pass-27 review docs, `git diff --stat 366efd7 HEAD` touches only `docs/reviews/`). B: `/workspace/.claude/wt-devcycle` (content at b73069e; merge d535260 has parents b73069e and 133ba2e, and its blobs of `scripts/dev-cycle.sh` (36b5044), `test/scripts/dev-cycle.bats` (e50dee2) and `skills/dev-cycle/SKILL.md` (32901bf) equal 366efd7's and b73069e's).
**Scope:** Partial: the pass-27 fix round only. A: `git diff b00c057..366efd7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of 56cc6fe and 366efd7. B: `git diff 7f3e392..b73069e -- skills/dev-cycle/SKILL.md` plus the message of b73069e and merge d535260. Everything else is context only (rubric section "Pass 27").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 20 verified, 7 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. One claim is an ID tally, the class of the logged "85 tests" and "mode1-equiv 33" patterns. It was recounted by execution and holds (Claim 24). The one Incorrect verdict (Claim 2a) is help wording about which answer line is read. It names no fabricated symbol, API or flag, so nothing goes in the log. The brief allows no other write anyway.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc28/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. Repos inside the temp dir got the same check after their `cd`. Probes took the code under review with `git show <commit>:<path>` or `git archive 366efd7` into the temp dir and ran it there, with `GIT_CONFIG_GLOBAL=/dev/null`. Every process ran under `timeout`. My probes wrote nothing to either worktree and nothing to `/workspace`'s own checkout. Questions files were only read with `git show` and copied into temp repos. At the end, `git status --short`: `wt-devcycle` was clean. `wt-digest` showed only another critic's untracked `api-consistency-review-2026-10-02-digest-pass28.md`, plus this report once written. `pgrep` found no dev-cycle or bats process of mine. It did list a `bats` suite running in `wt-devcycle/test/` (health-check.bats and others). That run is not mine: I ran bats only on the archive copy in `fc28/tmp.yRcoXomctb/`, and that run had already exited 0.

Scratch logs (not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc28/`, called `fc28/` below. Each probe ran with cwd `fc28/` as `timeout N bash fc28/pN.sh > fc28/logs/pN.txt`. `old` means b00c057 and `new` means 366efd7. Setlocale warnings in the logs are the environment's uninstalled `en_US.UTF-8`. The system `awk` is mawk 1.3.4 (`/etc/alternatives/awk -> /usr/bin/mawk`, and `nawk` resolves to the same), so every executed awk result below is mawk's. git is 2.39.5.

Executed runs (UTC, 2026-10-02, all exit 0):
- **E1**, 17:00:56Z, `p1.sh` → `logs/bats.txt`, `logs/lint.txt`, `logs/shellcheck.txt`, `logs/help.txt`. On `git archive 366efd7` in `fc28/tmp.yRcoXomctb/`, it ran `bats test/scripts/dev-cycle.bats`: 46 ok, 0 not ok. It ran `python3 scripts/hermeticity-lint --root .`, which said "126 test file(s) checked, no unstubbed network spawns". It ran `shellcheck scripts/dev-cycle.sh`, exit 0, and `--help`.
- **E2**, 17:01:52Z, `p2.sh` → `logs/p2.txt`. Fence probes under old and new: pass 27's api N1/N2, security Q-022/Q-023 and the four/info/indent/tilde briefs, plus my own Q-030 to Q-045.
- **E3**, 17:02:28Z, `p3.sh` → `logs/p3.txt`. Cases for the `-G` commit: a `--no-ff` merge, a fast-forward, a squash, a status edited inside the merge, a move into `closed/` in its own commit, a move merged from a branch, and `-s` against no `-s`.
- **E4**, 17:02:44Z, `p4.sh` → `logs/p4.txt`, and **E4b**, 17:05:16Z, `p4b.sh` → `logs/p4b.txt`. `--check-answer` old against new on real questions files. E4 used A at 366efd7 (98 headings) and `main` (99). E4b used B at b73069e and d535260 (102 headings each).
- **E5**, 17:03:03Z, `p5.sh` → `logs/p5.txt`. Q-001 to Q-102 on `main`'s files, old against new.
- **E6**, 17:04:04Z, `p6.sh` → `logs/p6.txt`. The stale-line flow: the glob, `--check-path`, `--check-brief` and `--check-write` on `closed/` paths, a move made only on a cycle branch, and `--check-branch main`. It ran the d535260 script.
- **E7**, 17:04:58Z, `p7.sh` → `logs/p7.txt`. The default-branch gates: a repo whose only branch is `trunk`, and a detached HEAD. Also a later commit that adds a fenced `Status: dropped` quote.
- **E8**, ~17:06Z (after E4b; not separately stamped), `python3 fc28/tz.py` and `fc28/tz2.py` → `logs/tz.txt`. The time-zone arithmetic for Claim 19.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the human reading the help, the record or the commit log.

**Pass-27 probes rerun against 366efd7 (brief item 1).** Every pass-27 case now reads the CommonMark answer (E2):

| Case | b00c057 | 366efd7 | CommonMark |
|---|---|---|---|
| api N1: ```` ```` ```` / ```` ``` ```` / `Q-001: [1]` / ```` ``` ```` / ```` ```` ```` / `Q-001: [2]` | `keep` | `drop` | drop |
| api N2: brief with the same nesting, quoted `Status: done`, then `Status: open` | `done` | `open` | open |
| sec Q-022: ```` ````markdown ```` … quoted `[2]` … real `[1]` | `drop` | `keep` | keep |
| sec Q-023: ```` ```text ```` / ```` ```bash ```` / `[2]` / ```` ``` ```` / `[1]` | `unrecognized` | `keep` | keep |
| sec briefs four / info / indent (2 spaces) | `done` ×3 | `open` ×3 | open |
| sec brief tilde (pass-26 F3) | `open` | `open` | open |
| Q-030: fence indented 2 spaces | `drop` | `keep` | keep |
| Q-031 / Q-032: fence indented 4 spaces / a tab (an indented code block, not a fence) | `drop` / `drop` | `drop` / `drop` | drop |
| Q-033: ```` ``` x ```` cannot close | `unrecognized` | `keep` | keep |
| Q-034: closing fence with trailing spaces | `keep` | `keep` | keep |
| Q-035: `#`, `##`, `###` shell comments in a ```` ```bash ```` block | `unrecognized` | `done` | done |
| Q-036: `### Q-037 · …` inside Q-036's fence | `unrecognized` | `unrecognized` | (fail-safe) |
| Q-042: ```` ~~~~ ```` closed only by ```` ~~~~ ```` | `unrecognized` | `keep` | keep |
| Q-044: blockquoted fence (`> ```` ``` ````) | `keep` | `keep` | keep |
| Q-045: answer, then a fence open at EOF | `unrecognized` | `unrecognized` | (fail-safe) |

---

## Claim 1a: help: "--check-brief for a build brief path (docs/working/briefs/[closed/] YYYY-MM-DD-<slug>.md): "ok <path> new" when the default branch has no file there (not landed, or moved to closed/), else "ok <path> open|done|dropped <commit>" from its first unfenced "Status:" line on the default branch"

**Location:** `scripts/dev-cycle.sh:29-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the accepted path forms (both `briefs/` and `briefs/closed/`), `new` for a path absent on the default branch, and the first unfenced `Status:` line under the CommonMark fence reader. Does not establish the commit field, which is Claim 1b.
**Legibility-target:** agent

```bash
# scripts/dev-cycle.sh:279-283 (check_brief :276-301, read)
  if ! isbrief "$a" && [[ ! "$a" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; then
    echo "skip $a: not a build brief (docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md)"; return
  fi
  if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi
  if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi
```
(excerpt ends :283; check_brief continues to :301, read.) E6 printed `ok docs/working/briefs/closed/2026-01-01-x.md done 07a417f` and `ok docs/working/briefs/2026-01-01-x.md new` after the move. A move made only on a cycle branch printed `ok …closed/2026-01-01-live.md new`. E2 shows the first-unfenced reading in the table above.

**Evidence:** `scripts/dev-cycle.sh:276-301`; `fc28/logs/p6.txt`; `fc28/logs/p2.txt`

---

## Claim 1b: help: "and its own commit (for merged work, the merge) that last added or removed a "Status: " line there"

**Location:** `scripts/dev-cycle.sh:33-34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--no-ff` merges, squashes, a status edited inside a merge, moves into `closed/` and later quoted `Status:` lines, all executed. Does not hold literally for a fast-forward merge, which creates no merge commit.
**Legibility-target:** user, agent

```bash
# scripts/dev-cycle.sh:298-300 (check_brief :276-301, read)
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
  echo "ok $a ${st#Status: } $c"
```
E3 results:
- `--no-ff` merge: printed the merge `b46e6c4`.
- Squash: printed the squash commit `2e214f1`.
- Status edited inside a `--no-commit` merge: printed that merge `dd7a3af`. Pass 27 had printed the creation commit here.
- Fast-forward: printed the branch's own commit `e0d5fd1`. No merge exists, so "(for merged work, the merge)" does not apply.

A precise version: "the default branch's own commit (first-parent; for a merge commit, the merge) that last added or removed a "Status: " line there".

**Evidence:** `scripts/dev-cycle.sh:294-300`; `fc28/logs/p3.txt`

---

## Claim 2a: help: "unrecognized (answered, but no answer line starts with one of the options, …)"

**Location:** `scripts/dev-cycle.sh:49-50`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which answer line decides. Does not establish anything about the fence half, which is Claim 2b.
**Legibility-target:** user, agent

Only the first answer line is read. Once it is found, `done = 1` stops the search, whatever its text:
```awk
# scripts/dev-cycle.sh:400-413 (ANSWER_AWK :365-418, read)
!done {
  line = $0; sub(/^- /, "", line)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
  ...
  result = option(rest); done = 1
}
```
E2 Q-038 has `**Answer:** maybe later` and then `**Answer:** [1]`. It reads `unrecognized Q-038`, even though an answer line does start with an option. The pass-27 wording ("the answer does not start with one of the options") was correct, and this round broadened it. A reader who adds a corrected answer line under a bad one would expect the new one to be read. It is not. The precise version: "the first answer line's text does not start with one of the options". The code comment at `:355-363` already says this.

**Evidence:** `scripts/dev-cycle.sh:47-53`, `:400-417`; `fc28/logs/p2.txt` (Q-038)

---

## Claim 2b: help: "… or a fence in the entry is left open"

**Location:** `scripts/dev-cycle.sh:50-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fence left open at EOF and one cut by a `### Q-NNN ` heading. Both read `unrecognized` even when an answer line came first. Does not establish fences outside the target entry, which are never tracked.
**Legibility-target:** user

`END { if (inside && infence) broken = 1 … print (!answered ? "open" : broken ? "unrecognized" : …) }` (`scripts/dev-cycle.sh:414-417`). `broken` beats `done`. E2 Q-045 has `[1]` and then an unclosed fence, and reads `unrecognized`. Q-036 reads `unrecognized`.

**Evidence:** `scripts/dev-cycle.sh:387-391`, `:414-417`; `fc28/logs/p2.txt`

---

## Claim 3: help/Exit: "--check-brief and --check-branch need a default branch found by name (origin/HEAD, main or master)" / "1 bad usage, not a git repo, no perl, or no default branch (for the digest, --check-brief and --check-branch)"

**Location:** `scripts/dev-cycle.sh:54-55`, `:61-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status in a repo whose only branch is `trunk` and in a detached HEAD with no main. Does not establish the bad-usage, no-perl or not-a-repo exits, which this round did not change.
**Legibility-target:** user

```bash
# scripts/dev-cycle.sh:456-462
[[ -n "$MAIN_SHA" || -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
...
if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) && -z "$MAIN_BY_NAME" ]]; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```
E7 results:
- On `trunk`: the digest rc=0 (it uses the current branch), `--check-brief` rc=1, `--check-branch` rc=1, `--check-path` rc=0.
- Detached with no main: the digest rc=1, `--check-answer` rc=0.

For the digest, "no default branch" includes the current-branch fallback. `:54-55` and the error text say so.

**Evidence:** `scripts/dev-cycle.sh:436-462`; `fc28/logs/p7.txt`

---

## Claim 4: `-h|--help) sed -n '2,64p' "$0"` prints the whole header

**Location:** `scripts/dev-cycle.sh:127`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the range ends at the header's last comment line (:63) plus the blank :64. Does not establish anything about future header edits.
**Legibility-target:** maintainer

Line 63 is `# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`, line 64 is blank and line 65 is `set -euo pipefail`. `logs/help.txt` ends with that Exit text and one empty line.

**Evidence:** `scripts/dev-cycle.sh:61-65`, `:127`; `fc28/logs/help.txt`

---

## Claim 5: "Code fences, as CommonMark has them: a line of 3 or more ` or ~ (after up to 3 spaces; a ` fence's info string holds no `) opens one, and only a line of the same character, at least as long and with nothing after it, closes it."

**Location:** `scripts/dev-cycle.sh:251-253`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers opening (3+ characters, up to 3 leading spaces, no backtick in a backtick fence's info string) and closing (same character, at least as long). "With nothing after it" is imprecise: trailing spaces and tabs are allowed, as in CommonMark. Does not establish blockquoted or list-nested fences, which are not modelled. Those fail the right way in E2 (Q-044).
**Legibility-target:** maintainer

```awk
# scripts/dev-cycle.sh:256-268 (FENCE_AWK :255-269, read)
function lead(l,   i) { i = 1; while (i <= 3 && substr(l, i, 1) == " ") i++; return substr(l, i) }
function run(l, ch,   n) { n = 0; while (substr(l, n + 1, 1) == ch) n++; return n }
function opens(l,   s, ch, n) {
  ...
  if (ch == "`" && index(substr(s, n + 1), "`")) return 0
  fch = ch; flen = n; return 1
}
function closes(l,   s, n) {
  s = lead(l); n = run(s, fch)
  return n >= flen && substr(s, n + 1) ~ /^[ \t]*$/
}
```
E2: Q-034 (closing ```` ``` ```` followed by spaces) closes. Q-033 (```` ``` x ````) does not. Q-043 (```` ``` a`b ````) does not open. Q-031 and Q-032 (4 spaces, a tab) do not open. A precise version: "with only spaces or tabs after it".

**Evidence:** `scripts/dev-cycle.sh:251-269`; `fc28/logs/p2.txt`

---

## Claim 6: commit 56cc6fe: "One fence reader (FENCE_AWK) for answers and briefs"

**Location:** `scripts/dev-cycle.sh:287`, `:425`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both call sites prepending `FENCE_AWK` and the concatenated programs running under mawk 1.3.4, the system awk. No names collide: FENCE_AWK's globals are `fch`/`flen` and its functions `lead`/`run`/`opens`/`closes`, while ANSWER_AWK uses `option`/`heading` and its own `infence`, `c`, `v`, `p`, `q`. Does not establish gawk or busybox awk, which are not installed.
**Legibility-target:** maintainer

`st="$(git cat-file blob "$MAIN_SHA:$a" | env LC_ALL=C awk "$FENCE_AWK"'` (`:287`), and `r="$(env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f")"` (`:425`). FENCE_AWK ends, and ANSWER_AWK starts, with a newline, so the concatenation parses. E1 ran 46/46 and E2 gave all the readings above under mawk.

**Evidence:** `scripts/dev-cycle.sh:255-269`, `:287-292`, `:365-418`, `:425`; `fc28/logs/bats.txt`, `fc28/logs/p2.txt`

---

## Claim 7: "A closed/ path is read the same way (its state, for In flight; it never holds a slot)." / commit: "the lookup runs only when a status was found"

**Location:** `scripts/dev-cycle.sh:274-275`, `:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a `closed/` path goes through the same blob read, and that the `-G` lookup is skipped on a skip. "Never holds a slot" is the skill's rule (Claim 15), not something the script enforces.
**Legibility-target:** maintainer

`if [[ -z "$st" ]]; then echo "skip $a: its first Status: line is not exactly Status: open, done or dropped"; return; fi` (`:293`) comes before the `git log` at `:298`. E6: `ok …/closed/2026-01-01-o.md open 07a417f` and `ok …/closed/2026-01-01-x.md done 07a417f`.

**Evidence:** `scripts/dev-cycle.sh:270-301`; `fc28/logs/p6.txt`

---

## Claim 8: "The default branch's own commit (first-parent history, a merge diffed against its first parent) that last added or removed a line starting "Status: " in this file: for merged work, the merge that brought the change in; never a later Asked:/Kept: edit. Any such line counts, a quoted one too."

**Location:** `scripts/dev-cycle.sh:294-297`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-parent attribution for merges, squashes and in-merge edits, the `-s` flag, quoted lines and renames into the path. Mostly accurate only because a fast-forward has no merge (as in Claim 1b). Does not establish anything about a history rewritten by force-push.
**Legibility-target:** maintainer

E3 results:
- Without `-s`, `--diff-merges=first-parent` prints the patch after the hash. With it, only the hash is printed. Both picked the same commit (`with-s=b46e6c4 without-s=b46e6c4` followed by a diff). The `-s` is required for `c` to hold a bare hash.
- A rename into `closed/` counts as adding the line there: a move commit `a45c140` is printed rather than the status-setting `7e6a133`. When the move comes in a merge, the merge `12840a4` is printed.
- E7: a later fenced `Status: dropped` quote names the quote commit `61edfe1…`, as "a quoted one too" says.
- "Never a later Asked:/Kept: edit" is the bats test "names the merge…" (`:843-855`), which passes: `printf 'Asked: Q-1\n' >> "$b"` on main does not move the result off the merge.

**Evidence:** `scripts/dev-cycle.sh:294-300`; `test/scripts/dev-cycle.bats:843-855`; `fc28/logs/p3.txt`, `fc28/logs/p7.txt`

---

## Claim 9: "The default branch is refused (the check modes that read it need it found by name)." / help "… or the default branch"

**Location:** `scripts/dev-cycle.sh:309`, `:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unconditional refusal at `:315`, which the gate at `:460` makes equivalent to "found by name". Does not establish refusal of other long-lived branches (only `$MAIN`).
**Legibility-target:** maintainer

`elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"` (`:315`). E6: `skip main: the default branch` and `ok chore/c 55b16e7 1 2026-10-02`.

**Evidence:** `scripts/dev-cycle.sh:310-322`, `:460-462`; `fc28/logs/p6.txt`

---

## Claim 10: "An entry is answered only when its header line (the first line starting "**Needs:**", as questions.sh writes it) ends with " **Status:** ANSWERED""

**Location:** `scripts/dev-cycle.sh:346-348`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's condition only. The sentence at `:349-350` in the same comment states the current rule (Claim 11).
**Legibility-target:** maintainer

The line-end anchor was removed in 56cc6fe. The gate now reads the first `**Status:** ` field:
```awk
# scripts/dev-cycle.sh:395-399 (ANSWER_AWK :365-418, read)
!header && /^\*\*Needs:\*\*/ {
  header = 1; v = $0; p = index(v, "**Status:** "); answered = 0
  if (p) { v = substr(v, p + 12); q = index(v, " "); if (q) v = substr(v, 1, q - 1); answered = (v == "ANSWERED") }
  next
}
```
E2 refutes "only when … ends with" in both directions:
- Q-040's `**Status:** OPEN · **Status:** ANSWERED` ends with it but reads `open`.
- Q-039's `**Status:** ANSWERED (by user)` does not end with it but reads `drop`.
- Q-041 (`ANSWERED` plus a trailing space) reads `drop`.

The comment now gives two rules, one after the other. The code does what `:349-350` says. This is wording only.

**Evidence:** `scripts/dev-cycle.sh:346-350`, `:395-399`; `fc28/logs/p2.txt`

---

## Claim 11: "Its status is the first "**Status:** " field of that line, up to the next space."

**Location:** `scripts/dev-cycle.sh:349-350`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle's own read (first field, cut at the first space). It agrees with `questions.sh` on every header `questions.sh` writes. It does not establish agreement on hand-edited headers, where the two readers differ, as listed below.
**Legibility-target:** maintainer

Quoted at Claim 10 (`:395-399`). The bats Q-4 case (`**Status:** OPEN · was set by **Status:** ANSWERED`) reads `open` and E2 Q-039/40/41 match the rule.

`questions.sh` splits on ` · ` and keeps the last field starting `Status:`: `if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }` (`scripts/questions.sh:179`). They differ in two cases:
- `ANSWERED (by user)`: dev-cycle reads ANSWERED, while `questions.sh check` sees a non-OPEN/ANSWERED status (`:269`).
- Two Status fields: dev-cycle uses the first, `questions.sh` the last.

Only the header's writer can produce either case. The real questions files contain neither (Claim 24: all readings are unchanged).

**Evidence:** `scripts/dev-cycle.sh:395-399`; `scripts/questions.sh:16`, `:171-181`, `:269`; `fc28/logs/p2.txt`

---

## Claim 12: "Entries are bounded by heading lines; inside the target entry, fenced lines are skipped (FENCE_AWK), and inside a fence only a "### Q-NNN " heading ends it (then, or when the entry ends with a fence still open, the answer is unrecognized: lost, never read from another entry)."

**Location:** `scripts/dev-cycle.sh:350-353`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers shell-comment headings inside a fence, a `### Q-NNN ` line inside a fence, and a fence open at EOF. The heading pattern matches the one `questions.sh` uses (`/^### Q-[0-9]+ /`, `scripts/questions.sh:161`). Does not establish fences in other entries, which are not tracked: a fenced copy of the target's own heading elsewhere still counts toward the duplicate skip.
**Legibility-target:** maintainer

```awk
# scripts/dev-cycle.sh:386-394 (ANSWER_AWK :365-418, read)
heading($0) { count++; inside = (count == 1); infence = 0; header = 0; next }
inside && infence {
  if ($0 ~ /^### Q-[0123456789]+ /) { broken = 1; inside = 0; next }
  if (closes($0)) infence = 0
  next
}
/^(#|##|###) / { inside = 0 }
!inside { next }
opens($0) { infence = 1; next }
```
E2 results: Q-035 (`#`/`##`/`###` comments in a fence) reads `done`. Q-036 reads `unrecognized`. Q-045 reads `unrecognized`.

**Evidence:** `scripts/dev-cycle.sh:386-417`; `scripts/questions.sh:161`; `fc28/logs/p2.txt`

---

## Claim 13: "Briefs in the directory are found only through `--check-path 'docs/working/briefs/*.md'` (a done or dropped brief moves to `docs/working/briefs/closed/`, so the glob lists only briefs not yet moved)."

**Location:** `skills/dev-cycle/SKILL.md:76-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that git's `:(glob)` `*` does not cross `/`, so `closed/` is never listed. Does not establish that every done or dropped brief has actually been moved.
**Legibility-target:** agent

The script runs `if [[ "$a" == *[*?]* ]]; then spec=":(glob)$a"` (`scripts/dev-cycle.sh:218`). E6: with two briefs in `closed/` and one in `briefs/`, the glob printed only `ok docs/working/briefs/2026-01-01-live.md`.

**Evidence:** `scripts/dev-cycle.sh:215-230`; `fc28/logs/p6.txt`

---

## Claim 14: "A brief's state comes only from `--check-brief '<path>'` (for a path in `briefs/` or `briefs/closed/`) … `ok <path> open|done|dropped <commit>` (the commit is the default branch's own commit that last changed a `Status:` line there; for merged work, the merge)"

**Location:** `skills/dev-cycle/SKILL.md:78-83`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both path forms and the commit as computed ("last changed a `Status:` line there" is exact, including moves and quoted lines). The "for merged work, the merge" part misses fast-forwards, as in Claim 1b. Does not establish the In flight consequences, which are Claims 16a and 16b.
**Legibility-target:** agent

The evidence is the same as Claims 1a and 1b (E3, E6). The SKILL wording mirrors the help text.

**Evidence:** `scripts/dev-cycle.sh:276-301`; `fc28/logs/p3.txt`, `fc28/logs/p6.txt`

---

## Claim 15: "**A brief holds a slot** when the glob prints `ok` for it (its skip lines are only recorded) or this cycle wrote it, unless it is under `closed/` or `--check-brief` prints `done` or `dropped` for it"

**Location:** `skills/dev-cycle/SKILL.md:83-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's question: the `closed/` exemption never conflicts with the glob, which cannot list `closed/` (Claim 13). It only matters for "this cycle wrote it", and the cycle writes new briefs only under `briefs/` (`SKILL.md:321`). Does not establish how an agent counts the slots.
**Legibility-target:** agent

E6's glob output (Claim 13) and the Build-briefs path `docs/working/briefs/YYYY-MM-DD-<slug>.md` (`SKILL.md:321`) show the exemption is consistent and redundant for the glob. The code comment at `scripts/dev-cycle.sh:274-275` gives the same rule.

**Evidence:** `skills/dev-cycle/SKILL.md:83-86`, `:318-325`; `fc28/logs/p6.txt`

---

## Claim 16a: stale In flight line "pointed at `docs/working/briefs/closed/<same name>` if `--check-path` prints `ok` there … otherwise removed" / check 1: "`git mv` the brief there (… a brief already under `closed/` stays) and point the roadmap line there"

**Location:** `skills/dev-cycle/SKILL.md:86-90`, `:276-278`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's question 2. No step moves a `closed/` brief twice: check 1 leaves one already there. No step leaves a line pointing at a removed path: a line is pointed only at a path `--check-path` prints `ok` for, and otherwise removed. Does not establish the resolution of `open`/`new` `closed/` briefs, which is Claim 16b.
**Legibility-target:** agent

E6 results:
- `--check-path` printed `skip docs/working/briefs/2026-01-01-x.md: no tracked file …` and `ok docs/working/briefs/closed/2026-01-01-x.md`.
- `--check-brief` on the `closed/` path printed `done 07a417f`.
- `--check-write` on it printed `ok`.

So the chain is stale line → re-pointed line → check 1 → Done, with no move.

**Evidence:** `skills/dev-cycle/SKILL.md:86-90`, `:269-280`; `fc28/logs/p6.txt`

---

## Claim 16b: "(In flight's check 1 then moves it to Done or Ideas by the state `--check-brief` prints)"

**Location:** `skills/dev-cycle/SKILL.md:89-90`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the `done` and `dropped` states, the normal case since check 1 moves only done or dropped briefs. Two other states are possible, and check 1 resolves neither. Does not establish how often they occur (only hand moves or an unlanded cycle branch produce them).
**Legibility-target:** agent

E6 shows both states:
- **`open`**: a brief moved by hand while open. `ok …/closed/2026-01-01-o.md open 07a417f`. Check 1 acts only on `done`/`dropped`. Checks 2 and 3 then run keep-or-drop on a `closed/` brief, which holds no slot (Claim 15) but stays in In flight under `:266-267`'s "line being resolved".
- **`new`**: the move is on the working branch but not yet on the default branch. `ok …/closed/2026-01-01-live.md new`. No In flight step names `new`, so the line waits, unresolved, until the move lands.

Both end safely (nothing is moved or lost), but "check 1 then moves it" is not true for them. A precise version: "(check 1 then moves it to Done or Ideas once `--check-brief` prints done or dropped there)". This is a low-impact agent-procedure gap.

**Evidence:** `skills/dev-cycle/SKILL.md:266-307`; `fc28/logs/p6.txt`

---

## Claim 17: "**In flight**: items whose brief holds a slot (as in the Rules), plus any line being resolved after its brief moved to `closed/`, each naming its brief path."

**Location:** `skills/dev-cycle/SKILL.md:266-267`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the Rules' slot definition (`:83-86`) and the stale-line rule (`:86-90`). Does not establish the resolution of every such line (Claim 16b).
**Legibility-target:** agent

The definition defers to "as in the Rules" and adds exactly the lines that `:86-90` re-points to `closed/`, which hold no slot under `:85`'s "unless it is under `closed/`" (quoted at Claim 15).

**Evidence:** `skills/dev-cycle/SKILL.md:83-92`, `:266-267`

---

## Claim 18: "→ Done, naming the commit it prints (for merged work, the merge that brought the status in)"

**Location:** `skills/dev-cycle/SKILL.md:269-271`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the normal case: a status set on a branch and merged `--no-ff`, where the printed commit is that merge (E3). The parenthetical describes a different commit in three cases (listed below). Does not affect the instruction itself ("naming the commit it prints"), which is exact.
**Legibility-target:** agent, user

The commit is not "the merge that brought the status in" when:
- **A stale line resolves through `closed/`.** E6 printed the move `07a417f`, not `f59d719`, the commit that set `done`.
- **A later commit adds a quoted `Status:` line.** E7 printed the quote commit.
- **The merge was a fast-forward.** E3 printed the branch commit.

The Rules' wording at `:81-82`, "the default branch's own commit that last changed a `Status:` line there", is the precise version. Pass 27 F4 asked for the computed wording, and the Rules now carry it, but this line does not. Provenance only: the state still comes from the blob.

**Evidence:** `skills/dev-cycle/SKILL.md:81-82`, `:269-271`, `:312-313`; `fc28/logs/p3.txt`, `fc28/logs/p6.txt`, `fc28/logs/p7.txt`

---

## Claim 19: "A tip date more than a day after today is recorded and counts as idle (the committer sets the date; a day covers time zones ahead of the cycle's)."

**Location:** `skills/dev-cycle/SKILL.md:305-307`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic for a commit made at or before the cycle's instant, with dates in the committer's zone (`%cs`, `scripts/dev-cycle.sh:319`) against the cycle's local today. "A day covers time zones" holds whenever the two UTC offsets differ by at most 24 h, which includes every pair with a cycle zone from UTC−10 to UTC+14 (and the user's US zones). It fails for spreads over 24 h. Does not establish a committer clock that is simply wrong.
**Legibility-target:** agent

E8 (`python3 fc28/tz.py`, `tz2.py`): with offsets from −12:00 to +14:00, the committer's date can be up to **2** days after the cycle's. One example: at 11:00Z on 2026-10-02 a UTC−12 cycle reads 2026-10-01 and a UTC+14 committer reads 2026-10-03. The smallest offset spread that gives 2 days is 25 h. A cycle at UTC−7 has a maximum spread of 21 h, so it sees at most 1 day. A precise version: "a day covers any two zones less than 24 hours apart". If it fails, a fresh commit counts as idle and a keep-or-drop question is filed. That is low impact.

**Evidence:** `skills/dev-cycle/SKILL.md:303-307`; `scripts/dev-cycle.sh:319`; `fc28/logs/tz.txt`

---

## Claim 20: final message lists "any keep-or-drop answer step 6 could not read, read as `unrecognized`, or found still `open` (each with its brief)"

**Location:** `skills/dev-cycle/SKILL.md:364-366`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with In flight check 2. Pass-27 Claim 23 had found `unrecognized` missing from this list. Does not establish that an agent compiles the list.
**Legibility-target:** agent, user

Check 2 sends `open` ("list it in the final message with its brief", `:287`), `unrecognized` ("goes in the record and the final message", `:290`) and `skip` ("goes in the record and the final message", `:294`) here. All three are now named, and "(each with its brief)" covers all of them.

**Evidence:** `skills/dev-cycle/SKILL.md:281-295`, `:364-369`

---

## Claim 21: test comment "A closed/ path is read for its state (not landed there yet: new); it never holds a slot."

**Location:** `test/scripts/dev-cycle.bats:680`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted `new` output. "Never holds a slot" is the skill's rule (Claim 15) and is not asserted by the test.
**Legibility-target:** maintainer

`[[ "$output" == "ok docs/working/briefs/closed/2026-03-01-open-a.md new" ]]` (`:682`). The path is only in the working tree, never committed under `closed/`. The test passes (E1).

**Evidence:** `test/scripts/dev-cycle.bats:671-683`; `fc28/logs/bats.txt`

---

## Claim 22: test comment "Inside a fence only a "### Q-NNN " heading ends the entry, so a shell comment in a pasted block does not cut it short."

**Location:** `test/scripts/dev-cycle.bats:759-760`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `# a comment, not a heading` line in Q-2's fence and the assertion `drop Q-2`. Does not establish anything beyond Claim 12.
**Legibility-target:** maintainer

`printf '%s\n# a comment, not a heading\n%s\n**Answer:** [2]\n\n' "$f" "$f"` (`:754`), asserted `*"drop Q-2"*` (`:761`). The test passes (E1). E2 Q-035 extends it to `##`/`###` lines.

**Evidence:** `test/scripts/dev-cycle.bats:746-764`; `fc28/logs/bats.txt`, `fc28/logs/p2.txt`

---

## Claim 23: test names "fences follow CommonMark: longer fences, info strings, indented fences; the status field is read whole" / "--check-brief names the merge that brought a status change in, and reads closed/ briefs"

**Location:** `test/scripts/dev-cycle.bats:823`, `:843`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test exercises what its name says and passes. The first test covers N1-style nesting (Q-1), an info string (Q-2), a 2-space indent (Q-3), a status field with a later ANSWERED mention (Q-4) and a nested brief. The second covers a `--no-ff` merge after a later `Asked:` edit, and a `git mv` into `closed/`. Does not establish fast-forward or quoted-line behaviour, which E3 and E7 cover.
**Legibility-target:** maintainer

`for want in "drop Q-1" "keep Q-2" "keep Q-3" "open Q-4"` (`:836`). `[[ "$output" == "ok $b done $m" ]]`, where `m` is the merge (`:851`). Both report `ok` in `logs/bats.txt` (tests 45, 46).

**Evidence:** `test/scripts/dev-cycle.bats:823-856`; `fc28/logs/bats.txt`

---

## Claim 24: commit 56cc6fe: "A four-backtick fence around a three-backtick block, an info-string line and an indented fence no longer expose a quoted answer or status." / "--check-branch refuses the default branch unconditionally" / "Tests: … 46/46; shellcheck and the hermeticity lint clean; all 102 real IDs read as before."

**Location:** commit `56cc6fe`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fence cases (E2 table), the refusal (Claim 9), 46/46, shellcheck on `scripts/dev-cycle.sh`, the lint, and the ID tally. The 102 IDs are the B branch's questions files (102 headings at b73069e and d535260). Does not establish shellcheck on the bats file (not run this pass).
**Legibility-target:** user

Tallies:
- E1: 46 `ok`, 0 `not ok`. Lint exit 0. Shellcheck exit 0.
- E4b: old and new give identical output on 102 IDs at both b73069e and d535260 (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized).
- E4/E5: also identical on A's 98 IDs and on `main`'s 99. On `main`, Q-001…Q-102 has 3 IDs with no entry, which skip identically.

The tally matches the logged "N tests" pattern class. It was recounted and holds.

**Evidence:** `fc28/logs/bats.txt`, `fc28/logs/lint.txt`, `fc28/logs/shellcheck.txt`, `fc28/logs/p4.txt`, `fc28/logs/p4b.txt`, `fc28/logs/p5.txt`, `fc28/logs/p2.txt`

---

## Claim 25: commit 366efd7: "Exit line names which modes need a default branch"

**Location:** commit `366efd7` (`scripts/dev-cycle.sh:61-63`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-hunk change and its accuracy (Claim 3). Does not establish anything beyond Claim 3.
**Legibility-target:** user

`git show --stat 366efd7`: `scripts/dev-cycle.sh | 4 ++--`, the Exit lines only. E7 confirms the modes (Claim 3).

**Evidence:** `scripts/dev-cycle.sh:61-63`; `fc28/logs/p7.txt`

---

## Claim 26: commit b73069e ("A stale In flight line pointed at briefs/closed/ now resolves … (no second move)" / "In flight is defined by the slot rule; the glob's skip lines are only recorded; closed/ briefs never hold a slot; the orphan check compares the glob's ok paths with the In flight paths as text" / "Done's commit is the default branch's own commit (the merge, for merged work); a tip date only counts as future-idle when it is more than a day ahead (time zones); the final message lists unrecognized answers too") and merge d535260

**Location:** commit `b73069e`; merge `d535260`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every bullet is present in `git diff 7f3e392..b73069e -- skills/dev-cycle/SKILL.md`, and that d535260 carries both branches' files unchanged. The accuracy of the content those bullets describe is verdicted in Claims 14 to 20, where "resolves" (16b), "the merge" (18) and "a day" (19) carry their own Mostly accurate verdicts.
**Legibility-target:** user

Each bullet maps to a hunk: `:79-92` (closed/ paths, slot, glob skips, the text comparison), `:266-278` (In flight, "a brief already under `closed/` stays"), `:305-307` (a day) and `:364-366` (unrecognized). `git rev-parse d535260:<path>` equals `366efd7:` for the script and bats file, and `b73069e:` for SKILL.md.

**Evidence:** `skills/dev-cycle/SKILL.md:76-92`, `:266-307`, `:364-366`; `git log -1 --format='%P' d535260`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2a** (`scripts/dev-cycle.sh:49-50`): wording, user/agent-facing. "No answer line starts with one of the options" is wrong. Only the first answer line is read (Q-038: a later `[1]` still gives `unrecognized`). Restore "the first answer line's text does not start with one of the options".

### Stale
- **Claim 10** (`scripts/dev-cycle.sh:346-348`): wording, maintainer-facing. "Ends with ' **Status:** ANSWERED'" describes the removed line-end anchor, and the next sentence gives the current first-field rule. Q-040 ends with it and reads `open`, while Q-039 does not and reads `drop`.

### Mostly Accurate
- **Claim 1b** (`scripts/dev-cycle.sh:33-34`): wording. "(For merged work, the merge)": a fast-forward has no merge, and the branch's own commit is printed.
- **Claim 5** (`scripts/dev-cycle.sh:251-253`): wording. "With nothing after it": trailing spaces and tabs are allowed (CommonMark's rule).
- **Claim 8** (`scripts/dev-cycle.sh:294-297`): wording. Same fast-forward qualifier as 1b. Everything else holds by execution, including `-s`, renames into `closed/`, quoted lines and in-merge edits.
- **Claim 14** (`skills/dev-cycle/SKILL.md:78-83`): wording. Same fast-forward qualifier, in the Rules.
- **Claim 16b** (`skills/dev-cycle/SKILL.md:89-90`): behavioral, low, agent. A re-pointed `closed/` line whose state is `open` (moved by hand) or `new` (move not on the default branch) is not resolved by check 1. It stays in In flight safely, but "check 1 then moves it" over-promises.
- **Claim 18** (`skills/dev-cycle/SKILL.md:269-271`): wording, agent/user. "The merge that brought the status in" is not what is printed for a `closed/` resolution (the move), a later quoted `Status:` line, or a fast-forward. Use the Rules' wording from `:81-82`.
- **Claim 19** (`skills/dev-cycle/SKILL.md:305-307`): behavioral, low, agent. A one-day tolerance covers offset spreads of up to 24 h. UTC−12 against UTC+14 gives 2 days (E8), but a cycle at UTC−10 or east is always covered.

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass28.md`. Its first line is `Commit: 366efd7 (A) / b73069e (B)` and it carries `**Replication:** k=1 (loop pass, decision 031)`. It follows the skill's header fields, the seven per-claim fields plus Legibility-target, and the attention summary. It is not committed.

Against the user's goal (a clean pass, then merge), the pass-27 fix round holds:
- Every pass-27 fence probe now reads the CommonMark answer.
- The `-G` lookup names the merge for `--no-ff` and in-merge edits.
- `closed/` briefs resolve without a second move, and no line is left pointing at a removed path.
- 46/46, shellcheck and the lint are clean, and all 102 real IDs read as before.

Two findings remain. One Incorrect (Claim 2a) and one Stale (Claim 10) are wording-only comment/help regressions introduced or left by this round. Neither changes behavior, but the Incorrect one blocks a clean pass under the review-fix-loop rules unless the orchestrator grades it below the bar. Of the seven Mostly accurate, five are wording (four of them the same fast-forward / "the merge" qualifier) and two are low-impact behavioral residues (16b, 19). The probe rule held: no write outside `fc28/` except this report, and no process of mine left running.
