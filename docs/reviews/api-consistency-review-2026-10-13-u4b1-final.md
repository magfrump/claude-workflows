Commit: ea59b0c3
# API Consistency Review: feat/build-loop-u4b1 (final confirming pass)

**Scope:** the full branch, `git diff main...HEAD` at ea59b0c3. Changed: `skills/dev-cycle/SKILL.md`, `workflows/pr-prep.md` (the quiesce line), `scripts/lib/dev-cycle-read.sh` (HARDEN gains `commit.gpgSign=false`), `test/lib/d6-snippet.bash` (the same pair in G), `scripts/build-loop.sh` (the header's HARDEN list), `test/scripts/build-loop-orchestrator.bats` (the git_harden pin now covers SKILL.md's `hg`), and `docs/`. The consumer contract under review is how SKILL.md uses the scripts' interfaces: the `build-loop.sh` header (lines 1-522, including the Exit paragraph at 511-522), the `dev-cycle.sh` header's Exit paragraph (87-90), the D6 snippet header (1-40), and `health-check.sh`'s `take_lock` (1104-1117).
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b1-final-r{1,2,3}.md` (at 4c911717) and the iteration-2 API report `docs/reviews/api-consistency-review-2026-10-13-u4b1-i2.md`. The fact-check's verified behaviour is referenced here, not re-verified.

## Iteration-2 items 1-4: confirmed fixed

| i2 # | Status at ea59b0c3 | Evidence |
|---|---|---|
| 1 Fallback covered only the digest | **Fixed** | `SKILL.md:19-28`: "every `dev-cycle.sh` call (the digest and every check mode) as `~/.claude/scripts/dev-cycle.sh` ... WT made as step 0.3 says, from the default branch's commit (`hg -C MAIN_WT rev-parse --verify refs/heads/main`, or master); the Rules' `hg` for every git command". The branch name comes from the Rules (`:43`), and the remaining gap is named (`:25-28`). |
| 2 Branch name `DATE-HHMM` vs step 7's `<date>` | Settled (U4b2 override row) | Not re-flagged. |
| 3 A stop was "quoted in the record" vs "no record" | **Fixed** | `SKILL.md:58-61`: "Each stop ends the iteration there, with no record (its `Main at:` would move the next SINCE): the line and stderr go in one `agent` entry and the final message". This agrees with step 0's intro (`:216-217`) and the digest-failure rule (`:259-261`). |
| 4 Exit taxonomy was "documented vs undocumented" | **Fixed** | `SKILL.md:54-58`: "A `build-loop.sh` answer is exit 0, or exit 2 with the lines its mode documents for it (refuse lines, `--main-log`'s `other` lines, `--check`'s verdict lines); any other exit (1 included) ... means nothing was decided". This matches the header's Exit paragraph (`build-loop.sh:511-522`): 2 for "any other --check, --merge, --start or --prompt verdict line, --main-log's other or refuse line, a --cycle-diff refuse line, or the state gate", and "a caller reads any exit but 0 as nothing decided" for a part-way `--check`/`--merge`. `--land-cycle`'s own text (`:264`) documents "refuse lines and exit 2". The check modes keep their own rule (`:173-174`), and `dev-cycle.sh:87-90` documents exit 0 with skips as answers. |
| 5 `--state` credited with refusing commit signing | **Fixed** | `hg` now carries `-c commit.gpgSign=false`. The prose (`:72-76`) moves commit signing to what `hg` switches off, and names "signature verification on a merge" as `--state`'s (the header's state gate refuses a "merge or diff setting", `build-loop.sh:276`). |

The HARDEN pair's documented copies agree everywhere. These are the lib's `HARDEN` (`dev-cycle-read.sh:354`) and its comment (`:341-343`), the snippet's `G` (`d6-snippet.bash:45`), SKILL.md's `hg` (`:69`) and `build-loop.sh`'s `--state` header (`:136-138`). A repo-wide search for `multiPackIndex` outside `docs/reviews/` finds no other hand copy of the list. `caller_gate` iterates `HARDEN` (`build-loop.sh:668`), so a caller pair for `commit.gpgSign` is now refused automatically, which matches SKILL's "Never export these settings ... (`--state` refuses a caller's config pair for a `HARDEN` key, row 702)". I ran the pin test and it passes (`TMPDIR=… bats -f 'git_harden exports'`: ok 1). In a temp copy, I removed `-c commit.gpgSign=false` from SKILL's `hg` line, and the test then fails at line 369 on the `-c` list comparison, so the pin is live.

## Baseline Conventions

These are unchanged from i2: mode contracts live in script headers, placeholders are upper-case nouns, settings keys use exact line forms, and hardened git is spelled once per consumer that cannot source the lib and is pinned by the bats test. Neither naming finding below is new: `hg` and the quiesce terms are settled Won't-Fix rows.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `commit.gpgSign=false` | HARDEN pair | `log.showSignature=false` (the gpg route HARDEN already shuts) | `scripts/lib/dev-cycle-read.sh:354` | Consistent. Spelled in git's canonical camelCase like its siblings, and `caller_gate` compares lower-cased. |
| `PGID`, `LOG` | placeholders | `PID` (pr-prep, step 1), `BRIEF`, `SHA` | `scripts/build-loop.sh:6-16` | Consistent: upper-case nouns |
| `GIT_AUTHOR_NAME` … `GIT_COMMITTER_EMAIL` | env per command | `--merge`'s identity source | `scripts/build-loop.sh:418-421` | Consistent: the same four variables `--merge` reads first |

## Findings

#### 1. "Stop" names three different things, and `refuse d6:` on a `build-loop.sh` call lost its explicit "is a stop"

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:53-61`, `:219-224`, `:173-174`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence, Rules: "Read a call's first line before its mode's output: `refuse d6: WHY` (exit 2) means nothing ran. A `build-loop.sh` answer is exit 0, or exit 2 with the lines its mode documents for it ...; any other exit (1 included), or a call the Bash tool timed out, means nothing was decided ... Each stop ends the iteration there, with no record ...: the line and stderr go in one `agent` entry and the final message". Step 0.1: "refuse lines (planted `.git` state ...) are a stop, quoted in one `you: judgment` entry unless an open one quotes the same lines. Any other exit is a stop as the Rules say." Paths rule: "A check that exits non-zero (no default branch, say) is recorded, and the step that needed it stops."

