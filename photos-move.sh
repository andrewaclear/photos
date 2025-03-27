SOURCE_DIR=${1%/}
DESTINATION_DIR=${2%/}

if [[ $SOURCE_DIR == "" || $DESTINATION_DIR == "" ]]; then
  echo "usage: ./photo-move.sh SOURCE_DIR DESTINATION_DIR"
  echo "description: sort photos from SOURCE_DIR into DESTINATION_DIR"
  echo "  - moves photos to DESTINATION_DIR/{year}/{month}/{date}_{original-photo-name.type}"
  echo "  - detects duplicates and deletes source when destination is identical"
  echo "  - errors and stops if any steps fails"
  exit 1
fi

count=0

while IFS= read -r file; do
  base=$(basename "$file")
  date=$(exiftool -s -s -s -d "%Y-%m-%d-%H%M%S" -DateTimeOriginal -CreateDate -FileModifyDate "$file" | grep -Ev "0000-|0000:" | head -n 1)
  [[ $date == "" ]] &&
    { echo "ERROR: failed to get date from exif of file://${file}"; exit 1; }

  year=$(echo $date | cut -d '-' -f 1)
  month=$(echo $date | cut -d '-' -f 2)
  [[ -d ${DESTINATION_DIR}/${year} ]] || mkdir ${DESTINATION_DIR}/${year}
  [[ -d ${DESTINATION_DIR}/${year}/${month} ]] || mkdir ${DESTINATION_DIR}/${year}/${month}

  new_file="${DESTINATION_DIR}/${year}/${month}/${date}_${base}"
  if [[ -f "$new_file" ]]; then
    echo -n "removing file://${file} if it is the same, file://${new_file} exists "
    diff <(exiftool "$file" | grep -Ev "File|Directory") <(exiftool "$new_file" | grep -Ev "File|Directory") ||
      { echo -e "\nERROR: file exifs are not the same: file://${file} and file://${new_file}"; exit 1; }
    cmp -s "$file" "$new_file" ||
      { echo -e "\nERROR: files are not the same: file://${file} and file://${new_file}"; exit 1; }
    rm "$file" ||
      { echo -e "\nERROR: saved file://${new_file}, but could not delete the original file file://${file}"; exit 1; }
  else
    mv -n "$file" "$new_file" ||
      { echo "ERROR: failed to move file://${file} as file://${new_file}"; exit 1; }
    echo -n "file://${file} -> file://${new_file} "
  fi

  count=$(($count + 1))
  echo "🮱"
done <<< $(find $SOURCE_DIR -type f)

echo "successfully saved $count file(s)"
