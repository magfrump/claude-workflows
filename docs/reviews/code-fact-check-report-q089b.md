# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q089b`, branch `feat/q089b4-host-tool-gate`)
**Scope:** `git diff 88432f39 79f22357`: the iteration-1 fix commits 7d25ea12, 2b183802 and 79f22357 (their messages and every changed doc, hook, test and probe script). 88432f39 and below, and A1/A2 below afe1ae59, are context the docs describe.
**Commit:** 79f22357
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-14
**Total claims checked:** 38
**Summary:** 33 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution: every executed claim ran under `timeout` in a fresh `mktemp -d` probe root
(`/home/node/.claude/jobs/00bcf178/tmp/fc-it2.xDBuze`), extracted from `git archive 79f22357`
(and from `git archive 7d25ea12` / `88432f39` for the commit-count claims), with `HOME` redirected
into the probe root, `LC_ALL=C`, `CLAUDE_DEVC_CONFIG_DIR` and `CC_LIVE_VERIFY_GATE_DISABLE`
unset. Nothing under `~/.claude` or the real config dir was written. No background processes
were started. The scripts and raw output are in `docs/reviews/execution-logs/fc-q089b-it2/`.
`run-mut.sh` applies single-edit mutations to the hook and re-runs `test/hooks/live-verify-gate.bats`.
Its results are summarised here because the summary `tee` failed: the log dir did not exist yet.
The per-mutation logs are complete.

| Run | Tests | Failing |
|---|---|---|
| clean (79f22357) | 28 | none |
| M1 remove `init-firewall\.sh` from `enforcement` only | 28 | 8 |
| M1-full swap `init-firewall\.sh` into `host_tools` | 28 | 8, 26 |
| M2 drop `--no-renames` from the `--cached` call | 28 | 28 |
| M3 drop `--no-renames` from the `-a` call | 28 | none |
| M4 re-add `$` end anchor to `host_tools` | 28 | none |
| M5 add `cc-extra\.sh` to `host_tools` | 28 | 26 |
| M6 add `cc-extra\.py` to `host_tools` | 28 | none |
| M7 host set judged on the joined set | 28 | 24 |
| M7b boundary set judged on the joined set | 28 | 27 |
| M8 headline back to "host-only tool" | 28 | 23, 27 |
| M9 drop the debt-query line from the host BLOCKED message | 28 | none |

Hallucination-pattern log read first. Two entries are test-count claims in commit messages
("All 85 tests…", "mode1-equiv 33"). The count claims here (Claims 31, 33) were checked
against that pattern by running the suites. They do not recur.

---

## Claim 1: "`hooks/live-verify-gate.sh` — `PreToolUse` Bash gate that blocks a `git commit` touching a cc-isolated enforcement file unless the message carries a `Live-verified:` trailer, or a host-only tool (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) unless it carries `Host-tool-tested:` (decision log row 71)"

**Location:** `README.md:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two-trailer rule and the three named host tools; does not establish the gate's coverage of commit forms it does not read (Claim 6).

The hook's host regex names exactly those three files, `hooks/live-verify-gate.sh:91`:
`host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'`. The test
"a host-tool commit needs Host-tool-tested, and Live-verified alone does not do"
(`test/hooks/live-verify-gate.bats:289-303`) passes in the clean run.

**Evidence:** `hooks/live-verify-gate.sh:91,152-155`; cmd `timeout 300 bats test/hooks/live-verify-gate.bats`, cwd `<probe>/src`, exit 0, 2026-10-15T01:3xZ, `docs/reviews/execution-logs/fc-q089b-it2/bats-clean.log`

---

## Claim 2: "refuses every action but `--bless` and `--list` (`--help` and usage errors are answered first)"

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--help`, an unknown flag and a bare `--profile` against a missing, mismatched or malformed `host-tools.sha256` on an installed-style copy; does not establish `--bless`/`--list` behaviour in that state (A1's tests own that).

The flag loop runs before the refusal, `devcontainer-config/cc-isolated.sh:735-753`:

```bash
      --help|-h)    usage; exit 0 ;;
      --)           shift; break ;;
      -*)           echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 2 ;;
...
  if [ -n "$HOST_TOOLS_ERR" ] && [ "$action" != "bless" ] && [ "$action" != "list" ]; then
    echo "ERROR: host-tool check failed — refusing to launch, probe or register:" >&2
