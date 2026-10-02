Commit: c1d0a80 (A) / fb643e2 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at c1d0a80; HEAD 0b4c97b adds review docs only). B: `/workspace/.claude/wt-devcycle` (content at fb643e2; HEAD 0caaba2 merges A in). `0caaba2:scripts/dev-cycle.sh` and `c1d0a80:scripts/dev-cycle.sh` are the same blob (2a1a6ba), checked with `git hash-object`.
**Scope:** Partial: the pass-23 fix round only. A: `git diff ba39470..c1d0a80 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of c1d0a80. B: `git diff 36ca12c..fb643e2 -- skills/dev-cycle/SKILL.md` plus the message of fb643e2. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 28
**Summary:** 20 verified, 6 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. No claim below matches a logged pattern. Neither Incorrect verdict is a fabricated symbol, API or flag: one is a real mechanism whose conclusion is stated too broadly, and one is a command that fails on its first use. So nothing is appended to the log, and the brief allows no other write anyway.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc24/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. Every process ran under `timeout`, and none is still running. The probes took the code under review with `git -C /workspace/.claude/wt-digest archive <commit> | tar -x` into the temp dir and ran it from there. Apart from this report, nothing was written to `/workspace` or to either worktree.

Execution logs are scratch and are not committed. They are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc24/` (below, `fc24/`). The environment's default `LC_ALL=en_US.UTF-8` is not installed, so the probes set `LC_ALL=C.utf8`. Only mawk 1.3.4 is installed (no gawk or busybox), so the awk program ran under mawk only. Its gawk portability is checked statically: it uses no intervals, and octal string escapes and byte `substr` under `LC_ALL=C` are POSIX.

Executed runs (UTC; both scripts exit 0):
- E1–E4, 16:09:46Z–16:09:59Z, `timeout 900 bash fc24/probe1.sh` (cwd `fc24/`) → `fc24/probe1.log`. Inside its temp copy of `c1d0a80:scripts` and `test`, it ran:
  - E1 `bats test/scripts/dev-cycle.bats`: `1..36`, 36 ok, 0 not ok → `fc24/bats.log`.
  - E2 `shellcheck scripts/dev-cycle.sh`: exit 0, empty output → `fc24/shellcheck.log`.
  - E3 `--help`: exit 0, 52 lines → `fc24/help.log`.
  - E4 `--check-answer` with all 102 `### Q-NNN` IDs from copies of wt-devcycle's `docs/working/questions.md` and `questions-archive.md`, under c1d0a80 and under ba39470 → `fc24/answers-new.log`, `fc24/answers-old.log`. `fc24/entries.py` lists each entry's answer-looking lines, joined with its reading → `fc24/joined.log`. The questions files are a time-varying input. The results hold for wt-devcycle's working tree as of 16:09Z (last changed in 8286c2b).
- P1–P6, 16:13:18Z, `timeout 300 bash fc24/probe2.sh` (cwd `fc24/`) → `fc24/probe2.log`. It covers:
  - P1: 14 answer shapes (notes after a space, attached dash, `?`, a tab heading, a colon in the label, a prose label before the answer, indented and mixed fences);
  - P2: a repo whose only branch is `trunk`, with HEAD detached;
  - P3: a repo whose only branch is `dev`;
  - P4: `git mv` into a `briefs/closed/` that does not exist yet;
  - P5: `git rev-list --count <default>..<commit>` for fresh, merged, squash-merged and working branches;
  - P6: a branch ref that points at a blob.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or tests.
- **user**: the human reading the digest, the record or the commit log.

---

## Claim 1: help: "--check-write  the same for one of the cycle's own bookkeeping files (roadmap, questions files, idea log, cycle records, open briefs and briefs/closed/); the file need not exist yet. --check-brief  the same, for an open build brief only"

**Location:** `scripts/dev-cycle.sh:26-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers which paths `--check-write` and `--check-brief` accept, including a `closed/` destination whose directory does not exist yet. It does not establish that the file can then be created there by `git mv` (Claim 19).

```bash
# scripts/dev-cycle.sh:228-232
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ \
    || "$1" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]] || isbrief "$1"
}
```

`check_write()` (`:233-240`, read) refuses a non-brief under `--check-brief` before `writable` runs. The test at `test/scripts/dev-cycle.bats:670-681` shows `--check-write` gives `ok` for a `closed/` path and `--check-brief` gives "not an open build brief". In P4, `--check-write docs/working/briefs/closed/2026-01-01-a.md` printed `ok` with no `closed/` directory present.

**Evidence:** `scripts/dev-cycle.sh:225-240`; `test/scripts/dev-cycle.bats:670-681`; `fc24/bats.log`; `fc24/probe2.log` (P4)

---

## Claim 2: help: "--check-branch  "ok <name> <commit>" for a brief's branch that exists, "absent <name>" for one that does not, "skip <name>: <reason>" for a name outside letters, digits, . _ - /, starting with -, not a valid branch name (HEAD, refs/...) or the default branch. The commit is refs/heads/<name>'s own, never a same-named tag's: give git that."

**Location:** `scripts/dev-cycle.sh:32-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the three output forms, the refusal list and tag shadowing. It does not establish two edges. In a repo with no origin/HEAD, main or master, "the default branch" is the current branch (P3: `skip dev: the default branch`). A branch ref that points at a non-commit object prints `absent` although the ref exists (P6).

```bash
# scripts/dev-cycle.sh:250-254
  elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"
  else
    sha="$(git show-ref --verify --hash "refs/heads/$a" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then echo "ok $a $sha"; else echo "absent $a"; fi
```

(excerpt ends :254; enclosing `check_branch()` ends :256 — read)

