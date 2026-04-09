---
name: context-os-cli
description: >
  This skill should be used when users ask about their work context,
  what they're working on, recent activity, file relationships, or
  knowledge graph structure. Uses context-os CLI (including graph
  health/search/stats commands) combined with grep/glob for context
  restoration. Every claim MUST cite a receipt ID for user verification.
---

# Context OS CLI Skill

Use `context-os` CLI + grep + glob together for context restoration.

**Core insight:** The CLI finds WHICH files matter. Grep/Read find WHAT's in them.

---

## Quick Start (90% of queries)

```bash
# 1. Full context for a topic (start here — one command does it all)
context-os context "pixee" --format json

# 2. If you need to drill deeper, use targeted queries
context-os query flex --files "*pixee*" --agg count,recency --format json

# 3. Read hot files to understand what they are
Read: <top_file_from_step_1>

# 4. Search content IN those files
Grep: pattern="hubspot|integration" path=<directory_from_step_1>

# 5. Check git for recent changes
git log --oneline -10 -- <hot_files>
```

**Start with `context` for broad questions, drop to `query` subcommands for targeted drilldowns.**

---

## CLI Commands

### Top-Level Commands

| Command | Purpose |
|---------|---------|
| `context <query>` | **Start here.** Composed query across flex, heat, chains, sessions, timeline, co-access |
| `query <subcommand>` | Targeted queries (flex, heat, chains, etc.) |
| `intel health` | Check intel service health |
| `intel name-chain <id>` | Name a chain using AI |
| `daemon status` | Show daemon sync state + registration |
| `daemon once` | Run a single sync cycle |

### Query Subcommands

| Command | Purpose |
|---------|---------|
| `query flex --files "*pattern*"` | Find files by path pattern |
| `query flex --time 7d` | Find files touched in time window |
| `query heat --time 30d` | File heat metrics (specificity, velocity, score, level) |
| `query co-access <file>` | Find files accessed together |
| `query session <id>` | All files in a session |
| `query sessions --time 7d` | Session-grouped data |
| `query chains` | List conversation chains |
| `query timeline --time 7d` | Timeline data for visualization |
| `query verify <receipt>` | Verify a previous query result |
| `query receipts` | List recent query receipts |

**Always use `--format json`** — table output truncates long paths.

---

## The `context` Command

**The highest-level query.** One command gives you executive summary, heat, work clusters, insights, continuity, timeline, and suggested reads.

```bash
context-os context "tastematter" --format json
context-os context "pixee" --time 14d --format json
```

**Response includes:**
- `executive_summary` — status, work_tempo, hot_file_count, focus_ratio
- `current_state` — key_metrics, evidence (file excerpts)
- `continuity` — left_off_at, pending_items, chain_context
- `work_clusters` — co-accessed file groups with PMI scores
- `suggested_reads` — prioritized files (with surprise flag for unexpected)
- `timeline` — weekly focus areas with top files and access counts
- `insights` — abandoned file detection, anomalies
- `verification` — receipt_id, files/sessions/pairs analyzed
- `quick_start` — commands and directory structures from matching files

**When to use `context` vs `query`:**
| Need | Use |
|------|-----|
| "What's happening with project X?" | `context "X"` |
| "What files are hot right now?" | `query heat` |
| "Find files matching a pattern" | `query flex --files` |
| "What did I work on this week?" | `query flex --time 7d` |
| "Show me session history" | `query sessions` |
| "What files go with this one?" | `query co-access <file>` |

---

## The `query heat` Command

Shows file heat metrics with percentile-based classification.

```bash
context-os query heat --time 30d --format json
context-os query heat --files "*tastematter*" --sort specificity --format csv
```

**Options:**
```
-t, --time <TIME>      Long window: 30d (default), 14d, 60d, 90d
-f, --files <FILES>    File path pattern filter (glob-style)
-l, --limit <LIMIT>    Max results (default: 50)
-s, --sort <SORT>      Sort by: heat (default), specificity, velocity, name
    --format <FORMAT>  Output: table (default), json, compact, csv
```

**Heat levels use percentile classification:**
- Top 10% = HOT, 10-30% = WARM, 30-60% = COOL, Bottom 40% = COLD

