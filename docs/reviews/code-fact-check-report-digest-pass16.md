Commit: 09f6fe7 (A) / 5423a33 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 09f6fe7; HEAD 6d4000d adds review docs only, `git diff --stat 09f6fe7 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 5423a33; HEAD 54ce432 merges the digest branch, `git diff 5423a33 HEAD -- skills/dev-cycle/SKILL.md` is empty).
**Scope:** Partial: the pass-15 fix round only. A: `git diff f47de85..09f6fe7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of commit 09f6fe7. B: `git diff cb2e5f9..5423a33 -- skills/dev-cycle/SKILL.md` plus the message of commit 5423a33. Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 20
**Summary:** 18 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc16/` (below, `fc16/`). Every throwaway repo was built under its own `mktemp -d` directory, removed on exit; every process ran under `timeout`. Nothing was written to either worktree except this report. **Working-tree note:** when this report was saved, B's worktree showed an uncommitted edit to `skills/dev-cycle/SKILL.md` that this run did not make. Every B verdict is against the committed text (`git show 5423a33:skills/dev-cycle/SKILL.md`, saved as `fc16/SKILL.md`), not that edit.
- `bats.log`: `timeout 300 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-10-02T06:50:10Z, 23/23 ok (test 10 is "section 2 names a skipped log even when other triggers print; a symlinked archive stops section 3").
- `shellcheck.log`: `timeout 60 shellcheck scripts/dev-cycle.sh`, same cwd, exit 0, empty output (0 bytes), 2026-10-02T06:50:55Z.
- `probe.log` (script `fc16/probe.sh`): `timeout 300 bash probe.sh`, exit 0, 2026-10-02T06:50:30Z. Section 3 and section 8 of the 09f6fe7 script for questions.md x archive, each absent / plain / symlinked / a directory (16 combinations), each with questions.sh present (copied beside the script) and absent (script alone, `$HOME` empty): 32 runs; plus a symlinked `docs/working/` with questions.md absent and present below it, questions.sh present and absent: 4 runs.
- `oldcode.log` (script `fc16/oldcode.sh`): `timeout 120 bash oldcode.sh`, exit 0, 2026-10-02T06:50:55Z. The f47de85 script with a symlinked archive in two cases (questions.md absent; questions.sh absent).
- `SKILL.md`: `git show 5423a33:skills/dev-cycle/SKILL.md`, the B text every B line number below refers to.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) present and consulted; no claim matches a logged pattern, and there are no Incorrect verdicts, so nothing is added (the brief also allows no write besides this report).

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or the record).

---

## Claim 1: "questions.sh checks that the archive exists with a test that follows a symlink, which would answer "does this host path exist?", so the archive passes the same check first. It is checked once, up front, so a non-plain archive is listed in section 8 whatever branch below runs."

**Location:** `scripts/dev-cycle.sh:246-250`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the questions.sh existence test, the single up-front `skipped "$QA"` call, and section 8's listing in all 36 probed states; does not establish what section 3's text says about the archive when questions.md is absent (it says nothing, Claim 3) or questions.sh behavior beyond `open` / `init`.

questions.sh's test follows symlinks: `[[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }` (`scripts/questions.sh:135`, inside `require_files`, which `cmd_open` calls first at `:409`). The digest checks the archive before the chain: `qa_at=""; skipped "$QA" && qa_at="$SKIP_AT"` (`scripts/dev-cycle.sh:250`), unconditionally, and `skipped` appends to `SKIPPED` (`:121`: `skipped() { SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }`), which section 8 prints (`:372-377`). Executed: in every probe with a symlinked or directory archive, section 8 lists `- docs/working/questions-archive.md`, whatever section 3 printed (questions.md absent, plain, symlinked, a directory; questions.sh present or not), e.g. `QS=without q=plain a=sym ... S8: - docs/working/questions-archive.md` (`fc16/probe.log`). With `docs/working/` itself symlinked, section 8 lists the blocking part `- docs/working/` instead, which is the documented rule (`:99-101`: "the blocking part is what section 8 lists"). Before the fix the archive went unlisted in two branches: `OLD f47de85 QS=with questions.md=absent archive=sym :: No docs/working/questions.md (or questions.sh) in this repo. :: S8: ... None: no input was skipped.` (`fc16/oldcode.log`).

