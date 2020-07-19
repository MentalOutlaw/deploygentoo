source /etc/profile
cd deploygentoo-master
scriptdir=$(pwd)
cd ..
LIGHTRED='\033[1;91m'
LIGHTGREEN='\033[1;32m'
sed '/^$/d' /mnt/gentoo/install_vars >> /mnt/gentoo/temp_f
rm -rf /mnt/gentoo/install_vars
cat /mnt/gentoo/temp_f >> /mnt/gentoo/install_vars
rm -rf /mnt/gentoo/temp_f
install_vars=/mnt/gentoo/install_vars
install_vars_count="$(wc -w /mnt/gentoo/install_vars)"
disk=$(sed '1q;d' install_vars)
username=$(sed '2q;d' install_vars)
kernelanswer=$(sed '3q;d' install_vars)
hostname=$(sed '4q;d' install_vars)
sslanswer=$(sed '5q;d' install_vars)
cpus=$(sed '6q;d' install_vars)
part_3=$(sed '7q;d' install_vars)
part_1=$(sed '8q;d' install_vars)
part_2=$(sed '9q;d' install_vars)
part_4=$(sed '10q;d' install_vars)
nw_interface=$(sed '11q;d' install_vars)
performance_opts=$(sed '12q;d' install_vars)
dev_sd=("/dev/$disk")
mount $part_2 /boot
jobs=("-j${cpus}")
printf "%s jobs equals \n" % $jobs
printf "mounted boot\n"
#TODO everything below this point fails on musl, figure out why, error is Your current profile is invalid
emerge --sync --quiet
emerge -q app-portage/mirrorselect
printf "searching for fastest servers\n"
mirrorselect -s5 -b10 -D
printf "sync complete\n"
sleep 10
filename=gentootype.txt
line=$(head -n 1 $filename)
#Checks what type of stage was used, and installs necessary overlays
case $line in
  latest-stage3-amd64-hardened)
    #TODO put stuff specific to gcc hardened here
    emerge --verbose --update --deep --newuse --quiet @world
    printf "big emerge complete\n"
    ;;
  latest-stage3-amd64-musl-hardened)
    eselect profile set --force 31
    echo "dev-vcs/git -gpg" >> /etc/portage/package.use
    emerge app-portage/layman dev-vcs/git
    layman -a musl
    emerge -uvNDq @world
    ;;
  latest-stage3-amd64-musl-vanilla)
    eselect profile set --force 30
    echo "dev-vcs/git -gpg" >> /etc/portage/package.use
    emerge app-portage/layman dev-vcs/git
    layman -a musl
    emerge -uvNDq @world
    ;;
esac


printf "preparing to do big emerge\n"

printf "America/New_York\n" > /etc/timezone
emerge --config --quiet sys-libs/timezone-data
printf "timezone data emerged\n"
#en_US.UTF-8 UTF-8
printf "en_US.UTF-8 UTF-8\n" >> /etc/locale.gen
locale-gen
printf "script complete\n"
eselect locale set 4
env-update && source /etc/profile

#Installs the kernel
printf "preparing to emerge kernel sources\n"
emerge -q sys-kernel/gentoo-sources
sleep 10
ls -l /usr/src/linux
cd /usr/src/linux
emerge -q sys-apps/pciutils
emerge -q app-arch/lzop
emerge -q app-arch/lz4
if [ $kernelanswer = "no" ]; then
	rm -rf /usr/src/linux/.config
	make mrproper
	cp /deploygentoo-master/gentoo/kernel/gentoohardenedminimal /usr/src/linux/.config
	make olddefconfig
	make $jobs && make modules_install
	make install
	printf "Kernel installed\n"
elif [ $kernelanswer = "edit" ]; then
    make mrproper
	cp /deploygentoo-master/gentoo/kernel/gentoohardenedminimal /usr/src/linux/.config
	make menuconfig
	make $jobs && make modules_install
	make install
	printf "Kernel installed\n"
else
	printf "time to configure your own kernel\n"
	make menuconfig
	make $jobs && make modules_installl
	make install
	printf "Kernel installed\n"
fi

cd /etc/init.d
#enables DHCP
sed -i -e "s/localhost/$hostname/g" /etc/conf.d/hostname
emerge --noreplace --quiet net-misc/netifrc
nw_config_str=("config_${nw_interface}=\"dhcp\"")
printf "$nw_config_str\n" >> /etc/conf.d/net
if [ $install_vars_count -gt 11 ]; then
    nw_interface2=$(sed '12q;d' install_vars)
    nw_config_str3=("config_${nw_interface2}=\"dhcp\"")
    printf "$nw_config_str3\n" >> /etc/conf.d/net
    net_config_str4=("net.${nw_interface2}")
    ln -s net.lo $net_config_str4
    rc-update add $net_config_str4 default
