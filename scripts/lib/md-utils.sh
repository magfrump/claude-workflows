#!/bin/bash
# Shared helpers for parsing markdown frontmatter.

# Print the YAML frontmatter block of a markdown file to stdout (without the
# surrounding `---` fences). Prints nothing if the file has no frontmatter.
#
# Usage: extract_yaml_frontmatter path/to/file.md
extract_yaml_frontmatter() {
    local file=$1
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Print the value of FIELD from the frontmatter of FILE.
# Handles inline values and quoted strings (single or double). Returns
# empty if the field is absent.
#
# Usage: get_frontmatter_field path/to/file.md persona-last-sampled
get_frontmatter_field() {
    local file=$1 field=$2
    extract_yaml_frontmatter "$file" \
        | sed -n "s/^${field}:[[:space:]]*//p" \
        | head -1 \
        | tr -d '"' \
        | tr -d "'" \
        | awk '{$1=$1; print}'
}
