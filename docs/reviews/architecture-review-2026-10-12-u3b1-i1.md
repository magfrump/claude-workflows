# Architecture Review — feat/build-loop-u3b1 (U3b1: --state and --marker), iteration 1

**Scope:** `git diff main...HEAD` on `feat/build-loop-u3b1` (ec9ba0c7 feature, 1bf01630 tests); `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`; plan step 9's U3b split note (`docs/working/plan-build-loop-handoff.md:323-326`, already on main at d1091eb8)
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-u3b1-i1.md` (claims 5, 9, 13 Incorrect; 4b, 24, 26, 27 Mostly accurate; 23 Unverifiable)
**Probe prefix:** `/tmp/u3b1arch-` (one probe, removed)

Scope check: in scope. The diff adds two public CLI modes (`--state`, `--marker`) with new output contracts the orchestrator parses (`ok BRIEF SHA` plus a `> `-quoted body; `refuse state WHAT: WHY` lines), splits the gate's startup (`state_start` / `gate_start`), widens a shared gate (`default_gate`, also run by `land`), and moves a shared predicate (`callervar`) to a third consumer. Categories: public APIs yes, cross-cutting (startup gating, hardening) yes, data models (marker body as a contract) yes, module structure no.

Trust-boundary cross-reference: the newest `docs/reviews/security-review-*.md` is `security-review-egress-zone-entries-2026-09-19.md` (unrelated diff). No finding below is a cognitive-move-3 module-boundary finding on a labelled boundary, so the section is a no-op.

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` (scrub, scrub_reexec, resolve_main, main_by_name, FENCE_AWK, oddwhy, read_settings, reader_settings, store_check). Dependencies flow script → lib only; the diff adds no lib change and no lib → script dependency.
- Top-level startup (`:554-569`) is a fixed pipeline: `ROOT`/`cd` → `caller_gate` (`--state` only) → `state_gate` (GATED modes) → `resolve_main` → `main_by_name` → `reader_settings` (ungated modes). The case arm then calls `state_start` (`--state`), `gate_start` = `state_start` + settings (`--check`, `--merge`, `--start`, `--prompt`), or `read_settings` (`--status`, `--settings`, `--marker`).
- New in-script dependencies: `caller_gate` → `callervar`, `STATE_KEYS_RE`, `CALLER_COUNT` (captured before `harden`) and a restated copy of harden's six keys. `marker` → `status_fields` (`STATUS[line|loop|branch|sha]`), `scrub`, `FENCE_AWK` (its END-visible globals `odd`, `oddwhy`, `infence`, `fline`), `oddwhy`, `BODY_RULE`/`BODY_LINES`/`BODY_BYTES`. The loop prompt (`:1515`) → `BODY_RULE`, `BODY_LINES`, `BODY_BYTES`.
- `default_gate` has two consumers: `state_start` (startup) and `land`'s re-check (`:1385`); its new check depends on `MAIN_SHA`, a startup snapshot.
- `callervar` now has three consumers: `caller_gate` (`:520`), `gate_repo` (`:858`), `checkout_gate` (`:1072`).
- Out-of-script consumers of the new contracts: the orchestrator flow (D13, D11; lands in U4's SKILL.md and U3b3's D6 snippet), `ANSWER_AWK` and `scripts/questions.sh` (column-0 anchored readers of the questions file the quoted body is pasted into).

## Findings

#### 1. default_gate's new check compares to a startup snapshot, so a shared state gate now also reports staleness, and land mislabels a concurrent move

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:543-545` (default_gate, continues to `:551` — read); consumer `scripts/build-loop.sh:1385-1386` (land, continues to `:1397` — read)
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** the `--merge` refusal reader (orchestrator / human reading `refuse BRIEF: the git state changed after the check (...)`)

Evidence:
```bash
  # resolve_main peels the ref to its commit, which land's compare-and-swap would then never match (row 656).
  [[ "$(git show-ref --verify --hash "refs/heads/$MAIN" 2>/dev/null)" == "$MAIN_SHA" ]] \
    || { echo "refuse state default-branch: refs/heads/$MAIN names an object that is not a commit"; bad=1; }
