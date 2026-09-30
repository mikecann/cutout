#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-${HOME}/.local/bin}"
if [[ $# -gt 1 || "$TARGET_DIR" == -* ]]; then
  echo 'Usage: uninstall.sh [target_bin_dir]' >&2
  exit 1
fi
if [[ -L "$TARGET_DIR/cutout" && "$(readlink "$TARGET_DIR/cutout")" == "$ROOT/cutout" ]]; then
  rm "$TARGET_DIR/cutout"
  echo "Removed $TARGET_DIR/cutout"
else
  echo 'No cutout symlink belonging to this clone to remove.'
fi
