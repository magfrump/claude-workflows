Commit: 4dc84ce4

# Code Fact-Check Report

**Commit:** 4dc84ce4
**Replication:** k=3
**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** `git diff main...feat/build-loop-u1c -- . ':!docs/reviews'` at 4dc84ce4 (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats) plus the messages of 859e29e8, aaae80c6, 553a50d5, c143b929, 4dc84ce4. Iteration 3, final confirming pass; merged from r1/r2/r3 (most-severe-wins on the verdict, annotations by union).
**Checked:** 2026-10-05
**Total claims checked:** 37
**Summary:** 30 verified, 2 mostly accurate, 0 stale, 2 incorrect, 3 unverifiable

Merge notes: claims are numbered from r3's list, which is the most finely split one (it splits 12a/12b and 20a/20b). Claims 32–35 are claims that r3 did not list. Per-replicate reports, all stamped `Commit: 4dc84ce4`: `code-fact-check-report-build-loop-u1c-r1.md`, `-r2.md` and `-r3.md`. Each claim's body is copied from the replicate named in `Merged from`.

Two orchestrator decisions on compound claims, both recorded per claim:
- For 20a and 30, a compound verdict from r1/r2 says in its own Scope line which sibling sub-claim its non-Verified atom belongs to. That verdict is carried by that sibling (20b, 31) and not imposed on the clean one (decision 033).
- Claim 20a's merged verdict was set to Verified on that basis, overriding the compound Incorrect.

---

## Claim 1: "--settings  four lines from the default branch's commit ... Lines 1-3 from one line of docs/dev-cycle.md"

**Location:** `scripts/build-loop.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and order of --settings' output lines and the fact that lines 1-3 are read from docs/dev-cycle.md. Does not establish the per-line semantics of lines 1-3, which are U1b's and are not re-checked here.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 1

`printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"` (`scripts/build-loop.sh:361`). The bats test "--settings prints its four lines in order" asserts `"${#lines[@]}" -eq 4` and the policy/slots/never/constraints prefixes, and it passes.

**Evidence:** `scripts/build-loop.sh:359-362`, `test/scripts/build-loop-read.bats:~192-196`, `fc-r3/logs/bats-read.log`

---

## Claim 2: "constraints ok N-hard M-soft|missing|none-hard|unreadable: WHY"

**Location:** `scripts/build-loop.sh:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four output forms, each produced by `read_settings`, plus `missing` for a file that exists only in the working tree. Does not establish that a WHY text cannot carry a newline (FILE_WHY comes from fixed strings plus the fixed path).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 2

```bash
# scripts/build-loop.sh:258-269
if ! main_file "$f" "$CONSTRAINTS_AWK"; then
  if [[ "$FILE_WHY" == absent ]]; then CONSTRAINTS_LINE="constraints missing: no $f on the default branch"
  else CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"; fi
...
  ok) if [[ "$c" -gt 0 ]]; then CONSTRAINTS_LINE="constraints ok $c-hard $l1-soft: ...
```
(excerpt ends :269; enclosing read_settings() continues to :271 — read). The T44 test asserts each of the four forms, and it passes.

**Evidence:** `scripts/build-loop.sh:257-270`, `test/scripts/build-loop-read.bats` (T44), `fc-r3/logs/bats-read.log`

---

## Claim 3: "A constraint is a line "H<n>: text" (hard) or "S<n>: text" (soft) at column 0, optionally after "- ", n without a leading 0; a hard one needs a "success: <observable>" line (any indent, optionally after "- ") before the next constraint or "#" heading; no ID repeats; fences are skipped."

**Location:** `scripts/build-loop.sh:30-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-line regex, the pending-hard rule (closed by a later constraint, by a `#` line, or at END), the dup check and fence skipping. Does not establish CommonMark heading semantics: any line starting `#` ends a pending hard constraint, including `#tag`, which the help's "a "#" heading" already describes literally.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 3

`/^(- )?[HS][123456789][0123456789]*: [^ \t]/` (`:167`), `/^#/ { if (bad == "" && pend != "") bad = "nosuccess " ... }` (`:177`), `/^[ \t]*(- )?success: [^ \t]/ { pend = "" }` (`:178`) and `fence($0) { next }` (`:166`). The T44 cases (H1 with a success: line under `## Other` gives nosuccess, duplicate H1 gives dup, H01 gives near) pass.

**Evidence:** `scripts/build-loop.sh:164-186`, `fc-r3/logs/bats-read.log`

---

## Claim 4: "A line starting like "h1"/"s1" in letters and digits (after marks and a task box) but not exact makes the file unreadable (best effort)."

**Location:** `scripts/build-loop.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these shapes, all now read as unreadable: GFM task boxes `[ ]`/`[x]`/`[X]` after any marks (`- [x] H2:`, `- [X] H2:`, `* [x] H2:`, `+ [x] H2:`, `1. [x] H2:`, `[x]H2:`, `- [ ] H2:`, `- [x][x] H2:`), plus `[-]`, which is not a letter. Does not establish refusal of bracketed prefixes that keep a letter: `- [x ] H2: x` and `- [y] H2: x` both still give `constraints ok 1-hard 0-soft`, silently dropping H2 (the letters then start "xh2"/"yh2", the same class as the Q-112 prose-word-prefix residue in override-log row 290). It also does not establish that the fold leaves ordinary lines alone: since 4dc84ce4 it refuses the file for ordinary task lines whose text starts with a letter and a digit (`- [x] S3 bucket moved`, `- [x] h2o`), which c143b929 read as ok (fail-closed).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "- [x ] H2:", "- [y] H2:", "- [xx] H2:", "- [ x] H2:", "- (x) H2:" still give `constraints ok` with H2 uncounted (r1, r2 place them in override row 290's letter-prefix family; r3 leaves it to the orchestrator) · r1+r2+r3: the new fold now refuses ordinary lines such as "- [x] S3 bucket moved" and "- [x] h2o" that read ok at c143b929 (fail-closed behaviour change)
**Merged from:** r3 claim 4

`{ s = $0; sub(/^([^a-zA-Z]|\[[ xX]\])*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }` and `s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }` (`scripts/build-loop.sh:175-176`). Probe results: at HEAD, `- [x] H2: x` gives "constraints unreadable: line 3 looks like a constraint ...", and so do `- [x] S3 bucket moved` and `- [x] h2o`; `- [x ] H2: x` and `- [y] H2: x` give `constraints ok 1-hard 0-soft`. At c143b929 (fold `sub(/^[^a-zA-Z]*/, "", s)`), `- [x] H2: x`, `- [x] S3 bucket moved` and `- [x] h2o` all give `ok 1-hard 0-soft`. The help says "best effort" and names only "a task box", so the claim holds as written. The two residues are for the orchestrator to weigh against Q-112's "file a new shape" rule (`[x ]` is not a GFM task box, so it reads as a bracketed prose prefix).

**Evidence:** `scripts/build-loop.sh:175-176`, `fc-r3/logs/claim1-head.log`, `fc-r3/logs/claim1-old.log` (commands: `bash $BL --settings` in `fc-r3/c1`, `fc-r3/c1old`; exit 0; 2026-10-05T17:32:49Z)

---

## Claim 5: "Only "ok" lets the orchestrator dispatch."

**Location:** `scripts/build-loop.sh:38`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers nothing executable: the orchestrator that would act on the constraints line is planned (skills/dev-cycle, later units). Does not establish any consumer of CONSTRAINTS_LINE besides --settings' printf.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable (compound, claim 3) · r3=Unverifiable
**Replicate annotations:** r2: "every loop prompt carries" is also planned (U3/U4)
**Merged from:** r3 claim 5

paraphrased — no quote available because the claim concerns the absence of a consumer: a grep for `CONSTRAINTS_LINE` in scripts/ finds only its assignments in read_settings and the printf at `:361`. Verifying it needs the orchestrator's dispatch code (a later unit).

**Evidence:** `scripts/build-loop.sh:201`, `scripts/build-loop.sh:257-270`, `scripts/build-loop.sh:361`

---

## Claim 6: "--status  one line per brief path, in argument order, from the default branch's commit (the path must also be plain in the working tree, as --check-brief)"

**Location:** `scripts/build-loop.sh:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order (T28: six mixed ok/skip args), main-commit reads (T21: working-tree and branch edits ignored) and the working-tree plainness check via check_brief's `blocker`. Does not establish anything for duplicate arguments beyond the one instrumented run (claim 22), where a repeated path printed twice, identically.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 6