The i2 text said "Each is a stop" right after listing `refuse d6:`, the undocumented exit and the timeout. ea59b0c3 rewrote that list into an answer definition, and "Each stop" now has as its only antecedent "any other exit ... or a call the Bash tool timed out". A `refuse d6:` line exits 2, so a literal reader cannot tell whether it is "another exit". The sentence says only that nothing ran, not where the line goes. In practice the orchestrator stops anyway, because it has no mode output. The route is the open question: is it an `agent` entry plus the final message, or nothing?

Second, step 0.1 calls a `--state` refusal "a stop". By the Rules' definition, that refusal is an answer (exit 2 with the mode's refuse lines), and step 0.1 routes it to `you: judgment`. The Rules' "Each stop ... one `agent` entry and the final message" can be read to cover it too, which gives two entries for one refusal. Step 0.1 does not say whether the final message names it. ea59b0c3's commit body says it made "one stop route" for `--state`'s exit 1, and that part holds. The word "stop" still carries two routes, though.

Third, the paths rule covers a check mode that "exits non-zero". A `dev-cycle.sh` check call that the Bash tool timed out has no exit, so it falls under neither rule.

**Recommendation:** One sentence in the Rules: "`refuse d6:` on any call, an exit that is not an answer, and a timed-out call are stops. Each stop ends the iteration ... (`dev-cycle.sh`'s check modes: the paths rule, a timeout counting as a non-zero exit)." In step 0.1, either say "end the iteration as a stop does, but the entry is `you: judgment`, not `agent`", or reword it to "end the iteration (no record)". That keeps "stop" for one route.

#### 2. Step 1's health-check line has no backgrounding and no source for PID

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:267-275`
**Move:** 3 (consumer contract: a command the skill names)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: "run the repo's health check from WT ... to a file, in the background as its own process group (`setsid scripts/health-check.sh > LOG 2>&1`) ... the run's whole process group is stopped (`kill -- -PGID`, PGID from `ps -o pgid= -p PID`...)".

The prose says "in the background", but the quoted command has no `&` and does not say where PID comes from. Pasted as written into the Bash tool, the command runs in the foreground. The tool's 10-minute cap then kills it long before the hour bound, and the Rules treat a timed-out call as a stop. I checked the intended form: `setsid CMD > LOG 2>&1 & p=$!` gives a process that is its own group leader (PID = PGID = SID), and `kill -- -$(ps -o pgid= -p $p)` stops it. So the mechanism the fact-check verified works, but only when the reader supplies `&` and `$!` themselves.

**Recommendation:** Write the command as `cd WT && setsid scripts/health-check.sh > LOG 2>&1 & echo $!` (or name the Bash tool's background run), and say "PID: the number it prints". Under setsid the PGID equals that PID, so the `ps` read is a check, not a requirement.

#### 3. "Run `--state` again right before the iteration's commits" does not say once or per commit

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:76-79`, `:294`
**Move:** 3 (contract timing)
**Confidence:** Medium
**Legibility-target:** for-author (U4b2)

