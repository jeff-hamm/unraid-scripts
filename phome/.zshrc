# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Disable insecure directory check (needed for Unraid's /mnt/pool storage)
ZSH_DISABLE_COMPFIX=true

# Theme - see https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Plugins - see https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
plugins=(
    git
    docker
    docker-compose
    command-not-found
    history
    sudo
    zsh-autosuggestions
)

# Custom completions directory
fpath=($HOME/.zsh/completions $fpath)

# Completion display settings (before loading Oh My Zsh)
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select                              # Arrow key navigation
zstyle ':completion:*' group-name ''                            # Group by tag
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'  # Group headers

# Auto-display completions
setopt AUTO_MENU           # Show completion menu on successive tab press
setopt AUTO_LIST           # Automatically list choices on ambiguous completion

# Load Oh My Zsh (compinit is called by oh-my-zsh.sh)
source $ZSH/oh-my-zsh.sh

# === User Configuration ===

# Combined status indicator for prompt
prompt_status() {
    local exit_code=$?
    
    # Priority 1: Show red up arrow on command failure
    if [[ $exit_code -ne 0 ]]; then
        echo "%{$fg_bold[red]%}%1{↑%}%{$reset_color%}"
    # Priority 2: Check git status
    elif git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            # Git repo with changes: yellow *
            echo "%{$fg_bold[black]%}+%{$reset_color%}"
        else
            # Git repo clean: green checkmark
            echo "%{$fg[black]%}✓%{$reset_color%}"
        fi
    # Priority 3: No error, not in git
    else
        printf '·'
    fi
}

# Custom prompt

# Default prompt for all users
# Show user@hostname only when su'd to a different user
# Track original login user in a persistent variable
if [[ -z "$ORIGINAL_USER" ]]; then
    export ORIGINAL_USER="$USER"
fi

if [[ "$USER" != "$ORIGINAL_USER" ]]; then
    # We've su'd to a different user - show user@hostname
PROMPT='$(prompt_status) %{$fg[black]%}%n@%m:%{$reset_color%}%{$fg_bold[cyan]%}%d%{$reset_color%} %{$fg[white]%}%#%{$reset_color%} '
else
    # Original login user - just show hostname
    PROMPT='$(prompt_status) %{$fg[black]%}%m:%{$reset_color%}%{$fg_bold[cyan]%}%d%{$reset_color%} %{$fg[white]%}%#%{$reset_color%} '
fi
setopt PROMPT_SUBST

# Don't source /etc/profile - it overrides Oh My Zsh's PS1
# PATH is already set via /etc/profile.d/phome-path.sh (created by boot.d)

# Load app environment variables
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

# Load personal functions (from ~/.zsh/functions/*.zsh)
[[ -f "$HOME/.zsh/functions.zsh" ]] && source "$HOME/.zsh/functions.zsh"
load-app-envs

# Simple aliases (set after oh-my-zsh to override plugin aliases)
alias ln='lnp'
alias user='su -ls /bin/zsh'
