#!/usr/bin/env bats
# devcontainer-config/seccomp-cc-sandbox.json (Q-125): Docker's default seccomp
# profile plus exactly one rule, tagged by a `cc-sandbox:` comment, that lets an
# unprivileged bwrap build its namespaces. These tests pin both halves: what was
# added, and that nothing else moved.
#
# UPSTREAM_CANONICAL is the sha256 of moby v28.3.3 profiles/seccomp/default.json in
# canonical form (keys sorted, no whitespace). Reproduce it with:
#   curl -sL https://raw.githubusercontent.com/moby/moby/v28.3.3/profiles/seccomp/default.json \
#     | jq -S -c . | tr -d '\n' | sha256sum
# (raw file sha256 01536f1d1df938ae611eba20d6349e0de7a99b6ecdee1549427a0b01b8301e28).
# Bumping the base means re-deriving the profile and moving this hash in one diff.

UPSTREAM_CANONICAL=7ce699efbba58df5691185a87189ecc0a47ff01c48ec8fc5708465954b672979

setup() {
  PROFILE="$BATS_TEST_DIRNAME/../devcontainer-config/seccomp-cc-sandbox.json"
  DEVC="$BATS_TEST_DIRNAME/../devcontainer-config/devcontainer.json"
}

@test "removing the cc-sandbox rule gives back upstream's default profile exactly" {
  run bash -c "jq -S -c 'del(.syscalls[] | select((.comment // \"\") | startswith(\"cc-sandbox:\")))' '$PROFILE' | tr -d '\n' | sha256sum | cut -d' ' -f1"
  [ "$status" -eq 0 ]
  echo "got $output, want $UPSTREAM_CANONICAL"
  [ "$output" = "$UPSTREAM_CANONICAL" ]
}

@test "exactly one rule is added, an unconditional allow of the five namespace syscalls" {
  run jq -c '[.syscalls[] | select((.comment // "") | startswith("cc-sandbox:"))]' "$PROFILE"
  [ "$status" -eq 0 ]
  echo "$output"
  [ "$(jq 'length' <<< "$output")" -eq 1 ]
  [ "$(jq -c '.[0].names | sort' <<< "$output")" = '["clone","mount","pivot_root","umount2","unshare"]' ]
  [ "$(jq -r '.[0].action' <<< "$output")" = SCMP_ACT_ALLOW ]
  # No args/includes/excludes: a cap-gated or arch-gated variant would silently not apply.
  [ "$(jq -c '.[0] | keys' <<< "$output")" = '["action","comment","names"]' ]
}

@test "setns stays cap-gated and clone3 stays ENOSYS without CAP_SYS_ADMIN" {
  # setns appears only in rules that require CAP_SYS_ADMIN.
  run jq -c '[.syscalls[] | select(.names | index("setns")) | .includes.caps // []]' "$PROFILE"
  echo "$output"
  [ "$output" = '[["CAP_SYS_ADMIN"]]' ]
  # clone3 without SYS_ADMIN is still the upstream ENOSYS (38) rule, not allowed.
  run jq -c '[.syscalls[] | select((.names | index("clone3")) and .action == "SCMP_ACT_ALLOW" and (.includes.caps // [] | index("CAP_SYS_ADMIN") | not))]' "$PROFILE"
  echo "$output"
  [ "$output" = '[]' ]
}

@test "the default action is still deny" {
  [ "$(jq -r '.defaultAction' "$PROFILE")" = SCMP_ACT_ERRNO ]
}

@test "devcontainer.json loads the profile by its absolute config-dir path" {
  grep -qF '"seccomp=${localEnv:CC_CONFIG_DIR}/seccomp-cc-sandbox.json"' "$DEVC"
  grep -qF '"--security-opt",' "$DEVC"
  # The broad alternatives Q-124 ruled out must not appear outside comments.
  run bash -c "grep -vE '^[[:space:]]*//' '$DEVC' | grep -E 'SYS_ADMIN|seccomp=unconfined|systempaths=unconfined|--privileged'"
  echo "$output"
  [ "$status" -eq 1 ]
}
