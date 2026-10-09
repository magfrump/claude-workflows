Commit: e02d056b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1b (branch feat/build-loop-u2b1b, HEAD e02d056b)
**Scope:** The five endorsement claims marked `route: code-fact-check` in `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b1b-final.md:134-169` (submitting critic: security-reviewer). Subject code: `scripts/build-loop.sh`. Nothing else in the diff is verdicted.
**Checked:** 2026-10-08
**Total claims checked:** 6 (five submitted claims; claim 72 split into 72a and 72b on verdict divergence)
**Summary:** 5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance, common to every `executed` claim below. Probe scripts and their captured output live in the agent's scratch directory, `/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-sub/` (written as `fc-sub/` below). Each probe was run as `timeout 300 bash pNN.sh > pNN.log 2>&1` from `fc-sub/`, and every final run exited 0. Each probe sources `fc-sub/lib.bash`, which starts with `set -eu`, creates its own `mktemp -d -p fc-sub` directory, `cd`s into it, refuses `git init` outside it, unsets git's local env variables, and sets `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 HOME=<tmp>/home LC_ALL=C`. Inside each fixture repo the probe runs `bash <worktree>/scripts/build-loop.sh --check BRIEF`. Each run's log records the fixture cwd, a UTC timestamp (2026-10-08T22:39Z to 22:43Z), the command and its exit code. git 2.39.5. The worktree's `test/scripts/build-loop-check.bats` already had uncommitted changes, not made by this agent, before any run here (mtime 22:38:14Z). They change one comment in the R6 test and the A15 test. The bats run cited below used that working copy, but none of the tests it selected (R6, R7, R9, A17, the U2b1a i2 tests and checkout attributes) has a changed assertion. No process outlives its probe: every script ran under `timeout` and none starts a background job. The worktree was not modified.

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read. No claim below matches a logged pattern.

---

## Submitted Claims

## Claim 72a: "A missing main ... tree ... makes `--check` refuse the brief (exit 2) rather than print ok."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:520-530`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a branch whose main commit's root tree object is deleted from the loose store: `--check` exits 2 and prints no ok line. It does not establish that merge_result's own main-tree test (`:525`) is ever what refuses: in this shape the brief read fails first, and the line is a `skip`, not a `refuse`. It also does not cover a packed-object store or a main tree that is corrupt but present.

The outcome holds: exit 2 and no ok line. The line kind and the code path differ from the claim. Probe 72a (`fc-sub/p72.log`, fixture `.../a`) deleted `main^{tree}` and got:

```
exit 2
fatal: unable to read tree (144083eb8cb629cedc9e891c7db0b24274953ed0)
skip docs/working/briefs/2026-10-01-x.md: the tree of the default branch could not be read
```

That is `status_line`'s skip, which `check_line` passes through before it reaches merge_result:

```bash
# scripts/build-loop.sh:581-582
  out="$(status_line "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
```

The main loop counts any line that is not ok as a failure. It does so here:

```bash
# scripts/build-loop.sh:646-649
      out="$(check_line "$a")"; printf '%s\n' "$out"
      [[ "$out" == "ok "* ]] || fails=1
    done
    [[ "$fails" -eq 0 ]] || exit 2
```

The brief is read from main's tree, so a missing main root tree always fails at that read before merge_result runs. Its `cat-file -e "$MAIN_SHA^{tree}"` at `:525` is therefore defence in depth on this path (paraphrased — no quote available because this is an inference that `check_brief`/`main_entry` in `scripts/lib/dev-cycle-read.sh` must read main's root tree to find the brief, drawn from the probe's `skip ... tree of the default branch could not be read` message). A reader who expects a `refuse` line for this case will see `skip` instead. Exit 2 and the absence of an ok line are as claimed. The lib's `fatal:` stderr line also reaches the output; that is outside this claim.

**Evidence:** `scripts/build-loop.sh:520-530`, `scripts/build-loop.sh:579-582`, `scripts/build-loop.sh:644-649`, fixture `fc-sub/p72.sh`, captured output `fc-sub/p72.log` (case "72a main tree missing")

---

## Claim 72b: "A missing ... tip or merge-base tree, any stderr from a gate git call, or a new regular file whose blob is absent or not a blob makes `--check` refuse the brief (exit 2) rather than print ok."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:510-530`, `scripts/build-loop.sh:599-618`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following, each executed: a deleted tip tree; a deleted merge-base tree; a stderr line injected into each of the six gate git calls (merge-base `:522`, cat-file -e `:525`, merge-tree `:526`, hash-object `:542`, diff-tree `:599`, cat-file --batch-check `:615`); an added (A) and a changed (M) 100644 entry whose blob is absent; a 100644 entry naming a tree; a 100755 entry naming a commit. Each refuses with exit 2. It does not establish the security-reviewer's own Not-verified case (a corrupt, present blob at an unchanged path), packed-object stores, or that every refusal message names the true cause: stderr from the batch-check reads "names a blob the object store lacks", and stderr from hash-object surfaces as a deny row.

