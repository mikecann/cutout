#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-${HOME}/.local/bin}"
if [[ $# -gt 1 || "$TARGET_DIR" == -* ]]; then
  echo 'Usage: install.sh [target_bin_dir]' >&2
  exit 1
fi
mkdir -p "$TARGET_DIR"
if [[ -e "$TARGET_DIR/cutout" && ! -L "$TARGET_DIR/cutout" ]]; then
  echo "Refusing to replace an existing file: $TARGET_DIR/cutout" >&2
  exit 1
fi
chmod +x "$ROOT/cutout"
ln -sfn "$ROOT/cutout" "$TARGET_DIR/cutout"
echo "Installed $TARGET_DIR/cutout -> $ROOT/cutout"
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) echo "Add to ~/.zshrc or ~/.bashrc: export PATH=\"$TARGET_DIR:\$PATH\"" ;;
esac
echo 'Install rembg in your Python environment first (see README.md).'