```
```bash
  { state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" \
    || { MERGE_WHY="the git state changed after the check ($(head -n 1 "$GATE_TMP/state"))"; return 1; }
```
default_gate's contract (comment at `:530-534`) is a property of the repository: "the default branch counts only when no other name could claim it". The new line compares the ref with `MAIN_SHA`, which is a value captured at startup. That adds a second concern, "main has not moved since startup", to a function that `land` re-runs after time has passed. The fact-check's p6 (Claim 13) shows the result: when another writer moves main to a new commit before land's re-check, the refusal now says `names an object that is not a commit`, and the CAS's accurate "moved after the check" is never reached. The outcome (refuse) is right, but the reason points the reader at a tag, not at a concurrent writer. Any future reuse of default_gate after startup inherits the same conflation.

**Recommendation:** Make the check snapshot-free so default_gate stays a pure state predicate: compare the ref with its own peel (`git rev-parse --verify -q "refs/heads/$MAIN"` vs `"refs/heads/$MAIN^{commit}"`, or `git cat-file -t` is `commit`). land's CAS then keeps reporting a move as a move.

#### 2. harden's key list is restated as caller_gate's regex (three copies), and U3b3 is slated to move harden into the lib

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:446-454` (harden), `scripts/build-loop.sh:525-526` (caller_gate, continues to `:529` — read), help `scripts/build-loop.sh:124-127`; plan `docs/working/plan-build-loop-handoff.md:326`
**Move:** 7 (coupling surface), 1 (dependency direction, for the U3b3 move)
**Confidence:** High
**Legibility-target:** whoever edits harden's key list (the U3b3 implementer of `git_harden`)

Evidence:
```bash
CALLER_COUNT="${GIT_CONFIG_COUNT:-0}"
harden() {
  local c="$CALLER_COUNT" kv
  ...
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false; do
```
```bash
    [[ "$v" == command ]] && [[ "$k" =~ $STATE_KEYS_RE || "$k" =~ ^core\.(usereplacerefs|hookspath|fsmonitor|attributesfile|commitgraph|multipackindex)$ ]] \
```
```
   - **U3b3, the D6 snippet** (T27, T33, T36, T37; rows 200, 495, 505, 644, 648): `test/lib/d6-snippet.bash`, the byte-equality test (pending until U4 puts the block in SKILL.md), and the shared `git_harden` for dev-cycle.sh's digest.
```
caller_gate's job is "a caller pair that would beat harden", so its key set is by definition harden's key set, but the two are separate literals (one mixed-case `key=value` list, one lowercased regex), plus a third in the help text. Adding a seventh hardened key to harden alone leaves `git -c <newkey>` passing `--state` silently, which is exactly the class caller_gate exists to show. The planned U3b3 move of harden into the lib as `git_harden` (row 495, and row 281's "one lib function") makes this a cross-module copy: the lib would own the list, `build-loop.sh` would restate it, and `CALLER_COUNT` (which must be captured before any harden runs, or caller_gate lists harden's own pairs) is a top-level temporal dependency the lib function must preserve.

**Recommendation:** Hold the six pairs in one array (`HARDEN_PAIRS=(core.useReplaceRefs=false ...)`); harden loops over it and caller_gate builds its lowercase key regex from it. Record in the U3b3 brief that `git_harden` must keep exposing the caller's pre-harden count (or the key array) for caller_gate.

#### 3. caller_gate refuses a caller already hardened like harden (keys only, no values): an unrecorded constraint on U3b3/U4's orchestrator environment

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:523-528` (caller_gate); flow consumers plan `docs/working/plan-build-loop-handoff.md:100` (D13 "Start of each iteration") and `:326` (U3b3's shared `git_harden`)
**Move:** 7 (coupling surface), 8 (contract the next units must meet)
**Confidence:** Medium (the refusal is executed; whether U3b3/U4 will export hardened pairs before calling `--state` is not yet decided)
**Legibility-target:** U3b3/U4 implementers wiring `--state` into the orchestrator iteration

Evidence (probe `/tmp/u3b1arch-*`, plain repo, `--state` otherwise `ok`):
```
--- caller COUNT pair equal to harden's own
refuse state core.hookspath: set by the caller's git -c or GIT_CONFIG_COUNT pairs, it overrides the gate's hardening or a key the state gate refuses
rc=2
--- git -c core.useReplaceRefs=false (same as harden)
refuse state core.usereplacerefs: set by the caller's git -c or GIT_CONFIG_COUNT pairs, it overrides the gate's hardening or a key the state gate refuses
rc=2
```
caller_gate matches keys, not values, so `core.hooksPath=/dev/null` or `core.useReplaceRefs=false` from the caller (the same values harden sets) refuses every `--state`. Refusing is fail-closed and fine for a planted value, but U3b3 introduces a shared `git_harden` for the digest, and D13 has the orchestrator call `--state` at the start of each iteration. If either exports hardened COUNT pairs in the environment that later calls `--state` (the natural way to share a hardening function across a shell session), every iteration refuses with a message that blames a loop. Nothing in the plan's U3b3/U4 notes or in caller_gate's comment records "call `--state` from an unhardened environment". (Separately, the fact-check's Claim 5 shows the "overrides the gate's hardening" wording is wrong for COUNT pairs, which harden's later pairs beat.)

**Recommendation:** Either accept value-equal pairs for harden's keys (refuse only a value other than harden's), or state the constraint in caller_gate's comment and carry it into the U3b3 and U4 briefs ("`--state` runs from the orchestrator's unhardened environment; `git_harden` is never exported into it").

#### 4. The caller-variable scan is duplicated in caller_gate and checkout_gate; callervar now carries two meanings across three consumers

**Severity:** Minor
**Location:** `scripts/build-loop.sh:499-504` (callervar), `:519-522` (caller_gate), `:858` (gate_repo), `:1070-1074` (checkout_gate, continues to `:1130` — read)
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** whoever next changes the trusted-variable set

Evidence:
```bash
  for v in $(git rev-parse --local-env-vars); do
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
      || { echo "refuse state $v: set in the caller's environment, so git can read another repository, object store, index, config, graft, shallow or replace-ref file"; bad=1; }
```
```bash
  for v in $(git rev-parse --local-env-vars); do
    # GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level.
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
      || { CHECKOUT_WHY="$v is set, so git can read another work tree, index, object store or config file"; return 1; }
```
```bash
  for v in $(git rev-parse --local-env-vars); do callervar "$v" || GATE_ENV+=(-u "$v"); done
```
Moving callervar above caller_gate is correct (definition before first use at top level). The resulting shape has the "which caller variables are trusted" policy split in two: three names in callervar and `GIT_PREFIX` inlined in two copy-pasted loops. callervar also means "keep in the gate repository's env" for gate_repo and "trusted, not refused" for the two gates; today these coincide, and the comment already reasons about two consumers ("gate_repo unsets it; checkout_gate refuses it"). Widening callervar for gate_repo's sake (or GIT_PREFIX's exemption for one gate) silently changes the others.

**Recommendation:** One helper, e.g. `caller_vars` printing the set, non-trusted repo-local variables (callervar and the GIT_PREFIX exemption in one place), which both gates loop over and format. Optional: a one-line note on callervar naming its three consumers.

#### 5. BODY_RULE is one string for prompt and skip message, but the enforcing regex is a separate literal inside marker's perl

**Severity:** Minor
**Location:** `scripts/build-loop.sh:785-788` (BODY_RULE), `:815-816` (perl rule inside marker, which continues to `:844` — read), `:829`, `:1515` (prompt); test oracle `test/scripts/build-loop-orchestrator.bats:25`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** loop authors reading the prompt; whoever edits the rule

Evidence:
```bash
BODY_RULE='no line that starts, after blanks, ">" and list markers, with "#", **Needs:**, **Status:**, **Answer, or Q- and a digit'
```
```perl
      (my $s = $l[$i]) =~ s/^(?:[ \t>]|[-*+][ \t]|[0-9]+[.)][ \t])*//;
      if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i) { print "rule ", $i + 1, "\n"; exit 0 }
