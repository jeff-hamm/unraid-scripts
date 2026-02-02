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
#zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
#zstyle ':completion:*:messages' format '%F{cyan}-- %d --%f'
zstyle ':completion:*' menu select  # Enable arrow key navigation
#zstyle ':completion:*' list-prompt ''
#zstyle ':completion:*' select-prompt ''

# Auto-display completions
setopt AUTO_MENU           # Show completion menu on successive tab press
setopt AUTO_LIST           # Automatically list choices on ambiguous completion

# Load Oh My Zsh (compinit is called by oh-my-zsh.sh)
source $ZSH/oh-my-zsh.sh

# === User Configuration ===

# Custom prompt: username@hostname: + robbyrussell theme
# ' $(git_prompt_info)'
PROMPT="%(?:%{$fg_bold[green]%}%1{↑%} :%{$fg_bold[red]%}%1{↑%} )%{$fg[yellow]%}%m:%{$reset_color%}%{$fg[cyan]%}%d%{$reset_color%} %{$fg_bold[white]%}%#%{$reset_color%} "

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
