Commit: 2eebdf8

# API Consistency Review — Q-094 stacked unit B (`q094b-exit-scan-worktree-removal`)

**Scope:** `git diff 9075003 2eebdf8` (claude-workflows): `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `test/cc-isolated-functions.bats`. Unit A (dfe4c0d..9075003) read as context only.
**Date:** 2026-09-28
**Based on:** Stage-1 merged fact-check summary `scratchpad/B-fc-summary.md` (k=3; 0 behavioral Incorrect, 172/172 bats pass at 2eebdf8).
**Delivery mode:** self-read. One executed probe (scratch archive of 2eebdf8, `LC_ALL=C`, `GIT_CONFIG_GLOBAL=/dev/null`).

## Baseline Conventions

- **The `note:` line (unit A, frozen format by user decision).** One line, lower case: `note: exit scan: only linked worktrees in git's standard layout changed (<list>). <reason>, so this is not a finding.` Unit A's list is `added: <n> <n>…` (names `LC_ALL=C sort`ed, space-separated); the reason is `They take config and hooks from the checkout's own .git`. Consumers: two bats assertions (`test/cc-isolated-functions.bats:2234`, `:2469`) and the guide's quoted line (`guides/cc-isolated-usage.md:337-338`). No code parses it.
- **`_snap_*` helper return convention** (`cc-exit-scan.sh:144-300`, `:534-560`, `:776-807`): values come back on **stdout** (`_snap_hash`, `_snap_first_line`, `_snap_path`, `_snap_dotgit_target`, `_snap_hash_str`), as a **predicate status** (`_snap_inside_ws`, `_snap_file_is`), by appending to the **shared dynamic-scope record buffer** `_snap` or setting the shared global `_snap_linkdir` (`_snap_file`), or, in one case, into an **output file** named by the first argument (`_snap_find <out> <find args...>`). The file header (`:144-147`) says `_snap_*` helpers run inside `git_exec_snapshot`, share its locals, and "return 1 after printing a reason on stderr". Unit A already added two silent helpers used from `scan_std_worktrees` (`_snap_hash_str`, `_snap_file_is`).
- **Out-variables elsewhere in the repo:** namerefs in `scripts/lib/si-morning-summary.sh:1532` (`local -n _srf_out="$2"`, prefixed local to avoid name capture), `:1555`, and `hooks/auto-approve-allowed-commands.sh:328`. No `printf -v "$var"` anywhere else in `devcontainer-config/*.sh`.
- **Acceptance contract of `scan_std_worktrees`** (unit A): paths compared as `%q` strings recomputed from `<n>` (`:823-824`), decline on anything unreadable, one `note:` on acceptance.

## Name-Pattern Audit

| New name / surface | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `_snap_unq <q> <var>` | helper function | `_snap_hash_str <string>`, `_snap_first_line <file>`, `_snap_find <out> <args>` | `devcontainer-config/cc-exit-scan.sh:167-275`, `:777-807` | Name consistent (terse `_snap_<abbrev>` like `_snap_wrel`, `_snap_opt`, `_snap_cond`); **return convention inconsistent** — first out-var-by-name helper (Finding 3) |
| `removed: <n> …` note list segment | message field | `added: <n> …` | `cc-exit-scan.sh:936` (unit A form) | Consistent — same `label: sorted space list` shape, same `LC_ALL=C sort` |
| `(added: x; removed: y)` combined segment | message field | none (unit A had one group only) | none — searched `devcontainer-config/*.sh` for multi-group parenthesised lists | New convention; `; ` separator is reasonable and fixed order (added first) is deterministic |
| `Removed ones left no git dir behind` / combined `…, and added ones take config and hooks …` | message reason | `They take config and hooks from the checkout's own .git` | `cc-exit-scan.sh:937` | Consistent — same `<reason>, so this is not a finding.` tail; `They` becomes `added ones` only when disambiguation is needed |
| `removed` (array), `why` (local) | private locals | `added` | `cc-exit-scan.sh:828` | Consistent (private, not audited further) |
| bats test titles `exit scan Q-094: …`, `_snap_unq: …` | test names | `exit scan Q-094: …` | `test/cc-isolated-functions.bats:2226-2350` | Consistent |

