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
# --noconfirm seemed to not work when confirming rustup dependency replacement?
installpkg(){ pacman --noconfirm --needed -S "$1" 2>&1 ;}
# Install aur package
aurinstall() { \
	# echo "$aurinstalled" | grep -q "^$1$" && return 1
  echo "[AUR] Installing " "$1"
  echo $1
	# sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
	sudo -u "$name" $aurhelper -S --noconfirm "$1"
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
  echo INSTALLING NPM PACKAGE
	npm -g install "$1"
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
  # sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si 2>&1 || return 1
  sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si
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
			*) installpkgsilent "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;
}


installationloop2() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep -q "^\".*\"$" && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"A") echo AUR "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			"N") npminstall "$program" "$comment" ;;
			*) echo "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;
}

drawTitle() {
  figlet $1
}


# make sure we have the bare minimum
for x in curl ca-certificates base-devel git ntp fish figlet python-pip npm; do
  # installpkg "$x"
  installpkgsilent "$x"
done


drawTitle "Install ${aurhelper}"
manualinstall paru || error "Failed to installAUR Helper"


installationloop
