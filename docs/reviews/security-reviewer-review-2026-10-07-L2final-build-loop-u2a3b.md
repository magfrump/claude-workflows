Commit: e1654266

# Security Review: feat/build-loop-u2a3b, loop 2 final confirming pass

**Scope:** `main...e1654266` (full unit: scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, the two bats suites, known-issues A5, plan F11/U2a3c/U2b)
**Date:** 2026-10-07
**Based on:** Stage 1 summary (`code-fact-check-report-build-loop-u2a3b-L2-final-r{1,2,3}.md`), escalation E1 addressed to this reviewer; rubric sections "Loop 2, iteration 2 of 3" and "iteration 1 of 3"; override-log rows for `feat/build-loop-u2a3` and `feat/build-loop-u2a3b`.

Harness (executed): `/tmp/u2a3bsecfin-VTm8` (a `git archive e1654266` copy of `scripts/`, main's copy in `mainlib/`, a probe repo, and Claude Code 2.1.292 run headless (`claude -p hi`, its own `CLAUDE_CONFIG_DIR`, a dummy key, an `InstructionsLoaded` hook writing `il.jsonl`, stopped by `timeout 25`, rc 124 every run). Scripts: session scratchpad `u2a3bsecfin-setup.sh`, `u2a3bsecfin-ccprobe.sh`, `u2a3bsecfin-utf8.sh`, `u2a3bsecfin-approve.py`. No process is left running.

## Trust Boundary Map

```
B1: instruction-file text (checkout file / main blob; branch content after a merge) → import_targets (sed, UTF8_OK gate, python3, IMPORT_AWK) → IMPORTED / IMPORTED_MAIN → check_fix / floor decision
B2: process environment (HOME, else the passwd entry)                             → import_home → IMPORT_AWK emit's ~/ join → B1's name set
B3: checkout file system (nested .git, symlinks, untracked names)                  → main_imports' per-candidate checks (.git skip, parent loop, -d/-e) → walk ok / failed
B4: instruction files outside ROOT_REAL (ancestor CLAUDE.md, user memory)          → [no transition: never read by either walk]                    → Claude Code session instructions (gap, pre-existing)
```

| Source | Mutability | Trust classification |
|---|---|---|
| S1: text of repo instruction files and the files they name | runtime-mutable (any branch the loop writes; main after a self-merge) | UNTRUSTED toward the path-construction and decision sinks (put, -f, head, blocker, isimported) |
| S2: HOME / passwd home | deploy-time (process env) | trusted for availability; used as a path prefix, so a relative or empty value must fail or match Claude Code |
| S3: checkout state (nested `.git` files, symlinks, untracked files) | runtime-mutable by whoever writes the checkout | UNTRUSTED for the main walk's pass/fail decision; branch content cannot create a `.git` path through git checkout |
| S4: out-of-repo instruction files (`<ancestor>/CLAUDE.md`, `$CLAUDE_CONFIG_DIR`/`~/.claude/CLAUDE.md`) | user-edited, outside the repo | trusted content, but the in-repo files they import are S1 (loop-editable) |
| S5: IMPORT_OUT_MAX, IMPORT_LEFT, UTF8_OK, UNI_SPACES | code-constant (set at source time; env cannot override) | trusted |

What crosses: S1 text becomes path candidates that are resolved, filtered to below ROOT_REAL and recorded; S2 joins `~/` names; S3 decides whether the main walk fails. The unit's contract (superset claim) is per file, B1/B2; B4 is a walk-start gap outside both walks.

## Findings

#### F1. Instruction files outside the repo are not walk starts: an ancestor CLAUDE.md or the user's memory file imports an in-repo doc that --check-fix still prints `ok` for (E1)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh` imported_names (`nul_list recs tree_starts`), main_imports (start candidates from `git ls-tree` / `git ls-files`); the exception list in the comment above `import_targets` (~:516-523)
**Boundary:** B4 (S4 → S1)
**Move:** 1 (trace the trust boundaries), 5 (invert: what the start set does not cover)
**Confidence:** High on the mechanism (executed against the 2.1.292 binary); exposure today is nil in this environment (below)
**Legibility-target:** for-orchestrator-synthesis
**Evidence:** executed

Claude Code 2.1.292 loads `CLAUDE.md` from each ancestor of the session's cwd and the user memory file (`$CLAUDE_CONFIG_DIR/CLAUDE.md`, else `~/.claude/CLAUDE.md`), and follows their `@` imports into the project. Probe (`/tmp/u2a3bsecfin-VTm8`, external includes **not** approved, `hasClaudeMdExternalIncludesApproved` absent):

```
parent  $d/CLAUDE.md:      parent @repo/docs/f.md
user    $d/cfg/CLAUDE.md:  user mem @$d/repo/docs/g.md
→ "file_path":".../repo/docs/f.md","memory_type":"Project","load_reason":"include"
→ "file_path":".../repo/docs/g.md","memory_type":"User","load_reason":"include"
```

Both walks at e1654266 start only from ROOT_REAL's own files, so:

```
$ dev-cycle.sh --check-fix docs/g.md docs/f.md     # e1654266 and main 8f24e63a alike
ok docs/g.md
ok docs/f.md
```

So an in-cycle fix (or, from U2a4, a self-merge the floor admits) can rewrite a file that every later session reads as instructions. The targets are inside the project, so the "approved external includes" exception does not cover this: Claude Code needs approval only when the *target* is outside the project (executed below, endorsement C2). None of the five named exceptions, A5's "Not covered" list, or override row 56 (the reader set: other checkout, other HOME) names out-of-repo *importers*.

Answers to E1's questions:
- **A fail-open of this unit's contract?** Not of the parser's superset claim, which is per file ("these rules read every name Claude Code 2.1.292 can import" from the text given), and that holds here: the names `@repo/docs/f.md` and `@<abs>/docs/g.md` would be yielded if their files were read. It is a fail-open of the walks' contract that both callers rely on ("an in-cycle fix never edits a file an instruction file imports"; F11's floor), and the comment above `import_targets` presents itself as the one list of where "a session reading the file can import what these rules do not yield".
- **Pre-existing on main?** Yes, executed: main 8f24e63a prints the same two `ok` lines (it also dropped every absolute and `~/` name). Not a regression of this unit.
- **Exposure here:** none today. `~/.claude/CLAUDE.md` links to `/opt/claude-workflows/CLAUDE.md`, which holds no absolute or `~/` token (grep) and resolves relative tokens from `/opt/claude-workflows`; `/workspace` has no `CLAUDE.md`, `CLAUDE.local.md` or `.claude/CLAUDE.md`, so the worktrees nested under `/workspace/.claude/` have no ancestor file. AGENTS.md is not loaded by 2.1.292 (the probe's AGENTS.md-only run logged no load events), so `/workspace/AGENTS.md` is not an ancestor start.

**Recommendation:** Name it now and route the fix with the reader set. (1) Add a sixth exception to the statement above `import_targets` (or, since it is a start-set gap rather than a parse gap, a sentence in imported_names' and main_imports' "Not covered" lists and A5): "instruction files outside the repo: CLAUDE.md files in ROOT_REAL's ancestors and the user's memory file (`$CLAUDE_CONFIG_DIR` or `~/.claude`), whose imports into the repo neither walk reads." (2) Extend override row 56 / plan step 5's U2b bullet: the reader set includes the out-of-repo starts. A fix would read those files (capped at 4 MiB like the tree walk), parse each with an absolute `IT_DIR` (`put` today prefixes `root "/" dir`, so it needs a branch for an absolute dir), follow regular files outside the repo without recording them, record only names below ROOT_REAL, charge everything to IMPORT_OUT_MAX, and fail closed on an unreadable start. For the gate this is host state, not main's commit, so it belongs with U2b's checkout/session decision. Untested start kinds to include in that work: ancestor `CLAUDE.local.md` and `.claude/CLAUDE.md`, `~/.claude/rules/`, the managed policy file, `--add-dir` directories.

#### F2. The nested `*/.git` skip lets a regular `.git` file's imports pass the main walk; the safe direction is the mutant (top-level skip only)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:759` (main_imports)
**Boundary:** B3
**Move:** 11 (bypasses for every guardrail), 3 (error path)
**Confidence:** High on the mechanism; reachability needs host control of the gate checkout
**Legibility-target:** for-author
**Evidence:** executed

```
      [[ "$p" != .git && "$p" != */.git ]] || continue
      # Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail.
```

Probe: untracked plain directory `n/` holding a regular file `n/.git` with `nested @../docs/e.md`; `CLAUDE.md` adds `nested gitfile @n/.git`. Claude Code 2.1.292 loads `n/.git` (`load_reason: include`) and then `docs/e.md`. At HEAD: tree walk ok, `docs/e.md: imported` (it reads the file); main walk **ok, `docs/e.md: -`**. Mutant `[[ "$p" != .git ]] || continue`: main walk **failed**. So r1's non-equivalent mutant is the fail-closed direction; HEAD trades it for availability (r1's nested linked worktree, whose `.git` is a gitfile). Until U2a3c the main walk fails on any other file the checkout holds and main lacks; the skip is the one exemption, and it covers files, not only the directory git uses.

