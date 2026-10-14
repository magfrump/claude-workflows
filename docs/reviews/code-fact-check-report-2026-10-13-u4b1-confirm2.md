Commit: c67ffd62

# Code Fact-Check Report

**Replication:** k=1 (confirming pass)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u4b1, branch feat/build-loop-u4b1)
**Scope:** `git diff 923f7d26..c67ffd62 -- scripts skills test` (scripts/health-check.sh, skills/dev-cycle/SKILL.md) plus c67ffd62's commit message; the brief's four priority claims first
**Checked:** 2026-10-13
**Total claims checked:** 12
**Summary:** 9 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Probe scripts and captured output live in the session scratchpad,
`/tmp/claude-1000/-workspace/5f7c1a26-c882-447d-bbc1-af5199ac916b/scratchpad/fcc2/` (`pN.sh` / `pN.out`; `$S` below).
Every probe made its own `mktemp -d /tmp/u4b1-fcc2-XXXX`, refused git writes outside it, and removed it by
exact name; no process was left running (checked with `ps`). git 2.39.5, util-linux flock 2.38.1.
`docs/reviews/hallucination-patterns.md` read; no logged pattern matches a claim below.

Extra per-claim fields asked for by the brief: **Severity** (for non-Verified claims: how much a reader acting on
the text is misled) and **Legibility-target** (who reads and acts on the text).

---

## Claim 1: "Seconds to wait for another run's lock (plain decimal, at most 7 digits; 0: no wait); past it the run exits 75, having run nothing"

**Location:** `scripts/health-check.sh:32-36`, `scripts/health-check.sh:1118-1120`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex gate (8 digits refused, 7 digits accepted with leading zeros as decimal), the `0` edge and the 75 path against a held lock, run with the c67ffd62 copy of the script in a throwaway clone; does not establish a full 9999999 s wait (not run) or the payload-exits-75 case (override row E6).
**Severity:** none
**Legibility-target:** the orchestrator session setting `HEALTH_CHECK_LOCK_WAIT` (SKILL step 1) and any caller of health-check.sh

Code: `[[ "$HEALTH_CHECK_LOCK_WAIT" =~ ^[0123456789]{1,7}$ ]] || { red "HEALTH_CHECK_LOCK_WAIT is not a plain number of seconds (at most 7 digits)"; exit 1; }` then `w=(-w "$HEALTH_CHECK_LOCK_WAIT")` (`scripts/health-check.sh:1118-1120`), and the bounded `flock "${w[@]}" -E 75 -o "$lk" …`, with the "gave up waiting" message on 75 and `exit "$rc"` (`scripts/health-check.sh:1123-1129`; whole `take_lock`, :1109-1130, read).

Executed (`bash $S/p2.sh`, cwd `/tmp/u4b1-fcc2-tg6P` then its clone `r` at c67ffd62, script exit 0, 2026-10-13T23:16:38Z, lock held 6 s by `flock … sleep 6`): `WAIT=12345678` → rc=1 in 16 ms with "HEALTH_CHECK_LOCK_WAIT is not a plain number of seconds (at most 7 digits)"; `WAIT=0000001` → rc=75 after 1024 ms, "gave up waiting for health-check.lock after 0000001s: nothing was checked"; `WAIT=0` → rc=75 in 34 ms, same message. The bats suite's test 3 also passes (Claim 10).

**Evidence:** `scripts/health-check.sh:32-36`, `scripts/health-check.sh:1109-1130`, `$S/p2.sh`, `$S/p2.out`

---

## Claim 2: "filed once: in the `you: judgment` entry the step names, if it names one (step 0's `--state` refusals and its lost `Main at:` line; `--main-log`'s `other` lines block dispatch but are no stop)"

