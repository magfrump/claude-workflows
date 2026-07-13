#!/usr/bin/env bash
# devcontainer-session.sh — launch an isolated Claude Code session inside the
# repo's devcontainer (decision 015: CC process isolation via Docker devcontainer).
#
# Run this from the HOST (your normal WSL terminal), never from inside a session:
#   scripts/devcontainer-session.sh            # verify config trust + boundary, then start claude
#   scripts/devcontainer-session.sh --bless    # re-bless .devcontainer/ after YOU reviewed a change
#   scripts/devcontainer-session.sh --probe-only  # run the boundary self-probe and exit
#
# Why the trust manifest exists: the repo (including .devcontainer/ and this
# script) is bind-mounted read-write into the container, so an agent inside a
# session CAN edit the enforcement config. Those edits only take effect at the
# next `devcontainer up` — which this launcher refuses to run unless the
# enforcement files match a manifest stored OUTSIDE the container's view
# (host ~/.config/claude-devcontainer/, never mounted). Tampering is therefore
# caught at the rebuild gate, by a human. Decision 015 requires exactly this:
# "the enforcement that matters lives host-side outside the agent's reach."
#
# Why the boundary self-probe exists (decision 015, failure-driven mitigation):
# a boundary that silently degrades is worse than none. Before claude starts,
# the probe must show (H1) host credentials invisible in-container and
# (egress) default-deny firewall live. Plant the canary once on the host:
#   touch ~/.ssh/canary

set -euo pipefail

# Files whose integrity gates a container (re)build. Everything here executes
# host-side or defines the boundary, so all of it must be human-blessed.
ENFORCEMENT_FILES=(
  ".devcontainer/devcontainer.json"
  ".devcontainer/Dockerfile"
  ".devcontainer/init-firewall.sh"
  "scripts/devcontainer-session.sh"
)

trust_dir() {
  echo "${CLAUDE_DEVC_TRUST_DIR:-$HOME/.config/claude-devcontainer}"
}

manifest_path() {
  local workspace="$1"
  echo "$(trust_dir)/$(basename "$workspace").sha256"
}

compute_manifest() {
  local workspace="$1"
  local f
  for f in "${ENFORCEMENT_FILES[@]}"; do
    if [ ! -f "$workspace/$f" ]; then
      echo "ERROR: enforcement file missing: $f" >&2
      return 1
    fi
    (cd "$workspace" && sha256sum "$f")
  done
}

bless_manifest() {
  local workspace="$1"
  mkdir -p "$(trust_dir)"
  compute_manifest "$workspace" > "$(manifest_path "$workspace")"
  echo "Blessed $(manifest_path "$workspace"):"
  cat "$(manifest_path "$workspace")"
}

# Returns 0 if the enforcement files match the blessed manifest.
check_manifest() {
  local workspace="$1"
  local manifest
  manifest="$(manifest_path "$workspace")"
  if [ ! -f "$manifest" ]; then
    echo "ERROR: no blessed manifest at $manifest" >&2
    echo "Review ${ENFORCEMENT_FILES[*]} yourself, then run: $0 --bless" >&2
    return 1
  fi
  local expected actual
  expected="$(cat "$manifest")"
  actual="$(compute_manifest "$workspace")"
  if [ "$expected" != "$actual" ]; then
    echo "ERROR: enforcement files changed since last bless — refusing to build/launch." >&2
    echo "An agent session may have modified the boundary config. Diff against" >&2
    echo "git and against the manifest, review by hand, then re-bless:" >&2
    echo "    git diff HEAD -- .devcontainer scripts/devcontainer-session.sh" >&2
    echo "    $0 --bless" >&2
    diff <(echo "$expected") <(echo "$actual") >&2 || true
    return 1
  fi
}

# In-container boundary self-probe. Must pass before claude starts.
probe_boundary() {
  local workspace="$1"
  local host_home="${2:-$HOME}"
  local failures=0

  # H1: host home (and the planted ~/.ssh/canary) must be invisible inside.
  if ! devcontainer exec --workspace-folder "$workspace" \
      bash -c "! test -e '$host_home/.ssh/canary' && ! test -d '$host_home'"; then
    echo "PROBE FAIL (H1): host home or ~/.ssh/canary is visible inside the container" >&2
    failures=$((failures + 1))
  fi

  # Egress: default-deny firewall must be live (example.com unreachable).
  if ! devcontainer exec --workspace-folder "$workspace" \
      bash -c "! curl --connect-timeout 5 -s https://example.com >/dev/null 2>&1"; then
    echo "PROBE FAIL (egress): container reached https://example.com — firewall not enforcing" >&2
    failures=$((failures + 1))
  fi

  if [ "$failures" -gt 0 ]; then
    echo "Boundary self-probe FAILED ($failures) — not starting Claude Code." >&2
    return 1
  fi
  echo "Boundary self-probe passed (H1 canary invisible, egress default-deny live)."
}

main() {
  local workspace
  workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  if ! command -v devcontainer >/dev/null 2>&1; then
    echo "ERROR: devcontainer CLI not found. Install on the HOST with:" >&2
    echo "    npm install -g @devcontainers/cli" >&2
    exit 1
  fi

  case "${1:-}" in
    --bless)
      bless_manifest "$workspace"
      exit 0
      ;;
    --probe-only)
      probe_boundary "$workspace"
      exit 0
      ;;
    --help|-h)
      sed -n '2,20p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
  esac

  if [ ! -f "$HOME/.ssh/canary" ]; then
    echo "WARNING: no ~/.ssh/canary on the host — H1 probe is weaker without it." >&2
    echo "Plant it once with: touch ~/.ssh/canary" >&2
  fi

  check_manifest "$workspace"
  devcontainer up --workspace-folder "$workspace"
  # `devcontainer up` on an already-running container skips postStartCommand,
  # so a failed earlier start can leave the firewall unenforced. Re-assert the
  # baked (image-side, not agent-editable) script once, then re-probe.
  if ! probe_boundary "$workspace"; then
    echo "Re-asserting firewall via baked init-firewall.sh, then re-probing ..."
    devcontainer exec --workspace-folder "$workspace" \
      sudo /usr/local/bin/init-firewall.sh
    probe_boundary "$workspace"
  fi
  exec devcontainer exec --workspace-folder "$workspace" claude "$@"
}

# Main-execution guard: allow sourcing for tests without running the launcher.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
