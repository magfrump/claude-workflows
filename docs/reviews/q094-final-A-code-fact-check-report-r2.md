# Code Fact-Check Report

**Commit:** 9075003
**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094-exit-scan-worktree-layout`, read via `git show` / `git archive`; working tree not touched)
**Scope:** `git diff dfe4c0d q094-exit-scan-worktree-layout -- . ':!docs/reviews'`: `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-isolated.sh`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, and the commit messages in dfe4c0d..9075003. Terminal confirming pass (pr-prep 3d), one replicate of the k=3 set.
**Checked:** 2026-09-28
**Total claims checked:** 47
**Summary:** 37 verified, 5 mostly accurate, 2 stale, 1 incorrect, 2 unverifiable

Line numbers refer to files at 9075003. Each claim's excerpt was read against its whole enclosing function. Execution ran in an extracted copy, `D=/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcA-r2x7` (`git archive q094-exit-scan-worktree-layout | tar -x -C $D/src`), with git 2.39.5 on Debian 12, `LC_ALL=C` and `TMPDIR=$D/tmp`. The logs are in `$D/logs/`. Timestamps are the sandbox clock in UTC, so they read 2026-09-29.

**Execution index** (referenced by the claims below):

| ID | Command (cwd) | Exit | Time (UTC) | Output |
|---|---|---|---|---|
| X1 | `TMPDIR=$D/tmp LC_ALL=C bats -f 'Q-094' test/cc-isolated-functions.bats` (`$D/src`) | 0 (9/9 ok) | 2026-09-29T03:10:07Z | `$D/logs/bats-q094.txt` |
| X2 | `TMPDIR=$D/tmp LC_ALL=C bats test/cc-isolated-functions.bats` (`$D/src`) | 0 (169/169 ok) | 2026-09-29T03:10:49Z | `$D/logs/bats-full.txt` |
| X3 | `bash $D/exp/exp.sh $D/exp/run`: plan E1–E12, B29, B30 re-run, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` (`$D`) | 0 | 2026-09-29T03:14:16Z | `$D/logs/exp.txt` |
| X4 | `bash $D/exp/exp2.sh $D/src $D/exp/run2`: global relative hooksPath in host and container form, the `invalid` regex, old `printf \| grep -q` under pipefail (`$D`) | 0 | 2026-09-29T03:14:38Z | `$D/logs/exp2.txt` |
| X5 | Mutants M1–M6 (one-line edits of a copy in `$D/mut/<name>`, then `bats -f <test>`) (`$D/mut/<name>`) | 1 for each mutant (it fails its test) | 2026-09-29T03:14:51Z | `$D/logs/mut-M1-no-f-guard.txt` … `mut-M6-no-dot-exempt.txt` |
| X6 | `bash $D/exp/exp3.sh <tree> <dir>`: FIFO `config` plus a legacy `remotes/r` in a worktree private dir, under `timeout 20`, on the tip and on mutant M7 (no `-f` in `_snap_worktree_of`) (`$D`) | tip: 0; M7: 124 (hang) | 2026-09-29T03:18:13Z | `$D/logs/exp3-tip.txt`, `$D/logs/exp3-mut.txt` |
| X7 | `bash $D/exp/exp4.sh $D/exp/run4`: `.gitmodules` `update=!cmd` (`$D`) | 0 | 2026-09-29T03:18:44Z | `$D/logs/exp4.txt` |

Mutants: M1 deletes the `-f` guard at cc-exit-scan.sh:860. M2 reverts the W check at :813 to `printf | grep -q`. M3 reverts the commondir check at :819 to `printf | grep -qxF`. M4 changes `""|.)` to `.)` at :417. M5 deletes line :417. M6 removes the `.` exemption at :357.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read. The nearest logged pattern is "counts claimed in commit messages", which bears on Claims 42 (the 399-line count) and 38 (the 40k padding). Both counts were recomputed and match.

---

## Claim 1: "When every difference is a linked worktree added in git's own layout … the scan prints one `note:` and returns 0"

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path `git_exit_scan` → `scan_std_worktrees` → one note and 0 for a host-form and a container-form added worktree; does not establish behaviour against git versions other than 2.39.5, and says nothing about removals (unit B).
**Legibility-target:** for-orchestrator-synthesis

`git_exit_scan` calls it only when there is no `invalid` finding: `if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then printf '%s\n' "$note" | scan_vis >&2; return 0` (`cc-exit-scan.sh:935-937`). X1 test "a new worktree in git's standard layout is one note and status 0" asserts `status 0` and exactly one output line (`test/cc-isolated-functions.bats:2227-2233`). It passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-970`, `test/cc-isolated-functions.bats:2227-2261`, `$D/logs/bats-q094.txt`

---

## Claim 2: "In a linked worktree git takes config, hooks and info/attributes from the common dir, never the private one (tested on git 2.39.5; the one exception, config.worktree under extensions.worktreeConfig, refuses the note)"

**Location:** `devcontainer-config/cc-exit-scan.sh:78-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--git-path` resolution for hooks, info/attributes and config, and the non-execution of private-dir hooks (pre-commit, post-commit, post-checkout), attributes filters and config hooksPath/fsmonitor on git 2.39.5; does not establish pre-push or reference-transaction (not re-run here) or git versions other than 2.39.5.

**Legibility-target:** for-orchestrator-synthesis

X3 output: `E2 hooks -> …/r/.git/hooks`, `E2 info/attributes -> …/r/.git/info/attributes`, `E2 config -> …/r/.git/config`, `E2 config.worktree -> …/r/.git/worktrees/wt/config.worktree`; `E3 private hooks ran: 0` with the control `yes`; `E4 private attributes filter ran: no` with the control `yes`; `E5 … used: 0`; `E6 config.worktree w/o extension: 0`, `with extension: 1`. The note is refused when `config.worktree` exists: `for k in hooks config config.worktree; do [ ! -e "$p/$k" ] && [ ! -L "$p/$k" ] || return 1; done` (`cc-exit-scan.sh:856`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:856`, `$D/logs/exp.txt`

---

