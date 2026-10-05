Commit: 0ae7d801

# API Consistency Review — feat/build-loop-u1b (U1b, review iteration 2)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` — `scripts/build-loop.sh` (`--settings`, `-h`), its three output lines, and the settings-line contract in `docs/dev-cycle.md` (unchanged by the diff, read as the user-facing contract the script implements)
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u1b.md` (Stage-1 merged fact-check, k=3), the shared Stage-2 context, the plan `docs/working/plan-build-loop-handoff.md` rev 4 (D2/D5/D9, "Script interface")

Probes ran in a throwaway repo under this pass's scratch dir (`build-loop.sh --settings` against committed fixtures); nothing was written in the worktree except this report.

## Baseline Conventions

Surveyed `scripts/dev-cycle.sh` (header :1-80, option parse :99-111, root/branch errors :116, :186-192), the lib `scripts/lib/dev-cycle-read.sh` (`check_brief` :309-347, `check_branch` :357-370, `check_answer` :534-560), the other repo scripts' option parsers (`scripts/skill-usage-report.sh:29`, `scripts/flag-removal-candidates.sh:42`, `scripts/archive-working-docs.sh:32`), and the plan's interface conventions (plan :196-199 and "Script interface" :201-204).

- **Output lines** are one line per answer, `KEYWORD SUBJECT…` then `: reason` (`ok <path>`, `skip <path>: <reason>`, `absent <name>`); the verdict word is in a fixed position (first token) so a consumer can switch on it.
- **Modes** are long flags (`--check-path`, `--check-brief`, …); `-h|--help` prints the header via `sed -n '2,Np' "$0"` and exits 0.
- **Errors** go to stderr, exit 1 for bad usage / no repo / no perl or lib / no default branch; read modes exit 0 when every line was answered. Unknown flags print `Unknown option: X` (capital U) in all four existing scripts.
- **Reading main's commit**: the lib distinguishes `main_entry`'s `error` ("the default branch's tree could not be read") from `notfile` ("not a regular file on the default branch").
- **Path forms** in repo text use `pathform` (lib :140-149), which refuses any part starting `.git` (any case).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--settings` | CLI mode flag | `--check-path`, `--check-brief`, `--check-answer` | `scripts/dev-cycle.sh:8-14` | Consistent — long-flag mode; no-argument mode is new but plan-specified (plan :204) |
| `-h` / `--help` | CLI flag | dev-cycle.sh `-h\|--help` | `scripts/dev-cycle.sh:110` | Consistent — same sed-the-header idiom, exit 0 |
| `policy … set\|unset: WHY` | output line | `ok X`, `skip X: why` | `scripts/lib/dev-cycle-read.sh:322-346`; plan :204 | Consistent with the plan's format; verdict word at token 3 |
| `slots N set\|default: WHY` | output line | same | same | Consistent; verdict at token 3 |
| `never GLOB… set\|none\|malformed: WHY` | output line | same | same | Inconsistent — verdict word is not positional (Finding 3) |
| `set`, `unset`, `default`, `none`, `malformed` | status words | `ok`, `skip`, `absent`, `open`, `unrecognized` | `scripts/lib/dev-cycle-read.sh:322-346, :448-451` | New vocabulary, plan-fixed (plan :204); acceptable — settings are not per-argument answers |
| `Build-loop policy:`, `Build-loop slots:`, `Self-merge never:` | settings keys | `Status:`, `Branch:`, `Policy:`, `Paths:` (brief machine lines) | `scripts/lib/dev-cycle-read.sh:270-271`; `docs/dev-cycle.md:7` | Plan-fixed (D5, D9). `Self-merge never:` does not share the `Build-loop ` prefix; noted only, the plan settled it |
| `unknown option: X (usage: …)` | error message | `Unknown option: X` | `scripts/dev-cycle.sh:111`, `scripts/skill-usage-report.sh:29`, `scripts/flag-removal-candidates.sh:42`, `scripts/archive-working-docs.sh:32` | Inconsistent — casing and the usage suffix (Finding 6) |
| `globform` | script-private function | `pathform` (glob mode) | `scripts/lib/dev-cycle-read.sh:140-149` | Deliberate divergence; plan text not amended (Finding 4) |
| `main_file`, `read_settings`, `FILE_OUT`, `FILE_WHY`, `SETTINGS_AWK` | script-private | `brief_fields`, `BRIEF_ODD`, `ANSWER_AWK` | `scripts/lib/dev-cycle-read.sh:280-300, :474` | Consistent — `*_AWK` program naming, `FILE_*` globals like `BRIEF*`; not public |

## Findings

