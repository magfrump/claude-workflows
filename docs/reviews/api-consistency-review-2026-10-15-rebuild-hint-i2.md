Commit: 980a9db4

# API Consistency Review — fix/rebuild-hint-recreate (iteration 2)

**Scope:** `git diff cb56299c..980a9db4` (devcontainer-config/cc-isolated.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats), excluding docs/reviews; cb56299c is context only
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint-i2.md (17 Verified, 3 Mostly accurate); iteration 1: docs/reviews/api-consistency-review-2026-10-15-rebuild-hint.md

This review covers the public surface a user reads and copies: the `--help` header (printed by `usage()` at cc-isolated.sh:733-735), the `rebuild_hint` output, the unverified-config NOTE, the `--bless` "Next:" line, and the matching passages in guides/cc-isolated-usage.md and guides/devcontainer-setup.md.

## Iteration-1 findings: status

| i1 # | Finding | Status at 980a9db4 | Evidence |
|---|---|---|---|
| F1 | NOTE / `--help` header / guide :955 said a plain launch rebuilds | **Resolved** | NOTE :881-885 "the container is recreated if it was built / from another config"; header :60-63 "recreates the container if it was built from another config … (--probe-only always recreates)"; guide :955 "The launch recreates the container if it was built from another config, then verifies". All three now state the same condition in nearly the same words, and they match the rebuild_hint comment at :561-564. |
| F2 | `--help` said `(re)build` for `--probe-only` | **Resolved** | :13 `# recreate WS's container from the blessed config, run the`; guide :25 `# RECREATE REPO's container from the blessed config, run the`. Same verb and object. The case and placeholder (WS vs REPO) differed before this diff too. |
| F3 | `--bless` Next: line said "rebuilds" | **Resolved** | :317 `# recreates from it and probes as node`. This is terser than suggested ("recreates its container from it"), but it uses the right verb. The commit body calls this the `--list` line. It is in `bless_manifest`, as the fact-check also notes. |
| F4 | Guide :841 "always rebuilds first" | **Resolved** | :841-842 "it always recreates / the container first". |
| F5 | init-firewall two-line form vs `&&` | Unchanged (Informational, no action). See new Finding 1, which concerns its trailing comments, not the `&&`. | — |
| F6 | Hint during `--probe-only` repeats the run | Deferred as C4 (per the rubric and the commit Notes). | — |
| F7 | Bats test name | **Resolved** | `@test "--probe-only always recreates before probing"`. The other image-"rebuild" uses stay, as accepted. |

## Baseline Conventions

- **Copyable hint lines in launcher output.** The established shape is a lead-in sentence ending in a colon, then the command indented by 4 spaces (cc-isolated.sh) or 9 spaces (init-firewall.sh). There are two sub-conventions for explaining a command:
  - *Command alone on its line:* `resolve_workspace`'s `    cc-isolated /path/to/repo` (cc-isolated.sh:364), the by-hand block in `rebuild_hint` (:572-573), and now the rebuild_hint recipe (:567).
  - *Trailing `# ...` comment:* init-firewall.sh:349-350 and the `--bless` Next: line (cc-isolated.sh:317). Every guide code block uses this form (e.g. guides/cc-isolated-usage.md:20-30, devcontainer-setup.md:114). In a guide the comment is plainly documentation, not shell input.
- **Parenthetical explanation.** Wording in parentheses already explains recovery steps: "Recreate it (the ~/.claude volume and your repo are not affected):" (cc-isolated.sh:923), init-firewall.sh:348, and the guides' "`cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`" (cc-isolated-usage.md:957, devcontainer-setup.md:399-400).
- **Vocabulary.** "recreate" means the container and "rebuild" means the image. Iteration 1 established this and this commit completes it.
- **Argument parsing.** `main()` keeps the last positional (`*) ws_arg="$1"`, :757). `resolve_workspace` rejects a non-directory with `ERROR: not a directory:` (:357-359).

## Name-Pattern Audit

This commit adds no new public names: no flags, functions, env vars, exit codes or output prefixes. It adds one bats test name. The audit below therefore covers each changed or added user-facing *phrase*.

| New phrase | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `    cc-isolated --probe-only WS && cc-isolated WS` (alone on line 1) | copyable hint | `    cc-isolated /path/to/repo`; by-hand block lines | `devcontainer-config/cc-isolated.sh:364,572-573` | Consistent with the command-alone sub-convention; inconsistent with the trailing-comment hints at :317 and init-firewall.sh:349-350 (Finding 1) |
| `      (the supported path: recreates the container from the blessed config, re-probes, then launches)` | hint explanation | "(recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`" | `guides/cc-isolated-usage.md:957`, `guides/devcontainer-setup.md:399-400` | Consistent: near-verbatim match to the guides' parenthetical |
| `recreate WS's container from the blessed config` | `--help` line | `RECREATE REPO's container from the blessed config` | `guides/cc-isolated-usage.md:25` | Consistent |
| `recreates the container if it was built from another config` (header, NOTE, guide :955) | condition phrase | rebuild_hint comment "recreates only when the baked config hash differs" | `devcontainer-config/cc-isolated.sh:561-564` | Consistent: same condition, in the user's terms |
| `# recreates from it and probes as node` | Next: line | `# recreates it from the blessed config, re-probes` | `devcontainer-config/init-firewall.sh:349` | Consistent verb |
| `always recreates the container first` | guide prose | "This always recreates the container from the blessed config" | `guides/devcontainer-setup.md:309` | Consistent |
| test `--probe-only exits non-zero and starts no session when the probe fails` | bats test name | `--probe-only always recreates before probing`, `a launch on a matching, verified container does not rebuild` | `test/cc-isolated-functions.bats` | Consistent: subject first, then the property (private) |

