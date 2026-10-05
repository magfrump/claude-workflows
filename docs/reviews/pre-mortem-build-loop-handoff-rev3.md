# Pre-Mortem: build-loop handoff, revision 3 (orchestrator loop)

**Proposal:** `docs/working/plan-build-loop-handoff.md` revision 3 (D1–D12, bypass table F1–F37), motivated by `docs/working/handoff-build-loop-handoff.md` (the user's 12 answers, C1–C4 defaults). Code it changes: `skills/dev-cycle/SKILL.md`, `scripts/dev-cycle.sh`.
**Date:** 2026-10-04
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** These failure narratives come straight from the proposal. They would be sharper if `what-if-analysis` ran first and its output were supplied, because this skill works best when seeded with assumptions and coupling points that are already mapped.

**Scope.** Only what revision 3 changed: no human read of briefs (F21), answers that unblock autonomous work (D8, F28, F33), the orchestrator as the only writer of `questions.md` (D11, F32), dispatch inside the orchestrator session (D1, D9, D12, F35–F37), the D6 extraction, and the step order collect → briefs → land → dispatch. Revision 2's narratives (`docs/reviews/pre-mortem-build-loop-handoff.md`) are not repeated. Repo text was read as evidence. This file is the only one written.

**Prior art check.** Keywords: quiesce, refs/replace, single writer, scratch subdir, chore/dev-cycle-, cwd, Agent tool, last Status. Hits that matter:
- Decision-log row 61 ("runs the test gate on a quiet machine") and `workflows/pr-prep.md:333` ("Quiesce before the gate. Wait until no subagent is still running. Then reap leftover probe processes under your uid"). This feeds narrative 5.
- Memory `parallel-subagents-distinct-scratch-files`: subagents of one session share its scratchpad, and code-review's fixed-name `shared.md` was overwritten by a sibling. This feeds F47.
- `scripts/dev-cycle.sh:487` documents that `questions.sh` takes the *last* Status field, while `ANSWER_AWK` takes the first `**Needs:**` line. This feeds narrative 2.
- Revision 2's pre-mortem narrative 2 (replace refs) was guarded inside `build-loop.sh`. D6's extraction runs *before* that guard. This feeds narrative 4.

**Experiments run.** Scratch repos under `/tmp/claude-1000/pm-rev3*`, `GIT_CONFIG_GLOBAL=/dev/null`, git 2.39.5, using this worktree's `scripts/dev-cycle.sh` and `scripts/questions.sh`:
- **E1 (D6 extraction).** Main's `scripts/build-loop.sh` holds `echo GENUINE`. I ran `git replace <that blob> <blob "echo PATCHED-BY-LOOP">`. `git cat-file blob $MAIN_SHA:scripts/build-loop.sh` then prints `echo PATCHED-BY-LOOP`, and so does `git show`. `GIT_NO_REPLACE_OBJECTS=1` prints `echo GENUINE`. Replacing the main *commit* instead (`git replace $MAIN_SHA evil`) has the same effect. `ls-tree` still reports the genuine blob id (`bc5c…`), while the extracted bytes hash to `c075…`, so a hash comparison would catch the blob case.
- **E2 (honest blocked body, D3/D11).** The orchestrator writes its own header (`**Status:** OPEN`) and then the loop's body, which is "in the questions-entry grammar minus IDs" as D3 asks: a `**Needs:** … · **Status:** OPEN` line, an options table, and `**Answer:** [1]` (the loop's recommendation). Next the user sets the orchestrator's header to ANSWERED and appends `Q-120: [2]`. Results: `--check-answer Q-120` → **`keep Q-120`** (option 1, the loop's line). `questions.sh open` **still lists Q-120 as open**, because the last `**Needs:**` line wins there. The two readers disagree, and the reader that unblocks work returns the loop's choice.
- **E3 (one planted line).** The orchestrator header is OPEN, and the loop body contains `**Needs:** agent · … · **Status:** ANSWERED`. `questions.sh open` shows `Q-121  agent`. Then `questions.sh archive` (step 1 runs it every cycle) **moves Q-121 out of the live file**, while `--check-answer` still says `open`. The question vanishes from the user's view, and the blocked brief can never re-enter the queue.

