#    Below here is where to modify
#    emerge --oneshot --quiet sys-devel/gcc
#    gcc-config 2
#    emerge --oneshot --usepkg=n --quiet sys-devel/libtool
#    yes | layman -a mv
#    yes | layman -a lto-overlay
#    layman -S
#    emerge --autounmask-continue app-text/texlive
#    emerge -q dev-libs/isl
#    git clone https://github.com/periscop/cloog
#    cd cloog
#    GET_SUBMODULES="/cloog/get_submodules.sh"
#    . "$GET_SUBMODULES"
#    AUTOGEN="/cloog/autogen.sh"
#    . "$AUTOGEN"
#    CONFIG="/cloog/configure"
#    bash "$CONFIG"
#    make && make install
#    #TODO create a more sophisticated way to figure out the latest version of these ebuilds
ebuild /var/lib/layman/lto-overlay/sys-config/ltoize/ltoize-0.9.7.ebuild manifest
ebuild /var/lib/layman/lto-overlay/app-portage/lto-rebuild/lto-rebuild-0.9.8.ebuild manifest
#ebuild /var/lib/layman/lto-overlay/dev-lang/python/python-3.9.0_beta5-r1.ebuild manifest
ebuild /var/lib/layman/lto-overlay/dev-lang/python/python-3.8.5-r1.ebuild manifest
ebuild /var/lib/layman/lto-overlay/dev-lang/python/python-3.7.8-r3.ebuild manifest
ebuild /var/lib/layman/lto-overlay/dev-lang/python/python-2.7.18-r100.ebuild manifest
ebuild /var/lib/layman/mv/app-portage/eix/eix-0.34.4.ebuild manifest
ebuild /var/lib/layman/mv/app-shells/push/push-3.3.ebuild manifest
ebuild /var/lib/layman/mv/app-shells/quoter/quoter-4.2.ebuild manifest
ebuild /var/lib/layman/mv/app-text/lesspipe/lesspipe-1.85_alpha20200517.ebuild manifest
ebuild /var/lib/layman/mv/sys-apps/less/less-563.ebuild manifest
ebuild /var/lib/layman/mv/virtual/man/man-0-r3.ebuild manifest
ebuild /var/lib/layman/mv/app-portage/portage-bashrc-mv/portage-bashrc-mv-20.1.ebuild manifest
ebuild /var/lib/layman/mv/virtual/freedesktop-icon-theme/freedesktop-icon-theme-0-r3.ebuild manifest
ebuild /var/lib/layman/mv/app-shells/runtitle/runtitle-2.11.ebuild manifest
emerge -q sys-config/ltoize
emerge -q =app-shells/runtitle-2.11::mv
emerge -q =virtual/freedesktop-icon-theme-0-r3::mv
emerge -q =app-portage/portage-bashrc-mv-20.1::mv
emerge -q =app-portage/eix-0.34.4::mv
emerge -q =app-shells/push-3.3::mv
emerge -q =app-shells/quoter-4.2::mv
emerge -q =app-text/lesspipe-1.85_alpha20200517::mv
emerge -q =sys-apps/less-563::mv
emerge -q =virtual/man-0-r3::mv
emerge -q =app-portage/lto-rebuild.0.9.8::lto-overlay
#emerge -q =dev-lang/python-3.9.0_beta5-r1::lto-overlay
emerge -q =dev-lang/python-3.8.5-r1::lto-overlay
emerge -q =dev-lang/python-3.7.8-r3::lto-overlay
emerge -q =dev-lang/python-2.7.18-r100::lto-overlay
#TODO add option to append -falign-functions=32 to CFLAGS if user has an Intel Processor
sed -i 's/^CFLAGS=\"${COMMON_FLAGS}\"/CFLAGS=\"-march=native ${CFLAGS} -pipe\"/g' /etc/portage/make.conf
sed -i 's/CXXFLAGS=\"${COMMON_FLAGS}\"/CXXFLAGS=\"${CFLAGS}\"/g' /etc/portage/make.conf
sed -i '5s/^/NTHREADS=\"$cpus\"\n/' /etc/portage/make.conf
sed -i '6s/^/source make.conf.lto\n\n/' /etc/portage/make.conf
sed -i '11s/^/LDFLAGS=\"${CFLAGS} -fuse-linker-plugin\"\n/' /etc/portage/make.conf
sed -i '12s/^/CPU_FLAGS_X86=\"aes avx avx2 f16c fma3 mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3\"\n/' /etc/portage/make.conf
sed -i '15s/^/ACCEPT_KEYWORDS=\"~amd64\"\n/' /etc/portage/make.conf
sed -i 's/-quicktime/-quicktime lto/g' /etc/portage/make.conf
sed -i 's/-clamav/-clamav graphite/g' /etc/portage/make.conf
emerge gcc
emerge -e @world
printf "performance enhancements setup, you'll have to emerge sys-config/ltoize to complete\n"
