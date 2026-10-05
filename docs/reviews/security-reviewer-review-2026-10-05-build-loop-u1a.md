Commit: 2da477b7

# Security Review — feat/build-loop-u1a (U1a, review-fix iteration 2)

**Scope:** `git diff main...feat/build-loop-u1a` over scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, plus commit messages (docs/reviews/ files excluded)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3, Commit 2da477b7), `docs/reviews/code-fact-check-report-build-loop-u1a.md`; escalation #3 addressed to this critic.

## Trust Boundary Map

```
B1:        [refs/heads/main | origin/HEAD in the shared .git]  → [resolve_main / main_by_name]          → [MAIN_SHA, the trusted snapshot]
B2 (new):  [tree entries under MAIN_SHA]                       → [main_entry: one ls-tree -t, map m[]]  → [verdict blob|absent|notfile|notdir|error]
B3 (moved):[blob bytes at MAIN_SHA:path]                        → [git cat-file | FENCE_AWK (+ANSWER_AWK)] → [BRIEF[...] / check_answer result line]
B4 (removed for answers): [working tree docs/working/questions*.md] → [was: skipped + awk on file]        → [no longer read by check_answer]
B5 (new):  [git process exit status / object-store integrity]   → [$(...) assignment under the caller's set -e/pipefail] → [caller's skip-or-answer decision]
B6:        [CLI args: brief path, Q-ID]                         → [pathform/isbrief, ^Q-[0-9]+$]         → [git argv / awk -v]
```

Input-source classification:

```
S1: refs/heads/main, origin/HEAD       — runtime-mutable — UNTRUSTED toward authorization (any process with write to .git, loops
                                                            included, can move them; plan F19/F28 covers "a forged commit on main");
                                                            treated as the trust anchor by design (D8)
S2: tree objects under MAIN_SHA        — runtime-mutable — UNTRUSTED toward the "regular file under plain dirs" decision (an object
                                                            can be malformed: duplicate entries pass local merges without fsck)
S3: blob contents on main              — runtime-mutable — UNTRUSTED toward print/exec/path sinks; parsed only under FENCE_AWK
S4: CLI args (brief path, Q-ID)        — request-time    — UNTRUSTED; pathform/isbrief and ^Q-[0-9]+$ before any git/awk use
S5: docs/working/questions{,-archive}.md — code-constant — trusted (all sinks)
S6: git exit status / object presence  — environment     — trusted as a signal only if the caller observes it (B5)
S7: working tree                       — runtime-mutable — UNTRUSTED (all sinks); check_answer no longer reads it; check_brief
                                                            still runs blocker on it
```

The diff moves the answer reader from the loop-writable working tree (B4) onto main's commit (B1-B3) and adds main_entry as the guard that the blob read is a regular file under plain directories. Two assumptions are not enforced: that main_entry's verdict and `git cat-file`'s path resolution agree (B2→B3), and that a failed `git cat-file` reaches the caller as a failure (B5). Inside `$(...)`, or under `if !`/`||`, set -e is off and nothing in the lib checks it.

## Findings

