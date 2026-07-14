# Hermeticity adapters — adding a language

Each `*.json` here teaches `scripts/hermeticity-lint` one language. Adding a language is normally a data
file; see the honest caveat at the bottom.

The rule never changes: **can a test file, transitively, spawn a network-capable binary?** An adapter only
describes *how that language spells things*.

## Schema

| key | required | meaning |
|---|---|---|
| `language` | ✓ | adapter name (`--lang` selects it) |
| `test_globs` | ✓ | where this language's test files live, relative to `--root` |
| `exclude_globs` | | globs to drop (vendor dirs, virtualenvs) |
| `network_bins` | ✓ | the binaries that constitute "reaching the network" |
| `matcher` | ✓ | `command_position` or `spawn_call` — see below |
| `spawn_tokens` | for `spawn_call` | literal tokens that spawn a process |
| `comment_prefixes` | | full-line comments are blanked before matching, so a binary named in prose never counts |
| `closure` | | how to follow references to other repo-local files |
| `stub_rules` | | what counts as "this binary is stubbed" |
| `optout_patterns` | | what counts as an explicit opt-out |
| `optout_scan_lines` | | how far from the top to look (default 15) |

## The two matchers

**`command_position`** — shell-shaped, where the binary *is* the command. A call site is the binary at line
start, after `;` `&` `|` `(` or `$(`, or as the target of bats `run`. Used by `bash.json`.

**`spawn_call`** — everything else. Finds a `spawn_token`, walks to its matching close paren, and looks for
the binary anywhere in that window. This one proximity model covers every non-shell language:

```
subprocess.run(["curl", ...])      Python
Command::new("curl")               Rust
exec.Command("curl")               Go
child_process.spawn("curl")        TS/JS
```

It deliberately over-approximates (a binary named anywhere in the call window counts, including inside a
`shell=True` string). That is the design: a false positive is annotated away in one line, a false negative
is an incident. The paren walk skips string literals, so an unbalanced `)` inside an argument — `bash -c
"echo :-) ; curl …"` — cannot close the window early and hide the binary behind it.

## `closure` — following the reach

4d39475 was **indirect**: the suite's own text held no call site; a sourced script did. So the closure is
the load-bearing part.

- `resolve: "basename_in_dirs"` — resolves **relative to the referring file first** (what bats and the shell
  actually do: `load helpers` in `test/skills/foo.bats` means `test/skills/helpers.bash`), then falls back to
  the token's basename in `search_dirs` — the fallback exists because a source path is usually built from a
  variable (`source "$BATS_TEST_DIRNAME/../scripts/x.sh"`) and cannot be resolved literally. `extensions` lets
  a suffix-less token resolve (`""` first, so an explicit `foo.sh` matches itself, then `.sh`/`.bash`).
  Shell-shaped.
- `resolve: "module_path"` — an import becomes a path, tried against the repo root, the importing file's
  directory, and `search_dirs`. Python-shaped. It must follow **`from pkg import mod` → `pkg/mod.py`**, not
  just `pkg/__init__.py`: the spawn lives in the imported *name*, and `__init__.py` is usually empty. A
  third-party import resolves to no file and is simply not followed, which is what we want.

`reference_pattern` is matched with `re.MULTILINE`, so `^` means start-of-line. It has to: an import is only
an import at line start, and without the flag `^` would mean start-of-*file* and only a reference on line 1
would ever be followed — a closure that quietly sees nothing.

### Reference, not mention

Enumerating helper directories does not work — the one you forget is the hole. (`test/skills/` was: 20 suites
`load` from it, and the generator inside it holds two live `claude -p`.) Resolve the way the runtime does,
relative to the referring file.

But follow only what the suite could actually *run*: a `load`/`source` directive, a command-position
execution (`run bash "$REPO_ROOT/scripts/x.sh"`), or an assignment whose value is later executed
(`SCRIPT="…/x.sh"` … `run bash "$SCRIPT"` — the house style, so command position alone would miss it).

A filename that merely *appears* — `skip "…run generate-reports.bash first"`, `grep -q 'x.sh'`, `rm "…/y.sh"`
— is a **mention, not a reach**. Following mentions flagged four honest eval suites for a generator they never
invoke, and their only escape would have been a blanket `@network: allowed` they do not deserve. An opt-out
that a correct suite is forced to write is worse than the false positive it silences: it permanently blinds
the gate to that file.

## `stub_rules`

A rule fires when **every** regex in its `all_of` matches. `{bin}` is substituted with the binary name.
Bash's shim is two facts that must co-occur — a file named after the binary is created, *and* a directory is
prepended to `PATH` — which is why `all_of` exists rather than a flat list.

