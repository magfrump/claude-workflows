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

# --- Exit scan: .git changes the container made during the session -------------
#
# WHY (Q-069 [3], Q-076). The container writes the checkout's .git through the bind
# mount, and the recommended workflow is "commit inside, push from the host with
# your keys". A plain host `git push` or `git status` then runs whatever hooks,
# core.fsmonitor, filter drivers, remote receive-pack commands or included config
# the session planted — as you, with your keys. So main() snapshots every file
# host git reads to decide what to run, before the session, and compares after
# claude exits; anything added, removed or changed is named, and the launcher
# exits 3 instead of 0.
#
# WHAT IS SNAPSHOTTED. Content hashes (and modes, and symlink targets), not a list
# of dangerous keys: git grows exec-capable settings faster than any list, and a
# 3-replicate fact-check of the first, key-list version found four bypasses
# (remote.*.receivepack, a repointed pushurl, a submodule's config, a hooks dir
# made unlistable). Recorded, for the checkout's git dir and common dir and,
# recursively, every git dir inside them (.git/modules/**, .git/worktrees/*):
#   every file named config, config.worktree or commondir; info/attributes; every
#   hooks dir (mode) and every entry in it except *.sample; every symlink.
# Plus: every nested `.git` in the working tree (host `git status` recurses into
# an embedded repo's gitlink and runs ITS fsmonitor), every core.hooksPath dir,
# every include.path / includeIf.*.path target and core.attributesFile named by
# any of those configs, and any local-path remote (url/pushurl) inside the
# checkout, walked as a git dir (a push to it runs its hooks). Also the hooks dir
# and attributes file your own global/system config names: a relative
# core.hooksPath there resolves inside the checkout.
# Any change to one of these is a finding, even an inert one such as user.name:
# no allowlist of "safe" keys holds up (branch.*.pushRemote can name a local path
# whose hooks a push runs). The key list below only labels report lines.
#
# FAIL CLOSED. A directory that cannot be listed, a file that cannot be read or a
# config git cannot parse makes the snapshot fail: at launch the launcher refuses
# to start, at exit it returns 4. Git needs only search permission to run a hook,
# so an unlistable hooks dir must never read as "empty".
#
# THE SCAN RUNS NOTHING FROM THE REPO. The git dir is located by plain file reads
# (a `.git` file's `gitdir:` line, a worktree's `commondir`), never `git rev-parse`
# in the checkout. Config is read with `git config --file <f> --no-includes` from
# cwd /, so no repo is discovered and include.path is not followed by git (the scan
# reads the target itself). Everything else is find, stat, readlink and sha256sum;
# find never follows symlinks (-P), and a symlink's target is hashed only when it
# is a regular file. Nothing refreshes an index, which is what starts fsmonitor
# and clean filters.
#
# EVERY CONTAINER-CHOSEN STRING (names, values, error text) reaches the terminal
# only through scan_vis, at launch and at exit.
#
# LIMITS (also in guides/cc-isolated-usage.md). The container keeps running after
# claude exits, so a process it left behind can plant after the scan. Whatever is
# present at launch is the baseline, including anything an earlier session planted
# that you did not remove. A launcher killed before the scan (closed terminal,
# SIGTERM) scans nothing. A config value that names a program by path inside the
# checkout (say core.pager = ./tools/pager.sh, present at launch) is recorded as a
# value, not followed: the session can rewrite the program without a finding.
#
# SIZE. This block brings cc-isolated.sh to about 1160 lines. It stays inline because
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
    line=""
    IFS= read -r line < "$g" || true
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
    IFS= read -r line < "$g/commondir" || true
    case "$line" in /*) common="$line" ;; *) common="$g/$line" ;; esac
  fi
  # Normalise (a worktree's commondir is usually "../.."): a plain cd, no git.
  g="$(cd "$g" 2>/dev/null && pwd -P)" || return 1
  common="$(cd "$common" 2>/dev/null && pwd -P)" || return 1
  printf '%s\n%s\n' "$g" "$common"
}

# The _snap_* helpers below run inside git_exec_snapshot and share its locals
# (bash dynamic scoping): _snap (the records), _snap_seen (walked dirs), _snap_ws,
# _snap_gd, _snap_common, _snap_tmp. Each returns 1 after printing a reason on
# stderr when something cannot be read. Records are tab-separated:
#   F <kind> <path %q> <attrs>     a file, dir or link host git reads
#   C <config %q> <key> <value>    one config entry (labels the report only)

# _snap_hash <file>: the first 16 hex of its sha256. Reads, never runs.
_snap_hash() {
  local h
  if [ ! -r "$1" ] || ! h="$(sha256sum < "$1" 2>/dev/null)"; then
    printf 'cannot read %s\n' "$1" >&2
    return 1
  fi
  printf '%s' "${h:0:16}"
}

# _snap_file <kind> <path>: record <path> without following it. A symlink is
# recorded with its target string, plus the target's hash when that is a regular
# file; when it resolves to a directory, _snap_linkdir is set to it so the caller
# can decide whether to walk it. A missing path is recorded as missing, so
# creating it later is a change.
_snap_file() {
  local kind="$1" p="$2" attrs h t
  _snap_linkdir=""
  if [ -L "$p" ]; then
    t="$(readlink -- "$p")" || { printf 'cannot read link %s\n' "$p" >&2; return 1; }
    attrs="link -> $(printf '%q' "$t")"
    if [ -f "$p" ]; then
      h="$(_snap_hash "$p")" || return 1
      attrs+=" file $h"
    elif [ -d "$p" ]; then
      _snap_linkdir="$(cd "$p" 2>/dev/null && pwd -P)" \
        || { printf 'cannot enter %s\n' "$p" >&2; return 1; }
      attrs+=" dir"
    elif [ -e "$p" ]; then
      attrs+=" other"
    else
      attrs+=" dangling"
    fi
  elif [ -f "$p" ]; then
    h="$(_snap_hash "$p")" || return 1
    attrs="file $(stat -c %a -- "$p") $h"
  elif [ -d "$p" ]; then
    attrs="dir $(stat -c %a -- "$p")"
  elif [ -e "$p" ]; then
    attrs="other $(stat -c '%F %a' -- "$p")"   # fifo, socket, device
  else
    attrs="missing"
  fi
  _snap+="F"$'\t'"$kind"$'\t'"$(printf '%q' "$p")"$'\t'"$attrs"$'\n'
}

# _snap_find <out> <find args...>: run find into <out> (NUL-separated). A find
# that cannot list a directory fails the snapshot: unlistable is not empty.
_snap_find() {
  local out="$1"; shift
  if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then
    printf 'cannot list everything under %s: %s\n' "$1" "$(tr '\n' ' ' < "$out.err")" >&2
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
  real="$(cd "$d" 2>/dev/null && pwd -P)" || { printf 'cannot enter %s\n' "$d" >&2; return 1; }
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

# _snap_remote <url>: a local-path remote inside the checkout is a git dir whose
# hooks and receive-pack a host push runs. URLs with a scheme or host:path are not
# local; a local path outside the checkout is not writable by the container.
_snap_remote() {
  local p="$1"
  case "$p" in
    file://*) p="${p#file://}" ;;
    /*|./*|../*) ;;
    *:*|"") return 0 ;;
  esac
  case "$p" in /*) ;; *) p="$_snap_ws/$p" ;; esac
  _snap_inside_ws "$p" || return 0
  _snap_file remote "$p" || return 1
  [ -z "$_snap_linkdir" ] || p="$_snap_linkdir"
  if [ -e "$p/.git" ] || [ -L "$p/.git" ]; then
    _snap_dotgit "$p/.git"
  elif [ -d "$p" ]; then
    _snap_gitdir "$p"
  fi
}

# _snap_config <file>: every entry (as C records), and what the entries point at.
_snap_config() {
  local f="$1" real out rec key val t
  real="$(realpath -m -- "$f" 2>/dev/null)" || real="$f"
  [ -z "${_snap_seen["c:$real"]:-}" ] || return 0
  _snap_seen["c:$real"]=1
  out="$_snap_tmp/c.${#_snap_seen[@]}"
  if ! (cd / && git --no-pager config --file "$f" --no-includes --null --list) > "$out" 2> "$out.err"; then
    printf 'could not read config %s: %s\n' "$f" "$(tr '\n' ' ' < "$out.err")" >&2
    return 1
  fi
  while IFS= read -r -d '' rec; do
    key="${rec%%$'\n'*}"
    val=""
    [[ "$rec" != *$'\n'* ]] || val="${rec#*$'\n'}"
    t="${val//$'\n'/?}"
    _snap+="C"$'\t'"$(printf '%q' "$f")"$'\t'"$key ${t//$'\t'/?}"$'\n'
    case "$key" in
      core.hookspath)
        [ -z "$val" ] || _snap_hooks "$(_snap_path "$val" "$(_snap_worktree_of "$f")")" || return 1 ;;
      include.path|includeif.*.path)
        [ -n "$val" ] || continue
        t="$(_snap_path "$val" "$(dirname -- "$f")")"
        _snap_file include "$t" || return 1
        if [ -f "$t" ]; then _snap_config "$t" || return 1; fi ;;
      core.attributesfile)
        [ -z "$val" ] || _snap_file attributes "$(_snap_path "$val" "$_snap_ws")" || return 1 ;;
      remote.*.url|remote.*.pushurl)
        _snap_remote "$val" || return 1 ;;
    esac
  done < "$out"
}

# _snap_host_config: the host's own global and system config (read from /, so no
# repo) can name a relative core.hooksPath or core.attributesFile, which git
# resolves inside the checkout; walk those targets. Its entries are not recorded:
# the container cannot write those files, and they are yours to change mid-session.
_snap_host_config() {
  local out="$_snap_tmp/host" rec key val
  if ! (cd / && git --no-pager config --null --list) > "$out" 2> "$out.err"; then
    printf 'could not read your global git config: %s\n' "$(tr '\n' ' ' < "$out.err")" >&2
    return 1
  fi
  while IFS= read -r -d '' rec; do
    key="${rec%%$'\n'*}"
    val=""
    [[ "$rec" != *$'\n'* ]] || val="${rec#*$'\n'}"
    [ -n "$val" ] || continue
    case "$key" in
      core.hookspath)      _snap_hooks "$(_snap_path "$val" "$_snap_ws")" || return 1 ;;
      core.attributesfile) _snap_file attributes "$(_snap_path "$val" "$_snap_ws")" || return 1 ;;
    esac
  done < "$out"
}

# _snap_gitdir <dir>: everything exec-relevant in a git dir and, recursively, in
# the git dirs inside it (modules/**, worktrees/*): one find, no pruning (a prune
# pattern is a name the container could choose to hide behind).
_snap_gitdir() {
  local real list f base parent
  real="$(cd "$1" 2>/dev/null && pwd -P)" || { printf 'cannot enter %s\n' "$1" >&2; return 1; }
  [ -z "${_snap_seen["g:$real"]:-}" ] || return 0
  _snap_seen["g:$real"]=1
  list="$_snap_tmp/g.${#_snap_seen[@]}"
  _snap_find "$list" "$real" \( -type l -o -name config -o -name config.worktree \
    -o -name commondir -o -path '*/info/attributes' -o -name hooks -o -path '*/hooks/*' \) \
    ! -name '*.sample' || return 1
  while IFS= read -r -d '' f; do
    base="${f##*/}"
    parent="${f%/*}"
    if [ "${parent##*/}" = hooks ]; then
      _snap_file hook "$f" || return 1
    elif [ "$base" = hooks ]; then
      # Its entries come from this same find; a symlinked one is walked there.
      _snap_file hooksdir "$f" || return 1
      if [ -n "$_snap_linkdir" ]; then _snap_hooks "$_snap_linkdir" || return 1; fi
    elif [ "$base" = config ] || [ "$base" = config.worktree ]; then
      _snap_file config "$f" || return 1
      if [ -f "$f" ]; then _snap_config "$f" || return 1; fi
    elif [ "$base" = commondir ]; then
      _snap_file commondir-file "$f" || return 1
    elif [ "$base" = attributes ]; then
      _snap_file attributes "$f" || return 1
    else
      # A symlink (anything else the find matched is under a hooks dir). Git
      # follows it, so a linked directory inside the checkout is walked too.
      _snap_file link "$f" || return 1
      if [ -n "$_snap_linkdir" ] && _snap_inside_ws "$_snap_linkdir"; then
        _snap_gitdir "$_snap_linkdir" || return 1
      fi
    fi
  done < "$list"
}

