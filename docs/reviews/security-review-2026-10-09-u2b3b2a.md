Commit: 55490d15

# Security Review — feat/build-loop-u2b3b2a (U2b3b2a, iteration 1)

**Scope:** `git diff main...HEAD` (55490d15): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats
**Date:** 2026-10-09
**Based on:** shared brief u2b3b2a-i1/shared.md (fact-check runs in parallel; not provided)

> **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

Probes: `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i1/security/probe.bats` (P1-P4, fixture repos under bats' TMPDIR) and `live.sh` (main walk over this repo's main, read-only). All four probes passed and printed the results quoted below.

## Trust Boundary Map

```
B1 (new): [outside file named by a // second-channel name]  → [-f && -r test, realpath -e, capped_read] → [parser input, walk name list]
B2 (new): [realpath of an outside file (symlink target)]    → [IMPORT_WHOLE projection, put()]          → [repo-relative name or //name]
B3:       [repo/checkout/main file text (@ names)]          → [IMPORT_AWK put(): roots, dotnest]         → [repo name | //PATH | trailer /N]
B4:       [parser stdout]                                   → [import_work trailer strip, line loop]     → [queue/tq, IMPORTED(_MAIN)]
B5:       [reader settings: IMPORT_READER_ROOTS/HOMES]      → [import_readers]                            → [IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST]
```

Input sources:

```
S1: main's blobs                          — runtime-mutable (merges)  — trusted for reading content; a loop cannot write main pre-merge
S2: checkout files (tree walk: a loop's   — request-time              — UNTRUSTED for every sink (a hostile loop writes its worktree);
    worktree; main walk: the checkout)                                   the walks treat extra names as acceptable (superset)
S3: outside files (// names), new         — runtime-mutable           — UNTRUSTED toward open/read sinks (any path an @ names: /proc,
                                                                         credentials, FIFOs); their *absence* is not evidence a reader
                                                                         cannot load them (see F1)
S4: realpath output of S3                 — runtime-mutable           — untrusted toward put() (handled as a whole name)
S5: docs/dev-cycle.md reader lines (main) — deploy-time (main only)   — trusted for root/home sets
```

What enters: arbitrary absolute paths that any walked file names now cross B1 into a file-system read, and their contents feed the same parser. The diff assumes that a `//` name the gate's own namespace cannot see (missing, unreadable, non-regular) is one no reader can load. That holds for sessions in this container. It fails for the reader homes the settings declare (F1).

## Findings

#### F1. A `//` name below a declared reader home that this namespace cannot see is skipped as "missing", so chains a host session loads stay invisible (fail-open)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1245`, `:1353` (the skip); `:720-725` (the justification)
**Boundary:** B1, B5
**Move:** 3 (error path), 5 (invert the access model), 11
**Confidence:** High for the mechanism (executed); Low for a live instance today (main has no `//` names: `live.sh`)
**Legibility-target:** the walk-header comment at :720-725 and the skip lines at :1245/:1353

Evidence (verbatim):

```
:1245      [[ "$p" != //* ]] || { p="${p#/}"; [[ -f "$p" && -r "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }
:1353      [[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" && -f "$p" && -r "$p" ]] && seen[$p]=1 && tq+=("$p"); continue; }
:722  # system, as the checkout phase does, through outside_targets; one that is
:723  # missing, unreadable or not a regular file is skipped, since a session cannot
:724  # load it either (a session under another uid is the reader model's host
:725  # exception). Neither walk starts at an instruction file outside the repo, though Claude
```

