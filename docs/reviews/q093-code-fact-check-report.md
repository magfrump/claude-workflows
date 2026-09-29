# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/worktrees/agent-ab977469478643bc3`, branch `q093-cc-push-self-commondir`)
**Scope:** `git diff dfe4c0d..HEAD`: `devcontainer-config/cc-push.sh`, `docs/working/plan-q093-cc-push-self-commondir.md`, `guides/cc-isolated-usage.md`, `test/cc-push.bats`, and the commit messages of `2c9ebf3` and `2c8163f`
**Commit:** 2c8163f
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 18
**Summary:** 12 verified, 3 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Two logged patterns are commit-message test counts that did not match the suites (entries at `:28` and `:30`). Claim 16 below ("12 refusals") is the same kind of claim. It was counted and is correct.

Execution provenance (all runs on 2026-09-28, local time -07:00; git 2.39.5; `LC_ALL=C` because the en_US locale is broken in this sandbox). The logs are kept in the session scratchpad rather than `docs/reviews/execution-logs/` because this pass may write only its report:
- **E1:** git experiment. `bash <scratch>/exp.sh <scratch>/exp` writes the bytes of every spelling in the plan table into a scratch repo's `.git/commondir`, then runs `git rev-parse --path-format=absolute --git-common-dir` and `git ls-remote --upload-pack='git-upload-pack --strict' <co>/.git`, and prints the helper's `head -c 2 | od -An -tx1` pipeline output raw and stripped. cwd: the worktree. Exit 0. Ran 18:00:34. Output: `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/exp.log`.
- **E2:** full suite. `LC_ALL=C bats test/cc-push.bats`. cwd: the worktree. Exit 0 (47/47 ok, including tests 14 and 15, the Q-093 tests). Ran 18:01:03–18:01:28. Output: `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/bats-cc-push.log`.
- **E3:** mutation checks. `bash <scratch>/mut.sh` copies `devcontainer-config/*.sh` and `test/cc-push.bats` into scratch, applies one mutation to `commondir_is_self`, and runs `bats -f Q-093`. Mutations: none; `-L` test removed; a `head -c 2` read added before the type test; hex compare replaced by `[ "$(cat)" = . ]`. cwd: the worktree. Exit 0. Ran ~18:02:36. Output: `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/mut.log`. The diagnostic follow-up is `mut-symlink.bats`, output in `.../scratchpad/mut-symlink.log`.
- **E4:** direct helper calls. `LC_ALL=C bash <scratch>/gc.sh` sources `cc-gitdir.sh`, evals `commondir_is_self` out of `cc-push.sh`, and prints `gitdir_common`, `gitdir_valid` and `commondir_is_self` for `.`, `.\n`, `.\0`, `./` and `d`, plus a symlink `commondir -> d` whose target is 1 byte long. cwd: the worktree. Exit 0. Ran ~18:03. Output: `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/gc.log`.

---

## Claim 1: "the one exception is a commondir that is a regular file holding exactly `.` or `.\n`, which names .git itself and which some host tool keeps writing: Q-093"

**Location:** `devcontainer-config/cc-push.sh:87-90`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the accepted byte set and the file-type requirement as `commondir_is_self` implements them, and git reading both forms as .git. Does not establish the claim that a host tool keeps writing the file (Q-091 host evidence; not checkable here).
**Legibility-target:** for-orchestrator-synthesis

The helper requires a non-symlink regular file, a size of 1 or 2 bytes, and hex `2e` or `2e0a`:

```bash
# devcontainer-config/cc-push.sh:273-278
  [ ! -L "$c" ] && [ -f "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  case "$s" in 1|2) ;; *) return 1 ;; esac
  hex="$(head -c 2 -- "$c" 2>/dev/null | od -An -tx1)" || return 1
  hex="${hex//[[:space:]]/}"
  [ "$hex" = 2e ] || [ "$hex" = 2e0a ]
```

"Regular file" is used in the strict (lstat) sense, because `! -L` comes before `-f`. E1 shows that git resolves both forms to the gitdir: `.  bytes=2e  common=<co>/.git` and `.\n  bytes=2e0a  common=<co>/.git`.

**Evidence:** `devcontainer-config/cc-push.sh:87-90`, `devcontainer-config/cc-push.sh:271-279`, exp.log