**Evidence:** `scripts/dev-cycle.sh:121`, `scripts/dev-cycle.sh:246-250`, `scripts/dev-cycle.sh:372-377`, `scripts/questions.sh:132-138`, `scripts/questions.sh:408-409`, `fc16/probe.log`, `fc16/oldcode.log`

---

## Claim 2: "**Watched questions were NOT checked** — <cause>" printed for every not-checked outcome (questions.md skipped; questions.sh missing; archive skipped; `questions.sh open` failing)

**Location:** `scripts/dev-cycle.sh:251-279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers every branch of the section 3 chain (read whole, `:242` to the closing `fi` at `:279`) in the 36 probed states plus test 11's failing-`open` case; does not establish that questions.sh's own output is right when `open` succeeds (unchanged, context only).

The chain, quoted whole:

```bash
# scripts/dev-cycle.sh:251-261
nc="**Watched questions were NOT checked** —"
if skipped docs/working/questions.md; then
  echo "$nc $(skipnote docs/working/questions.md)"
elif ! inrepo docs/working/questions.md; then
  echo "No docs/working/questions.md in this repo."
elif [[ ! -f "$QS" ]]; then
  echo "$nc questions.sh was not found (next to this script or in ~/.claude/scripts)."
elif [[ -n "$qa_at" ]]; then
  SKIP_AT="$qa_at"; echo "$nc $(skipnote "$QA")"
else
  qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT
```
(excerpt ends :261; the `else` branch continues to :279 — read: on success it lists watched entries and "Open by route"; on failure `:274` `echo "$nc questions.sh open failed. Its error:"` then the captured stderr.)

The branches are exhaustive and exclusive (an `if/elif/else` chain). In the archive branch `SKIP_AT="$qa_at"` restores the archive's blocker, since the earlier `skipped docs/working/questions.md` call overwrote `SKIP_AT` with an empty value; `skipnote` (`:123`) reads `$SKIP_AT`. Executed: each state prints the expected banner and cause, e.g. `q=plain a=sym` → "— docs/working/questions-archive.md is not read: docs/working/questions-archive.md is not a plain file or directory (section 8)."; `QS=without q=plain` → "— questions.sh was not found ..."; `QS=with q=plain a=absent` → "— questions.sh open failed. Its error:"; `q=sym` / `q=dir` → "— docs/working/questions.md is not read: ..."; symlinked `docs/working/` → "— docs/working/questions.md is not read: docs/working/ is not ..." (`fc16/probe.log`). The only not-banner outcomes are "No docs/working/questions.md in this repo." (absent, Claim 3) and a successful `open`.

**Evidence:** `scripts/dev-cycle.sh:123`, `scripts/dev-cycle.sh:242-279`, `fc16/probe.log`, `fc16/bats.log`

---

## Claim 3: "No docs/working/questions.md in this repo."

**Location:** `scripts/dev-cycle.sh:254-255`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers that the message prints exactly when questions.md is absent with a plain path to it, whatever the archive and questions.sh states; does not establish that section 3 mentions a skipped archive in that case (it does not; the archive appears only in section 8).

`elif ! inrepo docs/working/questions.md; then` (`:254`) is reached only after `skipped docs/working/questions.md` returned false (no blocking part), so `inrepo` (`:117`: `[[ -z "$(blocker "$1" file)" && -f "$1" ]]`) is false only when the file is absent. Executed: all 8 `q=absent` runs print it (archive absent / plain / symlinked / a directory, questions.sh present or not), and a missing questions.sh no longer prints it (`QS=without q=plain` gives the banner) (`fc16/probe.log`). With `docs/working/` symlinked and questions.md absent below it, the digest prints the banner instead, because the walk blocks at `docs/working/` before existence is probed (`fc16/probe.log`, `SYMDIR QS=with inner=absent`).

**Evidence:** `scripts/dev-cycle.sh:117`, `scripts/dev-cycle.sh:252-255`, `fc16/probe.log`

---

## Claim 4: "questions.sh was not found (next to this script or in ~/.claude/scripts)."

**Location:** `scripts/dev-cycle.sh:256-257`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the two lookup locations and the message; does not establish behavior when a found questions.sh is not executable or is another project's script (it runs with `bash`, not exec).

`QS="$SCRIPT_DIR/questions.sh"` then `[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`:243-244`), so `[[ ! -f "$QS" ]]` at `:256` means neither location holds it. Executed with the script copied alone and `$HOME` empty: "**Watched questions were NOT checked** — questions.sh was not found (next to this script or in ~/.claude/scripts)." (`fc16/probe.log`, all `QS=without q=plain` rows).

