#this gets alsa working
modprobe snd-intel8x0
#This lets us have a non-root Xorg
chmod 4711 /usr/bin/Xorg
