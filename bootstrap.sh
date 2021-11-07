#!/bin/bash
set -e

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/GideonWolfe/dots.git"
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/GideonWolfe/arch-bootstrap/master/progs.csv"
[ -z "$aurhelper" ] && aurhelper="paru"
[ -z "$repobranch" ] && repobranch="master"
[ -z "$wallpaperrepo" ] && wallpaperrepo="https://github.com/GideonWolfe/wallpapers.git"
[ -z "$name" ] && name="gideon"

export repodir="/home/$name/.local/src"; mkdir -p "$repodir"; chown -R "$name":wheel "$(dirname "$repodir")"

### FUNCTIONS ###

# Silent pacman install
installpkgsilent(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
# I like to see some output
installpkg(){ pacman --noconfirm --needed -S "$1" 2>&1 ;}
# Install aur package
aurinstall() { \
	echo "$aurinstalled" | grep -q "^$1$" && return 1
	sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
}
# Install python package
pipinstall() { \
	[ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
}
# Install node package
npminstall() { \
	[ -x "$(command -v "npm")" ] || installpkg npm >/dev/null 2>&1
	#npm install "$1"
	sudo -u "$name" npm install -g "$1"
}



# Generic error function
error() { printf "%s\n" "$1" >&2; exit 1; }

# Installs $1 manually. Used only for AUR helper here.
manualinstall() {
	# Should be run after repodir is created and var is set.
	sudo -u "$name" mkdir -p "$repodir/$1"
	#sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" >/dev/null 2>&1 ||
	sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" 2>&1 ||
		{ cd "$repodir/$1" || return 1 ; sudo -u "$name" git pull --force origin master;}
	cd "$repodir/$1"
	# sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si >/dev/null 2>&1 || return 1
  sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si 2>&1 || return 1
}


installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep -q "^\".*\"$" && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"A") aurinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			"N") npminstall "$program" "$comment" ;;
			*) installpkg "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;
}

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

# make sure we have the bare minimum
for x in curl ca-certificates base-devel git ntp fish figlet; do
  # dialog --title "Auto Installation" --infobox "Installing \`$x\` which is required to install and configure other programs." 5 70
  installpkg "$x"
done

# Set default shell
drawTitle "Change Shell"
chsh -s /usr/bin/fish "$name" 2>&1

# Install yay/paru
drawTitle "Install ${aurhelper}"
#manualinstall paru || error "Failed to installAUR Helper"

# Install packages

# Install dotfiles
drawTitle "Cloning Dotfiles"
# git clone $dotfilesrepo /home/$name/dotfiles

# Setup docker
drawTitle "Docker Setup"
usermod -aG docker $name

# Setup permissions


# Create desired folders
drawTitle "Creating Directories"
sudo -u "$name" mkdir -p "/home/$name/photos/screenshots"
sudo -u "$name" mkdir -p "/home/$name/programs/"
sudo -u "$name" mkdir -p "/home/$name/projects/"
sudo -u "$name" mkdir -p "/home/$name/documents/"
sudo -u "$name" mkdir -p "/home/$name/downloads/"
sudo -u "$name" mkdir -p "/home/$name/.local/bin/"

# Install nvim setup
# sudo -u "$name" git clone https://github.com/GideonWolfe/nvim-lua/ "/home/$name/programs/nvim-lua"

# Download wallpapers
drawTitle "Downloading Wallpapers"
# sudo -u "$name" git clone $wallpaperrepo "/home/$name/photos/wallpapers"


# Enable services
drawTitle "Enabling Services"
# systemctl enable lightdm
# systemctl enable NetworkManager
# systemctl enable bluetooth
# systemctl enable docker
# systemctl enable containerd
# systemctl enable sshd
# systemctl enable ckb-next-daemon
# systemctl enable cups

# Sync time
timedatectl set-ntp true

installationloop


# Non packaged programs:
# zathura pywal
# Gnuplot pywal
