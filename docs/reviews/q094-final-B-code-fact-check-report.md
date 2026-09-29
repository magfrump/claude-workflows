# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094b-exit-scan-worktree-removal`, read via `git show` / `git archive`; working tree not touched)
**Scope:** Unit B diff `9075003..2eebdf8` (commits 1f31b18, fc56eca, 2eebdf8): `devcontainer-config/cc-exit-scan.sh`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, plus the three commit messages; unit A (`dfe4c0d..9075003`) read as context where B interacts with it. Merged from three replicate reports (`B-code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`).
**Checked:** 2026-09-28 (replicate executions 2026-09-29T03:11Z–03:27Z UTC; merge 2026-09-28)
**Total claims checked:** 23
**Summary:** 18 verified, 2 mostly accurate, 2 stale, 1 incorrect, 0 unverifiable
**Commit:** 2eebdf8
**Replication:** k=3

Merge procedure: code-review skill, "Merging replicate verdicts (most-severe-wins)". Claims were clustered by (file, ±5 lines, substance) and emitted at the finest granularity any replicate used; a replicate that verdicted only a compound claim carries that verdict on each sub-claim row, marked `(compound)`. Each claim's verdict is the most severe any replicate gave it; its body, Scope, Confidence, Verification mode and Evidence come from the winning replicate (named in the line under the fields); every other replicate's scope caveats and notes are in `**Replicate annotations:**`. No claim, verdict or evidence was added in merging.

Replicate environments and log paths. All log paths below are relative to the session scratchpad `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/`:
- r1: `git archive 2eebdf8` tree at `fcB-r1x7/tree`, logs `fcB-r1x7/logs/`, probes in `fcB-r1x7/probe` (baseline `bats -f 'Q-094|_snap_unq'` 12/12 ok; mutations M1–M4b; PROBE tests).
- r2: tree at `fcB-r2x7/tree`, logs `fcB-r2x7/logs/` (R1 baseline 12/12; R2 `_snap_unq` fuzz; R3 mutations M1–M4; R4/R5 probes P1–P7).
- r3: tree at `fcB-r3k7/tree`, logs and scripts copied to `reviews/B-fc-r3-logs/` (baseline 12/12; full `test/cc-isolated-functions.bats` 172/172; experiments E1–E9; six mutations).
All three used GNU bash 5.2.15, git 2.39.5, `LC_ALL=C` unless a claim says C.UTF-8.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): all three replicates read it; none found a claim matching a logged pattern (2eebdf8 lists tests by content, not count).

---

## Claim 1: "When every difference is a linked worktree added or removed in git's own layout (agent worktrees outlive sessions), the scan prints one `note:` and returns 0 (scan_std_worktrees has the rule)."

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` returning 0 with one `note:` line when `scan_std_worktrees` accepts, for host-form and container-form removals and mixed add+remove; does not establish the launcher's end-to-end exit status (unit A test 12 covers that) or live behaviour on a host cc-isolated session (the commits themselves say "Live-verified: no").
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the exact acceptance rule (Claims 3, 6) or behaviour when `invalid` is set (the note path is skipped then)" · r3: "does not establish the launcher's end-to-end exit status for a removal (the launcher test that exercises this path, test 12, uses an added worktree only)"

Headline evidence from r2. `git_exit_scan` routes to the note on acceptance:

```bash
# devcontainer-config/cc-exit-scan.sh:982-985
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```

`scan_std_worktrees` emits exactly one `echo "note: ..."` (`cc-exit-scan.sh:942`). R1 test 3 asserts `[ "$status" -eq 0 ]` and `*"(removed: agent-y)."*` after `git worktree remove`; R4 P1 shows the same for a `.git` file in container form (`gitdir: /cws-probe/.git/worktrees/agent-y`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:75-77`, `devcontainer-config/cc-exit-scan.sh:951-985`, `devcontainer-config/cc-exit-scan.sh:942`, `test/cc-isolated-functions.bats:2263-2289`, `fcB-r2x7/logs/bats-q094-baseline.txt`, `fcB-r2x7/logs/probes.txt`

---

## Claim 2: "_snap_unq <%q string> <var>: sets <var> to the string printf %q quoted, for its backslash form only ($'…' and '…' forms return 1). The result is checked by quoting it again, so a wrong decode declines instead of passing."

**Location:** `devcontainer-config/cc-exit-scan.sh:783-785`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers decode-or-decline for every `printf %q` output of bash 5.2 in C and C.UTF-8 locales (including a record written in one locale and decoded in the other, which declines); does not establish behaviour if a caller passes a variable name that collides with `_snap_unq`'s own locals (`q s c i`) — the one caller passes `wt`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish behaviour when the `%q` text was produced under a different locale than the one decoding it (launch and exit snapshots would have to run under different LC_CTYPE), which was not tested" · r2: "does not establish behaviour when the record was quoted in one locale and is decoded in another (static reading: such a mismatch makes the re-quote differ and declines, not verified by execution) or under other bash versions" · merge note: r3's Scope states the cross-locale case was covered (it declines); r1 and r2 state they did not execute it

Headline evidence from r3. The full function (read signature to last line):

