# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094-exit-scan-worktree-layout`, read via `git show` / `git archive`; working tree not touched)
**Scope:** `git diff dfe4c0d..9075003 -- . ':!docs/reviews'`: `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-isolated.sh`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, plus the commit messages in dfe4c0d..9075003 (b4de821, 5a6d689, c32a734, 5fadfc2, 037621f, 9075003). Merged from three replicate reports (`A-code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`).
**Checked:** 2026-09-28 (replicate executions 2026-09-29T03:10Z–03:25Z UTC; merge 2026-09-28)
**Total claims checked:** 57
**Summary:** 36 verified, 12 mostly accurate, 4 stale, 2 incorrect, 3 unverifiable
**Commit:** 9075003
**Replication:** k=3

Merge procedure: code-review skill, "Merging replicate verdicts (most-severe-wins)". Claims were clustered by (file, ±5 lines, substance) and emitted at the finest granularity any replicate used; a replicate that verdicted only a compound claim carries that verdict on each sub-claim row, marked `(compound)`. Each claim's verdict is the most severe any replicate gave it; its body, Scope, Confidence, Verification mode and Evidence come from the winning replicate (named in the line under the fields); every other replicate's scope caveats and notes are in `**Replicate annotations:**`. No claim, verdict or evidence was added in merging.