**Evidence:** `scripts/dev-cycle.sh:243-244`, `scripts/dev-cycle.sh:256-257`, `fc16/probe.log`

---

## Claim 5: "If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first."

**Location:** `skills/dev-cycle/SKILL.md:99-100`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that the digest's absent-file message (Claim 3) still matches this condition after the message changed, and that no remaining text quotes the old "(or questions.sh)" message; does not establish what init does in a repo whose `docs/working/` is symlinked (questions.sh's `assert_write_targets` refuses, context only).

The digest now prints "No docs/working/questions.md in this repo." for exactly the absent case (Claim 3), which is the condition step 0 names. The old text "No docs/working/questions.md (or questions.sh) in this repo." no longer appears in either worktree outside `docs/reviews/` (paraphrased — no quote available because the claim covers absence of code: `rg -n "or questions.sh\) in this repo"` over both worktrees, excluding `docs/reviews/`, returned no hits). A missing questions.sh now produces the banner (Claim 4), so it no longer reads as "no questions.md" and cannot send step 0 to `init` when the file exists.

**Evidence:** `skills/dev-cycle/SKILL.md:99-100`, `scripts/dev-cycle.sh:254-257`, `fc16/probe.log`

---

## Claim 6: "If the digest says watched questions were NOT checked (it gives the cause: a skipped questions file or archive, questions.sh missing, or `questions.sh open` failing), fix or report that first; the section was not checked."

**Location:** `skills/dev-cycle/SKILL.md:156-158`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that every banner the digest prints carries the phrase step 3 keys on and that the four causes listed are exactly the four banner branches; does not establish step 3's handling of the absent-file case (step 0's `init`, Claim 5) or that the phrase matches case-sensitively (the skill writes "watched", the digest "**Watched").

The digest's banners all start with `nc="**Watched questions were NOT checked** —"` (`scripts/dev-cycle.sh:251`), and the four branches using it are a skipped questions.md (`:252-253`, including a symlinked `docs/working/`), questions.sh missing (`:256-257`), a skipped archive (`:258-259`) and `open` failing (`:274`). Each was observed in `fc16/probe.log`. The skill's cause list names the same four.

**Evidence:** `skills/dev-cycle/SKILL.md:156-158`, `scripts/dev-cycle.sh:251-259`, `scripts/dev-cycle.sh:274`, `fc16/probe.log`

---

## Claim 7a: "Each such question names the brief's path; the brief keeps an `Answered:` line listing the IDs of the ones already applied. ... apply each answered one whose ID is not on that line" (each answer counts once; an old brief's answer never applies)

