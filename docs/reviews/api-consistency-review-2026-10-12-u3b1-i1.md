# API Consistency Review — feat/build-loop-u3b1 (U3b1, review-fix loop iteration 1)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-build-loop-u3b1` (ec9ba0c7): `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md` (U3b1 note)
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-u3b1-i1.md` (29 claims; its executed probes p1-p6 are cited as `FC pN`)

The public surface is `build-loop.sh`'s CLI: mode flags, the line grammar (`ok` / `skip` / `refuse` / `path` / `deny`), exit codes 0/1/2, and the header documentation that `--help` prints. Its planned consumer is the dev-cycle orchestrator skill (U4). That skill is written from the plan's "Script interface" and "Skill changes" sections and D11. The loop prompt (U3d) is a second consumer-facing contract: it tells loops what blocked body `--marker` accepts. No new probes were needed. Every behavioural point below rests on the fact-check's executed results or on the suite's assertions, which are quoted.

## Baseline Conventions

- **Modes** are `--noun` flags, one per action: `--settings`, `--status`, `--check`, `--merge`, `--start`, `--prompt` (`scripts/build-loop.sh:393-427`). Each validates its arity in the `case` arm and calls `usage "--MODE takes …" / "needs …"`, which exits 1 with the full usage line on stderr.
- **Line grammar** (plan `:195-199`, header `:60-360`):
  - `ok BRIEF FIELDS…` is a verdict or answer that names the objects it decided on: `ok BRIEF TIP TREE` for `--check`, `ok BRIEF … SHA …` for `--status`, `ok BRIEF BRANCH DIR` for `--start`/`--prompt`.
  - `skip BRIEF: WHY`: the plan says "unreadable". In practice read modes also use it for content the script will not vouch for. `--status` skips a tip whose subject starts `handoff:` but is not a marker (`:85-95`). `dev-cycle.sh`'s check modes skip on policy (`scripts/dev-cycle.sh:168`, `:182-187`).
  - `refuse BRIEF: WHY` is a verdict in a deciding mode.
  - `refuse state WHAT: WHY` is a state-gate finding. WHAT is a short noun: a git path (`info/attributes`), a lowercased config key, `refs/replace`, `origin/HEAD`, or a hyphenated tag (`default-branch`, `gate`, `objects`). Where the problem lives (`set in config` / `set in config.worktree`) goes in WHY.
- **Payload after a verdict line**: `--start`/`--prompt` print `ok …`, `dispatched N`, then the prompt on every later line (`:323-327`). This is the precedent for a multi-line body after an `ok`.
- **Exit codes** (`:367-376`, plan `:196-199`): read modes exit 0 when every argument was answered, a skip included. Deciding modes exit 2 on any refusal, and the state gate exits 2 before any brief. Exit 1 covers usage errors and startup failures, which print no line on stdout.
- **Internal names**: `*_gate` for checks that print `refuse state` lines and return 1 (`state_gate`, `default_gate`, `checkout_gate`). `*_start` for startup sequences (`gate_start`). Upper-case globals for shared constants and regexes (`STATE_KEYS_RE`, `FENCE_AWK`, `ANSWER_AWK`, `CALLER_GLOBAL`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--marker BRIEF` | CLI mode | `--status BRIEF...`, `--start BRIEF`, `--prompt BRIEF` | `scripts/build-loop.sh:393-427`; plan `:206` | Consistent: `--noun`, one brief like `--start`/`--prompt`, name as planned |
| `--state` | CLI mode | `--settings` (no args), `--status`, `--check` | `scripts/build-loop.sh:394,397`; plan `:207` | Consistent with the plan and the no-arg `--settings`. It sits one letter-run from `--status`, but the names are the plan's and the help separates them |
| `"--marker takes one brief path"` / `"--state takes no arguments"` | usage text | `"--$MODE takes one brief path"`, `"--settings takes no arguments"` | `scripts/build-loop.sh:394,426` | Consistent, word for word |
| `ok BRIEF SHA` | output line | `ok BRIEF … SHA …` (`--status`), `ok BRIEF TIP TREE` | `scripts/build-loop.sh:67,151` | Consistent: SHA is the same marker sha `--status` prints |
| `> …` body lines + `> (build-loop.sh --marker cut this body: K of N lines shown, M cut at 300 bytes)` | output payload | `--start`/`--prompt` prompt after `ok`/`dispatched` | `scripts/build-loop.sh:323-327` | Consistent: a payload after the verdict line. Each line is prefixed, so no payload line can be mistaken for a verdict line |
| `skip BRIEF: …` (rule, FENCE_AWK, empty body, not a marker) | output line | `--status` skip for a non-marker `handoff:` subject; `dev-cycle.sh` policy skips | `scripts/build-loop.sh:85-95`; `scripts/dev-cycle.sh:168,182-187` | Consistent with the read-mode precedent; see Finding 7 on routing |
| `ok` (bare, `--state`) | output line | `ok BRIEF TIP TREE`, `ok BRIEF SHA` | `scripts/build-loop.sh:151`; plan `:207` | Matches the plan; it diverges from "ok names what it decided on" (Finding 6) |
| `refuse state GIT_DIR:` … (env-var WHAT) | refusal WHAT | `refuse state info/attributes:`, `refuse state core.fsmonitor:` | `scripts/build-loop.sh:479-495` | Consistent: WHAT names the thing itself |
| `refuse state caller-config:` | refusal WHAT | `default-branch`, `refs/replace`, `objects`, `gate` | `scripts/build-loop.sh:492,538,1152,1154` | Consistent: hyphenated tag like `default-branch` |
| `refuse state core.hookspath: set by the caller's …` | refusal WHAT/WHY | `refuse state core.hookspath: set in config, …` | `scripts/build-loop.sh:484` | Consistent: same WHAT, with the source in WHY as state_gate does. The WHY's mechanism is wrong for COUNT pairs (Finding 2) |
| `refuse state default-branch: refs/heads/MAIN names an object that is not a commit` | refusal WHY | other `default-branch` lines | `scripts/build-loop.sh:538,542,548` | Consistent token; its reason is wrong when reached from `--merge`'s land (Finding 1) |
| `caller_gate` | function | `state_gate`, `default_gate`, `checkout_gate` | `scripts/build-loop.sh:478,535,1068` | Consistent: `*_gate`, prints `refuse state` lines, returns 1 |
| `state_start` | function | `gate_start` | `scripts/build-loop.sh:1149-1159` | Consistent: the `*_start` startup half |
| `marker` | function | `status_line`, `status_fields` | `scripts/build-loop.sh:781-783` | Consistent: named for the mode, like `status_line` |
| `BODY_RULE`, `BODY_LINES`, `BODY_BYTES`, `CALLER_COUNT` | globals | `STATE_KEYS_RE`, `FENCE_AWK`, `CALLER_GLOBAL` | `scripts/build-loop.sh:458,474`; `scripts/lib/dev-cycle-read.sh` | Consistent: upper-case shared constants; `CALLER_*` like `CALLER_GLOBAL` |

