Commit: 63ea50e7
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a2 (branch feat/build-loop-u2b1a2)
**Scope:** `git diff feat/build-loop-u2b1a1...HEAD` at 63ea50e7 (scripts/build-loop.sh, test/scripts/build-loop-check.bats), commit 63ea50e7's message, the plan's Script interface and D7 lines, and the U2b1a rubric's Fixed notes (final confirming pass, replicate r2)
**Checked:** 2026-10-08
**Total claims checked:** 31
**Summary:** 23 verified, 3 mostly accurate, 2 stale, 3 incorrect, 0 unverifiable

Execution provenance. Every executed claim ran on git 2.39.5. Raw output and probe scripts are in `/tmp/fcu2b1a2-r2-logs/`, outside the repo, because the brief allows only this report file to be written:
- **Suites:** `TMPDIR=/tmp/fcu2b1a2-r2-tmp-VE22 bats <suite>` for the five suites, cwd the worktree, 2026-10-08T18:58:38Z to 19:00:05Z. Exit 0 each. Output is in `suites.txt` and `<suite>.txt`.
- **Mutants:** `mk.py` copies `scripts/`, `test/lib/` and the suite into `/tmp/fcu2b1a2-r2-mut/mN/` and changes one thing in each copy. The U2b1a tests then ran with `bats -f U2b1a mN/test/scripts/build-loop-check.bats`, about 19:00 to 19:01Z (`mutants.txt`, `mutants-partial.txt`).
  - m1: merge-tree in the real repo, from ROOT.
  - m2: m1 with GIT_ALLOW_PROTOCOL removed.
  - m3: state_gate after resolve_main.
  - m4: no `harden` call.
  - m5: no objectformat line.
  - m7: no GIT_ALLOW_PROTOCOL.
  - m8: no core.commitGraph pair.
  - m9: no partial-clone keys.
  - m10: m3 with no GIT_ALLOW_PROTOCOL.
- **Probes:** these scripts ran with `bash`, each in its own mktemp repo, from 2026-10-08T19:01Z to 19:04Z. Exit 0 each.
  - `sub.sh` and `sub2.sh` → `probe-submodule*.txt`
  - `gate-sub.sh` → `probe-gate-submodule.txt`
  - `misc.sh` → `probe-misc.txt`
  - `noobj.sh` → `probe-noobj.txt`
  - `env.sh` → `probe-env.txt`

I compared these claims against `docs/reviews/hallucination-patterns.md`. The suite-count entries ("85 tests" vs 97, "mode1-equiv 33" vs 25) match the shape of Claim 30. Its counts were executed and match.

---