**Location:** `skills/dev-cycle/SKILL.md:228-233`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers once-only application (both "keep" and "drop" add the ID before any later cycle reads the line) and non-matching across briefs (paths differ by date and slug); does not establish behavior for an answer that is neither keep nor drop, or for a brief path reused when an item is re-briefed with the same slug on the same date.

Quoted whole (step 2):

```markdown
<!-- skills/dev-cycle/SKILL.md:228-233 -->
2. If the brief is still open, apply answers to its keep-or-drop questions. Each such question names the brief's path;
   the brief keeps an `Answered:` line listing the IDs of the ones already applied. Search
   `questions.md` and `questions-archive.md` for questions naming this brief (the cycle's
   step 1 has already archived answered entries; search, do not read the archive whole), and apply
   each answered one whose ID is not on that line: "keep" adds its ID to `Answered:` and
   sets `Kept: <today>`; "drop" adds its ID and closes the brief as in 1.
```

Both outcomes add the ID, and step 2 skips IDs already on the line, so an answer applies once; there is no date in the key, so the pass-15 undated-answer defect is gone. Step 3 files its question as "keep or drop <brief path>?" (`:236`), so the "names the brief's path" premise holds for every question this skill files. Brief paths are `docs/working/handoffs/YYYY-MM-DD-<slug>.md` (`:249`); a new brief for the same item on a later date has a different path, and with the `.md` suffix one brief's path is not a substring of another's.

**Evidence:** `skills/dev-cycle/SKILL.md:228-237`, `skills/dev-cycle/SKILL.md:249`

---

## Claim 7b: "Search `questions.md` and `questions-archive.md` for questions naming this brief ... and apply each answered one whose ID is not on that line"

**Location:** `skills/dev-cycle/SKILL.md:229-232`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the search filter's breadth against the step's own subject ("its keep-or-drop questions"); does not establish how often other questions name a brief path in practice.

The step opens with "apply answers to its keep-or-drop questions" (`:228`), but the operative filter is "questions naming this brief" and "each answered one" (`:230-232`). Any other answered question that cites the brief's path (for instance, one the user's build session files about an acceptance criterion, or a step 3 note on a stuck `agent` entry linking the brief) passes that filter, and the step defines an effect only for "keep" and "drop" (`:232-233`). The mechanism (path match plus `Answered:` IDs) is right; the precise version is "search for keep-or-drop questions naming this brief". **Wording.**

**Evidence:** `skills/dev-cycle/SKILL.md:228-233`

---

## Claim 8: "(the cycle's step 1 has already archived answered entries; search, do not read the archive whole)"

**Location:** `skills/dev-cycle/SKILL.md:230-231`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the cycle's step 1 runs `archive` before step 6, and that "the cycle's step 1" no longer collides with In-flight item 1; does not establish that `archive` succeeds (if it fails, answered entries stay in questions.md, which step 2 also searches).

Cycle step 1: "`~/.claude/scripts/questions.sh archive` then `index`, so answered entries leave the live file." (`skills/dev-cycle/SKILL.md:124-125`), and the flow runs 1 before 6 (`:81-82`). The parenthetical now says "the cycle's step 1", distinct from item 1's "as in 1" (`:233`). Searching both files covers the case where an answered entry has not moved.

**Evidence:** `skills/dev-cycle/SKILL.md:81-82`, `skills/dev-cycle/SKILL.md:124-125`, `skills/dev-cycle/SKILL.md:230-233`

---

## Claim 9: ""keep" adds its ID to `Answered:` and sets `Kept: <today>`; "drop" adds its ID and closes the brief as in 1."

**Location:** `skills/dev-cycle/SKILL.md:232-233`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers both outcomes and the cross-reference to item 1; does not establish the order of application if two unapplied answers for one brief exist at once (the guard in step 3 makes that require a question filed outside this skill).

