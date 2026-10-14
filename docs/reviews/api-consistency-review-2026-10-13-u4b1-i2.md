Commit: 0cd86cc0
# API Consistency Review — feat/build-loop-u4b1 (iteration 2)

**Scope:** full branch, `git diff main...HEAD` (HEAD 0cd86cc0): `skills/dev-cycle/SKILL.md`, `workflows/pr-prep.md` (quiesce line), `test/scripts/build-loop-orchestrator.bats` (git_harden pin), `docs/working/plan-build-loop-handoff.md` (split note). The consumer contract under review is SKILL.md's use of the scripts' interfaces (`scripts/build-loop.sh` header lines 1-522, `scripts/dev-cycle.sh` header, `test/lib/d6-snippet.bash` header); `scripts/` and `test/lib/` are unchanged on the branch.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i1.md`, `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i2.md` (claim 3c Incorrect is referenced, not re-verified)

## Baseline Conventions

- **Mode contracts live in script headers.** Each `build-loop.sh` mode documents its argument shape (`--main-log SINCE`, a full 40/64-hex id; `--land-cycle --main SHA`), its output lines (`main MAIN N`, `gate|chore|answers|other SHA SUBJECT`, `refuse main-log: WHY`, `refuse state WHAT: WHY`), and a shared Exit paragraph (0 / 2 / 1, plus "a caller reads any exit but 0 as nothing decided" for a part-way `--check`/`--merge`). The D6 snippet's header documents `refuse d6: WHY` on stdout with exit 2, exit 1 for a bad first argument, else the script's own status.
- **Placeholders are upper-case nouns** (`BRIEF`, `SHA`, `MAIN`, `TIP`, `DIR`, `W`, `STEM`, `DATE`), defined once in the header where they first appear.
- **Branch and path names:** `chore/dev-cycle-DATE` or `chore/dev-cycle-DATE-HHMM` (DATE YYYY-MM-DD) for `--main-log`'s chore class and `--land-cycle`; worktrees at `.claude/wt-STEM` in the main worktree (`--start`); records `docs/working/cycles/cycle-YYYY-MM-DD.md` (isrecord).
- **Hardened git** is spelled once per consumer that cannot source the lib: the snippet's `G=(env ... git -c ...)` array with a `g()` wrapper, pinned to `HARDEN` and `git_harden` by the bats test.
- **Settings keys** are exact line forms from `--settings`' header (`Build-loop policy:`, `Build-loop slots: N`, `Self-merge never: GLOB ...|none`, `Reader roots:`, `Reader homes:`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `chore/dev-cycle-DATE-HHMM` | branch name | `chore/dev-cycle-DATE[-HHMM]` (`--main-log` chore, `--land-cycle`), `chore/dev-cycle-<date>` (SKILL step 7) | `scripts/build-loop.sh:161-162, 245`; `skills/dev-cycle/SKILL.md:498` | Consistent with the scripts; inconsistent with step 7 in the same file (Finding 2) |
| `.claude/wt-dev-cycle-DATE-HHMM` | worktree path | `.claude/wt-STEM` (`--start` default), plan's `.claude/wt-dev-cycle-<date>-<HHMM>` | `scripts/build-loop.sh:463`; `docs/working/plan-build-loop-handoff.md:99` | Consistent; brief STEMs start with a date, so no collision |
| `MAIN` | placeholder | `main MAIN N` (`--main-log`), `--main SHA` (`--land-cycle`), plan's `MAIN_SHA` | `scripts/build-loop.sh:146-147, 246` | Consistent with the line it is read from |
| `SINCE` | placeholder | `--main-log SINCE` | `scripts/build-loop.sh:10, 141-145` | Consistent |
| `MAIN_WT` | placeholder | "the main worktree" (`--start`), `W` (`--merge`) | `scripts/build-loop.sh:428, 463-464` | Consistent (new name for an existing concept) |
| `WT` | placeholder | `W` (`--merge`'s worktree), `DIR` (`--start`) | `scripts/build-loop.sh:428, 463` | Consistent enough; distinct from `W`, which is the worktree holding main |
| `hg()` | shell function | snippet's `g()` / `G` | `test/lib/d6-snippet.bash:47-48` | Minor: shadows the Mercurial binary name; inline uses read as commands (Finding 6) |
| `bash -s <<'G'` | heredoc delimiter | `<<'D6'` | `test/lib/d6-snippet.bash:7-9` | Consistent (distinct delimiter; the snippet holds no line `G`) |
| `refuse d6: WHY` | output line | `refuse main-log: WHY`, `refuse state WHAT: WHY` | `test/lib/d6-snippet.bash:30-31`; `scripts/build-loop.sh:180, 292` | Consistent |
| `Build-loop slots:`, `Self-merge never:` | settings keys | `--settings`' line forms | `scripts/build-loop.sh:31-40` | Consistent; template values `3` and `none` are valid |
| `Main at:` | record line | `--main-log`'s "the last record's "Main at:" commit" | `scripts/build-loop.sh:142-143`; plan `:260, 326` | Consistent; the record template does not carry it yet (U4b2, known) |
| `dev-cycle-orchestrator/` | directory | none | none — searched `skills/`, `workflows/`, `scripts/` for an orchestrator temp-dir name | New convention (plan D13); no finding |
| "The D6 block" | section / term | "The D6 snippet" | `test/lib/d6-snippet.bash:2` | Consistent: the section names the file as its canonical copy |

## Findings

#### 1. The by-hand fallback names only the digest, while every `dev-cycle.sh` check mode now says "through the D6 block"

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:19-23`, `:42-47`, `:122-123`, `:227-229`
**Move:** 3 (consumer contract), internal consistency
**Confidence:** High
**Legibility-target:** for-author

