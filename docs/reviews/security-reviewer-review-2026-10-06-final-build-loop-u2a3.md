Commit: cc1aa864

# Security Review — feat/build-loop-u2a3 (main_imports, final confirming pass i3)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD cc1aa864). Code: `scripts/lib/dev-cycle-read.sh` main_imports (:549-618), nul_list (:519), untracked_md (:517), isimported (:624-633), header (:28-35) and block comments (:453-476, :538-548). Docs: plan F11, known issue A5, override rows.
**Date:** 2026-10-06
**Based on:** the final fact-check summary (k=3; replicates `docs/reviews/code-fact-check-report-build-loop-u2a3-f-r1.md`, `-f-r2.md`, `-f-r3.md`); settled rows in `docs/reviews/override-log.md` (2026-10-06 `feat/build-loop-u2a3`, :365-381)
**Probes:** executed in `/tmp/u2a3-sec-i3-Uh0I` (`probe.sh`, `scen1.sh` to `scen3.sh`; patched lib copies `lib-patched.sh` and `lib-patched2.sh`). No background processes were started. Claude Code was not run, so every statement about what Claude Code loads is unexecuted and marked as such. `test/scripts/build-loop-check.bats` was run at HEAD; tests 15 and 16, the last two, printed ok (the fact-check replicates report all five suites passing, 114 tests).

## Trust Boundary Map

```
B1: [main's commit: tree names, modes, blobs, symlink text]               → [ls-tree/cat-file parse, link-text check :556-603]          → [IMPORTED_MAIN]
B2: [gate checkout: untracked listing, which paths exist, modes, links]   → [untracked_md :564, t: arm :580-583, -L :600, seen :572]    → [IMPORTED_MAIN]
B3: [IMPORTED_MAIN + walk status]                                         → [isimported main :630]                                      → [U2a4 floor: self-merge allowed or refused]
B4: [Claude Code loader semantics (external, unexecuted)]                 → [the walk's model (start set, base dir, resolution)]        → [plan F11 coverage claim]
B5: [main's gitlink entries (mode 160000): content not in main's objects] → [treated as "main lacks p", read from the checkout :612-615] → [IMPORTED_MAIN]
```

Input sources:

```
S1: main's tree names and modes           — runtime-mutable (a self-merge lands non-floor paths; F8 keeps the loop from adding symlinks/gitlinks)
                                             — UNTRUSTED for parsing; authoritative for "what main's checkouts load"
S2: main's instruction blobs (@ tokens)   — runtime-mutable — UNTRUSTED for parsing; authoritative for the import graph
S3: main's symlink text (120000)          — runtime-mutable, human-added only (F8) — UNTRUSTED for path construction
S4: the gate checkout's untracked files, their content and the listing
                                           — runtime-mutable by whoever writes the checkout (the loop, if the gate runs in its worktree)
                                             — UNTRUSTED; acceptable only as a source that adds imports
S5: the gate checkout's filesystem shape (links, plain dirs replacing main's links, modes, submodule init state)
                                           — runtime-mutable (same) — UNTRUSTED toward any decision that removes an import
S6: MAIN_SHA / MAIN_BY_NAME               — runtime-mutable refs — trusted only when main is found by name (:555); replace refs are settled (row 252; build-loop.sh exports GIT_NO_REPLACE_OBJECTS)
S7: ROOT_REAL / cwd / caller environment  — caller-set, checked by need_root — trusted
```

The header (:32-35) states the invariant the floor rests on: the checkout "can only add imports or fail it". S4 can be dropped at will by its writer (deleting an untracked file), so a checkout state that loses only S4-derived imports gives the writer nothing new. A checkout state that loses an import derived from S1-S3, or that turns a walk main alone fails into an ok walk, is fail-open on B2 → B3. Finding 1 is the second kind. Finding 2 is an S1-derived import whose content main does not hold (B5). Findings 3 and 4 lose only S4-derived imports or need link text no checkout can create.

## Findings

