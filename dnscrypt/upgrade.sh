#!/usr/bin/env bash
# Upgrade dnscrypt-proxy. It runs as a root service, so Homebrew can't replace it on its own.
# Order matters: DNS must be switched off first, or brew has no DNS to download with.
# Run:  bash ~/Developer/dotfiles/dnscrypt/upgrade.sh
set -u
dnsmode off
sudo brew services stop dnscrypt-proxy
# root-owned paths named in Homebrew's own warning
sudo rm -rf /opt/homebrew/Cellar/dnscrypt-proxy/*/sbin \
            /opt/homebrew/opt/dnscrypt-proxy \
            /opt/homebrew/var/homebrew/linked/dnscrypt-proxy
brew upgrade dnscrypt-proxy
sudo brew services start dnscrypt-proxy
sleep 5
dnsmode on
dnsmode status
