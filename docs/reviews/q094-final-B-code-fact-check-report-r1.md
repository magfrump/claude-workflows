# Code Fact-Check Report

**Commit:** 2eebdf8
**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094b-exit-scan-worktree-removal`)
**Scope:** Unit B diff `9075003..2eebdf8` (commits 1f31b18, fc56eca, 2eebdf8): `devcontainer-config/cc-exit-scan.sh`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, plus the three commit messages; unit A (`dfe4c0d..9075003`) read as context where B interacts with it.
**Checked:** 2026-09-28 (executions stamped in UTC, 2026-09-29T03:11Z–03:27Z)
**Total claims checked:** 20
**Summary:** 15 verified, 2 mostly accurate, 2 stale, 1 incorrect, 0 unverifiable

Execution setup (shared by every `executed` claim): tree extracted with `git -C <repo> archive 2eebdf8 | tar -x -C $D/tree`, `D=/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcB-r1x7`; bash 5.2.15, bats 1.8.2, git 2.39.5; all bats runs as `TMPDIR=$D/tmp LC_ALL=C bats -f '<filter>' test/cc-isolated-functions.bats`. Captured output lives under `$D/logs/`. Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern (the closest family, test-count tallies in commit messages, does not occur: 2eebdf8 lists tests by content, not count).

Baseline run — command: `TMPDIR=$D/tmp LC_ALL=C bats -f 'Q-094|_snap_unq' test/cc-isolated-functions.bats`; cwd `$D/tree`; exit 0; 2026-09-29T03:11:45Z; 12/12 ok; output `$D/logs/bats-q094.txt`.

---

## Claim 1: "STANDARD WORKTREES (Q-094 [1]). When every difference is a linked worktree added or removed in git's own layout … the scan prints one `note:` and returns 0" (and the same "added or removed" wording at `git_exit_scan`)

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`, `devcontainer-config/cc-exit-scan.sh:979-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `git_exit_scan` returns 0 with one note for an added-only, removed-only and mixed difference when `scan_std_worktrees` accepts; does not establish the exact acceptance rule (Claims 3, 6) or behaviour when `invalid` is set (the note path is skipped then).

`git_exit_scan` calls the acceptor and returns 0 on its success:

```bash
# devcontainer-config/cc-exit-scan.sh:982-985
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```

The acceptor now takes both `+` and `-` records of the three kinds (`[+-]F$'\t'dotgit$'\t'*) … [+-]F$'\t'commondir-file…`, `cc-exit-scan.sh:850-851`). The baseline run's test 3 asserts `status 0` and `(removed: agent-y).` for a removal and `(added: agent-z; removed: agent-y)` for the mix (`test/cc-isolated-functions.bats:2263-2276`), and passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:75-77`, `devcontainer-config/cc-exit-scan.sh:846-853`, `devcontainer-config/cc-exit-scan.sh:979-985`, `test/cc-isolated-functions.bats:2263-2276`, `$D/logs/bats-q094.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "_snap_unq <%q string> <var>: sets <var> to the string printf %q quoted, for its backslash form only ($'…' and '…' forms return 1). The result is checked by quoting it again, so a wrong decode declines instead of passing."

**Location:** `devcontainer-config/cc-exit-scan.sh:783-785`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every string whose `printf %q` output was produced and re-quoted in the same bash and locale (C and C.UTF-8 tested): either decoded exactly or declined, and every decline observed was a `$'…'`/`''` form; does not establish behaviour when the `%q` text was produced under a different locale than the one decoding it (launch and exit snapshots would have to run under different LC_CTYPE), which was not tested.

Full function read (`:786-796`):

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

The re-quote guard makes a wrong decode impossible to pass on its own: `printf %q` output evaluates back to its input, so it is injective; if `printf %q s == q == printf %q orig` then `s == orig` (paraphrased — no quote available because this is an argument about bash's quoting function, not a line of the repo). A backslash-form output never starts with `$'` or `'` because bash escapes a leading `$` or `'` (`\$`, `\'`). Executed checks:

- Every byte 1–255 in 10 contexts (bare, doubled, after `~`, before/after `#`, trailing backslash, inside a `/x/.git` path) plus 20 000 random byte strings — command `LC_ALL=C $D/unq.sh $D/tree` and `LC_ALL=C.UTF-8 $D/unq.sh $D/tree`; cwd `$D`; exit 0 both; 2026-09-29T03:18:24Z; result C: `ok=1947 declined=20589 (dollar/single-quote forms=20589) wrong=0`, C.UTF-8: `ok=2104 declined=20439 (… =20439) wrong=0`. No backslash-form output ever declined and no decode was wrong.
- 30 000 random printable-ASCII paths — `LC_ALL=C $D/unq2.sh $D/tree`; exit 0; 03:21:59Z; `ok=30000 declined=0 wrong=0`.

Mutation M3 (delete the re-quote line `:794`) makes test 5 fail (`not ok 5 _snap_unq: …`), via the malformed input `a\` which decodes to `a` without the guard.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:783-796`, `$D/unq.sh`, `$D/unq2.sh`, `$D/logs/unq-C.txt`, `$D/logs/unq-CUTF8.txt`, `$D/logs/unq-printable.txt`, `$D/logs/mut-M3-no-requote.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: scan_std_worktrees removal rule — "Only dotgit, commondir-file and hooksdir records differ, and the exit snapshot has no W record. Removed <n>: gone `hooksdir P/hooks missing` and `commondir-file P/commondir` of exactly "../..\n", P gone on disk, one gone `dotgit` record that held exactly "gitdir: P\n" (either form), and that record's directory (the old working tree) either gone or not looking like a git dir (looks_like_gitdir)."

**Location:** `devcontainer-config/cc-exit-scan.sh:808-818`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed condition against the removal branch (`:856-891`) and the final all-records-used loop (`:932`); does not establish that "the old working tree" check covers a path reached through a symlinked parent outside the checkout (it follows the symlink; see Claim 7b) or anything about the container form beyond hash equality.

Every condition maps to code in the full function (`:825-943`, read end to end):

- Record kinds and no W: `[[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1` (`:832`) and `*) return 1 ;;` for any other record (`:852`).
- Commondir content exactly `../..\n`: `re="^file [0-7]+ $std\$"` with `std="$(_snap_hash_str $'../..\n')"` (`:856`, `:867-868`), applied to the removed record's attrs.
- Paired removed hooksdir `missing`: `hk="${rec:0:1}F"$'\t'"hooksdir"$'\t'"$(printf '%q' "$p/hooks")"$'\t'"missing"` then `[ -n "${left[$hk]:-}" ] || return 1` (`:869-870`).
- P gone: `[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`:873`).
- One removed, not-yet-used dotgit record whose attrs are `file <mode> H("gitdir: P\n")` or the container-form hash: `re="^file [0-7]+ ($h${g:+|$g})\$"` over `dot` keys starting `-` (`:876-881`); a second record with the same content stays unused and fails `:932` (paraphrased — no quote available because this follows from the `break` at `:880` combined with the final loop at `:932`).
- Old working tree: `_snap_unq "$q" wt || return 1`, strip `/.git`, `! looks_like_gitdir "$wt" || return 1` (`:886-889`). `looks_like_gitdir` on a missing path returns 1 (both `-e`/`-f` tests false), so "gone" passes (paraphrased — no quote available because it is the evaluation of `cc-gitdir.sh:87-90` on a nonexistent directory).

Test 4 (`bats …:2290-2322`) exercises the positive control, HEAD+objects/, lone commondir, and `$'…'` path; passed in the baseline. Mutations M1 (drop `:889`) and M2 (drop `:888`, so `.git` itself is tested) each turn test 4 red (`$D/logs/mut-M1-drop-llg.txt`, `$D/logs/mut-M2-dotgit-path.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:825-943`, `devcontainer-config/cc-gitdir.sh:83-90`, `test/cc-isolated-functions.bats:2290-2322`, `$D/logs/bats-q094.txt`, `$D/logs/mut-M1-drop-llg.txt`, `$D/logs/mut-M2-dotgit-path.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "Paths are compared as the %q strings the records hold, recomputed from <n>; nothing is unquoted."

**Location:** `devcontainer-config/cc-exit-scan.sh:823-824`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "nothing is unquoted" clause against the function as of 2eebdf8; does not dispute that path *comparisons* still use recomputed `%q` strings (they do, e.g. `:866`, `:869`, `:916`).

The sentence dates from unit A (added-only). 2eebdf8 added an unquote of a record-held path in the removal branch:

```bash
# devcontainer-config/cc-exit-scan.sh:886-889
      q="${ok%$'\t'*}"; q="${q#?F$'\t'dotgit$'\t'}"
      _snap_unq "$q" wt || return 1
      case "$wt" in */.git) wt="${wt%/.git}" ;; *) return 1 ;; esac
      ! looks_like_gitdir "$wt" || return 1
