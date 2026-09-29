# Code Fact-Check Report

**Commit:** 2eebdf8
**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094b-exit-scan-worktree-removal`)
**Scope:** Unit B diff `9075003..2eebdf8` (commits 1f31b18, fc56eca, 2eebdf8): `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `test/cc-isolated-functions.bats`, plus the three commit messages. Unit A (`dfe4c0d..9075003`) read as context only.
**Checked:** 2026-09-28
**Total claims checked:** 17
**Summary:** 15 verified, 0 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern (the logged patterns are all measured-value/count claims; the count claims here — "three records", the four mutations, the test list — were re-measured and hold).

Execution environment for every `executed` claim: scratch copy of `git archive 2eebdf8` at `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcB-r2x7/tree` (mutants in `.../fcB-r2x7/m-<name>`, probes in `.../fcB-r2x7/probe`), GNU bash 5.2.15, `TMPDIR=.../fcB-r2x7/tmp LC_ALL=C GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. Captured output under `.../fcB-r2x7/logs/`. The worktree under review was not modified.

Runs:
- **R1 baseline**: `bats -f 'Q-094|_snap_unq' test/cc-isolated-functions.bats`, cwd `.../fcB-r2x7/tree`, exit 0, 2026-09-29T03:19:03Z, 12/12 ok. Log: `.../fcB-r2x7/logs/bats-q094-baseline.txt`.
- **R2 `_snap_unq` fuzz**: `LC_ALL=C bash fuzz.sh tree` and `LC_ALL=C.utf8 bash fuzz.sh tree` (20,000 random 1–6 byte non-NUL strings each, biased to shell metacharacters, `\`, `'`, `$`, `~`, high bytes), cwd `.../fcB-r2x7`, exit 0, finished 2026-09-29T03:18:53Z. Log: `.../fcB-r2x7/logs/fuzz-snap-unq.txt`.
- **R3 mutations**: `python3 mut.py` (one exact-string edit each) then the R1 bats command in each mutant, cwd `.../fcB-r2x7/m-<name>`, finished 2026-09-29T03:23:32Z. Logs: `.../fcB-r2x7/logs/mut-M1_drop_looks_like_gitdir.txt`, `mut-M2_check_dotgit_path.txt`, `mut-M3_skip_requote.txt`, `mut-M4_accept_on_decode_failure.txt`; each bats exit 1.
- **R4 probes P1–P5**: five extra `@test`s appended to the scratch copy's bats file, `bats -f PROBE`, cwd `.../fcB-r2x7/probe`, exit 0, 2026-09-29T03:24:04Z. Log: `.../fcB-r2x7/logs/probes.txt`.
- **R5 probes P6–P7** (added side, odd paths): `bats -f 'PROBE P[67]'`, cwd `.../fcB-r2x7/probe`, exit 0 (the probes print, they do not assert), 2026-09-29T03:24:25Z. Log: `.../fcB-r2x7/logs/probes-added-odd.txt`.

(`.../fcB-r2x7` = `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcB-r2x7`.)

---

## Claim 1: "When every difference is a linked worktree added or removed in git's own layout (agent worktrees outlive sessions), the scan prints one `note:` and returns 0 (scan_std_worktrees has the rule)."

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` returning 0 with one `note:` line when `scan_std_worktrees` accepts, for host-form and container-form removals and mixed add+remove; does not establish the launcher's end-to-end exit status (unit A test 12 covers that) or live behaviour on a host cc-isolated session (the commits themselves say "Live-verified: no").

`git_exit_scan` routes to the note on acceptance:

```bash
# devcontainer-config/cc-exit-scan.sh:982-985
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```

`scan_std_worktrees` emits exactly one `echo "note: ..."` (`cc-exit-scan.sh:942`). R1 test 3 asserts `[ "$status" -eq 0 ]` and `*"(removed: agent-y)."*` after `git worktree remove`; R4 P1 shows the same for a `.git` file in container form (`gitdir: /cws-probe/.git/worktrees/agent-y`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:75-77`, `devcontainer-config/cc-exit-scan.sh:951-985`, `devcontainer-config/cc-exit-scan.sh:942`, `test/cc-isolated-functions.bats:2263-2289`, `.../fcB-r2x7/logs/bats-q094-baseline.txt`, `.../fcB-r2x7/logs/probes.txt`

