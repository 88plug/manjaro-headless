#!/bin/bash

####################################
# Section 1: Pre-Installation Steps #
####################################

# Check if this script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./run.sh"
  exit 1
fi

# Show notice only once
if [[ -f ./notice.log ]]; then
  echo "Skipping notice"
else
  read -r -d '' notice_message <<EOF
READ THIS ...
Let's get it going... Sit back, this will take a few minutes to update and reboot the machine. 
SSH will be enabled on the host, and the console will not show any display during the reboot process. 
There is a potential that you will have no display at all available. Be prepared with SSH.
Once the installer finishes, log in with SSH to the new headless machine using the user you created during installation.

Do not try to log in until the system reboots.
This is a fully automated installer! Now sit back and relax...

As a reminder, your IP address is:
$(ip address)

EOF
echo "$notice_message"
sleep 20
pacman-mirrors ; pacman-mirrors -f15
u=$(logname)
echo "${u}" > user.log
echo "Remember current user $u before reboot"
touch notice.log
fi

#######################################
# Section 2: System Configuration #
#######################################

# Check if pacman is running
if [[ -f /var/lib/pacman/db.lck ]]; then
  echo "Cannot continue until pacman is done with updates. Please run again after background updates have completed."
  exit 1
fi

echo "Creating .ssh directory for keys"
mkdir -p ~/.ssh

echo "Enabling SSH"
systemctl enable sshd.service
systemctl start sshd.service
echo "Detecting GUI"

#####################################
# Section 3: GUI Removal (if found) #
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
# Section 4: Package Installation #
######################################

echo "Install goodies | docker docker-compose glances htop bmon jq whois yay ufw fail2ban git kubectl wireguard-tools"
yes | pacman -Sy ntp docker docker-compose glances htop bmon jq whois yay ufw fail2ban git kubectl lvm2 wireguard-tools

echo "Setting up Docker user"
groupadd docker
usermod -aG docker "$(cat user.log)"

echo "Allowing SSH"
ufw allow ssh

echo "Limiting SSH"
ufw limit ssh

echo "Rotating logs at 50M"
sed -i "/^#SystemMaxUse/s/#SystemMaxUse=/SystemMaxUse=50M/" /etc/systemd/journald.conf

####################################
# Section 5: Package Updates #
####################################

#echo "Install base-devel"
#yes | pacman -Sy autoconf automake binutils bison fakeroot file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman patch pkgconf sed sudo systemd texinfo util-linux which
#echo "Updating Packages"
#yes | pacman -Syyu
#timedatectl set-ntp true


######################################
# Section 6: Final Configuration #
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
systemctl start fail2ban.service
systemctl enable fail2ban.service

echo "Starting and enabling Docker service"
systemctl start docker.service
systemctl enable docker.service

echo "Enable UFW"
ufw --force enable

echo "Adding wireguard to kernel modules"
echo "wireguard" >> /etc/modules

####################################
# Section 7: Rebooting #
####################################

echo "Rebooting ..."
sleep 5

reboot now