## Findings

#### 1. The new command-alone layout is not applied to the other two copyable hints, including one printed in the same failing run

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:349-350`, `devcontainer-config/cc-isolated.sh:317` (contrast with `devcontainer-config/cc-isolated.sh:565-568`)
**Move:** 7 (asymmetry) / 2 (layout convention)
**Confidence:** High
**Legibility-target:** a host user on interactive zsh copying a recovery or Next: command from launcher output

Precedent: command alone on its line, with no trailing comment, used in `devcontainer-config/cc-isolated.sh:364` (`    cc-isolated /path/to/repo`) and `devcontainer-config/cc-isolated.sh:567-568` (this commit)

Evidence (the reason this commit gives, cc-isolated.sh:565-566):
> `# The explanation is on its own line, not a trailing \`# ...\`: interactive zsh`
> `# without interactivecomments would pass those words to step 2 as arguments.`

Evidence (still trailing):
> `echo "         cc-isolated <repo>                 # then start the session" >&2` (init-firewall.sh:350)
> `echo "  Next: cc-isolated --probe-only <repo>   # recreates from it and probes as node"` (cc-isolated.sh:317)

In the fail-closed state, `main()` runs `devcontainer exec … sudo /usr/local/bin/init-firewall.sh` (:920). That script's EXIT trap prints its two-line hint with trailing comments, and then the launcher's `ERROR:` block prints `rebuild_hint` in the new layout. So one run shows the same recipe in two layouts. The commit's own rationale, given at :565-566, applies to both remaining copies. Because `main()` keeps the last positional, a pasted `cc-isolated ~/code/api # then start the session` would run `ws_arg=session`, and `… # recreates from it and probes as node` would run `ws_arg=node`. Both copies carry a `<repo>` placeholder that the user must replace first (in zsh, an unreplaced `<repo>` is a redirect and fails), and `resolve_workspace` rejects a non-directory with `ERROR: not a directory:` (:357-359). The realistic outcome is therefore an error, not a retarget, unless the current directory happens to contain a git repo named `session` or `node`. The fact-check's "overstates the retarget" verdict on the commit body applies here too. Hence Minor.

**Recommendation:** Pick one layout for launcher-printed commands and write it down in one comment. The cheapest fix is :317 (`echo "  Next: cc-isolated --probe-only <repo>"` plus an indented "(recreates its container from it and probes as node)" line). It is in cc-isolated.sh, which this unit already re-blesses. init-firewall.sh is also manifest-hashed and already changed on this branch (cb56299c), so moving its two comments costs no extra bless. If the author prefers to leave init-firewall alone, record a Defer.

#### 2. Under `--probe-only` the NOTE states only the conditional recreate

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:880-886`
**Move:** 3 (consumer contract: documentation accuracy per mode)
**Confidence:** High
**Legibility-target:** a user running `cc-isolated --probe-only <repo>` on an unverified config

Evidence:
> `echo "      This run is that verification: the container is recreated if it was built"`
> `echo "      from another config, and the self-probe must pass (including the node-run"`

The NOTE prints before the `action` branch (:889), so `--probe-only` also shows it, and that path then recreates unconditionally (:892). The header paragraph covers this with "(--probe-only always recreates)" and the NOTE does not. Nothing in the NOTE is false, since a container from another config is indeed recreated. It simply understates what the run is about to do. No consumer is misled into a wrong action.

**Recommendation:** None needed. If the NOTE is touched again, a mode-aware clause (for example `[ "$action" = probe ] && echo "always recreated"`) would line it up with the header.

#### 3. The explanation line shares the by-hand continuation's indent and parses as shell if pasted with the command

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:567-573`
**Move:** 7 (asymmetry within one output block)
**Confidence:** Medium
**Legibility-target:** a user selecting the hint block with the mouse

Evidence:
> `echo "      (the supported path: recreates the container from the blessed config, re-probes, then launches)" >&2`
> `echo "      devcontainer up --remove-existing-container$(printf ' %q' "$@")" >&2`