`for a in "${ARGS[@]}"; do status_line "$a"; done` (`scripts/build-loop.sh:357`). `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi` (`scripts/lib/dev-cycle-read.sh:329`).

**Evidence:** `scripts/build-loop.sh:354-358`, `scripts/lib/dev-cycle-read.sh:321-360`, `fc-r3/logs/bats-read.log`, `fc-r3/logs/claim4-brief.log`

---

## Claim 7: "ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]" with STATE (open/done/dropped, or new → "new review - absent - - 0"), POLICY (self-merge only when settings and the brief's first Policy: line are both self-merge), BRANCH (first "Branch: NAME"), LOOP absent/working/ready/blocked/stopped, SHA, DATE as YYYY-MM-DD, DISPATCHED 0-99 or 0 without one

**Location:** `scripts/build-loop.sh:46-54, 62-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers field order and each field's source in status_line for the cases T5/T6/T8 exercise, plus the instrumented run (claim 22). Does not establish DATE's time zone, which is the committer's own (`%cs`, as the lib's check_branch comment says).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 7

`echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` (`:351`). `if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi` (`:322`). `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`:332`). `^Dispatched:\ (0|[123456789][0123456789]?)$` (`:328`). `git log -1 --format=%cs "$sha"` (`scripts/lib/dev-cycle-read.sh:380`).

**Evidence:** `scripts/build-loop.sh:316-352`, `scripts/lib/dev-cycle-read.sh:370-383`, `fc-r3/logs/bats-read.log`, `fc-r3/logs/claim4-brief.log`

---

## Claim 8: "A tip is a marker only when the branch is at least one commit ahead of main and the tip is an empty commit with one parent whose subject is exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (1-120 printable ASCII characters, no blank at either end), alone on its first line (a second line, if any, empty); REASON is printed last."

**Location:** `scripts/build-loop.sh:55-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ahead gate, parent count, the tree-equals-parent check, the NUL refusal, the exact subjects, the 1-120 reason regex and the empty-second-line rule. Here "empty" is literal: a whitespace-only second line (`" "`, `"\t"`) is a skip ("its subject runs onto a second line"), although git's own `%s` treats such a line as blank and reports the subject as "handoff: ready". The code is stricter than git there. Not established: messages that git's commit parsing rewrites.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound, claim 6) · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: a whitespace-only second line is a skip, stricter than git's own subject parsing; matches the help's "empty"
**Merged from:** r3 claim 8

`rest="${msg#"$subj"}"; rest="${rest#$'\n'}"` / `if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"` (`:286-287`). `LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` (`:294`). The probe printed skip for `handoff: ready\n \nbody` and `handoff: ready\n\t\n`, and ready for `handoff: ready\n\nbody`, `handoff: ready\n` and `handoff: ready`. T6 covers 120 vs 121 characters.

**Evidence:** `scripts/build-loop.sh:276-296`, `fc-r3/logs/claim2-marker.log` (cwd `fc-r3/g4`, `bash $BL --status docs/working/briefs/2026-10-01-a.md`, exit 0, 2026-10-05T17:34:02Z), `fc-r3/logs/bats-read.log`

---

## Claim 9: "A tip whose subject does not start "handoff:" is working."

**Location:** `scripts/build-loop.sh:61-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated direction: a non-"handoff:" subject always gives LOOP working (`loop=working` defaults, and marker_kind echoes working). Does not establish the converse. A tip on a branch 0 commits ahead is also working whatever its subject, `handoff: bogus garbage` and a bad `handoff: stopped: ` included. Claim 11 covers that.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 9

`[[ "$subj" == handoff:* ]] || { echo working; return; }` (`:281`); `loop=working` / `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`:342-344`). T7's "wip: before handoff: ready" case gives working.

**Evidence:** `scripts/build-loop.sh:281`, `scripts/build-loop.sh:342-350`, `fc-r3/logs/claim2-marker.log`

---

## Claim 10: "skip BRIEF: WHY — The brief cannot be read (as --check-brief), its Branch: line is missing or malformed or its Dispatched: line malformed, its branch name is refused (as --check-branch)"

