#!/bin/bash
VERSION="0.0.2"
SCRIPT_DESCRIPTION="claims to give you chroot in a gentoo installation env."
SCRIPT_URL='https://raw.githubusercontent.com/muiraie/deploygentoo/master/GIVEME_CHROOT.sh'
STAGE3_URL='http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-hardened-openrc/stage3-amd64-hardened-openrc-20211114T170549Z.tar.xz'

# github link: https://github.com/muiraie/deploygentoo/
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

function readSelection {
    read -p "> " INPUT
    if [ $INPUT ]; then
        selection=$INPUT
    fi
}

function prompt {
    case $1 in
    [yY][eE][sS] | [yY])
        return 1
        ;;
    [nN][oO] | [nN])
        return 0
        ;;
    *)
        echo "Invalid input..."
        exit
        ;;
    esac
}

# stage 3
function download_stage3 {
    cd /mnt/gentoo/
    if [ ! -e /mnt/gentoo/stage3* ]; then
        while [ 1 ]; do
            wget -q --show-progress --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 $STAGE3_URL
            if [ $? = 0 ]; then break; fi
            sleep 1s
        done
        check_file_exists() {
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
    fi
    stage3=$(ls /mnt/gentoo/stage3*)

    archive="$stage3"
    # originalsize=$(file $archive | rev | cut -d' ' -f1 | rev)
    originalsize=$(stat --printf="%s" $archive)*4.7 # don't judge me. will patch when i sober up.
    step=100
    blocks=$(echo "$originalsize / 512 / 20 / $step" | bc)
    tar -xp --xattrs-include='*.*' --numeric-owner --checkpoint=$step --totals \
        --checkpoint-action="exec='p=\$(echo "\$TAR_CHECKPOINT/$blocks" | bc -l);printf \"%.4f%%\r\" \$p'" \
        -f $archive
    # tar xpvf $stage3 --xattrs-include='*.*' --numeric-owner

    printf "unpacked stage 3\n"

}

if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
    echo "We are chrooted! if the PS1 hadn't changed simply run source ~/.bashrc"
    source /etc/profile
    source ~/.bashrc
    echo "Good Luck!"
else
    echo "Business as usual."
    echo "This script should be run after partitioning."
    echo ""
    # swap?
    echo "are you using a swap partition? (y/n)"
    readSelection
    if ! prompt $INPUT; then
        echo "what's your swap's partition name? (e.g. sda3)"
        readSelection
        swapon "/dev/$INPUT"
    fi

    # root partition?
    echo "what's your root's partition name? (e.g. sda2)"
    readSelection
    mount "/dev/$INPUT" "/mnt/gentoo"

    # boot partition?
    echo "what's your boot partition's name? (e.g. sda1)"
    readSelection
    mount "/dev/$INPUT" "/mnt/gentoo/boot"

    echo "Did you want to download stage3?"
    readSelection
    if ! prompt $INPUT; then
        download_stage3
    fi
    # confirming
    find /mnt/gentoo/ -maxdepth 0 -empty -exec echo {} something went wrong. \;

    # moving forward
    mount --types proc /proc /mnt/gentoo/proc
    mount --rbind /sys /mnt/gentoo/sys
    mount --make-rslave /mnt/gentoo/sys
    mount --rbind /dev /mnt/gentoo/dev
    mount --make-rslave /mnt/gentoo/dev
    cp "${0}" "/mnt/gentoo/"
    cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
    cd /mnt/gentoo
    echo 'PS1="(chroot) ${PS1}"' >/mnt/gentoo/root/.bashrc
    echo "switching to chroot. You should re-run this script afterwards to check your chroot status and source a thing or two."
    echo -n "	Press Enter to continue. ctrl+C to escape"
    read
    chroot /mnt/gentoo /bin/bash && exit
fi

# EOF
