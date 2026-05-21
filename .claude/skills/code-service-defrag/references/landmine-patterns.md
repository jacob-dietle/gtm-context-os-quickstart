# Landmine Patterns — Silent-Overwrite Shapes

Patterns are stated platform-agnostically. The shape is universal; the vocabulary is per-platform. Append new shapes as discovered (anonymized — no real IDs, domains, or user counts).

## Pattern 1: Duplicate Deploy-Target Name + Identical Bindings

**Shape:** two configs in different directories declare the same deploy-target name and point at the same shared resources.

```toml
# apps/foo/wrangler.toml          # apps/bar/wrangler.toml
name = "my-service"               name = "my-service"        # ← SAME
database_id = "<shared-id>"       database_id = "<shared-id>" # ← SAME
```

Same shape on other platforms:
- **Railway:** two `railway.json` files with the same service `name` linked to the same project
- **Vercel:** two dirs deploying to the same project `name`
- **Fly:** two `fly.toml` files with the same `app`
- **Compose:** two compose files defining the same service name against the same volumes

**Why it's a landmine:** deploys are keyed by target name within an account/project. Two directories declaring the same name point at the same live deployment. A deploy from either location overwrites the other's code with zero warning. If the resource bindings also match, production regresses immediately.

**Severity:** 🔴 Landmine (always)

**How it happens:** a service gets migrated into a monorepo but the original standalone directory is left in place. Both configs still declare the same target name and datastore binding. A deploy from the stale fork silently regresses production — typically missing the most recent changes that only landed in the canonical copy. Catch it by diffing a live `/health` or version endpoint against each directory's source.

**Scan that catches it:** `scan_deploy_target_names.sh` + `scan_bindings.sh`

## Pattern 2: Shared Datastore Bound by Multiple Services

**Shape:** two or more services reference the same production database without a clear owner.

```
apps/api/.env       → DATABASE_URL=postgres://…@db-prod.example/app
apps/worker/.env    → DATABASE_URL=postgres://…@db-prod.example/app   # ← SAME prod DB
apps/cron/.env      → SUPABASE_URL=https://<same-ref>.supabase.co     # ← SAME project
```

**Why it's a landmine (or at least drift):** a migration, schema change, or destructive query run from one service hits the datastore every other service depends on. It can be intentional (a shared DB by design) — but if nobody decided that on purpose, it's an invisible coupling. The first time someone runs a "safe" migration from the wrong service, three services break.

**Severity:** 🟡 Drift → 🔴 Landmine on schema change. Surface it, confirm it's intentional, document the owner.

**How it happens:** services get spun up by copy-pasting the same connection string. No single service "owns" migrations. Resolve by designating one service as the schema owner and pointing others at it read-only or via API.

**Scan that catches it:** `scan_bindings.sh` (generic datastore section — reads host/project identity only, never credentials)

## Pattern 3: Overlapping Domain Claims

**Shape:** two configs claim the same domain or route.

```toml
# apps/foo/wrangler.toml          # apps/bar/wrangler.toml (or same repo, env block)
pattern = "example.com"           pattern = "example.com"
custom_domain = true              custom_domain = true
```

Same shape elsewhere: two Vercel projects with the same production domain; two Railway services exposing the same custom domain; two Fly apps with the same `[[services]]` host.

**Why it's a landmine:** domain bindings are exclusive — last writer wins. Whoever deployed most recently owns the domain, including an env block (e.g. `[env.dev]`) that forgot to declare `routes = []` and silently inherited prod's pattern.

**Severity:** 🔴 Landmine (always)

**How it happens:** a named-env block doesn't explicitly clear inherited routes, so the first deploy to that env claims the prod domain. Fix: explicit empty `routes = []` (or equivalent) in every non-prod env.

**Scan that catches it:** `scan_bindings.sh` (custom domain section)

## Pattern 4: Platform Queue / Single-Consumer Resource Collision (Cloudflare example)

