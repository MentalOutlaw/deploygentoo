#backs up the default make.conf
#this puts some things in place like your make.conf, aswell as package.use
#cd ..
#mv deploygentoo-master /mnt/gentoo
#cd /mnt/gentoo/deploygentoo-master

LIGHTGREEN='\033[1;32m'
LIGHTBLUE='\033[1;34m'
printf "enter a number for the stage 3 you want to use\n"
printf "0 = regular hardened\n1 = hardened musl\n2 = vanilla musl\n>"
read stage3select
printf "enter a number for the SSL Library you want to use\n"
printf "0 = OpenSSL default\n1 = LibreSSL (recommended)\n>"
read ssl_choice
printf ${LIGHTBLUE}"Enter the disk name you want to install gentoo on (ex, sda)\n>"
read disk
disk="${disk,,}"
printf ${LIGHTBLUE}"Enter the username for your NON ROOT user\n>"
#There is a possibility this won't work since the handbook creates a user after rebooting and logging as root
read username
username="${username,,}"
printf ${LIGHTBLUE}"Enter Yes to make a kernel from scratch, edit to edit the hardened config, or No to use the default hardened config\n>"
read kernelanswer
kernelanswer="${kernelanswer,,}"
printf ${LIGHTBLUE}"Enter the Hostname you want to use\n>"
read hostname
printf ${LIGHTBLUE}"Do you want to replace OpenSSL with LibreSSL in your system?(yes or no)\n>"
read sslanswer
sslanswer="${sslanswer,,}"
printf ${LIGHTGREEN}"Beginning installation, this will take several minutes\n"
install_vars=/mnt/gentoo/deploygentoo-master/install_vars
echo "$disk" >> "$install_vars"
echo "$username" >> "$install_vars"
echo "$kernelanswer" >> "$install_vars"
echo "$hostname" >> "$install_vars"
echo "$sslanswer" >> "$install_vars"
case $stage3select in
  0)
    GENTOO_TYPE=latest-stage3-amd64-hardened
    ;;
  1)
    GENTOO_TYPE=latest-stage3-amd64-musl-hardened
    ;;
  2)
    GENTOO_TYPE=latest-stage3-amd64-musl-vanilla
    ;;
esac

STAGE3_PATH_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$GENTOO_TYPE.txt
STAGE3_PATH=$(curl -s $STAGE3_PATH_URL | grep -v "^#" | cut -d" " -f1)
STAGE3_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3_PATH
touch /mnt/gentoo/gentootype.txt
echo $GENTOO_TYPE >> /mnt/gentoo/gentootype.txt
cd /mnt/gentoo/
wget --tries=20 $STAGE3_URL
check_file_exists () {
	file=$1
	if [ -e $file ]; then
		exists=true
	else
		printf "%s doesn't exist\n" $file
		wget --tries=20 $STAGE3_URL
		exists=false
		$2
	fi
}

check_file_exists /mnt/gentoo/stage3*
check_file_exists /mnt/gentoo/stage3*
stage3=$(ls /mnt/gentoo/stage3*)
tar xpvf /mnt/gentoo/$stage3 --xattrs-include='*.*' --numeric-owner
printf "unpacked stage 3\n"

#rm -rf /mnt/gentoo/etc/portage
cd /mnt/gentoo/deploygentoo-master/gentoo/
cp -a /mnt/gentoo/deploygentoo-master/gentoo/portage/package.use/. /mnt/gentoo/etc/portage/package.use/
#TODO test if this works when setting up gentoo in chroot
case $ssl_choice in
  0)
    #Nothing to do here for default SSL
    ;;
  1)
    echo "dev-vcs/git -gpg" >> /etc/portage/package.use
    emerge app-portage/layman dev-vcs/git
    ;;
esac
cd /mnt/gentoo/
cpus=$(grep -c ^processor /proc/cpuinfo)
printf "there are %s cpus\n" $cpus
sed -i "s/MAKEOPTS=\"-j2\"/MAKEOPTS=\"-j$cpus\"/g" /etc/portage/make.conf
printf "moved portage files into place\n"
mkdir /mnt/gentoo/etc/portage/backup/
mv /mnt/gentoo/etc/portage/make.conf /mnt/gentoo/etc/portage/backup/
printf "moved old make.conf to /backup/\n"
##copies our pre-made make.conf over
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/make.conf /mnt/gentoo/etc/portage/
printf "copied new make.conf to /etc/portage/\n"

cp /mnt/gentoo/deploygentoo-master/gentoo/portage/linux_drivers /mnt/gentoo/etc/portage/
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/nvidia_package.license /mnt/gentoo/etc/portage/
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/package.license /mnt/gentoo/etc/portage
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/package.accept_keywords /mnt/gentoo/etc/portage/
cp -r /mnt/gentoo/deploygentoo-master/gentoo/portage/profile /mnt/gentoo/etc/portage/
cp -r /mnt/gentoo/deploygentoo-master/gentoo/portage/savedconfig /mnt/gentoo/etc/portage/

mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
#
printf "copied gentoo repository to repos.conf\n"
#
##copy DNS info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc
printf "copied over DNS info\n"

cp /mnt/gentoo/deploygentoo-master/post_chroot.sh /mnt/gentoo/
cp /mnt/gentoo/deploygentoo-master/install_vars /mnt/gentoo/
printf "copied post_chroot.sh to /mnt/gentoo\n"
chmod +x /mnt/gentoo/post_chroot.sh

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

cd /mnt/gentoo
chroot /mnt/gentoo /mnt/gentoo/post_chroot.sh
