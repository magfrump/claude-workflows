Merge branch 'feat/build-loop-u3a1': --check re-hashes what it reads and refuses a second copy of an object; status as values; one gate startup

## What this does

U3a1 of the build-loop handoff (plan step 7's U3 split note: U3 split before code into U3a1, U3a2 `--merge`, U3a3 `--approved`, U3d dispatch), all in `scripts/build-loop.sh`:
- **The decision's objects are verified** (override rows 492, 503, before anything moves main): git checks no object's hash when it reads one, so a same-uid writer rewriting an object file behind its id changed what the gate read (probed: a forged brief blob read back as naming another branch). `store_check` re-hashes main's commit and every tree and blob of its tree once per run (`refuse state objects`, exit 2, before any setting or brief is read), and per brief the tip's commit, its tree and the merge's tree, skipping main's ids.
- **One copy per object id**: git may read either of two copies of an id, and two reads did (review i1 security F1: a second pack holding forged bytes under the brief's id was read by brief_fields while the batch read the genuine copy). Every pack index and loose object file is listed, NUL-ended and following links (dot-named packs, newline-named packs with decoy indexes, linked fan-out directories: review i2 and final security F1), and an id of main's or of the brief's call with a second copy refuses. harden pins `core.multiPackIndex=false` (a multi-pack-index's offset table is a second route to an id, probed); the state gate refuses `objects/info/alternates`.
- **`status_fields`** gives --status's line as values (row 496): check_line reads STATUS and the brief's BRIEF instead of parsing printed text, so the branch and brief re-reads and their two untested refusals are gone (row 625). --status output is byte-identical to main's.
- **`gate_start`** holds the gate's startup order and the real-repo vs gate-repo rule in one place (row 525); one `GATED` flag at the top level.

**Workflow provenance:** RPI (plan revision 4, step 7) → U3 split before code (d5736445) → pr-prep.
← carried from RPI: D6/D7 (the gate decides from main's committed state and the exact merge result), the threat model of rows 492/503 (a same-uid writer to the object store), the gate caller contract.

**Failures prevented:**
- A rewritten loose object, or a forged second copy in a pack (any name git opens), steering a verdict: an ok for a brief whose committed bytes name another branch (each reproduced in review, now refused).
- One brief's refusal carrying to later briefs in the same run under their names (found in review i2, fixed).

## Reviewer's path — start here

1. `store_check` (after `gate_git`), then `gate_start` and check_line's `store_check "$sha" "$tree"` call.
2. `status_fields` and the top of `check_line`.
3. `harden` (core.multiPackIndex), `state_gate` (alternates), the top-level startup lines.
4. `test/scripts/build-loop-check.bats`: "re-hashes what it reads", "second-copy scan lists what git opens", the SHA-256 test's packed cases, the A15 call log, the config-pairs list.

## How to test

- Suites, run serially: build-loop-check 145, build-loop-read 20 (165), plus dev-cycle and fixtures in `scripts/health-check.sh`. Each new case fails on the code before its fix (the forged brief on main; the newline pack on d10cfba8; reviewers executed the others).
- `scripts/health-check.sh` passed at a27f93b6.

## Areas of uncertainty

- **Residuals for Q-103** (rows dated 2026-10-10): objects reached only through history (the tip's parent, check_branch's commits, check_brief's `git log -G` walk, merge bases); a same-uid writer racing the run, which for main's objects spans the whole run (re-hashed once).
- **Behaviour change**: a store holding a legitimate duplicate (overlapping packs) now refuses `--check`; `git repack -ad` clears it. /workspace's 21,742 packed ids have none. A FIFO at a pack index name hangs git and the gate alike (Won't-Fix row).
- **Deferred**: row 512's verdict values (TIP, TREE, verdict) moved to U3a2, their first reader; scan and re-hash cost triggers (store over 500k ids or 50 packs; store_check over 1 s).
- **Commit messages overtaken** (rows): 65007bf8 cites row 625 for both removed refusals (it covers the brief re-read) and row 512 for status_fields (row 496), and says the brief is read once (status_fields reads its blob twice; the removed re-read was self-merge only).
- **Pre-mortem fallback**: not fired (no `auth|crypto|migration` path; under 500 code lines).

Review: 3 iterations plus a confirming pass. i1 (k=1, full panel): 1 Must Fix (A1, second copy) and A2 (found while fixing: an empty skip list read stdin as a file). i2 (k=1, fix range): 1 Must Address (B1, carry-over), B2 listing gaps, fixed. Final (k=3, full panel, Stage 2.5): 1 Must Fix (E1, newline-named pack), fixed; iteration-4 gate decision escalate, resolved under Q-137 as a narrow confirming pass (k=1 fact-check + security over d10cfba8..a27f93b6): clean. Rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a1.md` (loop closed at a27f93b6). 320 changed code lines.
