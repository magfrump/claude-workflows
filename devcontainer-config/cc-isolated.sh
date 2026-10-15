#!/usr/bin/env bash
# cc-isolated — launch an isolated Claude Code session in ANY project, from a
# central host-side devcontainer config (decision 016; supersedes the per-repo
# scripts/devcontainer-session.sh from decision 015).
#
# Run from the HOST (your normal WSL terminal), never from inside a session:
#   cc-isolated                          # session for the git repo containing $PWD
#   cc-isolated ~/code/other-project     # session for an explicit repo
#   cc-isolated --register ~/code/api --profile python
#                                        # SET that project's egress profile (REPLACES any
#                                        # previous grant, never adds to it), then re-bless
#   cc-isolated --bless                  # re-bless the installed config after YOU reviewed it
#   cc-isolated --probe-only [WS]        # (re)build WS from the blessed config, run the
#                                        # boundary self-probe, record it verified live
#   cc-isolated --list                   # registered projects, blessed config, verified?
#   cc-isolated --help                   # this text
# Push a session's commits with cc-push, never with host git in the checkout.
#
# EXIT STATUS (the host tools' convention, decision log #58, plus two scan codes):
#   0  success; after a session: the exit scan found nothing (or only standard
#      linked worktrees, with a note on stderr), and claude's own
#      exit status is passed through — so a 1-4 from claude itself reads like
#      one of the codes below;
#   1  an error, including a launch refused because the scan's baseline could
#      not be taken (the checkout's .git unreadable, not a git dir git accepts,
#      or the root already looking like one) — 1 at launch; at exit an
#      unreadable .git is 4, and an invalid .git or a repository at the root
#      is a finding, 3;
#   2  bad usage;
#   3  the exit scan found a change the session made to what host git reads
#      (replaces claude's status);
#   4  the exit scan could not read everything, or was interrupted (replaces it).
# A clean scan is not permission to run git in the checkout:
# guides/cc-isolated-usage.md, "Known routes it does not see".
#
# WHY THE CONFIG LIVES OUTSIDE THE REPO (decision 016, H2). Under decision 015 the
# boundary config was committed inside each repo, which meant it was bind-mounted
# read-write into the container: a session could edit the boundary it ran under, and
# only the trust manifest (checked at the next rebuild) caught it. Here the config is
# installed to ~/.config/claude-devcontainer/ and passed via `--override-config`, so
# it is in no bind mount at all. Target repos get zero new files. The manifest stays
# as defence-in-depth against HOST-side tampering (e.g. a malicious npm postinstall
# running as you), not against the agent — the agent can no longer see these files.
#
# WHY THE WORKSPACE IS AN ARGUMENT, NOT $BASH_SOURCE. The 015 launcher derived its
# workspace from its own path, so running it from another repo silently opened a
# session on the WRONG repo. Here the workspace comes from the argument or $PWD, and
# the probe asserts in-container that /workspace really is the repo you asked for.
#
# Plant the canary once on the host:  touch ~/.ssh/canary
#
# BLESSED IS NOT VERIFIED. A bless hashes the installed config; it says nothing about
# whether a container built from that config actually works. Two boundary changes
# (decision log #40, #41) shipped with "needs a live-container check before bless" in
# their commit messages and were blessed without one; the bats suites cannot see a
# kernel, so four review passes could not catch it either, and sessions had no DNS
# for six days while every root-run probe passed (#44). So the launcher now keeps a
# second file next to the manifest — verified-live.sha256 — which is written ONLY by
# a passing self-probe against a container whose image bakes the hash of the manifest
# being blessed (CC_CONFIG_HASH build arg -> /etc/cc-config-hash). A launch on an
# unverified config says so, rebuilds the container so the probe exercises the new
# config rather than an old image, and refuses to start a session unless the baked
# firewall script reached its completion marker. See guides/devcontainer-setup.md,
# "Changing the boundary".

set -euo pipefail

config_dir() {
  echo "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"
}

projects_dir() {
  echo "$(config_dir)/projects"
}

manifest_path() {
  echo "$(config_dir)/manifest.sha256"
}

verified_path() {
  echo "$(config_dir)/verified-live.sha256"
}

# Identity of the blessed config: a hash over the manifest itself (which already
# hashes every enforcement file). Baked into the image as /etc/cc-config-hash and
# recorded in verified-live.sha256, so "which config is this container running" and
# "which config passed a live probe" are the same 16 hex characters as `--list` shows.
blessed_hash() {
  local m
  m="$(manifest_path)"
  [ -f "$m" ] || return 1
  sha256sum < "$m" | cut -c1-16
}

# The hash a passing self-probe recorded, or empty.
verified_hash() {
  local v
  v="$(verified_path)"
  [ -f "$v" ] && tr -d '[:space:]' < "$v" || true
}

# 0 iff the blessed config has passed a live self-probe.
is_verified_live() {
  local b v
  b="$(blessed_hash)" || return 1
  v="$(verified_hash)"
  [ -n "$v" ] && [ "$v" = "$b" ]
}

# Called by probe_boundary on a full pass. The probe has by then asserted that the
# container's baked hash equals the blessed one, so the receipt names a config that
# a real container was built from and booted with the firewall complete.
record_verified_live() {
  blessed_hash > "$(verified_path)"
}