Evidence: the fallback says "Run the cycle by hand instead: the digest as `~/.claude/scripts/dev-cycle.sh` ... no `build-loop.sh` call and no step that needs one, and the branch landed through `pr-prep`". The Rules say "Every `build-loop.sh` and `dev-cycle.sh` call runs from WT ... never `~/.claude/scripts/`", and the path rule says "only after `dev-cycle.sh --check-path '<path or glob>' …` (through the D6 block, run in WT) prints `ok <path>`".

An orchestrator following U4b1 now has an allowed form for the digest only. `--check-path`, `--check-write`, `--check-fix`, `--check-brief`, `--check-branch` and `--check-answer` are `dev-cycle.sh` calls that the Rules route through a block that does not exist, and the fallback does not say they run as `~/.claude/scripts/dev-cycle.sh` too. A literal reader either skips every path check (then by the path rule opens nothing) or runs them from the forbidden copy. The fallback is also silent on step 0: steps 0.1-0.2 need `build-loop.sh`, 0.3 needs the MAIN that 0.2 prints, and the old "Its own branch" rule that said where to commit is gone (Finding 2). So the by-hand run has no stated branch or worktree.

**Recommendation:** Make the fallback name every `dev-cycle.sh` mode ("every `dev-cycle.sh` call, digest and checks, as `~/.claude/scripts/dev-cycle.sh` ..."). Also say what replaces step 0.1-0.3 by hand, for example "a worktree from the default branch's tip on `chore/dev-cycle-DATE-HHMM`, hg as in the Rules". One sentence fixes it.