The mechanism, quoted. gate_git turns any stderr into status 3:

```bash
# scripts/build-loop.sh:510-515
gate_git() {
  local rc=0
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
  return "$rc"
}
```

merge_result returns 2 for any of those statuses, and for a missing tree among main, tip and every merge base:

```bash
# scripts/build-loop.sh:522-529 (enclosing merge_result() spans :520-530 — read)
  bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 ]] || return 2
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
```

`check_line` maps that return to a refuse line (`:591-596`), as it does a diff-tree failure (`:599-601`). Blob presence is checked only for new modes 100644 or 100755:

```bash
# scripts/build-loop.sh:606
    [[ "${nms[-1]}" != 100644 && "${nms[-1]}" != 100755 ]] || ids+=("${nos[-1]}")
# scripts/build-loop.sh:615-618
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
  fi
```

(`check_line` spans `:579-628` — read.) Executed results, all exit 2 with no ok line (`fc-sub/p72.log`, plus the first case of `fc-sub/p73.log`):

- tip tree deleted: `refuse ...: the merge of feat/x could not be computed`
- merge-base tree deleted: the same refuse line
- stderr injected (a PATH shim that writes one stderr line only when `GIT_DIR=*/git`):
  - merge-base, cat-file -e, merge-tree: `could not be computed`
  - diff-tree: `the paths the merge of feat/x changes could not be listed`
  - `--batch-check` alone: `names a blob the object store lacks`
  - hash-object: `1 of 1 changed paths refused ... deny ... this brief: ...`
- A entry with absent blob, M entry with absent blob, 100644 naming a tree, 100755 naming a commit (written with `hash-object -t tree --literally`): `refuse ...: the merge of feat/x names a blob the object store lacks`

A control run with no fault prints `ok` and exits 0. A second control, the honest own-brief edit without the shim, also exits 0.

**Evidence:** `scripts/build-loop.sh:510-530`, `scripts/build-loop.sh:579-628`, fixtures `fc-sub/p72.sh`, `fc-sub/p73.sh`, captured output `fc-sub/p72.log`, `fc-sub/p73.log` (case "72d stderr from gate cat-file --batch-check only"); the R6 bats test also passes (`fc-sub/bats.log`, ok 5)

---

## Claim 73: "Under both policies the brief's own file passes only as an `M` record with equal old and new modes whose new blob id equals main's copy with its first unfenced `Status: open` line rewritten to `Status: done` (CR kept)."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:558-560`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the own-brief arm of `nrules`, executed under both review and self-merge policy. It passes: the honest edit (LF, CRLF, and a 100755 brief keeping its mode), and an unchanged brief (no record). It denies: a fenced Status line changed; a second unfenced Status line changed, alone or with the first; open→dropped; "done " with a trailing blank; lower-cased "status: done"; an exec bit added; an exec bit dropped; another line changed; a trailing CR added; a dropped CRLF CR; deletion; replacement by a symlink (denied by the mode rule first). It does not establish behaviour when `brief_fields` and `own_blob` disagree on which line is the first Status line (security-reviewer's Not-verified item). It also does not establish that the brief path diff-tree reports always byte-equals the argument spelling `$1`: a case or `./` variant of the argument was not probed.

The rule, quoted:

```bash
# scripts/build-loop.sh:558-560 (enclosing nrules() spans :553-572 — read)
  elif [[ "$6" == "$1" ]]; then
    { [[ "$5" == M && "$2" == "$3" ]] && ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]; } \
      || DENY="this brief: only its first Status: line outside a fence may change, from open to done"
```

The pathform and mode arms come first (`:556-557`), so a T record never reaches this arm. own_blob finds the first unfenced `^Status:` line, rewrites only that line number, keeps an optional CR, and hashes the result in the gate repository:

```bash
# scripts/build-loop.sh:540-542 (enclosing own_blob() spans :536-543 — read)
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1
  [[ "$n" -gt 0 ]] || return 1
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
```

Executed (`fc-sub/p73.log`). The honest edit gives exit 0 with `path ... M <brief>`. It also passes alongside another file's change, and an unchanged brief passes with only the other path listed. CRLF with the CR kept: exit 0; with the CR dropped: deny. A 100755 brief edited honestly: exit 0; with its mode dropped: deny. Self-merge policy (`--settings` prints `policy self-merge set`): honest edit exit 0; extra line deny. Every other variant listed in Scope prints `deny ... this brief: only its first Status: line outside a fence may change, from open to done`, or, for the symlink, the mode deny, with exit 2.

