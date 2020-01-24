#backs up the default make.conf
#this puts some things in place like your make.conf, aswell as package.use

LIGHTGREEN='\033[1;32m'

cd /mnt/gentoo/
stage3=$(ls stage3*)
printf "found %s\n" $stage3
tar xpvf $stage3 --xattrs-include='*.*' --numeric-owner

mkdir /mnt/gentoo/etc/portage/backup
unzip /mnt/gentoo/deploygentoo-master/gentoo/portage.zip
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

#rm -rf /portage
#printf "clened up files\n"
#printf "mounted all the things\n"
#printf "you should now chroot into the new environment\n"
chroot /mnt/gentoo ./post_chroot.sh
#printf ${LIGHTGREEN}"chroot /mnt/gentoo /bin/bash"
#printf ${LIGHTGREEN}"source /etc/profile"
#printf ${LIGHTGREEN}"export PS1=\"(chroot) \${PS1}\""

#below this point we have to create a seperate script to run in the chroot portion
#chroot /mnt/gentoo /bin/bash << "EOT"
#source /etc/profile
#export PS1="(chroot) ${PS1}"