The tests at `:538-551` and `:574-584` pass (E1). They cover `ok feat/x-1 <sha>`, `absent chore/…`, `skip main: the default branch`, `HEAD`, `refs/heads/x` and a same-named tag. In P6, `refs/heads/odd` pointing at a blob printed `absent odd`. Both edges need a hand-built repo or ref, so the help is right for every case a cycle meets.

**Evidence:** `scripts/dev-cycle.sh:241-256`, `:344-364`; `test/scripts/dev-cycle.bats:538-551`, `:574-584`; `fc24/bats.log`; `fc24/probe2.log` (P3, P6)

---

## Claim 3: help: "--check-fix  "ok <path>" for a file an in-cycle fix may edit: a tracked .md file under docs/ (not docs/working/, docs/human-author/ or docs/reviews/) or README.md" (and commit c1d0a80: "Help text describes every mode's lines; comments match.")

**Location:** `scripts/dev-cycle.sh:37-39`; commit c1d0a80
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the help's statement of the `--check-fix` scope. It does not establish whether any reader acts on the omission. The roadmap is written through `--check-write` anyway.

The code also refuses every `--check-write` file, and outside `docs/working/` that means `docs/roadmap.md`:

```bash
# scripts/dev-cycle.sh:264-265
  elif [[ ! "$a" =~ ^docs/.*\.md$|^README\.md$ || "$a" =~ ^docs/(working|human-author|reviews)/ ]] || writable "$a"; then
    echo "skip $a: in-cycle fixes edit only tracked .md files under docs/ (not working/, human-author/ or reviews/) and README.md; file it instead"
```

(excerpt ends :265; enclosing `check_fix()` ends :267 — read)

The test at `:656-668` expects `docs/roadmap.md` among its 6 skips, and it passes (E1). The help and the skip reason both leave out the roadmap, so a reader of either would expect `ok` for it. The commit message says "(and not a bookkeeping file)", which is right. Precise version: "… (not docs/working/, docs/human-author/, docs/reviews/ or docs/roadmap.md)". Wording.

**Evidence:** `scripts/dev-cycle.sh:37-39`, `:257-267`, `:228-232`; `test/scripts/dev-cycle.bats:656-668`; `fc24/bats.log`

---

## Claim 4: help: "--check-answer  "<option> Q-NNN" … keep, drop, open (not answered yet) or unrecognized (answered, but not as keep or drop); "skip Q-NNN: <reason>" when it cannot be read (no such entry, a duplicate heading, a questions file that is not plain)."

**Location:** `scripts/dev-cycle.sh:40-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the output vocabulary and the three skip causes. It does not establish that every reading is right (Claims 10–12b). "unrecognized" also covers an ANSWERED entry with no answer line.

```awk
# scripts/dev-cycle.sh:324-327
END {
  if (count > 1) print "dup"
  else if (count) print (done ? result : answered ? "unrecognized" : "open")
}'
```

`check_answer()` (`:328-341`, read) turns `dup`, a second hit in the other file, and a non-plain file into the three skip reasons. The test at `:625-654` checks all three (E1).

**Evidence:** `scripts/dev-cycle.sh:282-341`; `test/scripts/dev-cycle.bats:625-654`; `fc24/bats.log`

---

## Claim 5: "Exit: 0 digest printed (or, for the check modes, every argument answered: a skip is an answer, not an error); 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:50-52`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the exit codes of the check modes now that they run after the default-branch lookup. It does not establish whether exit 1 for every check mode in such a repo is the intended behavior. The brief asks; the header documents it, and a dev cycle always runs on a default branch (step 0).

```bash
# scripts/dev-cycle.sh:364-366
[[ -n "$MAIN_SHA" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
# The check modes run here: --check-branch refuses the default branch by name.
if [[ -n "$CHECK" ]]; then
```

(excerpt ends :366; the check block ends :378 — read)

In P2 (the only branch is `trunk`, HEAD detached), both `--check-path README.md` and `--check-fix README.md` printed that message and exited 1. Before c1d0a80 they ran before the lookup. A repo with any current branch still resolves (P3).

**Evidence:** `scripts/dev-cycle.sh:342-378`; `fc24/probe2.log` (P2, P3)

---

## Claim 6: help range `sed -n '2,53p'`

**Location:** `scripts/dev-cycle.sh:116`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the range against the header at c1d0a80. It does not establish that the range stays right after a later header edit.

```bash
# scripts/dev-cycle.sh:116
    -h|--help) sed -n '2,53p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```

The header runs from `:2` to `:52`, and `:53` is the blank line before `set -euo pipefail` (`:54`). E3 printed 52 lines. They begin "Gather the mechanical signals …" and end "… Printed repo text is data." plus the blank line.

**Evidence:** `scripts/dev-cycle.sh:1-54`; `fc24/help.log`

---

## Claim 7: "The cycle's own bookkeeping files; in-cycle fixes to other files go through --check-fix. … A closed brief moves to briefs/closed/, so the open ones are all that the briefs/*.md glob lists."

**Location:** `scripts/dev-cycle.sh:220-224`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the glob does not reach into `closed/` and that fixes go through `--check-fix`. It does not establish that every closed brief is actually moved. That is the skill's job, and it has gaps (Claims 16, 19).

```bash
# scripts/dev-cycle.sh:207
  if [[ "$a" == *[*?]* ]]; then spec=":(glob)$a"; else spec=":(literal)$a"; fi
```

(excerpt ends :207; enclosing `check_path()` ends :219 — read)

In git's `:(glob)` magic, `*` does not match `/`. The test at `:670-681` puts 55 briefs in `closed/` and 2 in `briefs/`, and the glob lists exactly 2 `ok` lines (E1).

**Evidence:** `scripts/dev-cycle.sh:194-219`; `test/scripts/dev-cycle.bats:670-681`; `fc24/bats.log`

---

