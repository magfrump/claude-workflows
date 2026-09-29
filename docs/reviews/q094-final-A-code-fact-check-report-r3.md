# Code Fact-Check Report

**Commit:** 9075003
**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094-exit-scan-worktree-layout`, read via `git show`/`git archive`; not checked out)
**Scope:** `git diff dfe4c0d..9075003 -- . ':!docs/reviews'`: `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-isolated.sh`, `guides/cc-isolated-usage.md`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `test/cc-isolated-functions.bats`, plus the commit messages of the 7 commits in the range
**Checked:** 2026-09-28 (executions 2026-09-29T03:12Z–03:19Z UTC)
**Total claims checked:** 45
**Summary:** 32 verified, 7 mostly accurate, 2 stale, 2 incorrect, 2 unverifiable

Execution environment for every `executed` claim: the tree was extracted with `git -C <repo> archive q094-exit-scan-worktree-layout | tar -x -C $D`, where `D=/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcA-r3x7` (cwd for all runs). Bats ran as `TMPDIR=$D/tmp LC_ALL=C GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 bats ...`. Host git 2.39.5, Bats 1.8.2. Captured output is under `$D/logs/`. Mutation runs used `$D/mut.sh <name> <old> <new> <bats -f filter>`, which copies the tree to `$D/mut-<name>`, makes exactly one string replacement in `cc-exit-scan.sh` (it asserts a count of 1), and runs the filtered tests. Their logs are `$D/logs/mut-<name>.txt`, each ending in `exit=<bats status>`.

Baseline: `bats -f "Q-094"` gave 9/9 ok, exit 0 (`$D/logs/q094-tests.txt`, 03:12:11Z). The full `test/cc-isolated-functions.bats` gave 169/169 ok, exit 0 (`$D/logs/full-suite.txt`).

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): I compared every claim against the five logged patterns, all of them "a specific measured value quoted from an artifact set that does not contain it". The one numeric claim of that kind here, commit 037621f's "399 changed code lines", recomputes exactly (Claim 40). No claim matches a logged pattern, and no new fabrication was found.

---

## Claim 1: "When every difference is a linked worktree added in git's own layout (agent worktrees outlive sessions), the scan prints one `note:` and returns 0"

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added-worktree path of `git_exit_scan` → `scan_std_worktrees` for host-form and container-form worktrees. It does not establish behaviour for removals (unit B) or for layouts written by git ≥ 2.48 with relative paths.
**Legibility-target:** for-orchestrator-synthesis

`git_exit_scan` calls the acceptance before rendering:

```bash
# devcontainer-config/cc-exit-scan.sh:934-938
  local note
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```

Test 1 (`test/cc-isolated-functions.bats:2227`) asserts status 0 and exactly one output line starting `note: exit scan:`. It passed (`$D/logs/q094-tests.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-968`, `test/cc-isolated-functions.bats:2227-2241`, `$D/logs/q094-tests.txt` (cmd `bats -f "Q-094" test/cc-isolated-functions.bats`, exit 0, 2026-09-29T03:12:11Z)

---

## Claim 2: "In a linked worktree git takes config, hooks and info/attributes from the common dir, never the private one (tested on git 2.39.5; the one exception, config.worktree under extensions.worktreeConfig, refuses the note)"

**Location:** `devcontainer-config/cc-exit-scan.sh:77-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5: `--git-path` resolution for hooks, info/attributes and config, private-dir hooks not run, private-dir `config` core.hooksPath ignored, and `config.worktree` in P refusing the note. It does not re-run E4 (filter via private info/attributes) or E6, and it does not establish other git versions.
**Legibility-target:** for-orchestrator-synthesis

I re-ran the experiments in a scratch repo (`$D/exp.sh`). `git rev-parse --git-path` in the worktree printed `hooks -> …/r/.git/hooks`, `info/attributes -> …/r/.git/info/attributes` and `config -> …/r/.git/config`, but `config.worktree -> …/r/.git/worktrees/w1/config.worktree`. Private-dir `pre-commit`, `post-commit` and `post-checkout` hooks did not run on commit and checkout ("no private hook ran"), while the common `post-commit` control ran. A `core.hooksPath` in the private `config` was "not used". On the refusal: `_snap_gitdir` records `F config <P>/config.worktree` (`_snap_opt config "$real/$f"`, `cc-exit-scan.sh:578-579`), and that kind is not in the accepted set. The code also checks `for k in hooks config config.worktree; do [ ! -e "$p/$k" ] ...` (`cc-exit-scan.sh:856`). Test 5's `config.worktree` case warns.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:573-580`, `devcontainer-config/cc-exit-scan.sh:856`, `test/cc-isolated-functions.bats:2288-2313`, `$D/logs/experiments.txt` (cmd `bash $D/exp.sh $D/exp`, exit 0, 2026-09-29T03:16:14Z)

---

## Claim 3: "A relative core.hooksPath, core.attributesFile or local remote (not ".") in repo config would resolve in the new worktree's own tree, unscanned: those leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:80-83`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers W emission for relative hooksPath, attributesFile and remote values, and the refusal on any W. It does not establish that the refusal set is limited to what the sentence names, and in fact it is wider: see the two qualifiers below.
**Legibility-target:** for-author

