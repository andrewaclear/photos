SOURCE_DIR=${1%/}
DESTINATION_DIR=${2%/}

if [[ $SOURCE_DIR == "" || $DESTINATION_DIR == "" ]]; then
  echo "usage: ./photo-merge.sh SOURCE_DIR DESTINATION_DIR"
  echo "description: merge photos from SOURCE_DIR into DESTINATION_DIR"
  echo "  - moves photos to DESTINATION_DIR/{original-photo-name.type}"
  echo "  - detects duplicates and deletes source when destination is identical"
  echo "  - errors and stops if any steps fails"
  exit 1
fi

count=0

while IFS= read -r file; do

  new_file="${DESTINATION_DIR}${file#${SOURCE_DIR}}"

  if [[ -f "$new_file" ]]; then
    echo -n "removing file://${file} if it is the same, file://${new_file} exists "
    diff <(exiftool "$file" | grep -Ev "File|Directory") <(exiftool "$new_file" | grep -Ev "File|Directory") ||
      { echo -e "\nERROR: file exifs are not the same: file://${file} and file://${new_file}"; exit 1; }
    cmp -s "$file" "$new_file" ||
      { echo -e "\nERROR: files are not the same: file://${file} and file://${new_file}"; exit 1; }
    rm "$file" ||
      { echo -e "\nERROR: saved file://${new_file}, but could not delete the original file file://${file}"; exit 1; }
  else
    mv "$file" "$new_file" ||
      { echo "ERROR: failed to move file://${file} as file://${new_file}"; exit 1; }
    echo -n "file://${file} -> file://${new_file} "
  fi

  count=$(($count + 1))
  echo "🮱"
done <<< $(find "$SOURCE_DIR" -type f)

echo "successfully saved $count file(s)"