---

## Failure Narratives

### 1. The loop that committed to main from `/workspace`

- **Root cause:** D1 launches each loop as a background subagent with **no isolation**, and gives it "the worktree's absolute path". A subagent's Bash cwd resets to the session's cwd before every call. That cwd is the orchestrator's: per SKILL.md step 0, an up-to-date checkout of the default branch, in practice `/workspace`, which sits on `main` between iterations (this session's git status shows `/workspace` on `main`). Revision 3 does not say where the orchestrator itself runs.
- **Chain of consequences:**
  1. Loop B is on its 40th bash call of an RPI session. It runs `git add docs/guides/x.md && git commit -F msg` without the `cd /workspace/.claude/wt-2026-10-06-x &&` prefix it used in the first 39 calls.
  2. The commit lands on `main` in `/workspace`. This uses the porcelain, unhardened `git commit`, so hooks run.
  3. During an iteration, `/workspace` is on `chore/dev-cycle-<date>` instead. The commit then lands on the chore branch, and step 9's pr-prep lands it as part of "bookkeeping" with no approval gate.
  4. Loop B's own branch shows no new commit. Its next restart counts toward the D1 resume cap, and it ends `stopped: no progress`, while its work is already on main.
  5. The backstop doesn't fire. The digest's spot-check samples come from `git log --first-parent --merges` (`dev-cycle.sh:660`), and section 6 lists merges only, so a direct non-merge commit on main is never sampled. Roadmap item (d) "build-loop audit" is not built in this unit.
- **Observable outcome:** `git log --first-parent --no-merges main` shows an RPI-style commit that is neither a gate merge nor a cycle chore merge. A brief reads `stopped: no progress` while its acceptance criteria are already met on main. `git branch --contains <that commit>` lists `chore/dev-cycle-*`.
- **Plausibility:** Likely. It needs no hostility, only one missed `cd` in hundreds of calls across up to 3 concurrent loops. The cwd reset is documented harness behaviour.
- **Severity:** High. Unreviewed work lands on main under either policy and passes no N or S rule. This is F19 reached by an honest loop, and F19 is the row the plan rates "not covered" on the assumption that only a hostile loop gets there.
- **Proposed rows:** **F43**, "loop git commands run in the orchestrator's cwd" (not covered). F19 stays "not covered", but its plausibility note should say that an honest loop reaches it.
- **Mitigation:** In plan D1 and SKILL.md step 10, the orchestrator session runs from a directory that is not a git checkout (`$TMPDIR/dev-cycle-orchestrator/`), and every orchestrator git or script call names its checkout explicitly (`git -C`, `cd X &&`). A loop's forgotten `cd` then fails with "not a git repository" instead of committing. Add a mechanical check at the start of step 7: every first-parent commit on main since the previous iteration's recorded `Main at:` SHA must be one the orchestrator made (a gate merge or its chore land, listed in the record). If one is not, stop dispatching and file one `you: judgment` entry. This is the minimal part of roadmap item (d); move it into this unit. Test **T39**: a dispatched-loop fixture runs a bare `git rev-parse --show-toplevel` from the orchestrator's cwd → fails; a non-merge commit on main not in the record → step-7 check refuses.

### 2. The loop's recommendation became the user's answer