```
(excerpt ends :754; enclosing `main()` continues to its end — read through :800)

Probe B (one tool's hash wrong): `--help` exit 0 with usage, `--bogus-flag` exit 2, `--profile` exit 2, bare launch exit 1 with the refusal.

**Evidence:** `devcontainer-config/cc-isolated.sh:714-760`; cmd `bash scripts/probe-launcher.sh <probe>`, cwd `<probe>/inst`, exit 0, 2026-10-15T01:35:27Z, `docs/reviews/execution-logs/fc-q089b-it2/probe-launcher.log`

---

## Claim 3: "They remain enforcement files for code-review's mechanic 7 and RPI's bypass-family pre-mortem (rows 60, 61(4)): both now read \"the `enforcement` or `host_tools` pattern\"."

**Location:** `docs/decisions/log.md:94`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the two consumers say; does not establish that rows 60 and 61 were themselves reworded (they were not; row 71 amends them).

RPI reads it word for word, `workflows/research-plan-implement.md:233`: "a path matching the `enforcement` or `host_tools` pattern in `hooks/live-verify-gate.sh`". Mechanic 7 says the same thing in other words, `skills/code-review/SKILL.md:746`: "matched by the `enforcement` or the `host_tools` regex in `hooks/live-verify-gate.sh`". So the quoted phrase is exact for one consumer and a paraphrase for the other. Precise version: both now name "the `enforcement` or `host_tools` regex/pattern". Row 60 still reads "The enforcement set is the one `hooks/live-verify-gate.sh` gates (its regex mirrors … `enforcement_files()`…)" (`docs/decisions/log.md:83`). Row 71's sentence is the amendment.

**Evidence:** `workflows/research-plan-implement.md:233`, `skills/code-review/SKILL.md:745-749`, `docs/decisions/log.md:83-84,94`

---

## Claim 4: "Not covered: … a `sha256sum` or `awk` stand-in, on PATH or as an exported shell function, that prints the blessed hash (both are found by name, as `git` is)"

**Location:** `docs/decisions/log.md:94`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how `verify_host_tools` resolves the two commands; does not establish whether the entry points sanitise PATH or the environment somewhere else.

`verify_host_tools` calls both by bare name, `devcontainer-config/cc-isolated.sh:257,263`: ``want="$(awk -v f="$f" '$2 == f …' "$m")"`` and ``have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"`` (the same code is in `cc-push.sh:182-190`). Bash looks up functions, including exported ones a child bash inherits, before PATH. So the added "exported shell function" family is a real gap of the same kind (paraphrased — no quote available because this is bash's documented lookup order, not repo code).

**Evidence:** `devcontainer-config/cc-isolated.sh:230-265`, `devcontainer-config/cc-push.sh:182-196`

---

## Claim 5: "a static test tying each entry point's `source` lines to its check list was split out as Q-147"

**Location:** `docs/decisions/log.md:94`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Q-147 now exists on this branch and describes that split; does not establish that the `feat/q089-source-guard` unit has run its loop.

`docs/working/questions.md:319-322`: "### Q-147 · q089-loop-split-source-guard … the static source-set test (rubric A6/R2/R4) moves to its own unit, `feat/q089-source-guard`". The ID is used by nothing else on any local branch. `main`'s highest ID is Q-146. See Claim 9.

**Evidence:** `docs/working/questions.md:42,319-325`; see Claim 9's log

---

## Claim 6: "a `git commit <path>`, `-o` or `-i` commits unstaged gated changes with no trailer; a `git -C <dir> commit` … is checked against the hook's cwd; a shebang edit passes as comment-only"

**Location:** `docs/roadmap.md:63-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three gaps as filed, against the hook at 79f22357; does not establish `cd <dir> && git commit` (the security review's sibling form), which was not probed here.

With an unstaged egress widening, `git commit <path> -m x`, `-o` and `-i` all exit 0. After `git add`, a plain `git commit -m x` blocks (exit 2), but the same commit sent as `git -C <repo> commit -m x` from another cwd exits 0. A staged `#!/usr/bin/env bash` → `#!/tmp/evil` change to `cc-push.sh` exits 0. The reason is in the hook, `hooks/live-verify-gate.sh:140`: `'#'*|'//'*) continue ;;      # comment`.

**Evidence:** `hooks/live-verify-gate.sh:73-78,138-141`; cmd `bash scripts/probe-roadmap.sh <probe>`, cwd `<probe>/p3`, exit 0, 2026-10-15T01:36:02Z, `docs/reviews/execution-logs/fc-q089b-it2/probe-roadmap.log`

---

## Claim 7: "Each fails closed at runtime (the bless diff, `verify_host_tools`)."

**Location:** `docs/roadmap.md:66-67`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that an unseen commit still meets a refusal before it runs (the installed-config check refuses until a re-bless, which prints the diff; `verify_host_tools` refuses a changed host tool); does not establish that the human reads the diff, or anything for a change never installed.

`verify_host_tools` names a changed tool, `devcontainer-config/cc-isolated.sh:265`: `echo "$dir/$f changed since the last bless"`. The launch probe shows the refusal and the bless hint for a changed `cc-exit-scan.sh` (Claim 2's log). A boundary change reaches a launch only through `install.sh`, which ends in `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`devcontainer-config/install.sh:607`) (paraphrased — no quote available because the bless-prints-diff behaviour is A1's, spread across `bless_manifest`).

**Evidence:** `devcontainer-config/cc-isolated.sh:230-265,754-770`, `devcontainer-config/install.sh:601-607`, `docs/reviews/execution-logs/fc-q089b-it2/probe-launcher.log`

---

## Claim 8: "bless/`--list` use `config_dir()` while the pre-source check uses the launcher's own dir; every hint now names the right dir"

**Location:** `docs/roadmap.md:68-71`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two dir sources and the hints the refusal prints; does not establish `--list`'s output in a mismatched install.

Bless hashes from `config_dir`, `devcontainer-config/cc-isolated.sh:216`: `(cd "$(config_dir)" && sha256sum "${files[@]}")`. The pre-source check uses the script's own dir, `:714-716`: `CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"` … `verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh`. Every refusal in the probe prints `CLAUDE_DEVC_CONFIG_DIR=<launcher dir> <launcher dir>/cc-isolated.sh --bless`. The cited sources exist: architecture review A1 F1 ("Two notions of \"the install dir\"") and rubric row C1.

**Evidence:** `devcontainer-config/cc-isolated.sh:216,714-716,767-768`, `docs/reviews/architecture-review-2026-10-14-q089a1.md:24`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089a1-host-tool-manifest.md:36`, `docs/reviews/execution-logs/fc-q089b-it2/probe-launcher.log`

---

## Claim 9: Q-147 "was filed on feat/q089-host-tool-trust (548fe6f9) but not carried into this stack. It is added to docs/working/questions.md here."

**Location:** `docs/working/questions.md:42,319-325` (commit 7d25ea12 message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the entry's provenance, its byte-identical text, the regenerated index row and the file's structure check; does not establish the entry's merge order against main's next ID.

`git show 548fe6f9:docs/working/questions.md` has `### Q-147 · q089-loop-split-source-guard` at :319. That commit is on `feat/q089-host-tool-trust`. Its entry diffs identical to 79f22357's. The only branches holding a Q-147 are `feat/q089-host-tool-trust`, `feat/q089b3-host-tool-gate` and this one. `scripts/questions.sh check` on the archive reports `✓ questions: structure valid, indexes current`.

**Evidence:** `docs/working/questions.md:42,319-325`; cmd `timeout 60 bash scripts/questions.sh check`, cwd `<probe>/src`, exit 0, 2026-10-15T01:33:24Z, `docs/reviews/execution-logs/fc-q089b-it2/questions-check.log`

---

## Claim 10: "`ERROR: host-tool check failed — refusing to launch, probe or register` | A host tool … changed since the last bless, or `host-tools.sha256` is missing, unreadable or malformed (the indented lines say which)"

**Location:** `guides/cc-isolated-usage.md:927`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the headline and the three causes as printed by the launcher; does not establish the row's `--list` sentence.

The launcher prints the quoted headline, `devcontainer-config/cc-isolated.sh:754`, followed by one indented line per reason. The probe shows all three: "no host-tool manifest at …", "…/cc-exit-scan.sh changed since the last bless", and "host-tool manifest … is unreadable or malformed: inspect it before any bless overwrites it". Each run also shows the boundary diff note.

**Evidence:** `devcontainer-config/cc-isolated.sh:238-246,754-768`, `docs/reviews/execution-logs/fc-q089b-it2/probe-launcher.log`

---

## Claim 11: "`ERROR: cc-push refuses to run:` … `no host-tool manifest`, right after upgrading | Expected once on an install that predates host-tools.sha256 …: re-run `install.sh`, or review the tools and run the bless command cc-push prints."

**Location:** `guides/cc-isolated-usage.md:928`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push's output on an installed-style copy with no `host-tools.sha256`, and that `install.sh` blesses; does not run `install.sh` itself.

`cc-push.sh --help` in that state exits 1 with `ERROR: cc-push refuses to run:`, then `no host-tool manifest at …/host-tools.sha256 (re-run install.sh, or review the tools and bless this dir)` and `CLAUDE_DEVC_CONFIG_DIR=<dir> cc-isolated --bless`. `install.sh:607` runs that bless.

**Evidence:** `devcontainer-config/cc-push.sh:203-211`, `devcontainer-config/install.sh:607`, `docs/reviews/execution-logs/fc-q089b-it2/probe-launcher.log`

---

## Claim 12: the troubleshooting table renders (every row has the header's cell count)

**Location:** `guides/cc-isolated-usage.md:923-942`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unescaped-pipe cell counts for every table in both guides at 79f22357 (GFM splits on every unescaped `|`, code spans included); does not render the Markdown.

At 79f22357: `cc-isolated-usage.md:923 rows=20 cols=2 mismatched=[]`, plus the profile table (:92, 12 rows, 3 cols) and `devcontainer-setup.md:257` (6 rows, 3 cols), all clean. The history check shows the troubleshooting row broke at 7d25ea12 (`mismatched=[(927, 1)]`) and was fixed at 2b183802.

**Evidence:** cmd `python3 -I scripts/tables.py guides/cc-isolated-usage.md guides/devcontainer-setup.md`, cwd `<probe>/src`, exit 0, 2026-10-15T01:33:47Z, `docs/reviews/execution-logs/fc-q089b-it2/table-cells.log`, `docs/reviews/execution-logs/fc-q089b-it2/table-history.log`

---

## Claim 13: "so from row 71 on that list gains only debt a probe can pay (host-tool commits before it, from Q-076 on, stay in it); `git log --grep 'Host-tool-tested: no'` lists the host-tool debt"

**Location:** `guides/devcontainer-setup.md:250-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the history of host-tool commits and the grep's match against the trailer the gate demands; does not establish that later commits will fill in `no` honestly.

`git log -i --grep='Live-verified:' 79f22357 -- devcontainer-config/cc-{push,exit-scan,gitdir}.sh` lists host-tool commits from c3d9223b/f511cc19 (2026-09-27, Q-076) to afe1ae59. The gate's suggested form is `Host-tool-tested: no — <reason>` (`hooks/live-verify-gate.sh:200`), which the grep matches.

**Evidence:** `hooks/live-verify-gate.sh:198-204`; cmd `git log --format='%h %ad %s' --date=short -i --grep='Live-verified:' 79f22357 -- <3 host tools>`, cwd worktree, exit 0 (output inline in this session, not captured; read-only history query)

---

## Claim 14: "Enforcement files are what `enforcement_files()` … hashes: … the `egress/*.txt` lists, every registered `projects/*.profile`, and the staged `claude-home/`"

**Location:** `guides/devcontainer-setup.md:266-270`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function's list; does not establish that the gate's regex matches `projects/` (it does not; the bats comment at `test/hooks/live-verify-gate.bats:114-117` says why).

`devcontainer-config/cc-isolated.sh:144-149`:

```bash
    for f in egress/*.txt; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
    for f in projects/*.profile; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
    ...
    if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) | LC_ALL=C sort; fi
```
(excerpt from `enforcement_files()` :128-151 — read)

**Evidence:** `devcontainer-config/cc-isolated.sh:128-151`

---

## Claim 15: "it refuses every action except `--bless` and `--list` (`--help` and usage errors are answered first)"

**Location:** `guides/devcontainer-setup.md:281-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 2.

Same code and probe as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:735-760`, `docs/reviews/execution-logs/fc-q089b-it2/probe-launcher.log`

---

## Claim 16: "HOST TOOLS … carry their own trailer, `Host-tool-tested:` …, and a `Live-verified:` trailer does not satisfy them. A commit touching both kinds needs both trailers. Each set gets the comment-only narrowing below on its own."

**Location:** `hooks/live-verify-gate.sh:23-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three rules as pinned by tests 21-27 and mutations M7/M7b; does not establish that one trailer's value cannot mention the other (security review #7, informational).

`hooks/live-verify-gate.sh:153-154`:

```bash
if [ -n "$boundary_touched" ] && ! comment_only_diff "$boundary_touched"; then need+=("Live-verified"); fi
if [ -n "$host_touched" ] && ! comment_only_diff "$host_touched"; then need+=("Host-tool-tested"); fi
```
(excerpt ends :154; the block continues to :172 — read)

Feeding the joined set to either call fails test 24 (M7) or test 27 (M7b).

**Evidence:** `hooks/live-verify-gate.sh:150-172`, `docs/reviews/execution-logs/fc-q089b-it2/bats-clean.log`, `bats-M7-joined-host.log`, `bats-M7b-joined-boundary.log`

---

## Claim 17: Behavior table: "not a `git commit`, or no enforcement file or host tool staged → exit 0; each staged set whose diff touches only comment/blank lines → needs no trailer; every remaining set carries its trailer … → exit 0; a remaining set lacks its trailer → exit 2"

**Location:** `hooks/live-verify-gate.sh:40-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four rows against the code and the clean suite; does not establish "staged" for commit forms the gate does not read (Claim 6).

`hooks/live-verify-gate.sh:95`: `[ -n "$touched" ] || exit 0`, `:155`: `[ "${#need[@]}" -gt 0 ] || exit 0`, `:172`: `[ "${#missing[@]}" -gt 0 ] || exit 0`, `:208`: `exit 2`.

**Evidence:** `hooks/live-verify-gate.sh:92-208`, `docs/reviews/execution-logs/fc-q089b-it2/bats-clean.log`

---

## Claim 18: "--no-renames: a rename is listed as both paths, so moving a gated file to an ungated name is still gated (with rename detection only the destination shows)."

**Location:** `hooks/live-verify-gate.sh:71-73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with default `diff.renames`; does not establish the behaviour under a user config that turns rename detection off (then both forms list both paths anyway).

After `git mv devcontainer-config/egress/base.txt devcontainer-config/base-moved.txt`, `git diff --cached --name-only` prints only `devcontainer-config/base-moved.txt`. With `--no-renames` it prints both paths.

**Evidence:** cmd `git diff --cached --name-only [--no-renames]` in a scratch repo, cwd `<probe>/rn`, exit 0, 2026-10-15T01:33Z, `docs/reviews/execution-logs/fc-q089b-it2/rename-probe.log`

---

## Claim 19: "security F2: `git diff --name-only --no-renames`, so renaming a gated file to an ungated name is gated (new test)" — both name-only calls carry the flag

**Location:** `hooks/live-verify-gate.sh:73,77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both calls and the staged-rename test; does not establish that the `-a` call's flag is tested. Dropping it (M3) leaves all 28 green, but it matters: an intent-to-add rename under `commit -a` is listed only as the destination without it, and the gate blocks with it.

`hooks/live-verify-gate.sh:73`: `files="$(git diff --cached --name-only --no-renames 2>/dev/null)" || exit 0`. `:77`: `files="$files"$'\n'"$(git diff --name-only --no-renames 2>/dev/null)"`. M2 (cached call) fails test 28 and M3 (`-a` call) fails nothing. In probe2 P2, after `mv` plus `git add -N`, `git diff --name-only` lists only `moved.txt`, `--no-renames` lists both, and the gate exits 2 on `git commit -am x`.

**Evidence:** `hooks/live-verify-gate.sh:70-78`, `docs/reviews/execution-logs/fc-q089b-it2/bats-M2-cached-renames.log`, `bats-M3-all-renames.log`; cmd `bash scripts/probe2.sh <probe>`, cwd `<probe>/p2`, exit 0, 2026-10-15T01:33:00Z, `probe2.log`

---

## Claim 20: "keep in step with that function too (a bats test pins both lists in both directions)"

**Location:** `hooks/live-verify-gate.sh:84-85`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list-to-regex direction (test 25) and the regex-to-list direction for names of the form `[a-z-]+\.sh` (test 26); does not cover a regex name outside that form.

Test 26 pulls the names out with `grep -oE '[a-z-]+\\\.sh'` (`test/hooks/live-verify-gate.bats:356`). An extra `cc-extra\.sh` in the regex fails it (M5). An extra `cc-extra\.py` leaves all 28 green (M6). Precise version: "pins both directions for `.sh` names".

**Evidence:** `test/hooks/live-verify-gate.bats:335-361`, `docs/reviews/execution-logs/fc-q089b-it2/bats-M5-extra-sh.log`, `bats-M6-extra-py.log`

---

## Claim 21: "Not end-anchored, like `enforcement`: a stray sibling such as cc-push.sh.orig is gated too (it was, while the tools sat in `enforcement`)."

**Location:** `hooks/live-verify-gate.sh:89-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex and a staged `cc-push.sh.orig`; does not establish a test that pins it (M4, which restores the `$`, leaves all 28 green).

A staged `devcontainer-config/cc-push.sh.orig` blocks with "Host tools in the commit: devcontainer-config/cc-push.sh.orig" (exit 2) and passes with `Host-tool-tested:` (exit 0). Before 5650145a the tools sat in `enforcement` without a `$`: `…|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|install\.sh$|egress/)` (`git show 5650145a^:hooks/live-verify-gate.sh:73`).

**Evidence:** `hooks/live-verify-gate.sh:91`; `docs/reviews/execution-logs/fc-q089b-it2/probe2.log`, `bats-M4-endanchor.log`

---

## Claim 22: "restricted to one set's files (enforcement or host tools, whichever the caller passes)"

**Location:** `hooks/live-verify-gate.sh:97-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the callers at :153-154; does not establish other callers (there are none).

`comment_only_diff` reads `git diff --cached -U0 --no-color -- "${touched_files[@]}"` (`:109`) for the set it is passed. See Claim 16 for the M7/M7b evidence.

**Evidence:** `hooks/live-verify-gate.sh:104-148,153-154`, `docs/reviews/execution-logs/fc-q089b-it2/bats-M7-joined-host.log`

---

## Claim 23: "api F6/F7: one term (\"host tool\") in the BLOCKED message, which gains the why line and pointers the boundary message has"

**Location:** `hooks/live-verify-gate.sh:193-204`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message text as emitted; does not establish a test for the why and pointer lines (M9 removes the debt-query line and stays green). The headline is pinned (M8 fails tests 23 and 27).

Emitted output (probe2 P1): "BLOCKED: this commit changes a host tool but says nothing about testing it on a host." … "These run on the host after or outside the container, so cc-isolated --probe-only / cannot exercise them (guides/devcontainer-setup.md, host-tools note; decision log #71)." / "git log --grep 'Host-tool-tested: no' lists the outstanding host-tool debt." `host-only` no longer appears in the message (`hooks/live-verify-gate.sh:193-204`).

**Evidence:** `hooks/live-verify-gate.sh:192-206`, `docs/reviews/execution-logs/fc-q089b-it2/probe2.log`, `bats-M8-msg.log`, `bats-M9-why.log`

---

## Claim 24: wiring.json: "live-verify-gate.sh (blocks a `git commit` of a cc-isolated enforcement file whose message has no Live-verified: trailer, or of a host tool with no Host-tool-tested: trailer — decision log #45, #71)" and the file is valid JSON

**Location:** `hooks/wiring.json:27-29`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers JSON validity and the text against the hook; does not establish the installer's merge of the file.

`jq empty hooks/wiring.json` exits 0 and `python3 json.load` prints `ok`. The text matches Claim 1.

**Evidence:** cmd `jq empty hooks/wiring.json`, cwd `<probe>/src`, exit 0, 2026-10-15T01:33:47Z, `docs/reviews/execution-logs/fc-q089b-it2/wiring-json.log`

---

## Claim 25: mechanic 7: "matched by the `enforcement` or the `host_tools` regex in `hooks/live-verify-gate.sh`, which mirror … `enforcement_files()` and `host_tool_files()`, the owners of the lists, plus `install.sh`; host tools carry their own trailer but are still enforcement files here, decision log row 71"

**Location:** `skills/code-review/SKILL.md:745-749`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex names, their owners and the install.sh addition; does not establish how a reviewer applies a regex to a diff.

`hooks/live-verify-gate.sh:83` holds `enforcement=` with `install\.sh$`, and `:91` holds `host_tools=`. `devcontainer-config/cc-isolated.sh:128` defines `enforcement_files()` and `:199-203` defines `host_tool_files()`, which echoes the three tools. Row 71 records the rule (Claim 3).

**Evidence:** `hooks/live-verify-gate.sh:83,91`, `devcontainer-config/cc-isolated.sh:128-151,199-203`

---

## Claim 26: "Gated as a boundary file, not a host tool: Host-tool-tested alone does not pass it, Live-verified does (a swap into the host regex fails here)."

**Location:** `test/hooks/live-verify-gate.bats:133-138`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the init-firewall.sh swap; does not establish every enforcement name (the loop runs over all of them, but only one was mutated).

Under M1-full, test 8 fails at :136 with "boundary file passes on Host-tool-tested: init-firewall.sh". Removing the name from `enforcement` alone (M1) also fails test 8.

**Evidence:** `test/hooks/live-verify-gate.bats:110-142`, `docs/reviews/execution-logs/fc-q089b-it2/bats-M1-swap-full.log`, `bats-M1-swap.log`

---

## Claim 27a: "The direction the per-entry test above cannot see: an extra name in the regex, or a name dropped from host_tool_files, would leave it green."

**Location:** `test/hooks/live-verify-gate.bats:353-354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extra-name case by mutation; covers the dropped-name case by reading only (the per-entry loop iterates `host_tool_files`, so it cannot see a name that is gone).

Under M5 the per-entry test (25) passes and only test 26 fails.

**Evidence:** `test/hooks/live-verify-gate.bats:335-350`, `docs/reviews/execution-logs/fc-q089b-it2/bats-M5-extra-sh.log`

## Claim 27b: "the hook's host_tools regex names exactly host_tool_files, no more"

**Location:** `test/hooks/live-verify-gate.bats:352`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names matching `[a-z-]+\.sh`; does not cover any other name shape.

Same as Claim 20. M6 (`cc-extra\.py` added) leaves the test green.

**Evidence:** `test/hooks/live-verify-gate.bats:352-361`, `docs/reviews/execution-logs/fc-q089b-it2/bats-M6-extra-py.log`

---

## Claim 28: "the reverse direction (comment-only boundary edit beside a real host-tool change) has its own test"

**Location:** `test/hooks/live-verify-gate.bats:363-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regression where the boundary set is judged on the joined set; does not cover the `-a` path for this case.

Under M7b, test 27 fails.

**Evidence:** `docs/reviews/execution-logs/fc-q089b-it2/bats-M7b-joined-boundary.log`

---

## Claim 29: "renaming a gated file to an ungated name is still gated"

**Location:** `test/hooks/live-verify-gate.bats:375-380`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a staged `git mv`; does not cover the `-a` call (Claim 19).

Under M2, test 28 fails.

**Evidence:** `docs/reviews/execution-logs/fc-q089b-it2/bats-M2-cached-renames.log`

---

## Claim 30: "a path matching the `enforcement` or `host_tools` pattern in `hooks/live-verify-gate.sh`; the host-only tools count, decision log row 71"

**Location:** `workflows/research-plan-implement.md:233`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the definition the pre-mortem trigger now uses; does not establish the checklist line at :349, which says only "an enforcement file" and so inherits the definition.

Same regexes as Claim 25.

**Evidence:** `workflows/research-plan-implement.md:233,349`, `hooks/live-verify-gate.sh:83,91`

---

## Claim 31: "moving a boundary file such as init-firewall.sh into the host regex kept all 25 gate tests green … that swap now fails 2 tests (27/27 clean)"

**Location:** commit 7d25ea12 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 88432f39 and 7d25ea12; does not re-run the original swap at 88432f39 (the iteration-1 log `fc-q089b/probe-mutation-m3.log` did).

88432f39 has 25 tests and all pass. 7d25ea12 has 27 and all pass. The swap at 7d25ea12 fails tests 8 and 26. Matches prior pattern class "test-count claims in commit messages" (`hallucination-patterns.md:28,30`). No recurrence.

**Evidence:** cmd `bash scripts/run-7d.sh <probe> <worktree>`, cwd `<probe>/at-*`, exit 0, 2026-10-15T01:3xZ, `docs/reviews/execution-logs/fc-q089b-it2/bats-at-88432f39.log`, `bats-at-7d25ea12.log`, `bats-at-7d25ea12-mut.log`, `summary-7d.txt`

---

## Claim 32: "The fact-checker's new hallucination-log entry called it never filed; that is wrong, so it is dropped."

**Location:** commit 7d25ea12 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file at 79f22357 and in the worktree; does not establish whether the entry was ever committed on another branch.

`docs/reviews/hallucination-patterns.md` has no Q-147 or "never filed" entry at 79f22357 or in the worktree (paraphrased — no quote available because the claim is an absence; `grep -n -i 'q-147\|never filed'` returns nothing). Claim 9 shows the entry was filed.

**Evidence:** `docs/reviews/hallucination-patterns.md`

---

## Claim 33: "live-verify-gate.bats 28/28 under LC_ALL=C; mutation (init-firewall.sh moved into host_tools) fails 2 tests."

**Location:** commit 2b183802 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 79f22357, whose hook and test match 2b183802 byte for byte (`git diff --stat 2b183802 79f22357` touches only `docs/roadmap.md`); does not cover other suites.

Clean: 28 pass. M1-full: tests 8 and 26 fail.

**Evidence:** `docs/reviews/execution-logs/fc-q089b-it2/bats-clean.log`, `bats-M1-swap-full.log`

---

## Claim 34: "security: 1 Medium already fixed in 1b46a1ac" and "The usage guide's refusal row is repaired (a missing `|` from 1b46a1ac)"

**Location:** commit 2b183802 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the SHA and the row's history; does not affect the facts, which hold.

1b46a1ac is the pre-restack commit. It is reachable only from `feat/q089b3-host-tool-gate`, and on this branch its counterpart is 7d25ea12. That commit dropped the `|` (`table-history.log`: 7d25ea12 `mismatched=[(927, 1)]`), and 2b183802 restored it. Precise version: "fixed in 7d25ea12" / "a missing `|` from 7d25ea12".

**Evidence:** `docs/reviews/execution-logs/fc-q089b-it2/table-history.log`; `git branch -a --contains 1b46a1ac` → `feat/q089b3-host-tool-gate`

---

## Claim 35: "the rename test also needs the comment-only escape to see a rename as substantive, which it already did (\"rename from\")"

**Location:** commit 2b183802 message (Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism in the rename test's case (gated source, ungated destination); does not dispute the conclusion that the test blocks, or that `rename from` fires when both paths are in one set.

The escape is passed only the gated path. Limited to that pathspec, git shows a deletion, not a rename:

```
diff --git a/devcontainer-config/egress/base.txt b/devcontainer-config/egress/base.txt
deleted file mode 100644
```

So the `deleted file mode` alternative of `hooks/live-verify-gate.sh:117` keeps it gated. `rename from` appears only when both paths are in the pathspec. The conclusion holds and the stated mechanism does not.

**Evidence:** `hooks/live-verify-gate.sh:109,117`, `docs/reviews/execution-logs/fc-q089b-it2/rename-probe.log`

---

## Claim 36: "Reviewer probe scripts get a gate-6 shellcheck disable line." (behaviour unchanged)

**Location:** commit 2b183802 message; `docs/reviews/execution-logs/fc-q089b/run-probes.sh:2`, `sec-q089b/probe.sh:2`, `sec-q089b/probe2.sh:2`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gate 6's exact flags (`shellcheck -x -e SC1091 -s bash -S warning`) on all five reviewer scripts; does not re-run the probes.

With the line, all five pass gate 6. Without it, `run-probes.sh` raises SC1010 and both `sec-q089b` probes raise SC2164 (warnings). `run-bats.sh` and `run-m3.sh` show only info-level SC2015, so they need no line. Each script's non-comment lines are identical with and without the directive, so behaviour is unchanged.

**Evidence:** `scripts/health-check.sh:522`; cmd `shellcheck -x -e SC1091 -s bash -S warning <f>`, cwd `<probe>/src`, exit 0 for all five, 2026-10-15T01:34:14Z, `docs/reviews/execution-logs/fc-q089b-it2/shellcheck-gate6.log`, `shellcheck-probes.log`

---

## Claim 37: "Critics on 9001bf80 (security: 1 Medium already fixed …, 4 pre-existing; api-consistency: 1 Breaking, 1 Inconsistent, 3 Minor, 2 Info)" and "Security F3-F5 … pre-existing, are filed for a follow-up"

**Location:** commit 2b183802 / 79f22357 messages
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two summary tables and the roadmap entry; does not re-judge the severities.

The security table has #1 Medium (the swap gap), #2-#5 Medium "(pre-existing)", #6 Low and #7 Informational. The API table has 1 Breaking, 1 Inconsistent, 3 Minor and 2 Informational. #3-#5 are filed at `docs/roadmap.md:63-67`.

**Evidence:** `docs/reviews/security-review-2026-10-14-q089b.md:223-233`, `docs/reviews/api-consistency-review-2026-10-14-q089b.md:180-188`, `docs/roadmap.md:63-67`

---

## Claims Requiring Attention

### Incorrect
- **Claim 35** (commit 2b183802 Notes): the rename test is held by the escape's `deleted file mode` arm, not `rename from`, because only the gated path reaches `comment_only_diff`. This is commit-note only and the code is right, but anyone extending the rename handling should know which arm carries it.

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:94`): RPI quotes "the `enforcement` or `host_tools` pattern" word for word. Mechanic 7 says "the `enforcement` or the `host_tools` regex". "Both now read" overstates how close the wording is.
- **Claim 20** (`hooks/live-verify-gate.sh:84-85`) and **Claim 27b** (`test/hooks/live-verify-gate.bats:352`): the regex-to-list direction is pinned only for `[a-z-]+\.sh` names. A non-`.sh` extra name in `host_tools` stays green (M6).
- **Claim 34** (commit 2b183802): "1b46a1ac" is the pre-restack SHA, reachable only from `feat/q089b3-host-tool-gate`. On this branch it is 7d25ea12.

### Untested but accurate (residues from Verified scopes)
- **Claim 19**: `--no-renames` on the `-a` call matters (intent-to-add rename, probe2 P2), but no test fails without it (M3).
- **Claim 21**: the un-anchored `host_tools` is not pinned (M4 green).
- **Claim 23**: the host BLOCKED message's why and debt-query lines are not pinned (M9 green).

---

## Goal-Alignment Note

The goal was to fact-check B's iteration-1 fixes before merge, with the mutation checks the brief asked for. Every claim the brief listed was checked. The new tests were mutated against the hook: the swap, the cached-call rename, both per-set escapes and the headline all go red when the behaviour regresses. The `-a`-call rename flag, the un-anchored host regex and the message's why lines are accurate, but no test fails without them. The doc changes match the code. The troubleshooting table renders. `wiring.json` parses. Q-147 is filed with its original text, and the questions check passes. The probe-script disable lines change no behaviour. The claimed counts (25, 27/27, 28/28, "fails 2 tests") reproduce. Nothing found blocks the merge. The one Incorrect is a commit-message mechanism note, and the Mostly-accurate items are wording or test-reach tightenings. No Incorrect verdict is a fabrication of a symbol, API or flag, so `docs/reviews/hallucination-patterns.md` gets no new entry. One limit: Claim 13's `git log` query ran in the worktree, not in a captured log, because it is a read-only history query.
