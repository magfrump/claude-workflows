Commit: 1b0c4ff (A) / 462e561 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 1b0c4ff; HEAD d22a0a9 adds review docs only, `git diff --stat 1b0c4ff HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 462e561; HEAD 6c35818 only merges A in, `git diff --stat 462e561 6c35818 -- skills/dev-cycle docs/dev-cycle.md` is empty).
**Scope:** Partial: the pass-18 fix round only. A: `git diff 36417f5..1b0c4ff -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of 1b0c4ff. B: `git diff db24c74..462e561 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` plus the message of 462e561. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 19 verified, 5 mostly accurate, 0 stale, 4 incorrect, 1 unverifiable

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read first. No claim below matches a logged pattern.

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc19/` (below, `fc19/`). Throwaway repos were built under `mktemp -d` directories inside `fc19/` and removed by the probe scripts. Every process ran under `timeout` and none outlived its command. Nothing was written to either worktree except this report.

Executed runs (times UTC):
- E1 `timeout 300 bats test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` at 2026-10-02T08:37:24Z, exit 0, 24/24 ok → `fc19/logs/bats-digest.log`. `timeout 60 shellcheck scripts/dev-cycle.sh` in the same directory at 08:39:14Z, exit 0, empty output → `fc19/logs/shellcheck.log`.
- E2 1b0c4ff's test file run against 36417f5's `scripts/dev-cycle.sh` (plus `scripts/questions.sh`), copied into a `mktemp -d` tree under `fc19/`: `timeout 300 bats -f 'record dates match' test/scripts/dev-cycle.bats` at 08:37:41Z, exit 0 (the test passes on the pre-fix script) → `fc19/logs/bats-newtest-oldscript.log`.
- E3 `timeout 300 fc19/probe-a.sh fc19` at 08:38:03Z, exit 0 → `fc19/logs/probe-a.log`. P1: a quoted name that was committed and then removed from the index. P2/P3: a side change that a merge discarded, with the side's author date older (P2) or newer (P3) than main's. P4: a skipped record whose name is not a real date. P5: section 8 output when `docs/working` is a symlink.
- E4 `bash fc19/probe-b.sh` (cwd `/workspace/.claude/wt-devcycle`) at 08:38:59Z, exit 0 → `fc19/logs/probe-b.log`. Applies the skill's check 1 literally (regex) and check 2 (`git ls-files --error-unmatch`) to sample paths.
- E5 `timeout 120 bash fc19/probe-c.sh fc19` at 08:39:42Z, exit 0 → `fc19/logs/probe-c.log`. Uses `bash -x` to trace which `git ls-files` / `git log -1` calls the record loop makes for quoted-committed, plain-committed, untracked and staged-uncommitted records.

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest, record or commit log).

---

## Claim 1a: "Tracked files only, as plain paths from the repo root (letters, digits, `.`, `_`, `-`, `/`; no `..` or `.git` component), never through a symlink: the skill's \"Plain, tracked repo paths only\" rule."

**Location:** `docs/dev-cycle.md:27-29`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers whether this summary matches the skill's rule; does not establish whether the rule fits the file's own glob row (Claim 1b).

The skill's check 1 is wider than this summary: "does not start with `/` or `-`, and has no `..` component and no component starting with `.git` (any case)" (`skills/dev-cycle/SKILL.md:68-69`). The settings file says "no ... `.git` component". So a reader of the settings file would expect `.gitignore` or `.github/...` to pass, and the skill rejects both (E4: `.gitignore : check1=fail`). The summary also leaves out the leading-`-` ban, although "from the repo root" already implies the leading-`/` ban. The precise wording would be "no `..` component and no component starting with `.git` in any case; not starting with `-`".

**Evidence:** `docs/dev-cycle.md:27-29`, `skills/dev-cycle/SKILL.md:66-72`, `fc19/logs/probe-b.log`

---

## Claim 1b: The settings' own idea-source row is a valid path under the stated rule

**Location:** `docs/dev-cycle.md:27-33`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the row `docs/working/feature-ideas*.md` against check 1 as the skill orders it; does not establish which order a running agent would actually use (the text is open to the reading in Claim 9).

The paragraph says sources are "plain paths ... (letters, digits, `.`, `_`, `-`, `/` ...)" (`docs/dev-cycle.md:27`). The only row under it is `| Feature ideas | docs/working/feature-ideas*.md | ... |` (`docs/dev-cycle.md:33`), and its `*` is outside that character set. Check 1 run on the row as written fails, even though the file the glob matches is tracked:

```
docs/working/feature-ideas*.md : check1=fail ls-files-exit=0
docs/working/feature-ideas.md : check1=pass ls-files-exit=0
```
(`fc19/logs/probe-b.log`). E4 ran `bash fc19/probe-b.sh` in `/workspace/.claude/wt-devcycle` at 2026-10-02T08:38:59Z, exit 0.

The column is headed "Path or glob", and the pass-18 report's Claim 1 found this row compliant under the old rule, which had no character set. This round's rule makes the file contradict itself. Under the skill's literal check order (Claim 9), step 5 skips the repo's only configured idea source.

**Evidence:** `docs/dev-cycle.md:27-33`, `skills/dev-cycle/SKILL.md:66-72`, `fc19/logs/probe-b.log`

---

## Claim 2: "Keep the newest skipped date (not future-dated) to warn when it is newer than the record the window starts from." (with the added real-date check)

**Location:** `scripts/dev-cycle.sh:155-158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the skipped-record branch of the cycles loop and its only use, the Window note at `:172-174`; does not establish anything about readable records (`:161-162`, unchanged).