**Location:** `scripts/build-loop.sh:64-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check_brief pass-through, the Branch:/Dispatched: skips and the check_branch skip (`Branch: main`, HEAD, refs/heads/x, `a..b`, `-x`, non-ASCII). Does not establish the separate `"skip $a: the brief is not read"` arm at `:323`. That arm is reachable only if brief_fields fails after check_brief's own call succeeded, which is effectively unreachable.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none
**Merged from:** r3 claim 10

`[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (`:320`); `*) echo "skip $a: Branch: ${out#*: }"; return ;;` (`:340`). The T8 cases pass.

**Evidence:** `scripts/build-loop.sh:319-341`, `fc-r3/logs/bats-read.log`

---

## Claim 11: "... or the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:69-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip for a branch at least one commit ahead whose tip starts "handoff:" and fails a marker rule. Does not cover a branch 0 commits ahead: its tip is never passed to marker_kind, so a `handoff: bogus garbage` or `handoff: stopped: ` tip there prints `ok ... working`, not a skip.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: the "handoff:"-but-not-a-marker skip applies only on a branch at least one commit ahead of main; a 0-ahead tip with a malformed "handoff:" subject (even "handoff: stopped: ") reads working
**Merged from:** r3 claim 11

The skip is emitted only inside `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"; case "$kind" in bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ..."` (`scripts/build-loop.sh:343-346`). In the probe, with main's tip at `handoff: bogus garbage` and feat/a = main, the output was `ok docs/working/briefs/2026-10-01-a.md open review feat/a working 0af92613... 2026-10-05 0`. The same happened for `handoff: stopped: `. A precise wording would be "the branch is ahead of main and its tip's subject ... starts "handoff:" but it is not a marker". The marker sentence at `:55-56` carries the ahead condition. This skip sentence does not, and claim 9's "working" sentence does not name the 0-ahead case either. The behaviour is intended (T7 asserts a 0-ahead `handoff: ready` is working). Only the skip list's wording is imprecise.

**Evidence:** `scripts/build-loop.sh:342-350`, `fc-r3/logs/claim2-marker.log` (cwd `fc-r3/g4`, exit 0, 2026-10-05T17:34:02Z)

---

## Claim 12a: "for an open brief, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case)" — with git's default colour configuration

**Location:** `scripts/build-loop.sh:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip under the test environment's empty git config and under repo configs `grep.patternType=perl|fixed`, `grep.fullName`, `core.quotePath`, `grep.lineNumber`, `grep.column`, `grep.threads`, `core.ignoreCase` and `color.grep.filename=red`, with a CRLF partner brief, a partner in closed/ and a `.gitattributes` `binary` partner. Only an open queried brief is skipped (a done brief naming the same branch is ok, per T28). Does not establish the skip when colour is forced on (claim 12b), or for a partner in a nested subdirectory of briefs/ (`briefs/sub/…`), which is not a brief path and correctly does not count.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 9) · r2=Verified (claim 11) · r3=Verified
**Replicate annotations:** r1 (claim 18) + r2 (claim 21): the clause fails under forced colour or a failing git grep; see 12b
**Merged from:** r3 claim 12a

`if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then echo "skip $a: another open brief ..."` (`:333-334`). Each configuration above printed the skip in the probe log.

**Evidence:** `scripts/build-loop.sh:297-315`, `scripts/build-loop.sh:333-335`, `fc-r3/logs/claim3-gitgrep.log` (cwd `fc-r3/g1`, `bash $BL --status docs/working/briefs/2026-10-01-a.md`, exit 0, 2026-10-05T17:33:26Z)

---

## Claim 12b: same help clause — with `color.ui=always` or `color.grep=always` in repo or global git config

**Location:** `scripts/build-loop.sh:68-69`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --status at 4dc84ce4 when git's colour output is forced on through the repo's `.git/config` or the caller's global config. Does not establish other env-driven colour switches (e.g. `GIT_CONFIG_PARAMETERS`), which should behave the same but were not run.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect (claim 18, consequence) · r2=Incorrect (claim 21, consequence) · r3=Incorrect
**Replicate annotations:** r1+r2+r3: two open briefs naming one branch both print ok under color.ui=always / color.grep=always (repo or global config); c143b929 skipped both under the same config (regression from X1); tests cannot see it (GIT_CONFIG_GLOBAL=/dev/null)
**Merged from:** r3 claim 12b

With `git config color.ui always` (or `color.grep always`, or `[color] ui = always` in a `GIT_CONFIG_GLOBAL` file), two open briefs naming `feat/x` both print `ok … open review feat/x absent - - 0`, so F31 never fires. With the setting removed, the same repo prints the skip. At c143b929 the same repo with `color.ui=always` prints both skips, so 4dc84ce4 introduced the regression. Claim 20b gives the mechanism. The help states the skip unconditionally. The script itself treats repo config as untrusted for `core.useReplaceRefs` (`:107-111`), so a reader would expect repo config not to switch F31 off either.

**Evidence:** `scripts/build-loop.sh:306-309`, `fc-r3/logs/claim3-color.log` (cwd `fc-r3/g2`; HEAD and `fc-r3/old/scripts/build-loop.sh --status a b`; exit 0; 2026-10-05T17:33:39Z), `fc-r3/logs/misc.log` (global-config variant, 2026-10-05T17:34:59Z)

---

## Claim 13: "Exit: 0 every line printed (or help); 1 bad usage ..." and the usage line "--status needs at least one brief path"

**Location:** `scripts/build-loop.sh:77-78, 93-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` with no arguments exiting 1 (bats usage loop) and --status exiting 0 with mixed ok/skip lines. Does not establish exit codes under a git failure mid-status, where `set -e` inside command substitutions was not probed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 10) · r2=Verified (claim 12) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 13

`--status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage "--status needs at least one brief path" ;;` (`:97`). The bats loop `for args in "" "--bogus" "--settings extra" "--status"` asserts exit 1, and every --status probe in this report exited 0.

**Evidence:** `scripts/build-loop.sh:93-101`, `fc-r3/logs/bats-read.log`

---

## Claim 14: CONSTRAINTS_AWK prints ""ok HARD SOFT", "nosuccess ID LINE", "dup ID FIRST SECOND" or "near LINE" (the first problem found)."

**Location:** `scripts/build-loop.sh:161-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four constraint outcomes and first-problem-wins (every `bad` assignment is guarded by `bad == ""`). Does not list FENCE_AWK's `odd …`/`unbalanced …` outputs, which the same END also prints and which main_file consumes before read_settings sees them.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 11) · r2=Verified (claim 13) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 14

`print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)` (`:184`); `if (odd) print "odd " odd " " oddwhy` (`:180`). The symlinked-file and refdef T44 cases show main_file handling the FENCE_AWK outputs.

**Evidence:** `scripts/build-loop.sh:164-186`, `scripts/build-loop.sh:120-137`, `fc-r3/logs/bats-read.log`

---

## Claim 15: "# looks like an ID but is not exact" and "# a heading ends a pending one"

**Location:** `scripts/build-loop.sh:176-177`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two rules as coded. The near rule runs before the heading rule, so a heading like `# H2 rules` is a near-miss (unreadable) rather than a section end. Does not establish anything about headings indented by spaces, which are not `/^#/`.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (claim 14) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 15

`s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }` (`:176`); `/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }` (`:177`). T44's `'- H1: a' '## Other' '  success: b'` case gives nosuccess.

**Evidence:** `scripts/build-loop.sh:175-178`, `fc-r3/logs/bats-read.log`

---

## Claim 16: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER ..., NEVER_LINE and CONSTRAINTS_LINE from main's commit. POLICY is for --status and the planned gate, NEVER for the gate." (+ `# shellcheck disable=SC2034  # POLICY and NEVER: see above`)

**Location:** `scripts/build-loop.sh:197-202`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variables read_settings sets, POLICY's one reader (`:332`) and NEVER having no reader yet. "The gate" is the plan's D5/D6 `--merge`, which is not in this unit. Does not establish the gate's future use of NEVER.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 12) · r2=Verified (claim 15) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 16

`[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`:332`) is the only read of POLICY. NEVER is assigned at `:206` and `:242` and read nowhere (paraphrased — no quote available because the claim covers the absence of a reader: `grep -nw NEVER scripts/build-loop.sh` shows only comments and assignments). The plan names the gate ("the orchestrator runs the gate (D6) with `--merge --expect TIP`", `docs/working/plan-build-loop-handoff.md:58`).

**Evidence:** `scripts/build-loop.sh:197-206`, `scripts/build-loop.sh:242`, `scripts/build-loop.sh:332`, `docs/working/plan-build-loop-handoff.md:58`

---

## Claim 17: "The tip SHA of a brief's branch, read as a handoff marker: prints ready, blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY". The caller has checked that the branch is at least one commit ahead of main."

**Location:** `scripts/build-loop.sh:273-275`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers marker_kind's five output forms and its one caller's ahead check. Does not establish marker_kind's behaviour when called on a 0-ahead tip, which it never is.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 14) · r2=Verified (claim 16) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 17

`if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`:343-344`) is the only call. The echo arms are at `:281-295`.

**Evidence:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:343-344`

---

## Claim 18: "# git parses the object: its tree, its parents and where the message starts."

**Location:** `scripts/build-loop.sh:278`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parents via `rev-list --parents`, tree via `rev-parse ^{tree}` and message via `log --format=%B`. The T7 two-tree object is a skip ("it has no parent"). Does not establish that `cat-file commit` (used only for the NUL count) is consistent with git's parse in every malformed case.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 15) · r2=— · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 18

`read -ra p <<<"$(git rev-list --parents -n 1 "$1")"`, `msg="$(git log -1 --format=%B "$1")"` (`:279-280`). T7's two-trees case passes.

**Evidence:** `scripts/build-loop.sh:279-285`, `fc-r3/logs/bats-read.log`

---

## Claim 19: "# grep in the C locale: the ranges are ASCII bytes, and no locale is switched here."

**Location:** `scripts/build-loop.sh:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-command `LC_ALL=C` on the grep only, and T7's non-ASCII/bidi/escape reasons, which are refused and never echoed. Does not establish behaviour under a grep that ignores LC_ALL.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 16) · r2=Verified (claim 17) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 19

`printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` (`:294`).

**Evidence:** `scripts/build-loop.sh:292-295`, `fc-r3/logs/bats-read.log`

---

## Claim 20a: "One git grep finds the files with a "Status: open" line (a superset: fences are not modelled); brief_fields then reads only those." — under git's default colour configuration

