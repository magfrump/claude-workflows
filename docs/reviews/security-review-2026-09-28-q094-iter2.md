Commit: 5fadfc2

# Security Review — branch `q094-exit-scan-worktree-layout`, review-fix iteration 2

**Scope:** `git diff 5a6d689..HEAD` (c32a734 code and doc fixes; 5fadfc2 comments and docs only). Read in full: `devcontainer-config/cc-exit-scan.sh` as of HEAD, and the Q-094 tests at the end of `test/cc-isolated-functions.bats`. `dfe4c0d..5a6d689` was reviewed in iteration 1 and is used as context only.
**Date:** 2026-09-28
**Based on:** iteration-1 security review (`docs/reviews/security-review-2026-09-28-q094.md`) and rubric (`docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md`). There is no iteration-2 fact-check report in the dispatch, so comment claims were checked against the code and by the experiments below.

> ⚠️ **No code fact-check report provided for this iteration.** Where claims about security properties in comments matter below, they were checked by experiment. Other comment claims were not independently verified.

Experiments: `scratchpad/sec2/exp.bats` (E1–E8), run with `bats` against the worktree's `devcontainer-config/cc-isolated.sh` on git 2.39.5, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. All scratch repos are under `mktemp -d`.

## Trust Boundary Map

```
B1: container writes .git/** and the working tree (bind mount) → git_exec_snapshot records → scan_std_worktrees accept/decline
B2: checkout config values at launch (remote urls, insteadOf bases, branch remotes) → _snap_remote / _snap_wrel → W records (refuse the note)       (changed: "." exempt)
B3: snapshot string $after (host-produced, holds container-chosen bytes) → [[ ]] pattern/regex matches → W refusal, commondir equality, `invalid` finding  (changed: grep → [[ ]])
B4: host user runs `git push` in the checkout or a left-behind worktree → git remote resolution (insteadOf, local transport) → receive-pack hooks of the resolved repo
```

Input-source classification:

```
S1: dotgit / commondir-file / hooksdir records (paths %q, attrs)  — runtime-mutable (container) — UNTRUSTED for the accept decision and for index keys
S2: P/gitdir back-pointer bytes and size                            — runtime-mutable (container) — UNTRUSTED for path construction and reads
S3: checkout config entries present at launch (url, insteadOf)     — runtime-mutable (container in an earlier session, or you) — UNTRUSTED toward the exec sink "which repo's hooks a push runs"
S4: $after / $before snapshot strings                               — host-produced, container-chosen bytes inside — trusted as structure (one record per line, %q paths have no tab or newline); values untrusted
S5: GIT_EXIT_SCAN_CONTAINER_WS, the name regex, the 4097 cap       — code-constant — trusted
```

What crosses: container-chosen bytes reach the accept/decline decision through the S1 records and S2 file reads. S3 values reach the W-record decision. The diff changes three things on those paths: the `dot[]` index (S1), the `"."` exemption (S3 → B2), and the move from `grep` pipelines to `[[ ]]` (S4 → B3). The assumption it makes is that `"."` in `_snap_remote` always means "the repository git runs in". That holds for a url, a pushurl, a branch or pushDefault remote, and a legacy remotes file. It does not hold for an `insteadOf` base, where `"."` is a prefix (Finding 1).

## Findings

#### 1. The `"."` exemption also covers `url.<base>.insteadOf` bases, where `"."` is a prefix of a relative path, not the repository

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:355-357` (exemption), reached from `:414-417` (`url.*.insteadof|url.*.pushinsteadof` → `_snap_remote "$t" "$base"`)
**Boundary:** B2 → B4
**Move:** #11 (enumerate bypasses for the new exemption), #12 (every caller of `_snap_remote`)
**Confidence:** High that the mechanism works (executed). Low likelihood: the checkout config must already hold an unusual `url...insteadOf` at launch.

`_snap_remote` is called with the base of every `url.<base>.insteadOf`, and git rewrites a matching URL to `<base>` + the rest of the URL. With `<base>` = `.`, `https://x.invalid/evil` becomes `.evil`: a relative local path that git resolves in whatever working tree it runs in. Before c32a734 that base left a W record, which refused the note. Now `[ "$p" = . ] || _snap_wrel …` suppresses it. The comment's rationale ("the repository git runs in … in a linked worktree, the same common dir and hooks") is true for the other callers but not for this one.

