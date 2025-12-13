# Persistent Home Directory

This directory contains persistent configuration and scripts for the Unraid system user home directory.

## Structure

- `.bashrc` - Bash shell configuration
- `.github/` - GitHub Copilot instructions
- `.conf/` - Configuration files (symlinks.conf, etc.)
- `.local/bin/` - User scripts and utilities
- `boot.d/` - Scripts that run on system boot
- `.auth/` - Authentication files (gitignored, use GitHub secrets or .env.example)
- `.env.example` - Example environment variables

## Setup

1. Create `.env` from `.env.example` and fill in your values
2. Create `.auth/` directory and add your auth files
3. Run boot.d scripts to set up persistent environment

## GitHub Secrets

For CI/CD or deployment, store these secrets in GitHub:
- `COPILOT_TOKEN`
- `HA_API_KEY`
- `IMMICH_API_KEY`
- `GH_CONFIG` (contents of .auth/gh/config.yml)
- `GH_HOSTS` (contents of .auth/gh/hosts.yml)
