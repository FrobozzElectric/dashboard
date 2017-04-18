#!/bin/bash

set -e

# Check distro version and install packages
packages='sudo vim htop rxvt-unicode x11vnc chromium chromium-l10n xorg openbox unclutter xdotool figlet screen wmctrl'

if [ -z "$(grep "Debian GNU/Linux 8" /etc/issue)" ]; then 
    echo "This script was only written to run on Debian Jessie. Exiting..."
    exit 1
fi

su -c "apt-get update && apt-get install $packages -y && echo \"$USER    ALL=(ALL:ALL) ALL\" >> /etc/sudoers"

# This creates the .xsession file
echo '#!/bin/bash

get_ip() {
    ip addr | grep "inet " | grep -v "127.0.0.1" | cut -d" " -f6
}

echo $DISPLAY > ~/DISPLAY
xset s off
xset -dpms
x11vnc -q -nap -wait 30 -noxdamage -display $DISPLAY -forever -shared -nopw -o ~/vnc.log -bg
unclutter -idle 1 -jitter 2 -root &
ip=$(get_ip)
while [ -z $ip ]; do
    ip=$(get_ip)
done
hostname=$(hostname)
urxvt  -e bash -c "echo -e \"hostname: $hostname\\nip: $ip\" | figlet; bash" &
chromium-start
sleep 15 && xdotool search --onlyvisible --class "Chromium" windowfocus key F11 &
openbox-session' > ~/.xsession

# This adds to the .bashrc file
echo 'if [ -z "$SSH_CLIENT" ] || [ -z "$SSH_TTY" ]; then
    startx
fi' >> ~/.bashrc

# Make chromium-start and chromium-stop executables
echo '#!/bin/bash

export DISPLAY=$(<~/DISPLAY)
links=( $(cat ~/links-to-load.txt | grep -v ^#) )
screen -dm chromium \
    --kiosk-mode \
    --auto-launch-at-startup \
    --disable-hang-monitor \
    --disable-session-crashed-bubble \
    --disable-cache \
    --disable-canvas-aa \
    --default-tile-width=384 \
    --default-tile-height=384 \
    $( echo ${links[@]} )' > ~/chromium-start

echo '#!/bin/bash

export DISPLAY=$(<~/DISPLAY)
wmctrl -c chromium' > ~/chromium-stop

# This creates a default 'links-to-load.txt'. Add your own links!
echo 'https://www.google.com/' > ~/links-to-load.txt

# Install chromium-start and chromium-stop
chmod +x ~/chromium-start ~/chromium-stop
sudo mv ~/chromium-start ~/chromium-stop -t /usr/local/bin/

# Set auto-login for current user via systemd
sudo sed -i "s/ExecStart.*/ExecStart=-\/sbin\/agetty -a $USER %I $TERM/g" /etc/systemd/system/getty.target.wants/getty@tty1.service
sudo systemctl set-default multi-user.target
sudo reboot
