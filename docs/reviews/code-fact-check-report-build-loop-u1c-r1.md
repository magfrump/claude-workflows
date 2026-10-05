Commit: c143b929

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** unit diff `feat/build-loop-u1b...feat/build-loop-u1c` at HEAD c143b929: comments, help text and test names/comments in scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats; commit messages of 859e29e8, aaae80c6, 553a50d5, c143b929. docs/reviews/ artifacts are out of scope. Settled classes not re-filed: DATE format (override row 274), the 79 ms timing and U3/U4 claim (row 275), claims in already-merged commit messages of the A11 class (row 265; this includes aaae80c6's "single-parent" marker wording, whose two-tree exception c143b929's A1 fixed).
**Checked:** 2026-10-05
**Total claims checked:** 44
**Summary:** 37 verified, 4 mostly accurate, 0 stale, 0 incorrect, 3 unverifiable

Hallucination-pattern log (docs/reviews/hallucination-patterns.md) read first. No claim matches a logged pattern. The closest class, "a specific measured value quoted from a checked-in artifact set", was checked for each count in the commit messages: 426, 399, 2137/1017 and the test counts. All of them reproduce (Claims 34c, 35, 36f).

## Execution runs (provenance)

All logs are under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/fc-r1/` (abbreviated `fc-r1/`). Probe repos were built there with a hermetic git environment (`fc-r1/env.sh`: GIT_CONFIG_GLOBAL=/dev/null, GIT_CONFIG_NOSYSTEM=1, LC_ALL=C, the fixtures' helpers copied verbatim). Each run calls `bash /workspace/.claude/wt-build-loop-u1c/scripts/build-loop.sh` under `timeout 30`.

| Run | Command | cwd | Exit | Time (UTC) | Log |
|---|---|---|---|---|---|
| E1 | `LC_ALL=C.UTF-8 timeout 600 bats test/scripts/build-loop-read.bats` | /workspace/.claude/wt-build-loop-u1c | 0 (16/16 ok) | 2026-10-05T16:46:59Z | fc-r1/bats-read.log |
| E2 | 33 one-line near-miss shapes after `- H1: a` / `  success: b`, then `--settings` | fc-r1/p-constraints | 0 | 2026-10-05T16:48:01Z | fc-r1/constraints-shapes.log |
| E3 | 16 fence/heading/success/dup layouts, then `--settings` | fc-r1/p-constraints2 | 0 | 2026-10-05T16:48:11Z | fc-r1/constraints-structure.log |
| E4 | `timeout 300 bash ./status-probe.sh` (P1-P21: crafted marker objects, working-tree symlinks, F31, read-only, help, no default branch) | fc-r1 (repo fc-r1/p-status) | 0 | 2026-10-05T16:50:15Z | fc-r1/status-probe.log (script fc-r1/status-probe.sh) |
| E5 | `LC_ALL=en_US.UTF-8` (not installed) `--status` with HEAD and with 553a50d5's script | fc-r1/p-status | 0 / 0 | 2026-10-05T16:50:58Z | fc-r1/locale.log |
| E6 | 553a50d5's script (from `git archive`) vs HEAD on near-miss, heading, two-tree and closed/ fixtures | fc-r1/p-old | 0 | 2026-10-05T16:51:14Z | fc-r1/old-vs-new.log |
| E7 | `LC_ALL=C.UTF-8 timeout 600 bats test/scripts/build-loop-read.bats` on `git archive 859e29e8` | fc-r1/old-859e29e8 | 1 | 2026-10-05T16:51:21Z | fc-r1/bats-859e29e8.log |
| E8 | letter-prefixed shapes (`- [x] H2:`, `a) H2:`, `Note: H2:` ...), then `--settings` | fc-r1/p-constraints3 | 0 | 2026-10-05T16:52:12Z | fc-r1/constraints-letterprefix.log |
| E9 | `tip x $'handoff: ready \n# comment\n\n\ntrailing   '` then `git cat-file commit x \| od -c` | fc-r1/p-tip | 0 | 2026-10-05T16:52:16Z | fc-r1/tip-cleanup.log |
| E10 | numstat counts, rev-list counts, Branch: lines in briefs at aaae80c6, git log -G timing x20, `shellcheck -x scripts/build-loop.sh`, status_of grep | /workspace/.claude/wt-build-loop-u1c | 0 | 2026-10-05T16:53Z | fc-r1/static-counts.log |

---

## Claim 1: "Usage: scripts/build-loop.sh --settings / scripts/build-loop.sh --status BRIEF..." and the usage error "(usage: build-loop.sh --settings | --status BRIEF...)"

**Location:** `scripts/build-loop.sh:6-7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two modes the parser accepts and the usage text printed on error. It does not establish -h output beyond the lines E4/P20 printed.
**Legibility-target:** for-orchestrator-synthesis

The parser at `scripts/build-loop.sh:93-99` accepts `--settings) ... [[ $# -eq 1 ]]`, `--status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage ...`, and `-h|--help`. `usage()` at :91 prints `"$1 (usage: build-loop.sh --settings | --status BRIEF...)"`. In E1, test 9's loop over `"" "--bogus" "--settings extra" "--status"` asserts exit 1, empty stdout and non-empty stderr. E4/P20 shows `--help` printing the `--status` block.

**Evidence:** `scripts/build-loop.sh:6-8`, `scripts/build-loop.sh:91-99`, fc-r1/bats-read.log (E1), fc-r1/status-probe.log P20 (E4)

---

## Claim 2: "--settings  four lines from the default branch's commit, never the working tree"

**Location:** `scripts/build-loop.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and order of the lines and the working-tree exclusion for docs/constraints.md (the other three lines are U1b's). It does not establish behaviour under replace refs, which is U1b's settled hardening.
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:355` is `printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"`. main_file reads `git cat-file blob "$MAIN_SHA:$f"` (`:128`). E1 passes test 9 (`"${#lines[@]}" -eq 4`, in order) and test 8. Test 8 writes `docs/constraints.md` only in the working tree and asserts `constraints missing`.

**Evidence:** `scripts/build-loop.sh:117-134`, `scripts/build-loop.sh:254-267`, `scripts/build-loop.sh:355`, `test/scripts/build-loop-read.bats:359-366`, fc-r1/bats-read.log (E1)

---

## Claim 3: "constraints ok N-hard M-soft|missing|none-hard|unreadable: WHY"

