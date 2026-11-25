export PATH="$HOME/.local/bin:$PATH"   # devclean + native claude
# Personal commands take precedence; keep PATH entries unique on reload.
typeset -U path PATH
path=("$HOME/.local/bin" $path)

# Keep a larger, shared history. A leading space keeps a command out of history.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=40000
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE HIST_FIND_NO_DUPS
unsetopt BEEP

# Tab completion with a selectable menu and case-insensitive matching.
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'

# Search history using the text already typed when pressing Up/Down.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
[[ -n ${terminfo[kcuu1]} ]] && bindkey "$terminfo[kcuu1]" up-line-or-beginning-search
[[ -n ${terminfo[kcud1]} ]] && bindkey "$terminfo[kcud1]" down-line-or-beginning-search

# Ctrl-R: search history. Ctrl-T: pick files. Option-C: pick a directory.
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# z <folder-name> jumps to a previously visited directory; zi opens a picker.
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# Inline suggestions from history; Right Arrow accepts the suggestion.
if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Switch themes only after a successful download; retain the previous theme.
unalias posh 2>/dev/null
posh() {
  if (( $# != 1 )) || [[ "$1" == *[^a-zA-Z0-9_-]* || -z "$1" ]]; then
    print -u2 'Usage: posh <theme-name>'
    return 1
  fi
  local theme_tmp
  theme_tmp=$(mktemp "${TMPDIR:-/tmp}/posh-theme.XXXXXX") || return
  if curl -fsSL -o "$theme_tmp" "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/${1}.omp.json"; then
    cp "$HOME/.poshtheme.json" "$HOME/.poshtheme.previous.json" &&
      mv "$theme_tmp" "$HOME/.poshtheme.json" &&
      eval "$(oh-my-posh init zsh --config "$HOME/.poshtheme.json")"
  else
    rm -f "$theme_tmp"
    return 1
  fi
}

skillzip() { (cd ~/.agents/skills && zip -r ~/Desktop/"$1".zip "$1" -x "*.DS_Store"); }

if (( $+commands[oh-my-posh] )); then
  eval "$(oh-my-posh init zsh --config "$HOME/.poshtheme.json")"
fi
setopt interactive_comments
