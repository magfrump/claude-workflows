# Research: the write guard's Bash deny names a read route; the taint docstring covers subagents

Date: 2026-11-20 · Brief: `docs/working/briefs/2026-11-20-guard-read-route-text.md` · Branch: `fix/guard-read-route-text`

## What the code does

Line numbers are at the dispatch commit 0423fe3b.

- `hooks/guard-trusted-writes.py` classifies a Bash command by its text. `bash_targets`
  (about line 470) returns `hard` when the text has a write primitive (`WRITE_PRIMITIVE`,
  line 437: any `>` not to `/dev/null` or an fd, `tee`, `sed -i`, `dd of=`, `truncate`,
  `cp`/`mv`/`install`/`rsync`, and `python`/`node`/`perl`/`ruby` with `-c` or `-e`) plus a policy name. `main` then denies with one fixed text (line 512).
  The text says Bash can't write these files, points project files to Edit/Write and
  global ones outside Claude, and routes prose to `git commit -F` / `--body-file`.
- A read-only command that quotes a `>` or runs `python3 -c` near a policy path is
  denied the same way (philosophy-research F-022). The text gives a read-only session
  no way forward. The brief keeps the deny unchanged and only adds a route.
- `hooks/web-taint-mark.py` keys taint on `session_id` (line 48). Its docstring (line 5)
  says taint does not pass between subagent and parent sessions. F-021 saw the opposite
  for Workflow subagents: they report the parent's `session_id`, so one subagent's
  fetch tainted the whole session (7 fetches by subagents, none by the main loop).
  Whether Agent-tool subagents do the same is unverified (triage doc, F-021 extra finding).
- `guides/bare-host-hook-wiring.md:167` restates the same claim under "Known accepted
  gaps". It is corrected too, so the guide and the docstring agree (S3: one statement
  of a fact). This is the only path outside the brief's listed doc changes.
- `hooks/live-verify-gate.sh:83`: the enforcement set is `devcontainer-config/...`
  only. Neither hook is in it, so no `Live-verified:` trailer is needed.

## Prior decision this collides with: rubric row A2 (2026-09-23)

`docs/reviews/code-review-rubric-2026-09-23-ans-guard-q048-q050.md` row A2
(security-reviewer M2) removed "write that text with the Write tool and pass the
file" from this same deny text. A steered model could follow it literally, writing the
blocked command into a script and running it: the logged A8 bypass (the guard reads
command text, so a script file's contents are never seen). The fix was "never suggest
running a written file", and `test/hooks/guard-trusted-writes.bats` "A1/A2" pins it by
refusing any reason containing `script` or ` run `. The brief's criterion 2 asks for
exactly that kind of route ("run a check from a script file passed by path"), so a
choice is needed.

## Design choice: how to name the read route (divergent design)

Seeded with the brief (criterion 2: add one sentence naming Read, a script file run by
path, and prose in a Write-tool file; no change to what is denied) and the constraints:
S1 (proportionate; gates defend honest slips, not a hostile loop; do not add a
restriction whose bypass is already allowed), H2 (a deny says what went unenforced),
S11 (pure text), S3.

| Option | What it says | Brief | A2 concern | Read-only session unblocked |
|---|---|---|---|---|
| A. Read tool only | "To read these files, use the Read tool." | Misses the script route | Fully kept | Reads yes; testing a hook on a payload no (F-022's second case) |
| B. Literal brief | "...or run a check from a script file passed by path." | Met | Reopened: an unqualified "run a script" route, the M2 wording | Yes |
| C. Scoped script route | "If the command only reads or tests these files, read them with the Read tool, or write the check to a script file with the Write tool and run it by path; that route is for reads only, and a script that writes these files breaks the same rule." | Met | Narrowed: the route is offered only for reads and says a writing script is the same violation | Yes |
| D. Describe the trigger | "Quoted `>` and `python3 -c` count as writes; rephrase." | Misses Read/script | Worse: teaches how to dodge the classifier, for writes too | Yes |
| E. Status quo | none | Fails | Kept | No |

D teaches classifier evasion and E fails the motive (F-022, plus this cycle's repeated
hits). A leaves the hook-testing case without a route. Between B and C, C dominates:
it meets the brief and keeps A2's intent that the text never offers a script as a way to
write. Under S1, the residual risk is small: A8 (a script writes the file unseen) is
already open and known, and the text names it as a breach rather than a route, so an
honest model is told not to, and a steered one gains nothing it lacked.

Path A: C. The A1/A2 test changes from "never mentions a script" to "mentions the script
route only as a read route, with the write caveat", plus a new case pinning the sentence.
Residual risk, stated: a model that ignores the caveat can still use A8; that was true
before this change and is the accepted A8 gap.

Other choices (one line each):
- "With the Write tool" (review round 1 nit): without it, a session may write the script
  with a Bash heredoc that names the path and hit the same deny. The reads-only caveat in
  the same sentence is what keeps A2's intent, so naming the tool adds no write route.
- Where the sentence goes: before the prose sentence, so the three routes read in order
  read, test, prose. The prose route already exists and stays as written.
- Taint docstring: state what was observed (Workflow subagents share the parent's
  `session_id`, so they share its taint) and what is not verified (Agent-tool
  subagents). No code change, per the brief.
- Guard docstring: one line under the Bash tier noting that read-only commands are
  denied too (quoted `>`, `python3 -c`) and the deny names read routes (F-022).

## Gotchas

- Failure-pattern grep: FP-180, FP-185
  (`grep -inE 'guard-trusted|web-taint|taint|deny-(text|message|reason)|redirect|subagent|session.?id' docs/failure-patterns.md`)
  - FP-185: the earlier web-taint guard fix (a blanket `.claude` path rule caught whole
    worktrees). Same hook, but a path-classifier change; this one touches only text.
  - FP-180: matched on "redirected"; a test fixture's HISTFILE, unrelated.
- Failure-pattern skip: no new cause-and-fix shape; the change rewords a deny that stays as strict as before and corrects a docstring claim, so no entry would help a future diagnosis.
- `scripts/confine-tests.sh --probe` exits 3 here: "confine-tests: NO CONFINEMENT
  PRIMITIVE AVAILABLE — refusing to run." So the suites run through
  `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .`.

## Plan

1. Test first: new bats case pinning the read-route sentence; amend the A1/A2 case so
   the script route must appear only with the reads-only caveat. See them red.
2. Add the sentence to the deny text; add the guard docstring line.
3. Correct the taint docstring and the guide's gap line.
4. Run both hook suites, `test/link-claude-home-wiring.bats`, the hermeticity lint and
   `scripts/health-check.sh`; then pr-prep's review-fix loop.
