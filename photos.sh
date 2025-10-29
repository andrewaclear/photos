#!/bin/sh

MODE=$1
SOURCE_DIR=${2%/}
DESTINATION_DIRS=${3}

# DEFAULTS
MAX_PARALLEL_OPS=${MAX_PARALLEL_OPS:-$(nproc)}
ERROR_FILE=${ERROR_FILE:-$HOME/photos_error_file}

if [[ ( $MODE != "download" && $MODE != "move" ) || $SOURCE_DIR == "" || $DESTINATION_DIRS == "" || ( "${DESTINATION_DIRS%%,*}" != "$DESTINATION_DIRS" && $MODE == "move" ) ]]; then
  echo ""
  echo "usage: ./photos.sh MODE(=download|move) SOURCE_DIR DESTINATION_DIRS(=destination_1[,destination_2,...])"
  echo ""
  echo "description: download photos from mobile device SOURCE_DIR into each comma separated DESTINATION_DIRS (note: only one destination is permitted in 'move' MODE)"
  echo "  - for each of the DESTINATION_DIRS, saves photos to {destination}/{YYYY}/{MM}/{YYYY-MM-DD-hhmmss}_{original-photo-name.type}"
  echo "  - 'download' MODE verifies successful download before deleting source, 'move' MODE does not"
  echo "  - detects duplicates and deletes source when destination is identical"
  echo "  - errors and stops if any steps fails"
  echo ""
  exit 1
fi

function download() {
  local file=$1
  local new_file=$2
  local out=""
  cp -a "$file" "$new_file" ||
    { echo "ERROR: failed to save file://${file} as file://${new_file}" >> $ERROR_FILE; exit 1; }
  local out=$out$(echo -n "  🡢 file://${new_file} ")
  diff <(exiftool "$file" | grep -Ev "File|Directory") <(exiftool "$new_file" | grep -Ev "File|Directory") ||
    { echo "ERROR: file exifs are not the same: file://${file} and file://${new_file}" >> $ERROR_FILE; exit 1; }
  cmp -s "$file" "$new_file" ||
    { echo "ERROR: files are not the same: file://${file} and file://${new_file}" >> $ERROR_FILE; exit 1; }
  local out=$out$(echo "✓")
  echo -e "$out"
}

function move() {
  local file=$1
  local new_file=$2
  local out=""
  mv -n "$file" "$new_file" ||
    { echo "ERROR: failed to move file://${file} as file://${new_file}" >> $ERROR_FILE; exit 1; }
  local out=$out$(echo "  🡢 file://${new_file} ✓")
  echo -e "$out"
}

function save() {
  local file=$1
  local out=$2
  local name=$(basename "$file")
  local base="${name#*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]_}"
  local date=$(exiftool -s -s -s -d "%Y-%m-%d-%H%M%S" -DateTimeOriginal -CreateDate -FileModifyDate "$file" | grep -Ev "0000-|0000:" | head -n 1)
  [[ $date == "" ]] &&
    { echo "ERROR: failed to get date from exif of file://${file}" >> $ERROR_FILE; exit 1; }

  local year=$(echo $date | cut -d '-' -f 1)
  local month=$(echo $date | cut -d '-' -f 2)

  while IFS= read -r destination; do
    local destination="${destination%/}"
    [[ -d "${destination}/${year}" ]] || mkdir "${destination}/${year}"
    [[ -d "${destination}/${year}/${month}" ]] || mkdir "${destination}/${year}/${month}"

    local new_file="${destination}/${year}/${month}/${date}_${base}"
    if [[ $(find "${destination}/${year}/${month}" -type f -name "${date}*") ]]; then
      while IFS= read -r duplicate_file; do
        [[ -f $duplicate_file ]] || continue
        diff <(exiftool "$file" | grep -Ev "File|Directory") <(exiftool "$duplicate_file" | grep -Ev "File|Directory") > /dev/null || continue
        cmp -s "$file" "$duplicate_file" > /dev/null || continue
        local out=$out$(echo "  🡤 file://${duplicate_file} is the same, skipping")
        local found_file=true
        break
      done <<< $(echo $new_file; find "${destination}/${year}/${month}" -type f -name "${date}*")
    fi
    if [[ ! $found_file ]]; then
      if [[ ! -f $new_file ]]; then
        local out=$out$($MODE)
      else
        diff <(exiftool "$file" | grep -Ev "File|Directory") <(exiftool "$new_file" | grep -Ev "File|Directory")
        cmp "$file" "$new_file"
        echo "ERROR: files are not the same: file://${file} and file://${new_file}" >> $ERROR_FILE
        exit 1;
      fi
    fi
  done <<< $(echo "$DESTINATION_DIRS" | sed 's/,/\n/g')

  if [[ $MODE == "download" || $found_file ]]; then
    local out=$out$(echo -n "  𐄂 removing original ")
    rm "$file" ||
      { echo "ERROR: saved file://${new_file}, but could not delete the original file file://${file}" >> $ERROR_FILE; exit 1; }
    local out=$out$(echo "✓")
  fi

  echo -e "$out"
}

function track-parallel() {
  # check if there are any errors
  if [[ -f $ERROR_FILE ]]; then
    # wait for current running jobs to finish
    wait
    # print out errors and reset error file
    cat $ERROR_FILE
    rm $ERROR_FILE
    # stop
    exit 1
  fi
  # assure to not exceed max parallel operations
  if [[ $(jobs | wc -l) > $MAX_PARALLEL_OPS ]]; then
    wait -n
  fi
}

count=0
total=$(find "$SOURCE_DIR" -type f | wc -l)

while IFS= read -r file; do
  [[ -f $file ]] || continue
  count=$(($count + 1))

  current_file="file://${file}"
  progress="[${count}/${total}]"
  columns=$(tput cols)
  N=$(( columns - ${#current_file} - ${#progress} ))
  local out=$(printf "${current_file}%${N}s${progress}\n")

  save $file "$out" &
  track-parallel  
done <<< $(find "$SOURCE_DIR" -type f)

echo "successfully saved $count/$total file(s)"
