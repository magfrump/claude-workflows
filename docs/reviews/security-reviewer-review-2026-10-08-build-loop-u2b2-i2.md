Commit: 368a3194

# Security Review: feat/build-loop-u2b2 (U2b2, the gate's checkout), iteration 2

**Scope:** c10b972a..368a3194 (fix commits 639f7b40, 368a3194; d67966fe is review reports only): `scripts/build-loop.sh` (`callervar` 531, `gate_repo` 532-541, `checkout_gate` 626-690, `check_line` 697-753, header 102-157), `scripts/lib/dev-cycle-read.sh` contract item 3, `docs/working/` rows, `test/scripts/build-loop-check.bats` U2b2 tests. Whole enclosing functions read; probes run against the worktree's script.
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md (k=1: 26 claims, 16 Verified, 7 Mostly accurate, 3 Incorrect, all three about the documented order and fixed in 368a3194)
**Threat model:** Q-133 [3]. A hostile same-uid loop racing the gate is out of scope. In scope: honest-path correctness, fail-closed behaviour, and committed content or ordinary checkout state getting a self-merge brief past the gate.

No HALT escalation: no pattern from the escalation list matched.

## Trust Boundary Map

```
B1: [main's tree: names and modes (committed content)] → [ls-tree -z → LC_ALL=C bash =~ $re, mode case, name refusals → hash-object --stdin-paths] → [CHECKOUT_WHY]
B2: [checkout state: bytes, file types, dir perms, index flags] → [git status / ls-files -v / ls-files --others / ls -A / hash-object] → [CHECKOUT_WHY]
B3 (moved): [caller env: GIT_* repo-local vars, GIT_CONFIG, LC_ALL/LANG] → [callervar (shared with gate_repo); local -x LC_ALL=C] → [checkout_gate's reads and its children]
B4: [repo config core.symlinks / ignoreCase / sparseCheckout, incl. config.worktree] → [git config --type=bool --get, rc > 1 refuses] → [CHECKOUT_WHY]
B5 (moved): [CHECKOUT_WHY, now per self-merge brief inside check_line's subshell] → [co, printed in place of the verdict line] → [exit 2]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Names and modes in `$MAIN_SHA`'s tree | committed content (self-merge adds only pathform names; a review merge or old history can hold any bytes) | UNTRUSTED toward the bash regex, git's `--stdin-paths` line protocol and the `ls -A` lookup |
| S2 | Working-tree bytes, types, permissions, index bits | runtime-mutable (ordinary checkout state, user's global git config at checkout time) | UNTRUSTED for every read; it is what the gate judges |
| S3 | `.git/config` / `config.worktree` core.* keys | runtime-mutable | UNTRUSTED; read as a value, fail-closed on unreadable |
| S4 | Caller env (`GIT_CONFIG_PARAMETERS`/`COUNT` pairs, other `GIT_*`, locale) | caller session | Config pairs trusted by design (harden); every other repo-local var refused; locale now overridden inside checkout_gate |
| S5 | `MAIN_SHA`, `GATE_TMP` | derived after the state gates / mktemp | trusted |

The fixes move two boundaries: B3 now pins the locale for the function and its children and refuses `GIT_CONFIG` through the same `callervar` rule that gate_repo uses to unset it. B5 now runs per self-merge brief, after the merge's paths are read and before the N rules. The three iteration-1 assumptions (every record parses, every name reaches hash-object as itself, an `ls` failure means empty) are now each enforced or refused, and I re-tested each one by execution.

## Findings

No findings.

## Fix verification (iteration-1 findings; not re-raised)

- **F1 (`"q"` / `x\r` names):** `checkout_gate:680-681` refuses a name with a newline, a leading `"`, or a trailing CR before it reaches `--stdin-paths`. The branch's bats test covers `"q"` and `r\r`. The rule's exclusions match git's `strbuf_getline` + `unquote_c_style` behaviour as I traced it in iteration 1: only a *leading* quote is unquoted, and only a *trailing* CR is dropped.
- **F2 (locale):** `local -x LC_ALL=C` (629). Probe `locale`: main stores `d1/\xff.md` with `ident`. `--check` refused under `LC_ALL=C.utf8` and also under `LANG=C.utf8` with LC_ALL unset ("a file's checked-out bytes are not the default branch's blob"), exit 2. The default for an unmatched record is now a refusal (664, 676). Under C that branch cannot be reached (fact-check claim 24), so it only fails closed.
- **F3 (unlistable gitlink):** 671-674 refuse a symlink or an unlistable existing path. Probe `gl`: a dangling symlink at the gitlink path gives `git status` exit 128 ("expected submodule path 'sub' not to be a symbolic link"), and the gate refuses with "git status failed or warned". A regular file at the gitlink path gives status `T sub` and a refusal. A directory holding a `.git` file with an invalid gitdir makes git status fail, and the gate refuses. So the `-L` arm is defence in depth behind git status, as the test comment says.
- **GIT_CONFIG:** probe `prefix`: `GIT_CONFIG=` (set, empty) is refused ("GIT_CONFIG is set..."). `${!v+set}` treats set-but-empty as set. gate_repo (535) unsets it because `callervar` does not keep it. `GIT_PREFIX` is exempt, and the probe showed it does not change what `git status` reports from the top level.