```

The removed dotgit path is taken from the record (not recomputed from `<n>`) and decoded. The precise version: "Paths are compared as recomputed %q strings; the one decode (`_snap_unq`, removal branch) is verified by re-quoting."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:823-824`, `devcontainer-config/cc-exit-scan.sh:886-889`
**Legibility-target:** for-author

---

## Claim 5: "Its own `.git` file gone too: a removed dotgit record that held exactly "gitdir: P\n" (either form). Another worktree's .git never pairs."

**Location:** `devcontainer-config/cc-exit-scan.sh:874-875`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers content pairing of removed dotgit records to P by hash of `gitdir: P\n` / container form; does not establish that two `.git` files with identical content pointing at the same P could not both exist (the second would stay unused and decline, `:932`).

```bash
# devcontainer-config/cc-exit-scan.sh:876-882
      ok="" h="$(_snap_hash_str "gitdir: $p"$'\n')" g=""
      [ -z "$ccommon" ] || g="$(_snap_hash_str "gitdir: $ccommon/worktrees/$n"$'\n')"
      re="^file [0-7]+ ($h${g:+|$g})\$"
      for dk in "${!dot[@]}"; do
        if [ "${dk:0:1}" != - ] || [ -n "${used[${dot[$dk]}]:-}" ]; then continue; fi
        if [[ "${dot[$dk]##*$'\t'}" =~ $re ]]; then ok="${dot[$dk]}"; break; fi
      done
```

(excerpt ends :882; enclosing removal branch continues to :891 — read). Test 6 (`bats …:2336-2348`: agent-a's git dir removed, agent-b's `.git` removed) warns and lists `- dotgit …agent-b/.git`; passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:872-891`, `test/cc-isolated-functions.bats:2336-2348`, `$D/logs/bats-q094.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "The old working tree, if still there, must not look like a git dir: a repository left in its place is not "removed"."

**Location:** `devcontainer-config/cc-exit-scan.sh:884-885`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `looks_like_gitdir` test on the decoded old working-tree directory; does not establish detection of a repository in a subdirectory of it, or of a `.git` reached through a symlinked parent (Claim 7b).

`! looks_like_gitdir "$wt" || return 1` (`:889`), where `looks_like_gitdir` is `{ { [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]` (`cc-gitdir.sh:89`). Test 4 shows HEAD+objects/ and a lone commondir both warn, while objects/ plus an ordinary file is a note; M1 and M2 each break test 4.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:884-889`, `devcontainer-config/cc-gitdir.sh:83-90`, `test/cc-isolated-functions.bats:2290-2322`, `$D/logs/mut-M1-drop-llg.txt`, `$D/logs/mut-M2-dotgit-path.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7a: Note reason for added-only: "They take config and hooks from the checkout's own .git", and the combined form "…, and added ones take config and hooks from the checkout's own .git"

