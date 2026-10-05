Commit: 4dc84ce4

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u1c, branch feat/build-loop-u1c)
**Scope:** `git diff main...feat/build-loop-u1c -- . ':!docs/reviews'` (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats) plus the messages of 859e29e8, aaae80c6, 553a50d5, c143b929, 4dc84ce4. Replicate r2, iteration 3.
**Checked:** 2026-10-05
**Total claims checked:** 30
**Summary:** 25 verified, 1 mostly accurate, 0 stale, 1 incorrect, 3 unverifiable

Hallucination-pattern log read (docs/reviews/hallucination-patterns.md). No claim matches a logged pattern. The logged entries are all corpus statistics and test-count tallies. The one count claim here (433 lines, Claim 26) was recounted and is correct.

Execution provenance. Every executed probe ran with cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-r2/repos/<name>` (throwaway repos built by `fx.bash`, a copy of test/lib/build-loop-fixtures.bash with GIT_CONFIG_GLOBAL=/dev/null), between 2026-10-05T17:30Z and 17:36Z, git 2.39.5. Each probe called `timeout 30 bash /workspace/.claude/wt-build-loop-u1c/scripts/build-loop.sh ...`. The captured logs sit in the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-r2/`:
- `c1-nearmiss.log`: 31 near-miss constraint shapes
- `perf.log`: timing
- `mut-t44.log`: the mutation run
- `bats-build-loop-read.log`: the suite at HEAD, exit 0, 16/16 ok
- `probes2.log`: marker and git-config probes, script `probes2.sh`, exit 0

The c143b929 copy used for before/after comparison is `old/scripts/`.

---

## Claim 1: "--settings  four lines from the default branch's commit ... Lines 1-3 from one line of docs/dev-cycle.md"

**Location:** `scripts/build-loop.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count and order of --settings output. It does not re-verify lines 1-3's U1b grammar, which is out of this unit's scope.
**Legibility-target:** for-orchestrator-synthesis

`printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"` (`scripts/build-loop.sh:361`). The bats test "--settings prints its four lines in order" passes. It asserts `${#lines[@]} -eq 4` and the policy/slots/never/constraints prefixes.

**Evidence:** `scripts/build-loop.sh:361`, `test/scripts/build-loop-read.bats` (test 9 in bats-build-loop-read.log; cmd `bats test/scripts/build-loop-read.bats`, cwd worktree, exit 0, 2026-10-05T17:34:42Z)

---

## Claim 2: "constraints ok N-hard M-soft|missing|none-hard|unreadable: WHY" (the output forms)

**Location:** `scripts/build-loop.sh:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four output forms and their WHY texts as `read_settings` builds them (`:257-270`). It does not cover how a future orchestrator interprets them (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

`ok) if [[ "$c" -gt 0 ]]; then CONSTRAINTS_LINE="constraints ok $c-hard $l1-soft: ..." else CONSTRAINTS_LINE="constraints none-hard: ... has $l1 soft constraint(s) ..."` (`:264-265`). An absent file gives `constraints missing: no $f on the default branch` (`:259`), and every other failure gives `constraints unreadable:` (`:260`, `:266-268`). Every form was produced in the probes, and T44 passes.

**Evidence:** `scripts/build-loop.sh:257-270`, c1-nearmiss.log, bats-build-loop-read.log

---

## Claim 3: "docs/constraints.md, which every loop prompt carries" / "Only "ok" lets the orchestrator dispatch."

**Location:** `scripts/build-loop.sh:30`, `scripts/build-loop.sh:38`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether any code today carries constraints.md into a prompt or gates dispatch on "ok". It does not establish the planned behaviour, which exists only in the plan.
**Legibility-target:** for-orchestrator-synthesis

No script outside build-loop.sh reads docs/constraints.md (paraphrased — no quote available because the claim is about the absence of code: `grep -rn constraints.md scripts/ skills/dev-cycle` gives no other hit). The plan holds the design: "Every loop prompt carries `docs/constraints.md` from main's commit" (`docs/working/plan-build-loop-handoff.md:44`) and "`--start` refuses (T44)" (`:173`). Verifying this needs the --prompt and --start modes, which are planned for later units.

**Evidence:** `docs/working/plan-build-loop-handoff.md:44`, `docs/working/plan-build-loop-handoff.md:50`, `docs/working/plan-build-loop-handoff.md:173`

---

## Claim 4: "A constraint is a line "H<n>: text" (hard) or "S<n>: text" (soft) at column 0, optionally after "- ", n without a leading 0; a hard one needs a "success: <observable>" line (any indent, optionally after "- ") before the next constraint or "#" heading; no ID repeats; fences are skipped."

**Location:** `scripts/build-loop.sh:30-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-ID regex, the success-line regex, termination by a following constraint (hard or soft), by a `#` line and by EOF, the dup check, and fence skipping. "#" heading means any column-0 `#` line (including `#tag`). An indented ` # x` or a setext heading does not end a pending constraint. That matches the help's literal wording, but not every Markdown heading.
**Legibility-target:** for-orchestrator-synthesis