Item 1 reads: "The user dropped it (closed the brief, or said so) → Ideas, with the reason. Either way the brief gets `Status: closed`." (`:226-227`), so "closes the brief as in 1" has a defined meaning. `Kept: <today>` restarts step 3's clock (Claim 10), so a "keep" cannot trigger a new ask in the same cycle. Only one keep-or-drop question per brief can be open (step 3's guard, `:235-236`) and step 2 applies an answer the cycle after it is given, before step 3 runs, so at most one unapplied answer normally exists.

**Evidence:** `skills/dev-cycle/SKILL.md:226-237`

---

## Claim 10: "Then, if the brief is still open and the branch has no commit beyond the default branch (or does not exist yet) 14 days after the brief's last `Kept:` date (none yet: the brief's own date) ... file one `you: judgment` entry, "keep or drop <brief path>?". Until it is answered, the brief still holds its slot."

**Location:** `skills/dev-cycle/SKILL.md:234-237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the still-open guard, the single clock origin, and that the filed question names the path step 2 searches for; does not establish the breadth of the "no question naming this brief is open" guard (Claim 11).

The clock now has one origin: the last `Kept:` date, falling back to the brief's own date (`:235`). "If the brief is still open" (`:234`) excludes briefs item 1 or step 2 closed. The filed text "keep or drop <brief path>?" (`:236`) satisfies step 2's "Each such question names the brief's path" (`:228`). "Still holds its slot" agrees with the brief cap "while fewer than 3 briefs are open" (`:248`).

**Evidence:** `skills/dev-cycle/SKILL.md:228`, `skills/dev-cycle/SKILL.md:234-237`, `skills/dev-cycle/SKILL.md:247-248`

---

## Claim 11: "and no question naming this brief is open"

**Location:** `skills/dev-cycle/SKILL.md:235-236`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the duplicate-ask guard's breadth; does not establish that a wider guard is unintended (holding the ask while any open question cites the brief is a defensible reading).

The guard's purpose is not to ask keep-or-drop twice, and it does that. But as written, any open question that cites the brief's path (the same breadth as Claim 7b) suppresses the ask, so a stale brief can keep its slot, unasked, for as long as an unrelated open entry naming it stays open. The precise version is "no keep-or-drop question naming this brief is open". **Behavioral, narrow:** needs an open non-keep-or-drop entry that cites the brief path.

**Evidence:** `skills/dev-cycle/SKILL.md:234-237`

---

## Claim 12: "Every cycle checks each, in this order:" (items 1–3: exhaustive, ordered, terminating, no duplicate ask)

**Location:** `skills/dev-cycle/SKILL.md:224-237`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the control flow of the three items for one brief per cycle; does not establish the breadth issues of Claims 7b and 11.

Item 1 closes merged or dropped briefs (`:226-227`); items 2 and 3 each open with "If the brief is still open" / "if the brief is still open" (`:228`, `:234`), so a closed brief takes no further action; item 2 applies only unapplied IDs (finite); item 3 files at most one question, guarded against an open one. Every path ends in one of: closed, kept (clock restarted), asked, or unchanged. No step loops.

**Evidence:** `skills/dev-cycle/SKILL.md:224-237`

---

## Claim 13: "later cycles add `Kept:` and `Answered:` lines (In flight, above)"

**Location:** `skills/dev-cycle/SKILL.md:251-252`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the brief format names both lines and points at the section that writes them; does not establish their exact line syntax (comma or space separated IDs are not specified).

In flight (above the build-briefs paragraph) writes both: "adds its ID to `Answered:` and sets `Kept: <today>`" (`:232-233`). Only later cycles write them, since step 2 runs on briefs already In flight.

**Evidence:** `skills/dev-cycle/SKILL.md:232-233`, `skills/dev-cycle/SKILL.md:247-253`

---

## Claim 14: "section 2 names a skipped log even when other triggers print; a symlinked archive stops section 3"

**Location:** `test/scripts/dev-cycle.bats:207`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that test 10's name still describes its assertions after the new absent-questions.md case was added; does not establish anything about other tests' names.

The test still asserts the skipped log in section 2 (`:215-216`) and the archive banner in section 3 (`:217-219`); the new case (Claim 15) and the later mixed case (`:227-233`) extend it without contradicting the name. `ok 10 section 2 names a skipped log even when other triggers print; a symlinked archive stops section 3` (`fc16/bats.log`).

**Evidence:** `test/scripts/dev-cycle.bats:207-234`, `fc16/bats.log`

---

## Claim 15: "No questions.md: reported as absent, and the symlinked archive is still listed in section 8."

**Location:** `test/scripts/dev-cycle.bats:220-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the comment matches its two assertions and that both pass on 09f6fe7 and fail on f47de85; does not establish the missing-questions.sh case, which no test covers (probed instead, Claim 4).

