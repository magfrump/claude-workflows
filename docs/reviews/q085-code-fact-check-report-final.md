# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q085 (branch `review/q085`)
**Commit:** 6ac9dcd
**Replication:** k=1 (final confirming pass, decision 031)
**Scope:** full branch, `git diff main...HEAD` (merge base 6405e43), plus the commit messages from `git log main..HEAD`. The contents of `docs/reviews/q085-*` are review artifacts and are not fact-checked. The three `review/q085` override-log rows are checked as claims about the code.
**Checked:** 2026-09-28
**Total claims checked:** 21
**Summary:** 17 verified, 1 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`, 5 entries). None of the claims below match a logged pattern. No Incorrect verdict here is a fabrication, so the log is unchanged. This pass was also told to modify no other file.

**Execution provenance (shared by every `executed` claim).** All commands ran under `timeout 20`, and nothing was left running. The captured output is in `/home/node/.claude/jobs/9f431b13/tmp/q085-fc3/logs/`:
- `gate.sh`: the step 1a block extracted verbatim from `workflows/pr-prep.md:89-94` with awk, backslash continuations intact. `gate_body.sh` is the same block minus the `BASE=main` line, so `BASE` could be injected.
- `gate-matrix.txt` (2026-09-28T14:51:36-07:00; cwd `/workspace/.claude/wt-q085`, `skills/` and `scripts/`): BASE ∈ {main, empty, HEAD, bogusref, `-p`, `--all`, `main~0`}. Exit codes are recorded per row.
- `gate-edge.txt` (14:52:08-07:00, a scratch clone): BASE = an orphan commit (no merge base), and BASE = a commit one ahead of HEAD.
- `gate-stack.txt` (14:55:04-07:00, a scratch repo `main → lower(+10) → upper(+5, +50 under docs/)`): stacked BASE semantics, including after a `--no-ff` merge of `lower`.
- `numstat.txt`, `step0-and-b516.txt` (14:55:27-07:00): a hand cross-check of the count, and Step 0's total.
- Binary check (inline, same session): `git diff --numstat` on a committed binary file prints `-	-	bin.dat`.

Every row also carries a harmless `bash: warning: setlocale` line on stderr. It is an environment artifact and does not affect any result.

---

## Claim 1: "Every review unit has a hard size cap of ~400 changed code lines … checked before the review-fix loop starts" / "The cap applies to every unit, not only to enforcement files"

**Location:** `docs/decisions/log.md:85`; `workflows/pr-prep.md:97`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every unit prepared through `workflows/pr-prep.md` step 1a, and the claim that the cap is not limited to enforcement files. Does not establish that the cap reaches self-improvement-loop task branches: they never run step 1a and are gated by their own 500-line total, docs included (known since iteration 1).
**Legibility-target:** an agent or human running pr-prep. It is also the decision-log reader who asks "does this cover my unit?"

Step 1a states the cap without any enforcement-file condition: `The cap applies to every unit, not only to enforcement files (decision log 62, Q-085 [3]).` (`workflows/pr-prep.md:97`). The self-improvement loop keeps its own gate, `MAX_DIFF_LINES=500` (`scripts/self-improvement.sh:1180`), checked as `if [ "$TOTAL_CHANGED" -gt "$MAX_DIFF_LINES" ]` over `git diff --shortstat "main..$BRANCH"` (`scripts/self-improvement.sh:1202,1212`). Its implementation-agent prompt runs the review-fix loop but not pr-prep step 1a (paraphrased — no quote available because the claim is about absence: the prompt at `scripts/self-improvement.sh:1131-1148` lists verify, review-fix loop, retro and failure pattern, and has no size step). So an SI branch with 401–500 total lines reaches its loop without a split. This residue was noted in iteration 1 and is not new.

**Evidence:** `workflows/pr-prep.md:97`, `docs/decisions/log.md:85`, `scripts/self-improvement.sh:1180,1202-1219,1131-1148`, `guides/validation-gates.md:46-52`

---

## Claim 2: Row 62 mechanics: "Added and removed lines both count, against the unit's base (`main`, or the branch below it in a stack); the gate fires above 400. Over the cap the unit splits into stacked units … only the user can waive the cap, through an answered `Q-NNN` entry the waiver cites. In /away mode the agent splits without asking and records the split as an interim in `questions.md` and the commit body's `Notes:` line. Replaces step 1a's advisory size check ("If the PR exceeds ~500 lines changed, consider whether it can be split")."

**Location:** `docs/decisions/log.md:85`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against `workflows/pr-prep.md:89-104` and against `git show main:workflows/pr-prep.md:86`. Does not establish the gate's behavior on an empty or reversed BASE (Claims 13a, 13c), which row 62 does not describe.
**Legibility-target:** a future decision-log reader.

The quoted old text matches main verbatim: `If the PR exceeds ~500 lines changed, consider whether it can be split before doing any other prep work.` (`git show main:workflows/pr-prep.md`, line 86). The counting and base clauses match the command, `awk '{ n += $1 + $2 } …'` (`workflows/pr-prep.md:93`), and its comment, `for a stacked unit whose lower unit has not merged yet: that unit's branch` (`:89`). Execution confirms both: the stacked scratch repo gives 5 for `BASE=lower` and 15 for `BASE=main` (`gate-stack.txt`). The waiver and /away clauses restate `:97` and `:102` (Claims 17, 19).

