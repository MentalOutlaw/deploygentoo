#TODO add option to append -falign-functions=32 to CFLAGS if user has an Intel Processor
sed -i -e 's/CFLAGS=\"${COMMON_FLAGS}\"/CFLAGS=\"-march=native ${CFLAGS} -pipe\"/g' /etc/portage/make.conf
sed -i 's/CXXFLAGS=\"${COMMON_FLAGS}\"/CXXFLAGS=\"${CFLAGS}\"/g' /etc/portage/make.conf
#echo "NTHREADS=\"${cpus}\"" >> /etc/portage/make.conf
sed -i '5s/^/NTHREADS=\"${cpus}\"\n\n/' /etc/portage/make.conf
sed -i '6s/^/source make.conf.lto\n\n/' /etc/portage/make.conf
sed -i '11s/^/CPU_FLAGS_X86=\"aes avx avx2 f16c fma3 mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3\"' /etc/portage/make.conf
