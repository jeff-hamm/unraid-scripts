#!/usr/bin/env zsh
# Shell reload and environment functions
# Sourced by .zshrc

# @desc Load app environment variables
#   Sources app-envs to set up PHOME, APP_ROOT, etc.
load-app-envs() {
    if command -v app-envs &>/dev/null; then
        source =app-envs
    elif [[ -f "${PHOME:-$HOME}/.local/bin/app-envs" ]]; then
        source "${PHOME:-$HOME}/.local/bin/app-envs"
    else
        echo "Warning: app-envs not found" >&2
        return 1
    fi
}
