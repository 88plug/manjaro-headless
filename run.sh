#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root : sudo ./run.sh"
  exit
fi

if [ -f ./notice.log ]; then
  echo "Skipping notice"
else
echo "Let's get it going...sit back, this will take a few minutes to update and reboot twice."
echo "SSH will be enabled on the host and the console will not show any display after the second reboot."
echo "Once the installer finishes, login with ssh to the new headless machine with the user you created during install."
sleep 15
echo "Do not try to login until the system reboots two times!"
echo "This is a fully automated installer!"
sleep 5
touch notice.log
fi

if [ -f /var/lib/pacman/db.lck ]; then
  echo "Cannot continue until pacman is done with updates, please run again after background updates have completed."
  exit
fi

if [ -f /etc/systemd/system/88plug.service ]; then
    echo "Found reboot service configuration already installed."
else
location=$(pwd)
echo "${location}" > location.log
echo "Setup installer for reboots"
echo "Using $location location for this install"
cat <<EOT > /etc/systemd/system/88plug.service
[Service]
WorkingDirectory=$location
ExecStart=$location/run.sh
User=root
[Install]
WantedBy=default.target
EOT
echo "Enabling 88plug reboot service"
systemctl enable 88plug.service
echo "Updating mirrors and Manjaro"
pacman-mirrors --geoip ; yes | pacman -Syyu
echo "Remember current user before reboot"
u="$USER"
echo "${u}" > user.log
echo "Rebooting now..."
sleep 3
reboot now
fi

if [ -f /etc/fail2ban/jail.d/sshd.local ]; then
  echo "Succesfully installed all packages"
  echo "88plug cleaned up."
else
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
usermod -aG docker $(cat user.log)
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
echo "Cleaning up"
systemctl stop 88plug.service
systemctl disable 88plug.service
rm -f /etc/systemd/system/88plug.service
rm *.log
echo "Rebooting for the last time..."
ufw --force enable
echo "You can login after this reboot"
sleep 5
reboot now
fi
