# Unity CLI × cc-isolated — integration options (research notes)

Last verified: 2026-08-22 (updated same day with the Vindler assessment, supplied by the user)
Relevant paths: `devcontainer-config/egress/dotnet.txt`, `devcontainer-config/Dockerfile`, `devcontainer-config/init-firewall.sh`

Status: **research only, no decision.** The Behemoth Arsenal project runs on the
`dotnet` profile (decision log #38) for now. Revisit when the user wants
in-loop Unity test execution; this is a DD (options below have real tradeoffs).

## What shipped upstream (2026-07-20, Unite Seoul)

Three layers ("the CLI manages Unity, the Pipeline package drives it, and eval
reaches inside it" — Unity's VP of Authoring Platform):

- **Unity CLI** — standalone self-contained `unity` binary, 0.1.0 **beta**.
  Editor installs (`unity install 6000.2.10f1 -m android ios webgl`), project
  launch, auth (`unity auth login`), licensing incl. floating + offline,
  cloning, `unity doctor`. Linux RHEL 9 / Ubuntu 22.04+, glibc ≥ 2.34 (node:22
  bookworm has 2.36 ✓). No Hub needed. **Install is `curl | bash` from
  `public-cdn.cloud.unity3d.com` beta channel** — brew/winget/apt planned,
  GitHub Releases blocked on internal approvals. Structured JSON/TSV/NDJSON;
  exit-code contract 0=ok, 1=error, 130=cancelled, **6=tests ran and failed**.
- **`unity test`** — first-party test runner: EditMode/PlayMode via editor
  batchmode, NUnit XML via `--output`, exit code 6 distinguishes "job broke"
  from "tests found something". `unity build` covers Android signing/AAB,
  git-tag versioning, `--allow-dirty-build` gate. **Headless auth via service
  account in env vars**; floating license servers; authenticated-proxy support.
- **`com.unity.pipeline`** (experimental, Unity 6.0 LTS+; `unity pipeline
  install`) — running Editor accepts CLI commands over a **localhost-only HTTP
  API, off by default**, gated by a **bearer token written to
  `Library/Pipeline/.unity-pipeline-port`**. Any static method becomes a
  command via `[CliCommand]`/`[CliArg]`, self-describing (`unity command` lists
  operations). A runtime component reaches a dev-build Player
  (`unity command --runtime`). Never for production builds.
- **eval** — `unity eval "return …;"` compiles C# with Roslyn, runs on the
  Editor main thread, full engine/editor API reach, security-token gated;
  `eval_file` variant; `--runtime` aims at a Player. Command naming still
  shifting (`unity eval` vs `unity command eval`) — trust `unity --help`.
- **MCP**: the CLI ships its own MCP mode (`unity mcp`, setup commands incl.
  Claude Code); supersedes the community Unity MCP; free, unlimited
  connections. Discoverability gap: a CLI hands an agent nothing, so Unity
  ships a `unity-cli` skill (`npx skills add Unity-Technologies/skills`) —
  plan on shipping a skill/AGENTS.md alongside any integration.

## Beta-quality caveats (Vindler, first-days reports)

- **Domain reload regenerates the Pipeline bearer token** (entering Play Mode
  does this), so a client that read the token at start gets permanent 401s
  until restarted. Fix reportedly landed upstream — verify before building on it.
- Editor not fully agent-compatible: sometimes wants foreground focus to
  refresh assets/reload domain; modal dialogs block agents. Mitigation:
  launch with `-automated` (takes default action on every dialog) for
  Pipeline-connected sessions only.
- Performance: ~0.8 s per CLI call vs ~0.05 s for a studio's hand-built
  composable tools (~16×); poor token efficiency raw. Unity adopted that
  project as its optimization baseline, but the gap exists today.
- Vindler's architecture take (matches ours): don't point an agent at the raw
  general-purpose surface — build a **tailored, narrow tool layer** on top
  ([CliCommand]-registered operations with terse outputs; prototype as eval,
  promote to registered commands). Fewer calls, fewer tokens, fewer wrong turns.

## Options for cc-isolated

1. **Status quo (`dotnet` profile).** Editor-independent C# libraries +
   NUnit/xUnit via `dotnet test`. Zero new trust surface. No Unity-test
   coverage in-loop. Correct while the CLI is beta and command names shift.
2. **Host-side editor + Pipeline API, bridged into the container.**
   Sharper picture now: the API is **localhost-bound on the host**, so the
   container cannot reach it via the host /24 without a deliberate host-side
   proxy — good, the default is safe. But note the token file lives at
   `Library/Pipeline/.unity-pipeline-port` **inside the project checkout**: if
   the host editor runs on the same checkout that cc-isolated bind-mounts, the
   sandboxed agent can read the bearer token from /workspace. Token alone ≠
   reachability, but don't treat it as a secret boundary. If this option is
   ever built, the bridge should be exactly Vindler's tailored layer: a
   host-side proxy exposing an allowlisted, tests-and-queries-only command set
   (no `eval`, no arbitrary `[CliCommand]` passthrough), treated as blessed
   boundary config. `eval` into a host process from the sandbox = host compromise.
3. **Editor-in-container.** Strengthened by `unity test` (clean exit-code
   contract, NUnit XML) and env-var service-account auth — both fit headless
   containers well. Remaining blockers: (a) **no pinnable, hash-verifiable
   artifact yet** — `curl | bash` from a rolling beta CDN bucket violates the
   image's pinned-hash discipline (uv/Android/rust); wait for GitHub Releases
   or a stable channel with versioned artifacts, or pin whatever versioned URL
   the CDN bucket exposes; (b) licensing: service accounts may be plan-gated
   (Personal vs Pro — unverified), and a license credential inside the sandbox
   carries the OPENROUTER-style exfil caveat; (c) egress: runtime
   licensing/auth endpoints need enumerating (install CDN is build-time only);
   (d) multi-GB editor layer (Android-SDK reasoning applies: one shared
   content-addressed layer). PlayMode with `-batchmode -nographics`
   (+ `-automated`) covers logic-level tests; GPU-dependent tests won't run.
4. **MCP without Pipeline** — wiring convenience only; combine with 2 or 3.

## Remaining unknowns

- Licensing: does Personal-tier activation work non-interactively in a
  container? Are service accounts plan-gated? Exact runtime license/auth domains.
- Whether the CDN bucket serves versioned, pinnable CLI artifacts (or wait for
  GitHub Releases).
- Whether `unity install` tolerates a root-owned install dir (immutable-
  toolchain pattern), and the editor layer's actual size/build time.
- Whether the domain-reload token fix has actually shipped.

## Recommended sequencing (unchanged, now better-grounded)

Stay on `dotnet` while the surface is beta and command names shift. The useful
host-side experiment costs nothing and de-risks option 3: install the CLI on
the HOST, run `unity test` against Behemoth Arsenal (EditMode first, then
PlayMode with `-nographics`), and note which auth/license prompts appear —
that answers the licensing unknown empirically. When ready to integrate:
spike (pinnable artifact? license domains? headless activation?) → DD across
options 1–3.

## Sources

- unity.com/blog/meet-the-unity-cli · docs.unity.com/en-us/unity-cli (+ release notes)
- gamefromscratch.com/unity-cli-unity-pipeline-game-changers/
- docs.unity3d.com Test Framework `reference-command-line`
- vindler.solutions/blog/unity-cli-agent-automation (full text supplied by the
  user 2026-08-22; quotes Unity Discussions "Announcing the Unity CLI" thread
  for the bug reports and benchmarks)