```bash
# devcontainer-config/cc-exit-scan.sh:786-797
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

The re-quote line is what makes the "wrong decode declines" half hold in general: `printf %q` is injective (its output evals back to the input), so any `s` with `printf %q s` equal to `q` is the original string (paraphrased — no quote available because this is a property of bash's `%q`, argued from its eval-round-trip contract rather than a line of this repo). Bash emits only three forms: backslash-escaped, `$'…'` (whole string, when any byte needs it), and `''` for the empty string; the `case` rejects the latter two, and the re-quote check alone would also reject them (mutation `no-form-case` removing the `case` line leaves all 12 tests passing: `reviews/B-fc-r3-logs/m-no-form-case.txt`).

Executed: `LC_ALL=C bash q.sh` and `LC_ALL=C.UTF-8 bash q.sh` (exit 0, 2026-09-29T03:18Z): 17 path forms (space, newline, tab, `é`, `\xff`, `~`, quotes, `$`/backtick, `!`, braces/comma, `#`, `=`, `%`, `^`, `:`/`@`, DEL, ESC). Every result was `ok` (round-trip equal) or `declined`; none `WRONG`. In C locale `é` is `$'/a/\303\251/.git'` and declines; in C.UTF-8 it is written raw and decodes correctly (`reviews/B-fc-r3-logs/unq-forms.txt`). r1 (every byte 1–255 in 10 contexts plus 20 000 random byte strings, in C and C.UTF-8, plus 30 000 printable-ASCII paths) and r2 (20,000 random strings per locale) fuzzed the function with `wrong=0`, and each found that deleting the re-quote line fails test 5.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:783-797`, `reviews/B-fc-r3-logs/unq-forms.txt`, `reviews/B-fc-r3-logs/q.sh`, `reviews/B-fc-r3-logs/m-no-form-case.txt`

---

## Claim 3: scan_std_worktrees removal rule — "Only dotgit, commondir-file and hooksdir records differ, and the exit snapshot has no W record. Removed <n>: gone `hooksdir P/hooks missing` and `commondir-file P/commondir` of exactly "../..\n", P gone on disk, one gone `dotgit` record that held exactly "gitdir: P\n" (either form), and that record's directory (the old working tree) either gone or not looking like a git dir (looks_like_gitdir)."

**Location:** `devcontainer-config/cc-exit-scan.sh:806-818`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed condition against the removal branch (`:856-891`) and the final all-records-used loop (`:932`); does not establish that "the old working tree" check covers a path reached through a symlinked parent outside the checkout (it follows the symlink; see Claim 7b) or anything about the container form beyond hash equality.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: nothing is established about what lies under the old working tree below its root (r2: "only its root goes through `looks_like_gitdir` … a bare layout in an arbitrary subdirectory"; r3: "see Claim 6") · r3: "does not establish anything about paths not under the checkout's own common dir (those decline at `:862`, unit A)" · r2: "The 'exactly' in 'held exactly' is a match on the snapshot's 16-hex sha256 prefix of the file bytes, and only a regular-file record (`file <mode> <hash>`) matches — a symlinked `.git` never pairs."

Headline evidence from r1. Every condition maps to code in the full function (`:825-943`, read end to end):

- Record kinds and no W: `[[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1` (`:832`) and `*) return 1 ;;` for any other record (`:852`).
- Commondir content exactly `../..\n`: `re="^file [0-7]+ $std\$"` with `std="$(_snap_hash_str $'../..\n')"` (`:856`, `:867-868`), applied to the removed record's attrs.
- Paired removed hooksdir `missing`: `hk="${rec:0:1}F"$'\t'"hooksdir"$'\t'"$(printf '%q' "$p/hooks")"$'\t'"missing"` then `[ -n "${left[$hk]:-}" ] || return 1` (`:869-870`).
- P gone: `[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`:873`).
- One removed, not-yet-used dotgit record whose attrs are `file <mode> H("gitdir: P\n")` or the container-form hash: `re="^file [0-7]+ ($h${g:+|$g})\$"` over `dot` keys starting `-` (`:876-881`); a second record with the same content stays unused and fails `:932` (paraphrased — no quote available because this follows from the `break` at `:880` combined with the final loop at `:932`).
- Old working tree: `_snap_unq "$q" wt || return 1`, strip `/.git`, `! looks_like_gitdir "$wt" || return 1` (`:886-889`). `looks_like_gitdir` on a missing path returns 1 (both `-e`/`-f` tests false), so "gone" passes (paraphrased — no quote available because it is the evaluation of `cc-gitdir.sh:87-90` on a nonexistent directory).

Test 4 (`bats …:2290-2322`) exercises the positive control, HEAD+objects/, lone commondir, and `$'…'` path; passed in the baseline. Mutations M1 (drop `:889`) and M2 (drop `:888`, so `.git` itself is tested) each turn test 4 red.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:825-943`, `devcontainer-config/cc-gitdir.sh:83-90`, `test/cc-isolated-functions.bats:2290-2322`, `fcB-r1x7/logs/bats-q094.txt`, `fcB-r1x7/logs/mut-M1-drop-llg.txt`, `fcB-r1x7/logs/mut-M2-dotgit-path.txt`

---

## Claim 4: "Paths are compared as the %q strings the records hold, recomputed from <n>; nothing is unquoted."

**Location:** `devcontainer-config/cc-exit-scan.sh:823-824`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "nothing is unquoted" clause against the function as of 2eebdf8; does not dispute that path *comparisons* still use recomputed `%q` strings (they do, e.g. `:866`, `:869`, `:916`).
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** r2: "The removed `dotgit` record's path is never compared at all (pairing is by content hash, :876-882)"; "it has no 'added' qualifier and 'nothing is unquoted' is absolute, so a reader takes it as covering the whole function" · r3: "The same doc comment's removal clause four lines earlier (`:815-817`, 'that record's directory (the old working tree)') presupposes this decode, so the comment now contradicts itself."

Headline evidence from r1. The sentence dates from unit A (added-only). 2eebdf8 added an unquote of a record-held path in the removal branch:

```bash
# devcontainer-config/cc-exit-scan.sh:886-889
      q="${ok%$'\t'*}"; q="${q#?F$'\t'dotgit$'\t'}"
      _snap_unq "$q" wt || return 1
      case "$wt" in */.git) wt="${wt%/.git}" ;; *) return 1 ;; esac
      ! looks_like_gitdir "$wt" || return 1
```

The removed dotgit path is taken from the record (not recomputed from `<n>`) and decoded. The precise version: "Paths are compared as recomputed %q strings; the one decode (`_snap_unq`, removal branch) is verified by re-quoting."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:823-824`, `devcontainer-config/cc-exit-scan.sh:886-889`

---

## Claim 5: "Its own `.git` file gone too: a removed dotgit record that held exactly "gitdir: P\n" (either form). Another worktree's .git never pairs."

**Location:** `devcontainer-config/cc-exit-scan.sh:874-875`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pairing by content hash of this `<n>`'s `gitdir:` line, host or container form, and that a `.git` pointing at a different P does not pair; does not establish behaviour against a deliberate 64-bit hash-prefix collision (the snapshot keeps 16 hex digits of sha256).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that two `.git` files with identical content pointing at the same P could not both exist (the second would stay unused and decline, `:932`)" · r3: "does not establish anything about a `.git` that some other worktree held with content naming this P (such a file points at P and so is not 'another worktree's' in git's sense)"

Headline evidence from r2. The pattern is built only from this worktree's P (`gitdir: $p` / `gitdir: $ccommon/worktrees/$n`, at :876-878), and already-used records are skipped (:880). R1 test 6 (`test/cc-isolated-functions.bats:2336-2348`) removes agent-a's git dir and agent-b's `.git`, and asserts status 1 with `*"- dotgit $SCAN_WS/.claude/worktrees/agent-b/.git "*`; it passes.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:874-883`, `test/cc-isolated-functions.bats:2336-2348`, `fcB-r2x7/logs/bats-q094-baseline.txt`

---

## Claim 6: "The old working tree, if still there, must not look like a git dir: a repository left in its place is not "removed"."

**Location:** `devcontainer-config/cc-exit-scan.sh:884-885`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old working-tree root itself (HEAD-next-to-objects/ or a regular `commondir` file there declines; a `.git` recreated there declines via its record); does not establish anything about a git-dir layout placed in a subdirectory of the old working tree, which is accepted with the note (E4) — as a bare layout anywhere else in the checkout below the root would be.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish detection of a repository in a subdirectory of it, or of a `.git` reached through a symlinked parent (Claim 7b)" · r2: "a nested `.git` entry would show as its own `+ dotgit` record and decline; a bare layout in a subdirectory is not examined"; "R4 P4: the old path replaced by a symlink to an outside dir holding `HEAD` + `objects/` also declines (status 1), because the tests follow the link"

Headline evidence from r3. Code: `! looks_like_gitdir "$wt" || return 1` after `wt="${wt%/.git}"` (`devcontainer-config/cc-exit-scan.sh:888-889`). Test `a removal whose old working tree now looks like a git dir warns` passes (ok 4, `reviews/B-fc-r3-logs/baseline.txt`). Executed E6 (HEAD a dangling symlink, `objects` a symlink to a dir) → warns; E7 (`commondir` a directory, not a file) → note, consistent with `[ -f "$d/commondir" ]`; E4 (`sub/HEAD` + `sub/objects/` under the old tree) → note (`reviews/B-fc-r3-logs/experiments.txt`, exit 0, 2026-09-29T03:19:41Z).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:884-891`, `devcontainer-config/cc-gitdir.sh:87-90`, `test/cc-isolated-functions.bats:2290-2322`, `reviews/B-fc-r3-logs/experiments.txt`

---

## Claim 7a: Note reason for added-only: "They take config and hooks from the checkout's own .git", and the combined form "…, and added ones take config and hooks from the checkout's own .git"

**Location:** `devcontainer-config/cc-exit-scan.sh:937-942`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which reason is printed for added-only, removed-only and mixed differences; the underlying git-behaviour premise (linked worktrees read config/hooks from the common dir) is unit A's and not re-verified here.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "The `&& … ||` chain cannot misfire: a plain assignment always returns 0."

Headline evidence from r1.

```bash
# devcontainer-config/cc-exit-scan.sh:937-942
  why="They take config and hooks from the checkout's own .git"
  if [ "${#removed[@]}" -gt 0 ]; then
    [ "${#added[@]}" -eq 0 ] && why="Removed ones left no git dir behind" ||
      why="Removed ones left no git dir behind, and added ones take config and hooks from the checkout's own .git"
  fi
  echo "note: exit scan: only linked worktrees in git's standard layout changed (${line% }). $why, so this is not a finding."
```

The added-only reason is printed only when `removed` is empty. Test 3 asserts the mixed wording and test 4 the removed-only wording; both passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:933-943`, `test/cc-isolated-functions.bats:2273-2276`, `test/cc-isolated-functions.bats:2299`, `fcB-r1x7/logs/bats-q094.txt`

---

## Claim 7b: Note reason for removals: "Removed ones left no git dir behind"

**Location:** `devcontainer-config/cc-exit-scan.sh:939-940`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three places the code checks (P, the old working-tree dir, and its `.git` entry via the record being absent at exit); does not establish absence of a git dir in subdirectories of the old tree or at a `.git` reached through a symlinked path component.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish the absence of git dirs the branch never examines (subdirectories of the old tree, which the scan in general does not search for bare layouts)" · r3: "does not establish that no git-dir layout exists deeper under the old working tree (E4 prints this note with one at `<old wt>/sub`)" · r1's stated decision: "Rated 7b Mostly accurate rather than Incorrect, because the symlink target has to lie outside the checkout (not writable by the container) and the same limit applies to the whole scan." · r1 escalation: the symlinked-parent probe as a possible "Known routes" entry

