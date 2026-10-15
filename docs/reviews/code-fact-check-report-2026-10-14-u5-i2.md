Commit: c63da94d

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u5`)
**Scope:** fix range `git diff 42414307..c63da94d` on `feat/build-loop-u5` (commits 771a5d02, 57e26f6b, 87ca421e, c63da94d; 12 files), checked against `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh`, `scripts/health-check.sh`, `devcontainer-config/install.sh`, `skills/dev-cycle/SKILL.md`, `docs/reviews/override-log.md` and the iteration-1 reports. Commits main..42414307 are context only (iteration 1, `docs/reviews/code-fact-check-report-2026-10-14-u5-i1.md`).
**Checked:** 2026-10-14
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 36
**Summary:** 29 verified, 6 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution logs (scratch dir, not committed): `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2/logs/` holds `q156-paste.txt` (driver `../cases.sh`, paste copy `../paste.sh`, a throwaway clone at `../clone`), `bats-real.txt` and `qcheck.txt`. Every run used `GIT_CONFIG_GLOBAL=/dev/null` and `timeout`. Every process exited, and none was left running.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 patterns). Claim 34 (a count in a commit body) resembles the logged "count claimed in a commit message" patterns (59ca38f, 37c5ea9). It is a Mostly accurate miscount, not a fabricated symbol, so the log is not updated.

---

## Claim 1: "Self-merge never: workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/"

**Location:** `docs/dev-cycle.md:11`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `--settings` reads the line as a valid, set never list, and that the policy stays `review` unset, which is what the changed test asserts. Does not establish the glob matching of each entry against real paths, which is the `never_res` code, unchanged and not re-run here.

The test now asserts `[[ "$(line never)" == "never workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/ set: line "*" of docs/dev-cycle.md on the default branch" ]]` (`test/scripts/build-loop-read.bats:80`). `read_settings` sets `never_ok=1; NEVER=("${LIST[@]}"); NEVER_LINE="never $v set: ..."` (`scripts/build-loop.sh:812`). Run: `GIT_CONFIG_GLOBAL=/dev/null timeout 300 bats -f "own docs/dev-cycle.md" test/scripts/build-loop-read.bats`, cwd `/workspace/.claude/wt-build-loop-u5`, at 2026-10-15T04:53:48Z, exit 0, `ok 1 --settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)`.

**Evidence:** `test/scripts/build-loop-read.bats:72-82`, `scripts/build-loop.sh:785-822`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2/logs/bats-real.txt`

---

## Claim 2: "The scripts read the three lines above, and the two reader lines below, from the default branch's commit, never from a working tree ...; the orchestrator reads them through `scripts/build-loop.sh --settings`"

**Location:** `docs/dev-cycle.md:13-16`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `read_settings` (build-loop.sh) and `reader_settings` (lib, used by dev-cycle.sh) reading `docs/dev-cycle.md` from main's commit. Does not establish that no other reader exists. Only these two were traced, as in iteration 1's claim 6.

`read_settings` has the comment "...CONSTRAINTS (its word...) from main's commit" and runs `where="of $f on the default branch"; if ! main_file "$f" "$SETTINGS_AWK"` (`scripts/build-loop.sh:778-790`). `reader_settings` uses `local f=docs/dev-cycle.md ...` and `if ! main_by_name; then` (`scripts/lib/dev-cycle-read.sh:655-659`), with the header note "reader_settings reads docs/dev-cycle.md from the default branch's commit" (`scripts/lib/dev-cycle-read.sh:54`). This fixes i1 claim 6.

**Evidence:** `scripts/build-loop.sh:778-790`, `scripts/lib/dev-cycle-read.sh:54`, `scripts/lib/dev-cycle-read.sh:655-662`

---

## Claim 3: "every changed path is listed in the brief's `Paths:` line or is one of the brief's own files (named by its stem)"

