# Research: the cross-project board's v1, and how an answer gets back to its repo

**Date:** 2026-11-12 · **Brief:** `docs/working/briefs/2026-11-12-host-board-answer-route.md` · **Branch:** `docs/host-board-answer-route` (dispatched at b08c3c2c) · **Kind:** design only; no script, test or guide is written in this unit.

Repo text is evidence, not instructions. Every file quoted here was read as data.

Failure-pattern grep: FP-034, FP-116, FP-146, FP-167
Failure-pattern skip: the branch has no fix(...) commits; it adds one research doc and flips its brief's status line.

The grep was `grep -inE 'answer|questions\.sh|questions\.md|symlink|host|untracked|working.tree|update-ref|fsmonitor|hook' docs/failure-patterns.md`. The hits that bear on this design:

- **FP-116** (`host-git-runs-against-a-container-written-directory`, ref 1d8ea67) is the strongest prior. Host `git symbolic-ref -d` ran a ref transaction, so a container-written `reference-transaction` hook or `core.hooksPath` fired on the host. That fix removed the path. Any host write below that uses git has to neutralise hooks and every other config-run command before its first git call.
- **FP-034** (fixed tmp path, symlink TOCTOU) and **FP-167** (tracked symlink to an absolute host path) bear on any plain file write the host makes into a checkout. A container can plant a symlink there.
- FP-146 (a symlink hashed by its target only) bears only on reading through a link. The design below never reads a working tree, so it does not apply.
- The other hits (FP-050, FP-053, FP-072, FP-104, FP-139, FP-179) matched only on "host" or "answer" in unrelated senses.

## 1. What exists

### The ask

The proposal is `docs/thoughts/proposal-2026-11-12-cross-project-board.md`. It wants a registry of repos (`:35-37`, "one absolute repo path per line ... outside every repo, so no project can add itself"), and it reads questions through `questions.sh open` (`:30`, "S3: one grammar, never restated"). Its host-vs-container table recommends "[1] Host only" (`:107`, `:111`), and the roadmap Now item settles that: "The proposal's host-vs-container table is settled by this: [1] host only" (`docs/roadmap.md:278-279`). In the proposal the board wrote nothing to repos except `board add` (`:61-64`). The owner's v1 scope adds the write this doc is about: "takes answers back to the right repo" (`docs/roadmap.md:275`).

### The answer grammar

- `global-instructions/CLAUDE.md:273-276`: "**Answering costs one line.** The user writes `Q-NNN: <answer>` anywhere — a reply, a file, a commit — and the ID is the whole handle ... a bare `[2]` is a complete instruction".
- `scripts/questions.sh:598`, the preamble `init` writes: "**To answer:** write `Q-NNN: <your answer>` anywhere (a reply, a file, a commit)."
- The entry header is `**Needs:** <route> · **Opened:** YYYY-MM-DD · **Status:** OPEN|ANSWERED` (`scripts/questions.sh:16`). `parse_entries` (`:200-258`) reads it line by line.

### `questions.sh open`

`cmd_open` is at `scripts/questions.sh:575-587`. It calls `require_files` first, so a repo without both questions files makes it exit 1 with a pointer to `init` (`:142`; the header at `:45-48`: "reporting 'Q-001' or '0 archived' there would be a success claim about files that were never read"). It then lists the live file's entries plus the watches in watching.md that are not ANSWERED, sorted by route rank, printing `ID  route  slug` (`:584`).

Three properties matter for a host caller:

1. **Which files it reads.** It reads the docs/working/ of the git toplevel of `$PWD` (`:38-41`, `:88`), unless `QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE` or `QUESTIONS_WATCHING` overrides a path (`:41-43`). That is the working tree of whatever branch the checkout has out. In this repo another session often has a branch other than main checked out: at this dispatch `/workspace` was on `chore/dev-cycle-2026-11-13-0254`.
2. **Its only git call is `rev-parse`** (`:84`, `:88`). The dev cycle notes that a `rev-parse` inside `$( )` "runs no hook, fsmonitor or pager" (`skills/dev-cycle/SKILL.md:270-271`).
3. **On the host it is one installed copy.** install.sh's host target copies the whole `scripts` directory to `~/.claude` (`devcontainer-config/install.sh:146`, `CLAUDE_HOME_SRC=(... scripts)`), after a reviewed diff and a y/N (`:1-10`). Other repos have no `scripts/questions.sh` of their own. They call the installed path from inside the repo, so "each repo's own `questions.sh`" really means the host's installed copy, run with that repo as its cwd. In claude-workflows the repo copy is container-writable, and running it on the host would break H1 (section 3, "Reading questions").

