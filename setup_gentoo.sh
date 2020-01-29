#backs up the default make.conf
#this puts some things in place like your make.conf, aswell as package.use

#LIGHTGREEN='\033[1;32m'
##this block of code was added from post_chroot.sh, START
#LIGHTBLUE='\033[1;34m'
#printf ${LIGHTBLUE}"Enter the disk name you want to install gentoo on (ex, sda)\n>"
#read disk
#disk="${disk,,}"
#printf ${LIGHTBLUE}"Enter the username for your NON ROOT user\n>"
##There is a possibility this won't work since the handbook creates a user after rebooting and logging as root
#read username
#username="${username,,}"
#printf ${LIGHTBLUE}"Enter Yes to make a kernel from scratch, edit to edit the hardened config, or No to use the default hardened config\n>"
#read kernelanswer
#kernelanswer="${kernelanswer,,}"
#printf ${LIGHTBLUE}"Enter the Hostname you want to use\n>"
#read hostname

GENTOO_TYPE=latest-stage3-amd64-hardened
STAGE3_PATH_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$GENTOO_TYPE.txt
STAGE3_PATH=$(curl -s $STAGE3_PATH_URL | grep -v "^#" | cut -d" " -f1)
STAGE3_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3_PATH
wget $STAGE3_URL
#this block of code was added from post_chroot.sh, END

cd /mnt/gentoo/
#wget http://mirrors.rit.edu/gentoo/releases/amd64/autobuilds/current-stage3-amd64-hardened/stage3-amd64-hardened-20200122T214502Z.tar.xz
stage3=$(ls stage3*)
printf "found %s\n" $stage3
tar xpvf $stage3 --xattrs-include='*.*' --numeric-owner

mkdir /mnt/gentoo/etc/portage/backup
cd /mnt/gentoo/deploygentoo-master/gentoo/
unzip /mnt/gentoo/deploygentoo-master/gentoo/portage.zip
cd /mnt/gentoo/
cpus=$(grep -c ^processor /proc/cpuinfo)
printf "there are %s cpus\n" $cpus
sed -i "s/MAKEOPTS=\"-j2\"/MAKEOPTS=\"-j$cpus\"/g" /mnt/gentoo/deploygentoo-master/gentoo/portage/make.conf
mv /mnt/gentoo/etc/portage/make.conf /mnt/gentoo/etc/portage/backup/
printf "moved old make.conf to /backup/\n"
#copies our pre-made make.conf over
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/make.conf /mnt/gentoo/etc/portage/
printf "copied new make.conf to /etc/portage/\n"

#copies specific package.use stuff over
cp -a /mnt/gentoo/deploygentoo-master/gentoo/portage/package.use/. /mnt/gentoo/etc/portage/package.use/
printf "copied over package.use files to /etc/portage/package.use/\n"

#copies specific package stuff over (this might not be necessary)
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/linux_drivers /mnt/gentoo/etc/portage/
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/nvidia_package.license /mnt/gentoo/etc/portage/
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/package.license /mnt/gentoo/etc/portage
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/package.accept_keywords /mnt/gentoo/etc/portage/
printf "copied over specific package stuff\n"

#gentoo ebuild repository
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

printf "copied gentoo repository to repos.conf\n"

#copy DNS info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
printf "copied over DNS info\n"

cp /mnt/gentoo/deploygentoo-master/post_chroot.sh /mnt/gentoo/
printf "copied post_chroot.sh to /mnt/gentoo\n"
chmod +x /mnt/gentoo/post_chroot.sh

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

