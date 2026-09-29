# Code Fact-Check Report

**Commit:** 2eebdf8
**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094b-exit-scan-worktree-removal`)
**Scope:** Unit B range `9075003..2eebdf8` (commits 1f31b18, fc56eca, 2eebdf8): `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `test/cc-isolated-functions.bats`, plus commit messages. Unit A (`dfe4c0d..9075003`) is context only, read where B's changes interact with it (the `scan_std_worktrees` doc comment, plan row B18).
**Checked:** 2026-09-28 (executions 2026-09-29T03:11Z–03:23Z UTC)
**Total claims checked:** 21
**Summary:** 17 verified, 1 mostly accurate, 2 stale, 1 incorrect, 0 unverifiable

Execution environment for every `executed` claim: a `git archive 2eebdf8` copy at
`/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcB-r3k7/tree`
(the review worktree was not touched), GNU bash 5.2.15, Bats 1.8.2, git with
`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `TMPDIR=<scratch>/tmp`, `LC_ALL=C` unless a claim
says C.UTF-8. Captured outputs and the scripts that produced them are copied to
`/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/reviews/B-fc-r3-logs/`
(referred to below as `LOGS/`).

Baseline runs:
- `bats -f 'Q-094|_snap_unq' test/cc-isolated-functions.bats`, cwd `<scratch>/fcB-r3k7/tree`, exit 0, 2026-09-29T03:11:38Z: 12/12 ok (`LOGS/baseline.txt`).
- `timeout 580 bats test/cc-isolated-functions.bats`, same cwd, exit 0, 2026-09-29T03:20:29Z: 172/172 ok (`LOGS/full.txt`).

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; its logged patterns concern
fabricated test/corpus counts and consumers. No claim below matches one (2eebdf8 lists tests but gives no count).

---

## Claim 1: "When every difference is a linked worktree added or removed in git's own layout (agent worktrees outlive sessions), the scan prints one `note:` and returns 0 (scan_std_worktrees has the rule)."

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77` (also the `git_exit_scan` comment at `:979-980`)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` printing exactly one `note:` line and returning 0 for a `git worktree remove` of a standard worktree (and for add+remove mixes); does not establish the launcher's end-to-end exit status for a removal (the launcher test that exercises this path, test 12, uses an added worktree only).

`git_exit_scan` delegates to `scan_std_worktrees` and returns 0 after printing its note:

```bash
# devcontainer-config/cc-exit-scan.sh:981-985
  local note
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```

Executed: `LC_ALL=C bash exp.sh` (cwd `<scratch>/fcB-r3k7`, exit 0, 2026-09-29T03:19:41Z). Scenario E1
(`git worktree remove` of `agent-y`) printed one line
`note: exit scan: only linked worktrees in git's standard layout changed (removed: agent-y). Removed ones left no git dir behind, so this is not a finding.` and `rc=0`; E8 (two removed, one added) likewise `rc=0` with one note.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:75-77`, `devcontainer-config/cc-exit-scan.sh:951-990`, `LOGS/experiments.txt`, `LOGS/exp.sh`

---

## Claim 2: "_snap_unq <%q string> <var>: sets <var> to the string printf %q quoted, for its backslash form only ($'…' and '…' forms return 1). The result is checked by quoting it again, so a wrong decode declines instead of passing."

**Location:** `devcontainer-config/cc-exit-scan.sh:783-785`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers decode-or-decline for every `printf %q` output of bash 5.2 in C and C.UTF-8 locales (including a record written in one locale and decoded in the other, which declines); does not establish behaviour if a caller passes a variable name that collides with `_snap_unq`'s own locals (`q s c i`) — the one caller passes `wt`.

The full function (read signature to last line):

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