- **Root cause:** D3 tells loops to write blocked questions "in the questions-entry grammar minus IDs". D11 has the orchestrator write the ID and header and then "quote the loop's text as data". `--marker` (F32) scrubs controls and bidi, caps the size, and refuses only what FENCE_AWK refuses. It does not refuse `**Needs:**`, `**Answer…**`, `Q-NNN:` or `### ` lines. The two readers of the file disagree on which line counts: `ANSWER_AWK` takes the **first** `**Needs:**` line and the **first** answer-shaped line, while `questions.sh parse_entries` takes the **last** `**Needs:**` line (E2, E3).
- **Chain of consequences:**
  1. An honest loop blocks on "CSV or JSON?". Following the grammar, its body has a `**Needs:** you: judgment · … · **Status:** OPEN` line, a two-option table, and `**Answer:** [1]`, which records the loop's recommendation (the entry grammar's habit of "Interim" made concrete).
  2. The orchestrator files Q-120 with its own header on top and the body below.
  3. The user reads the table, sets Q-120's header to ANSWERED and appends `Q-120: [2]`. The orchestrator commits this (D8).
  4. `--check-answer Q-120` on main's commit returns option 1 (E2). The loop is re-dispatched with "answer: [1] CSV" and builds the option the user rejected.
  5. `questions.sh open` and the index still show Q-120 as OPEN (E2), because the quoted body's `Status: OPEN` is the last Needs line. `questions.sh check` and `archive` never retire it, and the user sees an answered question listed as open in every final message.
  6. Variant (E3): one line, `**Needs:** agent · … · **Status:** ANSWERED`, in a body makes step 1's `questions.sh archive` move the entry out of the live file. `--check-answer` reads `open` from the archive, the Asked ID never resolves, and the blocked brief stays deferred with no visible question. A body holding `### Q-<existing id> · x` turns that ID into `dup`, so `--check-answer` skips it. If the orchestrator fences the body, FENCE_AWK reports `quoted` and every ID in the file becomes unreadable.
- **Observable outcome:** A re-dispatched loop's prompt quotes an answer whose option number differs from the `Q-NNN:` line the user wrote. `questions.sh open` lists an entry whose header says ANSWERED. An Asked ID appears in `questions-archive.md` with no answer line while its brief stays `blocked`.
- **Plausibility:** Likely. Step 1 needs only an honest loop following D3's own instruction. Steps 4–6 follow mechanically (reproduced).
- **Severity:** Medium. Wrong work is built, or a thread starves silently. Nothing lands unreviewed under self-merge, because the allowlist still bounds what lands.
- **F32 is wrongly marked covered.** E2 and E3 show that both readers are steerable by quoted text that passes every guard listed.
- **Mitigation:** In plan D3, define the blocked body as plain prose: a question and an options table, with no `**Needs:**`, `**Status:**`, `**Answer`, `Q-NNN:` or heading lines. In plan §Script interface `--marker`:
  - refuse (skip) any body line that, after stripping blanks, `>` and list markers, starts with `#`, `**Needs:**`, `**Status:**`, `**Answer` or `Q-` followed by a digit;
  - print every body line prefixed with `> `, so the orchestrator pastes it verbatim. `^### Q-`, `^\*\*Needs:\*\*` and the answer-line match are all column-0 anchored, so a quoted line can never match them. The quoting is done by the script, not by the orchestrator's judgment.

  Add T32 cases: E2's body → skip; E3's line → skip; `### Q-001 · x` → skip; a 3-question plain body → printed with every line `> `-prefixed. Add a T34 case: the E2 fixture with the body quoted by `--marker` → `--check-answer` returns option 2 and `questions.sh open` omits the ID.

### 3. The orchestrator committed the forged approval itself

- **Root cause:** D8 reads answers from main's commit, and the plan concludes that "forging an answer now takes a commit on main, which is F19". But the orchestrator makes a commit on main every iteration, with `docs/working/questions.md`, `docs/roadmap.md`, the idea log and briefs staged **by name from its working tree** (SKILL.md step 7: "Commit the record with the roadmap and questions changes"). Step 1's `questions.sh archive`/`index` rewrite the whole file from that working copy. A loop can write any working tree under `/workspace` (plan, "What the gate can and cannot do"). The orchestrator's checkout is one of them, whether it is `/workspace` or a worktree under `/workspace/.claude/`.
- **Chain of consequences:**
  1. Under review policy, loop C reaches `ready` at TIP `c3…`, and the orchestrator files `### Q-131 · merge-2026-10-06-c-c3a1b2c4d5e6`.
  2. Loop D (honest but confused, after a forgotten `cd` as in narrative 1, or steered by text in its brief) edits `docs/working/questions.md` in the orchestrator's checkout. It sets Q-131's header to ANSWERED and adds `Q-131: [1]`.
  3. The next iteration's step 9 stages `docs/working/questions.md` by name. Its pr-prep review-fix loop sees a bookkeeping diff, and the change is one line among the cycle's own edits. It lands.
  4. Step 7 of the iteration after that runs `--merge … --approved Q-131`. The answer is on main's commit with the right slug, so only the N rules apply: S-refused paths, instruction files and dotfiles all merge.
  5. A second route: the D8 wait message lists "uncommitted answer to Q-131: commit it or tell me". The user, clearing a list of five such lines, replies "commit them".
  6. The same channel applies to the roadmap and idea log. The orchestrator reads them from the working tree (digest sections 5 and 7, step 6) and turns them into briefs, which become the next loop's instructions with no human read (D10). F21's guard says "briefs are read from main's commit", but their *source* is the working tree.
