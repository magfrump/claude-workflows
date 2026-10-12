Commit: cca66dc2

# Security Review — feat/build-loop-u3b2 (U3b2: --main-log SINCE), iteration 2 (fix range)

**Scope:** PARTIAL, the fix range `1d829fee..cca66dc2`: `scripts/build-loop.sh` (the help text, gate_msg's comment, ANSWERS_AWK, log_class's merge-tree check, main_log's refusal lines), the lib's ANSWER_AWK back-pointer, `test/scripts/build-loop-orchestrator.bats` test 10, the plan note and the override rows. Read beyond the range: log_class and main_log whole (`:1625-1690`), gate_repo and gate_git (`:917-943`), merge_result (`:1006-1016`), the file header's write list (`:404-412`), the loop prompt's rule (`:1593`).
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md` (2 Incorrect, not in scripts/: known, not re-filed). Its E3 (merge-tree equivalence: criss-cross, rename, ancestor second parent; caller `merge.directoryRenames` and `merge=union` diverge toward other) is used as the base and not re-run. Iteration 1: `docs/reviews/security-review-2026-10-12-u3b2-i1.md`.
**Probes:** one script, `scratchpad/u3b2-i2/sec/probe1.sh`. It made and entered its own `/tmp/u3b2rv-sec2-XXXX`, refused to run git outside it, set `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and an identity, ran each `--main-log` under `timeout 60` and the script under `timeout 300`, and removed its dir. An aborted first run left `/tmp/u3b2rv-sec2-qxIh`, removed by hand. No `/tmp/u3b2rv-sec2-*` dir remains.

No escalation pattern matched.

## Trust Boundary Map

```
B1: [main's first-parent commits after SINCE: message, parents, tree header] → [log_class: merge-tree tree check (new), gate/chore regex, gate_msg + cmp] → [CLASS; exit 0 lets the orchestrator dispatch]
B2: [each one-parent commit's diff of the questions files] → [diff-tree -p -U0 in the gate repo, ANSWERS_AWK (changed: an added answer line required)] → [CLASS answers]
B3: [the parents' trees and their merge] → [gate_git merge-tree --write-tree in the gate repo (new reader; it also writes into the real object store)] → [the tree compared with the commit's tree header]
B4: [repository state and the caller's git pairs] → [state_gate + gate_repo (unchanged since i1)] → [what gate_git reads]
```

| Source | Mutability | Trust per sink |
|---|---|---|
| S1: commit messages, parents and tree headers on main | runtime-mutable (anyone who commits to main, a slipped loop included) | UNTRUSTED for the classification decision |
| S2: the questions files' diff in a one-parent commit | runtime-mutable | UNTRUSTED for classification; the orchestrator later reads answers from it as the user's decision |
| S3: the parents' trees, merged by merge-tree | runtime-mutable, objects below MAIN not re-hashed (row 721) | UNTRUSTED; the merge is recomputed, not taken from the commit |
| S4: caller git pairs, repo config, attributes | as in i1 | refused by state_gate or neutralized by the gate repo; caller pairs trusted by design (row 723) |

The fix adds one reader (B3): a two-parent commit must carry the tree merge-tree computes for its parents. B2's rule now requires an added answer line. Both are meant to separate the user's and the orchestrator's commits from an honest slip by a loop, not from a forger (F19, row 721).

## Findings

#### F1. The answers class still passes a loop's ordinary resolution of an entry: a Status flip with an answer line, a revert of an answer edit, an answer line anywhere in the file

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1619` (the added-answer count), `:1597-1602` (its comment), `:160-167` (help)
**Boundary:** B2
**Move:** 11 (bypass enumeration), 5 (what the rule does not prevent)
**Confidence:** High (mechanism, executed); Low (likelihood: the loop prompt forbids writing the questions files, `:1593`)

D2 closes the exact cases i1 F2 listed: a bare Status flip and a bare deletion now read other (fact-check E3 case F, and my P7-P15 setup). But the rule counts any added line with an answer label, in any entry and at any place in the file:

```
1619	  if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }
```

The honest slip i1 F2 described was a loop that thinks it has resolved an `agent` question. A loop that does this following the global convention ("Record answers inline, set `Status: ANSWERED`") writes an answer line together with the flip, so the rule's new requirement is met. Probe1 printed, each in its own window:

```
== P7 agent-style resolve: Status flip + Answer line (expect answers)
answers 1e011e875c51b51fda8c16cef0012b36ab77fc53 agent resolves Q-001
== P8 revert of an answer edit (expect answers)
answers 95d78249dd5214d67b2acf64e6673c89865dd7e7 Revert "edit"
== P9 delete an answer of Q-002 + add one for Q-001 (expect answers)
answers 8679390190302936be29cb4904f2747c73db28ad withdraw Q-002, add Q-001
== P10 answer line inserted in the options table (expect answers: location unchecked)
answers 712b858f34338991ff524585d20113b1b4331ec8 tbl
== P15 empty answer Q-012: + Status flip of Q-002 (expect answers)
answers 2cb44a83f54ae220d0f02b26d40e625b09349056 empty
```

P7 is `**Status:** OPEN` → `ANSWERED` on Q-001 plus `- **Answer:** done by agent`. P8 is `git revert` of a commit that changed `Q-002: [1]` to `Q-002: [2]`: plain git, no hand-written text, and it restores the old answer. P9 withdraws Q-002's answer and adds one to Q-001 in one commit. P10 puts `Q-009: inside table` between two table rows of Q-002. P15 adds a bare `Q-012:` and flips Q-002's Status, so one entry's added label carries another entry's flip. In each case the orchestrator's next read takes the change as the user's decision. P7 and P8 need no disguise, so row 721's "a forger" reasoning does not cover them. The comment's "a revert alone adds none" (`:1601`) is true only for a revert of an added answer. A revert of an edited answer adds one (P8).

No content rule can tell P7 from a user's own answer: the text is the same. So this is a residual to record and route, not a rule to tighten further.

**Recommendation:** Add an override row next to row 721 saying the answers class reads an answer's shape, not who wrote it: a loop's inline resolution (flip plus answer line) and a `git revert` of an answer edit pass. Hand U4 a cheap way to expose it: list each `answers` SHA and subject in the iteration digest the user reads, so a commit the user did not write is visible. Two narrower tightenings are optional: bind a Status change to an added answer line in the same entry (blocks P15's split), and count only answer lines outside a table row's neighbourhood (P10). Reword `:1601` to "a revert of an added answer adds none".

**Legibility-target:** the ANSWERS_AWK comment at `scripts/build-loop.sh:1599-1601` ("a Status flip, a deleted answer or a revert alone adds none") and the override log's answers rows (`docs/reviews/override-log.md:720-721`), which record the rule's false positives and the forger residual but not an honest loop resolution or a revert passing.

#### F2 (Informational). The header's write list omits --main-log, which now writes merge-tree's trees and blobs into the real object store

**Severity:** Informational
**Location:** `scripts/build-loop.sh:404-412` (header), `:1640` (the new merge-tree call), `:924-933` (gate_repo: `GIT_OBJECT_DIRECTORY="$v"`, the real store)
**Boundary:** B3
**Move:** 1 (what leaves the code to somewhere else)
**Confidence:** High (the write); Low (any effect beyond loose objects)

```
405	# found by name (origin/HEAD, main or master). Writes nothing but --check's
406	# merge objects (merge-tree writes the merged trees and blobs into the object
```

log_class's merge-tree runs in the gate repository, whose object directory is the repository's own. So every two-parent commit in a SINCE window writes its merged trees into the store when they are not already there. Most are, because an honest merge's tree is the commit's own tree. An amended or hand-resolved merge's recomputed tree is new. git does not write an object that already exists, so I expect no second copy for store_check to refuse (store_check, `:968`). I did not test this against a concurrent `--check`. The header is the user's contract for what a gated mode changes on disk, and it now misses one mode.

**Recommendation:** Add "--main-log's merge objects" to the header's list beside --check's.

**Legibility-target:** the header's "Writes nothing but --check's merge objects" (`scripts/build-loop.sh:405-406`).

## Untested bypass candidates

- A `--check` running alongside `--main-log`, with merge-tree's writes racing store_check's second-copy listing. Not tested: git checks for an existing object before it writes one, and the race is R8's family (Q-103).
- A newer git (2.42+) that reads attributes from a bare repository's HEAD or `attr.tree`. Not tested: the sandbox has git 2.39.5. The gate repository's HEAD is unborn (`ref: refs/heads/none`, `:930`), so I expect no attributes. Any change would make land's merge_result and log_class's check move together, because both run the same call in the same repository.
- `git rebase --rebase-merges` on main, which re-creates a gate merge over a new first parent. Not tested: it rewrites main, so SINCE usually leaves the history (refuse). Where SINCE stays, the re-created merge's tree is merge-tree's only when it was clean, and in that case it adds nothing beyond its parents.

## Endorsement Claims

- **Claim:** An amend of a gate or chore merge that changes its tree reads other, and so does a hand-resolved gate-shaped merge.
  **Location:** `scripts/build-loop.sh:1639-1642`
  **Evidence:** executed
  **Verified:** probe1. `P1b gate amended with loop.txt` printed `other c4e6cfde… Merge branch 'feat/x' (build-loop self-merge)`. `P2 chore amended with slip` printed `other 2af46710… Merge branch 'chore/dev-cycle-2026-10-12': loop note`. `P6 hand-resolved gate-shaped merge` printed `other 5f6c8dcb…`. The honest gate before the amend printed `gate 8b22de55…`. A conflict makes merge-tree exit 1, so the `&&` chain fails and `return 0` leaves other. A git stderr line makes gate_git return 3, with the same result.
  **Not verified:** a merge whose parents' objects below MAIN were rewritten in place (row 721: not re-hashed).
  **route: code-fact-check**

- **Claim:** The tree check accepts only a merge that adds nothing beyond its parents' clean merge. A slip that passes as gate or chore must therefore already sit in a parent: the gate's second parent, which land verifies before it writes the message, or the chore branch itself (row 722, deferred).
  **Location:** `scripts/build-loop.sh:1639-1642`, `:1012`
  **Evidence:** executed (cases); read-static (land's side)
  **Verified:** `P3 gate whose 2nd parent carries a later slip` printed `gate 635b5d69…`. That merge was made with land's message by hand. Only land writes that message, after its verdict on the tip, through the same merge-tree call (`merge_result`, `:1012`). `P4 chore branch carrying a slip` printed `chore ecc1e9db…`, the row-722 residual. `P5`, a chore merge re-messaged by amend over the same tree, printed `chore de765132…`. The only change is the subject, so it adds no content.
  **Not verified:** land's tip-to-merge window (whether land merges exactly the tip it judged); that is --merge's contract, outside this range.

- **Claim:** An answer line's trailing CR is dropped before the label match. A UTF-8 BOM before the label, at the start of a line or of the file, makes the commit other, as does a table row beginning `| Q-NNN:`.
  **Location:** `scripts/build-loop.sh:1615-1620`
  **Evidence:** executed
  **Verified:** P12 (`Q-010: [1]\r`) printed `answers 3dd3e304…`. P14 (a BOM before `Q-011:`) printed `other b2efa657…`. P16 (a BOM at the start of the file plus an answer) printed `other 2f5fab58…`. P11 (`| Q-009: x |`) printed `other 7042d859…`.
  **Not verified:** a CR in the middle of a line, or a lone CR as a line ending (diff -U0 splits only on LF).

## Primitive sweep

Primitive: process exec / git invocation with repo-derived arguments (in the fix range)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1640` `gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}"` | S1 parent lines | ids come from the `parent ` header lines git validated when it wrote the object; gate repo, no config, empty work dir | cleared; it writes into the real store (F2) |
| `:1641` awk `/^tree /` over `$GATE_TMP/c` | S1 | the header's first line; exits at the first match | cleared |
| `:1619` ANSWERS_AWK | S2 | the rule itself | F1 |
| `:1678`, `:1681` `echo "main $MAIN_SHA -"` | default_gate's ref | hex id | cleared |

