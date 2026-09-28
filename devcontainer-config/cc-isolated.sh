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
# or define the boundary. Keep this list in step with install.sh's PAYLOAD: a file
# that is installed but not hashed is a boundary artefact nobody blessed (the SNI
# proxy shipped that way once; a bats test now pins PAYLOAD ⊆ this list).
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
  echo "cc-push.sh"
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

bless_manifest() {
  mkdir -p "$(config_dir)"
  compute_manifest > "$(manifest_path)"
  echo "Blessed $(manifest_path) ($(wc -l < "$(manifest_path)") entries):"
  cat "$(manifest_path)"
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

# logical_workspace <start> <ws>: the checkout <ws> (physical, as git reports it)
# by the path you reached it on — <start> (or $PWD) with symlinks unresolved, up
# to the toplevel — or nothing when that route is not recoverable. Host git
# matches your includeIf "gitdir:" patterns against this form as well as the
# physical one, so the exit scan has to (the scan's _snap_cond).
logical_workspace() {
  local start="${1:-$PWD}" ws="$2" lstart pstart rel
  lstart="$(cd "$start" 2>/dev/null && pwd -L)" || return 0
  pstart="$(cd "$start" 2>/dev/null && pwd -P)" || return 0
  case "$pstart" in
    "$ws")   rel="" ;;
    "$ws"/*) rel="${pstart#"$ws"}" ;;
    *) return 0 ;;
  esac
  case "$lstart" in *"$rel") printf '%s' "${lstart%"$rel"}" ;; esac
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

# --- Exit scan: a tripwire for .git changes the container made -------------------
#
# WHY (Q-069 [3], Q-076). The container writes the checkout's .git through the bind
# mount. A plain host `git push` or `git status` then runs whatever hooks,
# core.fsmonitor, filter drivers, remote receive-pack commands or included config
# the session planted — as you, with your keys. The way to push is cc-push
# (cc-push.sh, next to this file): it fetches into a separate host-only clone and
# pushes from there, and runs no git command in the checkout (its fetch has git
# start upload-pack there, which reads refs, objects and config and runs nothing
# from them). This scan is a TRIPWIRE:
# main() snapshots what host git reads to decide what to run, before the session,
# and compares after claude exits; anything added, removed or changed is named, and
# the launcher exits 3 instead of 0. It catches the common plants. It cannot be
# complete (see LIMITS): a clean scan is not permission to run git in the checkout.
#
# WHAT IS SNAPSHOTTED. Content hashes (and modes, and symlink targets), not a list
# of dangerous keys: git grows exec-capable settings faster than any list. Recorded,
# for every git dir reached (the checkout's git dir and common dir; every git dir
# nested in one at modules/** or worktrees/*, found by its HEAD; every embedded
# `.git` in the working tree; every common dir a `commondir` file names; every
# local-path remote), by its fixed layout, never by a file name found anywhere:
#   config, config.worktree, commondir, info/attributes, the hooks dir and every
#   entry in it except *.sample, the legacy remotes/* and branches/* files, the
#   in-progress rebase-merge/, rebase-apply/ and sequencer/ state (a todo `exec`
#   line runs on `git rebase --continue`), and every symlink.
# Plus what those configs name: every core.hooksPath dir, include.path /
# includeIf.*.path target and core.attributesFile, and every remote that is a
# local path inside the checkout (remote.*.url/pushurl, remote.pushDefault,
# branch.*.remote/pushRemote naming a path, url.<base>.insteadOf bases, legacy
# remotes files; a relative path resolved in the working tree of the repo whose
# config names it), walked as a git dir: a push to it runs its hooks. And your own
# global/system config, read with its includes evaluated for each git dir
# (includeIf gitdir:/gitdir/i: matched here against the physical git dir and the
# one under the path you launched on, symlinks kept, as git matches both;
# onbranch:/hasconfig: taken as matching): a relative core.hooksPath or
# core.attributesFile there resolves in each working tree, the top level and every
# embedded repo. Only those three kinds of entry are followed in your own config;
# its other entries are not recorded (the container cannot write it).
# Any change to one of these is a finding, even an inert one such as user.name. The
# key list below only labels report lines.
#
# FAIL CLOSED. A directory that cannot be listed, a file that cannot be read, a
# config git cannot parse, or a file too large to hash (over 64 MiB, or past 1 GiB
# in all: _snap_size_ok) makes the snapshot fail: at launch the launcher refuses
# to start, at exit it returns 4. Git needs only search permission to run a hook,
# so an unlistable hooks dir must never read as "empty". A Ctrl-C during the exit
# scan also exits 4, saying the scan did not finish.
#
# THE SCAN RUNS NOTHING FROM THE REPO. The git dir is located by plain file reads
# (a `.git` file's `gitdir:` line, a `commondir`), never `git rev-parse` in the
# checkout. Config is read with `git config --file <f> --no-includes` from cwd /,
# so no repo is discovered and git follows no include (the scan reads each target
# itself). The rest is host tools reading files: find, stat, readlink, realpath,
# sha256sum, cat, tr, sort, awk, cut, mktemp, dirname and rm; find never follows
# symlinks (-P), and a symlink's target is hashed only when it is a regular file.
# Nothing refreshes an index, which is what starts fsmonitor and clean filters.
# (The launcher's own resolve_workspace runs `git rev-parse --show-toplevel` in the
# checkout before the baseline; that runs no hook or fsmonitor.)
#
# EVERY CONTAINER-CHOSEN STRING (names, values, error text) is reduced to printable
# ASCII, newlines included, before it reaches the terminal: paths and values in
# report lines are %q-quoted or have line breaks replaced, every error reason is
# written by _snap_fail (tools' own error text is dropped: it would quote a path
# raw), and whole messages go through scan_vis.
#
# LIMITS (also in guides/cc-isolated-usage.md). No finding does not mean safe:
#   - a hook present at launch that runs a tracked file (husky's
#     core.hooksPath=.husky/_, the pre-commit framework, `exec ./scripts/check.sh`):
#     the session edits the tracked file, nothing in .git changes;
#   - anything present at launch is the baseline, including an earlier session's
#     plant or rebase left in progress, and a config value naming a program by path
#     in the checkout (core.pager = ./tools/pager.sh) is recorded as a value, not
#     followed;
#   - the container keeps running after claude exits, so a process it left behind
#     can plant after the scan; a launcher killed before the scan (closed terminal,
#     SIGTERM) scans nothing;
#   - tracked .gitattributes and .gitmodules are not scanned (they select drivers
#     and URLs that config defines, but git also acts on .gitmodules itself on
#     `submodule update`); a driver your own global config defines (filter.lfs.*)
#     runs on session-written content with no finding;
#   - includeIf gitdir: is matched for the physical path and the path you launched
#     on; running git through yet another symlinked route can match a condition
#     the scan did not evaluate;
#   - time: hashing is capped per file and in total, but a session can still plant
#     many files (and many embedded repos) to make the scan slow. A scan you stop
#     with Ctrl-C exits 4; one you kill some other way scans nothing.
#
# SIZE. This block brings cc-isolated.sh to about 1480 lines. It stays inline because
# install.sh ships a fixed PAYLOAD list and the trust manifest hashes each file;
# a sourced helper would need both to change.
GIT_EXIT_SCAN_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.|core\.hookspath|core\.sshcommand|core\.askpass|core\.pager|core\.editor|core\.gitproxy|core\.attributesfile|core\.worktree|sequence\.editor|pager\.|credential|diff\.|difftool\.|merge\.|mergetool\.|interactive\.|gpg\.|alias\.|submodule\.|protocol\.|remote\.|branch\..*\.(remote|pushremote)$|url\.|uploadpack\.|receive\.|sendemail\.|ssh\.|http\.|gc\.|web\.|browser\.|man\.|instaweb\.)'

# scan_git_dirs <ws>: print the git dir, then the common dir, of <ws>, from plain
# file reads. Returns 1 when either cannot be found.
scan_git_dirs() {
  local ws="$1" g line common
  g="$ws/.git"
  if [ -f "$g" ]; then
    # A linked worktree or submodule: `.git` is a file holding `gitdir: <path>`.
    # Read errors are dropped: their text would name a container-chosen path raw.
    line=""
    { IFS= read -r line < "$g"; } 2>/dev/null || true
    case "$line" in
      "gitdir: "*) g="${line#gitdir: }" ;;
      *) return 1 ;;
    esac
    case "$g" in /*) ;; *) g="$ws/$g" ;; esac
  fi
  [ -d "$g" ] || return 1
  common="$g"
  if [ -f "$g/commondir" ]; then
    line=""
    { IFS= read -r line < "$g/commondir"; } 2>/dev/null || true
    case "$line" in /*) common="$line" ;; *) common="$g/$line" ;; esac
  fi
  # Normalise (a worktree's commondir is usually "../.."): a plain cd, no git.
  g="$(cd "$g" 2>/dev/null && pwd -P)" || return 1
  common="$(cd "$common" 2>/dev/null && pwd -P)" || return 1
  printf '%s\n%s\n' "$g" "$common"
}

# The _snap_* helpers below run inside git_exec_snapshot and share its locals
# (bash dynamic scoping): _snap (the records), _snap_seen (walked dirs), _snap_ws,
# _snap_gd, _snap_common, _snap_tmp, _snap_names/_snap_rnames (remote names). Each
# returns 1 after printing a reason on stderr when something cannot be read.
# Records are tab-separated:
#   F <kind> <path %q> <attrs>     a file, dir or link host git reads
#   C <config %q> <key> <value>    one config entry (labels the report only)

# _snap_fail <printf format> <args...>: the reason on stderr, every byte outside
# printable ASCII (line breaks included) shown as '?'; returns 1.
_snap_fail() {
  local m
  # shellcheck disable=SC2059  # the format is always one of ours
  m="$(printf "$@")"
  printf '%s' "$m" | LC_ALL=C tr -c '[:print:]' '?' >&2
  echo >&2
  return 1
}

# _snap_hash <file>: the first 16 hex of its sha256. Reads, never runs.
_snap_hash() {
  local h
  if [ ! -r "$1" ] || ! h="$(sha256sum < "$1" 2>/dev/null)"; then
    _snap_fail 'cannot read %s' "$1"
    return 1
  fi
  printf '%s' "${h:0:16}"
}

# _snap_size_ok <file>: refuse to hash a file above GIT_EXIT_SCAN_MAX_FILE_BYTES,
# or once GIT_EXIT_SCAN_MAX_TOTAL_BYTES have been hashed in this snapshot: a
# session can plant a huge (or sparse, apparently huge) hook to stall the scan for
# hours, and a stalled scan gets killed, which is no scan. Too large reads as
# unreadable (fail closed, exit 4): treat the checkout as unsafe. The size is
# stat's apparent size (a sparse file counts in full); -L: a link's target.
GIT_EXIT_SCAN_MAX_FILE_BYTES=$((64 * 1024 * 1024))
GIT_EXIT_SCAN_MAX_TOTAL_BYTES=$((1024 * 1024 * 1024))
_snap_size_ok() {
  local s
  s="$(stat -L -c %s -- "$1" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$1"; return 1; }
  if [ "$s" -gt "$GIT_EXIT_SCAN_MAX_FILE_BYTES" ]; then
    _snap_fail '%s is too large to hash (%s bytes, over %s): treat the checkout as unsafe' \
      "$1" "$s" "$GIT_EXIT_SCAN_MAX_FILE_BYTES"
    return 1
  fi
  _snap_bytes=$((_snap_bytes + s))
  if [ "$_snap_bytes" -gt "$GIT_EXIT_SCAN_MAX_TOTAL_BYTES" ]; then
    _snap_fail 'more than %s bytes to hash (at %s): too much to hash, treat the checkout as unsafe' \
      "$GIT_EXIT_SCAN_MAX_TOTAL_BYTES" "$1"
    return 1
  fi
}

# _snap_file <kind> <path>: record <path> without following it. A symlink is
# recorded with its target string, plus the target's hash when that is a regular
# file; when it resolves to a directory, _snap_linkdir is set to it so the caller
# can decide whether to walk it. A missing path is recorded as missing, so
# creating it later is a change.
_snap_file() {
  local kind="$1" p="$2" attrs h t m
  _snap_linkdir=""
  # Tool errors are dropped (2>/dev/null) and replaced by _snap_fail: their text
  # would name the container-chosen path with its line breaks.
  if [ -L "$p" ]; then
    t="$(readlink -- "$p" 2>/dev/null)" || { _snap_fail 'cannot read link %s' "$p"; return 1; }
    attrs="link -> $(printf '%q' "$t")"
    if [ -f "$p" ]; then
      _snap_size_ok "$p" || return 1
      h="$(_snap_hash "$p")" || return 1
      attrs+=" file $h"
    elif [ -d "$p" ]; then
      _snap_linkdir="$(cd "$p" 2>/dev/null && pwd -P)" \
        || { _snap_fail 'cannot enter %s' "$p"; return 1; }
      attrs+=" dir"
    elif [ -e "$p" ]; then
      attrs+=" other"
    else
      attrs+=" dangling"
    fi
  elif [ -f "$p" ]; then
    _snap_size_ok "$p" || return 1
    h="$(_snap_hash "$p")" || return 1
    m="$(stat -c %a -- "$p" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$p"; return 1; }
    attrs="file $m $h"
  elif [ -d "$p" ]; then
    m="$(stat -c %a -- "$p" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$p"; return 1; }
    attrs="dir $m"
  elif [ -e "$p" ]; then
    m="$(stat -c '%F %a' -- "$p" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$p"; return 1; }
    attrs="other $m"   # fifo, socket, device
  else
    attrs="missing"
  fi
  _snap+="F"$'\t'"$kind"$'\t'"$(printf '%q' "$p")"$'\t'"$attrs"$'\n'
}

# _snap_opt <kind> <path>: _snap_file, but only for a path that exists (so one
# created later reads as "+ new").
_snap_opt() {
  _snap_linkdir=""
  if [ -e "$2" ] || [ -L "$2" ]; then _snap_file "$1" "$2"; fi
}

# _snap_find <out> <find args...>: run find into <out> (NUL-separated). A find
# that cannot list a directory fails the snapshot: unlistable is not empty.
_snap_find() {
  local out="$1"; shift
  if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then
    _snap_fail 'cannot list everything under %s: %s' "$1" "$(cat "$out.err")"
    return 1
  fi
}

# _snap_path <value> <base>: a config path value as git resolves it.
_snap_path() {
  # shellcheck disable=SC2088  # matching a literal "~/" in the config value
  case "$1" in
    "~/"*) printf '%s' "$HOME/${1#"~/"}" ;;
    /*)    printf '%s' "$1" ;;
    *)     printf '%s' "$2/$1" ;;
  esac
}

# _snap_inside_ws <path>: whether <path> (existing or not) resolves inside the
# checkout — the only tree the container can write.
_snap_inside_ws() {
  local r
  r="$(realpath -m -- "$1" 2>/dev/null)" || return 1
  case "$r/" in "$_snap_ws"/*) return 0 ;; esac
  return 1
}

# _snap_hooks <dir>: a hooks dir and every entry git could run from it.
_snap_hooks() {
  local d="$1" real list f
  _snap_file hooksdir "$d" || return 1
  [ -z "$_snap_linkdir" ] || d="$_snap_linkdir"
  [ -d "$d" ] || return 0   # recorded as missing: creating it is a change
  real="$(cd "$d" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$d"; return 1; }
  [ -z "${_snap_seen["h:$real"]:-}" ] || return 0
  _snap_seen["h:$real"]=1
  list="$_snap_tmp/h.${#_snap_seen[@]}"
  _snap_find "$list" "$real" -mindepth 1 -maxdepth 1 ! -name '*.sample' || return 1
  while IFS= read -r -d '' f; do
    _snap_file hook "$f" || return 1
  done < "$list"
}

# _snap_worktree_of <config file>: the working tree a relative core.hooksPath in
# that config is resolved against.
_snap_worktree_of() {
  local gd v
  gd="$(cd "$(dirname -- "$1")" 2>/dev/null && pwd -P)" || gd="$(dirname -- "$1")"
  if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then
    printf '%s' "$_snap_ws"
  elif v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then
    _snap_path "$v" "$gd"
  elif [ "${gd##*/}" = .git ]; then
    printf '%s' "${gd%/*}"
  else
    printf '%s' "$gd"
  fi
}

