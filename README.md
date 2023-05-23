# 🐧 Welcome to manjaro-headless 🚀

The manjaro-headless script is designed to help users set up a headless server using Manjaro Linux. By uploading the Manjaro XFCE minimal ISO to any VPS provider that supports console and ISO upload image, you can configure your server with a default installation and your normal user account via the console of your VPS. This is a one-shot installer, meaning that once it runs, your machine will be fully configured. 🎉

## 📝 Requirements:
- 8GB Disk 
- VPS provider with console support
- VPS provider with ISO upload image support (.iso)
- Time

## 🔧 Features

    Updates system packages and mirrors using pacman-mirrors.
    Enables SSH for remote access.
    Removes XFCE4 or GNOME GUI if detected.
    Installs Docker, Docker Compose, glances, htop, bmon, jq, whois, yay, ufw, wireguard kernel module, lvm2, and fail2ban.
    Configures Docker and adds the current user to the docker group.
    Sets up firewall rules and limits SSH access.
    Rotates logs to manage disk space.
    Sets up a fail2ban jail for SSH attempts.
    Starts and enables fail2ban and Docker services.
    Performs a final system reboot.

## 💾 Installation:
1. Download the Manjaro Minimal with XFCE ISO from https://manjaro.org/downloads/official/xfce/.
2. Upload the ISO to your VPS provider or server, such as Vultr, and use the host console to install with default options, including a normal user and password.
3. Run the automated installer with the following commands:

```
git clone https://github.com/88plug/manjaro-headless
cd manjaro-headless
sudo ./run.sh
```
The script will update and reboot the machine and enable SSH on the host. After the installation is complete, you can log in to the new headless machine with the user you created during the install. 

4. Let the machine reboot. Yes, it will do it automatically! 🤖  

## 🎁 Optional Add-ons:
- Check out the Manjaro-Post-Install repo at https://github.com/88plug/manjaro-post-install/ for more goodies.
- Need a VPS that supports custom ISO? Get $50 of free hosting with Vultr at https://m.do.co/c/d9874e8ceba7 or try HostHatch (NVMe supported!) at https://hosthatch.com/a?id=1577.

## 💡 Tips:
- Remember to wait until the system reboots two times before logging in.
- Don't worry if there is no display available during the reboot process. Be prepared with SSH.
- After the final reboot, set your hostname with "sudo hostnamectl set-hostname YOUR-H
