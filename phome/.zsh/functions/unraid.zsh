#!/usr/bin/env zsh
# Unraid-related utility functions
# Sourced by .zshrc via functions loader

# @desc Stop Unraid array
array-stop() {
    echo "Stopping array..."
    /usr/local/sbin/emcmd cmdStop=Stop
}

# @desc Start Unraid array
array-start() {
    echo "Starting array..."
    /usr/local/sbin/emcmd cmdStart=Start
}
