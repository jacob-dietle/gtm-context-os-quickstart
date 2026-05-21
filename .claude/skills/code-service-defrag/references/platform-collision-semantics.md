# Platform Collision Semantics

The potency of a defrag scan is not "did two names match?" — it's **"does the platform protect you from the collision, or leave it as a footgun?"** A name match is only a *candidate*. Severity comes from the platform's deploy model. This file encodes that calibration so classification (Step 3) is sharp, not flattened.

## The First Principle, Stated Precisely

> A landmine exists where two deploy targets can write to the same place **AND the platform offers no protection against the wrong one winning.**

Flattening "duplicate name = 🔴" across all platforms produces false confidence: it over-flags project-scoped platforms and under-investigates the platforms whose real key isn't the name field. Calibrate per platform.

## Per-Platform Calibration

### Cloudflare Workers — 🔴 (no protection)
- **Deploy key:** worker `name`, scoped to the **account** (global within account).
- **Footgun:** `wrangler deploy` overwrites the named worker. Two directories with the same name point at the same live worker. Whoever deploys last wins, silently.
- **Severity:** same name = 🔴 **always**. Same name **+ identical bindings** (D1 `database_id`, KV id, route) = guaranteed silent prod regression — the canonical landmine.
- **Subtlety:** `[env.*]` blocks override the name per-environment; an env name is **not** a collision with the top-level name. The scanner skips `[env.*]` for exactly this reason. But an `[env.dev]` that forgets `routes = []` inherits the prod domain — that *is* a 🔴 (see route pattern below).

### Fly.io — 🔴 (no protection)
- **Deploy key:** `app` name, scoped to the **org** (global within org).
- **Footgun:** identical to Cloudflare — `fly deploy` targets the app by name; two configs with the same app = silent overwrite.
- **Severity:** same app name = 🔴 always.

### Railway — 🟡 candidate (project-scoped)
- **Deploy key:** service name, scoped to a **project**. The same service name in two *different* projects is fine.
- **Footgun:** only real if both configs target the **same project**. The project link often lives outside `railway.json` (CLI-linked, `.railway/`), so the config alone may not prove it.
- **Severity:** name match = 🟡 candidate. Confirm same project → escalate to 🔴. Different projects → 🟢.

### Vercel — 🟡 candidate (name field is the wrong key)
- **Deploy key:** the linked **`projectId`** in `.vercel/project.json` (usually gitignored). The `name` field in `vercel.json` is advisory/deprecated.
- **Footgun:** two local directories linked to the *same* `projectId` both deploy to the same project. A `name` match is weak signal; a `projectId` match is the real landmine.
- **Severity:** `name` match alone = 🟡 (investigate the link). Same `projectId` = 🔴.

### Render — 🟡 candidate (blueprint-scoped)
- **Deploy key:** service name within a `render.yaml` blueprint / account.
- **Footgun:** same service name across two blueprints can collide depending on account setup.
- **Severity:** name match = 🟡 candidate; confirm account/blueprint scope.

### Docker Compose — 🟢 usually (project-scoped per file)
- **Deploy key:** service name, scoped to the **compose project** (the file, or `-p` flag). Same service name in two *different* files is two different containers.
- **Footgun:** the real Compose collision is **not** the service name — it's a shared **published host port** or a shared **named volume**, which two stacks can fight over on the same host.
- **Severity:** cross-file service-name match = 🟢 (coincidental). Shared host port / named volume = 🟡→🔴.

### Mixed platforms — 🟢 (separate namespaces)
- A name appearing in, say, one `wrangler.toml` and one `railway.json` is **not** a collision — different namespaces. Almost always coincidental. Verify, then ignore.

## Shared Datastore — Severity by Ownership
- **Footgun:** the risk is not a deploy; it's a **destructive migration or schema change** run from the wrong service against a datastore others depend on.
- **Severity:** same datastore referenced from 2+ services = 🟡 by default (often intentional). Escalate to 🔴 when **no single service owns migrations** — because then any service can run a "safe" migration that breaks the others.
- **Remediation:** designate one service as schema owner; others read-only or via its API. Document the decision so the shared binding is intentional, not accidental.

## How to Use This in Classification (Step 3)

1. The scanner emits collision **candidates** with a per-platform default severity.
2. For each candidate, confirm the platform-specific question above (same project? same projectId? shared port?).
3. Escalate (🟡→🔴) or clear (🟡→🟢) based on the answer. **Never leave a 🟡 candidate unresolved on a platform whose footgun you haven't checked.**
4. The 🔴 rule that never relaxes: **account/org-global name + identical bindings** (Cloudflare, Fly). That is the shape that fires silently with zero warning.
