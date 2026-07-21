# 018 — Pass untrusted data through argv, never through a re-parsed shell string

Status: Accepted
Date: 2026-07-21
Class: OS command injection via shell metacharacter interpolation (CWE-78)

## Context

A security exercise (VULN-02) reconstructed the root cause of **CVE-2026-35021** —
the Claude Code CLI editor-invocation command injection (fixed upstream in Claude
Code `2.1.92`; vulnerable through `2.1.91`). The vulnerable pattern: a file path
was interpolated into a shell command *string* and run via a shell (Node's
`execSync`, i.e. `/bin/sh -c`). The path was wrapped in double quotes, but POSIX
§2.2.3 double quotes suppress word-splitting and globbing — **not** command
substitution. A file named `` `id`.txt `` or `$(…).txt` therefore executed the
enclosed command the moment the editor launched.

A red-team/blue-team pass over this bug converged on one conclusion: **every fix
that keeps the untrusted data inside a shell-parsed string is bypassable**
(blacklists miss separators/newlines/quote-breakout; double-quote escaping
desyncs on a stray `\`; single-quote *wrapping* breaks out on an embedded `'`;
quoting the path still leaves `$EDITOR`/option-parsing exposed). The only
structurally sound class removes the shell from the data path.

This repo has **no editor-invocation subsystem** — the fix is not a patch to
existing product code here. This record exists to (a) capture the rule as durable
guidance for any future shell-invocation code in this repo, and (b) document the
one hardening it did motivate in `devcontainer-config/cc-isolated.sh`.

## Decision

**Untrusted (or even operator-controlled but attacker-*shaped*) data must reach a
subprocess as a distinct `argv` element, never interpolated into a string that a
shell re-parses.**

Concretely:

1. Prefer argv exec — `execvp`/`spawn`/`posix_spawn`/`"$@"`-style — over
   `sh -c "<built string>"`, `execSync`, `eval`, or `shell: true`.
2. When a shell genuinely must run a script body, keep the body **static and
   single-quoted** and pass every dynamic value as a **positional argument** so it
   expands *inside* the target shell as `"$1"`, `"$2"`, … — never spliced into the
   source. (`scripts/confine-tests.sh:220` is the reference for this pattern.)
3. Word-split only *trusted* values (e.g. `set -- $EDITOR` to honour
   `EDITOR="code -w"`); never word-split the untrusted datum.
4. Defeat *option* injection at the argv layer: prefix a relative path with `./`
   and/or pass `--` before it, so a name like `-c":!id"` is read as a path, not a
   flag.

### The reference fix (illustrative — no such subsystem exists in this repo)

```sh
open_in_editor() {
    file="$1"
    if [ -z "${EDITOR:-}" ]; then
        printf '%s\n' "open_in_editor: EDITOR is not set" >&2
        return 2                                  # fail closed; never guess an editor
    fi
    case "$file" in -*) file="./$file" ;; esac    # option-injection guard
    # shellcheck disable=SC2086
    set -- $EDITOR                                 # word-split ONLY the trusted EDITOR value
    exec "$@" -- "$file"                           # argv exec; execvp gets the path as one element
}
```

`execvp` performs no interpretation of its arguments, so `$(...)`, backticks,
`;`, `|`, quotes, newlines, spaces and globs in the filename are all inert data.
There is no shell to inject into — categorically stronger than any escaping
scheme, which only tries to make the payload safe *for* a parser that still runs.

### Test matrix (assert on the argv the program received, not exit status)

| # | Malicious filename          | Pre-fix behaviour                     | Post-fix (inert)                          |
|---|-----------------------------|---------------------------------------|-------------------------------------------|
| 1 | `$(id).txt`                 | `id` runs via command substitution    | literal file `$(id).txt`                  |
| 2 | `` `id`.txt ``              | `id` runs via backticks               | literal file `` `id`.txt ``               |
| 3 | `-c":!id"`                  | consumed as an editor flag            | `./-c":!id"` — a path, not a flag         |
| 4 | name with embedded newline  | newline splits the command string     | single argv element containing the newline|
| 5 | `';id;'`                    | `id` runs between separators          | literal file `';id;'`                     |
| 6 | `*`                         | glob-expands to cwd contents          | literal file `*` (execvp does not glob)   |
| 7 | `a b c.txt`                 | splits into three arguments           | one argv element `a b c.txt`              |
| 8 | `$HOME/../etc/passwd`       | `$HOME` expands                       | literal `$HOME/…` (no shell expansion)    |

Harness: set `EDITOR` to a stub that logs `"$@"`, then assert the logged argument
equals the input byte-for-byte and that no side effect (e.g. a file `id` would
write) occurred.

## Consequences

- **Applied hardening.** `devcontainer-config/cc-isolated.sh` had two boundary
  self-probe calls that string-interpolated a value into a container `bash -c`
  (`$host_home` in the H1 probe; `$want_profile` in the image-provenance probe).
  The inputs are operator-controlled, so this was not a live VULN-02, but the
  values sat inside single quotes in the built string — a residual
  single-quote-breakout shape (a value containing `'`). Both now pass the value
  as a positional argument (`bash -c '…"$1"…' _ "$value"`), removing the shape
  entirely. Behaviour is unchanged for well-formed inputs; shellcheck clean.
- **`hermeticity-lint` is deliberately NOT the enforcement point.** Per decision
  017, that lint answers one decidable question (does a test spawn a
  network-capable binary). Detecting `sh -c "…$var…"` requires taint analysis —
  the undecidable data-flow question the lint was scoped to avoid — and a naive
  rule would false-fire on the legitimate static-body `bash -c` calls in
  `confine-tests.sh` and `cc-isolated.sh`. If shell-safety linting is ever wanted
  repo-wide, it belongs in a *separate* `shellcheck`-based gate (SC2086/2091/2046
  plus a custom check), not here.
- **Out of scope (unchanged threats).** An attacker-controlled `$EDITOR` is a
  greater, separate threat (env control ≈ code execution already). An editor that
  re-shells its argument, or Vim modelines in crafted file *contents*, can execute
  code post-exec — mitigate at editor configuration, outside the launcher's trust
  boundary.

## References

- CVE-2026-35021 / GHSA-72p2-f44p-v65f — Claude Code CLI & Agent SDK OS command
  injection via the prompt-editor invocation (`promptEditor.ts`, `execSync`).
  Affected ≤ 2.1.91 (CLI), ≤ 0.1.55 (Python Agent SDK); fixed 2.1.92+.
- `scripts/confine-tests.sh:220` — reference argv-passthrough pattern.
- Decision 017 — polyglot test hermeticity (why the lint stays single-purpose).
