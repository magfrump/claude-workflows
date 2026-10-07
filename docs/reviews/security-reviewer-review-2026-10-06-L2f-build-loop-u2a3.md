Commit: 1898d21c

# Security Review — feat/build-loop-u2a3 (loop 2 final confirming pass, sec2f i2)

**Scope:** `git diff main...HEAD` of `feat/build-loop-u2a3` at 1898d21c (base main 62d366a7); code in `scripts/lib/dev-cycle-read.sh` (`main_imports`, `nul_list`, `isimported main`)
**Date:** 2026-10-06
**Based on:** the Stage 1 fact-check summary for this pass (replicates `code-fact-check-report-build-loop-u2a3-L2f-r1/-r2/-r3.md`, k=3), and the shared review context for loop 2
**Focus (from the task):** rate the tree/symlink doubled-name fail-open (r3 Claim 13b) and check its suggested fix; look for other ways main's own tree can make the text Claude Code reads at a path differ from `git cat-file blob MAIN:path`.

All probes ran in a throwaway directory (`/tmp/u2a3-sec2f-i2-XzI3`) with `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, every process under `timeout`, git 2.39.5. The fix was tried on a scratch copy of the lib, never on the worktree file.

## Trust Boundary Map

```
B1: [main's commit: tree records (ls-tree -r)]      → [record regex, doubled-name/newline checks :555-559] → [ent map: names and modes]
B2: [main's blobs: instruction-file + link text]    → [import_targets / link-text checks :578-596]       → [IMPORTED_MAIN set]
B3: [checkout state: untracked, index, paths]       → [start check :563-571, path probe :607-608]         → [walk fails closed (no content read)]
B4: [git checkout transform of main's tree]         → [none: the walk reads blobs, not the checkout]      → [bytes Claude Code reads in a worktree]   (new: named by this review)
B5: [IMPORTED_MAIN answer]                          → [isimported main :622]                              → [U2a4 floor's self-merge decision (no caller yet)]
```

Input sources:

```
S1: main's tree records         — runtime-mutable (each merge to main) — UNTRUSTED toward the walk's path model (shape is
                                                                           refused, not assumed); trusted as main's
                                                                           reviewed content only for merges the gate made
S2: main's blob text            — runtime-mutable                     — UNTRUSTED toward the import set (parsed, never run)
S3: main's .gitattributes       — runtime-mutable (human merges only:   — UNTRUSTED toward "checkout bytes == blob bytes";
                                  floor item 2 refuses dot paths)         not read by the walk at all
S4: repo config (core.symlinks, — host/deploy-time (.git/config)      — out of the walk's model; T42 refuses some keys
    filter drivers)                                                       for the gate's own git calls only
S5: checkout listings/probes    — request-time (the gate's worktree)   — UNTRUSTED; only ever fails the walk after the split
```

The walk's security premise is that `git cat-file blob MAIN:path` is the text Claude Code will read at `path` in a checkout of main. B1 tests the tree's shape; nothing tests B4, the transformation git applies between the blob and the file on disk. Every finding below is a place where B1 or B4 lets those two differ.

## Findings

#### F1. A name main stores as both a tree (listed first) and a symlink passes the doubled-name check; the walk reads the tree's blob while a checkout writes the symlink

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:557` (doubled-name check), `:606-608` (parent check skipped because `ent[l/x.md]` is set)
**Boundary:** B1
**Move:** 11 (bypasses for a guardrail), 3
**Confidence:** Medium that the walk fails open on that shape (executed); Low that it is reached in practice (see reachability)
**Legibility-target:** the doubled-name sentence in main_imports' block comment and return-1 comment ("a name is listed twice"), and A5's "odd names" clause; both read as covering every doubled name.

**Evidence (executed, reproduces r3 Claim 13b):** main = `CLAUDE.md` (`Rules: @l/x.md`), tree `l/` holding `x.md` (`benign`), `docs/x.md` (`evil: @docs/secret.md`), plus a symlink `l -> docs` written after the tree with `git hash-object --literally -t tree`. `git ls-tree` lists `040000 tree … l` then `120000 blob … l`; `git fsck` reports `duplicateEntries`. A fresh `git worktree add` writes `l -> docs`, so Claude Code reading `l/x.md` reads `docs/x.md` and its import of `docs/secret.md`. The walk: `walk: ok`, `l/x.md: imported`, `docs/x.md: -`, `docs/secret.md: -`. The check at :557 compares full names; `ls-tree -r` prints the tree's leaf `l/x.md` and the symlink `l`, which never collide. Same result with a slash-named blob entry `l/x.md` in place of the tree (probe F3). A gitlink instead of the symlink (F2) passes too, but the checkout then holds an empty `l/`, so Claude Code reads less than the walk, not more.

**Reachability (who can write a non-canonical tree into main):**
- *Through the gate: not reachable.* D7 computes the merge with `merge-tree --write-tree MAIN TIP`. Executed with that TIP against the canonical base: merge-tree wrote a canonical tree holding only the symlink `l` (the tree `l` was dropped), and `diff-tree -r --raw MAIN TIP` shows `A l` with mode 120000, which F7/T12 refuses. The walk on the merge-tree result would see `ent[l]=120000`, `l/x.md` absent, and fail at the parent check (:607).
- *Outside the gate: reachable with a human in the loop.* An agent with a shell can build the commit (`hash-object --literally`, `commit-tree`); a human who fast-forwards that branch (`git merge` fast-forwards by default; this repo's maintainer merges locally) puts the non-canonical tree on main verbatim. The reviewer's diff shows one added symlink `l -> docs`; `git fsck` would flag it, but nothing in the flow runs fsck. Whether the remote rejects it on push (`receive.fsckObjects`) is host-side and was not checked.
- Once on main, every later walk reads the stale tree blob, so `docs/x.md` and everything it imports can be self-merged through the floor.

Per the floor rule this names a concrete fail-open mechanism in a reachable environment (a human fast-forward), so it is not rated below Medium; the low likelihood sits in Confidence. Settled row :379 does not cover it: that row probed only the blob-first order, where the walk fails at `cat-file`.

**Recommendation:** take the fact-check's fix: refuse a listed name that is a proper path prefix of another listed name. One line after the record loop, before :561:
`for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${ent[$c]+set}" ]] || return 1; done; done`
**Completeness check (executed on a scratch copy):** it fails the walk on tree+symlink (F1), tree+gitlink (F2) and slash-named blob+symlink (F3), and leaves the canonical base ok (F4). Shapes it does not catch, all checked: (a) a tree listed twice with *different* leaves: the second copy's leaves are listed but `MAIN:path` finds the first tree, so any read of them fails at `cat-file` (closed); with the *same* leaf the full names collide at :557 (closed); (b) an empty tree doubled with anything: `ls-tree -r` prints nothing for it and the checkout writes nothing, so walk and checkout agree; (c) a lone slash-named entry `l/x.md` with no other `l` (F5): the checkout does not write it (empty `l/`), so Claude Code reads less than the walk. No shape found where the fix is needed and absent. A cheaper equivalent, if the O(entries x depth) loop matters at 30k entries (unmeasured; row :365 already prices this phase): apply the same prefix test only to each path the walk reads (the starts and each queued `p`). Fix in place: it is one line and closes a fail-open; add a test that builds F1 with `hash-object --literally`.

#### F2. A `working-tree-encoding` attribute in main's `.gitattributes` makes the checkout bytes differ from the blob: an import that exists only after conversion is never recorded

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:579` (`git cat-file blob "$MAIN_SHA:$f" | import_targets`), and the walk's whole read model (`:546-610`); no attribute is consulted anywhere in main_imports
**Boundary:** B4 (new)
**Move:** 2 (assumed equivalence of blob and file), 1
**Confidence:** High that the walk and the checkout diverge (executed); Medium that Claude Code reads the converted file as UTF-8 and loads the import (Claude Code not run; it reads instruction files as UTF-8 text)
**Legibility-target:** main_imports' block comment ("follows an import into the file main stores at that path") and plan F11 / A5, which list what the walk does not model and do not name checkout conversions.

**Evidence (executed):** main holds `CLAUDE.md` (`Rules: @docs/a.md`), `docs/secret.md`, and `.gitattributes` = `docs/a.md working-tree-encoding=ISO646-DE`. The blob of `docs/a.md` is the UTF-8 text `See §docs/secret.md for details` (`git cat-file blob main:docs/a.md` prints exactly that). A fresh `git worktree add` writes `See @docs/secret.md for details`: ISO646-DE puts `§` at byte 0x40, which is `@` in ASCII/UTF-8. The walk: `walk: ok`, `docs/a.md: imported`, `docs/secret.md: -`. So `docs/secret.md` can then be self-merged with any content, and Claude Code loads it in every session through `docs/a.md`. No config is needed: the attribute comes from the tree, and git's iconv conversion applies on every checkout.

**Reachability:** `.gitattributes` itself cannot self-merge (floor item 2 refuses any `.`-prefixed component, T10/F5), so the attribute and the `§` text in an imported file each need a human-reviewed merge. Neither looks dangerous in review: the diff shows `§docs/secret.md`, a section-sign reference, and an encoding line. ISO646 variants drop `[`, `\`, `]`, `{`, `|`, `}`, `~`, so the target file cannot hold Markdown brackets (conversion fails), which limits but does not remove the shape. Other encodings move whole files (EBCDIC, UTF-16); UTF-16 makes Claude Code see fewer imports, the safe direction. The same class includes a `filter=` attribute (for example `filter=lfs` when git-lfs is configured on the host: the walk reads the pointer text, the checkout gets the object), which needs host config (S4) and was not executed.

**Recommendation:** fail the walk when any path it reads carries a checkout conversion it does not model: `working-tree-encoding` or `filter` (and treat `ident` as harmless). In the fresh worktree the gate needs until U2a3c, the worktree's `.gitattributes` are main's, so `git check-attr -z working-tree-encoding filter -- <paths read>` gives the answer (git 2.39 here has no `check-attr --source`; that needs 2.40). If the 400-line cap rules it out of U2a3, record it with a must-address row against U2a3c/U2b and name it in A5 and F11's not-covered list.

#### F3. With `core.symlinks=false`, a symlink on main checks out as a plain file holding its link text, which Claude Code reads as instructions; the walk reads the text only as a path

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:580-596` (120000 arm)
**Boundary:** B4, S4
**Move:** 2, 11
**Confidence:** High for the divergence (executed); Low for reach on this project's Linux hosts (the setting is git's automatic default only on filesystems without symlinks, e.g. Windows clones)
**Legibility-target:** the 120000 arm's comment ("its text names the file read, as one more import") and A5.

**Evidence (executed):** main holds `CLAUDE.md -> '@docs/secret.md'` (a symlink whose text is an import token) and `docs/secret.md`. With `git config core.symlinks false`, `git worktree add` writes `CLAUDE.md` as a 15-byte regular file containing `@docs/secret.md`; Claude Code reading it would import `docs/secret.md`. The walk resolves the text as the path `@docs/secret.md` (main lacks it, checkout lacks it: recorded and not walked): `walk: ok`, `docs/secret.md: -`.

**Reachability:** symlink adds cannot self-merge (F7/T12), so a human merges the link; the gate's own worktree inherits the repo's `.git/config`, and T42's state refusals do not list `core.symlinks`. The exposure is for checkouts where Claude Code runs with `core.symlinks=false`.

**Recommendation:** in the 120000 arm, also pass the link text through `import_targets "$d"` and add those paths, so both readings of the text are recorded (cheap, and complete for this shape); or have the caller refuse when `core.symlinks` is false. Either way name it in A5.

## Untested bypass candidates

Candidates for "the checkout's bytes at a path differ from `MAIN:path`" that were enumerated and not executed:
- **NFD/NFC and HFS+-ignorable code points** (`CLAUDE` + U+200C + `.md` folding onto `CLAUDE.md` on macOS): the same class as A5's "other names one file has on a case-insensitive checkout", but A5 names case only. Not run: Linux host, no HFS+ volume.
- **`filter=lfs` with git-lfs configured globally** (F2's sibling): host config; git-lfs is not configured in this sandbox (`filter.lfs.smudge` unset).
- **`text`/`eol` conversion** (main's own `.gitattributes` holds `* text=auto eol=lf`): CRLF/LF changes cannot create or remove an `@` token, and Claude Code's token ends at `\s`, which includes CR; traced by reading, not executed.
- **Replace refs, grafts, `GIT_INDEX_FILE`, fsmonitor, sparse checkout:** settled (override row "untested git-hardening bypasses", to U2b); not re-filed.

## Endorsement Claims

- **Claim:** after the split, a start file main lacks fails the walk whether it is untracked, ignored or only in the checkout index, so checkout state cannot add an unwalked start.
  **Location:** `scripts/lib/dev-cycle-read.sh:561-571`
  **Evidence:** read-static
  **Verified:** read :561-571: both listings go through `nul_list` (fail on a short or failed listing); a candidate tagged `t:` that matches the start rule returns 1.
  **Not verified:** the fact-check's 22+ executed checkout states were not re-run in this pass; a gitlink stored at a start name (test-strategy's untested `160000` arm).
  **route: code-fact-check**
- **Claim:** the gate's D7 merge path cannot put a doubled-name tree on main: `merge-tree --write-tree` against a non-canonical TIP wrote a canonical tree, and `diff-tree` reports the symlink add F7 refuses.
  **Location:** plan D7; `scripts/lib/dev-cycle-read.sh:557`
  **Evidence:** executed
  **Verified:** one TIP (tree `l` then symlink `l`) merged against its canonical parent with git 2.39.5; `ls-tree` of the result lists `CLAUDE.md`, `docs`, symlink `l` only.
  **Not verified:** other git versions' merge-ort handling of duplicate entries; a non-canonical tree under a subdirectory rather than the root; U2a4/U2b's actual merge code (not written yet).
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction / git object lookup from tree-supplied names (`MAIN:path`, `realpath`, filesystem probes)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:579` `cat-file blob MAIN:$f` (regular file) | S1 name, S2 text | name came from `ent` (:557 doubled/newline checks) | Finding F1 (prefix doubling), F2 (blob is not the checkout's bytes) |
| `:582-583` `cat-file blob MAIN:$f` (link text, twice) | S1, S2 | NUL count, empty/newline/absolute checks | Finding F3 (text read as content under core.symlinks=false); otherwise cleared (settled rows) |
| `:589-591` per-component `realpath -ms` + `-L "$p"` | S2 link text, S5 | `..` after a link fails | cleared — settled row (token `..` lexical vs kernel) |
| `:595` `realpath -ms` of the link target | S2 | `..`/`../*` refused | cleared — leaves-repo check |
| `:607` parent-link loop | S2 import paths, S1 modes | 120000/160000 parents fail | cleared for lacked paths; does not run for stored paths (F1's gap) |
| `:608` `-d`/`-L`/`-e` + `blocker` probe | S5 | anything but a plain directory fails | cleared — fails closed (split contract) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Tree-first + symlink doubled name passes :557; walk reads the stale tree blob | Medium | B1 | `scripts/lib/dev-cycle-read.sh:557, :606-608` | Medium (fail-open executed; reach needs a human fast-forward) |
| 2 | `working-tree-encoding` on main makes checkout bytes differ from the blob (`§` becomes `@`) | Medium | B4 | `scripts/lib/dev-cycle-read.sh:579` | High divergence / Medium Claude Code side |
| 3 | `core.symlinks=false` turns link text into instruction text | Medium | B4, S4 | `scripts/lib/dev-cycle-read.sh:580-596` | High divergence / Low reach on Linux |

## Overall Assessment

The split's checkout contract holds within the paths read: checkout state only fails the walk. The open risk is B4, the blob-to-checkout step the walk treats as identity. F1 is the cheapest to close and should be fixed in place: the fact-check's prefix refusal is one line and, on a scratch copy, closes every doubled-name shape tried without refusing a canonical tree. The gate cannot produce F1 itself (merge-tree canonicalizes, F7 refuses the symlink), so it needs a human fast-forward of an agent-built commit. F2 and F3 come from main's own tree (an attribute, a symlink) turned into different bytes by git's checkout. Both need a human-reviewed merge because floor items 2 and 5 refuse dot paths and symlinks, and in review both look harmless. They can be deferred under must-address rows if the line cap binds, but they belong in A5 and F11's not-covered lists now, since those lists currently read as complete for main's own content. No finding is Critical or High; no HALT pattern applies. No findings within the other code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md, structured per the security-reviewer skill.
- **Answered:** the doubled-name fail-open was reproduced and rated (Medium; Confidence Medium for the mechanism and Low for reach, since the gate's own merge path cannot produce it). The suggested fix was checked on a scratch copy against five shapes and is complete for them. Two more ways main's own tree makes checkout bytes differ from `MAIN:path` were found and executed: F2 (working-tree-encoding) and F3 (core.symlinks=false).
- **Out of scope:** U2a4's floor (not written), so whether it prefix-matches changed paths against the import set is unknown; checkout-walking behaviour (U2a3c); parser and sed/grep failure arms (U2a3b, stacked); git-hardening bypasses (settled, to U2b); Claude Code itself was not run.
- **Escalate:** the author and the rubric should decide F1 fix-in-place against defer (recommended: fix in place, with a `hash-object --literally` test). For F2 and F3, decide whether U2a3 fixes them or opens must-address rows against U2a3c/U2b, and add both to A5 and F11. Test-strategy: no test builds a non-canonical tree today.
