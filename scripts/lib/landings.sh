#!/usr/bin/env bash
# The digest's section 6b (brief docs/working/briefs/2026-11-20-out-of-loop-landings.md;
# design in docs/working/research-2026-11-20-out-of-loop-landings.md): code
# that reached the default branch outside the build loop, each landing with
# the code-review rubric it carried, read by lib/rubric-check.sh's rubric_lines.
# Advisory: lines only, no verdict. Sourced by dev-cycle.sh after
# lib/rubric-check.sh; it gives rubric_lines the names build-loop.sh gives it
# there (gate_git, fp_blob, showpath, GATE_TMP), over the digest's own git
# (hardened by the reader lib's git_harden, in the checkout, read as data),
# and the reader lib gives MAIN_SHA, NAMECHARS and check_answer.

LANDING_CODE='^(skills|workflows|scripts|hooks)/'
GATE_TMP=""

# fp_blob and showpath are copies of build-loop.sh's (a bats case holds them
# equal). gate_git keeps its return contract only: it runs in the checkout,
# not build-loop.sh's isolated gate repository, so repo config applies; the
# one key that changes what these reads print, the log output encoding, is
# pinned to UTF-8 by the reader lib's HARDEN for every git call the digest
# makes (review R1: UTF-16 cut subjects and dropped a stale line silently;
# FP-188).
gate_git() {
  local rc=0
  git "$@" 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
  return "$rc"
}
fp_blob() {
  local x re
  gate_git ls-tree "$1" -- "$2" > "$GATE_TMP/fpls" || return 3
  [[ -s "$GATE_TMP/fpls" ]] || return 1
  x="$(cat "$GATE_TMP/fpls")" || return 3
  re=$'^(100644|100755) blob ([0123456789abcdef]+)\t'
  [[ "$x" =~ $re && "$x" == *$'\t'"$2" ]] || return 2
  gate_git cat-file blob "${BASH_REMATCH[2]}" > "$3" || return 3
}
showpath() { if [[ "$1" =~ ^[$NAMECHARS]+$ ]]; then printf '%s' "$1"; else printf '?'; fi; }

# landings_section SINCE: the section's body. A landing is a first-parent
# commit of MAIN_SHA whose committer date (%cs) is on or after SINCE, that
# changes a path under LANDING_CODE against its first parent (a root commit:
# the empty tree), and is not a build-loop merge: a merge whose message has a
# blank second line and "Build-loop-gate: STEM" as its third, where
# build-loop.sh's gate_msg writes it (a subject or a quoted line elsewhere
# does not count). That line alone decides, not --main-log's full check: this
# lists honest slips, not a disguised merge (S1). A --land-cycle merge never
# reaches the check: it changes no code path. If gate_msg's shape changes,
# change this match with it (TODO: name this reader in gate_msg's comment,
# which a change here may not edit: brief out of scope). Paths, not subjects:
# a docs(...) commit can change a skill. Each landing prints its SHA and
# subject, its code paths (up to 8) and every line rubric_lines prints for
# it (open, unread, stale, clean, superseded, or none: why none was read),
# with fix commits counted against its first parent; a root commit's rubric
# prints unread for that count, which has no parent to start from. A commit
# whose paths or message cannot be read is named on a "Not read" line and
# counted apart, never as no landing (H2). Up to 30 listed.
landings_section() {
  local since="$1" d c pars sub p1 p2 from=() s p n=0 u=0 out=() bad=() ps=() ss=() code=() msg=() l k
  if ! GATE_TMP="$(mktemp -d)"; then echo "**Out-of-loop landings were NOT checked** — a temp directory could not be made."; return 0; fi
  if ! gate_git log "$MAIN_SHA" --first-parent --format='%cs%x1f%H%x1f%P%x1f%s' > "$GATE_TMP/fp"; then
    echo "**Out-of-loop landings were NOT checked** — the default branch's first-parent history could not be listed."
    rm -rf -- "$GATE_TMP"; return 0
  fi
  # US, not a tab, between fields: IFS whitespace would merge a root commit's empty %P.
  while IFS=$'\x1f' read -r d c pars sub; do
    [[ ! "$d" < "$since" ]] || continue
    read -r p1 p2 _ <<< "$pars"
    ps=(); ss=(); code=(); from=("$p1")
    # A root commit is compared with the empty tree; with itself as BASE its rubric's fix count prints unread.
    [[ -n "${p1-}" ]] || { p1="$c"; from=(--no-commit-id --root); }
    if ! gate_git diff-tree -r -z --no-renames --name-status "${from[@]}" "$c" > "$GATE_TMP/d"; then
      u=$((u + 1)); bad+=("- Not read: ${c:0:12}: its changed paths could not be listed, so whether it changes code is unknown"); continue
    fi
    while IFS= read -r -d '' s && IFS= read -r -d '' p; do
      ps+=("$p"); ss+=("$s"); [[ ! "$p" =~ $LANDING_CODE ]] || code+=("$(showpath "$p")")
    done < "$GATE_TMP/d"
    [[ ${#code[@]} -gt 0 ]] || continue
    if [[ -n "${p2-}" ]]; then
      if ! gate_git log -1 --format=%B "$c" > "$GATE_TMP/m"; then
        u=$((u + 1)); bad+=("- Not read: ${c:0:12}: its message could not be read, so whether it is a build-loop merge is unknown"); continue
      fi
      mapfile -t -n 3 msg < "$GATE_TMP/m"
      [[ "${msg[1]-x}" == "" && "${msg[2]-}" =~ ^Build-loop-gate:\ [^[:space:]] ]] && continue
    fi
    n=$((n + 1)); [[ "$n" -le 30 ]] || continue
    k="${c:0:12}"
    out+=("- $k · ${sub:-(no subject)}")
    l="${code[*]:0:8}"; l="${l// /, }"
    [[ ${#code[@]} -le 8 ]] || l+=", … $((${#code[@]} - 8)) more"
    out+=("  - code paths (${#code[@]}): $l")
    l="$(rubric_lines "$k" "$k" "$c" ps ss "$p1")" || l=""
    [[ -n "$l" ]] || l="rubric $k: unread: the rubric check printed nothing for it"
    while IFS= read -r l; do out+=("  - rubric ${l#"rubric $k: "}"); done <<< "$l"
  done < "$GATE_TMP/fp"
  rm -rf -- "$GATE_TMP"
  if [[ "$n" -eq 0 && "$u" -eq 0 ]]; then echo "None in the window."; return 0; fi
  echo "$n code landing(s) outside the build loop; $u commit(s) not read (each named below, never counted as none). Step 4 files each landing as a roadmap item:"
  echo
  [[ ${#out[@]} -eq 0 ]] || printf '%s\n' "${out[@]}"
  [[ "$n" -le 30 ]] || echo "- … $((n - 30)) more"
  [[ ${#bad[@]} -eq 0 ]] || printf '%s\n' "${bad[@]}"
}
