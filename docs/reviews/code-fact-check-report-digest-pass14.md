Commit: 096042b (A) / 374d559 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 096042b; HEAD dd1548a adds review docs only, `git diff --stat 096042b HEAD` touches only `docs/reviews/`). B: `/workspace/.claude/wt-devcycle` (content at 374d559; HEAD 3d3b877 is a merge of the digest branch, and `git diff --stat 374d559 HEAD -- skills/` is empty).
**Scope:** Partial: the pass-13 fix round only. A: `git diff 591f098..096042b -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of commit 096042b. B: `git diff 44d06b7..374d559 -- skills/dev-cycle/SKILL.md` plus the message of commit 374d559. Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 24
**Summary:** 19 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc14/` (below, `fc14/`). The scripts ran against the worktree copy, whose `scripts/` and `test/` are identical to 096042b. Every repo was built under its own `mktemp -d` directory, removed on exit; every process ran under `timeout`.
- `bats.log`: `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-10-02T06:19:47Z, 23/23 ok.
- `shellcheck.log`: `timeout 60 shellcheck scripts/dev-cycle.sh`, same cwd, exit 0, empty output, 2026-10-02T06:20:40Z.
- `probe.log` (script `fc14/probe.sh`): `timeout 300 ./probe.sh`, cwd `fc14/`, exit 0, 2026-10-02T06:20:13Z. P1: section 3 and section 8 for all nine combinations of questions.md and questions-archive.md each absent / plain / symlinked. P2, P2b: section 2 with no triggers found and one input skipped next to a plain input. P3, P3b: a symlinked `docs/decisions/` and a symlinked `docs/` (dedup).
- `probe2.log` (script `fc14/probe2.sh`): `timeout 120 ./probe2.sh`, cwd `fc14/`, exit 0, 2026-10-02T06:20:30Z. The Window line for eight cycle-record layouts, with `DEV_CYCLE_TODAY=2026-01-10`.
- `trace.log` (script `fc14/trace.sh`) and `trace-sanity.log` (script `fc14/trace-sanity.sh`): `timeout 200 ./trace.sh` at 2026-10-02T06:20:57Z, exit 0, and `timeout 100 ./trace-sanity.sh` right after it, exit 0. The script runs under `DEV_CYCLE_SCRUBBED=1 bash -x` (strace is not in the sandbox). The trace is grepped for every `[[ -d/-e/-f/-L ]]` test and `realpath` call on a path below the blocking part, for a symlinked `docs/`, symlinked `docs/working/` + `docs/decisions/`, and a regular file at `docs/working`. The sanity run shows the grep does see the probes on the blocking part itself.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. No claim matches a logged pattern. The one Incorrect verdict is a false printed statement, not an invented symbol, so nothing is logged.

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or the record).

---

## Claim 1: "A fixed-name input is read only when no part of its path blocks it; the walk runs first, so nothing is looked up through a non-plain parent."

**Location:** `scripts/dev-cycle.sh:114-117`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `inrepo` for every fixed name it is called on (`docs/decisions/log.md`, `docs/working/questions.md`, `docs/roadmap.md`, `docs/working/idea-log.md`). It does not establish anything about the leaf itself when the leaf is a symlink: `rawfile`'s `-f` and `realpath -e` then resolve the leaf's target (pre-existing, and the output is the same either way).

`inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`scripts/dev-cycle.sh:117`). `blocker` tests each ancestor top down and returns at the first absent or non-plain one: `[[ -e "$p" || -L "$p" ]] || return 0` / `plaindir "$p" || { printf '%s/' "$p"; return 0; }` (`:107-108`). Only once every ancestor is plain does it test the leaf: `else rawfile "$1" || printf '%s' "${1//$'\n'/ }"; fi` (`:112`, the end of `blocker`, which closes at `:113`). The `-f "$1"` in `inrepo` runs only after an empty `blocker` result, so either every ancestor is plain, or one is absent and the test resolves nothing. In the trace runs, with `docs/`, `docs/working/` or `docs/decisions/` blocking, no test or `realpath` call names a path below the blocking part (`trace.log`: "probes below blocking part: 0" in all four runs). The sanity run shows the grep does catch the blocking part's own probes (`5 ++ [[ -d docs/working ]]`, `trace-sanity.log`).