Replicate environments and log paths. All log paths below are relative to the session scratchpad `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/`:
- r1: `git archive` tree at `fcA-k7q2/src`, logs `fcA-k7q2/logs/` (Q-094 bats 9/9 ok; full `test/cc-isolated-functions.bats` 169/169 ok; mutations m1–m6).
- r2: tree at `fcA-r2x7/src`, logs `fcA-r2x7/logs/` (X1 Q-094 bats 9/9; X2 full suite 169/169; X3–X7 experiments; mutants M1–M7).
- r3: tree at `fcA-r3x7`, logs `fcA-r3x7/logs/` (Q-094 bats 9/9; full suite 169/169; mutation runs via `mut.sh`).
All three read git 2.39.5 with `LC_ALL=C`. Mutation numbering is per replicate (r1 m1–m6, r2 M1–M7, r3 named mutants); a mutation name in a claim body refers to the winning replicate's set.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): all three replicates read it; none found a claim matching a logged pattern. r2 and r3 recomputed the unit's count claims (037621f's 399 lines, the 40k padding) and found them correct.

---

## Claim 1: "When every difference is a linked worktree added in git's own layout (agent worktrees outlive sessions), the scan prints one `note:` and returns 0 (scan_std_worktrees has the rule)."

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` returning 0 with exactly one `note:` line for a single standard `git worktree add` (host form and container form) and the launcher passing claude's status; does not establish acceptance of multiple simultaneous worktrees beyond the code reading (the loop at :839-890 handles N, not separately executed).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "says nothing about removals (unit B)" · r2: "does not establish behaviour against git versions other than 2.39.5" · r3: "does not establish behaviour … for layouts written by git ≥ 2.48 with relative paths"

Headline evidence from r1. `git_exit_scan` calls the acceptance before rendering and returns 0:

```bash
# devcontainer-config/cc-exit-scan.sh:934-938
  local note
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```

Test "a new worktree in git's standard layout is one note and status 0" asserts `status 0` and `wc -l == 1` and passed (`fcA-k7q2/logs/bats-q094.txt`, ok 1).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-970`, `test/cc-isolated-functions.bats:2227-2240`, `fcA-k7q2/logs/bats-q094.txt`

---

## Claim 2: "In a linked worktree git takes config, hooks and info/attributes from the common dir, never the private one (tested on git 2.39.5; the one exception, config.worktree under extensions.worktreeConfig, refuses the note)."

**Location:** `devcontainer-config/cc-exit-scan.sh:77-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--git-path` resolution for hooks, info/attributes and config, and the non-execution of private-dir hooks (pre-commit, post-commit, post-checkout), attributes filters and config hooksPath/fsmonitor on git 2.39.5; does not establish pre-push or reference-transaction (not re-run here) or git versions other than 2.39.5.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish behaviour of other git versions" · r3: "does not re-run E4 (filter via private info/attributes) or E6"

Headline evidence from r2. X3 output: `E2 hooks -> …/r/.git/hooks`, `E2 info/attributes -> …/r/.git/info/attributes`, `E2 config -> …/r/.git/config`, `E2 config.worktree -> …/r/.git/worktrees/wt/config.worktree`; `E3 private hooks ran: 0` with the control `yes`; `E4 private attributes filter ran: no` with the control `yes`; `E5 … used: 0`; `E6 config.worktree w/o extension: 0`, `with extension: 1`. The note is refused when `config.worktree` exists: `for k in hooks config config.worktree; do [ ! -e "$p/$k" ] && [ ! -L "$p/$k" ] || return 1; done` (`cc-exit-scan.sh:856`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:856`, `fcA-r2x7/logs/exp.txt`

---

## Claim 3: "A relative core.hooksPath, core.attributesFile or local remote (not ".") in repo config would resolve in the new worktree's own tree, unscanned: those leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:80-83`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers W emission for relative hooksPath, attributesFile and remote values, and the refusal on any W. It does not establish that the refusal set is limited to what the sentence names, and in fact it is wider: see the two qualifiers below.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish that W is limited to configs whose paths resolve in the *new* worktree — any config the scan reads (e.g. an embedded repo with `remote.o.url ../up`) also produces W and refuses the note (a conservative false positive, executed: `rc=1`)" · r2: "does not establish that these three are the only working-tree-relative exec inputs. For example, a relative `core.fsmonitor` or filter command also runs in the worktree's tree; the guide's 'Anything present at launch' route covers those" · r2: "The '(not \".\")' exception is scoped to remote URLs/names: an `insteadOf` base of `.` or `\"\"` does make a W record (:417)"

Headline evidence from r3. The mechanism is right. `_snap_wrel "$key" "$f" "$val"` runs for `core.hookspath` and `core.attributesfile` (`cc-exit-scan.sh:393,401`), `_snap_remote` calls `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`:357`), and the refusal is `[[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1` (`:813`). The sentence has two imprecisions:

- The "(not ".")" exemption covers only a remote value of `.`. An insteadOf base of `.` or `""` always makes a W record: `case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac` (`:417`). A reader could take "." to be exempt everywhere.
- "in repo config" undercounts. `_snap_config` emits W for every config the scan reads, including embedded repos' configs, which git never resolves in the new worktree. Executed: an embedded repo `emb` with `core.hooksPath .h` produced `W	core.hookspath	…/emb/.git/config`, and a standard worktree then warned (rc=1). This errs on the fail-closed side.

Suggested wording (r3): "a relative core.hooksPath or core.attributesFile, a relative local remote other than a remote of ".", or an insteadOf base of "." or "", in any config the scan reads".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:355-357`, `devcontainer-config/cc-exit-scan.sh:386-419`, `devcontainer-config/cc-exit-scan.sh:813`, `fcA-r3x7/logs/hostcfg.txt`

---

## Claim 4a: "(Your own config's relative hooksPath is walked in each new worktree, so its records refuse the note as well.)" (host-form worktree)

**Location:** `devcontainer-config/cc-exit-scan.sh:83-84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the host-form worktree, which is walked and refused, and the container-form worktree whose `/workspace/…` path does not exist on the host, which is not walked and is accepted; does not establish behaviour for a host checkout that really lives at `/workspace` beyond the static reading.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Verified
**Replicate annotations:** r1: "Covers the host-form worktree (its `.git` resolves on the host), where the walk happens and the note is refused; does not hold for a container-form worktree whose `/workspace/…` path does not exist on the host" (r1's executed host form: `rc=1`, with `+ hooksdir <ws>/.claude/worktrees/a/.githooks missing`) · r3: "Covers a worktree whose `.git` names the host path of P. It does not establish the container-form case (Claim 4b)" (r3's executed host form: rc=1) · merge note: r1 and r2 verdicted the sentence as one compound claim; the defect both describe is the container-form case, split out as Claim 4b

Headline evidence from r2 (compound). The walk happens only when the worktree's `.git` resolves on the host: `g="$(_snap_dotgit_target "$f")" …; [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}"` (`cc-exit-scan.sh:700-701`). X4 results:
- Host form: new records included `F hooksdir WS/.claude/worktrees/a/.husky/_`, and `scan_std_worktrees rc=1` (refused).
- Container form (not present on the host): `scan_std_worktrees rc=0`, so the note is given, and `host git in that worktree: fatal: not a git repository`.

The outcome is safe: host git cannot run there, as plan B14 says. The header should still qualify the claim: "walked in each new worktree whose `.git` resolves on the host; one that does not resolve is not a repository to host git."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:496-532`, `:534-549`, `:697-702`, `fcA-r2x7/logs/exp2.txt`

---

## Claim 4b: same sentence, for a container-form worktree (`.git` = `gitdir: /workspace/.git/worktrees/<n>`) on a host not at `/workspace`

**Location:** `devcontainer-config/cc-exit-scan.sh:83-84`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the container-form worktree on a host whose checkout is not at the container path. It does not establish any exposure: host git cannot use such a worktree (E10).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Incorrect
**Replicate annotations:** r1: "a container-form one that does not resolve is not walked (host git stops there, E10)"; "benign per E10; B14 says this, the header does not" · r2: "The outcome is safe: host git cannot run there, as plan B14 says"; escalation note: "Claim 4's safety rests on a container-form `.git` not resolving on the host; that is covered by :885-887, E10 and X4"

Headline evidence from r3. "Walked in each new worktree" is false here. `_snap_dotgit_target` returns nothing when the named git dir does not exist (`[ -d "$g" ] || return 0`, `cc-exit-scan.sh:547`). So `_snap_host_config` is skipped for that worktree (`[ -z "$g" ] || _snap_host_config …`, `:701`). No record is made, and the note is printed. Executed with the same global `hooksPath = .husky`, a container-form worktree gave `note: exit scan: only linked worktrees in git's standard layout changed (added: x). …` and rc=0.

This is the main case Q-094 targets (plan line 21: "A rule that accepted only the host path would never fire for the case Q-094 is about"). The safety conclusion still holds for a different reason than the comment gives: host git stops in a worktree whose `.git` names a missing path (plan B14 / E10; re-run for the missing-HEAD variant in `fcA-r3x7/logs/experiments.txt`, "fatal: not a git repository"). Fix the comment to match plan B14: walked only when the worktree's `.git` resolves on the host; otherwise host git refuses that worktree.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:536-551`, `devcontainer-config/cc-exit-scan.sh:694-701`, `docs/working/plan-q094-exit-scan-worktree-layout.md:86`, `fcA-r3x7/logs/hostcfg.txt` (section "same, container form")

---

## Claim 5: "W <kind> <config or path %q> a path git resolves in the working tree it runs in (read by scan_std_worktrees; never reported, and it changes only with a C or F record)"

**Location:** `devcontainer-config/cc-exit-scan.sh:151-153`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every W producer (`_snap_wrel` call sites in `_snap_config` and `_snap_remote`) and the fact that `scan_diff` ignores W. It does not establish that W is emitted only for paths git resolves in the new worktree: embedded-repo configs also emit it (Claim 3).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the invariant under concurrent mutation between reads (the existing 'file changed while the scan read it' exit-2 path)" · r2: "does not establish the invariant when a remote-name decision (:707-712) flips because a `remote.<name>.*` entry appears. That flip is itself a C change, so it still holds"

Headline evidence from r3. `_snap_wrel` is called only from `_snap_config` (`:393,401,417`) and `_snap_remote` (`:357`). Every value it sees comes from a config entry recorded as a C record (`_snap+="C"…`, `:390`) or from a legacy remotes or branches file recorded as `F legacy-remote` with its hash (`:599`). Whether a config is reached at all shows in its `F config` record (`:578`). The remote-name decision (`_snap_rnames`) depends only on C and F records (paraphrased — no quote available because the invariant is inferred from the four call sites and the `_snap_names` loop at `:707-713`). Never reported: `scan_diff` keys only on `$1 == "F"` and `$1 == "C"` (`:756-757`). `_snap_host_config` makes no W records (`:496-533`, no `_snap_wrel`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:290-294`, `devcontainer-config/cc-exit-scan.sh:346-419`, `devcontainer-config/cc-exit-scan.sh:596-613`, `devcontainer-config/cc-exit-scan.sh:707-713`, `devcontainer-config/cc-exit-scan.sh:752-769`

---

## Claim 6: "_snap_wrel <kind> <where> <value>: a W record when <value> is a relative path, which git resolves in the working tree it runs in"

**Location:** `devcontainer-config/cc-exit-scan.sh:287-294`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the relative/absolute split: empty, `/…` and `~/…` make no record. It does not establish that git itself treats `~user/…` or a bare `~` as relative. The function emits W for those too, which errs on the fail-closed side.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish which callers pass which values (Claim 3)"; executed via `fcA-k7q2/logs/exp-s.txt` (`~/h`, `/abs` → no W; `.h` → W) · r2: "`~user/…`, which counts as relative here (a conservative decline)" (same substance as the winning scope)

Headline evidence from r3.

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

## Claim 7: `_snap_worktree_of` guards the core.worktree read with `[ -f "$1" ]`, so a FIFO config no longer hangs the snapshot

**Location:** `devcontainer-config/cc-exit-scan.sh:321-335`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the legacy-remotes call path (`:608`, `:611`) with a FIFO at `<private dir>/config`; does not establish a guard against a file swapped to a FIFO between the `-f` test and the read (TOCTOU).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Covers the tip state: every content read of a container-writable file is preceded by `-f` (`scan_git_dirs` :123/:134, `_snap_file` :230/:243, `_snap_config` callers :399/:527/:529/:580, legacy remotes :602, `_snap_dotgit_target` :540, `_snap_gitdir` :585, `_snap_worktree_of` :328, `scan_std_worktrees` :855/:860/:881, `cc-gitdir.sh` :33/:57); does not make 5a6d689's sentence true *at 5a6d689*" (see Claim 44) · r3: "does not establish reads in `cc-gitdir.sh` beyond HEAD and commondir"; r3 surveyed the other tip reads and found each preceded by `-f`

Headline evidence from r2. `elif [ -f "$1" ] && v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then` (`cc-exit-scan.sh:328`). X6: the tip returns `snapshot rc=0`. Mutant M7, without `[ -f "$1" ] &&`, hits `timeout-wrapped rc=124`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:323-335`, `:594-614`, `fcA-r2x7/logs/exp3-tip.txt`, `fcA-r2x7/logs/exp3-mut.txt`

---

## Claim 8: "\".\" is the repository git runs in (a local-tracking branch's remote): in a linked worktree, the same common dir and hooks. Not a W record."

**Location:** `devcontainer-config/cc-exit-scan.sh:355-357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact string `.`; does not establish anything about `./`, `./.` and similar, which do make W records (conservative).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover insteadOf bases (handled separately at :417, Claim 9)" · r3: "does not establish fetch or other transports to `.`"

Headline evidence from r2. X3: `B29 push to . : common=yes private=no`. Code: `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`:357`). X1 test 8 asserts `branch.main.remote .` gives status 0, and M6 fails it.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-369`, `test/cc-isolated-functions.bats:2367-2384`, `fcA-r2x7/logs/exp.txt`, `fcA-r2x7/logs/mut-M6-no-dot-exempt.txt`

---

## Claim 9: "url.<base>.insteadOf rewrites matching URLs to <base>" / "a base \"\" or \".\" starts a relative path"

**Location:** `devcontainer-config/cc-exit-scan.sh:414-418`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `url.<base>.insteadOf` rewrites of a push URL for bases `""` and `.` on git 2.39.5. It does not establish other bases that yield relative paths (e.g. `sub`); those go through `_snap_remote` and get W anyway (`W	remote	sub` in `fcA-r3x7/logs/hostcfg.txt`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "does not establish that the rewritten URL itself is walked (it is not)" — a documented known route (Claim 40)

Headline evidence from r3. From the worktree, `git -c url..insteadOf=https://x.invalid/ push https://x.invalid/evil` ran the hook of the planted bare repo at `<wt>/evil` ("ran-evil-baseEMPTY"). With base `.`, the hook of `<wt>/.evil` ran ("ran-.evil-base."). `git config -f` stores these as `[url ""]` and `[url "."]` and lists them as `url..insteadof` and `url...insteadof`. The code line: `case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac   # a base "" or "." starts a relative path` (`:417`, quoted by r1 and r2). r1 (m3, m5) and r2 (M4, M5) each report that dropping `""` or dropping the line fails the bats test.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:414-418`, `fcA-r3x7/logs/experiments2.txt`

---

## Claim 10: "Where the container sees the checkout (devcontainer.json's workspaceMount target). Git in the container writes absolute paths under it into a new worktree's `.git` file and back-pointer."

**Location:** `devcontainer-config/cc-exit-scan.sh:771-774`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constant matching `devcontainer.json`'s workspaceMount and git 2.39.5 writing absolute paths into both files; does not establish the git version inside the built image (Dockerfile `FROM node:22` + apt `git`, not built here).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish an observation inside a live container (no Docker here)" · r3: "the Dockerfile's `FROM node:22` is unpinned (see Claim 20)" · r2 and r3 gave Confidence Medium

Headline evidence from r1. `GIT_EXIT_SCAN_CONTAINER_WS=/workspace` (:774); `devcontainer-config/devcontainer.json:134`: `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"`. E1 in `fcA-k7q2/logs/exp-e.txt`: `.git` = `gitdir: /tmp/…/r/.git/worktrees/wt\n`-shaped absolute path, back-pointer `/tmp/…/r/wt/.git\n`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:771-774`, `devcontainer-config/devcontainer.json:134`, `fcA-k7q2/logs/exp-e.txt`

---

## Claim 11a: "_snap_hash_str <string>: _snap_hash of exactly those bytes."

**Location:** `devcontainer-config/cc-exit-scan.sh:776-781`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers byte equality with `_snap_hash` (both take the first 16 hex of the sha256 of the bytes); does not establish handling of NUL bytes, which bash strings cannot hold.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "does not establish NUL-containing strings, which bash cannot hold" (same as winning scope)

Headline evidence from r2. `h="$(printf '%s' "$1" | sha256sum)"; printf '%s' "${h:0:16}"` (`:779-780`) matches `_snap_hash`'s `sha256sum < "$1"` … `${h:0:16}` (`:169-173`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:167-174`, `:777-781`

---

## Claim 11b: "_snap_file_is <path> <hash>: <path> is a regular file, not a link, within the size cap, whose bytes hash to <hash>."

**Location:** `devcontainer-config/cc-exit-scan.sh:783-791`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all four conditions; does not establish atomicity between the checks.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish TOCTOU safety between the checks" (same as winning scope)

Headline evidence from r2. `[ -f "$1" ] && [ ! -L "$1" ] || return 1; _snap_size_ok "$1" 2>/dev/null || return 1; h="$(_snap_hash "$1" 2>/dev/null)" || return 1; [ "$h" = "$2" ]` (`:787-790`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:785-791`

---

## Claim 12a: scan_std_worktrees doc comment — the list of checks ("P = <common>/worktrees/<n>, <n> of [A-Za-z0-9._-]. Only dotgit, commondir-file and hooksdir records are added (a removal warns), and the exit snapshot has no W record: … at snapshot time and now.")

**Location:** `devcontainer-config/cc-exit-scan.sh:793-805`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every stated check being implemented (each quoted below); does not claim the list is complete — the code also enforces checks the comment does not name (listed below), all of which only decline more, so no accepting path is undocumented.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r2: "Every stated check is implemented; does not establish that the list is exhaustive … Each of these only narrows acceptance, which the comment's 'Anything it cannot read or match declines' covers. The back-pointer is checked on disk only, not at snapshot time, since it is not a record." · r3: "The verdict concerns the checks the code makes that the comment does not state, which make '0 … when every difference is … git's standard layout' narrower in practice than written"; "All are fail-closed. Suggest adding 'not . or ..' after the charset, and one clause for the `<rel>` normalisation."

Headline evidence from r1. Every stated check is present (quoted from `scan_std_worktrees()` :806-896, read in full):
- no W: `:813`; P naming and charset: `case "$q" in "$pre"*/commondir)` (:843), `[[ "$n" =~ ^[A-Za-z0-9._-]+$ ]]` (:845); only +dotgit/+commondir-file/+hooksdir, anything else incl. `-` lines returns 1 (:830-834); `hooksdir P/hooks missing` (:850-851); commondir hash `re="^file [0-7]+ $std\$"` (:848-849); `[ -d "$common/worktrees" ] && [ ! -L "$common/worktrees" ] && [ -d "$p" ] && [ ! -L "$p" ]` (:854); no hooks/config/config.worktree (:856); no symlink `find -P "$p" -type l -print -quit` (:857); gitdir exact (:862-868); dotgit hash at snapshot (`[[ "$attrs" =~ $re ]]`) and now (`_snap_file_is "$wt/.git" "$h"`) (:878-882); container form resolving to P (:885-887).

Checks the code does that the comment does not state:
- `<n>` must not be `.` or `..` (`[ "$n" != . ] && [ "$n" != .. ]`, :845);
- the exit snapshot's `commondir` record must equal the recomputed common dir (:818-819);
- the back-pointer must be ≤ 4097 bytes (:861);
- `<rel>` must have no `.`, `..` or empty components (`case "/$wtrel/" in */../*|*/./*|*//*) return 1`, :870) and the working tree must not be inside the common dir (:872);
- the container-form back-pointer (and container-form `.git`) is accepted only when the common dir lies inside the checkout (`[ -n "$ccommon" ] || return 1`, :866; `${ccommon:+…}`, :878);
- `P/commondir` is re-hashed on disk now (:855) — "at snapshot time and now" is attached in the sentence to the dotgit only.

Precise version (r1): append these to the rule, or say "at least these checks". All 9 Q-094 tests pass (`fcA-k7q2/logs/bats-q094.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:793-896`, `fcA-k7q2/logs/bats-q094.txt`

---

## Claim 12b: scan_std_worktrees doc comment — "Anything it cannot read or match declines; nothing passes on error." / "Paths are compared as the %q strings the records hold, recomputed from <n>; nothing is unquoted."

**Location:** `devcontainer-config/cc-exit-scan.sh:795-805`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole function (`:806-896`), read end to end. Every stated check is present in the code. The verdict concerns the checks the code makes that the comment does not state, which make "0 … when every difference is … git's standard layout" narrower in practice than written.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1: "Covers every command in the function ending in `|| return 1` or feeding a guarded test, `git_exit_scan` discarding stderr and falling through to the warning on any non-zero, and all record comparisons using `printf '%q'` recomputation; does not establish behaviour if bash itself is killed (handled by the launcher's INT trap)"; "The only extraction from a quoted string (`n=\"${q#\"$pre\"}\"`, :844) is re-verified by recomputation at :847" · r2: lists "%q comparison" among the stated checks it verified; the unstated declines "only narrow acceptance, which the comment's 'Anything it cannot read or match declines' covers" · merge note: r3's Mostly-accurate verdict is on the doc comment as a whole (Claim 12a's omitted declines); r1 verdicted these two sentences separately as Verified

Headline evidence from r3 (compound). Every stated check is in the code: W refusal (`:813`), `pre`/`%q` recomputation (`:838-847`), `^file [0-7]+ $std$` (`:848-849`), `hooksdir … missing` pairing (`:850-851`), real dirs (`:854`), no hooks/config/config.worktree (`:856`), `find -P "$p" -type l` (`:857`), back-pointer forms (`:860-868`), dotgit at snapshot time and now (`:874-883`), container form resolving to P (`:885-887`), all records used (`:892`). The comment does not list these additional declines: `[ "$n" != . ] && [ "$n" != .. ]` (`:845`); the exit snapshot's `F commondir` record must equal the recomputed common dir (`:818-819`); a back-pointer over 4097 bytes (`:861`); `<rel>` containing `.`, `..` or `//` components (`:870`); a working tree inside the common dir (`:872`); a container-form back-pointer when the common dir is outside the checkout: `[ -n "$ccommon" ] || return 1` (`:866`). All are fail-closed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:793-896`, `fcA-r3x7/logs/q094-tests.txt`, `fcA-r3x7/logs/mut-fifo.txt`

---

## Claim 13: "Pattern matches, not `printf | grep -q`: under the launcher's pipefail an early match SIGPIPEs printf, and the pipeline reads as \"no match\"."

**Location:** `devcontainer-config/cc-exit-scan.sh:811-813`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the SIGPIPE mechanism under `set -o pipefail` for both checks in `scan_std_worktrees` (reverting either one makes the 40k-record test fail); does not establish the exact snapshot size at which SIGPIPE starts (pipe-buffer dependent).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Headline evidence from r1. The launcher sets `set -euo pipefail` (`devcontainer-config/cc-isolated.sh:66`). Mutation m2 (both checks back to `printf '%s\n' "$after" | LC_ALL=C grep -q…`) fails the test at `[ "$status" -eq 0 ]` (commondir check reads "no match", `fcA-k7q2/logs/mut-m2.txt`); m6 (only the W check reverted) fails at `[ "$status" -eq 1 ]` (W refusal fails open, `fcA-k7q2/logs/mut-m6.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:811-819`, `devcontainer-config/cc-isolated.sh:66`, `test/cc-isolated-functions.bats:2273-2286`, `fcA-k7q2/logs/mut-m2.txt`, `fcA-k7q2/logs/mut-m6.txt`

---

## Claim 14: "Regular file first: a FIFO there would block the read." / "# PATH_MAX + \n"

**Location:** `devcontainer-config/cc-exit-scan.sh:859-861`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a FIFO at `P/gitdir` declining within the test's 20 s timeout and the 4097 = Linux PATH_MAX (4096) + newline cap; does not establish behaviour for a FIFO swapped in after the `-f` test (race).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Headline evidence from r1.

```bash
# devcontainer-config/cc-exit-scan.sh:860-862
    [ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1
    [ "$(stat -c %s -- "$p/gitdir" 2>/dev/null || echo 99999)" -le 4097 ] || return 1   # PATH_MAX + \n
    line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1
```

Mutation m4 (line :860 → `true`) makes the FIFO step of test 6 fail `warns_listing_wt` (`fcA-k7q2/logs/mut-m4.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:860-862`, `test/cc-isolated-functions.bats:2336-2339`, `fcA-k7q2/logs/mut-m4.txt`

---

## Claim 15a: note text — "Names are [A-Za-z0-9._-] only (checked above); the caller still scan_vis-es."

**Location:** `devcontainer-config/cc-exit-scan.sh:893`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every value appended to `added` and the caller's pipe. It does not establish the other text in the note, which is a fixed literal.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: "does not extend to `config.worktree` (which declines the note before this line)"

Headline evidence from r3. `added+=("$n")` (`:889`) runs only after `[[ "$n" =~ ^[A-Za-z0-9._-]+$ ]]` (`:845`). The caller runs `printf '%s\n' "$note" | scan_vis >&2` (`:936`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:845`, `devcontainer-config/cc-exit-scan.sh:889-895`, `devcontainer-config/cc-exit-scan.sh:936`

---

## Claim 15b: note text — "They take config and hooks from the checkout's own .git, so this is not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:895`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the config and hooks resolution on git 2.39.5 (E2/E3), as in Claim 2; does not establish the "not a finding" safety beyond the scan's documented limits.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1: "does not extend to `config.worktree` (which declines the note before this line)"

Headline evidence from r2. The E2 and E3 results in `fcA-r2x7/logs/exp.txt` (quoted in Claim 2) back this.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:895`, `fcA-r2x7/logs/exp.txt`

---

## Claim 16: git_exit_scan doc — "0 when nothing the tripwire records changed, or only standard linked worktrees did (one `note:` line on stderr: scan_std_worktrees); 1 … when anything else did; 2 when the exit state could not be read, or the snapshots differ but nothing renders."

**Location:** `devcontainer-config/cc-exit-scan.sh:898-903`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return statement of `git_exit_scan` (`:904-968`). It does not establish `scan_interrupted`'s exit path.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish claude-side behaviour. (Residue: the plan's 'git 2.39 (the image's git)' is not checked — the image was not built.)" · r2: "does not establish that 0 is 'safe' (the comment disclaims that itself)"

Headline evidence from r3. The returns are: `return 2` after a failed snapshot (`:920`); `… || return 0` when the snapshots are equal and valid (`:931`); `return 0` after the note (`:937`); `return 2` when `changes` is empty (`:945`); `return 1` after the warning (`:969`). r1 and r2 ran the full `test/cc-isolated-functions.bats` (169/169 ok).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-968`

---

## Claim 17: "A pattern match, not `printf | grep -q` (pipefail: see scan_std_worktrees)." — replacement of the pre-existing `invalid` check

**Location:** `devcontainer-config/cc-exit-scan.sh:926-930`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new regex matching the same records as the old per-line grep (`^F\tgitdir-valid\t[^\t]*\tinvalid` per line ≡ `(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid` over the whole string) and the existing invalid-git-dir tests still passing; does not establish a pipefail/large-snapshot test for this check (none exists, as B28 says).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "With the old grep restored (`mut-inv-grep`), the three `exit scan gitdir:` tests still pass (exit=0). That is consistent with B28's 'no test of its own'" (bears on Claim 34)

Headline evidence from r1.

```bash
# devcontainer-config/cc-exit-scan.sh:927-930
  local re=$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'
  if [[ "$after" =~ $re ]]; then
    invalid="    ! $(printf '%q' "$ws/.git") is not a valid git directory now: host git would look for a repository elsewhere (the checkout root)"
  fi
```

Existing tests asserting `! $SCAN_WS/.git is not a valid git directory now` (`test/cc-isolated-functions.bats:1352`, `:1362`) — see `fcA-k7q2/logs/bats-full.txt`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:923-931`, `test/cc-isolated-functions.bats:1340-1365`, `fcA-k7q2/logs/bats-full.txt`

---

## Claim 18: "0 success; after a session: the exit scan found nothing (or only standard linked worktrees, with a note on stderr), and claude's own exit status is passed through"

**Location:** `devcontainer-config/cc-isolated.sh:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--help` text (printed from this header by `usage()`), the `0) exit "$rc"` mapping, and the launcher test; does not establish a live container run (the plan's `Live-verified: no`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Headline evidence from r1. `case "$scan" in 0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;; esac` (`devcontainer-config/cc-isolated.sh:747-751`). `bash devcontainer-config/cc-isolated.sh --help` printed the new lines (cwd `fcA-k7q2/src`, exit 0, 2026-09-29T03:22Z; captured in `fcA-k7q2/logs/help.txt`, lines 20-23). Bats "a session that leaves an agent worktree ends the launcher with claude's status and a note" passed (ok 9).

**Evidence:** `devcontainer-config/cc-isolated.sh:18-33`, `:566-568`, `:743-751`, `test/cc-isolated-functions.bats:2386-2394`, `fcA-k7q2/logs/bats-q094.txt`, `fcA-k7q2/logs/help.txt`

---

## Claim 19: Plan Problem — "`git worktree add <ws>/.claude/worktrees/agent-x -b wt-x` during a session adds exactly three records to the exit snapshot"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:9-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record diff with no global config; does not cover a host config with a relative hooksPath (adds a fourth, Claim 4a).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Headline evidence from r1. `fcA-k7q2/logs/exp-n.txt`: diff adds exactly `F commondir-file <ws>/.git/worktrees/agent-x/commondir file 644 …`, `F dotgit <ws>/.claude/worktrees/agent-x/.git file 644 …`, `F hooksdir <ws>/.git/worktrees/agent-x/hooks missing`.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:9-15`, `fcA-k7q2/logs/exp-n.txt`

---

## Claim 20: "`devcontainer.json` mounts the checkout at `/workspace`, and git 2.39 (the image's git) writes absolute paths."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:21`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The mount target is verified (Claim 10), and git 2.39.5 writing absolute paths is verified. The image's git version is not.
**Replicate verdicts:** r1=— · r2=Verified · r3=Unverifiable
**Replicate annotations:** r1 (not surfaced as a claim; residue in its git_exit_scan claim's scope): "the plan's 'git 2.39 (the image's git)' is not checked — the image was not built" · r2: "the image's git version is inferred from `FROM node:22` (Debian 12), matching this sandbox (Debian 12, git 2.39.5); does not establish the version in a freshly built image"

Headline evidence from r3. The Dockerfile has `FROM node:22` (`devcontainer-config/Dockerfile:14`) and installs distro `git` (`:24`), unpinned. The git version depends on which Debian release the `node:22` tag resolved to at build time. Verifying it needs a built image or registry access, and this sandbox has no network or docker. Any git below 2.48 without `worktree.useRelativePaths` would still write absolute paths.

**Evidence:** `devcontainer-config/Dockerfile:14-24`, `devcontainer-config/devcontainer.json:134`

---

## Claim 21: Plan Context — "The scan already records the private dir (`.git/worktrees/<n>`) by its fixed layout: config, config.worktree, info/attributes, hooks/ + entries, commondir, legacy remotes/branches, rebase-merge/, rebase-apply/, sequencer/, every symlink, and nested modules/** / worktrees/*."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_gitdir` reaching P through `_snap_nested "$real/worktrees"` (P qualifies via its `commondir` file, `looks_like_gitdir`) and the list in `_snap_gitdir`; does not establish that a P lacking `commondir` is walked (it is not, and it is then not accepted either).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "does not establish recording of a private dir whose HEAD was deleted. Such a dir is not walked, but then no `commondir-file` record exists and the note cannot be given"

Headline evidence from r1. `_snap_nested "$real/worktrees"` (:638) → `_snap_find … -mindepth 2 -name HEAD` → `looks_like_gitdir "$g"` → `_snap_gitdir` (:562-565), which records `config config.worktree` (:578-581), `info/attributes` (:582), hooks (:583), commondir (:584), remotes/branches (:594-614), rebase/sequencer (:616-623), symlinks (:626-636), nested (:637-638).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:555-639`, `devcontainer-config/cc-gitdir.sh:89`

---

## Claim 22: Plan Context — "The launcher maps `git_exit_scan` 0 → claude's own status, 1 → exit 3, 2 → exit 4. The acceptance lives inside `git_exit_scan` and returns 0, so `cc-isolated.sh` does not change."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:23`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The mapping is right and the launcher logic is unchanged; does not hold for the file as a whole, whose header comment, and so its `--help` output, changed in this unit.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

Headline evidence from r2. `case "$scan" in 0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;;` (`cc-isolated.sh:747-751`). But `git diff dfe4c0d q094-exit-scan-worktree-layout -- devcontainer-config/cc-isolated.sh` shows +2/-1 in the EXIT STATUS comment (`:20-21`). Tighten to "cc-isolated.sh's logic does not change (only its --help text)".

**Evidence:** `devcontainer-config/cc-isolated.sh:20-21`, `:743-751`

---

## Claim 23: Plan experiments table E1–E12

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:29-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers re-runs of E1, E2, E3 (pre-commit, post-commit, post-checkout; not pre-push / reference-transaction), E4, E5, E6, E7, E8, E9, E10 (only the ".git naming a missing path" shape), E11, E12 on git 2.39.5; does not re-run E3's pre-push/reference-transaction hooks or E10's "private dir removed / HEAD removed" shapes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "E5 (without a positive control for fsmonitor)"; E10 re-run for both the missing-HEAD and the missing-path cases · r3: "E4, E6 and E8 were not re-run"; "E10 (missing-HEAD variant only)"; E11 also accepted `../..\r\n`

Headline evidence from r1. `fcA-k7q2/logs/exp-e.txt`: E1 bytes (`../..\n` 6 bytes; private dir `HEAD ORIG_HEAD commondir gitdir index logs`); E2 paths exactly as tabled; E3 only `ran-common-post-commit`; E4 `no filter ran` then control `ran-filter`; E5 `none`; E6 `ignored` then `ran-hk`; E7 `ran-rel`; E10 `fatal: not a git repository: /nonexist/.git/worktrees/wt`; E11 both variants resolve to the same common dir. `fcA-k7q2/logs/exp-e2.txt`: E8 `ran-filter`; E9 `ran-prerecv`; E12 `git worktree remove` removed the last one and `.git/worktrees` no longer exists.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:29-44`, `fcA-k7q2/logs/exp-e.txt`, `fcA-k7q2/logs/exp-e2.txt`

---

## Claim 24: Plan acceptance rules 1–7 as the complete condition for the note

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:47-61`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rules 1–5 and 7 against `scan_std_worktrees` and `git_exit_scan`. Rule 6 describes unit B.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: "rule 5's third bullet omits that the container-form back-pointer needs the common dir inside the checkout (:866) — a stricter unstated check, same as Claim 12a"; rule 6 ("In this unit any removed record warns") verified against `*) return 1` (:833) and test 3 · r2: "does not re-derive rule 6, which lives in unit B"; rule-to-code table (rule 1 `:935`, rule 2 `:831-833`, rule 3 `:813`, rule 4 `:818-819`/`:843-847`, rule 5 `:848-887`, rule 7 `:892`)

Headline evidence from r3. Rules 1–5 and 7 are all implemented. Rule 1 is `[ -z "$invalid" ] &&` (`:935`); rule 2 is the `case` at `:830-834`; rule 4 names `.` and `..` explicitly. Unlike the source comment, rule 5 omits these declines:

- the 4097-byte back-pointer cap (`:861`)
- the `<rel>` component check (`:870`)
- the working tree not being inside the common dir (`:872`)
- the container-form back-pointer requiring `<common>` inside the checkout (`:866`; rule 5 states that condition only for the `.git` form)

Same class as Claim 12a, fail-closed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `devcontainer-config/cc-exit-scan.sh:935`

---

## Claim 25: "this unit came to 447 lines with it"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the committed states only; does not establish the count of the uncommitted pre-split working state the sentence refers to.
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=— · single-replicate detection
**Replicate annotations:** none

Headline evidence from r2. No commit holds "iteration-1 fixes plus removal acceptance". The counts outside `docs/` against dfe4c0d are 389 at b4de821 and 394 at 5a6d689 (paraphrased — no quote available because these are computed `git diff --numstat` sums, not source lines). Verifying 447 would need the discarded pre-split tree.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `git diff --numstat dfe4c0d b4de821|5a6d689 -- . ':!docs'`

---

## Claim 26: Plan — "A decline never errors … The scan still runs no git command in the checkout, and the note names only <n> values restricted by rule 4, through scan_vis."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:63`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `scan_std_worktrees` and `_snap_hash_str`/`_snap_file_is` containing no `git` invocation and the `scan_vis` pipe; does not re-audit the pre-existing snapshot's git use (`git config --file … ` from `/`).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:** r2 (inside its acceptance-rules claim): "The plan's line `:63`, 'the note names only `<n>` values … through `scan_vis`', matches `:894-895` and `:936`. No git command runs in `:806-896`."

Headline evidence from r1. (paraphrased — no quote available because the claim covers absence of code: reading :776-896 shows no `git` command; tools used are `awk`, `sha256sum`, `stat`, `find -P`, `sort`, `tr`, `cd`.) Note restriction and `scan_vis`: Claim 15a.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:776-896`, `:936`

---

## Claim 27a: Plan — "`_snap_config` and `_snap_remote` add `W <kind> <config or path %q>` whenever they resolve a path against a working tree."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:65`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every path resolution in the two functions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "plus two W emissions that resolve nothing (`\"\"` insteadOf base, which `_snap_remote` returns early on); does not cover `_snap_host_config`, which resolves your own config's relative paths against a working tree without W (by design, records instead — Claim 4a)" · r2: "does not cover `_snap_host_config`, which resolves against a working tree but emits F records instead"; "`include.path` resolves against the config's directory (`_snap_path \"$val\" \"$(dirname -- \"$f\")\"`, `:397`), not a working tree, so it correctly makes no W"

Headline evidence from r3. "Whenever" has two documented exceptions:

- `_snap_remote` resolves `.` against the base (`case "$p" in /*) ;; *) p="$base/$p" ;; esac`, `:358`) but emits no W, because `[ "$p" = . ] || _snap_wrel …` (`:357`). This is B29, by design.
- An insteadOf base of `.` gets its W from the explicit line at `:417`, not from `_snap_remote`.

Precise version: "…whenever they resolve a relative path against a working tree, except a remote of `.` (B29)."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-360`, `devcontainer-config/cc-exit-scan.sh:386-419`

---

## Claim 27b: Plan — "`scan_diff` ignores record types other than F and C, and a `W` record only changes when a C or F record does, so the report output is unchanged."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `scan_diff`'s awk and the W invariant (Claim 5). It does not establish the note path, which replaces the report when accepted.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "the unchanged warning output (169/169 pre-existing plus new tests)"

Headline evidence from r3.

```awk
# devcontainer-config/cc-exit-scan.sh:756-757
    FNR == NR { if ($1 == "F") b[$2 FS $3] = $4; else if ($1 == "C") bc[$0] = 1; next }
    { if ($1 == "F") a[$2 FS $3] = $4; else if ($1 == "C") ac[$0] = 1 }
```

(excerpt ends :757; enclosing `scan_diff()` continues to :769 — read). The END block iterates only `a`, `b`, `ac` and `bc`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:752-769`

---

## Claim 28: Plan B-table "covered"/"not accepted" rows (B1–B12, B16–B20, B26) with their stated mechanism

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:73-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the rows whose mechanism the tests exercise — B1/B2/B3/B7(info symlink)/B9 (test 5), B8/B10/B17/B26 (test 6), B16/B18/B19 (test 7), B12 (test 8), B20 (test 1), B11 by reading — and E3–E6 for "never run"; does not execute B5 (rebase dirs in P), B6 (modules in P) or B7's symlinked `P`/`worktrees/` shapes, which are verified only by reading `_snap_gitdir`'s recording plus the "every record consumed" rule (:892).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2 (covered B1–B14): "It does not establish B21–B23 and B27, whose accepting halves live in unit B; here only 'any removal warns' is checked (test 3)"; r2 gave Confidence High

Headline evidence from r1. Tests 1–9 in `fcA-k7q2/logs/bats-q094.txt` pass; the per-row test mapping is the Scope line above.

**Evidence:** `test/cc-isolated-functions.bats:2227-2384`, `devcontainer-config/cc-exit-scan.sh:573-639`, `:854-857`, `:892`, `fcA-k7q2/logs/bats-q094.txt`

---

## Claim 29: B13 — "Relative local remotes … incl. insteadOf bases, pushDefault/branch.*.remote naming a path, legacy remotes/*/branches/* — covered — Rule 3 (W from _snap_remote, which all of these go through)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:85`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "covered" (W is produced for every listed form, `fcA-k7q2/logs/exp-s.txt`); the mechanism "W from _snap_remote" is imprecise for insteadOf bases `.` and `""`, whose W comes from `_snap_config` :417 (`_snap_remote` exempts `.` at :357 and returns early on `""` at :349).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=—
**Replicate annotations:** r2 (B-table claim covering B1–B14): "B12, B13: test 8"

Headline evidence from r1. Precise version: "(W from `_snap_remote`, which all of these go through; for an insteadOf base of `.` or `""`, from `_snap_config` — see B30)."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:349`, `:357`, `:417`, `fcA-k7q2/logs/exp-s.txt`

---

## Claim 30: B14 — "When the worktree's .git resolves on the host, _snap_host_config already walks it for that git dir and any path inside the checkout becomes a new record (residue). When it does not resolve (container form, host not at /workspace), host git in it stops (E10)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches (host form: `rc=1` with `+ hooksdir …/.githooks`; container form: note; E10 fatal); does not cover `includeIf gitdir:` matching executed (read only: `_snap_cond` at :466-487 is called from the same walk).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "B14's container-form half: X4" · r3: "This is the accurate version of the header parenthetical that Claim 4b flags."

Headline evidence from r1. Executed in `fcA-k7q2/logs/exp-s.txt` (host form `rc=1`, container form note) and `fcA-k7q2/logs/exp-e.txt` (E10 `fatal: not a git repository`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:697-702`, `fcA-k7q2/logs/exp-s.txt`, `fcA-k7q2/logs/exp-e.txt`

---

## Claim 31: B15 — "`.gitmodules` `update=!cmd` is ignored by git"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:87`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git submodule update --init` on 2.39.5 after a clone; does not establish other submodule commands.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** none

Headline evidence from r2. X7: `fatal: invalid value for 'submodule.s.update'` and `update=!cmd from .gitmodules ran: no`. The command is not run, as the row concludes, but git refuses the value with a fatal error rather than ignoring it. Tighten to "rejected by git (fatal), never run".

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:87`, `fcA-r2x7/logs/exp4.txt`

---

## Claim 32: B21 — "Removal hiding a plant … covered — Rule 6 requires P gone on disk. E10: a private dir without HEAD is refused by git anyway"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:93`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited mechanism ("Rule 6 requires P gone on disk"), which is not in this unit's code; the "covered" status still holds in unit A, for a different reason (any removed record returns 1 at :833).
**Replicate verdicts:** r1=Stale · r2=— · r3=Stale
**Replicate annotations:** r2 (not surfaced as a claim; its B-table claim's scope): "does not establish B21–B23 and B27, whose accepting halves live in unit B; here only 'any removal warns' is checked (test 3)" · r3: "This row is unchanged since 6abe247 (`git diff 6abe247 9075003` does not touch it). … (B22's 'Its other records are residue' still holds.)"

Headline evidence from r1. Rule 6 itself says removal acceptance moved to `q094b-exit-scan-worktree-removal` (plan :60); B23 and B27 were updated to "Here, any removal warns", B21 was not. In A: `*) return 1 ;;` (`devcontainer-config/cc-exit-scan.sh:833`) catches every `-` line.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `:93`, `:95`, `:99`, `devcontainer-config/cc-exit-scan.sh:828-835`

---

## Claim 33: B25 — "Newer git writing relative paths (`worktree.useRelativePaths`, git ≥ 2.48) — not accepted (warns)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:97`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The "warns" half is verified: X1 test 6 writes the relative form `gitdir: ../../../.git/worktrees/agent-x` and gets a warning. The git ≥ 2.48 / `worktree.useRelativePaths` attribution needs git ≥ 2.48 or its release notes, and the sandbox has git 2.39.5 and no network.
**Replicate verdicts:** r1=Verified · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1: "does not verify the external fact that git 2.48 introduced `worktree.useRelativePaths` (no network; git 2.39.5 here)" (r1 verdicted the row on its "not accepted" consequence) · r3: "The claim is consistent with my recollection of the 2.48 release, but I could not check it here."

Headline evidence from r2. The test loop includes `$'gitdir: ../../../.git/worktrees/agent-x\n'` followed by `warns_listing_wt` (`test/cc-isolated-functions.bats:2320-2324`).

**Evidence:** `test/cc-isolated-functions.bats:2315-2342`, `fcA-r2x7/logs/bats-q094.txt`

---

## Claim 34: B28 — "Pattern matches in bash ([[ ]]), no pipeline. … The test (40k padding records) covers the two checks in `scan_std_worktrees`; the `invalid` check has no test of its own"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutation sensitivity of the two `scan_std_worktrees` checks; does not settle the `invalid` clause, which is true only in the narrow sense that it has no pipefail or large-snapshot test.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "the absence of any pipefail test for `invalid`"; "does not establish the test is sensitive to a revert of *only* the commondir check (not run separately; m2's first failing assertion is the one that check governs)" · r3: "`mut-inv-grep`: all tests still pass, which confirms 'no test of its own'" (r3 ran the commondir-only revert, `mut-cd-grep`, which fails test 4 at `bats:2283`)

Headline evidence from r2. X5: M2 (W check back to a pipeline) fails at `test/cc-isolated-functions.bats:2285` (`[ "$status" -eq 1 ]`), and M3 (commondir check back to a pipeline) fails at `:2283` (`[ "$status" -eq 0 ]`). So the test does cover both checks, each on its own. The `invalid` check does have functional tests (`[[ "$output" == *"! $SCAN_WS/.git is not a valid git directory now"* ]]`, `test/cc-isolated-functions.bats:1352`, `:1362`), and they pass on the new `[[ =~ ]]` form. Tighten to "has no pipefail test of its own".

**Evidence:** `test/cc-isolated-functions.bats:1352`, `:1362`, `:2273-2286`, `fcA-r2x7/logs/mut-M2-W-pipeline.txt`, `fcA-r2x7/logs/mut-M3-commondir-pipeline.txt`

---

## Claim 35a: B29 — "`.` is the repository git runs in … (verified: a push to `.` from the worktree ran the common `pre-receive`, not the private one). No W record"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 8 (r3): covers a push to `.` from a linked worktree (git 2.39.5) and the absence of a W record for a remote value `.`; does not establish fetch or other transports to `.`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Headline evidence from r3. "ran-common-pre-receive", and "no W for remote url ." (see Claim 8).

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:102`, `fcA-r3x7/logs/experiments2.txt`, `fcA-r3x7/logs/hostcfg.txt`

---

## Claim 35b: B30 — "An insteadOf base of `.` or of `""` … always makes a W record … Test cases for both, and for pushInsteadOf, were added; a mutation that drops `""` fails them. The broader, older gap … is now listed in the guide's Known routes"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the B29 push experiment, the three bats cases (`url...insteadOf`, `url..insteadOf`, `url..pushInsteadOf`), mutation m3, and the guide entry (Claim 40); does not execute `pushInsteadOf` with base `.`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish pushInsteadOf by experiment, only by test case: `url..pushInsteadOf` is in test 8" · r3: "The same mutation with the list reduced to only `url..pushInsteadOf` also fails. So each `\"\"` case fails independently: 'fails them' holds."

Headline evidence from r1 (r1's claim carries no body beyond its Scope and Evidence; the three cases and mutation m3 are listed there).

**Evidence:** `test/cc-isolated-functions.bats:2366-2381`, `fcA-k7q2/logs/exp-e2.txt`, `fcA-k7q2/logs/mut-m3.txt`, `guides/cc-isolated-usage.md:385-387`

---

## Claim 36a: Step 2: guide "the new known route list items (B12 cost, B25–B27 still warn)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:109`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what landed in the guide's Known routes and the Q-094 tests in unit A.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Stale (compound)
**Replicate annotations:** r2: "does not judge whether they belong in Known routes"; "B25 (relative paths) is implied only by 'exactly `gitdir: <private dir>\\n`'" · r2's Precise version: the B12 cost and B25–B27 "still warns" cases appear in the Q-094 paragraph instead of Known routes

Headline evidence from r3 (compound). The Known routes list gained only the "tracked file in a linked worktree" sentence and the insteadOf item (`guide:365-366,385-387`). The B12 cost is in the Q-094 paragraph (`:348-351`), not in Known routes. B25 (git ≥ 2.48 relative paths) appears nowhere in the guide (`grep useRelativePaths` finds nothing).

**Evidence:** `guides/cc-isolated-usage.md:334-387`

---

## Claim 36b: Step 3 lists a test for "private dir left behind after removal → 1"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:110`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers unit A's test file at 9075003; does not examine unit B's copy beyond locating the moved test.
**Replicate verdicts:** r1=— · r2=Stale · r3=Stale (compound)
**Replicate annotations:** r3: "Step 3 was edited in c32a734 but kept the item."

Headline evidence from r2. No Q-094 test in unit A exercises a private dir left behind. The only removal test is "a worktree removed during the session still warns" (`test/cc-isolated-functions.bats:2263-2271`), which does a clean `git worktree remove`. The half-removed case lived in b4de821's "a removed standard worktree is a note; a half-removed one warns" and now sits in unit B, `q094b-exit-scan-worktree-removal:test/cc-isolated-functions.bats:2263`. Drop the item from step 3, or mark it "(stacked unit)".

**Evidence:** `test/cc-isolated-functions.bats:2227-2394`, `git show b4de821:test/cc-isolated-functions.bats` (:2263)

---

## Claim 37a: Guide — "A linked worktree added in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stubbed-launcher run; does not establish a live host session.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Headline evidence from r2. X1 test 9 (`test/cc-isolated-functions.bats:2386-2394`) passed, and the mapping is at `cc-isolated.sh:747-748`.

**Evidence:** `test/cc-isolated-functions.bats:2386-2394`, `devcontainer-config/cc-isolated.sh:747-748`, `fcA-r2x7/logs/bats-q094.txt`

---

## Claim 37b: Guide — "3 the exit scan found a change (a note about standard worktrees is not one)"

**Location:** `guides/cc-isolated-usage.md:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same evidence as Claim 37a; does not re-check the unchanged codes 1, 2 and 4.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Headline evidence from r2. `git_exit_scan` returns 0 on the note path (`cc-exit-scan.sh:937`), and 0 maps to `exit "$rc"`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:935-937`, `fcA-r2x7/logs/bats-q094.txt`

---

## Claim 38: Guide Q-094 paragraph: the "Exact" rule list, "Anything else warns as before … and any checkout whose config holds a relative `core.hooksPath` or `core.attributesFile` (husky's `.husky/_`) or a relative local remote other than `.`, which git would resolve in the new worktree's tree, unscanned."

**Location:** `guides/cc-isolated-usage.md:334-351`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule summary against `scan_std_worktrees` and the refusal list. It does not establish husky's actual `core.hooksPath` value.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: "the 'Exact' summary, like Claim 12a, is a subset of the code's checks (it says so: '`scan_std_worktrees` has the full rule'), and 'any checkout whose config holds…' understates the refusal, which fires for a W from any config the scan reads (Claim 3)" · r2: "The 'other than `.`' exception applies to remote URLs and names: `insteadOf` bases `.` and `\"\"` do warn, which the paragraph does not state (the insteadOf case appears only under Known routes). The paragraph does not establish the note for repos whose embedded or vendored repos hold a relative hooksPath; those also warn, because any W in the snapshot refuses." · merge note: r1 and r2 recorded in Scope the same two imprecisions r3 verdicted on, but kept Verified

Headline evidence from r3. The rule summary matches the code: name charset `:845`, commondir `:848-855`, no hooks/config/config.worktree/symlink `:856-857`, working tree inside the checkout `:864-872`, `.git` host or container form `:878-887`. Test 8 confirms the refusals. Two imprecisions, as in Claim 3:

- "other than `.`" omits that an insteadOf base of `.` or `""` is never exempt (`cc-exit-scan.sh:417`; tests `url...insteadOf`, `url..insteadOf` and `url..pushInsteadOf` warn).
- A relative hooksPath in an embedded repo's config (not "the checkout's") also refuses the note (`fcA-r3x7/logs/hostcfg.txt`).

Both err toward more warnings, not fewer.

**Evidence:** `guides/cc-isolated-usage.md:334-351`, `devcontainer-config/cc-exit-scan.sh:414-418`, `test/cc-isolated-functions.bats:2367-2384`, `fcA-r3x7/logs/hostcfg.txt`

---

## Claim 39: Guide Known route — "The same holds in a linked worktree the session leaves behind: its tracked files are never read, only its layout (see above)."

**Location:** `guides/cc-isolated-usage.md:365-366`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the scan reads inside a new worktree's working tree. It does not establish anything about tracked files git itself executes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: "does not cover the snapshot's embedded-`.git` search and your own config's relative hooksPath walk, which do descend into the new worktree's tree (those only add refusals)" · r2: "It does not cover your own config's relative hooksPath/attributesFile targets inside that tree, which are recorded (Claim 4a). Those are not tracked content, and a tracked file used as one would be hashed." · merge note: r1 and r2 recorded the same reads r3 verdicted on, but kept Verified

Headline evidence from r3. The main point holds: the scan does not hash working-tree files in general. "Never read" is too strong, though:

- The embedded-repo `find -P … -name .git` walks the whole new tree (`cc-exit-scan.sh:694`).
- When your own config has a relative `core.hooksPath` and the worktree is host-form, `_snap_hooks` hashes every entry of `<wt>/<hooksPath>`, which may be tracked files (e.g. husky's `.husky/_`). Executed: `+ hooksdir …/w/x/.husky  missing` appeared in the warning.

That case refuses the note anyway, so this is imprecision, not a missed route. Suggest "its tracked files are not scanned".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:306-318`, `devcontainer-config/cc-exit-scan.sh:690-701`, `fcA-r3x7/logs/hostcfg.txt`

---

## Claim 40: Guide Known route — "A URL rewritten by `url.<base>.insteadOf`. The base is walked, never the rewritten URL, so a remote rewritten to a local path the session plants runs that repository's hooks on push."

**Location:** `guides/cc-isolated-usage.md:385-387`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_snap_remote "$t"` walking only the subsection `<base>` and the B30 experiment showing a rewritten relative URL's hook runs; does not establish the absolute-base case executed (read only).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish the top-level-checkout variant by experiment (static only)" · r3: "does not establish every rewrite shape"

Headline evidence from r1. `_snap_remote "$t" "$base"` (`devcontainer-config/cc-exit-scan.sh:418`), where `t` is the `url.<t>.insteadof` subsection (:416). `fcA-k7q2/logs/exp-e2.txt` B30 rows.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:414-418`, `fcA-k7q2/logs/exp-e2.txt`

---

## Claim 41a: Test names vs assertions (9 Q-094 tests) and the comment "git keeps '+' in a worktree name (a space it turns into '-')"

**Location:** `test/cc-isolated-functions.bats:2206-2394`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title against its assertions, and mutation sensitivity for tests 4, 6 and 8. Test 8's title ("keeps a new worktree a finding") is narrower than its body, which also asserts that the absolute-hooksPath and `.`-remote cases give status 0. It does not establish sensitivity of tests 1, 2, 5 and 7 to mutations.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish mutation sensitivity of tests 1, 2, 7, 9 (not mutated)"; name-sanitising comment executed (`wts/a+b` → `a+b`, `wts/c d` → `c-d`) · r3: "Test 8 also asserts the two accepted cases (absolute hooksPath, `branch.main.remote .`). The name does not mention them, but it does not contradict them."; `agent+x` and `agent y` gave names `agent+x` and `agent-y`

Headline evidence from r2. The details:
- "Git would also accept" holds for all four commondir variants (X3 E11).
- The pipefail test builds `for i in $(seq 40000)` padding and runs under `set -o pipefail` (`:2279-2285`).
- The FIFO case runs `timeout 20 … git_exit_scan` and asserts `warns_listing_wt` (`:2333-2335`). M1 fails it at `:2335`.
- X1 passed 9/9.

**Evidence:** `test/cc-isolated-functions.bats:2206-2394`, `fcA-r2x7/logs/bats-q094.txt`, `fcA-r2x7/logs/mut-M1-no-f-guard.txt`, `fcA-r2x7/logs/exp.txt`

---

## Claim 41b: "The container path the scan accepts is where devcontainer.json mounts the checkout." (bats check `grep -q "target=$GIT_EXIT_SCAN_CONTAINER_WS," "$CONFIG_SRC/devcontainer.json"`)

**Location:** `test/cc-isolated-functions.bats:2382-2384`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current file, where the only `target=/workspace,` is `workspaceMount` (`devcontainer.json:134`); does not establish that the grep is tied to the `workspaceMount` key. Any mount string containing `target=/workspace,` would satisfy it.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "`GIT_EXIT_SCAN_CONTAINER_WS` is `/workspace` in that test: bats re-sources the script per test, and test 2's override does not leak."

Headline evidence from r2. `grep -q "target=$GIT_EXIT_SCAN_CONTAINER_WS," "$CONFIG_SRC/devcontainer.json"` (`:2383`). The grep finds `target=` at `devcontainer.json:78`, `:79` (other targets) and `:134`. X1 passed.

**Evidence:** `test/cc-isolated-functions.bats:2383`, `devcontainer-config/devcontainer.json:78-79`, `:134`

---

## Claim 42: commit b4de821 — "when every record-level difference is a worktree of the checkout's own common dir added or removed in the exact layout git writes, it prints one note: line and returns 0 … Removed worktrees need P gone on disk."

**Location:** commit `b4de821` message
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tip's behaviour; true at b4de821, whose code accepted `[+-]F` records; does not re-verify unit B's removal acceptance.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Verified
**Replicate annotations:** r1: "the rest of the message (checks, W records, 'scan_diff ignores W records, so warning output is unchanged') is Verified at the tip (Claims 3, 5, 12a)"; "Commit messages are immutable; the plan (rule 6) and c32a734 record the move." · r3: "Covers the claim against b4de821's own tree. The removal half is superseded within the range by c32a734, which says so explicitly."; r3's stated decision: commit messages verdicted against their own commit's tree ("Claim 42 Verified though later superseded") · r2's stated decision: "b4de821 is Stale rather than Incorrect"

Headline evidence from r2. At b4de821 the loop accepted `[+-]F$'\t'dotgit$'\t'*|…` (`git show b4de821:devcontainer-config/cc-exit-scan.sh:825`). At the tip only `+F…` records pass, and any removal is `*) return 1` (`:831-833`). X1 test 3, "a worktree removed during the session still warns", passes. Removal acceptance moved to unit B (c32a734). Nothing to fix in the history; a reader of `git log` on this branch should know that c32a734 supersedes it.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:828-835`, `test/cc-isolated-functions.bats:2263-2271`

---

## Claim 43: commit 5a6d689 — "A FIFO planted at .git/worktrees/<n>/gitdir blocked the exit scan's read in scan_std_worktrees … Test: a FIFO there warns within a timeout."

**Location:** commit `5a6d689` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard at the tip and the test's sensitivity to removing it; does not re-run at 5a6d689 itself.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish the 'Ctrl-C and exit 4' path, which was not run"

Headline evidence from r2. `[ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1` (`cc-exit-scan.sh:860`). M1 (X5) fails test 6 at the FIFO step, `test/cc-isolated-functions.bats:2335`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:858-863`, `fcA-r2x7/logs/mut-M1-no-f-guard.txt`

---

## Claim 44: commit 5a6d689 — "The rest of the scan checks -f before every read; this one now does too."

**Location:** commit `5a6d689` message
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the state at 5a6d689, where the claim was false, and at 9075003, where it now holds, as far as every file read was traced (`_snap_first_line` callers, `_snap_hash`, `_snap_config`, legacy `cat`, `gitdir_head_kind`); does not establish TOCTOU safety.
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1 (compound, verdicted at the tip): "does not make 5a6d689's sentence true *at 5a6d689* — mutation m1 (removing the :328 guard) hangs the snapshot on a FIFO `P/config` next to a legacy remote (`timeout 20` → rc 124), as c32a734 concedes" · r2+r3: historical only; the tip's code matches the claim and the message cannot be changed without a history rewrite · r2+r3 stated decision: commit messages verdicted against their own commit

Headline evidence from r2. At 5a6d689, `_snap_worktree_of` read `$1` with no `-f`: `elif v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then` (`git show 5a6d689:devcontainer-config/cc-exit-scan.sh:325`). A FIFO `config` next to a legacy `remotes/` file hangs the snapshot there (X6 mutant M7, which restores that line: rc 124). c32a734's message acknowledges this ("makes 5a6d689's '-f before every read' true"), and the tip adds `[ -f "$1" ] &&` (`:328`). A commit message cannot be amended without a rewrite, so this is recorded for the history only; the tip's code matches the claim.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:328`, `git show 5a6d689:devcontainer-config/cc-exit-scan.sh` (:325), `fcA-r2x7/logs/exp3-mut.txt`, `fcA-r2x7/logs/exp3-tip.txt`

---

## Claim 45: commit c32a734 — R1 (pipefail fail-open; "All three checks, including the older `invalid` check …, are now bash pattern matches. Test: 40k padding records, both directions, under pipefail"), the `-f` guard in `_snap_worktree_of` ("a FIFO config hung the snapshot; makes 5a6d689's '-f before every read' true"), indexed dotgit lookup, the 4097-byte cap, "a '.' remote … makes no W record", and the devcontainer.json bats check

**Location:** commit `c32a734` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each code-level statement at the tip; does not verdict the reported review-finding severities or the "(hidden only by the next check failing the same way)" history at b4de821, which was not re-run.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not verify review-process statements" · r3: "The removal split (R2) is verified only as absence: unit A has no removal acceptance."

Headline evidence from r2. The pieces:
- Three `[[ ]]` checks at `:813`, `:819` and `:928`, with no `grep -q` pipelines left.
- X4 shows the old pipeline returning FALSE (141).
- M2 and M3 fail the test.
- X6 covers the FIFO config.
- The indexed lookup is `dot["${line%$'\t'*}"]="$line"` (`:831`) with `dk="${dot[…]:-}"` (`:874`).
- The cap is `-le 4097` (`:861`).
- The `.` remote is covered by B29 (X3) and M6.
- The bats check is at `:2383`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:811-892`, `:926-928`, `fcA-r2x7/logs/exp2.txt`, `fcA-r2x7/logs/exp3-tip.txt`, `fcA-r2x7/logs/mut-M2-W-pipeline.txt`, `fcA-r2x7/logs/mut-M3-commondir-pipeline.txt`, `fcA-r2x7/logs/mut-M6-no-dot-exempt.txt`

---

## Claim 46: commit 5fadfc2 — "No code behaviour change; the only line in cc-exit-scan.sh that changes is comments."

**Location:** commit `5fadfc2` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff `5fadfc2~1..5fadfc2` in cc-exit-scan.sh, where two changed lines are both comments; does not cover the other files in the commit (docs only).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "the only line" is two lines, both comments

Headline evidence from r2. The diff's changed lines are `# core.hooksPath, core.attributesFile or local remote (not ".") in repo config would` and `  # Only linked worktrees added in git's standard layout (STANDARD`. Both are comments. "The only line" is loose (there are two), but the stated conclusion, no behaviour change, holds.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:81`, `git diff 5fadfc2~1 5fadfc2 -- devcontainer-config/cc-exit-scan.sh`

---

## Claim 47: commit 037621f — insteadOf base "." bypass ("a host push there ran its hook"), "a mutation that drops the line fails it", "unit at 399 changed code lines outside docs/ against dfe4c0d"

**Location:** commit `037621f` message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the experiment, the mutation (M5 at the tip, which also removes the `""` arm that came later) and the line count; does not verdict "Performance iteration 2: no findings", which is a review outcome, not code.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not verify review-process statements ('Performance iteration 2: no findings' …)" (same as winning scope) · r3: "`git show 037621f -- guides/cc-isolated-usage.md` removes 'Each new worktree adds tens of milliseconds more to the check that allows the note.' … The net slow-scan clause (`guide:379-384`) is identical to dfe4c0d's."

Headline evidence from r2. X3: `B30 base='.' … hook ran: yes`. M5 fails test 8. `git diff --numstat dfe4c0d 037621f -- . ':!docs'` gives 171+4, 2+1, 29+3 and 189+0, which is 399 (paraphrased — no quote available because this is a computed numstat sum).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:417`, `fcA-r2x7/logs/exp.txt`, `fcA-r2x7/logs/mut-M5-drop-line.txt`

---

## Claim 48: commit 9075003 — "git accepts `[url \"\"] insteadOf = …` (key url..insteadof), which rewrites a remote to a bare relative path … _snap_remote returns early on \"\" … A base of \"\" or \".\" now always makes a W record. … a mutation that drops \"\" fails them."

**Location:** commit `9075003` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the experiment, the early return, the fix and the mutation; does not verify "it has not been re-reviewed by a critic", which is process history.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "The mutation fails each `\"\"` case independently (Claim 35b)."

Headline evidence from r2. `_snap_remote` begins `case "$p" in "") return 0 ;;` (`cc-exit-scan.sh:348-349`). X3: `B30 base='' rewrites to 'evil' hook ran: yes`. M4 fails test 8 at `test/cc-isolated-functions.bats:2380`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-349`, `:417`, `fcA-r2x7/logs/exp.txt`, `fcA-r2x7/logs/mut-M4-drop-empty.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`devcontainer-config/cc-exit-scan.sh:83-84`): "Your own config's relative hooksPath is walked in each new worktree" is false for a container-form worktree on a host not at `/workspace`, the main Q-094 case: it is not walked and the note prints (r3, executed rc=0). Safe only because host git refuses that worktree (E10). r1 and r2 rated the sentence as a whole Mostly accurate for the same reason. Reword to plan B14's two-case form.
- **Claim 44** (commit `5a6d689`): "The rest of the scan checks -f before every read" was false at that commit (`_snap_worktree_of` had no `-f`; a FIFO config hangs the snapshot, executed by r2 and r3). c32a734 made it true; history only, nothing to change at the tip.

### Stale
- **Claim 32** (`docs/working/plan-q094-exit-scan-worktree-layout.md:93`): B21 cites "Rule 6 requires P gone on disk", which is in unit B now; in unit A any removed record warns. Update like B23 and B27.
- **Claim 36a** (`docs/working/plan-q094-exit-scan-worktree-layout.md:109`): step 2's "known route list items (B12 cost, B25–B27)" did not land as Known-routes items.
- **Claim 36b** (`docs/working/plan-q094-exit-scan-worktree-layout.md:110`): step 3 lists a "private dir left behind after removal → 1" test that moved to unit B.
- **Claim 42** (commit `b4de821`): "added or removed … Removed worktrees need P gone on disk" describes the pre-split code; c32a734 supersedes it (r3 verdicted it Verified against b4de821's own tree).

### Mostly Accurate
- **Claim 3** (`devcontainer-config/cc-exit-scan.sh:80-83`): the "(not ".")" exemption does not cover insteadOf bases `.` and `""`, and W comes from any config the scan reads, not only "repo config".
- **Claim 4a** (`devcontainer-config/cc-exit-scan.sh:83-84`): host-form half of the own-config sentence; carries r1/r2's compound Mostly-accurate verdict (the defect is the container form, Claim 4b); r3 verified the host form alone.
- **Claim 12a** (`devcontainer-config/cc-exit-scan.sh:793-805`): every stated check is in the code, but the comment omits six stricter declines.
- **Claim 12b** (`devcontainer-config/cc-exit-scan.sh:795-805`): carries r3's compound Mostly-accurate verdict on the whole doc comment; r1 verified these two sentences on their own.
- **Claim 22** (`docs/working/plan-q094-exit-scan-worktree-layout.md:23`): "`cc-isolated.sh` does not change": its logic does not, its `--help` text did.
- **Claim 24** (`docs/working/plan-q094-exit-scan-worktree-layout.md:47-61`): rule 5 omits the same extra declines as Claim 12a.
- **Claim 27a** (`docs/working/plan-q094-exit-scan-worktree-layout.md:65`): "whenever they resolve a path against a working tree" has the `.` remote exception (B29), and the `.` insteadOf W comes from `:417`.
- **Claim 29** (`docs/working/plan-q094-exit-scan-worktree-layout.md:85`): B13 attributes all remote W records to `_snap_remote`; for insteadOf bases `.` and `""` the W comes from `_snap_config:417`.
- **Claim 31** (`docs/working/plan-q094-exit-scan-worktree-layout.md:87`): git rejects `.gitmodules` `update=!cmd` (fatal) rather than ignoring it; the command never runs either way.
- **Claim 34** (`docs/working/plan-q094-exit-scan-worktree-layout.md:100`): "the `invalid` check has no test of its own" should read "no pipefail test of its own".
- **Claim 38** (`guides/cc-isolated-usage.md:334-351`): "relative local remote other than `.`" omits that insteadOf bases `.` and `""` always refuse, and embedded repos' relative hooksPath also refuses.
- **Claim 39** (`guides/cc-isolated-usage.md:365-366`): "its tracked files are never read" is too strong; suggest "not scanned".

### Unverifiable
- **Claim 20** (`docs/working/plan-q094-exit-scan-worktree-layout.md:21`): "git 2.39 (the image's git)" needs a built image or registry access (`FROM node:22` is unpinned).
- **Claim 25** (`docs/working/plan-q094-exit-scan-worktree-layout.md:60`): "447 lines" refers to an uncommitted pre-split state; the committed states count 389 and 394.
- **Claim 33** (`docs/working/plan-q094-exit-scan-worktree-layout.md:97`): the `worktree.useRelativePaths` / git ≥ 2.48 attribution needs a newer git or its release notes; the "warns" half is verified.

---

## Goal-Alignment Note
- Success criterion (restated verbatim): Merged canonical fact-check reports for units A and B, schema-conformant
- Answered: yes for unit A. 57 merged claims from 40 (r1), 47 (r2) and 45 (r3) replicate claims; every replicate claim maps to at least one merged claim.
- Out of scope: new verification of any kind (this is collation only); unit B (its own merged report); the replicates' own out-of-scope items (r2: `docs/reviews/` artifacts, unit B's removal acceptance, the unchanged slow-scan clause at `guides/cc-isolated-usage.md:379-384`; r3: prior `docs/reviews/*`, a live host cc-isolated session).
- Escalate: see `## Escalations` (four entries, all addressed to the orchestrator; no replicate named a critic).
- Decisions I made: (1) For compound/atomic mismatches, the compound replicate's verdict is carried on every sub-claim row and counts in most-severe-wins, so Claim 4a (r3 Verified) and Claim 12b (r1 Verified) are Mostly accurate by carry-over; the annotations say so. (2) r1's Claim 38b (commits 5a6d689 + c32a734 + code :328) was treated as a compound covering Claims 7, 43, 44 and 45; its Verified-at-tip verdict is recorded as `(compound)` on each. (3) r2's acceptance-rules claim, which also checked plan line 63, is recorded as a compound on Claim 26. (4) Where tied replicates had equally specific Scope lines, the lowest replicate number supplied the evidence.

---

## Escalations

- **`devcontainer-config/cc-exit-scan.sh:83-84`** (Claims 4a/4b): the own-config hooksPath sentence is wrong for container-form worktrees; its safety rests on a container-form `.git` not resolving on the host (covered by `:885-887`, E10, r2's X4). Raised by r2 ("Escalate: nothing blocking. Claim 4's safety rests on …") and r3 ("Claim 4b (header comment wrong for the container-form case, safe only via E10) … small doc fixes before merge"). Addressee: orchestrator.
- **`docs/working/plan-q094-exit-scan-worktree-layout.md:93`** (Claim 32): B21's stale mechanism, a small doc fix before merge. Raised by r3. Addressee: orchestrator.
- **`devcontainer-config/cc-exit-scan.sh:80-83`, `guides/cc-isolated-usage.md:334-351`, `devcontainer-config/cc-exit-scan.sh:793-805`** (Claims 3, 38, 12a): tightening edits. Raised by r3. Addressee: orchestrator.
- **commit `5a6d689` message** (Claim 44): the one Incorrect is in an immutable commit message and c32a734 already acknowledges it; no action at the tip. Raised by r2. Addressee: orchestrator.

---

## Verdict stability

- Total clusters (merged claim rows, sub-claims counted separately): 57
- Clusters where all reporting replicates agreed: 41 (including 3 single-replicate detections: Claims 14, 25, 31). Among the 54 clusters with at least two reporting replicates: 38 agreed.
- Clusters where verdicts disagreed: 16
  - Claim 3: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 4a: r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Verified
  - Claim 4b: r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Incorrect
  - Claim 12a: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate (compound)
  - Claim 12b: r1=Verified · r2=Verified (compound) · r3=Mostly accurate (compound)
  - Claim 20: r1=— · r2=Verified · r3=Unverifiable
  - Claim 24: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 27a: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
  - Claim 29: r1=Mostly accurate · r2=Verified (compound) · r3=—
  - Claim 33: r1=Verified · r2=Unverifiable · r3=Unverifiable
  - Claim 34: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 36a: r1=— · r2=Mostly accurate · r3=Stale (compound)
  - Claim 38: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 39: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 42: r1=Stale · r2=Stale · r3=Verified
  - Claim 44: r1=Verified (compound) · r2=Incorrect · r3=Incorrect
- Agreement rate: 41/57 = 71.9% (38/54 = 70.4% excluding single-replicate clusters). Below the ≥90% bar for dropping to k=2.