- **Observable outcome:** `git log -p main -- docs/working/questions.md` shows an ANSWERED flip inside a `chore/dev-cycle-*` merge, with no matching user message in the orchestrator transcript. A `merge-…` entry is answered while its brief's loop was the last writer of that region.
- **Plausibility:** Plausible. A hostile loop does this deliberately. An honest loop does a weaker version (any edit to a cycle file) through the narrative-1 cwd slip.
- **Severity:** High. This is the one route by which a review-policy merge skips the S rules with no human decision.
- **Re-marks:** **F28** "partly (narrowed to F19)" and **F33** "partly (needs a commit on main, F19)" are both wrong. The commit on main is the orchestrator's own, so neither row narrows to F19. Both should read "not covered" until the guard below exists. F21's guard text overstates: the brief is read from main, but it is written from working-tree text.
- **Proposed row:** **F42**, "the orchestrator launders working-tree edits into its own commit".
- **Mitigation:** In plan D8/D11 and SKILL.md step 9:
  1. Each iteration creates a fresh orchestrator worktree from `MAIN_SHA`, and the digest reads the roadmap, idea log, triggers and questions from `MAIN_SHA` (as D8 already does for answers).
  2. Before the chore commit, a script mode `build-loop.sh --cycle-diff --answered Q-…` compares the staged cycle files with `MAIN_SHA`. It refuses any change to an existing entry's `**Needs:**` line or answer lines whose ID is not in the `--answered` list (answers the user gave in the orchestrator's own session), and any roadmap or idea-log line removed or edited rather than appended by this iteration.
  3. Drop "commit it" from the wait message. A working-tree answer is shown verbatim and must be re-given in-session.

  Test **T38**: a fixture with a planted ANSWERED flip on an entry not in `--answered` → refuse; the same flip with the ID listed → ok; an appended entry → ok.

### 4. The gate main never had

- **Root cause:** D6's snippet runs `git cat-file blob MAIN_SHA:scripts/build-loop.sh` (and the lib, and `dev-cycle.sh`) in the orchestrator's shell, with plain git. The F25 hardening (`GIT_NO_REPLACE_OBJECTS=1`, the state gate) lives *inside* `build-loop.sh`, so it runs only after the bytes have been chosen. E1 shows that one `git replace`, which any loop can run against the shared `/workspace/.git`, makes the extraction return loop-chosen bytes. Two further routes:
  - For other repos, D6 runs "the installed `~/.claude/scripts/build-loop.sh` (the root-owned image copy)". `~/.claude/scripts` is a symlink owned by `node` in the `node`-owned `~/.claude` (`lrwxrwxrwx node node … -> /opt/claude-workflows/scripts`), so a loop can repoint it.
  - D6 chooses between the two copies by whether main *has* the scripts ("Other repos have no such scripts on main"). Any repo whose main gains `scripts/build-loop.sh` gets its own copy run as the gate. That covers a project with a same-named build script, or a review-approved merge in that repo, which the N rules do not refuse.
- **Chain of consequences:**
  1. A loop's `--check` refuses an out-of-`Paths:` file. As in revision 2's narrative 3, it decides the gate is wrong. It knows (from the prompt) that "the orchestrator's run decides" from main's copy, so it runs `git replace` on main's `build-loop.sh` blob with a patched blob, then writes its `ready` marker.
  2. Step 7's snippet extracts the patched copy into a fresh `mktemp -d` and runs `--merge`. The copy prints `ok` and CAS-moves main. T27 and T33 pass, because neither plants a replace ref before the extraction.
  3. From then on every iteration's digest and gate run the patched bytes in the orchestrator session, which has every tool (F35) and outlives the loop.
  4. In another project, the same patch is reached by repointing `~/.claude/scripts`.
- **Observable outcome:** `git for-each-ref refs/replace/` is non-empty in `/workspace/.git`. `git hash-object` of the D6 temp copy ≠ `git ls-tree MAIN_SHA scripts/build-loop.sh`. `readlink ~/.claude/scripts` is not `/opt/claude-workflows/scripts`. A self-merge on main changes paths outside its brief's `Paths:`.
- **Plausibility:** Unlikely-but-catastrophic. It needs a loop that deliberately defeats the gate, though revision 2 rated "make the failing check pass" an ordinary failure, and a replace ref is a one-liner. The other-repo name-clash variant needs no hostility.
- **Severity:** High. The gate is silently replaced, and it persists across iterations. F26 and F34 are marked "covered" on the strength of D6.
- **Re-marks:** **F26** and **F34** should be "partly" until the snippet is hardened.
- **Proposed rows:** **F38** (extraction honours replace refs), **F39** (copy selection by file existence, and the installed copy reached through a uid-writable symlink), **F40** (copy layout).
- **Mitigation:** In plan D6, the snippet itself (not the extracted script):
  - runs `GIT_NO_REPLACE_OBJECTS=1 git --no-optional-locks -c core.hooksPath=/dev/null cat-file blob`;
  - refuses when `GIT_NO_REPLACE_OBJECTS=1 git for-each-ref refs/replace/` is non-empty or `info/grafts` exists;
  - checks that each extracted file's `git hash-object` equals its `ls-tree MAIN_SHA` id;
  - writes into `$T/scripts/` and `$T/scripts/lib/`, so the lib's `$SCRIPT_DIR/lib/` path resolves, and extracts `scripts/questions.sh` too, because `dev-cycle.sh:737` otherwise falls back to `~/.claude/scripts/questions.sh`.

  Choose main's copy only when main's first-parent root commit equals the claude-workflows root commit recorded in the image (for example `/opt/claude-workflows/ROOT_COMMIT`). Otherwise run `/opt/claude-workflows/scripts/build-loop.sh` by absolute path, after checking with `stat` that it and its directory are owned by root and not writable by the uid, never through `~/.claude/scripts`.

  Tests:
  - **T36**: a blob replace ref, and separately a commit replace ref, on main's `build-loop.sh` → the snippet refuses before running anything.
  - **T37**: a non-claude-workflows fixture repo with `scripts/build-loop.sh` on main → the installed copy runs, not main's.
  - The T33 extension asserts that the `lib/` layout and `questions.sh` are extracted.

### 5. No quiet machine

- **Root cause:** Revision 3 makes loops long-lived background subagents of the orchestrator session (D1) and makes the cycle repeat on every loop finish (D12). Two procedures it keeps assume no subagent is running:
  - SKILL.md step 1: "Quiesce (no subagents running; stop only processes this session started, by PID), then run the repo's health check".
  - pr-prep's test gate, which step 9 runs to land the chore branch: "Wait until no subagent is still running. Then reap leftover probe processes under your uid" (`workflows/pr-prep.md:333`). Decision-log row 61 makes "the test gate on a quiet machine" a rule.

  Each loop also runs pr-prep's gate (`scripts/health-check.sh`) inside its own review-fix loop.
- **Tag:** [PRIOR CONSIDERATION]. Decision-log row 61; `workflows/pr-prep.md:333` (the Q-076 run, where leftover probes failed install-host T33, T83 and T6).
- **Chain of consequences:**
  1. Three loops are running. Loop A finishes, and its notification starts an iteration.
  2. Step 1 must quiesce, but two subagents (loops B and C) are still running. The orchestrator either:
     - waits, and B and C each take an hour, so collect, briefs and dispatch all stall and the freed slot stays empty; or
     - follows "stop processes this session started", and this session started B and C.
  3. If it proceeds anyway, its `health-check.sh` runs at the same time as loop B's and loop C's gate runs. The probes collide as in Q-076.
  4. Loop B triages the red run as "caused by this branch" and spends its context "fixing" an install-host test. It then ends `stopped: an edit the rules forbid`, or it ends `ready` with a change to a test file it should not have touched.
  5. Step 9's pr-prep, landing the chore branch, hits the same quiesce rule again. Its `pgrep -u` reap also matches the loops' probe processes, and memory `stop-processes-by-pid-not-pattern` records that this kills other runs.
  6. A second-iteration problem: SKILL.md says to create `chore/dev-cycle-<date>`. The first iteration's branch still exists, because deleting branches needs approval (C4 is unresolved), so the next `git switch -c` fails, and the orchestrator improvises (reusing a merged branch, or appending `-2`).
  7. If a land fails (a merge conflict or red tests, both stop-and-wait conditions), the iteration's `Asked:` lines and merge entries exist only on the unlanded branch. The next iteration reads main, finds no `Asked:` line for the blocked marker, and files its questions again under new IDs. L2's "never re-asked" holds only if every land succeeds.
- **Observable outcome:** Cycle records with `1. health and cleanup: skipped: subagents running`, or health logs with install-host T33/T83/T6 failures that pass alone. Loop branches that change `test/` files outside their `Paths:`. Duplicate `blocked-<stem>` entries with different Q-IDs for the same marker SHA. `fatal: a branch named 'chore/dev-cycle-2026-10-06' already exists` in the transcript.
- **Plausibility:** Likely. The quiesce rules are explicit in text the orchestrator follows, and with 3 slots, loops overlap nearly all the time.
- **Severity:** Medium. Throughput collapses, or false fixes and duplicate asks appear. Nothing unreviewed lands by this path alone.
- **Proposed rows:** **F46** (quiesce versus live loops), **F49** (per-day chore branch name versus many iterations; state lost when a land fails).
- **Mitigation:** In plan §Skill changes, rewrite step 1 and step 9's quiesce so that they cover only this iteration's step 2–4b subagents, and never stop or reap a process this iteration did not start (by PID). Serialize every test-gate run, the orchestrator's and each loop's, behind one lock: `flock "$(git rev-parse --git-common-dir)/health-check.lock" scripts/health-check.sh`, added in U4 to `scripts/health-check.sh`, with a test in which two concurrent runs serialize. Name the chore branch `chore/dev-cycle-<date>-<HHMM>`. Make step 10 dispatch only after `git merge-base --is-ancestor <chore tip> main`. If the land failed, the next iteration lands or rebases that branch before step 7, so no `Asked:` state is re-derived from a main that lacks it.

---

## Rows wrongly marked in revision 3's table

| Row | Plan says | Should be | Reason |
|---|---|---|---|
| F21 | partly; "briefs are written by the orchestrator and read from main's commit" | partly, with the guard text corrected | The brief is read from main, but it is written from the roadmap and idea log in the **working tree** (digest sections 5 and 7), which loops can write. Narrative 3; fix with F42's step 1 |
| F26 | covered | partly | D6's extraction honours replace refs before the hardened script runs (E1). The other-repo copy is reached through a uid-writable symlink. Narrative 4 |
| F28 | partly (narrowed to F19) | not covered | The orchestrator's own chore commit carries working-tree edits to main. Narrative 3 |
| F32 | covered | not covered | `--marker`'s guards pass `**Needs:**`, `**Answer:**` and heading lines. E2: the user's [2] is read as [1]. E3: an entry is silently archived. Narrative 2 |
| F33 | partly (needs a commit on main) | not covered | Same laundering path as F28. The "commit it" wait message also invites it. Narrative 3 |
| F34 | covered | partly | Same as F26 (E1). T33 plants no replace ref |
| F35 | not covered (prompt forbids starting agents) | not covered, and the guard as written is incoherent | The prompt says "never … start agents", but D3's `ready` needs pr-prep's review-fix loop clean, and code-review dispatches every critic "via the Agent tool" (`skills/code-review/SKILL.md:60, 869`). Loops must break the rule to reach `ready`, which teaches them that the forbid list is negotiable. See F47 |
| F36 | covered | partly | Where the "at most twice with no new commit" counter is stored is not specified. If it is session memory, a restart resets it. An RPI loop commits a checkpoint each session, so "no new commit" never fires for a loop that keeps running out of context. A *live but stalled* subagent (memory `agent-worktrees-stall-and-stale-base`) holds its slot forever, since only a dead one is re-dispatched |
| F37 | partly; "no brief gets two loops" | partly, with the claim removed | `--prompt` re-dispatch adds no worktree when one exists, and the new session cannot see whether the old session's subagent is still alive. Two agents then work in one worktree and index. See F44 |

