echo "Let's get it going..."
sudo systemctl enable sshd.service; sudo systemctl start sshd.service
yes | sudo pacman -Rs xfce4 gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd lightdm light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings modemmanager
mkdir ~/.ssh 
sudo pacman -Sy docker docker-compose glances htop bmon jq whois yay ufw fail2ban
sudo ufw allow ssh
sudo ufw limit ssh
sudo cat <<EOT > /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled   = true
filter    = sshd
banaction = ufw
backend   = systemd
maxretry  = 5
findtime  = 1d
bantime   = 52w
EOT
sudo systemctl start fail2ban.service
sudo systemctl enable fail2ban.service
echo "..the going has been got.  Reboot!"
