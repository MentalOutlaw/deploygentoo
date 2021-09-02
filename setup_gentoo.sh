#!/bin/bash
#this puts some things in place like your make.conf, aswell as package.use
LIGHTGREEN='\033[1;32m'
LIGHTRED='\033[1;91m'
WHITE='\033[1;97m'
MAGENTA='\033[1;35m'
CYAN='\033[1;96m'
cd ..
start_dir=$(pwd)
printf ${MAGENTA}"MAKE SURE YOUR ROOT PARTITION IS THE 2ND ONE ON THE DEVICE YOU'LL BE INSTALLING TO\n\n"
fdisk -l >> devices
ifconfig -s >> nw_devices
cut -d ' ' -f1 nw_devices >> network_devices
rm -rf nw_devices
sed -e "s/lo//g" -i network_devices
sed -e "s/Iface//g" -i network_devices
sed '/^$/d' network_devices
sed -e '\#Disk /dev/ram#,+5d' -i devices
sed -e '\#Disk /dev/loop#,+5d' -i devices

cat devices
while true; do
    printf ${CYAN}"Enter the device name you want to install gentoo on (ex, sda for /dev/sda)\n>"
    read disk
    disk="${disk,,}"
    partition_count="$(grep -o $disk devices | wc -l)"
    disk_chk=("/dev/${disk}")
    if grep "$disk_chk" devices; then
        printf "Would you like to auto provision %s? \n This will create a GPT partition scheme where\n%s1 = 2 MB bios_partition\n%s2 = 128 MB boot partition\n%s3 = 4 GB swap_partition\n%s4 x GB root partition (the rest of the hard disk)\n\nEnter y to continue with auto provision or n to exit the script \n>" $disk_chk $disk_chk $disk_chk $disk_chk $disk_chk
        read auto_prov_ans
        if [ "$auto_prov_ans" = "y" ]; then
            wipefs -a $disk_chk
            parted -a optimal $disk_chk --script mklabel gpt
            parted $disk_chk --script mkpart primary 1MiB 3MiB
            parted $disk_chk --script name 1 grub
            parted $disk_chk --script set 1 bios_grub on
            parted $disk_chk --script mkpart primary 3MiB 131MiB
            parted $disk_chk --script name 2 boot
            parted $disk_chk --script mkpart primary 131MiB 4227MiB
            parted $disk_chk --script name 3 swap
            parted $disk_chk --script -- mkpart primary 4227MiB -1
            parted $disk_chk --script name 4 rootfs
            parted $disk_chk --script set 2 boot on
            part_1=("${disk_chk}1")
            part_2=("${disk_chk}2")
            part_3=("${disk_chk}3")
            part_4=("${disk_chk}4")
            mkfs.fat -F 32 $part_2
            #mkfs.ext4 $part_2
            mkfs.ext4 $part_4
            mkswap $part_3
            swapon $part_3
            rm -rf devices
            clear
            sleep 2
            break
        elif [ "$auto_prov_ans" = "n" ]; then
            printf ${CYAN}"Enter the partition number for root (ex, 2 for /dev/sda2)\n>"
            read num
            rootpart="$disk$num"
            if grep "$rootpart" devices; then
                #continue running the script
                if [ $partition_count -gt 2 ]; then
                    printf "do you want to enable swap?\n>"
                    read swap_answer
                fi
                swap_answer="${swap_answer,,}"
                if [ "$swap_answer" = "no" ]; then
                    printf "not using swap"
                    part_3="no"
                else
                    while true; do
                        printf "enter swap partition (ex, /dev/sda3)\n>"
                        read part_3
                        part_3="${part_3,,}"
                        if grep "$part_3" devices; then
                            mkswap $part_3
                            swapon $part_3
                            break
                        else
                            printf${LIGHTRED}"%s is not a valid swap partition, review this list of your devices and make a valid selection\n" $part_3
                            printf ${WHITE}".\n"
                            sleep 5
                            clear
                            cat devices
                        fi
                    done
                fi
                printf ${LIGHTGREEN}"%s is valid :D continuing with the script\n" $rootpart
                break
            else
                #rootpartnotfound
                printf ${LIGHTRED}"%s is not a valid installation target, review this list of your devices and make a valid selection\n" $rootpart
                printf ${WHITE}".\n"
                sleep 5
                clear
            fi
        else
            printf ${LIGHTRED}"%s is an invalid answer, do it correctly" $auto_prov_ans
            printf ${WHITE}".\n"
            sleep 2
        fi
    else
        printf ${LIGHTRED}"%s is an invalid device, try again with a correct one\n" $disk_chk
        printf ${WHITE}".\n"
        sleep 5
        clear
        cat devices
    fi
done

