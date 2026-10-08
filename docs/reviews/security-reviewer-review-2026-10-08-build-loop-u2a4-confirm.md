Commit: a3489c4f

# Security review: U2a4 confirming pass on the final-pass fixes (2b6f2f91..a3489c4f)

**User goal:** check that the fixes in 2f9464d3 close the final pass's security F1 (start directory stored as a link), security F2 (quoted mention spanning lines), performance F1 (quadratic prefixes after an unclosed `@"`), and the prompt_bases whole-component fix, without opening a new under-read in the self-merge floor.

Scope: `git diff 2b6f2f91..HEAD -- scripts/ test/ docs/working/`. Every probe below was executed. The fixture scripts are in the session scratchpad (`u2a4-confirm-sec/e2e.sh`, `tm.sh`). The oracle is the installed Claude Code 2.1.293 binary: `Jfn` (the mention reader, `(^|[\s。、？！])@"([^"]+)"` with the `g` flag), its caller `yPr`, and `NPr` (filename parsing).

## What the fixes get right

- **Security F1 is closed for its forms.** `.claude/commands`, `.claude/Skills` and `.claude` stored as links fail the main walk (the new bats case). Probes P4 (`.claude/rules/sub` is a directory link) and P5 (the nested `a/.claude` is a link) also fail the walk. P6 is a link above `.claude` (`a -> real`, where `real/.claude/commands/x.md` exists). That file is listed under its real path and walked with base `real/`, so `real/docs/q.md` and `docs/q.md` both read as imported. That is enough for the floor, because git records the change under the real path.
- **Security F2 is closed for its tested shape.** `@"x⏎/../docs/m.md"` resolves to `docs/m.md`. The CRLF form (`x\r⏎/../…`) works too, and so does a blank line inside the quote. In `put`, the newline drop removes only a resolved path that still contains a newline. Neither walk admits such a path: main_imports fails on a listed name that contains a newline.
- **No carry state leaks between files.** Each file runs its own awk process. The carry can leak from the raw text into the U+FFFD-decoded copy appended after it in the same awk input, but that only over-reads.
- **prompt_bases** splits whole components. `.claude/.claude/` and `.claudex` behave as documented.

## Findings

### F1 (Medium, regression in this diff): a quoted mention with a `#L`/`#fragment` suffix and a space in its name is no longer read

- **Location:** `scripts/lib/dev-cycle-read.sh`, IMPORT_AWK `scan` (the quoted text is emitted only whole), and `names` (prefixes stop at a blank).
- **Oracle:** in 2.1.293, `yPr` maps each `Jfn` mention through `NPr`, `e.match(/^([^#]+)(?:#L(\d+)(?:-(\d+))?)?(?:#[^#]*)?$/)`, and reads `filename` = group 1. So `@"docs/a b.md#L5"` reads `docs/a b.md`.
- **Before the fix (2b6f2f91):** `names(…, q=1)` emitted every prefix of the quoted text. `docs/a b.md` was one of them.
- **Now:** the whole text `docs/a b.md#L5` is emitted. The unquoted run stops at `docs/a`. Neither is the file.
- **Executed (e2e.sh P1):** on main, `.claude/commands/c.md` contains `review @"docs/a b.md#L5" now`, and `docs/a b.md` exists.
  - New lib: `walk main: ok`, `docs/a b.md: -`, `walk tree: ok`, `docs/a b.md: -`, and `floor docs/a b.md` returns 1 (self-mergeable).
  - Old lib: `imported`, and the floor refuses with the IMP reason.
  - `#sec` and `#L2-9` behave the same way.
- **Fix:** in `scan`, when the quoted text `t` holds a `#`, also emit `substr(t, 1, index(t, "#") - 1)`. This over-reads; when NPr's regex fails to match, NPr's filename is the whole text, which is already emitted. Do the same for the joined text in the qopen close arm. Add `@"docs/a b.md#L5"` to the "parser resolves each relative name…" bats case. The comment's grammar claim should also name NPr's suffix stripping.

### F2 (Low): `@"` at the very end of a line is not carried