Every other call site in log_class and main_log is unchanged since i1's sweep.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Answers class passes a loop's flip plus answer line, a revert of an answer edit, an answer anywhere | Medium | B2 | `scripts/build-loop.sh:1619`, `:1599-1601` | High (mechanism) / Low (likelihood) |
| 2 | Header's write list omits --main-log's merge objects | Informational | B3 | `scripts/build-loop.sh:404-412`, `:1640` | High |

## Overall Assessment

D1 closes i1 F1 without a new fail-open that I found. An amended or hand-resolved two-parent commit now reads other, for gate and chore alike (executed). The tree check means a passing merge can carry only what its parents already hold. For a gate merge, that is the tip land judged. For a chore merge, it is the chore branch, whose unread content is row 722's deferral. Every divergence between merge-tree and an honest `git merge` (fact-check E3/E4) falls toward other. D2 closes the literal cases of i1 F2. But a loop's ordinary resolution of an entry, a flip plus an answer line, still passes, and so does a `git revert` of an answer edit (F1). No content rule can separate these from the user's own answer, so the fix is a recorded residual plus a visible digest line, not more awk. F2 is a header line. Neither is architectural. Endorsement claims marked `route: code-fact-check` remain pending execution verification. The most important item is F1's override row.

## Goal-Alignment Note

Success criterion: "A security review saved to docs/reviews/security-review-2026-10-12-u3b2-i2.md in the worktree, per the security-reviewer skill." Met. The file is at that path, and its first line is `Commit: cca66dc2`. It carries the skill's sections: trust boundary map and source table, findings tied to boundaries with verbatim evidence and a Legibility-target, untested bypass candidates, endorsement claims with Verified/Not verified, primitive sweep, summary and assessment. The brief's focus questions are answered:

- **Tree check (D1).** It closes i1 F1. An evil merge reads other. A slip on a gate merge's second parent is land's domain. A slip on a chore branch is row 722's.
- **Answers rule (D2).** It closes i1 F2's literal cases. A revert or edit that also adds an answer line, and an answer line in a table or another entry, still pass (F1).
- **CR and BOM.** A trailing CR is accepted. A BOM reads other.

No file other than this report was written in the worktree.
