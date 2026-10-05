Commit: 553a50d5

# Security Review — feat/build-loop-u1c (U1c: constraints line and --status)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` (859e29e8, aaae80c6, 553a50d5); lib `scripts/lib/dev-cycle-read.sh` read as context only
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (k=1, 553a50d5) and the shared Stage-2 context
**Probes:** throwaway repos under /home/node/.claude/jobs/989f3e5a/tmp/review-u1c/security/ (probe1-4.sh, logs probe1-4.log; temp repos removed after each run); git 2.39.5, bash 5.2.15

## Trust Boundary Map

```
B1 (new): loop-written refs and commit objects (branch tip) → check_branch (lib) + marker_kind :255-280 → LOOP/SHA/DATE/REASON in "ok" lines (orchestrator dispatch, collect, gate)
B2 (new): docs/constraints.md on main's commit (human-written; loops N-denied, F54) → main_file + CONSTRAINTS_AWK :149-168 → "constraints ok" (the dispatch gate, D2)
B3 (new): briefs on main's commit (orchestrator-written) → brief_fields / shared_branches :284-295 / status_line :296-331 → POLICY, BRANCH, DISPATCHED, F31 skip
B4: loop-writable working tree → check_brief's blocker walk (lib :327) → "skip" lines
B5: loop-writable .git metadata (info/grafts, shallow, refs/remotes/origin/HEAD) → resolve_main / rev-list --count (lib :378) → MAIN, ahead count
B6: every printed repo-derived byte → scrub (lib :48-80, via scrub_reexec :80) → orchestrator terminal / parser
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | Branch tip commit object (header lines, message, committer date) | request-time (loop writes any ref/commit, incl. `hash-object --literally`) | UNTRUSTED for git-argument, marker-decision and output sinks |
| S2 | docs/constraints.md blob on main | runtime-mutable by humans only (N-denied for loops) | UNTRUSTED for the dispatch-gate sink: authoring errors are the realistic input, so the parser must fail closed on near-misses |
| S3 | Brief blobs on main (Status/Branch/Policy/Dispatched lines) | runtime-mutable (orchestrator/human; loops N-denied) | UNTRUSTED for git-argument and output sinks (Branch goes to show-ref); trusted-as-written for policy only via the exact-match rules |
| S4 | Working tree at the brief path | request-time (loop-writable) | UNTRUSTED for all sinks; used only to refuse |
| S5 | .git/info/grafts, .git/shallow, origin/HEAD symref | request-time (loop-writable) | UNTRUSTED for history-walk sinks (ahead count, -G walk, resolve_main) |
| S6 | Command-line BRIEF args | orchestrator-supplied | trusted-as-intent; still pathform-checked before use |

Prose: S1 is the one fully loop-controlled input this diff adds a parser for, and the parser (marker_kind) reads the raw commit object by its own rules rather than git's; S2 and S3 come from main, where loops cannot land edits, so their risk is authoring errors that pass the gate silently. The origin/HEAD part of B5 is settled (override-log rows 209 and 247, deferred to U3b's `--state`); this diff adds --status as another reader of `resolve_main` but does not change that premise (a loop that controls MAIN could already raise POLICY via --settings), so it is not re-raised.

## Findings

#### 1. marker_kind's view of the tip commit diverges from git's: a non-empty, parentless or NUL-bearing tip reads `ready`

**Severity:** Medium
**Location:** `scripts/build-loop.sh:257-267`
**Boundary:** B1
**Move:** 11 (bypasses for every guardrail), 2 (implicit sanitization)
**Confidence:** High (mechanism, executed); Medium (impact, depends on U2/U3b)
**Legibility-target:** for-author

**Evidence:**
```
  raw="$(git cat-file commit "$1")"
  hdr="${raw%%$'\n\n'*}"; msg=""; [[ "$raw" != *$'\n\n'* ]] || msg="${raw#*$'\n\n'}"
  subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
  while IFS= read -r l; do
    case "$l" in "tree "*) tree="${l#tree }" ;; "parent "*) np=$((np + 1)); parent="${l#parent }" ;; esac
  done <<<"$hdr"
  if [[ "$np" -eq 0 ]]; then echo "bad it has no parent"; return; fi
  if [[ "$np" -gt 1 ]]; then echo "bad it has $np parents"; return; fi
  ptree="$(git rev-parse --verify --quiet "$parent^{tree}" || true)"
  if [[ "$tree" != "$ptree" ]]; then echo "bad it changes files"; return; fi
