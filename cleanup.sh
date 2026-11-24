#!/usr/bin/env bash
# cleanup.sh: the parts of dev cleanup that need your real Terminal.
# Run:  bash ~/Developer/dotfiles/cleanup.sh        (add --claude-sessions to also wipe Claude Code session history)
set -u
DOT="$HOME/Developer/dotfiles"
say(){ printf "\n\033[1m▸ %s\033[0m\n" "$1"; }

say "Disk before"; df -h ~ | tail -1

say "Homebrew"
brew update >/dev/null
brew services list | grep -i dnscrypt && echo "  ↑ dnscrypt still registered. Run: sudo brew services stop dnscrypt-proxy && brew uninstall dnscrypt-proxy"
brew upgrade
brew autoremove
brew cleanup --prune=all -s
brew bundle dump --file="$DOT/Brewfile" --force && echo "  Brewfile written to $DOT/Brewfile (edit it, then 'brew bundle cleanup --file=$DOT/Brewfile --force' removes anything not listed)"

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