## Findings

#### 1. `--merge`'s land now reports a concurrent move of main as "names an object that is not a commit"

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:544-545`, reached from `scripts/build-loop.sh:1385-1386`
**Move:** 3 (consumer contract: altered error semantics of an existing mode) / 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/build-loop.sh:544-545
  [[ "$(git show-ref --verify --hash "refs/heads/$MAIN" 2>/dev/null)" == "$MAIN_SHA" ]] \
    || { echo "refuse state default-branch: refs/heads/$MAIN names an object that is not a commit"; bad=1; }
# scripts/build-loop.sh:1385-1389 (land continues to :1397)
  { state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" \
    || { MERGE_WHY="the git state changed after the check ($(head -n 1 "$GATE_TMP/state"))"; return 1; }
  if [[ -z "$w" ]]; then
    git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
      || { MERGE_WHY="the default branch moved after the check, or could not be updated; it was left as it is"; return 1; }
```
default_gate is shared, and land re-runs it just before its compare-and-swap. The new check compares the ref against the `MAIN_SHA` taken at startup. A main that another writer moved to a new **commit** between startup and `:1385` therefore fails here, and is reported as a non-commit. The fact-check reproduced this (FC p6, Claim 13). The output was `the git state changed after the check (refuse state default-branch: refs/heads/main names an object that is not a commit)` while `git cat-file -t main` gave `commit`. Before this diff the same race reached the CAS and printed "the default branch moved after the check". The outcome (refused, main untouched) is unchanged. But `--merge`'s refusal text is what the orchestrator quotes into a merge entry (D4). That text now sends the reader looking for a tag when the cause is a concurrent writer. The same mismatch exists for `--check`/`--start`/`--prompt` only in the microseconds between resolve_main and default_gate (FC Claim 12).