## Findings

#### 1. Add and remove accept different path sets: a `$'…'`-quoted working tree is a note when added and a warning when removed

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-exit-scan.sh:885-887` (removal decode) vs `:913-921` (added side, recomputed `%q` lookup); `guides/cc-isolated-usage.md:345-346`; commit 2eebdf8 message body line 25
**Move:** 7 (asymmetry), 3 (documentation drift)
**Confidence:** High (executed)

The added side never unquotes: it looks up `dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]`, so any path `printf %q` can render — including the `$'…'` form — matches. The removal side must recover the path from the record and does so with `_snap_unq`, which declines `$'…'`:

> `      _snap_unq "$q" wt || return 1` (`cc-exit-scan.sh:887`)
> `  case "$q" in \$\'*|\'*|"") return 1 ;; esac` (`:788`)

Executed probe (scratch copy of 2eebdf8, `LC_ALL=C`): `git worktree add .claude/worktrees/tab<TAB>x` → `note: exit scan: only linked worktrees in git's standard layout changed (added: tab-x). …` rc 0; then `git worktree remove` of the same tree → `WARNING: this session changed what HOST git reads …` rc 1. The fact-check replicates found the same for `é` under the C locale. So one agent worktree produces a note at birth and a finding at death. It fails closed, so it is not a security defect, but the user-visible contract ("a linked worktree added or removed in git's own layout … is not a finding", guide `:66`) is not symmetric, and the two places that describe it disagree: the guide scopes the `$'…'` caveat to removals only —

> `other byte that bash's `%q` quotes as `$'…'` warns. For an added` (`guides/cc-isolated-usage.md:346`)

— which is accurate, but the commit message claims symmetry that does not exist:

> `the added side already declines such paths (its back-pointer read` (2eebdf8 message)

That is true only for a newline (the back-pointer is read as one line); a tab or non-ASCII-in-C-locale path is accepted when added.

**Recommendation:** Keep the fail-closed decode (it is the right call for a tripwire) but state the asymmetry once where users read it, e.g. append to guide `:345-346`: "such a worktree is a note when added but warns when removed." The commit message cannot be amended on a stacked unit without a rewrite; record the correction in the merge commit body or the plan's row 6 instead.

#### 2. `scan_std_worktrees`' contract comment and plan row B18 still say nothing is unquoted

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:823-824`; `docs/working/plan-q094-exit-scan-worktree-layout.md:90`
**Move:** 3 (documentation drift)
**Confidence:** High

The function's header is its contract for maintainers and it now contradicts its own body:

> `# at snapshot time and now. Paths are compared as the %q` / `# strings the records hold, recomputed from <n>; nothing is unquoted.` (`:823-824`)

while `:887` runs `_snap_unq "$q" wt`. Plan B18 says the same ("paths are compared as the `%q` string recomputed from the parsed name, never unquoted"), although the same plan's row 6 (edited in this unit) now says "a path `%q` writes as `$'…'` is not decoded and warns". The header sentence was written for the added-only rule and was not scoped when the removal rule was added three lines above it.

**Recommendation:** Scope the sentence: "Added paths are compared as the %q strings recomputed from <n>; a removal decodes its dotgit record's path with _snap_unq (backslash form only; `$'…'` declines)." Update B18 to match.