---

## Claim 2: "_snap_unq <%q string> <var>: sets <var> to the string printf %q quoted, for its backslash form only ($'…' and '…' forms return 1). The result is checked by quoting it again, so a wrong decode declines instead of passing."

**Location:** `devcontainer-config/cc-exit-scan.sh:783-785`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every output of bash 5.2's `printf %q` in the C and C.utf8 locales (backslash form decodes exactly; `$'…'` and the empty string's `''` decline; malformed input such as a trailing lone backslash declines); does not establish behaviour when the record was quoted in one locale and is decoded in another (static reading: such a mismatch makes the re-quote differ and declines, not verified by execution) or under other bash versions.

The whole function:

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

Why a wrong decode cannot pass (paraphrased — no quote available because this is an argument from `%q`'s contract, not a code line): `printf %q` output evaluates back to its input, so two different strings cannot share one `%q` output; the final `[ "$(printf '%q' "$s")" = "$q" ]` therefore admits only `s` equal to the original. R2 confirms empirically: C locale `ok=4725 wrong=0 declined_ansi=15272 declined_quote=3 declined_backslash_form=0`; C.utf8 `ok=4876 wrong=0 declined_ansi=15120 declined_quote=4 declined_backslash_form=0` (the `'…'` declines are strings that became empty). No backslash-form output failed to decode, and no decode was wrong. Mutation M3 (drop the re-quote line) fails R1 test 5 (`run ! _snap_unq "a$bs" out`), so the check is load-bearing.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:783-796`, `test/cc-isolated-functions.bats:2324-2334`, `.../fcB-r2x7/logs/fuzz-snap-unq.txt`, `.../fcB-r2x7/logs/mut-M3_skip_requote.txt`

---

## Claim 3: "Only dotgit, commondir-file and hooksdir records differ, and the exit snapshot has no W record. Removed <n>: gone `hooksdir P/hooks missing` and `commondir-file P/commondir` of exactly "../..\n", P gone on disk, one gone `dotgit` record that held exactly "gitdir: P\n" (either form), and that record's directory (the old working tree) either gone or not looking like a git dir (looks_like_gitdir)."

**Location:** `devcontainer-config/cc-exit-scan.sh:806-817`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each stated condition of the removal branch and the all-records-consumed check, read end to end (`scan_std_worktrees` :825-943) and exercised by R1/R3/R4; does not establish anything about subdirectories of the old working tree (only its root goes through `looks_like_gitdir`) or about git dirs the whole scan never looks for (a bare layout in an arbitrary subdirectory).

Record-kind filter and W refusal:

```bash
# devcontainer-config/cc-exit-scan.sh:832, 847-854
  [[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1
  ...
      [+-]F$'\t'dotgit$'\t'*) left["$line"]=1; dot["${line%$'\t'*}"]="$line" ;;
      [+-]F$'\t'commondir-file$'\t'*|[+-]F$'\t'hooksdir$'\t'*) left["$line"]=1 ;;
      *) return 1 ;;
```

commondir content and the paired hooksdir record of the same sign:

```bash
# devcontainer-config/cc-exit-scan.sh:867-871
    re="^file [0-7]+ $std\$"
    [[ "$attrs" =~ $re ]] || return 1
    hk="${rec:0:1}F"$'\t'"hooksdir"$'\t'"$(printf '%q' "$p/hooks")"$'\t'"missing"
    [ -n "${left[$hk]:-}" ] || return 1
```

Removal branch:

```bash
# devcontainer-config/cc-exit-scan.sh:872-892
    if [ "${rec:0:1}" = - ]; then
      [ ! -e "$p" ] && [ ! -L "$p" ] || return 1
      ...
      ok="" h="$(_snap_hash_str "gitdir: $p"$'\n')" g=""
      [ -z "$ccommon" ] || g="$(_snap_hash_str "gitdir: $ccommon/worktrees/$n"$'\n')"
      re="^file [0-7]+ ($h${g:+|$g})\$"
      for dk in "${!dot[@]}"; do
        if [ "${dk:0:1}" != - ] || [ -n "${used[${dot[$dk]}]:-}" ]; then continue; fi
        if [[ "${dot[$dk]##*$'\t'}" =~ $re ]]; then ok="${dot[$dk]}"; break; fi
      done
      [ -n "$ok" ] || return 1
      ...
      q="${ok%$'\t'*}"; q="${q#?F$'\t'dotgit$'\t'}"
      _snap_unq "$q" wt || return 1
      case "$wt" in */.git) wt="${wt%/.git}" ;; *) return 1 ;; esac
      ! looks_like_gitdir "$wt" || return 1
      used["$ok"]=1; removed+=("$n")
      continue
    fi
```

Every record must be consumed: `for rec in "${!left[@]}"; do [ -n "${used[$rec]:-}" ] || return 1; done` (`cc-exit-scan.sh:932`). The "exactly" in "held exactly" is a match on the snapshot's 16-hex sha256 prefix of the file bytes, and only a regular-file record (`file <mode> <hash>`) matches — a symlinked `.git` never pairs. The dotgit record path is the physical path `find -P` produced under `$_snap_ws` (`cc-exit-scan.sh:692-699`), `%q`-quoted by `_snap_file` (`cc-exit-scan.sh:257`), which is what `_snap_unq` decodes. R4 P5: `git worktree remove` changes exactly three records (commondir-file, dotgit, hooksdir). R4 P1: container form accepted. R3 M1/M2: dropping the `looks_like_gitdir` line, or checking `<wt>/.git` instead of `<wt>`, each fail R1 test 4 at `test/cc-isolated-functions.bats:2303`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-943`, `devcontainer-config/cc-exit-scan.sh:222-259`, `devcontainer-config/cc-exit-scan.sh:692-700`, `devcontainer-config/cc-gitdir.sh:83-90`, `.../fcB-r2x7/logs/probes.txt`, `.../fcB-r2x7/logs/mut-M1_drop_looks_like_gitdir.txt`, `.../fcB-r2x7/logs/mut-M2_check_dotgit_path.txt`

---

## Claim 4: "Paths are compared as the %q strings the records hold, recomputed from <n>; nothing is unquoted."

**Location:** `devcontainer-config/cc-exit-scan.sh:823-824`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removal branch as of 2eebdf8, which decodes a record path; does not bear on the added branch, where the sentence still holds (paths there are recomputed and compared as `%q` strings, e.g. the `dot["+F…$(printf '%q' "$wt/.git")"]` lookup at :914).

Before 2eebdf8 this was true function-wide. 2eebdf8 added a decode of a path taken from a record, not recomputed from `<n>`:

```bash
# devcontainer-config/cc-exit-scan.sh:886-887
      q="${ok%$'\t'*}"; q="${q#?F$'\t'dotgit$'\t'}"
      _snap_unq "$q" wt || return 1
```

The removed `dotgit` record's path is never compared at all (pairing is by content hash, :876-882); it is unquoted and its directory is then tested on disk with `looks_like_gitdir`. The sentence sits at the end of the doc comment after the "Added <n>:" clause, but it has no "added" qualifier and "nothing is unquoted" is absolute, so a reader takes it as covering the whole function. The precise version: "Added paths are compared as the %q strings the records hold, recomputed from <n>; the only unquoting is the removed `.git` record's path (`_snap_unq`, backslash form only, verified by re-quoting)."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-824`, `devcontainer-config/cc-exit-scan.sh:884-889`, `devcontainer-config/cc-exit-scan.sh:914`

---

## Claim 5: "Its own `.git` file gone too: a removed dotgit record that held exactly "gitdir: P\n" (either form). Another worktree's .git never pairs."

**Location:** `devcontainer-config/cc-exit-scan.sh:874-875`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pairing by content hash of this `<n>`'s `gitdir:` line, host or container form, and that a `.git` pointing at a different P does not pair; does not establish behaviour against a deliberate 64-bit hash-prefix collision (the snapshot keeps 16 hex digits of sha256).

The pattern is built only from this worktree's P (`gitdir: $p` / `gitdir: $ccommon/worktrees/$n`, quoted in Claim 3 at :876-878), and already-used records are skipped (:880). R1 test 6 (`test/cc-isolated-functions.bats:2336-2348`) removes agent-a's git dir and agent-b's `.git`, and asserts status 1 with `*"- dotgit $SCAN_WS/.claude/worktrees/agent-b/.git "*`; it passes.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:874-883`, `test/cc-isolated-functions.bats:2336-2348`, `.../fcB-r2x7/logs/bats-q094-baseline.txt`

---

## Claim 6: "The old working tree, if still there, must not look like a git dir: a repository left in its place is not "removed"."

**Location:** `devcontainer-config/cc-exit-scan.sh:884-885`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old working-tree root under `looks_like_gitdir`'s loose heuristic (HEAD of any type next to `objects/`, or a regular `commondir` file, symlinks followed); does not establish that nothing repository-like exists elsewhere under the old tree (a nested `.git` entry would show as its own `+ dotgit` record and decline; a bare layout in a subdirectory is not examined).

```bash
# devcontainer-config/cc-gitdir.sh:87-90
looks_like_gitdir() {
  local d="$1"
  { { [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]
}
```

R1 test 4 declines HEAD+`objects/` and a lone `commondir`, and accepts the control (an `objects/` dir plus `notes.txt`). R4 P4: the old path replaced by a symlink to an outside dir holding `HEAD` + `objects/` also declines (status 1), because the tests follow the link.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:884-889`, `devcontainer-config/cc-gitdir.sh:83-90`, `test/cc-isolated-functions.bats:2290-2322`, `.../fcB-r2x7/logs/probes.txt`

---

## Claim 7: note reason text — "Removed ones left no git dir behind" / "They take config and hooks from the checkout's own .git" / "Removed ones left no git dir behind, and added ones take config and hooks from the checkout's own .git"

**Location:** `devcontainer-config/cc-exit-scan.sh:933-942`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which text is printed for added-only, removed-only and mixed results, and that "no git dir behind" matches what the removal branch checks (P gone; old working-tree root not `looks_like_gitdir`); does not establish the absence of git dirs the branch never examines (subdirectories of the old tree, which the scan in general does not search for bare layouts).

```bash
# devcontainer-config/cc-exit-scan.sh:937-942
  why="They take config and hooks from the checkout's own .git"
  if [ "${#removed[@]}" -gt 0 ]; then
    [ "${#added[@]}" -eq 0 ] && why="Removed ones left no git dir behind" ||
      why="Removed ones left no git dir behind, and added ones take config and hooks from the checkout's own .git"
  fi
  echo "note: exit scan: only linked worktrees in git's standard layout changed (${line% }). $why, so this is not a finding."
```

The `&& … ||` chain cannot misfire: a plain assignment always returns 0. R1 test 4 asserts the removed-only text verbatim (`"(removed: agent-y). Removed ones left no git dir behind, so this is not a finding."`); test 3 asserts the mixed text (`"(added: agent-z; removed: agent-y). Removed ones left no git dir behind, and added ones take config"`); R5 P6 prints the added-only text. "No git dir behind" is scoped by the two checks quoted in Claims 3 and 6: P gone (`[ ! -e "$p" ] && [ ! -L "$p" ]`, :873) and the old root not looking like one (:889).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:928-942`, `test/cc-isolated-functions.bats:2263-2322`, `.../fcB-r2x7/logs/bats-q094-baseline.txt`, `.../fcB-r2x7/logs/probes-added-odd.txt`

---

## Claim 8: "Only linked worktrees added or removed in git's standard layout (STANDARD WORKTREES above): a note, not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:979-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch that follows this comment (quoted in Claim 1, :982-985) and that it applies only when no invalid-gitdir finding is pending; does not re-establish the acceptance rule, which is Claims 3 and 6.

The guard is `if [ -z "$invalid" ] && note="$(scan_std_worktrees …)"` (`cc-exit-scan.sh:982`); on success it prints the note and returns 0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:966-985`

---

## Claim 9: Plan rule 6 — "The stacked unit accepts a removal when the difference removes exactly `hooksdir P/hooks missing` and `commondir-file P/commondir file <mode> H("../..\n")`, `P` no longer exists on disk, and one removed `dotgit` record held exactly `gitdir: P\n` (either form), and that record's directory (the old working tree) is gone or fails `looks_like_gitdir` (… a path `%q` writes as `$'…'` is not decoded and warns). … Pairing is now by content."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule-6 conditions as 2eebdf8 implements them and the `$'…'` decline; does not verify the historical statements (review iterations, "447 lines", decision-log row 62), which are unit-A context.

Same code as Claims 3 and 6. The `$'…'` decline is `case "$q" in \$\'*|\'*|"") return 1 ;; esac` (`cc-exit-scan.sh:788`), exercised by R1 test 4's newline path (`test/cc-isolated-functions.bats:2313-2322`); mutation M4 (accept on decode failure) fails that step at :2320.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `devcontainer-config/cc-exit-scan.sh:786-796`, `devcontainer-config/cc-exit-scan.sh:872-892`, `.../fcB-r2x7/logs/mut-M4_accept_on_decode_failure.txt`

---

## Claim 10: "A linked worktree added or removed in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` returning 0 with one note for a removal (R1 test 3) and the launcher mapping (unit A test 12, re-run in R1); does not establish a live host session.

Same code path as Claim 1. R1 test 12 ("a session that leaves an agent worktree ends the launcher with claude's status and a note") passes.

**Evidence:** `guides/cc-isolated-usage.md:66-68`, `devcontainer-config/cc-exit-scan.sh:982-985`, `.../fcB-r2x7/logs/bats-q094-baseline.txt`

---

## Claim 11: "…or removed (`git worktree remove`: git dir and `.git` file both gone) … For a removal, "exact" means the private dir is gone and the removed records are the ones git's layout makes (the `.git` file named that dir), and the old working-tree directory is gone or does not look like a git dir (no `HEAD` next to `objects/`, no `commondir` file); a working-tree path with a newline or other byte that bash's `%q` quotes as `$'…'` warns."

**Location:** `guides/cc-isolated-usage.md:335-346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removal conditions and the `$'…'` decline against `scan_std_worktrees` and `looks_like_gitdir`; does not establish which bytes bash quotes as `$'…'` beyond those R2 generated (all control bytes and, in C locale, all high bytes did), nor the example note text's `(added: agent-x)` for removals (it prints `removed:`; the example is labelled as the added case).

`looks_like_gitdir` (quoted in Claim 6) is "HEAD next to objects/, or a commondir file" — the guide's "no `HEAD` next to `objects/`, no `commondir` file" is its negation. The `$'…'` decline: `cc-exit-scan.sh:788` (quoted in Claim 2). "The removed records are the ones git's layout makes" corresponds to the commondir `../..\n`, hooks `missing` and `gitdir: P\n` checks (Claim 3); R4 P5 confirms those are all `git worktree remove` changes.

**Evidence:** `guides/cc-isolated-usage.md:334-356`, `devcontainer-config/cc-gitdir.sh:87-90`, `devcontainer-config/cc-exit-scan.sh:786-796`, `.../fcB-r2x7/logs/fuzz-snap-unq.txt`, `.../fcB-r2x7/logs/probes.txt`

---

## Claim 12: "Anything else warns as before, worktree lines included — also any other change in the session, a working tree deleted without a prune, …"

**Location:** `guides/cc-isolated-usage.md:352-354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a working tree `rm -rf`'d while its private dir stays (with or without its HEAD/commondir); does not cover a working tree deleted and then pruned (that is a full removal and gets the note, as the test's final step shows).

