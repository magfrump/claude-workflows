**Commit:** 9e5d92df
**Replication:** k=1 (loop pass, decision 031)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a (branch `feat/build-loop-u2b1a`)
**Scope:** `git diff main...HEAD` at 9e5d92df: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `test/scripts/build-loop-check.bats`, commit 9e5d92df's message, and the iteration-1 rubric's Fixed notes. The focus is the iteration-1 fix commit. Other branch comments were re-checked briefly against iteration 1 (93655b47).
**Checked:** 2026-10-08
**Total claims checked:** 24
**Summary:** 20 verified, 0 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Execution environment: git 2.39.5, bats 1.8.2, bash. Every probe ran in throwaway repos under `/tmp/claude-1000/-workspace/12df4484-20a6-4551-bee0-ba84544b2ac2/scratchpad/cfc2-u2b1a/` (`$S` below). Captured output is in `$S/logs/P*.txt`, `$S/mutants.txt` and `$S/*.bats.txt`. Probe scripts: `$S/mk.sh` (fixture), `$S/probes.sh` (P3-P8), `$S/q2-VDL0/run.sh` (P1), `$S/p5-*/run.sh` (P2). The mutant copies are in `$S/mut/{nokeys,gateafter,noharden,notextconv}` (the worktree was not edited). Per the shared brief, execution logs stay in the scratchpad and nothing in the repo besides this report was written. That includes `docs/reviews/hallucination-patterns.md`, and no fabrication was found anyway.

Hallucination-pattern log read: no claim in scope matches a logged pattern. The log's suite-count entries (commit-message denominators) were checked against Claim 21 here, and the counts match.

---

## Claim 1: "--check ... First a state gate: a git config key (...) for a filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.*, log.showSignature, extensions.partialClone or remote.*.promisor (a partial clone), a non-empty info/attributes or info/grafts, or a replace ref prints "refuse state WHAT: WHY" per finding and exits 2 before any brief is read."

**Location:** `scripts/build-loop.sh:78-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed keys (including the spelling variants below), the file and ref checks, the per-finding lines and exit 2 before any brief line. Does not establish that this list is all the state that can run a command (see Claims 6 and 7: a submodule repository's config is outside it).
**Legibility-target:** for-orchestrator-synthesis

The regex lists the new keys anchored at the end:

```bash
# scripts/build-loop.sh:181
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
```

P2 checked every spelling git normalises to these keys: `[remote "Origin"] Promisor = true`, `[Extensions] PartialClone = o`, the old `[remote.Up] promisor` form, and both keys in `config.worktree`. Each printed one `refuse state ...` line and exited 2, for example `refuse state remote.Origin.promisor: set in config, ...` and `refuse state remote.o.promisor: set in config.worktree, ...`. `git config --get-regexp` matches the canonical key, which keeps the subsection's case, and `.*` takes any subsection. The suite's state-gate loop (`test/scripts/build-loop-check.bats:1317-1325`) asserts one output line per key, the two new keys included. It passed in the 89/89 run.

**Evidence:** `scripts/build-loop.sh:78-85`, `scripts/build-loop.sh:181-200`, `test/scripts/build-loop-check.bats:1315-1338`; `$S/logs/P2-key-variants.txt` (cmd `bash -c "$(cat $S/p5-*/run.sh)"` with S and P exported, cwd `$S/q5-b9r4`, exit 0, 2026-10-08T18:33:27Z), `$S/build-loop-check.bats.txt`

---

## Claim 2: "refuse BRIEF: WHY — The brief is done, dropped or new on main, its branch is absent or not ahead, it moved or could not be read again after --status read it, TIP is not SHA, the merge conflicts, or the merge could not be computed."

**Location:** `scripts/build-loop.sh:93-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `refuse $a:` echo in `check_line`. Does not establish anything about the skip lines, which come from status_line.
**Legibility-target:** for-author

`check_line` has exactly these refusals:

```bash
# scripts/build-loop.sh:461-472 (excerpt; check_line runs :456-474 — read)
  if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st on the default branch; only an open brief merges"; return; fi
  if [[ "$loop" == absent ]]; then echo "refuse $a: its branch $br does not exist"; return; fi
  ...
  if [[ "$out" != "ok $br $sha "* || ! "$n" =~ ^$DIGIT+$ ]]; then echo "refuse $a: its branch $br moved or could not be read again"; return; fi
  if [[ "$n" -eq 0 ]]; then echo "refuse $a: its branch $br has no commit the default branch lacks"; return; fi
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
  ...
    1) echo "refuse $a: $br conflicts with the default branch" ;;
    *) echo "refuse $a: the merge of $br could not be computed" ;;
```

A brief that is new on main comes back from status_line as `ok $a new ...` (`:403`), so `st` is `new` and the first line refuses it.

**Evidence:** `scripts/build-loop.sh:93-97`, `scripts/build-loop.sh:397-403`, `scripts/build-loop.sh:456-474`

---

## Claim 3: "Writes nothing but --check's merge objects (merge-tree writes the merged trees and blobs into the object store) and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:101-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a normal `--check` run (a conflicting merge in P6): the new `.git` paths are only object files, and `TMPDIR` is empty afterwards. Does not establish cleanup after SIGKILL, or writes made by a lazy fetch (Claim 7).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:488
    GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
```

In P6, `--check` with `TMPDIR=$T` left `tmp-entries=0`. A `diff` of `ls -R .git` before and after showed only two new loose objects (`./objects/75/...` and `./objects/f1/...`).

**Evidence:** `scripts/build-loop.sh:101-104`, `scripts/build-loop.sh:443-453`, `scripts/build-loop.sh:485-495`; `$S/logs/P6-comment-claims.txt` (cmd `bash $S/probes.sh`, function p6, cwd the probe repo, exit 0, 2026-10-08T18:34:25Z)

---

## Claim 4: "Every git call in this process, the lib's included, runs hardened through config-count pairs, which outrank the repo's config: main's own objects (a replace ref could swap in any blob; core.useReplaceRefs in the repo's config would override GIT_NO_REPLACE_OBJECTS), no hook, no fsmonitor command, no core.attributesFile (GIT_ATTR_NOSYSTEM, below, drops the system one)."

**Location:** `scripts/build-loop.sh:147-151`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call that build-loop.sh and the lib make through `PATH` in the scrubbed child, the override of the env var by config, and the system-attributes wording. Does not establish anything about git's own internal subprocesses, which are run from exec-path and are not seen by a PATH shim.
**Legibility-target:** for-author

P4 logged all 37 git calls of a `--check` run in order. The suite's PATH-shim test (`test/scripts/build-loop-check.bats:1367-1379`) asserts that each call carries all four pairs, and it passed. The `noharden` mutant fails it (`$S/mutants.txt`: "a call without core.useReplaceRefs=false"). P6 showed `GIT_NO_REPLACE_OBJECTS=1 git -c core.useReplaceRefs=true cat-file blob ...` printing `replaced`, so the config does override the env var. GIT_ATTR_NOSYSTEM is exported on the next line:

```bash
# scripts/build-loop.sh:156,162
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null; do
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1
```

**Evidence:** `scripts/build-loop.sh:147-162`, `test/scripts/build-loop-check.bats:1367-1379`; `$S/logs/P4-call-order.txt`, `$S/logs/P6-comment-claims.txt`, `$S/mutants.txt` (cmd `bats -f 'every git call' test/scripts/build-loop-check.bats`, cwd `$S/mut/noharden`, exit 1, 2026-10-08T18:30:31Z)

---

## Claim 5: "What these pairs cannot switch off, --check's state gate refuses."

**Location:** `scripts/build-loop.sh:153`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one end-to-end counterexample: a lazy fetch through a submodule repository's promisor config during merge-tree (P1). Does not establish how often a target repo has gitlinks on main (this repo's main has 0).
**Legibility-target:** for-orchestrator-synthesis

P1 is a superproject with no promisor configuration, so the state gate passed. main and `feat/x` each moved a gitlink `sub` (named `sm` in `.gitmodules`) away from the merge base. `.git/modules/sm` is a bare repo with `remote.origin.promisor=true`, `extensions.partialClone=origin` and `remote.origin.uploadpack "touch $P/fetched; git-upload-pack"`. `--check` printed `refuse ...: feat/x conflicts with the default branch` with rc=2, and `$P/fetched` exists afterwards. Run on its own from an empty directory, `merge-tree --write-tree` reproduced the mark. The cause is merge-ort's submodule merge, which opens `$GIT_DIR/modules/<name>` and looks up the three gitlink commits there. A missing commit lazily fetches through that repository's promisor remote, and the command in its `uploadpack` runs. The state gate reads only the superproject's `config` and `config.worktree` (`:184-192`), so this configuration is not refused. The pairs do not switch it off either.

**Evidence:** `scripts/build-loop.sh:153`, `scripts/build-loop.sh:181-200`, `scripts/build-loop.sh:444-453`; `$S/logs/P1-submodule-promisor.txt` (cmd `bash $S/q2-VDL0/run.sh`, cwd `$S/q2-VDL0`, exit 0, `--check` rc=2, 2026-10-08T18:33:27Z)

---

## Claim 6: "a read of an object the clone lacks fetches it from the promisor remote, which runs that remote's transport (remote.*.uploadpack, core.sshCommand and the like), and git 2.39 has no switch for it"

**Location:** `scripts/build-loop.sh:172-175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lazy fetch through `remote.*.uploadpack` (core.sshCommand was not run) and the missing `--no-lazy-fetch` in 2.39.5. Does not establish the version that added GIT_NO_LAZY_FETCH (Claim 8).
**Legibility-target:** for-author

