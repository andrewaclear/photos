#!/bin/sh

DESTINATION_DIRS=${1}
SOURCE_DIR=${2}

if [[ ( $DESTINATION_DIRS == "" ) ]]; then
  echo ""
  echo "usage: ./download.sh DESTINATION_DIRS(=destination_1[,destination_2,...] [SOURCE_DIR])"
  echo ""
  echo "description: download photos from connected mobile device into each comma separated DESTINATION_DIRS"
  echo "  - for each of the DESTINATION_DIRS, saves photos to {destination}/{YYYY}/{MM}/{YYYY-MM-DD-hhmmss}_{original-photo-name.type}"
  echo "  - verifies successful download before deleting source"
  echo "  - detects duplicates and deletes source when destination is identical"
  echo "  - errors and stops if any steps fails"
  echo "  - if SOURCE_DIR is specified, download from there and do attempt to connect to device"
  echo ""
  exit 1
fi

if [[ ! $SOURCE_DIR ]]; then

  devices="$(gphoto2 --auto-detect | tail -n +3)"
  echo -e "$devices\n"
  if [[ $(echo "$devices" | wc -l) > 1 ]]; then
    echo "too many camera devices connected, remove other devices"
    exit 1
  fi

  GVFS_PATH=/run/user/$UID/gvfs
  CAMERA="$(ls $GVFS_PATH | grep gphoto2)"

  # mount camera if it is not
  unset MOUNTED
  if [[ ! "$CAMERA" ]]; then
    echo "mounting camera..."
    USB_PORT="$(echo "$devices" | cut -d ':' -f 2 | sed 's/[[:space:]]//g')"
    gio mount "gphoto2://[usb:${USB_PORT}]/"
    CAMERA="$(ls $GVFS_PATH | grep gphoto2)"
    if [[ ! $CAMERA ]]; then
      echo "failed to mount camera!"
      exit 1
    fi
    MOUNTED=true
  fi

  SOURCE_DIR="$GVFS_PATH/$CAMERA"

fi

for folder in $(ls "$SOURCE_DIR"); do
  echo "downloading "${SOURCE_DIR}/$folder". .."
  /home/development/projects/photos/photos.sh download ${SOURCE_DIR}/$folder $DESTINATION_DIRS || exit 1
  echo "going to next folder..."
  sleep 3
done

if [[ $MOUNTED == true ]]; then
  echo "unmounting iPhone..."
  read
  gio mount -u "gphoto2://[usb:${USB_PORT}]/"
fi

echo "done!"
