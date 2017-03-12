#!/bin/env bash

IMG="$1"

if [[ -e $IMG ]]; then
  P_START=$( fdisk -lu $IMG | grep Linux | awk '{print $2}' ) # Start of 1nd partition in 512 byte sectors
  P_SIZE=$(( $( fdisk -lu $IMG | grep Linux | awk '{print $3}' ) * 1024 )) # Partition size in bytes
  losetup /dev/loop1 $IMG -o $(($P_START * 512)) --sizelimit $P_SIZE
  fsck -f /dev/loop1
  resize2fs -M /dev/loop1 # Make the filesystem as small as possible
  fsck -f /dev/loop1
  P_NEWSIZE=$( dumpe2fs /dev/loop1 2>/dev/null | grep '^Block count:' | awk '{print $3}' ) # In 4k blocks
  P_NEWEND=$(( $P_START + ($P_NEWSIZE * 8) + 1 )) # in 512 byte sectors
  losetup -d /dev/loop1
  echo -e "p\nd\n1\nn\np\n1\n$P_START\n$P_NEWEND\np\nW\n" | fdisk $IMG
  I_SIZE=$((($P_NEWEND + 1) * 512)) # New image size in bytes
  truncate -s $I_SIZE $IMG else
  echo "Usage: $0 filename"
fi