**Location:** `docs/dev-cycle.md:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `ownfile`'s keying on the brief's full stem and `srules`' use of it. Does not establish the lower-case-only condition on own files, which the sentence omits.

`ownfile` runs `[[ "$1" =~ ^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$ && "${BASH_REMATCH[2]}" == "$2" ]]`, with `$2` the "full stem" (`scripts/lib/dev-cycle-read.sh:1950-1960`). `srules` runs `[[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:1211`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1950-1960`, `scripts/build-loop.sh:1203-1218`

---

## Claim 4: "A self-merge refused for a path falls through to review; a conflict is filed as stopped, and an environment refusal is retried."

**Location:** `docs/dev-cycle.md:25-26`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SKILL.md step 7's routing of `--merge` refusals for a self-merge brief. Does not establish what happens to a path refusal after it falls through. That is claim 5b.

SKILL.md step 7 reads: "A refusal of the paths ("K of N changed paths refused", `deny` lines following) falls through to review: a merge entry as below ... A conflict is `stopped`. Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's, not the loop's: recorded, named in the final message, and tried again next iteration." (`skills/dev-cycle/SKILL.md:582-588`). This fixes i1 claim 8.

**Evidence:** `skills/dev-cycle/SKILL.md:574-588`

---

## Claim 5a: "Under both policies a change to `docs/constraints.md`, this file, the questions files, the roadmap or another brief is refused, and such a branch is filed as stopped" (under `review`)

**Location:** `docs/dev-cycle.md:29-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the N rules' refusal of the named files under both policies and the review path's `refuse` → stopped routing. Does not establish the self-merge path's routing (claim 5b). The list is not exhaustive: the idea log and cycle records are refused too.

`nrules` refuses `cycle|settings) DENY="one of the dev cycle's own files"` and `user) DENY="the user's constraints doc..."` (`scripts/build-loop.sh:1153-1160`). `writable` covers `^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ ... || anybrief "$1"` (`scripts/lib/dev-cycle-read.sh:247-249`). The header says the N rules apply "under either policy" (`scripts/build-loop.sh:356`). A deny makes `--check`'s verdict `refuse BRIEF: ... "K of N changed paths refused ..."` (`scripts/build-loop.sh:300, 315-316`). Step 7's review bullet says "A `refuse` verdict is filed as `stopped`" (`skills/dev-cycle/SKILL.md:597-598`).

**Evidence:** `scripts/build-loop.sh:300-316`, `scripts/build-loop.sh:356-366`, `scripts/build-loop.sh:1130-1170`, `scripts/lib/dev-cycle-read.sh:247-249`, `skills/dev-cycle/SKILL.md:589-599`

---

## Claim 5b: "... and such a branch is filed as stopped, not as a merge entry" (under `self-merge`)

**Location:** `docs/dev-cycle.md:29-31`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers SKILL.md step 7's handling of a self-merge brief whose `--merge` prints an N-rule deny. Does not establish orchestrator behaviour beyond the skill text, since no script implements step 7's routing.

Under `self-merge`, an N-rule deny comes out of `--merge` as a path refusal, and the skill files a merge entry for it first. Step 7: "A refusal of the paths ("K of N changed paths refused", `deny` lines following) falls through to review: a merge entry as below, quoting `--merge`'s lines (a deny from a rule every merge applies refuses again under `--approved`, and is then filed as `stopped`)" (`skills/dev-cycle/SKILL.md:582-585`). The skill does not separate N-rule denies from S-rule denies at this point. So the branch reaches you as a `merge-STEM-SHA12` entry. Only after you answer `[1] merge` does `--approved` refuse it and file it as stopped (`skills/dev-cycle/SKILL.md:634-637`: "any other refusal is filed as `stopped`"). The sentence holds for `review` only. A precise version: "under review it is filed as stopped; under self-merge it first comes to you as a merge entry, and is filed as stopped when `--approved` refuses it."

**Evidence:** `skills/dev-cycle/SKILL.md:574-588`, `skills/dev-cycle/SKILL.md:634-638`, `scripts/build-loop.sh:400-410`

---

## Claim 6: "Slots. ... how many briefs the queue holds for build loops at once. The queue counts open briefs whose loop is absent (not yet dispatched) or working, plus those sent back to a loop; a blocked, stopped or ready-for-review one waits on you and is not counted."

**Location:** `docs/dev-cycle.md:36-39`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers step 8's queue count and step 10's use of slots. Does not establish runtime counts.

Step 8 matches: "while the queue is shorter than `--settings`' `slots` line ...: open briefs whose loop step 7 read as absent or working, plus those it sends back to a loop, each counted once (a blocked, stopped, capped or ready one, or a stalled one held, waits on the user and is not counted)" (`skills/dev-cycle/SKILL.md:647-652`). The prose leaves out the setting's second use. Step 10 caps dispatch with it too: "Fill free slots (`--settings`' `slots` less the loops this session runs)" (`skills/dev-cycle/SKILL.md:770-771`). The skill's own settings template still calls it "live loops at once" (`skills/dev-cycle/SKILL.md:119`). A precise version adds: "and step 10 starts loops only while fewer than that many run."

**Evidence:** `skills/dev-cycle/SKILL.md:119`, `skills/dev-cycle/SKILL.md:647-652`, `skills/dev-cycle/SKILL.md:770-772`

---

## Claim 7: "sessions in this repo read `workflows/`, `skills/`, `guides/` and `patterns/` from their own checkout"

**Location:** `docs/dev-cycle.md:44`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the in-repo instruction file's pointers to these directories. Does not establish that every session follows them rather than the installed `~/.claude` copies. That is a runtime choice and was not observed.

`AGENTS.md` is tracked at the repo root (paraphrased — no quote available because the claim is about file layout: `git ls-files` lists `AGENTS.md`, `GEMINI.md` and `global-instructions/CLAUDE.md` as the only instruction files). It directs sessions to "check `workflows/` for applicable process docs" and to skills "in `skills/`" and "read the skill file before starting the work it covers", and it cites `guides/doc-freshness.md` (`AGENTS.md:7, 23, 63`). Skills link to patterns by relative path, for example `[legibility-target tagging](../../patterns/orchestrated-review.md#legibility-target-tagging)` (`skills/code-review/SKILL.md:504`).

**Evidence:** `AGENTS.md:7`, `AGENTS.md:23`, `AGENTS.md:63`, `skills/code-review/SKILL.md:502-505`

---

## Claim 8: "the health check the orchestrator runs every iteration executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/` from its worktree"

**Location:** `docs/dev-cycle.md:45-46`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers step 1's run of `scripts/health-check.sh` from WT and what it executes. "Every iteration" has one exception: step 1 skips the check when the last one passed and only `chore` lines landed since. A self-merge is not a `chore` line, so the check runs after one. Does not establish which suites run under `--fast` versus `--slow` at any given time.

Step 1: "run the repo's health check from WT, if it has one (e.g. `scripts/health-check.sh` in claude-workflows; skipped when the previous iteration's `1.` line reads `passed at P` or `unchanged since P` and step 0.2 listed only `chore` lines" (`skills/dev-cycle/SKILL.md:382-386`). health-check.sh sets `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` and runs `source "$REPO_ROOT/scripts/lib/log-format.sh"` (`scripts/health-check.sh:67, 79`). It also sets `local runner="${HEALTH_CHECK_RUN_TESTS:-$REPO_ROOT/scripts/run-tests.sh}"` (`scripts/health-check.sh:413`) and runs `for hook in "$REPO_ROOT"/hooks/*.sh` (`scripts/health-check.sh:578`). The suites run hooks and devcontainer-config scripts by path. For example: `HOOK="${LOG_USAGE_POST_HOOK:-$BATS_TEST_DIRNAME/../../hooks/log-usage-post.sh}"` (`test/hooks/log-usage-post.bats:15`). `grep -l "devcontainer-config/" test/*.bats` lists `cc-push.bats`, `install-host.bats`, `cc-isolated-functions.bats` and two more (paraphrased — no quote available because the evidence is a grep file list).

**Evidence:** `skills/dev-cycle/SKILL.md:378-392`, `scripts/health-check.sh:67-83`, `scripts/health-check.sh:400-420`, `scripts/health-check.sh:578`, `test/hooks/log-usage-post.bats:15`

---

## Claim 9: "while the release paste runs `devcontainer-config/install.sh` on the host before you see its diff"

**Location:** `docs/dev-cycle.md:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both pastes execute install.sh and that the payload diff is drawn by install.sh itself (`review_diff`). Does not establish install.sh's own internal gates.

Q-156's paste ends `) && ./devcontainer-config/install.sh` (`docs/working/questions.md:494`). Step 0.1's paste is `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh` (`skills/dev-cycle/SKILL.md:306-307`). The review diff is drawn inside the script: `review_diff "$DEST" "$stage/" "${PAYLOAD[@]}" || same=0` (`devcontainer-config/install.sh:537`). So install.sh's own code has already run before any diff is shown.

**Evidence:** `docs/working/questions.md:494`, `skills/dev-cycle/SKILL.md:303-309`, `devcontainer-config/install.sh:527-537`

---

## Claim 10: "`templates/` (a snippet other repos copy by hand) and `global-instructions/` (every session's global instructions after a release; the floor already refuses its `CLAUDE.md`)"

**Location:** `docs/dev-cycle.md:48-49`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two directories' contents, install.sh's staging of `global-instructions/CLAUDE.md`, and the floor's instruction-file rule. Does not establish whether any other repo has copied the snippet.

`git ls-files templates global-instructions` lists `global-instructions/CLAUDE.md` and `templates/gitattributes-snippet.txt` (paraphrased — no quote available because the claim is about directory layout). RPI's workflow says "A template is available at `templates/gitattributes-snippet.txt` in this repo" (`workflows/research-plan-implement.md:44`). install.sh sets `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`). The floor's `INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[...]+)?\.md$|^skill\.md$'` (`scripts/lib/dev-cycle-read.sh:701`) is tested by basename in `isstart` (`scripts/lib/dev-cycle-read.sh:714`), and `truthrule` maps it to `instr` (`scripts/lib/dev-cycle-read.sh:1919`).

**Evidence:** `workflows/research-plan-implement.md:44`, `devcontainer-config/install.sh:135`, `scripts/lib/dev-cycle-read.sh:701-714`, `scripts/lib/dev-cycle-read.sh:1916-1925`

---

## Claim 11: "So in this repo self-merge can land only files outside those directories and off the floor: docs, `README.md`, `runs/` and `archive/`."

**Location:** `docs/dev-cycle.md:50-51`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the top-level tree at HEAD against the never line and the floor. "docs" means the part of `docs/` off the floor, and much of `docs/` is on it (working, reviews, thoughts, decisions, human-author, the cycle files). Does not establish that every file under `runs/` or `archive/` passes the import walk.

`git ls-tree --name-only HEAD` lists `.apir5-probe.sh .apir5-probe2.sh .evidence-config.example .gitattributes .gitignore .shellcheckrc AGENTS.md GEMINI.md README.md archive devcontainer-config docs global-instructions guides hooks patterns runs scripts skills templates test workflows` (paraphrased — no quote available because this is a tree listing). The dot paths fall to `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"`, and AGENTS.md and GEMINI.md fall to `isstart` → `instr` (`scripts/lib/dev-cycle-read.sh:1918-1920`). Ten of the remaining entries are on the never line. That leaves `README.md`, `archive`, `docs` and `runs`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1916-1925`, `scripts/lib/dev-cycle-read.sh:1997-2014`, `docs/dev-cycle.md:11`

---

## Claim 12: The rubric's mapping of iteration-1 findings (1 red, A1–A7, C1–C12, statuses, overrides, Confirmed Good)

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:1-95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that every i1 fact-check non-Verified claim and every security and api-consistency finding maps to one rubric row with matching severity, and that the cited override rows and Confirmed Good figures match. Does not establish the "fix-drift lite check found 1, then none" process claim. That run left no artifact in scope.

Fact-check i1: claims 6, 8, 10, 24 map to C1–C4, claims 12/28 to A1, 25 to A3, 26 to A4, 18 to A5 and 42 to A7, as the i1 summary lists them (`docs/reviews/code-fact-check-report-2026-10-14-u5-i1.md`, "Claims Requiring Attention"). The security summary table maps F1 (High) to R1, F2 to A2, F3/F4 to A1, F5 to C10, F6 to C11 and F7 to C12 (`docs/reviews/security-review-2026-10-14-u5-i1.md:186-194`). The api-consistency table maps F1 to A6, F2 to C3, F3 to A2, F4 to C5, F5 to C6, F6 to C7, F7 to C8 and F8 to C9 (`docs/reviews/api-consistency-review-2026-10-14-u5-i1.md:169-178`). Override row 244 is "docs/dev-cycle.md's text about the policy line is stale ... Revisit trigger: U5" (`docs/reviews/override-log.md:244`). The Confirmed Good figures match a re-run: `git log --first-parent 8d0e660e..main` gives 11 commits, the C-to-M diff outside `docs/` gives 28 paths, and the skipped-critic signal "16 code lines outside docs/" matches `git diff --stat main...42414307 -- . ':!docs'` ("13 insertions(+), 3 deletions(-)").

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:15-95`, `docs/reviews/security-review-2026-10-14-u5-i1.md:184-194`, `docs/reviews/api-consistency-review-2026-10-14-u5-i1.md:167-178`, `docs/reviews/override-log.md:244`

---

## Claim 13: The two new override-log rows (security i1 F7 Won't-Fix; fact-check i1 claim 42 Won't-Fix)

**Location:** `docs/reviews/override-log.md:828-829`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row's finding, severity and rationale against the i1 reports, install.sh and the Q-156 paste. Does not establish decision 035's full text beyond its existence and install.sh's own header.

Row 1 says "a `git hash-object --no-filters` check was suggested, untested (security i1 F7, Informational, pre-existing)". That matches F7: "**Severity:** Informational ... Confidence: High (pre-existing; accepted by decision 035) ... This is untested here" (`docs/reviews/security-review-2026-10-14-u5-i1.md:124-136`). The row's "install.sh installs committed content via `git archive`" matches the header line "Both targets install COMMITTED content (HEAD, via git archive)" (`devcontainer-config/install.sh:46`). `docs/decisions/035-install-sh-gating.md` exists. "Q-156's paste now also refuses when any released directory's committed tree differs from M" holds (claim 25). Row 2 matches i1 claim 42 (Mostly accurate, commit 2846f9fa) and rubric A7 (Must Address, Won't-Fix).

**Evidence:** `docs/reviews/override-log.md:828-829`, `docs/reviews/security-review-2026-10-14-u5-i1.md:124-136`, `devcontainer-config/install.sh:46`, `devcontainer-config/install.sh:277-280`

---

## Claim 14: "It is recorded instead as decision-log row 72 (written as row 70 before rows 70 and 71 were taken)"

**Location:** `docs/working/plan-build-loop-handoff.md:91`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the D10 bullet's row number. Does not establish row 72's text beyond its number. Steps 11–13 at `:349-350` still say row 70, which the as-built note supersedes by its own words.

The decision log holds `| 72 | 2026-10-14 | **The dev cycle is an orchestrator loop that dispatches build briefs ...` (`docs/decisions/log.md:95`). This fixes i1 claim 18.

**Evidence:** `docs/working/plan-build-loop-handoff.md:91`, `docs/decisions/log.md:95`

---

## Claim 15: As-built note: "a never line wider than D5's interim `workflows/` ... (override row 682; security review i1 F1, F3, F4) ... Q-103 re-routed, its residuals completed from the override log; Q-149 (the never line's width)"

**Location:** `docs/working/plan-build-loop-handoff.md:358`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cited row and findings and the entries named. Does not re-verify the note's unchanged parts, which iteration 1 checked.

Row 682 concerns "`scripts/health-check.sh` (and the suites it runs) ... add scripts/health-check.sh and test/ there, or record the acceptance" (`docs/reviews/override-log.md:682`). Security F1, F3 and F4 are "Self-merge can land install.sh", "Never-line rationale covers skills/, patterns/, guides/ too" and "Health-check backstop is self-mergeable" (`docs/reviews/security-review-2026-10-14-u5-i1.md:188-191`). Claims 20 and 22 cover Q-103 and Q-149.

**Evidence:** `docs/working/plan-build-loop-handoff.md:358`, `docs/reviews/override-log.md:682`, `docs/reviews/security-review-2026-10-14-u5-i1.md:186-191`

---

## Claim 16: "**Answer (2026-10-04, in session; plan D12; filed 2026-10-14):** [1], a full cycle every iteration for now"

**Location:** `docs/working/questions-archive.md:2715`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `[1]` names the option matching the answer text. Does not establish the in-session answer itself.

The entry's table has `| **[1] Full cycle every iteration** |` (`docs/working/questions-archive.md:2723`). `scripts/questions.sh check` passes: run at 2026-10-15T04:53:49Z, cwd the worktree, exit 0, "✓ questions: structure valid, indexes current".

**Evidence:** `docs/working/questions-archive.md:2712-2726`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2/logs/qcheck.txt`

---

## Claim 17: "F37 ... `questions.sh check` catches it, at the land or, after a merge-in of main (which skips step 1's check), at the next health check."

**Location:** `docs/working/questions.md:100`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers step 9's check placement, the merge-in path and health-check gate 14. Does not establish that a health check runs before the clash matters.

Step 9.1 runs "`questions.sh index` and `check` in WT when this iteration filed or edited entries". The merge-in remedies say "merge main in (below) and go back to 3" and "merge main in, then 3 again", which skips 1 (`skills/dev-cycle/SKILL.md:725-727, 750-755`). Gate 14 of health-check.sh is "Running-questions doc: entry grammar, unique ids, index freshness (gate)" (`scripts/health-check.sh:64`). This fixes i1 claim 24.

**Evidence:** `skills/dev-cycle/SKILL.md:723-764`, `scripts/health-check.sh:64`, `scripts/health-check.sh:1112-1120`

---

## Claim 18: "F58 ... The release entry (`image-lag`) ... flags self-merge subjects. The release paste runs `devcontainer-config/install.sh` before it shows its diff, so that directory is on this repo's never line (Q-149)."

**Location:** `docs/working/questions.md:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the subject-based flag and the never-line membership. Does not establish what the image carries beyond install.sh's lists.

Step 0.1: "flag a subject ending `(build-loop self-merge)`" (`skills/dev-cycle/SKILL.md:301-302`). `devcontainer-config/` is on `docs/dev-cycle.md:11`. The install.sh ordering is claim 9.

**Evidence:** `skills/dev-cycle/SKILL.md:298-305`, `docs/dev-cycle.md:11`

---

## Claim 19: "R8 ... `err`, `diff`, and `answer`, the file holding `--approved`'s verdict on the merge entry (override rows 509, 684)"

**Location:** `docs/working/questions.md:103`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `approval()`'s write-then-read of the file and the two rows. Does not establish the race window's timing.

`approval()` runs `check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"`, then `case "$r" in "keep $1") ;;` (`scripts/build-loop.sh:1445-1447`). Row 684: "approval reads check_answer's result word back from `$GATE_TMP/answer` ... U5's Q-103 re-route, which adds `answer` to row 509's surface list" (`docs/reviews/override-log.md:684`). This fixes i1 claim 25.

**Evidence:** `scripts/build-loop.sh:1440-1456`, `docs/reviews/override-log.md:509`, `docs/reviews/override-log.md:684`

---

## Claim 20: "Also routed here during the build (override-log rows in `docs/reviews/override-log.md`, by line)" and its items citing rows 668, 548, 749, 750, 784, 786, 787, 797, 801, 802, 682

**Location:** `docs/working/questions.md:104-118`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each item against the row at the cited line, and that the eleven rows i1 claim 26 named are all present. Does not establish that no other row routes to Q-103. No fresh sweep of the log was made.

Each cited line holds the matching row. 548: "a loop that points origin/HEAD at its own branch makes reader_settings read that branch's docs/dev-cycle.md". 668: "a hand-edited rebase todo holding an `update-ref refs/heads/main` line". 749: "a planted pre-commit hook could re-stage files". 750: "a FIFO swapped in between the plain-file test and flock's open". 784: "a rewrite of main to a history that never held a record bootstraps again". 786: "a session that ends first loses it and the cap of 4 admits one more run". 787: "`--prompt --steal` can take another live session's loop that has not committed in two hours". 797: "Merge entries flag floor paths by class, not the floor's own reasons". 801: "`--start`/`--prompt` read main live after step 10's `--main-log MAIN` re-read". 802: "`--cycle-diff`/`--land-cycle` accept any `--answered` ID". 682: health-check.sh self-mergeable. Each line also routes to Q-103 or U5's list. This fixes i1 claim 26.

**Evidence:** `docs/reviews/override-log.md:548`, `:668`, `:682`, `:749`, `:750`, `:784`, `:786`, `:787`, `:797`, `:801`, `:802`

---

## Claim 21: Q-103 options: "[1] review: Every `ready` branch the always-on rules pass gets one merge entry"; "[2] ... with this repo's never line (Q-149) only docs, `README.md`, `runs/` and `archive/` off the floor can self-merge"

**Location:** `docs/working/questions.md:121-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers [1]'s review routing (an `ok` verdict gets a merge entry, a `refuse` is stopped) and [2]'s scope, the same as claim 11. Does not establish [2]'s "falls to [1]'s entry" for N-rule denies beyond the first entry (see claim 5b).

Step 7 review: "On `ok`, one merge entry ... A `refuse` verdict is filed as `stopped`" (`skills/dev-cycle/SKILL.md:589-598`). [2]'s scope is claim 11.

**Evidence:** `skills/dev-cycle/SKILL.md:589-599`, `docs/dev-cycle.md:50-51`

---

## Claim 22: Q-149 (slug self-merge-never-scope): "sessions read `skills/` (beyond `SKILL.md`, which the floor already refuses), `guides/` and `patterns/` ...; the health check ... executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/`"; options [1]–[3]; "a one-line edit ... and its test line in `test/scripts/build-loop-read.bats`"

**Location:** `docs/working/questions.md:361-380`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the premise, the SKILL.md floor rule, the options' scope and the test line. Does not establish [2]'s "code self-merges when its brief lists it" for gate code and `SKILL.md`, which the floor still refuses. The entry's own premise says so for `SKILL.md`.

`INSTRUCTION_FILE` includes `^skill\.md$` by basename (`scripts/lib/dev-cycle-read.sh:701, 714`). The premise matches claims 7–9. The test line pins the never list (claim 1). No live reference to the old slug `self-merge-never-workflows` remains outside `docs/reviews/` (paraphrased — no quote available because the claim covers absence: `git grep` found no matches).

**Evidence:** `docs/working/questions.md:361-380`, `scripts/lib/dev-cycle-read.sh:701-714`, `test/scripts/build-loop-read.bats:79-80`

---

## Claim 23: "### Q-153 · build-loop-c4-merged-branch-deletion"

**Location:** `docs/working/questions.md:426`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the family (`build-loop-c1`..`c5` for Q-150..Q-154), the index row and the absence of the old slug. Does not establish anything about the entry's body, which is unchanged.

The index row reads `[Q-153](#q-153--build-loop-c4-merged-branch-deletion)` (`docs/working/questions.md:37`). The family runs Q-150 `build-loop-c1-questions-writer`, Q-151 `-c2-`, Q-152 `-c3-` and Q-154 `build-loop-c5-cycle-cost`. `git grep merged-branch-deletion-rule` outside `docs/reviews/` found nothing (paraphrased — no quote available because the claim covers absence).

**Evidence:** `docs/working/questions.md:33-37`, `docs/working/questions.md:426`, `docs/working/questions-archive.md:2712`

---

## Claim 24: "M is `771a5d028e8ef8a61253ad2f167ab421225d5af2`, the last commit on `feat/build-loop-u5` that changes anything the release installs; the branch's later commits change only `docs/`."

**Location:** `docs/working/questions.md:470`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the branch at c63da94d. Commits added after c63da94d (this report's own included, which is under `docs/`) are outside the check. Also covers the C-to-M path list (28 paths, about 500 under `docs/`).

Run: `git log --format=%h 771a5d02..HEAD -- devcontainer-config global-instructions guides hooks patterns scripts skills workflows`, cwd the worktree, at 2026-10-15T04:47Z, exit 0, empty output. `git log --name-only 771a5d02..HEAD` with `docs/` lines removed shows only the three subject lines. `git diff --name-only 8d0e660e 771a5d02` outside `docs/` gives exactly the entry's 28 paths, with `test/lib/d6-snippet.bash` as `D`. 501 paths fall under `docs/`. Output was captured in the session transcript only. These are read-only git queries, so they were not logged to a file.

**Evidence:** `docs/working/questions.md:470-488`

---

## Claim 25: Q-156 paste: "The check compares, with `rev-parse` alone, every directory the release installs ... at HEAD against M, so it refuses when main has moved those paths past what this entry lists, or when HEAD is not main" (in a subshell)

**Location:** `docs/working/questions.md:491-498`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste's guard on a merged main, a detached HEAD, a non-main branch, and main moving a released dir, a non-released file (`README.md`, `test/`) or a non-installed file in `global-instructions/`. Also covers that `exit` stays inside the subshell. Does not establish install.sh's own behaviour (replaced by an echo). "HEAD is not main" compares commits, so a detached HEAD at main's commit passes.

Run: `LC_ALL=C timeout 300 bash /home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2/cases.sh /home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2`, cwd the scratch dir, at 2026-10-15T04:49:41Z, exit 0. The driver clones the worktree, merges c63da94d into main at b279a2ba (`a4ce77e1 Merge branch 'u5tip'`) and runs the paste verbatim with `./devcontainer-config/install.sh` replaced by `echo INSTALL-WOULD-RUN`. Results: merged main → `INSTALL-WOULD-RUN`; detached at the branch tip → `release refused: HEAD is not main`; main moves `hooks/wiring.json` → `release refused: hooks differs from M`; main moves `README.md` → runs; main adds `global-instructions/extra.md` → `release refused: global-instructions differs from M`; main moves `test/` → runs; on another branch → `HEAD is not main`. Each case printed `outer shell still alive`. The only git subcommand in the guard is `rev-parse` (`docs/working/questions.md:494`).

**Evidence:** `docs/working/questions.md:491-498`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2/logs/q156-paste.txt`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2/paste.sh`

---

## Claim 26: "every directory the release installs (install.sh's payload and its own directory)" = `devcontainer-config global-instructions guides hooks patterns scripts skills workflows`

**Location:** `docs/working/questions.md:491, 494`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the list against `CLAUDE_HOME_SRC` and `PAYLOAD`. Does not establish anything install.sh reads outside those two arrays.

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`). `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh ... claude-home)` lists files under `devcontainer-config/` (`devcontainer-config/install.sh:110`). The paste's list covers both arrays. One entry is wider than what install.sh installs: from `global-instructions/` it installs only `CLAUDE.md`, but the paste compares the whole directory. So the paste also refuses on a change install.sh would not ship (claim 25's `extra.md` case). This fails closed. A precise version: "every directory install.sh installs from (its payload's directories and its own), `global-instructions/` whole".

**Evidence:** `devcontainer-config/install.sh:110`, `devcontainer-config/install.sh:135`, `docs/working/questions.md:494`

---

## Claim 27: "flag a subject ending `(build-loop self-merge)`, which no one reviewed: a hand commit with that subject reads the same, so the flag is a pointer, not proof"

**Location:** `skills/dev-cycle/SKILL.md:301-303`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the gate's subject has no unique marker in the subject line alone. Does not establish `--main-log`'s class test, which also checks the trailer and byte shape.

The gate's message is `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n"` (`scripts/build-loop.sh:1464`). Any commit can carry that subject. The step's flag reads the subject only (`--format='%h %s'`, `skills/dev-cycle/SKILL.md:300`).