printf "enter a number for the stage 3 you want to use\n"
printf "0 = regular\n1 = regular hardened\n2 = hardened musl\n3 = vanilla musl\n>"
read stage3select
printf ${CYAN}"Enter the username for your NON ROOT user\n>"
#There is a possibility this won't work since the handbook creates a user after rebooting and logging as root
read username
username="${username,,}"
printf ${CYAN}"Enter Yes to make a kernel from scratch, edit to edit the hardened config, or No to use the default hardened config\n>"
read kernelanswer
kernelanswer="${kernelanswer,,}"
printf ${CYAN}"Enter the Hostname you want to use\n>"
read hostname
printf ${CYAN}"Do you want to replace OpenSSL with LibreSSL (recommended) in your system?(yes or no)\n>"
read sslanswer
sslanswer="${sslanswer,,}"
printf ${CYAN}"Do you want to do performance optimizations. LTO -O3 and Graphite?(yes or no)\n>"
read performance_opts
performance_opts="${performance_opts,,}"
printf ${LIGHTGREEN}"Beginning installation, this will take several minutes\n"

#copying files into place
mount $part_4 /mnt/gentoo
mv deploygentoo-master /mnt/gentoo
mv deploygentoo-master.zip /mnt/gentoo/
mv network_devices /mnt/gentoo/deploygentoo-master/
cd /mnt/gentoo/deploygentoo-master

install_vars=/mnt/gentoo/deploygentoo-master/install_vars
cpus=$(grep -c ^processor /proc/cpuinfo)
pluscpus=$((cpus+1))
echo "$disk" >> "$install_vars"
echo "$username" >> "$install_vars"
echo "$kernelanswer" >> "$install_vars"
echo "$hostname" >> "$install_vars"
echo "$sslanswer" >> "$install_vars"
echo "$cpus" >> "$install_vars"
echo "$part_3" >> "$install_vars"
echo "$part_1" >> "$install_vars"
echo "$part_2" >> "$install_vars"
echo "$part_4" >> "$install_vars"
echo "$performance_opts" >> "$install_vars"
cat network_devices >> "$install_vars"
rm -f network_devices

case $stage3select in
  0)
    GENTOO_TYPE=latest-stage3-amd64
    ;;
  1)
    GENTOO_TYPE=latest-stage3-amd64-hardened
    ;;
  2)
    GENTOO_TYPE=latest-stage3-amd64-musl-hardened
    ;;
  3)
    GENTOO_TYPE=latest-stage3-amd64-musl-vanilla
    ;;
esac

STAGE3_PATH_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$GENTOO_TYPE.txt
STAGE3_PATH=$(curl -s $STAGE3_PATH_URL | grep -v "^#" | cut -d" " -f1)
STAGE3_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3_PATH
touch /mnt/gentoo/gentootype.txt
echo $GENTOO_TYPE >> /mnt/gentoo/gentootype.txt
cd /mnt/gentoo/
while [ 1 ]; do
	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 $STAGE3_URL
	if [ $? = 0 ]; then break; fi;
	sleep 1s;
done;
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
stage3=$(ls /mnt/gentoo/stage3*)
tar xpvf $stage3 --xattrs-include='*.*' --numeric-owner
printf "unpacked stage 3\n"

#rm -rf /mnt/gentoo/etc/portage
cd /mnt/gentoo/deploygentoo-master/gentoo/
cp -a /mnt/gentoo/deploygentoo-master/gentoo/portage/package.use/. /mnt/gentoo/etc/portage/package.use/
cd /mnt/gentoo/
rm -rf /mnt/gentoo/etc/portage/make.conf
##copies our pre-made make.conf over
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/make.conf /mnt/gentoo/etc/portage/
printf "copied new make.conf to /etc/portage/\n"
printf "there are %s cpus\n" $cpus
sed -i "s/MAKEOPTS=\"-j3\"/MAKEOPTS=\"-j$pluscpus -l$cpus\"/g" /mnt/gentoo/etc/portage/make.conf
sed -i "s/--jobs=3  --load-average=3/--jobs=$cpus  --load-average=$cpus/g" /mnt/gentoo/etc/portage/make.conf
printf "moved portage files into place\n"

#cp /mnt/gentoo/deploygentoo-master/gentoo/portage/linux_drivers /mnt/gentoo/etc/portage/
cp /mnt/gentoo/deploygentoo-master/gentoo/portage/package.license /mnt/gentoo/etc/portage
#cp /mnt/gentoo/deploygentoo-master/gentoo/portage/package.accept_keywords /mnt/gentoo/etc/portage/
#cp -r /mnt/gentoo/deploygentoo-master/gentoo/portage/profile /mnt/gentoo/etc/portage/

mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
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

cd /mnt/gentoo/
chroot /mnt/gentoo ./post_chroot.sh