```bash
# test/scripts/dev-cycle.bats:222-226
rm docs/working/questions.md
run --separate-stderr bash "$DC"
[[ "$output" == *"No docs/working/questions.md in this repo."* ]] || { echo "$output" | sed -n '/## 3/,/## 4/p'; return 1; }
[[ "$(echo "$output" | sed -n '/## 8/,$p')" == *"- docs/working/questions-archive.md"* ]] || { echo "$output" | sed -n '/## 8/,$p'; return 1; }
printf '# Running questions\n\n## Open\n' > docs/working/questions.md
```

The archive is still the dangling symlink set at `:213`. Passes at 09f6fe7 (`fc16/bats.log`). The f47de85 script printed "No docs/working/questions.md (or questions.sh) in this repo." and "None: no input was skipped." in the same state (`fc16/oldcode.log`), failing both assertions. The file is restored at `:226` before the mixed case, which needs it.

**Evidence:** `test/scripts/dev-cycle.bats:207-234`, `fc16/bats.log`, `fc16/oldcode.log`

---

## Claim 16: Commit 09f6fe7: "The archive is checked once, up front, so a non-plain archive is listed in section 8 whichever branch section 3 takes (it was missed when questions.md was absent or questions.sh missing). One chain, in order: questions.md skipped → banner; absent → "No docs/working/questions.md in this repo."; questions.sh missing → banner; archive skipped → banner; else run. Every "not checked" outcome prints "**Watched questions were NOT checked** — <cause>", including `questions.sh open` failing; a missing questions.sh no longer reads as a missing questions.md."

**Location:** commit 09f6fe7 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers each sentence against the 09f6fe7 code and the f47de85 baseline; does not establish anything outside section 3 and section 8.

The order matches `scripts/dev-cycle.sh:252-279` (quoted in Claim 2). The "missed" baseline is shown in `fc16/oldcode.log` for both named cases. The rest is Claims 1–4.

**Evidence:** `scripts/dev-cycle.sh:246-279`, `fc16/probe.log`, `fc16/oldcode.log`

---

## Claim 17: Commit 09f6fe7: "Loop pass 15 (api F2, F3, F5; security Info 2): ... Test 10 adds the absent-questions.md case. 23/23; shellcheck clean."

**Location:** commit 09f6fe7 (message body)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the references, the test count and shellcheck at 09f6fe7; does not establish that the referenced findings are fully resolved beyond what Claims 1–4 show.

The api report has `#### F2. Step 3's not-checked trigger misses two digest states ...`, `#### F3. Section 8 lists a symlinked archive in one "not read" branch but not in the other two`, `#### F5. The new banner bolds the consequence; its sibling bolds the cause` (`docs/reviews/api-consistency-review-2026-10-01-digest-pass15.md:60,97,150`); the security report's finding 2 is `**Severity:** Informational`, "A symlinked archive is not listed in section 8 when questions.md is absent or questions.sh is missing" (`docs/reviews/security-review-2026-10-01-digest-pass15.md:52-54`). 23/23 ok (`fc16/bats.log`); shellcheck exit 0, empty output (`fc16/shellcheck.log`).