**Evidence:** `skills/dev-cycle/SKILL.md:298-303`, `scripts/build-loop.sh:1457-1465`

---

## Claim 28: "each subject or path holding `<`, `>`, a CR or another control byte written as `(withheld: see SHA)` (questions.sh reads `<!--` anywhere in a line)"

**Location:** `skills/dev-cycle/SKILL.md:303-305`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the parenthetical's mechanism against questions.sh and the lib's questions reader. Does not establish that the withhold set covers every byte `--check-answer` refuses.

questions.sh has no rule for a bare `<!--`. What it finds anywhere in a line is its full index markers: `INDEX_START='<!-- index:start -->'` (`scripts/questions.sh:140`), matched with `index($0, start) { print; ...` (`scripts/questions.sh:340`) and `grep -aqF "$INDEX_START"` (`scripts/questions.sh:312`). A bare unclosed `<!--` matters to the lib's reader, which `--check-answer` uses: `function opencomment(l, n, p) {  # the last <!-- on the line has no --> after it` (`scripts/lib/dev-cycle-read.sh:277`). Step 7 notes that such a line makes "`--check-answer` ... refuse the whole questions file" (`skills/dev-cycle/SKILL.md:611-613`). build-loop.sh words the questions.sh half precisely: `"<!--" anywhere: questions.sh finds its index markers anywhere in a line` (`scripts/build-loop.sh:966`). The rule itself (withhold `<`) covers both readers. A precise version: "(questions.sh finds its `<!-- index:… -->` markers anywhere in a line, and `--check-answer` refuses an unclosed `<!--`)".

**Evidence:** `scripts/questions.sh:140-141`, `scripts/questions.sh:312`, `scripts/questions.sh:339-343`, `scripts/lib/dev-cycle-read.sh:255-280`, `scripts/build-loop.sh:966`, `skills/dev-cycle/SKILL.md:611-613`

---

## Claim 29: "else one `you: judgment` entry, slug `constraints-doc-missing`, asking for `docs/constraints.md`, unless an open one with that slug exists: D2"

**Location:** `skills/dev-cycle/SKILL.md:768-770`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the slug matching the filed entry. Does not establish any script check of the slug, since none exists: the step is skill text.

The filed entry is `### Q-155 · constraints-doc-missing` (index row `[Q-155](#q-155--constraints-doc-missing) | you: judgment`, `docs/working/questions.md:38`).

**Evidence:** `skills/dev-cycle/SKILL.md:767-772`, `docs/working/questions.md:38`

---

## Claim 30a: "plus any the project adds to its `Self-merge never:` line, which self-merge requires: `Self-merge never: none` for an empty list"

**Location:** `workflows/codebase-onboarding.md:453`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `read_settings`' requirement. Does not establish other projects' files.

`if [[ "$v" == self-merge && -z "$never_ok" ]]; then POLICY_LINE="policy review unset: ... but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"` (`scripts/build-loop.sh:818-820`).

**Evidence:** `scripts/build-loop.sh:800-822`

---

## Claim 30b: "a branch that changes the cycle's own files is stopped under either policy"

**Location:** `workflows/codebase-onboarding.md:453`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the end state under each policy. Does not establish the routing before that end state, which claim 5b covers.

The end state holds. Under `self-merge`, though, the branch first comes to the user as a merge entry, and is stopped only when `--approved` refuses it after a `[1] merge` answer (`skills/dev-cycle/SKILL.md:582-585`, quoted in claim 5b). A precise version: "...is never merged under either policy (under self-merge it reaches you first as a merge entry that cannot land)". Unlike claim 5b, this sentence does not deny the merge entry. It is only imprecise.

**Evidence:** `skills/dev-cycle/SKILL.md:582-585`, `skills/dev-cycle/SKILL.md:634-637`

---

## Claim 31: Commit 771a5d02 body: "sessions read the first group from the checkout, the orchestrator's health check executes the second, and the release paste runs install.sh before its diff is seen ... The settings prose says ... which files both policies refuse"

**Location:** commit `771a5d02`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the body against its diff. Does not establish the fix-drift history.

The body lists the ten directories in the line's order (`workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/`) and then speaks of "the first group" and "the second". In that order neither group is contiguous: the checkout group is workflows, skills, guides and patterns (`docs/dev-cycle.md:44`). `templates/` and `global-instructions/` fall in neither group, as 87ca421e's body admits ("named eight of its ten directories"). The other parts match the diff: the onboarding line, step 0.1's withhold rule and pointer wording, step 10's slug and the test assertion. "Which files both policies refuse" describes the prose added, and that prose carries claim 5b's error.