The ID rule is `/^(- )?[HS][123456789][0123456789]*: [^ \t]/` (`:167`). The success rule is `/^[ \t]*(- )?success: [^ \t]/ { pend = "" }` (`:178`). A heading ends a pending constraint at `/^#/ { ... pend = ""; next }` (`:177`), and the dup check is `if (bad == "" && (id in seen)) bad = "dup " ...` (`:170`). Fenced lines skip via `fence($0) { next }` (`:166`) (excerpt ends :178; enclosing CONSTRAINTS_AWK continues to :186 — read).

Probe results:
- An H2 inside a fence gives `ok 1-hard`.
- A success line inside a fence does not count (`nosuccess`).
- `#tag` ends a pending constraint.
- `\t\t- success: b` is accepted.
- `* success: b` and `success:b` are refused.
- `H10:` is accepted.
- `  - H1:` is a near-miss.
- A duplicate H1 gives `dup`.

**Evidence:** `scripts/build-loop.sh:164-186`; probe output in this session (repos/c1b), and T44 in bats-build-loop-read.log

---

## Claim 5: "A line starting like "h1"/"s1" in letters and digits (after marks and a task box) but not exact makes the file unreadable (best effort)."

**Location:** `scripts/build-loop.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GFM task boxes `[ ]`, `[x]` and `[X]` after any non-letter marks. It does not cover non-GFM boxes or letter prefixes, which pass silently under "best effort" (listed below). It does not establish that ordinary prose is never refused.
**Legibility-target:** for-orchestrator-synthesis

The fold is `{ s = $0; sub(/^([^a-zA-Z]|\[[ xX]\])*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }` followed by `s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }` (`:175-176`).

Shapes that now read unreadable:
- `- [x] H2: x`
- `- [X] H2: x`
- `* [x] H2: x`
- `1. [x] H2: x`
- `[x]H2: x`
- `- [ ] H2: x`
- `- [x] [x] H2: x`
- `- [x] **H2:** x`
- `- ✅ H2: x`

At c143b929, `- [x] H2: x` read `ok 1-hard` (old/scripts run).

Residue that still reads `ok 1-hard 0-soft` with a hidden H2:
- `- [x ] H2: x`
- `- [y] H2: x`
- `- [xx] H2: x`
- `- (x) H2: x`

Each puts a letter before the ID. These sit in the Q-112 [1] "prose-word prefix" family of override row 290 (`Hard H2:`, `a. H2:`) and are not a new shape. `[x ]` is not a GFM task box, so the help's "a task box" holds.

Behaviour change (fail-closed, consistent with the help's wording): `- [x] S3 bucket moved` and `- [x] h2o` were `ok` at c143b929 and are now unreadable. `H2O is water` was already unreadable before this fix.

**Evidence:** `scripts/build-loop.sh:175-176`, c1-nearmiss.log; c143b929 comparison run in this session (repos/c1old)

---

## Claim 6: "--status  one line per brief path, in argument order, from the default branch's commit (the path must also be plain in the working tree, as --check-brief)"

**Location:** `scripts/build-loop.sh:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers argument order, the main-commit read (T21), and the working-tree symlink refusal via check_brief's blocker. It does not cover paths that are absent from the working tree but present on main (not probed).
**Legibility-target:** for-orchestrator-synthesis