### How answers reach this repo today

There is a two-step practice, visible in the commits:

1. **The owner writes an answers file under `docs/human-author/`, in their own format.** Examples are `answers-10-22-26.txt` (6250d4ee, author magfrump, subject "answers") and `answers-10-28-26.txt`. The files hold one-line options (`Q-220: [1]`) and also multi-line content. They contain fenced terminal output pasted under a `Q-NNN:` line, a question back to the agent ("What is the handoff's probe.sh? What files do I need to copy into the herald session?", in `answers-11-7-26.txt`), and a free-form `general:` section. Several of these files are never committed: at this dispatch, `answers-11-3-2026.txt`, `answers-11-7-26.txt` and `answers-11-11-26.txt` sat untracked in the `/workspace` checkout (the session's starting git status).
2. **A session records them, when the owner points it at the file.** For example, a475f2de ("docs(questions): record owner answers of 2026-11-11", author magfrump, an agent co-author) reads "From docs/human-author/answers-11-11-26.txt. Answer lines and Status changes only, so the cycle classes this commit as answers." It changes only `docs/working/questions.md` (10+/5-). The recorder also judged: "Q-273 stays open: its first paste did not run", and "Q-270 is read as both [2] and [4]". The recorded line cites its source, for example `docs/working/questions-archive.md:6427`: "Q-274: [1] (owner, answers-11-11-26.txt)". 3fcbc89e (answers-10-28-26) and 80b7dabe (Q-277, answered "in session 2026-11-12" and then archived) follow the same shape.

### What the dev cycle reads, and when

- **D8** (`docs/working/plan-build-loop-handoff.md:91`): "Answers that unblock autonomous work are read from main's commit ... not the working tree, because a loop can write any working tree under `/workspace` (F28). An answer reaches main in one of two ways: you commit it yourself; you tell the orchestrator in its session, and it commits that answer." Also `:446`: "an answer typed into the working tree counts only once you commit it or tell the orchestrator."
- **`check_answer`** (`scripts/lib/dev-cycle-read.sh:1202`) reads `MAIN_SHA:docs/working/questions{,-archive}.md`. Its reader `ANSWER_AWK` (`:1136-1189`) finds the entry's heading. It reads Status from the first `**Needs:**` line and takes the first later line that starts `Q-NNN:` (or `- Q-NNN:`, or an `**Answer...` label) as the answer. It reports `open` unless Status is ANSWERED, and reads a leading `[1]`/`[2]`/`[3]` (or keep/drop/done) as the option.
- **`--main-log`'s `answers` class** is `log_class` (`scripts/build-loop.sh:1934-1976`) with the rule `ANSWERS_AWK` (`:1878-1907`). It applies to a single-parent commit that modifies only `docs/working/questions.md` and/or `questions-archive.md` (mode 100644). Every changed line has to be blank, an answer line, or a `**Needs:**` line whose only change is its Status, and at least one answer line has to be added. The cycle lists each such commit in its final message (`skills/dev-cycle/SKILL.md:299-301`). Its step 7 then reads the answers from main, so an answered merge entry merges at the next iteration (step 9's account of the answers step 7 reads, `:857-870`). Each iteration runs `questions.sh archive` from its own worktree, so an ANSWERED entry leaves the live file without anyone else doing it (`:401-407`).
- **The cycle never reads `docs/human-author/`.** The only references to it in `scripts/` and `skills/dev-cycle/` are floor and truth-file lists: `scripts/lib/dev-cycle-read.sh:972,991`, `scripts/build-loop.sh:252`, `scripts/dev-cycle.sh:54,191`, `skills/dev-cycle/SKILL.md:150,881`. An answers file reaches the cycle only through a session the owner points at it.
- **When everything waits on the owner, the loop ends**: "end the `/loop` ... and close the final message with 'Answer, then start `/loop /dev-cycle` again.'" (`skills/dev-cycle/SKILL.md:962-964`). In that state the owner opens the repo's session anyway, whatever the answer route. An answer route differs in what it saves only while a loop is still running other threads.