**Evidence:** `docs/decisions/log.md:85`, `workflows/pr-prep.md:89-104`, `gate-stack.txt`

---

## Claim 3: Row 62 rationale: "over the proposal's ~600 and over an enforcement-files-only scope"; "Q-076 grew from +476 to ~+3,600 code lines under review"; "the early split trigger (row 61) reacts only after an iteration has run"; "`docs/` is left out so review artifacts and working notes don't count, while `skills/` and `workflows/` markdown … do"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each factual clause. Does not establish the reasoning ("closer to the usual human-review guidance"), which is design rationale and not checkable.
**Legibility-target:** a future decision-log reader.

- The proposal said `a unit over ~600 changed code lines (reviews excluded) must split` (`docs/working/proposal-2026-09-27-smaller-review-units.md:34`). Q-085's option [1] is `~600 code lines, enforcement files only` (`docs/working/questions.md`, Q-085 table).
- Q-085 says `Q-076 grew from +476 to +3,613 code lines under review`, so "~+3,600" is a fair rounding.
- The early split trigger begins `After triaging any iteration, count its Must Fix findings` (`workflows/review-fix-loop.md:50`).
- The docs exclusion was executed. The 50 lines added under `docs/` in the stacked scratch repo are not counted (`upper BASE=[lower]: 5`). On this branch the count of 36 comes only from `guides/`, `skills/` and `workflows/` files (`numstat.txt`: `16	5	workflows/pr-prep.md`, `6	5	skills/code-review/references/chat-synthesis.md`, and 1+1 for each of the two guides).

**Evidence:** `docs/decisions/log.md:85`, `docs/working/proposal-2026-09-27-smaller-review-units.md:34`, `docs/working/questions.md:191-205`, `workflows/review-fix-loop.md:50`, `numstat.txt`, `gate-stack.txt`

---

## Claim 4: Override row: "Log rows record the state when they were written; row 62 cites row 61, so the link runs forward from the answer." (about row 61 still saying A4 "awaits the user's number")

**Location:** `docs/reviews/override-log.md:128`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the factual premises: row 61 is unchanged and row 62 cites it. Does not establish whether leaving row 61 unannotated is the right call, which is a judgment.
**Legibility-target:** the next review run that reads the override log at Step 3.5.

Row 61 (`docs/decisions/log.md:84`) still ends `A4 (size budget) is not adopted; it awaits the user's number.`, and the branch diff does not touch it. Row 62 cites it twice: `the early split trigger (row 61)` and, in its last column, `log 59, 61` (`docs/decisions/log.md:85`).

