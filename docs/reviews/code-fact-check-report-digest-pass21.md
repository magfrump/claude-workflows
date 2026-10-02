Commit: d5d9121 (A) / fbc7101 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at d5d9121; HEAD c227581 adds review docs only, `git diff --stat d5d9121 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at fbc7101; HEAD f493fc6 only merges A in, `git diff --stat fbc7101 HEAD -- skills` is empty).
**Scope:** Partial: the pass-20 fix round only. A: `git diff 546b86e..d5d9121 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of d5d9121. B: `git diff 46d3423..fbc7101 -- skills/dev-cycle/SKILL.md` plus the message of fbc7101. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 27
**Summary:** 21 verified, 4 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first. No claim below matches a logged pattern. The one Incorrect verdict (Claim 12a) is a scope overstatement, not a fabricated symbol, so nothing is appended to the log.

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc21/` (below, `fc21/`). Throwaway repos were built under one `mktemp -d` directory inside `fc21/` and removed after each probe. Every process ran under `timeout`; none outlived its command. Nothing was written to either worktree except this report. The environment's default `LC_ALL=en_US.UTF-8` is not installed (only `C`, `C.utf8`, `POSIX`), so the probes set `LC_ALL=C` or `LC_ALL=C.utf8` explicitly. Except where noted, the script ran unchanged from the worktree at d5d9121. `fc21/dev-cycle-546b86e.sh` is `git show 546b86e:scripts/dev-cycle.sh`, used only for old-versus-new comparisons.

Executed runs (times UTC, all exit 0 unless stated):
- E1 `timeout 300 bats test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` at 2026-10-02T09:14:14Z: 26/26 ok → `fc21/bats.log`. `timeout 60 shellcheck scripts/dev-cycle.sh`: empty output → `fc21/shellcheck.log`. `bash scripts/dev-cycle.sh --help` → `fc21/help.log`.
- E2 `fc21/probe1.sh` (globs, `.` forms, the cap, `--check-write` cases), run under `LC_ALL=C` and `LC_ALL=C.utf8` at 09:14:45Z → `fc21/probe1-C.log`, `fc21/probe1-Cutf8.log`. The two outputs differ only in the env line.
- E3 `fc21/probe2.sh` (the ignored-files filter on newline and non-UTF-8 names), both locales, at 09:15:03Z → `fc21/probe2-C.log`, `fc21/probe2-C.utf8.log`.
- E4 `LC_ALL=C.utf8 timeout 10 bash fc21/locale.sh` at 09:15:26Z (`local LC_ALL=C` inside a function) → `fc21/locale.log`.
- E5 `fc21/probe3.sh` (a newline name whose second line starts `docs/working/`; a non-UTF-8 name outside docs/working; date fallback for records removed from HEAD), both locales, at 09:15:40Z → `fc21/probe3-C.log`, `fc21/probe3-C.utf8.log`.
- E6 `core.ignorecase=true`, new against 546b86e, environment's own (missing) locale, at 09:17:20Z → `fc21/probe4-ignorecase.log`.
- E7 `.`-component arguments, new against 546b86e, at 09:17:39Z → `fc21/probe5-dot.log`.
- E8 `--check-path 'docs/**'` over 1,000 tracked files, new against 546b86e, at 09:17:53Z → `fc21/probe6-perf.log`.
- E9 a tracked symlink to an outside directory (the bats case) at 09:18:14Z → `fc21/probe7-linkdir.log`.
- E10 `timeout 30 python3 fc21/answers.py docs/working/questions-archive.md docs/working/questions.md` in `/workspace/.claude/wt-devcycle` at 09:18:34Z → `fc21/answers.log`. The script applies the skill's answer rule (text after the `**Answer…**`/`**Answered …**` label colon, `*` and a trailing `.` removed, first `[1]`/`[2]`, else exact `1|keep|2|drop`) to every real answer line.

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest, record or commit log).

---

## Claim 1: "--check-path instead of a digest, apply the dev-cycle skill's rule for paths taken from repo text: "ok <path>" for each file that may be read (a tracked file, or a gitignored one under docs/working/; at most 50 per argument), "skip <arg or match>: <reason>" otherwise."

**Location:** `scripts/dev-cycle.sh:18-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the read scope, the cap, and the shape of each output line; does not establish what the agent can do about matches past the cap (the line gives no count), nor how names that are not valid UTF-8 are handled (Claim 8).

The cap and both skip shapes are in `check_path()`:

```bash
# scripts/dev-cycle.sh:180-186
    n=$((n + 1))
    if [[ $n -gt $max ]]; then echo "skip $a: matches more than $max files; the rest are not listed"; break; fi
    if ! pathform "$m"; then echo "skip ${m//$'\n'/ }: not an allowed path form"
    elif ! inrepo "$m"; then echo "skip $m: reached through a symlink, or not a regular file"
    else echo "ok $m"; fi
  done < <(matches "$spec" "$a")
  [[ $n -gt 0 ]] || echo "skip $a: no tracked file (or ignored file under docs/working/) matches"
```