- **Location:** `scan`, `else if (k == 0 && carry && r != "") qopen = r`. When `r` is empty, nothing is carried, and `qopen != ""` cannot represent an open quote with empty text.
- **Oracle:** `[^"]+` matches the newline, so `@"⏎/../docs/m.md"` gives the group `⏎/../docs/m.md`. The resolved path is `docs/m.md`.
- **Executed:** `import_targets` on `run @"⏎/../docs/m.md" now` printed only `"`. In e2e.sh P2 (a command on main), `docs/m.md: -` and `floor docs/m.md` is self-mergeable.
- **Exploitability:** the shape is contrived: it needs a `..` after the newline component, and the command must already be on main. It is still the exact hole the final-pass F2 fix set out to close.
- **Fix:** carry an explicit flag, for example `qo = 1; qopen = r`, and test `qo` in the main rule instead of `qopen != ""`.

### F3 (Low; untraced whether Claude Code recurses into it): a start-named link to a directory under `.claude/rules/` passes START_LINK

- **Location:** `main_imports`, `[[ ! "/$f" =~ $START_LINK ]] || isstart "$f" || return 1`, and the 120000 read arm.
- **Executed (e2e.sh P3):** on main, `.claude/rules/r.md` is a link to `../../p`, and `p/x.md` holds `see @docs/q.md`. The result is `walk main: ok`, `docs/q.md: -`, and the floor reports it self-mergeable. The read arm treats the link text `p` as an import of a path main stores as a directory, and drops it silently. A link with the same target named `.claude/rules/sub` fails the walk (P4).
- **Exposure:** if Claude Code's rules loader follows a directory link that has an `.md` name, `p/x.md` is a rule and `docs/q.md` is under-read. F1's own rationale applies: the prompts are listed under the target's path, which isstart does not know.
- **Fix:** in the 120000 arm, fail when the resolved `out` is a directory on main (`dir[$out]` set) or a gitlink. Equivalently, exempt a start-named link from START_LINK only when its target is a blob.

### F4 (Low, availability; new in this diff): the multi-line carry is quadratic in time while charged as linear work

- **Location:** the main rule, `qopen = qopen "\n" $0`. mawk (`/usr/bin/mawk` here) copies the growing string on every line.
- **Executed (tm.sh):** an unclosed `@"x`, followed by N lines of 10 bytes each:

  | Lines (N) | Bytes | Time |
  |---|---|---|
  | 40,000 | 400 KB | 1.3 s |
  | 160,000 | 1.6 MB | 28 s |
  | 400,000 | 4.0 MB | 193 s |

  The 4.0 MB case is under capped_read's 4 MiB cap. Its charged work was 3,600,021, against IMPORT_WORK_MAX of 50,000,000. The work bound therefore does not bound time, and each such file costs about 3 minutes with the walk still returning ok.
- **Exposure:** this only stalls the gate; the walk does not under-read. The file has to be on main already, or untracked in the gate checkout.
- **Fix:** collect the carried lines in an array (`qp[++qn] = $0`) and join them once, at the closing quote. Alternatively, charge `length(qopen)` per line, so the existing bound fails the walk instead of stalling it.

### F5 (Low, outside this range: pre-existing since U2a4 i1): a UNI_SPACES character inside a quoted mention is read as a space

- **Location:** `import_targets` passes awk only the sed output, in which every UNI_SPACES character and NUL has become a blank.
- **Oracle:** in `Jfn`, `[^"]+` keeps U+00A0 and the others literally.
- **Executed:** `import_targets` on `run @"docs/a<U+00A0>b.md"` printed `docs/a b.md`, never `docs/a\xc2\xa0b.md`. The old lib behaves the same way.
- **Exposure:** a doc whose name contains an NBSP and that a command mentions in quotes is under-read.
- **Fix:** also feed awk the raw text, or emit quoted runs from text before the sed, for the quoted reader only. Alternatively, record it in known issue A5 as not covered.

## Informational (no change requested without a trace)

- **Comment splicing:** `scan(splice($0), 0)` reads a comment-spliced quote on one line but never carries it. Line 1 `a @<!-- c -->"x`, line 2 `/../docs/h.md"` gives no `docs/h.md` (executed, probe H). This matters only if command expansion strips HTML comments before `Jfn`, which is untraced. If it does, pass `carry` (with a separate qopen) for the spliced copy too.
- **Space trimming:** emit trims a quoted name's leading and trailing spaces. `@" docs/x.md"` and `@"docs/x.md "` never print ` docs/x.md` or `docs/x.md ` (executed, probes D and E). I could not trace whether 2.1.293's `Je` (path expansion after NPr) trims. If it does not, a file with a leading or trailing space is under-read. This was out of reach in this pass: the minified name `Je` is defined in many modules.