**Location:** `devcontainer-config/cc-exit-scan.sh:937-942`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which reason is printed for added-only, removed-only and mixed differences; the underlying git-behaviour premise (linked worktrees read config/hooks from the common dir) is unit A's and not re-verified here.

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

**Evidence:** `devcontainer-config/cc-exit-scan.sh:933-943`, `test/cc-isolated-functions.bats:2273-2276`, `test/cc-isolated-functions.bats:2299`, `$D/logs/bats-q094.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7b: Note reason for removals: "Removed ones left no git dir behind"

**Location:** `devcontainer-config/cc-exit-scan.sh:939-940`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three places the code checks (P, the old working-tree dir, and its `.git` entry via the record being absent at exit); does not establish absence of a git dir in subdirectories of the old tree or at a `.git` reached through a symlinked path component.

What the code rules out: P exists in no form (`:873`), the old tree dir does not pass `looks_like_gitdir` (`:889`), and `<wt>/.git` produced no record at exit (any `.git` entry found by `find -P "$_snap_ws" -mindepth 2 -name .git`, `:694`, would be a `+` dotgit record left unused, which declines at `:932`). The qualifier that is missing: `find -P` does not descend into a symlinked directory. Probe (scratch copy only): after `git worktree remove`, `.claude/worktrees` was replaced by a symlink to a directory outside the checkout holding `agent-y/.git` as a bare repository. Command `TMPDIR=$D/tmp LC_ALL=C bats -f 'PROBE2' test/cc-isolated-functions.bats`; cwd `$D/probe`; exit 0; run after 2026-09-29T03:24:58Z and before 03:26:39Z (not separately stamped); output `status=0 output=note: exit scan: … (removed: agent-y). Removed ones left no git dir behind, so this is not a finding.` while `$STD_WT/.git` resolved to a full git dir. (The same symlink route exists for any embedded repo and is a general scan limit, not new in B; the "Known routes" list at `guides/cc-isolated-usage.md:362-420` does not name it. When the symlink points inside the checkout, `find` reaches the target by its real path and the scan warns: first PROBE run, `$D/logs/probe.txt`.) Precise version: "Removed ones left no git dir at the private dir, the old working tree, or its .git."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:873`, `devcontainer-config/cc-exit-scan.sh:889`, `devcontainer-config/cc-exit-scan.sh:694`, `devcontainer-config/cc-exit-scan.sh:932`, `$D/probe/test/cc-isolated-functions.bats` (appended PROBE tests), `$D/logs/probe.txt`, `$D/logs/probe2.txt`
**Legibility-target:** for-author

---

## Claim 8: Plan rule 6 (as changed in 2eebdf8): accepts a removal when the difference removes exactly `hooksdir P/hooks missing` and `commondir-file P/commondir file <mode> H("../..\n")`, P no longer exists, one removed dotgit record held exactly `gitdir: P\n` (either form), "and that record's directory (the old working tree) is gone or fails `looks_like_gitdir` (… a path `%q` writes as `$'…'` is not decoded and warns)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rule 6's conditions against `:856-891` and the `$'…'` decline; does not re-verify the historical claims about review iterations 1 and 3 beyond the commit messages that record them.

Same code as Claim 3. The `$'…'` decline: `case "$q" in \$\'*|\'*|"") return 1 ;; esac` (`cc-exit-scan.sh:788`) then `_snap_unq "$q" wt || return 1` (`:887`). Test 4's newline path and a scratch probe with a tab path (`PROBE removed tab path`, `$D/logs/probe.txt`: `status=1`, lists `- dotgit $'…/odd\tdir/agent-t/.git'`) both warn.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `devcontainer-config/cc-exit-scan.sh:788`, `devcontainer-config/cc-exit-scan.sh:856-891`, `test/cc-isolated-functions.bats:2313-2321`, `$D/logs/probe.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: Plan edge-case row B18: "paths are compared as the `%q` string recomputed from the parsed name, never unquoted"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:90`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "never unquoted" clause (unit A text, unchanged by B) against 2eebdf8's code; does not dispute the rest of the row (name restriction to `[A-Za-z0-9._-]`).