(Excerpt :1245 sits in imported_names, :1215-1250; :1353 in main_imports, :1266-1361. I read both units whole, and each skipped name's flow ends at `continue`.)

`docs/dev-cycle.md:26` declares `Reader homes: /home/magfrump /home/node`, and the plan defines Reader homes as "homes of sessions the container cannot see" (plan-build-loop-handoff.md:301). The parser expands `@~/x.md` against every reader home (`emit`, :846-849), so it prints `//home/magfrump/x.md`. That path does not exist in this container (`ls /home/magfrump`: no such file), so both walks skip it. A host session does load `/home/magfrump/x.md`. If that file imports `@/home/magfrump/claude-workflows/docs/p.md`, an `@~/claude-workflows/...` name, or any name that resolves into a reader root, a host session loads `docs/p.md` while both walks answer "not imported". The floor then lets a loop self-merge a change to a file that host sessions load as instructions. That is exactly the defect class the floor exists to prevent. The comment's reason, "a session cannot load it either", is false for this reader class, and the host exception it cites is about another *uid*, not another *mount namespace*.

Executed (P1): a fixture whose AGENTS.md holds `See @~/notes.md`, with `T_READER_HOMES` set to a directory that does not exist. Output: `walk: ok`, `docs/x.md: -` for both walks. Control: create that home with `notes.md` holding `n: @<repo>/docs/x.md`, and both walks give `docs/x.md: imported`. So the only difference between the two runs is whether the reader home is visible from the gate.

This is not a regression. Before the change, main dropped every name below no root, and this unit makes all visible chains walkable. It does present the remaining gap as closed when it is not. U2b3b2b's planned seeds ("each reader home's `.claude`") will skip in the same way.

**Recommendation:** Fail closed on a `//` name that lies at or below an `IMPORT_READER_HOMES` (or `IMPORT_READER_ROOTS`) entry whose own directory does not exist in this namespace. One way: in import_readers, record the caller homes that fail `-d` and refuse the walk when a `//` name falls below one. This costs nothing on honest input today, because main currently yields zero `//` names (live.sh). If over-refusal is judged worse, name it as an explicit known exception in the :720-725 header and in the plan, rather than "a session cannot load it either". Add a test that pins the chosen behaviour (P1's fixture).

#### F2. Check-then-open window on outside files: swapping the file for a FIFO stalls the walk with no timeout

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1245`/`:1353` (check) → `:1117-1118` (use)
**Boundary:** B1
**Move:** 4 (TOCTOU), 8
**Confidence:** Medium (read-static; not executed: it needs a race)
**Legibility-target:** outside_targets' comment

Evidence:

```
:1117  r="$(realpath -e -- "$1")" || return 1
:1118  a="$(capped_read < "$1" | import_targets "${d:-/}")" && import_work a w || return 1
```

(outside_targets is :1115-1121, read whole.)

The `-f`/`-r` test runs when a name is queued. The open runs when the name is dequeued, which can be many files later. If the file is replaced by a FIFO in between, `< "$1"` blocks in open(2) indefinitely, and neither the work bound nor capped_read applies before open. A file that turns unreadable or disappears instead makes realpath or the redirection fail, which fails the walk closed, so that half of the brief's claim 5 holds by reading. Exploiting the window needs write access to the outside directory. Within this threat model, the only actor with that access is a hostile loop's own worktree, which is in the tree walk only, and could also be a writable `$TMPDIR` that its file names. The result is a stalled `--check-fix`, not a "not imported" answer. The same check-then-read gap already exists for repo files (`inrepo_here` at queue time, `capped_read < "$f"` at dequeue), so this change adds no new class. I rated it Informational rather than Medium because the outcome is availability only and the floor's answer is never wrong.

**Recommendation:** Optional hardening: open outside files with a non-blocking guard (for example, run `timeout` around the read, or re-test `-f` immediately before the redirection), or note the residual next to the existing one.

#### F3. The walks now open and parse any readable regular file an `@` names (/proc/self/environ, credentials), as the gate's uid

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1115-1125`, `:1245`, `:1353`
**Boundary:** B1, B4
**Move:** 6 (follow the secrets), 7
**Confidence:** Medium

Executed (P2): an AGENTS.md naming `@/proc/self/environ`, `@/dev/stdin`, `@/proc/self/fd/0` and `@/etc/passwd`. Both walks gave `walk: ok` in under 1 s with empty stderr. `/dev/stdin` and the fd are skipped by `-f`, since they are the process-substitution pipe and not regular files. Contents never leave the process. The only observable output is whether a hostile-chosen repo path is "imported". For a secret's bytes to change that answer, the secret would have to contain an `@` name that resolves into a reader root, or have a real path inside one. Names in `/proc` or `~/.claude` resolve against their own outside directory. So the review found no practical oracle. It is a confused-deputy surface only if the gate ever runs with more file access than the loop it judges.

**Recommendation:** None required. Keep `IMPORTED`/`IMPORTED_MAIN` out of any printed refusal text. The only printer found is isimported's membership answer, which callers word themselves.

## Untested bypass candidates (guard: the `-f && -r` skip of `//` names)

- A file under a directory the gate cannot search but a session can. I did not probe it: the gate and sessions share a uid here, and only a different-uid host session differs. F1 covers the cross-namespace version.
- A bind-mount or bwrap view that differs between the gate's sandbox and a container session, so the same path is absent for the gate and present for the session. I did not probe this. It is F1's mechanism with a non-home path.
- A `/proc` or FUSE regular file whose read blocks after open. Not probed. capped_read bounds bytes, not time.

Because of these, the skip guard does not appear among the endorsements.

## Endorsement Claims

- **Claim:** import_work rejects an output whose last line is a second-channel name `//123` (trailer missing), a repo name ending in digits (`a/123`), and an empty output. It strips exactly one trailer from `//123\n/5` and from `x\n//9\n/7`.
  **Location:** `scripts/lib/dev-cycle-read.sh:1130-1135`
  **Evidence:** executed
  **Verified:** P4 output: `fail [//123]`, `ok [//123] w=5`, `fail [a/123]`, `fail []`, `ok [x\n//9] w=7`.
  **Not verified:** outside_targets' combined output when `a` holds only the trailer and `b` holds names (the `${a:+"$a"}` arm), as consumed at :1237/:1314.
  **route: code-fact-check**
- **Claim:** In main_imports, an absolute queue item reaches the `checkout` arm, because `ent` is keyed by `git ls-tree` paths and these never start with `/`. The phase-2 admission (main_checkout) is applied only to names that do not start with `//`.
  **Location:** `scripts/lib/dev-cycle-read.sh:1276-1280`, `:1313`, `:1353-1355`
  **Evidence:** read-static
  **Verified:** the ent fill loop, the case selector and the `//` branch's `continue` before main_checkout.
  **Not verified:** a tree record whose path git prints with a leading `/` under some config (the parse at :1277 would take it); not probed.
  **route: code-fact-check**
- **Claim:** An outside symlink to a repo directory is skipped in both walks, the same as a plain repo directory named by an import, which main_checkout scores 2.
  **Location:** `scripts/lib/dev-cycle-read.sh:1245`, `:1353`
  **Evidence:** executed
  **Verified:** P3: `@<out>/dl` → repo `docs/d`, both walks `walk: ok`, `docs/d/q.md: -`.
  **Not verified:** whether Claude Code reads a directory import's files. The main arm's 120000 case refuses a link to a directory on the grounds that this is untraced (:1339-1342), so this skip is less strict than that refusal.
- **Claim:** A reader root of `/` (or all slashes) is refused in import_readers before the parser runs, so dropping the awk's `roots[i] == "/"` arm reaches no root equal to `/`.
  **Location:** `scripts/lib/dev-cycle-read.sh:1054`, `:1061`, `:949-950`
  **Evidence:** read-static
  **Verified:** both `-n "${p//\//}"` tests (as written and as realpath reads it), and that the awk takes IT_ROOTS only from IMPORT_ROOTS (:1106).
  **Not verified:** callers that set IMPORT_ROOTS directly rather than through import_readers; none found by reading import_targets.
  **route: code-fact-check**

## Primitive sweep

Primitive: file open/read of a path taken from walked text (path traversal by design)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:1117` realpath -e | S3 | `-f && -r` at queue time | cleared: fails closed |
| `scripts/lib/dev-cycle-read.sh:1118` `capped_read < "$1"` | S3 | `-f && -r` at queue time, 4 MiB cap | F2 (TOCTOU stall), F3 (reads any file) |
| `scripts/lib/dev-cycle-read.sh:1119` whole projection of realpath | S4 | none needed (name only, no open) | cleared: put() normalizes; a name holding a newline is dropped as elsewhere |
| `scripts/lib/dev-cycle-read.sh:1125` `capped_read < "$1"` (repo path) | S2 | inrepo_here / main_checkout | cleared: pre-existing, unchanged semantics |
| `scripts/lib/dev-cycle-read.sh:1245` `-f/-r` skip | S3 | — | F1 |
| `scripts/lib/dev-cycle-read.sh:1353` `-f/-r` skip | S3 | — | F1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Reader-home outside chains skipped as missing (fail-open; comment's justification false) | Medium | B1, B5 | `dev-cycle-read.sh:1245, :1353, :720-725` | High (mechanism), Low (live instance) |
| 2 | Check-then-open window: FIFO swap stalls the walk | Informational | B1 | `dev-cycle-read.sh:1117-1118` | Medium |
| 3 | Walks read any readable regular file an @ names | Informational | B1, B4 | `dev-cycle-read.sh:1115-1125` | Medium |

## Overall Assessment

The change moves the walks in the fail-closed direction. Chains through visible outside files are now followed, and the trailer and second-channel encoding held against the crafted outputs I executed. The one design-level gap is F1: the skip rule treats "absent in the gate's namespace" as "no reader can load it". That is false for the Reader homes, which the settings exist to model, so a host session's chain through its own home stays invisible. Today no instance is live, because main yields no `//` names. Fixing it in place (refuse a `//` name below an absent reader home) costs honest input nothing now, and U2b3b2b's home seeds will need the same rule. The most important thing to address is F1's skip rule or its comment. Status: no other findings in the code paths read, and the endorsement claims are pending execution verification.

## Goal-Alignment Note

The unit's goal is to close the outside-chain gap without opening a fail-open. It closes the gap for chains visible to the container and opens no new false negative relative to main. It does, however, document the host-reader residual as non-existent ("a session cannot load it either"). The reader settings landed in U2b3b1 specifically to model host sessions, so the floor's guarantee depends on whether this skip covers them. F1 should be resolved, either by fail-closed code or by a named exception, before U2b3b2b builds home seeds on the same rule.