# _snap_dotgit <path>: a `.git` entry — a git dir, a `gitdir:` file, or a link.
_snap_dotgit() {
  local p="$1" line g
  _snap_file dotgit "$p" || return 1
  if [ -n "$_snap_linkdir" ]; then
    _snap_gitdir "$_snap_linkdir"
  elif [ -f "$p" ]; then
    line=""
    IFS= read -r line < "$p" || true
    case "$line" in "gitdir: "*) g="${line#gitdir: }" ;; *) return 0 ;; esac
    case "$g" in /*) ;; *) g="${p%/*}/$g" ;; esac
    if [ -d "$g" ]; then _snap_gitdir "$g"; fi
  elif [ -d "$p" ]; then
    _snap_gitdir "$p"
  fi
}

# git_exec_snapshot <ws>: the records above for <ws>, sorted (LC_ALL=C) so two
# snapshots compare line by line. Lines are raw (values may hold control bytes the
# container chose); show them only through scan_vis. Returns 1, with a reason on
# stderr, when any part cannot be read.
git_exec_snapshot() {
  local ws="$1" dirs _snap="" _snap_gd _snap_common _snap_ws _snap_tmp _snap_linkdir="" rc=0 list f
  local -A _snap_seen=()
  if ! dirs="$(scan_git_dirs "$ws")"; then
    echo "cannot locate the git directory of $ws from its .git entry" >&2
    return 1
  fi
  _snap_gd="${dirs%%$'\n'*}"
  _snap_common="${dirs#*$'\n'}"
  _snap_ws="$(cd "$ws" && pwd -P)" || return 1
  if [ ! -f "$_snap_common/config" ]; then
    echo "no git config at $_snap_common/config" >&2
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
    # Default hooks dir, even when absent (creating it is a change).
    _snap_hooks "$_snap_common/hooks" &&
    _snap_host_config &&
    # Embedded repos anywhere in the working tree.
    list="$_snap_tmp/worktree" &&
    _snap_find "$list" "$_snap_ws" -mindepth 2 -name .git
  } || rc=1
  if [ "$rc" -eq 0 ]; then
    while IFS= read -r -d '' f; do
      [ "$f" != "$_snap_ws/.git" ] || continue
      _snap_dotgit "$f" || { rc=1; break; }
    done < "$list"
  fi
  rm -rf "$_snap_tmp"
  [ "$rc" -eq 0 ] || return 1
  printf '%s' "$_snap" | LC_ALL=C sort -u
}

# scan_vis: make control bytes visible as '?' so a container-chosen hook name or
# config value cannot rewrite the terminal around the warning.
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

# git_exit_scan <ws> <launch snapshot>: 0 when nothing host git reads to decide
# what to run changed; 1 (warning on stderr, naming each item) when something did;
# 2 when the exit state could not be read.
git_exit_scan() {
  local ws="$1" before="$2" after changes errf reason
  errf="$(mktemp)"
  if ! after="$(git_exec_snapshot "$ws" 2>"$errf")"; then
    reason="$(cat "$errf")"
    rm -f "$errf"
    {
      echo "WARNING: the exit scan could not read everything under $ws/.git: $reason"
      echo "  Git may still be able to run what the scan could not list (a hook needs only"
      echo "  search permission). Treat the checkout as untrusted: do not run git in it on"
      echo "  the host; push from a separate host clone that fetches from this one (see"
      echo "  guides/cc-isolated-usage.md, \"No credentials\")."
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
    echo "  local remotes). Any of these can make git run a program as you, with your"
    echo "  keys. Since launch (+ new, - removed, ~ changed):"
    printf '%s\n' "$changes"
    echo "  Do not run git in this checkout on the host (not even \`git status\`) until"
    echo "  you have checked each item and undone what you did not make:"
    echo "    a config entry  ->  git config --file <file> --unset-all <key>"
    echo "    a hook or file  ->  rm <path> (or restore it)"
    echo "    gitdir/commondir -> .git (or its commondir) was repointed; restore it"
    echo "  Safest: push from a separate host clone that fetches from this one; a fetch"
    echo "  runs none of this checkout's hooks, fsmonitor, filters or remote settings."
    echo "  \`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push\` covers hooks"
    echo "  and fsmonitor ONLY: not remote.*.receivepack, a repointed remote, filters,"
    echo "  includes, credential helpers or core.sshCommand."
    echo "  See guides/cc-isolated-usage.md, \"No credentials\"."
  } | scan_vis >&2
  return 1
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
  local git_before="" snap_err
  if [ "$action" = "launch" ]; then
    snap_err="$(mktemp)"
    if ! git_before="$(git_exec_snapshot "$ws" 2>"$snap_err")"; then
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
  trap - INT
  local scan=0
  git_exit_scan "$ws" "$git_before" || scan=$?
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