**Evidence:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:553-572`, fixture `fc-sub/p73.sh`, captured output `fc-sub/p73.log`

---

## Claim 74: "A record with mode other than 000000/100644/100755 on either side (symlink, gitlink, tree-typed entry) is denied, including a gitlink that `submodule.<name>.ignore=all` in repo config and `.gitmodules` would hide from diff-tree in the real repository."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:557`, `scripts/build-loop.sh:599`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these records as diff-tree prints them: symlink added, deleted, symlink→file, file→symlink; gitlink added, moved, and gitlink→file, each with `ignore = all` in both `.gitmodules` and repo config. Each is denied, and a control shows real-repo `git diff-tree` printing nothing for the added and the moved gitlink. It does not establish a denial for a raw non-canonical regular mode such as 100664. git reads that mode as 100644, so no such record ever appears and the path passes (see below). A tree-typed (040000) record cannot appear under `-r` and was not constructed.

The rule and the diff-tree call:

```bash
# scripts/build-loop.sh:557
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="a symlink, gitlink or other non-file entry on one side (only modes 100644 and 100755 land)"
# scripts/build-loop.sh:599
  if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree" > "$GATE_TMP/diff"; then
```

Executed (`fc-sub/p74.log`):

- Each symlink shape is denied: `deny ... A link`, `D was-link`, `T was-link`, `T f.txt`.
- With `ignore = all` set, real-repo `git diff-tree -r --no-renames --raw main <merge>` printed nothing (`(end; exit 0)`), and so did real-repo `git diff-tree -r main feat/x` for the moved gitlink.
- The gate still printed `deny ... A gl`, `deny ... M gl` and `deny ... T gl`, each with exit 2.

The reviewer's Not-verified expectation, that 100664 in main's old tree is "denied by the regex", is wrong, but harmlessly so. With 100664 on main's old side, real-repo `diff-tree` prints `:100644 100644 ... M g.txt` and the gate prints `ok` with `path ... M g.txt`. A branch tree whose raw bytes hold `100664 g.txt` also passes as `A g.txt`, and the gate's TREE stores the entry as `100644 g.txt` (`fc-sub/p74b.log`, raw tree bytes). git canonicalises the mode on read, and merge-tree writes the canonical mode, so no non-file mode lands. This is outside the claim, which is about records, and does not change the verdict.

**Evidence:** `scripts/build-loop.sh:553-572`, `scripts/build-loop.sh:599-606`, fixtures `fc-sub/p74.sh`, `fc-sub/p74b.sh`, captured output `fc-sub/p74.log`, `fc-sub/p74b.log`

---

