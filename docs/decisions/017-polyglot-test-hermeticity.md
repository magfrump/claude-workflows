# 017 — Polyglot test hermeticity: a narrow static lint + a CI netns runner

- **Goal**: Decide how to make hermeticity enforcement — today a bash/BATS-only static lint living inside this repo — applicable to any project and any test language, adoptable gradually.
- **Project state**: claude-workflows main · supersedes the layer-3 half of [014](014-secure-tool-guidance-layers.md) and corrects its spike · composes with [015](015-cc-process-isolation-docker-devcontainer.md)/[016](016-multi-project-devcontainer-central-config.md) · not blocked
- **Task status**: complete (decision made; increment 1 implemented)

## Context

`test/fixture-hermeticity.bats` (014, layer 2) enforces one rule: a bats suite that can reach a
network-capable binary (`claude`, `curl`, `wget`, `gh`) — including transitively, through a sourced repo
script — must stub it in `setup()` or carry `# @network: allowed — <reason>`. It exists because of commit
4d39475: a suite sourced `self-improvement.sh`, which invoked a live, billable `claude -p`.

The request was to make it "applicable across all projects… applicable to tests other than BATS." Two
probes and three ecosystem research passes reframed that request substantially. Full analysis:
`docs/working/dd-polyglot-test-hermeticity.md`.

### The ask hid two orthogonal gaps

The lint is a *bats test* that globs `$REPO_ROOT/test/*.bats`. It cannot lint another repo no matter how
many languages it learns. **Cross-project reach** and **cross-language detection** are independent, and
only the first is load-bearing for "applicable across all projects."

### Four findings that decided it

1. **The 014 layer-3 spike is stale; its primitive is gone.** [observed] It validated nested `bwrap
   --unshare-net` on 2026-07-09 and recommended "Proceed to RPI." Re-probed 2026-07-13: `bwrap` is
   **absent**, `unshare -rn` returns **EPERM** (seccomp blocks `CLONE_NEWUSER`), and `CapEff` is
   **`0000000000000000`**. Cause: 015/016 moved sessions into the `cc-isolated` Docker devcontainer, a
   different boundary than the one the spike measured. **The agent cannot confine its own test runs.**
   This is the spike's own pre-mortem narrative 1 ("platform pulls the rug"), realized in four days,
   before anything was built.

