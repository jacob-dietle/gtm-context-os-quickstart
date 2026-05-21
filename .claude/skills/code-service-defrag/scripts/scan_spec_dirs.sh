#!/usr/bin/env bash
# scan_spec_dirs.sh — detect spec/docs/context_packages drift within each project.
# Agentic coding creates context drift the same way it creates code drift:
# multiple specs/ dirs, competing context_packages/ locations, abandoned _system/
# variants, orphan files at spec root. Each is a 🟡 drift finding.
#
# Usage: bash scan_spec_dirs.sh [scope_root]

set -uo pipefail
SCOPE="${1:-apps}"

if [ ! -d "$SCOPE" ]; then
  echo "- Scope \`$SCOPE\` not found."
  exit 0
fi

# Iterate over each top-level project dir in scope.
total_projects=0
projects_with_findings=0

for project_dir in "$SCOPE"/*/; do
  [ -d "$project_dir" ] || continue
  total_projects=$((total_projects + 1))

  # Find all spec-like dirs inside the project (depth-limited to avoid node_modules).
  # We look for: specs/, context_packages/, _system/specs/ patterns.
  mapfile -t spec_dirs < <(find "$project_dir" -maxdepth 5 \
    -type d \( -name "specs" -o -name "context_packages" \) \
    -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort)

  [ "${#spec_dirs[@]}" -eq 0 ] && continue

  # Split by name: multiple `context_packages/` is drift; multiple `specs/` at different
  # levels is expected (top-level specs/ vs services/X/specs/) UNLESS two top-level specs/ dirs exist.
  context_pkg_count=0
  specs_count=0
  for d in "${spec_dirs[@]}"; do
    basename_d=$(basename "$d")
    case "$basename_d" in
      context_packages) context_pkg_count=$((context_pkg_count + 1)) ;;
      specs) specs_count=$((specs_count + 1)) ;;
    esac
  done

  project_findings=""

  # Finding 1: multiple context_packages/ dirs per project = drift
  if [ "$context_pkg_count" -gt 1 ]; then
    project_findings+="### 🟡 Multiple \`context_packages/\` in \`$project_dir\` ($context_pkg_count dirs)
"
    for d in "${spec_dirs[@]}"; do
      if [ "$(basename "$d")" = "context_packages" ]; then
        pkg_count=$(find "$d" -maxdepth 1 -name "*.md" -not -name "README.md" 2>/dev/null | wc -l)
        project_findings+="- \`${d%/}\` ($pkg_count packages)
"
      fi
    done
    project_findings+="  **Risk:** Parallel conventions fragment context. Future agents guess which is canonical; state drifts.
"
    project_findings+="
"
  fi

  # Finding 2: empty-except-README spec dirs (likely unused convention)
  for d in "${spec_dirs[@]}"; do
    total_files=$(find "$d" -maxdepth 1 -type f 2>/dev/null | wc -l)
    md_files=$(find "$d" -maxdepth 1 -name "*.md" -not -name "README.md" 2>/dev/null | wc -l)
    if [ "$total_files" -gt 0 ] && [ "$md_files" -eq 0 ]; then
      project_findings+="### 🟡 Empty spec dir: \`${d%/}\` (only README, no packages/specs)
"
      project_findings+="  **Risk:** Documented convention that was never adopted. Delete the dir or actually adopt the convention.
"
      project_findings+="
"
    fi
  done

  # Finding 3: _system/specs/ pattern (legacy staging area)
  if find "$project_dir" -maxdepth 5 -type d -path "*/_system/specs" -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
    project_findings+="### 🟡 Legacy \`_system/specs/\` pattern in \`$project_dir\`
"
    while IFS= read -r d; do
      file_count=$(find "$d" -maxdepth 1 -type f 2>/dev/null | wc -l)
      project_findings+="- \`${d%/}\` ($file_count files)
"
    done < <(find "$project_dir" -maxdepth 5 -type d -path "*/_system/specs" -not -path "*/node_modules/*" 2>/dev/null)
    project_findings+="  **Risk:** Orphan staging area from a deprecated convention. Move files into the main \`specs/\` dir.
"
    project_findings+="
"
  fi

  # Finding 4: orphan files directly in top-level specs/ (not under a subdir)
  top_specs="$project_dir/specs"
  if [ -d "$top_specs" ]; then
    mapfile -t orphans < <(find "$top_specs" -maxdepth 1 -type f -name "*.md" -not -name "README.md" 2>/dev/null)
    if [ "${#orphans[@]}" -gt 0 ]; then
      project_findings+="### 🟡 Orphan files in \`$top_specs/\` top level (${#orphans[@]} files)
"
      for f in "${orphans[@]}"; do
        project_findings+="- \`$f\`
"
      done
      project_findings+="  **Risk:** No clear owner. Move to \`specs/platform/sessions/\`, \`services/<name>/specs/\`, or a subdir that establishes scope.
"
      project_findings+="
"
    fi
  fi

  # Finding 5: no README in specs/ (convention undocumented)
  if [ -d "$top_specs" ] && [ ! -f "$top_specs/README.md" ]; then
    project_findings+="### 🟡 No README in \`$top_specs/\` (layout convention undocumented)
"
    project_findings+="  **Risk:** Future agents invent parallel conventions. Add a README listing where different spec types live.
"
    project_findings+="
"
  fi

  if [ -n "$project_findings" ]; then
    projects_with_findings=$((projects_with_findings + 1))
    echo "## Project: \`$project_dir\`"
    echo ""
    echo "$project_findings"
  fi
done

echo "---"
echo "**Summary:** $total_projects projects scanned, $projects_with_findings with spec-dir findings"

if [ "$projects_with_findings" -eq 0 ]; then
  echo "- 🟢 No spec-dir drift detected."
fi