(excerpt starts inside `check_path()`, which begins at :174 — read.) E2: `docs/decisions/*.md` over 60 tracked files printed 50 `ok` lines (`m01` to `m50`), then `skip docs/decisions/*.md: matches more than 50 files; the rest are not listed`. An ignored `docs/working/ign1.md` passed and `skip .gitignore` named the match, not the argument.

**Evidence:** `scripts/dev-cycle.sh:174-187`, `fc21/probe1-C.log`

---

## Claim 2: "--check-write the same for a file the cycle writes: only its own files (roadmap, questions files, idea log, cycle records, briefs)."

**Location:** `scripts/dev-cycle.sh:22-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the set of paths `--check-write` accepts; does not establish that this set is everything the skill writes (Claim 12a), and does not establish any date check (`2026-99-99` passes).

`writable()` (`scripts/dev-cycle.sh:191-195`, quoted in Claim 13) admits exactly these five kinds. E2: `ok` for `docs/roadmap.md`, `docs/working/questions.md`, `docs/working/questions-archive.md`, `docs/working/idea-log.md`, `docs/working/cycles/cycle-2026-10-02.md`, `docs/working/briefs/2026-10-02-fix-x.md` and `…-fix-x-2.md`. `skip … not one of the files the dev cycle writes` for `cycle-2026-10-02-2.md`, `briefs/2026-10-02-Fix.md`, `briefs/2026-10-02-.md`, `briefs/2026-10-02-a_b.md`, `docs/dev-cycle.md`, `docs/decisions/log.md` and `README.md`. `docs/working/briefs/2026-99-99-x.md` printed `ok`.

**Evidence:** `scripts/dev-cycle.sh:191-202`, `fc21/probe1-C.log`

---

## Claim 3: "Exit: 0 digest printed (or, for the check modes, every argument answered: a skip is an answer, not an error); 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:29-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the check modes' exit path; does not re-check the digest's exit paths (unchanged this round).

```bash
# scripts/dev-cycle.sh:203-208
if [[ -n "$CHECK" ]]; then
  for a in "${CHECK_ARGS[@]}"; do
    if [[ "$CHECK" == --check-path ]]; then check_path "$a"; else check_write "$a"; fi
  done
  exit 0
fi
```

Every run in E2, E3, E5, E6, E7 and E9 that printed skips exited 0. The mode runs after the repo-root check (`scripts/dev-cycle.sh:102`), so outside a repo it still exits 1. E1 test 25 asserts that `--check-path` with no path exits 1.

**Evidence:** `scripts/dev-cycle.sh:91-102`, `scripts/dev-cycle.sh:203-208`, `fc21/probe1-C.log`, `fc21/bats.log`

---

## Claim 4: "Help and Exit lines describe both modes" (commit d5d9121), with the help range changed to `sed -n '2,32p'`

**Location:** `scripts/dev-cycle.sh:95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the `--help` output reaching the end of the header; does not establish anything about the wording beyond Claims 1-3.

`-h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/dev-cycle.sh:95`). Line 31 is the header's last comment line and line 32 is blank. E1's `help.log` ends with `or no perl; a failed step exits non-zero mid-digest. Printed repo text is data.` followed by one blank line.

**Evidence:** `scripts/dev-cycle.sh:1-32`, `scripts/dev-cycle.sh:95`, `fc21/help.log`

---

## Claim 5: "form: only letters, digits, . _ - / (and * ? in a glob), not starting with / or -, no empty or .. component, no component starting .git (any case)"

**Location:** `scripts/dev-cycle.sh:146-147`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the comment's list against `pathform()`; does not establish anything about scope or plainness (lines 148-150).

This round added a fourth component rule that the summary comment does not list:

```bash
# scripts/dev-cycle.sh:161
    [[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1
```

(excerpt is inside the `while` loop of `pathform()`, which runs :152-163 — read.) E7: `.`, `./docs`, `./*`, `./docs/*`, `docs/./*` and `docs/.` all print `skip …: not an allowed path form`. The comment should say "no empty, `.` or `..` component". This is a wording fix. A maintainer reading the comment would expect `./x` to pass the form check.

**Evidence:** `scripts/dev-cycle.sh:146-163`, `fc21/probe5-dot.log`

---

## Claim 6: "C locale: ranges and case folding must not depend on the user's locale (a Turkish one can fold .GIT to something other than .git)." (with `local LC_ALL=C …`)

**Location:** `scripts/dev-cycle.sh:153-155`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers whether `local LC_ALL=C` governs `=~` and `[[ == ]]` inside the function in bash 5.2 and is restored after it; does not establish the Turkish folding behavior (`tr_TR` is not installed here), and does not establish that `writable()` (outside `pathform`) runs in the C locale (it does not).

