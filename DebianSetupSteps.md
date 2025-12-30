# Linux Debian-based distro setup (Gnome)

_ToDO: write a script that automates all below_

#### 1. Add user in sudo group
```
su -
usermod -aG sudo <username>
```
Relogin after commands above.

Check the user is added into the `sudo` group:
```
groups <username>
```

#### 2. Prepare necessary directories
```
mkdir $HOME/Projects $HOME/Documents/PARA $HOME/Logs
```

#### 3. Update & Upgrade
```
sudo apt update && sudo apt upgrade
```

#### 4. Install and set up necessities
```
sudo apt install -y htop && \
sudo apt install -y keepass2 && \
sudo apt install -y tmux && \
sudo apt install -y vim && \
sudo apt install -y curl && \
sudo apt install -y git && \
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
sudo apt install -y zsh
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

https://code.visualstudio.com/docs/setup/linux#_debian-and-ubuntu-based-distributions