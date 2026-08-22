# Unity CLI × cc-isolated — integration options (research notes)

Last verified: 2026-08-22
Relevant paths: `devcontainer-config/egress/dotnet.txt`, `devcontainer-config/Dockerfile`, `devcontainer-config/init-firewall.sh`

Status: **research only, no decision.** The Behemoth Arsenal project runs on the
`dotnet` profile (decision log #38) for now. Revisit when the user wants
in-loop Unity test execution; this is a DD (3+ tradeoff-bearing options below).

## What shipped upstream (2026-07-20, Unite Seoul)

- **Unity CLI** — a standalone `unity` binary, separate from the editor/Hub.
  Manages editors, modules, projects, auth, licensing, builds, tests from the
  terminal. Built for automation: JSON/TSV output, exit codes, non-interactive
  installs, service-account auth for CI. Linux: RHEL 9 / Ubuntu 22.04+,
  glibc ≥ 2.34 (node:22 bookworm has 2.36 — the binary would run in our image).
  `unity install lts` fetches an editor headlessly.
- **Unity Pipeline package** (`com.unity.pipeline`, experimental/beta,
  Unity 6.0 LTS+) — turns a *running* editor into an automation target via a
  **local HTTP API**: open scenes, toggle play mode, search objects, and
  `unity command eval` — arbitrary C# executed live inside the editor process,
  no recompile/domain reload.
- **MCP**: `unity mcp configure` registers a Unity MCP server into an agent's
  config in one step; Claude Code is among the 16 supported clients.
- Classic test path unchanged underneath: editor batchmode
  `-runTests -batchmode -projectPath … -testPlatform EditMode|PlayMode`
  (NUnit-format XML results).

## Options for cc-isolated

1. **Status quo (`dotnet` profile).** Editor-independent C# libraries +
   NUnit/xUnit via `dotnet test`. Zero new trust surface. No Unity-test
   coverage in-loop.
2. **Host-side editor + Pipeline HTTP API, bridged into the container.**
   The firewall already allows the host /24 (init-firewall.sh HOST_NETWORK
   rules), so the containerized agent could reach a host-side Pipeline
   endpoint with **no egress change**. ⚠️ **This is the boundary-defeating
   option**: `unity command eval` is arbitrary C# in a HOST process — handing
   that endpoint to the sandboxed agent converts "isolated session" into
   "arbitrary code execution on the host with the editor user's privileges."
   If ever considered, it needs an authenticating, command-allowlisting proxy
   (run-tests-only), not a raw port — and that proxy becomes boundary config.
3. **Editor-in-container.** Bake Unity CLI + a pinned Linux editor at build
   time (`unity install lts`; multi-GB layer, mirrors the Android SDK
   reasoning — shared content-addressed layer). Run EditMode/PlayMode tests
   headless with `-batchmode -nographics`. Needs: a new egress profile for
   Unity **licensing/auth at runtime** (license server + Unity services
   endpoints — enumerate exactly when speccing; download CDN is build-time
   only), a license secret inside the container (same exfil caveat as
   OPENROUTER_API_KEY in devcontainer.json), and a licensing-terms check for
   containerized/CI use (Personal vs Pro; service-account auth may be
   plan-gated). PlayMode tests needing a GPU won't run; -nographics covers
   logic-level PlayMode.
4. **MCP without Pipeline.** `unity mcp configure` inside the container only
   makes sense combined with 2 or 3 — it's a wiring convenience, not an
   integration path by itself.

## Known unknowns (spike before deciding)

- Does the new CLI wrap test-running directly (`unity … test`?) or still shell
  out to editor batchmode? (Docs at docs.unity.com/unity-cli — unreachable
  from the authoring session's egress; read from the host.)
- Exact runtime license/auth domains, and whether Personal-license activation
  works non-interactively in a container.
- Editor layer size and build time; whether `unity install` respects a
  root-owned install dir (our immutable-toolchain pattern).
- Pipeline package maturity — marked experimental; API surface may churn.

## Sources

- unity.com/blog/meet-the-unity-cli · docs.unity.com/en-us/unity-cli
- gamefromscratch.com/unity-cli-unity-pipeline-game-changers/
- docs.unity3d.com Test Framework `reference-command-line`
- vindler.solutions/blog/unity-cli-agent-automation (unread — egress-blocked;
  reportedly a what-works/what's-broken assessment worth reading first)