## Claim 75: "No gate git call (`:522`, `:525`, `:526`, `:542`, `:599`, `:615`) reads the repository's config, config.worktree, info/attributes, checkout `.gitattributes`, `.git/modules/*`, global or system config, absent a writer racing GATE_TMP (R8)."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:188-198`, `scripts/build-loop.sh:497-515`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the gate_git invocations at the six listed sites, each executed under planted values in every named source. Each sees only the gate repository's two-line config plus harden's command-line pairs, and no attribute. A union merge driver planted in every attribute source does not turn a conflict clean, though the real repository merges the same pair cleanly. It does not establish:
- a syscall-level absence of reads (strace is not installed; the evidence is git's own `config --list --show-origin` and `check-attr -a` run in each call's exact environment and cwd, plus the behavioural union test);
- the non-gate git call that shares line `:542` (own_blob's `git cat-file blob`, run in the real repository) or any lib read, which do read repo config, hardened;
- caller-set `GIT_CONFIG_PARAMETERS`/`GIT_ATTR_SOURCE`, alternates/MIDX, or the R8 race (the reviewer's Not-verified items).

The construction, quoted. harden adds the config pairs and `:198` exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1`. gate_repo unsets every local env variable except `GIT_CONFIG*` and `GIT_NO_REPLACE_OBJECTS`, and points git at a fresh git dir and an empty cwd:

```bash
# scripts/build-loop.sh:500-505 (enclosing gate_repo() spans :497-506 — read)
  for v in $(git rev-parse --local-env-vars); do [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v"); done
  v="$(git rev-parse --path-format=absolute --git-path objects)" && fmt="$(git rev-parse --show-object-format)" \
    && [[ "$fmt" == sha1 || "$fmt" == sha256 ]] && mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work" || return 1
  printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"
  printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"
  GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")
```

Executed (`fc-sub/p75.log` conflict run, `fc-sub/p75b.log` clean run). Planted `user.planted` values:

- repo `.git/config`
- `.git/config.worktree`, with `extensions.worktreeConfig=true`
- `~/.gitconfig` and `~/.config/git/config`
- a caller `GIT_CONFIG_SYSTEM` file
- `.git/modules/sm/config`

Planted `*.txt merge=union`:

- `~/.config/git/attributes`
- an untracked checkout `.gitattributes`
- `.git/info/attributes`, written by the shim at the first gate call, after the state gate passed

Controls: real-repo `merge-tree` exits 0 (union applied), and real-repo `config` shows the global, repo and worktree values.

Results:

- 13 gate calls logged across the two runs; together they cover all six sites (merge-base, three `cat-file -e`, merge-tree, diff-tree, `cat-file --batch-check`, hash-object).
- Every call shows `ls GIT_DIR: HEAD config refs`, an empty cwd, `GIT_COMMON_DIR=unset` and `GIT_WORK_TREE=unset`.
- Config origins seen: only `file:/tmp/tmp.*/git/config` and `command line:`. `grep 'planted\|union'` over the call log finds nothing, and `check-attr -a f.txt` is empty at every call.
- The conflict run ends `refuse ...: feat/x conflicts with the default branch` (exit 2). The clean run ends `ok`.

The A17, U2b1a i2 submodule, checkout-attributes and R9 bats tests pass (`fc-sub/bats.log`, ok 1-3, 7). Confidence is Medium because the evidence is git's view of its environment rather than an open() trace.

**Evidence:** `scripts/build-loop.sh:188-198`, `scripts/build-loop.sh:497-515`, `scripts/build-loop.sh:520-543`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:615`, fixtures `fc-sub/p75.sh`, `fc-sub/p75b.sh`, captured output `fc-sub/p75.log`, `fc-sub/p75b.log`, `fc-sub/bats.log` (bats run 2026-10-08T22:42:35Z, `TMPDIR=$(mktemp -d -p fc-sub) bats -f '...' test/scripts/build-loop-check.bats` from the worktree, exit 0)

---

## Claim 76: "`--check` exits 2 before reading any brief when both `main` and `master` exist or origin/HEAD names a branch other than the one resolve_main took."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:241-251`, `scripts/build-loop.sh:260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these cases, each exiting 2 with only `refuse state default-branch` lines and no git call naming `briefs`:
- main+master with no origin/HEAD, with origin/HEAD→master, and with origin/HEAD→main;
- main only with origin/HEAD→origin/master;
- master only with origin/HEAD→origin/main;
- main plus a `master` ref naming a tree.

Controls that pass: main or master alone, with an agreeing or absent origin/HEAD. It does not establish behaviour for a symbolic `refs/heads/main` (the reviewer's Q-103 residual). It does not cover packed refs or an origin/HEAD naming a third branch; that case is state_gate's, at `:230-233`, not this claim's.

The function and its call position, quoted:

```bash
# scripts/build-loop.sh:241-251
default_gate() {
  local p bad=0
  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then
    echo "refuse state default-branch: both main and master exist"; bad=1
  fi
  p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || true
  if [[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]; then
    echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"; bad=1
  fi
  return "$bad"
}
# scripts/build-loop.sh:257-260
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
if [[ "$MODE" == check ]]; then default_gate || exit 2; fi
```

The first brief read (`read_settings`, `open_shared`, then `check_line`) comes only at `:640-646`, after this exit. Executed with a PATH shim logging every git call (`fc-sub/p76.log`):

- 76a/76b/76b2/76g each print `refuse state default-branch: both main and master exist`, exit 2, 15 git calls, 0 naming briefs.
- 76c prints `refuse state default-branch: origin/HEAD names origin/master, but the default branch taken is main`, exit 2, 0 brief calls.
- 76d prints `... names origin/main, but the default branch taken is master`, exit 2, 0 brief calls.
- The controls 76e/76e2/76f print `ok`, exit 0, with 9 calls naming briefs (for example `cat-file blob <sha>:docs/working/briefs/2026-10-01-x.md`). This shows the shim does catch brief reads.

The R7 bats test passes (`fc-sub/bats.log`, ok 6).

**Evidence:** `scripts/build-loop.sh:241-260`, `scripts/build-loop.sh:639-649`, fixture `fc-sub/p76.sh`, captured output `fc-sub/p76.log`, `fc-sub/bats.log`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 72a** (`scripts/build-loop.sh:520-530`): a missing main tree gives exit 2 and no ok line, but as `skip BRIEF: the tree of the default branch could not be read` from status_line, not a `refuse` from merge_result. merge_result's main-tree check is unreachable in that shape. The endorsement should say "skip or refuse (exit 2)".

### Unverifiable
- (none)

Notes for the orchestrator (no verdict change):
- Claim 74: the reviewer's Not-verified expectation for 100664 is wrong. Git reads it as 100644, so it passes rather than being denied, and the gate's TREE stores 100644.
- Claim 72b: two refusal messages name the wrong cause. Stderr from `--batch-check` is reported as "names a blob the object store lacks", and stderr from hash-object as an own-brief deny row. Both still refuse.
