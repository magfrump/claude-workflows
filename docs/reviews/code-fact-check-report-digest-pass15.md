Commit: f47de85 (A) / cb2e5f9 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at f47de85; HEAD a3e2fea adds review docs only, `git diff --stat f47de85 HEAD` touches only `docs/reviews/`). B: `/workspace/.claude/wt-devcycle` (content at cb2e5f9; HEAD 737609e is a merge of the digest branch, and `git diff --stat cb2e5f9 HEAD -- skills/` is empty).
**Scope:** Partial: the pass-14 fix round only. A: `git diff 096042b..f47de85 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of commits f920f0d and f47de85. B: `git diff 374d559..cb2e5f9 -- skills/dev-cycle/SKILL.md` plus the message of commit cb2e5f9. Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 24
**Summary:** 19 verified, 3 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc15/` (below, `fc15/`). Every repo was built under its own `mktemp -d` directory, removed on exit; every process ran under `timeout`. Nothing was written to either worktree except this report.
- `bats.log`: `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-10-02T06:36:19Z, 23/23 ok.
- `shellcheck.log`: `timeout 60 shellcheck scripts/dev-cycle.sh`, same cwd, exit 0, empty output (0 bytes), 2026-10-02T06:36:26Z.
- `probe.log` (script `fc15/probe.sh`): `timeout 600 ./probe.sh`, cwd `fc15/`, exit 0, 2026-10-02T06:34:58Z. P1: section 3 and section 8 for questions.md x archive, each absent / plain / symlinked / a directory (16 combinations), each with questions.sh present and absent (a copy of the script in a directory with no questions.sh, and `$HOME` empty), plus a symlinked `docs/working/`. P2: section 2 for a decision record (none / with triggers / without / symlinked) x `log.md` (absent / with a revisit row / without / symlinked), plus a symlinked `docs/decisions/`.
- `oldcode.log` (script `fc15/oldcode.sh`): `timeout 600 ./oldcode.sh`, cwd `fc15/`, exit 0, 2026-10-02T06:36:26Z. Test 10 from f47de85 run against the 096042b script (fails) and the f47de85 script (passes), in a throwaway tree.
- `oldmixed.log` (script `fc15/oldmixed.sh`): `timeout 120 ./oldmixed.sh`, cwd `fc15/`, exit 0, 2026-10-02T06:36:36Z. Section 2 of the 096042b script in test 10's new mixed case.

**Working-tree note.** After every run above finished, uncommitted edits appeared in both worktrees (`scripts/dev-cycle.sh` mtime 2026-10-02T06:37:56Z, `test/scripts/dev-cycle.bats` 06:38:06Z, B's `skills/dev-cycle/SKILL.md` 06:38:22Z; not made by this run). All reads and executions here predate them, so every verdict is against the committed content at f47de85 / cb2e5f9, not those edits.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. No claim matches a logged pattern. The two Incorrect verdicts are a guarantee the skill's rule does not deliver, not an invented symbol, so nothing qualifies for the log (and the brief allows no write besides this report).

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or the record).

---

## Claim 1: "(Glob items use rawfile directly: their directory has already passed dirok.)"

**Location:** `scripts/dev-cycle.sh:115-116`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers both glob sites (cycle records, decision records): each runs only after `dirok` on its directory, and each item then goes through `rawfile`. It does not establish anything about fixed-name inputs (they use `inrepo`, Claim 1 of pass 14).

The gates are `if dirok docs/working/cycles; then` (`scripts/dev-cycle.sh:149`) followed by `if ! rawfile "$f"; then` (`:152`), and `if dirok docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi` (`:204`) followed by `rawfile "$f" || { skipped "$f" || true; continue; }` (`:206`). The comment now names the gate, as pass 14 Claim 2 asked. `dirok` is defined at `:120`: `dirok() { [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }`.

**Evidence:** `scripts/dev-cycle.sh:115-120`, `scripts/dev-cycle.sh:149-152`, `scripts/dev-cycle.sh:204-206`

---

## Claim 2: "No revisit triggers in the decision inputs that were read; the skipped ones above were not read."

**Location:** `scripts/dev-cycle.sh:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers every combination of a decision record and `log.md` being absent, read with triggers, read without, or skipped, and a skipped `docs/decisions/`: the sentence prints only when no trigger printed and at least one input was skipped, and it is true each time. It does not establish anything about a record whose `## Revisit triggers` heading has an empty body (it sets `found=1` and prints only a heading; pre-existing, out of scope). When every input was skipped, "the decision inputs that were read" is an empty set: the sentence is true but says nothing about read inputs.

The branch: `if [[ $found -eq 0 ]]; then` / `if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers in the decision inputs that were read; the skipped ones above were not read."` / `else echo "No revisit triggers recorded."; fi` (`scripts/dev-cycle.sh:237-240`, the end of section 2). The "above" holds: the `Not read: … its triggers are missing above.` lines print just before it under the same condition (`:231-236`). In `probe.log` P2, the sentence appears in exactly the five cases with a skip and no trigger printed (record none/without/symlinked with log symlinked; record symlinked with log absent or without a revisit row) and for a symlinked `docs/decisions/`. Wherever a trigger printed (e.g. `record=link log=trig`), only the `Not read:` line follows. With nothing skipped and nothing found, `No revisit triggers recorded.` prints. The old text was false in the mixed case: `oldmixed.log` shows 096042b printing "No revisit triggers read: every decision input that exists was skipped." beside a readable `002-none.md`.

**Evidence:** `scripts/dev-cycle.sh:200-240`, `fc15/probe.log` (P2), `fc15/oldmixed.log`

---

## Claim 3: "questions.sh checks that the archive exists with a test that follows a symlink, which would answer "does this host path exist?", so the archive passes the same check before questions.sh runs."

**Location:** `scripts/dev-cycle.sh:246-248`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what `questions.sh open` does with the archive (an existence test only; it parses the live file alone) and that the digest runs `blocker` on the archive before any `questions.sh` call when it would call it. It does not establish what other `questions.sh` subcommands do with the archive (`archive`, `index`, `next-id`, `init` read or write it; the digest runs only `open`).

`cmd_open() {` / `require_files` / `parse_entries "$LIVE" | route_rank | …` (`scripts/questions.sh:408-414`, the whole function). `require_files` is `for file in "$LIVE" "$ARCHIVE"; do` / `[[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }` (`:132-137`); bash's `-f` follows a symlink. The digest calls `bash "$QS" open` (`dev-cycle.sh:256`) only in the third branch, after `skipped "$QA"` has returned false in the second (`:252`). In `probe.log` P1, a symlinked or directory archive beside a plain questions.md gives the banner and no `questions.sh` output; test 10 asserts the output has neither `questions.sh open failed` nor the link target `no-such-file` (`test/scripts/dev-cycle.bats:219`, passing in `bats.log`).

**Evidence:** `scripts/dev-cycle.sh:246-256`, `scripts/questions.sh:132-137`, `scripts/questions.sh:408-414`, `fc15/probe.log` (P1), `fc15/bats.log`

---

## Claim 4: "skipped "$QA" || true  # still listed in section 8, so it shows this cycle"

**Location:** `scripts/dev-cycle.sh:251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers a skipped questions.md (symlink, directory, or a blocked `docs/` / `docs/working/`) with the archive absent, plain, symlinked or a directory. It does not establish listing of the archive when questions.md is absent or questions.sh is missing (then the archive is not examined at all: see Claim 10).

`if skipped docs/working/questions.md; then` / `skipnote docs/working/questions.md` / `skipped "$QA" || true` (`scripts/dev-cycle.sh:249-251`). `skipped` appends the blocking part to `SKIPPED` (`:121`), which section 8 prints with `sort -u` (`:372`). In `probe.log` P1, `questions=link archive=link` and `questions=dir archive=dir` (questions.sh present or absent) list both paths in section 8; a plain or absent archive adds nothing; a symlinked `docs/working/` lists only `docs/working/` (both paths block at the same part and are deduplicated).

**Evidence:** `scripts/dev-cycle.sh:121`, `scripts/dev-cycle.sh:249-251`, `scripts/dev-cycle.sh:367-373`, `fc15/probe.log` (P1)

---

## Claim 5: "**Watched questions were NOT checked** — docs/working/questions-archive.md is not read: …"

**Location:** `scripts/dev-cycle.sh:252-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the printed banner: it appears exactly when questions.md is a plain in-repo file, questions.sh exists, and the archive is skipped, and in that case questions.sh is not run. It does not establish what the skill's reader does with it (Claim 16).

`elif inrepo docs/working/questions.md && [[ -f "$QS" ]] && skipped "$QA"; then` / `echo "**Watched questions were NOT checked** — $(skipnote "$QA")"` (`scripts/dev-cycle.sh:252-253`). `skipnote` runs in a command substitution, but it only reads `SKIP_AT`, which `skipped` set in the parent shell first (`:121`, `:123`), so the note names the right part. `probe.log` P1: `qs=present questions=plain archive=link` and `archive=dir` print `**Watched questions were NOT checked** — docs/working/questions-archive.md is not read: docs/working/questions-archive.md is not a plain file or directory (section 8).` and nothing else in section 3.

**Evidence:** `scripts/dev-cycle.sh:121-123`, `scripts/dev-cycle.sh:249-274`, `fc15/probe.log` (P1)

---

## Claim 6: Tests 6 and 7 now assert "No revisit triggers in the decision inputs that were read" where every decision input was skipped

**Location:** `test/scripts/dev-cycle.bats:149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the two changed assertions (`:149`, `:173`) match the new text and pass. It does not establish that they distinguish the all-skipped case from the mixed case (the same sentence prints in both; test 10's new case, Claim 8, covers the mixed one).

`[[ "$output" == *"No revisit triggers in the decision inputs that were read"* ]]` (`test/scripts/dev-cycle.bats:149`) and the same pattern at `:173` with a section-2 dump on failure. Both tests pass (`bats.log`, ok 6 and ok 7).

**Evidence:** `test/scripts/dev-cycle.bats:126-156`, `test/scripts/dev-cycle.bats:157-190`, `fc15/bats.log`

---

## Claim 7: "section 2 names a skipped log even when other triggers print; a symlinked archive stops section 3" (test 10's name and its section 3 assertion)

**Location:** `test/scripts/dev-cycle.bats:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the banner assertion at `:218` and its pass/fail on new and old code. It does not establish the other section 3 branches (probed in `probe.log`, Claims 4, 5, 10).

`[[ "$section3" == *"**Watched questions were NOT checked** — docs/working/questions-archive.md is not read"* ]]` (`test/scripts/dev-cycle.bats:218`). It passes on f47de85 and fails on 096042b, whose section 3 printed the note and then `Watched questions were NOT checked: questions.sh reads the archive too.` (`oldcode.log`). Test 10 runs to `:227`; the rest is Claim 8.

**Evidence:** `test/scripts/dev-cycle.bats:207-227`, `fc15/oldcode.log`, `fc15/bats.log`

---

## Claim 8: "A plain record with no triggers beside a skipped log: the summary must not claim every input was skipped."

**Location:** `test/scripts/dev-cycle.bats:220-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the case built is the mixed case (`002-none.md` plain without triggers, `001-plain.md` removed, `log.md` still a symlink) and that the assertion would catch the old sentence. It does not establish an explicit negative assertion on the old text (none is needed: section 2 prints one of the two sentences, `scripts/dev-cycle.sh:238-239`).

`printf '# 002\n\nno triggers here\n' > docs/decisions/002-none.md` / `rm docs/decisions/001-plain.md` / `run --separate-stderr bash "$DC"` / `[[ "$section2" == *"No revisit triggers in the decision inputs that were read; the skipped ones above were not read."* ]]` (`test/scripts/dev-cycle.bats:222-226`, test closes at `:227`). On 096042b the same layout prints `No revisit triggers read: every decision input that exists was skipped.` (`oldmixed.log`), which the assertion rejects.

**Evidence:** `test/scripts/dev-cycle.bats:207-227`, `fc15/oldmixed.log`, `fc15/bats.log`

---

## Claim 9: "Section 2's no-trigger summary no longer claims every decision input was skipped when some were read and simply had no triggers (test 10 adds the mixed case)."

**Location:** commit f920f0d (message, bullet 1)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the section 2 sentence and test 10 being the tenth `@test` (`:207`). Same residue as Claim 2.

See Claims 2 and 8. Test 10: the tenth `@test` line in the file is `@test "section 2 names a skipped log even when other triggers print; a symlinked archive stops section 3" {` (`test/scripts/dev-cycle.bats:207`), and it is `ok 10` in `bats.log`.

**Evidence:** `scripts/dev-cycle.sh:237-240`, `test/scripts/dev-cycle.bats:207-227`, `fc15/probe.log`, `fc15/bats.log`

---

## Claim 10: "Section 3: a missing questions.md or questions.sh is reported as before even when the archive is a symlink; a skipped archive prints the bold "Watched questions were NOT checked" banner step 3 acts on; when questions.md itself is skipped, the archive is still checked so it is listed in section 8 the same cycle."

**Location:** commit f920f0d (message, bullet 2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers all 32 combinations in `probe.log` P1 (questions.md and archive each absent / plain / symlink / directory, questions.sh present and absent) plus a symlinked `docs/working/`. It does not establish that a non-plain archive is listed when questions.md is absent or questions.sh is missing: then the archive is not examined and section 8 says "None" (by design, "as before", but a reader of section 8 alone does not learn of it).

Branch order: questions.md skipped (`scripts/dev-cycle.sh:249`), then plain questions.md + questions.sh + skipped archive (`:252`), then run questions.sh (`:254`), else `No docs/working/questions.md (or questions.sh) in this repo.` (`:273`). `probe.log` P1: `qs=present questions=absent archive=link` and `qs=absent questions=plain archive=link` print the `No docs/working/questions.md (or questions.sh)` line, not an archive note; the banner prints only for `qs=present questions=plain archive=link|dir`; `questions=link|dir` with `archive=link|dir` lists both in section 8. "As before" checked against 096042b: its first two branches were `if skipped docs/working/questions.md` / `elif skipped "$QA"`, so an absent questions.md beside a symlinked archive printed the archive note (paraphrased — no quote available because the claim compares against a removed branch; the removed lines are in the `git show f920f0d` diff hunk at `@@ -243,12 +243,14 @@`).

**Evidence:** `scripts/dev-cycle.sh:242-274`, `fc15/probe.log` (P1)

---

## Claim 11: "The comment says what questions.sh actually does with the archive: an existence test that follows a symlink."

**Location:** commit f920f0d (message, bullet 3)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers `questions.sh open`, the only subcommand the digest runs. Same residue as Claim 3.

See Claim 3: `[[ -f "$file" ]]` in `require_files` (`scripts/questions.sh:135`) is the only use of `$ARCHIVE` on the `open` path (`:408-414`).

**Evidence:** `scripts/questions.sh:132-137`, `scripts/questions.sh:408-414`

---

## Claim 12: "Loop pass 14 (api F1, F3, F6; security Info 1, 2): … 23/23; shellcheck clean."

**Location:** commit f920f0d (message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the finding IDs against the pass-14 rubric and reviews, and the test and lint results at f47de85 (the worktree's `scripts/` and `test/` equal f47de85). It does not establish shellcheck on the bats file.

Rubric pass 14: `| R1 | … | fact-check 6; api F1; security Info 1 | f920f0d (+ test 10 mixed case) |`, `| A2 | … | api F3, F6; fact-check 9 | f920f0d; cb2e5f9 … |`, `| C1 | … | fact-check 2, 7a, 20; security Info 2; performance Info | f920f0d, f47de85; … |` (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:462-466`). F1, F3, F6 exist as headings at `docs/reviews/api-consistency-review-2026-10-01-digest-pass14.md:35`, `:80`, `:148`. `bats.log`: 23 `ok` lines, exit 0. `shellcheck.log`: empty, exit 0.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:454-466`, `docs/reviews/api-consistency-review-2026-10-01-digest-pass14.md:35`, `fc15/bats.log`, `fc15/shellcheck.log`

---

## Claim 13: "docs(dev-cycle): comment names dirok as the glob gate … Loop pass 14 fact-check Claim 2."

**Location:** commit f47de85 (message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the one-word comment change and its reference. Nothing else is in the commit.

The diff changes only `-# use rawfile directly: their directory has already passed plaindir.)` to `+# use rawfile directly: their directory has already passed dirok.)` (`scripts/dev-cycle.sh:116`), the precise version pass-14 Claim 2 gave ("Precise version: "their directory has already passed dirok"", `docs/reviews/code-fact-check-report-digest-pass14.md`, Claim 2).

**Evidence:** `scripts/dev-cycle.sh:116`, `docs/reviews/code-fact-check-report-digest-pass14.md:39-52`

---

## Claim 14: "It says "records, or a directory above them, were skipped", or names a newer record that was skipped"

**Location:** `skills/dev-cycle/SKILL.md:103-104`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the quoted phrase is a verbatim substring of the digest's Window note and that the second case matches the newer-skipped-record note. It does not establish that the Window line flags skipped records when `--since` is given (it then says only `(from --since)`, `scripts/dev-cycle.sh:165`; pre-existing, and the rerun step 0 asks for uses `--since`, so the bullet cannot fire again on the rerun, which is what makes it terminate).

Digest text: `source_note="no readable cycle record (records, or a directory above them, were skipped as not a plain file or directory: section 8), so the default of 14 days"` (`scripts/dev-cycle.sh:174`), which contains `records, or a directory above them, were skipped` exactly. The newer-record case: `source_note+="; a newer record, docs/working/cycles/cycle-$skipped_record.md, was skipped as not a plain file (section 8), so this window may start too early"` (`:169`). Both reach the Window line through `(from $source_note)` (`:183`).

**Evidence:** `scripts/dev-cycle.sh:164-183`, `skills/dev-cycle/SKILL.md:101-111`

---

## Claim 15: "file one `agent` entry listing the paths section 8 gives, unless an open one already reports them"

**Location:** `skills/dev-cycle/SKILL.md:106-107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the guard stops a second entry while one is open. It does not establish what happens when section 8 lists more paths than the open entry reports (the guard reads "reports them", so a new path would justify a new entry; the text does not say whether to extend the open one instead).

`Note that in this record, file one \`agent\` entry listing the paths section 8 gives, unless an open one already reports them (never read, copy or rewrite through them)` (`skills/dev-cycle/SKILL.md:105-107`). Before cb2e5f9 the sentence had no guard (`file one \`agent\` entry listing the paths section 8 gives (never read, …)`, the removed line in the cb2e5f9 diff).

**Evidence:** `skills/dev-cycle/SKILL.md:103-108`

---

## Claim 16: "If the digest says `questions.sh open` failed, or that watched questions were NOT checked (a skipped archive), fix or report that first; the section was not checked."

**Location:** `skills/dev-cycle/SKILL.md:156-157`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that both digest messages it names exist and mean the section was not checked. It does not establish handling of a skipped questions.md: the digest then prints `docs/working/questions.md is not read: …` with no banner (`scripts/dev-cycle.sh:249-250`), which this bullet does not name; section 8 and the record's `## Skipped inputs` carry it.

Digest: `echo "**Watched questions were NOT checked** — $(skipnote "$QA")"` (`scripts/dev-cycle.sh:253`) and `echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"` (`:268`). Both appear in `probe.log` P1 (`questions=plain archive=link` and `questions=plain archive=absent`, the latter because `require_files` fails on the missing archive).

**Evidence:** `scripts/dev-cycle.sh:249-274`, `skills/dev-cycle/SKILL.md:146-157`, `fc15/probe.log` (P1)

---

## Claim 17: "Every cycle checks each, in this order: 1. Its branch merged … Either way the brief gets `Status: closed`. 2. Apply any answer … 3. Then, if the branch has no commit beyond the default branch …"

**Location:** `skills/dev-cycle/SKILL.md:223-237`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the order (close, apply, ask), that each step runs once per brief per cycle (so the rule terminates), and that the three steps cover merged, dropped, answered and stale briefs. It does not establish that steps 2 and 3 skip a brief that step 1 closed: the text does not say so.

The order is right and it terminates: the list is numbered and step 3 opens with "Then" (`skills/dev-cycle/SKILL.md:225-237`). The gap is wording: steps 2 and 3 have no "if the brief is still open". Read literally, a brief whose branch step 1 just found merged also meets step 3's condition, because a merged branch "has no commit beyond the default branch" (`SKILL.md:234`). If its brief is 14+ days old, step 3 would then file "keep or drop the brief for <item>?" for an item that is already Done. The list heading ("items with an open build brief", `:223`) points the other way, so a careful reader skips it. Precise version: "2. If the brief is still open, apply …" and "3. Then, if it is still open and the branch has no commit …".

**Evidence:** `skills/dev-cycle/SKILL.md:223-237`

---

## Claim 18: "(step 1 has already archived answered entries)"

**Location:** `skills/dev-cycle/SKILL.md:228-229`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers what "step 1" refers to. It does not establish that the archive run happened (that is cycle step 1's own instruction).

The fact is right for the cycle's step 1: `\`~/.claude/scripts/questions.sh archive\` then \`index\`, so answered entries leave the live file.` (`skills/dev-cycle/SKILL.md:124-125`). But the parenthesis now sits inside In-flight item 2, right after an In-flight item numbered 1 ("Its branch merged …", `:225`), which archives nothing. The same item then says `"drop" closes the brief as in 1` (`:233`), where "1" does mean In-flight item 1. So within one item, "step 1" is the cycle step and "1" is the In-flight step. Precise version: "(the cycle's step 1, health and cleanup, has already archived answered entries)".

**Evidence:** `skills/dev-cycle/SKILL.md:117-125`, `skills/dev-cycle/SKILL.md:225-233`

---

## Claim 19a: "Apply it only if it is dated after the brief's last `Kept:` date (no `Kept:` yet: on or after the brief's own date) and not after today, so each answer counts once and an older brief's answer never applies." (answers with a written date)

**Location:** `skills/dev-cycle/SKILL.md:230-233`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers an answer that carries its own date. It does not establish the undated case (Claim 19b), or an answer dated on a brief's creation day for an older brief of the same item (it passes "on or after the brief's own date"; possible only if the old question was answered the day the new brief was written).

A dated "keep" writes `Kept: <the answer's date>` (`SKILL.md:233`); on the next cycle the same answer is not "dated after" that `Kept:`, so it is skipped: counts once. An older brief's dated answer predates the new brief (the question is filed only 14 days after a brief, `:234-236`), so it fails "on or after the brief's own date". "Not after today" rejects future dates.

**Evidence:** `skills/dev-cycle/SKILL.md:227-237`

---

## Claim 19b: "An answer's date is the one written with it, else today. … so each answer counts once and an older brief's answer never applies." (answers with no written date)

**Location:** `skills/dev-cycle/SKILL.md:229-232`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers an answer recorded without a date. It does not establish how often that happens (the questions grammar has no answer-date field, and the one-line answer form `Q-NNN: [2]` carries none; pass-14 api F5 (b) noted the same).

The "else today" date changes every cycle, so neither guarantee holds for an undated answer (paraphrased — no quote available because the claim is about what the rule yields over successive cycles, not one line). Keep: cycle 1 dates it T1 and writes `Kept: T1`; cycle 2 dates the same answer T2 > T1, which is "dated after the brief's last `Kept:` date", so it applies again and writes `Kept: T2`, and so on. It counts every cycle, the 14-day clock in step 3 never runs out, and the brief holds one of the three brief slots (`SKILL.md:247-248`) with no further ask. Drop: an older brief's undated "drop" for the same item (the question text is the same, "keep or drop the brief for <item>?", `:227`, `:236`) is dated today, which is on or after a newer brief's date, so it closes the newer brief. Preconditions: an undated answer to a keep-or-drop question, found by the search in step 2. Effect: a stuck brief slot (keep) or a wrongly closed brief (drop, only when an item gets a second brief). Precise version: write the date into the entry when the answer is first applied (or treat an undated answer as dated by its `Opened:` date), so the date never moves.

**Evidence:** `skills/dev-cycle/SKILL.md:227-237`, `skills/dev-cycle/SKILL.md:247-248`, `docs/reviews/api-consistency-review-2026-10-01-digest-pass14.md:129-147`

---

## Claim 20: "if the branch has no commit beyond the default branch (or does not exist yet) 14 days after the brief's date or its last `Kept:` date"

**Location:** `skills/dev-cycle/SKILL.md:234-235`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers which date starts the 14 days. It does not establish anything about the open-question guard (that holds: "and no such question is open", `:235-236`).

"The brief's date or its last `Kept:` date" does not say which one wins. The intended reading is the later one (the last `Kept:` if there is one, else the brief's date), as step 2 spells out for its own comparison: `(no \`Kept:\` yet: on or after the brief's own date)` (`SKILL.md:231`). Read as "either", the brief's own date is always more than 14 days back once a first question has been asked, so a brief kept in step 2 would get a new question in step 3 the same cycle: the duplicate ask cb2e5f9 sets out to stop. Precise version: "14 days after its last `Kept:` date (no `Kept:` yet: the brief's date)".

**Evidence:** `skills/dev-cycle/SKILL.md:227-237`

---

## Claim 21: "In flight is now three ordered steps: close merged/dropped briefs, apply keep/drop answers, then ask. Applying answers before asking stops the duplicate question a "keep" produced once step 1 had archived it."

**Location:** commit cb2e5f9 (message, bullet 1, first two sentences)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the reordering and the pass-14 G1 scenario (a dated keep, archived by cycle step 1, then applied before the ask check). It does not establish the "either" reading of step 3's dates (Claim 20) or a future-dated answer (not applied, so the next ask can file while the answer sits in the archive).

G1's scenario: a keep answered between cycles, archived in cycle step 1 (`SKILL.md:124-125`), is no longer open. Now step 2 applies it first (`Kept: <date>`, `:233`), and step 3 counts 14 days from that `Kept:` (`:234-235`), so no question is filed this cycle. Under the old text the ask condition came first in the paragraph (the removed lines in the cb2e5f9 diff). An undated keep (Claim 19b) does not cause a duplicate ask either: it suppresses all asks.

**Evidence:** `skills/dev-cycle/SKILL.md:117-125`, `skills/dev-cycle/SKILL.md:223-237`, `docs/reviews/code-fact-check-report-digest-pass14.md:435`

---

## Claim 22: "Answers are dated (the date written with them, else today) and apply only after the last Kept: date (or on/after the brief's own date) and not after today, so each counts once and an older brief's answer never applies."

**Location:** commit cb2e5f9 (message, bullet 1, last sentence)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Same as Claims 19a and 19b: true for dated answers, false for undated ones. Split not repeated here; the most severe part (undated) carries the verdict.

The rule described matches `SKILL.md:229-233`, and its stated guarantees fail for an answer with no written date, whose "today" date moves every cycle (see Claim 19b; paraphrased — no quote available because the reasoning spans successive cycles).

**Evidence:** `skills/dev-cycle/SKILL.md:227-237`

---

## Claim 23: "Step 0 quotes the digest's Window text exactly and files the skipped-records entry only if none is open. Step 3 also acts on "Watched questions were NOT checked". … Loop pass 14 (fact-check G1; api F2–F5; security Info 3)"

**Location:** commit cb2e5f9 (message, bullets 2–3 and reference line)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the two bullets (see Claims 14, 15, 16) and that each finding ID exists and is mapped to cb2e5f9 in the rubric. It does not establish that the security review's Info 3 text matches the fix (only the rubric's mapping was checked).

Rubric: `| A1 | … | fact-check G1; security Info 3; api F5 | cb2e5f9: … |`, `| A2 | … | api F3, F6; fact-check 9 | f920f0d; cb2e5f9 (step 3 acts on the banner) |`, `| A3 | Step 0 quoted the Window text loosely and could file a duplicate entry each cycle | 🟡 | api F2, F4 | cb2e5f9 |` (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:463-465`). F2–F5 exist at `docs/reviews/api-consistency-review-2026-10-01-digest-pass14.md:60`, `:80`, `:109`, `:129`.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:460-466`, `skills/dev-cycle/SKILL.md:103-107`, `skills/dev-cycle/SKILL.md:156-157`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19b** (`skills/dev-cycle/SKILL.md:229-232`): **behavioral.** An undated answer is dated "today" each cycle, so a keep re-applies every cycle (the brief never ages out and holds a slot) and an older brief's undated drop can close a newer brief for the same item. Fix: fix the date once (write it when first applied, or use the entry's `Opened:`).
- **Claim 22** (commit cb2e5f9): same defect as 19b, stated in the commit message ("so each counts once and an older brief's answer never applies").

### Stale
- None.

### Mostly Accurate
- **Claim 17** (`skills/dev-cycle/SKILL.md:223-237`): **wording.** In-flight steps 2 and 3 do not say "if still open"; read literally, step 3 asks keep-or-drop for a brief step 1 just closed as merged.
- **Claim 18** (`skills/dev-cycle/SKILL.md:228-229`): **wording.** "step 1 has already archived" means the cycle's step 1 but sits right after In-flight item 1, and the same item uses "as in 1" for the In-flight item. Say "the cycle's step 1".
- **Claim 20** (`skills/dev-cycle/SKILL.md:234-235`): **wording** (behavioral under the "either" reading). "14 days after the brief's date or its last `Kept:` date": say "its last `Kept:` date (no `Kept:` yet: the brief's date)".

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass15.md` with the required first line, header fields (including `**Replication:** k=1 (loop pass, decision 031)`), seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary. Against the round's aims: A holds in every probed combination (section 2's summary is true in mixed and all-skipped cases; section 3 reports a missing questions.md / questions.sh first, prints the bold banner for a skipped archive, lists the archive when questions.md is skipped; both comments are accurate). B's step 0 quote, duplicate guard and step 3 banner reference hold; the In-flight rule is ordered and terminates, but its "each answer counts once / an older brief's answer never applies" guarantee fails for undated answers (one behavioral Incorrect, mirrored in the commit message), and three wording issues remain in the new In-flight list. Not committed, per the brief.