#### 2. Branch name: Rules and step 0 say `chore/dev-cycle-DATE-HHMM`; step 7 still lands `chore/dev-cycle-<date>`

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:38`, `:227`, `:498`
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `chore/dev-cycle-DATE` or `chore/dev-cycle-DATE-HHMM` (DATE YYYY-MM-DD) used in `scripts/build-loop.sh:161-162` and `:245`.

Evidence: Rules: "on its own branch `chore/dev-cycle-DATE-HHMM`". Step 7: "then land `chore/dev-cycle-<date>` on the default branch through `pr-prep`". Both shapes pass `--main-log`'s chore pattern, so the gate does not break. The file still names two branches for one iteration, and step 7's `<date>` placeholder style (lower-case, angle brackets) differs from the file's new `DATE-HHMM` style. Also, the Rules never define DATE: the header gives YYYY-MM-DD, and step 0.3 says UTC. The record is `cycle-YYYY-MM-DD.md` "for today" with no clock named. Near midnight, the branch's DATE and the record's date can differ. That is harmless to `--main-log`, which matches only `Branch: B`, but confusing to a reader.

**Recommendation:** U4b2 replaces step 7's name with `chore/dev-cycle-DATE-HHMM` and the land with `--land-cycle --main MAIN` (already planned). When it does, define DATE once (YYYY-MM-DD, UTC) and use the same clock for the record's date. Until then, Finding 1's fallback sentence can name the branch.

#### 3. A stop "quoted in the record" vs step 0's "ends the iteration with no record"

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:50-52`, `:206-207`, `:247-249`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence: Rules: "Each is a stop: the iteration ends there, with the line and stderr quoted in the record and in one `agent` entry". Step 0: "a stop below ends the iteration with no record, so the next one starts from the same `Main at:`". Digest failure: "file one `agent` entry with the error and write **no** cycle record".

All three of step 0's script calls (`--state`, `--main-log`, the digest) go through the D6 block, so a `refuse d6:` or a timeout there falls under both rules at once. One says write the record and the other says don't. Writing it would be the harmful reading: once U4b2's record carries `Main at:`, a record written on a stop moves SINCE. The routes also differ by cause (`refuse d6:` goes to `agent`, a `--state` refusal to `you: judgment`, and a `--main-log` refusal to `you: judgment`). That is defensible, but the Rules' sentence reads as covering every call.

**Recommendation:** In the Rules, say "quoted in the record (a stop in step 0: no record, the entry only)". Or have step 0 say its stops override the Rules' record clause. U4b2 should state the same for a stop after the record exists (steps 7-10).

#### 4. Exit taxonomy: "an exit the mode does not document" vs the header's "any exit but 0 as nothing decided" and the old check-mode rule

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:47-50`, `:163-164`, `:214`
**Move:** 4 (error consistency), 3 (contract)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: SKILL: "an exit the mode does not document, or a call the Bash tool timed out, means nothing was decided ... Each is a stop". The header (`scripts/build-loop.sh:516-519`) says: "A --check or --merge can also stop part way ... with 1 (need_root) or a failed command's own status: a caller reads any exit but 0 as nothing decided. 1 bad usage, ... not a git repo, ... a failed mktemp ... or no default branch found by name." The SKILL text that U4b1 kept says: "A check that exits non-zero (no default branch, say) is recorded, and the step that needed it stops."

Exit 1 is documented for every `build-loop.sh` mode, so under SKILL's wording a `--check`/`--merge`/`--land-cycle` exit 1 is not a stop. SKILL gives exit 1 a handling only for `--state` (`:214`). The header itself tells callers to read exit 1 from a part-way `--check`/`--merge` as undecided. For `dev-cycle.sh` check modes, two rules now apply. The old one stops the step. The new one stops the iteration, because a git failure's 128 is not a documented exit. For a writing mode (`--land-cycle`, `--start`), "documented" exit 1 still needs a reader who knows that no line was printed.

**Recommendation:** State the rule by status, not by documentation: 0 and the mode's documented 2 lines are decided, and any other status is a stop. Then delete or narrow `:163-164` to "a `dev-cycle.sh` check's documented exit 1 (no default branch): the step stops". U4b2's steps 7-10 can then cite one rule.

#### 5. `--state` is credited with refusing commit signing; its header lists `gpg.*`, not `commit.gpgSign`

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:65-68`
**Move:** 3 (contract drift between the skill and the header it cites)
**Confidence:** High (fact-check i2 claim 3c, executed)
**Legibility-target:** for-orchestrator-synthesis

