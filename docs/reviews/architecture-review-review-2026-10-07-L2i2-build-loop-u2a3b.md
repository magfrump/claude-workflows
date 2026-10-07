Commit: 98e3b1df

# Architecture Review — feat/build-loop-u2a3b (loop 2, iteration 2, `--loop-pass`, k=1)

**Scope:** `git diff be94c871..98e3b1df -- . ':!docs/reviews'` (dd51e9a7, 98e3b1df: iteration 1's fixes), read against `main...98e3b1df` for context: `IMPORT_AWK`, `import_targets`, `imported_names`, `main_imports` (`scripts/lib/dev-cycle-read.sh:470-707`), `check_fix` wording, A5, F11 and the U2a3c bullet (`docs/working/plan-build-loop-handoff.md:277`).
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md` (42 claims; Claims 9, 11, 13, 14, 18, 20 and 31b are used below as fact and not re-verified). Prior: `architecture-review-review-2026-10-06-L2-build-loop-u2a3b.md` (findings 1-5) and the rubric's "Loop 2, iteration 1" rows.

Scope check: in scope. The parser's public contract changed (the superset statement, the resolution rule, a new python3 stage, a new walk-wide budget constant), and so did a cross-cutting concern: the reader model both walks share and that U2a3c and U2a4 will consume.

## Dependency Map

- `check_fix` (`scripts/dev-cycle.sh`) → `imported_names` → `isimported tree`. The floor (U2a4, not built) → `main_imports` → `isimported main`.
- Both walks → `import_targets` (bash) → `sed` (blanks) → **new** `python3 -I` (a U+FFFD-decoded second copy, only for text holding a byte above 0x7f) → `awk "$IMPORT_AWK"` (scan, splice, emit). `dir` and `root` now reach awk through `ENVIRON`.
- `emit` now resolves in absolute space (clamping `..` at `/`) and projects to repo-relative. `main_imports`' symlink arm still resolves with `realpath -ms` and its own leave-the-repo policy (it fails the walk where the parser drops the name). That makes two resolvers, and they no longer disagree on spelling.
- The walk-level policies sit in the walks: `IMPORT_OUT_MAX` (one constant, checked in each walk's loop), the 4 MiB+1 read cap (tree walk only), and the `.git` skip (main walk only).
- Direction is still sound. The parser is a leaf that both walks depend on, never the reverse, and the new python3 stage is a leaf inside it. Security cross-reference: the most recent security report on this branch, `docs/reviews/security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md` (Commit: be94c871, which predates this diff, so its boundaries may be stale), places the parser boundary at B1/B5 and the superset relation at B4. No recommendation below moves a boundary. Finding 1 says B4's "reader" side is wider than the walk models.

## Iteration-1 findings: disposition check

| Iter-1 finding | Disposition | Holds? |
|---|---|---|
| 1 (Coupling): prefix candidates meet main_imports' checkout-shape fail rule | L2-A6: `.git`/`.git/*` skipped; general rule "routed to U2a3c" | **Partly.** The skip works (fact-check 20, 24; mutant m-git fails). Two gaps remain: the skip covers only a top-level `.git` (finding 3), and the routing is recorded only in the rubric. The U2a3c bullet (plan :277) does not carry the "fail rules a prefix can safely trip" clause, and the override log has no L2 row (finding 2). |
| 2 (Coupling): resolve in absolute space, ENVIRON for dir/root | L2-R1 | **Yes.** `emit` now makes each name absolute, clamps `..` and projects (fact-check 10, 17, 27). The resolution is right for the walk's own root. Finding 1 is about which roots. |
| 3 (Minor): superset claim stated three ways | L2-C3: stated once above `import_targets`; A5 and F11 point to it | **Partly.** A5 and F11 now point to it (fact-check 1, 3). But the single statement leaves out `~/` (fact-check 9), lists one exception that is not one (fact-check 11), and A5 still carries the same item as "untraced", so the claim is again stated two ways (finding 4). |
| 4 (Info): two resolvers, opposite leave-the-repo policies | none recorded | **Unchanged.** The awk copy now matches `realpath -ms`'s lexical rule, but the comment does not say it mirrors the symlink arm, and nothing tells U2a3c not to add a third resolver (finding 6). |
| 5 (Info): mawk coupling | ENVIRON removes the `-v` trap | Yes (fact-check 17, 28). |

## Findings

#### 1. The superset is computed against the walk's own environment (ROOT_REAL, and `~/` dropped), but the reader is a Claude Code session in another checkout with its own HOME. Claim 9's `~/` hole is one case of this, and absolute imports into the main checkout are another.

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:526-536` (`emit`: `if (c == "" || substr(c, 1, 2) == "~/") return`, `if (substr(c, 1, 1) != "/") c = root "/" dir "/" c`, `if (index(out, pre) != 1 || length(out) <= length(pre)) return`), `:561` (`root = ENVIRON["IT_ROOT"]`), `:580` (`IT_ROOT="$ROOT_REAL"`); plan `:279` (U2b: the gate runs in "a fresh worktree at MAIN_SHA")
**Move:** 3 (the parser's contract to its consumers; B4), 2
**Confidence:** Medium (the walk side was executed; the Claude Code side is reasoned from the fact-check's binary reading, and `AD()`, its in-project test, was not traced)
**Legibility-target:** for-author (the U2a3b comment), for-orchestrator-synthesis (U2a3c/U2b carry)
**Executed vs reasoned:** executed for the walk side. From a `git archive 98e3b1df` copy (`/tmp/u2a3barchL2i2-*`), `import_targets ""` with `ROOT_REAL=/workspace/.claude/wt-gate` on `See @/workspace/docs/x.md` printed nothing (rc=0). With `ROOT_REAL=/home/u/proj HOME=/home/u`, `See @~/proj/docs/x.md` printed no `docs/x.md`, which matches fact-check Claim 9.

The parser's contract is "every name Claude Code 2.1.292 can import". Claude Code resolves a relative name against the importer's directory, which is checkout-independent, and the parser models that correctly. It resolves the other two spellings against the **reader's** environment: an absolute name against nothing (it is kept only if it lies inside the reader's project), and `~/` against the reader's `os.homedir()` (fact-check 9: `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))`). The parser substitutes the walk's environment for both. It uses one root, `ROOT_REAL`, and drops `~/` outright. The floor guards main's files for every session that later reads them. Those sessions run in the main checkout (`/workspace`) and in other worktrees, while U2b plans to run the gate in "a fresh worktree at MAIN_SHA". So `@/workspace/docs/x.md` in main's CLAUDE.md is a real import for every session in `/workspace`, yet the gate walk drops it. This is a fail-open in the floor, not a precision loss, and it is pre-existing: main's `realpath --relative-to="$ROOT_REAL"` had the same dependence. Iteration 1's L2-R1 closed absolute spellings only relative to the walk's own root, and override row 350's "absolute imports into the repo" deferral had not separated the two. Claim 9's `~/` hole is the same defect along a second axis (HOME). Patching it alone by resolving against the walk's `$HOME` would repeat the mistake, because the gate's HOME is not guaranteed to be the reader's (tests and sandboxes override it).

**Recommendation:** Model it as roots, not as a special case. `emit` takes a **set of reader roots** (`IT_ROOTS`, newline-separated, through ENVIRON as now) and a **home** (`IT_HOME`). A `~/` name becomes `home "/" rest` and then goes through the same lexical resolve. An absolute or home-resolved name is kept when it lies below any root, and it is printed relative to that root, so the output is still repo-relative and the consumers do not change. The `dir`-relative arm keeps using the walk's own root. The parser should not choose the set; its caller should. For U2a3b, keep `IT_ROOTS="$ROOT_REAL"` and `IT_HOME="$HOME"` so behaviour is unchanged except that `~/` is now read. Name "absolute or `~/` names that resolve into another checkout of this repo, or under another user's home" as a known exception in the one statement. Give U2b (which "names the checkout `--check` runs in") the job of filling the set: `ROOT_REAL` plus every `git worktree list --porcelain` path, plus the HOME of the account sessions run under. Record that in the U2b bullet and in A5. One cheap, HOME-independent over-approximation is also available if the user prefers no environment input: for `~/rest`, take every component suffix of the normalized `rest` as a repo-relative candidate. It is linear in components and a superset for any HOME, at the cost of more false positives.

#### 2. Iteration 1's routed items exist only in the rubric. The U2a3c bullet and the override log carry neither the prefix-safe fail rule nor the main walk's uncapped read.

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:277` (U2a3c bullet, unchanged since main); `docs/reviews/override-log.md` (the last `feat/build-loop-u2a3b` rows, 413-424, are iteration-3 rows; there are no loop-2 rows); rubric L2-A6 ("routed to U2a3c"), L2-C5 ("The main walk still reads a blob whole ...: deferred"), L2-C6 ("Deferred (Low; a U2a3c design question)")
**Move:** 3, 8
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Executed vs reasoned:** reasoned (`git diff be94c871..98e3b1df -- docs/working/plan-build-loop-handoff.md` changes only F11; grep of the plan for "prefix" finds nothing about candidates)

The U2a3c bullet reads: "after main's walk reaches a fixpoint, a second phase walks the checkout's start files main lacks and the imported paths main lacks, and only appends; an unsearchable checkout directory fails the walk. ... every phase-2 item passes one admission check (main's links and gitlinks, the checkout's links) before it is marked seen". It still describes phase 2 as working on *imported paths*, meaning exact names, and its seed ("the imported paths main lacks") is now the whole prefix superset. The U2a3c implementer reads the plan, not this unit's rubric, so the coupling iteration 1 found (a checkout-shape rule written for exact names, now applied to every prefix) will be rebuilt in phase 2.

**Recommendation:** Add to the U2a3c bullet: (a) phase 2's seeds and admission check apply to every superset candidate, so its fail rules must be ones a prefix can safely trip (fail on a non-plain node such as a link, gitlink or unsearchable directory, never on "the checkout holds a file main lacks", e.g. an ignored `.env` beside `@.env.example`); (b) phase 2 reads checkout files, which are unreviewed, so it must read them through the same capped reader as the tree walk (finding 5); (c) L2-C6 (blocker per prefix). Add the loop-2 Defer rows to the override log with these triggers.

#### 3. The `.git` skip encodes git's invariant only at the top level

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:702-703`
**Move:** 8
**Confidence:** High (fact-check 20's scope note; reasoned from git's path rule)
**Legibility-target:** for-author
**Executed vs reasoned:** reasoned

Evidence: `# git stores nothing at .git, so a prefix candidate there (from @.gitignore) names no file main has.` / `[[ "$p" != .git && "$p" != .git/* ]] || continue`. The comment's reason is true of any `.git` path component (git refuses to track one anywhere), but the test matches only the top level. A `@sub/.gitignore` beside a nested repo or a submodule checkout (`sub/.git` is a gitfile or directory) still trips the checkout-shape rule and fails the whole main walk, which is the iteration-1 finding-1 failure one directory down. Making the rule match its stated reason costs one pattern and removes a special case U2a3c would otherwise inherit.

**Recommendation:** `[[ "/$p/" != */.git/* ]] || continue` (any `.git` component), with the comment kept as is. Add a test with `@sub/.gitignore` and a nested `sub/.git` file.

#### 4. The "one statement" mixes the parser's name contract with the walks' file contract, and it is already stated two ways again

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:496-513` (the superset comment), `:525` (the trim comment); `docs/working/known-issues-dev-cycle.md:18` (A5's "Untraced" list); `test/scripts/build-loop-check.bats:552,557`
**Move:** 3, 5
**Confidence:** High (rests on fact-check 9, 11, 13, 31b)
**Legibility-target:** for-author
**Executed vs reasoned:** reasoned

The comment's known exception (a), "a .. after a symlinked directory, which the kernel follows through the link while both Claude Code and this walk resolve it lexically (row 350)", describes no parser miss. Both resolvers collapse `..` before any open, so the parser lists exactly the name Claude Code opens (fact-check 11). The real residue there is name-to-file aliasing: `@linkdir/x.md` is the name both sides compute, but the file it reaches is under the link's target. That is a property of the walks (A3, A5, main_imports' stored-link rules), not of the parser. Meanwhile A5 still lists "whether an `@` token's `..` after a directory link resolves through the link" and "whether a symlinked instruction file's imports resolve from the link's directory" as untraced, while the comment asserts the first. The fact-check reports that the same binary passage answers both, so code and A5 now disagree, which is exactly what L2-C3 set out to remove. The emit comment's "(an escaped space can lead it)" and the test title "as Claude Code decodes it ... a leading escaped space is trimmed" present an over-read as part of the superset (fact-check 13, 31b). That pins a non-requirement as a requirement, so a later, tighter parser would be told it broke the contract.

**Recommendation:** Scope the statement to names. Drop exception (a) from it and put `~/` (or finding 1's root-set wording) in its place, plus the existing "further decoding" item. Move the link-aliasing residue to A5, with the two "untraced" items rewritten as traced: lexical, and resolved from the target's directory. Relabel the trim case as an over-read in its test and comment, following the convention of the over-read test (`:366-368`).

#### 5. The reader model is split across layers: decoding happens in the parser, the size cap only in the tree walk

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:569-575` (decode in `import_targets`), `:614-616` (`out="$(head -c 4194305 -- "$f" | import_targets "$d")"`, tree walk only), `:687` (`out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")"`, main walk, uncapped)
**Move:** 2, 7
**Confidence:** High
**Legibility-target:** for-author, for-orchestrator-synthesis (U2a3c)
**Executed vs reasoned:** reasoned; the pipefail detail was executed (`set -o pipefail; head -c 50000000 /dev/zero | head -c 10 >/dev/null` → 141)

Three facts about how Claude Code reads a file make up its "reader model": it decodes as UTF-8 with U+FFFD, it skips any file over 4 MiB, and it applies the grammar. This diff puts the first and third in `import_targets` and the second in one caller. The main walk's omission was dispositioned as "main's content, reviewed: deferred" (L2-C5), and for main's blobs that is defensible. The structural cost lands in U2a3c, whose phase 2 runs inside main_imports' drain loop and reads unreviewed checkout files. If it copies main's read arm, it inherits no cap. The obvious consolidation, a `head -c` inside `import_targets`, carries a trap: under the walks' `pipefail`, closing the pipe early makes `git cat-file` exit 141, so the main walk would fail closed on every blob over 4 MiB instead of over-reading it.

**Recommendation:** Give the reader model one home: either `import_targets` caps its own stdin and drains the rest (`{ head -c 4194305; cat >/dev/null; }`), or a small `read_capped` helper is used by every read arm. Then the tree walk, the main walk and U2a3c's phase 2 share one rule. If this stays deferred, state the rule in the U2a3c bullet (finding 2b) and add an override row.

#### 6. Two resolvers remain, with no pointer between them

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:526-536` (`emit`) vs `:675-683` (symlink arm: `realpath -ms --relative-to="$ROOT_REAL"`, then `[[ "$out" != .. && "$out" != ../* ]] || { IMPORTED_MAIN=error; return 1; }`)
**Move:** 2, 7
**Confidence:** Medium
**Legibility-target:** for-author (U2a3c implementer)
**Executed vs reasoned:** reasoned

Iteration 1's finding 4 asked for a note that the awk resolver mirrors `realpath -ms` in absolute space, so that U2a3c does not add a third. The fix made the two agree on spelling, but no comment links them, and their leave-the-repo policies still differ on purpose: drop a name, fail on a link. Finding 1's root set would widen the gap, because the parser would accept other checkouts' roots while the symlink arm fails on anything outside `ROOT_REAL`.

**Recommendation:** Add one line in each place naming the other and its policy, and say in the U2a3c bullet that phase 2 resolves names through `emit` and links through the symlink arm, with no new resolver.

#### 7. The python3 decode is a pre-pass feeding the one parser, not a second parser, but it adds a runtime dependency the lib does not declare

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:573-575`
**Move:** 1
**Confidence:** High
**Legibility-target:** for-author
**Executed vs reasoned:** reasoned (fact-check 12 executed the no-python3 case: rc=1 for non-ASCII text, rc=0 for ASCII)

`d="$(printf '%s\n' "$toks" | python3 -I -c '...decode("utf-8", "replace").encode()...')" || return 1; [[ "$d" == "$toks" ]] || toks+=$'\n'"$d"`. The decoded copy is appended as more lines and scanned by the same awk program with the same `seen` dedupe, so there is one grammar, one resolver and one output contract, and the decode is an input normalization like the sed blanking. That is the right shape: it keeps "two spellings, one parser" instead of forking the grammar. It also keeps the encoding model in python3 (the critic's byte-for-byte match is against Node's decoder, per fact-check 15) rather than re-implementing UTF-8 validation in awk. The cost is a new runtime dependency. On a host without python3, any instruction file holding a non-ASCII byte fails the walk, so `--check-fix` refuses and the floor refuses everything. The lib header and dev-cycle's docs do not list python3, and the commit's justification ("questions.sh") is a different script.

**Recommendation:** Name python3 in the lib header's dependency or failure paragraph (one line). No structural change is needed.

#### 8. IMPORT_OUT_MAX is a walk-level budget spelled in each walk, which is fine as long as U2a3c stays in the one drain loop

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:482-485`, `:617-620`, `:693-696`
**Move:** 7, 8
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis (U2a3c)
**Executed vs reasoned:** reasoned (fact-check 7, 25 executed both checks and their mutants)

The budget is per walk, not per parser call, so it belongs in the walks. One shared constant with a three-line take-output step (`[[ -n "$out" ]] || continue`, budget, lower and append) is copied in both loops, and that copying is acceptable at two copies. The structural dependency is on U2a3c. The plan already says phase 2 is "one drain loop run over two seedings", and if it is built that way, phase 2 is charged to the same `used` automatically. A separate phase-2 loop would need its own copy of the check, and would easily miss it.

**Recommendation:** None for U2a3b. Add "phase 2 shares main_imports' `used` budget (IMPORT_OUT_MAX)" to the U2a3c bullet, with finding 2's other clauses. If a third consumer appears, factor the take-output step into a helper.

## What Looks Good

- **Resolution is now canonical-then-project.** `emit` makes the name absolute, normalizes with path.resolve's clamping, and only then decides "inside the repo?". That closed four holes with one rule (fact-check 10, 27) and leaves finding 1's root set as a parameter change rather than a redesign.
- **ENVIRON for dir and root** removes the only awk-portability trap the previous review found.
- **One parser, two spellings.** The U+FFFD copy is fed to the same awk program, so the grammar was not forked (finding 7).
- **Failure statuses are normalized.** `import_targets` returns 1 for sed, python3, awk or bound failures, and both walks map that to `error` as before.
- **The single-statement move is the right shape:** A5 and F11 point at the code comment instead of restating it. Finding 4 is about its content, not its placement.
- **The `.git` skip** is placed after the `ent` lookup, so it can only affect names main lacks, which is the minimal blast radius.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The superset is resolved against the walk's environment (one ROOT_REAL, `~/` dropped), not the reader's: `@/workspace/docs/x.md` is dropped by a gate in another worktree (executed); Claim 9's `~/` is the same class. Model a root set plus home, filled by the caller (U2b) | Coupling | `dev-cycle-read.sh:526-536,561,580` | Medium |
| 2 | Routed items (prefix-safe fail rules, capped checkout reads, blocker per prefix) live only in the rubric; the U2a3c bullet and override log carry none | Minor | `plan-build-loop-handoff.md:277`; override-log | High |
| 3 | The `.git` skip matches only the top level; its own reason covers any `.git` component (`@sub/.gitignore` still fails the walk) | Minor | `dev-cycle-read.sh:702-703` | High |
| 4 | The one statement mixes the name and file contracts: exception (a) is not a parser exception, `~/` is missing, A5's "untraced" items contradict it, and the trim over-read is labelled as a requirement | Minor | `dev-cycle-read.sh:496-513,525`; A5; `build-loop-check.bats:552` | High |
| 5 | The reader model is split: decode in the parser, 4 MiB cap in the tree walk only; U2a3c phase 2 would inherit an uncapped read; `head` inside the parser trips pipefail (141) | Minor | `dev-cycle-read.sh:569-575,614-616,687` | High |
| 6 | Two resolvers remain with no cross-pointer; a root set would widen their policy gap | Informational | `dev-cycle-read.sh:526-536` vs `:675-683` | Medium |
| 7 | The python3 decode is a pre-pass to the one parser (good shape), but python3 is an undeclared runtime dependency that fails closed | Informational | `dev-cycle-read.sh:573-575` | High |
| 8 | IMPORT_OUT_MAX is correctly walk-level; U2a3c must stay in the one drain loop to inherit it | Informational | `dev-cycle-read.sh:617-620,693-696` | High |

## Overall Assessment

Iteration 1's two coupling findings were fixed in the right place and the right shape. The parser now canonicalizes in absolute space and stays a leaf, and the decode stage keeps one grammar. The remaining structural concern is one level up. The parser's contract is defined against the walk's environment (its one root, and no home), while the property the floor needs is about a different reader: a Claude Code session in another checkout of the repo, with its own HOME. Claim 9's `~/` hole and the dropped `@/<main checkout>/…` import are two instances of that one gap (finding 1). It is fixable in place by making roots and home parameters the caller supplies, but the caller that knows the answer is U2b, so it has to be written into the plan now. The other findings are about bookkeeping and where things live: the routed items are not in the U2a3c bullet (findings 2, 5, 6, 8), the `.git` rule is narrower than its reason (finding 3), and the single statement needs pruning to the name contract (finding 4). None needs restructuring.

**What U2a3c (plan :277) must now carry:** (1) phase 2's seeds and admission check see every superset prefix, so its fail rules must be prefix-safe: fail on a non-plain node, never merely because the checkout holds a file main lacks (iteration-1 finding 1, L2-A6); (2) a capped reader shared with the tree walk for checkout files, with no early-close under pipefail (finding 5, L2-C5); (3) phase 2 runs in main_imports' one drain loop and is charged to its `used`/IMPORT_OUT_MAX budget (finding 8); (4) no third resolver: names through `emit`, links through the symlink arm (finding 6); (5) blocker per prefix candidate (L2-C6); (6) a `.git` component at any depth is skipped, if finding 3 is not fixed here. U2b's bullet (plan :279) should carry finding 1's root set: ROOT_REAL plus every worktree path, plus the session HOME.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 98e3b1df` line at the top.
- **Answered:** iteration-1 findings 1-4 checked against their dispositions (table above: 2 and 5 hold, 1 and 3 hold partly, 4 is unchanged); the python3 decode is one parser with a pre-pass (finding 7); IMPORT_OUT_MAX as a walk-level budget (finding 8); the head cap's asymmetry (finding 5); how to model Claim 9's `~/` (finding 1: a root set plus a home, supplied by the caller, with U2b owning the set; a HOME-free suffix alternative is noted); Claim 11 (finding 4); what U2a3c must carry (Overall Assessment).
- **Out of scope:** the security weight of the cross-checkout fail-open (finding 1) and the python3 decoder's fidelity, which belong to security-reviewer; the cost of the decode fork (fact-check 36b), which belongs to the performance reviewer.
- **Escalate:** finding 1 for orchestrator synthesis. It is a fail-open of the floor's premise (pre-existing on main), and its fix needs a U2b decision about which checkouts count as readers.
- **Questions I would have asked:** whether sessions that consume main's instruction files ever run from a checkout other than `/workspace` and its worktrees (that sets finding 1's root set), and whether the user wants the walk to read the environment (HOME) at all, or prefers the HOME-free suffix over-read.
- **Decisions I made:** I treated the cross-checkout absolute case as new evidence relative to override row 350, which deferred "absolute imports into the repo" without separating the walk's root from the reader's. I rated finding 1 Coupling rather than Structural because the fix is a parameter of an otherwise well-placed leaf. Probes ran only in `/tmp/u2a3barchL2i2-*` from `git archive 98e3b1df`, and no worktree file other than this report was written.
