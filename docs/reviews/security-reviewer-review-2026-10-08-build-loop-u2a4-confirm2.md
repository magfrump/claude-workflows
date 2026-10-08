Commit: a9894f29

**User goal:** confirm that 185e92f1 closes the confirming pass's F1-F4 in the self-merge floor's import walk (`scripts/lib/dev-cycle-read.sh`), and that it adds no new under-read and no new failure where the walk should succeed.

# Security review: U2a4 second confirming pass on 185e92f1 (a3489c4f..185e92f1)

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

The scope is `git diff a3489c4f..185e92f1`: IMPORT_AWK's `emit`/`scan`/`quoted`/main rule, and main_imports' START_LINK loop and 120000 arm. The oracle is the installed Claude Code 2.1.293 binary. Probes are under the session scratchpad `u2a4-cp2-sec/` (`p.sh` is the parser driver, `mi.sh` builds a fixture repo per case, `w.sh` measures the work bound). They ran with LC_ALL=C under bash 5.2.15, and every one ran in the foreground, so no process was left running.

## The four fixes close their holes

- **F1 is closed.** Reading NPr in the binary (`e.match(/^([^#]+)(?:#L(\d+)(?:-(\d+))?)?(?:#[^#]*)?$/)`, with `filename = r ?? e` and the whole text when nothing matches) shows that the filename is always one of two things: the text before the first `#`, or the whole text. `quoted()` emits both, trimmed and untrimmed. Executed results:
  - `@"docs/a b.md#L5#sec"` gives `docs/a b.md`.
  - `@"docs/a b.md#x#y"` gives the whole text and `docs/a b.md`. NPr itself reads the whole text here, because its regex fails.
  - `@"#docs/a.md"` gives the whole text, which is what NPr reads, since `[^#]+` needs one character.
  - `@"my dir#x/a b.md#L5"` gives the whole text, which is NPr's reading.
  - A multi-line `@"x⏎/../docs/a b.md#L5"` gives `docs/a b.md`.
- **F2 is closed.** `@"` at the end of a line followed by `/../docs/e.md"` is read (bats test 77, and probe 5).
  - When one line closes a quote and opens another (`/../docs/a b.md" and @"y`), both names are read. The qo arm runs before `scan`, so a `"` that closes the old quote and the `@"` that opens the new one are each handled.
  - `@"x⏎/../docs/p q.md"@"y⏎/../docs/r s.md"` reads both names.
- **F3 is closed.** Each of the following makes the main walk fail (executed, `mi.sh`):
  - a link to a directory (`docs/l.md -> sub`);
  - a link to `..`-relative `../docs`;
  - a link to `.`;
  - a start link whose target is itself a link to a directory (`chain`);
  - a link through a directory link (`docs/l.md -> dl/f.md`, with `dl -> sub`). main_checkout refuses this case.
  - A gitlink start is covered by test 77.

  The following stay ok:
  - the common `CLAUDE.md -> AGENTS.md` link, which reads `docs/r.md` and `agents.md`;
  - `.claude/rules/` links with odd names (`a]b[*].md`, and `$(x) \`y\`.md`).
- **F4 is closed.** A quote left open is charged per copy and fails the bound (test 78). The cost of that is C1 below.
- **Subscripts:** `${ent[${links[i]}]}` was checked with keys `a]b`, `*`, `@`, `x[1]`, `a b`, `]`, `[`, `a\b`, `$(…)` and a backticked command. Each key looked up its own value, `*` did not alias other keys, and nothing was evaluated (`sub.sh`). The subscript is expanded once, after parsing.
- **Index alignment:** `parts` comes from `lower_all "${links[@]}"` through `nul_list`, which keeps NUL-separated order. Its count is now checked against `links`, and names holding a newline were already refused, so `parts[i]` and `links[i]` align.
- **`-d "$out"` and the working directory:** every caller passes need_root, which exits unless `ROOT_REAL == $(pwd -P)`. The relative `-d` test is therefore relative to the root, as the existing `-L "$p"` test already is.
- **`keep` with `~/`:**
  - `@"~/a b.md "` gives `h/a b.md` and `h/a b.md␠`.
  - `@" ~/c d.md"` gives `h/c d.md`, from the trimmed copy, and the untrimmed copy as a relative name. That is an over-read only.
  - `@"~/e f.md#L3 "` gives `h/e f.md`.
