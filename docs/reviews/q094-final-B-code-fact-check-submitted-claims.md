Commit: 2eebdf8

# Code Fact-Check Report

**Repository:** claude-workflows (`git archive 2eebdf8` of `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, extracted to `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/s25-2763022088/B`; unit A's 9075003 extracted alongside at `.../A` for the Claim 3b comparison)
**Scope:** Stage 2.5 submitted-claims pass only — three critic endorsements on Q-094 unit B (`devcontainer-config/cc-exit-scan.sh` at 2eebdf8); no fresh harvesting
**Checked:** 2026-09-28
**Total claims checked:** 4

Submitted claim 3 was split into 3a/3b on verdict divergence.
**Summary:** 3 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read. Claim 3b matches the logged class "a specific measured value quoted … that does not contain it" in form: it quotes a timing. Here the value is a host timing that could not be reproduced, not a value missing from a checked-in artifact, so no new pattern entry is warranted (a timing miss is not a fabricated symbol).

Execution environment: cwd `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/s25-2763022088`, GNU bash 5.2.15, host kernel 6.18.35.2-microsoft-standard-WSL2, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C`, throwaway repos under `$TMPDIR` = that dir, removed after each run.

- Claims 1–2: `TMPDIR=$PWD bash harnessB.sh $PWD/B > logs/harnessB-2eebdf8.txt 2>&1` — exit 0, 2026-09-29T03:48:41Z (UTC). Output `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/s25-2763022088/logs/harnessB-2eebdf8.txt`. An earlier run at 03:47:56Z had a harness bug: `$?` was read after a command substitution in the same `res` call, so every content variant reported 0. The bug was fixed and the run repeated; the verdicts rest only on the 03:48:41Z run.
- Claim 3: `TMPDIR=$PWD bash perfB.sh $PWD/A $PWD/B 100 > logs/perf-B-S3.txt 2>&1` — exit 0, 2026-09-29T03:50:55Z (UTC). Output `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/s25-2763022088/logs/perf-B-S3.txt`. An earlier run at 03:49:40Z printed 0.00 s throughout because `bc` is absent; the arithmetic was switched to python3 and the run repeated.

---

## Submitted Claims

## Claim 1: "`_snap_unq` sets its output only to a string whose `printf %q` equals the input, so a decode that differs from the original path declines."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:786-796`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `_snap_unq` (`:786-796`, the whole function) and its one caller (`:886-887`), in a process whose locale is the one that produced the `%q` string (the launch and exit snapshots are taken in the same launcher process); does not establish that `%q` output is identical across locales or bash versions (a launch snapshot from another process or locale could decline, which fails closed), and does not cover the `$'…'` form, which it declines by design.

```bash
# devcontainer-config/cc-exit-scan.sh:786-796
_snap_unq() {
  local q="$1" s="" c i
  case "$q" in \$\'*|\'*|"") return 1 ;; esac
  for ((i = 0; i < ${#q}; i++)); do
    c="${q:i:1}"
    if [ "$c" = '\' ]; then i=$((i + 1)); c="${q:i:1}"; fi
    s+="$c"
  done
  [ "$(printf '%q' "$s")" = "$q" ] || return 1
  printf -v "$2" '%s' "$s"
}
```

The only write to the output variable is `printf -v "$2"` at `:795`, and it comes after the `%q` equality test at `:794`. `printf %q` output is a shell word that evaluates back to its input, so two strings with the same `%q` are equal. Therefore `%q(s) = q = %q(original)` implies `s = original`, and any other decode fails the test and returns 1. The caller treats that as a decline: `_snap_unq "$q" wt || return 1` (`devcontainer-config/cc-exit-scan.sh:887`). The output name `wt` is not one of `_snap_unq`'s locals (`q s c i`), so `printf -v` sets the caller's variable.

Executed: a round trip of 17 hand-picked paths (glob characters, `~`, `$(id)`, quotes, backslash, `;&|<>`, braces, `!`, `#`, tab, newline, `é`) plus 3,000 random printable-ASCII strings. Result: `correct=3014 declined=3 bad=0`. The 3 declines are tab, newline and `é`, which `%q` renders in `$'…'` form under `LC_ALL=C`, and on every decline the output variable was left untouched. Non-canonical inputs `a\b`, `\/x`, a trailing lone backslash, `/x/'a'`, `$'a'`, `''` and the empty string were all declined. `/x\\`, `\~x` and `a\ b\ ` were accepted, and each is exactly `%q` of its decode: `accepted-with-different-%q=0`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:783-796`, `devcontainer-config/cc-exit-scan.sh:884-890`, `logs/harnessB-2eebdf8.txt` (the `== S1` block)

---

## Claim 2: "A removed `dotgit` record is paired with a removed `commondir-file` only when its hashed content is exactly `gitdir: P\n` or the container form for the same `<n>`, and each record is consumed once."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:874-883`, `devcontainer-config/cc-exit-scan.sh:890`, `devcontainer-config/cc-exit-scan.sh:932`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the removal branch's pairing (`:872-891`, within `scan_std_worktrees` `:825-943`, read in full) and the all-consumed check (`:932`); "exactly" means equality of the 16-hex-digit (64-bit) sha256 prefix the records hold (`_snap_hash_str`, `:777-781`), not a byte comparison. The removed file no longer exists to compare. The pairing does not constrain the dotgit record's path (its old working tree is checked only by `looks_like_gitdir`, `:886-889`).

```bash
# devcontainer-config/cc-exit-scan.sh:872-891
    if [ "${rec:0:1}" = - ]; then
      [ ! -e "$p" ] && [ ! -L "$p" ] || return 1
      # Its own `.git` file gone too: a removed dotgit record that held exactly
      # "gitdir: P\n" (either form). Another worktree's .git never pairs.
      ok="" h="$(_snap_hash_str "gitdir: $p"$'\n')" g=""
      [ -z "$ccommon" ] || g="$(_snap_hash_str "gitdir: $ccommon/worktrees/$n"$'\n')"
      re="^file [0-7]+ ($h${g:+|$g})\$"
      for dk in "${!dot[@]}"; do
        if [ "${dk:0:1}" != - ] || [ -n "${used[${dot[$dk]}]:-}" ]; then continue; fi
        if [[ "${dot[$dk]##*$'\t'}" =~ $re ]]; then ok="${dot[$dk]}"; break; fi
      done
      [ -n "$ok" ] || return 1
      # The old working tree, if still there, must not look like a git dir: a
      # repository left in its place is not "removed".
      q="${ok%$'\t'*}"; q="${q#?F$'\t'dotgit$'\t'}"
      _snap_unq "$q" wt || return 1
      case "$wt" in */.git) wt="${wt%/.git}" ;; *) return 1 ;; esac
      ! looks_like_gitdir "$wt" || return 1
      used["$ok"]=1; removed+=("$n")
      continue
    fi
```

Only `-` dotgit records are considered (`${dk:0:1}`), and only when not already in `used`. The anchored regex accepts only the attrs form of a regular file (`file <mode> <hash>`; a link record's attrs start `link -> `, `:229`), with the hash of `gitdir: $p\n` or, when the common dir is inside the checkout, of `gitdir: $ccommon/worktrees/$n\n`. Both hashes are built from this iteration's `$n`. `used["$ok"]=1` (`:890`) marks the pairing, and `for rec in "${!left[@]}"; do [ -n "${used[$rec]:-}" ] || return 1; done` (`:932`) declines if any differing record was left unpaired.

Executed on real repos with `git worktree remove`:
- Baseline: one worktree removed → `status=0` with the note `(removed: a)`.
- The removed dotgit record's hash replaced with that of `gitdir: P\n\n`, of `gitdir: P` (no newline), of another name's P, of the relative `gitdir: ../../../.git/worktrees/a\n`, or of `gitdir: P/\n` → `status=1` each.
- A link-form record carrying the right hash → 1.
- Container form (`GIT_EXIT_SCAN_CONTAINER_WS` set to a test dir): same `<n>` → 0, other `<n>` → 1.
- Two worktrees removed where both dotgit records held P_a's content → 1. The control, both unmodified → 0 (`removed: a b`).
- An extra removed dotgit record at another path with P_a's content → 1 (left unconsumed).
- The old working tree left holding `HEAD` + `objects/` → 1.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:825-943`, `devcontainer-config/cc-exit-scan.sh:777-781`, `devcontainer-config/cc-exit-scan.sh:222-258`, `logs/harnessB-2eebdf8.txt` (the `== S2` block)

---

## Claim 3a: "The removal path of `git_exit_scan` returns the note in ~1.5 s at N=100 removed worktrees (measured on this WSL2 host)."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:825-943` (`scan_std_worktrees`)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the end-to-end wall time of `git_exit_scan` (exit snapshot + `scan_std_worktrees` + note), measured three times at N=100 removed worktrees on this host with a warm cache; does not establish behavior at other N, on a cold cache, or on another host or filesystem.

The removal branch (quoted under Claim 2, `:872-891`) runs two `_snap_hash_str` subshells per removed `<n>` and loops over the `dot` map. It does no filesystem walk of P, because P is gone (`[ ! -e "$p" ]`, `:873`). Measured: `B-removed-N100` 1.40 s, 1.38 s, 1.34 s, all `status=0` with one `note:` line. The exit snapshot alone took 0.06–0.07 s of that, so about 1.3 s is `scan_std_worktrees`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:872-891`, `devcontainer-config/cc-exit-scan.sh:951-1017`, `perfB.sh` (cwd above), `logs/perf-B-S3.txt`

---

## Claim 3b: "… while unit A's added path takes ~14.5 s at the same N (measured on this WSL2 host)."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:806-896` at 9075003 (`scan_std_worktrees`, unit A)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the end-to-end wall time of unit A's `git_exit_scan` at N=100 added worktrees, three runs on this host; does not establish the critic's own measurement conditions (host load at the time), and the spread between runs shows the number is load-sensitive.

The direction and rough magnitude hold: the added path is several times slower than the removal path. The ~14.5 s figure did not reproduce. Unit A, N=100 added: 7.48 s, 11.44 s, 7.29 s (all `status=0`, one `note:`). The exit snapshot alone took 4.0–4.4 s of each run, since it walks each new worktree's private dir and `.git` file. Unit B's added path at the same N took 7.84 s (snapshot 4.98 s). The precise version would read "~7–11 s here (about 4 s of it the exit snapshot), 5–8× the removal path", not ~14.5 s and ~10×. Per-worktree cost in the added branch comes from its hashing, `stat`, `find` and `cd` subshells (paraphrased — no quote available because the cost is spread over the eighteen lines `:854-889` of unit A's loop; the `find` line is quoted in the unit-A report, Claim 4).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:839-892` (at 9075003), `perfB.sh` (cwd above), `logs/perf-B-S3.txt`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 3b** (`devcontainer-config/cc-exit-scan.sh:806-896` at 9075003): the added-path timing of ~14.5 s at N=100 measured 7.3–11.4 s here (median 7.5 s). Restate it as "~7–11 s, load-sensitive". The comparison with the removal path still holds.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): two reports saved at the paths below, each a `## Submitted Claims` section in code-fact-check schema (seven bolded fields per claim, Verification mode, Scope line, Legibility-target), plus a Goal-Alignment Note.
- Answered: yes. All three unit-B submitted claims are verdicted, all executed. Claim 3 is split into 3a (Verified) and 3b (Mostly accurate) because its two timings earned different verdicts.
- Out of scope: no fresh harvesting. `%q` stability across locales and processes (Claim 1) and hash-prefix collisions (Claim 2) are named in Scope and were not tested.
- Escalate: nothing blocking. Claim 3b's number should be corrected wherever the performance-reviewer's endorsement is quoted (rubric or commit text).
- Decisions I made: I measured "the removal path of `git_exit_scan`" end to end (exit snapshot included) rather than `scan_std_worktrees` alone, and report both splits. Two harness bugs (a `$?` ordering error and the missing `bc`) were fixed and the runs repeated; only the repeated runs are cited.
