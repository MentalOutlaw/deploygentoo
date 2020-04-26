#!/bin/bash
#TODO
#there are some situations in which the deploygentoo-master folder will be named deploygentoo
#make this script work with that folder name aswell

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
emerge app-portage/layman
sed -i "s/conf_type : repos.conf/conf_type : make.conf/g" /etc/layman/layman.cfg
echo >> "source /var/lib/layman/make.conf" /etc/portage/make.conf
echo >> "PORTDIR_OVERLAY=\"${PORTDIR_OVERLAY} /usr/local/portage/\"" /etc/portage/make.conf
layman -a libressl
layman -S

emerge $DEPLIST
USE="X" emerge app-editors/vim
USE="perl xft" emerge x11-terms/rxvt-unicode
#USE="cli libmpv" emerge media-video/mpv

printf "installed dependencies\n"
script_home=$(pwd)
#check_dir_exists /apps
#if $exists; then
#	printf "apps directory already exists"
#else
#	unzip rice.zip
#fi
cd rice/
chmod +x rice-gentoo.sh
sh rice-gentoo.sh
X -configure
sed -ie "85i\ \t\tModes\t  \"1920x1080\"" /root/xorg.conf.new
cp /root/xorg.conf.new /etc/X11/xorg.conf
printf "completed installing dependencies\n"
X -configure
sed -ie "79i\ \t\tModes\t  \"1920x1080\"" /root/xorg.conf.new
rm -rf /etc/X11/xorg.conf
mv /root/xorg.conf.new /etc/X11/xorg.conf
printf "your GUI should be set up now, use startx to launch it\n"