2. **No language has an in-process all-egress blocker, and this is structural.** [observed + researched]
   Python's `socket` is a mutable module attribute, so pytest-socket can monkeypatch it — but it is blind
   to subprocesses, which its maintainer states outright
   ([#401](https://github.com/miketheman/pytest-socket/issues/401): *"the settings are not carried over
   into the subprocess"*; blocking `curl` is *"impractical"*). Rust and Go compile to direct syscalls with
   no interposition point and have **nothing at all**; for Go even `LD_PRELOAD` is structurally dead
   (static linking + raw `SYSCALL` instructions — the same reason proxychains fails on Go binaries).
   Locally confirmed: a pytest-socket-style patch blocks an in-process socket while
   `subprocess.run(["curl", …])` reaches **HTTP 200**.

3. **Statically *proving hermeticity* is undecidable in practice.** [researched] The mock call site is
   byte-identical to the real one — `client.get(url)` looks the same whether `url` is `server.url()` or
   `https://api.stripe.com`, and the URL is a runtime value threaded through a struct field several frames
   away. Deciding it needs interprocedural dataflow across crate boundaries. A linter that answers
   "is this suite hermetic?" would be wrong most of the time, in every language.

4. **But the subprocess rule is decidable everywhere, and nothing else covers it.** `Command::new("curl")`,
   `exec.Command("curl")`, `subprocess.run(["curl"])` are high-precision, greppable, and unblockable by any
   runtime tool in any language. **This is exactly the rule we already have.**

### The scope collapse

Findings 2–4 separate cleanly by *who already covers what*:

| Reach surface | Covered well by | Should the lint detect it? |
|---|---|---|
| In-process HTTP (`requests`, `fetch`, `reqwest`) | ecosystem runtime blockers (pytest-socket, nock, MSW) | **No** — recognizing the *mocks* is finding 3's swamp. Check the *config* for a baseline blocker instead. |
| **Subprocess → network binary** | **nobody, in any language** | **Yes. This is the lint's whole job.** |
| C-extension / raw-native egress | nobody | Out of scope; documented gap. |

So the polyglot lint is **narrower** than the bash one, not broader. That inverts the premise of the
original request: the work is not teaching a detector five new languages, it is deleting the ambition to
detect hermeticity at all and keeping the one rule that generalizes.

## Options considered

Fourteen candidates (full matrix in the DD doc). Survivors scored in step 4:

| Approach | Effort | Risk | Coverage | Key downside |
|----------|--------|------|----------|--------------|
| CLI + bash + Python adapter | ~5h | low | 7/7 hard | 2nd adapter proves the contract, serves no live suite |
| **+ CI netns runner (chosen)** | ~9h | med | 7/7 + real enforcement | touches CI; cannot run in-session (finding 1) |
| CLI + bash only | ~2.5h | low | 6/7 | H1 ("N+1 language is just data") stays untested |
| Full polyglot ×5 | ~2d | med-high | 7/7 | speculative generality ×5; Go should be config, not code |

**Adopt-vs-build gate (CLAUDE.md row 5):** searched the Semgrep registry, ast-grep packs, the pre-commit
index, and the eslint/Ruff/Clippy/golangci-lint catalogs. **Nothing implements this rule.** Nearest
neighbor `matthewdeanmartin/hermetic` is a Python-only *runtime* wrapper (0 stars; author calls it
"defeatable"). Verdict: build. For **Go specifically**, `golangci-lint`'s `depguard` (native `$test`
selector) + `forbidigo` (`analyze-types: true`) can be *configured* into most of this rule with zero new
code — so Go ships as a **config recipe, not an adapter**.

## Decision and rationale

Adopt a **two-layer** design, mirroring the layering 014 established but with the layers reassigned to
where the evidence says they actually work:

1. **Static lint — portable triage, runs everywhere.** Extract the rule from
   `test/fixture-hermeticity.bats` into `scripts/hermeticity-lint`, a dependency-free `python3` CLI
   (the only viable host: no semgrep/ast-grep/ruff in the environment, and no PyYAML). One rule:
   *transitive subprocess-reach to a network-capable binary.* Each language is a **JSON data file** under
   `scripts/hermeticity/adapters/` declaring its spawn grammar, closure grammar, stub patterns, and native
   opt-out markers. Ships with `bash` (a 1:1 port — the 13 existing suites stay green) and `python`.
   Invocable from any repo: `hermeticity-lint --root <repo>`.

2. **Netns runner — the real enforcement, CI-side.** `scripts/confine-tests.sh` runs *any* test command
   under a network namespace (`unshare -rn`, or `bwrap --unshare-net` where present). Language-agnostic by
   construction; it is the only mechanism that denies subprocess and C-extension egress. Per finding 1 it
   **cannot run in the agent's session**, so it is a CI/host-side gate — and its preflight probe **exits
   nonzero and loudly** when the primitive is missing rather than degrading to unconfined.

The lint is **triage**; the runner is **ground truth**. The lint says so itself: it prints the exact
`confine-tests.sh` command as the authoritative check rather than claiming sufficiency.

The verdict is **three-state, never binary** — `NETWORKED` / `STUBBED` / `UNCHECKED` — because no static
pass can prove hermeticity (finding 3), and a binary verdict would be a lie in the common case.

Rationale: this is the only design where each layer is doing something it can actually do. The static lint
covers the one class nothing else covers, in the one environment where the incident actually happened, and
it is pure text processing — so unlike the bwrap harness, no platform change can pull it out from under us
(it already happened once, in four days). The runner covers everything, but only where the kernel lets it.
Attempting a *polyglot hermeticity detector* — the naive reading of the request — would have produced a
tool that is wrong most of the time in Rust and Go.

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard` (IDs from the DD working doc).
Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

[0 status quo]: is the thing being fixed. [1 grep table in the bats suite]: H2 is structural — a bats test in *this* repo cannot lint another repo, so no amount of language grammar fixes it. [2 standalone CLI]: **absorbed** — it is the chosen design, with [3]'s rules-as-data on top. [4 bwrap confine-tests as an in-session gate]: **primitive absent** (finding 1); ⚠ on H5, because it would silently not-enforce. Survives only as CI-side infrastructure → became layer 2. [5 hybrid]: **absorbed** — the chosen design *is* the hybrid, with the enforcement half relocated to CI. [6 ecosystem-native blockers as the gate]: fails H7 outright — blind to subprocess reach in all four languages (finding 2), so adopting it reproduces 4d39475 in a new language. Retained as a *complementary recommendation* (a baseline `--disable-socket` is worth having; it is just not a hermeticity pass). [7 AST/tree-sitter]: not increment 1 — it is the **upgrade path** for a language where grep proves too noisy; the adapter interface deliberately does not preclude an AST-backed matcher. [8 skill]: advisory, not a gate [carried from 014-secure-tool-guidance-layers: *"skills trigger on intent, not tool failure"*]. [9 code-review sub-critic]: not a gate (H5) — but **adopted as a complement**, since it is the only mechanism with cross-project reach at zero cost. [10 PostToolUse hook]: hook sprawl; warns after the fact, gates nothing [same objection as 014's pruned deny-with-guidance hook]. [11 pre-commit]: not a rival detector — a *distribution channel* for layer 1; revive when a consuming project already uses pre-commit. [12 Bazel/Buck]: ⚠ on H4 — a build-system migration is the opposite of gradual. Cited as prior art instead: its `tags=["block-network"]` / `["requires-network"]` is the same annotation shape we chose. [13 devcontainer egress-deny]: **absorbed into layer 2** — same mechanism, scoped to CI. [14 defer/spec-only]: the honest baseline (this repo has zero Python/Rust/TS test suites), declined because H1 — "adding language N+1 is just a data file" — is the user's actual ask and cannot be validated with a single adapter.
[15 nested per-command sandboxes]: **revived from 014, then re-pruned on new evidence.** 014 pruned it for *"WSL2 nested-bwrap fragility"*; the layer-3 spike falsified that objection (nesting worked, ~5 ms overhead) and 014's revisit trigger fired. But the 2026-07-13 re-probe falsified the *spike* — the primitive is gone from the agent's environment entirely. It returns as layer 2, CI-side only.
Prior pruning grep: matches found for [lint, hermetic, test, network, stub] in 014 and 016; both surfaced candidates handled above.

## Stress-test mitigations

- How to read: *Boring alternative* mitigation — collapsed the scope from "polyglot detection engine" to
  "one narrow rule + a data file" after the move showed that the sophisticated version (detecting mocks)
  is undecidable anyway. This demoted the full-polyglot candidate and is the single most consequential
  change the stress test produced.
- How to read: *Failure-driven* mitigation — made the runner's preflight probe **exit nonzero and loud**
  rather than warn-and-continue. Silent degradation is H5's exact failure and the spike's pre-mortem
  narrative 1, which has now demonstrably fired once; a guard that silently stops guarding is worse than
  no guard, which is the whole 4d39475 lesson.
- How to read: *Invert the thesis* mitigation — argued sincerely for bash-only. It survives on one point:
  an adapter contract with exactly one implementation has never been tested, and H1 is the user's actual
  ask. The second adapter is the cheapest possible proof, and it partially falsified its own hypothesis
  (see Consequences).
- How to read: *Push to extreme* mitigation — the rule misses `subprocess.run(["python3", "-c", "import
  requests…"])`. Accepted and **documented** rather than papered over: the lint is triage, the netns runner
  is ground truth. Documenting the gap is what keeps the lint from being mistaken for a proof.

## Consequences

**Easier.** Hermeticity becomes a cross-project convention with a runnable checker instead of a bats test
welded into one repo. Adding a language is a JSON file. The 4d39475 class is caught in *any* language, in
the environment where it actually occurs. CI gains a real, kernel-enforced gate that no static tool can
match. And the annotation grammar — the part that survives turnover — is documented independently of the
implementation.

**Harder.** Two mechanisms now exist where there was one, and they disagree by design (the lint
over-approximates; the runner is exact) — the docs must keep saying which is authoritative. The runner
does not work in the agent's own session, so an agent cannot self-verify hermeticity; that is a real
regression in feedback loop, forced by 015/016. The lint's over-approximation will produce false positives
that must be annotated away.

**H1 was partially falsified, and this is worth recording honestly.** The step-4 hypothesis was *"the
Python adapter lands with ZERO edits to the core."* Outcome: the **matcher** generalized exactly as
predicted (a `spawn_call` proximity matcher serves Python, and will serve Rust/Go/TS unchanged), but the
**closure resolver** did not — Python module resolution needed a second resolver implementation alongside
bash's basename-in-dirs. So "adding a language is pure data" holds for the *detection* half and not for the
*closure* half. Rust (`mod`/`include!`, never `use`) and Go (an `_test.go` file implicitly sees its whole
package directory, with no import statement at all) will each need their own resolver too. The contract is
real but weaker than claimed: **new languages are a data file plus, sometimes, a ~20-line resolver.**

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision.
Future readers can grep this section when their context changes.

if a project with a real pytest/vitest/cargo suite adopts the lint and the false-positive rate exceeds ~1 per 20 suites → escalate that language's adapter from grep to an AST matcher (pruned candidate [7]; for Go, read `sonatard/noctx` first). if `unshare -rn` or `bwrap` becomes available inside the agent's devcontainer again → revive layer 2 as an in-session gate and re-run the 014 layer-3 RPI. if a fourth language is added and it needs a *third* closure resolver → the rules-as-data contract is not paying for itself; collapse to a single AST engine. if a consuming project already runs `pre-commit` → ship pruned candidate [11] as the distribution channel. if Node's `--permission` model is confirmed to propagate into jest/vitest worker threads → a JS-native baseline blocker becomes viable and the JS adapter's config-tier check should look for it. if any suite passes the lint and still makes a live network call → the over-approximation has a hole; escalate to the runner and file the counter-example as a fixture.