---

## Claim 2: "git (setup.c get_common_dir_noenv) reads that as 'the common dir is this git dir', exactly as when there is no commondir"

**Location:** `devcontainer-config/cc-push.sh:263-265` (repeated in commit `2c8163f` body and plan `:12-13`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the observable outcome for `.` and `.\n` on git 2.39.5: `rev-parse --git-common-dir` gives the same absolute gitdir as the no-commondir baseline, `ls-remote` through `git-upload-pack --strict <co>/.git` succeeds, and a full cc-push push succeeds (E2 test 14). Does not establish git-internal equivalence (for example, whether git sets an internal "different commondir" flag when the file exists). setup.c was not read because git source is not in the sandbox. Also does not cover git versions other than 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

E1 output: the baseline without a commondir resolves `--git-common-dir` to `.git`. With `.` and `.\n`, it resolves to `<scratch>/exp/co/.git` and `ls-remote --strict: ok`. The same run with `..` gives `ls-remote --strict: FAIL (fatal: '<co>/.git' does not appear to be a git repository)`, so the `--strict` probe does tell the cases apart. The function name `get_common_dir_noenv` could not be checked (paraphrased, no quote available because git's C source is not present in the sandbox). The behavior the comment attributes to it matches the observations above.

**Evidence:** `devcontainer-config/cc-push.sh:262-270`, exp.log (lines `.` and `.\n`)

---

## Claim 3: "Nothing else passes, not even other spellings git also reads as self (`./`, `.\r\n`, `.\0...`, the absolute path)"

**Location:** `devcontainer-config/cc-push.sh:266-267` (repeated in commit `2c8163f` body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both halves: git 2.39.5 reads each listed spelling as self (E1), and the helper refuses each one (E4 and the E2 refusal test). Does not establish that no other byte string of 1 or 2 bytes passes. That follows from the exact hex compare at `:278`, which was read but not tested exhaustively.
**Legibility-target:** for-orchestrator-synthesis

E1: `./  bytes=2e2f  common=<co>/.git | ok`; `.\r\n  bytes=2e0d0a ... ok`; `.\0  bytes=2e00 ... ok`; `abs ... common=<co>/.git | ls-remote --strict: ok`. E4: `.\0 ... is_self=1` and `./ ... is_self=1`. `.\r\n` and the absolute path fail the size case at `:275` (`case "$s" in 1|2)`), and the E2 refusal loop covers all four.

**Evidence:** `devcontainer-config/cc-push.sh:271-279`, exp.log, gc.log, bats-cc-push.log (test 15)

---

## Claim 4: "The type test comes before any read, so a FIFO is never opened"

**Location:** `devcontainer-config/cc-push.sh:267-268` (repeated in commit `2c8163f` body and plan B6 `:66`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `commondir_is_self` and its only call site in `check_checkout`, plus everything `main` runs before `check_checkout`. Does not cover a FIFO swapped in after the check (TOCTOU, plan B11).
**Legibility-target:** for-orchestrator-synthesis

The first line of the helper, `[ ! -L "$c" ] && [ -f "$c" ] || return 1` (`cc-push.sh:273`), uses stat-only tests. The caller tests only `-e` and `-L` before it: `if { [ -e "$g/commondir" ] || [ -L "$g/commondir" ]; } && ! commondir_is_self "$g/commondir"; then` (`cc-push.sh:294`). Before that, `main` runs `check_git_version` and `check_no_container`, and neither touches `.git` (`cc-push.sh:386-389`). E3 checks this by mutation: adding a `head -c 2` before the type test makes the refusal test fail at the FIFO step (`not ok 2 ... [ "$status" -eq 1 ]; [[ "$output" == *"commondir exists"* ]]' failed`), while the unmutated helper passes.

**Evidence:** `devcontainer-config/cc-push.sh:271-279`, `devcontainer-config/cc-push.sh:284-296`, `devcontainer-config/cc-push.sh:386-389`, mut.log

---

## Claim 5: "the size must be 1 or 2 bytes; the bytes are compared as hex, because bash's read drops NULs and $(...) strips trailing newlines"

**Location:** `devcontainer-config/cc-push.sh:268-270` (repeated in plan `:48-50`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size gate and the hex pipeline output for `.`, `.\n`, `.\0` and `..`, and shows that a `$(cat)` compare would accept `.\0`. Does not establish behavior under a locale where `[[:space:]]` differs (the pipeline was run with `LC_ALL=C`; `od` emits only ASCII spaces and newlines in any locale).
**Legibility-target:** for-orchestrator-synthesis

`case "$s" in 1|2) ;; *) return 1 ;; esac` (`cc-push.sh:275`). E1 prints the pipeline output: `dot raw=[ 2e] stripped=[2e]`, `dotnl raw=[ 2e 0a] stripped=[2e0a]`, `dotnul raw=[ 2e 00] stripped=[2e00]`, `dotdot raw=[ 2e 2e] stripped=[2e2e]`. The stripping gives exactly `2e` and `2e0a`. E3's `cat_compare` mutation accepts `.\0` (`# accepted:    .  \0`), which confirms the stated reason for comparing hex. Under `set -o pipefail`, a failed `head` makes the substitution fail, and `|| return 1` then refuses (`cc-push.sh:276`, which matches plan B8).

**Evidence:** `devcontainer-config/cc-push.sh:268-278`, exp.log, mut.log

---

## Claim 6: die text "(Only a regular file holding just `.`, a self-reference, is accepted.)"

**Location:** `devcontainer-config/cc-push.sh:295`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the helper's accepted set. Does not establish anything beyond the message text.
**Legibility-target:** for-author

The helper also accepts `.\n`: `[ "$hex" = 2e ] || [ "$hex" = 2e0a ]` (`cc-push.sh:278`). "Holding just `.`" leaves out the newline form that the header (`:88`) and the guide (`:258-259`) both list. It would read precisely as "holding just `.` (optionally followed by one newline)".

**Evidence:** `devcontainer-config/cc-push.sh:278`, `devcontainer-config/cc-push.sh:295`

---

## Claim 7: plan table "What git reads" (`.`/`.\n`/`.\r\n`/`.\r`/`.\n\n`/`./`/`.//`/`.\0`/`.\0/../x`/absolute → the gitdir; ` .`/`. `/`.\t`/`..`/`.\n.\n` → not a repository; empty → failed to read), and "`ls-remote --upload-pack='git-upload-pack --strict'` succeeds with `.` and fails with `..`"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:18-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every row on git 2.39.5 in a scratch layout whose checkout root has no `objects/`. Does not establish the "not a repository" result for `..` in general: `..` names the checkout root, so the result depends on what is there, and a planted repository at the root would resolve rather than fail (plan B1 correctly classes `..` as "elsewhere").
**Legibility-target:** for-orchestrator-synthesis

Every row matched in E1. The self rows all printed `common=<co>/.git | ls-remote --strict: ok`. The whitespace, `..` and `.\n.\n` rows all printed `fatal: not a git repository` and `ls-remote --strict: FAIL (... does not appear to be a git repository)`. The empty row printed `fatal: failed to read .../commondir`.

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:18-32`, exp.log

---

## Claim 8: "the refusal text stays, qualified ('other than a self-reference')"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:50-51`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wording of the die message. Does not establish anything about its correctness (see Claim 6).
**Legibility-target:** for-orchestrator-synthesis

The original sentence is kept, and a qualifier is added with different wording from the one the plan quotes: `(Only a regular file holding just \`.\`, a self-reference, is accepted.)` (`cc-push.sh:295`). The plan's quoted phrase does not appear anywhere in the code.

**Evidence:** `devcontainer-config/cc-push.sh:295`

---

## Claim 9: "`gitdir_valid` then resolves the common dir to `<g>/.`, i.e. `<g>`: unchanged"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `gitdir_common` and `gitdir_valid` for the two accepted forms. Does not establish anything about the forms the helper refuses, which `gitdir_valid` never sees because `check_checkout` dies first.
**Legibility-target:** for-orchestrator-synthesis

`gitdir_common` reads up to a NUL or trims trailing CR/LF, then prefixes `<d>/`:

```bash
# devcontainer-config/cc-gitdir.sh:61-67
  if ! IFS= read -r -d '' line < "$c" 2>/dev/null; then
    # No NUL: the whole file, trailing line breaks trimmed.
    while :; do
      case "$line" in *$'\n'|*$'\r') line="${line%?}" ;; *) break ;; esac
    done
  fi
  case "$line" in /*) printf '%s' "$line" ;; *) printf '%s/%s' "$d" "$line" ;; esac
```

(The excerpt starts at :61; the enclosing `gitdir_common()` runs :54-68, all read.) E4: `. common=[.../g/.] valid=0` and `.\n common=[.../g/.] valid=0`. `gitdir_valid` then checks `"$common/objects"` and `"$common/refs"` (`cc-gitdir.sh:79-80`), which are the same directories.

**Evidence:** `devcontainer-config/cc-gitdir.sh:54-81`, gc.log

---

## Claim 10: plan B1 "Only `2e`/`2e0a` pass; tests for `..`, `../../elsewhere`", and plan Step 3 "refuse `..`, `./`, ` .`, `../../elsewhere`, …"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:61`, `docs/working/plan-q093-cc-push-self-commondir.md:89-91`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which spellings the committed tests write. Does not establish any gap in the code: `../../elsewhere` is 14 bytes and fails the size gate at `cc-push.sh:275`.
**Legibility-target:** for-author

The refusal loop tests `for bytes in '..' './' ' .' '.\n\n' '.\r\n' '.\0' '.x' "$T/co/.git"; do` (`test/cc-push.bats:287`), and no test writes `../../elsewhere`. The plan names a test that does not exist. `..` is tested, and so are four spellings the plan's Step 3 does not list (`.\n\n`, `.\r\n`, `.\0`, `.x`). Fix: replace `../../elsewhere` with the spellings actually tested, or add the case.

**Evidence:** `test/cc-push.bats:283-308`, `docs/working/plan-q093-cc-push-self-commondir.md:61`, `docs/working/plan-q093-cc-push-self-commondir.md:89-91`

---

## Claim 11: plan B5 "helper refuses `-L` before anything else, independent of the later `find` symlink scan"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helper's own `-L` refusal, including the one case where it is the only guard (a symlink with a 1–2 byte target). Does not establish that the test suite pins this guard. It does not: see Claim 15.
**Legibility-target:** for-orchestrator-synthesis

`[ ! -L "$c" ] && [ -f "$c" ] || return 1` is the first statement (`cc-push.sh:273`), and the caller dies on the helper's result before the `find -P` scan at `cc-push.sh:305`. In E4, a symlink `commondir -> d` (link size 1) whose target holds `.` gets `is_self=1`. Without `! -L`, `stat -c %s` (lstat) would report 1 and `head` would follow the link and read `.`, so there the `-L` test is load-bearing.

**Evidence:** `devcontainer-config/cc-push.sh:273`, `devcontainer-config/cc-push.sh:294-311`, gc.log

---

## Claim 12: plan B6 "`-f` and not `-L` checked before any read; a FIFO is never opened; test with `timeout`"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:66`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers directory and FIFO `commondir`s, both of which the suite tests. Sockets and devices fail the same `-f` test (read) but are not tested. Does not cover TOCTOU (B11).
**Legibility-target:** for-orchestrator-synthesis

See Claim 4 for the code. The test runs the FIFO case under `run timeout 30 bash "$CC_PUSH" ...` (`test/cc-push.bats:301`). E3's read-before-type mutation fails that step, so the test would catch a regression.

**Evidence:** `devcontainer-config/cc-push.sh:273`, `test/cc-push.bats:299-302`, mut.log

---

## Claim 13: plan B11 (TOCTOU residual; "the running-container refusal (`check_no_container`) is the mitigation, as today"), B12 ("`looks_like_gitdir` still refuses any root `commondir`; not relaxed")

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:71-72`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers call order in `main` and the unchanged `looks_like_gitdir`. Does not establish that root-`commondir` refusal is complete for non-regular files. That behavior predates this branch and is untouched by it.
**Legibility-target:** for-orchestrator-synthesis

B11 is accurate. `check_no_container "$co" "$allow_running"` runs immediately before `check_checkout "$co"` (`cc-push.sh:388-389`), and the helper does nothing to close the check-then-read window. B12's "not relaxed" is accurate, because the diff does not touch `cc-gitdir.sh`. "Refuses any root `commondir`" overstates the check: it is `[ -f "$d/commondir" ]` (`cc-gitdir.sh:89`), which follows symlinks and does not match a directory, FIFO or dangling-symlink `commondir` at the root. A precise version would say "any root `commondir` that is, or links to, a regular file".

**Evidence:** `devcontainer-config/cc-push.sh:386-389`, `devcontainer-config/cc-gitdir.sh:87-90`

---

## Claim 14a: plan B13 "`.` resolves common dir = gitdir, so git reads the same files as with no `commondir`; `config.worktree` is still include-checked"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the resolved common dir (E1), the unchanged include check on `config.worktree`, and an end-to-end push (E2 test 14). Does not establish file-by-file equivalence inside git (for example, git's per-path common/worktree mapping when a commondir file exists), because git source was not read.
**Legibility-target:** for-orchestrator-synthesis

`for f in config config.worktree; do ... grep -Eiq '\[[[:space:]]*include' "$g/$f"` (`cc-push.sh:316-320`) still runs, and the new code sits before it and does not return early. E1 shows the common dir resolves to the same absolute path as the baseline. Any per-path remapping git does would therefore land on the same files (paraphrased, no quote available because this is an inference from git's documented common-dir remapping plus the E1 path equality; git source is not in the sandbox).

**Evidence:** `devcontainer-config/cc-push.sh:316-327`, exp.log, bats-cc-push.log (test 14)

---

## Claim 14b: plan B13 "`worktreeConfig` behaviour does not depend on `commondir`"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:73`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Would cover git's handling of `extensions.worktreeConfig` when a commondir file exists. Nothing here establishes it.
**Legibility-target:** for-orchestrator-synthesis

This is a claim about git internals (config.c and path.c), and it cannot be quoted or checked because git source is not in the sandbox (paraphrased, no quote available because the subject is external C code). Verifying it would take an E1-style run with `extensions.worktreeConfig=true` and a `config.worktree` containing a marker key, comparing `git config --get` with and without a `.` commondir. The practical risk is bounded by Claim 14a: the common dir and the gitdir are the same directory.

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:73`

---

## Claim 15: test comments: "git reads the other spellings refused below either as elsewhere or (./) as self too"; "'.\0' (bash would drop the NUL on read)"; "A FIFO is refused on its type, never opened (timeout: 124 would mean a hang)"; "A symlink to a file holding exactly `.` is refused by the helper itself"

**Location:** `test/cc-push.bats:262-265`, `test/cc-push.bats:285-286`, `test/cc-push.bats:299`, `test/cc-push.bats:303`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The most severe part carries the verdict: the `:263-264` comment about how git reads the refused spellings. The `.\0`, FIFO and symlink comments are each verified. The symlink test does not isolate the helper's `-L` guard (residue below).
**Legibility-target:** for-author

- `:263-264` is **incorrect**. Of the refused spellings, git 2.39.5 reads `.\n\n`, `.\r\n`, `.\0` and the absolute gitdir path as self, not only `./` (E1: each gives `common=<co>/.git | ls-remote --strict: ok`). A precise version: "git reads `./`, `.\n\n`, `.\r\n`, `.\0` and the absolute path as self too, and the rest as elsewhere or not a repository".
- `:285-286` is verified. `printf "$bytes"` with `'.\0'` writes `2e 00` (E1 `.\0 bytes=2e00`), and E3's `$(cat)` mutation accepts it (`accepted:    .  \0`).
- `:299` is verified. The step runs under `timeout 30`, and E3's read-before-type mutation fails it.
- `:303` is verified as stated: the refusal message is the commondir one (`[[ "$output" == *"commondir exists"* ]]`, `:306`), not the later `find` scan's "is a symlink, FIFO…". **Residue:** E3's mutation with `! -L` removed still passes both Q-093 tests. The link target `$T/dot` is a long absolute path, so `stat -c %s` (lstat) on the link returns a size over 2 and the size gate refuses it. The test therefore pins "the helper refuses" but not the `-L` guard itself. Only a link whose target is 1–2 bytes long (E4: `ln -s d commondir` → size 1) exercises that guard.

**Evidence:** `test/cc-push.bats:262-308`, exp.log, mut.log, mut-symlink.log, gc.log

---

## Claim 16: commit `2c8163f`: "Tests pin both accepted forms and 12 refusals."

**Location:** commit `2c8163f` message body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of refusal cases and the fact that the tests pass. Does not establish that every refusal pins the specific guard it targets (see the symlink residue in Claim 15).
**Legibility-target:** for-orchestrator-synthesis

There are 8 loop spellings (`'..' './' ' .' '.\n\n' '.\r\n' '.\0' '.x' "$T/co/.git"`, `test/cc-push.bats:287`), plus empty (`: > "$c"`, `:292`), directory (`:295`), FIFO (`:299-302`) and symlink (`:303-306`): 12 in total. Both accepted forms are pushed and asserted at `:268-281`. E2 passed (tests 14 and 15 ok). This is the same kind of claim as logged patterns `:28` and `:30` (commit-message test counts), and here the count is correct.

**Evidence:** `test/cc-push.bats:266-308`, bats-cc-push.log

---

## Claim 17: commit `2c8163f`: "both confirmed identical to 'absent' with git 2.39.5 (rev-parse --git-common-dir and ls-remote via upload-pack --strict)"; commit `2c9ebf3`: "Accepted bytes pinned from a git 2.39.5 experiment: exactly '.' and '.\n'"

**Location:** commits `2c8163f`, `2c9ebf3` message bodies
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reproducing the stated experiment on the same git version. Does not establish the "Live-verified: no" host rerun (Q-084 step 3), which needs the host.
**Legibility-target:** for-orchestrator-synthesis

E1 reproduced both probes. The `--git-common-dir` output for `.` and `.\n` equals the baseline gitdir, and `ls-remote --upload-pack='git-upload-pack --strict'` succeeds. `git --version` → `git version 2.39.5`.

**Evidence:** exp.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`docs/working/plan-q093-cc-push-self-commondir.md:61`, `:89-91`): the plan names a `../../elsewhere` test that does not exist. The loop tests `..`, `./`, ` .`, `.\n\n`, `.\r\n`, `.\0`, `.x` and the absolute path.
- **Claim 15** (`test/cc-push.bats:263-264`): the comment says only `./` among the refused spellings is read by git as self. `.\n\n`, `.\r\n`, `.\0` and the absolute path are too. Separately (residue, not an incorrect claim), the symlink case at `:303-306` passes even with the helper's `-L` test removed. Add a case with a short link target (`ln -s d commondir`, where `d` holds `.`) to pin it.

### Mostly Accurate
- **Claim 6** (`devcontainer-config/cc-push.sh:295`): the die message says "holding just `.`" but `.\n` is also accepted.
- **Claim 8** (`docs/working/plan-q093-cc-push-self-commondir.md:51`): the quoted qualifier "other than a self-reference" does not match the text that shipped.
- **Claim 13** (`docs/working/plan-q093-cc-push-self-commondir.md:72`): B12's "refuses any root `commondir`" is really `[ -f ]`: a regular file or a link to one (unchanged by this branch).

### Unverifiable
- **Claim 14b** (`docs/working/plan-q093-cc-push-self-commondir.md:73`): "`worktreeConfig` behaviour does not depend on `commondir`" needs git source or an `extensions.worktreeConfig` experiment.

No Incorrect verdict is a fabricated symbol, API or flag, so nothing qualifies for `docs/reviews/hallucination-patterns.md`. The file was also left untouched because this pass may write only its report.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/worktrees/agent-ab977469478643bc3/docs/reviews/q093-code-fact-check-report.md following skills/code-fact-check/SKILL.md, header including `**Commit:** <HEAD short sha>` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All 7 requested claim groups were verdicted. The code behavior claims all hold. Two doc/comment claims are incorrect (plan test list, test comment), and one test pin is weak (the symlink case does not isolate `-L`).
- Out of scope: security/design judgment of the accepted set; git internals (setup.c, config.c) are not in the sandbox; host live check (Q-084 step 3).
- Escalate: the symlink test does not pin the `-L` guard (E3 mutation survives). This is worth a short-target symlink case before merge.
- Decisions I made: execution logs were kept in the session scratchpad rather than `docs/reviews/execution-logs/`, to honor "do not modify any file other than your report". Legibility-target and Goal-Alignment follow `patterns/orchestrated-review.md` §§173-195 and 81-93, since SKILL.md does not define them.