**Location:** `skills/dev-cycle/SKILL.md:59-64`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the Rules' stop paragraph and steps 0.1 and 0.2 (each named stop has one judgment entry; `other` lines block dispatch only); does not establish where a non-bootstrap `refuse main-log:` line sits in the Rules (the parenthetical names only `other` lines; it is an answer under the Rules' "exit 2 with the lines its mode documents" sentence, and step 0.2 routes it like `other`), nor any step after 0.
**Severity:** none
**Legibility-target:** the orchestrator session deciding stop vs. continue

Step 0.1: "refuse lines … are a stop, quoted in one `you: judgment` entry unless an open one quotes the same lines. Any other exit is a stop as the Rules say." (`skills/dev-cycle/SKILL.md:229-232`). Step 0.2: "Otherwise a newest record without the line is a stop, with one `you: judgment` entry" (`:240-241`) and "Any `other` line, or a `refuse main-log:` line other than the bootstrap's own (…), blocks this iteration's dispatch and gets one `you: judgment` entry … unless an open one does" (`:247-251`). The Rules' general answer/stop split: "A `build-loop.sh` answer is exit 0, or exit 2 with the lines its mode documents for it (refuse lines, `--main-log`'s `other` lines, `--check`'s verdict lines)" (`:51-53`). The three routes agree; the stop route is stated once in the Rules and each step names only its own entry.

**Evidence:** `skills/dev-cycle/SKILL.md:51-66`, `skills/dev-cycle/SKILL.md:226-251`

---

## Claim 3: "A stop after step 0.3 removes WT as step 0.3 does (with `--force`, which discards WT's uncommitted edits; its branch stays)"

