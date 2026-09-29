# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace/.claude/worktrees/agent-aaad54fc687b7548c`), branch `q094b-exit-scan-worktree-removal`
**Commit:** 7c97a6b
**Replication:** k=1 (fix confirmation)
**Scope:** range a7e9b7a..7c97a6b (`devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `test/cc-isolated-functions.bats`, and the 7c97a6b commit message), plus the plan-only commit 31baaba (on base branch `q094-exit-scan-worktree-layout`) and its commit message. Every claim was checked against its callers and tests, not only the file it sits in.
**Checked:** 2026-09-28 (runs at 2026-09-29T03:52Z–04:02Z UTC)
**Legibility-target:** the parent agent deciding whether the Q-094 units A+B can merge, and the user reading the merged guide and plan. Verdicts are written so that a reader who has not opened the code can act on them.
**Total claims checked:** 47
**Summary:** 40 verified, 3 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

**Execution environment.** All runs used a scratch extract rather than the worktree: `git -C <repo> archive 7c97a6b | tar -x` into `$D/b` (and 31baaba into `$D/a`, a7e9b7a into `$D/old`), where `D=/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/re-fc-1065017133`. bats ran as `TMPDIR=$D/tmp LC_ALL=C bats …` (Bats 1.8.2, GNU bash 5.2.15, git 2.39.5). Mutation copies are `$D/m-<name>`. Experiment tests (EXP1–EXP5) were appended to a copy of the test file in `$D/x` only. The worktree was not modified.

**Hallucination-pattern log.** I read `docs/reviews/hallucination-patterns.md`, which has 5 real entries. Three of them are test-tally or count claims (for example, "All 85 tests … pass", "mode1-equiv 33"). This run checks the count-shaped claims (173/173, 267, 399, 16 s) the same way, by running them. None matched a logged pattern.

---

## Claim 1: "Unit A sits at the row-62 size cap (399 lines)" / "Unit B at 267 changed code lines on top of A" (also 31baaba: "399 changed code lines outside docs/")

**Location:** `git show 7c97a6b` (message, paragraph 1 and Notes); `git show 31baaba` (message, paragraph 2)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two numstat counts (A = dfe4c0d..31baaba, B = 31baaba..7c97a6b, outside `docs/`, adds plus deletes) and that dfe4c0d is A's base on main. It does not establish how the cap is applied beyond what decision-log row 62's text says.

Command (cwd = the worktree, 2026-09-29T04:02:03Z, exit 0): `git diff --numstat 31baaba 7c97a6b -- . ':!docs'` gives `95 19 cc-exit-scan.sh`, `28 10 guides/cc-isolated-usage.md` and `111 4 test/cc-isolated-functions.bats`, which sum to 267. `git diff --numstat dfe4c0d 31baaba -- . ':!docs'` gives 171+4, 2+1, 29+3 and 189+0, which sum to 399. `git merge-base main 31baaba` = `dfe4c0df…`. Decision log row 62 says the cap is "~400 changed code lines, counted outside `docs/` … Added and removed lines both count … the gate fires above 400" (`docs/decisions/log.md:85`). So 399 is at the cap without firing it.

**Evidence:** `$D/git-counts.log`, `docs/decisions/log.md:85`

---

## Claim 2: "a worktree made by container git has .git = "gitdir: /workspace/...", which names nothing on a host whose checkout is elsewhere, so the snapshot never walked your own relative core.hooksPath in it; the note hid a planted hook that ran after `git worktree repair`. The snapshot now maps such a .git to its host twin (_snap_container_target) and walks your config there, at launch and at exit. Test: …"

**Location:** `git show 7c97a6b` (message, "Unit A, security")
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix gap (reproduced by deleting the new line), the fix path, the fact that the same snapshot function runs at launch and at exit, and that the hook runs after a repair. It does not establish behavior for a container-form `.git` that is a symlink, since `_snap_container_target` returns nothing for a link.

Before the fix, the walk ran only when `_snap_dotgit_target` resolved. The fix adds a fallback:

```bash
# devcontainer-config/cc-exit-scan.sh:718-721
      g="$(_snap_dotgit_target "$f")" || { rc=1; break; }
      # A container-form .git: walk your config as it will apply after a repair.
      [ -n "$g" ] || g="$(_snap_container_target "$f")" || { rc=1; break; }
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
```

`git_exec_snapshot` is the one function that takes both the launch and the exit snapshot (`git_exit_scan` calls it at `:983`), so "at launch and at exit" holds.

- **Mutation (line 720 deleted, 2026-09-29T03:56:10Z, cwd `$D/m-container-walk`, exit 1).** The new test fails at `warns_listing_wt`: the note is printed where a warning is required.
- **EXP3 (cwd `$D/x`, 2026-09-29T03:59:34Z, exit 0).** With a container-form `.git` naming a missing path, `git status` gives `fatal: not a git repository` (status 128). After `git worktree repair`, `.git` reads `gitdir: …/proj/.git/worktrees/agent-x`, and `git commit` runs the planted hook (marker `hook-pre-commit` present).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:555-567`, `devcontainer-config/cc-exit-scan.sh:714-723`, `$D/mut-container-walk.log`, `$D/experiments.log`

---

## Claim 3: "a removal was accepted while a repository sat at the old .git path behind a symlinked parent (find -P makes no record there). The removal now also requires nothing at that path. Test: parent swapped for a link to an outside dir holding a repo warns; the same link without the repo is a note (control)."

**Location:** `git show 7c97a6b` (message, "Unit B, security")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlinked-parent case in the test and the new `[ ! -e ] && [ ! -L ]` check. It does not establish anything about other routes to an unrecorded repository (see the guide's Known routes, Claim 40).

The new check:

```bash
# devcontainer-config/cc-exit-scan.sh:914-918
      wt="$(_snap_unq "$q")" || return 1
      case "$wt" in */.git) ;; *) return 1 ;; esac
      [ ! -e "$wt" ] && [ ! -L "$wt" ] || return 1
      wt="${wt%/.git}"
      ! looks_like_gitdir "$wt" || return 1
```

`_snap_find` runs `find -P "$@" -print0` (`:273-279`), so it does not descend a symlinked `.claude/worktrees`.

- **Mutation (line 916 deleted, cwd `$D/m-old-dotgit`, exit 1).** The test fails at `test/cc-isolated-functions.bats:2338` (`[ "$status" -eq 1 ]`, the symlinked-parent case). Without the check, the case produces a note, which shows that no record is made there.
- **The control.** `:2341-2342` expects status 0, and in `git_exit_scan` status 0 with differing snapshots is only reachable through the note (`:1011-1013`). The control does not assert the note text itself.

**Evidence:** `test/cc-isolated-functions.bats:2331-2343`, `devcontainer-config/cc-exit-scan.sh:273-279`, `$D/mut-old-dotgit.log`

---

## Claim 4: "_snap_unq returns on stdout like its siblings (api-consistency); the note says "Removed ones' git dir and .git file are gone", which is what is checked."

**Location:** `git show 7c97a6b` (message); `devcontainer-config/cc-exit-scan.sh:968-969`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `_snap_unq` output channel, and that the note's two nouns match the two checks the removal branch makes. It does not establish that "gone" covers a path the scan cannot stat. Those decline by failing closed, which is consistent.

- **Output channel.** `_snap_unq` ends `printf '%s' "$s"` (`:816`), and its caller reads it as `wt="$(_snap_unq "$q")"` (`:914`). The sibling `_snap_hash_str` also prints (`:800`).
- **"git dir … gone".** Checked by `[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`:899`).
- **".git file … gone".** Checked by `[ ! -e "$wt" ] && [ ! -L "$wt" ]` on the `…/.git` path (`:916`), plus the removed `dotgit` record paired by content (`:902-909`).
- **The note text.** `why="Removed ones' git dir and .git file are gone"` (`:968`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:797-817`, `devcontainer-config/cc-exit-scan.sh:898-920`, `devcontainer-config/cc-exit-scan.sh:966-971`

---

## Claim 5: "Docs: the header's container-form and "." wording …, the scan_std_worktrees comment …, the _snap_* header and the _snap_bytes local, plan B14/B18, and the guide (note forms, the $'…' add/remove asymmetry, the insteadOf/embedded-repo cases, "not scanned", and a Known routes bullet …)"

**Location:** `git show 7c97a6b` (message, "Docs:")
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each listed change is present in the diff. Whether each change is itself accurate is verdicted in its own claim below: Claims 12–14, 18–19, 26, 28 and 33–40. Two of those are Incorrect (12b and 35b).

Every listed item appears in `git diff a7e9b7a 7c97a6b`:

- the header at `:81-86`
- the `scan_std_worktrees` comment at `:837-849`
- the `_snap_*` header at `:150-151`
- the `_snap_bytes` comment at `:852`
- plan B14 at `:87` and B18 at `:91`
- guide lines `:338-339`, `:345-347`, `:357-363`, `:378` and `:410-415`

(paraphrased — no quote available because the claim is a list of diff hunks, each quoted in its own claim below)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:81-86`, `devcontainer-config/cc-exit-scan.sh:150-151`, `devcontainer-config/cc-exit-scan.sh:837-852`, `docs/working/plan-q094-exit-scan-worktree-layout.md:87-91`, `guides/cc-isolated-usage.md:338-415`

---

## Claim 6: "The pipefail test builds its padding with one printf (16 s -> 0.1 s)." / test comment "one printf: a loop costs ~16 s under bats"

**Location:** `git show 7c97a6b` (message); `test/cc-isolated-functions.bats:2387`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the padding construction cost on this machine, and that both forms build a string of the same length. The exact seconds depend on the machine.

Command: `bats -T timing.bats` (cwd `$D`, 2026-09-29T03:58:24Z, exit 0). It holds two tests, one per construction form:

- The old loop, `for i in $(seq 40000); do pad+=…; done`, took **17960 ms**.
- The new `pad="$(printf 'F\tzz\t/p/%s\tmissing\n' $(seq 40000))"$'\n'` took **66 ms**.
- Both build a 868894-byte string.
- The whole pipefail test took 18174 ms at a7e9b7a and 3536 ms at 7c97a6b.

"16 s" is within machine variance of 18 s, and "0.1 s" matches.

**Evidence:** `$D/timing.log`, `$D/timing-pipefail-old.log`, `$D/timing-pipefail-new.log`, `test/cc-isolated-functions.bats:2380-2393`

---

## Claim 7: "Mutations: dropping the container walk, the old-.git check, the re-quote check, or looks_like_gitdir each fail a test."

**Location:** `git show 7c97a6b` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named single-line mutations against the Q-094 and `_snap_unq` tests. It does not establish that other mutations would be caught.

`$D/mut.sh <name> <sed>` copies the extract, applies the edit, and runs `bats -f 'Q-094|_snap_unq'` (cwd `$D/m-<name>`, 2026-09-29T03:56:10Z). The unmutated control passed 13/13, exit 0.

| Mutation | Edit | Exit | Failing test (line) |
|---|---|---|---|
| container walk | delete `:720` | 1 | "YOUR relative hooksPath … container-form" (`:2274`) |
| old-.git check | delete `:916` | 1 | "a removal whose old working tree …" (`:2338`) |
| re-quote check | `:815` → `true` | 1 | "_snap_unq: …" (`:2363`, `run ! _snap_unq "a$bs"`) |
| looks_like_gitdir | delete `:918` | 1 | "a removal whose old working tree …" |

**Evidence:** `$D/mut-container-walk.log`, `$D/mut-old-dotgit.log`, `$D/mut-requote.log`, `$D/mut-looks-like.log`, `$D/mut-none.log`

---

## Claim 8: "cc-isolated-functions.bats 173/173."

**Location:** `git show 7c97a6b` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this one file at 7c97a6b in this container. It does not establish that other suites pass, or that the result is the same on a host.

Command: `TMPDIR=$D/tmp LC_ALL=C bats test/cc-isolated-functions.bats` (cwd `$D/b`, 2026-09-29T03:52:18Z, exit 0). 173 `ok` lines, 0 `not ok`.

**Evidence:** `$D/bats-full.log`

---

## Claim 9a: "wrong for tabs and other $'…' bytes (only a newline declines on add)"

**Location:** `git show 7c97a6b` (message, Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tab (run) and a newline (run) in a working-tree path. The claim for other `$'…'` bytes rests on static reading: the back-pointer is read with `read -r`, which stops only at `\n`, and the `%q` strings are recomputed on both sides.

EXP1 (cwd `$D/x`, 2026-09-29T03:59:34Z, exit 0):

- A worktree added at `…/odd<TAB>dir/agent-t` gives status 0 and `note: … (added: agent-t)`.
- The same path with a newline, when added, gives status 1.
- A tab path removed gives status 1.

The newline declines because `line="$(_snap_first_line "$p/gitdir" …)"` reads one line, and `_snap_file_is "$p/gitdir" "$(_snap_hash_str "$line"$'\n')"` then fails (`:931-932`).

**Evidence:** `$D/experiments.log`, `devcontainer-config/cc-exit-scan.sh:929-937`

---

## Claim 9b: "2eebdf8's note "the added side already declines such paths" is wrong …"

**Location:** `git show 7c97a6b` (message, Notes)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the cited hash is where the quoted note lives in this branch. It does not affect the behavioral part, which is Claim 9a.

The quoted text exists in `2eebdf8`, but `git merge-base --is-ancestor 2eebdf8 7c97a6b` exits 1: 2eebdf8 is not in this branch's history. The in-branch commit with the same subject and the same Notes text is `a7e9b7a`:

```
a7e9b7a message:29  choice; the added side already declines such paths (its back-pointer read
```

A reader running `git log` on the merged branch will not find 2eebdf8. The precise reference is a7e9b7a, the rebased copy of 2eebdf8.

**Evidence:** `$D/git-counts.log`, `git show a7e9b7a`, `git show 2eebdf8`

---

## Claim 10: "Users with a relative hooksPath in their own config now see the warning on every new worktree in either form, as host-form ones already did."

**Location:** `git show 7c97a6b` (message, Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a global `core.hooksPath .githooks` with no hook planted, in host form and in container form. "Already did" for host form rests on the diff: only the container-form fallback was added.

EXP2 (cwd `$D/x`, 2026-09-29T03:59:45Z, exit 0) prints `OWN[core.hooksPath .githooks] host-form status=1` and `container-form status=1`. The same holds for `core.attributesFile .attrs`. The warning comes from the new `hooksdir <wt>/.githooks missing` record: `_snap_hooks` records a missing dir (`:312-314`), and `scan_std_worktrees` never marks that record `used` (`:961`).

**Evidence:** `$D/experiments-exp2.log`, `devcontainer-config/cc-exit-scan.sh:310-323`, `devcontainer-config/cc-exit-scan.sh:961`

---

## Claim 11: 31baaba message: "Plan-only fixes from the fact-check: B21's rule-6 reference …, steps 2 and 3 …, the cc-isolated.sh line …, B13 …, B15 …, B28 …, the uncommitted 447-line count, and the extra declines rule 5 did not list." / "B14 is reopened … the fix … land[s] in the stacked unit"

**Location:** `git show 31baaba` (message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 31baaba touches only the plan, and that each listed item is changed there. Each item's accuracy is verdicted in Claims 22–31.

`git show --stat 31baaba` lists one file, `docs/working/plan-q094-exit-scan-worktree-layout.md | 21 +++---`. Every listed item appears in its diff:

- the line-23 `--help` text
- rule 5's extras (`:60`) and rule 6's 447 note (`:61`)
- B13, B14, B15, B21 and B28
- steps 2 and 3
- the closing paragraph

The fix for B14 is in 7c97a6b (Claim 2).

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:23`, `docs/working/plan-q094-exit-scan-worktree-layout.md:60-61`, `docs/working/plan-q094-exit-scan-worktree-layout.md:86-114`

---

## Claim 12a: "A relative core.hooksPath, core.attributesFile or local remote (a remote of "." excepted, but not an insteadOf base of "." or "") in any config the scan reads … leave W records, and any W record refuses the note." — for repository configs (the checkout's, embedded repos', include targets)

**Location:** `devcontainer-config/cc-exit-scan.sh:81-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every config walked by `_snap_config`: the checkout's, embedded repos', and include targets inside the checkout. It does not cover your own global and system config (see 12b).

- **The `"."` exemption and the insteadOf rule.** `_snap_config` records W through `_snap_wrel` for `core.hookspath` and `core.attributesfile` (`:397`, `:405`). For insteadOf, `case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac` (`:421`). `_snap_remote` exempts only `.`, with `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`:361`).
- **The refusal.** `[[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1` (`:858`).
- **Tests.** The existing test at `test/cc-isolated-functions.bats:2474-2491` passed in the 173/173 run. It covers `.husky/_`, `.attrs`, `./sub.git`, `url...insteadOf` and `url..insteadOf` (warn), and `branch.main.remote .` (note).
- **Embedded repos.** EXP5 (cwd `$D/x`, 2026-09-29T04:01:17Z, exit 0): an embedded repo with `core.hooksPath .hk` makes a new standard worktree warn (status 1). The control without it gives status 0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:376-425`, `devcontainer-config/cc-exit-scan.sh:858`, `$D/bats-full.log`, `$D/experiments-exp5.log`

---

## Claim 12b: same sentence — "in any config the scan reads" as applied to your own global/system config

**Location:** `devcontainer-config/cc-exit-scan.sh:81-84`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers relative remotes and insteadOf bases in your own global config, which the scan does read (`_snap_host_config`). It does not concern `core.hooksPath` or `core.attributesFile` there: those are walked instead, per the parenthetical (Claim 13).

The scan reads your own config, but `_snap_host_config` follows only three kinds of key and creates no W record. Its `case` handles `core.hookspath`, `core.attributesfile` and `include.path|includeif.*.path` only (`:516-534`), which matches the header's own "Only those three kinds of entry are followed in your own config" (`:66`).

EXP2 (cwd `$D/x`, 2026-09-29T03:59:45Z, exit 0) sets global `url..insteadOf https://x.invalid/` or global `remote.loc.url ./sub.git`, then adds a new standard worktree. Result: status 0 and the note, in both host form and container form.

The pre-7c97a6b wording said "in repo config", which was accurate. The new "any config the scan reads" is broader than the code. The precise version is "in any repository config the scan reads (the checkout's, an embedded repo's, an include target in the checkout)".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:60-67`, `devcontainer-config/cc-exit-scan.sh:500-536`, `$D/experiments-exp2.log`

---

## Claim 13: "(Your own config's relative hooksPath is walked in each new worktree, including one whose .git names the container path, as `git worktree repair` would point it here; its records refuse the note too.)"

**Location:** `devcontainer-config/cc-exit-scan.sh:84-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a worktree found by the embedded `.git` search (`find -mindepth 2 -name .git` inside the checkout), in host form and container form. It does not establish a walk for worktrees outside the checkout, which are declined anyway.

- **The walk.** See Claim 2 for the code at `:718-721`.
- **The refusal.** The new test at `:2263-2279` asserts a warning that lists `$STD_WT/.githooks/pre-commit`.
- **The repair target.** The test's assertion `[ "$(cat "$STD_WT/.git")" = "gitdir: $STD_P" ]` confirms that repair points the `.git` at the host twin.
- **Without a planted hook.** EXP2 shows status 1 in both forms (Claim 10).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:714-723`, `test/cc-isolated-functions.bats:2263-2279`, `$D/experiments-exp2.log`

---

## Claim 14: "(_snap_hash_str, _snap_file_is and _snap_unq, further down, are silent helpers of scan_std_worktrees, which declares the _snap_bytes they need.)"

**Location:** `devcontainer-config/cc-exit-scan.sh:150-151`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the callers of these three helpers and which of them reads `_snap_bytes`. It does not establish silence on every error path of `sha256sum`: `_snap_hash_str` does not redirect stderr, though it has no read error to print.

- **Callers.** All three are called only from `scan_std_worktrees` (`:882`, `:902-903`, `:914`, `:924`, `:932`, `:948-950`) and from tests. A grep over `.sh` and `.bats` finds no other callers.
- **Who needs `_snap_bytes`.** Only `_snap_file_is` does, through `_snap_size_ok "$1" 2>/dev/null` (`:824`), and `_snap_size_ok` updates `_snap_bytes=$((_snap_bytes + s))` (`:196`). `_snap_hash_str` (`:797-801`) and `_snap_unq` (`:807-817`) never touch it.

"The `_snap_bytes` they need" reads as all three needing it. The precise version is "which declares the `_snap_bytes` that `_snap_file_is` needs".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:188-202`, `devcontainer-config/cc-exit-scan.sh:797-827`

---

## Claim 15: "_snap_container_target <path of a .git file>: for "gitdir: <container ws>/<rel>" (git in the container wrote it; GIT_EXIT_SCAN_CONTAINER_WS) naming nothing here, the host twin <ws>/<rel> if it is a dir, else nothing. Host git stops at such a file, but `git worktree repair` rewrites it to that twin."

**Location:** `devcontainer-config/cc-exit-scan.sh:555-558`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mapping and the repair behavior. The function does not itself check "naming nothing here". Its only caller (`:720`) enforces that by calling it only when `_snap_dotgit_target` returned nothing. It also returns nothing for a symlinked `.git`.

```bash
# devcontainer-config/cc-exit-scan.sh:559-567
_snap_container_target() {
  local line g
  [ -f "$1" ] && [ ! -L "$1" ] || return 0
  line="$(_snap_first_line "$1")" || return 1
  case "$line" in "gitdir: $GIT_EXIT_SCAN_CONTAINER_WS"/?*) ;; *) return 0 ;; esac
  g="$_snap_ws/${line#"gitdir: $GIT_EXIT_SCAN_CONTAINER_WS"/}"
  [ -d "$g" ] || return 0
  (cd "$g" 2>/dev/null && pwd -P) || true
}
```

The only caller is `:720`. EXP3 shows that "host git stops" (`fatal: not a git repository`, status 128) and that repair rewrites the file to the host twin.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:555-567`, `devcontainer-config/cc-exit-scan.sh:720`, `$D/experiments.log`

---

## Claim 16: "_snap_unq <%q string>: prints the string printf %q quoted, for its backslash form only ($'…' and '…' forms return 1; only those can end in a newline, which $(…) would drop). The result is checked by quoting it again, so a wrong decode declines instead of passing."

**Location:** `devcontainer-config/cc-exit-scan.sh:803-806`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the forms bash 5.2.15's `printf %q` emits and the re-quote guard. It does not establish the output of other bash versions' `%q`.

The guard: `case "$q" in \$\'*|\'*|"") return 1 ;; esac … [ "$(printf '%q' "$s")" = "$q" ] || return 1` (`:809`, `:815`). On bash 5.2.15, `printf %q` of the samples `""`, `a\n`, `a b`, `é`, `~x` and `a\tb` gives `''`, `$'a\n'`, `a\ b`, `$'\303\251'`, `\~x` and `$'a\tb'`. So:

- A trailing newline always yields the `$'…'` form.
- The `'…'` form appears only for the empty string.
- The backslash form cannot end in a newline, so `$(…)` loses nothing.

The re-quote mutation fails a test (Claim 7).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:807-817`, `$D/mut-requote.log`, `test/cc-isolated-functions.bats:2355-2364`

---

## Claim 17: "Removed <n>: gone hooksdir P/hooks missing and commondir-file P/commondir of exactly "../..\n", P gone on disk, one gone dotgit record that held exactly "gitdir: P\n" (either form), and at that record's path no .git and a directory (the old working tree) gone or not a git dir (looks_like_gitdir)."

**Location:** `devcontainer-config/cc-exit-scan.sh:834-838`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removal branch from `:884` to `:920`. "Either form" applies only when the common dir is inside the checkout (`ccommon` set). It does not establish anything about paths whose `%q` is not the backslash form: those decline (Claim 18).

- **The records.** The commondir attrs regex `^file [0-7]+ $std$` (`:893-894`) and the paired hooksdir record `hk` (`:895-896`) cover "exactly `../..\n`" and "hooksdir P/hooks missing".
- **The disk checks.** `[ ! -e "$p" ] && [ ! -L "$p" ]` (`:899`). The content pairing uses `re="^file [0-7]+ ($h${g:+|$g})\$"` over unused `-` dotgit records (`:902-909`). Then the checks at `:916` and `:918` (quoted in Claim 3).
- **`looks_like_gitdir`.** It is `{ [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]` (`devcontainer-config/cc-gitdir.sh:87-90`). It is false for a directory that is gone.
- **Tests.** The two mutations in Claim 7 and the 173/173 run.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:884-921`, `devcontainer-config/cc-gitdir.sh:87-90`, `$D/bats-full.log`

---

## Claim 18: "It also declines <n> of . or .., a back-pointer over 4097 bytes, a <rel> with ., .. or empty parts, a working tree inside the common dir, and the container form when the common dir is outside the checkout. Added paths are compared as the %q strings the records hold, recomputed; a removal decodes only its dotgit path (_snap_unq)."

**Location:** `devcontainer-config/cc-exit-scan.sh:845-849`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed decline, found in the code. The list is not exhaustive: the check that the exit snapshot's commondir record matches (`:863-864`) and the `_snap_unq` decline are also in the code. The sentence says "also declines", not "only".

Each decline is in the code:

- `<n>` of `.` or `..`: `[ "$n" != . ] && [ "$n" != .. ] || return 1` (`:890`)
- over 4097 bytes: `[ "$(stat -c %s …)" -le 4097 ] || return 1` (`:930`)
- `.`, `..` or empty parts: `case "/$wtrel/" in */../*|*/./*|*//*) return 1` (`:939`)
- working tree inside the common dir: `case "$wt/" in "$common"/*) return 1` (`:941`)
- container form with the common dir outside the checkout: `"$cws"/?*/.git) [ -n "$ccommon" ] || return 1` (`:935`), and the `.git` candidates list `${ccommon:+…}` only (`:947`)

Added paths are compared through `printf '%q'` recomputation (`:892`, `:895`, `:943`). The only `_snap_unq` call is `:914`, in the removal branch.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:863-959`

---

## Claim 19: "# _snap_bytes: _snap_size_ok's running total (unset under set -u otherwise)."

**Location:** `devcontainer-config/cc-exit-scan.sh:852`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the need for the local under `set -u`. It does not establish whether any other caller of `_snap_size_ok` lacks the declaration: `git_exec_snapshot` declares its own at `:676`.

`_snap_size_ok` does `_snap_bytes=$((_snap_bytes + s))` (`:196`). The launcher runs `set -euo pipefail` (`devcontainer-config/cc-isolated.sh:66`). `bash -uc 'x=$((y+1)); echo ok'` prints `y: unbound variable`, so without the local the arithmetic would abort under `set -u`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:196`, `devcontainer-config/cc-exit-scan.sh:853`, `devcontainer-config/cc-isolated.sh:66`

---

## Claim 20: "The old working tree, if still there, must not look like a git dir, nor hold a .git (one behind a symlinked parent makes no record): a repository left in its place is not "removed"."

**Location:** `devcontainer-config/cc-exit-scan.sh:910-912`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3: covers the symlinked-parent route and the `looks_like_gitdir` check.

See Claim 3 for the code at `:914-918` and the old-.git mutation. The looks_like_gitdir mutation also fails a test (Claim 7).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:910-918`, `$D/mut-old-dotgit.log`, `$D/mut-looks-like.log`

---

## Claim 21: note text "Removed ones' git dir and .git file are gone[, and added ones take config and hooks from the checkout's own .git]"

**Location:** `devcontainer-config/cc-exit-scan.sh:966-971`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the user-facing string and both of its variants, as the tests assert them. The match between the string and the checks is Claim 4.

The code sets `why="Removed ones' git dir and .git file are gone"` (removed only) and `why="Removed ones' git dir and .git file are gone, and added ones take config and hooks from the checkout's own .git"` (added and removed) (`:968-969`). The tests assert both verbatim (`test/cc-isolated-functions.bats:2293`, `:2317`) and passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:966-971`, `test/cc-isolated-functions.bats:2293`, `test/cc-isolated-functions.bats:2317`, `$D/bats-full.log`

---

## Claim 22: "The acceptance lives inside git_exit_scan and returns 0, so cc-isolated.sh's logic does not change (only its --help exit-status text)."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dfe4c0d..31baaba diff of `cc-isolated.sh`. It does not establish anything about 7c97a6b, which does not touch the file.

The whole diff is a header-comment change: `+#   0  success; after a session: the exit scan found nothing (or only standard` / `+#      linked worktrees, with a note on stderr)`. `usage()` prints that header: `awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"` (`devcontainer-config/cc-isolated.sh:567`).

**Evidence:** `devcontainer-config/cc-isolated.sh:16-22`, `devcontainer-config/cc-isolated.sh:566-567`

---

## Claim 23: "the code also declines shapes this list does not spell out: <n> of . or .., a back-pointer over 4097 bytes, a <rel> with ., .. or empty parts, a working tree inside the common dir, and the container form when the common dir is outside the checkout … (each only narrows what passes)."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers unit A's code at 31baaba, where the same five checks exist, and unit B's code, which is unchanged for these checks (Claim 18).

In A: `[ "$n" != . ] && [ "$n" != .. ]` (`:845`), `-le 4097` (`:861`), `[ -n "$ccommon" ] || return 1` (`:866`), `*/../*|*/./*|*//*` (`:870`) and `"$common"/*) return 1` (`:872`). Each is a `return 1`, so each only narrows what passes.

**Evidence:** `31baaba:devcontainer-config/cc-exit-scan.sh:845-872`

---

## Claim 24: "this unit came to 447 lines with it, a count taken before the split and never committed"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:61`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** The count describes a working tree that was never committed. It cannot be reconstructed from git history.

paraphrased — no quote available because the claim is about an uncommitted state that no commit or file records. To verify it, one would need the pre-split working tree or a log of the count command.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:61`

---

## Claim 25: B13 — "Rule 3 (W from _snap_remote; for an insteadOf base of . or "", from _snap_config)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:86`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the W records originate. It does not re-verify the refusal, which is Claim 12a.

- **Bases `.` and `""`.** `_snap_config` handles them with `case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac` (`:421`). For these two, `_snap_remote` itself returns early for `""` (`:353`) and exempts `.` (`:361`).
- **Other relative bases.** `pushDefault` and `branch.*.remote` paths, and the legacy files, reach `_snap_wrel` through `_snap_remote` (`:361`, `:626`, `:629`, `:731`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:350-373`, `devcontainer-config/cc-exit-scan.sh:418-422`

---

## Claim 26: B14 — "open in this unit; fixed in the stacked unit … host git in it stops (E10), but only until `git worktree repair` … rewrites .git to the host path; then a hook planted under your relative hooksPath runs … This unit sits at the row-62 size cap (399 lines) … There, _snap_container_target maps a container-form .git to its host twin and _snap_host_config walks it, at launch and at exit; a planted hook is a new record (test "YOUR relative hooksPath is walked in a container-form worktree too")"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:87`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "open in A" (A lacks the fallback), "stops", "repair then runs", the 399 count, the fix, and that the test exists. It does not cover `includeIf gitdir:` conditions in a container-form worktree beyond what `_snap_host_config` does for the mapped git dir.

- **Open in A.** A has no `_snap_container_target` (grep at 31baaba finds none).
- **Stops, then runs after repair.** EXP3.
- **399.** Claim 1.
- **The fix and the test.** Claim 2. The test name matches `test/cc-isolated-functions.bats:2263`, "exit scan Q-094: YOUR relative hooksPath is walked in a container-form worktree too".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:714-723`, `test/cc-isolated-functions.bats:2263-2279`, `$D/experiments.log`, `$D/git-counts.log`

---

## Claim 27: B15 — "`.gitmodules` `update=!cmd` is rejected by git, `fatal: invalid value`"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `submodule update --init` with `update = !cmd` only in `.gitmodules`. It does not cover `update` set in `.git/config`, which the scan records.

EXP4 (cwd `$D/x`, 2026-09-29T03:59:34Z, exit 0): `git submodule update --init` exits 128 with `fatal: invalid value for 'submodule.sub.update'`, and no marker was written.

**Evidence:** `$D/experiments.log`

---

## Claim 28: B18 — "added paths are compared as the %q string recomputed from the parsed name, never unquoted. The stacked unit's removal decodes one path, the removed dotgit record's, with _snap_unq (backslash form only, checked by quoting it again; $'…' paths warn)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:91`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comparison mechanism for added records and the removal decode. It does not re-verify the `$'…'` removal decline, which the test at `:2344-2352` covers and which passed.

"Never unquoted" and the removal part are correct: the only `_snap_unq` call is at `:914`.

"Recomputed from the parsed name" is imprecise. The commondir and hooksdir paths are recomputed from `<n>` (`:891-895`), but the added `dotgit` key is recomputed from the back-pointer's `<rel>`:

```bash
# devcontainer-config/cc-exit-scan.sh:940-943
    wt="$wsp/$wtrel"
    case "$wt/" in "$common"/*) return 1 ;; esac
    # Its `.git` file: a new record, and the bytes git writes, then and now.
    dk="${dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]:-}"
```

The code comment dropped "from <n>" in this commit (`:848-849`, "recomputed"). The precise version is "recomputed from `<n>` and the back-pointer".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:884-959`

---

## Claim 29: B21 — "Here, any removal warns. In the stacked unit, rule 6 requires P gone on disk."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A's diff filter and B's `P` check.

- **A.** The filter admits only `+` records: `+F$'\t'dotgit$'\t'*)` and `+F$'\t'commondir-file…|+F$'\t'hooksdir…`, with everything else `return 1` (31baaba `:831-833`). A's test "a worktree removed during the session still warns" is at 31baaba `test/…:2263`.
- **B.** `[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`:899`).

**Evidence:** `31baaba:devcontainer-config/cc-exit-scan.sh:826-835`, `devcontainer-config/cc-exit-scan.sh:899`

---

## Claim 30: B28 — "the invalid check has no pipefail test of its own (functional tests exercise it)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:101`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tests of the `invalid` check. It does not establish their coverage under pipefail.

- **Functional tests.** Tests at `test/cc-isolated-functions.bats:1344`, `:1355` and `:1439` assert `! $SCAN_WS/.git is not a valid git directory now` and `gitdir-valid … invalid`.
- **Pipefail.** The only pipefail test (`:2380`) calls `scan_std_worktrees`, not `git_exit_scan`.

**Evidence:** `test/cc-isolated-functions.bats:1344-1362`, `test/cc-isolated-functions.bats:2380-2393`

---

## Claim 31: Steps 2 and 3 — "guides/cc-isolated-usage.md: exit-status and tripwire sections, the note; in the Q-094 paragraph, the B12 cost and the cases that still warn; in Known routes, the insteadOf item." / "test/…: new standard (host form and container form) → 0 + note; removed → 1 …; pipefail …; non-standard variants (…) → 1 (removal cases are in the stacked unit); standard + plant → 1 …; launcher maps to claude's status."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:110-111`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A's guide and test diffs (dfe4c0d..31baaba) against the listed items. It does not re-verify that each test asserts what its name says.

- **Guide.** A's diff changes the exit-status text ("a note about standard worktrees is not one") and adds the Q-094 paragraph, which includes the relative hooksPath cost and the warn cases. It also adds the Known routes item "A URL rewritten by `url.<base>.insteadOf`".
- **Tests.** A's Q-094 tests are at `:2227`, `:2243`, `:2263` (removed warns), `:2273` (pipefail), `:2288`, `:2315`, `:2344`, `:2367` and `:2386` (launcher). Together they cover every listed variant.

**Evidence:** `31baaba:test/cc-isolated-functions.bats:2227-2400`, `git diff dfe4c0d 31baaba -- guides`

---

## Claim 32a: "This unit sits at the size cap (399 changed code lines outside docs/), so every code, comment and guide fix from its final review lands in the stacked unit …; only this plan changed here. The two units merge together."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:114`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 399 and "only this plan changed". "Merge together" is intent, not checkable.

See Claim 1 for the 399 count. 31baaba's stat shows one file, the plan.

**Evidence:** `$D/git-counts.log`

---

## Claim 32b: "Rubric: docs/reviews/code-review-rubric-2026-09-28-q094-final-A.md."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:114`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the file exists in any commit or in the worktree. It does not establish whether the parent plans to write it before merge.

`git log --all --oneline -- docs/reviews/code-review-rubric-2026-09-28-q094-final-A.md` returns nothing: the path was never committed on any ref. It is also absent from 31baaba's and 7c97a6b's `docs/reviews/` and from the worktree. The only Q-094 rubric in the tree is `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md`. The final-pass review files exist only in the session scratchpad (`…/scratchpad/reviews/A-*-final.md`). A reader following the link finds nothing.

**Evidence:** `$D/git-counts.log`

---

## Claim 33: "the scan prints one `note: …(added: agent-x) …` line (or `removed: …`, or `added: …; removed: …`)"

**Location:** `guides/cc-isolated-usage.md:337-339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three note forms.

The forms are built at `:964-965`, ending in `line="${line:+${line% }; }removed: …"`. The test at `:2289` and `:2293` asserts `(removed: agent-y).` and `(added: agent-z; removed: agent-y).`, and it passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:963-971`, `test/cc-isolated-functions.bats:2281-2306`

---

## Claim 34: "For a removal, "exact" means the private dir is gone and the removed records are the ones git's layout makes (the `.git` file named that dir), nothing is at the old `.git` path, and the old working-tree directory is gone or does not look like a git dir (no `HEAD` next to `objects/`, no `commondir` file)."

**Location:** `guides/cc-isolated-usage.md:342-345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same coverage as Claim 17, plus the `looks_like_gitdir` definition behind the parenthetical.

The parenthetical matches `looks_like_gitdir` (`devcontainer-config/cc-gitdir.sh:89`, quoted in Claim 17).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:898-920`, `devcontainer-config/cc-gitdir.sh:87-90`

---

## Claim 35a: "A working-tree path with a tab … or other byte that bash's `%q` quotes as `$'…'` is a note when added but warns when removed."

**Location:** `guides/cc-isolated-usage.md:345-347`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tab case (run). The case of other bytes rests on static reading (Claim 9a).

EXP1 gives TAB-ADD status 0 with the note, and TAB-REMOVE status 1.

**Evidence:** `$D/experiments.log`

---

## Claim 35b: same sentence — a working-tree path with a **newline** "is a note when added"

**Location:** `guides/cc-isolated-usage.md:346-347`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an added worktree whose path contains a newline.

EXP1 (cwd `$D/x`, 2026-09-29T03:59:34Z) prints `NL-ADD status=1`: the warning, not the note. The reason is that the back-pointer is read as one line (`line="$(_snap_first_line "$p/gitdir" …)"`, `:931`) and then re-hashed against the whole file (`:932`), which fails.

7c97a6b's own commit Notes say "(only a newline declines on add)", which contradicts this guide sentence. The precise version: "A working-tree path with a newline warns either way. A tab or other byte that `%q` quotes as `$'…'` is a note when added but warns when removed."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:929-932`, `$D/experiments.log`

---

## Claim 36: "(a remote of `.` is fine; an `insteadOf` base of `.` or `""` is not), which git would resolve in the new worktree's tree, unscanned."

**Location:** `guides/cc-isolated-usage.md:357-359`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checkout config, as the sentence says ("any checkout whose config"). Unlike the code header (Claim 12b), the guide makes no claim about your own config here.

The test at `:2474-2491` covers `branch.main.remote .` (note), `url...insteadOf` (warn), `url..insteadOf` (warn) and `url..pushInsteadOf` (warn). It passed in the 173/173 run.

**Evidence:** `test/cc-isolated-functions.bats:2474-2491`, `$D/bats-full.log`

---

## Claim 37: "That includes the config of any repo embedded in the checkout."

**Location:** `guides/cc-isolated-usage.md:359-360`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an embedded repo with a relative `core.hooksPath`. Other keys follow the same `_snap_config` path but were not run.

EXP5 gives status 1 with the relative hooksPath and status 0 in the control without it. Embedded repos' configs go through `_snap_dotgit` → `_snap_gitdir` → `_snap_config` (`:717`, `:596-598`).

**Evidence:** `$D/experiments-exp5.log`, `devcontainer-config/cc-exit-scan.sh:596-599`, `devcontainer-config/cc-exit-scan.sh:714-722`

---

## Claim 38: "A relative `core.hooksPath` or `core.attributesFile` in your own config is walked in each new worktree, also one whose `.git` names the container's `/workspace/…` path (as `git worktree repair` would point it here), so its paths refuse the note too."

**Location:** `guides/cc-isolated-usage.md:360-363`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both keys in both forms. The paths must resolve inside the checkout (`_snap_inside_ws`, `:519`, `:522`).

EXP2 gives status 1 for `core.hooksPath` and `core.attributesFile` in both host form and container form.

**Evidence:** `$D/experiments-exp2.log`, `devcontainer-config/cc-exit-scan.sh:516-522`

---

## Claim 39: "its tracked files are not scanned, only its layout"

**Location:** `guides/cc-isolated-usage.md:378`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the worktree walk. It does not concern files a config value names, which are walked.

In a working tree, the scan runs only `_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git` (`:712`). It records `.git` entries, never tracked files.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:709-723`

---

## Claim 40: "The embedded-repo search does not follow symlinked directories, so a link in the working tree to a repository outside the checkout … is not walked; host git run through that link would use the repository behind it. (A removed worktree's old `.git` path is checked directly, so the note is refused there.)"

**Location:** `guides/cc-isolated-usage.md:410-415`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `find -P` and the removal check. It does not establish the example "somewhere the container can write, such as a rootless-Docker volume", which is about deployment and cannot be checked here.

- **The search.** `find -P "$@" -print0` (`:275`).
- **The parenthetical.** Claim 3 (test `:2331-2340` plus the mutation).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:273-279`, `$D/mut-old-dotgit.log`

---

## Claim 41: test name "exit scan Q-094: YOUR relative hooksPath is walked in a container-form worktree too"

**Location:** `test/cc-isolated-functions.bats:2263-2279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name against the assertions: a warning, the hook listed, and the repair target. It does not assert that the hook runs after repair; EXP3 covers that.

The test sets global `core.hooksPath .githooks`, writes the container form, plants the hook, and asserts `warns_listing_wt` plus `*"$STD_WT/.githooks/pre-commit"*`. It passed, and it failed under the container-walk mutation.

**Evidence:** `$D/bats-full.log`, `$D/mut-container-walk.log`

---

## Claim 42: test comment "Its parent swapped for a link to a dir outside the checkout that holds a repo at the old path: find records nothing there, the .git check warns."

**Location:** `test/cc-isolated-functions.bats:2331-2332`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3.

The old-.git mutation fails exactly at `:2338` in this block.

**Evidence:** `$D/mut-old-dotgit.log`

---

## Claim 43: test name "_snap_unq: inverts printf %q's backslash form; other forms decline"

**Location:** `test/cc-isolated-functions.bats:2355-2364`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 7 round-trip samples plus a `$'…'`, a `''` and a malformed `a\` input. The last is not a `%q` form: it exercises the re-quote guard, whose mutation it catches.

The test compares `[ "$(_snap_unq "$(printf '%q' "$s")")" = "$s" ]` for each sample, and `run !` for the three decline inputs (Bats 1.8.2 supports `run !`). It passed, and it failed under the re-quote mutation.

**Evidence:** `$D/bats-full.log`, `$D/mut-requote.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12b** (`devcontainer-config/cc-exit-scan.sh:81-84`): "in any config the scan reads … leave W records" is wrong for your own global/system config. A relative remote or an insteadOf base of `.` there makes no W record, and a new worktree still gets the note (EXP2). Restore "repository config", or name the configs `_snap_config` reads.
- **Claim 32b** (`docs/working/plan-q094-exit-scan-worktree-layout.md:114`): the rubric path `docs/reviews/code-review-rubric-2026-09-28-q094-final-A.md` does not exist in any commit or in the worktree.
- **Claim 35b** (`guides/cc-isolated-usage.md:345-347`): a newline path does not become a note when added. It warns (EXP1 NL-ADD status 1), as the commit's own Notes say. Drop "newline" from the "note when added" list.

### Stale
- none

### Mostly Accurate
- **Claim 9b** (`git show 7c97a6b`, Notes): "2eebdf8" is not an ancestor of 7c97a6b. The in-branch commit with that note is a7e9b7a.
- **Claim 14** (`devcontainer-config/cc-exit-scan.sh:150-151`): only `_snap_file_is` needs `_snap_bytes`. `_snap_hash_str` and `_snap_unq` do not.
- **Claim 28** (`docs/working/plan-q094-exit-scan-worktree-layout.md:91`): the added `dotgit` path is recomputed from the back-pointer's `<rel>`, not from the parsed name.

### Unverifiable
- **Claim 24** (`docs/working/plan-q094-exit-scan-worktree-layout.md:61`): the 447-line count was never committed, so it could only be checked against the pre-split working tree.

## Goal-Alignment Note

The goal was to confirm that the final-pass fix commits are accurate before the parent merges A+B.

**The two security fixes hold under execution.**
- A's container-form hooksPath walk: the pre-fix gap was reproduced by mutation, and the post-repair hook execution was reproduced by EXP3.
- B's old-`.git` check: its mutation fails at the symlinked-parent case.
- All four claimed mutations fail a test, the suite is 173/173, and the 399/267 counts and the timing claim check out.

**The three Incorrect findings are documentation-only; none is a code defect.**
- 12b: a header overstatement that a reader could act on by assuming their own global insteadOf/remote refuses the note.
- 35b: a guide sentence that contradicts the commit's own Notes.
- 32b: a dangling rubric link in the plan. It may simply be written later in the pr-prep flow; if so, it only needs to exist before merge.

None of the three changes what the scan does. They matter only for merge hygiene, since 12b and 35b sit in the merged guide/header that users read.