**Evidence:** `scripts/dev-cycle.sh:103-117`, `fc14/trace.log`, `fc14/trace-sanity.log`

---

## Claim 2: "(Glob items use rawfile directly: their directory has already passed plaindir.)"

**Location:** `scripts/dev-cycle.sh:115-116`
**Type:** Staleness / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that each glob runs only after its directory passed `plaindir`. It does not establish that the gate a maintainer finds at the glob sites is named `plaindir` (it is `dirok`).

Glob items do use `rawfile` directly: `if ! rawfile "$f"; then` (`:152`) and `rawfile "$f" || { skipped "$f" || true; continue; }` (`:206`). The gates are now `if dirok docs/working/cycles; then` (`:149`) and `if dirok docs/decisions; then decisions_glob=(…)` (`:204`). `dirok` does run `plaindir` on the directory, through `blocker`'s leaf branch: `if [[ "$2" == dir ]]; then plaindir "$1" || printf '%s/' "$1"` (`:111`). So the statement is true, but it names the inner check, not the gate. Precise version: "their directory has already passed dirok".

**Evidence:** `scripts/dev-cycle.sh:111`, `scripts/dev-cycle.sh:115-120`, `scripts/dev-cycle.sh:149-152`, `scripts/dev-cycle.sh:204-206`

---

## Claim 3: "The same for a directory the digest globs in: the walk first, so nothing is looked up through a non-plain parent."

**Location:** `scripts/dev-cycle.sh:118-120`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers both glob gates (`:149`, `:204`) and the `skipdir` calls in their else branches. It does not establish anything about what the glob lists inside a plain directory (each item still goes through `rawfile`).

`dirok() { [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }` (`:120`). Same walk as Claim 1, with the leaf checked by `plaindir` (`:111`). Both callers fall back to `skipdir`, which runs the same walk: `else skipdir docs/working/cycles || true` (`:160-161`) and `else skipdir docs/decisions || true; fi` (`:204`). The trace shows no probe below a blocking `docs/`, `docs/working/` or `docs/decisions/` (`trace.log`).

**Evidence:** `scripts/dev-cycle.sh:120-122`, `scripts/dev-cycle.sh:148-162`, `scripts/dev-cycle.sh:203-204`, `fc14/trace.log`

---

## Claim 4: "no readable cycle record (records, or a directory above them, were skipped as not a plain file or directory: section 8), so the default of 14 days"

**Location:** `scripts/dev-cycle.sh:173-174`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the Window line when no readable record exists and `records_skipped > 0`. It does not establish the newer-skipped-record variant (`:168-169`, unchanged, still "not a plain file"; see Claim 20).

`records_skipped=${#SKIPPED[@]}` (`:163`) counts only what the cycles block added, since nothing is skipped before it. `probe2.log` shows this text for: only symlinked records, only a future-dated symlinked record, a symlinked `docs/working`, and a regular file at `docs/working/cycles`. In the last case the "directory above them" is the cycles path itself, which the phrase still fits.

**Evidence:** `scripts/dev-cycle.sh:148-178`, `fc14/probe2.log`

---

## Claim 5: "Name every decision input skipped here, even when other triggers printed: a reader of this section alone must see that some were not read."

**Location:** `scripts/dev-cycle.sh:229-236`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that every entry the triggers block adds to `SKIPPED` (the decisions directory, glob items, the log) prints one `Not read:` line, deduplicated by `sort -u`, whether or not triggers printed. It does not establish that the lines follow section 8's order beyond both using `sort -u`.

```bash
# scripts/dev-cycle.sh:231-236
if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then
  echo
  printf '%s\n' "${SKIPPED[@]:$n_before_triggers}" | sort -u | while IFS= read -r p; do
    echo "Not read: $p is not a plain file or directory (section 8); its triggers are missing above."
  done
fi
```

`n_before_triggers` is taken at `:202`, before the decisions gate. Test 10 prints a plain record's trigger and the `Not read:` line for the symlinked log (`bats.log`, ok 10). With `docs/decisions` symlinked, `docs/decisions/` goes in twice (gate, then log) and prints once. With `docs/` symlinked, it prints once although the cycles block added it before the slice too (`probe.log` P3, P3b).