## Claim 3: "A relative core.hooksPath, core.attributesFile or local remote (not ".") in repo config would resolve in the new worktree's own tree, unscanned: those leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:80-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three git behaviours (E7/E8/E9 reproduced), the W producers at :393, :401 and :357, and the refusal at :813; does not establish that these three are the only working-tree-relative exec inputs. For example, a relative `core.fsmonitor` or filter command also runs in the worktree's tree; the guide's "Anything present at launch" route covers those. The "(not ".")" exception is scoped to remote URLs/names: an `insteadOf` base of `.` or `""` does make a W record (:417).

**Legibility-target:** for-orchestrator-synthesis

X3: `E7 relative hooksPath in new wt ran: yes`, `E8 … filter ran: yes`, `E9 relative remote in new wt hook ran: yes`. The code emits W through `_snap_wrel "$key" "$f" "$val"` for `core.hookspath` and `core.attributesfile` (`cc-exit-scan.sh:393`, `:401`) and through `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`:357`). It refuses with `[[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1` (`:813`). X1 test 8 passed, and M6 (X5) fails it.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:287-294`, `:346-369`, `:372-421`, `:813`, `$D/logs/exp.txt`, `$D/logs/mut-M6-no-dot-exempt.txt`

---

## Claim 4: "(Your own config's relative hooksPath is walked in each new worktree, so its records refuse the note as well.)"

**Location:** `devcontainer-config/cc-exit-scan.sh:83-84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the host-form worktree, which is walked and refused, and the container-form worktree whose `/workspace/…` path does not exist on the host, which is not walked and is accepted; does not establish behaviour for a host checkout that really lives at `/workspace` beyond the static reading.
**Legibility-target:** for-author

The walk happens only when the worktree's `.git` resolves on the host: `g="$(_snap_dotgit_target "$f")" …; [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}"` (`cc-exit-scan.sh:700-701`). X4 results:
- Host form: new records included `F hooksdir WS/.claude/worktrees/a/.husky/_`, and `scan_std_worktrees rc=1` (refused).
- Container form (not present on the host): `scan_std_worktrees rc=0`, so the note is given, and `host git in that worktree: fatal: not a git repository`.

The outcome is safe: host git cannot run there, as plan B14 says. The header should still qualify the claim: "walked in each new worktree whose `.git` resolves on the host; one that does not resolve is not a repository to host git."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:496-532`, `:534-549`, `:697-702`, `$D/logs/exp2.txt`

---

## Claim 5: "W <kind> <config or path %q> … (read by scan_std_worktrees; never reported, and it changes only with a C or F record)"

**Location:** `devcontainer-config/cc-exit-scan.sh:151-153`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `scan_diff`, which ignores W, and every W producer (`_snap_wrel` calls at :393, :401, :417 and :357), each emitted next to a C record for the same config entry, or next to the F record of the legacy remotes file that names it; does not establish the invariant when a remote-name decision (:707-712) flips because a `remote.<name>.*` entry appears. That flip is itself a C change, so it still holds.
**Legibility-target:** for-orchestrator-synthesis

`scan_diff` keys only F and C: `FNR == NR { if ($1 == "F") b[$2 FS $3] = $4; else if ($1 == "C") bc[$0] = 1; next }` (`cc-exit-scan.sh:755-756`). Every `_snap_wrel` call in `_snap_config` runs inside the loop that has just appended `_snap+="C"…` for that entry (`:390`). `_snap_remote`'s W depends on the URL value, which comes from a C record, a legacy-remote F record (`:599`), or a deferred name (`:406`) that is itself a C entry (paraphrased — no quote available because the invariant is inferred from four call sites).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:385-421`, `:594-614`, `:704-712`, `:752-769`

---

## Claim 6: "_snap_wrel … a W record when <value> is a relative path, which git resolves in the working tree it runs in"

**Location:** `devcontainer-config/cc-exit-scan.sh:287-294`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the relative test `case "$3" in ""|/*|"~/"*) return 0`; does not establish the handling of `~user/…`, which counts as relative here (a conservative decline).
**Legibility-target:** for-orchestrator-synthesis

`case "$3" in ""|/*|"~/"*) return 0 ;; esac; _snap+="W"$'\t'"$1"$'\t'"$(printf '%q' "$2")"$'\n'` (`cc-exit-scan.sh:292-293`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:290-294`

---

## Claim 7: `_snap_worktree_of` guards the core.worktree read with `[ -f "$1" ]`, so a FIFO config no longer hangs the snapshot

**Location:** `devcontainer-config/cc-exit-scan.sh:321-335`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the legacy-remotes call path (`:608`, `:611`) with a FIFO at `<private dir>/config`; does not establish a guard against a file swapped to a FIFO between the `-f` test and the read (TOCTOU).
**Legibility-target:** for-orchestrator-synthesis

`elif [ -f "$1" ] && v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then` (`cc-exit-scan.sh:328`). X6: the tip returns `snapshot rc=0`. Mutant M7, without `[ -f "$1" ] &&`, hits `timeout-wrapped rc=124`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:323-335`, `:594-614`, `$D/logs/exp3-tip.txt`, `$D/logs/exp3-mut.txt`

---

## Claim 8: "\".\" is the repository git runs in (a local-tracking branch's remote): in a linked worktree, the same common dir and hooks. Not a W record."

**Location:** `devcontainer-config/cc-exit-scan.sh:355-357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact string `.`; does not establish anything about `./`, `./.` and similar, which do make W records (conservative).
**Legibility-target:** for-orchestrator-synthesis

X3: `B29 push to . : common=yes private=no`. Code: `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`:357`). X1 test 8 asserts `branch.main.remote .` gives status 0, and M6 fails it.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-369`, `test/cc-isolated-functions.bats:2367-2384`, `$D/logs/exp.txt`, `$D/logs/mut-M6-no-dot-exempt.txt`

---

## Claim 9: "url.<base>.insteadOf rewrites matching URLs to <base>" / "a base \"\" or \".\" starts a relative path"

**Location:** `devcontainer-config/cc-exit-scan.sh:414-418`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers W emission for bases `""` and `.` (insteadOf and pushInsteadOf) and the git behaviour; does not establish walking of the rewritten URL, which is a documented known route (Claim 37).
**Legibility-target:** for-orchestrator-synthesis

`case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac   # a base "" or "." starts a relative path` (`:417`). X3: `B30 base='.' rewrites to '.evil' hook ran: yes`; `B30 base='' rewrites to 'evil' hook ran: yes`. X5: M4 (drops `""`) and M5 (drops the line) both fail test 8.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:372-421`, `$D/logs/exp.txt`, `$D/logs/mut-M4-drop-empty.txt`, `$D/logs/mut-M5-drop-line.txt`

---

## Claim 10: "Where the container sees the checkout (devcontainer.json's workspaceMount target). Git in the container writes absolute paths under it into a new worktree's `.git` file and back-pointer."

**Location:** `devcontainer-config/cc-exit-scan.sh:771-774`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the constant against `devcontainer.json`, and git 2.39.5 writing absolute paths (E1); does not establish an observation inside a live container (no Docker here).
**Legibility-target:** for-orchestrator-synthesis

`"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"` (`devcontainer-config/devcontainer.json:134`). `GIT_EXIT_SCAN_CONTAINER_WS=/workspace` (`:774`). X3 E1 shows an absolute `gitdir:` in the `.git` file and an absolute back-pointer.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:774`, `devcontainer-config/devcontainer.json:134`, `$D/logs/exp.txt`

---

## Claim 11: "_snap_hash_str <string>: _snap_hash of exactly those bytes."

**Location:** `devcontainer-config/cc-exit-scan.sh:776-781`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers byte equality with `_snap_hash` (both take the first 16 hex of the sha256 of the bytes); does not establish handling of NUL bytes, which bash strings cannot hold.
**Legibility-target:** for-orchestrator-synthesis

`h="$(printf '%s' "$1" | sha256sum)"; printf '%s' "${h:0:16}"` (`:779-780`) matches `_snap_hash`'s `sha256sum < "$1"` … `${h:0:16}` (`:169-173`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:167-174`, `:777-781`

---

## Claim 12: "_snap_file_is <path> <hash>: <path> is a regular file, not a link, within the size cap, whose bytes hash to <hash>."

**Location:** `devcontainer-config/cc-exit-scan.sh:783-791`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all four conditions; does not establish atomicity between the checks.
**Legibility-target:** for-orchestrator-synthesis

`[ -f "$1" ] && [ ! -L "$1" ] || return 1; _snap_size_ok "$1" 2>/dev/null || return 1; h="$(_snap_hash "$1" 2>/dev/null)" || return 1; [ "$h" = "$2" ]` (`:787-790`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:785-791`

---

## Claim 13: scan_std_worktrees doc comment: every stated check (P naming, <n> charset, commondir "../..\n", hooksdir missing, only dotgit/commondir-file/hooksdir added, removal warns, no W, real dirs, no hooks/config/config.worktree/symlink in P, back-pointer form, `.git` form host or container, container form must be P if it exists, snapshot time and now, %q comparison)

**Location:** `devcontainer-config/cc-exit-scan.sh:793-805`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Every stated check is implemented; does not establish that the list is exhaustive. The code also declines, without saying so here, for:
- `<n>` of `.` or `..` (`:845`);
- a snapshot `commondir` record that differs from the recomputed common dir (`:818-819`);
- a back-pointer over 4097 bytes (`:861`);
- `<rel>` holding `.`, `..` or empty segments (`:870`);
- a working tree inside the common dir (`:872`);
- a container-form back-pointer when the common dir is outside the checkout (`:866`).

Each of these only narrows acceptance, which the comment's "Anything it cannot read or match declines" covers. The back-pointer is checked on disk only, not at snapshot time, since it is not a record.
**Legibility-target:** for-orchestrator-synthesis

The comment's checks map to the code as follows:

| Stated check | Code |
|---|---|
| no W record | `:813` |
| only `+F` of the three kinds; everything else, removals included, `return 1` | `+F$'\t'dotgit$'\t'*) …; +F$'\t'commondir-file$'\t'*\|+F$'\t'hooksdir$'\t'*) …; *) return 1` (`:831-833`) |
| P naming and charset | `[[ "$n" =~ ^[A-Za-z0-9._-]+$ ]]` (`:845`) with `[ "$q" = "$(printf '%q' "$p/commondir")" ]` (`:847`) |
| commondir hash at snapshot time | `re="^file [0-7]+ $std\$"` (`:848-849`) |
| hooksdir missing | `hk=…"$(printf '%q' "$p/hooks")"$'\t'"missing"` (`:850-851`) |
| real dirs | `:854` |
| commondir on disk | `:855` |
| no hooks/config/config.worktree | `:856` |
| no symlink | `find -P "$p" -type l -print -quit` (`:857`) |
| back-pointer is exactly `<line>\n` | `:860-863` |
| back-pointer form | `:864-868` |
| `.git` form, host or container, then and now | `for g in "$p" ${ccommon:+"$ccommon/worktrees/$n"}` with the attrs regex and `_snap_file_is` (`:878-882`) |
| container form must be P | `[ "$(cd "$ok" 2>/dev/null && pwd -P)" = "$p" ]` (`:885-887`) |
| every record consumed | `:892` |

X1 tests 2, 5, 6 and 7 exercise the declines, and all passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `test/cc-isolated-functions.bats:2243-2365`, `$D/logs/bats-q094.txt`

---

## Claim 14: "Pattern matches, not `printf | grep -q`: under the launcher's pipefail an early match SIGPIPEs printf, and the pipeline reads as \"no match\"."

**Location:** `devcontainer-config/cc-exit-scan.sh:811-812`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the SIGPIPE/pipefail mechanism with a 40k-line input and the launcher's `set -euo pipefail`; does not establish the exact size threshold, which depends on the pipe buffer.
**Legibility-target:** for-orchestrator-synthesis

The launcher runs `set -euo pipefail` (`cc-isolated.sh:66`) and sources the scan (`:562`). X4: `old printf|grep -q (match at top, 40k lines, pipefail): FALSE (status 141 0)`. `grep` finds no `grep -q` pipeline left in the file: the only "grep" hits are comments at `:98`, `:811` and `:926`.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-exit-scan.sh:811-813`, `$D/logs/exp2.txt`