Evidence: "`--state` refuses those, but only when it runs, so run it again (through the D6 block, from WT) right before the iteration's commits, and treat a refusal there as step 0 does." Step 1: "Fix what is mechanical now, one commit per concern." Steps 3 and 4 also commit in-cycle, and step 9 (U4b2) makes the chore commit and the merge of main into WT.

The iteration commits at several points. "Right before the iteration's commits" can mean one run before the first commit or one run before each commit script. The residual named next ("a loop that plants one between that check and the commit") depends on which reading is meant. This is not a contract break. U4b2's step 9 is the natural place to fix it.

**Recommendation:** Say "before each `hg` script that commits or merges", or "before step 1's first commit and again before step 9's", and have U4b2's step 9 cite it.

## Remaining i2 items (not re-flagged)

- 6 (`hg` shadows Mercurial) and 10 (task / iteration / session): settled Won't-Fix rows.
- 2, 7, 9, 11: in the U4b2 checklist row.
- 8 (the snippet header says "the orchestrator's own worktree" while step 0's first two calls run from MAIN_WT): unchanged, and still U4c's, because the header is copied byte for byte when the block lands. Nothing breaks: the snippet finds the repository through `.git`.

## What Looks Good

- The answer definition now matches `build-loop.sh`'s Exit paragraph mode by mode (`--main-log`'s `other` and refuse lines at exit 2, `--check`'s mixed verdicts at exit 2, part-way exit 1 as undecided). Step 0.2's handling of `other` (block dispatch, continue the iteration) follows from it.
- The identity recipe uses the same four variables `--merge` reads first (`build-loop.sh:418-421`). Values are read in-script and never pasted, and `--state`'s caller gate cannot trip on them (they are environment variables, not config pairs).
- The fallback is now complete for the by-hand mode. It covers every `dev-cycle.sh` call, WT from main's commit through `hg`, `hg` for all git, and pr-prep for the land, and it states its gap in `--state`'s own terms.
- The `--check-fix` paragraph's list of what passes `--cycle-diff` but not `--check-fix` agrees with `--cycle-diff`'s header ("wider than --check-fix, whose other refusals the rules here repeat only in part", `build-loop.sh:220-221`).
- pr-prep's quiesce line and SKILL step 1 now use the same rule: stop by PID (or process group), never by pattern.
- Commit messages agree with the diff. ea59b0c3's note correctly explains 4c911717's "count 10" (GIT_CONFIG_COUNT, 1 caller + 9 HARDEN).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | "Stop" covers three routes; `refuse d6:` on build-loop.sh no longer explicitly a stop; a check call's timeout unrouted | Inconsistent | `SKILL.md:53-61, 219-224, 173-174` | Medium |
| 2 | Health-check command lacks `&` and a PID source; a literal paste times out in the Bash tool | Minor | `SKILL.md:267-275` | Medium |
| 3 | `--state` re-run "before the iteration's commits": once or each | Informational | `SKILL.md:76-79` | Medium |

## Overall Assessment

Items 1, 3, 4 and 5 from iteration 2 are fixed, and the fixes hold against the headers they cite. The HARDEN change is consistent across all four documented copies. The pin test enforces it, and I confirmed that with a mutant. SKILL.md's use of each mode's names, argument shapes, output lines and exit codes matches the script headers. What remains is wording in the stop routing (Finding 1): ea59b0c3's rewrite dropped the explicit classification of `refuse d6:`, and "stop" names both an `agent`-entry route and step 0.1's `you: judgment` route. An orchestrator still stops in every case, so no case leads to proceeding on undecided output. The open question is only which entry gets filed. Finding 2 is a quoted command that does not do what its sentence says when pasted.

## Goal-Alignment Note

The goal is to land U4b1 after a clean loop, with SKILL.md as instructions an orchestrator executes. None of these findings lets an orchestrator act on an undecided gate answer, run a forbidden script copy, or write a record after a stop. The contract-level defects from i2 are closed. Finding 1 is a one-sentence fix in the Rules plus a few words in step 0.1, worth doing before landing because U4b2's steps 7-10 will cite "a stop" and inherit any ambiguity. Finding 2 is a one-line command edit. Finding 3 can ride with U4b2's step 9. None of them blocks the merge on API-consistency grounds if the loop prefers to file them as override rows.