**Evidence:** `scripts/dev-cycle.sh:200-236`, `test/scripts/dev-cycle.bats:207-220`, `fc14/bats.log`, `fc14/probe.log`

---

## Claim 6: "No revisit triggers read: every decision input that exists was skipped."

**Location:** `scripts/dev-cycle.sh:237-238`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the printed line in every case that reaches it (`found == 0` and at least one decision input skipped). It does not establish whether any reader acts differently on it, given that the `Not read:` lines just above name exactly what was skipped.

```bash
# scripts/dev-cycle.sh:237-240
if [[ $found -eq 0 ]]; then
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: every decision input that exists was skipped."
  else echo "No revisit triggers recorded."; fi
fi
```

`found` is set only when a record has a `## Revisit triggers` section (`grep -q '^## Revisit triggers' "$f" || continue` / `found=1`, `:207-208`) or the log has a row matching `revisit` (`:216-217`). The skip condition is "at least one was skipped", not "all were". A plain record with no triggers section is read (the `grep` at `:207`) but sets nothing, and the line still prints. `probe.log` P2 (plain `001-plain.md` without triggers, symlinked `log.md`) and P2b (plain `log.md` without revisit rows, symlinked `002-link.md`) both print "every decision input that exists was skipped" although one input existed and was read. The line is true in tests 6 and 7, where every input is skipped. Precise version: "No revisit triggers read; the inputs above were skipped." The printed line is the defect, not just its comment: an agent reading section 2 is told no decision input was readable.

**Evidence:** `scripts/dev-cycle.sh:200-240`, `fc14/probe.log` (P2, P2b)

---

## Claim 7a: "questions.sh reads the archive too and would follow a symlink there"

**Location:** `scripts/dev-cycle.sh:246-247`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers what the `open` subcommand, the one the digest runs, does with the archive. It does not establish anything about the other subcommands (`check`, `index`, `next-id` and `archive` do read its content).

`cmd_open() { require_files; parse_entries "$LIVE" | …` (`scripts/questions.sh:408-410`; the function ends at `:414` after printing). `require_files` only tests the archive: `for file in "$LIVE" "$ARCHIVE"; do [[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }` (`scripts/questions.sh:134-135`). `-f` follows a symlink, so the follows-a-symlink half is right, and the exists / missing outcome is the one-bit oracle. But `open` never reads the archive's content; it only tests whether it exists. Precise version: "questions.sh checks that the archive exists, following a symlink there".

**Evidence:** `scripts/questions.sh:84-86`, `scripts/questions.sh:130-138`, `scripts/questions.sh:408-414`

---

## Claim 7b: "so the archive passes the same check before questions.sh runs."

**Location:** `scripts/dev-cycle.sh:247-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the default archive path. It does not establish anything about a `QUESTIONS_ARCHIVE` set in the environment, which `questions.sh` would use instead (`:86`). That is an operator choice, not repo text.

`elif skipped "$QA"; then` (`:250`) runs `blocker` on `docs/working/questions-archive.md` before the `elif inrepo docs/working/questions.md && [[ -f "$QS" ]]; then` branch that runs `bash "$QS" open` (`:252-254`). In P1, a symlinked archive next to a plain questions.md never reaches questions.sh: no `questions.sh open failed` block appears, and section 8 lists the archive (`probe.log`). Test 10 asserts the dangling target's name never appears (`bats.log`, ok 10).

**Evidence:** `scripts/dev-cycle.sh:242-272`, `fc14/probe.log` (P1), `fc14/bats.log`

---

## Claim 8: Section 3's branch order: questions.md skipped → archive skipped → run questions.sh → absent (brief priority 1).

**Location:** `scripts/dev-cycle.sh:248-272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers all nine absent / plain / symlinked combinations of the two files with questions.sh present. It does not establish the output when questions.sh itself is missing (static: the `[[ -f "$QS" ]]` guard sends that to the last branch).

