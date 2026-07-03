#!/usr/bin/env bash

set -e

# 1. Enable macro switch for large repositories
if [ "$(git config --global feature.manyFiles)" != "true" ]; then
    echo "Updating feature.manyFiles to true"
    git config --global feature.manyFiles true
fi

# 2. Enable Windows Native Filesystem Monitor & Untracked Cache
if [ "$(git config --global core.fsmonitor)" != "true" ]; then
    echo "Updating core.fsmonitor to true"
    git config --global core.fsmonitor true
fi
if [ "$(git config --global core.untrackedCache)" != "true" ]; then
    echo "Updating core.untrackedCache to true"
    git config --global core.untrackedCache true
fi

# 3. Enable I/O and File Stat Caching
if [ "$(git config --global core.fscache)" != "true" ]; then
    echo "Updating core.fscache to true"
    git config --global core.fscache true
fi

# 4. Force git to use git native fs monitor
if [ "$(git config --global core.useBuiltinFSMonitor)" != "true" ]; then
    echo "Updating core.useBuiltinFSMonitor to true"
    git config --global core.useBuiltinFSMonitor true 
fi

# 5. Increasing checkout workers
if [ "$(git config --global checkout.workers)" != "4" ]; then
    echo "Updating checkout.workers to 4"
    git config --global checkout.workers 4
fi

# 6. Updating checkout workers threshold
if [ "$(git config --global checkout.threshold)" != "1000" ]; then
    echo "Updating checkout.threshold to 1000"
    git config --global checkout.threshold 1000
fi

# 7. Check if inside a local repository to run repo-specific tweaks
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Running repository-specific optimizations..."
    git commit-graph write --reachable --changed-paths
    git maintenance start
fi