## Claim 8: "A brief's branch reaches git only as the commit show-ref finds at exactly refs/heads/<name>: never as an option, and never as a tag of the same name … The default branch is refused: a brief's work happens on its own branch."

**Location:** `scripts/dev-cycle.sh:241-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the lookup and the refusal in `check_branch()`. It does not establish that the skill passes only that commit to git (Claim 21 has a second hash with no named source).

```bash
# scripts/dev-cycle.sh:247
  if [[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]; then echo "skip ${a//$'\n'/ }: not an allowed branch name"
```

(excerpt ends :247; enclosing `check_branch()` continues to :256 — read; quoted in Claim 2)

Names starting with `-` are refused. `show-ref --verify` takes only `refs/heads/<name>`, and the result is peeled with `^{commit}`. The tag test passes (E1).

**Evidence:** `scripts/dev-cycle.sh:241-256`; `test/scripts/dev-cycle.bats:574-584`; `fc24/bats.log`

---

## Claim 9: "An in-cycle fix edits documentation only: a tracked .md file under docs/ (outside the cycle's own working files, the user's own docs/human-author/ and the review records) or README.md. Anything else is filed."

**Location:** `scripts/dev-cycle.sh:257-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the gate as stated, with "the cycle's own working files" taken to include the roadmap. It does not establish whether the gate is wide enough for what in-cycle fixes need. Docs outside `docs/` (`skills/`, `workflows/`, `guides/`) and new doc files are always filed, which is a design fact, not a mismatch.

```bash
# scripts/dev-cycle.sh:262-266
  if [[ "$a" == *[*?]* ]]; then echo "skip $a: --check-fix takes one file, not a glob"
  elif ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ ! "$a" =~ ^docs/.*\.md$|^README\.md$ || "$a" =~ ^docs/(working|human-author|reviews)/ ]] || writable "$a"; then
    echo "skip $a: in-cycle fixes edit only tracked .md files under docs/ (not working/, human-author/ or reviews/) and README.md; file it instead"
  else check_path "$a"; fi
```

`check_path` then admits only tracked files, because ignored files count only under `docs/working/`, which is refused above. The test at `:656-668` gives `ok` only for `docs/guides/g.md` and skips an execution-log `.sh`, a human-author `.txt` and `.md`, an ignored and a tracked working file, and the roadmap (E1). `docs/decisions/*.md` passes (`:586-598`).

**Evidence:** `scripts/dev-cycle.sh:257-267`, `:194-219`; `test/scripts/dev-cycle.bats:586-598`, `:656-668`; `fc24/bats.log`

---

## Claim 10: "Lines inside ``` or ~~~ fences are ignored, and a trailing CR is dropped."

**Location:** `scripts/dev-cycle.sh:271`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers fences at column 0 and CRs. It does not establish how often real entries use indented or mixed fences. Today's files have 20 fence lines, all at column 0 and paired.

```awk
# scripts/dev-cycle.sh:303-305
{ sub(/\r$/, "") }
/^(```|~~~)/ { fence = !fence; next }
fence { next }
```

Only a fence line that starts the line is seen, and any fence line toggles the state, so `~~~` closes a ``` fence. In P1:
- Q-13 is an OPEN entry with `**Answer:** [2]` inside a fence indented under a list item. It read `drop`.
- Q-14 has a `~~~` line inside a ``` fence. It read `drop`.

CommonMark would treat both answers as code. Precise version: "lines between fence lines at the start of a line (``` or ~~~, either one closing) are ignored". Wording (behavioral residue: a quoted answer in an indented code block reads as the answer).

**Evidence:** `scripts/dev-cycle.sh:303-306`; `fc24/probe2.log` (P1 Q-13, Q-14); `fc24/bats.log` (Q-7, Q-8 in the test at `:625-654`)

---

## Claim 11: "The answer is the first line in the entry that starts with "Q-NNN:" (after an optional "- "), or that holds a bold "**Answer" / "**Answered" label (any case; not "**Answering") anywhere in it. Its text starts after the label: at ":**" when the label alone is bold, else at the first ": " after the label, and then ends at the bold's close if it opened inside the bold."

**Location:** `scripts/dev-cycle.sh:272-276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers label finding and where the text starts and ends. It does not establish two consequences that follow from "first line … anywhere" and "first ': '". Both are conservative (`unrecognized`), never a wrong keep or drop. First, a bold `**Answer**` in question prose before the real answer is taken as the answer (P1 Q-10). Second, a `: ` inside the label's parenthesis ends the label early (P1 Q-9).

```awk
# scripts/dev-cycle.sh:309-323
inside && !done {
  line = $0; sub(/^[ \t]*(- )?/, "", line)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
  low = tolower(line); p = index(low, "**answer"); if (!p) next
  after = substr(low, p + 8, 2)
  if (after ~ /^[a-z]/ && after != "ed") next
  rest = substr(line, p + 2)
  if ((c = index(rest, ":**")) > 0 && (c < (d = index(rest, ": ")) || !d)) {
    rest = substr(rest, c + 3)
  } else if ((c = index(rest, ": ")) > 0) {
    rest = substr(rest, c + 2)
    if ((e = index(rest, "**")) > 0) rest = substr(rest, 1, e - 1)
  } else next
  result = option(rest); done = 1
}
```

On the real files (E4), the "anywhere" change moved exactly Q-070, Q-071 and Q-073 (each `… ? **Answered 2026-09-27: [1] …**`). No other entry changed reading. Q-072 (`between [1] and [2]`) stays `unrecognized`. "Original entry:" quoting comes after the answer line in every real entry (Q-065, Q-066, Q-081, Q-083), so the first-line rule never reaches it. A time's colon (`10:30:`) is not a label end (test Q-5). A tab after the heading ID is read (P1 Q-8 → `drop`).

**Evidence:** `scripts/dev-cycle.sh:298-323`; `fc24/joined.log`; `fc24/answers-new.log`; `fc24/probe2.log` (P1 Q-8–Q-10)

---

## Claim 12a: "The text's leading token decides: [1], 1 or keep is keep; [2], 2 or drop is drop (a word must be followed by the end, punctuation or a dash) … With no such token, a lone [1] or [2] in the text decides; both, or neither, is unrecognized."

**Location:** `scripts/dev-cycle.sh:277-280`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what counts as "punctuation" and "a dash" after a leading word. It does not establish the comment's conclusion about notes (Claim 12b).

```awk
# scripts/dev-cycle.sh:287-292
  if (match(s, /^(1|2|keep|drop)/)) {
    w = substr(s, 1, RLENGTH); r = substr(s, RLENGTH + 1)
    t = r; sub(/^[ \t]+/, "", t)
    if (r == "" || r ~ /^[.,;:!)]/ || (t != r && (t == "" || substr(t, 1, 1) == "-" \
        || substr(t, 1, 3) == "\342\200\224" || substr(t, 1, 3) == "\342\200\223")))
      return (w == "1" || w == "keep") ? "keep" : "drop"
