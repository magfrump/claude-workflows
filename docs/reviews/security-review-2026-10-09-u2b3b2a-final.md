Commit: 82bb5281

# Security Review — feat/build-loop-u2b3b2a (U2b3b2a, final confirming pass)

**Scope:** whole branch, `git diff main...HEAD -- scripts test` (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats)
**Date:** 2026-10-09
**Based on:** u2b3b2a-i3/shared.md; u2b3b2a-i3/factcheck-summary.md (k=3; escalations on Claims 1 and 2); the iteration 1 and 2 security reports; override-log rows 558-572

Probe: `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i3/security/p2.sh`. It builds a hermetic fixture under its own mktemp dir with a private HOME and `GIT_CONFIG_GLOBAL=/dev/null`, and I removed the fixture afterwards. Both walks run as `imps` runs them in the suite.

## Trust Boundary Map

```
B1: [outside file text named by a // name]           → [outside_ok (-f && -r) at queue time; import_outside] → [parser input, walk lists]
B2: [an outside link's target inside a reader root]  → [outside_ok, then realpath -ez + IMPORT_WHOLE projection] → [repo name in the walk list]
B3: [quoted mention text spanning lines (@"…\n…")]   → [IMPORT_AWK put: index(out, "\n") drop]        → [nothing printed]
B4: [reader roots' checkouts other than ROOT_REAL]   → [read through an outside link, as the file system holds them] → [the main walk's answer for main's paths]
```

```
S1: outside file text and names            — runtime-mutable — UNTRUSTED for open/read; its absence is not evidence that a session cannot load the path
S2: other registered worktrees' checkouts  — runtime-mutable (any session, including another loop, checks out any branch there; /workspace's branch moves) — UNTRUSTED as a proxy for main's tree
S3: ROOT_REAL's checkout                   — clean at MAIN_SHA by the gate's contract — trusted as main's tree for the gate
S4: start/imported text on main            — deploy-time, through review — trusted for content, UNTRUSTED for name shapes (the superset must cover any)
```

The branch adds one new class of input: files below no reader root, reached from walked text (B1). It also adds one new projection: an outside link's real path is mapped back into a repo name (B2). Both escalated fail-opens come from the same admission rule, outside_ok. That rule treats "not a readable regular file here, now" as "no session loads it". The rule is right for files truly outside the repo. It is wrong in two cases: when the path resolves into another reader root's checkout (B4), and when the name cannot be printed at all (B3).

## Findings

#### F1. An outside link (or a linked directory on its path) into another reader root, where that checkout lacks a file main has, is skipped, so the floor answers "not imported" for main's path

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1158` (outside_ok), `:1386` (main walk `//` arm), `:1278` (tree walk `//` arm), `:723` (walk header: "one that is missing, unreadable or not a regular file here is skipped")
**Boundary:** B2, B4
**Move:** 5 (invert the access model: what the admission rule does not cover), 11
**Confidence:** High for the mechanism (executed). Medium for honest reachability: it needs an outside link in a chain from a repo start, and none exists live.
**Legibility-target:** the walk header's Known-exceptions list (:724-733) and outside_ok's header (:1155-1157)

Evidence (verbatim):

```
:1158 outside_ok() { [[ -f "$1" && -r "$1" ]]; }
:1386      [[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }
```

