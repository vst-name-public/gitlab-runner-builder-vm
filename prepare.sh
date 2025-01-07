#!/bin/bash -eux
sudo apt update && sudo apt upgrade -y && sudo apt install -y \
    wget \
    curl \
    cloud-image-utils \
    genisoimage \
    qemu-kvm virt-manager \
    qemu-system-x86 \
    qemu-utils \
    libvirt-daemon-system \
    libvirt-clients \
    virtinst \
    bridge-utils \
    xorriso \
    gzip \
    xz-utils

sudo apt autoremove -y