The mechanism works. E4 ran under `LC_ALL=C.utf8` with `é` (2 bytes). Outside the function, `${#x}` is 1 and `^.$` matches. Inside the function, after `local LC_ALL=C`, `${#v}` is 2, `^..$` matches, and `?? ` matches. After the return, `LC_ALL=C.utf8` and the length is 1 again. The wording is imprecise: `pathform()` no longer case-folds anything. The `${c,,}` that the Turkish example describes was replaced in this same change by explicit classes (`[.][gG][iI][tT]*`, `scripts/dev-cycle.sh:161`). The C locale now governs only the `[A-Za-z0-9…]` ranges and byte-wise matching. A precise comment would be "C locale: the character ranges must not depend on the user's locale; .git* is matched by explicit case classes, not by folding." This is a wording fix.

Side effect seen in E6 (behavioral, low, outside the claim): when the caller's `LC_ALL` names a locale that is not installed, every return from `pathform()` makes bash re-set the locale. Each one prints `…/dev-cycle.sh: line 176: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)` to stderr, once per argument and once per match. 546b86e printed only the two start-up warnings. This sandbox has exactly that setup. The `ok`/`skip` lines on stdout are unchanged.

**Evidence:** `scripts/dev-cycle.sh:152-163`, `fc21/locale.log`, `fc21/probe4-ignorecase.log`

---

## Claim 7a: "The form check … matches .git* by explicit case classes …; "." is refused as a component" (commit d5d9121)

**Location:** `scripts/dev-cycle.sh:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `.git*` refusal in any ASCII case and refusal of `.` components; does not establish any wanted exceptions (`.gitignore`, `.github/` are refused by design, per pass 20).

The line is quoted in Claim 5. E2: `.Git/x`, `.GIT`, `.gitignore` and `.git` all printed `skip …: not an allowed path form`. E7: every `.`-component form was refused. E1 test 25 asserts `skip .Git/x: not an allowed path form`.

**Evidence:** `scripts/dev-cycle.sh:161`, `fc21/probe1-C.log`, `fc21/probe5-dot.log`, `test/scripts/dev-cycle.bats:504-507`

---

## Claim 7b: "so "." or "./docs" no longer lists a tree." (commit d5d9121)

**Location:** commit d5d9121 message
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the old and new output for `.`-component arguments; does not re-measure git's internal listing cost.

At 546b86e, `.` and `./docs` already printed `skip .: no tracked file …` and `skip ./docs: no tracked file …` (E7). Nothing was listed in the output. What "lists a tree" refers to is the cost: git walked the whole subtree before the plain-path filter discarded every match. The pass-20 performance review measured 1.9 s for `.`. That cost is gone now. Glob forms did print matches before: at 546b86e `./*` printed `ok r.md` and `./docs/*` printed `ok docs/a.md`. Now both are refused. The precise version: "`.` components are refused up front, so `.`/`./docs` no longer make git walk a tree, and `./`-prefixed globs no longer match." This is a wording fix. The new refusal is narrower, never broader.

**Evidence:** `scripts/dev-cycle.sh:161`, `fc21/probe5-dot.log`

---

## Claim 8: "NUL-separated tracked files, then ignored ones under docs/working/" (matches() header) and "filtered with one grep instead of a byte-wise read loop" (commit d5d9121)

**Location:** `scripts/dev-cycle.sh:164-172`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what the grep filter passes for ASCII names, newline-embedded names and non-UTF-8 names in C and UTF-8 locales; does not establish behavior under other grep implementations (the script's `grep` resolves to GNU grep 3.8 here).

```bash
# scripts/dev-cycle.sh:164-173
matches() {  # $1 pathspec, $2 the argument; NUL-separated tracked files, then ignored ones under docs/working/
  local fixed="${2%%[*?]*}"
  GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1"
  # Ignored files count only under docs/working/; skip the query when the
  # argument's fixed prefix cannot lead there (it lists every ignored match).
  if [[ "$fixed" == docs/working/* || docs/working/ == "$fixed"* ]]; then
    GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
      | { grep -z '^docs/working/' || true; }
  fi
}
```

The filter is correct for any valid name. E5: an ignored `build/a<LF>docs/working/x.md` is not passed, because `^` anchors only at the start of a NUL record. E3 and E5: ignored files outside docs/working never reach the output. It diverges from the old byte-wise loop in one case. In a UTF-8 locale, GNU grep drops an ignored `docs/working/` name that is not valid UTF-8 and prints `grep: (standard input): binary file matches` to stderr, once per argument. E3 under `C.utf8`: `docs/working/ign\376.md` is missing from the filter's output and from the `**` run, and the stderr line appears three times. Under `C`, the same file reaches `check_path` and prints `skip docs/working/ign\376.md: not an allowed path form`. Such a file would be refused anyway, so no `ok` changes. What changes: the skip line the skill says to record is missing, and the agent sees an unexplained grep message. A non-UTF-8 name outside docs/working caused no message (E5). Precise version: "…then ignored ones under docs/working/ (in a UTF-8 locale, names that are not valid UTF-8 are dropped with a grep warning)". Running grep under `LC_ALL=C` would restore parity. This is behavioral but low severity: refused files only, and it requires a non-UTF-8 ignored file under docs/working.

**Evidence:** `scripts/dev-cycle.sh:164-187`, `fc21/probe2-C.log`, `fc21/probe2-C.utf8.log`, `fc21/probe3-C.utf8.log`

---

## Claim 9: "skip the query when the argument's fixed prefix cannot lead there (it lists every ignored match)." / commit: "The ignored-files query runs only when the argument can lead under docs/working/"

**Location:** `scripts/dev-cycle.sh:165-169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers every allowed-form argument (the charset admits no `[`, `\` or magic, so the only wildcards are `*` and `?`, and a `:(glob)`/`:(literal)` match always starts with the argument's text before its first wildcard); does not establish case-insensitive matching under `core.ignorecase` (git's pathspec is case-sensitive there too: E6, unchanged from 546b86e).

The quote is in Claim 8. `fixed` is the argument up to its first `*` or `?`. The query runs when `fixed` already lies under `docs/working/`, or when `docs/working/` begins with `fixed`. The second case covers `fixed` = `""`, `d`, `docs/`, `docs/w`, `docs/working`. Any match must begin with `fixed`. When neither condition holds, no match can begin with `docs/working/`, so skipping the query loses nothing. E2, with an ignored `docs/working/ign1.md`: `*/working/ign1.md`, `d*/working/*` and `?ocs/working/ign1.md` each printed `ok docs/working/ign1.md`. `docs/*/idea.md` (fixed `docs/`) ran the query and printed the tracked `ok docs/other/idea.md`. `docs/w*` and `docs/working*` ran it and correctly found nothing, because `*` does not cross `/` under `:(glob)`. E3: `**`, `docs/working/**` and `*/working/*` all listed the ignored files, including `docs/working/sub/idea.md` inside a wholly ignored directory, for the globs that cross directories. No argument from the brief's list skips the query when it should not.

**Evidence:** `scripts/dev-cycle.sh:164-173`, `fc21/probe1-C.log`, `fc21/probe2-C.log`, `fc21/probe4-ignorecase.log`

---

## Claim 10: "--check-path lists at most 50 files per argument" (commit d5d9121); `max=50` with `break`

**Location:** `scripts/dev-cycle.sh:175-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the count, what is printed at the cap, and determinism; does not establish how an agent should proceed past the cap (the line gives no total).

The excerpt is in Claim 1. `n` counts matches that survive the plain-path filter, including those that end in a `skip`, so at most 50 lines of any kind precede the cap line. With exactly 50 matches, no cap line is printed. E2: 50 `ok` lines (`m01`…`m50`, index order) and then the cap line. Two back-to-back runs were byte-identical (`identical`). Under `**`, `skip .gitignore` was one of the 50. The cut is deterministic: tracked matches come first in index (sorted) order, then ignored ones in git's sorted directory order. The early `break` closes the process substitution. git and grep then stop on SIGPIPE with no message, and the exit stays 0. E1 test 25 asserts the cap line.

**Evidence:** `scripts/dev-cycle.sh:174-187`, `fc21/probe1-C.log`, `fc21/bats.log`

---

## Claim 11: "a broad glob cost ~4.5 ms per match: 231 s for **/*.md on a 50k-file repo" (commit d5d9121)

