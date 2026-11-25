#!/usr/bin/env bash
# Encrypted DNS on this Mac via dnscrypt-proxy.
# Order is deliberate: install, configure, validate, start, TEST, and only then point Wi-Fi DNS at it.
# If anything fails before the last step your DNS is untouched.
# Run:  bash ~/Developer/dotfiles/dnscrypt/setup.sh
set -euo pipefail
SVC="Wi-Fi"
say(){ printf '\n\033[1m▸ %s\033[0m\n' "$1"; }

say "Install"
brew list dnscrypt-proxy >/dev/null 2>&1 || brew install dnscrypt-proxy
PREFIX="$(brew --prefix)"
CONF="$PREFIX/etc/dnscrypt-proxy.toml"
if [ ! -f "$CONF" ]; then
  EX="$(find "$PREFIX" -name 'example-dnscrypt-proxy.toml' -print -quit 2>/dev/null || true)"
  [ -n "$EX" ] || { echo "No config or example config found under $PREFIX"; exit 1; }
  cp "$EX" "$CONF"
fi
cp -n "$CONF" "$CONF.default" 2>/dev/null || true
cp "$CONF.default" "$CONF"   # always start from the clean default so re-runs are safe

say "Configure ($CONF)"
# Replace ONLY the first server_names line (the default file has commented examples that must stay comments).
# listen_addresses is left alone: Homebrew's default is already 127.0.0.1:53.
awk 'BEGIN{d=0} /^[# ]*server_names *=/ && !d {print "server_names = [\047cloudflare\047, \047quad9-dnscrypt-ip4-filter-pri\047]"; d=1; next} {print}' "$CONF.default" > "$CONF.new" && mv "$CONF.new" "$CONF"
for k in server_names listen_addresses; do
  n=$(grep -cE "^$k *=" "$CONF" || true)
  [ "$n" -eq 1 ] || { echo "Expected exactly 1 active $k, found $n. Restoring default and stopping."; cp "$CONF.default" "$CONF"; exit 1; }
done
grep -E "^(server_names|listen_addresses)" "$CONF"
dnscrypt-proxy -config "$CONF" -check

say "Start service (needs sudo: port 53 is privileged)"
sudo brew services restart dnscrypt-proxy

say "Wait for it to answer (first start downloads the resolver list)"
ok=0
for i in $(seq 1 30); do
  if dig +short +time=2 +tries=1 @127.0.0.1 cloudflare.com 2>/dev/null | grep -qE '^[0-9]'; then ok=1; break; fi
  sleep 1
done
if [ "$ok" -ne 1 ]; then
  echo "dnscrypt-proxy did not answer in 30s. Your DNS has NOT been changed."
  echo "See the error with:  sudo dnscrypt-proxy -config $CONF"
  exit 1
fi
echo "answering on 127.0.0.1"

say "Which resolvers it picked"
dnscrypt-proxy -config "$CONF" -resolve cloudflare.com 2>&1 | grep -iE "resolver|server|ip" | head -8 || true

say "Point Wi-Fi DNS at it"
sudo networksetup -setdnsservers "$SVC" 127.0.0.1
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder || true

say "Check"
echo "uncached vs cached lookup (ms):"
n="t$RANDOM$RANDOM.example.com"
for k in 1 2; do dig +tries=1 +time=3 "$n" | awk '/Query time/{print "  "$4" ms"}'; done
dnsmode status
echo
echo "Done. Verify encryption at https://dnscheck.tools"
echo "On captive-portal Wi-Fi (hotels, airports):  dnsmode off   then   dnsmode on"