```
Row 689 asked for "one shared string or a test". The string is shared by the prompt (`:1515`) and the skip line (`:829`), and the test pins the skip line against a copied RULE, so prompt and message cannot drift. The prose and the regex can: the regex is case-insensitive while the prompt's sentence is not (the help text adds "in any case", the prompt does not), and a change to the regex (for example adding `**Opened:**`) needs a hand edit of the prose. It fails closed (stricter than the prompt), so the cost is a loop's blocked marker skipped for a rule it was not told, not a misread entry. This mirrors the existing pattern for other prompt-stated rules (marker_kind, floor_why, row 689), so it is consistent with the codebase rather than a new gap.

**Recommendation:** Add "in any case" to BODY_RULE so the one string states what the regex enforces, and put the regex beside BODY_RULE (an env var to perl, like N and B) so the two literals sit together.

#### 6. marker reads FENCE_AWK's internal globals in its own END block (established pattern, now a fourth reader)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:835`; prior art `scripts/lib/dev-cycle-read.sh:410`, `:565-570`
**Move:** 7 (content coupling)
**Confidence:** High
**Legibility-target:** whoever changes FENCE_AWK's reporting

Evidence:
```bash
    r="$(printf '%s\n' "$m" | env LC_ALL=C awk "$FENCE_AWK"'fence($0) { next } END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }')" \
```
The END block reads `odd`, `oddwhy`, `infence` and `fline`, FENCE_AWK's internal state, and then the case on `odd\ *` / `unbalanced\ *` plus `oddwhy` restates `main_file`'s handling (`dev-cycle-read.sh:565-570`). This is the lib's existing convention (`brief_read` at `:410` has the same END text), so marker follows prior art; reuse of `status_fields`, `scrub`, `FENCE_AWK` and `oddwhy` is the right dependency direction. The END text and the odd/unbalanced dispatch now exist in three places.