**Location:** `scripts/build-loop.sh:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four first words and the `N-hard M-soft` shape. It does not establish wording beyond the strings E1–E3 printed. Note: a file holding no constraints at all reports `none-hard ... has 0 soft constraints`, which the help does not single out.
**Legibility-target:** for-orchestrator-synthesis

`:261` builds `"constraints ok $c-hard $l1-soft: $f on the default branch"`, and `:262` gives `none-hard` when `$c` is 0. `:256` gives `missing` for an absent file. `:257` and `:263-265` give `unreadable`. E1, E2 and E3 printed all four, for example `constraints ok 2-hard 1-soft: docs/constraints.md on the default branch` (test 8).

**Evidence:** `scripts/build-loop.sh:254-267`, fc-r1/constraints-shapes.log, fc-r1/constraints-structure.log, fc-r1/bats-read.log

---

## Claim 4: "docs/constraints.md, which every loop prompt carries"

**Location:** `scripts/build-loop.sh:30`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only that the plan states this. It does not establish any loop-prompt code, because none exists in U1. Blocker: the loop prompt (`--prompt`/`--start`) is U3's work and is not in this tree.
**Legibility-target:** for-orchestrator-synthesis

`docs/working/plan-build-loop-handoff.md:44` reads: "Every loop prompt carries `docs/constraints.md` from main's commit." A grep finds no `--prompt` mode in `scripts/build-loop.sh` (paraphrased; no quote is available because the claim is about code that is absent: `case "$MODE"` at :348-357 has only `status` and `settings`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:44`, `scripts/build-loop.sh:348-357`

---

## Claim 5: "A constraint is a line "H<n>: text" (hard) or "S<n>: text" (soft) at column 0, optionally after "- ", n without a leading 0"

**Location:** `scripts/build-loop.sh:30-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-line pattern, including multi-digit IDs (H12) and the requirement for one space followed by a non-blank. It does not establish how near-miss lines are treated (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:164` matches `/^(- )?[HS][123456789][0123456789]*: [^ \t]/`. In E3, `H3:` and `H12:` each with a success line gave `ok 3-hard`. In E2, `H01: x`, `S01: x`, `H2:  x` and `- H2: ` were all refused as near misses.

**Evidence:** `scripts/build-loop.sh:161-183`, fc-r1/constraints-structure.log, fc-r1/constraints-shapes.log

---

## Claim 6: "a hard one needs a "success: <observable>" line (any indent, optionally after "- ") before the next constraint or heading" (with the code comment "a heading ends a pending one")

**Location:** `scripts/build-loop.sh:33-35`, `scripts/build-loop.sh:174`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the success-line pattern and the ending of a pending hard constraint by a later constraint or by a column-0 `#` line. It does not hold for every Markdown heading: setext headings and ATX headings indented 1-3 spaces do not end a pending constraint, and a non-heading `#hashtag` line does.
**Legibility-target:** for-author

The heading rule is `/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }` (`scripts/build-loop.sh:174`), so only a line that starts with `#` at column 0 counts as a heading. E3 gave these results:
- `'- H1: a' 'Other' '=====' '  success: b'` printed `constraints ok 1-hard 0-soft`: a success line under a setext-headed section satisfied H1.
- `'- H1: a' '   ## Other' '  success: b'` printed the same `ok`. CommonMark treats this line as a heading.
- `'- H1: a' '#hashtag' '  success: b'` printed `unreadable ... no success: line`. CommonMark does not treat this line as a heading (no space after `#`). The error is in the fail-closed direction.

The success pattern at `:175` is `/^[ \t]*(- )?success: [^ \t]/`. E3 confirmed it accepts tab indent, `- success:` and `  - success:`, and refuses `> success:`, `Success:` and `success:  b`. Precise version: "before the next constraint or the next line starting with #".

**Evidence:** `scripts/build-loop.sh:172-175`, fc-r1/constraints-structure.log (E3)

---

## Claim 7: "no ID may repeat"

**Location:** `scripts/build-loop.sh:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact repeats of an ID across hard and soft constraints. It does not cover IDs that differ only by a leading 0, which are refused as near misses instead (Claim 36a).
**Legibility-target:** for-orchestrator-synthesis

`:167` is `if (bad == "" && (id in seen)) bad = "dup " id " " seen[id] " " NR`. In E3, `S1: c` / `S1: d` gave `constraint S1 is listed twice (lines 3 and 4)`. In E1, test 8 asserts the H1 case.

**Evidence:** `scripts/build-loop.sh:165-168`, fc-r1/constraints-structure.log, fc-r1/bats-read.log

---

## Claim 8: "Any other line whose letters and digits, from its first letter, start like "h1" or "s1" makes the file unreadable."

**Location:** `scripts/build-loop.sh:35-37`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every ASCII near-miss shape the brief listed, outside code fences: each one makes the file unreadable. The claim does not hold for lines inside a code fence or for non-ASCII letters and digits; for both, the file still reads `constraints ok` with the line uncounted.
**Legibility-target:** for-author

The code is `{ s = $0; sub(/^[^a-zA-Z]*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }` and `s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }` (`scripts/build-loop.sh:172-173`). awk runs under `env LC_ALL=C` (`:128`), so "letter" means ASCII a-z, and the rule sits behind `fence($0) { next }` (`:163`).

In E2, every shape the brief listed gave `unreadable: line 3 looks like a constraint`: `* H2:`, `1. H2:`, `H2:  x`, `H2:<TAB>x`, `  H2:`, `h2:`, `**H2:**`, `### H2:`, `> H2:`, `H10 :`, `| H2: x |`, `H01:`. So did `<!-- H2: x -->`, `` `H2: x` ``, `+ H2:`, `-H2:`, `H 2:`, fullwidth colons and `~~H2~~:`.

Three kinds of line still leave `constraints ok 1-hard 0-soft`:
- **Non-ASCII letters or digits.** E2 shows this for Cyrillic `Н2: x`, fullwidth `Ｈ2: x` and Arabic-Indic `H٢: x`. The help says "letters and digits" without "ASCII".
- **Lines inside a code fence.** E3 shows this for ```` ``` ```` / `H2: x` / ```` ``` ```` and `~~~` / `- H2: x` / `~~~`. The help says "Any other line".
- **Lines whose first ASCII letter is not h or s.** E8 shows this for `- [x] H2: never drop rows`, `a) H2: x`, `Note: H2: x` and `Hx2: x`. This matches the help's literal rule ("from its first letter") and the best-effort detection the user accepted in Q-112 [1]. It is listed here because the brief asks whether a hard-looking line can still vanish under `ok`, and these lines do.