Both lines use a 6-space indent. In the by-hand form, 6 spaces marks a continuation of the `\`-terminated line above. Under the recipe it marks an explanation. If a user pastes lines 1 and 2 together, the shell runs the session first and then, after it exits, runs `(the …)` as a subshell, which fails with a harmless "command not found: the". The parentheses read clearly as prose, and the wording matches the guides, so this is only a note.

**Recommendation:** None required. If Finding 1 leads to a written layout rule, it could say that explanation lines start with `(` and continuation lines end the previous line with `\`, which already holds.

#### 4. The `--help` line for `--probe-only` is now the widest line in the usage block

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:13`
**Move:** 1 (baseline: `--help` formatting)
**Confidence:** High
**Legibility-target:** a user reading `cc-isolated --help` in a terminal

Evidence:
> `#   cc-isolated --probe-only [WS]        # recreate WS's container from the blessed config, run the`

This line is 99 characters. The other usage lines are 52-94 (the next widest is :12 at 94), and `usage()` prints it with only the `# ` stripped. It wraps on a narrower terminal than its neighbours do. The wording itself is correct.

**Recommendation:** Optionally move "run the" down to :14 ("…from the blessed config," / "run the boundary self-probe, record it verified live").

#### 5. "rebuilding it." still follows a NOTE that now says "recreated" (carry-over from i1 F7)

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:903`, `guides/cc-isolated-usage.md:956`
**Move:** 2
**Confidence:** High
**Legibility-target:** maintainers deciding the end of the vocabulary sweep

Evidence:
> `echo "Blessed config changed since this container was built — rebuilding it."`

When the hashes mismatch, one launch prints the NOTE ("recreated if it was built from another config") and then this line ("rebuilding it"). Here the image *is* rebuilt, because the baked build arg changed, and a guide row and a test match the line. The commit Notes keep it on purpose. It was accepted in iteration 1 and is recorded here only so the next pass does not rediscover it.

**Recommendation:** None.

## What Looks Good

- All five absorbed iteration-1 findings are fixed in place, in the files the unit already touched, and each fix is pinned by a test that fails on the old text (fact-check R2: both rewritten tests fail against cb56299c's script).
- The header, the NOTE and guide :955 now state the plain-launch condition in the same words ("recreates the container if it was built from another config"). The fail-closed launch test asserts that the old promise is gone in the same run where the new hint appears.
- The two-line recipe follows the guides closely: same command, same order, and a parenthetical whose wording matches cc-isolated-usage.md:957 and devcontainer-setup.md:399-400. Pinning line 1 to exactly the command (`[ "$(… head -1)" = "    cc-isolated --probe-only $ws && cc-isolated $ws" ]`) makes the layout a tested contract.
- The new `--probe-only` failure test checks the property that the hint's `&&` depends on: non-zero exit, a forced recreate, no `claude`, and no receipt. The fact-check's mutant run (R5) confirms that it catches a swallowed probe failure.
- No flag, exit code, positional handling or by-hand assignment block changed (fact-check R6: no non-comment, non-echo lines in the script diff). Callers that script the launcher are unaffected.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Command-alone layout not applied to init-firewall's hint (same run) or the `--bless` Next: line; both still end in `# ...` | Minor | `init-firewall.sh:349-350`, `cc-isolated.sh:317` | High |
| 2 | NOTE under `--probe-only` states only the conditional recreate | Informational | `cc-isolated.sh:880-886` | High |
| 3 | Explanation line shares the continuation indent; harmless if pasted | Informational | `cc-isolated.sh:567-573` | Medium |
| 4 | `--help` `--probe-only` line is 99 cols, widest in the block | Informational | `cc-isolated.sh:13` | High |
| 5 | "rebuilding it." after a "recreated" NOTE (accepted carry-over) | Informational | `cc-isolated.sh:903` | High |

## Overall Assessment

The commit resolves iteration 1's F1-F4 and F7. The `--help` header, the NOTE, the `--bless` Next: line and both guides now agree with each other and with the hint on "recreate" and on when a plain launch recreates. Nothing is Breaking or Inconsistent. The one Minor finding comes from the fix itself. The new rule (no trailing `# ...` on a copyable launcher line, for zsh's sake) is applied only to `rebuild_hint`. The two other copyable lines keep the old form, and one of them, init-firewall's hint, prints in the same fail-closed run as the new layout. In practice the outcome is an `ERROR: not a directory` rather than a wrong launch, because both lines carry a `<repo>` placeholder. The fix is two small edits in manifest-hashed files the branch already changes, or an explicit Defer. Findings 2-5 need no action.

## Goal-Alignment Note

The goal is that a user whose firewall failed closed is sent to a recovery that works and is not told, anywhere, that a plain launch will recover them. The diff meets that goal. The NOTE no longer promises a recreate the launch skips, the `--help` and guide copies agree, and the recipe line is now safe to paste whole in interactive zsh. Finding 1 is the remaining edge. In that same failure run, the in-container hint still uses the trailing-comment shape that this commit's own comment calls unsafe. It does not reintroduce the original misdirection (both of its steps are correct) and fails to an error, so it does not block landing. C4 (F6) and the cached-CC-layer refresh (security i2 #2) remain out of scope as deferred.