- **Walks:** both walks are ok on the worktree (1.5 s) and on /workspace's main checkout (2.7 s), using the command in the brief.
- **Tests:** build-loop-check passes 79/79.

## Findings

### C1 (Low, availability; introduced by 185e92f1): charging each copy of qopen fails a mid-size file that has one unclosed `@"`

- **Location:** IMPORT_AWK's main rule, `work += length($0) + length(qopen)`.
- **Executed (`w.sh`):** the file is `see @"x`, then N lines of 80 bytes with no `"`, and the full 50M bound applies.

  | Lines (N) | Bytes | Charged work | Result |
  |---|---|---|---|
  | 500 | 40 KB | 9,895,044 | ok |
  | 1,000 | 80 KB | 39,539,794 | ok |
  | 1,100 | 88 KB | 47,838,744 | ok |
  | 1,200 | 96 KB | over the bound | rc=1 |

  Before 185e92f1, these files passed in well under a second.
- **Exposure:**
  - One stray unclosed `@"` (a typo, or a code sample), followed by about 96 KB with no double quote anywhere, fails the walk, and the floor then refuses every self-merge.
  - The bound is per walk and shared by all files, so a 40 KB file of this kind spends 20% of every walk's budget.
  - This fails closed: it is availability, not an under-read. No file in this repo or in /workspace triggers it today.
- **Fix:** take the confirming pass's other F4 option.
  - Collect the carried lines in an array (`qp[++qn] = $0`) and join them once, at the closing quote. Charge that join's length once.
  - Charge each line linearly.
  - Time and charge both become linear, and test 78's 20,000-line case still fails the bound only if its bytes exceed it. Re-check test 78's expectation after the change.
  - If the current charge stays, record its threshold of about 90 KB in IMPORT_WORK_MAX's note.

### C2 (Informational; pre-existing, only partly addressed by 185e92f1): when the raw scan opens a quote, the spliced variant is never carried, and a continuation line is never spliced

- **Location:** the main rule, `scan(splice($0), !qo)`, and the qo arm, which reads the raw `$0` only.
- **Executed (`p.sh`):**
  - Line 1 `@"docs/<!-- a/b -->x`, line 2 `/../e f.md"` gives `docs/<!-- a/e f.md` only. The spliced reading, `docs/e f.md`, is never read.
  - Line 1 `@"x`, line 2 `<!-- " -->/../docs/m n.md"`: the raw `"` inside the comment closes the quote, so `docs/m n.md` is never read.
- **Exposure:** this matters only if Claude Code strips HTML comments from the text before `Jfn` runs.
  - In 2.1.293, the comment stripper `pwt` is called only for the memory index.
  - `hPr`/`gPr` pass the raw input to `Jfn`.
  - It is untraced whether command expansion strips comments.
  - 185e92f1's spliced carry is therefore an over-read, and this residue is the same untraced case.
- **Fix, if a trace shows splicing:** keep a second quote state (`qo2`/`qopen2`) for the spliced copy. Feed it the spliced continuation lines and always carry it, independent of `qo`.

### C3 (Informational; introduced by 185e92f1): the main walk's directory test reads the checkout

- **Location:** the 120000 arm, `! -d "$out"`.
- **Executed (`mi.sh checkoutdir`):** on main, `docs/l.md -> r2.md` and `docs/r2.md` is a file. A checkout that holds `docs/r2.md` as a directory fails the main walk.
- **Exposure:** this fails closed, and the checkout state it depends on is unusual (main and the checkout disagree on whether a path is a file or a directory). No change is requested. A comment noting that `-d` reads the checkout, which is deliberate and which `-L` already does, would help a later reader.

## Process note

The /workspace walk ran as `cd /workspace && bash -c '…'`. It was a read-only `git ls-tree` / `cat-file` / `ls-files` walk, and nothing in /workspace was written. No tracked file was modified apart from this report.
