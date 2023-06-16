#!/bin/bash

# Check if this script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./run.sh"
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
READ THIS ...
SSH will be enabled on the host, and the console will not show any display during the reboot process.
There is a potential that you will have no display at all available. Be prepared with SSH.
Once the installer finishes, log in with SSH to the new headless machine using the user you created during installation.

## Do not try to log in until the system reboots.
## This is a fully automated installer! Now sit back and relax...

As a reminder, your IP address is:
$(ip address)

EOF
  echo "$notice_message"
  sleep 20
  pacman-mirrors
  pacman-mirrors -f15
  u=$(logname)
  echo "${u}" > user.log
  echo "Remember current user $u before reboot"
  touch notice.log
}

# Check if Docker installation is requested
install_docker_choice=""
while [[ ! "$install_docker_choice" =~ ^(y|n)$ ]]; do
  read -r -p "Do you want to install Docker? [y/n]: " install_docker_choice
  install_docker_choice=${install_docker_choice,,} # Convert the choice to lowercase
done

# Execute notice display only if Docker installation is chosen
if [[ ! -f ./notice.log ]]; then
  display_notice
fi

# Function to remove packages safely
remove_packages() {
  for package in "$@"; do
    if pacman -Qi "$package" &>/dev/null; then
      yes | pacman -Rcns "$package"
    else
      echo "Package $package does not exist. Skipping."
    fi
  done
}

# Remove XFCE4 GUI if found
if xfce4-panel --version &>/dev/null; then
  echo "Removing XFCE4 GUI"
  remove_packages xfce4 wayland gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin xfce4-panel xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd lightdm light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings modemmanager
else
  echo "XFCE4 not found! No GUI removed"
fi

# Remove GNOME GUI if found
if gnome-session --version &>/dev/null; then
  echo "Removing GNOME GUI"
  remove_packages gnome gnome-session gnome-shell wayland gnome-terminal gnome-control-center gnome-backgrounds gnome-calculator gnome-disk-utility gnome-keyring gnome-logs gnome-menus gnome-online-accounts gnome-settings-daemon gnome-shell-extensions gnome-software-packagekit-plugin gnome-software packagekit packagekit-qt5 polkit-gnome seahorse vino xdg-user-dirs-gtk
else
  echo "GNOME not found! No GUI removed"
fi

# Install necessary packages
echo "Installing packages: ntp glances htop bmon jq whois yay ufw fail2ban git kubectl lvm2 wireguard-tools openssh"
yes | pacman -Sy ntp glances htop bmon jq whois yay ufw fail2ban git kubectl lvm2 wireguard-tools openssh

# Install Docker and related packages if chosen
if [[ "$install_docker_choice" =~ ^[yY]$ ]]; then
  echo "Installing Docker and Docker Compose"
  yes | pacman -Sy docker docker-compose

  echo "Setting up Docker user"
  groupadd docker
  usermod -aG docker "$(cat user.log)"
fi

# Create .ssh directory for keys
echo "Creating .ssh directory for keys"
mkdir -p ~/.ssh

# Enable and start SSH
echo "Enabling SSH"
systemctl enable sshd.service
systemctl start sshd.service

# Configure UFW
echo "Configuring UFW"
ufw allow ssh
ufw limit ssh
ufw --force enable

# Add wireguard to kernel modules
echo "Adding wireguard to kernel modules"
echo "wireguard" >> /etc/modules

# Rotate logs at 50M
echo "Rotating logs at 50M"
sed -i "/^#SystemMaxUse/s/#SystemMaxUse=/SystemMaxUse=50M/" /etc/systemd/journald.conf

# Set time to use NTP
echo "Setting time to use NTP"
timedatectl set-ntp true

# Install base-devel and packages for building
echo "Installing base-devel and build packages"
yes | pacman -Sy autoconf automake binutils bison fakeroot file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman patch pkgconf sed sudo systemd texinfo util-linux which

# Update all packages
echo "Updating packages"
yes | pacman -Syyu

# Configure fail2ban for SSH
echo "Configuring fail2ban for SSH"
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

# Enable fail2ban and Docker services
echo "Enabling fail2ban and Docker services"
systemctl enable fail2ban.service
if [[ "$install_docker_choice" =~ ^[yY]$ ]]; then
  systemctl enable docker.service
fi

# Enable time sync
echo "Enabling time sync"
systemctl enable ntpd.service

# Reload systemctl daemon
echo "Reloading systemctl daemon"
systemctl daemon-reload

# Reboot the system
echo "Rebooting..."
reboot now