Headline evidence from r1. What the code rules out: P exists in no form (`:873`), the old tree dir does not pass `looks_like_gitdir` (`:889`), and `<wt>/.git` produced no record at exit (any `.git` entry found by `find -P "$_snap_ws" -mindepth 2 -name .git`, `:694`, would be a `+` dotgit record left unused, which declines at `:932`). The qualifier that is missing: `find -P` does not descend into a symlinked directory. Probe (scratch copy only): after `git worktree remove`, `.claude/worktrees` was replaced by a symlink to a directory outside the checkout holding `agent-y/.git` as a bare repository. Command `TMPDIR=$D/tmp LC_ALL=C bats -f 'PROBE2' test/cc-isolated-functions.bats`; cwd `fcB-r1x7/probe`; exit 0; output `status=0 output=note: exit scan: … (removed: agent-y). Removed ones left no git dir behind, so this is not a finding.` while `$STD_WT/.git` resolved to a full git dir. (The same symlink route exists for any embedded repo and is a general scan limit, not new in B; the "Known routes" list at `guides/cc-isolated-usage.md:362-420` does not name it. When the symlink points inside the checkout, `find` reaches the target by its real path and the scan warns: first PROBE run, `fcB-r1x7/logs/probe.txt`.) Precise version: "Removed ones left no git dir at the private dir, the old working tree, or its .git."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:873`, `devcontainer-config/cc-exit-scan.sh:889`, `devcontainer-config/cc-exit-scan.sh:694`, `devcontainer-config/cc-exit-scan.sh:932`, `fcB-r1x7/probe/test/cc-isolated-functions.bats` (appended PROBE tests), `fcB-r1x7/logs/probe.txt`, `fcB-r1x7/logs/probe2.txt`

---

## Claim 8: "Only linked worktrees added or removed in git's standard layout (STANDARD WORKTREES above): a note, not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:979-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch that follows this comment (quoted in Claim 1, :982-985) and that it applies only when no invalid-gitdir finding is pending; does not re-establish the acceptance rule, which is Claims 3 and 6.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Headline evidence from r2. The guard is `if [ -z "$invalid" ] && note="$(scan_std_worktrees …)"` (`cc-exit-scan.sh:982`); on success it prints the note and returns 0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:966-985`

---

## Claim 9: Plan rule 6 (as changed in 2eebdf8) — "The stacked unit accepts a removal when the difference removes exactly `hooksdir P/hooks missing` and `commondir-file P/commondir file <mode> H("../..\n")`, `P` no longer exists on disk, and one removed `dotgit` record held exactly `gitdir: P\n` (either form), and that record's directory (the old working tree) is gone or fails `looks_like_gitdir` (… a path `%q` writes as `$'…'` is not decoded and warns). … Pairing is now by content."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule-6 conditions as 2eebdf8 implements them and the `$'…'` decline; does not verify the historical statements (review iterations, "447 lines", decision-log row 62), which are unit-A context.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: tab-path probe (`PROBE removed tab path`, `fcB-r1x7/logs/probe.txt`: `status=1`) warns · r3: "with `é` it warns in C locale and is accepted in C.UTF-8 (where `%q` writes it raw, so the rule's condition does not apply)"

Headline evidence from r2. Same code as Claims 3 and 6. The `$'…'` decline is `case "$q" in \$\'*|\'*|"") return 1 ;; esac` (`cc-exit-scan.sh:788`), exercised by R1 test 4's newline path (`test/cc-isolated-functions.bats:2313-2322`); mutation M4 (accept on decode failure) fails that step at :2320.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `devcontainer-config/cc-exit-scan.sh:786-796`, `devcontainer-config/cc-exit-scan.sh:872-892`, `fcB-r2x7/logs/mut-M4_accept_on_decode_failure.txt`

---

## Claim 10: Plan risk row B18 — "paths are compared as the `%q` string recomputed from the parsed name, never unquoted"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:90`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "never unquoted" part as it applies to the unit-B removal path; does not dispute the row's `<n>` restriction (rule 4) or its "covered" status for odd names (the decode declines `$'…'` and re-quote-checks the rest, Claim 2).
**Replicate verdicts:** r1=Stale · r2=— · r3=Stale
**Replicate annotations:** r1: "The row, which covers `$'…'` and odd names, now misdescribes the removal branch the same way Claim 4 does." · r1's stated decision: "Included plan row B18 (unit A text) because 2eebdf8 made it stale; the alternative was to treat it as out-of-range context."

Headline evidence from r3. The row (unit A text, true for unit A) was not updated when 2eebdf8 added `_snap_unq "$q" wt` (`devcontainer-config/cc-exit-scan.sh:887`), and it now contradicts the same doc's rule 6 at `:60` ("a path `%q` writes as `$'…'` is not decoded"), which presupposes decoding other paths. 2eebdf8's "Guide and plan rule 6 updated to match" is accurate for rule 6 alone.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `docs/working/plan-q094-exit-scan-worktree-layout.md:90`, `devcontainer-config/cc-exit-scan.sh:887`

---

## Claim 11: "A linked worktree added or removed in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` returning 0 with one note for a removal (executed) and the launcher mapping a 0 scan to claude's status (unit A test 12, executed for an addition); does not establish a launcher run with a removal specifically.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the launcher's pass-through of claude's status is unit A's and covered by test 12 (passed), not re-read here" · r2: "does not establish a live host session" · r1 and r2 gave Confidence High

