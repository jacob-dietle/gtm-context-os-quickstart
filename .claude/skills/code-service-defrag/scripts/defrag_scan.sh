#!/usr/bin/env bash
# defrag_scan.sh — master orchestrator for code-service-defrag skill.
# Runs all sub-scans sequentially, streams findings to stdout, never modifies state.
#
# Usage:
#   bash defrag_scan.sh [scope_root]
#
# scope_root defaults to "apps" relative to cwd. Pass a different dir if needed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCOPE="${1:-apps}"

if [ ! -d "$SCOPE" ]; then
  echo "ERROR: scope directory '$SCOPE' not found (run from repo root)"
  exit 2
fi

divider() { printf '\n%s\n' "================================================================"; }

echo "# Defrag Scan — $(date +%Y-%m-%d)"
echo "# Scope: $SCOPE"
echo "# Host: $(hostname 2>/dev/null || echo unknown)"

divider
echo "## 1. Deploy-target name collisions (CF / Railway / Vercel / Fly / Render / Compose)"
bash "$SCRIPT_DIR/scan_deploy_target_names.sh" "$SCOPE"

divider
echo "## 2. Binding collisions (shared datastore + CF D1/KV/R2/routes)"
bash "$SCRIPT_DIR/scan_bindings.sh" "$SCOPE"

divider
echo "## 3. Archive / canonical markers"
bash "$SCRIPT_DIR/scan_archive_markers.sh" "$SCOPE"

divider
echo "## 4. Stale fork detection (similar names, diverged activity)"
bash "$SCRIPT_DIR/scan_stale_forks.sh" "$SCOPE"

divider
echo "## 5. Spec directory drift (context/docs layout)"
bash "$SCRIPT_DIR/scan_spec_dirs.sh" "$SCOPE"

divider
echo "## 6. Deploy surface inventory"
bash "$SCRIPT_DIR/scan_deploy_surface.sh" "$SCOPE"

divider
echo "# Scan complete. Classify findings by severity (🔴 🟡 🟢) and write report to _system/reports/defrag_$(date +%Y-%m-%d).md"
