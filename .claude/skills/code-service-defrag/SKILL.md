---
name: code-service-defrag
description: This skill should be used to periodically defragment a multi-app/multi-service codebase — both CODE (duplicate deploy targets, colliding bindings, stale forks) and CONTEXT (parallel spec conventions, orphan docs, scattered context packages) — on any platform (Cloudflare, Railway, Vercel, Fly, Render, Docker Compose). Converts the vague "things are getting messy" feeling into specific, located, severity-ranked findings. Detect-only — does NOT auto-consolidate. Apply on a monthly cadence, before any risky deploy, after a migration, or whenever canonical-source ambiguity is suspected. Core principle — agentic coding fragments state faster than humans consolidate it, so drift accumulates silently until a deploy fires from the wrong place or an agent onboards from the wrong context.
---

# Code + Service Defrag

Periodic consolidation of a fragmenting codebase — code AND context — back into coherent, single-source-of-truth wholes. The maintenance discipline that counteracts the entropy agentic coding produces.

**Meta-Principle:** *Agentic coding fragments state faster than humans consolidate it.* Fragmentation only accumulates — it is the second law applied to repos. Defrag is the periodic counter-force. Run it on a cadence, or discover the fragmentation the day a deploy fires from the wrong directory.

## Why Fragmentation Is Inevitable (it is not a failure)

Conway's Law says a system mirrors the communication structure of whoever built it. Invert it: a codebase touched by parallel agents and multiple humans across many sessions — with no single mind holding the whole map — *necessarily* accumulates fragments. Duplicate configs, forks, orphan specs, services quietly sharing a database. This is not sloppiness to feel bad about; it is the expected entropy of high-leverage, multi-actor development. The only real question is whether you defrag periodically **or** meet the fragmentation when it detonates.

The leverage of agentic coding (ship 10x faster) is paid for in visibility (nobody holds the full map). Defrag buys the visibility back, cheaply, on a schedule.

## Two Terrains Fragment in Parallel

| Terrain | Fragments into | Detonates as |
|---|---|---|
| **Code** | duplicate deploy targets, colliding bindings, stale forks, orphan repos | a **silent prod overwrite** — deploy from the wrong dir clobbers the live one |
| **Context** | parallel spec conventions, orphan docs, scattered context packages | a **false foundation** — an agent onboards from the wrong context and builds on it |

Treat both as first-class. Code drift fails loud (eventually — when a deploy detonates). **Context drift fails silent** — an agent reads the wrong spec, produces confidently wrong work, and nobody notices until it ships. The context half of this skill is not a footnote to the code half; it is the half that fails without a stack trace.

## The Collision Shape (universal across platforms)

**Any system with multiple deployable units accumulates collision risk: two things that can silently overwrite or corrupt each other.** The platform changes the vocabulary, not the shape.

| Universal concept | Cloudflare | Railway | Vercel | Fly | Docker Compose |
|---|---|---|---|---|---|
| **Deploy target** (what a deploy pushes to) | Worker name | Service name | Project name | App name | Compose service |
| **Shared datastore** (silent corruption risk) | D1 `database_id` | `DATABASE_URL` / Postgres | Linked DB | attached Postgres | named volume / DB service |
| **Domain claim** (exclusive, last-writer-wins) | route `pattern` | service domain | project domain | `[[services]]` | published port |
| **Deploy config** | `wrangler.toml` | `railway.json/toml` | `vercel.json` | `fly.toml` | `docker-compose.yml` |

The landmine is always the same shape: **two configs name the same target, or bind the same shared resource, and the platform does not stop the wrong one from winning.** Whether that shape is 🔴 or 🟢 depends on the platform's deploy model — see `references/platform-collision-semantics.md`. A name match is a *candidate*, never an automatic verdict.

## Perceived vs Actual Problem

Fragmentation registers as a vague *"things are getting messy in here"* unease. A vague feeling is not actionable, so it gets deferred — until it detonates. **Defrag's core move is converting the unactionable feeling into a specific, located, severity-ranked finding.**

| Perceived (the feeling) | Actual (what defrag locates) |
|---|---|
| "Things are getting messy in here" | Two `wrangler.toml` deploy to the same worker — and you can't say which is live |
| "I should clean up sometime" | Three services point at the same prod Postgres; none owns migrations |
| "There's old stuff lying around" | A 6-month-old fork shares a name with the active dir; grep finds the wrong one first |
| "The docs are a bit scattered" | Two context-package conventions; agents onboard from whichever they hit first |

If a defrag pass ends with a *feeling* instead of a *located finding with a file path and a severity*, it failed.

## The Three Tests (apply to any candidate)

These are the teeth. Run them before classifying severity.

**1. The "Which one is live?" test.** For every deploy-target name, can you name the canonical directory in under five seconds? Hesitation **is** the finding — your mental map has diverged from the repo. A system you can't answer this for instantly is already fragmented.

**2. The "Two-deploy" test.** If you ran the deploy command from each directory sharing a target name, would the *same* live deployment change? **Yes →** they are the same target; one is a silent-overwrite landmine (🔴). **No** (different platform/project/namespace) → coincidental (🟢). This test is what `platform-collision-semantics.md` formalizes per platform.

**3. The "Onboard cold" test (context).** If a fresh agent loaded context for this project right now, would it find **one** coherent source — or land in whichever fragment it happened to hit first? More than one possible answer = context fragmentation, even if every individual doc is fine.

## When to Apply This Skill

Apply when:
- **Periodic:** last defrag >30 days ago (the discipline — don't wait for a trigger)
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

## Detect-Only, Never Auto-Fix

The skill produces a severity-ranked report; **the human decides what to consolidate.** Auto-fixing would re-introduce the exact cowboy problem this skill exists to prevent — one more actor changing state without holding the whole map. Defrag's job is to restore visibility, not to act on it unsupervised.

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

**A name match is a *candidate*, not a verdict. Severity comes from the platform's deploy model — does it protect you from the collision, or leave it as a footgun?** Flattening "duplicate name = 🔴" across all platforms produces false confidence. Calibrate per platform using `references/platform-collision-semantics.md`.

| Severity | Meaning | Example trigger |
|----------|---------|-----------------|
| 🔴 **Landmine** | A single deploy silently regresses production, no warning | Account/org-global target name + identical bindings (**Cloudflare, Fly**); overlapping domain claim; same datastore with no migration owner |
| 🟡 **Candidate / Drift** | Real only if a platform-specific condition holds — confirm it | Same name on a **project-scoped** platform (Railway/Render — same project?); Vercel name match (same `projectId`?); shared datastore (intentional?); stale fork; spec drift |
| 🟢 **OK / coincidental** | Platform protects you, or the match is across namespaces | Cross-platform name match (separate namespaces); Compose service name across files; explicit canonical/archived marker |

**The 🔴 rule that never relaxes:** account/org-global name + identical bindings (Cloudflare, Fly) — the shape that fires silently with zero warning.

For each candidate, run the platform-specific check in `references/platform-collision-semantics.md` and escalate (🟡→🔴) or clear (🟡→🟢). Never leave a 🟡 candidate unresolved on a platform whose footgun you haven't checked. See `references/landmine-patterns.md` for the catalog of shapes.

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

- **`platform-collision-semantics.md`** — the calibration layer: per-platform deploy model, what each platform protects you from, and therefore what severity a detected collision deserves. This is where the skill's potency lives — consult it during classification.
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