**Recommendation:** Word the line so it covers both causes, e.g. `refs/heads/$MAIN is not at the default branch's commit $MAIN_SHA (it names an annotated tag, or it moved)`. Alternatively, peel and compare inside default_gate and print the tag reason only when the peeled value equals `MAIN_SHA` and the raw value does not. Add a land test that moves main to a commit before `:1385` (the `commit-tree` shim of FC p6) and asserts the reason.

#### 2. The caller-pair refusal says a `GIT_CONFIG_COUNT` pair "overrides the gate's hardening", which it cannot

**Severity:** Minor
**Location:** `scripts/build-loop.sh:526`, header `scripts/build-loop.sh:123-127`, test title `test/scripts/build-loop-orchestrator.bats:47`
**Move:** 4 (error message accuracy)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/build-loop.sh:526
      && { echo "refuse state $k: set by the caller's git -c or GIT_CONFIG_COUNT pairs, it overrides the gate's hardening or a key the state gate refuses"; bad=1; }
```
```bash
# test/scripts/build-loop-orchestrator.bats:57-58
    run --separate-stderr env GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller GIT_CONFIG_KEY_1=core.hooksPath GIT_CONFIG_VALUE_1=/x bash "$BL" --state
    [ "$status" -eq 2 ] && [ "$output" = "refuse state core.hookspath: $K" ] || { show; return 1; }
```
harden appends its pairs after the caller's COUNT pairs (`:447-454`), and git applies COUNT pairs in index order, last one winning (FC p1 case 1c, Claim 5). So a COUNT pair for `core.hooksPath` loses to harden. The line the test pins tells the user that it overrides the hardening. `core.hooksPath` is in `STATE_KEYS_RE`, so this case's refusal is right, but the reason given is wrong. For `core.usereplacerefs`, `core.commitgraph` and `core.multipackindex` set through COUNT, neither half of the "or" is true. Refusing them anyway is the stricter, safe choice. The WHY is the consumer-facing text the orchestrator files, and it should state the reason the pair was refused. The header's "which would win over it" (`:127`) has the same problem.

**Recommendation:** Name the actual reason per source, e.g. "set by the caller's git -c (which wins over the gate's hardening) or GIT_CONFIG_COUNT pairs; refused as a key the gate hardens or refuses". Rename the test title and fix the header to match.

#### 3. The loop prompt's blocked-body rule is narrower than what `--marker` enforces: the case-insensitivity is not in the shared string

**Severity:** Minor
**Location:** `scripts/build-loop.sh:787` (BODY_RULE), `:816` (the regex), `:1515` (prompt line), header `:107-115`
**Move:** 7 (asymmetry: the producer's contract and the consumer's check differ)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/build-loop.sh:787
BODY_RULE='no line that starts, after blanks, ">" and list markers, with "#", **Needs:**, **Status:**, **Answer, or Q- and a digit'
# scripts/build-loop.sh:816
      if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i) { print "rule ", $i + 1, "\n"; exit 0 }
# scripts/build-loop.sh:1515
- "handoff: blocked", with the question after a blank line as plain prose and an options table, at most $BODY_LINES lines of $BODY_BYTES bytes: $BODY_RULE;
```
Row 689 asked for one string shared by the prompt and the check. The string is shared. The header (`:111-112`, "in any case") and the commit's design call make the match case-insensitive, but that fact is not in the string. The list markers the check strips (`-`, `*`, `+`, `1.`, `1)` and a blank) are also not in it. A loop that follows its prompt literally can write `q-3 depends on the CSV choice` or `- **status:** pending upstream`. `--marker` then skips the whole question (suite test 4 pins `'> > **needs:** agent'` as a skip; FC p2 skipped `+ q-7 x` and `1) **ANSWERED** x`). Going the other way, the prompt's "at most 100 lines of 300 bytes" reads as a hard rule, but `--marker` cuts the body with a note rather than skipping it (suite test 6). That leniency is fine, but the prompt and the help describe the cap differently. The skip line embeds the same BODY_RULE, so a reader of a skip on a lower-case line also sees the narrower rule.

