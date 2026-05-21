#!/usr/bin/env bash
# scan_deploy_surface.sh — inventory every place a deploy can fire from.
# Output feeds the defrag report AND production-hardening (which consumes the inventory).
#
# Usage: bash scan_deploy_surface.sh [scope_root]

set -uo pipefail
SCOPE="${1:-apps}"

if [ ! -d "$SCOPE" ]; then
  echo "- Scope \`$SCOPE\` not found."
  exit 0
fi

echo "| Location | Config | Worker/Service name | Custom domain | Git remote |"
echo "|----------|--------|---------------------|---------------|------------|"

# Cloudflare Workers — wrangler.toml
while IFS= read -r f; do
  dir=$(dirname "$f")
  name=$(awk '
    /^\[/ { in_env = ($0 ~ /^\[env\./) ? 1 : 0 }
    !in_env && /^[[:space:]]*name[[:space:]]*=[[:space:]]*"/ {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "$f")
  pattern=$(grep -E '^[[:space:]]*pattern[[:space:]]*=' "$f" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
  # Find enclosing git repo root and its remote.
  remote=$(git -C "$dir" config --get remote.origin.url 2>/dev/null || echo "-")
  printf '| `%s` | wrangler.toml | `%s` | `%s` | `%s` |\n' "$dir" "${name:-?}" "${pattern:-none}" "$remote"
done < <(find "$SCOPE" -name "wrangler.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# Fly.io — fly.toml
while IFS= read -r f; do
  dir=$(dirname "$f")
  name=$(grep -E '^app[[:space:]]*=' "$f" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
  remote=$(git -C "$dir" config --get remote.origin.url 2>/dev/null || echo "-")
  printf '| `%s` | fly.toml | `%s` | - | `%s` |\n' "$dir" "${name:-?}" "$remote"
done < <(find "$SCOPE" -name "fly.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# Docker — Dockerfile (implies container deploy; target unknown from file alone)
while IFS= read -r f; do
  dir=$(dirname "$f")
  remote=$(git -C "$dir" config --get remote.origin.url 2>/dev/null || echo "-")
  printf '| `%s` | Dockerfile | (container) | - | `%s` |\n' "$dir" "$remote"
done < <(find "$SCOPE" -name "Dockerfile" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# Vercel — vercel.json
while IFS= read -r f; do
  dir=$(dirname "$f")
  remote=$(git -C "$dir" config --get remote.origin.url 2>/dev/null || echo "-")
  printf '| `%s` | vercel.json | (vercel) | - | `%s` |\n' "$dir" "$remote"
done < <(find "$SCOPE" -name "vercel.json" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