`probe.log` P1 results:
- questions.md symlinked (any archive): only `questions.md is not read` prints, and the archive is neither checked nor listed.
- questions.md plain, archive symlinked: archive note plus "NOT checked".
- questions.md plain, archive plain: "None open."
- questions.md plain, archive absent: `**questions.sh open failed**` with questions.sh's own `✗ missing: …/questions-archive.md` error. This is the case the brief singles out, and the error still shows.
- questions.md absent, archive absent or plain: "No docs/working/questions.md (or questions.sh) in this repo."
- questions.md absent, archive symlinked: archive note plus "NOT checked" (see Claim 9).

**Evidence:** `scripts/dev-cycle.sh:242-272`, `fc14/probe.log` (P1)

---

## Claim 9: "Watched questions were NOT checked: questions.sh reads the archive too."

**Location:** `scripts/dev-cycle.sh:251`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the printed reason in both cases that reach this branch. It does not establish anything beyond the wording: the not-checked conclusion holds in both.

With questions.md plain, the reason is right in substance, though "reads" overstates it (Claim 7a). With questions.md **absent** and the archive symlinked, the branch at `:250` also fires before the absent branch at `:270-271`. The output then says watched questions were not checked *because questions.sh reads the archive* (`probe.log`, `questions=absent archive=link`), when there is no questions.md to check. The same layout without the symlink prints "No docs/working/questions.md". Precise version: name the archive as the reason only when questions.md exists, or test questions.md's absence first.

**Evidence:** `scripts/dev-cycle.sh:248-272`, `fc14/probe.log` (P1)

---

## Claim 10: Step 0's first bullet ("It says records (or a directory above them) were skipped, or names a newer record that was skipped: a record, or one of `docs/`, `docs/working/` or the cycles directory, is not a plain file or directory, so records may exist that the digest could not read.") matches every Window variant.

**Location:** `skills/dev-cycle/SKILL.md:103-105`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the four `source_note` variants the digest prints (`--since`, last record, last record plus skipped newer record, no readable record, no record found). It does not establish that an agent recognises a paraphrase: the bullet paraphrases rather than quotes the Window text.

The variants come from `scripts/dev-cycle.sh:164-178`. The skipped-records variant prints "records, or a directory above them, were skipped" and the newer-record variant prints "a newer record, docs/working/cycles/cycle-2026-01-05.md, was skipped" (`probe2.log`). These are the two triggers of the first bullet. "No cycle record found" goes to the second bullet. `--since` prints neither, even with skipped records (`probe2.log`, "--since with skipped records"), so a rerun cannot re-fire the first bullet. The listed directories are exactly the ancestors `blocker` walks for a record path. A regular file at `docs/working/cycles` also gives the skipped variant (`probe2.log`), covered by "not a plain file or directory".

**Evidence:** `skills/dev-cycle/SKILL.md:100-111`, `scripts/dev-cycle.sh:163-178`, `fc14/probe2.log`

---

## Claim 11: "file one `agent` entry listing the paths section 8 gives (never read, copy or rewrite through them), and rerun with `--since` set to the date of the last cycle you know ran (none known: keep the window the digest chose)."

**Location:** `skills/dev-cycle/SKILL.md:105-108`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the instruction terminates (one rerun at most), uses section 8's whole list, and has a fallback when no cycle is known. It does not establish whether a skipped newer record's *file name* (printed in the Window line) counts as a "cycle you know ran". The text leaves that to the agent, so Confidence is Medium.

After a rerun with `--since`, the Window line reads "from --since" (`source_note="--since"`, `scripts/dev-cycle.sh:164-165`). The first bullet no longer matches. The second bullet ("if the window starts before the last cycle you know ran", `SKILL.md:109-111`) does not fire either, because the window now starts at that date. With none known, there is no rerun at all. Section 8 prints every `SKIPPED` path deduplicated (`printf '%s\n' "${SKIPPED[@]}" | sort -u | sed 's/^/- /'`, `scripts/dev-cycle.sh:370`). Those are the paths the entry lists.

**Evidence:** `skills/dev-cycle/SKILL.md:100-111`, `scripts/dev-cycle.sh:164-178`, `scripts/dev-cycle.sh:365-371`

---

## Claim 12: "\"keep\" adds `Kept: <the answer's date>` to the brief, \"drop\" closes it as above. Apply an answer only if it is newer than the brief's last `Kept:` date (so each answer counts once)"

