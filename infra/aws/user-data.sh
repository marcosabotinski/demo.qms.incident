#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/qms-bootstrap.log) 2>&1

# Extra headroom while Docker builds the Node images.
if [[ ! -f /swapfile ]]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
  chmod 600 /swapfile
  mkswap /swapfile
fi
swapon /swapfile || true
grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab

dnf install -y docker rsync
systemctl enable --now docker
usermod -aG docker ec2-user

mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

install -d -o ec2-user -g ec2-user /opt/qms
touch /opt/qms/.bootstrap-complete
chown ec2-user:ec2-user /opt/qms/.bootstrap-complete
