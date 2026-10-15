Commit: a54bb3b0

# Security Review: fix/cc-isolated-one-workspace (cc-isolated takes one workspace per run)

**Scope:** `git diff 5e6e9266..a54bb3b0`: devcontainer-config/cc-isolated.sh (header, `workspace_usage_error`, `two_workspaces`, `main()` parse loop), devcontainer-config/install.sh ("Next steps"), guides/cc-isolated-usage.md, test/cc-isolated-functions.bats
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-one-workspace.md (Stage-1 summary in the shared context); prior art devcontainer-config/cc-push.sh `main()` parse loop
**Probes:** stubbed-devcontainer bats harness built from the suite's own `setup`/`smart_devcontainer_stub`/`one_ws_setup` helpers, run against a scratch copy of devcontainer-config at HEAD and at base 5e6e9266 (`git archive`). Scratch: /home/node/.claude/jobs/00bcf178/tmp/one-ws/sec/. No real cc-isolated, install.sh, docker or devcontainer was run. No background processes were started.

## Trust Boundary Map

```
B1: [pasted/typed argv: copyable lines from install.sh, --help, guides; zsh without interactive_comments passes '# note' words] → [main() parse loop: flags, '\#*' refusal, one-workspace rule, '--' rule] → [action + ws_arg: bless_manifest / register_project / resolve_workspace → devcontainer up]
B2: [argv values echoed back in error messages]  → [printf %q (new paths) | raw echo (pre-existing paths)] → [user's terminal (escape-sequence interpreter)]
B3: [host-tool integrity state (HOST_TOOLS_ERR, computed at load)] → [refusal gate after parsing, line 797] → [launch / probe / register]
B4: [install.sh "Next steps" text (code constant)] → [user copy-paste] → [B1]
```

Input-source classification:

```
S1: argv words (pasted or typed)  — request-time  — UNTRUSTED toward action selection (bless/register/probe),
                                                    workspace selection, and terminal output; the user is the
                                                    author, but a paste carries text the user did not mean as argv
S2: --profile value               — request-time  — UNTRUSTED; validated against egress/*.txt only on --register,
                                                    unused by every other action
S3: install.sh / --help / guide copyable lines — code-constant — trusted content, but each line is an S1 generator:
                                                    a line carrying a trailing note becomes extra argv in zsh
S4: HOST_TOOLS_ERR                — deploy-time (host files) — trusted as a gate signal; computed before main()
```

What enters from outside is argv (S1/S2), shaped by whatever text the user pastes; the diff narrows how argv can select a workspace or an action and moves the "note" class from wrong-workspace-launch to exit 2. Nothing in the diff changes what an accepted action does. The one assumption the diff relies on and does not enforce: that a `#` word only ever reaches the parse loop at the top of a `case` iteration. A `--profile` consumes the next word without inspecting it, so a `#` there skips the guard (Finding 1).

Reproduction of zsh behaviour (executed): `printf 'printf "[%%s]" a # b c\n' | zsh -f -i` prints `[a][#][b][c]`. That confirms the premise: with interactive_comments off, zsh passes the note as words.

## Findings

#### 1. `--profile` consumes a `#` word unchecked, so a note's later words still act as flags (pre-existing; the diff's new comment overclaims)

**Severity:** Medium
**Location:** `devcontainer-config/cc-isolated.sh:770-777` (`--profile` branch), comment at `:781-782`
**Boundary:** B1
**Move:** 11 (enumerate bypasses for every guardrail)
**Confidence:** High for the mechanism (executed). Low likelihood: no shipped copyable line puts a bare `--profile` before a note.