P3: with the partial-clone keys removed from the regex (`nokeys`), or with the gate moved back after resolve_main (`gateafter`), and main's tip object deleted, `--check` left the upload-pack mark (`nokeys rc=1 fetched=yes`, `gateafter rc=1 fetched=yes`). HEAD gave `rc=2 fetched=no`. P6: `git --no-lazy-fetch version` gives `unknown option: --no-lazy-fetch` on 2.39.5.

**Evidence:** `scripts/build-loop.sh:172-175`; `$S/logs/P3-mutant-upload-pack.txt` (cmd `bash $S/probes.sh`, function p3, exit 0, 2026-10-08T18:34:24Z), `$S/logs/P6-comment-claims.txt`

---

## Claim 7: "With no promisor remote no gate call fetches, so the transport keys themselves are not listed."

**Location:** `scripts/build-loop.sh:175-176`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Holds for the superproject's own object reads: rev-parse, show-ref, ls-tree, cat-file, git grep, rev-list, `git log -G --no-textconv`, for-each-ref and `git config --file` all stay put when the repo has no promisor key (P1, P5). Refuted for merge-tree's submodule merge, which reads a second repository (`.git/modules/<name>`) whose own promisor config the gate does not read. Does not establish whether other in-process subrepository reads exist beyond merge-tree.
**Legibility-target:** for-orchestrator-synthesis

The mechanism ("no promisor remote, no fetch") is right for the repository the gate inspects. The conclusion is wrong because merge-tree's gitlink merge opens a submodule repository that has its own config. The gate never reads that config, so its promisor remote and transport keys are live. P1 ran `remote.origin.uploadpack` from `.git/modules/sm/config` during `--check` after the gate passed. The precondition is that main's history changed a gitlink. The branch can then choose a merge base before that change and move the same gitlink differently. A branch alone cannot create the main side.

Vectors probed that do **not** fetch or run a command, with no promisor key in the superproject (paraphrased — no quote available because these are absences observed across several probe runs; the outputs are in the logs named):
- `objects/info/alternates` pointing at a bare repo that is a partial clone, plus `.promisor` files beside the superproject's packs, with main's tip object missing: no fetch, and the alternate's config is not read (`$S/logs/P5-replace-alternates.txt`, and probe p4 earlier, `$S/p4-*`).
- `core.alternateRefsCommand` with an alternate: it did not run (P5).
- A replace ref to a missing object under a partial clone: the gate's `for-each-ref --format=%(refname)` did not fetch. The default-format `git for-each-ref` did (`files: fetched`), so the `%(refname)`-only format is load-bearing (P5).
- `submodule.recurse=true`, with a promisor submodule under `docs/working/briefs/` on main: `git grep` did not enter it (probe `$S/p3-*`, console only, not re-captured).
- Pager (`core.pager`, `pager.*`): not runnable here, and also not reachable, because the child's stdout is a pipe (`scrub_reexec`, `scripts/lib/dev-cycle-read.sh:115-120`) and every call sits in a command substitution.
- `safe.directory` is read only from protected config. An unsafe repo makes git die, which fails closed.
- Caller environment: trusted by design (`scripts/build-loop.sh:151-153`), so not tested.

