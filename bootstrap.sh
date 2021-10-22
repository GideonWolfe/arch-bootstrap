#!/bin/bash
set -e

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/GideonWolfe/dots.git"
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/GideonWolfe/arch-bootstrap/master/progs.csv"
[ -z "$aurhelper" ] && aurhelper="paru"
[ -z "$repobranch" ] && repobranch="master"
[ -z "$name" ] && name="gideon"


### FUNCTIONS ###

# Silent pacman install
installpkgsilent(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
# I like to see some output
installpkg(){ pacman --noconfirm --needed -S "$1" 2>&1 ;}

error() { printf "%s\n" "$1" >&2; exit 1; }

manualinstall() { # Installs $1 manually. Used only for AUR helper here.
	# Should be run after repodir is created and var is set.
	sudo -u "$name" mkdir -p "$repodir/$1"
	#sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" >/dev/null 2>&1 ||
	sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" 2>&1 ||
		{ cd "$repodir/$1" || return 1 ; sudo -u "$name" git pull --force origin master;}
	cd "$repodir/$1"
	# sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si >/dev/null 2>&1 || return 1
  sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si 2>&1 || return 1
}

drawTitle() {
  figlet $1
}


# Use all cores for compilation.
# sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf


# make sure we have the bare minimum
for x in curl ca-certificates base-devel git ntp fish figlet; do
  # dialog --title "Auto Installation" --infobox "Installing \`$x\` which is required to install and configure other programs." 5 70
  installpkg "$x"
done

export repodir="/home/$name/.local/src"; mkdir -p "$repodir"; chown -R "$name":wheel "$(dirname "$repodir")"


## Tasks

# Set default shell
drawTitle "Change Shell"
chsh -s /usr/bin/fish "$name" 2>&1

# Pacman config
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf || error "Failed to enable ILoveCandy"
sed -i "s/^#ParallelDownloads = 8$/ParallelDownloads = 5/;s/^#Color$/Color/" /etc/pacman.conf || error "Failed to enable Parallel Downloads and color"

# Install yay/paru
drawTitle "Install ${aurhelper}"
#manualinstall paru || error "Failed to installAUR Helper"

# Install packages

# Install nvim setup

# Install dotfiles
git clone $dotfilesrepo /home/$name/dotfiles

# Create ~/.local/bin/* dirs

# Setup docker
drawTitle "Docker Setup"
usermod -aG docker $name
systemctl enable docker.service
systemctl enable containerd.service

# Setup permissions

# Non packaged programs:
# zathura pywal
# Gnuplot pywal