**Recommendation:** None required for this unit. If a later unit touches FENCE_AWK's reporting, a lib `FENCE_END_AWK` string (and a small `fence_why` that turns `odd N WHY`/`unbalanced N` into a phrase) would collapse the copies.

#### 7. --state's behaviour is spread over top-level startup (mode test) and the case arm; the U3b split leaves rows that close only "on the flow" to later units

**Severity:** Informational
**Location:** `scripts/build-loop.sh:558-563`, `:1149-1155`, `:1527-1530`; plan `docs/working/plan-build-loop-handoff.md:324-326`
**Move:** 8 (extension points), 2
**Confidence:** Medium
**Legibility-target:** the U3b2/U3b3/U4 implementers and the override-log reader

Evidence:
```bash
GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1  # not the gate repository's GATE_*
# The caller's environment first: it can point the state gate's own reads elsewhere.
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```
```
Rows 493/494/517 close on the flow (the orchestrator's iteration starts with `--state`; `--status` gains no default_gate).
```
The GATED allowlist of ungated read modes (gated by default) is a sound extension point, and `state_start` as gate_start's first half keeps `--state` and `--check` from drifting: good structure. The new per-mode `if` at top level is the first startup step keyed to one mode name; a second such mode (U3b2's `--main-log` is a read mode and must be added to the ungated regex) grows the startup by special cases. For the split's coherence: U3b2 (`--main-log`) needs only the GATED allowlist, and is independent of U3b1. U3b3 depends on U3b1 through findings 2 and 3 (harden's key list and CALLER_COUNT move with `git_harden`; the orchestrator must call `--state` unhardened). Row 281's "one lib function" half belongs to U3b3 (row 495), and rows 493/494/517 and the "covers both" basis for leaving `--marker` ungated (`:560`) depend on U4's SKILL.md calling `--state` (fact-check Claims 23, 24). U3b1's plan note and commit list those rows as addressed here.