#### 1. An untracked start file pre-empts the parent-link refusal, and the dropped file need not be start-shaped

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:571-572`, `:610-614`; claims at `:32-35`, `:463-466`
**Boundary:** B2 → B3 (S5 overrides an S1-derived refusal)
**Move:** 3 (error path: the refusal is skipped, not failed), 4 (state set before the check), 5 (invert: what does the seen map prevent?)
**Confidence:** High for the walk's behaviour (executed, P1b/P1d/P1e/P1f). Medium for reachability: main must store a directory symlink that an instruction file imports through, and the gate must run in a checkout the loop has changed (U2b names that checkout). Whether Claude Code follows an `@` path through a directory link is unexecuted (B4), but the kernel does.
**Legibility-target:** the header invariant :32-35 ("which can only add imports or fail it"), the block comment :463-466, A5, F11, and commit e7b5d7ed's message (immutable: needs an Accepted-immutable row if not fixed)

**Evidence** (excerpts :571-572 and :607-616; enclosing main_imports() runs :549-618, read whole):

```
    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
      seen[${cand[i]:2}]=1; queue+=("${cand[i]}")
...
      IMPORTED_MAIN+="$(lower "$p")"$'\n'
      [[ -z "${seen[$p]+set}" ]] || continue
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); continue; fi
      # Main lacks p: under a directory link main stores (the checkout may lack it), fail.
      for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done
      queue+=("t:$p")
    done < <(printf '%s\n' "$out")