### The host trust model

`devcontainer-config/install.sh:14-18`: "This repo is bind-mounted read-write into agent sessions ... so an agent CAN edit these files. Those edits are inert until a human runs this script and approves the diff: only the INSTALLED copies are ever read." Its `git_state_gate` (`:203-263`) exists because "An agent can write .git, and so can a cc-isolated container through its bind mount, so this is a container-to-host path the no-agent gate cannot see". `git archive` runs a smudge filter, `git status` runs `core.fsmonitor` and clean filters, and so on. H1 says the same in general: what a session writes, "including git config, hooks and attributes in a checkout it can write, is input to those checks, not a source of their logic."

There is reusable prior art. The lib `scripts/lib/dev-cycle-read.sh` is "Sourced, never run ... Each script sources it from its own directory (never from the repo it acts on)" (`:9-11`), and `scripts/d6.sh` "sources the image copy in a subshell for git_harden alone" (`:13-14`). `git_harden` (`HARDEN` and the function, `:335-346`) exports `core.hooksPath=/dev/null`, `core.fsmonitor=false`, `core.attributesFile=/dev/null` and `commit.gpgSign=false` as `GIT_CONFIG_*` pairs. These env pairs outrank the repo's own config. It also sets `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1` and `GIT_ALLOW_PROTOCOL=none`. `resolve_main` (`:550-572`) finds main or master by exact ref.

The merge path `land` (`scripts/build-loop.sh:1607-1660`) also handles a default branch that is checked out in a worktree. There it requires that worktree to be clean (`git status`) and fast-forwards it. That is safe inside a container. On the host, `git status` and `merge --ff-only` in a container-written checkout run the clean and smudge filters that its in-tree `.gitattributes` and `.git/config` name. `core.attributesFile=/dev/null` does not cover those. So the host cannot reuse `land` as it is.

## 2. Invariants