**Location:** `scripts/build-loop.sh:304-305`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the superset property at line level. brief_fields's first Status line equals "Status: open" only if the blob has a line `Status: open` with at most one trailing CR, and the git grep ERE `^Status: open\r?$` matches exactly those lines. It holds for CRLF files, closed/ files, `.gitattributes binary`, `GIT_LITERAL_PATHSPECS=1` with the directory pathspec, and the configs listed in claim 12a. A blob that git grep cannot read (corrupt object) is dropped while git grep still exits 0, but brief_fields would fail on that blob too, so the superset holds. Does not establish the property when colour is forced on (claim 20b). Also, on any other git grep failure, `|| true` leaves the list empty and F31 off without a message (fail-open). That path is not described by the comment.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Incorrect (compound, claim 18) · r2=Incorrect (compound, claim 21) · r3=Verified
**Replicate annotations:** r1+r2: both compound Incorrect verdicts state in their own Scope that the superset holds under default config (CRLF, NUL/binary, nested dirs, grep.patternType perl/fixed, grep.fullName, core.quotePath, grep.column/lineNumber probed) and locate the failure in 20b's conditions; merged per decision 033 at sub-claim granularity, the compound Incorrect is carried by 20b
**Merged from:** r3 claim 20a

`list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"` (`:306`); brief_fields: `{ sub(/\r$/, "") } ... match($0, /^(Status|Branch|...):/)` with first-occurrence kept (`scripts/lib/dev-cycle-read.sh:297-303`).

**Evidence:** `scripts/build-loop.sh:301-315`, `scripts/lib/dev-cycle-read.sh:289-312`, `fc-r3/logs/claim3-gitgrep.log` (cwd `fc-r3/g1`, exit 0 each, 2026-10-05T17:33:26Z)

---

## Claim 20b: same comment — "a superset" — with `color.ui=always` / `color.grep=always` in effect

**Location:** `scripts/build-loop.sh:304-309`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep's `-l` output under forced colour and its effect on the candidate loop. Does not establish which deployments set forced colour. The script's hermetic tests (`GIT_CONFIG_GLOBAL=/dev/null`) cannot see it.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect (claim 18) · r2=Incorrect (claim 21) · r3=Incorrect
**Replicate annotations:** r1+r2+r3: forced colour wraps each `git grep -l` name in ANSI escapes, so `${f#"$MAIN_SHA":}` strips nothing and isbrief refuses every candidate: the set is empty, not a superset · r1+r2+r3: `|| true` turns a git grep failure (exit 128: grep.patternType=bogus, grep.threads=-1) into an empty set with exit 0 and no message · r1+r2: fix is `git grep --no-color` (or `-c color.grep=false`) and treat an exit other than 0/1 as an error · color.ui=auto is unaffected (r2)
**Merged from:** r3 claim 20b

git grep honours colour config even with `-l` piped to a file. The raw output was `033 [ 3 5 m m a i n : d o c s / ... a . m d 033 [ m \n`, meaning each name is wrapped in `\e[35m … \e[m`. Then `f="${f#"$MAIN_SHA":}"` strips nothing (the line starts with ESC), `isbrief "${f/closed\//}"` fails on every entry, `continue` drops all of them (`:308-309`), and SHARED_BRANCHES ends up as just `$'\n'`. The candidate set is empty rather than a superset, so F31 is silently off (claim 12b). In the probe the name prefix was `main:` because the probe called git grep with `main`. The script passes `$MAIN_SHA`, and the same wrapping applies there. A precise comment would have to say the superset holds only when git grep's colour is off. c143b929 did not use git grep and is unaffected.

**Evidence:** `scripts/build-loop.sh:306-312`, `fc-r3/logs/claim3-color.log` (cwd `fc-r3/g2`, `GIT_LITERAL_PATHSPECS=1 git grep -l -E … main -- docs/working/briefs/ | od -c` and both --status runs, exit 0, 2026-10-05T17:33:39Z), `fc-r3/logs/claim3-gitgrep.log`

---

## Claim 21: "Lower-cased branch names that more than one open brief on main (in briefs/ or closed/) names, each between newlines: such briefs are skipped (F31). status_line computes it on first use, so no caller can skip it."

**Location:** `scripts/build-loop.sh:297-299`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set's format (`$'\n'` plus names, each followed by a newline), the `lower` fold, closed/ inclusion (via `${f/closed\//}` before isbrief) and computation on status_line's first call (the empty-string sentinel, then `$'\n'`, so it is computed exactly once per run). Does not establish correctness under forced colour (claim 20b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 17) · r2=Verified (claim 18) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 21

`[[ -n "$SHARED_BRANCHES" ]] || shared_branches` (`:318`); `SHARED_BRANCHES=$'\n'; for b in "${!n[@]}"; do [[ "${n[$b]}" -lt 2 ]] || SHARED_BRANCHES+="$b"$'\n'; done` (`:313-314`). T28 (case-folded pair, closed/ partner, working-tree-only partner ignored) passes.

**Evidence:** `scripts/build-loop.sh:300-318`, `fc-r3/logs/bats-read.log`, `fc-r3/logs/claim3-gitgrep.log`

---

## Claim 22: "[[ -n "$SHARED_BRANCHES" ]] || shared_branches  # first: it reads other briefs into BRIEF"

**Location:** `scripts/build-loop.sh:318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers BRIEF holding the queried brief's fields at their use (`:324-332`) for five arguments in one run (done c, open a, open b, open closed/z, a again), where a, b and z are themselves git grep hits. check_brief's own brief_fields call runs in a `$(...)` subshell and cannot disturb the parent's BRIEF. Does not establish anything for future callers that read BRIEF between other lib calls.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 19) · r2=Verified (claim 19) · r3=Verified
**Replicate annotations:** r1+r2+r3: instrumented copies show BRIEF holds the queried brief's Branch, Dispatched and Policy in every call, across several arguments in one run, including open briefs git grep lists
**Merged from:** r3 claim 22

An instrumented copy (a debug echo inserted after `:332`) printed, e.g., `DEBUG …-a.md branch=[Branch: feat/a] disp=[Dispatched: 3] policy=[Policy: self-merge]` and then `ok …-a.md open self-merge feat/a absent - - 3`. `…/closed/2026-10-01-z.md` likewise printed its own `Dispatched: 42`, and every argument printed its own values.

**Evidence:** `scripts/build-loop.sh:316-332`, `fc-r3/inst/scripts/build-loop.sh`, `fc-r3/logs/claim4-brief.log` (cwd `fc-r3/g3`, exit 0, 2026-10-05T17:33:52Z)

---

## Claim 23: "The reader, kept in a lib so scripts/build-loop.sh can share it" / "kept apart so scripts/build-loop.sh can share it"

**Location:** `scripts/dev-cycle.sh:87`, `scripts/lib/dev-cycle-read.sh:2-3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers build-loop.sh sourcing the lib from its own directory. Does not establish that every lib function is used by both scripts.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 20) · r2=Verified (claim 20) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 23

`READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` … `source "$READ_LIB"` (`scripts/build-loop.sh:87-90`).

**Evidence:** `scripts/build-loop.sh:84-91`, `scripts/dev-cycle.sh:87`, `scripts/lib/dev-cycle-read.sh:1-3`

---

## Claim 24: fixture comments — "commit_all … (an empty commit when nothing changed, so rewriting a file as it was still works)"; "constraints LINE...: docs/constraints.md holding these lines, committed"; "brief SLUG LINE...: … sets B to its path"; "work BRANCH: BRANCH from main with one commit that changes a file"; "tip BRANCH MESSAGE [TREE [PARENT...]]: a commit with MESSAGE and a newline (no cleanup: commit-tree takes it as given) … pass TREE and the parents ("" for none)"