#### 1. The header's counting rule over-claims: rendered copies of a key stay hidden (E3)

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:28-31`, `scripts/build-loop.sh:106`
**Move:** 3 (consumer contract) / 8 (documented vs actual)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:28-31`):
```
#             A line outside a fence counts as a settings line when it
#             starts with the key (any case) after any blanks, >, list
#             markers, # * _ ` ~ and byte-order marks, so a quoted, bold,
#             heading or indented copy is a second line, not a hidden one. A
```
Evidence (`scripts/build-loop.sh:106`, inside `SETTINGS_AWK` :101-117; excerpt ends :106, the program continues to :117 — read):
```
  if (match(s, /^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*/)) s = substr(s, RLENGTH + 1)
```

The consumer of this contract is the human who edits `docs/dev-cycle.md` and reads it rendered. The header promises that a bold copy is "a second line, not a hidden one", but the strip only removes markup *before* the key text, so markup that closes before the colon hides the copy. Probes (each file: line 1 `Build-loop policy: self-merge`, line 2 the copy), every one printed `policy self-merge set: line 1 of docs/dev-cycle.md on the default branch`:

- `**Build-loop policy**: review` (fact-check Claim 5b, Incorrect)
- `- [ ] Build-loop policy: review` (GFM task item)
- `| Build-loop policy: review |` (table cell)
- `[Build-loop policy: review](x)` (link text)
- `\xc2\xa0Build-loop policy: review` (leading NBSP)
- `\# Build-loop policy: review` (escaped heading)
- `Build-loop  policy: review` (double space)

and `**Build-loop slots**: 2` beside `Build-loop slots: 4` printed `slots 4 set`. Each renders as a visible second policy line that the user would expect to make the setting ambiguous, and each direction of the gap is fail-open for self-merge (the hidden copy can say `review` while the counted line says `self-merge`). The other claims of the header (quoted, `#` heading, indented, emphasis wrapping the whole line) hold — T2 and T45 pin them.

**Recommendation:** Normalize before the prefix test rather than only stripping a prefix: delete `* _ \` ~` anywhere up to the first `:`, and add `|`, `[`, `[ ]`/`[x]`, `\`, and NBSP (`\302\240`) to the strippable prefix. Then restate the header as exactly what is counted, and name the residual unmodelled shapes (HTML entities, zero-width characters) as an accepted limit in the decision-log-69 style, so the contract a user reads is the one the reader enforces. If the 400-line cap blocks the code change, at minimum drop "bold" from the header claim and file the gap.

#### 2. `docs/dev-cycle.md`'s stated settings rule disagrees with the script in both directions

**Severity:** Minor
**Location:** `docs/dev-cycle.md:17-19`, `docs/dev-cycle.md:9`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`docs/dev-cycle.md:17-19`):
```
The handoff design counts the setting as made only when the file has exactly one line, outside code
blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a
trailing CR is ignored). Anything else counts as unset, which means `review`.
```
Evidence (`docs/dev-cycle.md:9`):
```
Read by the build-loop handoff (roadmap item "Build-loop handoff"; not built yet), not by the
```

This is the file users edit, and the only user-facing statement of the rule. It counts lines that *read exactly* the value; the script counts lines that *start with the key* after markup (`scripts/build-loop.sh:12-16`, :28-31), so `Build-loop policy: self-merge` plus `> Build-loop policy: review` is "set" by the doc's wording and "unset" by the script (stricter, fail-closed: safe, but the user cannot predict it). The doc also says nothing of `Build-loop slots:` or `Self-merge never:`, or that an open `<!--`, a raw-HTML line or a reference-definition-like line anywhere makes the whole file unread (all three settings fall back). "not built yet" is no longer true for `--settings`. The plan assigns this rewrite to U5 (plan :279), so this is drift with a scheduled fix, not a defect of U1b.

**Recommendation:** Keep it in U5, but add the counting rule ("starts with the key, after markup") and the whole-file refusals to U5's checklist explicitly; or, cheaply now, replace the three sentences with a pointer to `scripts/build-loop.sh -h` as the authority.

#### 3. The `never` line's status word is not positional, so `none`/`malformed`/`set` as a glob reads ambiguously

**Severity:** Minor
**Location:** `scripts/build-loop.sh:170`, `scripts/build-loop.sh:20`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:170`, inside `read_settings` :135-185; excerpt ends :170, the function continues to :185 — read):
```
      else NEVER="$v"; NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```

`policy` and `slots` put their verdict at token 3 (`policy review unset:`, `slots 5 set:`); `never` puts it after a variable-length list. A glob may be any NAMECHARS word, so probes printed `never none set: line 2 …` for `Self-merge never: none` and `never malformed set set: line 2 …` for `Self-merge never: malformed set`. A consumer that switches on a prefix (`never none`, as one would for the other two lines' tokens) reads a non-empty list as no list. The format is unambiguous only under the rule "the verdict is the last word before the first `:`" (NAMECHARS excludes `:`), which neither the header nor the plan states. No consumer exists yet (the skill and U2's gate are the readers), so the rule is cheap to fix now and expensive after the skill parses it.

