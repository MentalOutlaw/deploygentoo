#!/bin/bash
LIGHTRED='\033[1;91m'
LIGHTGREEN='\033[1;32m'
source /etc/profile
cd deploygentoo-master
scriptdir=$(pwd)
cd ..
sed -i '/^$/d' install_vars
#rm -rf /mnt/gentoo/install_vars
#cat /temp_f >> /mnt/gentoo/install_vars
#rm -rf /mnt/gentoo/temp_f
install_vars=install_vars

install_vars_count="$(wc -w /install_vars)"
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
performance_opts=$(sed '11q;d' install_vars)
#This line is getting written to line 13 for some reason
nw_interface=$(sed '12q;d' install_vars)
dev_sd=("/dev/$disk")
mount $part_2 /boot
jobs=("-j${cpus}")
#printf "jobs equals %s" % $jobs
printf "mounted boot\n"
#TODO everything below this point fails on musl, figure out why, error is Your current profile is invalid
emerge --sync --quiet
#TODO This emerge fails for some reason
emerge -q app-portage/mirrorselect
emerge -q gentoolkit
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
    emerge -uvNDq @world
    ;;
  latest-stage3-amd64-musl-vanilla)
    eselect profile set --force 30
    echo "dev-vcs/git -gpg" >> /etc/portage/package.use
    emerge -uvNDq @world
    ;;
  latest-stage3-amd64)
    emerge -uvNDq @world
    printf "big emerge complete\n"
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
emerge --autounmask-continue -q sys-kernel/genkernel
emerge app-eselect/eselect-repository
if [ $kernelanswer = "no" ]; then
	#cp /deploygentoo-master/gentoo/kernel/gentoominimal /root/kernel.config
	#genkernel --kernel-config=/root/kernel.config all
	cp /deploygentoo-master/gentoo/kernel/gentoominimal /usr/src/linux/.config
	make $jobs && make modules_install
	make install
	#mv /root/kernel.config /usr/src/linux/.config
	printf "Kernel installed\n"
elif [ $kernelanswer = "edit" ]; then
    make mrproper
	cp /deploygentoo-master/gentoo/kernel/gentoominimal /usr/src/linux/.config
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
genkernel --install --kernel-config=/usr/src/linux/.config initramfs

cd /etc/init.d
#enables DHCP
sed -i -e "s/localhost/$hostname/g" /etc/conf.d/hostname
emerge --noreplace --quiet net-misc/netifrc
nw_config_str=("config_${nw_interface}=\"dhcp\"")
printf "$nw_config_str\n" >> /etc/conf.d/net
if [ $install_vars_count -gt 12 ]; then
    nw_interface2=$(sed '13q;d' install_vars)
    nw_config_str3=("config_${nw_interface2}=\"dhcp\"")
    printf "$nw_config_str3\n" >> /etc/conf.d/net
    net_config_str4=("net.${nw_interface2}")
    ln -s net.lo $net_config_str4
    rc-update add $net_config_str4 default
    rc-update add elogind boot
else
    printf "only 1 network device found\n"
fi
lscpu >> install_vars
UUID2=$(blkid -s UUID -o value $part_2)
UUID2=("UUID=${UUID2}")
UUID3=$(blkid -s UUID -o value $part_3)
UUID3=("UUID=${UUID3}")
UUID4=$(blkid -s UUID -o value $part_4)
UUID4=("UUID=${UUID4}")
printf "%s\t\t/boot/efi\tvfat\t\tdefaults\t0 2\n" $UUID2 >> /etc/fstab
SUB_STR='/dev/'
if [[ "$part_3" == *"$SUB_STR"* ]]; then
    printf "%s\t\tnone\t\tswap\t\tsw\t\t0 0\n" $UUID3 >> /etc/fstab
fi
printf "%s\t\t/\t\text4\t\tnoatime\t\t0 1\n" $UUID4 >> /etc/fstab
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

#installs grub
emerge --verbose -q sys-boot/grub:2
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
printf "updated grub\n"
printf "run commands manually from here on to see what breaks\n"
##use this for MBR# grub-install $dev_sd
useradd -m -G users,wheel,audio -s /bin/bash $username
printf "added user\n"
cd ..
mv deploygentoo-master.zip /home/$username
##rm -rf /deploygentoo-master
stage3=$(ls stage3*)
rm -rf $stage3
#libressl selection stage
#if [ $sslanswer = "yes" ]; then
#    sed -i 's/-ios/-ios libressl/g' /etc/portage/make.conf
#    sed -i -e '$aCURL_SSL="libressl"' /etc/portage/make.conf
#    cp -r /deploygentoo-master/gentoo/portage/profile /etc/portage/
#    emerge -q gentoolkit
#    mkdir -p /etc/portage/profile
#    echo "-libressl" >> /etc/portage/profile/use.stable.mask
#    echo "dev-libs/openssl" >> /etc/portage/package.mask
#    echo "dev-libs/libressl" >> /etc/portage/package.accept_keywords
#    emerge -f libressl
#    emerge -C openssl
#    emerge -1q libressl
#    emerge -1q openssh wget python:2.7 python:3.6 iputils
##    #TODO
##    #check to see if we can get away with a preserved-rebuild instead of a world emerge for lto
##    #if yes then place the ssl build below lto
#    emerge -q @preserved-rebuild
#delete here Start
#    emerge -q app-portage/layman
#    sed -i "s/conf_type : repos.conf/conf_type : make.conf/g" /etc/layman/layman.cfg
#    if grep "source /var/lib/layman/make.conf" /etc/portage/make.conf; then
#        printf "layman source already added to make.conf\n"
#    else
#        echo "source /var/lib/layman/make.conf" >> /etc/portage/make.conf
#    fi
#Delete here end
#    layman -f
#    layman -a libressl
#    layman -S
#else
#    printf "not useing LibreSSL\n"
#fi