`for a in "${ARGS[@]}"; do status_line "$a"; done` (`:357`). check_brief runs `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"` (`scripts/lib/dev-cycle-read.sh:329`). A probe that replaced a committed brief in the working tree with a symlink gave exactly that skip, with exit 0. T28 (order across six arguments) and T21 pass.

**Evidence:** `scripts/build-loop.sh:357`, `scripts/lib/dev-cycle-read.sh:321-360`, bats-build-loop-read.log; probe repos/c8

---

## Claim 7: "ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]" with STATE/new, POLICY, BRANCH, DATE, DISPATCHED definitions

**Location:** `scripts/build-loop.sh:46-55`, `scripts/build-loop.sh:61-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers field order, the "new review - absent - - 0" line, the policy conjunction, first-Branch:-line use, %cs dates, "-" fields when absent, and Dispatched 0-99 or 0 when missing. It does not cover the planned gate's use of POLICY.
**Legibility-target:** for-orchestrator-synthesis

The line forms:
- New: `echo "ok $a new review - absent - - 0"` (`:322`).
- Policy: `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`:332`).
- Absent branch: `"absent "*) echo "ok $a $st $pol $br absent - - $disp"` (`:338`).
- Final line: `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` (`:351`).
- Dispatched: `^Dispatched:\ (0|[123456789][0123456789]?)$` (`:328`).

The date comes from check_branch's `git log -1 --format=%cs` (`scripts/lib/dev-cycle-read.sh:380`). T5, T6 and T8 assert every field and pass. The instrumented run (Claim 22) printed `ok ... open self-merge feat/a absent - - 3`.

**Evidence:** `scripts/build-loop.sh:316-352`, `scripts/lib/dev-cycle-read.sh:370-383`, bats-build-loop-read.log

---

## Claim 8: "A tip is a marker only when the branch is at least one commit ahead of main and the tip is an empty commit with one parent whose subject is exactly ... alone on its first line (a second line, if any, empty); REASON is printed last."

**Location:** `scripts/build-loop.sh:55-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ahead gate, the empty-tree, one-parent, NUL, two-line and exact-subject checks, and the 1-120 printable-ASCII reason. It does not cover message encodings other than UTF-8/ASCII (e.g. an `encoding` header re-encoded by `git log`), which were not probed.
**Legibility-target:** for-orchestrator-synthesis

The gate is `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`:343-344`). The second-line rule is `rest="${msg#"$subj"}"; rest="${rest#$'\n'}"` followed by `if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"` (`:286-287`).

Probe results:
- A whitespace-only second line (`handoff: ready\n \nbody`) gives skip "runs onto a second line".
- An empty second line (`handoff: ready\n\nbody`) gives `ready`.
- A CR-suffixed subject gives skip "not exactly".

T6 and T7 pass.

**Evidence:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:342-350`, probes2.log ("## marker probes"), bats-build-loop-read.log

---

## Claim 9: "A tip whose subject does not start "handoff:" is working."

**Location:** `scripts/build-loop.sh:61-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-"handoff:" tips, whether ahead or not. Not stated here but true: a tip 0 commits ahead is also working whatever its subject (see Claim 10).
**Legibility-target:** for-orchestrator-synthesis

`[[ "$subj" == handoff:* ]] || { echo working; return; }` (`:281`), with `loop=working` as the default (`:342`). T7's "wip: before handoff: ready" case reads working.

**Evidence:** `scripts/build-loop.sh:281`, `scripts/build-loop.sh:342`, bats-build-loop-read.log

---

## Claim 10: skip clause "or the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:69-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers branches at least one commit ahead of main. It does not hold for a branch 0 commits ahead whose tip subject starts "handoff:" but is malformed: that reads `working`, not skip.
**Legibility-target:** for-author

marker_kind runs only `if [[ "$ahead" -gt 0 ]]` (`:343`). A probe with main's tip `handoff: bogus` and feat/a == main printed `ok ... feat/a working <sha> ... 0`. The same subject one commit ahead printed `skip ...: its subject is not exactly ...`. The help's marker definition (`:55-56`, "only when the branch is at least one commit ahead") implies this, but the skip clause read alone over-states it. A precise version: "...or, on a branch ahead of main, the tip's subject starts "handoff:" but it is not a marker." Not filed against an override row: no row dated 2026-10-05 mentions the 0-ahead skip case.

