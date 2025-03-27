# photos

> author: Andrew D'Amario © 2025

Custom scripts designed to download photos with reliability, efficiency, and ease.

Primary features are:
- sorting downloaded photos into structure file path and helpful naming: `DESTINATION_DIR/{YYYY}/{MM}/{YYYY-MM-DD-hhmmss}_{original-photo-name.type}`
- verifies successful download by verifying no diff in file attributes and byte comparison before deleting source
- preservation of file attributes and timestamps
- detects duplicates and deletes source when destination is identical
- errors and stops if any steps fails

With these features you not only get a fully sorted archive separated by year and month, you also get fully organized files by date and time up to the second the photo was taken `YYYY-MM-DD-hhmmss`. Moreover, you don't have to worry if the script gets cut midway or if you halt it yourself. Since the source only gets deleted after precise comparison of the file attributes and bytes with the destination, a partial download will just be detected after restarting up the script. If the cut download was successful it will proceed to delete the source. If it wasn't, it will error to you that the destination is not the same as the source and you will have to remove the faulty target file yourself and restart the script. In the same way, if two files happen to have the same name and time stamp (up to the second) it will stop and error that the destination is different from the source. You will have to open both files and change the existing one's name in the destination to allow the script to copy the other one and continue.

## dependencies

Required commands:
- `exiftool` exif tool, install from repository
  - ARCH install: `sudo pacman -S perl-image-exiftool`

Also uses standard linux commands: `cp`, `diff`, `cmp`, `rm`, `basename`, and `cut`.

## usage

### `./photo.sh`

`./photo.sh` performs the strict validation process before deleting. It is designed for downloading from a mobile device that could be disconnected midway, where assurance of successful download before deleting the source is required. Run this when downloading your devices.

```sh
usage: ./photo.sh SOURCE_DIR DESTINATION_DIR
```

**description:** download photos from mobile device `SOURCE_DIR` into `DESTINATION_DIR`
- saves photos to `DESTINATION_DIR/{YYYY}/{MM}/{YYYY-MM-DD-hhmmss}_{original-photo-name.type}`
- verifies successful download before deleting source
- detects duplicates and deletes source when destination is identical
- errors and stops if any steps fails

### `./photo-move.sh`

`./photo-move.sh` does not perform the script validation process before moving. It is designed for sorting already downloaded photos into a new archive path that will have the nice year and month file structure with the updated date and time naming. Run this on your current photo directories to nicely sort everything into the new file structure.

```sh
usage: ./photo-move.sh SOURCE_DIR DESTINATION_DIR
```

**description:** sort photos from `SOURCE_DIR` into `DESTINATION_DIR`
- moves photos to `DESTINATION_DIR/{YYYY}/{MM}/{YYYY-MM-DD-hhmmss}_{original-photo-name.type}`
- detects duplicates and deletes source when destination is identical
- errors and stops if any steps fails

### `./photo-merge.sh`

`./photo-merge.sh` does not apply the year and month file path structure on the destination nor the validation process. It is designed to detect duplicates across the two directories and merge as much as possible. Run this on directories you have already sorted but may have duplicates among themselves.

```sh
usage: ./photo-merge.sh SOURCE_DIR DESTINATION_DIR
```

**description:** merge photos from `SOURCE_DIR` into `DESTINATION_DIR`
- moves photos to `DESTINATION_DIR/{original-photo-name.type}`
- detects duplicates and deletes source when destination is identical
- errors and stops if any steps fails

## example

Mount your mobile device through the UI with nautilus gvfs. Copy the device's photo folder and set it as the SOURCE_DIR. Copy your archive path and set it as the DESTINATION_DIR. For example:

```sh
./photo.sh /run/user/1000/gvfs/afc:host=00000000-0000000000000000/DCIM /run/media/username/MyPassport/photos
```

The out will look like this:

```log
file:///run/user/1000/gvfs/afc:host=00000000-0000000000000000/DCIM/100APPLE/IMG_3042.MOV -> file:///run/media/username/MyPassport/photos/2025/01/2025-01-05-024221_IMG_3042.MOV 🮱
```

This is means that `IMG_3042.MOV` has been downloaded to the archive with new name `2025-01-05-024221_IMG_3042.MOV`. `🮱` appears after the attribute and diff has been verified and the source deleted, i.e. the download complete.

When the destination exists you will see:

```log
removing file:///run/user/1000/gvfs/afc:host=00000000-0000000000000000/DCIM/100APPLE/IMG_4053.JPG if it is the same, file:///run/media/username/MyPassport/photos/2024/12/2024-12-14-183110_IMG_4053.JPG exists 
```

If the verification passes, you will see `🮱` appear and the script will continue.

If you get an error at any point during the process you will see something like this and the script will stop instantaneously so you can investigate before proceeding:

```log
ERROR: files are not the same: file:///run/user/1000/gvfs/afc:host=00000000-0000000000000000/DCIM/100APPLE/IMG_4053.JPG and file:///run/media/username/MyPassport/photos/2024/12/2024-12-14-183110_IMG_4053.JPG
```