2eebdf8 decodes the removed dotgit record's path: `_snap_unq "$q" wt || return 1` (`devcontainer-config/cc-exit-scan.sh:887`). The row, which covers `$'…'` and odd names, now misdescribes the removal branch the same way Claim 4 does.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:90`, `devcontainer-config/cc-exit-scan.sh:886-889`
**Legibility-target:** for-author

---

## Claim 10: "A linked worktree added or removed in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the note/status-0 outcome in `git_exit_scan` for removals; the launcher's pass-through of claude's status is unit A's and covered by test 12 (passed), not re-read here.

See Claim 1 (`cc-exit-scan.sh:982-985`); test 3 shows `status 0` with a removal.

**Evidence:** `guides/cc-isolated-usage.md:66-68`, `devcontainer-config/cc-exit-scan.sh:982-985`, `$D/logs/bats-q094.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "…or removed (`git worktree remove`: git dir and `.git` file both gone) in the exact layout git writes"

**Location:** `guides/cc-isolated-usage.md:335-337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a `git worktree remove` of a standard worktree on git 2.39.5 yields exactly the three removed records and is accepted; does not establish other git versions' removal layout.

Test 3 runs `git -C "$SCAN_WS" worktree remove "$STD_WT"` and asserts `status 0` / `(removed: agent-y).` (`test/cc-isolated-functions.bats:2268-2271`); the tab-path probe's warning lists exactly the three removed records (`- dotgit …`, `- commondir-file …`, `- hooksdir … missing`, `$D/logs/probe.txt`).

**Evidence:** `guides/cc-isolated-usage.md:335-337`, `test/cc-isolated-functions.bats:2263-2271`, `$D/logs/probe.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "For a removal, "exact" means the private dir is gone and the removed records are the ones git's layout makes (the `.git` file named that dir), and the old working-tree directory is gone or does not look like a git dir (no `HEAD` next to `objects/`, no `commondir` file); a working-tree path with a newline or other byte that bash's `%q` quotes as `$'…'` warns."

**Location:** `guides/cc-isolated-usage.md:342-346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paraphrase of `looks_like_gitdir` (matches `cc-gitdir.sh:89`: HEAD of any type with an `objects/` dir, or a regular-file `commondir`) and the `$'…'` decline; does not establish the symlinked-parent case (Claim 7b), which the paragraph does not address.

`looks_like_gitdir`: `{ { [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]` (`devcontainer-config/cc-gitdir.sh:89`). Decline of `$'…'`: `cc-exit-scan.sh:788`, `:887`; newline (test 4) and tab (probe) paths warn. Claim 2's runs show no path other than `$'…'`/`''` forms is declined, so "warns" is not hiding a wider decline set.

**Evidence:** `guides/cc-isolated-usage.md:342-346`, `devcontainer-config/cc-gitdir.sh:83-90`, `devcontainer-config/cc-exit-scan.sh:788`, `devcontainer-config/cc-exit-scan.sh:887`, `$D/logs/bats-q094.txt`, `$D/logs/probe.txt`, `$D/logs/unq-C.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "Anything else warns as before … also any other change in the session, a working tree deleted without a prune, …"

**Location:** `guides/cc-isolated-usage.md:352-354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a working tree deleted while its private dir remains; does not cover a later `git worktree prune` (which removes P and then yields an accepted removal, consistent with "without a prune").

`[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`cc-exit-scan.sh:873`). Test 3: `rm -rf "$SCAN_WS/.claude/worktrees/agent-x"` then `[ "$status" -eq 1 ]` and `- dotgit …agent-x/.git` listed (`test/cc-isolated-functions.bats:2277-2281`); passed.

**Evidence:** `guides/cc-isolated-usage.md:352-354`, `devcontainer-config/cc-exit-scan.sh:873`, `test/cc-isolated-functions.bats:2277-2288`, `$D/logs/bats-q094.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: Test names vs assertions — "a removed standard worktree is a note; a half-removed one warns", "a removal whose old working tree now looks like a git dir warns", "_snap_unq: inverts printf %q's backslash form; other forms decline", "a removed git dir pairs only with the .git that pointed at it"