E1, verbatim output:

```
# resolved: .evil
# W at launch: 0
# scan status=0
# HOOK RAN (worktree)
# top-level plant: scan status=0
# HOOK RAN (top level)
```

Setup: launch config `url...insteadOf=https://x.invalid/` and `remote.origin.url=https://x.invalid/evil`. The session then runs `git worktree add wts/agent-x` and plants a bare repo with a `pre-receive` at `wts/agent-x/.evil`. The exit scan returns 0 with the note, and a host `git push origin` in the worktree runs the planted hook. The control, E1c (`url../.insteadOf`, a relative base other than exactly `.`), prints `# control status=1`, so it warns as designed.

**The underlying gap is older than this branch, and it is broader than `.`.** The scan walks the insteadOf *base*, never the rewritten URL (base + suffix). The last two lines of E1 show the same plant at the top level (`$R/.evil`) also scanning 0 and running the hook. That path is unchanged by this diff, because `_snap_remote "."` walked `$R/.` before as well. E6 (`url.sub/.insteadOf`) was caught only because creating `sub/` changed the base's own record (`# top-level plant under sub/: status=1`). If `sub/` already existed at launch, a plant at `sub/evil` would change nothing the scan records. So the new exemption adds no capability the attacker lacks at the top level under the same precondition. What it does is make the header's contract false: "a relative … local remote (not ".") … leave W records, and any W record refuses the note".

**Recommendation:** Apply the exemption only where `"."` names the repository: url/pushurl, the `_snap_names` loop, and legacy remotes/branches. In the `insteadof` branch, keep `_snap_wrel` for `.` (for example, pass a flag to `_snap_remote`, or call `_snap_wrel remote "$t" "$t"` before it without the exemption). Add `"url...insteadOf https://x/"` to the W test loop in `test/cc-isolated-functions.bats:2370`, expecting `warns_listing_wt`. Handle the older base-not-rewritten-URL gap separately: either model the rewrite (walk `<base><suffix>` for each url/pushurl that an insteadOf prefix matches, longest match wins) or add it to "Known routes it does not see" in `guides/cc-isolated-usage.md`. It is not this unit's regression.