Why Low: branch content cannot create the file. git refuses to check out a path with a `.git` component, and the `.git` files git itself writes (linked worktree, absorbed submodule) hold a single `gitdir: <path>` line. Claude Code's regex needs whitespace or line start before `@`, so such a file imports something only if that path holds whitespace followed by `@`. The gate's checkout (U2b: a fresh worktree at MAIN_SHA) holds no nested `.git` unless someone with host access makes one, which falls below the floor rule's reachable-environment bar.

Bypass candidates tested against the skip:
- `@lnk/.git` where `lnk` is a symlink main stores: **cannot hide.** Every prefix is a candidate, and `lnk/.g` reaches the parent loop first, so the main walk failed (executed).
- An untracked checkout symlink `cl -> docs` with `@cl/.git`: the prefix `cl` fails the `-d && ! -L` check before `.git` is reached (traced).
- `@sub/.git` under a gitlink: `sub/.g` fails the parent loop (`^1[26]0000$`), same argument (traced).

**Recommendation:** Skip a nested `.git` only when it is a directory (`[[ ( "$p" == .git || "$p" == */.git ) && -d "$p" && ! -L "$p" ]] && continue`, keeping the top-level `.git` skip unconditional), or a regular file whose whole content is one `gitdir: ` line with no whitespace-`@`. Otherwise carry the rule to U2a3c: phase 2 must walk a nested `.git` regular file as it walks any checkout file main lacks, and must not inherit this `continue`. Also correct the comment: "a checkout file or directory git never stores" is true, but a file there can still be read as an import. Note for U2b: the gate worktree's path is copied into its top-level `.git` gitfile, so it should not contain whitespace followed by `@`.