**Evidence:** `docs/decisions/log.md:84-85`

---

## Claim 5: Override row: "No script, hook or test runs them [`docs/human-author/prompts.ts`, `docs/working/scratch/*.py`], and they are still reviewed"

**Location:** `docs/reviews/override-log.md:129`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers references from `scripts/`, `hooks/`, `test/` and the rest of the repo outside `docs/reviews/` and `archive/`. Does not establish that no human runs them by hand. It also does not cover the many `docs/reviews/execution-logs/*.sh|*.py` probe files, which the row does not name. They are review artifacts and are equally excluded from the count.
**Legibility-target:** the next review run, and a human deciding whether the `docs/` exclusion is safe.

Both files exist (`docs/human-author/prompts.ts`, `docs/working/scratch/health-check.py`). `rg -l "prompts\.ts|health-check\.py|docs/working/scratch"` over the repo, excluding `docs/reviews` and `archive`, returns only the two files themselves. `rg -n "human-author/" scripts hooks test` returns nothing (paraphrased — no quote available because the evidence is an empty grep). "Still reviewed" holds: code-review's default scope is `git diff main...HEAD` (`skills/code-review/SKILL.md:140`, "The default full-branch scope (`git diff main...HEAD`)"), and that scope includes `docs/`.

**Evidence:** `docs/human-author/prompts.ts`, `docs/working/scratch/health-check.py`, `skills/code-review/SKILL.md:140`

---

## Claim 6: Override row: commit b516af2 says "Deletions still count, as the user's rule says; raised as a question", "no Q-NNN was filed", and "the next commit's body states the correction"

**Location:** `docs/reviews/override-log.md:130`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote from b516af2, the absence of a filed Q-NNN, and the correction in 6ac9dcd. Does not establish "the deletion question goes to the user through the orchestrator's report", which is a future action outside the repo.
**Legibility-target:** the next review run.

b516af2's Notes contain `Deletions still count, as the user's rule says; raised as a question.` 6ac9dcd's body contains `Correction to b516af2's Notes: counting deletions toward the cap is my reading of "~400 code lines", not the user's stated rule; it is raised for the user's judgment, and no Q-NNN has been filed.` `grep -i deletion docs/working/questions.md` returns nothing (paraphrased — no quote available because the evidence is an empty grep). The user's recorded answer is only `Q-085: [3]` (`docs/human-author/answers-9-28-26.txt`, added in 6405e43), and option [3] says nothing about deletions.

**Evidence:** `git log -1 --format=%B b516af2`, `git log -1 --format=%B 6ac9dcd`, `docs/working/questions.md`, `docs/human-author/answers-9-28-26.txt`

---

## Claim 7: "~~A4's size budget: ~600 lines, enforcement files only?~~ Answered 2026-09-28 (Q-085 [3]): ~400 code lines, every unit (decision log 62, pr-prep step 1a)."

**Location:** `docs/working/proposal-2026-09-27-smaller-review-units.md:104`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the answer's date, option and content, and the two cross-references. Does not establish that the Q-085 entry itself was marked ANSWERED: it is still `**Status:** OPEN` in `docs/working/questions.md:192` on both this branch and main. The only record of the answer is `docs/human-author/answers-9-28-26.txt`.
**Legibility-target:** a reader of the proposal doc.