Evidence: SKILL says "It does not switch off what the repository's own config can still name (a filter, a merge driver, commit signing): `--state` refuses those". The header (`scripts/build-loop.sh:274-277`) lists "a filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.*, log.showSignature ...". `commit.gpgSign` is not in that list, and fact-check i2 claim 3c executed it: `--state` prints `ok` and `hg commit` runs `gpg`. The skill promises a refusal that the contract it cites does not offer. This is the same defect as the fact-check's, seen from the interface side. The fix choice (harden hg and HARDEN, extend `STATE_KEYS_RE`, or narrow the text) belongs to the security reviewer. If the script changes, its header list must change with it, so that the skill keeps citing a documented behaviour.

**Recommendation:** Whichever fix is chosen, keep SKILL's parenthesis and the header's state-gate list naming the same keys. If hg gains `-c commit.gpgSign=false`, the pin test requires the lib's HARDEN and the snippet's G to gain it too.

#### 6. `hg` shadows the Mercurial command, and steps 0 and 1 write it inline as if it were a shell command

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:54-60`, `:216`, `:227`, `:268`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `g()` wrapping the `G=(env ... git ...)` array used in `test/lib/d6-snippet.bash:47-48`.

Evidence: "run in a `bash -s <<'G'` script that starts with this line, never as bare `git` in its shell". Inline uses: "read with `hg -C MAIN_WT show`", "`hg -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN`", "`hg -C MAIN_WT worktree list`". Inside a G script the function shadows any `hg` binary, so the Rule is safe as written. A step line quoted alone and run in the Bash tool would invoke Mercurial where it is installed, or fail with "command not found" where it is not. The fallback period makes this likelier, because the fallback does not say whether hg applies. The snippet's precedent `g` has no such collision. The pin test greps `'^  hg() { env '`, so a rename touches the test too.

**Recommendation:** Keep `hg` (the pin test is built on it) but add "(the function above, inside that script)" at the first inline use in step 0. Or rename it to something like `hgit`. That costs one test edit.

#### 7. Step 6 and the record template still hard-code 3 slots; the new settings line makes slots configurable

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:107`, `:448`, `:485`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author (U4b2)

