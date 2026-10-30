Commit: ed06dec1

# Architecture Review: Q-092 unit 2 (fix/q092-drop-hook-deny-reader)

**Scope:** `git diff 1a831ffe..ed06dec1` (unit 2). Unit 1 (`00a27a2f..1a831ffe`) read as context only.
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-q092b-2026-10-15.md` (19 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable), plus the known-findings list in the review brief.

**Scope check:** in scope under *cross-cutting concerns*: the permission pipeline, meaning which component interprets `permissions.deny`. Also under *public API*: the hook's CLI surface loses `--deny` (unit 1), and its settings-file contract narrows (unit 2). The test suite passes at HEAD: 33 tests, 0 `not ok`.

## Dependency Map

- **Claude Code (permission engine)** reads `allow` / `ask` / `deny` from the merged settings files and applies deny > ask > allow (decision 023). It calls the hook at PreToolUse and folds the hook's decision into that precedence. Per Q-082, a hook `allow` does not beat `deny`.
- **`hooks/auto-approve-allowed-commands.sh`** depends on: the settings files (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`, the project `settings.json` and `settings.local.json`), resolved the same way as `devcontainer-config/link-claude-home.sh`'s DEST; and on `jq` and `shfmt`. After unit 2 it reads only `permissions.allow`. It checks the shape of `permissions` and `permissions.deny`. Its only output is the allow JSON or nothing (`:352`, the single `echo` of a decision).
- **`hooks/wiring.json`** is the data source for the deny rule (`Bash(*.credentials.json*)`). The linker merges it into the global settings. After unit 2, Claude Code is its only consumer. Before unit 2, the hook consumed it too.
- **Docs that state the ownership:** the hook header (ROLE, DENY RULES ARE CLAUDE CODE'S, FAILS CLOSED), the `wiring.json` `_comment`, `guides/bare-host-hook-wiring.md` §known gaps, decision log row 53, and decision 023.

Dependency direction after unit 2: the hook depends on settings data and on Claude Code's precedence contract. Nothing depends on the hook's deny behaviour any more. Before unit 2 there were two consumers of one policy datum (the deny list), with divergent matchers. Now there is one.

## Findings

#### 1. The `permissions.deny` shape check is justified coupling to the settings schema, not to deny semantics, but it mirrors only part of that schema, and its premise is unverified

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:69-73`, `:134-150`
**Move:** 7 (coupling surface), 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
# permissions.allow or permissions.deny of the wrong shape, no command is
# approved on that call. permissions.deny is shape-checked but not read: Claude
# Code may reject such a file, and then its allow rules should not count here.
...
  elif ((.deny // []) | type != "array" or any(.[]; type != "string"))
    then error("permissions.deny is not an array of strings")
  else
    (.allow // []) | if type == "array" then .[] | select(type == "string")
                     else error("permissions.allow is not an array") end
```

What remains is stamp coupling to the settings *document shape*, not control coupling to deny *meaning*. The hook never matches, parses or acts on a deny rule's content. The rationale is coherent: if Claude Code discards a malformed file, that file's allow rules are not in force, so the hook should not honour them either. Unit 2 therefore leaves no residual deny-semantics coupling. There are two weaknesses, though.

(a) The check is a partial, hand-picked mirror of Claude Code's settings validation. It checks `deny` but not `permissions.ask` (or `defaultMode`, `additionalDirectories`). On the hook's own reasoning, an ill-shaped `ask` makes the file equally rejectable. So the only reason `deny` is singled out is history: it is the leftover of the removed reader.

(b) The premise "Claude Code may reject such a file" is unverified. The header's "may" is honest. Even so, the check's justification rests on assumed upstream behaviour, the same pattern that row 53's original deny reader rested on. The plan's F6 row records it as "kept: the same jq validation".

Neither weakness widens what the hook approves: both only make it approve *less*. Severity stays Minor.

**Recommendation:** Keep the check. To remove the asymmetry, either shape-check `permissions.ask` with the same rule, or reword the comment to say the `deny` check is kept because it already existed and costs nothing, rather than as a principled mirror of Claude Code's validation. If anyone ever checks how Claude Code treats a non-array `deny` on a host, record the result next to this comment.

#### 2. Row 53's 2026-09-27 amendment still points to a header section unit 2 deleted

**Severity:** Informational
**Location:** `docs/decisions/log.md:76` (row 53, 2026-09-27 amendment)
**Move:** 3 (module boundary: the doc that claims to be the one statement)
**Confidence:** High
**Legibility-target:** for-future-reader

**Evidence:**
```
What the check guarantees, its residuals and the allow-vs-deny rule table live in the hook header only.
```

Unit 2 removes WHAT THE DENY CHECK GUARANTEES and RESIDUALS from the header. The new 2026-10-15 amendment in the same cell says the reader is gone, so a careful reader can work out the story. But a reader who follows the 09-27 amendment's pointer will find no such section. The row is append-only history, so editing the earlier amendment is not expected. The new amendment could add a one-clause pointer ("now: the header's ROLE and DENY RULES ARE CLAUDE CODE'S sections"). The grep found no other live reference to the removed section names outside `docs/reviews/` and the archive.

**Recommendation:** Optional: add the replacement section names to the 2026-10-15 amendment.

#### 3. A removed option is swallowed silently, so a stale `--deny` caller gets no deny without an error

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:264-278`; `test/auto-approve-allowed-commands.bats:182-186`
**Move:** 3 (public surface narrowed)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
      *)
        shift
        ;;
```
```
@test "the hook ignores a --deny argument (the option was removed in Q-092)" {
```

Unit 1 narrows the CLI surface, and the catch-all arm turns the removed `--deny` into a no-op. It is not rejected. The test pins that as intended. The behaviour is fail-safe in the only direction that matters, because Claude Code still applies deny. And no in-repo caller passes `--deny` (grep: none outside tests). The arm predates Q-092, so this is an observation about the narrowed contract, not a defect.

**Recommendation:** None required. If the CLI grows again, consider having unknown flags exit 0 silently *with a debug line*, so a stale caller is visible under `--debug`.

## Responsibility boundary: answers to the brief

- **Is the boundary now clean (hook = allow-only convenience; Claude Code = deny)?** Yes. `DENY_GLOBS`, `DENY_ALL`, `add_deny_rule`, `matches_deny` and both call sites are gone (fact-check Claim 17). The jq program emits only allow records. `main` has one decision output (`:352`), and every other path exits 0 with no output. The stdout test pins never `ask`/`deny`/`defer`. Fact-check flags that the test does not reach the jq-missing exit, but that path's `exit 0` with only a `debug` call is plain on reading. That settles Q-092's "can the hook ever emit `ask`" check structurally as well as by test: the only decision literal in the file is `allow`. The fail-closed loader is still needed even with deny gone, and the header now says why ("a wrongly resolved file could add allow rules"). It guards *allow* integrity, which is within the hook's responsibility.
- **Residual deny coupling?** Only the shape check (Finding 1). It is coupling to the document shape, defensible, and slightly asymmetric. The settings-source resolution shared with the linker remains, and is still right: it decides which allow rules count.
- **Is the stacked split coherent?** Yes. At 1a831ffe the deny reader is intact and functional: raw match on the full string and on each extracted command, `DENY_ALL` fail-closed, and the settings deny lists still read even under `--permissions`. Only the test-only `--deny` and the de-quoted pass are removed, and the header says "unit 1 of 2". The intermediate state never relaxes the hook below what Q-082 already guarantees. The one stale part of the intermediate state, the ROLE text still calling the check load-bearing, is already in the known-findings list and is rewritten by unit 2. One semantic shift between the units is worth knowing: in unit 1 a bad settings file meant "deny everything" (`DENY_ALL`); in unit 2 it means "no allow rules". The observable outcome is the same, no approval, so the split boundary does not change behaviour.
- **One ownership story across the docs?** Yes. The hook header (ROLE, DENY RULES ARE CLAUDE CODE'S), the `wiring.json` `_comment`, the bare-host guide and row 53's new amendment all say three things: the hook emits only `allow` or nothing; Claude Code applies deny after a hook `allow` (Q-082); and the string-match residuals (glob spellings; quote-split and compound-list spellings unverified on a host) now belong to Claude Code's matcher. Decision 023 needed no edit. It never said the hook reads deny rules. Its "deny > ask > allow, so a `deny` … beats an `allow` from auto-approve" (`023:73-74`) and its Amendment B note that a hook `ask` overrides deny (#39344) both match the new story, and now they also agree with the code. The only drift is the historical pointer in Finding 2.

## What Looks Good

- **One interpreter per policy datum.** The deny list in `wiring.json` now has a single consumer, which removes the divergent-matcher problem from architecture-review-2026-09-27 finding 1. Finding 3 there, two parsers for one grammar, also shrinks to one parser with one reading (allow prefix).
- **The role is stated as a contract, not a description.** The header's ROLE section names the full output alphabet ("allow" or nothing) and why that alphabet is what makes leaving deny to Claude Code safe. A future change that adds `ask` would visibly break a stated invariant and a test.
- **Fail-closed was re-justified, not just kept.** The relative-`CLAUDE_CONFIG_DIR` and newline guards now give an allow-side reason. Without one they would read as leftovers of the deny reader.
- **Residuals moved owner without disappearing.** The guide, `wiring.json` and row 53 all say the quote-split and compound-list cases are now Claude Code's and unverified. None of them claims coverage.
- **The stacked split puts the low-risk, test-only removals first,** so unit 1 is independently mergeable and leaves a working deny reader.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `permissions.deny` shape check: shape coupling, not semantic; asymmetric (no `ask`) and rests on unverified upstream rejection | Minor | `hooks/auto-approve-allowed-commands.sh:69-73, 134-150` | Medium |
| 2 | Row 53's 09-27 amendment points to deleted header sections | Informational | `docs/decisions/log.md:76` | High |
| 3 | Removed `--deny` is silently swallowed by the catch-all arm | Informational | `hooks/auto-approve-allowed-commands.sh:264-278` | High |

## Overall Assessment

Unit 2 improves the system's structure and closes finding 1 of architecture-review-2026-09-27. The hook goes back to a single responsibility: a pipe-aware allow layer with a stated output alphabet of `allow` or nothing. Deny interpretation has one owner, Claude Code. Every doc that states ownership agrees, and decision 023 already agreed. The stacked split leaves a consistent intermediate state. The most important remaining structural point is small: the `permissions.deny` shape check is the last trace of the old reader. It is defensible as a settings-integrity check, but it is a partial mirror of Claude Code's validation that rests on an unverified assumption. Making it symmetric (`ask` too) or honestly labelled would finish the cleanup. No security-review file covers this diff, and none of the findings is a module-boundary finding under move 3 that moves a trust boundary, so the trust-boundary cross-reference is a no-op.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved at the output path given below, structured per the named skill, with a `Commit: <sha>` first line and a Goal-Alignment Note.
- **Answered:** Is the responsibility boundary clean? Yes. Does the hook still couple to deny semantics? No; it couples only to the document shape (Finding 1). Is the deny shape check justified? Yes, with an asymmetry. Is the split coherent? Yes. Do the docs tell one ownership story? Yes, with one stale historical pointer (Finding 2).
- **Out of scope:** Bypass-spelling adequacy of Claude Code's matcher (plan F3/F4, known and accepted; security-reviewer). Exact wording errors already in the known-findings list (the `Bash(ls *)` row, `false`/`null` read as absent, the U1 NUL test, the stdout-test coverage comment). They were not re-filed.
- **Escalate:** None. Finding 1's premise (whether Claude Code rejects a non-array `deny`) could be added to any future host check, but nothing blocks on it.
- **Decisions I made:** Rated the shape check Minor, not Coupling, because it can only reduce approvals and it touches the shape of `deny`, not its meaning. Treated decision 023 as needing no change, because it never claimed the hook reads deny. Ran the hook suite once at HEAD to confirm the state is consistent (33 pass).
