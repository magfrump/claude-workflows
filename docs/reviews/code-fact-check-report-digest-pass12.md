Commit: 71e618d (A) / 8286c2b (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 71e618d; HEAD be7cc4e adds review docs only). B: `/workspace/.claude/wt-devcycle` (content at 8286c2b; HEAD 99c03fc merges A, and `git diff --stat 8286c2b HEAD -- skills/dev-cycle/SKILL.md docs/working/questions.md` is empty). **Working-tree note:** at 22:50:03–22:50:17 someone else wrote uncommitted edits to A's `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats` (a `blocker()` rewrite) while this review ran. Every verdict below is on 71e618d. The bats, shellcheck, probe and walk runs were repeated at 22:50:40–22:50:48 on files taken from `git show 71e618d:…` (`fc12/pin71e618d/`), and they match the earlier runs exactly (`diff` empty for the probes and the walk; bats 22/22 both times).
**Scope:** Partial: the pass-11 fix round only. A: `git diff c034a75..71e618d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of commits e08d526, 5dd5377 and 71e618d. B: `git diff a218ad8..8286c2b -- skills/dev-cycle/SKILL.md docs/working/questions.md` plus the message of commit 8286c2b. Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 28
**Summary:** 16 verified, 7 mostly accurate, 1 stale, 4 incorrect, 0 unverifiable

Execution logs (scratch, not committed) are all under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc12/`:
- `bats-pinned.log`: `bats fc12/pin71e618d/test/scripts/dev-cycle.bats`, exit 0, 2026-10-01T22:50:40-07:00, 22/22.
- `shellcheck-pinned.log`: empty, exit 0, 22:50:47.
- `probe-pinned.log` (script `probe-pinned.sh`), exit 0, 22:50:47. Scenarios S1–S7, each in a throwaway repo under `mktemp -d`.
- `walk-pinned.log` (script `walk-pinned.sh`), exit 0, 22:50:48. Lines 92–114 of the script, `eval`'d in a temp dir, run on edge-case paths.
- `bats-new-tests-on-{c034a75,e08d526,5dd5377}.log` (script `oldcode.sh`), 22:48:56–22:49:07: the 71e618d test file run against the older script versions, as a check that the tests tell old code from new. Tests 16 and 17 fail in every copy because `questions.sh` was not copied next to those scripts. That failure comes from the setup, not from the code.

All commands ran with cwd `/workspace/.claude/wt-digest`, or in their own `mktemp -d` repo for the probes, and under `timeout`. Nothing was written to either worktree except this report.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. The closest class in it is a measured value or reference quoted from an artifact set that does not contain it. Claim 22 ("New test 3") is a wrong index for a test that does exist (it is test 10), not an invented symbol, so it is not logged. This run writes nothing outside the report in any case.

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human answering Q-103 or reading the record).

---

## Claim 1: "(the seed's list: hooks, enforcement and harness settings, instruction files, skills/, … devcontainer-config/)"

**Location:** `docs/working/questions.md:57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers that Q-103 option [2] now matches the seed's rule 3 word for word, including "harness settings". It does not establish that the list is complete for this repo.

The seed reads `harness settings, instruction files, \`skills/\`, \`workflows/\`, \`scripts/\`, \`guides/\`,` (`docs/working/seed-build-loop-handoff.md:34`). Q-103 now says `hooks, enforcement and harness settings, instruction files, skills/, …` (`docs/working/questions.md:57`). The items and their order are the same. Pass 11's "harness config" difference is gone.

**Evidence:** `docs/working/questions.md:57`, `docs/working/seed-build-loop-handoff.md:33-35`

---

## Claim 2: "An input that exists in some form but is not a plain file (reached through a symlink, or not a regular file) is skipped, not absent: it is named where it would have been read and listed in section 8."

**Location:** `scripts/dev-cycle.sh:96-99`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what `skipped()` does when one of the input's parents fails. It does not establish anything about inputs whose parents are all plain; for those the comment still holds.