`Q-085: [3]` is in `docs/human-author/answers-9-28-26.txt` (commit 6405e43, dated 2026-09-28). Option [3] is `~400 code lines, every unit` (`docs/working/questions.md`, Q-085 table). Row 62 and step 1a exist as cited.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:104`, `docs/human-author/answers-9-28-26.txt`, `docs/working/questions.md:191-205`

---

## Claim 8: "Is the unit within pr-prep step 1a's size gate (≤ 400 changed code lines outside `docs/`), or split into stacked units, or waived by the user with the `Q-NNN` entry cited?"

**Location:** `guides/completion-signals.md:82`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 1a's number, boundary, count scope and three outcomes. Does not establish anything about this checklist's placement under "PR Description", which is a layout choice.
**Legibility-target:** an agent or human checking whether a phase is complete.

"≤ 400" matches `The gate fires above 400` (`workflows/pr-prep.md:97`). The three outcomes match the completion criterion `at most 400 … OR it was split into stacked units, OR the user waived the cap … with its Q-NNN entry` (`workflows/pr-prep.md:156`).

**Evidence:** `guides/completion-signals.md:82`, `workflows/pr-prep.md:97,156`

---

## Claim 9: "**Size gate** — unit ≤ 400 changed code lines outside `docs/` (count with pr-prep step 1a's command)? If not, split into stacked units before the review-fix loop. Only the user can waive the cap, through an answered `Q-NNN` entry; note the waiver in the PR description, citing that `Q-NNN`, and suggest a file review order"

**Location:** `guides/pr-prep-quick-ref.md:11`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 1a (number, count, timing, waiver owner and citation). Does not establish that the quick-ref carries step 1a's "quote the user's answer verbatim" requirement: it omits it, which is acceptable for a checklist that points at the command.
**Legibility-target:** an agent using the quick-ref instead of the full workflow.

Step 1a says `Before the review-fix loop starts` (`workflows/pr-prep.md:86`), `Only the user can waive it.` (`:97`), and `citing by ID the answered Q-NNN entry` (`:102`).

**Evidence:** `guides/pr-prep-quick-ref.md:11`, `workflows/pr-prep.md:86,97,102`

---

## Claim 10: "Inputs are … the unit's size as counted by `workflows/pr-prep.md` step 1a's command (changed lines outside `docs/`)."

**Location:** `skills/code-review/references/chat-synthesis.md:128`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the ladder's input line and rule 2 and step 1a (the iteration-2 Stale item A8 is resolved). Does not establish anything about the worked examples' "N-line diff" wording (`:173-178`), which still reads naturally under the new input.
**Legibility-target:** the code-review orchestrator deriving the next action.

Rule 2 uses the same count: `>400 changed lines outside docs/, counted with that step's command` (`:140-142`).

**Evidence:** `skills/code-review/references/chat-synthesis.md:128,140-144`

---

## Claim 11: "**split PR** — The unit is over the size gate in `workflows/pr-prep.md` step 1a (>400 changed lines outside `docs/`, counted with that step's command, so review artifacts don't count) AND ≥1 🔴 item exists (and rule 1 did not match)."

**Location:** `skills/code-review/references/chat-synthesis.md:140-144`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the boundary, the count and the "review artifacts don't count" clause. Does not establish how rule 2 should treat a user-waived unit: it is over 400, so any red still derives `split PR` despite the waiver. That interplay is a design gap, not a fact, and it was flagged in iteration 2.
**Legibility-target:** the code-review orchestrator.

Review artifacts are written under `docs/reviews/`, and step 1a's pathspec `':(top,exclude)docs/'` (`workflows/pr-prep.md:93`) excludes them. On this branch the 1,596 lines of `docs/reviews/q085-*` are left out of the count of 36 (`numstat.txt`, `gate-matrix.txt`). The `:176` example (`1 🔴 in security, 800-line diff → rule 2`) is still over the gate.

**Evidence:** `skills/code-review/references/chat-synthesis.md:140-144,176`, `workflows/pr-prep.md:93`, `numstat.txt`

---

## Claim 12: "# Show total lines changed, all files (step 1a's size gate runs its own count)"