**Recommendation:** Add the missing facts to BODY_RULE itself, e.g. append ", in any case" and name the list markers. The prompt, the skip line and the help then state the rule `--marker` actually applies. Optionally word the cap in the prompt as "(longer bodies are cut)".

#### 4. Plan's "Script interface" bullet for `--state` was not updated to the as-built output

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:207` (vs `:324` and `scripts/build-loop.sh:116-128`)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```markdown
<!-- docs/working/plan-build-loop-handoff.md:207 -->
- `--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`, then U2b1b's `default_gate` once main is resolved: both main and master, or origin/HEAD naming another branch than the one taken).
```
As built, `--state` prints refusals this bullet does not list:
- the caller-environment lines (`refuse state GIT_DIR: …`, `refuse state caller-config: …`, a caller key);
- `refuse state gate: …`;
- `refuse state objects: …`;
- the new non-commit default-branch line.

It also exits 1 with no line on a non-decimal `GIT_CONFIG_COUNT` (Finding 5). The U3b1 note at `:324` describes the extras. U3d's as-built note set the precedent of saying it "supersedes … the 'Script interface' Dispatch bullets" (`:320`), and U3b1's note has no such pointer. U4 writes the orchestrator skill from "Script interface" and "Skill changes". The stale bullet is the one it will read.

**Recommendation:** Either amend the `:207` bullet to the as-built output, or add "supersedes the Script interface's `--state` bullet where they differ" to the U3b1 note, as U3d did.

#### 5. `--state` reports some caller-environment plantings as exit 1 with stderr, not as `refuse state` lines

**Severity:** Minor
**Location:** `scripts/build-loop.sh:449` (harden), `:554` (top-level rev-parse), plan `:207`
**Move:** 4 (error consistency) / 8 (when is there a line at all)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/build-loop.sh:449
  [[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }
# scripts/build-loop.sh:554
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
```
`--state` is the mode that snapshots the caller's environment (`:119-123`). Row 276's own planting, a zero-padded `GIT_CONFIG_COUNT`, still never produces a `refuse state` line. It stops every mode at harden with exit 1, nothing on stdout, and one line on stderr (FC p2, Claim 7). A `GIT_DIR` that names a bare or missing repository exits 1 with "Not inside a git repository" before caller_gate runs (FC p2, Claim 4b). The header documents both under exit 1, and exit 1 already means "nothing decided", so the orchestrator will stop either way. But the plan's interface promises `ok` or `refuse state WHAT: WHY` (exit 2), and the orchestrator files `refuse state` lines as entries. For these two plantings it gets no WHAT to file and no reason that names the caller's environment.

**Recommendation:** Either make the U4 skill treat any non-0/2 exit from `--state` as "stop; quote stderr", and say so in the plan's `--state` bullet. Or, in `--state` mode only, print `refuse state GIT_CONFIG_COUNT: not a plain decimal count, set in the caller's environment` to stdout and exit 2 before harden's exit. The first is cheaper and keeps harden's every-mode stop.

#### 6. `--state`'s bare `ok` does not name the commit it checked

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1527-1529`, plan `:207`, `:247`
**Move:** 7 (asymmetry with sibling `ok` lines)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Precedent: `ok` lines that name what they decided on are used in `scripts/build-loop.sh:67` (`--status` `… SHA …`), `:151` (`--check` `ok BRIEF TIP TREE`), `:98` (`--marker` `ok BRIEF SHA`), `:323` (`--start`/`--prompt` `ok BRIEF BRANCH DIR`).