**Evidence:** `scripts/build-loop.sh:175-176`, `scripts/build-loop.sh:444-453`; `$S/logs/P1-submodule-promisor.txt`, `$S/logs/P5-replace-alternates.txt` (cmd `bash $S/probes.sh`, function p5, exit 0, 2026-10-08T18:34:31Z)

---

## Claim 8: "(GIT_NO_LAZY_FETCH is 2.44)"

**Location:** `scripts/build-loop.sh:175`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Only the version number. That 2.39.5 lacks the switch is Verified in Claim 6.
**Legibility-target:** for-author

The sandbox has no network egress, and no git 2.44 binary or release notes are available locally (paraphrased — no quote available because the claim is about an external release history). From recollection, `--no-lazy-fetch` and `GIT_NO_LAZY_FETCH` appeared in Git 2.44's release notes. To verify, read Documentation/RelNotes/2.44.0.txt.

**Evidence:** `scripts/build-loop.sh:175`

---

## Claim 9: "--check refuses planted state before any git call reads an object (resolve_main does)." / state_gate "reads nothing through porcelain git"

**Location:** `scripts/build-loop.sh:205-206`, `scripts/build-loop.sh:166-168`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of every git call in a `--check` run, and confirms that the gate's calls read no object (including a replace ref to a missing object under a partial clone). Does not establish anything about modes other than `--check`, which have no gate.
**Legibility-target:** for-automated-gate

P4's call log starts `rev-parse --show-toplevel`, `rev-parse --git-path config`, `config --file ... --no-includes --name-only --get-regexp ...`, `rev-parse --git-path config.worktree|info/attributes|info/grafts`, `for-each-ref --format=%(refname) refs/replace/`. It then continues `symbolic-ref ... origin/HEAD`, `show-ref --verify --hash refs/heads/main`, `rev-parse --verify --quiet <sha>^{commit}`, which are resolve_main and the first object reads. Before the gate, the parent process makes no git call: `scrub_reexec` (`:122`) only re-runs bash, and `harden` (`:161`) comes before line 201. P5: the gate's `for-each-ref` with a dangling replace ref did not fetch.

**Evidence:** `scripts/build-loop.sh:113-122`, `scripts/build-loop.sh:182-206`, `scripts/lib/dev-cycle-read.sh:483-507`; `$S/logs/P4-call-order.txt` (cmd `bash $S/probes.sh`, function p4, exit 0, 2026-10-08T18:34:24Z), `$S/logs/P5-replace-alternates.txt`

---

## Claim 10: "NUL are dropped here (bash would warn on stderr); the NUL check below reads the raw object." with "A failed read answers bad, never working (row 307)."

**Location:** `scripts/build-loop.sh:373-378`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL tip (no stderr, answers bad) and a failed `cat-file` under the script's `set -euo pipefail` (`:111`). Does not establish behavior if marker_kind is ever called without pipefail: it then answers `working`.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:376,382 (excerpt; marker_kind runs :369-396 — read)
  if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
  if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
```

P8: the commit `handoff: re\0ady` gave `bad it holds a NUL byte` with `stderr-bytes=0`. With `cat-file` stubbed to fail, it gave `bad its commit could not be read` under pipefail and `working` without pipefail. The failed-read guarantee therefore rests on line 111's pipefail.

**Evidence:** `scripts/build-loop.sh:111`, `scripts/build-loop.sh:369-396`; `$S/logs/P8-marker-kind.txt` (cmd `bash $S/probes.sh`, function p8, exit 0, 2026-10-08T18:34:25Z)

---

## Claim 11: "merge-tree in a fresh empty directory of the gate's own, against the common git dir (git then takes that empty directory as the work tree), so no checkout's .gitattributes ... sets a merge driver or a union merge (git 2.39 reads one from the current directory even under --work-tree). Prints the result tree; returns 1 on a conflict, 2 when git failed."

**Location:** `scripts/build-loop.sh:436-442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the work-tree choice, the attributes being read from cwd under `--work-tree`, and the return codes. Does not establish anything about submodule repositories that merge-tree opens (Claim 5).
**Legibility-target:** for-author

