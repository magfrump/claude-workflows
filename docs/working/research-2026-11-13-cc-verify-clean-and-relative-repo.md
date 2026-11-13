# Research: `cc-verify --clean` with no record, a relative REPO, `source_lines_ok`

Date: 2026-11-13 · Brief: `docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md`
Branch: `fix/cc-verify-clean-and-relative-repo` (build loop, dispatch 1)

## What the code does (devcontainer-config/cc-verify.sh at 63184f91)

- `--clean` (lines 206-216) loops over `$ROOT/run-*` and first reads `PID=` from
  `$d/record` with `sed ... 2>/dev/null | head -1` inside `$(...)`. With no `record`
  (or a non-directory `run-*`), `sed` exits 2, `pipefail` makes the assignment fail,
  and `set -e` ends the script with status 2 and no output, before the NOTE or the
  `cleaning` line. `teardown` (line 142) has the same read but runs under `||`/`set +e`,
  so it is not affected.
- A run makes its directory (line 225, named `run-<epoch>-$$`), `cd`s into it, and only
  then writes `record` (line 228). Between those lines a live run has no `record`.
- REPO (line 218) is used by `git clone` at line 232, after the `cd` into the run dir
  at line 225, so a relative REPO names a path inside the run dir. `--check FILE` is
  read at line 220, before the `cd`, so it is unaffected.
- `source_lines_ok` (lines 47-65) reads each file with `while IFS= read -r line`, which
  drops a final line that has no newline: a `source` there is never seen.
  `test/cc-host-tool-sources.bats` extracts this function by name with `sed`.

## Decisions

### D1: how `--clean` keeps a fresh live run with no `record` (Path A)

Options: (a) skip a no-record directory younger than N seconds; (b) a lock the run
holds (`flock` on a file); (c) the run's PID from the directory's own name.

(c) dominates. `cc-verify` names the directory `run-<epoch>-$$`, so the PID that the
`record` would carry is already in the name from the `mkdir` on. `--clean` now takes the
PID from `record` and, when there is none, from a name of exactly the form
`run-<digits>-<digits>`, and applies the existing `/proc/$p/cmdline` check. No new
mechanism (S3), no threshold to tune, and it fails safe: a reused PID that happens to be
another live `cc-verify` keeps a dead run's directory with a NOTE and exit 1, never the
reverse. (a) can delete a run paused at a slow `mkdir`/`cd` on a loaded host and keeps
a stale directory for N seconds; (b) adds a second liveness mechanism beside the PID
check and a dependency on `flock`. A name that is not in cc-verify's form (such as the
trial script's `run-1793211495-572412.d`) has no PID and is cleaned, as the brief asks.

### D2: a relative REPO (Path A over two options)