**Key fields:** `specificity` (IDF-like), `velocity`, `heat_score`, `heat_level`

See `references/heat-metrics-model.md` for formula details and interpretation tables.

---

## Graph Traversal: `graph-exec` Command

Executes JavaScript against an in-memory knowledge graph (markdown files with frontmatter + wiki-links). Uses Boa JS engine — pure Rust, no Node/bun.

```bash
context-os graph-exec --graph <path-to-markdown-dir> '<javascript-code>'
```

### The `codemode` Object (4 functions, all synchronous)

```
codemode.graph_search({ pattern, scope?, maxResults? })
  pattern: string        — regex to match
  scope: 'content' | 'frontmatter' | 'both' (default: 'both')
  maxResults: number     (default: 20)
  Returns: [{ path, matches: [{ line, content }], score, frontmatter }]

codemode.graph_traverse({ start, direction?, maxDepth?, filter? })
  start: string          — node name (filename without .md, e.g. "context-engineering")
  direction: 'outbound' | 'inbound' | 'both' (default: 'outbound')
  maxDepth: number       (default: 2)
  filter: { status?, domain?, tags? }
  Returns: { nodes: [{ path, name, depth, frontmatter }], edges: [{ from, to }] }

codemode.graph_read({ path, section?, maxLines? })
  path: string           — relative path (e.g. "technical/context-engineering.md")
  section: string        — extract named heading section only
  Returns: { path, content, frontmatter, outbound_links, inbound_links }

codemode.graph_query({ filter, sort?, limit? })
  filter: { status?, domain?, tags?, name?, validated_by? }
  sort: 'name' | 'last_updated' | 'status'
  limit: number          (default: 50)
  Returns: { nodes: [{ path, name, status, domain, tags, last_updated, link_count }], total }
```

### Code Pattern: Use IIFEs

Functions are **synchronous** (not async). Wrap code in an IIFE:

```bash
# CORRECT — IIFE returns a value
context-os graph-exec --graph 04_knowledge_base '(() => {
  const r = codemode.graph_query({ filter: { status: "canonical" } });
  return JSON.stringify({ total: r.total, names: r.nodes.map(n => n.name) });
})()'

# WRONG — bare return is a syntax error
context-os graph-exec --graph 04_knowledge_base 'return codemode.graph_search({})'

# WRONG — async not needed (and Boa doesn't support top-level await)
context-os graph-exec --graph 04_knowledge_base 'async () => { ... }'
```

### Bash Escaping

Keep JS simple when passing inline. Avoid backslashes and nested quotes. If complex, use a heredoc:

```bash
context-os graph-exec --graph 04_knowledge_base "$(cat <<'JSEOF'
(() => {
  const hubs = codemode.graph_query({ filter: {} });
  const sorted = hubs.nodes
    .sort((a, b) => (b.link_count.outbound + b.link_count.inbound) - (a.link_count.outbound + a.link_count.inbound))
    .slice(0, 10);
  return JSON.stringify(sorted.map(n => ({
    name: n.name,
    links: n.link_count.outbound + n.link_count.inbound
  })));
})()
JSEOF
)"
```

### Common Graph Queries

```bash
# Top hubs by link count
context-os graph-exec --graph 04_knowledge_base '(() => {
  const r = codemode.graph_query({ filter: {} });
  return JSON.stringify(r.nodes.sort((a,b) => (b.link_count.outbound+b.link_count.inbound)-(a.link_count.outbound+a.link_count.inbound)).slice(0,5).map(n => ({ name: n.name, out: n.link_count.outbound, in: n.link_count.inbound })));
})()'

# All canonical nodes
context-os graph-exec --graph 04_knowledge_base '(() => {
  const r = codemode.graph_query({ filter: { status: "canonical" } });
  return JSON.stringify({ total: r.total, nodes: r.nodes.map(n => n.name) });
})()'

# Traverse outbound from a node
context-os graph-exec --graph 04_knowledge_base '(() => {
  const r = codemode.graph_traverse({ start: "context-engineering", direction: "both", maxDepth: 1 });
  return JSON.stringify(r.nodes.map(n => ({ name: n.name, depth: n.depth })));
})()'

# Find orphan nodes (no links)
context-os graph-exec --graph 04_knowledge_base '(() => {
  const r = codemode.graph_query({ filter: {} });
  const orphans = r.nodes.filter(n => n.link_count.outbound === 0 && n.link_count.inbound === 0);
  return JSON.stringify({ count: orphans.length, nodes: orphans.map(n => n.name) });
})()'

# Search then read (composition)
context-os graph-exec --graph 04_knowledge_base '(() => {
  const results = codemode.graph_search({ pattern: "taste" });
  const top = results[0];
  const detail = codemode.graph_read({ path: top.path });
  return JSON.stringify({ path: detail.path, outbound: detail.outbound_links, inbound: detail.inbound_links });
})()'
```

