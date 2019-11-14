#!/bin/bash
echo "Let's get it going..."
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
echo "Updating Manjaro"
if [ -f reboot.log ]
  then
  echo "Already upgraded packages"
  rm reboot.log
else
yes | pacman -Syu
echo "Rebooting now, run me again after reboot to continue!"
sleep 10
touch reboot.log
reboot now
fi
echo "Enable SSH"
systemctl enable sshd.service; systemctl start sshd.service
echo "Removing GUI"
yes | pacman -Rs xfce4 gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd lightdm light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings modemmanager
echo "Make .ssh folder for keys"
mkdir ~/.ssh 
echo "Install goodies | docker docker-compose glances htop bmon jq whois yay ufw fail2ban"
yes | pacman -Sy docker docker-compose glances htop bmon jq whois yay ufw fail2ban
echo "Docker user setup"
groupadd docker
usermod -aG docker $USER
echo "Allow SSH"
ufw allow ssh
echo "Limit SSH"
ufw limit ssh
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
echo "..the going has been got.  Reboot!"
