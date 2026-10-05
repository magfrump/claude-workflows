Commit: c143b929

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** unit diff `feat/build-loop-u1b...feat/build-loop-u1c` at HEAD c143b929: comments, help text, test names and test comments in scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats; commit messages 859e29e8, aaae80c6, 553a50d5, c143b929. docs/reviews/ artifacts excluded. Replicate r3.
**Checked:** 2026-10-05
**Total claims checked:** 43
**Summary:** 35 verified, 7 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first; no claim below matches a logged pattern (the closest family, count claims in commit messages, was checked by execution for the 399 and 426 counts in Claims 40 and 43).

Execution provenance (shared by every `executed` claim). All probes ran with `LC_ALL=C.UTF-8`, a hermetic git env (`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`), throwaway repos under the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/fc-r3/` (cwd for each probe script is that dir; each script creates and cds into its own `rN/` repo), against `scripts/build-loop.sh` at c143b929. Each script ran under `timeout`; no background processes were left.

| Log | Command (cwd = scratch dir unless noted) | Exit | Time (UTC) |
|---|---|---|---|
| `bats-read.log` | `bats test/scripts/build-loop-read.bats` (cwd worktree) | 0 (16/16 ok) | 2026-10-05T16:46:55Z |
| `p1.log` | `bash p1.sh` — 36 near-miss constraint shapes after `- H1: a` / `  success: b` | 0 | ~16:47:15Z |
| `p2.log` | `bash p2.sh` — fences, headings, success forms, dup/first-problem order | 0 | ~16:47:46Z |
| `p3.log` | `bash p3.sh` — working-tree plainness, crafted marker objects via `git hash-object -t commit --literally` | 0 | ~16:48:27Z |
| `p4.log` | `bash p4.sh` — exit codes, help, read-only (find -newer), missing-tree marker | 0 | ~16:49:37Z |
| `p5.log` | `bash p5.sh` — commit-tree cleanup, done brief sharing a branch, real briefs | 0 | ~16:50:36Z |
| `p6.log` | `git log -1 --format=%B / %s` on crafted objects (cwd `fc-r3/r3`) | 0 | 2026-10-05T16:51:29Z |
| `p7.log` | `--status`/`--settings` under `LC_ALL=xx_YY.bogus` and `C.UTF-8` (cwd `fc-r3/r3`) | 0 | ~16:51:30Z |

---

## Claim 1: "Usage: ... scripts/build-loop.sh --status BRIEF..." / usage error "--status needs at least one brief path"

**Location:** `scripts/build-loop.sh:7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the --status mode's existence, its argument requirement and the usage text; does not establish behaviour for a path argument that itself starts with `-` (treated as data and refused per argument by check_brief's pathform).

`scripts/build-loop.sh:95` — `--status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage "--status needs at least one brief path" ;;`. p4.log: `--status` with no paths exits 1 with `--status needs at least one brief path (usage: build-loop.sh --settings | --status BRIEF...)`.

**Evidence:** `scripts/build-loop.sh:91-99`; p4.log

---

## Claim 2: "--settings  four lines from the default branch's commit ... Lines 1-3 from one line of docs/dev-cycle.md"

**Location:** `scripts/build-loop.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line count, order and the fourth line's source (docs/constraints.md); does not re-verify the unchanged policy/slots/never rules of lines 1-3 (U1b's scope).

`scripts/build-loop.sh:355` — `printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"`; `:254` sets `f=docs/constraints.md` for the fourth. bats test "--settings prints its four lines in order..." passed (bats-read.log, ok 12).

**Evidence:** `scripts/build-loop.sh:254-267`, `scripts/build-loop.sh:353-356`; bats-read.log

---

## Claim 3: "A constraint is a line "H<n>: text" (hard) or "S<n>: text" (soft) at column 0, optionally after "- ", n without a leading 0; a hard one needs a "success: <observable>" line (any indent, optionally after "- ") before the next constraint or heading, and no ID may repeat."

**Location:** `scripts/build-loop.sh:30-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exact-line regex, the leading-0 rule, success-line forms (space and tab indent, `- success:`), the heading and next-constraint cut-offs, end-of-file pending, and duplicate IDs across H and S; does not establish how lines inside a code fence count (they are skipped — see Claim 4) or what "<observable>" means beyond one non-blank character.

`scripts/build-loop.sh:164` — `/^(- )?[HS][123456789][0123456789]*: [^ \t]/ {`; `:174` — `/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }`; `:175` — `/^[ \t]*(- )?success: [^ \t]/ { pend = "" }`; `:167` — `if (bad == "" && (id in seen)) bad = "dup " id " " seen[id] " " NR`. p2.log: `- H1: a` / `# Other` / `  success: b` → `hard constraint H1 (line 1) has no success: line...`; tab-indented `- success: b` → ok; `success:  b` (two spaces) → nosuccess; `S1`,`S1` → dup; `H1:` / `H1: ` with nothing after → near (unreadable); p1.log: `H01: x` and `- H0: x` → unreadable.