# _snap_remote <url> [<working tree>]: a remote that is a local path inside the
# checkout is a git dir whose hooks and receive-pack a host push runs. Git's rule
# (transport.c, url_is_local_not_ssh): "scheme://" is a URL, and a ':' before any
# '/' is host:path over ssh; anything else, including sub/a:b, is a local path,
# relative to the working tree of the repo whose config names it (git runs there):
# an embedded repo's ./x.git is <embedded repo>/x.git, not <checkout>/x.git. The
# working tree defaults to the checkout's. For <p> git tries <p>/.git, <p>,
# <p>.git/.git and <p>.git (enter_repo), so both <p> and <p>.git are walked. A
# local path outside the checkout is not writable by the container.
_snap_remote() {
  local p="$1" base="${2:-$_snap_ws}" c
  case "$p" in
    "") return 0 ;;
    file://localhost/*) p="${p#file://localhost}" ;;
    file://*) p="${p#file://}" ;;
    *://*) return 0 ;;
  esac
  if [[ "$p" == *:* ]] && [[ "${p%%:*}" != */* ]]; then return 0; fi
  case "$p" in /*) ;; *) p="$base/$p" ;; esac
  for c in "$p" "$p.git"; do
    _snap_inside_ws "$c" || continue
    _snap_file remote "$c" || return 1
    [ -z "$_snap_linkdir" ] || c="$_snap_linkdir"
    if [ -e "$c/.git" ] || [ -L "$c/.git" ]; then
      _snap_dotgit "$c/.git" || return 1
    elif [ -e "$c/HEAD" ]; then
      _snap_gitdir "$c" || return 1
    fi
  done
}

# _snap_config <file>: every entry (as C records), and what the entries point at.
_snap_config() {
  local f="$1" base="${2:-}" real out rec key val t name
  # The working tree its relative paths resolve in; an include target inherits
  # the including repo's.
  [ -n "$base" ] || base="$(_snap_worktree_of "$f")"
  real="$(realpath -m -- "$f" 2>/dev/null)" || real="$f"
  [ -z "${_snap_seen["c:$real"]:-}" ] || return 0
  _snap_seen["c:$real"]=1
  out="$_snap_tmp/c.${#_snap_seen[@]}"
  if ! (cd / && git --no-pager config --file "$f" --no-includes --null --list) > "$out" 2> "$out.err"; then
    _snap_fail 'could not read config %s: %s' "$f" "$(cat "$out.err")"
    return 1
  fi
  while IFS= read -r -d '' rec; do
    key="${rec%%$'\n'*}"
    val=""
    [[ "$rec" != *$'\n'* ]] || val="${rec#*$'\n'}"
    t="${val//$'\n'/?}"
    _snap+="C"$'\t'"$(printf '%q' "$f")"$'\t'"${key//$'\t'/?} ${t//$'\t'/?}"$'\n'
    case "$key" in
      core.hookspath)
        [ -z "$val" ] || _snap_hooks "$(_snap_path "$val" "$base")" || return 1 ;;
      include.path|includeif.*.path)
        [ -n "$val" ] || continue
        t="$(_snap_path "$val" "$(dirname -- "$f")")"
        _snap_file include "$t" || return 1
        if [ -f "$t" ]; then _snap_config "$t" "$base" || return 1; fi ;;
      core.attributesfile)
        [ -z "$val" ] || _snap_file attributes "$(_snap_path "$val" "$base")" || return 1 ;;
      remote.pushdefault|branch.*.remote|branch.*.pushremote)
        # A remote name, or a URL/path when no remote has that name: decided once
        # every config is read (git_exec_snapshot), in this config's working tree.
        _snap_names+=("$val")
        _snap_nbases+=("$base") ;;
      remote.*.*)
        name="${key#remote.}"; name="${name%.*}"
        [ -z "$name" ] || _snap_rnames["$name"]=1
        case "$key" in
          remote.*.url|remote.*.pushurl) _snap_remote "$val" "$base" || return 1 ;;
        esac ;;
      url.*.insteadof|url.*.pushinsteadof)
        # url.<base>.insteadOf rewrites matching URLs to <base>.
        t="${key#url.}"; t="${t%.*}"
        _snap_remote "$t" "$base" || return 1 ;;
    esac
  done < "$out"
}

# _snap_glob_re <pattern>: git's wildmatch (WM_PATHNAME) as an anchored ERE.
# Returns 1 for a pattern with a bracket expression: the caller then treats the
# condition as matching rather than guess.
_snap_glob_re() {
  local pat="$1" re="" c i n=${#1}
  [[ "$pat" != *'['* ]] || return 1
  for ((i = 0; i < n; i++)); do
    c="${pat:i:1}"
    case "$c" in
      '*')
        if [ "${pat:i+1:1}" = '*' ]; then
          if [ "${pat:i+2:1}" = / ]; then re+='(.*/)?'; i=$((i + 2)); else re+='.*'; i=$((i + 1)); fi
        else
          re+='[^/]*'
        fi ;;
      '?') re+='[^/]' ;;
      [a-zA-Z0-9/_~-]) re+="$c" ;;
      '^') re+='\^' ;;
      *) re+="[$c]" ;;
    esac
  done
  printf '^%s$' "$re"
}