The re-quote line is what makes the "wrong decode declines" half hold in general: `printf %q` is injective (its output evals back to the input), so any `s` with `printf %q s` equal to `q` is the original string (paraphrased — no quote available because this is a property of bash's `%q`, argued from its eval-round-trip contract rather than a line of this repo). Bash emits only three forms: backslash-escaped, `$'…'` (whole string, when any byte needs it), and `''` for the empty string; the `case` rejects the latter two, and the re-quote check alone would also reject them (mutation `no-form-case` removing the `case` line leaves all 12 tests passing: `LOGS/m-no-form-case.txt`).

Executed: `LC_ALL=C bash q.sh` and `LC_ALL=C.UTF-8 bash q.sh` (cwd `<scratch>/fcB-r3k7`, exit 0, 2026-09-29T03:18Z): 17 path forms (space, newline, tab, `é`, `\xff`, `~`, quotes, `$`/backtick, `!`, braces/comma, `#`, `=`, `%`, `^`, `:`/`@`, DEL, ESC). Every result was `ok` (round-trip equal) or `declined`; none `WRONG`. In C locale `é` is `$'/a/\303\251/.git'` and declines; in C.UTF-8 it is written raw and decodes correctly (`LOGS/unq-forms.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:783-797`, `LOGS/unq-forms.txt`, `LOGS/q.sh`, `LOGS/m-no-form-case.txt`

---

## Claim 3: scan_std_worktrees doc comment — "Removed <n>: gone `hooksdir P/hooks missing` and `commondir-file P/commondir` of exactly "../..\n", P gone on disk, one gone `dotgit` record that held exactly "gitdir: P\n" (either form), and that record's directory (the old working tree) either gone or not looking like a git dir (looks_like_gitdir)." (with "added or removed in git's standard layout" and "Only dotgit, commondir-file and hooksdir records differ")

**Location:** `devcontainer-config/cc-exit-scan.sh:808-817`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause of the removal rule against the removal branch and the shared record parse; does not establish anything about paths not under the checkout's own common dir (those decline at `:862`, unit A) nor about what else lies under the old working tree below its root (see Claim 6).

Record filter (only three kinds, either sign) and the shared checks on the commondir record:

```bash
# devcontainer-config/cc-exit-scan.sh:847-853
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      [+-]F$'\t'dotgit$'\t'*) left["$line"]=1; dot["${line%$'\t'*}"]="$line" ;;
      [+-]F$'\t'commondir-file$'\t'*|[+-]F$'\t'hooksdir$'\t'*) left["$line"]=1 ;;
      *) return 1 ;;
    esac
```

```bash
# devcontainer-config/cc-exit-scan.sh:867-871
    re="^file [0-7]+ $std\$"
    [[ "$attrs" =~ $re ]] || return 1
    hk="${rec:0:1}F"$'\t'"hooksdir"$'\t'"$(printf '%q' "$p/hooks")"$'\t'"missing"
    [ -n "${left[$hk]:-}" ] || return 1
    used["$rec"]=1; used["$hk"]=1
```

Removal branch (whole branch quoted):

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
(the two `...` elide only comment lines at `:874-875` and `:884-885`, both read.) Every record must then be consumed (`:932`). `looks_like_gitdir` on a missing directory is false, so "gone" is accepted (`devcontainer-config/cc-gitdir.sh:87-90`, quoted in Claim 9).

Executed (`LOGS/experiments.txt`, `LOGS/experiments3.txt`, 2026-09-29T03:19Z/03:23Z, exit 0): standard removal → note (E1); container-form `.git` (`gitdir: <cws>/.git/worktrees/agent-x`) with P and wt deleted → note (`experiments3`); P left with only HEAD or only commondir deleted → warns (E2, E3); a `.git` dir recreated at the old path → warns (E5).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:808-817`, `devcontainer-config/cc-exit-scan.sh:825-943`, `devcontainer-config/cc-gitdir.sh:83-90`, `LOGS/experiments.txt`, `LOGS/experiments3.txt`

---

## Claim 4: "Paths are compared as the %q strings the records hold, recomputed from <n>; nothing is unquoted."

**Location:** `devcontainer-config/cc-exit-scan.sh:822-824`
**Type:** Behavioral / Invariant
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removal branch added in 2eebdf8; does not dispute the sentence for the added branch or for the commondir/hooksdir record paths, which are still recomputed from `<n>` and compared quoted.

This sentence (unchanged context from unit A, where it was true) is now contradicted by B's removal branch, which (a) does not recompute the removed `.git` record's path from `<n>` — it finds the record by content — and (b) unquotes it:

```bash
# devcontainer-config/cc-exit-scan.sh:886-887
      q="${ok%$'\t'*}"; q="${q#?F$'\t'dotgit$'\t'}"
      _snap_unq "$q" wt || return 1
```

The same doc comment's removal clause four lines earlier (`:815-817`, "that record's directory (the old working tree)") presupposes this decode, so the comment now contradicts itself. Precise version: "…recomputed from <n>, except the removed `.git` record's path, which is decoded by `_snap_unq` (backslash form only, re-quote checked) to test the old working tree."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:815-824`, `devcontainer-config/cc-exit-scan.sh:886-887`

---

## Claim 5: "Its own `.git` file gone too: a removed dotgit record that held exactly "gitdir: P\n" (either form). Another worktree's .git never pairs."

**Location:** `devcontainer-config/cc-exit-scan.sh:874-875`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers content pairing (a `.git` pairs only if its hash is `gitdir: P\n` or the container form) and single consumption (`used`); does not establish anything about a `.git` that some other worktree held with content naming this P (such a file points at P and so is not "another worktree's" in git's sense).

The loop skips `+` records and already-used ones and matches the record's hash against `P`'s two forms (quoted in Claim 3, `:876-882`). Test `exit scan Q-094: a removed git dir pairs only with the .git that pointed at it` (`test/cc-isolated-functions.bats:2336-2348`) removes agent-a's P and agent-b's `.git` and asserts status 1 listing agent-b's `.git`; it passes (`LOGS/baseline.txt`, ok 6).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:872-883`, `test/cc-isolated-functions.bats:2336-2348`, `LOGS/baseline.txt`

---

## Claim 6: "The old working tree, if still there, must not look like a git dir: a repository left in its place is not "removed"."

**Location:** `devcontainer-config/cc-exit-scan.sh:884-885`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old working-tree root itself (HEAD-next-to-objects/ or a regular `commondir` file there declines; a `.git` recreated there declines via its record); does not establish anything about a git-dir layout placed in a subdirectory of the old working tree, which is accepted with the note (E4) — as a bare layout anywhere else in the checkout below the root would be.

Code: `! looks_like_gitdir "$wt" || return 1` after `wt="${wt%/.git}"` (`devcontainer-config/cc-exit-scan.sh:888-889`). Test `a removal whose old working tree now looks like a git dir warns` passes (ok 4, `LOGS/baseline.txt`). Executed E6 (HEAD a dangling symlink, `objects` a symlink to a dir) → warns; E7 (`commondir` a directory, not a file) → note, consistent with `[ -f "$d/commondir" ]`; E4 (`sub/HEAD` + `sub/objects/` under the old tree) → note (`LOGS/experiments.txt`, exit 0, 2026-09-29T03:19:41Z).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:884-891`, `devcontainer-config/cc-gitdir.sh:87-90`, `test/cc-isolated-functions.bats:2290-2322`, `LOGS/experiments.txt`

---

## Claim 7: Note wording — "Removed ones left no git dir behind" (removals only); "They take config and hooks from the checkout's own .git" (additions only); "Removed ones left no git dir behind, and added ones take config and hooks from the checkout's own .git" (both), with "(added: …; removed: …)"

**Location:** `devcontainer-config/cc-exit-scan.sh:934-942`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which text is chosen for each mix and that "left no git dir behind" matches what is checked for the removed worktree (its P gone, its `.git` record gone with nothing new at that path, its old working-tree root not git-dir-like); does not establish that no git-dir layout exists deeper under the old working tree (E4 prints this note with one at `<old wt>/sub`).

```bash
# devcontainer-config/cc-exit-scan.sh:934-942
  line=""
  [ "${#added[@]}" -eq 0 ] || line="added: $(printf '%s\n' "${added[@]}" | LC_ALL=C sort | tr '\n' ' ')"
  [ "${#removed[@]}" -eq 0 ] || line="${line:+${line% }; }removed: $(printf '%s\n' "${removed[@]}" | LC_ALL=C sort | tr '\n' ' ')"
  why="They take config and hooks from the checkout's own .git"
  if [ "${#removed[@]}" -gt 0 ]; then
    [ "${#added[@]}" -eq 0 ] && why="Removed ones left no git dir behind" ||
      why="Removed ones left no git dir behind, and added ones take config and hooks from the checkout's own .git"
  fi
  echo "note: exit scan: only linked worktrees in git's standard layout changed (${line% }). $why, so this is not a finding."
```

Executed outputs (`LOGS/experiments.txt`): E1 `(removed: agent-y). Removed ones left no git dir behind, so this is not a finding.`; E8 `(added: agent-c; removed: agent-a agent-b). Removed ones left no git dir behind, and added ones take config and hooks from the checkout's own .git, so this is not a finding.`; E9 `(added: agent-c). They take config and hooks from the checkout's own .git, so this is not a finding.`

**Evidence:** `devcontainer-config/cc-exit-scan.sh:934-942`, `LOGS/experiments.txt`

---

## Claim 8: Plan rule 6 (as changed in 2eebdf8) — accepts a removal when the difference removes exactly `hooksdir P/hooks missing` and `commondir-file P/commondir file <mode> H("../..\n")`, `P` no longer exists on disk, one removed `dotgit` record held exactly `gitdir: P\n` (either form), and that record's directory is gone or fails `looks_like_gitdir`; "a path `%q` writes as `$'…'` is not decoded and warns"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the acceptance conditions and the `$'…'` decline; does not re-verify the rule's historical references (review iteration 1 / security iteration 3 findings) or unit A's "447 lines" figure.

Same code as Claim 3 (`devcontainer-config/cc-exit-scan.sh:867-891`). The `$'…'` decline: `case "$q" in \$\'*|\'*|"") return 1 ;; esac` (`:788`), and the removal returns 1 on decode failure (`:887`). Executed in `LOGS/experiments2.txt` (2026-09-29T03:22:55Z, exit 0): removal with a tab or newline in the path warns in both locales; with `é` it warns in C locale and is accepted in C.UTF-8 (where `%q` writes it raw, so the rule's condition does not apply).

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `devcontainer-config/cc-exit-scan.sh:786-797`, `devcontainer-config/cc-exit-scan.sh:872-891`, `LOGS/experiments2.txt`

---

## Claim 9: Plan risk row B18 — "paths are compared as the `%q` string recomputed from the parsed name, never unquoted"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:90`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "never unquoted" part as it applies to the unit-B removal path; does not dispute the row's `<n>` restriction (rule 4) or its "covered" status for odd names (the decode declines `$'…'` and re-quote-checks the rest, Claim 2).

The row (unit A text, true for unit A) was not updated when 2eebdf8 added `_snap_unq "$q" wt` (`devcontainer-config/cc-exit-scan.sh:887`), and it now contradicts the same doc's rule 6 at `:60` ("a path `%q` writes as `$'…'` is not decoded"), which presupposes decoding other paths. 2eebdf8's "Guide and plan rule 6 updated to match" is accurate for rule 6 alone.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `docs/working/plan-q094-exit-scan-worktree-layout.md:90`, `devcontainer-config/cc-exit-scan.sh:887`

---

## Claim 10: "A linked worktree added or removed in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` returning 0 with one note for a removal (executed) and the launcher mapping a 0 scan to claude's status (unit A test 12, executed for an addition); does not establish a launcher run with a removal specifically.

`git_exit_scan` returns 0 with the note (Claim 1, `devcontainer-config/cc-exit-scan.sh:981-985`). The launcher path is identical for added and removed (paraphrased — no quote available because the launcher's handling of scan status lives in `cc-isolated.sh` and does not branch on add vs remove; I did not re-read it for this unit). Test 12 `a session that leaves an agent worktree ends the launcher with claude's status and a note` passes (`LOGS/baseline.txt`).

**Evidence:** `guides/cc-isolated-usage.md:66-68`, `devcontainer-config/cc-exit-scan.sh:981-985`, `LOGS/baseline.txt`, `LOGS/experiments.txt`

---

## Claim 11: "…or removed (`git worktree remove`: git dir and `.git` file both gone) in the exact layout git writes"

**Location:** `guides/cc-isolated-usage.md:335-337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both-gone being required (P gone on disk; `.git` record removed with no replacement record); does not establish acceptance of a removal done by other means (a manual `rm -rf` of both is accepted too — test 3's last step).

`[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`devcontainer-config/cc-exit-scan.sh:873`) and the removed-dotgit pairing (`:876-883`). E1 shows `git worktree remove` drops exactly the three records (commondir-file, dotgit, hooksdir) and yields the note (`LOGS/experiments.txt`).

**Evidence:** `guides/cc-isolated-usage.md:335-337`, `devcontainer-config/cc-exit-scan.sh:872-883`, `LOGS/experiments.txt`

---

## Claim 12: "For a removal, "exact" means the private dir is gone and the removed records are the ones git's layout makes (the `.git` file named that dir), and the old working-tree directory is gone or does not look like a git dir (no `HEAD` next to `objects/`, no `commondir` file); a working-tree path with a newline or other byte that bash's `%q` quotes as `$'…'` warns."

**Location:** `guides/cc-isolated-usage.md:342-346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against `looks_like_gitdir` and `_snap_unq`, including locale dependence (whether a byte is `$'…'`-quoted depends on the locale, which the sentence's wording already defers to); does not establish anything about subdirectories of the old working tree (Claim 6).

```bash
# devcontainer-config/cc-gitdir.sh:87-90
looks_like_gitdir() {
  local d="$1"
  { { [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]
}
```

"No HEAD next to objects/, no commondir file" is the negation of this function (`-f` accepts a symlink to a regular file; a `commondir` directory is not a file and is accepted: E7). `$'…'` paths decline (Claim 8; `LOGS/experiments2.txt`: tab/newline warn in both locales, `é` warns only in C).

**Evidence:** `guides/cc-isolated-usage.md:342-346`, `devcontainer-config/cc-gitdir.sh:83-90`, `devcontainer-config/cc-exit-scan.sh:786-797`, `LOGS/experiments.txt`, `LOGS/experiments2.txt`

---

## Claim 13: "Anything else warns as before, worktree lines included — also … a working tree deleted without a prune"

**Location:** `guides/cc-isolated-usage.md:352-354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deleting a working tree while its P stays (only the `-dotgit` record differs, which nothing consumes); does not establish behaviour after a later `git worktree prune` (that removes P and then reads as a full removal, accepted).

With P intact, no commondir-file record differs, so the `-dotgit` record is never marked used and `for rec in "${!left[@]}"; do [ -n "${used[$rec]:-}" ] || return 1; done` (`devcontainer-config/cc-exit-scan.sh:932`) declines. Test 3 asserts status 1 and `- dotgit …/agent-x/.git` after `rm -rf` of the working tree (`test/cc-isolated-functions.bats:2276-2280`); passes (`LOGS/baseline.txt`).

**Evidence:** `guides/cc-isolated-usage.md:352-354`, `devcontainer-config/cc-exit-scan.sh:932`, `test/cc-isolated-functions.bats:2263-2288`, `LOGS/baseline.txt`

---

## Claim 14: Test names match their assertions — "a removed standard worktree is a note; a half-removed one warns", "a removal whose old working tree now looks like a git dir warns", "_snap_unq: inverts printf %q's backslash form; other forms decline", "a removed git dir pairs only with the .git that pointed at it"

**Location:** `test/cc-isolated-functions.bats:2263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test's assertions exercise what its name states and that each passes; does not establish that the `_snap_unq` test's third decline case (`a\`) is a `%q` "form" — it is a malformed input, which the name's "other forms" loosely includes.

- `:2263-2288`: note for `(removed: agent-y)`, combined note with `agent-z`, then working tree deleted (warns, `- dotgit`), P made invisible by `rm HEAD commondir` (warns), P deleted (status 0).
- `:2290-2322`: control (ordinary files + empty `objects/`) → note; `HEAD` next to `objects/` → status 1, warning, `- dotgit`, no note; lone `commondir` → status 1; `$'…'` path (newline) → status 1, no note.
- `:2324-2334`: round-trips seven strings (`plain/path`, `a b/c`, `x\y`, `~t`, `q'uote`, `semi;&|`, `*?[]`); `run !` on a newline string (`$'…'`), `''`, and `a\`.
- `:2336-2348`: see Claim 5.

(paraphrased — no quote available because four test bodies totalling ~85 lines are summarised; each is quoted in full in the unit's diff.) All four pass (`LOGS/baseline.txt` ok 3–6).

**Evidence:** `test/cc-isolated-functions.bats:2263-2348`, `LOGS/baseline.txt`

---

## Claim 15: 1f31b18 — "A worktree removed with `git worktree remove` drops three records: its .git file, its private dir's commondir, and the missing hooks/."

**Location:** commit `1f31b18` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout with no global/system git config (the test and experiment setup); does not establish the record set when your own global config adds records for the worktree (e.g. an `includeIf gitdir:` matching it, walked by `_snap_host_config`), which would add records and make the removal warn.

E1 in `LOGS/experiments.txt` (exit 0, 2026-09-29T03:19:41Z): the `diff` of before/after snapshots lists exactly `commondir-file …/agent-y/commondir file 644 …`, `dotgit …/agent-y/.git file 644 …`, `hooksdir …/agent-y/hooks missing`.

**Evidence:** `LOGS/experiments.txt`, `devcontainer-config/cc-exit-scan.sh:573-596`

---

## Claim 16: 1f31b18 — acceptance conditions list, including "the private dir P is gone on disk (a dir made invisible to the scan by deleting HEAD or commondir but left in place still warns)" and "Anything else, including a working tree deleted without a prune, warns."

**Location:** commit `1f31b18` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed condition and the HEAD-only and commondir-only invisibility cases individually; does not re-verify the historical "security review iteration 1 showed count pairing…" reference.

`_snap_nested` finds git dirs with `find … -name HEAD` then `looks_like_gitdir` (`devcontainer-config/cc-exit-scan.sh:562-566`), so deleting either file hides P; the removal branch then fails `[ ! -e "$p" ]` (`:873`). E2 (HEAD only) and E3 (commondir only) both `rc=1` with the warning (`LOGS/experiments.txt`). The test covers only both deleted together (`test/cc-isolated-functions.bats:2281-2283`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:555-567`, `devcontainer-config/cc-exit-scan.sh:873`, `LOGS/experiments.txt`

---

## Claim 17: 1f31b18 Notes — "89 changed code lines."

**Location:** commit `1f31b18` message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic of `git show --numstat 1f31b18`; does not establish which counting convention the decision-log size cap uses.

`git show --numstat --format= 1f31b18` (cwd the review worktree, exit 0, 2026-09-29T03:23Z): `32 13 cc-exit-scan.sh`, `5 4 guides/cc-isolated-usage.md`, `33 2 test/cc-isolated-functions.bats` — 70 + 19 = 89 changed lines, of which 9 are the guide (prose), so 80 are code (script + tests). Precise version: "89 changed lines (80 code, 9 guide)." (Output was read from the terminal, not captured; rerun the command to reproduce.)

**Evidence:** commit `1f31b18` (`git show --numstat --format= 1f31b18`)

---

## Claim 18: fc56eca — "the scan_std_worktrees comment now names the removed records' exact content ("../..\n", hooks "missing"), and the guide says which of the "exact" layout checks apply to a removal. No behaviour change."

**Location:** commit `fc56eca` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's diff (comment lines in `cc-exit-scan.sh`, prose in the guide); does not re-verify the fact-check iteration it cites.

`git show fc56eca` touches `devcontainer-config/cc-exit-scan.sh | 5 +++--` and `guides/cc-isolated-usage.md | 4 +++-`; the script hunk changes only `#` lines, replacing "those two records gone" with "gone `hooksdir P/hooks missing` and `commondir-file P/commondir` of exactly "../..\n"".

**Evidence:** commit `fc56eca`, `devcontainer-config/cc-exit-scan.sh:811-817`

---

## Claim 19: 2eebdf8 — change description and test list: "The removal branch of scan_std_worktrees now decodes the removed dotgit record's path (a new _snap_unq, printf %q's backslash form only, verified by re-quoting) and declines when that directory passes looks_like_gitdir (cc-gitdir.sh). A path %q writes as $'...' is not decoded and declines (warns)." / "Tests: a removal with the old dir back holding ordinary files (note, positive control), then HEAD next to objects/ (warns), then a lone commondir file (warns), then a $'...' path (warns); _snap_unq round trips." / "Guide and plan rule 6 updated to match."

**Location:** commit `2eebdf8` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the described code change, the four-step test sequence and the `_snap_unq` test, and the guide and plan rule 6 edits; does not extend "plan updated to match" to plan row B18, which was not updated (Claim 9).

Code: Claims 2–3. Tests: `test/cc-isolated-functions.bats:2290-2334` in that order (Claim 14); pass (`LOGS/baseline.txt`). Guide `:342-346` and plan `:60` edited in 2eebdf8 (`git diff 9075003 2eebdf8`).

**Evidence:** commit `2eebdf8`, `devcontainer-config/cc-exit-scan.sh:783-797`, `devcontainer-config/cc-exit-scan.sh:884-889`, `test/cc-isolated-functions.bats:2290-2334`, `LOGS/baseline.txt`

---

## Claim 20: 2eebdf8 — "Mutations that drop the looks_like_gitdir check, check the .git path instead of its dir, skip the re-quote check, or accept on a decode failure each fail a test."

**Location:** commit `2eebdf8` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four mutations in their natural forms (listed below); does not cover `_snap_unq … || true`, which survives all tests but is not an "accept on a decode failure": `wt` stays empty or suffix-free and the following `case "$wt" in */.git)` still returns 1.

Each ran as `./mutate.sh <name> <old> <new>` then `bats -f 'Q-094|_snap_unq' test/cc-isolated-functions.bats` (cwd `<scratch>/fcB-r3k7/m-<name>`, 2026-09-29T03:12–03:18Z):

| Mutation | Change | bats exit | Failing test (line) | Log |
|---|---|---|---|---|
| drop-llg | delete `! looks_like_gitdir "$wt" \|\| return 1` | 1 | 4 (`:2303` HEAD step) | `LOGS/m-drop-llg.txt` |
| dotgit-path | keep `wt` as `…/.git` (no strip) | 1 | 4 (`:2303`) | `LOGS/m-dotgit-path.txt` |
| no-requote | delete the re-quote line in `_snap_unq` | 1 | 5 (`:2333`, `run ! _snap_unq "a$bs"`) | `LOGS/m-no-requote.txt` |
| decode-fail-skip | run the wt checks only `if _snap_unq …; then … fi` | 1 | 4 (`:2320`, `$'…'` path) | `LOGS/m-decode-fail-skip.txt` |
| decode-fail-true (extra) | `_snap_unq "$q" wt \|\| true` | 0 | none | `LOGS/m-decode-fail-true.txt` |
| no-form-case (extra) | delete `_snap_unq`'s `case` line | 0 | none (re-quote check covers it) | `LOGS/m-no-form-case.txt` |

**Evidence:** `LOGS/mutate.sh`, `LOGS/m-drop-llg.txt`, `LOGS/m-dotgit-path.txt`, `LOGS/m-no-requote.txt`, `LOGS/m-decode-fail-skip.txt`, `LOGS/m-decode-fail-true.txt`, `LOGS/m-no-form-case.txt`, `devcontainer-config/cc-exit-scan.sh:886-889`

---

## Claim 21: 2eebdf8 Notes — "Declining (not accepting) an undecodable path is the fail-closed choice; the added side already declines such paths (its back-pointer read is one line)."

**Location:** commit `2eebdf8` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "the added side already declines such paths" for the class the sentence refers to (paths `%q` writes as `$'…'`); does not dispute that declining is fail-closed, nor that the added side declines a path containing a newline.

The one-line read only affects a newline. For other `$'…'` bytes the back-pointer is still one line, and the added branch compares the `.git` record by recomputed `%q` string (`dk="${dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]:-}"`, `devcontainer-config/cc-exit-scan.sh:914`), which matches a `$'…'` record fine. Executed `LC_ALL=C bash exp2.sh` and `LC_ALL=C.UTF-8 bash exp2.sh` (cwd `<scratch>/fcB-r3k7`, exit 0, 2026-09-29T03:22:55Z): ADD with a tab in the path → note, `rc=0` (both locales); ADD with `é` in C locale (`$'…'`) → note, `rc=0`; ADD with a newline → warns. REMOVE with a tab → warns. So add and remove are not symmetric for `$'…'` paths: additions accept tab and (in C locale) high bytes, while removals decline them. Precise version: "the added side already declines a path with a newline (its back-pointer read is one line); other `$'…'` paths are accepted when added and warn when removed."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:893-914`, `LOGS/experiments2.txt`, `LOGS/exp2.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 21** (commit `2eebdf8` Notes): "the added side already declines such paths" holds only for newlines; a tab (any locale) or a C-locale high byte in the path is accepted on add (note, rc 0) but declined on removal. Reword, or say it covers newlines only.

### Stale
- **Claim 4** (`devcontainer-config/cc-exit-scan.sh:822-824`): "recomputed from <n>; nothing is unquoted" is now false; the removal branch finds the `.git` record by content and decodes its path with `_snap_unq` (`:886-887`). Add the exception.
- **Claim 9** (`docs/working/plan-q094-exit-scan-worktree-layout.md:90`, row B18): "never unquoted" contradicts rule 6 as edited in 2eebdf8; update the row to mention the re-quote-checked decode.

### Mostly Accurate
- **Claim 17** (commit `1f31b18` Notes): "89 changed code lines" counts 9 guide lines; it is 89 changed lines, 80 of them code.

### Unverifiable
- (none)

## Goal-Alignment Note

Unit B's goal: accept a standard `git worktree remove` with one note, and (2eebdf8) decline one whose old working-tree root looks like a git dir. The code does this. The 12 targeted tests and all 172 in the file pass, and every mutation the commit names fails a test. `_snap_unq` never returned a wrong decode in either locale. None of the findings is a behaviour defect. Two comments (script `:822-824`, plan B18) still say "nothing is unquoted", which 2eebdf8 made false. One commit-message rationale overstates add/remove symmetry. Two advisory residues for the security reader, both outside what the claims assert: (a) a git-dir layout in a *subdirectory* of the removed tree still gets the "left no git dir behind" note (E4). This matches the scan's general blindness to bare layouts below the checkout root, and is not listed under "Known routes it does not see". (b) Add and remove handle `$'…'` paths differently (Claim 21).
