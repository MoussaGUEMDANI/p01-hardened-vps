#!/usr/bin/env bash
# verify.sh — check a server matches the P01 baseline. Run with sudo.
set -uo pipefail
fail=0
check() { if eval "$2" &>/dev/null; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi; }

check "deploy user in sudo group"   "id -nG deploy | grep -w sudo"
check "root login disabled"         "sshd -T | grep -x 'permitrootlogin no'"
check "password auth disabled"      "sshd -T | grep -x 'passwordauthentication no'"
check "UFW active"                  "ufw status | grep 'Status: active'"
check "UFW denies incoming"         "ufw status verbose | grep 'deny (incoming)'"
check "fail2ban sshd jail running"  "fail2ban-client status sshd"
check "auto-upgrades enabled"       "apt-config dump | grep 'Unattended-Upgrade \"1\"'"

exit $fail