**Location:** `workflows/pr-prep.md:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `git diff --stat main...HEAD | tail -1` prints. Does not establish anything about Step 0's other commands.
**Legibility-target:** an agent running Step 0.

Executed at 14:55:27-07:00 in `/workspace/.claude/wt-q085` with exit 0: ` 14 files changed, 1632 insertions(+), 13 deletions(-)`. That covers all files, docs included. Step 1a's own count is 36.

**Evidence:** `workflows/pr-prep.md:43-44`, `step0-and-b516.txt`

---

## Claim 13a: "An empty … BASE … must fail loudly, not print 0."

**Location:** `workflows/pr-prep.md:90` (also 6ac9dcd body: "refuses an empty, bad or HEAD base with an error")
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an empty or unset `BASE`. The part that does hold (it does not print 0) is in the Scope. This does not establish anything about bad or HEAD values (Claims 13b, 13c).
**Legibility-target:** an agent running the gate, especially on a stacked unit, where the harness does not keep shell variables between calls.

The command substitutes a default rather than failing:

```bash
# workflows/pr-prep.md:92
b=$(git rev-parse --verify --quiet --end-of-options "${BASE:-main}^{commit}") && [ "$b" != "$(git rev-parse HEAD)" ] \
```

(excerpt ends :92; the enclosing block continues to :94 — read)

`BASE=""` printed `36`, exit 0, and no error from the root, `skills/` and `scripts/` alike (`gate-matrix.txt`). This is the same count as `BASE=main`. So the "must fail loudly" mechanism is refuted: an empty BASE silently counts against `main`. The "not print 0" half holds. On a stacked unit whose `BASE` was lost, the gate counts the lower unit too: the stacked scratch repo gives `upper BASE=[]: 15` where `BASE=lower` gives 5 (`gate-stack.txt`). That errs toward a spurious split, not toward a silent pass. The code's behavior was the security reviewer's iteration-2 recommendation ("Use `"${BASE:-main}"` inline"); the comment and 6ac9dcd's summary line were not updated to match. 6ac9dcd's own Notes line (`with an empty BASE (31, defaults to main)`) contradicts its summary line. Precise wording: "An empty BASE counts against main; a BASE that is not a commit, or is HEAD, fails with an error."

**Evidence:** `workflows/pr-prep.md:89-94`, `gate-matrix.txt` (rows `BASE=[]`), `gate-stack.txt`, `git log -1 --format=%B 6ac9dcd`

---

## Claim 13b: "An … bad BASE (or BASE=HEAD) must fail loudly, not print 0." (a BASE that is not a commit, option-shaped, or HEAD)

**Location:** `workflows/pr-prep.md:90`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a nonexistent ref, option-shaped values (`-p`, `--all`) and `HEAD`, from three directories: each prints only the error and no count. Does not establish a non-zero exit status (every error row exits 0, because the final `echo … >&2` succeeds), so a script testing `$?` would pass. It does not establish anything about a BASE that is a descendant of HEAD or shares no history with it (Claim 13c), or git versions before `rev-parse --end-of-options` support (run here on git 2.39.5).
**Legibility-target:** an agent running the gate.

The failure branch is `|| echo "size gate: BASE '${BASE}' is not a commit other than HEAD; fix it and re-run" >&2` (`workflows/pr-prep.md:94`). Rows `bogusref`, `-p`, `--all` and `HEAD` each printed only that message, with `exit=0`, and no number (`gate-matrix.txt`). A count and the error never both appear. The `||` runs only when `rev-parse` or the `[ … ]` test fails, and then no pipeline has run. When the pipeline does run, its status is awk's, which is 0, so the `echo` is skipped.

**Evidence:** `workflows/pr-prep.md:92-94`, `gate-matrix.txt`

---

## Claim 13c: "An … bad BASE … must fail loudly, not print 0." (a BASE that is a descendant of HEAD, or has no merge base)

**Location:** `workflows/pr-prep.md:90`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two valid-commit BASE values that the guard lets through. The first is a reversed stack, where BASE is the upper branch while HEAD is the lower one. The second is an unrelated history. Does not establish how likely either is in practice: both need an agent error.
**Legibility-target:** an agent running the gate on stacked units.

The guard checks only that BASE is a commit other than HEAD (`workflows/pr-prep.md:92`), and the pipeline's status is awk's, whatever `git diff` did:

```bash
# workflows/pr-prep.md:93
  && git diff --numstat "$b"...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }' \
```