Resolve, rather than refuse: the documented `.` form then works, and the refusal would
only add a message to a mistake the script can fix itself. A REPO that exists on disk is
made absolute (`cd -P` of the directory, or of a file's directory for a bundle) before
the `cd`; anything else (a URL, `host:path`) is passed to `git clone` unchanged, and a
nonexistent path still ends at "could not clone". A third option, cloning before the
`cd`, would move the clone out of the run dir's trap and teardown: rejected.

The header of `docs/working/q125-verify-check.sh` now shows `"$PWD"`, not `.`: the host
keeps the old `cc-verify` until the next install, and `"$PWD"` works with both.

### D3: `source_lines_ok` (one-line note)

`while IFS= read -r line || [ -n "$line" ]`, the standard idiom; no other option is viable.
The function also gains a one-line comment naming `test/cc-host-tool-sources.bats` as its
second consumer (the architecture-review F3 Defer row in `docs/reviews/override-log.md`,
whose revisit trigger is this change). The unterminated-line fix closes the
security-reviewer Defer row there ("Shipped source_lines_ok misses an unterminated last
line, devcontainer-config/cc-verify.sh:54,62", 2026-11-05, `test/q089-source-guard-narrow`).

## Pre-mortem: bypass families (enforcement file)

Assume this shipped and a run was harmed or a check was skipped. How:

1. **`--clean` removes a live run.** A run between `mkdir` and `record` is kept by its
   name's PID (tested with a live process named `cc-verify-live`). A run whose `/proc`
   cmdline does not contain `cc-verify` (invoked under another name) would be removed;
   that was already true for runs with a `record`, so nothing widens.
2. **A planted name keeps a stale directory.** A same-uid writer naming a directory after
   a live `cc-verify` PID only makes `--clean` keep it with a NOTE and exit 1: fail-safe,
   and out of scope as a hostile author (S1).
3. **Resolution points REPO at a different repo.** `cd -P` follows symlinks to the real
   path, which is what `git clone` would have read; the merge still comes from REPO's
   objects only, never its working tree, so nothing about what is verified changes.
   A local directory named like a URL (`host:path`) becomes `/abs/host:path` and is
   cloned as a local path, which is what the operator named.
4. **The self-check still misses a line.** The fix reads an unterminated last line; other
   spellings stay unseen as before (the function's header lists them, row 71's Q-147).
5. **The host keeps the old copy.** Until the next `install.sh` re-blesses
   `host-tools.sha256`, the host runs the old `cc-verify`; the edited copy refuses to run
   un-blessed (`hash_ok`), so nothing runs half-updated.

## Review

Round 1 (one general-purpose reviewer, commit 3a9e162f): no red. Amber: an exported
CDPATH made `cd -P -- repo/` pick another directory (fails at the clone, but the bug
returns); fixed by passing a relative REPO as `./REPO`, which also stops a REPO of `-`
meaning the last directory, with a CDPATH case in the test. Green, taken: the help and
guide say "a URL or host:path"; the live-run test now waits on a builtin `read` from a
FIFO, so its kill leaves no `sleep` child. Green, left: line 135's `(cd stage && ...)`
has the same CDPATH exposure but predates this change and is out of the brief's scope.

Round 2 (same reviewer, commit c94bc0b6): no red. Amber: an empty REPO became `./`
and verified the current directory, where `git clone ""` used to fail; fixed by a usage
refusal (exit 2, "REPO is empty.") at argument parsing, with a bats case. Green, taken:
--help says a path that exists is read as a path (a local `host:path` directory is a
path, which round 1 already did). Nothing else open; the loop ends clean.

## Gotchas

- Failure-pattern grep: FP-020, FP-062, FP-129, FP-175
  - FP-020 / FP-062: a relative path resolved against the wrong directory; the same
    cause as defect 2, and the same fix shape (resolve where the operator meant).
  - FP-129 / FP-175: a pipe's exit status under `pipefail` deciding control flow; defect 1
    is the same family (an absent file read ending the script under `set -e`).
- Grep: `grep -inE 'cc-verify|pipefail|set-e|no-newline|unterminated|last-line|relative|cd-before|cwd' docs/failure-patterns.md`.
- New entries: FP-181 (defect 1) and FP-182 (defect 3). Defect 2 is FP-020's pattern again
  and gets no new entry.

## Verification

- `scripts/confine-tests.sh --probe` exit 3: "confine-tests: NO CONFINEMENT PRIMITIVE
  AVAILABLE — refusing to run." So the tests ran through `scripts/run-tests.sh` plus
  `scripts/hermeticity-lint --root .`.
- Three new cases in `test/cc-verify.bats`, each run before the fix and seen failing
  (status 2 vs 1; status 1 vs 0; status 0 vs 1), then passing.

## Host paste (after the merge, for a `you: terminal` entry)

It rides on the next `install.sh`, which installs all of main: file it with, or after, the
release decision that is holding the install (Q-277), not as a separate install.

```
cd ~/claude-workflows && ./devcontainer-config/install.sh   # your checkout at main; review the cc-verify.sh diff, y re-blesses host-tools.sha256
mkdir -p ~/cc-verify/run-1-999999999 && cc-verify --clean; echo "clean exit $?"   # expect: cleaning .../run-1-999999999, clean exit 0
printf 'true\n' > ~/cc-verify-true.sh && cc-verify --check ~/cc-verify-true.sh . main <<< n; echo "relative exit $?"; rm -f ~/cc-verify-true.sh   # expect: the y/N prompt, "declined: nothing was built.", relative exit 1, no "could not clone"
```