#### 3. `_snap_unq` returns through a caller-named variable — the first `_snap_*` helper to do so, and unprotected against name capture

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:783-796`
**Move:** 1, 2 (convention of the helper family)
**Confidence:** High

Precedent: value returned on stdout by `_snap_hash`, `_snap_first_line`, `_snap_path`, `_snap_dotgit_target`, `_snap_hash_str` in `devcontainer-config/cc-exit-scan.sh:167-290`, `:536-549`, `:777-782`; caller-named outputs elsewhere use a prefixed nameref local (`local -n _srf_out="$2"`) in `scripts/lib/si-morning-summary.sh:1532`.

> `  local q="$1" s="" c i` … `  printf -v "$2" '%s' "$s"` (`:787`, `:795`)

Every sibling a reader would pattern-match against returns on stdout, so a future caller will naturally write `wt="$(_snap_unq "$q")"` — which silently sets nothing and leaves `wt` empty (then `case "$wt" in */.git)` declines, so it fails closed, but the removal acceptance would quietly stop working). Separately, because `printf -v` writes to the innermost visible variable of that name, a caller passing `q`, `s`, `c` or `i` as `<var>` gets `_snap_unq`'s own local written and loses the result; the repo's only other out-by-name helper avoids exactly this with an underscore-prefixed local. There is a plausible reason for the choice (no subshell; command substitution strips trailing newlines), but a trailing newline can only appear in the `$'…'` form, which this helper already declines, so stdout would lose nothing.

**Recommendation:** Either return on stdout like the siblings (`wt="$(_snap_unq "$q")" || return 1`), or keep the out-var and rename the locals (`_su_q _su_s _su_c _su_i`) and add "(out-var, not stdout)" to the doc line.

#### 4. The guide quotes only the added form of the note line and frames the section as "left behind"

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:66`, `:334`, `:337-338`
**Move:** 3 (documentation drift)
**Confidence:** High

The note line now has three shapes and three reason sentences (`cc-exit-scan.sh:935-942`), but the guide still shows only unit A's:

> `in git's standard layout changed (added: agent-x) …` line instead of the` (`:338`)

and the surrounding framing still describes only additions: step 7 says "A linked worktree added or removed in git's own layout (an agent worktree left behind)" (`:66`) and the section heading is "**Linked worktrees left behind (Q-094).**" (`:334`) — a removed worktree is the opposite of left behind. A user who sees `(removed: agent-y). Removed ones left no git dir behind, …` has no quoted example to match it against.

**Recommendation:** Show the removed form too, e.g. "`(added: agent-x)` or `(removed: agent-y)` … line", and drop or broaden "left behind" (e.g. heading "Linked worktrees added or removed (Q-094)"; step 7 "(agent worktrees come and go)").

#### 5. The `_snap_*` family header no longer describes the family

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:144-147`, `:783-796`
**Move:** 1
**Confidence:** High

Precedent: header contract "run inside git_exec_snapshot and share its locals … Each returns 1 after printing a reason on stderr" in `devcontainer-config/cc-exit-scan.sh:144-147`; unit A already broke it with `_snap_hash_str` / `_snap_file_is` (silent, called from `scan_std_worktrees`).

`_snap_unq` is a third silent, snapshot-independent helper under the `_snap_` prefix and prints no reason on decline. It is consistent with unit A's two, so this is not a regression of B; it is the point where the header's "each" is plainly false for a group of three.

**Recommendation:** One header sentence: "`_snap_hash_str`, `_snap_unq` and `_snap_file_is` are pure checks used by `scan_std_worktrees` too; they fail silently." No rename needed.