**Evidence:** `docs/reviews/api-consistency-review-2026-10-01-digest-pass15.md:60`, `docs/reviews/security-review-2026-10-01-digest-pass15.md:52-54`, `fc16/bats.log`, `fc16/shellcheck.log`

---

## Claim 18: Commit 5423a33: "dates could not make "each answer counts once" hold, because an undated answer took today's date every cycle. Now each keep-or-drop question names the brief's path, and the brief keeps an `Answered:` line with the IDs already applied; an answer applies only if its ID is not there. ... Steps 2 and 3 run only for briefs still open after step 1; "the cycle's step 1" disambiguates the archive note; the 14-day clock runs from the last `Kept:` date (none yet: the brief's date). Step 3 of the cycle keys on the single "watched questions were NOT checked" banner, whatever the cause. The brief format notes the `Kept:` and `Answered:` lines."

**Location:** commit 5423a33 (message body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers each sentence against the cb2e5f9→5423a33 diff and the pass-15 references "(fact-check 17, 18, 19b, 20, 22; security F1; api F1, F4)"; does not establish the filter breadth noted in Claims 7b and 11, which the message does not address.

The removed text read "An answer's date is the one written with it, else today." (cb2e5f9 `skills/dev-cycle/SKILL.md`, In-flight item 2), which is the stated cause. Each "now" sentence matches Claims 7a, 8, 10, 6 and 13. The references exist: pass-15 fact-check Claims 17, 18, 19b, 20, 22; security finding 1 (`docs/reviews/security-review-2026-10-01-digest-pass15.md:38`, Medium); api F1 and F4 (`docs/reviews/api-consistency-review-2026-10-01-digest-pass15.md:30,131`).

**Evidence:** `skills/dev-cycle/SKILL.md:156-158`, `skills/dev-cycle/SKILL.md:228-237`, `skills/dev-cycle/SKILL.md:251-252`, `docs/reviews/code-fact-check-report-digest-pass15.md:283-331`

---

## Claim 19: Commit 5423a33: "An old brief's answer never matches a new brief's path."

**Location:** commit 5423a33 (message body)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers distinct briefs (different date or slug); does not establish the same-date, same-slug case, which needs an item closed and re-briefed in one day (item 1 moves a dropped item to Ideas, not Now, so the same cycle cannot re-brief it).

Paths are `docs/working/handoffs/YYYY-MM-DD-<slug>.md` (`skills/dev-cycle/SKILL.md:249`), and matching is on the path (`:228-230`), so an earlier brief's question names a different path.

**Evidence:** `skills/dev-cycle/SKILL.md:226-230`, `skills/dev-cycle/SKILL.md:247-249`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 7b** (`skills/dev-cycle/SKILL.md:229-232`): **wording.** Step 2 searches for "questions naming this brief" and applies "each answered one", but defines effects only for keep and drop. Say "keep-or-drop questions naming this brief".
- **Claim 11** (`skills/dev-cycle/SKILL.md:235-236`): **behavioral, narrow.** "No question naming this brief is open" lets any unrelated open entry that cites the brief's path hold off the keep-or-drop ask indefinitely. Say "no keep-or-drop question naming this brief is open".

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass16.md` with the required first line, the header fields (including `**Replication:** k=1 (loop pass, decision 031)`), the seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary. On the round's aims: A holds in all 36 probed states. Section 3 is one ordered chain, every not-checked outcome prints the banner with its cause, the absent message matches step 0, a non-plain archive is always in section 8, and test 10's new case passes on 09f6fe7 and fails on f47de85. In B the ID-keyed rule makes "each answer counts once" and "an old brief's answer never applies" hold. Steps 2–3 are limited to open briefs, the clock has one origin, and step 3's banner reference matches every banner. Two "questions naming this brief" filters are broader than the keep-or-drop questions they mean: one is wording and one is a narrow behavioral issue. Not committed, per the brief.
