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
| [Q-058](#q-058--installer-trust-model) | you: judgment | The copy-based bare-host install (`ans/copy-install`, parked at 9ae6e46) runs as your user, the same user a... | 2026-09-23 |
<!-- index:end -->

## Open


### Q-058 · installer-trust-model
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** OPEN

The copy-based bare-host install (`ans/copy-install`, parked at 9ae6e46) runs as your user, the same user as the agent. Three review passes kept finding the same root: anything that uid can write between the review and the swap reaches `~/.claude` unreviewed. Which trust model should the installer be built on?

- **Why it's yours:** it decides what "bless" guarantees on a bare host, and what you must do at install time.
- **Read:** on `ans/copy-install`, `docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md` (composition cluster 1 states the root), `docs/decisions/037-bare-host-copy-install.md`, `docs/decisions/035-install-sh-gating.md`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Stage behind `denyWrite ~/.claude`** | Stage, review, hash and install only from copies under the destination, which a sandboxed agent cannot write; re-hash right before the swap; refuse without perl; harden git (no fsmonitor or hooks). | Relies on your sandbox config carrying `denyWrite ~/.claude` | An unsandboxed agent, or a missing deny, reopens every gap |
| **[2] Install only when no agent can run** | The installer refuses while any `claude` process is running for your user (or asks you to close them), then runs [1]'s checks. | Close sessions before each install | A process the check misses (another host, renamed binary) |
| **[3] Separate user** | The installed copies are owned by a second account (or root) that agents never run as; the install runs through `sudo -u` after the review. | One-time account setup; a sudo prompt per install | Setup friction; WSL/macOS differences |
| **[4] Keep the symlinks** | Drop the copy install; the guard's resolved-path deny (merged in 5bd5c66) protects the checkout copies of linked files. | Global files stay uneditable from Claude on the host | Your Q-050 goal (the repo copy is the editable source) is not met |

- **Interim:** nothing changed on your host. The bare host still uses the README's symlink install, and the merged guard denies Claude's file tools on the linked checkout files. The copy-install branch stays unmerged; its fixes for R1, R3, R4 and R5 are kept for reuse.
- **If the answer differs:** [1]–[3] restart from `ans/copy-install` with a plan revision and one full review; [4] retires the branch and decision 037.
