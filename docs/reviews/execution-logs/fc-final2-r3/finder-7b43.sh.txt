find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  sed -E 's/`[^`]*`//g' "$1" \
    | grep -nE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$)))'
}