```bash
# scripts/dev-cycle.sh:157-159
      skipped "$f" && [[ "$SKIP_AT" == "$f" && "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] \
        && date -d "$d" >/dev/null 2>&1 && skipped_record="$d"
      continue
```
(excerpt ends :159; the enclosing `for` loop continues to :163 — read). In E3 P4 a symlinked `cycle-2026-02-31.md` left the Window line without a "newer record" note. A symlinked `cycle-2026-02-10.md` then produced "a newer record, docs/working/cycles/cycle-2026-02-10.md, was skipped" (`fc19/logs/probe-a.log`). E3 ran `timeout 300 fc19/probe-a.sh fc19` at 08:38:03Z, exit 0. The `&&` list sits in a non-final position, so a failing `date` does not trip `set -e` (`scripts/dev-cycle.sh:24`).

**Evidence:** `scripts/dev-cycle.sh:150-174`, `fc19/logs/probe-a.log`

---

## Claim 3: "A name git still quotes (a quote, backslash or control character) misses the map and, if tracked, falls back to its own lookup."

**Location:** `scripts/dev-cycle.sh:212-214`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers quoted names, committed or not, against the map built at `:219-224` and the fallback at `:234-236`; does not establish that a quoted name that is untracked but committed gets a date (it does not: Claim 6b).

The trace shows the quoted committed name going through `ls-files` and then its own `git log -1`. The untracked plain name stops after `ls-files`:

```
+ git ls-files --error-unmatch -- 'docs/decisions/001-a"b.md'
++ git log -1 --format=%ad --date=short -- 'docs/decisions/001-a"b.md'
### docs/decisions/001-a"b.md (last committed on this branch: 2026-10-02)
+ git ls-files --error-unmatch -- docs/decisions/003-untracked.md
### docs/decisions/003-untracked.md (last committed on this branch: never, uncommitted)
```
(`fc19/logs/probe-c.log`). E5 ran `timeout 120 bash fc19/probe-c.sh fc19` at 08:39:42Z, exit 0.

**Evidence:** `scripts/dev-cycle.sh:209-240`, `fc19/logs/probe-c.log`

---

## Claim 4: "Around merges the date can differ from per-file `git log -1`, in either direction: one walk over the whole directory does not simplify history per file, so a change a merge discarded, or the same change made on both sides, can decide the date."

**Location:** `scripts/dev-cycle.sh:214-217`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the discarded-change case in both directions; does not establish the "same change on both sides" case, which was not probed and is confirmed only by reading git's TREESAME simplification.