else
    printf "only 1 network device found\n"
fi
UUID2=$(blkid -s UUID -o value $part_2)
UUID2=("UUID=${UUID2}")
UUID3=$(blkid -s UUID -o value $part_3)
UUID3=("UUID=${UUID3}")
UUID4=$(blkid -s UUID -o value $part_4)
UUID4=("UUID=${UUID4}")
printf "%s\t\t/boot/efi\tvfat\t\tdefaults\t0 2\n" $UUID2 >> /etc/fstab
SUB_STR='/dev/'
if [[ "$part_3" == *"$SUB_STR"* ]]; then
    printf "%s\t\tnone\t swap\t\tsw\t\t0 0\n" $UUID3 >> /etc/fstab
fi
printf "%s\t\t/\t\text4\t\tnoatime\t0 1\n" $UUID4 >> /etc/fstab
net_config_str2=("net.${nw_interface}")
ln -s net.lo $net_config_str2
rc-update add $net_config_str2 default
printf "dhcp enabled\n"
emerge -q app-admin/sudo
rm -rf /etc/sudoers
cd $scriptdir
cp sudoers /etc/
printf "installed sudo and enabled it for wheel group\n"
emerge -q sys-apps/mlocate
emerge -q net-misc/dhcpcd

#installs grub, and layman
emerge --verbose -q sys-boot/grub:2
printf "run commands manually from here on to see what breaks\n"
emerge -q app-portage/layman
##use this for MBR# grub-install $dev_sd
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
printf "updated grub\n"
useradd -m -G users,wheel,audio -s /bin/bash $username
printf "added user\n"
cd ..
mv deploygentoo-master.zip /home/$username
##rm -rf /deploygentoo-master
stage3=$(ls stage3*)
rm -rf $stage3
if [ $sslanswer = "yes" ]; then
	emerge -q gentoolkit
	mkdir -p /etc/portage/profile
	echo "-libressl" >> /etc/portage/profile/use.stable.mask
	echo "dev-libs/openssl" >> /etc/portage/package.mask
	echo "dev-libs/libressl" >> /etc/portage/package.accept_keywords
	emerge -f libressl
	emerge -C openssl
	emerge -1q libressl
	emerge -1q openssh wget python:2.7 python:3.6 iputils
#    #TODO
#    #check to see if we can get away with a preserved-rebuild instead of a world emerge for lto
#    #if yes then place the ssl build below lto
	emerge -q @preserved-rebuild
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
    layman -f
    layman -a libressl
    layman -S
else
	printf "not useing LibreSSL\n"
fi

if [ $performance_opts = "yes" ]; then
    yes | layman -a mv
    yes | layman -a lto-overlay
    #this command doesn't work to emerge ltoize
    #TODO figure out how to fix it
    #emerge -q sys-config/ltoize
    echo "NTHREADS=\"${cpus}\"" /etc/portage/make.conf
#    emerge -e @world
    printf "performance enhancements setup, you'll have to emerge sys-config/ltoize to complete\n"
elif [ $performance_opts = "no" ]; then
    printf "performance optimization not selected\n"
fi

while true; do
    printf ${LIGHTGREEN}"enter the password for your root user\n>"
    read -s password
    printf ${LIGHTGREEN}"re-enter the password for your root user\n>"
    read -s password_compare
    if [ "$password" = "$password_compare" ]; then
	echo "root:$password" | chpasswd
        break
    else
        printf ${LIGHTRED}"passwords do not match, re enter them\n"
        printf ${WHITE}".\n"
        sleep 3
        clear
    fi
done
while true; do
    printf ${LIGHTGREEN}"enter the password for your user %s\n>" $username
    read -s password
    printf ${LIGHTGREEN}"re-enter the password for %s\n>" "$username"
    read -s password_compare
    if [ "$password" = "$password_compare" ]; then
	echo "$username:$password" | chpasswd
        break
    else
        printf ${LIGHTRED}"passwords do not match, re enter them\n"
        printf ${WHITE}".\n"
        sleep 3
        clear
    fi
done
printf "cleaning up\n"
rm -rf /gentootype.txt
rm -rf /install_vars
rm -rf /deploygentoo-master
printf ${LIGHTGREEN}"You now have a completed gentoo installation system, reboot and remove the installation media to load it\n"
printf ${LIGHTGREEN}"reboot\n"
rm -rf /post_chroot.sh
