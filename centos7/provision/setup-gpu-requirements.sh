#!/usr/bin/env bash

function setup() {
  sudo yum update -y

  cat <<EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

  echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee -a /etc/default/grub
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
}

setup