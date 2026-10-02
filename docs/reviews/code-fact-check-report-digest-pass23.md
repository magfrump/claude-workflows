Commit: ba39470 (A) / 36ca12c (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at ba39470; HEAD ca8ba77 adds review docs only). B: `/workspace/.claude/wt-devcycle` (content at 36ca12c; HEAD f2843cd merges A in, and `git show f2843cd:scripts/dev-cycle.sh` is byte-identical to `ba39470:scripts/dev-cycle.sh`, checked with `cmp`).
**Scope:** Partial: the pass-22 fix round only. A: `git diff bc98571..ba39470 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of 2008343 and ba39470. B: `git diff 6c8ae91..36ca12c -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` plus the messages of 6db3d8a and 36ca12c. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 38
**Summary:** 26 verified, 8 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. No claim below matches a logged pattern. None of the three Incorrect verdicts is a fabricated symbol, API or flag: each is a real mechanism that is described too broadly. So nothing is appended to the log.

**Probe discipline.** Every probe was one script. Each started with `set -eu`, created its own `mktemp -d` dir under `fc23/` in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. Every process ran under `timeout`, and none is still running. The probes read the code under review with `git -C <worktree> archive <commit> | tar -x` into the temp dir and ran it from there. Apart from this report, nothing was written to `/workspace` or to either worktree. After the probes, `/workspace` was still at bf54363 with only the session-start untracked files, and `git status --short` was empty in both worktrees.

Execution logs are scratch and are not committed. They are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc23/` (below, `fc23/`). The environment's default `LC_ALL=en_US.UTF-8` is not installed, so the probes set `LC_ALL=C.utf8`. Only mawk is installed (`/usr/bin/awk -> /etc/alternatives/awk -> /usr/bin/mawk`; no gawk or busybox), so the awk program ran under mawk only. Its gawk portability is checked statically.

Executed runs (UTC; all exit 0):
- E1–E3, 15:57:08Z, `timeout 600 bash fc23/probe1.sh` (cwd `fc23/`) → `fc23/probe1.log`. Inside its temp copy of `ba39470:scripts` and `test`, it ran:
  - `bats test/scripts/dev-cycle.bats`: 33/33 ok → `fc23/bats.log`.
  - `shellcheck scripts/dev-cycle.sh`: empty output → `fc23/shellcheck.log`.
  - `--help` → `fc23/help.log`.
- E4, same run: `--check-answer` with every `### Q-NNN` ID in copies of wt-devcycle's `docs/working/questions-archive.md` and `questions.md` (102 IDs) → `fc23/answers.log`. `fc23/entries.py` lists each entry's status and its answer-looking lines, for comparison by eye → `fc23/entries.log`. The questions files are a time-varying input; the results hold for wt-devcycle's working tree as of 15:57Z.
- E5–E9, same run: `--check-fix` scope, `--check-branch` with a tag at `refs/tags/refs/heads/feat/ghost`, a default-branch probe, 15 answer edge cases, and whether a fresh branch is an ancestor.
- P1–P6, 15:59:20Z, `timeout 300 bash fc23/probe2.sh` (cwd `fc23/`) → `fc23/probe2.log`. It covers:
  - the default-branch lookup with a tag named `refs/heads/main`;
  - notes that flip a label-only-bold answer;
  - a symlinked `questions.md`;
  - brief listing when untracked, staged, or under an ignored `docs/working/`;
  - a plain path that names an ignored directory;
  - 51 tracked briefs.

Legibility-target values:
- **agent**: the model running the skill or digest acts on the text.
- **maintainer**: someone editing the script or tests.
- **user**: the human reading the digest, record or commit log.

---

## Claim 1: "Each row is passed to `~/.claude/scripts/dev-cycle.sh --check-path` (in claude-workflows itself, `scripts/dev-cycle.sh`)"

**Location:** `docs/dev-cycle.md:27-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers which script copy the settings doc names for this repo. It does not establish that step 5 actually passes each row, which is skill behaviour and not in this diff.

The doc now says `(in claude-workflows itself, \`scripts/dev-cycle.sh\`)` (`docs/dev-cycle.md:27-28`). That matches the skill's `(inside claude-workflows, its own \`scripts/dev-cycle.sh\`)` (`skills/dev-cycle/SKILL.md:65`), and the script exists at `scripts/dev-cycle.sh` in both worktrees. This closes pass-22 Claim 1a.

**Evidence:** `docs/dev-cycle.md:27-28`, `skills/dev-cycle/SKILL.md:64-65`

---

## Claim 2: usage lines `scripts/dev-cycle.sh --check-fix PATH...` / `--check-answer Q-NNN...`, and the option list

**Location:** `scripts/dev-cycle.sh:13-14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that both modes are parsed and dispatched. It does not establish what each mode decides (Claims 5, 6, 12–14).

`--check-path|--check-write|--check-brief|--check-branch|--check-fix|--check-answer)` (`scripts/dev-cycle.sh:107`) sets `CHECK`. The dispatch has `--check-fix) check_fix "$a" ;;` and `--check-answer) check_answer "$a" ;;` (`:305-306`). E5 and E8 ran both modes with several arguments each, and every argument got one line.

**Evidence:** `scripts/dev-cycle.sh:13-14`, `:107-110`, `:298-310`; `fc23/probe1.log` (E5, E8)

---

## Claim 3: "--check-write  the same for one of the cycle's own bookkeeping files (…); the file need not exist yet. --check-brief  … a roadmap brief path must also pass --check-path (which needs the file to exist)."

**Location:** `scripts/dev-cycle.sh:26-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers existence: `check_write` does not require it, and `check_path` reports a missing file as a skip. It does not establish the write list itself, which pass 22 verified and this round did not change.

`check_write` tests only the form, `isbrief`, `writable` and `blocker` (`:226-231`). `blocker` returns empty for an absent path (`[[ -e "$p" || -L "$p" ]] || return 0`, `:139`), so an absent file passes. `check_path` with no match prints `skip $a: no tracked file (or ignored file under docs/working/) matches` (`:213`). P4 showed that for a brief glob with no tracked match.

