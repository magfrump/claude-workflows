# Plan: cc-push accepts a self-referencing `.git/commondir` (Q-093 [1])

**Date:** 2026-09-28 · **Branch:** `q093-cc-push-self-commondir` (from `main` at `dfe4c0d`)
**Read:** Q-093 and Q-084 in `docs/working/questions.md`, Q-091 in the archive,
`devcontainer-config/cc-push.sh` (header, `check_checkout`),
`devcontainer-config/cc-gitdir.sh` (`gitdir_common`, `gitdir_valid`), `test/cc-push.bats`.

## Goal

`check_checkout` refuses any `<checkout>/.git/commondir`. Something (probably
Claude Code's host bwrap sandbox, making a stand-in for a protected path) keeps
writing a 1-byte `commondir` holding `.` into the main checkout. Git reads that
as "the common dir is this gitdir", exactly as when the file is absent. Accept
that file, and refuse every other `commondir` exactly as today.

## What git reads (experiment, git 2.39.5, scratch repo under the session scratchpad)

`printf '<bytes>' > .git/commondir; git rev-parse --git-common-dir`:

| bytes | git's common dir |
|---|---|
| `.` | the gitdir |
| `.\n` | the gitdir |
| `.\r\n`, `.\r`, `.\n\n` | the gitdir (git trims trailing CR/LF) |
| `./`, `.//` | the gitdir (realpath) |
| `.\0`, `.\0/../x` | the gitdir (a C string ends at NUL) |
| absolute path of the gitdir | the gitdir |
| ` .`, `. `, `.\t`, `..`, `.\n.\n` | not a repository (fatal) |
| empty | fatal: failed to read |

`git ls-remote --upload-pack='git-upload-pack --strict' <co>/.git` succeeds with
`.` and fails ("does not appear to be a git repository") with `..`.

This matches `setup.c` `get_common_dir_noenv`: `strbuf_read_file`, trim trailing
`\n`/`\r`, prefix `<gitdir>/` unless absolute, then `strbuf_add_real_path`.

**Accepted set: exactly the bytes `2e` and `2e 0a`** (`.` and `.\n`). The first is
the observed file (1 byte, `.`); the second is the same line as written by
`echo .`, and git reads it identically. Everything else git would also read as
self (`./`, `.\r\n`, `.\0…`, the absolute path) stays refused: nothing observed
writes them, and each extra form is one more parser to get right.

## Design

A helper in `cc-push.sh`, `commondir_is_self <file>`: 0 only when the file is
not a symlink, is a regular file, is 1 or 2 bytes by `stat -c %s`, and its first
two bytes as hex (`head -c 2 | od -An -tx1`, whitespace removed) are `2e` or
`2e0a`. Hex, because bash's `read` drops NUL bytes and `$(…)` strips trailing
newlines: either would make `.\0` or `.\n\n` compare equal to `.`.
`check_checkout` calls it where it now refuses any `commondir`; the refusal text
stays, with a note naming the one accepted form (as shipped: "it can name
another repository … The only one accepted is a regular file holding exactly
`.`, or `.` and a newline"). No git runs in the checkout.
`gitdir_valid` then resolves the common dir to `<g>/.`, i.e. `<g>`: unchanged.

## Pre-mortem: bypass families

Assume the change shipped and a session got cc-push to read another repository
through `commondir`. How?

| # | Family | Covered? | How |
|---|---|---|---|
| B1 | Bytes git reads as elsewhere (`..`, `../../x`, an absolute path) | Covered | Only `2e`/`2e0a` pass; tests for `..` and the absolute path (new), `../../elsewhere` (the existing http-alternates/commondir test) |
| B2 | Bytes git reads as self but a lax parser accepts along with bad ones (`./`, `.//`, `.\r\n`, `.\n\n`) | Covered (refused) | exact hex compare; tests for `./`, ` .` |
| B3 | Whitespace / CRLF / multiple lines | Covered (refused) | size ≤ 2 and exact hex; `.\n.\n` is 4 bytes |
| B4 | NUL tricks (`.\0/../x`; bash `read` dropping NULs) | Covered | size cap + `od` hex, not `read`; git reads `.\0…` as self anyway |
| B5 | Symlinked `commondir` (to a file holding `.` that points elsewhere by being read relative to another dir, or a target swapped later) | Covered | helper refuses `-L` before anything else, independent of the later `find` symlink scan. (git resolves a relative commondir against the gitdir, not the link's directory, so this is defence in depth; the test uses a 1-byte link target so only the `-L` test refuses it, mutation-checked) |
| B6 | `commondir` a directory, FIFO, socket or device (a read blocks) | Covered | `-f` and not `-L` checked before any read; a FIFO is never opened; test with `timeout` |
| B7 | Large file | Covered | `stat` size must be 1 or 2 before reading; the read is `head -c 2` anyway |
| B8 | Unreadable file | Covered | `head` fails → empty hex → refused |
| B9 | Empty file | Covered (refused) | size 0; git dies on it too |
| B10 | Absolute path to the gitdir itself | Covered (refused) | not in the accepted set, kept minimal; test |
| B11 | TOCTOU: file replaced (by a FIFO, or new bytes) between the check and git's read | **Not covered (residual)** | same residual as every other check in `check_checkout`; the running-container refusal (`check_no_container`) is the mitigation, as today. cc-push's own read of the file is bounded (`timeout 5 head -c 2`), so a FIFO swapped in after the type test cannot hang it (review, performance F1) |
| B12 | `commondir` at the checkout ROOT (bare-repo fallback) | Unchanged | `looks_like_gitdir` still refuses a root `commondir` that is a regular file (or a link to one), exactly as before; not relaxed |
| B13 | A self-`commondir` changing what else git reads (`config.worktree`, `worktrees/`) | Covered by existing checks | `.` resolves common dir = gitdir, so git reads the same files as with no `commondir`; `config.worktree` is still include-checked. Verified after review (git 2.39.5, scratch repo with a linked worktree and `extensions.worktreeConfig=true`, `uploadpack.hideRefs` set per worktree): upload-pack --strict's ref advertisement, the `config.worktree` values read and HEAD are identical with commondir absent, `.` and `.\n` |

Retrospective stories considered: (1) the parser used `$(cat)` and accepted
`.\n\n…` or `.\0/../x` → B3/B4, hex compare. (2) a FIFO named `commondir` hung
cc-push because the read ran before a type test → B6. (3) a symlink `commondir`
passed because the helper trusted the later `find` scan's order → B5, the helper
tests `-L` itself.

**Round-1 triggers:** `/pre-mortem`: fired (enforcement file); done inline above,
bypass families enumerated and marked. `/architecture-review`: not triggered
(one module, `devcontainer-config/`, no new public surface).

## Steps

1. `cc-push.sh`: add `commondir_is_self`; use it in `check_checkout`; update the
   header's refusal list. 2. `guides/cc-isolated-usage.md`: note the exception.
3. `test/cc-push.bats`: accept `.` and `.\n` (push succeeds); refuse `..`, `./`,
   ` .`, `.\n\n`, `.\r\n`, `.\0`, `.x`, the gitdir's absolute path, empty, a directory, a FIFO
   (under `timeout`), a symlink to a file holding `.`.
4. `bats test/cc-push.bats`; `scripts/run-tests.sh test/cc-push.bats`.
5. Review-fix loop (`code-review`, security-reviewer key).

Size: well under the ~400-line cap (decision log 62).

**Live check:** Q-084 step 3 rerun on the host without deleting `.git/commondir`.
Commits carry `Live-verified: no`.
