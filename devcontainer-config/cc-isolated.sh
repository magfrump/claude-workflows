#!/usr/bin/env bash
# cc-isolated — launch an isolated Claude Code session in ANY project, from a
# central host-side devcontainer config (decision 016; supersedes the per-repo
# scripts/devcontainer-session.sh from decision 015).
#
# Run from the HOST (your normal WSL terminal), never from inside a session:
#   cc-isolated                          # session for the git repo containing $PWD
#   cc-isolated ~/code/other-project     # session for an explicit repo
#   cc-isolated --register ~/code/api --profile python
#                                        # widen that project's egress, then re-bless
#   cc-isolated --bless                  # re-bless the installed config after YOU reviewed it
#   cc-isolated --probe-only [WS]        # run the boundary self-probe and exit
#   cc-isolated --list                   # show registered projects and their egress
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

# Files whose integrity gates a container (re)build. All of them execute host-side
# or define the boundary. Paths are relative to config_dir. The per-project .profile
# files are included deliberately: a project's egress profile IS boundary config, so
# registering a new project re-blesses, and a profile file appearing by any other
# route is caught at the next launch.
enforcement_files() {
  local cfg
  cfg="$(config_dir)"
  echo "devcontainer.json"
  echo "Dockerfile"
  echo "init-firewall.sh"
  echo "cc-isolated.sh"
  # Sorted globs so the manifest is order-stable. An empty projects/ dir is normal
  # (no project has widened its egress yet), hence the -e guard on each match.
  local f
  (
    cd "$cfg" || return 0
    for f in egress/*.txt; do [ -e "$f" ] && echo "$f"; done | sort
    for f in projects/*.profile; do [ -e "$f" ] && echo "$f"; done | sort
  )
}

compute_manifest() {
  local cfg f
  cfg="$(config_dir)"
  while read -r f; do
    [ -n "$f" ] || continue
    if [ ! -f "$cfg/$f" ]; then
      echo "ERROR: enforcement file missing: $f" >&2
      return 1
    fi
    (cd "$cfg" && sha256sum "$f")
  done < <(enforcement_files)
}

bless_manifest() {
  mkdir -p "$(config_dir)"
  compute_manifest > "$(manifest_path)"
  echo "Blessed $(manifest_path):"
  cat "$(manifest_path)"
}

# Returns 0 if the installed config matches the blessed manifest.
check_manifest() {
  local manifest expected actual
  manifest="$(manifest_path)"
  if [ ! -f "$manifest" ]; then
    echo "ERROR: no blessed manifest at $manifest" >&2
    echo "Review the files in $(config_dir) yourself, then run: $0 --bless" >&2
    return 1
  fi
  expected="$(cat "$manifest")"
  actual="$(compute_manifest)"
  if [ "$expected" != "$actual" ]; then
    echo "ERROR: installed config changed since last bless — refusing to build/launch." >&2
    echo "Something host-side rewrote the boundary config. Review it by hand, then re-bless:" >&2
    echo "    diff -r $(config_dir) <your canonical devcontainer-config/>" >&2
    echo "    $0 --bless" >&2
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
  if [ -e "$ws/lean-toolchain" ] || [ -e "$ws/lakefile.lean" ]; then
    s+=("lean")
  fi
  if [ ${#s[@]} -gt 0 ]; then
    (IFS=,; echo "${s[*]}")
  fi
}

register_project() {
  local ws="$1" profiles="$2" p pid
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
  mkdir -p "$(projects_dir)"
  printf '%s\n' "$profiles" > "$(projects_dir)/$pid.profile"
  echo "Registered $ws"
  echo "  project-id: $pid"
  echo "  egress:     base${profiles:+,$profiles}"
  echo
  echo "Re-blessing (the profile file is boundary config, so it joins the manifest)…"
  bless_manifest
  echo
  echo "Next launch rebuilds the image for the new profile."
}

list_projects() {
  local pd f pid
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

# In-container boundary self-probe. Must pass before claude starts.
probe_boundary() {
  local ws="$1" host_home="${2:-$HOME}"
  local failures=0 pid expected_fp actual_fp
  pid="$(project_id "$ws")"
  local dc=(--workspace-folder "$ws"
            --override-config "$(config_dir)/devcontainer.json"
            --id-label "cc-project=$pid")

  # H1: host home (and the planted ~/.ssh/canary) must be invisible inside.
  if ! devcontainer exec "${dc[@]}" \
      bash -c "! test -e '$host_home/.ssh/canary' && ! test -d '$host_home'"; then
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
  # shellcheck disable=SC2016  # $CC_PROJECT_ID must expand in the CONTAINER (from containerEnv)
  if ! devcontainer exec "${dc[@]}" bash -c '
      m=/home/node/.claude/.cc-project-id
      if [ -f "$m" ]; then
        [ "$(cat "$m")" = "$CC_PROJECT_ID" ]
      else
        printf "%s" "$CC_PROJECT_ID" > "$m"
      fi
  '; then
    echo "PROBE FAIL (H6): /home/node/.claude belongs to a DIFFERENT project —" >&2
    echo "  this container is sharing a credential/memory volume across projects." >&2
    failures=$((failures + 1))
  fi

  # Image provenance: the container must have been built from the CENTRAL Dockerfile.
  # Only it creates /usr/local/share/cc-egress/ and bakes /etc/cc-egress-profile. If
  # the CLI ever resolves the build against the target repo again (the bug that made
  # a repo's own .devcontainer/Dockerfile get built instead — silently baking that
  # repo's agent-writable init-firewall.sh), these are absent or the profile is wrong,
  # and we refuse rather than hand the agent a boundary it wrote itself.
  local want_profile="${CC_EGRESS_PROFILE:-}"
  if ! devcontainer exec "${dc[@]}" bash -c "
      test -r /usr/local/share/cc-egress/base.txt &&
      test -r /etc/cc-egress-profile &&
      [ \"\$(tr -d '[:space:]' < /etc/cc-egress-profile)\" = '$want_profile' ]"; then
    echo "PROBE FAIL (image provenance): this container was NOT built from the central" >&2
    echo "  Dockerfile at $(config_dir) (missing /usr/local/share/cc-egress, or its baked" >&2
    echo "  egress profile is not '${want_profile:-<base only>}'). Refusing: the boundary in this image is" >&2
    echo "  not the one you blessed. Rebuild with:" >&2
    echo "    devcontainer up --remove-existing-container ${dc[*]}" >&2
    failures=$((failures + 1))
  fi

  if [ "$failures" -gt 0 ]; then
    echo "Boundary self-probe FAILED ($failures) — not starting Claude Code." >&2
    return 1
  fi
  echo "Boundary self-probe passed (canary invisible · egress default-deny · workspace identity · volume not shared · image from central Dockerfile)."
}

usage() {
  sed -n '2,28p' "${BASH_SOURCE[0]}"
}

main() {
  local ws_arg="" profiles="" action="launch"

  while [ $# -gt 0 ]; do
    case "$1" in
      --bless)      action="bless"; shift ;;
      --probe-only) action="probe"; shift ;;
      --register)   action="register"; shift ;;
      --list)       action="list"; shift ;;
      --profile)    profiles="${2:-}"; shift 2 ;;
      --help|-h)    usage; exit 0 ;;
      --)           shift; break ;;
      -*)           echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 1 ;;
      *)            ws_arg="$1"; shift ;;
    esac
  done

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

  local dc=(--workspace-folder "$ws"
            --override-config "$(config_dir)/devcontainer.json"
            --id-label "cc-project=$pid")

  if [ "$action" = "probe" ]; then
    probe_boundary "$ws"
    exit 0
  fi

  echo "Project: $ws  (id $pid, egress base${eff_profile:+,$eff_profile})"
  devcontainer up "${dc[@]}"

  # `devcontainer up` on an already-running container skips postStartCommand, so a
  # failed earlier start can leave the firewall unenforced. Re-assert the baked
  # (image-side, not agent-editable) script once, then re-probe.
  if ! probe_boundary "$ws"; then
    echo "Re-asserting firewall via baked init-firewall.sh, then re-probing …"
    devcontainer exec "${dc[@]}" sudo /usr/local/bin/init-firewall.sh
    probe_boundary "$ws"
  fi

  exec devcontainer exec "${dc[@]}" claude
}

# Main-execution guard: allow sourcing for tests without running the launcher.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
