# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-250](#q-250--merge-gate-2026-11-02-relax-grammar-and-loop-prompt-c1aae1b28040) | you: judgment | Merge restriction-audit unit 4 (the gate's brief, marker and path rules refuse only real ambiguity, and the... | 2026-11-02 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all th... | 2026-10-15 |
| [Q-222](#q-222--install-cc-verify-and-r6) | you: terminal | Four approved merges landed today, two of them in host tools: the `cc-verify` host tool (37b24c02, Q-217) a... | 2026-10-28 |
| [Q-227](#q-227--image-lag) | you: terminal | - The dev cycle runs its own bookkeeping git as plain `git -C`, drops the extra `--state` re-runs and per-w... | 2026-10-29 |
<!-- index:end -->

## Open

### Q-222 · install-cc-verify-and-r6
**Needs:** you: terminal · **Opened:** 2026-10-28 · **Status:** OPEN

Four approved merges landed today, two of them in host tools: the `cc-verify` host tool (37b24c02, Q-217) and the exit scan's R6 fix for a relative `core.hooksPath` in a linked worktree (7a5b4f4a, Q-220). Neither runs on your machine until `install.sh` re-installs the host tools. Run this in your host terminal (WSL, not inside a session):

```
cd /home/magfrump/claude-workflows && git merge-base --is-ancestor 37b24c026eed64b12b1c6f9849e31cedba7a5329 HEAD && ./devcontainer-config/install.sh && cc-verify --help | head -5 && cc-isolated --list
```

The first git call only checks that your checkout already holds the cc-verify merge (it runs no hook); if it prints nothing and stops, your checkout is behind main. Before your first real `cc-verify --check`, add `~/cc-verify` to your agents' sandbox `denyWrite` (the guide's cc-verify section says why).

- **Read:** `guides/cc-isolated-usage.md`, section "Verify a branch without installing it: cc-verify" · Q-167 (its probes can run in the same sitting)
- **Blocks:** roadmap Next 1 (Q-125's host live run through `cc-verify`), and behind it Q-098 and Q-161.
- **Interim:** both merges are bats-verified only; your installed exit scan does not yet see R6, and `cc-verify` is not on your PATH.
- **2026-10-28 (owner, in session):** waiting: the install needs every active session stopped first. Q-225, once merged, rides on the same paste.

### Q-167 · post-install-host-probes
**Needs:** you: terminal · **Opened:** 2026-10-15 · **Status:** OPEN

The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all three changes below. Run the three probes against it now, before the next release puts more unverified launcher changes on top of them. (If the install did not bless, run `./devcontainer-config/install.sh` in your host checkout first.)

**(a) The rebuild hint** (clears the rebuild-hint commits' `Live-verified: no`): the install's bless output should show `Verified live:  NO — a bless is a review, not a test.` followed by `Next: cc-isolated --probe-only <repo>` alone on its line, and `cc-isolated --list` should show `Blessed config <hash> — verified live: NO (run: cc-isolated --probe-only <repo>)`. Then:

```
cc-isolated --probe-only ~/code/ANY-REPO && cc-isolated --list | grep -i 'verified live'
```

Paste back the hash `--list` prints, for a `Live-verified: <hash>` record.

**(b) The one-workspace rule** (clears its `Live-verified: no`). Paste these lines as written in default zsh; each of the first three must print an ERROR and `exit=2` with nothing done (on a launcher older than the fix, the first line exits 1 with another error (or launches a session if `~/code/b` is a repository) and the second and third print the project list: the install has not taken effect, so stop at the first line that does not print `exit=2`):

```
cc-isolated ~/code/a ~/code/b; echo "exit=$?"
cc-isolated --list  # registered projects; echo "exit=$?"
cc-isolated --profile '#' --list; echo "exit=$?"
cc-isolated --probe-only -- ~/code/ANY-REPO
```

The last must pass its probe; then `cc-isolated --list` shows it verified live.

**(c) Q-096's exit scan:** a planted pre-receive hook in a repository that a remote is rewritten to must be caught.

```
T="$(mktemp -d)" && git init -q "$T/proj" && cd "$T/proj" && git -c user.name=p -c user.email=p@p commit -q --allow-empty -m init && git remote add o https://example.invalid/repo && git config "url.$T/proj/mirror-.insteadOf" https://example.invalid/ && git init -q --bare "$T/proj/mirror-repo" && cc-isolated "$T/proj"; echo "cc-isolated exit=$?   (expect 3, naming hook …/mirror-repo/hooks/pre-receive)"; cd "$HOME" && rm -rf "$T"
```

Step 2, inside the session at Claude's prompt, then exit the session:

```
! printf '#!/bin/sh\necho planted\n' > mirror-repo/hooks/pre-receive && chmod +x mirror-repo/hooks/pre-receive
```

- **Interim:** bats-only verification (193/193), as the commits' `Host-tool-tested: no` trailers say.
- **If the answer differs:** any exit but 3, or a warning that does not name the hook, is a bug in Q-096; paste the output.

### Q-084 · q076-live-checks
**Needs:** you: terminal · **Opened:** 2026-09-27 · **Status:** OPEN

Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git 2.39.5. After merging, re-run `install.sh` (it re-blesses; `cc-push.sh`, `cc-exit-scan.sh` and `cc-gitdir.sh` are new), then run this on the host:

```
git --version          # cc-push refuses below 2.39.4 / 2.40.2 / 2.41.1 / 2.42.2 / 2.43.4 / 2.44.1 / 2.45.1 (or <2.46 otherwise)
# 1. a clean session: launch, make one commit, exit claude -> expect exit 0 and no WARNING
cc-isolated ~/path/to/a/scratch/repo
# 2. while that container is still up, in another host shell -> expect a refusal naming the running container
cc-push --remote <your real remote URL> ~/path/to/a/scratch/repo
# 3. stop the container (or exit cc-isolated), then push for real -> expect the preview, then the push
cc-push ~/path/to/a/scratch/repo
# 3b. (Q-093, after re-running install.sh) leave .git/commondir holding '.' in place -> expect the push, no refusal
# 1b. (Q-094) a session that leaves an agent worktree behind -> expect exit 0 and one 'note:' line, no WARNING
# 4. inside any cc-isolated session on the rebuilt image (Q-086, 9e5477a) -> expect a version line
parallel --version | head -1
apt-cache depends parallel                 # Q-086 review C3: note any hard dependency (e.g. sysstat)
bats --jobs 2 test/agents-gemini-sync.bats 2>&1 | grep -iE 'cite|locale'   # expect no output (C2)
```

**2026-09-28 (answers-9-28-26-2.txt), step 3:** `cc-push` refused on `~/claude-workflows` itself (not a scratch repo): "`.git/commondir` exists (a linked worktree's layout)". Cause: the main checkout's `.git` has a stray 1-byte `commondir` holding `.` (it points to itself, so git behaves as if it weren't there). Next to it are an empty `config.worktree` and an empty `modules/`, all dated 2026-07-09 13:45. No commit that day runs `git worktree`, so some tool probably wrote them. `extensions.worktreeConfig` is unset, so git never reads `config.worktree`. `cc-push.sh:272` refuses any `commondir` without resolving it: a false positive on this repo. The fix is Q-091. Steps 1, 2 and 4 are not reported yet.

**2026-09-28, step 2:** passed. With the container still running, `cc-push` refused and named the running container, as expected. The stray `commondir` behind step 3's refusal is removed (Q-091 [1]), so step 3 needs a rerun. Steps 1 and 4 are not reported yet.

**2026-09-28, step 3:** passed. `cc-push` worked on `~/claude-workflows`, but only after the user deleted `.git/commondir` again. It had come back since Q-091 [1], which is now Q-093. Step 1 has not been run as written. Every session exited today gave a WARNING, mostly listing worktrees. The cause was reproduced in a scratch repo with the real `git_exit_scan`: a worktree still present at exit adds three records (`+ dotgit <wt>/.git`, `+ commondir-file .git/worktrees/<name>/commondir`, `+ hooksdir .git/worktrees/<name>/hooks missing`), so the scan returns 1. With the worktree removed and pruned it returns 0. That behaviour is what the scan specifies, not a bug, and whether it should change is Q-094. Step 1 is still a valid test as written: a scratch repo with no worktrees should exit 0. Steps 1 and 4 are not reported yet.

**2026-09-30 (answers-9-30-26.txt):** host git is now **2.55.0**. WSL's apt had an old version that `cc-push` refused, and apt listed nothing newer. **Step 1 passed:** a small test commit, then exit with no error. **Step 2 passed** again: refused while a session ran. **Steps 3 and 3b passed:** `cc-push` showed the preview and pushed without `.git/commondir` being deleted, which confirms Q-093's relaxation live. **Step 4 passed:** `GNU parallel 20221122`, which is bookworm's version, so it ran in the image (compare Q-086's host reading of 20210822). `apt-cache depends parallel` lists hard deps on `procps`, `sysstat` and `perl`, so sysstat comes into the image with parallel (review C3: noted, no action). The `bats --jobs 2 … | grep -iE 'cite|locale'` check printed nothing (C2 holds). That fires Q-090's trigger. **Still not reported: step 1b** (Q-094): a session that leaves an agent worktree behind should exit 0 with one `note:` line. Q-084 stays open for that step alone.

- **Interim:** every enforcement-file commit on Q-076 carries `Live-verified: no`.
- **If the answer differs:** a refusal on step 3, a warning on step 1, or a version refused that git's release notes list as fixed means a follow-up fix. Also check git's May 2024 security release notes against the version list in the `cc-push.sh` header, which was written from memory.

### Q-227 · image-lag
**Needs:** you: terminal · **Opened:** 2026-10-29 · **Status:** OPEN

**Release notes** (trial T1; rewritten 2026-11-02 for main at d9f2e42a). Installed image: `42295bd9`, read from `/opt/claude-workflows/.manifest`. Main is ahead in gate code by one file, `skills/dev-cycle/SKILL.md`: restriction-audit unit 3, which you approved (Q-249). The image carries the dev-cycle skill, so the shorter cycle is not live until you run the paste.

**If you say no:** the cycle keeps running the older, longer skill. Nothing breaks.

**⚑ Merged without your review:** none.

**What changes for you** (approved by you, Q-248 and Q-249):
- The dev cycle runs its own bookkeeping git as plain `git -C`, drops the extra `--state` re-runs and per-write path checks, and reports a main-log refusal instead of stopping on it (unit 3). Iterations take fewer tool calls.
- The workflows and skills the cycle references (pr-prep, RPI, the review-fix loop, code-review, security-reviewer, constraints-builder, and the global instructions) lose prose stops that had no in-scope threat. Unattended runs proceed on a stated default (unit 2).

**Not listed:** 8 routine dev-cycle record lands. Paths changed outside `docs/` (12 under `docs/` not listed): `global-instructions/CLAUDE.md`, `guides/convention-changes.md`, `guides/pr-prep-quick-ref.md`, `skills/code-review/SKILL.md`, `skills/constraints-builder/SKILL.md`, `skills/dev-cycle/SKILL.md`, `skills/research-plan-implement/SKILL.md`, `skills/security-reviewer/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`, `workflows/pr-prep.md`, `workflows/research-plan-implement.md`, `workflows/review-fix-loop.md`.

**The paste** (host terminal in WSL, not inside a session; stop every session first):

```
cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = d9f2e42afe7e89ebee9624ac1159fa812985ac46 && ./devcontainer-config/install.sh
```

The `rev-parse` check runs no hook. It only confirms that your checkout is at main's commit; if it fails, bring the checkout to main first.

- **Interim:** the image at 42295bd9 runs, with the older dev-cycle skill.
- **Blocks:** nothing.

### Q-250 · merge-gate-2026-11-02-relax-grammar-and-loop-prompt-c1aae1b28040
**Needs:** you: judgment · **Opened:** 2026-11-02 · **Status:** OPEN

Merge restriction-audit unit 4 (the gate's brief, marker and path rules refuse only real ambiguity, and the loop prompt runs divergent design only for 3+ options) at c1aae1b2?

**If you say no:** a brief holding `<details>`, a `NAME` placeholder in angle brackets or a `[1]: URL` line stays unreadable; a loop's question with a `## Options` heading or a "Q-12" line is filed as stopped; an approved branch adding `.github/` or `.gitignore` can never land; and every loop keeps running divergent design on single-answer choices and blocking on ties.

**What an attacker would want here:** this is gate code (`scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`), so it reaches the image at the next release. For an outside party, the relevant question is whether text from outside (a quoted web page in a brief, a pasted issue) can now make a reader see a different `Status:` or answer line. The loop kept the rules that prevent that: indented and list-item fences, an open HTML comment, CR, NUL, a BOM and an unclosed fence still refuse the whole file, and only column-0 key lines outside column-0 fences are read. The stated residual: a key line that HTML hides from a renderer is still read, which only a deliberately contrived file produces (out of scope, S1).

- **Tip:** c1aae1b2804000c8a1858211f7d8cd28c39f2fdd (5 commits past 4c410708; 17 files, +418/−180)
- **`--check` printed:**
  - `ok docs/working/briefs/2026-11-02-relax-grammar-and-loop-prompt.md c1aae1b2804000c8a1858211f7d8cd28c39f2fdd 54baccbcf8b141e99c86d8618168bf3adf22fa1c`
  - 16 `path` lines, all `M` except one `A`: `docs/decisions/log.md`, the brief, `docs/working/plan-build-loop-handoff.md`, `docs/working/research-2026-11-02-relax-grammar-and-loop-prompt.md` (A), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/migrations.sh`, `skills/constraints-builder/references/working-doc-template.md`, `skills/dev-cycle/SKILL.md`, `skills/draft-review/SKILL.md`, and five `test/scripts/` bats files
- **Paths self-merge would have refused:** the four gate-code files above, `docs/decisions/log.md` (a decision record), and the `SKILL.md` and skill-reference files (prompt files).
- **One departure from the brief (the loop's D2):** the brief said to relax the path rules "under `--approved`". But a review brief's `--check` refuses first, so a `.github/` change could still never reach your merge entry. The loop relaxed them for review briefs' `--check` and `--approved` alike. Self-merge keeps the strict rules (no `.git*` part, no symlink or gitlink). Path lines now mark `(symlink)` and `(gitlink)` so you see them here.
- **Also in it:** decision-log row 81 (the grammar redefinition, superseding row 69's HTML and link-reference refusals). The draft-review Fact-Check Gate gets unit 2's unattended default. The two stale lines unit 3 left are corrected. A no-op migration `brief-text-grammar-081` is added.
- **Checks:** two review passes; pass 1's red (a self-merge's tie question was lost) and ambers are fixed, and pass 2 was clean after two small fixes. The full health check passed on the branch ("All checks passed"). Won't-fix: a run of backticks in a release-entry path can break its code span (cosmetic).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The next iteration merges c1aae1b2; it takes effect at the next release | None beyond this answer | One `git revert` of the merge |
| **[2] drop** | The brief closes; unit 4 is abandoned | None now | The rules stay as strict as today |
| **[3] changes needed** | Your note goes back to the loop (for example, keep the path rules strict outside `--approved`) | A one-line note | Another loop round |

- **Blocks:** audit units 5 and 6 (they edit the same files).
- **Interim:** the branch waits.