```

Starts are marked seen at :572, before the walk. The parent-link refusal at :614 runs after the seen test at :610, so an import naming a path already marked seen skips it. This confirms fact-check r2 Claims 13, 18 and 27. The fact-check summary says "Exposure limited to start-shaped names". That holds when the link sits above an instruction-file basename (the basename survives the link, and U2a4's floor names start files by its own rule). It does not hold when the link is the `.claude` or `.claude/rules` component itself. The `.claude/rules/*.md` start rule then matches the link-side name, while the file the kernel opens has a plain name:

| Probe | main | gate checkout | walk | target |
|---|---|---|---|---|
| P1a | `ld -> deep`; CLAUDE.md `@ld/CLAUDE.md` | unchanged | failed | (fails closed) |
| P1b | same | `ld` replaced by a plain dir with untracked `ld/CLAUDE.md` | **ok** | `deep/CLAUDE.md: -` (start-shaped) |
| P1c | `.claude/rules -> ../docs`; CLAUDE.md `@.claude/rules/foo.md` | unchanged | failed | (fails closed) |
| P1d | same | `.claude/rules` replaced by a plain dir with untracked `foo.md` | **ok** | `docs/foo.md: -` |
| P1e | same; `docs/foo.md` holds `@bar.md` | same as P1d | **ok** | `docs/foo.md: -`, `docs/bar.md: -` |
| P1f | `.claude -> conf`; AGENTS.md `@.claude/rules/r.md` | `.claude` replaced by a plain dir with untracked `rules/r.md` | **ok** | `conf/rules/r.md: -` |
| P1g | as P1c without the import (baseline) | unchanged | ok | `docs/foo.md: -` (the documented A5 gap for starts under a symlinked directory) |

Attack: a loop that can write its gate checkout replaces main's `.claude/rules` link with a plain directory and drops in an untracked `foo.md`. The walk then passes, and a self-merge of `docs/foo.md` or `docs/bar.md` clears the floor (the dot-component rule refuses only `.claude/...` paths). In every checkout of main, CLAUDE.md's explicit import loads both files through the link. Without the tamper, main's own walk fails closed (P1c). P1g shows that A5's "start files under a symlinked directory" gap already covers the rules-dir load if Claude Code enters a symlinked rules directory. The explicit `@` import is a separate loader that A5 does not list, and here it is the S5 tamper that turns its refusal into a pass. This is new evidence against the summary's "start-shaped only" scoping. It is not a re-file of a settled row: no override row covers it, and rows 369-371 are B4 model questions.

**Recommendation:** run the parent-link check for every recorded path main lacks, before the seen test. Probed in `lib-patched.sh`, which moves the :614 loop above :610 under `[[ -z "${ent[$p]+set}" ]]`. That makes P1b, P1d, P1e and P1f fail and leaves the P1g baseline ok. The bats suites were not run on the patch. Add a P1d-shaped test, since the existing test 15 sub-cases do not seed a start at the import path. If the fix is deferred, narrow every copy of "can only add imports or fail it" and file an Accepted-immutable row for e7b5d7ed.

#### 2. An import into a submodule path reads the gate checkout's submodule state, so an uninitialised submodule drops main-pinned imports

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:612-615` (the parent check tests only 120000), `:580-583` (an absent t: path is `continue`); claim at `:457-458`
**Boundary:** B5, B2 → B3
**Move:** 1 (the gitlink's content crosses in from the checkout, not from main's objects), 5 (invert: the parent check denies 120000 parents only)
**Confidence:** High for the walk's behaviour (executed, P4a/P4b). Medium for reachability: main must hold a gitlink (none on this repo's main; F8 refuses the loop adding one, but a human can), and an instruction file must import a path inside it. `git worktree add` does not initialise submodules, so a fresh gate worktree is the default P4a state. That Claude Code loads `sub/x.md`'s relative import is unexecuted (B4), but a plain relative import is the case the walk models.
**Legibility-target:** the :457-458 sentence "A target main does not have is read from the checkout when it is a plain file there" (main does pin it, as a gitlink), A5's not-covered list, and rows 366/373

**Evidence** (excerpt :612-615 as quoted in Finding 1; :580-583):

```
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }
      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
      else continue; fi
```

| Probe | main | gate checkout | walk | `docs/y.md` |
|---|---|---|---|---|
| P4a | gitlink `sub` (its x.md holds `@../docs/y.md`); CLAUDE.md `@sub/x.md` | `sub` empty (not initialised) | ok | **-** |
| P4b | same | `sub` cloned at the pinned commit | ok | imported |

With `sub` a gitlink (`ent[sub]=160000`), `sub/x.md` passes the parent check and is queued `t:`. In the uninitialised worktree it is absent, so `else continue`, and its imports into the parent repo vanish. A checkout that has the submodule initialised (for example the user's main checkout) loads `docs/y.md` through CLAUDE.md. A self-merge of `docs/y.md` therefore clears the floor. A gate checkout with the submodule at some other commit can drop imports the same way. Relation to settled rows: rows 366 and 373 cover instruction files inside a submodule as starts, and row 373 suggests "the walk could later list gitlinks and fail on one", with trigger U2b. This finding is a different shape: an `@` path from main's own instruction file into a gitlink, failing open in the default worktree state. Row 373's suggested fix would cover it, but its trigger and reason do not name this shape.

**Recommendation:** treat a 160000 parent like a 120000 parent in the :614 check. A one-condition change was probed in `lib-patched2.sh`: P4a and P4b fail, and every scen1 case except the P1g baseline fails. Alternatively, amend row 373 to name this shape and list it in A5.

#### 3. An unsearchable checkout directory, or ls-files' exit-0 warning, hides checkout content without failing the walk (documentation and agreement, not a new capability)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:580-583`, `:517`, `:564`; claims at `:463` ("a checkout file it cannot read") and `:540` ("listed whole")
**Boundary:** B2 → B3
**Move:** 3 (error path), 5
**Confidence:** High (executed: P2b, P2c, controls P2a, P2d, P2e)
**Legibility-target:** the block comment :463, the return-1 comment :540-548, A5, F11

**Evidence** (:517, :564; :580-583 as quoted in Finding 2):

```
untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }
...
  nul_list recs untracked_md || return 1
```

Executed: with `sub` set to mode 000, the target `sub/x.md` (which main lacks) reads as absent, the walk is ok, and its import `docs/y.md` is `-` (P2b; readable control P2a imported). An untracked `priv/CLAUDE.md` under a mode-000 `priv` is skipped by `git ls-files --others` with `warning: could not open directory 'priv/'` and `rc=0`, so nul_list accepts the listing, and its import is `-` (P2c; control P2d imported). A mode-000 file still fails the walk (P2e). This confirms fact-check r2 Claim 19b.

Why Low and not Medium under the floor rule: both cases lose only imports derived from S4, the untracked content the checkout's writer can already delete. At gate time Claude Code, running as the same uid, cannot read those paths either, so the walk agrees with what that checkout loads. A main-derived (S1-S3) import is never read from the checkout's directory listing: the m: arms read objects, and the parent check reads `ent`. The property would break only if the gate ran under a uid that cannot search a directory which Claude Code's uid can. The plan has no such split. The comment's claim is wrong, though, so a reader of :463 or :540 would overrate the guard.

**Recommendation:** narrow the two claims ("a checkout file whose own mode blocks the read"; "listed whole" excludes directories git warns it cannot open). Or fail closed by running `untracked_md` with stderr captured and refusing on any `warning: could not open directory`, and by failing the t: arm when a parent component exists but is not searchable (`[[ -d parent && ! -x parent ]]`). The fix is optional for security.

#### 4. The link-text split at :596 is still a here-string; not materialisable

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:596-601`
**Boundary:** B1 (S3) → B3
**Move:** 3, 11
**Confidence:** High
**Legibility-target:** c42f017f's subject ("reads its import list without a here-string": true of the list, not of the link split)

**Evidence** (excerpt :596-601; enclosing 120000 arm :587-603 read whole):

```
          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
          for c in "${parts[@]}"; do
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
          done
```

As all three fact-check replicates found, an unchecked `read` failure (link text of 64 KiB or more, plus a temp-file write that fails without killing bash) leaves `parts` empty and skips the `..` check. Exploitability: executed on this host, `ln -s` with 4096-byte text fails with "File name too long" and 4095 succeeds, so no Linux checkout can create such a link, and Claude Code cannot load anything through it. The outcome is also bounded: the lexical target still passes the leaves-the-repo check at :602-603. No reachable fail-open. Bypass candidates considered: 64 KiB text with SIGXFSZ ignored (unmaterialisable); a disk-full temp-file failure (same text-length precondition); text that is exactly the pipe capacity (same).

**Recommendation:** for consistency with c42f017f, split with `mapfile -d / -t parts < <(printf '%s' "$out")`, or reject link text longer than 4095 bytes before the split (a cheap fail-closed bound that matches the kernel). Otherwise record an Accepted-immutable row for c42f017f's subject wording.

### Untested bypass candidates

- **Finding 1 through a link-text path rather than an `@` token:** a main symlink `CLAUDE.md -> ld/AGENTS.md` with an untracked start at `ld/AGENTS.md`. Not run separately because the same :610 ordering governs it; the lib-patched fix covers both.
- **A case-insensitive checkout:** an untracked `LD/CLAUDE.md` versus an import of `ld/CLAUDE.md`. Not testable on this filesystem; the case-insensitive gap is already listed in A5.
- **A t: start swapped to a FIFO between `inrepo_here` and the `<` read at :580:** this would hang the walk (fail-stop), and swapping a start for a symlink only changes S4 content. Not run.

## Endorsement Claims

- **Claim:** a main walk with no checkout tampering fails closed on an `@` import through a directory main stores as a symlink, both above an instruction basename and at the `.claude/rules` component.
  **Location:** `scripts/lib/dev-cycle-read.sh:612-614`
  **Evidence:** executed
  **Verified:** P1a and P1c returned `walk: failed`, with the targets answering imported through isimported's `|| return 0`.
  **Not verified:** the same shapes with an untracked start at the import path (Finding 1 shows they pass), and a gitlink parent (Finding 2).
  **route: code-fact-check**
- **Claim:** a checkout file whose own mode blocks reading fails the walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:580`
  **Evidence:** executed
  **Verified:** P2e, a mode-000 `sub/x.md`, gave `walk: failed`, with bash's "Permission denied" at :580.
  **Not verified:** a mode-000 parent directory (Finding 3: reads as absent).
  **route: code-fact-check**
- **Claim:** isimported main answers imported for every path after a failed walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:630`
  **Evidence:** executed
  **Verified:** every `walk: failed` probe (P1a, P1c, P2e and the patched runs) printed imported for each queried path.
  **Not verified:** a caller running under `set -e` that calls main_imports directly rather than through isimported (no caller exists yet; U2a4).
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction or traversal from repository data (S1-S5), reaching file reads or the floor's answer

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:580` `< "$f"` (t: read) | S2/S4 path, S4 content | `inrepo_here` (blocker plus `-f`) | cleared for links (blocker); Finding 3 for unsearchable parents |
| `:586` `git cat-file blob "$MAIN_SHA:$f"` | S1 | `ent` mode 100644/100755 | cleared: an object read, no filesystem traversal |
| `:589-590` cat-file of link text | S3 | NUL count, `x` sentinel | cleared |
| `:596-601` link-text split, `realpath -ms`, `-L` | S3, S5 | the `..`-after-link rule | Finding 4 (here-string; unmaterialisable) |
| `:602` `realpath -ms` of the link target | S3 | leaves-the-repo check :603 | cleared (lexical, so B4 is settled in row 371 for tokens) |
| `:612-615` main-lacks parent check | S1/S2 | 120000 parents only, after the seen test | Findings 1 and 2 |
| `import_targets` `realpath -ms` | S2/S4 tokens | `..`/`../*` drop | cleared for this unit (parser changes in U2a3b, stacked) |
| `:517` `git ls-files --others` | S5 | nul_list rc | Finding 3 (exit 0 with a warning) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | An untracked start pre-empts the parent-link refusal; non-start targets drop when the link is `.claude` or `.claude/rules` | Medium | B2 → B3 | `scripts/lib/dev-cycle-read.sh:571-572, :610-614` | High (behaviour) / Medium (reach) |
| 2 | An import into a gitlink path reads the checkout's submodule; an uninitialised worktree drops main-pinned imports | Medium | B5, B2 → B3 | `scripts/lib/dev-cycle-read.sh:612-615, :580-583` | High / Medium |
| 3 | An unsearchable dir or ls-files' exit-0 warning hides checkout content; only S4 is lost | Low | B2 → B3 | `scripts/lib/dev-cycle-read.sh:580-583, :517, :564` | High |
| 4 | The :596 here-string; link text ≥64 KiB cannot be checked out | Informational | B1 → B3 | `scripts/lib/dev-cycle-read.sh:596` | High |

## Overall Assessment

The walk fails closed on every shape that main's commit alone presents, among those probed. Two fail-opens remain where the gate's checkout removes an import that main's commit pins. Finding 1 needs a tampered checkout and a human-added directory link, and is not limited to start-shaped names. Finding 2 needs a human-added gitlink, and fires in the default state of a fresh `git worktree add`. Both are one-line, in-place fixes probed in patched copies: run the parent check before the seen test, and treat 160000 like 120000. Neither is architectural. The single most important change is Finding 1's reorder, because it restores the header's own invariant ("the checkout can only add imports or fail it"), which the floor's design relies on. Neither shape exists on this repo's main today (no 120000 or 160000 entries), and there is no caller until U2a4, so a reviewed Defer with U2a4 as the trigger is defensible if the claims are narrowed. Merging as is leaves those claims false. No findings beyond these within the code paths read; endorsement claims are pending execution verification by code-fact-check.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a3.md, structured per the security-reviewer skill.
- **Answered:** saved at that path. All four fact-check behavioural Incorrects were assessed for exploitability: the untracked start under a link is Finding 1, Medium, and wider than "start-shaped only"; the unsearchable directory and the ls-files warning are Finding 3, Low; the :596 here-string is Finding 4, Informational. One further fail-open was found and probed: Finding 2, the gitlink import. Each finding has Evidence, Severity, Confidence and Legibility-target. Settled rows: no settled row was re-raised. Finding 2 names rows 366 and 373 as related, with new evidence of a distinct shape. Row 252 (replace refs) was checked and left settled.
- **Out of scope:** the U2a3b parser and sed/grep/lower failure arms (stacked); Claude Code's own loader semantics (B4; no host probe); the c42f017f "read as no imports" commit wording (fact-check; needs an Accepted-immutable row); bats runs on the patched lib copies.
- **Escalate:** implementer, decide fix or Defer for Findings 1 and 2. If deferred, narrow the header :32-35, the block comment :463-466, A5 and F11, and add rows. Fact-check, take the routed Endorsement Claims. No HALT patterns matched.
