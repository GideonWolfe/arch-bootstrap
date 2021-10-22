#!/bin/bash
set -e


### FUNCTIONS ###

#installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
# I like to see some output
installpkg(){ pacman --noconfirm --needed -S "$1" 2>&1 ;}

error() { printf "%s\n" "$1" >&2; exit 1; }

# install dialog
# pacman --noconfirm --needed -Sy dialog || error



# Set default shell
# chsh -s /usr/bin/fish "$name" >/dev/null 2>&1

# Pacman config
# Make pacman colorful, concurrent downloads and Pacman eye-candy.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf || error "Failed to enable ILoveCandy"
sed -i "s/^#ParallelDownloads = 8$/ParallelDownloads = 5/;s/^#Color$/Color/" /etc/pacman.conf || error "Failed to enable Parallel Downloads and color"

# Use all cores for compilation.
# sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf





declare -a archpackages=(
    "alacritty-git"
    "dialog"
    "git"
)


## Tasks

# Install yay/paru

# Enable AUR repos

# Install Pacman packages
for package in "${archpackages[@]}"
do
   : 
   installpkg $package
done

# Install AUR packages

# Install NPM packages

# Install pip packages

# Install nvim setup

# Install dotdrop

# Create ~/.local/bin/* dirs

# Install docker

# Setup permissions