The `\#*` refusal fires only when a `#` word is the subject of a `case` iteration. `--profile` does `profiles="$2"; shift 2` with no inspection, so in `cc-isolated --profile # --bless` the `#` is eaten as the profile value and `--bless` is parsed as a flag. Executed at HEAD: `--profile '#' --bless` → status 0, `Blessed …/manifest.sha256 (8 entries)` printed. `--profile '#' <b>` → status 0, one `devcontainer up` on b. Base 5e6e9266 behaves identically, so this predates the unit and the diff did not introduce it. The diff's new comment at :781-782 claims "a note's later words can never act as flags", which this case refutes. An unintended `--bless` is the high-consequence sink here: it accepts whatever the installed config and host tools currently hold. The `--register` sink stays protected: `--profile '#'` reaching `register_project` exits 1 with `unknown egress profile '#'` and writes nothing (P3, P4). Reach: an rg sweep of the repo, excluding docs/reviews, docs/working and archive, found no copyable line with `--profile` followed by `#` or by end of line. The only path is a hand-typed or hand-edited line, so the threat is accidental rather than adversarial. An attacker-authored paste could write `--bless` outright and gains nothing from this route.

**Recommendation:** Close it in this unit, since the unit's own comment and plan F5 claim it is covered. In the `--profile` branch, add `case "$2" in \#*|-*) workspace_usage_error "$(printf '%q is not a profile name …' "$2")" ;; esac` (exit 2), and add a bats case for `--profile '#' --bless` (assert no bless, i.e. `blessed_hash` unchanged or `manifest.sha256` mtime unchanged). If it is deferred instead, reword the :781-782 comment to "…except after --profile" and queue the fix.

