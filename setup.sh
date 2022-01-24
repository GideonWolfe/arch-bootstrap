#!/bin/bash
set -e

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/GideonWolfe/dots.git"
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/GideonWolfe/arch-bootstrap/master/progs.csv"
[ -z "$repobranch" ] && repobranch="master"
[ -z "$wallpaperrepo" ] && wallpaperrepo="https://github.com/GideonWolfe/wallpapers.git"
[ -z "$name" ] && name="gideon"

export repodir="/home/$name/.local/src"; mkdir -p "$repodir"; chown -R "$name":wheel "$(dirname "$repodir")"

### FUNCTIONS ###

# Generic error function
error() { printf "%s\n" "$1" >&2; exit 1; }

drawTitle() {
  figlet $1
}

## Tasks

# Various system tweaks
drawTitle "System Tweaks"
# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf
# Pacman config
# enable ilovecandy
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf || error "Failed to enable ILoveCandy"
# Enable parallel downloads and color support
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 8/;s/^#Color$/Color/" /etc/pacman.conf || error "Failed to enable Parallel Downloads and color"
# Enable verbose package lists
sed -i "s/^#VerbosePkgLists/VerbosePkgLists/" /etc/makepkg.conf
# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
# Enable desired lightdm greeter
sed -i '/^\[Seat:\*\]$/,/\[/s/^#greeter-session=$/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf

# Set default shell
drawTitle "Change Shell"
chsh -s /usr/bin/fish "$name" 2>&1

# Install dotfiles
drawTitle "Cloning Dotfiles"
git clone $dotfilesrepo /home/$name/dotfiles

# Setup docker
drawTitle "Docker Setup"
usermod -aG docker $name

# Setup permissions


# Create desired folders
# drawTitle "Creating Directories"
sudo -u "$name" mkdir -p "/home/$name/photos/screenshots"
sudo -u "$name" mkdir -p "/home/$name/programs/"
sudo -u "$name" mkdir -p "/home/$name/projects/"
sudo -u "$name" mkdir -p "/home/$name/documents/"
sudo -u "$name" mkdir -p "/home/$name/downloads/"
sudo -u "$name" mkdir -p "/home/$name/.local/bin/"

# Install nvim setup
drawTitle "Downloading NeoVim config"
sudo -u "$name" git clone https://github.com/GideonWolfe/nvim-lua/ "/home/$name/programs/nvim-lua"

# Download wallpapers
drawTitle "Downloading Wallpapers"
sudo -u "$name" git clone $wallpaperrepo "/home/$name/photos/wallpapers"

# Enable services
drawTitle "Enabling Services"
systemctl enable lightdm
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable docker
systemctl enable containerd
systemctl enable sshd
systemctl enable ckb-next-daemon
systemctl enable cups

# Sync time
timedatectl set-ntp true

# Non packaged programs:
# zathura pywal
sudo -u "$name" git clone "https://github.com/GideonWolfe/Zathura-Pywal" "/home/$name/programs/"
sh /home/$name/programs/Zathura-Pywal/install.sh

# Gnuplot pywal

# Spicetify: god hopes it actually works
sudo -u "$name" git clone "https://github.com/morpheusthewhite/spicetify-themes" "/home/$name/programs/"
sudo -u "$name" cp -r "/home/$name/programs/spicetify-themes/Sleek/" "/home/$name/.config/spicetify/Themes/Sleek/"
# should be cached template spicetify_sleek.ini need to symlink to Themes/Sleek/color.ini
rm "/home/$name/.config/spicetify/Themes/Sleek/color.ini"
sudo -u "$name" ln -s "/home/$name/.cache/wal/spicetify_sleek.ini" "/home/$name/.config/spicetify/Themes/Sleek/color.ini"
# Do directory permissions https://github.com/khanhas/spicetify-cli/wiki/Installation#spotify-installed-from-aur
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
# actually apply it
spicetify config current_theme Sleek
spicetify config color_scheme Pywal
spotify backup apply


# cmus notify
sudo -u "$name" git clone "https://github.com/dcx86r/cmus-notify" "/home/$name/programs/"
sh /home/$name/programs/cmus-notify/installer.sh install

# Set Wallpaper
wal -i /home/$name/photos/wallpapers/gw9TTta.jpg

# Instruct slick-greeter to use this wallpaper
cat <<EOT >> /etc/lightdm/slick-greeter.conf
[Greeter]
background=/usr/share/wallpapers/wal
EOT


drawTitle "Installing Dotfiles"
dotdrop --cfg=/home/$name/dotfiles/config.yaml install laptop


# Install cmus-notify
# https://github.com/karan/joe get this, is there a package?
