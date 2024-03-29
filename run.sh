#!/bin/bash

set -euo pipefail

# Check if this script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

# Check if pacman is running updates
if [[ -f /var/lib/pacman/db.lck ]]; then
  echo "Cannot continue until pacman is done with updates. Please run again after background updates have completed."
  exit 1
fi

# Display notice message
display_notice() {
  read -r -d '' notice_message <<EOF
IMPORTANT NOTICE:
This script will enable SSH on the host and remove any graphical interface.
After the reboot, you will need to access the system using SSH.
Please ensure you have the necessary information to connect via SSH.

The installer will now proceed with the automated setup process.

Your current IP address is:
$(ip address)

EOF
  echo "$notice_message"
  read -p "Press Enter to continue or Ctrl+C to abort..."
  pacman-mirrors -f 15
  current_user=$(logname)
}

# Check if Docker installation is requested
read -p "Do you want to install Docker? [y/N]: " install_docker_choice
install_docker_choice=${install_docker_choice,,}

# Execute notice display
display_notice

# Function to remove packages safely
remove_packages() {
  for package in "$@"; do
    if pacman -Qi "$package" &>/dev/null; then
      pacman -Rcns --noconfirm "$package"
    fi
  done
}

# Remove XFCE4 and GNOME GUI if found
gui_packages=(
  xfce4 wayland gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin
  xfce4-panel xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter
  xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd lightdm light-locker lightdm-gtk-greeter
  lightdm-gtk-greeter-settings modemmanager gnome gnome-session gnome-shell wayland gnome-terminal
  gnome-control-center gnome-backgrounds gnome-calculator gnome-disk-utility gnome-keyring gnome-logs
  gnome-menus gnome-online-accounts gnome-settings-daemon gnome-shell-extensions gnome-software-packagekit-plugin
  gnome-software packagekit packagekit-qt5 polkit-gnome seahorse vino xdg-user-dirs-gtk
)
remove_packages "${gui_packages[@]}"

# Install necessary packages
packages=(
  ntp glances htop bmon jq whois yay ufw fail2ban git kubectl lvm2 wireguard-tools openssh
  autoconf automake binutils bison fakeroot file findutils flex gawk gcc gettext grep groff
  gzip libtool m4 make pacman patch pkgconf sed sudo systemd texinfo util-linux which
)
pacman -Sy --noconfirm "${packages[@]}"

# Install Docker and related packages if chosen
if [[ "$install_docker_choice" =~ ^[yY]$ ]]; then
  pacman -Sy --noconfirm docker docker-compose
  groupadd -f docker
  usermod -aG docker "$current_user"
fi

# Configure SSH
mkdir -p ~/.ssh
chmod 700 ~/.ssh
systemctl enable --now sshd.service

# Configure UFW
ufw allow ssh
ufw limit ssh
ufw --force enable

# Add wireguard to kernel modules
echo "wireguard" >> /etc/modules

# Rotate logs at 50M
sed -i "/^#SystemMaxUse/s/#SystemMaxUse=/SystemMaxUse=50M/" /etc/systemd/journald.conf

# Set time to use NTP
timedatectl set-ntp true

# Update all packages
pacman -Syu --noconfirm

# Configure fail2ban for SSH
cat <<EOF > /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled   = true
filter    = sshd
banaction = ufw
backend   = systemd
maxretry  = 5
findtime  = 1d
bantime   = 52w
EOF

# Enable services
systemctl enable fail2ban.service
[[ "$install_docker_choice" =~ ^[yY]$ ]] && systemctl enable docker.service
systemctl enable ntpd.service

# Reload systemd daemon
systemctl daemon-reload

echo "Setup complete. Please reboot the system for changes to take effect."