**Recommendation:** In the plan's U3b split note, move row 281's lib-function half to U3b3 and mark 493/494/517 (and the ungated-`--marker` premise) as "closed when U4 calls `--state`". Note in U3b2's brief that `--main-log` joins the ungated regex. No code change needed.

## What Looks Good

- `state_start` extracted as gate_start's state half: `--state` runs exactly `--check`'s startup state checks, by construction, not by a parallel copy (rows 525/690).
- The GATED allowlist stays deny-by-default for any new mode, and `--marker` is placed beside `--status` as a read mode with the same `read_settings` path.
- `--marker` composes existing lib pieces (`status_fields` for the tip, `scrub`, `FENCE_AWK`, `oddwhy`) instead of reparsing marker grammar; it depends only on the lib, never the reverse.
- `BODY_RULE`, `BODY_LINES`, `BODY_BYTES` as named constants consumed by both the loop prompt and `--marker` remove the prompt-restates-the-code drift that row 689 recorded, for prompt vs. skip message.
- harden's non-decimal GIT_CONFIG_COUNT refusal sits in the one function every mode runs, so the rule has a single home.
- callervar moved above its first top-level use rather than duplicated.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | default_gate compares to the startup snapshot; land reports a concurrent move as "not a commit" | Coupling | `scripts/build-loop.sh:543-545`, `:1385` | High |
| 2 | harden's six keys restated as caller_gate's regex (and help); U3b3 moves harden to the lib | Coupling | `scripts/build-loop.sh:446-454`, `:525-526` | High |
| 3 | caller_gate refuses value-equal hardened pairs; unrecorded "call --state unhardened" constraint on U3b3/U4 | Coupling | `scripts/build-loop.sh:523-528` | Medium |
| 4 | Caller-variable scan copy-pasted in caller_gate and checkout_gate; callervar's two meanings | Minor | `scripts/build-loop.sh:499-504`, `:519-522`, `:1070-1074` | High |
| 5 | BODY_RULE prose shared, regex separate (case-insensitivity unstated in prompt) | Minor | `scripts/build-loop.sh:787`, `:815-816` | High |
| 6 | marker's END block reads FENCE_AWK globals (fourth copy of an established pattern) | Informational | `scripts/build-loop.sh:835` | High |
| 7 | --state split across startup and case arm; rows 281/493/494/517 depend on U3b3/U4 | Informational | `scripts/build-loop.sh:558-563`; plan `:324-326` | Medium |

Rubric mapping: findings 1-3 → 🟡 Must Address; 4-7 → 🟢 Consider. No 🔴.

## Overall Assessment

The change keeps the script's structure intact and improves it in one place: `state_start` makes `--state` a true subset of the gate's startup rather than a parallel implementation, and `--marker` is built from the lib's existing readers. All findings are fixable in place. The most important structural concern is finding 1: default_gate, a shared state predicate re-run by land, now embeds a startup snapshot and so reports a concurrent move of main as a non-commit; a snapshot-free peel comparison fixes it without touching land. Findings 2 and 3 matter mostly for the split: U3b3's `git_harden` will move the hardening list into the lib while caller_gate keeps a copy of it, and caller_gate's key-only match will refuse an environment hardened by that same function, so both should be settled (one key array; a recorded or relaxed value rule) before U3b3 starts.

## Goal-Alignment Note

The goal is to land U3b1 (`--state`, `--marker`) after a clean review-fix loop. The architecture supports that goal: both modes are coherent with the existing startup pipeline and lib, and nothing here calls for restructuring. The Coupling items are small, local edits (finding 1: one comparison; finding 2: one array; finding 3: a comment or a value check) plus plan-note corrections (finding 7) that keep U3b2/U3b3 from inheriting hidden contracts. None blocks `--marker`'s D11 purpose: the quoted body is inert to the column-0 questions readers (fact-check Claim 17), and the reuse of FENCE_AWK keeps it from poisoning the questions file.
