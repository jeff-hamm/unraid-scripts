#!/bin/bash
#
# Install zsh + Oh My Zsh on boot
# Since /usr/bin is volatile, zsh must be reinstalled each boot
# Oh My Zsh lives in $PHOME/.oh-my-zsh (persistent)
#

set -e

PHOME="${PHOME:-/mnt/pool/appdata/home}"
ZSH_HOME="$PHOME/.oh-my-zsh"
ZSHRC="$PHOME/.zshrc"

echo "=== Installing zsh + Oh My Zsh ==="

# Check if zsh is already available
if command -v zsh &>/dev/null; then
    echo "  zsh already installed: $(zsh --version)"
else
    echo "  Installing zsh from Slackware mirror..."
    
    # Download zsh package directly from Slackware mirrors
    # Auto-detect the exact package name
    MIRROR_BASE="https://mirrors.slackware.com/slackware/slackware64-current/slackware64/ap"
    ZSH_PKG_NAME=$(curl -sL "$MIRROR_BASE/" | grep -oE 'zsh-[0-9][^"]*\.txz' | head -1)
    
    if [[ -z "$ZSH_PKG_NAME" ]]; then
        echo "  ✗ Could not find zsh package in mirror"
        exit 1
    fi
    
    ZSH_PKG_URL="$MIRROR_BASE/$ZSH_PKG_NAME"
    ZSH_PKG="/tmp/zsh.txz"
    
    echo "  Downloading $ZSH_PKG_NAME..."
    if curl -fsSL "$ZSH_PKG_URL" -o "$ZSH_PKG"; then
        installpkg "$ZSH_PKG"
        rm -f "$ZSH_PKG"
        echo "  ✓ zsh installed from Slackware package"
    else
        echo "  ✗ Failed to download zsh package"
        exit 1
    fi
fi

# Verify zsh is working
if ! command -v zsh &>/dev/null; then
    echo "  ✗ zsh not found after installation"
    exit 1
fi

ZSH_PATH="$(which zsh)"
echo "  zsh path: $ZSH_PATH"

# Install Oh My Zsh if not present
if [[ -d "$ZSH_HOME" ]]; then
    echo "  Oh My Zsh already installed at $ZSH_HOME"
else
    echo "  Installing Oh My Zsh to $ZSH_HOME..."
    
    # Clone Oh My Zsh (unattended install)
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_HOME" 2>/dev/null
    echo "  ✓ Oh My Zsh installed"
fi

# Create .zshrc if not present
if [[ ! -f "$ZSHRC" ]]; then
    echo "  Creating $ZSHRC..."
    cat > "$ZSHRC" << 'ZSHRC_EOF'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

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
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# === User Configuration ===

# Source /etc/profile for system paths
[[ -f /etc/profile ]] && emulate sh -c 'source /etc/profile'

# Source app-envs to load environment variables
if command -v app-envs &>/dev/null; then
    emulate sh -c '. app-envs'
elif [[ -f "$HOME/.local/bin/app-envs" ]]; then
    emulate sh -c '. $HOME/.local/bin/app-envs'
fi

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcl='docker-compose logs -f'
alias dcb='docker-compose build'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}"'

# Symlink helper
alias ln="lnp"

# Misc aliases
alias v="ls -lA"
alias user="su -ls /bin/bash"  # impersonate a user

# Docker-compose helper function
# Usage: dcr <service> [service2 ...]
# Builds, restarts, and tails logs for the specified service(s)
dcr() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: dcr <service> [service2 ...]"
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

# Unraid array control (sourced from bashrc logic)
array-stop() {
    echo "Stopping array..."
    /usr/local/sbin/emcmd cmdStop=Stop
}

array-start() {
    echo "Starting array..."
    /usr/local/sbin/emcmd cmdStart=Start
}

# MC: preserve CWD on exit
mc() {
    local f=$(mktemp)
    command mc -P "$f" "$@"
    [[ -s "$f" ]] && cd "$(cat "$f")"
    rm -f "$f"
}
ZSHRC_EOF
    echo "  ✓ Created $ZSHRC"
else
    echo "  .zshrc already exists at $ZSHRC"
fi

# Update root's shell in /etc/passwd
CURRENT_SHELL=$(grep '^root:' /etc/passwd | cut -d: -f7)
if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
    echo "  Changing root shell from $CURRENT_SHELL to $ZSH_PATH..."
    
    # Add zsh to /etc/shells if not present
    if ! grep -q "^$ZSH_PATH$" /etc/shells 2>/dev/null; then
        echo "$ZSH_PATH" >> /etc/shells
        echo "  Added $ZSH_PATH to /etc/shells"
    fi
    
    # Use chsh or direct sed
    if command -v chsh &>/dev/null; then
        chsh -s "$ZSH_PATH" root 2>/dev/null || \
            sed -i "s|^root:\(.*\):[^:]*$|root:\1:$ZSH_PATH|" /etc/passwd
    else
        sed -i "s|^root:\(.*\):[^:]*$|root:\1:$ZSH_PATH|" /etc/passwd
    fi
    
    echo "  ✓ Root shell changed to zsh"
else
    echo "  Root shell already set to $ZSH_PATH"
fi

# Symlink .oh-my-zsh to /root if not already done (05-symlink will handle .zshrc)
if [[ ! -L /root/.oh-my-zsh ]] && [[ -d "$ZSH_HOME" ]]; then
    rm -rf /root/.oh-my-zsh 2>/dev/null || true
    ln -sf "$ZSH_HOME" /root/.oh-my-zsh
    echo "  ✓ Symlinked /root/.oh-my-zsh -> $ZSH_HOME"
fi

echo "=== zsh + Oh My Zsh ready ==="