Since 5dd5377, an input below a parent that is not a plain directory is skipped whether or not the input itself exists, and section 8 lists the parent, not the input: `plaindir "$p" || { SKIPPED+=("$p/"); return 0; }` (`scripts/dev-cycle.sh:109`). Probe S1 showed this. `docs/working` was a symlink to an empty directory with no `questions.md`. Section 3 still printed `docs/working/questions.md is not a plain file … NOT read (section 8).`, and section 8 listed only `- docs/working/`. So "exists in some form" and "it is … listed in section 8" no longer hold for that case. The new comment at :101-103 states the parent rule, but this older one was not updated to match.

**Evidence:** `scripts/dev-cycle.sh:96-113`, `fc12/probe-pinned.log` (S1)

---

## Claim 3: "A newline in a name becomes a space here, before the name is ever printed."

**Location:** `scripts/dev-cycle.sh:98-99`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers both branches of `skipped()` and `skipdir()`. It does not establish that any caller can reach the parent branch with a newline in a name. None can today: every parent passed in is a fixed name.

The leaf branch replaces newlines: `SKIPPED+=("${1//$'\n'/ }")` (`scripts/dev-cycle.sh:111`). The parent branch does not: `SKIPPED+=("$p/")` (`:109`). `skipdir` does not either (`:114`). The walk harness recorded the literal newline for `skipped "d"$'\n'"x/l/f"`, giving `SKIPPED=(d⏎x/l/)` (`walk-pinned.log`). Every current caller passes fixed parents (`docs`, `docs/working`, `docs/decisions`, `docs/working/cycles`) or glob items whose parent is already known to be plain, so the gap cannot be reached today. The precise version would say "in a file name (a parent's name is not rewritten)".

**Evidence:** `scripts/dev-cycle.sh:104-114`, `fc12/walk-pinned.log`

---

## Claim 4: "Parents are checked first, top down: below a parent that is not a plain directory nothing is probed (not even whether a file exists there), and the parent is what gets recorded."