### MCP Alternative

If running inside Claude Code with the `codemode-graph` MCP server enabled, prefer the MCP tool over the CLI. The MCP tool description is embedded and the LLM gets the API right on the first call. Functions are async in MCP mode:

```js
// MCP mode (async, tool description auto-loaded)
async () => {
  const results = await codemode.graph_search({ pattern: 'context' });
  return results[0];
}
```

### When to Use graph-exec vs MCP vs grep/glob

| Need | Use |
|------|-----|
| Structural queries (hubs, clusters, orphans, traversal) | `graph-exec` or MCP |
| Simple file search by name | `Glob` |
| Content search | `Grep` |
| File activity/heat over time | `context-os query heat` |
| Co-access patterns | `context-os query co-access` |
| Full project context | `context-os context` |

---

## Common Mistakes

### Wrong: Expect semantic search
```bash
# DON'T - CLI searches file PATHS, not content
context-os query flex --files "*notification design*"  # Won't find anything
```

### Right: Use CLI for paths, grep for content
```bash
# DO - Find files first, then search content
context-os query flex --files "*alert*" --format json  # Find alert-related files
Grep: pattern="notification|digest|slack" path=<results>  # Search content
```

### Wrong: Only use CLI
```bash
# DON'T - You'll miss semantic understanding
context-os query flex --files "*hubspot*"  # Returns files but not WHAT they do
```

### Right: Combine tools
```bash
# DO - CLI narrows, Read/Grep understands
context-os query flex --files "*hubspot*" --format json
Read: <top_result>  # Understand what the file actually does
```

### Wrong: Skip `context` and go straight to `query`
```bash
# DON'T - You'll miss insights, clusters, and continuity
context-os query flex --files "*pixee*" --format json
```

### Right: Start broad, drill down
```bash
# DO - Get the full picture first
context-os context "pixee" --format json
# THEN drill into specific areas if needed
context-os query heat --files "*pixee*" --format json
```

---

## Combining Tools

| Need | Tool |
|------|------|
| Broad project context | `context-os context "<topic>"` |
| Find files by path pattern | `context-os query flex --files` |
| File heat/activity metrics | `context-os query heat` |
| Find files by content | `Grep` |
| Read file contents | `Read` |
| Find files by name glob | `Glob` |
| Check recent changes | `git log` |

**Workflow pattern:**
```
context → full picture (summary, heat, clusters, insights)
    ↓
query heat/flex → drill into specific files or patterns
    ↓
Read → understand what files contain
    ↓
Grep → find specific concepts in content
    ↓
git log → understand evolution
```

---

## Database Location

**Canonical:** `~/.context-os/context_os_events.db`

**If queries return empty results:**
```bash
# Check database exists
ls ~/.context-os/context_os_events.db

# Check daemon status
context-os daemon status

# Run a single sync
context-os daemon once

# Rebuild indexes if needed
context-os build-chains
context-os index-files
```

---

## Citation Requirements

Every claim from query results MUST include receipt ID:

```markdown
Found 147 Pixee files [q_7f3a2b]
To verify: context-os query verify q_7f3a2b
```

---

## When This Skill Helps vs Doesn't

| Helps | Doesn't Help |
|-------|--------------|
| "What files did I touch for project X?" | "What was I thinking about?" |
| "When was this file last accessed?" | "Why did I make this change?" |
| "What files are related to this one?" | "What's the best architecture for X?" |
| "What's the status of this work?" | "How should I fix this bug?" |
| "What files are hot/cold right now?" | "What's in my calendar?" |

