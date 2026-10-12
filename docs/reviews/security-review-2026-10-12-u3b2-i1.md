Commit: 1d829fee

# Security Review — feat/build-loop-u3b2 (U3b2: --main-log SINCE), iteration 1

**Scope:** `git diff main...HEAD` on `feat/build-loop-u3b2` (main b5f21758): `scripts/build-loop.sh` (gate_msg, ANSWERS_AWK, log_class, main_log, the dispatch and help), `test/scripts/build-loop-orchestrator.bats`, the plan "As built" note and four override rows. Read beyond the diff: gate_repo, gate_git, store_check, state_start, state_gate, harden, callervar, default_gate, merge_result, check_line's tree source (`scripts/build-loop.sh`), and scrub / scrub_reexec (`scripts/lib/dev-cycle-read.sh:127-160`).
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md` (Stage 1: 0 Incorrect, 7 Mostly accurate). Its executed verdicts (Claims 3, 7, 10, 14, 17-19) are used as the base and not re-run.
**Probes:** two scripts in the session scratchpad, `u3b2-i1/sec/probe1.sh` and `probe2.sh`. Each made and entered its own `/tmp/u3b2rv-sec-XXXX` and refused to run git outside it, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, under `timeout`. All `/tmp/u3b2rv-sec-*` dirs were removed afterwards (one was left by an aborted first run of probe2 and removed by hand).

No escalation pattern matched.

## Trust Boundary Map

```
B1: [main's first-parent commits after SINCE: message, parents] → [log_class: gate/chore regex, gate_msg + cmp] → [CLASS printed; exit 0 lets the orchestrator dispatch]
B2: [each commit's diff and the blobs it names: questions files, cycle record] → [diff-tree in the gate repo, ANSWERS_AWK, the "Branch: B" awk] → [CLASS answers/chore]
B3: [repository state: object store layout, repo config, attributes, refs] → [state_gate + harden + gate_repo (GATE_ENV)] → [what gate_git reads in log_class]
B4: [caller's environment: git -c pairs, GIT_CONFIG_COUNT] → [callervar keeps them in GATE_ENV; caller_gate runs for --state only] → [gate_git in --main-log]
B5: [commit subject (SUBJ)] → [scrub_reexec's outer scrub] → [orchestrator / terminal]
```

| Source | Mutability | Trust per sink |
|---|---|---|
| S1: commit messages and parent lists on main | runtime-mutable (anyone who can commit to main, a slipped loop included) | UNTRUSTED for the classification decision (the dispatch gate) and for terminal output |
| S2: tree contents of those commits (questions files, cycle records, any path) | runtime-mutable | UNTRUSTED for classification |
| S3: SINCE (the last cycle record's `Main at:`) | runtime-mutable (from a record on main) | UNTRUSTED for history lookup; format-checked to a full hex id at `:441-443` |
| S4: repo-local git state (`.git/config`, `info/*`, `objects/info/*`, packs, refs/replace) | runtime-mutable (same uid) | UNTRUSTED for what git reads; refused by state_gate or neutralized by the gate repo |
| S5: caller env git pairs | deploy-time per session (the orchestrator's shell) | trusted by design; checked by `--state` only |
| S6: gate_msg's format literal | code-constant | trusted |

The diff adds one decision boundary (B1/B2): a commit on main that reads as gate, chore or answers is let through, and anything else stops dispatch. Per the stated threat model, the boundary is meant to separate the orchestrator's and the user's commits from an honest slip by a loop. It is not meant to stop a forger. The findings below are all about that one boundary. Each is a case where an honest git operation, with no hand-written disguise, lands a slip under a passing class.

## Findings

#### F1. An amended gate or chore merge keeps its class: a loop's `git commit --amend` in the main checkout lands its work as `gate`/`chore`

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1626-1640`
**Boundary:** B1, B2
**Move:** 11 (bypass enumeration), 5 (invert the model: what does the gate class *not* check?)
**Confidence:** High (mechanism, executed); Medium (likelihood: it needs a loop in the main checkout whose habit is to amend)

The gate class is decided from the message and the parent count alone. The code has no check that the merge's tree is the one `land` wrote:

```
1626	  if [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(.+)\'\ \(build-loop\ (self-merge|approved merge)\)$ ]]; then
...
1632	    gate_msg "$b" "$x" "$p" "$q" > "$GATE_TMP/want" && cmp -s "$GATE_TMP/want" "$GATE_TMP/m" && CLASS=gate
```

The chore class looks at the merge's diff only for one record line. Any other changed path is never read:

```
1637	      [[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && "$meta" =~ ^:[01234567]{6}\ 100644\ [0123456789abcdef]+\ ([0123456789abcdef]+)\ [AM]$ ]] || continue
...
1639	      gate_git cat-file blob "${BASH_REMATCH[1]}" | LC_ALL=C awk -v w="Branch: $b" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && { CLASS=chore; return 0; }
```

`git commit --amend` keeps both parents and, with `--no-edit`, the message byte for byte. So suppose a loop is in the main checkout (the wrong-directory slip D13 targets) while main's tip is a gate or chore merge, and it amends its "last commit" there. The result has the same class as before, but its tree now carries the loop's unreviewed files. The original merge leaves first-parent history, so nothing reads as other. Probe1 executed this:

- P1: land's exact message on a merge of feat/x was committed with `commit-tree`. Then `echo LOOPWORK > loopwork.txt; git add loopwork.txt; git commit -q --amend --no-edit`. Output: `gate 9cb0620642f89bec34dd0ac8787272be9a51f3ad Merge branch 'feat/x' (build-loop self-merge)`, `exit 0`.
- P2: a `--no-ff` chore merge, then the same amend adding `loop2.txt`. Output: `chore ad8f08d9657e6e8ac80b39654395052e47ce8c42 Merge branch 'chore/dev-cycle-2026-10-12'`, `exit 0`.

This is not the forger residual in override row 721 ("a loop that writes the gate message or a record line by hand"). Here nobody writes the message: git carries it over. Row 721's reasoning ("D13's check catches an honest slip ... not a forger") therefore does not cover this case. The help text's "it catches an honest slip" (`:165-167`) is wrong for it.

**Recommendation:** For both two-parent classes, re-compute the merge in the gate repository and require the commit's tree to equal it: `gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}"`, first line, against the commit's `tree` header. land's tree is exactly merge_result's tree (`tree="$(merge_result "$sha")"`, `:1258`, then `VERDICT[tree]`, `:1302`). A clean `git merge --no-ff` of the chore branch uses ort too. A conflict, or a git upgrade that changes a merge result, then reads as other, which fails closed. Add P1 and P2 to T39 as other cases.

**Legibility-target:** the help clause "it catches an honest slip, not a commit made to look like one of the others (F19)" (`scripts/build-loop.sh:165-167`), and override row 721's Won't-Fix reasoning.

#### F2. The answers class passes changes that carry no answer: a Status-only flip, a deleted answer, a revert

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1594-1613` (ANSWERS_AWK), applied at `:1651`
**Boundary:** B2
**Move:** 11 (bypass enumeration), 5 (what the rule does not prevent)
**Confidence:** High (mechanism, executed); Low (likelihood: the loop prompt forbids writing the questions files)

The rule accepts any removed answer line, and any header line whose only change is its Status value, even when nothing in the commit adds an answer:

```
1609	  if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) next
1610	  if (substr(l, 1, 10) == "**Needs:**") { if (s == "-") r[++nr] = needs(l); else a[++na] = needs(l); next }
```

Probe1 (P3-P6) printed, with no other line in between:

```
answers 4235093fdcb4265250101712dc3dc87ee353a49c close Q-001
answers 918106cddade70bc8da6880d6ea257ccaf1262e5 tidy
answers caa0bc0cfec6f1db554172236a53eac58c7d96a0 Revert "close Q-001"
answers ca750ee93681039b001ecee47b55517cdc034111 note
```

These are, in order: `**Status:** OPEN` → `ANSWERED` with no answer line, the user's `- **Answer:** [1]` and `Q-001: [1]` deleted, a `git revert` of the first, and an appended `Q-999: <free text>` line. The last one is the disguise F19 accepts. The first three are not disguises. A loop that thinks it has resolved an `agent` question, or that "tidies" the file, makes exactly these edits with plain git. Each one changes what the orchestrator reads from main as the user's decision: an entry closed with no answer, or an answer withdrawn. Override row 720 records only the rule's strictness (false positives), not these acceptances.

**Recommendation:** Accept a Status change only in an entry whose hunk set also adds an answer line, and read a commit that only removes answer lines as other. A simpler rule: require at least one *added* non-blank answer line (count `+` answer lines rather than all non-blank lines). Either keeps a user's edit of an answer (`-Q-1: [1]`, `+Q-1: [2]`) passing. Add P3 and P4 to T39 as other cases.

**Legibility-target:** the ANSWERS_AWK comment "every changed line in a hunk is blank, an answer line or a header line ... and at least one changed line is not blank" (`scripts/build-loop.sh:1589-1592`), the plan's "As built" answers sentence, and override row 720.

#### F3. The chore class leaves the chore branch's other content to U3c/U4, and no row hands that coupling over

**Severity:** Low
**Location:** `scripts/build-loop.sh:1633-1640`
**Boundary:** B2
**Move:** 1 (trust boundaries: who checks the rest of the merge?)
**Confidence:** Medium (U3c's `--cycle-diff` is not built yet; its scope is read from the plan only)

The chore class reads one changed path of the merge (the record). Every other path the merge brings to main passes unread. That is fine if the chore branch holds only the orchestrator's own commit and `--cycle-diff` checked it. But if a loop's commit reaches the chore branch (a slip into the orchestrator's chore worktree), the merge lands it as chore. Probe1's P2 shows the class (before its amend, the merge carried `slip.txt` from a commit on the chore branch). The plan scopes `--cycle-diff` to the questions files and roadmap edits ("It refuses a change to an existing entry's header or answer lines ... and a roadmap or idea-log line removed or edited", `docs/working/plan-build-loop-handoff.md:104`), not to an arbitrary path. The F1 fix (tree equals merge-tree) does not cover this case, because the content is in the chore branch itself.

**Recommendation:** Either restrict chore to merges whose diff against the first parent touches only the paths a cycle writes (records, questions, roadmap, briefs: the cycle's documented set), or add an override row handing the requirement to U3c/U4: `--cycle-diff` refuses any path outside that set, and the chore branch holds the orchestrator's commit alone.

**Legibility-target:** override row 719 (the chore coupling handed to U4), which names --no-ff and the Branch: line but not the branch's content.

#### F4 (Informational). `--main-log` trusts the caller's git pairs without the caller check

**Severity:** Informational
**Location:** `scripts/build-loop.sh:621` (`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi`), `:551` (callervar)
**Boundary:** B4
**Move:** 1
**Confidence:** High

Probe2 ran `GIT_CONFIG_PARAMETERS="'core.commitgraph'='true' 'diff.interhunkcontext'='5'" bash build-loop.sh --main-log S`, and --main-log ran normally with those pairs live in gate_git. The same pair under `--state` printed `refuse state core.commitgraph: set by the caller's git -c ...`. This is the recorded design: U4 runs `--state` first in the same environment (row 690's flow). No new action is needed beyond U4 actually calling both from one environment. It is listed so the dependency is visible.

**Legibility-target:** the help clause "after --state's gate but its caller check" (`scripts/build-loop.sh:138-140`).

## Untested bypass candidates

- `git rebase --rebase-merges` run on main by a loop, which recreates a gate merge with its message onto a new base. Not tested: it rewrites main, so SINCE usually leaves the history (refuse, fail closed) unless SINCE predates the rebase base. The F1 tree check would catch the case where it does not.
- A loop branch that merged a `chore/dev-cycle-*` branch into itself (subject `... into feat/x`, which the chore regex accepts) and was then fast-forwarded onto main. Not tested: the loop's own commits in that fast-forward still read as other unless they are answer-shaped. F2 and F3 cover the residue.
- Diff alignment under a caller-set `diff.algorithm` (B4) that pairs header lines differently across a hunk. Not tested: B4 is trusted by design, and `--state` refuses `diff.*` pairs.

## Endorsement Claims

- **Claim:** A NUL inside a gate-shaped subject reads as other: the truncated subject matches the regex, but `cmp` against the raw message fails.
  **Location:** `scripts/build-loop.sh:1624-1632`
  **Evidence:** executed
  **Verified:** probe2 wrote `Merge branch 'feat/x' (build-loop self-merge)\0junk` with `hash-object --literally`. Output: `other d819e181... Merge branch 'feat/x' (build-loop self-merge)`. `git commit-tree` itself refuses a NUL ("a NUL byte in commit log message not allowed"), so an honest path cannot produce one.
  **Not verified:** a NUL inside a chore subject after the `:` suffix (the chore class reads only the subject's prefix and the record).

- **Claim:** A subject's ESC, BEL, CR, C1 (0x9B) and U+202E bytes do not reach --main-log's stdout. A lone 0xFF arrived as printable `ÿ` (C3 BF).
  **Location:** `scripts/lib/dev-cycle-read.sh:127-145` (scrub), via `scripts/build-loop.sh:432`
  **Evidence:** executed
  **Verified:** P7 (probe1) and probe2's C1 commit. od showed `evil [31mred]0;title ... rtl\n` and `c1 31m red 303 277 end`, with no 033, 007, 015 or 233 byte.
  **Not verified:** the scrub's documented gaps (overlong encodings, zero-width characters); and where the 0xFF → C3 BF conversion happens (it is not in log_class's perl, which runs under `LC_ALL=C`).

- **Claim:** In log_class, every git read of a commit, diff or blob goes through gate_git (no repo config, no checkout attributes, GIT_GRAFT_FILE/GIT_REPLACE_REF_BASE/GIT_ALTERNATE_OBJECT_DIRECTORIES unset by GATE_ENV), and a git stderr line makes the read fail (exit 3) and the class other.
  **Location:** `scripts/build-loop.sh:918-937`, `:1618-1654`
  **Evidence:** read-static (fact-check Claims 5, 15 and 23 executed parts of it)
  **Verified:** the function read whole; gate_repo's env construction; harden's `core.commitGraph=false`/`core.multiPackIndex=false` pairs are kept in GATE_ENV via callervar; state_gate refuses `info/grafts`, `shallow`, `objects/info/alternates`, `refs/replace/` and every `diff.*` repo key before state_start.
  **Not verified:** history commits' object bytes (store_check re-hashes only main's tip commit and tree: override row 721), and a same-uid writer racing GATE_TMP (R8).
  **route: code-fact-check**

- **Claim:** Crafted path names in the `--raw -z` records are compared whole against fixed strings or a regex, and an answers commit whose record count disagrees with its NUL count reads as other.
  **Location:** `scripts/build-loop.sh:1636-1649`
  **Evidence:** read-static
  **Verified:** NUL-delimited reads into `meta`/`p`; exact `==` comparisons for the questions files; mode 100644→100644 with status M only (a symlink, gitlink or executable is other: fact-check E3).
  **Not verified:** a chore record path holding a newline (`cycle-[^/]+\.md` accepts it). Its only effect would be to count as a record.

## Primitive sweep

Primitive: process exec / git invocation with repo-derived arguments (`gate_git` in the diff)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1621` `cat-file commit "$c"` | S1 (rev-list output) | id from rev-list; gate repo | cleared — a fixed subcommand, the argument is a hex id |
| `:1635` / `:1642` `diff-tree ... "${ps[0]}" "$c"` | S1 parent lines | awk prints `$2` of `parent ` header lines | cleared — git validated the header when the object was written; a bad id fails the read (other) |
| `:1639` `cat-file blob "${BASH_REMATCH[1]}"` | S2 raw record | regex `[0123456789abcdef]+` | cleared |
| `:1650` `diff-tree -p ... --no-ext-diff --no-textconv` | S1 | external diff/textconv switched off | cleared |
| `:1659` `rev-list --first-parent "$MAIN_SHA"` | default_gate's ref | default_gate | cleared |
| `:1661` awk `-v s="$1"` | S3 | usage regex, full hex only (`:443`) | cleared — awk `-v` escape processing cannot apply to hex digits |

Primitive: terminal output of repo text: `echo "$CLASS $c $SUBJ"` (`:1665`), source S1. Guard: scrub (B5). Disposition: cleared, see the endorsement above.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Amended gate/chore merge keeps its class (loop work lands as gate/chore) | Medium | B1, B2 | `scripts/build-loop.sh:1626-1640` | High (mechanism) / Medium (likelihood) |
| 2 | Answers class passes a Status-only flip, a deleted answer, a revert | Medium | B2 | `scripts/build-loop.sh:1594-1613` | High (mechanism) / Low (likelihood) |
| 3 | Chore class does not read the chore merge's other paths; no handoff row | Low | B2 | `scripts/build-loop.sh:1633-1640` | Medium |
| 4 | --main-log trusts caller git pairs (relies on --state first) | Informational | B4 | `scripts/build-loop.sh:551, 621` | High |

## Overall Assessment

The read side is sound against what it was asked about: repo state, attributes, config and object store layout. Everything goes through the gate repository with harden's pairs. A NUL, a non-UTF-8 byte or a control byte in a message fails closed or is scrubbed. A commit touching the questions files plus anything else, a fast-forwarded loop commit, and an honest plain merge all read as other. The weakness is in what the two-parent classes accept. Both trust the message and the record line, and say nothing about the merge's tree. So the most ordinary slip of a loop working in the main checkout, `git commit --amend --no-edit` on a gate or chore merge tip, passes as gate or chore with exit 0 (F1, executed). That is an honest slip, not the forger F19 accepts. A tree-equals-merge-tree check fixes it in place for both classes and fails closed on any drift. F2 should tighten the answers rule to require an added answer. F3 needs either a path restriction or a handoff row to U3c/U4. No findings rise to an architectural problem. Endorsement claims marked `route: code-fact-check` remain pending execution verification. The single most important thing to address is F1.

## Goal-Alignment Note

Success criterion: "A security review saved to docs/reviews/security-review-2026-10-12-u3b2-i1.md in the worktree, per the security-reviewer skill." Met. The file is at that path. Its first line is `Commit: 1d829fee`, and it carries the skill's sections: trust boundary map with source table, findings anchored to boundaries, untested bypass candidates, endorsement claims with Verified/Not verified, primitive sweep, summary and assessment. The brief's focus questions are answered. Honest slips can fail open: an amend of a gate or chore merge (F1), and answer-shaped non-answers (F2). A ff of a loop branch, a mixed questions-plus-other commit, NUL and non-UTF-8 messages and crafted names fail closed. Repo state, attributes, config and object store layout do not change what log_class reads beyond the recorded residuals (rows 721, R8; F4's caller pairs). Printed subjects are scrubbed. Each finding has its Legibility-target and verbatim evidence. No file other than this report was written in the worktree.