**Location:** `skills/dev-cycle/SKILL.md:64-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `worktree remove --force` under the skill's `hg` on a clean and on a modified worktree (both removed, branch kept, modification gone with the directory); does not establish removal of a locked worktree (refused, Claim 7) or what the skill does when the removal itself fails.
**Severity:** none
**Legibility-target:** the orchestrator session on a stop path

Executed (`bash $S/p3.sh`, cwd `/tmp/u4b1-fcc2-OjW1`, exit 0, 2026-10-13T23:17:08Z): `force-clean: rc=0 … wt_exists=n branch=kept`, `force-modified: rc=0 … wt_exists=n branch=kept`. The step-0.3 command it points to is `hg -C MAIN_WT worktree remove --force WT` (`skills/dev-cycle/SKILL.md:254`); grep finds no other removal in `skills/` or `workflows/` (`SKILL.md:64`, `:254` only).

**Evidence:** `skills/dev-cycle/SKILL.md:64-65`, `skills/dev-cycle/SKILL.md:254`, `$S/p3.sh`, `$S/p3.out`

---

## Claim 4: "`hg` … a test holds its pairs to the lib's `HARDEN` list" (the hg line now carries `-c commit.gpgSign=false`)

**Location:** `skills/dev-cycle/SKILL.md:75-80`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hg line's config pairs equalling `HARDEN` (including `commit.gpgSign=false`) as the bats test asserts; context outside the fix range, checked because the range's text depends on it; does not establish that `hg` disables repository-named drivers (it does not, as the skill says; Claim 6c).
**Severity:** none
**Legibility-target:** the orchestrator session; future editors of HARDEN

`HARDEN=(core.useReplaceRefs=false … log.showSignature=false commit.gpgSign=false)` (`scripts/lib/dev-cycle-read.sh:354`); the hg line ends `-c log.showSignature=false -c commit.gpgSign=false "$@"; }` (`skills/dev-cycle/SKILL.md:75`); the test greps exactly one `^  hg() { env .* "\$@"; }$` line and compares its pairs (`test/scripts/build-loop-orchestrator.bats:367-368`, test from :355). Executed: `TMPDIR=<mktemp> bats -f 'harden' test/scripts/build-loop-orchestrator.bats`, cwd the worktree, exit 0, 2026-10-13T23:19:55Z: `ok 2 git_harden exports HARDEN's pairs … SKILL.md's hg carry the same`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `skills/dev-cycle/SKILL.md:75`, `test/scripts/build-loop-orchestrator.bats:355-372`, `$S/bats-harden.out`

---

## Claim 5: "the newest record on the default branch (`docs/working/cycles/cycle-YYYY-MM-DD.md`, the latest date: listed with `hg -C MAIN_WT ls-tree` and read with `hg -C MAIN_WT show`, never from a working tree)"

**Location:** `skills/dev-cycle/SKILL.md:234-237`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the name shape against the lib's `isrecord` and the date ordering against dev-cycle.sh's window reader; does not establish the record's `Main at:` line format or which of several same-day lines is "newest" (both U4b2's step 9, not yet written).
**Severity:** Low
**Legibility-target:** the orchestrator session computing SINCE

The name shape matches the lib: `isrecord() { [[ "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]]; }` (`scripts/lib/dev-cycle-read.sh:246`). dev-cycle.sh's window reader, which picks the record the digest calls the last cycle, also skips what is not a plain file, a name that is not a real date, and a future date: `if ! rawfile "$f"; then … continue`, `date -d "$d" >/dev/null 2>&1 || continue  # a name that is not a real date`, `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated` (`scripts/dev-cycle.sh:225-235`, loop :223-238 read). `--main-log`'s chore class also requires mode 100644 (`scripts/build-loop.sh:1746`). The skill's "the latest date" has none of these exclusions, so a committed `cycle-2099-01-01.md`, `cycle-2026-13-45.md`, or a symlink (mode 120000, which `show` prints as its target text) would be step 0.2's "newest record" while the digest reads an older one. Precise version: "the latest real, not-future date among mode-100644 entries named cycle-YYYY-MM-DD.md".

**Evidence:** `skills/dev-cycle/SKILL.md:234-237`, `scripts/lib/dev-cycle-read.sh:246`, `scripts/dev-cycle.sh:223-238`, `scripts/build-loop.sh:1746`

---

## Claim 6a: "Only when main's history never held a `Main at:` line in a record (`hg -C MAIN_WT log -1 --format=%H -G'^Main at: ' MAIN0 -- docs/working/cycles/` prints nothing …), pass 40 zeros" (the never-held direction)

**Location:** `skills/dev-cycle/SKILL.md:237-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers: no records → empty; records without the line → empty; a line added on a chore branch and merged with `--no-ff` → found; a later record lacking the line → still found; a record moved out of the directory (rename) → found; the literal pathspec under `GIT_LITERAL_PATHSPECS=1` matching the directory; does not establish the converse for history reached only through a simplified merge (Claim 6b).
**Severity:** none
**Legibility-target:** the orchestrator session at step 0.2

Executed (`bash $S/p4.sh`, cwd `/tmp/u4b1-fcc2-dxAl/r`, exit 0, 2026-10-13T23:17:59Z), the skill's command under the skill's `hg`: `[a: no records] log -G: ''`, `[b: record without line] log -G: ''`, `[c: line added on chore branch, merged] log -G: '01fb7822…'`, `[d: newer record lacks line] log -G: '01fb7822…'`, `[e: record moved out (rename)] log -G: '37d624f2…'` (the move commit: the pathspec-limited diff sees a deletion).

**Evidence:** `skills/dev-cycle/SKILL.md:237-243`, `$S/p4.sh`, `$S/p4.out`

---

## Claim 6b: "Otherwise a newest record without the line is a stop" / commit message "E2: bootstrap only when main's history never held a Main at: line in a record (git log -G); otherwise a newest record without one is a stop"

**Location:** `skills/dev-cycle/SKILL.md:237-243`; c67ffd62 commit message, E2 bullet
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one commit on main, a two-parent merge whose `docs/working/cycles/` equals its second parent's, which makes the guard print nothing although main's history held the line, so a newest record without the line bootstraps instead of stopping; does not establish how such a merge reaches main (the Q-140 gap: a loop that moves main) or whether `--main-log` would have classed it `other` (bootstrap skips that read).
**Severity:** Medium (same consequence as E2: bootstrapping skips the check of what moved main, here the very merge that did it)
**Legibility-target:** the orchestrator session at step 0.2; the user reading E2 as closed

`git log` with a pathspec applies default history simplification: at a merge TREESAME to one parent for the path, it follows only that parent, and it shows no diff for merges. Executed (`bash $S/p5.sh`, cwd `/tmp/u4b1-fcc2-s6YW/r`, exit 0, 2026-10-13T23:18:26Z): main = root, then a `--no-ff` chore merge adding `cycle-2026-10-02.md` with `Main at: <root>`, then one merge (main first parent, an unrelated `side` commit second) whose cycles directory is taken from `side`, holding only `cycle-2026-10-09.md` without the line. Output: `records on main: docs/working/cycles/cycle-2026-10-09.md`, `newest record holds Main at: 0`, `skill's command: ''`. The same tree with the lib's own flags finds the merge: `lib-style (--first-parent --diff-merges=first-parent --no-textconv): '35b4cbd6…'` (= the merge, its first-parent diff deleting the old record's `-Main at: …` line); `--full-history` also prints a SHA (`06d922d2…`). `$S/p4.out` case f shows the same with the whole directory dropped (`''`, and `'01fb7822…'` with `--full-history`). Prior art in the repo uses the first-parent form for exactly this kind of read: `c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv --no-show-signature --no-follow -G'^Status: ' "$MAIN_SHA" -- "$a")"` (`scripts/lib/dev-cycle-read.sh:508`, comment from :504). Precise fix the text needs: add `--first-parent --diff-merges=first-parent -s` (and `--no-textconv`, Claim 6c) so a merge that drops the line on main's first-parent line is itself a match.

**Evidence:** `skills/dev-cycle/SKILL.md:237-243`, `scripts/lib/dev-cycle-read.sh:504-508`, `$S/p5.sh`, `$S/p5.out`, `$S/p4.out`

---

## Claim 6c: "`hg` … does not switch off what the repository's own config can still name (a filter, a merge driver, signature verification on a merge): `--state` refuses those, but only when it runs" (applied to step 0.2's `hg … log -G`)

**Location:** `skills/dev-cycle/SKILL.md:78-81`, `skills/dev-cycle/SKILL.md:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that step 0.2's `log -G` under `hg` runs a `diff.<d>.textconv` command planted in `.git/config` with an `info/attributes` line (so the skill's "does not switch off" holds) and that `--state` lists `diff.*` keys and `info/attributes`; does not establish the window between step 0.1's `--state` and 0.2's `log` (a snapshot, as the skill says), nor a planted `.gitattributes` in MAIN_WT's working tree combined with a driver key added after `--state`.
**Severity:** none for the text; Low residue (the lib's own `-G` read passes `--no-textconv`; the skill's command does not)
**Legibility-target:** the orchestrator session; the security reviewer

Executed (`$S/p4.sh` case g, same run as 6a): `git config diff.ev.textconv "sh -c 'echo ran >> …/TEXTCONV; cat …'"` and `*.md diff=ev` in `.git/info/attributes`, then the skill's command → `textconv ran: 1`. `--state`'s gate: "filter drivers, every merge.* and diff.* key (drivers run commands)" and "Files: an info/attributes," (`scripts/build-loop.sh:602-605`), checked in a loop over `info/attributes info/grafts shallow objects/info/alternates` (`:622`).

**Evidence:** `skills/dev-cycle/SKILL.md:78-81`, `skills/dev-cycle/SKILL.md:238`, `scripts/build-loop.sh:602-622`, `scripts/lib/dev-cycle-read.sh:504-508`, `$S/p4.out`

---

## Claim 7: "`--force` skips the clean check, whose status run would execute a filter planted in the repository's config"

**Location:** `skills/dev-cycle/SKILL.md:254-257`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers clean and modified worktrees with a clean filter planted in `.git/config` + `info/attributes`, removed under the skill's `hg`, and a worktree holding an uninitialized or (attempted) initialized submodule; does not establish a locked worktree (refused even with one `--force`) or other repo-named commands that `worktree remove --force` might reach (none seen).
**Severity:** none
**Legibility-target:** the orchestrator session at step 0.3 and on stop paths

Executed (`$S/p3.sh`, run as Claim 3): without `--force`, `plain-clean: rc=0 filter_ran=1` (the filter ran) and `plain-modified: rc=128 … contains modified or untracked files, use --force to delete it`; with `--force`, `force-clean: rc=0 filter_ran=0` and `force-modified: rc=0 filter_ran=0 wt_exists=n`. What it still refuses: `locked --force: rc=128 … cannot remove a locked working tree; use 'remove -f -f' to override or unlock first`. Submodules do not block it: `submodule-uninit --force: rc=0 wt_exists=n`, `submodule-init --force: rc=0 wt_exists=n` (the init step's stderr was discarded, so the initialized case is attempted, not confirmed). The orchestrator never locks its own WT, so a lock there means another same-uid process locked it; the removal then fails with 128 and leaves WT registered (paraphrased — no quote available because the claim is about the absence of any lock step for WT in the skill; grep of `skills/dev-cycle/SKILL.md` finds `worktree lock` nowhere).

**Evidence:** `skills/dev-cycle/SKILL.md:252-257`, `$S/p3.sh`, `$S/p3.out`

---

## Claim 8: "E5: HEALTH_CHECK_LOCK_WAIT takes at most 7 digits (flock's timer)"

**Location:** c67ffd62 commit message, E5 bullet
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 7-digit cap (Claim 1) and where flock's timer actually stops working; does not establish flock behaviour on other util-linux versions.
**Severity:** Low
**Legibility-target:** the user and later editors reading the log

The cap is real (Claim 1). The parenthetical reads as if flock's timer limit is 7 digits; it is far higher. Executed (`bash $S/p1.sh`, cwd `/tmp/u4b1-fcc2-2Uwm`, exit 0, 2026-10-13T23:13:25Z, holder `flock lk sleep 8`, each waiter under `timeout 4`): `w=10000000`, `99999999`, `999999999`, `9999999999`, `999999999999` all `rc=124 elapsed_ms=4005` (still waiting when killed), i.e. flock accepted 12 digits. The first confirming pass found the failure only at `9223372036854775807` and `99999999999999999999` (exit 71, "cannot set up timer"; `docs/reviews/code-fact-check-report-2026-10-13-u4b1-confirm.md:64`). Precise version: "at most 7 digits, a conservative cap well inside flock's timer range".

**Evidence:** `scripts/health-check.sh:1118`, `$S/p1.sh`, `$S/p1.out`, `docs/reviews/code-fact-check-report-2026-10-13-u4b1-confirm.md:64`

---

## Claim 9: "E1: both WT removals use `worktree remove --force`: no clean check, so no status run executes a planted filter; uncommitted edits in WT are discarded, its branch stays."

**Location:** c67ffd62 commit message, E1 bullet
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two removal sites and their behaviour (Claims 3 and 7); does not establish the locked-worktree refusal (Claim 7) or step 1's `worktree prune`.
**Severity:** none
**Legibility-target:** the user reading the log

The two sites are `skills/dev-cycle/SKILL.md:64` ("removes WT as step 0.3 does (with `--force`…") and `:254` (`hg -C MAIN_WT worktree remove --force WT`); behaviour as executed in `$S/p3.out` (Claims 3, 7).

**Evidence:** `skills/dev-cycle/SKILL.md:64`, `skills/dev-cycle/SKILL.md:254`, `$S/p3.out`

---

## Claim 10: "health-check-lock 3/3; shellcheck clean."

**Location:** c67ffd62 commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `test/scripts/health-check-lock.bats` and shellcheck of `scripts/health-check.sh` at the repo gate's severity (`-S warning`); does not establish shellcheck at info level (one pre-existing SC2016 at `scripts/health-check.sh:224`, present at 923f7d26 as :223) or the full health check.
**Severity:** none
**Legibility-target:** the user reading the log

Executed in the worktree, 2026-10-13T23:18:56Z: `TMPDIR=<mktemp> bats test/scripts/health-check-lock.bats` → exit 0, `1..3`, `ok 1`, `ok 2`, `ok 3 HEALTH_CHECK_LOCK_WAIT bounds the wait …` (`$S/bats.out`). The gate's own form, `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:490`), run as `shellcheck -x -e SC1091 -s bash -S warning scripts/health-check.sh` at 2026-10-13T23:19:38Z → exit 0 (`$S/sc-gate.out`, empty). Plain `shellcheck scripts/health-check.sh` exits 1 on the info-level SC2016 only (`$S/sc.out`).

**Evidence:** `scripts/health-check.sh:490`, `$S/bats.out`, `$S/sc-gate.out`, `$S/sc.out`

---

## Claim 11: "Confirming reports, rubric (iteration-4 gate) and one override row (E6)."

**Location:** c67ffd62 commit message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the two confirming reports, the rubric's iteration-4 section with E1-E6, and exactly one added override row (E6, Won't-Fix); does not establish the reports' own correctness.
**Severity:** none
**Legibility-target:** the user reading the log

`git diff --stat 923f7d26..c67ffd62` lists `code-fact-check-report-2026-10-13-u4b1-confirm.md` (+334), `security-review-2026-10-13-u4b1-confirm.md` (+139), the rubric (+24/-…), and `override-log.md | 1 +`. The rubric adds `## Iteration-4 gate (2026-10-13)` with rows E1-E6 and "E6 | The payload under set -e could exit 75 itself … | Won't-Fix (override row)" (`docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md:136-151`); the one added override row: "health-check.sh's payload runs under set -e, so a command exiting 75 inside it would read as 'gave up waiting' … | Won't-Fix" (`docs/reviews/override-log.md:783`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md:136-151`, `docs/reviews/override-log.md:783`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`skills/dev-cycle/SKILL.md:237-243`; commit E2): the `log -G` guard misses a line held only on a side of a merge that history simplification prunes; one merge on main taking its cycles directory from a second parent makes it print nothing, so a newest record without `Main at:` bootstraps instead of stopping (executed). Use the lib's form, `--first-parent --diff-merges=first-parent -s --no-textconv` (`scripts/lib/dev-cycle-read.sh:508`), which finds the merge.

### Mostly Accurate
- **Claim 5** (`skills/dev-cycle/SKILL.md:234-237`): "the latest date" lacks dev-cycle.sh's exclusions (not a plain file / mode 100644, not a real date, future-dated), so step 0.2's newest record can differ from the digest's.
- **Claim 8** (c67ffd62 commit, E5): 7 digits is a conservative cap; flock's timer accepts at least 12 digits here (executed).

---

## Goal-Alignment Note

The goal is to land U4b1 after a clean review-fix loop, merging on no new Must Fix or Must Address. The range does what E1 asked: both removals use `--force`. Executed, that runs no planted clean filter, removes clean and modified worktrees, keeps the branch, and still refuses only a locked worktree. HEALTH_CHECK_LOCK_WAIT's cap and its header text check out by execution, and so do the stop-route wording (E3) and the bats/shellcheck claims. E2's fix only partly closes its finding. The history-based guard is right for linear history and renames. But `git log -- path` simplifies merges, so one merge on main that takes its cycles directory from a second parent again turns a newest record with no `Main at:` line into a bootstrap rather than a stop. That is the same Medium consequence as E2, reached by a different commit shape, and it comes from the text this range wrote (Claim 6b). The lib already has a first-parent `-G` read that catches it (`dev-cycle-read.sh:508`), so the fix is one flag set in one SKILL.md line. The same line also lacks the lib's `--no-textconv`, which `--state` covers only as a snapshot (Claim 6c). Claim 5's "newest record" gap is Low. Whether 6b counts as new for the merge gate (it is the remainder of E2, not a new mechanism) is the caller's call under Q-142.
