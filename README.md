# manjaro-headless
Use manjaro linux as a headless server

# Upload ISO to your host
Upload the Manjaro Mininmal with XFCE ISO to Vultr or your hosting provider/server and install with default options
https://osdn.net/projects/manjaro/storage/xfce/18.1.1/minimal/manjaro-xfce-18.1.1-minimal-191025-linux53.iso/

# Enable ssh
```sudo systemctl enable sshd.service; sudo systemctl start sshd.service```

# Make it headless
```
yes | sudo pacman -Rs xfce4 gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd lightdm light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings modemmanager
```

Copy your ssh keys to the server now

```
mkdir ~/.ssh #needed for copying key
cat ~/.ssh/id_rsa.pub | ssh root@example.com 'cat - >> ~/.ssh/authorized_keys'
```

# Step 4 (Optional/Add goodies and secure the beast.)
```
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
```
