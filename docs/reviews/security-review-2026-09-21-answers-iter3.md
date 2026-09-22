Commit: 31f53e8

# Security Review — answers-2026-09-20, iteration 3 (final confirmation pass)

**Scope:** `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24, b951c4f, 31f53e8). The focus is `hooks/guard-trusted-writes.py` after a577546. Earlier branch commits were read as context only.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter3.md` (merged, k=3). Claim numbers below are "FC n".
**Probe logs:** these are in the scratchpad at `…/scratchpad/sec3/` and are not tracked. The files are `probe.sh.txt` and `probe-out.txt` (fake-HOME layouts A and B, with `CLAUDE_CONFIG_DIR` unset per probe) and `kern.sh.txt` (kernel path resolution compared with `normpath`).

The hook invariant under test says two things:
- **Arm 1:** the hook never returns `ask` on a path that a `permissions.deny` rule covers.
- **Arm 2:** the hook never defers on a protected path that no deny rule covers.

## Trust Boundary Map

```
B1: [tool_input.file_path from a possibly web-tainted agent] → [classify_path(): lexical / normpath / resolve()] → [hook decision: defer | deny | ask]
B2: [hook "defer"]                                           → [Claude Code permissions.deny matcher (unverified semantics, N3)] → [write to global policy file]
B3: [bare-host checkout ~/claude-workflows/*] (moved)        → [symlinks from ~/.claude (README:14,27-30)] → [live policy: global CLAUDE.md, per-file hooks]
B4: [host filesystem case semantics]                         → [Path equality / relative_to (case-sensitive)] → [HARD vs SOFT tier]
B5: [docs/working/* filenames + archive prefix]              → [archive-working-docs.sh prefix regex, [ -e ] check] → [mv into archive/]
B6: [Q-049 paste output ("enforced" / "NOT enforced")]       → [the user's reading of it] → [closure of security finding N3]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | `tool_input.file_path` (Edit/Write/MultiEdit) | request-time | UNTRUSTED for the path-classification and write sinks. A tainted session can pick any spelling. |
| S2 | `CLAUDE_CONFIG_DIR`, `HOME` env | deploy-time (per session) | Trusted for choosing the config dir. An attacker who already controls the env is out of scope. |
| S3 | The filesystem layout: symlinks under `~/.claude`, checkout paths | runtime-mutable (the agent can create symlinks through Bash `ln`, which is A8) | UNTRUSTED toward the "is this protected?" decision |
| S4 | The archive `PREFIX` argument and `si-run-id.txt` | runtime-mutable (the SI loop writes it) | UNTRUSTED toward the path-construction sink. It is validated against `[A-Za-z0-9._-]+`. |
| S5 | Q-049 paste output | runtime | UNTRUSTED as evidence for closing a finding. It cannot tell "enforced" from "never ran" (FC 7). |

The hook sits on B1 and decides whether B2 (the deny matcher) is the only gate. Every finding below comes from one of three sources. In some spellings the hook's idea of which string names a protected file differs from what the OS writes (B3, B4, `..`). In others the hook's defer depends on B2 matcher semantics that no one has verified.

## Findings

#### 1. Case variants of HARD entries fall to SOFT. On a case-insensitive host filesystem they are the protected files, and the result breaks one of the two invariant arms whichever way the matcher folds case

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:124-130,158-168`
**Boundary:** B4, B1→B2
**Move:** 11 (bypass enumeration), 5 (invert the access model)
**Confidence:** Medium. The Linux behaviour was executed. The macOS consequence is inferred and was not run: there is no case-insensitive mount here (FC 12a).
**Legibility-target:** for-author

**Evidence:**
```
        if first == "hooks":
            return True
        if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):
            return True
        if len(rel.parts) == 1 and first == "CLAUDE.md":
            return True
    if cand.name == "CLAUDE.md" and cand.parent == HOME:
```
```
    # Case-folded on purpose: SOFT only ever asks, so over-matching is safe.
```

The probe in layout A (`probe-out.txt`) gave these results. `~/.claude/SETTINGS.JSON` and `~/.claude/Settings.json` both return defer when clean and ask when tainted.