**Location:** `test/cc-isolated-functions.bats:2263`, `test/cc-isolated-functions.bats:2290`, `test/cc-isolated-functions.bats:2324`, `test/cc-isolated-functions.bats:2336`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test's assertions exercise what its name says and that each passes at 2eebdf8; does not establish that the names list everything asserted (test 2290 also holds a positive control and the `$'…'` decline; test 2324's "other forms" are `$'…'`, `''` and the malformed `a\`).

- 2263: note for `worktree remove` (`[ "$status" -eq 0 ]`, `(removed: agent-y).`), warn after `rm -rf` of a tree and after hiding P (`[ "$status" -eq 1 ]`).
- 2290: HEAD+objects/ → `[ "$status" -eq 1 ]` and `[[ "$output" != *"note:"* ]]`; commondir alone → same.
- 2324: `for s in plain/path "a b/c" "x${bs}y" "~t" "q${sq}uote" "semi;&|" "*?[]"` round-trips; `run ! _snap_unq "$(printf '%q' "new\nline")"`, `run ! _snap_unq "$sq$sq"`, `run ! _snap_unq "a$bs"`. `run !` is supported by bats 1.8.2 (used here).
- 2336: two half-removals of different worktrees → `status 1`, `- dotgit …agent-b/.git`.

All four passed in the baseline run.

**Evidence:** `test/cc-isolated-functions.bats:2263-2348`, `$D/logs/bats-q094.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15a: Commit 1f31b18 — "A worktree removed with `git worktree remove` drops three records: its .git file, its private dir's commondir, and the missing hooks/." … conditions … "(a dir made invisible to the scan by deleting HEAD or commondir but left in place still warns)" … "Pairing is by content, not count" … "Anything else, including a working tree deleted without a prune, warns."

**Location:** commit `1f31b18` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message's description against code at 2eebdf8 (the conditions are a subset of the final rule; 2eebdf8 added the old-tree check afterwards); deleting HEAD alone or commondir alone (rather than both, as the test does) is verified statically only.

Three records: tab-path probe lists exactly those three (`$D/logs/probe.txt`). P left in place warns via `cc-exit-scan.sh:873` whatever made it invisible to the snapshot; test 3 deletes both HEAD and commondir (`test/cc-isolated-functions.bats:2282-2285`). Deleting either alone also hides P from `_snap_nested`, which finds candidates by `-name HEAD` and keeps them only if `looks_like_gitdir` (`cc-exit-scan.sh:562-566`) — a worktree private dir has no `objects/`, so without `commondir` it fails that test (paraphrased — no quote available because this combines `_snap_nested` with the on-disk layout of a private dir). Content pairing: Claim 5.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:555-567`, `devcontainer-config/cc-exit-scan.sh:873-882`, `test/cc-isolated-functions.bats:2263-2288`, `$D/logs/probe.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15b: Commit 1f31b18 — "89 changed code lines."

**Location:** commit `1f31b18` message (Notes)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count of the commit's own diff; does not establish which counting rule the decision-log size cap uses.

`git show 1f31b18 --numstat`: `cc-exit-scan.sh 32/13`, `guides/cc-isolated-usage.md 5/4`, `test/cc-isolated-functions.bats 33/2` — 70 insertions + 19 deletions = 89, of which 9 are guide (documentation) lines; code and test files alone are 80. Precise version: "89 changed lines (80 in code and tests)". Command run in cwd `/workspace/.claude/worktrees/agent-aaad54fc687b7548c` (read-only `git show`), exit 0, 2026-09-29T03:26Z; output reproduced in this paragraph (read-only git metadata, deterministic).