# Files whose integrity gates a container (re)build. All of them execute host-side
# or define the boundary. Keep this list and host_tool_files (below) in step with
# install.sh's PAYLOAD: a file that is installed but not hashed is an artefact
# nobody blessed (the SNI proxy shipped that way once; a bats test now pins
# PAYLOAD ⊆ this list ∪ host_tool_files, the two disjoint).
# claude-home/ — the baked skills/hooks payload (scripts 0555, the rest 0444 inside
# the image) — is hashed file by file via a sorted walk; that includes the
# .manifest install.sh writes, so re-running install.sh re-blesses by design. Paths are relative to config_dir. The per-project .profile
# files are included deliberately: a project's egress profile IS boundary config, so
# registering a new project re-blesses, and a profile file appearing by any other
# route is caught at the next launch.
enforcement_files() {
  local cfg
  cfg="$(config_dir)"
  echo "devcontainer.json"
  echo "Dockerfile"
  echo "init-firewall.sh"
  echo "cc-sni-proxy.py"
  echo "link-claude-home.sh"
  echo "cc-isolated.sh"
  # Sorted globs so the manifest is order-stable. An empty projects/ dir is normal
  # (no project has widened its egress yet), hence the -e guard on each match.
  local f
  (
    cd "$cfg" || return 0
    # `[ ! -e ] ||` rather than `[ -e ] &&`: under set -e + pipefail the latter's
    # false status on an empty glob killed this subshell before the walk below.
    for f in egress/*.txt; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
    for f in projects/*.profile; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
    # Regular files AND symlinks: install.sh's cp -r preserves links, the Dockerfile
    # COPYs them, so a repointed link would otherwise change the served payload
    # without changing the manifest (symlinks are hashed by their target text).
    if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) | LC_ALL=C sort; fi
  )
}

compute_manifest() {
  local cfg f
  local -a files=()
  cfg="$(config_dir)"
  local -a links=() listing
  # Capture the listing FIRST so its exit status is checked: a process substitution
  # discards the producer's status by construction, which is how a failing glob
  # loop once truncated the list silently.
  local listing
  listing="$(enforcement_files)" || { echo "ERROR: enforcement_files failed" >&2; return 1; }
  while read -r f; do
    [ -n "$f" ] || continue
    # A symlink is recorded by its target text (a repoint changes the manifest)
    # AND, when it resolves to a regular file, by that file's content — a link to
    # a rewritten file must not stay byte-identical either.
    if [ -L "$cfg/$f" ]; then
      links+=("$f")
      [ -f "$cfg/$f" ] && files+=("$f")
    elif [ ! -f "$cfg/$f" ]; then
      echo "ERROR: enforcement file missing: $f" >&2
      return 1
    else
      files+=("$f")
    fi
  done <<< "$listing"
  [ "${#files[@]}" -gt 0 ] || { echo "ERROR: enforcement file list is empty" >&2; return 1; }
  # One sha256sum for all regular (or link-resolved) files — the claude-home walk
  # is ~100 files and a fork per file made every launch pay for it. Symlink
  # targets are emitted in sha256sum's own two-space format under a `link:` prefix
  # on the path, so the two kinds of line cannot collide.
  (
    cd "$cfg" && sha256sum "${files[@]}"
    for f in "${links[@]}"; do
      printf '%s  link:%s\n' "$(printf '%s' "$(readlink "$f")" | sha256sum | cut -d' ' -f1)" "$f"
    done
  ) | LC_ALL=C sort -k2
}

# Host-only tools (decision log row 71, amending row 45's scope). They run on the
# host, after or outside the container, so no live probe can exercise them and the
# image never copies them: they are not boundary config. They stay in install.sh's
# PAYLOAD and are hashed into their own file, host-tools.sha256, so a change to one
# leaves blessed_hash (the baked config identity), the verified-live receipt and the
# container alone. Each entry point checks the ones it executes (verify_host_tools,
# below and in cc-push.sh). Commits that change them carry `Host-tool-tested:`, not
# `Live-verified:` (hooks/live-verify-gate.sh).
host_tool_files() {
  echo "cc-exit-scan.sh"
  echo "cc-gitdir.sh"
  echo "cc-push.sh"
}

host_tools_path() {
  echo "$(config_dir)/host-tools.sha256"
}

compute_host_tools_manifest() {
  local -a files
  local f
  mapfile -t files < <(host_tool_files)
  for f in "${files[@]}"; do
    [ -f "$(config_dir)/$f" ] || { echo "ERROR: host tool missing: $f" >&2; return 1; }
  done
  (cd "$(config_dir)" && sha256sum "${files[@]}")
}

# --- verify_host_tools: KEEP IN STEP with the copy in cc-push.sh (a test
# compares the two byte for byte). Host-only tools are not boundary config
# (decision log row 71): install.sh's bless hashes them into host-tools.sha256,
# beside manifest.sha256, and each entry point checks the files it is about to
# execute against that file BEFORE sourcing them. DIR is the directory to check:
# an entry point's own resolved directory (`--list` passes config_dir()). Only a
# repo checkout is left unchecked, and it must say so
# positively: install.sh beside the script (install.sh is never installed, it is
# not in PAYLOAD), no manifest of either kind, and not the config dir. Anything
# else is checked, so deleting manifests is not enough to opt an installed copy
# out. Prints the reason and returns 1 on any mismatch.
verify_host_tools() {
  local dir="$1" m f want have cfg
  shift
  m="$dir/host-tools.sha256"
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
  if [ ! -f "$m" ] || [ -L "$m" ]; then
    echo "no host-tool manifest at $m (re-run install.sh, or review the tools and bless this dir)"
    return 1
  fi
  # The manifest itself is the anomaly when it cannot be read or is not
  # sha256sum's own output; say so rather than call every tool changed.
  if [ ! -r "$m" ] || [ ! -s "$m" ] || grep -qvE '^[0-9a-f]{64}  [A-Za-z0-9._-]+$' "$m"; then
    echo "host-tool manifest $m is unreadable or malformed: inspect it before any bless overwrites it"
    return 1
  fi
  # Every file it is given is checked and every mismatch named. (A caller that
  # checks only some host tools does not see the others: the bless prints them.)
  local bad=0
  for f in "$@"; do
    if [ ! -f "$dir/$f" ] || [ -L "$dir/$f" ]; then
      echo "$dir/$f is missing or a symlink"
      bad=1
      continue
    fi
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    if [ -z "$want" ]; then
      echo "host-tool manifest $m has no entry, or more than one, for $f"
      bad=1
      continue
    fi
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
    if [ "$want" != "$have" ]; then
      echo "$dir/$f changed since the last bless"
      bad=1
    fi
  done
  return "$bad"
}
# --- end verify_host_tools

# Both manifests are computed into temp files first and moved into place only when
# both succeed, so a bless that fails to compute either changes neither. The two
# same-directory renames can still split (one fails, or an interrupt lands between
# them): host-tools.sha256 is then new and manifest.sha256 old, so a launch refuses
# if the boundary changed too, and otherwise the host tools stand blessed although
# bless exited 1. Re-run the bless either way. What changed since the previous
# bless is printed first: the bless is the review, and a host-tool refusal that
# points here must not let a boundary change through unseen.
bless_manifest() {
  local new_m new_h
  mkdir -p "$(config_dir)"
  new_m="$(mktemp "$(config_dir)/.manifest.XXXXXX")" || return 1
  new_h="$(mktemp "$(config_dir)/.host-tools.XXXXXX")" || { rm -f "$new_m"; return 1; }
  if ! compute_manifest > "$new_m" || ! compute_host_tools_manifest > "$new_h"; then
    rm -f "$new_m" "$new_h"
    echo "ERROR: nothing blessed." >&2
    return 1
  fi
  local -a olds=("$(manifest_path)" "$(host_tools_path)") news=("$new_m" "$new_h")
  local i
  for i in 0 1; do
    if [ ! -f "${olds[$i]}" ]; then
      echo "No previous $(basename "${olds[$i]}"): every entry below is new to this bless."
      echo
    elif ! cmp -s "${olds[$i]}" "${news[$i]}"; then
      echo "Changed since the last bless ($(basename "${olds[$i]}")):"
      diff "${olds[$i]}" "${news[$i]}" | grep '^[<>]' || true
      echo
    fi
  done
  mv -f "$new_h" "$(host_tools_path)"
  mv -f "$new_m" "$(manifest_path)"
  echo "Blessed $(manifest_path) ($(wc -l < "$(manifest_path)") entries):"
  cat "$(manifest_path)"
  echo
  echo "Blessed host tools in $(host_tools_path) ($(wc -l < "$(host_tools_path)") entries; not boundary config, no probe needed):"
  cat "$(host_tools_path)"
  echo
  echo "Blessed config: $(blessed_hash)"
  if is_verified_live; then
    echo "Verified live:  yes (this exact config has passed a live self-probe before)"
  else
    echo "Verified live:  NO — a bless is a review, not a test. Nothing has run this config."
    echo "  Next: cc-isolated --probe-only <repo>   # rebuilds from it and probes as node"
    echo "  Commits that change the boundary carry a 'Live-verified:' trailer naming this hash."
  fi
}

# The bless command for the dir being checked: names CLAUDE_DEVC_CONFIG_DIR when it
# is set, so a hint printed for a non-default dir does not bless the default one.
bless_cmd() {
  if [ -n "${CLAUDE_DEVC_CONFIG_DIR:-}" ]; then
    printf 'CLAUDE_DEVC_CONFIG_DIR=%q %s --bless' "$CLAUDE_DEVC_CONFIG_DIR" "$0"
  else
    printf '%s --bless' "$0"
  fi
}

# Returns 0 if the installed config matches the blessed manifest.
check_manifest() {
  local manifest expected actual
  manifest="$(manifest_path)"
  if [ ! -f "$manifest" ]; then
    echo "ERROR: no blessed manifest at $manifest" >&2
    echo "Review the files in $(config_dir) yourself, then run: $(bless_cmd)" >&2
    return 1
  fi
  expected="$(cat "$manifest")"
  actual="$(compute_manifest)"
  if [ "$expected" != "$actual" ]; then
    echo "ERROR: installed config changed since last bless — refusing to build/launch." >&2
    echo "Something host-side rewrote the boundary config. Review it by hand, then re-bless:" >&2
    echo "    diff -r $(config_dir) <your canonical devcontainer-config/>" >&2
    echo "    $(bless_cmd)" >&2
    diff <(echo "$expected") <(echo "$actual") >&2 || true
    return 1
  fi
}

# Resolve the target workspace to the git toplevel of the argument (or $PWD).
# Hard requirement H1: never guess, never fall back to some other repo.
resolve_workspace() {
  local start="${1:-$PWD}" top
  if [ ! -d "$start" ]; then
    echo "ERROR: not a directory: $start" >&2
    return 1
  fi
  if ! top="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)"; then
    echo "ERROR: $start is not inside a git repository." >&2
    echo "cc-isolated mounts a repo at /workspace; point it at one:" >&2
    echo "    cc-isolated /path/to/repo" >&2
    return 1
  fi
  echo "$top"
}

# Stable per-project identity, derived from the absolute path. Used for the
# container --id-label and the volume names, so two repos that merely share a
# basename (~/work/app and ~/side/app) can never collide (decision 016, H3).
project_id() {
  printf '%s' "$1" | sha256sum | cut -c1-12
}

# Fingerprint of the repo's CONTENT identity, computed identically on the host and
# inside the container. Deliberately excludes the path: inside, the toplevel is
# always /workspace. This is what catches a wrong or aliased mount.
ws_fingerprint() {
  local ws="$1" head remote
  head="$(git -C "$ws" rev-parse HEAD 2>/dev/null || echo 'no-head')"
  remote="$(git -C "$ws" config --get remote.origin.url 2>/dev/null || echo 'no-remote')"
  printf '%s|%s' "$head" "$remote" | sha256sum | cut -c1-16
}

# Egress profiles for a project, as a comma-separated string ("" = base only).
project_profile() {
  local pf
  pf="$(projects_dir)/$(project_id "$1").profile"
  if [ -r "$pf" ]; then
    tr -d '[:space:]' < "$pf"
  fi
}

# Suggest (never auto-apply) profiles from what's in the repo. Auto-applying would
# let a repo's contents choose its own egress, which is exactly the authority an
# untrusted workspace must not have.
suggest_profiles() {
  local ws="$1"
  local -a s=()
  # `if` blocks rather than `[ ... ] && s+=(...)`: under `set -e` an AND-list whose
  # test fails returns non-zero and would kill the script on a repo that simply
  # isn't a Python project.
  if [ -e "$ws/pyproject.toml" ] || [ -e "$ws/requirements.txt" ] || [ -e "$ws/setup.py" ]; then
    s+=("python")
  fi
  if [ -e "$ws/Cargo.toml" ]; then
    s+=("rust")
  fi
  # Lean: `lakefile.toml` is the current Lake manifest format and `lakefile.lean` the
  # older one; `lean-toolchain` catches a project that has one but no lakefile yet.
  if [ -e "$ws/lean-toolchain" ] || [ -e "$ws/lakefile.lean" ] || [ -e "$ws/lakefile.toml" ]; then
    s+=("lean")
  fi
  # Gradle/Android: the wrapper (gradlew) or any Gradle build script. Groovy and
  # Kotlin DSL variants both count.
  if [ -e "$ws/gradlew" ] || [ -e "$ws/build.gradle" ] || [ -e "$ws/build.gradle.kts" ] || \
     [ -e "$ws/settings.gradle" ] || [ -e "$ws/settings.gradle.kts" ]; then
    s+=("android")
  fi
  # .NET / Unity: a Unity project root (ProjectSettings/ProjectVersion.txt or
  # Packages/manifest.json) or any top-level solution/project file. compgen -G
  # is the glob test: it returns non-zero on no match without tripping set -e
  # inside an `if` condition.
  if [ -e "$ws/ProjectSettings/ProjectVersion.txt" ] || [ -e "$ws/Packages/manifest.json" ] || \
     compgen -G "$ws/*.sln" >/dev/null || compgen -G "$ws/*.csproj" >/dev/null; then
    s+=("dotnet")
  fi
  if [ ${#s[@]} -gt 0 ]; then
    (IFS=,; echo "${s[*]}")
  fi
}

register_project() {
  local ws="$1" profiles="$2" p pid prev
  pid="$(project_id "$ws")"
  # Validate every named profile against the canonical egress/ dir before writing,
  # so a typo is caught here rather than at container start.
  for p in $(echo "$profiles" | tr ',' ' '); do
    if [ ! -r "$(config_dir)/egress/$p.txt" ]; then
      echo "ERROR: unknown egress profile '$p'. Available:" >&2
      local avail
      for avail in "$(config_dir)"/egress/*.txt; do
        [ -e "$avail" ] && echo "    $(basename "$avail" .txt)" >&2
      done
      return 1
    fi
  done
  # --profile SETS the grant; it does not add to it. That is deliberate — a boundary
  # you can only ever widen is not a boundary, and hand-editing files under
  # projects/ would be the only way to narrow one. What is NOT acceptable is doing
  # it silently: re-registering to add `lean` to a project that already had `dotnet`
  # drops `dotnet`, and the symptom lands much later as a network outage inside the
  # container with nothing pointing back here. So read the previous grant first and
  # print the transition, not just the result.
  prev="$(project_profile "$ws")"
  mkdir -p "$(projects_dir)"
  printf '%s\n' "$profiles" > "$(projects_dir)/$pid.profile"
  echo "Registered $ws"
  echo "  project-id: $pid"
  if [ "$prev" = "$profiles" ]; then
    echo "  egress:     base${profiles:+,$profiles} (unchanged)"
  else
    echo "  egress:     base${prev:+,$prev}  ->  base${profiles:+,$profiles}"
    # Name what was dropped explicitly. "base,dotnet -> base,lean" is only legible
    # if you were already looking for the difference.
    for p in $(echo "$prev" | tr ',' ' '); do
      case ",$profiles," in
        *",$p,"*) ;;
        *) echo "  NOTE:       '$p' was granted before and is NOT in the new profile." ;;
      esac
    done
  fi
  echo
  echo "Re-blessing (the profile file is boundary config, so it joins the manifest)…"
  bless_manifest
  echo
  echo "Next launch rebuilds the image for the new profile."
}

list_projects() {
  local pd f pid b
  if b="$(blessed_hash)"; then
    if is_verified_live; then
      echo "Blessed config $b — verified live: yes"
    else
      echo "Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"
    fi
  else
    echo "No blessed config (run devcontainer-config/install.sh)."
  fi
  # Each entry point's file list: the launcher refuses on the two files it
  # executes (and only warns on cc-push); cc-push refuses on itself and
  # cc-gitdir.sh. Checked in config_dir(); an entry point checks its own dir,
  # which differs whenever the command run is not the copy in config_dir() (a
  # repo checkout, or CLAUDE_DEVC_CONFIG_DIR naming another dir or unset for a
  # custom install).
  local cfg_real lerr="" perr=""
  # Not a bare assignment: readlink -f fails when the dir's parent is missing,
  # and under set -e that would end --list silently.
  cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"
  lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true
  perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true
  if [ ! -e "$(host_tools_path)" ]; then
    echo "No blessed host tools (review them, then run: $(bless_cmd))."
  elif [ -z "$lerr" ] && [ -z "$perr" ]; then
    echo "Host tools — match the bless ($(host_tool_files | tr '\n' ' ' | sed 's/ $//'))"
  else
    echo "Host tools — CHANGED (review, then run: $(bless_cmd))"
    if [ -n "$lerr" ]; then
      printf '  launches refuse: %s\n' "${lerr//$'\n'/; }"
    else
      echo "  launches warn (cc-push changed) but run"
    fi
    # An intact cc-push refuses on this; a copy that dropped its own check would
    # not, so the line says what to do rather than predicting what cc-push does.
    if [ -n "$perr" ]; then printf '  cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses): %s\n' "${perr//$'\n'/; }"; fi
  fi
  echo
  pd="$(projects_dir)"
  if [ ! -d "$pd" ] || [ -z "$(ls -A "$pd" 2>/dev/null)" ]; then
    echo "No projects registered (all run with the base egress profile)."
    return 0
  fi
  printf '%-14s  %s\n' "PROJECT-ID" "EGRESS (base + …)"
  for f in "$pd"/*.profile; do
    pid="$(basename "$f" .profile)"
    printf '%-14s  %s\n' "$pid" "$(tr -d '[:space:]' < "$f")"
  done
  echo
  echo "Project-ids are sha256 prefixes of the repo's absolute path."
}

# The rebuild instruction printed by every "this container is not the one you
# blessed" error. $1 = workspace, $2.. = the devcontainer CLI args.
#
# WHY THIS IS NOT A BARE `devcontainer up` STRING. devcontainer.json reads
# CC_PROJECT_ID, CC_PROJECT_NAME, CC_CONFIG_DIR, CC_EGRESS_PROFILE and CC_CONFIG_HASH
# through `${localEnv:...}`, and main() is the only thing that sets them. A bare
# `devcontainer up --remove-existing-container` copied out of an error message and
# run from your own shell therefore resolves them all to the EMPTY string: an empty
# CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty
# /etc/cc-config-hash (a silently NARROWER boundary — nothing fails closed, nothing
# warns; measured 2026-09-15: a re-registered `lean` profile had no effect for
# exactly this reason, base's 9 names instead of base+lean's 14); an empty
# CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR
# points the build at /Dockerfile.
#
# The remaining localEnv reads are not emitted on purpose: TZ has a default in
# devcontainer.json, and OPENROUTER_API_KEY / GH_TOKEN are opt-in credentials the
# user exports themselves — printing them would put secrets on the terminal.
#
# So: name the launcher first, because it is the path that cannot get this wrong, and
# if the by-hand form is used at all, emit it with EVERY launcher-set assignment
# already filled in. Values and args are shell-quoted (printf %q) so a workspace path
# with spaces or metacharacters copies out as one word, never as shell source.
rebuild_hint() {
  local ws="$1" var assigns=""
  shift
  echo "    cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches" >&2
  echo "  or by hand — ALL of these assignments are required, devcontainer.json reads them via localEnv:" >&2
  for var in CC_PROJECT_ID CC_PROJECT_NAME CC_CONFIG_DIR CC_EGRESS_PROFILE CC_CONFIG_HASH; do
    assigns+="$var=$(printf '%q' "${!var:-}") "
  done
  echo "    ${assigns}\\" >&2
  echo "      devcontainer up --remove-existing-container$(printf ' %q' "$@")" >&2
}

# 0 iff the running container's baked config hash equals the blessed one.
container_config_matches() {
  local have
  have="$(devcontainer exec "$@" cat /etc/cc-config-hash 2>/dev/null | tr -d '[:space:]' || true)"
  [ -n "${CC_CONFIG_HASH:-}" ] && [ "$have" = "$CC_CONFIG_HASH" ]
}

# In-container boundary self-probe. Must pass before claude starts.
probe_boundary() {
  local ws="$1" host_home="${2:-$HOME}"
  local failures=0 pid expected_fp actual_fp
  pid="$(project_id "$ws")"
  local dc=(--workspace-folder "$ws"
            --override-config "$(config_dir)/devcontainer.json"
            --id-label "cc-project=$pid")

  # H1: host home (and the planted ~/.ssh/canary) must be invisible inside.
  # host_home is passed as a positional arg (expands to $1 in the CONTAINER), not
  # interpolated into the shell string — so a home path containing shell
  # metacharacters can never become shell source (VULN-02 / decision 018).
  # shellcheck disable=SC2016  # single-quoted on purpose: $1 expands in the CONTAINER
  if ! devcontainer exec "${dc[@]}" \
      bash -c '! test -e "$1/.ssh/canary" && ! test -d "$1"' _ "$host_home"; then
    echo "PROBE FAIL (H1): host home or ~/.ssh/canary is visible inside the container" >&2
    failures=$((failures + 1))
  fi

  # Egress: default-deny firewall must be live (example.com unreachable).
  if ! devcontainer exec "${dc[@]}" \
      bash -c "! curl --connect-timeout 5 -s https://example.com >/dev/null 2>&1"; then
    echo "PROBE FAIL (egress): container reached https://example.com — firewall not enforcing" >&2
    failures=$((failures + 1))
  fi

  # Workspace identity: /workspace must be a git toplevel AND be the repo we meant.
  # This is what catches an --id-label alias silently attaching us to another
  # project's container (decision 016 stress test, Failure-driven).
  expected_fp="$(ws_fingerprint "$ws")"
  # shellcheck disable=SC2016  # single-quoted on purpose: this expands in the CONTAINER, not here
  actual_fp="$(devcontainer exec "${dc[@]}" bash -c '
      set -e
      [ "$(git -C /workspace rev-parse --show-toplevel 2>/dev/null)" = "/workspace" ] || exit 1
      head=$(git -C /workspace rev-parse HEAD 2>/dev/null || echo no-head)
      remote=$(git -C /workspace config --get remote.origin.url 2>/dev/null || echo no-remote)
      printf "%s|%s" "$head" "$remote" | sha256sum | cut -c1-16
  ' 2>/dev/null | tr -d '\r\n' || true)"
  if [ "$actual_fp" != "$expected_fp" ]; then
    echo "PROBE FAIL (workspace): /workspace is not the repo you asked for." >&2
    echo "  expected fingerprint $expected_fp (from $ws)" >&2
    echo "  container reports    ${actual_fp:-<none>}" >&2
    failures=$((failures + 1))
  fi
  if [ "$expected_fp" = "$(printf 'no-head|no-remote' | sha256sum | cut -c1-16)" ]; then
    echo "WARNING: $ws has no commits and no remote — the workspace-identity check is weak." >&2
  fi

  # H6: this project's ~/.claude volume must not be shared with another project.
  # First run stamps the volume; later runs assert the stamp matches.
  # The expected id is the HOST's $pid, passed as a positional arg ($1 in the
  # CONTAINER) the way H1/provenance pass theirs. It used to be the container's own
  # $CC_PROJECT_ID, which made the check self-referential: an empty or wrong
  # containerEnv stamped/compared "" = "" (or wrong = wrong) and passed (audit
  # 2026-09-18, D2). The container's CC_PROJECT_ID must also equal it, since the
  # volume name is derived from the same localEnv value.
  # shellcheck disable=SC2016  # single-quoted on purpose: $1 expands in the CONTAINER
  if ! devcontainer exec "${dc[@]}" bash -c '
      m=/home/node/.claude/.cc-project-id
      [ -n "$1" ] && [ "${CC_PROJECT_ID:-}" = "$1" ] || exit 1
      if [ -f "$m" ]; then
        [ "$(cat "$m")" = "$1" ]
      else
        printf "%s" "$1" > "$m"
      fi
  ' _ "$pid"; then
    echo "PROBE FAIL (H6): /home/node/.claude belongs to a DIFFERENT project (or the" >&2
    echo "  container's CC_PROJECT_ID is not '$pid') — this container may be sharing a" >&2
    echo "  credential/memory volume across projects." >&2
    failures=$((failures + 1))
  fi

  # Image provenance: the container must have been built from the CENTRAL Dockerfile.
  # Only it creates /usr/local/share/cc-egress/ and bakes /etc/cc-egress-profile. If
  # the CLI ever resolves the build against the target repo again (the bug that made
  # a repo's own .devcontainer/Dockerfile get built instead — silently baking that
  # repo's agent-writable init-firewall.sh), these are absent or the profile is wrong,
  # and we refuse rather than hand the agent a boundary it wrote itself.
  local want_profile="${CC_EGRESS_PROFILE:-}"
  # want_profile is passed as a positional arg (expands to $1 in the CONTAINER),
  # not interpolated into the shell string (VULN-02 / decision 018).
  # shellcheck disable=SC2016  # single-quoted on purpose: $1 expands in the CONTAINER
  if ! devcontainer exec "${dc[@]}" bash -c '
      test -r /usr/local/share/cc-egress/base.txt &&
      test -r /etc/cc-egress-profile &&
      [ "$(tr -d "[:space:]" < /etc/cc-egress-profile)" = "$1" ]' _ "$want_profile"; then
    echo "PROBE FAIL (image provenance): this container was NOT built from the central" >&2
    echo "  Dockerfile at $(config_dir) (missing /usr/local/share/cc-egress, or its baked" >&2
    echo "  egress profile is not '${want_profile:-<base only>}'). Refusing: the boundary in this image is" >&2
    echo "  not the one you blessed. Rebuild with:" >&2
    rebuild_hint "$ws" "${dc[@]}"
    failures=$((failures + 1))
  fi

  # Config identity: the image must have been built from the config that is blessed
  # NOW. `devcontainer up` reuses an existing container and never rebuilds, so after
  # a re-bless the running container is silently the OLD boundary until someone
  # passes --remove-existing-container; main() does that when this check fails.
  local want_hash="${CC_CONFIG_HASH:-}" have_hash
  have_hash="$(devcontainer exec "${dc[@]}" cat /etc/cc-config-hash 2>/dev/null | tr -d '[:space:]' || true)"
  if [ -z "$want_hash" ] || [ "$have_hash" != "$want_hash" ]; then
    echo "PROBE FAIL (config identity): this container was built from config '${have_hash:-<none>}'," >&2
    echo "  but the blessed config is '${want_hash:-<none>}'. The boundary it runs is not the one" >&2
    echo "  you blessed. Rebuild with:" >&2
    rebuild_hint "$ws" "${dc[@]}"
    failures=$((failures + 1))
  fi

  # Firewall completion: the baked init-firewall.sh must have reached its sentinel on
  # its LAST run. It fails closed, and a closed container passes every egress check
  # above while `node` has no DNS and no HTTPS — the 2026-09-09 outage looked exactly
  # like a healthy boundary from here. The marker is root-only and removed before
  # every flush, so it vouches for the current ruleset, not an earlier one.
  if ! devcontainer exec "${dc[@]}" test -f /run/cc-firewall/complete; then
    echo "PROBE FAIL (firewall): init-firewall.sh did not complete on this container." >&2
    echo "  It fails CLOSED, so egress looks denied — but node has no network either." >&2
    echo "  Read its output (devcontainer up / postStartCommand log), or re-run it inside:" >&2
    echo "    sudo /usr/local/bin/init-firewall.sh" >&2
    failures=$((failures + 1))
  fi

  if [ "$failures" -gt 0 ]; then
    echo "Boundary self-probe FAILED ($failures) — not starting Claude Code." >&2
    return 1
  fi
  record_verified_live
  echo "Boundary self-probe passed (canary invisible · egress default-deny · workspace identity · volume not shared · image from central Dockerfile · config $want_hash · firewall complete)."
  echo "Recorded config $want_hash as verified live in $(verified_path)."
}

# The session-exit scan (git_exec_snapshot, git_exit_scan, scan_interrupted,
# logical_workspace and their helpers) lives in cc-exit-scan.sh, next to this
# file. readlink -f: the command on PATH is a symlink to the installed copy.
# Both it and the cc-gitdir.sh it sources are host tools, checked against
# host-tools.sha256 first: sourcing runs a file's top level. When the check fails
# the scan is not loaded, and main refuses every action but --bless and --list
# (--help and usage errors are answered first; neither touches the scan).
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
HOST_TOOLS_ERR=""
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
  # shellcheck source=cc-exit-scan.sh
  source "$CC_ISOLATED_DIR/cc-exit-scan.sh"
else
  HOST_TOOLS_ERR="${HOST_TOOLS_ERR:-host-tool check failed}"
fi

# usage: the header comment block, from line 2 to the first line that is not a
# comment (cc-push's approach), so it cannot end mid-sentence when the block grows.
usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"
}

main() {
  local ws_arg="" profiles="" action="launch"

  while [ $# -gt 0 ]; do
    case "$1" in
      --bless)      action="bless"; shift ;;
      --probe-only) action="probe"; shift ;;
      --register)   action="register"; shift ;;
      --list)       action="list"; shift ;;
      --profile)
        # A bare trailing --profile used to die silently in `shift 2` under set -e.
        if [ $# -lt 2 ]; then
          echo "ERROR: --profile needs a value, e.g. --profile python (comma-separate several)." >&2
          usage >&2
          exit 2
        fi
        profiles="$2"; shift 2 ;;
      --help|-h)    usage; exit 0 ;;
      --)           shift; break ;;
      -*)           echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 2 ;;
      *)            ws_arg="$1"; shift ;;
    esac
  done

  if [ -n "$HOST_TOOLS_ERR" ] && [ "$action" != "bless" ] && [ "$action" != "list" ]; then
    echo "ERROR: host-tool check failed — refusing to launch, probe or register:" >&2
    while IFS= read -r line; do printf '  %s\n' "$line"; done <<< "$HOST_TOOLS_ERR" >&2
    # Never let this refusal hide a boundary change: run the boundary check too, and
    # show its diff, before pointing at a bless that would accept both.
    local line boundary_note="The boundary config is unchanged: the re-bless changes no boundary state, so it causes no rebuild (a config not yet verified live is still probed at its next launch, as before)."
    if ! CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest; then
      boundary_note="The BOUNDARY config changed too (above). Review that diff as well: the re-bless accepts both, and the next launch then rebuilds and probes."
    fi
    local push_err
    # Only a cc-push.sh-specific reason: a manifest-level one is already above.
    if ! push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)" && [[ "$push_err" == *cc-push.sh* ]]; then
      printf '  also changed — do not run cc-push until re-blessed: %s\n' "${push_err//$'\n'/; }" >&2
    fi
    echo "  Review the host tools in $CC_ISOLATED_DIR, then re-bless (it prints what changed):" >&2
    printf '    %s\n' "$(CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" bless_cmd)" >&2
    echo "  $boundary_note" >&2
    exit 1
  fi
  # cc-push is not executed by the launcher, so a change to it never blocks a launch,
  # but the launcher still says so: cc-push's self-check cannot catch a tampered
  # cc-push that skips it.
  local push_err
  if [ "$action" != "bless" ] && [ "$action" != "list" ] \
     && ! push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)"; then
    echo "WARNING: $push_err — do not run cc-push until you have reviewed it and re-blessed." >&2
  fi

  if ! command -v devcontainer >/dev/null 2>&1 && [ "$action" != "bless" ] && [ "$action" != "list" ]; then
    echo "ERROR: devcontainer CLI not found. Install on the HOST with:" >&2
    echo "    npm install -g @devcontainers/cli" >&2
    exit 1
  fi

  case "$action" in
    bless) bless_manifest; exit 0 ;;
    list)  list_projects;  exit 0 ;;
  esac

  local ws pid
  ws="$(resolve_workspace "$ws_arg")"
  pid="$(project_id "$ws")"

  if [ "$action" = "register" ]; then
    register_project "$ws" "$profiles"
    exit 0
  fi

  # Egress profile is read from HOST-side registration only — never from the repo.
  local eff_profile suggestion
  eff_profile="$(project_profile "$ws")"
  if [ -z "$eff_profile" ]; then
    suggestion="$(suggest_profiles "$ws")"
    if [ -n "$suggestion" ]; then
      echo "NOTE: $ws is unregistered — running with the base egress profile only."
      echo "      Its contents suggest: --profile $suggestion"
      echo "      To grant that: cc-isolated --register '$ws' --profile $suggestion"
    fi
  fi

  CC_PROJECT_ID="$pid"
  CC_PROJECT_NAME="$(basename "$ws")"
  CC_EGRESS_PROFILE="$eff_profile"
  # devcontainer.json anchors build.dockerfile/build.context to this. It MUST be
  # absolute: under --override-config the CLI resolves relative build paths against
  # the *target repo's* .devcontainer/, not against the config dir (see the comment
  # in devcontainer.json). Unset, the build context would silently become the repo.
  CC_CONFIG_DIR="$(config_dir)"
  export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR

  if [ ! -f "$HOME/.ssh/canary" ]; then
    echo "WARNING: no ~/.ssh/canary on the host — the H1 probe is weaker without it." >&2
    echo "Plant it once with: touch ~/.ssh/canary" >&2
  fi

  check_manifest

  # Baked into the image (devcontainer.json build arg) and compared by the probe.
  CC_CONFIG_HASH="$(blessed_hash)"
  export CC_CONFIG_HASH

  local dc=(--workspace-folder "$ws"
            --override-config "$(config_dir)/devcontainer.json"
            --id-label "cc-project=$pid")

  # Baseline for the exit scan, taken before the container is (re)started. A repo
  # whose .git cannot be read here could not be scanned at exit either, so refuse.
  # The reason can name files an earlier session chose, so it goes through scan_vis.
  local git_before="" snap_err lws
  lws="$(logical_workspace "$ws_arg" "$ws")"
  if [ "$action" = "launch" ]; then
    snap_err="$(mktemp)"
    # A .git git would not accept, or a root that looks like a git dir, is refused
    # rather than recorded: as the baseline it would hide a plant already there
    # (an earlier session's emptied HEAD, a repository at the root) from the scan.
    if ! launch_gitdir_ok "$ws" 2>"$snap_err"; then
      {
        echo "ERROR: refusing to launch on $ws: $(cat "$snap_err")."
        echo "  The session-exit scan compares against the checkout as it is at launch, so"
        echo "  this state would become its baseline and go unreported. Restore .git"
        echo "  (compare with a fresh clone) or remove what is at the checkout root, then"
        echo "  rerun. Do not run host git in the checkout meanwhile."
      } | scan_vis >&2
      rm -f "$snap_err"
      exit 1
    fi
    if ! git_before="$(git_exec_snapshot "$ws" "$lws" 2>"$snap_err")"; then
      {
        echo "ERROR: could not snapshot $ws/.git for the session-exit scan: $(cat "$snap_err")"
        echo "  cc-isolated checks at exit that the session changed nothing host git reads to"
        echo "  decide what to run; without a complete baseline it cannot. Fix the checkout"
        echo "  (an unreadable or unlistable path above), then rerun."
      } | scan_vis >&2
      rm -f "$snap_err"
      exit 1
    fi
    rm -f "$snap_err"
  fi

  if ! is_verified_live; then
    echo "NOTE: blessed config $CC_CONFIG_HASH has NOT been verified in a live container."
    echo "      This run is that verification: the container is rebuilt from it, and the"
    echo "      self-probe must pass (including the node-run firewall probes) before anything"
    echo "      starts. A pass records the hash in $(verified_path)."
  fi

  echo "Project: $ws  (id $pid, egress base${eff_profile:+,$eff_profile}, config $CC_CONFIG_HASH)"
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always rebuilds: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi

  devcontainer up "${dc[@]}"

  # `devcontainer up` never rebuilds an existing container. If the config was
  # re-blessed since this one was built, it is running the previous boundary;
  # recreate it (the ~/.claude volume and the repo are unaffected).
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi

  # `devcontainer up` on an already-running container skips postStartCommand, so a
  # failed earlier start can leave the firewall unenforced. Re-assert the baked
  # (image-side, not agent-editable) script once, then re-probe.
  if ! probe_boundary "$ws"; then
    echo "Re-asserting firewall via baked init-firewall.sh, then re-probing …"
    # Check the status. init-firewall.sh fails CLOSED (its EXIT trap forces DROP
    # policies on any incomplete run), so a container whose very first run died on a
    # transient outage carries DROP with no accept rules — and cannot bootstrap
    # again, because the script's own GitHub/DNS reads are then blocked. That state
    # is safe but terminal, and it is invisible here unless the status is read: every
    # probe_boundary check PASSES against a fully-DROP container (the canary is still
    # hidden, egress is still denied), so the probe alone cannot distinguish "locked
    # down correctly" from "bricked closed". Say so, and name the way out.
    if ! devcontainer exec "${dc[@]}" sudo /usr/local/bin/init-firewall.sh; then
      echo "ERROR: init-firewall.sh failed. It fails closed, so this container may now" >&2
      echo "  have DROP policies with no accept rules and be unable to rebuild them." >&2
      echo "  Recreate it (the ~/.claude volume and your repo are not affected):" >&2
      rebuild_hint "$ws" "${dc[@]}"
      return 1
    fi
    probe_boundary "$ws"
  fi

  # Not `exec`: the launcher has to outlive claude to run the exit scan. The INT
  # trap keeps a Ctrl-C that ends the session from also killing the launcher
  # before the scan (a trapped signal, unlike an ignored one, is reset to its
  # default in the child, so claude still gets its own Ctrl-C).
  local rc=0
  trap ':' INT
  devcontainer exec "${dc[@]}" claude || rc=$?
  # A Ctrl-C during the scan (it can take a while on a large or hostile checkout)
  # ends it; an unfinished scan is no scan, so say so and exit 4, never 0.
  trap scan_interrupted INT
  local scan=0
  git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
  trap - INT
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
}

# Main-execution guard: allow sourcing for tests without running the launcher.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