- Answers that unblock work are read from main's commit (D8). An answer only in a working tree is inert to the cycle.
- The orchestrator never commits an answer it did not get from the owner in session (D8, F42). A host write must not create something the cycle would treat as an answer the owner did not give.
- One questions grammar, one parser (S3): the board reads entries through `questions.sh`, never through its own parser.
- No repo-authored code runs on the host (H1). The board, `questions.sh` and the lib are the install-reviewed copies under `~/.claude/scripts/`. Every git call on a registered repo runs under `git_harden`'s environment.
- No LLM anywhere (the owner's scope; H4 does not apply, but the build has to keep it true, section 6).

## 3. Design choices

### The one write: how an answer gets back to its repo (divergent design)

Seeded with `docs/constraints.md` and the brief. These are the candidates: the brief's four, one variant of (c), and one composition.

- **(a) Answers file.** The board appends `Q-NNN: answer` to a dated `docs/human-author/answers-M-D-YY.txt` in that repo's main checkout, and recording is left to the repo's next session.
- **(b) Edit and archive.** The board edits the entry in the checkout's `docs/working/questions.md` (an answer line, plus Status ANSWERED) and runs `questions.sh archive` there.
- **(c1) Plumbing commit on main.** On the host, under `git_harden`, the board builds a new `questions.md` blob from main's commit. It adds the answer line directly after the entry's `**Needs:**` line and sets Status to ANSWERED. It then writes the commit with `hash-object -w --stdin`, `mktree`/`read-tree` into a temporary index, `commit-tree` and a compare-and-swap `update-ref refs/heads/main NEW OLD`. It never touches a working tree. It refuses when main is checked out in any worktree.
- **(c2) As c1, plus in place when main is checked out.** If main is checked out in worktree W, and W's `docs/working/questions.md` bytes equal both the HEAD blob and the index blob, the board does three things. It writes the new bytes to that one file, refusing a symlink at every component up to W's top level. It runs `update-index --cacheinfo 100644,NEWBLOB,docs/working/questions.md`, which reads no file and so runs no filter. Then it runs the same compare-and-swap `update-ref`. The equality is read from git objects and raw bytes (`cat-file`, `ls-files -s`), never with `status` or `diff`, so no clean filter runs.
- **(d) Print only.** The board prints `Q-NNN: answer` and the repo path for the owner to paste into that repo's session.
- **(e) c2, with d as its fallback.** Any refusal prints the line and why it was not written. This covers a multi-line answer, a dirty `questions.md` in W, an entry that is not one OPEN `you:` entry on main, a compare-and-swap that lost a race, or an unreadable repo.

Note on (c): "a commit on the host" means a commit on main. A commit on any other branch would reach main only through a session merging it, which makes it a slower (a). Committing to main is D8's first route ("you commit it yourself"): the owner typed the answer into a host tool, in their own terminal, under their own git identity. That identity is read from the host's global git config before `git_harden` hides it, and passed as `GIT_AUTHOR_*`/`GIT_COMMITTER_*`.

The table scores each candidate on what the cycle reads, a dirty checkout, and the H1 trust question:

| | What the cycle reads, and when | Uncommitted or dirty checkout | H1: a host script writing where a container can write |
|---|---|---|---|
| (a) | Nothing, until the owner tells a session "record answers-X". The file is in a working tree, so D8 makes it inert, and the orchestrator may not commit it on its own (F42). | No conflict: a new untracked file. But it can sit uncommitted for weeks, as three files do today. | A plain write into a container-writable tree. A planted symlink at `docs/`, `docs/human-author/` or the file turns an append into a write to any host file (FP-034/FP-167). It needs a component-by-component symlink refusal, but no git. |
| (b) | Nothing: an edit in the working tree is inert (D8). The `archive` it ran then makes a later commit of it class `other` (removed body lines), not `answers`. | It collides with any session editing `questions.md` in that checkout, and the checkout may be on a branch other than main, so the edit lands on the wrong branch. | It runs `questions.sh archive` on the host. The installed copy is acceptable. "The repo's own" copy is repo code on the host, which breaks H1. |
| (c1) | Main's commit, at the next iteration. `--main-log` classes it `answers` and lists it, `check_answer` reads it, and an answered merge entry merges next iteration. A running loop picks it up with no session visit. | Untouched, since no working tree is written. But when main is checked out (likely the common case in a one-checkout repo), moving the ref leaves that checkout's index one commit behind. A session's next commit there would revert the answer, and `land`'s clean check would refuse every merge. So c1 has to refuse whenever main is checked out. | Host git on a container-written `.git` is the FP-116 class. `git_harden` covers hooks (`reference-transaction`, `post-index-change`), fsmonitor and global config. The plumbing runs no filters (no `--path` to `hash-object`, no checkout). The residual is the local config keys that plumbing never consults. |
| (c2) | As c1. | It handles a checked-out main when that worktree's `questions.md` is unmodified. Other modified files in W are left alone: the commit changes only `questions.md`, and W's index keeps every other entry. A modified `questions.md` refuses. | As c1, plus one plain file write into W, with the same symlink refusal as (a). The race between the byte check and the write is accepted: a same-uid honest slip, S1. |
| (d) | Whatever the owner pastes into a session, where the orchestrator commits it (D8's second route). | None. | None. |
| (e) | As c2 when it writes; as d otherwise. | As c2; refusals fall through to printing. | As c2. |

The other constraints:

| | H2: fails closed, loud | H3: hermetic tests | S3: reuse | S8: size | S10: owner attention | S5: meets the owner's scope |
|---|---|---|---|---|---|---|
| (a) | Yes, with the symlink refusal. | Yes. | The owner's own format. | ~25 lines. | One "record the file" message per repo session. | Partly. The answer reaches the repo but not the cycle. |
| (b) | Weak: a working tree on the wrong branch is a silent mis-write. | Yes. | Duplicates the cycle's own archive step. | ~40 lines. | As (a), and worse when the checkout is on another branch. | No. |
| (c1) | Yes. | Yes, with fixture repos and no network. | `answers`-class shape, `git_harden`, `resolve_main`, `check_answer`. | ~110 lines. | None when it writes. | Only when main is not checked out. |
| (c2) | Yes. | Yes. | As c1. | ~150 lines. | None when it writes. | Yes, for one-line answers. |
| (d) | Trivially. | Yes. | — | ~5 lines. | A paste per repo session: the status quo, minus opening every workspace to find the questions. | No. Viewing only. |
| (e) | Yes: every refusal names its reason and prints the line. | Yes. | As c1. | ~160 lines. | As c2, falling back to d. | Yes. |

**Outcome: Path A, (e).** (b) is dominated: an inert write on a possibly wrong branch, duplicating a step the cycle already runs. (c1) is (c2) minus the common case. (d) alone is the status quo for answers, which the owner's scope rules out. Between (a) and (e), only (e) gets an answer to the cycle with no further owner action. (a) needs the in-session "record it" message that the board exists to remove. (e)'s extra cost is host git surface, which `git_harden` and FP-116's lesson (no hooks, no checkout, no filters) bound.

The one-line limit is principled, not a shortcoming. Pasted terminal output, questions back to the agent and partial answers are exactly the answers whose recording needs judgment ("Q-273 stays open: its first paste did not run", a475f2de). A host script cannot make that call, and the `answers` class does not admit them. So (e) writes a single line only, and prints anything multi-line for a session. Whether v1 should also save those multi-line answers to an answers file, (a) as a second write path, is the owner's call in section 8, row 2.

Details the build carries:

- **The entry check reads main's blob.** The board requires exactly one `### Q-NNN ` heading in main's `questions.md`, outside any fence (the lib's `FENCE_AWK` over the blob refuses an odd or unbalanced file), and none in the archive. It requires Status OPEN and a route starting `you:`. Anything else refuses.
- **The post-condition reuses the cycle's own reader.** Before `update-ref`, the board runs the lib's `check_answer` against the new commit, and the result has to be neither `open`, `dup`, `quoted` nor `odd`. It also checks that `diff-tree NEW^ NEW` lists only `docs/working/questions.md`. A failed post-condition refuses, and the ref does not move.
- **The answer text arrives as one argv element** (`board answer PROJECT Q-NNN TEXT`, the CLAUDE.md argv rule). It has to be strict UTF-8 with no CR, LF or other control characters. The written line is `Q-NNN: TEXT (owner, board YYYY-MM-DD)`, after the recorders' `(owner, answers-…)` citation.
- **The commit subject is `docs(questions): answer Q-NNN from the board`**, with no agent trailers. The owner sees it in the cycle's `answers` list.
- **The cost of a race.** If a host answer lands on main mid-iteration, that iteration's `--cycle-diff` refuses its own questions changes ("a questions change while main's questions files changed since BASE", `skills/dev-cycle/SKILL.md:875-876`). The next iteration redoes them. A hand commit by the owner costs the same today.

### Reading questions: through the installed `questions.sh open`, on main's blobs (two options, no divergent design)

The board extracts main's three questions files with `git cat-file blob MAIN_SHA:docs/working/…` into a temporary directory, after the lib's `main_entry` confirms each is a regular file. It then runs the installed `questions.sh open` with `QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE` and `QUESTIONS_WATCHING` pointed at those copies (`scripts/questions.sh:41-43`). This beats running it in the checkout. The parser is the one grammar (S3). The board shows what D8 reads, not some branch's working tree. And the write path checks against the same blob it showed.

`open` also lists open watches. The board shows only `you:` routes, and gives watches as a count.

H2 cases:

- **No installed `questions.sh` or lib next to the board** (`$(dirname "$0")`, the lib's own layout rule): the board refuses the whole run and names the missing file.
- **A repo whose main has no questions files:** the board prints `PROJECT: no questions doc on main (questions.sh: …)`, quoting `require_files`'s message. A repo is never shown as empty when nothing was read.
- **`open` fails, or `check` exits 1:** the board prints `PROJECT: UNREADABLE (questions.sh check: …)` and the first refusal line.
- **An older grammar, where entries parse but a route is unknown:** the board shows them under the route as printed. `open` lists malformed entries rather than dropping them (`:569-574`).
- **No main or master by name** (`resolve_main` falls back to the current branch, `MAIN_BY_NAME` empty): the board refuses that repo by name.

The board's exit is nonzero if any repo was unreadable.

### The registry (two options, no divergent design)

The registry is a host file, `~/.config/claude-board/repos`: one absolute path per line, with `#` comments. It sits outside every repo, so no project can add itself (proposal `:37`). It is also not under `~/.claude`, where install.sh's host target stages and replaces its payload, and backs up what it replaces. The owner sets "active" by listing a path, and retires a project by deleting or commenting its line. v1 has no `add` or `retire` subcommand: it is a text file the owner edits. Last activity (main's last commit date) is shown, never used to filter. Activity cannot tell a parked project from a dead one, and filtering on it would hide one silently.

The board checks each line: an absolute path, an existing directory, `rev-parse --git-dir` succeeding under `git_harden`. A bad line prints as `REGISTRY LINE N: …` and counts toward the nonzero exit.

### bash or python3 stdlib (two options, no divergent design)

bash. The board reuses three bash pieces: the installed `questions.sh`, the lib's `git_harden`, `resolve_main`, `main_entry` and `check_answer`, and `FENCE_AWK`. python3 would restate `HARDEN` and the answer reader, which S3 forbids. The proposal's `scripts/board.py` (`:25`) predates the write. The file is `scripts/board.sh`. It reaches the host as `~/.claude/scripts/board.sh` at the next release, through install.sh's existing `scripts` payload (`install.sh:146`), so install.sh needs no change.

### Output (two options, no divergent design)

v1 prints terminal text: one block per project with its open `you:` entries (`ID  route  slug`), the watch count, and main's last commit date, plus a footer that says how to answer. The proposal's `~/board.md` (`:52-57`) is a later option. It adds a second artifact to keep fresh and serves the Kanban growth that is out of scope. The proposal's "Use" observable (`:83`) stays as one line appended per run to `~/.local/state/claude-board/runs.log`, outside `~/.claude` for the same reason as the registry.

## 4. Pre-mortem (bypass families for the write)

The write is not an enforcement file, but it runs host git in container-writable repos, so here are its failure stories:

1. **A planted git config runs on the host.** `core.hooksPath`, `reference-transaction` and `post-index-change` hooks, `core.fsmonitor`: covered by `git_harden`'s env pairs, which outrank local config. `filter.*.clean` and `smudge`: no command the board runs reads a working-tree file through git. `include.path`: it only adds config values, which the env pairs still outrank. Residual: a local key plumbing consults that `HARDEN` does not pin. The test plants each family (section 5).
2. **A symlink redirects the write.** It could sit at W's `docs`, `docs/working` or `questions.md`, or at W itself. Every component from W's resolved top level down is refused if it is a link, as in `questions.sh`'s `assert_write_target` (`:104-116`), and the resolved path has to stay inside W.
3. **The checked-out worktree drifts.** W's `questions.md` could be modified, or its index blob could differ from HEAD's, mid-rebase or mid-merge. The board refuses unless the bytes match both blobs, and refuses when W has `MERGE_HEAD`, `rebase-*` or `BISECT_START`. The list is `land`'s (`scripts/build-loop.sh:1654-1657`).
4. **A forged answer.** A loop could write an answer that the cycle reads as the owner's. That is no new path: the board writes only what the owner typed, on the host, where a container cannot invoke it. A container can already commit `answers`-class content (the class "trusts content", `scripts/build-loop.sh:1882-1884`), which is the accepted F19 residual.
5. **A wrong entry is answered.** IDs are per repo, so the board requires PROJECT and Q-NNN together. The entry's slug is printed in the confirmation line, so a mistyped project shows.

## 5. Testing (H3), the host check (S10) and the no-LLM guard

**Hermetic bats** (`test/scripts/board.bats`):

- `setup()` builds fixture repos with `git init` under `$BATS_TEST_TMPDIR`. `HOME` points into it, the registry path comes from an env override (`BOARD_REGISTRY`), and the board runs from the repo's `scripts/`, finding `questions.sh` and the lib beside it, so no host path is touched.
- A PATH shim for `claude`, `curl`, `wget` and `gh` writes a sentinel and exits 97. Every case asserts the sentinel is absent.

The cases:

- **Listing:** entries; no questions doc (named, nonzero exit); `check` failing; an unknown route; no main by name; a bad registry line.
- **Writing:** main not checked out; main checked out and clean; `questions.md` dirty in W (refuses, prints the line, the ref unchanged); an entry absent, ANSWERED, duplicated, fenced or a watch; multi-line text; a symlinked `docs/` in W; W mid-merge.
- **Hooks:** planted `reference-transaction` and `post-index-change` hooks, and a `core.hooksPath` in local config. None fires.
- **The cycle's view:** after a write, the lib's `check_answer` on the fixture's main reads the option, and `build-loop.sh --main-log` in the fixture classes the commit `answers`.

**The no-LLM guard**, in the style of H4's success line: `rg -n -e '^[^#]*(^|[;&|( ])(claude|curl|wget|gh)( |$)' -e 'claude_headless_flags' -- scripts/board.sh` prints nothing. One bats case runs it, alongside the sentinel shim.

**One host check, one paste, after the release that installs it:** `~/.claude/scripts/board.sh; echo "board exit $?"`, with the registry filled in. It adds what fixtures cannot: the real installed copies, the host's git version, the WSL paths the owner registered, and whether the read-only listing matches each repo's own view. It writes nothing. The write is covered hermetically, and its first real use is the owner's first answer.

## 6. Recommended v1 design

`scripts/board.sh` (bash) sources the lib beside it and runs under `git_harden`. It has two subcommands:

- **`board.sh`** reads the registry and, for each repo, main's questions files through the installed `questions.sh open`. It prints open `you:` entries, the watch count and the last commit, plus any refusal per repo.
- **`board.sh answer PROJECT Q-NNN TEXT`** writes one answer line as an `answers`-class commit on that repo's main: (e) above, in place when main is checked out and its `questions.md` is unmodified, else printed with the reason.

**Files and size.** The ~400-line cap counts changed code lines outside `docs/`, tests included (decision log row 62), so v1 is two stacked units:

| Unit | Files | Estimate |
|---|---|---|
| 1. The listing | `scripts/board.sh` (registry, read, print), `test/scripts/board.bats` (listing cases, no-LLM guard) | ~150 + ~150 lines |
| 2. The answer write | `scripts/board.sh` (+ the `answer` subcommand), `test/scripts/board.bats` (+ write and hook cases) | ~160 + ~200 lines |

Unit 1 is useful alone: it is the "see which project needs me" half. Unit 2 needs unit 1's registry and read.

## 7. What this does not change

- No change to `questions.sh`, the lib, install.sh, the cycle or the gates. The board is one more caller of existing readers.
- The proposal's `Opened`-date column for `cmd_open` (`:30`) is not needed for v1. Age is a Kanban-growth concern and can come later in `questions.sh` itself.

## 8. Owner's calls (for the cycle to file; also in the ready marker)

**Row 1 is the registry** (the proposal's open question 1, `docs/thoughts/proposal-2026-11-12-cross-project-board.md:123`). It is a fact only you have. The build needs it before unit 1's host check, not before the build itself.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] List them** | You give the host paths of the repos to show, one per line, for `~/.config/claude-board/repos` | One reply listing paths | A missing repo stays invisible; add its line later |
| **[2] This repo only, for now** | The registry starts with claude-workflows' host path; you add others as you go | Nothing now | The board shows one project until you edit the file |

**Row 2 is multi-line answers.** Should v1 also save the answers it cannot commit (pasted output, questions back, anything multi-line) into that repo's dated answers file under `docs/human-author/`? Tentative pick [1], tiebreaker S8 and S3: a smaller unit, one write path.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Print them (pick)** | The board prints the answer and the repo; you paste it into that repo's session, as today | A paste when you next open that repo | You keep pasting long answers; unit 3 adds the file write |
| **[2] Also write the answers file** | The board appends them to `answers-M-D-YY.txt` in that repo; you tell its session "record it" | One message per repo session | A second host write path (~25 lines, a symlink guard) that saves little |

## Files read

`docs/thoughts/proposal-2026-11-12-cross-project-board.md`, `docs/roadmap.md:270-289`, `scripts/questions.sh` (header, `parse_entries`, `cmd_archive`, `cmd_open`, `live_preamble`), the "Running questions document" section of `global-instructions/CLAUDE.md`, `docs/working/plan-build-loop-handoff.md` (D7, D8, D11), `scripts/lib/dev-cycle-read.sh` (header, `git_harden`, `resolve_main`, `ANSWER_AWK`, `check_answer`), `scripts/build-loop.sh` (`ANSWERS_AWK`, `log_class`, `land`), `skills/dev-cycle/SKILL.md` (steps 0.1, 2, 9, final message), `devcontainer-config/install.sh` (header, `git_state_gate`, `CLAUDE_HOME_SRC`), `docs/constraints.md`, `docs/failure-patterns.md`, commits 80b7dabe, a475f2de, 3fcbc89e, 6250d4ee, 1d8ea67, and the answers files under `docs/human-author/` (tracked ones in the branch; the three untracked ones in the `/workspace` checkout, read as evidence only).
