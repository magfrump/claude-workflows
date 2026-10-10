Commit: a27f93b6

# Security Review — feat/build-loop-u3a1, confirming pass on the final pass's fix (d10cfba8..a27f93b6)

**Scope:** `git diff d10cfba8..a27f93b6` without docs/reviews (`scripts/build-loop.sh` store_check, gate_start and comments; `test/scripts/build-loop-check.bats` second-copy case; plan step 7 note). The rest of the branch was reviewed in iterations 1-3 and is used here as context only.
**Date:** 2026-10-10
**Based on:** final-pass security report `security-reviewer-review-2026-10-10-build-loop-u3a1-final.md` (F1 High, newline-named pack) and its probes `scratchpad/u3a1-f/security/probes/` (`nl.sh`, `idxswap.py`).

**Method:** executed. I wrote two probes under `scratchpad/u3a1-c/security/probes/`: `names.sh` (log `names.log`, 35 cases, a fresh throwaway repo per case) and `mainflag.sh` (log `mainflag.log`, store_check extracted verbatim from HEAD). Both ran against the worktree's `scripts/build-loop.sh` at a27f93b6, with git 2.39.5 and GNU find 4.9.0 (`/usr/bin/find`, the one the script resolves). Both follow the brief's probe-safety rule: `set -eu`, mktemp in the same script, and a pwd guard before `git init`. Every gate run went under `timeout`, and no probe process is left running. I also ran the new bats case at HEAD: `ok 1 --check's second-copy scan lists what git opens: ...`.

**Bottom line:** F1 is closed. A same-uid writer acting before the run did not get an `ok` verdict on unverified bytes through any name shape or file type I tried. Every case where plain git reads the forged copy was refused (`refuse state objects`). The cases where git cannot use the forged pack either fail the run before any verdict or hang, and they hang in git just the same. `--main` fails closed as claimed. **No findings.**

---

## Trust Boundary Map

```
B1: .git/objects/pack entries (any name, any file type) → store_check listing (find -L ... -print0 | read -d '') → per-id copy count → "one copy" trusted
B2: .git/objects (git's readdir of pack/*.idx, packs before loose, MRU) → cat-file --batch + perl re-hash → $GATE_TMP/main, $GATE_TMP/call
B3: .git/objects (same store, other git processes) → brief_fields / own_blob / checkout_gate / gate_git reads → verdict
B4: $GATE_TMP/main (skip list, written by store_check --main) → later per-brief store_check calls (skip + second-copy judging) (changed)
```

```
S1: pack dir and fan-out entry names and types — runtime-mutable (same-uid writer) — UNTRUSTED toward the listing sink
S2: pack .idx/.pack and loose object bytes    — runtime-mutable                   — UNTRUSTED toward verdict-integrity sinks
S3: $GATE_TMP contents                        — written by this run (mktemp -d)   — trusted toward the skip list (no pre-run writer can name it)
S4: caller environment (locale, fds, GIT_*)   — deploy/invocation-time            — trusted by design (prior passes); locale probed anyway
```

The invariant is unchanged from the final pass: B1's list of copies must cover every copy git can reach in B2/B3. The fix makes B1 NUL-delimited. B4 is new state flow. A skip list that is missing or empty must never let a non-main call skip anything, and a failed `--main` must leave nothing to skip.

## Findings

No findings.

## Verified closed (executed at a27f93b6)

Each row below installs i1's forged pack: a relabelled `.idx` that carries forged brief bytes under main's brief blob id, with a newer mtime. `FORGED-READ` is what plain `git cat-file blob main:BRIEF` returns, so `Branch: feat/y` means the case is live. Verbatim from `names.log`:

```
baseline                     FORGED-READ=[Branch: feat/x] GATE=[ok docs/working/briefs/2026-10-01-x.md a2b820d5... |path ... A work-feat-x.txt|]
F1 newline+decoys            FORGED-READ=[Branch: feat/y] GATE=[refuse state objects: the default branch's commit or an object of its tree does not hash to its id, has a second copy in the object store, or could not be read|]
trailing newline+decoys      FORGED-READ=[Branch: feat/y] GATE=[refuse state objects: ...]
```