```
(excerpt ends :267; enclosing marker_kind() continues to :280 — read; its output flows to status_line :323-330 — read)

F20's defence is "an empty single-parent commit at the branch tip" (D3; help text `:47-49`). The loop that the threat model lets write "commits with arbitrary messages, trees and parents" can write a commit object with `git hash-object -t commit --literally`, and the loop above parses that object by rules git does not use: the **last** `tree` line wins (git uses the first), a `parent` line is counted **anywhere** in the header (git reads parents only directly after `tree`), and the parent value goes to `rev-parse` as a **revision expression**, not a checked 40-hex id. The `$(...)` also drops NUL bytes that git keeps. Executed in throwaway repos (probe1.log, probe4.log), each tip printed `ok … feat/a ready <sha> …`:

| Crafted object | git's view | --status |
|---|---|---|
| `tree EVIL` / `parent P` / author / committer / `tree P^{tree}` | tree EVIL: `git diff --stat P X` shows `evil.txt \| 1 +` | `ready` |
| `tree P^{tree}` / author / committer / `parent P` | `%P` empty: a root commit | `ready` |
| both of the above combined | root commit with tree EVIL | `ready` |
| `parent feat/a` (a ref name, after committer) | root commit; the "parent" is resolved by name at read time | `ready` |
| message `handoff: \0ready` | `%s` is `handoff: ` | `ready` (stderr: "ignored null byte") |

So --status reports a marker the loop did not produce in the allowed shape, which is the property F20 and this task's threat model name. Impact today is bounded: D7's gate builds its diff with git's own tree (merge-tree/diff-tree on TIP), so the extra `evil.txt` would still be in the gate's path list and in a review merge entry; the orphan case depends on how U2's merge-tree treats unrelated histories, and the NUL case on whether U3b's `--marker` reads the message the same way. Those later units are the dependency; the shape guarantee stated here at `:47-52` is false now.

**Recommendation:** Read tree and parents the way git does and refuse anything git would not write: require the header's first line to be `tree <40-hex>`, the following lines to be consecutive `parent <40-hex>` lines, and no later line to start `tree ` or `parent `; then cross-check with git's own parse (`git rev-parse "$1^{tree}"` equals the header's tree; `git log -1 --format=%P "$1"` equals the parent list, run with grafts off, see Finding 4). Refuse a commit whose raw bytes contain NUL (e.g. `git cat-file commit "$1" | tr -d '\0' | cmp` or `grep -c $'\0'` in C locale). Add the five rows above to T7.

#### 2. Near-miss hard constraints are dropped silently and `constraints ok` still prints

**Severity:** Medium
**Location:** `scripts/build-loop.sh:152`, `scripts/build-loop.sh:160`
**Boundary:** B2
**Move:** 11 (bypasses for every guardrail), 5 (invert the access model: what does `ok` not cover?)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
/^(- )?[HS][0123456789]+: [^ \t]/ {
```
(`:152`; the rule's body runs to `:159`; the END block `:161-168` turns a run with no problem into `"ok " hard + 0 " " soft + 0`)
```
/^[ \t]*(- )?success: [^ \t]/ { pend = "" }
```
(`:160`)

A line that is meant as a hard constraint but misses the exact shape matches neither rule, so it is not counted, never needs a `success:` line, and the file still reads `ok` — the only state that lets the orchestrator dispatch (`:32`, plan D2/F55). Executed with `- H1: never lose a row` / `  success: counts match` followed by one near-miss third line (probe2.log): every one of `* H2:`, `+ H2:`, `1. H2:`, `  - H2:`, `-  H2:`, `H2:  x` (two spaces), `H2:<TAB>x`, `H2 : x`, `**H2:** x`, `### H2: x`, `> H2: x`, `h2: x`, Cyrillic `Н2: x` and `| H2 | x |` printed `constraints ok 1-hard 0-soft`. Separately, `H1: a` then a blank line, `## Unrelated`, blank, `success: is not guaranteed by anything` reads `ok 1-hard`: any later column-0 or indented `success: ` line satisfies the pending constraint, across headings. And `H1` and `H01` are distinct IDs (`ok 2-hard`), so "no ID may repeat" (`:31-32`) does not stop two constraints a reader would call H1. Loops cannot edit this file (F54), so the realistic input is a human typo; but the threat model for this unit names exactly this outcome ("make `constraints ok` print when a hard constraint lacks its success line"), and the file sits next to the --settings keys that already use a letters-only "copy" rule (`:33-35`) precisely so that markup cannot hide a line.

**Recommendation:** Apply the same copy rule as SETTINGS_AWK: a line whose markup-stripped, case-folded start looks like a constraint ID (e.g. after dropping `[-*+>#|` and blanks, digits-dot list markers and `*`/`_`, it matches `^[hs]0*[0-9]+[ \t]*:`) but fails the strict `:152` pattern makes the file `unreadable` with its line number; compare IDs numerically (`H01` = `H1`); and end a pending hard constraint's search window at the next heading or blank-line-separated block, or require the `success:` line to be the constraint's own indented continuation. Add these shapes to T44.

#### 3. F31's shared-branch count ignores briefs/closed/, which --status still reports

**Severity:** Low
**Location:** `scripts/build-loop.sh:287`, `scripts/build-loop.sh:312`
**Boundary:** B3
**Move:** 5 (invert the access model)
**Confidence:** Medium (static plus the fact-check's executed Claim 13/45; impact needs a main-side authoring error)
**Legibility-target:** for-author

**Evidence:**
```
  list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/)"
```
(`:287`; enclosing shared_branches() runs `:284-295` — read; `ls-tree` without `-r` lists only direct children, and `isbrief` at `:289` refuses `closed/` paths anyway)
```
  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
```
(`:312`; enclosing status_line() continues to `:331` — read)

check_brief accepts `docs/working/briefs/closed/…` and status_line reports its state (lib `:324`, `:317`). A closed/ brief that reads `Status: open` and names `feat/x`, plus an open brief directly under briefs/ naming `feat/x`, gives a count of 1, so the briefs/ brief prints `ok` against a branch another brief also claims — the F31 case "another loop's brief reads as its own". Briefs on main are cycle-owned (loops cannot land them), and a closed/ brief reading open is already an inconsistent state, hence Low.

**Recommendation:** Count `closed/` briefs too (one more `ls-tree` path and the closed/ regex already at lib `:324`), or have status_line skip a closed/ brief whose Status is open. Either way the help text `:58-59` should say which briefs F31 counts.

#### 4. The ahead count honours .git/info/grafts (and shallow), unlike the replace refs the script already disables

**Severity:** Informational
**Location:** `scripts/build-loop.sh:97`, `scripts/build-loop.sh:322`
**Boundary:** B5
**Move:** 4 (TOCTOU / indirection), 11
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```
(`:97`)
```
  if [[ "$ahead" -gt 0 ]]; then
```
(`:322`; `ahead` is check_branch's `git rev-list --count "$MAIN_SHA..$sha"`, lib `:378`)

With main at M2 and M1 (a `handoff: ready` commit already on main, e.g. after a fast-forward) as feat/a's tip, --status printed `working`; after writing M2's id into `.git/info/grafts` (M2 parentless) the same run printed `ok … feat/a ready <M1> …` (probe1.log, case 5). `GIT_GRAFT_FILE=/dev/null` turns this off (probe3.log: count 4 → 0). Informational rather than Medium because a loop that can write `.git/info/grafts` can equally move any ref, including the branch itself, so this adds no capability under the stated threat model; it is a consistency gap next to `GIT_NO_REPLACE_OBJECTS`, and the same graft view also feeds check_brief's `-G` walk and the future gate. `.git/shallow` has the same effect and has no environment switch.

**Recommendation:** Export `GIT_GRAFT_FILE=/dev/null` beside `GIT_NO_REPLACE_OBJECTS=1`, and note shallow as an accepted limit (or refuse to run when `git rev-parse --is-shallow-repository` says true) before U2's gate relies on ancestry.

#### 5. DATE is not always YYYY-MM-DD: a crafted committer line prints `%cs` or 1970-01-01

**Severity:** Informational
**Location:** `scripts/build-loop.sh:330`
**Boundary:** B1
**Move:** 7 (type confusion at a serialization boundary)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
  echo "ok $a $st $pol $br $loop $sha $date $disp$reason"
```
(`:330`, last line of status_line; `date` comes from check_branch's `git log -1 --format=%cs`, lib `:378`)

Committer lines `-5 +0000`, `x y` or empty made the DATE field the literal text `%cs`; `99999999999999999999 +0000` gave `1970-01-01` (probe1.log, case 4). The field count is unchanged and scrub covers the bytes, so nothing is injected, but the help text (`:46`) promises YYYY-MM-DD and DATE is committer-controlled in any case (lib `:364-365` already says a future date is possible). Anything that later computes ages from DATE (the `--steal` "tip over 2 hours old" rule, plan line 40) should not trust it.

**Recommendation:** Print `-` unless DATE matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`, and keep timing decisions on something the loop cannot write.

## Untested bypass candidates

- A tip commit with an `encoding` header (e.g. `encoding UTF-16`) whose raw subject bytes are `handoff: ready` while git's re-encoded `%s` differs — not built; relevant to U3b's `--marker`, which may read the message through git.
- `.git/shallow` naming main's tip — not run; expected to behave like the graft case (Finding 4).
- A case-insensitive file system (macOS, or WSL on an NTFS mount) where `Feat/X` and `feat/x` are one loose ref — `lower` at `:291`/`:312` is meant for this; not run on such a file system.
- A working-tree symlink planted at another loop's brief path (S4, lib `:327`) — traced only: the brief prints `skip … reached through a symlink`, which fails closed but lets one loop hide another's `blocked`/`ready` line until the symlink is removed; a loop that can move refs can do the same, so not filed.

## Primitive sweep

Primitive: git invocation with repo-derived arguments

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:116` `git cat-file blob "$MAIN_SHA:$f"` | constant path | main_entry blob check | cleared — path is a constant |
| `scripts/build-loop.sh:257` `git cat-file commit "$1"` | S1 (sha peeled by check_branch) | `show-ref --verify` + `^{commit}` | cleared — a hex id |
| `scripts/build-loop.sh:266` `git rev-parse --verify --quiet "$parent^{tree}"` | S1 raw header text | none (any revision expression) | Finding 1 |
| `scripts/build-loop.sh:287` `git ls-tree … "$MAIN_SHA" -- docs/working/briefs/` | constant | `--` and literal pathspecs | cleared |
| `scripts/build-loop.sh:289` `main_entry "$f"` / `brief_fields "$f"` | ls-tree names on main (S3) | isbrief first | cleared — isbrief pins the form |
| `scripts/build-loop.sh:315` `check_branch "$br"` → `show-ref --verify refs/heads/$br` | S3 Branch line | NAMECHARS, no leading `-`, check-ref-format, not HEAD/refs/* (lib `:371-373`) | cleared — executed with `@`, `*`, `$(touch…)`, backticks, `a]b`: no file created, no crash (probe3.log) |
| lib `:378` `rev-list --count`, `log -1 --format=%cs` | S1/S5 | GIT_NO_REPLACE_OBJECTS only | Findings 4, 5 |

Primitive: terminal / parser output

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:299,301,313,317,325,330` and `:340` | S1, S3, S6 | scrub (lib `:48-80`) on both streams; REASON limited to `[ -~]` under `local LC_ALL=C` (`:277-278`) | cleared — T7 executes ESC, é and U+202E reasons without echo; refused Branch names are not echoed (T8) |
| `scripts/build-loop.sh:325` `${kind#bad }` | constant strings from marker_kind | n/a | cleared — never holds commit text |

## Endorsement Claims

- **Claim:** A `handoff: stopped:` reason holding ESC, a non-ASCII byte or U+202E is never printed; the tip reads as a `skip` line instead.
  **Location:** `scripts/build-loop.sh:274-279`
  **Evidence:** executed
  **Verified:** T7 (`test/scripts/build-loop-read.bats:260-265`) with `\x1b[31m`, `caf\xc3\xa9` and `\xe2\x80\xae`; output checked for `\xc3` and `[31m`.
  **Not verified:** that U3b's `--marker` body reader applies the same byte rule to `blocked`/`stopped` bodies.
  **route: code-fact-check**
- **Claim:** A refused Branch: value (control bytes, `$(...)`, `@`, `*`) reaches neither a shell evaluation nor the output, and does not abort the run for other briefs.
  **Location:** `scripts/build-loop.sh:290-291`, `:304-319`
  **Evidence:** executed
  **Verified:** probe3.log: briefs with Branch `@`, `*`, `$(touch${IFS}PWNED)`, backtick form, `a]b`, `x[0]`, `0`, `-1`, `a=b` on main; --status exits 0, prints `skip … not an allowed branch name`, no file created; two `@` briefs both skip under F31.
  **Not verified:** bash versions before 5.2 (associative-array subscript expansion rules changed in 5.2).
  **route: code-fact-check**
- **Claim:** Working-tree and non-main-branch edits to docs/constraints.md and to a brief's machine lines do not change --settings' constraints line or --status' fields.
  **Location:** `scripts/build-loop.sh:237-249`, `:296-331`
  **Evidence:** executed
  **Verified:** T44 (`build-loop-read.bats:147-150`) and T21 (`:332-340`) pass at HEAD per the fact-check (83/83).
  **Not verified:** check_brief's working-tree blocker walk (lib `:327`), which can still turn a brief into a skip.
  **route: code-fact-check**

marker_kind (`:255-280`) is a guardrail with Finding 1 open and untested bypass candidates, so it carries no endorsement.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | marker_kind parses tree/parents/subject by its own rules; non-empty, root and NUL tips read `ready` | Medium | B1 | `scripts/build-loop.sh:257-267` | High (mechanism) / Medium (impact) |
| 2 | Near-miss hard constraints dropped silently; `constraints ok` still prints | Medium | B2 | `scripts/build-loop.sh:152,160` | High |
| 3 | F31 count ignores briefs/closed/ | Low | B3 | `scripts/build-loop.sh:287,312` | Medium |
| 4 | Ahead count honours grafts/shallow | Informational | B5 | `scripts/build-loop.sh:97,322` | High |
| 5 | DATE can be `%cs` or 1970-01-01 | Informational | B1 | `scripts/build-loop.sh:330` | High |

## Overall Assessment

No HALT pattern applies (no secrets, no shell injection: every repo-derived value reaching a shell or git option position is form-checked, and every printed byte passes scrub). The two Medium findings are both fixable in place and both are guardrails that fail open on inputs they do not model: marker_kind trusts its own reading of a raw commit object, which a loop can hand-craft so that --status says `ready` for a tip git sees as changing files or as parentless (Finding 1); and CONSTRAINTS_AWK ignores, rather than refuses, near-miss constraint lines, so the dispatch gate's `ok` does not mean "every hard constraint has a success line" (Finding 2). The single most important fix is Finding 1: take tree and parents from git's own parse with a strict header check (and grafts off), so the F20 shape rule describes the commit every later unit will merge. No findings beyond these within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): Your report saved at the path given in your task tail, structured per your skill, with every finding carrying a verbatim Evidence quote at a `path:line` in this worktree.
- Answered: yes — saved, five findings with verbatim evidence at `scripts/build-loop.sh` lines, three probes executed per Medium mechanism.
- Out of scope: origin/HEAD / resolve_main (override-log rows 209, 247; premise unchanged by this diff); the lib's check_brief working-tree walk (pre-existing, listed under untested candidates).
- Escalate: nothing (no HALT pattern).
- Questions I would have asked: whether U2's gate and U3b's --marker will reuse marker_kind's parse or git's — that decides Finding 1's real impact.
- Decisions I made: rated Finding 4 Informational, not Medium, because writing .git/info/grafts gives no capability beyond the ref writes the threat model already grants; rated Finding 2 Medium under the floor rule although the realistic author is a human, because the task's threat model names that exact outcome.
