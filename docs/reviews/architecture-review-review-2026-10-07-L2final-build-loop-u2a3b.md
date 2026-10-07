Commit: e1654266

# Architecture Review: feat/build-loop-u2a3b (loop 2, final confirming pass, full unit)

**Scope:** `git diff main...e1654266 -- . ':!docs/reviews'`. The review reads `IMPORT_AWK`, `UTF8_OK`, `import_home`, `import_targets`, `tree_starts`, `imported_names`, `main_imports` and `isimported` (`scripts/lib/dev-cycle-read.sh:447-780`) whole, plus check_fix's walk-failed arm (`scripts/dev-cycle.sh:181-184`), known issue A5, plan F11 (`:126`) and plan step 5's U2a3c and U2b bullets (`:277`, `:279`).
**Date:** 2026-10-07
**Based on:** the Stage 1 summary (`code-fact-check-report-build-loop-u2a3b-L2-final-r{1,2,3}.md`), used as fact and not re-verified, including escalation E1 and r3's relative re-entry (Claims 7 and 15c). Prior work: `architecture-review-review-2026-10-07-L2i2-build-loop-u2a3b.md` (findings 1-8), the rubric's loop-2 rows and override rows 403-430.

Scope check: in scope. The unit changes a public contract that two walks and two later units consume (the parser's superset statement and its rules). It adds an environment seam (`IT_*`, `import_home`) and a walk-wide budget (`IMPORT_OUT_MAX`/`IMPORT_LEFT`), and it changes the cross-cutting reader model that the floor (U2a4) and the gate (U2b) inherit.

## Dependency Map

- `check_fix` → `imported_names` (run first so a failed walk gets its own wording) → `isimported tree`. Floor (U2a4, not built) → `main_imports` → `isimported main`.
- Both walks → `import_home` (once per walk) → `import_targets` (it calls `import_home` again, which hits the cache) → `env sed` (blanks) → [only for text that fails `UTF8_OK`] `python3 -I` U+FFFD copy → `env … IT_DIR IT_ROOT IT_HOME IT_HOMER IT_LEFT awk "$IMPORT_AWK"` (scan, splice, emit, put).
- The walks own the start set (the tree walk uses `INSTRUCTION_FILE` names in the checkout, and the main walk uses `INSTRUCTION_FILE` plus `.claude/rules/**` on main), the content source (`head -c 4194305` against `git cat-file blob`, uncapped), the `.git` skip (main walk only), the checkout-shape fail rule (main walk only) and the `used`/`IMPORT_OUT_MAX` budget (both).
- Dependencies point the right way. The parser is a leaf that depends only on its stdin, `$1` and the `IT_*` environment. Neither walk is depended on by the parser, and the python3 stage is a leaf inside the parser. There are two path resolvers: `put` for names and the symlink arm's `realpath -ms` for links. Both are lexical, and the U2a3c bullet forbids a third.
- **Security cross-reference.** The skill's glob `docs/reviews/security-review-*.md` matches only unrelated egress reviews. The relevant map is in `docs/reviews/security-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md` (Commit: `98e3b1df`). That security review predates this diff, so its boundaries may be stale. Its B3 ("Claude Code loader ⊆? candidate set") and B4 (S3: "HOME is the gate's value, which need not equal the Claude Code session's") are the boundaries that findings 1-3 touch. No recommendation below moves either boundary. Findings 1 and 2 say that B3's left side (the loader) has more starts and more bases than B1/B2 model.

## Prior findings: disposition check (architecture L2-i2, commit 98e3b1df)

| L2-i2 finding | Disposition | Holds at e1654266? |
|---|---|---|
| 1 (Coupling): the superset is computed against the gate's root and home | L2-I2-A3: routed to U2b (plan :279, override row 425); exception named in the statement | **Routing holds for absolute and `~/` names.** The routed remedy ("pass it to the parser as a root set") is narrower than the gap. It does not reach E1 or r3's relative re-entry. See finding 1. |
| 2 (Minor): routed items recorded only in the rubric | L2-I2-C8 | **Yes.** The U2a3c bullet (plan :277) carries prefix-safe fail rules, the capped and drained reader, one drain loop under `IMPORT_OUT_MAX`, no third resolver and the `blocker` memo. |
| 3 (Minor): `.git` skip only at the top level | L2-I2-A2 | **Yes.** `[[ "$p" != .git && "$p" != */.git ]] \|\| continue` (lib, main_imports' import loop). Files under `.git` fail. Stage 1 notes that the nested-skip mutant survives (r1 44). That is a test gap, not a structural one. |
| 4 (Minor): the one statement mixed name and file contracts | L2-I2-C7 | **Mostly.** The statement now names `~/` and five real exceptions. Four restatements elsewhere are stale (finding 4). |
| 5 (Minor): reader split (cap in the tree walk only) | L2-I2-C10, routed to U2a3c | **Yes**, as a routing (plan :277 "one capped and drained reader … for checkout files and main's blobs alike"). |
| 6 (Info): two resolvers with no cross-pointer | U2a3c bullet | **Yes in the plan.** `put` itself still has no comment naming the symlink arm. That is acceptable because the plan is where U2a3c will look. |
| 7 (Info): python3 undeclared | L2-I2-C4 | **Yes** (lib header, lines 12-13). |
| 8 (Info): U2a3c must stay in the one drain loop | U2a3c bullet | **Yes.** |

## Findings

#### 1. E1 and r3 are start-set and base questions, not parser questions. The routed "reader root set" covers only a third axis.

**Severity:** Coupling
**Location:** plan `docs/working/plan-build-loop-handoff.md:279` (U2b bullet: "decide the reader set (ROOT_REAL, every worktree path, the sessions' HOME) and pass it to the parser as a root set"). Lib `scripts/lib/dev-cycle-read.sh` `put` (`if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` … `if (index(out, pre) != 1 || length(out) <= length(pre)) return`) and the `BEGIN` block (`pre = (root == "/") ? "/" : root "/"`). The superset statement ("Known exceptions, where a session reading the file can import what these rules do not yield: … a session in another checkout of the repo (an absolute name into that checkout; the gate's root set is U2b's) …"). main_imports' and imported_names' start loops; A5's "Not covered" list.
**Move:** 3 (the contract the floor consumes; B3/B4), 2 (which module owns which half)
**Confidence:** High for the decomposition and the executed parser behaviour. Medium for which out-of-repo files Claude Code 2.1.292 loads (taken from fact-check r1 Claim 3, executed. Whether parent-directory loading also covers `CLAUDE.local.md` and `.claude/rules/` is `[unverified — submitted as claim]`).
**Legibility-target:** for-orchestrator-synthesis
**Executed vs reasoned:** the parser side was executed (probe below) and the routing analysis is reasoned.

A Claude Code session is a *reader* with three independent properties, and the floor is safe only when the walks over-approximate all three:

- (a) **Start set**: which instruction files the reader loads. This includes files outside every checkout: the user memory (`~/.claude/CLAUDE.md`), a parent directory's `CLAUDE.md`, and managed policy.
- (b) **Base**: the directory each relative name resolves against. Per A5's trace this is the importer's real directory in the reader's own checkout, or outside every checkout for an out-of-repo start.
- (c) **Projection**: which absolute paths count as a repo path, and which repo path they map to.

The parser owns none of (a). It owns the mechanics of (b) and (c), but for one base and one root only, and the U2b bullet routes only (c). So E1 is (a), and r3's `@../wtB/docs/x.md` is (b). A wider keep filter does not fix r3: the name resolves against the gate's directory, not the reading session's, so a root set yields it only when the gate's checkout happens to be a sibling of wtB. The probe below shows this. The answer to "whose responsibility is E1":

- **Not this parser.** The superset statement is scoped to "a session reading *the file*", so E1 correctly sits outside it. Adding E1 there would blur the name contract that loop 2 worked to keep pure.
- **The start set is the walks'.** For the tree walk (--check-fix), the reader is this process's own user and directory chain, so out-of-repo starts would be coherent there. The walk already reads this process's HOME for `~/` names. For the main walk the reader is not the gate process, which is the same split as L2-I2-A3.
- **It is not U2a3c's.** Phase 2 is "the checkout's files main lacks", and out-of-repo files are not the checkout's. Widening U2a3c would mix a reader-model decision into a content-source unit.
- **It belongs to U2b, as one reader-model item.** That item would cover the start set, a base per reader root, and projection with nesting. Until then it is a named exception in A5 and in both walks' "not covered" lists, not in the superset statement.

This repo's layout limits the current exposure. Each mitigation reduces E1's cases to ones the routing already covers, or would cover once (b) is added:

1. `~/.claude/CLAUDE.md` is a symlink to the decision-022 payload `/opt/claude-workflows/CLAUDE.md`. That file is root-owned, assembled from a main commit (`.manifest`: `commit=8213c43e…`), and lands only through install.sh's human bless gate. Its relative names resolve inside `/opt/claude-workflows`, outside every checkout, so only its absolute and `~/` names can reach a checkout. Those are exactly L2-I2-A3's cases.
2. Every worktree here sits under `/workspace/.claude/`, so every worktree session has `/workspace` as a parent directory. The main checkout's instruction files are parent memory for all of them, and their relative names resolve against `/workspace`. That is axis (b) with the main checkout as the base. Today it is harmless only because `/workspace/CLAUDE.md` and `/workspace/CLAUDE.local.md` do not exist (checked).
3. A parent-directory file's content is the main checkout's *working tree*, which other sessions switch between branches (memory note "Check branch before merging in the shared checkout"). It is not main's commit, so a reader exists whose start content no walk of main can model. U2b should name this as an exception, or require that a parent-directory instruction file never exists in the layout.

Probe (`/tmp/u2a3barchfin-eLzu`, from `git archive e1654266 scripts/lib`, with `dc/` standing in for `.claude/`). Text `@dc/wtA/docs/x.md`, `@../wtA/docs/x.md`, `@<abs>/w/dc/wtA/docs/x.md`, `@../../docs/x.md`, `import_targets ""`:

```
root=w            →  dc/wtA/docs/x.md
root=w/dc/gate    →  dc/wtA/docs/x.md        (the relative ../wtA name is dropped)
root=w/dc/wtA     →  dc/wtA/docs/x.md, docs/x.md
```

**Recommendation:** Before merge, record the routing only, with no code change in this unit. Rewrite the U2b bullet's last sentence as a reader model with three parts: (a) a start set, including out-of-repo files (user memory, parent-directory files, managed policy), or a named exception for each part left out; (b) a base per reader root for relative names; (c) projection over a root set that handles nested checkouts (finding 2). Add "instruction files outside the checkout (user memory, a parent directory's, managed policy) are not starts (U2b's reader model)" to A5's Not covered list and to both walks' headers. Add an override row that routes E1 to U2b beside row 425. When U2b is planned, also decide whether `/workspace` may hold a parent-directory instruction file at all (mitigation 3).

#### 2. Projection with nested checkouts: a single `pre` maps a name into a worktree under the main checkout to the wrong repo path.

**Severity:** Minor
**Location:** lib `IMPORT_AWK` `BEGIN` (`pre = (root == "/") ? "/" : root "/"`) and `put` (`out = substr(out, length(pre) + 1)`).
**Move:** 3, 7
**Confidence:** High
**Legibility-target:** for-author (of U2b's plan)
**Executed vs reasoned:** executed (finding 1's probe, row `root=w`).

Worktrees live inside the main checkout's directory. With the gate rooted at the main checkout, an import of `<main>/.claude/wt-X/docs/x.md` is printed as `.claude/wt-X/docs/x.md`, a path main never stores. The floor therefore protects nothing useful, and `docs/x.md` is not marked. Today the main walk fails closed on this, because the checkout holds a file main lacks. That fail-closed behaviour is an accident of U2a3's checkout-shape rule, which U2a3c's prefix-safe rewrite (plan :277) is told to loosen. A root set added later with first-match projection would keep the bug.

**Recommendation:** Add to the U2b bullet: project a name under every matching root, and at least the longest one, with nested roots expected. Add a test where the gate root contains a worktree.

#### 3. The env seam is right, but the parser still reads ambient state (`import_home`, `ROOT_REAL`, `IMPORT_LEFT`). U2b's home and root sets would have to undo the internal `import_home` call.

**Severity:** Minor
**Location:** lib `import_targets` (`import_home || return 1` as its first statement; `IT_ROOT="${ROOT_REAL:-}" IT_HOME="$IMPORT_HOME" IT_HOMER="$IMPORT_HOMER" IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"`), `import_home` (`h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""`), the walks' calls (`IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d"`).
**Move:** 3, 7 (control coupling through dynamic scope)
**Confidence:** High
**Legibility-target:** for-author
**Executed vs reasoned:** reasoned (the full units were read; fact-check r3 21c executed the per-file getent fork).

Passing `dir`, `root`, `home` and `left` through `ENVIRON` is a good seam. It avoids `awk -v`'s escape processing, gives one named place where the awk program meets the shell, and extends naturally to list-valued variables. The bash wrapper does not use the seam consistently, though. It receives `dir` as `$1`, `root` from the global `ROOT_REAL`, `home` by calling `import_home` itself (so it reads `$HOME` from the process environment), and its budget from a dynamically scoped `IMPORT_LEFT`. Each walk also calls `import_home` before its loop. Two consequences follow:

- The walks' "once per walk" comment is true only through the cache key.
- The parser fixes the policy "the reader's home is this process's HOME, with passwd as the fallback". That policy belongs to the reader model (finding 1; B4's S3).

When U2b supplies a home set, the parser's own `import_home` call has to be removed, or it silently re-imposes the gate's HOME. The empty-HOME rule (passwd fallback) also matches Bun, not Node as the comment says (Stage 1, Incorrect). That makes it a runtime-specific behaviour that belongs in the revisit trigger next to the grammar.

**Recommendation:** Either now or as a line in the U2b bullet: the walks compute home (and later the home and root sets) and pass them in, and `import_targets` reads only its arguments and `IT_*`. Add "Claude Code's runtime (Bun) changes how it reads `os.homedir()`" to the superset's revisit trigger.

#### 4. The single-source rule leaks: four restatements of the superset or its gaps are stale, and both walks' failure lists enumerate instead of pointing.

**Severity:** Minor
**Location:** known issue A3 ("absolute-path imports into the repo, print `ok`"). Plan F11 `:126` and main_imports' header ("three shapes A5 lists as untraced"; A5 now lists one). `test/scripts/build-loop-check.bats:339` title ("~/ dropped"). The imported_names and main_imports failure lists, which omit `import_home`, the `IMPORT_OUT_MAX` overrun and the parser (Stage 1: Stale and Mostly accurate).
**Move:** 3
**Confidence:** High (fact-check verified each one; the structural reading is mine)
**Legibility-target:** for-author
**Executed vs reasoned:** reasoned on top of the executed fact-checks.

Loop 2 made the comment above `import_targets` the one statement, and A5 and F11 point to it, which is the right shape. Every place that still *re*-states part of the claim (A3, F11's count, the main walk's count, a test title) drifted within one iteration. This is the failure the rule exists to prevent. The walks' failure lists will drift the same way each time the parser gains a failure arm.

**Recommendation:** Fix the four stale lines before merge (documentation only). Replace each walk header's list of parser causes with "or `import_home` or `import_targets` fails (see their comments)", and keep only the walk's own causes there.

#### 5. The two walks now share the name rules but not the start rule. The start rule is where A2, E1 and U2b's reader model all land.

**Severity:** Informational
**Location:** imported_names' start loop (`if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi`) against main_imports' (`if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]`).
**Move:** 2, 8
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Executed vs reasoned:** reasoned.

After this unit, the name half of "what a session reads as instructions" is one function. The start half is two inline predicates that already differ (`.claude/rules/`, known issue A2). E1's out-of-repo starts would make that three. U2a4's shared check_fix/floor predicate (override row 418) is the natural owner of a single `is_start`, or a start-set producer, and U2b's reader model would feed it.

**Recommendation:** Add a line to the U2a4 bullet: "one start predicate for both walks (closes A2's rules half; the hook for U2b's out-of-repo starts)". No change in this unit.

## What Looks Good

- **One parser, one statement, two consumers** `[unverified — submitted as claim]` (lib, the comment above `import_targets`). The superset is defined as a name contract in one place, with its exceptions scoped to "a session reading the file". That scoping is what lets E1 be routed cleanly instead of growing the parser.
- **Absolute-space resolution** `[unverified — submitted as claim]` (`put`). Making every candidate absolute, clamping `..` at `/` and projecting below one prefix is the right primitive. A root set is a loop over `pre`, not a rewrite.
- **Policy at the walk level** `[unverified — submitted as claim]` (`IMPORT_OUT_MAX` in both walks, `IMPORT_LEFT` handed down). Without a walk-wide budget, the per-file awk bound would not limit what bash accumulates; with it, the walks stop at their remaining budget. U2a3c inherits this only if it stays in main_imports' drain loop, as the plan says.
- **The UTF-8 gate** `[unverified — submitted as claim]` (`UTF8_OK`, `import_targets`). The decode is a pre-pass that produces a second text for the same grammar, not a second grammar, and well-formed text skips the fork.
- **Fail-closed composition with wording** `[unverified — submitted as claim]` (`scripts/dev-cycle.sh` check_fix: `elif ! imported_names; then echo "skip $a: the instruction-file import walk failed…"`). The walk's failure is a first-class caller outcome rather than a hidden "imported".
- The U2a3c bullet now carries every routed constraint, so U2a3c has a concrete brief.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | E1 (out-of-repo starts) and r3 (relative re-entry from another checkout) are start-set and base axes of the reader model. The U2b routing ("a root set") covers only projection. Route E1 to U2b as one three-part reader model, and name it in A5 and the walk headers, not the superset statement | Coupling | plan `:279`; lib `put`/`BEGIN`; A5 | High (decomposition) / Medium (loader start set) |
| 2 | A single `pre` projects a name into a nested worktree as `.claude/wt-X/…` (executed). It fails closed today only because of a rule U2a3c will loosen | Minor | lib `IMPORT_AWK` `BEGIN`, `put` | High |
| 3 | The parser reads ambient state (its own `import_home` call, `ROOT_REAL`, `IMPORT_LEFT`). U2b's home and root sets must remove the internal call. The empty-HOME rule is Bun's and belongs in the revisit trigger | Minor | lib `import_targets`, `import_home` | High |
| 4 | Four stale restatements (A3, F11 and main_imports' "three shapes", the test title "~/ dropped") and enumerated parser causes in the walk headers break the single-source rule | Minor | A3; plan `:126`; lib main_imports header; `build-loop-check.bats:339` | High |
| 5 | The walks share name rules but not the start rule. One start predicate (U2a4) is where A2, E1 and U2b land | Informational | lib imported_names and main_imports start loops | High |

## Overall Assessment

The unit improves the system's structure, and nothing in it is Structural. The parser is a clean leaf with one stated contract. Its resolution primitive generalizes to a root set, and walk-level policy sits in the walks. U2a4 does not have to undo anything. U2b has to remove the parser's internal `import_home` call (finding 3) and replace the single `pre` with nested-aware projection (finding 2); both are small, local edits. The single most important concern is a routing one, not a code one. E1 is real and new to the override log. It is not this parser's to fix, and the "reader root set" already routed to U2b is too narrow to absorb it or r3's relative re-entry. A reader has a start set, a base and a projection, and only the third is routed. This unit is clean to merge once the U2b bullet, A5 and an override row record the three-part reader model (finding 1). The four stale restatements (finding 4) should also be fixed in the same documentation commit. On the trust boundaries, I agree with the L2-i2 security map's B3/B4 placement and add only that B3's loader side has more starts and bases than B1/B2 model.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:**
  - The parser's contract as one unit: sound, but four restatements leak (findings 4, 3).
  - E1's owner: not the parser, not U2a3c. U2b's reader model owns it, and until then it is a named walk-start exception (finding 1, with this repo's mitigations).
  - How E1 relates to the routed root set: it is a different axis (finding 1).
  - Whether the start-set and reader routing across U2a3b, U2a3c and U2b is coherent and complete: the U2a3c bullet is complete. The U2b bullet lacks the start set, the base (r3) and nested projection (findings 1, 2).
  - import_home and the IT_* seam: a good seam with ambient leaks (finding 3).
  - What U2a4 or U2b must undo: only finding 3's internal call and finding 2's single prefix.
  - Prior dispositions: the table above.
- **Out of scope:** the security weight of E1 and of the parent-directory working-tree reader (security-reviewer), the per-file getent fork's cost (performance), and the mutant gaps Stage 1 lists (test-strategy).
- **Escalate:** finding 1 for orchestrator synthesis. Record the routing before merge; no code change is needed here.
- **Questions I would have asked:** whether any session's cwd is ever outside `/workspace` and its `.claude/` worktrees (for example `/home/magfrump/claude-workflows`, the payload's `assembled_from`, which is another checkout and another HOME), and whether the user wants `/workspace` to be barred from holding a parent-directory `CLAUDE.md`.
- **Decisions I made:**
  - I treated E1 as new evidence relative to override row 425, because that row covers names, not starts.
  - I rated finding 1 Coupling, not Structural, because its remedy is a routing and documentation change in this unit.
  - The skill's security-review glob matched only unrelated files, so I used the L2-i2 security-reviewer report's map and labelled it stale.
  - The probe ran only in `/tmp/u2a3barchfin-eLzu` from `git archive e1654266`, with `dc/` standing in for `.claude/` because a hook blocks Bash writes under a `.claude` path. No process was left running, and no worktree file other than this report was written.