E3 P2 and P3 merge a side branch that changed `001-f.md` and `002-g.md`, and keep main's `001-f.md`. Per-file `git log -1` gives `2026-01-10 mainchange` in both probes. The digest gives `2026-01-05` when the side's author date is older (P2, so earlier) and `2026-01-20` when it is newer (P3, so later) (`fc19/logs/probe-a.log`). The directory walk at `:222` keeps the side branch because the merge is not TREESAME on `docs/decisions` as a whole:

```bash
# scripts/dev-cycle.sh:222-223
    git -c core.quotePath=false log --diff-merges=combined --format='@%ad' --date=short --name-only -- docs/decisions \
      | awk '/^@/ { d = substr($0, 2); next } NF && !seen[$0]++ { print $0 "\t" d }')
```
(excerpt ends :223; the enclosing `if` closes at :224 — read). The "earlier" direction needs an author date older than the commit order suggests (P2 used an author date of 01-05 with a committer date of 01-20).

**Evidence:** `scripts/dev-cycle.sh:219-224`, `fc19/logs/probe-a.log`

---

## Claim 5: "It is always a real commit on this branch that touched the record; it is shown as evidence only."

**Location:** `scripts/dev-cycle.sh:217-218`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the map (`:222`, `git log` with no revision, so HEAD) and the fallback (`:235`, also HEAD); does not establish that "this branch" is the default branch (that holds only when the digest is run from a checkout of it, as skill step 0 requires).

Every date comes from an `@%ad` line of a commit that `git log` on HEAD listed with the path under `--name-only` (`:222-223`, quoted in Claim 4), or from `git log -1 ... -- "$f"` (`:235`). Both are commits reachable from HEAD that the walk reports as touching the path. In P2 the date it chose was the side commit, which did touch `001-f.md`.

**Evidence:** `scripts/dev-cycle.sh:221-236`, `fc19/logs/probe-a.log`

---

## Claim 6a: "Fall back only for a tracked record (an index lookup, no history walk)"

**Location:** `scripts/dev-cycle.sh:231-236`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the untracked case (no `git log`) and the tracked case (one `git log -1`); does not establish cost for a record that is staged but never committed, which is "tracked" and still walks the whole history.

```bash
# scripts/dev-cycle.sh:234-236
  if [[ -z "${last_date[$f]+set}" ]] && git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    d="$(git log -1 --format=%ad --date=short -- "$f")"
  fi
```
In E5, `003-untracked.md` gets only the `ls-files` call. `004-staged.md` (in the index, never committed) gets the `git log -1` walk and prints "never, uncommitted" (`fc19/logs/probe-c.log`). `GIT_LITERAL_PATHSPECS=1` is exported at `:128`, so `ls-files` takes the name literally.

**Evidence:** `scripts/dev-cycle.sh:128`, `scripts/dev-cycle.sh:225-240`, `fc19/logs/probe-c.log`

---

## Claim 6b: "an untracked one was never committed here"

**Location:** `scripts/dev-cycle.sh:232`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers a record removed from the index but still in the worktree and in history; does not establish how often that happens (it needs a name that git quotes, since a plain name is found in the map).

E3 P1 commits `001-a"b.md` and `002-plain.md`, then runs `git rm --cached` on both:

```
per-file git log -1: 2026-02-01
ls-files --error-unmatch exit: 1
### docs/decisions/001-a"b.md (last committed on this branch: never, uncommitted)
### docs/decisions/002-plain.md (last committed on this branch: 2026-02-01)
```
(`fc19/logs/probe-a.log`). An untracked record can have been committed on this branch. For a quoted name, the digest then prints "never, uncommitted" where per-file `git log` has a date. The precise version: "an untracked record is not looked up; a quoted name that was committed and then removed from the index shows as never committed". This is a low-impact edge case: it needs a quoted name plus `git rm --cached`.

**Evidence:** `scripts/dev-cycle.sh:231-238`, `fc19/logs/probe-a.log`

---

## Claim 6c: "a full walk to prove it cost ~1 s per record on a 220k-commit repo" (commit 1b0c4ff adds: "150 of them passed the 120 s Bash default")