With the working tree deleted, only `- dotgit` differs; its P's commondir/hooksdir records are unchanged, so nothing consumes the dotgit record and :932 declines. R1 test 3 asserts `[ "$status" -eq 1 ]` and `*"- dotgit $SCAN_WS/.claude/worktrees/agent-x/.git "*` after `rm -rf` of the working tree, and status 1 again after deleting P's `HEAD` and `commondir` (P still on disk, :873). R4 P2/P3 (only HEAD, only commondir deleted) both give status 1.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:872-873`, `devcontainer-config/cc-exit-scan.sh:932`, `test/cc-isolated-functions.bats:2276-2288`, `.../fcB-r2x7/logs/probes.txt`

---

## Claim 13: Commit 1f31b18 — "A worktree removed with `git worktree remove` drops three records: its .git file, its private dir's commondir, and the missing hooks/. … when: the removed commondir-file held exactly "../..\n" and the removed hooksdir was "missing"; the private dir P is gone on disk (a dir made invisible to the scan by deleting HEAD or commondir but left in place still warns); a removed dotgit record held exactly "gitdir: P\n", by host or container path. … Anything else, including a working tree deleted without a prune, warns."

**Location:** `1f31b18` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three-record count, each listed condition, and the HEAD-or-commondir variant; does not verify the unit-A-era history ("reviewed in iteration 1", "89 changed code lines").

R4 P5 diffs two snapshots around `git worktree remove` and asserts exactly 3 changed lines, printed as `commondir-file`, `dotgit`, `hooksdir`. The "HEAD or commondir" parenthetical: R4 P2 (HEAD only) and P3 (commondir only) both warn, as does R1 test 3 (both). Conditions: code quoted in Claim 3.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:864-892`, `.../fcB-r2x7/logs/probes.txt`, `.../fcB-r2x7/logs/bats-q094-baseline.txt`