#### F3. The walk caches are keyed on ROOT_REAL (and main's commit), not on HOME

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh` imported_names (`[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]]`), main_imports (`IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`), import_home's comment ("it recomputes only when HOME changes")
**Boundary:** B2
**Move:** 4 (TOCTOU: the check is cached)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** executed

In one shell: `HOME=/nonexist; imported_names` gives `docs/h.md: -`; after `HOME="$ROOT_REAL"`, `imported_names` gives `-` from the cache, while the first `main_imports` and a fresh tree walk (`IMPORTED_DONE=""`) give `imported`. import_home recomputes, but the walk results do not. No caller in `scripts/`, `hooks/` or `skills/` changes HOME between walks (git grep), so this is the class of override row 3 (the cache ignores the checkout; deferred because no caller exists), and that premise still holds.

**Recommendation:** Add HOME to the sentence that already tells a caller changing IMPORT_OUT_MAX to clear IMPORTED_DONE and IMPORTED_MAIN_DONE. Or put `$IMPORT_HOME_KEY` into both keys (after calling import_home before the cache check).

## Untested bypass candidates

- A HOME holding a newline or a `~` component: not run. It reaches awk through ENVIRON and `put` splits on `/` only, so the expected result is an over-read.
- Ancestor `CLAUDE.local.md`, ancestor `.claude/CLAUDE.md`, `~/.claude/rules/*.md`, `/etc/claude-code/CLAUDE.md` and `--add-dir` as F1 starts: not probed. Each would widen F1, not change it.
- A file swapped for a symlink or FIFO between imported_names' `inrepo_here "$p"` and the later `head -c` (TOCTOU). Needs concurrent write access to the checkout (host control). This check-then-read pattern predates the unit.
- A relative name entering another checkout through its directory (`@../wtB/docs/x.md`, Stage 1 "Mostly accurate", r3 executed): this belongs to the "another checkout" exception's family, but that exception names only absolute names. Left to fact-check's wording item; not re-run here.

## Endorsement Claims

- **Claim:** For HOME empty or unset, import_home's passwd reading matches what Claude Code 2.1.292 does, and a relative HOME makes the walk fail rather than miss.
  **Location:** `scripts/lib/dev-cycle-read.sh:603-610` (import_home), IMPORT_AWK emit (`if (substr(home, 1, 1) != "/") exit 4`)
  **Evidence:** executed
  **Verified:** In the probe repo, with `@~/docs/h.md` and repo `docs/h.md`: under HOME="" and HOME unset the binary did not load `repo/docs/h.md`, and `--check-fix docs/h.md` printed `ok`, which agrees. Under HOME="." the binary loaded `docs/h.md` (`"file_path":"docs/h.md"`, include), and `--check-fix` printed "the instruction-file import walk failed" (refuses). Under HOME=`$d/repo`, both load it and the fresh walk records it.
  **Not verified:** a HOME whose passwd entry is missing (getent fails, so h="" and a `~/` name fails the walk; traced, not run); the code comment's attribution to Node (Stage 1 Incorrect; Bun is the runtime).
  **route: code-fact-check**

- **Claim:** A name that re-enters the repo through a symlink *outside* it (absolute, `../alias/...`, `~/link/...`) is an external include: Claude Code 2.1.292 loads it only after the project approves external includes. It therefore falls under the named exception, not outside it.
  **Location:** comment above `import_targets` ("Claude Code's approved external includes")
  **Evidence:** executed
  **Verified:** `@$d/alias/docs/a.md`, `@../alias/docs/b.md` and `@~/hl/docs/c.md` (alias and `hm/hl` both link to the repo): not loaded with approval absent; all three loaded after setting `hasClaudeMdExternalIncludesApproved: true` in the probe's own config. Both walks yield none of them (`docs/a.md: -` and so on). All 25 projects in this host's config have the flag false.
  **Not verified:** whether approval can be granted by anything but the interactive prompt (for example a settings key a branch could commit).
  **route: code-fact-check**

- **Claim:** The UTF8_OK gate under this host's awk (mawk) agrees with python3's strict decoding on overlongs, surrogates, code points past U+10FFFF, truncated, lone-continuation, 0xFE/0xFF and 5-byte sequences, and on lines of 100 KB, 1 MB and 4 MiB with an invalid byte at the end or in the middle. So no tested invalid sequence skips the python3 decode.
  **Location:** `scripts/lib/dev-cycle-read.sh` UTF8_OK and import_targets' gate line
  **Evidence:** executed
  **Verified:** `u2a3bsecfin-utf8.sh`: 38 cases, 0 disagreements. Also traced: the sed step runs before the decode, and a UNI_SPACES replacement starts at a lead byte (C2/E1/E2/E3/EF), which a UTF-8 decoder never takes as a continuation, so decoding the sed output gives the same names as decoding the file.
  **Not verified:** gawk or busybox awk (another host's `awk`); random fuzz beyond Stage 1's 30,000-50,000 cases.
  **route: code-fact-check**

- **Claim:** A symlink or gitlink parent cannot hide behind the `.git` skip in main_imports, because every prefix of the token is checked first.
  **Location:** `scripts/lib/dev-cycle-read.sh:759-762`
  **Evidence:** executed
  **Verified:** `@lnk/.git` with `lnk -> docs` stored on main: main walk failed (through the prefix `lnk/.g`).
  **Not verified:** a token whose every prefix between the link and `.git` normalizes to the link itself or to a path main stores (none found by tracing `./`, `../` and splice forms).
  **route: code-fact-check**

- **Claim:** Each early stop (awk `exit 3` at IMPORT_LEFT or at the 50M work bound, `exit 4` on a relative home, `exit 2` on an empty root, a sed or python3 failure) reaches every caller as a walk failure, and every caller answers "imported" or refuses on that failure.
  **Location:** import_targets (`|| return 1`), imported_names:669/671, main_imports:726/748, isimported:777-778, `scripts/dev-cycle.sh:181`
  **Evidence:** read-static (callers found by git grep over scripts/hooks/skills at e1654266: check_fix, isimported, the two walks)
  **Verified:** each call site captures the status (`out="$(...)" || { ...=error; return 1; }`) with pipefail set by the walk; check_fix tests `imported_names` under `elif !` before `isimported tree`; isimported maps a walk failure to 0 (imported).
  **Not verified:** U2a4's floor, which has not been written yet; it must call `isimported main` or `main_imports` under `if`.

## Primitive sweep

Primitive: path construction from S1 names (path join / traversal)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| IMPORT_AWK `put` (absolute join, `..` clamp at /, kept only below `pre`) | S1, S2 | lexical normalize, prefix test | cleared: only names below ROOT_REAL are printed; symlinks outside resolve as external includes (endorsement C2) |
| imported_names `[[ -f "$p" ]] && inrepo_here "$p"` then `head -c 4194305 -- "$f"` | S1 | blocker (no non-plain part), `--` | cleared; TOCTOU listed as untested (needs host control) |
| main_imports parent loop, `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]]` | S1, S3 | ent modes, blocker | F2 (the `.git` skip ahead of it) |
| main_imports symlink arm `realpath -ms` | main blob text (S1) | empty/newline/NUL/absolute/`..`-after-link refusals | cleared (U2a3, unchanged here) |

Primitive: process exec fed data
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `sed "${s[@]}"` | S1 on stdin; expressions from S5 | constant program | cleared |
| `awk -v ok="$UTF8_OK"` | S1 on stdin | constant program | cleared (C3) |
| `python3 -I -c '...decode("utf-8","replace")...'` | S1 on stdin | `-I` (no cwd on sys.path), constant code, status checked | cleared |
| `awk "$IMPORT_AWK"` with IT_DIR/IT_ROOT/IT_HOME/IT_HOMER/IT_LEFT via ENVIRON | S1, S2, S5 | ENVIRON (no `-v` escape processing) | cleared |
| `getent passwd "$(id -u)"`, `realpath -m -- "$h"` | S2 | `--`, `/`-prefix test | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Out-of-repo instruction files (ancestor CLAUDE.md, user memory) are not walk starts; their in-repo imports print `ok` (E1; pre-existing on main) | Medium | B4 | dev-cycle-read.sh imported_names / main_imports starts; exception list ~:516-523 | High (executed; no current exposure here) |
| F2 | Nested `*/.git` skip passes a regular `.git` file's imports in the main walk; the top-level-only mutant is the fail-closed direction | Low | B3 | dev-cycle-read.sh:759 | High (executed; needs host control) |
| F3 | Walk caches ignore HOME (import_home recomputes, the walks do not) | Informational | B2 | imported_names / main_imports cache keys | High (executed; no caller) |

## Overall Assessment

I found no fail-open inside the parser's own contract. The `~/` handling (empty, unset, relative, symlinked HOME), the UTF-8 gate and the early stops behave as stated: the first two were executed against the 2.1.292 binary and python3, and the early stops fail closed in every current caller (read-static). Names that re-enter through an outside symlink fall under the named external-includes exception (executed). The fixes from loop 2 iteration 2 that I re-exercised still hold: `~/` names into the repo are now recorded, and a link parent cannot hide behind the `.git` skip. The one remaining Medium is E1 (F1): out-of-repo importers are a start-set gap. It predates this unit (main behaves identically) and is in the same session-environment family as the reader set already routed to U2b, but no exception, A5 entry or override row names it. The most important thing to address before merge is naming it: one sentence in the exception statement or A5, and an extension of the U2b routing. The fix itself does not need to land in this unit. F2 is a narrow hardening (skip a nested `.git` only when it is a directory) or a U2a3c carry. I see no architectural problem. No findings block the parser within the code paths read; the endorsement claims are executed except the early-stop claim, which is read-static with its next hop named.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:** remaining fail-opens outside the five exceptions (F1 only; outside-symlink aliases fall under the external-includes exception, executed); E1 (contract, fix sketch, named-exception wording, pre-existing on main, executed); `~/` handling (empty, unset, relative, symlink via the binary; caching across walks and HOME changes = F3); the nested `.git` skip (crafted names cannot hide a link parent; a regular nested `.git` file can hide its imports; the mutant is the safe direction = F2); the IMPORT_LEFT/IMPORT_OUT_MAX stop (fail-closed in every current caller, read-static); the UTF8_OK gate (no accepted invalid sequence among 38 edge and long-line cases under mawk).
- **Out of scope:** Stage 1's wording items (the Node attribution, stale test comments, commit-message mutant claims), left to fact-check and the author; U2a4's future floor caller.
- **Escalate:** F1, for the orchestrator to decide between naming it in this unit and routing the fix to U2b (my recommendation) or fixing it here.
- **Questions I would have asked:** Should the out-of-repo starts be read from the gate host's own user-memory file (`$CLAUDE_CONFIG_DIR`), or from the user's? They can differ when the loop runs under its own config dir.
- **Decisions I made:** I rated F1 Medium under the floor rule (a named mechanism, executed; the environmental unlikelihood is recorded in Confidence) while noting that the exposure today is nil. I rated F2 Low because only host-level control of the gate checkout can create the file. I named prior harnesses but built a fresh one (`/tmp/u2a3bsecfin-VTm8`), since the r3 probe script was not kept in its logs path.
