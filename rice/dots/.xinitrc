# Uncomment to load xresources file
# xrdb -merge ~/.Xresources &

slstatus &
#dwmstatus 2>&1 >/dev/null &

# Uncomment and edit to set the wallpaper.
# feh --bg-fill ~/Pictures/Mountains.jpg

# Hides the mouse cursor after 3 seconds of inactivity
unclutter -idle 3 &
xrdb .Xresources &
./.setres.sh &
# Saving a dwm log
exec dwm > ~/.dwm.log
