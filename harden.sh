#!/bin/bash
# harden.sh — macOS hardening checklist (trimmed from drduh/macos-security-and-privacy-guide)
#   bash harden.sh           report only, changes nothing
#   bash harden.sh --apply   fix what's fixable (asks for sudo once)
# Safe to re-run. Skips anything already in place.

APPLY=0; [ "$1" = "--apply" ] && APPLY=1
FW=/usr/libexec/ApplicationFirewall/socketfilterfw
ZSHRC="$HOME/.zshrc"
ok()   { printf "  ✓ %s\n" "$1"; }
fix()  { printf "  ✗ %s\n" "$1"; }
todo() { printf "  → %s\n" "$1"; }
sec()  { printf "\n%s\n" "$1"; }

[ "$APPLY" = 1 ] && sudo -v

sec "Disk, boot, integrity"
fdesetup status | grep -q "is On"        && ok "FileVault on"        || fix "FileVault off (System Settings → Privacy & Security)"
csrutil status | grep -q "enabled"       && ok "SIP enabled"         || fix "SIP disabled (re-enable from Recovery)"
spctl --status | grep -q "enabled"       && ok "Gatekeeper on"       || fix "Gatekeeper off: sudo spctl --global-enable"

sec "Firewall"
if $FW --getglobalstate | grep -q "enabled"; then ok "Firewall on"
else fix "Firewall off"; [ "$APPLY" = 1 ] && sudo $FW --setglobalstate on && ok "  → turned on"; fi
if $FW --getstealthmode | grep -qi "enabled"; then ok "Stealth mode on"
else fix "Stealth mode off"; [ "$APPLY" = 1 ] && sudo $FW --setstealthmode on && ok "  → turned on"; fi

sec "Homebrew"
if [ "$(brew analytics state 2>/dev/null | head -1)" = "InfluxDB analytics are disabled." ] || brew analytics state 2>/dev/null | grep -qi "disabled"; then ok "Analytics off"
else fix "Analytics on"; [ "$APPLY" = 1 ] && brew analytics off && ok "  → turned off"; fi
if grep -q HOMEBREW_NO_INSECURE_REDIRECT "$ZSHRC" 2>/dev/null; then ok "Insecure-redirect guard in .zshrc"
else fix "HOMEBREW_NO_ANALYTICS / NO_INSECURE_REDIRECT missing from .zshrc"
  if [ "$APPLY" = 1 ]; then
    printf '\n# Homebrew hardening\nexport HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSECURE_REDIRECT=1\n' >> "$ZSHRC" && ok "  → added (run: exec zsh)"
  fi
fi

sec "sudo with Touch ID"
if grep -qs '^auth.*pam_tid.so' /etc/pam.d/sudo_local; then ok "Touch ID for sudo on (note: not inside tmux)"
else fix "Touch ID for sudo off"
  if [ "$APPLY" = 1 ] && [ -f /etc/pam.d/sudo_local.template ]; then
    sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null && ok "  → enabled (survives OS updates)"
  fi
fi

sec "DNS"
scutil --dns | grep -q "127.0.0.1" && ok "System DNS → 127.0.0.1 (dnscrypt-proxy)" || fix "System DNS not on dnscrypt (run: dnsmode on)"
pgrep -x dnscrypt-proxy >/dev/null || sudo pgrep -x dnscrypt-proxy >/dev/null && ok "dnscrypt-proxy running" || fix "dnscrypt-proxy not running"

sec "Backups"
if tmutil destinationinfo 2>/dev/null | grep -q "Name"; then ok "Time Machine destination set"; todo "Confirm it's encrypted and do a test restore"
else fix "No Time Machine destination"; fi

sec "Manual (can't be scripted)"
todo "Chrome: chrome://settings/security → Use secure DNS = off, or it bypasses dnscrypt"
todo "Chrome: install uBlock Origin Lite"
todo "iCloud: Advanced Data Protection + iMessage Contact Key Verification (System Settings → your name)"
todo "Software Update: Command Line Tools"
[ "$APPLY" = 0 ] && printf "\nReport only. Fix what's marked ✗ with: bash %s --apply\n" "$0"