**Evidence:** commit `1f31b18` (`git -C <repo> show 1f31b18 --numstat --format=`)
**Legibility-target:** for-author

---

## Claim 16: Commit fc56eca — "the scan_std_worktrees comment now names the removed records' exact content ("../..\n", hooks "missing"), and the guide says which of the "exact" layout checks apply to a removal. No behaviour change."

**Location:** commit `fc56eca` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that fc56eca's diff touches only comment lines in `cc-exit-scan.sh` and guide prose; does not re-verify fc56eca's guide wording, which 2eebdf8 later rewrote (checked as Claim 12).

`git show fc56eca -- devcontainer-config` filtered to non-comment `+`/`-` lines returns nothing (only the `---`/`+++` headers); stat is `cc-exit-scan.sh 5 +++--`, `guides/cc-isolated-usage.md 4 +++-`. The comment at 2eebdf8 names `` `hooksdir P/hooks missing` `` and `"../..\n"` (`cc-exit-scan.sh:813-815`).

**Evidence:** commit `fc56eca`, `devcontainer-config/cc-exit-scan.sh:813-815`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: Commit 2eebdf8 — decode via "_snap_unq, printf %q's backslash form only, verified by re-quoting … A path %q writes as $'...' is not decoded and declines (warns)"; "Tests: a removal with the old dir back holding ordinary files (note, positive control), then HEAD next to objects/ (warns), then a lone commondir file (warns), then a $'...' path (warns); _snap_unq round trips. Mutations that drop the looks_like_gitdir check, check the .git path instead of its dir, skip the re-quote check, or accept on a decode failure each fail a test."

**Location:** commit `2eebdf8` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test list and the four named mutations as I implemented them; does not establish that every conceivable variant of "accept on a decode failure" is caught (the variant `_snap_unq … || true` survives, but it still declines — see below — so it is not an acceptance).

Test list matches `test/cc-isolated-functions.bats:2290-2334` in order. Mutations, each applied to a fresh copy of `$D/tree` by `$D/mut.sh` and run with `bats -f 'Q-094|_snap_unq'`:

| Mutation | Change | Exit | Failing test | Log | Started (UTC) |
|---|---|---|---|---|---|
| M1 drop looks_like_gitdir | delete `:889` | 1 | 4 | `$D/logs/mut-M1-drop-llg.txt` | 03:12:54Z |
| M2 test `.git` path | delete `:888` | 1 | 4 | `$D/logs/mut-M2-dotgit-path.txt` | 03:14:07Z |
| M3 skip re-quote | delete `:794` | 1 | 5 | `$D/logs/mut-M3-no-requote.txt` | ~03:15Z |
| M4a accept on decode failure | `\|\| { used["$ok"]=1; removed+=("$n"); continue; }` | 1 | 4 | `$D/logs/mut-M4a-accept-on-fail.txt` | ~03:16Z |
| M4b ignore decode failure | `\|\| true` | 0 | none | `$D/logs/mut-M4b-ignore-fail.txt` | ~03:17Z |