**Location:** commit d5d9121 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the per-match order of magnitude at 546b86e and the cap's effect; does not re-run the 50k-file repo (the 231 s figure is the pass-20 performance review's measurement on another machine).

E8, 1,000 tracked files and `--check-path 'docs/**'`: 546b86e took 3.73 s for 1,000 lines (~3.7 ms per match). d5d9121 took 0.21 s for 51 lines. 231 s / 50,000 = 4.6 ms, consistent with "~4.5 ms" on slower hardware (paraphrased — no quote available because the timing comes from a wall-clock run, not from a code line).

**Evidence:** `fc21/probe6-perf.log`, `scripts/dev-cycle.sh:175-181`

---

## Claim 12a: "The only files the cycle writes" (and the skip reason "not one of the files the dev cycle writes")

**Location:** `scripts/dev-cycle.sh:188`, `scripts/dev-cycle.sh:199`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the comment's and skip message's claim about what the dev cycle writes, checked against skills/dev-cycle/SKILL.md at fbc7101; does not establish whether in-cycle fixes are meant to go through `--check-write` (the skill is ambiguous: Claim 19).

```bash
# scripts/dev-cycle.sh:188-190
# The only files the cycle writes; anything else named in repo text (a roadmap
# line pointing at an instruction file, say) is refused, so it is never treated
# as a brief and written to.
```

The skill also has the cycle write other files in-cycle. `skills/dev-cycle/SKILL.md:38-39`: "the doc is written in-cycle if that is mechanical". `:146`: "Fix what is mechanical now, one commit per concern." `:167`: "if it is mechanical, fits in one commit and needs no choice, do it in-cycle". `:182`: "fix it if mechanical". None of those targets can pass `writable()`. The skip line tells an agent that such a file is "not one of the files the dev cycle writes", which the skill's own steps contradict. An agent that also reads `SKILL.md:68-70` ("Before writing a file … write only on `ok`") as covering every write would drop the required in-cycle doc fixes. Precise version: "The cycle's own bookkeeping files (record, briefs, idea log, roadmap, questions files)", with a skip reason such as "not one of the dev cycle's own files". This is wording in the code, but it has a behavioral consequence for the agent because of the scope conflict.

