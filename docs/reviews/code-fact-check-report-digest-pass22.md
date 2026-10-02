Commit: bc98571 (A) / 6c8ae91 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at bc98571; HEAD dd14ff6 adds review docs only, `git diff --stat bc98571 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 6c8ae91; HEAD 21026af merges A in, and `git show 21026af:scripts/dev-cycle.sh` is byte-identical to A's script).
**Scope:** Partial: the pass-21 fix round only. A: `git diff d5d9121..bc98571 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of 3d839c1 and bc98571. B: `git diff fbc7101..6c8ae91 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` plus the message of 6c8ae91. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 31
**Summary:** 23 verified, 8 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. No claim below matches a logged pattern. There is no Incorrect verdict, so nothing is appended to the log.

**Probe-cleanup incident (read this first).** The first run of `fc22/probe2.sh` (09:29:38Z) went wrong. It ran in a fresh shell where `PROBE_TMP` was not exported, so `mktemp -d` failed and `cd ""` left the probe in `/workspace`. The probe's setup then ran inside `/workspace`'s own checkout, on branch `main`:
- it re-ran `git init`;
- it set local `user.email=t@t` and `user.name=t`;
- it overwrote `.gitignore` with the single line `docs/working/r*`;
- it wrote `docs/decisions/m1.md` to `m6.md`;
- it ran `git add -A && git commit -qm init`.

The result is commit **e28afaa "init" on `/workspace` main** (parent bf54363): 965 files, among them formerly ignored content (embedded repos, `.bats` logs, `__pycache__`, the `devcontainer-config/` files, of which the `.env*` files are 0 bytes). After the commit the probe also left untracked `docs/working/r<0xFF>.md`, `docs/working/rdir/` and a symlink `ul -> /etc` in `/workspace`. Nothing was pushed.

My repair attempt was denied by the permission classifier, so **the damage is still in place and needs the user**. The repair I tried, and still suggest after checking that `git -C /workspace rev-parse HEAD` is still e28afaa on main with parent bf54363:
1. `git reset --mixed bf54363` (the working tree is kept, and the reflog keeps e28afaa).
2. `git checkout -- .gitignore`.
3. `git config --local --unset user.email; git config --local --unset user.name` (the global config sets neither; author identity comes from `GIT_AUTHOR_*` in the environment).
4. Remove `ul`, `docs/decisions/m{1..6}.md`, `docs/working/r$'\xff'.md` and `docs/working/rdir/`.

The probe now fails closed if it has no temp dir. Every later run used a `mktemp -d` dir under `fc22/`. Apart from that incident and this report, nothing was written to `/workspace` or to either worktree.

Execution logs are scratch and are not committed. They are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc22/` (below, `fc22/`). Every process ran under `timeout`. The environment's default `LC_ALL=en_US.UTF-8` is not installed (`locale -a`: C, C.utf8, POSIX), so the probes set the locale explicitly. `fc22/dev-cycle-d5d9121.sh` is `git show d5d9121:scripts/dev-cycle.sh`, used only for old-versus-new comparisons.

Executed runs (UTC; all exit 0):
- E1, 09:28:57Z, in `/workspace/.claude/wt-digest`:
  - `timeout 300 bats test/scripts/dev-cycle.bats`: 30/30 ok → `fc22/bats.log`.
  - `timeout 60 shellcheck scripts/dev-cycle.sh`: empty output → `fc22/shellcheck.log`.
  - `bash scripts/dev-cycle.sh --help` → `fc22/help.log`.
- E2, 09:29:19Z: `LC_ALL={C,C.utf8} timeout 60 bash fc22/probe1.sh <A script>` in a throwaway repo → `fc22/probe1-C.log`, `fc22/probe1-C.utf8.log`. It covers branch names, brief shapes, the directory reason, symlinked directories and the write mode. The two logs differ only in the env line.
- E3, 09:32:11Z: `timeout 120 bash fc22/probe2.sh <A script> fc22/dev-cycle-d5d9121.sh` in a throwaway repo → `fc22/probe2.log`. It compares new and old under `LC_ALL=xx_XX.UTF-8` (not installed), `C.UTF-8` and `C`, on per-match warnings and on an ignored non-UTF-8 name. It also tries an untracked symlink to a directory and an ignored directory under docs/working.
- E4, 09:33:50Z: `timeout 30 python3 fc22/answers22.py docs/working/questions-archive.md docs/working/questions.md` in `/workspace/.claude/wt-devcycle` → `fc22/answers.log`. The script applies the 6c8ae91 answer rule to every real answer line, in two modes. Strict: only the labels exactly `**Answer:**` / `**Answered <date>:**`. Lenient: any `**Answer…:**` / `**Answered…:**`.

The questions files are a time-varying input. The E4 results hold for wt-devcycle's working tree as of 09:33Z.

Legibility-target values:
- **agent**: the model running the skill or digest acts on the text.
- **maintainer**: someone editing the script or tests.
- **user**: the human reading the digest, record or commit log.

---

## Claim 1a: "Each row is passed to `~/.claude/scripts/dev-cycle.sh --check-path`"

**Location:** `docs/dev-cycle.md:27`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers which copy of the script this repo's settings doc names; does not establish anything about other repos' settings files.

`docs/dev-cycle.md` is claude-workflows' own settings file. The skill says that inside claude-workflows the cycle runs "its own `scripts/dev-cycle.sh`" (`skills/dev-cycle/SKILL.md:65`). `ls ~/.claude/scripts/dev-cycle.sh` gives "No such file or directory" in this environment (E4 session, command output inline in the shell transcript; paraphrased: no quote available because the result is a missing file). So the doc names a copy that this repo does not use, and that is not installed here. Precise version: "passed to `scripts/dev-cycle.sh --check-path` (the installed `~/.claude/scripts/dev-cycle.sh` elsewhere)". Wording only.

**Evidence:** `docs/dev-cycle.md:27`, `skills/dev-cycle/SKILL.md:64-65`

---

## Claim 1b: "which allows tracked files and gitignored files under `docs/working/` …, at most 50 per row, never a symlink, a directory, a `.` or `..` component, `.git*` or any other untracked file."

**Location:** `docs/dev-cycle.md:27-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the scope list against `check_path()` at bc98571 for one argument per row; does not establish how a row containing several space-separated paths would be passed.

