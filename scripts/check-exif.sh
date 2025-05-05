#!/bin/bash
# Usage:
#   ./scripts/check-exif.sh [--ci]
#   --ci    : output tabular summary for CI environments

echo "🔍 Checking for EXIF metadata in content images..."

CI_MODE=0

for arg in "$@"; do
  if [[ "$arg" == "--ci" ]]; then
    CI_MODE=1
  fi
done

HAS_EXIF=0
EXIF_FILES=()
while IFS= read -r file; do
  echo ""
  echo "🖼️  Scanning file: $file"
  METADATA=$(exiftool "$file")

  # Categories
  HIGH=$(echo "$METADATA" | grep -E 'GPS|Serial|Owner|Latitude|Longitude')
  MEDIUM=$(echo "$METADATA" | grep -E 'Make|Model|Software|Create Date|Modify Date')
  LOW=$(echo "$METADATA" | grep -E 'Image Width|Image Height|MIME Type|Encoding Process|Y Cb Cr Sub Sampling')

  if [[ -n "$HIGH" || -n "$MEDIUM" ]]; then
    HAS_EXIF=1
    EXIF_FILES+=("$file")

    if [[ "$CI_MODE" -eq 1 ]]; then
      echo "Level | Field | Value"
      echo "------|-------|------"
      echo "$HIGH" | sed 's/^\(.*\) *: */🔴 High | \1 | /'
      echo "$MEDIUM" | sed 's/^\(.*\) *: */🟠 Medium | \1 | /'
      echo "$LOW" | sed 's/^\(.*\) *: */🟢 Low | \1 | /'
    else
      [[ -n "$HIGH" ]] && echo "🔴 High Risk Metadata:" && echo "$HIGH"
      [[ -n "$MEDIUM" ]] && echo "🟠 Medium Risk Metadata:" && echo "$MEDIUM"
      [[ -n "$LOW" ]] && echo "🟢 Low Risk Metadata:" && echo "$LOW"
    fi
  else
    echo "✅ No significant EXIF metadata found."
  fi
done < <(find ./content -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \))

if [[ "$HAS_EXIF" -eq 1 ]]; then
  echo ""
  echo "🧹 Attempting to remove EXIF metadata from affected files..."

  while IFS= read -r file; do
    exiftool -all= -overwrite_original "$file" >/dev/null
  done < <(find ./content -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \))

  echo "❌ Commit blocked. EXIF metadata was removed. Please re-add any changed files and try again."
  exit 1
else
  echo "✅ No EXIF metadata found. Proceeding."
  exit 0
fi