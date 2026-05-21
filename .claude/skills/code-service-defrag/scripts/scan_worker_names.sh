#!/usr/bin/env bash
# scan_worker_names.sh — find duplicate Cloudflare Worker names across wrangler.toml files.
# Duplicates with identical bindings are the silent-overwrite landmine pattern.
#
# Usage: bash scan_worker_names.sh [scope_root]
# Output: markdown-formatted findings to stdout.

set -uo pipefail
SCOPE="${1:-apps}"

# Find all wrangler.toml files, skipping node_modules and .git.
mapfile -t FILES < <(find "$SCOPE" -name "wrangler.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "- No \`wrangler.toml\` files found in \`$SCOPE\`. Skipping worker name scan."
  exit 0
fi

echo "- Found ${#FILES[@]} wrangler.toml files in \`$SCOPE\`"
echo ""

# Build name → list-of-files map. Top-level 'name = "X"' only (ignore [env.X] name overrides).
declare -A NAME_FILES
for f in "${FILES[@]}"; do
  # Grab first 'name = "..."' line; skip commented lines and lines inside [env.*] blocks
  name=$(awk '
    /^\[/ { in_env = ($0 ~ /^\[env\./) ? 1 : 0 }
    !in_env && /^[[:space:]]*name[[:space:]]*=[[:space:]]*"/ {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "$f")
  if [ -n "$name" ]; then
    NAME_FILES["$name"]+="$f"$'\n'
  fi
done

# Report duplicates.
found_dupes=0
for name in "${!NAME_FILES[@]}"; do
  count=$(echo -n "${NAME_FILES[$name]}" | grep -c '^')
  if [ "$count" -gt 1 ]; then
    found_dupes=$((found_dupes + 1))
    echo "### 🔴 Worker name collision: \`$name\` ($count configs)"
    echo ""
    echo "${NAME_FILES[$name]}" | sed '/^$/d' | while IFS= read -r line; do
      echo "- \`$line\`"
    done
    echo ""
    echo "  **Risk:** \`wrangler deploy\` from any of these directories will overwrite the same worker. If bindings also match, production regresses silently."
    echo ""
  fi
done

if [ "$found_dupes" -eq 0 ]; then
  echo "- 🟢 No duplicate worker names detected."
fi