**Evidence:** `scripts/dev-cycle.sh:188-201`, `skills/dev-cycle/SKILL.md:37-41`, `skills/dev-cycle/SKILL.md:146`, `skills/dev-cycle/SKILL.md:166-168`, `skills/dev-cycle/SKILL.md:181-183`

---

## Claim 12b: "anything else named in repo text (a roadmap line pointing at an instruction file, say) is refused, so it is never treated as a brief and written to." / commit: "a roadmap line naming any other tracked file is no longer treated as a brief and written to"

**Location:** `scripts/dev-cycle.sh:188-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `--check-write` refusing non-cycle files, tracked or not, combined with the skill's rule at `SKILL.md:70-71`; does not establish that an agent applies that rule (prose, not code), nor protection against a roadmap pointing at a different, existing dated brief (that passes).

E2: `docs/dev-cycle.md`, `docs/decisions/log.md` and `README.md` (tracked) printed `skip …: not one of the files the dev cycle writes`. E1 test 26 asserts the same for `AGENTS.md`, `scripts/x.sh` and `.env`. The skill makes this the brief test: "A roadmap brief path counts as a brief only if `--check-write` prints `ok` for it." (`skills/dev-cycle/SKILL.md:70-71`).

**Evidence:** `scripts/dev-cycle.sh:191-202`, `test/scripts/dev-cycle.bats:511-525`, `fc21/probe1-C.log`, `fc21/bats.log`

---

## Claim 13: `writable()` matches the files the skill names in its write rule (commit: "--check-write allows only the cycle's own files (roadmap, questions files, idea log, cycle records, dated briefs)")

**Location:** `scripts/dev-cycle.sh:191-195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers each file the skill names as written (record, brief, idea log, roadmap, questions files) and each brief edit (Status/Asked/Applied/Kept lines in existing dated briefs); does not cover the in-cycle fix targets (Claim 12a), nor `questions.sh`'s own writes (the script, not the agent, writes them, so they need no check).

```bash
# scripts/dev-cycle.sh:191-195
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ \
    || "$1" =~ ^docs/working/briefs/[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$ ]]
}
```

Against the skill: the record is `docs/working/cycles/cycle-YYYY-MM-DD.md`, updated in place if one exists for today, so there is no `-2` variant (`SKILL.md:288`). Briefs are `docs/working/briefs/YYYY-MM-DD-<slug>.md` with "lowercase letters, digits and hyphens only", `-2`/`-3` on collision (`SKILL.md:277-278`), which matches `[a-z0-9-]+`. The idea log is `docs/working/idea-log.md` (`SKILL.md:79`), the roadmap is `docs/roadmap.md` (`SKILL.md:223`), and the questions files are `docs/working/questions.md` and the archive. Nothing named is missing. `questions-archive.md` is extra but harmless: the agent only reads it, and `questions.sh archive` writes it. The regex runs in the caller's locale, not C. Its `[a-z]` range was not tested in a locale with non-codepoint collation (none is installed). The input has already passed the ASCII-only `pathform` (paraphrased — no quote available because this is about the absence of a `LC_ALL` in `writable()`).

**Evidence:** `scripts/dev-cycle.sh:191-202`, `skills/dev-cycle/SKILL.md:79`, `skills/dev-cycle/SKILL.md:223`, `skills/dev-cycle/SKILL.md:277-278`, `skills/dev-cycle/SKILL.md:288`, `fc21/probe1-C.log`

---

## Claim 14: "a record the map missed (a name git quotes) that is absent from HEAD prints "never, uncommitted" without a full walk to prove it …, even if it was committed once and later removed. A plain-named record keeps the map's date, removal included."

**Location:** `scripts/dev-cycle.sh:311-315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the four cases (plain or quoted name, present in or removed from HEAD); does not re-measure the "~1 s per record" figure (unchanged text from pass 20).

```bash
# scripts/dev-cycle.sh:316-318
  if [[ -z "${last_date[$f]+set}" ]] && git cat-file -e "HEAD:$f" 2>/dev/null; then
    d="$(git log -1 --format=%ad --date=short -- "$f")"
  fi