**Location:** `scripts/dev-cycle.sh:101-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the body of `skipped()` only. It does not establish that callers touch nothing below a failing parent. Each caller runs `inrepo` on the full path first, which stats through the parent (`:206`, `:228`, `:263`, `:313`, `:324`), and `skipdir` has no parent walk at all (Claim 12b).

```bash
# scripts/dev-cycle.sh:106-110
  while [[ "$rest" == */* ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"; p="${p:+$p/}$c"
    [[ -e "$p" || -L "$p" ]] || return 1
    plaindir "$p" || { SKIPPED+=("$p/"); return 0; }
  done
```
(excerpt ends :110; enclosing `skipped()` continues to :113 — read.) The walk returns at the first failing parent, before the leaf test at :111. The walk harness confirmed this: `skipped 'docs/l/f'` gave `SKIPPED=(docs/l/)`. Test 7's log.md assertion shows the same thing at the output level.

**Evidence:** `scripts/dev-cycle.sh:104-113`, `fc12/walk-pinned.log`, `fc12/bats-pinned.log` (test 7)

---

## Claim 5: The parent walk in `skipped()` is correct for every current call site (brief item 1: absolute paths, `..`, a trailing slash, the glob items)

**Location:** `scripts/dev-cycle.sh:104-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers every call site at 71e618d (:146, :197, :218, :246, :268, :318, :337) and the edge inputs listed below. It does not establish good behavior for inputs no caller passes: `..` or `//` in a path, or a trailing slash on a plain directory.

Results from the walk harness (`walk-pinned.log`):
- An absolute path (`/etc/passwd`) gives rc=1, so it is treated as absent: the first component is empty and `[[ -e "" ]]` fails.
- A plain file gives rc=1.
- `docs/working/` (a trailing slash on a plain directory) gives rc=0 and records `docs/working/`, because `inrepo` rejects a directory.
- `docs/working/../working/q.md` records `docs/working/../`.
- `docs//working/q.md` records `docs//`.

No caller passes any of the last four (paraphrased — no quote available because this is about which arguments are absent from the call sites, checked by reading each call listed in Scope). The glob items at :146 and :197 run only inside `plaindir` on their parent (`:140`, `:195`), so their walk re-checks plain parents and ends at the leaf test. The cycle glob, when nothing matches, stays a literal pattern: `inrepo` fails, the walk passes the plain parents, and `-e` on the leaf fails, so it is treated as absent (rc=1). That is the right result.

**Evidence:** `scripts/dev-cycle.sh:140-153`, `:195-197`, `:218`, `:246`, `:268`, `:318`, `:337`, `fc12/walk-pinned.log`

---

## Claim 6: "Keep the newest skipped date (not future-dated) to warn when it is newer than the record the window starts from."

**Location:** `scripts/dev-cycle.sh:144-146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers several skipped records, a future-dated one, one dated today, one that is a directory, and `--since`. It does not establish the case where the skip comes from a parent: then no date is kept, because the cycles directory itself must already be plain to reach this loop.

`skipped "$f" && [[ "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] && skipped_record="$d"` (`:146`). Results:
- S5a: skipped 02-10, 02-20 and 2099-01-01 next to a readable 01-01. The Window line names `cycle-2026-02-20.md` and passes over the future record.
- S5b: TODAY=2026-03-01, a skipped record dated 03-01 next to a readable 02-01. The 03-01 record is named; `! "$d" > "$TODAY"` lets a same-day date through.
- S5c: only a future-dated record is skipped. No note appears, and the line falls through to "no readable cycle record".
- Equal dates cannot occur, because two records cannot share a file name.

**Evidence:** `scripts/dev-cycle.sh:139-161`, `fc12/probe-pinned.log` (S5a–S5e)

---

## Claim 7: "; a newer record, cycle-$skipped_record.md, was skipped as not a plain file (section 8), so this window may start too early"

**Location:** `scripts/dev-cycle.sh:159-160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the note appearing only when the newest non-future skipped record is newer than `last_record`, and never under `--since`. It does not establish what the skill does with the note (Claim 14).

```bash
# scripts/dev-cycle.sh:157-161
elif [[ -n "$last_record" ]]; then
  SINCE="$last_record"; source_note="the last cycle record, docs/working/cycles/cycle-$last_record.md"
  if [[ "$skipped_record" > "$last_record" ]]; then
    source_note+="; a newer record, cycle-$skipped_record.md, was skipped as not a plain file (section 8), so this window may start too early"
  fi
```
(excerpt ends :161; the enclosing if/elif/else continues to :169 — read.) Results:
- S5a/S5b/S5d print the note. S5d covers a directory named like a record.
- S5b's older skipped record (01-01, older than the readable 02-01) does not take the note.
- S5e (`--since`) prints `from --since` with no note.
- Test 10 passes at 71e618d and fails on c034a75 (`bats-new-tests-on-c034a75.log`: `not ok 10`).

**Evidence:** `scripts/dev-cycle.sh:155-169`, `fc12/probe-pinned.log`, `fc12/bats-new-tests-on-c034a75.log`

---

## Claim 8: Section 2's skip count is taken before the decisions directory is checked (e08d526: "the count is now taken first")

**Location:** `scripts/dev-cycle.sh:193-195`, `:220-222`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers a symlinked `docs/decisions` (whether or not it holds records), a symlinked `docs`, and a regular file at `docs/decisions`. It does not establish the wording when some records are read and others skipped. In that case `found=1` and no skip line prints, which is the design.

`n_before_triggers=${#SKIPPED[@]}` (`:193`) now comes before `… else skipdir docs/decisions || true; fi` (`:195`). Results:
- S3a, S3b (`docs` a symlink) and S6 (`docs/decisions` a regular file) all print `No revisit triggers read: decision records or the log were skipped as not plain files (section 8).`
- Test 7's new assertion passes at 71e618d and fails on c034a75 (`not ok 7`).

**Evidence:** `scripts/dev-cycle.sh:189-223`, `fc12/probe-pinned.log` (S3a, S3b, S6), `fc12/bats-new-tests-on-c034a75.log`

---

## Claim 9: Inline skip messages, e.g. "docs/working/questions.md is not a plain file (reached through a symlink, or not a regular file): NOT read (section 8)."

**Location:** `scripts/dev-cycle.sh:247`, `:269`, `:319`, `:338`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the four call sites when the skip comes from a parent. It does not establish anything new for skips at the leaf, where the message is exact (S7: a FIFO at `docs/roadmap.md`).

Each call site still prints its own message, and each is reached correctly through `skipped`'s rc=0, so the routing is right. The text, though, says the named file "is not a plain file". When only a parent was skipped, the file may not exist at all. In S1, `docs/working` was a symlink to an empty directory, yet the output printed `docs/working/questions.md is not a plain file (reached through a symlink, or not a regular file): NOT read (section 8).`. In S3b, `docs` was a symlink to an empty directory, and `docs/roadmap.md is not a plain file …` printed the same way. Before 5dd5377 these cases printed the "No … yet" branch. The new text is safer, since it no longer reveals whether the file exists, but it is imprecise. The precise version is "<path> is not read: <parent>/ is not a plain directory (section 8)".

**Evidence:** `scripts/dev-cycle.sh:246-250`, `:268-272`, `:318-322`, `:337-341`, `fc12/probe-pinned.log` (S1, S3b, S7)

---

## Claim 10: "None: no input was skipped."

**Location:** `scripts/dev-cycle.sh:344-345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the empty-`SKIPPED` branch and test 8. It does not establish that every skip reaches `SKIPPED`: the inline messages and section 8 share that one array, so a skip cannot print inline yet be missing from section 8.

`if [[ ${#SKIPPED[@]} -eq 0 ]]; then echo "None: no input was skipped."` (`:344-345`). Test 8 checks that this is the last line (`tail -1 … | grep -q 'None: no input was skipped'`, `test/scripts/dev-cycle.bats:185`) and passes. Inputs that are simply absent no longer get the false "every input is a plain file".

**Evidence:** `scripts/dev-cycle.sh:343-349`, `test/scripts/dev-cycle.bats:182-188`, `fc12/bats-pinned.log`

---

## Claim 11a: "Reached through a symlink, or not a regular file or directory, so not read"

**Location:** `scripts/dev-cycle.sh:347`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers symlinks, FIFOs and a regular file at a directory path. It does not establish the "nothing below" half (Claim 11b).

A regular file sitting where a directory is expected is listed as `- docs/decisions/` (S6), yet it *is* a regular file, so a literal reading of "not a regular file or directory" leaves it out. The header is right only if read as "not the kind expected there". The precise version would say "not the kind of file expected at that path (a regular file, or a directory for paths ending in /)".

**Evidence:** `scripts/dev-cycle.sh:114`, `:347`, `fc12/probe-pinned.log` (S6, S7)

---

## Claim 11b: "nothing below a listed directory was read or probed"

**Location:** `scripts/dev-cycle.sh:347`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers `skipdir`'s two call sites (:152 and :195) when a parent of the directory is a symlink. It does not establish anything about `skipped()`'s own walk, which does honor the rule (Claim 4).

`skipdir` has no parent walk: `skipdir() { if [[ -e "$1" || -L "$1" ]] && ! plaindir "$1"; then SKIPPED+=("$1/"); return 0; fi; return 1; }` (`:114`). It is called on `docs/working/cycles` (`:152`) and `docs/decisions` (`:195`). Its `-e` follows a symlinked parent. Probes:
- **S1 vs S2:** `docs/working` is a symlink to `out/`. If `out/` has no `cycles`, section 8 lists only `- docs/working/`. If `out/cycles/` exists, it lists `- docs/working/` **and** `- docs/working/cycles/`. The Window line also changes, from `no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)` to `no readable cycle record (one or more were skipped …)`.
- **S3a vs S3b:** `docs` is a symlink. `- docs/decisions/` is listed only when `decisions` exists in the target.

So a directory below a listed directory is probed, and the result shows in the digest. The Window line goes into the committed cycle record as printed (`skills/dev-cycle/SKILL.md:246`), and section 8 goes into `## Skipped inputs`. **Behavioral.** This is the same class of leak as pass-11 A3 (rated Low by security F2). It needs a committed symlink at `docs` or `docs/working`, and it reveals only whether the fixed names `cycles` and `decisions` exist in the target. A second, smaller gap: each caller's `inrepo` on the full path (e.g. `if inrepo docs/decisions/log.md`, `:206`, which runs `[[ -f "$1" ]]`, `:92`) stats below a skipped parent before `skipped` runs. The digest output never shows that result, but it is still a probe.

**Evidence:** `scripts/dev-cycle.sh:92`, `:114`, `:140-153`, `:195`, `:206`, `:347`, `fc12/probe-pinned.log` (S1, S2, S3a, S3b)

---

## Claim 12: "The digest applies the same rule to everything it reads (and also skips anything that is not a regular file or directory) and lists what it skipped in its section 8."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers *reads*: no input is read through a symlink (tests 6 and 7), and FIFOs are skipped (S7). It does not establish that the digest's *probing* matches the skill's "checked through its directories" order (Claim 11b), or that section 8 lists only top-level blockers.

`inrepo` requires `[[ "$r" == "$ROOT_REAL/$1" ]]`, which holds only when no component is a symlink (`scripts/dev-cycle.sh:92`). Globs are expanded only inside `plaindir` directories (`:140-141`, `:195`). Tests 6 and 7 pass, and S7 lists the FIFO.

**Evidence:** `scripts/dev-cycle.sh:89-114`, `test/scripts/dev-cycle.bats:126-180`, `fc12/bats-pinned.log`, `fc12/probe-pinned.log` (S7)

---

## Claim 13: "If instead it says records were skipped, or names a newer record that was skipped, a record (or the cycles directory) exists but is not a plain file: note that in this record, file one `agent` entry reporting the path (never read, copy or rewrite through it), and rerun with `--since` the same way."

**Location:** `skills/dev-cycle/SKILL.md:103-106`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the match against the digest's two Window texts and the diagnosis the sentence gives. It does not establish the S1 case, where the digest prints "no cycle record found" and the step-0 sentence before this one fires instead (that comes from Claim 11b's code path).

The two Window texts match. The digest prints `no readable cycle record (one or more were skipped as not plain files: section 8)` (`scripts/dev-cycle.sh:165`), which is "says records were skipped". It also prints `a newer record, cycle-<d>.md, was skipped` (`:160`), which is "names a newer record". The diagnosis is too narrow, though. In S2 the thing that is not plain is `docs/working/` (and S3-style, `docs/`), not a record or the cycles directory. The precise version is "a record or one of its directories (section 8 names which)". "Never read, copy or rewrite through it" is the fix for security F3 (A2), and it is stated plainly.

**Evidence:** `skills/dev-cycle/SKILL.md:99-106`, `scripts/dev-cycle.sh:159-167`, `fc12/probe-pinned.log` (S2, S5a)

---

## Claim 14: The stale-brief rule agrees with the brief cap and the record line, and terminates

**Location:** `skills/dev-cycle/SKILL.md:219-223`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with the 3-brief cap (`:234`) and the record line (`:254`), duplicate prevention, and the reset by `Kept:`. It does not establish which step applies an answered keep or drop (Claim 15), or a brief whose branch has commits but has stalled (performance #1's optional widening, not taken).

The rule says "Until the user answers, the brief still holds its slot" (`:223`). The cap says "while fewer than 3 briefs are open, counting earlier cycles'" (`:234`), and the record line says `<k>/3 open (3/3: no new briefs)` (`:254`). Both count `Status: open` briefs, and a brief awaiting an answer stays open, so the three agree. "unless one is already open" (`:222`) stops duplicate entries. A "keep" moves the clock to the new `Kept:` date, so the rule re-asks at most once per 14 days per brief instead of every cycle. "Drop" closes the brief "as above", meaning Ideas plus `Status: closed` (`:218-219`). The start date is unambiguous: it is "the brief's date", which is the date in its file name `docs/working/handoffs/YYYY-MM-DD-<slug>.md` (`:235`), or the last `Kept:` date. "No commit beyond the default branch" is also unambiguous.

**Evidence:** `skills/dev-cycle/SKILL.md:216-238`, `:254`

---

## Claim 15: "\"keep\" adds `Kept: YYYY-MM-DD` to the brief, \"drop\" closes it as above"

**Location:** `skills/dev-cycle/SKILL.md:222-223`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers whether the skill says when and from where an answer is applied. It does not establish any runtime behavior, since this is a prose procedure.

The effect of each answer is clear. What the skill leaves unsaid is which step applies an *answered* entry. Step 1 runs `questions.sh archive` "so answered entries leave the live file" (`:119-120`) before step 6's In flight check. The answer therefore sits in `questions-archive.md` by the time step 6 runs, and "unless one is already open" no longer blocks a new entry. An agent that does not look in the archive would refile the same question. The precise version adds "(step 6 applies answered entries, which step 1 has moved to the archive)".

**Evidence:** `skills/dev-cycle/SKILL.md:119-120`, `:216-223`

---

## Claim 16: Test 7 title: "a symlinked directory is listed and nothing below it is read or probed; a newline in a skipped name stays on one line"

**Location:** `test/scripts/dev-cycle.bats:157`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what the test asserts in its own setup, where the symlinked directories are `docs/decisions` and `docs/working/cycles` themselves. It does not establish the parent-symlink case (Claim 11b), and it does not show that no stat happens at all.

The assertions are on output only: `[[ "$output" != *"docs/decisions/log.md"* ]]` (`:170`). The script still stats `docs/decisions/log.md` through the symlink in `inrepo` (`scripts/dev-cycle.sh:206`, `:92`) before `skipped` stops at the parent. "Probed" is accurate if it means "the result is disclosed". The precise title would say "nothing below it shows in the digest".

**Evidence:** `test/scripts/dev-cycle.bats:157-180`, `scripts/dev-cycle.sh:92`, `:206`

---

## Claim 17: "A fixed name below a skipped directory is not probed: whether log.md exists out there must not show."

**Location:** `test/scripts/dev-cycle.bats:166-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the claim that the assertion matches the comment and tells old code from new for `log.md` under a symlinked `docs/decisions`. It does not establish the parent-symlink case (Claim 11b).

The 71e618d test file run against e08d526's script gives `not ok 7` (`bats-new-tests-on-e08d526.log`). There, the old `skipped` follows the symlink with `-e` and lists `docs/decisions/log.md`. Against 5dd5377 and 71e618d, test 7 passes.

**Evidence:** `test/scripts/dev-cycle.bats:166-170`, `fc12/bats-new-tests-on-e08d526.log`, `fc12/bats-new-tests-on-5dd5377.log`, `fc12/bats-pinned.log`

---

## Claim 18: Test 7's section-2 assertion (and e08d526: "Test 7 asserts the section-2 wording")

**Location:** `test/scripts/dev-cycle.bats:173`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the claim that the assertion tells the c034a75 count order from the new one. It does not establish the section-2 wording when `docs` itself is a symlink (S3a/S3b cover that; no test does).

`[[ "$output" == *"No revisit triggers read: decision records or the log were skipped"* ]]` (`:173`). This line was added in e08d526. It fails on c034a75 (`not ok 7`) and passes at 71e618d.

**Evidence:** `test/scripts/dev-cycle.bats:173`, `fc12/bats-new-tests-on-c034a75.log`, `fc12/bats-pinned.log`

---

## Claim 19: Test 10: "a skipped newer cycle record is named in the window line"

**Location:** `test/scripts/dev-cycle.bats:198-204`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers one readable record and one newer symlinked record. It does not establish the several-records, future-dated or `--since` cases (probed instead: S5a–S5e).

The test asserts `*"Window: since 2026-01-01 (from the last cycle record"*"a newer record, cycle-2026-02-20.md, was skipped"*` (`:203`). It passes at 71e618d and fails on c034a75 (`not ok 10`).

**Evidence:** `test/scripts/dev-cycle.bats:198-204`, `fc12/bats-new-tests-on-c034a75.log`, `fc12/bats-pinned.log`

---

## Claim 20: Test 8: "tail -1 … | grep -q 'None: no input was skipped'"

**Location:** `test/scripts/dev-cycle.bats:185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the claim that the last line of a redirected digest in a repo with no docs is the new empty-section-8 text. It does not establish the non-empty section 8.

Test 8 passes at 71e618d and fails on c034a75 and e08d526, which still print the old text (`not ok 8` in both logs).

**Evidence:** `test/scripts/dev-cycle.bats:182-188`, `fc12/bats-pinned.log`, `fc12/bats-new-tests-on-c034a75.log`

---

## Claim 21: e08d526: "Loop pass 11 (performance critic, both reproduced by running the script)"

**Location:** commit `e08d526` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the claim that the pass-11 performance review reports both defects as executed probes. It does not establish that it was the only source: the rubric credits fact-check, api and security as well.

`docs/reviews/performance-review-2026-10-01-digest-pass11.md:85` (the section-2 count, "Probe case A … **Confidence:** High (executed)") and `:86` (the newer skipped record, "Probe case B … High (executed)").

**Evidence:** `docs/reviews/performance-review-2026-10-01-digest-pass11.md:85-86`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:413-414`

---

## Claim 22: e08d526: "New test 3."

**Location:** commit `e08d526` message
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the test index. It does not establish anything about what the test does (Claim 19).

At e08d526 the new test is the 10th `@test` in the file (`test/scripts/dev-cycle.bats:193` at that commit). Test 3 is "after a cycle record, every trigger still prints in full and nothing is carried" (`:65`), which this round did not change. **Wording.** A reader looking for the new test by the commit's number lands on the wrong one.

**Evidence:** `git show e08d526:test/scripts/dev-cycle.bats` lines 65 and 193

---

## Claim 23: e08d526 / 5dd5377: "22/22; shellcheck clean."

**Location:** commit `e08d526` and `5dd5377` messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers 71e618d (bats 22/22, shellcheck empty) and the test count at each commit. It does not re-run each commit's own test file at that commit.

`grep -c '@test'` gives 22 at e08d526, 5dd5377 and 71e618d (21 at c034a75). Pinned bats: 22 `ok` lines, exit 0. Pinned shellcheck: exit 0, empty output.

**Evidence:** `fc12/bats-pinned.log`, `fc12/shellcheck-pinned.log`

---

## Claim 24: 5dd5377: "The committed record no longer reveals which fixed names exist in a directory a symlink points to."

**Location:** commit `5dd5377` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the case where a parent of `docs/working/cycles` or `docs/decisions` is the symlink. It does not establish anything new about the case where the symlinked directory is the one checked (which holds, Claim 17).

`skipdir` (`scripts/dev-cycle.sh:114`) probes `docs/working/cycles` and `docs/decisions` through a symlinked `docs/working` or `docs`. Whether `cycles` or `decisions` exists in the target changes both section 8 (S2 adds `- docs/working/cycles/`; S3a adds `- docs/decisions/`) and the Window line (S1 vs S2). The Window line goes into the committed record. **Behavioral.** The preconditions are a committed symlink at `docs` or `docs/working`, and the leak is limited to two fixed names. Severity: Low, same class as pass-11 A3. Details are in Claim 11b.

**Evidence:** `scripts/dev-cycle.sh:114`, `:152`, `:195`, `fc12/probe-pinned.log` (S1, S2, S3a, S3b)

---

## Claim 25a: 71e618d: the header "says nothing below a listed directory was read or probed (true since 5dd5377)"

**Location:** commit `71e618d` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the "(true since 5dd5377)" assertion. Same defect as Claims 11b and 24.

S2 lists `docs/working/cycles/` below the listed `docs/working/`, and S3a lists `docs/decisions/` below the listed `docs/`. **Behavioral.**

**Evidence:** `fc12/probe-pinned.log` (S2, S3a), `scripts/dev-cycle.sh:114`

---

## Claim 25b: 71e618d: "the header now covers a regular file at a directory path"

**Location:** commit `71e618d` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Same as Claim 11a.

S6 lists `docs/decisions/` for a regular file. The header covers that case only if "not a regular file or directory" is read as "not the kind expected there". **Wording.**

**Evidence:** `scripts/dev-cycle.sh:347`, `fc12/probe-pinned.log` (S6)

---

## Claim 26: 8286c2b message (step 0 never reads, copies or rewrites through a skipped record; `Kept:` date and commits beyond the default branch; an unanswered question holds the slot; symlink-rule note; Q-103 "harness settings")

**Location:** commit `8286c2b` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the claim that each bullet matches the diff `a218ad8..8286c2b`. It does not establish that the new text is complete (Claims 13 and 15).

The diff carries each change: step 0 at `skills/dev-cycle/SKILL.md:103-106`, the brief rule at `:219-223`, the symlink note at `:66-68`, and Q-103 at `docs/working/questions.md:57`.

**Evidence:** `git diff a218ad8..8286c2b -- skills/dev-cycle/SKILL.md docs/working/questions.md`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11b** (`scripts/dev-cycle.sh:347`), **behavioral**: `skipdir` has no parent walk. A symlinked `docs` or `docs/working` makes the digest probe and list `docs/decisions/` or `docs/working/cycles/` below a listed directory, and changes the Window line. Give `skipdir` the same top-down parent walk.
- **Claim 24** (5dd5377 message), **behavioral**: the same root cause. The record still reveals whether `cycles` or `decisions` exists in a symlinked `docs/working` or `docs` (Low; needs a committed parent symlink).
- **Claim 25a** (71e618d message), **behavioral**: "(true since 5dd5377)" is refuted by the same probes.
- **Claim 22** (e08d526 message), **wording**: "New test 3" should be "new test 10".

### Stale
- **Claim 2** (`scripts/dev-cycle.sh:96-99`), **wording**: "exists in some form … listed in section 8" is no longer true below a skipped parent. Merge this comment with the one at :101-103.

### Mostly Accurate
- **Claim 3** (`scripts/dev-cycle.sh:98-99`), **wording**: the parent branch (:109) and `skipdir` do not replace newlines. No current caller can reach this.
- **Claim 9** (`scripts/dev-cycle.sh:247/269/319/338`), **wording**: "<file> is not a plain file" prints when only a parent was skipped and the file may not exist. Name the blocking parent instead.
- **Claim 11a** (`scripts/dev-cycle.sh:347`), **wording**: a regular file at a directory path is a "regular file". Say "not the kind expected at that path".
- **Claim 13** (`skills/dev-cycle/SKILL.md:103-106`), **wording**: "a record (or the cycles directory)" should be "a record or one of its directories (section 8 names which)".
- **Claim 15** (`skills/dev-cycle/SKILL.md:222-223`), **wording**: the skill does not say which step applies an answered keep or drop. Step 1 has already archived it, so "unless one is already open" no longer stops a refile.
- **Claim 16** (`test/scripts/dev-cycle.bats:157`), **wording**: the title says "probed", but the test checks only that nothing shows in the output. `inrepo` (:206) still stats through the symlink.
- **Claim 25b** (71e618d message), **wording**: the same point as 11a.

### Unverifiable
- None.

Rules confirmed correct and complete for their scope: section 2's skip count (Claim 8), the Window-line note across several, future-dated, same-day, directory and `--since` cases (Claims 6 and 7), `skipped()`'s own walk for every current call site (Claims 4 and 5), the empty-section-8 text (Claim 10), the stale-brief rule's agreement with the cap and the record line (Claim 14), and the Q-103 wording (Claim 1). Tests 7, 8 and 10 tell old code from new: each fails on the pre-fix script.

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass12.md`. Its first line is `Commit: 71e618d (A) / 8286c2b (B)`, and it carries the header field `**Replication:** k=1 (loop pass, decision 031)`. The skill's header fields are present, and every claim has the seven mandatory fields plus Legibility-target. Executed claims carry provenance in `fc12/`. The report serves the user goal: merging both branches once a clean pass is reached. That pass is not clean yet. Claim 11b/24/25a is one behavioral defect, Low by pass 11's grading of the same leak class: `skipdir` lacks the parent walk this round added to `skipped()`. The uncommitted `blocker()` edits that appeared in A's working tree during this review were not reviewed. They seem to target this exact defect, and they need their own pass.
