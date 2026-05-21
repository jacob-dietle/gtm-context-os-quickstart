# Downstream Handoff — Mapping Findings to Skill Chains

When a defrag scan produces findings, this document tells the agent which skill to invoke next. Every finding maps to exactly one handoff chain.

## Decision tree

```
Finding severity?
├── 🔴 Landmine  → Standard Consolidation Chain
├── 🟡 Drift     → Lightweight Cleanup Chain OR Defer
└── 🟢 OK        → No action (report-only)
```

## Standard Consolidation Chain (🔴)

Use when a landmine requires removing a duplicate codebase or merging two surfaces.

```
defrag findings
      │
      ▼
devops-architecture-perspectives
  • Apply multiple expert lenses to decide which config is canonical
  • Diagnose actual problem vs perceived problem
  • Choose simplest consolidation strategy (subtree / move / delete)
      │
      ▼
consequence-driven-design
  • Trace 1st-order (immediate deploy safety)
  • Trace 2nd-order (who/what references the old location)
  • Trace 3rd-order (will this create a new drift surface?)
      │
      ▼
specification-driven-development
  • Write a consolidation spec (like C0a_MCP_CONSOLIDATION)
  • Include: assumption audit, phases, rollback scenarios, gates
      │
      ▼
application-git-engineering
  • Execute: git subtree add / move / delete with history preserved
  • Archive upstream repo with STOP README
  • Rename local deprecated directory with date suffix
      │
      ▼
production-hardening
  • Verify deploy surface after consolidation
  • Confirm no new drift introduced
  • Re-run defrag to close the loop
      │
      ▼
context-package
  • Preserve the why, the evidence, the commits
  • Link to this defrag report as the triggering evidence
```

**Exemplar:** A service-consolidation migration where every step in the chain was executed and every artifact is traceable (canonical pick → consequence trace → spec → migration → hardening → context package).

## Lightweight Cleanup Chain (🟡)

Use for drift findings that don't yet warrant a full consolidation spec.

### Missing disposition marker
```
defrag finding → application-git-engineering (add README marker)
```
One commit, one line change. Example:
```markdown
# my-app — ARCHIVED 2026-04-20
**Canonical source:** the monorepo service directory (e.g., `apps/<monorepo>/services/<service>/`)
```

### Orphan repo (>90d, no CI, no CLAUDE.md reference)
```
defrag finding → user decision: archive or keep?
  ├── keep → application-git-engineering (add CLAUDE.md reference + CI)
  └── archive → application-git-engineering (rename + STOP README)
```

### Stale fork with unclear canonical status
```
defrag finding → devops-architecture-perspectives (which is canonical?) → then Standard Consolidation Chain
```
Escalates to the 🔴 chain because the moment you designate one canonical, the other becomes a true landmine.

## Defer to next defrag

Not every drift finding needs action now. Defer when:
- Cost of fix > cost of risk (orphan repo that no agent touches)
- Active work conflicts with consolidation (parallel agent editing the same area)
- Drift is downstream of a larger decision (pending architectural choice)

Mark the finding with a `DEFER_UNTIL: YYYY-MM-DD` line in the defrag report. The next defrag checks this list first.

## Escalation paths

| Finding characteristic | Escalation |
|-------------------------|------------|
| Affects live production traffic | Immediately to Standard Consolidation Chain, no defer option |
| Affects multiple accounts (Cloudflare, GitHub) | Start with `security-thinking` before architecture |
| Touches auth, access control, tokens | Start with `security-thinking` before architecture |
| Client-specific infra | Apply the client's specific infra skill first |
| KB / docs drift (not code) | Use `kb-branch-audit` or `context-os-maintenance` instead — this skill is code-scope only |

## What defrag does NOT hand off to

These skills do NOT follow from defrag findings:
- `feature-planning-and-decomposition` — consolidation is not a net-new feature; use `specification-driven-development`
- `debugging-and-complexity-assessment` — defrag findings are not bugs; they are structural drift
- `eval-loop` — defrag is not a quality-scoring problem
- `simplify` — defrag operates at the repo/service layer, not the code-quality layer

## Integration with `production-hardening`

Defrag's deploy-surface inventory (`scan_deploy_surface.sh` output) is a direct input to `production-hardening`. Pass the inventory forward when handing off:

```
Pre-deploy check:
  defrag (inventory deploy surface + flag landmines)
    ↓
  production-hardening (consume inventory, audit 5 dimensions)
    ↓
  proceed or block deploy
```

This pairing catches the case where a non-landmine directory is about to be deployed from, but its readiness (observability, health endpoints, runaway protection) hasn't been verified.
