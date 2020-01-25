#backs up the default make.conf
#this puts some things in place like your make.conf, aswell as package.use

LIGHTGREEN='\033[1;32m'

cd /mnt/gentoo/
wget http://mirrors.rit.edu/gentoo/releases/amd64/autobuilds/current-stage3-amd64-hardened/stage3-amd64-hardened-20200122T214502Z.tar.xz
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
cp /mnt/gentoo/portage/make.conf /mnt/gentoo/etc/portage/
printf "copied new make.conf to /etc/portage/\n"

#copies specific package.use stuff over
cp -a /mnt/gentoo/portage/package.use/. /mnt/gentoo/etc/portage/package.use/
printf "copied over package.use files to /etc/portage/package.use/\n"

#copies specific package stuff over (this might not be necessary)
cp /mnt/gentoo/portage/linux_drivers /mnt/gentoo/etc/portage/
cp /mnt/gentoo/portage/nvidia_package.license /mnt/gentoo/etc/portage/
cp /mnt/gentoo/portage/package.license /mnt/gentoo/etc/portage
cp /mnt/gentoo/portage/package.accept_keywords /mnt/gentoo/etc/portage/
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

chroot /mnt/gentoo ./post_chroot.sh