#### 1. main_entry and `git cat-file` resolve a duplicate-entry tree differently, so a symlink's target text is read as questions.md (or a brief)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:262` (map), `:547` and `:286` (reads)
**Boundary:** B2 → B3 (S2)
**Move:** #11 (bypasses for the main_entry guardrail), #4 (check/use mismatch)
**Confidence:** Medium (mechanism executed; reachability needs a malformed tree object on main's commit)
**Legibility-target:** for-author

**Evidence:**
```
  while IFS=$'\t' read -r mode path; do [[ -n "$path" ]] && m["$path"]="${mode%% *}"; done <<<"$out"
```
```
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"
```
(excerpt ends :262; the enclosing main_entry() continues to :267, which was read: it consults only `m[...]`.)

main_entry keeps the **last** ls-tree line per path. `git cat-file blob SHA:path` resolves the **first** matching tree entry. If a tree lists `120000 questions.md` and then `100644 questions.md`, main_entry prints `blob` and cat-file reads the symlink's blob. A symlink blob holds arbitrary bytes, and here it held an ANSWERED entry. Executed in a scratch repo, using a duplicate-entry tree built with `git hash-object -t tree --literally` and committed as main:

```
120000 blob 4f6ad29…	docs/working/questions.md      (ANSWERED, [1])
100644 blob 8c1ad0d…	docs/working/questions.md      (OPEN)
entry=blob
out=[keep Q-1]
```

With the order reversed (regular file first), the result is `entry=notfile` and a skip. The guard therefore fails open in exactly one order. A duplicated parent directory (`120000 working` before `040000 working`) gives `entry=blob`, then a cat-file failure, which leads to Finding 2. `git fsck` flags these trees (`duplicateEntries`), but local fast-forwards, `update-ref` and commit-tree do not run fsck. A loop's branch that carries such a subtree can reach main whole when it is fast-forwarded, or when the merge tree reuses the branch's unchanged `docs/working` subtree. `git diff` does show both entries, so a human reviewer would see the symlink. The weak spot is the unreviewed path: the `--approved Q-NNN` gate (U2) reads exactly this answer. This is a stealthier variant of plan F19 (a forged commit on main), not a new class, but it defeats the specific property main_entry's comment promises: "a file read from it is never a symlink's target text". The same mechanism applies to brief_fields, because check_brief's Status line is read the same way.

**Recommendation:** In main_entry, treat a path that ls-tree prints twice as `error` (or `notfile`). One check fixes it: `[[ -n "${m[$path]+x}" ]] && dup=1` in the read loop, then `error` if `dup` is set. Add a bats case with a `--literally` duplicate-entry tree.

**Verification:** run in a scratch dir: build a tree with `120000 questions.md <answered-blob>` followed by `100644 questions.md <open-blob>` via `git hash-object -t tree -w --literally`, wrap it in `docs/working`, commit-tree it, `update-ref refs/heads/main`, then `source lib; resolve_main; out="$(check_answer Q-1)"`. Today this prints `keep Q-1`; after the fix it should print a skip.

#### 2. A failed `git cat-file` is swallowed: check_answer turns a refusal into the archive's answer, and brief_fields returns 0 with no keys (escalation #3)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:547-548` (check_answer), `:286-299` (brief_fields)
**Boundary:** B5 (S6), feeding B3
**Move:** #3 (error path)
**Confidence:** High for the mechanism (executed); Low-to-Medium for reachability (missing object after a `blob` verdict: a partial clone `--filter=blob:none` offline, a damaged object store, or the duplicate-parent tree of Finding 1)
**Legibility-target:** for-author

**Evidence:**
```
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"
    [[ -n "$r" ]] || continue
```
```
  out="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'
```
(brief_fields' excerpt ends :286; the function continues to :300, which was read. On empty `out`, the `while read` loop runs one iteration on `''` and the function returns 0.)

The lib header tells callers to read answers as `out="$(check_brief ...)"`. bash 5.2 does not keep errexit inside a command substitution (inherit_errexit is unset; the lib does not set it). So when cat-file fails on questions.md, `r` is empty, the reader `continue`s to the archive, and the cross-file duplicate refusal ("an entry with this heading in both …") never fires. Executed, with questions.md holding Q-1 `OPEN` and the archive holding Q-1 `ANSWERED [1]`:

```
intact:                    out=[skip Q-1: an entry with this heading in both docs/working/questions.md and docs/working/questions-archive.md]
questions.md blob missing: out=[keep Q-1]
with shopt -s inherit_errexit: exit=128
```

For brief_fields under `||`/`if !` (escalation #3), executed after deleting the brief's blob: main_entry says `blob`, cat-file fails with "bad file", and brief_fields returns 0 with `n=0 odd=[] policy=[unset] paths=[unset]`. check_brief then prints the misleading `skip …: its first Status: line is not exactly …`. That still fails closed today, because every key is unset together and Status validation rejects it. A U1b consumer, though, cannot tell "brief has no Policy/Paths/Asked line" from "brief could not be read". That is the same class as iteration 1's A2 (an error read as absent), which this commit fixed for main_entry only. Called directly under dev-cycle.sh's set -e, both readers instead exit 128 with no answer line (fails closed, but violates the "one printed line per argument" contract).

The escalation's premise is confirmed. Its impact today is safe for brief_fields and fail-open for check_answer under the documented `$(...)` calling pattern. Partly pre-existing: the old working-tree reader also ignored awk's failure status. The cat-file pipe, and with it the missing-object/duplicate-tree triggers, are new in this diff.

**Recommendation:** Check the assignment explicitly, in a way that works whether or not set -e is live. In check_answer: `r="$(…)" || { echo "skip $a: $f could not be read from the default branch"; return; }`. In brief_fields: `out="$(…)" || { BRIEF=(); BRIEF_ODD="error"; return 1; }`, with an `error)` arm in check_brief's BRIEF_ODD case. pipefail (inherited into `$(...)`) makes the assignment's status cat-file's.

**Verification:** in a scratch repo, commit questions.md (Q-1 OPEN) and questions-archive.md (Q-1 ANSWERED [1]), `rm .git/objects/xx/yyyy` for questions.md's blob, then `bash -c 'set -euo pipefail; source lib; resolve_main; out="$(check_answer Q-1)"; echo "$out"'`. Today it prints `keep Q-1`; after the fix it should print a skip.

## Untested bypass candidates (main_entry guard)

- A gitlink (160000) at the leaf or at a parent. Traced only (the case arms send it to `notfile` / `notdir PART`); not executed.
- A pathform-legal name that ls-tree would quote (core.quotePath). Traced: NAMECHARS is ASCII `[A-Za-z0-9._/-]`, so nothing is quoted. Not executed under `core.quotePath=false` / odd configs.
- brief_fields called by a future caller with `./x` from a subdirectory (cat-file is cwd-relative for `./`, while main_entry is `--full-tree`). Traced: pathform rejects `.`/`..` segments, and the contract requires pathform first. Not exercised, because there is no U1b caller yet.

Tested: a symlinked parent directory (suite test, `notdir docs/working`), duplicate leaf entries in both orders (Finding 1), duplicate parent entries in both orders (Finding 1 / Finding 2), and a missing blob after a `blob` verdict (Finding 2).

## Endorsement Claims

The main_entry guard has findings and untested candidates, so it does not appear here as a guard.

- **Claim:** check_answer never opens a working-tree path; both files are read only as `MAIN_SHA:<constant path>` objects.
  **Location:** `scripts/lib/dev-cycle-read.sh:538-547`
  **Evidence:** read-static
  **Verified:** read check_answer :534-560; the only reads are `main_entry "$f"` and `git cat-file blob "$MAIN_SHA:$f"`, with `f` from a two-element constant list.
  **Not verified:** whether ANSWER_AWK/FENCE_AWK (defined earlier in the file) reference any file other than stdin.
  **route: code-fact-check**
- **Claim:** The Q-ID reaching `awk -v id=` matches `^Q-[0-9]+$`, so awk's `-v` escape processing has no backslashes to act on.
  **Location:** `scripts/lib/dev-cycle-read.sh:536`, `:547`
  **Evidence:** read-static
  **Verified:** the regex test at the top of check_answer returns before any git/awk call.
  **Not verified:** U1b/U2 callers that might build ANSWER_AWK invocations themselves.
- **Claim:** `git cat-file blob "$MAIN_SHA:$1"` cannot be parsed as an option, because its argument starts with the hex MAIN_SHA.
  **Location:** `scripts/lib/dev-cycle-read.sh:286`, `:547`
  **Evidence:** read-static
  **Verified:** MAIN_SHA is set only by resolve_main (from `rev-parse`), and main_by_name gates both readers' callers.
  **Not verified:** a U1b caller that sets MAIN_SHA itself.
  **route: code-fact-check**
- **Claim:** main_entry prints `error` (never `absent`) when ls-tree exits non-zero or main is not found by name, and both current callers skip on `error`.
  **Location:** `scripts/lib/dev-cycle-read.sh:259-261`, `:320-326`, `:539-545`
  **Evidence:** read-static (the Stage-1 fact-check reports it executed: bad SHA gives exit 128 and `error`)
  **Verified:** read both `|| { echo error; return; }` arms and both callers' `error)` case arms.
  **Not verified:** ls-tree exiting 0 with partial output on a damaged tree (not exercised).
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec of `git` / `awk` with repo- or argument-derived argv

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:261` `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` | S4 (via callers), S5 | `--`, pathform by caller, hash-only MAIN_SHA | cleared for injection; map semantics → Finding 1 |
| `scripts/lib/dev-cycle-read.sh:286` `git cat-file blob "$MAIN_SHA:$1" \| awk "$FENCE_AWK"…` | S4, S3 | main_entry by caller | Findings 1, 2 |
| `scripts/lib/dev-cycle-read.sh:547` `git cat-file blob "$MAIN_SHA:$f" \| awk -v id="$a"` | S5, S4 (Q-ID), S3 | main_entry; `^Q-[0-9]+$` | Findings 1, 2 |
| `scripts/lib/dev-cycle-read.sh:350-351` `git log … -G'^Status: ' "$MAIN_SHA" -- "$a"` (unchanged context) | S4 | pathform, isbrief, `--` | cleared, not changed by this diff |
| `scripts/dev-cycle.sh:191-203` check dispatch (`check_answer "$a"`) | S4 | per-function validation | cleared; exit-128 behaviour noted in Finding 2 |

Primitive: printing repo text (S3) to the terminal. BRIEF values are raw blob text (minus NUL/CR/LF). The lib's comment leaves judging and printing to callers ("The callers judge the values"; output through scrub). No new print sink in this diff echoes BRIEF values or answer text: check_answer prints only an option word from ANSWER_AWK's `option()`, and the skip lines carry constant paths and numbers. Cleared for this diff; U1b's printing of BRIEF values is out of scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Duplicate tree entries: main_entry (last wins) and cat-file (first wins) disagree, so a symlink's target text is read as an answer | Medium | B2→B3 | `scripts/lib/dev-cycle-read.sh:262` | Medium |
| 2 | A failed cat-file is swallowed: check_answer returns the archive's answer instead of the cross-file skip; brief_fields returns 0 with no keys (esc. #3) | Medium | B5 | `scripts/lib/dev-cycle-read.sh:547-548`, `:286-299` | High (mechanism) / Low-Med (reach) |

## Overall Assessment

The change does what D8 asks: answers are no longer read from a loop-writable working tree, and iteration 1's R1/A1/A2 fixes hold within the paths read (NUL refusal and `error` verdicts are wired to skips in both callers). Both remaining issues sit on the error and edge paths of the new main-commit reader, and both can be fixed in place with a few lines. Finding 1 refuses duplicate ls-tree paths in main_entry. Finding 2 checks the `$(git cat-file … | awk …)` status in check_answer and brief_fields rather than relying on the caller's set -e, which `$(...)`, `if !` and `||` all disable. Neither is an architectural problem. The single most important fix is Finding 2's check_answer guard, because U2's `--approved Q-NNN` merge gate will consume exactly this answer through the `$(...)` pattern the lib header recommends. Otherwise: no further findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path given in your tail, structured per your skill, with `Commit: 2da477b7` as its first line.
- Answered: security review of `main...feat/build-loop-u1a` at 2da477b7, with escalation #3 confirmed by execution (safe for check_brief today, fail-open for check_answer under the `$(...)` pattern), plus one new guard bypass (duplicate tree entries).
- Out of scope: U1b/U1c consumers of BRIEF values (unset-key semantics, printing); escalations #1 and #4 (addressed to other critics/the orchestrator); settled rows 201, 208, 213, 215, 220, 221 (not re-raised; nothing here contradicts them). Plan F19 (forged commit on main) is not re-raised as such; Finding 1 is a narrower defect in main_entry's own promise.
- Escalate: Finding 1's reachability depends on whether U2's merge path (merge-tree → commit-tree) or local fast-forwards can carry a duplicate-entry tree onto main without fsck. That is worth a `transfer.fsckObjects`/`fsck` question for the U2 gate design.