- **Reversed stack:** with `HEAD=lower` and `BASE=upper`, the output is `0`, exit 0, with no message (`gate-stack.txt`, `lower BASE=[upper]: 0`).
- **BASE one commit ahead of HEAD:** the output is `0`, exit 0, silently (`gate-edge.txt`).
- **Orphan BASE:** git prints `fatal: …...HEAD: no merge base`, and the gate still prints `0` with exit 0 (`gate-edge.txt`).

So a "bad" BASE of these shapes prints 0 and passes the gate, which is the fail-open the comment says cannot happen. A reader who takes the comment at its word would trust a 0 from a reversed stack.

**Evidence:** `workflows/pr-prep.md:92-94`, `gate-stack.txt`, `gate-edge.txt`

---

## Claim 14: "':(top)' anchors both pathspecs at the repository root, so the count is the same from any directory."

**Location:** `workflows/pr-prep.md:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working-tree root, `skills/` and `scripts/` for every BASE value tested. Does not establish anything about running from outside the repository, where git fails and the gate prints its error.
**Legibility-target:** an agent running the gate from a subdirectory.

`BASE=main` printed `36` from all three directories, and so did `main~0` and an empty BASE (`gate-matrix.txt`). The count matches a hand count of `git diff --numstat main...HEAD` minus `docs/` rows (`numstat.txt`, 36).

**Evidence:** `workflows/pr-prep.md:91-93`, `gate-matrix.txt`, `numstat.txt`

---

## Claim 15: "Added and removed lines both count; binary files count 0. The gate fires above 400: the "~" marks a round number, not a tolerance band."

**Location:** `workflows/pr-prep.md:97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk sum and the binary `-` fields. "Fires above 400" is a threshold the reader applies to the printed number; the command prints the count and does not compare it. Does not establish anything about renames without `-M` (counted as delete plus add), which the claim does not address.
**Legibility-target:** an agent reading the gate's output.

`awk '{ n += $1 + $2 } END { print n+0 }'` (`:93`) sums columns 1 (added) and 2 (removed). Git prints `-	-	bin.dat` for a binary file, and awk reads `-` as 0 in numeric context. `workflows/pr-prep.md` shows `16	5`, and its 21 lines both count toward the 36 (`numstat.txt`).

**Evidence:** `workflows/pr-prep.md:93,97`, `numstat.txt`, inline binary probe

---

## Claim 16: Stacked units: "for a stacked unit whose lower unit has not merged yet: that unit's branch" (`:89`); "each lower unit runs its own review-fix loop and merges once green, so the units above it review against a settled base" (`:97`); "(a stacked unit runs step 1a's count with `BASE` set to the branch below it)" (`:104`)

**Location:** `workflows/pr-prep.md:89,97,104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers counting before and after a `--no-ff` merge of the lower unit (the local-merge path). Does not establish anything about a squash-merged lower unit on the GitHub path, where `main...upper` would still include the lower commits until upper is rebased.
**Legibility-target:** an agent splitting a unit into a stack.

Scratch repo: `upper BASE=[lower]: 5` counts only the upper unit, and after `git merge --no-ff lower` into main, `upper-after-merge BASE=[main]: 5` (`gate-stack.txt`). Steps 1a and 1b agree on the lower branch as BASE.

**Evidence:** `workflows/pr-prep.md:89,97,104`, `gate-stack.txt`

---

## Claim 17: "In /away mode, split without asking and record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line, as the early split trigger does"

**Location:** `workflows/pr-prep.md:97`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the /away behavior and where the split is recorded. Does not establish /active behavior: the early split trigger says "propose the split and wait", and step 1a does not state an /active rule.
**Legibility-target:** an autonomous agent.

`In /away mode and autonomous loops, split without asking. Record the split as an interim in docs/working/questions.md and in the commit body's Notes: line.` (`workflows/review-fix-loop.md:52`). The anchor `#early-split-trigger-after-any-iteration` resolves to the heading `### Early split trigger (after any iteration)` (`:48`).

