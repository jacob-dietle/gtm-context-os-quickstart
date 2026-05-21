#!/usr/bin/env bash
# scan_stale_forks.sh — detect stale forks via similar directory names + diverging activity.
# Two directories with a shared prefix and very different last-commit timestamps = stale-fork signal.
#
# Usage: bash scan_stale_forks.sh [scope_root]

set -uo pipefail
SCOPE="${1:-apps}"

if [ ! -d "$SCOPE" ]; then
  echo "- Scope \`$SCOPE\` not found."
  exit 0
fi

# For each apps/* dir, capture (name, last_commit_unix_ts). Skip if not a git repo.
declare -A LAST_COMMIT
declare -A DIR_PATH

for dir in "$SCOPE"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  # Skip worktrees (names ending with .something, e.g. "foo.mcp-consolidation")
  case "$name" in *.*) continue;; esac

  if [ -d "$dir/.git" ] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    ts=$(git -C "$dir" log -1 --format=%ct 2>/dev/null)
    if [ -n "$ts" ]; then
      LAST_COMMIT["$name"]="$ts"
      DIR_PATH["$name"]="$dir"
    fi
  else
    # Not a git repo — treat via mtime of most recent file.
    ts=$(find "$dir" -maxdepth 2 -type f -printf '%T@\n' 2>/dev/null | sort -nr | head -1 | cut -d. -f1)
    if [ -n "$ts" ]; then
      LAST_COMMIT["$name"]="$ts"
      DIR_PATH["$name"]="$dir"
    fi
  fi
done

# Pair any two directories whose names share a prefix of 4+ chars.
names=("${!LAST_COMMIT[@]}")
found=0

for i in "${!names[@]}"; do
  for j in "${!names[@]}"; do
    [ "$i" -ge "$j" ] && continue
    a="${names[$i]}"
    b="${names[$j]}"

    # Compute shared prefix length.
    common=""
    min=${#a}; [ ${#b} -lt $min ] && min=${#b}
    for ((k=0; k<min; k++)); do
      ca="${a:$k:1}"
      cb="${b:$k:1}"
      [ "$ca" != "$cb" ] && break
      common+="$ca"
    done

    if [ ${#common} -ge 6 ]; then
      ta="${LAST_COMMIT[$a]}"
      tb="${LAST_COMMIT[$b]}"
      diff=$((ta > tb ? ta - tb : tb - ta))
      days=$((diff / 86400))

      # Flag if divergence > 60 days (one is clearly stale).
      if [ "$days" -gt 60 ]; then
        found=$((found + 1))
        newer="$a"; older="$b"
        if [ "$tb" -gt "$ta" ]; then newer="$b"; older="$a"; fi
        echo "### 🟡 Potential stale fork: \`$older\` vs \`$newer\`"
        echo "- Shared prefix: \`$common\` (${#common} chars)"
        echo "- Last activity diff: $days days"
        echo "- \`${DIR_PATH[$older]}\` → $(date -d @"${LAST_COMMIT[$older]}" +%Y-%m-%d 2>/dev/null || echo "ts=${LAST_COMMIT[$older]}")"
        echo "- \`${DIR_PATH[$newer]}\` → $(date -d @"${LAST_COMMIT[$newer]}" +%Y-%m-%d 2>/dev/null || echo "ts=${LAST_COMMIT[$newer]}")"
        echo ""
      fi
    fi
  done
done

if [ "$found" -eq 0 ]; then
  echo "- 🟢 No stale-fork pairs detected (no similarly-named dirs with >60 day activity divergence)."
fi
