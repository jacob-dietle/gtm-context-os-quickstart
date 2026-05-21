---
name: code-service-defrag
description: This skill should be used to periodically audit a multi-app/multi-service codebase for duplication, drift, and silent-overwrite landmines — on any deploy platform (Cloudflare, Railway, Vercel, Fly, Render, Docker Compose). Scans for duplicate deploy-target names, colliding shared-resource bindings (shared databases, datastores, domains, CF D1/KV/R2), stale forks, ambiguous canonical-vs-archived status, and spec/context drift. Produces a severity-ranked report. Detect-only — does NOT auto-consolidate. Apply proactively on a monthly cadence, or reactively before any risky deploy, after a migration, or whenever canonical-source ambiguity is suspected. Core principle — agentic coding creates leverage at the cost of visibility, so drift accumulates silently until a deploy command hits the wrong target.
---

# Code + Service Defrag

Systematic audit of a multi-service codebase for duplication, drift, and silent-overwrite landmines — where agents and humans both create and modify code faster than anyone maintains a mental model of it.

## The First Principle

**Any system with multiple deployable units accumulates collision risk: two things that can silently overwrite or corrupt each other.** The platform changes the vocabulary, not the problem.

| Universal concept | Cloudflare | Railway | Vercel | Fly | Docker Compose |
|---|---|---|---|---|---|
| **Deploy target** (what a deploy pushes to) | Worker name | Service name | Project name | App name | Compose service |
| **Shared datastore** (silent corruption risk) | D1 `database_id` | `DATABASE_URL` / Postgres | Linked DB | attached Postgres | named volume / DB service |
| **Domain claim** (exclusive, last-writer-wins) | route `pattern` | service domain | project domain | `[[services]]` | published port |
| **Deploy config** | `wrangler.toml` | `railway.json/toml` | `vercel.json` | `fly.toml` | `docker-compose.yml` |

The landmine is always the same shape: **two configs name the same target, or bind the same shared resource, and a deploy from the wrong directory clobbers production.** This skill scans for that shape across every platform present in the repo.

## When to Apply This Skill

Apply when:
- **Periodic:** last defrag >30 days ago
- **Pre-deploy:** before any `deploy` / `push` / `release` on a shared account
- **Post-migration:** immediately after a repo merge, `git subtree add`, directory move, or fork consolidation
- **Post-multi-agent work:** after parallel agents create parallel fragments
- **On-demand:** when canonical-source ambiguity is suspected ("which one is the real one?")
- **On confusion:** when someone catches themselves saying "I thought I deleted that" or "didn't we consolidate that?"

Do NOT apply when:
- Starting a greenfield project with no existing multi-service layout
- Auditing knowledge base branches (use a KB-specific audit instead)
- Auditing a single app's internal structure (use a general code-review/simplify pass)
- Fixing is already planned and scoped — skip to the migration step

## Core Principle

**Agentic coding creates leverage at the cost of visibility.** Sessions end with multiple codebases, forks, and deploy surfaces that nobody has a clear mental model of. Drift is silent until a wrong-directory deploy fires. This skill codifies the scan that would have caught the landmine *before* it fired.

**Detect-only, never auto-fix.** The skill produces a severity-ranked report; the human decides what to consolidate. Auto-fixing would re-introduce the cowboy problem this skill is built to prevent.

## Workflow

### Step 1: Establish Scan Scope

Default scope: `apps/*` (or `services/`, `packages/`) in the current repo — any directory holding deployable units with their own configs.

```bash
# List app-like directories
ls -d apps/*/ services/*/ packages/*/ 2>/dev/null

# Spot deployable units across platforms
find . -maxdepth 3 \( -name "wrangler.toml" -o -name "railway.json" -o -name "railway.toml" \
  -o -name "vercel.json" -o -name "fly.toml" -o -name "render.yaml" \
  -o -name "docker-compose.yml" -o -name "Dockerfile" \) -not -path "*/node_modules/*" 2>/dev/null
```

Confirm scope with the user if ambiguous.

### Step 2: Run the Full Defrag Scan

```bash
bash .claude/skills/code-service-defrag/scripts/defrag_scan.sh [scope_root]
```

The master scanner runs six sub-scans and aggregates findings:
1. `scan_deploy_target_names.sh` — duplicate deploy-target names across CF / Railway / Vercel / Fly / Render / Compose configs
2. `scan_bindings.sh` — shared-datastore collisions (Postgres/Supabase/MySQL/`DATABASE_URL`) + CF D1/KV/R2/route collisions
3. `scan_archive_markers.sh` — directories with no explicit CANONICAL or ARCHIVED marker in their README
4. `scan_stale_forks.sh` — directories sharing similar names with divergent commit activity
5. `scan_spec_dirs.sh` — spec/context-package drift (parallel conventions, orphan files, legacy staging dirs)
6. `scan_deploy_surface.sh` — enumeration of every location a deploy can fire from, with git remote

