printf ${LIGHTBLUE}"Enter the device name you want to install gentoo on (ex, sda for /dev/sda)\n>"
read disk
partition_count="$(grep -o $disk devices | wc -l)"
echo "$partition_count"