(I read main_imports whole, :1300 to the end of its loop. The `//` arm is the only path by which a // name reaches tq, and a rejected name ends at `continue`. import_outside, the projection, runs only on admitted names.)

Executed (p2.sh). Fixture: main has `docs/q.md` and `docs/sub/s.md`. A second registered worktree `wt2` is checked out at the base commit, which lacks both. AGENTS.md on main names `@$O/lq.md` (where `lq.md` links to `$W/docs/q.md`) and `@$O/ld/s.md` (where `ld` links to `$W/docs/sub`). Both walks print `walk: ok`, `docs/q.md: -` and `docs/sub/s.md: -`. The control case passes: a link into wt2 at a path wt2 has (`docs/x.md`) gives `imported`.

The defect: the projection at :1144 maps a link into a reader root to the repo path, but only once outside_ok has admitted the link. Admission tests the other checkout's state, not main's. Yet a repo-relative import of the same path counts as imported whatever any checkout holds. So for the same repo path, two spellings get two answers. Reachability: another worktree's checkout (S2) is whatever branch someone last checked out there. The main worktree /workspace is the registry's first record, and other sessions switch its branch. So a file new on main, imported through an outside link into /workspace while /workspace sits on an older branch, reads as "not imported". A loop may then self-merge an edit to it. Sessions load that edit once that checkout moves to main. The fact-check's directory-component sibling holds too (`ld/s.md`).

**Proportionate fix.** Do not fail the walk: dangling links on prefix candidates are honest input, and a test on the last component (`-L`) would not catch the directory case. Instead, project the names outside_ok rejects. For each file's output, pass its rejected // names through one batched `realpath -mz` (one fork per file, not per name), then through one `IMPORT_WHOLE=1 import_targets /`. Keep the repo names that come out, and drop the // ones. I executed the core of this on the fixture: `realpath -m` of `$O/lq.md`, `$O/ld/s.md` and `$O/nonexist/x.md`, piped through `IMPORT_WHOLE=1 import_targets /`, gives `docs/q.md`, `docs/sub/s.md` and the third name as `//…/out/nonexist/x.md`, with `rc=0`. This is a superset, and it adds false positives only for names that really resolve into a root. If the fix is deferred, deferral to U2b3b2b is reasonable, since its seeds meet the same rule. Even then, the walk header's exception list should name this case now ("an outside link into another reader root whose checkout lacks the target, or holds it unreadable"). Today the header's "skipped" sentence reads as complete.

#### F2. An outside file whose name holds a newline, named by a quoted mention spanning two lines, is dropped by the parser; both walks answer ok and miss its imports

**Severity:** Medium (floor rule: named mechanism, executed; its reachability rests on untraced Claude Code behaviour, which lowers Confidence, not Severity)
**Location:** `scripts/lib/dev-cycle-read.sh:880-882` (IMPORT_AWK put), `:803-806` (superset statement on @" spanning lines)
**Boundary:** B3
**Move:** 2, 11
**Confidence:** High for the mechanism (executed). Low for exploitability: it needs Claude Code's prompt-mention reader to import a multi-line name (untraced), and it needs referencing text that a loop which can plant it could already use to inject directly.
**Legibility-target:** the superset statement's Known-exceptions sentence (:818-826)

Evidence (verbatim):

```
:880   # A quoted text that spans lines can resolve to a name holding a newline,
:881   # which no file a walk admits has (and a printed one would split in two).
:882   if (index(out, "\n") || out == "") return
```

(The excerpt ends at :882. The enclosing put() continues to its closing brace after the `nho == 0` show, and I read it. The early return means neither channel prints.)

Executed (p2.sh): AGENTS.md on main holds `A: @"$O/a` and, on the next line, `b.md"`. `$O/a<newline>b.md` exists and imports `@docs/n.md`. Both walks print `walk: ok` and `docs/n.md: -`. The comment's premise, "no file a walk admits has" such a name, is false for outside files. outside_ok would admit `a\nb.md`, so the drop is what hides it. On the repo side, the main walk refuses newline names at ls-tree and checkout_md, so the gap is outside-only for the floor. The tree walk has a pre-existing checkout sibling: an untracked non-start file with a newline name, which main's lib already dropped. This is not a regression, because main dropped every outside name.

**Proportionate fix.** Do not fail on every newline spelling. Any honest file with a stray `@"` and a later `"` produces one, and docs/decisions/018 already holds `@"`. Two options:
- (a) Minimum: name the case in the superset statement's exceptions ("a name holding a newline, which only a quoted mention spanning lines can spell").
- (b) If the prompt-mention reader is ever confirmed to span lines, refuse only when such a name exists. put would print it escaped (`\\`→`\\\\`, newline→`\n`) on a distinct `///` channel. Both walks would decode it with `printf %b` and fail the walk when `-e || -L` holds. Honest text never meets an existing file of that name.

Do not use awk `system()`, since the name is attacker-shaped text. I recommend (a) now, with (b) behind the existing re-check trigger on the prompt-mention reader.

#### F3. (Context) Fact-check Claim 3's gaps in import_outside's returns-1 list are all fail-closed

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1129-1148` (import_outside's header and body)
**Boundary:** B1
**Move:** 3
**Confidence:** High (read-static, consistent with the fact-check's execution)
**Legibility-target:** import_outside's header

Evidence (verbatim): `:1142   nul_list rl realpath -ez -- "$1" && [[ ${#rl[@]} -eq 1 && "${rl[0]}" != *$'\n'* ]] || return 1`. I read import_outside whole.

I checked each gap. A summed trailer past IMPORT_WORK_MAX returns 1 through import_work, which fails closed. "A read fails" holds only under pipefail, and both walks set it. An edited file is read as it now is, and its imports are still walked: the i2 F2 snapshot residual, with no new direction. A FIFO stalls (row 559). None of these is a false "not imported". This is a documentation completeness issue only, and it belongs to code-fact-check's rows.

## Untested bypass candidates (guard: outside_ok plus the second channel)

- A bind-mount alias of a reader root (realpath does not resolve it). The fact-check escalated this to the orchestrator, and I did not test it. It is the F1 class by another route: a name under the alias is a // name, read from that mount. If that mount's content is the same checkout, it is read but never projected to a repo path. Proportionate handling is the same as F1's projection, plus a mount-table alias list, which is U2b3b2b's concern.
- An outside link into a reader root at a path that checkout holds unreadable, or as a directory, while main has a file. The F1 class through `-r` / `-f`. Not probed. F1's fix covers it, since the fix projects every rejected name.
- Deployed copies of repo files (this container's `~/.claude/{skills,guides,…}` → `/opt/claude-workflows`, a read-only non-git copy). A repo start importing `@~/.claude/guides/x.md` reads `/opt`'s copy as an outside file, and never names the repo's `guides/x.md`, which reaches sessions on the next image build. No live start imports `@~/` (grep). The memory-file seed is U2b3b2b's.
- Invalid-UTF-8 real paths under IMPORT_WHOLE (carried from i2): not probed.

Because of these, and F1 and F2, outside_ok does not appear among the endorsements below.

## Endorsement Claims

- **Claim:** A link into a reader root at a path that root's checkout holds is projected to the repo path in both walks, and so is a link into ROOT_REAL's checkout.
  **Location:** `scripts/lib/dev-cycle-read.sh:1144`
  **Evidence:** executed
  **Verified:** p2.sh controls: `$O/lx.md` → `$W/docs/x.md` and `$O/lc.md` → `$R/docs/c.md` both give `imported` in the tree and main walks.
  **Not verified:** a root reached through a host alias in IMPORT_READER_ROOTS (absent here).
  **route: code-fact-check**
- **Claim:** The second channel's `//` lead cannot be read as a repo name or a work trailer by import_work, which requires the trailer's form `^/[0-9]+$` as the last line.
  **Location:** `:1164-1168` (import_work), `:886-887` (put)
  **Evidence:** read-static, and the fact-check executed it (Claim 1 of shared.md's list: Verified)
  **Verified:** import_work's regex and its last-line test. An outside name ending in digits still starts `//`, so `${iw_o##*/}` reads the true trailer.
  **Not verified:** none beyond the fact-check's run.
  **route: code-fact-check**

## Primitive sweep

Primitive: file open/read of a path taken from walked text (branch scope)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1158` outside_ok (`-f`, `-r`) | S1/S2 | — | F1 (rejects a missing target in another root's checkout) |
| `dev-cycle-read.sh:1142` `realpath -ez` | S1 | outside_ok | cleared: fails closed on missing, multi-record or newline (i2, executed) |
| `dev-cycle-read.sh:1143` `capped_read < "$1"` | S1/S2 | outside_ok, 4 MiB | cleared; FIFO stall row 559 |
| `dev-cycle-read.sh:1144` IMPORT_WHOLE projection | S2 | newline refusal | cleared (executed control) |
| `dev-cycle-read.sh:1154` import_file repo branch | S3 | inrepo_here / main_checkout | cleared: unchanged |
| `dev-cycle-read.sh:882` put newline drop (not an open; it decides what is opened) | S4 | — | F2 |
| `dev-cycle-read.sh:1278`, `:1386` `//` arms | S1 | outside_ok | F1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Outside link or linked dir into another reader root whose checkout lacks main's file is skipped; floor answers "-" | Medium | B2, B4 | `dev-cycle-read.sh:1158, :1386, :1278, :723` | High (mechanism), Medium (reachability) |
| 2 | Newline-named outside file via a two-line quoted mention is dropped by put; walks answer ok | Medium | B3 | `dev-cycle-read.sh:880-882` | High (mechanism), Low (exploitability) |
| 3 | import_outside's returns-1 list gaps are all fail-closed (context) | Informational | B1 | `dev-cycle-read.sh:1129-1148` | High |

## Overall Assessment

The branch moves the floor in the right direction: main's lib dropped every outside name, and this branch reads them. Neither escalated fail-open is a regression. Both are real false "not imported" answers in a reachable shape, though, and I executed both. F1 is the one to act on. Its cause is architectural in a small way: admission asks about the file system, while the floor's question is about main's tree, and the two differ exactly when an outside link points into a checkout that is not at main. That makes F1 more than a documentation problem. A batched realpath -m projection of rejected names fixes it without failing honest input. If the fix is deferred to U2b3b2b, the walk header must name the exception now. F2 needs only a named exception, unless Claude Code's multi-line mention reading is confirmed. In short, the branch has two Medium fail-opens. No finding blocks the branch outright, and the endorsement claims are pending execution verification where they are routed.

## Goal-Alignment Note

The goal is to land U2b3b2a with no unnamed fail-open in the floor. The two Medium findings are fail-opens that this branch's own comments describe as covered: the walk header's "skipped" sentence and put's "no file a walk admits has" premise. The smallest change consistent with the goal is to name both in the exception lists before merge. The fix that matches the design principle (a superset, fail toward imported) is F1's rejected-name projection, and it fits naturally into U2b3b2b, whose seeds will meet outside_ok far more often.