# _snap_logical <path>: <path> (physical, inside the checkout) as seen from the
# logical checkout path _snap_lws — the path you launched on, symlinks kept —
# or nothing when there is none or it is the physical path.
_snap_logical() {
  [ -n "${_snap_lws:-}" ] && [ "$_snap_lws" != "$_snap_ws" ] || return 0
  case "$1" in
    "$_snap_ws") printf '%s' "$_snap_lws" ;;
    "$_snap_ws"/*) printf '%s' "$_snap_lws${1#"$_snap_ws"}" ;;
  esac
}

# _snap_cond <condition> <including file> <git dir> <logical git dir>: 0 when an
# includeIf condition applies to the repo whose git dir is given (config.c,
# include_by_gitdir). Git matches the pattern against the git dir as an absolute
# path WITHOUT resolving symlinks (from $PWD, so a checkout reached through a
# symlinked directory keeps that route) and then against its realpath; both are
# tried here, the first as the logical checkout path (_snap_lws) gives it.
# onbranch:, hasconfig: and anything unknown count as matching: walking a target
# git might not include costs nothing.
_snap_cond() {
  local cond="$1" from="$2" gd="$3" lgd="$4" pat icase="" re
  local lg1 lg2
  lg1="$(_snap_logical "$gd")"; lg2="$(_snap_logical "$lgd")"
  case "$cond" in
    gitdir:*)   pat="${cond#gitdir:}" ;;
    gitdir/i:*) pat="${cond#gitdir/i:}"; icase=1 ;;
    *) return 0 ;;
  esac
  # shellcheck disable=SC2088  # matching a literal "~/" in the pattern
  case "$pat" in
    "~/"*) pat="$HOME/${pat#"~/"}" ;;
    ./*)   pat="$(dirname -- "$from")/${pat#./}" ;;
    /*)    ;;
    *)     pat="**/$pat" ;;
  esac
  case "$pat" in */) pat+='**' ;; esac
  re="$(_snap_glob_re "$pat")" || return 0
  if [ -n "$icase" ]; then re="${re,,}"; gd="${gd,,}"; lgd="${lgd,,}"; lg1="${lg1,,}"; lg2="${lg2,,}"; fi
  [[ "$gd" =~ $re ]] || [[ "$lgd" =~ $re ]] \
    || { [ -n "$lg1" ] && [[ "$lg1" =~ $re ]]; } || { [ -n "$lg2" ] && [[ "$lg2" =~ $re ]]; }
}

