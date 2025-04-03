#!/usr/bin/env bash

# source and run thorne theme

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=$current_dir
tmux set-environment -g "@thorne-root" "$ROOT_DIR"

$current_dir/scripts/thorne.sh