**For semantic understanding, READ the files.** The CLI tells you which ones matter.

---

## References

For advanced patterns:
- `references/heat-metrics-model.md` - Heat formula: specificity, exponential decay, percentile classification
- `references/search-strategies.md` - 9 multi-step search strategies (Pilot Drilling, Triangulation, etc.)
- `references/query-patterns.md` - Path substring patterns and result interpretation

---

## CLI Full Reference

### context (Composed Query — Start Here)

```bash
context-os context <QUERY> [OPTIONS]

ARGUMENTS:
  <QUERY>            Search query (used as glob pattern *query*)

OPTIONS:
  -t, --time <TIME>      Time window (default: 30d)
  -l, --limit <LIMIT>    Max results per sub-query (default: 20)
      --format <FORMAT>  Output: json (default), compact, table
```

### query flex (Targeted File Query)

```bash
context-os query flex [OPTIONS]

OPTIONS:
  -f, --files <FILES>      File pattern (glob): "*pixee*", "*.py"
  -t, --time <TIME>        Time window: 7d (default), 14d, 30d
  -c, --chain <CHAIN>      Filter by chain ID
  -s, --session <SESSION>  Filter by session ID
  -a, --agg <AGG>          Aggregations: count, recency
  -l, --limit <LIMIT>      Max results (default: 20)
      --sort <SORT>        Order: count (default), recency
      --format <FORMAT>    Output: json (default), compact
```

### query heat (File Heat Metrics)

```bash
context-os query heat [OPTIONS]

OPTIONS:
  -t, --time <TIME>      Window: 30d (default), 14d, 60d, 90d
  -f, --files <FILES>    File pattern filter (glob-style)
  -l, --limit <LIMIT>    Max results (default: 50)
  -s, --sort <SORT>      Sort: heat (default), specificity, velocity, name
      --format <FORMAT>  Output: table (default), json, compact, csv
```

### query timeline (Visualization Data)

```bash
context-os query timeline [OPTIONS]

OPTIONS:
  -t, --time <TIME>      Time range: 7d (default), 14d, 30d
  -p, --files <FILES>    File pattern filter
  -c, --chain <CHAIN>    Filter by chain ID
  -l, --limit <LIMIT>    Max files (default: 30)
      --format <FORMAT>  Output: json (default), compact
```

### query sessions (Session-Grouped)

```bash
context-os query sessions [OPTIONS]

OPTIONS:
  -t, --time <TIME>      Time range: 7d (default), 14d, 30d
  -c, --chain <CHAIN>    Filter by chain ID
  -l, --limit <LIMIT>    Max sessions (default: 50)
      --format <FORMAT>  Output: json (default), compact
```

### Other Query Commands

| Command | Purpose |
|---------|---------|
| `query search <term>` | Keyword search in file paths |
| `query file <path>` | History for specific file |
| `query co-access <path>` | Files accessed with target |
| `query chains` | List conversation chains |
| `query verify <receipt>` | Verify a receipt |
| `query receipts` | List recent receipts |

All support `--format json`.

### Non-Query Commands

| Command | Purpose |
|---------|---------|
| `sync-git` | Sync git commits from repository |
| `parse-sessions` | Parse JSONL session files |
| `build-chains` | Build chain graph from sessions |
| `index-files` | Build inverted file index |
| `watch` | Watch directory for file changes |
| `daemon once` | Run single sync cycle |
| `daemon start` | Start daemon (foreground) |
| `daemon status` | Show sync state + registration |
| `daemon install` | Install daemon to run on login |
| `daemon uninstall` | Remove daemon from login |
| `intel health` | Check intel service health |
| `intel name-chain <id>` | Name a chain using AI |
| `serve` | Start HTTP API server |

---

**Last Updated:** 2026-04-07
**Version:** 6.0 (Renamed from context-query to context-os-cli. All local CLI commands now reference `context-os` binary. Publishing commands remain `tastematter`. Added graph health/search/stats from Spec 32.)