**Evidence:** `scripts/dev-cycle.sh:26-31`, `:135-145`, `:199-214`, `:225-232`; `fc23/probe2.log` (P4)

---

## Claim 4: "--check-branch  "ok <name> <hash>" (or "ok <name> absent") for a branch name from a brief: letters, digits, . _ - / only, not starting with -, a valid ref name; the hash is refs/heads/<name>'s, so a tag of the same name never stands in for it. Give git the hash."

**Location:** `scripts/dev-cycle.sh:32-35`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the output shape, the hash source and the refusal list. It does not establish what the hash is used for downstream (Claim 21).

The output shape and the hash are right. E6 printed `ok feat/real 9a60bf1…` and `ok feat/ghost absent`, while a tag `refs/tags/refs/heads/feat/ghost` existed. The refusal list in the help is incomplete. The code also requires `git check-ref-format --branch "$a"` and refuses `HEAD` and `refs/*`:

```bash
# scripts/dev-cycle.sh:239-240
  elif ! git check-ref-format "refs/heads/$a" || ! git check-ref-format --branch "$a" >/dev/null 2>&1 \
    || [[ "$a" == HEAD || "$a" == refs/* ]]; then echo "skip $a: not a valid branch name"
```

(excerpt ends :240; enclosing `check_branch()` continues to :245 — read)

E6 printed `skip HEAD: not a valid branch name` and `skip refs/heads/x: not a valid branch name`. Precise version: "…a valid branch name (not `HEAD`, not under `refs/`)". Wording only.

**Evidence:** `scripts/dev-cycle.sh:32-35`, `:236-245`; `fc23/probe1.log` (E6)

---

## Claim 5: "--check-fix  "ok <path>" for an existing file an in-cycle fix may edit: one --check-path allows, under docs/ or README.md."

**Location:** `scripts/dev-cycle.sh:36-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the location gate and the delegation to `check_path`. It does not establish that everything under `docs/` is documentation (Claim 12). `README.md` means the root file only.

```bash
# scripts/dev-cycle.sh:248-253
check_fix() {
  local a="$1"
  if ! pathform "$a" || [[ "$a" == *[*?]* ]]; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ ! "$a" =~ ^docs/|^README\.md$ ]]; then echo "skip $a: in-cycle fixes edit only docs/ and README.md; file it instead"
  else check_path "$a"; fi
}
```

E5 results:
- `ok docs/README.md`, `ok docs/working/questions.md`.
- `skip sub/README.md: in-cycle fixes edit only docs/ and README.md`.
- `skip README.md: no tracked file …`: there was no root README in that repo, so the existence check applies.

The bats test covers `docs/new.md` (absent), a glob, and `docs` itself.

**Evidence:** `scripts/dev-cycle.sh:36-37`, `:248-253`; `fc23/probe1.log` (E5); `fc23/bats.log` (test 32)

---

## Claim 6: "--check-answer  "keep|drop|open|unrecognized Q-NNN" for a keep-or-drop question, read from docs/working/questions.md or its archive."

**Location:** `scripts/dev-cycle.sh:38-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the output vocabulary and the two files, read in order. It does not establish the parsing rule (Claim 13) or what the skip reason says when a file is not plain (Claim 14). Besides the four words, the mode can also print `skip` lines.

`check_answer` loops `for f in docs/working/questions.md docs/working/questions-archive.md` and prints `"$r $a"` from the first file with a non-empty result (`:291-295`). On the real files (E4), the 13 `open` results came from `questions.md`, and every keep, drop and unrecognized result came from the archive.

**Evidence:** `scripts/dev-cycle.sh:38-39`, `:288-297`; `fc23/answers.log`, `fc23/entries.log`

---

## Claim 7: `echo "$CHECK needs at least one argument"`

