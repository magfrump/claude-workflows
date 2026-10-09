Commit: f7a96eed

# Security Review — feat/build-loop-u2b3b2a (U2b3b2a, iteration 2)

**Scope:** fix range `55490d15..HEAD` (`git diff 55490d15..HEAD -- scripts test`): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats
**Date:** 2026-10-09
**Based on:** u2b3b2a-i2/shared.md; u2b3b2a-i2/factcheck-summary.md (k=1, 30 claims); iteration 1's security report and override-log rows 558-567

Probes: `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i2/security/p1.sh`, a hermetic fixture under its own mktemp dir. I also ran the suite filter `outside|IMPORT_WHOLE|newline` on build-loop-check.bats: 10/10 ok.

## Trust Boundary Map

```
B1: [outside file named by a // name]            → [outside_ok (-f && -r), then import_outside's nul_list realpath -ez + newline refusal, capped_read] → [parser input]
B2: [real path of an outside file (symlink)]     → [IMPORT_WHOLE=1 import_targets / (put)]       → [repo name | //name in walk lists]
B3: [caller environment (IMPORT_WHOLE inherited)] → [lib sourcing: IMPORT_WHOLE=""] (new)         → [parser mode IT_WHOLE]
B4: [import_file's caller (DIRS, IMPORT_WORK_LEFT)] → [import_file → import_outside "${@:3}"] (moved) → [parser dirs, work trailer]
```

```
S1: outside file text (// names)       — runtime-mutable — UNTRUSTED for open/read sinks (any path an @ names)
S2: realpath of S1                     — runtime-mutable — UNTRUSTED toward put(); may hold a newline or any byte but NUL
S3: inherited environment (IMPORT_*)   — deploy-time for dev-cycle.sh/build-loop.sh (they source the lib once, at :98/:193) — untrusted toward parser mode, so it is cleared at source
S4: walk-internal DIRS (prompt_bases)  — code-derived   — trusted for dirs (newline refused upstream, :1107 comment)
```

What enters the fix range: the inherited environment no longer reaches the parser mode (B3). An outside file's real path is now checked as one NUL-terminated record that holds no newline before it is projected (B1/B2). import_file now forwards DIRS to import_outside (B4). No new open or exec sink was added. outside_ok renames the existing `-f && -r` test without changing it.

## Findings

#### F1. import_file's header omits that its absolute branch returns 1 unless the caller sets IMPORT_WORK_LEFT, and U2b3b2b's seeds will be its first non-walk callers

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1144-1148` (import_file), `:1132-1135` (import_outside's header)
**Boundary:** B4
**Move:** 3 (error path)
**Confidence:** High for the behaviour (executed); Low for any fail-open, which would need a future caller that reads rc 1 as "skip"
**Legibility-target:** import_file's header comment

Evidence (verbatim):

```
:1144 # import_file FILE DIR [DIRS...]: import_targets over FILE as the file system
:1145 # holds it, for both walks: a repo path (DIR and DIRS as import_targets takes
:1146 # them), or an absolute one through import_outside (its own directory in
:1147 # place of DIR, and DIRS).
:1148 import_file() { if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; else capped_read < "$1" | import_targets "${@:2}"; fi; }
```

(import_file is the single line :1148, read whole. import_outside is :1136-1143, read whole. With IMPORT_WORK_LEFT unset the parser prints no trailer (IMPORT_AWK END, `if (trail)`), so `import_work a w` fails.)

Executed (p1.sh): `import_outside "$O/real.md"` with IMPORT_WORK_LEFT unset gives `rc=1`, and `import_file "$O/real.md" x` gives `rc=1`. The repo-path branch, by contrast, succeeds without the variable. Today this is fail-closed: both walks set IMPORT_WORK_LEFT, and both treat 1 as a walk error. The risk is on the next unit. U2b3b2b's outside seeds (user memory, reader homes) will call import_file on absolute paths. A seed caller that copies the repo-path calling pattern, or that tolerates rc 1 as "file not loadable", would drop every outside seed silently. That is the fail-open class: a seed's chain back into the repo goes unseen. The fact-check rates commit 18fba03d's A4 bullet Incorrect on this point (Claim 24). Only import_outside's header states the requirement.

**Recommendation:** In import_file's header, state that the absolute branch needs IMPORT_WORK_LEFT and returns 1 without it, or have the branch default the variable as the repo branch effectively does. Either way, U2b3b2b's seed callers should treat 1 as a walk error.

#### F2. (Context, outside the fix range) The main walk's outside admission is a gate-time snapshot of files the floor does not protect

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1380` (main walk `//` arm), `:1152` (outside_ok)
**Boundary:** B1
**Move:** 4 (TOCTOU), 5
**Confidence:** Medium (read-static; not executed)
**Legibility-target:** the walk header's Known-exceptions list (:725-732)

Evidence (verbatim):

```
:1380      [[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }
```

(The excerpt is from main_imports, :1294 to the end of the walk loop. I read the unit's phase-1/phase-2 loop whole. A skipped name's flow ends at `continue`.)

Suppose main's instructions import an outside file that a loop can write, for example under a shared `$TMPDIR`. The loop can remove or rewrite that file while the floor runs, so the main walk sees no chain into `docs/p.md`. The loop then self-merges `docs/p.md` and restores the file. This is not new in the fix range: the rule is 55490d15's, and outside_ok is a rename of it. It also adds no capability: a loop that can write an outside instruction file can already inject instructions through that file directly, and the floor never guarded it. I note it because iteration 1's F1 and F2 named the cross-namespace case and the FIFO case, but did not name the case of an outside file the loop can write. Live instance: none (main yields no `//` names; iteration 1's live.sh).