**Location:** `skills/dev-cycle/SKILL.md:227-229`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that a keep answer, once applied, is never applied again: its date equals the new `Kept:`, and "newer than" excludes it. It does not establish (a) that the answer's date can always be found, since the questions grammar mandates `Opened:` but no answer-date field (this repo's archive does record one by convention, e.g. "**Answered 2026-09-12: …**"), or (b) that no repeat ask is filed (see the gap below).

Paraphrased — no quote available because this is a walk-through of the rule as text, not code. Keep answered on day A: at the next cycle there is no `Kept:`, so it applies and `Kept: A` is written. In later cycles A is not newer than A, so it is skipped. A later answer B > A applies once more. The re-ask clock restarts at A ("14 days after … its last `Kept:` date", `:225-226`). The rule terminates. A drop answer closes the brief, and a closed brief has no further asks.

**Evidence:** `skills/dev-cycle/SKILL.md:222-232`, `docs/working/questions-archive.md:12-13`

---

## Claim 13: "find it by searching `questions.md` and `questions-archive.md` for that question (step 1 has already archived answered entries) rather than reading the archive whole."

**Location:** `skills/dev-cycle/SKILL.md:229-231`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the step-1 ordering claim and that both files are named. It does not establish the order of step 6's two actions (see the gap below).

Step 1: "`~/.claude/scripts/questions.sh archive` then `index`, so answered entries leave the live file." (`SKILL.md:124-125`). `cmd_archive` moves ANSWERED entries to the archive (`scripts/questions.sh:374-394`). Step 1 runs before step 6 (flow diagram, `SKILL.md:81-82`).

**Evidence:** `skills/dev-cycle/SKILL.md:81-82`, `skills/dev-cycle/SKILL.md:124-125`, `scripts/questions.sh:374-394`

---

## Claim 14: Test 10, "section 2 names a skipped log even when other triggers print; a symlinked archive stops section 3"