```

(excerpt ends :292; enclosing `option()` continues to :297 — read)

"Punctuation" is only `. , ; : ! )`. A dash (`-`, em dash, en dash) counts only after whitespace, because the `t != r` guard needs a space first. So `drop?` and `drop—x` are not leading tokens (P1 Q-7, Q-4). The em and en dash bytes work under mawk: the test's `drop — [1] …` read `drop`, and P1 Q-5 `drop – [1] …` read `drop`. "keep both" stays `unrecognized` (P1 Q-6; real Q-010). Precise version: "followed by the end, by one of . , ; : ! ), or by a space and then a dash". Wording.

**Evidence:** `scripts/dev-cycle.sh:283-297`; `fc24/probe2.log` (P1 Q-4–Q-7); `fc24/bats.log`

---

## Claim 12b: "… so a note after it ("drop. Option [1] would cost more") cannot flip it." (also the test title "--check-answer: notes cannot flip an answer; …" and commit c1d0a80: "the answer's leading token decides ([1], 1, keep / [2], 2, drop), so a note after it cannot flip it")

**Location:** `scripts/dev-cycle.sh:278-279`; `test/scripts/dev-cycle.bats:625`; commit c1d0a80
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers worded answers followed by a note that names the other option in brackets. It does not establish how often users write that shape: no real archive entry has it today. It does not affect bracketed answers (`[2] …`), which always decide first.

A note can still flip a worded answer when the word is followed by a space and anything other than a dash. The leading-token test fails (Claim 12a), and the fallback reads the note's bracket:

```awk
# scripts/dev-cycle.sh:294-296
  one = index(s, "[1]") > 0; two = index(s, "[2]") > 0
  if (one != two) return one ? "keep" : "drop"
  return "unrecognized"
```

In P1:
- `**Answer:** drop because [1] costs more` read **`keep`**.
- `**Answer:** drop (not [1])` read **`keep`**.
- `**Answer:** keep it, not [2]` read **`drop`**.
- `**Answer:** drop—[1] was the interim` read **`keep`**.
- `**Answer:** drop? [1] maybe later` read **`keep`**.

The test covers only notes separated by `.`, `,` or ` — `.

Behavioral consequence through the skill: In flight 2 applies the flipped reading once and puts the ID on `Applied:` (`skills/dev-cycle/SKILL.md:262-265`). A dropped brief gets `Kept:` and holds its slot, or a kept brief is closed to Ideas, and the answer is never re-read. Preconditions: the user answers with the word, not the number, and the same line names the other option in brackets after a space. Medium likelihood for "drop because [1] …" and "drop (not [1])". Precise version: "a note after punctuation or a spaced dash cannot flip it". Or the fix: with a leading `keep`/`drop` word, ignore brackets elsewhere.

**Evidence:** `scripts/dev-cycle.sh:277-297`; `test/scripts/dev-cycle.bats:625-654`; `fc24/probe2.log` (P1 Q-1–Q-4, Q-7)

---

## Claim 13: check_answer skip lines: "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read" and "skip $a: more than one entry with this heading (… and …)"

**Location:** `scripts/dev-cycle.sh:328-341`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers a non-plain questions file and duplicates within or across the two files. It does not establish when a cycle produces a cross-file duplicate. That happens only when `questions.sh archive` is interrupted between its two writes (it appends to the archive first, `scripts/questions.sh:381-387`). A completed archive run moves the entry, so it is never found twice.

```bash
# scripts/dev-cycle.sh:331-338
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi
    [[ -f "$f" ]] || continue
    r="$(env LC_ALL=C awk -v id="$a" "$ANSWER_AWK" "$f")"
    [[ -n "$r" ]] || continue
    if [[ "$r" == dup || -n "$hit" ]]; then echo "skip $a: more than one entry with this heading${where:+ ($where and $f)}"; return; fi
    hit="$r"; where="$f"
  done
```

(excerpt ends :338; enclosing `check_answer()` ends :341 — read)

The test at `:625-654` gives `skip Q-9` (twice in one file), `skip Q-10` (once in each file) and `keep Q-100`. It also gives the symlinked-`questions.md` skip, which fixes pass 23's Claim 14 (E1). Pass-23 Incorrect 14 is resolved.

**Evidence:** `scripts/dev-cycle.sh:328-341`; `scripts/questions.sh:374-395`; `test/scripts/dev-cycle.bats:625-654`; `fc24/bats.log`

---

## Claim 14: "The check modes run here: --check-branch refuses the default branch by name."

**Location:** `scripts/dev-cycle.sh:365`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers placement after the lookup and the use of `$MAIN` in `check_branch`. It does not establish that `$MAIN` is the remote's default (Claim 2's residue: it can be the current branch).

```bash
# scripts/dev-cycle.sh:366-378
if [[ -n "$CHECK" ]]; then
  for a in "${CHECK_ARGS[@]}"; do
    case "$CHECK" in
      --check-path) check_path "$a" ;;
      --check-write) check_write "$a" ;;
      --check-brief) check_write "$a" brief ;;
      --check-branch) check_branch "$a" ;;
      --check-fix) check_fix "$a" ;;
      --check-answer) check_answer "$a" ;;
    esac
  done
  exit 0
