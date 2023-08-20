#!/bin/bash
# https://blog.simos.info/running-x11-software-in-lxd-containers/
# https://discuss.linuxcontainers.org/t/audio-via-pulseaudio-inside-container/8768
# https://discuss.linuxcontainers.org/t/proxy-device-not-connecting-to-pulseaudio-on-lxd-host/7472

# Exit on error
set -e

# Check if there is a current DISPLAY
while [ -z $DISPLAY ]; do
  # Set default from who
  WHO_DISPLAY="$(who | cut -d "(" -f 2 | cut -d ")" -f 1)"
  # Ask in case non-default is desired
  read -p "Enter desired DISPLAY (default -> \"${WHO_DISPLAY}\"): " DISPLAY
  DISPLAY="{DISPLAY:-$WHO_DISPLAY}"
done

# Create Profile for LXC

lxc profile create x11

cat << EOF | lxc profile edit x11
config:
  environment.DISPLAY: $DISPLAY
  environment.PULSE_SERVER: unix:/home/ubuntu/pulse-native
  ### NVIDIA GPU ###
  ### all or compute, display, graphics, utility, video ###
  # nvidia.driver.capabilities: all
  # nvidia.runtime: "true"
  ### cloud-init ###
  cloud-init.user-data: |
    #cloud-config
    # package_upgrade: true
    runcmd:
      - 'sed -i "s/; enable-shm = yes/enable-shm = no/g" /etc/pulse/client.conf'
    packages:
      - x11-apps
      - mesa-utils
      - pulseaudio
      - firefox
    write_files:
      - owner: root:root
        permissions: '0644'
        append: true
        content: |
          PULSE_SERVER=unix:/home/ubuntu/pulse-native
        path: /etc/environment
description: Profile for X11
devices:
  ### Bind PulseAudio to Host ###
  PASocket1:
    bind: container
    connect: unix:/run/user/1000/pulse/native
    listen: unix:/home/ubuntu/pulse-native
    security.gid: "1000"
    security.uid: "1000"
    uid: "1000"
    gid: "1000"
    mode: "0777"
    type: proxy
  ### Bind X ###
  X0:
    bind: container
    ### @ == abstract Unix sockets == no actual file ###
    connect: unix:@/tmp/.X11-unix/X${DISPLAY#:}
    listen: unix:@/tmp/.X11-unix/X0
    security.gid: "1000"
    security.uid: "1000"
    type: proxy
  mygpu:
    type: gpu
    ### for raspi ###
    # gid: 44
name: x11
used_by: []
EOF

lxc launch ubuntu:22.04 --profile default --profile x11 x11-firefox

### Create Alias ###
echo 'alias LXFF="lxc exec x11-firefox -- sudo --user ubuntu --login --"' >> ~/.bashrc
source ~/.bashrc

# Wait for cloud-init to finish
while [ -n "$(lxc exec x11-firefox -- sudo --user ubuntu --login -- sh -c 'cloud-init status |grep running')" ];do init_string=${init_string}"..."; echo "Initialzing$init_string"; sleep 5; done; echo -e "\nfinished\n"


### Create Icon and add app to host ###
mkdir --parents ~/.local/share/icons/
# Image License: GPLv3 [original](https://commons.wikimedia.org/wiki/File:Tux_and_Firefox.png)
cp ./lxc-firefox.png ~/.local/share/icons/lxc-firefox.png
wget  https://upload.wikimedia.org/wikipedia/commons/4/42/Tux_and_Firefox.png

cat << EOF > ~/.local/share/applications/lxc-firefox.desktop
[Desktop Entry]
 Name=LXFF
 Comment=Firefox in LXC
 Exec=lxc exec x11-firefox -- sudo --user ubuntu --login firefox
 Icon=/home/${USER}/.local/share/icons/lxc-firefox.png
 Terminal=false
 Type=Application
 Categories=Game;
EOF

# Link to Desktop
ln -s ~/.local/share/applications/lxc-firefox.desktop ~/Desktop/lxc-firefox.desktop
# Make Executable
sudo chmod u+x ~/Desktop/lxc-firefox.desktop