Evidence:
```bash
# scripts/build-loop.sh:1527-1529
  state)
    state_start
    echo ok
```
`state_start` re-hashes main's commit and tree at `MAIN_SHA` (`store_check --main "$MAIN_SHA"`, `:1153`), but the `ok` does not say which commit was checked. The skill flow then runs `--main-log` and the digest "from main" (plan `:247`), which read main again and may see a later commit. Printing `ok MAIN SHA` would let the orchestrator pin the iteration to the commit that `--state` verified, the way it records `Asked: Q@SHA` from `--marker`'s SHA. The plan specifies a bare `ok`, so this is a suggestion only.

**Recommendation:** Consider `ok MAIN SHA` (the branch name taken and `MAIN_SHA`). The plan's bullet and suite test 1's `state_is ok` would change with it. Otherwise leave it as planned.

#### 7. `--marker` uses one `skip` token for "not a marker", "unreadable" and "the loop's body breaks the rule"

**Severity:** Informational
**Location:** `scripts/build-loop.sh:107-115`, `:803-841`; plan `:196`, `:206`, `:63`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Precedent: read modes `skip` for content they will not vouch for, in `scripts/build-loop.sh:85-95` (`--status` on a malformed `handoff:` subject) and `scripts/dev-cycle.sh:168,182-187`.

Evidence:
```bash
# scripts/build-loop.sh:805, 829-830
    || { echo "skip $a: the tip of ${STATUS[branch]} is not a blocked or stopped marker (${STATUS[loop]})"; return; }
  if [[ "$body" == "rule "* ]]; then echo "skip $a: a line of its marker's body breaks the blocked-body rule ($BODY_RULE): line ${body#rule }"; return; fi
  [[ -n "$body" || "${STATUS[loop]}" == stopped ]] || { echo "skip $a: its blocked marker holds no question (the body is empty)"; return; }
```
This follows the read-mode precedent and the plan's interface (`:206`), and every skip exits 0 as read modes do. The routing consequence is what to note. A "not a blocked or stopped marker" skip means "use `--status`'s LOOP". A rule, fence or empty-body skip means "the loop's question cannot be filed safely", which needs its own entry or a re-dispatch. An unreadable skip may clear on retry. D4 (`:63`) does not say what the orchestrator does on a `--marker` skip, so the U4 skill will have to route on WHY prose.

**Recommendation:** No code change needed now. When U4 is written, specify the action per skip cause in the skill. If routing on prose turns out fragile, a stable leading phrase per cause is the cheap fix.

#### 8. The "only `--state` reads the caller's environment" contract is pinned on an ungated mode

**Severity:** Informational
**Location:** `test/scripts/build-loop-orchestrator.bats:66-68`
**Move:** 3 (test drift: the contract claimed for `--check` is not exercised)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# test/scripts/build-loop-orchestrator.bats:66-68
    # Only --state reads the caller's environment: --settings is not refused for it.
    run --separate-stderr env GIT_REPLACE_REF_BASE=refs/x/ bash "$BL" --settings
    [ "$status" -eq 0 ] || { show; return 1; }
