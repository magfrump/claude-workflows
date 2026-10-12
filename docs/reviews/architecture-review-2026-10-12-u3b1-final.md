# Architecture Review — feat/build-loop-u3b1 (U3b1: --state and --marker), final confirming pass

**Scope:** `git diff main...HEAD` on `feat/build-loop-u3b1` at 5e816c5b (ec9ba0c7 feature, 8f99a919 iteration-1 fixes, 8367359f iteration-2 fixes, tests 1bf01630 and in the fixes): `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-merge.bats` (one case), plan step 9's U3b split / U3b1 as-built note (`docs/working/plan-build-loop-handoff.md:324-326`), override rows 700-711 dated 2026-10-12
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-u3b1-final.md` (k=3 merged: 0 behavioural Incorrect; 1 Incorrect cluster, commit-body text; 4 Mostly accurate, help/plan text; 2 Unverifiable) and iteration 1's `docs/reviews/architecture-review-2026-10-12-u3b1-i1.md`
**Probe prefix:** `/tmp/u3b1farch-` (one probe, directory removed; no process left running)

Scope check: in scope. The branch adds two public CLI modes with output contracts the orchestrator parses (`--state`: `ok` / `refuse state WHAT: WHY`; `--marker`: `ok BRIEF SHA` plus a `> `-quoted body, or `skip`), splits the gate's startup (`state_start` / `gate_start`), changes a shared gate (`default_gate`, re-run by `land`), adds shared constants (`HARDEN`, `BODY_RULE`, `BODY_LINES`, `BODY_BYTES`, `MARKER_MAX`) and a shared helper (`stray_vars`). Categories: public APIs yes, cross-cutting (startup gating, hardening) yes, data models (marker body as pasted contract) yes, module structure no.

Trust-boundary cross-reference: active. Newest security review is `docs/reviews/security-review-2026-10-12-u3b1-i1.md` (Commit: `ec9ba0c796e1c26989ac1d27125ce238ffc19348` — security review predates this diff's fix commits 8f99a919 and 8367359f; boundaries may be stale). Its map labels B1 (marker body → `marker()` → questions entry), B2 (quoted body → questions readers), B3 (caller env → harden decimal check, caller_gate → `--state ok`), B4 (repo state → state_gate + default_gate + store_check via state_start), B5 (loop-movable refs → status_fields/marker_kind in `--marker`). Findings below that touch these cite the label; none recommends moving a crossing.

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` (scrub, scrub_reexec, resolve_main, main_by_name, FENCE_AWK, oddwhy, read_settings, reader_settings, store_check). Direction is script → lib only; the branch changes nothing in the lib.
- Top-level startup (`:454-464`, `:572-591`): `CALLER_COUNT` captured → `harden` (decimal check; exports `HARDEN` pairs after the caller's) → `ROOT`/`cd` → `GATED` (deny-by-default; `settings|status|marker` ungated) → `caller_gate` (`--state` only) → `state_gate` (GATED) → `resolve_main` → `main_by_name` → `reader_settings` (ungated only).
- Case arms: `state` → `state_start` + `echo ok`; `check`/`merge`/`start`/`prompt` → `gate_start` = `state_start` + `reader_settings; read_settings; never_res; open_shared`; `status`/`marker` → `read_settings` then `status_line` / `marker`.
- Shared in-script pieces now: `HARDEN` (harden, caller_gate; help text restates it), `stray_vars` → `callervar` (caller_gate, checkout_gate; gate_repo calls `callervar` directly), `STATE_KEYS_RE` (state_gate, caller_gate), `default_gate` (state_start, land's re-check), `BODY_RULE`/`BODY_LINES`/`BODY_BYTES`/`MARKER_MAX` (marker's skip line, the loop prompt at `:1538`).
- `marker` → `status_fields` (`STATUS[line|loop|branch|sha]`), `scrub`, `FENCE_AWK` + its END-visible globals, `oddwhy`. Out-of-script consumers: the orchestrator flow (U4's SKILL.md), `ANSWER_AWK` and `scripts/questions.sh` (column-0 anchored readers; B2).

## Iteration-1 findings: status

| i1 # | Finding | Rubric | Status at 5e816c5b |
|---|---|---|---|
| 1 | default_gate compared the ref with startup `MAIN_SHA` | B4 | Resolved. `:559-560` now tests the ref's own `cat-file -t`, snapshot-free; merge suite pins the moved-main case (C3). |
| 2 | harden's keys in three copies | B8 | Resolved in code: one `HARDEN` array read by harden (`:459`) and caller_gate (`:540`). The help text (`:133-134`) still lists the six keys (finding 4 below, Informational). The U3b3 half of the recommendation is not recorded (finding 1 below). |
| 3 | caller_gate refuses value-equal hardened pairs | B9 | Settled by override row 702 (Defer; "the orchestrator calls `--state` from an environment where the shared git_harden is not exported", revisit trigger U3b3) and the plan's as-built note. Behaviour unchanged (probe: `GIT_CONFIG_COUNT` pair `core.commitGraph=false` → `refuse state core.commitgraph`, rc 2). Not re-filed. |
| 4 | caller-variable scan copy-pasted | B12 | Resolved: `stray_vars` (`:517`) owns the callervar + GIT_PREFIX policy; caller_gate and checkout_gate (`:1096`) loop over it. |
| 5 | BODY_RULE prose vs enforcing regex | B10 | Text half resolved ("in any case", list markers, `<!--`, strict UTF-8 now in BODY_RULE). Co-location half not done (finding 3 below, Minor). |
| 6 | marker reads FENCE_AWK's END globals | B15 | Settled by row 703 (Defer; revisit on a fourth caller or a FENCE_AWK change). Not re-filed. |
| 7 | --state split across startup and case arm; rows dependent on U3b3/U4 | B19, plan note | Resolved for the rows: the plan note re-keys 281/311/666 to U3b3 and says 493/494/517 close "once U4's SKILL.md starts each iteration with `--state`"; row 709 records it. The startup per-mode `if` remains (accepted; see What Looks Good). |

## Findings

#### 1. U3b3's planned `git_harden` move has no recorded contract for `HARDEN` and `CALLER_COUNT`, which caller_gate reads

**Severity:** Minor
**Location:** `scripts/build-loop.sh:454-464` (CALLER_COUNT, HARDEN, harden, and its call), `scripts/build-loop.sh:532-546` (caller_gate, read in full), plan `docs/working/plan-build-loop-handoff.md:326`, override rows 702 and 709
**Move:** 1 (dependency direction), 7 (coupling surface), 8 (contract the next unit must meet)
**Confidence:** Medium (the move is planned, its shape is not yet decided)
**Legibility-target:** the U3b3 implementer of the shared `git_harden`

Evidence:
```bash
CALLER_COUNT="${GIT_CONFIG_COUNT:-0}"
HARDEN=(core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false)
harden() {
  local c="$CALLER_COUNT" kv
```
```bash
  x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only)" || { echo "refuse state caller-config: the caller's config pairs could not be read"; return 1; }
  while IFS=$'\t' read -r v k; do
    [[ "$v" == command ]] || continue
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
```
```
   - **U3b3, the D6 snippet** (T27, T33, T36, T37; rows 200, 495, 505, 644, 648): `test/lib/d6-snippet.bash`, the byte-equality test (pending until U4 puts the block in SKILL.md), and the shared `git_harden` for dev-cycle.sh's digest.
```
caller_gate is correct only while two top-level facts hold: `HARDEN` is the list harden applies, and `CALLER_COUNT` is read before any harden runs (otherwise `GIT_CONFIG_COUNT="$CALLER_COUNT"` would list harden's own pairs and `--state` would refuse every caller). Both now sit beside harden in `build-loop.sh`, which is the right shape for this unit. U3b3 moves hardening into the lib (`git_harden`, rows 281/495, re-keyed there by row 709). Row 702 carries the value-equality constraint into U3b3, but nothing carries the structural one: if `git_harden` takes its own key list or reads `GIT_CONFIG_COUNT` itself, `build-loop.sh` keeps a second list (i1 finding 2 returns, now across a module boundary) or loses the pre-harden count. This sits on B3 from `docs/reviews/security-review-2026-10-12-u3b1-i1.md` (Commit: `ec9ba0c7…` — security review predates this diff; boundary may be stale); the recommendation keeps the crossing where it is.

**Recommendation:** Add one clause to the U3b3 plan bullet (or row 709's revisit text): "`git_harden` owns `HARDEN` and exposes the caller's pre-harden count (or `HARDEN` and the count stay in `build-loop.sh` and are passed in); caller_gate reads the same list." No code change in U3b1.

#### 2. caller_gate marks a HARDEN key by appending a blank to the key string

**Severity:** Minor
**Location:** `scripts/build-loop.sh:540-543` (inside caller_gate `:532-546`, read in full)
**Move:** 2 (responsibility), legibility of a shared predicate
**Confidence:** High
**Legibility-target:** whoever next edits caller_gate or the HARDEN/STATE_KEYS_RE sets

Evidence:
```bash
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
    if [[ "$k" == *" " || "$k" =~ $STATE_KEYS_RE ]]; then
      echo "refuse state ${k% }: set by the caller's git -c or GIT_CONFIG_COUNT pairs, a key the state gate refuses or one the gate's own hardening sets (a git -c pair wins over it)"; bad=1
```
The membership test for "is a HARDEN key" is encoded as data in the key itself (a sentinel blank), then decoded twice (`*" "`, `${k% }`). It works (probe: `git -c core.hooksPath=/dev/null` → `refuse state core.hookspath`, rc 2; a `user.name` pair → `ok`), and the inner loop stops matching once the blank is appended. But a reader has to simulate the loop to see that, and any later use of `$k` in the body (for example a per-key message) inherits the blank. The codebase's stated preference is explicit over clever.

**Recommendation:** Optional: build the lowercase HARDEN key set once (an associative array or a `^(...)$` regex from `HARDEN`) and test `[[ -n "${HARDEN_KEYS[$k]+x}" || "$k" =~ $STATE_KEYS_RE ]]`. Pure readability; behaviour unchanged.

#### 3. BODY_RULE's prose and its enforcing regex are still two literals in different places

**Severity:** Minor
**Location:** `scripts/build-loop.sh:807` (BODY_RULE), `scripts/build-loop.sh:839-842` (perl rule inside marker, which continues to `:870` — read), `:855` (skip line), `:1538` (prompt)
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** whoever changes the blocked-body rule (loop prompt readers see only the prose)

Evidence:
```bash
BODY_RULE='no line that starts, after blanks, ">" and list markers ("-", "*", "+", "1." or "1)" and a blank), with "#", **Needs:**, **Status:**, **Answer, or Q- and a digit, in any case; no line holding "<!--"; strict UTF-8'
```
```perl
      (my $s = $l[$i]) =~ s/^(?:[ \t>]|[-*+][ \t]|[0-9]+[.)][ \t])*//;
      # "<!--" anywhere: questions.sh finds its index markers anywhere in a line (security i1 F1).
      if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i || index($l[$i], "<!--") >= 0
```
The prose now matches the regex clause for clause (checked: blanks/`>`/list markers stripped in any order; the five prefixes, case-insensitive; `<!--` on the whole line; the strict UTF-8 alternation), so i1 finding 5's drift is gone today. The rule grew from one clause to three in this branch, each a hand edit in two places 30 lines apart; the bats oracle pins the skip line's copy of the prose and mutants pin the regex, but nothing pins prose ↔ regex. It fails closed (a regex stricter than the prose skips a marker; it never admits a heading), so the cost of drift is a loop's question skipped for a rule it was not told. On B1 (security review, Commit `ec9ba0c7…`, predates the fix commits).

**Recommendation:** When the rule next changes, move the regex beside BODY_RULE (passed to perl in the environment, as N and B are) so both literals are edited together. No change needed to land U3b1.

#### 4. The help text still restates HARDEN's six keys

**Severity:** Informational
**Location:** `scripts/build-loop.sh:133-134` (header, `--state` paragraph)
**Move:** 7
**Confidence:** High
**Legibility-target:** whoever adds a hardened key

Evidence:
```
#             (core.useReplaceRefs, core.hooksPath, core.fsmonitor,
#             core.attributesFile, core.commitGraph, core.multiPackIndex;
```
B8 collapsed the two code copies into `HARDEN`; the third, documentary copy remains. A seventh key added to `HARDEN` is enforced by caller_gate automatically, so only the help goes stale (no behaviour drift). Acceptable as is.

**Recommendation:** Optional: "one this script's own hardening sets (the HARDEN array)" in place of the list, or leave it and accept a doc edit per key.

#### 5. `--state`'s startup is the first mode-named branch at top level; U3b2's `--main-log` gating is left to its own plan

**Severity:** Informational
**Location:** `scripts/build-loop.sh:581-584`; plan `docs/working/plan-build-loop-handoff.md:325`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** the U3b2 implementer

Evidence:
```bash
GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1  # not the gate repository's GATE_*
# The caller's environment first: it can point the state gate's own reads elsewhere.
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```
The deny-by-default `GATED` allowlist means U3b2's `--main-log` is gated unless its plan adds it to the regex: safe either way (gated costs only the state gate's reads), so this is not a coherence break. The one-off `MODE == state` line is justified (caller_gate must precede state_gate and only `--state` reads the caller's environment, a design call recorded in the brief). It would become a pattern to restructure only if a second mode needs its own pre-gate step.

**Recommendation:** None for U3b1. U3b2's plan should state whether `--main-log` is a read mode (joins the ungated regex) or gated.

## What Looks Good

- **state_start / gate_start split** (`:1172-1182`): `--state` runs exactly `--check`'s state half by construction; `gate_start` is `state_start` plus the settings steps, so the two cannot drift (rows 525/690). Probe: plain repo `--state` → `ok`, rc 0. `state_start` needs nothing from `reader_settings`, so `--state` correctly skips it.
- **default_gate is a pure state predicate again** (`:559-560`): the ref's own object type, no startup snapshot, so `land`'s re-run reports a concurrent move through the CAS / W's ff (merge-suite case added). Shared consumers keep one meaning.
- **HARDEN** gives harden and caller_gate one key list, and harden's non-decimal `GIT_CONFIG_COUNT` refusal sits in the one function every mode runs (probe: `GIT_CONFIG_COUNT=010 --settings` → exit 1 before any output).
- **stray_vars** gives the "trusted caller variable" policy one home (callervar + GIT_PREFIX), consumed by caller_gate and checkout_gate; gate_repo keeps using `callervar` alone, which matches its narrower meaning.
- **caller_gate reads only in `--state`** (probe: the same `core.hooksPath` COUNT pair passes `--settings`; the bats file pins `--check` too), and reads with `CALLER_COUNT`, so harden's own pairs are never listed (probe: unrelated `user.name` pair → `ok`).
- **`--marker` composes the lib** (status_fields, scrub, FENCE_AWK, oddwhy) and the shared constants instead of reparsing marker grammar; it sits beside `--status` as an ungated read mode with the same `read_settings` path. The size cap (`cat-file -s`) precedes the body read, and every printed line is `> `-prefixed, which keeps B2's column-0 readers inert.
- **BODY_RULE / BODY_LINES / BODY_BYTES / MARKER_MAX** are interpolated into the loop prompt (`:1538`), so the prompt and the skip line state the same rule and caps.
- **Plan coherence:** the as-built note re-keys rows 281/311/666 to U3b3 and 493/494/517 to U4, and records the "call `--state` without git_harden exported" constraint; U3b2 (`--main-log`) depends on nothing U3b1 added beyond the GATED allowlist.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | U3b3's git_harden move has no recorded contract for HARDEN and the pre-harden CALLER_COUNT that caller_gate reads | Minor | `scripts/build-loop.sh:454-464`, `:532-546`; plan `:326` | Medium |
| 2 | caller_gate encodes "HARDEN key" as a trailing blank in the key string | Minor | `scripts/build-loop.sh:540-543` | High |
| 3 | BODY_RULE prose and its regex are separate literals (in sync today) | Minor | `scripts/build-loop.sh:807`, `:839-842` | High |
| 4 | Help text restates HARDEN's six keys | Informational | `scripts/build-loop.sh:133-134` | High |
| 5 | `--state`'s per-mode startup branch; `--main-log`'s gating left to U3b2's plan | Informational | `scripts/build-loop.sh:581-584`; plan `:325` | Medium |

Rubric mapping: no Structural (no 🔴), no Coupling (no 🟡); findings 1-5 → 🟢 Consider.

## Overall Assessment

The branch keeps the script's structure intact and, after the two fix iterations, improves it: the state half of the gate is one function shared by `--state` and every gated mode, default_gate is snapshot-free again, and the hardening list and the stray-variable policy each have one home. All seven iteration-1 findings are resolved in code (1, 2, 4, the text half of 5, the plan half of 7) or settled by override rows (3 → row 702, 6 → row 703). Nothing remaining is Structural or Coupling. The single most important structural concern is forward-looking: when U3b3 moves hardening into the lib, `HARDEN` and the pre-harden `CALLER_COUNT` must move or be exposed together, or caller_gate either keeps a second list or loses the count; one sentence in the U3b3 plan bullet covers it. No disagreement with the security review's trust-boundary placement.

## Goal-Alignment Note

- Success criterion (restated verbatim): "A markdown report saved to /workspace/.claude/wt-build-loop-u3b1/docs/reviews/architecture-review-2026-10-12-u3b1-final.md, structured per the architecture-review skill."
- Answered: yes. The architecture supports landing U3b1 now: 0 🔴, 0 🟡, 5 🟢. Iteration-1 findings 1-7 are all resolved or settled by override rows 702/703 (table above).
- U3b2 / U3b3 coherence: U3b2 is independent of U3b1 (only the GATED allowlist touches it). U3b3 depends on U3b1 through HARDEN, CALLER_COUNT and row 702's unhardened-caller constraint; finding 1 asks for one plan clause so that dependency is recorded before U3b3 starts.
- Out of scope: correctness of the strict-UTF-8 regex and FENCE_AWK line numbering (fact-check, 0 mismatches / Verified), security of B1-B5 (security review), the questions.sh:184 summary-line escalation (security-reviewer).
