#!/bin/sh

# GVFS_PATH=/run/user/$UID/gvfs

# DEVICE="$(ls $GVFS_PATH | grep afc)"
# echo -e "$DEVICE\n"
# if [[ $(echo "$DEVICE" | wc -l) > 1 ]]; then
#   echo "too many devices connected, remove other devices"
#   exit 1
# fi

# SOURCE_DIR="$GVFS_PATH/$DEVICE"

IPHONE=~/iPhone
mkdir -p $IPHONE
idevicepair pair || exit 1
ifuse $IPHONE

echo "reset photos database? (y/N)"
read -n 1 answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  echo "resetting iphone photos database..."
  backup=reset-iphone-photos-backup_$(date +%s%N)
  mkdir $backup
  cp $IPHONE/PhotoData/Photos* $backup
  rm $IPHONE/PhotoData/Photos*
fi

fusermount -u $IPHONE
