#!/bin/bash

SOURCE_DIR=${1%/}
DESTINATION_DIR=${2%/}

if [[ $SOURCE_DIR == "" || $DESTINATION_DIR == "" ]]; then
  echo "usage: ./photos-move.sh SOURCE_DIR DESTINATION_DIR"
  echo "description: sort photos from SOURCE_DIR into DESTINATION_DIR"
  echo "  - moves photos to DESTINATION_DIR/{YYYY}/{MM}/{YYYY-MM-DD-hhmmss}_{original-photo-name.type}"
  echo "  - detects duplicates and deletes source when destination is identical"
  echo "  - errors and stops if any steps fails"
  exit 1
fi

count=0

while IFS= read -r file; do
  [[ -f $file ]] || continue
  unset found_file
  base=$(basename "$file")
  date=$(exiftool -s -s -s -d "%Y-%m-%d-%H%M%S" -DateTimeOriginal -CreateDate -FileModifyDate "$file" | grep -Ev "0000-|0000:" | head -n 1)
  [[ $date == "" ]] &&
    { echo "ERROR: failed to get date from exif of file://${file}"; exit 1; }

  year=$(echo $date | cut -d '-' -f 1)
  month=$(echo $date | cut -d '-' -f 2)
  [[ -d "${DESTINATION_DIR}/${year}" ]] || mkdir "${DESTINATION_DIR}/${year}"
  [[ -d "${DESTINATION_DIR}/${year}/${month}" ]] || mkdir "${DESTINATION_DIR}/${year}/${month}"

  new_file="${DESTINATION_DIR}/${year}/${month}/${date}_${base}"
  if [[ $(find "${DESTINATION_DIR}/${year}/${month}" -type f -name "${date}*") ]]; then
    while IFS= read -r duplicate_file; do
      [[ -f $duplicate_file ]] || continue
      diff <(exiftool "$file" | grep -Ev "File|Directory") <(exiftool "$duplicate_file" | grep -Ev "File|Directory") > /dev/null || continue 
      cmp -s "$file" "$duplicate_file" > /dev/null || continue
      rm "$file" ||
        { echo -e "\nERROR: saved file://${duplicate_file}, but could not delete the original file file://${file}"; exit 1; }
      echo -n "removed file://${file}, it is the same as file://${duplicate_file} "
      found_file=true
      break
    done <<< $(echo $new_file; find "${DESTINATION_DIR}/${year}/${month}" -type f -name "${date}*")
  fi
  if [[ ! $found_file ]]; then
    if [[ ! -f $new_file ]]; then
      mv -n "$file" "$new_file" ||
        { echo "ERROR: failed to move file://${file} as file://${new_file}"; exit 1; }
      echo -n "file://${file} -> file://${new_file} "
    else
      diff <(exiftool "$file" | grep -Ev "File|Directory") <(exiftool "$new_file" | grep -Ev "File|Directory")
      cmp -s "$file" "$new_file"
      echo -e "\nERROR: files are not the same: file://${file} and file://${new_file}"
      exit 1;
    fi
  fi

  count=$(($count + 1))
  echo "🮱"
done <<< $(find "$SOURCE_DIR" -type f)

echo "successfully saved $count file(s)"
