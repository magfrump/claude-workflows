Commit: 34edec56

# Security Review — feat/build-loop-u2a3 (main_imports, iteration 2)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 34edec56): `scripts/lib/dev-cycle-read.sh` main_imports (:545-615), isimported (:621-630), header comments (:452-472, :532-544); tests; plan F11/U2a3/U2b; known issue A5
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3-i2.md` (iteration 2) and `docs/reviews/code-fact-check-report-build-loop-u2a3.md` (iteration 1), via the shared fact-check summary
**Probes:** executed in `/tmp/u2a3-sec-i2-IYxc`, `/tmp/u2a3-sec-i2-Ta6l`, `/tmp/u2a3-sec-i2-Bz0r` (scripts `probe.sh`, `probe2.sh`, `probe-patched.sh` in the session scratchpad `u2a3-sec-i2/`). No background processes were started. Claude Code 2.1.292 is installed, but running it against probe repos was not permitted in this sandbox, so every statement below about what Claude Code loads is unexecuted and is marked as such.

## Trust Boundary Map

```
B1: [main's commit: tree names, modes, blobs, symlink text]       → [main_imports: ls-tree -r -z / cat-file parse, link-text check :552-602] → [IMPORTED_MAIN]
B2 (new): [gate checkout: untracked files, which paths exist, symlinks] → [untracked_md :562, inrepo_here / -d -e -L :580-582, -L :600]   → [IMPORTED_MAIN]
B3 (new): [IMPORTED_MAIN + walk status]                             → [isimported main :626]                                               → [U2a4 floor: self-merge allowed / refused]
B4: [Claude Code 2.1.292 loader semantics (external)]               → [the walk's model of what gets loaded (start set, base dir, resolution)] → [the floor's coverage claim, plan F11]
```

Input sources:

```
S1: main's tree names and modes      — runtime-mutable (a self-merge lands non-floor paths; F8 refuses new symlinks/gitlinks)
                                       — UNTRUSTED for path construction/parsing; trusted as main's reviewed state for "what is loaded"
S2: main's instruction blobs (@ tokens) — runtime-mutable (same) — UNTRUSTED for parsing; authoritative for the import graph
S3: main's symlink text (mode 120000)   — runtime-mutable (human-reviewed only; F8 keeps the loop from adding links) — UNTRUSTED for path construction
S4: checkout's untracked .md listing and content — runtime-mutable by whoever writes the checkout (the loop, if the gate runs in its worktree)
                                       — UNTRUSTED; acceptable only as a source that adds imports
S5: checkout's filesystem shape (which links/dirs exist) — runtime-mutable (same) — UNTRUSTED toward any decision that removes an import
S6: MAIN_SHA / MAIN_BY_NAME (resolve_main, refs) — runtime-mutable refs — trusted to name the commit only when found by name (main_by_name gate :551)
S7: ROOT_REAL / cwd                  — caller-set, checked by need_root — trusted for path construction
```

The walk's stated invariant (lib header :32-34) is that the checkout "can only add imports": S4 and S5 may only make `isimported main` say "imported" more often. The boundary that matters is B2 → B3: anything in the checkout that makes the walk drop a target main's commit would load is a fail-open on the self-merge floor. Finding 1 is exactly such a case; findings 2 and 3 are B4 model gaps.

## Findings

#### 1. The checkout's lack of a link main stores removes an import: link text and @ tokens through a directory main stores as a symlink are recorded under the link's name, not the file read

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:596-602`, `:612`, `:580-583`; comment `:464-468`
**Boundary:** B2, B1 → B3
**Move:** 1 (trace the trust boundaries), 5 (invert: what does the checkout probe prevent?), 11
**Confidence:** High for the walk's behaviour (executed); Medium for reachability (needs a directory symlink on main with a path through it, and a gate checkout that lacks the link)
**Legibility-target:** the lib comment at :466-468 and known issue A5 (both understate the gap); the header invariant at :32-34

**Evidence** (excerpt :596-602 and :607-613; enclosing main_imports() runs :545-615 — read whole):

```
          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
          for c in "${parts[@]}"; do
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
          done
          out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..
...
      IMPORTED_MAIN+="$(lower "$p")"$'\n'
      ...
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi
```

and the t: arm (:580-583):

```
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }
      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
      else continue; fi
```

The comment at :466-468 reads "an @ token's path (link text is checked above) through a directory main stores as a symlink when the checkout does not have that link". `lk` is set when a component is a link but is only consulted for a later `..`; a final path through a symlinked directory passes, is recorded as `ld/evil.md`, is queued as `t:ld/evil.md` (ls-tree -r never lists a path under a symlink, so `ent` lacks it), and when the checkout lacks `ld` the t: arm takes `else continue`. The file the kernel opens, `deep/evil.md`, is never recorded.

Executed (probe.sh / probe2.sh):

| Probe | main | checkout | walk | `deep/…` |
|---|---|---|---|---|
| P1 (fact-check Q10) | `CLAUDE.md -> ld/evil.md`, `ld -> deep` | `ld` removed | ok | `deep/evil.md: -` |
| P14 (Q11, chain) | `CLAUDE.md -> l1.md -> ld/evil.md`, `ld -> deep` | `ld` removed | ok | `deep/evil.md: -` |
| P2 (A5, @ token) | CLAUDE.md `@ld/x.md`, `ld -> deep` | `ld` removed | ok | `deep/x.md: -` |
| P2b / P16 | same | `ld` present | failed | imported (fails closed) |

Attack: a loop worktree is branched from main, so it has `ld`. The loop deletes `ld` in its working tree without committing (or commits the deletion and restores it in a later commit the gate does not see at walk time, depending on U2b), edits `deep/evil.md`, and the gate runs in that checkout. The walk answers "not imported" for `deep/evil.md` and the floor lets it self-merge, while the merged tree still has `CLAUDE.md -> ld/evil.md` and Claude Code loads the edited file unreviewed. The checkout's *absence* subtracted an import, which the header (":32-34 ... which can only add imports") says cannot happen. Whether the attack is reachable depends on U2b: whether `--check` runs in the loop's worktree and whether its state gate requires a clean tree. Neither exists yet, so Confidence is Medium. Under the floor rule this cannot rate below Medium: the mechanism is concrete, and the precondition on main (a reviewed directory symlink with a load path through it) is legitimate repo content.

This is the same class as iteration 1's red (link text resolved lexically past a symlink). The fix closed the `..` half and left the prefix half, and the comment's "link text is checked above" makes the gap read as closed for link text.

**Recommendation:** Decide from main's tree alone, never from the checkout's absence. Before queueing a `t:` item, fail the walk when any proper prefix of the path is a 120000 entry in `ent`. One loop over `ent`, no I/O:
`if [[ -z "${ent[$p]+set}" ]]; then c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ "${ent[$c]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done; fi`
Prototyped at :612 in a scratch copy of the lib (`lib-patched.sh`, executed). P1 and P2 now fail closed, and P3, P3b and P11 (plain-directory and same-directory links) stay ok. The bats suite was not run against the patch. This also closes A5's "@ token's path through a directory main stores as a symlink" half. Then reword :466-468, A5 and plan F11, and add a test for P1 with `ld` removed from the checkout.

#### 2. A symlinked instruction file's imports are resolved only against the link target's directory; if Claude Code resolves them against the link's own path, those imports are missed

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:575-577` (base dir `d` from the queued path), `:602`, `:612`
**Boundary:** B4 → B3
**Move:** 2 (implicit assumption), 11
**Confidence:** Low (the walk side is executed; Claude Code's base directory is unverified)
**Legibility-target:** lib comment :455-456 ("a symlink there is followed to the path its text names"); tests at build-loop-check.bats "main walk follows what Claude Code loads"

**Evidence** (excerpt :575-577; enclosing main_imports() continues to :615 — read):

```
    src="${queue[0]:0:1}"; f="${queue[0]:2}"; queue=("${queue[@]:1}")
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
```

When `m:CLAUDE.md` is a 120000 entry, the walk queues the resolved target (`docs/real.md`), and the target's tokens resolve against `docs/`. Executed: P3 (`CLAUDE.md -> docs/real.md`, real.md `@x.md`) gives `docs/x.md: imported`, `x.md: -`. P3b (`@docs/link.md`, `docs/link.md -> ../other/real.md`, real.md `@y.md`) gives `other/y.md: imported`, `docs/y.md: -`. A loader that reads the file at the path it found (`CLAUDE.md`) and resolves relative imports with `dirname()` of that path, with no realpath (the common Node pattern), resolves `@x.md` to `x.md`. A loop branch could then self-merge `x.md`. Both existing symlink tests place link and target in the same directory (`CLAUDE.md -> real.md`, `docs/link.md -> target.md`), so they do not distinguish the two bases.

**Recommendation:** Resolve a followed link target's tokens against both directories (the target's and the link's own `d`) and record both. Over-reading only over-refuses, which matches the walk's existing "whole and stripped" practice. Alternatively, establish Claude Code's behaviour with a probe on a host that may run it, and pin the answer with a test that uses different directories.

#### 3. `.claude/commands/` files are not start files, but Claude Code expands their `@` file references when the command runs (B14 candidate)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:567-573` (start filter)
**Boundary:** B4 → B3
**Move:** 5 (invert: which loaded files are not starts?), 11
**Confidence:** Medium (the walk side is executed; Claude Code's expansion of `@` in custom slash commands is documented behaviour but was not executed here)
**Legibility-target:** known issue A5 / plan F11 (neither lists commands or agents)

**Evidence** (excerpt :567-573; enclosing main_imports() continues to :615 — read):

```
  for i in "${!cand[@]}"; do
    f="${low[i]:2}"
    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
      seen[${cand[i]:2}]=1; queue+=("${cand[i]}")
    fi
  done
```

Executed (P4): `.claude/commands/deploy.md` containing `run with @docs/c.md`, `.claude/agents/a.md` containing `@docs/ag.md` and `.claude/output-styles/s.md` containing `@docs/os.md` give walk ok and `-` for all three targets. Floor item 2 (any `.`-prefixed component) protects the command file itself, but not `docs/c.md`. When the user runs `/deploy`, Claude Code inlines `docs/c.md` into the prompt, so a self-merged edit to it takes effect unreviewed, which is the threat this walk exists for. Command `@` references are likely resolved against the session's working directory rather than the command file's directory; that is unverified, so a fix should record both bases. Agents and output styles are listed as untested below, since `@` expansion there is less likely.

**Recommendation:** Add `.claude/commands/**/*.md` (any depth, any case) to the start set, and resolve its tokens against both the repo root and the file's directory. If that is out of scope for U2a3, add the gap to A5, plan F11 and the lib's not-covered list, so Q-103 sees it.

#### 4. The walk's cache ignores checkout state, so a second call in one shell misses an untracked start file added after the first

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:549-550`
**Boundary:** B2 → B3
**Move:** 4 (TOCTOU: the check is cached)
**Confidence:** Low (no caller yet; it matters only if U2a4/U2b call the walk twice with the checkout changing between calls)
**Legibility-target:** lib comment :469-470 ("cached for the commit and root")

**Evidence** (excerpt :549-550; enclosing main_imports() continues to :615 — read):

```
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"
```

Executed (P5): walk 1 ok; then `CLAUDE.local.md` with `@docs/u.md` is written; walk 2 ok and `docs/u.md: -`; after clearing `IMPORTED_MAIN_DONE`, `docs/u.md: imported`. This confirms the fact-check escalation. The key also ignores `MAIN_BY_NAME`, but that side fails closed.

**Recommendation:** Document "one walk per process; the checkout is read once" as a precondition for U2a4/U2b, or key the cache on the untracked listing too (the walk already reads it whole). U2a4's floor test should cover a floor that walks, sees the checkout change, and walks again.

#### 5. D8: override row 366's Defer reason answers the wrong direction

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:366`
**Boundary:** B4 → B3
**Move:** 5
**Confidence:** Medium
**Legibility-target:** override-log row 366's reason

**Evidence:** row 366's reason reads "A submodule's files do not change on a parent merge (F8 refuses gitlinks)." The risk D8 names runs the other way: an instruction file *inside* a submodule (content this repo did not review) that `@`-imports a parent-repo path (e.g. `@../docs/p.md`), which does change on a parent merge. Claude Code would load that file when it works in the submodule's directory (nested CLAUDE.md, loaded lazily; not executed here). The mechanism is already recorded and deferred, and row 350 keeps self-merge off until Q-103 is answered, so this is not a new finding and the Defer is adequate. The reason should still say the parent-path direction, so the U2b trigger evaluates the right thing.

**Recommendation:** When U2b revisits row 366, record that a submodule start file's imports into the parent are the exposure. Either start the walk from gitlink paths' instruction files in the checkout, or fail the walk when main stores a gitlink and the checkout has an instruction file under it.

## Carried candidates (B14, D8, iteration-1 fix) — disposition

| Candidate | Disposition |
|---|---|
| `.claude/commands/` references | **Finding 3** (executed, walk side) |
| `.claude/agents/`, `.claude/output-styles/` references | Untested (below): walk does not start from them (P4 executed); whether Claude Code expands `@` there is unverified |
| Non-.md under `.claude/rules/` | Cleared for the walk (P7b: `a.txt` not a start; `b.MD` is a start, an over-inclusion). Claude Code loading only `.md` there is documentation, not executed |
| HTML escape `&#64;` | Cleared: Claude Code 2.1.292's import regex `(?:^|\s)@((?:[^\s\\]|\\ )+)` (read from the binary's string table at byte 99785292) needs a literal `@`; P8 walk records nothing for `&#64;docs/h.md` |
| A name stored as both blob and tree | Cleared, fails closed (P6, executed: ls-tree lists `CLAUDE.md` and `CLAUDE.md/CLAUDE.md`, cat-file of the latter fails, walk failed, everything imported) |
| `[` / `]` in a token | P8 executed: `@docs/a]b.md` records `docs/a`, not `docs/a]b.md`. **Fixed in U2a3b (stacked)** per override row 358 (each token yields its whole and its pre-cut part) |
| D8 (submodule / untracked nested repo) | Documented (row 366, A5, F11); Finding 5 on the row's reason |
| Iteration-1 fix (`..` after a symlink in link text) | Verified for that shape: P12 (`ld/../x.md`, `ld` symlink on main) fails; P13 (main plain dir, checkout symlink, `a/../x.md`) fails, exercising the `-L` half the fact-check says no test pins; P11 (`a/b/../c.md`, plain dirs) ok. The prefix half is Finding 1 |
| Untracked `.claude/rules` start (iteration-1 test gap) | Behaviour ok (P9b: top-level and `pkg/.claude/rules` untracked starts both recorded); still untested in the suite |

## Untested bypass candidates

- **`..` after a symlinked directory inside an `@` token** (P15, walk side executed). Setup: CLAUDE.md `@ld/../q.md`, `ld -> deep/sub` on main, with `ld` present in the checkout too. The walk is ok and records `q.md`, and `deep/q.md: -`; the kernel path `ld/../q.md` reads `deep/q.md` (`cat` confirmed). `import_targets` normalizes lexically (:499, still `realpath -ms` in U2a3b), so no checkout probe sees `ld`, and A5's "when the checkout lacks that link" qualifier does not describe this shape. It is a real miss only if Claude Code resolves `@` paths through the kernel, or with realpath, rather than lexically (`path.resolve`). Fact-check i2 Claim 12b leaves that open. Not filed as a finding for that reason; Finding 1's prefix check does not cover it, because the prefix is gone after normalization.
- **Claude Code's base directory for a symlinked memory file** (Finding 2's dependency): not executable here.
- **`@` expansion in `.claude/agents/*.md` and output styles**: not executable here.
- **A submodule's CLAUDE.md loaded lazily and importing parent paths**: not executable here.
- **Backslash-escaped space (`@docs/a\ b.md`)**: settled under override rows 350/356 (Defer); not re-tested.
- **A failing `lower` at :609 recording an empty name** (fail-open under `if`): fixed in U2a3b (stacked), per override row 359; not re-tested.
- **Case-insensitive checkout, absolute imports, starts under a symlinked directory** (P10 executed: `sub -> real`, `real/CLAUDE.md`, the import is recorded as `real/sec.md` only): documented in A5; not re-filed.

