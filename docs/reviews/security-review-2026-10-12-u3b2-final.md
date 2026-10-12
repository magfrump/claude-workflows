Commit: 4afdd68b

# Security Review — feat/build-loop-u3b2 (U3b2: --main-log SINCE), final confirming pass

**Scope:** the full branch, `main...4afdd68b`: `scripts/build-loop.sh` (the --main-log help block `:138-180`, the header's write list `:408-415`, gate_msg `:1368-1377`, ANSWERS_AWK `:1602-1631`, clean_merge `:1641-1648`, log_class `:1649-1687`, main_log `:1688-1703`, the mode case `:1714-1717`), the lib's ANSWER_AWK back-pointer, test 9-10 in `test/scripts/build-loop-orchestrator.bats`, the plan note and the override rows. Read beyond the diff: harden, state_gate, caller_gate, default_gate (`:500-626`), gate_repo and gate_git (`:929-948`), store_check, merge_result, state_start (`:1220-1226`), and the lib's scrub and scrub_reexec (`scripts/lib/dev-cycle-read.sh:127-160`).
**Date:** 2026-10-12
**Based on:** the stage-1 merged summary (`scratchpad/u3b2-f/fc-summary.md`, k=3 replicates `code-fact-check-report-2026-10-12-u3b2-final-r{1,2,3}.md`: no behavioural Incorrect; two text Incorrect in override rows 726 and 728, known, not re-filed). Prior: `security-review-2026-10-12-u3b2-i1.md`, `security-review-2026-10-12-u3b2-i2.md`, rubric D1-D13, E1-E8.
**Probes:** one script, `scratchpad/u3b2-f/secf/probe1.sh`. It starts with `set -eu`, makes and enters `/tmp/u3b2rv-secf-XXXX`, refuses to run git unless `pwd -P` is under it, sets `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and an identity, runs each `--main-log` under `timeout 60` (the script under `timeout 300`), and removes its dir by trap. Afterwards `ls -d /tmp/u3b2rv-secf-*` matched nothing. The sandbox's unavailable `en_US.UTF-8` locale made bash print setlocale warnings on stderr. They come from bash, not git, so they do not reach gate_git's stderr check. They are left out of the quotes below.

No escalation pattern matched.

## Trust Boundary Map

```
B1: [main's first-parent commits after SINCE: message, parents, tree header] → [log_class: subject regex, then clean_merge (moved in 4afdd68b), gate_msg + cmp / record read] → [CLASS; exit 0 lets the orchestrator dispatch]
B2: [a one-parent commit's diff of the questions files] → [diff-tree --raw -z record check, then diff-tree -p -U0 --text through ANSWERS_AWK] → [CLASS answers, later read as the user's decision]
B3: [the parents' trees and their merge] → [gate_git merge-tree --write-tree in the gate repository (writes into the real object store)] → [compared with the commit's tree header]
B4: [repository state, the caller's environment and git pairs] → [state_gate, default_gate, harden, gate_repo (GATE_ENV unsets repo-local variables)] → [what gate_git reads]
B5: [repo text printed: SUBJ, SHAs] → [scrub_reexec: stdout and stderr each through scrub] → [the orchestrator's parse of "CLASS SHA SUBJECT"]
```

| Source | Mutability | Trust per sink |
|---|---|---|
| S1: commit messages, parents and tree headers on main | runtime-mutable (anyone who commits to main, a slipped loop included) | UNTRUSTED for the classification decision; display-only for SUBJ |
| S2: the questions files' diff in a one-parent commit | runtime-mutable | UNTRUSTED for classification; the class trusts the answer text by design (F19, row for E2) |
| S3: the parents' trees, merged by merge-tree | runtime-mutable; objects outside MAIN's tree not re-hashed (row for F19) | UNTRUSTED; the merge is recomputed, not taken from the commit |
| S4: repo config, attributes, grafts, alternates, replace refs, commit-graph | runtime-mutable | refused by state_gate or neutralised by harden and the gate repository |
| S5: caller git pairs and environment | per run | trusted by design in --main-log (row for D12; --state checks them first) |
| S6: SINCE argument | per run, from the orchestrator's record | format-checked (40/64 hex), then matched exactly against the first-parent list |

The only reader 4afdd68b changes is the order inside B1. clean_merge now runs after a gate or chore subject has matched, not on every two-parent commit. Every two-parent commit that does not match a subject was already other, so moving the check later cannot let a new commit through. B2 to B5 are unchanged since i2.

## Findings

No findings.

Before writing this, I checked i2's two findings against HEAD. F1 (the answers class passes any added answer label) is now a Won't-Fix row under F19 (rubric E2, override row "The answers class counts any added answer label…"). I re-read that row's reasoning, and it stands. No content rule can tell a loop's inline answer from the user's own, and the hand-off routes the residual to U4's digest. The ANSWERS_AWK comment now says this:

```
1605	# values are set aside, and at least one answer line is added (a Status flip
1606	# or a deleted answer alone adds none: i1 security F2). Any added answer label
1607	# counts, in any entry and from anyone (a revert restoring an old answer, a
1608	# loop answering an agent entry): the class trusts content (i2 security F1,
```

F2 (the header's write list) is fixed at `:410-411`:

```
410	# found by name (origin/HEAD, main or master). Writes nothing but --check's
411	# and --main-log's merge objects (merge-tree writes the merged trees and blobs into the object
```

The stage-1 items that touch security are all text: clean_merge's comment leaves out `-s`/`-X`/config merges, and override rows 726 and 728 give the wrong counts. Each such merge falls toward other, not toward a class. For example, a `-X theirs` merge reads other (P2 below). So none of them is a fail-open, and I have not re-filed them.

**Legibility-target:** none (no finding).

## Untested bypass candidates

- **main_log prints fewer class lines than its count when `tac` fails.** `:1698` prints `main MAIN N`, and then `:1701` (`done < <(tac "$GATE_TMP/after")`) prints the lines. The status of a process substitution is never read. So if tac failed, the run would print N but no lines, keep `o=0` and exit 0. I traced this but did not trigger it. tac reads a regular file the script has just written into its own mktemp directory, and I found no reachable way to make that fail. It depends on U4 reading a missing line as other. If U4 parses only the lines that are present, a cheap guard is to compare the count with the lines printed.
- **A newer git (2.42+) that reads attributes from `attr.tree` or a bare HEAD during merge-tree.** Not tested: the sandbox has git 2.39.5. The gate repository's HEAD is unborn (`ref: refs/heads/none`, `:935`) and it has no config, so I expect no attributes. Any change would move land's merge_result and clean_merge together, because both make the same call in the same repository.
- **A commit object holding duplicate parent lines (`parent X` twice), so merge-tree merges X with itself.** Not tested: `git commit-tree` drops a duplicate parent, so only `hash-object --literally` makes one. That is a forger, which F19 already lists.

## Endorsement Claims

- **Claim:** At HEAD, a two-parent commit with a chore subject whose tree is not merge-tree's clean merge reads other. Three cases were tested: a `-X theirs` resolution of a conflict, an octopus (three parents) and an `--allow-unrelated-histories` merge.
  **Location:** `scripts/build-loop.sh:1644-1648`, `:1666-1667`
  **Evidence:** executed
  **Verified:** probe1 printed `other 7392ad4d… Merge branch 'chore/dev-cycle-2026-10-13'` / `exit 2` (P2, -X theirs over a conflict), `other 0c05ca5e… Merge branch 'chore/dev-cycle-2026-10-14'` / `exit 2` (P3, octopus) and `other a936711c… Merge branch 'chore/dev-cycle-2026-10-15'` / `exit 2` (P4, unrelated histories). The honest no-ff chore merge printed `chore c9c4852b… Merge branch 'chore/dev-cycle-2026-10-12': c` / `exit 0` (P1). Static reading: clean_merge is called in a `||` list at `:1659` (gate) and `:1667` (chore), before any `CLASS=` assignment in those branches. BASH_REMATCH is copied into `b` and `x` before the call, and clean_merge runs no `=~`.
  **Not verified:** the gate branch's merge-tree failure cases with land's own message (covered for an amend by test 10 and i2 P1b/P6, not re-run here).
  **route: code-fact-check**

- **Claim:** An answers-shaped commit reads other when its added line starts with a NUL or is a lone vertical tab, or when it also changes the questions file's mode to 100755. In each case a valid `Q-001:` line is added as well.
  **Location:** `scripts/build-loop.sh:1624-1625`, `:1677`
  **Evidence:** executed
  **Verified:** P5 (`\000rm -rf x` plus `Q-001: [1]`) printed `other 44c4b783… nul`. P6 (`\013` plus `Q-001: [2]`) printed `other ebdd1bdc… vt`. P9 (chmod +x plus `Q-001: [1]`) printed `other 24d1f286… mode`, each with `exit 2`. Separately, mawk (`/usr/bin/mawk`, the system awk) keeps a NUL inside a record: `printf '+\000rm -rf x\n'` piped through the blank test read length 10, `nonblank`. So a NUL never hides the rest of a line from the blank rule.
  **Not verified:** gawk or busybox awk as the system awk (the script calls plain `awk`).
  **route: code-fact-check**

- **Claim:** The subject is printed with ESC and CR removed and stays on its own output line, so a subject cannot add a new "CLASS SHA" line.
  **Location:** `scripts/build-loop.sh:442`, `:1700`; `scripts/lib/dev-cycle-read.sh:134`, `:158`
  **Evidence:** executed
  **Verified:** P7 committed the subject `ans\033[2K\rgate deadbeef fake`. --main-log printed `answers c01ce957… ans[2Kgate deadbeef fake`. Piping the same run through `od -c` found no `033` or `\r`. SUBJ is the first LF-split line of the message (`mapfile -t -n 5`), so it holds no LF. scrub's `tr/\000-\010\013-\037\177//d` removes the other C0 controls.
  **Not verified:** a caller that sets `DEV_CYCLE_SCRUBBED` (`scripts/lib/dev-cycle-read.sh:156` skips the scrub; an environment choice).

- **Claim:** A loop that merges main into its own branch with a chore-shaped subject, after which main is fast-forwarded to that branch, puts both of its commits on main's first-parent history as other.
  **Location:** `scripts/build-loop.sh:1666-1672`
  **Evidence:** executed
  **Verified:** P10 printed `main 2fbe52c1… 2`, then `other 7bfa32af… loop` and `other 2fbe52c1… Merge branch 'chore/dev-cycle-2026-10-16'`, with `exit 2`. The merge is clean, but its diff against its first parent (the loop commit) adds no cycle record.
  **Not verified:** the same shape where the loop branch also carries a matching record (a forger under F19).

## Primitive sweep

Primitive: process exec / git invocation with repo-derived arguments (the whole --main-log path)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1646` `gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}"` | S1 parent lines, S3 | ids from the `parent ` header lines; gate repo, no config, empty work dir; reached only after a subject match (4afdd68b) | cleared (P2-P4); its store writes are recorded (header `:410-411`, deferred row) |
| `:1652` `gate_git cat-file commit "$c"` | S6/rev-list output | hex id from rev-list | cleared |
| `:1668` and `:1675` `gate_git diff-tree -r --no-renames --raw -z` | S1 | NUL-separated read, records compared whole | cleared (rows for D8) |
| `:1671` `gate_git cat-file blob "${BASH_REMATCH[1]}" \| awk` | S1 record meta | hex regex; pipefail | cleared |
| `:1683` `gate_git diff-tree -p -U0 ... --text` → ANSWERS_AWK | S2 | rule; no attributes or textconv | cleared for the bypasses probed (P5, P6, P9); content trust is the E2 row |
| `:1664` `gate_msg ... > want && cmp -s` | S1 | printf `%s`; byte cmp | cleared |
| `:1694`, `:1697` `gate_git rev-list --first-parent` / awk exact match | S6 | hex format + `$0 == s` | cleared |
| `:1700` `echo "$CLASS $c $SUBJ"` | S1 | scrub (B5) | cleared (P7) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

I found no new fail-open at 4afdd68b. Moving clean_merge after the subject leaves the two-parent classes' guard intact: each subject branch calls it before it can set a class, and a commit that matches no subject was already other. Every merge shape I probed that git can make outside a default clean merge reads other: `-X theirs`, octopus, unrelated histories, and a loop's merge-then-fast-forward. So do the byte-level near-misses of the answers rule (a NUL, a lone VT, a mode change). Printed subjects are scrubbed and cannot add a line. The residuals that remain are recorded rows I re-read and still agree with: the answers class trusts content (E2/F19), the chore branch's other paths are unread (D11), the caller's git pairs go unchecked in this mode (D12), and history objects are not re-hashed (F19). The one untested candidate, a silent `tac` failure, needs U4 to treat a missing line as other, and I found no way to trigger it. There are no findings within the code paths I read, and the endorsement claims marked `route: code-fact-check` still need execution verification.

## Goal-Alignment Note

Success criterion: "A security review saved to docs/reviews/security-review-2026-10-12-u3b2-final.md in the worktree, per the security-reviewer skill." Met. The file is at that path, and its first line is `Commit: 4afdd68b`. It has the skill's sections: a trust boundary map and source table, Findings (none, with i2's two findings and stage-1's text items rechecked against HEAD), untested bypass candidates, endorsement claims with Verified and Not verified lines (two routed to code-fact-check), a primitive sweep covering every --main-log git call, a summary and an assessment. The brief's three questions get these answers. Fail-opens: none new; the recorded residuals stand. Reads that repo state could redirect: refused or neutralised as in i1, and unchanged since. Unscrubbed output: none found (P7). The report quotes its evidence verbatim, and the Findings section carries a Legibility-target line ("none"). I wrote no file in the worktree other than this report.
