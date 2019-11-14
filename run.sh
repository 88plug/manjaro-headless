#!/bin/bash
echo "Let's get it going...sit back, this will take a few minutes and 2 reboots."
echo "Do not login until the system reboots three times!"
echo "This is a fully automated installer!"
location=$(pwd)

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -f /etc/systemd/system/88plug.service ]; then
  echo "Found service and using $location location"
else
echo "Setup installer for reboots"
echo "Using $location location for this install"
#cp $location/run.sh /usr/local/bin/88plug_run.sh
cat <<EOT > /etc/systemd/system/88plug.service
[Service]
WorkingDirectory=$location/
Type=forking
ExecStart=/bin/bash run.sh
#ExecStart=/run.sh
User=root
[Install]
WantedBy=default.target
EOT
echo "Enabling 88plug reboot service"
systemctl start 88plug.service
systemctl enable 88plug.service
echo "Updating Manjaro"
yes | pacman -Syu
echo "Rebooting now, run me again after reboot to continue!"
sleep 1
reboot now
fi

if [ -f $location/reboot_1.log ]; then
  echo "Succesfully installed all packages"
  rm $location/reboot_1.log
  systemctl stop 88plug.service
  systemctl disable 88plug.service
  rm /etc/systemd/system/88plug.service
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
echo "Rebooting for the last time..."
sleep 1
touch $location/reboot_1.log
reboot now
fi
