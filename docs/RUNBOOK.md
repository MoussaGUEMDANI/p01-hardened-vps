# Runbook — P01

## Lab server
- Created with: `multipass launch 24.04 --name p01-vps --cpus 1 --memory 1G --disk 10G`
- Specs mirror a ~€5 VPS (1 vCPU / 1 GB / 10 GB)

## First-contact checklist
lsb_release -a; uptime; free -h; df -h; ip -br a; sudo ss -tulpn

## Admin User (Issue #1)
- User `deploy`, member of `sudo`, password disabled (key-only)
- Sudo rule: /etc/sudoers.d/90-deploy (validated with `vsudo -c`)
- ~/.ssh = 700, authorized_key = 600
- Access: `ssh deploy@10.81.12.101` (alias `p01` in ~/.ssh/config)

## SSH hardening (Issue #2)
- Source of truth: configs/sshd/01-hardening.conf -> /etc/ssh/sshd_config.d/
- Named 01- because sshd uses the FIRST value found (cloud image ships 60-*)
- verify: `sudo sshd -t` (syntax), `sudo sshd -T | grep ...` (effective values)
- Always keep a session open while restarting ssh
- Tests: key login OK, password refused, root refused

## Firewall - UFW (Issue #3)
- Policy: deny incoming / allow outgoing
- Rules: `ufw limit OpenSSH` (22/tcp, blocked ≥6 conn/30s per IP)
- Verified: test port 8080 blocked -> allowed -> removed
- WARNING: Docker-published ports bypass UFW -> bind containers to 127.0.0.1
- Loukout prevention: allow SSH before `ufw enable`, keep a session open

## fail2ban (Issue #3)
- Config: configs/fail2ban/sshd/local -> /etc/fail2ban/jail.d/
- 5 failures / 10 min -> 1h ban, increasing for repeat offenders
- backend=systemd (Ubuntu 24.04 logs sshd to journald)
- Tested from a separate VM: banned after 5 attempts (evidence: fail2ban-client status sshd)
- Unban: 'sudo fail2ban-client set sshd unbanip <IP>'

## Automatic security updates
- Configs: configs/apt/20auto-upgrades, 52unattended-local -> /etc/apt/apt.conf.d/
- Aoto-reboot only if required, at 03:30 server time (UTC) - agree window with client
- Verify: `sudo unattended-upgrade --dry-run --debug`, `apt-config dump | grep Reboot`
- Logs: /var/log/unattended-upgrades/- Workstation clock was ~5 min fast (no NTP service) → tar "time stamp in the future" warnings.
  Check: `timedatectl` → "System clock synchronized: yes". Servers need outbound UDP 123 for NTP.