**Location:** `scripts/dev-cycle.sh:109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the empty-argument error for all six modes. It does not establish the wording of other usage errors.

`[[ ${#CHECK_ARGS[@]} -gt 0 ]] || { echo "$CHECK needs at least one argument" >&2; exit 1; }` (`:109`). Test 31 runs `--check-branch` with no arguments and asserts status 1 and that stderr contains "needs at least one argument". It passed in E1. This closes pass-22 Claim 4.

**Evidence:** `scripts/dev-cycle.sh:109`; `test/scripts/dev-cycle.bats:579-581`; `fc23/bats.log`

---

## Claim 8: help range `sed -n '2,48p'`

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the range spans the whole header comment at ba39470. It does not establish that it stays aligned after later header edits.

Line 47 is the last header line (`# or no perl; a failed step exits non-zero mid-digest. Printed repo text is data.`), and line 48 is blank. Line 49 is `set -euo pipefail`. E3's help output starts with "Gather the mechanical signals…" and ends with that Exit sentence plus one empty line. So nothing is cut and no code is printed.

**Evidence:** `scripts/dev-cycle.sh:1-49`, `:111`; `fc23/help.log`

---

## Claim 9: "Every grep here runs in the C locale (set through env, which bash does not apply to its own locale), so a name that is not UTF-8 still passes, to be skipped by the form check." / `exact()`: "a plain path keeps only itself (not a directory's contents)"

**Location:** `scripts/dev-cycle.sh:183-198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers both listings in `matches()`: tracked files and ignored files under `docs/working/`. It does not establish behaviour for a non-UTF-8 name in a tracked listing; the test covers only the ignored listing.

```bash
# scripts/dev-cycle.sh:186-197
exact() {  # $1 the argument: a plain path keeps only itself (not a directory's contents)
  if [[ "$1" == *[*?]* ]]; then cat; else env LC_ALL=C grep -zxF -- "$1" || true; fi
}
matches() {  # …
  local fixed="${2%%[*?]*}"
  GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1" | exact "$2"
  …
    GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
      | { env LC_ALL=C grep -z '^docs/working/' || true; } | exact "$2"
```

(excerpt ends :197; enclosing `matches()` continues to :198 — read)

Both greps run under `env LC_ALL=C`.
- P5: `--check-path docs/working/rdir`, an ignored directory holding `x.md`, printed only `skip docs/working/rdir: a directory, not a file`.
- Test 30 ("reports an ignored docs/working name that is not UTF-8") passed in E1.

This closes pass-22 Claim 9.

**Evidence:** `scripts/dev-cycle.sh:183-198`; `fc23/probe2.log` (P5); `fc23/bats.log`

---

## Claim 10: "The cycle's own bookkeeping files (in-cycle fixes to other files go through --check-path instead)"

**Location:** `scripts/dev-cycle.sh:215-216`
**Type:** Staleness / Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the parenthetical only. The rest of the comment (refusing other paths) stays correct.

This round added `check_fix()` (`:248-253`). The skill now says an in-cycle fix "edits only a file that `--check-fix '<path>'` prints `ok` for" (`skills/dev-cycle/SKILL.md:71-72`). The comment still names `--check-path`. The precise version is "(in-cycle fixes to other files go through `--check-fix` instead)". Wording, maintainer-facing; pass 22 verified this line before `--check-fix` existed.

**Evidence:** `scripts/dev-cycle.sh:215-218`, `:246-253`; `skills/dev-cycle/SKILL.md:71-72`

---

## Claim 11: "A brief's branch reaches git only as the hash show-ref finds at exactly refs/heads/<name>: never as an option, and never as a tag of the same name (git's own name lookup falls back to refs/tags/refs/heads/<name>)."

**Location:** `scripts/dev-cycle.sh:233-235`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `check_branch`'s output and the lookup fallback it guards against. It does not establish that every skill step hands git only that hash (Claim 18). Inside the check itself, the name reaches `check-ref-format` and `show-ref` as the string `refs/heads/$a`, after the character check.

`sha="$(git show-ref --verify --hash "refs/heads/$a" 2>/dev/null || true)"; echo "ok $a ${sha:-absent}"` (`:242-243`). In E6, with only the tag `refs/tags/refs/heads/feat/ghost`:
- the script printed `ok feat/ghost absent`;
- `git rev-parse --verify 'refs/heads/feat/ghost^{commit}'` returned the tag's commit.

That confirms the fallback the comment describes. A name starting with `-` is refused before any git call (`:238`).

**Evidence:** `scripts/dev-cycle.sh:233-245`; `fc23/probe1.log` (E6)

---

## Claim 12: "An in-cycle fix edits documentation only: anything else (scripts, hooks, egress lists, instruction files) is filed, never changed by the cycle itself."

**Location:** `scripts/dev-cycle.sh:246-247`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers what the gate admits. It does not establish whether editing non-doc files under `docs/` matters in practice; nothing found executes them.

The gate is by location, not by file type: `[[ ! "$a" =~ ^docs/|^README\.md$ ]]` (`:251`). E5 printed `ok docs/human-author/prompts.ts` and `ok docs/reviews/execution-logs/p.sh`. In this repo, `git ls-files docs | grep -v '\.md$'` lists:
- `docs/human-author/prompts.ts` and `property-tests.json`;
- the user's `answers-*.txt` files;
- `.py` and `.sh` probes under `docs/reviews/execution-logs/`.

(paraphrased — no quote available because the claim is about a file listing, not a snippet.)

So a "script" under `docs/` is editable in-cycle. Hooks, egress lists and root instruction files (`AGENTS.md`) are refused, as the comment says. The test refuses `hooks/x.sh`, `egress/x.txt` and `AGENTS.md`. Precise version: "edits only existing files under docs/ (of any type) or the root README.md". Behavioral residue low: the non-doc files found under `docs/` are records and probes, not anything installed or run.

**Evidence:** `scripts/dev-cycle.sh:246-253`; `fc23/probe1.log` (E5); `test/scripts/dev-cycle.bats:584-596`

---

## Claim 13a: "prints keep, drop, open (no answer line and not marked ANSWERED) or unrecognized, and nothing when the file has no such entry"

**Location:** `scripts/dev-cycle.sh:254-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the END rule and entry matching, including prefix IDs. It does not establish IDs written with different zero-padding: `Q-0100` does not find `### Q-100` and gets a skip.

`END { if (found) print (done ? result : answered ? "unrecognized" : "open") }` (`:287`). Entry start: `$0 == "### " id || index($0, "### " id " ") == 1` (`:273`). That rule needs a space or end-of-line after the ID, so `Q-10` never enters `### Q-100`.

In E8:
- `Q-10` (OPEN, no answer line) printed `open Q-10`.
- `Q-100: [2]` printed `drop Q-100`.
- `Q-0100` printed the skip.

On the real files (E4), all 13 `open` results are `**Status:** OPEN` entries in `questions.md` (`fc23/entries.log`). The answer-line test `index(line, id ":") == 1` (`:278`) has the same prefix safety: `Q-10:` is not a prefix of `Q-100:`.

**Evidence:** `scripts/dev-cycle.sh:263-287`; `fc23/probe1.log` (E4, E8); `fc23/entries.log`

---

## Claim 13b: "The answer is the first line in the entry that starts with "Q-NNN:" or with a bold "**Answer" / "**Answered" label (any case, after an optional "- ")"

**Location:** `scripts/dev-cycle.sh:256-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers label recognition and the first-line rule. It does not establish entry boundaries other than the next `##…` line: an in-entry `#### ` subheading ends the entry. Nor does it cover a `* ` bullet prefix, which is not stripped.

```awk
# scripts/dev-cycle.sh:274-280
inside && /^##/ { inside = 0 }
inside && tolower($0) ~ /\*\*status:\*\* *answered/ { answered = 1 }
inside && !done {
  line = $0; sub(/^[ \t]*(- )?/, "", line)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
  label = tolower(substr(line, 1, 10))
  if (label !~ /^\*\*answer([^a-z]|ed)/) next
```

(excerpt ends :280; the enclosing rule continues to :286 — read)

The regex admits `**answer` followed by a non-letter, or `**answered`. It refuses `**Answering`, which E8 and test Q-007 read as `unrecognized`, never as an answer. Two residue cases from E8, both conservative:
- Q-104 has `#### Detail` before its answer, so the entry ends early and it reads `unrecognized`.
- Q-103, `* **Answer:** keep`, reads `unrecognized`.

On the real archive (E4), I compared the 45 keep/drop results by eye against the first answer line. Each matches the `[1]`/`[2]` on that line, for example `**Answered 2026-09-23: [1], drop both.**` gives keep and `- **Answered 2026-09-20: [2], test first.**` gives drop. None takes an answer from a non-answer line.

**Evidence:** `scripts/dev-cycle.sh:263-287`; `fc23/entries.log`, `fc23/answers.log`, `fc23/probe1.log` (E8)

---

## Claim 13c: "only the text after the label's colon counts"

**Location:** `scripts/dev-cycle.sh:258`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers which colon is used. It does not establish any wrong keep/drop reading, since the failure here is `unrecognized`.

The code takes the first colon on the line, not the label's: `c = index(line, ":"); if (!c) next` (`:281`). When the label itself holds a colon, the cut lands inside the label. E8's Q-102, `**Answered 2026-09-17 10:30: keep**`, read `unrecognized` because the text became `30: keep`. None of the real archive's labels contains a colon before the label's own. Precise version: "the text after the first colon on the line". Wording; a conservative failure.

**Evidence:** `scripts/dev-cycle.sh:281-282`; `fc23/probe1.log` (E8)

---

## Claim 13d: "when the answer sits inside the bold, only up to the bold's end (notes after it are the recorder's)"

**Location:** `scripts/dev-cycle.sh:258-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the in-bold shape (`**Answered <date>: [2] drop it.** Notes [1].`). It does not establish anything for the label-only-bold shape (`**Answer (…):** drop. … [1] …`): there the whole rest of the line, notes included, counts (see Claim 30a).

```awk
# scripts/dev-cycle.sh:282-285
  rest = substr(line, c + 1)
  if (substr(rest, 1, 2) == "**") rest = substr(rest, 3)
  else if ((e = index(rest, "**")) > 0) rest = substr(rest, 1, e - 1)
  result = option(rest); done = 1
```

In test Q-008, `**ANSWERED 2026-09-20, run 3: [2] drop it.** Notes [1].` reads drop. The `[1]` after the bold is cut, as the comment says.

**Evidence:** `scripts/dev-cycle.sh:281-286`; `test/scripts/dev-cycle.bats:609`; `fc23/bats.log`

---

## Claim 13e: "[1] or [2] alone decides; both together are unrecognized; with neither, a first word 1, keep, 2 or drop followed by nothing or punctuation."

**Location:** `scripts/dev-cycle.sh:260-261`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `option()` and its mawk behaviour, plus a static gawk/POSIX read. It does not establish the behaviour of awks other than mawk by execution.

```awk
# scripts/dev-cycle.sh:264-272
function option(span,   one, two, w) {
  one = index(span, "[1]") > 0; two = index(span, "[2]") > 0
  if (one != two) return one ? "keep" : "drop"
  if (one) return "unrecognized"
  span = tolower(span); sub(/^[ \t*]+/, "", span)
  if (!match(span, /^(1|2|keep|drop)([.,;:!)]|$)/)) return "unrecognized"
  w = substr(span, 1, RLENGTH); sub(/[.,;:!)]$/, "", w)
  return (w == "1" || w == "keep") ? "keep" : "drop"
}
```

The bracket rule and the both-rule match the comment. "Punctuation" means only the six characters `. , ; : ! )`. So in E8:
- `**Answer:** drop it` (a space after the word) reads `unrecognized`;
- `**Answered:** 2 ` (a trailing space) reads `unrecognized`;
- `Keep!` and `1)` read keep.

Precise version: "followed by nothing or one of `. , ; : ! )`". Wording; a conservative failure.

Portability, read statically: the program uses no interval expressions. `tolower`, `match`/`RLENGTH`, `index`, `sub` and `substr` are POSIX awk. The `$` inside the alternation group is valid ERE. It runs under `env LC_ALL=C` (`:293`), so `tolower` is ASCII-only in any awk.

**Evidence:** `scripts/dev-cycle.sh:264-272`, `:293`; `fc23/probe1.log` (E8)

---

## Claim 14: skip reason `"skip $a: no such entry in docs/working/questions.md or questions-archive.md"`

**Location:** `scripts/dev-cycle.sh:290-296`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers what the skip line says when a questions file is not plain. It does not establish how often section 8 blocks a questions file in practice.

```bash
# scripts/dev-cycle.sh:291-296
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    inrepo "$f" || continue
    r="$(env LC_ALL=C awk -v id="$a" "$ANSWER_AWK" "$f")"
    if [[ -n "$r" ]]; then echo "$r $a"; return; fi
  done
  echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md"
