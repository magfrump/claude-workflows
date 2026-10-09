Commit: 809df345

# Security Review: feat/build-loop-u2b1b (U2b1b, iteration 1)

**Scope:** `git diff main...HEAD` (809df345 against 0e4596ce): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/reviews/override-log.md`, `docs/working/plan-build-loop-handoff.md`; the lib `scripts/lib/dev-cycle-read.sh` was read for `pathform`, `writable`, `lower`, `brief_fields`, `check_brief`, `resolve_main` (unchanged here)
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2b1b.md` (43 claims, 0 Incorrect) and its merged summary
**Threat classes:** every finding is tagged **honest-path** (inside the plan's "What the gate can and cannot do": a unit red if it holds) or **hostile-loop** (a same-uid loop with a shell: recorded as a Q-103 residual, not a unit red)

## Trust Boundary Map

```
B1: [loop branch: tip commit, tree, path names, modes, blob ids (S2)] → [merge-tree in the gate repo → diff-tree -z parse → nrules (both policies)] → [verdict line + path/deny lines (exit 0/2)]
B2: [repo-local git state and refs: .git/config, info/*, refs/replace, refs/heads/{main,master}, origin/HEAD (S4)] → [state_gate; R7 default-branch refusal (new)] → [MAIN / MAIN_SHA used as the trusted base]
B3: [shared object store: loose/packed objects, alternates (S5)] → [gate_git stderr refusal; cat-file -e on main, tip and merge-base trees (new)] → [merge result TREE]
B4: [GATE_TMP files: git/config, git/HEAD, work/, err (new), diff (new) (S6)] → [no guard; mktemp -d mode 700 does not stop the same uid] → [config read by every gate_git call; err and diff read back by gate_git and check_line]
B5: [path names from the merge (S2)] → [NAMECHARS filter: "?" unless every byte is allowed] → [stdout lines that a Q entry quotes (D4)]
```

Input-source classification:

```
S1: brief path argument (CLI)          — request-time    — trusted caller; still validated (check_brief: pathform, anybrief) before any git arg or compare
S2: loop branch content (refs/heads/*) — runtime-mutable — UNTRUSTED for all sinks (rules input, git args, stdout); loop-written
S3: main's committed content (MAIN_SHA)— runtime-mutable — trusted as the rules' reference (D6: the gate decides from main's commit);
                                                           the ref itself is loop-writable (S4), D13 covers it
S4: repo-local git state, refs         — runtime-mutable — UNTRUSTED toward exec/merge-shaping sinks; refused before reads (B2),
                                                           TOCTOU after the gate is deferred (override row 494, F7)
S5: object store                       — runtime-mutable — UNTRUSTED for integrity (an object can be missing or come via alternates)
S6: GATE_TMP contents                  — runtime-mutable — gate-written but same-uid-writable: UNTRUSTED toward the git-config/attributes
                                                           sink and the diff/err read-back sink (R8)
S7: caller environment (GIT_CONFIG_*)  — deploy-time     — trusted (stated at harden: the caller's own git -c wins)
S8: code constants (NAMECHARS, regexes, FENCE_AWK, perl -pe program) — code-constant — trusted
```

What enters from outside: everything about the branch (S2) is loop-written, and so are the repo's state (S4), the object store (S5) and, against a concurrent writer, the gate's own temp directory (S6). The diff adds B1's path judgment, tightens B2 (R7) and B3 (R6), and widens B4 by two read-back files. It assumes the object store and GATE_TMP are not written concurrently. That holds on the honest path and is the plan's stated non-goal on the hostile one.

## Findings

#### F1. own_blob's exit status is dropped: a failed read of main's brief compares as the empty blob (fail-open shape)

**Severity:** Low
**Class:** hostile-loop (the honest path cannot reach it: the same blob was read successfully moments earlier)
**Location:** `scripts/build-loop.sh:547` (caller) and `scripts/build-loop.sh:527-533` (own_blob)
**Boundary:** B1, B3
**Move:** 3 (error path)
**Confidence:** High (the mechanism ran); Low that it can be reached without a racing writer
**Legibility-target:** the U2b1b author (a one-line fix in this unit)

Evidence (verbatim):

```
    [[ "$5" == M && "$2" == "$3" && "$4" == "$(own_blob "$1")" ]] || DENY="this brief: only its first Status: line outside a fence may change, from open to done"
```
```
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
```

own_blob reads main's brief twice. The awk pass (`:531`) is status-checked (`|| return 1`), but the second `git cat-file` (`:533`) feeds a pipeline whose last stage, `hash-object --stdin`, still prints an id when the first stage fails. nrules compares that printed id and never checks own_blob's status. If the second read fails (the loose object is removed between the two reads, or a transient I/O error), own_blob prints `e69de29b…` (the empty blob) and returns 1. A branch that empties its own brief then has `$4 == e69de29b…`, so the brief path passes with no deny line. Executed: a pipeline of that shape whose first stage is `false` prints `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` with status 1, and the `[[ … == "$(f)" ]]` comparison matches (probe `sec/probe1.sh`, part a). Reaching it for real takes a writer that deletes main's brief object inside a window of a few milliseconds, so it is hostile-loop. The finding is the fail-open shape: everywhere else the unit fails closed.

**Recommendation:** Compare only on success: `ob="$(own_blob "$1")" && [[ "$5" == M && "$2" == "$3" && "$4" == "$ob" ]] || DENY=…`. Reading the blob once (into the awk's NR and then perl over the same bytes) would also remove the double read.

#### F2. A merge whose tree references a missing blob prints ok (fact-check escalation)

**Severity:** Low (advisory `--check` lands nothing; revisit at U3's `--merge` and U2c's content rules)
**Class:** honest-path robustness (a corrupted or partially pruned shared store); a hostile loop can produce it on purpose with `git mktree --missing`
**Location:** `scripts/build-loop.sh:512-521` (merge_result) and `scripts/build-loop.sh:578-593` (check_line's diff loop)
**Boundary:** B3
**Move:** 3 (error path), 4 (check now, use at U3)
**Confidence:** High (executed)
**Legibility-target:** the U3 (`--merge`) and U2c (S rules) builders

Evidence (verbatim):

```
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
```

Executed (`sec/probe1.sh`, part b): a branch adding `new.txt` whose blob was never written (`git mktree --missing`):

```
ok docs/working/briefs/2026-10-01-x.md 888639aea00cdd184a428831e6cb9f208d605c58 6b88a4ea828e9d47ed7687e3526d6db694c4e9f7
path docs/working/briefs/2026-10-01-x.md A new.txt
exit 0
blob-missing
```

R6's guard checks that the top-level trees exist. Neither merge-tree (which never opens a blob only one side changed) nor diff-tree (which compares ids) reads a blob the merge does not need. **This does not bypass any N rule**: the N rules judge path, mode and blob id, and the own-brief rule compares ids, so no content is needed. The risks are later ones. (1) U3's `--merge` would commit-tree and CAS a tree that main cannot check out (fsck errors, and every later checkout or worktree add fails). (2) U2c's S rules, or any later content read (floor's `@`-import walk of a new instruction file, say), must refuse on a missing blob rather than read it as empty. Honest-path reachability is low (honest commits write their blobs), so this is Low today.

**Recommendation:** In check_line's loop, for each record with a new mode other than `000000`, run `gate_git cat-file -e "$no"` and refuse the merge if it fails. That is one call per changed path, the same cost class as the loop. Or add the check before U3 lands and record it as a U3 entry condition. Either way, note in U2c's plan row that content reads must fail closed on a missing object.

#### F3. U2b1b widens R8's surface: the diff and err files in GATE_TMP are read back after git writes them

**Severity:** Informational (folds into R8's disposition; not a separate red)
**Class:** hostile-loop
**Location:** `scripts/build-loop.sh:502-506` (gate_git's err), `scripts/build-loop.sh:578-591` (the diff file)
**Boundary:** B4
**Move:** 4 (TOCTOU)
**Confidence:** High (read-static; the race was not run, since R8 already demonstrated writes into GATE_TMP 3 of 3)
**Legibility-target:** the user, via the Q-103 residual's wording

Evidence (verbatim):

```
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
```
```
  if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree" > "$GATE_TMP/diff"; then
```
```
  done < "$GATE_TMP/diff"
  # Every record read whole: two NUL-ended fields each.
  if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * i)) ]]; then
```

R8, as recorded, was about planting config or attributes before merge-tree. This unit adds two files whose contents decide the verdict. A writer that truncates `diff` after diff-tree exits and before the read loop makes every changed path vanish: `i=0` and the NUL count is 0, so the gate prints `ok … TREE` with no path lines, and a denied path's merge reads ok. A writer that empties `err` hides R6's warning. Neither gives a same-uid loop anything it lacks (see the R8 recommendation below), but Q-103's entry should name the full surface: `git/config`, `git/info/`, `work/.gitattributes`, `err`, `diff`.

**Recommendation:** Name all five in the R8 residual. Optional and not required: stream diff-tree into the loop (`< <(gate_git …)` plus a NUL count taken from the same stream) and keep stderr in a variable, which takes two files off the surface at no cost. It does not close R8 (`git/config` remains), so do it only if it also simplifies the code.

## R8 recommendation: record it as a Q-103 residual, not a fix in this unit

**Recommendation: Q-103 residual.** Reasoning, tied to the plan's "What the gate can and cannot do" (`docs/working/plan-build-loop-handoff.md:31-35`):

1. **The plan names this exact capability as outside scope.** It says: "Loops run as your uid, with a shell … No script can contain a loop that turns hostile with its shell. It could run plain `git merge` or `git push`, write any working tree under `/workspace`, or plant `.git` state. What this design does is make the **honest path** safe and checkable." Writing GATE_TMP needs the same uid and deliberate hostility: a process has to find another process's fresh mktemp directory and race it. No honest slip (a command in the wrong directory, D13's case) writes into a directory created by `mktemp -d` that it did not create.
2. **A fix cannot be built inside the script.** Mode 700, O_EXCL, a random name, or a directory outside `/tmp` all stop other uids, not the same uid, which can list `$TMPDIR` or watch it with inotify. Closing it needs a uid or mount-namespace boundary (the gate under another user, or bwrap with a private tmp and a read-only object store), which is a deployment decision, not a U2b1b change.
3. **Fixing it would buy nothing while the cheaper routes stay open.** The same writer can (a) plant `.git/config` after state_gate passes (override row 494, F7, already deferred to U3b's `--state`); (b) write objects or `objects/info/alternates` into the store that GATE_ENV's `GIT_OBJECT_DIRECTORY` points at (A17's F3 row, deferred to U3); (c) move `refs/heads/main` directly (D13's check). Closing R8 alone moves the hostile loop to (a)-(c).
4. **The honest path is unaffected.** On that path GATE_TMP is unique per run and only the gate writes it. Confirmed by reading `:608` (`mktemp -d`, trap set after a successful assignment, so a failed mktemp exits under `set -e` before any `rm -rf` of an empty path).

**What must accompany the residual so it is not a silent downgrade:**
- Correct override row 494's sentence "the gate repository closes merge-tree" to "closes merge-tree against repo state planted before the run, not against a concurrent same-uid writer". The rubric's R8 row says that sentence is false as written. This is the legibility fix the user reads.
- The Q-103 entry names GATE_TMP's full surface (F3) and the same revisit trigger as row 494: U3b's `--state` or U3's `--merge`, or any move of the gate under another uid or sandbox. At that point GATE_TMP must live where the loop's uid cannot write.
- No unit red is needed: R8 was carried at High as a hostile-loop finding, and the plan classifies it out of scope.

## Untested bypass candidates (N rules matcher, move 11)

Dispositioned candidates (each tested):

| Candidate | How | Outcome |
|---|---|---|
| Case variant of a cycle file (`Docs/Roadmap.md`, `docs/Dev-Cycle.md`) | suite T14 (executed by Stage 1) | denied |
| Case variant of `docs/constraints.md` | read-static `:549-550` (`lower`, then `==`) | denied; not executed (fact-check 26: T14 exercises roadmap and dev-cycle.md only) |
| Rename out of a protected path | suite T11 | D side denied |
| Own brief: an extra line, a mode change, `dropped`, a move to closed/ | suite T15 | denied |
| `.github/`, `-x.md`, non-ASCII, newline in a name | suite T13 | denied, printed as `?` |
| A blob the merge references but the store lacks | probe part b | passes the N rules (they need no content): F2 |

Untested candidates (listed, not dispositioned):

- **Win32 trailing dot (`docs/constraints.md.`, `docs./constraints.md`):** pathform admits a trailing `.`, and an NTFS checkout would alias it to the protected file. Not tested: there is no Windows host, and this repo runs on Linux/WSL ext4, where the name does not alias. Git for Windows' `is_valid_win32_path` is believed to refuse such names at checkout (unverified: the sandbox has no egress). Honest path: not reachable here.
- **A malformed tree (duplicate entry names, or a `/` inside an entry, via `hash-object -t tree --literally`):** how merge-tree and diff-tree print such entries was not probed. Hostile-loop.
- **A gitlink on the old side only:** the regex at `:545` covers `$2`, but only the new side is executed (fact-check 29).

Because the matcher has untested candidates, the N rules as a whole do not appear in Endorsement Claims below.

## Endorsement Claims

- **Claim:** With both `refs/heads/main` and `refs/heads/master` present, or with origin/HEAD naming a branch other than `origin/$MAIN`, `--check` prints `refuse state default-branch: …` and exits 2 before any brief line.
  **Location:** `scripts/build-loop.sh:244-252`
  **Evidence:** read-static (Stage 1 executed the R7 test and its mutant)
  **Verified:** the two conditions and their `exit 2`; they sit after `main_by_name` and before `read_settings`.
  **Not verified:** a dangling origin/HEAD (`symbolic-ref -q` returns its target even when `refs/remotes/origin/<x>` is missing; read as a mismatch only when it differs from `$MAIN`).
  **route: code-fact-check**
- **Claim:** Any stderr output from a gate_git call makes merge_result return 2 or check_line refuse, whatever git's exit status.
  **Location:** `scripts/build-loop.sh:502-506`, `:514-519`, `:578`
  **Evidence:** read-static (Stage 1: each R6 guard alone passes the R6 test; neither is pinned separately)
  **Verified:** `gate_git` returns 3 on a non-empty err file; merge_result's `[[ "$rc" -le 1 ]]` checks and the `|| return 2` on each `cat-file -e`; check_line's `if ! gate_git diff-tree`.
  **Not verified:** own_blob's `gate_git hash-object`, whose status is dropped by its caller (F1).
  **route: code-fact-check**
- **Claim:** check_line prints its verdict line only after every diff-tree record has been parsed, judged and NUL-counted. A record that fails the meta regex or the count prints a refuse line and no path lines.
  **Location:** `scripts/build-loop.sh:582-593`
  **Evidence:** read-static
  **Verified:** the verdict `echo` at `:592` follows the loop and the count check; every early `return` in the loop is preceded by a `refuse` echo.
  **Not verified:** the NUL-count check is not pinned by any test (Stage 1 escalation: removing it passes the suite).
  **route: code-fact-check**
- **Claim:** A path name reaches stdout only when every byte is in NAMECHARS; otherwise it prints `?`. Deny reasons are code constants.
  **Location:** `scripts/build-loop.sh:586-588`
  **Evidence:** read-static, plus suite T13
  **Verified:** `shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` and the fixed DENY strings at `:544-551`.
  **Not verified:** the brief argument `$a`, echoed as given (S1, the trusted caller; check_brief has already run pathform on it).

## Primitive sweep

Primitive: process exec with data-derived arguments (git, perl, awk) in the diff scope

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:245` `git show-ref --verify` | S8 constants | none needed | cleared: constant refs |
| `scripts/build-loop.sh:248` `git symbolic-ref -q refs/remotes/origin/HEAD` | S4 | output compared only | cleared |
| `scripts/build-loop.sh:514` `merge-base --all "$MAIN_SHA" "$1"` | S3, S2 (tip id) | tip from `show-ref --verify` + `^{commit}` (check_branch), re-read at `:566` | cleared |
| `scripts/build-loop.sh:517` `cat-file -e "$b^{tree}"`, `$bases` unquoted | S5 (merge-base output) | git's own hex output, split on words | cleared: hex ids only |
| `scripts/build-loop.sh:518` `merge-tree --write-tree` | S3, S2 | output regex 40/64-hex | cleared |
| `scripts/build-loop.sh:531,533` `git cat-file blob "$MAIN_SHA:$1"` | S1 | check_brief: pathform + anybrief; `$6 == $1` only after pathform | cleared as an argument; F1 for the status |
| `scripts/build-loop.sh:533` `perl -pe '…'` with `N` from env | S8 program, N from awk (`print n + 0`) | numeric; no data in the program text | cleared |
| `scripts/build-loop.sh:533` `gate_git hash-object --no-filters --stdin` | S3 bytes | no `-w`, no filters | cleared |
| `scripts/build-loop.sh:578` `diff-tree … "$MAIN_SHA" "$tree"` | S3, merge output | `$tree` passed the hex regex | cleared |
| `scripts/build-loop.sh:504` `2>"$GATE_TMP/err"`, `:578` `> "$GATE_TMP/diff"` (file write and read-back) | S6 | none against the same uid | F3 / R8 (hostile-loop residual) |
| `scripts/build-loop.sh:608` `rm -rf -- "$GATE_TMP"` (trap) | mktemp output | trap set only after a successful assignment (`set -e`) | cleared |

## Summary Table

| # | Finding | Severity | Class | Boundary | Location | Confidence |
|---|---------|----------|-------|----------|----------|------------|
| F1 | own_blob's status is dropped: a failed second read compares as the empty blob | Low | hostile-loop | B1, B3 | `scripts/build-loop.sh:547`, `:527-533` | High (mechanism executed) |
| F2 | A merge referencing a missing blob prints ok; the N rules are unaffected, but U3/U2c inherit it | Low | honest-path robustness | B3 | `scripts/build-loop.sh:512-521`, `:578-593` | High (executed) |
| F3 | R8's surface grows by the err and diff read-back files | Informational | hostile-loop | B4 | `scripts/build-loop.sh:502-506`, `:578-591` | High (read-static) |
| R8 | Disposition: Q-103 residual, with row 494's wording corrected and the full surface named | n/a | hostile-loop | B4 | `scripts/build-loop.sh:479-497`, `:608` | High |

## Overall Assessment

The unit's posture is sound for its stated threat scope. R7's refusal, R6's stderr and tree guards, the in-gate-repo diff-tree (A16), the NUL-complete parse and the NAMECHARS output filter all fail closed on the code paths read. No finding is an honest-path bypass of an N rule. The one fail-open shape is F1, a one-line fix that is worth making in this unit even though only a racing writer reaches it, because it is the only place where the gate trusts a pipeline's output without its status. F2 needs no change today, but it should become an entry condition for U3's `--merge`, since a commit with a missing blob would corrupt main. R8 should be closed as a Q-103 residual: the plan places a hostile same-uid writer out of scope, no in-script fix stops the same uid, and the writer already has cheaper routes (rows 494 and F3, refs). The override row's "closes merge-tree" sentence must be qualified so the residual is legible. No findings within the code paths read rise above Low. The endorsement claims are pending execution verification, and the N-rules matcher carries three untested bypass candidates, so this is not a categorical all-clear.

## Goal-Alignment Note

The user goal is to land U2b1b after a clean review-fix loop. On security, nothing here blocks landing. F1 is a cheap in-unit fix (recommended). F2 is a forward note for U3/U2c. F3 and R8 are disposition and wording work on override row 509, row 494 and Q-103, not code. If the author takes F1 and records R8 as a residual with the corrected wording, this critic expects no security reds in the next iteration. The review stayed within its brief: findings are tagged honest-path or hostile-loop, R8 is judged against the plan's scope section, and endorsements are routed to code-fact-check rather than self-certified.
