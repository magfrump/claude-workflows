Commit: a54bb3b0

# API Consistency Review: fix/cc-isolated-one-workspace

**Scope:** `git diff 5e6e9266..a54bb3b0` (cc-isolated.sh `main()`/header, install.sh "Next steps", guides/cc-isolated-usage.md, test/cc-isolated-functions.bats); guides/devcontainer-setup.md read for doc consistency (not in the diff)
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-one-workspace.md (Stage-1 summary in the shared context)

## Baseline Conventions

- **Parser prior art, `cc-push.sh` `main()` (lines 430-450):** left-to-right `case` loop. A value flag with no value goes to `usage_die`. `--help|-h` prints usage and exits 0 when the parser reaches it. `--` breaks. Any other `-*` is `usage_die "unknown flag: $1"`. A second positional, or more than one word after `--`, or one word after `--` once a checkout is set, is `usage_die "one checkout at a time"`. The header says so: "One checkout at a time: a second one, before or after `--`, is a usage error." (cc-push.sh:27).
- **Usage-error shape:** `ERROR: <reason>` on stderr, then the full usage header on stderr, then exit 2. cc-push routes this through one helper, `usage_die` (cc-push.sh:242-246), and passes the text through `vis`. cc-isolated before this diff wrote it inline at each site (`--profile` without a value, `unknown flag`, cc-isolated.sh:768-780), with no sanitisation.
- **Exit status (decision log #58):** 0 success, 1 an error or a declined prompt, 2 bad usage. cc-isolated adds 3 and 4 for the exit scan.
- **Ordering (decision log row 71):** "`--help` and usage errors are answered first", which means before the host-tool refusal. In cc-isolated that refusal is the `HOST_TOOLS_ERR` block right after the parse loop.
- **Copyable-command docs:** both guides and both `--help` headers show commands in aligned blocks of `command   # note`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `workspace_usage_error` | internal function (usage-error helper) | `usage_die` (cc-push), the inline `echo "ERROR: ..."; usage >&2; exit 2` sites in cc-isolated | `devcontainer-config/cc-push.sh:242`, `devcontainer-config/cc-isolated.sh:768-780` | Mostly consistent. It has the same shape as `usage_die` (ERROR line, usage on stderr, exit 2) but a different name, and it adds a fixed two-line hint. Informational (F6). |
| `two_workspaces` | internal function | `usage_die "one checkout at a time"` | `devcontainer-config/cc-push.sh:442,447` | Consistent in rule. The message differs (F3). |
| `two workspaces given: A and B. cc-isolated takes one.` | usage-error message | `one checkout at a time`, `unknown flag: X`, `--profile needs a value` | `devcontainer-config/cc-push.sh:441-447`, `devcontainer-config/cc-isolated.sh:768-780` | Same `ERROR:` prefix and exit 2, but the wording differs from the sibling tool for the same rule (F3). |
| `<word> is not a workspace; it looks like a pasted comment (...)` | usage-error message | none. cc-push has no `#` rule. | none. Searched `devcontainer-config/*.sh` for `\#\*)` and `pasted comment`. | A new rule that only one of the two tools has (F4). |
| "Next steps (copy the command lines only):" | install.sh printed output | the old "Next steps:" block | `devcontainer-config/install.sh:614` | Consistent. |

The diff adds no new flags, exit codes or env vars.

## Findings

#### F1. The guides and the `--help` header still print copyable lines with trailing `# notes`. Pasted into default zsh, `--bless` and `--list` lines that used to work now exit 2

**Severity:** Inconsistent. This is a documented narrowing, not a silent break, but some previously working doc-copied invocations stop working.
**Location:** `guides/cc-isolated-usage.md:20-35`, `:564`, `:592`, `:626`; `guides/devcontainer-setup.md:47-48`, `:79-81`, `:114`, `:153`, `:174`; `devcontainer-config/cc-isolated.sh:7-17` (the `--help` header)
**Move:** 3 (trace the consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** user copying commands from the guides or `--help`

Evidence:
```
guides/cc-isolated-usage.md:22:cc-isolated --list                # blessed config hash + verified-live status, host-tool state, registered projects
guides/cc-isolated-usage.md:24:cc-isolated --bless               # re-bless the installed config after YOU reviewed it
guides/devcontainer-setup.md:81:cc-isolated --list                                     # who has what
guides/devcontainer-setup.md:114:cc-isolated --register ~/code/api --profile python   # opens PyPI, re-blesses, rebuilds next launch
```
Old parser (base 5e6e9266, cc-isolated.sh:759 and :798-799): `*) ws_arg="$1"; shift ;;` then `bless) bless_manifest; exit 0 ;;` / `list) list_projects; exit 0 ;;`. These run before `resolve_workspace`.

install.sh's block was rewritten so that no command line carries a note, because zsh passes the note through as arguments. The same hazard is still in every other copy source. Under the old parser, pasting `--bless`/`--list` with a note into default zsh worked, because those actions never read `ws_arg`. At HEAD the `#` word hits the `\#*)` arm and exits 2. The `--register … # note` lines used to fail with exit 1 or open the wrong path, and now exit 2 with a clear message. That part is an improvement. The new guide paragraph warns "Copy the command, not its `# …` note", and the error message explains itself, so this is a consistency gap rather than a trap. Still, the tool now rejects the form its own docs present, and only one of the four copy sources was fixed.

**Recommendation:** Pick one of two options. (a) Give the guides' fenced blocks and the `--help` header the install.sh treatment: put the note on its own line, or move notes out of the code blocks. (b) Record the decision that `#` in a fenced block is acceptable because the refusal explains itself. Either way, add the remaining copy sources to the plan's scope or to its deferred list. Today the PR intent covers only install.sh.

#### F2. The `--help` header states the `#` rule without "before `--`" and gives only the `./#x` escape

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:18-20`
**Move:** 3 (documentation drift); builds on the fact-check's "Mostly accurate" verdict
**Confidence:** High
**Legibility-target:** `--help` reader

Evidence:
```
# One workspace per run. A second one, or a word starting with '#' (a pasted
# '# note': zsh passes it as words unless interactive_comments is set), is bad
# usage, exit 2; name a directory called '#x' as ./#x.
```
The guide gives both escapes ("`./#name` or `-- '#name'`") and limits the refusal to "before `--`". The code matches the guide: words after `--` skip the `\#*)` arm, and the bats test "a directory named '#x' is still reachable as ./#x and after --" passes. cc-push's header mentions `--` for its one-checkout rule ("before or after `--`"). The new header says nothing about `--` for either rule, so `--help` and the guide describe the same contract at different levels of detail.

**Recommendation:** Add "before `--`" and "or `-- '#x'`" to the header line, or mention `--` in the one-workspace sentence the way cc-push.sh:27 does.

#### F3. cc-isolated and cc-push word the same rule differently

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:757-758`
**Move:** 4 (error consistency); 2 (naming)
**Confidence:** High
**Legibility-target:** user of both host tools

Precedent: `usage_die "one checkout at a time"` used in `devcontainer-config/cc-push.sh:442,447`

Evidence:
```
two_workspaces() {
  workspace_usage_error "$(printf 'two workspaces given: %q and %q. cc-isolated takes one.' "$1" "$2")"
}
```
The guide says the two tools follow "the same rule". The rule is the same, with one edge case noted below, and so are the exit code and the `ERROR:`-then-usage shape. The wording is not. cc-isolated names both values; cc-push names neither. cc-isolated's message is more useful, so the recommendation is not to weaken it. One edge case does differ: cc-isolated sets `ws_given=1` even for an empty word, so `cc-isolated '' -- B` exits 2, while cc-push accepts `'' -- B` and `'' B` because it tests `[ -z "$start" ]`. The fact-check verified this. No caller passes an empty positional.

**Recommendation:** Accept the divergence for this unit, and record it in a decision-log row or the plan as cc-push's wording to align later. Or have cc-push name its two checkouts in a follow-up. No change is needed here.

#### F4. The `#` refusal exists in cc-isolated only. cc-push still takes a `#` word as its checkout

**Severity:** Informational (no precedent; the floor rule applies)
**Location:** `devcontainer-config/cc-isolated.sh:781-783`; `devcontainer-config/cc-push.sh:442`
**Move:** 7 (asymmetry)
**Confidence:** Medium. The cc-push behaviour comes from reading the code, not a probe.
**Legibility-target:** maintainer of the two parsers

No existing precedent in `devcontainer-config/*.sh` (searched for `\#*)` and `pasted comment`)

Evidence: cc-push.sh:442 `*)  [ -z "$start" ] || usage_die "one checkout at a time"; start="$1"; shift ;;`. A `#` word is just a positional there. The guide line `cc-push ~/code/app   # afterwards (or from inside it: cc-push)` pasted in zsh still exits 2, through "one checkout at a time". But `cc-push  # --yes` sets `start='#'` and then `yes=1`. That form fails later in `find_checkout` rather than at parse time, so no push happens, but the note's later words are still read as flags. The guide documents the asymmetry ("`cc-isolated` also refuses a word starting with `#`"), so this is deliberate. It is still a new convention that only one of two sibling parsers sets.

**Recommendation:** Note cc-push as a follow-up candidate in the plan's deferred list, so the convention spreads on purpose rather than by accident.

#### F5. The "pasted note" hint prints for every two-workspace error, including forms no note can produce

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:749-755`, `:792-793`
**Move:** 4 (error messages helpful and consistent in tone)
**Confidence:** High
**Legibility-target:** user who typed `A -- B` or `-- A B`

Evidence:
```
workspace_usage_error() {
  printf 'ERROR: %s\n' "$1" >&2
  echo "  A pasted line ending in a '# ...' note does this: interactive zsh passes the" >&2
  echo "  note as arguments unless 'setopt interactive_comments'. Rerun without the note." >&2
  usage >&2
  exit 2
}
```
A note that starts with `#` is caught by the `\#*)` arm before any second workspace. So the two-workspace path can fire on a note only when the note's first word does not start with `#`, which a zsh note always does. In practice, someone who gets "two workspaces given" typed two paths, or used `--`. Telling them "Rerun without the note" is misleading. The other usage errors (`unknown flag`, `--profile needs a value`) print only the reason and the usage.

**Recommendation:** Print the zsh hint only from the `\#*)` arm, and let `two_workspaces` print just `ERROR:` plus the usage, like the other usage errors.

#### F6. The new helper duplicates cc-push's `usage_die` under a narrower name, and the older inline usage errors in cc-isolated still don't use it

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:749`, `:768-772`, `:780`
**Move:** 2 (naming), 4
**Confidence:** High
**Legibility-target:** maintainer

Precedent: `usage_die` used in `devcontainer-config/cc-push.sh:242`

cc-isolated now has three ways to raise a usage error: an inline block (`--profile`), an inline one-liner (`unknown flag`), and `workspace_usage_error`. Values go to the terminal raw in the first two (`ERROR: unknown flag: $1`, pre-existing) and escaped with `%q` in the third. cc-push escapes all of them with `vis`. The `%q` choice is justified in the comment, but it leaves the unknown-flag echo of untrusted input as the odd one out.

**Recommendation:** Optional follow-up: a single `usage_die` in cc-isolated with the hint split off (see F5) would make all three sites uniform.

#### F7. `--profile` takes the next word unchecked, so a note can still reach the parser as flags through it

**Severity:** Informational (the API angle only; escalated to security-reviewer by the fact-check)
**Location:** `devcontainer-config/cc-isolated.sh:764-772`
**Move:** 3
**Confidence:** High. This is the fact-check's verified finding.
**Legibility-target:** reviewer of the plan's F5 claim

The fact-check verified that `cc-isolated --profile '#' --bless` runs a bless. Value-taking flags that consume the next word unchecked are consistent with cc-push (`--remote`, `--branch`, `--clone` do the same). So rejecting a `#` value would be new behaviour for value flags. The plan says "covered already", which is not accurate.

**Recommendation:** Fix the plan's F5 claim. Whether to reject `#`-prefixed `--profile` values is the security-reviewer's call.

## Breaking-change check

Previously working invocations, and what each does now:

| Invocation | Before | Now | Assessment |
|---|---|---|---|
| `cc-isolated A B` | opened B | exit 2 | Intended narrowing. The fact-check found no legitimate caller. |
| `cc-isolated -- A` | opened `$PWD` (A dropped) | opens A | A semantic change that fixes a bug. A script relying on it would have been opening the wrong repo. |
| `cc-isolated A -- X…` | opened A (X dropped) | exit 2 | Narrowing; matches cc-push. |
| `cc-isolated '#dir'` | opened `#dir` | exit 2; `./#dir` / `-- '#dir'` work | Narrowing with a documented escape. |
| `cc-isolated --bless   # note` / `--list   # note` in default zsh | worked (ws ignored) | exit 2 | **Breaks a previously working doc-copied form** (F1). |
| `cc-isolated --help` or a usage error, with the host-tool check failing | answered first | still answered first (the parse precedes the `HOST_TOOLS_ERR` block) | Consistent with row 71. |

There are no flag removals or renames and no exit-code changes. Every new refusal uses exit 2, as #58 requires.

## What Looks Good

- The rule, the `--` handling and the exit code match cc-push's "one checkout at a time" closely. The post-`--` block is almost line for line cc-push.sh:445-449.
- Every new refusal follows the existing usage-error shape: `ERROR:` on stderr, the full usage on stderr, exit 2. The bats helper `assert_refused_untouched` checks for `EXIT STATUS` in the output and for no devcontainer call or registration.
- The refusals happen during parsing, before the host-tool refusal, which keeps row 71's "usage errors are answered first".
- Values are printed with `%q`, the first escaping of untrusted argv in cc-isolated's error output.
- install.sh's "Next steps" now prints each command on its own line, its note on the line above it, and the misleading "rebuilds" is gone. A test pins both.
- The guide states the shared rule beside cc-push's and documents both `#name` escapes.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Guides and the `--help` header still show `cmd  # note` lines. `--bless`/`--list` copied into zsh used to work and now exit 2 | Inconsistent | `guides/cc-isolated-usage.md:20-35`, `guides/devcontainer-setup.md:47-174`, `cc-isolated.sh:7-17` | High |
| F2 | The `--help` header omits "before `--`" and the `-- '#x'` escape | Minor | `cc-isolated.sh:18-20` | High |
| F3 | Same rule, different wording from cc-push; the `'' -- B` edge differs | Minor | `cc-isolated.sh:757-758` | High |
| F5 | The zsh-note hint prints on two-workspace errors no note can cause | Minor | `cc-isolated.sh:749-755` | High |
| F4 | The `#` refusal exists in cc-isolated only | Informational | `cc-isolated.sh:781-783`, `cc-push.sh:442` | Medium |
| F6 | The helper duplicates `usage_die` under another name; three usage-error styles | Informational | `cc-isolated.sh:749,768-780` | High |
| F7 | `--profile` consumes `#` unchecked (the plan's F5 claim is wrong) | Informational | `cc-isolated.sh:764-772` | High |

## Overall Assessment

The CLI change is consistent with the codebase's conventions. It reuses cc-push's one-target rule and `--` handling, the usage-error shape, exit 2 from decision #58, and row 71's parse-first ordering. No flag, exit code or documented invocation in a script changes. The one previously working consumer path that breaks is a human pasting a noted `--bless`/`--list` line into default zsh. That follows from the guides and the `--help` header keeping the `cmd  # note` format that this branch removed from install.sh (F1). The rest is small: wording and hint placement (F3, F5), the header leaving out `--` (F2), and an asymmetry with cc-push to record (F4). All of it can be fixed in place. None of it shows that the author skipped the existing conventions; the parser is plainly modelled on cc-push.

## Goal-Alignment Note

The goal is to land roadmap Next 3, one workspace per run, as a clean, reviewed branch. The branch delivers the core of it. A second workspace, a `#` word, and extra words after `--` are each refused with exit 2 before any action, and tests cover each form, so the wrong-workspace launch the goal targets is closed. The finding closest to the goal is F1. The hazard named in the PR intent ("a pasted copyable line with a trailing `# note`") was fixed only at install.sh. The guides and the `--help` header still hand users noted lines, which now fail safely with exit 2 instead of launching the wrong workspace. That is safe, but it is not the "copy the command lines only" experience install.sh now gives. F2 and F5 are small text fixes that bring the user-facing text into line with the behaviour. F3, F4, F6 and F7 are follow-ups or plan corrections and need not block the merge.
