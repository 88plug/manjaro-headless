#!/bin/bash
# Check if this script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo ./run.sh"
  exit
fi

# Show notice only once
if [ -f ./notice.log ]; then
  echo "Skipping notice"
else
  echo "READ THIS ..."
  echo "Let's get it going...sit back, this will take a few minutes to update and reboot the machine twice. Don't worry we already took care of resuming the process after the first reboot ;)."
  echo "SSH will be enabled on the host and the console will not show any display during the reboot process.  There is potential you will have no display at all available.  Be prepared with SSH."
  echo "Once the installer finishes, login with ssh to the new headless machine with the user you created during install."
  sleep 30
  ip=$(ip address)
  echo "As a reminder your IP address is :\n$ip"
  echo "Do not try to login until the system reboots two times!"
  echo "This is a fully automated installer! Now sit back and relax..."
  sleep 5
  touch notice.log
fi

# Check if pacman is running
if [ -f /var/lib/pacman/db.lck ]; then
  echo "Cannot continue until pacman is done with updates, please run again after background updates have completed."
  exit
else
  #Get fresh mirrors
  pacman-mirrors ; pacman-mirrors -f15
  echo "Updating Manjaro"
  yes | pacman -Syyu
  u=$(logname)
  echo "${u}" > user.log
  echo "Remember current user $u before reboot"
fi

echo "Make .ssh folder for keys"
mkdir ~/.ssh 

echo "Enable SSH"
systemctl enable sshd.service
systemctl start sshd.service
echo "Detecting GUI"

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
  remove_packages xfce4 gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd lightdm light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings modemmanager
else
  echo "XFCE4 not found! No GUI Removed"
fi

# Check for GNOME GUI manager, if found remove it
if gnome-session --version &>/dev/null; then
  echo "Removing GNOME GUI"
  remove_packages gnome-shell gnome-terminal gnome-control-center gnome-backgrounds gnome-calculator gnome-disk-utility gnome-keyring gnome-logs gnome-menus gnome-online-accounts gnome-settings-daemon gnome-shell-extensions gnome-software-packagekit-plugin gnome-software packagekit packagekit-qt5 polkit-gnome seahorse vino xdg-user-dirs-gtk
else
  echo "GNOME not found! No GUI Removed"
fi


echo "Install goodies | docker docker-compose glances htop bmon jq whois yay ufw fail2ban git kubectl"
yes | pacman -Sy ntp docker docker-compose glances htop bmon jq whois yay ufw fail2ban git kubectl

echo "Install base-devel"
yes | pacman -Sy autoconf automake binutils bison fakeroot file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman patch pkgconf sed sudo systemd texinfo util-linux which
timedatectl set-ntp true

echo "Docker user setup"
groupadd docker
usermod -aG docker $(cat user.log)

echo "Allow SSH"
ufw allow ssh

echo "Limit SSH"
ufw limit ssh

echo "Rotate logs at 50M"
sed -i "/^#SystemMaxUse/s/#SystemMaxUse=/SystemMaxUse=50M/" /etc/systemd/journald.conf

echo "Setup jail for naughty SSH attempts"
cat <<EOT > /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled   = true
filter    = sshd
banaction = ufw
backend   = systemd
maxretry  = 5
findtime  = 1d
bantime   = 52w
EOT

echo "Starting and enabling the jail/fail2ban"
systemctl start fail2ban.service
systemctl enable fail2ban.service

echo "Starting and enabling the docker"
systemctl start docker.service
systemctl enable docker.service

echo "Rebooting for the last time..."
ufw --force enable
echo "You can login after this reboot - don't forget to set your hostname with : sudo hostnamectl set-hostname deathstar"
reboot now