**Location:** `scripts/dev-cycle.sh:232-233`, commit `1b0c4ff` body
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the arithmetic (150 × ~1 s ≈ 150 s > 120 s) and the mechanism (Claim 6a); does not establish the ~1 s figure.

The figure needs a repo with about 220k commits, and none was available in the sandbox. Paraphrased — no quote available because the claim covers the absence of a check: no measurement is cited in the diff, so the figure presumably comes from the pass-18 performance review. The removal of the walk for untracked records is verified in Claim 6a.

**Evidence:** `scripts/dev-cycle.sh:231-236`, `fc19/logs/probe-c.log`

---

## Claim 7: "their own scratch output (the health-check log, the kept digest) goes to the usual temp directory"

**Location:** `skills/dev-cycle/SKILL.md:62-63`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with steps 0 and 1; does not establish where a subagent writes its own scratch files.

Step 0 says only "Keep its output" (`skills/dev-cycle/SKILL.md:110-111`), and step 1 says "run the repo's health check ... to a file" (`:134-135`). Neither names a repo path, so the new sentence fills the gap without contradicting either step.

**Evidence:** `skills/dev-cycle/SKILL.md:61-63`, `skills/dev-cycle/SKILL.md:104-137`

---

## Claim 8: "steps 2, 3, 4, 5 and 6 read these"

**Location:** `skills/dev-cycle/SKILL.md:63-65`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers which steps take paths from repo text; does not establish that step 4b reads none (it reads digest section 7 lists, which are names, not opened paths).

Step 2 reads records "read the record itself then" (`:157-158`). Step 3 acts on questions (`:168-179`). Step 4 reads files a commit message, log row or plan names (`:183-186`). Step 5 reads "the idea sources `docs/dev-cycle.md` lists" (`:219-220`). Step 6 reads brief paths from In flight (`:245-253`).

**Evidence:** `skills/dev-cycle/SKILL.md:153-284`

---

## Claim 9: "(a settings row and its glob matches ...) is opened only if all of these hold, checked in this order: 1. it uses only letters, digits, `.`, `_`, `-` and `/` ... 2. `git ls-files --error-unmatch -- '<path>'` accepts it ... (expand a glob first, with the same check on each match); 3. no part of it below the repo root is a symlink"

**Location:** `skills/dev-cycle/SKILL.md:63-72`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the order as written, applied to a settings glob row; does not establish how an agent would resolve the ambiguity in practice. It also does not cover non-glob paths, which the rule handles as stated (Claims 11-13).

The rule names "a settings row and its glob matches" as inputs and puts "expand a glob first" inside check 2. Read in the stated order, check 1 runs on the row itself, and a glob contains `*`, which check 1 rejects. E4 confirms this for the repo's only row (`docs/working/feature-ideas*.md : check1=fail`, `fc19/logs/probe-b.log`). So the rule as ordered admits no glob row, while the settings format is "Path or glob" (`skills/dev-cycle/SKILL.md:52`) and the one row is a glob.