**Shape:** two configs bind the same single-consumer resource (a CF Queue allows exactly one consumer).

```toml
[[queues.consumers]]    # apps/foo      [[queues.consumers]]   # apps/bar
queue = "my-queue"                      queue = "my-queue"     # ← SAME
```

**Why it's a landmine:** the second deploy binding the same queue consumer fails at deploy time — but the config looks valid until then, and a dev-env deploy can displace the prod consumer binding.

**Severity:** 🟡 Drift → 🔴 Landmine on deploy

**How it happens:** copying a prod queue-consumer binding into a dev env. Workaround: dev env doesn't bind the consumer; reads the prod queue read-only via HTTP triggers. (This is the CF instance of a general rule: any platform resource that allows exactly one binder is a collision risk when two configs claim it.)

**Scan that catches it:** `scan_bindings.sh` (when extended to single-consumer resources — future enhancement)

## Pattern 5: Stale Fork Under Similar Directory Name

**Shape:**
```
apps/
├── foo/          ← last commit 6 months ago, 871 lines source
├── foo-v2/       ← last commit yesterday, 982 lines source
```

**Why it's drift (not yet a landmine):** no immediate overwrite risk because names differ. But agents and humans may grep for `foo`, find the old dir first, and modify the wrong code. Becomes a landmine if both also match pattern 1 (same target name).

**Severity:** 🟡 Drift

**How it happens:** a service is migrated to a new location but the original is left behind. Resolve by renaming the old dir to `.ARCHIVED-YYYY-MM-DD` (and adding a STOP README) before any agent modifies it.

**Scan that catches it:** `scan_stale_forks.sh`

## Pattern 6: No Disposition Marker

**Shape:** an `apps/foo/` directory exists but its README doesn't say whether it's canonical, archived, or migrated.

**Why it's drift:** future agents and humans cannot quickly determine whether to work in this dir. Combined with pattern 5, this is how stale forks become landmines.

**Severity:** 🟡 Drift

**Remediation:** add a clear marker to the first 30 lines of the directory's README:
- `# name — CANONICAL` or
- `# name — ARCHIVED YYYY-MM-DD` or
- `# name — MIGRATED YYYY-MM-DD to [new-location]`

**Scan that catches it:** `scan_archive_markers.sh`

## Pattern 7: Parallel Context-Package Conventions

**Shape:**
```
apps/foo/
├── specs/context_packages/              ← 25 packages, numerical (22_...md)
└── specs/platform/context_packages/     ← 0 packages, README proposing letter-prefix (A_...)
```

**Why it's drift:** two spec dirs with different conventions fragment context. Future agents reading session-start context may land in either dir and miss the other's packages.

**Severity:** 🟡 Drift (high priority — invisible to deploy, but directly undermines agent onboarding)

**How it happens:** a proposed-but-never-adopted naming convention leaves an empty spec dir with only a README beside the real one. Resolve by deleting the unused dir and adding a `specs/README.md` codifying the canonical layout.

**Scan that catches it:** `scan_spec_dirs.sh`

## Pattern 8: Orphan Files at Spec Root

**Shape:**
```
apps/foo/specs/
├── 27_SOMETHING.md        ← orphan — no clear scope
├── context_packages/
└── platform/
```

**Why it's drift:** an `.md` directly under `specs/` has no clear scope signal — session spec? service spec? context package? Future agents can't tell.

**Severity:** 🟡 Drift

**How it happens:** a service-specific design spec gets placed at the top-level `specs/` root instead of under the service's own `specs/` dir. Move it next to related specs.

**Scan that catches it:** `scan_spec_dirs.sh`

## How to add a new pattern

1. Document the shape with a minimal reproducing snippet (anonymized — no real IDs, domains, or user counts)
2. Describe how it tends to happen
3. Classify severity (🔴 = immediate deploy risk; 🟡 = becomes a landmine later)
4. Identify which script catches it, or propose a new script
