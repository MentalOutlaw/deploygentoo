#!/bin/bash
VERSION="0.0.1"
SCRIPT_DESCRIPTION="claims to give you chroot in a gentoo installation env."
SCRIPT_URL='https://raw.githubusercontent.com/muiraie/deploygentoo/master/GIVEME_CHROOT.sh'

# github link: https://github.com/muiraie/deploygentoo/
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# STRINGS
DIR="/mnt/"

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
        exit;
        ;;
    esac
}

if [ -d "$DIR" ]; then
    if [ "$(ls -A $DIR)" ]; then
        source /etc/profile
        export PS1="(chroot) ${PS1}"
        if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
            echo "We are chrooted!"
            echo "Good Luck!"
        else
            echo "Business as usual."
        fi
    else

        # swap?
        echo "are you using a swap partition? (y/n)"
        readSelection
        if prompt $INPUT; then
            echo "what's your swap's partition name? (e.g. sda3)"
            readSelection
            swapon "/dev/$INPUT"
        else
            echo "Nopes, moving on..."
        fi

        # root partition?
        echo "what's your root's partition name? (e.g. sda2)"
        readSelection
        mount "/dev/$INPUT" "/mnt/gentoo"

        # boot partition?
        echo "what's your boot partition's name? (e.g. sda1)"
        readSelection
        mount "/dev/$INPUT" "/mnt/gentoo/boot"

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
        cp /mnt/gentoo
        echo "switching to chroot. You should re-run this script afterwards."
        echo -n "	Press Enter to continue. ctrl+C to escape"
        read
        chroot /mnt/gentoo /bin/bash && exit
    fi
else
    echo "Something is seriously wrong x_x"
fi

# EOF
