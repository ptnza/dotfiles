#!/usr/bin/env bash
# cleanup.sh: the parts of dev cleanup that need your real Terminal.
# Run:  bash ~/Developer/dotfiles/cleanup.sh        (add --claude-sessions to also wipe Claude Code session history)
set -u
DOT="$HOME/Developer/dotfiles"
say(){ printf "\n\033[1m▸ %s\033[0m\n" "$1"; }

say "Disk before"; df -h ~ | tail -1

say "Homebrew"
brew update >/dev/null
# dnscrypt-proxy runs as a root service; Homebrew cannot upgrade it in place, so skip it by name.
UPG=$(brew outdated --quiet | grep -vx dnscrypt-proxy || true)
[ -n "$UPG" ] && brew upgrade $UPG || echo "  nothing to upgrade"
brew outdated --quiet | grep -qx dnscrypt-proxy && echo "  ⚠ dnscrypt-proxy has an update (skipped on purpose, root service). Run: bash $DOT/dnscrypt/upgrade.sh"
brew autoremove
brew cleanup --prune=all -s
brew bundle dump --file="$DOT/Brewfile" --force && echo "  Brewfile written to $DOT/Brewfile (edit it, then 'brew bundle cleanup --file=$DOT/Brewfile --force' removes anything not listed)"
grep -q '^brew "dnscrypt-proxy"' "$DOT/Brewfile" || printf '# Encrypted DNS (root service; installed by dnscrypt/setup.sh)\nbrew "dnscrypt-proxy"\n' >> "$DOT/Brewfile"   # dump cannot see root-owned installs

say "npm"
npm cache clean --force 2>/dev/null
rm -rf ~/.npm/_npx ~/.npm/_logs
echo "  done"

say "Shell"
rm -rf ~/.zsh_sessions/*
rm -rf ~/.zcompdump* ~/.zcompcache/* 2>/dev/null   # rebuilt on next shell start
cp ~/.zshrc "$DOT/.zshrc" 2>/dev/null && echo "  .zshrc backed up to dotfiles"

say "Claude Code"
echo "  claude binaries on PATH:"; which -a claude | sed 's/^/    /'
[ "$(which -a claude | sort -u | wc -l)" -gt 1 ] && echo "  ⚠ more than one install. Keep the native one (~/.local/bin/claude); remove an npm copy with: npm rm -g @anthropic-ai/claude-code"
[ -d ~/.local/share/claude ] && [ ! -e ~/.local/bin/claude ] && echo "  ⚠ native install exists but ~/.local/bin/claude link is missing. Fix with: claude install"
du -sh ~/.claude/* ~/.claude.json 2>/dev/null | sort -hr | head -10
rm -rf ~/.claude/{todos,shell-snapshots,statsig,debug,file-history}
if [[ "${1:-}" == "--claude-sessions" ]]; then rm -rf ~/.claude/projects; echo "  session history wiped"; fi
cp ~/.claude/settings.json "$DOT/claude/" 2>/dev/null
cp ~/.claude/CLAUDE.md "$DOT/claude/" 2>/dev/null
echo "  settings.json / CLAUDE.md backed up to dotfiles/claude"

say "Health"; brew doctor
say "Disk after"; df -h ~ | tail -1

say "App configs"
# Mirrors each file (relative to $HOME) into $DOT/home/. Add a path here to track it.
CONFIGS=(
  ".config/zed/settings.json"
  ".config/git/ignore"
  ".config/ohmyposh.omp.json"
  ".config/opencode/opencode.json"
  ".config/neofetch/config.conf"
  ".poshtheme.json"
  ".gitconfig"
)
for f in "${CONFIGS[@]}"; do
  if [ -f "$HOME/$f" ]; then mkdir -p "$DOT/home/$(dirname "$f")" && cp "$HOME/$f" "$DOT/home/$f" && echo "  $f"
  else echo "  (skipped, not found) $f"; fi
done
# Ghostty: macOS keeps it in Application Support, but ~/.config/ghostty/config also works. Stored as ghostty.conf.
GHOSTTY=""
for p in "$HOME/Library/Application Support/com.mitchellh.ghostty/config" "$HOME/.config/ghostty/config"; do
  [ -f "$p" ] && GHOSTTY="$p" && break
done
if [ -n "$GHOSTTY" ]; then cp "$GHOSTTY" "$DOT/ghostty.conf" && echo "  ghostty → ghostty.conf"; else echo "  (skipped, not found) ghostty config"; fi

say "Dotfiles sync"
if git -C "$DOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$DOT" add -A
  if git -C "$DOT" diff --cached --quiet; then echo "  nothing changed"
  else
    git -C "$DOT" commit -qm "devclean sync $(date +%F)" && echo "  committed"
    if git -C "$DOT" remote get-url origin >/dev/null 2>&1; then
      if command -v gitleaks >/dev/null && ! gitleaks detect --source "$DOT" --no-banner -l error; then
        echo "  ⚠ gitleaks flagged something, NOT pushed. See: gitleaks detect --source $DOT -v"
      else git -C "$DOT" push -q && echo "  pushed"; fi
    else echo "  (no remote yet, committed locally)"; fi
  fi
else echo "  dotfiles is not a git repo"; fi
