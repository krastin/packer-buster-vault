#!/usr/bin/env bash

## Standard boostrap
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qy update

# Add no-password sudo config for vagrant user
echo "%vagrant ALL=NOPASSWD:ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

# Add vagrant to sudo group
usermod -a -G sudo vagrant

# Install vagrant key
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Install NFS for Vagrant
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get install -y nfs-common
# Without libdbus virtualbox would not start automatically after compile
# apt-get -y install --no-install-recommends libdbus-1-3

# Install Linux headers and compiler toolchain
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -y install build-essential linux-headers-$(uname -r) 


# The netboot installs the VirtualBox support (old) so we have to remove it
# service virtualbox-ose-guest-utils stop
# rmmod vboxguest
# apt-get purge -y virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms virtualbox-ose-guest-utils
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get install -y dkms

# Install the VirtualBox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
VBOX_ISO=/home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop $VBOX_ISO /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt

#Cleanup VirtualBox
rm $VBOX_ISO

# unattended apt-get upgrade
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qy autoclean


# Install tools that make life better
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -y install vim tmux curl unzip policykit-1 jq

DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get autoremove -y
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get clean

# Install Vault
if [ -z "$VERSION" ]; then
  VERSION=`curl -sL https://releases.hashicorp.com/vault/index.json | jq -r '.versions[].version' | sort -V | egrep -v 'beta|rc|alpha' | tail -1`
fi
which vault || {
  cd /usr/local/bin
  wget https://releases.hashicorp.com/vault/${VERSION}/vault_${VERSION}_linux_amd64.zip
  unzip vault_${VERSION}_linux_amd64.zip
}

chown root:root /usr/local/bin/vault
mkdir /etc/vault.d
chmod 640 -R /etc/vault.d/
# Add autocomplete
vault -autocomplete-install
complete -C /usr/local/bin/vault vault
# Give Vault the ability to use the mlock syscall without running the process as root.
# The mlock syscall prevents memory from being swapped to disk
setcap cap_ipc_lock=+ep /usr/local/bin/vault
# Create a  user to run under
useradd --system --home /etc/vault.d --shell /bin/false vault
mkdir --parents /opt/vault
chown --recursive vault /opt/vault
chown -R vault /etc/vault.d
# Set up config for systemd
cat <<EOF >> /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionDirectoryNotEmpty=/etc/vault.d/
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable vault

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

# Zero out the free space to save space in the final image:
echo "Zeroing device to make space..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