# _snap_host_config <git dir> <logical git dir> <working tree> [<file> <depth>]:
# your own global and system config (read from /, so no repo is discovered), with
# its includes followed here and includeIf conditions evaluated for this git dir,
# as git would for a command run in <working tree>. A relative core.hooksPath or
# core.attributesFile there resolves inside the checkout; walk those. Entries are
# not recorded (the container cannot write these files, and they are yours to
# change mid-session), except in an include target that is inside the checkout.
_snap_host_config() {
  local gd="$1" lgd="$2" wt="$3" file="${4:-}" depth="${5:-0}" out origin rec key val t cond
  local -a src=()
  [ "$depth" -le 10 ] || return 0   # git's own include depth limit
  [ -z "$file" ] || src=(--file "$file")
  out="$_snap_tmp/host.$depth.${#_snap_seen[@]}.$RANDOM"
  if ! (cd / && git --no-pager config "${src[@]}" --no-includes --show-origin --null --list) > "$out" 2> "$out.err"; then
    _snap_fail 'could not read your git config%s: %s' "${file:+ $file}" "$(cat "$out.err")"
    return 1
  fi
  while IFS= read -r -d '' origin && IFS= read -r -d '' rec; do
    key="${rec%%$'\n'*}"
    val=""
    [[ "$rec" != *$'\n'* ]] || val="${rec#*$'\n'}"
    [ -n "$val" ] || continue
    origin="${origin#file:}"
    case "$key" in
      core.hookspath)
        t="$(_snap_path "$val" "$wt")"
        if _snap_inside_ws "$t"; then _snap_hooks "$t" || return 1; fi ;;
      core.attributesfile)
        t="$(_snap_path "$val" "$wt")"
        if _snap_inside_ws "$t"; then _snap_file attributes "$t" || return 1; fi ;;
      include.path|includeif.*.path)
        if [ "$key" != include.path ]; then
          cond="${key#includeif.}"; cond="${cond%.path}"
          _snap_cond "$cond" "$origin" "$gd" "$lgd" || continue
        fi
        t="$(_snap_path "$val" "$(dirname -- "$origin")")"
        if _snap_inside_ws "$t"; then
          _snap_file include "$t" || return 1
          if [ -f "$t" ]; then _snap_config "$t" "$wt" || return 1; fi
        fi
        if [ -f "$t" ]; then _snap_host_config "$gd" "$lgd" "$wt" "$t" $((depth + 1)) || return 1; fi ;;
    esac
  done < "$out"
}