cd /mnt/gentoo
printf "chroot /mnt/gentoo /bin/bash\n"
printf "now run post_chroot.sh\n"
#TODO this part of the script doesn't accept user input, you must have all read commands before you change root
#chroot /mnt/gentoo /bin/bash << "EOT"
#
##TODO
##Replace all the echo with printf
##env-update
##source /etc/profile
##export PS1="(chroot) ${PS1}"
#cd deploygentoo-master
#scriptdir=$(pwd)
#cd ..
#
##mount /dev/sda1 /boot
#part_1=("/dev/${disk}1")
#part_2=("/dev/${disk}2")
#dev_sd=("/dev/$disk")
#mount $part_1
#printf "mounted boot\n"
#emerge-webrsync
#printf "webrsync complete\n"
#
#printf "preparing to do big emerge\n"
#
#emerge --verbose --update --deep --newuse @world
#printf "big emerge complete\n"
#printf "America/New_York\n" > /etc/timezone
#emerge --config sys-libs/timezone-data
#printf "timezone data emerged\n"
#en_US.UTF-8 UTF-8
#printf "en_US.UTF-8 UTF-8\n" >> /etc/locale.gen
#locale-gen
#printf "script complete\n"
#eselect locale set 4
#env-update && source /etc/profile
#
##Installs the kernel
#printf "preparing to emerge kernel sources\n"
#emerge sys-kernel/gentoo-sources
##emerge sys-kernel/ck-sources-5.4.7
##sleep5
##emerge sys-kernel/ck-sources
#cd /usr/src/linux
#emerge sys-apps/pciutils
#emerge lzop
#emerge app-arch/lz4
#printf "Do you want to configure your own kernel?\n"
#if [ $kernelanswer = "no" ]; then
#	cp /deploygentoo-master/gentoo/kernel/gentoohardenedminimal /usr/src/linux
#	mv gentoohardenedminimal .config
#	make olddefconfig
#	make && make modules_install
#	make install
#	printf "Kernel installed\n"
#elif [ $kernelanswer = "edit" ]; then
#	cp /deploygentoo-master/gentoo/kernel/gentoohardenedminimal /usr/src/linux
#	mv gentoohardenedminimal .config
#	make menuconfig
#	make && make modules_install
#	make install
#	printf "Kernel installed\n"
#else
#	printf "time to configure your own kernel\n"
#	make menuconfig
#	make && make modules_installl
#	make install
#	printf "Kernel installed\n"
#fi
#
##enables DHCP
#sed -i -e "s/localhost/$hostname/g" /etc/conf.d/hostname
#emerge --noreplace net-misc/netifrc
#printf "config_enp0s3=\"dhcp\"\n" >> /etc/conf.d/net
##printf "/dev/sda1\t\t/boot\t\text4\t\tdefaults,noatime\t0 2\n" >> /etc/fstab
#printf "%s\t\t/boot\t\text4\t\tdefaults,noatime\t0 2\n" $part_1 >> /etc/fstab
##printf "/dev/sda2\t\t/\t\text4\t\tnoatime\t0 1\n" >> /etc/fstab
#printf "%s\t\t/\t\text4\t\tnoatime\t0 1\n" $part_2 >> /etc/fstab
#cd /etc/init.d
#ln -s net.lo net.enp0s3
#rc-update add net.enp0s3 default
#printf "dhcp enabled\n"
#emerge app-admin/sysklogd
#emerge app-admin/sudo
#printf "just emerged sudo\n"
#rm -rf /etc/sudoers
#cd $scriptdir
#cp sudoers /etc/
#printf "installed sudo and enabled it for wheel group\n"
#rc-update add sysklogd default
#emerge sys-apps/mlocate
#emerge net-misc/dhcpcd
#
##installs grub
#emerge --verbose sys-boot/grub:2
##grub-install /dev/sda
#grub-install $dev_sd
#grub-mkconfig -o /boot/grub/grub.cfg
#printf "updated grub\n"
#useradd -m -G users,wheel,audio -s /bin/bash $username
#printf "just tried to add our user\n"
#cd ..
#printf "cleaning up\n"
#mv deploygentoo-master.zip /home/$username
#rm -rf /deploygentoo-master
#stage3=$(ls stage3*)
#rm -rf $stage3
#printf "preparing to exit the system, run the following commands and then reboot without the CD\n"
#printf "you should now have a working Gentoo installation, dont forget to set your root and user passwords!\n"
#printf ${LIGHTGREEN}"passwd\n"
#printf ${LIGHTGREEN}"passwd %s\n" $username
#printf ${LIGHTGREEN}"exit\n"
#printf ${LIGHTGREEN}"cd\n"
#printf ${LIGHTGREEN}"umount -l /mnt/gentoo/dev{/shm,/pts,}\n"
#printf ${LIGHTGREEN}"umount -R /mnt/gentoo\n"
#printf ${LIGHTGREEN}"reboot\n"
#rm -rf /post_chroot.sh
##exit
#EOT
