#!/bin/bash

check_file_exists () {
	file=$1
	if [ -e $file ]; then
		exists=true
	else
		printf "%s doesn't exist\n" $file
		exists=false
		$2
	fi
}
check_dir_exists () {
	file=$1
	if [ -d $file ]; then
		exists=true
	else
		printf "%s doesn't exist\n" $file
		exists=false
		$2
	fi
}
set -e

if [ "$EUID" -ne 0 ]
  then echo "The script has to be run as root."
  exit
fi

BIN_DIR=${BIN_DIR:-/usr/local/bin/}

scriptdir=$(pwd)
cd ..
cd ..
userhome=$(pwd)
check_dir_exists $HOME/.config
if $exists; then
	printf "root users .config directory already exists"
else
	echo "creating rice directory for root"
	mkdir -p $HOME/.config
fi
check_dir_exists $userhome/.config
if $exists; then
	printf "your users .config directory already exists"
else
	echo "creating rice directory for user"
	mkdir -p .config/htop
	cp -f dots/aliasrc .config/
	cp -f dots/htoprc .config/htop
fi
cd $scriptdir

checkinstdir() {
if [ -d $1 ]; then
	echo "$1 ok"
else
	echo "$1 is missing"
	exit -1
fi
}

echo "Checking directories"
checkinstdir $BIN_DIR
#check_file_exists $HOME/.bashrc
echo "Adding Dots to root home"
cp -f dots/.rootbashrc /$HOME/.bashrc
cp -f dots/.vimrc $HOME
cp -f dots/.xinitrc $HOME
cp -f dots/.Xresources $HOME
cp -f dots/init.vim $HOME

echo "Adding Dots to user home"
cp -f dots/.bashrc $userhome
cp -f dots/.vimrc $userhome
cp -f dots/.xinitrc $userhome
cp -f dots/.Xresources $userhome
cp -f dots/init.vim $userhome

cd $HOME/.config
git clone https://github.com/MentalOutlaw/st
git clone https://github.com/MentalOutlaw/slstatus
git clone https://github.com/MentalOutlaw/dwm
git clone https://github.com/MentalOutlaw/dmenu

cd $HOME/.config/dwm
make clean install
echo "installed dwm"
cd $HOME/.config/dmenu
make clean install
echo "installed dmenu"
cd $HOME/.config/slstatus
make clean install
echo "installed slstatus"
cd $HOME/.config/st
make clean install
echo "installed st"

#chmod +x $userhome/deploygentoo/finalize.sh
#sh $userhome/deploygentoo/finalize.sh
#echo "xorg can now be run as a non root user, and ALSA works now"
#this gets alsa working
modprobe snd-intel8x0
#This lets us have a non-root Xorg
chmod 4711 /usr/bin/Xorg

fc-cache -fv

echo "Install finished. Add software to .xinitrc to launch the DE with startx,
or copy the provided .xinitrc file to your home directory (backup the old one!)"
