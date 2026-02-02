#!/usr/bin/env zsh
# Shell reload and environment functions
# Sourced by .zshrc

# @desc Reload zsh completions
#   Rebuilds the completion cache without restarting shell
reload-completions() {
    autoload -U compinit && compinit
    echo "Completions reloaded"
}

unalias ls 2>/dev/null
# @desc List files with group-based coloring
#   Colors user/group: root=yellow, users=green
ls() {
    command ls -lAt --color=always "$@" | awk '
    BEGIN { 
        YELLOW="\033[1;33m"
        GREEN="\033[1;32m"
        RESET="\033[0m"
    }
    NR==1 { print; next }  # Print header as-is
    {
        # Match user and group names (fields 3 and 4)
        if (match($0, /^([^ ]+ +[^ ]+ +)([^ ]+)( +)([^ ]+)(.*)$/, arr)) {
            group = arr[4]
            if (group == "root")
                color = YELLOW
            else
                color = GREEN
            
            print arr[1] color arr[2] RESET arr[3] color arr[4] RESET arr[5]
        } else {
            print
        }
    }'
}
