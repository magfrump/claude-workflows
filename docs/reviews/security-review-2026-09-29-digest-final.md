Commit: 3aee138

# Security Review — feat/dev-cycle-digest (final pass)

**Scope:** `git diff main...HEAD` — `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, commit message
**Date:** 2026-09-29
**Based on:** pass-1 security finding (option-like default branch → `git log --output=`), commit 89a3d3b

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified by code-fact-check. The claims this review
> relies on were checked by executing the script in throwaway repos under the scratchpad.

## Trust Boundary Map

```
B1: [remote repo: branch names, origin/HEAD symref] → [candidate loop: `-*` skip + rev-parse refs/heads/$c^{commit}] → [git argv as a hash]
B2: [repo working tree: file names, symlinks]       → [fixed globs + `-f`]                                   → [grep/awk/git reads]
B3: [repo content: record text, log rows, commit subjects, roadmap, questions.md] → [awk/grep extraction, no escaping] → [stdout digest read by the agent / a terminal]
B4: [CLI args --since / --sample]                   → [regex checks]                                         → [git --since, shuf -n]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | origin/HEAD target, local branch names | request-time (anyone who controls the remote) | UNTRUSTED for git argv; UNTRUSTED for display |
| S2 | file names/symlinks under `docs/` | runtime-mutable (any committer) | UNTRUSTED for path reads; globs fix the path shape, not the link target |
| S3 | record, log, roadmap, questions.md text; commit subjects | runtime-mutable (any committer) | UNTRUSTED for display and for the agent (header says "data, not instructions"); never reaches exec |
| S4 | `--since`, `--sample`, `DEV_CYCLE_TODAY`, `$HOME` | invoker-controlled | trusted (same principal as the caller) |
| S5 | cycle-record filename date | runtime-mutable (any committer) | shape-checked by glob and regex; UNTRUSTED for window semantics |

What enters from outside is the repo itself (B1–B3). The only exec-class sinks are `git` argv and
`bash "$QS"`; everything else flows to stdout. The diff assumes that output is inert text, which holds
for the shell. It does not hold for the output's structure or for terminal control sequences (Findings 1–2).

## Findings

#### 1. Repo text can forge digest structure

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:122`, `:138`, `:171`, `:195`
**Boundary:** B3
**Move:** 2 (implicit sanitization assumption)
**Confidence:** High (executed)

The trigger and roadmap extractors stop only at `^## `, so a record's Revisit-triggers section can emit
`### docs/decisions/999-fake.md (last changed …)` or `# Dev-cycle digest — …`, and those lines print as
though the script wrote them. I confirmed this by execution. The questions.sh stderr is also printed
inside a ``` fence it can close. The consumer is an agent that decides fired/not-fired from this text,
so a committer can plant fake "entries". The header line (22–23) is the only mitigation. The impact is
bounded: anyone who can commit can already edit the real triggers.

**Recommendation:** Optional. Indent or prefix extracted lines (e.g. `sed 's/^/> /'`) so repo text is visibly quoted and cannot start a heading. Otherwise accept it as-is. Not merge-blocking.

#### 2. Control characters from commit subjects and records reach the terminal raw

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:95-100` (also 122, 138, 195)
**Boundary:** B3
**Move:** 7 (serialization boundary)
**Confidence:** High (executed)

`git log --format=%s` passes ESC/BEL through. A merge subject carrying `ESC]52;c;…BEL` (OSC 52 clipboard
write) was printed verbatim. So were title-set sequences. When a human runs the digest in a terminal that
honours OSC 52, a committer can write to their clipboard. Through the Bash tool it is inert.

**Recommendation:** Optional. Pipe output through `tr -d '\000-\010\013-\037\177'` (or `cat -v`) at the print points. Not merge-blocking.

#### 3. Symlinked `docs/` files are followed out of the repo

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:114-122`, `:192-195`
**Boundary:** B2
**Move:** 1
**Confidence:** High (executed)

`-f` follows symlinks. A committed `docs/roadmap.md` → `/some/outside/file` printed that file's lines
after `## Next` (probe: `TOPSECRET=hunter2`). The target must contain the matching heading, and the
output goes only to the invoking user, who can already read the file. The risk is an agent copying the
text into a committed cycle record. That takes an unusual target file, so this is not a real exfil path.

**Recommendation:** None required. If wanted, add `[[ -L "$f" ]] && continue` next to the existing `-f` checks.