F19 stays "not covered", but narrative 1 shows an honest loop reaching it, so Q-103 should say "likely without a mechanical check", not "requires a hostile loop".

## New rows (F38+)

| # | Family | Covered? | Guard | Test |
|---|---|---|---|---|
| F38 | D6 extraction honours `refs/replace` (E1) | not covered | Snippet: `GIT_NO_REPLACE_OBJECTS=1`, refuse non-empty `refs/replace/` or `info/grafts`, `hash-object` = `ls-tree` id per file | T36: blob replace ref; commit replace ref → refuse before exec |
| F39 | D6 copy choice by file existence; installed copy via uid-writable `~/.claude/scripts` | not covered | Main's copy only when main's first-parent root = the image's recorded root commit; otherwise `/opt/claude-workflows/scripts/…` by absolute path, owner root, not uid-writable | T37: foreign repo with `scripts/build-loop.sh` on main → installed copy runs; a symlinked install dir → refuse |
| F40 | D6 copy layout: `lib/` must sit under the copy's `SCRIPT_DIR`; `questions.sh` falls back to the installed copy (version skew) | not covered | Extract to `$T/scripts/{,lib/}` and include `scripts/questions.sh` | T33 extension: the copy sources its own lib; `QS` resolves inside `$T` |
| F41 | Loop body uses entry grammar (E2/E3): first-vs-last Needs split, planted answer line, headings | not covered (re-marks F32) | D3 body = plain prose + table; `--marker` refuses grammar lines and `> `-prefixes every line | T32 additions; T34 E2 case |
| F42 | Orchestrator launders working-tree edits into its chore commit (answers, roadmap, idea log) | not covered | Fresh worktree from MAIN_SHA per iteration; digest data from MAIN_SHA; `--cycle-diff --answered` before commit; no "commit it" | T38 |
| F43 | Loop git/bash calls run in the orchestrator's cwd (cwd resets per call; no isolation) | not covered | Orchestrator cwd outside any checkout; step-7 check that main's first-parent commits since the last `Main at:` are all orchestrator-made | T39 |
| F44 | Two agents in one worktree after re-dispatch; live-but-stalled loop holds a slot | not covered | At dispatch, `git worktree lock --reason "<session-id> <UTC time>"`; `--prompt` refuses a locked worktree unless `--steal` and the tip is older than N hours; a live loop with no commit across 2 fallback wakeups is stopped (TaskStop) and marked `stopped: stalled` by the orchestrator | T40: `--prompt` on a locked worktree → refuse; with `--steal` and an old tip → ok |
| F45 | Resume cap state not persisted; checkpoint commits reset "no new commit" | not covered (re-marks F36) | A `Dispatched: N` machine line on the brief (written by the orchestrator, read from main), with a hard cap on total dispatches regardless of commits | T41: brief with `Dispatched: 5` → `--prompt` refuses |
| F46 | Quiesce rules (step 1, pr-prep gate) versus live loops; concurrent test gates (log row 61) | not covered | Quiesce scoped to this iteration's subagents; `flock` around `health-check.sh` | health-check test: two concurrent runs serialize |
| F47 | Loop prompt forbids agents that pr-prep/code-review require; loops share the session scratchpad (memory) and overwrite each other's `shared.md` | not covered | Prompt: "subagents only for research and review, each with scratch dir `<scratchpad>/<brief stem>/`; never start build loops, background agents or schedules" | T19: prompt holds the scratch-dir line with the stem, and no blanket "never start agents" |
| F48 | Merge entry asks [1] with no diff; `--approved` merges S-refused paths (instruction files, dotfiles, symlinks) on one token; slug pins only 48 bits of TIP | not covered | Entry body is `--check`'s output: every changed path, every S refusal flagged ("changes CLAUDE.md"), full 40-hex TIP line, which `--approved` must also match | T35 additions: entry body with a different full TIP → refuse; S-refused instruction file → entry lists it |
| F49 | Per-day chore branch name versus many iterations a day; a failed land loses `Asked:` and merge-entry state → re-filing | not covered | `chore/dev-cycle-<date>-<HHMM>`; dispatch only after the land is verified; the next iteration lands a pending chore first | SKILL lint test: step 10 names the `merge-base --is-ancestor` check |
| F50 | D7 "clean and on main" versus `/workspace`'s habitual untracked files: either every self-merge refuses, or ff-only meets an untracked file at an incoming path | not covered | Define clean as `status --porcelain --untracked-files=no` empty, and refuse only when an untracked path collides with R's added paths; or never ff a shared checkout (CAS only) | T23d: untracked unrelated file → merge; untracked colliding file → refuse |
| F51 | The orchestrator's own porcelain git (status, commit, pr-prep's `git merge`) runs planted `.git` state, now unattended each iteration | partly (F25 covers the gate's calls only) | Each iteration starts with the D6 copy's `--state` check; stop the iteration on any finding | T42: `core.fsmonitor` set → `--state` refuses, exit 2 |
| F52 | Gate files changed by a review merge become the running gate (D6) and, after the release entry, the installed gate for every repo | not covered | `--approved` refuses when R touches `scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/` or `skills/dev-cycle/`, unless the entry slug is `merge-gate-<stem>-<sha12>` (its own ask); the release entry lists commits on main touching `scripts/` since the last release | T35: gate path under plain `merge-` slug → refuse |
| F53 | Per-iteration fixed cost (health check, 4 parallel subagents, pr-prep review-fix loop on the chore branch) times one iteration per loop finish | not covered (D12 bounds only no-op wakeups) | Put to the user as C5: full cycle at most every N hours; in between, a light iteration runs steps 7, 8 and 10 with a mechanical land checked by `--cycle-diff` | none; a decision, not code |

## Recommendations

**Must address before proceeding** (each changes the plan text that U1–U4's tests encode):
- **Narrative 1 / F43** (plan D1, SKILL step 10, plus step 7's main-moved check moved in from roadmap item (d)). Without it, the most likely way unreviewed work reaches main is an honest missed `cd`.
- **Narrative 2 / F32→F41** (plan D3 body grammar; §Script interface `--marker`; T32, T34). This is reproduced: the user's [2] is read as [1], and an entry is archived out of sight.
- **Narrative 3 / F42** (plan D8, D11; SKILL step 9; new `--cycle-diff`; T38). Re-mark F28 and F33 "not covered" in the table and in Q-103.
- **Narrative 4 / F38–F40** (plan D6 snippet; T33, T36, T37). This is cheap: about 10 lines in the snippet, and E1 shows the gap is real.

**Worth mitigating:**
- **Narrative 5 / F46, F49** (SKILL steps 1, 9 and 10; `health-check.sh` lock). Likely, but it fails slow and loud, not unsafe.
- **F44, F45** (re-mark F36 and F37): a worktree lock and a persisted dispatch count.
- **F47** (prompt text, T19): the prompt has to permit code-review's own subagents with distinct scratch dirs.
- **F48, F52** (merge-entry content, a gate-file carve-out under `--approved`).
- **F50, F51.**

**Acknowledged risks:** a hostile loop with the session's tools (F35) and shell can still do what F19 allows. F53 is a budget choice for the user (file it as C5), not a defect. The `mktemp -d` time-of-check-to-time-of-use window, where a same-uid process rewrites the extracted copy between the hash check and exec, is same-uid trust like F19, and is acceptable once F38's check runs immediately before exec.
