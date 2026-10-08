# Code Fact-Check Report

**Commit:** 93655b47
**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace/.claude/wt-build-loop-u2b1a (branch `feat/build-loop-u2b1a`)
**Scope:** `git diff main...HEAD` (d0199be6, 93655b47): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md`, `docs/working/questions.md`, both commit messages; plus `scripts/dev-cycle.sh`'s help for the changed `check_branch`.
**Checked:** 2026-10-08
**Total claims checked:** 33
**Summary:** 23 verified, 6 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern. The suite-count claim was the closest match to the "N tests claimed in a commit" entries, and it was re-counted (Claim 28).

Execution provenance (all runs used git 2.39.5 and bash 5.2.15. The scratch root S is `/tmp/claude-1000/-workspace/12df4484-20a6-4551-bee0-ba84544b2ac2/scratchpad/fcu2b-y66y`):

- **E1 suites:** `TMPDIR=$(mktemp -d /tmp/fcu2b-XXXX) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`. Run in the worktree, exit 0, 2026-10-08T18:10:15Z. Output is in `S/suites.log` (1..188, all ok).
- **E2 probes:** `bash S/probes.sh S/probe-Oheb /workspace/.claude/wt-build-loop-u2b1a`. Run in S, exit 0, 2026-10-08T18:17:21Z. Output is in `S/probes.log` (sections P1-P7 are cited below).
- **E3 mutants:** these ran against copies of `scripts/` and `test/` under S/m1 and S/m2 at about 2026-10-08T18:14Z. Each run used its own TMPDIR, removed afterwards. m1 has merge_result's `cd "$t" && git --git-dir=...` replaced by a plain `git merge-tree`: `bats -f 'reads no checkout attributes|clean merge is ok'` exits 1 (`S/m1.log`). m2 drops `info/attributes` from the state gate's file loop: `bats -f 'state gate refuses'` exits 1 (`S/m2.log`). m3 replaces the `harden` call with `:`: `bats -f 'runs no hook'` exits 0 (`S/m3.log`).
- **E4 old vs new NUL:** main's `scripts/build-loop.sh` and lib (`git show main:...`, saved under S/old) and the branch's, each run as `bash <script> --status docs/working/briefs/2026-10-01-x.md 2>S/err.{old,new}`. Run in S/r2, exit 0 both, about 2026-10-08T18:05Z. `S/err.old` is empty. `S/err.new` holds the bash NUL warning.

---

## Claim 1: "U2b1a ... `harden` (config-count pairs for every git call: no replace refs, hooks, fsmonitor or outside attributes file), the state gate (refuse filter/include/hook/merge/diff keys, ...), ... merge-tree run from a fresh empty directory against the common git dir (git 2.39 reads `.gitattributes` from the current directory even under `--work-tree`, so an untracked or `.git`-planted `* merge=union` turned a conflict into a clean merge: reproduced), brief enumeration into the lib (`open_shared`, `anybrief`; rows 298, 323), row 307 (...). Tests T16, T17, T18, T20, T26."

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the split note's U2b1a item list against the code and tests at 93655b47, and the reproduction claim. It does not establish the size estimate in the note's heading ("measured well over the 400-line cap"), which was not re-measured. It also does not establish that the `.git`-planted case flips a merge from any working directory other than `.git` itself.

Every listed item exists in code. `harden` is at `scripts/build-loop.sh:150`. The state-gate keys are `STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature)'` (`scripts/build-loop.sh:404`), and the files are `for f in info/attributes info/grafts; do` (`:416`). merge-tree runs as `out="$(cd "$t" && git --git-dir="$common" merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)"` (`:437`). The lib has `open_shared() {` (`scripts/lib/dev-cycle-read.sh:461`). The test titles carry T16, T17, T18, T20 and T26 (`test/scripts/build-loop-check.bats:1256,1275,1295,1356,1315,1339`).

Reproduction (E2 P1, P1b, P1d): an untracked `.gitattributes` in the working directory turns the conflict clean (`rc=0`), including under `--work-tree=<empty dir>`. A `.git/.gitattributes` turns it clean only when the working directory is `.git` (`rc=0`). From the top level it does not (P1e `rc=1`). Rows 298, 307 and 323 in `docs/reviews/override-log.md` are the F31 second-read-path row, the broken-log-config row and the `anybrief` row, as cited.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `docs/working/plan-build-loop-handoff.md:281`, `scripts/build-loop.sh:150-158,404,416,437`, `scripts/lib/dev-cycle-read.sh:461`, `docs/reviews/override-log.md:298,307,323`, `S/probes.log` (P1-P1e)

---

## Claim 2: "U2b was split the same way before any code, for size alone ... Plan step 5's U2b split note lists each. No new judgment; commit d0199be6 on `feat/build-loop-u2b1a`."

