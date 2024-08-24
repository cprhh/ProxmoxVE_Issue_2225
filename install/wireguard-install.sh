#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Installing WireGuard"
$STD apt-get install -y wireguard wireguard-tools net-tools iptables
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install -y iptables-persistent &>/dev/null
$STD netfilter-persistent reload
msg_ok "Installed WireGuard"

msg_info "Installing WGDashboard"
git clone -q https://github.com/donaldzou/WGDashboard.git /etc/wgdashboard
cd /etc/wgdashboard/src
chmod u+x wgd.sh
$STD ./wgd.sh install
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
$STD sysctl -p /etc/sysctl.conf
msg_ok "Installed WGDashboard"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wg-dashboard.service
[Unit]
After=syslog.target network-online.target
Wants=wg-quick.target
ConditionPathIsDirectory=/etc/wireguard

[Service]
Type=forking
PIDFile=/etc/wgdashboard/src/gunicorn.pid
WorkingDirectory=/etc/wgdashboard/src
ExecStart=/etc/wgdashboard/src/wgd.sh start
ExecStop=/etc/wgdashboard/src/wgd.sh stop
ExecReload=/etc/wgdashboard/src/wgd.sh restart
TimeoutSec=120
PrivateTmp=yes
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wg-dashboard.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
