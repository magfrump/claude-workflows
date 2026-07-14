#!/usr/bin/env bash
# Shared test-environment pinning. Load from a suite with:
#
#   load lib/hermetic-env          # from test/
#   load ../lib/hermetic-env       # from test/hooks/, test/scripts/, ...
#
# then call `pin_hermetic_locale` at the top of the file (or in setup()).

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
    if locale -a 2>/dev/null | grep -qxF "$candidate"; then
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
