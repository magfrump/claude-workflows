find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  awk '/^[[:space:]]*```/ { fence = !fence; print ""; next } fence { print ""; next } { print }' "$1" \
    | sed -E 's/``([^`]|`[^`])*``//g; s/`[^`]*`//g' \
    | grep -nE '(^|[[:space:]*_])@(\./|~/|/|[[:alnum:]._-])'
}