## Untested bypass candidates

All the iteration-1 candidates are now tested (see Endorsement Claims and the cleared list below). Still untested:

- **A crafted tree with duplicate entry names** (for example `sub` as both a gitlink and a tree, which fsck rejects but a hand-built object can carry). Not probed: it can only reach main through a merge-tree result or history the gate already accepted, and its interaction with ls-tree's ordering needs a hand-built object.
- **The stderr-only half of the git status rule** (status exits 0 but warns). I found no input that triggers it on git 2.39 with `-uno` (fact-check claim 24 notes the mutant stays green). Not probed further, because the branch is fail-closed whichever way it fires.
- **Case-insensitive filesystem with `core.ignoreCase` false** (for example a WSL drvfs mount): one file can have several names. This is already listed open in A5, and no case-insensitive mount was available here.

Cleared by execution (recorded so they are not re-raised): a FIFO at a tracked path (status ` M`, refused, no hang); a tracked directory replaced by a symlink to identical copies (status ` D`, refused); a symlink checked out as a file under a global `core.symlinks=false` (status ` T`, refused); `core.ignoreCase`/`core.symlinks` in `config.worktree` under `extensions.worktreeConfig` (refused); an unreadable tracked file, with or without `core.trustctime=false` (status ` M`, refused); an unmerged index entry (ls-files `M`, refused); a stat-dirty file with unchanged bytes (ok, correctly); an untracked directory whose `.git` file names a missing gitdir (git lists its files as untracked, `n/CLAUDE.md`, so the walk sees them; ok is consistent with "untracked files are allowed, the walk reads them"); the same with a valid gitdir (listed as `n/`, refused); `core.fileMode=false` with an exec bit flipped (ok: exec bits are outside contract items 2-3 and do not change what a session reads).

## Endorsement Claims

- **Claim:** A smudge filter that only the user's global config defines (hidden from the gate's git by `GIT_CONFIG_GLOBAL=/dev/null`) and that rewrote a checked-out instruction file makes `--check` refuse a self-merge brief.
  **Location:** `scripts/build-loop.sh:652-654, 686-689`
  **Evidence:** executed
  **Verified:** probe `smudge`: `d1/CLAUDE.md filter=x`, checked out under a global `filter.x.smudge = sed s/ok/evil/`. The file read `see @docs/evil.md`. `--check` printed the checkout refusal (git status ` M`), exit 2, with and without the caller's `GIT_CONFIG_GLOBAL` pointing at that file.
  **Not verified:** a filter whose `clean` exactly inverts its smudge, so that git status *under the global config* would be clean. The gate's status runs without that config, and the hash comparison would catch it anyway, but this case was not executed.
  **route: code-fact-check**
- **Claim:** Under `LC_ALL=C.utf8` or `LANG=C.utf8`, a file main stores under a non-UTF-8 name is still byte-compared, and an ident expansion there refuses a self-merge brief.
  **Location:** `scripts/build-loop.sh:629-630, 663-683`
  **Evidence:** executed
  **Verified:** probe `locale` (both environments, exit 2 with the blob refusal). The branch's bats test runs the `LC_ALL=C.utf8` case.
  **Not verified:** `en_US.UTF-8` on a host where that locale is installed (here bash falls back to C with a setlocale warning). `local -x` overrides it the same way, but this was not executed.
  **route: code-fact-check**
- **Claim:** A FIFO, a symlinked parent directory, or a file-for-symlink at a path main tracks is refused by the git status rule before `hash-object` opens it, so `--check` does not block on a FIFO there.
  **Location:** `scripts/build-loop.sh:652-654`
  **Evidence:** executed
  **Verified:** probes `fifo`, `symparent` and `gsym`: each refused with "the checkout's index or tracked files differ from that commit (git status)", each within the 20 s timeout.
  **Not verified:** a FIFO at an *untracked* start path. That is the walk's concern (row 440, still open) and is not read by checkout_gate.