```

(excerpt ends :296; enclosing `check_answer()` ends :297 — read)

A file that fails `inrepo` (a symlink, or not a regular file) is passed over silently, and the skip line then says the entry does not exist. In P3, `questions.md` was a symlink to a file holding an answered Q-001. The script printed `skip Q-001: no such entry in docs/working/questions.md or questions-archive.md`.

Behavioral consequence through the skill: In flight 2 treats "a skip" like `unrecognized`. "In each of these cases add the ID to `Applied:`, so each answer is read once" (`skills/dev-cycle/SKILL.md:259-261`). So when a questions file is blocked, the user's answer is consumed as unreadable and never read later. Preconditions: section 8 lists a questions file, and a brief has an Asked ID. Precise version: a distinct reason, such as "skip Q-NNN: docs/working/questions.md is not a plain file (not read)", and the skill should not add a blocked-file skip to `Applied:`.

**Evidence:** `scripts/dev-cycle.sh:149`, `:288-297`; `skills/dev-cycle/SKILL.md:253-261`; `fc23/probe2.log` (P3)

---

## Claim 15: "show-ref --verify takes only the exact ref, so a tag named refs/heads/<c> cannot stand in for a missing branch (rev-parse would accept it)."

**Location:** `scripts/dev-cycle.sh:320-321`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the candidate loop. It does not establish the current-branch fallback, which uses `rev-parse HEAD` (`:330`) and is unaffected. `MAIN` is used only as a printed label (`:372`, `:384`, `:546-547`); git always receives `MAIN_SHA` (`:379`, `:382`, `:540`).

In P1 (a repo on branch `trunk` at a031b8f, with tag `refs/heads/main` at 37373ea):
- the digest printed `on \`trunk\` at a031b8f`;
- the old lookup, `git rev-parse --verify 'refs/heads/main^{commit}'`, returned 37373ea, the tag's commit.