- **F1 (final pass) closed.** The exact nl.sh shape (`x\ny` with decoy indexes at `pack/x` and `objects/y.idx`) is refused, and so is a trailing-newline name with decoys at `pack/x` and `objects/.idx`. At d10cfba8 the same shape gave `ok ... A work-feat-y.txt` (final-pass `nl.log`).
- **Other byte shapes in the name.** All of these were refused with FORGED-READ=`Branch: feat/y`: `$'x\ty'`, `$'x\ry'`, leading space, trailing space, trailing and leading backslash, `$'\001x'`, `$'\E[0mx'`, `$'\377'`, `$'\303'` (invalid UTF-8), `-x`, `*`, `[a]`, `$'x\n\ny'`, `.x`, `..`. `IFS= read -r -d ''` keeps every byte except NUL, which no file name can hold. The `< "$o/$r"` redirect is quoted, so glob characters are not expanded. show-index reads stdin, so a leading `-` is never parsed as an option.
- **Locale.** gate_start's store_check runs under the caller's locale, not check_line's `LC_ALL=C`. Run under `LC_ALL=C.utf8` (the only UTF-8 locale installed), a pack named `$'\xff\nz'` with decoys was refused. GNU find's `-name '*.idx'` matched `\377.idx` and `a\303.idx` under both C and C.utf8 (direct test).
- **Links.** These were refused with live forged reads: the pack directory as an absolute link, the pack directory as a relative link, the objects directory as a link, `.idx` and `.pack` as symlinks to files outside the store, an `.idx` reached through a linked subdirectory, and hard links.
- **find -L loops fail closed.** Each case below printed a find error and then `refuse state objects`: a self-loop `pack/loop.idx`, both alone and next to a forged pack; `pack/d -> .`; `objects/ab -> .`; `pack/up.idx -> ..`. Both finds exit non-zero. The pack find carries `|| exit 1`. The loose find is the last pipeline in the brace group, so under `set -o pipefail` its status reaches the group, the outer pipeline and `|| return 1`.
- **`.idx` that is a directory, or a link to one,** with the forged `.pack` beside it: git itself dies (`fatal: mmap failed: No such device`), and the gate stops at resolve_main with no verdict. `! -type d` drops the entry from the listing, and git cannot read that pack either, so the two do not diverge.
- **`.idx` that is a FIFO:** both `git cat-file` and the gate hung until `timeout` killed them, with empty output. This is denial of service only (see the candidates below).
- **Dangling `.idx` link:** the gate refused, since the show-index redirect failed. Git ignores the pack and reads the genuine brief. A false refusal is the worst outcome.

### store_check --main (mainflag.log, verbatim)

```
== no --main, main list absent
1caac20b...         rc=1 main=absent call=absent
== no --main, main list empty
1caac20b...         rc=1 main=0 call=absent
== --main
--main c7ff2ce2...  rc=0 main=5 call=absent
== --main again on a corrupted object: list left empty?
--main c7ff2ce2...  rc=1 main=0 call=2
== tip call after the failed --main
1caac20b...         rc=1 main=0 call=2
== --main with a forged second copy in a pack: list left empty?
--main 147903fa...  rc=1 main=0 call=5
== the second copy is a main id seen from a tip call (main list from a clean start)
--main 147903fa...  rc=0 main=5 call=absent
c3f5ac1f...         rc=1 main=5 call=3
```

