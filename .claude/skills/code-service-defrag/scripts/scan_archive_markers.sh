#!/usr/bin/env bash
# scan_archive_markers.sh — flag directories without explicit CANONICAL or ARCHIVED markers.
# Every apps/* directory should have a README that says unambiguously what it is.
# Absence of a marker = drift candidate.
#
# Usage: bash scan_archive_markers.sh [scope_root]

set -uo pipefail
SCOPE="${1:-apps}"

if [ ! -d "$SCOPE" ]; then
  echo "- Scope \`$SCOPE\` not found."
  exit 0
fi

# Markers we treat as valid explicit dispositions.
MARKERS=("ARCHIVED" "DEPRECATED" "MIGRATED" "CANONICAL" "DO NOT DEPLOY")

missing=0
flagged=0
total=0

for dir in "$SCOPE"/*/; do
  [ -d "$dir" ] || continue
  total=$((total + 1))

  # Look for a readme at common capitalizations.
  readme=""
  for candidate in README.md README.MD Readme.md readme.md; do
    if [ -f "$dir$candidate" ]; then
      readme="$dir$candidate"
      break
    fi
  done

  if [ -z "$readme" ]; then
    echo "- 🟡 \`$dir\` — no README.md (disposition unknown)"
    missing=$((missing + 1))
    continue
  fi

  # Check first 30 lines for any disposition marker.
  head -n 30 "$readme" > /tmp/_defrag_readme_head.$$ 2>/dev/null
  found_marker=""
  for m in "${MARKERS[@]}"; do
    if grep -q -i "$m" /tmp/_defrag_readme_head.$$; then
      found_marker="$m"
      break
    fi
  done
  rm -f /tmp/_defrag_readme_head.$$

  if [ -n "$found_marker" ]; then
    echo "- 🟢 \`$dir\` — marker: \`$found_marker\`"
  else
    echo "- 🟡 \`$dir\` — README present but no explicit disposition marker in first 30 lines"
    flagged=$((flagged + 1))
  fi
done

echo ""
echo "**Summary:** $total dirs scanned, $missing missing README, $flagged README without marker"