## Endorsement Claims

- **Claim:** Link text on main with a `..` after a component that is a symlink on main, or in the checkout, fails the walk (IMPORTED_MAIN=error, every path imported).
  **Location:** `scripts/lib/dev-cycle-read.sh:596-600`
  **Evidence:** executed
  **Verified:** P12 (`CLAUDE.md -> ld/../x.md`, `ld` symlink on main) walk failed; P13 (main plain `a`, checkout `a -> other`, `CLAUDE.md -> a/../x.md`) walk failed; P11 (plain `a/b/../c.md`) walk ok, `a/c.md` and `a/z.md` imported.
  **Not verified:** a `..` after a symlink inside an `@` token (P15, normalized away at :499 before this loop is reached).
  **route: code-fact-check**
- **Claim:** A name main's tree stores both as a blob and as a tree (`CLAUDE.md` and `CLAUDE.md/CLAUDE.md`) fails the walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:586`
  **Evidence:** executed
  **Verified:** P6: mktree accepted the tree, ls-tree -r listed both, `git cat-file blob` of the inner path failed, walk failed, `docs/blob.md` and `docs/inner.md` imported.
  **Not verified:** whether a checkout of such a commit is possible (the gate reads the commit, so this is not on the walk's path).
  **route: code-fact-check**
- **Claim:** Untracked `.md` files under `.claude/rules/`, at the top level and nested (`pkg/.claude/rules/`), start the walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:562-573`
  **Evidence:** executed
  **Verified:** P9b: `docs/ur.md` and `docs/nr.md` imported from untracked rules files.
  **Not verified:** untracked rules files under an untracked nested repo (git ls-files `--others` does not enter one; A5).
- **Claim:** `isimported main` answers imported (0) whenever main_imports returns 1.
  **Location:** `scripts/lib/dev-cycle-read.sh:626`
  **Evidence:** executed
  **Verified:** P2b, P6, P12, P13 and P16 each printed `walk: failed` followed by `imported` for every queried path.
  **Not verified:** the U2a4 floor's handling of that answer (no caller yet).
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction / file read (checkout reads, git object reads, lexical resolution)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:552` `git ls-tree -r -z --full-tree "$MAIN_SHA"` | S6 | main_by_name (:551), rc sentinel, record regex (:556) | cleared: hash argument only; parse failures fail the walk |
| `:562` `untracked_md` | S4 | rc sentinel; newline names fail (:565) | cleared: can only add starts |
| `:580` `import_targets "$d" < "$f"` (checkout read) | S4, S2 | `inrepo_here` (blocker walk + `-f`) | cleared: content main lacks; a swap after the check only changes which added imports are read |
| `:581-583` `-d` / `-e` / `-L` on the checkout path | S5 | blocker | **Finding 1**: an absent path main reaches through a symlinked directory is `continue` |
| `:586` `git cat-file blob "$MAIN_SHA:$f"` | S1, S2 | `$MAIN_SHA:` prefix (no option injection), pipefail | cleared |
| `:590-591` `git cat-file blob` for link text (NUL count, `x` sentinel) | S3 | NUL, newline, empty and absolute checks (:592-593) | cleared |
| `:599-600` per-component `realpath -ms` + `ent`/`-L` | S3, S5 | `..` after link fails | cleared for `..` (P12, P13); lstat outside the repo when the text climbs above root is metadata-only and fails closed (fact-check Q9, informational) |
| `:602` final `realpath -ms` of link text | S3 | `..`/`../*` refusal | **Finding 1**: lexical through a directory symlink |
| `:499` `realpath -ms` in `import_targets` | S2 | `..`/`../*` refusal | **Finding 1** (prefix half; prototype fix at :612); P15 untested candidate (`..` half) |
| `:609` `lower "$p"` | S2 | none in this branch | fixed in U2a3b (stacked), row 359 |
| `:612` queue `t:` vs `m:` by `ent` | S1, S5 | none for symlinked prefixes | **Finding 1** |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Checkout lacking a link main stores drops imports through that symlinked directory (link text and @ tokens); comment says link text is checked | Medium | B2, B1→B3 | `scripts/lib/dev-cycle-read.sh:596-602, :612, :580-583, :466-468` | High (behaviour) / Medium (reach) |
| 2 | Symlinked file's imports resolved only against the target's directory | Medium | B4→B3 | `:575-577, :602, :612` | Low |
| 3 | `.claude/commands/` not a start; its `@` references load on invocation | Medium | B4→B3 | `:567-573` | Medium |
| 4 | Cache key ignores checkout state | Medium | B2→B3 | `:549-550` | Low |
| 5 | Row 366's Defer reason names the wrong direction (D8) | Informational | B4→B3 | `docs/reviews/override-log.md:366` | Medium |

## Overall Assessment

The walk fails closed on every malformed shape probed (doubled names, blob/tree collision, `..` after a symlink in link text, checkout symlinks on a path it reads), and `isimported main` refuses whenever the walk fails. The iteration-1 red is fixed for its `..` shape. The most important remaining issue is Finding 1. The checkout's absence of a symlinked directory that main stores makes the walk drop the file the kernel reads, which breaks the lib's own invariant that the checkout "can only add imports". It also makes the :466-468 comment's "link text is checked above" untrue. The fix is local and cheap: a prefix check against `ent` before queueing a `t:` item. It was prototyped and executed here, but not run against the suite. Findings 2 and 3 are gaps in the model of what Claude Code loads. Each can be closed by over-reading (both base directories; commands as starts) or by recording it in A5/F11. Finding 4 is a precondition U2a4/U2b must state. None of these is architectural, and self-merge stays off until Q-103 (row 350). Not safe to call clean: there are no other findings within the code paths read, the endorsement claims are pending execution verification, and every Claude Code loader behaviour above is unexecuted.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3.md, structured per the security-reviewer skill."
- **Answered:** The security design review of `git diff main...HEAD` at 34edec56, focused on the walk answering "not imported" for a file Claude Code would load. Iteration-1 fix verified for `..`. Q10/Q11 reproduced and generalized to Finding 1, with an executed prototype fix. B14 candidates and D8 dispositioned. Cache escalation confirmed.
- **Out of scope:** U2a3b's parser changes (brackets, Unicode spaces, failing `lower`), referenced as "fixed in U2a3b (stacked)"; the U2a4 floor and U2b `--check` (no caller yet); performance (row 365).
- **Escalate:** (1) Finding 1 should be fixed in this unit (it is the same class as iteration 1's red) or explicitly re-scoped in A5 with the checkout-subtracts framing. (2) Claude Code's base directory for symlinked memory files, `@` expansion in commands and agents, and lexical-vs-kernel resolution of `@` tokens (P15) need a probe on a host allowed to run Claude Code; that probe decides whether Findings 2 and 3 and candidate P15 are real misses.
