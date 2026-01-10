# Linux Fedora distro setup (Gnome)

_ToDO: write a script that automates all below_

#### 1. Add user in sudo group
```
su -
usermod -aG wheel <username>
```
Relogin after commands above.

Check the user is added into the `sudo` group:
```
groups <username>
```

#### 2. Prepare necessary directories
```
mkdir -p $HOME/Projects $HOME/Documents/PARA $HOME/Logs $HOME/.config/systemd/user
```

#### 3. Provide custom dnf.conf if needed for fast mirrors access
Check `/etc/dnf/dnf.conf` before the action.
```
sudo su
```
```
echo "
[main]
fastestmirror=True
max_parallel_downloads=10
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
" > /etc/dnf/dnf.conf
```

#### 4. Update & Upgrade
```
sudo dnf update && sudo dnf upgrade
```

#### 4. Install and set up necessities
```
sudo dnf install -y htop && \
sudo dnf install -y keepassxc && \
sudo dnf install -y tmux && \
sudo dnf install -y vim && \
sudo dnf install -y curl && \
sudo dnf install -y git && \
git config --global user.email "example@mail.com" && \
git config --global user.name "Your Name" && \
git config --global core.editor "vim"
```

#### 5. Set up access to Cloud Mail.ru via WebDav in the distro file manager ([Gnome Files](https://apps.gnome.org/Nautilus/))

##### 5.1 Generate [application password](https://help.mail.ru/mail/faq/password/external/) and remember it
The password has to be generated for full access via all protocols.

##### 5.2 Add a connection string in the file manager (Gnome Files specific):
Push `+ Other Locations`,

add connection string: `"davs://username@domain.ru@webdav.cloud.mail.ru"`,

save the password within the file manager for the next usages (the saving abbility is a Gnome ui stuff).


#### 6. Generate ssh keys and add them into ssh agent
```
ssh-keygen -t ed25519 -C "example@mail.com" -f ~/.ssh/ed25519_<unic_part> -N <PassPhrase>
```
```
ssh-add ~/.ssh/ed25519_<unic_part>
```

#### 7. Add ssh keys in git repos for access

#### [8. Install rclone](https://rclone.org/install/)
```
sudo -v ; curl https://rclone.org/install.sh | sudo bash
```

#### 9. Generate Cloud Mail.ru application password for rclone
The password has to be generated for full access via all protocols.
See `man rclone` the section `Mail.ru Cloud`.

#### 10. Create rclone config
```
rclone config create mailru mailru user=username@domain.ru pass=<generated_app_password> speedup-enable=false
```

#### [11. Install zsh and make it as a default shell](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH#install-and-set-up-zsh-as-default)
```
sudo dnf install -y zsh
```
```
chsh -s $(which zsh)
```
```
sudo reboot                     # to apply changes
```

#### 12. Clone repo with oh-my-zsh fork to install
```
REPO=<ohmyzsh fork repo> BRANCH=branch_with_your_customs sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### 13. Install VSCode

https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions

#### 14. Install and set up VirtualBox

1. Check the host OS is supported by VirtualBox, visit official site.

2. Allow virtualization in BIOS

3. Disable secure boot otherwise you have to sign the kernel modules.

4. Install headers for kernel modules building

 ```bash
 sudo dnf install -y kernel-devel kernel-devel-$(uname -r)
 ```

 5. Initiate VBox installation

 6. Check kernel modules are installed
```bash
 lsmod | grep vbox
 ```


**_Note: VirtualBox vs KVM kernel module_**

VirtualBox bug was reported on the kernels >= 6.14: [issue 81](https://github.com/VirtualBox/virtualbox/issues/81)

Check kvm modules are present:
```bash
lsmod | grep kvm
```
_**Temporary workaround:** unload kvm modules_
```bash
sudo modprobe -r kvm_intel # or kvm_amd
sudo modprobe -r kvm
```

_**Permanent workaround:** add kvm modules to blacklist to prevent their loading after reboot._
```bash
sudo vim /etc/modprobe.d/kvm-blacklist.conf
```
Add lines in the mentioned file and reboot the system:
```bash
blacklist kvm
blacklist kvm_intel
blacklist kvm_amd
```

#### 14. Setup VPN client

[Happ](https://github.com/Happ-proxy/happ-desktop/releases)

#### 15. Set up Syncthing for Android <-> Linux sync

[Downloads](https://syncthing.net/downloads/)

[Releases](https://github.com/syncthing/syncthing/releases)

##### [Set up syncthing as user service](https://docs.syncthing.net/users/autostart.html#how-to-set-up-a-user-service)

1. copy [provided](https://github.com/syncthing/syncthing/blob/main/etc/linux-systemd/user/syncthing.service) user service file into `$HOME/.config/systemd/user`
2. create symlink:
```bash
ln -s <path_to_executable_dir>/syncthing /usr/bin/syncthing
```
or modify `.service` file by specifying the path to executable.

Note: WebUi: http://127.0.0.1:8384/

#### 16. Set up [Obsidian](https://obsidian.md/download)

1. `mkfir -p ~/Programs/Obsidian`
2. Download the AppImage into `~/Programs/Obsidian`
3. `touch ~/.local/share/applications/obsidian.desktop`
4. Put into the file the content:
```
[Desktop Entry]
Name=Obsidian
Comment=Markdown-based knowledge base
Exec=$HOME/Programs/Obsidian/Obsidian-1.10.6.AppImage %U
Icon=$HOME/Documents/PARA/3_Resources/it/Obsidian/obsidian_logo.svg
Terminal=false
Type=Application
Categories=Office;Utility;TextEditor;
StartupWMClass=obsidian
MimeType=text/markdown;
```
5. Make `.desktop` file executable
```
chmod +x ~/.local/share/applications/obsidian.desktop
```
6. Update the applications cache
```
update-desktop-database ~/.local/share/applications
```