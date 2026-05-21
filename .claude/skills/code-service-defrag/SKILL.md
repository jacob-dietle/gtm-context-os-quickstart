---
name: code-service-defrag
description: This skill should be used to periodically audit a multi-app/multi-service codebase for duplication, drift, and silent-overwrite landmines. Scans all `apps/*` directories (or equivalent) for duplicate Cloudflare Worker names, colliding D1/KV/R2/domain bindings, stale forks, ambiguous canonical-vs-archived status, and orphan repos. Produces a severity-ranked defrag report. Detect-only — does NOT auto-consolidate. Apply proactively on a monthly cadence (surfaced by `context-foundation` at session start), or reactively before any risky deploy, after a migration, or whenever canonical-source ambiguity is suspected. Core principle — agentic coding creates leverage at the cost of visibility, so drift accumulates silently until a `deploy` command hits the wrong codebase. Run defrag before the landmine fires, not after.
---

# Code + Service Defrag

Systematic audit of `apps/` for duplication, drift, and silent-overwrite landmines in a multi-service codebase where agents and humans both create and modify code.

## When to Apply This Skill

Apply when:
- **Periodic:** last defrag >30 days ago (surfaced by `context-foundation` at session start)
- **Pre-deploy:** before any `wrangler deploy`, `gh release`, or equivalent risky action on a shared account
- **Post-migration:** immediately after `git subtree add`, repo merge, directory move, or fork consolidation
- **Post-multi-agent work:** after `coordinated-agent-teams` execution — parallel agents create parallel fragments
- **On-demand:** when canonical-source ambiguity is suspected ("which one is the real one?")
- **On confusion:** when an agent or human catches themselves saying "I thought I deleted that" or "didn't we consolidate that?"

Do NOT apply when:
- Starting a greenfield project with no existing `apps/` directory
- Auditing knowledge base branches (use `kb-branch-audit` instead)
- Auditing a single app's internal structure (use `simplify` or `debugging-and-complexity-assessment`)
- Fixing is already planned and scoped — skip to `application-git-engineering`

## Core Principle

**Agentic coding creates leverage at the cost of visibility.** Sessions end with multiple codebases, forks, and deploy surfaces that nobody has a clear mental model of. Drift is silent until a wrong-directory `deploy` command fires. This skill codifies the scan that would have caught the landmine *before* it fired — the same scan that `epistemic-context-grounding` performs ad-hoc for one question, applied systematically to the entire deploy surface.

**Detect-only, never auto-fix.** Same philosophy as `kb-branch-audit` and `production-hardening`: the skill produces a severity-ranked report; the human decides what to consolidate and which downstream skill to invoke. Auto-fixing would re-introduce the cowboy problem this skill is built to prevent.

## Workflow

### Step 1: Establish Scan Scope

Default scope: `apps/*` in the current repo. Extend to sibling top-level directories (e.g., `services/`, `packages/`) only if they contain deployable units with their own configs.

Determine scope:
```bash
# List all app-like directories
ls -d apps/*/ 2>/dev/null

# Spot any siblings that look like deployable units
find . -maxdepth 3 -name "wrangler.toml" -o -name "fly.toml" -o -name "Dockerfile" 2>/dev/null | head -20
```

Confirm scope with the user if ambiguous.

### Step 2: Run the Full Defrag Scan

Execute the master scanner:
```bash
bash .claude/skills/code-service-defrag/scripts/defrag_scan.sh
```

The master scanner runs six sub-scans in order and aggregates findings:
1. `scan_worker_names.sh` — duplicate CF Worker names across configs
2. `scan_bindings.sh` — colliding D1 `database_id`, KV `id`, R2 bucket names, custom domain routes
3. `scan_archive_markers.sh` — directories with no explicit CANONICAL or ARCHIVED marker in their README
4. `scan_stale_forks.sh` — directories sharing similar names with divergent commit activity
5. `scan_spec_dirs.sh` — spec/context-packages drift: multiple `context_packages/` per project, empty convention dirs, legacy `_system/specs/`, orphan files at spec root, missing layout README
6. `scan_deploy_surface.sh` — enumeration of every location a deploy can fire from, with git remote

If a sub-scan fails or returns no output, that is a finding in itself — note it explicitly (e.g., "no `wrangler.toml` files found" is valid for a non-CF codebase).

### Step 3: Classify Findings by Severity

Every finding maps to one of three severities. Never ship a report without severity assignments.

| Severity | Meaning | Trigger |
|----------|---------|---------|
| 🔴 **Landmine** | A single `deploy` command could silently regress production | Duplicate worker names with identical bindings; duplicate D1 IDs; overlapping custom domain routes |
| 🟡 **Drift** | Ambiguity that will become a landmine if not resolved | No archive marker on an inactive directory; test count mismatch between similarly-named dirs; orphan repos (>90d no commits, no CI, no CLAUDE.md reference) |
| 🟢 **OK** | Expected state — explicit canonical or archived marker present, no collisions | Directory with clear README disposition; single config per worker name |

Consult `references/landmine-patterns.md` for the specific shapes that map to 🔴 (established from prior incidents).

### Step 4: Produce the Defrag Report

Write the report to `_system/reports/defrag_YYYY-MM-DD.md`. Structure it as:

```markdown
# Defrag Report — YYYY-MM-DD

## Scope
- Directories scanned: N
- Configs found: X wrangler.toml, Y package.json, Z Dockerfile

## Findings by Severity

### 🔴 Landmines (N)
1. **[finding title]** — [what collides, where, evidence]
   - Locations: `apps/foo/wrangler.toml:3`, `apps/bar/wrangler.toml:3`
   - Collision: `name = "worker-x"` + identical D1 `database_id`
   - Recommended downstream: `devops-architecture-perspectives` → `specification-driven-development` → `application-git-engineering`

### 🟡 Drift (N)
1. ...

### 🟢 OK (N)
- Listed without detail; report-only.

## Deploy Surface Inventory
| Location | Config | Target | Last deploy (inferred) |
| apps/foo/ | wrangler.toml | worker-x @ prod | ... |

## Recommended Next Actions
1. [highest-severity finding with specific skill handoff]
2. ...
```

Every finding MUST have:
- Specific file paths with line numbers
- Evidence (grep output, git log excerpt, or wrangler field values)
- A recommended downstream skill chain

### Step 5: Present to User + Hand Off

Show the report summary (counts by severity + top 3 landmines if any). Do NOT start consolidating — the user decides.

If 🔴 findings exist, recommend the standard consolidation chain:
```
devops-architecture-perspectives  (pick canonical)
    ↓
consequence-driven-design         (trace 2nd/3rd-order effects)
    ↓
specification-driven-development  (write consolidation spec)
    ↓
application-git-engineering       (execute migration)
    ↓
production-hardening              (verify safety before deploy)
    ↓
context-package                   (preserve the why)
```

If only 🟡 findings exist, recommend either deferring to next defrag or executing lightweight fixes (add archive marker, delete orphan, nothing structural).

### Step 6: Record the Run

Append one line to `_system/reports/defrag_log.md`:
```
YYYY-MM-DD | N scanned | L 🔴 / D 🟡 / O 🟢 | report: defrag_YYYY-MM-DD.md
```

This is the source-of-truth for "last defrag was X days ago" that `context-foundation` checks at session start.

## Bundled Resources

### Scripts (`scripts/`)

All scripts are bash, cross-platform (tested on git-bash/Windows), detect-only, and exit 0 on success with findings on stdout. None modify the filesystem.

- **`defrag_scan.sh`** — master orchestrator; runs all sub-scans and concatenates output
- **`scan_worker_names.sh`** — greps every `wrangler.toml` for `name = "X"`, reports duplicates
- **`scan_bindings.sh`** — reports duplicate D1 `database_id`, KV `id`, R2 bucket names, and custom domain routes across all configs
- **`scan_archive_markers.sh`** — for each `apps/*/`, checks README for explicit CANONICAL or ARCHIVED marker; flags ambiguous
- **`scan_stale_forks.sh`** — finds directories with similar base names + diverging last-commit timestamps (e.g., `foo/` vs `foo-v2/`)
- **`scan_spec_dirs.sh`** — detects context/docs drift per project: multiple `context_packages/` dirs, empty-except-README spec dirs (unused conventions), legacy `_system/specs/` staging areas, orphan `.md` files at `specs/` root, missing layout README. Context drift is as load-bearing as code drift — agents write the wrong spec to the wrong dir and fragment state
- **`scan_deploy_surface.sh`** — enumerates every `wrangler.toml` / `Dockerfile` / `fly.toml` with their worker names, targets, and git remote

Run individually for targeted investigation, or use `defrag_scan.sh` for the full pass.

### References (`references/`)

- **`landmine-patterns.md`** — the specific shapes of silent-overwrite landmines, with anonymized reproducing snippets and severity rules. Append new shapes as they are discovered.
- **`downstream-handoff.md`** — decision tree mapping finding types to skill chains. Used when a finding doesn't fit the default landmine-consolidation chain.
- **`cadence.md`** — when to run, what to expect, how "good" looks over time. Includes the 30-day freshness threshold `context-foundation` checks.

## Quality Gates

Before delivering the report:
- [ ] Every 🔴 finding has line-numbered evidence
- [ ] Every finding has a recommended downstream skill chain
- [ ] Deploy surface inventory is exhaustive (every place a deploy could fire)
- [ ] Report written to `_system/reports/defrag_YYYY-MM-DD.md`
- [ ] Log entry appended to `_system/reports/defrag_log.md`
- [ ] No auto-fix actions taken — detect-only respected

## Integration with Other Skills

### Upstream (skills that trigger defrag)

| Skill | Trigger condition |
|-------|-------------------|
| `context-foundation` | Session-start check: "last defrag >30d ago" |
| `epistemic-context-grounding` | Grounding surfaces "which one is canonical?" → systematic answer is defrag |
| `application-git-engineering` | Post-migration verification: "did we leave orphans?" |
| `coordinated-agent-teams` | After multi-agent work: "did parallel agents create fragments?" |
| `production-hardening` | Pre-deploy sanity check for deploy-surface ambiguity |

### Downstream (skills defrag hands off to when findings exist)

Standard landmine-consolidation chain (🔴):
```
defrag → devops-architecture-perspectives → consequence-driven-design →
specification-driven-development → application-git-engineering →
production-hardening → context-package
```

Lightweight drift cleanup (🟡):
```
defrag → application-git-engineering (add README marker, delete orphan)
```

### Siblings (same "audit before action" family)

- `kb-branch-audit` — same pattern applied to KB branches
- `context-os-maintenance` — CLAUDE.md surface audit
- `context-os-rebuild` — when drift is past the point of audit
- `production-hardening` — consumes defrag's deploy-surface inventory as input