The precise version would read: "Any other line outside a code fence whose ASCII letters and digits ...".

**Evidence:** `scripts/build-loop.sh:128`, `scripts/build-loop.sh:161-175`, `scripts/lib/dev-cycle-read.sh:213-229`, fc-r1/constraints-shapes.log (E2), fc-r1/constraints-structure.log (E3), fc-r1/constraints-letterprefix.log (E8)

---

## Claim 9: "Only "ok" lets the orchestrator dispatch."

**Location:** `scripts/build-loop.sh:37`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only agreement with the plan. It does not establish any dispatch code. Blocker: `--start` (U3) and the orchestrator skill (U4) do not exist yet.
**Legibility-target:** for-orchestrator-synthesis

`docs/working/plan-build-loop-handoff.md:340` (T44) reads "`--start` refuses unless `ok`". Line :173 (F55) reads "`--start` refuses (T44)". No `start` mode exists in `scripts/build-loop.sh:348-357`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:173`, `docs/working/plan-build-loop-handoff.md:340`, `scripts/build-loop.sh:348-357`

---

## Claim 10: "--status  one line per brief path, in argument order, from the default branch's commit (the path must also be plain in the working tree, as --check-brief)"

**Location:** `scripts/build-loop.sh:42-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers argument order, main-commit reads, and the plainness check on each argument path. Two limits apply: "plain" passes a path that is absent from the working tree (E4/P15 prints ok), and the other briefs read for F31 are never checked in the working tree (E4/P16, where a symlinked other brief still counts). The help claims neither.
**Legibility-target:** for-orchestrator-synthesis

`status_line` begins `out="$(check_brief "$a")"` (`:312`). check_brief runs `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"` (`scripts/lib/dev-cycle-read.sh:329`) and then reads only from main. In E4/P14, a working-tree symlink at the brief path gave `skip ...: reached through a symlink, or not a regular file`. In E1, T28 asserts six lines in argument order and T21 asserts that working-tree and branch edits are ignored. The lite-drift concern ("unenforced because shared_branches no longer calls main_entry") is refuted: the working-tree check is check_brief's blocker call. It never involved shared_branches.

**Evidence:** `scripts/build-loop.sh:310-316`, `scripts/build-loop.sh:349-352`, `scripts/lib/dev-cycle-read.sh:107-117`, `scripts/lib/dev-cycle-read.sh:321-360`, fc-r1/status-probe.log P14-P16, fc-r1/bats-read.log

---

## Claim 11: "STATE: open, done or dropped (dev-cycle.sh --check-brief), or new when main has no file there (then "new review - absent - - 0")"

**Location:** `scripts/build-loop.sh:46-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the state source and the literal `new` line. It does not cover a brief already moved to closed/, which also reads as new; that case is settled by row 272.
**Legibility-target:** for-orchestrator-synthesis

`:315` is `if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi`. check_brief is the same lib function that dev-cycle.sh calls for `--check-brief` (`scripts/dev-cycle.sh:201` `--check-brief) check_brief "$a" ;;`). In E1, T8 asserts `ok docs/working/briefs/2026-10-01-none.md new review - absent - - 0`.

**Evidence:** `scripts/build-loop.sh:312-315`, `scripts/dev-cycle.sh:201`, fc-r1/bats-read.log

---

## Claim 12: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"; else review."

**Location:** `scripts/build-loop.sh:48-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 2x5 matrix in T5 and the malformed-never case. It does not cover a Policy: line inside a fence, which brief_fields skips.
**Legibility-target:** for-orchestrator-synthesis

`:325` is `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge`. brief_fields keeps the first `Policy:` line outside a fence (`scripts/lib/dev-cycle-read.sh:300-301`). T5 passes in E1.

**Evidence:** `scripts/build-loop.sh:325`, `scripts/lib/dev-cycle-read.sh:289-312`, fc-r1/bats-read.log

---

## Claim 13: "BRANCH: from the brief's first "Branch: NAME" line. LOOP: absent (no such branch), working, ready, blocked or stopped, from the branch tip (SHA, with DATE its commit date as YYYY-MM-DD; "-" when absent)."

**Location:** `scripts/build-loop.sh:50-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field sources and the absent form. It does not establish that DATE is always YYYY-MM-DD for a crafted committer line (settled by row 274).
**Legibility-target:** for-orchestrator-synthesis

`:318-319` is `[[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]] ... br="${BASH_REMATCH[1]}"`. `:332` is `"absent "*) echo "ok $a $st $pol $br absent - - $disp"`. `:333` reads sha, ahead and date from check_branch, which uses `git log -1 --format=%cs` (`scripts/lib/dev-cycle-read.sh:380`). T6 asserts every field for absent, working (0 ahead and ahead), ready, blocked and stopped, and passes in E1.

**Evidence:** `scripts/build-loop.sh:316-345`, `scripts/lib/dev-cycle-read.sh:370-383`, fc-r1/bats-read.log

---

## Claim 14: "A tip is a marker only when the branch is at least one commit ahead of main and the tip is an empty commit with one parent whose subject is exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (1-120 printable ASCII characters, no blank at either end), alone on its first line; REASON is printed last. Any other tip is working."

**Location:** `scripts/build-loop.sh:54-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ahead gate, emptiness, the parent count, the exact subjects, the REASON grammar (1 and 120 characters accepted, 121 refused, tab, CR and latin-1 refused), and "alone on its first line". The last is enforced strictly: a whitespace-only second line is refused. "Any other tip is working" holds only for tips whose subject does not start "handoff:"; a "handoff:" tip that fails a rule is a skip, as :67-69 says.
**Legibility-target:** for-orchestrator-synthesis