The extra `rev-parse "$sha^{commit}"` (`:323`) only peels the found hash.

**Evidence:** `scripts/dev-cycle.sh:313-333`, `:372-384`, `:540-547`; `fc23/probe2.log` (P1)

---

## Claim 16: "An in-cycle fix (steps 1, 3, 4, and a missing doc) edits only a file that `--check-fix '<path>'` prints `ok` for: an existing file under `docs/`, or `README.md`; anything else (a new file, code, scripts, hooks, egress lists, instruction files) is filed, not written."

**Location:** `skills/dev-cycle/SKILL.md:71-74`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers what `--check-fix` admits. It does not establish that steps 1 and 3 ("Fix what is mechanical now", `:153`; "do it in-cycle", `:174`) are read as bound by this rule; neither step repeats it.

As in Claim 12, code and scripts under `docs/` pass (E5: `ok docs/human-author/prompts.ts`, `ok docs/reviews/execution-logs/p.sh`). "an existing file under `docs/`, or `README.md`" is exact. "anything else (… code, scripts …)" is imprecise for files of those types under `docs/`. Wording, low.

**Evidence:** `skills/dev-cycle/SKILL.md:71-74`; `scripts/dev-cycle.sh:248-253`; `fc23/probe1.log` (E5)

---

## Claim 17: "Briefs are found only through `--check-path 'docs/working/briefs/*.md'`"

**Location:** `skills/dev-cycle/SKILL.md:74`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the listing this glob produces. It does not establish the brief count at which this bites in practice.

The glob is capped at 50 matches (`:206`). Git lists tracked paths in byte order, and brief names start with their date. So past 50 brief files the newest ones are dropped, and those are the ones most likely to be open. In P6, with 51 tracked briefs, the listing ended `ok docs/working/briefs/2026-01-50-b.md` and then `skip docs/working/briefs/*.md: matches more than 50 files; the rest are not listed (narrow the glob)`. The Rules elsewhere say "past that, narrow the glob" (`:67`). But this sentence names the one glob as the only way. Closed briefs stay in the directory, so the count only grows: about 17 cycles at 3 briefs each. Precise version: "…through `--check-path` on `docs/working/briefs/*.md`, narrowed (e.g. by year) when it reports more than 50". Behavioral, low.

**Evidence:** `skills/dev-cycle/SKILL.md:66-67`, `:74`; `scripts/dev-cycle.sh:199-210`; `fc23/probe2.log` (P6)

---

## Claim 18: "A brief's branch reaches git only as the hash `--check-branch '<name>'` prints (`ok <name> <hash>`; `ok <name> absent` means no such branch), never by name."

**Location:** `skills/dev-cycle/SKILL.md:76-78`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the output format and its meaning, plus every skill sentence that runs git with a brief's branch: In flight 1 and 3 use the hash. It does not establish that "absent" means the work was never merged (Claim 21). Step 1's merged-branch list compares names produced by git and gives git no name from a brief.

E6 confirms the output format. "absent" means no `refs/heads/<name>`, even if a tag of that name exists. The skill places that branch into git in only two spots. In flight 1 uses "Its branch's hash (from `--check-branch`…)" (`:249`). In flight 3 uses "its branch passed the check, and that branch has no commit beyond the default branch" (`:262-264`). Step 1, "Skip any branch or worktree an open brief … names" (`:147-148`), only compares names.

**Evidence:** `skills/dev-cycle/SKILL.md:76-78`, `:146-149`, `:249-264`; `fc23/probe1.log` (E6)

---

## Claim 19: "A question ID from a brief is read only through `--check-answer`."

**Location:** `skills/dev-cycle/SKILL.md:78`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers every skill sentence that reads an answer for an Asked ID. It does not establish how step 3 (watched questions), which reads other entries, does so.

In flight 2 says "Run `--check-answer` with the IDs not yet on its `Applied:` line" (`:254-255`). In flight 3's "no ID on its `Asked:` line is still `open`" (`:262`) uses that same output word. No other sentence reads an Asked ID's answer; the old prose parsing rule is gone (`git diff 6c8ae91..36ca12c`).

**Evidence:** `skills/dev-cycle/SKILL.md:78`, `:253-264`

---

## Claim 20: "Skip any branch or worktree an open brief (found as in the Rules) names: work on it may be in progress."

**Location:** `skills/dev-cycle/SKILL.md:147-149`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that step 1 lists briefs through the Rules' check. It does not establish the cap residue, which is shared with Claim 17.

"found as in the Rules" points to "Briefs are found only through `--check-path 'docs/working/briefs/*.md'`" (`:74`). `check_path` refuses a symlinked brief: `elif ! inrepo "$m"; then echo "skip $m: reached through a symlink, or not a regular file"` (`scripts/dev-cycle.sh:208`). The Build briefs count refers to the same rule ("found as in the Rules", `:281`). This closes the pass-22 rubric's A4.

**Evidence:** `skills/dev-cycle/SKILL.md:74`, `:147-149`, `:281`; `scripts/dev-cycle.sh:207-209`

---

## Claim 21: In flight 1 and 3: "Its branch's hash (from `--check-branch`, as in the Rules) is an ancestor of the default branch → Done." … "that branch has no commit beyond the default branch (or is `absent`) 14 days after the brief's last `Kept:` date … file one `you: judgment` entry"

**Location:** `skills/dev-cycle/SKILL.md:249-250`, `:262-265`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the ancestor test as the Done condition, and how it interacts with check 3. It does not establish how often a cycle runs while a build branch has no commits; that is likely, given the final message's "on its own branch and worktree".

Two things are wrong.