(cwd for each: `$D/mut-<name>`; M2–M4b ran in one command started 03:14:07Z.) M4b survives but still declines: `wt` then holds either nothing or a value without a `/.git` suffix left from an earlier loop pass (`wt="$wsp/$wtrel"`, `:911`, or the stripped removal value, `:888`), so `case "$wt" in */.git) … *) return 1` (`:888`) returns 1 (paraphrased — no quote available because this is the combination of the two assignments with the case at `:888`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:786-796`, `devcontainer-config/cc-exit-scan.sh:884-891`, `test/cc-isolated-functions.bats:2290-2334`, `$D/mut.sh`, `$D/logs/mut-M1-drop-llg.txt`, `$D/logs/mut-M2-dotgit-path.txt`, `$D/logs/mut-M3-no-requote.txt`, `$D/logs/mut-M4a-accept-on-fail.txt`, `$D/logs/mut-M4b-ignore-fail.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: Commit 2eebdf8 Notes — "Declining (not accepting) an undecodable path is the fail-closed choice; the added side already declines such paths (its back-pointer read is one line)."

**Location:** commit `2eebdf8` message (Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added branch's handling of worktree paths that `%q` writes as `$'…'`; does not assess whether accepting such added paths is a security problem (not a fact-check question).

"Such paths" means paths `%q` writes as `$'…'`. The stated mechanism, a one-line back-pointer read (`line="$(_snap_first_line "$p/gitdir" …)"`, `cc-exit-scan.sh:902`, then `_snap_file_is "$p/gitdir" "$(_snap_hash_str "$line"$'\n')"`, `:903`), only rejects a path containing a **newline**. Other bytes that `%q` quotes as `$'…'` (tab, control bytes) pass it, and the added branch never decodes a path — it recomputes `printf '%q' "$wt/.git"` for the lookup (`:914`). Probe (scratch copy): command `TMPDIR=$D/tmp LC_ALL=C bats -f 'PROBE' test/cc-isolated-functions.bats`; cwd `$D/probe`; exit 0; 2026-09-29T03:24:58Z; results `PROBE added tab path`: `status=0 output=note: … (added: agent-t). They take config and hooks …`; `PROBE added ctrl-A path`: `status=0 … (added: agent-c)`. So the added side accepts tab and control-byte paths that the removal side declines. Precise version: "the added side declines paths with a newline (its back-pointer read is one line); other `$'…'` paths are accepted there, since it never unquotes."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:895-925`, `$D/probe/test/cc-isolated-functions.bats` (appended PROBE tests), `$D/logs/probe.txt`
**Legibility-target:** for-author

---

## Claims Requiring Attention

### Incorrect
- **Claim 18** (commit `2eebdf8`, Notes): "the added side already declines such paths" holds only for a newline; tab/control-byte `$'…'` paths are accepted on the added side (probe: note, status 0). Say "declines newline paths" instead, or make the two sides consistent.

### Stale
- **Claim 4** (`devcontainer-config/cc-exit-scan.sh:824`): "nothing is unquoted" — 2eebdf8's removal branch now decodes the dotgit path with `_snap_unq` (`:887`).
- **Claim 9** (`docs/working/plan-q094-exit-scan-worktree-layout.md:90`, row B18): "never unquoted" — same change; the row covers `$'…'` paths.

### Mostly Accurate
- **Claim 7b** (`devcontainer-config/cc-exit-scan.sh:939-940`): "Removed ones left no git dir behind" — true for P, the old tree dir and its `.git` entry, but not through a symlinked parent that `find -P` skips (probe: note printed while `<old wt>/.git` resolved to a bare repo outside the checkout). Narrow the wording, or list the symlinked-dir route under "Known routes".
- **Claim 15b** (commit `1f31b18`): "89 changed code lines" is total changed lines including 9 guide lines; code and tests alone are 80.

### Unverifiable
- (none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown code-fact-check report saved at the output path below, structured per the code-fact-check skill, with the header fields `**Commit:** 2eebdf8` and per-claim sections.
- Answered: yes — all 8 flagged areas checked; the 4 named mutations re-run (plus one surviving variant, shown to be benign).
- Out of scope: judging whether the added side should decline `$'…'` paths, and whether the symlinked-parent route matters for security (security-reviewer's call); hallucination-pattern log not updated (the Incorrect is a behavioural misstatement, not a fabricated symbol, and the repo must not be modified).
- Escalate: Claim 18 (a commit-message claim that the two sides are consistent when they are not — security-reviewer may want the tab/control-byte added-path behaviour); Claim 7b's symlinked-parent probe as a possible "Known routes" entry.
- Decisions I made: Included plan row B18 (unit A text) because 2eebdf8 made it stale; the alternative was to treat it as out-of-range context. Rated 7b Mostly accurate rather than Incorrect, because the symlink target has to lie outside the checkout (not writable by the container) and the same limit applies to the whole scan.