If a sub-scan returns no output, that is a finding in itself — note it explicitly (e.g., "no platform configs found" is valid for a library-only repo).

### Step 3: Classify Findings by Severity

| Severity | Meaning | Trigger |
|----------|---------|---------|
| 🔴 **Landmine** | A single deploy could silently regress production | Duplicate deploy-target names with identical bindings; duplicate datastore bindings on prod; overlapping domain claims |
| 🟡 **Drift** | Ambiguity that will become a landmine if not resolved | Same datastore referenced from multiple services; no archive marker on an inactive directory; stale fork; spec drift |
| 🟢 **OK** | Expected state — explicit marker, no collisions | Directory with clear README disposition; single config per target name |

Consult `references/landmine-patterns.md` for the specific shapes that map to each severity.

### Step 4: Produce the Defrag Report

Write the report to `_system/reports/defrag_YYYY-MM-DD.md` (or wherever the repo keeps reports). Structure:

```markdown
# Defrag Report — YYYY-MM-DD

## Scope
- Directories scanned: N
- Configs found: X by platform

## Findings by Severity
### 🔴 Landmines (N)
1. **[finding title]** — [what collides, where, evidence]
   - Locations: `apps/foo/<config>:3`, `apps/bar/<config>:3`
   - Collision: same deploy-target name + same datastore binding
   - Recommended downstream: pick canonical → write consolidation plan → migrate → verify

### 🟡 Drift (N)
### 🟢 OK (N)

## Deploy Surface Inventory
| Location | Config | Target | Domain | Git remote |

## Recommended Next Actions
```

Every finding MUST have: specific file paths with line numbers, evidence, and a recommended next step.

### Step 5: Present to User + Hand Off

Show the report summary (counts by severity + top 3 landmines if any). Do NOT start consolidating — the user decides.

If 🔴 findings exist, the standard consolidation sequence is:
```
pick canonical → trace 2nd/3rd-order effects → write consolidation spec →
execute migration (preserve history) → verify safety before deploy → record the why
```

If only 🟡 findings exist, either defer to the next defrag or execute lightweight fixes (add archive marker, delete orphan, document the intentional shared datastore).

### Step 6: Record the Run

Append one line to a defrag log so "last defrag was X days ago" is answerable:
```
YYYY-MM-DD | N scanned | L 🔴 / D 🟡 / O 🟢 | report: defrag_YYYY-MM-DD.md
```

## Bundled Resources

### Scripts (`scripts/`)

All scripts are bash, detect-only, exit 0 on success with findings on stdout. None modify the filesystem. None print credentials (the datastore scan reads only host/identifier portions of connection strings, never passwords).

- **`defrag_scan.sh`** — master orchestrator; runs all sub-scans and concatenates output
- **`scan_deploy_target_names.sh`** — duplicate deploy-target names across all supported platforms
- **`scan_bindings.sh`** — shared-datastore collisions (any stack) + CF D1/KV/R2/route collisions
- **`scan_archive_markers.sh`** — for each app dir, checks README for explicit CANONICAL or ARCHIVED marker
- **`scan_stale_forks.sh`** — directories with similar base names + diverging last-commit timestamps
- **`scan_spec_dirs.sh`** — context/docs drift: parallel `context_packages/` dirs, empty convention dirs, legacy staging dirs, orphan spec files
- **`scan_deploy_surface.sh`** — enumerates every deploy config (CF/Fly/Docker/Vercel/Railway/Render/Compose) with target name and git remote

Run individually for targeted investigation, or use `defrag_scan.sh` for the full pass.

### References (`references/`)

- **`landmine-patterns.md`** — the specific shapes of silent-overwrite landmines, with anonymized reproducing snippets and severity rules. Patterns are stated platform-agnostically with per-platform examples.
- **`downstream-handoff.md`** — decision tree mapping finding types to remediation chains.
- **`cadence.md`** — when to run, what to expect, how "good" looks over time.

## Quality Gates

Before delivering the report:
- [ ] Every 🔴 finding has line-numbered evidence
- [ ] Every finding has a recommended next step
- [ ] Deploy surface inventory is exhaustive (every place a deploy could fire)
- [ ] Report written to disk
- [ ] Log entry appended
- [ ] No auto-fix actions taken — detect-only respected

## Adapting to Your Stack

The scanners already cover Cloudflare, Railway, Vercel, Fly, Render, and Docker Compose. To add a platform:
1. Teach `scan_deploy_target_names.sh` how to extract the target name from that platform's config
2. Teach `scan_bindings.sh` the platform's shared-resource identifiers (if any beyond the generic datastore scan)
3. Add the config filename to `scan_deploy_surface.sh`

The directory-level scanners (`scan_archive_markers.sh`, `scan_stale_forks.sh`, `scan_spec_dirs.sh`) are already platform-agnostic — they reason about directories, READMEs, and git history, not deploy configs.