#### 2. A container still running can swap `P/gitdir` for a FIFO after the `-f` / size checks (a hang, not a fail-open)

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:859-862`
**Boundary:** B1
**Move:** #4 (TOCTOU)
**Confidence:** Medium (read-static; not executed)

`[ -f "$p/gitdir" ]`, then `stat`, then `_snap_first_line` (`read < file`). A container that is still writing between these steps can replace the regular file with a FIFO, and the read then blocks. The result is a stalled scan: Ctrl-C prints `scan_interrupted` and exits 4. That fails closed and falls under B24's "After the scan" / TOCTOU caveat, which predates this unit. It is noted only because the comment "Regular file first: a FIFO there would block the read" reads as a full guarantee.

**Recommendation:** None needed for merge. If it matters later, open the file once with a non-blocking read (e.g. `timeout 5 head -c 4097`) instead of check-then-read.

## Answers to the dispatch questions

**Q1: the `dot[]` index.** No wrong match or wrong consumption was found.
- Keys and attrs cannot hold a tab. Paths are `printf '%q'` (a tab becomes `$'\t'`), and attrs are `file <mode> <hash>` or `link -> <%q> …`. So `${line%$'\t'*}` always splits off exactly the attrs field.
- E4 added seven worktrees under parents named `a b`, `x]y[z`, `st*r?`, `q$'t'`, `back\slash`, `tab<TAB>in` and `@`: `# odd paths status=0`. Every one was keyed and consumed exactly, with no glob or subscript interpretation.
- Two records with the same key (the same `.git` walked twice with different content) leave the non-indexed one in `left[]` unused. The final loop then declines: E8 `# dup same-key record status=1`.
- One `.git` cannot satisfy two worktrees, because its hash must equal `gitdir: P\n` for one specific `P`. E5 (two back-pointers naming one working tree): `# shared back-pointer status=1`.
- The final loop (`:891`) walks every key of `left[]`. Every added record of an accepted kind goes into `left[]` (`:830-831`), and any other difference returns 1 there. No record can escape it.

**Q2: the `"."` exemption.**
- It is safe for url/pushurl, pushDefault / `branch.*.remote` (only when no remote is named `.`: a remote named `.` is looked up by name and its url is checked), and legacy remotes/branches files.
- It is safe in an embedded repo's config and in an include target (there `.` is that repo, or the including repo).
- It is **not** safe for insteadOf bases (Finding 1).
- E7 confirms the developer's verification: `branch.main.remote .` / `remote.dot.url .` → `# '.' status=0`, and a push from the new worktree left only the `COMMON` marker (`# markers: COMMON r`).
- `file://.` is also exempt (it is stripped to `.`), but git rejects it. E2: `# push: fatal: no path specified; see 'git help pull' for valid url syntax`. So the exemption is harmless there.

**Q3: `[[ ]]` against `grep`.**
- W refusal: `$'\n'"$after"` contains `\nW\t`, which is the same as `^W\t` on any line.
- commondir: `$'\n'"$after"$'\n'` contains `\n<line>\n` with `$line` quoted (literal), which is the same as `grep -xF`.
- `invalid`: `(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid` with no REG_NEWLINE, which is the same as the per-line grep.
- Locale (E3): under C.UTF-8, invalid UTF-8 bytes in *other* records do not stop either match (`# C.UTF-8: W-found invalid-found`). Raw invalid bytes *in the gitdir-valid path itself* do stop the regex (`raw-bytes-path:no`). That field is `printf '%q'` of your own checkout path, which `%q` renders as ASCII, so the case cannot happen.
- No pipeline remains on a pass/warn decision path: `diff` uses process substitution with its status checked, `_snap_hash_str` pipes a short string into sha256sum, and the other pipelines (`added:` line, `scan_vis`, `scan_diff`) only render output. The pipefail test at `test/cc-isolated-functions.bats:2273` passes.

**Q4: new fail-open on error.** None found.
- `stat … || echo 99999` turns a stat failure into a value over the cap, so the check returns 1. A non-integer would make `[` error, which also returns 1.
- `lnk="$(find …)" && [ -z "$lnk" ] || return 1` returns 1 when find fails (for example on an unlistable subdirectory) or when it finds a link.
- The `-f` guard in `_snap_worktree_of` falls through to the name-based working tree. The iteration-1 Low finding is fixed.

## Untested bypass candidates

- `url.<base>.pushInsteadOf` with base `.`: same code path as Finding 1 (`:414`), not run separately.
- A remote literally named `.` combined with `branch.*.remote = .`: traced statically (the named remote's url is walked), not run.

## Endorsement Claims

- **Claim:** Removal records now decline: any `-` record in the difference makes `scan_std_worktrees` return 1.
  **Location:** `devcontainer-config/cc-exit-scan.sh:827-834`
  **Evidence:** executed
  **Verified:** the bats test "a worktree removed during the session still warns" passes (status 1, `- commondir-file` listed); the case statement has no `-` branch.
  **Not verified:** removal together with an added worktree in the same session (the stacked unit's territory).
  **route: code-fact-check**
- **Claim:** The `dot[]` index consumes exactly one record per accepted worktree, keyed by the exact `%q` path, including paths with spaces, brackets, `*`, `?`, `$'`, backslash, tab and `@`.
  **Location:** `devcontainer-config/cc-exit-scan.sh:830,873-887,891`
  **Evidence:** executed
  **Verified:** E4 (status 0 with 7 odd-parent worktrees), E8 (a duplicate key declines), E5 (a shared back-pointer declines).
  **Not verified:** non-UTF-8 bytes in a working-tree path under a UTF-8 locale.
  **route: code-fact-check**
- **Claim:** The W refusal and the `invalid` finding are pipefail-independent and match the same lines the old greps did.
  **Location:** `devcontainer-config/cc-exit-scan.sh:812,817-818,926-928`
  **Evidence:** executed
  **Verified:** the 40k-record pipefail test passes; E3 under the C and C.UTF-8 locales.
  **Not verified:** the launcher's real locale on your host (en_US.UTF-8 is unavailable in this sandbox; C.UTF-8 was used).
  **route: code-fact-check**
- **Claim:** A push to the remote `.` from an accepted new worktree runs the common dir's `pre-receive`.
  **Location:** `devcontainer-config/cc-exit-scan.sh:355-357`
  **Evidence:** executed
  **Verified:** E7 markers.
  **Not verified:** other hooks (`post-receive`, `reference-transaction`) and a relative `core.hooksPath` in the common config (that already leaves a W record).

(The `"."` exemption as a guardrail is not endorsed: Finding 1.)

## Primitive sweep

Primitive: container-chosen path → file read, and `_snap_remote` (path → walked git dir)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:861` `_snap_first_line "$p/gitdir"` | S2 | `-f`, `! -L`, size ≤ 4097, 64 MiB cap | cleared (FIFO swap race: Finding 2, Informational) |
| `cc-exit-scan.sh:862,880,854` `_snap_file_is` | S1/S2 | `-f`, `! -L`, size cap, hash | cleared |
| `cc-exit-scan.sh:856` `find -P "$p" -type l` | S1 | `-P`, status checked | cleared |
| `cc-exit-scan.sh:328` `git config --file "$1"` in `_snap_worktree_of` | S1 | `-f` (new) | cleared (iteration-1 Low fixed) |
| `cc-exit-scan.sh:412` `_snap_remote` url/pushurl | S3 | `.` exempt | cleared (E7) |
| `cc-exit-scan.sh:417` `_snap_remote` insteadOf base | S3 | `.` exempt | **Finding 1** |
| `cc-exit-scan.sh:710` `_snap_remote` names loop | S3 | `.` exempt, named-remote lookup | cleared |
| `cc-exit-scan.sh:607,610` `_snap_remote` legacy branches/remotes | S1 | `.` exempt | cleared (read-static: same semantics as url) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `"."` exemption also covers insteadOf bases, where `.` is a prefix; the base-vs-rewritten-URL gap is older than this branch | Medium | B2→B4 | `cc-exit-scan.sh:355-357,414-417` | High (mechanism), Low (likelihood) |
| 2 | `P/gitdir` FIFO swap after the checks stalls the scan (fails closed) | Informational | B1 | `cc-exit-scan.sh:859-862` | Medium |

## Overall Assessment

The iteration-1 fixes hold. Count-paired removal is gone (every removal now warns), the `_snap_worktree_of` `-f` guard is in, the `[[ ]]` matches are exactly as strict as the greps and pipefail-safe, and neither the `dot[]` index nor the 4097 cap nor the `find` form fails open. The one new issue is the `"."` exemption's placement. It lives inside `_snap_remote`, so it also exempts `url...insteadOf`, where `.` is a path prefix rather than the repository. Keeping it in the callers where `.` names the repository is a one-line fix plus one test row. The broader gap it touches (insteadOf rewrite targets are not walked, even at the top level) is older than this branch and belongs in a follow-up or in "Known routes". Endorsement claims are backed by execution. Merge after Finding 1's one-line fix.

## Goal-Alignment Note

The goal is for agent worktrees left behind by a session to stop raising a false warning (exit 3) without letting a real plant through. This iteration moves toward that goal and narrows the unit correctly: removal handling moves to the stacked branch, where the iteration-1 Medium is fixed by pairing on content. Finding 1 does not work against the goal. It is a scoping slip in one exemption added to cut a false positive (`branch.main.remote = .`), and it can be fixed without losing that false-positive cut.
