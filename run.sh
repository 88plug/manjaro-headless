#!/bin/bash

####################################
# Section 1: Pre-Installation Steps #
####################################

# Check if this script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./run.sh"
  exit 1
fi

if [[ -f /var/lib/pacman/db.lck ]]; then
  echo "Cannot continue until pacman is done with updates. Please run again after background updates have completed."
  exit 1
fi

# Show notice only once
if [[ -f ./notice.log ]]; then
  echo "Skipping notice"
else
  # Function to display the notice message
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

  # Prompt the user until they provide a valid response
  valid_response=false
  while ! $valid_response; do
    read -r -p "Do you want to install Docker? [y/n]: " install_docker_choice
    install_docker_choice=${install_docker_choice,,} # Convert the choice to lowercase

    case $install_docker_choice in
      y|yes)
        valid_response=true
        display_notice
        ;;
      n|no)
        valid_response=true
        echo "Skipping Docker"
        ;;
      *)
        echo "Invalid response. Please answer with 'y' or 'n'."
        ;;
    esac
  done
display_notice
fi

#####################################
# Section 2: GUI Removal (if found) #
#####################################

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

# Check for XFCE4 GUI manager, if found remove it
if xfce4-panel --version &>/dev/null; then
  echo "Removing XFCE4 GUI"
  remove_packages xfce4 wayland gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin xfce4-panel xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd lightdm light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings modemmanager
else
  echo "XFCE4 not found! No GUI Removed"
fi

# Check for GNOME GUI manager, if found remove it
if gnome-session --version &>/dev/null; then
  echo "Removing GNOME GUI"
  remove_packages gnome gnome-session gnome-shell wayland gnome-terminal gnome-control-center gnome-backgrounds gnome-calculator gnome-disk-utility gnome-keyring gnome-logs gnome-menus gnome-online-accounts gnome-settings-daemon gnome-shell-extensions gnome-software-packagekit-plugin gnome-software packagekit packagekit-qt5 polkit-gnome seahorse vino xdg-user-dirs-gtk
else
  echo "GNOME not found! No GUI Removed"
fi

######################################
# Section 3: Package Installation #
######################################

echo "Install goodies | ntp glances htop bmon jq whois yay ufw fail2ban git kubectl lvm2 wireguard-tools openssh"
yes | pacman -Sy ntp glances htop bmon jq whois yay ufw fail2ban git kubectl lvm2 wireguard-tools openssh

# Function to install Docker and related packages
install_docker() {
  echo "Installing Docker and Docker Compose"
  yes | pacman -Sy docker docker-compose

  echo "Setting up Docker user"
  groupadd docker
  usermod -aG docker "$(cat user.log)"
}

# Ask the user if they want to install Docker
if [[ $install_docker_choice =~ ^[Yy]$ ]]; then
  install_docker
else
  echo "Skipping Docker installation"
fi

echo "Creating .ssh directory for keys"
mkdir -p ~/.ssh

echo "Enabling SSH"
systemctl enable sshd.service
systemctl start sshd.service

echo "Allowing SSH"
ufw allow ssh

echo "Limiting SSH"
ufw limit ssh

echo "Enable UFW"
ufw --force enable

echo "Adding wireguard to kernel modules"
echo "wireguard" >> /etc/modules

echo "Rotating logs at 50M"
sed -i "/^#SystemMaxUse/s/#SystemMaxUse=/SystemMaxUse=50M/" /etc/systemd/journald.conf

echo "Set time to use NTP"
timedatectl set-ntp true

####################################
# Section 4: Package Updates #
####################################

echo "Install base-devel and packages to build with"
yes | pacman -Sy autoconf automake binutils bison fakeroot file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman patch pkgconf sed sudo systemd texinfo util-linux which
echo "Updating Packages"
yes | pacman -Syyu

######################################
# Section 5: Final Configuration #
######################################

echo "Setting up jail for naughty SSH attempts"
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

echo "Starting and enabling the jail/fail2ban service"
systemctl enable fail2ban.service

if [[ $install_docker_choice =~ ^[Yy]$ ]]; then
  echo "Starting and enabling Docker service"
  systemctl enable docker.service
fi

echo "Starting time sync"
systemctl enable ntpd.service

echo "Update systemctl daemon"
systemctl daemon-reload

echo "Rebooting ..."
reboot now