**Evidence:** `workflows/pr-prep.md:97`, `workflows/review-fix-loop.md:48-52`

---

## Claim 18: "citing by ID the answered `Q-NNN` entry where the user granted it (in `docs/working/questions.md`, or `questions-archive.md` once archived)"

**Location:** `workflows/pr-prep.md:102`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where `scripts/questions.sh archive` moves ANSWERED entries and whether the ID survives the move. Does not establish that the user actually marks a waiver entry ANSWERED: Q-085 itself is still OPEN in `questions.md` (Claim 7).
**Legibility-target:** an agent recording a waiver, and a reviewer checking it.

`ARCHIVE="${QUESTIONS_ARCHIVE:-$PROJECT_ROOT/docs/working/questions-archive.md}"` (`scripts/questions.sh:86`). `cmd_archive` skips non-answered entries (`[[ "$status" == "ANSWERED" ]] || continue`, `:379`) and copies the entry to the archive whole (`replace_with "$ARCHIVE" archive_with_entry "$id"`, `:386`), so the `Q-NNN` heading keeps its ID. The bare `questions-archive.md` omits the `docs/working/` prefix, but the parenthesis reads as the sibling of `docs/working/questions.md`.

**Evidence:** `workflows/pr-prep.md:102`, `scripts/questions.sh:86,374-394`

---

## Claim 19: "The unit is at most 400 changed code lines (outside `docs/`, counted with step 1a's command against its base), OR it was split into stacked units, OR the user waived the cap and the PR description records the waiver with its `Q-NNN` entry and an expanded "Reviewer's path — start here" section"

**Location:** `workflows/pr-prep.md:156`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 1a's prose. Does not establish that the criterion repeats the prose's "user's answer quoted verbatim" requirement: it does not, which is a looser restatement, not a contradiction.
**Legibility-target:** an agent closing step 1.

