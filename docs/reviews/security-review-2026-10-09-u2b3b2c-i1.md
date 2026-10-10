Commit: f7e1bea2

# Security Review — feat/build-loop-u2b3b2c (iteration 1)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD f7e1bea2): `scripts/lib/dev-cycle-read.sh` (import_readers, root_copies, with_at, outside_proj, import_outside, outside_seeds, imported_names, main_imports, and the doc comments above them), `test/scripts/build-loop-check.bats` (three new tests plus the C1 test); `scripts/build-loop.sh` checkout_gate read for contract item 2.
**Date:** 2026-10-09
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b3b2c-i1.md (k=1; 26 claims, 18 Verified), the orchestrator's critic-shared brief.

## Trust Boundary Map

```
B1: [other reader root's file tree (a loop's own worktree)] → [root_copies: outside_ok / -L / realpath + sha1sum vs ROOT_REAL] → [walk queue (import_outside)]   (new)
B2: [dangling link in another root or a config dir]         → [seed loop / root_copies // branch → outside_proj realpath -m] → [projected repo names]   (new)
B3: [ROOT_REAL checkout (the gate's clean worktree)]        → [rawfile-equivalent test, sha1sum] → [byte-equal skip of a copy; C1 skip]   (moved: C1's byte check now lives in root_copies)
B4: [worktree registry (shared common dir)]                 → [import_readers realpath, -d] → [IMPORT_OTHER]   (new global)
B5: [repo text / outside file text]                         → [import_targets parser] → [names nm → root_copies]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | another registered worktree's files (names, bytes, links, directory links) | runtime-mutable (any loop writes its own worktree at any time, including mid-walk) | UNTRUSTED for the floor's import set (path/kind decisions) and for availability (it can fail or stall the walks) |
| S2 | config-dir and C1 seeds that are dangling links | runtime-mutable (user config; a loop's worktree) | UNTRUSTED for path/kind decisions |
| S3 | ROOT_REAL checkout file bytes | deploy-time per decision (contract item 2: clean at MAIN_SHA, hashed to main's blobs by checkout_gate) | trusted for the byte-equal comparison only under item 2; untrusted otherwise (tree walk outside the gate) |
| S4 | worktree registry | runtime-mutable (shared common dir; Q-103 residual) | UNTRUSTED for root completeness (pre-existing, not changed here) |
| S5 | parser output names (repo-relative / `//` absolute) | derived from S1/S3 text | UNTRUSTED for path construction; the parser normalizes and routes names leaving every root to the `//` channel, so `"$r/$p"` joins a repo-relative name |

What crosses: S1 now feeds the walk for every repo name a walk reaches, not just start files; the decision "this copy needs no read" is a byte comparison against S3 plus a final-component `-L` test. The diff assumes (a) a copy whose bytes equal ROOT_REAL's yields the same names, and (b) a dangling link's target is read as a plain import. Both assumptions have a gap (Findings 1 and 2).

## Findings

#### 1. A dangling prompt link loses its prompt kind: names it resolves against the session's top level are missed

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1504`, `:1595` (seed loops), `:1262` (root_copies' `//` branch), `outside_proj` `:1211-1223`
**Boundary:** B2
**Move:** 11 (bypass enumeration on the new `//PATH` seed guardrail), executed
**Confidence:** Medium (executed; exploit needs a dangling prompt link whose target later appears, the same future-state model U2b3b2b final security F1 accepted)