E2 printed `skip docs: a directory, not a file`, `skip linkd: reached through a symlink, or not a regular file` and `skip build: a directory, not a file`. E1's bats cases cover `..`, `.git*`, the cap and untracked files (`test/scripts/dev-cycle.bats:484-510`). "Per row" equals "per argument" when a row is one glob.

**Evidence:** `scripts/dev-cycle.sh:188-203`, `fc22/probe1-C.utf8.log`, `fc22/bats.log`

---

## Claim 2: "--check-brief the same, for a build brief only (docs/working/briefs/YYYY-MM-DD-<slug>.md): what a roadmap brief path must pass. --check-branch "ok <name>" for a branch name from a brief that git may be given as refs/heads/<name>: letters, digits, . _ - / only, not starting with -, and a valid ref name."

**Location:** `scripts/dev-cycle.sh:11-12`, `scripts/dev-cycle.sh:26-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers both modes' accept and refuse sets as stated. Does not establish that a brief's date is real (`2026-13-45` passes, which commit 3d839c1 discloses), that the brief file exists, or that an `ok` branch is one `git branch` will create (see Claim 15).

```bash
# scripts/dev-cycle.sh:224-229
check_branch() {
  local a="$1"
  if [[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]; then echo "skip ${a//$'\n'/ }: not an allowed branch name"
  elif ! git check-ref-format "refs/heads/$a"; then echo "skip $a: not a valid branch name"
  else echo "ok $a"; fi
}
```

E2 results. `ok feat/x-1`, `ok a/-b`. `skip -a: not an allowed branch name`. `a/.b`, `a.`, `a//b`, `a/b.lock`, `.a` and `a.lock/b` each give `skip …: not a valid branch name`. `@`, `a@b`, `a*b`, `a?b`, `a[b`, `a\b`, `a~b`, `a^b`, `a:b`, a newline name, `é` and fullwidth `Ａ` each give `not an allowed branch name`. Brief mode: `ok docs/working/briefs/2026-01-01-x.md`. Refused: the empty slug `-.md`, `.MD`, a subdirectory, `.md.md`. Arabic-Indic digits fail the form check. Both locales gave identical output.

**Evidence:** `scripts/dev-cycle.sh:208-229`, `fc22/probe1-C.log`, `fc22/probe1-C.utf8.log`

---

## Claim 3: "--check-write the same for a file the cycle writes: only its own files (roadmap, questions files, idea log, cycle records, briefs)."

**Location:** `scripts/dev-cycle.sh:24-25`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the help line's wording against the bc98571 comment and the 6c8ae91 skill; does not re-test `writable()` (unchanged in behavior; Claim 14).

These lines are unchanged in this round. Meanwhile the in-code comment was reworded to "The cycle's own bookkeeping files (in-cycle fixes to other files go through --check-path instead)" (`scripts/dev-cycle.sh:204-205`). The skill now has in-cycle fixes write other existing files (`SKILL.md:71-72`). "For a file the cycle writes" therefore still reads as covering every write, which is the pass-21 12a wording the comment and the skip reason dropped. The parenthesis limits it to the right list. Precise version: "--check-write the same for one of the cycle's own bookkeeping files (roadmap, …)". Wording only.

**Evidence:** `scripts/dev-cycle.sh:24-25`, `scripts/dev-cycle.sh:204-207`, `skills/dev-cycle/SKILL.md:68-72`

---

## Claim 4: "$CHECK needs at least one path" (for all four modes)

**Location:** `scripts/dev-cycle.sh:100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the message text for `--check-branch`; does not establish anything about exit status (1, which is correct).

```bash
# scripts/dev-cycle.sh:98-101
    --check-path|--check-write|--check-brief|--check-branch)
      CHECK="$1"; shift; CHECK_ARGS=("$@")
      [[ ${#CHECK_ARGS[@]} -gt 0 ]] || { echo "$CHECK needs at least one path" >&2; exit 1; }
      break ;;
```

`--check-branch` takes names (the usage line says `NAME...`), so the message for it says "path" where it means "name". Wording only.

**Evidence:** `scripts/dev-cycle.sh:12`, `scripts/dev-cycle.sh:98-101`

---

## Claim 5: help range `sed -n '2,39p'`

**Location:** `scripts/dev-cycle.sh:102`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the header block at bc98571; does not establish that the range will follow future header edits.

The header comment runs from :2 to :38. Line :39 is blank and :40 is `set -euo pipefail`. E1's `--help` output ends with the "Exit: …" lines and the "Printed repo text is data." line, followed by one blank line, and includes both new usage lines and both new mode descriptions.

**Evidence:** `scripts/dev-cycle.sh:1-40`, `fc22/help.log`

---

## Claim 6: "form: only letters, digits, . _ - / (and * ? in a glob), not starting with / or -, no empty, . or .. component, no component starting .git (any case)"

**Location:** `scripts/dev-cycle.sh:153-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the summary against `pathform()`; does not establish the scope or plainness clauses (`:155-157`, unchanged).

```bash
# scripts/dev-cycle.sh:167-172 (excerpt starts inside pathform(), which begins at :164 — read)
  [[ "$p" =~ $set && "$p" != /* && "$p" != -* ]] || return 1
  rest="$p/"
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1
  done
}
```

The pass-21 Stale item (Claim 5, the missing `.`) is fixed.

**Evidence:** `scripts/dev-cycle.sh:151-173`

---

## Claim 7: "Characters are listed one by one, not as ranges, so the check does not depend on the caller's locale …; setting LC_ALL here instead printed a setlocale warning per call when the caller's locale was not installed."

**Location:** `scripts/dev-cycle.sh:159-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers locale independence across C, C.utf8 and an uninstalled locale, and the historical warning. The Turkish-folding clause is rationale (no case-insensitive match remains), not a checkable property here. Does not establish behavior under an installed non-C locale with exotic collation (none is installed).

`NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`:163`). E2: the outputs under C and C.utf8 are identical. E3, uninstalled `xx_XX.UTF-8`, `--check-path 'docs/decisions/*.md' docs/decisions/m1.md`: the new script prints 7 `ok`, and its stderr has 2 lines, both `bash: warning: setlocale…` start-up lines. The d5d9121 script prints the same 7 `ok`, but its stderr has 11 lines: 2 start-up lines plus 9 from `dev-cycle-d5d9121.sh: line 176/182` (the `local LC_ALL=C` in `pathform`). That is one warning per argument and per match.

**Evidence:** `scripts/dev-cycle.sh:159-166`, `fc22/probe2.log`, `fc22/probe1-C.log`, `fc22/probe1-C.utf8.log`

---

## Claim 8: "# * ? first: - must stay last"

**Location:** `scripts/dev-cycle.sh:166`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the bracket built at `:165-166` and the one at `:226`; does not establish anything about bracket expressions elsewhere in the script.

`set="^[*?$NAMECHARS]+\$"` expands to `[*?a…z A…Z 0…9 ._/-]`, and `NAMECHARS` ends in `-`, so `-` is last and literal. Inside a bracket, `.`, `*` and `?` are literal. The same holds for `^[$NAMECHARS]+$` in `check_branch` (`:226`), where the unquoted expansion is wanted. E2's `a*b` and `a?b` are refused by `--check-branch`, which confirms that `*` and `?` are not in that set.

**Evidence:** `scripts/dev-cycle.sh:163-166`, `scripts/dev-cycle.sh:226`, `fc22/probe1-C.log`

---

## Claim 9: "a plain path names one file: drop a directory's contents here, not one by one" / commit 3d839c1: "A plain path that names a directory is filtered in one grep"

**Location:** `scripts/dev-cycle.sh:177-178`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the tracked-file branch of `matches()` and the ignored-file query that follows it. Does not establish timing (not measured this pass).

```bash
# scripts/dev-cycle.sh:174-187
matches() {  # $1 pathspec, $2 the argument; NUL-separated tracked files, then ignored ones under docs/working/
  local fixed="${2%%[*?]*}"
  if [[ "$2" == *[*?]* ]]; then GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1"
  else  # a plain path names one file: drop a directory's contents here, not one by one
    GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1" | { env LC_ALL=C grep -zxF -- "$2" || true; }
  fi
  ...
  if [[ "$fixed" == docs/working/* || docs/working/ == "$fixed"* ]]; then
    GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
      | { env LC_ALL=C grep -z '^docs/working/' || true; }
```

The `-x` filter applies only to tracked files. For a plain directory argument under `docs/working/` (e.g. `docs/working`), every ignored file below it still reaches `check_path()`'s loop. There, `[[ "$a" == *[*?]* || "$m" == "$a" ]] || continue` (`:193`) drops them one by one. The output is still right (E3: `skip docs/working: a directory, not a file`). Precise version: "a directory's tracked contents are dropped in one grep; ignored ones under docs/working/ are still dropped in the loop". Wording (performance only).

**Evidence:** `scripts/dev-cycle.sh:174-203`, `fc22/probe2.log`

---

## Claim 10: "C (set through env, which bash does not apply to its own locale): a name that is not UTF-8 still passes, to be skipped below" / commit bc98571: "an ignored docs/working name that is not UTF-8 reaches the form check and gets its skip line again"

**Location:** `scripts/dev-cycle.sh:184-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the ignored-file filter under C.UTF-8, C and an uninstalled locale; does not establish behavior with a grep other than GNU grep.

E3, ignored `docs/working/r\xff.md`, `--check-path 'docs/working/*'`. The new script prints `skip docs/working/r?.md: not an allowed path form` in all three locales, with no grep stderr, and under the uninstalled locale only the 2 bash start-up warnings. The d5d9121 script under C.UTF-8 prints `skip docs/working/*: no tracked file …` plus `grep: (standard input): binary file matches`, and under the uninstalled locale it adds per-call `setlocale` warnings. `env` runs grep as a child, so bash's own locale is untouched.

**Evidence:** `scripts/dev-cycle.sh:182-186`, `fc22/probe2.log`

---

## Claim 11: "skip $a: matches more than $max files; the rest are not listed (narrow the glob)"

**Location:** `scripts/dev-cycle.sh:195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the message and the cap; does not establish a total count (none is printed).

The new bats assertion `"skip docs/**: matches more than 50"` (`test/scripts/dev-cycle.bats:507`) passed in E1.

**Evidence:** `scripts/dev-cycle.sh:189-199`, `test/scripts/dev-cycle.bats:507-509`, `fc22/bats.log`

---

## Claim 12: directory skip reason, `if [[ "$a" != *[*?]* ]] && dirok "$a"; then echo "skip $a: a directory, not a file"`

**Location:** `scripts/dev-cycle.sh:200-202`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers which arguments get the directory reason and that `dirok` does not look below a symlink. Does not establish that the reason is limited to readable-scope directories: an untracked or ignored directory outside `docs/working/` also gets it, which reveals only that it exists.

`dirok()` is `[[ -z "$(blocker "$1" dir)" && -d "$1" ]]` (`:143`). `blocker()` walks top down and stops at the first non-plain part (`:126-136`), so `-d` runs only when no part is a symlink.

E2 and E3 results:
- A tracked symlink to a directory (`linkd`, `docs/linkdir2`) is listed by git as a file and gets `reached through a symlink`.
- An untracked symlink to `/etc` (`ul`) gets `no tracked file …`.
- `ul/passwd` and `linkd/f.md` get `no tracked file …`.
- Real directories get `a directory, not a file`: `docs`, `sub/dir`, ignored `build`, untracked `untr`, and `docs/working/rdir`.

`blocker` does `-e` on a symlinked component itself (which stats its target), as before this round.

**Evidence:** `scripts/dev-cycle.sh:126-143`, `scripts/dev-cycle.sh:200-202`, `fc22/probe1-C.utf8.log`, `fc22/probe2.log`

---

## Claim 13: "The cycle's own bookkeeping files (in-cycle fixes to other files go through --check-path instead); anything else named in repo text … is refused, so it is never treated as a brief and written to." and skip reason "not one of the dev cycle's own files"

**Location:** `scripts/dev-cycle.sh:204-207`, `scripts/dev-cycle.sh:218`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the comment and the skip reason against `SKILL.md:68-72` at 6c8ae91 and against E2. Does not establish that every in-cycle fix the skill describes has an existing target (Claim 18).

The skill matches: "Before writing one of the cycle's own files … `--check-write` …. An in-cycle fix (steps 1, 2, 3, 4) edits only an existing file that `--check-path` prints `ok` for" (`SKILL.md:68-72`). E2 printed `skip AGENTS.md: not one of the dev cycle's own files`. The pass-21 Incorrect 12a is fixed in the comment and the skip reason. The help line is not (Claim 3).

**Evidence:** `scripts/dev-cycle.sh:204-221`, `skills/dev-cycle/SKILL.md:68-72`, `fc22/probe1-C.utf8.log`

---

## Claim 14: `--check-brief` is "dated brief shape plus the write checks" (brief: `check_write "$a" brief`)

**Location:** `scripts/dev-cycle.sh:208-221`, `scripts/dev-cycle.sh:235`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the check order (form, then brief shape, then `writable`, then `blocker`) and that `isbrief` implies `writable`. Does not establish existence or tracking of the file, which needs `--check-path` (and the skill asks for both: Claim 19).

```bash
# scripts/dev-cycle.sh:209-221
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-[abcdefghijklmnopqrstuvwxyz0123456789-]+\.md$ ]]; }
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || isbrief "$1"
}
check_write() {  # $1 path, $2 "brief" to allow only a build brief
  local a="$1"
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ "${2:-}" == brief ]] && ! isbrief "$a"; then echo "skip $a: not a build brief (docs/working/briefs/YYYY-MM-DD-<slug>.md)"
  elif ! writable "$a"; then echo "skip $a: not one of the dev cycle's own files"
  elif [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"
  else echo "ok $a"; fi
}
```

`$DIGIT{4}` expands unquoted to `[0123456789]{4}`, as intended. E1's bats case (`:528-536`) and E2 agree.

**Evidence:** `scripts/dev-cycle.sh:208-221`, `test/scripts/dev-cycle.bats:528-536`, `fc22/probe1-C.utf8.log`

---

## Claim 15: "A brief's branch reaches git as refs/heads/<name>, so it can never be read as an option or as some other ref."

**Location:** `scripts/dev-cycle.sh:222-223`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers option injection and ref ambiguity for a name passed as `refs/heads/<name>`. Does not establish that an `ok` name is one `git branch` accepts: `HEAD` passes (`git check-ref-format --branch HEAD` fails), and `refs/heads/x` passes as the ref `refs/heads/refs/heads/x`.

The parse loop stops at the mode (`:98-101`), so E2's `-a` and the bats `--output=x` arrive as arguments and are refused. `-*` is refused before git runs (`:226`), and git sees only `refs/heads/$a`. E2 printed `ok HEAD` and `ok refs/heads/x`. Neither can be read as an option or as another ref when written with the `refs/heads/` prefix. A brief naming `HEAD` would only fail when the user tries to create it.

**Evidence:** `scripts/dev-cycle.sh:98-101`, `scripts/dev-cycle.sh:222-229`, `fc22/probe1-C.utf8.log`

---

## Claim 16: "`--check-path` allows tracked files and gitignored files under `docs/working/`, at most 50 per argument (past that, narrow the glob), never a symlink, a directory, a `.` or `..` component, `.git*` or any other untracked file."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the list against the bc98571 script (identical in 21026af). Does not establish what happens to the files past the cap (they are simply not listed).

The evidence is the same as for Claims 1b, 6, 11 and 12. The merged script is byte-identical: `git show 21026af:scripts/dev-cycle.sh | cmp - <A script>` succeeded.

**Evidence:** `skills/dev-cycle/SKILL.md:61-80`, `scripts/dev-cycle.sh:188-203`, `fc22/probe1-C.utf8.log`, `fc22/bats.log`

---

## Claim 17: "Before writing one of the cycle's own files (the record, a brief, the idea log, the roadmap, the questions files), run the same script with `--check-write '<path>'` and write only on `ok`; it allows only those files."

**Location:** `skills/dev-cycle/SKILL.md:68-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the list against `writable()`. Does not establish that `--check-write` is consulted before `questions.sh init/archive` (the skill gates those through section 8 instead, `SKILL.md:137-140`).

`writable()` (quoted in Claim 14) allows the roadmap, `questions.md`, `questions-archive.md`, `idea-log.md`, dated cycle records and dated briefs, and nothing else.

**Evidence:** `skills/dev-cycle/SKILL.md:68-71`, `scripts/dev-cycle.sh:208-213`

---

## Claim 18: "An in-cycle fix (steps 1, 2, 3, 4) edits only an existing file that `--check-path` prints `ok` for; a fix that needs a new file is filed, not written."

**Location:** `skills/dev-cycle/SKILL.md:71-72`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the step list against the steps that fix things in-cycle and against "Undocumented is broken". Does not establish whether step 1's health-check code fixes (which "land through `pr-prep`", `:31`) are meant to be included.

In-cycle fixes exist in:
- step 1: "Fix what is mechanical now" (`:150`);
- step 3: "do it in-cycle, at most 3 per cycle" (`:171`);
- step 4: "fix it if mechanical" (`:186`);
- "Undocumented is broken", a step 4 finding: "the doc is written in-cycle if that is mechanical" (`:38-39`).

Step 2 has none. A fired trigger "becomes a questions.md entry" (`:160`), so listing step 2 is imprecise but harmless. "Undocumented is broken" says the doc is "written". The new rule narrows that to editing an existing file, and a new doc file goes to the roadmap, which agrees with that rule's "otherwise it is filed on the roadmap as a bug" (`:39`). No contradiction. Precise version: "(steps 1, 3 and 4, including step 4's doc fixes)". Wording.

**Evidence:** `skills/dev-cycle/SKILL.md:37-41`, `skills/dev-cycle/SKILL.md:71-72`, `skills/dev-cycle/SKILL.md:150`, `skills/dev-cycle/SKILL.md:160`, `skills/dev-cycle/SKILL.md:171`, `skills/dev-cycle/SKILL.md:186`

---

## Claim 19: "A roadmap brief path counts as a brief (and holds a slot) only if `--check-brief '<path>'` and `--check-path '<path>'` both print `ok` for it."

**Location:** `skills/dev-cycle/SKILL.md:72-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that the two checks together require brief shape, plainness, and tracked (or ignored-under-docs/working) existence. Does not establish what happens to a brief written this cycle and still untracked: `docs/working/briefs/` is not ignored in this repo (`git check-ignore` exit 1), so `--check-path` refuses it until it is staged. It also does not establish whether step 1's reading of `docs/working/briefs/` by listing (`:145`) goes through these checks: that is context, not changed this round.

`--check-brief` does not test existence (E2 `ok` for a path that does not exist, `docs/working/briefs/2026-13-45-x.md`). `--check-path` does test it. Requiring both covers the gap.

**Evidence:** `skills/dev-cycle/SKILL.md:72-74`, `scripts/dev-cycle.sh:188-221`, `fc22/probe1-C.utf8.log`

---

## Claim 20: "A brief's branch reaches git only after `--check-branch '<name>'` prints `ok`, and then only as `refs/heads/<name>`." (with In flight 1: "Its branch (checked as in the Rules; one that fails is a skip, and the brief is left as it is)" and step 6: "branch (one `--check-branch` prints `ok` for)")

**Location:** `skills/dev-cycle/SKILL.md:74-75`, `skills/dev-cycle/SKILL.md:246-247`, `skills/dev-cycle/SKILL.md:287`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers every place the skill hands a brief's branch to git: In flight 1 (merged?), explicitly, and In flight 3 ("the branch has no commit beyond the default branch (or does not exist yet)", `:266`), through the general rule. Does not establish what In flight 2 and 3 do for a brief whose branch failed the check ("left as it is" does not say whether a keep-or-drop entry may still be filed).

I searched every mention of a branch in SKILL.md. In step 1, "Skip any branch or worktree a brief … names" (`:145`) compares names against `git worktree list` and the merged-branch list without passing the name to git. "Its own branch" (`:27-28`) is the cycle's own `chore/dev-cycle-<date>`, not a brief's. Paraphrased — no quote available because the claim concerns the absence of other git uses across the whole file.

**Evidence:** `skills/dev-cycle/SKILL.md:27-31`, `skills/dev-cycle/SKILL.md:143-146`, `skills/dev-cycle/SKILL.md:244-271`, `skills/dev-cycle/SKILL.md:287`

---

## Claim 21: "Pass a value to any check only if it uses letters, digits, `.`, `_`, `-`, `/`, `*` and `?` and nothing else, in single quotes; a value that fails this is skipped without running anything."

**Location:** `skills/dev-cycle/SKILL.md:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that the pre-filter is no wider than any mode's own check, so the script still refuses whatever slips through. Does not establish the agent's quoting.

A value with `*` or `?` passes the pre-filter. The script then refuses it in `--check-branch` (E2 `skip a*b: not an allowed branch name`) and in `--check-write` and `--check-brief` (`pathform` without `glob`). A value starting with `-` reaches the script as an argument, not as an option (Claim 15).

**Evidence:** `skills/dev-cycle/SKILL.md:75-78`, `scripts/dev-cycle.sh:98-101`, `scripts/dev-cycle.sh:214-229`, `fc22/probe1-C.utf8.log`

---

## Claim 22a: "the entry's `**Answer:**` / `**Answered <date>:**` line, any case; not `**Answering …**`" / commit 6c8ae91: "the bold label is Answer: / Answered <date>: in any case, not Answering"

**Location:** `skills/dev-cycle/SKILL.md:254-256`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the named label forms against every real answer line in wt-devcycle's questions files as of 09:33Z. Does not establish how keep-or-drop answers will be labelled in future (none exists yet).

E4 strict mode found 16 real answer lines whose label is neither named form. Among them:
- `**Answer (2026-09-28): [1].**` (×4);
- `**Answer (2026-09-30, answers-9-30-26.txt): [1].**` (×2);
- the newest, `- **Answer (2026-10-01, in chat):** [1].` (`questions-archive.md:1832`);
- several `**Answered 2026-09-23 (`docs/human-author/…`):**` forms.

The fbc7101 wording (`**Answer…**` / `**Answered …**`) covered these. The new exact forms do not. Read literally, such a line is not an answer line and its answer would be listed as unrecognized and re-asked. That costs the user attention but misapplies nothing. Precise version: "a `**Answer…:**` or `**Answered…:**` line (any text before the colon, any case; not `**Answering…**`)". Behavioral, low.

**Evidence:** `skills/dev-cycle/SKILL.md:249-264`, `docs/working/questions-archive.md:1697`, `docs/working/questions-archive.md:1832`, `fc22/answers.log`

---

## Claim 22b: "If that text has `[1]` or `[2]` but not both, that is the option …; with neither, its first word, with a trailing `.` or `,` removed, if that is `1`, `keep`, `2` or `drop` (any case)." / commit: "[1] and [2] together are unrecognized; otherwise the first word decides, so "keep. Still wanted." reads as keep."

**Location:** `skills/dev-cycle/SKILL.md:256-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the rule's results on the real answer lines and the commit's example. Does not establish that "the text after the label colon" stops at the answer: it runs to the end of the line.

E4 lenient mode, applying the rule as written: 27 `[1]`, 19 `[2]`, 1 `keep`, 3 `both → unrecognized`, 32 unrecognized. The hedged "between [1] and [2]" (`questions-archive.md:1452`, the pass-21 residue) is now unrecognized, as intended. Two lines that give a clear `[1]` and then mention `[2]` in trailing prose also become unrecognized:
- `:1412`: "[1] supply the backstops. … [2] (narrow the hook), which the entry recommended";
- `:1697`: "[1]. … reopen with [2]".

These are re-asked, not misapplied. `:186` "keep both — neither is wrong" reads as `keep`. The commit's example "keep. Still wanted." gives `keep` by the first-word rule.

**Evidence:** `skills/dev-cycle/SKILL.md:256-264`, `docs/working/questions-archive.md:186`, `docs/working/questions-archive.md:1412`, `docs/working/questions-archive.md:1452`, `fc22/answers.log`

---

## Claim 23: test "--check-brief allows only a dated build brief" (6 refusals)

**Location:** `test/scripts/dev-cycle.bats:528-536`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the six refused shapes (own files that are not briefs, a one-digit month, an uppercase slug, AGENTS.md); does not establish refusal of an impossible date (it passes, as disclosed).

E1: ok 27.

**Evidence:** `test/scripts/dev-cycle.bats:528-536`, `fc22/bats.log`

---

## Claim 24: test title "--check-branch allows only a plain, valid branch name"

**Location:** `test/scripts/dev-cycle.bats:538-548`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title against `check_branch`; the cases the test lists all behave as asserted (E1 ok 28).

The mode checks a valid *ref* under `refs/heads/`, not a valid *branch name*. E2 printed `ok HEAD`, while `git check-ref-format --branch HEAD` fails. Precise title: "… a plain name that is a valid ref under refs/heads/". Wording (behavioral residue in Claim 15).

**Evidence:** `test/scripts/dev-cycle.bats:538-548`, `scripts/dev-cycle.sh:224-229`, `fc22/probe1-C.utf8.log`

---

## Claim 25: test "the check modes do not warn per match under an uninstalled locale" with "At most bash's own start-up warnings (one per bash process), none per match."

**Location:** `test/scripts/dev-cycle.bats:550-560`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the comment (true: 2 start-up lines, E3) and the title's reach. Does not establish anything for `--check-write`, `--check-brief` or `--check-branch`, which the test does not run.

Only `--check-path` is run. E3 confirms 2 stderr lines for the new script and 11 for d5d9121, so the test discriminates. The title says "the check modes". Precise: "--check-path does not warn …". Wording.

**Evidence:** `test/scripts/dev-cycle.bats:550-560`, `fc22/probe2.log`

---

## Claim 26: test "--check-path reports an ignored docs/working name that is not UTF-8"

**Location:** `test/scripts/dev-cycle.bats:562-569`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the test's pass on bc98571 and its failure mode on d5d9121 (reproduced outside bats); does not establish behavior for non-UTF-8 tracked names.

E1: ok 30. E3: the same setup on d5d9121 under C.UTF-8 prints `skip docs/working/*: no tracked file …`, which the test's exact-match assertion would reject.

**Evidence:** `test/scripts/dev-cycle.bats:562-569`, `fc22/bats.log`, `fc22/probe2.log`

---

## Claim 27: commit 3d839c1 message (new modes; "lists its characters one by one instead of switching LC_ALL, which printed a setlocale warning per argument and per match …"; directory filtered in one grep with its own skip reason; cap message; "29/29; shellcheck clean"; Notes on impossible dates)

**Location:** commit 3d839c1
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each bullet against the diff and E2/E3. The "one grep" part carries Claim 9's qualifier. Does not establish the 29 count by running 3d839c1 (inferred: bc98571 adds exactly one `@test`, giving 30).

The setlocale bullet matches E3's per-argument (`line 176`) and per-match (`line 182`) warnings on d5d9121. The rest matches Claims 2, 11, 12 and 14.

**Evidence:** commit 3d839c1, `fc22/probe2.log`, `fc22/probe1-C.utf8.log`

---

## Claim 28: commit bc98571 message ("--check-write's list is the cycle's own bookkeeping files …; comment and skip reason say so", "The form-rule summary names the "." component", grep filters in C via env, test fixes, "30/30; shellcheck clean")

**Location:** commit bc98571
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each bullet as worded (the commit says "comment and skip reason", and both changed). Does not establish the unchanged help line, which still says "a file the cycle writes" (Claim 3).

E1: 30/30, shellcheck output empty. The rest matches Claims 6, 10, 13 and 26.

**Evidence:** commit bc98571, `fc22/bats.log`, `fc22/shellcheck.log`

---

## Claim 29: commit 6c8ae91 message (branch and brief checks; in-cycle fixes; answer parsing; "The refusal list names directories and . components; the 50 cap says to narrow the glob; docs/dev-cycle.md matches")

**Location:** commit 6c8ae91
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers each bullet as a description of the diff. The label wording carries Claim 22a's qualifier, and "docs/dev-cycle.md matches" carries Claim 1a's path wording. Does not establish the rules' adequacy (Claims 18-22).

Each bullet corresponds to a hunk in `git diff fbc7101..6c8ae91`. Paraphrased — no quote available because the claim is a summary spanning both files' hunks, quoted piecewise in Claims 1, 16 and 18-22.

**Evidence:** commit 6c8ae91, `skills/dev-cycle/SKILL.md:66-77`, `skills/dev-cycle/SKILL.md:246-259`, `skills/dev-cycle/SKILL.md:287`, `docs/dev-cycle.md:27-31`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1a** (`docs/dev-cycle.md:27`): names `~/.claude/scripts/dev-cycle.sh`. In this repo the skill uses its own `scripts/dev-cycle.sh`, and the installed copy is absent here. Wording.
- **Claim 3** (`scripts/dev-cycle.sh:24-25`): the help line still says `--check-write` is "for a file the cycle writes", although the comment and the skip reason now say "own (bookkeeping) files". Wording, agent-facing.
- **Claim 4** (`scripts/dev-cycle.sh:100`): "needs at least one path" is also printed for `--check-branch`, which takes names. Wording.
- **Claim 9** (`scripts/dev-cycle.sh:177`, commit 3d839c1): the one-grep filter drops only a directory's tracked contents. Ignored files under a `docs/working/...` directory argument are still dropped one by one in the loop. Wording (performance).
- **Claim 18** (`skills/dev-cycle/SKILL.md:71`): "steps 1, 2, 3, 4" lists step 2, which makes no in-cycle fix. Better: "steps 1, 3 and 4 (with step 4's doc fixes)". Wording.
- **Claim 22a** (`skills/dev-cycle/SKILL.md:255`, commit 6c8ae91): the exact label forms miss 16 real answer labels, including the newest (`**Answer (2026-10-01, in chat):**`). Under a literal reading those answers are unrecognized and re-asked. Better: "`**Answer…:**` / `**Answered…:**`, not `**Answering…**`". Behavioral, low (conservative failure).
- **Claim 24** (`test/scripts/dev-cycle.bats:538`): the title says "valid branch name", but `HEAD` passes (a valid ref under refs/heads/, refused by `check-ref-format --branch`). Test wording; behavioral residue low.
- **Claim 25** (`test/scripts/dev-cycle.bats:550`): the title says "the check modes", but only `--check-path` is run. Test wording.

### Unverifiable
(none)

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass22.md`. It has:
- the required first line;
- the header fields, including `**Replication:** k=1 (loop pass, decision 031)`;
- the seven mandatory per-claim fields plus `**Legibility-target:**`;
- the attention summary.

It was not committed.

Against the brief's priority list:
- **A, character lists:** correct and complete. Every bracket keeps `-` last and treats `.`, `*` and `?` literally. The unquoted `$NAMECHARS` in `[[ =~ ]]` is intended (Claim 8). Output is identical under C and C.utf8 (Claim 7).
- **A, `--check-branch` against git's ref rules and option injection:** option injection is closed (Claim 15). The git rules are delegated to `check-ref-format refs/heads/<name>`. Residue: `HEAD` and `refs/heads/x` pass (Claims 15, 24).
- **A, `--check-brief` against `writable()`:** `isbrief` implies `writable`. The order is form, shape, writable, plainness (Claim 14).
- **A, the directory reason:** `dirok` does not look below a symlink; symlinked directories never get the directory reason (Claim 12).
- **A, `env LC_ALL=C` grep under an uninstalled locale:** only bash's 2 start-up warnings, against 11 lines before; the non-UTF-8 name gets its skip line again (Claims 7, 10).
- **A, help range:** `2,39p` is correct (Claim 5). The help's `--check-write` line keeps the old wording (Claim 3).
- **A, tests and commits:** 30/30, shellcheck clean. Two test titles overstate (Claims 24, 25).
- **B, git with a brief's branch:** every use is gated (Claim 20).
- **B, reading a brief path:** a roadmap brief path is gated (Claim 19). Step 1 lists `docs/working/briefs/` directly; that is context, unchanged.
- **B, the in-cycle fix rule:** consistent with "Undocumented is broken" (Claim 18).
- **B, answer parsing on real lines:** the both-rule fixes the hedged case. The narrowed label list misses current real forms (Claim 22a).

**Process failure:** the probe-cleanup rule was broken once (see the incident note at the top). `/workspace` main has the stray commit e28afaa, an overwritten `.gitignore`, local git identity config and stray files. The repair was denied by the permission classifier and is left to the user.