The ahead gate is `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`:337-338`). Emptiness is checked by `git rev-parse --verify "$1^{tree}"` against `"${p[1]}^{tree}"` (`:282`). Parent count is checked at `:280-281`. The REASON grammar is `LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` (`:291`).

E4 results:
- P10 (`stopped: x`) printed `... stopped <sha> <date> 0 x`.
- P8 (CR), P9 (tab) and P12 (an `encoding ISO-8859-1` header with `caf\xe9`) each gave `skip ... its subject is not exactly`.
- P2 (`handoff: ready` / `   ` / `body`) gave `skip ... its subject runs onto a second line`. git would treat a whitespace-only line as a paragraph break, so the script is stricter than git here, in the fail-closed direction.
- P6 (one parent listed twice) gave `it has 2 parents`.

In E1, T6 accepts the 120-character reason, and T7 rejects the 121-character reason, content, merge, orphan and two-line shapes. T7 also covers a 0-ahead marker at main's tip, which reads as working.

**Evidence:** `scripts/build-loop.sh:273-293`, `scripts/build-loop.sh:336-345`, fc-r1/status-probe.log P2-P12, fc-r1/bats-read.log

---

## Claim 15: "DISPATCHED: the brief's "Dispatched: N" (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:60-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the value range and the default. It does not cover a Dispatched: line inside a fence, which brief_fields skips.
**Legibility-target:** for-orchestrator-synthesis

The local default is `disp=0` (`:311`). `:321` is `=~ ^Dispatched:\ (0|[123456789][0123456789]?)$`. T6 asserts `2`. T5 and T28 assert `0` when the line is missing. T8 refuses `x`, `100`, `01`, `-1` and `Dispatched:`. All pass in E1.

**Evidence:** `scripts/build-loop.sh:311`, `scripts/build-loop.sh:320-324`, fc-r1/bats-read.log

---

## Claim 16a: "skip BRIEF: WHY — The brief cannot be read (as --check-brief), its Branch: line is missing or malformed or its Dispatched: line malformed, its branch name is refused (as --check-branch), ... or the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:62-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed skip cause other than F31 (see 16b) and the "first line" definition of the subject. It does not claim to match git's own `%s`. A message that starts with a blank line has git subject "handoff: ready" but reads as working here, which matches the help's "first line" wording.
**Legibility-target:** for-orchestrator-synthesis

The code uses `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (`:313`), the Branch checks at `:317-318`, the Dispatched check at `:321-322`, `*) echo "skip $a: Branch: ${out#*: }"` (`:334`), and `bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ..."` (`:340`). The subject is `msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"` (`:277`).

In E4/P1, a raw message `\n\nhandoff: ready` makes `%B` start `\n handoff: ready`, and --status printed `working`. In E1, T8 covers every brief-side cause, including `Branch: main`, `HEAD`, `refs/heads/x`, `a..b`, `-x` and non-ASCII.

**Evidence:** `scripts/build-loop.sh:310-345`, fc-r1/status-probe.log P1, fc-r1/bats-read.log

---

## Claim 16b: "another open brief on main, in briefs/ or closed/, names the same branch (ignoring case)" (as a skip cause)

**Location:** `scripts/build-loop.sh:66-67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip of an open brief when another open brief on main (briefs/ or closed/) names its branch, compared ignoring ASCII case. It does not cover done or dropped briefs: they are never skipped for this cause, even when open briefs name the same branch.
**Legibility-target:** for-author

The code is `if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]` (`scripts/build-loop.sh:327`). The skip needs the brief itself to be open.

In E4/P17, done brief c (`Branch: feat/a`) printed `ok ... done review feat/a working ...` while two open briefs named feat/a. In P18, the same done brief printed `ok` while one other open brief named feat/a. Read literally, the help predicts a skip in both cases: "another open brief ... names the same branch". T28 asserts the done case prints ok (`test/scripts/build-loop-read.bats:561`), so the code is intended.

Precise version: "the brief is open and another open brief on main ... names the same branch".

**Evidence:** `scripts/build-loop.sh:298-309`, `scripts/build-loop.sh:326-329`, `test/scripts/build-loop-read.bats:553-561`, fc-r1/status-probe.log P17-P18

---

## Claim 17: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:72`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one run each of `--status` (two briefs) and `--settings` on a probe repo: `.git` and the working tree were unchanged. It does not establish behaviour under hooks or a git that writes on reads, such as fsmonitor or commit-graph auto-write configured by the caller.
**Legibility-target:** for-orchestrator-synthesis