Evidence: Settings: "**Build-loop slots** (live loops at once, 1-9; else 3: D9) ... read only through `build-loop.sh --settings`". Step 6: "while fewer than 3 briefs hold a slot". The record template has "`<k>/3 slots held (3/3: no new briefs)`". U4b2 owns step 6 and the record (plan's "free slots" item). This entry makes sure the reconcile covers the template line as well as step 6's sentence.

**Recommendation:** U4b2: replace both literal 3s with the `slots N` value `--settings` prints (and in the fallback, 3).

#### 8. The D6 snippet's header says to run from the orchestrator's own worktree; SKILL runs step 0's first two calls from MAIN_WT

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:42-43`; `test/lib/d6-snippet.bash:11`
**Move:** 3 (contract)
**Confidence:** High
**Legibility-target:** for-author (U4c)

Evidence: snippet: "Run it from the repository's checkout (the orchestrator's own worktree)." SKILL: "runs from WT (step 0's first two, from MAIN_WT)". Nothing breaks: the snippet finds the repository through `.git`, and a main checkout's `.git` is a directory. Still, the two texts name different checkouts, and U4c copies the snippet into SKILL byte for byte, header included.

**Recommendation:** U4c: change the snippet's comment to "a checkout of the repository (step 0's first two calls run from the main worktree, every other from the iteration's)", or say "a checkout".

#### 9. SINCE's read names no ref and no way to find "the newest record"

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:215-217`
**Move:** 3 (contract)
**Confidence:** Medium
**Legibility-target:** for-author (U4b2)

Evidence: "SINCE is the newest `Main at:` line of the newest record on the default branch (read with `hg -C MAIN_WT show`, never from a working tree)". `show` needs a `REF:PATH`. The default branch may be `master` (the snippet accepts either), and "newest record" needs a listing (`ls-tree` of `docs/working/cycles/` at that ref, ordered by the file name's date, as dev-cycle.sh's window reader does). The record template's `Main at:` line belongs to U4b2. This read is the consumer of that line, so the two should be written together.

**Recommendation:** U4b2: give the read as two hg commands (`ls-tree --name-only REF docs/working/cycles/`, then `show REF:PATH`, REF being the branch `--main-log`'s first line names), and say which `Main at:` line is newest (the last in the file).

#### 10. Quiesce wording: "this task" (pr-prep) vs "this iteration" / "this session" (SKILL); the pr-prep hazard sentence still implies a clean process table

**Severity:** Informational
**Location:** `workflows/pr-prep.md:333`; `skills/dev-cycle/SKILL.md:253-255`
**Move:** 2 (terminology), internal consistency
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: pr-prep says "Wait until no subagent this task started is still running; other sessions' agents and build loops share the uid and keep running (dev-cycle D14). Then reap leftover probe processes this task's agents started ... Stray processes are a real hazard here, because install.sh's no-agent guard (Q-058/Q-062) reads the real process table." SKILL says "no subagent this iteration started is still running ... only a process this session started is ever stopped".

The scopes differ: pr-prep says task, and SKILL says iteration for waiting and session for stopping. Plan D14 says "this task", and SKILL's "session" is wider than D14. That is safe in direction, but it is a third term. The kept hazard sentence explains why strays matter. After the change, it also implies that the gate can fail because of processes the reader is now told to leave alone. `test/install-host.bats` stubs `pgrep`, so the agent half of that guard is not affected. Whether a live loop's processes can reach the `/proc` half (Q-062, cwd in the checkout) was not established here.

**Recommendation:** Use D14's "this task" in SKILL step 1, or define iteration = task once. In pr-prep, optionally add "a failure traced to another session's process is triaged as pre-existing/flaky, not fixed by stopping it", so the hazard sentence and the new scope agree.

#### 11. Interim text U4b2 must reconcile: description, Flow and the land

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:4`, `:193-196`, `:471-499`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence: the frontmatter description still says "then hand build briefs for the top roadmap items to the user". The Flow still reads "0 digest → ... → 7 close (lands the branch)", while step 0 is now "Start and digest". Step 7 lands "through `pr-prep`", but the intro says the orchestrator "lands what `scripts/build-loop.sh` (the gate) allows". Under the fallback each of these is correct, and against the intro each is stale. This is the deliberate interim state, listed so U4b2's checklist names all three. One more contract point for U4b2: `--land-cycle` fast-forwards "in the worktree that has it checked out" (`scripts/build-loop.sh:256`), usually MAIN_WT, and `--merge`'s W rules refuse a tracked change there. So "MAIN_WT, which the cycle reads but never commits in" (`:210`) should say that the land moves MAIN_WT's checkout and refuses while the user has uncommitted tracked edits in it.

**Recommendation:** U4b2: update the description and Flow, replace step 7's land, and state the MAIN_WT dirty-checkout refusal next to `--land-cycle`.

## What Looks Good

- The call form `bash -s -- SCRIPT ARG... <<'D6'` and "Arguments: `build-loop.sh` or `dev-cycle.sh`, then that script's own" match the snippet header (`test/lib/d6-snippet.bash:7-9, 29`) exactly, and `refuse d6: WHY` (stdout, exit 2, nothing run) matches its Exit line.
- Step 0.2 reads `--main-log` by its documented shapes: first line `main MAIN N`, later lines by position with SUBJECT as data, the bootstrap's `main MAIN -` plus refusal, and the three refusal causes. These match `scripts/build-loop.sh:141-183` and the code's three `refuse main-log:` messages (`:1802-1808`). The 40-zeros bootstrap passes the usage regex (`:545`).
- Step 0.1's `--state` handling (ok / refuse lines with exit 2 / exit 1 with stderr) matches the header's three outcomes, and "a caller's config pair for a `HARDEN` key" matches `:133-139`.
- The settings bullets restate `--settings`' line forms faithfully (slots 1-9 else 3; never globs or `none`; a malformed never line turns self-merge off; Reader roots/homes optional), and the template's two new lines are valid values.
- The `--check-fix` re-run paragraph agrees with `--cycle-diff`'s own "wider than --check-fix, whose other refusals the rules here repeat only in part" (`:219-220`).
- The drift check names the `--merge` commit by its documented trailer `Build-loop-gate:` and the research doc by the N/S rules' own-file pattern `docs/working/research-STEM.md`.
- The pin test now holds SKILL's `hg` line and the snippet's `G` to the same HARDEN and git_harden lists, and asserts exactly one `hg()` line. That is the right guard for a hand-copied contract.
- The health check's lock wait matches `take_lock` (`scripts/health-check.sh:1104-1116`: a flock on `health-check.lock` in the common dir, one "waiting for another health check" line).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Fallback names only the digest; check modes say "through the D6 block"; no by-hand branch/worktree | Inconsistent | `SKILL.md:19-23, 122-123` | High |
| 3 | Stop "quoted in the record" vs step 0 "no record" | Inconsistent | `SKILL.md:50-52, 206-207, 247-249` | High |
| 5 | `--state` credited with refusing commit signing; header lists `gpg.*` only | Inconsistent | `SKILL.md:65-68` | High |
| 4 | "Undocumented exit" rule vs header's "any exit but 0" and the old check-mode rule | Inconsistent | `SKILL.md:47-50, 163-164` | Medium |
| 2 | `chore/dev-cycle-DATE-HHMM` vs step 7's `chore/dev-cycle-<date>`; DATE's clock undefined | Minor | `SKILL.md:38, 227, 498` | High |
| 7 | Hard-coded 3 slots vs `Build-loop slots:` | Minor | `SKILL.md:448, 485` | High |
| 6 | `hg` shadows Mercurial; inline uses outside the G script | Minor | `SKILL.md:60, 216, 227, 268` | Medium |
| 8 | Snippet header's "own worktree" vs step 0's MAIN_WT calls | Informational | `d6-snippet.bash:11` | High |
| 11 | Description, Flow, step 7 land, MAIN_WT dirty-checkout refusal (U4b2) | Informational | `SKILL.md:4, 193-196, 471-499` | High |
| 9 | SINCE read: no ref, no listing for "newest record" | Informational | `SKILL.md:215-217` | Medium |
| 10 | task / iteration / session quiesce terms; pr-prep hazard sentence | Informational | `pr-prep.md:333`, `SKILL.md:253-255` | Medium |

## Overall Assessment

SKILL.md's new text follows the scripts' contracts closely. Mode names, argument shapes, output lines, the bootstrap, the `refuse d6:` line and the settings keys match the headers, and the pin test is a good guard for the one hand-copied list. The inconsistencies are inside the skill, and they matter because U4b1 is a partial rewrite that an orchestrator may follow now.

The by-hand fallback covers only the digest. Findings 1 and 2 leave the check modes, the branch and the worktree without an allowed form. Two stop rules disagree on whether a record is written (Finding 3). The exit rule's "documented vs undocumented" split leaves exit 1 unhandled outside `--state`, against the header's own reading (Finding 4). The `--state` coverage claim for commit signing exceeds the header (Finding 5, already Incorrect in fact-check i2). Findings 1, 3 and 4 are each a one- or two-sentence fix in place and do not need U4b2. Findings 2, 7, 9 and 11 are U4b2's reconcile list. The consumer impact is behavioural rather than cosmetic: an orchestrator reading the fallback literally either opens no repo-named path or runs the forbidden copy.

## Goal-Alignment Note

The goal is landing U4b1 after a clean loop, with SKILL.md as instructions an orchestrator executes. Nothing here blocks the script contract. Every mode U4b1 names is used as its header defines it. The loop should still fix Findings 1, 3 and 4 before landing, because they are the places where U4b1's own text, followed today under the fallback, sends the reader to a command it may not run or a record it must not write. Finding 5 rides on the security reviewer's choice for fact-check claim 3c. Findings 2, 7, 9 and 11 are correctly deferred to U4b2 by the plan's split note and are listed here so its brief names them. Findings 6, 8 and 10 are optional wording.