**Evidence:** `scripts/build-loop.sh:343-350`, probes2.log ("0-ahead bogus", "1-ahead bogus")

---

## Claim 11: skip clause "for an open brief, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case)"

**Location:** `scripts/build-loop.sh:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default git configuration (and color.ui=auto): open/open pairs in briefs/ and closed/, case folding, CRLF briefs, the skip applying only when the queried brief is open (T28's done brief reads ok), and working-tree-only briefs not counting. It does not hold when color.grep or color.ui is "always" in repo or user config, or when git grep fails. There the skip silently never fires (see Claim 21, the root).
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then echo "skip $a: another open brief ..."` (`:333-334`). Probe results:
- A CRLF brief naming `Feat/X` makes both open briefs skip.
- An open brief in `closed/` counts.
- A brief in `closed/sub/` is ignored, as isbrief requires.

**Evidence:** `scripts/build-loop.sh:333-335`, probes2.log ("plain:"), probe repos/c3, repos/c3b, bats-build-loop-read.log (T28)

---

## Claim 12: "Exit: 0 every line printed (or help); 1 bad usage ..." and "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:74`, `scripts/build-loop.sh:77-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 with skip lines, exit 1 for no mode and for `--status` with no paths, and an unchanged HEAD and working tree after --status. It does not establish that no git-internal file (index stat refresh, objects) is ever touched.
**Legibility-target:** for-orchestrator-synthesis

The usage guard is `--status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage "--status needs at least one brief path"` (`:97`), and `usage()` ends `exit 1` (`:93`). Probe results:
- No arguments: exit 1.
- `--status` alone: exit 1 with the message.
- --status with a symlink skip: exit 0.
- HEAD and `git status --porcelain` were unchanged across a --status run.

**Evidence:** `scripts/build-loop.sh:93-101`, probe repos/c8

---

## Claim 13: "docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE", "dup ID FIRST SECOND" or "near LINE" (the first problem found)."

**Location:** `scripts/build-loop.sh:161-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers CONSTRAINTS_AWK's own outputs and first-problem precedence (`bad == ""` guards). It does not list FENCE_AWK's "odd"/"unbalanced" outputs, which main_file consumes before this reader sees them.
**Legibility-target:** for-orchestrator-synthesis

Every `bad = ...` assignment is guarded by `bad == ""` (`:169-170`, `:176-177`, `:183`). END prints `print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)` after the `odd`/`infence` arms (`:180-184`).

**Evidence:** `scripts/build-loop.sh:164-186`, `scripts/build-loop.sh:131-136`

---

## Claim 14: "# looks like an ID but is not exact" / "# a heading ends a pending one"

**Location:** `scripts/build-loop.sh:176-177`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two inline comments as the code implements them. "Heading" means a column-0 `#` line (see Claim 4).
**Legibility-target:** for-orchestrator-synthesis

`/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }` (`:177`). T44's `'- H1: a' '## Other' '  success: b'` reads nosuccess and passes.

**Evidence:** `scripts/build-loop.sh:176-177`, bats-build-loop-read.log

---

## Claim 15: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER ..., NEVER_LINE and CONSTRAINTS_LINE from main's commit. POLICY is for --status and the planned gate, NEVER for the gate." and "# shellcheck disable=SC2034  # POLICY and NEVER: see above"

**Location:** `scripts/build-loop.sh:197-202`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set of globals assigned, POLICY's one reader (`:332`), NEVER having no reader yet, and shellcheck passing. Two residues remain. The SC2034 disable is now needed only for NEVER, since POLICY is read. "the gate" for NEVER refers to the same planned gate named earlier in the sentence.
**Legibility-target:** for-orchestrator-synthesis

The only `$POLICY` read is `[[ "$POLICY" == self-merge && ... ]]` (`:332`). NEVER is assigned at `:206` and `:242` and never read (paraphrased — no quote available because the claim covers the absence of a reader: `grep -n 'NEVER\b' scripts/build-loop.sh` shows only comments and assignments). `shellcheck -x scripts/build-loop.sh` exited 0 (cwd worktree, 2026-10-05T17:3xZ).

**Evidence:** `scripts/build-loop.sh:197-206`, `scripts/build-loop.sh:242`, `scripts/build-loop.sh:332`

