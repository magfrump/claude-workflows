#!/bin/bash
# Shared color/log helpers. Output is ANSI-colored on a TTY, plain otherwise,
# so piping or redirecting captures clean text.

if [ -t 1 ]; then
    red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
    green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
    yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
    bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
else
    red()    { printf '%s\n' "$*"; }
    green()  { printf '%s\n' "$*"; }
    yellow() { printf '%s\n' "$*"; }
    bold()   { printf '%s\n' "$*"; }
fi
