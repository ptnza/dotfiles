#!/bin/bash
# restore.sh — put tracked configs (home/) back into $HOME on a fresh Mac.
#   bash restore.sh          copies only files that don't exist yet
#   bash restore.sh --force  overwrites existing files
DOT="$(cd "$(dirname "$0")" && pwd)"
FORCE=0; [ "$1" = "--force" ] && FORCE=1
cd "$DOT/home" || exit 1
find . -type f ! -name .DS_Store | sed 's|^\./||' | while IFS= read -r f; do
  if [ -e "$HOME/$f" ] && [ "$FORCE" = 0 ]; then echo "  exists, skipped: $f"
  else mkdir -p "$HOME/$(dirname "$f")" && cp "$DOT/home/$f" "$HOME/$f" && echo "  restored: $f"; fi
done
echo "Next: cp $DOT/.zshrc ~/.zshrc, brew bundle --file=$DOT/Brewfile, then exec zsh"