**Evidence:**
```
    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* || "$p" == //* ]] || pdir[$p]="$(lower "$p")" || return 1
```
```
      elif [[ -L "$r/$p" ]]; then rc_q+=("/$r/$p"); fi
```
(`:1504`; `:1595` is the same test in main_imports. The second excerpt is one branch of root_copies' inner loop, which ends with `done` on the next lines; the rest of root_copies compares the plain copies.)

A seed of kind `p` (a command, agent, output style or skill) that is a dangling link joins the queue as `//PATH` with no `pdir` entry. outside_proj then projects its real path as an ordinary repo name, which the walk reads against its own directory only. A live link of the same kind is read through import_outside with prompt_bases (the session's top level), so its relative names are followed. Probe P3 (throwaway repo plus a `side` worktree): `side/.claude/commands/k.md -> ../../docs/t.md`, with main's `docs/t.md` holding `@top.md`. While side holds `docs/t.md` (a live link), both walks answer `top.md: imported`. Once side lacks it (a dangling link), both walks answer `top.md: -` and only `docs/top.md: imported`. A self-merge editing `top.md` passes the floor. When the link's target appears (side merges main), the command loads `top.md` as instructions. root_copies' `//` branch drops the kind of a copy of a `pdir` name the same way, and so does a dangling `~/.claude/commands` link.

**Recommendation:** Carry the kind across the projection: when a `//` entry came from a `p` seed or from a copy of a `pdir` name, mark each repo name its projection yields as a prompt (`pdir[name]=lower(name)`; prompt_bases then adds the top level). Add P3 as a test for both walks.

#### 2. A byte-equal copy reached through a linked directory in another root is skipped, losing its real-path projection

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1261`, `:1266-1271` (root_copies)
**Boundary:** B1, B3
**Move:** 11, 4 (executed)
**Confidence:** Medium (executed; reachable when a reader root holds a directory link its tree differs from main's by, e.g. a user-made link in the main worktree or one a loop plants in its own worktree)

**Evidence:**
```
        if [[ -L "$r/$p" ]]; then rc_q+=("$r/$p"); else ps+=("$p"); cs+=("$r/$p"); fi
```
```
    if [[ -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" ]]; then sp+=("${cs[i]}"); hs+=("${cs[i]}" "${ps[i]}"); else rc_q+=("${cs[i]}"); fi
```
(The second line is the body of root_copies' realpath loop. The function goes on to sha1sum `hs` and queues each `sp` copy whose hash differs, up to its closing `}`.)

The `-L` test checks only the copy's last component, and the realpath test checks ROOT_REAL's side only. A copy below a live directory link in another root (`side/docs -> alt`) is compared by bytes and, when the bytes are equal, never read. import_outside would read such a copy and also project its real path (`alt/a.md`) as an import. The same copy reached through a file link (`side/docs/a.md -> ../alt/a.md`), or through the directory link with other bytes, is read and projected. Probe P2: with the directory link and equal bytes, both walks answer `alt/a.md: -`. With the file link, both answer `alt/a.md: imported`. A branch editing `alt/a.md` then passes the floor, though once the branch lands in that root, sessions there load it through `docs/a.md`. The skip has the same gap when a copy is swapped from a plain file to a link between the `-L` test and sha1sum. The doc comment names only a copy below a *dangling* linked directory (A5) as not covered.

**Recommendation:** Apply rawfile's test to the copy as well: skip only when `realpath -m` of `ROOT/NAME` equals `ROOT/NAME` (one more batched realpath over `cs`). Otherwise queue the copy, so import_outside projects it. If you keep the skip instead, add this case to the named exceptions next to A5.

#### 3. root_copies' realpath call is not batched, so many existing copies fail every walk (fail-closed)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1266`
**Boundary:** B1
**Move:** 8
**Confidence:** Low (read-static, not executed)

**Evidence:**
```
  nul_list rl realpath -mz -- "${ps[@]}" && [[ ${#rl[@]} -eq ${#ps[@]} ]] || return 1
```
(The next line starts the comparison loop over `ps`.)

`ps` holds one entry per existing copy (names times roots). Its siblings, sha1sum two lines below and with_at, go through `xargs` to avoid an argument list that is too long; this call does not (ARG_MAX here is 2097152). A loop that writes tens of thousands of imported files into its own worktree can make realpath fail with E2BIG, which fails every walk. This is the accepted fail-closed class (i1 security F3: one loop's worktree can hold every self-merge back), and the work budget may fail first. It is listed for consistency, not as a new exposure.

**Recommendation:** Run the realpath through `xargs -0r -a` as the sha1sum call does, or accept it under the existing fail-closed note.

#### 4. The new guardrail branches lack tests that fail without them

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:761-776`
**Boundary:** B1, B2
**Move:** 11
**Confidence:** High (executed)

**Evidence:**
```
    # side's docs/a.md differs; side alone holds docs/n.md; its docs/b.md is a link to a file side lacks.
```
(A comment inside the first new U2b3b2c test, which goes on to write side's files and run both walks through line 776.)

Per fact-check, side's `docs/b.md` is a live link, so the `//ROOT/NAME` branch is never exercised, and the byte-equal skip check never reaches the copy it claims to test. Probe P1 and its mutant: side's `docs/b.md -> gone.md` with side lacking `docs/gone.md`. The branch as written gives `docs/gone.md: imported` in both walks. With the `elif` deleted, both answer `docs/gone.md: -`. So the branch is load-bearing and untested.

**Recommendation:** Add P1 (delete side's `docs/gone.md`) and P2's link-file and directory-link pair as tests.

## Untested bypass candidates

- A sparse multi-GB copy whose bytes sha1sum reads in full: this stalls every walk (fail-closed, availability only). Not run, to avoid disk and CPU load. Same class as the documented FIFO stall.
- A root that is a bind-mount alias of ROOT_REAL (a different real path, the same files): it lands in IMPORT_OTHER, and its copies compare equal. Expected harmless (over-read at most). Not run, because it needs mount privileges.
- A race that deletes or chmods a copy between outside_ok and sha1sum: it fails the walk. Traced, not executed. This is the documented fail-closed class.
- Names holding `..` components reaching `"$r/$p"`: traced to the parser's normalization (the existing U2a2 test resolves `gone/../docs/m.md`). Not probed against root_copies directly.

## Endorsement Claims

- **Claim:** root_copies' `//ROOT/NAME` branch makes both walks protect the repo path a dangling copy in another root names.
  **Location:** `scripts/lib/dev-cycle-read.sh:1262`
  **Evidence:** executed
  **Verified:** Probe P1 gave `docs/gone.md: imported` (tree and main). The mutant lib without the branch gave `docs/gone.md: -` in both walks.
  **Not verified:** a dangling copy whose target lies below a nested root reached only through IMPORT_DOTNEST.
  **route: code-fact-check**
- **Claim:** A copy whose bytes differ, or a name ROOT_REAL lacks, is read through chains in another root, and a prompt name's copy is read with prompt bases.
  **Location:** `scripts/lib/dev-cycle-read.sh:1252-1273`
  **Evidence:** executed (the branch's bats test, run green per fact-check; P2's control row)
  **Verified:** test at `build-loop-check.bats:761`, and P2's file-link row (`alt/a.md: imported`).
  **Not verified:** copies in a root nested below a `.claude/skills/` directory (C1 seeds those as `p`; root_copies keys the kind on ROOT_REAL's name).
  **route: code-fact-check**
- **Claim:** Under checkout_gate, every start file ROOT_REAL holds as a plain file is a walk start, so C1's skip (now with no byte check) hands each such name to root_copies.
  **Location:** `scripts/lib/dev-cycle-read.sh:1388`; `scripts/build-loop.sh:635-637`
  **Evidence:** read-static
  **Verified:** checkout_gate lists `git ls-files --others` without `--exclude-standard` (ignored files included) and refuses any nested repository (a trailing `/`). It also refuses a gitlink checked out with files. The fact-check executed the C1 skip sentence for both walks under item 2.
  **Not verified:** the tree walk outside the gate, where an untracked or ignored nested repository's start would be skipped by C1 and never compared (named exception: "a checkout that is not clean").
  **route: code-fact-check**
- **Claim:** A failed comparison (an unreadable ROOT_REAL file, or a sha1sum failure) fails both walks rather than skipping the copy.
  **Location:** `scripts/lib/dev-cycle-read.sh:1266`, `:1270`
  **Evidence:** executed (the branch's test at `build-loop-check.bats:789`, green per fact-check)
  **Verified:** mode 000 on `docs/a.md` and a failing `sha1sum` shim each give `walk failed` in both walks.
  **Not verified:** a realpath failure (E2BIG: Finding 3).

## Primitive sweep

Primitive: path construction plus file read and hash (outside reads, `realpath`, `sha1sum` over paths built from S1/S5)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1260` `outside_ok "$r/$p"` | S4 root, S5 name | `p` not absolute or `//`; r has no newline (import_readers) | cleared: repo-relative join |
| `:1261-1262` `-L "$r/$p"` → queue | S1 | final-component test only | Finding 2 (directory link); Finding 1 (kind of the `//` branch) |
| `:1266` `realpath -mz -- "${ps[@]}"` | S5 | `--` | cleared for injection; Finding 3 (unbatched) |
| `:1270` `xargs ... sha1sum -z --` | S1, S3 | `--`, xargs batching | cleared; TOCTOU to the read is point-in-time (documented) |
| `:1260` `lower "$r/$p"` | S4, S5 | none needed (printf to tr) | cleared |
| `:1504` / `:1595` seed `-L "$p"` → `//PATH` | S2 | outside_ok, then `-L` | Finding 1 |
| `:1211-1223` outside_proj `realpath -mz` + whole projection | S1, S2 | newline check, work budget | cleared for paths; Finding 1 for kind |
| `:1197` import_file → import_outside (`realpath -ez`, capped_read) | S1 | `realpath -e`, 4 MiB cap, budget | cleared (pre-existing; the copy is read as it is at read time, documented) |
| `:1388` C1 `rawfile "${ir[i]}"` | S3 | rawfile | cleared under contract item 2 (Endorsement 3) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | A dangling prompt link loses its prompt kind; session-relative names missed | Medium | B2 | `dev-cycle-read.sh:1504,1595,1262` | Medium |
| 2 | A byte-equal copy below a linked directory is skipped; real-path projection lost | Medium | B1, B3 | `dev-cycle-read.sh:1261,1268` | Medium |
| 3 | root_copies' realpath not batched (E2BIG fails every walk) | Informational | B1 | `dev-cycle-read.sh:1266` | Low |
| 4 | Dangling branch and byte-equal skip have no tests that fail without them | Informational | B1, B2 | `build-loop-check.bats:761-776` | High |

## Overall Assessment

The unit closes the i1 F1 gap: in probes and the branch's own tests, both walks read other roots' copies of every reached name when the bytes differ or this checkout lacks the name, and they fail closed when a comparison cannot run. Moving C1's byte check into root_copies is sound under checkout_gate's clean checkout, which refuses nested repositories, so every start the skip relies on is queued. Two fail-open edges remain, and both were confirmed by execution. Each is a missing projection detail that can be fixed in place, not an architectural problem:

- **Finding 1:** a dangling prompt link is projected as a plain import, so names it resolves against the session's top level are missed.
- **Finding 2:** the byte-equal skip ignores a directory link in the copy's path, which drops the copy's real-path projection.

No new fail-closed class was found: a hostile worktree could already fail or stall every walk (i1 security F3). The most important fix is Finding 1, which re-opens part of the gap U2b3b2b final security F1 targeted for prompt seeds. No findings remain beyond these within the code paths read. Endorsement 3 awaits execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/security-review-2026-10-09-u2b3b2c-i1.md, structured per the security-reviewer skill, with `Commit: f7e1bea2` as its first line."
- **Answered:** the fail-open paths in the brief's focus list:
  - Answered with a finding: kind mismatches and dangling `//PATH` seeds and copies (F1); copies below a linked directory (F2).
  - Cleared: absolute and `//` names, CMP dedupe ordering, projection-only names, names ROOT_REAL holds as a link, the main walk's comparison with the checkout under item 2, and the C1 skip's reliance on root_copies.
  - Fail-closed regressions: F3 only, same class as before. TOCTOU: point-in-time only, as documented.
- **Out of scope:** the stale doc lines and the dev-cycle.bats sourcing inventory (fact-check escalation), and the prior override rows 580-589.
- **Escalate:** none at HALT level. F1 and F2 are Medium fail-opens for the review-fix loop.