**Location:** `docs/working/questions.md:346`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the split note sits under plan step 5, names the four units, and arrived in d0199be6. It does not establish "for size alone" (intent).

The U2b bullets sit under `5. **U2 code** (~200): ...` (`docs/working/plan-build-loop-handoff.md:272`). The note lists U2b1a, U2b1b, U2b2 and U2b3 (`:280-284`). `git show --stat d0199be6` lists `docs/working/plan-build-loop-handoff.md | 5 +` (paraphrased: no quote available because this is git's stat output, not file text). The update line sits inside Q-119 before its `If the answer differs` line.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `docs/working/questions.md:346`, `docs/working/plan-build-loop-handoff.md:272,280-284`

---

## Claim 3: "--check ... First a state gate: a git config key (common config or config.worktree, includes not followed) for a filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.* or log.showSignature, a non-empty info/attributes or info/grafts, or a replace ref prints "refuse state WHAT: WHY" per finding and exits 2 before any brief is read."

**Location:** `scripts/build-loop.sh:78-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help's list against `STATE_KEYS_RE` and the file and ref checks, the output form, exit 2, and the gate's order before `read_settings` and the brief loop. It does not establish that the list is complete for command-running state: Claim 13 finds it is not. Note also that "non-empty" undersells the check, which also refuses a symlink or non-regular node even when empty.

The help's list matches `STATE_KEYS_RE` one for one (`scripts/build-loop.sh:404`). The files are covered by `if [[ -s "$line" || -L "$line" || ( -e "$line" && ! -f "$line" ) ]]` (`:418`). Replace refs are covered by `refs="$(git for-each-ref --format='%(refname)' refs/replace/)"` (`:420`). The order is `state_gate || exit 2` then `read_settings` (`:474-475`). The T26 test passed in E1, as did the per-key loop and the config.worktree, info/attributes, info/grafts and refs/replace assertions (`S/suites.log`).

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:78-84,404-422,474-475`, `test/scripts/build-loop-check.bats:1315-1337`, `S/suites.log`

---

## Claim 4: "refuse BRIEF: WHY — The brief is done, dropped or new on main, its branch is absent or not ahead, TIP is not SHA, or the merge conflicts."

**Location:** `scripts/build-loop.sh:92-94`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's refuse reasons against this list. It does not establish the stderr or exit behaviour, which is Claim 6.

check_line has two refusals the help omits: `echo "refuse $a: its branch $br moved or could not be read again"` (`scripts/build-loop.sh:453`) and `*) echo "refuse $a: the merge of $br could not be computed" ;;` (`:460`). A precise help text would add "its branch moved or could not be read again, or the merge could not be computed".

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:92-94,446-462`

---

## Claim 5: "Writes nothing but --check's merge objects (merge-tree writes the merged trees into the object store)."

**Location:** `scripts/build-loop.sh:99-100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what merge-tree writes and the gate's temp directory. It does not establish that no other git call writes. GIT_OPTIONAL_LOCKS=0 covers index refresh, but a partial clone's lazy fetch (Claim 13) writes fetched objects.

merge-tree writes merged blobs as well as trees. A clean content merge of one file raised `git count-objects` from 9 to 11 (one new blob and one new tree). This was a manual run in S/r5 at about 18:13Z, with output shown in the session only. Paraphrased: no quote available because this is git's own write behaviour, not repo code. The script also creates and removes a temp directory outside the repo: `GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT` (`scripts/build-loop.sh:477`). A precise version would say "merged trees and blobs".

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:99-100,437,477`

---

## Claim 6: "Exit: 0 every line printed (or help), and for --check every line ok; 2 any --check line or the state gate not ok; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:103-105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --check exit paths (the gate, a non-ok line, the usage errors) as the E1 tests exercise them. It does not establish exit codes under a `set -e` abort from an unexpected failure (for example, a failing `mktemp -d` exits 1).

The code reads `[[ "$out" == "ok "* ]] || fails=1` and then `[[ "$fails" -eq 0 ]] || exit 2` (`scripts/build-loop.sh:481-484`), and `usage() { ... exit 1; }` (`:120`). The T17 and T18 tests assert status 1 and 2 respectively and pass (E1).

**Legibility-target:** for-automated-gate
**Evidence:** `scripts/build-loop.sh:103-105,120,474-484`, `test/scripts/build-loop-check.bats:1275-1313`, `S/suites.log`

---

## Claim 7: "Every git call in this process, the lib's included, runs hardened through config-count pairs, which outrank the repo's config"

**Location:** `scripts/build-loop.sh:143-144`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers precedence (a command-scope pair beats a local value) and ordering (`harden` runs before the first git call, `git rev-parse --show-toplevel`, and before `resolve_main`; the lib runs no git at source time). It does not establish behaviour when the caller exports a zero-padded or malformed GIT_CONFIG_COUNT, which the comment itself carves out as trusted.

`harden` then `export GIT_LITERAL_PATHSPECS=1 ...` then `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` (`scripts/build-loop.sh:157-159`). `resolve_main || true` follows. `scrub_reexec` runs earlier but only re-executes bash: `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" ...` (`scripts/lib/dev-cycle-read.sh:118`). A grep for git at the lib's top level found no git call outside a function (paraphrased: no quote available because the claim is about the absence of a match). E2 P2: with local `core.hooksPath=/x` and a count pair `/dev/null`, `git config --get core.hooksPath` printed `/dev/null`. An earlier run also showed the same precedence for core.attributesFile, core.fsmonitor and core.useReplaceRefs.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:143-159`, `scripts/lib/dev-cycle-read.sh:115-119`, `S/probes.log` (P2)

---

## Claim 8: "...: main's own objects (...), no hook, no fsmonitor command, no attributes file from outside the repo."

**Location:** `scripts/build-loop.sh:145-147`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four pairs and the attribute sources outside the repo. It does not establish that hooks would otherwise run from any `--check` git call (Claim 26 finds none would).

The pairs are `core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null` (`scripts/build-loop.sh:152`). The pair blocks the user-level attributes file. In an earlier run in S/e, `$HOME/.config/git/attributes` with `* merge=union` turned the merge clean without the pair and left it conflicted with the pair (paraphrased: no quote available because that run's output was shown in the session only). The system attributes file is switched off by the environment variable on the next line, `GIT_ATTR_NOSYSTEM=1` (`:158`), not by a pair. The sentence credits the config-count pairs with all four properties. A precise version would say "pairs and GIT_ATTR_NOSYSTEM".

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:143-158`

---

## Claim 9: "What these pairs cannot switch off, --check's state gate refuses."

**Location:** `scripts/build-loop.sh:149`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one counterexample, run end to end: a partial-clone promisor remote whose `uploadpack` is a command. It does not establish the full set of command-running state the gate misses.

E2 P5 sets up a repo with `extensions.partialClone origin`, `remote.origin.promisor true`, `remote.origin.uploadpack "touch $P/pwned-uploadpack; git-upload-pack"` and a main commit whose tree object is absent. `bash scripts/build-loop.sh --check ...` passed the state gate and printed `refuse ...: the brief is new on the default branch`, exit 2. The marker file went from `none` to present: the gate's own `ls-tree` read of main lazily fetched from the promisor remote and ran the configured command. Neither the pairs (`scripts/build-loop.sh:152`) nor `STATE_KEYS_RE` (`:404`) mentions `remote.`, `extensions.` or `core.sshCommand`. This is the same gap as Claim 13.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/build-loop.sh:149-158,404`, `S/probes.log` (P5)

---

## Claim 10: "the message is the raw object's text after its first empty line (no header holds one)"

**Location:** `scripts/build-loop.sh:327-328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message split for a gpgsig multi-line header, an empty message and a message that starts with a blank line, all compared with git's own reading and with main's code. It does not establish the mergetag header separately, though it uses the same continuation form.

The split is `if [[ "$msg" == *$'\n\n'* ]]; then msg="${msg#*$'\n\n'}"; else msg=""; fi` (`scripts/build-loop.sh:334`). git's continuation lines start with a space, so a signature's blank armour line is stored as " ". A non-literal `hash-object -t commit` accepted a gpgsig header with a ` ` line, and `--status` read the marker as `ready`. An empty-message commit read as `working`: `$(...)` strips the trailing `\n\n`, so the else branch fires. A leading blank message line read as `working` in both the new code and main's code. These were manual runs in S/r2, output in the session (paraphrased: no quote available because the results are runtime output).

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:324-350`

---

## Claim 11: "read with cat-file so no log.* or i18n.* config can change or break it. A failed read answers bad, never working (row 307)."

**Location:** `scripts/build-loop.sh:328-333`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rev-list `--parents` and cat-file under bogus log.date, log.showSignature, log.mailmap and i18n.logOutputEncoding, and the failed-read arm. It does not establish silence on stderr. A commit holding a NUL now makes bash print `warning: command substitution: ignored null byte in input` from `:331`, which main's `git log --format=%B` did not (E4).

The code reads `if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null)"; then echo "bad its commit could not be read"; return` (`scripts/build-loop.sh:331-333`). E2 P4: rev-list `--parents` and cat-file exit 0 under each bogus key, while `git log -1 --format=%cs` exits 128 under the three log.* keys. E2 P6 and E4: the branch prints the NUL warning to stderr and main's code prints nothing. The `2>/dev/null` covers git's stderr, not bash's warning.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:331-337`, `S/probes.log` (P4, P6), `S/err.old`, `S/err.new`

---

## Claim 12: "it reads nothing through porcelain git (git config --file with --no-includes follows no include, and --git-path reads no index)"

**Location:** `scripts/build-loop.sh:394-396`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's calls (`rev-parse --git-path`, `config --file --no-includes`, `for-each-ref`) and that --no-includes lists `include.path` without following it. It does not establish that these calls are immune to repo config generally (they run hardened, Claim 7).

The calls are `git config --file "$f" --no-includes --name-only --get-regexp "$STATE_KEYS_RE"` (`scripts/build-loop.sh:410`) and `git rev-parse --path-format=absolute --git-path "$f"` (`:408,417`). In a manual run against `S/cfgf`, `--no-includes` printed only `include.path`, while `--includes` also printed `merge.z.driver` from the included file. Paraphrased: no quote available because this is runtime output shown in the session.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:405-422`

---

## Claim 13: "The gate's state check (D7, F25): the repo-local git state that can make the gate's git run a command, or change the merge it computes, which harden's config pairs do not switch off." (with STATE_KEYS_RE as the key list)

**Location:** `scripts/build-loop.sh:391-404`
**Type:** Invariant / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the completeness of the key list for command-running state that the gate's git honours. It does not establish completeness for keys beyond the partial-clone family found here.

The list misses `extensions.partialClone` and `remote.<name>.promisor` combined with `remote.<name>.uploadpack`, and `core.sshCommand` for an ssh promisor URL. With these set, any gate read of a missing object (ls-tree, cat-file, rev-list, merge-tree) lazily fetches and runs a command. E2 P5 shows `--check` running `touch` through `remote.origin.uploadpack` after passing the gate. The regex is `STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature)'` (`scripts/build-loop.sh:404`). The repo has prior art covering both families: `devcontainer-config/cc-exit-scan.sh:119` includes `remote\.` and `core\.sshcommand`, and `devcontainer-config/cc-push.sh:323-327` refuses `promisor|partialclone`. No override-log row covers this (grep for promisor, partialclone and uploadpack in `docs/reviews/override-log.md` found nothing).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/build-loop.sh:391-422`, `devcontainer-config/cc-exit-scan.sh:119`, `devcontainer-config/cc-push.sh:323-327`, `S/probes.log` (P5)

---

## Claim 14: "(a merge driver is a command; diff.ignoreSubmodules can hide a gitlink)"

**Location:** `scripts/build-loop.sh:398`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff.ignoreSubmodules half against the plumbing `diff-tree` that D7 uses, and porcelain `git diff`, on git 2.39.5. It does not establish that refusing diff.* is wrong: diff.*.textconv and diff.external do run commands. The "merge driver is a command" half is correct.

E2 P3: with `-c diff.ignoreSubmodules=all`, `git diff-tree -r --raw HEAD~1 HEAD` still prints `:000000 160000 ... A	sub`. Only porcelain `git diff` hides it, printing nothing. No `--check` git call in this unit, and none of the D7 steps (merge-tree, diff-tree, commit-tree), is a porcelain diff. The stated reason does not apply to the gate's git. The plan's F8 row makes the same assumption (`plumbing diff-tree with diff.ignoreSubmodules=none`, `docs/working/plan-build-loop-handoff.md:123`).

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:398`, `docs/working/plan-build-loop-handoff.md:123`, `S/probes.log` (P3)

---

## Claim 15: "a non-empty info/attributes (it sets merge drivers and union merges for every path), info/grafts, and any ref under refs/replace/ (both rewrite history; the hardened reads ignore replace refs, but a planted one means a writer is at work)."

**Location:** `scripts/build-loop.sh:400-403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that common-dir info/attributes reaches merge_result's merge-tree (mutant m2), that grafts still rewrite history under GIT_NO_REPLACE_OBJECTS and `core.useReplaceRefs=false`, and that the hardened reads ignore replace refs. It does not establish anything for per-worktree `info/attributes`, which merge-tree against the common dir does not read.

Mutant m2, with info/attributes dropped from the loop, fails the T26 test (E3, `S/m2.log`). In a manual run, `git rev-list --count main` printed 2, then 1 under hardened env with `.git/info/grafts` naming main as parentless (paraphrased: no quote available because this is runtime output shown in the session). From a linked worktree, `--git-path info/attributes` resolves to the common dir's file, and a per-worktree `info/attributes` did not change the result (`refuse ...: feat/x conflicts`).

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:400-403,416-421`, `S/m2.log`

---

## Claim 16: "(git 2.39 reads one from the current directory even under --work-tree)"

**Location:** `scripts/build-loop.sh:427-428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 `merge-tree --write-tree` with an untracked `.gitattributes` in the working directory, with and without `--work-tree`. It does not establish other git versions.

E2 P1 and P1b both print `rc=0 (0 clean, 1 conflict)` with `* merge=union` in the working directory, the second under `--work-tree=<empty dir>`. Without it, the same merge conflicts (P1c, rc=1).

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:424-430`, `S/probes.log` (P1, P1b, P1c)

---

## Claim 17: "merge-tree in a fresh empty directory of the gate's own, against the common git dir with no work tree, so no checkout's .gitattributes (untracked ones included, or one planted in .git) sets a merge driver or a union merge"

**Location:** `scripts/build-loop.sh:424-428`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the effect for an untracked checkout file, a `.git` plant, a parent directory of the temp dir, a staged index entry, `core.worktree` pointing at a checkout holding the file, and a linked worktree. It does not establish behaviour when the caller exports GIT_WORK_TREE (trusted environment).

The call is `out="$(cd "$t" && git --git-dir="$common" merge-tree ...)"` (`scripts/build-loop.sh:437`). The effect holds in every case tried: P1c, P1f (parent dir), P1g (staged index) and P1h (`core.worktree`) all give `rc=1`. In the linked worktree run (S/r4-wt), untracked attributes in both checkouts and a per-worktree gitdir plant still gave `refuse ...: feat/x conflicts with the default branch`. The mechanism wording is imprecise. With `--git-dir` and no core.worktree, git takes the current directory as the work tree's top level, so there is a work tree: the empty `$t`. With core.worktree set, the working directory lies outside it and attributes are still read from `$t`. The protection comes from `$t` being empty, not from there being no work tree.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:424-440`, `S/probes.log` (P1c-P1h)

---

## Claim 18: "Prints the result tree; returns 1 on a conflict, 2 when git failed."

**Location:** `scripts/build-loop.sh:428-429`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge_result's return mapping and check_line's three arms. It does not establish which git failures reach rc 2. Any rc above 1, or a first line that is not a hex id, does.

The code reads `[[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2` then `[[ "$rc" -eq 0 ]] || return 1` then `echo "${out%%$'\n'*}"` (`scripts/build-loop.sh:438-440`). T16 asserts the ok tree equals `git merge-tree --write-tree main feat/x`, and the conflict refuses. It passes in E1.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:432-441,457-461`, `test/scripts/build-loop-check.bats:1256-1264`, `S/suites.log`

---

## Claim 19: "--check for one brief: "ok BRIEF TIP TREE", or one skip or refuse line (from status_line, then the gate's own reasons)."

**Location:** `scripts/build-loop.sh:442-443`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of reasons (not open, absent, moved or unreadable re-read, not ahead, --expect mismatch, merge) and the field parsing of status_line's and check_branch's lines. It does not establish when "moved or could not be read again" fires in practice: only a ref move between the two reads, or a re-read failure that status_line's own read did not hit.

The fields are read as `read -r _ _ st _ br loop sha _ <<<"$out"` against `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` (`scripts/build-loop.sh:448,388`), so st is field 3, br field 5, loop 6 and sha 7. They are also read as `read -r _ _ _ n _` against `echo "ok $a $sha $n $d"` (`:452`, `scripts/lib/dev-cycle-read.sh:447`). The refusals then follow in the order stated (`scripts/build-loop.sh:449-460`). check_line does not refuse on LOOP (working, ready and the rest) beyond `absent`. The help's ok line does not claim it does.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:388,442-462`, `scripts/lib/dev-cycle-read.sh:442-449`

---

## Claim 20: "--check-branch ... "skip <name>: <reason>" for a name outside letters, digits, . _ - /, starting with -, not a valid branch name (HEAD, refs/...) or the default branch."

**Location:** `scripts/dev-cycle.sh:43-49`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dev-cycle.sh's help for check_branch's skip reasons. It does not establish dev-cycle.sh's other modes.

`dev-cycle.sh --check-branch` calls `check_branch "$a"` (`scripts/dev-cycle.sh:199`), which now also prints `else echo "skip $a: its commit count or date could not be read"; fi` (`scripts/lib/dev-cycle-read.sh:448`). The help's list of skip reasons does not include it. build-loop.sh's own help was updated (`scripts/build-loop.sh:73`). This file is outside the diff.

**Legibility-target:** for-author
**Evidence:** `scripts/dev-cycle.sh:43-49,199`, `scripts/lib/dev-cycle-read.sh:435-449`

---

## Claim 21: "and so is a branch whose count or date cannot be read (a broken log.* config, say: row 307)."

**Location:** `scripts/lib/dev-cycle-read.sh:433-434`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip on a failed or malformed count or date read, and the `--status` wording the new test asserts. It does not establish the count read failing under log.* config: only the date read does (P4).

The code reads `elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] && d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ... ]]; then echo "ok $a $sha $n $d"` / `else echo "skip $a: its commit count or date could not be read"` (`scripts/lib/dev-cycle-read.sh:446-448`). status_line maps that to `*) echo "skip $a: Branch: ${out#*: }"` (`scripts/build-loop.sh:377`), giving exactly `skip $B: Branch: its commit count or date could not be read`, as the test asserts (`test/scripts/build-loop-check.bats:1353`). That test passes in E1.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:433-449`, `scripts/build-loop.sh:373-378`, `test/scripts/build-loop-check.bats:1349-1354`, `S/probes.log` (P4)

---

## Claim 22: "open_shared computes it once per process, from MAIN_SHA. ... brief_fields then reads only those, so every brief is still read through main_entry. Exit 1 is "none"; any exit above 1, a corrupt object's included, fails closed. A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293). Call it in the caller's shell."

**Location:** `scripts/lib/dev-cycle-read.sh:451-459`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo guard, the main_entry path, the exit-code mapping and the missing-blob case (exit 1). It does not establish the "exits 0" variant of a missing object or the corrupt-object exit code, which were not reproduced. "Once per process" holds only when the first call is in the main shell, as the comment's last sentence and `scripts/build-loop.sh:476` arrange.

The guard is `[[ -z "$OPEN_SHARED" ]] || return 0` (`scripts/lib/dev-cycle-read.sh:464`). The failure checks are `if [[ "$rc" -gt 1 ]]; then OPEN_SHARED=error; return; fi` (`:467`) and `if ! anybrief "$f" || ! brief_fields "$f"; then continue; fi` (`:470`). brief_fields runs `[[ "$(main_entry "$1")" != blob ]]` (`:360`). In a manual run in S/r6 with a brief blob removed from the object store, git grep printed `error: ... unable to read` and exited 1. Paraphrased: no quote available because this is runtime output shown in the session.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:355-360,451-476`, `scripts/build-loop.sh:354,476`

---

## Claim 23: The move of `shared_branches` into the lib as `open_shared` preserved its behaviour (commit d0199be6: "brief enumeration moved in")

**Location:** `scripts/lib/dev-cycle-read.sh:461-476`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a body-by-body diff of main's `shared_branches` against `open_shared`. It does not establish dev-cycle.sh use, since open_shared has no dev-cycle.sh caller yet.

The differences are renames (`SHARED_BRANCHES` to `OPEN_SHARED`, `n` to `count`, `isbrief || isclosed` to `anybrief`), the memo moved inside the function (old caller: `[[ -n "$SHARED_BRANCHES" ]] || shared_branches`; new: `open_shared`, `scripts/build-loop.sh:354`), and one new guard, `if ! main_by_name; then OPEN_SHARED=error; return; fi` (`scripts/lib/dev-cycle-read.sh:465`). build-loop.sh never reaches that guard, because it exits 1 on `main_by_name` failure first (`scripts/build-loop.sh:164`). The grep, the loop and the result string are character-identical. Paraphrased: no quote available because this compares two whole function bodies (see the diff hunks at `scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:461-476`, `scripts/build-loop.sh:164,354`, `git show main:scripts/build-loop.sh` (old `shared_branches`)

---

## Claim 24: "--check's merge reads no checkout attributes: an untracked .gitattributes, or one planted in .git, cannot turn a conflict into a union merge (U2b1a)"

**Location:** `test/scripts/build-loop-check.bats:1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test fails when merge-tree runs from the checkout (mutant m1). It does not establish separate coverage for each of the two plants: both are planted at once, so a mutant reading only one of them is still caught, but which one is not identified.

The test plants `printf '* merge=union\n' > .gitattributes` and `printf '* merge=union\n' > .git/.gitattributes`, then asserts the conflict refusal (`test/scripts/build-loop-check.bats:1269-1272`). Mutant m1 makes it fail (`not ok 2`, `S/m1.log`).

**Legibility-target:** for-automated-gate
**Evidence:** `test/scripts/build-loop-check.bats:1266-1273`, `S/m1.log`

---

## Claim 25: "--check's state gate refuses each planted git state that can run a command or change the merge, before reading any brief (T26, U2b1a)"

**Location:** `test/scripts/build-loop-check.bats:1315`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed key, config.worktree, the two files and a replace ref. It does not establish "before reading any brief": the test checks only that the brief path is absent from the output. It also does not establish "each ... state that can run a command": the partial-clone family is not planted (Claim 13).

The only ordering assertion is `&& [[ "$output" != *"$B"* ]]` (`test/scripts/build-loop-check.bats:1323`), which shows that no brief line was printed. That brief reads do not happen is true from code order (`scripts/build-loop.sh:474-475`), but the test does not check it. A precise title would say "before any brief line".

**Legibility-target:** for-author
**Evidence:** `test/scripts/build-loop-check.bats:1315-1337`, `scripts/build-loop.sh:474-475`, `S/suites.log`

---

## Claim 26: "--check runs no hook from .git/hooks (T26, U2b1a)"

**Location:** `test/scripts/build-loop-check.bats:1339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal title: no hook among the seven planted ones ran. It does not establish that `harden`'s `core.hooksPath=/dev/null` is what prevents them. With the `harden` call removed (mutant m3), the test still passes, because no `--check` git call (merge-tree, rev-list, ls-tree, cat-file, grep, log, for-each-ref) fires any of these hooks and core.fsmonitor is unset in the fixture.

E3: `ok 1 --check runs no hook from .git/hooks (T26, U2b1a)` with harden disabled (`S/m3.log`). As T26 evidence that the hooks are inert because of hardening, as d0199be6's "hooks inert" bullet implies, the test does not detect a regression.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/build-loop-check.bats:1339-1347`, `scripts/build-loop.sh:150-157`, `S/m3.log`

---

## Claim 27: The other new test titles: T16 (`:1256`), T17 (`:1275`), T18 (`:1295`), row 307 (`:1349`), T20 "never push" (`:1356`)

**Location:** `test/scripts/build-loop-check.bats:1256-1359`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each body asserts what its title lists, and that all pass. T20 checks only that the word "push" (`grep -nwi`) is absent from the two files. It does not establish that no git command is invoked under another name.

T17 loops both argument orders, a stale id, four bad ids (`full 40- or 64-hex` stderr) and four usage cases (`:1276-1292`). T18 covers done and dropped, new, absent, level, ok in one call, and the case-folded twin skip (`:1296-1312`). The row 307 test sets `git config log.date bogus` on a `handoff: ready` tip and asserts the skip (`:1350-1353`). All pass in E1.

**Legibility-target:** for-automated-gate
**Evidence:** `test/scripts/build-loop-check.bats:1256-1359`, `S/suites.log`

---

## Claim 28: "Suites: build-loop-check 87, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; scripts/health-check.sh passed."

**Location:** commit d0199be6 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five counts (`bats --count`) and a full passing run of the five suites. It does not establish the health-check.sh claim, which was not re-run.

`bats --count` gives 87, 19, 78, 2 and 2, and E1 ran 1..188 with all ok and exit 0. Paraphrased: no quote available because these are counts of tool output, captured in `S/suites.log`.

**Legibility-target:** for-automated-gate
**Evidence:** `S/suites.log`

---

## Claim 29: "350 code lines against main."

**Location:** commit d0199be6 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers additions plus deletions outside `docs/` from `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'`. It does not establish any other line-count convention.

The numstat rows are `154 42 scripts/build-loop.sh`, `36 6 scripts/lib/dev-cycle-read.sh` and `112 0 test/scripts/build-loop-check.bats`, totalling 350 (run in the worktree, exit 0, output shown in the session; the counts are restated here).

**Legibility-target:** for-automated-gate
**Evidence:** `git diff --numstat main...HEAD` (worktree)

---

## Claim 30: "Two mutants checked (the merge-tree cwd, the info/attributes check): both fail their tests."

**Location:** commit d0199be6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two mutants as reconstructed here (m1 and m2 in E3). It does not establish that they are the same edits the author made.

`S/m1.log`: `not ok 2 --check's merge reads no checkout attributes ...`. `S/m2.log`: `not ok 1 --check's state gate refuses each planted git state ...`.

**Legibility-target:** for-automated-gate
**Evidence:** `S/m1.log`, `S/m2.log`

---

## Claim 31: "marker_kind's failed-read arm is not reachable through a log.* config any more (cat-file), so the row-307 test covers check_branch's arm only."

**Location:** commit d0199be6 message (Notes)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rev-list `--parents` and cat-file under bogus log.* and i18n.* values. It does not establish unreachability under other config, such as a broken core.* key, which fails every git call.

E2 P4: `log.date=bogus 0 0 0 128` (rev-list `--parents`, cat-file and rev-list `--count` exit 0; only `git log` fails). Earlier runs gave the same result for log.decorate, log.showRoot, log.follow, log.abbrevCommit, log.graphColors and i18n.commitEncoding.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:331`, `S/probes.log` (P4)

---

## Claim 32: "The U2b split (U2b1a, U2b1b, U2b2, U2b3) was made without asking, per pr-prep 1a in away mode; it is an interim in docs/working/questions.md."

**Location:** commit d0199be6 message (Notes)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the questions.md record is. It does not establish the pr-prep 1a reference.

d0199be6 does not touch `docs/working/questions.md`: its stat lists only the plan, the two scripts and the test. The record arrives in the next commit, 93655b47, as an `Update 2026-10-08` line under Q-119 (`docs/working/questions.md:346`). The line itself says `No new judgment` and does not mark the split as an interim. Q-119's own `Interim:` is [1], for the U2a split. A precise version would say "recorded as an update to Q-119 in 93655b47".

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `docs/working/questions.md:344-346`, `git show --stat d0199be6 93655b47`

---

## Claim 33: "the plan's risk note already accepts that a legitimate local merge.* or diff.* key refuses."

**Location:** commit d0199be6 message (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and wording of the risk note. It does not establish acceptance for the other refused families (filter, include, gpg.*).

The plan reads: `- **The state gate (F25, F51) can refuse** when a legitimate local config sets a \`diff.*\` or \`merge.*\` key. The refusal names the key.` (`docs/working/plan-build-loop-handoff.md:382`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `docs/working/plan-build-loop-handoff.md:382`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (`scripts/build-loop.sh:149`): "What these pairs cannot switch off, --check's state gate refuses" is false. A partial clone's promisor `remote.<name>.uploadpack` ran a command during `--check` after the gate passed (P5).
- **Claim 13** (`scripts/build-loop.sh:391-404`): the key list misses `extensions.partialClone`, `remote.*` (promisor, uploadpack) and `core.sshCommand`, all of which let the gate's reads run a command through a lazy fetch. The repo's `cc-exit-scan.sh` and `cc-push.sh` already cover these.
- **Claim 14** (`scripts/build-loop.sh:398`): "diff.ignoreSubmodules can hide a gitlink" does not hold for the gate's git. Plumbing `diff-tree` ignores the config on 2.39.5 (P3), and only porcelain `git diff` hides the gitlink. The plan's F8 row (`plan:123`) makes the same assumption.

### Stale
- **Claim 20** (`scripts/dev-cycle.sh:43-49`): the `--check-branch` help does not list the new "its commit count or date could not be read" skip.

### Mostly Accurate
- **Claim 4** (`scripts/build-loop.sh:92-94`): the refuse list omits "moved or could not be read again" and "the merge ... could not be computed".
- **Claim 5** (`scripts/build-loop.sh:99-100`): merge-tree writes blobs too, not only trees, and the gate also creates and removes a temp directory.
- **Claim 8** (`scripts/build-loop.sh:145-147`): the system attributes file is switched off by `GIT_ATTR_NOSYSTEM=1`, not by a config-count pair.
- **Claim 17** (`scripts/build-loop.sh:424-428`): the effect holds, but "with no work tree" is imprecise. git takes the empty `$t` as the work tree, and its emptiness is what protects the merge.
- **Claim 25** (`test/scripts/build-loop-check.bats:1315`): "before reading any brief" is checked only as "no brief line printed".
- **Claim 32** (d0199be6 Notes): questions.md was not changed in d0199be6. The record is a Q-119 update in 93655b47 and is not marked interim.

### Unverifiable
- None.

## Escalations

- **for-orchestrator-synthesis (security, Claims 9 and 13):** a repo-local partial-clone configuration (`extensions.partialClone` plus `remote.<name>.promisor` and `remote.<name>.uploadpack`, or `core.sshCommand` with an ssh URL) passes the state gate. Any gate read of a missing object then runs a command. This was reproduced end to end with `--check` (P5). The gate's own premise is "refuse what can run a command", so this is a gap in this unit's core claim, not a design choice. No override-log row covers it.
- **for-author (Claim 26):** the "runs no hook" test also passes with `harden` removed. It is not regression evidence for `core.hooksPath=/dev/null`. Only a hook-firing git operation, or an fsmonitor setting, would make it bite.
- **for-author (Claim 11):** a NUL-byte commit tip now makes bash print `warning: command substitution: ignored null byte in input` to stderr (`scripts/build-loop.sh:331`). main's `git log` read printed nothing (E4). No test asserts empty stderr for that case.
- **Out of scope, observed:** in `--status` (no state gate), a repo-local `diff.x.textconv` plus a checkout `.gitattributes` `*.md diff=x` runs a command through check_brief's `git log -G` (`scripts/lib/dev-cycle-read.sh:421`, P7). This predates the branch, and `--check` refuses the key.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 93655b47` line at the top.
- Answered: yes
- Out of scope: `scripts/health-check.sh` (not re-run). The `--status` textconv exposure predates this branch.
- Escalate: the partial-clone lazy-fetch gap in the state gate (Claims 9 and 13), and the hook test that passes without `harden` (Claim 26).
