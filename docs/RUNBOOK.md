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
- Access: `ssh deploy@10.81.21.101` (alias `p01` in ~/.ssh/config)