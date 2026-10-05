Commit: 2e711a7b

# Security Review — feat/build-loop-u1b (review-fix iteration 4 of 4, final confirming pass)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 2e711a7b: `scripts/build-loop.sh` (`--settings`), `test/lib/build-loop-fixtures.bash`, `test/scripts/build-loop-read.bats`, override-log rows 222-264; `scripts/lib/dev-cycle-read.sh` (U1a) and `docs/working/plan-build-loop-handoff.md` (D1, D2, D5, D6, D9, D13, F38, T42) read for context
**Date:** 2026-10-05
**Based on:** Stage-1 fact-check replicates `docs/reviews/code-fact-check-report-build-loop-u1b-r{1,2,3}.md` at 2e711a7b (escalation E1 is answered here); shared Stage-2 context (settled rows, Q-112 [1], Q-113)
**Probes:** run in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/security/` on throwaway repos (`git init -b main`, `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`), git 2.39.5, against a byte copy of `scripts/` at 2e711a7b (`s2/`) and two candidate-fix mutants (`s3/`, `s4/`). `bats test/scripts/build-loop-read.bats` passes 9/9 at 2e711a7b. No process left running.

## Trust Boundary Map

```
B1: [docs/dev-cycle.md blob on MAIN_SHA]  → [FENCE_AWK + SETTINGS_AWK letters-only key count (build-loop.sh:103-118)] → [POLICY / SLOTS / NEVER]
B2: [Self-merge never: line text]         → [single-space + next-line check + globform (build-loop.sh:151-174)]       → [NEVER array, never_ok → POLICY (:179)]
B3: [refs and repo config: origin/HEAD, refs/heads/*, refs/replace/*, .git/config core.useReplaceRefs] → [resolve_main / main_by_name (lib), replace guard (build-loop.sh:66-70)] → [MAIN_SHA, "the default branch's commit"]
B4: [caller environment: GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT/KEY_n/VALUE_n, GIT_REPLACE_REF_BASE] → [replace guard (build-loop.sh:69-70)] → [git's effective config for every read]
B5: [repo text reaching stdout/stderr]    → [scrub_reexec / scrub (lib)]  → [orchestrator transcript]
```

```
S1: docs/dev-cycle.md on main   — runtime-mutable (user's/orchestrator's commits; floor-denied to loops,
                                   plan F12/F56) — UNTRUSTED for printing (B5); trusted as the author's
                                   intent, but its parse must fail closed where render and parse disagree (B1, B2)
S2: local refs and .git/config  — runtime-mutable by any process with the uid, a build loop included
                                   (in-model: plan F25/F38/F51, override row C18) — UNTRUSTED for "which
                                   commit and which blob is main" (B3)
S3: caller environment (GIT_CONFIG_*, GIT_REPLACE_REF_BASE, DEV_CYCLE_SCRUBBED, LC_ALL)
                                — set by the orchestrator session (D1, D13); a loop subagent cannot set
                                   another process's environment, but its shell can write the uid-owned
                                   shell profile (~/.zshrc is node-owned, 0644) that initialises later
                                   shells — trusted toward this script's sinks only as far as the account
                                   is (same actor class as PATH and `alias git`)
S4: code constants (SETTINGS_AWK, NAMECHARS, key strings, the guard pair) — code-constant — trusted
```

Repo text enters through S1 and is printed only as validated globs or fixed text with line numbers. The unit's claims are that settings come from main's own objects (B3, B4) and that any ambiguity fails toward review, or self-merge off (B1, B2). At 2e711a7b the guard stops a loop-writable `.git/config` (S2), which closes iteration 3's A16. Several caller-environment shapes (S3) still defeat it, and the comment says otherwise (Finding 1).

## Findings

#### 1. The replace-ref guard does not win against caller-supplied config, contrary to its comment (fact-check E1)

**Severity:** Low
**Location:** `scripts/build-loop.sh:66-70`
**Boundary:** B4 (feeding B3)
**Move:** 11 (bypasses for every guardrail), 1 (trust boundaries)
**Confidence:** High on the mechanism (executed); Medium on the rating (it depends on the orchestrator's environment, which ships in U3b/U4)
**Legibility-target:** the comment at `:67-68`, which a reader takes as the guard's contract

Evidence (verbatim; excerpt ends :70, top-level code continues at :71-72 with `resolve_main || true` / `main_by_name || …`, read: these are the first git reads that see the exported config):
```
# Read main's own objects: a replace ref could swap in any settings blob.
# core.useReplaceRefs in the repo's config would override the variable: add a
# command-line config pair after any the caller passed.
cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```

Executed. Setup: main's `docs/dev-cycle.md` says `Build-loop policy: review` and has a replace ref to a blob that says `self-merge`. Results:

| Caller environment | `.git/config` core.useReplaceRefs | `--settings` policy line |
|---|---|---|
| none | true | `policy review set` (A16 fixed) |
| `GIT_CONFIG_PARAMETERS="'core.usereplacerefs'='true'"` | unset or true | `policy self-merge set` |
| `git -c core.useReplaceRefs=true -c alias.bl='!bash …/build-loop.sh --settings' bl` | true | `policy self-merge set` |
| `GIT_CONFIG_COUNT=02` (or `010`), KEY_0..n innocuous | **true** | `policy self-merge set` |
| `GIT_CONFIG_COUNT=08`, KEY_0..7 innocuous | **true** | `policy self-merge set`; stderr `line 69: 08: value too great for base`; exit 0 |
| `GIT_CONFIG_COUNT=08`, KEY_0..7 innocuous | unset | `policy review set` (GIT_NO_REPLACE_OBJECTS still exported) |
| `GIT_CONFIG_COUNT=+2` or `' 2'` | true | exit 1 (`export: not a valid identifier`), fails closed |
| `GIT_CONFIG_COUNT=abc`, `0x2`, `'2 '`, `-1` | true | exit 1, "Not inside a git repository" (wrong reason, E2) |

Two mechanisms are at work. Git applies `GIT_CONFIG_PARAMETERS`, which is where `git -c` lands for child processes, after the `GIT_CONFIG_COUNT` pairs, so a caller's `-c` wins. Bash's `$((cfg + 1))` also reads a leading-zero count as octal. The pair is then exported under a key name git never reads (`GIT_CONFIG_KEY_02`, not `_2`), and a loop-written `.git/config` wins again. With `08`, the arithmetic error skips the pair and `set -e` does not stop the script.

Threat model:
- The orchestrator sets the caller environment (D1, D13). D6's extracted-script run sets environment of its own, but it does not set `GIT_CONFIG_PARAMETERS` or `GIT_CONFIG_COUNT`.
- A build loop cannot set another process's environment. It can write `~/.zshrc`, which is uid-owned, and Bash-tool shells source it. That same write can also plant `alias git`, a PATH shim or `GIT_DIR`, and no in-script guard survives those, so this route counts as controlling the account. It is not a loop-reachable bypass of this guard.
- The leading-zero rows need two things: an odd caller count, which nothing in the plan produces, and a loop-planted replace ref plus repo config. The replace ref is what the u1a row and the u1b architecture-M1 row already route to U3b's `--state`. Plan T42 and D6 refuse any `refs/replace/` before the gate reads anything.
- Every E1 shape still needs a replace ref, so `--state` closes all of them in the default namespace. That makes E1 strictly less reachable than C18, which needs only a ref write the loop can make directly and is settled as Defer to U3b.

The floor rule does not force Medium: the only loop-reachable route to S3 needs the attacker to already control the account. The finding is that the comment claims more than the code does, and the fix is a single line.

**Recommendation:** Replace the GIT_CONFIG_COUNT pair with an append to the variable git reads last. This line was checked in mutant `s4/`:
`export GIT_CONFIG_PARAMETERS="${GIT_CONFIG_PARAMETERS:+$GIT_CONFIG_PARAMETERS }'core.usereplacerefs'='false'"`
On every row above it gave `policy review set`: repo config, caller `PARAMETERS=true`, caller `COUNT=2` with `KEY_1=core.useReplaceRefs true`, and the `git -c … alias` route. A malformed caller `GIT_CONFIG_PARAMETERS` (a dangling quote or a trailing backslash) already fails at `:62`'s rev-parse, so it fails closed. The append also removes the octal and arithmetic failure modes, because nothing parses the count any more. If the author prefers to keep the code, the minimum fix is the comment: "after any GIT_CONFIG_COUNT pair the caller passed; a caller's `-c`/GIT_CONFIG_PARAMETERS, or a non-decimal count, still wins". A test for the repo-config case (iteration 3's C3) already exists in T4 (`:120-121` of the bats file). One for the caller-`-c` case would be one more `settings_like` line if the code fix is taken.

#### 2. Plan-level note: the orchestrator's shell is initialised from a uid-writable file (outside this unit)

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md` D6 (`:77`, "It never trusts a file the uid can write") and D13; this unit's `scripts/build-loop.sh:66-70` is the first script-level guard that depends on the caller environment
**Boundary:** B4
**Move:** 1 (trust boundaries)
**Confidence:** Medium (the ownership is observed in this container image; how the orchestrator's shell is launched ships in U3b/U4)
**Legibility-target:** D6's "never trusts a file the uid can write"

Evidence: `ls -la ~` shows `-rw-r--r-- 1 node node 645 … .zshrc`, and the tool environment says each shell "is initialized from the user's profile". A loop subagent at the same uid (D1: Agent tool, no isolation) can therefore set environment, aliases and PATH for every later orchestrator shell, the D6 snippet's included. D6's root-owned SKILL.md copy does not cover this channel. Separately, `GIT_REPLACE_REF_BASE` (S3) moves replace refs out of `refs/replace/`, so T42's `for-each-ref refs/replace/` check would list nothing while git still followed `refs/<other>/`. This script is not affected, because the guard turns replace refs off entirely, but U3b's `--state` would be. This is not a defect in U1b. Record it in the plan's F-table if U3b agrees.

**Recommendation:** Route to U3b: `--state` should run with `GIT_REPLACE_REF_BASE` unset, or refuse a set one. D6's snippet should start from a clean environment (`env -i` with an explicit PATH), or the plan should list the shell profile as an accepted residual next to F19 and F35.

## Re-checks of iteration-3 items at 2e711a7b

- **A16 (core.useReplaceRefs in repo config bypasses GIT_NO_REPLACE_OBJECTS): FIXED for the repo-config vector.** With `.git/config` `core.useReplaceRefs=true` and a replace blob that says self-merge, the output is `policy review set: line 1 …`. In the same repo, `git -c core.useReplaceRefs=true cat-file blob main:docs/dev-cycle.md` prints `Build-loop policy: self-merge`, which confirms the replace ref is live and that the guard is what stops it. Bats T4 (`:120-121`) covers it, and the fact-check confirms that a mutant dropping the pair fails test 5. The remaining caller-environment vectors are Finding 1.
- **A17 (sole never line hidden → `never none` with self-merge on): FIXED.** With `Build-loop policy: self-merge` plus one hidden never line as the only never-like line, every probe printed `policy review unset: …`: `- [x] Self-merge never: b/`, `[Self](u)-merge never: b/` and `Self-merge&nbsp;never: b/` gave `never none: no line starts …`, and `<b>Self-merge</b> never: b/`, `<!-- … -->`, a 4-space indent, `> ` and an NBSP after the colon gave `never malformed: …`. The gate is `:179`: `if [[ "$v" == self-merge && -z "$never_ok" ]]`. never_ok is set only at `:172-173`, the exact, single, valid-line arms. Bats T45 (`:117`) asserts the task-box case.
- **Q-112 rule: can any input RAISE the policy or ADD self-merge? No shape found (executed).**
  - `policy self-merge set` appeared only for an exact `Build-loop policy: self-merge` together with an exact, single, next-line-blank `Self-merge never: none|GLOB…`, with or without one trailing CR.
  - An exact never line followed by `===` (setext), `- b/`, a fence or an HTML block fails closed: malformed, so review.
  - A hidden policy line alone (`- [x] Build-loop policy: self-merge`) gives `policy review unset: no line starts …`.
  - An unread file (an open comment or fence, a BOM, a symlink, a directory) keeps POLICY=review (`:139-143`).
  - Hidden shapes next to an exact line are settled (override row 256) and were not re-raised.
  - The fact-check replicates reach the same verdict independently (shared context, "Verified (executed, all three)").

## Untested bypass candidates

- **Real zero-width bytes (U+200B) inside the never key with no exact line:** my probe passed the six-character escape text (backslash, u, 200b), not the bytes. The bytes are not letters, so they are dropped and the line would count as a copy, which fails closed. Settled as C19 in any case.
- **`GIT_CONFIG_PARAMETERS` holding a well-formed string whose last token is an open-quoted key that swallows the appended pair (for Finding 1's recommended fix):** not tested beyond the two malformed shapes, which fail at rev-parse. The fix is not code under review.
- **`safe.directory` passed by the caller through `GIT_CONFIG_PARAMETERS` and broken by the recommended append:** not tested. The append keeps caller pairs and adds one after them, so nothing is dropped.

## Endorsement Claims

- **Claim:** With `core.useReplaceRefs=true` in the target repo's `.git/config` and a replace ref on main's `docs/dev-cycle.md`, `--settings` reads main's original blob.
  **Location:** `scripts/build-loop.sh:69-70`
  **Evidence:** executed
  **Verified:** probe `probe.sh` "A16 repo config" section and bats T4 at 2e711a7b; the replace ref was confirmed live with `git -c core.useReplaceRefs=true cat-file`.
  **Not verified:** caller-environment config, which Finding 1 shows does bypass it; the `--state` refusal in U3b.
  **route: code-fact-check**
- **Claim:** `policy self-merge set` is printed only when an exact policy line and an exact, single, valid never line (`never_ok`) are both present on main's commit; a never line hidden in markup with no exact line gives `policy review unset`.
  **Location:** `scripts/build-loop.sh:151-182`
  **Evidence:** executed
  **Verified:** 9 hidden-never shapes, 5 rendered-continuation shapes and 2 hidden-policy shapes (probe.sh), plus bats T45 and T1.
  **Not verified:** how U2's gate uses POLICY and NEVER, since it is not built yet.
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec / git object reads driven by environment-derived config
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:62` `git rev-parse --show-toplevel` | S3 | none (runs before the guard) | cleared — reads no object; a malformed GIT_CONFIG_* fails closed here |
| lib `resolve_main` / `main_by_name` (`:71-72`) | S2, S3 | `:69-70` | refs only; origin/HEAD symref is C18 (settled) |
| lib `main_entry` `ls-tree` (via `main_file` `:81`) | S2, S3 | `:69-70` | Finding 1 (caller config) |
| `scripts/build-loop.sh:89` `git cat-file blob "$MAIN_SHA:$f"` | S1, S2, S3 | `:69-70` | Finding 1 (caller config); repo-config cleared (A16) |
| `scripts/build-loop.sh:89` `awk "$FENCE_AWK$2"` | S4 (program), S1 (stdin) | code constant | cleared — the program text is a code constant |
| `scripts/build-loop.sh:57` `sed -n … "$0"` (help) | S4 | none | cleared — reads the script itself, not the repo |

Shell glob expansion of never entries: `:163` uses `IFS=' ' read -ra`, which does not expand globs, and that line was the only candidate site. It is cleared: T45 has a mutation guard for it, per the fact-check.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Replace-ref guard loses to caller `GIT_CONFIG_PARAMETERS` / `git -c` and to a leading-zero `GIT_CONFIG_COUNT`; comment overclaims | Low | B4 | `scripts/build-loop.sh:66-70` | High (mechanism) / Medium (rating) |
| 2 | Orchestrator shell profile is uid-writable; `GIT_REPLACE_REF_BASE` escapes T42's `refs/replace/` check (plan-level, U3b) | Informational | B4 | plan D6 `:77`, T42 `:338` | Medium |

## Overall Assessment

The unit's security posture holds for loop-reachable inputs. Settings come from main's commit. A loop-written `.git/config` no longer re-enables replace refs (A16 fixed). Under Q-112's rule, a hidden never list can only turn self-merge off (A17 fixed): no input raised the policy or added self-merge. The one in-scope finding is that the replace-ref guard is weaker against the caller's own environment than its comment says. Only the orchestrator, or something that already controls the account, can reach that environment, so I rate it Low. The most important action is to fix the comment at `:67-68`, preferably together with the one-line `GIT_CONFIG_PARAMETERS` append, which closes every caller-config shape probed. Endorsement claims are execution-backed; they are routed to code-fact-check for the Confirmed-Good verdict.

## Goal-Alignment Note

**Success criterion (verbatim):** "A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b."

This report is saved at `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1b.md` and has `Commit: 2e711a7b` as its first line. It follows the security-reviewer structure: boundary map, source table, findings, untested candidates, endorsements, primitive sweep, summary and assessment. It covers all three code files and the override-log rows. It answers escalation E1, and it re-checks A16, A17 and Q-112 by execution at 2e711a7b. Settled rows (C18, C19, row 256, Q-113 size) were not re-raised; their premises are unchanged at 2e711a7b.