**Location:** `test/lib/build-loop-fixtures.bash:21-23, 31-32, 41-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each helper's stated effect. commit-tree keeping a whitespace-only line was observed in claim 8's probe. Does not establish anything about the helpers outside the bats environment's hermetic config.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 21) · r2=Verified (claim 22) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 24

`commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }`; `git update-ref "refs/heads/$b" "$(printf '%s\n' "$m" | git commit-tree "$t" "${p[@]}")"`; `for x in "$@"; do [[ -n "$x" ]] && p+=(-p "$x"); done` (an empty string adds no parent, as used for T7's orphan).

**Evidence:** `test/lib/build-loop-fixtures.bash:21-65`, `fc-r3/logs/bats-read.log`, `fc-r3/logs/claim2-marker.log`

---

## Claim 25: T44 additions — "# Only in the working tree: still missing."; "# A line that looks like a constraint ID but is not exact: unreadable, never skipped (Q-112 [1])."; the new case `'- S1: a' '- H1: b'` → nosuccess H1 (line 2)

**Location:** `test/scripts/build-loop-read.bats:~155-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions passing at HEAD, and the new case killing the mutant that deletes the END nosuccess check. Does not establish coverage of the residue shapes in claim 4 (`[x ]`, `[y]`), which the test list does not include.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 22) · r2=Verified (claims 23, 24) · r3=Verified
**Replicate annotations:** r1+r2+r3: deleting the END nosuccess check makes T44 fail at line 184 (mutation run)
**Merged from:** r3 claim 25

Mutation: deleting `if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl` inside END (`scripts/build-loop.sh:183`) makes `bats -f T44` fail at line 184 (`constraints ok 1-hard 1-soft` instead of the nosuccess line), exit 1.

**Evidence:** `test/scripts/build-loop-read.bats` (T44), `fc-r3/mut/scripts/build-loop.sh`, `fc-r3/logs/claim7-mutation.log` (cwd `fc-r3/mut`, `timeout 300 bats -f 'T44' test/scripts/build-loop-read.bats`, exit 1, 2026-10-05T17:34:33Z)

---

## Claim 26: "# A ready marker's body is not read here (the planned --marker reads blocked and stopped bodies)."

**Location:** `test/scripts/build-loop-read.bats:~256`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's interface line for --marker and marker_kind ignoring a ready marker's body (it checks only the second line). Does not establish --marker's implementation (not in this unit).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 23) · r2=Verified (claim 23) · r3=Verified
**Replicate annotations:** r1: matches plan line 206
**Merged from:** r3 claim 26

The plan says "`--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body under D11's rules; otherwise `skip`." (`docs/working/plan-build-loop-handoff.md:206`). The T6 case `handoff: ready\n\nAll green.` gives ready.

**Evidence:** `docs/working/plan-build-loop-handoff.md:206`, `scripts/build-loop.sh:286-289`

---

## Claim 27: T7/T28 comments — "A hand-made object with two tree lines, the parent's last: git stops at the second and sees no parent; a reader taking the last tree would say ready."; "A marker at main's tip with the branch 0 commits ahead is main's, not the loop's."; "So is a branch that is a symbolic ref to main."; "An open brief left in closed/ counts too."; "An open brief only in the working tree does not count."

**Location:** `test/scripts/build-loop-read.bats:~296-313, ~393-399`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each commented case's asserted outcome (all pass). The "a reader taking the last tree would say ready" counterfactual was not re-run against a raw-object reader. Does not establish symref behaviour beyond a symref to main.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 24) · r2=— · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 27

The assertions `check "skip $B: $n: it has no parent" two-trees`, `[[ "$output" == "ok $B open review feat/a working $(git rev-parse main) "* ]]` and `[[ "$output" == "skip $d: another open brief"* ]]` pass.

**Evidence:** `test/scripts/build-loop-read.bats` (T7, T28), `fc-r3/logs/bats-read.log`

---

## Claim 28: 4dc84ce4 message — "shared_branches read every brief … with brief_fields (O(every closed brief), 8 s at 500) … One `git grep -l '^Status: open'` on main now picks the candidates, brief_fields reads only those, and status_line computes the set first."; "A12: a leading task box (`- [x] H2:`) no longer hides a constraint ID"; "C16: the END check … is tested; C23: "soft constraint(s)""

**Location:** commit 4dc84ce4 message
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timing (one argument, 3 open briefs plus N closed): HEAD took 0.07/0.07/0.08/0.10 s and c143b929 took 0.07/0.38/2.13/10.06 s at N = 0/50/200/500 on this 16-core host. So the old cost was about 10 s at 500 here, the same order as the message's 8 s (host-dependent), and the new cost is flat. It also covers the mechanism change, A12 (claim 4), C16 (claim 25) and C23 (`:265` and the T44 assertion match). It does not establish that the git grep candidate set is complete when colour is forced on (claims 12b, 20b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claims 25, 26) · r2=Verified (claim 27) · r3=Verified
**Replicate annotations:** r1+r2+r3: --status with 3 open briefs at 0/50/200/500 closed: 4dc84ce4 0.06-0.10 s throughout; c143b929 0.07/0.34-0.44/2.1-2.4/8.7-10.4 s
**Merged from:** r3 claim 28

`list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"` (`scripts/build-loop.sh:306`); `"constraints none-hard: $f on the default branch has $l1 soft constraint(s) and no hard one (H1: with a success: line)"` (`:265`).

**Evidence:** `scripts/build-loop.sh:301-318`, `fc-r3/logs/claim5-perf.log` (cwd `fc-r3/pN`, `bash <script> --status docs/working/briefs/2026-10-01-o1.md`, exit 0 each, 2026-10-05T17:34:12Z)

---

## Claim 29: Line counts — 4dc84ce4 "433 changed code lines against main"; c143b929 "426 changed code lines against U1b"; 553a50d5 "U1c stays at 399 changed code lines against U1b"

**Location:** commits 4dc84ce4, c143b929, 553a50d5 messages
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added+removed from `git diff --numstat … -- . ':!docs/reviews'`: `main...HEAD` = 433; `2e711a7b c143b929` = 426 (2e711a7b is U1b's tip merged at 176a5fcc); `1d79ffef 553a50d5` = 399 (U1b's tip merged at 83b9fd49). Does not establish which base the authors used beyond this match.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claims 28, 29) · r2=Verified (claim 26) · r3=Verified
**Replicate annotations:** none
**Merged from:** r3 claim 29

`git diff --numstat main...HEAD` gives 175+8, 1+1, 2+2, 32+2 and 207+3 = 433.

**Evidence:** `fc-r3/logs/real-status.log` (cwd `/workspace/.claude/wt-build-loop-u1c`, 2026-10-05T17:35:05Z)

---

## Claim 30: aaae80c6 message — "The real briefs have no Branch: line yet, so --status skips them until the cycle writes machine lines (U4)."

**Location:** commit aaae80c6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's three briefs on main. Does not establish U4's future behaviour.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (claim 31) · r2=Unverifiable (compound, claim 29) · r3=Verified
**Replicate annotations:** r2: compound Unverifiable rests on the timing atoms (claim 31 here); the no-Branch-line atom matches at HEAD
**Merged from:** r3 claim 30

`--status` over the three real briefs printed `skip …: no Branch: line on the default branch` for each.

**Evidence:** `fc-r3/logs/real-status.log` (cwd `/workspace/.claude/wt-build-loop-u1c`, `bash scripts/build-loop.sh --status <3 briefs>`, exit 0, 114 ms, 2026-10-05T17:35:05Z)

---

## Claim 31: aaae80c6 message — "check_brief's `git log -1 -G'^Status: '` costs about 1 ms per brief on this repo (2137 commits, 1017 first-parent) … --status over the 3 real briefs: 79 ms."

**Location:** commit aaae80c6 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** A point-in-time measurement on a different code revision and repo state. Today's re-run of --status over the same 3 briefs took 114 ms, the same order. Does not establish the per-brief 1 ms figure or the commit counts at that time.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable (claim 30) · r2=Unverifiable (compound, claim 29) · r3=Unverifiable
**Replicate annotations:** r2: 104 ms today; r3: 114 ms today (79 ms claimed)
**Merged from:** r3 claim 31