**Recommendation:** None in code. Optionally, add "an outside file a loop can write" to the walk header's exceptions, next to the Q-103 registry residual.

## Untested bypass candidates (guard: outside_ok plus import_outside's record check)

- A real path with an invalid UTF-8 byte sequence: the parser adds a U+FFFD spelling (superset). Not probed under IMPORT_WHOLE.
- An outside file under a bind mount that differs between the gate's sandbox and a session: iteration 1's F1 mechanism, deferred to U2b3b2b (override row 558).
- A FIFO swapped in after outside_ok: named in the header, Won't-Fix (row 559).

Because of these, outside_ok as a skip guard does not appear among the endorsements below. The endorsements cover only the fix-range additions.

## Endorsement Claims

- **Claim:** An outside link whose real path ends in a newline makes import_outside return 1 (fail closed), rather than being projected with the newline stripped by command substitution.
  **Location:** `scripts/lib/dev-cycle-read.sh:1137-1138`
  **Evidence:** executed
  **Verified:** p1.sh: link `out/tn.md` → `repo/docs/tn\n`, giving `rc=1`. Embedded newline: bats test 6 (`walk failed` for both walks).
  **Not verified:** the main walk's half of test 6 pins this only through the separate newline-file refusal at :1323 (fact-check Claim 20a); a main-walk outside link to an outside newline path was not probed.
  **route: code-fact-check**
- **Claim:** A two-hop outside symlink chain (l2 → l1 → real.md) yields the content's imports (read through the link) and the final real path as a `//` name for the walk to re-read.
  **Location:** `scripts/lib/dev-cycle-read.sh:1139-1141`
  **Evidence:** executed
  **Verified:** p1.sh: output holds `docs/x.md`, `//…/out/real.md` and the trailer `/14390`, `rc=0`.
  **Not verified:** the intermediate link l1.md is not printed. Claude Code opens l2.md and the kernel resolves the chain, so that matches, but I did not check it against a session.
- **Claim:** IMPORT_WHOLE is assigned empty when the lib is sourced. Its only other assignment is the call-scoped `IMPORT_WHOLE=1 import_targets /` at :1141, and the two entry scripts source the lib once at start.
  **Location:** `scripts/lib/dev-cycle-read.sh:1032`, `:1141`; `scripts/dev-cycle.sh:98`; `scripts/build-loop.sh:193`
  **Evidence:** executed (bats test 5 with `IMPORT_WHOLE=1 imps`, and the fact-check) plus read-static (grep of every IMPORT_WHOLE reference)
  **Verified:** grep lists :781, :963, :968, :1030-1032, :1102, :1121 and :1141 as the only references; test 5 passes.
  **Not verified:** a future caller that sets IMPORT_WHOLE in its own scope between sourcing and a walk; none exists.
  **route: code-fact-check**
- **Claim:** outside_ok keeps 55490d15's admission semantics and order in both walks.
  **Location:** `:1272`, `:1380`, `:1152`
  **Evidence:** read-static (diff), consistent with the fact-check's executed verdict
  **Verified:** the old `-f && -r` pair moved into outside_ok verbatim; the main walk's seen test still precedes it and the tree walk's still follows it.
  **Not verified:** none beyond the fact-check's run.

## Primitive sweep

Primitive: file open/read of a path taken from walked text (fix range only)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1137` `realpath -ez` via nul_list | S1 | outside_ok at queue time | cleared: fails closed on missing, multi-record or newline |
| `dev-cycle-read.sh:1139` `capped_read < "$1"` | S1 | outside_ok, 4 MiB cap | cleared in this range; FIFO stall pre-existing (row 559) |
| `dev-cycle-read.sh:1141` whole projection | S2 | newline refusal at :1137 | cleared: executed |
| `dev-cycle-read.sh:1148` `capped_read < "$1"` (repo branch) | S4/checkout | inrepo_here / main_checkout | cleared: unchanged |
| `dev-cycle-read.sh:1272`, `:1380` outside_ok | S1 | — | F2 (context); iteration 1 F1 deferred |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | import_file's header omits that its absolute branch needs IMPORT_WORK_LEFT (rc 1 without it); U2b3b2b's seeds are the next callers | Low | B4 | `dev-cycle-read.sh:1144-1148` | High (behaviour), Low (fail-open) |
| 2 | Main walk's outside admission is a snapshot of files the loop may write (context, pre-existing, no new capability) | Informational | B1 | `dev-cycle-read.sh:1380` | Medium |

## Overall Assessment

The iteration-1 fixes move in the fail-closed direction and add no new sink. I executed the A1 and A2 checks: an inherited IMPORT_WHOLE is neutralised, and a real path holding a newline, embedded or trailing, fails the walk. A4's forwarding of DIRS only widens what is read, which is a superset. The iteration-1 F1 residual is now named in the walk header, as the override log recorded. No finding here is a false "not imported" today. The most important item is F1, and it matters for the next unit rather than this one: import_file's contract should say that an absolute path fails without IMPORT_WORK_LEFT, before U2b3b2b's seed callers are written against it. Within the code paths read I found no other findings. The endorsement claims are executed or scoped, each with its unverified hop named.

## Goal-Alignment Note

The goal is to land U2b3b2a with no fail-open in the floor. Within the fix range, nothing weakens the floor. The only forward-looking risk is on the hand-off to U2b3b2b. Its outside seeds will call import_file on absolute paths, and the rc-1-without-IMPORT_WORK_LEFT behaviour is documented only on import_outside. A one-line header fix, which can be deferred to U2b3b2b, keeps the next unit from treating an outside seed's failure as a skip.