---

## Claim 14: Commit fc56eca — "the scan_std_worktrees comment now names the removed records' exact content ("../..\n", hooks "missing"), and the guide says which of the "exact" layout checks apply to a removal. No behaviour change."

**Location:** `fc56eca` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that fc56eca touches only comments in `cc-exit-scan.sh` and prose in the guide; does not re-verify content that 2eebdf8 later rewrote (Claims 3, 11).

`git show fc56eca -- devcontainer-config/cc-exit-scan.sh`, filtered to changed lines that are not comments, prints only the `---`/`+++` file headers (paraphrased — no quote available because the evidence is an empty filtered diff); `--stat` lists only `devcontainer-config/cc-exit-scan.sh` (5 lines) and `guides/cc-isolated-usage.md` (4 lines).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-817`, `guides/cc-isolated-usage.md:342-346`

---

## Claim 15: Commit 2eebdf8 — "Tests: a removal with the old dir back holding ordinary files (note, positive control), then HEAD next to objects/ (warns), then a lone commondir file (warns), then a $'...' path (warns); _snap_unq round trips. Mutations that drop the looks_like_gitdir check, check the .git path instead of its dir, skip the re-quote check, or accept on a decode failure each fail a test."

**Location:** `2eebdf8` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed test steps (R1) and my own rendering of each of the four mutations (R3; the commit does not record its exact mutants, so "accept on a decode failure" was rendered as `_snap_unq "$q" wt || { used["$ok"]=1; removed+=("$n"); continue; }`); does not establish that other renderings of the same mutation (e.g. `|| true`, which leaves `wt` empty and declines at the `*/.git` case anyway) would fail a test.

R3 results (each mutant's bats exit 1):
- M1 drop `! looks_like_gitdir "$wt" || return 1` → `not ok 4`, `test/cc-isolated-functions.bats:2303` (`[ "$status" -eq 1 ]` after HEAD planted).
- M2 delete `case "$wt" in */.git) wt="${wt%/.git}" ;; *) return 1 ;; esac` (so the `.git` path is tested) → `not ok 4` at :2303.
- M3 delete `[ "$(printf '%q' "$s")" = "$q" ] || return 1` → `not ok 5` (the `_snap_unq` test).
- M4 accept on decode failure → `not ok 4` at :2320 (the `$'…'` newline-path step).

Test steps in the order listed: `test/cc-isolated-functions.bats:2295-2322` (control with `mkdir -p "$STD_WT/objects"; echo x > "$STD_WT/notes.txt"`, then `HEAD`, then a lone `commondir`, then the newline path) and `:2324-2334` (`_snap_unq`).

**Evidence:** `test/cc-isolated-functions.bats:2290-2334`, `.../fcB-r2x7/logs/mut-M1_drop_looks_like_gitdir.txt`, `.../fcB-r2x7/logs/mut-M2_check_dotgit_path.txt`, `.../fcB-r2x7/logs/mut-M3_skip_requote.txt`, `.../fcB-r2x7/logs/mut-M4_accept_on_decode_failure.txt`

---

## Claim 16: Commit 2eebdf8 Notes — "Declining (not accepting) an undecodable path is the fail-closed choice; the added side already declines such paths (its back-pointer read is one line)."

**Location:** `2eebdf8` (commit message, Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added branch's handling of working-tree paths that `%q` writes as `$'…'`; does not say the added side is unsafe for them (it accepts only after the same layout checks as for any path). The consequence is an add/remove asymmetry that fails closed, not an acceptance hole.

"Such paths" means paths `%q` writes as `$'…'` (the removal side declines all of them). The added side declines only paths containing a **newline**, because the one-line back-pointer read then disagrees with the file's hash:

```bash
# devcontainer-config/cc-exit-scan.sh:902-903
    line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1
    _snap_file_is "$p/gitdir" "$(_snap_hash_str "$line"$'\n')" || return 1
