#!/usr/bin/env bash

set -euo pipefail

echo "🔎 Checking frontmatter metadata in content files..."

CONTENT_DIR="./content"
INVALID_FILES=()
WARNING_FILES=()

for file in $(find "$CONTENT_DIR" -name "*.md"); do
  # Check for YAML frontmatter delimiters
  if ! head -n 1 "$file" | grep -q '^---'; then
    echo "❌ Missing frontmatter delimiter in $file"
    INVALID_FILES+=("$file")
    continue
  fi

  # Extract frontmatter block only
  frontmatter=$(awk '/^---/ { if (++c == 2) exit; next } c == 1 { print }' "$file")

  if ! grep -q '^title:' <<< "$frontmatter"; then
    echo "❌ Missing 'title' in $file"
    INVALID_FILES+=("$file")
  fi

  if ! grep -q '^date:' <<< "$frontmatter"; then
    echo "❌ Missing 'date' in $file"
    INVALID_FILES+=("$file")
  fi

  if grep -q '^draft: *true' <<< "$frontmatter"; then
    echo "⚠️  Draft still true in $file"
    WARNING_FILES+=("$file")
  fi
done

echo

if [ "${#INVALID_FILES[@]}" -ne 0 ]; then
  echo "🚫 Metadata check failed. ${#INVALID_FILES[@]} file(s) are missing required fields."
  exit 1
fi

echo "✅ All content files have required frontmatter metadata."

if [ "${#WARNING_FILES[@]}" -ne 0 ]; then
  echo "⚠️  ${#WARNING_FILES[@]} draft content file(s) found (not failing build):"
  for f in "${WARNING_FILES[@]}"; do
    echo "   - $f"
  done
fi