Headline evidence from r3. `git_exit_scan` returns 0 with the note (Claim 1, `devcontainer-config/cc-exit-scan.sh:981-985`). The launcher path is identical for added and removed (paraphrased — no quote available because the launcher's handling of scan status lives in `cc-isolated.sh` and does not branch on add vs remove; r3 did not re-read it for this unit). Test 12 `a session that leaves an agent worktree ends the launcher with claude's status and a note` passes (`reviews/B-fc-r3-logs/baseline.txt`).

**Evidence:** `guides/cc-isolated-usage.md:66-68`, `devcontainer-config/cc-exit-scan.sh:981-985`, `reviews/B-fc-r3-logs/baseline.txt`, `reviews/B-fc-r3-logs/experiments.txt`

---

## Claim 12a: "…or removed (`git worktree remove`: git dir and `.git` file both gone) in the exact layout git writes"

**Location:** `guides/cc-isolated-usage.md:335-337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both-gone being required (P gone on disk; `.git` record removed with no replacement record); does not establish acceptance of a removal done by other means (a manual `rm -rf` of both is accepted too — test 3's last step).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish other git versions' removal layout" · r2: "nor the example note text's `(added: agent-x)` for removals (it prints `removed:`; the example is labelled as the added case)"

Headline evidence from r3. `[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`devcontainer-config/cc-exit-scan.sh:873`) and the removed-dotgit pairing (`:876-883`). E1 shows `git worktree remove` drops exactly the three records (commondir-file, dotgit, hooksdir) and yields the note (`reviews/B-fc-r3-logs/experiments.txt`).

**Evidence:** `guides/cc-isolated-usage.md:335-337`, `devcontainer-config/cc-exit-scan.sh:872-883`, `reviews/B-fc-r3-logs/experiments.txt`

---

## Claim 12b: "For a removal, "exact" means the private dir is gone and the removed records are the ones git's layout makes (the `.git` file named that dir), and the old working-tree directory is gone or does not look like a git dir (no `HEAD` next to `objects/`, no `commondir` file); a working-tree path with a newline or other byte that bash's `%q` quotes as `$'…'` warns."

**Location:** `guides/cc-isolated-usage.md:342-346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paraphrase of `looks_like_gitdir` (matches `cc-gitdir.sh:89`: HEAD of any type with an `objects/` dir, or a regular-file `commondir`) and the `$'…'` decline; does not establish the symlinked-parent case (Claim 7b), which the paragraph does not address.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish which bytes bash quotes as `$'…'` beyond those R2 generated (all control bytes and, in C locale, all high bytes did)" · r3: "including locale dependence (whether a byte is `$'…'`-quoted depends on the locale, which the sentence's wording already defers to); does not establish anything about subdirectories of the old working tree (Claim 6)"; "a `commondir` directory is not a file and is accepted: E7"

Headline evidence from r1. `looks_like_gitdir`: `{ { [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]` (`devcontainer-config/cc-gitdir.sh:89`). Decline of `$'…'`: `cc-exit-scan.sh:788`, `:887`; newline (test 4) and tab (probe) paths warn. r1's fuzz runs show no path other than `$'…'`/`''` forms is declined, so "warns" is not hiding a wider decline set.

**Evidence:** `guides/cc-isolated-usage.md:342-346`, `devcontainer-config/cc-gitdir.sh:83-90`, `devcontainer-config/cc-exit-scan.sh:788`, `devcontainer-config/cc-exit-scan.sh:887`, `fcB-r1x7/logs/bats-q094.txt`, `fcB-r1x7/logs/probe.txt`, `fcB-r1x7/logs/unq-C.txt`

---

## Claim 13: "Anything else warns as before, worktree lines included — also any other change in the session, a working tree deleted without a prune, …"

**Location:** `guides/cc-isolated-usage.md:352-354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a working tree deleted while its private dir remains; does not cover a later `git worktree prune` (which removes P and then yields an accepted removal, consistent with "without a prune").
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "R4 P2/P3 (only HEAD, only commondir deleted) both give status 1"

Headline evidence from r1. `[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`cc-exit-scan.sh:873`). Test 3: `rm -rf "$SCAN_WS/.claude/worktrees/agent-x"` then `[ "$status" -eq 1 ]` and `- dotgit …agent-x/.git` listed (`test/cc-isolated-functions.bats:2277-2281`); passed.

**Evidence:** `guides/cc-isolated-usage.md:352-354`, `devcontainer-config/cc-exit-scan.sh:873`, `test/cc-isolated-functions.bats:2277-2288`, `fcB-r1x7/logs/bats-q094.txt`

---

## Claim 14: Test names vs assertions — "a removed standard worktree is a note; a half-removed one warns", "a removal whose old working tree now looks like a git dir warns", "_snap_unq: inverts printf %q's backslash form; other forms decline", "a removed git dir pairs only with the .git that pointed at it"

**Location:** `test/cc-isolated-functions.bats:2263`, `test/cc-isolated-functions.bats:2290`, `test/cc-isolated-functions.bats:2324`, `test/cc-isolated-functions.bats:2336`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test's assertions exercise what its name says and that each passes at 2eebdf8; does not establish that the names list everything asserted (test 2290 also holds a positive control and the `$'…'` decline; test 2324's "other forms" are `$'…'`, `''` and the malformed `a\`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "test 3's final step asserts only the status, not the note text" · r3: "does not establish that the `_snap_unq` test's third decline case (`a\`) is a `%q` 'form' — it is a malformed input, which the name's 'other forms' loosely includes"

Headline evidence from r1.
- 2263: note for `worktree remove` (`[ "$status" -eq 0 ]`, `(removed: agent-y).`), warn after `rm -rf` of a tree and after hiding P (`[ "$status" -eq 1 ]`).
- 2290: HEAD+objects/ → `[ "$status" -eq 1 ]` and `[[ "$output" != *"note:"* ]]`; commondir alone → same.
- 2324: `for s in plain/path "a b/c" "x${bs}y" "~t" "q${sq}uote" "semi;&|" "*?[]"` round-trips; `run ! _snap_unq "$(printf '%q' "new\nline")"`, `run ! _snap_unq "$sq$sq"`, `run ! _snap_unq "a$bs"`. `run !` is supported by bats 1.8.2 (used here).
- 2336: two half-removals of different worktrees → `status 1`, `- dotgit …agent-b/.git`.

All four passed in the baseline run.

**Evidence:** `test/cc-isolated-functions.bats:2263-2348`, `fcB-r1x7/logs/bats-q094.txt`

---

## Claim 15a: commit 1f31b18 — "A worktree removed with `git worktree remove` drops three records: its .git file, its private dir's commondir, and the missing hooks/."

**Location:** commit `1f31b18` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout with no global/system git config (the test and experiment setup); does not establish the record set when your own global config adds records for the worktree (e.g. an `includeIf gitdir:` matching it, walked by `_snap_host_config`), which would add records and make the removal warn.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Headline evidence from r3. E1 in `reviews/B-fc-r3-logs/experiments.txt` (exit 0, 2026-09-29T03:19:41Z): the `diff` of before/after snapshots lists exactly `commondir-file …/agent-y/commondir file 644 …`, `dotgit …/agent-y/.git file 644 …`, `hooksdir …/agent-y/hooks missing`. r1 (tab-path probe) and r2 (R4 P5) report the same three records.

**Evidence:** `reviews/B-fc-r3-logs/experiments.txt`, `devcontainer-config/cc-exit-scan.sh:573-596`

---

## Claim 15b: commit 1f31b18 — acceptance conditions list, including "the private dir P is gone on disk (a dir made invisible to the scan by deleting HEAD or commondir but left in place still warns)", "Pairing is by content, not count" and "Anything else, including a working tree deleted without a prune, warns."

**Location:** commit `1f31b18` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed condition and the HEAD-only and commondir-only invisibility cases individually; does not re-verify the historical "security review iteration 1 showed count pairing…" reference.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "the conditions are a subset of the final rule; 2eebdf8 added the old-tree check afterwards; deleting HEAD alone or commondir alone (rather than both, as the test does) is verified statically only" · r2: "does not verify the unit-A-era history ('reviewed in iteration 1', …)"; executed R4 P2 (HEAD only) and P3 (commondir only), both warn

Headline evidence from r3. `_snap_nested` finds git dirs with `find … -name HEAD` then `looks_like_gitdir` (`devcontainer-config/cc-exit-scan.sh:562-566`), so deleting either file hides P; the removal branch then fails `[ ! -e "$p" ]` (`:873`). E2 (HEAD only) and E3 (commondir only) both `rc=1` with the warning (`reviews/B-fc-r3-logs/experiments.txt`). The test covers only both deleted together (`test/cc-isolated-functions.bats:2281-2283`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:555-567`, `devcontainer-config/cc-exit-scan.sh:873`, `reviews/B-fc-r3-logs/experiments.txt`

---

## Claim 16: commit 1f31b18 Notes — "89 changed code lines."

**Location:** commit `1f31b18` message (Notes)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count of the commit's own diff; does not establish which counting rule the decision-log size cap uses.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate
**Replicate annotations:** r2 (not surfaced as a claim; its 1f31b18 claim's scope): "does not verify the unit-A-era history ('reviewed in iteration 1', '89 changed code lines')" · r3: "(Output was read from the terminal, not captured; rerun the command to reproduce.)"

Headline evidence from r1. `git show 1f31b18 --numstat`: `cc-exit-scan.sh 32/13`, `guides/cc-isolated-usage.md 5/4`, `test/cc-isolated-functions.bats 33/2` — 70 insertions + 19 deletions = 89, of which 9 are guide (documentation) lines; code and test files alone are 80. Precise version: "89 changed lines (80 in code and tests)". Command run in cwd `/workspace/.claude/worktrees/agent-aaad54fc687b7548c` (read-only `git show`), exit 0, 2026-09-29T03:26Z; output reproduced in this paragraph (read-only git metadata, deterministic).

**Evidence:** commit `1f31b18` (`git -C <repo> show 1f31b18 --numstat --format=`)

---

## Claim 17: commit fc56eca — "the scan_std_worktrees comment now names the removed records' exact content ("../..\n", hooks "missing"), and the guide says which of the "exact" layout checks apply to a removal. No behaviour change."

**Location:** commit `fc56eca` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that fc56eca's diff touches only comment lines in `cc-exit-scan.sh` and guide prose; does not re-verify fc56eca's guide wording, which 2eebdf8 later rewrote (checked as Claim 12b).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not re-verify the fact-check iteration it cites"

Headline evidence from r1. `git show fc56eca -- devcontainer-config` filtered to non-comment `+`/`-` lines returns nothing (only the `---`/`+++` headers); stat is `cc-exit-scan.sh 5 +++--`, `guides/cc-isolated-usage.md 4 +++-`. The comment at 2eebdf8 names `` `hooksdir P/hooks missing` `` and `"../..\n"` (`cc-exit-scan.sh:813-815`).

**Evidence:** commit `fc56eca`, `devcontainer-config/cc-exit-scan.sh:813-815`

---

## Claim 18a: commit 2eebdf8 — change description and test list: "The removal branch of scan_std_worktrees now decodes the removed dotgit record's path (a new _snap_unq, printf %q's backslash form only, verified by re-quoting) and declines when that directory passes looks_like_gitdir (cc-gitdir.sh). A path %q writes as $'...' is not decoded and declines (warns)." / "Tests: a removal with the old dir back holding ordinary files (note, positive control), then HEAD next to objects/ (warns), then a lone commondir file (warns), then a $'...' path (warns); _snap_unq round trips." / "Guide and plan rule 6 updated to match."

**Location:** commit `2eebdf8` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the described code change, the four-step test sequence and the `_snap_unq` test, and the guide and plan rule 6 edits; does not extend "plan updated to match" to plan row B18, which was not updated (Claim 10).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Headline evidence from r3. Code: Claims 2–3. Tests: `test/cc-isolated-functions.bats:2290-2334` in that order (Claim 14); pass (`reviews/B-fc-r3-logs/baseline.txt`). Guide `:342-346` and plan `:60` edited in 2eebdf8 (`git diff 9075003 2eebdf8`).

**Evidence:** commit `2eebdf8`, `devcontainer-config/cc-exit-scan.sh:783-797`, `devcontainer-config/cc-exit-scan.sh:884-889`, `test/cc-isolated-functions.bats:2290-2334`, `reviews/B-fc-r3-logs/baseline.txt`

---

## Claim 18b: commit 2eebdf8 — "Mutations that drop the looks_like_gitdir check, check the .git path instead of its dir, skip the re-quote check, or accept on a decode failure each fail a test."

**Location:** commit `2eebdf8` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test list and the four named mutations as r1 implemented them; does not establish that every conceivable variant of "accept on a decode failure" is caught (the variant `_snap_unq … || true` survives, but it still declines — see below — so it is not an acceptance).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "the commit does not record its exact mutants, so 'accept on a decode failure' was rendered as `_snap_unq \"$q\" wt || { used[\"$ok\"]=1; removed+=(\"$n\"); continue; }`" · r3: extra mutation `no-form-case` (delete `_snap_unq`'s `case` line) survives, "none (re-quote check covers it)"; r3's decode-failure rendering (`decode-fail-skip`) fails test 4 at `:2320`

Headline evidence from r1. Mutations, each applied to a fresh copy of the tree by `mut.sh` and run with `bats -f 'Q-094|_snap_unq'`:

| Mutation | Change | Exit | Failing test | Log |
|---|---|---|---|---|
| M1 drop looks_like_gitdir | delete `:889` | 1 | 4 | `fcB-r1x7/logs/mut-M1-drop-llg.txt` |
| M2 test `.git` path | delete `:888` | 1 | 4 | `fcB-r1x7/logs/mut-M2-dotgit-path.txt` |
| M3 skip re-quote | delete `:794` | 1 | 5 | `fcB-r1x7/logs/mut-M3-no-requote.txt` |
| M4a accept on decode failure | `\|\| { used["$ok"]=1; removed+=("$n"); continue; }` | 1 | 4 | `fcB-r1x7/logs/mut-M4a-accept-on-fail.txt` |
| M4b ignore decode failure | `\|\| true` | 0 | none | `fcB-r1x7/logs/mut-M4b-ignore-fail.txt` |

M4b survives but still declines: `wt` then holds either nothing or a value without a `/.git` suffix left from an earlier loop pass (`wt="$wsp/$wtrel"`, `:911`, or the stripped removal value, `:888`), so `case "$wt" in */.git) … *) return 1` (`:888`) returns 1 (paraphrased — no quote available because this is the combination of the two assignments with the case at `:888`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:786-796`, `devcontainer-config/cc-exit-scan.sh:884-891`, `test/cc-isolated-functions.bats:2290-2334`, `fcB-r1x7/mut.sh`, `fcB-r1x7/logs/mut-M1-drop-llg.txt`, `fcB-r1x7/logs/mut-M2-dotgit-path.txt`, `fcB-r1x7/logs/mut-M3-no-requote.txt`, `fcB-r1x7/logs/mut-M4a-accept-on-fail.txt`, `fcB-r1x7/logs/mut-M4b-ignore-fail.txt`

---

## Claim 19: commit 2eebdf8 Notes — "Declining (not accepting) an undecodable path is the fail-closed choice; the added side already declines such paths (its back-pointer read is one line)."

**Location:** commit `2eebdf8` message (Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added branch's handling of worktree paths that `%q` writes as `$'…'`; does not assess whether accepting such added paths is a security problem (not a fact-check question).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2: "does not say the added side is unsafe for them (it accepts only after the same layout checks as for any path). The consequence is an add/remove asymmetry that fails closed, not an acceptance hole"; "a tab-path worktree that got the note when added warns when removed" · r3: "does not dispute that declining is fail-closed, nor that the added side declines a path containing a newline"; executed: ADD with a tab → note in both locales, ADD with `é` in C locale → note, ADD with a newline → warns, REMOVE with a tab → warns · r1 escalation: security-reviewer may want the tab/control-byte added-path behaviour

Headline evidence from r1. "Such paths" means paths `%q` writes as `$'…'`. The stated mechanism, a one-line back-pointer read (`line="$(_snap_first_line "$p/gitdir" …)"`, `cc-exit-scan.sh:902`, then `_snap_file_is "$p/gitdir" "$(_snap_hash_str "$line"$'\n')"`, `:903`), only rejects a path containing a **newline**. Other bytes that `%q` quotes as `$'…'` (tab, control bytes) pass it, and the added branch never decodes a path — it recomputes `printf '%q' "$wt/.git"` for the lookup (`:914`). Probe (scratch copy): command `TMPDIR=$D/tmp LC_ALL=C bats -f 'PROBE' test/cc-isolated-functions.bats`; cwd `fcB-r1x7/probe`; exit 0; 2026-09-29T03:24:58Z; results `PROBE added tab path`: `status=0 output=note: … (added: agent-t). They take config and hooks …`; `PROBE added ctrl-A path`: `status=0 … (added: agent-c)`. So the added side accepts tab and control-byte paths that the removal side declines. Precise version: "the added side declines paths with a newline (its back-pointer read is one line); other `$'…'` paths are accepted there, since it never unquotes."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:895-925`, `fcB-r1x7/probe/test/cc-isolated-functions.bats` (appended PROBE tests), `fcB-r1x7/logs/probe.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (commit `2eebdf8`, Notes): "the added side already declines such paths" holds only for newline paths; a worktree added at a path with a tab or control byte (or, in C locale, a high byte) gets the note, while its removal warns (all three replicates, executed). Reword to "declines newline paths", or make the two sides consistent.

### Stale
- **Claim 4** (`devcontainer-config/cc-exit-scan.sh:823-824`): "nothing is unquoted" became false in 2eebdf8, which decodes the removed `.git` record's path with `_snap_unq` (`:886-887`). Add the exception.
- **Claim 10** (`docs/working/plan-q094-exit-scan-worktree-layout.md:90`, row B18): "never unquoted" is the same change, and now contradicts rule 6 as edited in 2eebdf8.

### Mostly Accurate
- **Claim 7b** (`devcontainer-config/cc-exit-scan.sh:939-940`): "Removed ones left no git dir behind" is true for P, the old tree root and its `.git` entry. It is not true through a symlinked parent that `find -P` skips (r1 probe: the note printed while `<old wt>/.git` resolved to a bare repo outside the checkout), nor for a layout in a subdirectory of the old tree (r2/r3 scope; r3 E4).
- **Claim 16** (commit `1f31b18`): "89 changed code lines" counts 9 guide lines; 80 are code and tests.

### Unverifiable
- (none)

---

## Goal-Alignment Note
- Success criterion (restated verbatim): Merged canonical fact-check reports for units A and B, schema-conformant
- Answered: yes for unit B. 23 merged claims from 20 (r1), 17 (r2) and 21 (r3) replicate claims; every replicate claim maps to at least one merged claim.
- Out of scope: new verification of any kind (this is collation only); unit A (its own merged report); the replicates' own out-of-scope items (r1: judging whether the added side should decline `$'…'` paths and whether the symlinked-parent route matters for security, both left to security-reviewer; hallucination-pattern log not updated, since the Incorrect is a behavioural misstatement, not a fabricated symbol).
- Escalate: see `## Escalations` (three entries, all addressed to security-reviewer).
- Decisions I made: (1) The `:979-980` git_exit_scan comment, which r1 and r3 folded into their header-comment claim, is its own claim (Claim 8, from r2), with r1/r3 recorded as `(compound)`. (2) Guide `:335-337` and `:342-346` are split (Claims 12a/12b) because r1 and r3 split them; r2's single guide claim is carried as `(compound)` on both. (3) The 1f31b18 and 2eebdf8 commit messages are split to r3's granularity (15a/15b, 18a/18b); the "89 changed code lines" note is its own claim (16) because r1 and r3 verdicted it separately. (4) Where tied replicates had equally specific Scope lines, the lowest replicate number supplied the evidence.

---

## Escalations

- **commit `2eebdf8` message (Notes); `devcontainer-config/cc-exit-scan.sh:895-925`** (Claim 19): the added side accepts worktree paths with a tab, control byte or (C locale) high byte, which the removal side declines; a worktree that got the note when added warns when removed. Raised by r1 ("Escalate: Claim 18 … security-reviewer may want the tab/control-byte added-path behaviour"; Out of scope: "judging whether the added side should decline `$'…'` paths … (security-reviewer's call)") and r3 ("advisory residues for the security reader … (b) Add and remove handle `$'…'` paths differently"). Addressee: security-reviewer.
- **`devcontainer-config/cc-exit-scan.sh:694`, `devcontainer-config/cc-exit-scan.sh:939-940`** (Claim 7b): symlinked-parent route. After a standard removal, a symlinked `.claude/worktrees` pointing outside the checkout can hold a git dir at the old `.git` path; `find -P` does not follow it and the note prints. r1 suggests it as a possible "Known routes" entry in `guides/cc-isolated-usage.md:362-420`. Raised by r1 (Escalate; Out of scope: "whether the symlinked-parent route matters for security (security-reviewer's call)"). Addressee: security-reviewer.
- **`devcontainer-config/cc-exit-scan.sh:884-889`** (Claims 6, 7b): a git-dir layout in a *subdirectory* of the removed working tree still gets the "left no git dir behind" note (r3 E4). This matches the scan's general blindness to bare layouts below the checkout root, and is not listed under "Known routes it does not see". Raised by r3 ("advisory residues for the security reader … (a)"). Addressee: security-reviewer.

---

## Verdict stability

- Total clusters (merged claim rows, sub-claims counted separately): 23
- Clusters where all reporting replicates agreed: 22 (no single-replicate detections; Claims 10 and 16 were reported by two replicates, which agreed)
- Clusters where verdicts disagreed: 1
  - Claim 7b: r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
- Agreement rate: 22/23 = 95.7% on a 23-claim sample. Pooled with unit A from the same run (41/57), the rate is 63/80 = 78.8%, below the ≥90% bar for dropping to k=2.
