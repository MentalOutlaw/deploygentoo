#TODO
#Replace all the echo with printf
source /etc/profile
export PS1="(chroot) ${PS1}"
cpus=$(grep -c ^processor /proc/cpuinfo)
printf "there are %s cpus" $cpus
sed -i "s/MAKEOPTS=\"-j2\"/MAKEOPTS=\"-j$cpus\"/g" /mnt/gentoo/etc/portage/make.conf

cd deploygentoo-master
scriptdir=$(pwd)
cd ..
LIGHTGREEN='\033[1;32m'
LIGHTBLUE='\033[1;34m'
printf ${LIGHTBLUE}"Enter the disk name you want to install gentoo on (ex, sda)"
read disk
printf ${LIGHTBLUE}"Enter the username for your NON ROOT user\n"
#There is a possibility this won't work since the handbook creates a user after rebooting and logging as root
read username
username="${username,,}"
printf ${LIGHTBLUE}"Enter Yes to make a kernel from scratch, edit to edit the hardened config, or No to use the default hardened config\n"
read kernelanswer
printf ${LIGHTBLUE}"Enter the Hostname you want to use\n"
read hostname


#mount /dev/sda1 /boot
part1 = "/dev/%s1" $disk
part2 = "/dev/%s2" $disk
dev_sd = "/dev/%s" $disk
mount $part1
printf "mounted boot\n"
emerge-webrsync
printf "webrsync complete\n"

printf "preparing to do big emerge\n"

emerge --verbose --update --deep --newuse @world
printf "big emerge complete\n"
printf "America/New_York\n" > /etc/timezone
emerge --config sys-libs/timezone-data
printf "timezone data emerged\n"
en_US.UTF-8 UTF-8
printf "en_US.UTF-8 UTF-8\n" >> /etc/locale.gen
locale-gen
printf "script complete\n"
eselect locale set 4
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

#Installs the kernel
#emerge sys-kernel/gentoo-sources
emerge sys-kernel/ck-sources-5.4.7
cd /usr/src/linux
emerge sys-apps/pciutils
emerge lzop
emerge app-arch/lz4
printf "Do you want to configure your own kernel?\n"
if [ $kernelanswer = "No" ]; then
	cp /gentootestscript-master/gentoo/kernel/gentoohardenedminimal /usr/src/linux
	mv gentoohardenedminimal .config
	make oldconfig
	make && make modules_install
	make install
	printf "Kernel installed\n"
elif [ $kernelanswer = "edit" ]; then
	cp /gentootestscript-master/gentoo/kernel/gentoohardenedminimal /usr/src/linux
	mv gentoohardenedminimal .config
	make menuconfig
	make && make modules_install
	make install
	printf "Kernel installed\n"
else
	printf "time to configure your own kernel\n"
	make menuconfig
	make && make modules_installl
	make install
	printf "Kernel installed\n"
fi

#enables DHCP
sed -i -e "s/localhost/$hostname/g" /etc/conf.d/hostname
emerge --noreplace net-misc/netifrc
printf "config_enp0s3=\"dhcp\"\n" >> /etc/conf.d/net
#printf "/dev/sda1\t\t/boot\t\text4\t\tdefaults,noatime\t0 2\n" >> /etc/fstab
printf "%s\t\t/boot\t\text4\t\tdefaults,noatime\t0 2\n" $part1 >> /etc/fstab
#printf "/dev/sda2\t\t/\t\text4\t\tnoatime\t0 1\n" >> /etc/fstab
printf "%s\t\t/\t\text4\t\tnoatime\t0 1\n" $part2 >> /etc/fstab
cd /etc/init.d
ln -s net.lo net.enp0s3
rc-update add net.enp0s3 default
printf "dhcp enabled\n"
emerge app-admin/sysklogd
emerge app-admin/sudo
rm -rf /etc/sudoers
cd $scriptdir
cp sudoers /etc/
printf "installed sudo and enabled it for wheel group\n"
rc-update add sysklogd default
emerge sys-apps/mlocate
emerge net-misc/dhcpcd

#installs grub
emerge --verbose sys-boot/grub:2
#grub-install /dev/sda
grub-install $dev_sd
grub-mkconfig -o /boot/grub/grub.cfg
useradd -m -G users,wheel,audio -s /bin/bash $username
cd ..
printf "cleaning up\n"
mv gentootestscript-master.zip /home/$username
rm -rf /gentootestscript-master
stage3=$(ls stage3*)
rm -rf $stage3
printf "preparing to exit the system, run the following commands and then reboot without the CD\n"
printf "you should now have a working Gentoo installation, dont forget to set your root and user passwords!\n"
printf ${LIGHTGREEN}"passwd\n"
printf ${LIGHTGREEN}"passwd %s\n" $username
printf ${LIGHTGREEN}"exit\n"
printf ${LIGHTGREEN}"cd\n"
printf ${LIGHTGREEN}"umount -l /mnt/gentoo/dev{/shm,/pts,}\n"
printf ${LIGHTGREEN}"umount -R /mnt/gentoo\n"
printf ${LIGHTGREEN}"reboot\n"
rm -rf /post_chroot.sh
exit