paraphrased — no quote available because the claim is a timing on a past revision. A same-order re-measurement (114 ms, with the host's LC_ALL warnings) is logged.

**Evidence:** `fc-r3/logs/real-status.log`

---

## Claim 32: 4dc84ce4: "A12: a leading task box (`- [x] H2:`) no longer hides a constraint ID"

**Location:** commit 4dc84ce4 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3 (GFM task boxes); does not cover non-GFM bracket shapes.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (claim 28) · r3=—
**Replicate annotations:** none
**Merged from:** r1 claim 27

`c1.log`: `- [x] H2: x` → unreadable; T44 includes it.

**Evidence:** `scripts/build-loop.sh:175`, `c1.log`

---

## Claim 33: "# shellcheck disable=SC2034  # POLICY and NEVER: see above"

**Location:** `scripts/build-loop.sh:202`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which variables still trigger SC2034; does not establish anything about other directives.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r2 (handback note, not a claim): shellcheck confirms the SC2034 disable is needed only for NEVER · single-replicate detection
**Merged from:** r1 claim 13

With the directive removed, shellcheck reports only `NEVER appears unused` at line 242 (`c6.log` tail); POLICY is now read at `:332`, so the disable is needed only for NEVER. Precise version: "NEVER: see above". (Harmless.)

**Evidence:** `scripts/build-loop.sh:202`, `scripts/build-loop.sh:332`, `c6.log`

---

## Claim 34: 859e29e8: T7 covers "content, a merge, an orphan, suffixed or mis-cased subjects, an empty, control, bidi or non-ASCII reason, a two-line subject"

**Location:** commit 859e29e8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the T7 test body at HEAD; does not establish coverage of the NUL refusal (override row 291).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Merged from:** r1 claim 32

T7 builds each shape: `commit_all 'handoff: ready'` with a file change, a two-parent `tip`, an orphan `tip ... ""`, `'handoff: blocked!' 'handoff: Ready' 'handoff: stopped: ' $'...a\x1b[31mb' $'...caf\xc3\xa9' $'...x\xe2\x80\xaey'`, and `$(printf 'handoff: ready\nmore subject')`.

**Evidence:** `test/scripts/build-loop-read.bats` T7 (diff lines 453-494)

---

## Claim 35: c143b929 A1: "marker_kind lets git parse the commit (rev-list --parents, rev-parse ^{tree}, log %B) instead of reading the raw object, and refuses a NUL byte"; 859e29e8/c143b929 test descriptions (T5-T8, T21, T28)

**Location:** commits c143b929, 859e29e8
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** At HEAD, the mechanism matches (Claim 16, with the raw read kept only for NUL counting), and the test descriptions match passing tests. Whether they matched at those historical commits was not re-run, so the historical-state atom is the one left Unverifiable.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=— · single-replicate detection
**Replicate annotations:** r2: matches at HEAD; the historical commits were not re-run
**Merged from:** r2 claim 30

paraphrased — no quote available because the claim describes the state at a historical commit, and only HEAD was executed. At HEAD: `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"` (`scripts/build-loop.sh:279`) and `git cat-file commit "$1" | tr -cd '\000' | wc -c` (`:282`).

**Evidence:** `scripts/build-loop.sh:279-285`

---

## Claims Requiring Attention

### Incorrect
- **Claim 20b** (`scripts/build-loop.sh:304-306`): "a superset" is false, and all 3 replicates confirmed this by running it.
  - With `color.ui=always` or `color.grep=always` (repo or global config), `git grep -l` names carry ANSI escapes, `isbrief` refuses every one, and the F31 set comes out empty.
  - `|| true` turns a git grep failure (exit 128) into the same empty set, with no message and exit 0.
  - This is a regression from c143b929. Fix: `--no-color` (or `-c color.grep=false`), and treat an exit other than 0/1 as an error.
- **Claim 12b** (`scripts/build-loop.sh:68-69`): the help's F31 skip clause does not hold under the conditions in 20b. Two open briefs naming one branch both print `ok`.

### Stale
- None.

### Mostly Accurate
- **Claim 11** (`scripts/build-loop.sh:69-71`): the "starts handoff: but is not a marker" skip applies only on a branch at least one commit ahead of main (3/3 replicates).
- **Claim 33** (`scripts/build-loop.sh:202`): the SC2034 disable says "POLICY and NEVER", but POLICY is now read at `:332`, so only NEVER needs it (r1; r2 notes the same).

### Unverifiable
- **Claim 5:** "Only ok lets the orchestrator dispatch" describes planned U3/U4 behaviour.
- **Claim 31:** aaae80c6's timings are historical. Today they measure 104–114 ms against the 79 ms stated, the same order of magnitude.
- **Claim 35:** c143b929's historical-state claims match at HEAD, but the historical commits were not re-run.

## Escalations

- **F31 fails open under forced colour or a failing git grep** (`scripts/build-loop.sh:306`)
  - Raised by: r1, r2, r3
  - Addressee: security-reviewer (fail-open of a dispatch guard), then the orchestrator for tiering
  - Note: no override row covers it, and it is outside Q-112.
- **Bracketed non-task-box prefixes still give `constraints ok` with an uncounted H2** (`scripts/build-loop.sh:175`)
  - Shapes: `- [x ] H2:`, `- [y] H2:`, `- [xx] H2:`, `- (x) H2:`
  - Raised by: r1, r2, r3
  - Addressee: orchestrator, to place against override row 290's letter-prefix residue
  - r1 and r2 judge these covered by row 290.

## Verdict stability

- **Clusters:** 37
- **Fully agreed:** 30 of 37 (81%), counting only replicates that reported each cluster
- **Disagreements:**
  - Claims 20a and 30: compound vs sub-claim. r1/r2 recorded a compound verdict, and r3 verdicted the sub-claims Verified; see the merge notes.
  - Claim 12b: r1/r2 recorded the clause Verified under default config and filed the colour consequence under their comment claim. Counted as agreement on Incorrect by substance.
  - Single-replicate claims 10, 32 (two replicates), 33, 34 and 35: no disagreement measurable.
- **Blocking channel:** all three replicates independently reached Incorrect at high confidence on the same mechanism (20b), so the blocking verdict is unanimous.

---

## Submitted Claims

Appended from `code-fact-check-submitted-claims-build-loop-u1c.md` (Stage 2.5, k=1, Commit 4dc84ce4).

## Claim 36: "At 2000 closed briefs `--status` with one argument takes about 0.18 s, and 21 MB of closed-brief text adds no measurable time."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:301-315`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers one-argument `--status` wall time on this 16-core host with 2000 closed briefs that read `Status: done` (113,786 bytes, then 21,731,786 bytes), in a packed repo and a loose-object repo. It does not establish the 0.18 s figure on the critic's host. It also does not cover cost when closed briefs still carry a `Status: open` line, because each of those is read by `brief_fields` (measured: about 10 ms each).

The scaling mechanism holds. Only files that match one `git grep` reach `brief_fields`:

```bash
# scripts/build-loop.sh:306-310
  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
  while IFS= read -r f; do
    f="${f#"$MAIN_SHA":}"
    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
```
(excerpt ends :310; enclosing shared_branches() continues to :315 — read)

Executed results:
- Loose objects (`probe36.log`), 5 runs each. With 2000 small closed briefs: 0.084-0.088 s. After growing them to 21.7 MB: 0.103-0.114 s. With no closed briefs: 0.046-0.048 s. In this layout the 21 MB added about 20-28 ms, and the run ranges do not overlap.
- Packed with `git gc` (`probe36b.log`), 15 interleaved runs. Small: median 74 ms (67-82). 21.7 MB: median 73 ms (63-83). No measurable difference.
- Residue (`probe36c.log`): 200 closed briefs with `Status: open` took 2017 ms.

A more precise version of the claim would read: "about 0.1 s here (0.18 s on the critic's host); 21 MB of closed-brief text adds no measurable time in a packed repo and about 25 ms with loose objects."

**Evidence:** `scripts/build-loop.sh:301-315`, `scripts/lib/dev-cycle-read.sh:289-312`. Commands: `timeout 590 bash probe36.sh > probe36.log 2>&1` (exit 0, 2026-10-05T17:52:41Z), `timeout 590 bash probe36b.sh > probe36b.log 2>&1` (exit 0, 2026-10-05T17:53:04Z), `timeout 400 bash probe36c.sh > probe36c.log 2>&1` (exit 0, 2026-10-05T17:53:15Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe36.log`, `.../probe36b.log`, `.../probe36c.log`

---

## Claim 37: "Moving the guard to the top of `status_line` gives the right answer on every path. `check_brief` runs in a subshell, so the only `BRIEF` writer after the guard is `brief_fields "$a"` itself."

**Submitted by:** architecture-review
**Location:** `scripts/build-loop.sh:316-355`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which `BRIEF` contents `status_line` judges on every return path (skip, new, Branch/Dispatched/F31 skips, absent, marker), for one or several arguments. It does not establish that the guard's shared set is itself correct: under repo `color.ui=always` or `color.grep=always`, `shared_branches` finds nothing and F31 is off (see claims 41 and 43).

The guard is the first statement, and every later call that could write `BRIEF` runs in a command substitution, except `brief_fields "$a"`:

```bash
# scripts/build-loop.sh:318-323
  [[ -n "$SHARED_BRANCHES" ]] || shared_branches  # first: it reads other briefs into BRIEF
  out="$(check_brief "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
  read -r _ _ st _ <<<"$out"
  if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi
  brief_fields "$a" || { echo "skip $a: the brief is not read"; return; }
```
(excerpt ends :323; enclosing status_line() continues to :352 — read)

The rest of the function writes nothing to `BRIEF`: `check_branch` (:336), `marker_kind` (:344) and `lower` (:333) all run inside `$(...)`. `brief_fields` starts with `BRIEF=(); BRIEF_ODD=""` (`scripts/lib/dev-cycle-read.sh:293`), so a leftover value cannot survive into a later read. The two returns before :323 (:320, :322) do not read `BRIEF`.

Executed (`probe37.log`): the queried brief `a` (self-merge, Dispatched 3) came out as `ok ... open self-merge feat/a absent - - 3`. That held even though `shared_branches` read `zz` (Dispatched 7) and `closed/...-zzz` (Dispatched 9) last, and for argument orders `a`, `zz a`, `a zz`, `docs/x.md a` and `new a`. `probe37b.log`: two open briefs that both name the odd keys `@`, `*` or `x]y` still produce the F31 skip with exit 0.

**Evidence:** `scripts/build-loop.sh:300-352`, `scripts/lib/dev-cycle-read.sh:289-312`. Commands: `timeout 300 bash probe37.sh > probe37.log 2>&1` (exit 0, 2026-10-05T17:53:34Z), `timeout 200 bash probe37b.sh > probe37b.log 2>&1` (exit 0, ~2026-10-05T17:53:40Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe37.log`, `.../probe37b.log`

---

## Claim 38: "C23's `constraint(s)` matches dev-cycle.sh's `(s)` convention exactly."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/build-loop.sh:265`, `scripts/dev-cycle.sh:259`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plural form after a count: a count, then the noun with `(s)` attached. It does not establish that every count-plus-noun output in build-loop.sh uses `(s)`. The one other count message, `it has N parents` (:284), prints only for N of 2 or more.

```bash
# scripts/build-loop.sh:265
          else CONSTRAINTS_LINE="constraints none-hard: $f on the default branch has $l1 soft constraint(s) and no hard one (H1: with a success: line)"; fi ;;
```
```bash
# scripts/dev-cycle.sh:259
echo "$n_merges merge(s) on \`$MAIN\`'s first-parent line; $commits commit(s) reachable from it, merged branches included."
```
dev-cycle.sh uses the same shape in `file(s)` (:400), `item(s)` (:433) and `day(s)` (:449). The executed diff in claim 40 shows the output changed from `2 soft constraints` to `2 soft constraint(s)`.

**Evidence:** `scripts/build-loop.sh:265`, `scripts/dev-cycle.sh:259`, `scripts/dev-cycle.sh:400`, `scripts/dev-cycle.sh:433`, `scripts/dev-cycle.sh:449`

---

## Claim 39: "A17's 'for an open brief' matches the `st == open` gate."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/build-loop.sh:68-69`, `scripts/build-loop.sh:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help's condition that only an open queried brief takes the F31 skip, and that a done or dropped one sharing the branch does not. It does not establish that the shared set is complete under colour config (claims 41 and 43). It also does not cover open briefs whose `Branch:` line is malformed: those are not counted, and the help's "names the same branch" leaves that case open.

```bash
# scripts/build-loop.sh:68-69
#                 for an open brief, another open brief on main (in briefs/ or
#                 closed/) names the same branch (ignoring case), or the tip's subject (its
```
```bash
# scripts/build-loop.sh:333-335
  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
    echo "skip $a: another open brief on the default branch names the same branch (compared ignoring case)"; return
  fi
```
"Another" holds because the queried open brief is always one of the counted briefs. Its first unfenced `Status:` line is exactly `Status: open` (`scripts/lib/dev-cycle-read.sh:349`), so the grep at :306 finds the file, and the count at :310-311 uses the same `Branch:` regex as :325. A skip therefore needs a count of 2 or more, which means at least one other brief.

Executed (`probe41.log` baseline): with open briefs a (`feat/x`) and b (`Feat/X`) and a done brief c (`feat/x`), the output was `skip a ...`, `skip b ...` and `ok c done review feat/x absent - - 0`. bats T28 asserts the same for a done brief (`bats.log`, ok 16).

**Evidence:** `scripts/build-loop.sh:68-69`, `scripts/build-loop.sh:306-314`, `scripts/build-loop.sh:333-335`, `scripts/lib/dev-cycle-read.sh:348-351`. Command: `timeout 300 bash probe41.sh > probe41.log 2>&1` (exit 0, 2026-10-05T17:51:41Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe41.log`, `.../bats.log`

---

## Claim 40a: "4dc84ce4 changes no output format. The `--settings` four-line order, the `--status` field order ... are byte-identical to c143b929"

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/build-loop.sh:262-269`, `scripts/build-loop.sh:316-363` (via `git diff c143b929 4dc84ce4 -- scripts/build-loop.sh`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output strings and field order that build-loop.sh itself emits. It does not establish that classifications are unchanged. A12 moves `- [x] H2: x` from `none-hard` to `unreadable`, using a reason string that already existed.

`git diff c143b929 4dc84ce4 -- scripts/build-loop.sh` changes only these things:
- header comments
- the C23 string (`soft constraints` → `soft constraint(s)`, :265)
- the near-miss regex (:175)
- the `shared_branches` list source (:306-308)
- where the guard sits (:318)

It changes no `echo` or `printf` format. The `printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"` (:361) and `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` (:351) lines are the same in both versions (paraphrased — no quote available because the claim concerns lines the diff does not touch; the diff text was read in full).

Executed differential (`probe40.log`): both versions gave the same output on the r41, r43 and r37 fixtures (`--status` with open/done/new/non-brief/marker/stopped/closed briefs, and `--settings`). For the constraints variants, there were two kinds of difference:
- the C23 prose (`2 soft constraints` vs `2 soft constraint(s)`, and the same for `0`)
- the A12 reclassification of `- [x] H2: x`

**Evidence:** `scripts/build-loop.sh:175`, `scripts/build-loop.sh:265`, `scripts/build-loop.sh:306-318`, `scripts/build-loop.sh:351`, `scripts/build-loop.sh:361`. Command: `timeout 400 bash probe40.sh > probe40.log 2>&1` (exit 1 from the abandoned duplicate-tree tail, redone in probe40b; every SAME/DIFF line above it ran; 2026-10-05T17:54:18Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe40.log`

---

## Claim 40b: "... and every skip reason [is] byte-identical to c143b929, apart from the C23 prose."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:337` (claim cites `git diff c143b929 4dc84ce4 -- scripts/build-loop.sh`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every skip reason `--status` can print between c143b929 and 4dc84ce4, including those that come from the lib. It does not cover `--check-answer` output from dev-cycle.sh, where the same lib wording change (:557) also lands.

The claim holds for build-loop.sh's own strings. But `--status` also prints check_brief's reasons, and the range c143b929..4dc84ce4 includes the merge of main (48663245, bringing in 8dc4880b). That merge changed one of check_brief's reasons:

```bash
# scripts/lib/dev-cycle-read.sh:337
    error) echo "skip $a: the tree of the default branch could not be read"; return ;;
```
At c143b929 the line read `skip $a: the default branch's tree could not be read`. 4dc84ce4 as a commit did not make this change (`git show --stat 4dc84ce4` lists only build-loop.sh, the bats file and override-log.md). It still falls inside the c143b929-to-4dc84ce4 comparison the claim makes.

Executed (`probe40b.log`): a main commit whose `docs/working/briefs/` tree lists `2026-10-01-a.md` twice. c143b929 printed `skip docs/working/briefs/2026-10-01-a.md: the default branch's tree could not be read`. 4dc84ce4 printed `skip docs/working/briefs/2026-10-01-a.md: the tree of the default branch could not be read`.

Precise version: "byte-identical apart from C23 and check_brief's tree-read error reason, which main's U1a gate fix reworded."

**Evidence:** `scripts/lib/dev-cycle-read.sh:337`, `scripts/lib/dev-cycle-read.sh:557`, `scripts/build-loop.sh:319-320`. Command: `timeout 200 bash probe40b.sh > probe40b.log 2>&1` (exit 0, 2026-10-05T17:54:31Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe40b.log`

---

## Claim 41: "With repo config grep.patternType=fixed|perl, grep.extendedRegexp=false, grep.fullName=true, grep.lineNumber=true, grep.column=true, core.bigFileThreshold=1, core.quotePath=true, submodule.recurse=true, grep.fallbackToNoIndex=true, color.grep.filename=red or core.attributesFile=/nonexistent, the two-brief fixture still prints both F31 skips."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:306`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed key set alone in `.git/config` (plus grep.patternType=basic and grep.threads=1), checked against exact expected output on a three-brief fixture (two open sharing a branch case-insensitively, one done). It does not establish robustness to other repo config. **Repo `color.ui=always` or `color.grep=always` defeats F31:** both open briefs print `ok ...` instead of skipping. `color.grep.filename=red` is harmless only while colour is off.

```bash
# scripts/build-loop.sh:306-308
  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
  while IFS= read -r f; do
    f="${f#"$MAIN_SHA":}"
```
(excerpt ends :308; enclosing shared_branches() continues to :315 — read)

Executed (`probe41.log`): every listed config gave PASS, with output equal to `skip a`, `skip b`, `ok c done review feat/x absent - - 0`. Three settings outside the list gave FAIL: `color.ui=always`, `color.grep=always`, and `color.grep.filename=red` combined with `color.ui=always`. In each, `--status` printed `ok ... open review feat/x absent - - 0` for a and `ok ... Feat/X ...` for b. The raw grep shows the cause: under `color.ui=always`, `git grep -l` prints `\033[35mmain:docs/...a.md\033[m`, so the `${f#"$MAIN_SHA":}` strip and `isbrief` both fail, and no brief is counted.

**Evidence:** `scripts/build-loop.sh:306-315`, `scripts/build-loop.sh:333`. Command: `timeout 300 bash probe41.sh > probe41.log 2>&1` (exit 0, 2026-10-05T17:51:41Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe41.log`

---

## Claim 42: "A diff=x textconv or a binary -text attribute in .git/info/attributes for *.md leaves the F31 result unchanged."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the F31 skip lines and exit status on the three-brief fixture under the attributes `*.md diff=x`, `-text`, `binary`, `-text -diff` and `diff=x -text`, with textconv set to a failing command, `false`, `cat`, `sed s/open/shut/`, or an upper-casing `sh -c`. It does not establish that `--status` runs no repo-configured command. check_brief's `git log -G'^Status: '` (`scripts/lib/dev-cycle-read.sh:357`) does invoke the textconv driver, and a failing one writes `fatal: unable to read files to diff` to stderr once per brief.

`git grep` at :306 has no `--textconv`, so it reads raw blobs, and `-l` lists binary-marked files the same way (raw `git grep -l` under `diff=x -text` listed both briefs, `probe41.log`). Executed (`probe42.log`): every attribute and textconv combination printed exactly `skip a ...`, `skip b ...`, `ok c done ...` with exit 0. Even `sed s/open/shut/`, which would hide `Status: open` from a reader that applied it, left both skips in place. With the failing textconvs (`tr a-z A-Z` given a file operand, `false`), stderr carried `fatal: unable to read files to diff` three times. That comes from the lib's `git log -G` (:357), not from :306:

```bash
# scripts/lib/dev-cycle-read.sh:357-358
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
(excerpt ends :358; enclosing check_brief() continues to :360 — read)

**Evidence:** `scripts/build-loop.sh:306`, `scripts/lib/dev-cycle-read.sh:357-359`. Commands: `timeout 300 bash probe42.sh > probe42.log 2>&1` (exit 0, 2026-10-05T17:52:02Z), `timeout 300 bash probe41.sh > probe41.log 2>&1` (attribute section; exit 0, 2026-10-05T17:51:41Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe42.log`, `.../probe41.log`

---

## Claim 43: "Under repo color.ui=always, the --status line for a marked branch carries no ESC byte and reads ready; among the --status git calls, only the git grep at :306 was colour-sensitive."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:336-351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the marker read (`ready`, and `stopped` with its reason) and the 20 git invocations on the `--status` path, under repo `color.ui=always` (also with `color.diff=always`, `color.decorate.branch=red` and `log.decorate=full`). It does not establish that the colour sensitivity of :306 is harmless. At 4dc84ce4 it is still live and turns F31 off (claim 41's scope). It also does not cover a `git -c` or `GIT_CONFIG_*` colour setting in the caller's environment.

```bash
# scripts/build-loop.sh:279-281
  read -ra p <<<"$(git rev-list --parents -n 1 "$1")"
  msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
```
(excerpt ends :281; enclosing marker_kind() continues to :296 — read)

Executed (`probe43.log`): with `color.ui always`, `--status` printed `ok ...-m.md open review feat/m ready 0799065f... 2026-10-05 1` and `ok ...-s.md open review feat/s stopped 8cb2bf08... 2026-10-05 0 needs a key`, with no ESC byte (`od -c` shows no `033`). The 20 calls were each run separately, and 19 printed no ESC:
- rev-parse --show-toplevel, symbolic-ref, show-ref (main, branch), rev-parse --verify ^{commit}/^{tree}
- ls-tree -t --full-tree, cat-file blob (brief, settings)
- log -G and log -1 --format=%H (check_brief), check-ref-format (both forms)
- rev-list --count, log --format=%cs, rev-list --parents, log --format=%B, cat-file commit

The one that printed ESC was `git grep -l ... -- docs/working/briefs/`.

**Evidence:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:306`, `scripts/build-loop.sh:336-351`, `scripts/lib/dev-cycle-read.sh:357-358`, `scripts/lib/dev-cycle-read.sh:370-383`. Command: `timeout 300 bash probe43.sh > probe43.log 2>&1` (exit 0, 2026-10-05T17:52:22Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe43.log`

---