The mechanism is right. `_snap_wrel "$key" "$f" "$val"` runs for `core.hookspath` and `core.attributesfile` (`cc-exit-scan.sh:393,401`), `_snap_remote` calls `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`:357`), and the refusal is `[[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1` (`:813`). The sentence has two imprecisions:

- The "(not ".")" exemption covers only a remote value of `.`. An insteadOf base of `.` or `""` always makes a W record: `case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac` (`:417`). A reader could take "." to be exempt everywhere.
- "in repo config" undercounts. `_snap_config` emits W for every config the scan reads, including embedded repos' configs, which git never resolves in the new worktree. Executed: an embedded repo `emb` with `core.hooksPath .h` produced `W	core.hookspath	…/emb/.git/config`, and a standard worktree then warned (rc=1). This errs on the fail-closed side.

Suggested wording: "a relative core.hooksPath or core.attributesFile, a relative local remote other than a remote of ".", or an insteadOf base of "." or "", in any config the scan reads".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:355-357`, `devcontainer-config/cc-exit-scan.sh:386-419`, `devcontainer-config/cc-exit-scan.sh:813`, `$D/logs/hostcfg.txt` (cmd `bash $D/hc.sh $D`, exit 0, ~03:17Z)

---

## Claim 4a: "(Your own config's relative hooksPath is walked in each new worktree, so its records refuse the note as well.)" (host-form worktree)

**Location:** `devcontainer-config/cc-exit-scan.sh:83-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a worktree whose `.git` names the host path of P. It does not establish the container-form case (Claim 4b).
**Legibility-target:** for-orchestrator-synthesis

With `GIT_CONFIG_GLOBAL` set to a file holding `hooksPath = .husky`, adding a host-form worktree gave rc=1. The warning listed `+ hooksdir …/hc/a/w/x/.husky  missing` next to the three worktree records. That comes from the embedded-`.git` loop calling `_snap_host_config "$g" "$f" "${f%/*}"` (`cc-exit-scan.sh:694-701`). The resulting extra `hooksdir` record is never marked used, so `for rec in "${!left[@]}"; do [ -n "${used[$rec]:-}" ] || return 1; done` (`:892`) declines.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:496-533`, `devcontainer-config/cc-exit-scan.sh:690-702`, `devcontainer-config/cc-exit-scan.sh:892`, `$D/logs/hostcfg.txt`

---

## Claim 4b: same sentence, for a container-form worktree (`.git` = `gitdir: /workspace/.git/worktrees/<n>`) on a host not at `/workspace`

**Location:** `devcontainer-config/cc-exit-scan.sh:83-84`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the container-form worktree on a host whose checkout is not at the container path. It does not establish any exposure: host git cannot use such a worktree (E10).
**Legibility-target:** for-author

"Walked in each new worktree" is false here. `_snap_dotgit_target` returns nothing when the named git dir does not exist (`[ -d "$g" ] || return 0`, `cc-exit-scan.sh:547`). So `_snap_host_config` is skipped for that worktree (`[ -z "$g" ] || _snap_host_config …`, `:701`). No record is made, and the note is printed. Executed with the same global `hooksPath = .husky`, a container-form worktree gave `note: exit scan: only linked worktrees in git's standard layout changed (added: x). …` and rc=0.

This is the main case Q-094 targets (plan line 21: "A rule that accepted only the host path would never fire for the case Q-094 is about"). The safety conclusion still holds for a different reason than the comment gives: host git stops in a worktree whose `.git` names a missing path (plan B14 / E10; re-run for the missing-HEAD variant in `$D/logs/experiments.txt`, "fatal: not a git repository"). Fix the comment to match plan B14: walked only when the worktree's `.git` resolves on the host; otherwise host git refuses that worktree.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:536-551`, `devcontainer-config/cc-exit-scan.sh:694-701`, `docs/working/plan-q094-exit-scan-worktree-layout.md:86`, `$D/logs/hostcfg.txt` (section "same, container form")

---

## Claim 5: "W <kind> <config or path %q>   a path git resolves in the working tree it runs in (read by scan_std_worktrees; never reported, and it changes only with a C or F record)"

**Location:** `devcontainer-config/cc-exit-scan.sh:151-153`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every W producer (`_snap_wrel` call sites in `_snap_config` and `_snap_remote`) and the fact that `scan_diff` ignores W. It does not establish that W is emitted only for paths git resolves in the new worktree: embedded-repo configs also emit it (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

`_snap_wrel` is called only from `_snap_config` (`:393,401,417`) and `_snap_remote` (`:357`). Every value it sees comes from a config entry recorded as a C record (`_snap+="C"…`, `:390`) or from a legacy remotes or branches file recorded as `F legacy-remote` with its hash (`:599`). Whether a config is reached at all shows in its `F config` record (`:578`). The remote-name decision (`_snap_rnames`) depends only on C and F records (paraphrased — no quote available because the invariant is inferred from the four call sites and the `_snap_names` loop at `:707-713`). Never reported: `scan_diff` keys only on `$1 == "F"` and `$1 == "C"` (`:756-757`). `_snap_host_config` makes no W records (`:496-533`, no `_snap_wrel`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:290-294`, `devcontainer-config/cc-exit-scan.sh:346-419`, `devcontainer-config/cc-exit-scan.sh:596-613`, `devcontainer-config/cc-exit-scan.sh:707-713`, `devcontainer-config/cc-exit-scan.sh:752-769`

---

## Claim 6: "_snap_wrel <kind> <where> <value>: a W record when <value> is a relative path"

**Location:** `devcontainer-config/cc-exit-scan.sh:287-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the relative/absolute split: empty, `/…` and `~/…` make no record. It does not establish that git itself treats `~user/…` or a bare `~` as relative. The function emits W for those too, which errs on the fail-closed side.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-exit-scan.sh:290-294
_snap_wrel() {
  # shellcheck disable=SC2088  # matching a literal "~/" in the value
  case "$3" in ""|/*|"~/"*) return 0 ;; esac
  _snap+="W"$'\t'"$1"$'\t'"$(printf '%q' "$2")"$'\n'
}
```

**Evidence:** `devcontainer-config/cc-exit-scan.sh:287-294`

---

## Claim 7: `_snap_worktree_of` `[ -f "$1" ] &&` guard, and c32a734's "a -f guard in _snap_worktree_of (a FIFO config hung the snapshot; makes 5a6d689's '-f before every read' true)"

**Location:** `devcontainer-config/cc-exit-scan.sh:328`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hang via the legacy-remotes path (`_snap_worktree_of "$real/config"`) and a survey of every container-controlled read in the tip scan. It does not establish reads in `cc-gitdir.sh` beyond HEAD and commondir.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-exit-scan.sh:328
  elif [ -f "$1" ] && v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then
```

Executed with an embedded repo whose `.git/config` is a FIFO and whose `.git/remotes/o` holds `URL: ./x`. With the guard, `git_exec_snapshot` returned 0. With the guard removed (`$D/mut-noguard`), `timeout 15` killed it (exit 124). Survey of the other reads at the tip: `_snap_first_line` callers check `-f` first (`:123→125`, `:134→135`, `:540→541`, `:585→588`, `:860→862`); `_snap_hash` runs only after `-f` in `_snap_file` and `_snap_file_is` (`:230`, `:243-245`, `:787-789`); `_snap_config` is called only after `-f` (`:580`, `:399`, `:527`); the legacy `cat` after `[ -f "$f" ] || continue` (`:602→605`); `cc-gitdir.sh` checks `[ -f "$h" ] && [ -r "$h" ]` (`cc-gitdir.sh:33`) and `[ -f "$c" ] && [ -r "$c" ]` (`:57`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:321-335`, `devcontainer-config/cc-exit-scan.sh:596-613`, `devcontainer-config/cc-gitdir.sh:28-61`, `$D/logs/worktree-of-fifo.txt` (cmd `timeout 15 bash $D/fifo.sh <src> <tmp>` for the tip and for the mutant; exit 0 / exit 124; 2026-09-29T03:17:48Z)

---

## Claim 8: "'.' is the repository git runs in (a local-tracking branch's remote): in a linked worktree, the same common dir and hooks. Not a W record."

**Location:** `devcontainer-config/cc-exit-scan.sh:355-357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a push to `.` from a linked worktree (git 2.39.5) and the absence of a W record for a remote value `.`. It does not establish fetch or other transports to `.`.
**Legibility-target:** for-orchestrator-synthesis

`git push . HEAD:refs/heads/zz` from worktree `w1` ran the common `.git/hooks/pre-receive` ("ran-common-pre-receive"). `remote.o.url .` gave "no W for remote url .". Test 8's `branch.main.remote .` case expects status 0 and passes. The mutation that drops the exemption (`mut-dot-remote`) fails test 8.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:355-357`, `test/cc-isolated-functions.bats:2367-2384`, `$D/logs/experiments2.txt` (cmd `bash $D/exp2.sh $D/exp2`, exit 0, ~03:18Z), `$D/logs/hostcfg.txt`, `$D/logs/mut-dot-remote.txt` (exit=1)

---

## Claim 9: "a base "" or "." starts a relative path"

**Location:** `devcontainer-config/cc-exit-scan.sh:417`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `url.<base>.insteadOf` rewrites of a push URL for bases `""` and `.` on git 2.39.5. It does not establish other bases that yield relative paths (e.g. `sub`); those go through `_snap_remote` and get W anyway (`W	remote	sub` in `$D/logs/hostcfg.txt`).
**Legibility-target:** for-orchestrator-synthesis

From the worktree, `git -c url..insteadOf=https://x.invalid/ push https://x.invalid/evil` ran the hook of the planted bare repo at `<wt>/evil` ("ran-evil-baseEMPTY"). With base `.`, the hook of `<wt>/.evil` ran ("ran-.evil-base."). `git config -f` stores these as `[url ""]` and `[url "."]` and lists them as `url..insteadof` and `url...insteadof`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:414-418`, `$D/logs/experiments2.txt`

---

## Claim 10: "Where the container sees the checkout (devcontainer.json's workspaceMount target). Git in the container writes absolute paths under it into a new worktree's `.git` file and back-pointer."

**Location:** `devcontainer-config/cc-exit-scan.sh:771-773`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the devcontainer.json target and git 2.39.5 writing absolute paths into both files. It does not establish the git version actually inside the built image: the Dockerfile's `FROM node:22` is unpinned (see Claim 23).
**Legibility-target:** for-orchestrator-synthesis

`"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"` (`devcontainer-config/devcontainer.json:134`). E1 re-run: `.git` = `gitdir: /tmp/…/r/.git/worktrees/w1…` and back-pointer = `/tmp/…/r/wts/w1/.git`, both absolute.

**Evidence:** `devcontainer-config/devcontainer.json:134`, `devcontainer-config/cc-exit-scan.sh:774`, `$D/logs/experiments.txt`

---

## Claim 11: "_snap_hash_str <string>: _snap_hash of exactly those bytes." / "_snap_file_is <path> <hash>: <path> is a regular file, not a link, within the size cap, whose bytes hash to <hash>."

**Location:** `devcontainer-config/cc-exit-scan.sh:776, 783-784`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both helpers' full bodies. It does not establish NUL-containing strings, which bash cannot hold.
**Legibility-target:** for-orchestrator-synthesis

`h="$(printf '%s' "$1" | sha256sum)"; printf '%s' "${h:0:16}"` (`:779-780`) is the same 16-hex truncation as `_snap_hash` (`:169-173`). `_snap_file_is` runs `[ -f "$1" ] && [ ! -L "$1" ] || return 1; _snap_size_ok … || return 1; h="$(_snap_hash …)" || return 1; [ "$h" = "$2" ]` (`:787-790`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:167-174`, `devcontainer-config/cc-exit-scan.sh:776-791`

---

## Claim 12: scan_std_worktrees doc comment: every listed check (P naming, `<n>` charset, byte-exact commondir, back-pointer form, container-form resolution to P, no hooks/config/config.worktree/symlink in P, only dotgit/commondir-file/hooksdir added, no W record, %q comparison)

**Location:** `devcontainer-config/cc-exit-scan.sh:793-805`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole function (`:806-896`), read end to end. Every stated check is present in the code. The verdict concerns the checks the code makes that the comment does not state, which make "0 … when every difference is … git's standard layout" narrower in practice than written.
**Legibility-target:** for-author

Every stated check is in the code: W refusal (`:813`), `pre`/`%q` recomputation (`:838-847`), `^file [0-7]+ $std$` (`:848-849`), `hooksdir … missing` pairing (`:850-851`), real dirs (`:854`), no hooks/config/config.worktree (`:856`), `find -P "$p" -type l` (`:857`), back-pointer forms (`:860-868`), dotgit at snapshot time and now (`:874-883`), container form resolving to P (`:885-887`), all records used (`:892`). Tests 5, 6 and 7 plus mutations exercise them.

The comment does not list these additional declines:

- `[ "$n" != . ] && [ "$n" != .. ]` (`:845`)
- the exit snapshot's `F commondir` record must equal the recomputed common dir (`:818-819`)
- a back-pointer over 4097 bytes (`:861`)
- `<rel>` containing `.`, `..` or `//` components: `case "/$wtrel/" in */../*|*/./*|*//*) return 1` (`:870`)
- a working tree inside the common dir (`:872`)
- a container-form back-pointer when the common dir is outside the checkout: `[ -n "$ccommon" ] || return 1` (`:866`)

All are fail-closed. Suggest adding "not . or .." after the charset, and one clause for the `<rel>` normalisation.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:793-896`, `$D/logs/q094-tests.txt`, `$D/logs/mut-fifo.txt`

---

## Claim 13: "Pattern matches, not `printf | grep -q`: under the launcher's pipefail an early match SIGPIPEs printf, and the pipeline reads as 'no match'."

**Location:** `devcontainer-config/cc-exit-scan.sh:811-812`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's `set -euo pipefail` (`cc-isolated.sh:66`) and the fail-open effect on the W check and on the old `invalid` pattern with a large input. It does not establish a size threshold.
**Legibility-target:** for-orchestrator-synthesis

Mutation `W-grep` restores `! printf '%s\n' "$after" | grep -q $'^W\t' || return 1`. Test 4 then fails at line 2285 (`[ "$status" -eq 1 ]`), the W-refusal assertion, so the check failed open. `$D/inv.sh`: with `set -o pipefail` and 40k lines after a matching `invalid` line, the old `printf | grep -q` printed `old:NO-match` in 3 of 3 runs, and the new `[[ =~ ]]` printed `new:match`.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-exit-scan.sh:811-818`, `$D/logs/mut-W-grep.txt` (exit=1), `$D/logs/invalid-pipefail.txt` (cmd `bash $D/inv.sh` ×3, ~03:17Z)

---

## Claim 14: "Names are [A-Za-z0-9._-] only (checked above); the caller still scan_vis-es."

**Location:** `devcontainer-config/cc-exit-scan.sh:893`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every value appended to `added` and the caller's pipe. It does not establish the other text in the note, which is a fixed literal.
**Legibility-target:** for-orchestrator-synthesis

`added+=("$n")` (`:889`) runs only after `[[ "$n" =~ ^[A-Za-z0-9._-]+$ ]]` (`:845`). The caller runs `printf '%s\n' "$note" | scan_vis >&2` (`:936`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:845`, `devcontainer-config/cc-exit-scan.sh:889-895`, `devcontainer-config/cc-exit-scan.sh:936`

---

## Claim 15: git_exit_scan doc: "0 when nothing … changed, or only standard linked worktrees did (one `note:` line on stderr …); 1 … when anything else did; 2 when the exit state could not be read, or the snapshots differ but nothing renders."

**Location:** `devcontainer-config/cc-exit-scan.sh:898-903`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return statement of `git_exit_scan` (`:904-968`). It does not establish `scan_interrupted`'s exit path.
**Legibility-target:** for-orchestrator-synthesis

The returns are: `return 2` after a failed snapshot (`:920`); `… || return 0` when the snapshots are equal and valid (`:931`); `return 0` after the note (`:937`); `return 2` when `changes` is empty (`:945`); `return 1` after the warning (`:969`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-968`

---

## Claim 16: the `invalid` check's `[[ ]]` replacement ("A pattern match, not `printf | grep -q` (pipefail: see scan_std_worktrees)") matches what the old grep matched

**Location:** `devcontainer-config/cc-exit-scan.sh:926-930`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equivalence of `(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid` with the old line-anchored `^F\tgitdir-valid\t[^\t]*\tinvalid`, and the three existing gitdir-valid tests. It does not establish a large-snapshot test for this check (there is none, as B28 says).
**Legibility-target:** for-orchestrator-synthesis

`local re=$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'` (`:927`). The `$'…'` makes `\t` and `\n` real bytes, and adding `\n` to the negated class keeps the match within one line. With the old grep restored (`mut-inv-grep`), the three `exit scan gitdir:` tests still pass (exit=0). That is consistent with B28's "no test of its own", and `$D/logs/invalid-pipefail.txt` shows the old form failing open.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:922-930`, `$D/logs/mut-inv-grep.txt` (exit=0), `$D/logs/invalid-pipefail.txt`

---

## Claim 17: cc-isolated.sh help: "0 success; after a session: the exit scan found nothing (or only standard linked worktrees, with a note on stderr), and claude's own exit status is passed through"

**Location:** `devcontainer-config/cc-isolated.sh:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's mapping and test 9. It does not establish a live host session (`Live-verified: no` in every commit).
**Legibility-target:** for-orchestrator-synthesis

`0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;;` (`cc-isolated.sh:747-751`). The note goes to stderr (`scan_vis >&2`, `cc-exit-scan.sh:936`). `usage()` prints the whole header comment block (`awk 'NR > 1 && /^#/ …'`, `cc-isolated.sh:566-568`), so the new lines are included. Test 9 (`bats:2386`) runs the launcher with a stub session that adds a worktree, and asserts status 0 with the note and no WARNING. It passed.

**Evidence:** `devcontainer-config/cc-isolated.sh:17-33`, `devcontainer-config/cc-isolated.sh:564-568`, `devcontainer-config/cc-isolated.sh:740-751`, `$D/logs/q094-tests.txt`

---

## Claim 18: guide step 7 "A linked worktree added in git's own layout … is not a finding: one `note:` line, and the exit status is claude's" and Exit status "3 the exit scan found a change (a note about standard worktrees is not one)"

**Location:** `guides/cc-isolated-usage.md:66-68, 76-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 17.
**Legibility-target:** for-orchestrator-synthesis

The wording matches the mapping at `cc-isolated.sh:747-751` and test 9 (`$D/logs/q094-tests.txt`, ok 9).

**Evidence:** `devcontainer-config/cc-isolated.sh:747-751`, `test/cc-isolated-functions.bats:2386-2394`

---

## Claim 19: guide Q-094 paragraph: the "Exact" rule list, "Anything else warns as before … and any checkout whose config holds a relative `core.hooksPath` or `core.attributesFile` (husky's `.husky/_`) or a relative local remote other than `.`, which git would resolve in the new worktree's tree, unscanned."

**Location:** `guides/cc-isolated-usage.md:334-351`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule summary against `scan_std_worktrees` and the refusal list. It does not establish husky's actual `core.hooksPath` value.
**Legibility-target:** for-author

The rule summary matches the code: name charset `:845`, commondir `:848-855`, no hooks/config/config.worktree/symlink `:856-857`, working tree inside the checkout `:864-872`, `.git` host or container form `:878-887`. Test 8 confirms the refusals. Two imprecisions, as in Claim 3:

- "other than `.`" omits that an insteadOf base of `.` or `""` is never exempt (`cc-exit-scan.sh:417`; tests `url...insteadOf`, `url..insteadOf` and `url..pushInsteadOf` warn).
- A relative hooksPath in an embedded repo's config (not "the checkout's") also refuses the note (`$D/logs/hostcfg.txt`).

Both err toward more warnings, not fewer.

**Evidence:** `guides/cc-isolated-usage.md:334-351`, `devcontainer-config/cc-exit-scan.sh:414-418`, `test/cc-isolated-functions.bats:2367-2384`, `$D/logs/hostcfg.txt`

---

## Claim 20: "The same holds in a linked worktree the session leaves behind: its tracked files are never read, only its layout (see above)."

**Location:** `guides/cc-isolated-usage.md:365-366`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the scan reads inside a new worktree's working tree. It does not establish anything about tracked files git itself executes.
**Legibility-target:** for-author

The main point holds: the scan does not hash working-tree files in general. "Never read" is too strong, though:

- The embedded-repo `find -P … -name .git` walks the whole new tree (`cc-exit-scan.sh:694`).
- When your own config has a relative `core.hooksPath` and the worktree is host-form, `_snap_hooks` hashes every entry of `<wt>/<hooksPath>`, which may be tracked files (e.g. husky's `.husky/_`). Executed: `+ hooksdir …/w/x/.husky  missing` appeared in the warning.

That case refuses the note anyway, so this is imprecision, not a missed route. Suggest "its tracked files are not scanned".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:306-318`, `devcontainer-config/cc-exit-scan.sh:690-701`, `$D/logs/hostcfg.txt`

---

## Claim 21: "A URL rewritten by `url.<base>.insteadOf`. The base is walked, never the rewritten URL, so a remote rewritten to a local path the session plants runs that repository's hooks on push."

**Location:** `guides/cc-isolated-usage.md:385-387`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_config`'s insteadOf branch and `_snap_remote`'s early return for `scheme://` URLs. It does not establish every rewrite shape.
**Legibility-target:** for-orchestrator-synthesis

`t="${key#url.}"; t="${t%.*}"; … _snap_remote "$t" "$base"` (`:416-418`) walks only the base. The remote URL itself hits `*://*) return 0 ;;` (`:351`). Nothing computes base plus suffix (paraphrased — no quote available because the claim is an absence: grep finds no code composing the rewritten URL). Claim 9's experiment shows such a rewritten push runs the planted repo's hook.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-352`, `devcontainer-config/cc-exit-scan.sh:414-418`, `$D/logs/experiments2.txt`

---

## Claim 22: "`git worktree add <ws>/.claude/worktrees/agent-x -b wt-x` during a session adds exactly three records to the exit snapshot"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout with no relative hooksPath in the global config. It does not establish a checkout that has one (a fourth `hooksdir` record appears, Claim 4a).
**Legibility-target:** for-orchestrator-synthesis

Executed (embedded-repo case in `$D/logs/hostcfg.txt`): the warning lists exactly `+ commondir-file …/worktrees/x/commondir`, `+ hooksdir …/worktrees/x/hooks  missing` and `+ dotgit …/w/x/.git`.

**Evidence:** `$D/logs/hostcfg.txt`

---

## Claim 23: "`devcontainer.json` mounts the checkout at `/workspace`, and git 2.39 (the image's git) writes absolute paths."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:21`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The mount target is verified (Claim 10), and git 2.39.5 writing absolute paths is verified. The image's git version is not.
**Legibility-target:** for-orchestrator-synthesis

The Dockerfile has `FROM node:22` (`devcontainer-config/Dockerfile:14`) and installs distro `git` (`:24`), unpinned. The git version depends on which Debian release the `node:22` tag resolved to at build time. Verifying it needs a built image or registry access, and this sandbox has no network or docker. Any git below 2.48 without `worktree.useRelativePaths` would still write absolute paths.

**Evidence:** `devcontainer-config/Dockerfile:14-24`, `devcontainer-config/devcontainer.json:134`

---

## Claim 24: "The launcher maps `git_exit_scan` 0 → claude's own status, 1 → exit 3, 2 → exit 4. The acceptance lives inside `git_exit_scan` and returns 0, so `cc-isolated.sh` does not change."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:23`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping and the diff of `cc-isolated.sh`.
**Legibility-target:** for-author

The mapping is exact (`cc-isolated.sh:747-751`). Its code does not change, but `cc-isolated.sh` is in the diff: the EXIT STATUS header, which `--help` prints, changed (`+2 −1`, `git diff --numstat dfe4c0d 9075003`). Precise version: "`cc-isolated.sh`'s behaviour does not change; only its help text does."

**Evidence:** `devcontainer-config/cc-isolated.sh:20-23`, `devcontainer-config/cc-isolated.sh:747-751`

---

## Claim 25: Experiments table E1–E12

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:29-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Re-run on git 2.39.5: E1, E2, E3, E5, E7, E10 (missing-HEAD variant only), E11 (absolute and `../../`, plus CRLF), E12, and E9's shape via the B30 push experiments. E4, E6 and E8 were not re-run.
**Legibility-target:** for-orchestrator-synthesis

- E1: `.git` is `gitdir: <abs>`; `commondir` is `. . / . . \n` (6 bytes); back-pointer is `<abs wt>/.git`; the private dir holds `HEAD ORIG_HEAD commondir gitdir index logs`.
- E2: the `--git-path` list matches exactly.
- E3: "no private hook ran", while the common control ran.
- E5: "private config hooksPath not used".
- E7: "ran-e7".
- E10: `fatal: not a git repository: …/worktrees/w1`.
- E11: both variants gave the same `--git-common-dir`, and `../..\r\n` was accepted too (`$D/logs/experiments3.txt`).
- E12: `.git/worktrees` was gone after remove.

**Evidence:** `$D/logs/experiments.txt`, `$D/logs/experiments2.txt`, `$D/logs/experiments3.txt` (cmd `bash $D/exp3.sh $D/exp3`, exit 0, ~03:18Z)

---

## Claim 26: Acceptance rules 1–7 as the complete condition for the note

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:47-61`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rules 1–5 and 7 against `scan_std_worktrees` and `git_exit_scan`. Rule 6 describes unit B.
**Legibility-target:** for-author

Rules 1–5 and 7 are all implemented. Rule 1 is `[ -z "$invalid" ] &&` (`:935`); rule 2 is the `case` at `:830-834`; rule 4 names `.` and `..` explicitly. Unlike the source comment, rule 5 omits these declines:

- the 4097-byte back-pointer cap (`:861`)
- the `<rel>` component check (`:870`)
- the working tree not being inside the common dir (`:872`)
- the container-form back-pointer requiring `<common>` inside the checkout (`:866`; rule 5 states that condition only for the `.git` form)

Same class as Claim 12, fail-closed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `devcontainer-config/cc-exit-scan.sh:935`

---

## Claim 27a: "`_snap_config` and `_snap_remote` add `W <kind> <config or path %q>` whenever they resolve a path against a working tree."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:65`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every path resolution in the two functions.
**Legibility-target:** for-author

"Whenever" has two documented exceptions:

- `_snap_remote` resolves `.` against the base (`case "$p" in /*) ;; *) p="$base/$p" ;; esac`, `:358`) but emits no W, because `[ "$p" = . ] || _snap_wrel …` (`:357`). This is B29, by design.
- An insteadOf base of `.` gets its W from the explicit line at `:417`, not from `_snap_remote`.

Precise version: "…whenever they resolve a relative path against a working tree, except a remote of `.` (B29)."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-360`, `devcontainer-config/cc-exit-scan.sh:386-419`

---

## Claim 27b: "`scan_diff` ignores record types other than F and C, and a `W` record only changes when a C or F record does, so the report output is unchanged."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `scan_diff`'s awk and the W invariant (Claim 5). It does not establish the note path, which replaces the report when accepted.
**Legibility-target:** for-orchestrator-synthesis

```awk
# devcontainer-config/cc-exit-scan.sh:756-757
    FNR == NR { if ($1 == "F") b[$2 FS $3] = $4; else if ($1 == "C") bc[$0] = 1; next }
    { if ($1 == "F") a[$2 FS $3] = $4; else if ($1 == "C") ac[$0] = 1 }
```

(excerpt ends :757; enclosing `scan_diff()` continues to :769 — read). The END block iterates only `a`, `b`, `ac` and `bc`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:752-769`

---

## Claim 28: B14 "When the worktree's `.git` resolves on the host, `_snap_host_config` already walks it … When it does not resolve (container form, host not at `/workspace`), host git in it stops (E10)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global relative hooksPath in both forms. It does not re-run the `includeIf gitdir:` variant.
**Legibility-target:** for-orchestrator-synthesis

Host form: rc=1 with `+ hooksdir …/w/x/.husky`. Container form: note, rc=0; host git there is refused (E10). This is the accurate version of the header parenthetical that Claim 4b flags.

**Evidence:** `$D/logs/hostcfg.txt`, `$D/logs/experiments.txt`

---

## Claim 29: B21 "Removal hiding a plant … | covered | Rule 6 requires `P` gone on disk. E10: …"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:93`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the B21 row's stated mechanism for unit A. The "covered" status itself holds.
**Legibility-target:** for-author

This row is unchanged since 6abe247 (`git diff 6abe247 9075003` does not touch it). Rule 6 moved to the stacked unit in c32a734. In unit A the operative mechanism is that any removed record declines: the `*) return 1 ;;` in the diff loop (`cc-exit-scan.sh:833`) catches every `-` line. B23 and B27 were updated to say "Here, any removal warns"; B21 was not. (B22's "Its other records are residue" still holds.) Update it to match B23 and B27.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:828-835`, `docs/working/plan-q094-exit-scan-worktree-layout.md:59`

---

## Claim 30: B25 "Newer git writing relative paths (`worktree.useRelativePaths`, git ≥ 2.48)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:97`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The "not accepted (warns)" consequence follows from byte-exact matching (Claim 12). The version and config name are not verified.
**Legibility-target:** for-orchestrator-synthesis

Only git 2.39.5 is available and there is no network to check git's release notes. The code's byte-exact hash comparison (`:848-849`, `:878-881`) would decline any relative form, as test 6's relative `.git` case shows. The claim is consistent with my recollection of the 2.48 release, but I could not check it here.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:848-849`, `devcontainer-config/cc-exit-scan.sh:874-883`

---

## Claim 31: B28 "… For the W refusal that means it fails open on a large snapshot … The test (40k padding records) covers the two checks in `scan_std_worktrees`; the `invalid` check has no test of its own"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both `[[ ]]` checks in `scan_std_worktrees` and the `invalid` check.
**Legibility-target:** for-orchestrator-synthesis

- `mut-W-grep`: test 4 fails at `bats:2285`, the W-refusal assertion, so the check failed open.
- `mut-cd-grep` (commondir-line check → `printf | grep -qxF`): test 4 fails at `bats:2283` (`[ "$status" -eq 0 ]`), so that check failed closed.
- `mut-inv-grep`: all tests still pass, which confirms "no test of its own".

The loop `for i in $(seq 40000)` is at `bats:2279`.

**Evidence:** `test/cc-isolated-functions.bats:2273-2286`, `$D/logs/mut-W-grep.txt`, `$D/logs/mut-cd-grep.txt`, `$D/logs/mut-inv-grep.txt`

---

## Claim 32: B29 "`.` is the repository git runs in … (verified: a push to `.` from the worktree ran the common `pre-receive`, not the private one). No W record"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 8.
**Legibility-target:** for-orchestrator-synthesis

See Claim 8: "ran-common-pre-receive", and "no W for remote url .".

**Evidence:** `$D/logs/experiments2.txt`, `$D/logs/hostcfg.txt`

---

## Claim 33: B30 "An insteadOf base of `.` or of `""` … always makes a W record … Test cases for both, and for pushInsteadOf, were added; a mutation that drops `""` fails them."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three test entries and the drop-`""` and drop-`.` mutations.
**Legibility-target:** for-orchestrator-synthesis

Test 8's list includes `"url...insteadOf …" "url..insteadOf …" "url..pushInsteadOf …"` (`bats:2371`).

- `mut-empty-base` (`case "$t" in .)`) fails test 8.
- The same mutation with the list reduced to only `url..pushInsteadOf` also fails. So each `""` case fails independently: "fails them" holds.
- `mut-dot-base` fails test 8.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:417`, `test/cc-isolated-functions.bats:2367-2384`, `$D/logs/mut-empty-base.txt`, `$D/logs/mut-empty-base-pushonly.txt`, `$D/logs/mut-dot-base.txt` (all exit=1)

---

## Claim 34: Steps 2–3: "the new known route list items (B12 cost, B25–B27 still warn)"; tests including "private dir left behind after removal → 1"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:109-110`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what landed in the guide's Known routes and the Q-094 tests in unit A.
**Legibility-target:** for-author

The Known routes list gained only the "tracked file in a linked worktree" sentence and the insteadOf item (`guide:365-366,385-387`). The B12 cost is in the Q-094 paragraph (`:348-351`), not in Known routes. B25 (git ≥ 2.48 relative paths) appears nowhere in the guide (`grep useRelativePaths` finds nothing).

No unit-A test covers "private dir left behind after removal". Test 3 is the only removal test, and it does a full `git worktree remove` (`bats:2263-2271`). That item is a removal case that moved to unit B. Step 3 was edited in c32a734 but kept the item.

**Evidence:** `guides/cc-isolated-usage.md:334-387`, `test/cc-isolated-functions.bats:2263-2271`

---

## Claim 35: Test names vs assertions (9 tests) and the comment "git keeps '+' in a worktree name (a space it turns into '-')"

**Location:** `test/cc-isolated-functions.bats:2227-2394`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test's name against its assertions, plus the `+` and space naming. It does not establish coverage beyond each test's own cases.
**Legibility-target:** for-orchestrator-synthesis

Each name matches what its assertions check:

- Test 2 exercises the container form through a variable set to `$TEST_TMPDIR/cws`, standing in for `/workspace`.
- Test 5's "git would also accept": git accepted absolute, `../../` and CRLF commondir (E11 and `$D/logs/experiments3.txt`).
- Test 8 also asserts the two accepted cases (absolute hooksPath, `branch.main.remote .`). The name does not mention them, but it does not contradict them.

`git worktree add ".../agent+x"` and `".../agent y"` gave names `agent+x` and `agent-y` (`$D/logs/experiments3.txt`). All 9 pass.

**Evidence:** `test/cc-isolated-functions.bats:2227-2394`, `$D/logs/q094-tests.txt`, `$D/logs/experiments3.txt`

---

## Claim 36: "The container path the scan accepts is where devcontainer.json mounts the checkout." (`grep -q "target=$GIT_EXIT_SCAN_CONTAINER_WS," "$CONFIG_SRC/devcontainer.json"`)

**Location:** `test/cc-isolated-functions.bats:2383-2384`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current file. The grep is not anchored to `workspaceMount` and would pass on any `target=/workspace,` substring, but `devcontainer.json:134` is the only one.
**Legibility-target:** for-orchestrator-synthesis

`GIT_EXIT_SCAN_CONTAINER_WS` is `/workspace` in that test: bats re-sources the script per test, and test 2's override does not leak. The grep matches `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,…"`. The test passes.

**Evidence:** `devcontainer-config/devcontainer.json:134`, `$D/logs/q094-tests.txt`

---

## Claim 37: commit 5a6d689: "The rest of the scan checks -f before every read; this one now does too."

**Location:** commit `5a6d689` message
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim as of its own commit. At tip 9075003 the statement is true (Claim 7).
**Legibility-target:** for-author

At 5a6d689, `_snap_worktree_of` ran `git config --file "$1"` without a `-f` check. The guard `[ -f "$1" ] &&` arrived in c32a734, whose message says it "makes 5a6d689's '-f before every read' true". Executed: without that guard, a FIFO config reached via a legacy remotes file hangs the snapshot (exit 124 under `timeout 15`). The claim was false when committed and was made true in the same range, so no code action is needed. It matters only for readers of `git log` at 5a6d689, and the message cannot be changed without a history rewrite.

**Evidence:** `git show 5a6d689`, `git diff dfe4c0d 9075003 -- devcontainer-config/cc-exit-scan.sh` (hunk at `:325-328`), `$D/logs/worktree-of-fifo.txt`

---

## Claim 38: commit 5a6d689: "A FIFO planted at .git/worktrees/<n>/gitdir blocked the exit scan's read in scan_std_worktrees … Test: a FIFO there warns within a timeout."

**Location:** commit `5a6d689` message; `test/cc-isolated-functions.bats:2333-2335`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regular-file guard and its test. It does not establish the "Ctrl-C and exit 4" path, which was not run.
**Legibility-target:** for-orchestrator-synthesis

Mutation `mut-fifo` replaces `[ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1` with `:`. Test 6 then fails at `bats:2335`, the `run timeout 20 bash -c …` line followed by `warns_listing_wt`, because the read blocks until the timeout.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:858-862`, `test/cc-isolated-functions.bats:2333-2335`, `$D/logs/mut-fifo.txt` (exit=1)

---

## Claim 39: commit c32a734: "All three checks, including the older `invalid` check in git_exit_scan, are now bash pattern matches. Test: 40k padding records, both directions, under pipefail." Also: the 4097-byte cap, the "." remote, and the bats devcontainer.json check

**Location:** commit `c32a734` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed Must Fix and Must Address items that are in unit A. The removal split (R2) is verified only as absence: unit A has no removal acceptance.
**Legibility-target:** for-orchestrator-synthesis

- Three `[[ ]]` checks: `:813`, `:819`, `:928`.
- Test 4 checks both directions (Claim 31).
- `[ "$(stat -c %s -- "$p/gitdir" …)" -le 4097 ]` is at `:861`.
- The `.` exemption is at `:357` (Claim 8).
- The bats check is at `:2384` (Claim 36).
- The `-f` guard is at `:328` (Claim 7).
- The indexed lookup is `dot["${line%$'\t'*}"]="$line"` (`:831`), then `dk="${dot[…]}"` (`:874`).
- Any `-` line declines (`:833`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `devcontainer-config/cc-exit-scan.sh:926-927`, `$D/logs/mut-W-grep.txt`, `$D/logs/mut-cd-grep.txt`

---

## Claim 40: commit 037621f: "An insteadOf base of "." now always makes a W record. Test case added; a mutation that drops the line fails it. … The guide's per-worktree ms clause makes room for it (size cap)." / "Notes: unit at 399 changed code lines outside docs/ against dfe4c0d."

**Location:** commit `037621f` message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutation, the removal of the guide clause, and the line count at 037621f.
**Legibility-target:** for-orchestrator-synthesis

`mut-dot-base` fails test 8. `git show 037621f -- guides/cc-isolated-usage.md` removes "Each new worktree adds tens of milliseconds more to the check that allows the note." and adds the insteadOf route. `git diff --numstat dfe4c0d 037621f -- . ':!docs'` gives 171+4, 2+1, 29+3 and 189+0, which sums to 399. The net slow-scan clause (`guide:379-384`) is identical to dfe4c0d's.

**Evidence:** `$D/logs/mut-dot-base.txt`, `guides/cc-isolated-usage.md:379-387`

---

## Claim 41: commit 9075003: "git accepts `[url ""] insteadOf = https://x.invalid/` … _snap_remote returns early on "", so a planted bare repo in a new worktree passed … A base of "" or "." now always makes a W record. Test cases for url..insteadOf and url..pushInsteadOf; a mutation that drops "" fails them."

**Location:** commit `9075003` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 9 and 33.
**Legibility-target:** for-orchestrator-synthesis

`_snap_remote` has `"") return 0 ;;` (`:349`). git stores and uses `[url ""]` (`$D/logs/experiments2.txt`: `url..insteadof=a`; hook "ran-evil-baseEMPTY"). The mutation fails each `""` case independently (Claim 33).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-352`, `devcontainer-config/cc-exit-scan.sh:417`, `$D/logs/mut-empty-base.txt`, `$D/logs/mut-empty-base-pushonly.txt`

---

## Claim 42: commit b4de821: "when every record-level difference is a worktree … added or removed in the exact layout git writes … Removed worktrees need P gone on disk. … scan_diff ignores W records, so warning output is unchanged."

**Location:** commit `b4de821` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim against b4de821's own tree. The removal half is superseded within the range by c32a734, which says so explicitly.
**Legibility-target:** for-orchestrator-synthesis

`git show b4de821:devcontainer-config/cc-exit-scan.sh` has `local -a added=() removed=()` (`:805`) and `removed+=("$n")` (`:848`). The tip has no removal branch. `scan_diff`'s F/C-only awk is unchanged (Claim 27b).

**Evidence:** `git show b4de821:devcontainer-config/cc-exit-scan.sh` lines 789-905, `devcontainer-config/cc-exit-scan.sh:752-769`

---

## Claim 43: commit 5fadfc2: "No code behaviour change; the only line in cc-exit-scan.sh that changes is comments."

**Location:** commit `5fadfc2` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the full `cc-exit-scan.sh` hunk of that commit.
**Legibility-target:** for-orchestrator-synthesis

Two lines change, both comments: `:81` (`local remote (not ".") in repo config`) and `:931` (`# Only linked worktrees added in git's standard layout (STANDARD`). The wording is singular, but both lines are comments.

**Evidence:** `git diff 5fadfc2^ 5fadfc2 -- devcontainer-config/cc-exit-scan.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`devcontainer-config/cc-exit-scan.sh:83-84`): "Your own config's relative hooksPath is walked in each new worktree, so its records refuse the note" is false for a container-form worktree on a host not at `/workspace`, which is the main Q-094 case. It is not walked (`_snap_dotgit_target` returns nothing) and the note prints (executed, rc=0). The outcome is safe only because host git refuses that worktree (E10). Reword to plan B14's two-case form.
- **Claim 37** (commit `5a6d689`): "The rest of the scan checks -f before every read" was false at that commit (`_snap_worktree_of` had no `-f`; a FIFO config hangs the snapshot, executed). c32a734 in the same range made it true. Historical only; no action at the tip.

### Stale
- **Claim 29** (`docs/working/plan-q094-exit-scan-worktree-layout.md:93`): B21 still cites "Rule 6 requires P gone on disk". Rule 6 is in unit B now; in unit A any removed record warns. Update it like B23 and B27.
- **Claim 34** (`docs/working/plan-q094-exit-scan-worktree-layout.md:109-110`): Step 2's "known route list items (B12 cost, B25–B27)" did not land as Known-routes items (B25 is not in the guide). Step 3 lists a "private dir left behind after removal" test that unit A does not have (removal moved to unit B).

### Mostly Accurate
- **Claim 3** (`devcontainer-config/cc-exit-scan.sh:80-83`): the "(not ".")" exemption does not cover insteadOf bases `.` and `""`, and W comes from any config the scan reads, including embedded repos, not only "repo config".
- **Claim 12** (`devcontainer-config/cc-exit-scan.sh:793-805`): every stated check is in the code, but the comment omits further declines: `.`/`..` names, the 4097-byte back-pointer cap, `<rel>` normalisation, working tree not in the common dir, container back-pointer needing common inside ws, and the snapshot commondir record matching.
- **Claim 19** (`guides/cc-isolated-usage.md:334-351`): "relative local remote other than `.`" omits that insteadOf bases `.` and `""` always refuse, and embedded repos' relative hooksPath also refuses.
- **Claim 20** (`guides/cc-isolated-usage.md:365-366`): "its tracked files are never read" is too strong. The tree is walked for `.git`, and hooks under your own relative hooksPath are hashed. Suggest "not scanned".
- **Claim 24** (`docs/working/plan-q094-exit-scan-worktree-layout.md:23`): "`cc-isolated.sh` does not change": its behaviour does not, but its help text did.
- **Claim 26** (`docs/working/plan-q094-exit-scan-worktree-layout.md:47-61`): rule 5 omits the same extra declines as Claim 12.
- **Claim 27a** (`docs/working/plan-q094-exit-scan-worktree-layout.md:65`): "whenever they resolve a path against a working tree" has the `.` remote exception (B29).

### Unverifiable
- **Claim 23** (`docs/working/plan-q094-exit-scan-worktree-layout.md:21`): "git 2.39 (the image's git)" needs a built image or registry access, because `FROM node:22` is unpinned.
- **Claim 30** (`docs/working/plan-q094-exit-scan-worktree-layout.md:97`): the `worktree.useRelativePaths` / git ≥ 2.48 reference needs a git ≥ 2.48 binary or the release notes. There is no network.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown code-fact-check report saved at the output path below, structured per the code-fact-check skill, with the header fields `**Commit:** 9075003` and per-claim sections.
- Answered: yes. 45 claims covering all 10 focus areas, 29 of them executed (full suite 169/169, 9 mutations, 4 git experiment scripts).
- Out of scope: `docs/reviews/*` prior artifacts; stacked unit B; pre-existing unchanged guide text (the slow-scan clause is byte-identical to dfe4c0d); a live host cc-isolated session.
- Escalate: Claim 4b (header comment wrong for the container-form case, safe only via E10) and Claim 29 (B21's stale mechanism) are small doc fixes before merge. Claims 3, 19 and 12 are tightening edits.
- Decisions I made: I verdicted commit messages against their own commit's tree (Claim 37 Incorrect at 5a6d689 though true at the tip; Claim 42 Verified though later superseded). I split the header's own-config parenthetical by worktree form (4a/4b) rather than giving one most-severe verdict.
