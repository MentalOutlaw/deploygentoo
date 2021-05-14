this is a gentoo deployment script created by mental outlaw
PREREQUISITES
This script can be run from a live CD or a live OS, you can download this script from there using links or wget
1. Run setup_gentoo.sh it will prompt you to provision your disk, or you can auto provision using my recommended format
2. The script is going to prompt you to answer several questions to configure your installation(LibreSSL Replacement, LTO Optimizations, kernel editing, and platform selection).  After this the script will setup your system for you (it takes several minutes or hours depending on your hardware.  This is Gentoo, so everything is compiled!)
3. When this finishes you'll have a working gentoo linstallation with my minimal kernel config and use flags, exit the chroot, remove the live cd and reboot.
4. From here you could go on and customize gentoo to your liking, or deploy my included "rice" (gui configuration and dotfiles) with sudo deploy_rice.sh. Currently I use urxvt, dwm, slstatus, pcmanfm, zsh, bash, and vim.
5. You can also run install_software.sh to install a list of software that I use on gentoo.

TODOs
continued testing for LTO & Graphite optimizations, this script pulls in the Gentoo LTO Overlay https://github.com/InBetweenNames/gentooLTO which itself is still in the works, things may or may not compile correctly as changes are added to that overlay
Add a browser that supports LTO & LibreSSL, earlier builds of firefox worked with this setup, but it has not been supported for several versions now.
Deprecate Libressl functionality (No further attempts are being made to integrate LibreSSL into Gentoo, and LibreSSL has been all but abandoned by distro devs in general)