## Claim 1: R2 Fixed note, the code half: "merge_result runs in a gate-owned repository (`gate_repo`, once per run): a git dir with no config but the repo's object format, no modules/, info/ or shallow, run from an empty directory, with GIT_OBJECT_DIRECTORY the real store and the repo-local variables unset. The moved gitlink is now a conflict."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gate_repo's layout and that a gitlink moved on both sides from a common base is a conflict with no submodule fetch. It holds even with GIT_ALLOW_PROTOCOL removed (m7). It does not cover the note's test sentence, which is Claim 2.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:448-457
gate_repo() {
  local fmt v
  GATE_ENV=(env)
  for v in $(git rev-parse --local-env-vars); do [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v"); done
  v="$(git rev-parse --path-format=absolute --git-path objects)" && fmt="$(git rev-parse --show-object-format)" \
    && [[ "$fmt" == sha1 || "$fmt" == sha256 ]] && mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work" || return 1
  printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"
  printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"
  GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")
}
```

`gate-sub.sh` builds a plant where the merge base already holds the gitlink (aaaa…), main moves it to cccc… and feat/x moves it to bbbb…. `.git/modules/sm` is a promisor repository whose uploadpack runs `touch $P/fetched`. Results:

| Script | Output | Fetch |
|---|---|---|
| Unmodified | `refuse …: feat/x conflicts with the default branch`, rc=2 | `fetched=no` |
| m7 (no GIT_ALLOW_PROTOCOL) | the same conflict | `fetched=no` |
| m2 (real repo, protocol allowed) | the same conflict | `fetched=yes` |

So the gate repository, not the protocol block, is what keeps the submodule repository closed.

**Evidence:** `scripts/build-loop.sh:448-467`; `/tmp/fcu2b1a2-r2-logs/probe-gate-submodule.txt` (cmd `bash gate-sub.sh <script>`, cwd `/tmp/fcu2b1a2-r2-p`, exit 0, 2026-10-08T19:01:52Z)

---

## Claim 2: R2 Fixed note, the test half: "Test: the P1 plant (mutant running merge-tree in the real repo fetches)." The iteration-2 summary line says the same: "Mutants: merge-tree in the real repo (submodule and union tests fail)".

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`, `:48`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the submodule test as committed at 63ea50e7, which matches c66988b6 (`git diff c66988b6 HEAD -- test` is empty). The union-test half of line 48 is true (Claim 3). This does not say the code is wrong; Claim 1 shows it is right.
**Legibility-target:** for-orchestrator-synthesis

Under mutant m1 (merge-tree run in the real repo from ROOT), the test `--check's merge opens no submodule repository…` passes. It also passes under m2, which is m1 with GIT_ALLOW_PROTOCOL removed (`mutants.txt`: `ok 11` for both). The cause is in the test's plant:

```bash
# test/scripts/build-loop-check.bats:1398-1399 (excerpt ends :1399; the test continues to :1409 — read)
    git update-index --add --cacheinfo "160000,$s1,sub"; commit_all sub1
```

`commit_all` is `git add -A && git commit …` (`test/lib/build-loop-fixtures.bash:28`). With no `sub` directory in the work tree, `add -A` stages the gitlink's removal, so commit sub1 carries only `.gitmodules`. My replica of the plant shows this: `mb=d2b9c6a…` with an empty `git ls-tree $mb sub` (`probe-submodule.txt`). Both sides then add `sub`, and merge-tree reports `Failed to merge submodule sub (no merge base)` before it opens any submodule repository. That holds in the real repo even with transport allowed (`rc=1 fetched=no`, all four ways).

When the gitlink is committed at the base (`sub2.sh`, `git add .gitmodules` in place of `add -A`), the real-repo merge-tree fetches (`rc=141 fetched=yes`). So the test as written cannot fail for the regression R2 fixed.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1409`, `test/lib/build-loop-fixtures.bash:28`; `/tmp/fcu2b1a2-r2-logs/mutants.txt`, `/tmp/fcu2b1a2-r2-logs/probe-submodule.txt`, `/tmp/fcu2b1a2-r2-logs/probe-submodule-fixed-plant.txt` (cmds `bash sub.sh`, `bash sub2.sh`, cwd `/tmp/fcu2b1a2-r2-p`, exit 0, about 2026-10-08T19:01Z)

---

## Claim 3: iteration-2 "Tests and mutants" line, the other mutants: "no objectformat (SHA-256 test), no GIT_ALLOW_PROTOCOL (shim), no shallow (state test). Suites 91/19/78/2/2."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these mutants:

| Mutant | Test that fails |
|---|---|
| m5 | SHA-256 test (`not ok 12`) |
| m7 | shim test (`not ok 9`) |
| m1 | union test (`not ok 2`) |

The suite counts are covered too. The no-shallow mutant was not run: the state test asserts the exact line `refuse state shallow: present and not empty` (`:1337-1341`), so it would fail by construction. This does not cover the submodule mutant (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

The mutant results are in `mutants.txt`. The suite counts from `suites.txt`:

| Suite | Result |
|---|---|
| build-loop-check | 91 ok |
| build-loop-read | 19 ok |
| dev-cycle | 78 ok |
| fixture-git-env | 2 ok |
| fixture-hermeticity | 2 ok |

Each suite exited 0.

**Evidence:** `test/scripts/build-loop-check.bats:1315-1342`, `:1411-1416`; `/tmp/fcu2b1a2-r2-logs/mutants.txt`, `/tmp/fcu2b1a2-r2-logs/suites.txt`

---

## Claim 4: R1 Fixed note: "Test: a promisor remote whose upload-pack leaves a mark, main's tip commit deleted; mutants without the keys, or with the gate after resolve_main, both let upload-pack run."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:60`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named mutants against the code at 63ea50e7. The fix itself is true: the keys are in STATE_KEYS_RE and the gate runs before resolve_main. This does not say whether the note was true at 9e5d92df. It plausibly was, since GIT_ALLOW_PROTOCOL arrived in iteration 2.
**Legibility-target:** for-orchestrator-synthesis

Neither mutant lets upload-pack run at 63ea50e7:

| Mutant | Test result | Upload-pack ran? |
|---|---|---|
| m9 (no partial-clone keys) | fails on its output: `build-loop.sh needs a default branch found by name …` | no |
| m3 (gate after resolve_main) | passes | no |
| m10 (m3 plus no GIT_ALLOW_PROTOCOL) | fails | yes (`# upload-pack ran`) |

`GIT_ALLOW_PROTOCOL=none` (`scripts/build-loop.sh:166`) now blocks the fetch in both of the note's mutants. See Claim 27 for what this means for the test.

**Evidence:** `scripts/build-loop.sh:166`, `:180`, `:209`; `/tmp/fcu2b1a2-r2-logs/mutants-partial.txt` (cmd `bats -f 'partial clone' mN/test/scripts/build-loop-check.bats`, cwd `/tmp/fcu2b1a2-r2-mut`, about 2026-10-08T19:03Z)

---

## Claim 5: the other Fixed notes (R3, R4, A1, A3, A4, A5, A6, A7, A8, A9 partly, A10, A14, C1, C3, C4)

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:17-33`, `:60-79`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each note's description of the code at 63ea50e7, as listed below. It does not re-run the iteration-1 probes, and it does not cover C11 (Claim 6). A4 says "all four" pairs; there are now five, plus G and P, all asserted. That is a superset, not a mismatch.
**Legibility-target:** for-orchestrator-synthesis

- **R3:** the origin/HEAD refusal is at `scripts/build-loop.sh:198-201` and is tested.
- **R4:** `GIT_CONFIG_GLOBAL=/dev/null` is at `:166`. The shim asserts `G=/dev/null` on every call, and m7 fails it.
- **A6:** the `shallow` file is in the gate's file loop, `for f in info/attributes info/grafts shallow; do` (`:192`).
- **A7:** the `core.commitGraph=false` pair is at `:160`. m8 fails the shim test, and a garbage commit-graph is never read (`probe-misc.txt`: the control gives `error: commit-graph file is too small`; `--check` stays silent).
- **A8:** the gate git dir's config holds only the format lines (`:455`).
- **A10:** no comment now says a fetch needs a promisor remote.
- **A14:** the plan lines (Claims 7 and 8).
- **C4:** `refuse state $f: its path could not be read` uses `f` as the name and `p` as the path.
- **A1:** the comment reads "filter, merge and diff drivers (commands)".
- **A3:** the help refuse list, the objects-and-temp-dir sentence and "an empty directory to run in".
- **A5:** `tr -d '\000'` in marker_kind.
- **C1:** `[ "${#lines[@]}" -eq 1 ]` at `test/…:1324`.
- **C3:** `--no-textconv` in check_brief.

paraphrased — no quote available because the claim spans fifteen notes and their sites; the bullets above name each site.

**Evidence:** `scripts/build-loop.sh:158-166`, `:180-202`, `:455`, `scripts/lib/dev-cycle-read.sh:422`; `/tmp/fcu2b1a2-r2-logs/mutants.txt`, `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 6: C11: "Global and system config apply to the gate repository; an inherited GIT_COMMON_DIR undoes it." Status: "Fixed: GIT_CONFIG_GLOBAL for all calls; GATE_ENV unsets the repo-local variables."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:46`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global-config half and the GIT_COMMON_DIR half, both fixed. The system-config half of the finding is not fixed, and the status does not say so. This does not establish that a loop can write the system config: there is no `/etc/gitconfig` here, its location is root's, and GIT_CONFIG_SYSTEM is caller environment.
**Legibility-target:** for-orchestrator-synthesis

Nothing sets GIT_CONFIG_NOSYSTEM: the export line is `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_ALLOW_PROTOCOL=none` (`scripts/build-loop.sh:166`). GATE_ENV keeps every inherited variable it does not `-u`.

GIT_COMMON_DIR is in `git rev-parse --local-env-vars` (probed), so GATE_ENV unsets it.

A system `core.attributesFile` pointing at `* merge=union` did not change the result: `--check` still refused with a conflict (`probe-misc.txt`, "P-sys"). That is because the pair outranks it. Other system keys, such as `merge.directoryRenames`, are not switched off.

A precise status would read: "Fixed for global config and GIT_COMMON_DIR; system config still applies (root-owned)."

**Evidence:** `scripts/build-loop.sh:166`, `:451`; `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 7: plan Script interface: "`--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`)" and "`--check` … Output (U2b1a): `refuse state WHAT: WHY` lines (exit 2 before any brief), then per brief `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`; U2b1b adds per-path lines and must make the exit status 'every line ok'."

**Location:** `docs/working/plan-build-loop-handoff.md:207`, `:212`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `--check` grammar against check_line and state_gate, and the `--state` grammar against state_gate's output. It does not establish `--state` itself (not built; U3b) or the rest of the plan's U2b1b duty.
**Legibility-target:** for-orchestrator-synthesis

State lines are `echo "refuse state $line: set in $f, …"` (`scripts/build-loop.sh:189`). The per-brief lines are `ok $a $sha $tree`, `refuse $a: …`, or status_line's skip passed through (`:472-496`). The exit is `[[ "$fails" -eq 0 ]] || exit 2` (`:508`). These amendments landed in U2b1a1 (ae08688c), not in this unit's diff.

**Evidence:** `scripts/build-loop.sh:181-209`, `:470-509`

---

## Claim 8: D7: "All git calls are hardened, with a state gate after `devcontainer-config/install.sh`'s `git_state_gate`."

**Location:** `docs/working/plan-build-loop-handoff.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path and the function name: `devcontainer-config/install.sh` is tracked and defines `git_state_gate() {` at `:209`. It does not establish that the two gates refuse the same set; the build-loop gate is a superset (partial clone, shallow, origin/HEAD and others).
**Legibility-target:** for-author

`git ls-files devcontainer-config/install.sh` prints the path. The script has `# git_state_gate: exit the script, naming each entry, when the checkout's own git` (`devcontainer-config/install.sh:193`).

**Evidence:** `devcontainer-config/install.sh:193-212`

---

## Claim 9: plan U2b1a bullet: "merge-tree run from a fresh empty directory against the common git dir"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge-tree sentence of the 281 bullet. Its harden and state-gate lists are also short of the code: there is no commit-graph, GLOBAL or protocol, and no partial clone, shallow or origin/HEAD. The bullet is dated "before code". Line 282 records the split but not this change.
**Legibility-target:** for-author

merge-tree now runs against a gate-owned git dir, `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`scripts/build-loop.sh:456`). It no longer runs against the common git dir.

**Evidence:** `scripts/build-loop.sh:448-467`

---

## Claim 10: --check help, the state gate list: "a git config key (common config or config.worktree, includes not followed) for a filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.*, log.showSignature, extensions.partialClone or remote.*.promisor (a partial clone), a non-empty info/attributes or info/grafts, or a replace ref prints "refuse state WHAT: WHY" per finding and exits 2 before any brief is read."

**Location:** `scripts/build-loop.sh:78-85`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every item listed, the line format and exit 2 before any brief. The list omits two refusals the code makes: a non-empty `shallow` file, and an origin/HEAD naming anything but origin/main or origin/master. Both are tested and both appear in the state_gate comment and the commit message.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:192-201 (excerpt ends :201; state_gate continues to :202 — read)
  for f in info/attributes info/grafts shallow; do
  ...
  if [[ "$rc" -gt 1 ]] || [[ -n "$p" && "$p" != refs/remotes/origin/main && "$p" != refs/remotes/origin/master ]]; then
    echo "refuse state origin/HEAD: it names a branch other than origin/main or origin/master"; bad=1
```

A precise version adds ", a non-empty shallow, an origin/HEAD naming any branch but origin/main or origin/master". In `noobj.sh` the help's items printed one line each and exited 2 (`probe-noobj.txt`).

**Evidence:** `scripts/build-loop.sh:78-85`, `:181-202`; `/tmp/fcu2b1a2-r2-logs/probe-noobj.txt`

---

## Claim 11: --check help, the ok, refuse and skip lines: "ok BRIEF TIP TREE … TREE is the merge of TIP into main as merge-tree writes it, run where no checkout's attributes are read"; refuse "The brief is done, dropped or new on main, its branch is absent or not ahead, it moved or could not be read again after --status read it, TIP is not SHA, the merge conflicts, or the merge could not be computed"; "skip BRIEF: WHY As --status skips it."

**Location:** `scripts/build-loop.sh:86-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refuse reason against check_line's branches (all seven exist), the ok fields, and skip pass-through from status_line. The help's ordering is not the code's: "not ahead" is tested after the re-read. The list does not claim an order.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:470-496 (whole function, check_line)
  out="$(status_line "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
  ...
  if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st on the default branch; only an open brief merges"; return; fi
  if [[ "$loop" == absent ]]; then echo "refuse $a: its branch $br does not exist"; return; fi
  ...
  if [[ "$out" != "ok $br $sha "* || ! "$n" =~ ^$DIGIT+$ ]]; then echo "refuse $a: its branch $br moved or could not be read again"; return; fi
  if [[ "$n" -eq 0 ]]; then echo "refuse $a: its branch $br has no commit the default branch lacks"; return; fi
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
  tree="$(merge_result "$sha")" || rc=$?
```

How each part was checked:
- **Field positions:** `read -r _ _ st _ br loop sha _` matches status_line's `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"`.
- **Executed:** T16, T17 and T18 pass.
- **The XDG `merge=union` attributes file:** it does not reach the merge, because `--check` still refuses with a conflict (`probe-misc.txt`).
- **"could not be computed":** with a blob missing from the store, `--check` printed `refuse …: the merge of feat/x could not be computed` (`probe-misc.txt`, "without alternates").

**Evidence:** `scripts/build-loop.sh:461-496`; `/tmp/fcu2b1a2-r2-logs/suites.txt`, `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 12: "Writes nothing but --check's merge objects (merge-tree writes the merged trees and blobs into the object store) and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:102-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one conflicting `--check` run, measured by a snapshot of the repo directory's sizes and mtimes. It does not cover the `--settings` and `--status` modes, which write no objects, or other runs' paths, such as an object-freshening write on a clean merge.
**Legibility-target:** for-author

The snapshot diff in `probe-misc.txt` ("P-writes") shows two lines, both loose objects freshened by merge-tree:

```
changed …/repo/.git/objects/37/594f…
changed …/repo/.git/objects/4b/9a39…
```

`tmp left: []` shows the temporary directory is gone. The trap is `trap 'rm -rf -- "$GATE_TMP"' EXIT` (`scripts/build-loop.sh:502`).

**Evidence:** `scripts/build-loop.sh:499-509`; `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 13: "Exit: 0 every line printed (or help), and for --check every line ok; 2 any --check line or the state gate not ok; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:107-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the observed exits:
- 0 on an all-ok run;
- 2 on a refusal, a skip or the state gate;
- 1 on usage (T17);
- 1 on "Not inside a git repository" and on no default branch (`probe-misc.txt`, `probe-noobj.txt`).

A failed gate_repo also exits 2 (`:503`), which falls under "state gate". The no-perl and no-lib exits were not run; they are pre-existing.
**Legibility-target:** for-author

The loop is `[[ "$out" == "ok "* ]] || fails=1` … `[[ "$fails" -eq 0 ]] || exit 2` (`scripts/build-loop.sh:506-508`). The state gate's exit is `if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` (`:209`).

**Evidence:** `scripts/build-loop.sh:209`, `:499-509`; `/tmp/fcu2b1a2-r2-logs/suites.txt`, `/tmp/fcu2b1a2-r2-logs/probe-noobj.txt`

---

## Claim 14: harden: "Every git call in this process, the lib's included, runs hardened. Config pairs outrank the repo's config: main's own objects (core.useReplaceRefs in the repo's config would override GIT_NO_REPLACE_OBJECTS), no hook, no fsmonitor command, no core.attributesFile …"

**Location:** `scripts/build-loop.sh:147-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these:
- Every `git` that `--check` runs through PATH carries the five pairs and both exports: shim test, more than 10 calls logged. m4, m7 and m8 each fail it.
- harden runs before any git call in the child: argument parsing makes none.
- The replace-ref override exists and the pair beats it.

It does not establish the claim for calls made by absolute path; none exist.
**Legibility-target:** for-orchestrator-synthesis

`env.sh` gives:

| Setting | Result |
|---|---|
| `NO_REPLACE env` | `a` |
| `NO_REPLACE + repo useRR=true` | `b` (repo config re-enables replace refs) |
| `+ count pair false` | `a` |

The harden loop is `for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false; do` (`:160`), and `harden` is called at `:165`, before `:166`'s exports and every git call.

**Evidence:** `scripts/build-loop.sh:158-166`, `test/scripts/build-loop-check.bats:1371-1383`; `/tmp/fcu2b1a2-r2-logs/probe-env.txt`, `/tmp/fcu2b1a2-r2-logs/mutants.txt`

---

## Claim 15: "no commit-graph (a forged one changes merge bases)"

**Location:** `scripts/build-loop.sh:150-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the fact that no `--check` call reads `objects/info/commit-graph`. A garbage graph makes `git -c core.commitGraph=true log` print `error: commit-graph file is too small`, while `--check` prints only its refuse line. The pair is on every call (shim, m8). It does not establish the rationale clause (a forged graph changes merge bases). That rests on iteration-2 security F5's probe, which I did not repeat. GIT_TEST_COMMIT_GRAPH in the caller's environment could override the pair (caller trusted).
**Legibility-target:** for-orchestrator-synthesis

The pair is `core.commitGraph=false` (`scripts/build-loop.sh:160`). The probe output is in `probe-misc.txt`, under "P-cg".

**Evidence:** `scripts/build-loop.sh:160`; `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 16: "GIT_CONFIG_GLOBAL=/dev/null: a loop can write the user's ~/.gitconfig as easily as .git/config."

**Location:** `scripts/build-loop.sh:151-152`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export on every call: the shim asserts `G=/dev/null`. With GIT_CONFIG_GLOBAL set, git reads neither `~/.gitconfig` nor `$XDG_CONFIG_HOME/git/config`. It does not cover system config (Claim 6).
**Legibility-target:** for-author

The export is `GIT_CONFIG_GLOBAL=/dev/null` (`scripts/build-loop.sh:166`). Relatedly, a `* merge=union` file at both `$XDG_CONFIG_HOME/git/attributes` and `~/.config/git/attributes` turned the conflict clean for plain `git merge-tree` (`control rc=0`). `--check` still refused (`probe-misc.txt`, "P-xdg"), because the `core.attributesFile=/dev/null` pair replaces the XDG default.

**Evidence:** `scripts/build-loop.sh:160`, `:166`; `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 17: "GIT_ALLOW_PROTOCOL=none: no transport at all, so a lazy fetch (a partial clone's missing object) fails however the config was planted, even after the state gate read it."

**Location:** `scripts/build-loop.sh:152-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file and https transports. A planted submodule promisor fetched under real-repo merge-tree only when the variable was absent (`fetched=yes` without it; `fatal: transport 'file' not allowed`, `fetched=no` with it). `GIT_ALLOW_PROTOCOL=none git fetch` over https printed `fatal: transport 'https' not allowed`. m10 vs m3 shows the same for the superproject's own partial clone. ssh and ext were not probed; ext is off by default.
**Legibility-target:** for-orchestrator-synthesis

The export is at `scripts/build-loop.sh:166`: `… GIT_CONFIG_GLOBAL=/dev/null GIT_ALLOW_PROTOCOL=none`.

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r2-logs/probe-submodule-fixed-plant.txt`, `/tmp/fcu2b1a2-r2-logs/probe-env.txt`, `/tmp/fcu2b1a2-r2-logs/mutants-partial.txt`

---

## Claim 18: "The caller's own environment is trusted: its `git -c` or a zero-padded GIT_CONFIG_COUNT can still win (U3b's --state). What the rest cannot switch off, --check's state gate refuses."

**Location:** `scripts/build-loop.sh:154-157`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the `git -c` precedence: `-c core.hooksPath=/x` beats the count pair, printing `/x`. It also covers the gate's refusal of every state the iteration-1 and iteration-2 probes named. It does not establish completeness. Two pieces of state are neither switched off nor refused: system config (Claim 6), and `objects/info/alternates`, which every call reads, merge-tree in the gate repo included. A blob present only through a planted alternates file made the merge computable: "could not be computed" without it, a normal conflict with it. Alternates can only supply objects whose ids are not in the local store, so its exposure is the same as the deferred security F3 (rewritten object bytes, override-log row 492). Packs and multi-pack-index belong to the same class and were not probed.
**Legibility-target:** for-orchestrator-synthesis

The state gate's files loop covers `info/attributes info/grafts shallow` only (`scripts/build-loop.sh:192`). No line reads `objects/info/alternates`. paraphrased — no quote available because the claim covers absence of code (`rg -n alternates scripts/build-loop.sh` finds only none).

**Evidence:** `scripts/build-loop.sh:181-202`; `/tmp/fcu2b1a2-r2-logs/probe-env.txt`, `/tmp/fcu2b1a2-r2-logs/probe-misc.txt` ("P-alt")

---

## Claim 19: state_gate comment: "Prints one 'refuse state WHAT: WHY' line per finding, returns 1 on any, and reads no object (git config --file --no-includes follows no include; --git-path reads no index)." And at the call site: "--check refuses planted state before any git call reads an object (resolve_main does)."

**Location:** `scripts/build-loop.sh:167-170`, `:208-209`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an empty object store, with every object moved out and refs packed. state_gate ran to completion, printed its four findings (filter key, info/attributes, a replace ref, a foreign origin/HEAD) with no git error, and exited 2. With nothing planted it passed, and resolve_main then failed (rc=1). The call order is static: `:209` precedes `resolve_main` at `:210`. This does not cover the early-return paths: an unreadable `--git-path` or for-each-ref returns 1 after one line, not "one line per finding".
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:208-210
# --check refuses planted state before any git call reads an object (resolve_main does).
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
```

**Evidence:** `scripts/build-loop.sh:181-210`; `/tmp/fcu2b1a2-r2-logs/probe-noobj.txt` (cmd `bash noobj.sh`, cwd `/tmp/fcu2b1a2-r2-p`, exit 0, about 2026-10-08T19:03Z)

---

## Claim 20: state_gate comment, the key and file list: "Keys, in the common config and this worktree's config.worktree: filter, merge and diff drivers (commands), config hooks, includes, core.attributesFile, gpg and log.showSignature (gpg.program runs), and a partial clone (extensions.partialClone, remote.*.promisor …). Files: a non-empty info/attributes, info/grafts or shallow …, a ref under refs/replace/, and an origin/HEAD …"

**Location:** `scripts/build-loop.sh:170-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed key and file. T26 plants each key in config, one in config.worktree, and each file, and gets one line each. The `--name-only` keys are lower-cased, which the regex matches. Two notes on breadth: the regex also refuses core.fsmonitor and core.hooksPath, which harden switches off anyway; and `merge.` and `diff.` refuse every key in those sections, not only drivers. Two narrower details: a symlink or non-regular entry at a file path is refused even when empty, with the message "present and not empty"; and config.worktree is read whether or not `extensions.worktreeConfig` is set.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:180
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
```

**Evidence:** `scripts/build-loop.sh:180-202`, `test/scripts/build-loop-check.bats:1315-1342`; `/tmp/fcu2b1a2-r2-logs/build-loop-check.bats.txt`

---

## Claim 21: "an origin/HEAD naming any branch but origin/main or origin/master (resolve_main would take the default branch from it)"

**Location:** `scripts/build-loop.sh:177-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers resolve_main's first candidate. It also covers that the two allowed targets resolve to the same local branches as the fallbacks. A non-symbolic origin/HEAD passes the gate (`symbolic-ref -q` exits 1); resolve_main also ignores it.
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:486-488 (excerpt ends :488; resolve_main continues to :507 — read)
  origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  [[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")
  candidates+=(main master)
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:483-507`, `scripts/build-loop.sh:198-201`

---

## Claim 22: gate_repo comment: "a git dir with no config but the repo's object format, no modules/, info/ or shallow, and an empty directory to run in, so merge-tree reads none of the repo's config (a submodule repository under .git/modules is never opened), no checkout's .gitattributes (git 2.39 reads one from the current directory even under --work-tree), and only the repo's object store (GIT_OBJECT_DIRECTORY, where it also writes). GATE_ENV unsets the repo-local variables (GIT_COMMON_DIR and the like) that would point it back."

**Location:** `scripts/build-loop.sh:439-446`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Each part was checked as listed below. Not established: (a) "only the repo's object store" includes that store's `info/alternates`, which merge-tree follows (Claim 18; F3 class); (b) system config still applies (Claim 6); (c) the "--work-tree" wording was not probed directly. The union test shows the current-directory read in the real repo (m1 fails it).
**Legibility-target:** for-orchestrator-synthesis

- **No repo config and no submodule repository:** the fixed submodule plant does not fetch, even with protocol allowed (Claim 1).
- **No checkout attributes:** the union test fails under m1.
- **Object format kept:** the SHA-256 test fails under m5.
- **Repo-local variables unset:** GATE_ENV `-u`s every name from `git rev-parse --local-env-vars` except `GIT_CONFIG*` and `GIT_NO_REPLACE_OBJECTS`. That list holds GIT_COMMON_DIR, GIT_DIR, GIT_INDEX_FILE, GIT_ALTERNATE_OBJECT_DIRECTORIES, GIT_GRAFT_FILE and GIT_SHALLOW_FILE (probed).
- **Writes to the real store:** the freshened loose objects in Claim 12.

The quoted code is in Claim 1 (`scripts/build-loop.sh:448-457`).

**Evidence:** `scripts/build-loop.sh:439-467`; `/tmp/fcu2b1a2-r2-logs/probe-gate-submodule.txt`, `/tmp/fcu2b1a2-r2-logs/mutants.txt`, `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 23: merge_result: "prints the result tree; returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable), 2 when git failed."

**Location:** `scripts/build-loop.sh:458-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rc 0 (T16 ok), rc 1 (conflicts, including the both-sides-moved gitlink in `gate-sub.sh`) and rc 2. For rc 2, a missing blob produced "could not be computed". It does not establish rc 2 for every git failure shape. Any first line that is not a hash, or an exit above 1, maps to 2.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:461-467 (whole function)
merge_result() {
  local out rc=0
  out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
  echo "${out%%$'\n'*}"
}
```

**Evidence:** `scripts/build-loop.sh:461-467`; `/tmp/fcu2b1a2-r2-logs/probe-gate-submodule.txt`, `/tmp/fcu2b1a2-r2-logs/probe-misc.txt`

---

## Claim 24: T16 test title: "--check: a clean merge is ok with the tip and the merged tree; main's later commits are merged, not judged; a conflict refuses (T16, U2b1a)"

**Location:** `test/scripts/build-loop-check.bats:1256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact ok line, with TREE compared to a direct `git merge-tree`, after main moves on, and the exact conflict refusal. It does not cover rc 2 ("could not be computed"), which no test plants.
**Legibility-target:** for-author

The test asserts `[ "$output" = "ok $B $t $(git merge-tree --write-tree main feat/x)" ]` and then `"refuse $B: feat/x conflicts with the default branch"` (`:1259-1263`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1256-1264`; `/tmp/fcu2b1a2-r2-logs/build-loop-check.bats.txt`

---

## Claim 25: union test title: "--check's merge reads no checkout attributes: an untracked .gitattributes, or one planted in .git, cannot turn a conflict into a union merge (U2b1a)"

**Location:** `test/scripts/build-loop-check.bats:1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both plants. The test fails under m1 (merge-tree in the real repo from ROOT) and m2. It does not separate the two plants: either alone could trip the mutant.
**Legibility-target:** for-author

The plants are `printf '* merge=union\n' > .gitattributes` and `> .git/.gitattributes` (`:1269-1270`). The test asserts the conflict line, and `mutants.txt` shows `not ok 2` for m1 and m2.

**Evidence:** `test/scripts/build-loop-check.bats:1266-1273`; `/tmp/fcu2b1a2-r2-logs/mutants.txt`

---

## Claim 26: T17, T18, T26 and T20 test titles

The four titles in full:
- **T17:** "--check --expect: the tip's full id passes in either order; a stale id refuses; a short id, a name, HEAD, upper case, no value, a second --expect or two briefs are usage errors"
- **T18:** "--check refuses a brief done, dropped or new on main, a branch absent or not ahead; skips what --status skips; answers each brief and exits 2 on any refusal"
- **T26:** "--check's state gate refuses each planted git state that can run a command or change the merge, before reading any brief"
- **T20:** "build-loop.sh and the reader lib never push"

**Location:** `test/scripts/build-loop-check.bats:1275`, `:1295`, `:1315`, `:1351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what each body asserts against its title. All four pass.
- T17 asserts each listed case, with exit 1, empty stdout and the usage text.
- T18 asserts each refusal's exact text, the three-brief output in order with exit 2, and the F31 skip.
- T26 asserts each of the 16 keys, the config.worktree key, and the five file and ref lines. For each key it asserts exactly one output line, so no brief line follows.
- T20 is a word grep for "push" over the two files.

T26's "before reading any brief" is asserted only as the absence of a brief line; ordering against resolve_main is Claim 27's subject.
**Legibility-target:** for-author

From T26: `[ "$status" -eq 2 ] && [[ "$output" == "refuse state "*": set in config, …" ]] && [ "${#lines[@]}" -eq 1 ]` (`:1323-1324`).

**Evidence:** `test/scripts/build-loop-check.bats:1275-1354`; `/tmp/fcu2b1a2-r2-logs/build-loop-check.bats.txt`

---

## Claim 27a: partial-clone test title, its refusal and no-fetch clauses: "--check refuses a partial clone … a promisor remote's upload-pack never runs for a missing object"

**Location:** `test/scripts/build-loop-check.bats:1356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact two-line refusal, exit 2 and the absent mark. m9 (no keys) fails the test. It does not cover the ordering clause (27b).
**Legibility-target:** for-author

The test asserts the two `refuse state` lines and `[ ! -e "$BATS_TEST_TMPDIR/fetched" ]` (`:1366-1369`).

**Evidence:** `test/scripts/build-loop-check.bats:1356-1369`; `/tmp/fcu2b1a2-r2-logs/mutants-partial.txt`

---

## Claim 27b: partial-clone test title, its ordering clause: "… before any object is read". The test's comment adds: "main's tip commit: resolve_main reads it, so the gate must run before resolve_main."

**Location:** `test/scripts/build-loop-check.bats:1356`, `:1363`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test detects the gate running after resolve_main. It does not. The code's ordering is right (Claim 19); only the test's power is at issue.
**Legibility-target:** for-orchestrator-synthesis

Under m3, where state_gate moves after `resolve_main`, the test passes (`mutants-partial.txt`: `ok 1`). Two things combine:
- resolve_main's failed read of the missing commit is blocked, not fetched: `GIT_ALLOW_PROTOCOL=none`.
- resolve_main then falls back to the current branch, which sets MAIN_SHA. The gate's later two-line refusal is identical, so the test sees no difference.

The test fails only when GIT_ALLOW_PROTOCOL is also removed (m10: `upload-pack ran`). The ordering is therefore pinned by nothing in the suite. A test that sees an object read before the gate (an unreadable store with a planted key, as in `noobj.sh`, run under m3) would pin it.

**Evidence:** `test/scripts/build-loop-check.bats:1356-1369`, `scripts/build-loop.sh:209-210`, `scripts/lib/dev-cycle-read.sh:497-505`; `/tmp/fcu2b1a2-r2-logs/mutants-partial.txt`

---

## Claim 28: shim test title: "every git call --check makes carries harden's config pairs (core.hooksPath=/dev/null among them), no global config and no transport"

**Location:** `test/scripts/build-loop-check.bats:1371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every PATH-resolved `git` call, the GATE_ENV `env … git` included. The test requires more than 10 logged calls and asserts the five pairs, `G=/dev/null` and `P=none` on every line. m4, m7 and m8 each fail it. It does not check GIT_LITERAL_PATHSPECS, GIT_NO_REPLACE_OBJECTS, GIT_OPTIONAL_LOCKS or GIT_ATTR_NOSYSTEM; the title does not claim them.
**Legibility-target:** for-author

The test asserts `! grep -v -- " $kv" "$BATS_TEST_TMPDIR/calls"` for each pair (`:1381`).

**Evidence:** `test/scripts/build-loop-check.bats:1371-1383`; `/tmp/fcu2b1a2-r2-logs/mutants.txt`

---

## Claim 29: submodule test title: "--check's merge opens no submodule repository: a promisor one under .git/modules never fetches, and the moved gitlink is a conflict (U2b1a i2)"

**Location:** `test/scripts/build-loop-check.bats:1394`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test checks what its title says. It does not. The code's behavior is right (Claim 1). The SHA-256 test (`:1411`), checked alongside, is Verified: m5 fails it, and it asserts a 64-hex TIP and the TREE from `git merge-tree`.
**Legibility-target:** for-orchestrator-synthesis

Same mechanism as Claim 2. `commit_all sub1` (`:1399`) drops the cacheinfo gitlink, so there is no gitlink at the merge base. The "moved gitlink" is an add/add, which merge-tree rejects as `(no merge base)` without opening `.git/modules/sm`. The test passes with merge-tree in the real repo, with protocol allowed (m2) or not (m1).

Committing the base gitlink (`git add .gitmodules; git commit` in place of `commit_all`) makes the real-repo merge fetch (`fetched=yes`). The unmodified script still does not fetch on that plant.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1416`, `test/lib/build-loop-fixtures.bash:28`; `/tmp/fcu2b1a2-r2-logs/probe-submodule.txt`, `/tmp/fcu2b1a2-r2-logs/probe-submodule-fixed-plant.txt`, `/tmp/fcu2b1a2-r2-logs/probe-gate-submodule.txt`, `/tmp/fcu2b1a2-r2-logs/mutants.txt`

---

## Claim 30: commit 63ea50e7's message

The message claims:
- the bullets on harden, state_gate, gate_repo and merge_result, check_line, and the tests;
- "Suites: build-loop-check 91, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2";
- "330 code lines against U2b1a1";
- "Its code, tests and review history are feat/build-loop-u2b1a at c66988b6";
- "security F3 … is deferred with an override row".

**Location:** `git show 63ea50e7` (message body)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the code (Claims 10-23), the suite counts, the 330, the c66988b6 identity and the F3 row. How each was checked:
- **Suite counts:** the five suites ran with exit 0 and those exact `ok` counts.
- **330:** `git diff --numstat feat/build-loop-u2b1a1...HEAD -- ':(top)' ':(top,exclude)docs/'` gives 165+11 (scripts/build-loop.sh) and 151+3 (test), so 316 added plus 14 deleted is 330. The figure counts test and comment lines.
- **c66988b6:** `git diff c66988b6 HEAD --stat -- scripts test` is empty. The full diff touches only `docs/working/plan-build-loop-handoff.md` (+1) and `docs/working/questions.md`, so docs/reviews is identical too.
- **F3:** it is override-log row 492.

The Tests bullet's "the … submodule plants" exists but does not test what it is for (Claim 29). That is a test defect, not a false statement in the message.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the commit message is not a file; the commands and their outputs are recorded in the Scope field and in `suites.txt`.

**Evidence:** `docs/reviews/override-log.md:492`; `/tmp/fcu2b1a2-r2-logs/suites.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`, `:48`): "mutant running merge-tree in the real repo fetches" and "submodule … tests fail" are false. The submodule test passes under that mutant, even with transport allowed.
- **Claim 27b** (`test/scripts/build-loop-check.bats:1356`, `:1363`): the partial-clone test does not detect the state gate running after resolve_main (m3 passes). GIT_ALLOW_PROTOCOL masks the fetch, and resolve_main's fallback leaves the output unchanged.
- **Claim 29** (`test/scripts/build-loop-check.bats:1394-1409`): the submodule test is vacuous. `commit_all sub1` drops the base gitlink, so the merge is an add/add that never opens `.git/modules/sm`. Commit the gitlink at the base (`git add .gitmodules` + `git commit`) so the real-repo mutant fetches.

### Stale
- **Claim 4** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:60`): R1's "both mutants let upload-pack run" no longer holds now that GIT_ALLOW_PROTOCOL=none is set. m9 fails on output, and m3 passes.
- **Claim 9** (`docs/working/plan-build-loop-handoff.md:281`): "merge-tree … against the common git dir" now runs in a gate-owned git dir with GIT_OBJECT_DIRECTORY.

### Mostly Accurate
- **Claim 6** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:46`): C11's "Fixed" covers global config and GIT_COMMON_DIR. System config still applies; nothing sets GIT_CONFIG_NOSYSTEM.
- **Claim 10** (`scripts/build-loop.sh:78-85`): the --check help's state-gate list omits the shallow file and the origin/HEAD rule.
- **Claim 18** (`scripts/build-loop.sh:156-157`): "What the rest cannot switch off, the state gate refuses" leaves out system config and `objects/info/alternates`. Both are read by every call, and neither is refused. Alternates is F3-class.

### Unverifiable
- (none)

## Escalations

- **for-orchestrator-synthesis (Claims 2, 29):** the R2 regression test cannot fail. Its plant has no gitlink at the merge base, so the rubric's R2 "Fixed" rests on code that is right (Claim 1, executed: no fetch even with protocol allowed) but on a test that pins nothing. A real-repo merge-tree passes the test with or without GIT_ALLOW_PROTOCOL (m1, m2). Fix in the test only: commit the base gitlink without `add -A`.
- **for-orchestrator-synthesis (Claim 27b):** nothing in the suite pins "state gate before resolve_main" (m3 passes all 91). GIT_ALLOW_PROTOCOL makes the upload-pack mark unreachable in every mutant. An ordering test needs an observable that does not depend on transport. One example: an object store resolve_main cannot read, with a planted key, asserting the refuse lines and no "default branch" error.
- **for-orchestrator-synthesis (Claim 18, informational):** `objects/info/alternates` is read by the gate's merge-tree and every other call, and the state gate does not refuse it. It adds no capability beyond the deferred F3 (row 492). The F3 row could name alternates, packs and multi-pack-index alongside loose objects when U3's re-hash work lands.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 63ea50e7` line at the top.
- Answered: yes
- Out of scope: the hallucination-pattern log was not updated, because the brief allows only this report file. None of the Incorrect verdicts is a fabricated symbol anyway: they are test-power and stale-note findings. Probe logs live in /tmp/fcu2b1a2-r2-logs/, not docs/reviews/execution-logs/, for the same reason.
- Escalate: the vacuous submodule test (Claims 2, 29) and the unpinned gate ordering (Claim 27b).