```

A path with a tab (or another control byte, or a high byte in the C locale) reads in full on one line, and the `.git` record is then found by re-quoting, `dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]` (:914), which matches the `$'…'` form the snapshot wrote. R5 P6: a worktree added at `…/odd<TAB>dir/agent-t` (record path `$'…/odd\tdir/agent-t/.git'`) gives `status=0` and `note: … (added: agent-t). They take config and hooks from the checkout's own .git, …`. R5 P7 (newline path) gives `status=1`, which matches the parenthetical. So the mechanism holds only for newlines; the conclusion "the added side already declines such paths" is false for every other `$'…'` byte, and a tab-path worktree that got the note when added warns when removed. Precise version: "the added side already declines paths with a newline (its back-pointer read is one line); other `$'…'` paths are accepted there, and warn only on removal."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:898-927`, `.../fcB-r2x7/logs/probes-added-odd.txt`

---

## Claim 17: Test names vs assertions — "a removed standard worktree is a note; a half-removed one warns", "a removal whose old working tree now looks like a git dir warns", "_snap_unq: inverts printf %q's backslash form; other forms decline", "a removed git dir pairs only with the .git that pointed at it"

**Location:** `test/cc-isolated-functions.bats:2263`, `test/cc-isolated-functions.bats:2290`, `test/cc-isolated-functions.bats:2324`, `test/cc-isolated-functions.bats:2336`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each name's claim is asserted in its body and that the assertions are live (R3 shows mutants turn tests 4 and 5 red); does not claim the names list everything the bodies test (test 4 also covers the `$'…'` path decline, which is not a "looks like a git dir" case, and test 3's final step asserts only the status, not the note text).