if [ $performance_opts = "yes" ]; then
#ADDED TODAY START
    emerge --autounmask-continue -UD @world
    emerge dev-vcs/git
    eselect repository enable mv
    eselect repository enable lto-overlay
    emerge --sync
    emerge --oneshot --quiet sys-devel/gcc
    gcc-config 2
    emerge --oneshot --usepkg=n --quiet sys-devel/libtool
    emerge --autounmask-continue app-text/texlive
    emerge -q dev-libs/isl
    cd /bin
    git clone https://github.com/periscop/cloog
    cd cloog
    GET_SUBMODULES="/bin/cloog/get_submodules.sh"
    . "$GET_SUBMODULES"
    AUTOGEN="/bin/cloog/autogen.sh"
    . "$AUTOGEN"
    CONFIG="/bin/cloog/configure"
    bash "$CONFIG"
    make && make install
    echo "dev-lang/python::lto-overlay ~amd64" >> /etc/portage/package.accept_keywords
    echo "dev-lang/python::lto-overlay ~amd64" >> /etc/portage/package.accept_keywords
    echo "virtual/freedesktop-icon-theme::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-portage/eix::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-shells/push::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-shells/quoter::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-text/lesspipe::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "sys-apps/less::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "x11-libs/gtk+::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "virtual/man::mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "sys-apps/less:mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-text/lesspipe:mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-shells/quoter:mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-shells/push:mv ~amd64" >> /etc/portage/package.accept_keywords
    echo "app-portage/eix:mv ~amd64" >> /etc/portage/package.accept_keywords
    emerge -q sys-config/ltoize
    emerge -q app-portage/portage-bashrc-mv
    emerge -q app-portage/eix
    emerge -q app-portage/lto-rebuild
    emerge -q app-shells/runtitle
    emerge -q app-shells/push
    emerge -q app-shells/quoter
    emerge -q app-text/lesspipe
    emerge -q sys-apps/less
    emerge -q virtual/freedesktop-icon-theme
    emerge -q virtual/man
    emerge -q dev-lang/python
    #TODO add option to append -falign-functions=32 to CFLAGS if user has an Intel Processor
    if grep -Fq "$GenuineIntel" install_vars
    then
        sed -i 's/^CFLAGS=\"${COMMON_FLAGS}\"/CFLAGS=\"-march=native ${CFLAGS} -pipe -falign-functions=32\"/g' /etc/portage/make.conf
    else
        sed -i 's/^CFLAGS=\"${COMMON_FLAGS}\"/CFLAGS=\"-march=native ${CFLAGS} -pipe\"/g' /etc/portage/make.conf
    fi
    sed -i 's/CXXFLAGS=\"${COMMON_FLAGS}\"/CXXFLAGS=\"${CFLAGS}\"/g' /etc/portage/make.conf
    sed -i "5s/^/NTHREADS=\"$cpus\"\n/" /etc/portage/make.conf
    sed -i '6s/^/source make.conf.lto\n\n/' /etc/portage/make.conf
    sed -i '11s/^/LDFLAGS=\"${CFLAGS} -fuse-linker-plugin\"\n/' /etc/portage/make.conf
    sed -i '12s/^/CPU_FLAGS_X86=\"aes avx avx2 f16c fma3 mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3\"\n/' /etc/portage/make.conf
    sed -i 's/-quicktime/-quicktime lto/g' /etc/portage/make.conf
    sed -i 's/-clamav/-clamav graphite/g' /etc/portage/make.conf
    emerge gcc
    emerge dev-util/pkgconf
    emerge -eq --keep-going @world
    printf "performance enhancements setup, you'll have to emerge sys-config/ltoize to complete\n"
elif [ $performance_opts = "no" ]; then
    printf "performance optimization not selected\n"
fi
#libressl selection stage
if [ $sslanswer = "yes" ]; then
    sed -i 's/-ios/-ios libressl/g' /etc/portage/make.conf
    sed -i 's/mbedtls/mbedtls libressl/g' /etc/portage/package.use/package.use
    sed -i 's/nodejs/nodejs -system-ssl/g' /etc/portage/package.use/package.use
    sed -i -e '$aCURL_SSL="libressl"' /etc/portage/make.conf
    cp -r /deploygentoo-master/gentoo/portage/profile /etc/portage/
    mkdir -p /etc/portage/profile
    echo "-libressl" >> /etc/portage/profile/use.stable.mask
    echo "dev-libs/openssl" >> /etc/portage/package.mask
    echo "dev-libs/libressl ~amd64" >> /etc/portage/package.accept_keywords
    echo "=dev-qt/qtnetwork-5.15.0::libressl ~amd64" >> /etc/portage/package.accept_keywords
    emerge -f libressl
    emerge -C openssl
    emerge -1q libressl
    emerge -1q openssh wget python:2.7 python:3.6 iputils
    emerge -q @preserved-rebuild
    layman -f
    layman -a libressl
    layman -S
else
    printf "not useing LibreSSL\n"
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
cp -r /deploygentoo-master/gentoo/portage/savedconfig /etc/portage/
cp -r /deploygentoo-master/gentoo/portage/env /etc/portage/
cp /deploygentoo-master/gentoo/portage/package.env /etc/portage/
rm -rf /deploygentoo-master
printf ${LIGHTGREEN}"You now have a completed gentoo installation system, reboot and remove the installation media to load it\n"
printf ${LIGHTGREEN}"reboot\n"
rm -rf /post_chroot.sh
