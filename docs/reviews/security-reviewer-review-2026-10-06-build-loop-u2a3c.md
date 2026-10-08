Commit: cebfed35

# Security Review — feat/build-loop-u2a3c (U2a3c checkout phase), loop pass 1

**Scope:** `git diff 5e51b58b..HEAD` (cebfed35): `scripts/lib/dev-cycle-read.sh` (`checkout_md`, `main_checkout`, `main_imports`), `test/scripts/build-loop-check.bats`, docs rows A5/F11
**Date:** 2026-10-06
**Based on:** shared review context (u2a3c-orch/shared.md) and the Stage 1 summary of `docs/reviews/code-fact-check-report-build-loop-u2a3c.md` (33 claims, no behavioural Incorrect)

All probes were run in fixture repos under `/tmp/u2a3c-sec-GDBT` (uid 1000, bash 5.2.15, `LC_ALL=C`, hermetic git env as `test/lib/build-loop-fixtures.bash`), with this branch's lib sourced as in the bats `imps` helper (`resolve_main; ROOT_REAL="$(pwd -P)"; main_imports; isimported main PATH`).

## Trust Boundary Map

```
B1 (new): [checkout listing: git ls-files --cached --others, S2/S4] → [checkout_md: exit 0 + empty stderr; nul_list]   → [start candidates (t:)]
B2 (new): [checkout path a start or import names, S1/S3]            → [main_checkout: parent link/gitlink, -x, inrepo_here, -r] → [tq: admitted for reading]
B3 (new): [checkout file bytes, S3]                                  → [`import_targets "$d" < "$f"` (checkout arm)]     → [IMPORTED_MAIN (gate floor input)]
B4:       [main's commit tree/blobs, S5]                             → [ls-tree record regex, cat-file arms]             → [IMPORTED_MAIN]
B5:       [IMPORTED_MAIN + IMPORTED_MAIN_DONE cache, S6]              → [isimported main]                                 → [self-merge floor (U2a4, not yet written)]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | import tokens in main's or the checkout's instruction text | request-time (authored by the loop or a contributor) | UNTRUSTED toward path construction and file reads |
| S2 | checkout working tree and index (untracked, ignored, index-only files, their types and modes) | runtime-mutable (the loop writes it; other sessions share the checkout) | UNTRUSTED toward reads and toward "nothing here loads" verdicts |
| S3 | checkout file contents | runtime-mutable | UNTRUSTED toward the parser; its imports may only append |
| S4 | caller environment and repo config (GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, core.ignoreCase, core.fsmonitor, GIT_TRACE) | deploy/runtime-mutable | UNTRUSTED; hardening owned by the caller (settled override row, U2b) |
| S5 | main's commit (MAIN_SHA by name) | committed history | trusted as the authority on what main stores; its texts are S1 |
| S6 | in-shell cache `IMPORTED_MAIN_DONE` | process-local | trusted only for the snapshot it was computed on |

What enters: checkout paths and bytes (S2, S3) now cross into the walk for the first time (B1-B3). The diff's assumption is that `checkout_md` lists every checkout start Claude Code would load, and that a path `main_checkout` admits is still the same plain file when phase 2 reads it. Both assumptions are probed below.

## Findings

#### 1. Cache now holds checkout content: a walked checkout file's later edit is answered from the stale walk (extends the settled cache-key row)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:569-570` (cache key), `:600` (checkout read)
**Boundary:** B5, B3
**Move:** 4 (TOCTOU, cached check)
**Confidence:** Medium (reach depends on how U2a4/U2b call the walk; no caller exists yet)
**Legibility-target:** the override row for the cache key and the lib comment at `:474-476`

Evidence (verbatim): `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` (excerpt ends :569; enclosing main_imports() continues to :632 — read).

Before this commit an untracked start made the walk fail, and that failure was cached; the cache could only go stale when a start was added after a successful walk (the settled row; test at bats :298 pins it). Now the walk reads checkout bytes and caches ok, so editing an already-walked checkout file (e.g. an untracked `CLAUDE.local.md` gaining an import) is answered from the old content. Executed (P16): walk ok with `CLAUDE.local.md` = `see @s.md`; same shell, rewrite to `see @s.md @t.md`; `isimported main t.md` → `t.md: -`; after `IMPORTED_MAIN_DONE=""` → `t.md: imported`. This is the same mechanism as the settled row (key ignores the checkout), but its reach is new: every checkout byte the walk reads, not only the start set. Not a new class; filed so the rubric can decide whether the Defer row's wording still covers it.

