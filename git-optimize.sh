#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Logging helper functions
log_info() {
    echo -e "\033[36m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

log_info "Starting Windows Git configuration script..."

# --- Core Settings ---
log_info "Configuring core settings..."

log_info "Setting global excludes file to '~/.gitignore'..."
git config --global core.excludesfile '~/.gitignore'

log_info "Setting text editor to 'nvim'..."
git config --global core.editor 'nvim'

log_info "Disabling automatic CRLF conversion (core.autocrlf = false)..."
git config --global core.autocrlf 'false'

log_info "Enabling untracked cache (core.untrackedCache = true)..."
git config --global core.untrackedCache 'true'

log_info "Enabling file system cache (core.fscache = true)..."
git config --global core.fscache 'true'

log_info "Enabling file system monitor daemon (core.fsmonitor = true)..."
git config --global core.fsmonitor 'true'

log_info "Enabling index preloading (core.preloadindex = true)..."
git config --global core.preloadindex 'true'

log_info "Enabling split index format (core.splitIndex = true)..."
git config --global core.splitIndex 'true'

log_info "Setting core compression level to 1..."
git config --global core.compression '1'

# --- Feature Flags ---
log_info "Configuring feature flags..."
log_info "Disabling manyFiles feature optimization..."
git config --global feature.manyFiles 'false'

# --- Packing & Garbage Collection ---
log_info "Configuring pack and garbage collection settings..."
git config --global pack.compression '1'
git config --global pack.threads '0'
git config --global pack.windowMemory '512m'
git config --global pack.packSizeLimit '512m'
git config --global gc.auto '256'

# --- Index & Protocol ---
log_info "Configuring index parallelism and protocol version..."
git config --global index.threads 'true'
git config --global index.version '4'
git config --global protocol.version '2'

# --- Remotes, Checkout & Push ---
log_info "Configuring remotes, checkout workers, and push tracking..."
git config --global remote.origin.tagOpt '--no-tags'
git config --global checkout.workers '0'
git config --global checkout.thresholdForParallelism '100'
git config --global push.autoSetupRemote 'True'

# --- Maintenance Repositories ---
log_info "Cleaning up old maintenance registrations..."
git config --global --unset-all maintenance.repo 2>/dev/null || true

log_info "Registering base configuration repo: C:/Users/dreis/windowsconfig"
git config --global --add maintenance.repo "C:/Users/dreis/windowsconfig"

# Dynamically scan Projects directory
PROJECTS_DIR="/c/Users/dreis/Projects"
if [ -d "$PROJECTS_DIR" ]; then
    log_info "Scanning '$PROJECTS_DIR' for Git repositories..."
    for dir in "$PROJECTS_DIR"/*; do
        if [ -d "$dir/.git" ]; then
            REPO_NAME=$(basename "$dir")
            WIN_PATH="C:/Users/dreis/Projects/$REPO_NAME"
            log_info "Discovered Git repository -> Registering: $WIN_PATH"
            git config --global --add maintenance.repo "$WIN_PATH"
        fi
    done
else
    log_info "Warning: Projects directory not found at $PROJECTS_DIR."
fi

log_info "Enabling background maintenance automation and strategy..."
git config --global maintenance.auto 'true'
git config --global maintenance.strategy 'incremental'

log_success "Git configuration successfully applied with all repositories registered!"