---

## Claim 15: note text "They take config and hooks from the checkout's own .git, so this is not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:895`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the config and hooks resolution on git 2.39.5 (E2/E3), as in Claim 2; does not establish the "not a finding" safety beyond the scan's documented limits.
**Legibility-target:** for-orchestrator-synthesis

The E2 and E3 results in `$D/logs/exp.txt` (quoted in Claim 2) back this.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:895`, `$D/logs/exp.txt`

---

## Claim 16: git_exit_scan: "0 when nothing the tripwire records changed, or only standard linked worktrees did (one `note:` line on stderr: scan_std_worktrees); 1 … anything else did; 2 when the exit state could not be read, or the snapshots differ but nothing renders."

**Location:** `devcontainer-config/cc-exit-scan.sh:898-903`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four return paths; does not establish that 0 is "safe" (the comment disclaims that itself).
**Legibility-target:** for-orchestrator-synthesis

The return paths are at `:920` (2), `:931` (0), `:937` (0 plus the note), `:945` (2) and `:969` (1). X2 passed all 169 tests.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-970`, `$D/logs/bats-full.txt`

---

## Claim 17: "A pattern match, not `printf | grep -q` (pipefail: see scan_std_worktrees)": the `invalid` check replacement keeps its meaning

**Location:** `devcontainer-config/cc-exit-scan.sh:926-930`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equivalence with the old `grep -q $'^F\tgitdir-valid\t[^\t]*\tinvalid'` (dfe4c0d:768) for the first record, a middle record and a valid record; does not establish a pipefail test of this check (none exists; see Claim 30).
**Legibility-target:** for-orchestrator-synthesis