# _snap_dotgit_target <path of a .git entry>: the git dir it names (a dir, a
# `gitdir:` file, or a link), or nothing.
_snap_dotgit_target() {
  local p="$1" line g
  if [ -d "$p" ]; then
    g="$p"
  elif [ -f "$p" ]; then
    line=""
    { IFS= read -r line < "$p"; } 2>/dev/null || true
    case "$line" in "gitdir: "*) g="${line#gitdir: }" ;; *) return 0 ;; esac
    case "$g" in /*) ;; *) g="${p%/*}/$g" ;; esac
  else
    return 0
  fi
  [ -d "$g" ] || return 0
  (cd "$g" 2>/dev/null && pwd -P) || true
}

# _snap_nested <dir>: the git dirs under <dir> (a modules/ or worktrees/ dir, or a
# linked dir in the checkout): each directory holding HEAD next to objects/ or a
# commondir file, at any depth (submodule names contain slashes).
_snap_nested() {
  local d="$1" real list f g
  [ -d "$d" ] && [ ! -L "$d" ] || return 0   # a link is walked by the link loop
  real="$(cd "$d" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$d"; return 1; }
  [ -z "${_snap_seen["n:$real"]:-}" ] || return 0
  _snap_seen["n:$real"]=1
  list="$_snap_tmp/n.${#_snap_seen[@]}"
  _snap_find "$list" "$real" -mindepth 2 -name HEAD || return 1
  while IFS= read -r -d '' f; do
    g="${f%/*}"
    if [ -d "$g/objects" ] || [ -f "$g/commondir" ]; then _snap_gitdir "$g" || return 1; fi
  done < "$list"
}

# _snap_gitdir <dir>: everything exec-relevant in one git dir, by its fixed layout
# (never by a name found anywhere under it: a branch named `config` or `hooks`, or
# a checkout under a directory named hooks, is not a git file), then the common
# dir its commondir names and the git dirs nested in it.
_snap_gitdir() {
  local real list f line c name d body
  real="$(cd "$1" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$1"; return 1; }
  [ -z "${_snap_seen["g:$real"]:-}" ] || return 0
  _snap_seen["g:$real"]=1
  for f in config config.worktree; do
    _snap_opt config "$real/$f" || return 1
    if [ -f "$real/$f" ]; then _snap_config "$real/$f" || return 1; fi
  done
  _snap_opt attributes "$real/info/attributes" || return 1
  _snap_hooks "$real/hooks" || return 1
  _snap_opt commondir-file "$real/commondir" || return 1
  if [ -f "$real/commondir" ]; then
    # A nested worktree's common dir can be a bare repo in the checkout not named
    # .git; walk it (the checkout's own common dir is walked by the caller).
    line=""
    { IFS= read -r line < "$real/commondir"; } 2>/dev/null || true
    case "$line" in /*) c="$line" ;; *) c="$real/$line" ;; esac
    if [ -n "$line" ] && [ -d "$c" ] && _snap_inside_ws "$c"; then _snap_gitdir "$c" || return 1; fi
  fi
  # Legacy remotes: remotes/<name> ("URL: <url>" lines), branches/<name> ("<url>#<branch>"),
  # a relative path resolved in this git dir's working tree, as git would.
  for d in remotes branches; do
    [ -d "$real/$d" ] || continue
    list="$_snap_tmp/r.${#_snap_seen[@]}.$d"
    _snap_find "$list" "$real/$d" -mindepth 1 ! -type d || return 1
    while IFS= read -r -d '' f; do
      _snap_file legacy-remote "$f" || return 1
      name="${f#"$real/$d/"}"
      _snap_rnames["$name"]=1
      [ -f "$f" ] || continue
      # Read in one go (the hash above proved it readable); a read error's text
      # would name the container-chosen path raw.
      body="$(cat -- "$f" 2>/dev/null)" || { _snap_fail 'cannot read %s' "$f"; return 1; }
      while IFS= read -r line || [ -n "$line" ]; do
        if [ "$d" = branches ]; then
          _snap_remote "${line%%#*}" "$(_snap_worktree_of "$real/config")" || return 1
          break
        fi
        case "$line" in URL:*) line="${line#URL:}"; _snap_remote "${line#"${line%%[![:space:]]*}"}" "$(_snap_worktree_of "$real/config")" || return 1 ;; esac
      done <<< "$body"
    done < "$list"
  done
  # An interrupted rebase, cherry-pick or revert: its todo list runs on --continue.
  for d in rebase-merge rebase-apply sequencer; do
    [ -d "$real/$d" ] || continue
    list="$_snap_tmp/s.${#_snap_seen[@]}.$d"
    _snap_find "$list" "$real/$d" ! -type d || return 1
    while IFS= read -r -d '' f; do
      _snap_file sequencer "$f" || return 1
    done < "$list"
  done
  # Every symlink (git follows them); a linked dir inside the checkout is searched
  # for git dirs too. Hooks were recorded above.
  list="$_snap_tmp/l.${#_snap_seen[@]}"
  _snap_find "$list" "$real" -type l || return 1
  while IFS= read -r -d '' f; do
    [ "${f%/*}" != "$real/hooks" ] || continue
    _snap_file link "$f" || return 1
    if [ -n "$_snap_linkdir" ] && _snap_inside_ws "$_snap_linkdir"; then
      c="$_snap_linkdir"
      if [ -e "$c/HEAD" ]; then _snap_gitdir "$c" || return 1; fi
      _snap_nested "$c" || return 1
    fi
  done < "$list"
  _snap_nested "$real/modules" || return 1
  _snap_nested "$real/worktrees"
}

# _snap_dotgit <path>: a `.git` entry — a git dir, a `gitdir:` file, or a link.
_snap_dotgit() {
  local p="$1" g
  _snap_file dotgit "$p" || return 1
  g="$(_snap_dotgit_target "$p")"
  [ -z "$g" ] || _snap_gitdir "$g"
}

# git_exec_snapshot <ws> [<logical ws>]: the records above for <ws>, sorted
# (LC_ALL=C) so two snapshots compare line by line. <logical ws> is the same
# checkout by the path you reach it on, symlinks unresolved (logical_workspace);
# your includeIf gitdir: conditions are matched against it too. Lines are raw
# (values may hold control bytes the container chose); show them only through
# scan_vis. Returns 1, with a reason on stderr, when any part cannot be read. Every
# reason goes through _snap_fail, so none can hold a line break.
git_exec_snapshot() {
  local ws="$1" _snap_lws="${2:-}" dirs _snap="" _snap_gd _snap_common _snap_ws _snap_tmp _snap_linkdir="" rc=0 list f g i
  local _snap_bytes=0
  local -A _snap_seen=() _snap_rnames=()
  local -a _snap_names=() _snap_nbases=()
  if ! dirs="$(scan_git_dirs "$ws")"; then
    _snap_fail 'cannot locate the git directory of %s from its .git entry' "$ws"
    return 1
  fi
  _snap_gd="${dirs%%$'\n'*}"
  _snap_common="${dirs#*$'\n'}"
  _snap_ws="$(cd "$ws" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$ws"; return 1; }
  if [ ! -f "$_snap_common/config" ]; then
    # The common dir is whatever `commondir` names: the container's choice.
    _snap_fail 'no git config at %s/config' "$_snap_common"
    return 1
  fi
  # The resolved dirs are records too: repointing `.git` or `commondir` shows up.
  _snap+="F"$'\t'"gitdir"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$(printf '%q' "$_snap_gd")"$'\n'
  _snap+="F"$'\t'"commondir"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$(printf '%q' "$_snap_common")"$'\n'
  _snap_tmp="$(mktemp -d)"
  {
    _snap_dotgit "$ws/.git" &&
    _snap_gitdir "$_snap_gd" &&
    _snap_gitdir "$_snap_common" &&
    _snap_host_config "$_snap_gd" "$_snap_ws/.git" "$_snap_ws" &&
    # Embedded repos anywhere in the working tree, each with your host config as
    # it applies there.
    list="$_snap_tmp/worktree" &&
    _snap_find "$list" "$_snap_ws" -mindepth 2 -name .git
  } || rc=1
  if [ "$rc" -eq 0 ]; then
    while IFS= read -r -d '' f; do
      [ "$f" != "$_snap_ws/.git" ] || continue
      _snap_dotgit "$f" || { rc=1; break; }
      g="$(_snap_dotgit_target "$f")"
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
    done < "$list"
  fi
  # Remote names that no remote defines are URLs or paths to git (remote.c).
  # Walking one can reach configs that name more, hence the growing index.
  i=0
  while [ "$rc" -eq 0 ] && [ "$i" -lt "${#_snap_names[@]}" ]; do
    f="${_snap_names[$i]}"
    g="${_snap_nbases[$i]}"
    i=$((i + 1))
    [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_remote "$f" "$g" || rc=1
  done
  rm -rf "$_snap_tmp"
  [ "$rc" -eq 0 ] || return 1
  printf '%s' "$_snap" | LC_ALL=C sort -u
}

# scan_vis: make control bytes visible as '?' so a container-chosen hook name or
# config value cannot rewrite the terminal around the warning. Newlines pass, so
# only whole messages go through here; every container-chosen string in them has
# already lost its line breaks (%q, _snap_fail, or the C-record replacement).
scan_vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}

# scan_diff <before> <after>: the report lines for everything that differs. Files
# first (+ new, - gone, ~ changed); under a changed config file, its added and
# removed entries, with keys the label list knows marked "<- can run a program".
scan_diff() {
  SCAN_KEYS_RE="$GIT_EXIT_SCAN_KEYS_RE" LC_ALL=C awk -F'\t' '
    function note(key) { return (tolower(key) ~ ENVIRON["SCAN_KEYS_RE"]) ? "   <- can run a program" : "" }
    FNR == NR { if ($1 == "F") b[$2 FS $3] = $4; else if ($1 == "C") bc[$0] = 1; next }
    { if ($1 == "F") a[$2 FS $3] = $4; else if ($1 == "C") ac[$0] = 1 }
    END {
      for (k in a) {
        split(k, p, FS)
        if (!(k in b))        { print p[2] "\t0\t    + " p[1] " " p[2] "  " a[k] }
        else if (a[k] != b[k]) { print p[2] "\t0\t    ~ " p[1] " " p[2] "  " a[k] }
      }
      for (k in b) if (!(k in a)) { split(k, p, FS); print p[2] "\t0\t    - " p[1] " " p[2] "  " b[k] }
      # Entries sort under the line of the config file they sit in (same path).
      for (e in ac) if (!(e in bc)) { split(e, p, FS); print p[2] "\t1\t        + " p[3] note(substr(p[3], 1, index(p[3] " ", " ") - 1)) }
      for (e in bc) if (!(e in ac)) { split(e, p, FS); print p[2] "\t2\t        - " p[3] }
    }' <(printf '%s\n' "$1") <(printf '%s\n' "$2") \
    | LC_ALL=C sort -t $'\t' -k1,1 -k2,2n -k3 | cut -f3-
}

# git_exit_scan <ws> <launch snapshot> [<logical ws>]: 0 when nothing the tripwire
# records changed; 1 (warning on stderr, naming each item) when something did; 2
# when the exit state could not be read. 0 is not "safe": see LIMITS above.
# <logical ws> must be what the launch snapshot was taken with.
git_exit_scan() {
  local ws="$1" before="$2" lws="${3:-}" after changes errf reason
  errf="$(mktemp)"
  if ! after="$(git_exec_snapshot "$ws" "$lws" 2>"$errf")"; then
    reason="$(cat "$errf")"
    rm -f "$errf"
    {
      echo "WARNING: the exit scan could not read everything it checks in $ws (its git"
      echo "  dirs, its working tree and what their config names):"
      printf '%s\n' "$reason" | sed 's/^/    /'
      echo "  Git may still be able to run what the scan could not list (a hook needs only"
      echo "  search permission). Treat the checkout as untrusted: do not run git in it on"
      echo "  the host. Push with cc-push, which fetches into a separate host-only clone"
      echo "  and pushes from there:  cc-push $ws"
      echo "  (guides/cc-isolated-usage.md, \"Pushing: cc-push\")."
    } | scan_vis >&2
    return 2
  fi
  rm -f "$errf"
  [ "$before" != "$after" ] || return 0
  changes="$(scan_diff "$before" "$after")"
  [ -n "$changes" ] || return 0
  {
    echo
    echo "WARNING: this session changed what HOST git reads in $ws to decide which"
    echo "  programs to run (hooks, config, attributes, submodule and nested git dirs,"
    echo "  local remotes, rebase todo lists). Any of these can make git run a program"
    echo "  as you, with your keys. Since launch (+ new, - removed, ~ changed):"
    printf '%s\n' "$changes"
    echo "  Do not run git in this checkout on the host (not even \`git status\`). Push"
    echo "  with cc-push, which fetches into a separate host-only clone and pushes from"
    echo "  there, running nothing from this checkout:  cc-push $ws"
    echo "  To use the checkout with host git again, first check each item and undo what"
    echo "  you did not make:"
    echo "    a config entry  ->  git config --file <file> --unset-all <key>"
    echo "    a hook or file  ->  rm <path> (or restore it)"
    echo "    gitdir/commondir -> .git (or its commondir) was repointed; restore it"
    echo "  \`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push\` is NOT a safe"
    echo "  alternative: it still runs remote.*.receivepack, a repointed remote's hooks,"
    echo "  credential helpers and core.sshCommand, from included config files too."
    echo "  See guides/cc-isolated-usage.md, \"Pushing: cc-push\"."
  } | scan_vis >&2
  return 1
}

# scan_interrupted: the INT trap while the exit scan runs.
scan_interrupted() {
  {
    echo
    echo "WARNING: the exit scan was interrupted, so it checked nothing. Treat the"
    echo "  checkout as untrusted: do not run git in it on the host. Push with cc-push"
    echo "  (guides/cc-isolated-usage.md, \"Pushing: cc-push\")."
  } >&2
  exit 4
}

usage() {
  # Line range: the header block above, down to the last line of the "WHY THE
  # WORKSPACE IS AN ARGUMENT" paragraph. Adding a line to that block means moving
  # this bound with it — test/cc-isolated-functions.bats asserts the last line is
  # still included, so a stale bound fails there rather than silently truncating.
  sed -n '2,29p' "${BASH_SOURCE[0]}"
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
          exit 1
        fi
        profiles="$2"; shift 2 ;;
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