---

## Claim 16: marker_kind header "prints ready, blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY". The caller has checked that the branch is at least one commit ahead of main." and "# git parses the object: its tree, its parents and where the message starts."

**Location:** `scripts/build-loop.sh:273-278`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output set and the single caller's ahead check. It also covers parents and tree via `rev-list --parents` / `rev-parse ^{tree}` and the message via `log %B`. The NUL check still reads the raw object (`git cat-file commit | tr -cd '\000'`), only to count NUL bytes.
**Legibility-target:** for-orchestrator-synthesis

The parse is `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"` and `msg="$(git log -1 --format=%B "$1")"` (`:279-280`). The only caller is `:344` inside `if [[ "$ahead" -gt 0 ]]` (`:343`). T7's two-tree hand-made object reads "it has no parent" and passes.

**Evidence:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:343-344`, bats-build-loop-read.log

---

## Claim 17: "# grep in the C locale: the ranges are ASCII bytes, and no locale is switched here."

**Location:** `scripts/build-loop.sh:293-294`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason regex running under `LC_ALL=C` for that grep only. It does not cover other greps in the script.
**Legibility-target:** for-orchestrator-synthesis

`printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` (`:294`). T6's 120-char reason is accepted, a 121-char reason is refused, and T7's `café`, ESC and RLO reasons are refused. All pass.

**Evidence:** `scripts/build-loop.sh:294`, bats-build-loop-read.log

---

## Claim 18: "Lower-cased branch names that more than one open brief on main (in briefs/ or closed/) names, each between newlines: such briefs are skipped (F31)."

**Location:** `scripts/build-loop.sh:297-298`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set's form (`$'\n'` delimited, lower-cased via `lower`) and its contents under default git config. It does not hold under color.grep/color.ui=always or a failing git grep, where the set is empty (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

`b="$(lower "${BASH_REMATCH[1]}")"; n[$b]=$(( ${n[$b]-0} + 1 ))`, then `SHARED_BRANCHES=$'\n'` and `for b in "${!n[@]}"; do [[ "${n[$b]}" -lt 2 ]] || SHARED_BRANCHES+="$b"$'\n'; done` (`:311-314`).

**Evidence:** `scripts/build-loop.sh:301-315`, bats-build-loop-read.log (T28)

---

## Claim 19: "status_line computes it on first use, so no caller can skip it." and "# first: it reads other briefs into BRIEF"

**Location:** `scripts/build-loop.sh:299`, `scripts/build-loop.sh:318`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers call order, meaning shared_branches runs before check_brief/brief_fields on the queried brief, so BRIEF holds the queried brief's fields at `:324-332` for every argument in a multi-argument run. It does not establish that the computed set is complete (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

The guard is `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` (`:318`). shared_branches always leaves the set non-empty (`SHARED_BRANCHES=$'\n'`, `:313`), so it runs exactly once.

An instrumented copy (scratch `inst/scripts/build-loop.sh`) printed BRIEF just before `:332`. It ran `--status a z d a m` over four briefs, three of them open and listed by git grep. Each DBG line showed the queried brief's own fields:
- `a: Branch: feat/a | Dispatched: 3 | Policy: self-merge`
- `z: Branch: feat/z | Dispatched: 7 | Policy: review`
- `d: ... | Dispatched: 1 | ...`
- `a` again, with its own fields
- `m: ... | Dispatched: 9 | ...`

The output lines matched.

**Evidence:** `scripts/build-loop.sh:316-332`; instrumented run in repos/c4 (this session)

---

## Claim 20: "kept apart so scripts/build-loop.sh can share it" / "kept in a lib so scripts/build-loop.sh can share it"

**Location:** `scripts/lib/dev-cycle-read.sh:2-3`, `scripts/dev-cycle.sh:287`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers build-loop.sh sourcing the lib. It does not cover which lib functions each script uses.
**Legibility-target:** for-orchestrator-synthesis

`READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` … `source "$READ_LIB"` (`scripts/build-loop.sh:87-90`).

**Evidence:** `scripts/build-loop.sh:87-90`

---

## Claim 21: "# One git grep finds the files with a "Status: open" line (a superset: fences are not modelled); brief_fields then reads only those."

**Location:** `scripts/build-loop.sh:304-306`
**Type:** Invariant / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The superset holds under default config (CRLF, NUL, binary attribute, nested dirs, grep.patternType=perl/fixed, grep.fullName, core.quotePath, grep.column and grep.lineNumber were all probed). It fails under color.grep=always or color.ui=always, set in the repo's .git/config or the user's global config, and when git grep exits non-zero. Other git-config keys were not exhaustively probed.
**Legibility-target:** for-author

The list is built by `list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"` and then `f="${f#"$MAIN_SHA":}"`. Each name is passed through `if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi` (`:306-309`) (excerpt ends :309; enclosing shared_branches() continues to :315 — read).

**Color config.** With `color.ui=always` or `color.grep=always`, git grep -l wraps each name in ANSI escapes. Raw output begins `033 [ 3 5 m <sha>:docs/...`. The `${f#"$MAIN_SHA":}` strip and isbrief then fail for every candidate, so the set is empty. Two open briefs naming `feat/x`/`Feat/X` then print `ok ... open review feat/x absent - - 0` instead of the F31 skip. This happens both with the key in .git/config and with `GIT_CONFIG_GLOBAL` holding `[color] ui = always`. The c143b929 ls-tree version, under the same global config, still prints the skip, so this is a regression from fix X1. `color.ui=auto` is unaffected, because the output is a pipe.

**Failing git grep.** `|| true` turns a git grep failure into an empty list. With `grep.patternType=bogus` (exit 128, "fatal: bad grep.patterntype argument") or `grep.threads=-1`, the F31 skip silently disappears and the run still exits 0.

In both cases the set is a subset of the open briefs, not a superset. F31 fails open with no diagnostic. A precise version would force the output format, e.g. `git grep --no-color` or `-c color.grep=false`. It would also refuse (or skip every open brief) when git grep exits with a status other than 0 or 1.

**Evidence:** `scripts/build-loop.sh:301-315`, probes2.log ("## F31 vs git config", "GLOBAL color.ui=always", "OLD c143b929 GLOBAL color.ui=always", "raw grep -l with color.ui=always"); cmd `bash probes2.sh`, cwd fc-r2, exit 0, 2026-10-05T17:35:57Z

---

## Claim 22: fixture comments: commit_all "(an empty commit when nothing changed ...)", constraints, brief, work, and tip "(no cleanup: commit-tree takes it as given) ... By default it is empty (BRANCH's own tree) with BRANCH's tip as its one parent"

**Location:** `test/lib/build-loop-fixtures.bash:21-23`, `test/lib/build-loop-fixtures.bash:29-30`, `test/lib/build-loop-fixtures.bash:42-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each helper's documented effect. It does not cover use outside these suites.
**Legibility-target:** for-orchestrator-synthesis

`commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }` (`:23`). The tip default is `t="$(git rev-parse "$b^{tree}")"; p=(-p "$(git rev-parse "$b")")` (`:64`). The "no cleanup" property was observed: a whitespace-only second line passed through commit-tree intact and was refused by marker_kind (probes2.log).

**Evidence:** `test/lib/build-loop-fixtures.bash:21-66`, probes2.log

---

## Claim 23: bats comments: "A line that looks like a constraint ID but is not exact: unreadable, never skipped (Q-112 [1])"; "A ready marker's body is not read here (the planned --marker reads blocked and stopped bodies)"; the two-tree object comment; "A marker at main's tip with the branch 0 commits ahead is main's, not the loop's"; "So is a branch that is a symbolic ref to main."

**Location:** `test/scripts/build-loop-read.bats:177`, `test/scripts/build-loop-read.bats:256`, `test/scripts/build-loop-read.bats:284-285`, `test/scripts/build-loop-read.bats:295`, `test/scripts/build-loop-read.bats:299`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted behaviours, which pass at HEAD, and the plan's --marker scope. "Never skipped" is established only for the eleven listed shapes (see Claim 5 for the residue).
**Legibility-target:** for-orchestrator-synthesis

The plan says "`--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body" (`docs/working/plan-build-loop-handoff.md:206`), and T32 there says "a `ready` marker → skip" (`:328`). All 16 tests pass.