- :2263 asserts status 0 and `(removed: agent-y).` for the removal, then status 1 for the working tree deleted without a prune and for the HEAD/commondir-stripped P, then status 0 once P is gone.
- :2290 asserts status 0 for the control, then status 1, the WARNING header, the `- dotgit` line and no `note:` for HEAD+`objects/`; status 1 and no `note:` for a lone `commondir`; the same for the newline path.
- :2324 round-trips seven strings including `\`, `'`, `~`, `;&|`, `*?[]`, and uses `run !` for the `$'…'` form, `''`, and a trailing lone backslash.
- :2336 asserts status 1 and that agent-b's `- dotgit` line is listed.

(paraphrased — no quote available because these summarise four whole test bodies, 86 lines, whose assertions are listed above by line range.)

**Evidence:** `test/cc-isolated-functions.bats:2263-2348`, `.../fcB-r2x7/logs/bats-q094-baseline.txt`, `.../fcB-r2x7/logs/mut-M1_drop_looks_like_gitdir.txt`, `.../fcB-r2x7/logs/mut-M3_skip_requote.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 16** (`2eebdf8` commit Notes): "the added side already declines such paths" holds only for newline paths; a worktree added at a path with a tab (another `$'…'` byte) is accepted with a note (R5 P6), so add and remove are asymmetric. Fix the note, or make the added side decline `$'…'` record paths too if symmetry is intended.

### Stale
- **Claim 4** (`devcontainer-config/cc-exit-scan.sh:823-824`): "nothing is unquoted" became false in 2eebdf8, which unquotes the removed `.git` record's path with `_snap_unq` (:886-887). Qualify it to the added branch and name the one decode.

### Mostly Accurate
- (none)

### Unverifiable
- (none)

---

## Goal-Alignment Note

The unit's goal: accept a standard `git worktree remove` with a note while failing closed on everything else, including (new in 2eebdf8) a repository left at the old working-tree path. The code does this. The removal conditions match the doc comment, guide and plan rule 6; `_snap_unq` cannot return a wrong decode (the re-quote check makes that impossible, and 40,000 fuzzed strings agree); all four mutations named in the commit fail a test; container-form removal, a symlinked old path, and HEAD-only or commondir-only stripping behave as documented (probes P1–P5). Neither finding changes behaviour. Claim 4 is a doc-comment sentence that 2eebdf8 made false. Claim 16 is a commit-message rationale that overstates the added side's symmetry; that side still fails closed in the direction that matters (a tab-path worktree gets the note when added and a warning when removed), but a reader relying on the note would expect otherwise.