**Recommendation:** Widen the row's text and the `:474-476` comment from "a start file added" to "any checkout change, including the content of a checkout file the walk read"; or make U2a4's floor clear `IMPORTED_MAIN_DONE` before every gate decision (one line, no cost worth caching).

#### 2. A FIFO (or other non-regular, non-link) start is invisible to `checkout_md`, so `main_checkout`'s "anything else fails" never runs for it

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:524` (`checkout_md`), `:587-592` (start loop); doc claim at `:466-469`
**Boundary:** B1
**Move:** 11 (bypass enumeration), 5 (invert the model)
**Confidence:** Low (the Claude Code side, reading a FIFO as an instruction file, is untraced; pre-existing in U2a3's listing)
**Legibility-target:** lib comment `:466-469` and known-issues A5

Evidence (verbatim): `checkout_md() { local e; { e="$(GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` and the comment "or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included) ... fail the walk".

`git ls-files --others` lists regular files and symlinks only. Executed (P6): untracked symlink `CLAUDE.local.md -> real.md` is listed and fails the walk (good); replacing it with `mkfifo CLAUDE.local.md` gives `ls-files --others` = `real.md` only, `walk: ok`, `s.md: -`. If Claude Code opens that FIFO at session start and a writer process feeds it `@s.md`, the import is loaded but answered `-`. The same FIFO at an import path is refused (main_checkout rc 1), so only starts are affected. The doc comment reads as if the admission check covers every checkout start shape; it covers only those git lists.

**Recommendation:** Either add the shape to A5's not-covered list and correct the `:466-469` sentence to "a checkout path it lists or an import reaches", or probe the fixed start names Claude Code reads at the root (`CLAUDE.md`, `CLAUDE.local.md`) and every entry of each `.claude/rules` directory with `main_checkout` directly, which would refuse a FIFO there.

#### 3. Read-time TOCTOU: the checkout read follows whatever is at `$f` when phase 2 reaches it, after the whole main phase

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:532` (admission) vs `:600` (read)
**Boundary:** B2 → B3
**Move:** 4
**Confidence:** High (mechanism executed with a simulated race); exploit value Low (a concurrent writer can already edit the file itself)
**Legibility-target:** lib comment above `main_imports` (snapshot assumption)

Evidence (verbatim): `if inrepo_here "$1"; then [[ -r "$1" ]]; return; fi` (excerpt ends :532; enclosing main_checkout() continues to :535 — read) and `checkout) out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; } ;;`.

Executed (P17, swap injected by wrapping `main_checkout` so the race is deterministic): after admission, `CLAUDE.local.md` is replaced by a symlink to an empty file outside the repo; the read follows it, `walk: ok`, `s.md: -`. P17b: replaced by a directory; this branch's parser swallows grep's `Is a directory` (`done < <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)`, :510), `walk: ok`. U2a3b's parser already returns 1 there (executed: U2a3b `import_targets "" < dir` rc=1; this branch rc=0) — **route to U2a3b** (already fixed once stacked). A FIFO swap would hang the walk (bounded only by the caller's timeout). A writer racing the gate can equally rewrite the file's text before the walk and restore it after, so this adds no capability; it matters only as a documented snapshot assumption, especially since other sessions share the checkout.

**Recommendation:** State in the comment that the walk is a snapshot of a quiescent checkout; optionally re-run `rawfile "$f"` immediately before the `<` (narrows, does not close, the window).

#### 4. The C1 start-only control has no regression test (fact-check Claim 22a)

**Severity:** Low
**Location:** `test/scripts/build-loop-check.bats:316-` (checkout-phase test); control at `scripts/lib/dev-cycle-read.sh:531, :589-590`
**Boundary:** B2
**Move:** 5
**Confidence:** High
**Legibility-target:** commit message "a new test pins C1" and the bats test 18 fixtures

Evidence: fact-check Claim 22a — a mutant dropping the parent link/gitlink check for starts survives all 18 tests because test 18's starts import a path under the link, whose own admission refuses. The control itself works: executed P1 (main `.claude/rules -> ../docs`, checkout plain `.claude/rules/foo.md`) → `walk: failed`, `.claude/rules/secret.md: imported`. A security control without a pinning test is how C1 regressed in U2a3.

**Recommendation:** Add the fact-check's import-free start fixture (checkout `.claude/rules/foo.md` reading `harmless` under a main link) asserting `walk failed`.

## Probes executed (no fail-open found unless noted)

| # | Probe | Result |
|---|---|---|
| P1 | start-only under a main link (`.claude/rules -> ../docs` on main, plain dir in checkout) | walk failed (fail closed) |
| P2 | import `@ld/x.md`, `ld -> deep` only in the checkout, deep/x.md importing `@secret.md` | walk failed |
| P2b/c | same, target absent behind the link / dangling link | walk ok, `ld/x.md: imported`; nothing to read (rc 2) |
| P2d | index-only `ld/CLAUDE.md` (via `update-index --cacheinfo`) under a checkout symlink dir | walk failed |
| P3 | index-only start deleted from the checkout (rc 2), then imported by an untracked `CLAUDE.local.md` | walk ok; `docs/claude.md: imported`; absent file read nowhere — consistent with Claude Code (nothing loads) |
| P3b | directory named `CLAUDE.md` (rc 2) holding `x.md` | walk ok; not a start for Claude Code either |
| P5 | untracked starts under `-x/`, `a b/`, `[x]/`, `*/`, `q?/`, `b\/` | all walked, imports recorded |
| P5b/c | imports `@-y.md`, `@*.md`, `@w/` (trailing slash; dir and file), `@@` | walked/recorded; `@[z].md` stops at `[` (parser rule, U2a3b) |
| assoc keys | `seen`/`ent` with keys `@`, `*` | looked up as literal keys (no all-elements expansion) |
| P6 | untracked start symlink / FIFO | symlink: walk failed; FIFO: **walk ok, import missed** (Finding 2) |
| P7 | main-stored `CLAUDE.md` deleted / replaced by a dir in checkout | main's blob read; import kept |
| P8 | `sub/.claude/rules/deep/x.md` untracked | walked |
| P9/P9b | case variants `Docs/x.md` vs main `docs/x.md`; `Docs/CLAUDE.md` vs main `docs/CLAUDE.md` | both walked, imports recorded (case-sensitive FS) |
| P10 | `core.excludesFile` and `info/exclude` ignoring `CLAUDE.local.md` | still listed (no `--exclude*`), walked |
| P11 | `core.ignoreCase=true` on a case-sensitive FS, untracked `.claude/rules/A.md` beside main's `a.md` | **walk ok, `s.md: -`** — settled (U2a3 L2f-r2 classed it under A5 case-insensitive + override row 387); unchanged by this commit. `git -c core.ignoreCase=false ls-files ...` lists both (cheap fix, advisory) |
| P12 | sparse cone checkout (with and without `index.sparse`), untracked starts in an out-of-cone dir | listed and walked |
| P13 | skip-worktree index entry present in the worktree | walked |
| P14 | `GIT_WORK_TREE` (and `GIT_DIR`+`GIT_WORK_TREE`) pointing elsewhere | **walk ok, untracked start unseen** — caller env (S4), settled row; not re-filed |
| P15 | `GIT_TRACE=1` | walk failed (stderr non-empty → fail closed) |
| P16 | cache after a walked checkout file's edit | stale `-` (Finding 1) |
| P17 | admission→read swap (symlink, directory) | walk ok, imports missed (Finding 3; directory case route to U2a3b) |
| P18/P19 | `000` grandparent, `r--` parent, `000` start file | walk failed |

## Untested bypass candidates

- `core.fsmonitor` hook and `GIT_INDEX_FILE` hiding an untracked start — settled override row (caller-owned git hardening, U2b); not re-run.
- Replace refs / grafts altering MAIN_SHA's tree — settled row; not re-run.
- Claude Code's own behaviour on a FIFO, socket or device at a start name — untraced (needs the Claude Code loader source); bounds Finding 2's confidence.
- A case-insensitive filesystem (A5) — environment not available here.
- `core.untrackedCache` with a stale directory mtime hiding a new untracked start — not built (needs mtime manipulation; git's own invalidation is believed sound).

## Endorsement Claims

- **Claim:** A checkout start under a directory main stores as a symlink fails the walk, even when the start imports nothing under the link.
  **Location:** `scripts/lib/dev-cycle-read.sh:531, :589-590`
  **Evidence:** executed
  **Verified:** P1 and P2d fixtures → `walk: failed`.
  **Not verified:** the gitlink (160000) parent variant for an import-free start; no test pins either (Finding 4).
  **route: code-fact-check**
- **Claim:** A checkout path under an unsearchable (`000` or `r--`) directory, or an unreadable start file, fails the walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:524, :531-532`
  **Evidence:** executed
  **Verified:** P18, P19 as uid 1000.
  **Not verified:** behaviour under root (where mode bits do not deny), the likely uid of a container-run loop.
  **route: code-fact-check**
- **Claim:** Phase 2 reads a checkout file only after `main_checkout` returned 0 for it.
  **Location:** `scripts/lib/dev-cycle-read.sh:589-591, :596-600, :628-629`
  **Evidence:** read-static
  **Verified:** `tq+=` appears only behind `c -eq 0` (starts) and `c -ne 0 || tq+=` (imports); `queue+=` only for paths with `ent` set, so the `checkout` arm is reached only from `tq`.
  **Not verified:** the state of the path at the moment of the read (Finding 3).
- **Claim:** Marking an import seen before `main_checkout` (fact-check Claims 4/17b) yields no fail-open: rc 1 fails the walk, rc 2 means nothing loads there, rc 0 queues it.
  **Location:** `scripts/lib/dev-cycle-read.sh:626-629`
  **Evidence:** read-static, plus P3/P2b executed
  **Verified:** the three return codes' handling in the import loop; P3 (rc 2 start later imported) stays consistent.
  **Not verified:** a path that becomes present between its first rc-2 visit and the end of the walk (snapshot assumption).

## Primitive sweep

Primitive: file read of a checkout path (`< "$f"`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:600` `import_targets "$d" < "$f"` | S2/S3 via `tq` | `main_checkout` rc 0 (inrepo_here + -r), earlier in time | Finding 3 (TOCTOU, Informational) |
| `scripts/lib/dev-cycle-read.sh:551` (`imported_names`, tree walk) | S2/S3 | `inrepo_here` at queue time | out of scope (unchanged by this diff; tree walk) |

Primitive: git listing of checkout paths

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:524` `checkout_md` | S2, S4 | exit 0 + empty stderr, `nul_list` | Finding 2 (FIFO unlisted); S4 bypasses settled |
| `:519` `untracked_md` (tree walk) | S2, S4 | none on stderr | out of scope (unchanged; tree walk) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Cache answers a walked checkout file's later edit from the stale walk (extends settled cache row) | Medium | B5, B3 | `dev-cycle-read.sh:569-570, :600` | Medium |
| 2 | FIFO start unlisted by `checkout_md`; walk ok, import missed | Medium | B1 | `dev-cycle-read.sh:524, :587-592, :466-469` | Low |
| 3 | Admission-to-read TOCTOU; directory swap swallowed by parser (route to U2a3b, fixed there) | Informational | B2→B3 | `dev-cycle-read.sh:532, :600, :510` | High |
| 4 | C1 start-only control unpinned by tests | Low | B2 | `build-loop-check.bats:316-` | High |

## Overall Assessment

The checkout phase holds the line it set out to hold: across the requested probes (symlinked parents, main links and gitlinks, unsearchable directories, odd names, case variants, deleted and index-only entries, nested rules, sparse and skip-worktree, exclude config, GIT_TRACE) every admitted read was a plain in-repo file and every refused shape failed closed. The only executed fail-opens come from inputs the admission check never sees — a FIFO start git does not list (Finding 2), caller-owned git env/config (P11, P14; settled), a stale cache (Finding 1, settled mechanism with wider reach) and a concurrent swap (Finding 3). None is architectural; the most important thing to address is Finding 1's wording/caller contract, because U2a4's floor will be the first caller and a reused shell would silently answer from stale checkout content. No findings within the code paths read beyond these; endorsement claims pending execution verification.

## Goal-Alignment Note

The user goal is to land U2a3c through the review-fix loop with the walk failing closed on checkout input. Findings 1 and 2 bear on that goal directly (both are walk-ok-with-a-missed-import shapes) but neither requires changing `main_checkout`; both can be closed by wording plus a caller contract or an A5 row, which keeps the unit inside its 140-line scope. Finding 3's live half is already fixed by U2a3b's stacking. Finding 4 is the fact-check's test gap seen from the security side. Nothing here argues for re-splitting the unit.