**A fresh or idle branch reads as Done.** A branch with no commit beyond the default branch is by definition an ancestor of it. E9 created a branch at main's tip, and `git merge-base --is-ancestor <hash> main` succeeded. So a branch created for the brief whose session has not committed yet passes check 1. That includes the branch `git worktree add -b` creates when the user starts the brief (`:323-324`). The cycle moves it to Done and sets `Status: closed`, with nothing merged. The same happens to a branch left behind on an older default commit.

**The two checks overlap.** For an existing branch, "has no commit beyond the default branch" is exactly the ancestor condition, so check 1 has already closed it. Check 3's existing-branch clause can therefore never fire. Keep-or-drop questions are filed only for `absent` branches.

Answer to the brief's question: a merged-then-deleted branch never reaches Done. It prints `ok <name> absent`, which has no hash to test in check 1. After 14 days check 3 files keep-or-drop. A "drop" answer then sends it to Ideas as dropped, and a "keep" answer holds the slot. Only the user closing the brief by hand ends it otherwise.

The old wording ("merged into the default branch") had the same `--merged` semantics. This round makes the ancestor test explicit and adds the "or is `absent`" path. Behavioral.

**Evidence:** `skills/dev-cycle/SKILL.md:247-269`, `:322-324`; `fc23/probe1.log` (E9)

---

## Claim 22: "A branch the check skips is recorded; checks 2 and 3 still run." (also commit 6db3d8a: "A skipped branch is recorded and checks 2 and 3 still run.")

**Location:** `skills/dev-cycle/SKILL.md:251-252`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers how a skipped branch flows through checks 2 and 3. It does not establish how a brief's branch line could fail the check after step 6 required `ok`; it would need a hand edit, or a branch name git later refuses.

Check 2 runs. Check 3 also "runs", but its condition includes "its branch passed the check" (`:263`), so for a skipped branch it can never file a keep-or-drop entry. Check 1 cannot fire either, because there is no hash. Such a brief keeps its slot (`:269`, and the 3-brief limit at `:280`) until the user closes it by hand. Precise version: "…check 2 still runs; check 3 files nothing until the branch line is fixed". Wording, with a small behavioral residue (a stuck slot).

**Evidence:** `skills/dev-cycle/SKILL.md:249-269`, `:279-282`

---

## Claim 23: In flight 2: "Run `--check-answer` with the IDs not yet on its `Applied:` line …; it reads `questions.md` and, once step 1 has archived an entry, `questions-archive.md`. `open` is not answered yet: leave the ID. `keep` sets `Kept: <today>` …; `drop` closes the brief as in 1; `unrecognized` or a skip goes in the record …"

**Location:** `skills/dev-cycle/SKILL.md:253-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the lookup order and the output vocabulary the step relies on. It does not establish the two residues. A blocked questions file gives a misleading skip that this step consumes (Claim 14). An OPEN entry that already holds a placeholder `**Answer:**` line reads `unrecognized`, not `open`; in E8, Q-108 with `- **Answer:** pending, see Q-109` read `unrecognized`, so that ID would be applied before the user answers.

`check_answer` reads `questions.md` first and the archive second (`scripts/dev-cycle.sh:291`), and prints exactly one of keep/drop/open/unrecognized or a skip per ID. E4 returned results from both files. The script's comment defines `open` as "no answer line and not marked ANSWERED" (`:255`), which matches E8.

**Evidence:** `skills/dev-cycle/SKILL.md:253-261`; `scripts/dev-cycle.sh:254-297`; `fc23/answers.log`, `fc23/probe1.log` (E8)

---

## Claim 24: "counting earlier cycles' (found as in the Rules) and the ones this cycle has written (not yet committed, so `--check-path` does not list them)" (also commit 36ca12c: "briefs written this cycle are not committed yet, so --check-path does not list them")

**Location:** `skills/dev-cycle/SKILL.md:280-282`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers when `--check-path` lists an uncommitted brief. It does not establish that any repo running the cycle ignores `docs/working/`; claude-workflows does not (`git check-ignore docs/working/briefs/x.md` prints nothing).

`--check-path` lists the index, not commits, plus ignored files under `docs/working/` (`scripts/dev-cycle.sh:191-197`). In P4:
- an untracked new brief gave `skip … no tracked file … matches`, so the claim holds here;
- after `git add` it gave `ok docs/working/briefs/2026-10-01-a.md`;
- with `docs/working/` in `.gitignore` and the brief untracked, it also gave `ok`.

So "not yet committed" is really "not yet staged". In a project that ignores `docs/working/`, a cycle following this sentence would count its own briefs twice and write fewer than 3. Precise version: "(not yet staged, so `--check-path` does not list them unless `docs/working/` is gitignored)". Behavioral residue low, cross-project.

**Evidence:** `skills/dev-cycle/SKILL.md:279-282`; `scripts/dev-cycle.sh:189-198`; `fc23/probe2.log` (P4)

---

## Claim 25: test "--check-branch allows only a plain, valid branch name" (now with `HEAD`, `refs/heads/x`)

**Location:** `test/scripts/dev-cycle.bats:538-549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the 14 listed inputs and the count of exactly 2 `ok` lines. It does not establish branch names outside the list.

The test asserts `"skip HEAD: not a valid"` and `"skip refs/heads/x: not a valid"`, and `[ "$(grep -c '^ok ' <<<"$output")" -eq 2 ]`. It passed in E1, and E6 reproduced both skips. This closes pass-22 Claim 24.

**Evidence:** `test/scripts/dev-cycle.bats:538-549`; `fc23/bats.log`; `fc23/probe1.log` (E6)

---

## Claim 26: test title "--check-path does not warn per match under an uninstalled locale"

**Location:** `test/scripts/dev-cycle.bats:551`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title against the body. It does not establish warning behaviour for the other modes.

The body runs only `run --separate-stderr env LC_ALL=xx_XX.UTF-8 bash "$DC" --check-path 'docs/decisions/*.md' docs/decisions/m1.md` (`:555`), and it passed in E1. This closes pass-22 Claim 25.

**Evidence:** `test/scripts/dev-cycle.bats:551-561`; `fc23/bats.log`

---

