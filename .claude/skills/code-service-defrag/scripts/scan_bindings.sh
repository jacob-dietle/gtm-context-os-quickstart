#!/usr/bin/env bash
# scan_bindings.sh — detect colliding shared-resource bindings across configs, any platform.
#
# First principle: when two deploy targets bind the SAME shared resource (database, store,
# domain, queue), a change or deploy to one can corrupt or displace the other. The classic
# landmine is two services pointed at the same production datastore without knowing it.
#
# Platform-agnostic datastore scan (Postgres/Supabase/MySQL connection targets, DATABASE_URL)
# PLUS Cloudflare-specific bindings (D1 database_id, KV id, R2 bucket, custom-domain routes)
# when wrangler.toml files are present.
#
# Reads only HOST/identifier portions of connection strings — never prints credentials.
#
# Usage: bash scan_bindings.sh [scope_root]

set -uo pipefail
SCOPE="${1:-apps}"

# report_dupes <label> <severity> <"value<TAB>file" stream>
report_dupes() {
  local label="$1" severity="$2" stream="$3"
  [ -z "$stream" ] && { echo "- No $label found."; return; }
  local dupe_values
  dupe_values=$(echo "$stream" | awk -F'\t' '{print $1}' | sort | uniq -d)
  if [ -z "$dupe_values" ]; then
    echo "- 🟢 All $label are unique."
    return
  fi
  while IFS= read -r v; do
    [ -z "$v" ] && continue
    local count; count=$(echo "$stream" | awk -F'\t' -v key="$v" '$1 == key' | wc -l | tr -d ' ')
    echo "### $severity $label collision: \`$v\` ($count references)"
    echo "$stream" | awk -F'\t' -v key="$v" '$1 == key {print "- `" $2 "`"}' | sort -u
    echo ""
  done <<< "$dupe_values"
}

# ============================================================
# GENERIC: shared datastore references (works for any stack)
# ============================================================
echo "### Shared datastore collisions (Postgres / Supabase / MySQL / DATABASE_URL)"

# Scan committed config + env-template files. Extract the datastore IDENTITY (host/ref/db),
# never the password. Same datastore referenced from 2+ dirs = worth surfacing.
mapfile -t ENVFILES < <(find "$SCOPE" \
  \( -name ".env" -o -name ".env.*" -o -name "*.toml" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

ds_stream=""
for f in "${ENVFILES[@]}"; do
  # Supabase project ref: https://<ref>.supabase.co  (the <ref> is the project identity)
  while IFS= read -r ref; do
    [ -n "$ref" ] && ds_stream+="supabase:$ref	$(dirname "$f")"$'\n'
  done < <(grep -oiE 'https://[a-z0-9]+\.supabase\.co' "$f" 2>/dev/null | sed -E 's#https://([a-z0-9]+)\.supabase\.co#\1#i' | sort -u)

  # Postgres/MySQL connection: capture host[:port]/db, strip any user:pass@ prefix.
  while IFS= read -r conn; do
    [ -n "$conn" ] && ds_stream+="db:$conn	$(dirname "$f")"$'\n'
  done < <(grep -oiE '(postgres(ql)?|mysql)://[^"'"'"' ]+' "$f" 2>/dev/null \
            | sed -E 's#^[a-z]+://([^@/]*@)?#${proto}#I; s#^\$\{proto\}##' \
            | sed -E 's#\?.*$##' | sort -u)
done
report_dupes "shared datastore" "🟡" "$(echo "$ds_stream" | sed '/^$/d')"
echo ""

# ============================================================
# CLOUDFLARE-SPECIFIC (only if wrangler.toml present)
# ============================================================
mapfile -t WRANGLER < <(find "$SCOPE" -name "wrangler.toml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
if [ "${#WRANGLER[@]}" -eq 0 ]; then
  echo "- (No wrangler.toml found — skipping Cloudflare D1/KV/R2/route binding scan.)"
  exit 0
fi

extract_values() {  # extract_values <key>
  local key="$1" f line v
  for f in "${WRANGLER[@]}"; do
    grep -E "^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"[^\"]+\"" "$f" 2>/dev/null \
      | while IFS= read -r line; do
          v=$(echo "$line" | sed -E 's/.*"([^"]+)".*/\1/')
          [ -n "$v" ] && printf '%s\t%s\n' "$v" "$f"
        done
  done
}

echo "### D1 database_id collisions"
report_dupes "D1 database_id" "🔴" "$(extract_values "database_id")"
echo ""
echo "### KV / binding id collisions (coarse — may include non-KV ids)"
report_dupes "binding id" "🟡" "$(extract_values "id")"
echo ""
echo "### R2 bucket_name collisions"
report_dupes "R2 bucket_name" "🟡" "$(extract_values "bucket_name")"
echo ""
echo "### Custom domain route collisions"
route_stream=""
for f in "${WRANGLER[@]}"; do
  while IFS= read -r r; do
    [ -n "$r" ] && route_stream+="$r	$f"$'\n'
  done < <(grep -E '^[[:space:]]*pattern[[:space:]]*=[[:space:]]*"[^"]+"' "$f" 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/')
done
report_dupes "custom domain route" "🔴" "$route_stream"