- **Claim:** `checkout_gate` runs for each self-merge brief, inside the `check_line` subshell, after `import_reset` and before any `nrules` call. A refusal it sets replaces the verdict line, and every exit path from check_line after that point prints a non-`ok` first line.
  **Location:** `scripts/build-loop.sh:699, 734-751`
  **Evidence:** read-static
  **Verified:** read check_line whole. The paths after line 734 are 735 (`${co:-ok...}`), 742 (blob refusal), 745 (lower-casing refusal) and 751 (`co` before nd/ok). Probes showed the refusal plus the path line, exit 2.
  **Not verified:** U2c's floor walk, which is not wired yet. Whether it runs after line 734 inside the same subshell is the next unit's hop.

## Primitive sweep

Primitive: process exec / filesystem lookup on repo-derived paths (checkout_gate)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:632` `git rev-parse --local-env-vars` | S4 | fixed list of names | cleared. If it failed, the loop would run zero times, but every later git call would also fail and refuse |
| `build-loop.sh:637` `git rev-parse --verify -q HEAD^{commit}` | S2 | compared to S5 | cleared |
| `build-loop.sh:641` `git config --type=bool --get` | S3 (key constants) | rc > 1 refuses | cleared (probe `wtcfg`) |
| `build-loop.sh:648` `ls-files -v -z \| tr \| awk` | S2 | pipefail, refuse on failure | cleared (probe `stderr`, unmerged) |
| `build-loop.sh:652` `git status ... 2>err` | S2 | output or stderr refuses | cleared (probes fifo, symparent, gsym, gl, smudge) |
| `build-loop.sh:659-660` `ls-files -z --others` to a file, then awk | S2 | failure refuses | cleared (probe `gitfile`) |
| `build-loop.sh:662` `ls-tree -r -z --full-tree` | S5 | failure refuses | cleared |
| `build-loop.sh:664` `[[ $r =~ $re ]]` | S1 | LC_ALL=C; no match refuses | cleared (F2 fix, probe `locale`) |
| `build-loop.sh:671` `ls -A -- PATH` | S1 + S2 | `--`; `-L` and failure refuse | cleared (F3 fix, probe `gl`) |
| `build-loop.sh:686` `git hash-object --no-filters --stdin-paths` | S1 names | newline / leading `"` / trailing CR refused | cleared (F1 fix, bats) |
| `build-loop.sh:535` gate_repo `env -u` list | S4 | `callervar` | cleared (GIT_CONFIG now unset) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| none | No findings | – | – | – | – |

## Overall Assessment

The iteration-1 fixes hold. I re-ran each of the three fail-open reproductions against 368a3194 and all three now refuse. None of the ten new bypass candidates I tried got a self-merge brief past the gate (FIFO, symlinked parent, file-for-symlink, dangling or file-typed gitlink, invalid `.git` file, worktree-scoped config, unreadable file, unmerged entry, global smudge filter, empty `GIT_CONFIG`). Git status turns out to be the first line of defence for most checkout-shape tricks, and the byte comparison and name refusals cover the conversions status cannot see. No findings within the code paths read. The endorsement claims marked `route: code-fact-check` are pending execution verification. What remains open is listed above: a case-insensitive filesystem with `core.ignoreCase` false (A5), a FIFO at an untracked start path (row 440, the walk's concern), and the race between the gate's check and U2c's read (Q-103 residual). The most important thing to carry forward is that U2c's walk must run in the same `check_line` subshell after line 734, so that the gate's verdict and the walk's read concern the same decision.

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2-i2.md (first line `Commit: 368a3194`), structured per the critic skill."

**Answered:** Iteration-2 security review of U2b2's fix delta under Q-133 [3]. All three iteration-1 Medium findings are verified fixed by execution, the GIT_CONFIG rule is verified, the iteration-1 untested candidates plus new ones were tested, and there are no new findings.

**Out of scope:** the same-uid race (Q-103 residual), the trust that harden places in the caller's config pairs, reader-model questions (U2b3), the walk's own FIFO start (row 440), and performance of the per-brief full-tree hash (the performance reviewer's area). Override-log rows 366/373, 387, 391/392/397, 399, 439, 440, 459/465 were not re-raised.

**Escalate:** none.

**Questions/Decisions:** none new. Last iteration's question, whether to export `LC_ALL=C` for the whole process, is now answered for checkout_gate by `local -x`. U2c's walk still needs its own guarantee under contract item 1.