**Evidence:** `docs/dev-cycle.md:11`, `docs/dev-cycle.md:44-51`, `skills/dev-cycle/SKILL.md:301-305`, `test/scripts/build-loop-read.bats:79-80`

---

## Claim 32: Commit 57e26f6b body (Q-103, Q-149, Q-153, Q-154, Q-156 fixes; "Q-156's M is a branch commit rather than the merge, so the paste stays valid after the merge as long as main changes no released path")

**Location:** commit `57e26f6b`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named fix against its diff and the Notes line against claim 25's runs. Does not establish the "IDs" provenance of the questions entries.

Each named item is in the diff (claims 14, 16, 19, 20, 22–25). The Notes line matches claim 25's cases: the merged main passes and a moved `hooks/` refuses (`/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i2/logs/q156-paste.txt`).

**Evidence:** `docs/working/questions.md:97-122`, `docs/working/questions.md:361-380`, `docs/working/questions.md:463-498`, `docs/working/plan-build-loop-handoff.md:91`

---

## Claim 33: Commit 87ca421e body: "the never line's prose named eight of its ten directories. It now says why templates/ and global-instructions/ are listed and which files self-merge can still land here ...; Q-149 and Q-103 [2] say the same."

**Location:** commit `87ca421e`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the before and after text. Does not establish the fix-drift check run itself.

At 771a5d02, the prose named the eight and ended with "So in this repo self-merge can land only docs that are not on the floor." (`git show 771a5d02:docs/dev-cycle.md`, lines 44-48). 87ca421e changes `docs/dev-cycle.md` (5 lines) and `docs/working/questions.md` (Q-103 [2] and Q-149 [1], each now reading "only docs, `README.md`, `runs/` and `archive/` off the floor").

**Evidence:** `docs/dev-cycle.md:48-51`, `docs/working/questions.md:122`, `docs/working/questions.md:373`

---

## Claim 34: Commit c63da94d body: "the rubric (1 red, 6 Must Address, 12 Consider, all fixed but two Won't-Fix rows), and two override-log rows"

**Location:** commit `c63da94d`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the counts against the rubric committed in the same change. Does not establish the skipped-critic rationale beyond claim 12.

The rubric's Must Address table has seven rows, A1 through A7 (`docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:23-29`). A7 is one of the two Won't-Fix rows, so it is counted, not excluded. The body should say 7. The rest holds: R1 is the one red, C1–C12 are the 12 Consider rows, A7 and C12 are the two Won't-Fix rows, and override-log.md gains two rows. This resembles the logged commit-count patterns (59ca38f, 37c5ea9).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:15-52`, `docs/reviews/override-log.md:828-829`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`docs/dev-cycle.md:29-31`): under self-merge, a branch touching the constraints doc, this file, the questions files, the roadmap or another brief is filed first as a merge entry (step 7: a path refusal falls through to review). It is stopped only after `--approved` refuses it. "Filed as stopped, not as a merge entry" holds for `review` only.

### Stale
- none

### Mostly Accurate
- **Claim 6** (`docs/dev-cycle.md:36-39`): slots also cap dispatch (step 10: "slots less the loops this session runs"), not only the queue. The skill's template still says "live loops at once".
- **Claim 26** (`docs/working/questions.md:491,494`): the paste compares all of `global-instructions/`, but install.sh installs only its `CLAUDE.md`. This fails closed, but it is not "every directory the release installs".
- **Claim 28** (`skills/dev-cycle/SKILL.md:303-305`): questions.sh finds its full `<!-- index:… -->` markers anywhere in a line. It is `--check-answer` that refuses an unclosed `<!--`.
- **Claim 30b** (`workflows/codebase-onboarding.md:453`): "stopped under either policy" is the end state. Under self-merge the branch is a merge entry first.
- **Claim 31** (commit 771a5d02): "the first group ... the second" does not map onto the line's order, and two directories fall in neither group. The commit also carries claim 5b's error.
- **Claim 34** (commit c63da94d): the rubric has 7 Must Address rows, not 6.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/code-fact-check-report-2026-10-14-u5-i2.md, structured per the code-fact-check skill, first line `Commit: c63da94d`, header carrying `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All 9 focus areas were checked. The Q-156 paste was run across 7 cases in a throwaway clone. The changed bats test and `questions.sh check` were run. M's "last commit" claim and the directory list were re-derived.
- Out of scope: the full bats suites and the health check (only the one changed test was run); re-verifying iteration 1's Verified claims outside the fix range; a fresh sweep of the override log for Q-103 routes beyond the rows i1 named.
- Escalate: claim 5b. The settings prose tells the user that the cycle-file branches never reach them as merge entries under self-merge, but SKILL.md step 7 files one. Either the prose or step 7 should change before Q-103 is answered.
- Decisions I made: read claim 5b's "such a branch is filed as stopped, not as a merge entry" as covering self-merge too, since it opens "Under both policies"; treated "every iteration" (claim 8) as accurate, because the skip rule applies only when nothing but chore lines landed; did not log claim 34 as a hallucination pattern (a Mostly accurate miscount, not a fabricated symbol).
