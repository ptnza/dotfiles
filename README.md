# dotfiles

My Mac dev setup: Homebrew, Ghostty, Oh My Posh, encrypted DNS, and a monthly cleanup.

| File | What it does |
|---|---|
| `cleanup.sh` | The engine behind `devclean`: updates brew, prunes caches, dumps the Brewfile, commits and pushes (after a secrets scan) |
| `Brewfile` | Everything installed via Homebrew (`brew bundle`) |
| `harden.sh` | macOS hardening checklist, trimmed from [drduh's guide](https://github.com/drduh/macos-security-and-privacy-guide). Report by default, `--apply` to fix |
| `dnscrypt/` | Encrypted DNS via dnscrypt-proxy (`setup.sh`, `upgrade.sh`) |
| `ghostty.conf` | My full Ghostty config, synced by `devclean` |
| `oh-my-posh-segment.json`, `zshrc-snippet.sh` | Prompt and shell bits |
| `home/` | Mirror of app configs (Zed, git, Oh My Posh, opencode, neofetch), synced by `devclean`. Add paths to `CONFIGS` in `cleanup.sh` |
| `restore.sh` | Copies `home/` back into `~` on a new Mac (`--force` to overwrite) |
| `hooks/pre-push` | gitleaks scan before every push |

## Use

```bash
brew bundle --file=Brewfile        # install everything
bash harden.sh                     # check the Mac
bash harden.sh --apply             # fix what it can
git config core.hooksPath hooks    # enable the secrets scan
```

Secrets live in `~/.zshrc.local`, which is gitignored.
