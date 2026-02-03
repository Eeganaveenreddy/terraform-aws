#!/bin/bash
set -eux

MOUNT="/data"

# Find the 250G disk dynamically
DEVICE=$(lsblk -dn -o NAME,SIZE | awk '$2 ~ /250G/ {print "/dev/"$1}')

while [ -z "$DEVICE" ]; do
  sleep 3
  DEVICE=$(lsblk -dn -o NAME,SIZE | awk '$2 ~ /250G/ {print "/dev/"$1}')
done

blkid $DEVICE || mkfs.ext4 $DEVICE

mkdir -p $MOUNT
mount $DEVICE $MOUNT
echo "$DEVICE $MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab
