Commit: 5d175c0e

# Architecture Review — feat/build-loop-u3b3 (iteration 2)

**Scope:** branch diff `main...5d175c0e` (docs/reviews/ excluded): `scripts/lib/dev-cycle-read.sh` (git_harden, HARDEN, CALLER_COUNT), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `test/lib/d6-snippet.bash`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-check.bats`, the plan's U3b3 as-built note; read against `build-loop.sh`'s `store_check`, `default_gate`, `caller_gate` and override rows 200, 281, 311, 495, 505, 509, 548, 644, 648, 666, 702, 704, 709
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b3-i2.md` (57 claims: 49 verified, 5 mostly accurate, 3 unverifiable; two escalations to security)

Scope check: in scope. The diff moves a cross-cutting concern (process-wide git hardening) from one script into the shared lib and gives the lib's public surface a new function and two globals (`git_harden`, `HARDEN`, `CALLER_COUNT`). It also adds a new module (`test/lib/d6-snippet.bash`), which is the orchestrator's only entry point to both scripts and a forward contract on U4's SKILL.md.

Trust-boundary cross-reference: the newest security review on disk is `docs/reviews/security-review-egress-zone-entries-2026-09-19.md` (Commit: `7c970bfe1660681c71ea51853eb894416fb31131`). It covers another subsystem and predates this diff, so its boundaries may be stale here, and no security review for this commit exists yet. No finding below recommends moving the snippet's trust-root selection, the extraction dir or the gate repository, so the cross-reference constrains nothing.

## Dependency Map

- **The orchestrator (U4, not yet written)** runs `bash -s -- SCRIPT ARG... <<'D6'` (the D6 snippet). In claude-workflows (main's first-parent root is `D6_ROOT`), the snippet runs `{build-loop,dev-cycle,questions}.sh` and `lib/dev-cycle-read.sh`, extracted from main. Anywhere else it runs the root-owned `/opt/claude-workflows/scripts/SCRIPT`. The snippet depends on nothing in the repository's code. It restates, as literal text, the lib's HARDEN pairs and git_harden's environment (`g()`, `test/lib/d6-snippet.bash:34`), and a subset of `build-loop.sh`'s state and default-branch policy (`:40-47`) and its object re-hash (`:53-55`).
- **build-loop.sh and dev-cycle.sh** each run `source lib/dev-cycle-read.sh`, then `scrub_reexec`, then `git_harden` (`build-loop.sh:496`, `dev-cycle.sh:128`). The direction is correct: both volatile entry scripts depend on the shared lib, and the lib imports nothing. One back-edge exists only in data and prose. The lib sets `CALLER_COUNT`, which only `build-loop.sh`'s `caller_gate` reads (`build-loop.sh:563`), and the lib's header explains itself in terms of `build-loop.sh`'s `caller_gate`, `merge_ident`, `store_check` and state gate.
- **`caller_gate`** reads `HARDEN` from the lib (`build-loop.sh:566`). A key added to the list is therefore refused by name with no edit to `build-loop.sh`. That is the one coupling this diff tightens on purpose.
- **Tests:** one test (`build-loop-orchestrator.bats:338-353`) pins three things to each other: the lib's exported environment, a literal list `H`/`E` in the test, and the snippet's `g()` line. Two other tests enumerate the HARDEN keys literally (`build-loop-check.bats:1699`, `build-loop-orchestrator.bats:368`).

## Findings

#### 1. Row 704 expects U3b3's git_harden to be the orchestrator's hardened git wrapper; as built, the orchestrator cannot reach it

**Severity:** Minor
**Location:** `docs/reviews/override-log.md:704`; `scripts/lib/dev-cycle-read.sh:326-357`; `test/lib/d6-snippet.bash:34`; `docs/working/plan-build-loop-handoff.md:326`
**Move:** 3 (module boundary), 1 (dependency direction)
**Confidence:** High
**Legibility-target:** U4's author, who writes the SKILL.md flow and must decide how the orchestrator's own git reads are hardened

Row 704 defers the orchestrator's bare-git exposure to U4 and names this unit's function as the answer: the orchestrator's git reads go "through build-loop.sh or a hardened wrapper ... U3b3's git_harden is the shared wrapper". As built, `git_harden` lives only inside the uid-writable lib. Its only callers are the two scripts after they source that lib. The snippet's own design rule is that nothing is sourced before it is checked, so the orchestrator's shell cannot source it either. The snippet's `g()` is local to the snippet's `bash -s` process and does not survive into the orchestrator. So U4 has no shared wrapper. Either every orchestrator git read goes through a script mode (via D6), or SKILL.md writes a third copy of the HARDEN list (after the lib and the snippet) with no pin. The as-built note lists the rows U3b3 discharges and does not mention 704, so U4's author would read the stale row and expect a wrapper that does not exist.

Evidence (verbatim):
- `docs/reviews/override-log.md:704`: `Revisit trigger: U4's SKILL.md: the orchestrator's git reads go through build-loop.sh or a hardened wrapper, never bare git in its shell; U3b3's git_harden is the shared wrapper.`
- `test/scripts/build-loop-orchestrator.bats:349`: `    # The snippet cannot source the lib (it runs before anything is checked): its one git line repeats both lists.`
- `test/lib/d6-snippet.bash:34`: `  g() { GIT_NO_REPLACE_OBJECTS=1 GIT_CONFIG_GLOBAL=/dev/null ... git -c core.useReplaceRefs=false ... -c log.showSignature=false "$@"; }` (excerpt: the full line is quoted at the diff's line 250; it lies inside `d6()`, which runs to `:76`)

**Recommendation:** Amend row 704's revisit text (or add one line to the U3b3 as-built note) to say what the wrapper actually is. Either "the orchestrator's git reads go through a build-loop.sh mode via D6", or "U4 adds a pinned third copy". Then U4 starts from the real constraint.

#### 2. The HARDEN key list is repeated literally in two "every git call carries" tests that nothing pins to HARDEN

**Severity:** Minor
**Location:** `test/scripts/build-loop-check.bats:1699`; `test/scripts/build-loop-orchestrator.bats:368`; `scripts/lib/dev-cycle-read.sh:348`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** the next author who adds a HARDEN key (as this unit added log.date and log.showSignature), who must find every copy

The list now has these copies: the lib (canonical), the snippet's `g()`, the pin test's `H`, and two shim-test loops. U4's SKILL.md will add a sixth. Two of the copies are tied together through `H`: the lib's export must equal it and so must the snippet's line, and this pinning is the right answer to a duplication the bootstrap forces. The two shim loops are not pinned. Each checks that the keys it names are present, not that it names every key. A key added to HARDEN and to the pinned copies, but not to these loops, leaves both tests green and quietly narrower than their names: "every git call --check makes carries git_harden's config pairs" and "every git call dev-cycle.sh makes carries git_harden's pairs". This unit had to edit both loops by hand to add the two new keys, which shows the propagation cost.

Evidence (verbatim):
- `test/scripts/build-loop-check.bats:1699`: `    for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false log.date=default log.showSignature=false G=/dev/null P=none S=1; do`
- `test/scripts/build-loop-orchestrator.bats:368`: the same line, byte for byte.
- `scripts/lib/dev-cycle-read.sh:348`: `HARDEN=(core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false log.date=default log.showSignature=false)`

**Recommendation:** Have both loops take their keys from the lib, for example `source "$REPO_ROOT/scripts/lib/dev-cycle-read.sh"; for kv in "${HARDEN[@]}" G=/dev/null P=none S=1`. That leaves exactly one forced literal copy (the snippet), and it is pinned.

#### 3. The snippet's object re-hash is a second, narrower store_check, and the two do not refer to each other

**Severity:** Minor
**Location:** `test/lib/d6-snippet.bash:49-55`; `scripts/build-loop.sh:926-985` (`store_check`); `docs/working/plan-build-loop-handoff.md:326` (rows 644/648 closure)
**Move:** 2 (responsibility), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** whoever next hardens either object verifier (the store_check history shows one fix per review round), who has no pointer to the other

Rows 644/648 closed as "not moved" because "the digest re-hashes nothing, so its only caller stays build-loop.sh". That is true of the lib. Not moving store_check is also forced, because the snippet cannot source the lib. The diff still adds a second implementation of the same invariant, "the objects that choose what runs hash to their ids", and the two policies differ:
- store_check walks every tree and blob below each revision, handles sha1 and sha256, and refuses an id that has a second copy in the store. Its comment says why: two reads of one id "took different ones".
- The snippet re-hashes commits and three trees in one `cat-file --batch`, is SHA-1 only, and then lets `ls-tree` and `cat-file blob` re-read the trees in separate processes. That is the same two-reads shape, with no second-copy rule. Its blob copies are covered after the fact, because the extracted bytes are hashed against the ids `ls-tree` returned.

The fact-check found that a loose plus packed second copy of a tree is read the same way by both (its P2/P3). My two-pack probe (a newer pack holding a forged `scripts` tree under the true id together with a copy of the tip commit) also read the true tree in `ls-tree`. So no divergence is shown. The structural cost is that neither comment names the other. A future store_check rule (sha256, or another second route to an id) will not reach the snippet, and the snippet's list of what it does not check is unstated.

Evidence (verbatim):
- `scripts/build-loop.sh:935-938`: `# main's or of this call may have a second copy in the store: in two packs, or` / `# loose and packed. git can read either copy of an id, and two reads of one id` / `# (cat-file --batch here, cat-file blob MAIN:PATH in brief_fields) took` / `# different ones (U3a1 i1 security F1: ...` (excerpt from the header comment of `store_check`, which runs to `:985`)
- `test/lib/d6-snippet.bash:52-53`: `    # down to scripts/lib/. D6_ROOT is a SHA-1 id, so the repository is SHA-1.` / `    { g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"; } | g cat-file --batch \` (excerpt: inside `d6()`, continued by the perl check at `:54` and the refusal at `:55`)
- `docs/working/plan-build-loop-handoff.md:326`: `644/648 not moved (store_check: the digest re-hashes nothing, so its only caller stays build-loop.sh)`

**Recommendation:** Add a cross-reference line to each comment. The snippet's line should name store_check as the full policy and say what it omits (second copies, sha256) and why that is acceptable before main's own gate runs. Store_check's line should name the snippet as a reduced copy to update alongside it. Whether the second-copy rule is needed in the snippet is security's call; it is not raised here as a finding.

#### 4. git_harden puts build-loop.sh's state into the shared reader lib

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:326-357`
**Move:** 2 (responsibility), 1 (dependency direction)
**Confidence:** Medium
**Legibility-target:** a maintainer of dev-cycle.sh or a third script that calls git_harden, who inherits a global and a call-once rule meant for build-loop.sh

Moving the hardening into the lib is right, because it discharges row 495's Coupling. Two details still point the shared lib back at one consumer:
- `CALLER_COUNT`, which the U3b1 contract had build-loop.sh capture "before it runs", is now set as a side effect of `git_harden`. It is a global that only `caller_gate` reads, as the lib's own shellcheck note says.
- The header describes `build-loop.sh`'s `caller_gate`, `merge_ident`, `store_check` and state gate.

The function is also not idempotent. A second call in the same process reads the hardened count, so `CALLER_COUNT` would cover HARDEN's own pairs, and `caller_gate` would then refuse them as caller pairs. Today that is safe only because each script calls it once, after `scrub_reexec`, in the child that `scrub_reexec` starts. The comment states this rule ("call it once") but nothing enforces it. The lib, which is named a reader, now also owns process-wide environment mutation. That stretches its responsibility, but at this scale the stretch is acceptable.

Evidence (verbatim):
- `scripts/lib/dev-cycle-read.sh:350-354`: `git_harden() {` / `  local c="${GIT_CONFIG_COUNT:-0}" kv` / `  [[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { ... exit 1; }` / `  # shellcheck disable=SC2034  # read by build-loop.sh (caller_gate)` / `  CALLER_COUNT="$c"` (excerpt: the function continues with the HARDEN export loop and the `export GIT_CONFIG_COUNT=... GIT_ALLOW_PROTOCOL=none` line, and ends at `:357`)
- `scripts/lib/dev-cycle-read.sh:327-329`: `# hardened, but where a caller hands back its own setting on purpose` / `# (build-loop.sh's caller_gate reads the caller's count, merge_ident its global` / `# config); build-loop.sh and dev-cycle.sh call it once, after scrub_reexec and`

**Recommendation:** Either make the second call a no-op (`[[ -z "$CALLER_COUNT" ]] || return 0` at the top), so that call-once is enforced and not only stated, or have build-loop.sh capture `CALLER_COUNT` itself before the call, as before. Both are one-line changes. No restructuring is needed.

#### 5. The snippet restates default_gate's and state_gate's branch, replace-ref and graft rules with no pin

**Severity:** Informational
**Location:** `test/lib/d6-snippet.bash:40-47`; `scripts/build-loop.sh:578-596` (`default_gate`); `scripts/lib/dev-cycle-read.sh:563` (`resolve_main`)
**Move:** 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** whoever changes the default-branch rule (a third branch name, origin/HEAD handling), who must change the snippet and SKILL.md too

The snippet decides "exactly one of main and master, not symbolic, its ref a commit", which mirrors `default_gate`, plus "no replace ref, no info/grafts", which mirrors part of `state_gate`. For `build-loop.sh` this is a pre-check, and the script's own gate runs again afterwards, so a drift between the two fails closed in one direction and blocks the orchestrator in the other. For `dev-cycle.sh`, which runs no default_gate (row 548), the snippet's copy is the only "exactly one" rule, and it can choose a different branch from the one `resolve_main` reads (origin/HEAD). That part is row 548's settled class. The point here is only that there are now three statements of the policy, and no test asserts that they agree.

Evidence (verbatim):
- `test/lib/d6-snippet.bash:44-45`: `  m=""; for n in main master; do g show-ref --verify -q "refs/heads/$n" && m+="$n "; done` / `  m="${m% }"; [[ "$m" == main || "$m" == master ]] || no "the default branch is not exactly one of main and master"` (excerpt: inside `d6()`, which runs to `:76`)
- `scripts/build-loop.sh:580-581`: `  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then` / `    echo "refuse state default-branch: both main and master exist"; bad=1` (excerpt: `default_gate` continues to `:596`)

**Recommendation:** A one-line comment above the snippet's checks naming `default_gate`/`state_gate` as the full rule ("a pre-check; the script's own gate repeats it") is enough for now. Revisit if the default-branch rule ever changes.

#### 6. The snippet's canonical copy is in test/lib/, and the plan and the header disagree on which copy is the source

**Severity:** Informational
**Location:** `test/lib/d6-snippet.bash:3-10`; `docs/working/plan-build-loop-handoff.md:321`
**Move:** 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** U4's author, and whoever edits the snippet after U4 lands (which file first?)

Production code, the orchestrator's only entry point, lives under `test/lib/`, next to test fixtures. Plan step 8 calls the test/lib file "a byte copy of the SKILL.md block". The snippet's header says "U4 puts this file, byte for byte, in skills/dev-cycle/SKILL.md". The pin test greps `^  g() { ` in the test/lib copy, so test/lib is the de-facto source today. T33's byte equality, once U4 adds it, makes either direction safe. Still, the edit-first rule should be stated once, and U4 is the moment to decide whether the file moves next to `scripts/` (for example `scripts/d6-snippet.bash`) so the SKILL.md block is visibly a copy of a script and not of a test helper.

Evidence (verbatim):
- `test/lib/d6-snippet.bash:3-4`: `# build-loop.sh (the gate) and dev-cycle.sh (the digest). U4 puts this file,` / `# byte for byte, in skills/dev-cycle/SKILL.md, the root-owned image copy, as`
- `docs/working/plan-build-loop-handoff.md:321`: `T33, T36 and T37 test the D6 snippet, which U3b ships as `test/lib/d6-snippet.bash`, a byte copy of the SKILL.md block; a test asserts the two match.` (excerpt from step 8)

**Recommendation:** In U4, name one canonical file in both the plan and the header, and consider moving it out of `test/lib/`.

## What Looks Good

- **One HARDEN list, read by caller_gate.** The two new keys are refused by name in `--state` without touching `caller_gate` (`build-loop.sh:566`). That is the Open/Closed behaviour the U3b1 contract asked for, and it is the main payoff of the move.
- **Call order matches the dependency order.** Each script sources the lib, re-execs through `scrub_reexec`, then calls `git_harden` before its first git call (`build-loop.sh:441-496`, `dev-cycle.sh:100-128`). Argument parsing in between makes no git call. The fact-check verified that `questions.sh` and the lib inherit the exported environment (its Claims 1, 20, 21).
- **The scripts know nothing about D6.** The snippet extracts all four files with their layout, so each script's existing `SCRIPT_DIR`-relative lib and `questions.sh` lookup works unchanged. The entry scripts gain no parameter and no D6-specific branch.
- **The snippet is a script, not a pasted function.** `bash -s` with stdin from `/dev/null` isolates it from the caller's shell (zsh, aliases) and from main's script reading the heredoc. It exports no pair, so `--state` passes `caller_gate` by construction (row 702), and T33 pins that.
- **Forced duplication is pinned.** Where the bootstrap rules out sharing (the snippet cannot source an unchecked lib), the test pins the copy to the lib, which is the right substitute for a shared module.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Row 704 expects git_harden as the orchestrator's wrapper; the orchestrator cannot reach it | Minor | `override-log.md:704`; `dev-cycle-read.sh:326-357` | High |
| 2 | HARDEN keys repeated literally in two unpinned "every git call" tests | Minor | `build-loop-check.bats:1699`; `build-loop-orchestrator.bats:368` | High |
| 3 | Snippet re-hash is a narrower second store_check with no cross-reference | Minor | `d6-snippet.bash:49-55`; `build-loop.sh:926-985` | Medium |
| 4 | git_harden sets a build-loop.sh-only global and is not idempotent | Minor | `dev-cycle-read.sh:326-357` | Medium |
| 5 | Snippet restates default_gate/state_gate rules with no pin | Informational | `d6-snippet.bash:40-47`; `build-loop.sh:578-596` | Medium |
| 6 | Snippet's canonical home is test/lib/; plan and header disagree on the source copy | Informational | `d6-snippet.bash:3-10`; plan `:321` | Medium |

## Re-flagged settled decisions

- **Rows 644/648 (store_check to the lib, closed "not moved"):** finding 3 does not dispute the closure, since the snippet cannot source the lib. It flags that the closure's reason ("its only caller stays build-loop.sh") leaves a second, narrower verifier in the snippet with no cross-reference.
- **Row 704 (orchestrator's bare git, deferred to U4):** finding 1. The row's stated assumption about U3b3's git_harden no longer holds; the decision itself (defer to U4) stands.
- **Row 548 (dev-cycle.sh runs no default_gate):** finding 5 and fact-check Claim 26. Through D6, the snippet's branch rule is now the digest's only exactly-one check. Not reopened.
- **Rows 200/509 (same-uid race on the 0700 extraction dir, Q-103):** no structural finding. Fact-check Claim 30c's comment narrowing is the whole residue.

## Overall Assessment

The change improves the system's structure. It turns a duplicated cross-cutting concern (row 495: hardening in `build-loop.sh` only, `dev-cycle.sh` unhardened) into one lib function that both entry scripts call at the same point. It also adds the orchestrator's entry point as a self-contained script that needs no change to the scripts it runs. Every finding can be fixed in place, and none needs restructuring. The most important structural concern is a forward-contract one (finding 1). The bootstrap rule that makes the snippet repeat HARDEN also means `git_harden` cannot be the orchestrator's wrapper that row 704 promised U4, so U4 must either route every git read through a script mode or add a third pinned copy. The other findings are about keeping the forced duplicates (HARDEN, the re-hash, the branch rule) pinned or cross-referenced to their sources. The fact-check's two escalations stay with security and are not structural findings here. They are (a) a failed root-check `rev-list` silently selecting the image copy and (b) the re-hash proving self-consistency, not provenance. One structural note on (a): the trust-root choice is a two-way branch on a predicate whose error state falls into "no", so an explicit match / no-match / error split would make that third state visible, whatever security decides it should do.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/architecture-review-2026-10-12-u3b3-i2.md, structured per the architecture-review skill.
- Answered: yes. All four structural questions in the dispatch are covered: git_harden in the lib (finding 4, What Looks Good), the snippet's forced HARDEN duplication and its pin (finding 2, What Looks Good), the snippet's home in test/lib/ (finding 6), and rows 644/648 against the snippet's own re-hash (finding 3).
- Out of scope: whether the snippet needs store_check's second-copy rule, and the fact-check's two escalations (the root-check fallthrough and ref provenance). These are security judgements and are only noted structurally.
- Escalate: amend row 704's revisit text before U4 starts (finding 1). My two-pack probe (`/tmp/u3b3-arch2-XXXX`, removed) showed no divergent tree read, but security may want the snippet/store_check second-copy question answered explicitly.
- Decisions I made: I filed row 704's broken assumption as a new Minor finding and cross-listed it under re-flagged rows, because the row's decision stands and only its premise changed. I rated the forced duplicates Minor or Informational, not Coupling, because each is either pinned or fails closed through the script's own gate.