**Evidence:** `test/scripts/build-loop-read.bats`, `docs/working/plan-build-loop-handoff.md:206`, `docs/working/plan-build-loop-handoff.md:328`, bats-build-loop-read.log

---

## Claim 24: T44 asserts `'- S1: a' '- H1: b'` gives "hard constraint H1 (line 2) has no success: line" (C16: "the END check for a hard constraint with no success: line is tested")

**Location:** `test/scripts/build-loop-read.bats:183-184`; commit 4dc84ce4
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that this assertion kills the mutant with END's nosuccess line (`scripts/build-loop.sh:183`) deleted. It does not cover other mutants.
**Legibility-target:** for-orchestrator-synthesis

The mutant was built in scratch `mut/`, with `scripts/build-loop.sh:183` (`if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl`) removed. `bats -f T44 test/scripts/build-loop-read.bats` (cwd `fc-r2/mut`, exit 1, 2026-10-05T17:34:37Z) failed at line 184 with `constraints ok 1-hard 1-soft`. The unmutated suite passes.

**Evidence:** mut-t44.log, bats-build-loop-read.log

---

## Claim 25: "soft constraint(s)" wording and its bats assertion

**Location:** `scripts/build-loop.sh:265`, `test/scripts/build-loop-read.bats:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the string match between code and test. It does not cover singular/plural grammar beyond the "(s)" form.
**Legibility-target:** for-orchestrator-synthesis

The code's `has $l1 soft constraint(s) and no hard one (H1: with a success: line)` (`:265`) equals the test's expected string, and the test passes.

**Evidence:** `scripts/build-loop.sh:265`, `test/scripts/build-loop-read.bats:161`, bats-build-loop-read.log

---

## Claim 26: 4dc84ce4: "433 changed code lines against main"; c143b929: "426 changed code lines against U1b"; 553a50d5: "U1c stays at 399 changed code lines against U1b"

**Location:** commits 4dc84ce4, c143b929, 553a50d5
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts as added+removed from `--numstat`, excluding docs/reviews. The U1b counts use the current feat/build-loop-u1b tip (3ed87f03) as base, which may differ from the base at commit time.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat main...HEAD -- . ':!docs/reviews'` gives 175+8, 1+1, 2+2, 32+2 and 207+3, which sum to 433. Against feat/build-loop-u1b, c143b929 gives 426 and 553a50d5 gives 399.