It matches `:97` ("fires above 400", split into stacked units, only the user waives) and `:102` (the waiver cites `Q-NNN`, and the reviewer's path is expanded for an oversized PR).

**Evidence:** `workflows/pr-prep.md:97,102,156`

---

## Claim 20: Other repo statements of a PR or unit size rule (outside `docs/`)

**Location:** `skills/code-review/SKILL.md:35,144,153`; `guides/skill-trigger-guide.md:93`; `guides/validation-gates.md:48,274`; `workflows/pr-prep.md:142`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether these thresholds contradict step 1a. None states a unit split rule for pr-prep units. Does not establish that they still serve their purpose under the cap: the ~1000-line review-pass triage and the >500-line tech-debt trigger can now fire only on a waived or docs-heavy unit. The search was one regex sweep (`rg` over `[0-9]{3,4}[- ](changed )?(code )?lines|split (the |this )?pr|lines changed|pr size|diff size`) plus a reading of each hit, so a rule phrased differently could be missed. That is why Confidence is Medium.
**Legibility-target:** a maintainer checking for leftover size rules.

- `Diffs exceeding roughly 1000 lines … split the review into multiple passes` (`skills/code-review/SKILL.md:144`) splits review passes, not units.
- `tech-debt-triage.md — triggered on large diffs (>10 files or >500 lines)` (`:35`, repeated at `guides/skill-trigger-guide.md:93`) is a critic-selection trigger.
- `LOC_TOTAL … -gt 500` (`workflows/pr-prep.md:142`) is the pre-mortem fallback's risk trigger.
- `Total lines changed … does not exceed 500` (`guides/validation-gates.md:48`) and `under 500 lines changed` (`:274`) belong to the SI loop (Claim 1 residue).

No other hit states a split rule.

**Evidence:** listed locations; `rg` sweep in this session

---

## Claim 21: Commit 6ac9dcd summary: "The size gate runs as one command that resolves BASE with rev-parse --verify --end-of-options and refuses an empty, bad or HEAD base with an error, instead of printing 0 and passing."

**Location:** commit `6ac9dcd` (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit summary against the code at 6ac9dcd. The "empty" and "bad" clauses are verdicted in Claims 13a and 13c. This entry records only that the commit text repeats the comment's error. Does not establish anything about the Notes' figure "31", which was correct for the committed HEAD at the time: the count at b516af2 is 31 (`step0-and-b516.txt`), and at 6ac9dcd it is 36.
**Legibility-target:** a reader of `git log`.

The rev-parse mechanism, the one-command shape and the HEAD refusal are accurate (Claims 13b, 14). "Refuses an empty … base" is the Claim 13a error. The commit's own Notes contradict it: `with an empty BASE (31, defaults to main)`. This is new; it is not among the logged 49a3dbb/b516af2 inaccuracies. The part-verdict is Mostly accurate because the refuted atom is already carried as Incorrect by Claim 13a; fixing the comment resolves both. Rewriting the message needs a history rewrite, like the logged b516af2 row.

**Evidence:** `git log -1 --format=%B 6ac9dcd`, `gate-matrix.txt`, `step0-and-b516.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 13a** (`workflows/pr-prep.md:90`): an empty `BASE` does not fail loudly. `${BASE:-main}` silently counts against main, which over-counts a stacked unit (15 vs 5). Reword to "An empty BASE counts against main; a BASE that is not a commit, or is HEAD, fails with an error."
- **Claim 13c** (`workflows/pr-prep.md:90`, `:92-93`): a BASE that is a descendant of HEAD (a reversed stack) prints `0` silently. One with no merge base prints `0` after git's `fatal`. Either narrow the comment or guard these cases, for example by requiring `git merge-base --is-ancestor "$b" HEAD`.

### Stale
- (none)

### Mostly Accurate
- **Claim 21** (commit 6ac9dcd): the summary says an empty base is refused with an error, and the commit's own Notes say it defaults to main. No action beyond fixing the comment (13a) and, if desired, an override-log row like b516af2's.

### Unverifiable
- (none)

Informational residues, already known and not new: the SI loop keeps a 500-total cap outside step 1a (Claim 1). Rule 2 still derives `split PR` for a user-waived unit that has a red (Claim 11). Every gate error path exits 0 (Claim 13b). Q-085 is still OPEN in `questions.md` although the answer is recorded in `docs/human-author/answers-9-28-26.txt` (Claim 7).

---

## Goal-Alignment Note

- **Answered:** A full-branch k=1 fact-check of `main...6ac9dcd` covering all 7 brief items. Item 1: the gate was executed verbatim from the root, `skills/` and `scripts/`, with BASE = main, empty, HEAD, a bogus ref, `-p`, `--all` and `main~0`, plus descendant, orphan and stacked cases in scratch repos. The chain never prints both a count and the error. It prints 0 for a descendant or unrelated BASE (13c), and an empty BASE defaults to main instead of failing (13a). Item 2: Claims 15-16. Item 3: Claims 2-3 and 7-12, 19. Item 4: Claim 18. Item 5: Claim 17. Item 6: Claim 20. Item 7: Claims 4-6. Two new Incorrect verdicts (13a, 13c), both in the one gate comment at `workflows/pr-prep.md:90`, plus a matching new commit-message inaccuracy in 6ac9dcd (Claim 21).
- **Out of scope:** The contents of `docs/reviews/q085-*` (except the override-log rows). Whether deletions *should* count, and how rule 2 should treat a waived unit, are design questions, not facts. I did not check git versions older than 2.39.5 for `rev-parse --end-of-options`.
- **Escalate:** Whether Claims 13a/13c are worth a fourth fix commit, or should be tiered as comment-wording ambers with an override row, is the orchestrator's triage call. The code behavior of 13a errs safe (over-count). 13c is a silent fail-open, but only on an agent's reversed-stack mistake. Separately, Q-085 is still OPEN in `docs/working/questions.md`, so the "answered Q-NNN" convention this branch introduces is not yet followed for Q-085 itself.