#### 4. A future-dated cycle record silently moves every trigger to "carried forward"

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:71-85`, `:105`, `:132`
**Boundary:** B3 / S5
**Move:** 5 (invert the model)
**Confidence:** Medium (read-static; not executed)

`cycle-9999-12-31.md` satisfies both the glob and the regex, so it becomes SINCE. After that, no record
counts as changed and no log row counts as dated in the window, so everything is listed by name only.
This is integrity rather than confidentiality, and a committer could simply delete triggers instead.

**Recommendation:** Optional: ignore records dated after `$TODAY`.

## Option-name fix: verification (move 11)

The fix has two layers. First, `[[ "$c" == -* ]] && continue`. Second, and load-bearing,
`rev-parse --verify "refs/heads/$c^{commit}"`: that argument always starts with `refs/`, so it cannot
parse as an option. After this point only the full hash `$MAIN_SHA` reaches git. `$MAIN` is display-only.

Bypass candidates, tested:

| Input | Result |
|---|---|
| Remote HEAD → `--output=<path>`, clone checks it out, no local `main` | Candidate skipped. Current branch also starts with `-`, so it is skipped. Exit 1 "Could not resolve", no file created (executed) |
| Same remote with a local `main` created | Uses `main`. `$MAIN_SHA` is a hash (executed) |
| Branches `-p`, `--exec=touch` present on the remote | Never reach argv. The globs name no branch (executed) |
| origin/HEAD symref to a nonexistent local branch | rev-parse fails, falls through to main/master (read-static) |
| Names with spaces, globs, `^`, `~`, `:`, `..` | Forbidden by git's ref-name rules. Would fail `--verify` anyway (read-static) |
| Detached HEAD with no main/master, or empty repo | `cur` is empty or HEAD is unborn, `MAIN_SHA` is empty, exit 1 (read-static) |
| Option-like current branch with no main | Skipped. Fails closed (executed, row 1) |

Other git argv from repo data: decision file paths come after `--` and start with `docs/`. SINCE is
regex-checked and cannot start with `-`. The fix is complete. Note that the `-*` skip also refuses
option-like *current* branches, even though that path only passes `HEAD`. That costs availability
(the digest fails on such a repo) and nothing in safety. No change needed.

Untested bypass candidates: none for this guard.

## Primitive sweep

Primitive: process exec / git argv
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:59` rev-parse `refs/heads/$c^{commit}` | S1 | `refs/` prefix, `-*` skip | cleared (tested) |
| `:66` rev-parse HEAD | S1 (name only gates) | literal `HEAD` | cleared |
| `:95`, `:97` log/rev-list `$MAIN_SHA` | S1 → hash | hash-only | cleared (executed) |
| `:118`, `:121` log `-- "$f"` | S2 | `--`, `docs/` prefix | cleared |
| `:193` log `-- docs/roadmap.md` | literal | — | cleared |
| `:157` `bash "$QS" open` | S4 (`SCRIPT_DIR`/`$HOME`), not the repo when installed | — | cleared: same trust as dev-cycle.sh itself; questions.md is parsed by awk as data |
| `:184` shuf `--random-source=<(yes "$seed")` | S4 date hash | — | cleared |

Primitive: file read (path construction)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:72` cycle glob | S5 | digit glob | cleared, see Finding 4 |
| `:114-122` decision glob | S2 | `-f` | Finding 3 (symlink) |
| `:127-142` log.md | S2 | `-f` | cleared: text only, `$d` only in `[[ < ]]` |
| `:192-195` roadmap | S2 | `-f` | Finding 3 |

Shell injection check (executed): a log row containing `$(touch …)` and backticks was printed literally,
and nothing was created. Repo text reaches only here-strings, `[[ ]]` and awk data, never `eval`.

## Endorsement Claims

- **Claim:** After line 61, no repo-derived branch name is passed to git as an argument; only `$MAIN_SHA` (a full hash) is.
  **Location:** `scripts/dev-cycle.sh:52-69, 95, 97`
  **Evidence:** executed
  **Verified:** Hostile remote (`--output=`, `-p`, `--exec=`) cloned and digest run; no file created, clean exit 1 or correct digest.
  **Not verified:** Behaviour under a user `~/.gitconfig` alias or `log.*` config (outside the diff).
  **route: code-fact-check**
- **Claim:** In the paths tested, repo text in log rows reached stdout without being evaluated by the shell.
  **Location:** `scripts/dev-cycle.sh:128-142`
  **Evidence:** executed
  **Verified:** `$(…)` and backtick payload in a log row printed literally.
  **Not verified:** The questions.sh `open` parser's handling of hostile entries (a separate script, unchanged here).
- **Claim:** The questions.sh temp file is created with `mktemp` and removed by an EXIT trap. The header's "writes nothing" is accurate apart from this temp file.
  **Location:** `scripts/dev-cycle.sh:156`
  **Evidence:** read-static
  **Verified:** Lines 156-171 read.
  **Not verified:** Removal when the process is killed by SIGKILL.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Repo text can forge digest structure | Low | B3 | `:122,138,171,195` | High |
| 2 | Raw control chars (OSC 52) to terminal | Low | B3 | `:95-100` | High |
| 3 | Symlinked docs files followed | Informational | B2 | `:114,192` | High |
| 4 | Future-dated cycle record carries all triggers | Informational | B3/S5 | `:71-85` | Medium |

## Overall Assessment

The pass-1 High is fixed completely. The load-bearing part is the `refs/heads/` prefix plus passing only
the hash. Every hostile-name probe either failed closed or resolved correctly, and no git call takes a
repo-derived argument without either a `--` separator or a hash. Untrusted repo content can only print:
no probe got code execution or a file write. What remains is output-integrity hardening (quoting
extracted text, stripping control characters). None of it blocks merge. Verdict: safe to merge on
security grounds. The load-bearing endorsement is executed. The other claims have their `Not verified`
hop named.

## Goal-Alignment Note
- **Answered:** Checked the option-name fix against 7 bypass shapes (3 executed). Swept every git and exec call site. Probed injection, symlinks, structure forgery and escape sequences in throwaway repos. No Must-Fix-class security issue.
- **Out of scope:** The 13-test mutation check and the carry-forward boundary-date checks from the brief's "Particularly check" list are correctness work, left to the code-review/fact-check critics. Finding 4 was not executed.
- **Escalate:** None.