The other reading, expanding first and then running checks 1-3 on each match, works, but the text no longer says to expand only inside directories that pass the symlink check. The removed clause read "expand a glob only inside a directory that passes the same check" (db24c74's `skills/dev-cycle/SKILL.md:71-72`, in the diff). Under that reading, expansion lists a symlinked directory's contents before check 3 runs.

The precise version: "1. the pattern, ignoring `*`, `?` and `[]`, passes check 1; expand it only inside directories that pass check 3; then apply checks 1-3 to each match".

**Evidence:** `skills/dev-cycle/SKILL.md:50-54`, `skills/dev-cycle/SKILL.md:61-81`, `fc19/logs/probe-b.log`

---

## Claim 10: "`git ls-files --error-unmatch -- '<path>'` accepts it, so it is a tracked file"

**Location:** `skills/dev-cycle/SKILL.md:70-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers what the command accepts; does not establish any harm (a directory that passes is not a file to open, so the next read fails safely).

E4: `docs/decisions : check1=pass ls-files-exit=0` and `. : check1=pass ls-files-exit=0` (`fc19/logs/probe-b.log`). The command accepts any pathspec that matches a tracked file, including a directory that holds one. It also accepts an index entry whose file is missing from the worktree. The precise version: "is, or contains, a tracked file".

**Evidence:** `skills/dev-cycle/SKILL.md:70-71`, `fc19/logs/probe-b.log`

---

## Claim 11: "no component starting with `.git` (any case)" closes `.git` and its case variants

**Location:** `skills/dev-cycle/SKILL.md:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers `.git`, `.GIT` and any `.git*` component; does not establish that nothing the cycle needs is blocked: tracked `.gitignore` and `.gitattributes` (and any `.github/` path) are rejected too, so step 4 cannot open them when a merge's claim rests on them.

E4: `.GIT/config : check1=fail`, `.github/x : check1=fail`, `.gitignore : check1=fail ls-files-exit=0` (`fc19/logs/probe-b.log`). This repo tracks two such files (`git ls-files | grep -ic '^\.git'` printed 2).

**Evidence:** `skills/dev-cycle/SKILL.md:68-69`, `fc19/logs/probe-b.log`

---

## Claim 12: "Quote such a path in single quotes in every command."

**Location:** `skills/dev-cycle/SKILL.md:74`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers paths that passed check 1; does not establish quoting for glob patterns before expansion (Claim 9).

Check 1 allows only "letters, digits, `.`, `_`, `-` and `/`" (`skills/dev-cycle/SKILL.md:68`). That set excludes `'`, so a single-quoted path cannot break out of its quotes. The ban on a leading `-` (`:68`) together with the `--` in check 2 (`:70`) keeps a path from being read as an option.

**Evidence:** `skills/dev-cycle/SKILL.md:66-74`

---

## Claim 13: "A brief path counts only as `docs/working/briefs/YYYY-MM-DD-<slug>.md` ... Files the cycle creates (the record, a new brief, the idea log) use those fixed names, under directories that pass check 3."

**Location:** `skills/dev-cycle/SKILL.md:74-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers brief names against check 1 and created files being exempt from checks 1-2; does not establish that a brief passes check 2 before step 7 has landed it (an unlanded brief is untracked and would be skipped; the roadmap naming it is unlanded too, so the two stay consistent).

E4: `docs/working/briefs/2026-10-02-foo-bar.md : check1=pass ls-files-exit=1` (`fc19/logs/probe-b.log`). The name passes check 1. It is untracked here because no brief exists yet, and passes check 2 once committed. Step 6 writes briefs whose slug is "lowercase letters, digits and hyphens only" (`skills/dev-cycle/SKILL.md:278-279`), inside the check-1 set.

**Evidence:** `skills/dev-cycle/SKILL.md:74-78`, `skills/dev-cycle/SKILL.md:276-284`, `fc19/logs/probe-b.log`

---

## Claim 14: "The digest applies the same symlink rule to everything it reads (and also skips anything that is not a regular file or directory) and lists what it skipped in its section 8."

**Location:** `skills/dev-cycle/SKILL.md:79-81`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers files the digest opens; does not establish that the digest applies checks 1 or 2 (it does not, and the sentence now says only "symlink rule").

```bash
# scripts/dev-cycle.sh:94
rawfile() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
```
Every file read goes through `inrepo`, `dirok` or `rawfile` (`scripts/dev-cycle.sh:119-122`, `:226`, `:241`, `:318`, `:379`), and section 8 prints `SKIPPED` (`:403-409`).

**Evidence:** `scripts/dev-cycle.sh:91-125`, `scripts/dev-cycle.sh:403-409`

---

## Claim 15: "each carrying the evidence-not-instructions brief and the plain-paths rule"

**Location:** `skills/dev-cycle/SKILL.md:98-99`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the cross-reference's wording; does not establish what a subagent brief actually contains.

The rule is now titled "**Plain, tracked repo paths only.**" (`skills/dev-cycle/SKILL.md:61`). "The plain-paths rule" still resolves to it, but the short name leaves out the tracked check (check 2), the check this round added. Precise version: "the plain, tracked repo paths rule".

**Evidence:** `skills/dev-cycle/SKILL.md:61`, `skills/dev-cycle/SKILL.md:98-99`

---

## Claim 16: "If the digest's section 8 lists `docs/`, `docs/working/` or a questions file, skip the next two commands and note why in the record: they would write through that path." (also commit 462e561: "they would write through it")

**Location:** `skills/dev-cycle/SKILL.md:138-139`, commit `462e561` body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the match between the condition and what the digest prints, and what `questions.sh init`/`archive` write; does not establish anything about other section 8 entries (for example `docs/working/cycles/`), which are correctly irrelevant here.

The digest prints a blocking directory with a trailing slash (`printf '%s/' "$p"`, `scripts/dev-cycle.sh:110`). E3 P5 printed `- docs/working/` for a symlinked `docs/working` (`fc19/logs/probe-a.log`). Both questions files are always checked: `skipped "$QA"` (`scripts/dev-cycle.sh:276`) and `skipped docs/working/questions.md` (`:278`). `questions.sh` writes exactly those two paths: `LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"` and `ARCHIVE=...questions-archive.md` (`scripts/questions.sh:85-86`).

**Evidence:** `skills/dev-cycle/SKILL.md:138-143`, `scripts/dev-cycle.sh:105-115`, `scripts/dev-cycle.sh:271-285`, `scripts/questions.sh:85-86`, `fc19/logs/probe-a.log`

---

## Claim 17: "In flight: items with an open build brief, each naming its brief path" / "Move the item to In flight, naming the brief's path."

**Location:** `skills/dev-cycle/SKILL.md:245`, `skills/dev-cycle/SKILL.md:283`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with the brief-path form at `:74-76`; does not establish that "naming" forces the backtick form (only the rule paragraph says so).

Both lines now say "naming", which matches "written in the roadmap as that repo-root path in backticks" (`skills/dev-cycle/SKILL.md:75-76`). This closes pass 18's Claim 8.

**Evidence:** `skills/dev-cycle/SKILL.md:74-76`, `:245`, `:283`

---

## Claim 18a: "read the option the user chose: the first `[1]` or `[2]` in their answer (as in `Q-NNN: [1]`)"

**Location:** `skills/dev-cycle/SKILL.md:253-255`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers bracketed answers (`Q-012: [2]` → drop; `[1] keep, it's close` → keep); does not establish answers that mention both brackets (the first one wins).

The bracket search ignores a `Q-NNN:` prefix, so both realistic bracketed forms give the option the user wrote (`skills/dev-cycle/SKILL.md:254-256`).

**Evidence:** `skills/dev-cycle/SKILL.md:249-259`

---

## Claim 18b: "or, if there is none, its first word when that is exactly `1`, `keep`, `2` or `drop` (any case)" (as a reading of "the option the user chose")

**Location:** `skills/dev-cycle/SKILL.md:253-257`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers free-text answers with no bracket; does not establish how often users answer in free text (the global grammar invites `Q-NNN: [2]`).

The free-text answer `2 more weeks` has no bracket, and its first word is exactly `2`. So "`[2]`, `2` or `drop` closes the brief" (`skills/dev-cycle/SKILL.md:256-257`) closes a brief whose owner asked to keep it two more weeks. The rule then reads an option the user did not choose.

A second problem is wording. The example frames the answer as `Q-NNN: [1]`, prefix included. Under that framing, `Q-012: keep` has first word `Q-012:` and is "unrecognized", the safe failure. The text does not say whether the `Q-NNN:` prefix is part of "their answer".

**Evidence:** `skills/dev-cycle/SKILL.md:249-259`

---

## Claim 18c: "anything else is unrecognized: list it in the record and the final message so the user can answer again."

**Location:** `skills/dev-cycle/SKILL.md:257-258`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers where a second answer is read; does not establish the timing in a repo where the branch gained commits (then no new entry is filed).

The same item also says "In every case add the ID to `Applied:`, so each answer is read once" (`:258-259`). A second answer on the same entry is therefore never read. The user can answer again only on the new entry step 3 files: Kept is unchanged and no `Asked:` ID is unanswered, so `:260-266` fires the same cycle. The precise version: "so the user can answer the new keep-or-drop entry".

**Evidence:** `skills/dev-cycle/SKILL.md:249-266`

---

## Claim 18d: "in ascending ID order ... In every case add the ID to `Applied:`, so each answer is read once." (commit 462e561: "every read answer goes on Applied:, so none is re-read forever")

**Location:** `skills/dev-cycle/SKILL.md:253`, `skills/dev-cycle/SKILL.md:258-259`, commit `462e561` body
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the termination of re-reading (closes pass 18's Claim 16 loop); does not establish numeric versus lexical order past Q-999.

The ID goes on `Applied:` whether the answer was recognized or not, and only IDs "not yet on its `Applied:` line" are read (`skills/dev-cycle/SKILL.md:252-253`).

**Evidence:** `skills/dev-cycle/SKILL.md:249-259`

---

## Claim 19: "slug `keep-or-drop-<brief file name without .md>-<n>` (n = how many it has been asked)" (commit 462e561: "so it is unique")

**Location:** `skills/dev-cycle/SKILL.md:263-264`, commit `462e561` body
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers uniqueness across briefs and asks; does not establish whether n counts this ask (either count is unique if used consistently, since `Asked:` lists every prior ID).

Brief paths are never reused ("a path no brief has used before; add `-2`, `-3` if it is taken", `skills/dev-cycle/SKILL.md:279-280`), and n increases with each ask (`:263-265`).

**Evidence:** `skills/dev-cycle/SKILL.md:260-266`, `skills/dev-cycle/SKILL.md:276-284`

---

## Claim 20: Test "record dates match per-file git log for quoted names and a merge-resolution change", which "adds an uncommitted record" (commit 1b0c4ff)

**Location:** `test/scripts/dev-cycle.bats:243-262`, commit `1b0c4ff` body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the name and the added assertion; does not establish that the test pins this round's fix: it passes against the pre-fix script (E2), because the old code also printed "never, uncommitted" after its full walk.

```bash
# test/scripts/dev-cycle.bats:256-258
    printf '# x\n\n## Revisit triggers\nif y.\n' > docs/decisions/005-uncommitted.md
    run --separate-stderr bash "$DC" --since=2000-01-01
    [[ "$output" == *"005-uncommitted.md (last committed on this branch: never, uncommitted)"* ]] || ...
```
(excerpt ends :258; the test continues to :262 with the per-file loop over `00[1-4]*` — read). E1 passes. E2 also passes (`ok 1 record dates match ...`, `fc19/logs/bats-newtest-oldscript.log`; ran 2026-10-02T08:37:41Z, exit 0).

**Evidence:** `test/scripts/dev-cycle.bats:243-262`, `fc19/logs/bats-digest.log`, `fc19/logs/bats-newtest-oldscript.log`

---

## Claim 21: "24/24; shellcheck clean." (commit 1b0c4ff)

**Location:** commit `1b0c4ff` body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the bats file and shellcheck on `scripts/dev-cycle.sh` at 1b0c4ff (HEAD has no script/test diff); does not establish the repo-wide health check (stated as passing at 6c35818 in the brief, not rerun here).

E1 ran `timeout 300 bats test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` at 08:37:24Z: exit 0, 24 `ok` lines. `timeout 60 shellcheck scripts/dev-cycle.sh` ran at 08:39:14Z: exit 0, 0 bytes of output.

**Evidence:** `fc19/logs/bats-digest.log`, `fc19/logs/shellcheck.log`

---

## Claim 22: "This closes glob-expands-to-.git, case variants, untracked secret files and shell-quoting injection as one class." (commit 462e561)

**Location:** commit `462e561` body; `skills/dev-cycle/SKILL.md:66-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each named case under either reading of the check order; does not establish that globs remain usable (Claim 9) or that symlinked directories are never listed during expansion (Claim 9's second reading).

`.git` in any case fails check 1 (Claim 11). Untracked files fail check 2 (`docs/working/briefs/...: ls-files-exit=1`, `fc19/logs/probe-b.log`). Quotes are outside the character set (Claim 12). A glob match into `.git` fails check 1 under the expand-first reading. Under the literal order the glob fails check 1 outright.

**Evidence:** `skills/dev-cycle/SKILL.md:66-74`, `fc19/logs/probe-b.log`

---

## Claim 23: "\"tracked only\" means an untracked idea source is skipped; the default source here (docs/working/feature-ideas.md) is tracked." (commit 462e561 Notes)

**Location:** commit `462e561` body; `docs/dev-cycle.md:33`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the tracked status of the file; does not establish that the configured source passes the rule (it is the glob `docs/working/feature-ideas*.md`, rejected by check 1 as written, Claim 1b).

`git ls-files` lists `docs/working/feature-ideas.md`, and E4 shows `ls-files-exit=0` for it. The settings row, though, is `docs/working/feature-ideas*.md` (`docs/dev-cycle.md:33`), not the file. The precise version should name the glob and its one current match.

**Evidence:** `docs/dev-cycle.md:33`, `fc19/logs/probe-b.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`docs/dev-cycle.md:27-33`): **behavioral.** The stated character set excludes `*`, yet the file's only row is the glob `docs/working/feature-ideas*.md`. Under the skill's check order the repo's idea source is skipped.
- **Claim 6b** (`scripts/dev-cycle.sh:232`): **behavioral, low impact.** "An untracked one was never committed here" fails for a quoted name that was committed and then removed from the index. The digest prints "never, uncommitted" where per-file `git log` gives 2026-02-01 (E3 P1).
- **Claim 9** (`skills/dev-cycle/SKILL.md:63-72`): **behavioral.** Check 1 comes before "expand a glob first" (inside check 2), so every glob settings row fails check 1. The alternative reading (expand first) lost the old "expand only inside a directory that passes the symlink check" clause.
- **Claim 18b** (`skills/dev-cycle/SKILL.md:253-257`): **behavioral.** The first-word fallback reads `2 more weeks` as drop. **Wording**: it is unclear whether the `Q-NNN:` prefix counts as the first word, which makes `Q-012: keep` unrecognized.

### Stale
- None.

### Mostly Accurate
- **Claim 1a** (`docs/dev-cycle.md:27-29`): **wording.** Says "no `.git` component"; the skill bans any component starting with `.git` in any case, and a leading `-`.
- **Claim 10** (`skills/dev-cycle/SKILL.md:70-71`): **wording.** `ls-files --error-unmatch` also accepts a tracked directory or `.`, so the precise version is "is or contains a tracked file".
- **Claim 15** (`skills/dev-cycle/SKILL.md:99`): **wording.** "The plain-paths rule" is the old short name; the rule is now "Plain, tracked repo paths only".
- **Claim 18c** (`skills/dev-cycle/SKILL.md:257-258`): **wording.** "So the user can answer again" should say "on the new keep-or-drop entry": a re-answer on the applied entry is never read.
- **Claim 23** (commit `462e561` Notes): **wording.** Names the matched file, not the configured glob row, which check 1 rejects.

### Unverifiable
- **Claim 6c** (`scripts/dev-cycle.sh:232-233`, commit `1b0c4ff`): the ~1 s per record on a 220k-commit repo needs such a repo. The mechanism (no walk for untracked records) is verified in 6a.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass19.md`. It has the required first line, the header fields (including `**Replication:** k=1 (loop pass, decision 031)`), the seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary.

Against the round's aims:
- **A, tracked-only fallback:** it works as intended. Quoted tracked names still get their date, and untracked records no longer walk history (E5). The comment's justification is wrong in one edge case (6b). The new test assertion does not pin the fix: it passes on the pre-fix script (Claim 20).
- **A, date-map comment:** the general rule holds in both directions (E3 P2/P3).
- **A, skipped-record date check:** correct (E3 P4).
- **B, path rule:** it closes the named classes (Claim 22). As ordered, though, it blocks the one thing the settings file configures, a glob row (Claims 1b, 9). It also blocks tracked `.gitignore` and `.gitattributes`, which step 4 might need (Claim 11's residue). Brief paths and cycle-created files are compatible (Claim 13).
- **B, step 1 skip:** matches what the digest prints (Claim 16).
- **B, answer parsing:** right for bracketed answers. Free-text answers starting with `2` are misread as drop (18b).
- **B, slug and naming:** both hold (Claims 17, 19).