**Location:** `test/scripts/dev-cycle.bats:207-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers both halves of the name: the assertions check `if plain.` and the `Not read:` log line in section 2, then the archive note followed by "Watched questions were NOT checked", with neither `questions.sh open failed` nor `no-such-file` in section 3. It does not cover a symlinked archive next to an absent questions.md (Claim 9).

`[[ "$section2" == *"if plain."* && "$section2" == *"Not read: docs/decisions/log.md is not a plain file or directory"* ]]` (`:217`); `[[ "$section3" == *"docs/working/questions-archive.md is not read"*"Watched questions were NOT checked"* ]]` (`:219`); `[[ "$section3" != *"questions.sh open failed"* && "$section3" != *"no-such-file"* ]]` (`:220`). Passes (`bats.log`, ok 10).

**Evidence:** `test/scripts/dev-cycle.bats:207-221`, `fc14/bats.log`

---

## Claim 15: Tests 6 and 7 updated to the new Window and section 2 wording.

**Location:** `test/scripts/dev-cycle.bats:148-149`, `test/scripts/dev-cycle.bats:173`, `test/scripts/dev-cycle.bats:187`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the updated assertions match the script's output in those tests' layouts, where every decision input is skipped. It does not establish the section 2 line in a mixed layout (Claim 6).

`[[ "$output" == *"no readable cycle record (records, or a directory above them, were skipped"* ]]` and `[[ "$output" == *"No revisit triggers read: every decision input that exists was skipped"* ]]` (`:148-149`). The same strings appear at `:173` and `:187`. Tests 6 and 7 pass (`bats.log`).

**Evidence:** `test/scripts/dev-cycle.bats:126-189`, `fc14/bats.log`

---

## Claim 16: "questions.sh reads questions-archive.md and followed a symlink there, which made section 3's result a one-bit oracle on any host path a committer names. The archive now passes the same check before questions.sh runs; a skipped archive is noted and watched questions are reported as not checked"

**Location:** commit 096042b message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the oracle mechanism (`require_files`'s `-f` on the archive, with a different section 3 output for a present or missing target) and the fix. It does not endorse "reads" as more than an existence test for `open` (Claim 7a).

`[[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }` (`scripts/questions.sh:135`). Before the fix, that line's outcome reached section 3 through the `questions.sh open failed` block. After it, P1 and test 10 show the archive note and the not-checked line with no questions.sh output (`probe.log`, `bats.log`).

**Evidence:** `scripts/questions.sh:130-138`, `scripts/dev-cycle.sh:245-252`, `fc14/probe.log`, `fc14/bats.log`

---

## Claim 17: "Section 2 names every decision input it skipped, even when other triggers printed … Duplicates (a blocked docs/decisions/ via the glob and the log) print once."

**Location:** commit 096042b message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Same as Claim 5. It does not cover the no-triggers summary line (Claim 6).

See Claim 5: `sort -u` over the slice (`scripts/dev-cycle.sh:233`). P3 prints one `Not read: docs/decisions/` line (`probe.log`).

**Evidence:** `scripts/dev-cycle.sh:229-236`, `fc14/probe.log` (P3)

---

## Claim 18: "The two glob directories go through dirok() (walk first), so nothing is looked up through a non-plain ancestor; section 8's header is now literally true"

**Location:** commit 096042b message
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers every probe the digest itself makes below a listed directory (the trace greps all `[[ -d/-e/-f/-L ]]` tests and `realpath` calls). It does not cover the leaf-symlink resolution inside `rawfile` (Claim 1's residue), which is not "below a listed directory".

Section 8's header: "nothing below a listed directory was read or probed" (`scripts/dev-cycle.sh:369`). The trace finds zero probes below `docs/`, `docs/working/` or `docs/decisions/` when each blocks (`trace.log`). Section 3 under a blocked `docs/working/` never runs questions.sh, because `skipped docs/working/questions.md` fires first (`:248`).

**Evidence:** `scripts/dev-cycle.sh:149`, `scripts/dev-cycle.sh:204`, `scripts/dev-cycle.sh:248`, `scripts/dev-cycle.sh:365-371`, `fc14/trace.log`

---

## Claim 19: "inrepo no longer re-runs realpath on the leaf (performance #1)."

**Location:** commit 096042b message
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the number of `realpath` calls on an existing leaf per `inrepo` call (two before, one now). It does not establish equivalence for an absent leaf (`-f` is false there, and so was `rawfile`).

Before: `inrepo() { [[ -z "$(blocker "$1" file)" ]] && rawfile "$1"; }` (591f098). Now: `inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:117`). An empty `blocker` result with an existing leaf means `rawfile` already passed inside it (`:112`), so the leaf check is the same.

**Evidence:** `scripts/dev-cycle.sh:110-117`

---

## Claim 20: "One phrase for the condition, \"not a plain file or directory\", in the Window line and section 2 (api F2)."

**Location:** commit 096042b message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the strings the commit names. It does not judge whether the remaining file-only wording is wrong (it is accurate for its case).

The skipped-records Window variant (`:174`) and section 2's `Not read:` lines (`:234`) use the phrase. The Window line's newer-record variant still says "was skipped as not a plain file (section 8)" (`:169`). That is accurate, since it fires only when `SKIP_AT == "$f"` (`:155`), but it is a second phrasing in the Window line. Section 2's summary (`:238`) no longer names the condition at all. Precise version: "in the Window line's skipped-records note and section 2's skip lines".

**Evidence:** `scripts/dev-cycle.sh:155`, `scripts/dev-cycle.sh:168-174`, `scripts/dev-cycle.sh:234-238`

---

## Claim 21: "New test 10 (partial skip in section 2, symlinked archive); tests 6 and 7 updated. 23/23; shellcheck clean."

**Location:** commit 096042b message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the count, the pass and lint state, and test 10's position. It does not cover test coverage of Claim 6 or 9's cases.

`grep -c '^@test'` gives 23. Test 10 is the fifth test from line 126 (`:207`). Command `timeout 600 bats test/scripts/dev-cycle.bats` (cwd `/workspace/.claude/wt-digest`) exits 0 with 23/23 ok at 2026-10-02T06:19:47Z (`bats.log`). Command `timeout 60 shellcheck scripts/dev-cycle.sh` exits 0 with empty output at 06:20:40Z (`shellcheck.log`).

**Evidence:** `test/scripts/dev-cycle.bats:207`, `fc14/bats.log`, `fc14/shellcheck.log`

---

## Claim 22: "Step 0, skipped records: records may exist that the digest could not read (or none may exist); the agent entry lists every path section 8 gives; the --since rerun uses the last cycle the agent knows ran, else keeps the digest's window."

**Location:** commit 374d559 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that the message matches `SKILL.md:103-108`. The "(or none may exist)" is implied by "may exist" rather than stated. It does not re-establish Claims 10 and 11.

"so records may exist that the digest could not read. Note that in this record, file one `agent` entry listing the paths section 8 gives … rerun with `--since` set to the date of the last cycle you know ran (none known: keep the window the digest chose)" (`SKILL.md:105-108`).

**Evidence:** `skills/dev-cycle/SKILL.md:103-108`

---

## Claim 23: "Stale briefs: `Kept:` takes the answer's date and an answer applies only if newer than the last `Kept:`, so an archived \"keep\" is not re-applied every cycle; answers are found by searching the questions files rather than reading the growing archive whole."

**Location:** commit 374d559 message
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers re-application (Claim 12) and the search instruction (Claim 13). It does not establish that no duplicate question is filed: the commit dropped the earlier text's ordering, "apply each before deciding whether to ask again" (see the gap below).

`SKILL.md:227-231` as quoted in Claims 12–13.

**Evidence:** `skills/dev-cycle/SKILL.md:222-232`

---

## Gap (not a verdicted claim; behavioral)

**G1. Step 6 no longer orders "apply answers" before "decide whether to ask again". A keep answer can be followed by a duplicate ask.** 44d06b7 said "Apply answers here, … and apply each before deciding whether to ask again". 374d559 removed that clause (see the diff). Now `SKILL.md:225-231` reads, in order: the 14-day condition with "file one `you: judgment` entry … unless one is already open", then the answer rule. Step 1 always archives the answered entry before step 6, so it is no longer "open". An agent that follows the text in order works out the condition before applying the keep (no `Kept:` yet, past day 14, nothing open), files a second "keep or drop" question, then applies `Kept:`. Preconditions: a brief past its 14 days, answered "keep" between cycles, and the agent evaluating in text order. Effect: one redundant `you: judgment` ask per keep answer. It does not loop: the second answer's date is newer, so it applies once. Severity: Low (attention cost only, bounded). Brief priority 2's "no repeat asks" does not hold as written. "Applies once" and "terminates" do hold.

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`scripts/dev-cycle.sh:238`): **behavioral** (printed output). "every decision input that exists was skipped" prints whenever at least one input was skipped and no triggers were found, including when a plain record or log was read and had none (probe P2, P2b). Say only that the listed inputs were skipped.

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:115-116`): **wording**. The glob directories now pass `dirok`, not `plaindir` by name.
- **Claim 7a** (`scripts/dev-cycle.sh:246-247`): **wording**. `questions.sh open` only tests that the archive exists (`-f`, following a symlink); it does not read it.
- **Claim 9** (`scripts/dev-cycle.sh:251`): **wording** (printed). With questions.md absent and the archive symlinked, section 3 blames the archive instead of saying there is no questions.md. "Not checked" is still true.
- **Claim 20** (commit 096042b): **wording**. The Window line's newer-record note keeps "not a plain file"; section 2's summary no longer uses the phrase.

### Gap
- **G1** (`skills/dev-cycle/SKILL.md:225-231`): **behavioral**, Low. The "apply answers before deciding whether to ask again" ordering was dropped, so a keep answer can trigger one duplicate ask.

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass14.md`. It uses the skill's header and per-claim fields, plus the requested `Commit:` first line, `**Replication:**` header and `**Legibility-target:**` tags. It covers the brief's priority list:
- section 3's branch order in all nine combinations, including the absent archive (questions.sh's error still shows);
- a trace showing no lookup below any non-plain ancestor;
- section 2's skip lines: dedup, order and wording, with the "every decision input that exists" line found Incorrect;
- `dirok` and `inrepo`;
- tests 6, 7 and 10, and commits 096042b and 374d559;
- step 0's first bullet against every Window variant;
- the stale-brief rule: it terminates and applies once, but a repeat ask is possible (G1).

Nothing outside this file and the scratch directory was written. Nothing was committed.
