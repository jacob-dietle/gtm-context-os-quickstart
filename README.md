# GTM Context OS Quickstart

Build your first context operating system in 10 minutes. A structured knowledge graph where AI compounds intelligence over time.

## Prerequisites

### 1. Claude Code

Install [Claude Code](https://claude.ai/code) — the CLI for Claude.

### 2. Context-OS CLI

The context-os CLI gives your system structural intelligence — graph queries, file heat tracking, and behavioral co-access analysis.

**macOS/Linux:**
```bash
curl -fsSL https://install.tastematter.dev/install-context-os.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://install.tastematter.dev/install-context-os.ps1 | iex
```

Verify: `context-os --version`

## Quick Start

1. Fork this repo (or clone it)
2. Open in Claude Code: `claude`
3. Run: `/quickstart`
4. Follow the guided setup (~10 minutes)

The quickstart will:
- Ask what your context OS is for (GTM, Product, Research)
- Create the two-layer directory structure
- Generate your CLAUDE.md navigation guide
- Process your first piece of content
- Verify it works

## What You Get

A knowledge system with two layers:

**Knowledge Graph** (`knowledge_base/`) — Atomic concepts linked via `[[wiki-links]]`. Each concept has structured frontmatter, a lifecycle (`emergent` → `validated` → `canonical`), and connections to related ideas.

**Operational Docs** (`00_foundation/`) — Strategic documents (positioning, messaging, brand) that compose from the knowledge graph. They reference concepts, they don't redefine them.

### Context-OS CLI

After setup, initialize the CLI to start tracking your work:
```bash
context-os init          # Index your sessions, build chains
context-os daemon start  # Background sync (auto-tracks file access)
```

Then query your system:
```bash
# Graph structure — find orphans, hubs, node counts
context-os graph-exec --graph knowledge_base '(() => {
  const r = codemode.graph_query({ filter: {}, limit: 500 });
  return JSON.stringify({ total: r.total,
    orphans: r.nodes.filter(n => n.link_count.outbound === 0 && n.link_count.inbound === 0).length
  });
})()'

# File heat — what's been active
context-os query heat --time 14d --limit 10 --format csv

# Co-access — which files travel together
context-os query co-access knowledge_base/technical/my-concept.md

# Broad context search
context-os context "positioning"
```

## Commands

| Command | Purpose |
|---------|---------|
| `/quickstart` | Guided setup experience |
| `/ingest` | Process raw content into the knowledge graph |

## Learn More

For advanced patterns (multi-agent orchestration, client engagement systems, enterprise context architectures): [taste.systems](https://taste.systems)
