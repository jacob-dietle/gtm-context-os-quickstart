# Defrag Cadence — When to Run and What "Good" Looks Like

## Core cadence

| Trigger | Interval | Invoked by |
|---------|----------|------------|
| Periodic | Monthly (30-day freshness threshold) | `context-foundation` at session start |
| Post-migration | Immediately after any `git subtree add`, repo merge, or directory consolidation | `application-git-engineering` |
| Pre-deploy | Before any `wrangler deploy` to shared prod accounts | `production-hardening` |
| Post-multi-agent | Immediately after `coordinated-agent-teams` execution | User or agent discretion |
| Ad-hoc | When canonical-source ambiguity is felt | User explicitly (`/code-service-defrag`) |

## Freshness check (for `context-foundation`)

At session start, `context-foundation` should grep `_system/reports/defrag_log.md` for the most recent entry and compare to current date. If >30 days stale, surface a nudge:

```
⚠ Defrag last run: YYYY-MM-DD (XX days ago)
Recommend: run /code-service-defrag before starting deploy-adjacent work
```

This keeps drift visible without being noisy. The user decides whether to defrag now or defer.

## What "good" looks like over time

A healthy codebase produces defrag reports where:
- 🔴 count = 0 (no landmines)
- 🟡 count is small and trending down over consecutive reports
- 🟢 count grows as more directories gain explicit markers
- Deploy-surface inventory matches the agent's mental model (no surprises)

An unhealthy trajectory:
- 🔴 count >0 for multiple consecutive reports (landmine not getting fixed)
- 🟡 count growing over time (drift accumulating faster than it's being resolved)
- New directories appearing without disposition markers
- Deploy surface contains entries the agent didn't know existed

## Time budget

- **Scan:** <30 seconds for a codebase with <50 apps/
- **Report classification:** 2-5 minutes (agent reads findings, assigns severity, writes report file)
- **User review:** <5 minutes (severity-ranked, actionable items only)

If a single defrag pass takes >15 minutes total, either the codebase has genuine structural issues (run the Standard Consolidation Chain on 🔴s) or the skill needs tuning (add exclusions, refine heuristics).

## What to do between defrags

Behaviors that prevent drift between scheduled defrags:
1. **Every new `apps/*` dir gets a CANONICAL marker in its README on day one** — not "later"
2. **Every migration ends with a defrag pass** — proves the migration removed, not just added
3. **Every multi-agent session ends with a brief defrag** — catches parallel-fragment creation
4. **`context-package` output should link to the defrag report date** — proves state at package creation

## What NOT to do

- **Don't run defrag every session.** Monthly cadence is the baseline; reactive runs are the exception.
- **Don't auto-fix findings inside the defrag skill.** Handoff to the appropriate downstream skill is load-bearing — auto-fix reintroduces the cowboy problem.
- **Don't skip 🟡 findings just because they aren't landmines.** Every 🟡 becomes a 🔴 on the next migration.
- **Don't defrag one directory at a time.** Cross-cutting collisions (duplicate worker names, shared bindings) only surface when scanning everything at once.