On Linux these are different files, so nothing is exposed. The bare-host guide supports macOS ("README's Linux/macOS setup", `guides/bare-host-hook-wiring.md:7`), and APFS is case-insensitive by default. There, `SETTINGS.JSON` is the real `settings.json`, which holds the hook wiring and the deny list. `resolve()` does not canonicalise case, because `realpath` keeps the spelling it was given. That is [assumed] from CPython and macOS behaviour and was not run here. So `rp` is not in `_HARD_FILE_TARGETS` either.

The outcome depends on how Claude Code's deny matcher treats case on macOS, which could not be tested:
- **If the matcher folds case,** the deny rule covers `SETTINGS.JSON`. A tainted session gets `ask`, and an ask overrides the deny (#39344). That breaks Arm 1. At 2d93589 the lowercased HARD check deferred to the rule, so for this case N1 is a regression.
- **If the matcher is case-sensitive,** no rule covers `SETTINGS.JSON`. A clean session defers with no gate, which breaks Arm 2. This was true at 2d93589 too.

The comment's argument, "SOFT only ever asks, so over-matching is safe", holds only when the SOFT path is never deny-covered. On a case-insensitive filesystem that premise fails.

**Recommendation:** Classify by file identity, not by spelling. If `rp` exists and `os.path.samefile(rp, t)` holds for any HARD target, or `rp`'s parent is the same file as `CONFIG_DIR`/`HOME` and `name.casefold()` matches a HARD name, return `"hard-resolved"` (deny). A deny is safe under either matcher behaviour. The identity check also covers hard links, whose creation is A8.

#### 2. Bare-host per-file hook links: the live hook scripts, edited at their checkout path, get no gate even when the session is tainted. The newly denied `global-instructions/CLAUDE.md` is the same class of file

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:95-102,154-155`
**Boundary:** B3
**Move:** 12 (sweep sibling cases of the resolve tier), 5
**Confidence:** High. The mechanism was probed in layout B.
**Legibility-target:** for-author

**Evidence:**
```
_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
...
_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}
```
```
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
```
The README install (`README.md:27-30`) links the logging and routing hooks into a real `~/.claude/hooks/` one file at a time: `ln -s ~/claude-workflows/hooks/$h ~/.claude/hooks/$h`. `dd-routing-reminder.sh` is wired as `bash {{CLAUDE_DIR}}/hooks/dd-routing-reminder.sh` (`hooks/wiring.json:43`).

Layout B probe results (`probe-out.txt`):
```
deny    clean    B/h/claude-workflows/global-instructions/CLAUDE.md
deny    tainted  B/h/claude-workflows/global-instructions/CLAUDE.md
defer   clean    B/h/claude-workflows/hooks/log-usage.sh
defer   tainted  B/h/claude-workflows/hooks/log-usage.sh
```

`_HARD_DIR_TARGETS` holds only the resolved hooks directory. On a bare host that is the real `~/.claude/hooks`, so a checkout hook resolves to itself and misses every HARD test. It also misses SOFT, because its path has no `.claude` and no `skills` segment, so it gets "none". Editing that file changes code that runs on every prompt, outside the sandbox. No deny rule names the checkout path. That breaks Arm 2, and a tainted session does not even get an ask.

The gap predates this diff: `_HARD_DIR_TARGETS` is unchanged. a577546, however, defines the "resolved" tier as covering "a resolve() onto the target of a symlinked global entry", and in this layout that description covers only CLAUDE.md. The two classes are now handled inconsistently: editing the checkout's global CLAUDE.md is denied (a577546, FC 15), while editing the checkout's live hooks is not gated at all.

**Recommendation:** Decide the bare-host policy once and apply it to both. There are two options:
- At import, add `_safe_resolve(e)` for each `e` in `CONFIG_DIR/hooks/*` to `_HARD_FILE_TARGETS`. That gives deny, which matches CLAUDE.md.
- If editing hooks from the checkout is intended in bare-host development, route those targets to SOFT so they at least ask when tainted. Record the exception in the docstring.

#### 3. `normpath` folds `..` lexically, but the kernel resolves `..` after following a symlinked component. A path that is "covered" by the hook's reading can land on a different file (N3-adjacent; a new mechanism)

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:138-148`
**Boundary:** B1→B2, B3
**Move:** 11
**Confidence:** Low. The disagreement between the kernel and the hook was executed. Whether it is exploitable depends on the unverified N3 matcher semantics.
**Legibility-target:** for-author

**Evidence:**
```
    # pathlib already collapses `//` and `/./`; normpath also folds `..` lexically,
    # so `~/.claude/x/../CLAUDE.md` is seen as `~/.claude/CLAUDE.md` (R4).
    norm = Path(os.path.normpath(str(p)))
...
    for cand in (p, norm):
        if _is_hard(cand, [CONFIG_DIR]):
            return "hard"
```
The bare-host layout B was probed with `kern.sh.txt` and `probe.sh.txt`. For `~/.claude/skills/../CLAUDE.md`:
- The kernel resolves it to `~/claude-workflows/CLAUDE.md`.
- `normpath` gives `~/.claude/CLAUDE.md`.
- The hook defers on it, clean and tainted.
- The kernel target addressed directly, `~/claude-workflows/CLAUDE.md`, gets `ask` when tainted.

The hook returns "hard" and defers before it looks at `rp`, so its answer rests on B2 folding `..` exactly the way `normpath` does. There are two cases:
- **If the matcher folds `..` lexically,** this is a harmless false deny.
- **If it does not (the N3 residue),** a tainted session creates the project CLAUDE.md for the checkout with no ask. It only has to spell the path through `skills/..`.

N3 is already disclosed and is not re-raised here. What is new is that the docstring's "the path AS GIVEN … names a HARD entry" can be wrong about *which file is written*, not only about the matcher.

**Recommendation:** Never defer on a spelling that contains `..`. Classify it by `rp`. If either `rp` or `norm` is HARD, deny. That closes the `..` half of N3 without waiting for Q-049. (See Overall Assessment for the broader version.)

#### 4. The Q-049 paste can close a live security finding on a run that never happened

**Severity:** Medium
**Location:** `docs/working/questions.md` (Q-049, "The paste" and "What I do with it")
**Boundary:** B6
**Move:** 3 (check the error path)
**Confidence:** High. FC 7 is unanimous, and r2 executed the paste against a failing stand-in.
**Legibility-target:** for-author

**Evidence:**
```
  (cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json >/dev/null 2>&1)
  [ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" || echo "$form-slash rule: enforced"
```
The excerpt ends inside the `for` loop, which closes with `done`.
```
- **What I do with it:** if single-slash is enforced, N3 is closed as a non-issue.
```

Any failure prints "enforced". That covers a logged-out CLI, an outside-cwd permission prompt that `-p` cannot answer (the target sits in a second `mktemp -d`, outside `$d`), and a crash. The test uses project settings, while N3 concerns user settings (FC 7). Closing N3 on that output would leave the whole deferred "hard" tier resting on an unverified matcher. It would also withdraw the hardening the entry itself names ("have the hook return `deny` itself for HARD paths").

The paste itself is safe to run. It writes only to fresh temp dirs and grants `Write` only in a temp project's settings.

**Recommendation:** Add a control run with the allow rule and no deny rule, which must print "NOT enforced". Put the target inside `$d`. Keep the JSON output and gate on `is_error`/`num_turns`, per the user's memory note on headless runs. Better still, take the security outcome out of the paste's hands: have the hook deny every HARD tier itself (see Overall Assessment). Q-049 then becomes informational.

#### 5. The hard-resolved deny message sends the agent to a spelling that cannot be edited "with review"

**Severity:** Low
**Location:** `hooks/guard-trusted-writes.py:282-285`
**Boundary:** B1→B2
**Move:** 3
**Confidence:** High (FC 19, unanimous)
**Legibility-target:** for-author

**Evidence:**
```
            emit("deny", f"This write reaches a protected policy file ({Path(fp).name}: "
                         ".claude hooks/settings or global CLAUDE.md) through a symlink or "
                         "resolved path that permissions.deny does not name. Edit it at its "
                         "~/.claude path, with review.")
```
The `~/.claude` spelling is exactly what `permissions.deny` blocks, and a deny cannot be approved. Under the N3 failure case, that same spelling is deferred and has no gate at all. The message is the only guidance an honest agent gets, and it points either at a dead end or at the path that depends on the unverified matcher.

This does not change what an injected agent can do on its own, which is why it is rated Low.

**Recommendation:** Reword to: "Protected policy file. A human must edit it outside Claude Code."

#### 6. Bare-host deny of the checkout's `global-instructions/CLAUDE.md` (FC 15 escalation): it strengthens security, but it is an undisclosed behaviour change

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:95,154-155`; `README.md:14`
**Boundary:** B3
**Move:** 5
**Confidence:** High (FC 15, executed by r2)
**Legibility-target:** for-author

**Evidence:**
```
_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
```
`README.md:14`: `ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md`

At 2d93589 this path deferred. That was a live global instruction file with no deny rule, which breaks Arm 2, so a tainted session could rewrite it through the checkout spelling with no gate. The new deny closes that hole. It also matches the Bash tier, which already denies any write that names both `CLAUDE.md` and `global-instructions`.

This is not a security regression. The cost falls on the workflow: bare-host sessions working on this repo can no longer Edit its global instructions, and nothing in the docstring, the commit or the README says so. This finding interacts with Finding 2, which covers the same class of file handled the opposite way.

**Recommendation:** Keep the deny. Say so in the docstring's "resolved" examples and in the bare-host guide, and name the human-edit route.

#### 7. Archive: overwriting a dangling symlink (FC 24) and `.`/`..` prefixes. Both were tested and cleared

**Severity:** Informational
**Location:** `scripts/archive-working-docs.sh:52,133,138-147`
**Boundary:** B5
**Move:** 4 (TOCTOU), 2
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  dest="$ARCHIVE_DIR/${PREFIX}-${name}"
...
  if [ -e "$dest" ]; then
...
    mv -- "$f" "$dest"
```
I tested this in the scratchpad, `sec3/mvt`, with a dangling link at `$dest`. `[ -e ]` was false, and `mv` replaced the link *entry* through rename(2). The link's target directory stayed empty, so there was no write-through, and no data was lost because a dangling link holds none.

A prefix of `.` or `..` only produces the file names `.-name` and `..-name` inside `archive/`, so it cannot traverse (see also FC 23). The check-then-`mv` race needs a concurrent local writer in a single-user tree. Nothing needs to change beyond FC 24's wording note.

## Untested bypass candidates

- **A case-insensitive filesystem** (Finding 1): this needs a macOS APFS host or a `/mnt/c` config dir. Neither is available in the sandbox.
- **Claude Code's deny-matcher handling** of case, `..`, `//` and MultiEdit (Findings 1 and 3; the N3 residue): there is no matcher in the sandbox. These are tracked as Q-049.
- **Unicode-normalisation variants on macOS**, such as NFD and NFC spellings of the same name. APFS treats them as the same file, and the hook compares strings. The HARD names are ASCII, so this is unlikely to matter. It was not tested, and the same kind of identity check as in Finding 1 would cover it.

The following were tested and cleared (executed; `probe-out.txt`, and FC 13 for the rest):
- `//`-prefixed absolute paths are denied through `rp`.
- A symlinked HOME, a symlinked `CLAUDE_CONFIG_DIR`, a relative `CLAUDE_CONFIG_DIR`, and a project `.claude` symlinked to `~/.claude` all return hard-resolved → deny (FC 13).
- The devcontainer `hooks/../CLAUDE.md` spelling lands on the read-only `/opt` payload.
- No probed HARD path returned `ask`.

## Endorsement Claims

- **Claim:** No file-tool path that the hook classifies as HARD reaches the `ask` branch. The `"hard"` return defers, `"hard-resolved"` emits deny, and both come before the SOFT check.
  **Location:** `hooks/guard-trusted-writes.py:146-155,275-286`
  **Evidence:** executed (FC 13 invariant sweep; `probe-out.txt`)
  **Verified:** `classify_path` returns before the SOFT loop on any HARD match. `main()` handles both HARD tiers before `ask`. The probes returned no `ask` on any HARD spelling.
  **Not verified:** Whether spellings the hook does *not* classify as HARD (case variants on a case-insensitive filesystem, Finding 1) are covered by a deny rule.
  **route: code-fact-check**
- **Claim:** A path that is HARD only after `resolve()` returns deny whether or not the session is tainted.
  **Location:** `hooks/guard-trusted-writes.py:151-155,279-285`
  **Evidence:** executed (FC 13; layout B `global-instructions/CLAUDE.md` → deny/deny)
  **Verified:** the payload by its real path, a symlinked config dir, and the checkout CLAUDE.md.
  **Not verified:** Resolve targets of per-file links inside `CONFIG_DIR/hooks/` (Finding 2).
  **route: code-fact-check**
- **Claim:** An explicit archive prefix outside `[A-Za-z0-9._-]+` is rejected before any path is built.
  **Location:** `scripts/archive-working-docs.sh:52-55`
  **Evidence:** executed (FC 23)
  **Verified:** the regex check exits 1 before `ARCHIVE_DIR` is used.
  **Not verified:** Whether `archive/` itself is a symlink (the directory is gitignored). This predates the diff.

The hook guardrail has untested bypass candidates, listed above, so no categorical endorsement of it is made.

## Primitive sweep

Primitive: path classification feeding a write decision (resolve, normpath and relative_to on an untrusted path)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/guard-trusted-writes.py:137` `expanduser` | S1 | none needed (classification only) | cleared |
| `hooks/guard-trusted-writes.py:140` `normpath` → "hard" at `:146-148` | S1 | none | Finding 3 |
| `hooks/guard-trusted-writes.py:141,151-155` `resolve()` → hard-resolved | S1, S3 | target sets `:95-102` | Finding 2 (per-file link targets missing) |
| `hooks/guard-trusted-writes.py:121-131` `_is_hard` string compare | S1, S2 | case-sensitive equality | Finding 1 |
| `hooks/guard-trusted-writes.py:97` `CONFIG_DIR.glob("settings*.json")` | S2, S3 | try/except | cleared: import-time and read-only; a new settings file is still caught lexically |

Primitive: file move into a constructed path

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/archive-working-docs.sh:147` `mv -- "$f" "$dest"` | S4 (+ filenames) | prefix regex `:52`, `[ -e ]` `:138` | Finding 7 (cleared) |

The other scripts in the diff (`si-functions.sh`, `si-morning-summary.sh`, `questions.sh`) change only parsing, exit codes and comments. None adds a write primitive (checked with `git diff 2d93589..HEAD -- scripts/`, grepping for mv/cp/redirect).

## Iteration-2 🟡 status (security view)

| Item | Status | Basis |
|---|---|---|
| N1 | resolved for its stated cases; residue opened as Findings 1–2 | The case-fold was removed and resolve-only paths now deny (FC 12b, 12c, 13; 144/144 hook tests, which I re-ran). New residue: case-insensitive filesystems (F1) and per-file link targets (F2). The root cause the rubric named, a HARD set copied by hand into four places with no contract test, is unchanged. |
| N4 | resolved | FC 27, 31a (fails before the fix, passes after) |
| N5 | still-open | The rewording still overclaims: an in-repo `docs -> .git` link is written through (FC 29b) |
| N6 | still-open (minor) | Two errors were fixed. The description still omits the single-token HARD_FRAG denies and the `CLAUDE_CONFIG_DIR` token (FC 10), so the user would answer Q-048 underestimating the over-block. |
| N7 | resolved | FC 4 |
| N8 | resolved | FC 30 |
| N9 | resolved | FC 25, 26, 28. The `\x1e` pass-through is a residual note only. |
| N10 | resolved | FC 16, 5 |
| A6 remainder | resolved | The prefix is validated (FC 23), and the no-overwrite behaviour holds apart from the benign dangling-link case (F7). The regex copies are Deferred, and there are 4, not 3 (FC 3); the settled row's count is factually low. |
| A12 remainder | resolved (via N4) | FC 27 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Case variants → SOFT; on case-insensitive filesystems this breaks Arm 1 or Arm 2 | Medium | B4 | `hooks/guard-trusted-writes.py:124-130,158` | Medium |
| 2 | Checkout per-file hook links get no gate, even tainted; handled opposite to CLAUDE.md | Medium | B3 | `hooks/guard-trusted-writes.py:95-102,154` | High |
| 3 | `normpath` `..` ≠ kernel `..` after a symlink; "covered" defer can land elsewhere | Medium | B1→B2, B3 | `hooks/guard-trusted-writes.py:138-148` | Low |
| 4 | Q-049 paste reports "enforced" on any failure and would close N3 | Medium | B6 | `docs/working/questions.md` Q-049 | High |
| 5 | Deny message advises an impossible or ungated route | Low | B1→B2 | `hooks/guard-trusted-writes.py:282-285` | High |
| 6 | Bare-host deny of checkout global CLAUDE.md: positive but undisclosed | Informational | B3 | `hooks/guard-trusted-writes.py:95` | High |
| 7 | Archive dangling-link / `..` prefix: cleared | Informational | B5 | `scripts/archive-working-docs.sh:133-147` | High |

## Overall Assessment

a577546 does what N1 asked on Linux. No HARD spelling reaches `ask`, and every path that is HARD only after resolve() is now denied instead of deferred, which also closes a real bare-host hole (Finding 6). The remaining exposure is architectural and has one root.

The hook still *defers* on the "covered" tier. That makes the tier's safety depend on two things. One is the hook predicting, string for string, what Claude Code's unverified deny matcher will match: case (F1), `..` (F3), and `//`/MultiEdit (N3). The other is a fact-finding paste that cannot fail closed (F4).

**The most important fix is to have the hook return `deny` for the `"hard"` tier as well.** It then decides the Edit/Write/MultiEdit outcome itself, which is the direction Q-049's own "What I do" already suggests. A hook deny cannot be overridden by an ask or an allow, and it is redundant with, never weaker than, the rule. That one change makes Arm 1 hold whatever the matcher does. Together with an identity-based HARD test (F1) and per-file link targets (F2), it also closes Arm 2.

The cost: a user who deliberately removes a deny rule to let Claude edit settings would also have to change the hook. That is a policy choice for the user, and it is worth a `you: judgment` question.

No findings are Critical or High. Endorsement claims are pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): A security critique saved to /workspace/docs/reviews/security-review-2026-09-21-answers-iter3.md with `Commit: 31f53e8` on the first line, structured per the security-reviewer skill, every finding carrying Evidence and Legibility-target, plus the iteration-2 status table and a Goal-Alignment Note.
- Answered:
  - I probed the repo hook with fake-HOME devcontainer-like and README bare-host layouts, with `CLAUDE_CONFIG_DIR` unset per probe and a scratch taint dir.
  - I re-ran `bats test/hooks/`: 144 ok, 0 not ok.
  - I actioned all four escalations addressed to security:
    - FC 15 → F6, plus the related F2.
    - FC 7 → F4.
    - FC 12a → F1.
    - FC 24 → F7, tested and cleared.
  - Two further bypass mechanisms were found and executed: per-file hook link targets (F2) and the `..`-after-symlink kernel mismatch (F3).
  - The iteration-2 status table is included.
- Out of scope:
  - Settled items A7, A8, N2, N3/Q-049 and Q-048 were not re-raised. F3 and F4 are presented as new mechanisms next to N3, not as a re-raise of it.
  - Claude Code's real deny-matcher semantics were not assessed; there is no egress or matcher in the sandbox.
  - The Bash tier was not assessed; it is N2/A8.
- Escalate:
  - (1) F1 needs a macOS/APFS host check, or should be closed by adopting the identity check without one.
  - (2) Whether the hook should deny the covered "hard" tier itself is a policy decision for the user (`you: judgment`). It would subsume F1, F3, F4 and N3.
  - (3) F2's policy (deny or SOFT for checkout hook scripts on a bare host) is the user's call. It must be made consistently with F6.
