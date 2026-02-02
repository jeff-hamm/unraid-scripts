#!/usr/bin/env zsh
# General utility functions
# Sourced by .zshrc via functions loader

# @desc Midnight Commander (preserves CWD)
mc() {
    unalias mc 2>/dev/null
    local f=$(mktemp)
    command mc -P "$f" "$@"
    [[ -s "$f" ]] && cd "$(cat "$f")"
    rm -f "$f"
}
