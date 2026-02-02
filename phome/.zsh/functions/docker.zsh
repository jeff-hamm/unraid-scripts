#!/usr/bin/env zsh
# Docker-related utility functions
# Sourced by .zshrc via functions loader

# Unset ALL aliases that could conflict (from oh-my-zsh docker plugin)
unalias d dcu dcl dcb dps dpsa 2>/dev/null || true

# @desc Docker command shortcut
d() { docker "$@" }

# @desc Docker compose up -d
dcu() { docker-compose up -d "$@" }

# @desc Docker compose logs -f
dcl() { docker-compose logs -f "$@" }

# @desc Docker compose build
dcb() { docker-compose build "$@" }

# @desc Docker ps (formatted)
#   Shows container names, status, and ports in table format
dps() { docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" "$@" }

# @desc Docker ps -a (formatted)
#   Shows all containers including stopped ones
dpsa() { docker ps -a --format "table {{.Names}}\t{{.Status}}" "$@" }

# @desc Build, restart, and tail logs for service(s)
#   Convenience wrapper for the common rebuild workflow
dc-rebuild() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: dc-rebuild <service> [service2 ...]"
        echo "Builds, restarts (up -d), and tails logs for the specified service(s)"
        return 1
    fi
    echo "Building $@..."
    docker-compose build "$@" && \
    echo "Starting $@..." && \
    docker-compose up -d --force-recreate "$@" && \
    echo "Tailing logs for $@... (Ctrl+C to exit)" && \
    docker-compose logs -f "$@"
}