In E4/P19, `ls -laR .git` was captured before and after the two runs and `cmp` reported `.git unchanged`. `git status --porcelain` printed nothing. The git subcommands in the new code are all reads (paraphrased; no single quote is available because they span `:276-282`, `:301`, and the lib's check_brief/check_branch: rev-list, log, cat-file, rev-parse, ls-tree, show-ref).

**Evidence:** `scripts/build-loop.sh:273-309`, fc-r1/status-probe.log P19

---

## Claim 18: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:75-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 for --status across every probe in E4, which included skip lines, crafted objects and a non-hex parent, and exit 1 for usage errors and a missing default branch under --status and --settings. It does not cover the no-perl path, which was not run.
**Legibility-target:** for-orchestrator-synthesis

In E4, every P-run printed `[exit 0]` except P21. In P21, after `git branch -m main trunk`, the output was `build-loop.sh needs a default branch found by name ...` with `[exit 1]`. In E1, test 9 asserts exit 1 for usage errors, a missing default branch and a path outside a git repo.

**Evidence:** `scripts/build-loop.sh:91-111`, fc-r1/status-probe.log, fc-r1/bats-read.log

---

## Claim 19: "docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE", "dup ID FIRST SECOND" or "near LINE" (the first problem found)." (with the case arms that render them)

**Location:** `scripts/build-loop.sh:158-159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four output forms, the rendering arms at :259-266, and the `*)` catch-all, which only `near` reaches; `odd` and `unbalanced` make main_file return 1 first. "First problem found" means first detected in line order, so a pending nosuccess is detected only at the next constraint, heading or end of file.
**Legibility-target:** for-orchestrator-synthesis

The END block prints `print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)` (`:181`). Each setter is guarded by `bad == ""`. `:259` is `read -r k c l1 l2 <<<"$FILE_OUT"`. The arms render `ok` (`:261-262`), `nosuccess` (`:263`), `dup` (`:264`) and `*)` with `line $c` (`:265`). main_file returns 1 for `odd\ *` and `unbalanced\ *` (`:131-132`). E1, E2 and E3 printed each rendering.

**Evidence:** `scripts/build-loop.sh:117-134`, `scripts/build-loop.sh:161-183`, `scripts/build-loop.sh:254-267`, fc-r1/constraints-shapes.log, fc-r1/constraints-structure.log

---

## Claim 20: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (...), NEVER_LINE and CONSTRAINTS_LINE from main's commit. POLICY is for --status and the gate, NEVER for the gate."

**Location:** `scripts/build-loop.sh:194-197`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the six variables set and the current readers: POLICY is read by status_line, and NEVER has no reader yet. The gate is future U2/U3 work, so its use of the two variables is not established. shellcheck -x passes (E10).
**Legibility-target:** for-orchestrator-synthesis

The initialisation `POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=(); NEVER_LINE=""; CONSTRAINTS_LINE=""` is at `:198`. CONSTRAINTS_LINE is set at `:256-265`. The only POLICY read is `[[ "$POLICY" == self-merge && ...` (`:325`). NEVER is only assigned, at `:203` and `:239` (a grep in E10 found no other use).

**Evidence:** `scripts/build-loop.sh:194-268`, `scripts/build-loop.sh:325`, fc-r1/static-counts.log

---

## Claim 21: "The tip SHA of a brief's branch, read as a handoff marker: prints ready, blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY". The caller has checked that the branch is at least one commit ahead of main."

**Location:** `scripts/build-loop.sh:270-272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers marker_kind's five output forms and its one caller's ahead check. It does not establish the ahead count's behaviour under grafts or shallow files (settled by row 273).
**Legibility-target:** for-orchestrator-synthesis

The outputs are `echo working` (`:278`), the `bad ...` lines (`:279-284`, `:292`), `echo ready` and `echo blocked` (`:286-287`) and `echo "stopped $r"` (`:291`). The only caller guards with `if [[ "$ahead" -gt 0 ]]` (`:337`); grep finds no other `marker_kind` call (paraphrased; no quote is available because the claim covers absence of other callers). E4 exercised every form.

**Evidence:** `scripts/build-loop.sh:273-293`, `scripts/build-loop.sh:336-344`, fc-r1/status-probe.log

---

## Claim 22: "git parses the object: its tree, its parents and where the message starts."

**Location:** `scripts/build-loop.sh:275`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent list (rev-list --parents), the tree (rev-parse ^{tree}) and the message (log %B) as git's own parser sees them on crafted objects. The NUL check still reads the raw object (`git cat-file commit ... | tr -cd '\000'`, :279), and a non-hex parent cannot be reached at all because update-ref refuses the object.
**Legibility-target:** for-orchestrator-synthesis

The code is `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"` and `msg="$(git log -1 --format=%B "$1")"` (`:276-277`). E4 results:
- P7 (two tree lines, then a parent): `rev-list` printed only the commit id, and --status gave `it has no parent`.
- P5 (parent line after author): the same.
- P3 (NUL in the message): `it holds a NUL byte`.
- P4 (non-hex parent): `git update-ref` failed with `bad parents in commit`, so no branch can point at such an object.

**Evidence:** `scripts/build-loop.sh:273-284`, fc-r1/status-probe.log P3-P7

---

## Claim 23: "grep in the C locale: the ranges are ASCII bytes, and no locale is switched here."

**Location:** `scripts/build-loop.sh:290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of any shell-level locale switch in marker_kind and of any warning from it under an uninstalled caller locale. The two bash start-up warnings that remain come from bash itself and are identical for --settings.
**Legibility-target:** for-orchestrator-synthesis

The code is `printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` (`:291`), a per-command environment for the external grep. In E5, under `LC_ALL=en_US.UTF-8` (not installed), HEAD's --status on a stopped marker printed two `bash: warning: setlocale` lines. A --settings run in the same session also printed two, so neither comes from marker_kind. 553a50d5's script printed a third, `build-loop.sh: line 323: warning: setlocale`, from its `local LC_ALL=C` (`old-553a50d5/scripts/build-loop.sh:277`).

**Evidence:** `scripts/build-loop.sh:289-292`, fc-r1/locale.log (E5)

---

## Claim 24: "Lower-cased branch names that more than one open brief on main (in briefs/ or closed/) names, each between newlines: such briefs are skipped (F31). status_line computes it on first use, so no caller can skip it."

**Location:** `scripts/build-loop.sh:294-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set's contents and format, closed/ inclusion, main-only reading, and lazy computation before the F31 check. Lower-casing is ASCII only, through `tr`; branch names are ASCII anyway because check_branch refuses others. The set is computed once per process.
**Legibility-target:** for-orchestrator-synthesis

The code lists `git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/ docs/working/briefs/closed/` (`:301`) and filters with `isbrief "${f/closed\//}"` (`:303`). It sets `SHARED_BRANCHES=$'\n'` and appends `"$b"$'\n'` for counts of 2 or more (`:307-308`). `:326` is `[[ -n "$SHARED_BRANCHES" ]] || shared_branches`, which runs before the check at `:327`.

In E6, an open brief in closed/ naming feat/a gave `ok ... working` under 553a50d5 and `skip ...: another open brief` under HEAD. In E1, T28 passes, including the closed/ case and the working-tree-only case. In E4/P16, a brief on main that is a symlink in the working tree still counts, consistent with "on main".

**Evidence:** `scripts/build-loop.sh:297-309`, `scripts/build-loop.sh:326-329`, `scripts/lib/dev-cycle-read.sh:430`, fc-r1/old-vs-new.log, fc-r1/status-probe.log P16, fc-r1/bats-read.log

---

## Claim 25: "The reader, kept in a lib so scripts/build-loop.sh can share it" / "kept apart so scripts/build-loop.sh can share it"

**Location:** `scripts/dev-cycle.sh:278`, `scripts/lib/dev-cycle-read.sh:2-3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that build-loop.sh exists and sources the lib. It does not cover which lib functions each script uses.
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:85-88` is `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` ... `source "$READ_LIB"`. The word "planned" is gone from both files (the E10 grep found no hit).

**Evidence:** `scripts/build-loop.sh:82-89`, `scripts/dev-cycle.sh:278`, `scripts/lib/dev-cycle-read.sh:1-5`

---

## Claim 26: "commit_all [MSG]: stage everything and commit it on the current branch (an empty commit when nothing changed, so rewriting a file as it was still works)."

**Location:** `test/lib/build-loop-fixtures.bash:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --allow-empty behaviour. It does not cover hooks, which the hermetic config disables.
**Legibility-target:** for-orchestrator-synthesis

The helper is `commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }` (`:23`). T5 rewrites the same settings file in a loop, and passes in E1.

**Evidence:** `test/lib/build-loop-fixtures.bash:21-23`, `test/scripts/build-loop-read.bats:522-531`, fc-r1/bats-read.log

---

## Claim 27: helper comments for constraints, brief and work ("docs/constraints.md holding these lines, committed"; "docs/working/briefs/2026-10-01-SLUG.md holding a title and these lines, committed on the current branch; sets B to its path"; "BRANCH from main with one commit that changes a file")

**Location:** `test/lib/build-loop-fixtures.bash:29`, `test/lib/build-loop-fixtures.bash:42-43`, `test/lib/build-loop-fixtures.bash:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what each helper writes and commits. It does not cover failure modes such as an existing branch name passed to work.
**Legibility-target:** for-orchestrator-synthesis

The helpers are `printf '%s\n' "$@" > docs/constraints.md && commit_all constraints` (`:30`), `printf '# Brief: %s\n\n' "$s" > "$B" && printf '%s\n' "$@" >> "$B"` (`:47`), and `git branch -q "$1" main` then `echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1"` (`:53-54`). E4 used verbatim copies of these helpers, and E1 used the originals.

**Evidence:** `test/lib/build-loop-fixtures.bash:29-55`, fc-r1/env.sh, fc-r1/bats-read.log

---

## Claim 28: "tip BRANCH MESSAGE [TREE [PARENT...]]: a commit with MESSAGE and a newline (no cleanup: commit-tree takes it as given) on BRANCH's tip. By default it is empty (BRANCH's own tree) with BRANCH's tip as its one parent; pass TREE and the parents ("" for none) to build anything else."

**Location:** `test/lib/build-loop-fixtures.bash:57-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers message preservation (trailing blanks, `#` lines and blank runs are kept) and the default tree and parent. It does not cover a message that holds a NUL, which printf would cut.
**Legibility-target:** for-orchestrator-synthesis

The helper is `git update-ref "refs/heads/$b" "$(printf '%s\n' "$m" | git commit-tree "$t" "${p[@]}")"` (`:65`). In E9, `git cat-file commit` showed `handoff: ready ` with the trailing space, `# comment`, two blank lines and `trailing   ` followed by a single `\n`. The `""` parent is dropped by `[[ -n "$x" ]] && p+=(-p "$x")` (`:63`). T7's orphan case relies on this and passes.

**Evidence:** `test/lib/build-loop-fixtures.bash:57-66`, fc-r1/tip-cleanup.log, fc-r1/bats-read.log

---

## Claim 29: the test names in the diff (T44, "prints its four lines in order...", T6, T7, T8, T5, T21, T28)

**Location:** `test/scripts/build-loop-read.bats:159`, `test/scripts/build-loop-read.bats:189`, `test/scripts/build-loop-read.bats:412`, `test/scripts/build-loop-read.bats:445`, `test/scripts/build-loop-read.bats:488`, `test/scripts/build-loop-read.bats:522`, `test/scripts/build-loop-read.bats:539`, `test/scripts/build-loop-read.bats:549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each name describes what its body asserts and that all 16 pass. It does not establish the bidi part of T7's "a bad reason is not echoed": the loop checks only `\xc3` and `[31m` (settled by row 265). The code's skip message is a constant and never echoes a subject.
**Legibility-target:** for-orchestrator-synthesis

The bodies were read in full (paraphrased; no quote is available because the claim spans eight test bodies, quoted in the shared diff). Each body asserts the cases its name lists. For example, T44 asserts `missing`, `none-hard`, `ok 2-hard 1-soft` and several `unreadable` cases, and T28 asserts six lines in order plus the closed/ and working-tree cases. E1 passes 16/16.

**Evidence:** `test/scripts/build-loop-read.bats:159-573`, fc-r1/bats-read.log

---

## Claim 30: "A ready marker's body is not read here (--marker reads blocked and stopped bodies)."

**Location:** `test/scripts/build-loop-read.bats:439`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that --status ignores a ready marker's body (executed) and agreement with the plan's --marker definition (static). It does not establish --marker's behaviour, because --marker is U3b work and does not exist yet.
**Legibility-target:** for-orchestrator-synthesis

The plan reads: "`--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body" (`docs/working/plan-build-loop-handoff.md:206`). The test's `handoff: ready\n\nAll green.` asserts `ready` and passes in E1. marker_kind looks only at `rest%%$'\n'*`, the second line (`scripts/build-loop.sh:283-284`).

**Evidence:** `test/scripts/build-loop-read.bats:439-442`, `docs/working/plan-build-loop-handoff.md:206`, `scripts/build-loop.sh:283-284`

---

## Claim 31: "A hand-made object with two tree lines, the parent's last: git stops at the second and sees no parent; a reader taking the last tree would say ready."

**Location:** `test/scripts/build-loop-read.bats:467-468`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's parse of this object and the earlier raw reader's answer. It does not cover other duplicated header kinds.
**Legibility-target:** for-orchestrator-synthesis

In E4/P7, `git rev-list --parents -n 1` on the object printed only its own id (no parent), and HEAD gave `it has no parent`. In E6, 553a50d5's script, which read the raw object, printed `ok ... feat/a ready ff2098949ce6...`.

**Evidence:** `test/scripts/build-loop-read.bats:467-472`, fc-r1/status-probe.log P7, fc-r1/old-vs-new.log

---

## Claim 32: the other in-test comments ("Only in the working tree: still missing", "A line that looks like a constraint ID but is not exact: unreadable, never skipped (Q-112 [1])", "A marker at main's tip with the branch 0 commits ahead is main's", "So is a branch that is a symbolic ref to main", "Not landed on main: new", "A malformed Self-merge never: line turns it off", "An open brief left in closed/ counts too", "An open brief only in the working tree does not count")

**Location:** `test/scripts/build-loop-read.bats:363`, `test/scripts/build-loop-read.bats:387`, `test/scripts/build-loop-read.bats:478`, `test/scripts/build-loop-read.bats:482`, `test/scripts/build-loop-read.bats:516`, `test/scripts/build-loop-read.bats:532`, `test/scripts/build-loop-read.bats:564`, `test/scripts/build-loop-read.bats:569`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each comment matches the assertion that follows it and that the assertion passes. The "never skipped" comment holds only for the ten ASCII shapes the loop lists (see Claim 8 for the shapes that still read ok).
**Legibility-target:** for-orchestrator-synthesis

Each comment sits directly above an assertion that encodes it (paraphrased; no quote is available because there are eight separate sites, each quoted in the shared diff). All pass in E1.

**Evidence:** `test/scripts/build-loop-read.bats:363-572`, fc-r1/bats-read.log

---

## Claim 33: 859e29e8 message: "Failing tests for the rest of U1: --settings' fourth line ... (T44), and --status BRIEF..." plus its T5-T8/T21/T28 bullets and the Notes

**Location:** `859e29e8 (commit message)`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the new tests failed at 859e29e8, with the T-bullets matching the test bodies. The "without echoing" bidi sub-claim is settled by row 265. T7's name changed in c143b929.
**Legibility-target:** for-orchestrator-synthesis

In E7, against `git archive 859e29e8`, tests 8, 9 and 11-16 (the new and changed tests) were `not ok`. Test 4 also failed there, but it reads the repo's own docs and the archive is not a git repo, so that failure is not the unit's (paraphrased; no quote is available because the cause was inferred from the test's name, "on this repo's own docs/dev-cycle.md"). The Notes ("a skip line, not a sixth LOOP value (plan T7's 'unreadable')"; `new review - absent - - 0`) match `docs/working/plan-build-loop-handoff.md:324` and `scripts/build-loop.sh:315`.

**Evidence:** fc-r1/bats-859e29e8.log, `docs/working/plan-build-loop-handoff.md:324`, `scripts/build-loop.sh:315`

---

## Claim 34a: aaae80c6 message: what was built (fourth line, --status output forms, the lib called in-process with no dev-cycle.sh subprocess, the "--status --settings" usage case dropped, commit_all allowing an empty commit, real briefs having no Branch: line yet)

**Location:** `aaae80c6 (commit message)`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed items. It does not cover the marker-definition sentence, which was not true at aaae80c6 for a two-tree crafted object; that is history, fixed and stated in c143b929's A1, and is the A11 class settled by row 265. The show-ref wording is row 265 and the 79 ms is row 275.
**Legibility-target:** for-orchestrator-synthesis

`git diff 859e29e8 aaae80c6 -- test/scripts/build-loop-read.bats` shows `-    for args in "" "--bogus" "--settings extra" "--status" "--status --settings"; do` replaced by `+    for args in "" "--bogus" "--settings extra" "--status"; do`. build-loop.sh mentions dev-cycle.sh only in comments (lines 46, 71 and 82 in the grep), never as a command. In E10, the three briefs at aaae80c6 have 0 `^Branch:` lines each.

**Evidence:** `scripts/build-loop.sh:82-88`, fc-r1/static-counts.log

---

## Claim 34b: aaae80c6 message: "check_brief's `git log -1 -G'^Status: '` costs about 1 ms per brief on this repo"

**Location:** `aaae80c6 (commit message)`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers today's measurement only. It does not establish the cost under the load at authoring time. The result depends on load, as row 275 found for the sibling 79 ms figure.
**Legibility-target:** for-orchestrator-synthesis

E10 averaged 20 runs at 2300 us per call, against a 940 us `git rev-parse` baseline, so the increment is about 1.4 ms. An earlier run the same session measured 4.2 ms against 1.4 ms (paraphrased; no quote is available because that earlier run's output was not captured to a file, so only E10 is cited). This is consistent with "about 1 ms" on top of git start-up, but it is not reproducible to that precision.

**Evidence:** fc-r1/static-counts.log

---

## Claim 34c: aaae80c6 message: "(2137 commits, 1017 first-parent)"

**Location:** `aaae80c6 (commit message)`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at the default branch the branch was cut from (f6357ea1, the merge base with main). At aaae80c6 itself the counts are 2143/1023.
**Legibility-target:** for-orchestrator-synthesis

In E10, `f6357ea1 2137 1017` and `aaae80c6 2143 1023`.

**Evidence:** fc-r1/static-counts.log

---

## Claim 35: 553a50d5 message: "this says four lines, three of them from docs/dev-cycle.md. U1c stays at 399 changed code lines against U1b."

**Location:** `553a50d5 (commit message)`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help change and the count against the U1b tip of that time (1d79ffef, the merge base). It does not cover the count against today's U1b tip.
**Legibility-target:** for-orchestrator-synthesis

In E10, `git diff --numstat feat/build-loop-u1b...553a50d5 -- scripts test` gives 164+8, 36+2 and 186+3, which sum to 399 (python3). The help at 553a50d5 reads "four lines ... Lines 1-3 from one line of docs/dev-cycle.md", the same as HEAD's `scripts/build-loop.sh:10-12`.

**Evidence:** fc-r1/static-counts.log, `scripts/build-loop.sh:10-12`

---

## Claim 36a: c143b929 R1: "a line whose letters and digits, from its first letter, start like "h1" or "s1" but is not an exact constraint line makes docs/constraints.md unreadable (it was skipped while --settings said ok). IDs have no leading 0, so H1 and H01 cannot both count"

**Location:** `c143b929 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before and after behaviour for ASCII near-miss shapes and the H01 case. The same ASCII-and-outside-fences residue as Claim 8 applies.
**Legibility-target:** for-orchestrator-synthesis

In E6, `* H2: x` gave `ok 1-hard 0-soft` under 553a50d5 and `unreadable: line 3 looks like a constraint` under HEAD. In E2, `H01: x` gave `unreadable`.

**Evidence:** fc-r1/old-vs-new.log, fc-r1/constraints-shapes.log

---

## Claim 36b: c143b929 R1: "a heading ends a pending hard constraint, so a success: line under another section does not satisfy it."

**Location:** `c143b929 (commit message)`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ATX headings at column 0 (`## Other`): fixed, as stated. It does not cover setext headings or headings indented 1-3 spaces, where a success: line under the other section still satisfies the constraint.
**Legibility-target:** for-author

In E6, `'- H1: a' '## Other' '  success: b'` gave `ok` under 553a50d5 and `unreadable ... no success: line` under HEAD. In E3, `Other` / `=====` and `   ## Other` before the success line both still gave `ok 1-hard`. The rule is `/^#/` (`scripts/build-loop.sh:174`). Precise version: "a line starting with # ends a pending hard constraint".

**Evidence:** `scripts/build-loop.sh:174`, fc-r1/old-vs-new.log, fc-r1/constraints-structure.log

---

## Claim 36c: c143b929 A1: "marker_kind lets git parse the commit (rev-list --parents, rev-parse ^{tree}, log %B) instead of reading the raw object, and refuses a NUL byte; a hand-made object with two tree lines is now a skip, not ready."

**Location:** `c143b929 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three git calls, the NUL refusal, and the two-tree before/after. "Instead of reading the raw object" applies to parsing only: the raw object is still read once to count NUL bytes (`scripts/build-loop.sh:279`).
**Legibility-target:** for-orchestrator-synthesis

See Claims 22 and 31. In E6, the two-tree object gave `ready` under 553a50d5 and `skip ... it has no parent` under HEAD. In E4/P3, NUL gave `it holds a NUL byte`.

**Evidence:** `scripts/build-loop.sh:273-284`, fc-r1/old-vs-new.log, fc-r1/status-probe.log P3

---

## Claim 36d: c143b929 A4/A5: "an open brief left in closed/ counts for F31, and status_line computes the shared-branch set on first use, so no caller skips it."

**Location:** `c143b929 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 24.
**Legibility-target:** for-orchestrator-synthesis

In E6, the closed/ brief changed `ok` (553a50d5) to `skip ...: another open brief` (HEAD). `:326` is `[[ -n "$SHARED_BRANCHES" ]] || shared_branches`.

**Evidence:** `scripts/build-loop.sh:326`, fc-r1/old-vs-new.log

---

## Claim 36e: c143b929 A8: "the stopped-reason check runs grep in the C locale instead of switching the shell's locale (which warned on restore)."

**Location:** `c143b929 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 23.
**Legibility-target:** for-orchestrator-synthesis

E5 shows the old `local LC_ALL=C` printing `line 323: warning: setlocale` and HEAD printing no such line.

**Evidence:** fc-r1/locale.log

---

## Claim 36f: c143b929 remaining items: wording fixes ("planned" dropped from the lib and dev-cycle.sh; T7 renamed; "the unused status_of helper removed"), "T5 sets "Self-merge never: none", which self-merge now needs (Q-112)", "Override-log rows: A11, C1-C6, C8, C10-C13", "426 changed code lines against U1b"

**Location:** `c143b929 (commit message)`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed item. It does not re-audit the content of the override rows, which are settled.
**Legibility-target:** for-orchestrator-synthesis

The item-by-item evidence:
- **status_of:** it existed at 553a50d5 (`old-553a50d5/test/lib/build-loop-fixtures.bash:70` `status_of() { ... }`), had no caller there (grep outside the fixtures file found nothing), and has no hit at HEAD (E10).
- **T7 rename:** `git diff 553a50d5 c143b929` shows only T7 renamed, to "spoofed markers are skips or read as working ...".
- **T5:** `settings "Build-loop policy: $s" "" "Self-merge never: none"` is at `test/scripts/build-loop-read.bats:525`. read_settings requires `never_ok` for self-merge (`scripts/build-loop.sh:245-246`).
- **Override rows:** docs/reviews/override-log.md rows 265-275 carry A11, C1, C2/C4, C3, C5, C6, C8, C10, C11, C12 and C13.
- **426:** in E10, numstat over scripts and test sums to 170+8+1+1+2+2+32+2+205+3 = 426 (python3).

**Evidence:** `scripts/build-loop.sh:245-246`, `test/scripts/build-loop-read.bats:525`, `docs/reviews/override-log.md:265-275`, fc-r1/static-counts.log

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 6** (`scripts/build-loop.sh:33-35`, `:174`): "before the next constraint or heading" means "before the next line starting with #". Setext headings and 1-3-space-indented ATX headings do not end a pending hard constraint, while `#hashtag` lines do. Say "a line starting with #".
- **Claim 8** (`scripts/build-loop.sh:35-37`): the near-miss rule covers ASCII letters and digits outside code fences only. Fenced `H2:` lines and homoglyph IDs (`Н2:`, `Ｈ2:`, `H٢:`) leave `constraints ok` with the line uncounted. Say "Any other line outside a code fence whose ASCII letters and digits ...". Letter-prefixed shapes (`- [x] H2:`, `a) H2:`) also read ok, which the literal rule permits under Q-112's best effort.
- **Claim 16b** (`scripts/build-loop.sh:66-67`): the F31 skip applies only when the brief itself is open. A done or dropped brief prints ok even when open briefs name its branch (E4/P17-P18, T28 line 561). Say "the brief is open and another open brief ...".
- **Claim 36b** (`c143b929` message): "a heading ends a pending hard constraint" holds for column-0 `#` headings only (same residue as Claim 6). History only; the help text at :33-35 is the place to fix.

### Unverifiable
- **Claim 4** (`scripts/build-loop.sh:30`): "every loop prompt carries" docs/constraints.md. This needs U3's `--prompt`/`--start`; the plan at :44 agrees.
- **Claim 9** (`scripts/build-loop.sh:37`): "Only ok lets the orchestrator dispatch". This needs U3's `--start` or U4's skill; the plan at T44/F55 agrees.
- **Claim 34b** (`aaae80c6` message): "about 1 ms per brief". Measured at roughly a 1.4 ms increment over git start-up; the figure is load-dependent (compare row 275).

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: c143b929` first line.
- Answered: yes. 44 claims across the five files and four commit messages were verdicted. Every item in the brief was probed by execution: CONSTRAINTS_AWK shapes, output forms, working-tree plainness, crafted marker objects, Dispatched, F31/closed/, the C-locale grep, the POLICY/NEVER comment, the fixtures' comments, commit-message counts, and exit and read-only behaviour.
- Out of scope: docs/reviews/ artifacts. Settled rows 265 (old commit-message wording, including aaae80c6's pre-A1 marker sentence), 272, 273, 274 and 275 were not re-filed. The no-perl exit path was not run.
- Escalate: Claim 8's residue for the security/API critics to weigh against Q-112 [1]. A hard constraint written inside a code fence, or with a homoglyph H, Ｈ or Arabic-Indic digit, or behind a `[x]` task box, still yields `constraints ok N-hard` with that line uncounted. Q-112 accepts best effort, but the help's "Any other line" wording promises more than the code does for fences and non-ASCII.
- Decisions I made: I treated the "heading" claims (6, 36b) as Mostly accurate rather than Incorrect, because the mechanism (a `#` line ends a pending constraint) is right and only CommonMark's other heading forms escape it. I verdicted aaae80c6's message only on what row 265 does not cover. I kept execution logs in my scratch dir rather than docs/reviews/execution-logs/, because the task allows writing only this report in the worktree.
