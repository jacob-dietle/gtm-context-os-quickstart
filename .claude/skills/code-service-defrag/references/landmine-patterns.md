# Landmine Patterns — Silent-Overwrite Shapes

Append new landmine shapes to this file as they are discovered. Each entry includes: the pattern, an anonymized example, and the severity classification rule.

## Pattern 1: Duplicate Worker Name + Identical Bindings

**Shape:**
```toml
# apps/foo/wrangler.toml
name = "my-worker"
[[d1_databases]]
database_id = "<same-id>"

# apps/bar/wrangler.toml
name = "my-worker"           # ← SAME
[[d1_databases]]
database_id = "<same-id>"     # ← SAME
```

**Why it's a landmine:** Cloudflare Worker deploys are keyed by worker name within an account. Two directories declaring the same name will both point at the same deployed worker. A `wrangler deploy` from either location overwrites the other's code with zero warning. If bindings (D1, KV, R2, routes) also match, the new code takes over production traffic immediately.

**Severity:** 🔴 Landmine (always)

**How it happens:** A service gets migrated into a monorepo (`git subtree add`) but the original standalone directory is left in place. Both configs still declare the same worker name and D1 binding. A deploy from the stale fork silently regresses production — typically missing the most recent code changes that only landed in the canonical copy. Catch it by diffing a live `/health` or version endpoint against each directory's source.

**Scan that catches it:** `scan_worker_names.sh` + `scan_bindings.sh`

## Pattern 2: Overlapping Custom Domain Routes

**Shape:**
```toml
# apps/foo/wrangler.toml
[[routes]]
pattern = "example.com"
custom_domain = true

# apps/bar/wrangler.toml (or same repo, different env)
[[routes]]
pattern = "example.com"
custom_domain = true
```

**Why it's a landmine:** CF custom domain bindings are exclusive. The last deploy to claim a domain wins. In a two-config setup, whoever deployed most recently owns the domain — including an `env.dev` block that forgot to specify `routes = []` and inherited prod's pattern.

**Severity:** 🔴 Landmine (always)

**How it happens:** A `[env.dev]` block does not explicitly declare `routes = []`, so Wrangler inherits the top-level production `pattern`. The first `wrangler deploy --env dev` silently claims the prod custom domain for the dev worker. Fix: explicit empty `routes = []` in every named env block.

**Scan that catches it:** `scan_bindings.sh` (custom domain section)

## Pattern 3: Two-Consumer Queue Collision

**Shape:**
```toml
# apps/foo/wrangler.toml
[[queues.consumers]]
queue = "my-queue"

# apps/bar/wrangler.toml
[[queues.consumers]]
queue = "my-queue"  # ← SAME
```

**Why it's a landmine:** CF Queues allow exactly one consumer per queue. A second `wrangler deploy` binding the same queue as a consumer will fail at deploy time — but before that, the config looks valid, and if the second deploy is to a dev env that wasn't caught in review, the prod consumer binding may be displaced.

**Severity:** 🟡 Drift → 🔴 Landmine on deploy

**How it happens:** Setting up a dev environment that copies the prod queue-consumer binding. Workaround: dev env does not bind the queue consumer; reads the prod queue read-only via HTTP triggers instead.

**Scan that catches it:** `scan_bindings.sh` (when extended to queue consumers — future enhancement)

## Pattern 4: Stale Fork Under Similar Directory Name

**Shape:**
```
apps/
├── foo/          ← last commit 6 months ago, 871 lines source
├── foo-v2/       ← last commit yesterday, 982 lines source
```

**Why it's drift (not yet a landmine):** No immediate overwrite risk because names differ. But agents and humans may grep for `foo`, find the old dir first, and modify the wrong code. Will become a landmine if both dirs also match pattern 1 (same worker name).

**Severity:** 🟡 Drift

**How it happens:** A service is migrated into a new location but the original is left behind. Resolve by renaming the old dir to `.ARCHIVED-YYYY-MM-DD` (and adding a STOP README) before any agent modifies it.

**Scan that catches it:** `scan_stale_forks.sh`

## Pattern 5: No Disposition Marker

**Shape:** An `apps/foo/` directory exists but its README doesn't say whether it's canonical, archived, or migrated.

**Why it's drift:** Future agents and humans cannot quickly determine whether to work in this dir. Combined with pattern 4, this is how stale forks become landmines.

**Severity:** 🟡 Drift

**Remediation:** Add a clear marker to the first 30 lines of the directory's README:
- `# name — CANONICAL` or
- `# name — ARCHIVED YYYY-MM-DD` or
- `# name — MIGRATED YYYY-MM-DD to [new-location]`

**Scan that catches it:** `scan_archive_markers.sh`

## Pattern 6: Parallel Context-Package Conventions

**Shape:**
```
apps/foo/
├── specs/context_packages/              ← 25 packages, numerical (22_...md)
└── specs/platform/context_packages/     ← 0 packages, README proposing letter-prefix (A_...)
```

**Why it's drift:** Two spec dirs with different conventions fragment context. Future agents reading session-start context may land in either dir and miss the other's packages. One convention "wins" only when an agent happens to notice the other exists.

**Severity:** 🟡 Drift (high priority — unlike code landmines, this is invisible to `wrangler deploy` but *directly* undermines agent onboarding)

**How it happens:** A proposed-but-never-adopted naming convention leaves an empty spec dir with only a README beside the real one. Resolve by deleting the unused dir and adding a `specs/README.md` codifying the canonical layout.

**Scan that catches it:** `scan_spec_dirs.sh`

## Pattern 7: Orphan Files at Spec Root

**Shape:**
```
apps/foo/specs/
├── 27_SOMETHING.md        ← orphan — no clear scope
├── context_packages/
└── platform/
    └── sessions/
```

**Why it's drift:** An `.md` directly under `specs/` has no clear scope signal. Is it a session spec? A service-specific spec? A context package? Future agents can't tell.

**Severity:** 🟡 Drift

**How it happens:** A service-specific design spec gets placed at the top-level `specs/` root instead of under the service's own `specs/` dir. Move it next to related specs.

**Scan that catches it:** `scan_spec_dirs.sh`

## Pattern 8: Legacy Staging-Prefix Spec Dir

**Shape:**
```
services/pipeline/
├── specs/                          ← active
└── _system/specs/                  ← 1-2 orphan files from a prior convention
```

**Why it's drift:** A deprecated staging prefix (`_system/` or similar) leaves files that rot; agents don't know to check two places.

**Severity:** 🟡 Drift

**How it happens:** A prior directory convention is abandoned but a stray spec file is left behind in the old location. Resolve by moving the file into the active `specs/` dir and removing the empty legacy tree.

**Scan that catches it:** `scan_spec_dirs.sh`

## How to add a new pattern

When a new landmine shape surfaces:
1. Document the shape with a minimal reproducing snippet (anonymized — no real IDs, domains, or user counts)
2. Describe how it tends to happen
3. Classify severity (🔴 Landmine = immediate deploy risk; 🟡 Drift = becomes a landmine on next migration)
4. Identify which script catches it, or propose a new script