```

(excerpt is inside the record loop that starts at :307 and continues past :318 — read to the heading print.) E5, records committed 2026-09-05, with 003 and 004 removed 2026-09-06 and then re-created untracked: `001-plain.md` → `2026-09-05`, `002-q"t.md` → `2026-09-05` (HEAD fallback), `003-plaingone.md` → `2026-09-06` (map date of the removal), `004-q"gone.md` → `never, uncommitted`. E1 test 13 now asserts the staged quoted case (`test/scripts/dev-cycle.bats:264-268`).

**Evidence:** `scripts/dev-cycle.sh:307-320`, `fc21/probe3-C.log`, `test/scripts/dev-cycle.bats:264-268`

---

## Claim 15: "A symlinked parent directory, ** across directories, a case variant, a glob over too many files."

**Location:** `test/scripts/dev-cycle.bats:498-499`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what the four cases under this comment assert; does not establish that the symlinked-parent refusal path in `inrepo()` is tested elsewhere.

```bash
# test/scripts/dev-cycle.bats:504-508
    run --separate-stderr bash "$DC" --check-path 'docs/working/linkdir/f.md' 'docs/**' '.Git/x' 'docs/decisions/*.md'
    [[ "$output" == *"skip docs/working/linkdir/f.md: no tracked file"* || "$output" == *"skip docs/working/linkdir/f.md: reached through a symlink"* ]] || { echo "$output"; return 1; }
    [[ "$output" != *"ok docs/working/linkdir"* ]]
    [[ "$output" == *"skip .Git/x: not an allowed path form"* ]]
    [[ "$output" == *"skip docs/decisions/*.md: matches more than 50 files"* ]] || { echo "$output" | tail -3; return 1; }
