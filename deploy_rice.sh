#!/bin/bash
cd rice/
scriptdir=$(pwd)
cd ..
script_home=$(pwd)
cd ..
userhome=$(pwd)
cd $script_home


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

if [ "$EUID" -ne 0 ]
  then printf "The script has to be run as root.\n"
  exit
fi

printf "This script is designed for gentoo linux and it will not work in any other OS\n"
printf "Installing dependencies listed in dependencies.txt...\n"

DEPLIST="`sed -e 's/#.*$//' -e '/^$/d' dependencies.txt | tr '\n' ' '`"

#Installs and configures layman
emerge -q app-portage/layman
sed -i "s/conf_type : repos.conf/conf_type : make.conf/g" /etc/layman/layman.cfg
if grep "source /var/lib/layman/make.conf" /etc/portage/make.conf; then
    printf "layman source already added to make.conf\n"
else
    echo "source /var/lib/layman/make.conf" >> /etc/portage/make.conf
fi
if grep "PORTDIR_OVERLAY" /etc/portage/make.conf; then
    printf "PORTDIR_OVERLAY string already added to make.conf\n"
else
    #echo "PORTDIR_OVERLAY=\"${PORTDIR_OVERLAY} /usr/local/portage/\"" >> /etc/portage/make.conf
    printf "nothing to do here\n"
fi
emerge -q dev-vcs/git
check_dir_exists /var/lib/layman/libressl
if $exists; then
    printf "libressl has already been added"
else
    layman -a libressl
    layman -S
fi
#yes | layman -a steam-overlay

emerge -q $DEPLIST

printf "installed dependencies\n"
check_dir_exists /usr/lib64/urxvt/perl/font-size
if $exists; then
	printf "urxvt font-size folder already exists\n"
else
    check_dir_exists /usr/lib64/urxvt
    if $exists; then
        cd /usr/lib64/urxvt/perl
        git clone https://github.com/majutsushi/urxvt-font-size
        mv urxvt-font-size/font-size .
    else
        printf "urxvt folder doesn't exist, urxvt was not emerged correctly\n"
    fi
fi
BIN_DIR=${BIN_DIR:-/usr/local/bin/}

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
check_dir_exists $HOME/.config/st
if $exists; then
	printf "st folder exists already"
else
	echo "cloning st from github"
    git clone https://github.com/MentalOutlaw/st
fi
check_dir_exists $HOME/.config/slstatus
if $exists; then
	printf "slstatus folder exists already"
else
	echo "cloning slstatus from github"
    git clone https://github.com/MentalOutlaw/slstatus
fi
check_dir_exists $HOME/.config/dwm
if $exists; then
	printf "dwm folder exists already"
else
	echo "cloning dwm from github"
    git clone https://github.com/MentalOutlaw/dwm
fi
check_dir_exists $HOME/.config/dmenu
if $exists; then
	printf "dmenu folder exists already"
else
	echo "cloning dmenu from github"
    git clone https://github.com/MentalOutlaw/dmenu
fi

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

modprobe snd-intel8x0
#This lets us have a non-root Xorg
chmod 4711 /usr/bin/Xorg

fc-cache -fv

echo "Install finished. Add software to .xinitrc to launch the DE with startx,
or copy the provided .xinitrc file to your home directory (backup the old one!)"
if grep "1920x1080" /etc/X11/xorg.conf; then
    printf "xorg.conf is already generated, check your config\n"
else
    X -configure
    sed -ie "79i\ \t\tModes\t  \"1920x1080\"" /root/xorg.conf.new
    rm -rf /etc/X11/xorg.conf
    mv /root/xorg.conf.new /etc/X11/xorg.conf
fi


printf "your GUI should be set up now, use startx to launch it\n"