#### 6. "Removed ones left no git dir behind" states more than the check establishes

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:939-940`
**Move:** 4 (message accuracy/tone)
**Confidence:** Medium (fact-check "Mostly accurate", security escalation owns the substance)

The reason sentence is an unqualified claim, but the code checks for a git dir only at `P`, at the old working-tree root (`looks_like_gitdir "$wt"`, `:889`), and via the absent `.git` record; the fact-check's executed probes show a bare repo in a subdirectory of the removed tree, or under a symlinked parent, still gets this note. The added-side reason ("They take config and hooks from the checkout's own .git") is a claim about git's behaviour that is verified; the removed-side one is a claim about the disk that is only partly verified. For API consistency this is only a wording point — the security reviewer owns whether the gap matters.

**Recommendation:** Word it at the strength of the check, e.g. "Removed ones' git dir and `.git` file are gone", which is exactly what the rule establishes.

## What Looks Good

- The note's list grammar extends unit A's cleanly: same `label: names` shape, same sort, `; ` between groups, fixed order, and the added-only output is byte-identical to unit A (the unit-A assertions at `:2234`/`:2469` pass unchanged) — no break for any existing consumer.
- The reason sentence keeps the `<reason>, so this is not a finding.` tail in all three variants, and only switches `They` to `added ones` when both groups are present — minimal, readable variation.
- Record matching is symmetric by construction: `hk` is built from `${rec:0:1}` so the removed side requires the removed `hooksdir … missing` exactly as the added side requires the added one; both sides consume `commondir-file`/`hooksdir`/`dotgit` via the same `used` set and the same "every record accounted for" loop.
- Content pairing of the removed `.git` (`:878-884`) mirrors the added side's hash check against both the host and container `gitdir:` forms — the same two-form rule on both sides.
- `_snap_unq` self-verifies by re-quoting (`:794`), so its partial decoder can only decline, never mis-accept; the doc line states the declined forms. Tests cover round-trip, `$'…'`, `''` and a trailing backslash.
- Guide, plan row 6, function header and in-code comment were all updated in the same unit; the only stale spots are the ones in Findings 2 and 4.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `$'…'` working tree: note when added, warning when removed; commit message claims symmetry | Inconsistent | `cc-exit-scan.sh:885-887` vs `:913-921`; guide `:345-346`; 2eebdf8 msg | High |
| 2 | Function header and plan B18 still say "nothing is unquoted" | Minor | `cc-exit-scan.sh:823-824`; plan `:90` | High |
| 3 | `_snap_unq` out-var return, unlike every `_snap_*` sibling; locals capturable | Minor | `cc-exit-scan.sh:783-796` | High |
| 4 | Guide quotes only the added note form; "left behind" framing | Minor | `guides/cc-isolated-usage.md:66`, `:334`, `:337-338` | High |
| 5 | `_snap_*` header contract false for three silent helpers | Informational | `cc-exit-scan.sh:144-147` | High |
| 6 | "Removed ones left no git dir behind" overstates the check | Informational | `cc-exit-scan.sh:939-940` | Medium |

## Overall Assessment

Unit B extends unit A's public surface consistently: the note line is backward-compatible (added-only output unchanged), the new `removed:` and combined forms follow the same grammar, and the record-matching rules mirror the added side. Nothing breaks a consumer. The one real inconsistency is behavioural symmetry: a worktree whose path `%q` writes as `$'…'` is accepted when added and warned about when removed. That fails closed and is rare (tab, or non-ASCII under the C locale), and the guide already describes the removal side correctly; it needs one clause saying the add side differs, and the commit message's contrary claim should be corrected where it can be (merge body or plan). The rest is documentation drift inside the unit (a function header and plan row that still say "never unquoted", a guide example showing only the added form) and one helper-convention choice (`_snap_unq`'s out-var) that is safe today but invites the stdout calling pattern its siblings use. All are fixable in place with a few lines; none blocks the merge.

## Goal-Alignment Note

The PR's goal is that a standard `git worktree remove` during a session yields a note and status 0, while anything that could make host git run something new still warns. From the API-consistency side the surface serves that goal: the message the user sees is consistent with unit A, and every deviation found fails toward warning rather than toward silence. Finding 1 is the only place a user would notice a contract that differs by direction, and Finding 6 is the only place the user-facing text claims more than the code checks; both concern what the user is told, not what the scan accepts. The substantive question behind Finding 6 (bare repos below the old tree root or behind a symlinked parent) belongs to the security reviewer, as the fact-check escalated.