```

(excerpt ends :508; the enclosing `@test` closes at :509 — read.) `docs/**` is passed but nothing asserts its output, so "** across directories" is not tested here. The `git add -A` at :502 commits `linkdir` as a tracked symlink. git does not list files below it, so the run takes the "no tracked file" branch, never the symlink branch (E9 reproduces this: `skip docs/working/linkdir/f.md: no tracked file …`). The test still guards against an `ok`. Precise version: name the `**` case as unasserted, or add an assertion. This is a test-wording issue.

**Evidence:** `test/scripts/dev-cycle.bats:473-509`, `fc21/probe7-linkdir.log`

---

## Claim 16: "Tests: write scope, symlinked parent directory, .Git, the 50 cap, a staged quoted record. 26/26; shellcheck clean." (commit d5d9121)

**Location:** commit d5d9121 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers presence of each named case and the counts; does not establish the strength of the symlinked-parent assertion (Claim 15).

E1: 26 `ok`, 0 `not ok`, and `grep -c '^@test'` is 26. shellcheck printed nothing. Cases: write scope at `test/scripts/dev-cycle.bats:516-523`, symlinked parent and `.Git` and the cap at `:500-508`, staged quoted record at `:264-268`.

**Evidence:** `test/scripts/dev-cycle.bats:264-268`, `test/scripts/dev-cycle.bats:498-525`, `fc21/bats.log`, `fc21/shellcheck.log`

---

## Claim 17: "only after `~/.claude/scripts/dev-cycle.sh --check-path '<path or glob>' …` (inside claude-workflows, its own `scripts/dev-cycle.sh`) prints `ok <path>`"

**Location:** `skills/dev-cycle/SKILL.md:64-65`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the install path that the payload produces; does not establish that this container has it now (`~/.claude/scripts/dev-cycle.sh` is absent because the branch is not merged or installed yet).

`devcontainer-config/link-claude-home.sh:50` installs `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`, and `devcontainer-config/install.sh:135` stages `scripts`. Both comments say helpers are called "by their installed path, ~/.claude/scripts/". Here `~/.claude/scripts` is a symlink to `/opt/claude-workflows/scripts`, which holds `questions.sh` but not yet `dev-cycle.sh`. Step 0 (`SKILL.md:101`) uses the same path.

**Evidence:** `devcontainer-config/link-claude-home.sh:43-50`, `devcontainer-config/install.sh:125-135`, `skills/dev-cycle/SKILL.md:101`

---

## Claim 18: "`--check-path` allows tracked files and gitignored files under `docs/working/`, at most 50 per argument, never a symlink, a directory, `..`, `.git*` or any other untracked file."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers each listed property against E2, E3, E7 and E9; does not establish that it lists everything refused (`.` components are refused too, and non-UTF-8 ignored names drop silently in a UTF-8 locale: Claim 8).

This is the `--check-path` scope, now stated separately from `--check-write` (pass 20's Claim 22). E2/E3: tracked and ignored docs/working files pass, ignored files elsewhere are absent, and the cap holds. E9: a directory (`docs/working/linkdir`) prints `skip … reached through a symlink`. E7 and pass-20's E3 cover `..`, `.git*` and untracked files.

**Evidence:** `scripts/dev-cycle.sh:152-187`, `fc21/probe1-C.log`, `fc21/probe2-C.log`, `fc21/probe7-linkdir.log`

---

## Claim 19: "Before writing a file (the record, a brief, the idea log, the roadmap, the questions files), run the same script with `--check-write '<path>'` and write only on `ok`; it allows only those files."

**Location:** `skills/dev-cycle/SKILL.md:68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers "it allows only those files" against `writable()`; does not resolve whether "Before writing a file" covers the in-cycle fixes at `SKILL.md:38-39, 146, 167, 182`, which `--check-write` refuses (if it does, those steps cannot run; see Claim 12a).

Claims 2 and 13 show `--check-write` accepts exactly these five kinds. Read with the parenthetical as the full list of writes the rule governs, the sentence is accurate. The other reading, every write, conflicts with the skill's own in-cycle fix steps.

**Evidence:** `scripts/dev-cycle.sh:191-202`, `skills/dev-cycle/SKILL.md:68-70`, `fc21/probe1-C.log`

---

## Claim 20: "A roadmap brief path counts as a brief only if `--check-write` prints `ok` for it." / commit fbc7101: "(now limited in code to the dated briefs directory)"

**Location:** `skills/dev-cycle/SKILL.md:70-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers what `--check-write` accepts under docs/working/briefs/; does not establish that the brief also passes `--check-path` before it is read (a separate rule, `SKILL.md:61-66`), nor whether a roadmap line names a dated brief that belongs to another item.

E2: `docs/working/briefs/2026-10-02-fix-x.md` → `ok`. Undated and uppercase brief names, and every non-briefs path, print `skip … not one of the files the dev cycle writes`. A brief path in a roadmap that resolves to a non-brief file is therefore not a brief.

**Evidence:** `scripts/dev-cycle.sh:191-195`, `fc21/probe1-C.log`

---

## Claim 21: "Pass a path to either check only if it uses letters, digits, `.`, `_`, `-`, `/`, `*` and `?` and nothing else, in single quotes; a path that fails this is skipped without running anything. Every skip, with its reason, goes in the record under `## Skipped inputs`."

**Location:** `skills/dev-cycle/SKILL.md:71-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency of the pre-filter with `pathform()`'s charset and the presence of the record section; does not establish that every refusal produces a skip line (Claim 8's dropped names do not).

The pre-filter charset equals `pathform`'s glob set `'^[A-Za-z0-9._/*?-]+$'` (`scripts/dev-cycle.sh:156`). Inside single quotes those characters need no escaping. The record template has `## Skipped inputs` (`skills/dev-cycle/SKILL.md:301`). The new sentence makes pre-filter skips recorded too, as the commit says.

**Evidence:** `scripts/dev-cycle.sh:155-157`, `skills/dev-cycle/SKILL.md:71-74`, `skills/dev-cycle/SKILL.md:301`

---

## Claim 22: "the line they wrote (`Q-NNN: …`, or the entry's `**Answer…**` / `**Answered …**` line), never the options table, taking only the text after that line's label colon, with `*` and a trailing `.` removed. The option is the first `[1]` or `[2]` in that text …" (commit fbc7101: "the option is read from the text after the answer line's label colon (`**Answered DATE: …**`), with * and a trailing . removed")

**Location:** `skills/dev-cycle/SKILL.md:249-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the rule applied to all 81 real answer lines in questions.md and the archive; does not establish correct reading of hedged answers, or of a bare keep/drop followed on the same line by prose (the "line" runs to the end of the paragraph line, past the closing `**`).

E10 matched all four label shapes in the files: `**Answered DATE: …**`, `**Answered DATE (…): …**`, `**Answer (DATE): [1].**` and `- **Answer (DATE, in chat):** [1].` In each, the label colon isolates the answer: 30 read as `[1]`, 19 as `[2]`, 32 as unrecognized (prose such as `yes, fatal`, or `[3] …` answers). An unrecognized answer is re-asked, never misapplied. One real line shows the residue: `**Answered 2026-09-27: between [1] and [2].**` (`docs/working/questions-archive.md:1452`) reads as `[1]`. On a keep-or-drop entry, a hedge like that would set `Kept:`. Its cost is one 14-day deferral, and it needs a hedged answer. Whitespace trimming before the exact-match test is implied but not stated.

**Evidence:** `skills/dev-cycle/SKILL.md:244-258`, `docs/working/questions-archive.md:1452`, `docs/working/questions-archive.md:1697`, `docs/working/questions-archive.md:1832`, `fc21/answers.log`

---

## Claim 23: "(the user answers on the next keep-or-drop entry, which step 3 files; a second reply on this one is not read)"

**Location:** `skills/dev-cycle/SKILL.md:255-257`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the sequencing between sub-steps 2 and 3 of In flight; does not cover a brief whose branch has gained commits (step 3 then files nothing, which is the intended outcome).

An unrecognized answer adds the ID to `Applied:` and does not set `Kept:` (`SKILL.md:254-258`). Step 3 runs next in the same cycle: "if the brief is still open, no ID on its `Asked:` line is still unanswered, and the branch has no commit beyond the default branch … 14 days after the brief's last `Kept:` date (none yet: the brief's own date), file one `you: judgment` entry" (`SKILL.md:259-262`). The answered ID no longer blocks, and `Kept:` is unchanged, so a new entry is filed. The old ID is on `Applied:`, and sub-step 2 reads only IDs "not yet on its `Applied:` line" (`SKILL.md:248`), so a second reply on it is never read.

**Evidence:** `skills/dev-cycle/SKILL.md:244-265`

---

## Claim 24: "branch (letters, digits, `.`, `_`, `-`, `/`, not starting with `-`)" / commit: "a brief's branch name uses a fixed character set"

**Location:** `skills/dev-cycle/SKILL.md:281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the presence of the rule in the brief template; does not establish enforcement (nothing in code checks it), nor that every such name is a valid git ref (`a..b` or `x/` fit the charset but are not).

The text is quoted in the claim title from `skills/dev-cycle/SKILL.md:281`. It matches the commit's description.

**Evidence:** `skills/dev-cycle/SKILL.md:275-284`

---

## Claim 25: commit fbc7101 summary ("A roadmap brief path counts as a brief only if --check-write prints ok …; the questions files are in the write list. The rule calls the installed ~/.claude/scripts/dev-cycle.sh …, and states each mode's scope separately. … Paths skipped before any check are recorded too")

**Location:** commit fbc7101 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers each bullet against the diff `46d3423..fbc7101`; does not establish the bullets' completeness against pass-20 findings.

Each bullet has a matching hunk: the brief-path sentence (`SKILL.md:70-71`), "the questions files" (`:69`), the installed path (`:64-65`), the separate `--check-path` scope (`:66-68`) and `--check-write` scope (`:70`), the answer-label rule (`:250-251`), re-answer wording (`:255-257`), recorded pre-filter skips (`:72-74`), and the branch charset (`:281`) (paraphrased — no quote available because this is a bullet-to-hunk mapping across the diff; the hunks are quoted in Claims 17-24).

**Evidence:** `skills/dev-cycle/SKILL.md:61-76`, `skills/dev-cycle/SKILL.md:244-258`, `skills/dev-cycle/SKILL.md:275-284`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12a** (`scripts/dev-cycle.sh:188`, `:199`): "The only files the cycle writes" and the skip reason "not one of the files the dev cycle writes" are false against the skill. Steps 1, 3 and 4 and the "Undocumented is broken" rule write other files in-cycle. Reword to "the cycle's own bookkeeping files", and state in SKILL.md:68-70 whether in-cycle fixes go through `--check-write`. Wording in code, behavioral for the agent through the scope conflict.

### Stale
- **Claim 5** (`scripts/dev-cycle.sh:146-147`): the form summary omits the new `.`-component refusal. Say "no empty, `.` or `..` component". Wording.

### Mostly Accurate
- **Claim 6** (`scripts/dev-cycle.sh:153-155`): `local LC_ALL=C` works (E4), but `pathform()` no longer case-folds, so the Turkish-folding rationale describes removed code. Wording. Side observation, behavioral and low: with an uninstalled `LC_ALL`, each `pathform` return prints a bash setlocale warning to stderr (E6).
- **Claim 7b** (commit d5d9121): "." and "./docs" already printed a skip at 546b86e. What is gone is git's internal tree walk, plus `./`-prefixed globs that did print `ok`. Wording.
- **Claim 8** (`scripts/dev-cycle.sh:164-172`): in a UTF-8 locale, `grep -z` drops ignored docs/working names that are not valid UTF-8 and prints `grep: (standard input): binary file matches` to stderr. The old loop printed a skip line. Behavioral, low: those files are refused either way, but the skip line the record needs is missing.
- **Claim 15** (`test/scripts/dev-cycle.bats:498-499`): `docs/**` is passed but never asserted, and the symlinked-parent case exercises the "no tracked file" path, not the symlink path. Test wording.

### Unverifiable
(none)

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass21.md`. It has the required first line, the header fields (including `**Replication:** k=1 (loop pass, decision 031)`), the seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary.

Against the brief's priority list:
- **A, `writable()` against every file the skill writes:** every file the write rule names is covered, and `questions-archive.md` is a harmless extra (Claim 13). Missing: the in-cycle fix targets of steps 1, 3 and 4, which the comment's "only files the cycle writes" denies exist (Claim 12a, the round's one Incorrect).
- **A, the cap:** an agent sees up to 50 `ok`/`skip` lines and then `skip <arg>: matches more than 50 files; the rest are not listed`, with no total. The cut is deterministic (index order, then sorted ignored files; two runs identical) (Claim 10).
- **A, C locale:** `local LC_ALL=C` does govern `=~` and `[[ == ]]` inside the function in bash 5.2.15 and is restored on return (E4). The comment's folding rationale is out of date (Claim 6). With a missing caller locale, stderr gets one warning per check.
- **A, the ignored-query prefix test:** correct and complete for every allowed-form argument. `*/working/x`, `d*/working/*`, `?ocs/…` and `docs/*/idea.md` all still run the query (Claim 9). The grep filter adds a UTF-8-locale divergence for non-UTF-8 names (Claim 8).
- **A, tests and d5d9121:** 26/26, shellcheck clean, every named case present (Claim 16). Two cases in the new block assert less than their comment says (Claim 15). The "." wording in the commit overstates (Claim 7b).
- **B, instructions against the modes' output:** the installed path, the per-mode scopes, the brief-path test and the pre-filter all match (Claims 17-21). The write rule's reach over in-cycle fixes is ambiguous (Claim 19 residue, tied to 12a).
- **B, answer parsing on real lines:** the label-colon rule extracts the answer on all 81 real answer lines (30 `[1]`, 19 `[2]`, 32 unrecognized, which are re-asked rather than misapplied). One real hedged answer, "between [1] and [2]", would read as `[1]` (Claim 22 residue).
