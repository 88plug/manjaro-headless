# manjaro-headless
Use manjaro linux as a headless server

# Step 1
Install manjaro mininmal with xfce

# Step 2
Enable ssh
```sudo systemctl enable sshd.service; sudo systemctl start sshd.service```

# Step 3
Make it headless
```sudo pacman -Rs xfce4 gtkhash-thunar libxfce4ui mousepad orage thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin parole xfce4-notifyd
sudo pacman -Rs lightdm light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings modemmanager
mkdir ~/.ssh #needed for copying key```