`local re=$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'; if [[ "$after" =~ $re ]]` (`:927-928`). X4: `invalid regex: matches mid-string record`, `matches first record`, `valid not matched`. The pre-existing functional tests at `test/cc-isolated-functions.bats:1352` and `:1362` pass in X2.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:925-931`, `$D/logs/exp2.txt`, `$D/logs/bats-full.txt`

---

## Claim 18: cc-isolated `--help` EXIT STATUS: "0 success; after a session: the exit scan found nothing (or only standard linked worktrees, with a note on stderr), and claude's own exit status is passed through"

**Location:** `devcontainer-config/cc-isolated.sh:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help text rendering and the exit mapping; does not establish a live host session (`Live-verified: no`).
**Legibility-target:** for-orchestrator-synthesis

`usage()` prints the header comment (`:566-567`). Running `bash devcontainer-config/cc-isolated.sh --help` shows the new lines. The mapping is `0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;;` (`:747-751`). X1 test 9 (`test/cc-isolated-functions.bats:2386-2394`) asserts status 0 and the note with no WARNING.

**Evidence:** `devcontainer-config/cc-isolated.sh:19-33`, `:566-567`, `:743-751`, `$D/logs/bats-q094.txt`

---

## Claim 19: "`git worktree add <ws>/.claude/worktrees/agent-x -b wt-x` during a session adds exactly three records to the exit snapshot"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:9-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an empty global config; does not establish the count when your own config has a relative hooksPath (X4 saw a fourth record, `hooksdir <wt>/.husky/_`, as designed).
**Legibility-target:** for-orchestrator-synthesis

X1 test 1 accepts only when every diff line is `+F dotgit|commondir-file|hooksdir` and each is consumed once per worktree (`cc-exit-scan.sh:831-833`, `:892`). X4's host-form listing shows exactly those three plus the global-hooksPath record.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:828-892`, `$D/logs/bats-q094.txt`, `$D/logs/exp2.txt`

---

## Claim 20: "`devcontainer.json` mounts the checkout at `/workspace`, and git 2.39 (the image's git) writes absolute paths."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:21`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mount and git 2.39.5 writing absolute paths; the image's git version is inferred from `FROM node:22` (Debian 12), matching this sandbox (Debian 12, git 2.39.5); does not establish the version in a freshly built image.
**Legibility-target:** for-orchestrator-synthesis

`FROM node:22` (`devcontainer-config/Dockerfile:14`) and `git \` from apt (`:24`). The mount is at `devcontainer.json:134`. E1 is in `$D/logs/exp.txt`.

**Evidence:** `devcontainer-config/Dockerfile:14-24`, `devcontainer-config/devcontainer.json:134`, `$D/logs/exp.txt`

---

## Claim 21: "The scan already records the private dir (`.git/worktrees/<n>`) by its fixed layout: config, config.worktree, info/attributes, hooks/ + entries, commondir, legacy remotes/branches, rebase-merge/, rebase-apply/, sequencer/, every symlink, and nested modules/** / worktrees/*."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a private dir reached through `_snap_nested "$real/worktrees"`, which needs `HEAD` plus `commondir` or `objects/`; does not establish recording of a private dir whose HEAD was deleted. Such a dir is not walked, but then no `commondir-file` record exists and the note cannot be given.
**Legibility-target:** for-orchestrator-synthesis

`for f in config config.worktree; do _snap_opt config …` (`:578-581`), `_snap_opt attributes "$real/info/attributes"`, `_snap_hooks "$real/hooks"`, `_snap_opt commondir-file` (`:582-584`), legacy remotes (`:594-614`), sequencer state (`:616-623`), symlinks (`:626-636`), `_snap_nested "$real/modules"` / `"$real/worktrees"` (`:637-638`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:551-639`

---

## Claim 22: "The launcher maps `git_exit_scan` 0 → claude's own status, 1 → exit 3, 2 → exit 4. The acceptance lives inside `git_exit_scan` and returns 0, so `cc-isolated.sh` does not change."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:23`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The mapping is right and the launcher logic is unchanged; does not hold for the file as a whole, whose header comment, and so its `--help` output, changed in this unit.
**Legibility-target:** for-author

`case "$scan" in 0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;;` (`cc-isolated.sh:747-751`). But `git diff dfe4c0d q094-exit-scan-worktree-layout -- devcontainer-config/cc-isolated.sh` shows +2/-1 in the EXIT STATUS comment (`:20-21`). Tighten to "cc-isolated.sh's logic does not change (only its --help text)".

**Evidence:** `devcontainer-config/cc-isolated.sh:20-21`, `:743-751`

---

## Claim 23: Experiments table E1–E12

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:29-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Re-ran E1, E2, E3 (pre-commit, post-commit, post-checkout, with control), E4 (with control), E5 (without a positive control for fsmonitor), E6, E7, E8, E9, E10, E11 and E12; does not establish E3's pre-push and reference-transaction hooks, which were not re-run.
**Legibility-target:** for-orchestrator-synthesis