**Evidence:** `scripts/build-loop.sh:161-183`; p1.log; p2.log

---

## Claim 4: "Any other line whose letters and digits, from its first letter, start like "h1" or "s1" makes the file unreadable."

**Location:** `scripts/build-loop.sh:35-37`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every ASCII near-miss shape iteration 1 listed plus 20 more (all refused as unreadable); does not hold for non-ASCII look-alikes or for lines inside a code fence, which are dropped while the line reads `constraints ok`.

The normalisation is ASCII-only, run under `LC_ALL=C` (`scripts/build-loop.sh:128` — `env LC_ALL=C awk "$FENCE_AWK$2"`): `:172` — `{ s = $0; sub(/^[^a-zA-Z]*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }` and `:173` — `s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }`. Every iteration-1 ASCII shape is refused by execution (p1.log): `* H2:`, `1. H2:`, `H2:  x`, `H2:<TAB>x`, `  H2:`, `h2:`, `**H2:**`, `### H2:`, `> H2:`, `H10 :`, `| H2: x |`, `H01:` → `constraints unreadable: line 3 looks like a constraint...`.

Residue, by execution (p1.log, p2.log), each with `- H1: a` / `  success: b` before it:
- `Н2: x` (Cyrillic En — the "Cyrillic H" shape named in iteration 1's R1) → `constraints ok 1-hard 0-soft`; likewise `Ｈ2: x` (fullwidth) and `H²: x`. The non-ASCII bytes are not `[a-zA-Z]`, so `sub(/^[^a-zA-Z]*/...)` strips them together with the digit.
- A column-0 fence around `H2: x` (``` or ~~~) → `constraints ok 1-hard 0-soft`: `:163` — `fence($0) { next }` runs before the near check. The loop prompt still carries that line.

The precise version: "Any other line outside a code fence whose ASCII letters and digits, from its first ASCII letter, start like "h1" or "s1" ...". Under Q-112 [1] look-alike detection is best effort; this is reported because Q-112 asks for any case where "a hard constraint can still be silently dropped while the line reads `constraints ok`" — whether a Cyrillic-H or fenced line is a "hard constraint" is the orchestrator's call; the help's wording ("letters") does not say ASCII.

**Evidence:** `scripts/build-loop.sh:128`, `scripts/build-loop.sh:161-183`; p1.log; p2.log

---

## Claim 5: "docs/constraints.md, which every loop prompt carries." / "Only "ok" lets the orchestrator dispatch."

**Location:** `scripts/build-loop.sh:30`, `scripts/build-loop.sh:37`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the plan specifies both rules; does not establish them in code, since neither `--prompt` nor the orchestrator's dispatch step exists in this unit.

The plan states both: `docs/working/plan-build-loop-handoff.md:44` — "Every loop prompt carries `docs/constraints.md` from main's commit", and `:260` — "**Step 10, dispatch**: only when `--settings` prints `constraints ok`". No code in scripts/ dispatches or builds a prompt (paraphrased — no quote available because the claim covers absence of code: `grep -n -- '--prompt\|dispatch' scripts/build-loop.sh` finds only comments). Verifying needs U3's `--prompt` and U4's skill text.

**Evidence:** `docs/working/plan-build-loop-handoff.md:44`, `docs/working/plan-build-loop-handoff.md:260`

---

## Claim 6: "--status  one line per brief path, in argument order, from the default branch's commit (the path must also be plain in the working tree, as --check-brief)"

**Location:** `scripts/build-loop.sh:42-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the argument brief: order, main-commit reads, and the working-tree plainness check via check_brief's `blocker`; does not cover the other briefs shared_branches reads (main only, no working-tree check — and the help does not claim one), and "plain" allows an absent working-tree file.

`scripts/build-loop.sh:351` — `for a in "${ARGS[@]}"; do status_line "$a"; done`; `:312` — `out="$(check_brief "$a")"`; lib `scripts/lib/dev-cycle-read.sh:329` — `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi`. p3.log: a working-tree symlink brief and a symlinked `docs/working/briefs/` both → `skip ...: reached through a symlink, or not a regular file`; a deleted working-tree copy → ok (blocker: "An absent path is not skipped, just absent", `dev-cycle-read.sh:105`). Order and main-commit reads: bats T28 and T21 passed (bats-read.log ok 15, 16). The lite drift claim that the check is unenforced does not hold: the enforcement is check_brief, not shared_branches.

**Evidence:** `scripts/build-loop.sh:310-316`, `scripts/build-loop.sh:349-352`, `scripts/lib/dev-cycle-read.sh:100-118`, `scripts/lib/dev-cycle-read.sh:321-360`; p3.log; bats-read.log

---

## Claim 7: "STATE: open, done or dropped (dev-cycle.sh --check-brief), or new when main has no file there (then "new review - absent - - 0")."

**Location:** `scripts/build-loop.sh:46-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the state values and the new line's fixed fields; does not re-litigate that "new" also covers a brief moved to closed/ (override row 272).

`scripts/build-loop.sh:315` — `if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi`; state from check_brief's `ok $a ${st#Status: } $c` (`dev-cycle-read.sh:359`). T8's last assertion (`ok docs/working/briefs/2026-10-01-none.md new review - absent - - 0`) and T28's done/dropped lines passed.

**Evidence:** `scripts/build-loop.sh:312-315`; `scripts/lib/dev-cycle-read.sh:348-359`; bats-read.log

---

## Claim 8: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"; else review. BRANCH: from the brief's first "Branch: NAME" line."

**Location:** `scripts/build-loop.sh:48-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the policy conjunction and the first-line rule (brief_fields keeps the first unfenced match); does not establish the gate's later use of POLICY.

`scripts/build-loop.sh:325` — `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge`; `:318` — `if [[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]`; lib `:301` — `if (!(k in got)) { got[k] = 1; ...` (first line wins). T5 (10 combinations plus a malformed never line) passed.

**Evidence:** `scripts/build-loop.sh:316-325`; `scripts/lib/dev-cycle-read.sh:289-312`; bats-read.log ok 14

---

## Claim 9: "LOOP: absent (no such branch), working, ready, blocked or stopped, from the branch tip (SHA, with DATE its commit date as YYYY-MM-DD; "-" when absent)."

**Location:** `scripts/build-loop.sh:51-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five values and the SHA/date fields for honest commits; does not re-litigate crafted committer dates (override row 274).

`scripts/build-loop.sh:332` — `"absent "*) echo "ok $a $st $pol $br absent - - $disp"; return ;;`; DATE from `dev-cycle-read.sh:380` — `$(git log -1 --format=%cs "$sha")`. T6 asserts every field for absent, working (0 ahead and 1 ahead), ready, blocked and stopped; passed.

**Evidence:** `scripts/build-loop.sh:330-345`; `scripts/lib/dev-cycle-read.sh:370-383`; bats-read.log ok 10

---

## Claim 10: "A tip is a marker only when the branch is at least one commit ahead of main and the tip is an empty commit with one parent whose subject is exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (1-120 printable ASCII characters, no blank at either end), alone on its first line; REASON is printed last. Any other tip is working."

**Location:** `scripts/build-loop.sh:54-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the ahead-count gate, empty single-parent rule, exact subjects, the REASON grammar and placement; does not hold literally for "Any other tip is working" (a "handoff:"-prefixed non-marker is a skip) or for "alone on its first line" (a whitespace-only second line is also refused).

Both imprecisions fail closed:
- "Any other tip is working": `scripts/build-loop.sh:340` — `bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;`. The help states this only later (`:67-69`). Precise: "Any other tip whose subject does not start "handoff:" is working; one that does is a skip."
- "alone on its first line": `:283-284` — `rest="${msg#"$subj"}"; rest="${rest#$'\n'}"` / `if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"`. p3.log: message `handoff: ready\n   \nbody` → `skip ...: its subject runs onto a second line`, although git's own subject is `handoff: ready` (p6.log `s=[handoff: ready]`). Precise: "...alone on its first line, with the next line (if any) empty".

The rest holds by execution: p3.log root commit and parent-after-author object → "it has no parent"; repeated parent → "it has 2 parents"; encoding header → ready; message with no trailing newline `handoff: blocked` → blocked; T6's 120-char reason ok and 121-char reason skip; T7's 0-ahead marker at main's tip → working.

**Evidence:** `scripts/build-loop.sh:270-293`, `scripts/build-loop.sh:336-345`; p3.log; p6.log; bats-read.log ok 10-11

---

## Claim 11: "DISPATCHED: the brief's "Dispatched: N" (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:60-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the default 0 and the 0-99 range with no leading 0; does not cover fenced Dispatched: lines (skipped by brief_fields, as for every key).

`scripts/build-loop.sh:311` — `local ... disp=0`; `:321` — `=~ ^Dispatched:\ (0|[123456789][0123456789]?)$`. p3.log: a brief with no Dispatched: line → `ok ... absent - - 0`; T8's `100`, `01`, `-1`, `x`, empty → skip.

**Evidence:** `scripts/build-loop.sh:311`, `scripts/build-loop.sh:320-324`; p3.log; bats-read.log ok 13

---

## Claim 12: "skip BRIEF: WHY — The brief cannot be read (as --check-brief), its Branch: line is missing or malformed or its Dispatched: line malformed, its branch name is refused (as --check-branch)"

**Location:** `scripts/build-loop.sh:62-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed skip reason's trigger and message source; does not cover the shared-branch and marker reasons (Claims 13, 14).

`scripts/build-loop.sh:313` — `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (check_brief's own skip), `:317`/`:318` Branch: missing/malformed, `:322` Dispatched:, `:334` — `*) echo "skip $a: Branch: ${out#*: }"; return ;;` (check_branch's reason). T8 passed: fence-like line, no Branch:, five malformed Branch: forms, `Branch: main`, HEAD/refs/heads/x/a..b/-x/non-ASCII, five malformed Dispatched: forms.

**Evidence:** `scripts/build-loop.sh:312-335`; bats-read.log ok 13

---

## Claim 13: "another open brief on main, in briefs/ or closed/, names the same branch (ignoring case)"

**Location:** `scripts/build-loop.sh:66-67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers open briefs in briefs/ and closed/, case folding, and working-tree-only briefs not counting; does not hold for a done or dropped argument brief, which prints ok even when open briefs share its branch.

`scripts/build-loop.sh:327` — `if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then` — the skip applies only when the argument brief is itself open. p5.log: done brief `feat/x` plus one open brief naming `feat/x` → `ok docs/working/briefs/2026-10-01-c.md done review feat/x absent - - 0`; T28 asserts the same for a done brief with two open ones (`ok $c done review feat/x absent - - 0`). The help, read as written, predicts a skip there. Precise: "the brief is open and another open brief ... names the same branch". Case folding is ASCII only (`dev-cycle-read.sh:430` — `tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'`), which is moot because check_branch refuses non-ASCII names.

**Evidence:** `scripts/build-loop.sh:298-309`, `scripts/build-loop.sh:326-329`; `scripts/lib/dev-cycle-read.sh:430`; p5.log; bats-read.log ok 16

---

## Claim 14: "or the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:67-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the definition of "subject" as the raw first line of `%B`; does not establish agreement with git's `%s`, which skips leading blank lines (a tip whose message starts with a blank line then `handoff: ready` reads as working, failing closed).

`scripts/build-loop.sh:277` — `msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"`. p6.log: for a message `\nhandoff: ready`, `%B` begins with `\n` (raw) while `%s` is `handoff: ready`; p3.log: that tip → `ok ... working`. Answers the brief's item-4 question: `%B` returns the raw first line, not git's subject.

**Evidence:** `scripts/build-loop.sh:273-278`; p3.log; p6.log

---

## Claim 15: "Read-only: writes nothing." / "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:72`, `scripts/build-loop.sh:75-76`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers --status and --settings exit codes and that neither run writes in the repo (including .git); does not exercise the no-perl path or establish behaviour when git itself errors mid-run (a missing tree object printed `fatal: Needed a single revision` to stderr and still skipped, exit 0).

p4.log: outside a repo → exit 1 `Not inside a git repository`; `--status` without paths and `--settings x` → exit 1; main renamed → exit 1 `needs a default branch`; `--help` → exit 0; `find . -newer stamp` after `--status` and `--settings` runs printed nothing. Missing-lib exit 1: bats test "sources the lib from its own directory" passed.

**Evidence:** `scripts/build-loop.sh:80-111`; p4.log; bats-read.log

---

## Claim 16: "docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE", "dup ID FIRST SECOND" or "near LINE" (the first problem found)." and the case arms that render them

**Location:** `scripts/build-loop.sh:158-159`, `scripts/build-loop.sh:259-266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four output forms, first-problem precedence and each arm's message; does not cover odd/unbalanced, which main_file handles before the arms (`:130-133`).

`:181` — `print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)`; every `bad =` assignment is guarded by `bad == ""`. `:265` — `*) CONSTRAINTS_LINE="constraints unreadable: line $c looks like a constraint ...` is reached only by `near` (the sole remaining form). p2.log: `H1: a` / `H1: b` / `success: x` → nosuccess (first), not dup; `none-hard` for an empty file; T44's ok/none-hard/nosuccess/dup/near/link/symlink assertions passed.

**Evidence:** `scripts/build-loop.sh:161-183`, `scripts/build-loop.sh:254-267`; p2.log; bats-read.log ok 11

---

## Claim 17: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (...), NEVER_LINE and CONSTRAINTS_LINE from main's commit. POLICY is for --status and the gate, NEVER for the gate."

**Location:** `scripts/build-loop.sh:194-197`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the variables set and POLICY's --status reader; does not establish a gate, which is planned (plan D5-D7) and not in this file, so NEVER has no reader yet.

POLICY is read at `scripts/build-loop.sh:325` (status_line). No gate exists: `grep -n 'gate\|NEVER\[' scripts/build-loop.sh` matches only this comment and `:199` (paraphrased — no quote available because the claim covers absence of code). The previous wording said "(--status, then the gate)", which marked the gate as later; the new wording reads as present. Precise: "NEVER for the planned gate (U2)". The unchanged `:199` `# shellcheck disable=SC2034  # POLICY and NEVER` now also covers POLICY, which is read.

**Evidence:** `scripts/build-loop.sh:194-203`, `scripts/build-loop.sh:325`; `docs/working/plan-build-loop-handoff.md:15`

---

## Claim 18: "The tip SHA of a brief's branch, read as a handoff marker: prints ready, blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY". The caller has checked that the branch is at least one commit ahead of main."

**Location:** `scripts/build-loop.sh:270-272`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers marker_kind's five outputs and its single caller's ahead check; does not cover marker semantics (Claim 10).

Outputs at `:278` (`echo working`), `:279-284` and `:292` (`bad ...`), `:286-287` (ready/blocked), `:291` (`stopped $r`). The only caller: `:337-338` — `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"`.

**Evidence:** `scripts/build-loop.sh:273-293`, `scripts/build-loop.sh:336-344`

---

## Claim 19: "git parses the object: its tree, its parents and where the message starts."

**Location:** `scripts/build-loop.sh:275`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parents (rev-list --parents), tree (rev-parse ^{tree}) and message (log %B) coming from git's parser; does not mean the raw object is never read (the NUL count at `:279` reads it with `git cat-file commit`).

`:276` — `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"`; `:282` — `git rev-parse --verify "$1^{tree}"`; `:277` — `git log -1 --format=%B`. p3.log: a parent line after the author line → git reports no parent → `it has no parent`; T7's two-tree-lines object → `it has no parent` (passed). NUL in message or subject → `it holds a NUL byte` (p3.log).

**Evidence:** `scripts/build-loop.sh:273-284`; p3.log; bats-read.log ok 11

---

## Claim 20: "grep in the C locale: the ranges are ASCII bytes, and no locale is switched here."

**Location:** `scripts/build-loop.sh:290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the shell's locale is not changed and that the check adds no setlocale warning; does not cover the two warnings bash itself prints at start-up (outer process and scrub re-exec) under an uninstalled caller locale, which --settings prints too.

`:291` — `printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` (a per-command environment prefix). p7.log under `LC_ALL=xx_YY.bogus` (en_US.UTF-8 also not installed; `locale -a` lists only C, C.utf8, POSIX): `--status` printed exactly two `setlocale` warnings, the same two `--settings` prints with no grep path; `café` reason → skip and `needs a key` → stopped under both locales.

**Evidence:** `scripts/build-loop.sh:289-292`; p7.log

---

## Claim 21: "Lower-cased branch names that more than one open brief on main (in briefs/ or closed/) names, each between newlines: such briefs are skipped (F31). status_line computes it on first use, so no caller can skip it."

**Location:** `scripts/build-loop.sh:294-296`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the set's contents, closed/ inclusion, newline delimiting and lazy computation in status_line; "such briefs are skipped" holds only for open argument briefs (Claim 13).

`:301` — `git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/ docs/working/briefs/closed/`; `:303` — `isbrief "${f/closed\//}"`; `:307` — `SHARED_BRANCHES=$'\n'` (non-empty after one run); `:326` — `[[ -n "$SHARED_BRANCHES" ]] || shared_branches`. status_line is the only consumer and the only caller of the mode loop (`:351`). T28 passed, including "An open brief left in closed/ counts too" and the working-tree-only brief not counting.

**Evidence:** `scripts/build-loop.sh:297-309`, `scripts/build-loop.sh:326`, `scripts/build-loop.sh:349-352`; bats-read.log ok 16

---

## Claim 22: "The reader, kept in a lib so scripts/build-loop.sh can share it" / "kept apart so scripts/build-loop.sh can share it"

**Location:** `scripts/dev-cycle.sh:87`, `scripts/lib/dev-cycle-read.sh:2-3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that build-loop.sh exists and sources the lib; does not verify the rest of the lib header's list of contents (unchanged text).

`scripts/build-loop.sh:85-88` — `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` ... `source "$READ_LIB"`.

**Evidence:** `scripts/build-loop.sh:82-89`

---

## Claim 23: "commit_all [MSG]: stage everything and commit it on the current branch (an empty commit when nothing changed, so rewriting a file as it was still works)."

**Location:** `test/lib/build-loop-fixtures.bash:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--allow-empty`; does not cover hooks (none in the hermetic env).

`:23` — `git add -A && git commit -q --allow-empty -m "${1:-fixture}"`. T5 rewrites the same settings and brief files repeatedly and passed.

**Evidence:** `test/lib/build-loop-fixtures.bash:23`; bats-read.log ok 14

---

## Claim 24: fixture comments for constraints, brief and work ("docs/constraints.md holding these lines, committed"; "a title and these lines, committed on the current branch; sets B to its path"; "BRANCH from main with one commit that changes a file")

**Location:** `test/lib/build-loop-fixtures.bash:29`, `test/lib/build-loop-fixtures.bash:42-43`, `test/lib/build-loop-fixtures.bash:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what each helper writes and commits; does not cover failure behaviour (each chains with &&).

`:30` — `printf '%s\n' "$@" > docs/constraints.md && commit_all constraints`; `:46-48` — `B="docs/working/briefs/2026-10-01-$s.md"` ... `printf '# Brief: %s\n\n' "$s" > "$B" && printf '%s\n' "$@" >> "$B"` ... `commit_all "brief $s"`; `:53-54` — `git branch -q "$1" main` ... `echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1"`.

**Evidence:** `test/lib/build-loop-fixtures.bash:29-55`

---

## Claim 25: "tip BRANCH MESSAGE [TREE [PARENT...]]: a commit with MESSAGE and a newline (no cleanup: commit-tree takes it as given) on BRANCH's tip. By default it is empty (BRANCH's own tree) with BRANCH's tip as its one parent; pass TREE and the parents ("" for none) to build anything else."

**Location:** `test/lib/build-loop-fixtures.bash:57-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the message bytes, default tree/parent and the "" no-parent form; does not cover a non-commit TREE argument.

`:65` — `printf '%s\n' "$m" | git commit-tree "$t" "${p[@]}"`; `:63` — `[[ -n "$x" ]] && p+=(-p "$x")`. p5.log: a message with two trailing spaces, a `# comment` line and three trailing blank lines is stored byte for byte by commit-tree (no stripspace).

**Evidence:** `test/lib/build-loop-fixtures.bash:61-66`; p5.log

---

## Claim 26: test "--settings: docs/constraints.md from main gives ok, missing, none-hard or unreadable (T44)" and its comments ("Only in the working tree: still missing."; "A line that looks like a constraint ID but is not exact: unreadable, never skipped (Q-112 [1]).")

**Location:** `test/scripts/build-loop-read.bats:151-187`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name and comments against the assertions; does not mean the loop's 10 shapes are exhaustive (Claim 4's non-ASCII and fence residue is not asserted).

The test asserts all four states, working-tree-only missing, nosuccess, dup, link-reference refusal, 10 near-miss shapes, the heading cut-off and a symlinked file; passed (bats-read.log ok 11).

**Evidence:** `test/scripts/build-loop-read.bats:151-187`; bats-read.log

---

## Claim 27: test "--settings prints its four lines in order and exits 0; usage errors and a missing default branch exit 1"

**Location:** `test/scripts/build-loop-read.bats:190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name against the assertions (it also asserts the not-a-repo exit 1, beyond the name); does not assert -h (override row 246).

`:190-192` assert 4 lines with prefixes policy/slots/never/constraints; `:194-198` four usage cases exit 1 with empty stdout; `:199-201` renamed main → exit 1. Passed (ok 12).

**Evidence:** `test/scripts/build-loop-read.bats:190-206`; bats-read.log

---

## Claim 28: test "--status: each loop state with every field (T6)"

**Location:** `test/scripts/build-loop-read.bats:227`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers absent, working (0 and 1 ahead), ready, blocked, stopped (120-char reason) with full-line equality; the "new dependency (left-pad)" and ready-with-body cases use prefix/suffix matches, not every field.

Full-line `=` assertions at `:231`, `:234`, `:237`, `:241`, `:247`. Passed (ok 10).

**Evidence:** `test/scripts/build-loop-read.bats:227-258`; bats-read.log

---

## Claim 29: "A ready marker's body is not read here (--marker reads blocked and stopped bodies)."

**Location:** `test/scripts/build-loop-read.bats:254`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers "not read here" (a ready tip with a body reads as ready); does not hold for "--marker reads", which is a planned U3b mode not in scripts/build-loop.sh.

`scripts/build-loop.sh:93-99` accepts only `--settings`, `--status`, `-h|--help`. The plan: `docs/working/plan-build-loop-handoff.md:206` — "`--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body" and `:276` — "**U3b code** (~230): `--marker`, ...". Precise: "(the planned --marker reads ...)".

**Evidence:** `test/scripts/build-loop-read.bats:254-257`; `scripts/build-loop.sh:93-99`; `docs/working/plan-build-loop-handoff.md:206`, `docs/working/plan-build-loop-handoff.md:276`

---

## Claim 30: test "--status: spoofed markers are skips or read as working, and a bad reason is not echoed (T7)"

**Location:** `test/scripts/build-loop-read.bats:260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the skip and working cases and the non-echo of the `\xc3` and `[31m` reasons; the bidi reason's non-echo is not asserted (`:280` checks only `\xc3` and `[31m`), the premise already settled by override row 265 and unchanged.

`:280` — `[[ "$output" != *$'\xc3'* && "$output" != *'[31m'* ]]`. The skip message is fixed text (`scripts/build-loop.sh:292`), so no reason is echoed for any refused subject. Passed (ok 11).

**Evidence:** `test/scripts/build-loop-read.bats:260-301`; `scripts/build-loop.sh:292`; bats-read.log

---

## Claim 31: "A hand-made object with two tree lines, the parent's last: git stops at the second and sees no parent; a reader taking the last tree would say ready."

**Location:** `test/scripts/build-loop-read.bats:282-283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's parse (no parent) and the resulting skip; the "a reader taking the last tree would say ready" half is a counterfactual about a different reader, checked only by reasoning (last tree = parent's tree, one parent line → empty single-parent commit).

`:287` asserts `it has no parent`; passed. p3.log reproduces the same git behaviour for a parent line placed after the author line.

**Evidence:** `test/scripts/build-loop-read.bats:282-287`; p3.log; bats-read.log

---

## Claim 32: "A marker at main's tip with the branch 0 commits ahead is main's, not the loop's." / "So is a branch that is a symbolic ref to main."

**Location:** `test/scripts/build-loop-read.bats:293`, `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both cases reading as working; does not cover a symref to a non-main branch.

`:296` and `:300` assert `working`; passed. Mechanism: `scripts/build-loop.sh:337` — `if [[ "$ahead" -gt 0 ]]`.

**Evidence:** `test/scripts/build-loop-read.bats:293-300`; bats-read.log

---

## Claim 33: test "--status: a brief it cannot read, or whose Branch or Dispatched line is wrong, is a skip with why (T8)" and comment "Not landed on main: new, with nothing else to read."

**Location:** `test/scripts/build-loop-read.bats:303`, `test/scripts/build-loop-read.bats:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name and comment against the assertions; passed (ok 13).

Assertions `:308-334` match the name (fence, Branch:, Dispatched:, refused names, new). 

**Evidence:** `test/scripts/build-loop-read.bats:303-335`; bats-read.log

---

## Claim 34: test "--status: the policy is the stricter of main's settings and the brief's Policy line (T5)" and comment "A malformed Self-merge never: line turns it off."

**Location:** `test/scripts/build-loop-read.bats:337`, `test/scripts/build-loop-read.bats:347`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 10 combinations and the malformed-never case; passed (ok 14).

`:343` — `want=review; [[ "$s" == self-merge && "$p" == 'Policy: self-merge' ]] && want=self-merge`; `:348-351` the `../x` never line → review.

**Evidence:** `test/scripts/build-loop-read.bats:337-352`; bats-read.log

---

## Claim 35: test "--status reads main's commit: working-tree and branch edits to a brief's lines are ignored (T21)"

**Location:** `test/scripts/build-loop-read.bats:354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Status/Branch/Policy/Dispatched edits on the branch and in the working tree; passed (ok 15).

`:361` asserts `ok $B open review feat/a working ... 1` after both edits.

**Evidence:** `test/scripts/build-loop-read.bats:354-362`; bats-read.log

---

## Claim 36: test "--status: two open briefs naming one branch both skip; many briefs keep their order (T28)" and comments "An open brief left in closed/ counts too." / "An open brief only in the working tree does not count."

**Location:** `test/scripts/build-loop-read.bats:364`, `test/scripts/build-loop-read.bats:379`, `test/scripts/build-loop-read.bats:384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name and both comments; passed (ok 16).

`:374`, `:377` both open briefs skip; `:372-378` six lines in argument order; `:381` closed/ brief → skip; `:387` working-tree-only → ok.

**Evidence:** `test/scripts/build-loop-read.bats:364-388`; bats-read.log

---

## Claim 37: commit 859e29e8 — "Failing tests for the rest of U1 ..." and its per-test lists (T6, T7, T8, T5, T21, T28; Notes)

**Location:** commit 859e29e8
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the listed cases match the tests and that --status did not exist at that commit (so the tests failed); the bidi "without echoing" gap is override row 265 and not re-filed; did not run the suite at 859e29e8.

`git show 859e29e8:scripts/build-loop.sh | grep -n -- --status` finds only `117:# for the modes that judge a brief (--status, then the gate).` — no mode. The listed T7 shapes (content, merge, orphan, suffixed/mis-cased, empty/control/bidi/non-ASCII reason, two-line subject, main's tip, symref) all appear in the current T7 (`test/scripts/build-loop-read.bats:270-300`).

**Evidence:** `test/scripts/build-loop-read.bats:227-388`; commit 859e29e8

---

## Claim 38: commit aaae80c6 — "Everything is read from main's commit through the lib: check_brief for STATE, brief_fields for Branch:, Policy: and Dispatched:, check_branch for the tip..." / "The lib is called in-process (no dev-cycle.sh subprocess)" / "The real briefs have no Branch: line yet, so --status skips them"

**Location:** commit aaae80c6
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lib routing, in-process calls and the real-brief skips at HEAD; the show-ref-only and 1 ms / 79 ms claims are settled by override rows 265 and 275 and not re-checked; the constraints grammar it states ("before the next constraint") was true then and was widened by c143b929 (heading).

`scripts/build-loop.sh:312`, `:316`, `:330` call check_brief, brief_fields and check_branch in-process; the only `dev-cycle.sh` mentions in build-loop.sh are comments (`:46`, `:71`, `:82`). p5.log: `--status` over the three briefs on main → `skip ...: no Branch: line on the default branch` for each.

**Evidence:** `scripts/build-loop.sh:310-345`; p5.log

---

## Claim 39: commit 553a50d5 — "this says four lines, three of them from docs/dev-cycle.md. U1c stays at 399 changed code lines against U1b."

**Location:** commit 553a50d5
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count as added+deleted lines under scripts/ and test/ against the current merge base; does not establish the count against U1b's tip as it stood at that moment if the merge base has since moved.

`git diff --numstat feat/build-loop-u1b...553a50d5 -- scripts test` → 164+8, 36+2, 186+3 = 399.

**Evidence:** `scripts/build-loop.sh:10-12`; command output in this session (numstat, cwd worktree, exit 0, 2026-10-05T16:46Z)

---

## Claim 40: commit c143b929, R1 bullet — "a line whose letters and digits, from its first letter, start like "h1" or "s1" but is not an exact constraint line makes docs/constraints.md unreadable (it was skipped while --settings said ok)."

**Location:** commit c143b929
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every ASCII shape; does not hold for the Cyrillic-H shape that R1 itself listed, nor for fenced lines (same residue as Claim 4).

p1.log: `Н2: x` (Cyrillic) and `Ｈ2: x` (fullwidth) still give `constraints ok 1-hard 0-soft`; the rule is ASCII letters and digits (`scripts/build-loop.sh:172` — `sub(/^[^a-zA-Z]*/, "", s)` under `LC_ALL=C`). The other R1 sub-claims hold: "IDs have no leading 0, so H1 and H01 cannot both count" (p1.log `H01: x` → unreadable) and "a heading ends a pending hard constraint" (p2.log `heading-pend` → nosuccess).

**Evidence:** `scripts/build-loop.sh:164-175`; p1.log; p2.log

---

## Claim 41: commit c143b929, A1 bullet — "marker_kind lets git parse the commit (rev-list --parents, rev-parse ^{tree}, log %B) instead of reading the raw object, and refuses a NUL byte; a hand-made object with two tree lines is now a skip, not ready."

**Location:** commit c143b929
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the parse moving to git and the two-tree skip; "instead of reading the raw object" is imprecise, since the raw object is still read for the NUL check.

`scripts/build-loop.sh:279` — `if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]` reads the raw object. Precise: "lets git parse the commit ...; reads the raw object only to refuse a NUL byte". The two-tree skip passed in T7 (`:287`).

**Evidence:** `scripts/build-loop.sh:273-284`; bats-read.log ok 11; p3.log

---

## Claim 42: commit c143b929 — A4/A5 ("an open brief left in closed/ counts for F31, and status_line computes the shared-branch set on first use"), A8 ("grep in the C locale instead of switching the shell's locale (which warned on restore)"), wording bullet ("the unused status_of helper removed"), "T5 sets "Self-merge never: none", which self-merge now needs (Q-112)"

**Location:** commit c143b929
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet's current-state claim; does not re-verify the prior code's restore warning (history).

A4/A5: Claim 21. A8: Claim 20. `grep -rn status_of scripts test` → no hits. T5: `test/scripts/build-loop-read.bats:340` — `settings "Build-loop policy: $s" "" "Self-merge never: none"`; need: `scripts/build-loop.sh:245-246` — `if [[ "$v" == self-merge && -z "$never_ok" ]]; then POLICY_LINE="policy review unset: ...`.

**Evidence:** `scripts/build-loop.sh:245-246`, `scripts/build-loop.sh:290-309`; `test/scripts/build-loop-read.bats:340`; p7.log; bats-read.log

---

## Claim 43: commit c143b929 — "426 changed code lines against U1b"

**Location:** commit c143b929
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers added+deleted lines under scripts/ and test/ in the three-dot diff; excludes docs/reviews/.

`git diff --numstat feat/build-loop-u1b...c143b929 -- scripts test` → 170+8, 1+1, 2+2, 32+2, 205+3 = 426.

**Evidence:** command output in this session (numstat, cwd worktree, exit 0, 2026-10-05T16:46Z)

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 4** (`scripts/build-loop.sh:35-37`): the near-miss rule is ASCII-only and skips fenced lines; `Н2: x` (Cyrillic, R1's own shape), `Ｈ2: x` and a fenced `H2: x` still print `constraints ok`. Say "ASCII letters and digits ... outside a code fence", or extend the check.
- **Claim 10** (`scripts/build-loop.sh:54-60`): "Any other tip is working" omits that a "handoff:"-prefixed non-marker is a skip; "alone on its first line" omits that a whitespace-only second line is refused.
- **Claim 13** (`scripts/build-loop.sh:66-67`): the shared-branch skip applies only when the argument brief is open; a done/dropped brief sharing a branch prints ok.
- **Claim 17** (`scripts/build-loop.sh:194-197`): "the gate" is planned, not in the file; NEVER has no reader yet.
- **Claim 29** (`test/scripts/build-loop-read.bats:254`): `--marker` is a planned U3b mode, not an existing one.
- **Claim 40** (commit c143b929, R1): same ASCII/fence residue as Claim 4.
- **Claim 41** (commit c143b929, A1): the raw object is still read for the NUL check.

### Unverifiable
- **Claim 5** (`scripts/build-loop.sh:30`, `:37`): "every loop prompt carries" and "Only ok lets the orchestrator dispatch" need U3's `--prompt` and U4's skill.

## Goal-Alignment Note

**Goal:** Final confirming fact-check of U1c (HEAD c143b929) before it merges into feat/build-loop-u1b.
**Alignment:** Aligned — every in-scope comment, help clause, test name and the four commit messages were checked, mostly by execution; no claim is Incorrect or Stale. The one item touching the Q-112 reporting criterion is Claim 4/40: a Cyrillic or fullwidth H, or a fenced line, can still drop a would-be hard constraint while the line reads `constraints ok`. Whether that is inside Q-112's accepted best effort is for the orchestrator to decide.
