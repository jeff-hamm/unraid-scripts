#!/usr/bin/env zsh
# Functions loader - sources all .zsh files in ~/.zsh/functions/
# Also builds the ZSH_FUNCTION_DESCRIPTIONS array for autocomplete

# Get the directory of this script
local SCRIPT_DIR="${0:A:h}"

# Load parser library
[[ -f "$SCRIPT_DIR/functions/app-envs.zsh" ]] && source "$SCRIPT_DIR/functions/app-envs.zsh" && load-app-envs

source "${PHOME:-$HOME}/.zsh/lib/parse-utils.zsh"

# Source all function files
for _func_file in "${PHOME:-$HOME}/.zsh/functions/"*.zsh(N); do
    [[ -f "$_func_file" ]] && source "$_func_file"
done
unset _func_file

# Build function descriptions from all files
typeset -gA ZSH_FUNCTION_DESCRIPTIONS
_build_function_descriptions() {
    local -a parsed
    parsed=($(parse_all_function_descriptions "${PHOME:-$HOME}/.zsh/functions"))
    # Only assign if we got results and they're in pairs
    if (( ${#parsed[@]} > 0 && ${#parsed[@]} % 2 == 0 )); then
        ZSH_FUNCTION_DESCRIPTIONS=(${parsed[@]})
    fi
}
_build_function_descriptions