(The last three sections come from the rerun after a chmod fix to the probe, so their ids differ from the first run's.) The claims hold:
1. Without `--main`, a call fails when the skip list is missing or empty.
2. `--main` truncates the list before reading, so a failed `--main` (a re-hash mismatch, or a second copy) leaves it empty, and every later call fails.
3. The ids move into the list (`mv call main`) only after both the batch and the scan pass.
4. A second copy of one of main's ids that appears after startup is caught by a later tip call, since the scan judges main ∪ call.

`grep` shows one `--main` call site (gate_start, line 867). A failed `mv` is the function's last status, and gate_start then refuses.

## Untested bypass candidates (move #11)

- **FIFO `.idx` with a live writer that serves different bytes per open.** Not executed. Traced: git's `check_packed_git_idx` fstat-checks the size, and a FIFO reports 0, below the minimum index size. Git therefore never uses a FIFO index, and whatever the scan reads adds ids at most. Serving bytes also means acting during the run, which is the settled race family.
- **`.idx` links into `/proc/self/...`** (fd, cwd), which resolve differently in the scan's bash and in a later git process. Traced only. The scan opens the link from bash, where the fds are the loop's NUL list (fd 0), the pipe and stderr, and the cwd is the checkout. A link to `/proc/self/fd/0` reads the NUL list, so show-index fails and the scan refuses. A link to an fd bash lacks fails the redirect and also refuses. Diverging would need the scan to read a valid harmless index through that path while git reads the forged one, and that requires the caller to pass a crafted open fd (S4, trusted by design). Not executed.
- **Case-insensitive filesystem or a non-hex fan-out name:** as in the final pass, traced only. git looks in packs first and uses one fixed loose path, so neither yields a divergent copy.

## Endorsement Claims

- **Claim:** At a27f93b6 a forged second pack copy of main's brief blob is refused at startup for every pack name shape in `names.log` (newline variants with decoys, the control bytes tab, CR, 0x01 and ESC, invalid UTF-8, spaces, backslashes, glob characters, a leading dash, dot names), under LC_ALL=C and C.utf8.
  **Location:** `scripts/build-loop.sh:649-650` (store_check pack listing)
  **Evidence:** executed (`probes/names.sh`, `names.log`)
  **Verified:** git read the forged bytes in each case, and the gate printed `refuse state objects: ...`
  **Not verified:** names on a filesystem that rewrites names (case folding or Unicode normalisation), and a forged copy in a pack that only a merge-tree in gate_git writes during the run (the race family, row 646)
  **route: code-fact-check**

- **Claim:** store_check without `--main` returns 1 when `$GATE_TMP/main` is missing or empty, and a failed `--main` leaves the list empty.
  **Location:** `scripts/build-loop.sh:621-654`
  **Evidence:** executed (`probes/mainflag.sh`, function extracted verbatim)
  **Verified:** rc=1 in the absent and empty cases; main=0 after a failed `--main` caused by a corrupt loose object and after one caused by a forged second pack copy
  **Not verified:** the extracted function ran under the probe's own `set -euo pipefail`, not inside the full script after harden. Its env pairs do not touch the paths exercised here.
  **route: code-fact-check**

- **Claim:** find -L loops in the pack directory or the fan-out directories make the gate refuse; they do not drop entries silently.
  **Location:** `scripts/build-loop.sh:649-652`
  **Evidence:** executed (four loop shapes in `names.log`)
  **Verified:** each printed a find loop error and then `refuse state objects`
  **Not verified:** findutils versions other than 4.9.0. bfs is installed but not on the script's PATH ahead of `/usr/bin/find` here, and its loop exit status was not run.

## Primitive sweep

Primitive: object-store enumeration and read used for an integrity decision (diff scope)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:649` pack `find -L ... -print0 > idx` | S1 | NUL-ended; find exit checked | cleared (executed, names.log) |
| `build-loop.sh:650` `while read -d ''; show-index < "$o/$r"` | S1, S2 | quoted redirect; `\|\| exit 1` | cleared (executed) |
| `build-loop.sh:651` loose `find -L . ... \| awk -F/` | S1 | pipefail; lines only added | cleared (loop executed; a split line can only add) |
| `build-loop.sh:652` awk judge `main` + `call` | S3 | `\|\| return 1` | cleared (executed, mainflag.log) |
| `build-loop.sh:628` skip-list start / `:653` `mv` | S3 | `--main` gate | cleared (executed) |
| `build-loop.sh:867` gate_start `store_check --main` | S2 | exit 2 on failure | cleared (executed via names.sh refusals) |
| `build-loop.sh:925` per-brief `store_check "$sha" "$tree"` | S2 | refuse line on failure | unchanged in this range; executed through the mainflag tip calls only |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

The fix closes F1, and I found no other name shape or file type through which a pre-run same-uid writer gets an `ok` on bytes store_check did not verify. 35 executed cases covered control bytes, invalid UTF-8 under a UTF-8 locale, links at every level, link loops, and an `.idx` that is a directory, a FIFO or a dangling link. Each either refuses or fails with git itself. `--main` fails closed in all four ways the brief names. The remaining surface is the settled race family (row 646, code unchanged), caller-supplied fds or environment (trusted by design), and FIFO hangs (denial of service only, and git hangs too). The endorsement claims are executed and await the code-fact-check intake. The final pass recommended refusing any `pack/` entry not named `pack-<hex>.<ext>`; that remains optional hardening, not a requirement.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes. F1 was re-run at HEAD and is closed (executed). 33 other name and type shapes were executed, and all refused or failed without a verdict. `--main` fail-closed was executed in 4 scenarios. No findings.
- Out of scope: settled override rows (646 race, 638 history objects), whose code is unchanged; DoS-only FIFO hangs; caller-environment candidates (S4).
- Escalate: nothing blocks the merge from the security side. The FIFO-with-writer and `/proc/self` candidates are traced only and listed above.
- Decisions I made: I treated the final pass's `pack-<hex>` name-form refusal as optional hardening rather than a finding, because no executed bypass needs it. I counted the caller's locale as S4 but probed it anyway, since gate_start runs before check_line's `LC_ALL=C`.
