#!/usr/bin/env bash
# scan_deploy_target_names.sh — find duplicate deploy-target names across any platform's config.
#
# First principle: a "deploy target" is the named unit a deploy command pushes to
# (CF Worker, Railway service, Vercel project, Fly app, Docker Compose service, npm package).
# Two configs declaring the SAME target name can point at the same live deployment —
# a deploy from either silently overwrites the other. Identical resource bindings make it certain.
#
# Detects names across: wrangler.toml, fly.toml, vercel.json, railway.json/railway.toml,
# render.yaml, docker-compose.yml, package.json (fallback).
#
# Usage: bash scan_deploy_target_names.sh [scope_root]
# Output: markdown-formatted findings to stdout.

set -uo pipefail
SCOPE="${1:-apps}"

declare -A NAME_FILES   # name -> newline-joined list of "file (platform)"
total=0

add() {  # add <name> <file> <platform>
  local name="$1" file="$2" platform="$3"
  [ -z "$name" ] && return
  NAME_FILES["$name"]+="$file ($platform)"$'\n'
  total=$((total + 1))
}

# --- Cloudflare Workers: top-level name (skip [env.*] overrides) ---
while IFS= read -r f; do
  name=$(awk '
    /^\[/ { in_env = ($0 ~ /^\[env\./) ? 1 : 0 }
    !in_env && /^[[:space:]]*name[[:space:]]*=[[:space:]]*"/ {
      match($0, /"[^"]+"/); print substr($0, RSTART+1, RLENGTH-2); exit
    }' "$f")
  add "$name" "$f" "cloudflare"
done < <(find "$SCOPE" -name "wrangler.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# --- Fly.io: app = "name" ---
while IFS= read -r f; do
  name=$(grep -E '^app[[:space:]]*=' "$f" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
  add "$name" "$f" "fly"
done < <(find "$SCOPE" -name "fly.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# --- Vercel / Railway (JSON): "name": "..." ---
while IFS= read -r f; do
  name=$(grep -E '"name"[[:space:]]*:' "$f" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]+)".*/\1/')
  platform=$([ "$(basename "$f")" = "vercel.json" ] && echo "vercel" || echo "railway")
  add "$name" "$f" "$platform"
done < <(find "$SCOPE" \( -name "vercel.json" -o -name "railway.json" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# --- Railway (TOML): name = "..." ---
while IFS= read -r f; do
  name=$(grep -E '^[[:space:]]*name[[:space:]]*=' "$f" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
  add "$name" "$f" "railway"
done < <(find "$SCOPE" -name "railway.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# --- Render: services with a name ---
while IFS= read -r f; do
  while IFS= read -r name; do
    add "$name" "$f" "render"
  done < <(grep -E '^[[:space:]]*-?[[:space:]]*name:' "$f" 2>/dev/null | sed -E 's/.*name:[[:space:]]*"?([^"#]+)"?.*/\1/' | sed 's/[[:space:]]*$//')
done < <(find "$SCOPE" -name "render.yaml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# --- Docker Compose: service keys under 'services:' ---
while IFS= read -r f; do
  while IFS= read -r name; do
    add "$name" "$f" "compose-service"
  done < <(awk '
    /^services:/ { in_svc=1; next }
    in_svc && /^[a-zA-Z]/ { in_svc=0 }            # left the services block
    in_svc && /^[[:space:]]{2}[a-zA-Z0-9._-]+:/ {
      gsub(/[[:space:]]|:/, ""); print
    }' "$f")
done < <(find "$SCOPE" \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

if [ "$total" -eq 0 ]; then
  echo "- No platform deploy configs found in \`$SCOPE\` (wrangler/fly/vercel/railway/render/compose). Skipping deploy-target name scan."
  exit 0
fi

echo "- Scanned $total deploy-target name declaration(s) across \`$SCOPE\`"
echo ""

found_dupes=0
for name in "${!NAME_FILES[@]}"; do
  block="${NAME_FILES[$name]}"
  count=$(echo -n "$block" | grep -c '^')
  [ "$count" -gt 1 ] || continue
  found_dupes=$((found_dupes + 1))

  # Determine which platform(s) the collision spans. Severity is platform-calibrated:
  #   cloudflare / fly  → 🔴  (target name is account/org-global; deploy overwrites silently, no protection)
  #   railway / render  → 🟡  (project-scoped; collision only real if same project — confirm)
  #   vercel            → 🟡  (the real key is the linked projectId, not the name field — confirm)
  #   compose           → 🟢  (service names are per-file/project-scoped; cross-file match usually coincidental)
  #   mixed platforms   → 🟢  (different namespaces; almost always coincidental)
  platforms=$(echo "$block" | sed -n 's/.*(\([a-z-]*\))$/\1/p' | sort -u)
  pcount=$(echo "$platforms" | sed '/^$/d' | wc -l | tr -d ' ')

  if [ "$pcount" -gt 1 ]; then
    sev="🟢"; note="Name appears across DIFFERENT platforms ($(echo $platforms | tr '\n' ' '))— separate namespaces, almost certainly coincidental. Verify, then ignore."
  else
    case "$platforms" in
      cloudflare|fly)
        sev="🔴"; note="$platforms target names are account/org-global. A deploy from any of these locations overwrites the same live deployment. If bindings also match → guaranteed silent prod regression." ;;
      railway|render)
        sev="🟡"; note="$platforms services are project-scoped. This is a landmine ONLY if these configs target the SAME project — confirm the linked project, then escalate to 🔴 or clear to 🟢." ;;
      vercel)
        sev="🟡"; note="Vercel's real deploy key is the linked projectId in .vercel/project.json, not the name field. Confirm whether these dirs link to the same project; if so → 🔴." ;;
      compose)
        sev="🟢"; note="Compose service names are scoped per-file/project. A cross-file name match is usually coincidental. The real Compose collision is a shared published port or named volume." ;;
      *)
        sev="🟡"; note="Unknown platform scoping — confirm whether these configs target the same deployment." ;;
    esac
  fi

  echo "### $sev Deploy-target name collision: \`$name\` ($count configs, platform: ${platforms:-?})"
  echo ""
  echo "$block" | sed '/^$/d' | while IFS= read -r line; do echo "- \`$line\`"; done
  echo ""
  echo "  **Severity rule:** $note"
  echo "  See \`references/platform-collision-semantics.md\` for the full calibration."
  echo ""
done

[ "$found_dupes" -eq 0 ] && echo "- 🟢 No duplicate deploy-target names detected."