## Claim 27: test "--check-branch gives the branch's own hash, never a tag's"

**Location:** `test/scripts/dev-cycle.bats:572-582`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers an existing branch and a tag-only name. It does not establish the case where both a branch and a same-named `refs/heads/` tag exist; static reading says `show-ref --verify` returns the branch.

The test makes `git tag refs/heads/feat/ghost` and asserts `ok feat/real $(git rev-parse feat/real)` and `ok feat/ghost absent`. It passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:572-582`; `fc23/bats.log`

---

## Claim 28: test "--check-fix allows only existing docs/ and README.md files"

**Location:** `test/scripts/dev-cycle.bats:584-596`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the eight listed inputs. It does not establish that docs/ holds documentation only (Claim 12).

The test asserts:
- `ok docs/decisions/log.md` and `ok README.md`;
- skips for `hooks/x.sh`, `egress/x.txt`, `AGENTS.md`, `docs/new.md` ("no tracked file"), `docs/*.md` ("not an allowed path form") and `docs`.

It passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:584-596`; `fc23/bats.log`

---

## Claim 29: test "--check-answer reads keep-or-drop answers in the archive's real shapes"

**Location:** `test/scripts/dev-cycle.bats:598-621`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the 12 inputs and that most fixtures copy real archive shapes:
- Q-001 is Q-091's `**Answer (date): [1].**`;
- Q-002 is Q-101's `- **Answer (…, in chat):** [2].`;
- Q-004 and Q-005 are Q-010's "keep both";
- Q-008 follows Q-049's `run 3` label.

It does not establish coverage of the label-only-bold shape with a bracket in the notes (Claim 30a). Q-003's "between [1] and [2]" does not occur in the archive.

The test passed in E1, and every expected line was present.

**Evidence:** `test/scripts/dev-cycle.bats:598-621`; `fc23/bats.log`; `fc23/entries.log`

---

## Claim 30a: commit 2008343: "only the bold answer span counts, so the recorder's notes cannot flip it"

**Location:** commit 2008343 (`scripts/dev-cycle.sh:282-285`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the label-only-bold shape and the `Q-NNN:` shape. It does not establish how often recorded notes name an option after a worded answer, and the archive has no such line today.

The bold cut applies only when the answer sits inside the bold. When the bold closes right after the label (`**Answer (…):** …`, the shape of the newest real entry, Q-101 at `questions-archive.md:1832`), `rest` starts with `**`. That prefix is stripped, and the whole remainder, notes included, goes to `option()`, where any lone `[1]`/`[2]` beats a worded first answer:

```awk
# scripts/dev-cycle.sh:283
  if (substr(rest, 1, 2) == "**") rest = substr(rest, 3)
```

(excerpt ends :283; enclosing rule continues to :286 — read)

In P2:
- `- **Answer (2026-10-01, in chat):** drop. Option [1] would cost more.` read **`keep`**.
- `Q-002: drop, not [1]` read **`keep`**.
- `**Answer (2026-10-01):** [2]. Reopen with [1] if it comes back.` read `unrecognized`.

So notes can flip a worded answer, and can turn a bracketed one into `unrecognized`. In the skill, a flipped `keep` sets `Kept:` on a brief the user dropped (`skills/dev-cycle/SKILL.md:258`). Preconditions: the answer is a word rather than `[n]`, and the same line names the other option in brackets. Behavioral. Precise version: "only the bold span counts when the answer is inside the bold; after a label-only bold or `Q-NNN:`, the whole line counts".

**Evidence:** commit 2008343 message; `scripts/dev-cycle.sh:264-286`; `fc23/probe2.log` (P2); `fc23/entries.log`

---

## Claim 30b: commit 2008343: "On the real archive: 26 keep, 19 drop, 44 unrecognized, none read wrongly as open."

**Location:** commit 2008343
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers wt-devcycle's archive as of 15:57Z. It does not establish that the keep/drop words mean "keep"/"drop" for these entries; none of them is a keep-or-drop question (`grep -c keep-or-drop` is 0 in both files).

E4 printed 26 keep, 19 drop, 44 unrecognized and 13 open. The 13 open IDs all come from `questions.md` and are `**Status:** OPEN`, so the archive alone gives 26/19/44 with no `open`. Checked by eye against `fc23/entries.log`, there is no misreading:
- every keep/drop follows the first answer line's `[1]`/`[2]`;
- every unrecognized result has a worded or hedged answer (for example `keep both — neither is wrong`, `[3]`), a mid-line answer, or no answer line under `ANSWERED`.

**Evidence:** `fc23/answers.log`, `fc23/entries.log`, `fc23/probe1.log` (E4)

---

## Claim 30c: commit 2008343, the rest of the message ("Labels: Q-NNN:, **Answer…** and **Answered…** in any case and with a "- " prefix, never **Answering**"; "[1] and [2] together, hedges like "keep both", and an ANSWERED entry with no readable answer are unrecognized"; --check-branch hash and default-branch lookup; "Plain paths keep only themselves in the ignored listing too"; "usage error says "argument""; "33/33; shellcheck clean")

**Location:** commit 2008343
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the listed bullets. It does not cover the "notes cannot flip it" clause (Claim 30a) or the --check-fix bullet's "scripts … are filed" gloss (Claim 12).

Each bullet is confirmed in Claims 7, 9, 11, 13b, 13e and 15. The test count of 33 was checked at ba39470 (E1). 2008343 added tests 31–33, and ba39470 added none. Shellcheck printed nothing (E2). (Paraphrased — no quote available because the claim summarises hunks quoted piecewise in the cited claims.)

**Evidence:** commit 2008343; `fc23/bats.log`, `fc23/shellcheck.log`

---

## Claim 31: commit ba39470: "--check-branch also requires git check-ref-format --branch and refuses HEAD and names under refs/ …; The uninstalled-locale test is titled for the one mode it runs. 33/33; shellcheck clean."

**Location:** commit ba39470
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the message against the diff and E1/E2. It does not establish anything beyond Claims 25 and 26.

`scripts/dev-cycle.sh:239-240` (quoted in Claim 4) and the test edits match. E1 gave 33/33, and E2 was empty.

**Evidence:** commit ba39470; `fc23/bats.log`, `fc23/shellcheck.log`

---

## Claim 32: commit 6db3d8a, apart from the skipped-branch clause ("Keep-or-drop answers come from --check-answer …; the prose parsing rule is gone"; "Step 2 dropped from the list: it fixes nothing"; "A brief's branch reaches git only as the hash"; "Briefs are listed only through --check-path, so a symlinked brief is never followed (steps 1 and 6)"; "docs/dev-cycle.md names the in-repo script path too")

**Location:** commit 6db3d8a
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the listed bullets against the diff. The skipped-branch clause is verdicted in Claim 22, and the in-cycle fix gloss in Claim 16.

Step 2 (`skills/dev-cycle/SKILL.md:155-166`) only files questions entries, so dropping it from the fix list is right. The other bullets are confirmed in Claims 1, 18, 19 and 20. (Paraphrased — no quote available because the claim summarises hunks quoted in those claims.)

**Evidence:** commit 6db3d8a; `skills/dev-cycle/SKILL.md:71-78`, `:147-149`, `:155-166`, `:249-261`; `docs/dev-cycle.md:27-28`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14** (`scripts/dev-cycle.sh:290-296`): when a questions file is not plain, `--check-answer` prints "no such entry". In flight 2 then adds the ID to `Applied:`, so the answer is never read. It needs a distinct skip reason, and a blocked-file skip should not be applied. **Behavioral** (precondition: section 8 lists a questions file).
- **Claim 21** (`skills/dev-cycle/SKILL.md:249-250`, `:262-265`): "hash is an ancestor of the default branch → Done" closes a brief whose branch exists but has no commits yet (a fresh `worktree add -b`) as Done, with nothing merged. Check 3's existing-branch clause can never fire. A merged-then-deleted (`absent`) branch never reaches Done and goes to keep-or-drop instead. **Behavioral.**
- **Claim 30a** (commit 2008343; `scripts/dev-cycle.sh:283`): "notes cannot flip it" is false after a label-only bold or `Q-NNN:`. `**Answer (…):** drop. Option [1] would cost more.` reads `keep`. **Behavioral** (precondition: a worded answer plus a bracketed option in the same line).

### Stale
- **Claim 10** (`scripts/dev-cycle.sh:215-216`): "in-cycle fixes to other files go through --check-path" now means `--check-fix`. **Wording.**

### Mostly Accurate
- **Claim 4** (`scripts/dev-cycle.sh:32-35`): the help's `--check-branch` refusal list omits `HEAD`, `refs/*` and the `--branch` rule. **Wording.**
- **Claim 12** (`scripts/dev-cycle.sh:246-247`): "documentation only … scripts … filed". The gate is by location, so `.ts`/`.py`/`.sh` files under `docs/` pass. **Wording** (low behavioral residue).
- **Claim 13c** (`scripts/dev-cycle.sh:258`): it is the first colon on the line, not the label's; a time in the label gives `unrecognized`. **Wording** (conservative).
- **Claim 13e** (`scripts/dev-cycle.sh:260-261`): "punctuation" is only `. , ; : ! )`, so "drop it" and a trailing space give `unrecognized`. **Wording** (conservative).
- **Claim 16** (`skills/dev-cycle/SKILL.md:71-74`): the same docs/-code imprecision as Claim 12. **Wording.**
- **Claim 17** (`skills/dev-cycle/SKILL.md:74`): the one named brief glob is capped at 50, and past that the newest briefs drop out. It should say to narrow. **Behavioral, low** (at scale).
- **Claim 22** (`skills/dev-cycle/SKILL.md:251-252`, commit 6db3d8a): "checks 2 and 3 still run", but check 3 requires a passed check, so a skipped-branch brief holds its slot until closed by hand. **Wording** (small behavioral residue).
- **Claim 24** (`skills/dev-cycle/SKILL.md:280-282`, commit 36ca12c): "not yet committed" is really "not yet staged". Where `docs/working/` is gitignored, uncommitted briefs are listed and counted twice. **Behavioral, low** (cross-project).

### Unverifiable
(none)

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass23.md`. It has:
- the required first line;
- `**Replication:** k=1 (loop pass, decision 031)`;
- the seven mandatory per-claim fields plus `**Legibility-target:**`;
- the attention summary.

It was not committed.

Against the brief's priority list:

**A, `--check-answer` on every real answer line.** No clear keep or drop is misread. No non-answer line is taken as an answer. Entry boundaries hold for `##` headings and for prefix IDs (Q-10 vs Q-100) (Claims 13a, 13b, 30b). Residues:
- notes can flip a worded answer after a label-only bold (30a);
- a blocked file is reported as "no such entry" (14);
- `####` subheadings, `* ` bullets, colons in labels and trailing spaces give `unrecognized` (13b, 13c, 13e).

**A, awk portability.** No intervals are used. `tolower`, `match`/`RLENGTH` and the anchored alternation are POSIX. The C locale is set. It was executed under mawk only; there is no gawk here (13e).

**A, `--check-fix` scope.** The rule is correct as a location gate. `docs/` holds non-doc files (`prompts.ts`, execution-log `.py`/`.sh`, the user's answers files), and these pass (12).

**A, `--check-branch` hash and tag shadowing.** Correct and complete. A tag-only name gives `absent` (11, 27).

**A, the default-branch lookup.** Correct. `MAIN` is only a label, and git receives `MAIN_SHA` (15).

**A, help range and commits.** `2,48p` is correct (8). The 2008343 message is right except "notes cannot flip it" (30a). The ba39470 message is right (31). 33/33, shellcheck clean.

**B, each mode in its place.** Answers go through `--check-answer` (19). Fixes go through `--check-fix` (16). Branches reach git only by hash (18). Briefs are listed through `--check-path` (17, 20).

**B, the In-flight flow.** A merged-then-deleted branch cannot reach Done. A fresh branch at the default tip reaches Done wrongly. A skipped branch holds its slot (21, 22). This cycle's briefs are counted, with the staged/ignored residue (24).
