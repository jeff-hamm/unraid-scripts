#!/bin/bash
# app-envs - Load application environment variables
# 
# Usage:
#   Source it:  . app-envs [PHOME] [APP_ROOT]
#   Or call it: eval "$(app-envs [PHOME] [APP_ROOT])"
#
# Arguments:
#   $1 or -p|--phome|--home|-h  PHOME path
#   $2 or -r|--root             APP_ROOT path
#   -s|--source                 Custom .env path to try first
#
# Environment discovery order (if PHOME not set):
#   1. Custom .env path (if -s specified)
#   2. Calling script's directory .env
#   3. Crawl parent directories for .env
#   4. ~/.env
#   5. $APP_ROOT/home/.env
#
# Once PHOME is set, sources $PHOME/.env and exports all variables.

_app_envs_main() {
    local arg_phome=""
    local arg_root=""
    local arg_source=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--phome|--home|-h)
                arg_phome="$2"
                shift 2
                ;;
            -r|--root)
                arg_root="$2"
                shift 2
                ;;
            -s|--source)
                arg_source="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                # Positional arguments
                if [[ -z "$arg_phome" ]]; then
                    arg_phome="$1"
                elif [[ -z "$arg_root" ]]; then
                    arg_root="$1"
                fi
                shift
                ;;
        esac
    done
    
    APP_ROOT="$arg_root"
    if [ -z "$APP_ROOT" ]; then
        if [ -f "/mnt/pool/appdata" ]
            APP_ROOT="/mnt/pool/appdata"
        else [ -f "/mnt/cache/appdata" ]
            APP_ROOT="/mnt/cache/appdata"
        else
            APP_ROOT="/mnt/user/appdata"
        fi
        echo "APP_ROOT not specified, defaulting to $APP_ROOT"
    fi
    [[ -n "$arg_phome" ]] && PHOME="$arg_phome"
    
    # If PHOME still not set, search for .env files
    if [[ -z "${PHOME:-}" ]]; then
        # Try custom source first
        if [[ -n "$arg_source" && -f "$arg_source" ]]; then
            # shellcheck disable=SC1090
            . "$arg_source"
        fi
        
        # If still not set, search from calling script's directory
        if [[ -z "${PHOME:-}" ]]; then
            local search_dir=""
            
            # Get calling script's directory (if sourced)
            if [[ -n "${BASH_SOURCE[1]:-}" ]]; then
                search_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" 2>/dev/null && pwd)"
            elif [[ -n "${0:-}" && "$0" != "-bash" && "$0" != "bash" ]]; then
                search_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
            else
                search_dir="$PWD"
            fi
            
            # Crawl up to find .env
            while [[ -n "$search_dir" && "$search_dir" != "/" ]]; do
                if [[ -f "$search_dir/.env" ]]; then
                    # shellcheck disable=SC1091
                    . "$search_dir/.env"
                    break
                fi
                search_dir="$(dirname "$search_dir")"
            done
        fi
    fi
    
    # Try ~/.env if still not set
    if [[ -z "${PHOME:-}" && -f "$HOME/.env" ]]; then
        # shellcheck disable=SC1091
        . "$HOME/.env"
    fi
    
    # Try hardcoded default if still not set
    if [[ -z "${PHOME:-}" && -f "$APP_ROOT/home/.env" ]]; then
        # shellcheck disable=SC1091
        . "$APP_ROOT/home/.env"
    fi
    
    # Set defaults if still not set
    if [ -z $PHOME ]; then
        PHOME="${PHOME:-$APP_ROOT/home}"
        echo "Phome not specified, defaulting to $PHOME"
    fi
    
    # Source $PHOME/.env if it exists and export all variables
    if [[ -f "$PHOME/.env" ]]; then
        set -a  # Auto-export all variables
        # shellcheck disable=SC1091
        . "$PHOME/.env"
        set +a
    fi
    
    # Always export core variables
    export APP_ROOT PHOME
}

# Detect if sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Executed directly - output export commands for eval
    _app_envs_main "$@"
    echo "export APP_ROOT='$APP_ROOT'"
    echo "export PHOME='$PHOME'"
    # Also output other exported vars from .env (skip core vars already printed)
    if [[ -f "$PHOME/.env" ]]; then
        grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$PHOME/.env" 2>/dev/null | while read -r line; do
            var_name="${line%%=*}"
            # Skip core vars and comments
            [[ "$var_name" =~ ^(APP_ROOT|PHOME|PATH)$ ]] && continue
            var_value="${!var_name:-}"
            [[ -n "$var_value" ]] && echo "export $var_name='$var_value'"
        done
    fi
else
    # Sourced - just run the function
    _app_envs_main "$@"
fi