**Evidence:** numstat runs in this session (cwd worktree)

---

## Claim 27: 4dc84ce4 X1: "shared_branches read every brief ... (O(every closed brief), 8 s at 500) ... One `git grep -l '^Status: open'` on main now picks the candidates, brief_fields reads only those, and status_line computes the set first."

**Location:** commit 4dc84ce4
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old cost, the new mechanism and its ordering. The quoted pattern is abbreviated (the code's is `^Status: open\r?$` with -E). It does not establish that the candidate set is complete (Claim 21). Timings are machine-dependent.
**Legibility-target:** for-orchestrator-synthesis

`--status` timings with one argument, 3 open briefs and N closed `Status: done` briefs:

| N | 4dc84ce4 | c143b929 |
|---|---|---|
| 0 | 73 ms | 75 ms |
| 50 | 84 ms | 439 ms |
| 200 | 84 ms | 2237 ms |
| 500 | 97 ms | 8659 ms |

The new cost is flat in closed briefs. The old ~8 s at 500 is reproduced. The ordering is verified in Claim 19.

**Evidence:** perf.log (cmd `timeout 120 bash <script> --status docs/working/briefs/2026-10-01-o1.md`, cwd fc-r2/repos/perfN, exit 0 each, 2026-10-05T17:34:30Z)

---

## Claim 28: 4dc84ce4 "A12: a leading task box (`- [x] H2:`) no longer hides a constraint ID"; "Merges main (U1a and U1b landed)."

**Location:** commit 4dc84ce4
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named shape and the merge. Non-GFM box residue is in Claim 5.
**Legibility-target:** for-orchestrator-synthesis

`- [x] H2: x` reads `ok 1-hard` at c143b929 and unreadable at 4dc84ce4 (c1-nearmiss.log and the repos/c1old run). 4dc84ce4's parent is 48663245, "Merge branch 'main' into feat/build-loop-u1c", whose second parent 6a1d3fdb sits above 62830b0a (U1b merge) and adff525b (U1a merge).

**Evidence:** c1-nearmiss.log; `git log --graph` in this session

---

## Claim 29: aaae80c6: "The real briefs have no Branch: line yet, so --status skips them"; "The lib is called in-process"; "--status over the 3 real briefs: 79 ms"; "check_brief's `git log -1 -G'^Status: '` costs about 1 ms per brief"

**Location:** commit aaae80c6
**Type:** Behavioral / Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The verdict is carried by the two timing atoms. They are time- and machine-varying: as of 2026-10-05T17:35Z this run measured 104 ms over the 3 real briefs, with locale warnings. The skip and in-process atoms are Verified.
**Legibility-target:** for-orchestrator-synthesis

`bash scripts/build-loop.sh --status docs/working/briefs/*.md` (cwd worktree) printed `skip ...: no Branch: line on the default branch` for all three briefs. `source "$READ_LIB"` (`scripts/build-loop.sh:90`) loads the lib in-process. The two timing figures were not split into separate claims. The per-brief ~1 ms needs the commit-time repo state and machine to verify.

**Evidence:** `scripts/build-loop.sh:90`; run in this session

---

## Claim 30: c143b929 A1: "marker_kind lets git parse the commit (rev-list --parents, rev-parse ^{tree}, log %B) instead of reading the raw object, and refuses a NUL byte"; 859e29e8/c143b929 test descriptions (T5-T8, T21, T28)

**Location:** commits c143b929, 859e29e8
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** At HEAD, the mechanism matches (Claim 16, with the raw read kept only for NUL counting), and the test descriptions match passing tests. Whether they matched at those historical commits was not re-run, so the historical-state atom is the one left Unverifiable.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the claim describes the state at a historical commit, and only HEAD was executed. At HEAD: `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"` (`scripts/build-loop.sh:279`) and `git cat-file commit "$1" | tr -cd '\000' | wc -c` (`:282`).

**Evidence:** `scripts/build-loop.sh:279-285`

---

## Claims Requiring Attention

### Incorrect
- **Claim 21** (`scripts/build-loop.sh:304-306`): The git grep candidate list is not a superset of the open briefs. With color.grep/color.ui=always (repo or user global config), every name carries ANSI escapes and fails isbrief. A failing git grep (exit 128) is swallowed by `|| true`. Either way F31's same-branch skip silently disappears, which is fail-open. The c143b929 ls-tree version kept the skip under the same color config. Fix: force `--no-color` (or `-c color.grep=false`), and treat a git grep exit other than 0/1 as an error.

### Stale
- None.

### Mostly Accurate
- **Claim 10** (`scripts/build-loop.sh:69-71`): The "handoff:" skip clause applies only to a branch ahead of main. A 0-ahead tip with a malformed "handoff:" subject reads working. Add "on a branch ahead of main" (or similar).

### Unverifiable
- **Claim 3** (`scripts/build-loop.sh:30`, `:38`): "every loop prompt carries" and "Only ok lets the orchestrator dispatch" describe planned --prompt/--start behaviour (plan :44, :173). These need U3/U4.
- **Claim 29** (aaae80c6): The 79 ms and ~1 ms/brief timings are time- and machine-varying. Today's run gives 104 ms for the 3 real briefs.
- **Claim 30** (c143b929, 859e29e8): Historical-state claims. They match at HEAD, but the historical commits were not re-run.

---

## Goal-Alignment Note

The goal is a final confirming review of U1c at 4dc84ce4 before merge. This pass verified every brief item by execution. X1's mechanism and ordering hold, BRIEF is not clobbered, the 8 s to 97 ms improvement is real, A12's task box is refused, and C16's test kills the END mutant. It found one new defect introduced by X1 itself (Claim 21): git grep's output depends on color config, and its exit status is discarded. As a result F31 fails open under a user's `color.ui = always` or a broken `grep.*` key. No override-log row covers it; the rows dated 2026-10-05 predate the git grep. The A12 residue (`[x ]`, `[y]`, `(x)` prefixes) falls in override row 290's prose-word-prefix family, so it is noted and not filed. The 0-ahead wording point (Claim 10) is minor. No tracked file other than this report was edited, and no probe process remains running.