**Recommendation:** Either state the parse rule in the header and plan :204 ("the status is the word before the first `:`"), or put the status first for all three lines (`never set: GLOB… — line 2 …`) while the plan text is still the only consumer. Internal callers should use `NEVER`/`POLICY`, never re-parse the printed line.

#### 4. A4's fix (globform) diverges from the plan's "pathform globs" without a plan amendment

**Severity:** Minor
**Location:** `scripts/build-loop.sh:118-129`; `docs/working/plan-build-loop-handoff.md:74`
**Move:** 3 (contract drift) / 7 (asymmetry with pathform)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:118-121`; excerpt ends :121, `globform` continues to :129 — read):
```
# A Self-merge never: entry: pathform's characters and glob marks, not starting
# / or -, no empty, . or .. part. Unlike pathform it allows a part starting .git
# (.github/, .gitignore): the list only adds refusals, so naming one must not
# make the line malformed and turn self-merge off.
```
Evidence (`docs/working/plan-build-loop-handoff.md:74`):
```
  - **Per project.** `docs/dev-cycle.md` may add `Self-merge never: GLOB …` (pathform globs, one line, read from main's commit). A malformed line turns self-merge off for that repo (`--settings` says why).
```

A4 is fixed as intended: `Self-merge never: .github/ .gitignore` now prints `never .github/ .gitignore set:` and policy stays self-merge (probe; T45 :125-126, though :126's first `&&` operand, the `never` check itself, is not enforced under bats — fact-check Claim 38 / E2). The reasoning is sound — the list only adds refusals, so accepting more forms cannot widen what self-merges. But the plan still says "pathform globs", and globform also accepts `.git`, `.GIT/config` (probe: `never .git .GIT/config set:`; fact-check Claim 15). Two consequences for later units: U2's gate must consume `NEVER` without re-validating entries through `pathform glob` (which would now call `.github/` malformed and disagree with `--settings`), and must match `.git*` entries against changed paths harmlessly. The same file (`docs/dev-cycle.md:30`) tells users that `.git*` paths are refused for idea sources, a different rule for the same kind of path text.

**Recommendation:** Amend plan :74 to "globform globs (pathform's characters and glob marks; `.git*` parts allowed, since the list only adds refusals)" or add a `docs/decisions/log.md` row, and note in U2's brief that the gate uses the parsed `NEVER` value as-is.

#### 5. A failed tree read is reported as "not a regular file", unlike the lib's own wording

**Severity:** Minor
**Location:** `scripts/build-loop.sh:82-87`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:82-87`, inside `main_file` :79-94; excerpt ends :87, the function continues to :94 — read):
```
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
```

`main_entry` prints `error` when ls-tree fails (lib :251-252, :261); the `*` arm folds it into `notfile`'s message. Both lib callers distinguish it: `check_brief` prints "the default branch's tree could not be read" (`scripts/lib/dev-cycle-read.sh:325`), `check_answer` the same plus "so $f is not read" (`:544`). Fail-closed either way (never → `malformed`), so only the WHY misleads; reachable only when ls-tree fails after `main_by_name` succeeded (fact-check Claim 13).

**Recommendation:** Add `error) FILE_WHY="the default branch's tree could not be read, so $f is not read"; return 1 ;;` matching lib :544.

#### 6. Unknown-option message casing and suffix differ from every other script

**Severity:** Minor
**Location:** `scripts/build-loop.sh:56`, `scripts/build-loop.sh:62`
**Move:** 2 (naming) / 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `Unknown option: X` used in `scripts/dev-cycle.sh:111`, `scripts/skill-usage-report.sh:29`, `scripts/flag-removal-candidates.sh:42`, `scripts/archive-working-docs.sh:32`

Evidence (`scripts/build-loop.sh:56`, `:62`):
```
usage() { echo "$1 (usage: build-loop.sh --settings)" >&2; exit 1; }
  *) usage "unknown option: $1" ;;
```

The four sibling scripts print `Unknown option: X` with no suffix. Tests check only exit 1 and non-empty stderr (`test/scripts/build-loop-read.bats:139-143`), so this is cosmetic; the usage suffix is a reasonable addition but will need updating as U1c/U2/U3 add modes (it names only `--settings`).

**Recommendation:** `Unknown option: $1`; consider `(see build-loop.sh -h)` instead of listing modes, so the suffix does not go stale as modes land.

#### 7. `-h` exit status is omitted from the Exit line (matches dev-cycle.sh)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:40-41`
**Move:** 4
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# Exit: 0 every line printed; 1 bad usage, not a git repo, no perl or
# lib/dev-cycle-read.sh, or no default branch found by name.
```
Fact-check Claim 10 (Mostly accurate). `scripts/dev-cycle.sh:78-80` omits help's exit 0 the same way, so this is consistent with precedent; noted only. No action needed unless dev-cycle.sh changes too.

## What Looks Good

- The three-line output follows the plan's "Script interface" format exactly (plan :204), with a WHY on every line including `set` lines, which gives the skill one parse shape for all outcomes.
- Error/exit conventions match dev-cycle.sh: stderr for errors, exit 1 for usage/no repo/no perl or lib/no default branch, the `needs a default branch … found none` wording, `-h` via the header sed idiom.
- Fail-closed semantics are consistent across the three keys and with D5/D9: absent file → `never none`, unread file → `never malformed` and self-merge off; a self-merge policy with a malformed never line prints `policy review unset` with the reason, which keeps `POLICY` and the printed line in agreement.
- Reading only main's commit via `main_entry`/FENCE_AWK reuses the lib's reader exactly as `check_brief`/`check_answer` do, including the `notdir` wording.
- The tab/whitespace fix (R1/A1) is a sound contract choice: single spaces only, so no later reader can split differently.
- Script-private names (`main_file`, `SETTINGS_AWK`, `FILE_*`) follow the lib's `brief_fields`/`*_AWK`/`BRIEF_*` patterns.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Header's counting rule over-claims; bold-before-colon, task-item, table, link, NBSP, `\#`, double-space copies stay hidden (E3) | Inconsistent | `scripts/build-loop.sh:28-31`, `:106` | High |
| 2 | `docs/dev-cycle.md` rule ("reading exactly") disagrees with the script ("starts with the key"); slots/never undocumented; "not built yet" | Minor | `docs/dev-cycle.md:17-19`, `:9` | High |
| 3 | `never` line's status word is not positional (`never none set:`) | Minor | `scripts/build-loop.sh:170` | High |
| 4 | globform (A4 fix) diverges from plan's "pathform globs"; plan not amended; U2 must not re-validate with pathform | Minor | `scripts/build-loop.sh:118-129`; plan :74 | High |
| 5 | `main_entry` `error` reported as "not a regular file" (lib says "tree could not be read") | Minor | `scripts/build-loop.sh:82-87` | High |
| 6 | `unknown option:` casing/suffix vs `Unknown option:` in 4 scripts | Minor | `scripts/build-loop.sh:56`, `:62` | High |
| 7 | Exit line omits `-h` exit 0 (same as dev-cycle.sh) | Informational | `scripts/build-loop.sh:40-41` | High |

## Overall Assessment

The CLI surface is consistent with dev-cycle.sh's conventions and implements the plan's `--settings` format as written; nothing here breaks a consumer, and none exist yet. The substantive issue is contract legibility for the human editor (Finding 1, the E3 escalation): the header promises that rendered copies of a key are counted, but several common Markdown shapes still hide a second line. That gap fails open for self-merge, which makes it worth fixing before U2's gate reads `POLICY`. The rest are fixable in place or by plan/doc amendment: an unstated parse rule for the `never` line, the plan text still saying "pathform" after A4's fix, one error message that differs from the lib's, and message casing.

## Goal-Alignment Note

- **Success criterion (verbatim):** a markdown report saved to /workspace/.claude/wt-build-loop-u1b/docs/reviews/api-consistency-reviewer-review-2026-10-05-build-loop-u1b.md, structured per the api-consistency-reviewer skill.
- **Answered:** API-consistency review of `--settings`, `-h`, the three output lines' format and the `docs/dev-cycle.md` settings contract against dev-cycle.sh's conventions and plan rev 4 (D2/D5/D9, Script interface). E3 is weighed as a user-facing contract question (Finding 1, seven shapes reproduced). A4's globform fix is checked against the plan (Finding 4: works as intended; the plan text is stale).
- **Out of scope:** the constraints line and `--status` (U1c, absent by design); exploitability of the hidden-copy gap (security-reviewer's, E1/E3); test enforcement of non-final `&&` assertions (E2, test-strategy/orchestrator); settled override-log rows (`-h extra` exit 0, "byte-exact", graph-on-failure) — not re-raised.
- **Escalate:** Finding 1 to the orchestrator for synthesis with security-reviewer's E1/E3 verdict (the same gap, fail-open for self-merge); Finding 4's U2 consequence (gate must use `NEVER` as parsed, not re-validate with `pathform glob`) to U2's brief.
- **Questions / Decisions:** Finding 3 is a format decision best made before the skill parses the line (status-first vs documented "word before the first `:`"); either is consistent, the current unstated form is not. Finding 1's fix may push U1b past the 400-line cap; if so, the minimum is correcting the header claim and filing the gap.
