#!/usr/bin/env bash

set -euo pipefail

CONTENT_DIR="./content"
permalink_keys=()
permalink_values=()
DUPLICATES=()

slugify() {
  echo "$1" | sed -E 's/\.[^.]+$//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9\/-]//g'
}

resolve_permalink() {
  local file="$1"
  local slug url dir relative

  slug=$(awk '/^slug:/ { print $2; exit }' "$file")
  url=$(awk '/^url:/ { print $2; exit }' "$file")

  if [[ -n "$url" ]]; then
    echo "$url" | sed 's/^\///'
  elif [[ -n "$slug" ]]; then
    dir=$(dirname "${file#$CONTENT_DIR/}")
    echo "$dir/$slug"
  else
    relative="${file#$CONTENT_DIR/}"
    echo "${relative%/index.md}" | sed 's/\.md$//'
  fi
}

echo "🔎 Checking for permalink/slug uniqueness..."

while IFS= read -r -d '' file; do
  permalink=$(resolve_permalink "$file")
  normalized=$(slugify "$permalink")

  found=0
  for i in "${!permalink_keys[@]}"; do
    if [[ "${permalink_keys[$i]}" == "$normalized" ]]; then
      echo "❌ Duplicate permalink: /$normalized"
      echo "   - ${permalink_values[$i]}"
      echo "   - $file"
      DUPLICATES+=("$normalized")
      found=1
      break
    fi
  done

  if [[ $found -eq 0 ]]; then
    permalink_keys+=("$normalized")
    permalink_values+=("$file")
  fi

done < <(find "$CONTENT_DIR" -type f -name '*.md' -print0)

if [[ ${#DUPLICATES[@]} -gt 0 ]]; then
  echo -e "\n🚫 Found ${#DUPLICATES[@]} duplicate permalink(s). Failing build."
  exit 1
fi

echo "✅ All permalinks are unique."
exit 0
