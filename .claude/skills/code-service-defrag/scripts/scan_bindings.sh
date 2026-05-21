#!/usr/bin/env bash
# scan_bindings.sh — detect colliding D1/KV/R2/domain bindings across configs.
# Two configs binding the same D1 database_id (or same custom domain route) is a landmine shape.
#
# Usage: bash scan_bindings.sh [scope_root]

set -uo pipefail
SCOPE="${1:-apps}"

mapfile -t FILES < <(find "$SCOPE" -name "wrangler.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "- No wrangler.toml files found. Skipping binding scan."
  exit 0
fi

# Emit "value<TAB>file" tuples for a given key, across all FILES.
extract_values() {
  local key="$1"
  for f in "${FILES[@]}"; do
    grep -E "^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"[^\"]+\"" "$f" 2>/dev/null \
      | while IFS= read -r line; do
          v=$(echo "$line" | sed -E 's/.*"([^"]+)".*/\1/')
          [ -n "$v" ] && printf '%s\t%s\n' "$v" "$f"
        done
  done
}

# Report duplicates given a "value<TAB>file" stream.
report_dupes() {
  local label="$1"
  local severity="$2"
  local stream="$3"

  [ -z "$stream" ] && { echo "- No $label bindings found."; return; }

  # Build list of values that appear 2+ times.
  local dupe_values
  dupe_values=$(echo "$stream" | awk -F'\t' '{print $1}' | sort | uniq -d)

  if [ -z "$dupe_values" ]; then
    echo "- 🟢 All $label bindings are unique."
    return
  fi

  # For each duplicate value, list all files that declare it.
  while IFS= read -r v; do
    [ -z "$v" ] && continue
    local count
    count=$(echo "$stream" | awk -F'\t' -v key="$v" '$1 == key' | wc -l)
    echo "### $severity $label collision: \`$v\` ($count configs)"
    echo "$stream" | awk -F'\t' -v key="$v" '$1 == key {print "- `" $2 "`"}'
    echo ""
  done <<< "$dupe_values"
}

echo "### D1 database_id collisions"
report_dupes "D1 database_id" "🔴" "$(extract_values "database_id")"
echo ""

echo "### KV / binding id collisions (coarse — may include non-KV ids)"
report_dupes "Binding id" "🟡" "$(extract_values "id")"
echo ""

echo "### R2 bucket_name collisions"
report_dupes "R2 bucket_name" "🟡" "$(extract_values "bucket_name")"
echo ""

echo "### Custom domain route collisions"
# Extract 'pattern = "..."' lines (CF custom domains).
route_stream=""
for f in "${FILES[@]}"; do
  while IFS= read -r r; do
    [ -n "$r" ] && route_stream+="$r	$f"$'\n'
  done < <(grep -E '^[[:space:]]*pattern[[:space:]]*=[[:space:]]*"[^"]+"' "$f" 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/')
done
report_dupes "Custom domain route" "🔴" "$route_stream"