#### 2. Pre-existing error paths still echo raw argv to the terminal while the new paths use `%q`

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:780` (`unknown flag: $1`), `:363` (`resolve_workspace`: `not a directory: $start`) and `:367`
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption)
**Confidence:** High (executed)

The new messages are escape-safe. `two_workspaces`/`workspace_usage_error` print `$'\E]0;PWN\a\E[2J'` and `$'#\E[2J\E]0;x\a'` as inert `%q` text (P14, P15), and a newline shows as `$'x\ny'` (P18). The older siblings in the same parse path print the raw bytes: `--$'\e[2J'x` gives `ERROR: unknown flag: --^[[2Jx`, and `-- $'/nope\e[2J'` gives `ERROR: not a directory: /nope^[[2J` (shown through `cat -v`). The diff's comment ("Values are printed with %q: they are untrusted text going to a terminal") states a rule the file does not yet follow. Not rated higher because the bytes must arrive as argv. A paste goes through zsh's line editor (and bracketed paste) and does not deliver raw ESC bytes, so the user has to write `$'…'` themselves. That does not meet the floor rule's reachable-environment bar.

**Recommendation:** Optional hardening. Route `unknown flag` and `resolve_workspace`'s two echoes through `printf %q`, or file it as a follow-up. Not a blocker.

#### 3. Copyable lines with trailing notes remain in guides/cc-isolated-usage.md; they now fail closed

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:20-35, 215-217, 564, 592, 626`; `devcontainer-config/cc-isolated.sh:7-17` (`--help` header)
**Boundary:** B4 → B1
**Move:** 5 (invert: what does the rule prevent, and what does it leave)
**Confidence:** High for the cc-isolated lines (executed equivalents). Medium for the cc-push lines (traced, not run under zsh).

The diff cleans install.sh only. The guide and the `--help` header still show `cmd   # note` lines. Each cc-isolated form now exits 2 before acting: `<ws> '#' …` (P8, P19), `'#' …` (P12), `--list '#' …` (P10), and `--help` lines exit 0 at `--help` first (P11). The cc-push lines: 215 (`… ~/code/app   # first time: …`) hits cc-push's "one checkout at a time" at `#`. Lines 216 and 217 contain `(`, `:` and an apostrophe in the note, so zsh fails to parse them or waits on PS2. Lines 28-34 contain `[REPO]`, which zsh treats as a glob and rejects with "no matches found". No guide line puts a note right after `cc-push` plus only boolean flags, so no line lets `#` become cc-push's checkout while a later note word sets `--yes` (rg sweep). Residual: cc-push does not refuse `#` words, so `cc-push # --yes` would set `yes=1` and then fail at `find_checkout '#'` unless a `#` directory exists. cc-push is outside this diff.

**Recommendation:** None required for this unit, since the result is fail-closed and the guide text now explains the exit 2. Optionally, a later docs pass can move the notes onto their own lines as install.sh does, and cc-push can adopt the same `\#*` refusal for parity.

## Untested bypass candidates

- **zsh with `EXTENDED_GLOB` set:** a lone `#` is then a glob operator. Not run under a user zsh config. A bad-pattern error (nothing runs) or a literal `#` word (refused) are the only outcomes I could find, so this needs a live zsh check rather than anything in the diff.
- **cc-push `#`-first-positional with a `#` directory present** (Finding 3 residual): outside this diff's files, not probed.

## Endorsement Claims

The `\#*` guard has an open bypass (Finding 1), so per move 11 it gets no endorsement here. The claims below cover the one-workspace and `--` rules, ordering, and escape handling only.

- **Claim:** A second positional workspace, in launch, `--probe-only` and `--register --profile python` modes, exits 2 before any `devcontainer` call or profile write, naming both values.
  **Location:** `devcontainer-config/cc-isolated.sh:784-787, 757-759`
  **Evidence:** executed
  **Verified:** branch bats test "a second workspace is a usage error in every mode…" (DC_LOG empty, both `project_profile`s empty); my probe P9 (`'' <b>` → 2), P3b (`--register a --profile '#' note` → 2).
  **Not verified:** the same forms under a real zsh paste with the installed (symlinked) `~/.local/bin/cc-isolated`.
  **route: code-fact-check**

- **Claim:** After `--`, more than one word, or one word following an earlier workspace, exits 2. A single word after `--` is used as the workspace instead of being dropped for `$PWD`.
  **Location:** `devcontainer-config/cc-isolated.sh:789-795`
  **Evidence:** executed
  **Verified:** branch bats "after --: one workspace…". Probe P20 at HEAD: `--probe-only -- <b>` → 0, `devcontainer up … --workspace-folder <b>`. The same probe at base → 1, `ERROR: <TEST_TMPDIR> is not inside a git repository` (it opened $PWD). P6 `-- '#' note` → 2.
  **Not verified:** interaction with a workspace path that is itself `--`-prefixed after `--` (e.g. `-- --x`), which goes to `resolve_workspace`.
  **route: code-fact-check**

- **Claim:** Usage errors (second workspace, `#` word) are raised before the host-tool refusal, and they exit 2 with no action taken. With host tools tampered, a single valid workspace still gets the exit-1 refusal.
  **Location:** `devcontainer-config/cc-isolated.sh:763-795` vs `:797`
  **Evidence:** executed
  **Verified:** scratch copy with a mismatching `host-tools.sha256`. O0 `<b>` → 1 `ERROR: host-tool check failed — refusing…`. O1 `<a> <b>` → 2 `two workspaces given`. O2 `<a> '#' --bless` → 2 `\# is not a workspace`. The order is benign: both exits precede every action, and `--help` already answered before the gate.
  **Not verified:** that the cc-isolated.sh doing the parsing is itself the blessed copy (it is a boundary-manifest file checked later by `check_manifest`, not by the host-tool gate).

- **Claim:** Values in the two new error messages are printed via `printf %q`, so ESC/OSC/BEL bytes and newlines reach the terminal as inert escaped text.
  **Location:** `devcontainer-config/cc-isolated.sh:749-759, 783`
  **Evidence:** executed
  **Verified:** P14, P15, P18 output shown through `cat -v` contains no raw `^[`.
  **Not verified:** the `usage` text that follows, which comes from the script's own header (code-constant, S3), not from argv.

- **Claim:** install.sh's "Next steps" block prints five command lines, none with a trailing `#`, and no "rebuild" wording.
  **Location:** `devcontainer-config/install.sh:611-625`
  **Evidence:** read-static (plus the branch bats test, which greps the source)
  **Verified:** read lines 609-629. The command lines are `touch ~/.ssh/canary`, `cc-isolated --probe-only <repo>`, `cc-isolated`, `cc-isolated --register <repo> --profile python` and `cc-push --remote <url> <repo>`.
  **Not verified:** the rendered output of a real install.sh run (not run, per rules). The comment at :611 says each note is "on the line below" but the code prints it above (fact-check Incorrect; doc only, not a security issue).

## Primitive sweep

Primitive engaged: untrusted argv printed to a terminal (B2).

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:783` `\#*` message | S1 | `%q` | cleared (P15) |
| `cc-isolated.sh:758` `two_workspaces` | S1 | `%q` | cleared (P14, P18) |
| `cc-isolated.sh:780` `unknown flag: $1` | S1 | none | Finding 2 (pre-existing) |
| `cc-isolated.sh:363` `not a directory: $start` | S1 | none | Finding 2 (pre-existing) |
| `cc-isolated.sh:367` `$start is not inside a git repository` | S1 | none | Finding 2 (pre-existing, same path) |
| `cc-isolated.sh:445-449` `unknown egress profile '$p'` | S2 | none | not separately probed; same class as Finding 2, `--register` only |

Primitive engaged: action selection from argv (bless/register/probe).

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `--bless` case, `:765` | S1 | `\#*` refusal at iteration head | Finding 1: bypassed via `--profile '#'` |
| `--register` case → `register_project` | S1, S2 | `\#*` refusal + profile allowlist (`egress/$p.txt`) | cleared: `'#'` as profile exits 1, no write (P3, P4) |
| `--probe-only` case | S1 | `\#*` refusal | `--profile '#' --probe-only` is the same Finding 1 shape, recreates a container (no config acceptance) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `--profile` eats a `#` word; the note's later words act as flags (`--profile # --bless` blesses). Pre-existing, but the diff's comment claims otherwise | Medium | B1 | `cc-isolated.sh:770-777, 781-782` | High (mechanism); low likelihood |
| 2 | Pre-existing error paths echo raw argv (ESC reaches terminal), unlike the new `%q` paths | Informational | B2 | `cc-isolated.sh:780, 363, 367` | High |
| 3 | Guide and `--help` copyable lines keep trailing notes; they now fail closed (exit 2, or zsh parse/glob error) | Informational | B4→B1 | `guides/cc-isolated-usage.md:20-35, 215-217, 564, 592, 626` | High / Medium |

## Overall Assessment

The change narrows B1 as intended, and I found no copyable line in install.sh, `--help` or the guide that can make the launcher act on an unintended workspace or action. Every such line now exits 2 before any check or action, or is never run because zsh fails to parse it. Usage errors land before the host-tool refusal, which is harmless because neither path acts. The new messages are escape-safe. The one gap is Finding 1. `--profile` swallows the `#` word, so `cc-isolated --profile # --bless` still runs a bless. It predates this unit (base behaves identically), no shipped line triggers it, and `--register` stays protected by the profile allowlist. Still, the unit's own comment and plan F5 claim the class is closed, and the fix is a few lines in the same `case`. It is the single most important thing to address, either fixed in place with a test or the comment narrowed and the fix queued. No architectural problem. No findings within the other code paths read. The endorsement claims tagged `route: code-fact-check` still need execution verification there.

## Goal-Alignment Note

The user goal is to land roadmap Next 3 (one workspace per run) as a clean, reviewed branch. The diff serves it. The wrong-workspace class from rubric A7 is closed for every form the plan names except F5 (`--profile` taking the note's `#`), and F5 is the item that keeps the branch from being "clean" against its own plan. Closing it in this unit costs little and keeps the goal's scope; deferring it is acceptable only if the :781-782 comment and plan F5 are corrected so the branch stops claiming coverage it lacks. Findings 2 and 3 are outside the goal and should not hold the merge.