fi
```

`skip main: the default branch` passes in the test at `:538-551` (E1), and P3 shows the current-branch case.

**Evidence:** `scripts/dev-cycle.sh:342-378`; `test/scripts/dev-cycle.bats:538-551`; `fc24/probe2.log` (P3)

---

## Claim 15: "An in-cycle fix … edits only a file that `--check-fix '<path>'` prints `ok` for: a tracked `.md` file under `docs/` (not `docs/working/`, `docs/human-author/` or `docs/reviews/`) or `README.md`" (also commit fb643e2: "--check-fix scope stated as the script enforces it")

**Location:** `skills/dev-cycle/SKILL.md:71-74`; commit fb643e2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the skill's statement of the scope. It does not establish a behavioral effect, because the gate is the script's `ok` and the roadmap is written through `--check-write`.

```markdown
<!-- skills/dev-cycle/SKILL.md:71-74 -->
only those files. An in-cycle fix (steps 1, 3, 4, and a missing doc) edits only a file that
`--check-fix '<path>'` prints `ok` for: a tracked `.md` file under `docs/` (not
`docs/working/`, `docs/human-author/` or `docs/reviews/`) or `README.md`; anything else (a
new file, code, scripts, hooks, egress lists, instruction files) is filed, not written.
```

This leaves out the same `docs/roadmap.md` refusal as Claim 3 (`scripts/dev-cycle.sh:264`, quoted there). So "as the script enforces it" is one exclusion short. Wording.

**Evidence:** `skills/dev-cycle/SKILL.md:71-74`; `scripts/dev-cycle.sh:257-267`; `test/scripts/dev-cycle.bats:656-668`; `fc24/bats.log`

---

## Claim 16: "Open briefs are found only through `--check-path 'docs/working/briefs/*.md'` (a closed brief moves to `docs/working/briefs/closed/`, so the glob lists open ones only)"

**Location:** `skills/dev-cycle/SKILL.md:75-76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers which briefs stay in `briefs/`. It does not establish how often a brief is closed by hand. Medium confidence: "said so" may be read to cover a hand edit.

The glob excludes `closed/` (Claim 7). But only In flight 1 moves a brief, and only for `Status: done` or a user drop:

```markdown
<!-- skills/dev-cycle/SKILL.md:251-255 -->
  1. The brief on the default branch says `Status: done` (the build session sets it in the
     change it merges; see Build briefs) → Done, with that merge. The user dropped it (said
     so, or by keep-or-drop) → Ideas, with the reason, and the brief gets `Status: closed`.
     Either way, `git mv` the brief to `docs/working/briefs/closed/` (same file name; its
     destination passes `--check-write`) and point the roadmap line there. Done never
```

(excerpt ends :255; In flight 1 ends :256 — read)

The pass-23 text listed "closed the brief, or said so". "Closed the brief" is gone. A brief whose `Status:` the user set to `closed` by hand, without moving it, matches no rule. It stays in the glob, counts as open, holds a slot and goes to keep-or-drop. The move can also fail outright (Claim 19). Precise version: keep "closed the brief" as a drop signal, or say "every brief whose Status is not open is moved". Wording (small behavioral residue).

**Evidence:** `skills/dev-cycle/SKILL.md:75-76`, `:249-276`; `git diff 36ca12c..fb643e2 -- skills/dev-cycle/SKILL.md`

---

## Claim 17: "A brief's branch reaches git only as the commit `--check-branch '<name>'` prints (`ok <name> <commit>`; `absent <name>` means no such branch), never by name."

**Location:** `skills/dev-cycle/SKILL.md:78-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that the output forms match the script. It does not establish the source of the second hash in In flight 3 (Claim 21).

```bash
# scripts/dev-cycle.sh:254
    if [[ -n "$sha" ]]; then echo "ok $a $sha"; else echo "absent $a"; fi