Keep that two-fact shape for every PATH-shim rule. A rule that matches only the `PATH` half accepts things
that stub nothing: `env = dict(PATH=os.environ["PATH"])` merely *reads* `PATH` to build a subprocess
environment, and reading it is not stubbing. Because `stubbed()` is evaluated per-binary over the whole
file, such a rule marks *every* network binary in the file stubbed — a green gate on a suite that really
does spawn `curl`.

`stub_scan_dirs` widens the stub search from the suite's own text to the test helpers it pulls in — a shim
inside `load lib/stub-bins` is a shim that runs. Two guards make that safe, and both were learned by getting
them wrong:

- **Only code that actually runs counts**: a helper's top-level code, plus the bodies of helper functions the
  suite *calls* (transitively). A `stub_claude()` merely **defined** in a shared helper is not a stub — but
  counting it exempted every suite that so much as loaded that helper, including suites that really did spawn
  `claude`.
- **Scope it to the test tree**, and compare *normalized* paths. A `PATH` tweak inside a sourced *product*
  script is not a test stub; an un-normalized `test/../scripts/tool.sh` looks like it lives under `test/` to a
  lexical check, which is exactly how one sneaked through.

If a language has no such analysis yet, leave `stub_scan_dirs` out (Python does). A stub you cannot prove runs
is a stub you must not credit: a false positive costs one line, a false pass costs an incident.

## `command_prefixes` / `shell_wrappers` (the `command_position` matcher)

Command position is not a regex, and three review passes proved it the hard way: each pass tightened a
pattern and opened a new hole (`run ! bash x.sh` not followed, `load "$DIR/x"` not resolved, a `(` inside a
trailing comment read as a call site, and a wrapper-chain pattern that backtracked exponentially — 22
`--k=v` flags on one line took 1.7s, ~30 hung the gate). Those were four faces of one mistake: pattern-matching
a grammar. Shell source is now **tokenized** — quotes, comments, separators, `$( )`, backticks — and every
consumer asks structural questions of the tokens.

- `command_prefixes` — wrapper words to step over when looking for the command: `if`, `while`, `timeout`,
  `env`, `xargs`, `sudo`, and bats' `run` and `!`. This repo's suites are *written* in `run !`, so omitting it
  would blind the gate to its own house idiom.
- `shell_wrappers` — wrappers whose quoted argument is shell *source*, not data: `bash -c "curl …"` and
  `eval "…"` are the shell twin of Python's `shell=True`, and the matcher recurses into them.

The **same list drives the closure**. When the matcher and the resolver disagreed about what command position
means, `run bash x.sh` entered the reach and `run ! bash x.sh` did not — a blind spot shaped exactly like the
difference between them.

## `optout_patterns` are FILE-scoped

`opted_out()` reads the head of the file and exempts the whole file. So only ever accept markers that are
themselves file-level (`pytestmark = pytest.mark.network`, a `//go:build` tag, the `@network: allowed`
comment). Never accept a per-test marker such as a bare `@pytest.mark.network` decorator: it means "this one
test is online", but the lint would read it as "this file is exempt", silently covering every other test in
the module — including ones added long after. That is 014's failure mode.

## Honest caveat: it is data *plus, sometimes, a resolver*

Decision 017's step-4 hypothesis was "adding a language is pure data, zero core edits." Adding Python
**partially falsified** it. The *matcher* generalized exactly as predicted — `spawn_call` will serve Rust,
Go and TS unchanged. The *closure resolver* did not: Python module resolution needed a second resolver in
the core.

Expect the same for the next two:

- **Rust** — follow `mod foo;` and `include!`, but **never** `use` (a `use` names an item already in the
  module tree; it is not a file). Each file in `tests/` is its own crate root.
- **Go** — an `_test.go` file implicitly sees **every** non-test `.go` file in its own directory, with *no
  import statement at all*. The closure seed is the package **directory**, not the file. Also special-case
  `exec.Command(os.Args[0], ...)`, the standard self-re-exec test helper — it is the #1 false positive.
- **TS/JS** — follow relative specifiers and tsconfig `paths`; do **not** follow bare specifiers (importing
  `execa` is itself a spawn signal, not a file to recurse into). Tagged templates hide the binary inside the
  literal: `` $`gh pr list` ``.

If a fourth language needs a *third* resolver, the rules-as-data contract is not paying for itself — see
017's revisit triggers.

## Don't write an adapter for Go

`golangci-lint`'s `depguard` (native `$test` file selector) plus `forbidigo` (`analyze-types: true`) can be
*configured* into this rule with zero new code. Ship a config recipe instead.