```
The commit's design call is that `--check` keeps its behaviour for a caller's variables. `--settings` is ungated and never reaches caller_gate's position, so this assertion passes even if every gated mode ran caller_gate (FC Claim 26). The `--check` half of the contract, which is the one a consumer relies on, is unpinned. FC p2 showed it holds today.

**Recommendation:** Assert it on `--check` too: under `GIT_REPLACE_REF_BASE`, `--check` prints no `refuse state GIT_REPLACE_REF_BASE:` line.

## What Looks Good

- **Mode and usage surface.** `--marker BRIEF` and `--state` follow the `--noun` mode shape. Their arity checks reuse the existing usage wording verbatim ("takes one brief path", "takes no arguments"), and the usage line and header list both modes in the same order.
- **`--marker`'s output shape.** It follows the `--start`/`--prompt` precedent: a verdict line, then a payload. Every payload line starts with `>`, so no body line can be read as a verdict line by a consumer reading line by line. The `ok BRIEF SHA` field is `--status`'s marker SHA, so the orchestrator can record `Asked: Q-NNN@SHA` from the exact commit whose body it filed. The cut note is quoted too, so it stays inert to the questions readers (FC Claim 17).
- **Exit codes.** These match the read/decide split. `--marker` exits 0 on ok and on every skip, like `--status`. `--state` exits 0/2 like the state gate, with a failed mktemp exiting 1 as in the other gated modes.
- **`refuse state` vocabulary.** The new WHAT tokens fit the existing vocabulary: env-var names, a hyphenated `caller-config`, lowercased config keys identical to state_gate's. The source goes in WHY, as state_gate already does with "set in config" / "set in config.worktree".
- **Internal names.** `caller_gate`, `state_start` and `CALLER_COUNT` follow the `*_gate` / `*_start` / `CALLER_*` patterns.
- **One rule string.** BODY_RULE, BODY_LINES and BODY_BYTES are shared by the loop prompt and the skip message, so producer and checker cannot drift on the text (Finding 3 is about what the text omits). The prompt sentence changed only by gaining the caps (FC Claim 16).
- **Default-branch narrowing.** The new default_gate refusal (a tag main) applies to `--check`, `--merge`, `--start` and `--prompt` as well. That narrows accepted input, but it is documented in `--check`'s header (`:139-141`) and only refuses a state git's own update-ref will not create (FC p5).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--merge` land reports a moved main as "not a commit" | Inconsistent | `scripts/build-loop.sh:544-545` via `:1385` | High |
| 2 | Caller-pair refusal says a COUNT pair overrides the hardening | Minor | `scripts/build-loop.sh:526`, `:123-127`; bats `:47` | High |
| 3 | Prompt's BODY_RULE omits the case-insensitivity and list markers `--marker` applies | Minor | `scripts/build-loop.sh:787`, `:816`, `:1515` | Medium |
| 4 | Plan's `--state` interface bullet not updated or superseded | Minor | `docs/working/plan-build-loop-handoff.md:207` | High |
| 5 | Non-decimal COUNT / bare GIT_DIR give exit 1 + stderr, no `refuse state` line | Minor | `scripts/build-loop.sh:449`, `:554` | High |
| 6 | `--state`'s bare `ok` does not name the checked commit | Informational | `scripts/build-loop.sh:1527-1529` | Medium |
| 7 | One `skip` token for three different orchestrator actions | Informational | `scripts/build-loop.sh:803-841` | High |
| 8 | "Only --state" contract pinned on ungated `--settings` | Informational | `test/scripts/build-loop-orchestrator.bats:66-68` | High |

## Overall Assessment

U3b1's two modes are consistent with the script's established CLI conventions and with the plan's interface:
- the mode names, usage text, `ok`/`skip`/`refuse state` grammar and exit codes all match their nearest neighbours;
- the `--marker` payload follows the `--start`/`--prompt` verdict-then-payload shape, quoted so that no payload line can be read as grammar.

One finding changes the meaning of an existing consumer-facing output. Finding 1: `--merge`'s refusal reason for a concurrent move of main now names a tag. It is a one-line rewording plus a test. Findings 2 and 3 are text that states the wrong or an incomplete rule for the consumer who reads it: the user reading a refusal, and the loop reading its prompt. Both are fixable in place. Findings 4 and 5 are contract notes for U4: the skill will be written from a plan bullet that no longer lists every line `--state` prints, and it must handle two `--state` exits that carry no line. Nothing here suggests the author skipped the existing conventions. The issues sit at the seams with land's re-check, harden and the plan text.

## Goal-Alignment Note

The goal: an orchestrator-side `--state` that refuses planted repository state and planted caller environment at the start of each iteration, and a `--marker` that hands the orchestrator a loop's question body it can file under its own heading, with no loop-written line read as entry grammar.

The public surface serves that goal:
- `--marker`'s quoted payload, its skip-on-grammar rule and its exit-0 read-mode behaviour give the U4 skill a safe, parseable body;
- `--state` prints in the same `refuse state` grammar the gate already uses.

The gaps that bear on the goal are at the consumer boundary, not in what gets refused:
- the loop is told a narrower body rule than the one enforced (Finding 3), so honest questions can be skipped;
- the U4 author's reference (the plan's `--state` bullet) is stale (Finding 4) and omits two line-less exits (Finding 5).

Finding 1 is the only change to an existing mode's output. It sits off the goal's path, as a side effect of the shared default_gate.