P6: `git --git-dir=<repo>/.git rev-parse --show-toplevel` run from an empty directory printed that directory. A `.gitattributes` holding `*.txt merge=union` in cwd, with `--work-tree=<repo>`, made a conflicting merge clean (rc=0). From the empty directory, the same merge conflicted (rc=1, stages 2 and 3 listed). The return codes follow `:450-451` (rc>1 or no tree gives 2, rc 1 gives 1).

**Evidence:** `scripts/build-loop.sh:436-453`; `$S/logs/P6-comment-claims.txt`

---

## Claim 12: "--check-branch ... "skip <name>: <reason>" for ... or the default branch, or a branch whose count or date cannot be read (a broken log.* config)."

**Location:** `scripts/dev-cycle.sh:45-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new skip under `log.date=bogus`. Does not establish other ways the count can fail to be read.
**Legibility-target:** for-author

P6: `dev-cycle.sh --check-branch feat/x` under `log.date bogus` printed `skip feat/x: its commit count or date could not be read`, which comes from `scripts/lib/dev-cycle-read.sh:449`: `else echo "skip $a: its commit count or date could not be read"; fi`.

**Evidence:** `scripts/dev-cycle.sh:45-50`, `scripts/lib/dev-cycle-read.sh:436-451`; `$S/logs/P6-comment-claims.txt`

---

## Claim 13: "--no-textconv: -G greps the diff, and a repo-local textconv driver would run."

**Location:** `scripts/lib/dev-cycle-read.sh:421-422`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers textconv: it runs without the flag and not with it, and an ordinary brief's Status commit is unchanged. Does not establish that `-G` ignores other diff-driver settings. A `diff.<driver>.binary=true`, or a `-diff`/`binary` attribute (including one in an untracked checkout `.gitattributes`), makes `-G` skip the blob, so `c` falls back to the last commit that touched the file. No command runs (`diff.x.command` did not run).
**Legibility-target:** for-author

The `notextconv` mutant fails the suite's `--status` textconv test with "textconv ran" (`$S/mutants.txt`). P7 used a brief with a later non-Status edit. With `diff=x` plus textconv and command set, `c` was the brief commit (`45bf...`), the same as with no driver. With `diff.x.binary=true` added, `c` was `15f7... later edit`. Neither `extdiff-ran` nor `textconv-ran` was created. `--status` and `--check` drop `c` (`scripts/build-loop.sh:402`: `read -r _ _ st _ <<<"$out"`), so only `dev-cycle.sh --check-brief` prints the shifted value.

**Evidence:** `scripts/lib/dev-cycle-read.sh:387-424`, `scripts/build-loop.sh:400-402`; `$S/logs/P7-G-driver.txt` (cmd `bash $S/probes.sh`, function p7, exit 0, 2026-10-08T18:34:25Z), `$S/mutants.txt`

---

## Claim 14: check_branch and open_shared comments (branch-wide, unchanged since 93655b47): "and so is a branch whose count or date cannot be read"; "Exit 1 is "none"; any exit above 1 ... fails closed"; anybrief = isbrief or isclosed

**Location:** `scripts/lib/dev-cycle-read.sh:201`, `scripts/lib/dev-cycle-read.sh:426-476`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Confirms that these lines are byte-identical to the 93655b47 text iteration 1 verified (`git diff 93655b47 9e5d92df -- scripts/lib` touches only `:421-422`). It does not re-execute iteration 1's probes.
**Legibility-target:** for-orchestrator-synthesis

`git show 9e5d92df -- scripts/lib/dev-cycle-read.sh` changes only the `git log -G` line and its comment (paraphrased — no quote available because the claim is about the absence of other hunks in the commit diff). The code these comments describe is unchanged, and iteration 1's verdicts (Claims 21-23 there) still apply.

**Evidence:** `scripts/lib/dev-cycle-read.sh:201`, `scripts/lib/dev-cycle-read.sh:426-476`

---

## Claim 15: test "--check refuses a partial clone before any object is read: a promisor remote's upload-pack never runs for a missing object" and its comment "main's tip commit: resolve_main reads it, so the gate must run before resolve_main."

**Location:** `test/scripts/build-loop-check.bats:1352-1365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unfixed orders: both mutants run upload-pack (fetched=yes), and the test fails for both. Does not establish which assertion fails first. In both mutants that is the status/output line (rc=1, "needs a default branch"), so the `fetched` mark is a second, redundant witness rather than the failing line.
**Legibility-target:** for-author

P4 shows that resolve_main's `show-ref --verify` and `rev-parse --verify <sha>^{commit}` are the first reads of main's tip. P3 shows that the plant makes both unfixed orders fetch. `bats -f 'partial clone'` failed in `$S/mut/nokeys` and in `$S/mut/gateafter` and passed at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:1352-1365`; `$S/logs/P3-mutant-upload-pack.txt`, `$S/mutants.txt` (cmd `bats -f 'partial clone' test/scripts/build-loop-check.bats`, cwd each mutant, exit 1 each, 2026-10-08T18:30:31Z)

---

## Claim 16: test "every git call --check makes carries harden's config pairs, core.hooksPath=/dev/null among them"

**Location:** `test/scripts/build-loop-check.bats:1367-1379`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The shim sees every git call that both bash processes make through `PATH` (the parent makes none, and the scrubbed child and the lib inherit `PATH`). `grep -v -- " $kv"` tests whether each call's pair list *contains* the text of `kv`, with `.` as a regex wildcard. It does not test the effective (last-wins) value, and it misses git's own exec-path subprocesses. With no caller pairs in the fixture, containment equals the effective value. A call with no pairs logs an empty line, which `grep -v` prints, so that case fails the test.
**Legibility-target:** for-automated-gate

```bash
# test/scripts/build-loop-check.bats:1376-1378 (excerpt; the test runs :1367-1379 — read)
    for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null; do
        ! grep -v -- " $kv" "$BATS_TEST_TMPDIR/calls" || { echo "a call without $kv"; return 1; }
    done
```

The `noharden` mutant fails this test (empty lines, "a call without core.useReplaceRefs=false"). The dropped hooks test passes under the same mutant (`$S/mutants.txt`: `ok 1 --check runs no hook from .git/hooks`), which bears out "pinned nothing".

**Evidence:** `test/scripts/build-loop-check.bats:1367-1379`; `$S/mutants.txt`

---

## Claim 17: test "--status runs no repo-local textconv driver while it finds a brief's Status commit"

**Location:** `test/scripts/build-loop-check.bats:1381-1388`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The plant (repo `diff.x.textconv` plus an untracked checkout `*.md diff=x`) runs textconv through `git log -G` on main when `--no-textconv` is absent. Does not establish that the test checks which commit was found: `--status` does not print it.
**Legibility-target:** for-author

It passed at HEAD and failed in `$S/mut/notextconv` with "textconv ran" (`$S/mutants.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1381-1388`; `$S/mutants.txt`

---

## Claim 18: commit 9e5d92df: "STATE_KEYS_RE refuses extensions.partialclone and remote.*.promisor; with no promisor remote no gate call fetches, so the transport keys are never read." and Notes: "refusing the partial clone ... follows cc-push.sh's refusal: the gate never fetches when no promisor remote exists."

**Location:** commit 9e5d92df message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The regex change and the cc-push precedent are Verified (`devcontainer-config/cc-push.sh:323-327` refuses `promisor|partialclone`). "the transport keys are never read" / "the gate never fetches" is refuted by P1, which reads a submodule repository's `remote.origin.uploadpack` and runs it.
**Legibility-target:** for-orchestrator-synthesis

Same counterexample as Claims 5 and 7: `$S/logs/P1-submodule-promisor.txt` shows `fetched` after a `--check` whose state gate passed.

**Evidence:** `scripts/build-loop.sh:181`, `devcontainer-config/cc-push.sh:323-327`; `$S/logs/P1-submodule-promisor.txt`

---

## Claim 19: commit 9e5d92df: "--check runs state_gate before resolve_main, its first object read (the function moves above the root setup)."

**Location:** commit 9e5d92df message
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call order (P4) and the move (the definition is now at `:182`, and `ROOT=` is at `:201`). Does not establish anything beyond Claim 9.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:205-207
# --check refuses planted state before any git call reads an object (resolve_main does).
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
```

**Evidence:** `scripts/build-loop.sh:182-207`; `$S/logs/P4-call-order.txt`

---

## Claim 20: commit 9e5d92df Ambers list: A1 "diff-tree still shows a gitlink under diff.ignoreSubmodules=all"; A2 help; A3 wording; A5 "marker_kind drops NULs in its pipe, so bash no longer warns on stderr"; C3 "--status runs no repo-local textconv"

**Location:** commit 9e5d92df message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each item as stated. C3's "no repo-local textconv" was checked against every git call `--status` makes: `git grep` and `cat-file blob` need opt-in flags to use textconv, and the fallback `git log` makes no content diff. The residual diff-driver `binary` effect on `-G` (Claim 13) is not a textconv.
**Legibility-target:** for-author

P6 printed `:160000 160000 aaaa... bbbb... M	sm` under `-c diff.ignoreSubmodules=all diff-tree -r` (A1). A2 is Claim 12, A3 is Claims 2-4 and 11, and A5 is Claim 10. C3 is Claim 17.

**Evidence:** `scripts/build-loop.sh:166-172`, `scripts/dev-cycle.sh:45-50`; `$S/logs/P6-comment-claims.txt`, `$S/logs/P8-marker-kind.txt`

---

## Claim 21: commit 9e5d92df: "Mutants checked: no partial-clone keys, the gate after resolve_main (both let upload-pack run), no harden, no --no-textconv: each fails its test. Suites: build-loop-check 89, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2. 396 code lines against main."

**Location:** commit 9e5d92df message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four mutants (rebuilt independently in scratch copies), the five suite counts and the line count by the stated method. "396" is added plus deleted (346 + 50), not net. `scripts/health-check.sh` was not run.
**Legibility-target:** for-automated-gate

Suites (`TMPDIR=$(mktemp -d /tmp/cfc2u2b-XXXX) bats --jobs 8 <file>`, cwd the worktree, each exit 0, 2026-10-08): 89/89, 19/19, 78/78, 2/2, 2/2 ok. `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` gives `165 42 build-loop.sh`, `2 1 dev-cycle.sh`, `38 7 dev-cycle-read.sh` and `141 0 build-loop-check.bats`, which sum to 346 + 50 = 396.

**Evidence:** `$S/build-loop-check.bats.txt`, `$S/build-loop-read.bats.txt`, `$S/dev-cycle.bats.txt`, `$S/fixture-git-env.bats.txt`, `$S/fixture-hermeticity.bats.txt`, `$S/mutants.txt`, `$S/logs/P3-mutant-upload-pack.txt`

---

## Claim 22: rubric R1 Fixed note: "STATE_KEYS_RE refuses extensions.partialclone and remote.*.promisor, and --check runs the state gate before resolve_main (its first object read). Test: ...; mutants without the keys, or with the gate after resolve_main, both let upload-pack run."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers R1 as reported (the superproject's own partial clone). Does not establish that the underlying invariant, harden's "the state gate refuses" sentence, now holds: the submodule-repository vector (Claim 5) is a separate instance R1's fix does not reach.
**Legibility-target:** for-orchestrator-synthesis

See Claims 6, 15 and 19.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:18`; `$S/logs/P3-mutant-upload-pack.txt`

---

## Claim 23: rubric A1-A5, C1, C3 Fixed notes (including A4 "the shim pins core.hooksPath=/dev/null, which also keeps the unit at 396 lines" and A5 "not pinned by a test, since the NUL marker test lives in build-loop-read.bats")

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:24-28`, `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:34-36`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each note against the code and the probes. For A5, the build-loop-read.bats NUL marker test exists (`test/scripts/build-loop-read.bats:297-301`, `check "skip $B: $n: it holds a NUL byte" nul`), but nothing asserts empty stderr for it. The note says the same.
**Legibility-target:** for-author

A1: P6. A2: Claim 12. A3: Claims 2, 3, 4 and 11. A4: Claim 16. A5: Claim 10. C1: `test/scripts/build-loop-check.bats:1324` (`&& [ "${#lines[@]}" -eq 1 ]`). C3: Claim 17.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:24-36`, `test/scripts/build-loop-read.bats:297-301`, `test/scripts/build-loop-check.bats:1317-1325`

---

## Claim 24: state_gate comment key rationale "merge and diff drivers name commands: driver, textconv, command, external"; "a non-empty info/attributes (it sets merge drivers and union merges for every path), info/grafts, and any ref under refs/replace/ (both rewrite history ...)"

**Location:** `scripts/build-loop.sh:169-180`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these rationale clauses for the files and keys the gate lists. Does not establish that the file list is exhaustive for "change the merge". `.git/shallow` and `objects/info/commit-graph` also bear on history, and `.git/modules/*/` repositories bear on gitlink merges. None of these was probed for a merge change.
**Legibility-target:** for-orchestrator-synthesis

`merge.<driver>.driver`, `diff.<driver>.textconv`, `diff.<driver>.command` and `diff.external` are git's command-valued merge and diff keys, and `merge\.|diff\.` refuses every one (paraphrased — no quote available because the claim maps git's documented keys onto one regex alternative). Iteration 1's Claim 15 executed the info/attributes and grafts checks, and that text is unchanged.

**Evidence:** `scripts/build-loop.sh:169-181`, `scripts/build-loop.sh:193-198`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`scripts/build-loop.sh:153`): "What these pairs cannot switch off, --check's state gate refuses" is still false. A submodule repository under `.git/modules/<name>` with promisor config runs its `uploadpack` command during merge-tree's gitlink merge after the gate passed (P1).
- **Claim 7** (`scripts/build-loop.sh:175-176`): "With no promisor remote no gate call fetches" holds only for the superproject's own reads. merge-tree opens the submodule's repository, whose promisor remote the gate never reads.
- **Claim 18** (commit 9e5d92df message): "the transport keys are never read" / "the gate never fetches when no promisor remote exists". Same counterexample.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- **Claim 8** (`scripts/build-loop.sh:175`): "GIT_NO_LAZY_FETCH is 2.44". Checking it needs Git's 2.44 release notes, and there is no network egress.

## Escalations

- **for-orchestrator-synthesis (security, Claims 5, 7, 18):** a second lazy-fetch path survives the R1 fix. When main's history changed a gitlink and the branch moves the same gitlink, `merge-tree --write-tree` (`scripts/build-loop.sh:449`) opens `$GIT_COMMON_DIR/modules/<name>` (located through `.gitmodules` from the index or HEAD, because the work tree is the empty temp directory). A missing gitlink commit there is lazily fetched through that repository's own `remote.*.promisor` / `uploadpack`. Reproduced end to end with `--check` (P1, `fetched` present, gate passed). Possible closures: the gate also refuses `modules/` under the common dir, or any promisor key in `modules/*/config`, or merge-tree refuses gitlinks (U2b1b's mode rule may already refuse gitlink changes, but merge-tree runs before it). This repo's main has no gitlinks (`git ls-tree -r main | grep -c ^160000` gives 0), so the exposure is for target repos that do. The same subrepository can also change the merge result (a fast-forwardable submodule turns a conflict clean) through objects planted there. That is untested.
- **for-author (Claim 13, residue):** `-G` still honours `diff.<driver>.binary` and `-diff`/`binary` attributes (an untracked checkout `.gitattributes` included). These shift check_brief's Status commit to the fallback "last touch" commit. No command runs. Only `dev-cycle.sh --check-brief` prints that field; `--status` and `--check` discard it. This predates the branch and was not introduced by `--no-textconv`.
- **for-author (Claim 15):** in both partial-clone mutants, the test fails at its status/output assertion before the `fetched` check. The mark is real (P3) but is never the failing line, so a future change that kept exit 2 and still fetched would be caught only by the mark. That works today because the assertions are chained with `&&`.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 9e5d92df` line at the top.
- Answered: yes
- Out of scope: `scripts/health-check.sh` (not run); the hallucination-pattern log (not written, per the brief's write-only-your-report rule; no fabrication found anyway); forged `commit-graph` / `.git/shallow` effects on the merge base (named, not probed).
- Escalate: the submodule-repository lazy fetch (Claims 5, 7, 18).