```

(excerpt ends :254; enclosing `check_branch()` ends :256 — read)

E1 and P5 show the `ok <name> <40-hex>` and `absent <name>` forms.

**Evidence:** `skills/dev-cycle/SKILL.md:78-80`; `scripts/dev-cycle.sh:245-256`; `fc24/probe2.log` (P5)

---

## Claim 18: "The brief on the default branch says `Status: done` (the build session sets it in the change it merges; see Build briefs) → Done, with that merge. … Done never depends on the branch, so a squash, a rebase or a deleted branch does not matter."

**Location:** `skills/dev-cycle/SKILL.md:251-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the Done signal and that it ignores the branch. It does not establish two things. First, what happens when the build session forgets the status (Claim 21's residue). Second, how the cycle finds "that merge": no command for it is named, and the Rules allow only named commands (`:25-26`).

```markdown
<!-- skills/dev-cycle/SKILL.md:294-296 -->
included, and "set this brief's `Status: done` in the change that merges it"), branch (a
new name: `--check-branch` prints `absent` for it), and
```

(excerpt ends :296; the Build briefs paragraph ends :299 — read)

Check 1 reads only the brief's own status. The cycle reads it from its working tree, and step 0 runs on an up-to-date default-branch checkout before the cycle branch is cut (`:110-113`), so that is the default branch's copy. The status reaches the default branch only through the merge, so squash, rebase and branch deletion do not change it. Pass-23 Incorrect 21 (ancestry wrong in both directions) is resolved.

**Evidence:** `skills/dev-cycle/SKILL.md:108-119`, `:249-256`, `:286-299`

---

## Claim 19: "Either way, `git mv` the brief to `docs/working/briefs/closed/` (same file name; its destination passes `--check-write`)"

**Location:** `skills/dev-cycle/SKILL.md:254-255`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the command as written, on the first close in a repo. It does not establish later closes, which work once `closed/` exists. It does not establish what an agent does after the failure.

Git does not track empty directories, so `docs/working/briefs/closed/` exists only after a brief has been moved there. Neither worktree has `docs/working/briefs/` at all today. `--check-write` approves the destination regardless (Claim 1). In P4, on a tracked open brief:

```text
ok docs/working/briefs/closed/2026-01-01-a.md
fatal: renaming 'docs/working/briefs/2026-01-01-a.md' failed: No such file or directory
  [git mv exit 128]
```

So the first close in every project fails as written. The skill names no `mkdir`, and its Rules allow only commands it names (`skills/dev-cycle/SKILL.md:25-26`). The agent has to improvise, or leave the brief in place, where it keeps counting as open.

Second precondition (paraphrased — no quote available because it concerns git's refusal on files outside the index, not a line in this repo): in a project where `docs/working/` is gitignored, the brief is not tracked, so `git mv` refuses it ("not under version control"). The briefs also never reach the default branch there, so check 1's `Status: done` signal never arrives.

Fix: "create the directory if needed (`mkdir -p docs/working/briefs/closed`), then `git mv`", named in the skill. Behavioral, low severity: there is a visible error, and nothing is lost.

**Evidence:** `skills/dev-cycle/SKILL.md:25-26`, `:251-256`; `scripts/dev-cycle.sh:228-240`; `fc24/probe2.log` (P4)

---

## Claim 20: "A `skip` (the entry could not be read) goes in the record and the final message, and the ID stays off `Applied:`, so the answer is read once the cause is fixed."

**Location:** `skills/dev-cycle/SKILL.md:265-267`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that a skipped ID is re-read every cycle. It does not establish a residue. A skip whose cause persists ("no such entry": the entry was deleted, or step 3 wrote `Asked:` but the entry was never filed) also blocks check 3 every cycle, because check 3 needs no Asked ID that is "still `open` or skipped" (`:268-269`). That brief holds its slot until the user acts. It is reported in every final message (`:331-332`), so the residue is not silent.

```markdown
<!-- skills/dev-cycle/SKILL.md:264-267 -->
     keep-or-drop entry, which step 3 files; a second reply on this one is not read). Add the
     ID to `Applied:` after `keep`, `drop` or `unrecognized`, so each answer is read once. A
     `skip` (the entry could not be read) goes in the record and the final message, and the
     ID stays off `Applied:`, so the answer is read once the cause is fixed.
```

The script reports every unreadable case as a `skip` with its cause (Claim 13). Pass-23 Incorrect 14's skill half is resolved.

**Evidence:** `skills/dev-cycle/SKILL.md:257-276`, `:331-332`; `scripts/dev-cycle.sh:328-341`

---

## Claim 21: "\"Shows no work\": `--check-branch` prints `absent`, skips the name (recorded), or prints a commit with no commit beyond the default branch (`git rev-list --count <default-commit>..<commit>` is 0)."

**Location:** `skills/dev-cycle/SKILL.md:274-276`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the rev-list test on hashes for fresh, merged, squash-merged and working branches. It does not establish what a brief whose build session forgot `Status: done` costs. A merged-and-deleted or no-ff-merged branch shows no work, so after 14 days the user gets keep-or-drop. A "drop" then files finished work under Ideas, and nothing routes it to Done. A squash-merged branch that was kept shows work, so it is never asked and holds its slot until closed by hand.

The test works on hashes alone. In P5, after `--check-branch` and with `D=$(git rev-parse main)`:

```text
  ok fresh f974e33… -> rev-list count 0
  ok merged 9c612a4… -> rev-list count 0
  ok squashed 8d18d1b… -> rev-list count 1
  ok working 880d8d1… -> rev-list count 1
```

But `<default-commit>` has no named source. `--check-branch` refuses the default branch (Claim 2), and the digest's Window line prints only a 7-character abbreviation:

```bash
# scripts/dev-cycle.sh:417
echo "Window: since $SINCE (from $source_note). Merges, commits and section 7's changed files: those on \`$MAIN\` at ${MAIN_SHA:0:7} whose committer date …"
```

(excerpt ends inside the line; the Window `echo` is a single line — read)

The Rules' "only as the commit … never by name" (`:78-80`) covers brief branches, so `git rev-parse <default name>` is not forbidden. It is not named either. Precise version: name the source, e.g. "the digest's `at <hash>` on the Window line". Wording.

**Evidence:** `skills/dev-cycle/SKILL.md:25-26`, `:78-80`, `:268-276`; `scripts/dev-cycle.sh:245-256`, `:417`; `fc24/probe2.log` (P5)

---

## Claim 22: "while fewer than 3 briefs are open: the ones the Rules' glob lists plus any this cycle has written that it does not list yet (a new brief is untracked until it is staged), each counted once."

**Location:** `skills/dev-cycle/SKILL.md:286-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the count against `--check-path`'s listing: the index, plus ignored files under `docs/working/`. It does not establish the case where a closed brief's `git mv` failed (Claim 19). That brief stays listed and counted.

```bash
# scripts/dev-cycle.sh:196
  GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1" | exact "$2"
```

(excerpt ends :196; enclosing `matches()` continues to :203 — read)

`git ls-files` reads the index. So a staged new brief is listed, an unstaged one is not, and a brief `git mv`'d this cycle is listed under `closed/`, outside the glob. Where `docs/working/` is ignored, a new brief is listed at once, and "each counted once" covers it. This resolves pass-23 Mostly accurate 24.

**Evidence:** `scripts/dev-cycle.sh:194-219`; `skills/dev-cycle/SKILL.md:286-289`

---

## Claim 23: Build briefs: "a file name no brief has used before, in `briefs/` or `briefs/closed/`" … acceptance criteria "set this brief's `Status: done` in the change that merges it", "branch (a new name: `--check-branch` prints `absent` for it)"

**Location:** `skills/dev-cycle/SKILL.md:290-297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that each instruction is expressible with the named checks. It does not establish how the cycle lists `closed/` for the name check. A `closed/*.md` glob is capped at 50 matches (`scripts/dev-cycle.sh:205-211`), so past 50 closed briefs only an exact-path `--check-path` per candidate name is complete.

```bash
# scripts/dev-cycle.sh:211
    if [[ $n -gt $max ]]; then echo "skip $a: matches more than $max files; the rest are not listed (narrow the glob)"; break; fi
```

(excerpt ends :211; enclosing `check_path()` continues to :219 — read)

`absent` is printed for a free name (E1 test `:538-551`; `fc24/probe2.log` shows the form). The new acceptance criterion is the one check 1 reads (Claim 18).

**Evidence:** `skills/dev-cycle/SKILL.md:286-299`; `scripts/dev-cycle.sh:204-219`, `:245-256`; `fc24/bats.log`

---

## Claim 24: test titles "--check-fix refuses code, the user's own files and ignored scratch under docs/" and "closed briefs move out of the glob, so open ones are listed past 50 briefs", and the updated "--check-branch allows only a plain, valid branch name"

**Location:** `test/scripts/dev-cycle.bats:538-551`, `:656-668`, `:670-681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that each test asserts what its title says and passes. It does not establish the "notes cannot flip" title at `:625` (Claim 12b).

```bash
# test/scripts/dev-cycle.bats:671-675
    mkdir -p docs/working/briefs/closed
    for i in $(seq 10 64); do echo c > "docs/working/briefs/closed/2026-01-$((i % 28 + 1))-b$i.md"; done
    echo o > docs/working/briefs/2026-03-01-open-a.md && echo o > docs/working/briefs/2026-03-02-open-b.md
    git add -A && git commit -qm briefs
    run --separate-stderr bash "$DC" --check-path 'docs/working/briefs/*.md'
```

(excerpt ends :675; the test continues to :681 — read)

That is 55 closed briefs and 2 open ones. Some closed names have a one-digit day, which is harmless because only the glob is under test. `:656-668` asserts exactly 1 `ok` (a guide) and 6 refusals, including ignored `docs/working/round-3.md`. `:538-551` asserts one `ok` line with its hash, `absent`, and `skip main: the default branch`. All 36 pass (E1).

**Evidence:** `test/scripts/dev-cycle.bats:538-551`, `:656-681`; `fc24/bats.log`

---

## Claim 25: commit c1d0a80: "Bold Answer labels are found anywhere in a line (the archive's Q-070, Q-071, Q-073 now read keep; nothing else changed on the real files)."

**Location:** commit c1d0a80
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers all 102 entries in wt-devcycle's two questions files as of 16:09Z. It does not establish entries written later.

The ba39470 vs c1d0a80 readings differ only on these lines (`diff fc24/answers-old.log fc24/answers-new.log`):

```text
< unrecognized Q-070
< unrecognized Q-071
---
> keep Q-070
> keep Q-071
73c73
< unrecognized Q-073
---
> keep Q-073
```

The counts went from 26 keep / 19 drop / 13 open / 44 unrecognized to 29 / 19 / 13 / 41. Each of the three answers is `**Answered 2026-09-27: [1] …**` mid-line, so `keep` is right. I read all 41 `unrecognized` entries in `fc24/joined.log`. None holds a clear keep or drop: they are worded answers, `[3]`, "between [1] and [2]", "keep both", and ANSWERED entries with no answer line. No answered entry reads `open`, and no open entry reads as answered.

**Evidence:** `fc24/answers-old.log`; `fc24/answers-new.log`; `fc24/joined.log`; `/workspace/.claude/wt-devcycle/docs/working/questions-archive.md:1409-1484`

---

## Claim 26: commit c1d0a80, the rest ("a lone bracket decides only when there is no leading token"; "The label ends at ":**" or the first ": ", not at a time's colon. Fenced lines are ignored, a trailing CR is dropped, a heading may be followed by a tab, and a heading found twice … is a skip. A questions file that is not plain is reported as a skip"; the `--check-fix`, `--check-branch` and closed-brief bullets; "Tests: … 55 closed briefs. 36/36; shellcheck clean.")

**Location:** commit c1d0a80
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each listed bullet apart from three handled elsewhere: "so a note after it cannot flip it" (Claim 12b), "Help text describes every mode's lines" (Claim 3), and "Fenced lines are ignored" as qualified in Claim 10. It does not establish behavior on other awks than mawk by execution.

These are verified by E1 (`1..36`, 36 ok), E2 (shellcheck exit 0, empty log), P1 Q-8 (tab heading) and the code quoted in Claims 2, 9, 11 and 13. The "55 closed briefs" figure is `seq 10 64` (`test/scripts/dev-cycle.bats:672`), which is 55 values.

**Evidence:** `fc24/bats.log`; `fc24/shellcheck.log`; `fc24/probe2.log`; `test/scripts/dev-cycle.bats:670-681`

---

## Claim 27: commit fb643e2 ("Done is the brief's own `Status: done` … The old rule … closed unstarted branches as Done and never reached Done for a merged-then-deleted, squashed or rebased one"; "A closed or done brief moves to docs/working/briefs/closed/, so the open-brief glob never reaches the 50 cap; new file names avoid both dirs"; "\"shows no work\" … so a brief whose branch fails the check no longer holds its slot forever"; "A --check-answer skip stays off Applied:"; "the open-brief count counts each brief once")

**Location:** commit fb643e2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers these bullets as statements about the new text and the old rule. It does not establish two parts handled elsewhere: that the move itself succeeds (Claim 19) and "--check-fix scope stated as the script enforces it" (Claim 15).

The old rule's failures are reproduced in P5. A fresh branch has `rev-list --count 0` and is an ancestor of main, so the old rule called it Done. A squash-merged branch has count 1, so the old rule never reached Done. The new text's handling of each bullet is quoted in Claims 18, 20, 21 and 22. A brief whose branch is skipped now "shows no work" (`skills/dev-cycle/SKILL.md:274-275`), so it reaches keep-or-drop. This resolves pass-23 Mostly accurate 22.

**Evidence:** `skills/dev-cycle/SKILL.md:249-299`; `fc24/probe2.log` (P5)

---

## Claims Requiring Attention

### Incorrect
- **Claim 12b** (`scripts/dev-cycle.sh:278-279`, test title `:625`, commit c1d0a80): "a note after it cannot flip it" is false when a worded answer is followed by a space and a note. `drop because [1] costs more` and `drop (not [1])` read `keep`, and `keep it, not [2]` reads `drop`. In flight 2 then applies the flipped reading once and for good. **Behavioral** (precondition: a worded answer plus the other bracketed option after a space; no real entry has it today).
- **Claim 19** (`skills/dev-cycle/SKILL.md:254-255`): `git mv` into `docs/working/briefs/closed/` fails (exit 128) on the first close in any repo, because the directory does not exist yet and no `mkdir` is named. Where `docs/working/` is gitignored, `git mv` refuses the untracked brief. **Behavioral, low** (a visible error, nothing lost).

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`scripts/dev-cycle.sh:37-39`, `:265`; commit c1d0a80 "Help text describes every mode's lines"): the help and the skip reason leave out the `docs/roadmap.md` refusal. **Wording.**
- **Claim 10** (`scripts/dev-cycle.sh:271`): only column-0 fences are seen, and `~~~` closes ```. An answer inside an indented code block is read. **Wording** (small behavioral residue).
- **Claim 12a** (`scripts/dev-cycle.sh:277-280`): "punctuation" is `. , ; : ! )` only, and a dash counts only after a space. **Wording.**
- **Claim 15** (`skills/dev-cycle/SKILL.md:71-74`; commit fb643e2): the same roadmap omission as Claim 3. **Wording.**
- **Claim 16** (`skills/dev-cycle/SKILL.md:75-76`): "the glob lists open ones only". A brief closed by hand (Status edited, not moved) matches no rule now that "closed the brief" is gone, so it stays listed as open. **Wording** (small behavioral residue).
- **Claim 21** (`skills/dev-cycle/SKILL.md:274-276`): the rev-list test works on hashes, but `<default-commit>` has no named source. `--check-branch` refuses the default, and the digest gives a 7-character abbreviation. Residue: a brief whose build session forgot `Status: done` either goes to keep-or-drop (where "drop" files done work under Ideas) or, if squash-merged with the branch kept, holds its slot indefinitely. **Wording** (the residue is behavioral and needs the build session to forget).

### Unverifiable
(none)

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass24.md`. It has the required first line, `**Replication:** k=1 (loop pass, decision 031)`, the seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary. It was not committed.

Against the brief's priority list:

**A, `--check-answer` on the real files.** Confirmed: only Q-070, Q-071 and Q-073 changed reading, all to a correct `keep`. No misread among the 102 entries. "Original entry:" quoting always follows the answer line. No real `**Answer` sits in question prose or a table row before an answer (25, 11).

Edges:
- The em and en dash bytes work under mawk.
- "keep both" stays `unrecognized` (12a).
- A worded answer followed by a space and a bracketed note still flips (12b, the one behavioral defect on the A side).
- Prose labels and colons in labels give a conservative `unrecognized` (11).
- Indented or mixed fences are not seen (10).

**A, duplicates across files.** Correct and complete. During a cycle, a cross-file duplicate arises only from an interrupted `questions.sh archive`, and it is a skip that stays off `Applied:` (13, 20).

**A, `--check-fix` vs in-cycle needs.** The gate is correct as a rule (9). Decision records pass. `guides/`, `skills/`, `workflows/`, new docs and the roadmap are refused. The roadmap refusal is undocumented (3, 15).

**A, `--check-branch` ordering.** Correct. A repo with no resolvable default branch now fails every check mode with exit 1, which the header documents. It cannot arise in a cycle, which runs on the default branch (5, 14). Edges: the current branch stands in as "default" in a repo with no main or master, and a non-commit ref prints `absent` (2).

**A, help range and commit.** `2,53p` is correct (6). c1d0a80's message is right except "notes cannot flip it" (12b) and "help describes every mode" (3). 36/36, shellcheck clean.

**B, Done flow end to end.** The build session sets the status in its merge. The cycle reads it from the default-branch checkout. Squash, rebase and deletion do not matter (18). Gaps:
- a forgotten status falls to keep-or-drop or holds the slot (21);
- a brief closed by hand is no longer recognized (16);
- "with that merge" has no named command (18).

**B, `git mv` to `closed/`.** It stages named paths only, which is consistent with the Rules, and its destination passes `--check-write`. But it fails on the first close (19).

**B, keep-or-drop "shows no work".** It is correct on hashes (P5), but the default commit's source is unnamed (21).

**B, commit fb643e2.** Right, apart from the fix-scope wording (15) and the unstated precondition of the move (19).
