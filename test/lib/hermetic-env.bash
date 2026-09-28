#!/usr/bin/env bash
# Shared test-environment pinning. Load from a suite with:
#
#   load lib/hermetic-env          # from test/
#   load ../lib/hermetic-env       # from test/hooks/, test/scripts/, ...
#
# then call `pin_hermetic_locale` at the top of the file (or in setup()).
#
# scripts/run-tests.sh also sources this file for `locale_installed`, so that
# "installed" has one definition for the runner and the suites.

# Pin a locale that is actually installed on this machine.
#
# Why this matters: bats' `run` folds stderr into $output, so anything a
# subprocess writes to stderr becomes part of the value the test asserts on.
# When the ambient LC_ALL/LANG names a locale that is *not* installed — the
# common case in a container that inherits en_US.UTF-8 from the host without
# generating it — every bash subprocess prints
#
#   bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
#
# to stderr. That noise silently breaks any assertion that treats captured
# output as exact: `[ -z "$output" ]` sees a non-empty string, and "${lines[0]}"
# is the warning rather than the first real line. Pinning the locale makes
# captured output a function of the code under test instead of the host's
# locale configuration.
pin_hermetic_locale() {
  local candidate
  for candidate in C.utf8 C.UTF-8 en_US.utf8 en_US.UTF-8; do
    if locale_installed "$candidate"; then
      export LC_ALL="$candidate" LANG="$candidate"
      unset LANGUAGE
      return 0
    fi
  done

  # POSIX guarantees C exists. It has no UTF-8 support, but it never warns,
  # which is what these assertions actually depend on.
  export LC_ALL=C LANG=C
  unset LANGUAGE
}

# _locale_normalize <name>: a simplified form of glibc's codeset
# normalisation, so "en_US.UTF-8" (what people set) and "en_US.utf8" (what
# `locale -a` lists) compare equal: the codeset part is lowercased and stripped
# of non-alphanumerics. (glibc also prefixes "iso" to an all-digit codeset;
# this does not, which only matters for names like "xx.8859-1".)
_locale_normalize() {
  local name="$1" mod="" base codeset
  if [[ "$name" == *@* ]]; then
    mod="@${name#*@}"
    name="${name%%@*}"
  fi
  if [[ "$name" == *.* ]]; then
    base="${name%%.*}"
    codeset="${name#*.}"
    codeset="${codeset,,}"
    codeset="${codeset//[^a-z0-9]/}"
    printf '%s.%s%s' "$base" "$codeset" "$mod"
  else
    printf '%s%s' "$name" "$mod"
  fi
}

# locale_installed <name>: succeed when setting LC_ALL=<name> should not make
# bash warn. Empty (unset), C and POSIX always exist; anything else must be in
# `locale -a`, compared after normalising the codeset. It can report a usable
# locale as not installed (e.g. an "@modifier" name glibc falls back from, or
# no `locale` binary on PATH); that errs safe, costing only an unneeded pin.
locale_installed() {
  local want have
  case "$1" in
    ""|C|POSIX) return 0 ;;
  esac
  want="$(_locale_normalize "$1")"
  while IFS= read -r have; do
    [[ "$(_locale_normalize "$have")" == "$want" ]] && return 0
  done < <(locale -a 2>/dev/null)
  return 1
}