X3 results:
- E1: commondir is 6 bytes, `.  .  /  .  .  \n`. P holds `HEAD ORIG_HEAD commondir gitdir index logs`.
- E2: every path resolves to the side the table says.
- E3–E6: as quoted in Claim 2.
- E7, E8, E9: `yes`.
- E10: `fatal: not a git repository` for both the missing-HEAD and the missing-path cases.
- E11: all four commondir variants (absolute, `../../\n`, `../..\r\n`, `../..` with no newline) resolve to the common dir.
- E12: `wt=gone P=gone worktrees/=gone`.

**Evidence:** `$D/logs/exp.txt`

---

## Claim 24: Acceptance rules 1–5 and 7 match the code

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:48-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each rule's check against `scan_std_worktrees` and `git_exit_scan`; does not re-derive rule 6, which lives in unit B.
**Legibility-target:** for-orchestrator-synthesis

The rules map to the code as follows:

| Rule | Code |
|---|---|
| 1 (no `invalid` finding) | `[ -z "$invalid" ] &&` (`cc-exit-scan.sh:935`) |
| 2 (only the three kinds, no C records) | `:831-833` |
| 3 (no W record) | `:813` |
| 4 (checkout's own common dir, `<n>` charset) | `:818-819`, `:843-847` |
| 5 (the per-worktree checks) | `:848-887` |
| 7 (every record consumed) | `:892` |

Rule 5's "when `<common>` is inside the checkout" matches `case "$common" in "$wsp") ccommon="$cws" ;; "$wsp"/*) …` (`:820-823`). The plan's line `:63`, "the note names only `<n>` values … through `scan_vis`", matches `:894-895` and `:936`. No git command runs in `:806-896`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `:925-938`

---

## Claim 25: "this unit came to 447 lines with it"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the committed states only; does not establish the count of the uncommitted pre-split working state the sentence refers to.
**Legibility-target:** for-orchestrator-synthesis

No commit holds "iteration-1 fixes plus removal acceptance". The counts outside `docs/` against dfe4c0d are 389 at b4de821 and 394 at 5a6d689 (paraphrased — no quote available because these are computed `git diff --numstat` sums, not source lines). Verifying 447 would need the discarded pre-split tree.

**Evidence:** `git diff --numstat dfe4c0d b4de821|5a6d689 -- . ':!docs'`

---

## Claim 26: "`_snap_config` and `_snap_remote` add `W <kind> <config or path %q>` whenever they resolve a path against a working tree. `scan_diff` ignores record types other than F and C, and a `W` record only changes when a C or F record does, so the report output is unchanged."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:65`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every working-tree resolution in `_snap_config` (hooksPath, attributesFile, the remote-name deferral, url/pushurl, insteadOf/pushInsteadOf) and `_snap_remote` (every relative local path except `.`), and the unchanged warning output (169/169 pre-existing plus new tests); does not cover `_snap_host_config`, which resolves against a working tree but emits F records instead, as the header says.
**Legibility-target:** for-orchestrator-synthesis

`include.path` resolves against the config's directory (`_snap_path "$val" "$(dirname -- "$f")"`, `:397`), not a working tree, so it correctly makes no W. `scan_diff` ignores W at `:755-756`. X2 passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-421`, `:752-769`, `$D/logs/bats-full.txt`

---

## Claim 27: Bypass table "covered" rows B1–B14, B16–B20, B26 and their stated mechanisms

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:73-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each row's cited mechanism in code and, where a test exists, the test:
- B1, B2, B3, B7: test 5
- B8, B10, B17: test 6
- B16, B18, B19: test 7
- B12, B13: test 8
- B20: test 1
- B26: test 6
- B14's container-form half: X4

It does not establish B21–B23 and B27, whose accepting halves live in unit B; here only "any removal warns" is checked (test 3).
**Legibility-target:** for-orchestrator-synthesis

B14: X4 shows the host-form walk refusing the note, and the container form failing host git with `fatal: not a git repository`. B18 compares `%q` strings (`:847`, `:850`, `:874`). Every test listed passed in X1.

**Evidence:** `test/cc-isolated-functions.bats:2227-2384`, `devcontainer-config/cc-exit-scan.sh:806-896`, `$D/logs/bats-q094.txt`, `$D/logs/exp2.txt`

---

## Claim 28: B15: "`.gitmodules` `update=!cmd` is ignored by git"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:87`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git submodule update --init` on 2.39.5 after a clone; does not establish other submodule commands.
**Legibility-target:** for-author

X7: `fatal: invalid value for 'submodule.s.update'` and `update=!cmd from .gitmodules ran: no`. The command is not run, as the row concludes, but git refuses the value with a fatal error rather than ignoring it. Tighten to "rejected by git (fatal), never run".

**Evidence:** `$D/logs/exp4.txt`

---

## Claim 29: B25: "Newer git writing relative paths (`worktree.useRelativePaths`, git ≥ 2.48) — not accepted (warns)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:97`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The "warns" half is verified: X1 test 6 writes the relative form `gitdir: ../../../.git/worktrees/agent-x` and gets a warning. The git ≥ 2.48 / `worktree.useRelativePaths` attribution needs git ≥ 2.48 or its release notes, and the sandbox has git 2.39.5 and no network.
**Legibility-target:** for-orchestrator-synthesis

The test loop includes `$'gitdir: ../../../.git/worktrees/agent-x\n'` followed by `warns_listing_wt` (`test/cc-isolated-functions.bats:2320-2324`).

**Evidence:** `test/cc-isolated-functions.bats:2315-2342`, `$D/logs/bats-q094.txt`

---

## Claim 30: B28: "The test (40k padding records) covers the two checks in `scan_std_worktrees`; the `invalid` check has no test of its own"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutation sensitivity of the two `scan_std_worktrees` checks; does not settle the `invalid` clause, which is true only in the narrow sense that it has no pipefail or large-snapshot test.
**Legibility-target:** for-author

X5: M2 (W check back to a pipeline) fails at `test/cc-isolated-functions.bats:2285` (`[ "$status" -eq 1 ]`), and M3 (commondir check back to a pipeline) fails at `:2283` (`[ "$status" -eq 0 ]`). So the test does cover both checks, each on its own. The `invalid` check does have functional tests (`[[ "$output" == *"! $SCAN_WS/.git is not a valid git directory now"* ]]`, `test/cc-isolated-functions.bats:1352`, `:1362`), and they pass on the new `[[ =~ ]]` form. Tighten to "has no pipefail test of its own".

**Evidence:** `test/cc-isolated-functions.bats:1352`, `:1362`, `:2273-2286`, `$D/logs/mut-M2-W-pipeline.txt`, `$D/logs/mut-M3-commondir-pipeline.txt`

---

## Claim 31: B29 (push to `.` from a worktree runs the common `pre-receive`, not the private one) and B30 (insteadOf base `.` and `""` experiments; "a mutation that drops `""` fails them")

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:101-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both experiments and the mutation; does not establish pushInsteadOf by experiment, only by test case: `url..pushInsteadOf` is in test 8.
**Legibility-target:** for-orchestrator-synthesis

The X3 and X5 results are quoted in Claims 8 and 9.

**Evidence:** `$D/logs/exp.txt`, `$D/logs/mut-M4-drop-empty.txt`, `test/cc-isolated-functions.bats:2367-2384`

---

## Claim 32a: Step 3 lists a test for "private dir left behind after removal → 1"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:110`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers unit A's test file at 9075003; does not examine unit B's copy beyond locating the moved test.
**Legibility-target:** for-author

No Q-094 test in unit A exercises a private dir left behind. The only removal test is "a worktree removed during the session still warns" (`test/cc-isolated-functions.bats:2263-2271`), which does a clean `git worktree remove`. The half-removed case lived in b4de821's "a removed standard worktree is a note; a half-removed one warns" and now sits in unit B, `q094b-exit-scan-worktree-removal:test/cc-isolated-functions.bats:2263`. Drop the item from step 3, or mark it "(stacked unit)".

**Evidence:** `test/cc-isolated-functions.bats:2227-2394`, `git show b4de821:test/cc-isolated-functions.bats` (:2263)

---

## Claim 32b: Step 2: guide "the new known route list items (B12 cost, B25–B27 still warn)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:109`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the guide actually carries B12 and B25–B27; does not judge whether they belong in Known routes.
**Legibility-target:** for-author

The Known routes list gains only the `insteadOf` item and one sentence on tracked files (`guides/cc-isolated-usage.md:365-366`, `:385-387`). The B12 cost and the B25–B27 "still warns" cases appear in the Q-094 paragraph instead: "any checkout whose config holds a relative `core.hooksPath` …" (`:348-351`), "its working tree is inside the checkout" and "a worktree removed during it" (`:344`, `:348`). B25 (relative paths) is implied only by "exactly `gitdir: <private dir>\n`".

**Evidence:** `guides/cc-isolated-usage.md:334-351`, `:360-387`

---

## Claim 33: "A linked worktree added in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stubbed-launcher run; does not establish a live host session.
**Legibility-target:** for-orchestrator-synthesis

X1 test 9 (`test/cc-isolated-functions.bats:2386-2394`) passed, and the mapping is at `cc-isolated.sh:747-748`.

**Evidence:** `test/cc-isolated-functions.bats:2386-2394`, `devcontainer-config/cc-isolated.sh:747-748`, `$D/logs/bats-q094.txt`

---

## Claim 34: "3 the exit scan found a change (a note about standard worktrees is not one)"

**Location:** `guides/cc-isolated-usage.md:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same evidence as Claim 33; does not re-check the unchanged codes 1, 2 and 4.
**Legibility-target:** for-orchestrator-synthesis

`git_exit_scan` returns 0 on the note path (`cc-exit-scan.sh:937`), and 0 maps to `exit "$rc"`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:935-937`, `$D/logs/bats-q094.txt`

---

## Claim 35: Q-094 "Linked worktrees left behind" paragraph (the note text, the common-dir sourcing tested on 2.39.5, the `config.worktree` refusal, the "Exact" rule, and the "anything else warns" list including relative hooksPath/attributesFile/local remote other than `.`)

**Location:** `guides/cc-isolated-usage.md:334-351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence against the code and tests. "The checkout's own `.git/worktrees/<name>`" means the checkout's common dir (the same thing for a normal checkout). The "other than `.`" exception applies to remote URLs and names: `insteadOf` bases `.` and `""` do warn, which the paragraph does not state (the insteadOf case appears only under Known routes). The paragraph does not establish the note for repos whose embedded or vendored repos hold a relative hooksPath; those also warn, because any W in the snapshot refuses.
**Legibility-target:** for-orchestrator-synthesis

Note prefix: `echo "note: exit scan: only linked worktrees in git's standard layout changed (${line% }). …"` (`cc-exit-scan.sh:895`). The rule is as in Claim 13. The warn list is exercised by tests 1, 3 and 8.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `test/cc-isolated-functions.bats:2227-2384`, `$D/logs/bats-q094.txt`

---

## Claim 36: "The same holds in a linked worktree the session leaves behind: its tracked files are never read, only its layout"

**Location:** `guides/cc-isolated-usage.md:365-366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the scan's reads in a worktree's tree: `find -name .git` lists names, and the `.git` entries are read. It does not cover your own config's relative hooksPath/attributesFile targets inside that tree, which are recorded (Claim 4). Those are not tracked content, and a tracked file used as one would be hashed.
**Legibility-target:** for-orchestrator-synthesis

`_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git` (`cc-exit-scan.sh:694`), then `_snap_dotgit` on each hit (`:699`). The only file read inside the new worktree in `scan_std_worktrees` is `$wt/.git` (`:881`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:686-703`, `:874-882`

---

## Claim 37: Known route: "A URL rewritten by `url.<base>.insteadOf`. The base is walked, never the rewritten URL, so a remote rewritten to a local path the session plants runs that repository's hooks on push."

**Location:** `guides/cc-isolated-usage.md:385-387`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk: only `_snap_remote "$t"` on the base. The route itself was reproduced in a linked worktree (X3 B30); it does not establish the top-level-checkout variant by experiment (static only).
**Legibility-target:** for-orchestrator-synthesis

`t="${key#url.}"; t="${t%.*}" … _snap_remote "$t" "$base"` (`cc-exit-scan.sh:416-418`). A remote `https://…` returns early at `*://*) return 0 ;;` (`:352`), so the rewritten URL is never formed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-354`, `:414-418`, `$D/logs/exp.txt`

---

## Claim 38: The nine Q-094 test names match what the tests assert (including "large snapshots under pipefail neither lose the note nor skip the W refusal", "a private dir git would also accept …", and the FIFO "must not block the scan")

**Location:** `test/cc-isolated-functions.bats:2227-2394`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title against its assertions, and mutation sensitivity for tests 4, 6 and 8. Test 8's title ("keeps a new worktree a finding") is narrower than its body, which also asserts that the absolute-hooksPath and `.`-remote cases give status 0. It does not establish sensitivity of tests 1, 2, 5 and 7 to mutations.
**Legibility-target:** for-orchestrator-synthesis

The details:
- "Git would also accept" holds for all four commondir variants (X3 E11).
- The pipefail test builds `for i in $(seq 40000)` padding and runs under `set -o pipefail` (`:2279-2285`).
- The FIFO case runs `timeout 20 … git_exit_scan` and asserts `warns_listing_wt` (`:2333-2335`). M1 fails it at `:2335`.
- X1 passed 9/9.

**Evidence:** `test/cc-isolated-functions.bats:2206-2394`, `$D/logs/bats-q094.txt`, `$D/logs/mut-M1-no-f-guard.txt`, `$D/logs/exp.txt`

---

## Claim 39: "The container path the scan accepts is where devcontainer.json mounts the checkout." (bats check)

**Location:** `test/cc-isolated-functions.bats:2382-2383`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current file, where the only `target=/workspace,` is `workspaceMount` (`devcontainer.json:134`); does not establish that the grep is tied to the `workspaceMount` key. Any mount string containing `target=/workspace,` would satisfy it.
**Legibility-target:** for-orchestrator-synthesis

`grep -q "target=$GIT_EXIT_SCAN_CONTAINER_WS," "$CONFIG_SRC/devcontainer.json"` (`:2383`). The grep finds `target=` at `devcontainer.json:78`, `:79` (other targets) and `:134`. X1 passed.

**Evidence:** `test/cc-isolated-functions.bats:2383`, `devcontainer-config/devcontainer.json:78-79`, `:134`

---

## Claim 40a: 5a6d689: "A FIFO planted at .git/worktrees/<n>/gitdir blocked the exit scan's read in scan_std_worktrees … Test: a FIFO there warns within a timeout."

**Location:** commit `5a6d689` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard at the tip and the test's sensitivity to removing it; does not re-run at 5a6d689 itself.
**Legibility-target:** for-orchestrator-synthesis

`[ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1` (`cc-exit-scan.sh:860`). M1 (X5) fails test 6 at the FIFO step, `test/cc-isolated-functions.bats:2335`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:858-863`, `$D/logs/mut-M1-no-f-guard.txt`

---

## Claim 40b: 5a6d689: "The rest of the scan checks -f before every read; this one now does too."

**Location:** commit `5a6d689` message
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the state at 5a6d689, where the claim was false, and at 9075003, where it now holds, as far as every file read was traced (`_snap_first_line` callers, `_snap_hash`, `_snap_config`, legacy `cat`, `gitdir_head_kind`); does not establish TOCTOU safety.
**Legibility-target:** for-author

At 5a6d689, `_snap_worktree_of` read `$1` with no `-f`: `elif v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then` (`git show 5a6d689:devcontainer-config/cc-exit-scan.sh:325`). A FIFO `config` next to a legacy `remotes/` file hangs the snapshot there (X6 mutant M7, which restores that line: rc 124). c32a734's message acknowledges this ("makes 5a6d689's '-f before every read' true"), and the tip adds `[ -f "$1" ] &&` (`:328`). A commit message cannot be amended without a rewrite, so this is recorded for the history only; the tip's code matches the claim.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:328`, `git show 5a6d689:devcontainer-config/cc-exit-scan.sh` (:325), `$D/logs/exp3-mut.txt`, `$D/logs/exp3-tip.txt`

---

## Claim 41: c32a734: R1 (pipefail fail-open; "All three checks, including the older `invalid` check …, are now bash pattern matches. Test: 40k padding records, both directions, under pipefail"), the `-f` guard in `_snap_worktree_of` ("a FIFO config hung the snapshot"), indexed dotgit lookup, the 4097-byte cap, "a '.' remote … makes no W record (verified …)", and the devcontainer.json bats check

**Location:** commit `c32a734` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each code-level statement at the tip; does not verdict the reported review-finding severities or the "(hidden only by the next check failing the same way)" history at b4de821, which was not re-run.
**Legibility-target:** for-orchestrator-synthesis

The pieces:
- Three `[[ ]]` checks at `:813`, `:819` and `:928`, with no `grep -q` pipelines left.
- X4 shows the old pipeline returning FALSE (141).
- M2 and M3 fail the test.
- X6 covers the FIFO config.
- The indexed lookup is `dot["${line%$'\t'*}"]="$line"` (`:831`) with `dk="${dot[…]:-}"` (`:874`).
- The cap is `-le 4097` (`:861`).
- The `.` remote is covered by B29 (X3) and M6.
- The bats check is at `:2383`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:811-892`, `:926-928`, `$D/logs/exp2.txt`, `$D/logs/exp3-tip.txt`, `$D/logs/mut-M2-W-pipeline.txt`, `$D/logs/mut-M3-commondir-pipeline.txt`, `$D/logs/mut-M6-no-dot-exempt.txt`

---

## Claim 42: 037621f: insteadOf base "." bypass ("a host push there ran its hook"), "a mutation that drops the line fails it", "unit at 399 changed code lines outside docs/ against dfe4c0d"

**Location:** commit `037621f` message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the experiment, the mutation (M5 at the tip, which also removes the `""` arm that came later) and the line count; does not verdict "Performance iteration 2: no findings", which is a review outcome, not code.
**Legibility-target:** for-orchestrator-synthesis

X3: `B30 base='.' … hook ran: yes`. M5 fails test 8. `git diff --numstat dfe4c0d 037621f -- . ':!docs'` gives 171+4, 2+1, 29+3 and 189+0, which is 399 (paraphrased — no quote available because this is a computed numstat sum).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:417`, `$D/logs/exp.txt`, `$D/logs/mut-M5-drop-line.txt`

---

## Claim 43: 9075003: "git accepts `[url \"\"] insteadOf = …` (key url..insteadof), which rewrites a remote to a bare relative path … _snap_remote returns early on \"\" … A base of \"\" or \".\" now always makes a W record. … a mutation that drops \"\" fails them."

**Location:** commit `9075003` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the experiment, the early return, the fix and the mutation; does not verify "it has not been re-reviewed by a critic", which is process history.
**Legibility-target:** for-orchestrator-synthesis

`_snap_remote` begins `case "$p" in "") return 0 ;;` (`cc-exit-scan.sh:348-349`). X3: `B30 base='' rewrites to 'evil' hook ran: yes`. M4 fails test 8 at `test/cc-isolated-functions.bats:2380`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-349`, `:417`, `$D/logs/exp.txt`, `$D/logs/mut-M4-drop-empty.txt`

---

## Claim 44: b4de821: "when every record-level difference is a worktree … added or removed in the exact layout git writes, it prints one note: line and returns 0 … Removed worktrees need P gone on disk."

**Location:** commit `b4de821` message
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tip's behaviour; true at b4de821, whose code accepted `[+-]F` records; does not re-verify unit B's removal acceptance.
**Legibility-target:** for-author

At b4de821 the loop accepted `[+-]F$'\t'dotgit$'\t'*|…` (`git show b4de821:devcontainer-config/cc-exit-scan.sh:825`). At the tip only `+F…` records pass, and any removal is `*) return 1` (`:831-833`). X1 test 3, "a worktree removed during the session still warns", passes. Removal acceptance moved to unit B (c32a734). Nothing to fix in the history; a reader of `git log` on this branch should know that c32a734 supersedes it.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:828-835`, `test/cc-isolated-functions.bats:2263-2271`

---

## Claim 45: 5fadfc2: "No code behaviour change; the only line in cc-exit-scan.sh that changes is comments."

**Location:** commit `5fadfc2` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff `5fadfc2~1..5fadfc2` in cc-exit-scan.sh, where two changed lines are both comments; does not cover the other files in the commit (docs only).
**Legibility-target:** for-orchestrator-synthesis

The diff's changed lines are `# core.hooksPath, core.attributesFile or local remote (not ".") in repo config would` and `  # Only linked worktrees added in git's standard layout (STANDARD`. Both are comments. "The only line" is loose (there are two), but the stated conclusion, no behaviour change, holds.

**Evidence:** `git diff 5fadfc2~1 5fadfc2 -- devcontainer-config/cc-exit-scan.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 40b** (commit `5a6d689`): "The rest of the scan checks -f before every read" was false at that commit, because `_snap_worktree_of` had no `-f` (a FIFO config hangs the snapshot). The tip fixes it (`cc-exit-scan.sh:328`) and c32a734 says so. This is history only; there is nothing to change at the tip.

### Stale
- **Claim 32a** (`docs/working/plan-q094-exit-scan-worktree-layout.md:110`): step 3 still lists a "private dir left behind after removal → 1" test, which moved to unit B with removal acceptance. Drop it or mark it "(stacked unit)".
- **Claim 44** (commit `b4de821`): "added or removed" and "Removed worktrees need P gone on disk" describe the pre-split code; at the tip any removal warns (c32a734 supersedes it).

### Mostly Accurate
- **Claim 4** (`devcontainer-config/cc-exit-scan.sh:83-84`): your own config's relative hooksPath is walked only in new worktrees whose `.git` resolves on the host. A container-form worktree not present on the host is not walked, and the note is given. That is safe, because host git refuses it, but the sentence should say so.
- **Claim 22** (`docs/working/plan-q094-exit-scan-worktree-layout.md:23`): "cc-isolated.sh does not change". Its EXIT STATUS header, and so its `--help` output, did change; only the logic is unchanged.
- **Claim 28** (`docs/working/plan-q094-exit-scan-worktree-layout.md:87`): git does not ignore `.gitmodules` `update=!cmd`; it rejects it (`fatal: invalid value`). The command never runs either way.
- **Claim 30** (`docs/working/plan-q094-exit-scan-worktree-layout.md:100`): "the `invalid` check has no test of its own" should read "no pipefail test of its own". Functional tests at `test/cc-isolated-functions.bats:1352` and `:1362` exercise the new `[[ =~ ]]` form.
- **Claim 32b** (`docs/working/plan-q094-exit-scan-worktree-layout.md:109`): step 2 says Known routes gains "B12 cost, B25–B27 still warn". The guide carries those in the Q-094 paragraph instead, and Known routes gained the insteadOf item.

### Unverifiable
- **Claim 25** (`docs/working/plan-q094-exit-scan-worktree-layout.md:60`): "447 lines" refers to an uncommitted pre-split state. The committed states count 389 and 394.
- **Claim 29** (`docs/working/plan-q094-exit-scan-worktree-layout.md:97`): the `worktree.useRelativePaths` / git ≥ 2.48 attribution needs a newer git or its release notes. The "warns" half is verified.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown code-fact-check report saved at the output path below, structured per the code-fact-check skill, with the header fields `**Commit:** 9075003` and per-claim sections.
- Answered: yes. 47 claims: the ten focus areas, plus the plan's context and rule claims and every commit message in range.
- Out of scope: the `docs/reviews/` artifacts in the range (per the brief); unit B's removal acceptance; the pre-existing slow-scan clause (`guides/cc-isolated-usage.md:379-384`). That clause is unchanged in this range: the Q-094 per-worktree millisecond sentence was added in c32a734 and removed in 037621f, so no Q-094 timing claim remains to check.
- Escalate: nothing blocking. Claim 4's safety rests on a container-form `.git` not resolving on the host; that is covered by :885-887, E10 and X4. The one Incorrect is in an immutable commit message and is already acknowledged by c32a734.
- Decisions I made: I verdicted commit messages against their own commit, so b4de821 is Stale rather than Incorrect and 5a6d689's "-f before every read" is Incorrect. I kept the scan_std_worktrees doc comment (Claim 13) Verified because its unstated extra checks only narrow acceptance, and listed them in its Scope. I re-ran the experiments under the global-config isolation the plan names.
